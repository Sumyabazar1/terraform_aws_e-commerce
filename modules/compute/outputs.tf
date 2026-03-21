output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.dns_name
}

output "target_group_arn" {
  description = "Web target group ARN."
  value       = aws_lb_target_group.web.arn
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name."
  value       = aws_autoscaling_group.web.name
}
