# PH-WEBSITE-T8.12AS.17.1Q-1B-0-KEY-323-KV-SECRETS-ROTATION-PLAN-READONLY-01

> Date : 2026-05-16
> Linear : KEY-323
> Phase : AS.17.1Q-1B-0 read-only KV secrets rotation plan
> Environnement : Vault HA Raft + Kubernetes + External Secrets Operator + apps DEV/PROD
> Bastion : install-v3 (46.62.171.61)

## 1. VERDICT

GO KV ROTATION PLAN READY.

Inventaire complet realise sans aucune lecture de valeur secret. 30 ExternalSecrets cartographies sur 10 namespaces vers 35 paths Vault KV uniques. 29 K8s Secrets ESO-managed identifies (metadata + key names seulement). 72 workload refs secrets mappees (envFrom, envSecret, volumes, imagePullSecrets). 17+ secrets crees manuellement hors ESO documentes en Category E. Classification A/B/C/D/E produite. Batch plan Q-1B-1 a Q-1B-7 propose. Policy temporaire keybuzz-kv-rotator-q1b-temp designee sans creation. Validation Q-1F definie par domaine. Brouillon Linear KEY-323 pret pour Codex.

Phrase cible :
GO KV ROTATION PLAN READY. AS.17.1Q-1B-0 read-only complete : ExternalSecrets/K8s Secret metadata/workload refs/code env usage mapped sans valeur secrete, classification A/B/C/D/E produite, batch plan Q-1B-1..Q-1B-7 pret, future policy keybuzz-kv-rotator designee sans creation, validation Q-1F definie. Aucun secret lu ou affiche. Rapport PH pret/commit selon GO. Brouillon Linear KEY-323 pret. NO GO rotation effective jusqu'a GO separe. NO GO PROD promotion maintenu.

## 2. Scope / hors scope

### Scope (read-only)

- Inventaire ExternalSecrets/Secrets/workloads/code env.
- Classification rotation par categorie.
- Plan executable par lots avec blast radius et rollback.
- Design policy keybuzz-kv-rotator-q1b-temp.
- Plan validation Q-1F par domaine.
- Rapport docs-only ASCII strict.

### Hors scope strict

- Aucune lecture valeur KV Vault.
- Aucun vault kv get/put/patch/write.
- Aucune creation policy/token Vault.
- Aucune utilisation vault-admin-token pour ecrire KV.
- Aucune modification ExternalSecret / Secret K8s.
- Aucun rollout / restart / deploy.
- Aucun appel provider externe.
- Aucune promotion PROD AS.17.0 / AS.17.0.1.
- Investigation backfill-scheduler ImagePullBackOff (gap connu hors scope).

## 3. Context commit chain (KEY-323)

| Sequence | Commit | Rapport |
|---|---|---|
| AS.17.0.1-RCA | a486ee8 | contact sendEmail RCA DEV+PROD |
| AS.17.1 | aef393a | emailService contact remediation audit |
| AS.17.1B | 7708a83 | SMTP B1 mail.keybuzz remediation |
| AS.17.1O-D-E-F-N | 9956506 | Hetzner control plane audit |
| AS.17.1H | 1bf9387 | Postgres rescue forensic |
| AS.17.1N-bis | c32eeb9 | SSH authorized_keys forensic post-restore |
| AS.17.1Q-0 | e6e0f26 | secrets exposure inventory read-only |
| AS.17.1Q-1A | b27e94a | Vault verification rotation design read-only |
| AS.17.1Q-1A-bis | 1064c6e | Vault admin token replacement design |
| AS.17.1Q-1A-bis-exec | 346b17a | Vault admin token replacement execution Mode B SAFE |

## 4. PHASE E0 - Preflight observe

| Check | Resultat |
|---|---|
| Bastion identite | install-v3 / 46.62.171.61 |
| Date UTC | 2026-05-16 14:56 |
| Date Paris | 2026-05-16 16:56 CEST |
| Git keybuzz-infra HEAD | 346b17a (Q-1A-bis-exec) clean |
| Fichiers sensibles temp | tous absents |
| Vault 3 nodes | unsealed, Raft 1125113/1125113 sync, vault-03 active leader |
| K8s nodes | 8 nodes Ready (k8s-worker-03 SchedulingDisabled), v1.30.14 |
| ESO pods | 3/3 Running 0 restart |
| vault-management cronjobs | monitoring-alerts + vault-token-renew actifs |
| ExternalSecrets total | 30/30 SecretSynced=True |

| Repo | Branch | HEAD | Dirty | Notes |
|---|---|---|---|---|
| keybuzz-infra | main | 346b17a | 0 | clean post Q-1A-bis-exec push |
| keybuzz-api | ph147.4/source-of-truth | 7a09c005 | 223 | dirty connu prior sessions, ne pas commit ici |
| keybuzz-backend | main | b183817 | 1 | 1 fichier dirty, hors scope phase |
| keybuzz-client | ph148/onboarding-activation-replay | 3fe90ab | 0 | clean |
| keybuzz-admin-v2 | main | 3707c83 | 0 | clean |
| keybuzz-website | main | f5c2b26 | 0 | clean |

## 5. PHASE E1 - ExternalSecrets inventory metadata (30 items)

Liste complete (Store=vault-backend ClusterSecretStore sauf mention) :

