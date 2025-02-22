param(
    [Parameter(Position=0)]
    [string]$Command="up",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs
)

# Vérification des prérequis
function Test-Prerequisites {
    # Vérifier que Docker est en cours d'exécution
    if (-not (Get-Service -Name "Docker*" | Where-Object { $_.Status -eq 'Running' })) {
        Write-Host "❌ Docker n'est pas en cours d'exécution. Démarrez Docker Desktop et réessayez." -ForegroundColor Red
        exit 1
    }

    # Vérifier que le fichier .env.prod existe
    if (-not (Test-Path ".env.prod")) {
        Write-Host "❌ Le fichier .env.prod est manquant. Copiez .env.example en .env.prod et configurez-le." -ForegroundColor Red
        exit 1
    }

    # Vérifier que le fichier acme.json existe avec les bonnes permissions
    if (-not (Test-Path "traefik/acme.json")) {
        Write-Host "ℹ️ Création du fichier acme.json..." -ForegroundColor Yellow
        New-Item -Path "traefik" -ItemType Directory -Force | Out-Null
        New-Item -Path "traefik/acme.json" -ItemType File -Force | Out-Null
        # Définir les permissions les plus restrictives possibles sous Windows
        icacls "traefik/acme.json" /inheritance:r /grant:r "SYSTEM:(R,W)" /grant:r "$env:USERNAME:(R,W)" | Out-Null
    }

    # Créer les répertoires de données s'ils n'existent pas
    @("data/n8n", "data/postgres") | ForEach-Object {
        if (-not (Test-Path $_)) {
            Write-Host "ℹ️ Création du répertoire $_..." -ForegroundColor Yellow
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }
}

# Charger les variables d'environnement
function Load-EnvFile {
    Get-Content ".env.prod" | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
        }
    }
}

# Vérifier la configuration
Test-Prerequisites
Load-EnvFile

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Check-DNS {
    # Récupérer le domaine depuis .env.prod
    $domain = (Get-Content .env.prod | Select-String "DOMAIN=").ToString().Split("=")[1]
    $hasError = $false
    
    Write-Output "`n=== Vérification des DNS ==="
    
    # Liste des sous-domaines à vérifier
    $subdomains = @("n8n", "traefik", "adminer")
    
    foreach ($subdomain in $subdomains) {
        $fullDomain = "$subdomain.$domain"
        Write-Host "Vérification de $fullDomain... " -NoNewline
        
        try {
            $null = Resolve-DnsName -Name $fullDomain -ErrorAction Stop
            Write-ColorOutput Green "OK"
        }
        catch {
            Write-ColorOutput Red "NON CONFIGURÉ"
            $hasError = $true
        }
    }

    if ($hasError) {
        Write-ColorOutput Red "`n[ERROR] Certains DNS ne sont pas configurés correctement."
        Write-ColorOutput Yellow "Configuration DNS requise (Cloudflare) :"
        Write-Host "1. Allez sur le dashboard Cloudflare"
        Write-Host "2. Sélectionnez le domaine $domain"
        Write-Host "3. Ajoutez les enregistrements DNS A suivants :"
        Write-Host "   - n8n.$domain     → [IP_SERVEUR]"
        Write-Host "   - traefik.$domain → [IP_SERVEUR]"
        Write-Host "   - adminer.$domain → [IP_SERVEUR]"
        Write-Host "`nNotes importantes :"
        Write-Host "- Proxy Status : Activez le proxy Cloudflare (orange) pour le SSL"
        Write-Host "- SSL/TLS : Réglez sur 'Full' dans les paramètres Cloudflare"
        Write-Host "- La propagation DNS peut prendre quelques minutes avec Cloudflare"
        
        $response = Read-Host "`nVoulez-vous continuer quand même ? (o/N)"
        if ($response -notmatch '^[oO]$') {
            exit 1
        }
    }
    else {
        Write-ColorOutput Green "`n✓ Tous les DNS sont correctement configurés"
    }
}

