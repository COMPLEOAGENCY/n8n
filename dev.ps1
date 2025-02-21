param(
    [Parameter(Position=0)]
    [string]$Command="up",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs
)

$composeArgs = @(
    "--env-file", ".env.dev",
    "-f", "compose.dev.yaml"
)

if ($Command -eq "up") {
    $composeArgs += @($Command, "-d")
} else {
    $composeArgs += @($Command)
}

if ($AdditionalArgs) {
    $composeArgs += $AdditionalArgs
}

Write-Host "🚀 Lancement de n8n en environnement de développement..." -ForegroundColor Green
docker compose $composeArgs

if ($Command -eq "up") {
    Write-Host "`n✅ Services disponibles sur:" -ForegroundColor Green
    Write-Host "   n8n: http://n8n.localhost" -ForegroundColor Cyan
    Write-Host "   Adminer: http://adminer.localhost" -ForegroundColor Cyan
    Write-Host "   Traefik: http://traefik.localhost" -ForegroundColor Cyan
}
