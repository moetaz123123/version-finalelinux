# Script pour corriger la base de données Trivy corrompue
Write-Host "=== Correction de la base de données Trivy ===" -ForegroundColor Green

# Chemins des caches Trivy
$trivyCacheDir = "$env:USERPROFILE\.cache\trivy"
$trivyConfigDir = "$env:USERPROFILE\.config\trivy"

Write-Host "🧹 Nettoyage des caches Trivy..." -ForegroundColor Yellow

# Supprimer les caches existants
if (Test-Path $trivyCacheDir) {
    Remove-Item -Path $trivyCacheDir -Recurse -Force
    Write-Host "✅ Cache supprimé: $trivyCacheDir" -ForegroundColor Green
}

if (Test-Path $trivyConfigDir) {
    Remove-Item -Path $trivyConfigDir -Recurse -Force
    Write-Host "✅ Config supprimé: $trivyConfigDir" -ForegroundColor Green
}

# Recréer les répertoires
New-Item -ItemType Directory -Path $trivyCacheDir -Force | Out-Null
New-Item -ItemType Directory -Path $trivyConfigDir -Force | Out-Null

Write-Host "`n📥 Téléchargement de la base de données avec timeouts étendus..." -ForegroundColor Yellow

# Définir des timeouts très longs pour le téléchargement initial
$env:TRIVY_TIMEOUT = "60m"
$env:TRIVY_DB_TIMEOUT = "60m"
$env:TRIVY_ARTIFACT_TIMEOUT = "60m"

# Forcer la mise à jour de la base de données
Write-Host "Exécution de: trivy image --download-db-only --timeout 60m" -ForegroundColor Cyan
trivy image --download-db-only --timeout 60m

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Base de données téléchargée avec succès!" -ForegroundColor Green
    
    Write-Host "`n🧪 Test du scan après correction..." -ForegroundColor Yellow
    trivy fs . --skip-files vendor/laravel/pint/builds/pint --timeout 10m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Scan Trivy fonctionne maintenant correctement!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Le scan a encore échoué. Essayez la méthode Docker." -ForegroundColor Red
    }
} else {
    Write-Host "`n❌ Échec du téléchargement de la base de données." -ForegroundColor Red
    Write-Host "💡 Essayez la méthode Docker: .\trivy-docker-scan.ps1" -ForegroundColor Cyan
} 