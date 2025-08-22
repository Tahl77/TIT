#!/bin/bash

# Update system
yum update -y

# Install development tools
yum groupinstall -y "Development Tools"
yum install -y git curl wget unzip

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.6.6_linux_amd64.zip

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and npm (useful for additional tools)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
yum install -y nodejs

# Create workspace directory
mkdir -p /home/ec2-user/workspace
cd /home/ec2-user/workspace

# Clone the TIT repository
git clone ${github_repo}
chown -R ec2-user:ec2-user /home/ec2-user/workspace

# Create helpful scripts
cat << 'EOF' > /home/ec2-user/setup-demo.sh
#!/bin/bash
echo "🚀 Setting up TIT demo environment..."

cd /home/ec2-user/workspace/TIT

# Make scripts executable
chmod +x scripts/*.sh

# Copy terraform.tfvars.example
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

echo "✅ Demo environment ready!"
echo "📁 Repository cloned to: /home/ec2-user/workspace/TIT"
echo "📝 Edit terraform/terraform.tfvars with your settings"
echo "🚀 Run: ./scripts/deploy.sh to deploy infrastructure"
EOF

chmod +x /home/ec2-user/setup-demo.sh
chown ec2-user:ec2-user /home/ec2-user/setup-demo.sh

# Install useful aliases
cat << 'EOF' >> /home/ec2-user/.bashrc

# TIT Demo aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias tit='cd /home/ec2-user/workspace/TIT'
alias tf='terraform'
alias k='kubectl'

# AWS shortcuts
alias awswhoami='aws sts get-caller-identity'
alias awsregion='aws configure get region'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

echo "🎯 TIT Development Machine Ready!"
echo "💻 Run 'tit' to go to project directory"
echo "🔧 Run './setup-demo.sh' to prepare demo"
EOF

# Create welcome message
cat << 'EOF' > /etc/motd

╔════════════════════════════════════════════════════════════════╗
║                    TIT Development Machine                     ║
║                                                                ║
║  🚀 All tools installed: Terraform, AWS CLI, Docker, Git      ║
║  📁 Project location: /home/ec2-user/workspace/TIT             ║
║  🔧 Setup command: ./setup-demo.sh                            ║
║                                                                ║
║  Quick commands:                                               ║
║    tit          - Go to project directory                     ║
║    awswhoami    - Check AWS credentials                       ║
║    tf           - Terraform shortcut                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Development machine setup completed" >> /var/log/setup.log