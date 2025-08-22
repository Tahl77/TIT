#!/bin/bash

# Update system
yum update -y

# Install development tools
yum groupinstall -y "Development Tools"
yum install -y git curl wget unzip htop

# Install Terraform
cd /tmp
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repository
mkdir -p /home/ec2-user/workspace
cd /home/ec2-user/workspace
git clone ${github_repo}
chown -R ec2-user:ec2-user /home/ec2-user/workspace

# Create setup script
cat << 'EOF' > /home/ec2-user/setup-demo.sh
#!/bin/bash
echo "🚀 Setting up TIT Free Tier Demo..."

cd /home/ec2-user/workspace/TIT
chmod +x scripts/*.sh

# Setup terraform vars
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

echo "✅ Free Tier demo ready!"
echo "📁 Project: /home/ec2-user/workspace/TIT"
echo "🚀 Deploy: ./scripts/deploy.sh"
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
║  🚀 All tools installed: Terraform, AWS CLI, Docker, Git  🚀  ║
║  📁 Project location: /home/ec2-user/workspace/TIT        📁  ║
║  🔧 Setup command: ./setup-demo.sh                        🔧  ║
║                                                                ║
║  Quick commands:                                               ║
║    tit          - Go to project directory                      ║
║    awswhoami    - Check AWS credentials                        ║
║    tf           - Terraform shortcut                           ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Development machine setup completed" >> /var/log/setup.log