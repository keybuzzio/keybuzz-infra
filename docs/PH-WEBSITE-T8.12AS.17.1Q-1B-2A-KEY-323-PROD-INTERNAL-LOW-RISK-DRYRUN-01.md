# PH-WEBSITE-T8.12AS.17.1Q-1B-2A-KEY-323-PROD-INTERNAL-LOW-RISK-DRYRUN-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-2A PROD internal low-risk DRY-RUN read-only
> Environnement : PROD inventory/design read-only + controle DEV cross-env
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO Q-1B-2A DRY-RUN READY.

Dry-run read-only complete sans mutation. Inventaire PROD + cross-env DEV+PROD cartographie. 4 paths Vault KV PROD identifies (3 PROD purs + 1 cross-env `keybuzz/internal-tokens` partage DEV+PROD). 5 properties cibles candidates Q-1B-2B (JWT_SECRET+COOKIE_SECRET api + JWT_SECRET backend + NEXTAUTH_SECRET property-only client + KEYBUZZ_INTERNAL_TOKEN cross-env). 4 deployments confirmes restart (3 PROD : api/backend/client + 1 DEV cross-env : backend). 2 deployments admin-v2 (DEV+PROD) en option a decider Ludovic. Reloader auto present sur keybuzz-api-prod + keybuzz-client-prod uniquement ; keybuzz-backend-prod + keybuzz-backend-dev necessitent restart manuel (consistance avec DEV Q-1B-1B). PROD ages 21h+ unchanged, 0 Warning events. AI feature parity OK. Aucun secret lu/affiche.

Decouverte security disclosure pre-existant (P2) : route `keybuzz-client/app/api/debug-env/route.ts` retourne sans auth `nextAuthUrl` complet + prefix 4 chars GOOGLE/AZURE Client IDs + booleens has* + filtre envKeys GOOGLE|AZURE|NEXTAUTH. A discuter avant Q-1B-2B (disable/protect ou accepte).

Phrase finale :
STOP AS.17.1Q-1B-2A - GO Q-1B-2A DRY-RUN READY. Rapport docs-only pret, en attente GO Ludovic commit/push. Q-1B-2B EXEC et PROD promotion restent NO GO.

## 2. Scope

### Scope read-only strict

Verifie sans mutation :
- Etat Vault HA + ESO baseline.
- ExternalSecrets PROD + cross-env mapping vers paths Vault KV.
- K8s Secrets PROD + DEV + admin-v2 metadata + key names + ownerReferences (no values).
- Workloads DEV+PROD consumers via envFrom/envSecret/volumes.
- Reloader annotations per deployment (auto + secret-specific).
- Code/env usage grep sur 4 repos applicatifs.
- Risk register avec disclosure findings.
- Future execution Q-1B-2B design (NO EXEC).

### Hors scope strict

Aucune action :
- aucune rotation PROD ni DEV.
- aucun vault kv patch/put/write/token create/revoke/policy write.
- aucun kubectl apply/patch/edit/set/annotate/restart/delete/create.
- aucun token rotator ni root temp Shamir.
- aucun build/deploy.
- aucun provider externe.
- aucun webhook mutationnel.
- aucun affichage secret/token/JWT/cookie/bearer/base64/KV value.
- aucune promotion PROD AS.17.0/AS.17.0.1.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports KEY-323 chain

| Sequence | Commit | Description |
|---|---|---|
| Q-1Q-0 | e6e0f26 | secrets exposure inventory |
| Q-1Q-1A | b27e94a | Vault verification rotation design |
| Q-1Q-1A-bis-exec | 346b17a | Vault admin token replacement execution Mode B SAFE |
| Q-1Q-1B-0 | 7846785 | KV secrets rotation plan |
| Q-1Q-1B-1A | 423ad49 | DEV internal low-risk dry-run |
| Q-1Q-1B-1B | fcc1170 | DEV internal low-risk execution Mode B SAFE |
| Q-1Q-1F-1 | 556772c | DEV post-rotation validation read-only |
| Q-1Q-1B-2A | en cours (ce rapport) | PROD internal low-risk dry-run |

Linear ticket : KEY-323. Verdict Q-1F-1 : GO DEV POST-ROTATION VALIDATION OK.

## 4. Preflight

| Check | Attendu | Resultat | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 12:19 UTC / 14:19 CEST | OK |
| Git infra branch | main | main | OK |
| Git infra HEAD | 556772c ou descendant | 556772cdafa42bf87c843784de23a3f70e2d99aa | OK |
| Worktree | clean | clean | OK |
| Rapports KEY-323 requis | 5 presents | Q-1A-bis-exec + Q-1B-0 + Q-1B-1A + Q-1B-1B + Q-1F-1 presents | OK |
| Fichiers sensibles temp | absent | 5/5 absent | OK |

## 5. Vault / ESO baseline

