#!/bin/bash

echo "🔍 Finding SSL Certificate Location"
echo "==================================="

echo "1. Checking common certificate locations..."

# Check standard locations
LOCATIONS=(
    "/etc/letsencrypt/live/yardeespaces.com/fullchain.pem"
    "/etc/letsencrypt/live/yardeespaces.com/cert.pem"
    "/etc/letsencrypt/archive/yardeespaces.com/cert*.pem"
    "/etc/ssl/certs/yardeespaces.com.crt"
    "/etc/ssl/private/yardeespaces.com.key"
)

FOUND_CERT=""
FOUND_KEY=""

for location in "${LOCATIONS[@]}"; do
    if ls $location 2>/dev/null | head -1; then
        echo "✅ Found certificate at: $location"
        FOUND_CERT=$(ls $location 2>/dev/null | head -1)
        break
    fi
done

# Check for private key
KEY_LOCATIONS=(
    "/etc/letsencrypt/live/yardeespaces.com/privkey.pem"
    "/etc/letsencrypt/archive/yardeespaces.com/privkey*.pem"
    "/etc/ssl/private/yardeespaces.com.key"
)

for location in "${KEY_LOCATIONS[@]}"; do
    if ls $location 2>/dev/null | head -1; then
        echo "✅ Found private key at: $location"
        FOUND_KEY=$(ls $location 2>/dev/null | head -1)
        break
    fi
done

echo ""
echo "2. Checking certbot certificates list..."
sudo certbot certificates

echo ""
echo "3. Checking letsencrypt directory structure..."
if [ -d "/etc/letsencrypt" ]; then
    echo "✅ /etc/letsencrypt directory exists"
    echo "Contents:"
    ls -la /etc/letsencrypt/
    
    if [ -d "/etc/letsencrypt/live" ]; then
        echo ""
        echo "Live certificates:"
        ls -la /etc/letsencrypt/live/
        
        if [ -d "/etc/letsencrypt/live/yardeespaces.com" ]; then
            echo ""
            echo "Yardee Spaces certificate files:"
            ls -la /etc/letsencrypt/live/yardeespaces.com/
        fi
    fi
    
    if [ -d "/etc/letsencrypt/archive" ]; then
        echo ""
        echo "Archive certificates:"
        ls -la /etc/letsencrypt/archive/
        
        if [ -d "/etc/letsencrypt/archive/yardeespaces.com" ]; then
            echo ""
            echo "Yardee Spaces archive files:"
            ls -la /etc/letsencrypt/archive/yardeespaces.com/
        fi
    fi
else
    echo "❌ /etc/letsencrypt directory not found"
fi

echo ""
echo "4. Checking certificate validity..."
if [ -n "$FOUND_CERT" ]; then
    echo "Certificate: $FOUND_CERT"
    echo "Certificate details:"
    openssl x509 -in "$FOUND_CERT" -noout -subject -issuer -dates
else
    echo "❌ No certificate found"
fi

echo ""
echo "5. Summary:"
if [ -n "$FOUND_CERT" ] && [ -n "$FOUND_KEY" ]; then
    echo "✅ Certificate and key found"
    echo "Certificate: $FOUND_CERT"
    echo "Private key: $FOUND_KEY"
    echo ""
    echo "To configure nginx, update the paths in nginx-yardeespaces-ssl.conf:"
    echo "ssl_certificate $FOUND_CERT;"
    echo "ssl_certificate_key $FOUND_KEY;"
else
    echo "❌ Certificate or key not found"
    echo "You may need to obtain a new certificate"
fi
