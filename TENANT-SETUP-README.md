# Configuration des Tenants avec Chroot SSH/SFTP

Ce système permet de configurer des tenants isolés avec un accès SFTP sécurisé via chroot.

## 🎯 Objectifs

- ✅ Tous les tenants ont le même mot de passe : `tenant@2024!`
- ✅ Chaque tenant est isolé dans son propre espace
- ✅ Accès SSH avec chroot sécurisé
- ✅ Chroot empêche l'accès aux autres tenants
- ✅ Structure de dossiers organisée

## 📁 Structure des Dossiers

Pour chaque tenant `tenant_name` :

```
/home/tenant_name/
├── .ssh/                           # Clés SSH du tenant
└── www.tenant_name.localhost/      # Dossier chroot racine
    └── project/                    # Dossier de travail du tenant
        └── README.txt              # Fichier d'accueil
```

## 🚀 Installation et Configuration

### 1. Exécuter le script de configuration

```bash
sudo ./setup-all-tenants-chroot-fixed.sh
```

Ce script :
- Détecte automatiquement tous les tenants dans `/home/`
- Crée les utilisateurs manquants
- Configure le mot de passe unique `tenant@2024!`
- Configure le chroot SSH/SFTP
- Crée la structure de dossiers
- Configure les permissions de sécurité

### 2. Tester la configuration

```bash
sudo ./test-tenant-access.sh
```

Ce script vérifie :
- La structure des dossiers
- Les permissions de sécurité
- La configuration SSH
- L'isolation entre tenants

### 3. Voir la démonstration

```bash
./demo-tenant-usage.sh --list          # Lister tous les tenants
./demo-tenant-usage.sh tenant_name     # Démonstration pour un tenant
```

## 🔐 Accès des Tenants

### Informations de connexion

- **Serveur** : `$(hostname -I | awk '{print $1}')`
- **Utilisateur** : `tenant_name`
- **Mot de passe** : `tenant@2024!`
- **Protocole** : SSH avec chroot

### Commandes SSH

```bash
# Connexion
ssh tenant_name@server_ip

# Navigation
$ ls                        # Voir le contenu du projet
$ pwd                       # Voir le répertoire actuel
$ cd ..                     # Remonter au dossier parent
$ ls                        # Voir le contenu du chroot
$ cd project                # Retourner au projet

# Manipulation de fichiers
$ touch nouveau_fichier.txt
$ mkdir nouveau_dossier
$ rm fichier.txt
$ rmdir dossier_vide
$ chmod 644 fichier.txt

# Affichage d'informations
$ whoami                    # Voir l'utilisateur actuel
$ id                        # Voir les informations d'identité
$ cat README.txt            # Lire le fichier d'accueil

# Déconnexion
$ exit
```

## 🔒 Sécurité

### Restrictions

- ✅ Accès SSH avec chroot sécurisé
- ❌ Pas d'accès aux autres tenants
- ❌ Pas d'accès au système de fichiers principal
- ✅ Accès uniquement à l'espace chroot
- ✅ Isolation complète entre tenants

### Configuration Chroot

Chaque tenant est chrooté dans `/home/tenant_name/www.tenant_name.localhost/` :

```bash
# Configuration SSH pour chaque tenant
Match User tenant_name
    ChrootDirectory /home/tenant_name/www.tenant_name.localhost
    ForceCommand /bin/bash
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
    PubkeyAuthentication yes
```

### Permissions

- **Dossier chroot** : `root:root` avec permissions `755`
- **Dossier project** : `tenant:tenant` avec permissions `755`
- **Dossier .ssh** : `tenant:tenant` avec permissions `700`

## 🛠️ Gestion des Tenants

### Ajouter un nouveau tenant

1. Créer le dossier dans `/home/` :
   ```bash
   sudo mkdir /home/nouveau_tenant
   ```

2. Re-exécuter le script de configuration :
   ```bash
   sudo ./setup-all-tenants-chroot-fixed.sh
   ```

### Supprimer un tenant

1. Supprimer l'utilisateur :
   ```bash
   sudo userdel -r tenant_name
   ```

2. Nettoyer la configuration SSH :
   ```bash
   sudo sed -i '/^# Chroot pour le tenant tenant_name/,/^$/d' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

### Changer le mot de passe

```bash
sudo passwd tenant_name
```

## 🔧 Dépannage

### Vérifier le statut SSH

```bash
sudo systemctl status sshd
sudo sshd -t
```

### Vérifier les logs SSH

```bash
sudo tail -f /var/log/auth.log
```

### Tester la connexion locale

```bash
ssh tenant_name@localhost
```

### Vérifier les permissions

```bash
ls -la /home/tenant_name/www.tenant_name.localhost/
ls -la /home/tenant_name/www.tenant_name.localhost/project/
```

## 📋 Scripts Disponibles

| Script | Description |
|--------|-------------|
| `setup-all-tenants-chroot-fixed.sh` | Configuration principale |
| `test-tenant-access.sh` | Tests de validation |
| `demo-tenant-usage.sh` | Démonstration d'utilisation |

## 💡 Conseils

### Clients SSH Recommandés

- **PuTTY** (Windows)
- **Terminal** (Linux/Mac)
- **iTerm2** (Mac)
- **Windows Terminal** (Windows)
- **VS Code** (avec extension Remote SSH)

### Sécurité Supplémentaire

1. **Clés SSH** : Configurez des clés SSH pour éviter les mots de passe
2. **Firewall** : Limitez l'accès SSH aux IPs autorisées
3. **Fail2ban** : Protégez contre les attaques par force brute
4. **Sauvegardes** : Sauvegardez régulièrement les données des tenants

### Performance

- Les tenants sont isolés et n'affectent pas les performances des autres
- Chaque tenant a son propre espace de travail
- Le chroot limite l'impact sur le système principal

## 🆘 Support

En cas de problème :

1. Vérifiez les logs SSH : `sudo tail -f /var/log/auth.log`
2. Testez la configuration : `sudo ./test-tenant-access.sh`
3. Vérifiez les permissions des dossiers
4. Redémarrez le service SSH : `sudo systemctl restart sshd` 