function Show-Urls {
    # Récupérer le domaine depuis .env.prod
    $domain = (Get-Content .env.prod | Select-String "DOMAIN=").ToString().Split("=")[1]
    
    Write-Output "`n=== URLs des services ==="
    Write-ColorOutput Green "n8n:    https://n8n.$domain"
    Write-ColorOutput Green "Traefik: https://traefik.$domain"
    Write-ColorOutput Green "Adminer: https://adminer.$domain"
    Write-Output ""
}

function Show-Help {
    Write-Output "Usage: .\prod.ps1 [command]`n"
    Write-Output "Commands:"
    Write-Output "  up      - Démarre les services en mode détaché"
    Write-Output "  down    - Arrête les services"
    Write-Output "  restart - Redémarre les services"
    Write-Output "  logs    - Affiche les logs des services"
    Write-Output "  ps      - Liste les services en cours d'exécution"
    Write-Output "  urls    - Affiche les URLs des services"
    Write-Output "  dns     - Vérifie la configuration DNS"
    Write-Output "  help    - Affiche cette aide"
}

$composeArgs = @(
    "--env-file", ".env.prod",
    "-f", "compose.prod.yaml"
)

# Gestion des commandes spéciales
switch ($Command) {
    "up" {
        Write-ColorOutput Green "[INFO] Vérification des DNS..."
        Check-DNS
        Write-ColorOutput Green "[INFO] Démarrage des services..."
        $composeArgs += @($Command, "-d")
        Write-Host "🚀 Lancement de n8n en environnement de production..." -ForegroundColor Yellow
    }
    "down" {
        Write-ColorOutput Green "[INFO] Arrêt des services..."
        Write-Host "⚠️ Arrêt des services..." -ForegroundColor Yellow
        $confirmation = Read-Host "Êtes-vous sûr de vouloir arrêter tous les services ? (o/N)"
        if ($confirmation -ne "o") {
            Write-Host "Opération annulée." -ForegroundColor Yellow
            exit 0
        }
        $composeArgs += $Command
    }
    "restart" {
        Write-ColorOutput Green "[INFO] Vérification des DNS..."
        Check-DNS
        Write-ColorOutput Green "[INFO] Redémarrage des services..."
        $composeArgs += @($Command)
    }
    "logs" {
        if (-not $AdditionalArgs) {
            $composeArgs += @($Command, "--tail=100", "-f")
        } else {
            $composeArgs += @($Command)
        }
    }
    "urls" {
        Show-Urls
        exit 0
    }
    "dns" {
        Check-DNS
        exit 0
    }
    default {
        Show-Help
        exit 0
    }
}

if ($AdditionalArgs) {
    $composeArgs += $AdditionalArgs
}

# Exécuter la commande Docker Compose
docker compose $composeArgs

# Afficher les informations après le démarrage
if ($Command -eq "up") {
    Write-Host "`n✅ Services disponibles sur:" -ForegroundColor Green
    Write-Host "   n8n: https://$env:N8N_DOMAIN" -ForegroundColor Cyan
    Write-Host "   Adminer: https://$env:ADMINER_DOMAIN" -ForegroundColor Cyan
    Write-Host "   Traefik: https://$env:TRAEFIK_DASHBOARD_DOMAIN" -ForegroundColor Cyan
    Write-Host "`n📝 Identifiants par défaut:" -ForegroundColor Yellow
    Write-Host "   n8n - Utilisateur: $env:N8N_BASIC_AUTH_USER" -ForegroundColor Yellow
    Write-Host "   Base de données - Utilisateur: $env:DB_USER" -ForegroundColor Yellow
    Write-Host "   (Les mots de passe sont stockés dans .env.prod)" -ForegroundColor Yellow
    Write-Host "`n💡 Commandes utiles:" -ForegroundColor White
    Write-Host "   .\prod.ps1 logs     - Voir les logs" -ForegroundColor White
    Write-Host "   .\prod.ps1 down     - Arrêter les services" -ForegroundColor White
    Write-Host "   .\prod.ps1 restart  - Redémarrer les services" -ForegroundColor White
    Write-Host "   .\prod.ps1 urls     - Afficher les URLs des services" -ForegroundColor White
}