| Component | Etat | Detail | Verdict |
|---|---|---|---|
| Vault HA 3/3 | unsealed | Raft 1138677/1138677 sync, vault-03 active leader | OK |
| ExternalSecrets cluster-wide | 30/30 True | aucun degraded | OK |
| ClusterSecretStores | 2/2 Ready=True | vault-backend + vault-backend-database | OK |
| ESO pods | 3/3 Running | external-secrets + cert-controller + webhook 2d+ ages 0 restart | OK |
| CronJob vault-token-renew | actif | schedule 0 3 * * *, dernier run 9h ago Complete | OK |
| CronJob monitoring-alerts | actif | */2 * * * *, regular Complete | OK |

## 6. ExternalSecrets mapping (cibles Q-1B-2B)

### 3 ExternalSecrets PROD purs

| Namespace | ExternalSecret | Store | Target | Refresh | Remote key | Property | Ready | refreshTime |
|---|---|---|---|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | keybuzz/prod/jwt | JWT_SECRET | True SecretSynced | 2026-05-17T11:26:43Z |
| keybuzz-api-prod | keybuzz-api-jwt | vault-backend | keybuzz-api-jwt | 1h | keybuzz/prod/jwt | COOKIE_SECRET | True | (idem) |
| keybuzz-backend-prod | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | keybuzz/prod/backend-jwt | JWT_SECRET | True SecretSynced | 2026-05-17T11:59:35Z |
| keybuzz-backend-prod | keybuzz-backend-secrets | vault-backend | keybuzz-backend-secrets | 1h | keybuzz/internal-tokens | KEYBUZZ_INTERNAL_TOKEN | True | (idem) |
| keybuzz-client-prod | keybuzz-auth-secrets | vault-backend | keybuzz-auth-secrets | 1h | secret/keybuzz/prod/auth | NEXTAUTH_SECRET | True SecretSynced | 2026-05-17T11:36:24Z |

Note : keybuzz-backend-secrets PROD contient 5 keys hors scope Q-1B-2B (MINIO_*, PRODUCT_DATABASE_URL) qui resteront preservees par patch property-only.

Note : keybuzz-auth-secrets PROD contient 5 keys hors scope Q-1B-2B (GOOGLE_*, AZURE_AD_*) qui resteront preservees par patch property-only.

### ExternalSecret DEV cross-env (KEYBUZZ_INTERNAL_TOKEN)

| Namespace | ExternalSecret | Target | Property |
|---|---|---|---|
| keybuzz-backend-dev | keybuzz-backend-secrets | keybuzz-backend-secrets | KEYBUZZ_INTERNAL_TOKEN -> keybuzz/internal-tokens |

Le path `keybuzz/internal-tokens` est partage DEV+PROD. Rotation atomique requise simultanement sur les 2 K8s Secrets DEV+PROD pour eviter desynchronisation cross-service.

### ExternalSecrets admin-v2 (scope optionnel)

| Namespace | ExternalSecret | Target | Property |
|---|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | keybuzz-admin-v2-bootstrap | ADMIN_BOOTSTRAP_EMAIL + ADMIN_BOOTSTRAP_PASSWORD_HASH |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | keybuzz-admin-v2-bootstrap | ADMIN_BOOTSTRAP_EMAIL + ADMIN_BOOTSTRAP_PASSWORD_HASH |

ADMIN_BOOTSTRAP_PASSWORD_HASH : decision Ludovic GO/NO GO separe avant inclusion Q-1B-2B (cf section 13).
ADMIN_BOOTSTRAP_EMAIL : email Ludovic non-secret, NE PAS rotate.

## 7. K8s Secrets metadata

| Namespace | Secret | Type | rv current | Keys count | Keys (no values) | Owner | reloader annot K8s Secret |
|---|---|---|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api-jwt | Opaque | 31857841 | 2 | COOKIE_SECRET, JWT_SECRET | ES keybuzz-api-jwt | absent |
| keybuzz-backend-prod | keybuzz-backend-secrets | Opaque | 36935360 | 7 | JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_SECRET_KEY, PRODUCT_DATABASE_URL | ES keybuzz-backend-secrets | absent |
| keybuzz-client-prod | keybuzz-auth-secrets | Opaque | 40891619 | 6 | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET | ES keybuzz-auth-secrets | absent |
| keybuzz-backend-dev | keybuzz-backend-secrets | Opaque | 69633502 | 8 | INBOUND_WEBHOOK_KEY, JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_*, PRODUCT_DATABASE_URL | ES keybuzz-backend-secrets | absent (Q-1B-1B baseline) |
| keybuzz-admin-v2-dev | keybuzz-admin-v2-bootstrap | Opaque | 60743650 | 2 | ADMIN_BOOTSTRAP_EMAIL, ADMIN_BOOTSTRAP_PASSWORD_HASH | ES | absent |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | Opaque | 37239641 | 2 | ADMIN_BOOTSTRAP_EMAIL, ADMIN_BOOTSTRAP_PASSWORD_HASH | ES | absent |

