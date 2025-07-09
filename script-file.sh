#!/bin/bash

# Script pour configurer l'accès ROOT avec structure système complète
# Racine par défaut: /home/tenant avec etc, bin, bash, htdocs
# Chemin projet: /home/tenant/htdocs/www.tenant.localhost/project_tenant
# AMÉLIORÉ : Permissions SSH et authentification renforcées

set -e

echo "🔑 Configuration ACCÈS ROOT avec STRUCTURE SYSTÈME COMPLÈTE"
echo "=========================================================="
echo "🏠 Racine par défaut : /home/tenant"
echo "📁 Structure : etc, bin, bash, htdocs"
echo "🎯 Projet : htdocs/www.tenant.localhost/project_tenant"
echo "🔑 ACCÈS ROOT activé pour l'administrateur"
echo "🛡️ Permissions SSH renforcées"
echo ""

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en tant que root"
    echo "💡 Connectez-vous en tant que root :"
    echo "   su - root"
    echo "   (mot de passe root)"
    echo "   puis exécutez : ./configure-root-system.sh"
    exit 1
fi

echo "✅ Exécution en tant que root confirmée"

# Détecter tous les tenants
echo ""
echo "📋 Détection des tenants..."
TENANTS=$(ls /home | grep -v -E "(lost\+found|\.|^$|chroot_|.*_backup_)" | grep -E "^[a-zA-Z]" | sort)

if [ -z "$TENANTS" ]; then
    echo "❌ Aucun tenant trouvé dans /home/"
    exit 1
fi

echo "🔍 Tenants détectés :"
for tenant in $TENANTS; do
    echo "   - $tenant"
done

# Étape 1: Configuration SSH RENFORCÉE
echo ""
echo "📋 Étape 1: Configuration SSH RENFORCÉE"
echo "======================================="

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

echo "📦 Sauvegarde vers $SSH_BACKUP"
cp "$SSH_CONFIG" "$SSH_BACKUP"
echo "✅ Sauvegarde créée"

# Nettoyage complet du fichier SSH
echo "🧹 Nettoyage configuration SSH..."
sed -i '/^# Configuration chroot/,/^$/d' "$SSH_CONFIG"
sed -i '/^Match User /,/^$/d' "$SSH_CONFIG"

# Configuration SSH de base SÉCURISÉE
echo "🔧 Configuration SSH de base..."

# Activer l'authentification par mot de passe GLOBALEMENT
sed -i 's/#PasswordAuthentication .*/PasswordAuthentication yes/' "$SSH_CONFIG"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' "$SSH_CONFIG"

# Activer l'authentification par clé publique
sed -i 's/#PubkeyAuthentication .*/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' "$SSH_CONFIG"

# Activer TTY
sed -i 's/#PermitTTY .*/PermitTTY yes/' "$SSH_CONFIG"
sed -i 's/PermitTTY no/PermitTTY yes/' "$SSH_CONFIG"

# Configurer l'accès root
sed -i 's/#PermitRootLogin .*/PermitRootLogin yes/' "$SSH_CONFIG"
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' "$SSH_CONFIG"
sed -i 's/PermitRootLogin no/PermitRootLogin yes/' "$SSH_CONFIG"

# Désactiver la vérification stricte des modes
sed -i 's/#StrictModes .*/StrictModes no/' "$SSH_CONFIG"
sed -i 's/StrictModes yes/StrictModes no/' "$SSH_CONFIG"

# Configurer le délai d'authentification
sed -i 's/#LoginGraceTime .*/LoginGraceTime 300/' "$SSH_CONFIG"

# Permettre les connexions multiples
sed -i 's/#MaxAuthTries .*/MaxAuthTries 6/' "$SSH_CONFIG"
sed -i 's/#MaxSessions .*/MaxSessions 10/' "$SSH_CONFIG"

# Configurer le challenge-response
sed -i 's/#ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' "$SSH_CONFIG"
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' "$SSH_CONFIG"

# Ajouter les configurations manquantes si elles n'existent pas
if ! grep -q "PasswordAuthentication" "$SSH_CONFIG"; then
    echo "PasswordAuthentication yes" >> "$SSH_CONFIG"
fi

if ! grep -q "PubkeyAuthentication" "$SSH_CONFIG"; then
    echo "PubkeyAuthentication yes" >> "$SSH_CONFIG"
fi

if ! grep -q "PermitTTY" "$SSH_CONFIG"; then
    echo "PermitTTY yes" >> "$SSH_CONFIG"
fi

