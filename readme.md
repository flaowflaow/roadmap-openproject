# 🚀 RoadMap‑OpenProject — Plateforme DevOps & Observabilité

---

## 📚 Table des matières

- [🚀 RoadMap‑OpenProject — Plateforme DevOps & Observabilité](#-roadmapopenproject--plateforme-devops--observabilité)
  - [🎯 Objectifs](#-objectifs)
  - [🏗️ Architecture globale](#️-architecture-globale)
    - [Frontend exposé (Traefik + Cloudflare Tunnel)](#frontend-exposé-traefik--cloudflare-tunnel)
    - [Backend Observabilité & Pipeline](#backend-observabilité--pipeline)
    - [Cluster Swarm (3 nœuds)](#cluster-docker-swarm-3-nœuds)
  - [📁 Structure du dépôt](#-structure-du-dépôt)
  - [🧩 Environnement de développement (Docker Compose)](#-environnement-de-développement-docker-compose)
  - [🧠 DCA Skills Applied](#-dca-skills-applied-certification-validation)
    - [1. Orchestration](#1-orchestration-swarm)
    - [2. Image Creation / Multi-stage](#2-image-creation-management--registry)
    - [3. Installation & Configuration](#3-installation-and-configuration)
    - [4. Networking](#4-networking)
    - [5. Security](#5-security)
  - [🔒 Sécurité & bonnes pratiques](#-sécurité--bonnes-pratiques)
  - [🔄 Lifecycle Management](#️-lifecycle-management)
  - [🚀 Déploiement](#-déploiement)
  - [📅 Roadmap Certifications](#️-roadmap-certifications)
  - [📜 Licence](#-licence)
  - [🏷️ Badges](#️-badges)

---

# RoadMap‑OpenProject — Plateforme DevOps & Observabilité

Ce dépôt contient **l’infrastructure complète** d’une plateforme de gestion de projet et d’observabilité moderne, reposant uniquement sur **RoadMap‑OpenProject**.

La stack repose sur :
- Une **image Alpine multi‑stage** construite depuis les sources **OpenProject**
- Un cluster **Docker Swarm (3 nœuds)**
- Une exposition **Cloudflare Tunnel** (aucun port ouvert)
- Un reverse‑proxy **Traefik v3**
- Une stack d’observabilité complète : **OpenSearch**, **Dashboards**, **Logstash**, **Metricbeat**, **cAdvisor**, **SNMP**
- Une supervision réelle via **Uptime Kuma**

---

## 🎯 Objectifs

- Obtenir une **plateforme OpenProject performante, légère et sécurisée**
- Assurer une **haute disponibilité** grâce au cluster Swarm
- Centraliser logs & métriques (système, Docker, réseau)
- Superviser l’infrastructure via **OpenSearch Dashboards**
- Fournir un accès externe **sans ouverture de ports** grâce à Cloudflare
- Surveiller la disponibilité réelle via **Uptime Kuma**

---

# 🏗️ Architecture globale

```
                                   ┌────────────────────────────────┐
                                   │            Internet            │
                                   └───────────────▲────────────────┘
                                                   │
                                           Cloudflare (WAF + TLS)
                                                   │
                                      (Tunnel sortant — aucun port WAN)
                                                   │
                                   ┌───────────────┴────────────────┐
                                   │           cloudflared          │
                                   │     (Tunnel vers Cloudflare)   │
                                   └───────────────▲────────────────┘
                                                   │  overlay: traefik
                                      routes HTTPS │
                                                   │
                                   ┌───────────────┴────────────────┐
                                   │             Traefik            │
                                   │  Reverse Proxy (labels Swarm)  │
                                   └───────▲────────▲──────────▲────┘
                                           │        │          │
                        Applications       │        │          │       Applications
                        accessibles        │        │          │       accessibles
                        depuis Internet    │        │          │       depuis Internet
                                           │        │          │
               ┌───────────────────────────┘        │          └───────────────────────────┐
               │                                    │                                      │
┌───────────────────────────────┐                   │                  ┌──────────────────────────────┐
│     RoadMap‑OpenProject       │                   │                  │   OpenSearch Dashboards      │
│     (UI OpenProject)          │                   │                  │     (UI Observabilité)       │
│     port 8080                 │                   │                  │     port 5601                │
└───────────────────────────────┘                   │                  └──────────────────────────────┘
                                                    │
                                    ┌────────────────────────────┐
                                    │        Uptime Kuma         │
                                    │  (HTTP/TCP/Ping; LAN + CF) │
                                    └────────────────────────────┘


────────────────────────────  BACKEND (observabilité & pipeline)  ────────────────────────────

    ┌────────────────────────────────────────────────────────────────────────────────────────┐
    │                                        Observabilité                                   │
    └──────────────────────────────┬───────────────────────────────┬─────────────────────────┘
                                   │                               │
                      (global — chaque nœud)              (global — chaque nœud)
                 ┌───────────▼───────────┐              ┌────────▼──────────────────┐
                 │ Metricbeat (sys,      │              │        cAdvisor           │
                 │ docker, swarm)        │              │ (metrics conteneurs)      │
                 └───────────▲───────────┘              └────────▲──────────────────┘
                             │   envoi beats (5044)               │
                             │                                    │
                     ┌───────┴────────────────────────────────────┴────────┐
                     │                        Logstash                     │
                     │   pipelines : logs OP, métriques, SNMP, events      │
                     └───────▲───────────────────────────────────▲─────────┘
                             │                                   │
                             │                                   │   SNMP (réseau)
                    ┌────────┴─────────┐                ┌────────┴──────────────────┐
                    │    OpenSearch    │◄───────────────┤     Metricbeat SNMP       │
                    │ (stockage data)  │                └───────────────────────────┘
                    └──────────────────┘
```

---

# 🐋 Cluster Docker Swarm (3 nœuds)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                Swarm Cluster                                 │
│                                                                              │
│  [Manager]  Node‑1 — overlay: traefik | backend | obs                        │
│                                                                              │
│      Services dédiés au manager (faible charge + accès Docker API) :         │
│        - Traefik (reverse proxy)                                             │
│        - cloudflared (Tunnel Cloudflare)                                     │
│        - Uptime‑Kuma (optionnel ici, très léger)                             │
│                                                                              │
│      Services globaux (mode global, tous les nœuds) :                        │
│        - Metricbeat (collecte système/Docker/Swarm)                          │
│        - cAdvisor (métriques Docker)                                         │
│                                                                              │
│                                                                              │
│  [Worker]   Node‑2 — overlay: traefik | backend | obs                        │
│                                                                              │
│      Services applicatifs principaux :                                       │
│        - RoadMap‑OpenProject (UI)                                            │
│        - PostgreSQL (DB)                                                     │
│        - Redis (cache)                                                       │
│                                                                              │
│      Observabilité backend :                                                 │
│        - OpenSearch (moteur)                                                 │
│        - Dashboards (UI)                                                     │
│        - Logstash (pipelines logs/metrics/SNMP)                              │
│                                                                              │
│      Services globaux :                                                      │
│        - Metricbeat[global]                                                  │
│        - cAdvisor[global]                                                    │
│                                                                              │
│                                                                              │
│  [Worker]   Node‑3 — overlay: traefik | backend | obs                        │
│                                                                              │
│      Répartition / redondance / scalabilité :                                │
│        - RoadMap‑OpenProject (réplica si désiré)                             │
│        - OpenSearch (réplica potentiel en prod)                              │
│        - Logstash (réplica possible)                                         │
│                                                                              │
│      Services globaux :                                                      │
│        - Metricbeat[global]                                                  │
│        - cAdvisor[global]                                                    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

# 📁 Structure du dépôt

```
.
├── roadmap-openproject/
│   ├── Dockerfile                # Build Alpine multi-stage
│   └── entrypoint.sh
│
├── observability/
│   ├── logstash/
│   │   ├── logstash.conf
│   │   └── pipelines/           # (si tu veux splitter par pipelines)
│   ├── metricbeat/
│   │   ├── metricbeat.yml
│   │   └── modules.d/
│   ├── metricbeat-snmp.yml
│   └── dashboards/
│
├── proxy/
│   ├── traefik/
│   │   ├── traefik.yml
│   │   └── dynamic/
│   └── cloudflared/
│       └── config.yml
│
├── swarm/
│   ├── stack.yml
│   ├── networks.yml
│   └── secrets/                 # références/README pour Docker secrets
│
├── dev/
│   ├── docker-compose.dev.yml   # ← compose dev avec TOUS les services
│   └── .env.dev                 # ← variables locales (non commit)
│
├── docs/
│   ├── CERTIFICATIONS.md
│   └── schema/
│
└── README.md
```

---

# 🧩 Environnement de développement (Docker Compose)

Pour développer localement **sans déployer le cluster Swarm**, ce dépôt fournit un
`docker-compose.dev.yml` qui **reprend tous les services** de la stack :

- Traefik
- cloudflared
- RoadMap‑OpenProject
- PostgreSQL
- Redis
- OpenSearch
- OpenSearch Dashboards
- Logstash
- Metricbeat
- cAdvisor
- Metricbeat SNMP
- Uptime‑Kuma

> 🎯 **Objectif :** itérer rapidement en local, valider les configurations (Traefik, réseaux,
> variables d’environnement, volumes) et pré‑tester avant un `docker stack deploy`.

---

### ▶️ Lancer l’environnement de dev

```sh
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml up -d
```

---
### 🛑 Arrêter l’environnement

```sh
docker compose --env-file dev/.env.dev -f dev/docker-compose.dev.yml down
```

---
### 🔎 Accès (par défaut)

- RoadMap‑OpenProject → **http://localhost:8080**
- OpenSearch Dashboards → **http://localhost:5601**
- Uptime Kuma → **http://localhost:3001**
- Traefik Dashboard (optionnel si activé) → **http://localhost:8088**

---

### 📌 Notes importantes

- Les secrets Docker ne sont pas utilisés : tout passe par `dev/.env.dev`.
- Les volumes sont persistés sous `.data/*`.

---

# 🧠 DCA Skills Applied (Certification Validation)
Ce projet démontre la maîtrise complète des compétences requises pour la **Docker Certified Associate (DCA)**.

## 1. Orchestration (Swarm)
- Cluster **3 nœuds** : 1 manager, 2 workers.
- Déploiement via `docker stack deploy`.
- Contraintes de placement pour isoler les workloads.
- Services globaux : Metricbeat & cAdvisor.

## 2. Image Creation, Management & Registry
- Build **multi‑stage** Alpine pour RoadMap‑OpenProject.
- Sécurité renforcée : base Alpine minimale.
- Dockerfile optimisé (layers, cache, entrypoint, user non‑root).

## 3. Installation and Configuration
- Configuration complète du moteur Docker.
- Volumes persistants (PostgreSQL, Redis, OpenSearch).
- Réseaux overlay dédiés : `traefik`, `backend`, `obs`.

## 4. Networking
- Overlay networks isolés entre services.
- Routage via **Traefik v3** (labels Swarm).
- Accès externe via **Cloudflare Tunnel** (aucun port ouvert).

## 5. Security
- Secrets Docker pour DB & Tunnel Cloudflare.
- Isolation réseau stricte.
- Runtime minimal → surface d'attaque réduite.

---

## 🔄 Lifecycle Management

La plateforme suit un cycle de vie simple et maîtrisé :  
- Build et publication des images via multi‑stage Docker (`make build-push`)  
- Déploiement et mises à jour progressives via `docker stack deploy`  
- Suivi continu des services grâce à l’observabilité centralisée (OpenSearch + Dashboards + Metricbeat)  
- Répartition automatique des workloads via Docker Swarm selon les règles de placement  
- Gestion sécurisée des configurations et secrets tout au long du cycle de vie

Ce processus garantit une exploitation fluide, cohérente et reproductible.

---

# 🔒 Sécurité & bonnes pratiques

- Aucun port WAN ouvert (Cloudflare Tunnel outbound)
- Certificats TLS gérés par Cloudflare + Traefik
- Secrets via Docker Secrets
- Sécurisation OpenSearch (prod)
- Rotation automatique des logs Docker

---

# 🚀 Déploiement

### 1) Initialiser le Swarm
```sh
docker swarm init
```

### 2) Ajouter le secret Cloudflare
```sh
echo "TON_TUNNEL_TOKEN" | docker secret create cf_tunnel_token -
```

### 3) Déployer la stack
```sh
docker stack deploy -c swarm/stack.yml roadmap
```

---

## 📅 Roadmap Certifications
Ce projet s'inscrit dans un parcours d'expertise global :

* **Q1 2026 :** 🎓 **DCA (Docker Certified Associate)** — *En cours*.
* **Q2-Q3 2026 :** 🏗️ **HashiCorp Terraform & Vault Associate** (Infrastructure as Code & Sécurité).
* **2027 :** 🐧 **RHCSA & RHCE** (Ingénierie Système & Automatisation Red Hat).
* **2028-2029 :** 👨‍🚀 **Kubestronaut** (Cycle complet Kubernetes : KCNA, KCSA, CKA, CKAD, CKS).

---

# 📜 Licence

Projet personnel — libre d’usage pour inspiration technique.

## 🏷️ Badges

![Docker](https://img.shields.io/badge/Docker-2396ED?logo=docker&logoColor=white)
![Swarm](https://img.shields.io/badge/Swarm-1D63ED?logo=docker&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?logo=traefikproxy&logoColor=white)
![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare_Tunnel-F38020?logo=cloudflare&logoColor=white)
![Alpine](https://img.shields.io/badge/Alpine_Linux-0D597F?logo=alpinelinux&logoColor=white)

![OpenSearch](https://img.shields.io/badge/OpenSearch-005EB8?logo=opensearch&logoColor=white)
![Logstash](https://img.shields.io/badge/Logstash-005571?logo=elasticstack&logoColor=white)
![Metricbeat](https://img.shields.io/badge/Metricbeat-0077CC?logo=elasticstack&logoColor=white)
![cAdvisor](https://img.shields.io/badge/cAdvisor-4479A1?logo=google&logoColor=white)
![SNMP](https://img.shields.io/badge/SNMP-5B5B5B?logo=prometheus&logoColor=white)

![Uptime Kuma](https://img.shields.io/badge/Uptime_Kuma-5D5FEF?logo=monitoring&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?logo=redis&logoColor=white)

![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen)
![Contributions](https://img.shields.io/badge/Contributions-Welcome-blue)