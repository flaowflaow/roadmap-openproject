# Guide de réflexion et d’exécution — Construction d’une image Docker OpenProject
Ce document est un guide de réflexion et d’exécution pour construire une image Docker OpenProject propre, optimisée et adaptée à la production. Il couvre les étapes clés, les choix d’architecture, les pièges à éviter et les bonnes pratiques pour concevoir une image multi‑stage basée sur Alpine ou Debian, avec un runtime non‑root, des logs sur STDOUT, et une intégration facile dans un pipeline CI/CD.

---

## 1. Définir l’objectif de build

1.1. Choisir la base système :
- **Alpine** pour une image légère (compilations natives nécessaires).
- **Debian/Ubuntu** pour minimiser les frictions Ruby/gems.

1.2. Fixer le périmètre fonctionnel : build complet ou minimal (plugins limités).

1.3. Adopter un **runtime non‑root**.

1.4. Retenir le serveur d’application (**Puma** recommandé).

1.5. Standardiser les logs sur **STDOUT/STDERR** (intégration pipelines observabilité).

1.6. Définir la stratégie de tag : `major-alpine`, `major.minor-alpine`, `dev`.

---

## 2. Concevoir l’architecture multi‑stage

2.1. **Stage 1 — Builder Ruby (gems)**
- Installer toolchain de compilation et *-dev nécessaires.
- Résoudre les gems natives (ex. `pg`, `nokogiri`, `ffi`, `sassc`, `vips`).
- Exécuter `bundle install` en environnement *production*.

2.2. **Stage 2 — Builder Assets**
- Installer Node.js + gestionnaire de paquets (npm/yarn).
- Définir `SECRET_KEY_BASE` factice pour la précompilation.
- Exécuter `rake assets:precompile` (aucune compilation côté runtime).

2.3. **Stage 3 — Runtime minimal**
- Installer uniquement les dépendances d’exécution (Ruby runtime, `tini`, `tzdata`, `imagemagick`, client `psql` si nécessaire).
- Créer l’utilisateur système dédié ; ajuster les permissions des répertoires d’écriture.
- Définir `ENTRYPOINT`/`CMD` (voir §7).

---

## 3. Recenser les dépendances critiques

3.1. Lire `.ruby-version` du dépôt OpenProject pour arrêter la version Ruby de base.
3.2. Dresser la table *gem → paquets système requis* à partir des erreurs de `bundle install`.
3.3. Lister les dépendances JS (versions, lockfiles).
3.4. Établir les variables nécessaires à la build d’assets (`NODE_ENV`, `RAILS_ENV`, `SECRET_KEY_BASE` factice).

---

## 4. Définir le contrat runtime (Entrées/Sorties)

4.1. Variables d’environnement exigées :
- `DATABASE_URL`, `OPENPROJECT_HTTPS`, `OPENPROJECT_HOST__NAME`, `REDIS_URL` (si cache), toute variable spécifique au déploiement.

4.2. Port exposé : **8080** (par défaut Puma).

4.3. Volumes/données :
- Localisation des assets persistants (ex. `/var/openproject/assets`).
- Éviter les logs fichiers ; préférer STDOUT.

4.4. Healthcheck :
- Contrôler `GET http://127.0.0.1:8080/` ou endpoint de santé si disponible.

---

## 5. Exigences de sécurité et robustesse

5.1. Exécuter le service en **utilisateur non‑root**.
5.2. Utiliser **`tini`** comme PID 1.
5.3. Limiter la surface d’attaque (runtime sans toolchain, ni *-dev*).
5.4. Vérifier les permissions (chown/chmod) des répertoires d’écriture.
5.5. Définir un **HEALTHCHECK** pour activer les redémarrages supervisés.

---

## 6. Méthodologie de build (itérative)

6.1. Prototyper un **Dockerfile mono‑stage** pour collecter les erreurs de compilation (gems/JS).
6.2. Migrer vers **multi‑stage** dès stabilisation des dépendances.
6.3. Nettoyer chaque stage (cache npm/bundle, dossiers inutiles).
6.4. Exécuter un **smoke test** local (voir §8).
6.5. Mesurer la taille ; comparer avec une base Debian pour arbitrer Alpine vs Debian.

---

## 7. Démarrage et orchestration de processus

