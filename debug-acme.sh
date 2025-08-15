#!/bin/bash

echo "🔍 ACME Challenge Diagnostic Tool"
echo "================================="

echo ""
echo "1. Checking nginx service status..."
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
    echo "Starting nginx..."
    sudo systemctl start nginx
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx started successfully"
    else
        echo "❌ Failed to start nginx"
        sudo systemctl status nginx --no-pager -l
        exit 1
    fi
fi

echo ""
echo "2. Checking nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "3. Checking port 80..."
if sudo ss -tulpn | grep -q ":80 "; then
    echo "✅ Port 80 is listening"
    sudo ss -tulpn | grep ":80 "
else
    echo "❌ Port 80 is not listening"
fi

echo ""
echo "4. Checking ACME challenge directory..."
if [ -d "/var/www/yardeespaces/.well-known/acme-challenge" ]; then
    echo "✅ ACME challenge directory exists"
    echo "Permissions: $(ls -ld /var/www/yardeespaces/.well-known/acme-challenge)"
else
    echo "❌ ACME challenge directory does not exist"
    echo "Creating it..."
    sudo mkdir -p /var/www/yardeespaces/.well-known/acme-challenge
    sudo chown -R www-data:www-data /var/www/yardeespaces
    sudo chmod -R 755 /var/www/yardeespaces
fi

echo ""
echo "5. Creating test file..."
sudo tee /var/www/yardeespaces/.well-known/acme-challenge/test > /dev/null << 'EOF'
test-acme-challenge-working
EOF

echo ""
echo "6. Testing local access..."
if curl -s http://localhost/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ Local ACME challenge access works"
else
    echo "❌ Local ACME challenge access failed"
    echo "Nginx error log:"
    sudo tail -n 5 /var/log/nginx/error.log
fi

echo ""
echo "7. Testing external access..."
if curl -s http://yardeespaces.com/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ External ACME challenge access works"
else
    echo "❌ External ACME challenge access failed"
    echo ""
    echo "8. DNS check..."
    echo "yardeespaces.com resolves to:"
    nslookup yardeespaces.com 2>/dev/null | grep "Address:" | tail -1
    echo ""
    echo "9. Firewall check..."
    echo "UFW status:"
    sudo ufw status
    echo ""
    echo "10. Testing with IP address..."
    SERVER_IP=$(curl -s ifconfig.me)
    echo "Server IP: $SERVER_IP"
    if curl -s http://$SERVER_IP/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
        echo "✅ ACME challenge works with IP address"
        echo "This suggests a DNS issue"
    else
        echo "❌ ACME challenge doesn't work with IP address"
        echo "This suggests a firewall or nginx configuration issue"
    fi
fi

echo ""
echo "11. Cleaning up test file..."
sudo rm -f /var/www/yardeespaces/.well-known/acme-challenge/test

echo ""
echo "🔍 Diagnostic complete!"
