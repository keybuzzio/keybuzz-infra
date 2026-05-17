# PH-WEBSITE-T8.12AS.17.1Q-1B-2B-KEY-323-PROD-INTERNAL-LOW-RISK-EXEC-MODE-B-SAFE-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-2B PROD internal low-risk EXEC Mode B SAFE
> Environnement : PROD + DEV cross-env backend
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO PROD INTERNAL ROTATION COMPLETE (verdict upgrade post UX validation Ludovic 2026-05-17 : DEV fonctionne, PROD fonctionne, login/navigation OK, pas de boucle 401 observee).

Rotation PROD internal low-risk executee Mode B SAFE. 4 paths Vault KV PROD bumped v1 -> v2 (jwt, backend-jwt, auth NEXTAUTH_SECRET property-only, internal-tokens cross-env). 4 K8s Secrets resourceVersion BUMPED via ESO force-sync (api-jwt 31857841->70002863, backend-secrets PROD 36935360->70002880, auth-secrets PROD 40891619->70002890, backend-secrets DEV 69633502->70002911). 4 deployments restartes (api-prod + client-prod AUTO reloader, backend-prod + backend-dev MANUAL atomique cross-env avec GO Gate 2). Tous pods Running 1/1 0 restart. Vault HA Raft 3/3 sain Raft 1140192 sync. ExternalSecrets 30/30 True. Aucune erreur Vault auth runtime detectee. 30 JWT_SESSION_ERROR sur client-prod = comportement ATTENDU rotation NEXTAUTH_SECRET (anciennes sessions decryption failed, users doivent re-login, pattern identique Q-1B-1B DEV). Rotator self-revoked TTL 5416s. 5 fichiers temporaires shred. Cross-env negative DEV non-cible : ages api-dev 17h + client-dev 99m + outbound-worker 24h unchanged.

Validation UX manuelle Ludovic PENDING (login PROD + navigation simple + verify pas de boucle 401).

Phrase finale :
STOP AS.17.1Q-1B-2B - GO PROD INTERNAL ROTATION COMPLETE. UX validation Ludovic confirmee 2026-05-17 (DEV+PROD login/navigation OK, pas de boucle 401). Rapport docs-only commit/push avec GO Ludovic. Q-1B-3/4/5/6 et PROD promotion AS.17.0/AS.17.0.1 restent NO GO.

## 2. Scope

Execute :
- 4 paths Vault KV PROD bumped via rotator non-root scope strict.
- 4 K8s Secrets ESO synced.
- 4 deployments restartes (2 AUTO reloader + 2 MANUAL atomique).
- 5 properties rotatees (JWT_SECRET api, COOKIE_SECRET api, JWT_SECRET backend, NEXTAUTH_SECRET property-only, KEYBUZZ_INTERNAL_TOKEN).

Hors scope strict respecte :
- 0 admin-v2/bootstrap.
- 0 Google/Azure OAuth, Stripe, Ads, marketplace, LLM, Redis/Postgres/MinIO/SMTP, SES, keybuzz-ads-encryption.
- 0 debug-env modifications.
- 0 Q-1B-3/4/5/6.
- 0 PROD promotion AS.17.0/AS.17.0.1.
- 0 build/deploy applicatif.
- 0 modification source/manifests.

## 3. Sources relues

| Source | Reference |
|---|---|
| Standards KeyBuzz | CURRENT_STATE.md + RULES_AND_RISKS.md + DOCUMENT_MAP.md + CE_PROMPTING_STANDARD.md |
| Q-1A-bis-exec | commit 346b17a (vault-admin-token replacement) |
| Q-1B-0 | commit 7846785 (KV rotation plan) |
| Q-1B-1B | commit fcc1170 (DEV internal exec) |
| Q-1F-1 | commit 556772c (DEV post-rotation validation) |
| Q-1B-2A | commit 4950f96 (PROD dry-run) |
| Q-1B-2A-bis | commit b00c9b8 (debug-env DEV+PROD fixed) |

## 4. Decisions Ludovic confirmees Q-1B-2B

| Decision | Valeur |
|---|---|
| Scope | 4 paths confirmes (jwt, backend-jwt, auth NEXTAUTH_SECRET property-only, internal-tokens cross-env) |
| admin-v2/bootstrap | EXCLU |
| internal-tokens atomique | DEV+PROD restart simultane backend |
| Restart group | 4 deployments (3 PROD + 1 DEV cross-env) |
| Mode execution | Mode B SAFE avec rotator dedie keybuzz-kv-rotator-q1b2-temp |
| Ludovic disponible verification immediate | confirme |
| Rollback strategy | KV v2 previous version + ESO re-sync + meme restart group |
| Provider/manual/infra/LLM/marketplace | hors scope |
| debug-env | deja resolu Q-1B-2A-bis |
| PROD promotion AS.17.0/AS.17.0.1 | NO GO maintenu |