| Namespace | ExternalSecret | Store | Target Secret | Refresh | Ready |
|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | vault-backend | keybuzz-admin-v2-bootstrap | 1h | True |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-postgres | vault-backend | keybuzz-admin-v2-postgres | 1h | True |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | vault-backend | keybuzz-admin-v2-bootstrap | 1h | True |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | vault-backend | keybuzz-admin-v2-postgres | 1h | True |
| keybuzz-ai | litellm-secrets | vault-backend | litellm-secret | 1h | True |
| keybuzz-api-dev | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | True |
| keybuzz-api-dev | keybuzz-api-postgres-admin | vault-backend-database | keybuzz-api-postgres-admin | 1h | True |
| keybuzz-api-dev | keybuzz-api-postgres-kv | vault-backend | keybuzz-api-postgres | 5m | True |
| keybuzz-api-dev | keybuzz-db-migrator | vault-backend | keybuzz-db-migrator | 1h | True |
| keybuzz-api-dev | keybuzz-litellm-secrets | vault-backend | keybuzz-litellm-secrets | 1h | True |
| keybuzz-api-dev | keybuzz-ses-secrets | vault-backend | keybuzz-ses | 1h | True |
| keybuzz-api-dev | keybuzz-stripe-secrets | vault-backend | keybuzz-stripe | 1h | True |
| keybuzz-api-dev | minio-credentials | vault-backend | minio-credentials | 1h | True |
| keybuzz-api-dev | octopia-credentials | vault-backend | octopia-credentials | 1h | True |
| keybuzz-api-dev | redis-credentials | vault-backend | redis-credentials | 1h | True |
| keybuzz-api-prod | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | True |
| keybuzz-api-prod | keybuzz-api-postgres | vault-backend | keybuzz-api-postgres | 5m | True |
| keybuzz-api-prod | minio-credentials | vault-backend | minio-credentials | 1h | True |
| keybuzz-api-prod | octopia-credentials | vault-backend | octopia-credentials | 1h | True |
| keybuzz-api-prod | redis-credentials | vault-backend | redis-credentials | 1h | True |
| keybuzz-backend-dev | keybuzz-backend-db | vault-backend | keybuzz-backend-db | 1h | True |
| keybuzz-backend-dev | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | True |
| keybuzz-backend-prod | keybuzz-backend-db | vault-backend | keybuzz-backend-db | 1h | True |
| keybuzz-backend-prod | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | True |
| keybuzz-client-dev | keybuzz-auth-secrets | vault-backend | keybuzz-auth | 1h | True |
| keybuzz-client-dev | minio-credentials | vault-backend | minio-credentials | 1h | True |
| keybuzz-client-prod | keybuzz-auth-secrets | vault-backend | keybuzz-auth-secrets | 1h | True |
| keybuzz-seller-dev | seller-api-postgres | vault-backend | seller-api-postgres | 1h | True |
| observability | alerting-slack-dev | vault-backend | alerting-slack-dev | 1h | True |
| observability | alerting-smtp-dev | vault-backend | alerting-smtp-dev | 1h | True |

### Paths Vault KV uniques (35)

KV v2 abstrait sous mount secret/ :
- database/creds/keybuzz-admin (Database Secrets Engine dynamic)
- keybuzz/admin-v2/bootstrap
- keybuzz/admin-v2/postgres
- keybuzz/admin-v2/postgres-prod
- keybuzz/dev/backend-jwt
- keybuzz/dev/backend-postgres
- keybuzz/dev/backend-product-db
- keybuzz/dev/inbound-webhook
- keybuzz/dev/jwt
- keybuzz/internal-tokens
- keybuzz/minio
- keybuzz/observability/slack/dev
- keybuzz/observability/smtp/dev
- keybuzz/prod/backend-jwt
- keybuzz/prod/backend-postgres
- keybuzz/prod/backend-product-db
- keybuzz/prod/jwt
- keybuzz/prod/octopia
- keybuzz/redis

KV v2 chemin explicite avec data/ :
- secret/data/keybuzz/dev/api-postgres
- secret/data/keybuzz/dev/seller-api-postgres
- secret/data/keybuzz/minio

KV v2 chemin sans data/ :
- secret/keybuzz/ai/anthropic_api_key
- secret/keybuzz/ai/openai_api_key
- secret/keybuzz/auth
- secret/keybuzz/dev/db_migrator
- secret/keybuzz/dev/octopia
- secret/keybuzz/litellm/database_url
- secret/keybuzz/litellm/master_key
- secret/keybuzz/litellm/use_prisma_migrate
- secret/keybuzz/prod/auth
- secret/keybuzz/prod/db_api
- secret/keybuzz/prod/minio
- secret/keybuzz/ses
- secret/keybuzz/stripe

Note observee : incoherence de convention de chemin (avec/sans prefix secret/, avec/sans data/) entre ExternalSecrets. ESO normalise via le store mount. A documenter en Gap pour Q-1B-1 consolidation possible.

## 6. PHASE E2 - K8s Secret metadata + key names (29 ESO-managed)

| Namespace | Secret | Type | Created | RV | Keys |
|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | Opaque | 2026-03-13 | 60743650 | ADMIN_BOOTSTRAP_EMAIL, ADMIN_BOOTSTRAP_PASSWORD_HASH |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-postgres | Opaque | 2026-03-13 | 37332181 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | Opaque | 2026-03-13 | 37239641 | ADMIN_BOOTSTRAP_EMAIL, ADMIN_BOOTSTRAP_PASSWORD_HASH |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | Opaque | 2026-03-13 | 37342023 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-ai | litellm-secret | Opaque | 2025-12-14 | 31857794 | ANTHROPIC_API_KEY, DATABASE_URL, LITELLM_DATABASE_URL, LITELLM_MASTER_KEY, OPENAI_API_KEY, USE_PRISMA_MIGRATE |
| keybuzz-api-dev | keybuzz-api-jwt | Opaque | 2026-02-06 | 31857798 | COOKIE_SECRET, JWT_SECRET |
| keybuzz-api-dev | keybuzz-api-postgres | Opaque | 2026-01-08 | 31857810 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-api-dev | keybuzz-api-postgres-admin | Opaque | 2026-02-06 | 25982539 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-api-dev | keybuzz-db-migrator | Opaque | 2026-01-14 | 31857815 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-api-dev | keybuzz-litellm-secrets | Opaque | 2026-01-14 | 31857821 | LITELLM_MASTER_KEY |
| keybuzz-api-dev | keybuzz-ses | Opaque | 2026-01-07 | 31857825 | AWS_SES_ACCESS_KEY_ID, AWS_SES_FROM_EMAIL, AWS_SES_REGION, AWS_SES_SECRET_ACCESS_KEY |
| keybuzz-api-dev | keybuzz-stripe | Opaque | 2026-01-07 | 46138570 | API_BASE_URL, APP_BASE_URL, STRIPE_PRICE_* (8 prix), STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET |
| keybuzz-api-dev | minio-credentials | Opaque | 2026-01-15 | 31857833 | MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_REGION, MINIO_SECRET_KEY |
| keybuzz-api-dev | octopia-credentials | Opaque | 2026-01-29 | 31857837 | OCTOPIA_API_URL, OCTOPIA_AUTH_URL, OCTOPIA_CLIENT_ID, OCTOPIA_CLIENT_SECRET |
| keybuzz-api-dev | redis-credentials | Opaque | 2026-03-12 | 36935334 | REDIS_PASSWORD, REDIS_URL |
| keybuzz-api-prod | keybuzz-api-jwt | Opaque | 2026-02-06 | 31857841 | COOKIE_SECRET, JWT_SECRET |
| keybuzz-api-prod | keybuzz-api-postgres | Opaque | 2026-02-01 | 31857848 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-api-prod | minio-credentials | Opaque | 2026-01-20 | 31857851 | access-key, secret-key |
| keybuzz-api-prod | octopia-credentials | Opaque | 2026-03-12 | 36935366 | OCTOPIA_API_URL, OCTOPIA_AUTH_URL, OCTOPIA_CLIENT_ID, OCTOPIA_CLIENT_SECRET |
| keybuzz-api-prod | redis-credentials | Opaque | 2026-03-12 | 36935340 | REDIS_PASSWORD, REDIS_URL |
| keybuzz-backend-dev | keybuzz-backend-db | Opaque | 2026-01-08 | 31857856 | DATABASE_URL, PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-backend-dev | keybuzz-backend-secrets | Opaque | 2026-03-12 | 36935347 | INBOUND_WEBHOOK_KEY, JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_SECRET_KEY, PRODUCT_DATABASE_URL |
| keybuzz-backend-prod | keybuzz-backend-db | Opaque | 2026-02-08 | 38404701 | DATABASE_URL, PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| keybuzz-backend-prod | keybuzz-backend-secrets | Opaque | 2026-03-12 | 36935360 | JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_SECRET_KEY, PRODUCT_DATABASE_URL |
| keybuzz-client-dev | keybuzz-auth | Opaque | 2026-01-07 | 31857863 | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET, NEXTAUTH_URL |
| keybuzz-client-dev | minio-credentials | Opaque | 2026-01-15 | 31857867 | MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_REGION, MINIO_SECRET_KEY |
| keybuzz-client-prod | keybuzz-auth-secrets | Opaque | 2026-01-20 | 40891619 | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET |
| keybuzz-seller-dev | seller-api-postgres | Opaque | 2026-01-30 | 31857879 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER |
| observability | alerting-slack-dev | Opaque | 2026-01-03 | 31857886 | channel, webhook_url |
| observability | alerting-smtp-dev | Opaque | 2026-01-03 | 31857892 | from, host, password, port, require_tls, to_default, username |

