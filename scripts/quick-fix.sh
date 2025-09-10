#!/bin/bash

# =================================
# QUICK FIX FOR POETRY PACKAGE-MODE ERROR
# =================================

set -e

echo "🔧 Fixing Poetry package-mode compatibility issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop any running containers
print_status "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Clean up Docker build cache
print_status "Cleaning Docker build cache..."
docker system prune -f 2>/dev/null || true

# Check if pyproject.toml has the problematic line
if grep -q "package-mode = false" backend/pyproject.toml 2>/dev/null; then
    print_warning "Found 'package-mode = false' in pyproject.toml"
    print_status "Removing unsupported package-mode line..."
    
    # Create backup
    cp backend/pyproject.toml backend/pyproject.toml.backup
    
    # Remove the problematic line
    grep -v "package-mode = false" backend/pyproject.toml.backup > backend/pyproject.toml
    
    print_success "Removed package-mode line from pyproject.toml"
else
    print_success "pyproject.toml is already compatible"
fi

# Rebuild the backend image
print_status "Rebuilding backend image..."
if docker-compose build --no-cache backend; then
    print_success "Backend image rebuilt successfully!"
else
    print_error "Failed to rebuild backend image"
    exit 1
fi

# Start the services
print_status "Starting all services..."
if docker-compose up -d; then
    print_success "All services started successfully!"
else
    print_error "Failed to start services"
    exit 1
fi

# Wait a moment for services to initialize
print_status "Waiting for services to initialize..."
sleep 5

# Check service status
print_status "Checking service status..."
docker-compose ps

# Test backend health
print_status "Testing backend health..."
if curl -f http://localhost:8000/health 2>/dev/null; then
    print_success "Backend is healthy and responding!"
else
    print_warning "Backend health check failed, but services are running"
    print_status "Check logs with: docker-compose logs backend"
fi

echo ""
print_success "🎉 Fix applied successfully!"
echo ""
echo "Next steps:"
echo "1. Check service status: docker-compose ps"
echo "2. View logs: docker-compose logs [service-name]"
echo "3. Access frontend: http://localhost:3000"
echo "4. Access backend API docs: http://localhost:8000/docs"
echo ""
print_success "Happy coding! 🚀"
