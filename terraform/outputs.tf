# /terraform/outputs.tf - CORRECTED VERSION

output "application_url" {
  description = "URL to access the TIT application"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "web_server_ip" {
  description = "Web server public IP address"
  value       = aws_instance.web_server.public_ip
}

output "grafana_url" {
  description = "URL to access Grafana monitoring dashboard"
  value       = "http://${aws_instance.web_server.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus metrics"
  value       = "http://${aws_instance.web_server.public_ip}:9090"
}

output "database_endpoint" {
  description = "RDS MySQL database endpoint"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to web server"
  value       = "ssh ec2-user@${aws_instance.web_server.public_ip}"
}

output "demo_access_info" {
  description = "All access points for the demo"
  value = {
    application = "http://${aws_instance.web_server.public_ip}"
    grafana     = "http://${aws_instance.web_server.public_ip}:3000"
    prometheus  = "http://${aws_instance.web_server.public_ip}:9090"
    ssh         = "ssh ec2-user@${aws_instance.web_server.public_ip}"
  }
}

output "monitoring_credentials" {
  description = "Grafana login credentials"
  value = {
    username = "admin"
    password = "tit-demo-2025"
  }
  sensitive = true
}

output "cost_summary" {
  description = "AWS Free Tier cost breakdown"
  value = {
    ec2_instance      = "t3.micro - $0.00/month (Free Tier)"
    rds_database      = "db.t3.micro - $0.00/month (Free Tier)"
    ebs_storage       = "20GB - $0.00/month (Free Tier)"
    nginx_lb          = "Open Source - $0.00/month"
    total_monthly     = "$0.00/month"
    vs_traditional    = "Saves ~$50/month vs ALB setup"
  }
}
output "resource_group_arn" {
  description = "ARN of the resource group containing all TIT resources"
  value       = aws_resourcegroups_group.tit_resources.arn
}

output "aws_console_links" {
  description = "Direct links to AWS Console for your resources"
  value = {
    ec2_instances    = "https://${var.aws_region}.console.aws.amazon.com/ec2/home?region=${var.aws_region}#Instances:tag:Project=TIT-DevMachine"
    security_groups  = "https://${var.aws_region}.console.aws.amazon.com/ec2/home?region=${var.aws_region}#SecurityGroups:tag:Project=TIT-DevMachine"
    resource_group   = "https://console.aws.amazon.com/resource-groups/group/TIT-DevMachine-Resources"
  }
}