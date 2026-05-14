# PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-DEV-01
> Environnement : DEV (API uniquement). PROD strictement inchangee.

---

## 1. VERDICT

GO COMPAT AMAZON TENANTGUARD DEV READY

Les 6 endpoints HTTP fixes `/api/v1/marketplaces/amazon/*` exposes par le compat module de `keybuzz-api` sont desormais proteges par tenantGuard global en DEV via `ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-dev` (digest GHCR `sha256:214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848`, OCI revision `8f162dde531ccf9205a15d1ed2f801e1123367cf`). Probes negative-only DEV confirment :
- sans `x-user-email` (no-auth) sur GET status / POST disconnect / GET oauth/start => 401 ;
- avec `x-user-email` + tenantId fictif non-member sur les 6 endpoints (incluant POST disconnect / oauth/start GET+POST / send-validation) => 403 ;
- aucun POST positif emis vers les 3 mutations provider externe (disconnect / oauth/start / send-validation) ;
- aucun proxy backend declenche (logs `keybuzz-backend-dev` 2 min : 0 trace `oauth-start`, `disconnect`, `inbound-address` correlee aux probes).

DB `inbound_connections` DEV (total/amazon) = 8/8 identique avant=apres. Protections AS.13.1 google-observability, AS.13.2A outbound deliveries, AS.12.1A messages preservees (samples 400/400/403). 0 5xx API DEV 3 min. QA navigateur Ludovic confirmee sur Client DEV (Inbox, Brouillon IA, switcher, escalation, playbooks, Amazon integration UI en lecture seule). PROD strictement inchangee. KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface protegee | API HTTP `/api/v1/marketplaces/amazon/*` (6 endpoints fixes) |
| Module patch | `keybuzz-api/src/plugins/tenantGuard.ts` (+11 lignes : 5 commentaire + 6 entrees `PROTECTED_ROUTES`) |
| Handler compat | `keybuzz-api/src/modules/compat/routes.ts` (INCHANGE) |
| Hors scope strict | Client BFF (consume backend directement), Admin v2 (zero consumer compat), Backend keybuzz-backend (hors scope KEY-313, voir R3 backlog), Worker, cron, AS.13.4 destinations, R2.2 outbound deliveries defense-in-depth, R3 backend trust X-Internal-Token |
| Pattern protection | tenantGuard global avec PROTECTED_ROUTES static (paths fixes, pas de matchers dynamiques) |

---

## 3. SOURCES

- PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01.md (design audit detaille)
- PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md (R1 precedent PROD)
- PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md
- PH-SAAS-T8.12AS.12.3A-KEY-301-LINEAR-CLOSEOUT-01.md
- Linear KEY-313

---

## 4. PREFLIGHT

### 4.1 Repos

| Repo | Path | Branche | HEAD avant | HEAD apres | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 55ab4bd6 | 8f162dde | OK | dist/ deleted en worktree (cosmetique, build-from-git fresh clone) | OK |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 78f60c3 | 64856d4 (manifest), puis rapport | OK | clean | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970fb3b4 | inchange | OK | clean | read-only |
| keybuzz-backend | /opt/keybuzz/keybuzz-backend | main | b183817d3bf6 | inchange | OK | 1 fichier dirty pre-existant (hors scope) | read-only |

### 4.2 Runtime avant promotion

| Env | Service | Image avant | Statut |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-dev | a promouvoir |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | inchange |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev | inchange |
| DEV | keybuzz-backend | v1.0.40 / v1.0.42 / v1.0.47 (-dev) | inchange |
| DEV | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | inchange |
| PROD | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-prod | strictement inchange |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod | strictement inchange |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | strictement inchange |
| PROD | keybuzz-backend | v1.0.40 / v1.0.42 / v1.0.47 (-prod) | strictement inchange |

KEY-309 tag `v3.5.189-compat-amazon-tenantguard-dev` : `manifest unknown` avant push (libre).

---

## 5. PATCH SOURCE

Fichier : `keybuzz-api/src/plugins/tenantGuard.ts`

Ajout : 6 entrees a `PROTECTED_ROUTES` static, regroupees apres les entrees AS.12.2C-5B, avec commentaire de phase :

```typescript
// PH-SAAS-T8.12AS.13.3A KEY-313: compat Amazon legacy proxy (6 fixed paths).
// The compat module forwards to keybuzz-backend with X-Internal-Token. Client BFF
// and api-client.ts:fetchBackend already target keybuzz-backend directly, so 0
// legitimate consumer of the compat surface is observed. Each path is whitelisted
// by exact (method, path) to require user_tenants membership before proxy.
{ method: 'GET', path: '/api/v1/marketplaces/amazon/status' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/disconnect' },
{ method: 'GET', path: '/api/v1/marketplaces/amazon/oauth/start' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/oauth/start' },
{ method: 'GET', path: '/api/v1/marketplaces/amazon/inbound-address' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/inbound-address/send-validation' },
```

