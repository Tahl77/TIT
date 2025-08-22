#!/bin/bash

set -e

echo "🧹 Destroying TIT Infrastructure..."
echo "⚠️  This will permanently delete all resources!"

# Navigate to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/terraform"

cd "$TERRAFORM_DIR"

# Confirmation
read -p "❓ Are you sure you want to destroy everything? (type 'yes'): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "❌ Operation cancelled"
    exit 0
fi

echo "🔧 Destroying infrastructure..."
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "✅ Infrastructure destroyed successfully!"
    echo "💰 All AWS charges stopped"
    
    # Clean up terraform files
    rm -f tfplan
    rm -f terraform.tfstate.backup
    
    echo "🧹 Cleanup completed"
else
    echo "❌ Destroy failed!"
    echo "💡 Try running manually: terraform destroy"
    exit 1
fi