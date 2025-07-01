#!/bin/bash

echo "🚀 Yardee Spaces Production Deployment Script"
echo "============================================="

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

# Check if running as non-root user
if [ "$EUID" -eq 0 ]; then 
    print_error "Please run this script as a non-root user (not with sudo)"
    exit 1
fi

print_info "Starting Yardee Spaces deployment..."

# Step 1: Update system packages
print_info "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_status "System packages updated"

# Step 2: Install required packages
print_info "Step 2: Installing required packages..."
sudo apt install -y git docker.io docker-compose nginx certbot python3-certbot-nginx curl ufw
print_status "Required packages installed"

# Step 3: Setup Docker
print_info "Step 3: Setting up Docker..."
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
print_status "Docker setup completed"

# Step 4: Setup firewall
print_info "Step 4: Configuring firewall..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Docker frontend (temporary)
sudo ufw allow 8000/tcp  # Docker backend (temporary)
sudo ufw --force enable
print_status "Firewall configured"

# Step 5: Clone/Update repository
REPO_DIR="$HOME/yardeespaces-production"
if [ -d "$REPO_DIR" ]; then
    print_info "Step 5: Updating existing repository..."
    cd "$REPO_DIR"
    git pull origin main
else
    print_info "Step 5: Cloning repository..."
    cd "$HOME"
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git yardeespaces-production
    cd yardeespaces-production
fi
print_status "Repository ready"

# Step 6: Setup environment variables
print_info "Step 6: Setting up environment variables..."
if [ ! -f "backend/.env" ]; then
    cat > backend/.env << EOF
# Database Configuration
DB_NAME=yardee_subscribers
DB_USER=sa
DB_PASSWORD=Yardeespaces123!
DB_HOST=db
DB_PORT=1433

# Django Settings
DEBUG=0
SECRET_KEY=your-super-secret-production-key-change-this-$(openssl rand -hex 32)

# Performance Settings
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
EOF
    print_status "Environment variables created"
else
    print_warning "Environment file already exists"
fi

# Step 7: Setup nginx configuration
print_info "Step 7: Setting up nginx configuration..."
sudo mkdir -p /var/www/yardeespaces
sudo chown -R www-data:www-data /var/www/yardeespaces

# Create index.html
sudo tee /var/www/yardeespaces/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Yardee Spaces</title>
    <meta http-equiv="refresh" content="0; url=http://yardeespaces.com:3000">
</head>
<body>
    <h1>Yardee Spaces - Loading...</h1>
    <p>If you are not redirected automatically, <a href="http://yardeespaces.com:3000">click here</a>.</p>
</body>
</html>
EOF

# Remove default nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Create nginx configuration
sudo tee /etc/nginx/sites-available/yardeespaces > /dev/null << 'EOF'
server {
    listen 80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Root directory for serving files
    root /var/www/yardeespaces;
    index index.html index.htm;
    
    # Let's Encrypt ACME challenge location (must be first)
    location /.well-known/acme-challenge/ {
        root /var/www/yardeespaces;
        try_files $uri =404;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
    }
    
    # Proxy all other requests to frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/

# Test nginx configuration
if sudo nginx -t; then
    sudo systemctl reload nginx
    print_status "Nginx configuration updated"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Step 8: Build and start Docker containers
print_info "Step 8: Building and starting Docker containers..."
newgrp docker << EONG
docker-compose down
docker-compose build
docker-compose up -d
EONG

print_status "Docker containers started"

# Step 9: Wait for containers to be healthy
print_info "Step 9: Waiting for containers to be healthy..."
sleep 30

# Check container status
if docker-compose ps | grep -q "healthy"; then
    print_status "Containers are healthy"
else
    print_warning "Some containers may not be healthy yet. Check with: docker-compose ps"
fi

# Step 10: Test the deployment
print_info "Step 10: Testing deployment..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend may not be ready yet"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health/ | grep -q "200"; then
    print_status "Backend API is responding"
else
    print_warning "Backend API may not be ready yet"
fi

echo ""
echo "🎉 Deployment completed!"
echo "======================================"
echo ""
print_info "Next steps:"
echo "1. Test your site: http://yardeespaces.com"
echo "2. Setup SSL certificate:"
echo "   sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
echo ""
print_info "Useful commands:"
echo "• Check container status: docker-compose ps"
echo "• View logs: docker-compose logs"
echo "• Restart containers: docker-compose restart"
echo "• Check nginx status: sudo systemctl status nginx"
echo ""
print_warning "Important: You may need to log out and back in for Docker group changes to take effect"
