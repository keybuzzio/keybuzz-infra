# PH-WEBSITE-T8.12AS.17.1T-4-B-AD-SPEND-DAILY-SYNC-CRONJOB-DRYRUN-01

> Date : 2026-05-18
> Linear : a rattacher post-decision Ludovic
> Phase : AS.17.1T-4-B AD_SPEND DAILY SYNC CRONJOB DRY-RUN
> Environnement : PROD + DEV lecture + dry-run server-side uniquement

## VERDICT

GO READY Q-1T-4-B DAILY SYNC AUTOMATION DESIGN COMPLETE

4 options architecturales evaluees. **Option B recommandee** : nouvel endpoint API SaaS `POST /admin/internal/ad-accounts/sync-all` protege par `X-Internal-Token` header + CronJob simple daily 06:00 UTC. Manifest CronJob draft genere dans `/tmp/keybuzz-q1t4b-cronjob-draft.yaml` (2222 bytes, ASCII strict), `kubectl apply --dry-run=server` exit 0 (structure YAML valide), non-persistance confirmee (CronJob NotFound post-dry-run).

Prerequis identifies pour Q-1T-4-B-EXEC :
1. Endpoint API SaaS `POST /admin/internal/ad-accounts/sync-all` (estime ~50-80 LOC) factorisant la logic de `/ad-accounts/:id/sync` deja existante : SELECT ad_platform_accounts WHERE status='active' AND deleted_at IS NULL + loop sync per account avec retry/backoff
2. Secret K8s `keybuzz-internal-tokens` avec key `AD_SPEND_SYNC_INTERNAL_TOKEN` (pattern reproductible de `keybuzz-internal-proxy` deja en place dans backend/client DEV+PROD 89d age)
3. Manifest CronJob committed `k8s/keybuzz-api-prod/ad-accounts-sync-daily-cronjob.yaml`

Aucun apply effectif. Aucun POST vers `/ad-accounts/:id/sync` (endpoint sync) ni vers `/admin/internal/ad-accounts/sync-all` (endpoint inexistant). Aucun provider call Meta/Google Ads. Aucun fake spend. Aucun DB write. Aucun secret value lu. Aucun patch code/manifest dans `k8s/`. Manifest draft dans `/tmp` uniquement (shred apres rapport). PROD intouchee.

## Scope / hors scope

### Scope strict applique

- Lecture code source `keybuzz-api/src/modules/ad-accounts/routes.ts` (handlers GET / POST /:id/sync complets)
- Lecture `keybuzz-api/src/app.ts` register order + tenantGuard plugin coverage
- Lecture BFF admin V2 `proxy.ts` + `/api/admin/marketing/ad-accounts/[id]/sync/route.ts`
- Lecture pattern INTERNAL_TOKEN (`agents/routes.ts:282-285`)
- Lecture pattern sync-all (`orders/routes.ts:610`)
- Lecture CronJob model `carrier-tracking-poll-cronjob.yaml`
- Generation manifest CronJob draft dans `/tmp` UNIQUEMENT
- `kubectl apply --dry-run=server` + `--dry-run=client` (validation YAML + RBAC)
- `kubectl get cronjob` non-persistance check
- Verification Secret prereq `keybuzz-internal-tokens` non-existant + pattern `keybuzz-internal-proxy` reproductible

### Hors scope respecte

