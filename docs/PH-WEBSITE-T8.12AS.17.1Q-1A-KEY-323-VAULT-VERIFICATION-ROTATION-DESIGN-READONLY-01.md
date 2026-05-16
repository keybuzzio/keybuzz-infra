# PH-WEBSITE-T8.12AS.17.1Q-1A-KEY-323-VAULT-VERIFICATION-ROTATION-DESIGN-READONLY-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1Q-1A Vault verification + rotation design read-only
> Environnement : HashiCorp Vault Raft cluster + External Secrets
>          Operator + Kubernetes - read-only strict

---

## VERDICT

GO PARTIAL VAULT DESIGN WITH BLOCKERS

### Ce qui a pu etre verifie (sans token Vault auth)

- Vault cluster status (sealed=false, initialized=true, version 1.21.1,
  Raft HA 3 nodes, active leader = vault-03 / 10.0.0.155)
- ExternalSecrets architecture complete : 30 ExternalSecrets actives,
  status SecretSynced=True, refresh 1h ou 5m
- Mapping complet ExternalSecret -> Vault KV path remoteRef
- ClusterSecretStores : `vault-backend` + `vault-backend-database`
  (auth Kubernetes ServiceAccount JWT, pas de token statique)
- vault-token-renew CronJob ACTIF : derniere execution Complete a 03:00 UTC
  2026-05-16 (90s avant audit), schedule daily
- External Secrets Operator pods : 3/3 Running (16-17h uptime
  post-restore Lots B+D)

### Ce qui est BLOQUE (token operateur `~/.vault-token` invalide/expire)

- vault auth list (Code 403 invalid token)
- vault list auth/kubernetes/role
- vault read auth/kubernetes/role/<role>
- vault policy list
- vault secrets list (KV engines metadata)
- vault token list-accessors
- vault token lookup -accessor

### Design rotation prepare

Plan AS.17.1Q-1B propose sans execution :
- 30+ ExternalSecrets-managed : rotation valeur dans Vault KV path ->
  ESO re-sync automatique (1h ou 5m selon refresh interval) -> reloader
  redemarre pods
- 15+ PROD secrets manuels : rotation provider + kubectl create secret
  + rollout
- Vault tokens auto-rotates deja en place via CronJob

Aucune mutation effectuee. Aucune valeur de secret affichee. Aucun
root token / unseal key / KV value lu. Token operateur invalide non
affiche.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu jusqu'a AS.17.1Q-1B
rotation effective et validee.

---

## Resume executif

### Architecture Vault HA Raft

| Field | Value | Risk |
|---|---|---|
| Cluster Name | vault-cluster-bec03650 | n/a |
| Cluster ID | 44ee17d7-a4de-d363-00d6-6aae72150d74 | n/a |
| Version | 1.21.1 (build 2025-11-18) | recent (release Nov 2025) |
| Seal Type | shamir (5 shares, threshold 3) | OK best practice 5/3 |
| Sealed | false | OPERATIONNEL |
| Initialized | true | OK |
| Storage Type | raft (integrated) | OK best practice |
| HA Enabled | true | OK 3 nodes |
| Active Node Address | http://10.0.0.155:8200 (vault-03) | OK |
| HA Cluster | https://10.0.0.155:8201 | OK |
| Standby Nodes (visibles) | 10.0.0.150 (vault-01) | + vault-02 restaure (10.0.0.154) |
| Raft Committed Index | 1117463 | OK in-sync |
| Raft Applied Index | 1117463 | OK matches |
| Removed From Cluster | false | OK |

**Note critique** : vault-02 (rebuilt par attaquant + restaure par Ludovic
AS.17.1N-bis Lot A) a rejoint le cluster Raft post-restore. vault-03 est
actuellement leader (non touche par incident). vault-01 et vault-02
standby.

### External Secrets Operator architecture

| Element | Detail |
|---|---|
| ESO version | deployement `external-secrets-5db667f798` (uptime 16h) |
| ClusterSecretStore actifs | vault-backend + vault-backend-database |
| Auth method ESO -> Vault | Kubernetes ServiceAccount JWT (`external-secrets/external-secrets`) |
| K8s auth roles utilisees | `keybuzz-external-secrets` (vault-backend) + `eso-keybuzz` (vault-backend-database) |
| Engine KV version | v2 (path = `secret`) |
| Server URL | http://10.0.0.150:8200 (vault-01 standby) |
| ExternalSecrets count | 30 actives, **toutes SecretSynced=True / Ready=True** |
| Refresh intervals observes | 1h pour la plupart, 5m pour `keybuzz-api-postgres-kv` et `keybuzz-api-postgres` PROD |
| Reloader | DEPLOYE (namespace reloader) - redemarre pods sur changement secret |

### Vault token-renew CronJob

