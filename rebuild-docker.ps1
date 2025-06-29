# PowerShell script to rebuild and restart Docker containers
Write-Host "=== Rebuilding Laravel Docker Containers ===" -ForegroundColor Green

# Stop and remove existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down

# Remove existing images to force rebuild
Write-Host "Removing existing images..." -ForegroundColor Yellow
docker rmi laravel-app 2>$null

# Clean up any dangling images and containers
Write-Host "Cleaning up Docker..." -ForegroundColor Yellow
docker system prune -f

# Rebuild the containers
Write-Host "Rebuilding containers..." -ForegroundColor Yellow
docker-compose build --no-cache

# Start the containers
Write-Host "Starting containers..." -ForegroundColor Yellow
docker-compose up -d

# Wait for containers to be ready
Write-Host "Waiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check container status
Write-Host "Checking container status..." -ForegroundColor Yellow
docker-compose ps

# Show logs
Write-Host "Container logs:" -ForegroundColor Yellow
docker-compose logs app

Write-Host "=== Rebuild Complete ===" -ForegroundColor Green
Write-Host "Your Laravel application should now be available at: http://localhost:8000" -ForegroundColor Cyan
Write-Host "PHPMyAdmin is available at: http://localhost:8080" -ForegroundColor Cyan 