output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    health_checks = aws_cloudwatch_log_group.health_checks.name
    nginx_access  = aws_cloudwatch_log_group.nginx_access.name
    failover      = aws_cloudwatch_log_group.failover.name
  }
}