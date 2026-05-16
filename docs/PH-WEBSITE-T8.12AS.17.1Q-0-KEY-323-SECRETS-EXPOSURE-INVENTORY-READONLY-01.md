# PH-WEBSITE-T8.12AS.17.1Q-0-KEY-323-SECRETS-EXPOSURE-INVENTORY-READONLY-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1Q-0 secrets exposure inventory read-only
> Environnement : Hetzner KeyBuzz prod + dev - read-only strict

---

## VERDICT

GO SECRETS INVENTORY READY

Inventaire complet effectue cote Kubernetes Secrets metadata (key
names sans valeurs), workload references (envFrom + valueFrom +
imagePullSecrets), GitOps manifests grep, ExternalSecrets
resources, ClusterSecretStores Vault.

Architecture moderne identifiee : **External Secrets Operator + HashiCorp
Vault + ArgoCD + cert-manager + reloader** = source de verite des
secrets centralisee dans Vault, synchronisee automatiquement vers
Kubernetes Secrets.

**Aucune valeur de secret en clair commit dans GitOps** verifie via
grep patterns sensibles : seuls templates `sk_test_REPLACE_ME` et
commentaires d'exemple trouves, pas de fuite reelle.

CronJob `vault-token-renew` automatise deja la rotation des Vault
tokens (period 768h = 32 jours) sur tous les namespaces consommateurs.

Plan rotation prepare en E7-E8 hierarchise :
- Vault root token + unseal keys = decision Ludovic (verification non
  compromis)
- 30+ secrets via ExternalSecrets = rotation centralisee dans Vault
- 15+ secrets PROD non-ExternalSecrets = rotation manuelle sequentielle
- TLS/dockerconfig = standard

Aucune rotation effectuee. Aucune mutation Kubernetes/Vault/services.
Aucune valeur de secret affichee.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu jusqu'a rotation
secrets effective via AS.17.1Q-1.

---

## Resume executif

### Architecture secrets KeyBuzz

| Element | Statut | Notes |
|---|---|---|
| HashiCorp Vault cluster | UP | vault-01 + vault-02 + vault-03 (vault-02 restaure et valide AS.17.1N-bis Lot A) |
| External Secrets Operator | DEPLOYE | namespace external-secrets, ClusterSecretStores `vault-backend` + `vault-backend-database` |
| ExternalSecrets ressources | 30+ actifs | refresh interval 1h ou 5m, status SecretSynced True sur tous |
| ArgoCD GitOps | DEPLOYE | namespace argocd |
| cert-manager | DEPLOYE | letsencrypt-prod + letsencrypt-staging |
| reloader | DEPLOYE | redemarre pods sur changement secret |
| Vault token rotation auto | ACTIF | k8s/vault-token-renew CronJob, period 768h |
| Vault DB dynamic credentials | ACTIF | ClusterSecretStore vault-backend-database (DEV refresh 5m) |
| Secret values in GitOps | NON | grep patterns sensibles = templates seulement |

### Couverture ExternalSecrets per namespace

| Namespace | Secrets totaux Opaque | ExternalSecrets count | Couverture | Manuels restants |
|---|---|---|---|---|
| keybuzz-api-prod | 15 | 5 | 33% | 10 (Stripe, Google Ads, Meta Ads, Shopify, SES, ads-encryption, litellm, 17track, vault tokens) |
| keybuzz-api-dev | 21 | 10 | 48% | 11 (incluant ads-encryption, google-ads, meta-ads, shopify, stripe partial, vault tokens) |
| keybuzz-backend-prod | 7 | 2 | 29% | 5 (amazon-spapi, inbound-webhook, internal-proxy, vault tokens) |
| keybuzz-backend-dev | 6 | 2 | 33% | 4 (amazon-spapi, internal-proxy, vault tokens) |
| keybuzz-admin-v2-prod | 3 | 2 | 67% | 1 (admin-v2-auth) + 1 stripe DEV-only |
| keybuzz-admin-v2-dev | 4 | 2 | 50% | 2 (admin-v2-auth, admin-v2-stripe) |
| keybuzz-client-prod | 2 | 1 | 50% | 1 (internal-proxy) |
| keybuzz-client-dev | 3 | 2 | 67% | 1 (internal-proxy) |
| keybuzz-website-prod | 0 (Opaque) | 0 | n/a | 0 secrets opaque (que TLS + dockerconfigjson) |
| keybuzz-website-dev | 1 | 0 | 0% | 1 (preview-basic-auth) |
| keybuzz-studio-api-prod | 3 | 0 | 0% | 3 (auth, db, llm) |
| keybuzz-studio-api-dev | 3 | 0 | 0% | 3 (auth, db, llm) |
| keybuzz-seller-dev | 2 | 1 | 50% | 1 (vault-token) |
| keybuzz-ai | 3 | 1 | 33% | 2 (litellm-runtime-key, litellm-db-secret) |
| observability | 15 | 2 | 13% | alerting infra + Grafana admin (alertmanager helm-managed) |
| vault-management | 1 | 0 | 0% | vault-admin-token (root token, deja gere par vault-token-renew CronJob) |
| minio | 1 | 0 | 0% | minio-credentials (root user/password MinIO) |

**Conclusion couverture** : DEV a meilleure couverture que PROD. Les
PROD secrets manuels seront le gros du travail rotation.

---

## Preflight (E0)

| Champ | Valeur | Statut |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-16T02:36 | OK |
| Token RO Hetzner | absent (supprime AS.17.1O) | OK |
| keybuzz-infra HEAD | c32eeb9 (post AS.17.1N-bis) | clean |

---

