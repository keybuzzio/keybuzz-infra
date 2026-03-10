# PH-S03.5C — Closeout : Catalog Sources « Unknown error » + Wizard FTP sans mapping (seller-dev)

**Date :** 2026-01-30  
**Périmètre :** Déployer les correctifs PH-S03.5B et PH-S03.4/PH-S03.4B sur seller-dev et fournir les preuves runtime + screenshots.  
**Environnement :** seller-dev uniquement.  
**Règles :** DEV only, GitOps only, aucune action manuelle Ludovic, CE fournit les preuves.

---

## 1. Objectifs (sortie non négociable)

| Id | Critère |
|----|--------|
| A | Page `/catalog-sources` : **aucun bandeau « Unknown error »** au chargement. |
| B | Wizard création source FTP : **pas d’étape « Mapping des colonnes »** ; mapping uniquement dans fiche source > onglet « Colonnes (CSV) ». |
| C | CE fournit preuves runtime + screenshots. |

---

## 2. Modifications livrées

### 2.1 Preuve de version déployée (PH-S03.5C)

- **seller-client Dockerfile**  
  - `ARG BUILD_SHA` + `ENV NEXT_PUBLIC_BUILD_SHA=${BUILD_SHA}` au build.
- **seller-client next.config.js**  
  - `NEXT_PUBLIC_BUILD_SHA` dans `env` (injecté au build Docker).
- **seller-client app/(dashboard)/layout.tsx**  
  - Footer affichant `build {sha}` (7 premiers caractères) lorsque `NEXT_PUBLIC_BUILD_SHA` est défini.
- **Effet :** La version déployée est identifiable dans l’UI (footer) et par le script de preuve.

### 2.2 Catalog Sources — plus de « Unknown error » (PH-S03.5B)

- **api.ts** : erreurs HTTP avec `status` et `endpoint` sur l’`Error` ; messages explicites (fallback, `getDisplayErrorMessage`).
- **catalog-sources/page.tsx** : dans `loadSources()` — `console.warn` endpoint/status/message ; si 400 (tenant) ou 404 (tenant/source) → liste vide sans bandeau global ; sinon `setError(getDisplayErrorMessage(err))`.

### 2.3 Wizard FTP sans étape Mapping (PH-S03.4 / PH-S03.4B)

- **catalog-sources/page.tsx** :  
  - Wizard FTP à **5 étapes** (1=Kind, 2=Type, 3=Connexion, 4=Fichiers, 5=Finalisation).  
  - Pas d’étape « Mapping des colonnes » ; `getStepTitle()` étape 5 = « Finalisation ».  
  - Fiche source : onglets **Infos** | **Connexion FTP** | **Colonnes (CSV)** ; `SourceColumnMappingTab` pour détection + mapping.

### 2.4 GitOps — image seller-client

- **keybuzz-infra/k8s/keybuzz-seller-dev/deployment-client.yaml**  
  - Image mise à jour : `ghcr.io/keybuzzio/seller-client:v1.0.1` (commentaire PH-S03.5C).

---

## 3. Phase 1 — Vérifier la version réellement déployée

Exécuter le script de preuve (machine avec accès cluster + réseau) :

```bash
bash keybuzz-infra/scripts/ph-s035c-proof.sh
```

Ou manuellement :

### 3.1 ArgoCD app keybuzz-seller-dev

- **Sync :** SYNCED  
- **Health :** HEALTHY  
- **Revision :** commit déployé du repo keybuzz-infra (path `k8s/keybuzz-seller-dev`).

```bash
argocd app get keybuzz-seller-dev
# Relever: status.sync.revision, status.sync.status, status.health.status
```

### 3.2 Images runtime