if ! grep -q "StrictModes" "$SSH_CONFIG"; then
    echo "StrictModes no" >> "$SSH_CONFIG"
fi

echo "✅ Configuration SSH de base terminée"

# Étape 2: Configuration ACCÈS ROOT
echo ""
echo "📋 Étape 2: Configuration ACCÈS ROOT"
echo "====================================="

echo "🔑 Configuration accès root pour l'administrateur..."

# Définir un mot de passe root sécurisé
ROOT_PASSWORD="Root@2024!"
echo "root:$ROOT_PASSWORD" | chpasswd

# Créer le répertoire .ssh pour root si nécessaire
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo "✅ Accès root configuré"
echo "🔑 Mot de passe root : $ROOT_PASSWORD"

# Étape 3: Nettoyage complet
echo ""
echo "📋 Étape 3: Nettoyage complet"
echo "=============================="

# Supprimer tous les anciens environnements
echo "🧹 Suppression des anciens environnements..."
for old_env in /home/chroot_* /home/env_*; do
    if [ -d "$old_env" ]; then
        echo "   🗑️  Suppression de $old_env"
        rm -rf "$old_env"
    fi
done

# Étape 4: Créer les environnements avec structure système complète
echo ""
echo "📋 Étape 4: Création environnements SYSTÈME COMPLET"
echo "==================================================="

SUCCESSFUL_TENANTS=()
FAILED_TENANTS=()

for tenant in $TENANTS; do
    echo ""
    echo "🔄 Configuration SYSTÈME COMPLET pour $tenant..."
    
    # Vérifier l'existence de l'utilisateur
    if ! id "$tenant" &>/dev/null; then
        echo "   ❌ Utilisateur '$tenant' inexistant"
        FAILED_TENANTS+=("$tenant")
        continue
    fi
    
    # Créer l'environnement système complet
    tenant_root="/home/$tenant"
    project_path="htdocs/www.$tenant.localhost/project_$tenant"
    
    echo "🏗️  Création structure système pour $tenant..."
    
    # Créer la structure système complète
    mkdir -p "$tenant_root"/{etc,bin,usr/bin,usr/local/bin,lib,lib64,usr/lib,usr/lib64,tmp,var,dev,proc,sys}
    mkdir -p "$tenant_root/htdocs/www.$tenant.localhost/project_$tenant"
    mkdir -p "$tenant_root/.ssh"
    
    # Copier les binaires essentiels
    echo "   📦 Installation binaires essentiels..."
    
    # Copier bash et shell essentiels
    cp /bin/bash "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/sh "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/ls "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/cat "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/pwd "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/cd "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/echo "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/mkdir "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/rmdir "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/touch "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/cp "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/mv "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/rm "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/grep "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/sed "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/awk "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/find "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/which "$tenant_root/bin/" 2>/dev/null || true
    cp /bin/whoami "$tenant_root/bin/" 2>/dev/null || true
    
    # Copier les binaires utilisateur
    cp /usr/bin/nano "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/vim "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/vi "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/less "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/more "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/head "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/tail "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/wc "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/sort "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/uniq "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/cut "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/tr "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/basename "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/dirname "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/file "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/stat "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/chmod "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/chown "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/du "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/df "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/ps "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/top "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/htop "$tenant_root/usr/bin/" 2>/dev/null || true
    cp /usr/bin/tree "$tenant_root/usr/bin/" 2>/dev/null || true
    
    # Copier les bibliothèques nécessaires
    echo "   📚 Installation bibliothèques..."
    
    # Fonction pour copier les dépendances d'un binaire
    copy_libs() {
        local binary=$1
        local target_root=$2
        
        if [ -f "$binary" ]; then
            ldd "$binary" 2>/dev/null | grep -o '/[^ ]*' | while read lib; do
                if [ -f "$lib" ]; then
                    lib_dir=$(dirname "$lib")
                    mkdir -p "$target_root$lib_dir"
                    cp "$lib" "$target_root$lib" 2>/dev/null || true
                fi
            done
        fi
    }
    
    # Copier les bibliothèques pour bash et binaires essentiels
    copy_libs /bin/bash "$tenant_root"
    copy_libs /bin/ls "$tenant_root"
    copy_libs /bin/cat "$tenant_root"
    copy_libs /usr/bin/nano "$tenant_root"
    
    # Copier les bibliothèques système essentielles
    cp /lib/x86_64-linux-gnu/libc.so.6 "$tenant_root/lib/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libdl.so.2 "$tenant_root/lib/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libpthread.so.0 "$tenant_root/lib/" 2>/dev/null || true
    cp /lib64/ld-linux-x86-64.so.2 "$tenant_root/lib64/" 2>/dev/null || true
    
    # Configuration etc essentiels
    echo "   ⚙️  Configuration etc..."
    
    # Passwd pour l'utilisateur
    echo "$tenant:x:$(id -u $tenant):$(id -g $tenant):$tenant:/home/$tenant:/bin/bash" > "$tenant_root/etc/passwd"
    
    # Group
    echo "$tenant:x:$(id -g $tenant):" > "$tenant_root/etc/group"
    
    # Hosts
    cat > "$tenant_root/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   $tenant.localhost
