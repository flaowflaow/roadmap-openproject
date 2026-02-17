# Script de création de l'arborescence RoadMap-OpenProject
# Génère les dossiers et les fichiers .gitkeep associés

$folders = @(
    "roadmap-openproject",
    "observability/logstash/pipelines",
    "observability/metricbeat/modules.d",
    "observability/dashboards",
    "proxy/traefik/dynamic",
    "proxy/cloudflared",
    "swarm/secrets",
    "dev",
    "docs/schema"
)

# Création des dossiers et des fichiers .gitkeep
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "✅ Dossier créé : $folder" -ForegroundColor Cyan
    }
    
    $gitkeepPath = Join-Path $folder ".gitkeep"
    if (-not (Test-Path $gitkeepPath)) {
        New-Item -ItemType File -Path $gitkeepPath -Force | Out-Null
        Write-Host "  └─ Fichier .gitkeep ajouté" -ForegroundColor Gray
    }
}

# Création des fichiers racine vides (facultatif)
$rootFiles = @(
    "roadmap-openproject/Dockerfile",
    "roadmap-openproject/entrypoint.sh",
    "observability/logstash/logstash.conf",
    "observability/metricbeat/metricbeat.yml",
    "proxy/traefik/traefik.yml",
    "proxy/cloudflared/config.yml",
    "swarm/stack.yml",
    "swarm/networks.yml",
    "dev/docker-compose.dev.yml",
    "dev/.env.dev"
)

foreach ($file in $rootFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "📄 Fichier initial créé : $file" -ForegroundColor Yellow
    }
}

Write-Host "`n🚀 Arborescence terminée ! Ton projet est prêt pour la certification DCA." -ForegroundColor Green