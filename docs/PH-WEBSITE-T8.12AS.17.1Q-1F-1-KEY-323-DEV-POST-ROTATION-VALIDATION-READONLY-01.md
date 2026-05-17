# PH-WEBSITE-T8.12AS.17.1Q-1F-1-KEY-323-DEV-POST-ROTATION-VALIDATION-READONLY-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1F-1 DEV post-rotation validation read-only strict
> Environnement : DEV only + controles negatifs PROD
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO TECHNICAL VALIDATION OK - MANUAL UX PENDING.

Validation technique complete read-only effectuee 14h apres rotation Q-1B-1B :
- Vault HA Raft 3/3 unsealed stable (Raft 1138119 sync vs Q-1B-1B baseline 1129422 = +8697 activite normale ESO refresh hourly).
- 3 ExternalSecrets cibles Ready=SecretSynced avec refreshTime fresh 2026-05-17T11:02:07-09Z (last refresh ~25min avant Q-1F-1).
- 3 K8s Secrets cibles resourceVersion INCHANGEES depuis Q-1B-1B baseline (69633483, 69633502, 69633511) confirmant rotation stable sans rollback ni rotation supplementaire.
- 3 deployments DEV Ready 1/1, 0 restart 14h, pods identiques aux noms post-rotation Q-1B-1B (keybuzz-api-587774dbb6-rzzmq, keybuzz-backend-7b86b7ddb4-kx987, keybuzz-client-669589b8b6-n9m4b).
- 0 erreur Vault auth runtime dans logs backend (216 mentions "Vault" = logs informationnels, 0 co-occurrence Vault+403/401/unauthorized/forbidden).
- 2 JWT_SESSION_ERROR client = symptome ATTENDU rotation NEXTAUTH_SECRET (anciennes sessions invalidees, comportement documente Q-1B-1A).
- 0 Warning event Kubernetes sur 5 namespaces (api-dev, backend-dev, client-dev, external-secrets, vault-management).
- PROD strictement unchanged : pods 20h+ unchanged, ExternalSecrets 10/10 True, K8s Secrets PROD rv inchanges depuis fevrier-mars 2026.
- LiteLLM + workers + CronJobs DEV business-as-usual.
- Aucun build / deploy / mutation / provider call / secret displayed.

Manual UX validation Ludovic (login DEV testers, verify session OK, navigation simple) : PENDING.

