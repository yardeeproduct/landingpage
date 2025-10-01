# 🚀 Simple Azure Web App Deployment

## What You'll Create:
- **Web App** (Python 3.11) - ~$13/month
- **SQL Database** (Basic) - ~$5/month
- **Static Web App** (Frontend) - Free
- **Total**: ~$18/month

## Step 1: Create Azure Resources

### 1.1 Resource Group
1. Go to [Azure Portal](https://portal.azure.com)
2. Create Resource Group: `yardee-spaces-rg`

### 1.2 SQL Database
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

### 1.3 App Service Plan
1. Create **App Service Plan**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Name**: `yardee-spaces-plan`
   - **OS**: **Linux**
   - **Pricing tier**: **B1** (1 vCPU, 1.75 GB)

### 1.4 Web App (Backend)
1. Create **Web App**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Name**: `yardee-spaces-api` (must be globally unique)
   - **Runtime stack**: **Python 3.11**
   - **Operating System**: **Linux**
   - **App Service Plan**: Select your plan

### 1.5 Static Web App (Frontend)
1. Create **Static Web App**:
   - **Resource Group**: `yardee-spaces-rg`
   - **Name**: `yardee-spaces-web`
   - **Hosting Plan**: **Free**
   - **Region**: Same as resource group

## Step 2: Deploy Backend (Web App)

### 2.1 Prepare Backend
1. Copy `requirements-webapp.txt` to `requirements.txt`:
   ```bash
   cp requirements-webapp.txt requirements.txt
   ```

2. Copy `startup.py` to root directory

### 2.2 Deploy via GitHub
1. In your Web App → **Deployment Center**
2. Choose **GitHub**
3. Select repository and branch: `main`
4. **Build settings**:
   - **Build provider**: **App Service build service**
   - **Build command**: (leave empty)
   - **Startup command**: `python startup.py`

### 2.3 Configure Environment Variables
Go to Web App → **Configuration** → **Application settings**:

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
FRONTEND_URL=https://yardee-spaces-web.azurestaticapps.net

# Performance
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
```

## Step 3: Deploy Frontend (Static Web App)

### 3.1 Connect to GitHub
1. In Static Web App → **Deployment Center**
2. Choose **GitHub**
3. Select repository and branch: `main`

### 3.2 Configure Build
- **App location**: `/frontend`
- **Build command**: `npm run build`
- **Output location**: `/frontend/dist`

### 3.3 Update Frontend API URL
In `frontend/src/main.js`, update the API URL:
```javascript
// Change this line:
const apiBaseUrl = '';

// To this:
const apiBaseUrl = 'https://yardee-spaces-api.azurewebsites.net';
```

## Step 4: Test Deployment

### Backend API:
- URL: `https://yardee-spaces-api.azurewebsites.net`
- Health check: `https://yardee-spaces-api.azurewebsites.net/api/health/`

### Frontend:
- URL: `https://yardee-spaces-web.azurestaticapps.net`

## Step 5: Custom Domain (Optional)

### For Backend:
1. Go to Web App → **Custom domains**
2. Add your domain: `api.yourdomain.com`

### For Frontend:
1. Go to Static Web App → **Custom domains**
2. Add your domain: `yourdomain.com`

## Troubleshooting

### Backend Issues:
1. **Check logs**: Web App → **Log stream**
2. **Restart**: Web App → **Restart**
3. **Check startup command**: Configuration → General settings

### Frontend Issues:
1. **Check build logs**: Static Web App → **Deployment Center**
2. **Verify build settings**: App location and build command

### Database Issues:
1. **Check firewall**: SQL Server → Networking
2. **Verify connection string**: App settings
3. **Test connection**: Web App → Console

## Cost Breakdown:
- **App Service Plan (B1)**: $13.14/month
- **SQL Database (Basic)**: $5/month
- **Static Web App**: Free
- **Total**: ~$18/month

## Scaling:
- **Scale up**: B1 → B2 → B3 as traffic grows
- **Database**: Basic → Standard → Premium
- **Auto-scale**: Set up based on CPU/memory usage

---

**Setup Time**: 20-30 minutes
**No Docker knowledge required!**
**Automatic deployments from GitHub!**
