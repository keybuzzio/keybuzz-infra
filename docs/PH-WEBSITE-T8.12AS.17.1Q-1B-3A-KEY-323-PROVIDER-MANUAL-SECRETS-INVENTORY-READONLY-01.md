# PH-WEBSITE-T8.12AS.17.1Q-1B-3A-KEY-323-PROVIDER-MANUAL-SECRETS-INVENTORY-READONLY-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-3A provider/manual secrets inventory refresh read-only
> Environnement : DEV + PROD read-only
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO Q-1B-3A PROVIDER INVENTORY READY.

Inventaire complet sans aucune lecture de valeur secret. 30 ExternalSecrets cartographies sur 11 namespaces vers 35 paths Vault KV uniques (matches Q-1B-0). 125 K8s Secrets identifies : 28 ESO managed + 12 imagePull (GHCR) + 61 manual + 14 TLS + 10 helm. 47 manual secrets significatifs DEV+PROD (apres exclusion observability/external-secrets/vault-management/TLS/helm/SA-token/vault-tokens auto-CronJob). Workload consumption mapping cross-reference E2/E3 + source grep confirme runtime usage par fichier source pour 9 providers (Stripe, SES, Google Ads, Meta Ads, Amazon SP-API, Shopify, Octopia, 17track, ADS_ENCRYPTION). 5 secrets manuels ORPHELINS detectes sans workload reference (vault-emergency-token, keybuzz-api-postgres-static, keybuzz-api-auth, keybuzz-octopia doublon ESO, litellm-runtime-key). Classification A-J produite : 4 provider externe high-risk (B), 3 OAuth login (C), 4 marketplace OAuth (D), 4 infra direct (E), 5 LLM/AI (F), 6 manual internal candidats migration ESO (G), 2 imagePull GHCR (H), 1 encryption durable blocker (I keybuzz-ads-encryption), 8 non-secret exclude (J Stripe price IDs + URLs + tenant IDs publics). 0 secret/token/value affiche, 0 provider externe call, 0 build/deploy/restart, 0 mutation. Vault HA Raft 3/3 stable Raft 1140836 sync. ExternalSecrets 30/30 True. 0 Warning event Kubernetes 2h.

Phrase finale :
STOP AS.17.1Q-1B-3A - GO Q-1B-3A PROVIDER INVENTORY READY. Rapport docs-only pret, en attente GO Ludovic commit/push. Q-1B-3B EXEC, Q-1B-4, Q-1B-5, Q-1B-6 et PROD promotion restent NO GO.

## 2. Scope et hors scope

### Scope inclus read-only

- preflight bastion + git HEAD + temp files cleanup verify.
- Vault HA + ESO health.
- 30 ExternalSecrets metadata JSONL (no values).
- 125 K8s Secrets metadata + key names (no values).
- Workload consumption mapping 15 namespaces.
- Source grep provider/manual patterns 5 repos applicatifs (file counts + critical paths).
- 5 secrets orphelins suspects verify (workload references).
- Classification A-J 10 categories.
- Provider-specific risk deep-dive (Stripe, SES, OAuth, GHCR, Ads, marketplace, LLM, ads-encryption, inbound-webhook, litellm-db).
- AI feature parity matrix.
- No fake metrics verification.
- Proposed future batches Q-1B-3B/3C/3D/3E/4/5/6 + Q-1F-3.
- Decisions Ludovic required.

### Hors scope strict

- aucune rotation, aucune mutation Vault/K8s.
- aucun vault kv get/put/patch/delete.
- aucun token create/revoke, policy write/delete.
- aucun appel provider externe.
- aucun login dashboard provider.
- aucun build, docker push, GitOps deploy.
- aucun restart, kubectl apply/patch/edit/set/annotate/delete/create.
- aucun changement source applicatif ou manifest.
- aucun test paiement, webhook emis, fake event.
- aucun secret value/base64/JWT/cookie/token affiche.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports KEY-323 chain

| Sequence | Commit | Description |
|---|---|---|
| Q-1A-bis-exec | 346b17a | Vault admin token replacement |
| Q-1B-0 | 7846785 | KV secrets rotation plan |
| Q-1B-1A | 423ad49 | DEV internal low-risk dry-run |
| Q-1B-1B | fcc1170 | DEV internal low-risk execution |
| Q-1F-1 | 556772c | DEV post-rotation validation |
| Q-1B-2A | 4950f96 | PROD internal low-risk dry-run |
| Q-1B-2A-bis | b00c9b8 | debug-env disclosure audit fix |
| Q-1B-2B | 41b80a0 | PROD internal rotation execution Mode B SAFE |
| Q-1F-2 | 9d82413 | PROD internal rotation stability validation |
| Q-1B-3A | en cours (ce rapport) | provider/manual secrets inventory read-only |

Linear : KEY-323 (lecture commentaires non disponible cote CE, documente).

## 4. Preflight

| Check | Attendu | Resultat | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 15:30 UTC | OK |
| Git infra HEAD | descendant 9d82413 | 9d824139... clean | OK |
| Git client HEAD | descendant f61763a | f61763a4... clean | OK |
| keybuzz-api | ph147.4/source-of-truth dirty 223 connu | OK pre-existant prior sessions | OK |
| keybuzz-backend | main dirty 1 connu | OK | OK |
| keybuzz-admin-v2 / keybuzz-website | main clean | clean | OK |
| keybuzz-studio-api / keybuzz-studio | snapshots sans .git per CLAUDE.md | confirme | OK |
| 6 fichiers temp sensibles KEY-323 | tous absents | 6/6 absent | OK |
| Runners /tmp/keybuzz-*rotator*.sh | absents | 0 match | OK |

## 5. Health baseline

| Component | Resultat | Verdict |
|---|---|---|
| Vault HA Raft 3 nodes | unsealed, Raft 1140836 sync, vault-03 active leader | OK (+272 vs Q-1F-2 = activite normale ESO refresh) |
| ExternalSecrets | 30/30 Ready=True | OK |
| ClusterSecretStores | 2/2 Ready (vault-backend + vault-backend-database) | OK |
| ESO pods | 3/3 Running | OK |
| Workloads api-prod | 2 Running Deployment + Completed pods CronJob | OK |
| Workloads backend-prod | 3 Running Deployment (backend + amazon-orders/items workers) | OK |
| Workloads client-prod | 1/1 Running | OK |
| Workloads admin-v2 dev/prod | 1/1 + 1/1 Running | OK |
| Workloads studio-api dev/prod | 1/1 + 1/1 Running | OK |
| Workloads keybuzz-ai | 2/2 Running (litellm 2 replicas) | OK |
| Events Warning 2h 6 namespaces | 0/0/0/0/0/0 | OK |

