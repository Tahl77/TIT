#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

# Script header
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    TIT Infrastructure Deployment               ║"
echo "║                    Terraform + AWS Deployment                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        error "Terraform not installed. Please install Terraform first."
    fi
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not installed. Please install AWS CLI first."
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Run 'aws configure' first."
    fi
    
    if [ ! -f "terraform/terraform.tfvars" ]; then
        error "terraform.tfvars not found. Copy terraform.tfvars.example and configure it."
    fi
    
    success "All prerequisites met!"
}

# Deploy infrastructure
deploy_infrastructure() {
    log "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log "Planning infrastructure changes..."
    terraform plan -out=tfplan -detailed-exitcode
    plan_exit_code=$?
    
    if [ $plan_exit_code -eq 0 ]; then
        warning "No changes detected. Infrastructure is up to date."
        cd ..
        return 0
    elif [ $plan_exit_code -eq 2 ]; then
        log "Changes detected. Applying infrastructure..."
        terraform apply tfplan
        
        if [ $? -eq 0 ]; then
            success "Infrastructure deployed successfully!"
            
            # Show outputs
            log "Infrastructure outputs:"
            terraform output
        else
            error "Terraform apply failed!"
        fi
    else
        error "Terraform plan failed!"
    fi
    
    cd ..
}

# Test deployment
test_deployment() {
    log "Testing deployment..."
    
    cd terraform
    
    # Get load balancer DNS name
    ALB_DNS=$(terraform output -raw application_url 2>/dev/null || echo "")
    
    if [ -z "$ALB_DNS" ]; then
        warning "Could not retrieve application URL. Check Terraform outputs manually."
        return 0
    fi
    
    log "Application URL: $ALB_DNS"
    log "Waiting for application to be ready (this may take a few minutes)..."
    
    # Wait for application to be ready
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s "$ALB_DNS/health" > /dev/null 2>&1; then
            success "Application is responding!"
            success "You can access your application at: $ALB_DNS"
            break
        else
            log "Waiting for application... (attempt $((attempt + 1))/$max_attempts)"
            sleep 30
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -eq $max_attempts ]; then
        warning "Application health check timed out. It may still be starting up."
        warning "Please check the application manually at: $ALB_DNS"
    fi
    
    cd ..
}

# Cleanup function
cleanup() {
    if [ -f "terraform/tfplan" ]; then
        rm -f terraform/tfplan
    fi
}

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Parse command line arguments
    case "${1:-deploy}" in
        "check")
            check_prerequisites
            ;;
        "plan")
            check_prerequisites
            cd terraform
            terraform init
            terraform plan
            cd ..
            ;;
        "deploy")
            check_prerequisites
            deploy_infrastructure
            test_deployment
            ;;
        *)
            echo "Usage: $0 [check|plan|deploy]"
            echo "  check  - Check prerequisites only"
            echo "  plan   - Show deployment plan"
            echo "  deploy - Deploy infrastructure (default)"
            exit 1
            ;;
    esac
    
    success "Script completed successfully!"
}

# Run main function
main "$@"