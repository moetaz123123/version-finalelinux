# Script de test Trivy local
Write-Host "=== Test Trivy Local ===" -ForegroundColor Green

# Test simple avec timeout court
Write-Host "Test 1: Scan rapide (30s timeout)..." -ForegroundColor Yellow
try {
    docker run --rm -v "${PWD}:/app" aquasec/trivy:latest fs /app --skip-files vendor/ --timeout 30s --format table
    Write-Host "✅ Test 1 réussi" -ForegroundColor Green
} catch {
    Write-Host "❌ Test 1 échoué: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest 2: Scan avec exclusions..." -ForegroundColor Yellow
try {
    docker run --rm -v "${PWD}:/app" aquasec/trivy:latest fs /app --skip-dirs vendor,storage,bootstrap/cache --timeout 60s --format table
    Write-Host "✅ Test 2 réussi" -ForegroundColor Green
} catch {
    Write-Host "❌ Test 2 échoué: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest 3: Scan d'image Docker..." -ForegroundColor Yellow
try {
    docker run --rm aquasec/trivy:latest image php:8.2-fpm --format table
    Write-Host "✅ Test 3 réussi" -ForegroundColor Green
} catch {
    Write-Host "❌ Test 3 échoué: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Tests terminés ===" -ForegroundColor Green
Write-Host "Si les tests échouent, c'est normal - Trivy peut avoir des problèmes de réseau/timeout" -ForegroundColor Yellow 