# 💰 Low-Cost Azure App Service Deployment

## Estimated Monthly Costs
- **Azure SQL Database (Basic)**: ~$5/month
- **App Service Plan (B1)**: ~$13/month
- **Total**: **~$18/month** (vs $50+ with Container Registry)

## 🚀 Step-by-Step Deployment

### Step 1: Create Azure Resources (via Portal)

#### 1.1 Resource Group
1. Go to [Azure Portal](https://portal.azure.com)
2. Create Resource Group: `yardee-spaces-rg`

#### 1.2 Azure SQL Database (Basic Tier)
1. Create **SQL Database**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Database name**: `yardee-spaces-db`
   - **Server**: Create new (`yardee-spaces-sql`)
   - **Compute tier**: **Basic** (5 DTUs)
   - **Admin username**: `yardeeadmin`
   - **Password**: Create strong password (save it!)

2. **Configure Firewall**:
   - Go to SQL Server → **Networking**
   - Enable **"Allow Azure services"**
   - Save

#### 1.3 App Service Plan (Lowest Cost)
1. Create **App Service Plan**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Name**: `yardee-spaces-plan`
   - **OS**: **Linux**
   - **Pricing tier**: **B1** (1 vCPU, 1.75 GB) - $13.14/month
   - **Region**: Same as resource group

#### 1.4 App Service
1. Create **Web App**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Name**: `yardee-spaces-app` (must be globally unique)
   - **Runtime stack**: **Docker**
   - **App Service Plan**: Select your plan

### Step 2: Deploy Code

#### Option A: GitHub Integration (Recommended - Free)
1. In your App Service → **Deployment Center**
2. Choose **GitHub** as source
3. Authorize and select your repository
4. Choose branch: **main**
5. **Build settings**:
   - **Build provider**: **App Service build service**
   - **Dockerfile path**: `Dockerfile.simple`
6. Click **Save**

#### Option B: Local Git Deployment
1. In App Service → **Deployment Center**
2. Choose **Local Git**
3. Copy the Git clone URL
4. Locally run:
   ```bash
   git remote add azure <your-git-url>
   git push azure main
   ```

### Step 3: Configure Environment Variables

1. Go to App Service → **Configuration** → **Application settings**
2. Add these settings:

```bash
# Database Configuration
DB_HOST=yardee-spaces-sql.database.windows.net
DB_NAME=yardee-spaces-db
DB_USER=yardeeadmin
DB_PASSWORD=your-sql-password
DB_PORT=1433

# Django Settings
DEBUG=0
SECRET_KEY=your-super-secure-secret-key
DJANGO_SETTINGS_MODULE=backend.settings

# CORS Settings
CORS_ALLOW_ALL_ORIGINS=False
FRONTEND_URL=https://yardee-spaces-app.azurewebsites.net

# Performance
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
```

3. Click **Save**

### Step 4: Test Deployment

1. Go to your App Service URL: `https://yardee-spaces-app.azurewebsites.net`
2. Test the newsletter signup
3. Check logs: App Service → **Log stream**

## 🔧 Troubleshooting

### Common Issues

1. **Build Fails**:
   - Check **Deployment Center** → **Logs**
   - Verify Dockerfile.simple exists in root
   - Check for syntax errors

2. **Database Connection Issues**:
   - Verify firewall rules in SQL Server
   - Check connection string format
   - Ensure SSL is enabled

3. **App Won't Start**:
   - Check **Log stream** for errors
   - Verify environment variables
   - Check Django settings

### Useful Commands

```bash
# View deployment logs
az webapp log tail --name yardee-spaces-app --resource-group yardee-spaces-rg

# Restart app
az webapp restart --name yardee-spaces-app --resource-group yardee-spaces-rg

# View app settings
az webapp config appsettings list --name yardee-spaces-app --resource-group yardee-spaces-rg
```

## 📊 Cost Optimization Tips

1. **Start with F1 (Free) tier** for testing
2. **Scale down** during low usage periods
3. **Use Basic SQL tier** (5 DTUs is usually enough)
4. **Monitor usage** with Azure Cost Management
5. **Set up budget alerts**

## 🚀 Scaling Options

### When to Scale Up
- **B1 → B2**: If you get > 1000 visitors/day
- **Basic SQL → Standard**: If database becomes slow

### Auto-scaling Rules
1. Go to App Service → **Scale out**
2. Enable **Custom autoscale**
3. Set rules based on CPU/Memory usage

## 🔒 Security Best Practices

1. **Enable HTTPS** (free with App Service)
2. **Use Managed Identity** for database access
3. **Rotate secrets** regularly
4. **Enable Application Insights** for monitoring

## 📈 Monitoring

1. **Application Insights** (free tier available)
2. **Log Analytics** for detailed logs
3. **Metrics** for performance monitoring
4. **Alerts** for critical issues

---

**Total Setup Time**: ~30 minutes
**Monthly Cost**: ~$18
**No Container Registry needed!**
