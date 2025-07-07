#!/bin/bash

# Script pour mettre à jour la configuration Nginx avec les sous-domaines
# Usage: ./update-nginx-config.sh

set -e

echo "🔄 Mise à jour de la configuration Nginx..."

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Sauvegarder la configuration actuelle
echo "📦 Sauvegarde de la configuration actuelle..."
cp /etc/nginx/sites-available/laravel-app /etc/nginx/sites-available/laravel-app.backup.$(date +%Y%m%d_%H%M%S)

# Vérifier la syntaxe de la nouvelle configuration
echo "🔍 Vérification de la syntaxe Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Syntaxe Nginx OK"
    
    # Recharger Nginx
    echo "🔄 Rechargement de Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ Nginx rechargé avec succès"
        echo "🌐 Configuration mise à jour :"
        echo "   - localhost : Application Laravel principale"
        echo "   - pma.localhost : phpMyAdmin"
        echo "   - *.localhost : Sous-domaines des tenants"
    else
        echo "❌ Erreur lors du rechargement de Nginx"
        exit 1
    fi
else
    echo "❌ Erreur de syntaxe dans la configuration Nginx"
    exit 1
fi

echo "🎉 Configuration Nginx mise à jour avec succès !" 