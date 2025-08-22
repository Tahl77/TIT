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
    password = "tit-demo-2024"
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