Divergences DEV/PROD observees :
- keybuzz-backend-secrets PROD a 7 keys vs DEV 8 keys : INBOUND_WEBHOOK_KEY ABSENT en PROD (PROD utilise secret manuel separe `inbound-webhook-key`).
- keybuzz-auth-secrets PROD a 6 keys vs DEV 7 keys : NEXTAUTH_URL ABSENT en PROD (asymetrie config DEV/PROD).
- K8s Secret keybuzz-auth-secrets PROD nomme avec suffixe `-secrets` (PROD) vs DEV target `keybuzz-auth` (sans suffixe).

Aucune annotation reloader sur K8s Secrets (les annotations reloader sont sur Deployments).

## 8. Workload impact map (Q-1B-2B futur)

### Cibles confirmees restart Q-1B-2B (4 deployments)

| Env | Namespace | Workload | Kind | Secret consume | Mode | Restart needed future | Reloader auto |
|---|---|---|---|---|---|---|---|
| PROD | keybuzz-api-prod | keybuzz-api | Deployment | keybuzz-api-jwt | envSecret JWT_SECRET + COOKIE_SECRET | OUI (rotation jwt+cookie) | true (AUTO) |
| PROD | keybuzz-backend-prod | keybuzz-backend | Deployment | keybuzz-backend-secrets | envFrom (entier) | OUI (rotation backend-jwt + internal-tokens) | absent (MANUAL) |
| PROD | keybuzz-client-prod | keybuzz-client | Deployment | keybuzz-auth-secrets | envSecret NEXTAUTH_SECRET (+ Google/Azure) | OUI (rotation nextauth property-only) | true (AUTO) |
| DEV | keybuzz-backend-dev | keybuzz-backend | Deployment | keybuzz-backend-secrets | envFrom (entier) | OUI (rotation internal-tokens cross-env) | absent (MANUAL) |

### CronJob/Job hereditiers (no restart action needed, new pod per tick)

| Env | Namespace | Workload | Kind | Secret consume | Impact |
|---|---|---|---|---|---|
| PROD | keybuzz-api-prod | trial-lifecycle-dryrun | CronJob | keybuzz-api-jwt envSecret | nouvelle valeur hereditee au prochain tick (zero action) |

### Workloads NON impactes (verify negative)

| Workload | Pourquoi non impacte |
|---|---|
| keybuzz-api-prod/keybuzz-outbound-worker | consomme keybuzz-api-postgres + keybuzz-ses (pas keybuzz-api-jwt) |
| keybuzz-backend-prod/amazon-items-worker + amazon-orders-worker | consomment keybuzz-backend-db + vault-token (pas keybuzz-backend-secrets envFrom) |
| keybuzz-backend-prod/backfill-scheduler | consomme keybuzz-backend-db envFrom only (ImagePullBackOff pre-existant hors scope) |
| keybuzz-api-dev/keybuzz-api | hors scope Q-1B-2B (DEV jwt deja rotate en Q-1B-1B) |
| keybuzz-client-dev/keybuzz-client | hors scope (DEV nextauth_secret deja rotate Q-1B-1B) |
| keybuzz-backend-dev/amazon-items/orders-worker | n'utilisent pas keybuzz-backend-secrets |

### Cibles option admin-v2 (a decider Ludovic)

| Env | Namespace | Workload | Secret consume | Restart |
|---|---|---|---|---|
| PROD | keybuzz-admin-v2-prod | keybuzz-admin-v2 | keybuzz-admin-v2-bootstrap envSecret | OUI si scope (MANUAL reloader absent) |
| DEV | keybuzz-admin-v2-dev | keybuzz-admin-v2 | keybuzz-admin-v2-bootstrap envSecret | OUI si scope (MANUAL reloader absent) |

## 9. Reloader / restart dry-run classification

| Namespace | Deployment | reloader.stakater.com/auto | secret.reloader.stakater.com/reload | Pod actuel age | Future restart mode | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api | true | absent | 21h | AUTO (bump rv -> reloader trigger) | OK |
| keybuzz-backend-prod | keybuzz-backend | absent | absent | 21h | MANUAL kubectl rollout restart | requires GO Ludovic |
| keybuzz-client-prod | keybuzz-client | true | absent | 2d1h | AUTO | OK |
| keybuzz-backend-dev | keybuzz-backend | absent | absent | 14h | MANUAL kubectl rollout restart (atomique avec backend-prod) | requires GO Ludovic |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | absent | absent | 2d+ | MANUAL (si scope inclus) | requires GO Ludovic |
| keybuzz-admin-v2-dev | keybuzz-admin-v2 | absent | absent | 2d+ | MANUAL (si scope inclus) | requires GO Ludovic |