Aucun matcher dynamique ajoute (les 6 paths sont fixes). Aucune modification de `isProtected` (les entrees passent par la verification `PROTECTED_ROUTES.some(...)` existante). Aucune modification de `compat/routes.ts`. Aucun hardcode tenant/email/provider/seller.

Diff observable :
```
src/plugins/tenantGuard.ts | 11 +++++++++++
 1 file changed, 11 insertions(+)
```

Commit + push :

| Commit | Message | Repo | Push |
|---|---|---|---|
| 8f162dde | feat(security): protect compat Amazon proxy via tenantGuard (KEY-313) | keybuzz-api ph147.4/source-of-truth | 55ab4bd6..8f162dde |

Verifications source :
- 6 endpoints exact-path couverts (GET status + POST disconnect + GET/POST oauth/start + GET inbound-address + POST inbound-address/send-validation).
- Aucune route compat non inventoriee n est capturee (pas de wildcard prefix).
- AS.13.1 `/outbound-conversions/google-observability` non capture (prefix different).
- AS.13.2A `/outbound/deliveries*` non capture (matchers dynamiques deja en place + prefix different).
- AS.12 `/messages*`, `/notifications*`, `/autopilot*`, `/ai/*`, `/playbooks*` non captures.

---

## 6. BUILD EVIDENCE

Commande :
```
/opt/keybuzz/keybuzz-infra/scripts/build-api-from-git.sh dev v3.5.189-compat-amazon-tenantguard-dev ph147.4/source-of-truth
```

Sequence : fresh clone github.com/keybuzzio/keybuzz-api ph147.4/source-of-truth dans /tmp/keybuzz-api-build-$$ ; verif clean ; docker build --no-cache avec ARGs IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION.

KEY-308 OCI labels :

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | 8f162dde531ccf9205a15d1ed2f801e1123367cf (SHA full) |
| org.opencontainers.image.created | 2026-05-14T11:27:41Z |
| org.opencontainers.image.version | v3.5.189-compat-amazon-tenantguard-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |

Image locale ID : `sha256:dd51be200748e32e6ce960a3f159b9f9a7e579ee609f33d96c2fac0e4c468d7a`. Push GHCR : digest `sha256:214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848`, size 2416.

---

## 7. GITOPS EVIDENCE

### 7.1 Manifest patch (1 fichier, +2/-1)

```
-        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-dev  # PH-SAAS-T8.12AS.13.2A KEY-313 ...
+        # PREVIOUS: v3.5.188-outbound-deliveries-tenantguard-dev  # PH-SAAS-T8.12AS.13.2A KEY-313 (2026-05-14)
+        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-dev  # PH-SAAS-T8.12AS.13.3A KEY-313 (2026-05-14): extend tenantGuard to compat Amazon legacy proxy (6 fixed endpoints, API-only, no positive mutations) ; rollback: v3.5.188-outbound-deliveries-tenantguard-dev ; digest: sha256:214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848
```

### 7.2 Commit + push

- Commit : `64856d4 deploy(dev): protect compat Amazon tenant scope (KEY-313)` sur main
- Push : `78f60c3..64856d4 main -> main`
- Scope : 1 fichier, +2 lignes, -1 ligne

### 7.3 Apply + rollout

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
=> deployment.apps/keybuzz-api configured
kubectl rollout status deploy/keybuzz-api -n keybuzz-api-dev --timeout=240s
=> deployment "keybuzz-api" successfully rolled out
```

### 7.4 spec = lastApplied = podImageID = digest GHCR

| Item | Valeur |
|---|---|
| deploy.spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-dev |
| pod qchw2 status.containerStatuses[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-dev |
| pod qchw2 status.containerStatuses[0].imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848 |
| pod final | ready=1 restart=0 |

Identite spec = lastApplied = podImageID = digest GHCR : CONFIRMEE.

---

## 8. VALIDATION NEGATIVE-ONLY DEV

URL : `https://api-dev.keybuzz.io`. UUID fictif `00000000-0000-0000-0000-000000000000`, email `probe@example.invalid`. **Aucun POST positif emis** vers les 3 mutations provider externe (disconnect / oauth/start / send-validation).

