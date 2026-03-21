variable "name_prefix" {
  description = "Name prefix for database resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the database will live."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to reach the database."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
}

variable "db_username" {
  description = "Master username for PostgreSQL."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
}

variable "allocated_storage" {
  description = "Allocated DB storage in GiB."
  type        = number
}

variable "backup_retention" {
  description = "RDS backup retention in days."
  type        = number
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot during destroy."
  type        = bool
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}
