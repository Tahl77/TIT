# DB Subnet Group (Free)
resource "aws_db_subnet_group" "mysql" {
  name       = "tit-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "tit-db-subnet-group"
  }
}

# RDS MySQL Instance - db.t3.micro (FREE TIER)
resource "aws_db_instance" "mysql" {
  identifier = "tit-mysql-freetier"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"  # FREE TIER
  
  allocated_storage     = 20  # FREE TIER (up to 20GB)
  max_allocated_storage = 20  # Don't auto-scale to avoid charges
  storage_type          = "gp2"
  storage_encrypted     = false  # Encryption costs extra
  
  db_name  = "titdb"
  username = "admin"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  
  backup_retention_period = 0  # No backups to stay free
  backup_window          = null
  maintenance_window     = "sun:03:00-sun:04:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  # Free tier settings
  multi_az               = false
  publicly_accessible    = false
  auto_minor_version_upgrade = false

  tags = {
    Name = "tit-mysql-freetier"
  }
}