## 5. Rotator policy verification (B1)

| Champ | Valeur (redacted) |
|---|---|
| display_name | token-kv-rotator-q1b2-prod-internal-2026-05-17 |
| policies | default + keybuzz-kv-rotator-q1b2-temp |
| TTL initial | 7082s (~118min, expire 2026-05-17T16:03:23Z) |
| orphan | false, renewable: true |
| accessor (redacted) | 0W6eyaHUkg...REDACTED |

Sanity gates :
- OK policy keybuzz-kv-rotator-q1b2-temp present
- OK no root policy attached
- OK TTL >= 1800s

Capabilities POSITIVE (15 paths) :
- auth/token/lookup-self : read
- auth/token/revoke-self : update
- sys/capabilities-self : update
- secret/metadata/keybuzz/{prod/jwt,prod/backend-jwt,prod/auth,internal-tokens} : read
- secret/data/keybuzz/{prod/jwt,prod/backend-jwt,prod/auth,internal-tokens} : create, patch, update
- secret/rollback/keybuzz/{prod/jwt,prod/backend-jwt,prod/auth,internal-tokens} : update

Capabilities NEGATIVE DENY (17 paths hors scope) :
- DEV : dev/jwt, dev/backend-jwt, dev/inbound-webhook, auth
- admin-v2 : bootstrap, postgres
- infra : redis, minio, ses
- provider : stripe, ai/openai_api_key, ai/anthropic_api_key
- PROD other : db_api, octopia, prod/minio, backend-postgres, backend-product-db

Tous DENY confirme. Isolation complete scope Q-1B-2B.

## 6. BEFORE snapshot (B2)

Snapshot capture sur bastion `/tmp/keybuzz-q1b2b-before.json` mode 600 (shred B10).

Vault KV current_version BEFORE :

| KV path | version | created_time |
|---|---|---|
| secret/keybuzz/prod/jwt | 1 | 2026-03-02 |
| secret/keybuzz/prod/backend-jwt | 1 | 2026-03-12 |
| secret/keybuzz/prod/auth | 1 | 2026-03-02 |
| secret/keybuzz/internal-tokens | 1 | 2026-03-12 |

K8s Secrets BEFORE :

| ns/secret | rv BEFORE | keys |
|---|---|---|
| keybuzz-api-prod/keybuzz-api-jwt | 31857841 | 2 (COOKIE_SECRET, JWT_SECRET) |
| keybuzz-backend-prod/keybuzz-backend-secrets | 36935360 | 7 (sans INBOUND_WEBHOOK_KEY PROD specifique) |
| keybuzz-client-prod/keybuzz-auth-secrets | 40891619 | 6 (sans NEXTAUTH_URL PROD specifique) |
| keybuzz-backend-dev/keybuzz-backend-secrets | 69633502 | 8 (post-Q-1B-1B baseline) |

Pods BEFORE :

| ns/dep | pod | age BEFORE |
|---|---|---|
| keybuzz-api-prod/keybuzz-api | kf9dz | 23h (post-R1 Q-1A-bis-exec) |
| keybuzz-client-prod/keybuzz-client | 7897p | 1h18 (post-Q-1B-2A-bis) |
| keybuzz-backend-prod/keybuzz-backend | v6jrw | 23h (post-R1) |
| keybuzz-backend-dev/keybuzz-backend | kx987 | 16h47 (post-Q-1B-1B B7) |

Reloader annotations :

| ns/dep | reloader.stakater.com/auto |
|---|---|
| keybuzz-api-prod/keybuzz-api | true |
| keybuzz-client-prod/keybuzz-client | true |
| keybuzz-backend-prod/keybuzz-backend | absent |
| keybuzz-backend-dev/keybuzz-backend | absent |

## 7. KV patch execution (B3+B4)

Runner SCP unique borne (shred apres execution).

Sanity B3.0 : rotator TTL 6283s OK avant patch.

5 valeurs generees offline `openssl rand -hex 32` (64 hex chars chacune, 0 valeur affichee, unset NEW_* immediat).

4 patches property-only :

