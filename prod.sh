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
    echo -e "\n${BLUE}=== Vérification des DNS ===${NC}"
    
    # S'assurer que les variables d'environnement sont chargées
    if [ -f .env.prod ]; then
        source .env.prod
    else
        error "Fichier .env.prod non trouvé"
        exit 1
    fi
    
    # Vérifier que N8N_DOMAIN est défini
    if [ -z "$N8N_DOMAIN" ]; then
        error "Variable N8N_DOMAIN non définie dans .env.prod"
        exit 1
    fi
    
    # Récupérer le domaine de base
    local base_domain=${N8N_DOMAIN#n8n.}
    local has_error=0
    
    # Afficher le domaine pour debug
    echo "Domaine de base: $base_domain"
    
    # Liste des sous-domaines à vérifier
    local subdomains=("n8n" "adminer" "portainer")
    
    for subdomain in "${subdomains[@]}"; do
        local full_domain="${subdomain}.${base_domain}"
        echo -n "Vérification de $full_domain... "
        
        # Vérifier si le DNS résout
        if host "$full_domain" >/dev/null 2>&1; then
            # Vérifier si le DNS résout vers une IP
            local dns_result=$(dig +short $full_domain)
            if [[ -n "$dns_result" ]]; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${YELLOW}ATTENTION: DNS non résolu${NC}"
                has_error=1
            fi
        else
            echo -e "${RED}NON CONFIGURÉ${NC}"
            has_error=1
        fi
    done

    if [ $has_error -eq 1 ]; then
        echo -e "\n${YELLOW}[WARN] Certains DNS peuvent ne pas être correctement configurés.${NC}"
        echo -e "${YELLOW}Vérifiez que les DNS suivants sont correctement configurés :${NC}"
        echo -e "   - n8n.${base_domain}"
        echo -e "   - adminer.${base_domain}"
        echo -e "\n${YELLOW}Notes :${NC}"
        echo -e "- La propagation DNS peut prendre jusqu'à 48h"
        echo -e "- Vous pouvez continuer, mais les services pourraient ne pas être accessibles"
        
        read -p "Voulez-vous continuer quand même ? (o/N) " response
        if [[ ! "$response" =~ ^[oO]$ ]]; then
            exit 1
        fi
    else
        echo -e "\n${GREEN}✓ Tous les DNS sont correctement configurés${NC}"
    fi
}

# Fonction pour vérifier l'état des services
check_services() {
    echo -e "\n${BLUE}=== Vérification des services ===${NC}"
    
    # Charger les variables d'environnement
    if [ -f .env.prod ]; then
        source .env.prod
    fi
    
    # Vérifier si les conteneurs sont en cours d'exécution
    if docker compose --env-file .env.prod -f compose.prod.yaml ps | grep -q "Up"; then
        echo -e "${GREEN}✓ Les services sont en cours d'exécution${NC}"
        
        # En production, nous vérifions principalement que les conteneurs sont en cours d'exécution
        # car les services peuvent ne pas être accessibles directement via localhost
        
        # Vérifier n8n via docker
        if docker ps --filter "name=n8n$" --filter "status=running" | grep -q "n8n"; then
            echo -e "${GREEN}✓ n8n est en cours d'exécution${NC}"
        else
            warn "n8n ne semble pas être en cours d'exécution"
        fi
        
        # Vérifier Nginx via docker
        if docker ps --filter "name=nginx" --filter "status=running" | grep -q "nginx"; then
            echo -e "${GREEN}✓ Nginx est en cours d'exécution${NC}"
        else
            warn "Nginx ne semble pas être en cours d'exécution"
        fi
        
        # Vérifier Adminer via docker
        if docker ps --filter "name=adminer" --filter "status=running" | grep -q "adminer"; then
            echo -e "${GREEN}✓ Adminer est en cours d'exécution${NC}"
        else
            warn "Adminer ne semble pas être en cours d'exécution"
        fi
        
        # Vérifier Portainer via docker
        if docker ps --filter "name=portainer" --filter "status=running" | grep -q "portainer"; then
            echo -e "${GREEN}✓ Portainer est en cours d'exécution${NC}"
        else
            warn "Portainer ne semble pas être en cours d'exécution"
        fi
        
        # Vérifier Redis (via docker)
        if docker exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
            echo -e "${GREEN}✓ Redis répond correctement${NC}"
        else
            warn "Redis ne répond pas correctement"
        fi

        # Vérifier n8n-worker
        if docker ps --filter "name=n8n-worker" --filter "status=running" | grep -q "n8n-worker"; then
            echo -e "${GREEN}✓ n8n-worker est en cours d'exécution${NC}"
        else
            warn "n8n-worker ne semble pas être en cours d'exécution"
        fi
        
        echo -e "\n${YELLOW}Note: Pour vérifier l'accès complet aux services, utilisez les URLs:${NC}"
        echo -e "   n8n: https://${N8N_DOMAIN}"
        echo -e "   Adminer: https://adminer.${N8N_DOMAIN#n8n.}"
        echo -e "   Portainer: https://portainer.${N8N_DOMAIN#n8n.}"
    else
        warn "Certains services ne sont pas en cours d'exécution"
    fi
}