## E1 - Kubernetes Secrets metadata inventory

31 namespaces visibles. Secrets metadata extraits via
`kubectl get secrets -o jsonpath` et key names via
`jq '.data | keys[]'` (zero affichage de valeurs).

### keybuzz-api-prod (15 Opaque + 1 TLS + 1 dockerconfigjson)

| Secret name | Type | Key names | ExternalSecret? |
|---|---|---|---|
| ghcr-cred | dockerconfigjson | .dockerconfigjson | NON manuel |
| keybuzz-ads-encryption | Opaque | ADS_ENCRYPTION_KEY | NON manuel |
| keybuzz-api-jwt | Opaque | COOKIE_SECRET, JWT_SECRET | OUI vault-backend |
| keybuzz-api-postgres | Opaque | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER | OUI vault-backend (5m) |
| keybuzz-api-prod-tls | TLS | tls.crt, tls.key | gere cert-manager |
| keybuzz-google-ads | Opaque | GOOGLE_ADS_CLIENT_ID, GOOGLE_ADS_CLIENT_SECRET, GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_REFRESH_TOKEN | NON manuel |
| keybuzz-litellm | Opaque | LITELLM_MASTER_KEY | NON manuel |
| keybuzz-meta-ads | Opaque | META_ACCESS_TOKEN, META_AD_ACCOUNT_ID | NON manuel |
| keybuzz-ses | Opaque | AWS_SES_ACCESS_KEY_ID, AWS_SES_FROM_EMAIL, AWS_SES_REGION, AWS_SES_SECRET_ACCESS_KEY | NON manuel (PROD) - present DEV |
| keybuzz-shopify | Opaque | SHOPIFY_CLIENT_ID, SHOPIFY_CLIENT_SECRET, SHOPIFY_ENCRYPTION_KEY | NON manuel |
| keybuzz-stripe | Opaque | STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRICE_* | NON manuel (PROD) - present DEV |
| minio-credentials | Opaque | access-key, secret-key | OUI vault-backend |
| octopia-credentials | Opaque | OCTOPIA_API_URL, OCTOPIA_AUTH_URL, OCTOPIA_CLIENT_ID, OCTOPIA_CLIENT_SECRET | OUI vault-backend |
| redis-credentials | Opaque | REDIS_PASSWORD, REDIS_URL | OUI vault-backend |
| tracking-17track | Opaque | TRACKING_17TRACK_API_KEY | NON manuel |
| vault-app-token | Opaque | VAULT_TOKEN, token | auto vault-token-renew |
| vault-root-token | Opaque | VAULT_TOKEN | auto vault-token-renew |

### keybuzz-api-dev (21 Opaque)

Pattern similaire + ajouts :
- keybuzz-api-postgres-admin (vault-backend-database 5m, dynamic creds)
- keybuzz-api-postgres-static (manuel)
- keybuzz-db-migrator (vault-backend)
- keybuzz-litellm-secrets (vault-backend)
- keybuzz-ses-secrets (vault-backend) -- present DEV non PROD
- keybuzz-stripe (avec API_BASE_URL + APP_BASE_URL en plus)
- keybuzz-octopia (OCTOPIA_CLIENT_SECRET seul)
- vault-emergency-token (DESCRIPTION + VAULT_TOKEN)

### keybuzz-backend-prod (7 Opaque)

| Secret | Keys | ExternalSecret |
|---|---|---|
| amazon-spapi-creds | AMAZON_SPAPI_APP_ID/CLIENT_ID/CLIENT_SECRET/REDIRECT_URI | NON manuel |
| inbound-webhook-key | INBOUND_WEBHOOK_KEY | NON manuel |
| keybuzz-backend-db | DATABASE_URL, PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER | OUI vault-backend |
| keybuzz-backend-secrets | JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_*, PRODUCT_DATABASE_URL | OUI vault-backend |
| keybuzz-internal-proxy | token | NON manuel |
| vault-app-token | VAULT_TOKEN, token | auto vault-token-renew |
| vault-token | VAULT_TOKEN | auto vault-token-renew |

### keybuzz-admin-v2-prod (3 Opaque)

| Secret | Keys | ExternalSecret |
|---|---|---|
| keybuzz-admin-v2-auth | NEXTAUTH_SECRET | NON manuel |
| keybuzz-admin-v2-bootstrap | ADMIN_BOOTSTRAP_EMAIL, ADMIN_BOOTSTRAP_PASSWORD_HASH | OUI vault-backend |
| keybuzz-admin-v2-postgres | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER | OUI vault-backend |

### keybuzz-admin-v2-dev (4 Opaque)

Ajout : keybuzz-admin-v2-stripe (STRIPE_SECRET_KEY).

### keybuzz-client-prod (2 Opaque)

| Secret | Keys | ExternalSecret |
|---|---|---|
| keybuzz-auth-secrets | AZURE_AD_CLIENT_ID/SECRET/TENANT_ID, GOOGLE_CLIENT_ID/SECRET, NEXTAUTH_SECRET | OUI vault-backend |
| keybuzz-internal-proxy | token | NON manuel |

### keybuzz-client-dev (3 Opaque)

Pattern + minio-credentials ExternalSecret + keybuzz-auth (avec NEXTAUTH_URL en plus).

### keybuzz-website-prod / dev

PROD : aucun secret Opaque (que TLS + dockerconfigjson). Le contact form
NEXT_PUBLIC_CONTACT_API_URL est build-time arg, pas runtime secret.

DEV : preview-basic-auth (auth = htpasswd file pour basic auth Nginx
Ingress preview.keybuzz.pro) NON ExternalSecret.

