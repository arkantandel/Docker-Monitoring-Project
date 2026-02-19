#!/bin/bash

set -e

echo "======================================"
echo "Docker Monitoring Stack Initializer"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "[1/5] Checking prerequisites..."
echo "✓ Docker is installed: $(docker --version)"
echo "✓ Docker Compose is installed: $(docker-compose --version)"
echo ""

echo "[2/5] Stopping any existing containers..."
docker-compose down --remove-orphans || true
echo "✓ Done"
echo ""

echo "[3/5] Building Docker images..."
docker-compose build
echo "✓ Images built successfully"
echo ""

echo "[4/5] Starting the monitoring stack..."
docker-compose up -d
echo "✓ Stack started"
echo ""

echo "[5/5] Waiting for services to be ready..."
sleep 5

# Check if containers are running
echo ""
echo "======================================"
echo "Container Status:"
echo "======================================"
docker-compose ps
echo ""

echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Access the services at:"
echo "  • Grafana (Dashboard):  http://localhost/grafana"
echo "  • Prometheus (Metrics): http://localhost/prometheus"
echo "  • Health Check:         http://localhost/health"
echo ""
echo "Default Grafana Credentials:"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "To stop the stack:"
echo "  docker-compose down"
echo ""
echo "To remove all data volumes:"
echo "  docker-compose down -v"
echo ""
