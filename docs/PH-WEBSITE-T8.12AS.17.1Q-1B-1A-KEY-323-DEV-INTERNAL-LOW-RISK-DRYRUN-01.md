# PH-WEBSITE-T8.12AS.17.1Q-1B-1A-KEY-323-DEV-INTERNAL-LOW-RISK-DRYRUN-01

> Date : 2026-05-16
> Linear : KEY-323
> Phase : AS.17.1Q-1B-1A DEV internal low-risk DRY-RUN read-only
> Environnement : DEV only, Vault HA Raft + Kubernetes + External Secrets Operator
> Bastion : install-v3 (46.62.171.61)

## 1. VERDICT

GO DEV INTERNAL LOW-RISK DRYRUN READY.

Scope DEV confirme et restreint. Aucune mutation. Aucun secret lu ou affiche. 3 paths Vault KV cibles avec 4 properties precises (1 path mixte sur secret/keybuzz/auth necessite KV v2 patch property-only). 3 K8s Secrets ESO-managed cibles. 3 deployments DEV a restart (keybuzz-api, keybuzz-backend, keybuzz-client). 0 workload PROD impacte. Code source confirme usage internal generated (JWT signing, cookie signing, NextAuth session encryption, HMAC inbound webhook). Script Q-1B-1B prepare en design only avec patch property-only et openssl rand generation.

Phrase cible :
GO DEV INTERNAL LOW-RISK DRYRUN READY. Q-1B-1A confirme les paths DEV/key names/workloads exacts pour JWT/cookies/inbound webhook/auth DEV, sans lire de valeurs. Script Q-1B-1B prepare mais non execute. No mutation, no secret displayed. Rapport PH pret/commit selon GO. Brouillon Linear KEY-323 pret.

## 2. Scope exact confirme

### Inclus Q-1B-1 (4 properties sur 3 KV paths)

| KV path Vault | Property | Type secret |
|---|---|---|
| keybuzz/dev/jwt | JWT_SECRET | internal generated (JWT signing api) |
| keybuzz/dev/jwt | COOKIE_SECRET | internal generated (cookie signing api) |
| keybuzz/dev/backend-jwt | JWT_SECRET | internal generated (JWT signing backend cross-service) |
| keybuzz/dev/inbound-webhook | INBOUND_WEBHOOK_KEY | internal generated (HMAC inbound webhook) |
| secret/keybuzz/auth | nextauth_secret | internal generated (NextAuth session encryption DEV) |

Note : 5 properties total reparties sur 4 paths logiques (keybuzz/dev/jwt contient 2 properties).

### Non inclus Q-1B-1 (defer batches suivants)

| Path / property | Raison |
|---|---|
| keybuzz/internal-tokens : KEYBUZZ_INTERNAL_TOKEN | partage DEV+PROD, atomique synchro requise -> Q-1B-2 |
| keybuzz/minio + secret/data/keybuzz/minio + secret/keybuzz/prod/minio | service direct MinIO -> Q-1B-4 |
| keybuzz/dev/backend-product-db : PRODUCT_DATABASE_URL | Postgres connection direct -> Q-1B-4 |
| secret/keybuzz/auth : google_client_secret, azure_ad_client_secret | provider externe (Google/Azure OAuth) -> Q-1B-3 |
| secret/keybuzz/auth : nextauth_url, google_client_id, azure_ad_client_id, azure_ad_tenant_id | non-secrets (URLs et IDs publics) -> skip rotation |
| keybuzz-ads-encryption | clef chiffrement durable data -> blocker Category E |
| PROD secrets | tous, defer Q-1B-2/3/4/5/6 |
| secrets manuels hors ESO (keybuzz-google-ads, keybuzz-meta-ads, keybuzz-shopify, tracking-17track, etc.) | Category C/E -> Q-1B-3/5/6 |
| LITELLM_MASTER_KEY, OPENAI/ANTHROPIC keys | AI/LLM provider -> Q-1B-5 |

## 3. Context commit chain (KEY-323)

