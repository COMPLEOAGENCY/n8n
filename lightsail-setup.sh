#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Définition du répertoire d'installation
INSTALL_DIR="/home/ubuntu/n8n"
log "Installation dans $INSTALL_DIR"

# Mise à jour du système
log "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances
log "Installation des dépendances..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Installation de Docker
log "Installation de Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Installation de Docker Compose
log "Installation de Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configuration du pare-feu
log "Configuration du pare-feu..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Configuration des permissions Docker
log "Configuration des permissions Docker..."
usermod -aG docker ubuntu
systemctl restart docker
newgrp docker

# Création des répertoires
log "Création des répertoires..."
mkdir -p "$INSTALL_DIR"/{data/n8n,data/postgres,traefik/config}

# Configuration de Traefik
log "Configuration de Traefik..."
touch "$INSTALL_DIR/traefik/acme.json"
chmod 600 "$INSTALL_DIR/traefik/acme.json"

# Configuration des permissions
log "Configuration des permissions des fichiers..."
chown -R ubuntu:ubuntu "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# Configuration des permissions pour les scripts shell
log "Configuration des permissions des scripts..."
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Vérification des permissions
log "Vérification des permissions..."
if ! groups ubuntu | grep -q docker; then
    warn "L'utilisateur ubuntu n'est pas dans le groupe docker. Ajout en cours..."
    usermod -aG docker ubuntu
fi

# Instructions finales
cat << EOF

${GREEN}=== Installation terminée avec succès ===${NC}

${YELLOW}Étapes suivantes :${NC}
1. Transférez vos fichiers vers le serveur :
   scp -r * ubuntu@votre-ip:$INSTALL_DIR/

2. Configurez votre environnement :
   cd $INSTALL_DIR
   cp .env.example .env.prod
   nano .env.prod

3. Mettez à jour les variables dans .env.prod :
   - DOMAIN=votre-domaine.com
   - TRAEFIK_ACME_EMAIL=votre-email@domaine.com
   - Vérifiez que TRAEFIK_DASHBOARD_CREDENTIALS est configuré

4. Démarrez les services avec le script prod.sh :
   cd $INSTALL_DIR
   ./prod.sh up

${YELLOW}Important :${NC}
- Mettez à jour vos enregistrements DNS pour pointer vers cette instance
- Les certificats SSL seront générés automatiquement
- Les identifiants du dashboard Traefik sont configurés dans .env.prod

Pour plus d'informations, consultez le README.md

${YELLOW}Note :${NC}
Pour que les changements de permission Docker prennent effet,
vous devrez peut-être vous déconnecter et vous reconnecter à votre session SSH.

${GREEN}Scripts disponibles :${NC}
- ./prod.sh up     : Démarrer les services
- ./prod.sh down   : Arrêter les services
- ./prod.sh logs   : Voir les logs
- ./prod.sh ps     : État des services
EOF
