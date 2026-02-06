#!/bin/bash

echo "=========================================="
echo "Starting AWX Local Environment"
echo "=========================================="
echo ""

# Check if AWX is already running
if docker ps | grep -q awx-web; then
    echo "⚠️  AWX containers are already running"
    echo ""
    read -p "Do you want to restart AWX? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping existing AWX containers..."
        docker-compose -f docker-compose-awx.yml down
    else
        echo "Using existing AWX instance"
        echo "AWX Web UI: http://localhost:8081"
        echo "Username: admin"
        echo "Password: Cloudflare@2025"
        exit 0
    fi
fi

echo "Starting AWX containers (this may take a few minutes)..."
docker-compose -f docker-compose-awx.yml up -d

echo ""
echo "Waiting for AWX to initialize (60 seconds)..."
sleep 60

echo ""
echo "=========================================="
echo "✓ AWX Started Successfully!"
echo "=========================================="
echo ""
echo "Access AWX Web Interface:"
echo "  URL: http://localhost:8081"
echo "  Username: admin"
echo "  Password: Cloudflare@2025"
echo ""
echo "Check container status:"
echo "  docker-compose -f docker-compose-awx.yml ps"
echo ""
echo "View logs:"
echo "  docker-compose -f docker-compose-awx.yml logs -f awx_web"
echo ""
echo "Stop AWX:"
echo "  docker-compose -f docker-compose-awx.yml down"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:8081 in your browser"
echo "  2. Login with admin/Cloudflare@2025"
echo "  3. Run: ansible-playbook awx_setup.yml -i inventories/TEST/hosts"
echo "=========================================="
