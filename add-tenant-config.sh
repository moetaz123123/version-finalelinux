#!/bin/bash

# Script pour ajouter un nouveau tenant avec port spécifique
# Usage: ./add-tenant-config.sh <tenant_name> <port>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <tenant_name> <port>"
    echo "Exemple: $0 newtenant 50003"
    exit 1
fi

TENANT_NAME=$1
TENANT_PORT=$2
CONFIG_FILE="/etc/nginx/sites-available/laravel-app"

echo "🔄 Ajout du tenant '$TENANT_NAME' sur le port $TENANT_PORT..."

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Sauvegarder la configuration actuelle
echo "📦 Sauvegarde de la configuration actuelle..."
cp $CONFIG_FILE ${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)

# Ajouter le mapping du port dans la section générique
echo "🔧 Ajout du mapping de port..."
sed -i "/# Ajouter d'autres tenants ici.../a if (\$tenant = \"$TENANT_NAME\") { set \$tenant_port $TENANT_PORT; }" $CONFIG_FILE

# Ajouter la configuration du serveur pour le nouveau tenant
echo "🌐 Ajout de la configuration serveur..."
cat >> $CONFIG_FILE << EOF

# Configuration pour $TENANT_NAME sur port $TENANT_PORT
server {
    listen $TENANT_PORT;
    server_name $TENANT_NAME.localhost www.$TENANT_NAME.localhost;

    # Retourne 404 si le dossier du tenant $TENANT_NAME n'existe pas
    if (!-d /home/$TENANT_NAME/www.$TENANT_NAME.localhost/version-welcome/public) {
        return 404;
    }

    root /home/$TENANT_NAME/www.$TENANT_NAME.localhost/version-welcome/public;
    index index.php index.html index.htm;

    access_log /var/log/nginx/$TENANT_NAME.localhost_${TENANT_PORT}_access.log;
    error_log /var/log/nginx/$TENANT_NAME.localhost_${TENANT_PORT}_error.log;

    client_max_body_size 100M;
    client_body_timeout 300s;
    client_header_timeout 300s;
    keepalive_timeout 300s;
    send_timeout 300s;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

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
        echo "🌐 Tenant '$TENANT_NAME' ajouté :"
        echo "   - URL: http://$TENANT_NAME.localhost (redirection automatique)"
        echo "   - Port direct: http://$TENANT_NAME.localhost:$TENANT_PORT"
        echo "   - Dossier: /home/$TENANT_NAME/www.$TENANT_NAME.localhost/version-welcome/public"
    else
        echo "❌ Erreur lors du rechargement de Nginx"
        exit 1
    fi
else
    echo "❌ Erreur de syntaxe dans la configuration Nginx"
    exit 1
fi

echo "🎉 Tenant '$TENANT_NAME' ajouté avec succès !" 