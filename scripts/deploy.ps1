#!/usr/bin/env pwsh

Write-Host " Deploying TIT Free Tier Infrastructure..." -ForegroundColor Green

# Navigate to terraform directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path (Split-Path -Parent $ScriptDir) "terraform"

Set-Location $TerraformDir
Write-Host " Working directory: $(Get-Location)"

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host " terraform.tfvars not found!" -ForegroundColor Red
    Write-Host " Copy terraform.tfvars.example to terraform.tfvars and configure it" -ForegroundColor Yellow
    Write-Host " Example:" -ForegroundColor Yellow
    Write-Host "   Copy-Item terraform.tfvars.example terraform.tfvars"
    Write-Host "   notepad terraform.tfvars"
    exit 1
}

# Check AWS credentials
try {
    aws sts get-caller-identity | Out-Null
    Write-Host " AWS credentials valid"
} catch {
    Write-Host " AWS credentials not configured!" -ForegroundColor Red
    Write-Host " Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host " Prerequisites met"
Write-Host " Initializing Terraform..."
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host " Terraform init failed!" -ForegroundColor Red
    exit 1
}

Write-Host " Planning deployment..."
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host " Terraform plan failed!" -ForegroundColor Red
    exit 1
}

Write-Host " Applying infrastructure..."
terraform apply tfplan

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host " Infrastructure deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host " Access Points:" -ForegroundColor Yellow
    
    # Get outputs
    try {
        $outputs = terraform output -json | ConvertFrom-Json
        Write-Host " Application: $($outputs.application_url.value)"
        Write-Host " Prometheus: $($outputs.prometheus_url.value)"
        Write-Host " SSH: $($outputs.ssh_command.value)"
    } catch {
        Write-Host " Run 'terraform output' to see access information"
    }
    
    Write-Host ""
    Write-Host " Note: Application may take 3-5 minutes to fully start" -ForegroundColor Yellow
    Write-Host " Ready for demo!" -ForegroundColor Green
} else {
    Write-Host " Deployment failed!" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue
