$ErrorActionPreference = "Stop"

# Créer le répertoire des certificats s'il n'existe pas
$certsPath = "."
if (!(Test-Path $certsPath)) {
    New-Item -ItemType Directory -Path $certsPath
}

# Générer la clé privée et le certificat
docker run --rm -v ${PWD}:/certs alpine:latest sh -c '
    apk add --no-cache openssl &&
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /certs/key.pem \
        -out /certs/cert.pem \
        -subj "/CN=localhost"
'

Write-Host "Certificats générés avec succès dans le dossier $certsPath"
