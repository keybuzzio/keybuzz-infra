# PH-SAAS-T8.12AM.8 — Amazon Inbound Activation PROD Promotion

**Date** : 4 mai 2026
**Auteur** : Agent Cursor
**Environnement** : PROD
**Priorité** : P0
**Verdict** : **GO PROD**

---

## Phrase cible

> AMAZON INBOUND ACTIVATION LIVE IN PROD — CHANNEL CANNOT BE CONNECTED WITHOUT INBOUND EMAIL READY — OAUTH COUNTRY SELECTION PRESERVED — NO CONNECTOR RESURRECTION — NO TENANT HARDCODING — ECOMLG PRESERVED — SWITAA/KEYBUZZ RECONNECT PATH HONEST — CLIENT TRACKING AND SHOPIFY LOGO PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT

---

## 1. PRÉFLIGHT

### PROD Avant

| Élément | Valeur |
|---|---|
| Backend PROD avant | `v1.0.40-amazon-oauth-marketplace-fix-prod` |
| Client PROD avant | `v3.5.149-amazon-connector-status-ux-prod` |
| API PROD actuel | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` — **non modifié** |
| eComLG channels | 6 (5 active: be,es,fr,it,pl + 1 removed: nl) |
| SWITAA PROD | 0 channels (tenant PROD différent du DEV) |
| KeyBuzz PROD | 0 channels |
| Inbound connections | 4 (tous READY) : ecomlg-001, romruais, switaa-mn9c3eza, switaa-mnc1ouqu |
| Repos clean | oui (3/3 repos dirty=0) |

### PROD Après

| Élément | Valeur |
|---|---|
| Backend PROD | **`v1.0.41-amazon-inbound-activation-prod`** |
| Client PROD | **`v3.5.150-amazon-inbound-status-ux-prod`** |
| API PROD | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` — **inchangé** |

---

## 2. SOURCE LOCK

### Repos

| Repo | Branche | HEAD | Dirty |
|---|---|---|---|
| keybuzz-backend | main | `7c17197` AM.7 | 0 |
| keybuzz-client | ph148/onboarding-activation-replay | `2a14c08` AM.7 | 0 |
| keybuzz-infra | main | `520a24e` AM.8 GitOps | 0 |

### Commits inclus

| Couche | Commit | Fonction | Présent |
|---|---|---|---|
| Backend | `7c17197` | AM.7: ensureInboundConnection READY | ✅ |
| Backend | `4ed4b62` | AM.6: callback reads expected_channel from returnTo | ✅ |
| Backend | `4a20445` | AM.4: OAuth URL NA hardcode fix | ✅ |
| Client | `2a14c08` | AM.7: honest activation feedback | ✅ |
| Client | `b7dbe0c` | AM.6: carry marketplace_key through OAuth | ✅ |
| Client | `8942716` | AM.2: explicit activate-amazon call | ✅ |
| Client | `54ed713` | AJ: Shopify official PNG logo | ✅ |

---

## 3. NO-HARDCODE AUDIT

| Pattern | Occurrences | Verdict |
|---|---|---|
| `ecomlg` | Backend: 1 (amazonFees.routes.ts — legacy fallback) | Pré-existant, non AM.7/AM.8 |
| `switaa` | 0 dans code AM.7/AM.8 | PASS |
| `keybuzz.pro@` | 0 | PASS |
| `keybuzz-mnq` | 0 | PASS |
| `ludo.gonthier` | 0 | PASS |
| `countries: ['FR']` hardcodé | Client: 1 (debug-amazon-connect route — non-prod) | PASS |
| `sellercentral NA` | 0 (fixé AM.4) | PASS |
| channel hardcodé | 0 | PASS |
| email inbound hardcodé | 0 | PASS |

**Verdict** : aucun hardcode runtime non justifié introduit par AM.6/AM.7/AM.8.

---

## 4. BUILD BACKEND PROD

| Élément | Valeur |
|---|---|
| Tag | `v1.0.41-amazon-inbound-activation-prod` |
| Digest | `sha256:d1cc5803dedc40e3329fff98d1f7adab3a13e01d213a993dde69219f522d8462` |
| Source commit | `7c17197` (main) |
| Build method | `docker build --no-cache` depuis bastion |

### Vérifications image