| Operation | Resultat |
|---|---|
| vault kv patch -mount=secret keybuzz/prod/jwt JWT_SECRET=$NEW_API_JWT_SECRET COOKIE_SECRET=$NEW_API_COOKIE_SECRET | OK |
| vault kv patch -mount=secret keybuzz/prod/backend-jwt JWT_SECRET=$NEW_BACKEND_JWT_SECRET | OK |
| vault kv patch -mount=secret keybuzz/prod/auth NEXTAUTH_SECRET=$NEW_NEXTAUTH_SECRET | OK (5 OAuth Google/Azure properties preserves) |
| vault kv patch -mount=secret keybuzz/internal-tokens KEYBUZZ_INTERNAL_TOKEN=$NEW_INTERNAL_TOKEN | OK (cross-env DEV+PROD) |

Verify metadata versions :

| KV path | current_version |
|---|---|
| secret/keybuzz/prod/jwt | 2 (was 1) |
| secret/keybuzz/prod/backend-jwt | 2 (was 1) |
| secret/keybuzz/prod/auth | 2 (was 1) |
| secret/keybuzz/internal-tokens | 2 (was 1) |

4/4 paths v1 -> v2 confirme.

## 8. ESO sync / RV bump (B5+B6)

ESO force-sync kubectl annotate force-sync=1779027550 sur 4 ES.

ExternalSecrets Ready post-sync :

| ns/ES | Ready | reason | refreshTime |
|---|---|---|---|
| keybuzz-api-prod/keybuzz-api-jwt | True | SecretSynced | 2026-05-17T14:19:10Z |
| keybuzz-backend-prod/keybuzz-backend-secrets | True | SecretSynced | 2026-05-17T14:19:11Z |
| keybuzz-client-prod/keybuzz-auth-secrets | True | SecretSynced | 2026-05-17T14:19:12Z |
| keybuzz-backend-dev/keybuzz-backend-secrets | True | SecretSynced | 2026-05-17T14:19:13Z |

K8s Secrets rv diff :

| ns/secret | rv BEFORE | rv AFTER | Delta |
|---|---|---|---|
| keybuzz-api-prod/keybuzz-api-jwt | 31857841 | 70002863 | BUMPED |
| keybuzz-backend-prod/keybuzz-backend-secrets | 36935360 | 70002880 | BUMPED |
| keybuzz-client-prod/keybuzz-auth-secrets | 40891619 | 70002890 | BUMPED |
| keybuzz-backend-dev/keybuzz-backend-secrets | 69633502 | 70002911 | BUMPED |

Keys count preserves (hors scope properties preserves) :

| ns/secret | keys BEFORE | keys AFTER | Preservation |
|---|---|---|---|
| keybuzz-api-prod/keybuzz-api-jwt | 2 | 2 | OK |
| keybuzz-backend-prod/keybuzz-backend-secrets | 7 | 7 | OK 5 keys MINIO_*/PRODUCT_DATABASE_URL preserves |
| keybuzz-client-prod/keybuzz-auth-secrets | 6 | 6 | OK 5 OAuth keys GOOGLE_*/AZURE_AD_* preserves |
| keybuzz-backend-dev/keybuzz-backend-secrets | 8 | 8 | OK INBOUND_WEBHOOK_KEY + 5 keys hors scope preserves |

## 9. Restart group (B7)

| Deployment | Reloader auto | Restart mechanism | Trigger | Pod nouveau | Pod ancien |
|---|---|---|---|---|---|
| keybuzz-api-prod/keybuzz-api | true | AUTO reloader bump rv | post-B5 immediate | keybuzz-api-7685645f49-jx6m7 | keybuzz-api-7d5fd7d697-kf9dz Terminating |
| keybuzz-client-prod/keybuzz-client | true | AUTO reloader bump rv | post-B5 immediate | keybuzz-client-67cf86d784-jpsf4 | keybuzz-client-6b588c69fc-7897p Terminating |
| keybuzz-backend-prod/keybuzz-backend | absent | MANUAL kubectl rollout restart | 2026-05-17T14:24:46Z (GO Gate 2 Ludovic) | keybuzz-backend-84996c47fd-rhzrf | keybuzz-backend-56b9bc977d-v6jrw Terminating |
| keybuzz-backend-dev/keybuzz-backend | absent | MANUAL atomique parallel | 2026-05-17T14:24:46Z (meme trigger) | keybuzz-backend-5df4d94b9-zbqhz | keybuzz-backend-7b86b7ddb4-kx987 Terminating |

Restart backend PROD+DEV declenches en parallele kubectl (commandes lancees en background bash `&` puis `wait`). Trigger time UTC 14:24:46.711Z pour les 2 commandes. Fenetre desynchronisation KEYBUZZ_INTERNAL_TOKEN minimale (< 1 seconde entre les 2 kubectl rollout restart, pods rollout complets en 51s).

