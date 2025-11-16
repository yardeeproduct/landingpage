# Deployment Guide for Yardee Spaces

This guide covers deploying the Yardee Spaces landing page to production.

## Prerequisites

- Docker and Docker Compose installed on the server
- Domain name configured (yardeespaces.com and www.yardeespaces.com)
- SSL certificates (Let's Encrypt recommended)
- Azure SQL Database credentials
- Email credentials (Outlook 365 Business)

## Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Django Settings
DEBUG=false
SECRET_KEY=your-secret-key-here-change-in-production
DJANGO_SETTINGS_MODULE=backend.settings

# Database Configuration (Azure SQL)
DB_HOST=your-azure-sql-server.database.windows.net
DB_NAME=yardee_subscribers
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_PORT=1433

# Security
CORS_ALLOW_ALL_ORIGINS=False
SECURE_SSL_REDIRECT=True

# Email Configuration (Outlook 365 Business)
EMAIL_HOST_USER=no-reply@yardeespaces.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=Yardee Spaces <no-reply@yardeespaces.com>
EMAIL_SUBJECT_PREFIX=[Yardee Spaces] 

# Company Information
COMPANY_NAME=Yardee Spaces
EMAIL_LOGO_URL=https://yardeespaces.com/assets/images/logo.svg
COMPANY_WEBSITE_URL=https://yardeespaces.com
COMPANY_ADDRESS=Yardee Spaces, Toronto, ON, Canada
COMPANY_LINKEDIN_URL=https://linkedin.com/company/yardeespaces
COMPANY_TWITTER_URL=https://twitter.com/yardeespaces
COMPANY_INSTAGRAM_URL=https://www.instagram.com/yardeespaces/
COMPANY_FACEBOOK_URL=https://www.facebook.com/yardeespaces/

# Frontend (optional, for API URL override)
VITE_API_BASE_URL=
```

## Deployment Steps

### 1. Server Setup

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose (if not included)
sudo apt-get install docker-compose-plugin -y

# Install Nginx (for reverse proxy and SSL termination)
sudo apt-get install nginx certbot python3-certbot-nginx -y
```

### 2. Firewall Configuration

```bash
# Allow HTTP, HTTPS, and SSH
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

### 3. DNS Configuration

Ensure your DNS records point to your server's IP:

```
A     yardeespaces.com        -> YOUR_SERVER_IP
A     www.yardeespaces.com    -> YOUR_SERVER_IP
```

Verify DNS:
```bash
dig yardeespaces.com
dig www.yardeespaces.com
```

### 4. SSL Certificate Setup

```bash
# Get SSL certificates using Let's Encrypt
sudo certbot certonly --standalone -d yardeespaces.com -d www.yardeespaces.com

# Certificates will be stored at:
# /etc/letsencrypt/live/yardeespaces.com/fullchain.pem
# /etc/letsencrypt/live/yardeespaces.com/privkey.pem
```

### 5. Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/yardeespaces.com`:

```nginx
# HTTP - Redirect to HTTPS
server {
    listen 80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yardeespaces.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yardeespaces.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Proxy to Docker frontend
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Proxy API requests directly to backend
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/yardeespaces.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Deploy Application

```bash
# Clone repository (if not already done)
git clone <your-repo-url>
cd landingpage

# Create .env file with production values
nano .env

# Build and start containers
docker-compose build
docker-compose up -d

# Check logs
docker-compose logs -f

# Verify containers are running
docker-compose ps
```

### 7. Verify Deployment

```bash
# Check container health
docker-compose ps

# Test HTTP endpoint
curl -I http://localhost/api/health/

# Test from external machine
curl -I https://www.yardeespaces.com
curl -I https://www.yardeespaces.com/api/health/
```

### 8. Auto-renewal SSL Certificates

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot will auto-renew, but ensure Nginx reloads
# Add to crontab:
sudo crontab -e
# Add: 0 0 * * * certbot renew --quiet && systemctl reload nginx
```

## Maintenance

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Update Application
```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose build
docker-compose up -d

# Or restart specific service
docker-compose restart backend
docker-compose restart frontend
```

### Backup Database
```bash
# Azure SQL backups are handled automatically
# For manual backup, use Azure Portal or Azure CLI
```

## Troubleshooting

### Containers won't start
```bash
# Check logs
docker-compose logs

# Check environment variables
docker-compose config

# Verify .env file exists and has correct values
cat .env
```

### Database connection issues
```bash
# Check Azure SQL firewall rules
# Ensure VM IP is allowed in Azure SQL firewall

# Test connection from container
docker-compose exec backend python -c "import pyodbc; print('OK')"
```

### SSL certificate issues
```bash
# Check certificate expiration
sudo certbot certificates

# Renew manually
sudo certbot renew

# Verify Nginx config
sudo nginx -t
```

### Port conflicts
```bash
# Check if ports are in use
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443
sudo netstat -tulpn | grep :8000

# Stop conflicting services
sudo systemctl stop apache2  # if Apache is running
```

## Security Checklist

- [ ] DEBUG is set to `false` in production
- [ ] SECRET_KEY is strong and unique
- [ ] Database credentials are secure
- [ ] SSL certificates are valid and auto-renewing
- [ ] Firewall is configured correctly
- [ ] Docker containers run as non-root users
- [ ] Regular security updates are applied
- [ ] Backups are configured
- [ ] Monitoring is set up

## Monitoring

Consider setting up:
- Uptime monitoring (UptimeRobot, Pingdom)
- Error tracking (Sentry)
- Log aggregation (ELK Stack, CloudWatch)
- Performance monitoring (New Relic, Datadog)

## Support

For issues or questions, contact the development team.