Observation : zero valeur secret affichee. Type Opaque uniforme. Aucune base64 lue.

### Secrets crees manuellement HORS ESO (Category E candidates)

Decouverts via mapping E3, present cote runtime mais sans ExternalSecret correspondante :

| Namespace | Secret | Age | Notes |
|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-auth | 64d | auth admin-v2 (probable NextAuth/JWT manual) |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-auth | 64d | idem PROD |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-stripe | 11d | Stripe creds admin-v2 manual |
| keybuzz-api-dev | keybuzz-ads-encryption | 23d | clef chiffrement ads dataset |
| keybuzz-api-prod | keybuzz-ads-encryption | 23d | idem PROD |
| keybuzz-api-dev | keybuzz-google-ads | 17d | Google Ads OAuth manual |
| keybuzz-api-prod | keybuzz-google-ads | 17d | idem PROD |
| keybuzz-api-prod | keybuzz-meta-ads | 25d | Meta/Facebook Ads OAuth manual |
| keybuzz-api-dev | keybuzz-shopify | 37d | Shopify OAuth manual |
| keybuzz-api-prod | keybuzz-shopify | 36d | idem PROD |
| keybuzz-api-dev | keybuzz-litellm | 94d | LiteLLM connector manual (different from keybuzz-litellm-secrets ESO) |
| keybuzz-api-prod | keybuzz-litellm | 94d | idem PROD |
| keybuzz-backend-dev | keybuzz-internal-proxy | 87d | proxy token cross-service manual |
| keybuzz-backend-prod | keybuzz-internal-proxy | 87d | idem |
| keybuzz-client-dev | keybuzz-internal-proxy | 87d | idem |
| keybuzz-client-prod | keybuzz-internal-proxy | 87d | idem |
| keybuzz-api-dev | tracking-17track | 46d | 17track API token manual |
| keybuzz-api-prod | tracking-17track | 46d | idem PROD |
| keybuzz-backend-dev | amazon-spapi-creds | 128d | Amazon SP-API creds manual |
| keybuzz-backend-prod | amazon-spapi-creds | 95d | idem PROD |
| keybuzz-backend-prod | inbound-webhook-key | 95d | PROD different layout vs DEV (DEV via ESO keybuzz-backend-secrets) |
| keybuzz-ai | litellm-db-secret | 154d | LiteLLM DB creds manual (probable doublon avec ESO litellm-secret) |
| keybuzz-studio-api-dev | keybuzz-studio-api-auth/db/llm | 40-43d | Studio API trois secrets manual |
| keybuzz-studio-api-prod | keybuzz-studio-api-auth/db/llm | 40-43d | idem PROD |

## 7. PHASE E3 - Workload usage mapping (72 refs)

Resume par workload critique (extrait, full liste sur runtime) :

| Namespace | Workload | Kind | Secret refs |
|---|---|---|---|
| keybuzz-api-dev | keybuzz-api | Deployment | envSecret: keybuzz-ads-encryption, keybuzz-api-jwt, keybuzz-api-postgres, keybuzz-google-ads, keybuzz-litellm, keybuzz-shopify, keybuzz-stripe, minio-credentials, redis-credentials, tracking-17track, vault-root-token + imagePull: ghcr-cred + volume: keybuzz-api-postgres |
| keybuzz-api-dev | keybuzz-outbound-worker | Deployment | envFrom: keybuzz-api-postgres, keybuzz-ses |
| keybuzz-api-prod | keybuzz-api | Deployment | envSecret: keybuzz-ads-encryption, keybuzz-api-jwt, keybuzz-api-postgres, keybuzz-google-ads, keybuzz-litellm, keybuzz-meta-ads, keybuzz-shopify, keybuzz-stripe, minio-credentials, redis-credentials, tracking-17track, vault-root-token + imagePull: ghcr-cred |
| keybuzz-api-prod | keybuzz-outbound-worker | Deployment | envFrom: keybuzz-api-postgres, keybuzz-ses + envSecret: minio-credentials, octopia-credentials |
| keybuzz-backend-dev | keybuzz-backend | Deployment | envFrom: amazon-spapi-creds, keybuzz-backend-db, keybuzz-backend-secrets, vault-token + envSecret: keybuzz-internal-proxy, vault-app-token |
| keybuzz-backend-prod | keybuzz-backend | Deployment | envFrom: amazon-spapi-creds, inbound-webhook-key, keybuzz-backend-db, keybuzz-backend-secrets, vault-token + envSecret: keybuzz-internal-proxy, vault-app-token |
| keybuzz-backend dev/prod | amazon-orders-worker, amazon-items-worker | Deployment | envSecret: keybuzz-backend-db, vault-token |
| keybuzz-client dev/prod | keybuzz-client | Deployment | envSecret: keybuzz-auth (DEV) / keybuzz-auth-secrets (PROD) |
| keybuzz-admin-v2 dev/prod | keybuzz-admin-v2 | Deployment | envSecret: keybuzz-admin-v2-auth, keybuzz-admin-v2-bootstrap, keybuzz-admin-v2-postgres, keybuzz-admin-v2-stripe (DEV) |
| keybuzz-ai | litellm | Deployment | envFrom: litellm-db-secret, litellm-secret |
| keybuzz-seller-dev | seller-api | Deployment | envSecret: seller-api-postgres |
| keybuzz-studio-api dev/prod | keybuzz-studio-api | Deployment | envFrom: keybuzz-studio-api-llm + envSecret: keybuzz-studio-api-auth, keybuzz-studio-api-db |
| keybuzz-backend dev/prod | backfill-scheduler | Deployment | envFrom: keybuzz-backend-db (ImagePullBackOff pre-existant, hors scope) |
| vault-management | monitoring-alerts (CronJob+Jobs) | CronJob/Job | envSecret: monitoring-webhook |
| observability | alertmanager | StatefulSet | volume: alerting-slack-dev, alerting-smtp-dev (parmi autres TLS configs) |

