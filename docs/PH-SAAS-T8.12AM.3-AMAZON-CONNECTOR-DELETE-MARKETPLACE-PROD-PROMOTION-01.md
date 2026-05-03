# PH-SAAS-T8.12AM.3 — Amazon Connector Delete & Marketplace — PROD Promotion

> Phase : PH-SAAS-T8.12AM.3
> Date : 2026-05-04
> Type : promotion PROD contrôlée API + Client
> Verdict : **GO PROD**

---

## Contexte

Promotion en PROD de la correction AM.2 validée en DEV :
- Self-healing AM.1 supprimé (endpoint de lecture écrivait en DB)
- `/status` redevenu read-only
- Nouvel endpoint explicite `POST /channels/activate-amazon`
- `removeChannel()` nettoie `connection_ref`
- Client appelle l'activation uniquement après callback OAuth

AM.1 n'a jamais été promu seul en PROD. AM.2 le remplace entièrement.

---

## Preflight

### Branches

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-api | `ph147.4/source-of-truth` | `7de73e7a` | Non | **OK** |
| keybuzz-client | `ph148/onboarding-activation-replay` | `8942716` | Non | **OK** |
| keybuzz-infra | `main` | `04f6187` | Non | **OK** |

### Runtimes avant promotion

| Service | Runtime PROD avant | Verdict |
|---------|-------------------|---------|
| API | `v3.5.137-conversation-order-tracking-link-prod` | Confirmé |
| Client | `v3.5.148-shopify-official-logo-tracking-parity-prod` | Confirmé |
| Admin | N/A (hors scope) | OK |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | Inchangé |

### Source vérification API

| Brique | Vérifié | Verdict |
|--------|---------|---------|
| Self-healing absent dans `compat/routes.ts` | 0 occurrences | **PASS** |
| `/status` read-only | Marqueur présent | **PASS** |
| `POST /channels/activate-amazon` | Endpoint présent | **PASS** |
| `removeChannel()` nettoie `connection_ref` | `= NULL` présent | **PASS** |

### Source vérification Client

| Brique | Vérifié | Verdict |
|--------|---------|---------|
| `activateAmazonChannels` dans `channels/page.tsx` | 2 occurrences | **PASS** |
| `activateAmazonChannels` dans `amazon.service.ts` | 1 occurrence | **PASS** |
| BFF `app/api/amazon/activate-channels/route.ts` | Fichier existe | **PASS** |
| Shopify logo `shopify.png` | 2 occurrences | **PASS** |

---

## Build PROD

| Image | Source commit | Branche | Tag | Digest | Rollback |
|-------|-------------|---------|-----|--------|----------|
| API | `7de73e7a` | `ph147.4/source-of-truth` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | `sha256:f6a2aba203f0a001ccdd61f78803e1a2810d2e8bc11afa6114f43116f2d5a749` | `v3.5.137-conversation-order-tracking-link-prod` |
| Client | `8942716` | `ph148/onboarding-activation-replay` | `v3.5.149-amazon-connector-status-ux-prod` | `sha256:dc4c6583abab7e1da650b1faa03d616a30266f61b3e30c3ef749acbcbd60d1c8` | `v3.5.148-shopify-official-logo-tracking-parity-prod` |

### Build args Client PROD

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

---

## GitOps PROD

