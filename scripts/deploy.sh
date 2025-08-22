#!/bin/bash

set -e

echo "🚀 Deploying TIT Free Tier Infrastructure..."

# Navigate to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/terraform"

cd "$TERRAFORM_DIR"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found!"
    echo "📝 Copy terraform.tfvars.example to terraform.tfvars and configure it"
    echo "💡 Example:"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   nano terraform.tfvars"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured!"
    echo "💡 Run: aws configure"
    exit 1
fi

echo "✅ Prerequisites met"
echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan -out=tfplan

echo "🚀 Applying infrastructure..."
terraform apply tfplan

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Infrastructure deployed successfully!"
    echo ""
    echo "📊 Access Points:"
    terraform output -json | jq -r '
        "🌐 Application: " + .application_url.value,
        "📊 Grafana: " + .grafana_url.value + " (admin/tit-demo-2024)",
        "📈 Prometheus: " + .prometheus_url.value,
        "🔧 SSH: " + .ssh_command.value
    ' 2>/dev/null || {
        echo "🌐 Application: $(terraform output -raw application_url 2>/dev/null || echo 'Check terraform output')"
        echo "📊 Grafana: $(terraform output -raw grafana_url 2>/dev/null || echo 'Check terraform output'):3000"
        echo "📈 Prometheus: $(terraform output -raw prometheus_url 2>/dev/null || echo 'Check terraform output'):9090"
    }
    
    echo ""
    echo "⏱️  Note: Application may take 3-5 minutes to fully start"
    echo "🎯 Ready for demo!"
else
    echo "❌ Deployment failed!"
    exit 1
fi

# Clean up
rm -f tfplan