CronJobs et Jobs nombreux (sla-evaluator, outbound-tick-processor, amazon-orders-backfill/sync, carrier-tracking-poll, trial-lifecycle-dryrun, monitoring-alerts) consomment principalement keybuzz-api-postgres, keybuzz-internal-proxy, keybuzz-api-jwt et postgres images.

## 8. PHASE E4 - Code env-var usage (sample observe)

Repo keybuzz-api (ph147.4/source-of-truth) : env-vars observees par grep process.env :

Domaines confirmes :
- DB : PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
- Crypto/Auth : JWT_SECRET, COOKIE_SECRET, VAULT_ADDR, VAULT_TOKEN
- MinIO : MINIO_BUCKET_ATTACHMENTS, MINIO_SECRET_KEY
- AI : LITELLM_MASTER_KEY, LITELLM_BASE_URL, AI_REAL_EXECUTION_ENABLED, AI_CONNECTOR_CUSTOMER_INTERACTION_ENABLED, AI_PROVIDER, AI_REAL_EXECUTION_TENANTS
- Providers : SHOPIFY_CLIENT_SECRET, OCTOPIA_AUTH_URL, OCTOPIA_API_URL, AMAZON_SPAPI_CLIENT_ID, AMAZON_SPAPI_CLIENT_SECRET, UPS_CLIENT_ID, UPS_CLIENT_SECRET, OUTBOUND_CONVERSIONS_WEBHOOK_URL, OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
- Tracking : TRACKING_*
- Mail : SMTP_HOST, SMTP_FROM
- Runtime : NODE_ENV, CORS_ORIGINS, WORKER_VERSION, PH

Observation : la totalite des secrets references par process.env est couverte soit par ExternalSecret (E1), soit par secret manuel (E2 Category E). Une analyse exhaustive par repo (api, backend, client, admin-v2, website) est differee en Q-1B-1 prep si necessaire.

## 9. PHASE E5 - Classification A/B/C/D/E

### Category A - KV-only internal generated (regenerable Vault seul)

Rotation = generation aleatoire Vault + write KV + ESO refresh + reloader restart. Pas de service externe a synchroniser. Attention sessions/cookies si applicable.

| Path Vault KV | Keys logiques | Impact rotation | Batch |
|---|---|---|---|
| keybuzz/dev/jwt | JWT_SECRET, COOKIE_SECRET | invalide sessions DEV (testers seulement) | Q-1B-1 |
| keybuzz/prod/jwt | JWT_SECRET, COOKIE_SECRET | invalide sessions PROD (aucun client reel actuellement) | Q-1B-2 |
| keybuzz/dev/backend-jwt | JWT_SECRET (backend) | invalide tokens internes DEV | Q-1B-1 |
| keybuzz/prod/backend-jwt | JWT_SECRET (backend) | invalide tokens internes PROD | Q-1B-2 |
| keybuzz/dev/inbound-webhook | INBOUND_WEBHOOK_KEY | invalide webhooks entrants DEV (verif test seulement) | Q-1B-1 |
| keybuzz/internal-tokens | KEYBUZZ_INTERNAL_TOKEN | invalide proxy cross-service, attention coherence DEV+PROD (path partage) | Q-1B-2 |
| keybuzz/admin-v2/bootstrap (password_hash) | ADMIN_BOOTSTRAP_PASSWORD_HASH | re-bootstrap admin local seul (Ludovic), email inchange | Q-1B-2 |
| secret/keybuzz/auth (nextauth_secret) | NEXTAUTH_SECRET (DEV portion) | invalide sessions client DEV | Q-1B-1 |
| secret/keybuzz/prod/auth (NEXTAUTH_SECRET) | NEXTAUTH_SECRET (PROD portion) | invalide sessions client PROD | Q-1B-2 |
| secret/keybuzz/litellm/master_key | LITELLM_MASTER_KEY | requis coherent entre litellm-secret (keybuzz-ai) + keybuzz-litellm-secrets (api-dev). Rotation = stop trafic AI puis redemarre. | Q-1B-5 |

### Category B - KV + service direct (rotation cote service + Vault)

Rotation = nouveau credential cote service + write KV + ESO + restart apps consommatrices. Risque coupure transitoire.

| Path Vault KV | Service | Validation | Batch |
|---|---|---|---|
| keybuzz/redis | Redis (REDIS_PASSWORD) | redis-cli + apps reconnect | Q-1B-4 |
| keybuzz/admin-v2/postgres | Postgres role admin-v2-dev (PGPASSWORD) | psql + admin-v2 reconnect | Q-1B-4 |
| keybuzz/admin-v2/postgres-prod | Postgres role admin-v2-prod | psql + admin-v2 reconnect | Q-1B-4 |
| keybuzz/dev/backend-postgres | Postgres role backend-dev | psql + backend reconnect | Q-1B-4 |
| keybuzz/prod/backend-postgres | Postgres role backend-prod | psql + backend reconnect | Q-1B-4 |
| keybuzz/dev/backend-product-db | Postgres role product-db-dev | psql + backend reconnect | Q-1B-4 |
| keybuzz/prod/backend-product-db | Postgres role product-db-prod | psql + backend reconnect | Q-1B-4 |
| secret/data/keybuzz/dev/api-postgres | Postgres role api-dev | psql + api reconnect | Q-1B-4 |
| secret/keybuzz/prod/db_api | Postgres role api-prod | psql + api reconnect | Q-1B-4 |
| secret/data/keybuzz/dev/seller-api-postgres | Postgres role seller-dev | psql + seller-api reconnect | Q-1B-4 |
| secret/keybuzz/dev/db_migrator | Postgres role db_migrator-dev | reserve job ponctuel | Q-1B-4 |
| secret/keybuzz/litellm/database_url | Postgres role litellm | psql + litellm reconnect | Q-1B-4 |
| keybuzz/minio + secret/data/keybuzz/minio + secret/keybuzz/prod/minio | MinIO access/secret keys | mc admin user + apps reconnect | Q-1B-4 |
| keybuzz/observability/smtp/dev | SMTP creds (probable mail.keybuzz.io local) | alertmanager test | Q-1B-4 |
| database/creds/keybuzz-admin | Vault Database Engine dynamic | rotation auto par Vault (TTL gere) | N/A auto |

