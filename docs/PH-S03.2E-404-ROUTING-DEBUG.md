# PH-S03.2E — Debug 404 « Not Found » sur Tester la connexion FTP (seller-dev)

**Date :** 2026-01-30  
**Scope :** ROUTING ONLY — URL, prefix, ingress, service, version. Aucune modif Vault/DB (sauf lecture version).  
**Objectif :** Identifier la cause exacte du 404 et fournir la correction minimale (GitOps only).

---

## A) Preuve côté navigateur (source of truth)

**Procédure :** Ouvrir DevTools → Network sur seller-dev, cliquer « Tester la connexion », relever l’appel.

**URL exacte appelée (déduite du code client) :**
```
https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/<sourceId>/ftp/test-connection
```
- **Méthode :** POST  
- **Status code observé :** 404  
- **Response body :** « Not Found » (ou équivalent)

**Type d’URL :** `/api/seller/...` (proxy same-origin) puis sous-chemin `api/catalog-sources/<id>/ftp/test-connection`. L’URL est donc **sous le préfixe proxy** `/api/seller`, pas directement `/api/catalog-sources/...`.

**Preuve à coller (à remplacer par capture réelle masquée) :**
```
Request URL: https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/<uuid>/ftp/test-connection
Request Method: POST
Status Code: 404 Not Found
Response (extrait): {"detail":"Not Found"} ou body texte "Not Found"
```

**Note :** Si le body est `{"detail":"Catalog source not found"}`, la route **existe** et le 404 vient de l’API (source_id invalide ou tenant incorrect), pas du routing — voir section G.

---

## B) Routing front (seller-client)

**Fichier / ligne :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/FtpConnection.tsx` (l. 209–228).

**Appel :**
```ts
const result = await api.post<...>(`/api/catalog-sources/${sourceId}/ftp/test-connection`, body);
```

**Base path :** `src/lib/config.ts` — `apiProxyPrefix: '/api/seller'`.  
**Construction URL :** `src/lib/api.ts` — en navigateur `path = config.apiProxyPrefix + endpoint` → `/api/seller` + `/api/catalog-sources/${sourceId}/ftp/test-connection` = **`/api/seller/api/catalog-sources/<id>/ftp/test-connection`**.

**Preuve (extrait code, sans secrets) :**
```ts
// config.ts
apiProxyPrefix: '/api/seller',

// api.ts (navigateur)
const path = config.apiProxyPrefix + endpoint;
const url = window.location.origin + path;
// → https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/<id>/ftp/test-connection
```

**Conclusion :** L’URL côté client est cohérente avec le proxy Next.js `/api/seller/[...path]`.

---

## C) seller-api expose bien la route

**Route FastAPI :** `keybuzz-seller/seller-api/src/routes/ftp.py`  
- Router : `prefix="/catalog-sources/{source_id}/ftp"` (l. 34)  
- Endpoint : `@router.post("/test-connection", ...)` (l. 369)  
- Montage : `main.py` — `app.include_router(ftp_router, prefix="/api")`  

**Chemin complet exposé :** `POST /api/catalog-sources/{source_id}/ftp/test-connection`.

**Vérifications depuis le bastion (read-only) :**
```bash
# OpenAPI (si host séparé seller-api-dev)
curl -sI https://seller-api-dev.keybuzz.io/openapi.json

# Ou via proxy (seller-dev)
curl -sI https://seller-dev.keybuzz.io/api/seller/openapi.json

# Chercher la route dans openapi.json (masqué)
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -o '"\/api\/catalog-sources\/[^"]*\/ftp\/test-connection"'
```

**Preuve à coller (extrait OpenAPI masqué) :**
```
Dans openapi.json, paths doit contenir :
"/api/catalog-sources/{source_id}/ftp/test-connection": { "post": { ... } }
```
Si cette entrée est **absente**, l’image déployée est probablement **antérieure à PH-S03.2** (route non incluse) → voir E et G.

---

## D) Ingress (seller-dev)

**Manifests actuels :**

| Host | Backend | Path |
|------|---------|------|
| seller-dev.keybuzz.io | service seller-client, port 3001 | / (Prefix) |
| seller-api-dev.keybuzz.io | service seller-api, port 3002 | / (Prefix) |

**Flux :**
1. Le navigateur appelle **seller-dev.keybuzz.io** → Ingress → **seller-client** (Next.js).
2. Next.js route **/api/seller/[...path]** → `app/api/seller/[...path]/route.ts` (proxy).
3. Le proxy envoie la requête à **SELLER_API_URL** (`https://seller-api-dev.keybuzz.io`) avec le path `pathSegments.join('/')` = `api/catalog-sources/<id>/ftp/test-connection`.
4. **seller-api-dev.keybuzz.io** → Ingress → **seller-api** (FastAPI) reçoit donc `POST /api/catalog-sources/<id>/ftp/test-connection`.

**Preuve (extrait manifests) :**
```yaml
# ingress-client.yaml (keybuzz-seller-dev)
rules:
  - host: seller-dev.keybuzz.io
    http:
      paths:
        - path: /
          pathType: Prefix
          backend: service/seller-client, port 3001

# ingress-api.yaml (keybuzz-seller-dev)
rules:
  - host: seller-api-dev.keybuzz.io
    http:
      paths:
        - path: /
          pathType: Prefix
          backend: service/seller-api, port 3002
```
Aucun rewrite de path : le proxy Next.js fait le relais avec le bon path. **Aucune modification d’ingress nécessaire** pour ce flux.

