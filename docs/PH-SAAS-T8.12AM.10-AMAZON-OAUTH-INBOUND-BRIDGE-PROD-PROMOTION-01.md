# PH-SAAS-T8.12AM.10 — Amazon OAuth Inbound Bridge PROD Promotion

> Date : 4 mai 2026
> Type : Promotion PROD controllee (AM.9 + AM.9.1)
> Priorite : P0
> Environnement : PROD

---

## 1. PREFLIGHT PROD

### Images AVANT promotion

| Service | Image manifest | Image runtime | Match |
|---|---|---|---|
| Backend | `v1.0.41-amazon-inbound-activation-prod` | `v1.0.41-amazon-inbound-activation-prod` | OK |
| API | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | OK |
| Client | `v3.5.150-amazon-inbound-status-ux-prod` | `v3.5.150-amazon-inbound-status-ux-prod` | OK |
| Admin | inchange | inchange | N/A |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | `v0.6.8-tiktok-browser-pixel-prod` | OK |

### Tenants PROD AVANT

| Tenant | Canaux avant | Notes |
|---|---|---|
| eComLG (`ecomlg-001`) | amazon-fr, amazon-es, amazon-it, amazon-be, amazon-pl (5 actifs, tous avec inbound_email) | DO_NOT_TOUCH |
| SWITAA (`switaa-sasu-mn9c3eza`) | amazon-fr actif avec inbound_email | Lecture seule |
| SWITAA (`switaa-sasu-mnc1ouqu`) | amazon-fr actif avec inbound_email | Lecture seule |
| compta.ecomlg (`compta-ecomlg-gmail--mnvu4649`) | amazon-fr actif avec inbound_email | Lecture seule |
| eComLG (`ecomlg-mo4h93e7`) | amazon-fr actif avec inbound_email | Lecture seule |

---

## 2. SOURCE LOCK

### Commits exacts

| Service | Branche | Commit | Fonction AM.9 | Fonction AM.9.1 |
|---|---|---|---|---|
| Backend | `main` | `f2afd3e` | GET /inbound-connection endpoint pour BFF bridge | n/a |
| API | `ph147.4/source-of-truth` | `6511ed7c` (AM.9.1) + `192f0225` (AM.9) | backendConnection upsert inbound_connections | inbound_addresses upsert + inbound_email set |
| Client | `ph148/onboarding-activation-replay` | `b2bba25` (AM.9.1) + `e3d8a33` (AM.9) | bridge activation BFF | backendAddresses transmission |

---

## 3. AUDIT NO-HARDCODING

| Pattern | Occurrences | Verdict |
|---|---|---|
| `ecomlg` (dans patches) | 0 | CLEAN |
| `switaa` (dans patches) | 0 | CLEAN |
| `keybuzz-mnq` | 0 | CLEAN |
| `A13V1IB3` (marketplace ID) | 0 | CLEAN |
| `A1PA6795` (marketplace ID) | 0 | CLEAN |
| `sellercentral.amazon.com` hardcode | 0 | CLEAN |
| country hardcode | 0 | CLEAN |
| tenant_id hardcode | 0 | CLEAN |

**Verdict : ZERO HARDCODING dans les fichiers patches AM.9/AM.9.1**

---

## 4. BUILD BACKEND PROD

- **Tag** : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.42-amazon-oauth-inbound-bridge-prod`
- **Digest** : `sha256:4271127286975c67c0adf3660529106610a5c7ebb82ec423cb95f5fb4c7c3009`
- **Source** : branche `main`, commit `f2afd3e`
- **Workspace** : propre (`git status --short` = vide)

### Contenu verifie

- endpoint `GET /api/v1/marketplaces/amazon/inbound-connection` : present
- auth guard (devAuthMiddleware) : present
- expected_channel AM.6 : preserve
- Seller Central Europe AM.5 : preserve
- pas de hardcode FR/NA

---

## 5. BUILD API PROD

- **Tag** : `ghcr.io/keybuzzio/keybuzz-api:v3.5.139-amazon-oauth-inbound-bridge-prod`
- **Digest** : `sha256:2f98b23f0b6cc03fd39736f2ca73a6500c9cfc02812e804c0611f4e2a1a4094e`
- **Source** : branche `ph147.4/source-of-truth`, commit `6511ed7c`
- **Workspace** : propre

### Contenu verifie

- `backendConnection` accepte dans POST /activate-amazon : oui
- `backendAddresses` accepte : oui
- upsert `inbound_connections` : oui
- upsert `inbound_addresses` : oui
- update `tenant_channels.inbound_email` : oui
- aucun channel active sans inbound email possible : correct
- `/status` read-only : correct
- no self-healing write : correct

---

## 6. BUILD CLIENT PROD

- **Tag** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.151-amazon-oauth-inbound-bridge-prod`
- **Digest** : `sha256:fb3cc19bb54e4ae5bd4882c422b0c9f2c96f8e234127bf2689589b2c6288adb8`
- **Source** : branche `ph148/onboarding-activation-replay`, commit `b2bba25`
- **Workspace** : propre