### Category C - Provider external (rotation portail externe)

Rotation = revoke + regenerer cote provider + write KV + restart. Pas d'appel API provider dans Q-1B-0.

| Path Vault KV | Provider | Owner | Batch |
|---|---|---|---|
| secret/keybuzz/ai/openai_api_key | OpenAI Platform | Ludovic console | Q-1B-5 |
| secret/keybuzz/ai/anthropic_api_key | Anthropic Console | Ludovic console | Q-1B-5 |
| secret/keybuzz/stripe (secret_key, webhook_secret) | Stripe Dashboard | Ludovic console (test mode actuellement) | Q-1B-3 |
| secret/keybuzz/ses | AWS SES (access keys) | Ludovic console AWS IAM | Q-1B-3 |
| secret/keybuzz/dev/octopia + keybuzz/prod/octopia | Octopia OAuth | Ludovic portal Octopia | Q-1B-6 |
| secret/keybuzz/auth (google_client_secret, azure_ad_client_secret) | Google Cloud / Azure AD | Ludovic GCP/Azure consoles | Q-1B-3 |
| secret/keybuzz/prod/auth (idem) | idem | idem | Q-1B-3 |
| keybuzz/observability/slack/dev (webhook_url) | Slack webhook | Ludovic Slack app | Q-1B-3 |
| Secret manuel keybuzz-google-ads | Google Ads OAuth | Ludovic Google Ads | Q-1B-3 |
| Secret manuel keybuzz-meta-ads | Meta Marketing API | Ludovic Meta | Q-1B-3 |
| Secret manuel keybuzz-shopify | Shopify Partners | Ludovic Shopify | Q-1B-6 |
| Secret manuel tracking-17track | 17track API | Ludovic 17track portal | Q-1B-3 |
| Secret manuel amazon-spapi-creds | Amazon SP-API | Ludovic Amazon Seller Central + AWS | Q-1B-6 |
| Secret manuel keybuzz-admin-v2-stripe (DEV) | Stripe test | Ludovic Stripe console | Q-1B-3 |
| Secret manuel litellm-db-secret (keybuzz-ai) | LiteLLM DB (probable doublon ESO) | Owner clarification requis | Q-1B-5 |
| imagePullSecrets : ghcr-secret, ghcr-cred | GHCR PAT | Ludovic GitHub | Q-1B-3 |

### Category D - Already rotated / do not rotate now

| Secret | Statut | Source |
|---|---|---|
| vault-management/vault-admin-token | rotated Q-1A-bis-exec (Mode B SAFE) | commit 346b17a, accessor 2JVSfmbKRn...REDACTED |
| keybuzz-api-prod/dev vault-root-token, vault-app-token | recreated R1 par vault-token-renew | accessors 3wjhHVy01J et BdBzLPH4e8 (api + backend auto) |
| keybuzz-backend-prod/dev vault-token, vault-app-token | recreated R1 | idem |
| 2 anciens root tokens Vault | revoked Option C decision Ludovic | vrMCXE0T38 + IE2JZ90CMt |
| ESO ClusterSecretStore Kubernetes auth | SA JWT projected, pas de token statique | role keybuzz-external-secrets + eso-keybuzz |
| TLS certs cert-manager (argocd-*, ingress-nginx-admission, external-secrets-webhook, kube-prometheus-*) | rotation auto cert-manager | hors scope sauf incident |
| litellm-db-secret possible doublon ESO | a decider (Category E) | doublon avec keybuzz-ai/litellm-secret/DATABASE_URL ? |

### Category E - Blocked / owner decision

| Secret/path | Pourquoi blocker | Decision requise |
|---|---|---|
| keybuzz-ads-encryption (api-dev/prod) | clef chiffrement durable de donnees ads dataset | NE PAS rotate sans migration dual-read OU vidage dataset |
| keybuzz-admin-v2-auth (manual) | usage exact non documente (NextAuth? JWT admin?) | Ludovic confirme avant decision |
| keybuzz-internal-proxy (manual, 4 namespaces) | proxy token cross-service, rotation requires synchro 4 namespaces | clarifier owner + sequence atomique |
| keybuzz-studio-api-auth/db/llm (manual) | Studio API hors AS.17.x current scope | Ludovic confirme owner |
| amazon-spapi-creds | provider strict OAuth + LWA refresh tokens | Ludovic decide (deja rotation envisagee post-Hetzner) |
| inbound-webhook-key (PROD layout different DEV) | divergence DEV vs PROD a consolider | option : harmoniser PROD via ESO keybuzz-backend-secrets ? |
| secret/keybuzz/litellm/use_prisma_migrate | config flag, pas un secret -> sortir du scope rotation | reclasse ou ignore |
| Stripe price IDs (8 cles dans secret/keybuzz/stripe) | identifiants publics non secrets -> rotation N/A | NE PAS rotate, garder seulement secret_key + webhook_secret |
| API_BASE_URL + APP_BASE_URL dans keybuzz-stripe | URLs publiques non secretes | retirer du scope rotation |
| monitoring-webhook (vault-management) | webhook Slack/Discord interne | Ludovic confirme provider |

## 10. PHASE E6 - Batch plan Q-1B-1 a Q-1B-7

Principe : DEV avant PROD, internal avant provider, low-risk avant high-risk, GO Ludovic explicite par batch, rollback documente par lot, validation Q-1F par lot.

### Q-1B-1 DEV internal low-risk

Scope :
- keybuzz/dev/jwt (JWT_SECRET, COOKIE_SECRET)
- keybuzz/dev/backend-jwt (JWT_SECRET)
- keybuzz/dev/inbound-webhook (INBOUND_WEBHOOK_KEY)
- secret/keybuzz/auth (nextauth_secret DEV portion)

Mutations requises :
- vault kv put nouveaux secrets generes openssl rand
- ESO refresh (auto via refresh interval 1h ou kubectl annotate force-sync)
- restart deployments concernes (keybuzz-api-dev, keybuzz-client-dev, keybuzz-backend-dev)

Validation Q-1F-1 DEV :
- ExternalSecrets SecretSynced=True post-rotation
- pods Running 1/1 post-restart
- DEV testers logout puis re-login OK
- inbound webhook DEV test endpoint

Rollback :
- Vault KV restore version precedente (`vault kv rollback -version=N path`)
- restart deployments

Owner : CE avec keybuzz-kv-rotator + GO Ludovic. Ludovic genere secrets aleatoires offline si prefere.

GO required : explicite Ludovic apres Q-1B-0 + creation policy keybuzz-kv-rotator-q1b-temp.

### Q-1B-2 PROD internal low-risk