---

## E) Version réelle déployée (seller-api)

**Commande (depuis bastion) :**
```bash
kubectl get deploy seller-api -n keybuzz-seller-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

**Image déclarée dans GitOps (deployment-api.yaml) :**
```yaml
image: ghcr.io/keybuzzio/seller-api:v1.8.1-ph-s02.2
```

**Preuve à coller (à remplacer par sortie réelle) :**
```
Image: ghcr.io/keybuzzio/seller-api:v1.8.1-ph-s02.2
```
**Interprétation :** Le tag `v1.8.1-ph-s02.2` correspond à la phase **PH-S02.2**. La route `POST /api/catalog-sources/{source_id}/ftp/test-connection` (PH-S03.2) est dans le **code** actuel du repo mais peut **ne pas être dans cette image** si le build d’image n’a pas été refait après merge PH-S03.2. Si l’OpenAPI (section C) ne liste pas cette route, la **cause du 404 est l’image trop ancienne**.

---

## F) Reproduire le 404 hors UI (curl)

**En appelant exactement l’URL de A (sans corps sensible) :**
```bash
# Remplacer <sourceId> par un UUID valide ou factice pour test routing
curl -i -X POST 'https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection' \
  -H 'Content-Type: application/json' \
  -d '{"mode":"temp_password","host":"ftp.example.com","port":21,"username":"u","password":"p"}'
```

**Interprétation :**
- **404** → routing cassé (route absente côté API ou non atteinte).
- **401** → route atteinte, auth manquante (attendu sans cookies/headers).
- **422** → route atteinte, validation (attendu si body incomplet).
- **400** → route atteinte, logique métier (ex. host requis).

**Preuve à coller (sortie masquée) :**
```
HTTP/1.1 404 Not Found
...
{"detail":"Not Found"}
```
Si on obtient **401/422/400** au lieu de 404, le routing est **correct** ; le problème restant est auth / body / source.

---

## G) Correction minimale (GitOps only)

**Synthèse des causes possibles :**

| Cause | Diagnostic | Correction |
|-------|------------|------------|
| **1) URL UI incorrecte** | L’URL appelée n’est pas sous `/api/seller/...`. | Ajuster le base path ou l’endpoint dans seller-client (config ou FtpConnection). |
| **2) Ingress ne route pas /api/seller** | Requête vers seller-dev ne va pas au client ou path coupé. | Adapter règles Ingress ou path du proxy (section D : actuellement correct). |
| **3) Image seller-api trop ancienne** | OpenAPI sans `/api/catalog-sources/{source_id}/ftp/test-connection` ; image tag PH-S02.2. | **Bump image tag** dans `deployment-api.yaml` vers une image contenant PH-S03.2 (ex. `v1.8.2-ph-s03.2` ou tag commit post-PH-S03.2) puis commit/push et resync ArgoCD. |
| **4) Route sous un autre préfixe** | API expose la route sous un path différent. | Aligner proxy (route.ts) et/ou client sur le préfixe réel de l’API. |
| **5) 404 « Catalog source not found »** | Body de réponse `{"detail":"Catalog source not found"}`. | La route **existe** ; le 404 est métier (source_id ou X-Tenant-Id). Vérifier que la source existe et que les headers auth/tenant sont envoyés. Pas de changement routing. |

**Correction recommandée si cause = image (3) :**

- Fichier : `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml`  
- Modifier l’image pour utiliser un tag **incluant les routes PH-S03.2** (build après merge de `ftp.py` avec `test-connection`).  
- Exemple (à adapter au tag réel du registry) :
```yaml
# Remplacer
image: ghcr.io/keybuzzio/seller-api:v1.8.1-ph-s02.2
# par (exemple)
image: ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2
```
- Commit + push, sync ArgoCD. Aucun `kubectl apply` manuel.
- **Prérequis :** L’image `ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2` doit exister (build + push depuis keybuzz-seller/seller-api avec le code PH-S03.2). Si elle n’existe pas encore, la créer avant ou conserver l’ancien tag jusqu’au prochain build.

**Validation :** Après correction, le bouton « Tester la connexion » ne doit plus renvoyer **404**. En cas de Vault/secret_ref manquants, on doit obtenir **400 / 401 / 422**, pas 404.

---

## Récapitulatif

| # | Catégorie | Statut |
|---|-----------|--------|
| A | URL navigateur | `/api/seller/api/catalog-sources/<id>/ftp/test-connection` (POST) |
| B | Base path front | `/api/seller` + endpoint → cohérent |
| C | Route seller-api | `POST /api/catalog-sources/{source_id}/ftp/test-connection` (code) ; à confirmer dans OpenAPI déployé |
| D | Ingress | seller-dev → client ; seller-api-dev → api ; pas de changement requis |
| E | Image déployée | v1.8.1-ph-s02.2 — risque que la route PH-S03.2 soit absente |
| F | curl | À exécuter pour distinguer 404 routing vs 401/422 |
| G | Correction | Si route absente dans l’image : bump image tag (GitOps) ; si 404 = « Catalog source not found » : vérifier source_id / tenant |

---

**Aucune action PROD. Aucun secret en clair. Pas de kubectl apply. Pas de modification SSH. DEV uniquement.**
