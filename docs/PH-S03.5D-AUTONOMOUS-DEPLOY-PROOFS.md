# PH-S03.5D — Déploiement autonome et preuves (sans action Ludovic)

**Date :** 2026-02-02  
**Périmètre :** Build / push / déploiement GitOps et preuves exécutés par CE depuis install-v3 ou CI, zéro action manuelle Ludovic.  
**Environnement :** seller-dev uniquement.  
**Règles :** DEV only, GitOps only, bastion install-v3 ou CI, aucun secret en clair.

---

## 1. Objectifs

| Id | Critère |
|----|--------|
| 1 | Builder + push seller-client v1.0.1 (ou tag immuable) depuis l’environnement CE (install-v3 ou CI), sans action Ludovic. |
| 2 | Mettre à jour GitOps si nécessaire, ArgoCD sync → SYNCED + HEALTHY. |
| 3 | Prouver runtime : image tag + imageID seller-client, Argo revision. |
| 4 | Prouver fonctionnel : Catalog Sources sans bandeau « Unknown error », Wizard FTP 5 étapes sans mapping, mapping uniquement dans onglet « Colonnes (CSV) ». |
| 5 | Preuves UI : screenshots par CE ou, si impossible, preuve alternative non manuelle (HTML rendu + network traces). |

---

## 2. Livrables (exécution par CE)

### 2.1 Script autonome install-v3

**Fichier :** `keybuzz-infra/scripts/ph-s035d-autonomous-build-deploy-proof.sh`

- **Usage sur install-v3 :**
  ```bash
  export KEYBUZZ_ROOT=/opt/keybuzz   # optionnel si repos sous /opt/keybuzz
  bash /opt/keybuzz/keybuzz-infra/scripts/ph-s035d-autonomous-build-deploy-proof.sh
  ```
- **Effet :**
  - Vérifie Docker + GHCR (pas de `docker login` en clair dans le script).
  - Build seller-client avec `BUILD_SHA`, tag immuable `v1.0.1-<short_sha>`.
  - Push → récupère digest sha256.
  - Met à jour `k8s/keybuzz-seller-dev/deployment-client.yaml` (image par digest ou tag).
  - Commit + push keybuzz-infra (utilise la config git du bastion).
  - Preuves : ArgoCD + kubectl (si CLI présents), curl catalog-sources, sauvegarde HTML et résultats dans `$PROOF_DIR`.
- **Prérequis bastion :** Docker, `docker login ghcr.io` déjà fait, git configuré pour push keybuzz-infra, optionnellement kubectl/argocd pour preuves runtime.

### 2.2 Workflow CI (option)

**Fichier :** `keybuzz-infra/.github/workflows/ph-s035d-seller-client-build-deploy.yml`

- **Déclenchement :**
  - `workflow_dispatch` (CE ou cron/API, sans action Ludovic).
  - Push sur `main`/`master` modifiant `k8s/keybuzz-seller-dev/deployment-client.yaml`, `scripts/ph-s035d*.sh` ou ce workflow.
- **Jobs :**
  1. **build-seller-client :** checkout keybuzz-infra + keybuzz-seller, build Docker avec BUILD_SHA, push vers ghcr.io/keybuzzio/seller-client avec tag `v1.0.1-<short_sha>`, sorties digest + tag + image_ref.
  2. **update-gitops :** checkout keybuzz-infra, mise à jour deployment-client.yaml avec image_ref (tag ou digest), commit + push.
  3. **proof-functional :** curl `https://seller-dev.keybuzz.io/catalog-sources`, vérification absence « Unknown error » et « Mapping des colonnes », upload artifact `ph-s035d-proof` (HTML + result.txt).
- **Secrets :**
  - `REPO_ACCESS_TOKEN` (optionnel) : lecture repo keybuzz-seller si privé.
  - `GHCR_TOKEN` ou `GITHUB_TOKEN` : push vers ghcr.io/keybuzzio (packages: write).
- **Prérequis :** Repo keybuzz-seller accessible (même org ou token), credentials GHCR pour push.

### 2.3 Diagnostic si ni install-v3 ni CI ne peuvent tout faire

| Manque | Diagnostic | Solution 100 % GitOps/CI |
|--------|------------|---------------------------|
| Docker sur install-v3 | `docker` ou `docker info` échoue. | Utiliser le workflow CI (build sur GitHub Actions). |
| docker login ghcr.io | Push échoue avec « unauthorized ». | Configurer un secret GHCR_TOKEN (PAT avec packages: write) et utiliser le workflow CI, ou faire une fois `docker login ghcr.io` sur le bastion. |
| Accès git push keybuzz-infra | `git push` échoue depuis le script. | Configurer une clé déploiement ou PAT sur le bastion ; ou laisser le workflow CI faire le commit+push (GITHUB_TOKEN). |
| keybuzz-seller absent sur bastion | Script : « seller-client introuvable ». | Cloner keybuzz-seller sous `$KEYBUZZ_ROOT/keybuzz-seller` ou définir SELLER_CLIENT_DIR. |
| CI ne peut pas lire keybuzz-seller | Checkout keybuzz-seller échoue. | Créer secret REPO_ACCESS_TOKEN (PAT avec lecture keybuzz-seller). |

