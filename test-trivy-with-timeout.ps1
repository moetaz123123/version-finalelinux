# Script pour exécuter Trivy avec des timeouts étendus
Write-Host "=== Test Trivy avec timeouts étendus ===" -ForegroundColor Green

# Définir des timeouts plus longs
$env:TRIVY_TIMEOUT = "30m"
$env:TRIVY_DB_TIMEOUT = "30m"
$env:TRIVY_ARTIFACT_TIMEOUT = "30m"

Write-Host "Timeouts configurés:" -ForegroundColor Yellow
Write-Host "  TRIVY_TIMEOUT: $env:TRIVY_TIMEOUT"
Write-Host "  TRIVY_DB_TIMEOUT: $env:TRIVY_DB_TIMEOUT"
Write-Host "  TRIVY_ARTIFACT_TIMEOUT: $env:TRIVY_ARTIFACT_TIMEOUT"

# Essayer avec des timeouts étendus
Write-Host "`nExécution de Trivy avec timeouts étendus..." -ForegroundColor Yellow
trivy fs . --skip-files vendor/laravel/pint/builds/pint --timeout 30m

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Trivy s'est exécuté avec succès!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Trivy a échoué avec le code: $LASTEXITCODE" -ForegroundColor Red
} 