# n8n Docker Setup

Cette configuration permet de déployer n8n avec Docker, en utilisant Traefik comme reverse proxy et PostgreSQL comme base de données. Bien qu'optimisée pour Amazon Lightsail, cette configuration est compatible avec tout type d'hébergement supportant Docker et Docker Compose.

## 🌐 Compatibilité

Cette configuration a été testée sur :
- Amazon Lightsail (recommandé)
- VPS standard (OVH, DigitalOcean, Linode, etc.)
- Serveurs dédiés
- Machines locales (développement)

### Configuration recommandée
- RAM : 2 GB minimum (4 GB recommandé)
- CPU : 1 vCPU minimum (2 vCPU recommandé)
- Stockage : 60 GB minimum
- OS : Ubuntu 22.04 LTS (ou toute distribution Linux supportant Docker)

## 🔧 Prérequis

- Docker et Docker Compose
- Git
- Un domaine configuré sur Cloudflare
- Pour Windows : PowerShell
- Pour Linux : Bash

### Configuration du serveur
1. Ports requis :
   - 80 (HTTP)
   - 443 (HTTPS)
   - 22 (SSH, optionnel)

2. Règles de pare-feu :
   ```bash
   # Sur Ubuntu/Debian
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 22/tcp
   
   # Sur Amazon Lightsail
   # Configurez via l'interface de gestion Lightsail
   ```

## 📦 Installation

### Sur Amazon Lightsail

1. Créez une instance :
   - Ubuntu 22.04 LTS
   - Plan à 10$ minimum (2 GB RAM)
   - 60 GB stockage
   - Attachez une IP statique

2. Connectez-vous à votre instance et exécutez :
   ```bash
   # Option 1 : Installation directe (plus rapide)
   curl -fsSL https://raw.githubusercontent.com/COMPLEOAGENCY/n8n/main/lightsail-setup.sh | sudo bash

   # Option 2 : Installation en deux étapes (plus sécurisée)
   curl -fsSL https://raw.githubusercontent.com/COMPLEOAGENCY/n8n/main/lightsail-setup.sh -o setup.sh && \
   chmod +x setup.sh && \
   sudo ./setup.sh
   ```

   Le script va automatiquement :
   - Installer Docker et Docker Compose
   - Cloner le dépôt n8n
   - Configurer les permissions
   - Préparer l'environnement

3. Configurez votre environnement :
   ```bash
   cd /home/ubuntu/n8n
   cp .env.example .env.prod
   nano .env.prod
   ```

### Sur d'autres hébergeurs

1. Installez Docker et Docker Compose :
   ```bash
   # Sur Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo apt-get install docker-compose-plugin
   ```

2. Clonez le dépôt :
   ```bash
   git clone <repository_url>
   cd n8n
   ```

3. Créez les répertoires nécessaires :
   ```bash
   mkdir -p data/n8n data/postgres traefik/acme
   chmod 600 traefik/acme/acme.json
   ```

4. Configurez votre environnement :
   ```bash
   cp .env.example .env.prod
   nano .env.prod
   ```

### Configuration DNS (Cloudflare)

1. Allez sur le dashboard Cloudflare
2. Sélectionnez votre domaine
3. Ajoutez les enregistrements DNS A suivants :
   - `n8n.votre-domaine.com` → IP_SERVEUR
   - `traefik.votre-domaine.com` → IP_SERVEUR
   - `adminer.votre-domaine.com` → IP_SERVEUR

4. Pour chaque enregistrement :
   - Activez le proxy Cloudflare (icône orange)
   - Dans les paramètres SSL/TLS, réglez sur 'Full'

## 🚀 Utilisation

### En Production (Linux)

```bash
# Vérifier la configuration DNS
./prod.sh dns

# Démarrer les services
./prod.sh up

# Autres commandes disponibles
./prod.sh down     # Arrêter les services
./prod.sh restart  # Redémarrer les services
./prod.sh logs     # Voir les logs
./prod.sh ps       # État des services
./prod.sh urls     # Afficher les URLs
./prod.sh help     # Aide
```

### En Production (Windows)

```powershell
# Vérifier la configuration DNS
.\prod.ps1 dns

# Démarrer les services
.\prod.ps1 up

# Autres commandes disponibles
.\prod.ps1 down     # Arrêter les services
.\prod.ps1 restart  # Redémarrer les services
.\prod.ps1 logs     # Voir les logs
.\prod.ps1 ps       # État des services
.\prod.ps1 urls     # Afficher les URLs
.\prod.ps1 help     # Aide
```

### En Développement (Windows)

```powershell
# Démarrer les services
.\dev.ps1 up

# Autres commandes disponibles
.\dev.ps1 down     # Arrêter les services
.\dev.ps1 restart  # Redémarrer les services
.\dev.ps1 logs     # Voir les logs
.\dev.ps1 ps       # État des services
.\dev.ps1 urls     # Afficher les URLs
.\dev.ps1 help     # Aide
```

## 🔐 Accès aux Services

### Production

- n8n : `https://n8n.votre-domaine.com`
- Traefik Dashboard : `https://traefik.votre-domaine.com`
- Adminer : `https://adminer.votre-domaine.com`

### Développement

- n8n : `http://localhost:5678`
- Traefik Dashboard : `http://localhost:8080`
- Adminer : `http://localhost:8081`

## 📝 Variables d'Environnement

Copiez `.env.example` vers `.env.prod` ou `.env.dev` et configurez les variables suivantes :

