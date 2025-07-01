#!/bin/bash

echo "=== Setting up Nginx for Yardee Spaces ==="

# Create web root directory
sudo mkdir -p /var/www/yardeespaces
sudo chown -R www-data:www-data /var/www/yardeespaces

# Create a simple index.html for ACME challenge verification
sudo tee /var/www/yardeespaces/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Yardee Spaces</title>
</head>
<body>
    <h1>Yardee Spaces - Loading...</h1>
    <script>
        // Redirect to Docker container
        window.location.href = 'http://' + window.location.hostname + ':3000';
    </script>
</body>
</html>
EOF

# Remove default nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Create nginx configuration for yardeespaces.com
sudo tee /etc/nginx/sites-available/yardeespaces > /dev/null << 'EOF'
server {
    listen 80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Root directory for serving files
    root /var/www/yardeespaces;
    index index.html index.htm;
    
    # Serve static files and handle SPA routing
    location / {
        try_files $uri $uri/ @docker;
    }
    
    # Proxy to Docker containers when file not found
    location @docker {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }
    
    # Let's Encrypt ACME challenge location
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
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Reload nginx
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    sudo systemctl restart nginx
    
    echo "✅ Nginx setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Verify your site is accessible: http://yardeespaces.com"
    echo "2. Run SSL certificate setup: sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
    
else
    echo "❌ Nginx configuration has errors. Please fix them before proceeding."
    exit 1
fi