7.1. `ENTRYPOINT` : `/sbin/tini --` (gestion des signaux et zombies).
7.2. `CMD` : `bundle exec puma -C config/puma.rb -p ${PORT:-8080}`.
7.3. Migrations de base de données :
- Exécuter en **job séparé** (ex. tâche CI/CD ou `docker run … rake db:migrate`) **ou**
- Intégrer une séquence *preStart* idempotente (précautions en environnement Swarm).
7.4. Secrets/configuration : variables en **dev** ; **Docker Secrets** en Swarm/prod.

---

## 8. Tests locaux minimaux

8.1. Build : `docker build -t <image>:dev -f roadmap-openproject/Dockerfile .`
8.2. Run : `docker run --rm -p 8080:8080 <image>:dev`.
8.3. Vérifier :
- Accessibilité HTTP locale.
- Absence de compilation à chaud (assets déjà présents).
- Logs en STDOUT uniquement.
- Raccordement à PostgreSQL en dev (Compose) via `DATABASE_URL`.

---

## 9. Intégration Compose (dev)

9.1. Déclarer `build:` ou `image:` + `--build` pour itérations rapides.
9.2. Organiser des **profiles** :
- `core` : OP / DB / Redis / Traefik.
- `all` : + Observabilité (Logstash, OpenSearch, Metricbeat, cAdvisor, Uptime‑Kuma).
9.3. Centraliser les variables dans `.env.dev` (non commité).

---

## 10. Intégration Swarm (prod)

10.1. Publier l’image sur un registre privé/public avec tag explicite.
10.2. Définir les **labels Traefik** : `router.rule`, `entrypoints`, `service.port`.
10.3. Placer le service sur **workers** via `placement.constraints`.
10.4. Gérer la configuration sensible avec **Docker Secrets**.
10.5. Configurer les **rolling updates** (`update_config`) et la stratégie de redémarrage.

---

## 11. Versionnage et multi‑architecture

11.1. Adopter une nomenclature de tags stable (`13-alpine`, `13.1.0-alpine`, `dev`).
11.2. Prévoir **buildx** pour `linux/amd64,linux/arm64` si nécessaire.
11.3. Pinner les versions (Ruby, OP, paquets natifs) pour la reproductibilité.

---

## 12. Optimisations

12.1. Ordonner `COPY`/`RUN` pour maximiser le cache.
12.2. Supprimer caches (bundle/npm), artefacts de build, `.git`.
12.3. Limiter l’image runtime aux binaires strictement requis.
12.4. Ajouter un healthcheck efficace (latence, timeout, retries raisonnables).

---

## 13. Pièges fréquents et remèdes

13.1. Gems natives en échec sur Alpine → ajouter les libs *-dev* manquantes et recompiler.
13.2. `SECRET_KEY_BASE` absent lors de `assets:precompile` → définir une valeur factice au stage build.
13.3. Recompilation au démarrage → assets non précompilés ou pipeline incomplet.
13.4. Erreurs de permissions (`EACCES`) → corriger propriétaires/groupes des répertoires d’écriture.
13.5. Surpoids de l’image → supprimer paquets de build dans le runtime ; revoir le découpage.

---

## 14. Checklist de validation

- [ ] Démarrage sans compilation runtime.
- [ ] Assets précompilés.
- [ ] Logs sur STDOUT/STDERR uniquement.
- [ ] Exécution **non‑root**.
- [ ] Permissions des répertoires d’écriture correctes.
- [ ] Healthcheck réussi localement.
- [ ] Variables d’environnement documentées.
- [ ] Tagging défini, éventuellement build multi‑arch validé.

---

## 15. Ordre de travail recommandé (roadmap)

1. Lire `.ruby-version` et arrêter la base Ruby.
2. Énumérer les gems natives et déduire la liste des paquets système.
3. Prototyper un Dockerfile mono‑stage pour collecter les erreurs.
4. Rebasculer en multi‑stage (gems → assets → runtime).
5. Tester localement (HTTP, logs, DB).
6. Documenter ENV/ports/volumes/healthcheck.
7. Intégrer à Compose (dev) puis publier et intégrer à Swarm (prod).

---

## 16. Espace de notes (compléter)

- Gems → paquets Alpine requis :
  - `nokogiri` → `libxml2-dev`, `libxslt-dev`
  - `pg` → `postgresql-dev`
  - `ffi` → `libffi-dev`
  - autres : …
- Scripts : `rake db:migrate` (job/preStart), tâches de maintenance.
- Décisions : utilisateur runtime, port applicatif, structure des volumes.
