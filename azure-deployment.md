# Azure App Service Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Yardee Spaces landing page to Azure App Service.

## Prerequisites
- Azure subscription
- Azure CLI installed
- Docker installed locally
- Git repository access

## Architecture
- **Frontend**: Static React app served by Nginx (Container)
- **Backend**: Django REST API (Container)
- **Database**: Azure SQL Database
- **Hosting**: Azure App Service (Multi-container)

## Step 1: Azure Infrastructure Setup

### 1.1 Create Resource Group
```bash
az group create --name yardee-spaces-rg --location eastus
```

### 1.2 Create Azure SQL Database
```bash
# Create SQL Server
az sql server create \
  --name yardee-spaces-sql \
  --resource-group yardee-spaces-rg \
  --location eastus \
  --admin-user yardeeadmin \
  --admin-password "YourStrong@Passw0rd123!"

# Create Database
az sql db create \
  --resource-group yardee-spaces-rg \
  --server yardee-spaces-sql \
  --name yardee-spaces-db \
  --service-objective Basic

# Configure firewall rule for Azure services
az sql server firewall-rule create \
  --resource-group yardee-spaces-rg \
  --server yardee-spaces-sql \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 1.3 Create Azure Container Registry
```bash
az acr create \
  --resource-group yardee-spaces-rg \
  --name yardeespacesacr \
  --sku Basic \
  --admin-enabled true
```

### 1.4 Create App Service Plan
```bash
az appservice plan create \
  --name yardee-spaces-plan \
  --resource-group yardee-spaces-rg \
  --location eastus \
  --sku P1V2 \
  --is-linux
```

## Step 2: Build and Push Container Images

### 2.1 Login to ACR
```bash
az acr login --name yardeespacesacr
```

### 2.2 Build and Push Backend Image
```bash
docker build -f Dockerfile.backend -t yardeespacesacr.azurecr.io/backend:latest .
docker push yardeespacesacr.azurecr.io/backend:latest
```

### 2.3 Build and Push Frontend Image
```bash
docker build -f Dockerfile.frontend -t yardeespacesacr.azurecr.io/frontend:latest .
docker push yardeespacesacr.azurecr.io/frontend:latest
```

## Step 3: Deploy to App Service

### 3.1 Create Multi-container App Service
```bash
az webapp create \
  --resource-group yardee-spaces-rg \
  --plan yardee-spaces-plan \
  --name yardee-spaces-app \
  --multicontainer-config-type compose \
  --multicontainer-config-file docker-compose.azure.yml
```

### 3.2 Configure Application Settings
```bash
az webapp config appsettings set \
  --resource-group yardee-spaces-rg \
  --name yardee-spaces-app \
  --settings \
    DEBUG=0 \
    SECRET_KEY="your-production-secret-key" \
    DB_HOST="yardee-spaces-sql.database.windows.net" \
    DB_NAME="yardee-spaces-db" \
    DB_USER="yardeeadmin" \
    DB_PASSWORD="YourStrong@Passw0rd123!" \
    DB_PORT="1433" \
    FRONTEND_URL="https://yardee-spaces-app.azurewebsites.net" \
    CORS_ALLOW_ALL_ORIGINS=False
```

### 3.3 Configure Container Registry Authentication
```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name yardeespacesacr --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name yardeespacesacr --query passwords[0].value --output tsv)

# Set in App Service
az webapp config appsettings set \
  --resource-group yardee-spaces-rg \
  --name yardee-spaces-app \
  --settings \
    DOCKER_REGISTRY_SERVER_URL="https://yardeespacesacr.azurecr.io" \
    DOCKER_REGISTRY_SERVER_USERNAME="$ACR_USERNAME" \
    DOCKER_REGISTRY_SERVER_PASSWORD="$ACR_PASSWORD"