Limitation : vault kv metadata get retourne 403 invalid token (rotator Q-1B-1B revoque post-cleanup B10, vault-admin-token policy keybuzz-vault-renewer n'a pas KV capability). Preuve indirecte via K8s Secret resourceVersion immuable depuis Q-1B-1B = rotation stable confirmee.

Phrase finale :
STOP AS.17.1Q-1F-1 - GO TECHNICAL VALIDATION OK - MANUAL UX PENDING. Rapport docs-only pret, en attente GO Ludovic commit/push. Q-1B-2 PROD reste NO GO tant que Ludovic n'a pas valide la decision gate.

## 2. Scope

### Scope read-only strict

Verifie sans mutation :
- Etat Vault HA Raft + KV metadata (limite par absence token KV).
- ExternalSecrets sync status + refresh time + syncedResourceVersion.
- K8s Secrets metadata + key names + ownerReferences (no values).
- Deployments + Pods DEV readiness + annotations restart.
- Logs DEV filtered avec grep patterns + redaction tokens.
- Kubernetes events warnings 5 namespaces.
- PROD pods + ExternalSecrets + K8s Secrets equivalents.
- AI feature parity / anti-regression.
- Conformite no fake metrics.

### Hors scope strict

Aucune action :
- aucune rotation PROD ni DEV supplementaire.
- aucun vault kv patch/put/write/token create/revoke/policy write.
- aucun kubectl apply/patch/edit/set/restart/delete/create.
- aucun build/deploy.
- aucun provider externe.
- aucun webhook mutationnel.
- aucun affichage secret/token/JWT/cookie/bearer/base64/KV value.
- aucun test client destructif.
- aucune promotion PROD AS.17.0/AS.17.0.1.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports KEY-323 chain

| Sequence | Commit | Rapport |
|---|---|---|
| AS.17.1Q-0 | e6e0f26 | secrets exposure inventory |
| AS.17.1Q-1A | b27e94a | Vault verification rotation design |
| AS.17.1Q-1A-bis | 1064c6e | Vault admin token replacement design |
| AS.17.1Q-1A-bis-exec | 346b17a | Vault admin token replacement execution Mode B SAFE |
| AS.17.1Q-1B-0 | 7846785 | KV secrets rotation plan |
| AS.17.1Q-1B-1A | 423ad49 | DEV internal low-risk dry-run |
| AS.17.1Q-1B-1B | fcc1170 | DEV internal low-risk execution Mode B SAFE |
| AS.17.1Q-1F-1 | en cours (ce rapport) | DEV post-rotation validation read-only |

Linear ticket : KEY-323. Dernier comment Codex Q-1B-1B : b446a40d-b0a1-4cca-86f1-edcceb59d7b6. Cleanup root temp Ludovic note : b76b1b4a-57ce-48dc-9d41-b0f6ed04b903.

## 4. Preflight

| Check | Attendu | Resultat | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 11:26 UTC / 13:26 CEST | OK |
| Git infra branch | main | main | OK |
| Git infra HEAD | fcc1170 | fcc1170012480dcd887d2353720470eca9a8fdbc | OK |
| Worktree | clean | clean | OK |
| Rapport Q-1B-1B | present | docs/PH-WEBSITE-T8.12AS.17.1Q-1B-1B-...md (20903 bytes May 17 06:19) | OK |
| Temp files Q-1B-1B | absent | 6/6 absent (rotator+root temp+before.json+3 runners) | OK |

## 5. Vault HA / KV metadata

### Vault HA Raft nodes

| Vault node | IP | Sealed | Mode | Raft index | Verdict |
|---|---|---|---|---|---|
| vault-01 | 10.0.0.150:8200 | false | standby | 1138119 | OK |
| vault-02 | 10.0.0.154:8200 | false | standby | 1138119 | OK |
| vault-03 | 10.0.0.155:8200 | false | active | 1138119 | OK leader |

Delta Raft index : 1138119 - 1129422 (Q-1B-1B B9 baseline) = +8697 sur 14h = activite normale ESO refresh + vault-token-renew schedule.

### KV metadata versions (limitation observee)

Tentative vault kv metadata get sur les 4 paths cibles retourne HTTP 403 invalid token.

Cause : aucun token avec KV capability disponible cote CE.
- rotator Q-1B-1B revoque/expire naturel post-cleanup B10.
- root temp Shamir revoque par Ludovic (cleanup confirme).
- vault-admin-token (non-root, policy keybuzz-vault-renewer) limite a auth/token/* (lookup-self, renew, create) - aucune capability KV.

| KV path | Current version | Methode | Verdict |
|---|---|---|---|
| secret/keybuzz/dev/jwt | non-mesurable directement | preuve indirecte K8s rv | OK indirect (rv 69633483 inchange) |
| secret/keybuzz/dev/backend-jwt | non-mesurable directement | preuve indirecte K8s rv | OK indirect (rv 69633502 inchange) |
| secret/keybuzz/dev/inbound-webhook | non-mesurable directement | preuve indirecte K8s rv | OK indirect (rv 69633502 inchange - meme target) |
| secret/keybuzz/auth | non-mesurable directement | preuve indirecte K8s rv | OK indirect (rv 69633511 inchange) |

Preuve indirecte solide : si la version Vault avait roll-back ou ete re-patched, ESO refresh hourly aurait detecte une diff content et bumpe le K8s Secret rv. Le rv etant strictement identique a la baseline Q-1B-1B B6.3 (post-rotation), la rotation est stable.

## 6. ExternalSecrets / K8s Secret metadata

### ExternalSecrets cluster-wide

30/30 ExternalSecrets Ready=True (matche baseline Q-1B-1B).

### 3 ExternalSecrets cibles

| Namespace | ExternalSecret | Ready | Reason | refreshTime | syncedResourceVersion |
|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api-jwt | True | SecretSynced | 2026-05-17T11:02:07Z | 1-3989115182218d01a40350719561571962ec69da8530e66bfe5c71a7 |
| keybuzz-backend-dev | keybuzz-backend-secrets | True | SecretSynced | 2026-05-17T11:02:08Z | 1-ae1e55ca73d8011062a323bc078c6fe416fac971e2a37c8d87ce2238 |
| keybuzz-client-dev | keybuzz-auth-secrets | True | SecretSynced | 2026-05-17T11:02:09Z | 1-871083aafc01415157764893eb8a904a3b7025e86d91cc151fa25ed5 |

refreshTime fresh : last ESO sync ~25min avant Q-1F-1, confirmant que ESO continue de polling Vault avec succes. Si Vault avait perdu/corrompu les KV cibles, ce sync aurait echoue et Ready serait False.

### 3 K8s Secrets cibles (metadata + key names only, no values)

| Namespace | Secret | Type | Created | rv current | Keys | Owner |
|---|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api-jwt | Opaque | 2026-02-06T16:21:04Z | 69633483 | COOKIE_SECRET, JWT_SECRET (2) | ExternalSecret/keybuzz-api-jwt |
| keybuzz-backend-dev | keybuzz-backend-secrets | Opaque | 2026-03-12T17:58:39Z | 69633502 | INBOUND_WEBHOOK_KEY, JWT_SECRET, KEYBUZZ_INTERNAL_TOKEN, MINIO_ACCESS_KEY, MINIO_BUCKET_ATTACHMENTS, MINIO_ENDPOINT, MINIO_SECRET_KEY, PRODUCT_DATABASE_URL (8) | ExternalSecret/keybuzz-backend-secrets |
| keybuzz-client-dev | keybuzz-auth | Opaque | 2026-01-07T13:37:35Z | 69633511 | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET, NEXTAUTH_URL (7) | ExternalSecret/keybuzz-auth-secrets |

| Verdict |
|---|
| rv identique a Q-1B-1B B6.3 baseline (69633483/69633502/69633511) - aucune mutation depuis 14h |
| Keys count preserve (2, 8, 7) - 0 key dropped |
| ownerReferences ExternalSecret maintenu - ESO gere toujours ces secrets |
| Aucune valeur lue ni affichee |

## 7. Workloads DEV readiness

### Deployments

| Namespace | Deployment | Image | Ready | restartedAt | reloader | vaultRenewRestart | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev | 1/1 | 2026-05-05T07:30:07Z (old) | true | 2026-05-16T14:32:16Z (R1) | OK |
| keybuzz-backend-dev | keybuzz-backend | ghcr.io/keybuzzio/keybuzz-backend:v1.0.47-cross-env-guard-fix-dev | 1/1 | 2026-05-16T21:36:54Z (Q-1B-1B B7 manual) | - (absent) | 2026-05-16T14:32:17Z (R1) | OK restart manuel confirme |
| keybuzz-client-dev | keybuzz-client | ghcr.io/keybuzzio/keybuzz-client:v3.5.197-channels-bff-userauth-dev | 1/1 | 2026-05-01T16:38:33Z (old) | true | - | OK |

Notes :
- keybuzz-backend restartedAt 2026-05-16T21:36:54Z confirme l'execution B7 Q-1B-1B (kubectl rollout restart trigge l'annotation).
- keybuzz-api + keybuzz-client n'ont pas leur restartedAt mis a jour par Q-1B-1B B6 reloader (reloader force restart via image hash bump differemment).
- reloader.stakater.com/auto present sur api+client (confirme decouverte B0 Q-1B-1B).
- reloader absent sur backend (confirme decouverte B0 Q-1B-1B - manual restart requis pour ce service).

### Pods

| Namespace | Deployment | Pod | Status | Ready | Age | Restarts | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api | keybuzz-api-587774dbb6-rzzmq | Running | 1/1 | 14h | 0 | OK identique post-Q-1B-1B B6 |
| keybuzz-backend-dev | keybuzz-backend | keybuzz-backend-7b86b7ddb4-kx987 | Running | 1/1 | 13h | 0 | OK identique post-Q-1B-1B B7 |
| keybuzz-client-dev | keybuzz-client | keybuzz-client-669589b8b6-n9m4b | Running | 1/1 | 14h | 0 | OK identique post-Q-1B-1B B6 |

3/3 pods identiques aux noms observes apres Q-1B-1B B6/B7, 0 restart en 14h, 0 crashloop.

## 8. Logs DEV filtered

### keybuzz-api-dev/keybuzz-api-587774dbb6-rzzmq (24011 lines, 14h window)

| Pattern | Count | Note |
|---|---|---|
| 403 | 254 | majoritairement request completed statusCode=200 + health probes (logs JSON niveau 30) |
| 401 | 232 | idem |
| error | 98 | dont [Billing Webhook] foreign key constraint billing_subscriptions/customers - bug data pre-existant non-lie a Q-1B-1B |
| exception | 14 | non-bloquant |

Sample errors notables (filtered, no token leak) :
- "[OCTOPIA-SYNC] Completed: tenants=0 imported=0 skipped=0 errors=0" : sync Octopia OK
- "[Billing Webhook] Error processing event: insert or update on table billing_subscriptions violates foreign key constraint fk_billing_sub_customer" : bug data pre-existant (Stripe envoie customer.subscription.updated pour customer non present localement), HORS scope rotation
- aucune erreur JWT / Vault auth specifique

### keybuzz-backend-dev/keybuzz-backend-7b86b7ddb4-kx987 (41424 lines, 14h window)

| Pattern | Count | Note |
|---|---|---|
| Vault | 216 | logs informationnels ("Vault initialized", lifecycle) - 0 co-occurrence avec 403/401/unauthorized/forbidden/invalid/denied/error (verifie targeted grep) |
| 403 | 415 | majoritairement Amazon SP-API errors ([Orders Sync] Failed: Error: SP-API error 403) - pre-existant, hors scope |
| 401 | 154 | majoritairement SP-API |
| unauthorized | 283 | majoritairement {"code": "Unauthorized"} dans response JSON SP-API + NODE_TLS_REJECT_UNAUTHORIZED warning startup |
| error | 2772 | majoritairement SP-API errors + DeprecationWarning punycode + business workflow errors normales |

Error ratio 2804/41424 = 6.76% = compatible baseline pre-Q-1B-1B (workload Amazon SP-API genere du bruit constant). Non-attribuable a rotation.

Verdict : 0 erreur Vault auth confirmee.

### keybuzz-client-dev/keybuzz-client-669589b8b6-n9m4b (33 lines, 14h window)

| Pattern | Count | Note |
|---|---|---|
| JWT | 4 | inclus dans JWT_SESSION_ERROR |
| error | 4 | idem |
| JWT_SESSION_ERROR | 2 | NEXTAUTH "decryption operation failed" : SYMPTOME ATTENDU rotation NEXTAUTH_SECRET (anciennes sessions client tete encrypte avec ancien secret = decryption fail apres rotation) |

Verdict : comportement attendu et documente en Q-1B-1A. Pas une regression. Les testers DEV doivent se reconnecter.

## 9. Kubernetes events

| Namespace | Window | Warning count | Verdict |
|---|---|---|---|
| keybuzz-api-dev | 2h | 0 | OK |
| keybuzz-backend-dev | 2h | 0 | OK |
| keybuzz-client-dev | 2h | 0 | OK |
| external-secrets | 2h | 0 | OK |
| vault-management | 2h | 0 | OK |

5/5 namespaces zero Warning event. Pas de crashloop, ImagePullBackOff (sauf backfill-scheduler pre-existant hors scope), ES sync error, ou anomalie auth.

## 10. PROD negative control

### Pods PROD

| Namespace | Pod | Status | Age | Restarts | Verdict |
|---|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api-7d5fd7d697-kf9dz | Running | 20h | 0 | OK unchanged (post-R1 baseline) |
| keybuzz-api-prod | keybuzz-outbound-worker-7bfb4944c4-tnsl6 | Running | 20h | 0 | OK unchanged |
| keybuzz-backend-prod | keybuzz-backend-56b9bc977d-v6jrw | Running | 20h | 0 | OK unchanged |
| keybuzz-client-prod | keybuzz-client-68556c9dbf-5zmjk | Running | 2d | 0 | OK unchanged (pas touche par R1 vault-token-renew) |

### ExternalSecrets PROD

| Namespace | ExternalSecret | Ready |
|---|---|---|
| keybuzz-api-prod | keybuzz-api-jwt | True |
| keybuzz-api-prod | keybuzz-api-postgres | True |
| keybuzz-api-prod | minio-credentials | True |
| keybuzz-api-prod | octopia-credentials | True |
| keybuzz-api-prod | redis-credentials | True |
| keybuzz-backend-prod | keybuzz-backend-db | True |
| keybuzz-backend-prod | keybuzz-backend-secrets | True |
| keybuzz-client-prod | keybuzz-auth-secrets | True |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-bootstrap | True |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | True |

10/10 PROD ExternalSecrets True.

### K8s Secrets PROD equivalents (rv unchanged)

| Namespace | Secret | rv current | Created | Verdict |
|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api-jwt | 31857841 | 2026-02-06T16:21:05Z | OK rv inchange depuis fevrier 2026 |
| keybuzz-backend-prod | keybuzz-backend-secrets | 36935360 | 2026-03-12T17:58:40Z | OK rv inchange depuis mars 2026 |
| keybuzz-client-prod | keybuzz-auth-secrets | 40891619 | 2026-01-20T13:22:36Z | OK rv inchange depuis janvier 2026 |

PROD strictement intact. Aucune mutation cross-env. Control negatif PASS.

## 11. Manual Ludovic validation status

MANUAL VALIDATION PENDING.

Items en attente confirmation Ludovic (UX/integration manuelle, hors scope CE) :
- ouvrir Client DEV (https://client-dev.keybuzz.io ou equivalent).
- constater que sessions anciennes peuvent etre invalidees (JWT_SESSION_ERROR observe = comportement attendu rotation NEXTAUTH_SECRET).
- se reconnecter avec compte testeur DEV (Google OAuth ou Azure AD selon config DEV).
- verifier navigation simple (dashboard, channels, autopilot read-only).
- verifier API DEV repond sans boucle 401 (verifier directement avec curl/browser fetch).
- verifier action simple non-destructive (lecture liste tenants, etc.).
- NE PAS tester paiement Stripe ni provider externe.
- NE PAS envoyer webhook externe mutationnel.

Si Ludovic confirme : verdict peut etre upgrade a `GO DEV POST-ROTATION VALIDATION OK`.

Si Ludovic identifie blocker UX : verdict downgrade a `GO PARTIAL WITH BLOCKERS` ou `NO GO DEV POST-ROTATION VALIDATION`.

CE ne fabrique pas cette validation. Aucun test automatise execute.

## 12. AI feature parity / anti-regression

| Surface | Check read-only | Resultat | Verdict |
|---|---|---|---|
| IA / autopilot (LiteLLM) | pods Running | litellm-55bcfd7769-sfw8l Running 1/1 41d + litellm-55bcfd7769-xlhm7 Running 1/1 2d | OK |
| Images runtime DEV | tag inchange depuis Q-1B-1B | v3.5.190 api, v1.0.47 backend, v3.5.197 client (identique a Q-1B-1B B0 baseline) | OK pas de build/deploy entre Q-1B-1B et Q-1F-1 |
| Endpoint/feature IA | aucun changement | aucun manifest IA/Inbox/connecteur modifie, repos applicatifs non touches | OK |
| Inbox / messages | no new error burst logs | mentions Inbox=10 dans backend logs 14h, no error burst specifique | OK |
| Connecteurs | no new error burst logs | mentions connector=1 api, channel=8 api, marketplace=13 api + 4776 backend (workload Amazon normal), shopify=3, octopia=260 | OK business-as-usual |
| Commandes/tracking colis | no new error burst logs | tracking=637 api (workload normal) | OK |
| AI providers (OpenAI/Anthropic) | hors scope Q-1B-1, non touche | aucun appel CE | OK |

Aucun test mutationnel IA execute. Aucun message client. Aucun workflow declenche. Aucun email envoye. Aucun webhook externe.

## 13. No fake metrics / no fake events

| Metrique / event | Source | Fenetre | Mutation | Verdict |
|---|---|---|---|---|
| K8s Secret rv (3 cibles) | kubectl get secret jsonpath rv | snapshot Q-1F-1 | non | reel |
| ExternalSecret refreshTime | kubectl get externalsecret jsonpath status | snapshot Q-1F-1 | non | reel |
| Vault Raft index | vault status 3 nodes | snapshot Q-1F-1 | non | reel |
| Log pattern counts | kubectl logs --since=14h + grep -c | 14h window | non (logs lecture) | reel |
| Pod ages | kubectl get pods | snapshot Q-1F-1 | non | reel |
| Events Warning count | kubectl get events --field-selector | 2h window | non | reel |
| Error ratio backend 6.76% | calcul ratio sur logs lus | 14h | non | reel |

Aucun fake event/metric. Aucun signup_complete, purchase, CAPI/GA4, paiement test, marketing mutation, dashboard pollution.

## 14. Incidents / anomalies

### Anomalie 1 : vault kv metadata get bloque par 403 invalid token

| Champ | Detail |
|---|---|
| Severite | P2 |
| Type | limitation outillage post-cleanup |
| Cause | rotator Q-1B-1B revoque + root temp Shamir revoque + vault-admin-token sans capability KV |
| Impact | impossibilite preuve directe Vault KV version >= 2 |
| Mitigation | preuve indirecte K8s Secret rv unchanged + ExternalSecret refreshTime fresh + SecretSynced=True 14h post-rotation |
| Decision | accepte (verifier directement Vault metadata necessiterait creation token ad-hoc, hors scope Q-1F-1 read-only) |

### Anomalie 2 : 2 JWT_SESSION_ERROR client

| Champ | Detail |
|---|---|
| Severite | P3 (attendu) |
| Type | comportement documente |
| Cause | rotation NEXTAUTH_SECRET invalide les anciens cookies session encryptes avec ancien secret |
| Impact | testers DEV doivent se reconnecter (logout silencieux) |
| Mitigation | re-login normal apres rotation, attendu et documente Q-1B-1A |
| Decision | accepte (low-impact DEV, zero client reel actuel) |

### Anomalie 3 : Billing webhook foreign key constraint

| Champ | Detail |
|---|---|
| Severite | P2 pre-existant |
| Type | bug data hors scope rotation |
| Cause | Stripe envoie customer.subscription.updated pour customer.id non present dans table customers locale (probable race ou test data) |
| Impact | webhook event non-traite, log error |
| Lien Q-1B-1B | aucun (bug pre-existant) |
| Decision | hors scope, a documenter dans ticket Stripe/billing separe |

### Anomalie 4 : SP-API error 403 backend (Amazon)

| Champ | Detail |
|---|---|
| Severite | P2 pre-existant |
| Type | Amazon SP-API auth/quota errors |
| Cause | tokens Amazon SP-API expires/limites, hors scope KV rotation Q-1B-1B (defer Q-1B-6 marketplace OAuth) |
| Impact | sync Amazon orders periodically fails |
| Decision | hors scope, defer Q-1B-6 |

### Anomalie 5 : backfill-scheduler ImagePullBackOff (rappel)

| Champ | Detail |
|---|---|
| Severite | P1 pre-existant 48h+ |
| Type | image inexistante ou registry permissions |
| Lien Q-1B-1B | aucun |
| Decision | hors scope, phase dediee post-Q-1B-x |

## 15. Risk register

| Risk | Severity | Status | Mitigation |
|---|---|---|---|
| Manual UX validation Ludovic non confirmee | P1 | PENDING | attendre Ludovic test login DEV avant Q-1B-2 GO |
| vault kv metadata get bloque (token rotator deja revoque) | P2 | observe | preuve indirecte K8s rv suffisante pour validation Q-1F-1 ; future phase necessitant Vault KV read directe devra creer token ad-hoc |
| Sessions DEV anciennes invalidees | P3 attendu | observe | testers re-login normal |
| Bug Billing webhook foreign key | P2 pre-existant | observe | ticket separe Stripe/billing, hors KEY-323 |
| Amazon SP-API 403 errors backend | P2 pre-existant | observe | defer Q-1B-6 marketplace OAuth rotation |
| backfill-scheduler ImagePullBackOff | P1 pre-existant | observe | phase dediee |
| keybuzz-backend reloader annotation manquante | P2 known | observe | a corriger en parallele Q-1B-x ou phase infra dediee (eviter restart manuel futur) |
| keybuzz/internal-tokens cross-env DEV+PROD non rotate | P1 | observe | defer Q-1B-2 (atomique synchronise) |
| Q-1B-2 PROD internal low-risk | P0 NO GO | bloque | requiere manual UX validation Q-1F-1 + GO Ludovic separe |
| Q-1B-3/4/5/6 (provider/infra/LLM/marketplace) | P0 NO GO | bloque | phases dediees post-Q-1B-2 stabilite confirmee |
| PROD promotion AS.17.0 / AS.17.0.1 | P0 NO GO | maintenu | bloque jusqu'a Q-1B-x cycle complet + decision Ludovic |

## 16. Decision gate for Q-1B-2

Conditions remplies pour Q-1B-2 GO :
- Q-1B-1B rotation effective et stable (CONFIRMED).
- ExternalSecrets 30/30 True (CONFIRMED).
- K8s Secrets rv stables vs baseline (CONFIRMED).
- Apps DEV Running 1/1 sans crashloop (CONFIRMED).
- 0 erreur Vault auth runtime (CONFIRMED).
- PROD unchanged (CONFIRMED).
- AI feature parity OK (CONFIRMED).
- Manual UX validation Ludovic (PENDING).

Recommandation : attendre Manual UX validation Ludovic explicite avant Q-1B-2 GO. Le Q-1B-2 (PROD internal low-risk : keybuzz/prod/jwt + keybuzz/prod/backend-jwt + keybuzz/prod/auth NEXTAUTH_SECRET + keybuzz/internal-tokens cross-env) implique restart pods PROD, donc UX validation DEV doit etre confirmee pour reduire le risque PROD.

Decision gate Q-1B-2 : NO GO immediate, attente Manual UX validation Ludovic.

## 17. Rollback / recovery notes (read-only, no command destructive)

### Si UX validation Ludovic detecte regression bloquante

Procedure rollback Q-1B-1B (documentee design Q-1B-1A) :

1. Ludovic genere root temp Shamir + creates policy keybuzz-kv-rotator-q1b1-rollback-temp (similaire keybuzz-kv-rotator-q1b1-temp).
2. CE Mode B SAFE rollback runner :
   - vault kv rollback -version=1 secret/keybuzz/dev/jwt
   - vault kv rollback -version=1 secret/keybuzz/dev/backend-jwt
   - vault kv rollback -version=1 secret/keybuzz/dev/inbound-webhook
   - vault kv rollback -version=1 secret/keybuzz/auth (property-only nextauth_secret v1)
3. kubectl annotate externalsecret force-sync sur 3 ES DEV.
4. Wait ESO refresh + verify K8s Secret rv re-bumped.
5. Restart 3 deployments (keybuzz-api auto reloader, keybuzz-backend manuel, keybuzz-client auto reloader).

KV v2 conserve 10 versions retention par defaut, donc v1 accessible.

Risque rollback : reintroduit les anciennes valeurs (potentiellement exposees pre-incident Hetzner). Trade-off securite vs UX continuity a decider Ludovic.

### Si UX validation Ludovic OK

Pas de rollback necessaire. Verdict upgrade a `GO DEV POST-ROTATION VALIDATION OK` et Q-1B-2 peut etre prepare.

### Pas de commande destructive executee par CE

CE n'a execute aucune commande destructive. Toutes les commandes Q-1F-1 sont strictement read-only ou metadata-only.

## 18. Linear draft comment (a poster par Codex apres commit)

```
AS.17.1Q-1F-1 DEV post-rotation validation read-only COMPLETE

Commit rapport Q-1B-1B : fcc1170
Commit rapport Q-1F-1 : <CE remplira apres push>
Verdict : GO TECHNICAL VALIDATION OK - MANUAL UX PENDING.

Resume technique :
- Vault HA Raft 3/3 unsealed stable, Raft 1138119 (+8697 sur 14h, activite normale).
- 3 ExternalSecrets cibles Ready=SecretSynced, refreshTime fresh 2026-05-17T11:02:07-09Z (last ESO refresh 25min pre-Q-1F-1).
- 3 K8s Secrets cibles rv INCHANGEES depuis Q-1B-1B baseline (69633483/69633502/69633511) = rotation stable 14h sans rollback ni rotation supplementaire.
- 3 deployments DEV Ready 1/1, 0 restart 14h, pods identiques post-Q-1B-1B (api 14h auto reloader, backend 13h B7 manual @ 21:36:54Z, client 14h auto reloader).
- 0 erreur Vault auth runtime backend (216 mentions "Vault" = logs informationnels, 0 co-occurrence avec 403/401/unauthorized/forbidden).
- 2 JWT_SESSION_ERROR client = symptome ATTENDU rotation NEXTAUTH_SECRET (sessions anciennes invalidees, documente Q-1B-1A).
- 0 Warning event Kubernetes sur 5 namespaces.
- PROD strictement unchanged : 4 pods PROD 20h-2d unchanged, 10/10 ES PROD True, 3 K8s Secrets PROD rv inchanges depuis fevrier-mars 2026.
- AI feature parity OK : LiteLLM Running 1/1, images DEV inchangees depuis Q-1B-1B, Inbox/connector/marketplace/tracking business-as-usual.
- Conformite : aucun secret/token/accessor complet/JWT/cookie/base64/KV value affiche, no fake metrics, runner SCP atomique respecte.

Limitation observee :
- vault kv metadata get blocked HTTP 403 invalid token (rotator Q-1B-1B revoque post-cleanup, vault-admin-token sans KV capability). Preuve indirecte K8s rv unchanged + ESO refresh fresh confirme rotation stable.

Anomalies pre-existantes (hors scope rotation) :
- Billing webhook fk_billing_sub_customer (bug data Stripe).
- Amazon SP-API 403 backend (defer Q-1B-6 marketplace OAuth).
- backfill-scheduler ImagePullBackOff dev+prod (phase dediee).

Decisions Ludovic en attente :
1. Manual UX validation DEV : login Client DEV + navigation simple + verify API repond sans boucle 401.
2. GO Q-1B-2 PROD internal low-risk (jwt+backend-jwt+auth+internal-tokens cross-env) : NO GO maintenu jusqu'a UX validation OK.
3. Optional : creer reloader.stakater.com/auto=true sur keybuzz-backend-dev deployment pour eviter restart manuel future.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

## 19. Conformite interdits

| Interdit Q-1F-1 | Respect |
|---|---|
| vault kv get | OK : tentative metadata get bloquee 403, aucun get valeur |
| vault kv patch | OK : aucun |
| vault kv put | OK : aucun |
| vault write | OK : aucun |
| vault token create | OK : aucun |
| vault token revoke | OK : aucun |
| vault policy write | OK : aucun |
| vault policy delete | OK : aucun |
| kubectl apply | OK : aucun |
| kubectl patch | OK : aucun |
| kubectl edit | OK : aucun |
| kubectl set | OK : aucun |
| kubectl delete | OK : aucun |
| kubectl create | OK : aucun |
| kubectl rollout restart | OK : aucun (B7 Q-1B-1B etait phase precedente) |
| kubectl exec | OK : aucun |
| base64 -d | OK : aucun |
| Restart service/pod | OK : aucun |
| Build | OK : aucun |
| Deploy | OK : aucun |
| Provider externe call | OK : aucun (Google/Azure/Stripe/OpenAI/Anthropic/Amazon/Shopify/Octopia/SES/17track/Slack) |
| Webhook mutationnel | OK : aucun |
| Affichage secret/token/JWT/cookie/bearer/base64/KV value | OK : tous redacts, valeurs jamais dans stdout |
| Test client destructif | OK : aucun |
| PROD promotion AS.17.0 / AS.17.0.1 | OK : NO GO maintenu |
| Bastion install-v3 only | OK |
| /opt/keybuzz/credentials/ non touche | OK |
| /opt/keybuzz/secrets/ non touche | OK |
| Read-only strict (sauf rapport docs-only) | OK |
| Aucun root temp Shamir lu/utilise par CE | OK |
| Aucune mutation policy par CE | OK |
| ASCII strict rapport | a verifier post-Write |
| STOP avant commit/push | OK (E12 STOP) |

STOP final : rapport pret, en attente GO Ludovic commit/push + manual UX validation.