| Sequence | Commit | Rapport |
|---|---|---|
| AS.17.1Q-1A-bis | 1064c6e | Vault admin token replacement design |
| AS.17.1Q-1A-bis-exec | 346b17a | Vault admin token replacement execution Mode B SAFE |
| AS.17.1Q-1B-0 | 7846785 | KV secrets rotation plan read-only |
| AS.17.1Q-1B-1A | en cours (ce rapport) | DEV internal low-risk dry-run |

## 4. PHASE A0 - Preflight observe

| Check | Resultat |
|---|---|
| Bastion identite | install-v3 / 46.62.171.61 |
| Date UTC | 2026-05-16 16:12 |
| Date Paris | 2026-05-16 18:12 CEST |
| Git keybuzz-infra HEAD | 7846785 (Q-1B-0) clean |
| Fichiers sensibles temp | tous absents (4/4 verifie) |
| Vault 3 nodes | unsealed, Raft 1125911/1125911 sync |
| Active leader Vault | vault-03 (10.0.0.155) |
| ESO pods | 3/3 Running 0 restart age 29-31h |
| ExternalSecrets total | 30/30 SecretSynced=True |

## 5. PHASE A1 - ExternalSecrets target table (cibles confirmees)

| Namespace | ExternalSecret | Store | K8s Target | Refresh | Properties cibles Q-1B-1 |
|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api-jwt | vault-backend ClusterSecretStore | keybuzz-api-jwt | 1h | JWT_SECRET, COOKIE_SECRET (2/2) |
| keybuzz-backend-dev | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | JWT_SECRET, INBOUND_WEBHOOK_KEY (2/8 - 6 autres hors scope) |
| keybuzz-client-dev | keybuzz-auth-secrets | vault-backend | keybuzz-auth | 1h | NEXTAUTH_SECRET (1/7 - 6 autres hors scope) |

ATTENTION naming asymetrique client : ExternalSecret nom = `keybuzz-auth-secrets`, target K8s Secret = `keybuzz-auth` (sans suffixe). PROD inverse : ExternalSecret `keybuzz-auth-secrets` target K8s Secret `keybuzz-auth-secrets`. A documenter dans Gaps Q-1B-1A.

## 6. PHASE A2 - K8s Secret key names table (no values)

| Namespace | Secret | Type | Created | RV current | Keys totales | Keys rotatees Q-1B-1 |
|---|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api-jwt | Opaque | 2026-02-06 | 31857798 | 2 (COOKIE_SECRET, JWT_SECRET) | 2/2 |
| keybuzz-backend-dev | keybuzz-backend-secrets | Opaque | 2026-03-12 | 36935347 | 8 (INBOUND_WEBHOOK_KEY, JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_*, PRODUCT_DATABASE_URL) | 2/8 (JWT_SECRET + INBOUND_WEBHOOK_KEY) |
| keybuzz-client-dev | keybuzz-auth | Opaque | 2026-01-07 | 31857863 | 7 (AZURE_AD_*, GOOGLE_*, NEXTAUTH_*) | 1/7 (NEXTAUTH_SECRET) |
| keybuzz-client-dev | keybuzz-auth-secrets | - | - | - | ABSENT | N/A (nom asymetrique) |

Tous Opaque, tous geres par ExternalSecret (ownerReference confirmee).

ATTENTION effet de bord ESO patch property-only :
- ESO re-extrait toutes les properties du KV path apres patch -> K8s Secret bump rv complete (toutes les keys re-ecrites en data avec les memes valeurs sauf les properties patchees).
- Reloader si configure -> rolling restart de tous les pods qui consomment ce secret.
- 6 autres keys de keybuzz-backend-secrets non patchees mais leurs valeurs sont preservees par ESO car ESO les re-lit depuis Vault et la valeur est inchangee.

## 7. PHASE A3 - Workload consumers table (DEV)

