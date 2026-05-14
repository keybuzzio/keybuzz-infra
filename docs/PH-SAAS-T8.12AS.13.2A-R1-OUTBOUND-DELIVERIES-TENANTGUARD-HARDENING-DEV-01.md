# PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-DEV-01
> Environnement : DEV (API uniquement). PROD strictement inchangee.

---

## 1. VERDICT

GO OUTBOUND DELIVERIES TENANTGUARD DEV READY

Les 5 endpoints HTTP `/outbound/deliveries*` sont desormais proteges par tenantGuard global en DEV via `ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-dev` (digest GHCR `sha256:3f7d7629d4b613b5a79d0d7f6145113db3405d3009863dc2b6bf3795f4581a20`, OCI revision `55ab4bd6de48d91746f04e0024a2898f91945c1f`). Probes negative-only confirment :
- sans headers => 400 (module preHandler local conserve) ;
- avec tenantId mais sans x-user-email => 401 (tenantGuard membership check) ;
- avec email + tenantId fake, non-member => 403 sur les 5 endpoints incluant les 3 mutations ;
- aucun POST positif emis, aucun pickup worker outbound, aucun appel provider externe.

DB outbound_deliveries (total/queued/delivered/failed/attempts) = 306/0/264/42/463 identique avant=apres probes. AS.13.1 google-observability et AS.12.1 messages/conversations protections preservees (samples 400/403). 0 5xx API DEV. PROD strictement inchangee. QA navigateur Ludovic confirmee sur Client DEV (Inbox, Brouillon IA, switcher, escalation, playbooks). KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface protegee | API HTTP `/outbound/deliveries*` (5 endpoints) |
| Module patch | `keybuzz-api/src/plugins/tenantGuard.ts` (+52 lignes, 2 matchers dynamiques + 2 lignes isProtected) |
| Handler outbound | `keybuzz-api/src/modules/outbound/routes.ts` (INCHANGE, le preHandler local tenantId-only est conserve mais devient redondant) |
| Hors scope strict | Client, Admin v2, Backend/worker, autres modules outbound-conversions, AS.13.3 compat, AS.13.4 destinations, R2.2 defense-in-depth UPDATE WHERE tenant_id |

---

## 3. SOURCES

- PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01.md (audit + design)
- PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md (R1 precedent)
- PH-SAAS-T8.12AS.12.3A-KEY-301-LINEAR-CLOSEOUT-01.md (parent KEY-301)
- Linear KEY-313

---

## 4. PREFLIGHT

| Repo | Path | Branche | HEAD avant | HEAD apres | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 1c8b6b18 | 55ab4bd6 | OK | dist/ deleted en worktree (cosmetique) | OK build-from-git |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 4626eac | cccffb5 (manifest), 5ce0d22 puis docs | OK | clean | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | inchange | inchange | OK | read-only | non touche |

Runtime avant promotion :

| Env | Service | Image | Restart |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.187-google-observability-tenantguard-dev | 1/1 ready |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | 1/1 ready |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev | 1/1 ready |
| PROD | keybuzz-api | v3.5.187-google-observability-tenantguard-prod | inchange |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod | inchange |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |

KEY-309 tag DEV `v3.5.188-outbound-deliveries-tenantguard-dev` : `manifest unknown` avant push (libre).

---

## 5. PATCH SOURCE

Fichier : `keybuzz-api/src/plugins/tenantGuard.ts`

Ajout de 2 fonctions matcher (squelette decrit en AS.13.2 design, applique tel quel) :

- `isOutboundDeliveriesGet(method, path)` : matche `GET /outbound/deliveries` (list) et `GET /outbound/deliveries/:id` (detail, 1 segment, pas de sous-path). Exclut les 3 mutations.
- `isOutboundDeliveryAction(method, path)` : matche `POST /outbound/deliveries/:id/{simulate-deliver,simulate-fail,retry}` (action en liste blanche litterale, refuse toute autre forme).

Wiring : 2 nouvelles lignes dans `isProtected(method, path)` apres `isPlaybookSuggestionActionPatch`.

Aucune modification de `outbound/routes.ts`, aucun hardcode tenant/email, aucun lien Client/Admin v2. Le preHandler local du module est laisse en place (verifie tenantId only, redondant avec tenantGuard mais ne casse rien).

Diff observable :
```
src/plugins/tenantGuard.ts | 52 ++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 52 insertions(+)
```

Commit + push :

| Commit | Message | Repo | Push |
|---|---|---|---|
| 55ab4bd6 | feat(security): protect outbound deliveries via tenantGuard (KEY-313) | keybuzz-api ph147.4/source-of-truth | 1c8b6b18..55ab4bd6 |

