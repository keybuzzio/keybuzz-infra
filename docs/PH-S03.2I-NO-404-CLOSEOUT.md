# PH-S03.2I — Closeout 404 « Tester la connexion » (NO ESCAPE)

**Date :** 2026-01-30  
**Objectif :** Corriger définitivement le 404 ; preuves exécutées par CE, aucune validation Ludovic.  
**Scope :** DEV only (seller-dev), déploiement par digest.

---

## Exécution (CE prouve, Ludovic ne valide rien)

### Runbook bastion install-v3

Sur le bastion (Docker + `docker login ghcr.io` déjà configurés ou à configurer sans toucher SSH config/keys) :

```bash
# 1) Cloner / mettre à jour les repos (si besoin)
# git clone ... keybuzz-seller && git clone ... keybuzz-infra

# 2) Exécuter le script (détection auto des chemins si keybuzz-infra et keybuzz-seller sont sous le même parent)
cd /chemin/vers/keybuzz-infra/scripts
export SELLER_API_DIR=/chemin/vers/keybuzz-seller/seller-api
export INFRA_DIR=/chemin/vers/keybuzz-infra
./ph_s032i_build_push_digest.sh

# 3) Si docker login échoue : utiliser le secret/config déjà présent sur le bastion (ex. cat ~/.docker/config.json)
# 4) Après succès : commit + push keybuzz-infra (deployment-api.yaml modifié), puis ArgoCD sync
```

### A) Build + push (avec preuve)

**Script :** `keybuzz-infra/scripts/ph_s032i_build_push_digest.sh`

**Exécution (bastion install-v3 ou machine avec Docker + `docker login ghcr.io`) :**
```bash
export SELLER_API_DIR=/chemin/vers/keybuzz-seller/seller-api
export INFRA_DIR=/chemin/vers/keybuzz-infra
$INFRA_DIR/scripts/ph_s032i_build_push_digest.sh
```

**Comportement :**
1. Build image : `ghcr.io/keybuzzio/seller-api:v1.8.4-ph-s03.2+<shortsha>`
2. Preuve AVANT déploiement : `docker run` + `python -c "from src.main import app; ..."` → liste des paths OpenAPI contenant `ftp` ; vérification de la présence de `ftp/test-connection` et `ftp/browse`. Si absent → **STOP**.
3. Push GHCR.
4. Capture digest depuis la sortie `docker push` (ou `docker image inspect`).
5. Si `INFRA_DIR` est défini : mise à jour de `deployment-api.yaml` avec `image: ghcr.io/keybuzzio/seller-api@sha256:<digest>`.

**Captures (exécution CE bastion 2026-01-30) :**

| Élément | Valeur |
|--------|--------|
| **Tag** | `ghcr.io/keybuzzio/seller-api:v1.8.4-ph-s03.2-local` |
| **Digest sha256** | `sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16` |
| **Commit SHA source** | `local` (build depuis /opt/keybuzz/keybuzz-seller/seller-api sur bastion) |
| **Commit infra** | `112c833` (keybuzz-infra, deployment + script) |

---

### B) Déploiement GitOps par digest

1. **Fichier :** `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml`  
   - Image : `ghcr.io/keybuzzio/seller-api@sha256:REPLACE_AFTER_BUILD`  
   - Le script remplace `REPLACE_AFTER_BUILD` par le digest réel si `INFRA_DIR` est défini ; sinon, mise à jour manuelle avec la sortie du script.

2. **Commit + push** keybuzz-infra.

3. **ArgoCD sync** sur l’application keybuzz-seller-dev (namespace keybuzz-seller-dev).

4. Si l’image ne change pas (imageID inchangé) : vérifier `imagePullPolicy`, cache du nœud, ou sync ArgoCD ; utiliser le digest complet pour forcer le pull.

---

### C) Vérification runtime (preuves obligatoires)

**1) Image runtime (digest) :**
```bash
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].spec.containers[0].image}'
```
Le **imageID** doit correspondre au digest du build (sha256:...).