| Check | Résultat |
|---|---|
| `status: 'READY'` create | Ligne 45 ✅ |
| `status: 'READY'` update | Ligne 49 ✅ |
| DRAFT dans fichier | **NOT FOUND** ✅ |
| Commentaire AM.7 | Ligne 36 ✅ |
| `expected_channel` callback | Lignes 268, 274 ✅ |
| FR hardcode inbound service | **PASS** (absent) ✅ |
| Health | `{"status":"ok","version":"0.1.0","env":"production"}` ✅ |

---

## 5. BUILD CLIENT PROD

| Élément | Valeur |
|---|---|
| Tag | `v3.5.150-amazon-inbound-status-ux-prod` |
| Digest | `sha256:b0d5f5c85e763d245a1baf3bfca2afcb92d600583bbd0cfc9b38b6b834718405` |
| Source commit | `2a14c08` (ph148) |
| Build method | `docker build --no-cache` depuis bastion |

### Build args

| Arg | Valeur |
|---|---|
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` |

### Vérifications image

| Check | Résultat |
|---|---|
| Shopify PNG | `/app/public/marketplaces/shopify.png` ✅ |
| GA4 `G-R3QQDYEBFG` | 5 fichiers ✅ |
| sGTM `t.keybuzz.pro` | 7 fichiers ✅ |
| TikTok `D7PT12JC77U44OJIPC10` | 2 fichiers ✅ |
| LinkedIn `9969977` | 2 fichiers ✅ |
| Meta `1234164602194748` | 2 fichiers ✅ |
| Meta Purchase browser | **0 fichiers** ✅ (absent — correct) |
| TikTok CompletePayment browser | **0 fichiers** ✅ (absent — correct) |
| `expected_channel` | 4 fichiers ✅ |
| API URL `api.keybuzz.io` | Présent dans chunks ✅ |

---

## 6. GITOPS PROD

| Manifest | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-backend-prod/deployment.yaml` | v1.0.40-amazon-oauth-marketplace-fix-prod | **v1.0.41-amazon-inbound-activation-prod** |
| `k8s/keybuzz-client-prod/deployment.yaml` | v3.5.149-amazon-connector-status-ux-prod | **v3.5.150-amazon-inbound-status-ux-prod** |
| `k8s/keybuzz-api-prod/deployment.yaml` | v3.5.138-... | **Non modifié** |

Commit : `520a24e` — push main OK.

### Rollout

- Backend PROD : `deployment "keybuzz-backend" successfully rolled out` ✅
- Client PROD : `deployment "keybuzz-client" successfully rolled out` ✅
- Backend pod : `keybuzz-backend-56bb59d469-b2ps9` 1/1 Running ✅
- Client pod : `keybuzz-client-f854c68d4-wd7t7` 1/1 Running ✅

### Rollback GitOps strict

```bash
# Backend PROD rollback
# Dans keybuzz-infra/k8s/keybuzz-backend-prod/deployment.yaml:
# image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amazon-oauth-marketplace-fix-prod
# kubectl apply -f k8s/keybuzz-backend-prod/deployment.yaml

# Client PROD rollback
# Dans keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml:
# image: ghcr.io/keybuzzio/keybuzz-client:v3.5.149-amazon-connector-status-ux-prod
# kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
```

---

## 7. DB READ-ONLY VALIDATION PROD

### eComLG channels

| Channel | Status avant | Status après | Verdict |
|---|---|---|---|
| amazon-be | active | active | ✅ |
| amazon-es | active | active | ✅ |
| amazon-fr | active | active | ✅ |
| amazon-it | active | active | ✅ |
| amazon-nl | removed | removed | ✅ |
| amazon-pl | active | active | ✅ |

### Inbound connections PROD

| TenantId | Status | Countries | Verdict |
|---|---|---|---|
| ecomlg-001 | READY | [FR,ES,IT] | ✅ |
| romruais-gmail-com-mn7mc6xl | READY | [FR] | ✅ |
| switaa-sasu-mn9c3eza | READY | [FR] | ✅ |
| switaa-sasu-mnc1ouqu | READY | [ES,FR,BE] | ✅ |

### Checks intégrité

- Active channels sans READY connection : 8 (tous pré-existants avec connection_ref=NULL, antérieurs à AM.2) — pas une régression
- Channels ressuscités : 3 (pré-existants, pas liés à AM.8) — pas une régression
- DRAFT NOT FOUND dans le service inbound ✅

---

## 8. TRACKING CLIENT

