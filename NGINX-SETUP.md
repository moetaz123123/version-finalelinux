# Configuration Nginx pour Laravel Multi-Tenant

## 📋 Prérequis

- Ubuntu/Debian avec Nginx installé
- PHP 8.4 avec FPM
- Extension SQLite pour PHP
- Projet Laravel configuré

## 🚀 Installation

### 1. Installation des packages
```bash
sudo apt update
sudo apt install nginx php-fpm php-sqlite3
```

### 2. Configuration Nginx
Le fichier de configuration se trouve dans `/etc/nginx/sites-available/laravel-app`

**Fonctionnalités :**
- Support de localhost et sous-domaines *.localhost
- Configuration PHP-FPM
- Cache pour les assets statiques
- Sécurité renforcée

### 3. Activation du site
```bash
sudo ln -s /etc/nginx/sites-available/laravel-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 4. Permissions
```bash
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### 5. Redémarrage des services
```bash
sudo systemctl restart nginx php8.4-fpm
```

## 🌐 URLs d'accès

- **Page principale :** http://localhost
- **Sous-domaines :** http://ff.localhost, http://www.ta.localhost, etc.

## 📝 Configuration /etc/hosts

Ajoute ces lignes dans `/etc/hosts` :
```
127.0.0.1   localhost
127.0.0.1   ff.localhost
127.0.0.1   www.ta.localhost
127.0.0.1   www.gt.localhost
127.0.0.1   www.yy.localhost
127.0.0.1   www.oo.localhost
127.0.0.1   www.rr.localhost
```

## 🔧 Script de démarrage

Utilise le script `start-nginx.sh` pour démarrer facilement :
```bash
./start-nginx.sh
```

## 📊 Logs

- **Nginx :** `/var/log/nginx/laravel-access.log` et `/var/log/nginx/laravel-error.log`
- **Sous-domaines :** `/var/log/nginx/laravel-subdomain-access.log` et `/var/log/nginx/laravel-subdomain-error.log`

## 🛠️ Commandes utiles

```bash
# Test de configuration
sudo nginx -t

# Redémarrage des services
sudo systemctl restart nginx php8.4-fpm

# Statut des services
sudo systemctl status nginx
sudo systemctl status php8.4-fpm

# Logs en temps réel
sudo tail -f /var/log/nginx/laravel-error.log
```

## 🔒 Sécurité

- Les fichiers cachés sont bloqués
- Cache optimisé pour les assets statiques
- Configuration PHP-FPM sécurisée

## 🚨 Dépannage

### Erreur 502 Bad Gateway
- Vérifier que PHP-FPM fonctionne : `sudo systemctl status php8.4-fpm`
- Vérifier le socket : `ls -la /var/run/php/php8.4-fpm.sock`

### Erreur 403 Forbidden
- Vérifier les permissions : `sudo chown -R www-data:www-data storage bootstrap/cache`
- Vérifier que le sous-domaine existe dans la table `tenants`

### Erreur 404 Not Found
- Vérifier que le DocumentRoot pointe vers `/public`
- Vérifier la configuration des routes Laravel 