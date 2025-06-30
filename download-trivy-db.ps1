# Script pour télécharger la base de données Trivy une seule fois
Write-Host "=== Téléchargement de la base de données Trivy ===" -ForegroundColor Green

# Chemin vers Trivy
$TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

# Vérifier si Trivy existe
if (-not (Test-Path $TRIVY_PATH)) {
    Write-Host "❌ Trivy non trouvé à: $TRIVY_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Trivy trouvé: $TRIVY_PATH" -ForegroundColor Green

# Créer le répertoire de cache
$CACHE_DIR = "$env:USERPROFILE\.cache\trivy"
if (-not (Test-Path $CACHE_DIR)) {
    New-Item -ItemType Directory -Path $CACHE_DIR -Force
    Write-Host "📁 Répertoire de cache créé: $CACHE_DIR" -ForegroundColor Yellow
}

Write-Host "`n📥 Téléchargement de la base de données Trivy..." -ForegroundColor Yellow
Write-Host "⚠️ Cela peut prendre 10-15 minutes selon votre connexion internet" -ForegroundColor Yellow
Write-Host "💡 Vous pouvez interrompre avec Ctrl+C et relancer plus tard" -ForegroundColor Cyan

try {
    # Téléchargement avec timeout très long
    Write-Host "`n🔄 Lancement du téléchargement..." -ForegroundColor Cyan
    & $TRIVY_PATH image --download-db-only --cache-dir $CACHE_DIR --timeout 1800s
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Base de données téléchargée avec succès!" -ForegroundColor Green
        Write-Host "📁 Cache stocké dans: $CACHE_DIR" -ForegroundColor Cyan
        
        # Test rapide
        Write-Host "`n🧪 Test rapide de la base de données..." -ForegroundColor Yellow
        & $TRIVY_PATH fs . --skip-files vendor/ --format table --cache-dir $CACHE_DIR --timeout 30s
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n🎉 Configuration Trivy terminée avec succès!" -ForegroundColor Green
            Write-Host "💡 Vous pouvez maintenant utiliser Trivy normalement" -ForegroundColor Cyan
        } else {
            Write-Host "`n⚠️ Base de données téléchargée mais test échoué" -ForegroundColor Yellow
            Write-Host "💡 Essayez: trivy fs . --skip-files vendor/ --cache-dir $CACHE_DIR" -ForegroundColor Cyan
        }
    } else {
        Write-Host "`n❌ Échec du téléchargement de la base de données" -ForegroundColor Red
        Write-Host "💡 Solutions possibles:" -ForegroundColor Yellow
        Write-Host "   1. Vérifier votre connexion internet" -ForegroundColor White
        Write-Host "   2. Essayer avec un VPN si nécessaire" -ForegroundColor White
        Write-Host "   3. Relancer le script plus tard" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "`n❌ Erreur lors du téléchargement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 