Scope :
- keybuzz/prod/jwt
- keybuzz/prod/backend-jwt
- keybuzz/internal-tokens (PARTAGE DEV+PROD - synchronisation requise)
- secret/keybuzz/prod/auth (NEXTAUTH_SECRET)
- keybuzz/admin-v2/bootstrap (password_hash)

Mutations :
- idem Q-1B-1 mais sur paths PROD
- attention keybuzz/internal-tokens partage : invalide TOUS les proxy cross-service simultanement -> orchestrer restart DEV+PROD ensemble

Validation Q-1F-2 PROD :
- pas de client reel impacte (confirmation Ludovic)
- pods PROD Running 1/1
- workflows cross-service backend<->api OK

Rollback :
- Vault KV rollback (KV v2 supporte versions retention)
- restart deployments

GO required : explicite Ludovic, confirmation absence clients reels actifs.

### Q-1B-3 KV provider references (Stripe, SES, Slack, GHCR, Google/Azure OAuth, Google Ads, Meta Ads, 17track, Stripe admin-v2)

Scope :
- secret/keybuzz/stripe (secret_key + webhook_secret seulement, price IDs preserves)
- secret/keybuzz/ses (AWS SES access keys)
- secret/keybuzz/auth (google_client_secret, azure_ad_client_secret) + prod equivalents
- secret manuel keybuzz-google-ads, keybuzz-meta-ads, tracking-17track, keybuzz-admin-v2-stripe
- ghcr-secret, ghcr-cred (image pull)
- keybuzz/observability/slack/dev (webhook_url)

Mutations :
- Ludovic genere/revoque cote provider (Stripe Dashboard, AWS IAM, GCP, Azure AD, Google Ads, Meta, 17track, GitHub PAT, Slack)
- Ludovic met a jour Vault KV (ou CE via keybuzz-kv-rotator)
- ESO refresh + restart deployments
- Stripe webhook : reconfigurer endpoint si rotation webhook_secret

Validation Q-1F-3 :
- Stripe webhook reception test (Stripe CLI ou Dashboard send test event)
- SES sandbox test send (compte test seulement)
- Slack alert test
- GHCR pull test via image build
- Google/Azure OAuth login test client
- Pas d'appel marketplace prod sans GO

Rollback :
- Provider : restaurer ancien token si encore actif (impossible si revoque)
- Vault KV rollback

GO required : par provider, batched par owner/portal.

### Q-1B-4 Infra direct credentials (Redis, Postgres, MinIO, SMTP)

Scope :
- keybuzz/redis (REDIS_PASSWORD)
- keybuzz/admin-v2/postgres + postgres-prod (PGPASSWORD app role)
- keybuzz/dev/backend-postgres + keybuzz/prod/backend-postgres
- keybuzz/dev/backend-product-db + keybuzz/prod/backend-product-db
- secret/data/keybuzz/dev/api-postgres + secret/keybuzz/prod/db_api
- secret/data/keybuzz/dev/seller-api-postgres
- secret/keybuzz/dev/db_migrator
- secret/keybuzz/litellm/database_url
- keybuzz/minio + secret/data/keybuzz/minio + secret/keybuzz/prod/minio
- keybuzz/observability/smtp/dev

Mutations :
- Redis : ACL SETUSER ou requirepass + restart redis ou config rewrite
- Postgres : ALTER ROLE password (par database keybuzz/keybuzz_backend) - attention dual DB
- MinIO : mc admin user svcacct rotate ou regenerate root creds
- SMTP : depend du provider (mail.keybuzz.io interne ou externe)
- Synchroniser Vault KV avec nouveaux creds
- ESO refresh + restart workloads

Validation Q-1F-4 :
- redis-cli AUTH success
- psql connect par role
- mc alias set + mc ls success
- alertmanager SMTP test
- workers reconnect OK
- pas de timeout Postgres pool reconnect

Rollback :
- service : reset ancien password si possible
- Vault KV rollback
- restart

Risque : coupure transitoire pendant rotation. Lots independants par service.

GO required : par service, runbook detaille par lot.

### Q-1B-5 LLM/AI providers

Scope :
- secret/keybuzz/ai/openai_api_key
- secret/keybuzz/ai/anthropic_api_key
- secret/keybuzz/litellm/master_key (interne, regenerable)
- secret manuel keybuzz-litellm (api-dev/prod) - clarifier doublon vs ESO
- litellm-db-secret (keybuzz-ai) - clarifier doublon

Mutations :
- OpenAI : revoke + new key cote console OpenAI
- Anthropic : revoke + new key cote Anthropic Console
- LiteLLM master key : openssl rand + sync KV + restart litellm + restart api
- Synchroniser litellm-secret (keybuzz-ai/ESO) ET keybuzz-litellm-secrets (api-dev/prod ESO) + secret manuel keybuzz-litellm si encore utilise

Validation Q-1F-5 :
- litellm pod Running 1/1 post-restart
- api pods Running 1/1
- AI features parity : test brouillon IA dry-run DEV (consommation provider) seulement avec GO
- pas d'appel provider non necessaire

Rollback :
- conserver ancien key OpenAI/Anthropic actif jusqu'a validation new key
- Vault KV rollback

GO required : provider keys = Ludovic console. Attention couts.

### Q-1B-6 Marketplace OAuth (Amazon, Shopify, Octopia)

Scope :
- secret manuel amazon-spapi-creds (DEV+PROD)
- secret manuel keybuzz-shopify (DEV+PROD)
- secret/keybuzz/dev/octopia + keybuzz/prod/octopia

Mutations :
- Amazon SP-API : refresh tokens via LWA + AWS IAM rotation - depend marketplace consent flow
- Shopify : rotation app secret depuis Partners Dashboard + re-consent eventuel
- Octopia : OAuth rotation cote portal Octopia

Validation Q-1F-6 :
- workers amazon-orders/items Running 1/1
- backfill scheduler eventuellement (toujours hors scope si ImagePullBackOff)
- API marketplace test endpoint health (sans declencher message client reel)

Rollback :
- conserver ancien token actif si possible
- Vault rollback
- restart

GO required : marketplace = impact tenant connecte, ATTENTION absence client reel actuellement = risque limite, mais coordination par tenant si reconnection requise.

### Q-1B-7 PROD promotion gate

Scope :
- promotion AS.17.0 / AS.17.0.1 PROD apres validation Q-1F sur lots 1-6
- decision finale Ludovic
- ouverture Q-1F (validation cross-domaine integree)

Mutations : aucune ici, c'est un gate.

GO required : Ludovic explicite, conditionne a NO regression cumulee 1-6.

## 11. PHASE E7 - Future policy keybuzz-kv-rotator-q1b-temp (design only)

### Principes

