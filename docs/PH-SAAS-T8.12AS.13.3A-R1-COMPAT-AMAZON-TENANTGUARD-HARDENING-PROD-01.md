# PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-PROD-01
> Environnement : PROD (API uniquement). Client/Admin v2/Backend/Worker PROD strictement inchanges.

---

## 1. VERDICT

GO COMPAT AMAZON TENANTGUARD PROD READY

Les 6 endpoints HTTP fixes `/api/v1/marketplaces/amazon/*` exposes par le compat module sont desormais proteges par tenantGuard global en PROD via `ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod` (digest GHCR `sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe`, OCI revision `8f162dde531ccf9205a15d1ed2f801e1123367cf`). Probes negative-only PROD confirment l alignement exact avec DEV : sans `x-user-email` (no-auth) => 401 (3 endpoints testes) ; avec `x-user-email` + tenantId fictif non-member sur les 6 endpoints (incluant les 3 mutations provider externe disconnect / oauth/start / send-validation) => 403. Aucun POST positif emis, aucun proxy keybuzz-api -> keybuzz-backend declenche (logs `keybuzz-backend-prod` 2 min : 0 trace amazon/{status,oauth-start,disconnect,inbound-address} correlee aux probes).

DB `inbound_connections` PROD (total/amazon) = 6/6 identique avant=apres. Protections AS.13.1 google-observability, AS.13.2A outbound deliveries, AS.12.1A messages preservees (samples 400/400/403). 0 5xx API PROD 3 min. QA navigateur Ludovic confirmee sur Client PROD (Inbox, Brouillon IA, switcher, escalation, playbooks, Amazon UI lecture seule). Client / Admin v2 / Backend / Worker PROD strictement inchanges (images identiques). KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface protegee | API HTTP `/api/v1/marketplaces/amazon/*` (6 endpoints fixes) |
| Service runtime affecte | keybuzz-api uniquement (namespace keybuzz-api-prod) |
| Hors scope (strict) | keybuzz-client, keybuzz-admin-v2, keybuzz-outbound-worker, keybuzz-backend (4 deploys PROD), keybuzz-website, keybuzz-studio, keybuzz-seller |
| Pattern protection | tenantGuard global, PROTECTED_ROUTES static (6 entrees) aligne KEY-301 AS.11/12 |
| Source du patch | commit keybuzz-api `8f162dde feat(security): protect compat Amazon proxy via tenantGuard (KEY-313)` sur ph147.4/source-of-truth |

---

## 3. SOURCES RELUES

- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01.md
- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-DEV-01.md
- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md
- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md
- Linear KEY-313

---

## 4. PREFLIGHT

### 4.1 Repos

| Repo | Branche | HEAD avant | HEAD apres | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 8f162dde | 8f162dde | OK | dist/ deleted en worktree (cosmetique) | OK build-from-git |
| keybuzz-infra | main | 193cd2b | b377416 (manifest), puis rapport | OK | clean | OK |

### 4.2 Runtime avant promotion

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-api | v3.5.189-compat-amazon-tenantguard-dev |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev |
| PROD | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-prod (a promouvoir) |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |
| PROD | keybuzz-backend (4 deploys) | v1.0.40 / v1.0.42 / v1.0.47 (-prod) |

### 4.3 KEY-309

```
docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod
=> manifest unknown
```

Tag immuable libre avant push : OK.

---

## 5. BUILD EVIDENCE

Commande :
```
/opt/keybuzz/keybuzz-infra/scripts/build-api-from-git.sh prod v3.5.189-compat-amazon-tenantguard-prod ph147.4/source-of-truth
```

KEY-308 OCI labels :

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | 8f162dde531ccf9205a15d1ed2f801e1123367cf (SHA full) |
| org.opencontainers.image.created | 2026-05-14T11:45:15Z |
| org.opencontainers.image.version | v3.5.189-compat-amazon-tenantguard-prod |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |

