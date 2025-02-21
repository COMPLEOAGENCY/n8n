param(
    [Parameter(Position=0)]
    [string]$Command="up",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs
)

$composeArgs = @(
    "--env-file", ".env.prod",
    "-f", "compose.prod.yaml"
)

if ($Command -eq "up") {
    $composeArgs += @($Command, "-d")
} else {
    $composeArgs += @($Command)
}

if ($AdditionalArgs) {
    $composeArgs += $AdditionalArgs
}

Write-Host "🚀 Lancement de n8n en environnement de production..." -ForegroundColor Yellow
docker compose $composeArgs

if ($Command -eq "up") {
    Write-Host "`n✅ Services disponibles sur:" -ForegroundColor Green
    Write-Host "   n8n: https://$env:N8N_DOMAIN" -ForegroundColor Cyan
    Write-Host "   Adminer: https://$env:ADMINER_DOMAIN" -ForegroundColor Cyan
    Write-Host "   Traefik: https://$env:TRAEFIK_DASHBOARD_DOMAIN" -ForegroundColor Cyan
}
