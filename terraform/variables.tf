variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tit"
  
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "Project name must be 10 characters or less for AWS resource naming."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "min_capacity" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}