# Script de test Trivy simplifie pour diagnostiquer les problemes dans Jenkins
Write-Host "Diagnostic Trivy pour Jenkins..." -ForegroundColor Green

# Chemin vers Trivy
$TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

# Test 1: Verifier si Trivy existe
Write-Host "1. Verification de l'existence de Trivy..." -ForegroundColor Yellow
if (Test-Path $TRIVY_PATH) {
    Write-Host "Trivy trouve: $TRIVY_PATH" -ForegroundColor Green
} else {
    Write-Host "Trivy non trouve a: $TRIVY_PATH" -ForegroundColor Red
    exit 1
}

# Test 2: Verifier la version de Trivy
Write-Host "2. Verification de la version Trivy..." -ForegroundColor Yellow
try {
    $version = & $TRIVY_PATH version
    Write-Host "Version Trivy: $version" -ForegroundColor Green
} catch {
    Write-Host "Impossible d'obtenir la version Trivy" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Verifier le repertoire de travail
Write-Host "3. Verification du repertoire de travail..." -ForegroundColor Yellow
$currentDir = Get-Location
Write-Host "Repertoire actuel: $currentDir" -ForegroundColor Cyan

# Test 4: Verifier les permissions
Write-Host "4. Verification des permissions..." -ForegroundColor Yellow
try {
    $testFile = "test-trivy-permissions.txt"
    "Test de permissions" | Out-File -FilePath $testFile -Encoding UTF8
    if (Test-Path $testFile) {
        Write-Host "Permissions d'ecriture OK" -ForegroundColor Green
        Remove-Item $testFile
    }
} catch {
    Write-Host "Probleme de permissions d'ecriture" -ForegroundColor Red
}

# Test 5: Test de scan simple
Write-Host "5. Test de scan simple..." -ForegroundColor Yellow
try {
    $testReport = "test-trivy-scan.txt"
    Write-Host "Lancement d'un scan de test..."
    & $TRIVY_PATH fs . --skip-files vendor/ --format table --output $testReport --timeout 30s
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scan de test reussi" -ForegroundColor Green
        if (Test-Path $testReport) {
            Write-Host "Rapport de test genere: $testReport" -ForegroundColor Cyan
            $content = Get-Content $testReport -Raw
            Write-Host "Contenu du rapport:" -ForegroundColor Yellow
            Write-Host $content -ForegroundColor White
            Remove-Item $testReport
        } else {
            Write-Host "Scan reussi mais fichier de rapport non trouve" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Scan de test echoue" -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors du scan de test" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

Write-Host "Diagnostic Trivy termine!" -ForegroundColor Green 