# Magento GitPod Environment - Startup Guide

## Quick Start

The environment will automatically start when GitPod workspace opens. If you need to manually start/stop services:

### Start All Services
```bash
./start-magento.sh
```

### Stop All Services
```bash
./stop-magento.sh
```

## Automatic Startup Process

When the GitPod workspace starts, the following happens automatically:

1. **MySQL Database** (Port 3306)
   - Starts in Docker container
   - Uses existing data from `/workspace/magento-gitpod/mysql`
   - Credentials: root/nem4540

2. **Elasticsearch** (Port 9200)
   - Starts in Docker container
   - Version: 7.17.10
   - No authentication required

3. **Redis Cache** (Port 6379)
   - Starts in Docker container
   - Used for session storage and caching

4. **PHP Web Server** (Port 8002)
   - PHP 8.4 built-in server
   - Document root: `/workspace/magento-gitpod/pub`

5. **Magento Configuration**
   - Base URLs are automatically updated
   - Database schema is checked and upgraded if needed
   - Cache is cleared

## Access Information

### Store URLs
- **Frontend**: https://8002-[your-workspace].gitpod.io/
- **Admin Panel**: https://8002-[your-workspace].gitpod.io/admin

### Admin Credentials
- **Username**: admin
- **Password**: password1

### Database Access
- **Host**: 127.0.0.1
- **Database**: magento2
- **Username**: root
- **Password**: nem4540

## Troubleshooting

### If services don't start automatically:
```bash
# Run the startup script manually
./start-magento.sh
```

### Check service status:
```bash
# Check if services are running
docker ps
ps aux | grep php
```

### View logs:
```bash
# Web server logs
tail -f /workspace/magento-gitpod/var/log/webserver.log

# MySQL logs
docker logs mysql-server

# Elasticsearch logs
docker logs elasticsearch
```

### Clear cache if issues occur:
```bash
php bin/magento cache:clean
php bin/magento cache:flush
```

### Rebuild if needed:
```bash
php bin/magento setup:upgrade
php bin/magento setup:di:compile
php bin/magento setup:static-content:deploy -f
```

## Manual Service Management

### MySQL
```bash
# Start
docker start mysql-server

# Stop
docker stop mysql-server

# Access MySQL CLI
docker exec -it mysql-server mysql -uroot -pnem4540
```

### Elasticsearch
```bash
# Start
docker start elasticsearch

# Stop
docker stop elasticsearch

# Check status
curl http://localhost:9200
```

### Redis
```bash
# Start
docker start redis

# Stop
docker stop redis

# Access Redis CLI
docker exec -it redis redis-cli
```

## Important Notes

- All services run in Docker containers for consistency
- Data persists between restarts
- The startup script checks if services are already running to avoid conflicts
- URLs are automatically configured based on your GitPod workspace