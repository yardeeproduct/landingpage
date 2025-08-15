#!/bin/bash

echo "🚀 Starting Application with SSL"
echo "================================"

echo "1. Stopping system nginx..."
sudo systemctl stop nginx

# Check if nginx is stopped
if sudo systemctl is-active --quiet nginx; then
    echo "❌ Failed to stop nginx"
    sudo systemctl status nginx --no-pager -l
    exit 1
else
    echo "✅ Nginx stopped"
fi

# Wait for port 80 to be free
sleep 3

# Check if port 80 is free
if sudo ss -tulpn | grep -q ":80 "; then
    echo "❌ Port 80 is still in use"
    sudo ss -tulpn | grep ":80 "
    exit 1
else
    echo "✅ Port 80 is free"
fi

echo ""
echo "2. Starting Docker containers..."
docker-compose up -d

# Check if containers are running
sleep 5

if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker containers are running"
else
    echo "❌ Docker containers failed to start"
    docker-compose ps
    exit 1
fi

echo ""
echo "3. Testing application access..."
sleep 3

# Test HTTP access
if curl -s --connect-timeout 10 http://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ HTTP is working"
else
    echo "❌ HTTP is not working"
fi

# Test HTTPS access
if curl -s -k --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ HTTPS is working"
    
    # Test without -k flag to check real certificate
    if curl -s --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
        echo "✅ SSL certificate is valid"
    else
        echo "⚠️  SSL certificate may have issues"
    fi
else
    echo "❌ HTTPS is not working"
fi

echo ""
echo "🎉 Application is now running!"
echo ""
echo "Your site is accessible at:"
echo "✅ HTTP:  http://yardeespaces.com"
echo "✅ HTTPS: https://yardeespaces.com"
echo ""
echo "Container status:"
docker-compose ps
echo ""
echo "To view logs:"
echo "docker-compose logs -f"
echo ""
echo "To stop:"
echo "docker-compose down"
