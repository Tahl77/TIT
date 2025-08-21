# TIT - Technical Infrastructure Test

This repository demonstrates Infrastructure as Code (IaC) principles using Terraform to provision a scalable web application stack on AWS with automated failover capabilities.

## Architecture

- **Load Balancer**: AWS Application Load Balancer
- **Web Servers**: Auto Scaling Group with 2-4 EC2 instances
- **Database**: RDS MySQL with encryption and backups
- **Monitoring**: CloudWatch metrics and logs
- **Failover**: Automated health checks and service restart

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/[your-username]/TIT.git
   cd TIT