Image locale ID : `sha256:3d466c8ad3f3b3c9041f7155d17200a108f82e72d008769b12eceb997818854e`.

---

## 6. PUSH DIGEST

Commande :
```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod
```

| Item | Valeur |
|---|---|
| Image | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod |
| Manifest digest GHCR | sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe |
| Manifest size | 2416 |
| Config digest (= image ID local) | sha256:3d466c8ad3f3b3c9041f7155d17200a108f82e72d008769b12eceb997818854e |

KEY-309 respecte (tag unique immuable).

---

## 7. GITOPS EVIDENCE

### 7.1 Manifest patch (1 fichier, +2/-1)

```
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod  # PH-SAAS-T8.12AS.13.2A-PROD KEY-313 ...
+          # PREVIOUS: v3.5.188-outbound-deliveries-tenantguard-prod  # PH-SAAS-T8.12AS.13.2A-PROD KEY-313 (2026-05-14)
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod  # PH-SAAS-T8.12AS.13.3A-PROD KEY-313 (2026-05-14): extend tenantGuard to compat Amazon legacy proxy (6 fixed endpoints, API-only, no positive mutations) ; rollback: v3.5.188-outbound-deliveries-tenantguard-prod ; digest: sha256:3a6661f7...
```

### 7.2 Commit + push

- Commit : `b377416 deploy(prod): protect compat Amazon tenant scope (KEY-313)` sur main
- Push : `193cd2b..b377416 main -> main`
- Scope : 1 fichier, +2 lignes, -1 ligne

### 7.3 Apply + rollout

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
=> deployment.apps/keybuzz-api configured
kubectl rollout status deploy/keybuzz-api -n keybuzz-api-prod --timeout=240s
=> deployment "keybuzz-api" successfully rolled out
```

### 7.4 spec = lastApplied = podImageID = digest GHCR

| Item | Valeur |
|---|---|
| deploy.spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod |
| pod hxmsp status.containerStatuses[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod |
| pod hxmsp status.containerStatuses[0].imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe |
| pod hxmsp ready / restart | true / 0 |

Identite spec = lastApplied = podImageID = digest GHCR : CONFIRMEE.

---

## 8. VALIDATION NEGATIVE-ONLY PROD

URL : `https://api.keybuzz.io`. UUID fictif `00000000-...`, email `probe@example.invalid`. **Aucun POST positif emis** vers les 3 mutations provider externe (disconnect / oauth/start / send-validation).

| Test | Endpoint | Headers | Expected | Actual | Backend/provider impact | DB impact | Verdict |
|---|---|---|---|---|---|---|---|
| N1 | GET /api/v1/marketplaces/amazon/status?tenantId=fake | aucun | 400/401 | 401 | 0 | 0 | OK |
| N2 | GET status | email=probe, tenant=fake | 403 not member | 403 | 0 | 0 | OK |
| N3 | POST /api/v1/marketplaces/amazon/disconnect | aucun | 400/401 | 401 | 0 (no backend proxy) | 0 | OK |
| N4 | POST disconnect | email=probe, tenant=fake | 403 | 403 | 0 (no Amazon OAuth revoke) | 0 | OK |
| N5 | GET /api/v1/marketplaces/amazon/oauth/start?tenantId=fake | aucun | 400/401 | 401 | 0 | 0 | OK |
| N6 | GET oauth/start | email=probe, tenant=fake | 403 | 403 | 0 (no OAuth state generated) | 0 | OK |
| N7 | POST oauth/start | email=probe, tenant=fake | 403 | 403 | 0 | 0 | OK |
| N8 | GET /api/v1/marketplaces/amazon/inbound-address?tenantId=fake | email=probe, tenant=fake | 403 | 403 | 0 | 0 | OK |
| N9 | POST /api/v1/marketplaces/amazon/inbound-address/send-validation (CRITIQUE) | email=probe, tenant=fake | 403 (no real email) | 403 | 0 (no SES email sent) | 0 | OK |

