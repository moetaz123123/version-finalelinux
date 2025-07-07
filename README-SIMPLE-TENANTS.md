# Configuration Simple des Tenants avec Chroot SSH

Ce projet fournit une solution simple pour configurer des tenants avec accès SSH sécurisé via chroot, permettant l'isolation complète entre les utilisateurs.

## 🎯 Objectif

Configurer plusieurs tenants avec :
- ✅ Accès SSH avec mot de passe
- ✅ Chroot jail pour l'isolation
- ✅ Même mot de passe pour tous les tenants
- ✅ Redirection automatique vers le dossier de travail
- ✅ Environnement Bash fonctionnel

## 📁 Scripts Disponibles

### 1. `setup-tenants-simple.sh` - Configuration principale
```bash
sudo ./setup-tenants-simple.sh
```
**Fonctionnalités :**
- Crée les utilisateurs tenant1, tenant2, tenant3
- Configure le chroot pour chaque tenant
- Définit le mot de passe unique : `tenant@2024!`
- Configure SSH avec les bonnes permissions
- Crée l'environnement minimal pour Bash

### 2. `test-simple-tenants.sh` - Test de la configuration
```bash
./test-simple-tenants.sh
```
**Fonctionnalités :**
- Vérifie l'existence des utilisateurs
- Contrôle les permissions des dossiers
- Teste la configuration SSH
- Effectue un test de connexion automatique

### 3. `demo-simple-tenants.sh` - Démonstration
```bash
./demo-simple-tenants.sh
```
**Fonctionnalités :**
- Affiche les informations de connexion
- Montre la structure des dossiers
- Explique l'utilisation pratique
- Fournit des exemples de commandes

## 🚀 Installation et Configuration

### Étape 1 : Préparation
```bash
# Rendre les scripts exécutables
chmod +x setup-tenants-simple.sh test-simple-tenants.sh demo-simple-tenants.sh
```

### Étape 2 : Configuration des tenants
```bash
# Exécuter le script de configuration (nécessite sudo)
sudo ./setup-tenants-simple.sh
```

### Étape 3 : Test de la configuration
```bash
# Tester que tout fonctionne
./test-simple-tenants.sh
```

## 🔐 Accès aux Tenants

### Informations de connexion
- **Utilisateurs :** tenant1, tenant2, tenant3
- **Mot de passe :** `tenant@2024!` (pour tous)
- **Accès :** `ssh tenant@localhost`

### Exemple de connexion
```bash
ssh tenant1@localhost
# Mot de passe : tenant@2024!
```

## 📁 Structure des Dossiers

Pour chaque tenant (exemple avec tenant1) :
```
/home/tenant1/
├── .bashrc                    # Configuration personnalisée
└── www.tenant1.localhost/     # Racine du chroot (root:root, 755)
    ├── bin/                   # Binaires système
    ├── lib/                   # Bibliothèques
    ├── etc/                   # Configuration système
    ├── dev/                   # Périphériques
    └── project/               # Espace de travail (tenant1:tenant1, 755)
        └── README.txt         # Fichier d'accueil
```

## 🔒 Sécurité et Isolation

### Chroot Jail
- Chaque tenant est isolé dans son propre chroot
- Pas d'accès aux autres tenants
- Pas d'accès au système principal
- Environnement minimal et sécurisé

### Permissions Critiques
- **Racine chroot :** `root:root` avec permissions `755`
- **Dossier project :** `tenant:tenant` avec permissions `755`
- **Binaires :** Exécutables dans le chroot

### Commandes Disponibles
Dans le chroot, les tenants ont accès à :
- `bash`, `ls`, `pwd`, `cd`
- `mkdir`, `rm`, `touch`, `cat`
- `whoami`, `id`
- Alias : `ll`, `la`, `l`

## 🧪 Tests et Vérifications

### Test manuel de connexion
```bash
# Connexion au premier tenant
ssh tenant1@localhost
# Mot de passe : tenant@2024!

# Dans le chroot, tester :
whoami          # Devrait afficher : tenant1
pwd             # Devrait afficher : /project
ls -la          # Devrait lister le contenu du projet
ls /home        # Devrait échouer (isolation)
exit            # Déconnexion
```

