# Système de Jail SSH pour Tenants

Ce système configure un environnement de jail SSH sécurisé pour tous les tenants, où chaque tenant est isolé dans son propre espace et ne peut pas accéder aux autres tenants.

## 🎯 Objectifs

- ✅ Chaque tenant a son propre espace isolé (jail)
- ✅ Mot de passe unique : `tenant@2024!` pour tous
- ✅ Accès SSH avec chroot sécurisé
- ✅ `/home` affiche vide (pas d'accès aux autres tenants)
- ✅ Dossier de travail : `/project` pour chaque tenant
- ✅ Isolation complète entre les espaces

## 🚀 Installation

### 1. Exécuter le script de configuration

```bash
sudo ./setup-tenant-jail.sh
```

Ce script :
- Détecte automatiquement tous les tenants dans `/home/`
- Crée les utilisateurs manquants
- Configure le mot de passe unique `tenant@2024!`
- Crée la structure de jail pour chaque tenant
- Configure SSH avec chroot
- Copie les binaires et bibliothèques nécessaires

### 2. Tester la configuration

```bash
./test-tenant-jail.sh --list          # Lister tous les tenants
./test-tenant-jail.sh tenant_name     # Tester un tenant spécifique
```

## 🔐 Accès des Tenants

### Informations de connexion

- **Commande** : `ssh tenant_name@localhost`
- **Mot de passe** : `tenant@2024!`
- **Dossier de travail** : `/project`

### Exemple de connexion

```bash
ssh nn@localhost
# Mot de passe: tenant@2024!
```

### Ce que voit le tenant une fois connecté

```
🔒 === JAIL SSH - nn ===
📁 Dossier de travail : /project
🔐 Utilisateur : nn
======================================

📁 Contenu de votre espace de travail :
total 8
drwxr-xr-x 2 nn nn 4096 ... .
drwxr-xr-x 3 root root 4096 ... ..
-rw-r--r-- 1 nn nn  123 ... README.txt

[nn@jail] /project$ 
```

## 📁 Structure des Dossiers

Pour chaque tenant `tenant_name` :

```
/home/tenant_name/
└── www.tenant_name.localhost/      # Jail racine (chroot)
    ├── bin/                        # Binaires essentiels
    ├── lib/                        # Bibliothèques système
    ├── etc/                        # Configuration système
    ├── dev/                        # Périphériques
    ├── usr/                        # Binaires utilisateur
    └── project/                    # Espace de travail du tenant
        └── README.txt              # Fichier d'accueil
```

## 🔒 Sécurité

### Ce que le tenant peut faire

- ✅ Accéder à son dossier `/project`
- ✅ Utiliser les commandes de base (ls, pwd, mkdir, rm, etc.)
- ✅ Créer, modifier, supprimer des fichiers dans son espace
- ✅ Voir son nom d'utilisateur et son répertoire

### Ce que le tenant ne peut pas faire

- ❌ Accéder aux autres tenants
- ❌ Voir le contenu de `/home` (vide)
- ❌ Accéder au système principal
- ❌ Utiliser des commandes système avancées
- ❌ Sortir de son jail

### Configuration Chroot

```bash
# Configuration SSH pour chaque tenant
Match User tenant_name
    ChrootDirectory /home/tenant_name/www.tenant_name.localhost
    ForceCommand /bin/bash
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
    PubkeyAuthentication yes
    PermitTTY yes
```

## 🛠️ Commandes Disponibles

Dans le jail, les tenants ont accès aux commandes suivantes :

### Navigation
- `ls` - Lister les fichiers
- `pwd` - Afficher le répertoire actuel
- `cd` - Changer de répertoire

### Manipulation de fichiers
- `mkdir` - Créer un dossier
- `rm` - Supprimer des fichiers
- `touch` - Créer un fichier vide
- `cp` - Copier des fichiers
- `mv` - Déplacer des fichiers
- `cat` - Afficher le contenu d'un fichier

### Informations système
- `whoami` - Afficher l'utilisateur actuel
- `id` - Afficher les informations d'identité

## 📝 Exemple de Session

```bash
$ ssh nn@localhost
nn@localhost's password: tenant@2024!

🔒 === JAIL SSH - nn ===
📁 Dossier de travail : /project
🔐 Utilisateur : nn
======================================

📁 Contenu de votre espace de travail :
total 8
drwxr-xr-x 2 nn nn 4096 ... .
drwxr-xr-x 3 root root 4096 ... ..
-rw-r--r-- 1 nn nn  123 ... README.txt

[nn@jail] /project$ ls
README.txt

[nn@jail] /project$ cat README.txt
=== ESPACE DE TRAVAIL DE nn ===

Bienvenue dans votre espace de travail sécurisé !

📁 Votre dossier de projet : /project
🔒 Vous êtes isolé dans votre propre jail
🚫 Vous ne pouvez pas accéder aux autres tenants

[nn@jail] /project$ ls /home
# Vide - pas d'accès aux autres tenants

[nn@jail] /project$ pwd
/project

[nn@jail] /project$ whoami
nn

[nn@jail] /project$ exit
Connection to localhost closed.
```

## 🔧 Gestion des Tenants

### Ajouter un nouveau tenant

1. Créer le dossier dans `/home/` :
   ```bash
   sudo mkdir /home/nouveau_tenant
   ```

2. Re-exécuter le script de configuration :
   ```bash
   sudo ./setup-tenant-jail.sh
   ```

### Supprimer un tenant

1. Supprimer l'utilisateur et son jail :
   ```bash
   sudo userdel -r tenant_name
   sudo rm -rf /home/tenant_name/www.tenant_name.localhost
   ```

2. Nettoyer la configuration SSH :
   ```bash
   sudo sed -i '/^# Jail pour le tenant tenant_name/,/^$/d' /etc/ssh/sshd_config
   sudo systemctl restart ssh
   ```

### Changer le mot de passe

```bash
sudo passwd tenant_name
```

## 🔧 Dépannage

### Vérifier le statut SSH

```bash
sudo systemctl status ssh
sudo sshd -t
```

### Vérifier les logs SSH

```bash
sudo tail -f /var/log/auth.log
```

### Vérifier la structure de jail

```bash
ls -la /home/tenant_name/www.tenant_name.localhost/
ls -la /home/tenant_name/www.tenant_name.localhost/project/
```

### Tester la connexion locale

```bash
ssh tenant_name@localhost
```

## 📋 Scripts Disponibles

| Script | Description |
|--------|-------------|
| `setup-tenant-jail.sh` | Configuration principale du système de jail |
| `test-tenant-jail.sh` | Tests de validation du jail |

## 💡 Avantages du Système

### Sécurité
- Isolation complète entre tenants
- Pas d'accès croisé entre les espaces
- Chroot empêche l'évasion du jail
- Permissions strictes

### Simplicité
- Mot de passe unique pour tous
- Configuration automatique
- Interface utilisateur claire
- Prompt personnalisé

### Flexibilité
- Ajout/suppression facile de tenants
- Espace de travail dédié pour chaque tenant
- Commandes de base disponibles
- Fichier d'accueil personnalisé

## 🆘 Support

En cas de problème :

1. Vérifiez les logs SSH : `sudo tail -f /var/log/auth.log`
2. Testez la configuration : `./test-tenant-jail.sh tenant_name`
3. Vérifiez les permissions des dossiers jail
4. Redémarrez le service SSH : `sudo systemctl restart ssh`
5. Vérifiez que les binaires sont présents dans le jail 