Lecture : tenantGuard global intercepte avant le handler compat. Les rejets (401/403) ne touchent ni la DB locale `inbound_connections`, ni le backend, ni le provider Amazon SP-API, ni le service email SES.

### 8.1 Preserve sample protections

| Famille | Sample | Verdict attendu | Observe |
|---|---|---|---|
| AS.13.2A outbound deliveries | `GET /outbound/deliveries` no headers | 400 | 400 |
| AS.13.1 google-observability | `GET /outbound-conversions/google-observability` no headers | 400 | 400 |
| AS.12.1A messages/conversations | `GET /messages/conversations` fake email + fake tenant | 403 | 403 |

Protections KEY-301 + AS.13.1 + AS.13.2A PROD preservees apres promotion AS.13.3A.

---

## 9. DB / BACKEND / PROVIDER NO-MUTATION

| Counter inbound_connections (PROD) | Avant probes | Apres probes | Delta |
|---|---|---|---|
| total | 6 | 6 | 0 |
| WHERE marketplace='amazon' | 6 | 6 | 0 |

| Surveillance | Periode | Resultat |
|---|---|---|
| Backend PROD `keybuzz-backend` logs (amazon/{status,oauth-start,disconnect,inbound-address}) | 2 min apres probes | 0 trace correlee aux probes |
| API PROD `keybuzz-api` stdout 5xx | 3 min | 0 ligne 5xx |
| Provider Amazon SP-API calls | implicite | 0 (aucun backend hit) |
| Email SES validation envoyes | implicite (N9 bloque) | 0 |
| Pod API PROD restart | post-rollout | 0 (nouveau pod, frais) |

Conforme `no fake metrics / no fake events / no fake conversion / no fake provider response / no fake Amazon event / no fake marketplace state`.

---

## 10. LOGS / QA

### 10.1 Logs PROD

- API PROD 3 min post-rollout : 0 5xx, traffic conforme aux probes (9 reponses 401/403 attendues).
- Backend PROD 2 min : 0 trace amazon/{status,oauth-start,disconnect,inbound-address} correlee aux probes. Le backend tourne normalement (workers sync orders, image v1.0.40 inchangee).

### 10.2 QA Ludovic Client PROD

URL : `https://client.keybuzz.io`

Confirmation Ludovic :
> "OK : QA Client PROD validee sur https://client.keybuzz.io. Inbox OK, Brouillon IA OK sur les cas attendus, tenant switcher OK, escalation OK, playbooks read-only OK. Amazon UI moderne verifiee en lecture seule, sans disconnect, sans OAuth start, sans send-validation. Aucune regression visible. Aucune mutation declenchee."

Lecture : la chain Client moderne fonctionne normalement. Les BFF `app/api/amazon/*/route.ts` consomment `BACKEND_URL` directement, donc la protection du compat keybuzz-api ne touche aucune chain UX legitime.

---

## 11. PROD SERVICES UNCHANGED

| Service | Namespace | Image avant | Image apres | Action effectuee |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.188-outbound-deliveries-tenantguard-prod | v3.5.189-compat-amazon-tenantguard-prod | apply manifest + rollout |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | aucune |
| keybuzz-client | keybuzz-client-prod | v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff-prod | aucune |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | aucune |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | aucune |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | inchange | aucune |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | inchange | aucune |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | inchange | aucune |

Aucun build PROD autre que API. Aucun docker push autre que API. Aucun kubectl apply autre que `k8s/keybuzz-api-prod/deployment.yaml`. Aucun set/edit/patch.

---

## 12. ROLLBACK

Procedure si regression critique :

1. `cd /opt/keybuzz/keybuzz-infra && git revert b377416 --no-edit`
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deploy/keybuzz-api -n keybuzz-api-prod --timeout=240s`

Tag de rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod` (stable PROD precedente, presente sur GHCR).

Effet rollback : reouvre la surface compat `/api/v1/marketplaces/amazon/*` non-member en PROD mais restaure le runtime stable AS.13.2A-PROD.

