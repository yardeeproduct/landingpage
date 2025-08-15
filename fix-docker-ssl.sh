#!/bin/bash

echo "🔧 Fixing Docker SSL Configuration"
echo "=================================="

echo "1. Checking current nginx container..."
docker ps | grep nginx

echo ""
echo "2. Checking nginx configuration in container..."
docker exec landingpage_nginx cat /etc/nginx/conf.d/default.conf

echo ""
echo "3. Copying SSL certificate to nginx container..."

# Create SSL directory in nginx container
docker exec landingpage_nginx mkdir -p /etc/nginx/ssl

# Copy certificate files to nginx container
sudo cp /etc/letsencrypt/live/yardeespaces.com/fullchain.pem /tmp/fullchain.pem
sudo cp /etc/letsencrypt/live/yardeespaces.com/privkey.pem /tmp/privkey.pem
sudo chown $USER:$USER /tmp/fullchain.pem /tmp/privkey.pem

docker cp /tmp/fullchain.pem landingpage_nginx:/etc/nginx/ssl/
docker cp /tmp/privkey.pem landingpage_nginx:/etc/nginx/ssl/

# Clean up temp files
rm /tmp/fullchain.pem /tmp/privkey.pem

echo ""
echo "4. Creating SSL nginx configuration..."

# Create SSL nginx config
cat > /tmp/nginx-ssl.conf << 'EOF'
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Let's Encrypt ACME challenge location (for renewals)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
        allow all;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server configuration
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL settings for security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Root directory for serving files
    root /var/www/html;
    index index.html index.htm;
    
    # Let's Encrypt ACME challenge location (for renewals)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
        allow all;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
    }
    
    # Serve static files and handle SPA routing
    location / {
        try_files $uri $uri/ @frontend;
    }
    
    # Proxy to frontend when file not found
    location @frontend {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Copy SSL config to nginx container
docker cp /tmp/nginx-ssl.conf landingpage_nginx:/etc/nginx/conf.d/default.conf

# Clean up temp file
rm /tmp/nginx-ssl.conf

echo ""
echo "5. Testing nginx configuration in container..."
docker exec landingpage_nginx nginx -t

echo ""
echo "6. Reloading nginx configuration..."
docker exec landingpage_nginx nginx -s reload

echo ""
echo "7. Testing HTTPS access..."
sleep 3

if curl -s -k --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ HTTPS is working"
    
    # Test without -k flag to check real certificate
    if curl -s --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
        echo "✅ SSL certificate is valid"
    else
        echo "⚠️  SSL certificate may have issues"
    fi
    
    echo ""
    echo "🎉 HTTPS is now working!"
    echo ""
    echo "Your site is accessible at:"
    echo "✅ HTTP:  http://yardeespaces.com"
    echo "✅ HTTPS: https://yardeespaces.com"
    
else
    echo "❌ HTTPS is still not working"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check nginx logs: docker logs landingpage_nginx"
    echo "2. Check nginx config: docker exec landingpage_nginx nginx -t"
    echo "3. Test with: curl -k https://yardeespaces.com"
fi