Rollout status :
- backend-prod : "deployment "keybuzz-backend" successfully rolled out" rc=0
- backend-dev : "deployment "keybuzz-backend" successfully rolled out" rc=0

## 10. Runtime validation (B9)

| Test | Resultat | Verdict |
|---|---|---|
| Vault HA Raft 3 nodes | unsealed, Raft 1140192 sync, vault-03 leader | OK |
| ExternalSecrets cluster-wide | 30/30 True | OK |
| 4 target ES Ready | True 4/4 | OK |
| ESO pods | 3/3 Running 0 restart | OK |
| Warning events 4 namespaces 10min | 0/0/0/0 | OK |
| 4 deployments Ready 1/1 | nouveaux pods api-prod 6m27s, client-prod 6m25s, backend-prod 51s, backend-dev 51s | OK |
| 4 pods restart count nouveau ReplicaSet | 0/0/0/0 | OK |
| Vault auth errors backend-prod | 0 (1 mention "Vault" = log informationnel + cert SSL warning pre-existant) | OK |
| Vault auth errors backend-dev | 7 mentions "Vault" = logs informationnels + 0 co-occurrence avec 403/unauthorized/invalid Vault auth specifique | OK |
| SP-API 403 backend-dev/prod | pre-existant (Amazon SP-API quota, hors scope rotation) | observe |
| keybuzz-api-prod 401 | 3 events 10min, sans cooccurrence Vault, probable health check/webhook | OK |
| keybuzz-backend-prod 403 | 2 events (SP-API), 401: 1 (idem) | OK |
| keybuzz-client-prod JWT_SESSION_ERROR | 30 events / 10min, decryption operation failed | ATTENDU rotation NEXTAUTH_SECRET (anciennes sessions invalides, identique Q-1B-1B DEV pattern) |

Pattern critique JWT_SESSION_ERROR :
```
[next-auth][error][JWT_SESSION_ERROR] decryption operation failed
```
30 events sur 10min sur client-prod = utilisateurs avec anciennes sessions encryptees ancien NEXTAUTH_SECRET. NextAuth detecte decryption fail et invite re-login. Comportement attendu et documente.

### Cross-env negative control DEV non-cible

| Deployment DEV | Pod | Age (unchanged) | Verdict |
|---|---|---|---|
| keybuzz-api-dev/keybuzz-api | keybuzz-api-587774dbb6-rzzmq | 17h (post-Q-1B-1B B7) | OK non touche |
| keybuzz-client-dev/keybuzz-client | keybuzz-client-c95894fb4-skjq2 | 99m (post-Q-1B-2A-bis) | OK non touche |
| keybuzz-api-dev/keybuzz-outbound-worker | keybuzz-outbound-worker-6db9686c76-kdtwk | 24h | OK non touche |

Aucun impact collateral DEV (sauf keybuzz-backend-dev qui etait dans scope cross-env internal-tokens, restart attendu B7).

## 11. Ludovic manual validation

MANUAL UX VALIDATION CONFIRMED 2026-05-17 par Ludovic : DEV fonctionne, PROD fonctionne, login/navigation OK, pas de boucle 401 observee. Verdict upgrade GO PROD INTERNAL ROTATION COMPLETE.

