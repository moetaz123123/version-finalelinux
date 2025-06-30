# Script pour initialiser Trivy dans Jenkins
Write-Host "=== Initialisation Trivy pour Jenkins ===" -ForegroundColor Green

# Chemin vers Trivy
$TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

# Verifier si Trivy existe
if (-not (Test-Path $TRIVY_PATH)) {
    Write-Host "Trivy non trouve a: $TRIVY_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Trivy trouve: $TRIVY_PATH" -ForegroundColor Green

# Creer le repertoire de cache
$CACHE_DIR = "$env:USERPROFILE\.cache\trivy"
if (-not (Test-Path $CACHE_DIR)) {
    New-Item -ItemType Directory -Path $CACHE_DIR -Force
    Write-Host "Repertoire de cache cree: $CACHE_DIR" -ForegroundColor Yellow
}

# Verifier si la base de donnees existe
$DB_PATH = "$CACHE_DIR\trivy.db"
if (Test-Path $DB_PATH) {
    Write-Host "Base de donnees Trivy trouvee: $DB_PATH" -ForegroundColor Green
    Write-Host "Taille: $((Get-Item $DB_PATH).Length / 1MB) MB" -ForegroundColor Cyan
} else {
    Write-Host "Base de donnees Trivy non trouvee, telechargement necessaire" -ForegroundColor Yellow
    Write-Host "Executez: powershell -ExecutionPolicy Bypass -File download-trivy-db-simple.ps1" -ForegroundColor Cyan
}

# Test rapide
Write-Host "`nTest rapide de Trivy..." -ForegroundColor Yellow
try {
    & $TRIVY_PATH fs . --skip-dirs vendor,storage,bootstrap/cache --cache-dir $CACHE_DIR --format table --timeout 30s
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Test Trivy reussi!" -ForegroundColor Green
        Write-Host "Jenkins peut maintenant utiliser Trivy avec le cache local" -ForegroundColor Cyan
    } else {
        Write-Host "`n⚠️ Test Trivy echoue (code: $LASTEXITCODE)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "`n❌ Erreur lors du test Trivy: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Initialisation terminee ===" -ForegroundColor Green