- TTL court : 2h max.
- No root.
- No `auth/token/*` capability.
- No system/.
- No policies/.
- No unseal/seal.
- Pas de read sur valeurs si possible (mais write KV requiert souvent read pour version check) - solution : update + create capabilities sur data paths, list capability sur metadata.
- Limite stricte aux paths Vault necessaires.

### HCL design propose

```hcl
# Policy: keybuzz-kv-rotator-q1b-temp
# Purpose: temporary write capability on KeyBuzz KV paths for Q-1B rotation execution
# Created: future Q-1B execution phase (NOT created in Q-1B-0)
# TTL: 2h short

# Permettre self-lookup pour TTL check
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# KV v2 data paths - update + create pour put/patch nouvelles versions
path "secret/data/keybuzz/dev/jwt" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/prod/jwt" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/dev/backend-jwt" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/prod/backend-jwt" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/dev/inbound-webhook" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/internal-tokens" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/auth" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/prod/auth" { capabilities = ["create", "update"] }
path "secret/data/keybuzz/admin-v2/bootstrap" { capabilities = ["create", "update"] }

# Add only when needed per batch (Q-1B-4 infra) :
# path "secret/data/keybuzz/redis" { capabilities = ["create", "update"] }
# path "secret/data/keybuzz/dev/backend-postgres" { capabilities = ["create", "update"] }
# ... per batch

# KV v2 metadata paths - read/list pour version check, delete pour cleanup tres ancien
path "secret/metadata/keybuzz/*" {
  capabilities = ["read", "list"]
}

# Sys mount info pour ESO refresh check si necessaire (read only)
path "sys/mounts" {
  capabilities = ["read"]
}
```

### Workflow creation (future, NOT in Q-1B-0)

1. Ludovic genere root token temporaire via Shamir generate-root.
2. Ludovic `vault policy write keybuzz-kv-rotator-q1b-temp`.
3. Ludovic `vault token create -policy=keybuzz-kv-rotator-q1b-temp -ttl=2h -orphan -display-name="kv-rotator-q1b-batch-N"`.
4. Stocker token dans `/root/.vault-kv-rotator.tmp` mode 600 root:root.
5. CE Mode B SAFE execute rotation par batch via runner SCP.
6. Apres batch : vault token revoke -self + shred fichier.
7. Ludovic vault token revoke root temp + shred.

### Garde-fous

- TTL 2h auto-expire.
- Paths limites par batch (etendre uniquement si necessaire pour le batch).
- Pas de capability sur `auth/*` (impossible escalation token creation).
- Pas de delete sur data path (rollback via metadata versions).
- Audit Vault doit etre actif (a verifier en E0 future phase).

## 12. PHASE E8 - Validation Q-1F par domaine

| Domaine | Tests obligatoires post-batch | Tests interdits |
|---|---|---|
| Vault/ESO | vault status 3/3 unsealed, ExternalSecrets SecretSynced=True, ESO pods Running, no Vault 403 | rekey, recreate token sans GO |
| Vault token-renew | manual job Complete (filtre logs sans token), accessor count attendu | revoke token sans certitude |
| API DEV | pods Running 1/1, /healthz si existant, no CrashLoop, login/JWT issue test | impacter client reel |
| API PROD | idem mais validation manuelle Ludovic, no client reel actuellement | call provider sans GO |
| Backend DEV+PROD | pods Running, amazon workers Running, no Vault 403 | declencher message reel |
| Client (Next.js) | login Google/Azure OAuth test, NextAuth session test | persister credentials test |
| Admin-v2 | bootstrap login Ludovic test, postgres connect | exposer hash en log |
| Studio + Studio-api | Running 1/1 (hors scope Q-1B sauf E Category) | toucher prod sans GO |
| Seller | seller-api Running, postgres connect | tenant-cross check |
| AI/LiteLLM | litellm pod Running, master_key sync OK, no provider error pod logs | appel API provider non necessaire |
| Inbox/marketplace | workers Running, no fake event, no message client | declencher message OAuth refresh client |
| Billing/Stripe | webhook reception (Stripe CLI test) | live charge, fake event |
| OTP/email | DEV controle GO uniquement | spam PROD |
| Observability | alertmanager Slack/SMTP test (controle) | spam Slack channel prod |
| Tracking 17track | API ping seulement | declencher faux event tracking |
| Image pull GHCR | image pull test via deploy fictif | exposer PAT log |

### Tests anti-regression AI feature parity

- Inbox AI assist/evaluate/execute/guard : ne pas appeler en Q-1B-0 ; lors Q-1B-5 test dry-run brouillon IA seulement avec GO.
- Autopilot : pods Running only, no trigger.
- Channels routing : tenantGuard tests negatifs (Q-1B-0 = read-only, deja valides AS.13.x/AS.14.x).
- Connecteurs Amazon/Shopify/Octopia : Running + no refresh OAuth automatique pendant rotation.

## 13. PHASE E9 - Risk register

| Risk | Severity | Status | Decision needed | Next action |
|---|---|---|---|---|
| KV path convention incoherente (secret/data vs keybuzz/ vs secret/keybuzz/) | P2 | observe | Ludovic decide harmonisation | Q-1B-1 cleanup proposal |
| 17+ secrets manuels non geres par ESO | P1 | observe | Ludovic decide import dans ESO | clarifier owners + plan migration |
| inbound-webhook-key DEV via ESO mais PROD manuel | P1 | observe | Ludovic decide harmonisation | proposer ESO PROD equivalent |
| keybuzz/internal-tokens chemin partage DEV+PROD | P1 | observe | rotation atomique cross-env | sequencer Q-1B-2 + restart synchro |
| keybuzz-ads-encryption durable data key | P0 | blocked | Ludovic decide rotation strategie (dual-read vs vidage dataset vs skip) | hors batch initial |
| litellm-db-secret possible doublon ESO | P2 | unclear | Ludovic clarifie usage | check kubectl describe pods/litellm |
| backfill-scheduler ImagePullBackOff pre-existant 27h | P1 | pre-existant | hors scope Q-1B | phase dediee post Q-1B |
| amazon-spapi-creds + Amazon refresh tokens | P0 | observe | rotation = re-consent par tenant, mais zero client reel actuellement | Q-1B-6 plan synchro Amazon |
| Vault audit log activation a verifier | P1 | non-teste | E0 future phase | check `vault audit list` |
| Postgres dual DB (keybuzz/keybuzz_backend) coherence | P0 | observe (Q-1A-bis verifie) | rotation Postgres = par database | Q-1B-4 runbook par DB |
| Stripe price IDs presents dans secret KV (non-secret) | P3 | observe | NE PAS rotate, optionel deplacer en ConfigMap | hors scope Q-1B |
| GHCR PAT impacte tous imagePullSecrets | P0 | observe | rotation = impact pull simultanee | Q-1B-3 sequence avec image cache verifie |
| Aucun client reel actuellement (RGPD/business) | low | observe | continuer documenter | maintenir |