Verifications source :
- 5 endpoints `/outbound/deliveries*` couverts (isOutboundDeliveriesGet : 2 GET ; isOutboundDeliveryAction : 3 POST).
- AS.13.1 `/outbound-conversions/google-observability` non capture par les nouveaux matchers (prefix different).
- AS.12 `/messages/conversations*`, `/notifications*`, `/autopilot/*`, `/ai/*`, `/playbooks/*` non captures.
- Aucun hardcode tenant id, user id, email, seller, marketplace, order, tracking, URL.

---

## 6. BUILD EVIDENCE

Commande :
```
/opt/keybuzz/keybuzz-infra/scripts/build-api-from-git.sh dev v3.5.188-outbound-deliveries-tenantguard-dev ph147.4/source-of-truth
```

Sequence : fresh clone github.com/keybuzzio/keybuzz-api ph147.4/source-of-truth dans /tmp/keybuzz-api-build-$$ ; verif clean ; docker build --no-cache avec ARGs IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION.

KEY-308 OCI labels :

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | 55ab4bd6de48d91746f04e0024a2898f91945c1f (SHA full) |
| org.opencontainers.image.created | 2026-05-14T09:20:13Z |
| org.opencontainers.image.version | v3.5.188-outbound-deliveries-tenantguard-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |

Image locale ID : `sha256:3756a1e14a07...`. Push GHCR : digest `sha256:3f7d7629d4b613b5a79d0d7f6145113db3405d3009863dc2b6bf3795f4581a20`, size 2416.

---

## 7. GITOPS EVIDENCE

Manifest patch (1 fichier, +2/-1) :
```
        -        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-dev  # ... rollback: v3.5.186-...
        +        # PREVIOUS: v3.5.187-google-observability-tenantguard-dev  # PH-SAAS-T8.12AS.13.1 KEY-313 (2026-05-14)
        +        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-dev  # PH-SAAS-T8.12AS.13.2A KEY-313 (2026-05-14): extend tenantGuard to outbound/deliveries (5 endpoints, API-only, no positive mutations) ; rollback: v3.5.187-google-observability-tenantguard-dev ; digest: sha256:3f7d7629...
```

Commit + push + apply :

| Item | Valeur |
|---|---|
| Commit manifest | cccffb5 deploy(dev): protect outbound deliveries tenant scope (KEY-313) |
| Push | 4626eac..cccffb5 main -> main |
| kubectl apply | deployment.apps/keybuzz-api configured |
| rollout status (240s) | deployment "keybuzz-api" successfully rolled out |
| spec image | ghcr.io/keybuzzio/keybuzz-api:v3.5.188-outbound-deliveries-tenantguard-dev |
| pod new (keybuzz-api-7b8bb48744-kmsn5) imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:3f7d7629d4b613b5a79d0d7f6145113db3405d3009863dc2b6bf3795f4581a20 |
| spec = lastApplied = podImageID = digest GHCR | CONFIRME |
| Client DEV | inchange (v3.5.196-ai-rules-bff-dev) |

---

## 8. VALIDATION NEGATIVE-ONLY DEV

Toutes les requetes envoyees a `https://api-dev.keybuzz.io`. UUIDs fictifs (`00000000-...-0001`), email `probe@example.invalid`. Aucun POST positif vers les 3 mutations.

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

Lecture : tenantGuard global intercepte avant le handler module. Les rejets pre-handler (400/401/403) ne touchent ni la DB ni le worker. Le retry endpoint (le plus sensible) est ferme sans declencher de queueing.

### 8.1 Preserve sample protections

| Famille | Sample | Verdict attendu | Observe |
|---|---|---|---|
| AS.13.1 google-observability | `GET /outbound-conversions/google-observability` no headers | 400 missing | 400 |
| AS.12.1A messages/conversations | `GET /messages/conversations?tenantId=fake` fake email + fake tenant | 403 | 403 |

Aucune regression dans les protections KEY-301/AS.13.1.

---

## 9. DB / PROVIDER NO-MUTATION

| Counter outbound_deliveries (DEV) | Avant probes | Apres probes | Delta |
|---|---|---|---|
| total | 306 | 306 | 0 |
| status=queued | 0 | 0 | 0 |
| status=delivered | 264 | 264 | 0 |
| status=failed | 42 | 42 | 0 |
| SUM(attempt_count) | 463 | 463 | 0 |

| Surveillance | Periode | Resultat |
|---|---|---|
| worker outbound logs (pickup/retry/provider/send) | 2 min | 0 ligne correlee aux probes |
| API DEV stdout 5xx | 3 min | 0 ligne 5xx |
| Pod API DEV restart | rollout | 0 (nouveau pod, frais) |
| Fake event GA4 / CAPI / TikTok / LinkedIn | n/a | 0 emis |
| Fake outbound conversion / fake delivery / fake retry / fake send | n/a | 0 emis |

Conforme `no fake metrics / no fake events / no fake conversion / no fake provider response`.

---

## 10. LOGS / QA

### 10.1 Logs DEV

