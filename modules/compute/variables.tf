variable "name_prefix" {
  description = "Name prefix for compute resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the web tier."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used for ALB egress scoping."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the web tier Auto Scaling Group."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
}

variable "desired_capacity" {
  description = "Desired Auto Scaling capacity."
  type        = number
}

variable "min_size" {
  description = "Minimum Auto Scaling capacity."
  type        = number
}

variable "max_size" {
  description = "Maximum Auto Scaling capacity."
  type        = number
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}
