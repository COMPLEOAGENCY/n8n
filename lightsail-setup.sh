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
    software-properties-common \
    git \
    bind9-host

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
log "Clonage du dépôt n8n..."
cd /home/ubuntu
rm -rf "$INSTALL_DIR"
git clone https://github.com/COMPLEOAGENCY/n8n.git "$INSTALL_DIR"

# Configuration automatique de .env.prod
log "Configuration de l'environnement..."
cd "$INSTALL_DIR"
cp .env.example .env.prod

# Demande des informations
echo -e "\n${YELLOW}Configuration de votre environnement${NC}"
read -p "Entrez votre domaine (ex: compleo.dev) : " DOMAIN
read -s -p "Choisissez un mot de passe admin pour n8n : " N8N_PASSWORD
echo

# Génération des valeurs aléatoires
ENCRYPTION_KEY=$(openssl rand -hex 16)
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
N8N_VERSION="1.80.4"

# Configuration du fichier .env.prod
log "Application de la configuration..."
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env.prod
sed -i "s/DB_NAME=.*/DB_NAME=n8n_prod/" .env.prod
sed -i "s/DB_USER=.*/DB_USER=n8n_prod/" .env.prod
sed -i "s/N8N_BASIC_AUTH_PASSWORD=.*/N8N_BASIC_AUTH_PASSWORD=$N8N_PASSWORD/" .env.prod
sed -i "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env.prod
sed -i "s/N8N_DOMAIN=.*/N8N_DOMAIN=n8n.$DOMAIN/" .env.prod
sed -i "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=https/" .env.prod
echo "N8N_VERSION=$N8N_VERSION" >> .env.prod

# Création du répertoire nginx/conf.d
log "Configuration de Nginx..."
mkdir -p "$INSTALL_DIR/nginx/conf.d"

# Création du fichier de configuration Nginx
cat > "$INSTALL_DIR/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    server_name n8n.$DOMAIN;

    location / {
        proxy_pass http://n8n:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name adminer.$DOMAIN;

    location / {
        proxy_pass http://adminer:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Sauvegarde des identifiants
log "Sauvegarde des identifiants..."
cat > "$INSTALL_DIR/credentials.txt" << EOF
=== Identifiants n8n ===
URL : https://n8n.$DOMAIN
Utilisateur : admin
Mot de passe : $N8N_PASSWORD

=== Identifiants Base de données ===
Hôte : n8n-db
Base de données : n8n_prod
Utilisateur : n8n_prod
Mot de passe : $DB_PASSWORD

=== Identifiants Adminer ===
URL : https://adminer.$DOMAIN
Serveur : n8n-db
Base de données : n8n_prod
Utilisateur : n8n_prod
Mot de passe : $DB_PASSWORD
EOF

# Définir les permissions
log "Configuration des permissions..."
chown -R ubuntu:ubuntu "$INSTALL_DIR"
chmod 600 "$INSTALL_DIR/credentials.txt"

# Création du script de démarrage
log "Création du script de démarrage..."
cat > "$INSTALL_DIR/start.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./prod.sh up
EOF

chmod +x "$INSTALL_DIR/start.sh"
chmod +x "$INSTALL_DIR/prod.sh"

# Instructions finales
echo -e "\n${GREEN}=== Installation terminée avec succès ===${NC}"
echo -e "Vos identifiants ont été sauvegardés dans $INSTALL_DIR/credentials.txt"
echo -e "\n${YELLOW}Prochaines étapes :${NC}"
echo -e "1. Configurez votre solution de load balancing (AWS Lightsail LB ou autre)"
echo -e "2. Configurez des certificats SSL pour les domaines n8n.$DOMAIN et adminer.$DOMAIN"
echo -e "3. Configurez les DNS pour pointer vers votre serveur ou load balancer"
echo -e "4. Démarrez les services avec la commande : cd $INSTALL_DIR && ./prod.sh up"
echo -e "\nPour plus d'informations, consultez le README.md"

echo -e "\n${YELLOW}Note :${NC}"
echo -e "Pour que les changements de permission Docker prennent effet,"
echo -e "vous devrez peut-être vous déconnecter et vous reconnecter à votre session SSH."

# Fin du script
log "Installation terminée avec succès"
