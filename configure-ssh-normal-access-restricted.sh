#!/bin/bash

# Script pour configurer l'accès SSH avec chroot isolé pour LE DERNIER TENANT CRÉÉ
# Détecte automatiquement le tenant le plus récent et configure le chroot SSH pour lui
# Usage: sudo ./configure-ssh-chroot-auto-last.sh

set -e

LOG_FILE="/home/taz/ssh-chroot-auto.log"
echo "=== Script lancé automatiquement le $(date) ===" >> "$LOG_FILE"
echo "[INFO] Tenant détecté et traité : $TENANT" | tee -a "$LOG_FILE"

echo "🔧 Configuration SSH avec chroot isolé pour le dernier tenant créé"
echo "================================================================="

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Fonction pour détecter le dernier tenant créé
detect_latest_tenant() {
    # Méthode : dernier dossier /home/tenant créé, hors admin, chroot, backup, etc.
    LATEST=$(ls -dt /home/[a-zA-Z]* | grep -v -E "(lost\\+found|chroot_|backup|taz|root)" | head -1 | xargs -n1 basename)
    echo "$LATEST"
}

# Détecter le dernier tenant
TENANT=$(detect_latest_tenant)

TENANT=$(echo "$TENANT" | xargs)  # Supprime les espaces avant/après

if [ -z "$TENANT" ]; then
    echo "❌ Aucun tenant détecté dans /home/"
    echo "📋 Tenants disponibles :"
    ls -la /home | grep -E "^d" | grep -v -E "(lost\+found|\.|chroot_|.*_backup_)" | awk '{print $NF}' | sort
    exit 1
fi

# Vérifier que le tenant existe et est valide
if [ ! -d "/home/$TENANT" ]; then
    echo "❌ Le tenant détecté '$TENANT' n'existe pas dans /home/"
    echo "📋 Dossiers valides dans /home :"
    ls -d /home/[a-zA-Z]*
    exit 1
fi

if ! id "$TENANT" &>/dev/null; then
    echo "⚠️  L'utilisateur '$TENANT' n'existe pas, création en cours..."
    useradd -d "/home/$TENANT" -m "$TENANT"
    echo "✅ Utilisateur '$TENANT' créé."
else
    echo "ℹ️  L'utilisateur '$TENANT' existe déjà, configuration du chroot/SSH..."
fi

# Définir (ou réinitialiser) le mot de passe à chaque passage
PASSWORD="${TENANT}@2024!"
echo "$TENANT:$PASSWORD" | chpasswd
echo "🔑 Mot de passe (ré)initialisé pour $TENANT : $PASSWORD"

echo "🎯 Dernier tenant détecté : $TENANT"
echo "📅 Informations sur le tenant :"
echo "   - Dossier home : /home/$TENANT"
echo "   - Utilisateur : $(id $TENANT)"
echo "   - Date création dossier : $(stat -c %y /home/$TENANT)"
echo ""

echo "✅ Configuration automatique sans confirmation utilisateur."

# Étape 1: Sauvegarder la configuration SSH actuelle
echo ""
echo "📋 Étape 1: Sauvegarde de la configuration SSH"
echo "----------------------------------------------"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

echo "📦 Sauvegarde de $SSH_CONFIG vers $SSH_BACKUP"
cp "$SSH_CONFIG" "$SSH_BACKUP"
echo "✅ Sauvegarde créée"

# Étape 2: Nettoyer les anciennes configurations pour ce tenant
echo ""
echo "📋 Étape 2: Nettoyage des anciennes configurations"
echo "------------------------------------------------"

# Supprimer l'ancien chroot s'il existe
CHROOT_DIR="/home/$TENANT-chroot"
if [ -d "$CHROOT_DIR" ]; then
    echo "🧹 Suppression de l'ancien chroot $CHROOT_DIR"
    rm -rf "$CHROOT_DIR"
fi

# Supprimer les anciennes configurations SSH pour ce tenant
echo "🧹 Suppression des anciennes configurations SSH pour $TENANT"
sed -i "/# CHROOT USER: $TENANT/,/^$/d" "$SSH_CONFIG"

# Étape 3: Créer l'environnement chroot isolé
echo ""
echo "📋 Étape 3: Création de l'environnement chroot isolé"
echo "---------------------------------------------------"

