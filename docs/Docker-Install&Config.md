# 🐳 Docker — Installation & Configuration (DEV + PROD)

Version compacte, professionnelle, adaptée au projet **RoadMap‑OpenProject**.

---

# 1. Installation de Docker (RHEL / Rocky / Alma)

## Désinstaller les anciennes versions
```bash
sudo dnf remove docker docker-client docker-common docker-engine podman runc
```

## Ajouter le dépôt Docker
```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

## Installer Docker + Compose
```bash
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Activer Docker au démarrage
```bash
sudo systemctl enable --now docker
```

## Utilisation sans sudo
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

---

# 2. Configuration DEV
*Objectif : simplicité, rapidité, compatibilité `docker logs`.*

## daemon.json (DEV)
```json
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Redémarrer Docker :
```bash
sudo systemctl restart docker
```

---

# 3. Configuration PROD (Swarm + Observabilité)
*Objectif : stabilité, sécurité, performances.*

## Paramètres système
### Pour OpenSearch
```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Activer cgroups v2
```bash
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
```

### Firewall Swarm / Traefik
```bash
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --add-port=2377/tcp --permanent
sudo firewall-cmd --add-port=7946/tcp --permanent
sudo firewall-cmd --add-port=7946/udp --permanent
sudo firewall-cmd --add-port=4789/udp --permanent
sudo firewall-cmd --reload
```

---

# 4. daemon.json (PROD)
```json
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5",
    "compress": "true"
  },
  "live-restore": true,
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

Redémarrer Docker :
```bash
sudo systemctl restart docker
```

---

# 5. Initialisation Swarm (PROD)
## Manager
```bash
docker swarm init --advertise-addr <IP_MANAGER>
```

## Worker
```bash
docker swarm join --token <TOKEN> <IP_MANAGER>:2377
```

---

# 6. Vérifications
```bash
docker info | grep "Logging Driver"
docker info | grep Cgroup
docker network ls
sysctl vm.max_map_count
```

---

# 7. Troubleshooting rapide
| Problème | Solution |
|---------|----------|
| `docker logs` indisponible | Ne pas utiliser `syslog` → driver `local` |
| Containers stoppés au restart Docker | Ajouter `"live-restore": true` |
| OpenSearch KO | `vm.max_map_count` absent |
| Overlay Swarm KO | Ports 4789/udp ou 7946 bloqués |

---

# 8. Conclusion
Configuration prête pour **Dev**, **Prod**, **Swarm**, **Traefik**, **OpenSearch**, **Logstash**, et intégrée dans le projet **RoadMap‑OpenProject**.

