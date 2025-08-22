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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[0]
  default_for_az    = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_security_group" "dev_machine" {
  name_prefix = "tit-dev-sg-"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Development ports
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
    Name = "tit-dev-sg"
  }
}

resource "aws_iam_role" "dev_role" {
  name = "tit-dev-role"

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

resource "aws_iam_role_policy" "dev_policy" {
  name = "tit-dev-policy"
  role = aws_iam_role.dev_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "iam:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dev_profile" {
  name = "tit-dev-profile"
  role = aws_iam_role.dev_role.name
}

resource "aws_key_pair" "dev_key" {
  key_name   = "tit-dev-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "dev_machine" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"  # FREE TIER
  
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.dev_machine.id]
  associate_public_ip_address = true
  
  key_name             = aws_key_pair.dev_key.key_name
  iam_instance_profile = aws_iam_instance_profile.dev_profile.name
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    github_repo = var.github_repo
  }))

  root_block_device {
    volume_type = "gp2"
    volume_size = 8  # FREE TIER (up to 30GB)
    encrypted   = false  # Encryption costs extra
  }

  tags = {
    Name = "TIT-DevMachine-FreeTier"
  }
}