setup_chroot_environment() {
    local tenant=$1
    local chroot_dir="/home/$tenant-chroot"
    
    # Calculer le port pour ce tenant
    local port=8080
    
    # Définir le nom du projet
    local project_name="project_$tenant"
    
    echo "🔧 Configuration de l'environnement chroot isolé pour $tenant..."
    
    # Créer le répertoire chroot
    mkdir -p "$chroot_dir"
    
    # Créer la structure minimale nécessaire
    mkdir -p "$chroot_dir"/{bin,lib,lib64,etc,dev,proc,tmp,usr}
    mkdir -p "$chroot_dir/usr"/{bin,lib,lib64}
    mkdir -p "$chroot_dir/home"
    
    # Copier bash et sh dans le chroot
    cp /bin/bash "$chroot_dir/bin/"
    cp /bin/sh "$chroot_dir/bin/"
    
    # Copier les binaires essentiels
    echo "   📦 Copie des binaires essentiels..."
    ESSENTIAL_BINS="ls cat pwd mkdir rm cp mv chmod chown touch nano vi"
    for bin in $ESSENTIAL_BINS; do
        if command -v "$bin" >/dev/null 2>&1; then
            BIN_PATH=$(which "$bin")
            cp "$BIN_PATH" "$chroot_dir/bin/" 2>/dev/null || true
        fi
    done
    
    # Copier les bibliothèques dynamiques
    echo "   📦 Copie des bibliothèques..."
    for binary in /bin/bash /bin/sh /bin/ls /bin/cat /bin/pwd; do
        if [ -f "$binary" ]; then
            ldd "$binary" 2>/dev/null | grep -E "/(lib|lib64)/" | awk '{print $3}' | while read lib; do
                if [ -n "$lib" ] && [ -f "$lib" ]; then
                    lib_dir=$(dirname "$lib")
                    mkdir -p "$chroot_dir$lib_dir"
                    cp "$lib" "$chroot_dir$lib_dir/" 2>/dev/null || true
                fi
            done
        fi
    done
    
    # Copier l'interpréteur dynamique
    echo "   📦 Copie de l'interpréteur dynamique..."
    if [ -f "/lib64/ld-linux-x86-64.so.2" ]; then
        mkdir -p "$chroot_dir/lib64"
        cp "/lib64/ld-linux-x86-64.so.2" "$chroot_dir/lib64/"
    fi
    if [ -f "/lib/ld-linux.so.2" ]; then
        mkdir -p "$chroot_dir/lib"
        cp "/lib/ld-linux.so.2" "$chroot_dir/lib/"
    fi
    
    # Créer les fichiers système essentiels
    echo "   📦 Création des fichiers système..."
    echo "$tenant:x:1000:1000:$tenant:/home:/bin/sh" > "$chroot_dir/etc/passwd"
    
    cat > "$chroot_dir/etc/group" << EOF
root:x:0:
$tenant:x:$(id -g $tenant):
EOF
    
    # Créer les périphériques essentiels
    echo "   📦 Création des périphériques..."
    mknod "$chroot_dir/dev/null" c 1 3 2>/dev/null || true
    mknod "$chroot_dir/dev/zero" c 1 5 2>/dev/null || true
    mknod "$chroot_dir/dev/random" c 1 8 2>/dev/null || true
    mknod "$chroot_dir/dev/urandom" c 1 9 2>/dev/null || true
    
    # CRUCIAL: Créer SEULEMENT le dossier du tenant spécifique
    echo "   📁 Configuration du dossier isolé pour $tenant..."
    
    # Créer le dossier tenant dans le chroot
    mkdir -p "$chroot_dir/home/$tenant"
    mkdir -p "$chroot_dir/home/$tenant/www.$tenant.localhost"
    mkdir -p "$chroot_dir/home/$tenant/www.$tenant.localhost/$project_name"
    
    # Nettoyer le dossier www.tenant.localhost dans le chroot
    rm -rf "$chroot_dir/home/$tenant/www.$tenant.localhost"
    mkdir -p "$chroot_dir/home/$tenant/www.$tenant.localhost"

    # Copier uniquement le dossier du projet (ex: version-welcome)
    if [ -d "/home/$tenant/www.$tenant.localhost/version-welcome" ]; then
        cp -a "/home/$tenant/www.$tenant.localhost/version-welcome" "$chroot_dir/home/$tenant/www.$tenant.localhost/"
        # S'assurer que le propriétaire est bien le tenant
        chown -R "$tenant:$tenant" "$chroot_dir/home/$tenant/www.$tenant.localhost/version-welcome"
        chmod 755 "$chroot_dir/home/$tenant/www.$tenant.localhost/version-welcome"
    fi
    
    # Créer un fichier de bienvenue avec informations sur la détection automatique
    cat > "$chroot_dir/home/$tenant/www.$tenant.localhost/README.txt" << EOF
🎉 Bienvenue $tenant !

✨ TENANT DÉTECTÉ AUTOMATIQUEMENT ✨
Vous êtes le dernier tenant créé sur ce système.

🔒 Environnement sécurisé :
- Vous êtes dans un chroot isolé
- Vous ne pouvez voir que votre propre dossier
- Configuration automatique basée sur la détection du dernier tenant

📁 Structure des dossiers :
- /home/$tenant/www.$tenant.localhost/ (votre dossier home)
- /home/$tenant/www.$tenant.localhost/$project_name/ (votre projet)

🌐 Accès web :
- Votre site web est accessible via http://www.$tenant.localhost:$port

🔧 Commandes disponibles :
- pwd : voir le répertoire actuel
- ls : voir le contenu
- cd $project_name : aller dans le dossier projet
- ls /home : voir seulement votre dossier (isolation)

📅 Informations de détection :
- Date de création : $(date)
- Tenant détecté automatiquement : $tenant
- Isolation activée : OUI
EOF
    
    # Créer un .bashrc personnalisé avec informations de détection
    cat > "$chroot_dir/home/$tenant/.bashrc" << EOF
# Configuration bash pour le tenant $tenant (environnement isolé)
# Tenant détecté automatiquement comme le plus récent

export PS1="\\[\\033[01;32m\\]$tenant@chroot-auto\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ "
export PATH="/bin:/usr/bin"
export HOME="/home/$tenant"
cd /home/$tenant/www.$tenant.localhost

echo "🎯 Tenant détecté automatiquement : $tenant"
echo "🔒 Environnement isolé activé"
echo "📂 Répertoire actuel : \$(pwd)"
echo "📁 Contenu disponible :"
ls -la
echo ""
echo "💡 Utilisez 'cd $project_name' pour aller dans votre projet"
echo "📖 Lisez README.txt pour plus d'informations"
EOF
    
    # Configurer les permissions
    echo "   🔐 Configuration des permissions..."
    chown root:root "$chroot_dir"
    chmod 755 "$chroot_dir"
    
    
    
    # Permissions pour le dossier home
    chmod 755 "$chroot_dir/home"
    
    # Permissions pour le dossier du tenant
    chown -R "$tenant:$tenant" "$chroot_dir/home/$tenant"
    chmod 755 "$chroot_dir/home/$tenant"
    
    # Vérifier l'isolation
    echo "   🔍 Vérification de l'isolation..."
    echo "   📁 Contenu de $chroot_dir/home :"
    ls -la "$chroot_dir/home"
    
    # Vérification finale
    if [ "$(ls "$chroot_dir/home" | wc -l)" -eq 1 ] && [ -d "$chroot_dir/home/$tenant" ]; then
        echo "   ✅ Isolation parfaite : seul $tenant visible"
    else
        echo "   ⚠️  ATTENTION : Problème d'isolation détecté"
        echo "   📁 Contenu actuel :"
        ls -la "$chroot_dir/home"
    fi
    
    echo "   ✅ Environnement chroot isolé configuré pour $tenant"

    # S'assurer que /etc n'existe pas dans le chroot (suppression si présent)
    if [ -d "$chroot_dir/etc" ]; then
        echo "🧹 Suppression de /etc dans le chroot (isolation stricte)"
        rm -rf "$chroot_dir/etc"
    fi
}

