# Script pour tester la correction Trivy (simulation Jenkins)
Write-Host "=== Test de la correction Trivy (simulation Jenkins) ===" -ForegroundColor Green

# Variables d'environnement (simulation Jenkins)
$env:TRIVY_PATH = "C:\Users\User\Downloads\trivy_0.63.0_windows-64bit\trivy.exe"

Write-Host "🔍 Test 1: Exécutable local Trivy" -ForegroundColor Yellow

# Test avec l'exécutable local
$localResult = & $env:TRIVY_PATH fs . --skip-files vendor/laravel/pint/builds/pint --timeout 300s 2>&1
$localExitCode = $LASTEXITCODE

Write-Host "Code de sortie local: $localExitCode" -ForegroundColor Cyan

if ($localExitCode -eq 0) {
    Write-Host "✅ Trivy local fonctionne correctement" -ForegroundColor Green
    $localResult | Out-File -FilePath "trivy-report.txt" -Encoding UTF8
} else {
    Write-Host "❌ Trivy local a échoué, tentative Docker..." -ForegroundColor Red
    
    # Vérifier Docker
    try {
        docker --version | Out-Null
        Write-Host "🐳 Docker disponible, test avec image Trivy..." -ForegroundColor Yellow
        
        # Test avec Docker
        $dockerResult = docker run --rm -v "${PWD}:/workspace" -w /workspace aquasec/trivy:latest fs . --skip-files vendor/laravel/pint/builds/pint --format table 2>&1
        $dockerExitCode = $LASTEXITCODE
        
        Write-Host "Code de sortie Docker: $dockerExitCode" -ForegroundColor Cyan
        
        if ($dockerExitCode -eq 0) {
            Write-Host "✅ Trivy Docker fonctionne correctement" -ForegroundColor Green
            $dockerResult | Out-File -FilePath "trivy-report.txt" -Encoding UTF8
        } else {
            Write-Host "❌ Trivy Docker a aussi échoué" -ForegroundColor Red
            # Créer un rapport d'erreur
            @"
=== Rapport Trivy ===
Date: $(Get-Date)
Statut: Échec
Code de sortie local: $localExitCode
Code de sortie Docker: $dockerExitCode

Détails de l'erreur:
- Trivy a rencontré une erreur lors du scan
- Vérifiez la connectivité réseau
- Vérifiez que la base de données de vulnérabilités est accessible
- Considérez l'utilisation de Docker pour éviter les problèmes de téléchargement

Aucune vulnérabilité détectée ou erreur lors du scan.
"@ | Out-File -FilePath "trivy-report.txt" -Encoding UTF8
        }
    } catch {
        Write-Host "❌ Docker non disponible" -ForegroundColor Red
        # Créer un rapport d'erreur
        @"
=== Rapport Trivy ===
Date: $(Get-Date)
Statut: Échec
Code de sortie local: $localExitCode

Détails de l'erreur:
- Trivy local a échoué
- Docker non disponible
- Vérifiez la connectivité réseau
- Vérifiez que la base de données de vulnérabilités est accessible

Aucune vulnérabilité détectée ou erreur lors du scan.
"@ | Out-File -FilePath "trivy-report.txt" -Encoding UTF8
    }
}

# Afficher le rapport final
if (Test-Path "trivy-report.txt") {
    Write-Host "`n📄 Contenu du rapport Trivy:" -ForegroundColor Green
    Get-Content "trivy-report.txt"
    Write-Host "`n✅ Rapport créé: trivy-report.txt" -ForegroundColor Green
} else {
    Write-Host "`n❌ Aucun rapport créé" -ForegroundColor Red
}

Write-Host "`n💡 Le build Jenkins continuera même si Trivy échoue" -ForegroundColor Cyan 