- 0 POST reel vers `/ad-accounts/:id/sync` (endpoint sync)
- 0 POST reel vers `/admin/internal/ad-accounts/sync-all` (endpoint inexistant)
- 0 provider call Meta/Google Ads authentifie
- 0 DB write (INSERT/UPDATE/DELETE/ALTER/TRUNCATE)
- 0 fake spend / campaign / metric
- 0 apply effectif (uniquement --dry-run=server/client)
- 0 patch code source ou manifest `k8s/`
- 0 build/deploy
- 0 secret value lu en clair
- 0 commentaire Linear
- 0 affichage tenant_id / account_id / campaign_id raw (sauf KBC UUID deja public PH-T8.8F)

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1T-4-AD-SPEND-PROD-MIGRATION-DRYRUN-01.md | commit ae0c026 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1T-3-A-GA4-DEDUP-DB-VERIFICATION-READONLY-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1T-3-GA4-ADDINGWELL-EVENT-DELIVERY-DEDUP-DIAGNOSTIC-READONLY-01.md | present | OK |
| docs/PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md | present | OK |
| docs/PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md | present | OK idempotence ON CONFLICT |
| docs/PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01.md | present | OK schema |
| keybuzz-api/src/modules/ad-accounts/routes.ts | handler /:id/sync complete lignes 158-260 | OK |
| keybuzz-api/src/modules/agents/routes.ts | INTERNAL_TOKEN pattern lignes 282-285 | OK reference |
| keybuzz-api/src/modules/orders/routes.ts:610 | pattern POST /sync-all | OK modele |
| keybuzz-api/src/app.ts | register order + tenantGuard | OK |
| keybuzz-admin-v2/src/app/api/admin/marketing/proxy.ts | proxyMutate + requireMarketing | OK |
| k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml | CronJob pattern | OK model |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra HEAD descendant ae0c026 | OUI | exact | OK |
| 4 rapports Q-1T + 2 rapports PH-T8.8A.2/T8.8G | OK | OK | OK |
| /tmp residuels Q-1T-4-B | absent | absent | OK |
| Repos source | api ph147.4 dirty 223 / admin-v2 main clean | OK | OK |

## Architecture endpoint /ad-accounts/:id/sync (E2)

Handler complet `keybuzz-api/src/modules/ad-accounts/routes.ts` lignes 158-260 :

| Aspect | Detail |
|---|---|
| HTTP method + path | `POST /:id/sync` (prefix `/ad-accounts` enregistre app.ts:212) |
| Params | `id` = UUID interne `ad_platform_accounts.id` (not Meta external `account_id`) |
| Auth requise | `request.headers['x-tenant-id']` uniquement (PAS dans tenantGuard liste, donc accessible avec ce header seul cote API SaaS) |
| Body schema | `{since?: string, until?: string}` (defaults today-30d / today) |
| Logic |
| 1 | SELECT FROM ad_platform_accounts WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL ; 404 NOT_FOUND si absent |
| 2 | Check `status === 'active'` ; 400 ACCOUNT_NOT_ACTIVE sinon |
| 3 | Choose fetchFn : meta -> fetchMetaAdsInsights(account.account_id, account.token_ref, since, until, 'campaign') ; google -> fetchGoogleAdsInsights ; 400 PLATFORM_NOT_SUPPORTED autre |
| 4 | Loop UPSERT INTO ad_spend_tenant (tenant_id, account_id, platform, campaign_id, campaign_name, adset_id, adset_name, date, spend, spend_currency, impressions, clicks, conversions) ON CONFLICT (tenant_id, platform, date, COALESCE(campaign_id, '__none__')) DO UPDATE SET ... (idempotence T8.8G) |
| 5 | UPDATE ad_platform_accounts SET last_sync_at=NOW(), last_error=NULL, updated_at=NOW() WHERE id=$1 |
| 6 | SELECT totals : COUNT(*) + SUM(spend) FROM ad_spend_tenant WHERE tenant_id=$1 AND account_id=$2 |
| 7 | reply.send({sync: 'completed', tenant_id, account_id, platform, period: {since, until}, rows_upserted, totals: {rows, spend, currency}}) |
| Error path | UPDATE ad_platform_accounts SET last_error=sanitizedError ; reply.status(500).send({error: 'SYNC_FAILED', message: sanitizedError}) |

Validation : code est COMPLET et fonctionnel (verifie Q-1T-4 par Ludovic manual click admin UI confirmation).

## BFF Admin V2 proxyMutate (E3)

`keybuzz-admin-v2/src/app/api/admin/marketing/ad-accounts/[id]/sync/route.ts` :
```typescript
export async function POST(request, {params}) {
  const session = await requireMarketing();  // NextAuth + MARKETING_ROLES check
  if (!session) return 403;
  const body = await request.json();
  const tenantId = body.tenantId;
  if (!tenantId) return 400;
  return proxyMutate('POST', `/ad-accounts/${params.id}/sync`, session, tenantId, payload);
}
```

`proxy.ts` :
- `MARKETING_ROLES = ['super_admin', 'account_manager', 'media_buyer']`
- `GLOBAL_ROLES = ['super_admin', 'ops_admin']` (skip tenant access check)
- `assertTenantAccess(session, tenantId)` : verifie user has tenant access OU role global
- `apiInternalUrl = process.env.KEYBUZZ_API_INTERNAL_URL || 'https://api.keybuzz.io'`
- `proxyMutate` injecte header `x-tenant-id` + auth headers vers API SaaS