## 6. ExternalSecrets inventory (30 ES)

| Namespace | ExternalSecret | Store | Target Secret | Refresh | Ready | Category |
|---|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | vault-backend | keybuzz-admin-v2-bootstrap | 1h | True | G manual internal (admin) |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-postgres | vault-backend | keybuzz-admin-v2-postgres | 1h | True | E infra direct Postgres |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | vault-backend | keybuzz-admin-v2-bootstrap | 1h | True | G |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | vault-backend | keybuzz-admin-v2-postgres | 1h | True | E |
| keybuzz-ai | litellm-secrets | vault-backend | litellm-secret | 1h | True | F LLM/AI |
| keybuzz-api-dev | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | True | A internal generated (deja rotate Q-1B-1B) |
| keybuzz-api-dev | keybuzz-api-postgres-admin | vault-backend-database | keybuzz-api-postgres-admin | 1h | True | E (Vault dynamic database engine) |
| keybuzz-api-dev | keybuzz-api-postgres-kv | vault-backend | keybuzz-api-postgres | 5m | True | E Postgres app |
| keybuzz-api-dev | keybuzz-db-migrator | vault-backend | keybuzz-db-migrator | 1h | True | E Postgres role migrator |
| keybuzz-api-dev | keybuzz-litellm-secrets | vault-backend | keybuzz-litellm-secrets | 1h | True | F LLM |
| keybuzz-api-dev | keybuzz-ses-secrets | vault-backend | keybuzz-ses | 1h | True | B provider externe SES |
| keybuzz-api-dev | keybuzz-stripe-secrets | vault-backend | keybuzz-stripe | 1h | True | B provider Stripe |
| keybuzz-api-dev | minio-credentials | vault-backend | minio-credentials | 1h | True | E infra MinIO |
| keybuzz-api-dev | octopia-credentials | vault-backend | octopia-credentials | 1h | True | D marketplace Octopia |
| keybuzz-api-dev | redis-credentials | vault-backend | redis-credentials | 1h | True | E infra Redis |
| keybuzz-api-prod | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | True | A (rotate Q-1B-2B) |
| keybuzz-api-prod | keybuzz-api-postgres | vault-backend | keybuzz-api-postgres | 5m | True | E |
| keybuzz-api-prod | minio-credentials | vault-backend | minio-credentials | 1h | True | E |
| keybuzz-api-prod | octopia-credentials | vault-backend | octopia-credentials | 1h | True | D |
| keybuzz-api-prod | redis-credentials | vault-backend | redis-credentials | 1h | True | E |
| keybuzz-backend-dev | keybuzz-backend-db | vault-backend | keybuzz-backend-db | 1h | True | E Postgres backend |
| keybuzz-backend-dev | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | True | A+E mixed (JWT+MinIO+internal-tokens+webhook+product-db rotate Q-1B-1B/Q-1B-2B) |
| keybuzz-backend-prod | keybuzz-backend-db | vault-backend | keybuzz-backend-db | 1h | True | E |
| keybuzz-backend-prod | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | True | A+E mixed |
| keybuzz-client-dev | keybuzz-auth-secrets | vault-backend | keybuzz-auth | 1h | True | C OAuth (NEXTAUTH_SECRET rotate, Google/Azure preserve) |
| keybuzz-client-dev | minio-credentials | vault-backend | minio-credentials | 1h | True | E |
| keybuzz-client-prod | keybuzz-auth-secrets | vault-backend | keybuzz-auth-secrets | 1h | True | C |
| keybuzz-seller-dev | seller-api-postgres | vault-backend | seller-api-postgres | 1h | True | E |
| observability | alerting-slack-dev | vault-backend | alerting-slack-dev | 1h | True | B provider externe Slack |
| observability | alerting-smtp-dev | vault-backend | alerting-smtp-dev | 1h | True | E infra SMTP local probable |

