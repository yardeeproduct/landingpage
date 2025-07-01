#!/bin/bash

echo "🔧 Fixing SSL Certificate Setup for Yardee Spaces"
echo "================================================="

# Stop any existing containers to free up ports
echo "Stopping Docker containers temporarily..."
docker-compose down

# Create the ACME challenge directory with proper permissions
echo "Setting up ACME challenge directory..."
sudo mkdir -p /var/www/yardeespaces/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/yardeespaces
sudo chmod -R 755 /var/www/yardeespaces

# Create a test file to verify ACME challenge works
echo "Creating test file for ACME challenge verification..."
sudo tee /var/www/yardeespaces/.well-known/acme-challenge/test > /dev/null << 'EOF'
test-acme-challenge
EOF

# Update nginx configuration for proper ACME handling
echo "Updating nginx configuration..."
sudo tee /etc/nginx/sites-available/yardeespaces > /dev/null << 'EOF'
server {
    listen 80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Root directory
    root /var/www/yardeespaces;
    index index.html index.htm;
    
    # ACME challenge location (highest priority)
    location /.well-known/acme-challenge/ {
        root /var/www/yardeespaces;
        try_files $uri =404;
        allow all;
        access_log /var/log/nginx/acme.log;
    }
    
    # Proxy API requests to backend (when containers are running)
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Handle when backend is not available
        proxy_connect_timeout 1s;
        proxy_send_timeout 1s;
        proxy_read_timeout 1s;
        
        # Fallback for when Docker is down
        error_page 502 503 504 /50x.html;
    }
    
    # Proxy everything else to frontend (when containers are running)
    location / {
        # Try to proxy to Docker, fallback to static file
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_Set_header X-Forwarded-Proto $scheme;
        
        # Handle when frontend is not available
        proxy_connect_timeout 1s;
        proxy_send_timeout 1s;
        proxy_read_timeout 1s;
        
        # Fallback when Docker is down
        error_page 502 503 504 /index.html;
    }
    
    # Error page
    location = /50x.html {
        root /var/www/yardeespaces;
        internal;
    }
}
EOF

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl reload nginx
else
    echo "❌ Nginx configuration has errors!"
    exit 1
fi

# Test ACME challenge directory access
echo "Testing ACME challenge access..."
if curl -s http://yardeespaces.com/.well-known/acme-challenge/test | grep -q "test-acme-challenge"; then
    echo "✅ ACME challenge directory is accessible"
    
    # Clean up test file
    sudo rm -f /var/www/yardeespaces/.well-known/acme-challenge/test
    
    echo ""
    echo "🎉 Ready for SSL certificate setup!"
    echo "Run: sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
    
else
    echo "❌ ACME challenge directory is not accessible"
    echo "Please check the nginx configuration and domain DNS settings"
    exit 1
fi

echo ""
echo "After SSL setup completes, restart Docker containers:"
echo "docker-compose up -d"