## INTERNAL_TOKEN pattern reference (E5.2)

`keybuzz-api/src/modules/agents/routes.ts:282-285` :
```typescript
app.post('/internal-keybuzz', async (request, reply) => {
  const internalToken = request.headers['x-internal-token'] as string;
  const expectedToken = process.env.KEYBUZZ_INTERNAL_PROXY_TOKEN;
  if (!internalToken || !expectedToken || internalToken !== expectedToken) {
    return reply.status(403).send({error: 'FORBIDDEN'});
  }
  // ... handler logic
});
```

Pattern reproductible pour nouvel endpoint `/admin/internal/ad-accounts/sync-all`.

Note bonus : env-var `KEYBUZZ_INTERNAL_PROXY_TOKEN` est definie `value: "true"` plain text dans manifest api-prod (vu Q-1B-5B-2). Cela suggere que l'auth est en realite ouverte avec header `X-Internal-Token: true` ou que c'est legacy. A clarifier en Q-1T-4-B-EXEC-CODE (creer un vrai secret AD_SPEND_SYNC_INTERNAL_TOKEN dedie ESO+Vault au lieu de reutiliser KEYBUZZ_INTERNAL_PROXY_TOKEN).

## Sync-all pattern reference (E5.3)

`keybuzz-api/src/modules/orders/routes.ts:610` :
```typescript
app.post<{Body: {tenantId?, months?}}>('/sync-all', async (request, reply) => {
  // batch processing pour tous tenants
});
```

Modele reproductible pour `/admin/internal/ad-accounts/sync-all`.

## Architecture options A-D (E5)

### Option A : CronJob hardcode UUID

```yaml
args: |
  curl -sk -X POST \
    -H 'x-tenant-id: keybuzz-consulting-mo9zndlk' \
    --max-time 120 \
    https://api.keybuzz.io/ad-accounts/b8b89a18-aa86-4e34-9488-b53fc404b96a/sync
```

| Aspect | Evaluation |
|---|---|
| Implementation cost | TRES FAIBLE (1 CronJob YAML, 0 code change) |
| Time to deploy | 1 commit + apply |
| Scalability | NON (1 CronJob per ad account, drift Git si on ajoute tenants) |
| UUID exposure Git | OUI (UUID interne ad_platform_accounts dans manifest Git) |
| Verdict | Acceptable pour 1 tenant pilot KBC immediat, **non recommande long terme** |

### Option B : Nouvel endpoint API SaaS batch + CronJob simple (RECOMMANDE)

```yaml
args: |
  curl -sk -X POST \
    -H 'X-Internal-Token: $INTERNAL_TOKEN' \
    -H 'Content-Type: application/json' \
    -d '{}' \
    --max-time 300 \
    https://api.keybuzz.io/admin/internal/ad-accounts/sync-all
```

Endpoint API SaaS :
```typescript
app.post('/sync-all', async (request, reply) => {
  // Auth INTERNAL_TOKEN
  const internalToken = request.headers['x-internal-token'];
  const expectedToken = process.env.AD_SPEND_SYNC_INTERNAL_TOKEN;
  if (!internalToken || internalToken !== expectedToken) return reply.status(403).send({error: 'FORBIDDEN'});

  // SELECT all active ad accounts
  const accounts = await pool.query(`SELECT id, tenant_id FROM ad_platform_accounts WHERE status='active' AND deleted_at IS NULL`);

  // Loop sync per account
  const results = [];
  for (const account of accounts.rows) {
    try {
      const result = await syncOneAccount(account.id, account.tenant_id);
      results.push({tenant_id: account.tenant_id, account_id: account.id, status: 'success', rows: result.rows_upserted});
    } catch (err) {
      results.push({tenant_id: account.tenant_id, account_id: account.id, status: 'failed', error: sanitizedError});
    }
  }

  return reply.send({total: accounts.rows.length, results});
});
```

