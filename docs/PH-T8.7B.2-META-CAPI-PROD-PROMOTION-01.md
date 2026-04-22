# PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01.md`
> **Date** : 2026-04-22
> **Type** : Promotion PROD cumulative
> **Phases incluses** : PH-T8.7A + PH-T8.7B + PH-T8.7B.2
> **Environnement** : PROD

---

## 1. RÉSUMÉ EXÉCUTIF

Promotion en PROD de la chaîne complète :
- **PH-T8.7A** — Marketing Tenant Attribution Foundation (metrics scoped, platform-native destination types)
- **PH-T8.7B** — Meta CAPI Native Per-Tenant Connector (adapter, routing, CRUD, token masking)
- **PH-T8.7B.2** — Meta CAPI Test Endpoint Fix (PageView au lieu de ConnectionTest pour meta_capi)

PH-T8.7B.1 (validation réelle Meta) n'est pas déployée — elle sert de preuve de validation.

---

## 2. PRÉFLIGHT

| Point | Attendu | Constaté |
|-------|---------|----------|
| Branche API | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` |
| HEAD commit | `9b461717` | `9b461717` |
| Repo clean | OUI | OUI |
| Commit poussé sur origin | OUI | OUI |
| Image PROD actuelle | `v3.5.95-outbound-destinations-api-prod` | `v3.5.95-outbound-destinations-api-prod` |
| Image DEV validée | `v3.5.99-meta-capi-test-endpoint-fix-dev` | `v3.5.99-meta-capi-test-endpoint-fix-dev` |
| Digest DEV validé | `sha256:8ce4f07d...` | Confirmé |

---

## 3. VÉRIFICATION SOURCE

### T8.7A — Marketing Tenant Attribution Foundation

| Point | Résultat |
|-------|----------|
| `/metrics/overview` accepte `tenant_id` | OK — `request.query.tenant_id` (ligne 89) |
| Réponse inclut `scope` | OK — `scope = tenantFilter ? 'tenant' : 'global'` (ligne 90/289) |
| Réponse inclut `tenant_id` | OK — retourné dans la réponse JSON |
| `DESTINATION_TYPES` contient `meta_capi` | OK — `'meta_capi'` (ligne 10) |
| Colonne `platform_account_id` | OK — ALTER TABLE + CRUD (lignes 59, 158) |
| Colonne `platform_pixel_id` | OK — ALTER TABLE + CRUD (lignes 60, 161-166) |
| Colonne `platform_token_ref` | OK — ALTER TABLE + CRUD + masking (lignes 61, 102, 165) |
| Colonne `mapping_strategy` | OK — ALTER TABLE DEFAULT 'direct' (ligne 62) |

### T8.7B — Meta CAPI Native Per-Tenant Connector

| Point | Résultat |
|-------|----------|
| `adapters/meta-capi.ts` présent | OK — 3494 bytes |
| Routing par `destination_type` | OK — `emitter.ts` lignes 368-369 |
| CRUD destinations `meta_capi` | OK — validation + auto-generate endpoint (routes.ts lignes 160-166) |
| Token masqué dans les réponses | OK — `sanitizeDestinationRow()` + `maskSecret()` (lignes 83-102) |
| Endpoint Meta auto-généré via pixel ID | OK — `getMetaEndpointUrl()` (ligne 166) |

### T8.7B.2 — Meta CAPI Test Endpoint Fix

| Point | Résultat |
|-------|----------|
| Test endpoint `meta_capi` envoie PageView | OK — `event_name: 'PageView'` (ligne 301) |
| Test endpoint `webhook` garde ConnectionTest | OK — `event_name: 'ConnectionTest'` (ligne 279) |
| Delivery logs reflètent le bon `event_name` | OK — condition `meta_capi ? 'PageView' : 'ConnectionTest'` (ligne 352) |

### Tableau récapitulatif

| Point | Résultat |
|-------|----------|
| T8.7A tenant metrics | ✅ OK |
| T8.7A destination framework | ✅ OK |
| T8.7B adapter Meta | ✅ OK |
| T8.7B routing meta_capi | ✅ OK |
| T8.7B token masking | ✅ OK |
| T8.7B.2 PageView test | ✅ OK |
| Webhook ConnectionTest inchangé | ✅ OK |

---

## 4. BUILD PROD

| Paramètre | Valeur |
|-----------|--------|
| Tag | `v3.5.99-meta-capi-test-endpoint-fix-prod` |
| Commit source | `9b461717` |
| Branche | `ph147.4/source-of-truth` |
| Build | `docker build --no-cache` |
| Registry | `ghcr.io/keybuzzio/keybuzz-api` |
| Digest PROD | `sha256:bcd51da92d726a55494775398d68c36357e5c310d3be4ba2c2b3fb523306c912` |
| Build ID local | `2a7987c8467f` |

---

## 5. GITOPS PROD

| Étape | Détail |
|-------|--------|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.99-meta-capi-test-endpoint-fix-prod` |
| Commit infra | `a7ba43e` sur `main` |
| Push infra | `5d59c88..a7ba43e main -> main` |
| SCP + apply | `kubectl apply -f` depuis le bastion |
| Rollout | Succès en ~21s |
| Pod PROD | `keybuzz-api-9dbd5d8dd-2v9bl` (Running) |

---

## 6. VALIDATION PROD

### A — Fondation Tenant Marketing

| Test | Résultat |
|------|----------|
| `/metrics/overview` sans `tenant_id` → `scope = global` | ✅ `global` |
| `/metrics/overview?tenant_id=ecomlg-001` → `scope = tenant` | ✅ `tenant` |
| `tenant_id` retourné | ✅ `ecomlg-001` |
| Pas de crash | ✅ |
| `test_accounts_count` global = 15 | ✅ Exclusion test fonctionne |
| `test_accounts_count` tenant = 1 | ✅ Scoped correctement |

