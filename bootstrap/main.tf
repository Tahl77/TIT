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
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
  default_for_az    = true
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group for development machine
resource "aws_security_group" "dev_machine" {
  name_prefix = "tit-dev-machine-"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP access for testing
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker/app ports for testing
  ingress {
    from_port   = 8080
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "tit-dev-machine-sg"
    Project = "TIT-DevMachine"
  }
}

# IAM role for EC2 instance
resource "aws_iam_role" "dev_machine_role" {
  name = "tit-dev-machine-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for full AWS access (for demo purposes)
resource "aws_iam_role_policy" "dev_machine_policy" {
  name = "tit-dev-machine-policy"
  role = aws_iam_role.dev_machine_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dev_machine_profile" {
  name = "tit-dev-machine-profile"
  role = aws_iam_role.dev_machine_role.name
}

# Key pair for SSH access
resource "aws_key_pair" "dev_machine_key" {
  key_name   = "tit-dev-machine-key"
  public_key = var.ssh_public_key
}

# EC2 Instance for development
resource "aws_instance" "dev_machine" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.dev_machine.id]
  associate_public_ip_address = true
  
  key_name             = aws_key_pair.dev_machine_key.key_name
  iam_instance_profile = aws_iam_instance_profile.dev_machine_profile.name
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    github_repo = var.github_repo
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "TIT-DevMachine"
    Project     = "TIT-DevMachine"
    Environment = "development"
  }
}