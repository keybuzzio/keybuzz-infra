# PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01
> Environnement : PROD (API uniquement). Client/Admin v2/worker outbound PROD strictement inchanges.

---

## 1. VERDICT

GO OUTBOUND DELIVERIES TENANTGUARD PROD READY

Les 5 endpoints HTTP `/outbound/deliveries*` sont desormais proteges par tenantGuard global en PROD via `ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod` (digest GHCR `sha256:d7a25ce81598211f433ad0ba945a2176d60e0d20ac2aea7d893189ca744d4c1b`, OCI revision `55ab4bd6de48d91746f04e0024a2898f91945c1f`). Probes negative-only confirment l alignement exact avec DEV : sans headers => 400 (module preHandler) ; tenantId seul sans email => 401 (tenantGuard) ; fake email + fake tenant non-member sur les 5 endpoints (incluant les 3 mutations simulate-deliver / simulate-fail / retry) => 403. Aucun POST positif emis, aucun pickup worker, aucun appel provider externe.

DB `outbound_deliveries` PROD (total/queued/delivered/failed/attempts) = 246/0/245/1/250 identique avant=apres probes. AS.13.1 google-observability et AS.12.1 messages/conversations protections preservees (samples 400/403). 0 5xx API PROD 5-10 min. QA navigateur Ludovic confirmee sur Client PROD (Inbox, Brouillon IA, switcher, escalation, playbooks). Client / Admin v2 / outbound worker PROD strictement inchanges. KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface protegee | API HTTP `/outbound/deliveries*` (5 endpoints : 2 GET + 3 mutations) |
| Service runtime affecte | keybuzz-api uniquement (namespace keybuzz-api-prod) |
| Hors scope (strict) | keybuzz-client, keybuzz-admin-v2, keybuzz-outbound-worker, keybuzz-backend, keybuzz-website, keybuzz-studio, keybuzz-seller |
| Pattern protection | tenantGuard global avec matchers dynamiques `isOutboundDeliveriesGet` + `isOutboundDeliveryAction` (aligne KEY-301 AS.11/12) |
| Source du patch | commit keybuzz-api `55ab4bd6 feat(security): protect outbound deliveries via tenantGuard (KEY-313)` sur ph147.4/source-of-truth |

---

## 3. SOURCES RELUES

- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01.md
- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-DEV-01.md
- /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md
- Linear KEY-313 (R1 outbound+compat surfaces tenantGuard extension)

---

## 4. PREFLIGHT

### 4.1 Repos

| Repo | Branche | HEAD avant | HEAD apres | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 55ab4bd6 | 55ab4bd6 | OK fetch origin | dist/ deleted en worktree (cosmetique) | OK build-from-git |
| keybuzz-infra | main | a8a68b1 | 649a63e (manifest), puis rapport | OK | clean | OK |

### 4.2 Runtime avant promotion

| Env | Service | Image | Restart |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-dev | inchange |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | inchange |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev | inchange |
| PROD | keybuzz-api | v3.5.187-google-observability-tenantguard-prod | a promouvoir |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | inchange |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod | inchange |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |

### 4.3 KEY-309 verification

```
docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod
=> manifest unknown
```

Tag immuable libre avant push : OK.

---

## 5. BUILD EVIDENCE

Commande :
```
/opt/keybuzz/keybuzz-infra/scripts/build-api-from-git.sh prod v3.5.188-outbound-deliveries-tenantguard-prod ph147.4/source-of-truth
```

Sequence : fresh clone github.com/keybuzzio/keybuzz-api ph147.4/source-of-truth dans /tmp/keybuzz-api-build-$$ ; verif clean ; docker build --no-cache avec ARGs IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION.

KEY-308 OCI labels :

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | 55ab4bd6de48d91746f04e0024a2898f91945c1f (SHA full) |
| org.opencontainers.image.created | 2026-05-14T09:58:40Z |
| org.opencontainers.image.version | v3.5.188-outbound-deliveries-tenantguard-prod |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |

Image locale ID : `sha256:8ade5400cc487412c38b8897a40a37964034251dd80a9a26daedf9eb88ee90bc`.

---

## 6. PUSH DIGEST

Commande :
```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod
```

| Item | Valeur |
|---|---|
| Image | ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod |
| Manifest digest GHCR | sha256:d7a25ce81598211f433ad0ba945a2176d60e0d20ac2aea7d893189ca744d4c1b |
| Manifest size | 2416 |
| Config digest (= image ID local) | sha256:8ade5400cc487412c38b8897a40a37964034251dd80a9a26daedf9eb88ee90bc |

Aucun push d autre tag. KEY-309 respecte (tag unique immuable).

---

## 7. GITOPS EVIDENCE

### 7.1 Manifest patch (1 fichier, +2/-1)