# Configurer l'environnement chroot pour le tenant détecté automatiquement
setup_chroot_environment "$TENANT"

# Étape 4: Ajouter la configuration SSH
echo ""
echo "📋 Étape 4: Configuration SSH"
echo "----------------------------"

echo "🔧 Ajout de la configuration SSH avec chroot pour $TENANT..."
cat >> "$SSH_CONFIG" << EOF

# CHROOT USER: $TENANT (Auto-détecté comme dernier tenant)
# Configuré automatiquement le $(date)
Match User $TENANT
    ChrootDirectory /home/$TENANT-chroot
    ForceCommand cd /home && exec /bin/sh
    PermitTTY yes
    PasswordAuthentication yes
EOF

echo "✅ Configuration SSH ajoutée pour $TENANT"

# Étape 5: Configurer l'utilisateur
echo ""
echo "📋 Étape 5: Configuration de l'utilisateur"
echo "-----------------------------------------"

echo "🔧 Configuration de l'utilisateur $TENANT..."

# Définir le shell bash
usermod -d "/home" -s /bin/sh "$TENANT"

# Créer/modifier le mot de passe
PASSWORD="${TENANT}@2024!"
echo "$TENANT:$PASSWORD" | chpasswd 2>/dev/null || {
    echo "   ⚠️  Impossible de définir le mot de passe complexe"
    PASSWORD="${TENANT}123"
    echo "$TENANT:$PASSWORD" | chpasswd
}

