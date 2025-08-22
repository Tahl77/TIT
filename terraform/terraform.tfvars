# Copy this file to terraform.tfvars and update the values

# AWS Configuration
aws_region = "eu-north-1"

# Project Configuration  
project_name = "tit"
environment  = "demo"

# Database Configuration
db_password = "ChangeMe123!SecurePassword"

# Instance Configuration
instance_type    = "t2.micro"
min_capacity     = 2
max_capacity     = 4
desired_capacity = 2

# Security Configuration (Optional - restrict to your IP)
# allowed_cidr_blocks = ["YOUR.IP.ADDRESS.HERE/32"]