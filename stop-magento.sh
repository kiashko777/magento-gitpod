#!/bin/bash

echo "======================================="
echo "Stopping Magento Development Environment"
echo "======================================="

# Stop PHP server
echo "Stopping web server..."
pkill -f "php.*8002" 2>/dev/null
echo "  ✓ Web server stopped"

# Stop Docker containers
echo "Stopping Docker containers..."
docker stop mysql-server 2>/dev/null
echo "  ✓ MySQL stopped"
docker stop elasticsearch 2>/dev/null
echo "  ✓ Elasticsearch stopped"
docker stop redis 2>/dev/null
echo "  ✓ Redis stopped"

echo ""
echo "======================================="
echo "All services have been stopped"
echo "======================================="
echo ""
echo "To restart, run: ./start-magento.sh"
echo ""