Rollback NON declenche : verdict GO valide.

---

## 13. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans secret OAuth, sans client_id/client_secret, sans seller_id, sans PII) :

```
PH-SAAS-T8.12AS.13.3A-R1 PROD livre.

Runtime API PROD : v3.5.189-compat-amazon-tenantguard-prod
Digest GHCR : sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe
OCI revision : 8f162dde531ccf9205a15d1ed2f801e1123367cf

6 endpoints HTTP /api/v1/marketplaces/amazon/* du compat keybuzz-api desormais proteges par tenantGuard global (DEV+PROD) :
- GET status
- POST disconnect
- GET oauth/start
- POST oauth/start
- GET inbound-address
- POST inbound-address/send-validation

Probes negative-only PROD : N1/N3/N5 401 (no x-user-email), N2/N4/N6/N7/N8/N9 403 (not member). Aucun POST positif (disconnect / oauth/start / send-validation jamais declenche). Aucun proxy keybuzz-api -> keybuzz-backend correle aux probes (logs backend PROD 2 min : 0 trace amazon/{status,oauth-start,disconnect,inbound-address}). Aucun OAuth state genere, aucun email reel SES envoye, aucune deconnexion provider Amazon declenchee.

DB inbound_connections inchange (6 amazon avant=apres). 0 5xx API PROD 3 min.

Preserve : AS.13.2A outbound deliveries 400 sample, AS.13.1 google-observability 400 sample, AS.12.1 messages 403 sample. QA Ludovic Client PROD : Inbox, Brouillon IA, switcher, escalation, playbooks read-only OK. Amazon UI moderne lecture seule OK (consume backend directement via BFF, aucune dependance au compat keybuzz-api).

Client / Admin v2 / Backend (4 deploys) / Worker outbound PROD strictement inchanges.

KEY-313 reste Open. KEY-301 reste Done.

Next : AS.13.4 destinations confirmatif (6 endpoints, audit confirmatif `checkAccess` deja en place, probable 0 patch) en attente GO Ludovic explicite. Suivi backlog : R3 backend defense-in-depth (network segmentation + rotation X-Internal-Token), R2.2 outbound deliveries UPDATEs scope.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. NEXT AS.13.4 DESTINATIONS CONFIRMATIF

| Phase | Scope | Statut |
|---|---|---|
| AS.13.4 design audit | outbound-conversions/destinations : 6 endpoints. Audit confirmatif `checkAccess` couvre 100% des handlers. Probable 0 patch (destinations deja proteges par checkAccess local via user_tenants). | En attente GO Ludovic explicite |
| AS.13.4 IMPL (optionnel) | uniquement si gap detecte par l audit | En attente |
| R2.2 outbound UPDATEs scope | ajouter `AND tenant_id = $X` dans les 3 UPDATEs outbound_deliveries (simulate-deliver, simulate-fail, retry) | Backlog hors KEY-313 strict |
| R3 backend defense-in-depth | network segmentation backend + rotation `KEYBUZZ_INTERNAL_PROXY_TOKEN` (gap U1 AS.13.3 design) | Backlog hors KEY-313 strict |
| U2 surveillance | Surveiller logs API PROD 401/403 sur `/api/v1/marketplaces/amazon/*` post AS.13.3A pour detecter d eventuels consumers externes legitimes inattendus | Continu |
| KEY-312 (GP1) | PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 garde-fous metier | Hors scope KEY-313 |

---

## 15. VERDICTS AUTORISES

- GO COMPAT AMAZON TENANTGUARD PROD READY (verdict retenu)
- NO GO COMPAT AMAZON PROD ROLLBACK DONE
- NO GO PROVIDER MUTATION RISK DETECTED
- NO GO SOURCE DIRTY / DRIFT

---

## 16. PHRASE CIBLE FINALE

GO COMPAT AMAZON TENANTGUARD PROD READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.4 sans GO Ludovic explicite.

STOP.