- API DEV (5 min post-rollout) : 0 5xx, 0 stacktrace, traffic conforme aux probes.
- Worker outbound DEV : restart=0 (image v3.5.165 inchangee), aucun pickup nouveau, aucun appel provider declenche.

### 10.2 QA Ludovic DEV navigateur

URL : `https://client-dev.keybuzz.io`

Confirmation Ludovic dans la conversation courante :
> "OK : QA DEV validee sur https://client-dev.keybuzz.io. Inbox OK, Brouillon IA OK sur les cas attendus, tenant switcher OK, escalation OK, playbooks read-only OK. Aucune regression visible. Aucune mutation declenchee."

Aucun test outbound UI car aucun consumer HTTP legitime des endpoints `/outbound/deliveries*` n existe (cf AS.13.2 design audit section 5).

---

## 11. PROD UNCHANGED

| Service | Namespace | Image PROD | Action effectuee |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.187-google-observability-tenantguard-prod | aucune |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | aucune |
| keybuzz-client | keybuzz-client-prod | v3.5.196-ai-rules-bff-prod | aucune |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | aucune |

Aucun build PROD, aucun docker push PROD, aucun kubectl apply PROD, aucun set/edit/patch PROD. PROD strictement read-only pour cette phase.

---

## 12. ROLLBACK

Procedure DEV en cas de regression decouverte :

1. `cd /opt/keybuzz/keybuzz-infra && git revert cccffb5 --no-edit`
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`
4. `kubectl rollout status deploy/keybuzz-api -n keybuzz-api-dev --timeout=240s`

Tag de rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-dev` (image stable DEV precedente, present sur GHCR).

Effet rollback : restaure la faille `outbound/deliveries*` non-member en DEV uniquement. Aucun impact PROD (deja sur v3.5.187).

Rollback NON declenche : verdict GO valide.

---

## 13. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans PII, sans secret) :

```
PH-SAAS-T8.12AS.13.2A-R1 DEV livre.

Runtime API DEV : v3.5.188-outbound-deliveries-tenantguard-dev
Digest GHCR : sha256:3f7d7629d4b613b5a79d0d7f6145113db3405d3009863dc2b6bf3795f4581a20
OCI revision : 55ab4bd6de48d91746f04e0024a2898f91945c1f

5 endpoints HTTP /outbound/deliveries* desormais proteges par tenantGuard global :
- GET /outbound/deliveries (list)
- GET /outbound/deliveries/:id (detail)
- POST /outbound/deliveries/:id/simulate-deliver
- POST /outbound/deliveries/:id/simulate-fail
- POST /outbound/deliveries/:id/retry

Probes negative-only DEV : N1 400, N2 401, N3..N4 403, N5 400, N6..N8 403. Aucun POST positif (regle absolue retry = real provider send). DB outbound_deliveries inchange (total/queued/delivered/failed/attempts = 306/0/264/42/463 avant=apres). Worker outbound : 0 pickup, 0 provider call. 0 5xx API DEV 5 min.

Preserve : AS.13.1 google-observability 400 sample, AS.12.1 messages 403 sample. QA Ludovic Client DEV : Inbox, Brouillon IA, switcher, escalation, playbooks read-only sans regression.

PROD strictement inchangee. Aucun build/push/apply PROD. KEY-313 reste Open. KEY-301 reste Done.

Next : AS.13.2A-PROD (promotion API PROD) en attente GO Ludovic explicite. Suivi backlog : R2.2 defense-in-depth (ajouter AND tenant_id dans les 3 UPDATEs outbound_deliveries).

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 14. GAPS R2.2 / NEXT PROD

| Phase | Scope | Statut |
|---|---|---|
| AS.13.2A-PROD | build API PROD v3.5.188-outbound-deliveries-tenantguard-prod + push + GitOps PROD apply + validation negative-only + DB snapshot + QA Ludovic | En attente GO Ludovic explicite |
| AS.13.3 compat Amazon | 6 endpoints proxy backend (X-Internal-Token) | Apres AS.13.2A-PROD |
| AS.13.4 destinations confirmatif | 6 endpoints, audit confirmatif `checkAccess` | Apres AS.13.3 |
| R2.2 defense-in-depth | Ajouter `AND tenant_id = $X` dans les 3 UPDATEs `outbound_deliveries` (simulate-deliver, simulate-fail, retry) | Backlog suivi, hors KEY-313 strict |
| KEY-312 (GP1) | PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 garde-fous metier | Hors scope KEY-313 |

---

## 15. VERDICTS AUTORISES

- GO OUTBOUND DELIVERIES TENANTGUARD DEV READY (verdict retenu)
- NO GO OUTBOUND DELIVERIES REGRESSION ROLLBACK DONE
- NO GO MUTATION RISK DETECTED
- NO GO SOURCE DIRTY / DRIFT

---

## 16. PHRASE CIBLE FINALE

GO OUTBOUND DELIVERIES TENANTGUARD DEV READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.2A-PROD sans GO Ludovic explicite.

STOP.
