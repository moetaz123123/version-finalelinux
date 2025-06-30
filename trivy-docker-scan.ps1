# Script pour exécuter Trivy via Docker (évite les problèmes de téléchargement local)
Write-Host "=== Test Trivy via Docker ===" -ForegroundColor Green

# Vérifier si Docker est disponible
try {
    docker --version | Out-Null
    Write-Host "✅ Docker est disponible" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker n'est pas disponible. Veuillez installer Docker Desktop." -ForegroundColor Red
    exit 1
}

# Créer un cache directory pour Trivy
$cacheDir = "$env:USERPROFILE\.cache\trivy"
if (!(Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    Write-Host "📁 Cache directory créé: $cacheDir" -ForegroundColor Yellow
}

Write-Host "`nExécution de Trivy via Docker..." -ForegroundColor Yellow
Write-Host "Cette méthode évite les problèmes de téléchargement local" -ForegroundColor Cyan

# Exécuter Trivy via Docker avec cache persistant
docker run --rm `
    -v "${PWD}:/workspace" `
    -v "${cacheDir}:/root/.cache/trivy" `
    -w /workspace `
    aquasec/trivy:latest `
    fs . --skip-files vendor/laravel/pint/builds/pint --format table

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Scan Trivy Docker terminé avec succès!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Scan Trivy Docker a échoué avec le code: $LASTEXITCODE" -ForegroundColor Red
}

Write-Host "`n💡 Le cache est sauvegardé dans: $cacheDir" -ForegroundColor Cyan
Write-Host "Les prochaines exécutions seront plus rapides." -ForegroundColor Cyan 