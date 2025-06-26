function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Show-Urls {
    Write-Output "`n=== URLs des services ==="
    Write-ColorOutput Green "n8n:      http://localhost:5678"
    Write-ColorOutput Green "Adminer:  http://localhost:8080"
    Write-ColorOutput Green "Portainer: http://localhost:9000"
    Write-ColorOutput Yellow "Redis:    http://localhost:6379 (interne uniquement)"
    
    # Ajout des URLs de monitoring
    Write-Output "`n=== URLs de monitoring ==="
    Write-ColorOutput Blue "Grafana:    http://localhost:3000"
    Write-ColorOutput Blue "Prometheus: http://localhost:9090"
    Write-ColorOutput Blue "cAdvisor:   http://localhost:8081"  # cAdvisor utilise le port 8081 en externe
    Write-Output ""
}

function Show-Help {
    Write-Output "Usage: .\dev.ps1 [command]`n"
    Write-Output "Commands:"
    Write-Output "  up        - Démarre les services en mode détaché"
    Write-Output "  up-all    - Démarre services + monitoring"
    Write-Output "  down      - Arrête dev + monitoring (supprime le réseau)"
    Write-Output "  restart   - Redémarre les services"
    Write-Output "  logs      - Affiche les logs des services"
    Write-Output ""
}

$command = $args[0]

switch ($command) {
    "up" {
        Write-ColorOutput Green "[INFO] Démarrage des services..."
        docker compose --env-file .env.dev -f compose.dev.yaml up -d 2>&1 | Select-String -NotMatch 'Found orphan containers'
        Show-Urls
    }
    "up-all" {
        Write-ColorOutput Green "[INFO] Démarrage des services de développement..."
        docker compose --env-file .env.dev -f compose.dev.yaml up -d 2>&1 | Select-String -NotMatch 'Found orphan containers'
        Write-ColorOutput Green "[INFO] Démarrage de la stack monitoring..."
        docker compose -f compose.monitoring.yaml up -d 2>&1 | Select-String -NotMatch 'Found orphan containers'
        Show-Urls
    }
    "down" {
        Write-ColorOutput Green "[INFO] Arrêt de la stack monitoring..."
        docker compose -f compose.monitoring.yaml down
        Write-ColorOutput Green "[INFO] Arrêt des services de développement..."
        docker compose --env-file .env.dev -f compose.dev.yaml down
    }

    "restart" {
        # Vérifier si la stack monitoring est lancée
        $monitoringRunning = $(docker ps --format '{{.Names}}' | Select-String -Pattern 'prometheus|grafana|cadvisor')
        if ($monitoringRunning) {
            Write-ColorOutput Green "[INFO] Redémarrage de la stack monitoring..."
            docker compose -f compose.monitoring.yaml down
            docker compose -f compose.monitoring.yaml up -d 2>&1 | Select-String -NotMatch 'Found orphan containers'
        }
        Write-ColorOutput Green "[INFO] Redémarrage des services de développement..."
        docker compose --env-file .env.dev -f compose.dev.yaml down
        docker compose --env-file .env.dev -f compose.dev.yaml up -d 2>&1 | Select-String -NotMatch 'Found orphan containers'
        Show-Urls
    }
    "logs" {
        if ($args.Count -gt 1) {
            $service = $args[1]
            Write-ColorOutput Green "[INFO] Affichage des logs pour le service: $service..."
            docker compose --env-file .env.dev -f compose.dev.yaml logs -f $service
        } else {
            Write-ColorOutput Green "[INFO] Affichage des logs de tous les services..."
            docker compose --env-file .env.dev -f compose.dev.yaml logs -f
        }
    }
    "urls" {
        Show-Urls
    }
    default {
        Show-Help
    }
}
