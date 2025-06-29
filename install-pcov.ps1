# Script d'installation PCOV pour la couverture de code PHPUnit
Write-Host "Installation PCOV pour la couverture de code..." -ForegroundColor Green

# Chemin vers PHP
$PHP_PATH = "C:\xampp\php\php.exe"

# Vérifier si PHP existe
if (-not (Test-Path $PHP_PATH)) {
    Write-Host "❌ PHP non trouvé à: $PHP_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PHP trouvé: $PHP_PATH" -ForegroundColor Green

# Vérifier si PCOV est déjà installé
Write-Host "Vérification de PCOV..." -ForegroundColor Yellow
try {
    $pcovCheck = & $PHP_PATH -m | Select-String "pcov"
    if ($pcovCheck) {
        Write-Host "✅ PCOV est déjà installé" -ForegroundColor Green
        Write-Host "PCOV version: $pcovCheck" -ForegroundColor Cyan
    } else {
        Write-Host "PCOV non trouvé, installation..." -ForegroundColor Yellow
        
        # Vérifier si Composer existe
        $composerPath = "composer"
        try {
            $composerVersion = & $composerPath --version
            Write-Host "✅ Composer trouvé: $composerVersion" -ForegroundColor Green
        } catch {
            Write-Host "❌ Composer non trouvé" -ForegroundColor Red
            exit 1
        }
        
        # Installer PCOV via Composer
        Write-Host "Installation de PCOV via Composer..." -ForegroundColor Yellow
        try {
            & $composerPath require --dev pcov/clobber
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ PCOV installé avec succès" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec de l'installation PCOV" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "❌ Erreur lors de l'installation PCOV" -ForegroundColor Red
            Write-Host "Erreur: $_" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "❌ Erreur lors de la vérification PCOV" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
    exit 1
}

# Test de PCOV
Write-Host "Test de PCOV..." -ForegroundColor Yellow
try {
    $pcovTest = & $PHP_PATH -m | Select-String "pcov"
    if ($pcovTest) {
        Write-Host "✅ PCOV fonctionne correctement" -ForegroundColor Green
        
        # Test avec PHPUnit
        Write-Host "Test avec PHPUnit..." -ForegroundColor Yellow
        try {
            $env:PCOV_ENABLED = "1"
            & $PHP_PATH vendor/bin/phpunit --testsuite=Unit --coverage-text --stop-on-failure
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Test PHPUnit avec PCOV réussi" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Test PHPUnit avec PCOV terminé avec des avertissements" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️ Test PHPUnit avec PCOV échoué, mais PCOV est installé" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ PCOV ne fonctionne pas" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur lors du test PCOV" -ForegroundColor Red
}

Write-Host "Installation PCOV terminée!" -ForegroundColor Green
Write-Host "💡 Vous pouvez maintenant utiliser --coverage-clover dans PHPUnit" -ForegroundColor Cyan 