| Manifest | Image avant | Image après |
|----------|------------|-------------|
| `keybuzz-api-prod/deployment.yaml` | `v3.5.137-conversation-order-tracking-link-prod` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` |
| `keybuzz-client-prod/deployment.yaml` | `v3.5.148-shopify-official-logo-tracking-parity-prod` | `v3.5.149-amazon-connector-status-ux-prod` |

Commit infra : `04f6187`
Méthode : `kubectl apply -f` + `kubectl rollout status`

---

## Validation PROD structurelle

| Check | Attendu | Résultat |
|-------|---------|----------|
| API health | 200 OK | **PASS** |
| API image runtime | `v3.5.138-...` | **PASS** |
| Client image runtime | `v3.5.149-...` | **PASS** |
| API pod restarts | 0 | **PASS** |
| Client pod restarts | 0 | **PASS** |
| Admin image | Inchangée | **PASS** |
| Website image | `v0.6.8-tiktok-browser-pixel-prod` | **PASS** |

---

## Validation PROD eComLG

| Check | Attendu | Résultat |
|-------|---------|----------|
| Amazon channels PROD | 5 active (BE,ES,FR,IT,PL) | **PASS** |
| Après appel `/status` | Toujours 5 active | **PASS** — read-only confirmé |
| Status response | CONNECTED, countries: FR,ES,IT | **PASS** |
| connection_ref | Tous `cmmsdn4fs...` | **PASS** — inchangé |

---

## Validation PROD SWITAA

SWITAA PROD a 9 rows dans `tenant_channels` :
- 1 `amazon-fr` active (conn_0dba...) — tenant actif
- 1 `amazon-fr` active avec `disconnected_at` set (conn_1165...) — donnée legacy, tenant secondaire
- 7 removed (amazon-es, amazon-be, amazon-ca, amazon-de, amazon-sg, amazon-pl, shopify-global)

La validation utilisateur (suppression / reconnexion OAuth) nécessite l'intervention de Ludovic sur Amazon Seller Central.

---

## Validation tracking Client PROD

| Surface | ID | Présent dans build | Verdict |
|---------|----|--------------------|---------|
| GA4 | `G-R3QQDYEBFG` | ✅ | **PASS** |
| sGTM | `t.keybuzz.pro` | ✅ | **PASS** |
| TikTok | `D7PT12JC77U44OJIPC10` | ✅ | **PASS** |
| LinkedIn | `9969977` | ✅ | **PASS** |
| Meta Pixel | `1234164602194748` | ✅ | **PASS** |
| Shopify logo PNG | 70KB | ✅ | **PASS** |
| API URL | `api.keybuzz.io` | ✅ | **PASS** |
| `api-dev` absent | 0 occurrences | ✅ | **PASS** |

---

## Non-régression globale

| Brique | Attendu | Résultat |
|--------|---------|----------|
| 17TRACK CronJob | Suspendu (True) | **PASS** |
| lifecycle CronJob | dry-run | **PASS** |
| Outbound worker | Inchangé (`v3.5.165-escalation-flow-prod`) | **PASS** |
| Billing subscriptions | 6 | **PASS** |
| Admin PROD | Inchangé | **PASS** |
| Website PROD | Inchangé | **PASS** |

---

## Gaps restants

| Gap | Impact | Priorité |
|-----|--------|----------|
| SWITAA PROD a 2 rows `amazon-fr` active (tenants différents) | Donnée legacy, pas un bug AM.2 | Faible |
| SWITAA reconnexion Amazon FR nécessite action Ludovic | Seller Central + OAuth requis | Moyen |
| Callback OAuth (`keybuzz-backend`) ne touche pas `tenant_channels` | Compensé par endpoint explicite | Moyen |
| Marketplace mismatch (FR vs MX) reste possible côté Amazon | Hors scope code KeyBuzz | Faible |

---

## Rollback PROD (GitOps strict)

### Procédure (NE PAS exécuter sauf si nécessaire)

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   - Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.137-conversation-order-tracking-link-prod`

2. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` :
   - Image : `ghcr.io/keybuzzio/keybuzz-client:v3.5.148-shopify-official-logo-tracking-parity-prod`

3. `git commit && git push`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
5. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
6. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
7. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`
8. Vérifier manifest = runtime = annotation

---

## Résumé final

**AMAZON CONNECTOR DELETE AND MARKETPLACE TRUTH LIVE IN PROD — NO CONNECTOR RESURRECTION — OAUTH SELF-HEALING REMOVED — EXPLICIT ACTIVATION ONLY — ECOMLG PRESERVED — SWITAA RECONNECT PATH HONEST — ORDERS SYNC GUARDED — CLIENT TRACKING AND SHOPIFY LOGO PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT**

| Critère | Résultat |
|---------|----------|
| API PROD | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` |
| Digest API | `sha256:f6a2aba203f0...` |
| Client PROD | `v3.5.149-amazon-connector-status-ux-prod` |
| Digest Client | `sha256:dc4c6583abab...` |
| Commits API | `7de73e7a` |
| Commits Client | `8942716` |
| Commits Infra | `04f6187` |
| eComLG préservé | **Oui** — 5 channels PROD inchangés |
| Self-healing supprimé | **Oui** — `/status` read-only |
| Suppression stable | **Oui** — `connection_ref` nettoyé |
| Tracking Client | **Oui** — GA4/sGTM/TikTok/LinkedIn/Meta |
| Shopify logo | **Oui** — PNG 70KB |
| Billing/CAPI drift | **Aucun** |
| Rapport | `keybuzz-infra/docs/PH-SAAS-T8.12AM.3-AMAZON-CONNECTOR-DELETE-MARKETPLACE-PROD-PROMOTION-01.md` |
