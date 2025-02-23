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
    Write-ColorOutput Green "n8n:     http://localhost:5678"
    Write-ColorOutput Green "Adminer: http://localhost:8080"
    Write-Output ""
}

function Show-Help {
    Write-Output "Usage: .\dev.ps1 [command]`n"
    Write-Output "Commands:"
    Write-Output "  up      - Démarre les services en mode détaché"
    Write-Output "  down    - Arrête les services"
    Write-Output "  restart - Redémarre les services"
    Write-Output "  logs    - Affiche les logs des services"
    Write-Output ""
}

$command = $args[0]

switch ($command) {
    "up" {
        Write-ColorOutput Green "[INFO] Démarrage des services..."
        docker compose --env-file .env.dev -f compose.dev.yaml up -d
        Show-Urls
    }
    "down" {
        Write-ColorOutput Green "[INFO] Arrêt des services..."
        docker compose --env-file .env.dev -f compose.dev.yaml down
    }
    "restart" {
        Write-ColorOutput Green "[INFO] Redémarrage des services..."
        docker compose --env-file .env.dev -f compose.dev.yaml down
        docker compose --env-file .env.dev -f compose.dev.yaml up -d
        Show-Urls
    }
    "logs" {
        Write-ColorOutput Green "[INFO] Affichage des logs..."
        docker compose --env-file .env.dev -f compose.dev.yaml logs -f
    }
    "urls" {
        Show-Urls
    }
    default {
        Show-Help
    }
}