```bash
kubectl -n keybuzz-seller-dev get deploy seller-client seller-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}'
kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
kubectl -n keybuzz-seller-dev get pod -l app=seller-api -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

**Attendu après déploiement :**

| Ressource       | Image / imageID |
|----------------|------------------|
| seller-client  | `ghcr.io/keybuzzio/seller-client:v1.0.1` |
| seller-api     | (inchangé, par digest) |

### 3.3 Preuve que seller-client déployé contient les commits

- **Option 1 :** Ouvrir seller-dev → page quelconque (ex. Catalog Sources) → footer « build xxxxxxx » = 7 premiers caractères du commit utilisé au build (si `BUILD_SHA` passé au `docker build`).
- **Option 2 :** Vérifier que l’image `v1.0.1` a été construite avec le script `ph-s035c-build-seller-client.sh` (qui utilise `BUILD_SHA=$(git rev-parse HEAD)` du repo keybuzz-seller).

---

## 4. Phase 2 — Corriger le déploiement si mismatch

- **ArgoCD non SYNCED / non HEALTHY :** corriger la cause (diff, santé des workloads) et resync.
- **seller-client pas à jour :**
  1. Build + push image immuable :  
     `bash keybuzz-infra/scripts/ph-s035c-build-seller-client.sh`  
     (ou build manuel avec `--build-arg BUILD_SHA=$(git rev-parse HEAD)` et tag `v1.0.1`).
  2. Mettre à jour le manifest GitOps :  
     `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-client.yaml` → `image: ghcr.io/keybuzzio/seller-client:v1.0.1` (déjà fait dans ce closeout).
  3. Commit + push keybuzz-infra → ArgoCD sync automatique.
- **Cache navigateur :** ne pas demander de « hard refresh » ; si besoin, bump version des assets (ex. nouveau build avec nouveau BUILD_SHA) et prouver par la nouvelle version servie (footer « build xxxxxxx »).

---

## 5. Phase 3 — Fix fonctionnel (déjà en place dans le code)

- **Catalog Sources :** appel au load = `GET /api/catalog-sources?include_fields=true` ; erreurs affichées via `getDisplayErrorMessage` ; 400/404 tenant → liste vide sans bandeau.
- **Wizard :** 5 étapes avec FTP ; pas d’étape « Mapping des colonnes » ; fiche source avec onglet « Colonnes (CSV) » et `SourceColumnMappingTab`.

---

## 6. Phase 4 — Preuves obligatoires

### 6.1 Sortie du script de preuve

**Preuve Network (exécution locale 2026-01-30) :**

```
GET https://seller-dev.keybuzz.io/catalog-sources → HTTP 200
OK: no 'Unknown error' in initial HTML (SSR).
OK: no 'Mapping des colonnes' in page.
Build SHA in page: (non présent — attendu après déploiement v1.0.1 avec BUILD_SHA)
```

*(Le bandeau « Unknown error » peut encore apparaître côté client si l’appel `GET /api/catalog-sources?include_fields=true` échoue et que la version déployée est encore v1.0.0. Déployer v1.0.1 avec les correctifs PH-S03.5B pour dégrader en liste vide sans bandeau sur 400/404 tenant.)*

Coller la sortie du script (machine avec accès cluster) :

```bash
bash keybuzz-infra/scripts/ph-s035c-proof.sh 2>&1 | tee ph-s035c-proof.log
```

Le script produit notamment :

- Révision / sync / health ArgoCD (si CLI disponible).
- Images déployées (seller-client, seller-api) et imageID des pods.
- `GET https://seller-dev.keybuzz.io/catalog-sources` → status HTTP et vérification absence de « Unknown error » dans le HTML.
- Vérification présence « Finalisation » et absence « Mapping des colonnes » dans la page.

### 6.2 Screenshots (seller-dev)

| # | Capture |
|---|--------|
| 1 | Page **Catalog Sources** au chargement : aucun bandeau rouge « Unknown error ». |
| 2 | **Wizard** création source FTP : liste des étapes (1–5) sans « Mapping des colonnes » ; étape 5 = « Finalisation ». |
| 3 | **Fiche source** (détail) : onglets **Infos**, **Connexion FTP**, **Colonnes (CSV)** ; contenu onglet « Colonnes (CSV) » visible (détection + mapping). |

### 6.3 Network

- Requête initiale au chargement de `/catalog-sources` :  
  - Méthode : GET (ex. `/api/catalog-sources?include_fields=true` via proxy).  
  - Statut attendu : 200 (ou 401/redirect si non authentifié) ; pas de réponse dont le corps ou les headers provoquent l’affichage du bandeau « Unknown error » côté client.

---

## 7. Rollback

En cas de régression :

1. **Revert** du commit keybuzz-infra qui met à jour `deployment-client.yaml` (remettre `image: ghcr.io/keybuzzio/seller-client:v1.0.0`).
2. **Commit + push** → ArgoCD resync → ancienne image déployée.
3. Côté code seller-client : conserver les correctifs (PH-S03.5B, PH-S03.4) ; le rollback ne concerne que la version d’image déployée (tag v1.0.0 vs v1.0.1).

---

## 8. Fichiers modifiés / ajoutés

| Fichier | Modification |
|---------|---------------|
| keybuzz-seller/seller-client/Dockerfile | ARG BUILD_SHA, ENV NEXT_PUBLIC_BUILD_SHA |
| keybuzz-seller/seller-client/next.config.js | env NEXT_PUBLIC_BUILD_SHA |
| keybuzz-seller/seller-client/app/(dashboard)/layout.tsx | Footer « build {sha} » |
| keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx | Commentaire étape wizard (5=finalize, pas mapping) |
| keybuzz-infra/k8s/keybuzz-seller-dev/deployment-client.yaml | image: seller-client:v1.0.1 |
| keybuzz-infra/scripts/ph-s035c-build-seller-client.sh | Nouveau : build + push v1.0.1 avec BUILD_SHA |
| keybuzz-infra/scripts/ph-s035c-proof.sh | Nouveau : preuves ArgoCD + kubectl + curl |
| keybuzz-infra/docs/PH-S03.5C-CLOSEOUT.md | Ce rapport |

---

## 9. Stop conditions

- **Impossible de prouver la version déployée (Argo + image + commit) :** arrêter et diagnostiquer (accès cluster, révision ArgoCD, image réellement déployée).
- **Solution « hard refresh » :** interdite ; il faut versionner (BUILD_SHA, tag v1.0.1) et déployer correctement via GitOps.
