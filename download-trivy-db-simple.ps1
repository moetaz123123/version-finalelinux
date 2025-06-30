# Script pour telecharger la base de donnees Trivy
Write-Host "=== Telechargement de la base de donnees Trivy ===" -ForegroundColor Green

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

Write-Host "Telechargement de la base de donnees Trivy..." -ForegroundColor Yellow
Write-Host "Cela peut prendre 10-15 minutes selon votre connexion internet" -ForegroundColor Yellow

try {
    Write-Host "Lancement du telechargement..." -ForegroundColor Cyan
    & $TRIVY_PATH image --download-db-only --cache-dir $CACHE_DIR --timeout 1800s
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Base de donnees telechargee avec succes!" -ForegroundColor Green
        Write-Host "Cache stocke dans: $CACHE_DIR" -ForegroundColor Cyan
        
        Write-Host "Test rapide de la base de donnees..." -ForegroundColor Yellow
        & $TRIVY_PATH fs . --skip-files vendor/ --format table --cache-dir $CACHE_DIR --timeout 30s
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Configuration Trivy terminee avec succes!" -ForegroundColor Green
        } else {
            Write-Host "Base de donnees telechargee mais test echoue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Echec du telechargement de la base de donnees" -ForegroundColor Red
        Write-Host "Solutions possibles:" -ForegroundColor Yellow
        Write-Host "1. Verifier votre connexion internet" -ForegroundColor White
        Write-Host "2. Essayer avec un VPN si necessaire" -ForegroundColor White
        Write-Host "3. Relancer le script plus tard" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "Erreur lors du telechargement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 