| Test | Endpoint | Headers | Expected | Actual | Backend/provider impact | DB impact | Verdict |
|---|---|---|---|---|---|---|---|
| N1 | GET /api/v1/marketplaces/amazon/status?tenantId=fake | aucun | 400/401 | 401 | 0 (no proxy) | 0 | OK |
| N2 | GET /api/v1/marketplaces/amazon/status?tenantId=fake | email=probe, tenant=fake | 403 not member | 403 | 0 | 0 | OK |
| N3 | POST /api/v1/marketplaces/amazon/disconnect | aucun | 400/401 | 401 | 0 (no proxy) | 0 | OK |
| N4 | POST /api/v1/marketplaces/amazon/disconnect | email=probe, tenant=fake | 403 (no real revoke) | 403 | 0 (no backend call, no OAuth revoke Amazon) | 0 | OK |
| N5 | GET /api/v1/marketplaces/amazon/oauth/start?tenantId=fake | aucun | 400/401 | 401 | 0 | 0 | OK |
| N6 | GET /api/v1/marketplaces/amazon/oauth/start?tenantId=fake | email=probe, tenant=fake | 403 (no OAuth start) | 403 | 0 (no OAuth state generated) | 0 | OK |
| N7 | POST /api/v1/marketplaces/amazon/oauth/start | email=probe, tenant=fake | 403 (no OAuth state) | 403 | 0 | 0 | OK |
| N8 | GET /api/v1/marketplaces/amazon/inbound-address?tenantId=fake | email=probe, tenant=fake | 403 | 403 | 0 (no backend read of SES address) | 0 | OK |
| N9 | POST /api/v1/marketplaces/amazon/inbound-address/send-validation (CRITIQUE) | email=probe, tenant=fake | 403 (no real email) | 403 | 0 (no SES email sent) | 0 | OK |

Lecture : tenantGuard global intercepte AVANT le handler module. Les rejets pre-handler (401/403) ne touchent ni la DB locale, ni le backend, ni le provider Amazon SP-API, ni le service email.

### 8.1 Preserve sample protections

| Famille | Sample | Verdict attendu | Observe |
|---|---|---|---|
| AS.13.2A outbound deliveries | `GET /outbound/deliveries` no headers | 400 TENANT_ID_MISSING | 400 |
| AS.13.1 google-observability | `GET /outbound-conversions/google-observability` no headers | 400 missing | 400 |
| AS.12.1A messages/conversations | `GET /messages/conversations` fake email + fake tenant | 403 not member | 403 |

Aucune regression dans les protections KEY-301/AS.13.1/AS.13.2A.

---

## 9. DB / BACKEND / PROVIDER NO-MUTATION

| Counter inbound_connections (DEV) | Avant probes | Apres probes | Delta |
|---|---|---|---|
| total | 8 | 8 | 0 |
| WHERE marketplace='amazon' | 8 | 8 | 0 |

| Surveillance | Periode | Resultat |
|---|---|---|
| Backend DEV `keybuzz-backend` logs (oauth/start, disconnect, inbound-address) | 2 min apres probes | 0 trace correlee aux probes ; seuls les workers amazon-orders-worker / amazon-items-worker / backfill-scheduler tournent (background sync, non lie au compat HTTP) |
| API DEV `keybuzz-api` stdout 5xx | 3 min | 0 ligne 5xx |
| Provider Amazon SP-API calls | implicite (aucun backend hit) | 0 |
| Email SES validation envoyes | implicite (N9 bloque) | 0 |
| Worker outbound DEV logs (no pickup correlation) | 2 min | aucun pickup nouveau lie a Amazon |
| Pod API DEV restart count | post-rollout | 0 |

Conforme `no fake metrics / no fake events / no fake conversion / no fake provider response / no fake Amazon event / no fake marketplace state`.

---

## 10. LOGS / QA

### 10.1 Logs DEV

- API DEV 3 min post-rollout : 0 5xx, traffic conforme aux probes (9x 401/403 attendus).
- Backend DEV 2 min : aucun proxy keybuzz-api -> backend declenche par les probes. Les workers sync orders tournent normalement (background, image v1.0.40 inchangee).
- Worker outbound DEV : image v3.5.165 inchangee, restart count inchange.

### 10.2 QA Ludovic Client DEV

URL : `https://client-dev.keybuzz.io`

Confirmation Ludovic :
> "OK : QA DEV validee sur https://client-dev.keybuzz.io. Inbox OK, Brouillon IA OK sur les cas attendus, tenant switcher OK, escalation OK, playbooks read-only OK. Amazon integration UI moderne verifiee en lecture seule, sans disconnect, sans OAuth start, sans send-validation. Aucune regression visible. Aucune mutation declenchee."

Lecture : le Client moderne consomme `BACKEND_URL` directement via ses BFF Next.js (`app/api/amazon/*/route.ts`) -- aucune dependance au compat keybuzz-api. La protection du compat ne casse donc aucune chain UX.

---

## 11. PROD UNCHANGED

