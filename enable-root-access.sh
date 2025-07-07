#!/bin/bash

# Script simple pour activer l'accès root SSH
# Usage: ./enable-root-access.sh

echo "🔑 Activation de l'accès root SSH"
echo "================================"

# Sauvegarder la configuration SSH
SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

echo "📦 Sauvegarde vers $SSH_BACKUP"
sudo cp "$SSH_CONFIG" "$SSH_BACKUP"
echo "✅ Sauvegarde créée"

# Activer l'accès root
echo "🔑 Activation accès root..."
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' "$SSH_CONFIG"
sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' "$SSH_CONFIG"

# Définir le mot de passe root
ROOT_PASSWORD="Root@2024!"
echo "root:$ROOT_PASSWORD" | sudo chpasswd

echo "✅ Accès root configuré"
echo "🔑 Mot de passe root : $ROOT_PASSWORD"

# Redémarrer SSH
echo "🔄 Redémarrage SSH..."
sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null

echo ""
echo "🎉 ACCÈS ROOT ACTIVÉ !"
echo "====================="
echo ""
echo "🔑 Connexion : ssh root@localhost"
echo "🔑 Mot de passe : $ROOT_PASSWORD"
echo ""
echo "💡 Testez maintenant : ssh root@localhost" 