### keybuzz-studio-api-prod / dev (3 Opaque each)

| Secret | Keys | ExternalSecret |
|---|---|---|
| keybuzz-studio-api-auth | BOOTSTRAP_SECRET | NON manuel |
| keybuzz-studio-api-db | DATABASE_URL | NON manuel |
| keybuzz-studio-api-llm | ANTHROPIC_API_KEY, GEMINI_API_KEY, LLM_API_KEY, LLM_MAX_TOKENS, LLM_MODEL, LLM_PROVIDER, LLM_TEMPERATURE, LLM_TIMEOUT_MS, PIPELINE_MODE | NON manuel |

### keybuzz-seller-dev (2 Opaque)

| Secret | Keys | ExternalSecret |
|---|---|---|
| seller-api-postgres | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER | OUI vault-backend |
| vault-token | VAULT_TOKEN | auto vault-token-renew |

### keybuzz-ai (3 Opaque)

| Secret | Keys | ExternalSecret |
|---|---|---|
| litellm-db-secret | DATABASE_URL, LITELLM_DATABASE_URL, USE_PRISMA_MIGRATE | NON manuel |
| litellm-runtime-key | LITELLM_RUNTIME_KEY | NON manuel |
| litellm-secret | ANTHROPIC_API_KEY, DATABASE_URL, LITELLM_DATABASE_URL, LITELLM_MASTER_KEY, OPENAI_API_KEY, USE_PRISMA_MIGRATE | OUI vault-backend |

### Infra et systeme

| NS | Secret | Keys | Notes |
|---|---|---|---|
| keybuzz-system | vault-auth-token | ca.crt, namespace, token | service-account-token K8s pour vault auth |
| vault-management | vault-admin-token | token | **VAULT ROOT TOKEN equivalent**, gere par vault-token-renew CronJob |
| minio | minio-credentials | MINIO_ROOT_PASSWORD, MINIO_ROOT_USER | racine MinIO interne (different de keybuzz-api/backend MinIO clients) |
| observability | alerting-slack-dev | channel, webhook_url | OUI vault-backend |
| observability | alerting-smtp-dev | from, host, password, port, require_tls, to_default, username | OUI vault-backend |
| observability | kube-prometheus-grafana | admin-password, admin-user, ldap-toml | NON manuel (helm-managed) |
| argocd | argocd-initial-admin-secret | password | NON manuel |
| argocd | argocd-secret | admin.password, admin.passwordMtime, server.secretkey, tls.crt, tls.key | NON manuel |
| argocd | argocd-redis | auth | NON manuel |
| cert-manager | letsencrypt-prod | tls.key | Let's Encrypt account key |
| cert-manager | letsencrypt-staging | tls.key | Let's Encrypt staging key |

---

## E2 - Workload secret references

Resume des deployments K8s qui consomment des secrets via
envFrom / valueFrom.secretKeyRef / imagePullSecrets / serviceAccount :

| Namespace | Workload | envFrom | valueFromSecret | imagePullSecret |
|---|---|---|---|---|
| keybuzz-api-prod | Deployment/keybuzz-api | (none) | keybuzz-ads-encryption, keybuzz-api-jwt, keybuzz-api-postgres, keybuzz-google-ads, keybuzz-litellm, keybuzz-meta-ads, keybuzz-shopify, keybuzz-stripe, minio-credentials, redis-credentials, tracking-17track, vault-root-token | ghcr-cred |
| keybuzz-api-prod | Deployment/keybuzz-outbound-worker | keybuzz-api-postgres, keybuzz-ses | minio-credentials, octopia-credentials | ghcr-cred |
| keybuzz-api-dev | Deployment/keybuzz-api | (none) | keybuzz-ads-encryption, keybuzz-api-jwt, keybuzz-api-postgres, keybuzz-google-ads, keybuzz-litellm, keybuzz-shopify, keybuzz-stripe, minio-credentials, redis-credentials, tracking-17track, vault-root-token | ghcr-cred |
| keybuzz-api-dev | Deployment/keybuzz-outbound-worker | keybuzz-api-postgres, keybuzz-ses | (none) | ghcr-cred |
| keybuzz-backend-prod | Deployment/keybuzz-backend | keybuzz-backend-db, keybuzz-backend-secrets, vault-token, amazon-spapi-creds, inbound-webhook-key | keybuzz-internal-proxy, vault-app-token | ghcr-cred |
| keybuzz-backend-prod | Deployment/amazon-items-worker | (none) | keybuzz-backend-db, vault-token | ghcr-cred |
| keybuzz-backend-prod | Deployment/amazon-orders-worker | (none) | keybuzz-backend-db, vault-token | ghcr-cred |
| keybuzz-backend-prod | Deployment/backfill-scheduler | keybuzz-backend-db | (none) | (none) |
| keybuzz-backend-dev | (similar pattern) | + amazon-orders-backfill cronjob | | |
| keybuzz-admin-v2-prod | Deployment/keybuzz-admin-v2 | (none) | keybuzz-admin-v2-auth, keybuzz-admin-v2-bootstrap, keybuzz-admin-v2-postgres | ghcr-secret |
| keybuzz-admin-v2-dev | Deployment/keybuzz-admin-v2 | (none) | + keybuzz-admin-v2-stripe | ghcr-secret |
| keybuzz-client-prod | Deployment/keybuzz-client | (none) | keybuzz-auth-secrets | ghcr-cred |
| keybuzz-client-dev | Deployment/keybuzz-client | (none) | keybuzz-auth | ghcr-cred |
| keybuzz-website-prod / dev | Deployment/keybuzz-website | (none) | (none) | ghcr-secret |
| keybuzz-studio-api-prod / dev | Deployment/keybuzz-studio-api | keybuzz-studio-api-llm | keybuzz-studio-api-auth, keybuzz-studio-api-db | ghcr-cred |
| keybuzz-seller-dev | Deployment/seller-api | (none) | seller-api-postgres | ghcr-cred |
| keybuzz-seller-dev | Deployment/seller-client | (none) | (none) | ghcr-cred |
| keybuzz-ai | Deployment/litellm | litellm-secret, litellm-db-secret | (none) | (none) |