| Element | Detail |
|---|---|
| Schedule | `0 3 * * *` (3h UTC daily) |
| Last execution | 2026-05-16T03:00 UTC = 90s avant audit |
| Status | Complete (Duration 13s) |
| Role | renouvelle vault-app-token, vault-root-token, vault-token sur namespaces consommateurs |
| TOKEN_PERIOD | 768h (32 jours) |
| ROOT TOKEN source | `vault-management/vault-admin-token` (K8s secret) |
| Mecanisme | vault token API (renew si TTL > 0, recreate si invalid) |

**Conclusion** : le mecanisme de rotation auto Vault tokens est
OPERATIONNEL et a tourne avec succes ce matin. Les Vault tokens K8s
secrets sont rafraichis daily.

---

## Preflight (E0)

| Surface | Valeur | Statut |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-16T02:58 | OK |
| keybuzz-infra HEAD | e6e0f26 (post AS.17.1Q-0) | clean |
| Token Hetzner RO | absent (supprime AS.17.1O) | OK |
| vault CLI | /usr/bin/vault v1.21.1 | OK |
| kubectl | /usr/bin/kubectl | OK |
| jq | /usr/bin/jq | OK |
| VAULT_ADDR env | ABSENT (utilise http://10.0.0.150:8200 manuellement) | OK |
| VAULT_TOKEN env | ABSENT | OK |
| `~/.vault-token` file | PRESENT mais **INVALIDE (Code 403)** | BLOCKER admin ops |
| DNS vault.keybuzz.io | 10.0.0.150 (vault-01) | OK |

---

## E1 - Vault health metadata

Verifie via `vault status` non-authentifie (endpoint `/sys/seal-status`
public).

Voir tableau Resume executif ci-dessus.

**Verdict E1 : Vault HA cluster operationnel et sain. Aucun signe
visible de probleme.**

---

## E2 - ExternalSecrets architecture

### ClusterSecretStores

| Store | Auth method | Role | SA | Path | Version | Status |
|---|---|---|---|---|---|---|
| vault-backend | kubernetes | keybuzz-external-secrets | external-secrets/external-secrets | secret | v2 | Valid Ready |
| vault-backend-database | kubernetes | eso-keybuzz | external-secrets/external-secrets | secret | v2 | Valid Ready |

Note : deux stores utilisent le meme SA `external-secrets/external-secrets`
mais avec deux roles Vault differents (`keybuzz-external-secrets` vs
`eso-keybuzz`). Les policies attachees a chaque role sont a verifier
(BLOCKED par token invalide).

### ExternalSecrets inventory complet (30 actives)

| Namespace | ExternalSecret | Target Secret | Refresh | Store | Vault KV path remoteRef (sans values) |
|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | keybuzz-admin-v2-bootstrap | 1h | vault-backend | keybuzz/admin-v2/bootstrap [email, password_hash] |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-postgres | keybuzz-admin-v2-postgres | 1h | vault-backend | keybuzz/admin-v2/postgres [PG*] |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | keybuzz-admin-v2-bootstrap | 1h | vault-backend | keybuzz/admin-v2/bootstrap [email, password_hash] |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | keybuzz-admin-v2-postgres | 1h | vault-backend | **keybuzz/admin-v2/postgres-prod** [PG*] (prod separe) |
| keybuzz-ai | litellm-secrets | litellm-secret | 1h | vault-backend | secret/keybuzz/ai/anthropic_api_key, openai_api_key + secret/keybuzz/litellm/master_key, database_url, use_prisma_migrate |
| keybuzz-api-dev | keybuzz-api-jwt | keybuzz-api-jwt | 1h | vault-backend | keybuzz/dev/jwt [COOKIE_SECRET, JWT_SECRET] |
| keybuzz-api-dev | keybuzz-api-postgres-admin | keybuzz-api-postgres-admin | 1h | **vault-backend-database** | (dynamic creds, no remoteRefs static) |
| keybuzz-api-dev | keybuzz-api-postgres-kv | keybuzz-api-postgres | **5m** | vault-backend | secret/data/keybuzz/dev/api-postgres [PG*] |
| keybuzz-api-dev | keybuzz-db-migrator | keybuzz-db-migrator | 1h | vault-backend | secret/keybuzz/dev/db_migrator [database, host, password, port, username] |
| keybuzz-api-dev | keybuzz-litellm-secrets | keybuzz-litellm-secrets | 1h | vault-backend | secret/keybuzz/litellm/master_key [value] |
| keybuzz-api-dev | keybuzz-ses-secrets | keybuzz-ses | 1h | vault-backend | secret/keybuzz/ses [access_key_id, from_email, region, secret_access_key] |
| keybuzz-api-dev | keybuzz-stripe-secrets | keybuzz-stripe | 1h | vault-backend | secret/keybuzz/stripe [api_base_url, app_base_url, price_*, secret_key, webhook_secret] |
| keybuzz-api-dev | minio-credentials | minio-credentials | 1h | vault-backend | secret/data/keybuzz/minio [MINIO_*] |
| keybuzz-api-dev | octopia-credentials | octopia-credentials | 1h | vault-backend | secret/keybuzz/dev/octopia [api_url, auth_url, client_id, client_secret] |
| keybuzz-api-dev | redis-credentials | redis-credentials | 1h | vault-backend | keybuzz/redis [REDIS_PASSWORD, REDIS_URL] |
| keybuzz-api-prod | keybuzz-api-jwt | keybuzz-api-jwt | 1h | vault-backend | keybuzz/prod/jwt [COOKIE_SECRET, JWT_SECRET] |
| keybuzz-api-prod | keybuzz-api-postgres | keybuzz-api-postgres | **5m** | vault-backend | secret/keybuzz/prod/db_api [PG*] |
| keybuzz-api-prod | minio-credentials | minio-credentials | 1h | vault-backend | secret/keybuzz/prod/minio [access-key, secret-key] |
| keybuzz-api-prod | octopia-credentials | octopia-credentials | 1h | vault-backend | keybuzz/prod/octopia [OCTOPIA_*] |
| keybuzz-api-prod | redis-credentials | redis-credentials | 1h | vault-backend | keybuzz/redis [REDIS_PASSWORD, REDIS_URL] (SHARED DEV+PROD) |
| keybuzz-backend-dev | keybuzz-backend-db | keybuzz-backend-db | 1h | vault-backend | keybuzz/dev/backend-postgres [DATABASE_URL, PG*] |
| keybuzz-backend-dev | keybuzz-backend-secrets | keybuzz-backend-secrets | 1h | vault-backend | multiples paths : keybuzz/dev/backend-jwt + backend-product-db + inbound-webhook + internal-tokens + minio (chaque path expose meme set de keys = pattern aggregation/fallback) |
| keybuzz-backend-prod | keybuzz-backend-db | keybuzz-backend-db | 1h | vault-backend | keybuzz/prod/backend-postgres [PG*] |
| keybuzz-backend-prod | keybuzz-backend-secrets | keybuzz-backend-secrets | 1h | vault-backend | multiples paths : keybuzz/internal-tokens + keybuzz/minio + keybuzz/prod/backend-jwt + keybuzz/prod/backend-product-db |
| keybuzz-client-dev | keybuzz-auth-secrets | keybuzz-auth | 1h | vault-backend | secret/keybuzz/auth [azure_ad_*, google_*, nextauth_secret, nextauth_url] |
| keybuzz-client-dev | minio-credentials | minio-credentials | 1h | vault-backend | secret/data/keybuzz/minio [MINIO_*] |
| keybuzz-client-prod | keybuzz-auth-secrets | keybuzz-auth-secrets | 1h | vault-backend | secret/keybuzz/prod/auth [AZURE_AD_*, GOOGLE_*, NEXTAUTH_SECRET] |
| keybuzz-seller-dev | seller-api-postgres | seller-api-postgres | 1h | vault-backend | secret/data/keybuzz/dev/seller-api-postgres [PG*] |
| observability | alerting-slack-dev | alerting-slack-dev | 1h | vault-backend | keybuzz/observability/slack/dev [channel, webhook_url] |
| observability | alerting-smtp-dev | alerting-smtp-dev | 1h | vault-backend | keybuzz/observability/smtp/dev [from, host, password, port, require_tls, to_default, username] |

### Sync status

`lastRefresh` recent (entre 02:07 et 02:59 UTC le 2026-05-16) sur toutes
les 30 ExternalSecrets. Sync running normalement post-restore Lots
B+D (k8s-workers).

### Observations architecture ESO

**Patterns positifs** :
- Auth Kubernetes SA (pas de token statique)
- Refresh 5m pour Postgres credentials critiques (API prod + DEV postgres-kv)
- Refresh 1h pour le reste (raisonnable)
- 100% SecretSynced post-restore

**Inconsistances notees (P2 hygiene)** :

| Inconsistance | Detail | Impact |
|---|---|---|
| Naming KV path | melange `secret/keybuzz/...` + `keybuzz/...` + `secret/data/keybuzz/...` | hygiene seulement, ESO normalise |
| Shared dev/prod | `keybuzz/redis` partage entre DEV et PROD ; `secret/keybuzz/auth` partage ? non, DEV `secret/keybuzz/auth` vs PROD `secret/keybuzz/prod/auth` separes | Redis PARTAGE = risque rotation DEV impacte PROD |
| Shared ses/stripe | `secret/keybuzz/ses` et `secret/keybuzz/stripe` non-prefixe = partages DEV+PROD ? mais Stripe PROD est non-ESO donc non concerne ; SES PROD est non-ESO aussi | Vault paths potentiellement partages DEV+PROD mais usage PROD est manuel |
| Multiples paths backend-secrets | Aggregation 5 paths Vault avec memes 8 keys (backend-jwt, backend-product-db, inbound-webhook, internal-tokens, minio) | sub-optimal mais fonctionne |

---

## E3 - Vault auth methods metadata - **BLOCKED**

Tentative `vault auth list -format=json` retourne :

```
Code: 403. Errors:
* 2 errors occurred:
  * permission denied
  * invalid token
```

**Token operateur `~/.vault-token` est invalide/expire.**

Information deduite des ClusterSecretStore configurations :
- auth/kubernetes/ mounted (utilise par ESO via SA JWT)
- Role `keybuzz-external-secrets` (vault-backend)
- Role `eso-keybuzz` (vault-backend-database)
- SA `external-secrets/external-secrets` bind a ces roles

Information deduite de vault-token-renew CronJob :
- auth/token/ active (root token operations)
- vault-admin-token (K8s secret vault-management/vault-admin-token) =
  TOKEN ROOT-equivalent utilise pour creer/renouveler les other tokens

**Auth methods complets BLOCKED par token operateur invalide. A
debloquer en re-login Vault par Ludovic puis Q-1A-bis si necessaire.**

---

## E4 - Vault policies metadata - **BLOCKED**

`vault policy list` retourne 403 invalid token.

Information deduite :
- Policy `keybuzz-external-secrets` (attachee role meme nom) - donne
  read access aux paths secret/keybuzz/* via KV v2
- Policy `eso-keybuzz` (attachee role meme nom) - donne probable read +
  database engine dynamic creds
- Policy root-like utilisee par vault-token-renew CronJob script
  (lit vault-management/vault-admin-token comme token argument)

Verification des policies complete BLOCKED par token operateur invalide.

---

## E5 - Vault secrets engines metadata - **BLOCKED**

`vault secrets list -format=json` retourne 403 invalid token.

Information deduite :
- `secret/` KV v2 mounted (path utilise par tous les ESO)
- Possiblement database engine mounted (utilise par vault-backend-database
  ClusterSecretStore, role `eso-keybuzz`) - retourne dynamic credentials
  Postgres rotated automatiquement
- Path `keybuzz/...` sans prefix `secret/` est aussi accepte = KV v2
  avec implicit mount

Verification engines complete BLOCKED par token operateur invalide.

---

## E6 - Tokens/accessors/leases metadata - **BLOCKED**

`vault token list-accessors` BLOCKED par token operateur invalide.

Information deduite :
- vault-app-token + vault-root-token + vault-token (K8s secrets dans
  keybuzz-api-prod/dev, keybuzz-backend-prod/dev, keybuzz-seller-dev) =
  tokens auto-rotated daily par vault-token-renew CronJob
- TOKEN_PERIOD = 768h (32 jours)
- vault-emergency-token DEV existe (DESCRIPTION + VAULT_TOKEN)
- vault-admin-token (vault-management) = source root pour renew

Lease metadata + accessors count BLOCKED.

---

## E7 - DEV/PROD ExternalSecrets coverage gaps

### PROD secrets manuels (non-ESO) = priorite rotation manuelle

| Secret PROD manuel | Keys | Vault path manquant | Impact rotation |
|---|---|---|---|
| keybuzz-ads-encryption (api-prod) | ADS_ENCRYPTION_KEY | non present Vault | rotation rolling key requise (donnees chiffrees) |
| keybuzz-google-ads (api-prod) | GOOGLE_ADS_* (4 keys) | non present Vault | rotation manuelle |
| keybuzz-litellm (api-prod) | LITELLM_MASTER_KEY | non present Vault | rotation manuelle |
| keybuzz-meta-ads (api-prod) | META_ACCESS_TOKEN, META_AD_ACCOUNT_ID | non present Vault | rotation manuelle |
| keybuzz-ses (api-prod) | AWS_SES_* (4 keys) | DEV present `secret/keybuzz/ses` mais ExternalSecret PROD absent | ajouter ExternalSecret PROD recommande |
| keybuzz-shopify (api-prod) | SHOPIFY_* (3 keys) | non present Vault | rotation manuelle |
| keybuzz-stripe (api-prod) | STRIPE_* (multiples keys) | DEV present `secret/keybuzz/stripe` mais ExternalSecret PROD absent | ajouter ExternalSecret PROD recommande |
| tracking-17track (api-prod+dev) | TRACKING_17TRACK_API_KEY | non present Vault | rotation manuelle |
| amazon-spapi-creds (backend-prod+dev) | AMAZON_SPAPI_* (4 keys) | non present Vault | rotation manuelle |
| inbound-webhook-key (backend-prod) | INBOUND_WEBHOOK_KEY | DEV present dans `keybuzz/dev/inbound-webhook` Vault path mais PROD manuel | rotation manuelle PROD |
| keybuzz-internal-proxy (backend-prod+dev, client-prod+dev) | token | non present Vault | rotation manuelle |
| keybuzz-admin-v2-auth (admin-v2-prod+dev) | NEXTAUTH_SECRET | non present Vault | rotation manuelle |
| keybuzz-admin-v2-stripe (admin-v2-dev only) | STRIPE_SECRET_KEY | non present Vault | rotation manuelle |
| keybuzz-studio-api-auth (studio-api-prod+dev) | BOOTSTRAP_SECRET | non present Vault | rotation manuelle |
| keybuzz-studio-api-db (studio-api-prod+dev) | DATABASE_URL | non present Vault | rotation manuelle |
| keybuzz-studio-api-llm (studio-api-prod+dev) | ANTHROPIC_API_KEY, GEMINI_API_KEY, LLM_API_KEY, LLM_MODEL, LLM_PROVIDER, etc. | non present Vault | rotation manuelle |
| preview-basic-auth (website-dev) | auth | non present Vault | rotation manuelle |
| litellm-db-secret (keybuzz-ai) | DATABASE_URL, LITELLM_DATABASE_URL, USE_PRISMA_MIGRATE | partiellement Vault `secret/keybuzz/litellm/database_url` | rotation Vault possible |
| litellm-runtime-key (keybuzz-ai) | LITELLM_RUNTIME_KEY | non present Vault | rotation manuelle |
| ghcr-cred / ghcr-secret (all namespaces) | .dockerconfigjson | non present Vault | rotation manuelle PAT GitHub |
| minio (root user) | MINIO_ROOT_USER, MINIO_ROOT_PASSWORD | non present Vault (separate du keybuzz/minio client) | rotation MinIO root direct |
| vault-management (vault-admin-token) | token | meta-secret root | rotation Vault root operations |
| observability/grafana-admin-password | admin-password, admin-user | non present Vault | rotation manuelle Grafana |
| observability/alertmanager-* | helm-managed | non present Vault | helm release |
| argocd-* | password, secretkey, etc. | non present Vault | rotation ArgoCD admin |
| cert-manager letsencrypt | tls.key | hors scope (auto cert-manager) | non concerne |

### DEV non-ESO

mostly meme pattern que PROD avec quelques ajouts :
- keybuzz-api-postgres-static (DEV only, manuel non-ESO)

### Vault dynamic credentials (vault-backend-database)

| Workload | Detail |
|---|---|
| keybuzz-api-postgres-admin (DEV) | Database engine dynamic credentials, rotated automatically |
| (PROD ?) | non present, potentiellement opportunite optimisation |

**Verdict E7** : PROD a une couverture ESO partielle. Les rotations
critiques (Stripe, Google Ads, Meta, Shopify, Amazon SP-API, LLM,
ads-encryption) restent manuelles en PROD. **Recommandation Q-1B :
augmenter couverture ESO PROD avant rotation, ou faire rotation
manuelle directe sans passer par Vault**.

---

## E8 - Rotation design

### Phase Q-1B Vault-managed (30+ ExternalSecrets-managed)

```
Pour chaque ExternalSecret :
1. Generer nouvelle valeur hors chat (vault CLI write OU provider
   console pour secrets externes pris en charge par Vault wrapping)
2. `vault kv put secret/keybuzz/<path> key=NEW_VALUE` (mutation Vault)
3. Attendre refreshInterval (1h ou 5m)
   OU forcer trigger : `kubectl annotate externalsecret <name>
   force-sync="$(date +%s)"`
4. Verifier `kubectl get externalsecret <name> -o json |
   jq .status.refreshTime` change
5. Verifier `kubectl get secret <target> -o json |
   jq '.metadata.resourceVersion'` increment
6. Reloader detecte changement et rolling restart pods consommateurs
7. Verifier `kubectl rollout status deploy/<name>` OK
8. Tester service en aval (OTP, Inbox, billing, etc.)
9. Revoke ancienne valeur provider si applicable
```

Mutation point unique : Vault. Pas de touch Kubernetes Secret direct.

### Phase Q-1C PROD secrets manuels (15+)

```
Pour chaque secret manuel PROD :
1. Generer/rotation nouvelle valeur cote provider :
   - Stripe Dashboard pour STRIPE_SECRET_KEY / WEBHOOK_SECRET
   - Google Cloud Console pour GOOGLE_ADS_CLIENT_SECRET / REFRESH_TOKEN
   - Meta Business pour META_ACCESS_TOKEN (re-OAuth)
   - Shopify Partners pour SHOPIFY_CLIENT_SECRET
   - Amazon Seller Central pour AMAZON_SPAPI_CLIENT_SECRET (LWA app)
   - OpenAI Platform pour OPENAI_API_KEY
   - Anthropic Console pour ANTHROPIC_API_KEY
   - Google AI Studio pour GEMINI_API_KEY
   - 17track Dashboard pour TRACKING_17TRACK_API_KEY
   - AWS IAM pour AWS_SES_* (rotate IAM access key)
   - GitHub Settings pour GHCR PAT
2. `kubectl create secret generic <name> --from-literal=KEY=NEW_VALUE
   --dry-run=client -o yaml | kubectl apply -f -` (mutation K8s)
3. Reloader detecte et rolling restart pods
4. Validation
5. Revoke ancienne valeur cote provider
```

Mutation : K8s Secret + provider.

### Phase Q-1D Infra direct (Redis, RabbitMQ, Postgres roles, MinIO root)

#### Redis
```
1. Generer nouvelle password (16 chars random)
2. `vault kv put secret/keybuzz/redis REDIS_PASSWORD=NEW REDIS_URL=NEW`
   (vault-managed - reloader pod consommateurs)
3. SSH redis-01 + edit redis.conf + redis-cli CONFIG SET requirepass NEW
   (mutation Redis cluster) OU restart service avec nouvelle config
4. Verifier sentinels et replication continue
5. Validation services consommateurs
```

#### RabbitMQ
```
1. Generer nouveaux passwords pour chaque user RabbitMQ
2. SSH queue-01 + rabbitmqctl change_password USER NEW_PASS
3. Update K8s secret (si externalisable apporter en Vault) - actuellement
   PAS dans Vault, donc manuel kubectl
4. Reloader rolling restart pods consommateurs
5. Validation Inbox / outbound worker
```

#### Postgres app roles
```
1. Pour role applicatif (keybuzz_api, keybuzz_backend, etc.) :
   ALTER ROLE <user> PASSWORD 'NEW' (mutation Postgres via leader Patroni)
2. Update Vault path secret/keybuzz/prod/db_api PGPASSWORD=NEW
3. ESO sync sub 5m (refresh interval) -> K8s secret update
4. Reloader rolling restart
5. Validation
NOTE : si on utilisait vault-backend-database (dynamic creds), le mecanisme
      serait automatique sans mutation Postgres manuelle. PROD utilise
      static + ESO 5m refresh.
```

#### MinIO root
```
1. Generer nouveau MINIO_ROOT_PASSWORD
2. SSH minio-01 (controller) + mc admin user / docker-compose env update
3. Update K8s secret minio/minio-credentials
4. Reloader restart MinIO pods (mais minio est StatefulSet, careful)
5. Validation
```

### Phase Q-1E Rotation P1 (OAuth login + GHCR)

| Item | Mutation |
|---|---|
| GHCR PAT | GitHub PAT settings + update K8s secret ghcr-cred/ghcr-secret + rollout |
| OAuth Google Login | Google Console regenerate client_secret + update Vault secret/keybuzz/prod/auth + ESO sync + rollout |
| OAuth Azure AD | Azure Portal regenerate client_secret + update Vault + ESO sync + rollout |

### Phase Q-1F Validation post-rotation

Test surface :
- OTP signup DEV+PROD (cle Redis pour storage)
- Login NextAuth Google/Azure (client app)
- Stripe webhook test (mode test)
- LLM call test (via litellm)
- Inbox replies (outbound worker -> queue -> SES)
- Amazon SP-API connector
- Shopify webhook
- Admin v2 login

### Phase Q-1G Promotion PROD AS.17.0 + AS.17.0.1

GO Ludovic apres validation Q-1F + tests SaaS non-regressifs.

### Phase Q-1H Rotation P2 + cleanup

- Alertmanager Slack/SMTP
- Grafana admin
- ArgoCD admin
- Linear API token
- Cleanup secrets obsoletes (vault-emergency-token DEV ?)

### Rollback strategy

Pour chaque rotation :
- Garder ancienne valeur cote provider active 24h apres rotation
- Possibilite de revert K8s secret via kubectl apply ancienne version
- Vault keeps version history (KV v2) - rollback via `vault kv rollback`
- Si rolling restart casse : kubectl rollback deployment

---

## Risk register

| Risk ID | Severity | Finding | Evidence | Action |
|---|---|---|---|---|
| R-Q1A-1 | P0 | Token operateur `~/.vault-token` invalide/expire | 403 invalid token sur toutes operations admin | Ludovic re-login Vault avec ses credentials, generer token TTL court pour Q-1A-bis si necessaire OU passer directement Q-1B avec admin-token via K8s |
| R-Q1A-2 | P0 | Vault root token reel utilise = vault-management/vault-admin-token (K8s secret) | vault-token-renew CronJob lit ce K8s secret comme token argument | Confirmer son integrite (a ete read pendant fenetre attaque sur k8s-worker compromis ?) ; decision Ludovic rotation manuelle |
| R-Q1A-3 | P0 | Shamir unseal keys 5/3 | vault status confirme | Verifier integrite des 5 keyshares (offline storage Ludovic) ; rekey decide separement |
| R-Q1A-4 | P1 | PROD coverage ESO partielle = 15+ secrets manuels | E7 detail | augmenter couverture ESO PROD OU rotation manuelle prevue Q-1C |
| R-Q1A-5 | P1 | Naming inconsistance Vault KV paths (`secret/keybuzz/...` + `keybuzz/...` + `secret/data/keybuzz/...`) | E2 ExternalSecrets remoteRefs | hygiene future, pas urgent |
| R-Q1A-6 | P1 | Path `keybuzz/redis` partage DEV+PROD | E2 | rotation Redis DEV impacte PROD ; separer en `keybuzz/prod/redis` + `keybuzz/dev/redis` recommande |
| R-Q1A-7 | P2 | Multiples paths Vault pour backend-secrets (5 paths, memes 8 keys) | keybuzz-backend-dev keybuzz-backend-secrets ESO | simplifier en 1 seul path |
| R-Q1A-8 | OK | Vault HA Raft cluster sain (3 nodes, leader vault-03 non touche par incident) | E1 vault status | maintenir, vault-02 a rejoint cluster post-restore |
| R-Q1A-9 | OK | ESO operator + 30 ExternalSecrets SecretSynced=True | E2 | maintenir |
| R-Q1A-10 | OK | vault-token-renew CronJob OPERATIONNEL (last 2026-05-16T03:00 Complete) | E0 | maintenir monitoring |
| R-Q1A-11 | OK | Auth ESO -> Vault via K8s SA JWT (pas de token statique) | ClusterSecretStore config | best practice |
| R-Q1A-12 | OK | Aucune valeur secret en clair commit dans GitOps | AS.17.1Q-0 verifie | maintenir hygiene |

---

## Recommendation phase suivante AS.17.1Q-1B

### Prerequis avant Q-1B

1. **Decision Ludovic Vault root** : verification integrite
   vault-management/vault-admin-token. Si lue par attaquant pendant
   fenetre k8s-worker compromis, ROTATION ROOT requise (= rekey
   processus avec unseal keys, action critique downtime).
2. **Decision Ludovic Shamir unseal keys** : si stockage securise OK,
   pas de rekey. Sinon rekey + nouveau split 5/3.
3. **Re-login Ludovic Vault CLI** sur bastion pour debloquer admin
   operations (token operateur valide pour Q-1A-bis si besoin).
4. **GO Ludovic plan rotation** Q-1B - Q-1H.

### Q-1B execution proposee

Ordre :
1. **Q-1A-bis** (optionnel) : Ludovic re-login Vault et CE complete
   E3-E6 metadata auth/policies/engines/tokens (10 min)
2. **Q-1B Vault-managed rotations** (30 secrets) : changement valeurs
   dans Vault KV -> ESO sync -> reloader rollout. Estimation : sub 24h
   pour completer toutes refresh intervals.
3. **Q-1C PROD manuels** (15+ secrets) : rotation provider + K8s.
   Estimation : 1-2h par provider rotation, total 1-2 jours selon
   parallelisation Ludovic.
4. **Q-1D Infra direct** (Redis/RabbitMQ/Postgres/MinIO) : mutations
   coordonnees, downtime planifie. Estimation : 2-4h.
5. **Q-1E P1** : OAuth + GHCR.
6. **Q-1F Validation** : tests SaaS non-regression.
7. **Q-1G Promotion PROD** AS.17.0 + AS.17.0.1.
8. **Q-1H P2** + cleanup.

### Recommandations design specifiques

- **Avant Q-1B** : amelioration P2 Vault hygiene (separer paths
  Redis DEV/PROD, harmoniser naming, fusionner backend-secrets 5
  paths -> 1)
- **Avant Q-1C** : envisager migration des PROD manuels vers ESO
  (creer Vault paths + ExternalSecrets resources) pour simplifier
  futures rotations
- **Pendant Q-1B** : monitor ESO controller logs pour erreurs sync
- **Pendant Q-1D** : downtime planifie window communique
- **Apres Q-1G** : monitoring intensif 24h pour detecter eventuelles
  regressions

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1Q-1A Vault verification + rotation design read-only.
Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1A-KEY-323-VAULT-VERIFICATION-ROTATION-DESIGN-READONLY-01.md

Verdict : GO PARTIAL VAULT DESIGN WITH BLOCKERS

DECOUVERTES PRINCIPALES :

1. Vault HA Raft cluster sain et operationnel :
   - 3 nodes (vault-01/02/03), leader = vault-03 (non touche par
     incident)
   - vault-02 (restaure par Ludovic AS.17.1N-bis Lot A) a rejoint
     cluster Raft, standby
   - Shamir 5/3, KV v2, version 1.21.1
   - Raft committed = applied (in-sync)

2. External Secrets Operator architecture saine :
   - 30 ExternalSecrets actives, status SecretSynced=True
   - ClusterSecretStores vault-backend + vault-backend-database
   - Auth K8s ServiceAccount JWT (pas de token statique)
   - Refresh 1h ou 5m
   - 100% sync post-restore

3. vault-token-renew CronJob OPERATIONNEL :
   - Schedule daily 3h UTC
   - Last execution 2026-05-16T03:00 Complete (13s)
   - Rotates vault-app-token + vault-root-token + vault-token sur
     namespaces consommateurs

4. Inventory complet ExternalSecret -> Vault KV path mapping
   produit pour les 30 ExternalSecrets (chemins, refresh interval,
   target Secret, status).

BLOCKERS Q-1A :
- Token operateur ~/.vault-token sur bastion install-v3 est
  INVALIDE/EXPIRE (Code 403 sur toutes operations admin Vault).
  Auth methods, policies, secrets engines, token accessors et leases
  metadata non verifies.
- Pour debloquer : Ludovic re-login Vault sur bastion avec ses
  credentials et generer token TTL court pour Q-1A-bis OU passer
  directement Q-1B avec mecanisme alternative.

GAPS COUVERTURE PROD :
- 15+ secrets PROD manuels non-ESO (Stripe, Google Ads, Meta,
  Shopify, SES, ads-encryption, litellm, 17track, amazon-spapi,
  internal-proxy, admin-v2-auth, studio-api-*, etc.)
- Path Vault keybuzz/redis partage DEV+PROD (separation recommandee)
- Naming inconsistance KV paths (hygiene P2)

DESIGN ROTATION PLAN Q-1B propose :
- Q-1B Vault-managed (30+ ExternalSecrets) : rotation valeur Vault ->
  ESO sync -> reloader rollout
- Q-1C PROD manuels (15+) : rotation provider + kubectl + rollout
- Q-1D Infra direct (Redis, RabbitMQ, Postgres app roles, MinIO root)
- Q-1E P1 (OAuth login + GHCR)
- Q-1F Validation non-regression SaaS
- Q-1G Promotion PROD AS.17.0 + AS.17.0.1
- Q-1H P2 + cleanup

RISK REGISTER FINAL :
- P0 : Vault root token (vault-admin-token K8s secret) integrite a
  verifier ; unseal keys offline storage a confirmer
- P1 : PROD coverage ESO partielle ; naming inconsistance KV paths
- OK : Vault HA + ESO + vault-token-renew CronJob OPERATIONNELS

Aucune mutation effectuee. Aucune valeur secret affichee. Aucun root
token / unseal key / KV value lu. Token operateur invalide non
affiche.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic. Codex via connecteur Linear postera
apres GO commit.

---

## Hors scope / actions NON faites

- Aucun `vault kv get`
- Aucun `vault read secret/...`
- Aucun affichage root token / admin token / unseal key
- Aucun affichage VAULT_TOKEN env value
- Aucun affichage du token operateur `~/.vault-token` (invalide,
  non affiche)
- Aucun `vault token revoke / create / lookup -accessor`
- Aucun `vault write / delete / policy write`
- Aucun `vault operator unseal / rekey`
- Aucun `vault secrets disable / enable`
- Aucun `kubectl get secret -o yaml/json` affichant `.data`
- Aucun base64 -d
- Aucun cat de fichiers secrets/credentials
- Aucun changement Kubernetes Secret
- Aucun changement ExternalSecret
- Aucun rollout / restart / reload
- Aucun appel provider externe
- Aucun commit Git infra du rapport AS.17.1Q-1A (en attente GO -
  ce rapport untracked apres ecriture)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation declenchee

---

## Phrase cible finale

GO PARTIAL VAULT DESIGN WITH BLOCKERS. Vault HA Raft cluster sain
(3 nodes, leader vault-03 non touche), ESO + 30 ExternalSecrets
SecretSynced=True, vault-token-renew CronJob OPERATIONNEL, mapping
complet ExternalSecret -> Vault KV path produit. Bloqueurs : token
operateur ~/.vault-token invalide/expire (E3-E6 auth/policies/engines/
tokens metadata non verifies) ; PROD couverture ESO partielle (15+
secrets manuels). Design rotation Q-1B-H prepare avec ordre, mutations,
rollback, validation. Aucune valeur secret affichee, aucune mutation
effectuee. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu jusqu'a
Q-1B rotation effective et validee.

---