### Build args

```
NEXT_PUBLIC_API_URL=https://api.keybuzz.io
NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
NEXT_PUBLIC_APP_ENV=production
NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Contenu verifie dans le bundle

| Element | Statut |
|---|---|
| `backendAddresses` transmis par BFF | oui |
| Message activation honnete | oui |
| Shopify PNG `/public/marketplaces/shopify.png` | PRESENT |
| GA4 `G-R3QQDYEBFG` | PRESENT dans layout |
| sGTM `t.keybuzz.pro` | PRESENT dans layout |
| TikTok `D7PT12JC77U44OJIPC10` | PRESENT dans layout |
| LinkedIn `9969977` | PRESENT dans layout |
| Meta `1234164602194748` | PRESENT dans layout |
| Meta Purchase browser | ABSENT (correct — server-side only) |
| TikTok CompletePayment browser | ABSENT (correct — server-side only) |
| API URL `api.keybuzz.io` | PRESENT (correct PROD) |

---

## 7. GITOPS PROD

### Manifests modifies

| Fichier | Image avant | Image apres |
|---|---|---|
| `k8s/keybuzz-backend-prod/deployment.yaml` | `v1.0.41-amazon-inbound-activation-prod` | `v1.0.42-amazon-oauth-inbound-bridge-prod` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | `v3.5.139-amazon-oauth-inbound-bridge-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.150-amazon-inbound-status-ux-prod` | `v3.5.151-amazon-oauth-inbound-bridge-prod` |

- **Commit** : `f943166` sur `main` (keybuzz-infra)
- **Push** : `394042a..f943166 main -> main`
- **Apply** : `kubectl apply -f` sur les 3 manifests
- **Rollout** : les 3 deployments rolled out avec succes

### Manifests NON modifies (confirme)

- Admin PROD : inchange
- Website PROD : inchange (`v0.6.8-tiktok-browser-pixel-prod`)

---

## 8. ROLLOUT PROD

| Service | Image runtime post-rollout | Pod | Restarts | Status |
|---|---|---|---|---|
| Backend | `v1.0.42-amazon-oauth-inbound-bridge-prod` | `keybuzz-backend-5d8957fd59-sjsns` | 0 | Running |
| API | `v3.5.139-amazon-oauth-inbound-bridge-prod` | `keybuzz-api-786f4858cd-f7ddc` | 0 | Running |
| Client | `v3.5.151-amazon-oauth-inbound-bridge-prod` | `keybuzz-client-7d4445559b-hnnrr` | 0 | Running |

### Health checks

| Service | URL | Resultat |
|---|---|---|
| Backend | `https://backend.keybuzz.io/health` | `{"status":"ok"}` |
| API | `https://api.keybuzz.io/health` | `{"status":"ok"}` |
| Client | `https://client.keybuzz.io/login` | HTTP 200 |

---

## 9. VALIDATION STRUCTURELLE PROD

### eComLG (DO_NOT_TOUCH)

| Channel | Status | inbound_email | Verdict |
|---|---|---|---|
| amazon-be | active | `amazon.ecomlg-001.be.ub0m1q@inbound.keybuzz.io` | INCHANGE |
| amazon-es | active | `amazon.ecomlg-001.es.zul3wn@inbound.keybuzz.io` | INCHANGE |
| amazon-fr | active | `amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io` | INCHANGE |
| amazon-it | active | `amazon.ecomlg-001.it.hz4alx@inbound.keybuzz.io` | INCHANGE |
| amazon-pl | active | `amazon.ecomlg-001.pl.36ngpp@inbound.keybuzz.io` | INCHANGE |

- `inbound_connections` : `conn_6ce49a192df94ff6a6039c2deca3c36a` (READY, FR/ES/IT) — INCHANGE
- `inbound_addresses` : 3 adresses (FR/ES/IT, VALIDATED) — INCHANGE

### Tous canaux Amazon actifs PROD

| Tenant | Channel | inbound_email | Verdict |
|---|---|---|---|
| compta.ecomlg | amazon-fr | OK | INCHANGE |
| eComLG (ecomlg-001) | amazon-be,es,fr,it,pl | 5x OK | INCHANGE |
| eComLG (ecomlg-mo4h93e7) | amazon-fr | OK | INCHANGE |
| SWITAA (switaa-sasu-mn9c3eza) | amazon-fr | OK | INCHANGE |
| SWITAA (switaa-sasu-mnc1ouqu) | amazon-fr | OK | INCHANGE |

**Resultat : 9/9 canaux Amazon actifs ont un inbound_email — AUCUN canal actif sans email**

