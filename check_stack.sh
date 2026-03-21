#!/usr/bin/env bash

set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-2}}"
PROJECT_PREFIX="${1:-northwind-dev}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd aws
require_cmd python3

aws_cli() {
  aws --region "$REGION" "$@"
}

section() {
  printf '\n== %s ==\n' "$1"
}

get_vpc_id() {
  aws_cli ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text
}

get_db_sg_id() {
  aws_cli ec2 describe-security-groups \
    --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-db-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text
}

get_alb_name() {
  printf '%s-alb' "$PROJECT_PREFIX"
}

get_asg_name() {
  printf '%s-web' "$PROJECT_PREFIX"
}

VPC_ID="$(get_vpc_id)"
DB_SG_ID="$(get_db_sg_id)"
ALB_NAME="$(get_alb_name)"
ASG_NAME="$(get_asg_name)"
DB_ID="${PROJECT_PREFIX}-postgres"
DB_SUBNET_GROUP="${PROJECT_PREFIX}-db-subnets"

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "VPC not found for prefix ${PROJECT_PREFIX}" >&2
  exit 1
fi

section "Config"
echo "Region: $REGION"
echo "Prefix: $PROJECT_PREFIX"
echo "VPC ID: $VPC_ID"
echo "DB ID: $DB_ID"
echo "ALB Name: $ALB_NAME"
echo "ASG Name: $ASG_NAME"

section "Part 1: VPC"
aws_cli ec2 describe-vpcs \
  --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].{VpcId:VpcId,Cidr:CidrBlock,DnsHostnames:EnableDnsHostnames,DnsSupport:EnableDnsSupport,State:State}' \
  --output table

section "Part 1: Subnets"
aws_cli ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[].{Name:Tags[?Key==`Name`]|[0].Value,SubnetId:SubnetId,AZ:AvailabilityZone,Cidr:CidrBlock,PublicIPOnLaunch:MapPublicIpOnLaunch}' \
  --output table

section "Part 1: Route Tables"
aws_cli ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[].{RouteTableId:RouteTableId,Routes:Routes[*].DestinationCidrBlock,GatewayIds:Routes[*].GatewayId,Associations:Associations[*].SubnetId}' \
  --output json

section "Part 1: RDS"
aws_cli rds describe-db-instances \
  --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].{Engine:Engine,Version:EngineVersion,Class:DBInstanceClass,PubliclyAccessible:PubliclyAccessible,Status:DBInstanceStatus,SubnetGroup:DBSubnetGroup.DBSubnetGroupName,Endpoint:Endpoint.Address,BackupRetention:BackupRetentionPeriod,VpcSecurityGroups:VpcSecurityGroups[*].VpcSecurityGroupId}' \
  --output table

section "Part 1: DB Subnet Group"
aws_cli rds describe-db-subnet-groups \
  --db-subnet-group-name "$DB_SUBNET_GROUP" \
  --query 'DBSubnetGroups[0].Subnets[].{SubnetId:SubnetIdentifier,Status:SubnetStatus}' \
  --output table

section "Part 1: DB Security Group"
aws_cli ec2 describe-security-groups \
  --group-ids "$DB_SG_ID" \
  --query 'SecurityGroups[0].IpPermissions' \
  --output json

section "Part 2: ALB"
aws_cli elbv2 describe-load-balancers \
  --names "$ALB_NAME" \
  --query 'LoadBalancers[0].{DNSName:DNSName,Scheme:Scheme,Type:Type,State:State.Code,VpcId:VpcId}' \
  --output table

TG_ARN="$(aws_cli elbv2 describe-target-groups \
  --query "TargetGroups[?VpcId=='${VPC_ID}' && starts_with(TargetGroupName, 'nw')].TargetGroupArn | [0]" \
  --output text)"

section "Part 2: Target Group"
aws_cli elbv2 describe-target-groups \
  --target-group-arns "$TG_ARN" \
  --query 'TargetGroups[0].{TargetGroupArn:TargetGroupArn,Port:Port,Protocol:Protocol,TargetType:TargetType,HealthPath:HealthCheckPath,Matcher:Matcher.HttpCode}' \
  --output table

section "Part 2: Auto Scaling Group"
aws_cli autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,TargetGroups:TargetGroupARNs,VpcSubnets:VPCZoneIdentifier}' \
  --output table

LT_ID="$(aws_cli autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId' \
  --output text)"

section "Part 2: Launch Template"
aws_cli ec2 describe-launch-template-versions \
  --launch-template-id "$LT_ID" \
  --versions '$Latest' \
  --query 'LaunchTemplateVersions[0].LaunchTemplateData.{ImageId:ImageId,InstanceType:InstanceType,SecurityGroups:SecurityGroupIds,IamProfile:IamInstanceProfile.Name}' \
  --output table

