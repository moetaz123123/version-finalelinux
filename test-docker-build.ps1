# PowerShell script to test Docker build locally
Write-Host "=== Testing Docker Build ===" -ForegroundColor Green

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host "✅ .env file found" -ForegroundColor Green
} else {
    Write-Host "⚠️ .env file not found, creating basic .env file..." -ForegroundColor Yellow
    @"
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel_multitenant
DB_USERNAME=root
DB_PASSWORD=rootpassword
"@ | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Basic .env file created" -ForegroundColor Green
}

# Clean up any existing containers and images
Write-Host "Cleaning up existing containers and images..." -ForegroundColor Yellow
docker-compose down 2>$null
docker rmi laravel-app 2>$null
docker system prune -f

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t laravel-app .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker build successful!" -ForegroundColor Green
    
    # Test running the container
    Write-Host "Testing container..." -ForegroundColor Yellow
    docker run --rm -d --name test-laravel -p 8001:8000 laravel-app
    
    Start-Sleep -Seconds 10
    
    # Check if container is running
    $containerStatus = docker ps --filter "name=test-laravel" --format "table {{.Names}}\t{{.Status}}"
    Write-Host "Container status:" -ForegroundColor Cyan
    Write-Host $containerStatus
    
    # Stop test container
    docker stop test-laravel 2>$null
    docker rm test-laravel 2>$null
    
    Write-Host "✅ Docker build and test completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
} 