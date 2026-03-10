# PH-S03.2F — Correction 404 « Tester la connexion » FTP (seller-dev)

**Date :** 2026-01-30  
**Scope :** Distinguer 404 métier vs routing ; prouver version runtime et présence de route ; corriger (GitOps only). DEV uniquement.

---

## Diagnostic principal (preuve C)

**Vérification OpenAPI en production (réelle) :**

- `GET https://seller-api-dev.keybuzz.io/openapi.json` → 200, body récupéré.
- `GET https://seller-dev.keybuzz.io/api/seller/openapi.json` → 200 (proxy vers même API).

**Recherche dans `paths` :** aucune clé ne contient `ftp` ni `test-connection`.

- Présent dans OpenAPI déployé : `/api/catalog-sources`, `/api/catalog-sources/{source_id}` (get, patch, delete), `/api/secret-refs`, etc.
- **Absent :** `/api/catalog-sources/{source_id}/ftp/*` (donc pas de `test-connection`, `browse`, `connection`, etc.).

**Conclusion :** L’image actuellement servie par seller-api **ne contient pas les routes PH-S03.2 (FTP)**. Le 404 est un **404 routing** (route non enregistrée dans FastAPI), pas un 404 métier « Catalog source not found ».

---

## A) Preuve « réponse 404 »

**Procédure :** Sur seller-dev, ouvrir DevTools → Network, cliquer « Tester la connexion », sélectionner la requête POST vers `.../ftp/test-connection`.

**À capturer :**
- Status : **404**
- Response body brut (masqué) : typiquement `{"detail":"Not Found"}` (réponse par défaut FastAPI pour chemin non enregistré).

**Classification :**
- **404 métier** si body = `{"detail":"Catalog source not found"}` (alors la route existerait et `get_source_or_404` aurait levé).
- **404 routing** si body = `{"detail":"Not Found"}` ou équivalent générique.

**Preuve (constat réel) :** L’OpenAPI en production ne liste pas la route FTP → la route n’est pas enregistrée → le 404 ne peut pas provenir de `get_source_or_404`. Donc **404 routing**.

**Extrait à coller (après capture navigateur) :**
```
Status: 404
Response body: {"detail":"Not Found"}
→ Classé: 404 routing (route absente de l’image déployée).
```

---

## B) Preuve version runtime (seller-api)

**Commandes (depuis bastion, read-only) :**
```bash
kubectl get deploy seller-api -n keybuzz-seller-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].spec.containers[0].image}'
kubectl get pod -l app=seller-api -n keybuzz-seller-dev -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
kubectl get replicaset -n keybuzz-seller-dev -l app=seller-api --sort-by=.metadata.creationTimestamp | tail -5
```

**État GitOps (deployment-api.yaml) :**
- Image déclarée : `ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2` (PH-S03.2E).

**Preuve à coller (à remplacer par sortie réelle) :**
```
Image deploy spec: ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2
Image pod (réel): <coller sortie jsonpath>
ImageID: <coller si différent du tag>
ReplicaSet récent: <nom + date>
```
Si le pod tourne encore avec un tag **v1.8.1-ph-s02.2** (ou sans ftp dans OpenAPI), alors soit l’image **v1.8.2-ph-s03.2 n’existe pas** (ImagePullBackOff, ancien pod conservé), soit le rollout n’a pas été déclenché.

---

## C) Preuve présence de la route dans seller-api (OpenAPI)

**Vérification effectuée (réelle) :**
```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -o '"/api/[^"]*"' | sort -u
```
ou
```bash
curl -s https://seller-dev.keybuzz.io/api/seller/openapi.json | grep -n "ftp\|test-connection"
```

**Résultat constaté :** Aucune occurrence de `ftp` ni `test-connection` dans les clés de `paths` de l’OpenAPI servi en production.

**Preuve (extrait masqué) :**
```
Paths contenant "catalog-sources" dans OpenAPI live:
  "/api/catalog-sources"
  "/api/catalog-sources/{source_id}"
Aucun path "/api/catalog-sources/{source_id}/ftp/..." ni "test-connection".
→ La route POST /api/catalog-sources/{source_id}/ftp/test-connection n’est pas exposée par l’image actuelle.
```

---

## D) Si l’image v1.8.2-ph-s03.2 n’existe pas

**Vérification (read-only si possible) :**
- Depuis le bastion : `kubectl describe pod -l app=seller-api -n keybuzz-seller-dev` → Events (Failed to pull image?, ImagePullBackOff).
- Si accès GHCR : vérifier présence du tag `ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2`.

**Si le tag est absent :**
1. Builder l’image depuis le dépôt **keybuzz-seller** (seller-api avec le code PH-S03.2 : `routes/ftp.py`, `main.py` incluant `ftp_router` et `ftp_direct_router`).
2. Pousser vers `ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2` (ou tag convenu).
3. Aucun `kubectl apply` : la spec du deployment est déjà à jour dans GitOps (PH-S03.2E) ; après push d’image, **resync ArgoCD** ou attendre le prochain sync pour que le déploiement tire la nouvelle image.

**Alternative si le tag v1.8.2-ph-s03.2 ne peut pas être créé immédiatement :** Utiliser un tag existant qui contient déjà les routes FTP (si un build post-PH-S03.2 a été poussé sous un autre tag), et aligner `deployment-api.yaml` sur ce tag. La preuve que l’image contient les routes est la présence de `/api/catalog-sources/{source_id}/ftp/test-connection` dans l’OpenAPI servi après déploiement.

**Procédure type (CE / pipeline, sans action manuelle Ludovic) :**
- Utiliser le pipeline de build d’images existant (CI) pour keybuzz-seller/seller-api, en ciblant le commit contenant les routes FTP et en taguant l’image (ex. `v1.8.2-ph-s03.2`).
- Si aucun pipeline n’existe : documenter la commande de build (Dockerfile présent dans keybuzz-seller/seller-api) et le push vers ghcr.io ; exécution par CE ou CI.

---

## E) Si 404 métier (« Catalog source not found »)

À utiliser **une fois la route présente** (image PH-S03.2 déployée). Si le 404 persiste avec body `{"detail":"Catalog source not found"}` :

**1) Vérifier que la source existe pour le tenant :**
```sql
-- Depuis psql read-only (pod ou bastion)
SELECT id, "tenantId" FROM seller.catalog_sources WHERE id = '<sourceId>';
```
Le `tenantId` doit correspondre au tenant de la session.

**2) Comment seller-api obtient le tenant_id :**
- **Auth :** Cookie de session KeyBuzz → introspection `KEYBUZZ_CLIENT_URL/api/auth/session` → email (pas de tenant dans la session côté code actuel).
- **Tenant :** Uniquement via le header **X-Tenant-Id** (middleware `get_tenant_from_header`). Ce header est **obligatoire** pour les routes tenant-scoped (`require_auth_with_tenant`).
- **seller-client :** `useAuth()` récupère `tenantId` (contexte tenant / me), puis `setAuthHeaders(email, tenantId)` envoie `X-Tenant-Id` sur chaque appel `api.*`.

**3) Vérifications :**
- Le `sourceId` envoyé par l’UI est bien l’id de la source affichée (celle créée dans le tenant courant).
- Le header `X-Tenant-Id` est bien envoyé et égal au `tenantId` de la source en base.
- Log safe côté seller-api (sans cookie) : logger `tenant_id` résolu et `user.email` en début de route pour tracer les appels (optionnel, pour debug).

**4) Causes possibles et correctifs :**
- **X-Tenant-Id manquant** → 400 « X-Tenant-Id header required » (pas 404). Si 404, la route est atteinte et `get_source_or_404` a levé : source inexistante ou mauvais tenant.
- **Source créée dans un autre tenant** → s’assurer que l’UI utilise le tenant sélectionné (contexte) et que la source a été créée dans ce tenant.
- **sourceId faux / stale** → s’assurer que l’état UI (source affichée / ouverte) correspond bien à l’id utilisé dans l’URL (`/api/catalog-sources/${sourceId}/ftp/test-connection`).

**Objectif final :** Une fois routing corrigé (image PH-S03.2), « Tester la connexion » doit renvoyer **400 / 401 / 422** (ex. credentials manquants, connexion durable non configurée), **jamais 404** tant que la route et la source existent.

---

## Correctif appliqué (résumé)

| Élément | Statut |
|--------|--------|
| **Cause du 404** | **Routing** : route FTP absente de l’OpenAPI déployé (image sans PH-S03.2). |
| **Correction GitOps** | Déjà faite en PH-S03.2E : `deployment-api.yaml` → image `v1.8.2-ph-s03.2`. |
| **Action requise** | S’assurer que l’image `ghcr.io/keybuzzio/seller-api:v1.8.2-ph-s03.2` existe (build + push si besoin), puis resync ArgoCD. Aucun changement de code ni d’ingress nécessaire. |
| **404 métier** | Procédure E documentée pour le cas où, après déploiement de l’image PH-S03.2, le body serait « Catalog source not found ». |

---

## Preuve finale attendue

Après déploiement d’une image contenant les routes PH-S03.2 :

- **OpenAPI** : présence de `/api/catalog-sources/{source_id}/ftp/test-connection` (et autres routes ftp).
- **Bouton « Tester la connexion »** : ne renvoie plus **404**. Réponses attendues selon le cas :
  - **401** si session invalide ou absente ;
  - **400** si X-Tenant-Id manquant ou « Connexion durable non configurée » (mode vault_secret_ref) ;
  - **422** si body invalide (ex. mode temp_password sans host) ;
  - **200** si le test FTP réussit.

**Aucune action PROD. Aucun secret en clair. Vérifications en read-only. DEV uniquement.**
