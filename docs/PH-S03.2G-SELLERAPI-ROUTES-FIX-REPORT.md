# PH-S03.2G — Fix définitif 404 FTP : build + deploy image seller-api avec routes PH-S03.2

**Date :** 2026-01-30  
**Scope :** DEV only, GitOps only. Garantir que l’OpenAPI live contient les routes FTP et que « Tester la connexion » ne renvoie plus 404.

---

## Cause racine identifiée

**Constat (preuve réelle PH-S03.2F) :** L’OpenAPI servi par `seller-api-dev.keybuzz.io` et `seller-dev.keybuzz.io/api/seller/openapi.json` **ne contient aucune route** `/api/catalog-sources/{source_id}/ftp/*`. Le backend déployé ne contient donc pas le code PH-S03.2, même si le tag GitOps pointait vers `v1.8.2-ph-s03.2`.

**Cause :** L’image effectivement utilisée (ou l’image du tag déclaré) n’a pas été buildée à partir du commit contenant les routes FTP, ou le tag n’existait pas / pointait vers une ancienne image.

**Vérification code source (wiring) :**

- **Routes FTP :** `keybuzz-seller/seller-api/src/routes/ftp.py` — `router = APIRouter(prefix="/catalog-sources/{source_id}/ftp", ...)` ; endpoints `test-connection`, `browse`, `connection`, `select-file`, etc.
- **Wiring :** `keybuzz-seller/seller-api/src/main.py` — `app.include_router(ftp_router, prefix="/api")` et `app.include_router(ftp_direct_router, prefix="/api")`.
- **Package :** `src/routes/__init__.py` exporte `ftp_router` et `ftp_direct_router`.
- **Dockerfile :** `COPY src/ ./src/` puis `CMD ["uvicorn", "src.main:app", ...]` — le code source est bien inclus dans l’image.

**Conclusion :** Le code source contient les routes ; l’image déployée jusqu’ici ne les incluait pas (build absent ou tag incorrect). Il faut **builder une image à partir de ce code**, la pousser avec un **tag immuable**, et mettre à jour le déploiement GitOps pour utiliser cette image.

---

## Plan d’exécution

### A) Preuve que le code et l’image buildée exposent les routes FTP

**1) Code :** Voir ci-dessus (ftp.py, main.py, __init__.py, Dockerfile).

**2) Preuve locale SANS déployer :** Le script `keybuzz-infra/scripts/ph_s032g_build_seller_api.sh` après `docker build` exécute dans le conteneur :

```bash
docker run --rm <image> python -c "
from src.main import app
paths = list(app.openapi().get('paths', {}).keys())
ftp_paths = [p for p in paths if 'ftp' in p]
print(ftp_paths)
"
```

Si aucune route FTP n’apparaît → **STOP** : Dockerfile ou contexte de build incorrect (fichiers manquants).  
Si les routes apparaissent → l’image buildée expose bien les routes ; on peut push et déployer.

**Preuve (à remplir après exécution du script) :**
```
FTP paths dans l'image buildée:
  /api/catalog-sources/{source_id}/ftp/test-connection
  /api/catalog-sources/{source_id}/ftp/browse
  /api/catalog-sources/{source_id}/ftp/connection
  /api/catalog-sources/{source_id}/ftp/select-file
  ...
```

---

### B) Build & push image « garantie routes FTP »

**1) Script :** `keybuzz-infra/scripts/ph_s032g_build_seller_api.sh`

**2) Prérequis :** Docker, git, `docker login` vers ghcr.io (ou équivalent pour keybuzzio).

**3) Exécution (depuis machine avec Docker, ex. bastion ou CI) :**
```bash
# Option 1: depuis keybuzz-infra/scripts (détection auto de keybuzz-seller/seller-api)
cd keybuzz-infra/scripts
./ph_s032g_build_seller_api.sh

# Option 2: chemin explicite
export SELLER_API_DIR=/chemin/vers/keybuzz-seller/seller-api
./ph_s032g_build_seller_api.sh
```

**4) Comportement du script :**
- Build de l’image depuis `keybuzz-seller/seller-api` (Dockerfile présent).
- Tag **immuable** : `ghcr.io/keybuzzio/seller-api:v1.8.3-ph-s03.2+<shortsha>` (shortsha = `git rev-parse --short HEAD`).
- Vérification OpenAPI dans l’image : présence de routes FTP (dont `ftp/test-connection`) ; sinon sortie en erreur (STOP).
- Push vers ghcr.io/keybuzzio/seller-api.
- Affichage du **tag** et du **digest** (si disponible) pour mise à jour du deployment.

**5) Captures à conserver :**
- Tag exact : `ghcr.io/keybuzzio/seller-api:v1.8.3-ph-s03.2+<shortsha>`
- Digest sha256 (optionnel, pour déploiement par digest)
- Commit SHA source : `git rev-parse HEAD` dans le repo keybuzz-seller/seller-api

---

### C) Déploiement GitOps (DEV only)

**1) Mise à jour du deployment :**  
Fichier : `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml`

