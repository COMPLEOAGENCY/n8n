#!/bin/bash

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Fonction pour vérifier les DNS
check_dns() {
    # Récupérer le domaine depuis .env.prod
    DOMAIN=$(grep "DOMAIN=" .env.prod | cut -d '=' -f2)
    local has_error=0

    echo -e "\n${BLUE}=== Vérification des DNS ===${NC}"
    
    # Liste des sous-domaines à vérifier
    local subdomains=("n8n" "traefik" "adminer")
    
    for subdomain in "${subdomains[@]}"; do
        local full_domain="$subdomain.$DOMAIN"
        echo -n "Vérification de $full_domain... "
        
        if host "$full_domain" >/dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}NON CONFIGURÉ${NC}"
            has_error=1
        fi
    done

    if [ $has_error -eq 1 ]; then
        echo -e "\n${RED}[ERROR] Certains DNS ne sont pas configurés correctement.${NC}"
        echo -e "${YELLOW}Configuration DNS requise (Cloudflare) :${NC}"
        echo -e "1. Allez sur le dashboard Cloudflare"
        echo -e "2. Sélectionnez le domaine $DOMAIN"
        echo -e "3. Ajoutez les enregistrements DNS A suivants :"
        echo -e "   - n8n.$DOMAIN     → [IP_SERVEUR]"
        echo -e "   - traefik.$DOMAIN → [IP_SERVEUR]"
        echo -e "   - adminer.$DOMAIN → [IP_SERVEUR]"
        echo -e "\n${YELLOW}Notes importantes :${NC}"
        echo -e "- Proxy Status : Activez le proxy Cloudflare (orange) pour le SSL"
        echo -e "- SSL/TLS : Réglez sur 'Full' dans les paramètres Cloudflare"
        echo -e "- La propagation DNS peut prendre quelques minutes avec Cloudflare"
        
        read -p "Voulez-vous continuer quand même ? (o/N) " response
        if [[ ! "$response" =~ ^[oO]$ ]]; then
            exit 1
        fi
    else
        echo -e "\n${GREEN}✓ Tous les DNS sont correctement configurés${NC}"
    fi
}

# Fonction pour afficher les URLs des services
show_urls() {
    # Récupérer le domaine depuis .env.prod
    DOMAIN=$(grep "DOMAIN=" .env.prod | cut -d '=' -f2)
    
    echo -e "\n${BLUE}=== URLs des services ===${NC}"
    echo -e "${GREEN}n8n:${NC}     https://n8n.$DOMAIN"
    echo -e "${GREEN}Traefik:${NC}  https://traefik.$DOMAIN"
    echo -e "${GREEN}Adminer:${NC}  https://adminer.$DOMAIN"
    echo ""
}

# Vérification que nous sommes dans le bon répertoire
if [ ! -f "compose.prod.yaml" ]; then
    error "Ce script doit être exécuté depuis le répertoire n8n"
    exit 1
fi

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: ./prod.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up      - Démarre les services en mode détaché"
    echo "  down    - Arrête les services"
    echo "  restart - Redémarre les services"
    echo "  logs    - Affiche les logs des services"
    echo "  ps      - Liste les services en cours d'exécution"
    echo "  urls    - Affiche les URLs des services"
    echo "  dns     - Vérifie la configuration DNS"
    echo "  help    - Affiche cette aide"
}

# Vérifier si la commande host est disponible
if ! command -v host >/dev/null 2>&1; then
    warn "La commande 'host' n'est pas installée. Installation en cours..."
    apt-get update && apt-get install -y bind9-host
fi

# Traitement des commandes
case "$1" in
    "up")
        log "Vérification des DNS..."
        check_dns
        log "Démarrage des services..."
        docker compose --env-file .env.prod -f compose.prod.yaml up -d
        show_urls
        ;;
    "down")
        log "Arrêt des services..."
        docker compose --env-file .env.prod -f compose.prod.yaml down
        ;;
    "restart")
        log "Vérification des DNS..."
        check_dns
        log "Redémarrage des services..."
        docker compose --env-file .env.prod -f compose.prod.yaml down
        docker compose --env-file .env.prod -f compose.prod.yaml up -d
        show_urls
        ;;
    "logs")
        log "Affichage des logs..."
        docker compose --env-file .env.prod -f compose.prod.yaml logs -f
        ;;
    "ps")
        log "Liste des services..."
        docker compose --env-file .env.prod -f compose.prod.yaml ps
        show_urls
        ;;
    "urls")
        show_urls
        ;;
    "dns")
        check_dns
        ;;
    "help"|"")
        show_help
        ;;
    *)
        error "Commande inconnue: $1"
        show_help
        exit 1
        ;;
esac