echo "✅ Utilisateur $TENANT configuré"
echo "🔑 Mot de passe: $PASSWORD"

# Étape 6: Tester et redémarrer SSH
echo ""
echo "📋 Étape 6: Test et redémarrage SSH"
echo "----------------------------------"

echo "🔍 Test de la configuration SSH..."
if sshd -t 2>/dev/null; then
    echo "✅ Configuration SSH valide"
else
    echo "❌ Erreur dans la configuration SSH"
    sshd -t
    echo "   Restauration de la sauvegarde..."
    cp "$SSH_BACKUP" "$SSH_CONFIG"
    exit 1
fi

echo "🔄 Redémarrage du service SSH..."
if systemctl restart sshd 2>/dev/null; then
    echo "✅ Service SSH redémarré"
elif systemctl restart ssh 2>/dev/null; then
    echo "✅ Service SSH redémarré"
else
    echo "❌ Erreur lors du redémarrage"
    exit 1
fi

# Étape 7: Afficher le résumé
echo ""
echo "📋 Résumé de la configuration automatique"
echo "========================================"

echo "🎉 Configuration SSH avec chroot isolé terminée pour le dernier tenant !"
echo ""
echo "🎯 Tenant détecté automatiquement : $TENANT"
echo "📊 Détails :"
echo "   - Tenant configuré : $TENANT"
echo "   - Détection : Automatique (dernier créé)"
echo "   - Environnement chroot : /home/$TENANT-chroot"
echo "   - Répertoire home : /home/$TENANT/www.$TENANT.localhost"
echo "   - Projet : /home/$TENANT/www.$TENANT.localhost/project_$TENANT"
echo "   - Mot de passe : $PASSWORD"
echo ""
echo "🔐 Connexion SSH :"
echo "   ssh $TENANT@localhost"
echo "   (ou ssh $TENANT@$(hostname -I | awk '{print $1}' 2>/dev/null || echo 'IP_SERVER'))"
echo ""
echo "📁 Structure après connexion :"
echo "   - pwd : /home/$TENANT/www.$TENANT.localhost"
echo "   - ls : voir le contenu de votre dossier"
echo "   - cd project_$TENANT : aller dans votre projet"
echo "   - ls /home : voir SEULEMENT $TENANT (isolation garantie)"
echo ""
echo "🧪 Test de l'isolation :"
echo "   1. Connectez-vous : ssh $TENANT@localhost"
echo "   2. Tapez : pwd"
echo "      → Résultat attendu : /home/$TENANT/www.$TENANT.localhost"
echo "   3. Tapez : ls /home"
echo "      → Résultat attendu : $TENANT seulement"
echo "   4. Tapez : cd /home/$TENANT/www.$TENANT.localhost"
echo "   5. Tapez : ls"
echo "      → Voir votre projet et README.txt"
echo ""
echo "✨ AVANTAGE : Plus besoin de spécifier le tenant, détection automatique !"
echo "🔄 Pour reconfigurer : relancez simplement ce script"
echo ""
echo "✅ L'isolation est maintenant configurée automatiquement pour $TENANT !"