```
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod  # PH-SAAS-T8.12AS.13.1-PROD KEY-313 (2026-05-14) ...
+          # PREVIOUS: v3.5.187-google-observability-tenantguard-prod  # PH-SAAS-T8.12AS.13.1-PROD KEY-313 (2026-05-14)
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod  # PH-SAAS-T8.12AS.13.2A-PROD KEY-313 (2026-05-14): extend tenantGuard to outbound/deliveries (5 endpoints, API-only, no positive mutations) ; rollback: v3.5.187-google-observability-tenantguard-prod ; digest: sha256:d7a25ce8...
```

### 7.2 Commit + push

- Commit : `649a63e deploy(prod): protect outbound deliveries tenant scope (KEY-313)` sur main
- Push : `a8a68b1..649a63e main -> main` push origin main OK
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
| deploy.spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod |
| pod 7zn57 status.containerStatuses[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-prod |
| pod 7zn57 status.containerStatuses[0].imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:d7a25ce81598211f433ad0ba945a2176d60e0d20ac2aea7d893189ca744d4c1b |
| pod final | replicas=1 ready=1 restart=0 |

Identite spec = lastApplied = podImageID = digest GHCR : CONFIRMEE.

---

## 8. VALIDATION NEGATIVE-ONLY PROD

URL : `https://api.keybuzz.io`. UUIDs fictifs `00000000-...-0001`, email `probe@example.invalid`. **Aucun POST positif emis** sur les 3 mutations.

| Test | Endpoint | Headers | Expected | Actual | DB impact | Provider impact | Verdict |
|---|---|---|---|---|---|---|---|
| N1 | GET /outbound/deliveries | aucun | 400 | 400 TENANT_ID_MISSING (module preHandler) | 0 | 0 | OK |
| N2 | GET /outbound/deliveries?tenantId=fake | (rien) | 400/401 missing email | 401 (tenantGuard) | 0 | 0 | OK |
| N3 | GET /outbound/deliveries?tenantId=fake | email=probe@invalid, tenant=fake | 403 not member | 403 | 0 | 0 | OK |
| N4 | GET /outbound/deliveries/:fakeid?tenantId=fake | email=probe@invalid, tenant=fake | 403 | 403 | 0 | 0 | OK |
| N5 | POST /outbound/deliveries/:fakeid/simulate-deliver | aucun | 400 | 400 (module preHandler) | 0 | 0 | OK |
| N6 | POST /outbound/deliveries/:fakeid/simulate-deliver | email=probe@invalid, tenant=fake | 403 | 403 (tenantGuard avant handler) | 0 | 0 | OK |
| N7 | POST /outbound/deliveries/:fakeid/simulate-fail | email=probe@invalid, tenant=fake | 403 | 403 | 0 | 0 | OK |
| N8 | POST /outbound/deliveries/:fakeid/retry (CRITIQUE) | email=probe@invalid, tenant=fake | 403 (no real send) | 403 | 0 | 0 (worker no pickup) | OK |

### 8.1 Preserve sample protections

| Famille | Sample | Verdict attendu | Observe |
|---|---|---|---|
| AS.13.1 google-observability | `GET /outbound-conversions/google-observability` no headers | 400 missing | 400 |
| AS.12.1A messages/conversations | `GET /messages/conversations` fake email + fake tenant | 403 | 403 |

Protections KEY-301 et AS.13.1 PROD preservees apres promotion AS.13.2A.

---

## 9. DB / PROVIDER NO-MUTATION

| Counter outbound_deliveries (PROD) | Avant probes | Apres probes | Delta |
|---|---|---|---|
| total | 246 | 246 | 0 |
| status=queued | 0 | 0 | 0 |
| status=delivered | 245 | 245 | 0 |
| status=failed | 1 | 1 | 0 |
| SUM(attempt_count) | 250 | 250 | 0 |

| Surveillance | Periode | Resultat |
|---|---|---|
| worker outbound PROD logs (pickup/retry/provider/send) | 2 min | 0 ligne correlee aux probes |
| API PROD stdout 5xx | 3 min | 0 ligne 5xx |
| Pod API PROD restart | post-rollout | 0 (nouveau pod, frais) |
| Fake event GA4 / CAPI / TikTok / LinkedIn | n/a | 0 emis |
| Fake outbound conversion / fake delivery / fake retry / fake send | n/a | 0 emis |

Conforme `no fake metrics / no fake events / no fake conversion / no fake provider response`.

---

## 10. LOGS / QA

### 10.1 Logs PROD

- API PROD (5 min post-rollout) : 0 5xx, 0 stacktrace, traffic conforme aux probes.
- Worker outbound PROD : image v3.5.165 inchangee, restartCount inchange, aucun pickup nouveau, aucun appel provider declenche.

### 10.2 QA Ludovic Client PROD

URL : `https://client.keybuzz.io`

Confirmation Ludovic dans la conversation courante :
> "OK : QA Client PROD validee sur https://client.keybuzz.io. Inbox OK, Brouillon IA OK sur les cas attendus, tenant switcher OK, escalation OK, playbooks read-only OK. Aucune regression visible. Aucune action mutationnelle declenchee."

Aucun test outbound UI car aucun consumer HTTP legitime des endpoints `/outbound/deliveries*` n existe (cf AS.13.2 design audit section 5).

---

## 11. PROD SERVICES UNCHANGED

| Service | Namespace | Image avant | Image apres | Action |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.187-google-observability-tenantguard-prod | v3.5.188-outbound-deliveries-tenantguard-prod | apply manifest + rollout |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | aucune |
| keybuzz-client | keybuzz-client-prod | v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff-prod | aucune |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | aucune |

Aucun build PROD autre que API. Aucun docker push autre que API. Aucun kubectl apply autre que `k8s/keybuzz-api-prod/deployment.yaml`. Aucun set/edit/patch.

---

## 12. ROLLBACK

Procedure si regression critique :

1. `cd /opt/keybuzz/keybuzz-infra && git revert 649a63e --no-edit`
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deploy/keybuzz-api -n keybuzz-api-prod --timeout=240s`

Tag de rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod` (stable PROD precedente, presente sur GHCR).

Effet rollback : reouvre temporairement la surface `outbound/deliveries*` non-member en PROD mais restaure le runtime stable AS.13.1-PROD jusqu a correction.

Rollback NON declenche : verdict GO valide.

---

## 13. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans PII, sans secret) :

```
PH-SAAS-T8.12AS.13.2A-R1 PROD livre.

Runtime API PROD : v3.5.188-outbound-deliveries-tenantguard-prod
Digest GHCR : sha256:d7a25ce81598211f433ad0ba945a2176d60e0d20ac2aea7d893189ca744d4c1b
OCI revision : 55ab4bd6de48d91746f04e0024a2898f91945c1f

5 endpoints HTTP /outbound/deliveries* desormais proteges par tenantGuard global (DEV+PROD) :
- GET /outbound/deliveries (list)
- GET /outbound/deliveries/:id (detail)
- POST /outbound/deliveries/:id/simulate-deliver
- POST /outbound/deliveries/:id/simulate-fail
- POST /outbound/deliveries/:id/retry

Probes negative-only PROD : N1 400, N2 401, N3..N4 403, N5 400, N6..N8 403. Aucun POST positif (regle absolue retry = real provider send). DB outbound_deliveries inchange (total/queued/delivered/failed/attempts = 246/0/245/1/250 avant=apres). Worker outbound : 0 pickup, 0 provider call. 0 5xx API PROD 5 min.

Preserve : AS.13.1 google-observability 400 sample, AS.12.1 messages 403 sample. QA Ludovic Client PROD : Inbox, Brouillon IA, switcher, escalation, playbooks read-only sans regression.

Client / Admin v2 / outbound worker PROD strictement inchanges.

KEY-313 reste Open. KEY-301 reste Done.

Next : AS.13.3 compat Amazon (6 endpoints proxy backend) en attente GO Ludovic explicite.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. NEXT AS.13.3 COMPAT AMAZON

| Phase | Scope | Statut |
|---|---|---|
| AS.13.3 design audit | compat /api/v1/marketplaces/amazon/* : 6 endpoints proxy backend (X-Internal-Token, OAuth start/disconnect/send-validation). Decision (a) tenantGuard membership avant proxy ou (b) refactor BFF Client safe pattern partout. Recommande (a) pour scope minimal. | En attente GO Ludovic explicite |
| AS.13.3 IMPL DEV | apres design GO | En attente |
| AS.13.3 PROD | apres DEV OK + GO Ludovic | En attente |
| AS.13.4 destinations confirmatif | 6 endpoints, audit confirmatif `checkAccess` deja en place. Probable 0 patch. | En attente |
| R2.2 defense-in-depth suivi | Ajouter `AND tenant_id = $X` dans les 3 UPDATEs outbound_deliveries | Backlog, hors KEY-313 strict |
| KEY-312 (GP1) | PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 garde-fous metier | Hors scope KEY-313 |

---

## 15. VERDICTS AUTORISES

- GO OUTBOUND DELIVERIES TENANTGUARD PROD READY (verdict retenu)
- NO GO OUTBOUND DELIVERIES PROD ROLLBACK DONE
- NO GO MUTATION RISK DETECTED
- NO GO SOURCE DIRTY / DRIFT

---

## 16. PHRASE CIBLE FINALE

GO OUTBOUND DELIVERIES TENANTGUARD PROD READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.3 sans GO Ludovic explicite.

STOP.
