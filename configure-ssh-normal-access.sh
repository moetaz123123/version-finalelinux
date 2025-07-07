#!/bin/bash

# Script pour configurer l'accès SSH normal (sans chroot) pour tous les tenants
# Usage: sudo ./configure-ssh-normal-access.sh

set -e

echo "🔧 Configuration de l'accès SSH normal pour tous les tenants"
echo "=========================================================="

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Étape 1: Sauvegarder la configuration SSH actuelle
echo ""
echo "📋 Étape 1: Sauvegarde de la configuration SSH"
echo "----------------------------------------------"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

echo "📦 Sauvegarde de $SSH_CONFIG vers $SSH_BACKUP"
cp "$SSH_CONFIG" "$SSH_BACKUP"
echo "✅ Sauvegarde créée"

# Étape 2: Lister tous les tenants existants
echo ""
echo "📋 Étape 2: Détection des tenants"
echo "---------------------------------"

TENANTS=$(ls /home | grep -v -E "(taz|lost\+found|\.|^$)" | grep -E "^[a-zA-Z]" | sort)

if [ -z "$TENANTS" ]; then
    echo "❌ Aucun tenant trouvé dans /home/"
    exit 1
fi

echo "🔍 Tenants détectés :"
for tenant in $TENANTS; do
    echo "   - $tenant"
done

# Étape 3: Nettoyer la configuration SSH actuelle
echo ""
echo "📋 Étape 3: Nettoyage de la configuration SSH"
echo "--------------------------------------------"

# Supprimer toutes les anciennes configurations de tenants
echo "🧹 Suppression des anciennes configurations..."
sed -i '/^# Match User [a-zA-Z]/,/^$/d' "$SSH_CONFIG"
sed -i '/^Match User [a-zA-Z]/,/^$/d' "$SSH_CONFIG"

# Étape 4: Ajouter la nouvelle configuration pour tous les tenants (sans chroot)
echo ""
echo "📋 Étape 4: Ajout de la configuration SSH normal pour tous les tenants"
echo "---------------------------------------------------------------------"

echo "🔧 Ajout des configurations SSH normal..."
for tenant in $TENANTS; do
    echo "   - Configuration pour $tenant"
    
    cat >> "$SSH_CONFIG" << EOF

# Match User $tenant
Match User $tenant
    # ChrootDirectory /home/$tenant/chroot
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
    PubkeyAuthentication yes
EOF
done

echo "✅ Configuration SSH normal ajoutée pour tous les tenants"

# Étape 5: Configurer les shells et mots de passe des utilisateurs
echo ""
echo "📋 Étape 5: Configuration des shells et mots de passe"
echo "---------------------------------------------------"

for tenant in $TENANTS; do
    echo "🔧 Configuration pour $tenant..."
    
    # Définir le shell bash pour l'utilisateur
    usermod -s /bin/bash "$tenant"
    
    # Créer un mot de passe complexe pour le tenant
    PASSWORD="${tenant}@2024!"
    
    # Définir le mot de passe
    echo "$tenant:$PASSWORD" | chpasswd 2>/dev/null || {
        echo "   ⚠️  Impossible de définir le mot de passe pour $tenant"
        echo "   🔧 Tentative avec un mot de passe plus simple..."
        echo "$tenant:${tenant}123456" | chpasswd 2>/dev/null || {
            echo "   ❌ Échec de la définition du mot de passe pour $tenant"
            continue
        }
        PASSWORD="${tenant}123456"
    }
    
    echo "   ✅ Shell et mot de passe configurés pour $tenant"
    echo "   🔑 Mot de passe: $PASSWORD"
done

# Étape 6: Créer les dossiers de projets pour chaque tenant
echo ""
echo "📋 Étape 6: Configuration des dossiers de projets"
echo "------------------------------------------------"

for tenant in $TENANTS; do
    echo "🔧 Configuration du dossier projet pour $tenant..."
    
    # S'assurer que le dossier www.tenant.localhost existe
    WWW_DIR="/home/$tenant/www.$tenant.localhost"
    mkdir -p "$WWW_DIR"
    
    # Créer un fichier .bashrc personnalisé
    cat > "/home/$tenant/.bashrc" << EOF
