# Script de test Docker Trivy pour Windows
Write-Host "Docker Trivy Test pour Windows..." -ForegroundColor Green

# Test 1: Verifier si Docker est disponible
Write-Host "1. Verification de Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker trouve: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker non trouve ou non accessible" -ForegroundColor Red
    exit 1
}

# Test 2: Verifier si Docker fonctionne
Write-Host "2. Test de Docker..." -ForegroundColor Yellow
try {
    docker ps
    Write-Host "Docker fonctionne correctement" -ForegroundColor Green
} catch {
    Write-Host "Docker ne fonctionne pas" -ForegroundColor Red
    exit 1
}

# Test 3: Télécharger l'image Trivy
Write-Host "3. Téléchargement de l'image Trivy..." -ForegroundColor Yellow
try {
    docker pull aquasec/trivy:latest
    Write-Host "Image Trivy téléchargée avec succès" -ForegroundColor Green
} catch {
    Write-Host "Echec du téléchargement de l'image Trivy" -ForegroundColor Red
    exit 1
}

# Test 4: Test de scan avec Docker Trivy
Write-Host "4. Test de scan avec Docker Trivy..." -ForegroundColor Yellow
$currentDir = Get-Location
Write-Host "Repertoire actuel: $currentDir" -ForegroundColor Cyan

try {
    # Utiliser le chemin Windows correct pour le montage Docker
    $dockerCommand = "docker run --rm -v `"${currentDir}:/app`" aquasec/trivy:latest fs /app --skip-files vendor/ --format table --output trivy-docker-test.txt --timeout 300s"
    Write-Host "Commande Docker: $dockerCommand" -ForegroundColor Cyan
    
    Invoke-Expression $dockerCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scan Docker Trivy reussi" -ForegroundColor Green
        if (Test-Path "trivy-docker-test.txt") {
            Write-Host "Rapport genere: trivy-docker-test.txt" -ForegroundColor Cyan
            $content = Get-Content "trivy-docker-test.txt" -Raw
            Write-Host "Contenu du rapport:" -ForegroundColor Yellow
            Write-Host $content -ForegroundColor White
            Remove-Item "trivy-docker-test.txt"
        } else {
            Write-Host "Scan reussi mais fichier de rapport non trouve" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Scan Docker Trivy echoue avec code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors du scan Docker Trivy" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

Write-Host "Test Docker Trivy termine!" -ForegroundColor Green 