```bash
# Domaine
DOMAIN=votre-domaine.com

# Traefik
TRAEFIK_ACME_EMAIL=votre-email@domaine.com
TRAEFIK_DASHBOARD_DOMAIN=traefik.votre-domaine.com
TRAEFIK_DASHBOARD_CREDENTIALS=admin:hashed_password

# n8n
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password
N8N_ENCRYPTION_KEY=your_encryption_key

# Base de données
POSTGRES_USER=n8n_prod
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=n8n_prod
```

## 🛡️ Sécurité

1. Permissions des fichiers :
   ```bash
   chmod 600 .env.prod
   chmod 600 traefik/acme/acme.json
   ```

2. Pare-feu :
   - Limitez l'accès aux ports 80 et 443
   - Utilisez les groupes de sécurité AWS si sur Lightsail

3. SSL/TLS :
   - Utilisez Cloudflare en mode "Full"
   - Les certificats sont gérés automatiquement par Let's Encrypt

## 🛟 Support

Pour toute question ou problème :
1. Vérifiez les logs : `./prod.sh logs` ou `.\prod.ps1 logs`
2. Vérifiez la configuration DNS : `./prod.sh dns` ou `.\prod.ps1 dns`
3. Consultez l'état des services : `./prod.sh ps` ou `.\prod.ps1 ps`

### Problèmes courants

1. **Les services ne démarrent pas** :
   - Vérifiez que Docker est en cours d'exécution
   - Vérifiez les logs avec `logs`
   - Assurez-vous que les ports ne sont pas utilisés
   - Vérifiez les permissions des fichiers :
     ```bash
     sudo chown -R 1000:1000 data/n8n
     sudo chmod 600 traefik/acme/acme.json
     ```
   - Sur Windows, utilisez le script PowerShell
   - Sur Linux, assurez-vous que les scripts ont les permissions d'exécution :
     ```bash
     chmod +x prod.sh
     chmod +x dev.sh
     ```

2. **Erreurs SSL/DNS** :
   - Vérifiez la configuration DNS avec `dns`
   - Assurez-vous que Cloudflare est en mode "Full"
   - Attendez la propagation DNS (peut prendre jusqu'à 24h)
   - Vérifiez que tous les sous-domaines sont configurés :
     - n8n.votre-domaine.com
     - traefik.votre-domaine.com
     - adminer.votre-domaine.com
   - Dans Cloudflare :
     - Activez le proxy (icône orange) pour chaque sous-domaine
     - Vérifiez que le mode SSL/TLS est sur "Full"
     - Désactivez temporairement le mode "Development" si activé

3. **Problèmes de permissions** :
   - Erreur "permission denied" sur n8n :
     ```bash
     sudo chown -R 1000:1000 data/n8n
     ```
   - Erreur sur acme.json :
     ```bash
     sudo chmod 600 traefik/acme/acme.json
     ```
   - Erreur sur les fichiers .env :
     ```bash
     sudo chmod 600 .env.prod
     sudo chmod 600 .env.dev
     ```

4. **Erreurs de configuration** :
   - Le dashboard Traefik n'est pas accessible :
     - Vérifiez TRAEFIK_DASHBOARD_DOMAIN dans .env.prod
     - Vérifiez TRAEFIK_DASHBOARD_CREDENTIALS
   - n8n ne démarre pas :
     - Vérifiez N8N_ENCRYPTION_KEY (32 caractères requis)
     - Vérifiez les identifiants PostgreSQL
   - Erreurs de base de données :
     - Vérifiez que les variables POSTGRES_* correspondent dans .env.prod
     - Assurez-vous que le volume PostgreSQL existe :
       ```bash
       mkdir -p data/postgres
       sudo chown -R 1000:1000 data/postgres
       ```

5. **Performances** :
   - Minimum 2 GB RAM recommandé
   - Si n8n est lent :
     - Augmentez les limites dans compose.prod.yaml :
       ```yaml
       n8n:
         deploy:
           resources:
             limits:
               memory: 2G
             reservations:
               memory: 1G
       ```
     - Surveillez l'utilisation CPU/RAM :
       ```bash
       docker stats
       ```
   - Pour PostgreSQL :
     - Ajustez shared_buffers dans compose.prod.yaml
     - Limitez les workflows lourds en parallèle

6. **Problèmes de mise à jour** :
   - Sauvegardez avant toute mise à jour :
     ```bash
     # Sur Linux
     sudo tar czf n8n-backup-$(date +%Y%m%d).tar.gz data traefik/acme/acme.json .env.prod
     
     # Sur Windows PowerShell
     Compress-Archive -Path data,traefik/acme/acme.json,.env.prod -DestinationPath "n8n-backup-$(Get-Date -Format 'yyyyMMdd').zip"
     ```
   - En cas d'erreur après mise à jour :
     - Vérifiez la compatibilité des versions
     - Restaurez la sauvegarde si nécessaire
     - Nettoyez les conteneurs et volumes si nécessaire :
       ```bash
       docker compose down -v
       docker compose up -d
       ```

7. **Problèmes réseau** :
   - Ports déjà utilisés :
     ```bash
     # Vérifiez les ports utilisés
     sudo netstat -tulpn | grep -E '80|443'
     # ou sur Windows
     netstat -ano | findstr "80 443"
     ```
   - Problèmes de proxy :
     - Vérifiez la configuration Traefik
     - Assurez-vous que les labels Docker sont corrects
     - Vérifiez les règles de routage dans compose.prod.yaml

8. **Problèmes spécifiques à Lightsail** :
   - Vérifiez les groupes de sécurité
   - Assurez-vous que l'IP statique est attachée
   - Configurez le pare-feu Lightsail :
     - Port 80 (HTTP)
     - Port 443 (HTTPS)
     - Port 22 (SSH)