## 14. Decisions Ludovic requises

Decisions necessaires avant Q-1B-1 execution :

1. **Mode execution Q-1B** : Mode A (Ludovic execute) vs Mode B SAFE (CE runner) ? (recommande Mode B SAFE comme Q-1A-bis-exec).
2. **Creation policy keybuzz-kv-rotator-q1b-temp** : confirmer design HCL section 11, donner GO creation future phase.
3. **Secrets manuels Category E** : owner par secret (keybuzz-ads-encryption, keybuzz-internal-proxy, keybuzz-admin-v2-auth, studio-api-*, monitoring-webhook, amazon-spapi-creds, litellm-db-secret possible doublon).
4. **Harmonisation paths Vault KV** : laisser conventions actuelles OU harmoniser en Q-1B-1 cleanup ?
5. **Migration secrets manuels vers ESO** : import dans ESO en Q-1B-1 OU laisser manuel ?
6. **inbound-webhook-key PROD divergence DEV** : harmoniser ?
7. **keybuzz/internal-tokens cross-env** : accept rotation atomique DEV+PROD synchronisee OU split par env ?
8. **Stripe** : test mode actuel = OK rotation Stripe TEST keys ; LIVE keys rotation differee a post-launch reel.
9. **keybuzz-ads-encryption** : decision rotation strategique (dual-read + migration vs garder ancienne clef si dataset acceptable).
10. **Validation Q-1F scope** : OK plan section 12 ?

## 15. Brouillon Linear KEY-323 (a poster par Codex apres commit)

```
AS.17.1Q-1B-0 KV secrets rotation plan read-only COMPLETE

Commit rapport : <CE remplira apres push>
Verdict : GO KV ROTATION PLAN READY.

Resume technique :
- 30 ExternalSecrets cartographies sur 10 namespaces vers 35 paths Vault KV uniques.
- 29 K8s Secrets ESO-managed identifies (metadata + key names seulement, ZERO valeur affichee).
- 72 workload refs secrets mappees (envFrom, envSecret, volumes, imagePullSecrets).
- 17+ secrets crees manuellement HORS ESO documentes en Category E (keybuzz-ads-encryption, keybuzz-google-ads, keybuzz-meta-ads, keybuzz-shopify, tracking-17track, keybuzz-internal-proxy, amazon-spapi-creds, keybuzz-studio-api-*, etc.).
- Classification A/B/C/D/E produite :
  - A internal generated (JWT, COOKIE_SECRET, NEXTAUTH_SECRET, INBOUND_WEBHOOK_KEY, KEYBUZZ_INTERNAL_TOKEN, LITELLM_MASTER_KEY, admin bootstrap password_hash)
  - B KV + service direct (Redis, Postgres app roles dual DB, MinIO, SMTP)
  - C provider external (Stripe test, AWS SES, OpenAI, Anthropic, Google/Azure OAuth, Octopia, Slack webhook, Google Ads, Meta Ads, Shopify, 17track, Amazon SP-API, GHCR PAT)
  - D already rotated Q-1A-bis-exec/R1 (vault-admin-token, vault-app/root/token)
  - E blocked/owner decision (keybuzz-ads-encryption durable, secrets manuels hors ESO, divergences DEV/PROD)
- Batch plan Q-1B-1 a Q-1B-7 sequence DEV avant PROD, internal avant provider, low-risk avant infra direct.
- Policy keybuzz-kv-rotator-q1b-temp designee sans creation (TTL 2h, paths limites par batch, no auth/* capability).
- Validation Q-1F definie par domaine (Vault/ESO/API/Backend/Client/Admin-v2/AI/Inbox/Billing/OTP/Observability/Tracking/GHCR).
- Risk register 13 risques documentes.
- Aucun secret lu ou affiche pendant le mapping (conformite Q-1B-0 read-only strict).

Decisions Ludovic requises (10 items section 14 du rapport).

Gaps :
- Vault audit log activation a verifier en future phase.
- backfill-scheduler ImagePullBackOff dev+prod pre-existant 27h, hors scope Q-1B.
- PROD promotion AS.17.0 / AS.17.0.1 NO GO maintenu jusqu'a Q-1B-7 gate.

Pas de changement de status KEY-323 ou KEY-322 sans GO supplementaire.
```

## Conformite interdits Q-1B-0

| Interdit | Respect |
|---|---|
| vault kv get/put/patch | OK : aucun |
| vault read/write secret/... | OK : aucun |
| vault policy write | OK : aucun |
| vault token create/revoke | OK : aucun |
| kubectl get secret -o yaml/json complet | OK : seules metadata + keys via jq |
| base64 -d secret data | OK : aucun |
| kubectl logs avec risque token | OK : aucun appel logs sensibles |
| Appel provider externe | OK : aucun |
| Generation/stockage nouvelle valeur secret | OK : aucun |
| Ancien vault-admin-token utilise | OK : non utilise |
| /root/.vault-root-token.tmp | OK : absent depuis Q-1A |
| Bastion install-v3 uniquement | OK |
| credentials/secrets locaux | OK : non touches |
| kubectl patch/edit/set | OK : aucun |
| git push/commit | OK : aucun (STOP E10 GO requis) |

## No fake metrics / no fake events

Aucune metric ou event invente. Toutes observations issues de :
- vault status / vault list (metadata only)
- kubectl get/describe (metadata + keys only)
- jq filtrage strict sans data
- grep code env-var names seulement

Marqueurs explicites utilises : "observe" et "non teste" pour les sections du plan execution future.

## AI feature parity / anti-regression

Cette phase read-only ne touche pas IA. Identifie les secrets AI/LLM dans :
- ESO keybuzz-ai/litellm-secrets (LITELLM_MASTER_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, DATABASE_URL, USE_PRISMA_MIGRATE)
- ESO keybuzz-api-dev/keybuzz-litellm-secrets (LITELLM_MASTER_KEY)
- Secret manuel keybuzz-litellm (api-dev/prod) - possible doublon a clarifier
- Secret manuel litellm-db-secret (keybuzz-ai) - possible doublon
- Secret manuel keybuzz-studio-api-llm (studio-api dev/prod)

Recommandation : Q-1B-5 traitera ces secrets ensemble pour eviter desynchronisation LITELLM_MASTER_KEY entre namespaces.

Aucun appel provider IA dans Q-1B-0. Aucun message client. Aucun workflow declenche.

## STOP final

Rapport complet pret. STOP avant E10 commit + push pour GO Ludovic explicite.

Ne pas enchainer sur Q-1B-1 sans nouveau GO.
Ne pas creer policy keybuzz-kv-rotator-q1b-temp.
Ne pas faire de rotation KV.
Ne pas promotion PROD AS.17.0 / AS.17.0.1.
