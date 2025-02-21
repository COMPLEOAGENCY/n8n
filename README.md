# n8n avec Traefik

Cette configuration permet de déployer n8n avec Traefik comme reverse proxy, en utilisant des configurations distinctes pour le développement et la production.

## Points d'accès

### Environnement de développement
- **n8n**: http://n8n.localhost
  - Utilisateur : `admin`
  - Mot de passe : `N8nSecurePass123!`
- **Adminer**: http://adminer.localhost
  - Serveur : `n8n-db`
  - Base de données : `n8n`
  - Utilisateur : `n8n`
  - Mot de passe : `n8n`
- **Traefik Dashboard**: 
  - Via le routeur : http://traefik.localhost
  - Accès direct : http://localhost:8080
  - Utilisateur : `admin`
  - Mot de passe : `password123`

### Environnement de production
- **n8n**: https://n8n.votre-domaine.com
- **Adminer**: https://adminer.votre-domaine.com
- **Traefik Dashboard**: https://traefik.votre-domaine.com

## Configuration

### Structure des fichiers
```
.
├── compose.common.yaml    # Configuration commune
├── compose.dev.yaml      # Configuration de développement
├── compose.prod.yaml     # Configuration de production
├── .env.dev             # Variables d'environnement de développement
├── .env.prod            # Variables d'environnement de production
├── .env.example         # Exemple de configuration
├── data/
│   ├── n8n/            # Données persistantes de n8n
│   └── postgres/       # Données persistantes de PostgreSQL
└── traefik/
    ├── config/         # Configuration dynamique de Traefik
    └── acme.json       # Certificats Let's Encrypt
```

### Commandes principales

#### Développement
```powershell
# Démarrer les services
.\dev.ps1

# Arrêter les services
.\dev.ps1 down

# Voir les logs
.\dev.ps1 logs -f

# Redémarrer un service spécifique
.\dev.ps1 restart n8n
```

#### Production
```powershell
# Démarrer les services
.\prod.ps1

# Arrêter les services
.\prod.ps1 down

# Voir les logs
.\prod.ps1 logs -f

# Redémarrer un service spécifique
.\prod.ps1 restart n8n
```

### Configuration initiale

1. Copier `.env.example` vers `.env.dev` et `.env.prod`
2. Modifier les variables d'environnement selon vos besoins
3. En production, mettre à jour :
   - Les noms de domaine
   - Les mots de passe
   - L'email pour Let's Encrypt
   - La clé de chiffrement n8n

### Sécurité

- Les mots de passe par défaut sont uniquement pour le développement
- En production, changez tous les mots de passe dans `.env.prod`
- La clé de chiffrement n8n doit être une chaîne de 32 caractères
- Les certificats SSL sont gérés automatiquement par Let's Encrypt en production

### Données persistantes

Les données sont stockées dans :
- `data/n8n/` : Workflows et données n8n
- `data/postgres/` : Base de données PostgreSQL

### Mise à jour

Pour mettre à jour les images :
```powershell
.\dev.ps1 pull  # En développement
.\prod.ps1 pull # En production
```

## Support

Pour plus d'informations, consultez :
- [Documentation n8n](https://docs.n8n.io/)
- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Documentation Adminer](https://www.adminer.org/)