| Service | Namespace | Image PROD | Action effectuee |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.188-outbound-deliveries-tenantguard-prod | aucune |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | aucune |
| keybuzz-client | keybuzz-client-prod | v3.5.196-ai-rules-bff-prod | aucune |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | aucune |
| keybuzz-backend (4 deploys) | keybuzz-backend-prod | v1.0.40 / v1.0.42 / v1.0.47 (-prod) | aucune |

Aucun build PROD, aucun docker push PROD, aucun kubectl apply PROD, aucun set/edit/patch. PROD strictement read-only pour cette phase.

---

## 12. ROLLBACK

Procedure DEV si regression critique :

1. `cd /opt/keybuzz/keybuzz-infra && git revert 64856d4 --no-edit`
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`
4. `kubectl rollout status deploy/keybuzz-api -n keybuzz-api-dev --timeout=240s`

Tag de rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-dev` (stable DEV precedente, present sur GHCR).

Effet rollback : reouvre la surface compat Amazon non-member en DEV uniquement. Aucun impact PROD (deja sur v3.5.188).

Rollback NON declenche : verdict GO valide.

---

## 13. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans secret OAuth / client_id / seller_id, sans PII) :

```
PH-SAAS-T8.12AS.13.3A-R1 DEV livre.

Runtime API DEV : v3.5.189-compat-amazon-tenantguard-dev
Digest GHCR : sha256:214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848
OCI revision : 8f162dde531ccf9205a15d1ed2f801e1123367cf

6 endpoints HTTP /api/v1/marketplaces/amazon/* du compat keybuzz-api desormais proteges par tenantGuard global :
- GET status
- POST disconnect
- GET oauth/start
- POST oauth/start
- GET inbound-address
- POST inbound-address/send-validation

Probes negative-only DEV : N1/N3/N5 401 (no x-user-email), N2/N4/N6/N7/N8/N9 403 (not member). Aucun POST positif (disconnect / oauth/start / send-validation jamais declenche). Aucun proxy keybuzz-api -> keybuzz-backend correle aux probes (logs backend DEV 2 min : 0 trace amazon/{oauth-start,disconnect,inbound-address}). Aucun OAuth state genere, aucun email reel envoye, aucune deconnexion declenchee.

DB inbound_connections inchange (8 amazon connections avant=apres). 0 5xx API DEV 3 min.

Preserve : AS.13.2A outbound deliveries 400 sample, AS.13.1 google-observability 400 sample, AS.12.1 messages 403 sample. QA Ludovic Client DEV : Inbox, Brouillon IA, switcher, escalation, playbooks read-only OK. Amazon integration UI moderne verifiee en lecture seule (le Client moderne consume backend directement via BFF, aucune dependance au compat keybuzz-api).

PROD strictement inchangee. Aucun build/push/apply PROD. KEY-313 reste Open. KEY-301 reste Done.

Next : AS.13.3A-PROD (promotion API PROD v3.5.189) en attente GO Ludovic explicite. Suivi backlog : R3 backend defense-in-depth (network segmentation + X-Internal-Token rotation), AS.13.4 destinations confirmatif.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 14. GAPS R3 BACKEND DEFENSE-IN-DEPTH / NEXT PROD

| Phase | Scope | Statut |
|---|---|---|
| AS.13.3A-PROD | build API PROD v3.5.189-compat-amazon-tenantguard-prod + push + GitOps PROD apply + validation negative-only + QA Ludovic | En attente GO Ludovic explicite |
| AS.13.4 destinations confirmatif | 6 endpoints, audit confirmatif `checkAccess` deja en place. Probable 0 patch. | Apres AS.13.3A-PROD |
| R2.2 defense-in-depth outbound | Ajouter `AND tenant_id = $X` dans les 3 UPDATEs outbound_deliveries | Backlog hors KEY-313 strict |
| R3 backend defense-in-depth | Network segmentation keybuzz-backend + rotation `KEYBUZZ_INTERNAL_PROXY_TOKEN` (gap U1 AS.13.3 design) | Backlog hors KEY-313 strict |
| U2 surveillance | Surveiller logs API PROD 401/403 post AS.13.3A-PROD pour detecter d eventuels consumers externes legitimes | Post-promotion PROD |
| KEY-312 (GP1) | PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 garde-fous metier | Hors scope KEY-313 |

---

## 15. VERDICTS AUTORISES

- GO COMPAT AMAZON TENANTGUARD DEV READY (verdict retenu)
- NO GO COMPAT AMAZON REGRESSION ROLLBACK DONE
- NO GO PROVIDER MUTATION RISK DETECTED
- NO GO SOURCE DIRTY / DRIFT

---

## 16. PHRASE CIBLE FINALE

GO COMPAT AMAZON TENANTGUARD DEV READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.3A-PROD sans GO Ludovic explicite.

STOP.