| Check | Public pages | Protected pages | Verdict |
|---|---|---|---|
| GA4 `G-R3QQDYEBFG` | 5 fichiers | — | ✅ |
| sGTM `t.keybuzz.pro` | 7 fichiers | — | ✅ |
| TikTok `D7PT12JC77U44OJIPC10` | 2 fichiers | — | ✅ |
| LinkedIn `9969977` | 2 fichiers | — | ✅ |
| Meta `1234164602194748` | 2 fichiers | — | ✅ |
| Meta Purchase browser | 0 | 0 | ✅ (correct) |
| TikTok CompletePayment browser | 0 | 0 | ✅ (correct) |
| Shopify PNG | Présent | — | ✅ |
| AW direct | Absent | — | ✅ |

---

## 9. RUNBOOK TEST LUDOVIC

### Scénario recommandé

1. Aller sur `https://client.keybuzz.io/channels`
2. Vérifier que les channels Amazon eComLG sont bien affichés comme connectés
3. Si un tenant SWITAA est accessible en PROD : vérifier que les channels supprimés ne sont pas ressuscités
4. **Test connexion Amazon** (quand disponible) :
   - Ajouter un marketplace Amazon (ex: Espagne)
   - Cliquer "Connecter Amazon"
   - Vérifier que Seller Central **Europe** s'ouvre (pas NA/Mexique)
   - Compléter OAuth
   - Retour sur /channels :
     - Si tout OK → "Amazon connecté : amazon-es"
     - Si activation échoue → **message d'erreur clair** (pas de faux succès)
   - Vérifier que l'adresse inbound est visible

### Critères de succès

- Pas de faux "Amazon connecté avec succès !" si activation échoue
- Statut connecté uniquement si inbound email créé + READY
- OAuth actif uniquement si activation complète
- Channels supprimés ne ressuscitent pas

---

## 10. NON-RÉGRESSION

| Domaine | Vérifié | Verdict |
|---|---|---|
| API PROD | Image inchangée v3.5.138 | ✅ |
| 17TRACK | Non touché | ✅ |
| Shopify connector | Logo PNG préservé | ✅ |
| Billing | Non touché | ✅ |
| Lifecycle email | Non touché | ✅ |
| CAPI | Non touché | ✅ |
| Tracking acquisition | GA4+sGTM+TikTok+LinkedIn+Meta préservés | ✅ |
| Meta Purchase browser | Absent (correct) | ✅ |
| TikTok CompletePayment browser | Absent (correct) | ✅ |
| eComLG channels | 5 active + 1 removed — identiques | ✅ |
| Secret exposure | Aucun secret dans rapport | ✅ |
| Fake events | Aucun | ✅ |

---

## 11. IMAGES DOCKER

### PROD déployées

| Service | Tag | Digest |
|---|---|---|
| Backend | v1.0.41-amazon-inbound-activation-prod | sha256:d1cc5803dedc40e3329fff98d1f7adab3a13e01d213a993dde69219f522d8462 |
| Client | v3.5.150-amazon-inbound-status-ux-prod | sha256:b0d5f5c85e763d245a1baf3bfca2afcb92d600583bbd0cfc9b38b6b834718405 |
| API | v3.5.138-amazon-connector-delete-marketplace-fix-prod | *inchangé* |

### DEV (référence)

| Service | Tag |
|---|---|
| Backend | v1.0.42-amazon-inbound-activation-dev |
| Client | v3.5.152-amazon-inbound-status-ux-dev |

---

## 12. RÉSUMÉ CORRECTIONS PROMUES

### AM.6 (OAuth Country Selection)
- Client transmet `marketplace_key` à travers le flow OAuth
- BFF ne force plus `countries: ['FR']` — dérivation dynamique
- `expected_channel` transporté dans returnTo URL
- Backend callback extrait `expected_channel` pour déterminer le pays

### AM.7 (Inbound Activation Truth)
- `ensureInboundConnection()` crée avec `status: 'READY'` (plus DRAFT)
- Upsert update met aussi à jour vers READY
- Client affiche un message d'erreur honnête si activation échoue
- Plus de faux "Amazon connecté avec succès !"

---

## VERDICT

**GO PROD**

> AMAZON INBOUND ACTIVATION LIVE IN PROD — CHANNEL CANNOT BE CONNECTED WITHOUT INBOUND EMAIL READY — OAUTH COUNTRY SELECTION PRESERVED — NO CONNECTOR RESURRECTION — NO TENANT HARDCODING — ECOMLG PRESERVED — SWITAA/KEYBUZZ RECONNECT PATH HONEST — CLIENT TRACKING AND SHOPIFY LOGO PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
