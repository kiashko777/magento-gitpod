#!/bin/bash

echo "======================================="
echo "Starting Magento Development Environment"
echo "======================================="

# Set working directory
cd /workspace/magento-gitpod

# Function to check if a service is running
check_service() {
    local service=$1
    local port=$2
    nc -zv localhost $port 2>/dev/null
    return $?
}

# Function to wait for service
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=0

    echo -n "Waiting for $service to start on port $port..."
    while [ $attempt -lt $max_attempts ]; do
        if check_service "$service" $port; then
            echo " ✓ Started"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo " ✗ Failed"
    return 1
}

# 1. Start MySQL if not running
echo "1. Checking MySQL..."
if ! check_service "MySQL" 3306; then
    echo "   Starting MySQL in Docker..."
    # Stop any existing MySQL container
    docker stop mysql-server 2>/dev/null
    docker rm mysql-server 2>/dev/null

    # Start MySQL with existing data
    docker run -d --name mysql-server \
        -e MYSQL_ROOT_PASSWORD=nem4540 \
        -v /workspace/magento-gitpod/mysql:/var/lib/mysql \
        -p 3306:3306 \
        mysql:5.7

    wait_for_service "MySQL" 3306

    # Grant permissions for remote connections
    sleep 5
    docker exec mysql-server mysql -uroot -pnem4540 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'nem4540' WITH GRANT OPTION; FLUSH PRIVILEGES;" 2>/dev/null
    echo "   MySQL is ready!"
else
    echo "   MySQL is already running ✓"
fi

# 2. Start Elasticsearch if not running
echo "2. Checking Elasticsearch..."
if ! check_service "Elasticsearch" 9200; then
    echo "   Starting Elasticsearch in Docker..."
    # Stop any existing Elasticsearch container
    docker stop elasticsearch 2>/dev/null
    docker rm elasticsearch 2>/dev/null

    # Start Elasticsearch
    docker run -d --name elasticsearch \
        -p 9200:9200 -p 9300:9300 \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
        elasticsearch:7.17.10

    wait_for_service "Elasticsearch" 9200
    echo "   Elasticsearch is ready!"
else
    echo "   Elasticsearch is already running ✓"
fi

# 3. Start Redis if not running (optional)
echo "3. Checking Redis..."
if ! check_service "Redis" 6379; then
    echo "   Starting Redis in Docker..."
    # Stop any existing Redis container
    docker stop redis 2>/dev/null
    docker rm redis 2>/dev/null

    # Start Redis
    docker run -d --name redis -p 6379:6379 redis:latest

    wait_for_service "Redis" 6379
    echo "   Redis is ready!"
else
    echo "   Redis is already running ✓"
fi

# 4. Update Magento configuration
echo "4. Updating Magento configuration..."
cd /workspace/magento-gitpod

# Update base URLs
URL=$(gp url 8002 2>/dev/null || echo "http://localhost:8002")
if [ "$URL" != "http://localhost:8002" ]; then
    echo "   Setting base URL to: $URL"
    php bin/magento config:set web/unsecure/base_url "${URL}/" 2>/dev/null
    php bin/magento config:set web/secure/base_url "${URL}/" 2>/dev/null
    php bin/magento config:set web/secure/use_in_frontend 0 2>/dev/null
    php bin/magento config:set web/secure/use_in_adminhtml 0 2>/dev/null
    php bin/magento config:set web/seo/use_rewrites 1 2>/dev/null
    php bin/magento config:set web/default/cms_home_page home 2>/dev/null
    php bin/magento config:set web/default/cms_no_route no-route 2>/dev/null
fi

# 5. Check if database needs upgrade
echo "5. Checking database status..."
DB_STATUS=$(php bin/magento setup:db:status 2>&1)
if echo "$DB_STATUS" | grep -q "upgrade"; then
    echo "   Database needs upgrade. Running setup:upgrade..."
    php bin/magento setup:upgrade
    echo "   Database upgraded successfully!"

    # Deploy static content if needed
    echo "   Deploying static content..."
    php bin/magento setup:static-content:deploy -f 2>/dev/null
else
    echo "   Database is up to date ✓"
fi

# 6. Clear cache
echo "6. Clearing Magento cache..."
php bin/magento cache:clean 2>/dev/null
php bin/magento cache:flush 2>/dev/null
echo "   Cache cleared ✓"

# 7. Ensure router.php exists
if [ ! -f "/workspace/magento-gitpod/pub/router.php" ]; then
    echo "7. Creating router.php..."
    cat > /workspace/magento-gitpod/pub/router.php << 'EOF'
<?php
/**
 * PHP Built-in server router for Magento 2
 */

// Set the document root
$documentRoot = __DIR__;

// Get the request URI
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Remove index.php from the URI if present
if (strpos($uri, '/index.php') === 0) {
    $uri = substr($uri, strlen('/index.php'));
    if ($uri === '' || $uri === '/') {
        $uri = '/';
    }
}

// Handle static files
$filePath = $documentRoot . $uri;
if ($uri !== '/' && file_exists($filePath) && is_file($filePath)) {
    // Serve static file
    return false;
}

// Handle pub/static files
if (preg_match('#^/static/#', $uri)) {
    include $documentRoot . '/static.php';
    return true;
}

// Handle pub/media files
if (preg_match('#^/media/#', $uri)) {
    include $documentRoot . '/get.php';
    return true;
}

// All other requests go through index.php
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = $documentRoot . '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';
$_SERVER['PATH_INFO'] = $uri;

require $documentRoot . '/index.php';
EOF
    echo "   Router created ✓"
else
    echo "7. Router already exists ✓"
fi

# 8. Start web server if not running
echo "8. Starting web server..."
# Kill any existing PHP built-in server on port 8002
pkill -f "php.*8002" 2>/dev/null
sleep 1

# Create log directory if not exists
mkdir -p /workspace/magento-gitpod/var/log

# Start PHP built-in server with router
php -S 0.0.0.0:8002 -t /workspace/magento-gitpod/pub/ /workspace/magento-gitpod/pub/router.php > /workspace/magento-gitpod/var/log/webserver.log 2>&1 &
echo "   Web server started on port 8002 ✓"

echo ""
echo "======================================="
echo "✅ Magento Environment Ready!"
echo "======================================="
echo ""
echo "Access your store at:"
echo "  Store URL: ${URL}"
echo "  Admin URL: ${URL}/admin"
echo ""
echo "Admin credentials:"
echo "  Username: admin"
echo "  Password: password1"
echo ""
echo "Database:"
echo "  Host: 127.0.0.1"
echo "  Database: magento2"
echo "  Username: root"
echo "  Password: nem4540"
echo ""
echo "Services running:"
echo "  ✓ MySQL on port 3306"
echo "  ✓ Elasticsearch on port 9200"
echo "  ✓ Redis on port 6379"
echo "  ✓ PHP server on port 8002"
echo ""
echo "Logs available at:"
echo "  /workspace/magento-gitpod/var/log/webserver.log"
echo ""
echo "To stop all services, run: ./stop-magento.sh"
echo ""