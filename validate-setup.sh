#!/bin/bash

# Project Setup Validation Script
# This script validates that the project is ready for deployment

set -e

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

print_info "Starting project validation..."

# Check if required files exist
print_info "Checking required files..."

required_files=(
    "Dockerfile.backend"
    "Dockerfile.frontend"
    "docker-compose.yml"
    "docker-compose.azure.yml"
    "backend/requirements.txt"
    "backend/manage.py"
    "frontend/package.json"
    "frontend/nginx.conf"
    ".gitignore"
    ".dockerignore"
    "README.md"
    "azure-deployment.md"
    ".github/workflows/azure-deploy.yml"
)

missing_files=()

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_error "Missing: $file"
        missing_files+=("$file")
    fi
done

# Check if directories exist
print_info "Checking required directories..."

required_dirs=(
    "backend"
    "frontend"
    "frontend/src"
    "frontend/public"
    ".github/workflows"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status "Found directory: $dir"
    else
        print_error "Missing directory: $dir"
        missing_files+=("$dir")
    fi
done

# Check Docker installation
print_info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    print_status "Docker is installed"
    docker_version=$(docker --version)
    print_info "Docker version: $docker_version"
else
    print_warning "Docker is not installed (required for local development)"
fi

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    print_status "Docker Compose is installed"
elif docker compose version &> /dev/null; then
    print_status "Docker Compose (plugin) is available"
else
    print_warning "Docker Compose is not available"
fi

# Check Python installation
print_info "Checking Python installation..."
if command -v python3 &> /dev/null; then
    print_status "Python 3 is installed"
    python_version=$(python3 --version)
    print_info "Python version: $python_version"
else
    print_warning "Python 3 is not installed (required for backend development)"
fi

# Check Node.js installation
print_info "Checking Node.js installation..."
if command -v node &> /dev/null; then
    print_status "Node.js is installed"
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_info "Node version: $node_version"
    print_info "NPM version: $npm_version"
else
    print_warning "Node.js is not installed (required for frontend development)"
fi

# Check Azure CLI installation
print_info "Checking Azure CLI installation..."
if command -v az &> /dev/null; then
    print_status "Azure CLI is installed"
    az_version=$(az version --query '"azure-cli"' --output tsv)
    print_info "Azure CLI version: $az_version"
else
    print_warning "Azure CLI is not installed (required for Azure deployment)"
fi

# Check if environment files exist
print_info "Checking environment configuration..."
if [ -f "backend/env.example" ]; then
    print_status "Environment example file found"
else
    print_warning "Environment example file not found"
fi

# Check Dockerfile syntax (basic check)
print_info "Validating Dockerfiles..."
if grep -q "FROM" Dockerfile.backend; then
    print_status "Backend Dockerfile has FROM instruction"
else
    print_error "Backend Dockerfile missing FROM instruction"
fi

if grep -q "FROM" Dockerfile.frontend; then
    print_status "Frontend Dockerfile has FROM instruction"
else
    print_error "Frontend Dockerfile missing FROM instruction"
fi

# Check if GitHub Actions workflow is valid
print_info "Validating GitHub Actions workflow..."
if [ -f ".github/workflows/azure-deploy.yml" ]; then
    if grep -q "name:" .github/workflows/azure-deploy.yml && grep -q "on:" .github/workflows/azure-deploy.yml; then
        print_status "GitHub Actions workflow appears valid"
    else
        print_warning "GitHub Actions workflow may have issues"
    fi
fi

# Check project structure
print_info "Validating project structure..."

# Check if backend has required Django files
if [ -f "backend/backend/settings.py" ] && [ -f "backend/backend/urls.py" ] && [ -f "backend/manage.py" ]; then
    print_status "Django backend structure looks correct"
else
    print_error "Django backend structure is incomplete"
fi

# Check if frontend has required files
if [ -f "frontend/package.json" ] && [ -f "frontend/src/main.js" ] && [ -f "frontend/index.html" ]; then
    print_status "Frontend structure looks correct"
else
    print_error "Frontend structure is incomplete"
fi

# Summary
echo ""
echo "======================================"
if [ ${#missing_files[@]} -eq 0 ]; then
    print_status "All required files and directories found!"
    echo ""
    print_info "Project is ready for deployment!"
    echo ""
    print_info "Next steps:"
    echo "1. Set up environment variables (copy backend/env.example to backend/.env)"
    echo "2. Test locally: docker-compose up --build"
    echo "3. Deploy to Azure: ./deploy-azure.sh"
    echo "4. Or follow the detailed guide: azure-deployment.md"
else
    print_error "Found ${#missing_files[@]} missing files/directories:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    print_warning "Please ensure all required files are present before deployment"
fi

echo ""
print_info "Validation complete!"
