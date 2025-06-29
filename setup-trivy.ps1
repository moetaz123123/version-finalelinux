# Script de configuration Trivy pour Jenkins
# Exécuter ce script avant de lancer le pipeline Jenkins

Write-Host "🔧 Configuration de Trivy pour Jenkins..." -ForegroundColor Green

# Chemin vers Trivy
$TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

# Vérifier si Trivy existe
if (-not (Test-Path $TRIVY_PATH)) {
    Write-Host "❌ Trivy non trouvé à: $TRIVY_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Trivy trouvé: $TRIVY_PATH" -ForegroundColor Green

# Créer le répertoire de cache
$CACHE_DIR = "C:\ProgramData\Jenkins\.jenkins\workspace\pipeline-laravel\.trivycache"
if (-not (Test-Path $CACHE_DIR)) {
    New-Item -ItemType Directory -Path $CACHE_DIR -Force
    Write-Host "📁 Répertoire de cache créé: $CACHE_DIR" -ForegroundColor Yellow
}

# Télécharger la base de données de vulnérabilités
Write-Host "📥 Téléchargement de la base de données Trivy..." -ForegroundColor Yellow

$success = $false

try {
    # Tentative 1: Téléchargement normal
    Write-Host "Tentative 1: Téléchargement normal..." -ForegroundColor Cyan
    & $TRIVY_PATH image --download-db-only --cache-dir $CACHE_DIR
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Base de données téléchargée avec succès" -ForegroundColor Green
        $success = $true
    } else {
        throw "Échec du téléchargement"
    }
} catch {
    Write-Host "⚠️ Tentative 1 échouée, tentative 2 avec timeout étendu..." -ForegroundColor Yellow
    try {
        # Tentative 2: Avec timeout étendu
        & $TRIVY_PATH image --download-db-only --cache-dir $CACHE_DIR --timeout 600s
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Base de données téléchargée avec succès (tentative 2)" -ForegroundColor Green
            $success = $true
        } else {
            throw "Échec du téléchargement"
        }
    } catch {
        Write-Host "⚠️ Tentative 2 échouée, tentative 3 avec options de sécurité..." -ForegroundColor Yellow
        try {
            # Tentative 3: Avec options de sécurité
            & $TRIVY_PATH image --download-db-only --cache-dir $CACHE_DIR --timeout 600s --insecure
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Base de données téléchargée avec succès (tentative 3)" -ForegroundColor Green
                $success = $true
            } else {
                Write-Host "❌ Impossible de télécharger la base de données Trivy" -ForegroundColor Red
                Write-Host "💡 Solutions possibles:" -ForegroundColor Yellow
                Write-Host "   1. Vérifier la connectivité réseau" -ForegroundColor White
                Write-Host "   2. Configurer un proxy si nécessaire" -ForegroundColor White
                Write-Host "   3. Exécuter manuellement: $TRIVY_PATH image --download-db-only" -ForegroundColor White
                exit 1
            }
        } catch {
            Write-Host "❌ Toutes les tentatives ont échoué" -ForegroundColor Red
            exit 1
        }
    }
}

if ($success) {
    # Test de scan rapide
    Write-Host "🧪 Test de scan rapide..." -ForegroundColor Yellow
    try {
        & $TRIVY_PATH fs . --skip-files vendor/ --severity CRITICAL --format table --cache-dir $CACHE_DIR --timeout 30s
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Test de scan réussi" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Test de scan échoué, mais la base de données est téléchargée" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Test de scan échoué, mais la base de données est téléchargée" -ForegroundColor Yellow
    }
    Write-Host "🎉 Configuration Trivy terminée!" -ForegroundColor Green
    Write-Host "💡 Le pipeline Jenkins peut maintenant utiliser Trivy avec le cache local" -ForegroundColor Cyan
} 