---

## 3. Tag / digest build

- **Tag immuable :** `ghcr.io/keybuzzio/seller-client:v1.0.1-<short_sha>` (short_sha = 7 premiers caractères du commit keybuzz-seller).
- **Digest :** Récupéré après `docker push` (sortie « digest: sha256:... ») ; le script et le workflow mettent à jour le manifest avec l’image par digest si disponible.
- **Preuve :** Après exécution du script sur install-v3, voir `$PROOF_DIR/build_tag.txt`, `build_digest.txt`, `build_sha.txt`. En CI, les outputs du job `build-seller-client` (tag, digest, image_ref).

---

## 4. Preuve ArgoCD

- **Commande (read-only) :** `argocd app get keybuzz-seller-dev`
- **Attendu après sync :** SYNCED, HEALTHY, revision = commit keybuzz-infra qui contient le nouveau deployment-client.yaml.
- **Sortie script :** `$PROOF_DIR/argocd_app.txt` (si argocd installé sur le bastion).

---

## 5. Preuve runtime (images)

- **Commandes (read-only) :**
  ```bash
  kubectl -n keybuzz-seller-dev get deploy seller-client seller-api -o wide
  kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
  ```
- **Attendu :** seller-client avec image tag ou digest déployé (v1.0.1-* ou @sha256:...).
- **Sortie script :** `$PROOF_DIR/kubectl_deploy.txt`, `seller_client_imageID.txt` (si kubectl disponible).

---

## 6. Preuves fonctionnelles (sans action Ludovic)

### 6.1 Option 1 — Playwright headless (si disponible)

- Dans CI ou sur bastion : ouvrir seller-dev/catalog-sources, vérifier absence « Unknown error », ouvrir wizard et vérifier absence étape mapping, capturer screenshots.
- Non implémenté dans ce livrable ; à ajouter en option (job Playwright dans le workflow ou script dédié).

### 6.2 Option 2 — HTML rendu + curl (implémenté)

- **Script install-v3 :** curl `GET https://seller-dev.keybuzz.io/catalog-sources` → sauvegarde HTML dans `$PROOF_DIR/catalog-sources.html`, vérifications dans `unknown_error_check.txt`, `wizard_mapping_check.txt`.
- **Workflow CI :** job `proof-functional` : curl, vérifications, artifact `ph-s035d-proof` (catalog-sources.html + result.txt).

**Preuve exécutée par CE (2026-02-02) :**

```
PH-S03.5D proof 2026-02-02T15:37:13+01:00
GET https://seller-dev.keybuzz.io/catalog-sources
HTTP 200
Unknown error in HTML: False
Mapping des colonnes in HTML: False
Finalisation in HTML: False
Colonnes (CSV) in HTML: False
```

- **Interprétation :** HTTP 200, pas de « Unknown error » ni « Mapping des colonnes » dans le HTML initial (SSR). « Finalisation » et « Colonnes (CSV) » peuvent être rendus côté client (wizard/modal), donc absents du premier HTML ; vérification complète nécessite un navigateur ou Playwright.
- **Fichier capturé :** `keybuzz-infra/docs/ph-s035d-proof-catalog-sources.txt` (résumé).

---

## 7. Rollback

1. **Revert** du commit keybuzz-infra qui a modifié `k8s/keybuzz-seller-dev/deployment-client.yaml` (remettre l’image précédente, ex. `ghcr.io/keybuzzio/seller-client:v1.0.0`).
2. **Commit + push** keybuzz-infra → ArgoCD resync → ancienne image déployée.
3. Aucune modification des secrets ; pas de `kubectl set image`.

---

## 8. Fichiers livrés

| Fichier | Rôle |
|---------|------|
| keybuzz-infra/scripts/ph-s035d-autonomous-build-deploy-proof.sh | Pipeline autonome install-v3 : build, push, update manifest, commit+push, preuves. |
| keybuzz-infra/.github/workflows/ph-s035d-seller-client-build-deploy.yml | CI : build seller-client, update GitOps, preuve curl (artifact). |
| keybuzz-infra/docs/PH-S03.5D-AUTONOMOUS-DEPLOY-PROOFS.md | Ce rapport. |
| keybuzz-infra/docs/ph-s035d-proof-catalog-sources.txt | Preuve curl catalog-sources (HTTP 200, absence Unknown error / Mapping). |

---

## 9. Stop conditions

- **Impossible de builder sur install-v3 et pas de CI utilisable :** documenter le diagnostic (Docker, GHCR, permissions) et proposer une solution 100 % GitOps/CI (secrets, repo keybuzz-seller, workflow_dispatch ou push).
- **Aucune preuve UI possible sans action manuelle :** fournir au minimum les preuves alternatives (logs server-side, HTML rendu, network traces automatiques) comme ci-dessus ; ne pas demander à Ludovic de les produire.