Synthese restart groups Q-1B-2B :
- Groupe AUTO reloader : keybuzz-api-prod + keybuzz-client-prod (2 deployments)
- Groupe MANUAL CROSS-ENV ATOMIQUE : keybuzz-backend-prod + keybuzz-backend-dev (2 deployments, rotation simultanee KEYBUZZ_INTERNAL_TOKEN)
- Groupe MANUAL OPTIONNEL admin-v2 : keybuzz-admin-v2-prod + keybuzz-admin-v2-dev (2 deployments, si scope inclus)

Total cibles confirmees : 4 deployments restart (3 PROD + 1 DEV).
Total cibles si admin-v2 inclus : 6 deployments restart.

## 10. Code/env usage dry-run

| Repo | Env var | Files / modules | Runtime implication | Verdict |
|---|---|---|---|---|
| keybuzz-api | JWT_SECRET | src/modules/auth/routes.ts, src/modules/lifecycle/trial-lifecycle-unsubscribe.ts | sign JWT api user sessions, invalidation tous JWT issued PROD post-rotation | OK regenerable |
| keybuzz-api | COOKIE_SECRET | src/app.ts, src/modules/lifecycle/trial-lifecycle-unsubscribe.ts, src/modules/lifecycle/trial-lifecycle.routes.ts | sign cookies api, invalidation cookies PROD post-rotation | OK regenerable |
| keybuzz-backend | JWT_SECRET | src/main.ts, src/config/env.ts, src/config/jwt.ts (probable + webhooks/tenants/inbound routes) | sign JWT backend cross-service, invalidation tous JWT backend issued | OK regenerable |
| keybuzz-backend | KEYBUZZ_INTERNAL_TOKEN | src/modules/marketplaces/amazon/amazonFees.routes.ts, src/modules/marketplaces/amazon/amazonFees.service.ts | proxy token cross-service backend -> api Amazon Fees module, doit rester en sync cross-env (DEV+PROD partagent meme value) | OK regenerable mais atomique cross-env requise |
| keybuzz-client | NEXTAUTH_SECRET | middleware.ts, app/api/debug-env/route.ts | NextAuth session encryption client, invalidation sessions client PROD post-rotation | OK regenerable mais ATTENTION debug-env route (cf section 14 risk) |
| keybuzz-admin-v2 | ADMIN_BOOTSTRAP_PASSWORD_HASH | src/lib/auth.ts | hash admin bootstrap login Ludovic | OK regenerable mais nouveau hash bcrypt requis a generer offline |
| keybuzz-admin-v2 | ADMIN_BOOTSTRAP_EMAIL | src/lib/auth.ts | email admin Ludovic, NON-secret | NE PAS rotate |

## 11. Future execution design Q-1B-2B (NO EXEC)

### Pre-requis Ludovic Mode A (avant Q-1B-2B)

1. Generate root token temporaire Shamir (3 keyshares).
2. Creation policy `keybuzz-kv-rotator-q1b2-temp` scoped capacities :
   - auth/token/lookup-self read
   - auth/token/revoke-self update
   - secret/metadata/keybuzz/prod/jwt read
   - secret/metadata/keybuzz/prod/backend-jwt read
   - secret/metadata/keybuzz/prod/auth read
   - secret/metadata/keybuzz/internal-tokens read
   - secret/data/keybuzz/prod/jwt create+patch+update
   - secret/data/keybuzz/prod/backend-jwt create+patch+update
   - secret/data/keybuzz/prod/auth create+patch+update
   - secret/data/keybuzz/internal-tokens create+patch+update
   - SI admin-v2 inclus : metadata + data sur secret/keybuzz/admin-v2/bootstrap
3. Token rotator non-root TTL 2h orphan=false depot bastion /root/.vault-kv-rotator-q1b2.tmp mode 600.

### Phases Q-1B-2B Mode B SAFE CE (NO EXEC dans Q-1B-2A)

