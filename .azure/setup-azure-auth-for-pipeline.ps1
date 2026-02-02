# Setup Azure Authentication for GitHub Actions Pipeline
# Run this script to automate the setup process

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope"
)

Write-Host "🚀 Setting up Azure Authentication for GitHub Actions Pipeline" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Check if GitHub CLI is installed
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Login to Azure
Write-Host "`n📝 Step 1: Azure Login" -ForegroundColor Green
az login

# Get subscription info
$subscription = az account show | ConvertFrom-Json
$subscriptionId = $subscription.id
$tenantId = $subscription.tenantId

Write-Host "✅ Using subscription: $($subscription.name) ($subscriptionId)" -ForegroundColor Green

# Create resource group for pipeline infrastructure
Write-Host "`n📝 Step 2: Creating Pipeline Infrastructure" -ForegroundColor Green
$pipelineRg = "rg-yaok-pipeline"

az group create --name $pipelineRg --location $Location | Out-Null
Write-Host "✅ Created resource group: $pipelineRg" -ForegroundColor Green

# Create managed identity
Write-Host "`n📝 Step 3: Creating Managed Identity" -ForegroundColor Green
$identityName = "yaok-github-pipeline"

az identity create `
    --name $identityName `
    --resource-group $pipelineRg `
    --location $Location | Out-Null

$identity = az identity show `
    --name $identityName `
    --resource-group $pipelineRg | ConvertFrom-Json

$clientId = $identity.clientId
Write-Host "✅ Created Managed Identity: $identityName" -ForegroundColor Green
Write-Host "   Client ID: $clientId" -ForegroundColor Cyan

# Prompt for resource groups
Write-Host "`n📝 Step 4: Resource Group Configuration" -ForegroundColor Green
$devRg = Read-Host "Enter DEV resource group name (or press Enter to skip)"
$stagingRg = Read-Host "Enter STAGING resource group name (or press Enter to skip)"
$prodRg = Read-Host "Enter PRODUCTION resource group name (or press Enter to skip)"
$acrName = Read-Host "Enter Azure Container Registry name (or press Enter to skip)"

# Function to assign roles
function Assign-Roles {
    param($resourceGroup, $envName)
    
    if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
        Write-Host "⏭️  Skipping $envName environment" -ForegroundColor Yellow
        return
    }
    
    Write-Host "   Assigning Contributor role for $envName..." -ForegroundColor Cyan
    az role assignment create `
        --assignee $clientId `
        --role Contributor `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
        --only-show-errors | Out-Null
    
    if (![string]::IsNullOrWhiteSpace($acrName)) {
        Write-Host "   Assigning AcrPull role for $envName..." -ForegroundColor Cyan
        az role assignment create `
            --assignee $clientId `
            --role AcrPull `
            --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerRegistry/registries/$acrName" `
            --only-show-errors | Out-Null
    }
    
    Write-Host "✅ Roles assigned for $envName" -ForegroundColor Green
}

# Assign roles for each environment
Write-Host "`n📝 Step 5: Assigning RBAC Roles" -ForegroundColor Green
Assign-Roles -resourceGroup $devRg -envName "DEV"
Assign-Roles -resourceGroup $stagingRg -envName "STAGING"
Assign-Roles -resourceGroup $prodRg -envName "PRODUCTION"

# Create federated credentials
Write-Host "`n📝 Step 6: Creating Federated Credentials" -ForegroundColor Green
$repoPath = "$GitHubOrg/$GitHubRepo"

function Create-FederatedCredential {
    param($envName)
    
    $credName = "yaok-github-$envName"
    Write-Host "   Creating federated credential for $envName..." -ForegroundColor Cyan
    
    az identity federated-credential create `
        --name $credName `
        --identity-name $identityName `
        --resource-group $pipelineRg `
        --issuer "https://token.actions.githubusercontent.com" `
        --subject "repo:${repoPath}:environment:$envName" `
        --audiences "api://AzureADTokenExchange" `
        --only-show-errors | Out-Null
    
    Write-Host "✅ Created federated credential: $credName" -ForegroundColor Green
}

Create-FederatedCredential -envName "dev"
Create-FederatedCredential -envName "staging"
Create-FederatedCredential -envName "production"

# GitHub setup
Write-Host "`n📝 Step 7: GitHub Configuration" -ForegroundColor Green
Write-Host "   Authenticating with GitHub..." -ForegroundColor Cyan
gh auth login

# Set repository secrets
Write-Host "`n📝 Step 8: Setting GitHub Secrets" -ForegroundColor Green
gh secret set AZURE_CLIENT_ID --body $clientId --repo "$repoPath"
gh secret set AZURE_TENANT_ID --body $tenantId --repo "$repoPath"
gh secret set AZURE_SUBSCRIPTION_ID --body $subscriptionId --repo "$repoPath"
Write-Host "✅ GitHub secrets configured" -ForegroundColor Green

# Prompt for environment variables
Write-Host "`n📝 Step 9: Environment Variables Configuration" -ForegroundColor Green
Write-Host "   Please configure the following variables for each environment:" -ForegroundColor Yellow

function Configure-Environment {
    param($envName, $resourceGroup)
    
    if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
        return
    }
    
    Write-Host "`n   $envName Environment:" -ForegroundColor Cyan
    $relayAppName = Read-Host "     Relay Container App name for $envName"
    $webAppName = Read-Host "     Web App Service name for $envName"
    
    gh variable set ACR_NAME --env $envName --body $acrName --repo "$repoPath"
    gh variable set RESOURCE_GROUP --env $envName --body $resourceGroup --repo "$repoPath"
    gh variable set RELAY_APP_NAME --env $envName --body $relayAppName --repo "$repoPath"
    gh variable set WEB_APP_NAME --env $envName --body $webAppName --repo "$repoPath"
    
    Write-Host "   ✅ $envName variables configured" -ForegroundColor Green
}

Configure-Environment -envName "dev" -resourceGroup $devRg
Configure-Environment -envName "staging" -resourceGroup $stagingRg
Configure-Environment -envName "production" -resourceGroup $prodRg

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Create GitHub Environments (dev, staging, production)" -ForegroundColor White
Write-Host "   Go to: https://github.com/$repoPath/settings/environments" -ForegroundColor Cyan
Write-Host "2. Add required reviewers for staging and production" -ForegroundColor White
Write-Host "3. Push to main branch to trigger the pipeline" -ForegroundColor White
Write-Host "`nConfiguration Summary:" -ForegroundColor Yellow
Write-Host "  Subscription ID: $subscriptionId" -ForegroundColor White
Write-Host "  Tenant ID: $tenantId" -ForegroundColor White
Write-Host "  Client ID: $clientId" -ForegroundColor White
Write-Host "  Pipeline RG: $pipelineRg" -ForegroundColor White
Write-Host "  Managed Identity: $identityName" -ForegroundColor White
Write-Host "`n🎉 Happy deploying!" -ForegroundColor Cyan