ServiceAccount = `default` partout (pas de SA custom).

CronJobs sans secret refs : carrier-tracking-poll, outbound-tick-processor,
sla-evaluator, trial-lifecycle-dryrun, sla-evaluator-escalation,
amazon-orders-backfill/sync, amazon-reports-tracking-sync.

---

## E3 - GitOps secret references

Search patterns SECRET/TOKEN/PASSWORD/API_KEY/CLIENT_SECRET/PRIVATE_KEY/
BEARER/AUTH_KEY dans `/opt/keybuzz/keybuzz-infra/k8s/`.

### Templates et commentaires (pas de fuite)

| File | Pattern trouve | Severite |
|---|---|---|
| k8s/keybuzz-api-dev/stripe-secret.template.yaml | `STRIPE_SECRET_KEY: "sk_test_REPLACE_ME"` + `STRIPE_WEBHOOK_SECRET: "whsec_REPLACE_ME"` | OK template seulement |
| k8s/keybuzz-admin-v2-dev/externalsecret-stripe.yaml | commentaire `--from-literal=STRIPE_SECRET_KEY=sk_test_XXXX` | OK exemple seulement |

**Aucune valeur reelle de secret commit dans GitOps.**

### Patterns metadata (references legitimes secretKeyRef/envFrom/secretRef)

`k8s/vault-token-renew/configmap-script.yaml` : script automation
contenant references `TOKEN_PERIOD`, `SA_TOKEN`, etc. Tous des
NOMS de variables ou de chemins, jamais de valeurs.

### ExternalSecrets ressources (30+ actives)

| ClusterSecretStore | Secrets count refs | Refresh interval |
|---|---|---|
| vault-backend | 28+ | 1h ou 5m |
| vault-backend-database | 1 (keybuzz-api-postgres-admin) | 1h |

Status : SecretSynced=True / Ready=True sur tous.

### CronJob vault-token-renew

`k8s/vault-token-renew/` : automated rotation des Vault tokens
- Periode : TOKEN_PERIOD=768h (32 jours)
- Renew tous les vault-app-token, vault-root-token, vault-token sur
  namespaces : keybuzz-api-prod, keybuzz-api-dev, keybuzz-backend-prod,
  keybuzz-backend-dev, keybuzz-seller-dev (probable)
- Lit ROOT TOKEN depuis `vault-management/vault-admin-token`
- Si TOKEN expire/invalid : recreate via vault token API
- Patche K8s secrets via Kubernetes API

---

## E4 - Service-by-service dependency map

| Service | Runtime | Secrets dependances directes | Exposed pendant fenetre attaque ? |
|---|---|---|---|
| keybuzz-api (prod+dev) | k8s-worker pods | 12 secrets (jwt, postgres, ads, llm, meta, shopify, ses, stripe, minio, redis, tracking, vault) | OUI 1-14h (pods sur k8s-workers compromis) |
| keybuzz-outbound-worker (prod+dev) | k8s-worker pods | 4 secrets (postgres, ses, minio, octopia) | OUI 1-14h |
| keybuzz-backend (prod+dev) | k8s-worker pods | 8+ secrets (db, internal-secrets, vault, amazon-spapi, inbound-webhook, internal-proxy) | OUI 1-14h |
| amazon-items-worker, amazon-orders-worker | k8s-worker pods | keybuzz-backend-db + vault-token | OUI 1-14h |
| backfill-scheduler | k8s-worker pods | keybuzz-backend-db | OUI 1-14h |
| keybuzz-admin-v2 (prod+dev) | k8s-worker pods | 3-4 secrets (auth, bootstrap, postgres, stripe DEV) | OUI 1-14h |
| keybuzz-client (prod+dev) | k8s-worker pods | keybuzz-auth-secrets (Azure AD + Google + NEXTAUTH) | OUI 1-14h |
| keybuzz-website (prod+dev) | k8s-worker pods | (none Opaque) + ghcr-secret | OUI mais image only (pas de runtime secret) |
| keybuzz-studio-api (prod+dev) | k8s-worker pods | 3 secrets (auth, db, LLM) | OUI 1-14h |
| seller-api (DEV only) | k8s-worker pods | seller-api-postgres + vault-token | OUI 1-14h |
| litellm | k8s-worker pods (keybuzz-ai NS) | litellm-secret, litellm-db-secret | OUI 1-14h + litellm-01 host compromis |
| Redis HA | redis-01/02/03 servers | redis.conf password (si configure) | OUI 1-14h hosts compromis |
| RabbitMQ cluster | queue-01/02/03 servers | RabbitMQ users | OUI 1-14h hosts compromis |
| Postgres Patroni | db-postgres-01/02/03 (NON rebuild) | DB roles passwords | NON cote DB hosts (rescue ineffective AS.17.1H), MAIS app credentials lus depuis pods K8s = OUI |
| Vault | vault-01/02/03 | Root token + unseal keys | vault-02 rebuilt + restaure ; root token potentiellement lu depuis pods avec vault-root-token secret |
| MinIO | minio-01/02/03 | MINIO_ROOT_USER, MINIO_ROOT_PASSWORD | minio-02 rescue ineffective, minio-01/03 NON touches ; root password potentiellement lu depuis pods |