| Future phase | Action | Owner | Mutation | STOP gate |
|---|---|---|---|---|
| B-1.0 Preflight | identite + git + rotator file metadata + Vault + ES + targets | CE | none | n/a |
| B-1.1 Verify rotator | metadata redacted + sanity gates (policy + non-root + TTL >= 1800s) + capabilities probe + negative tests | CE | none | STOP si policy/TTL KO |
| B-1.2 Capture BEFORE | vault kv metadata get 4 paths + K8s rv 4 secrets + pod ages 6 deployments + reloader annotations | CE | none | n/a |
| **B-1.3 GO Gate** | STOP attendre GO Ludovic explicite avant mutation | Ludovic | n/a | **OBLIGATOIRE** |
| B-1.4 Generate + patch | runner SCP atomique : openssl rand x5 + vault kv patch x4 property-only + unset NEW_* + verify v2 via metadata | CE avec GO | Vault KV write | STOP si patch echec |
| B-1.5 ESO force-sync | kubectl annotate force-sync x3 ES PROD + 1 ES DEV cross-env | CE | K8s mutation safe | STOP si annotate fail |
| B-1.6 Wait + verify rv bump | sleep 30s + ES Ready=True 4 cibles + K8s Secret rv BUMPED vs BEFORE + keys count preserves | CE | none | STOP si rv unchanged |
| **B-1.7 GO Gate restart** | STOP attendre GO Ludovic pour restart manuel keybuzz-backend-prod + keybuzz-backend-dev atomique simultane | Ludovic | n/a | **OBLIGATOIRE** |
| B-1.8 Restart MANUAL | kubectl rollout restart keybuzz-backend-prod + keybuzz-backend-dev SIMULTANE + rollout status 180s | CE avec GO | K8s mutation | STOP si rollout fail |
| B-1.9 Verify auto restart | check keybuzz-api-prod + keybuzz-client-prod nouveau pods (reloader-trigger) + rollout status | CE | none | STOP si pods non-Ready |
| B-1.10 Validation | Vault + ES + apps + logs filter + PROD apps Running + DEV cross-env Running + no Vault 403 | CE | none | STOP si regression |
| B-1.11 Cleanup | rotator self-revoke (si TTL > 0) + shred /root/.vault-kv-rotator-q1b2.tmp + shred runners + Ludovic revoke root temp | CE + Ludovic | none / file delete | n/a |
| B-1.12 Rapport docs-only ASCII strict | sections 19 obligatoires + brouillon Linear + STOP avant commit/push | CE | local write | STOP |
| **B-1.13 GO Gate commit** | STOP attendre GO Ludovic | Ludovic | n/a | **OBLIGATOIRE** |

Plan Q-1B-2B integre 3 STOP gates Ludovic explicites (avant mutation KV + avant restart manuel cross-env + avant commit/push).

Note specifique restart cross-env atomique : keybuzz-backend-prod + keybuzz-backend-dev DOIVENT etre restarte simultanement pour eviter desynchronisation KEYBUZZ_INTERNAL_TOKEN. Si un seul pod redemarre, il aura nouveau token mais l'autre ancien token = appels cross-service fail. Fenetre de risque minimale via kubectl rollout restart parallele (les 2 commandes en immediate succession).

## 12. Risk register

| Risk | Severity | Scope | Mitigation | Decision needed |
|---|---|---|---|---|
| Invalidation sessions JWT PROD client | P1 attendu | PROD client+api | testers/utilisateurs PROD doivent re-login post-rotation, zero client reel actuellement = acceptable | Ludovic accept |
| Invalidation cookies PROD | P1 attendu | PROD client | idem JWT sessions | Ludovic accept |
| Invalidation JWT backend PROD cross-service | P1 attendu | PROD backend | invalidation tokens transit api->backend transitoire pendant restart, restart group atomique minimize fenetre | Ludovic accept |
| KEYBUZZ_INTERNAL_TOKEN cross-env desync | P0 critique | DEV+PROD backend | restart simultane keybuzz-backend-prod + keybuzz-backend-dev mandatory, ne pas separer en deux runs | Ludovic GO restart atomique requis |
| Reloader absent keybuzz-backend-prod | P1 known | PROD backend | restart manuel kubectl rollout restart, meme pattern que Q-1B-1B B7 DEV | Ludovic GO B-1.7 |
| Rollback KV v2 previous version | P2 mitigation | tous | KV v2 conserve 10 versions retention par defaut, rollback rapide via vault kv rollback -version=N (necessite capability rollback dans policy futur OU re-Shamir Ludovic) | Ludovic decide rollback strategy |
| OAuth keys preservation secret/keybuzz/prod/auth | P0 critique | PROD client | patch property-only obligatoire pour nextauth_secret, ne JAMAIS rotate les autres 5 properties GOOGLE/AZURE/NEXTAUTH_URL/IDs publics (provider Q-1B-3) | confirmer property-only strict |
| ADMIN_BOOTSTRAP_PASSWORD_HASH inclusion/exclusion | P2 decision | admin-v2 DEV+PROD | bcrypt hash require generation offline Ludovic + cross-env DEV+PROD synchronisation, ADMIN_BOOTSTRAP_EMAIL non-secret a NE PAS rotate | Ludovic GO/NO GO scope |
| No real clients currently | P0 mitigation | business | absence clients reels reduit impact UX, mais PROD runtime cross-service reste critique | accepte (validation Q-1B-1B/Q-1F-1 confirme zero client reel) |
| Provider/manual secrets out of scope | P0 isolation | tous | Q-1B-2B ne touche pas Google/Azure OAuth (provider), MinIO/Postgres/Redis/SMTP (infra direct), Stripe/SES/OpenAI/Anthropic (provider externe), keybuzz-ads-encryption (durable) | confirme isolation scope |
| **debug-env route disclosure pre-existant** | P2 SECURITY DISCLOSURE | PROD client | `keybuzz-client/app/api/debug-env/route.ts` retourne sans auth `nextAuthUrl` complet + prefix 4 chars GOOGLE_CLIENT_ID + AZURE_AD_CLIENT_ID + booleens has* + filtre envKeys | Ludovic decide : disable route avant Q-1B-2B / proteger par auth / accepter |
| Inbound-webhook divergence DEV/PROD | P2 known | DEV ESO vs PROD manuel | divergence pre-existante documentee Q-1B-0, hors scope Q-1B-2 (defer architecture cleanup) | observe |
| backfill-scheduler ImagePullBackOff | P1 pre-existant | DEV+PROD backend | hors scope Q-1B-2, phase dediee future | observe |
| Vault kv get bloque post-Q-1B-2B (token rotator revoque) | P2 known | future validation | preuve indirecte K8s rv bumped + ESO refresh fresh suffisante (pattern Q-1F-1) | accepte |

