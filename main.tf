data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source = "./modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "database" {
  source = "./modules/database"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr_block
  private_subnet_ids  = module.network.private_subnet_ids
  db_name             = var.db_name
  db_username         = var.db_username
  db_instance_class   = var.db_instance_class
  db_engine_version   = var.db_engine_version
  allocated_storage   = var.db_allocated_storage
  backup_retention    = var.db_backup_retention
  skip_final_snapshot = var.db_skip_final_snapshot
  tags                = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  vpc_cidr          = module.network.vpc_cidr_block
  public_subnet_ids = module.network.public_subnet_ids
  instance_type     = var.app_instance_type
  desired_capacity  = var.app_desired_capacity
  min_size          = var.app_min_size
  max_size          = var.app_max_size
  health_check_path = var.app_health_check_path
  tags              = local.common_tags
}