### Vérification des permissions
```bash
# Vérifier les permissions du chroot
ls -la /home/tenant1/www.tenant1.localhost/
# Devrait afficher : drwxr-xr-x root root

# Vérifier les permissions du dossier project
ls -la /home/tenant1/www.tenant1.localhost/project/
# Devrait afficher : drwxr-xr-x tenant1 tenant1
```

## 🔧 Dépannage

### Problèmes courants

#### 1. "Broken pipe" lors de la connexion SSH
**Cause :** Permissions incorrectes du chroot
**Solution :**
```bash
sudo chown root:root /home/tenant1/www.tenant1.localhost
sudo chmod 755 /home/tenant1/www.tenant1.localhost
```

#### 2. "bad ownership or modes for chroot directory"
**Cause :** Le chroot n'est pas possédé par root
**Solution :**
```bash
sudo chown root:root /home/tenant1/www.tenant1.localhost
sudo chmod 755 /home/tenant1/www.tenant1.localhost
```

#### 3. Connexion SSH échoue
**Vérifications :**
```bash
# Vérifier le service SSH
sudo systemctl status ssh

# Vérifier les logs SSH
sudo journalctl -u ssh -f

# Tester la configuration SSH
sudo sshd -t
```

#### 4. Binaires manquants dans le chroot
**Solution :**
```bash
# Recopier les binaires nécessaires
sudo cp /bin/bash /home/tenant1/www.tenant1.localhost/bin/
sudo cp /bin/ls /home/tenant1/www.tenant1.localhost/bin/
sudo chmod +x /home/tenant1/www.tenant1.localhost/bin/*
```

### Logs utiles
```bash
# Logs SSH en temps réel
sudo journalctl -u ssh -f

# Logs d'authentification
sudo tail -f /var/log/auth.log

# Test de la configuration SSH
sudo sshd -t
```

## 📝 Personnalisation

### Modifier la liste des tenants
Éditez le fichier `setup-tenants-simple.sh` :
```bash
# Ligne 18 : Modifiez la liste des tenants
tenants=("mon_tenant1" "mon_tenant2" "mon_tenant3")
```

### Changer le mot de passe
Éditez le fichier `setup-tenants-simple.sh` :
```bash
# Ligne 21 : Modifiez le mot de passe
TENANT_PASSWORD="mon_nouveau_mot_de_passe"
```

### Ajouter des commandes supplémentaires
Dans le script, ajoutez les binaires nécessaires :
```bash
# Copier des commandes supplémentaires
cp /bin/vim /home/$tenant/www.$tenant.localhost/bin/
cp /usr/bin/git /home/$tenant/www.$tenant.localhost/usr/bin/
```

## 🎯 Utilisation Avancée

### Transfert de fichiers
```bash
# Depuis l'extérieur du chroot
scp mon_fichier.txt tenant1@localhost:/project/

# Depuis le chroot (si configuré)
scp /project/mon_fichier.txt utilisateur@serveur:/chemin/
```

### Configuration SFTP (optionnel)
Pour ajouter l'accès SFTP, modifiez la configuration SSH :
```bash
# Dans /etc/ssh/sshd_config, remplacer ForceCommand /bin/bash par :
ForceCommand internal-sftp
```

## 📊 Comparaison avec les autres scripts

| Fonctionnalité | Script Simple | Script Complet |
|----------------|---------------|----------------|
| Configuration | Basique | Avancée |
| Tenants | Fixes (3) | Détection automatique |
| Mot de passe | Unique | Unique |
| Environnement | Minimal | Complet |
| Tests | Basiques | Complets |
| Documentation | Simple | Détaillée |

## 🚀 Prochaines étapes

1. **Testez la configuration** avec `./test-simple-tenants.sh`
2. **Connectez-vous** à un tenant : `ssh tenant1@localhost`
3. **Explorez l'environnement** dans le chroot
4. **Personnalisez** selon vos besoins
5. **Documentez** vos modifications

## 📞 Support

En cas de problème :
1. Consultez la section "Dépannage"
2. Vérifiez les logs SSH
3. Testez avec le script de test
4. Vérifiez les permissions des dossiers

---

**Note :** Ce script est une version simplifiée pour un déploiement rapide. Pour un environnement de production, considérez des mesures de sécurité supplémentaires. 