## 13. PROD negative baseline

| PROD component | Baseline | Result | Verdict |
|---|---|---|---|
| keybuzz-api-prod/keybuzz-api | Running 1/1 21h | keybuzz-api-7d5fd7d697-kf9dz Running age=21h restarts=0 | OK stable depuis R1 Q-1A-bis-exec |
| keybuzz-api-prod/keybuzz-outbound-worker | Running 1/1 21h | keybuzz-outbound-worker-7bfb4944c4-tnsl6 Running age=21h restarts=0 | OK (hors scope, ne sera pas restart Q-1B-2B) |
| keybuzz-backend-prod/keybuzz-backend | Running 1/1 21h | keybuzz-backend-56b9bc977d-v6jrw Running age=21h restarts=0 | OK |
| keybuzz-client-prod/keybuzz-client | Running 1/1 2d1h | keybuzz-client-68556c9dbf-5zmjk Running age=2d1h restarts=0 | OK (non touche par R1) |
| Warning events keybuzz-api-prod 2h | 0 attendu | 0 | OK |
| Warning events keybuzz-backend-prod 2h | 0 attendu | 0 | OK |
| Warning events keybuzz-client-prod 2h | 0 attendu | 0 | OK |
| ExternalSecrets PROD | 10/10 True | 10/10 True (5 api-prod + 2 backend-prod + 1 client-prod + 2 admin-v2-prod) | OK |
| K8s Secrets PROD cibles rv | unchanged depuis Q-1F-1 baseline | 31857841 / 36935360 / 40891619 inchanges | OK PROD intact |

## 14. DEV cross-env baseline (internal-tokens)

| DEV component | Secret/path | Consumer | Future restart required | Verdict |
|---|---|---|---|---|
| keybuzz-backend-dev/keybuzz-backend pod | keybuzz/internal-tokens via keybuzz-backend-secrets envFrom | Deployment keybuzz-backend | OUI atomique simultane avec keybuzz-backend-prod | OK pod baseline Running 1/1 14h post-Q-1B-1B |
| DEV restart group | keybuzz-backend-dev/keybuzz-backend | seul deployment DEV impacte par cross-env | restart manuel reloader absent | OK |
| Warning events keybuzz-backend-dev 2h | 0 attendu | 0 | OK |
| Risk casser validation DEV Q-1F-1 | P1 | DEV backend restart force re-validation post-Q-1B-2B | re-validation manual Ludovic apres Q-1B-2B execution | observe |

Implication critique : Q-1B-2B doit etre planifie avec fenetre validation DEV+PROD simultanee, car keybuzz-backend-dev recevra impact collatteral (restart pour internal-tokens cross-env sync).

## 15. AI feature parity / anti-regression

| Surface | Check read-only | Resultat | Verdict |
|---|---|---|---|
| IA / autopilot (LiteLLM) | 2 pods Running | litellm-55bcfd7769-sfw8l Running 1/1 41d + litellm-55bcfd7769-xlhm7 Running 1/1 2d1h | OK |
| Images runtime PROD | tag inchange | v3.5.190-channels-tenantguard-prod api, v1.0.47-cross-env-guard-fix-prod backend, v3.5.197-channels-bff-userauth-prod client | OK aucun build Q-1B-2A |
| Aucun manifest IA/Inbox/connecteur modifie | aucun changement | repos applicatifs non touches | OK |
| Inbox / messages | no new error burst | logs DEV post-Q-1B-1B normaux (cf Q-1F-1 rapport) | OK |
| Connecteurs marketplace | no new error burst | Amazon SP-API errors pre-existants (hors scope), Octopia/Shopify normaux | OK |
| Commandes / tracking colis | no new error burst | logs DEV post-Q-1B-1B normaux, PROD inchangee | OK |

Aucun test mutationnel IA execute. Aucun message client. Aucun appel provider. Aucun email envoye. Aucun webhook externe.

## 16. No fake metrics / no fake events

