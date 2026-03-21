output "db_endpoint" {
  description = "Database endpoint."
  value       = aws_db_instance.this.address
}

output "db_master_secret_arn" {
  description = "Secrets Manager ARN of the generated master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}

output "db_security_group_id" {
  description = "Security group attached to the database."
  value       = aws_security_group.db.id
}