35 unique remote KV paths : 19 keybuzz/* (dont 4 rotated Q-1B-2B) + 13 secret/keybuzz/* + 3 secret/data/keybuzz/* + database/creds/keybuzz-admin (dynamic).

## 7. K8s Secrets manual inventory (47 significant + 12 imagePull)

### Provider externe (Category B)

| Namespace | Secret | Keys | Files runtime |
|---|---|---|---|
| keybuzz-api-prod | keybuzz-stripe | 11 (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, 8 price IDs, STRIPE_PRODUCT_ADDON_CHANNEL) | api src/modules/billing/stripe.ts, src/modules/billing/routes.ts |
| keybuzz-api-prod | keybuzz-ses | 4 (AWS_SES_ACCESS_KEY_ID, AWS_SES_SECRET_ACCESS_KEY, AWS_SES_REGION, AWS_SES_FROM_EMAIL) | api src/services/emailService.ts |
| keybuzz-api-prod | keybuzz-meta-ads | 2 (META_ACCESS_TOKEN, META_AD_ACCOUNT_ID) | api src/modules/metrics/routes.ts |
| keybuzz-api-dev + keybuzz-api-prod | keybuzz-google-ads | 4 (GOOGLE_ADS_CLIENT_ID, GOOGLE_ADS_CLIENT_SECRET, GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_REFRESH_TOKEN) | api src/modules/metrics/ad-platforms/google-ads.ts |
| keybuzz-api-dev + keybuzz-api-prod | keybuzz-shopify | 3 (SHOPIFY_CLIENT_ID, SHOPIFY_CLIENT_SECRET, SHOPIFY_ENCRYPTION_KEY) | api src/modules/marketplaces/shopify/{shopify.routes,shopifyWebhook.routes,shopifyAuth.service}.ts |
| keybuzz-api-dev + keybuzz-api-prod | tracking-17track | 1 (TRACKING_17TRACK_API_KEY) | api src/modules/tracking/trackingWebhook.routes.ts, seventeenTrackProvider, providerFactory |

### Marketplace OAuth (Category D)

| Namespace | Secret | Keys | Files runtime |
|---|---|---|---|
| keybuzz-backend-dev + keybuzz-backend-prod | amazon-spapi-creds | 4 (AMAZON_SPAPI_APP_ID, AMAZON_SPAPI_CLIENT_ID, AMAZON_SPAPI_CLIENT_SECRET, AMAZON_SPAPI_REDIRECT_URI) | api src/modules/orders/routes.ts + src/services/spapiMessaging.ts ; backend src/modules/marketplaces/amazon/amazon.vault.ts + src/config/env.ts |

Note : Octopia geree via ESO octopia-credentials (DEV + PROD, paths Vault secret/keybuzz/dev/octopia + keybuzz/prod/octopia), file ref api src/modules/marketplaces/octopia/{octopiaAuth.service,octopia.routes}.ts + workers/outboundWorker.ts.

### LLM / AI (Category F)

| Namespace | Secret | Managed | Keys | Notes |
|---|---|---|---|---|
| keybuzz-ai | litellm-secret | ESO via litellm-secrets | 6 (LITELLM_MASTER_KEY, DATABASE_URL, LITELLM_DATABASE_URL, USE_PRISMA_MIGRATE, OPENAI_API_KEY, ANTHROPIC_API_KEY) | source-of-truth ESO managed |
| keybuzz-ai | litellm-db-secret | manual | 3 (DATABASE_URL, LITELLM_DATABASE_URL, USE_PRISMA_MIGRATE) | DOUBLON probable avec ESO litellm-secret, decision Ludovic |
| keybuzz-ai | litellm-runtime-key | manual | 1 (LITELLM_RUNTIME_KEY) | ORPHELIN 0 workload ref, decision Ludovic supprimer ou usage cache ? |
| keybuzz-api-dev + keybuzz-api-prod | keybuzz-litellm | manual | 1 (LITELLM_MASTER_KEY) | DOUBLON ESO keybuzz-litellm-secrets, decision migration |
| keybuzz-studio-api-dev + keybuzz-studio-api-prod | keybuzz-studio-api-llm | manual | 9 (ANTHROPIC_API_KEY, GEMINI_API_KEY, LLM_API_KEY, LLM_MAX_TOKENS, LLM_MODEL, LLM_PROVIDER, LLM_TEMPERATURE, LLM_TIMEOUT_MS, PIPELINE_MODE) | studio-api LLM config + secrets, decision Ludovic migration ESO |

### Manual internal (Category G - candidat migration ESO)

| Namespace | Secret | Keys | Files runtime |
|---|---|---|---|
| keybuzz-backend-dev + keybuzz-backend-prod + keybuzz-client-dev + keybuzz-client-prod | keybuzz-internal-proxy | 1 (token) | backend src/modules/marketplaces/amazon/amazonFees.{routes,service}.ts |
| keybuzz-backend-prod | inbound-webhook-key | 1 (INBOUND_WEBHOOK_KEY) | backend src/modules/inbound/inbound.routes.ts (DEV utilise ESO keybuzz-backend-secrets, PROD divergence) |
| keybuzz-admin-v2-dev + keybuzz-admin-v2-prod | keybuzz-admin-v2-auth | 1 (NEXTAUTH_SECRET) | admin-v2 src/lib/auth.ts (separe de client NEXTAUTH_SECRET) |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-stripe | 1 (STRIPE_SECRET_KEY) | admin-v2 (test mode DEV only) |
| keybuzz-studio-api-dev + keybuzz-studio-api-prod | keybuzz-studio-api-auth | 1 (BOOTSTRAP_SECRET) | studio-api bootstrap auth |
| keybuzz-studio-api-dev + keybuzz-studio-api-prod | keybuzz-studio-api-db | 1 (DATABASE_URL) | studio-api Postgres |

### Image Pull (Category H)

| Namespace | Secret | Type | Note |
|---|---|---|---|
| keybuzz-{admin-v2-dev,admin-v2-prod,client-dev} | ghcr-secret | dockerconfigjson | GHCR PAT v1 |
| keybuzz-{api-dev,api-prod,backend-dev,backend-prod,client-dev,client-prod,seller-dev,studio-api-dev,studio-api-prod} | ghcr-cred | dockerconfigjson | GHCR PAT v2 (probable harmonisation incomplete) |

12 imagePull secrets dans 12 namespaces. 2 conventions de naming (ghcr-secret vs ghcr-cred).

### Encryption durable (Category I - blocker rotation)

| Namespace | Secret | Keys | Files runtime |
|---|---|---|---|
| keybuzz-api-dev + keybuzz-api-prod | keybuzz-ads-encryption | 1 (ADS_ENCRYPTION_KEY) | api src/lib/ads-crypto.ts - chiffre les data ads (refresh tokens Google Ads etc), BLOCKER rotation sans migration dual-read |

### Non-secret / public IDs (Category J - exclude rotation)

| Namespace | Secret/key | Type | Verdict |
|---|---|---|---|
| keybuzz-api-prod / keybuzz-stripe | STRIPE_PRICE_* (8 keys) + STRIPE_PRODUCT_ADDON_CHANNEL | Stripe price/product IDs | NON-SECRET, IDs publics, exclude rotation |
| keybuzz-client-prod / keybuzz-auth-secrets | NEXTAUTH_URL | URL publique | NON-SECRET, exclude |
| keybuzz-client-prod / keybuzz-auth-secrets | GOOGLE_CLIENT_ID + AZURE_AD_CLIENT_ID + AZURE_AD_TENANT_ID | OAuth client/tenant IDs | semi-publics (OAuth norm), exclude rotation directe (regenerable via provider mais inutile sans secret rotate) |
| keybuzz-api-prod / keybuzz-stripe | API_BASE_URL + APP_BASE_URL | URLs publiques | NON-SECRET, exclude |
| keybuzz-studio-api-{dev,prod} / keybuzz-studio-api-llm | LLM_MAX_TOKENS + LLM_MODEL + LLM_PROVIDER + LLM_TEMPERATURE + LLM_TIMEOUT_MS + PIPELINE_MODE | Config LLM | NON-SECRET, exclude |
| keybuzz-api-prod / keybuzz-meta-ads | META_AD_ACCOUNT_ID | Account ID | semi-public, exclude rotation directe |

### Orphelins detectes (5 secrets sans workload reference)

| Namespace | Secret | Status | Decision Ludovic |
|---|---|---|---|
| keybuzz-api-dev | vault-emergency-token | manual, 0 workload ref, contient DESCRIPTION + VAULT_TOKEN | break-glass token probable, decision : conserver ou cleanup |
| keybuzz-api-dev | keybuzz-api-postgres-static | manual, 0 workload ref, 5 keys Postgres | backup statique probable si ESO down, decision : conserver ou cleanup |
| keybuzz-api-dev | keybuzz-api-auth | manual, 0 workload ref, 2 keys COOKIE_SECRET + JWT_SECRET | obsolete probable (workload utilise ESO keybuzz-api-jwt), decision : cleanup |
| keybuzz-api-dev | keybuzz-octopia | manual, 0 workload ref, 1 key OCTOPIA_CLIENT_SECRET | obsolete doublon ESO octopia-credentials, decision : cleanup |
| keybuzz-ai | litellm-runtime-key | manual, 0 workload ref, 1 key LITELLM_RUNTIME_KEY | usage non clair, decision Ludovic |

### Workload reference summary

| Secret | Consumed by | Restart needed if rotated |
|---|---|---|
| keybuzz-stripe (PROD) | keybuzz-api Deployment | api-prod restart (rotate impact billing webhook) |
| keybuzz-ses | keybuzz-outbound-worker envFrom (api-dev/prod) | outbound-worker restart |
| keybuzz-google-ads | keybuzz-api Deployment envSecret | api restart |
| keybuzz-meta-ads | keybuzz-api Deployment envSecret (PROD only) | api-prod restart |
| keybuzz-shopify | keybuzz-api Deployment envSecret | api restart |
| tracking-17track | keybuzz-api Deployment envSecret | api restart |
| amazon-spapi-creds | keybuzz-backend envFrom | backend restart |
| keybuzz-litellm | keybuzz-api Deployment envSecret | api restart |
| keybuzz-internal-proxy | keybuzz-backend envSecret + keybuzz-client envSecret | backend + client restart (cross-service) |
| inbound-webhook-key (PROD) | keybuzz-backend envFrom | backend-prod restart |
| keybuzz-ads-encryption | keybuzz-api Deployment envSecret | api restart (mais BLOCKER rotation = data ads chiffree durable) |
| keybuzz-admin-v2-auth | keybuzz-admin-v2 envSecret | admin-v2 restart |
| keybuzz-admin-v2-bootstrap (ESO) | keybuzz-admin-v2 envSecret | admin-v2 restart |
| keybuzz-admin-v2-postgres (ESO) | keybuzz-admin-v2 envSecret | admin-v2 restart |
| keybuzz-admin-v2-stripe | keybuzz-admin-v2 envSecret (DEV only) | admin-v2 restart |
| keybuzz-studio-api-{auth,db,llm} | keybuzz-studio-api Deployment | studio-api restart |
| litellm-secret + litellm-db-secret | litellm Deployment (keybuzz-ai) envFrom | litellm restart |
| ghcr-cred / ghcr-secret | imagePull tous Deployments | impact pull image (pas restart pod direct, mais blocker future deploy) |

## 8. Source grep summary (E5)

Patterns provider detectes par repo :

| Repo | Patterns + counts |
|---|---|
| keybuzz-api | STRIPE_ (3 files), SES_ (1), SMTP (8), GOOGLE_ (2), META_ (5), SHOPIFY_ (5), TRACKING_17TRACK (3), AMAZON_SPAPI (4), OCTOPIA (19), LITELLM (2), ADS_ENCRYPTION_KEY (1) |
| keybuzz-backend | SMTP (1), AMAZON_SPAPI (3), INBOUND_WEBHOOK_KEY (3), KEYBUZZ_INTERNAL_TOKEN (2) |
| keybuzz-client | SMTP (3), GOOGLE_ (1), AZURE_AD_ (1), META_ (1) |
| keybuzz-admin-v2 | STRIPE_ (1) |
| keybuzz-studio-api | SMTP (2), ANTHROPIC_ (3), GEMINI_ (4) |

Confirme runtime usage critique :
- billing Stripe : api src/modules/billing/stripe.ts
- SES email : api src/services/emailService.ts
- Google Ads : api src/modules/metrics/ad-platforms/google-ads.ts
- Meta : api src/modules/metrics/routes.ts
- Amazon SP-API : api orders + spapiMessaging, backend amazon.vault.ts + config/env.ts
- Shopify : api marketplaces/shopify (3 fichiers)
- Octopia : api marketplaces/octopia (auth + routes) + workers/outboundWorker
- 17track : api tracking webhook + seventeenTrackProvider + providerFactory
- ADS_ENCRYPTION : api src/lib/ads-crypto.ts

## 9. Classification A-J

| Category | Description | Secrets | Future phase |
|---|---|---|---|
| **A** | KV-only internal generated | keybuzz/{dev,prod}/jwt, keybuzz/{dev,prod}/backend-jwt, keybuzz/{dev,prod}/inbound-webhook (DEV ESO), secret/keybuzz/auth NEXTAUTH_SECRET, secret/keybuzz/prod/auth NEXTAUTH_SECRET, keybuzz/internal-tokens | DEJA ROTATE Q-1B-1B + Q-1B-2B |
| **B** | Provider externe high-risk | keybuzz-stripe (PROD), keybuzz-ses (PROD), keybuzz-meta-ads (PROD), keybuzz-google-ads (DEV+PROD), alerting-slack-dev | Q-1B-3B (Ludovic decisions per provider) |
| **C** | OAuth login/user-session | secret/keybuzz/auth Google/Azure (DEV) + secret/keybuzz/prod/auth Google/Azure | Q-1B-3C (impact UX login PROD users) |
| **D** | Marketplace OAuth | amazon-spapi-creds (DEV+PROD), keybuzz-shopify (DEV+PROD), octopia-credentials ESO (DEV+PROD), tracking-17track (DEV+PROD) | Q-1B-6 (re-consent tenant requise pour Amazon, decoupling Shopify/Octopia) |
| **E** | Infra direct | keybuzz/redis, keybuzz/{minio,prod/minio}, keybuzz/{dev,prod}/backend-postgres, keybuzz/{dev,prod}/backend-product-db, secret/keybuzz/prod/db_api, secret/data/keybuzz/dev/api-postgres, secret/data/keybuzz/dev/seller-api-postgres, keybuzz/admin-v2/{postgres,postgres-prod}, secret/keybuzz/dev/db_migrator, secret/keybuzz/litellm/database_url, keybuzz/observability/smtp/dev | Q-1B-4 (runbook par service Redis/Postgres/MinIO/SMTP) |
| **F** | LLM/AI | secret/keybuzz/ai/{openai_api_key,anthropic_api_key}, secret/keybuzz/litellm/master_key, keybuzz-litellm (manual doublon), keybuzz-studio-api-llm (ANTHROPIC+GEMINI), litellm-db-secret (manual doublon), litellm-runtime-key (orphelin) | Q-1B-5 (sync 3 namespaces + provider portals + cost considerations) |
| **G** | Manual internal candidat migration ESO | keybuzz-internal-proxy (4 namespaces), inbound-webhook-key PROD (divergence DEV ESO), keybuzz-admin-v2-auth (DEV+PROD), keybuzz-admin-v2-stripe (DEV), keybuzz-studio-api-{auth,db}, keybuzz-api-postgres-static (orphelin), keybuzz-api-auth (orphelin), keybuzz-octopia (orphelin doublon), litellm-runtime-key (orphelin) | Q-1B-3E (migration ESO + cleanup orphelins) |
| **H** | imagePull / registry | ghcr-cred (9 namespaces) + ghcr-secret (3 namespaces) | Q-1B-3D (GHCR PAT rotation dedicated plan, harmonisation naming) |
| **I** | Encryption durable | keybuzz-ads-encryption (DEV+PROD, 1 key ADS_ENCRYPTION_KEY) | BLOCKER sans dual-read/migration design |
| **J** | Non-secret / public ID / config | STRIPE_PRICE_* (8), STRIPE_PRODUCT_*, API_BASE_URL/APP_BASE_URL, NEXTAUTH_URL, GOOGLE_CLIENT_ID, AZURE_AD_CLIENT_ID, AZURE_AD_TENANT_ID, META_AD_ACCOUNT_ID, LLM_MAX_TOKENS/MODEL/PROVIDER/TEMPERATURE/TIMEOUT_MS/PIPELINE_MODE | EXCLUDE rotation - deplacer ConfigMap si possible |

## 10. Provider-specific risk deep-dive

### Stripe

| Aspect | Detail |
|---|---|
| Secret manuel | keybuzz-stripe (api-prod) 11 keys + keybuzz-admin-v2-stripe (admin-v2-dev) 1 key STRIPE_SECRET_KEY |
| ESO | keybuzz-stripe-secrets (api-dev only) -> secret/keybuzz/stripe (12 properties dont 8 price IDs publics) |
| Secrets reels rotatables | STRIPE_SECRET_KEY (test/prod), STRIPE_WEBHOOK_SECRET |
| Non-secrets | STRIPE_PRICE_* (8 IDs Stripe publics), API_BASE_URL, APP_BASE_URL, STRIPE_PRODUCT_ADDON_CHANNEL |
| Runtime files | api src/modules/billing/stripe.ts + src/modules/billing/routes.ts |
| Risque rotation | rotation webhook_secret cassera webhooks Stripe entrants -> re-config Stripe Dashboard endpoint requis ; rotation secret_key impacte API calls api -> Stripe |
| Mode test vs prod | Ludovic confirme test mode actuel (Q-1B-0/Q-1B-2A documente) |
| Decision Ludovic | scope rotation Stripe TEST keys (low-risk) OR defer PROD keys jusqu'a launch reel |

### SES (AWS)

| Aspect | Detail |
|---|---|
| ESO | keybuzz-ses-secrets -> secret/keybuzz/ses (4 keys access_key_id, secret_access_key, region, from_email) |
| Manual PROD | keybuzz-ses (api-prod) 4 keys (probable doublon ESO ou PROD pre-ESO) |
| Runtime | api src/services/emailService.ts (envFrom keybuzz-ses dans keybuzz-outbound-worker dev+prod) |
| Rotation | AWS IAM Access Key rotation : creer nouveau access key, deploy, revoke ancien |
| Risque | impact outbound email (notifications, OTP probable) - critique business |
| Decision Ludovic | window operation + rotation method (dual-key 2-phase) |

### OAuth Google / Azure AD

| Aspect | Detail |
|---|---|
| ESO | keybuzz-auth-secrets (client-dev) -> secret/keybuzz/auth (7 properties dont 2 secrets Google/Azure) + keybuzz-auth-secrets (client-prod) -> secret/keybuzz/prod/auth (6 properties dont 2 secrets) |
| Manual admin | keybuzz-admin-v2-auth (DEV+PROD) 1 key NEXTAUTH_SECRET admin (separe de client) |
| Runtime | client middleware.ts + NextAuth handlers ; admin-v2 src/lib/auth.ts |
| Rotation | Google Cloud Console + Azure AD portal regenerate Client Secret, redeploy |
| Risque | rotation cassera sessions OAuth actives users PROD, re-login requis (deja experience Q-1B-2B avec NEXTAUTH_SECRET) |
| Decision Ludovic | rotation Google/Azure secrets PROD requires Ludovic accept invalidation sessions + window operation |

### GHCR (Container Registry)

| Aspect | Detail |
|---|---|
| imagePullSecrets | ghcr-cred (9 namespaces) + ghcr-secret (3 namespaces) - inconsistency naming |
| Manual all namespaces | non-ESO, type kubernetes.io/dockerconfigjson |
| Runtime | tous Deployments KeyBuzz, impact pull images |
| Rotation | regenerer GitHub PAT, recreer imagePullSecrets dans 12 namespaces simultane (eviter periode mixte mid-rotation) |
| Risque | si nouveau PAT non deploy dans tous ns avant revoke ancien -> impact pull future deploy ; aucun impact pods Running |
| Decision Ludovic | harmonisation naming (ghcr-cred vs ghcr-secret) ; window operation rotation atomique 12 ns |

### Ads providers (Google Ads, Meta Ads)

| Aspect | Detail |
|---|---|
| Manual | keybuzz-google-ads (DEV+PROD, 4 keys), keybuzz-meta-ads (PROD only, 2 keys) |
| Runtime | api src/modules/metrics/ad-platforms/google-ads.ts + src/modules/metrics/routes.ts |
| Rotation | Google Ads API Console + Meta Marketing API regenerate tokens |
| Risque | impact reporting Ads dashboard, GA4/CAPI events si proxy |
| Decision Ludovic | rotation Ads tokens necessite re-authentication via OAuth flow + tenant impact |

### Marketplace OAuth (Amazon SP-API, Shopify, Octopia, 17track)

| Aspect | Detail |
|---|---|
| Amazon SP-API | amazon-spapi-creds (backend dev+prod) 4 keys LWA + AWS IAM. Rotation requires re-consent par tenant Seller Central + AWS IAM rotation. Files : api orders+spapiMessaging, backend amazon.vault.ts+config |
| Shopify | keybuzz-shopify (dev+prod) 3 keys CLIENT_ID/SECRET/ENCRYPTION_KEY. Rotation = Partners Dashboard regenerate app secret + ENCRYPTION_KEY (probable encryption tokens shop) = risque encryption blocker |
| Octopia | ESO octopia-credentials (dev+prod) 4 keys. Rotation = Octopia portal regenerate, Vault patch, ESO sync |
| 17track | tracking-17track 1 key API_KEY. Rotation = 17track portal regenerate, plus simple. Workflow : api tracking webhook + 17track provider |
| Decision Ludovic | scope marketplace : tenant coordination Amazon, encryption-key Shopify blocker, sequence per portal |

### LLM / AI

| Aspect | Detail |
|---|---|
| ESO (source-of-truth) | litellm-secret (keybuzz-ai) 6 keys + keybuzz-litellm-secrets (api-dev) 1 key duplicate LITELLM_MASTER_KEY |
| Manual doublons | keybuzz-litellm (api dev+prod) 1 key + litellm-db-secret (keybuzz-ai) 3 keys + litellm-runtime-key (keybuzz-ai) 1 key orphelin |
| Studio-api distinct | keybuzz-studio-api-llm (dev+prod) 9 keys (ANTHROPIC, GEMINI, LLM config) |
| Runtime | LiteLLM proxy keybuzz-ai gateway + api consumers + studio-api LLM |
| Rotation OpenAI/Anthropic | regenerer keys via console, update Vault, restart LiteLLM + api + studio-api ; cost considerations (suspendre pendant window operation) |
| Rotation LITELLM_MASTER_KEY | impact tous services AI consumers, requires sync 3 namespaces (keybuzz-ai + keybuzz-api-dev + keybuzz-api-prod) |
| Decision Ludovic | cleanup doublons keybuzz-litellm + litellm-db-secret + litellm-runtime-key (orphelin) ; coordination provider OpenAI/Anthropic + window IA suspendue |

### keybuzz-ads-encryption (BLOCKER Category I)

| Aspect | Detail |
|---|---|
| Manual | DEV+PROD, 1 key ADS_ENCRYPTION_KEY |
| Runtime | api src/lib/ads-crypto.ts - chiffre les data ads dataset (probable refresh tokens Google Ads stockes dans DB chiffres) |
| Rotation directe | IMPOSSIBLE sans dual-read OR vidage dataset OR migration scheme keys |
| Decision Ludovic | strategy : (a) skip rotation indefinite, (b) dual-read + re-encryption batch, (c) vidage dataset ads + re-collect |

### inbound-webhook-key PROD (Category G divergence)

| Aspect | Detail |
|---|---|
| Manual PROD | keybuzz-backend-prod/inbound-webhook-key 1 key |
| ESO DEV | keybuzz-backend-dev/keybuzz-backend-secrets contient INBOUND_WEBHOOK_KEY -> ESO geree |
| Divergence | DEV ESO + PROD manuel = harmonisation requise |
| Decision Ludovic | migrer PROD vers ESO OU laisser separation pour isolement (depends sur process emetteur webhook PROD) |

### litellm-db-secret + litellm-runtime-key (Category F doublons/orphelins)

| Aspect | Detail |
|---|---|
| litellm-db-secret | keybuzz-ai 3 keys = DOUBLON probable avec litellm-secret ESO (DATABASE_URL + LITELLM_DATABASE_URL + USE_PRISMA_MIGRATE) |
| litellm-runtime-key | keybuzz-ai 1 key, ORPHELIN 0 workload reference - cleanup candidat |
| Decision Ludovic | verifier helm chart litellm utilise quel secret + cleanup orphelin runtime-key |

## 11. AI feature parity / anti-regression matrix

| Feature | Secret dependencies | Workloads | Risk if rotated | Validation future | Verdict |
|---|---|---|---|---|---|
| Inbox AI assist / Autopilot draft | OPENAI_API_KEY + ANTHROPIC_API_KEY (via LiteLLM), LITELLM_MASTER_KEY | LiteLLM gateway + api Deployment | rotation LITELLM_MASTER_KEY = cassure transitoire AI features ; rotation OpenAI/Anthropic = cassure jusqu'a sync 3 ns | dry-run test sans appel provider, sync atomique 3 ns | Q-1B-5 |
| LiteLLM gateway | LITELLM_MASTER_KEY + DATABASE_URL + provider keys | litellm (keybuzz-ai) 2 pods | rotation cassere si secret manuel litellm-db-secret pas synchronise | cleanup doublons + ESO migration | Q-1B-5 |
| Studio API LLM | ANTHROPIC_API_KEY + GEMINI_API_KEY + LLM_API_KEY + config | keybuzz-studio-api (dev+prod) | rotation cassere si non sync, GEMINI nouveau provider | dry-run + ESO migration | Q-1B-5/Q-1B-3E |
| Amazon orders / fees | AMAZON_SPAPI_CLIENT_ID/SECRET + APP_ID + KEYBUZZ_INTERNAL_TOKEN cross-service | api orders + backend amazon workers | rotation re-consent par tenant requise, impact orders sync | runbook par tenant, defer Q-1B-6 | Q-1B-6 |
| Octopia connector | OCTOPIA_CLIENT_ID/SECRET | api octopiaAuth + workers/outboundWorker | rotation portal Octopia + Vault sync | Q-1B-6 |
| Shopify connector | SHOPIFY_CLIENT_ID/SECRET + SHOPIFY_ENCRYPTION_KEY | api shopify routes + auth.service | rotation ENCRYPTION_KEY BLOCKER (chiffrement shop tokens DB) | dual-read OR scope reduit (uniquement CLIENT_SECRET) | Q-1B-6 |
| Tracking 17track | TRACKING_17TRACK_API_KEY | api tracking webhook + provider | rotation simple = portal 17track regenerate | Q-1B-6 batch |
| Billing Stripe | STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET | api billing stripe.ts + routes.ts | rotation webhook_secret = re-config Stripe Dashboard endpoint | test mode first | Q-1B-3B |
| Outbound email SES | AWS_SES_* | api outbound-worker + emailService | rotation IAM keys 2-phase | runbook AWS IAM | Q-1B-3B |
| Slack webhook (observability) | webhook_url | alertmanager | rotation cassere alerting jusqu'a redeploy | low risk DEV-only | Q-1B-3B optionnel |

## 12. No fake metrics / no fake events

Verifications conformite Q-1B-3A :

| Interdit | Action verifiee | Verdict |
|---|---|---|
| 0 Stripe API call | aucune commande stripe CLI/API executee | OK |
| 0 webhook emitted | aucun curl POST vers endpoint provider | OK |
| 0 Meta/Google Ads call | aucune commande Google/Meta API | OK |
| 0 GA4/CAPI event | aucun fake event tracking | OK |
| 0 checkout | aucun paiement test | OK |
| 0 email test SES | aucun envoi email | OK |
| 0 tracking provider call (17track) | aucune commande API | OK |
| 0 marketplace provider call (Amazon/Shopify/Octopia) | aucune commande | OK |
| 0 OpenAI/Anthropic/Gemini call | aucune commande API | OK |
| 0 fake signup_complete / purchase | aucun event business | OK |
| 0 dashboard / KPI invente | toutes metriques via kubectl get/logs/vault status reels | OK |

## 13. Proposed future batches

| Future phase | Scope | Preconditions | Blast radius | Suggested mode | GO gate |
|---|---|---|---|---|---|
| **Q-1B-3B** | Provider externe low-risk : Stripe TEST keys + SES IAM + Slack webhook + Ads tokens (Google/Meta) | Ludovic decisions per provider + window operation par provider | impact billing/email/Ads/alerting | Mode B SAFE + provider-by-provider runbook | GO Ludovic explicite per provider |
| **Q-1B-3C** | OAuth login secrets (Google/Azure client_secret DEV+PROD) | Ludovic accept invalidation sessions users PROD + window operation | restart Client + sessions invalides PROD | Mode B SAFE + co-validation UX Ludovic post-rotation | GO Ludovic explicite |
| **Q-1B-3D** | GHCR PAT + imagePullSecrets harmonisation | rotation GitHub PAT + redeploy 12 namespaces atomique + harmoniser naming ghcr-cred/ghcr-secret | impact pull image future deploy (no current pod impact) | Mode B SAFE rotation atomique 12 ns | GO Ludovic |
| **Q-1B-3E** | Manual internal migration ESO + orphelins cleanup | inventaire complet doublons + tests source workload references | aucun runtime impact si orphelin cleanup, restart workloads pour migration ESO | docs design + DEV-first | GO Ludovic per secret |
| **Q-1B-4** | Infra direct (Redis password, Postgres app roles, MinIO access keys, SMTP) | runbook par service + window operation + dual-credentials transient si possible | runtime apps backend/api/admin/seller impact | runbook par service | GO Ludovic per service |
| **Q-1B-5** | LLM/AI : LITELLM_MASTER_KEY + OpenAI/Anthropic/Gemini keys, cleanup doublons litellm-db-secret + litellm-runtime-key + keybuzz-litellm | provider portals access + cost considerations + sync 3 namespaces (keybuzz-ai + keybuzz-api-dev/prod + keybuzz-studio-api-dev/prod) | impact IA SAV + Studio LLM + autopilot | Mode B SAFE + AI feature parity tests dry-run | GO Ludovic per provider |
| **Q-1B-6** | Marketplace OAuth : Amazon SP-API (re-consent par tenant), Shopify (BLOCKER ENCRYPTION_KEY), Octopia, 17track | tenant coordination Amazon + Shopify encryption dual-read design + portals access | impact orders/marketplace tenant + tracking | Mode B SAFE + per-tenant runbook | GO Ludovic per marketplace |
| **Q-1B-7 (Category I separe)** | keybuzz-ads-encryption strategy : skip / dual-read / vidage dataset | decision strategique Ludovic | BLOCKER si rotate directement = perte data ads | docs design only | GO Ludovic strategique |
| **Q-1F-3** | Validation phase apres Q-1B-3B/3C/3D execution | Q-1B-3B/3C/3D EXEC completes + UX Ludovic | observability cumulee | read-only stability validation | post Q-1B-3 cycle complet |
| **AS.17.0/AS.17.0.1** | PROD promotion marketing/website | tout cycle Q-1B-x complet + decisions strategiques | impact marketing public | dedicated phase | NO GO maintenu |

## 14. Decisions Ludovic required

1. **Q-1B-3B providers a inclure** : Stripe TEST keys (low-risk recommended) ? SES IAM rotation 2-phase ? Slack webhook DEV ? Ads tokens (Google/Meta) ?
2. **Stripe scope** : TEST keys only ou inclure PROD keys ? mode launch reel pas atteint -> TEST recommande.
3. **SES IAM rotation strategy** : 2-phase create-new + deploy + revoke-old ou immediate (risque coupure outbound email transitoire) ?
4. **OAuth Google/Azure rotation** : accept invalidation sessions PROD + window operation ?
5. **GHCR PAT rotation** : harmoniser naming ghcr-cred / ghcr-secret avant rotation ? Rotation atomique 12 namespaces ?
6. **Ads tokens (Google/Meta)** : rotation = re-authentication OAuth flow + tenant impact, scope DEV-first ?
7. **Shopify ENCRYPTION_KEY** : BLOCKER (chiffrement shop tokens DB) - decision : skip / dual-read design / scope rotation reduit a CLIENT_SECRET only ?
8. **Amazon SP-API** : re-consent par tenant Seller Central + AWS IAM rotation - window operation + coordination Ludovic ?
9. **Octopia / 17track** : portal access OK ? rotation simple ?
10. **LLM/AI cleanup doublons** : supprimer keybuzz-litellm (api-dev+prod) + litellm-db-secret (keybuzz-ai) + litellm-runtime-key (orphelin) avant rotation OpenAI/Anthropic/Gemini ?
11. **keybuzz-ads-encryption** : decision strategique skip / dual-read / vidage dataset ?
12. **5 orphelins detectes** : vault-emergency-token (conserver break-glass?) + keybuzz-api-postgres-static (conserver backup?) + keybuzz-api-auth (cleanup obsolete) + keybuzz-octopia (cleanup doublon ESO) + litellm-runtime-key (cleanup orphelin) - actions per secret ?
13. **inbound-webhook-key PROD** : migrer vers ESO ou laisser separe (depends process emetteur webhook PROD) ?
14. **STRIPE_PRICE_* + AZURE_AD_TENANT_ID + META_AD_ACCOUNT_ID + LLM_MAX_TOKENS/MODEL/PROVIDER/TEMPERATURE/TIMEOUT_MS/PIPELINE_MODE + NEXTAUTH_URL + URLs publiques** : deplacer ConfigMap (non-secret) ou laisser dans Secret ?
15. **Studio-api scope KEY-323** : inclure dans Q-1B-3E migration ESO ou phase dediee ?
16. **Window operation Q-1B-3B/3C/3D** : preferences horaires ?
17. **Mode B SAFE pattern** : confirme reutilisation pattern Q-1B-2B (Ludovic Mode A creation policy + token rotator + CE Mode B SAFE execution avec STOP gates) ?
18. **Validation Q-1F-3 scope** : tests par domaine apres chaque batch ?

## 15. Gaps / blockers

| Gap | Severity | Status | Decision needed |
|---|---|---|---|
| keybuzz-ads-encryption durable | P0 BLOCKER | observe Category I | strategie Ludovic skip/dual-read/vidage |
| Shopify ENCRYPTION_KEY | P0 BLOCKER | observe | scope reduit ou dual-read design |
| 5 secrets orphelins | P2 cleanup | observe | decisions per secret |
| Doublons LLM (litellm/keybuzz-litellm/litellm-db-secret) | P1 confusion | observe | cleanup avant rotation Q-1B-5 |
| inbound-webhook-key PROD divergence DEV ESO | P1 architecture | observe | migration ESO ou separation maintenue |
| GHCR naming ghcr-cred vs ghcr-secret | P2 consistency | observe | harmonisation avant Q-1B-3D rotation |
| keybuzz-api-auth orphelin (potentiel doublon ESO keybuzz-api-jwt) | P2 cleanup | observe | confirmation cleanup ou usage cache |
| keybuzz-api-postgres-static backup statique | P2 known | observe | conserver pour resilience ou migrer ConfigMap reference |
| vault-emergency-token break-glass | P2 known | observe | documenter usage ou cleanup |
| Linear connector unavailable cote CE | P3 | observe | Codex postera comment final |
| backfill-scheduler ImagePullBackOff dev+prod | P1 pre-existant | hors scope Q-1B-3A | phase dediee future |

## 16. Compliance interdits

| Interdit Q-1B-3A | Respect | Evidence |
|---|---|---|
| vault kv get/put/patch/delete/destroy/rollback | OK aucun | utilise uniquement vault status |
| vault token create/revoke | OK aucun | rotator Q-1B-2B deja revoque, pas de creation |
| vault policy write/delete | OK aucun | |
| kubectl apply/patch/edit/set/delete/create/annotate/rollout restart | OK aucun | uniquement kubectl get + describe metadata + logs |
| kubectl get secret -o yaml/json complet | OK aucun | jq filter strict (managed, type, created, rv, keys names only) |
| base64 -d | OK aucun | |
| Provider externe call (Stripe/SES/Slack/GHCR/Google/Azure/Ads/Shopify/Octopia/17track/Amazon/OpenAI/Anthropic/Gemini) | OK aucun | |
| Webhook mutationnel | OK aucun | |
| Build/deploy/docker push | OK aucun | |
| Modification source applicatif | OK aucun | grep read-only uniquement |
| Modification manifest | OK aucun | |
| Fake metric/event | OK aucun | |
| Affichage secret/token/JWT/cookie/base64/KV value/API key/OAuth secret/password | OK aucun | redacts partout |
| Bastion install-v3 only | OK |  |
| /opt/keybuzz/credentials/ non touche | OK |  |
| /opt/keybuzz/secrets/ non touche | OK |  |
| Read-only strict (sauf rapport docs-only) | OK |  |
| ASCII strict rapport | a verifier post-Write |  |
| STOP avant commit/push | OK E13 STOP |  |

## 17. Brouillon Linear KEY-323 (a poster par Codex apres commit)

```
AS.17.1Q-1B-3A provider/manual secrets inventory read-only COMPLETE

Commit rapport Q-1F-2 : 9d82413 (PROD internal rotation stability validation)
Commit rapport Q-1B-3A : <CE remplira apres push>
Verdict : GO Q-1B-3A PROVIDER INVENTORY READY.

Resume technique :
- 30 ExternalSecrets cartographies sur 11 namespaces vers 35 paths Vault KV uniques (matches Q-1B-0).
- 125 K8s Secrets identifies : 28 ESO + 12 imagePull + 61 manual + 14 TLS + 10 helm.
- 47 manual secrets significatifs DEV+PROD (apres exclusion observability + vault-tokens auto-CronJob + TLS + helm + SA-token).
- Source grep 5 repos confirme runtime usage par fichier source pour 9 providers (Stripe billing, SES email, Google Ads, Meta Ads, Amazon SP-API marketplaces+messaging, Shopify routes+webhook+auth, Octopia auth+routes+workers, 17track tracking, ADS_ENCRYPTION ads-crypto).
- 5 secrets manuels ORPHELINS detectes sans workload reference :
  - vault-emergency-token (api-dev, break-glass probable)
  - keybuzz-api-postgres-static (api-dev, backup statique probable)
  - keybuzz-api-auth (api-dev, obsolete doublon ESO keybuzz-api-jwt)
  - keybuzz-octopia (api-dev, obsolete doublon ESO octopia-credentials)
  - litellm-runtime-key (keybuzz-ai, usage non clair)
- Classification A-J produite :
  - A internal generated rotated Q-1B-1B/Q-1B-2B (jwt/cookie/nextauth/internal-tokens)
  - B provider externe high-risk (Stripe/SES/Meta Ads/Google Ads/Slack) -> Q-1B-3B
  - C OAuth login (Google/Azure secrets DEV+PROD) -> Q-1B-3C
  - D marketplace OAuth (Amazon SP-API/Shopify/Octopia/17track) -> Q-1B-6
  - E infra direct (Redis/Postgres/MinIO/SMTP) -> Q-1B-4
  - F LLM/AI (LITELLM/OpenAI/Anthropic/Gemini) -> Q-1B-5
  - G manual internal candidat migration ESO (internal-proxy/inbound-webhook-key PROD/admin-v2-auth/admin-v2-stripe/studio-api-{auth,db}) -> Q-1B-3E
  - H imagePull GHCR (12 namespaces, 2 conventions naming) -> Q-1B-3D
  - I encryption durable (keybuzz-ads-encryption) -> BLOCKER strategique
  - J non-secret IDs/config (Stripe prices, URLs publiques, OAuth client IDs, Azure tenant ID, Meta ad account ID, LLM config) -> exclude rotation, deplacer ConfigMap
- Decisions Ludovic requises : 18 items (cf section 14 rapport).
- AI feature parity matrix : 10 features impactees identifiees avec validation future par batch.
- Conformite : 0 secret/token/value affiche, 0 provider externe call, 0 mutation, 0 build/deploy/restart.

Gaps :
- keybuzz-ads-encryption durable BLOCKER (decision strategique skip/dual-read/vidage)
- Shopify ENCRYPTION_KEY BLOCKER (scope reduit ou dual-read design)
- 5 orphelins cleanup decisions
- Doublons LLM (litellm/keybuzz-litellm/litellm-db-secret) cleanup avant Q-1B-5
- inbound-webhook-key PROD divergence DEV ESO
- GHCR naming inconsistency harmonisation avant Q-1B-3D
- backfill-scheduler ImagePullBackOff hors scope

Next steps :
- Decisions Ludovic 18 items
- Q-1B-3B EXEC provider low-risk (Stripe TEST + SES + Ads + Slack) post-decisions
- Q-1B-3C OAuth Google/Azure
- Q-1B-3D GHCR rotation
- Q-1B-3E manual->ESO migration + orphelins cleanup
- Q-1B-4 infra direct
- Q-1B-5 LLM/AI
- Q-1B-6 marketplace OAuth
- Q-1F-3 validation cumulee

NO GO Q-1B-3B EXEC, Q-1B-4, Q-1B-5, Q-1B-6 et PROD promotion AS.17.0/AS.17.0.1 maintenus.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

STOP final : rapport pret, en attente GO Ludovic commit/push E13.

Aucun enchainement sur Q-1B-3B EXEC.
Aucun enchainement sur Q-1B-4/5/6.
Aucun enchainement sur PROD promotion AS.17.0/AS.17.0.1.