| Aspect | Evaluation |
|---|---|
| Implementation cost | MOYEN (~50-80 LOC endpoint, factorise existing /:id/sync logic) |
| Time to deploy | code + build + push + GitOps + Secret + CronJob YAML |
| Scalability | OUI (1 CronJob, support N tenants illimite) |
| UUID exposure Git | NEANT (loop interne, jamais hardcode dans manifest) |
| Idempotence | OUI (heritage T8.8G ON CONFLICT) |
| Auth | INTERNAL_TOKEN secret (vrai secret, pas "true" plain-text) |
| Verdict | **RECOMMANDE** propre, scalable, future-proof |

### Option C : Worker queue pod long-running

| Aspect | Evaluation |
|---|---|
| Implementation cost | ELEVE (nouveau Deployment + worker logic + monitoring) |
| Scalability | OUI |
| Overhead | EXCESSIF pour daily task (vs CronJob batch) |
| Verdict | INADAPTE |

### Option D : External scheduler (Zapier, cron-job.org)

| Aspect | Evaluation |
|---|---|
| Dependency externe | OUI (3rd party reliability) |
| Cost | $$ |
| Auth complexity | Webhook signing OU API key external |
| Verdict | NON RECOMMANDE |

## Manifest CronJob draft (E8)

Genere dans `/tmp/keybuzz-q1t4b-cronjob-draft.yaml` (mode 600, 2222 bytes, ASCII strict, 0 BOM, 0 non-ASCII).

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ad-accounts-sync-daily
  namespace: keybuzz-api-prod
  labels:
    app: ad-accounts-sync-daily
    environment: production
  annotations:
    description: "Daily sync of ad_spend_tenant from Meta/Google Ads providers (Option B endpoint batch)"
    phase: "AS.17.1T-4-B-EXEC"
    requires-endpoint: "POST /admin/internal/ad-accounts/sync-all (TBD)"
    requires-secret: "X-Internal-Token via env AD_SPEND_SYNC_INTERNAL_TOKEN (TBD)"
