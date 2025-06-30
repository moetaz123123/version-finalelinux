# Script de configuration Trivy optimisé
Write-Host "=== Configuration Trivy optimisée ===" -ForegroundColor Green

# Créer le répertoire de cache Trivy
$trivyCacheDir = "$env:USERPROFILE\.cache\trivy"
if (!(Test-Path $trivyCacheDir)) {
    New-Item -ItemType Directory -Path $trivyCacheDir -Force
    Write-Host "✅ Répertoire de cache Trivy créé: $trivyCacheDir" -ForegroundColor Green
}

# Créer le fichier de configuration Trivy
$trivyConfigDir = "$env:USERPROFILE\.config\trivy"
if (!(Test-Path $trivyConfigDir)) {
    New-Item -ItemType Directory -Path $trivyConfigDir -Force
}

$trivyConfig = @"
db:
  repository: "mirror.gcr.io/aquasec/trivy-db"
  cache-ttl: 24h
  download-timeout: 600s
  update-interval: 24h

scan:
  timeout: 600s
  slow: true

report:
  format: table
  output: trivy-report.txt

cache:
  dir: "$trivyCacheDir"

security-checks:
  - vuln
  - secret

skip-dirs:
  - vendor/
  - node_modules/
  - .git/
  - storage/
  - bootstrap/cache/

skip-files:
  - vendor/laravel/pint/builds/pint
  - .dockerignore
  - .gitignore
"@

$trivyConfig | Out-File -FilePath "$trivyConfigDir\trivy.yaml" -Encoding UTF8
Write-Host "✅ Configuration Trivy créée: $trivyConfigDir\trivy.yaml" -ForegroundColor Green

Write-Host "=== Configuration terminée ===" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser Trivy avec: docker run --rm -v ${PWD}:/app aquasec/trivy:latest fs /app" -ForegroundColor Yellow 