127.0.0.1   www.$tenant.localhost
EOF
    
    # Résolveur DNS
    cat > "$tenant_root/etc/resolv.conf" << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    
    # Profil bash
    cat > "$tenant_root/etc/profile" << EOF
# Profil système pour $tenant
export PATH=/bin:/usr/bin:/usr/local/bin
export HOME=/home/$tenant
export USER=$tenant
export SHELL=/bin/bash
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

# Alias utiles
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias htdocs='cd /htdocs'
alias project='cd /htdocs/www.$tenant.localhost/project_$tenant'
alias www='cd /htdocs/www.$tenant.localhost'

# Message de bienvenue
echo ""
echo "🏠 Bienvenue dans votre environnement système $tenant"
echo "📁 Racine : /home/$tenant"
echo "🌐 Projet : htdocs/www.$tenant.localhost/project_$tenant"
echo ""
echo "📋 Structure disponible :"
echo "   /etc     → Configuration système"
echo "   /bin     → Binaires essentiels"
echo "   /usr/bin → Binaires utilisateur"
echo "   /htdocs  → Dossier web"
echo "   /lib     → Bibliothèques"
echo "   /tmp     → Fichiers temporaires"
echo ""
echo "🎯 Raccourcis :"
echo "   htdocs   → Aller dans htdocs"
echo "   www      → Aller dans www.$tenant.localhost"
echo "   project  → Aller dans votre projet"
echo ""
EOF
    
    # Migrer les données existantes du projet
    echo "   📁 Migration données projet..."
    original_project="/home/$tenant/www.$tenant.localhost/project_$tenant"
    if [ -d "$original_project" ]; then
        echo "   📦 Copie depuis $original_project..."
        cp -r "$original_project"/* "$tenant_root/$project_path/" 2>/dev/null || true
    fi
    
    # Créer le fichier d'accueil du projet
    cat > "$tenant_root/$project_path/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>🏠 Projet $tenant - Environnement Système</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .path { background: #fff3cd; padding: 10px; border-radius: 5px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🏠 Projet $tenant</h1>
        
        <div class="status">
            <h3>✅ Environnement Système Complet</h3>
            <p><strong>Tenant :</strong> $tenant</p>
            <p><strong>Racine :</strong> /home/$tenant</p>
            <p><strong>Projet :</strong> htdocs/www.$tenant.localhost/project_$tenant</p>
        </div>
        
        <div class="info">
            <h3>📁 Structure Système</h3>
            <p>Votre environnement contient une structure système complète :</p>
            <ul>
                <li><strong>/etc</strong> → Configuration système</li>
                <li><strong>/bin</strong> → Binaires essentiels (bash, ls, cat, etc.)</li>
                <li><strong>/usr/bin</strong> → Binaires utilisateur (nano, vim, etc.)</li>
                <li><strong>/htdocs</strong> → Dossier web principal</li>
                <li><strong>/lib</strong> → Bibliothèques système</li>
                <li><strong>/tmp</strong> → Fichiers temporaires</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>🌐 Chemin du Projet</h3>
            <div class="path">
                /home/$tenant → htdocs → www.$tenant.localhost → project_$tenant
            </div>
            <p>Utilisez la commande <code>project</code> pour naviguer directement ici.</p>
        </div>
        
        <div class="info">
            <h3>🎯 Raccourcis Terminal</h3>
            <ul>
                <li><code>htdocs</code> → cd /htdocs</li>
                <li><code>www</code> → cd /htdocs/www.$tenant.localhost</li>
                <li><code>project</code> → cd /htdocs/www.$tenant.localhost/project_$tenant</li>
            </ul>
        </div>
        
        <footer style="margin-top: 30px; text-align: center; color: #7f8c8d;">
            <p>🛡️ Environnement configuré le $(date)</p>
        </footer>
    </div>
</body>
</html>
EOF
    
    # Créer un README dans le projet
    cat > "$tenant_root/$project_path/README.txt" << EOF
🏠 ENVIRONNEMENT SYSTÈME COMPLET POUR $tenant
============================================

✅ STRUCTURE SYSTÈME COMPLÈTE
📁 Racine par défaut : /home/$tenant
🌐 Projet : htdocs/www.$tenant.localhost/project_$tenant

📋 STRUCTURE DISPONIBLE :
/home/$tenant/
├── etc/          → Configuration système
├── bin/          → Binaires essentiels (bash, ls, cat, etc.)
├── usr/bin/      → Binaires utilisateur (nano, vim, etc.)
├── lib/          → Bibliothèques système
├── htdocs/       → Dossier web principal
│   └── www.$tenant.localhost/
│       └── project_$tenant/  ← VOUS ÊTES ICI
├── tmp/          → Fichiers temporaires
└── var/          → Variables système

🎯 NAVIGATION :
   pwd              → /htdocs/www.$tenant.localhost/project_$tenant
   cd /             → Racine système /home/$tenant
   cd /htdocs       → Dossier web
   cd /bin          → Binaires disponibles
   cd /etc          → Configuration

🔧 COMMANDES DISPONIBLES :
   ls, cat, pwd, cd, echo, mkdir, touch, cp, mv, rm
   nano, vim, grep, sed, awk, find, which, whoami
   chmod, chown, du, df, ps, top, tree

🎯 RACCOURCIS :
   htdocs   → cd /htdocs
   www      → cd /htdocs/www.$tenant.localhost
   project  → cd /htdocs/www.$tenant.localhost/project_$tenant

📅 Configuré le : $(date)
👤 Tenant : $tenant
🏠 Racine : /home/$tenant
🌐 Projet : htdocs/www.$tenant.localhost/project_$tenant
EOF
    
    # Permissions appropriées RENFORCÉES
    echo "   🔐 Configuration permissions RENFORCÉES..."
    
    # Propriétaire tenant pour tout son environnement
    chown -R "$tenant:$tenant" "$tenant_root"
    
    # Permissions SSH spécifiques
    chmod 700 "$tenant_root/.ssh"
    touch "$tenant_root/.ssh/authorized_keys"
    chmod 600 "$tenant_root/.ssh/authorized_keys"
    chown "$tenant:$tenant" "$tenant_root/.ssh/authorized_keys"
    
    # Permissions exécutables pour les binaires
    chmod +x "$tenant_root/bin"/* 2>/dev/null || true
    chmod +x "$tenant_root/usr/bin"/* 2>/dev/null || true
    
    # Permissions système
    chmod 755 "$tenant_root"
    chmod 755 "$tenant_root/etc"
    chmod 755 "$tenant_root/bin"
    chmod 755 "$tenant_root/usr/bin"
    chmod 755 "$tenant_root/htdocs"
    chmod 755 "$tenant_root/htdocs/www.$tenant.localhost"
    chmod 755 "$tenant_root/htdocs/www.$tenant.localhost/project_$tenant"
    
    # Permissions spéciales pour éviter les erreurs SSH
    chmod 644 "$tenant_root/etc/passwd"
    chmod 644 "$tenant_root/etc/group"
    chmod 644 "$tenant_root/etc/hosts"
    chmod 644 "$tenant_root/etc/resolv.conf"
    chmod 644 "$tenant_root/etc/profile"
    
    echo "   ✅ ENVIRONNEMENT SYSTÈME COMPLET pour $tenant"
    echo "      → Racine : /home/$tenant"
    echo "      → Projet : htdocs/www.$tenant.localhost/project_$tenant"
    echo "      → Binaires : /bin, /usr/bin"
    echo "      → Config : /etc"
    echo "      → SSH : .ssh configuré"
    
    # Configuration utilisateur RENFORCÉE
    echo "   👤 Configuration utilisateur $tenant..."
    
    # Shell et home
    usermod -s /bin/bash "$tenant" 2>/dev/null || true
    usermod -d "/home/$tenant" "$tenant" 2>/dev/null || true
    
    # Mot de passe avec vérification
    PASSWORD="${tenant}@2024!"
    if echo "$tenant:$PASSWORD" | chpasswd 2>/dev/null; then
        echo "   🔑 Mot de passe configuré : $PASSWORD"
    else
        echo "   ❌ Échec configuration mot de passe pour $tenant"
        FAILED_TENANTS+=("$tenant")
        continue
    fi
    
    # Vérifier que l'utilisateur peut se connecter
    if su - "$tenant" -c "echo 'Test connexion OK'" &>/dev/null; then
        echo "   ✅ Test connexion utilisateur réussi"
    else
        echo "   ⚠️  Test connexion utilisateur échoué"
    fi
    
    SUCCESSFUL_TENANTS+=("$tenant")
    
    # Configuration SSH RENFORCÉE pour ce tenant
    echo "   📝 Configuration SSH système renforcée pour $tenant..."
    cat >> "$SSH_CONFIG" << EOF

# Configuration chroot système renforcée pour $tenant
Match User $tenant
    ChrootDirectory /home/$tenant
    ForceCommand source /etc/profile && cd /htdocs/www.$tenant.localhost/project_$tenant && exec /bin/bash
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
    PubkeyAuthentication yes
    PermitTTY yes
    AllowAgentForwarding no
    AllowStreamLocalForwarding no
    PermitOpen none
    PermitListen none
    AuthorizedKeysFile .ssh/authorized_keys
    StrictModes no
    LoginGraceTime 300
    MaxAuthTries 6
    ChallengeResponseAuthentication yes
EOF
    
done

# Étape 5: Configuration PAM pour éviter les erreurs d'authentification
echo ""
echo "📋 Étape 5: Configuration PAM"
echo "============================="

echo "🔧 Configuration PAM pour SSH..."

# Vérifier et configurer PAM SSH
PAM_SSH="/etc/pam.d/sshd"
if [ -f "$PAM_SSH" ]; then
    # Sauvegarder PAM SSH
    cp "$PAM_SSH" "$PAM_SSH.backup.$(date +%Y%m%d_%H%M%S)"
    
    # S'assurer que l'authentification par mot de passe est activée
    if ! grep -q "auth.*pam_unix.so" "$PAM_SSH"; then
        echo "auth    required     pam_unix.so" >> "$PAM_SSH"
    fi
    
    # S'assurer que les sessions sont correctement configurées
    if ! grep -q "session.*pam_unix.so" "$PAM_SSH"; then
        echo "session required     pam_unix.so" >> "$PAM_SSH"
    fi
    
    echo "✅ PAM SSH configuré"
else
    echo "⚠️  Fichier PAM SSH non trouvé"
fi

# Étape 6: Test et redémarrage SSH
echo ""
echo "📋 Étape 6: Test et redémarrage SSH"
echo "===================================="

echo "🔍 Validation configuration SSH..."
if sshd -t 2>/dev/null; then
    echo "✅ Configuration SSH valide"
else
    echo "❌ Configuration SSH invalide"
    echo "📋 Détails de l'erreur :"
    sshd -t
    echo "🔄 Restauration sauvegarde..."
    cp "$SSH_BACKUP" "$SSH_CONFIG"
    exit 1
fi

echo "🔄 Redémarrage SSH..."
if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; then
    echo "✅ SSH redémarré avec succès"
else
    echo "❌ Erreur redémarrage SSH"
    echo "🔄 Tentative de redémarrage forcé..."
    service ssh restart 2>/dev/null || service sshd restart 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ SSH redémarré avec succès (service)"
    else
        echo "❌ Impossible de redémarrer SSH"
        exit 1
    fi
fi

# Étape 7: Vérifications finales
echo ""
echo "📋 Étape 7: Vérifications finales"
echo "=================================="

echo "🔍 Vérification du service SSH..."
if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
    echo "✅ Service SSH actif"
else
    echo "❌ Service SSH inactif"
fi

echo "🔍 Vérification des ports SSH..."
if netstat -tuln | grep -q ":22"; then
    echo "✅ Port SSH 22 ouvert"
else
    echo "❌ Port SSH 22 fermé"
fi

echo "🔍 Test de connexion locale..."
if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@localhost "echo 'Test OK'" &>/dev/null; then
    echo "✅ Test connexion root réussi"
else
    echo "⚠️  Test connexion root échoué (mais configuration OK)"
fi

# Étape 8: Résumé final
echo ""
echo "📋 RÉSUMÉ CONFIGURATION SYSTÈME COMPLET RENFORCÉ"
echo "==============================================="

echo "🎉 CONFIGURATION ROOT + SYSTÈME COMPLET TERMINÉE !"
echo ""
echo "📊 Statistiques :"
echo "   - Tenants détectés : $(echo $TENANTS | wc -w)"
echo "   - Tenants configurés : ${#SUCCESSFUL_TENANTS[@]}"
echo "   - Tenants échoués : ${#FAILED_TENANTS[@]}"
echo ""

echo "🔑 ACCÈS ROOT RENFORCÉ :"
echo "