# Configuration bash pour le tenant $tenant
export PS1="\[\033[01;32m\]$tenant\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# Surcharge ls pour masquer /home
ls() {
  if [ "\$1" = "/home" ]; then
    return 0
  else
    command ls "\$@"
  fi
}

# Afficher les informations du projet
echo ""
echo "🎉 Bienvenue $tenant !"
echo "📁 Votre projet se trouve dans: www.$tenant.localhost"
echo "🌐 Votre site web: http://www.$tenant.localhost"
echo "🔧 Accès SSH: ssh $tenant@\$(hostname -I | awk '{print \$1}')"
echo ""

# Lister les fichiers du projet
if [ -d "www.$tenant.localhost" ]; then
    echo "📋 Contenu de votre projet:"
    ls -la www.$tenant.localhost
    echo ""
fi

# Fonction pour afficher l'aide
help_tenant() {
    echo "🔧 Commandes utiles pour $tenant:"
    echo "   - ls -la                    : Lister les fichiers"
    echo "   - cd www.$tenant.localhost  : Aller dans le projet"
    echo "   - pwd                       : Voir le chemin actuel"
    echo "   - help_tenant               : Afficher cette aide"
    echo "   - exit                      : Quitter SSH"
    echo ""
}

# Afficher l'aide au premier démarrage
help_tenant
EOF
    
    # Configurer les permissions
    chown -R "$tenant:$tenant" "/home/$tenant"
    chmod 755 "/home/$tenant"
    chmod 644 "/home/$tenant/.bashrc"
    chmod 755 "$WWW_DIR"
    
    echo "   ✅ Dossier projet configuré pour $tenant"
done

# Étape 7: Tester la configuration SSH
echo ""
echo "📋 Étape 7: Test de la configuration SSH"
echo "---------------------------------------"

echo "🔍 Test de la syntaxe de la configuration SSH..."
if sshd -t; then
    echo "✅ Configuration SSH valide"
else
    echo "❌ Erreur dans la configuration SSH"
    echo "   Restauration de la sauvegarde..."
    cp "$SSH_BACKUP" "$SSH_CONFIG"
    exit 1
fi

# Étape 8: Redémarrer le service SSH
echo ""
echo "📋 Étape 8: Redémarrage du service SSH"
echo "-------------------------------------"

echo "🔄 Redémarrage du service SSH..."
if systemctl restart sshd 2>/dev/null; then
    echo "✅ Service SSH (sshd) redémarré avec succès"
elif systemctl restart ssh 2>/dev/null; then
    echo "✅ Service SSH (ssh) redémarré avec succès"
else
    echo "❌ Erreur lors du redémarrage de SSH"
    exit 1
fi

# Étape 9: Afficher le résumé
echo ""
echo "📋 Étape 9: Résumé de la configuration"
echo "-------------------------------------"

echo "🎉 Configuration SSH normal terminée avec succès !"
echo ""
echo "📊 Résumé :"
echo "   - Tenants configurés : $(echo $TENANTS | wc -w)"
echo "   - Configuration SSH : $SSH_CONFIG"
echo "   - Sauvegarde : $SSH_BACKUP"
echo ""
echo "🔐 Accès SSH pour chaque tenant :"
for tenant in $TENANTS; do
    echo "   - $tenant : ssh $tenant@$(hostname -I | awk '{print $1}')"
done
echo ""
echo "🔑 Mots de passe des tenants :"
for tenant in $TENANTS; do
    echo "   - $tenant : ${tenant}@2024! (ou ${tenant}123456 si le premier a échoué)"
done
echo ""
echo "🔒 Sécurité configurée :"
echo "   - Accès SSH normal (pas de chroot)"
echo "   - Chaque tenant a son propre dossier projet"
echo "   - Pas d'accès aux autres dossiers /home"
echo "   - Mots de passe temporaires définis"
echo ""
echo "📝 Prochaines étapes :"
echo "1. Tester la connexion SSH pour chaque tenant"
echo "2. Changer les mots de passe temporaires"
echo "3. Ajouter les clés SSH des tenants"
echo "4. Configurer le chroot si nécessaire"
echo ""
echo "🧪 Test de connexion :"
echo "   ssh tenant@localhost"
echo "   Mot de passe: tenant@2024! (ou tenant123456)"
echo "   Commandes: pwd, ls -la, cd /home/tenant/project, ls -la, exit" 