# Fonction pour afficher les URLs des services
show_urls() {
    # Charger les variables d'environnement
    if [ -f .env.prod ]; then
        source .env.prod
    else
        error "Fichier .env.prod non trouvé"
        exit 1
    fi
    
    echo -e "\n${BLUE}=== URLs des services ===${NC}"
    echo -e "${GREEN}n8n:${NC}       https://${N8N_DOMAIN}"
    echo -e "${GREEN}Adminer:${NC}    https://adminer.${N8N_DOMAIN#*.}"
    echo -e "${GREEN}Portainer:${NC}  https://portainer.${N8N_DOMAIN#*.}"
    
    # Afficher aussi les URLs locales
    echo -e "\n${BLUE}=== URLs locales (pour debug) ===${NC}"
    echo -e "${GREEN}n8n:${NC}       http://localhost:5678"
    echo -e "${GREEN}Adminer:${NC}    http://localhost:8080"
    echo -e "${GREEN}Portainer:${NC}  http://localhost:9000"
    echo -e "${GREEN}Nginx:${NC}      http://localhost:80"
    echo -e "${YELLOW}Redis:${NC}      localhost:6379 (interne uniquement)"
    
    # Ajout des URLs de monitoring
    echo -e "\n${BLUE}=== URLs de monitoring ===${NC}"
    echo -e "${BLUE}Grafana:${NC}    https://grafana.${N8N_DOMAIN#*.}"
    echo -e "${BLUE}Prometheus:${NC} https://prometheus.${N8N_DOMAIN#*.}"
    echo -e "${BLUE}cAdvisor:${NC}   https://cadvisor.${N8N_DOMAIN#*.}"
    
    # Afficher aussi les URLs locales de monitoring
    echo -e "\n${BLUE}=== URLs locales de monitoring (pour debug) ===${NC}"
    echo -e "${BLUE}Grafana:${NC}    http://localhost:3000"
    echo -e "${BLUE}Prometheus:${NC} http://localhost:9090"
    echo -e "${BLUE}cAdvisor:${NC}   http://localhost:8081"
    echo ""
}

# Fonction d'aide
show_help() {
    echo "Usage: ./prod.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up        - Démarre les services en mode détaché"
    echo "  up-all    - Démarre services + monitoring"
    echo "  down      - Arrête prod + monitoring (supprime le réseau)"
    echo "  restart   - Redémarre les services"
    echo "  logs      - Affiche les logs des services"
    echo "  ps        - Liste les services en cours d'exécution"
    echo "  urls      - Affiche les URLs des services"
    echo "  dns       - Vérifie la configuration DNS"
    echo "  check     - Vérifie l'état des services"
    echo "  help      - Affiche cette aide"
}

# Traitement des commandes
case "$1" in
    "up")
        log "Vérification des DNS..."
        check_dns
        log "Démarrage des services..."
        docker compose --env-file .env.prod -f compose.prod.yaml up -d 2>&1 | grep -v 'Found orphan containers'
        log "Vérification des services..."
        sleep 5  # Attendre que les services démarrent
        check_services
        show_urls
        ;;
    "up-all")
        log "Vérification des DNS..."
        check_dns
        log "Démarrage des services de production..."
        docker compose --env-file .env.prod -f compose.prod.yaml up -d 2>&1 | grep -v 'Found orphan containers'
        log "Démarrage de la stack monitoring..."
        docker compose -f compose.monitoring.yaml up -d 2>&1 | grep -v 'Found orphan containers'
        log "Vérification des services..."
        sleep 5
        check_services
        show_urls
        ;;
    "down")
        log "Arrêt de la stack monitoring..."
        docker compose -f compose.monitoring.yaml down
        log "Arrêt des services de production..."
        docker compose --env-file .env.prod -f compose.prod.yaml down
        ;;
    "restart")
        # Vérifier si la stack monitoring est lancée
        monitoring_running=$(docker ps --format '{{.Names}}' | grep -E 'prometheus|grafana|cadvisor')
        if [ -n "$monitoring_running" ]; then
            log "Redémarrage de la stack monitoring..."
            docker compose -f compose.monitoring.yaml down
            docker compose -f compose.monitoring.yaml up -d 2>&1 | grep -v 'Found orphan containers'
        fi
        log "Redémarrage des services de production..."
        docker compose --env-file .env.prod -f compose.prod.yaml down
        docker compose --env-file .env.prod -f compose.prod.yaml up -d 2>&1 | grep -v 'Found orphan containers'
        log "Vérification des services..."
        sleep 5  # Attendre que les services démarrent
        check_services
        show_urls
        ;;
    "logs")
        if [ -z "$2" ]; then
            log "Affichage des logs de tous les services..."
            docker compose --env-file .env.prod -f compose.prod.yaml logs -f
        else
            log "Affichage des logs pour le service: $2..."
            docker compose --env-file .env.prod -f compose.prod.yaml logs -f "$2"
        fi
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
    "check")
        check_services
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