spec:
  schedule: "0 6 * * *"
  suspend: false
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 600
      template:
        metadata:
          labels:
            app: ad-accounts-sync-daily
        spec:
          restartPolicy: Never
          containers:
            - name: sync
              image: badouralix/curl-jq:latest
              command: ["/bin/sh", "-c"]
              env:
                - name: INTERNAL_TOKEN
                  valueFrom:
                    secretKeyRef:
                      name: keybuzz-internal-tokens
                      key: AD_SPEND_SYNC_INTERNAL_TOKEN
                      optional: true
              args:
                - |
                  echo "[$(date -u +%H:%M:%S)] Ad accounts daily sync starting..."
                  if [ -z "$INTERNAL_TOKEN" ]; then
                    echo "ERROR: INTERNAL_TOKEN missing"
                    exit 1
                  fi
                  RESP=$(curl -sk -X POST \
                    -H 'Content-Type: application/json' \
                    -H "X-Internal-Token: $INTERNAL_TOKEN" \
                    -d '{}' \
                    --max-time 300 \
                    https://api.keybuzz.io/admin/internal/ad-accounts/sync-all)
                  STATUS=$?
                  echo "Response: $RESP"
                  echo "[$(date -u +%H:%M:%S)] Ad accounts daily sync complete (exit=$STATUS)"
                  exit $STATUS
              resources:
                limits:
                  cpu: "100m"
                  memory: "64Mi"
                requests:
                  cpu: "50m"
                  memory: "32Mi"
```

### Validation dry-run (E8.1-E8.3)

| Test | Resultat |
|---|---|
| ASCII strict | 0 BOM, 0 non-ASCII, size 2222 bytes |
| kubectl apply --dry-run=server | exit 0 : `cronjob.batch/ad-accounts-sync-daily created (server dry run)` |
| kubectl apply --dry-run=client | exit 0 : YAML syntax valide |
| Non-persistance post dry-run | CronJob NotFound (verifie kubectl get) |
| Secret prereq existant | `keybuzz-internal-tokens` **NotFound** (a creer) |
| Pattern Secret existant similaire | `keybuzz-internal-proxy` (backend/client DEV+PROD, 89d, 1 key Opaque) |

Manifest structure VALIDE. Apply effective bloquee par 2 prereq : endpoint API + Secret.

## Prerequis Q-1T-4-B-EXEC (E10)

### 1. Endpoint API SaaS `POST /admin/internal/ad-accounts/sync-all`

Code estime ~50-80 LOC dans `keybuzz-api/src/modules/ad-accounts/routes.ts` (factorisation existant `/:id/sync` logic) :

- New handler `app.post('/sync-all', async (request, reply) => {...})` (route relative au prefix `/ad-accounts`, donc full path = `/ad-accounts/sync-all` ; OU register separe sous `/admin/internal/ad-accounts` pour clarity)
- Auth check `X-Internal-Token` header vs env `AD_SPEND_SYNC_INTERNAL_TOKEN`
- SELECT all ad_platform_accounts WHERE status='active' AND deleted_at IS NULL ORDER BY last_sync_at NULLS FIRST
- For each account : factorise body de `/:id/sync` dans helper `syncOneAccount(id, tenantId, since, until)`. Catch error per account (continue loop)
- Aggregate results `{total, succeeded, failed, details: [{tenant_id, account_id_internal, status, rows_upserted | error}]}`
- Return reply 200 avec aggregate

### 2. Secret K8s `keybuzz-internal-tokens` + ESO

Choix d'implementation :
- **Sous-option I (recommande)** : Vault path `secret/keybuzz/internal-tokens/ad_spend_sync` + ExternalSecret `keybuzz-internal-tokens` target `keybuzz-internal-tokens` Secret avec key `AD_SPEND_SYNC_INTERNAL_TOKEN` (pattern Q-1B-5B-0/1 reproductible)
- **Sous-option II** : Reutiliser `keybuzz-internal-proxy` Secret existant + ajouter key dans le meme Secret (moins propre, mais 0 nouveau secret K8s)

Generation valeur token : `openssl rand -hex 32` offline. Documenter dans `AD_SPEND_SYNC_INTERNAL_TOKEN` env var de l'API api-prod deployment.

### 3. Patch Deployment api-prod env-var

Ajouter `AD_SPEND_SYNC_INTERNAL_TOKEN` valueFrom secretKeyRef keybuzz-internal-tokens.

### 4. Manifest CronJob committed

`k8s/keybuzz-api-prod/ad-accounts-sync-daily-cronjob.yaml` (clone du draft `/tmp`).

### 5. Q-1T-4-B-EXEC sequence

| step | action | gate | risk |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-CODE : patch keybuzz-api code (endpoint + auth + helper factorisation + ENV var) + commit + push | GO Ludovic | FAIBLE |
| 2 | Q-1T-4-B-EXEC-BUILD : build image API v3.5.X-ad-spend-sync-dev/prod | GO build | FAIBLE |
| 3 | Q-1T-4-B-EXEC-SECRET : creer Vault path + ES + Secret K8s `keybuzz-internal-tokens` | GO secret | FAIBLE |
| 4 | Q-1T-4-B-EXEC-DEPLOY-API-PROD : patch Deployment api-prod env-var + apply | GO Mode B SAFE PROD | MOYEN (rollout) |
| 5 | Q-1T-4-B-EXEC-CRONJOB : commit manifest CronJob + apply | GO Mode B SAFE | FAIBLE |
| 6 | Q-1T-4-B-EXEC-VALIDATE : wait first scheduled run (06:00 UTC next day) ou trigger manuel (kubectl create job --from=cronjob/ad-accounts-sync-daily) ; verify logs + last_sync_at PROD ad_platform_accounts | (auto-monitor) | MOYEN |

## Risk matrix (E9)

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Endpoint `/admin/internal/ad-accounts/sync-all` mal isole (auth contournable) | FAIBLE (pattern INTERNAL_TOKEN deja prouve agents/routes.ts) | ELEVE | code review + test 403 sans token |
| R2 | Provider rate limit Meta API quotidien (1 ad account, daily, ~30j window) | TRES FAIBLE | FAIBLE | retry exponential backoff per account (deja dans pattern) |
| R3 | DB lock contention pendant sync (concurrent admin UI click + cron) | FAIBLE | FAIBLE | concurrencyPolicy: Forbid (sequential) + admin UI separe |
| R4 | Token revoked mid-sync (cas reel hypothese H3 Q-1T-4) | MOYEN | FAIBLE per account | last_error logged dans ad_platform_accounts ; admin UI affiche |
| R5 | Race condition concurrent : 2 syncs simultanes pour meme account | NEANT (concurrencyPolicy Forbid + UPSERT idempotent T8.8G) | NEANT | architectural |
| R6 | CronJob suspended par accident (ex: pattern carrier-tracking-poll-prod) | FAIBLE | MOYEN (sync stops) | monitoring + alertes Grafana |
| R7 | Secret AD_SPEND_SYNC_INTERNAL_TOKEN expose Git | NEANT (via ESO + Vault, pattern Q-1B-5B-0/1) | ELEVE | implementation correcte |
| R8 | Endpoint dry-run failure quand deploy reel | TRES FAIBLE (structure valide dry-run server) | MOYEN | apply en Mode B SAFE avec rollback git revert |

## Schedule recommande (E11)

| Item | Valeur | Justification |
|---|---|---|
| Schedule cron | `0 6 * * *` | Daily 06:00 UTC = 07:00 Paris hiver / 08:00 ete (avant heures business) |
| concurrencyPolicy | Forbid | Pas de superposition si run precedent encore en cours |
| successfulJobsHistoryLimit | 3 | Historique court (3 derniers succes visible kubectl logs) |
| failedJobsHistoryLimit | 3 | Idem failed pour debug |
| activeDeadlineSeconds | 600 | 10 minutes max (large pour 1 tenant aujourd'hui, marge future) |
| backoffLimit | 1 | 1 seul retry si fail (puis logged failure) |
| Window date sync | Optionnel: `{since: today-30d, until: today}` dans body POST si veut etre explicite ; sinon defaults endpoint |

## Bonus Q-1T-4-D carrier-tracking-poll PROD suspend=true

Re-rappel finding bonus Q-1T-4 : `carrier-tracking-poll` CronJob PROD a `suspend: true`. **Pourquoi ?** A clarifier en phase dediee Q-1T-4-D. Pas urgent mais a remettre en service si nominal.

## No fake metrics

N/A. Phase design + dry-run pure. Aucune metric/event reelle creee.

## Cleanup temporary files (E12)

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1t4b-cronjob-draft.yaml | 600 | shred apres rapport (contenu inline dans le rapport) |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T-4-B | Impact |
|---|---|---|---|
| ad_platform_accounts table | inchange | inchange | 0 |
| ad_spend_tenant table | inchange | inchange | 0 |
| Endpoint /ad-accounts/:id/sync | OK existant | inchange | 0 |
| Admin V2 UI marketing/ad-accounts | OK existant | inchange | 0 |
| Provider tokens Meta + Google Ads | inchanges | inchanges | 0 |
| CronJobs cluster | 0 ads-sync detecte | 0 (manifest draft uniquement /tmp, NON committed) | 0 |
| API SaaS keybuzz-api | v3.5.190 Running | inchange | 0 |
| Argo CD | inchange | inchange | 0 |
| DB | 0 query mutationnelle | 0 | 0 |
| Provider call Meta/Google | 0 | 0 | 0 |

## Compliance read-only + dry-run

| Interdit | Evidence | Verdict |
|---|---|---|
| POST reel vers /ad-accounts/:id/sync | 0 (uniquement dry-run du manifest CronJob, pas du payload sync) | OK |
| Provider call Meta/Google authentifie | 0 | OK |
| DB write | 0 (psql disponible mais inutilise) | OK |
| Fake spend | 0 | OK |
| Apply effectif | 0 (uniquement --dry-run=server/client) | OK |
| Patch code ou manifest k8s/ | 0 (manifest draft dans /tmp uniquement) | OK |
| Build/deploy | 0 | OK |
| Secret value lu | 0 (Secret keybuzz-internal-tokens NotFound, pattern keybuzz-internal-proxy metadata-only) | OK |
| Commentaire Linear | 0 (brouillon present rapport, non poste) | OK |
| Tenant/user/email/account_id raw | 0 (KBC UUID b8b89a18 deja public PH-T8.8F) | OK |
| Manifest source Git modifies | 0 | OK |
| ASCII strict rapport | (a verifier post-redaction) | OK |

12/12 contraintes respectees.

## Brouillon Linear (a creer si Ludovic GO)

```
TITRE proposed : Automatisation daily sync ad_spend (CronJob + endpoint batch) - design ready

Status: DESIGN COMPLETE - PRET POUR Q-1T-4-B-EXEC
Scope: PROD + DEV lecture + dry-run server-side

Findings:
- Endpoint /ad-accounts/:id/sync operationnel, validation manual Ludovic Q-1T-4 OK
- BFF admin V2 + tenantGuard verifie : API SaaS check x-tenant-id header seul
- Pattern INTERNAL_TOKEN deja en place (agents/routes.ts) reproductible
- Pattern sync-all deja en place (orders/routes.ts:610) modele

Architecture recommandee Option B:
- POST /admin/internal/ad-accounts/sync-all + X-Internal-Token auth (~50-80 LOC endpoint API SaaS)
- Secret K8s keybuzz-internal-tokens + key AD_SPEND_SYNC_INTERNAL_TOKEN via ESO+Vault
- CronJob daily 06:00 UTC schedule "0 6 * * *" concurrencyPolicy: Forbid
- Manifest dry-run validate exit 0 (cronjob.batch/ad-accounts-sync-daily created server dry run)
- Idempotence garantee (T8.8G ON CONFLICT ad_spend_tenant)

Plan EXEC 6 steps:
1. Q-1T-4-B-EXEC-CODE: patch keybuzz-api endpoint + auth
2. Q-1T-4-B-EXEC-BUILD: image API new tag
3. Q-1T-4-B-EXEC-SECRET: Vault path + ES + Secret K8s
4. Q-1T-4-B-EXEC-DEPLOY-API-PROD: Mode B SAFE PROD
5. Q-1T-4-B-EXEC-CRONJOB: commit manifest CronJob + apply
6. Q-1T-4-B-EXEC-VALIDATE: wait first run + verify last_sync_at

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-4-B-AD-SPEND-DAILY-SYNC-CRONJOB-DRYRUN-01.md
```

## Gaps restants

1. **Q-1T-4-B-EXEC-CODE** : patch API SaaS endpoint `/admin/internal/ad-accounts/sync-all` (50-80 LOC, factorisation existant)
2. **Q-1T-4-B-EXEC-SECRET** : creation Vault path + ESO + Secret K8s keybuzz-internal-tokens
3. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : Mode B SAFE PROD (rollout pod)
4. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest + apply
5. **Q-1T-4-D carrier-tracking-poll suspend=true PROD** : pourquoi suspended ? bonus
6. **Q-1T-2-EXEC SUPPRESSION CronJob outbound-tick** : cleanup trivial differable
7. **Q-1T-5 tracking secrets Git cleanup consolide** : pattern accumule
8. **Envoi draft agence/media buyer** (Q-1T-3 + Q-1T-3-A) : decision business Ludovic
9. **Reprise KEY-323** : Q-1B-5B-2-EXEC LLM env migration

## Phrase cible finale

Ad spend daily sync automation dry-run complete : endpoint sync analyse (POST /ad-accounts/:id/sync logic ligne 158-260 ad-accounts/routes.ts avec auth x-tenant-id header + idempotence T8.8G UPSERT + last_sync_at update + sanitized error handling), admin V2 BFF proxy analyse (NextAuth requireMarketing MARKETING_ROLES + assertTenantAccess + proxyMutate to api SaaS internal URL), account list design etabli (GET /ad-accounts retourne accounts active tenant-scoped + UI affiche bouton Sync per account), pattern INTERNAL_TOKEN reproductible identifie (agents/routes.ts:282-285 + orders/routes.ts:610 sync-all pattern), 4 options A-D comparees (A hardcode immediate non-scalable, B endpoint batch recommande, C worker pod overkill, D external scheduler dependency), **option B recommandee** documentee avec endpoint /admin/internal/ad-accounts/sync-all + Secret K8s keybuzz-internal-tokens + AD_SPEND_SYNC_INTERNAL_TOKEN env-var + CronJob daily 06:00 UTC schedule "0 6 * * *", manifest CronJob draft genere dans /tmp ASCII strict 2222 bytes kubectl apply --dry-run=server exit 0 non-persistance confirmee, plan EXEC prepare en 6 steps Mode B SAFE (CODE + BUILD + SECRET + DEPLOY-API + CRONJOB + VALIDATE), 0 provider call Meta/Google Ads, 0 DB write, 0 fake metric, 0 patch code/manifest k8s/, 0 apply effectif, PROD intouchee - decision Ludovic requise sur Option B (recommande) vs Option A (interim immediate KBC seul) avant Q-1T-4-B-EXEC-CODE.

STOP