- L’image est actuellement : `ghcr.io/keybuzzio/seller-api:v1.8.3-ph-s03.2+REPLACE_AFTER_BUILD`
- **Action obligatoire après build :** Remplacer `REPLACE_AFTER_BUILD` par le **short SHA** affiché par le script (ex. `a1b2c3d` → image `v1.8.3-ph-s03.2+a1b2c3d`), ou utiliser l’image par digest : `ghcr.io/keybuzzio/seller-api@sha256:...`

**2) Commit / push** du repo keybuzz-infra (fichier deployment-api.yaml mis à jour avec le tag ou digest réel).

**3) ArgoCD :** Sync de l’application keybuzz-seller-dev (pas de `kubectl apply` manuel).

**4) Si ArgoCD déploie mais imageID ne change pas :** Vérifier imagePullPolicy (si `IfNotPresent`, utiliser un tag immuable différent ou un digest pour forcer le pull). Tag immuable `v1.8.3-ph-s03.2+shortsha` évite le réutilisation de cache.

---

### D) Vérification post-deploy (preuves obligatoires)

**1) Image runtime :**
```bash
kubectl get deploy seller-api -n keybuzz-seller-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```
Preuve : coller le tag et l’imageID (digest) réellement utilisés.

**2) OpenAPI (critère de sortie non négociable) :**
```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -o '"/api/catalog-sources/[^"]*ftp[^"]*"'
curl -s https://seller-dev.keybuzz.io/api/seller/openapi.json | grep -o '"/api/catalog-sources/[^"]*ftp[^"]*"'
```
**Résultat attendu :** Au moins les paths suivants présents :
- `/api/catalog-sources/{source_id}/ftp/test-connection`
- `/api/catalog-sources/{source_id}/ftp/browse`
- `/api/catalog-sources/{source_id}/ftp/connection`
- `/api/catalog-sources/{source_id}/ftp/select-file`

**Preuve à coller (après déploiement) :**
```
Avant (PH-S03.2F): grep ftp → aucune ligne.
Après (PH-S03.2G): 
  "/api/catalog-sources/{source_id}/ftp/test-connection"
  "/api/catalog-sources/{source_id}/ftp/browse"
  ...
```

**3) Disparition du 404 :**
- **curl** (sans creds) :  
  `curl -s -o /dev/null -w "%{http_code}" -X POST https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection -H "Content-Type: application/json" -d '{}'`  
  Attendu : **400** ou **401** ou **422**, **jamais 404**.
- **UI :** Le bouton « Tester la connexion » doit renvoyer 400/401/422/200, jamais 404.

**Preuve à coller :**
```
HTTP status POST .../ftp/test-connection (sans auth): 401 (ou 400/422)
→ 404 n'apparaît plus.
```

---

## Critères de sortie (non négociables)

1. **OpenAPI seller-api-dev :** Les paths suivants sont présents dans `openapi.json` :
   - `/api/catalog-sources/{source_id}/ftp/test-connection`
   - `/api/catalog-sources/{source_id}/ftp/browse`
   - `/api/catalog-sources/{source_id}/ftp/connection`
   - `/api/catalog-sources/{source_id}/ftp/select-file`

2. **OpenAPI via proxy :** `https://seller-dev.keybuzz.io/api/seller/openapi.json` contient les mêmes paths.

3. **UI :** Le bouton « Tester la connexion » ne renvoie plus 404 (attendu : 400/401/422/200).

---

## Rollback

En cas de régression :

1. **Image précédente :** Remettre dans `deployment-api.yaml` l’image utilisée avant PH-S03.2G (ex. `v1.8.1-ph-s02.2` ou le tag qui tournait effectivement).
2. **Revert commit infra :** `git revert <commit_ph_s032g>` sur keybuzz-infra puis push, puis sync ArgoCD.
3. Ne pas supprimer l’image `v1.8.3-ph-s03.2+shortsha` du registry tant que le rollback n’est pas validé.

---

## Stop conditions (diagnostic)

- **Les routes sont dans le code mais jamais dans l’image :** Dockerfile ou contexte de build incorrect (fichiers exclus, mauvais WORKDIR). Arrêter et corriger le Dockerfile / .dockerignore.
- **ArgoCD déploie mais imageID ne change pas :** Tag réutilisé ou imagePullPolicy. Utiliser un tag immuable (`v1.8.3-ph-s03.2+shortsha`) ou déployer par digest.
- **OpenAPI contient les routes mais UI renvoie encore 404 :** Problème de proxy/path (seller-client ou ingress). Traiter dans un PH dédié « proxy rewrite » après avoir confirmé qu’OpenAPI est OK.

---

## Récapitulatif des artefacts

| Artefact | Emplacement |
|----------|-------------|
| Script build + preuve OpenAPI locale | `keybuzz-infra/scripts/ph_s032g_build_seller_api.sh` |
| Deployment (tag à finaliser après build) | `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml` (image: ...v1.8.3-ph-s03.2+REPLACE_AFTER_BUILD) |
| Rapport | `keybuzz-infra/docs/PH-S03.2G-SELLERAPI-ROUTES-FIX-REPORT.md` |

**Aucune action manuelle Ludovic. DEV only. GitOps only. Aucun secret en clair.**
