# Yardee Spaces Deployment Guide

## 🚀 Quick Deployment Instructions

### Prerequisites
- Ubuntu/Debian Linux server
- Domain name pointing to your server IP
- SSH access to the server

### Step 1: Connect to Your Linux Server
```bash
ssh azureuser@20.151.76.30
```

### Step 2: Clone the Repository
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git yardeespaces-production
cd yardeespaces-production
```

### Step 3: Run the Deployment Script
```bash
chmod +x deploy.sh
./deploy.sh
```

### Step 4: Setup SSL Certificate (After Testing)
```bash
sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com
```

## 🔧 Manual Setup (Alternative)

If the automatic script doesn't work, follow these manual steps:

### 1. Install Dependencies
```bash
sudo apt update
sudo apt install -y git docker.io docker-compose nginx certbot python3-certbot-nginx curl
```

### 2. Setup Docker
```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### 3. Configure Environment
```bash
cd yardeespaces-production
cp backend/.env.example backend/.env
# Edit backend/.env with your settings
```

### 4. Build and Start Containers
```bash
docker-compose build
docker-compose up -d
```

### 5. Setup Nginx
```bash
sudo ./setup-nginx.sh
```

### 6. Setup SSL
```bash
sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com
```

## 🔍 Troubleshooting

### Check Container Status
```bash
docker-compose ps
docker-compose logs
```

### Check Nginx Status
```bash
sudo nginx -t
sudo systemctl status nginx
```

### Test Endpoints
```bash
curl http://localhost:3000        # Frontend
curl http://localhost:8000/api/health/  # Backend
curl http://yardeespaces.com      # Public access
```

### View Container Logs
```bash
docker-compose logs backend   # Backend logs
docker-compose logs frontend  # Frontend logs
```

### Restart Services
```bash
docker-compose restart        # Restart containers
sudo systemctl restart nginx  # Restart nginx
```

## 📁 Important Files

- `docker-compose.yml` - Container orchestration
- `backend/.env` - Backend environment variables
- `frontend/.env.production` - Frontend production settings
- `nginx-yardeespaces.conf` - Nginx configuration
- `setup-nginx.sh` - Nginx setup script
- `deploy.sh` - Full deployment script

## 🌐 URLs After Deployment

- **Production Site**: https://yardeespaces.com
- **API Endpoint**: https://yardeespaces.com/api/subscribe/
- **Container Frontend**: http://20.151.76.30:3000
- **Container Backend**: http://20.151.76.30:8000

## 🔐 Security Notes

- Change the default `SECRET_KEY` in `backend/.env`
- Set `DEBUG=0` in production
- Configure proper firewall rules
- Use strong database passwords
- Keep SSL certificates updated