**Conclusion** : Les K8s secrets sur k8s-worker-01/02/03 ont ete potentiellement
lus pendant 1-14h selon timing rebuild + restore (08:38-10:54 UTC le
2026-05-15 pour les workers + restore Ludovic AS.17.1N-bis Lot B
2026-05-16 ~01:08-01:34 UTC = ~14-17h fenetre maximale).

---

## E5 - Infra service secret surfaces

Audit metadata only (pas de connexion psql/redis-cli/rabbitmqctl/vault).

| Infra | Secret surface | Accessed by CE? | Risk apres restore |
|---|---|---|---|
| Postgres Patroni | DB roles + passwords | non (CE n'a pas role RO Postgres en AS.17.1H) | rotation app passwords requise (lus via K8s secrets) |
| Redis HA | redis.conf eventuel password | non (port 6379+26379 listening confirmes en AS.17.1N-bis Lot C) | rotation password requise |
| RabbitMQ | users credentials | non (port 5672+15672 listening) | rotation users requise |
| Vault Raft | root token + unseal keys + KV | non (CE n'a jamais touche vault CLI) | verification non compromission + decision rotation root |
| MinIO | MINIO_ROOT_USER + MINIO_ROOT_PASSWORD | non | rotation root + clients keys requise |
| SMTP mail-core-01 | (no auth visible per audit AS.17.1B emailService) | non | n/a (SMTP sans auth = no secret) |

---

## E6 - External providers exposure inventory

| Provider | K8s secret refs | Used by | Rotation urgency | Notes |
|---|---|---|---|---|
| Stripe | keybuzz-stripe (PROD+DEV), keybuzz-admin-v2-stripe (DEV) | keybuzz-api, keybuzz-admin-v2 | P0 | STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET ; rotation via Stripe Dashboard + update K8s secret |
| Google Ads | keybuzz-google-ads (PROD+DEV) | keybuzz-api | P0 | OAuth client secret + refresh token ; rotation via Google Cloud Console |
| Meta (Facebook) Ads | keybuzz-meta-ads (PROD only) | keybuzz-api | P0 | META_ACCESS_TOKEN ; rotation via Meta Business |
| Shopify | keybuzz-shopify (PROD+DEV) | keybuzz-api | P0 | OAuth client + encryption key ; rotation via Shopify Partners |
| Octopia | octopia-credentials (PROD+DEV) + keybuzz-octopia (DEV) | keybuzz-api | P0 | OAuth client ; rotation via Octopia |
| Amazon SP-API | amazon-spapi-creds (PROD+DEV) | keybuzz-backend, amazon-workers | P0 | OAuth APP_ID/CLIENT_ID/CLIENT_SECRET ; rotation via Amazon Seller Central + LWA |
| 17track | tracking-17track (PROD+DEV) | keybuzz-api | P1 | API key ; rotation via 17track dashboard |
| AWS SES | keybuzz-ses (DEV+PROD via ExternalSecret PROD partial) | keybuzz-outbound-worker | P0 | AWS IAM keys ; rotation via AWS IAM |
| LiteLLM master | keybuzz-litellm + keybuzz-litellm-secrets + litellm-secret/runtime-key (keybuzz-ai) | keybuzz-api, keybuzz-studio-api, litellm | P0 | LiteLLM internal master key |
| OpenAI | litellm-secret (keybuzz-ai) | litellm | P0 | OPENAI_API_KEY ; rotation via OpenAI Platform |
| Anthropic | litellm-secret (keybuzz-ai) + keybuzz-studio-api-llm (PROD+DEV) | litellm, studio-api | P0 | ANTHROPIC_API_KEY ; rotation via Anthropic Console |
| Gemini Google | keybuzz-studio-api-llm (PROD+DEV) | studio-api | P0 | GEMINI_API_KEY ; rotation via Google AI Studio |
| Google OAuth (NextAuth login) | keybuzz-auth-secrets (PROD+DEV) | keybuzz-client | P1 | GOOGLE_CLIENT_ID/SECRET ; rotation via Google Cloud Console |
| Azure AD OAuth | keybuzz-auth-secrets (PROD+DEV) | keybuzz-client | P1 | AZURE_AD_CLIENT_ID/SECRET/TENANT_ID ; rotation via Azure AD Portal |
| GHCR | ghcr-cred + ghcr-secret (toutes namespaces) | tous deployments imagePullSecret | P1 | PAT GitHub ; rotation via GitHub PAT settings |
| GitHub deploy | n/a en K8s | (sur bastion install-v3 ?) | non touche par incident | bastion n'a pas ete rebuild |
| Slack alerting | alerting-slack-dev (observability) | Alertmanager | P2 | webhook URL ; rotation via Slack |
| Slack/SMTP alerting SMTP | alerting-smtp-dev (observability) | Alertmanager | P2 | password SMTP alerting |
| Microsoft Clarity | wrff07upjx (PROD website) | website public | NOT_SECRET by design (Microsoft Clarity Project IDs are public) | aucune rotation |
| Linear API token | n/a en K8s (utilise par Codex / CE hors K8s) | Codex / CE | P2 | rotation via Linear settings |
| Hetzner Cloud token | revoque RW + supprime RO | n/a | DONE | deja gere AS.17.1O |

---

## E7 - Rotation priority plan

### P0 ROTATION URGENTE (avant promotion PROD)

| Groupe | Secrets concernes | Justification | Methode |
|---|---|---|---|
| **Vault root + admin** | vault-management/vault-admin-token + Vault unseal keys | Si compromis, tous les secrets dans Vault sont compromis. Vault tokens deja rotated automatiquement, mais root token besoin verification | Decision Ludovic + rotation manuelle si necessaire |
| **Postgres app passwords** | keybuzz-api-postgres, keybuzz-api-postgres-admin/static, keybuzz-db-migrator, keybuzz-admin-v2-postgres, keybuzz-backend-db, seller-api-postgres | Lus depuis pods k8s | Pour ExternalSecret : rotation valeur dans Vault. Pour DB role rotation : ALTER ROLE password (mutation Postgres) |
| **Redis password** | redis-credentials | Lu depuis pods k8s + redis-* hosts compromis | Vault rotation + Redis CONFIG SET (ou redis.conf rewrite + SIGHUP) |
| **JWT/COOKIE secrets** | keybuzz-api-jwt, keybuzz-admin-v2-auth, keybuzz-auth-secrets (NEXTAUTH_SECRET) | Lus depuis pods k8s | Vault rotation pour ExternalSecret ; manuel pour autres |
| **Stripe keys** | keybuzz-stripe (PROD+DEV), keybuzz-admin-v2-stripe (DEV) | API key + webhook secret | Rotation via Stripe Dashboard + K8s secret update |
| **Google Ads tokens** | keybuzz-google-ads (PROD+DEV) | OAuth refresh token + client secret | Google Cloud Console + K8s |
| **Meta Ads token** | keybuzz-meta-ads (PROD) | Long-lived access token | Meta Business + K8s |
| **Shopify tokens** | keybuzz-shopify (PROD+DEV) | OAuth + encryption key | Shopify Partners + K8s |
| **Amazon SP-API** | amazon-spapi-creds (PROD+DEV) | OAuth LWA app | Amazon Seller Central + K8s |
| **Octopia OAuth** | octopia-credentials (PROD+DEV), keybuzz-octopia (DEV) | OAuth client | Octopia + K8s |
| **LLM keys** | OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, LITELLM_MASTER_KEY/RUNTIME_KEY | Pods + litellm-01 host compromis | Provider consoles + K8s |
| **AWS SES** | keybuzz-ses | Lus depuis pods | AWS IAM + K8s |
| **MinIO root + clients** | minio (root) + minio-credentials (clients K8s) | minio-02 host rescue partial + clients lus depuis pods | mc admin user + K8s |
| **RabbitMQ users** | RabbitMQ users (queue-* hosts) | hosts compromis | rabbitmqctl change_password (mutation, Ludovic) |
| **Internal proxy tokens** | keybuzz-internal-proxy (token) | Lus depuis pods | Vault rotation ou regeneration manuelle |
| **Inbound webhook key** | inbound-webhook-key (PROD) | Lu depuis pods backend | Regeneration + K8s |
| **Ads encryption key** | keybuzz-ads-encryption (PROD+DEV) | Lus depuis pods api | **ATTENTION** : si donnees deja chiffrees avec, rotation peut casser dechiffrement ; verifier mecanisme rolling key |
| **Bootstrap admin v2 password** | keybuzz-admin-v2-bootstrap (PASSWORD_HASH) | Lus depuis pods admin | Regeneration via Vault + K8s |
| **Vault tokens K8s** | vault-app-token, vault-root-token, vault-token (per namespace) | Deja en rotation auto via CronJob | Trigger rotation manuelle apres verification root |

### P1 (apres P0 et avant promotion PROD)

| Groupe | Secrets | Justification |
|---|---|---|
| OAuth login providers | keybuzz-auth-secrets (Azure AD + Google) | Lus depuis pods client |
| 17track API | tracking-17track | API key |
| GHCR deploy tokens | ghcr-cred + ghcr-secret | PAT GitHub - peut servir push images si compromis |
| Studio API LLM | keybuzz-studio-api-llm (PROD+DEV) | Lus depuis pods studio-api (k8s-worker compromis) |
| Studio API DB + auth | keybuzz-studio-api-db, keybuzz-studio-api-auth | meme raison |
| LiteLLM DB | litellm-db-secret, litellm-runtime-key | meme raison |

### P2 (peut attendre)

| Groupe | Secrets | Notes |
|---|---|---|
| Alertmanager Slack/SMTP | alerting-slack-dev, alerting-smtp-dev | observability seulement |
| Grafana admin | kube-prometheus-grafana | admin password Grafana |
| ArgoCD admin | argocd-* | admin ArgoCD |
| TLS certs | * tls.crt/key | renouveles cert-manager auto |
| Let's Encrypt account keys | letsencrypt-prod/staging | rotation rare, pas exposition K8s pods |
| Linear API token | hors K8s | deja recommande rotation incident |

### NOT_NEEDED rotation

| Element | Raison |
|---|---|
| Microsoft Clarity Project ID `wrff07upjx` | Public by design |
| Bastion install-v3 SSH keys | Bastion non touche par incident |
| GitHub keybuzz-infra repo | Non touche, GitOps source-of-truth intact |

---

## E8 - Rotation dependency graph (proposition)

### Sequence haut-niveau

1. **Phase 1 : Verification Vault** (decision Ludovic)
   - Verifier vault-management/vault-admin-token integrite
   - Si compromis : reset root + reseal Vault (mutation, downtime)
   - Sinon : continuer P0 rotations
2. **Phase 2 : Rotation P0 ExternalSecrets-managed**
   - Rotation valeurs dans Vault directement (pour 30+ secrets via vault-backend)
   - Attendre refresh ExternalSecrets (1h ou 5m)
   - Verifier SecretSynced=True
   - Pour ces secrets : pas de mutation K8s necessaire, ExternalSecrets re-sync
3. **Phase 3 : Rotation P0 manuels (10+ PROD non-ExternalSecrets)**
   - Stripe, Google Ads, Meta, Shopify, Amazon SP-API, SES, LLM keys, etc.
   - Pour chaque : rotation cote provider + `kubectl apply` nouveau Secret + rollout deployment
4. **Phase 4 : Rotation P0 infra direct (Redis/RabbitMQ/Postgres roles + MinIO root)**
   - Postgres : ALTER ROLE password (Patroni-aware)
   - Redis : CONFIG SET requirepass + redis.conf
   - RabbitMQ : rabbitmqctl change_password
   - MinIO : mc admin user
5. **Phase 5 : Rotation P1**
6. **Phase 6 : Verification post-rotation**
   - Tester chaque service (OTP signup, Inbox, billing, etc.)
   - Pas de regression
7. **Phase 7 : Promotion PROD AS.17.0 + AS.17.0.1** (decision Ludovic apres rotation effective)
8. **Phase 8 : Rotation P2**

### Reloader interaction

Reloader est deploye et redemarre les pods automatiquement sur changement
de Secret. Donc apres update Secret, les pods se rechargent automatiquement
(pas besoin de `kubectl rollout restart` manuel).

ATTENTION : si Reloader configure sur Secret/ConfigMap utilise par
plusieurs deployments, le redemarrage peut etre simultane. Verifier
disponibilite multi-replicas durant rotations PROD.

---

## E9 - Business / RGPD note

Information communiquee par Ludovic : **aucun client reel actuellement,
seulement comptes de test**.

Implication :
- Risque atteinte personnes concernees = **TRES FAIBLE** en pratique
- Volume PII reel exfiltre = nul ou test data only
- Decision RGPD CNIL Art 33 notification = decision juridique Ludovic mais
  argumentation possible de **risque limite pour les personnes**

CE classe : **low practical data subject impact per Ludovic statement**.
Documentation conservee :
- Timeline incident detaillee (CSV Hetzner, rapports AS.17.0.1-RCA + AS.17.1 +
  AS.17.1B + AS.17.1H + AS.17.1N + AS.17.1N-bis + AS.17.1O)
- Cle attaquant explore-k8s + IP source M247 VPN documentees
- Containment + restoration documentes
- Inventaire secrets potentiellement exposes documente (ce rapport)

Decision finale RGPD = juridique Ludovic + conseil legal externe.

---

## Risk register final

| Risk ID | Severity | Finding | Action requise |
|---|---|---|---|
| R-Q0-1 | P0 | Vault root token compromission possible | verification + decision Ludovic |
| R-Q0-2 | P0 | 30+ ExternalSecrets-managed secrets potentiellement lus pendant fenetre attaque | rotation valeurs dans Vault, ExternalSecrets re-sync auto |
| R-Q0-3 | P0 | 15+ PROD secrets non-ExternalSecrets potentiellement lus | rotation manuelle sequentielle |
| R-Q0-4 | P0 | Redis password (si configure) lu depuis pods + redis-* hosts | rotation password + mise a jour K8s |
| R-Q0-5 | P0 | RabbitMQ users credentials lus depuis queue-* hosts | rotation users + mise a jour K8s |
| R-Q0-6 | P0 | Postgres app passwords lus depuis pods | rotation roles via Vault dynamic credentials ou ALTER ROLE |
| R-Q0-7 | P0 | LLM provider API keys (OpenAI, Anthropic, Gemini) lus depuis pods + litellm-01 host | rotation cote providers + K8s |
| R-Q0-8 | P0 | OAuth marketplace tokens (Amazon SP-API, Shopify, Octopia) lus depuis pods | rotation OAuth clients + refresh tokens |
| R-Q0-9 | P0 | Stripe keys lus depuis pods | rotation Stripe Dashboard |
| R-Q0-10 | P0 | Ads encryption key (KMS-equivalent) | ATTENTION : rolling key requise pour ne pas casser dechiffrement donnees existantes |
| R-Q0-11 | P0 | MinIO root + clients lus depuis pods + minio-02 partial | rotation root + clients access keys |
| R-Q0-12 | P1 | OAuth login providers (Azure AD, Google) | rotation client_secret |
| R-Q0-13 | P1 | GHCR deploy tokens | rotation PAT GitHub |
| R-Q0-14 | P2 | Alertmanager Slack/SMTP | rotation faible urgence |
| R-Q0-15 | P2 | Linear API token | rotation faible urgence |
| R-Q0-16 | OK | GitOps clean (pas de fuite valeur secret en clair) | maintien hygiene |
| R-Q0-17 | OK | Vault token rotation auto deja active | continuer monitoring CronJob |
| R-Q0-18 | OK | External Secrets Operator simplifie rotation 30+ secrets | utiliser pour P0 ExternalSecrets-managed |
| R-Q0-19 | OK | Cle bastion install-v3 install-v3-keybuzz-v3 sur 19 serveurs | preserver, non rotation requise |
| R-Q0-20 | OK | Architecture moderne (ArgoCD + cert-manager + reloader) | propice a rotation organisee |

---

## Recommendation phase suivante AS.17.1Q-1

**AS.17.1Q-1 ROTATION SECRETS EXECUTION** :

Prerequis :
- Decision Ludovic verification Vault root token integrite
- GO Ludovic plan rotation par phases
- Methode safe pour valeurs nouvelles (jamais affichees dans chat) :
  - Soit Ludovic genere les nouveaux secrets cote provider et les
    pousse dans Vault directement
  - Soit Ludovic genere via openssl rand cote bastion + push Vault
- Plan rollback documente

Sub-phases proposees :
1. AS.17.1Q-1A Vault verification + decision root rotation
2. AS.17.1Q-1B Rotation ExternalSecrets-managed via Vault (30+
   secrets, ~quelques heures)
3. AS.17.1Q-1C Rotation P0 manuels (Stripe, Google Ads, Meta,
   Shopify, Amazon SP-API, SES, LLM keys)
4. AS.17.1Q-1D Rotation infra direct (Redis, RabbitMQ, Postgres
   roles, MinIO root)
5. AS.17.1Q-1E Rotation P1 (OAuth login, GHCR)
6. AS.17.1Q-1F Validation post-rotation (tests OTP, Inbox, billing,
   Stripe webhook, etc.)
7. AS.17.1Q-1G Promotion PROD AS.17.0 + AS.17.0.1 (apres validation)
8. AS.17.1Q-1H Rotation P2 (Slack, Linear, etc.) + cleanup

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1Q-0 secrets exposure inventory read-only termine.
Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-0-KEY-323-SECRETS-EXPOSURE-INVENTORY-READONLY-01.md

Verdict : GO SECRETS INVENTORY READY

DECOUVERTES PRINCIPALES :

1. Architecture moderne SECRETS deja en place :
   - HashiCorp Vault (vault-01/02/03)
   - External Secrets Operator avec ClusterSecretStore vault-backend
     + vault-backend-database
   - 30+ ExternalSecrets actives, refresh 1h ou 5m, status SecretSynced
   - CronJob vault-token-renew automatise rotation Vault tokens
     period 768h
   - ArgoCD + cert-manager + reloader

2. Aucune valeur de secret en clair commit dans GitOps verifie via
   grep patterns (sk_, whsec_, BEGIN PRIVATE, ghp_, etc.). Seuls
   templates _REPLACE_ME et commentaires d exemple.

3. Couverture ExternalSecrets : DEV plus complet que PROD. PROD a
   environ 10 secrets manuels par namespace critique (Stripe, Google
   Ads, Meta, Shopify, SES, ads-encryption, litellm, 17track, etc.).

4. Secrets potentiellement lus pendant fenetre attaque (1-14h selon
   timing rebuild + restore par k8s-worker) :
   - 12+ secrets pour keybuzz-api (PROD+DEV)
   - 8+ secrets pour keybuzz-backend (PROD+DEV)
   - 3-4 secrets pour keybuzz-admin-v2
   - 1-2 secrets pour keybuzz-client
   - 3 secrets pour keybuzz-studio-api
   - 2 secrets pour keybuzz-seller-dev
   - 3 secrets pour litellm (keybuzz-ai)
   - + secrets infra Redis/RabbitMQ/MinIO root depuis hosts compromis

5. RGPD : Ludovic indique aucun client reel actuellement, comptes de
   test uniquement. Risque atteinte personnes concernees TRES FAIBLE
   en pratique. Decision juridique Ludovic.

PHASE SUIVANTE PROPOSEE : AS.17.1Q-1 ROTATION SECRETS EXECUTION
en 8 sous-phases sequentielles (verification Vault root -> rotation
ExternalSecrets-managed -> rotation P0 manuels -> rotation infra
direct -> rotation P1 -> validation -> promotion PROD -> rotation P2).

Aucune rotation effectuee dans AS.17.1Q-0. Aucune valeur de secret
affichee. Aucune mutation Kubernetes/Vault/services. Tous les key
names extraits via jq | keys[] (zero data).

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu jusqu'a
AS.17.1Q-1 effective.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic. Codex via connecteur Linear posera
apres GO commit.

---

## Hors scope / actions NON faites

- Aucune valeur de secret affichee en clair
- Aucun `kubectl get secret -o yaml` qui affiche `.data`
- Aucun `base64 -d`
- Aucun `vault kv get` ni `vault read`
- Aucun `cat /opt/keybuzz/credentials/*` ni `secrets/*`
- Aucun `cat .env`
- Aucun `printenv` ou `env`
- Aucun `kubectl exec env`
- Aucun `kubectl set/patch/edit` sur Kubernetes Secrets
- Aucun `helm upgrade`
- Aucun restart/reload service
- Aucun `psql ALTER`
- Aucun `redis-cli CONFIG SET`
- Aucun `rabbitmqctl change_password`
- Aucun appel provider externe (Stripe, Google, Meta, TikTok,
  LinkedIn, Amazon, Shopify, OpenAI, Anthropic, etc.)
- Aucun token Hetzner reutilise
- Aucun affichage de hash password ou empreinte sensible
- Aucun PII en clair
- Aucun commit Git infra du rapport AS.17.1Q-0 (en attente GO -
  ce rapport untracked apres ecriture)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation declenchee
- Aucune notification RGPD declenchee

---

## Phrase cible finale

GO SECRETS INVENTORY READY. Architecture moderne External Secrets +
Vault deja en place sur KeyBuzz prod/dev. 30+ ExternalSecrets actives
permettent rotation centralisee dans Vault. PROD a couverture moindre
avec 10+ secrets manuels par namespace critique. Aucune valeur secret
commit dans GitOps. Vault tokens deja en rotation auto via CronJob.
Plan rotation hierarchise P0/P1/P2 prepare en 8 sous-phases AS.17.1Q-1.
Risque RGPD atteinte personnes concernees TRES FAIBLE en pratique
(comptes test uniquement per Ludovic). Aucune valeur secret affichee,
aucune mutation effectuee. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1
maintenu jusqu'a AS.17.1Q-1 effective.

---