| Item | Source | Window | Mutation | Verdict |
|---|---|---|---|---|
| K8s Secret rv (6 cibles) | kubectl get secret jsonpath rv | snapshot Q-1B-2A | non | reel |
| ExternalSecret Ready/refreshTime | kubectl get externalsecret jsonpath status | snapshot Q-1B-2A | non | reel |
| Vault Raft index | vault status 3 nodes | snapshot Q-1B-2A | non | reel |
| Deployment metadata + annotations | kubectl get deployment jsonpath | snapshot Q-1B-2A | non | reel |
| Pod ages | kubectl get pods | snapshot Q-1B-2A | non | reel |
| Code grep counts | grep -rIl --include filter | repos source | non | reel |
| Events count | kubectl get events --field-selector | 2h window | non | reel |

Aucun fake event/metric. Aucun signup_complete, purchase, CAPI/GA4, paiement test, marketing mutation, dashboard pollution.

## 17. Decisions Ludovic required (avant Q-1B-2B EXEC)

1. **Scope exact Q-1B-2B** : confirmer 4 paths PROD (jwt + backend-jwt + auth NEXTAUTH_SECRET property-only + internal-tokens cross-env). Inclure ou exclure `keybuzz/admin-v2/bootstrap` (ADMIN_BOOTSTRAP_PASSWORD_HASH) ?
2. **Rotation `keybuzz/internal-tokens` atomique DEV+PROD** : confirmer restart simultane keybuzz-backend-dev + keybuzz-backend-prod (mandatory pour eviter desynchronisation cross-service). OK ?
3. **Window operation PROD** : choisir fenetre d'exec (heure creuse, weekend, immediate). Validation Ludovic UX requise post-execution.
4. **Acceptation invalidation sessions PROD** : zero client reel actuellement confirme (cf Q-1B-1B/Q-1F-1), donc accepte d'inviter testers/Ludovic a re-login post-rotation ?
5. **Restart groups DEV/PROD** : confirmer architecture restart 4 deployments (3 PROD + 1 DEV cross-env) OR 6 deployments si admin-v2 inclus ?
6. **Rollback strategy KV v2** : capability `rollback` a inclure dans policy `keybuzz-kv-rotator-q1b2-temp` OU rollback via re-Shamir Ludovic ad-hoc ?
7. **Mode B SAFE rotator dedie** : confirmer pattern Q-1B-1B (Ludovic Mode A creation policy + token rotator + CE Mode B SAFE execution avec STOP gates) ?
8. **NO GO provider/manual/infra/LLM** : confirmer scope strict Q-1B-2B = internal generated PROD uniquement, exclure Google/Azure OAuth (Q-1B-3), MinIO/Postgres/Redis/SMTP (Q-1B-4), OpenAI/Anthropic/LiteLLM (Q-1B-5), marketplace (Q-1B-6) ?
9. **debug-env disclosure** : decision sur `keybuzz-client/app/api/debug-env/route.ts` retournant nextAuthUrl + prefix 4 chars Client IDs + boolean has* sans auth : disable avant Q-1B-2B / proteger par auth NextAuth / accepter (information disclosure P2 isolee) ?
10. **PROD promotion AS.17.0 / AS.17.0.1** : confirmer NO GO maintenu jusqu'a Q-1B-2B post-validation Q-1F-2 separe ?

## 18. Linear draft comment (a poster par Codex apres commit)

