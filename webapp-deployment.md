# 🌐 Azure Web App Deployment (No Docker)

## Option 1: Python Web App (Recommended - Easiest)

### Step 1: Create Resources

#### 1.1 Resource Group
- Name: `yardee-spaces-rg`

#### 1.2 SQL Database
- **Compute tier**: Basic (5 DTUs) - ~$5/month
- **Server name**: `yardee-spaces-sql`
- **Database name**: `yardee-spaces-db`

#### 1.3 App Service Plan
- **OS**: Linux
- **Pricing tier**: B1 - ~$13/month

#### 1.4 Web App
- **Runtime stack**: **Python 3.11**
- **Operating System**: **Linux**
- **App Service Plan**: Select your plan

### Step 2: Deploy Backend

#### 2.1 GitHub Integration
1. Go to Web App → **Deployment Center**
2. Choose **GitHub**
3. Select repository and branch
4. Azure will automatically deploy your Django backend

#### 2.2 Configure Startup Command
In Web App → **Configuration** → **General settings**:
```
gunicorn --bind 0.0.0.0:8000 --workers 2 backend.wsgi:application
```

### Step 3: Deploy Frontend Separately

#### Option A: Static Web App (Free)
1. Create **Static Web App**
2. Connect to GitHub
3. Build command: `npm run build`
4. App location: `/frontend`

#### Option B: CDN/Blob Storage (Cheapest)
1. Upload built frontend to Azure Blob Storage
2. Enable static website hosting
3. Cost: ~$0.50/month

## Option 2: Container Apps (If you prefer Docker)

### Create Container App:
1. Create **Container Apps Environment**
2. Create **Container App**
3. Use your `Dockerfile.simple`

## Option 3: Hybrid Approach (Most Cost-Effective)

### Backend: Function App (Consumption Plan)
- **Cost**: Pay per request (~$0.50/month for low traffic)
- **Runtime**: Python 3.11
- **Deploy**: Django app as Azure Function

### Frontend: Static Web App
- **Cost**: Free
- **Deploy**: Vite build output

---

## Recommended: Option 1 (Python Web App)

**Total Cost**: ~$18/month
**Complexity**: Low
**Setup Time**: 15 minutes

### Quick Setup:
1. Create Web App with Python 3.11
2. Connect GitHub repository
3. Set environment variables
4. Deploy frontend to Static Web App (free)

Would you like me to create the specific configuration files for the Python Web App approach?