### B — Webhook Existant

| Test | Résultat |
|------|----------|
| Webhook destinations | SKIP — aucun webhook actif en PROD |
| (Le mécanisme est vérifié via source code : ConnectionTest inchangé) | ✅ |

### C — Meta CAPI Destination

| Test | Résultat |
|------|----------|
| Création destination `meta_capi` | ✅ ID `28cbc2be-489a-4f22-a5a8-228d0c0d6551` |
| Token masqué en réponse | ✅ `EA****...ZD` |
| Endpoint Meta auto-généré | ✅ `https://graph.facebook.com/v21.0/1353921442291697/events` |
| Isolation tenant confirmée | ✅ "Insufficient permissions" pour autre tenant |

### D — Meta CAPI Test Endpoint

| Test | Résultat |
|------|----------|
| POST `/destinations/:id/test` | ✅ Pipeline exécuté |
| Event envoyé = PageView | ✅ (confirmé via delivery logs) |
| Meta HTTP 400 "Malformed access token" | Attendu (token de test, pas un vrai token PROD) |
| Delivery log `event_name` = `PageView` | ✅ |
| Token absent des réponses API | ✅ 0 occurrences |
| Token absent des delivery logs | ✅ 0 occurrences |

> **Note** : Le "Malformed access token" est attendu car le token utilisé pour la validation est un token de test. En production réelle, chaque tenant configurera son propre token Meta valide. Le pipeline complet fonctionne correctement (création, masquage, envoi PageView, logging).

### E — Non-régression

| Test | Résultat |
|------|----------|
| Health API | ✅ `{"status":"ok"}` |
| Metrics fonctionnels | ✅ scope global + tenant |
| Test exclusion | ✅ 15 comptes test exclus globalement |
| Delivery logs propres | ✅ event_name correct, pas de fuite token |
| PATCH destinations (deactivate) | ✅ Fonctionnel |
| Admin V2 | ✅ Non touché |
| Client SaaS | ✅ Non touché |
| Backend Python | ✅ Non touché |

---

## 7. ROLLBACK GITOPS (NON EXÉCUTÉ)

### Image de rollback

```
v3.5.95-outbound-destinations-api-prod
```

### Procédure (GitOps strict)

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.95-outbound-destinations-api-prod
```

2. Commit + push :
```bash
cd keybuzz-infra
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "ROLLBACK: revert to v3.5.95-outbound-destinations-api-prod"
git push origin main
```

3. Apply depuis le bastion :
```bash
scp deployment.yaml root@46.62.171.61:/tmp/
ssh root@46.62.171.61 "kubectl apply -f /tmp/deployment.yaml && kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod"
```

**Aucun `kubectl set image` autorisé.**

---

## 8. IMAGES AVANT/APRÈS

| Env | Avant | Après |
|-----|-------|-------|
| PROD | `v3.5.95-outbound-destinations-api-prod` | `v3.5.99-meta-capi-test-endpoint-fix-prod` |
| DEV | `v3.5.99-meta-capi-test-endpoint-fix-dev` | Inchangé |

---

## 9. FICHIERS MODIFIÉS (cumul T8.7A + T8.7B + T8.7B.2)

### keybuzz-api (bastion)

| Fichier | Phase | Modification |
|---------|-------|-------------|
| `src/modules/metrics/routes.ts` | T8.7A | `tenant_id` query param, `scope` dans réponse |
| `src/modules/outbound-conversions/routes.ts` | T8.7A + T8.7B + T8.7B.2 | DESTINATION_TYPES, platform columns, CRUD meta_capi, sanitize, PageView test |
| `src/modules/outbound-conversions/emitter.ts` | T8.7B | Routing destination_type, sendToMetaCapiDest |
| `src/modules/outbound-conversions/adapters/meta-capi.ts` | T8.7B | Adapter Meta Conversions API v21.0 |

### keybuzz-infra (local)

| Fichier | Modification |
|---------|-------------|
| `k8s/keybuzz-api-prod/deployment.yaml` | Image → `v3.5.99-meta-capi-test-endpoint-fix-prod` |

---

## 10. DOCUMENTS DE RÉFÉRENCE

| Document | Chemin |
|----------|--------|
| T8.7A Foundation | `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md` |
| T8.7A Audit | `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md` |
| T8.7B Meta CAPI | `keybuzz-infra/docs/PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md` |
| T8.7B Audit | `keybuzz-infra/docs/PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-AUDIT.md` |
| T8.7B.1 Validation réelle | `keybuzz-infra/docs/PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01.md` |
| T8.7B.2 Test Endpoint Fix | `keybuzz-infra/docs/PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md` |
| Knowledge Transfer unifié | `keybuzz-infra/docs/KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md` |

---

## 11. VERDICT FINAL

```
META CAPI NATIVE PER TENANT LIVE IN PROD
— TENANT FOUNDATION PROMOTED
— PAGEVIEW TEST ENDPOINT LIVE
— WEBHOOKS UNCHANGED
— MULTI-TENANT SAFE
```

| Critère | Statut |
|---------|--------|
| Build-from-git | ✅ Commit `9b461717` |
| GitOps strict | ✅ Aucun kubectl set image |
| Token masking | ✅ Aucune fuite |
| Tenant isolation | ✅ RBAC vérifié |
| Non-régression | ✅ Health + metrics + destinations |
| Rollback documenté | ✅ v3.5.95-outbound-destinations-api-prod |
| Admin V2 inchangé | ✅ |
| Client SaaS inchangé | ✅ |
| Backend inchangé | ✅ |
