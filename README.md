# n8n Docker Setup

Cette configuration permet de déployer n8n avec Docker, en utilisant Traefik comme reverse proxy et PostgreSQL comme base de données. Bien qu'optimisée pour Amazon Lightsail, cette configuration est compatible avec tout type d'hébergement supportant Docker et Docker Compose.

## Compatibilité

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

## Prérequis

- Un serveur Linux (Ubuntu 22.04 LTS recommandé)
- Un domaine configuré sur Cloudflare
- Pour Windows : PowerShell (développement uniquement)
- Pour Linux : Bash

## Structure du Projet

```
📂 n8n/
├── 📂 data/ - Contient les données persistantes de l'application (workflows, logs, bases de données)
├── 📂 traefik/ - Configuration du reverse proxy Traefik pour le routage HTTP/HTTPS
├── 📂 letsencrypt/ - Certificats SSL/TLS pour le domaine (générés par Let's Encrypt)
├── 📄 compose.*.yaml - Fichiers de composition Docker pour différents environnements
│   ├── compose.common.yaml - Configuration commune
│   ├── compose.dev.yaml - Développement local
│   └── compose.prod.yaml - Production
├── 📄 .env.* - Fichiers de configuration d'environnement
│   ├── .env.dev - Variables dev
│   └── .env.prod - Variables prod
└── 📄 *.ps1/*.sh - Scripts de déploiement pour Windows/Linux
```

### Description des composants

- `data/` : Stockage persistant des workflows n8n, historiques d'exécution, et logs
- `traefik/config/` : Configuration du routage des requêtes et gestion SSL
- `letsencrypt/` : Certificats renouvelés automatiquement pour HTTPS
- `compose.*.yaml` : Définition des services Docker pour les différents environnements
- `.env.*` : Fichiers de variables d'environnement pour la configuration
- `*.ps1/*.sh` : Scripts d'automatisation pour Windows (PowerShell) et Linux (Bash)

## Installation

### Installation rapide (Production)

1. Créez une instance (si sur Lightsail) :
   - Ubuntu 22.04 LTS
   - Plan à 10$ minimum (2 GB RAM)
   - 60 GB stockage
   - Attachez une IP statique

2. Connectez-vous à votre serveur et exécutez :
   ```bash
   curl -fsSL https://raw.githubusercontent.com/COMPLEOAGENCY/n8n/main/lightsail-setup.sh | sudo bash
   ```

3. Suivez les instructions à l'écran pour configurer :
   - Votre domaine
   - Votre email (pour Let's Encrypt)
   - Les mots de passe administrateurs

   Le script configurera automatiquement :
   - Docker et Docker Compose
   - Le dépôt n8n
   - Les fichiers de configuration
   - Les permissions
   - Les mots de passe sécurisés

4. Conservez le fichier `credentials.txt` généré qui contient :
   - Les URLs d'accès
   - Les identifiants n8n
   - Les identifiants Traefik
   - Les identifiants base de données

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

## Utilisation

### En Production

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

## Accès aux Services

### Production

- n8n : `https://n8n.votre-domaine.com`
- Traefik Dashboard : `https://traefik.votre-domaine.com`
- Adminer : `https://adminer.votre-domaine.com`

### Développement

- n8n : `http://localhost:5678`
- Traefik Dashboard : `http://localhost:8080`
- Adminer : `http://localhost:8081`

## Sécurité

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

## Support

Pour toute question ou problème :
1. Vérifiez les logs : `./prod.sh logs`
2. Vérifiez la configuration DNS : `./prod.sh dns`
3. Consultez l'état des services : `./prod.sh ps`

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
