# Guide d'Installation — RoadMap-OpenProject sur CentOS 10.1

📅 **Dernière mise à jour :** 17 février 2026  
🔄 **Version :** 1.0  
🖥️ **OS cible :** CentOS 10.1 (RHEL-based)

---

## Table des matières

- [Prérequis Système](#prérequis-système)
- [1. Installation de Docker](#1-installation-de-docker)
- [2. Installation de Docker Compose](#2-installation-de-docker-compose)
- [3. Configuration Initiale](#3-configuration-initiale)
- [4. Clonage du Dépôt](#4-clonage-du-dépôt)
- [5. Configuration de l'Environnement](#5-configuration-de-lenvironnement)
- [6. Lancement en Développement](#6-lancement-en-développement)
- [7. Déploiement en Production (Swarm)](#7-déploiement-en-production-swarm)
- [8. Vérification & Tests](#8-vérification--tests)
- [Troubleshooting](#troubleshooting)

---

## Prérequis Système

### Configuration matérielle recommandée

| Ressource | Développement | Production (3 nœuds) |
|-----------|---|---|
| **CPU** | 4 cœurs | 8 cœurs / nœud |
| **RAM** | 8 GB | 16 GB / nœud |
| **Disque** | 30 GB | 100 GB / nœud |
| **Réseau** | 1 Gbps | 1 Gbps (LAN) |

### Versions logicielles

- **CentOS :** 10.1 (ou compatible RHEL 10.1)
- **Docker Engine :** 25.0+
- **Docker Compose :** 2.20+ (version composée)
- **Git :** 2.30+
- **Bash/Shell :** 4.4+

### Accès système

Vous devez avoir :
- ✅ Accès root ou sudo
- ✅ Connexion Internet (pour télécharger les images)
- ✅ Accès au dépôt GitHub

---

## 1. Installation de Docker

### Étape 1.1 : Mise à jour du système

```bash
sudo dnf update -y
sudo dnf install -y net-tools curl wget git
```

### Étape 1.2 : Ajouter le dépôt Docker

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### Étape 1.3 : Installer Docker Engine

```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Étape 1.4 : Démarrer et activer Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Étape 1.5 : Ajouter votre utilisateur au groupe docker

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Étape 1.6 : Vérifier l'installation

```bash
docker --version
docker run hello-world
```

**Output attendu :**
```
Docker version 25.x.x, build xxxxx
Hello from Docker!
```

---

## 2. Installation de Docker Compose

### Étape 2.1 : Vérifier la version du plugin Compose

Docker Compose est généralement inclus avec Docker Engine moderne. Vérifiez :

```bash
docker compose version
```

**Output attendu :**
```
Docker Compose version v2.20.0+
```

### Étape 2.2 : (Optionnel) Installation manuelle

Si la version est trop ancienne :

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

---

## 3. Configuration Initiale

### Étape 3.1 : Créer les répertoires de travail

```bash
mkdir -p ~/roadmap-openproject
cd ~/roadmap-openproject
```

### Étape 3.2 : Configurer les permissions

```bash
chmod 755 ~/roadmap-openproject
```

### Étape 3.3 : Vérifier l'espace disque

```bash
df -h ~/roadmap-openproject
```

Vous devez avoir **au moins 30 GB** d'espace libre.

---

## 4. Clonage du Dépôt

### Étape 4.1 : Cloner le dépôt

```bash
cd ~/roadmap-openproject
git clone https://github.com/flaowflaow/roadmap-openproject.git .
```

### Étape 4.2 : Vérifier la structure

```bash
ls -la
```

**Output attendu :**
```
.
├── README.md
├── .gitignore
├── Dockerfile
├── docker-compose.dev.yml
├── dev/
│   ├── docker-compose.dev.yml
│   └── .env.dev (à créer)
├── observability/
├── proxy/
├── swarm/
└── docs/
```

---

## 5. Configuration de l'Environnement

### Étape 5.1 : Créer le fichier `.env.dev`

```bash
cat > dev/.env.dev << 'EOF'
# ============= APPLICATION =============
APP_NAME=roadmap-openproject
APP_ENV=development

# ============= DATABASE =============
POSTGRES_DB=openproject
POSTGRES_USER=openproject
POSTGRES_PASSWORD=ChangeMeSecurePassword123!
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# ============= REDIS =============
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=ChangeMe456SecurePass!

# ============= OPENSEARCH =============
OPENSEARCH_HOST=opensearch
OPENSEARCH_PORT=9200
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=ChangeMe789SecurePass!
OPENSEARCH_DASHBOARDS_PASSWORD=ChangeMe789!

# ============= CLOUDFLARE TUNNEL =============
CLOUDFLARE_TUNNEL_TOKEN=YOUR_TUNNEL_TOKEN_HERE
CLOUDFLARE_TUNNEL_NAME=roadmap-openproject

# ============= TRAEFIK =============
TRAEFIK_API_INSECURE=true
TRAEFIK_LOG_LEVEL=INFO

# ============= OPENPROJECT =============
OPENPROJECT_HOST=openproject.local
OPENPROJECT_PROTOCOL=http
OPENPROJECT_PORT=8080
SECRET_KEY_BASE=ChangeMeWithRandomString32Chars!

# ============= LOGSTASH =============
LOGSTASH_LOG_LEVEL=info

# ============= UPTIME KUMA =============
UPTIME_KUMA_PORT=3001
EOF
```

> ⚠️ **IMPORTANT :** Remplacez les mots de passe par des valeurs sécurisées !

### Étape 5.2 : Générer une clé secrète sécurisée

```bash
openssl rand -base64 32
```

Copiez le résultat et remplacez `SECRET_KEY_BASE` dans `.env.dev`

### Étape 5.3 : (Optionnel) Ajouter un token Cloudflare Tunnel

Si vous utilisez Cloudflare Tunnel :

```bash
# Remplacez dans .env.dev
CLOUDFLARE_TUNNEL_TOKEN=YOUR_ACTUAL_TUNNEL_TOKEN
```

Pour créer un tunnel : https://dash.cloudflare.com/

### Étape 5.4 : Vérifier les permissions du fichier

```bash
chmod 600 dev/.env.dev
ls -la dev/.env.dev
```

---

## 6. Lancement en Développement

### Étape 6.1 : Pré-construire les images (optionnel)

```bash
docker compose -f dev/docker-compose.dev.yml build
```

Cette étape peut prendre **10-30 minutes** selon la vitesse de votre connexion.

### Étape 6.2 : Démarrer la stack

```bash
cd ~/roadmap-openproject
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml up -d
```

### Étape 6.3 : Vérifier le démarrage

```bash
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml ps
```

**Output attendu :**
```
NAME                          COMMAND                  STATUS          PORTS
roadmap-postgres-1            "docker-entrypoint.s…"   Up 2 minutes    5432/tcp
roadmap-redis-1               "redis-server --auth …"  Up 2 minutes    6379/tcp
roadmap-opensearch-1          "bash opensearch.sh"     Up 2 minutes    9200/tcp, 9600/tcp
roadmap-opensearch-dashboards-1  "tini /usr/local/bi…"   Up 2 minutes    5601/tcp
roadmap-logstash-1            "/usr/share/logstash/…"  Up 1 minute     9600/tcp
roadmap-metricbeat-1          "metricbeat -e -strict…" Up 1 minute
roadmap-cadvisor-1            "/usr/bin/cadvisor"      Up 2 minutes    8081/tcp
roadmap-traefik-1             "traefik --configFile…"  Up 2 minutes    80/tcp, 443/tcp, 8088/tcp
roadmap-cloudflared-1         "cloudflared tunnel r…"  Up 1 minute
roadmap-openproject-1         "/usr/bin/openproject …"  Up 45 seconds   8080/tcp
roadmap-uptime-kuma-1         "node server/server.j…"  Up 30 seconds   3001/tcp
```

### Étape 6.4 : Consulter les logs

```bash
# Tous les logs
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml logs -f

# Logs d'un service spécifique
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml logs openproject -f
```

---

## 7. Déploiement en Production (Swarm)

### Étape 7.1 : Initialiser le cluster Swarm

Sur le **manager node** :

```bash
docker swarm init
```

**Output attendu :**
```
Swarm initialized: current node (xxxxx) is now a manager.
```

### Étape 7.2 : Ajouter les workers au cluster

Sur chaque **worker node**, exécutez d'abord sur le manager :

```bash
docker swarm join-token worker
```

Puis sur chaque worker :

```bash
docker swarm join --token SWMTKN-xxx <MANAGER_IP>:2377
```

### Étape 7.3 : Vérifier les nœuds

Depuis le manager :

```bash
docker node ls
```

**Output attendu :**
```
ID                            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS
xxxxx *                       manager       Ready     Active         Leader
yyyyy                         worker-1      Ready     Active
zzzzz                         worker-2      Ready     Active
```

### Étape 7.4 : Créer les secrets Docker

```bash
# Secret Cloudflare Tunnel
echo "YOUR_TUNNEL_TOKEN" | docker secret create cf_tunnel_token -

# Secret PostgreSQL
echo "ChangeMeSecurePassword123!" | docker secret create postgres_password -

# Secret OpenSearch
echo "ChangeMe789SecurePass!" | docker secret create opensearch_password -

# Secret Redis
echo "ChangeMe456SecurePass!" | docker secret create redis_password -
```

### Étape 7.5 : Créer les réseaux overlay

```bash
docker network create --driver overlay --opt encrypted traefik
docker network create --driver overlay --opt encrypted backend
docker network create --driver overlay --opt encrypted obs
```

### Étape 7.6 : Déployer la stack

```bash
cd ~/roadmap-openproject
docker stack deploy -c swarm/stack.yml roadmap
```

### Étape 7.7 : Vérifier le déploiement

```bash
docker stack services roadmap
docker stack ps roadmap
```

---

## 8. Vérification & Tests

### Étape 8.1 : Accès aux services (Développement)

| Service | URL | Identifiants |
|---------|-----|---|
| **RoadMap-OpenProject** | http://localhost:8080 | admin / admin |
| **OpenSearch Dashboards** | http://localhost:5601 | admin / changeme789 |
| **Uptime Kuma** | http://localhost:3001 | — |
| **Traefik Dashboard** | http://localhost:8088 | — |

### Étape 8.2 : Test de connectivité PostgreSQL

```bash
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml exec postgres psql -U openproject -d openproject -c "SELECT version();"
```

### Étape 8.3 : Test de connectivité Redis

```bash
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml exec redis redis-cli -a ChangeMe456SecurePass! PING
```

**Output attendu :**
```
PONG
```

### Étape 8.4 : Test de connectivité OpenSearch

```bash
curl -u admin:ChangeMe789SecurePass! http://localhost:9200/ | jq .
```

### Étape 8.5 : Santé globale de la stack

```bash
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml ps
```

Tous les services doivent être **"Up"**.

---

## Troubleshooting

### ❌ Erreur : "Docker daemon is not running"

**Solution :**
```bash
sudo systemctl start docker
sudo systemctl status docker
```

### ❌ Erreur : "Permission denied while trying to connect to the Docker daemon"

**Solution :**
```bash
sudo usermod -aG docker $USER
newgrp docker
# Reconnectez-vous à votre session
```

### ❌ Erreur : "docker-compose: command not found"

**Solution :**
```bash
docker compose version  # Utilisez "docker compose" (avec espace)
# Et non "docker-compose" (avec tiret)
```

### ❌ Erreur : Port 8080 déjà utilisé

**Solution :**
```bash
# Trouver le processus utilisant le port
ss -tlnp | grep 8080

# Tuer le processus ou modifier le port dans .env.dev
```

### ❌ Erreur : "postgres: could not open file: /var/lib/postgresql/data"

**Solution :**
```bash
# Les répertoires de données doivent exister
mkdir -p .data/postgres .data/opensearch .data/redis
chmod 777 .data/*
```

### ❌ Logs vides dans Openproject

**Solution :**
```bash
# Attendre 2-3 minutes que l'application se initialise
# Vérifier les logs en détail
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml logs openproject -f --tail=50
```

### ❌ Erreur : "Out of memory"

**Solution :**
```bash
# Augmenter les ressources Docker
# Réduire le nombre de replicas ou réduire le heap OpenSearch

# Dans docker-compose.dev.yml :
# OPENSEARCH_JAVA_OPTS: -Xms512m -Xmx512m
```

### ❌ Cloudflare Tunnel ne démarre pas

**Solution :**
```bash
# Vérifier le token
echo $CLOUDFLARE_TUNNEL_TOKEN

# Consulter les logs
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml logs cloudflared -f
```

---

## Étapes Suivantes

Après l'installation réussie :

1. ✅ Consultez [README.md](../README.md) pour l'architecture complète
2. ✅ Configurez les dashboards dans OpenSearch Dashboards
3. ✅ Importez les dashboards Grafana si applicable
4. ✅ Testez les alertes via Uptime Kuma
5. ✅ Lisez [CERTIFICATIONS.md](CERTIFICATIONS.md) pour les points DCA

---

## Support & Aide

- 📖 **Documentation Docker :** https://docs.docker.com/
- 📖 **Documentation OpenProject :** https://www.openproject.org/docs/
- 📖 **Documentation OpenSearch :** https://opensearch.org/docs/
- 🐛 **Issues :** https://github.com/VOTRE_USERNAME/roadmap-openproject/issues

---

**✨ Installation terminée avec succès !**
