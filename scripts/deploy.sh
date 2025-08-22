#!/bin/bash

set -e

echo "🆓 Deploying TIT Free Tier Infrastructure..."

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not installed"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

cd terraform

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan -out=tfplan

echo "🚀 Applying infrastructure..."
terraform apply tfplan

echo "✅ Free Tier infrastructure deployed!"
echo ""
echo "📊 Outputs:"
terraform output

echo ""
echo "🎯 Your application will be ready in 2-3 minutes at:"
echo "http://$(terraform output -raw web_server_ip)"
echo ""
echo "💰 Monthly cost: $0.00 (Free Tier)"