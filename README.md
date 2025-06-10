# n8n Docker Setup

Cette configuration permet de déployer n8n avec Docker, en utilisant Nginx comme reverse proxy, PostgreSQL comme base de données et Redis pour les files d'attente et le cache. Le système est configuré en mode queue avec des workers dédiés pour une meilleure performance et stabilité. Bien qu'optimisée pour Amazon Lightsail, cette configuration est compatible avec tout type d'hébergement supportant Docker et Docker Compose.

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
- Un domaine configuré sur votre fournisseur DNS
- Pour Windows : PowerShell (développement uniquement)
- Pour Linux : Bash

## Structure du Projet

📂 n8n/
├── 📂 data/ - Contient les données persistantes de l'application (workflows, logs, bases de données)
├── 📂 nginx/ - Configuration du reverse proxy Nginx pour le routage HTTP/HTTPS
├── 📄 compose.*.yaml - Fichiers de composition Docker pour différents environnements
│   ├── compose.common.yaml - Configuration commune
│   ├── compose.dev.yaml - Développement local
│   └── compose.prod.yaml - Production
├── 📄 .env.* - Fichiers de configuration d'environnement
│   ├── .env.dev - Variables dev
│   └── .env.prod - Variables prod
└── 📄 *.ps1/*.sh - Scripts de déploiement pour Windows/Linux

### Description des composants

- `data/` : Stockage persistant des workflows n8n, historiques d'exécution, et logs
- `nginx/conf.d/` : Configuration du routage des requêtes HTTP
- `compose.*.yaml` : Définition des services Docker pour les différents environnements
- `.env.*` : Fichiers de variables d'environnement pour la configuration
- `*.ps1/*.sh` : Scripts d'automatisation pour Windows (PowerShell) et Linux (Bash)

### Architecture et composants

- **n8n** : Plateforme d'automatisation (service principal, interface utilisateur et API)
- **n8n-worker** : Service dédié au traitement des tâches en file d'attente
- **PostgreSQL** : Base de données optimisée pour stocker les workflows et les données
- **Redis** : Système de cache et de files d'attente pour améliorer les performances
- **Adminer** : Interface web pour gérer la base de données
- **Nginx** : Reverse proxy pour accéder à n8n via HTTPS
- **Portainer** : Interface web pour gérer les conteneurs Docker

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
   - Les identifiants base de données

### Configuration du Load Balancer

Vous pouvez utiliser n'importe quelle solution de load balancing :

1. AWS Lightsail Load Balancer
2. Nginx Proxy Manager
3. HAProxy
4. Traefik
5. Ou tout autre reverse proxy de votre choix

Configurez votre solution pour :
1. Rediriger le trafic HTTP vers HTTPS
2. Gérer les certificats SSL pour vos domaines
3. Router le trafic vers votre instance n8n

### Configuration DNS

1. Dans votre gestionnaire DNS (Route 53, Cloudflare, OVH, etc.)
2. Créez des enregistrements pour pointer vers votre serveur ou load balancer :
   - `n8n.votre-domaine.com` → Votre serveur ou load balancer
   - `adminer.votre-domaine.com` → Votre serveur ou load balancer
   - `portainer.votre-domaine.com` → Votre serveur ou load balancer

## Utilisation

### En Production

```bash
# Vérifier la configuration DNS
./prod.sh dns

# Démarrer les services
./prod.sh up

# Autres commandes disponibles
./prod.sh down                # Arrêter les services
./prod.sh restart             # Redémarrer les services
./prod.sh logs                # Voir les logs de tous les services
./prod.sh logs n8n           # Voir les logs du service principal n8n
./prod.sh logs n8n-worker    # Voir les logs du worker n8n
./prod.sh ps                  # État des services
./prod.sh urls                # Afficher les URLs
./prod.sh check               # Vérifier l'état des services
./prod.sh help                # Aide
```

### En Développement (Windows)

```powershell
# Démarrer les services
.\dev.ps1 up

# Autres commandes disponibles
.\dev.ps1 down                # Arrêter les services
.\dev.ps1 restart             # Redémarrer les services
.\dev.ps1 logs                # Voir les logs de tous les services
.\dev.ps1 logs n8n           # Voir les logs du service principal n8n
.\dev.ps1 logs n8n-worker    # Voir les logs du worker n8n
.\dev.ps1 urls                # Afficher les URLs
.\dev.ps1 help                # Aide
```

## Accès aux Services

### Production

- n8n : `https://n8n.votre-domaine.com`
- Adminer : `https://adminer.votre-domaine.com`
- Portainer : `https://portainer.votre-domaine.com`
- Redis : Service interne (non exposé directement)

### Développement

- n8n : `http://localhost:5678`
- Adminer : `http://localhost:8080`
- Portainer : `http://localhost:9000`
- Redis : `localhost:6379` (interne uniquement)
- Nginx : `http://localhost:80`

## Optimisations

### PostgreSQL

La base de données PostgreSQL est optimisée pour les performances avec les configurations suivantes :

- **Intégrité des données** : Checksums activés, WAL séparés
- **Mémoire** : `shared_buffers=256MB`, `effective_cache_size=768MB`, `work_mem=16MB`
- **Performances** : Paramètres optimisés pour SSD, gestion améliorée des E/S concurrentes
- **Surveillance** : Module `pg_stat_statements` activé pour analyser les requêtes
- **Ressources** : Limitation à 1 Go de RAM et 1 CPU

### Redis et Workers

Redis est configuré pour améliorer les performances de n8n :

- **Mode Queue** : Exécution des workflows via Redis (`EXECUTIONS_MODE=queue`)
- **Workers dédiés** : Service `n8n-worker` séparé pour traiter les tâches en file d'attente
- **Concurrence** : Traitement simultané de plusieurs workflows (`WORKERS_CONCURRENCY=5`)
- **Exécutions manuelles** : Déchargement vers les workers (`OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true`)
- **Cache** : Stockage en mémoire des données fréquemment utilisées (`N8N_CACHE_ENABLED=true`)
- **Persistance** : Mode AOF activé (`appendonly yes`) pour éviter la perte de données
- **Gestion mémoire** : Limite à 256 Mo avec politique LRU (`maxmemory-policy allkeys-lru`)
- **Ressources** : Limitation à 384 Mo de RAM et 0,5 CPU

### Surveillance des Workers et Files d'Attente

Pour surveiller efficacement le système en mode queue avec workers :

- **Logs des workers** : Consultez les logs spécifiques au worker
  ```bash
  # En production
  ./prod.sh logs n8n-worker
  
  # En développement
  .\dev.ps1 logs n8n-worker
  ```

- **État des services** : Vérifiez que le worker est bien en cours d'exécution
  ```bash
  ./prod.sh check
  ```

- **Surveillance Redis** : Accédez à la console Redis pour vérifier les files d'attente
  ```bash
  docker exec -it redis redis-cli
  # Liste des clés dans la base de données 0 (file d'attente)
  SELECT 0
  KEYS n8n:bull:*
  # Liste des clés dans la base de données 1 (cache)
  SELECT 1
  KEYS n8n:cache:*
  ```

- **Métriques de performance** : Surveillez les ressources utilisées par les services
  ```bash
  docker stats n8n n8n-worker redis n8n-db
  ```

## Sécurité

1. Permissions des fichiers :
   ```bash
   chmod 600 .env.prod
   ```

2. Pare-feu :
   - Limitez l'accès aux ports 80 et 443
   - Utilisez les groupes de sécurité AWS si sur Lightsail

3. SSL/TLS :
   - Utilisez votre solution de load balancing pour gérer les certificats SSL
   - Configurez les certificats SSL dans votre gestionnaire DNS

## Support

Pour toute question ou problème :
1. Vérifiez les logs : `./prod.sh logs`
2. Vérifiez la configuration DNS : `./prod.sh dns`
3. Vérifiez l'état des services : `./prod.sh check`
4. Consultez l'état des services : `./prod.sh ps`

### Problèmes courants

1. **Les services ne démarrent pas** :
   - Vérifiez que Docker est en cours d'exécution
   - Vérifiez les logs avec `logs`
   - Assurez-vous que les ports ne sont pas utilisés
   - Vérifiez les permissions des fichiers :
     ```bash
     sudo chown -R 1000:1000 data/n8n
     ```
   - Sur Windows, utilisez le script PowerShell
   - Sur Linux, assurez-vous que les scripts ont les permissions d'exécution :
     ```bash
     chmod +x prod.sh
     chmod +x dev.sh
     ```

2. **Erreurs SSL/DNS** :
   - Vérifiez la configuration DNS avec `dns`
   - Vérifiez que votre solution SSL est correctement configurée
   - Attendez la propagation DNS (peut prendre jusqu'à 48h)
   - Vérifiez que tous les sous-domaines sont configurés :
     - n8n.votre-domaine.com
     - adminer.votre-domaine.com
   - Dans votre gestionnaire DNS :
     - Vérifiez que les certificats SSL sont valides
     - Vérifiez que les règles de routage sont correctes

3. **Problèmes de permissions** :
   - Erreur "permission denied" sur n8n :
     ```bash
     sudo chown -R 1000:1000 data/n8n
     ```
   - Erreur sur les fichiers .env :
     ```bash
     sudo chmod 600 .env.prod
     sudo chmod 600 .env.dev
     ```

4. **Erreurs de configuration** :
   - n8n ne démarre pas :
     - Vérifiez N8N_ENCRYPTION_KEY (32 caractères requis)
     - Vérifiez les identifiants PostgreSQL
   - Erreurs de base de données :
     - Vérifiez que les variables DB_* correspondent dans .env.prod
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
   - Pour les workers :
     - Ajustez WORKERS_CONCURRENCY dans compose.common.yaml selon vos besoins
     - Augmentez les ressources du worker si nécessaire

6. **Problèmes avec les workers et files d'attente** :
   - Les workflows restent bloqués en attente :
     - Vérifiez que le service n8n-worker est en cours d'exécution :
       ```bash
       ./prod.sh check
       ```
     - Consultez les logs du worker :
       ```bash
       ./prod.sh logs n8n-worker
       ```
     - Vérifiez la connexion à Redis :
       ```bash
       docker exec -it redis redis-cli ping
       ```
     - Redémarrez le worker si nécessaire :
       ```bash
       docker compose --env-file .env.prod -f compose.prod.yaml restart n8n-worker
       ```

7. **Problèmes de mise à jour** :
   - Sauvegardez avant toute mise à jour :
     ```bash
     # Sur Linux
     sudo tar czf n8n-backup-$(date +%Y%m%d).tar.gz data .env.prod
     
     # Sur Windows PowerShell
     Compress-Archive -Path data,.env.prod -DestinationPath "n8n-backup-$(Get-Date -Format 'yyyyMMdd').zip"
     ```
   - En cas d'erreur après mise à jour :
     - Vérifiez la compatibilité des versions
     - Restaurez la sauvegarde si nécessaire
     - Nettoyez les conteneurs et volumes si nécessaire :
       ```bash
       docker compose down -v
       docker compose up -d
       ```

8. **Problèmes réseau** :
   - Ports déjà utilisés :
     ```bash
     # Vérifiez les ports utilisés
     sudo netstat -tulpn | grep -E '80|443'
     # ou sur Windows
     netstat -ano | findstr "80 443"
     ```
   - Problèmes de proxy :
     - Vérifiez la configuration Nginx
     - Vérifiez les règles de routage dans nginx/conf.d/default.conf

9. **Problèmes spécifiques à Lightsail** :
   - Vérifiez les groupes de sécurité
   - Assurez-vous que l'IP statique est attachée
   - Configurez le pare-feu Lightsail :
     - Port 80 (HTTP)
     - Port 443 (HTTPS)
     - Port 22 (SSH)