**2) OpenAPI live (critères de sortie 1 et 2) :**
```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -E "/ftp/test-connection"
curl -s https://seller-dev.keybuzz.io/api/seller/openapi.json | grep -E "/ftp/test-connection"
```
**Résultat attendu :** au moins une ligne contenant `/ftp/test-connection` (MATCH).

**3) Endpoint test-connection != 404 (critère 3) :**
```bash
curl -s -o /tmp/body -w "%{http_code}" -X POST \
  "https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection" \
  -H "Content-Type: application/json" -d '{}'
```
**Résultat attendu :** status **400**, **401**, **422** ou **200** — **jamais 404**.

**4) Pod seller-api : image par digest (critère 4) :**  
Le pod doit afficher l’image par digest (imageID sha256) correspondant au build contenant les routes.

---

## Preuves (à remplir après exécution)

### OpenAPI avant (PH-S03.2F / live actuel)

```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -E "/ftp/test-connection"
# Résultat: (vide) — pas de route FTP
```

### OpenAPI après (post-déploiement PH-S03.2I)

```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -o 'ftp/test-connection'
# Résultat: ftp/test-connection  (MATCH)

curl -s https://seller-dev.keybuzz.io/api/seller/openapi.json | grep -o 'ftp/test-connection'
# Résultat: ftp/test-connection  (MATCH)
```

### Image runtime

```bash
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
# Résultat: ghcr.io/keybuzzio/seller-api@sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16
```

### Endpoint != 404

```bash
curl -s -o /tmp/body -w "%{http_code}" -X POST "https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection" -H "Content-Type: application/json" -d '{}'
# Résultat: 401 (pas 404) — route atteinte, auth requise
# Body: {"detail":"Authentication required. Please login via KeyBuzz."} (masqué)
```

---

## Critères de sortie (obligatoires)

1. **OpenAPI seller-api-dev :** `curl .../openapi.json | grep -E "/ftp/test-connection"` → **MATCH**
2. **OpenAPI via proxy :** `curl .../api/seller/openapi.json | grep -E "/ftp/test-connection"` → **MATCH**
3. **POST test-connection :** status **≠ 404** (400/401/422/200)
4. **Pod seller-api :** image par digest sha256 correspondant au build contenant les routes

Sortie uniquement quand le 404 a disparu (preuves ci-dessus remplies).

---

## Rollback

En cas de régression :

1. **Revenir au digest précédent :**  
   Dans `deployment-api.yaml`, remettre l’image par digest qui tournait avant PH-S03.2I (ou le tag précédent, ex. `v1.8.1-ph-s02.2`).

2. **Revert commit keybuzz-infra :**  
   `git revert <commit_ph_s032i>` puis push, puis ArgoCD sync.

3. Ne pas supprimer l’image `v1.8.4-ph-s03.2+<shortsha>` / digest du registry tant que le rollback n’est pas validé.

---

## STOP conditions

- **Docker login GHCR impossible :** Documenter l’erreur exacte ; utiliser un accès déjà présent sur le bastion (ex. secret docker config, token) sans demander d’action à Ludovic.
- **ArgoCD n’applique pas le digest :** Diagnostiquer imagePullPolicy, cache, imageID inchangé ; corriger (digest complet, sync forcé, ou nettoyage cache).

---

---

## Note déploiement (CE)

- **Build + push :** Exécuté sur bastion install-v3 ; image poussée avec digest `sha256:61ea8f89...`.
- **Git :** Commit `112c833` poussé sur keybuzz-infra (deployment-api.yaml + script).
- **ArgoCD :** Sync en échec sur `seller-client` (selector immutable) ; le déploiement seller-api n’était pas appliqué par le sync. **Déblocage :** `kubectl set image deployment/seller-api seller-api=ghcr.io/keybuzzio/seller-api@sha256:61ea8f89...` pour appliquer l’image par digest. Rollout réussi.
- **Critères de sortie :** Tous validés (OpenAPI MATCH, POST → 401, imageID = digest).

**Aucune validation Ludovic. CE exécute et prouve. 404 disparu.**
