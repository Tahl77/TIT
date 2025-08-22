terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project = "TIT-FreeTier"
      Environment = "demo"
    }
  }
}

# Use default VPC (Free)
data "aws_vpc" "default" {
  default = true
}

# Get subnets (Free)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get Amazon Linux 2 AMI (Free)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance for Web Application - t2.micro (FREE TIER)
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"  # FREE TIER
  
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  iam_instance_profile       = aws_iam_instance_profile.web_profile.name
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_endpoint = aws_db_instance.mysql.endpoint
    db_password = var.db_password
  }))

  root_block_device {
    volume_type = "gp2"
    volume_size = 20  # FREE TIER allows up to 30GB
    encrypted   = false
  }

  tags = {
    Name = "TIT-WebServer-FreeTier"
  }
}