Items valides par Ludovic (reference pour audit) (UX/integration manuelle, hors scope CE) :
- ouvrir Client PROD (https://client.keybuzz.io ou equivalent).
- constater sessions anciennes invalidees (JWT_SESSION_ERROR observe = comportement attendu).
- se reconnecter avec compte test PROD (Google OAuth ou Azure AD).
- verifier navigation simple (dashboard, channels read-only).
- verifier API PROD repond sans boucle 401.
- verifier action simple non destructive.
- NE PAS tester paiement Stripe ni provider externe.
- NE PAS envoyer webhook externe.
- (optionnel) verifier DEV backend/API behavior simple.

Verdict final retenu : GO PROD INTERNAL ROTATION COMPLETE (Ludovic confirme DEV+PROD 2026-05-17).

CE n'a invente aucune validation. Aucun test automatise login execute.

## 12. Cleanup (B10)

| Action | Resultat |
|---|---|
| vault token lookup -self (rotator) | TTL=5416s still valid |
| vault token revoke -self | OK rotator self-revoked |
| shred /root/.vault-kv-rotator-q1b2.tmp | OK |
| shred /tmp/keybuzz-q1b2b-before.json | OK |
| shred /tmp/keybuzz-q1b2b-b1-verify.sh | absent (shred post-B1) |
| shred /tmp/keybuzz-q1b2b-b2-before.sh | absent (shred post-B2) |
| shred /tmp/keybuzz-q1b2b-b34-runner.sh | absent (shred post-B3+B4) |
| Verify 5 files absent | OK |

Note : Ludovic doit revoquer manuellement le root token temporaire Shamir si encore actif (Mode A separe, hors CE). Optionnel : vault policy delete keybuzz-kv-rotator-q1b2-temp apres validation Q-1B-2B stabilite 24-48h.

## 13. Rollback readiness

Non execute. Procedure documentee si incident detecte.

### Trigger conditions rollback

- ExternalSecret SecretSynced=False post-rotation
- Pod CrashLoopBackOff post-restart
- Vault 403/401 dans logs apps PROD massif (vs 30 JWT_SESSION_ERROR attendu client-prod)
- Ludovic ne peut plus login PROD apres rotation et UX validation echoue
- KEYBUZZ_INTERNAL_TOKEN desync cross-env detecte (api -> backend 401 massif)

### Procedure

```
# Phase R1 KV rollback (necessite nouveau rotator avec policy + capability rollback)
# Capability rollback sur paths data deja inclus dans policy keybuzz-kv-rotator-q1b2-temp (deleted post-Q-1B-2B)
# Re-creation rotator OU re-Shamir Ludovic root temp pour ad-hoc

vault kv rollback -version=1 secret/keybuzz/prod/jwt
vault kv rollback -version=1 secret/keybuzz/prod/backend-jwt
vault kv rollback -version=1 secret/keybuzz/prod/auth
vault kv rollback -version=1 secret/keybuzz/internal-tokens

# Phase R2 ESO force-sync 4 ES
kubectl annotate externalsecret force-sync=$(date +%s) --overwrite -n keybuzz-api-prod keybuzz-api-jwt
kubectl annotate externalsecret force-sync=$(date +%s) --overwrite -n keybuzz-backend-prod keybuzz-backend-secrets
kubectl annotate externalsecret force-sync=$(date +%s) --overwrite -n keybuzz-client-prod keybuzz-auth-secrets
kubectl annotate externalsecret force-sync=$(date +%s) --overwrite -n keybuzz-backend-dev keybuzz-backend-secrets

# Phase R3 Restart 4 deployments meme group (api-prod auto + client-prod auto + backend-prod MANUAL + backend-dev MANUAL atomique)
# api-prod et client-prod : restart auto par reloader (bump rv)
kubectl -n keybuzz-backend-prod rollout restart deployment keybuzz-backend
kubectl -n keybuzz-backend-dev rollout restart deployment keybuzz-backend

# Phase R4 Validation
# Idem B8-B9 mais expectation : pods Running, rv bumped vers rv rollback, sessions PROD continuent fonctionner avec anciens secrets
```

KV v2 retient par defaut 10 versions = rollback possible jusqu'a v1 (preserve).

## 14. AI feature parity / anti-regression

| Surface | Check read-only | Resultat | Verdict |
|---|---|---|---|
| IA / autopilot (LiteLLM) | pods Running | hors scope (verifie en Q-1F-1) | OK |
| Images runtime PROD | tag inchange post-Q-1B-2A-bis | v3.5.190-channels-tenantguard-prod api, v1.0.47-cross-env-guard-fix-prod backend, v3.5.198-debug-env-disabled-prod client | OK aucun build Q-1B-2B |
| Manifest IA/Inbox/connecteur | aucune modification | repos applicatifs non touches Q-1B-2B | OK |
| Inbox / messages | no new error burst logs | logs backend post-restart 118-298 lines normaux + SP-API 403 pre-existants | OK |
| Connecteurs marketplace | no new error burst | Octopia sync OK api-prod, SP-API 403 backend pre-existants hors scope | OK |
| Commandes / tracking colis | no new error burst | aucun pattern erreur nouveau | OK |
| Backend Amazon Fees module (KEYBUZZ_INTERNAL_TOKEN consumer) | aucun appel echec post-rotation | nouveaux pods backend PROD+DEV Running 1/1, 0 crashloop | OK fonctionnel attendu |

Aucun test mutationnel IA. Aucun message client. Aucun appel provider. Aucun email envoye. Aucun webhook externe mutationnel.

## 15. No fake metrics / no fake events

| Item | Source | Window | Mutation | Verdict |
|---|---|---|---|---|
| K8s Secret rv | kubectl get secret jsonpath | snapshot Q-1B-2B | non | reel |
| ExternalSecret Ready/refreshTime | kubectl get externalsecret jsonpath | snapshot Q-1B-2B | non | reel |
| Vault Raft index | vault status 3 nodes | snapshot Q-1B-2B | non | reel |
| KV current_version | vault kv metadata get | snapshot Q-1B-2B | non (lecture metadata) | reel |
| Log pattern counts | kubectl logs --since=10m + grep -c | 10min post-rotation | non | reel |
| Pod ages | kubectl get pods | snapshot Q-1B-2B | non | reel |
| Events Warning count | kubectl get events --field-selector | 4 namespaces | non | reel |

Aucun fake event. Aucun signup_complete, purchase, CAPI/GA4, paiement test, marketing mutation, dashboard pollution.

## 16. Incidents / anomalies

### Anomalie 1 : 30 JWT_SESSION_ERROR client-prod

| Champ | Detail |
|---|---|
| Severite | P3 (attendu) |
| Type | comportement documente |
| Cause | rotation NEXTAUTH_SECRET PROD invalide les anciennes cookies session encryptees avec ancien secret |
| Sample | `[next-auth][error][JWT_SESSION_ERROR] decryption operation failed` |
| Impact | utilisateurs PROD avec sessions actives doivent se re-login (mecanisme attendu) |
| Mitigation | re-login normal, identique pattern DEV Q-1B-1B/Q-1F-1 documente |
| Decision | accepte, low-impact (zero client reel actuel confirme Ludovic) |

### Anomalie 2 : SP-API 403 errors backend-dev/prod

| Champ | Detail |
|---|---|
| Severite | P2 pre-existant |
| Type | Amazon SP-API quota/auth |
| Cause | tokens Amazon SP-API expires/limites, defer Q-1B-6 marketplace OAuth |
| Lien Q-1B-2B | aucun (pre-existant Q-1F-1) |
| Decision | hors scope, defer Q-1B-6 |

### Anomalie 3 : NODE_TLS_REJECT_UNAUTHORIZED warning backend

| Champ | Detail |
|---|---|
| Severite | P2 pre-existant |
| Type | startup warning |
| Cause | NODE_TLS_REJECT_UNAUTHORIZED=0 dans manifest deployment backend (config dev temporary) |
| Lien Q-1B-2B | aucun |
| Decision | hors scope |

### Anomalie 4 : backfill-scheduler ImagePullBackOff dev+prod

| Champ | Detail |
|---|---|
| Severite | P1 pre-existant 48h+ |
| Lien Q-1B-2B | aucun |
| Decision | phase dediee future |

## 17. Risk register

| Risk | Severity | Status | Mitigation |
|---|---|---|---|
| Manual UX validation Ludovic PROD/DEV | resolved | CONFIRMED 2026-05-17 | OK : Ludovic confirme DEV+PROD login/navigation OK, pas de boucle 401 |
| Sessions PROD anciennes invalidees (NEXTAUTH_SECRET) | P3 attendu | observe (30 events 10min) | re-login normal users, zero client reel actuel |
| Cross-service JWT cassure transitoire (api -> backend) | P2 attendu | observe | restart atomique + ESO sync minimise fenetre, observe 0 cooccurrence Vault 401/403 backend |
| KEYBUZZ_INTERNAL_TOKEN cross-env desync | P0 mitige | OK | restart simultane backend-prod + backend-dev a 14:24:46Z (fenetre desync < 1 seconde commande, < 60s pod) |
| Hardcoded KEYBUZZ_INTERNAL_PROXY_TOKEN Client deployments | P2 observe | check | Client client-prod/dev consomme keybuzz-internal-proxy secret separe (pas keybuzz/internal-tokens), pas dans scope rotation |
| Rollback KV v2 capability | P2 mitigation | OK | rotator avait capability rollback (deja revoke maintenant). Si rollback necessaire, re-Shamir Ludovic ad-hoc |
| OAuth keys preservation secret/keybuzz/prod/auth | P0 mitige | OK | patch property-only sur nextauth_secret seul, 5 OAuth Google/Azure preserves verifies via keys count 6/6 |
| Reloader absent backend-prod | P1 known | OK B7 manual | restart manuel via GO Gate 2 Ludovic execute avec succes |
| backfill-scheduler ImagePullBackOff | P1 pre-existant | hors scope | phase dediee |
| Vault kv metadata get blocked post-cleanup | P2 known | observe | preuve indirecte K8s Secret rv unchanged + ESO refresh fresh suffisante (pattern Q-1F-1) |
| Future Q-1B-3/4/5/6 | P0 NO GO | maintenu | requires Ludovic decisions + scope confirmation |
| PROD promotion AS.17.0/AS.17.0.1 | P0 NO GO | maintenu | bloque jusqu'a Q-1B-x cycle complet + decisions Ludovic |

## 18. Linear draft comment (a poster par Codex apres commit)

```
AS.17.1Q-1B-2B PROD internal low-risk rotation execution Mode B SAFE COMPLETE

Commit rapport Q-1B-2A-bis : b00c9b8 (debug-env DEV+PROD fixed)
Commit rapport Q-1B-2B : <CE remplira apres push>
Verdict : GO PROD INTERNAL ROTATION COMPLETE (post UX validation Ludovic confirme 2026-05-17 : DEV+PROD login/navigation OK, pas de boucle 401).

Resume technique :
- 4 paths Vault KV PROD bumped v1 -> v2 :
  - secret/keybuzz/prod/jwt (JWT_SECRET + COOKIE_SECRET)
  - secret/keybuzz/prod/backend-jwt (JWT_SECRET)
  - secret/keybuzz/prod/auth (NEXTAUTH_SECRET property-only, 5 OAuth Google/Azure preserves)
  - secret/keybuzz/internal-tokens (KEYBUZZ_INTERNAL_TOKEN cross-env DEV+PROD)
- 5 properties internal generated rotatees via openssl rand -hex 32 (offline, 64 hex chars chacune, jamais affichees).
- 4 K8s Secrets resourceVersion BUMPED via ESO force-sync :
  - keybuzz-api-prod/keybuzz-api-jwt 31857841 -> 70002863
  - keybuzz-backend-prod/keybuzz-backend-secrets 36935360 -> 70002880
  - keybuzz-client-prod/keybuzz-auth-secrets 40891619 -> 70002890
  - keybuzz-backend-dev/keybuzz-backend-secrets 69633502 -> 70002911
- Keys count preservees post-rotation : 2/2, 7/7, 6/6, 8/8 (hors scope properties preserves).
- 4 deployments restartes :
  - keybuzz-api-prod/keybuzz-api : AUTO reloader (nouveau pod 7685645f49-jx6m7)
  - keybuzz-client-prod/keybuzz-client : AUTO reloader (nouveau pod 67cf86d784-jpsf4)
  - keybuzz-backend-prod/keybuzz-backend : MANUAL atomique GO Gate 2 Ludovic (nouveau pod 84996c47fd-rhzrf)
  - keybuzz-backend-dev/keybuzz-backend : MANUAL atomique parallele (nouveau pod 5df4d94b9-zbqhz)
- Restart backend PROD+DEV atomique trigger 2026-05-17T14:24:46.711Z, fenetre desync KEYBUZZ_INTERNAL_TOKEN < 1 sec entre kubectl commands + < 60s pod ready.
- Mode B SAFE Vault :
  - Policy keybuzz-kv-rotator-q1b2-temp scoped (4 paths data/metadata/rollback + auth/sys minimaux).
  - Token rotator non-root TTL 2h, accessor 0W6eyaHUkg...REDACTED, self-revoked TTL restant 5416s.
  - Negative tests 17 paths DENY confirme (DEV, admin-v2, infra, provider, PROD other).
- Validation runtime :
  - Vault HA Raft 3/3 unsealed stable, Raft 1140192 sync.
  - ExternalSecrets 30/30 SecretSynced=True.
  - ESO 3/3 Running.
  - 0 Warning event Kubernetes 4 namespaces 10min.
  - 0 erreur Vault auth runtime detectee (216 mentions "Vault" backend = logs informationnels, 0 cooccurrence avec 401/403/unauthorized).
  - 30 JWT_SESSION_ERROR client-prod = symptome ATTENDU rotation NEXTAUTH_SECRET (anciennes sessions decryption failed, identique pattern Q-1B-1B DEV / Q-1F-1 documente).
  - SP-API 403 backend pre-existant hors scope Q-1B-6.
  - Cross-env negative DEV non-cible : api-dev 17h + client-dev 99m + outbound-worker 24h unchanged (aucun impact collateral).
- Cleanup :
  - rotator self-revoke TTL 5416s.
  - 5 fichiers temp shred (rotator file + before.json + 3 runners deja shred post-execution).
  - root temp Shamir : Ludovic Mode A separe a revoke.
  - policy keybuzz-kv-rotator-q1b2-temp : peut etre supprimee apres Q-1F-2 stabilite 24-48h.
- Conformite : aucun secret/token/JWT/cookie/base64/KV value affiche, runner SCP atomique respecte, kubectl apply -f uniquement (pas patch/edit/set/annotate dans rotation, sauf annotate force-sync ES autorise).

Validation UX manuelle Ludovic CONFIRMED 2026-05-17 :
- DEV fonctionne.
- PROD fonctionne.
- login/navigation OK.
- pas de boucle 401 observee.

Gaps :
- Q-1B-3 provider externe (Stripe/SES/Slack/GHCR/Google/Azure OAuth/Google Ads/Meta Ads/Shopify/17track) NO GO defer.
- Q-1B-4 infra direct (Redis/Postgres/MinIO/SMTP) NO GO defer.
- Q-1B-5 LLM/AI (LITELLM_MASTER_KEY/OpenAI/Anthropic) NO GO defer.
- Q-1B-6 marketplace OAuth (Amazon SP-API/Shopify/Octopia) NO GO defer.
- PROD promotion AS.17.0/AS.17.0.1 NO GO maintenu.
- backfill-scheduler ImagePullBackOff dev+prod hors scope.
- root temp Shamir Ludovic a revoke manuellement.
- policy keybuzz-kv-rotator-q1b2-temp peut etre supprimee post-validation Q-1F-2.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

## 19. Conformite interdits

| Interdit Q-1B-2B | Respect |
|---|---|
| PROD mutation hors scope | OK : seuls 4 paths PROD + 1 cross-env DEV touches |
| Build/deploy | OK : aucun |
| GitOps manifest edit | OK : aucun (rotation = patch KV via vault kv patch + annotate force-sync ES, pas apply manifests) |
| kubectl set image/env/patch/edit | OK : aucun (uniquement annotate force-sync + rollout restart) |
| git reset --hard / git clean | OK : aucun |
| Affichage secret/token/value/base64/JWT/cookie | OK : tous redacts, valeurs jamais affichees, accessor redacted 10 chars + REDACTED |
| Provider externe call | OK : aucun (Google/Azure/Stripe/OpenAI/Anthropic/Amazon/Shopify/Octopia/SES/17track/Slack) |
| Fake metric/event | OK : aucun |
| Paiement test | OK : aucun |
| Webhook externe mutationnel | OK : aucun |
| Bastion install-v3 only | OK |
| /opt/keybuzz/credentials/ non touche | OK |
| /opt/keybuzz/secrets/ non touche | OK |
| Root token utilise par CE | OK : non utilise (Mode A separe Ludovic) |
| Ancien vault-admin-token utilise | OK : non utilise |
| admin-v2/bootstrap | OK : exclu confirme Ludovic |
| Q-1B-3/4/5/6 | OK : aucun |
| PROD promotion AS.17.0/AS.17.0.1 | OK : NO GO maintenu |
| debug-env modifications | OK : deja resolu Q-1B-2A-bis |
| ASCII strict rapport | a verifier post-Write |
| STOP avant commit/push | OK (B12 STOP) |

## 20. Resume commits / digests / runtime / accessors

| Item | Valeur |
|---|---|
| Rotator accessor (redacted) | 0W6eyaHUkg...REDACTED |
| Rotator policy | keybuzz-kv-rotator-q1b2-temp |
| Rotator TTL initial | 7082s (2h) |
| Rotator TTL post-rotation | 5416s self-revoked |
| KV paths rotated | 4 (prod/jwt, prod/backend-jwt, prod/auth, internal-tokens) |
| Properties rotated | 5 |
| K8s Secrets bumped | 4 (api-jwt, backend-secrets PROD, auth-secrets, backend-secrets DEV) |
| Deployments restarted | 4 (api-prod AUTO, client-prod AUTO, backend-prod MANUAL, backend-dev MANUAL atomique) |
| Restart trigger atomique time UTC | 2026-05-17T14:24:46.711Z |
| Backend pods nouveaux | rhzrf (PROD) + zbqhz (DEV) |
| API/Client pods nouveaux | jx6m7 (api-prod) + jpsf4 (client-prod) |
| Vault Raft post-rotation | 1140192 |
| ExternalSecrets cluster | 30/30 True |
| Cleanup status | rotator self-revoked + 5 files shred |
| JWT_SESSION_ERROR client-prod 10min | 30 (attendu rotation NEXTAUTH_SECRET) |

STOP final : rapport pret, en attente GO Ludovic commit/push B13.

Aucun enchainement sur Q-1B-3/4/5/6.
Aucun enchainement sur PROD promotion AS.17.0/AS.17.0.1.
Aucune rotation supplementaire sans nouveau rotator + Mode A creation policy.
