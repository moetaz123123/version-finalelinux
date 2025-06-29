# Script de test Trivy pour diagnostiquer les problèmes dans Jenkins
Write-Host "🔍 Diagnostic Trivy pour Jenkins..." -ForegroundColor Green

# Chemin vers Trivy
$TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

# Test 1: Vérifier si Trivy existe
Write-Host "`n1. Vérification de l'existence de Trivy..." -ForegroundColor Yellow
if (Test-Path $TRIVY_PATH) {
    Write-Host "✅ Trivy trouvé: $TRIVY_PATH" -ForegroundColor Green
} else {
    Write-Host "❌ Trivy non trouvé à: $TRIVY_PATH" -ForegroundColor Red
    exit 1
}

# Test 2: Vérifier la version de Trivy
Write-Host "`n2. Vérification de la version Trivy..." -ForegroundColor Yellow
try {
    $version = & $TRIVY_PATH version
    Write-Host "✅ Version Trivy: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ Impossible d'obtenir la version Trivy" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Vérifier le répertoire de travail
Write-Host "`n3. Vérification du répertoire de travail..." -ForegroundColor Yellow
$currentDir = Get-Location
Write-Host "📁 Répertoire actuel: $currentDir" -ForegroundColor Cyan

# Test 4: Vérifier les permissions
Write-Host "`n4. Vérification des permissions..." -ForegroundColor Yellow
try {
    $testFile = "test-trivy-permissions.txt"
    "Test de permissions" | Out-File -FilePath $testFile -Encoding UTF8
    if (Test-Path $testFile) {
        Write-Host "✅ Permissions d'écriture OK" -ForegroundColor Green
        Remove-Item $testFile
    }
} catch {
    Write-Host "❌ Problème de permissions d'écriture" -ForegroundColor Red
}

# Test 5: Test de connectivité réseau
Write-Host "`n5. Test de connectivité réseau..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://mirror.gcr.io" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Connectivité vers mirror.gcr.io OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Problème de connectivité vers mirror.gcr.io" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 6: Test de téléchargement de la base de données
Write-Host "`n6. Test de téléchargement de la base de données..." -ForegroundColor Yellow
try {
    Write-Host "Tentative de téléchargement de la base de données..."
    & $TRIVY_PATH image --download-db-only --timeout 60s
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Base de données téléchargée avec succès" -ForegroundColor Green
    } else {
        Write-Host "❌ Échec du téléchargement de la base de données" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur lors du téléchargement de la base de données" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 7: Test de scan simple
Write-Host "`n7. Test de scan simple..." -ForegroundColor Yellow
try {
    $testReport = "test-trivy-scan.txt"
    Write-Host "Lancement d'un scan de test..."
    & $TRIVY_PATH fs . --skip-files vendor/ --format table --output $testReport --timeout 30s
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Scan de test réussi" -ForegroundColor Green
        if (Test-Path $testReport) {
            Write-Host "📄 Rapport de test généré: $testReport" -ForegroundColor Cyan
            $content = Get-Content $testReport -Raw
            Write-Host "Contenu du rapport:" -ForegroundColor Yellow
            Write-Host $content -ForegroundColor White
            Remove-Item $testReport
        } else {
            Write-Host "⚠️ Scan réussi mais fichier de rapport non trouvé" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Scan de test échoué" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur lors du scan de test" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 8: Test avec le chemin exact du workspace Jenkins
Write-Host "`n8. Test avec le workspace Jenkins simulé..." -ForegroundColor Yellow
$jenkinsWorkspace = "C:\ProgramData\Jenkins\.jenkins\workspace\pipeline-laravel"
if (Test-Path $jenkinsWorkspace) {
    Write-Host "📁 Workspace Jenkins trouvé: $jenkinsWorkspace" -ForegroundColor Green
    try {
        $testReport = "$jenkinsWorkspace\test-jenkins-scan.txt"
        Write-Host "Test de scan dans le workspace Jenkins..."
        & $TRIVY_PATH fs $jenkinsWorkspace --skip-files vendor/ --format table --output $testReport --timeout 30s
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Scan dans workspace Jenkins réussi" -ForegroundColor Green
            if (Test-Path $testReport) {
                Remove-Item $testReport
            }
        } else {
            Write-Host "❌ Scan dans workspace Jenkins échoué" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Erreur lors du scan dans workspace Jenkins" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️ Workspace Jenkins non trouvé: $jenkinsWorkspace" -ForegroundColor Yellow
}

Write-Host "`n🎉 Diagnostic Trivy terminé!" -ForegroundColor Green
Write-Host "💡 Vérifiez les résultats ci-dessus pour identifier les problèmes potentiels" -ForegroundColor Cyan 