| Namespace | Workload | Kind | Secret consomme | Type ref | Restart attendu Q-1B-1B |
|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api | Deployment | keybuzz-api-jwt | envSecret | OUI (impact rotation jwt+cookie) |
| keybuzz-api-dev | keybuzz-outbound-worker | Deployment | keybuzz-api-postgres, keybuzz-ses | envFrom | NON (pas de target Q-1B-1) |
| keybuzz-api-dev | sla-evaluator | CronJob | keybuzz-api-postgres | envFrom | NON |
| keybuzz-api-dev | sla-evaluator-escalation | CronJob | keybuzz-api-postgres | envFrom | NON |
| keybuzz-backend-dev | keybuzz-backend | Deployment | amazon-spapi-creds, keybuzz-backend-db, keybuzz-backend-secrets, vault-token (envFrom) + keybuzz-internal-proxy, vault-app-token (envSecret) | mixed | OUI (impact rotation backend-jwt + inbound-webhook via keybuzz-backend-secrets) |
| keybuzz-backend-dev | amazon-items-worker | Deployment | keybuzz-backend-db, vault-token | envSecret | NON (pas de backend-secrets) |
| keybuzz-backend-dev | amazon-orders-worker | Deployment | keybuzz-backend-db, vault-token | envSecret | NON |
| keybuzz-backend-dev | backfill-scheduler | Deployment | keybuzz-backend-db | envFrom | NON (et ImagePullBackOff pre-existant hors scope) |
| keybuzz-backend-dev | amazon-orders-backfill | CronJob | keybuzz-internal-proxy | envSecret | NON |
| keybuzz-backend-dev | amazon-orders-sync | CronJob | keybuzz-internal-proxy | envSecret | NON |
| keybuzz-client-dev | keybuzz-client | Deployment | keybuzz-auth | envSecret | OUI (impact rotation nextauth) |

