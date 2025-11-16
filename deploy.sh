#!/bin/bash
# Production deployment script for Yardee Spaces
# Usage: ./deploy.sh

set -e

echo "🚀 Starting deployment for Yardee Spaces..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create .env file from .env.production.example"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running!${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Error: docker-compose is not installed!${NC}"
    exit 1
fi

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${YELLOW}📦 Building Docker images...${NC}"
$DOCKER_COMPOSE build --no-cache

echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
$DOCKER_COMPOSE down

echo -e "${YELLOW}🚀 Starting containers...${NC}"
$DOCKER_COMPOSE up -d

echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"
sleep 10

# Check container status
echo -e "${YELLOW}📊 Checking container status...${NC}"
$DOCKER_COMPOSE ps

# Test health endpoints
echo -e "${YELLOW}🏥 Testing health endpoints...${NC}"

# Test backend health
if curl -f http://localhost:8000/api/health/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend health check passed${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    echo "Backend logs:"
    $DOCKER_COMPOSE logs backend --tail=50
    exit 1
fi

# Test frontend health
if curl -f http://localhost:80/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend health check passed${NC}"
else
    echo -e "${RED}❌ Frontend health check failed${NC}"
    echo "Frontend logs:"
    $DOCKER_COMPOSE logs frontend --tail=50
    exit 1
fi

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Verify DNS is pointing to this server"
echo "2. Configure SSL certificates (see DEPLOYMENT.md)"
echo "3. Set up reverse proxy (see DEPLOYMENT.md)"
echo ""
echo "📊 View logs: $DOCKER_COMPOSE logs -f"
echo "🛑 Stop services: $DOCKER_COMPOSE down"
echo "🔄 Restart services: $DOCKER_COMPOSE restart"

