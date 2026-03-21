output "vpc_id" {
  description = "ID of the Northwind VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}

output "db_endpoint" {
  description = "PostgreSQL endpoint."
  value       = module.database.db_endpoint
}

output "db_master_secret_arn" {
  description = "Secrets Manager ARN for the generated master password."
  value       = module.database.db_master_secret_arn
  sensitive   = true
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = module.compute.alb_dns_name
}

output "autoscaling_group_name" {
  description = "Name of the web Auto Scaling Group."
  value       = module.compute.autoscaling_group_name
}
