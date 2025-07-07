# 🔗 Intégration Nginx - Configuration Multi-Tenant

## 📁 Structure des Fichiers

### Fichiers de Configuration
- `nginx-subdomain-config.conf` : Configuration des sous-domaines (template)
- `nginx-corrected-config.conf` : Configuration principale avec phpMyAdmin
- `/etc/nginx/sites-available/laravel-app` : Configuration active intégrée

### Scripts d'Automatisation
- `update-nginx-config.sh` : Script pour mettre à jour la configuration
- `start-nginx.sh` : Script de démarrage Nginx

## 🌐 Architecture des Domaines

### 1. localhost (Application Principale)
```nginx
server {
    listen 80;
    server_name localhost;
    root /home/taz/Downloads/version-windows-linux/public;
    # Configuration Laravel principale
}
```

### 2. pma.localhost (phpMyAdmin)
```nginx
server {
    listen 80;
    server_name pma.localhost;
    root /usr/share/phpmyadmin;
    # Configuration phpMyAdmin
}
```

### 3. *.localhost (Sous-domaines des Tenants)
```nginx
server {
    listen 80;
    server_name ~^(?<tenant_name>[^.]+)\.localhost$;
    root /home/taz/Downloads/version-windows-linux/public;
    # Configuration multi-tenant
}
```

## 🔄 Processus d'Intégration

### Méthode 1 : Intégration Directe ✅ (Recommandée)
La configuration des sous-domaines est intégrée directement dans `/etc/nginx/sites-available/laravel-app` :

1. **Bloc Server Principal** : Gère `localhost`
2. **Bloc Server Sous-domaines** : Gère `*.localhost`
3. **Configuration phpMyAdmin** : Fichier séparé activé

### Méthode 2 : Fichiers Séparés
Alternative avec des fichiers de configuration séparés :

```bash
# Activer les configurations
sudo ln -s /etc/nginx/sites-available/laravel-app /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
```

## 🛠️ Utilisation

### Mise à Jour de la Configuration
```bash
# Utiliser le script automatisé
sudo ./update-nginx-config.sh

# Ou manuellement
sudo nginx -t
sudo systemctl reload nginx
```

### Vérification
```bash
# Tester les domaines
curl -I http://localhost
curl -I http://pma.localhost
curl -I http://tenant-name.localhost
```

## 📋 Avantages de l'Intégration

1. **Gestion Centralisée** : Une seule configuration pour l'application principale
2. **Performance** : Moins de fichiers à charger
3. **Maintenance** : Plus facile à maintenir et déboguer
4. **Cohérence** : Configuration uniforme pour tous les domaines
5. **Sécurité** : Headers et timeouts cohérents

## 🔧 Configuration des Tenants

### Création d'un Tenant
1. L'application Laravel crée le tenant
2. Le dossier `/home/tenants/tenant-name/` est créé
3. Nginx vérifie l'existence du dossier
4. Retourne 404 si le tenant n'existe pas

### Variables Nginx
- `$tenant_name` : Nom du tenant extrait du sous-domaine
- Utilisé pour vérifier l'existence du dossier tenant

## 🚨 Points d'Attention

1. **Permissions** : S'assurer que Nginx peut accéder aux dossiers
2. **Timeouts** : Configuration optimisée pour éviter les erreurs 504
3. **Cache** : Headers de cache pour les assets statiques
4. **Sécurité** : Protection des fichiers `.htaccess`

## 📞 Support

En cas de problème :
1. Vérifier les logs : `/var/log/nginx/`
2. Tester la syntaxe : `sudo nginx -t`
3. Redémarrer Nginx : `sudo systemctl restart nginx`
4. Vérifier les permissions des dossiers 