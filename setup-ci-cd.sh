#!/bin/bash

# Script d'installation automatique du pipeline CI/CD Jenkins
# avec Trivy et SonarQube pour le projet Laravel Multi-tenant

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier si Docker est installé
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi
    
    print_success "Docker et Docker Compose sont installés"
}

# Fonction pour créer le réseau Docker
create_network() {
    print_message "Création du réseau Docker pour Jenkins..."
    
    if ! docker network ls | grep -q jenkins; then
        docker network create jenkins
        print_success "Réseau Jenkins créé"
    else
        print_warning "Le réseau Jenkins existe déjà"
    fi
}

# Fonction pour installer Jenkins
install_jenkins() {
    print_message "Installation de Jenkins..."
    
    # Créer le volume Jenkins
    if ! docker volume ls | grep -q jenkins-data; then
        docker volume create jenkins-data
        print_success "Volume Jenkins créé"
    else
        print_warning "Le volume Jenkins existe déjà"
    fi
    
    # Arrêter et supprimer le conteneur Jenkins s'il existe
    if docker ps -a | grep -q jenkins; then
        print_message "Arrêt et suppression du conteneur Jenkins existant..."
        docker stop jenkins 2>/dev/null || true
        docker rm jenkins 2>/dev/null || true
    fi
    
    # Lancer Jenkins
    docker run -d \
        --name jenkins \
        --network jenkins \
        -p 8080:8080 \
        -p 50000:50000 \
        -v jenkins-data:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        jenkins/jenkins:lts-jdk11
    
    print_success "Jenkins installé et démarré"
    print_message "Attente du démarrage de Jenkins..."
    sleep 30
}

# Fonction pour installer SonarQube
install_sonarqube() {
    print_message "Installation de SonarQube..."
    
    # Créer le fichier docker-compose pour SonarQube
    cat > sonarqube-docker-compose.yml << 'EOF'
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
    
    # Arrêter et supprimer le conteneur SonarQube s'il existe
    if docker ps -a | grep -q sonarqube; then
        print_message "Arrêt et suppression du conteneur SonarQube existant..."
        docker stop sonarqube 2>/dev/null || true
        docker rm sonarqube 2>/dev/null || true
    fi
    
    # Lancer SonarQube
    docker-compose -f sonarqube-docker-compose.yml up -d
    
    print_success "SonarQube installé et démarré"
    print_message "Attente du démarrage de SonarQube..."
    sleep 60
}

# Fonction pour installer Trivy sur Jenkins
install_trivy() {
    print_message "Installation de Trivy sur Jenkins..."
    
    # Attendre que Jenkins soit prêt
    print_message "Attente que Jenkins soit prêt..."
    sleep 30
    
    # Installer Trivy dans le conteneur Jenkins
    docker exec jenkins bash -c '
        if ! command -v trivy &> /dev/null; then
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
            trivy image --download-db-only
            trivy fs --download-db-only
        fi
    '
    
    print_success "Trivy installé sur Jenkins"
}

# Fonction pour afficher les informations de configuration
show_configuration_info() {
    print_success "Installation terminée !"
    echo ""
    echo "=== INFORMATIONS DE CONFIGURATION ==="
    echo ""
    echo "🔧 Jenkins:"
    echo "   URL: http://localhost:8080"
    echo "   Mot de passe initial:"
    echo "   $(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo 'Non disponible')"
    echo ""
    echo "🔍 SonarQube:"
    echo "   URL: http://localhost:9000"
    echo "   Utilisateur: admin"
    echo "   Mot de passe: admin"
    echo ""
    echo "📋 Étapes suivantes:"
    echo "1. Accédez à Jenkins et configurez l'utilisateur administrateur"
    echo "2. Installez les plugins suggérés"
    echo "3. Configurez SonarQube (changez le mot de passe admin)"
    echo "4. Créez le projet dans SonarQube avec la clé 'laravel-multitenant'"
    echo "5. Générez un token SonarQube"
    echo "6. Configurez les credentials dans Jenkins"
    echo "7. Créez le job Jenkins avec le Jenkinsfile"
    echo ""
    echo "📚 Documentation complète: CI-CD-SETUP.md"
    echo ""
}

# Fonction pour vérifier l'état des services
check_services_status() {
    print_message "Vérification de l'état des services..."
    
    echo ""
    echo "=== ÉTAT DES SERVICES ==="
    
    # Vérifier Jenkins
    if docker ps | grep -q jenkins; then
        print_success "Jenkins: En cours d'exécution"
    else
        print_error "Jenkins: Arrêté"
    fi
    
    # Vérifier SonarQube
    if docker ps | grep -q sonarqube; then
        print_success "SonarQube: En cours d'exécution"
    else
        print_error "SonarQube: Arrêté"
    fi
    
    # Vérifier Trivy
    if docker exec jenkins command -v trivy &> /dev/null; then
        print_success "Trivy: Installé"
    else
        print_error "Trivy: Non installé"
    fi
    
    echo ""
}

# Fonction pour nettoyer l'installation
cleanup() {
    print_message "Nettoyage de l'installation..."
    
    # Arrêter et supprimer les conteneurs
    docker stop jenkins sonarqube 2>/dev/null || true
    docker rm jenkins sonarqube 2>/dev/null || true
    
    # Supprimer les volumes (optionnel)
    read -p "Voulez-vous supprimer les volumes de données ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume rm jenkins-data sonarqube_data sonarqube_extensions sonarqube_logs 2>/dev/null || true
        print_success "Volumes supprimés"
    fi
    
    # Supprimer le réseau
    docker network rm jenkins 2>/dev/null || true
    
    # Supprimer le fichier docker-compose
    rm -f sonarqube-docker-compose.yml
    
    print_success "Nettoyage terminé"
}

# Fonction d'aide
show_help() {
    echo "Script d'installation du pipeline CI/CD Jenkins"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  install     Installer Jenkins, SonarQube et Trivy"
    echo "  status      Vérifier l'état des services"
    echo "  cleanup     Nettoyer l'installation"
    echo "  help        Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 install    # Installation complète"
    echo "  $0 status     # Vérifier l'état"
    echo "  $0 cleanup    # Nettoyer"
}

# Fonction principale
main() {
    case "${1:-install}" in
        "install")
            print_message "Début de l'installation du pipeline CI/CD..."
            check_docker
            create_network
            install_jenkins
            install_sonarqube
            install_trivy
            show_configuration_info
            check_services_status
            ;;
        "status")
            check_services_status
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Option invalide: $1"
            show_help
            exit 1
            ;;
    esac
}

# Exécuter la fonction principale
main "$@" 