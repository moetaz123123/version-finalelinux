# Pipeline CI/CD Jenkins avec Trivy et SonarQube

Ce document décrit la configuration complète d'un pipeline CI/CD Jenkins pour le projet Laravel Multi-tenant avec analyse de sécurité (Trivy) et qualité de code (SonarQube).

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation Jenkins](#installation-jenkins)
3. [Configuration SonarQube](#configuration-sonarqube)
4. [Configuration Trivy](#configuration-trivy)
5. [Configuration du Pipeline](#configuration-du-pipeline)
6. [Utilisation](#utilisation)
7. [Dépannage](#dépannage)

## 🔧 Prérequis

### Système
- Ubuntu 20.04+ ou CentOS 8+
- Docker et Docker Compose
- Java 11+
- Git

### Espace disque
- Jenkins: 10GB minimum
- SonarQube: 5GB minimum
- Docker images: 5GB minimum

## 🚀 Installation Jenkins

### 1. Installation via Docker

```bash
# Créer un réseau Docker
docker network create jenkins

# Créer un volume pour Jenkins
docker volume create jenkins-data

# Lancer Jenkins
docker run -d \
  --name jenkins \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk11
```

### 2. Configuration initiale

1. Accédez à `http://localhost:8080`
2. Récupérez le mot de passe initial :
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Installez les plugins suggérés
4. Créez un utilisateur administrateur

### 3. Installation des plugins requis

Dans Jenkins > Manage Jenkins > Manage Plugins > Available :

- **Pipeline**: workflow-aggregator
- **Git**: git
- **SonarQube**: sonar, sonar-quality-gates
- **Docker**: docker-plugin, docker-workflow
- **Security**: trivy, dependency-check-jenkins-plugin
- **Code Quality**: warnings-ng, cobertura
- **Notifications**: email-ext, slack
- **UI**: blueocean

## 🔍 Configuration SonarQube

### 1. Installation SonarQube

```bash
# Créer un docker-compose pour SonarQube
cat > sonarqube-docker-compose.yml << EOF
version: '3.8'
services:
  sonarqube:
    image: sonarqube:9.9-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
EOF

# Lancer SonarQube
docker-compose -f sonarqube-docker-compose.yml up -d
```

### 2. Configuration SonarQube

1. Accédez à `http://localhost:9000`
2. Connectez-vous avec `admin/admin`
3. Changez le mot de passe
4. Créez un nouveau projet :
   - **Project key**: `laravel-multitenant`
   - **Project name**: `Laravel Multi-tenant Application`
   - **Main branch**: `main`

### 3. Génération du token SonarQube

1. Allez dans **My Account** > **Security**
2. Générez un nouveau token
3. Copiez le token (vous en aurez besoin pour Jenkins)

### 4. Configuration Jenkins pour SonarQube

Dans Jenkins > Manage Jenkins > Configure System :

1. **SonarQube servers** :
   - **Name**: `SonarQube`
   - **Server URL**: `http://localhost:9000`
   - **Server authentication token**: `[Votre token SonarQube]`

2. **SonarQube Scanner installations** :
   - **Name**: `SonarQubeScanner`
   - **Installation directory**: `/opt/sonar-scanner`

## 🛡️ Configuration Trivy

### 1. Installation Trivy sur Jenkins

```bash
# Se connecter au conteneur Jenkins
docker exec -it jenkins bash

# Installer Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Vérifier l'installation
trivy --version
```

### 2. Configuration des bases de données Trivy

```bash
# Mettre à jour les bases de données
trivy image --download-db-only
trivy fs --download-db-only
```

## ⚙️ Configuration du Pipeline

### 1. Création du job Jenkins

1. **New Item** > **Pipeline**
2. **Name**: `laravel-multitenant-pipeline`
3. **Description**: `Pipeline CI/CD pour Laravel Multi-tenant`

### 2. Configuration du pipeline

Dans **Pipeline** > **Definition** :
- **Definition**: `Pipeline script from SCM`
- **SCM**: `Git`
- **Repository URL**: `[URL de votre repo GitHub]`
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`

### 3. Configuration des credentials

Dans Jenkins > Manage Jenkins > Manage Credentials :

1. **SonarQube Token** :
   - **Kind**: `Secret text`
   - **ID**: `sonar-token`
   - **Secret**: `[Votre token SonarQube]`

2. **GitHub Credentials** (si nécessaire) :
   - **Kind**: `Username with password`
   - **ID**: `github-credentials`
   - **Username**: `[Votre username GitHub]`
   - **Password**: `[Votre token GitHub]`

### 4. Configuration des triggers

Dans **Build Triggers** :
- ✅ **GitHub hook trigger for GITScm polling**
- ✅ **Poll SCM** (optionnel)
  - **Schedule**: `H/5 * * * *` (toutes les 5 minutes)

## 🚀 Utilisation

### 1. Premier lancement

```bash
# Dans Jenkins, cliquez sur "Build Now"
# Ou poussez du code sur la branche main
git push origin main
```

### 2. Monitoring du pipeline

- **Jenkins**: `http://localhost:8080`
- **SonarQube**: `http://localhost:9000`
- **Blue Ocean**: `http://localhost:8080/blue`

### 3. Interprétation des résultats

#### SonarQube
- **Quality Gate**: Pass/Fail basé sur les métriques définies
- **Coverage**: Pourcentage de code couvert par les tests
- **Duplications**: Code dupliqué détecté
- **Vulnerabilities**: Vulnérabilités de sécurité
- **Code Smells**: Problèmes de qualité de code

#### Trivy
- **Vulnerabilities**: Vulnérabilités dans les dépendances
- **Secrets**: Secrets exposés dans le code
- **Misconfigurations**: Mauvaise configuration Docker

## 🔧 Dépannage

### Problèmes courants

#### 1. Jenkins ne peut pas accéder à SonarQube
```bash
# Vérifier que SonarQube est accessible
curl http://localhost:9000/api/system/status

# Vérifier les logs
docker logs sonarqube
```

#### 2. Trivy ne trouve pas les vulnérabilités
```bash
# Mettre à jour les bases de données
trivy image --download-db-only
trivy fs --download-db-only

# Vérifier la configuration
trivy config --help
```

#### 3. Pipeline échoue sur les tests
```bash
# Vérifier la configuration PHP
php --version
composer --version

# Vérifier les dépendances
composer install --no-dev
```

#### 4. Problèmes de permissions Docker
```bash
# Ajouter l'utilisateur jenkins au groupe docker
sudo usermod -aG docker jenkins

# Redémarrer Jenkins
docker restart jenkins
```

### Logs utiles

```bash
# Logs Jenkins
docker logs jenkins

# Logs SonarQube
docker logs sonarqube

# Logs du pipeline
# Dans Jenkins > [Job] > [Build] > Console Output
```

## 📊 Métriques et rapports

### SonarQube Metrics
- **Reliability**: Bugs et erreurs
- **Security**: Vulnérabilités et hotspots
- **Maintainability**: Code smells et dette technique
- **Coverage**: Couverture de tests

### Trivy Reports
- **Vulnerability Summary**: Résumé des vulnérabilités
- **Severity Levels**: Critical, High, Medium, Low
- **CVE References**: Références CVE
- **Remediation**: Solutions recommandées

## 🔄 Maintenance

### Mise à jour des outils

```bash
# Mettre à jour Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Mettre à jour SonarQube
docker-compose -f sonarqube-docker-compose.yml pull
docker-compose -f sonarqube-docker-compose.yml up -d

# Mettre à jour Jenkins
docker pull jenkins/jenkins:lts-jdk11
docker stop jenkins
docker rm jenkins
# Relancer avec la nouvelle image
```

### Sauvegarde

```bash
# Sauvegarder Jenkins
docker run --rm -v jenkins-data:/var/jenkins_home -v $(pwd):/backup alpine tar czf /backup/jenkins-backup.tar.gz -C /var/jenkins_home .

# Sauvegarder SonarQube
docker run --rm -v sonarqube_data:/opt/sonarqube/data -v $(pwd):/backup alpine tar czf /backup/sonarqube-backup.tar.gz -C /opt/sonarqube/data .
```

## 📞 Support

Pour toute question ou problème :
1. Vérifiez les logs mentionnés ci-dessus
2. Consultez la documentation officielle
3. Créez une issue dans le repository du projet 