```

## Step 4: Database Migration

### 4.1 Run Django Migrations
```bash
az webapp ssh --resource-group yardee-spaces-rg --name yardee-spaces-app
# In the SSH session:
cd /home/site/wwwroot
python manage.py migrate
python manage.py collectstatic --noinput
exit
```

## Step 5: Custom Domain (Optional)

### 5.1 Add Custom Domain
```bash
az webapp config hostname add \
  --webapp-name yardee-spaces-app \
  --resource-group yardee-spaces-rg \
  --hostname yardeespaces.com
```

### 5.2 Configure SSL
```bash
az webapp config ssl bind \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI \
  --name yardee-spaces-app \
  --resource-group yardee-spaces-rg
```

## Step 6: Monitoring and Logging

### 6.1 Enable Application Insights
```bash
az monitor app-insights component create \
  --app yardee-spaces-insights \
  --location eastus \
  --resource-group yardee-spaces-rg

# Link to App Service
az monitor app-insights component connect-webapp \
  --app yardee-spaces-insights \
  --resource-group yardee-spaces-rg \
  --web-app yardee-spaces-app
```

### 6.2 Configure Logging
```bash
az webapp log config \
  --resource-group yardee-spaces-rg \
  --name yardee-spaces-app \
  --application-logging true \
  --level information \
  --web-server-logging filesystem
```

## Step 7: CI/CD Pipeline

### 7.1 GitHub Actions Workflow
Create `.github/workflows/azure-deploy.yml`:

```yaml
name: Deploy to Azure App Service

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Log in to Azure Container Registry
      uses: azure/docker-login@v1
      with:
        login-server: ${{ secrets.ACR_LOGIN_SERVER }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}
    
    - name: Build and push backend
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./Dockerfile.backend
        push: true
        tags: ${{ secrets.ACR_LOGIN_SERVER }}/backend:${{ github.sha }}
    
    - name: Build and push frontend
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./Dockerfile.frontend
        push: true
        tags: ${{ secrets.ACR_LOGIN_SERVER }}/frontend:${{ github.sha }}
    
    - name: Deploy to Azure App Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ secrets.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

## Troubleshooting

### Common Issues

1. **Container Startup Failures**
   - Check logs: `az webapp log tail --name yardee-spaces-app --resource-group yardee-spaces-rg`
   - Verify environment variables
   - Check database connectivity

2. **Database Connection Issues**
   - Verify firewall rules
   - Check connection string format
   - Ensure SSL is enabled

3. **CORS Issues**
   - Verify FRONTEND_URL setting
   - Check CORS_ALLOWED_ORIGINS configuration

### Useful Commands

```bash
# View application logs
az webapp log tail --name yardee-spaces-app --resource-group yardee-spaces-rg

# Restart app service
az webapp restart --name yardee-spaces-app --resource-group yardee-spaces-rg

# Scale app service
az appservice plan update --name yardee-spaces-plan --resource-group yardee-spaces-rg --sku P2V2

# View container logs
az webapp log download --name yardee-spaces-app --resource-group yardee-spaces-rg
```

## Cost Optimization

### Resource Sizing
- **App Service Plan**: Start with P1V2, scale based on usage
- **Azure SQL Database**: Start with Basic (5 DTU), upgrade as needed
- **Container Registry**: Basic tier sufficient

### Monitoring Costs
- Set up budget alerts
- Monitor resource utilization
- Use Azure Cost Management

## Security Best Practices

1. **Secrets Management**
   - Use Azure Key Vault for sensitive data
   - Enable Managed Identity for database access
   - Rotate secrets regularly

2. **Network Security**
   - Configure VNet integration
   - Use Private Endpoints for database
   - Enable Web Application Firewall

3. **Application Security**
   - Enable HTTPS redirect
   - Configure security headers
   - Regular security updates

## Performance Optimization

1. **Caching**
   - Enable Azure Redis Cache
   - Configure CDN for static assets
   - Use browser caching headers

2. **Database Optimization**
   - Enable connection pooling
   - Use read replicas for scaling
   - Monitor query performance

3. **Application Performance**
   - Enable auto-scaling
   - Monitor response times
   - Optimize container images