**Total restart Q-1B-1B : 3 deployments DEV** (keybuzz-api, keybuzz-backend, keybuzz-client). 0 impact PROD. 0 impact CronJobs/workers (n'utilisent pas les targets cibles).

## 8. PHASE A4 - Code usage env var table

| Env var | Repo | Fichiers references |
|---|---|---|
| JWT_SECRET | keybuzz-api | src/modules/auth/routes.ts, src/modules/lifecycle/trial-lifecycle-unsubscribe.ts |
| COOKIE_SECRET | keybuzz-api | src/app.ts, src/modules/lifecycle/trial-lifecycle-unsubscribe.ts, src/modules/lifecycle/trial-lifecycle.routes.ts |
| JWT_SECRET | keybuzz-backend | src/main.ts, src/config/env.ts, src/config/jwt.ts, src/modules/webhooks/inboundEmailWebhook.routes.ts, src/modules/tenants/tenantSync.routes.ts, src/modules/inbound/inbound.routes.ts, generate-token.ts |
| INBOUND_WEBHOOK_KEY | keybuzz-backend | src/modules/inbound/inbound.routes.ts |
| NEXTAUTH_SECRET | keybuzz-client | .next/standalone/middleware.js (NextAuth integration, source dans NextAuth config) + multiple compiled route handlers OAuth |

Classification confirmee :

| Property | Category | Regenerable ? | Risk |
|---|---|---|---|
| JWT_SECRET (api) | A internal generated | OUI (openssl rand) | invalide tous JWT issued DEV (logout testers) |
| COOKIE_SECRET (api) | A internal generated | OUI | invalide cookies signes DEV (logout testers) |
| JWT_SECRET (backend) | A internal generated | OUI | invalide cross-service JWT, restart backend coupe le pool transit |
| INBOUND_WEBHOOK_KEY | A internal generated | OUI | invalide HMAC inbound webhook (impact = source emetteur webhook doit etre informee si externe, sinon test-only DEV) |
| NEXTAUTH_SECRET (client) | A internal generated | OUI | invalide encryption JWT session NextAuth (logout testers OAuth) |

## 9. PHASE A5 - Future Q-1B-1B execution script outline (NON execute)

### Pre-requis avant Q-1B-1B execution

1. Phase separee creation policy `keybuzz-kv-rotator-q1b1-temp` via root token temporaire Shamir Ludovic.
2. Capability `patch` sur `secret/data/keybuzz/dev/jwt`, `secret/data/keybuzz/dev/backend-jwt`, `secret/data/keybuzz/dev/inbound-webhook`, `secret/data/keybuzz/auth`.
3. Token TTL 2h, depose dans `/root/.vault-kv-rotator.tmp` mode 600 root:root.
4. GO Ludovic explicite execution.

### Outline script Q-1B-1B (a fournir en prompt CE separe)

```
PHASE B1.0 Preflight script
- ssh install-v3 verify VAULT_ADDR + kubectl context
- test -f /root/.vault-kv-rotator.tmp mode 600 size > 20
- vault token lookup-self (metadata only, redacted)
- capture BEFORE: kubectl get secret keybuzz-api-jwt keybuzz-backend-secrets keybuzz-auth resourceVersion + ExternalSecret status

PHASE B1.1 Generate new values offline (script local in shell, never echo)
- NEW_JWT_API=$(openssl rand -base64 48 | tr -d "\n")
- NEW_COOKIE_API=$(openssl rand -base64 48 | tr -d "\n")
- NEW_JWT_BACKEND=$(openssl rand -base64 48 | tr -d "\n")
- NEW_INBOUND=$(openssl rand -hex 32)
- NEW_NEXTAUTH=$(openssl rand -base64 48 | tr -d "\n")
- verify all variables non-empty, length >= 32

PHASE B1.2 Patch KV property-only via vault kv patch
- vault kv patch secret/keybuzz/dev/jwt JWT_SECRET="$NEW_JWT_API" COOKIE_SECRET="$NEW_COOKIE_API"
- vault kv patch secret/keybuzz/dev/backend-jwt JWT_SECRET="$NEW_JWT_BACKEND"
- vault kv patch secret/keybuzz/dev/inbound-webhook INBOUND_WEBHOOK_KEY="$NEW_INBOUND"
- vault kv patch secret/keybuzz/auth nextauth_secret="$NEW_NEXTAUTH"
- (note : si vault kv patch ne supporte pas le mount alias, utiliser KV v2 PATCH HTTP via curl avec -H "Content-Type: application/merge-patch+json")
- unset NEW_* immediatly after patch

PHASE B1.3 Force ESO refresh
- kubectl -n keybuzz-api-dev annotate externalsecret keybuzz-api-jwt force-sync=$(date +%s) --overwrite
- kubectl -n keybuzz-backend-dev annotate externalsecret keybuzz-backend-secrets force-sync=$(date +%s) --overwrite
- kubectl -n keybuzz-client-dev annotate externalsecret keybuzz-auth-secrets force-sync=$(date +%s) --overwrite
- (note : annotate est mutation kubectl autorisee uniquement en Q-1B-1B execution avec GO)

PHASE B1.4 Wait ESO sync + verify
- sleep 30s
- for each ES : kubectl get externalsecret -n NS NAME -o json | jq '.status.conditions[] | select(.type=="Ready") | .status' must be "True"
- for each Secret : kubectl get secret -n NS NAME -o json | jq '.metadata.resourceVersion' must be BUMPED vs BEFORE

PHASE B1.5 Restart deployments (only the 3 impacted)
- if reloader is configured for these Secrets (annotation reloader.stakater.com/auto=true), restart will be automatic
- otherwise kubectl rollout restart deployment -n keybuzz-api-dev keybuzz-api
- kubectl rollout restart deployment -n keybuzz-backend-dev keybuzz-backend
- kubectl rollout restart deployment -n keybuzz-client-dev keybuzz-client

PHASE B1.6 Wait pods ready
- kubectl rollout status deployment -n keybuzz-api-dev keybuzz-api --timeout=180s
- kubectl rollout status deployment -n keybuzz-backend-dev keybuzz-backend --timeout=180s
- kubectl rollout status deployment -n keybuzz-client-dev keybuzz-client --timeout=180s

PHASE B1.7 Validation
- kubectl get pods -n keybuzz-api-dev -n keybuzz-backend-dev -n keybuzz-client-dev (Running 1/1, 0 restart new)
- kubectl get events -A --sort-by=.lastTimestamp | tail -50 | egrep "warn|fail|error" filter
- vault token lookup-self (TTL > 60min ok)

PHASE B1.8 Cleanup
- shred -u /root/.vault-kv-rotator.tmp
- verify absent
- script local : unset VAULT_TOKEN, unset NEW_*

PHASE B1.9 Validation manuelle Ludovic
- DEV testers logout puis re-login OK (sessions invalides apparaissent)
- pas de test PROD
- pas d'envoi message client
- pas de call provider
```

### Contraintes garde-fous script

- Aucune lecture valeur ancienne (vault kv patch ne lit pas avant).
- Aucun echo de NEW_* variables.
- Aucun logging des keys generees.
- Token rotator TTL 2h auto-expire securite.
- Paths Vault limites a 4 (jwt, backend-jwt, inbound-webhook, auth).
- Pas de capability sur autres paths.
- Restart limite a 3 deployments DEV.
- 0 mutation PROD.

## 10. PHASE A6 - Validation future Q-1F-1

### Tests Vault/ESO post-Q-1B-1B

| Test | Attendu | Methode |
|---|---|---|
| Vault HA Raft | 3/3 unsealed, Raft sync | vault status par node |
| ExternalSecrets target | SecretSynced=True (3 cibles) | kubectl get externalsecret -n NS NAME |
| K8s Secret target | resourceVersion bumped | kubectl get secret -o jsonpath rv |
| Vault audit | new entries pour KV patch (verify count, no value content) | kubectl logs vault si audit file backend |

### Tests pods

| Pod | Attendu | Methode |
|---|---|---|
| keybuzz-api-dev/keybuzz-api | Running 1/1 nouveau pod, ancien Terminated | kubectl get pods |
| keybuzz-backend-dev/keybuzz-backend | Running 1/1 nouveau pod | kubectl get pods |
| keybuzz-client-dev/keybuzz-client | Running 1/1 nouveau pod | kubectl get pods |
| Autres workers/CronJobs DEV | non touches | kubectl get pods age unchanged |
| Pods PROD | non touches | kubectl get pods -n keybuzz-api-prod, etc. |

### Tests auth/session DEV

| Test | Attendu |
|---|---|
| Session JWT testers DEV emise avant rotation | invalide (verify HTTP 401 sur endpoint protege) |
| Login Ludovic DEV apres rotation | OK (nouveau JWT emis avec nouveau JWT_SECRET) |
| Cookie signature verify | nouveau cookie genere avec nouveau COOKIE_SECRET |
| NextAuth session client testeur DEV | logout force (cookie nextauth invalide) |
| NextAuth login Ludovic apres rotation | OK |

### Tests inbound webhook DEV

| Test | Attendu |
|---|---|
| Webhook HMAC test avec ancien INBOUND_WEBHOOK_KEY | rejete 401 |
| Webhook HMAC test avec nouveau INBOUND_WEBHOOK_KEY | accepte (uniquement si endpoint test DEV existe et GO Ludovic) |

ATTENTION : ne pas envoyer webhook externe sans GO Ludovic explicite. Si emetteur externe (Octopia, marketplace, etc.) doit etre coordonne, defer.

### Tests events

| Test | Attendu |
|---|---|
| kubectl get events -A | no Vault 403, no ESO auth error |
| ClusterSecretStore conditions | Valid=True (re-validated post rotation) |

### Tests PROD (control negatif)

| Test | Attendu |
|---|---|
| ExternalSecrets PROD 17/17 | SecretSynced=True unchanged |
| Pods PROD age | unchanged (no restart cross-env) |

## 11. PHASE A7 - Rollback design

### Conditions trigger rollback

- ExternalSecret SecretSynced=False post-rotation
- Pod CrashLoopBackOff post-restart
- Vault 403 dans logs apps
- Ludovic ne peut plus login DEV apres rotation

### Procedure rollback

```
PHASE R1 KV rollback
- vault kv rollback -version=N secret/keybuzz/dev/jwt
- vault kv rollback -version=N secret/keybuzz/dev/backend-jwt
- vault kv rollback -version=N secret/keybuzz/dev/inbound-webhook
- vault kv rollback -version=N secret/keybuzz/auth
- (N = version capturee BEFORE en Phase B1.0)

PHASE R2 Force ESO refresh
- kubectl annotate externalsecret force-sync=$(date +%s) sur les 3 ES

PHASE R3 Restart deployments
- kubectl rollout restart deployment sur les 3 deployments DEV

PHASE R4 Validation rollback
- pods Running 1/1
- testers login OK avec ancien JWT_SECRET
- ExternalSecrets SecretSynced=True
```

Note : KV v2 conserve historique versions (par defaut 10 versions retention). Rollback rapide possible.

Pre-requis rollback : capability `rollback` sur `secret/data/*` requise dans policy keybuzz-kv-rotator-q1b1-temp OU root temp Ludovic re-genere.

## 12. PHASE A8 - Risk register

| Risk | Severity | Status | Mitigation |
|---|---|---|---|
| ESO patch property-only declenche bump rv complete + restart pods consommateurs supplementaires non-cibles | P2 | observe (effet ESO normal) | accepte DEV, monitorer pods autres si refresh declenche restart inattendu |
| vault kv patch necessite capability "patch" non garantie sur policy actuelle | P1 | a verifier en Q-1B-1B preflight | future policy doit inclure patch sur data paths cibles |
| secret/keybuzz/auth mixte Category A + C + non-secret | P0 mitige | observe | patch property-only sur nextauth_secret SEUL, ne pas toucher Google/Azure/NEXTAUTH_URL |
| naming asymetrique keybuzz-auth-secrets ExternalSecret vs keybuzz-auth target K8s Secret (DEV vs PROD divergence) | P2 | observe | Q-1B-1B doit cibler les bons noms par env, eviter confusion |
| Inbound webhook emetteur externe ? | P1 | non-teste | si emetteur DEV externe (Octopia/marketplace test), coordonner avant rotation. Si tests internes only, OK. |
| Sessions DEV invalidees | P3 acceptable | observe | DEV = testers only, logout/re-login normal |
| Rollback necessite capability rollback policy | P1 | a inclure dans policy keybuzz-kv-rotator-q1b1-temp | ajouter `rollback` capability OU re-Shamir Ludovic |
| KV v2 versions retention par defaut 10 versions | P2 observe | OK 10 suffit | apres 10 rotations, anciennes versions supprimees auto |
| Reloader configure ou non sur ces Secrets ? | P1 | a verifier en Q-1B-1B preflight | si non, ajout kubectl rollout restart manuel |
| trial-lifecycle CronJob PROD consomme keybuzz-api-jwt PROD ? | P3 hors scope DEV | observe | trial-lifecycle-dryrun-29648640 utilise keybuzz-api-jwt mais en PROD only, pas DEV. PROD non touche par Q-1B-1B. |

## 13. Decisions Ludovic requises avant Q-1B-1B

1. **Mode execution Q-1B-1B** : Mode A (Ludovic execute) vs Mode B SAFE (CE runner depose kv-rotator token via Ludovic) ?
2. **Policy keybuzz-kv-rotator-q1b1-temp** : OK design section 9 ? Inclure capability `rollback` ?
3. **Inbound webhook DEV** : confirmer emetteurs externes connus a coordonner (probable aucun, tests internes only).
4. **secret/keybuzz/auth patch property-only** : OK ne toucher que `nextauth_secret`, preserver les 6 autres properties (Google/Azure/URL/IDs) ?
5. **Reloader status** : verifier en Q-1B-1B preflight si reloader.stakater.com configure sur les 3 Secrets OU restart manuel.
6. **Timing Q-1B-1B** : maintenant ou plus tard (low-risk DEV donc flexible) ?
7. **Capture BEFORE versions Vault KV** : OK utiliser vault kv metadata get (read-only metadata, pas de value) pour capturer version actuelle avant patch ? Necessite capability metadata read.

## 14. Brouillon Linear KEY-323 (a poster par Codex apres commit)

```
AS.17.1Q-1B-1A DEV internal low-risk DRY-RUN COMPLETE

Commit rapport : <CE remplira apres push>
Verdict : GO DEV INTERNAL LOW-RISK DRYRUN READY.

Resume technique :
- Scope DEV confirme: 3 paths Vault KV + 5 properties (keybuzz/dev/jwt JWT_SECRET+COOKIE_SECRET, keybuzz/dev/backend-jwt JWT_SECRET, keybuzz/dev/inbound-webhook INBOUND_WEBHOOK_KEY, secret/keybuzz/auth nextauth_secret).
- 3 K8s Secrets ESO-managed cibles (keybuzz-api-dev/keybuzz-api-jwt, keybuzz-backend-dev/keybuzz-backend-secrets, keybuzz-client-dev/keybuzz-auth).
- 3 deployments DEV impactes (keybuzz-api, keybuzz-backend, keybuzz-client). 0 workload PROD/worker/CronJob impacte.
- Code usage confirme internal generated (JWT signing, cookie signing, NextAuth session, HMAC inbound webhook).
- ATTENTION secret/keybuzz/auth mixte Category A (nextauth_secret) + C (Google/Azure OAuth) + non-secret (URL/IDs) -> patch property-only obligatoire.
- ATTENTION effet de bord ESO patch -> bump rv K8s Secret complete (mais valeurs autres properties preservees).
- Future Q-1B-1B script outline avec openssl rand generation + vault kv patch property-only + ESO force-sync + 3 deployment restarts.
- Validation Q-1F-1 par domaine definie (Vault/ESO/pods/auth/inbound/events/PROD-control).
- Rollback design via KV v2 versions (defaut 10 retention).
- Risk register 10 risques.
- Aucun secret lu/affiche pendant cette phase read-only.

Decisions Ludovic requises (7 items section 13 du rapport).

Gaps :
- keybuzz-internal-tokens (cross-env DEV+PROD) defer Q-1B-2.
- Provider secrets Google/Azure OAuth defer Q-1B-3.
- Postgres/MinIO/Redis/SMTP defer Q-1B-4.
- LITELLM/OpenAI/Anthropic defer Q-1B-5.
- Marketplace Amazon/Shopify/Octopia defer Q-1B-6.
- backfill-scheduler ImagePullBackOff hors scope.
- PROD promotion AS.17.0/AS.17.0.1 NO GO maintenu.

Pas de changement de status KEY-323 ou KEY-322 sans GO supplementaire.
```

## Conformite interdits Q-1B-1A

| Interdit | Respect |
|---|---|
| vault kv get/put/patch | OK : aucun |
| vault read/write secret/... | OK : aucun |
| vault policy write | OK : aucun |
| vault token create/revoke | OK : aucun |
| kubectl get secret -o yaml | OK : seulement -o json + jq filter sans .data values |
| base64 -d | OK : aucun |
| kubectl annotate | OK : aucun |
| kubectl rollout restart | OK : aucun |
| kubectl apply/patch/edit/delete | OK : aucun |
| Provider call | OK : aucun |
| Test envoyant email/message/webhook externe | OK : aucun |
| Ancien vault-admin-token utilise | OK : non utilise |
| Bastion install-v3 uniquement | OK |
| credentials/secrets locaux | OK : non touches |
| Git push/commit | OK : aucun (STOP A8 GO requis) |

## No fake metrics / no fake events

Aucun login, webhook, billing, marketplace ou tracking event fabrique. Toutes observations issues de :
- kubectl get/describe (metadata + keys only)
- jq filtrage strict sans .data values
- grep code env-var names seulement
- vault status (metadata only)

Marqueurs : observe, non teste, bloque utilises ou Q-1B-1B/Q-1F-1 sections.

## AI feature parity / anti-regression

Cette phase ne touche pas IA/LLM. Scope verifie :
- 0 inclusion LITELLM_MASTER_KEY (defer Q-1B-5).
- 0 inclusion OpenAI/Anthropic keys (defer Q-1B-5).
- 0 inclusion studio-api LLM (defer si scope).

Aucun appel provider IA, aucun message client, aucun workflow declenche.

## STOP final

Rapport complet pret. STOP avant A8 commit + push pour GO Ludovic explicite.

Ne pas executer Q-1B-1B.
Ne pas creer keybuzz-kv-rotator-q1b1-temp.
Ne pas faire de rotation KV.
Ne pas restart workload.
Ne pas promotion PROD AS.17.0 / AS.17.0.1.