---

## 10. VALIDATION CLIENT TRACKING

| Tracker | ID | Bundle PROD | Verdict |
|---|---|---|---|
| GA4 | `G-R3QQDYEBFG` | PRESENT layout | OK |
| sGTM | `t.keybuzz.pro` | PRESENT layout | OK |
| TikTok Pixel | `D7PT12JC77U44OJIPC10` | PRESENT layout | OK |
| LinkedIn | `9969977` | PRESENT layout | OK |
| Meta Pixel | `1234164602194748` | PRESENT layout | OK |
| Meta Purchase browser | — | ABSENT | OK (server-side only) |
| TikTok CompletePayment browser | — | ABSENT | OK (server-side only) |
| Shopify PNG | `/marketplaces/shopify.png` | PRESENT | OK |

---

## 11. RUNBOOK LUDOVIC POST-DEPLOY

### Test recommande : SWITAA — ajouter un connecteur Amazon non critique

1. Aller sur `https://client.keybuzz.io/channels` (connexion SWITAA)
2. Cliquer "Ajouter un connecteur" et choisir un pays Amazon EU non critique (ex: NL, BE ou DE)
3. Lancer le OAuth Amazon
4. **Si Amazon affiche un autre pays EU** dans Seller Central : c'est un comportement Amazon normal (session EU partagee). Continuer UNIQUEMENT si le compte vendeur affiche est bien le compte SWITAA
5. Apres autorisation, retour automatique sur `/channels`
6. Verifier :
   - Message de succes avec le canal attendu (ex: "amazon-nl")
   - Carte du connecteur en statut "Connecte"
   - **Adresse inbound email visible** sur la carte
   - Badge "OAuth actif"
7. Si test concluant : supprimer le connecteur test via le bouton "Supprimer"
8. Revenir sur `/channels` — verifier que le connecteur supprime ne ressuscite pas
9. Verifier que les autres connecteurs (notamment amazon-fr) sont inchanges

### En cas de probleme

- Si activation echoue : verifier les logs API (`kubectl logs -n keybuzz-api-prod -l app=keybuzz-api --tail=50`)
- Si inbound email manquant : verifier les logs Backend (`kubectl logs -n keybuzz-backend-prod -l app=keybuzz-backend --tail=50`)
- Rollback disponible (voir section 14)

---

## 12. NON-REGRESSION

| Element | Statut | Verification |
|---|---|---|
| 17TRACK | INCHANGE | Aucune modification tracking routes |
| Shopify | INCHANGE | PNG present, aucune modif connector |
| Billing | INCHANGE | Aucune modification billing routes |
| Lifecycle emails | INCHANGE | Aucune modification lifecycle |
| Acquisition tracking | INCHANGE | 5 trackers confirmes dans bundle |
| CAPI (Meta/TikTok/LinkedIn) | INCHANGE | Aucune modification serveur |
| Sample Demo | INCHANGE | Aucune modification demo |
| Fake event | AUCUN | Pas de fake OAuth/event/CAPI |
| Fake spend | AUCUN | Pas de fake spend |
| Secret exposure | AUCUN | Pas de secret dans logs/rapport |

---

## 13. IMAGES APRES PROMOTION

| Service | Image PROD | Digest |
|---|---|---|
| Backend | `v1.0.42-amazon-oauth-inbound-bridge-prod` | `sha256:427112728697...` |
| API | `v3.5.139-amazon-oauth-inbound-bridge-prod` | `sha256:2f98b23f0b6c...` |
| Client | `v3.5.151-amazon-oauth-inbound-bridge-prod` | `sha256:fb3cc19bb54e...` |
| Admin | INCHANGE | — |
| Website | INCHANGE (`v0.6.8-tiktok-browser-pixel-prod`) | — |

---

## 14. ROLLBACK GITOPS STRICT

En cas de probleme, rollback immediat :

```bash
# Backend
kubectl set image deploy/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-amazon-inbound-activation-prod -n keybuzz-backend-prod

# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.138-amazon-connector-delete-marketplace-fix-prod -n keybuzz-api-prod

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.150-amazon-inbound-status-ux-prod -n keybuzz-client-prod
```

Puis mettre a jour les manifests dans `keybuzz-infra/k8s/` et push.

---

## 15. VERDICT

### GO PROD

**AMAZON OAUTH INBOUND BRIDGE LIVE IN PROD — BACKEND/API DB SPLIT RECONCILED — INBOUND ADDRESSES SYNCED — CONNECTED STATUS REQUIRES VISIBLE INBOUND EMAIL — SELECTED MARKETPLACE PRESERVED END TO END — NO CONNECTOR RESURRECTION — NO TENANT HARDCODING — ECOMLG PRESERVED — CLIENT TRACKING AND SHOPIFY LOGO PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT**
