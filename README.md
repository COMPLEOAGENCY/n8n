# n8n Docker Setup

Ce projet configure n8n avec Docker, en utilisant Traefik comme reverse proxy et PostgreSQL comme base de données.

## 🔧 Prérequis

- Docker et Docker Compose
- Git
- Un domaine configuré sur Cloudflare
- Pour Windows : PowerShell
- Pour Linux : Bash

## 📦 Installation

### Sur le serveur de production (Linux)

1. Clonez le dépôt :
```bash
git clone <repository_url>
cd n8n
```

2. Exécutez le script d'installation :
```bash
chmod +x lightsail-setup.sh
sudo ./lightsail-setup.sh
```

3. Configurez votre environnement :
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

## 🛟 Support

Pour toute question ou problème :
1. Vérifiez les logs : `./prod.sh logs` ou `.\prod.ps1 logs`
2. Vérifiez la configuration DNS : `./prod.sh dns` ou `.\prod.ps1 dns`
3. Consultez l'état des services : `./prod.sh ps` ou `.\prod.ps1 ps`
