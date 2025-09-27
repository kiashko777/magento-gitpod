#!/bin/bash

# Health Check Script for Magento GitPod Environment

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================="
echo "Magento Environment Health Check"
echo "======================================="
echo ""

ERRORS=0

# Function to check service
check_service() {
    local service=$1
    local port=$2

    nc -zv localhost $port 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $service is running on port $port"
        return 0
    else
        echo -e "${RED}✗${NC} $service is NOT running on port $port"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Check MySQL
check_service "MySQL" 3306
if [ $? -eq 0 ]; then
    DB_CHECK=$(docker exec mysql-server mysql -uroot -pnem4540 -e "SELECT 1;" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}├─${NC} Database connection: OK"
        TABLE_COUNT=$(docker exec mysql-server mysql -uroot -pnem4540 -e "USE magento2; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'magento2';" 2>/dev/null | tail -1)
        echo -e "  ${GREEN}└─${NC} Tables in database: $TABLE_COUNT"
    else
        echo -e "  ${RED}└─${NC} Database connection: FAILED"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""

# Check Elasticsearch
check_service "Elasticsearch" 9200
if [ $? -eq 0 ]; then
    ES_STATUS=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$ES_STATUS" = "green" ] || [ "$ES_STATUS" = "yellow" ]; then
        echo -e "  ${GREEN}└─${NC} Cluster status: $ES_STATUS"
    else
        echo -e "  ${YELLOW}└─${NC} Cluster status: $ES_STATUS"
    fi
fi

echo ""

# Check Redis
check_service "Redis" 6379

echo ""

# Check PHP Server
check_service "PHP Server" 8002
if [ $? -eq 0 ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8002)
    if [ "$HTTP_STATUS" = "302" ] || [ "$HTTP_STATUS" = "200" ]; then
        echo -e "  ${GREEN}└─${NC} HTTP response: $HTTP_STATUS OK"
    else
        echo -e "  ${YELLOW}└─${NC} HTTP response: $HTTP_STATUS"
    fi
fi

echo ""

# Check Magento
echo "Checking Magento:"
if [ -f "/workspace/magento-gitpod/app/etc/env.php" ]; then
    echo -e "${GREEN}✓${NC} Magento is installed"

    # Check cache status
    CACHE_STATUS=$(php /workspace/magento-gitpod/bin/magento cache:status 2>/dev/null | grep -c "1")
    echo -e "  ${GREEN}├─${NC} Cache types enabled: $CACHE_STATUS"

    # Check mode
    MODE=$(php /workspace/magento-gitpod/bin/magento deploy:mode:show 2>/dev/null | grep -o "mode: .*" | cut -d' ' -f2)
    echo -e "  ${GREEN}├─${NC} Mode: $MODE"

    # Check URLs
    URL=$(gp url 8002 2>/dev/null || echo "http://localhost:8002")
    echo -e "  ${GREEN}└─${NC} Base URL: $URL"
else
    echo -e "${RED}✗${NC} Magento is NOT installed"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check essential files
echo "Checking essential files:"
FILES=(
    "/workspace/magento-gitpod/pub/router.php"
    "/workspace/magento-gitpod/start-magento.sh"
    "/workspace/magento-gitpod/stop-magento.sh"
    "/workspace/magento-gitpod/.gitpod.yml"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $(basename $file) exists"
    else
        echo -e "${RED}✗${NC} $(basename $file) missing"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "======================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All systems operational!${NC}"
else
    echo -e "${RED}✗ Found $ERRORS issue(s)${NC}"
    echo ""
    echo "To fix issues, run: ./start-magento.sh"
fi
echo "======================================="

exit $ERRORS