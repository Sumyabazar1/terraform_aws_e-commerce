resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Allow PostgreSQL access only from inside the VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from the application VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "this" {
  identifier                  = "${var.name_prefix}-postgres"
  engine                      = "postgres"
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.allocated_storage + 20
  storage_type                = "gp3"
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  backup_retention_period     = var.backup_retention
  skip_final_snapshot         = var.skip_final_snapshot
  deletion_protection         = true
  auto_minor_version_upgrade  = true
  copy_tags_to_snapshot       = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