```
AS.17.1Q-1B-2A PROD internal low-risk DRY-RUN COMPLETE

Commit rapport Q-1F-1 : 556772c (GO DEV POST-ROTATION VALIDATION OK)
Commit rapport Q-1B-2A : <CE remplira apres push>
Verdict : GO Q-1B-2A DRY-RUN READY.

Resume technique :
- Vault HA 3/3 Raft 1138677 sync, ESO 30/30 True, ClusterSecretStores 2/2 Ready.
- Scope Q-1B-2B confirme : 4 paths Vault KV / 5 properties (3 PROD purs + 1 cross-env atomique).
- 3 ExternalSecrets PROD cibles Ready=SecretSynced refreshTime fresh aujourd'hui :
  - keybuzz-api-prod/keybuzz-api-jwt -> keybuzz/prod/jwt (JWT_SECRET + COOKIE_SECRET)
  - keybuzz-backend-prod/keybuzz-backend-secrets -> keybuzz/prod/backend-jwt (JWT_SECRET) + keybuzz/internal-tokens (KEYBUZZ_INTERNAL_TOKEN cross-env)
  - keybuzz-client-prod/keybuzz-auth-secrets -> secret/keybuzz/prod/auth (NEXTAUTH_SECRET property-only)
- 1 ExternalSecret DEV cross-env : keybuzz-backend-dev/keybuzz-backend-secrets share KEYBUZZ_INTERNAL_TOKEN.
- 3 K8s Secrets PROD metadata (rv 31857841 / 36935360 / 40891619 inchanges) + 1 K8s Secret DEV cross-env (rv 69633502 inchange post-Q-1B-1B) + 2 K8s Secrets admin-v2 (option scope).
- 4 deployments confirmes restart Q-1B-2B :
  - keybuzz-api-prod/keybuzz-api (AUTO reloader)
  - keybuzz-client-prod/keybuzz-client (AUTO reloader)
  - keybuzz-backend-prod/keybuzz-backend (MANUAL kubectl rollout restart, reloader absent)
  - keybuzz-backend-dev/keybuzz-backend (MANUAL atomique cross-env avec backend-prod, reloader absent)
- +2 deployments admin-v2 (DEV+PROD) si scope inclus avec ADMIN_BOOTSTRAP_PASSWORD_HASH (decision Ludovic).
- Divergences DEV/PROD documentees : INBOUND_WEBHOOK_KEY absent PROD backend-secrets (secret manuel separe), NEXTAUTH_URL absent PROD auth-secrets.
- Code usage confirme : JWT_SECRET (api 2 + backend 4 files), COOKIE_SECRET (api 3), KEYBUZZ_INTERNAL_TOKEN (backend Amazon Fees module), NEXTAUTH_SECRET (client middleware + debug-env), ADMIN_BOOTSTRAP_PASSWORD_HASH (admin-v2 auth lib).
- PROD baseline strictement intact : pods 21h-2d1h, 0 Warning events 2h, ES 10/10 True, K8s rv inchanges depuis fevrier-mars 2026.
- Design Q-1B-2B Mode B SAFE : 13 phases + 3 STOP gates Ludovic (avant mutation + avant restart manuel cross-env + avant commit/push), restart atomique cross-env mandatory.
- AI feature parity OK : LiteLLM 2 pods Running, images PROD inchangees, aucun manifest modifie.

Decouverte security P2 :
- keybuzz-client/app/api/debug-env/route.ts retourne sans auth nextAuthUrl complet + prefix 4 chars GOOGLE_CLIENT_ID/AZURE_AD_CLIENT_ID + booleens has* + filtre envKeys. Information disclosure pre-existant. Decision Ludovic requise avant Q-1B-2B : disable / proteger auth / accepter.

10 decisions Ludovic requises (cf section 17 du rapport).

Gaps :
- ADMIN_BOOTSTRAP_PASSWORD_HASH scope decision.
- Rollback strategy capability.
- Window operation choix.
- debug-env route disclosure decision.
- backfill-scheduler ImagePullBackOff hors scope (phase dediee).

NO GO Q-1B-2B EXEC tant que decisions Ludovic non prises + pre-requis Mode A (policy + token rotator) non realises.
NO GO Q-1B-3/4/5/6 (provider/infra/LLM/marketplace) maintenus.
NO GO PROD promotion AS.17.0/AS.17.0.1 maintenu.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

## 19. Conformite interdits

| Interdit Q-1B-2A | Respect |
|---|---|
| Rotation PROD | OK : aucune |
| Rotation DEV | OK : aucune |
| vault kv patch/put/write | OK : aucun |
| vault token create/revoke | OK : aucun |
| vault policy write/delete | OK : aucun |
| kubectl apply/patch/edit/set/annotate | OK : aucun |
| kubectl rollout restart/delete/create/exec | OK : aucun |
| base64 -d | OK : aucun |
| Token rotator/root temp | OK : aucun (rotator Q-1B-1B revoque, root temp Ludovic revoque) |
| Restart service/pod | OK : aucun |
| Build/Deploy | OK : aucun |
| Test provider | OK : aucun |
| Webhook mutationnel | OK : aucun |
| Appel paiement | OK : aucun |
| Event marketing | OK : aucun |
| Promotion PROD AS.17.0/AS.17.0.1 | OK : NO GO maintenu |
| Affichage valeur secret/token/JWT/cookie/bearer/base64/KV value | OK : tous redacts, valeurs jamais affichees |
| Affichage `.data` Secret Kubernetes | OK : seulement keys names via jq |
| Affichage hash admin complet | OK : seulement key name ADMIN_BOOTSTRAP_PASSWORD_HASH, hash value jamais lue |
| Affichage OAuth secret/provider key | OK : aucun |
| /opt/keybuzz/credentials/ non touche | OK |
| /opt/keybuzz/secrets/ non touche | OK |
| Bastion install-v3 only | OK |
| Read-only strict (sauf rapport docs-only) | OK |
| ASCII strict rapport | a verifier post-Write |
| STOP avant commit/push | OK (E15 STOP) |
| Aucun root token utilise par CE | OK |

STOP final : rapport pret, en attente GO Ludovic commit/push.

Aucun enchainement sur Q-1B-2B EXEC.
Aucun enchainement sur Q-1B-3/4/5/6 (provider/infra/LLM/marketplace).
Aucun enchainement sur PROD promotion AS.17.0/AS.17.0.1.
