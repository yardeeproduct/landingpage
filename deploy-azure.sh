#!/bin/bash

# Azure App Service Deployment Script
# Usage: ./deploy-azure.sh [resource-group] [app-name] [acr-name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi

# Get parameters
RESOURCE_GROUP=${1:-yardee-spaces-rg}
APP_NAME=${2:-yardee-spaces-app}
ACR_NAME=${3:-yardeespacesacr}
LOCATION=${4:-eastus}

print_info "Starting Azure deployment..."
print_info "Resource Group: $RESOURCE_GROUP"
print_info "App Name: $APP_NAME"
print_info "ACR Name: $ACR_NAME"
print_info "Location: $LOCATION"

# Step 1: Create resource group
print_info "Step 1: Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION
print_status "Resource group created"

# Step 2: Create Azure SQL Database
print_info "Step 2: Creating Azure SQL Database..."
az sql server create \
  --name "${APP_NAME}-sql" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user yardeeadmin \
  --admin-password "Yardee123!@#" \
  --output none

az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server "${APP_NAME}-sql" \
  --name "${APP_NAME}-db" \
  --service-objective Basic \
  --output none

az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server "${APP_NAME}-sql" \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output none

print_status "Azure SQL Database created"

# Step 3: Create Azure Container Registry
print_info "Step 3: Creating Azure Container Registry..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true \
  --output none
print_status "Container Registry created"

# Step 4: Create App Service Plan
print_info "Step 4: Creating App Service Plan..."
az appservice plan create \
  --name "${APP_NAME}-plan" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku P1V2 \
  --is-linux \
  --output none
print_status "App Service Plan created"

# Step 5: Login to ACR
print_info "Step 5: Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Step 6: Build and push images
print_info "Step 6: Building and pushing container images..."

# Build backend image
print_info "Building backend image..."
docker build -f Dockerfile.backend -t $ACR_NAME.azurecr.io/backend:latest .
docker push $ACR_NAME.azurecr.io/backend:latest

# Build frontend image
print_info "Building frontend image..."
docker build -f Dockerfile.frontend -t $ACR_NAME.azurecr.io/frontend:latest .
docker push $ACR_NAME.azurecr.io/frontend:latest

print_status "Container images built and pushed"

# Step 7: Create App Service
print_info "Step 7: Creating App Service..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan "${APP_NAME}-plan" \
  --name $APP_NAME \
  --multicontainer-config-type compose \
  --multicontainer-config-file docker-compose.azure.yml \
  --output none
print_status "App Service created"

# Step 8: Configure application settings
print_info "Step 8: Configuring application settings..."
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    DEBUG=0 \
    SECRET_KEY="$(openssl rand -base64 32)" \
    DB_HOST="${APP_NAME}-sql.database.windows.net" \
    DB_NAME="${APP_NAME}-db" \
    DB_USER="yardeeadmin" \
    DB_PASSWORD="Yardee123!@#" \
    DB_PORT="1433" \
    FRONTEND_URL="https://${APP_NAME}.azurewebsites.net" \
    CORS_ALLOW_ALL_ORIGINS=False \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
  --output none
print_status "Application settings configured"

# Step 9: Configure container registry authentication
print_info "Step 9: Configuring container registry authentication..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    DOCKER_REGISTRY_SERVER_URL="https://${ACR_NAME}.azurecr.io" \
    DOCKER_REGISTRY_SERVER_USERNAME="$ACR_USERNAME" \
    DOCKER_REGISTRY_SERVER_PASSWORD="$ACR_PASSWORD" \
  --output none
print_status "Container registry authentication configured"

# Step 10: Start the app service
print_info "Step 10: Starting App Service..."
az webapp restart --resource-group $RESOURCE_GROUP --name $APP_NAME --output none
print_status "App Service started"

# Step 11: Display deployment information
echo ""
echo "🎉 Deployment completed successfully!"
echo "======================================"
echo ""
print_info "Deployment Summary:"
echo "• App URL: https://${APP_NAME}.azurewebsites.net"
echo "• Resource Group: ${RESOURCE_GROUP}"
echo "• Database: ${APP_NAME}-sql.database.windows.net"
echo "• Container Registry: ${ACR_NAME}.azurecr.io"
echo ""
print_info "Next Steps:"
echo "1. Wait 5-10 minutes for the application to fully start"
echo "2. Test the application: https://${APP_NAME}.azurewebsites.net"
echo "3. Check logs: az webapp log tail --name ${APP_NAME} --resource-group ${RESOURCE_GROUP}"
echo "4. Run database migrations:"
echo "   az webapp ssh --resource-group ${RESOURCE_GROUP} --name ${APP_NAME}"
echo "   python manage.py migrate"
echo ""
print_warning "Important: Update the SECRET_KEY in Azure App Service settings with a secure value"
