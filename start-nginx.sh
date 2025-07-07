#!/bin/bash

echo "🚀 Démarrage du projet Laravel avec Nginx..."

# Vérification des permissions
echo "📁 Configuration des permissions..."
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Vérification de la configuration Nginx
echo "🔧 Test de la configuration Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration Nginx valide"
    
    # Redémarrage des services
    echo "🔄 Redémarrage des services..."
    sudo systemctl restart nginx php8.4-fpm
    
    # Vérification du statut
    echo "📊 Statut des services:"
    sudo systemctl status nginx --no-pager -l
    sudo systemctl status php8.4-fpm --no-pager -l
    
    echo ""
    echo "🌐 Ton application Laravel est maintenant accessible sur:"
    echo "   - http://localhost"
    echo "   - http://ff.localhost (si configuré dans /etc/hosts)"
    echo "   - http://www.ta.localhost (si configuré dans /etc/hosts)"
    echo ""
    echo "📝 N'oublie pas d'ajouter tes sous-domaines dans /etc/hosts:"
    echo "   127.0.0.1 ff.localhost"
    echo "   127.0.0.1 www.ta.localhost"
    echo "   127.0.0.1 www.gt.localhost"
    echo "   127.0.0.1 www.yy.localhost"
    echo "   127.0.0.1 www.oo.localhost"
    echo "   127.0.0.1 www.rr.localhost"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi 