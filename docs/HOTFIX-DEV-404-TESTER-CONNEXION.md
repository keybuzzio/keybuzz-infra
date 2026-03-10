# HOTFIX DEV — 404 « Tester la connexion » FTP

**Objectif :** Que l’appel atteigne le backend et retourne autre chose que 404 (400/401/422/200).  
**Scope :** DEV only (seller-dev), GitOps only, fix minimal (chemin/proxy uniquement).

---

## 1) Requête exacte du bouton « Tester la connexion »

**Fichier :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/FtpConnection.tsx`

- **Endpoint :** `POST /api/catalog-sources/${sourceId}/ftp/test-connection`
- **Base path (config) :** `/api/seller` → **URL finale :**  
  `https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/{sourceId}/ftp/test-connection`
- **Log temporaire (console) :** Au clic, la console affiche :  
  `[HOTFIX DEV] Tester la connexion — URL appelée (sans password): <url> | method: POST`

---

## 2) Preuve Network / curl

**À confirmer dans DevTools Network (ou via curl) :**

- **URL appelée :** `https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/<sourceId>/ftp/test-connection`
- **Méthode :** POST  
- **Status actuel :** 404  
- **Response body :** `{"detail":"Not Found"}` (ou équivalent)

**Reproduction curl (depuis bastion) :**
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection" \
  -H "Content-Type: application/json" -d '{}'
# → 404 tant que le backend ne expose pas la route
```

---

## 3) Ce que seller-api expose (code)

**Route attendue (code) :**  
`POST /api/catalog-sources/{source_id}/ftp/test-connection`  
(définie dans `keybuzz-seller/seller-api/src/routes/ftp.py`, montée avec préfixe `/api` dans `main.py`).

**Proxy Next.js :**  
`/api/seller/[...path]` → forward vers `SELLER_API_URL` + `path`  
→ requête reçue par seller-api : `POST /api/catalog-sources/{source_id}/ftp/test-connection`.  
Donc **prefix et proxy sont corrects** ; l’URL côté client et le forward sont alignés avec le code backend.

---

## 4) Cause du 404 et fix minimal

**Cause :** L’**image seller-api actuellement déployée** ne contient pas les routes FTP (PH-S03.2). L’OpenAPI live (`seller-api-dev.keybuzz.io/openapi.json`) ne contient pas `/api/catalog-sources/{source_id}/ftp/*`. Le 404 est renvoyé par le backend (route non enregistrée), pas par le proxy.

**Fix minimal (sans toucher Vault/DB/secret refs) :**

- **Côté client/proxy :** Aucune modification nécessaire (URL et proxy déjà corrects).  
- **Côté déploiement :** Déployer une **image seller-api** qui contient les routes PH-S03.2 :
  1. Build + push : exécuter `keybuzz-infra/scripts/ph_s032g_build_seller_api.sh` (tag immuable `v1.8.3-ph-s03.2+<shortsha>`).
  2. Mettre à jour `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml` : remplacer `REPLACE_AFTER_BUILD` par le short SHA affiché (ou utiliser l’image par digest).
  3. Commit + push keybuzz-infra, puis **ArgoCD sync** (namespace keybuzz-seller-dev).

---

## 5) Validation

- **Avant :** Clic « Tester la connexion » → 404, body `{"detail":"Not Found"}`.
- **Après (image avec routes déployée) :**
  - Clic « Tester la connexion » → **plus de 404**.
  - Creds faux / session invalide → **400 ou 401** (OK).
  - Creds bons → **200** (OK).

**Preuve à fournir :**  
Capture Network (ou curl) : URL + status **avant** (404) et **après** (400/401/200), + commit + tag image + Argo sync.

---

## 6) Récap

| Élément              | Statut |
|----------------------|--------|
| URL appelée          | `https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/{id}/ftp/test-connection` |
| Proxy                | Forward correct vers seller-api avec path `/api/catalog-sources/{id}/ftp/test-connection` |
| Backend (code)       | Route exposée dans le code PH-S03.2 |
| Backend (image live) | Route **absente** de l’image déployée → 404 |
| Fix                  | Déployer une image seller-api contenant les routes PH-S03.2 (build + deployment + Argo sync) |

Pas de changement SSH, pas de refactor, pas de Vault/DB/secret refs. Fix limité au chemin/proxy (déjà correct) + déploiement de la bonne image.