section "Part 2: Target Health"
aws_cli elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[].{InstanceId:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason}' \
  --output table

section "Assertions"
python3 - "$REGION" "$PROJECT_PREFIX" "$VPC_ID" "$DB_SG_ID" "$DB_ID" "$ASG_NAME" "$TG_ARN" <<'PY'
import json
import subprocess
import sys

region = sys.argv[1]
prefix = sys.argv[2]
vpc_id = sys.argv[3]
db_sg_id = sys.argv[4]
db_id = sys.argv[5]
asg_name = sys.argv[6]
tg_arn = sys.argv[7]

def aws_json(*args):
    cmd = ["aws", "--region", region, *args, "--output", "json"]
    return json.loads(subprocess.check_output(cmd, text=True))

def ok(label, condition, detail):
    status = "PASS" if condition else "FAIL"
    print(f"{status}: {label} - {detail}")
    return condition

all_ok = True

vpc = aws_json("ec2", "describe-vpcs", "--vpc-ids", vpc_id)["Vpcs"][0]
all_ok &= ok("VPC CIDR", vpc["CidrBlock"] == "192.168.0.0/16", vpc["CidrBlock"])

subnets = aws_json("ec2", "describe-subnets", "--filters", f"Name=vpc-id,Values={vpc_id}")["Subnets"]
public = [s for s in subnets if s["MapPublicIpOnLaunch"]]
private = [s for s in subnets if not s["MapPublicIpOnLaunch"]]
all_ok &= ok("Two public subnets", len(public) == 2, str(len(public)))
all_ok &= ok("Two private subnets", len(private) == 2, str(len(private)))
all_ok &= ok("Two AZs used", len({s["AvailabilityZone"] for s in subnets}) >= 2, str(sorted({s["AvailabilityZone"] for s in subnets})))

route_tables = aws_json("ec2", "describe-route-tables", "--filters", f"Name=vpc-id,Values={vpc_id}")["RouteTables"]
public_default_routes = 0
for rt in route_tables:
    has_igw = any(r.get("DestinationCidrBlock") == "0.0.0.0/0" and r.get("GatewayId", "").startswith("igw-") for r in rt.get("Routes", []))
    if has_igw:
        public_default_routes += len([a for a in rt.get("Associations", []) if a.get("SubnetId")])
all_ok &= ok("Only public subnets have IGW route", public_default_routes == 2, str(public_default_routes))

db = aws_json("rds", "describe-db-instances", "--db-instance-identifier", db_id)["DBInstances"][0]
all_ok &= ok("RDS engine", db["Engine"] == "postgres", db["Engine"])
all_ok &= ok("RDS class", db["DBInstanceClass"] == "db.t3.micro", db["DBInstanceClass"])
all_ok &= ok("RDS not public", db["PubliclyAccessible"] is False, str(db["PubliclyAccessible"]))

sg = aws_json("ec2", "describe-security-groups", "--group-ids", db_sg_id)["SecurityGroups"][0]
postgres_rules = [
    p for p in sg.get("IpPermissions", [])
    if p.get("FromPort") == 5432 and p.get("ToPort") == 5432 and p.get("IpProtocol") == "tcp"
]
cidrs = sorted(c["CidrIp"] for p in postgres_rules for c in p.get("IpRanges", []))
all_ok &= ok("DB ingress restricted to VPC CIDR", cidrs == ["192.168.0.0/16"], str(cidrs))

lbs = aws_json("elbv2", "describe-load-balancers", "--names", f"{prefix}-alb")["LoadBalancers"]
lb = lbs[0]
all_ok &= ok("ALB type", lb["Type"] == "application", lb["Type"])
all_ok &= ok("ALB scheme", lb["Scheme"] == "internet-facing", lb["Scheme"])

tg = aws_json("elbv2", "describe-target-groups", "--target-group-arns", tg_arn)["TargetGroups"][0]
all_ok &= ok("Target group port", tg["Port"] == 80, str(tg["Port"]))
all_ok &= ok("Health check path", tg["HealthCheckPath"] == "/", tg["HealthCheckPath"])
all_ok &= ok("Health check matcher", tg["Matcher"]["HttpCode"] == "200", tg["Matcher"]["HttpCode"])

asg = aws_json("autoscaling", "describe-auto-scaling-groups", "--auto-scaling-group-names", asg_name)["AutoScalingGroups"][0]
all_ok &= ok("ASG min size", asg["MinSize"] == 1, str(asg["MinSize"]))
all_ok &= ok("ASG max size", asg["MaxSize"] == 3, str(asg["MaxSize"]))
all_ok &= ok("ASG target group attached", tg_arn in asg.get("TargetGroupARNs", []), str(asg.get("TargetGroupARNs", [])))

if not all_ok:
    sys.exit(1)
PY
