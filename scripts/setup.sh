#!/bin/bash

# =================================
# PROMPT FLOW SETUP SCRIPT (Unix/Linux/macOS)
# =================================

set -e

echo "🚀 Setting up Prompt Flow development environment..."

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

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Prerequisites check passed!"

# Create environment file
print_status "Setting up environment configuration..."
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    print_success "Created backend/.env from template"
    print_warning "Please edit backend/.env with your API keys and configuration"
else
    print_warning "backend/.env already exists, skipping copy"
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x debug-poetry.sh
chmod +x scripts/*.sh 2>/dev/null || true
print_success "Scripts are now executable"

# Build and start services
print_status "Building and starting services..."
docker-compose down 2>/dev/null || true
docker-compose build --no-cache
docker-compose up -d

print_status "Waiting for services to be ready..."
sleep 10

# Health checks
print_status "Performing health checks..."
if curl -f http://localhost:8000/health &>/dev/null; then
    print_success "Backend is healthy!"
else
    print_warning "Backend health check failed, check logs with: docker-compose logs backend"
fi

if curl -f http://localhost:3000 &>/dev/null; then
    print_success "Frontend is accessible!"
else
    print_warning "Frontend not accessible, check logs with: docker-compose logs frontend"
fi

print_success "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit backend/.env with your API keys"
echo "2. Access the application:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:8000"
echo "   - API Docs: http://localhost:8000/docs"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f [service]"
echo "  - Debug Poetry: ./debug-poetry.sh"
echo "  - Stop services: docker-compose down"
echo ""
print_success "Happy coding! 🚀"
