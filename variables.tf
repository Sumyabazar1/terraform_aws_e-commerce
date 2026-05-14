variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "northwind"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the application VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets."
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets."
  type        = list(string)
  default     = ["192.168.101.0/24", "192.168.102.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "northwind"
}

variable "db_username" {
  description = "Master username for the PostgreSQL instance."
  type        = string
  default     = "postgres"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL major engine version."
  type        = string
  default     = "16"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the PostgreSQL instance in GiB."
  type        = number
  default     = 20
}

variable "db_backup_retention" {
  description = "Backup retention window in days. Set to 0 to disable automated backups."
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy."
  type        = bool
  default     = false
}

variable "app_instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t3.micro"
}

variable "app_desired_capacity" {
  description = "Desired Auto Scaling capacity for the web tier."
  type        = number
  default     = 1
}

variable "app_min_size" {
  description = "Minimum Auto Scaling capacity for the web tier."
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum Auto Scaling capacity for the web tier."
  type        = number
  default     = 3
}

variable "app_health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/"
}
