# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-APPLY-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE APPLY API PROD GitOps strict
> Environnement : PROD API only (Client PROD inchange)

## VERDICT

GO APPLY API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Manifest `k8s/keybuzz-api-prod/deployment.yaml` bumpe v3.5.252 -> v3.5.255-ai-draft-blocked-reason-prod.
- Infra commit manifest `2254c8d` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-api" successfully rolled out`.
- Pod nouveau unique **`keybuzz-api-56bff5c9c5-qv4jd`** Ready 1/1, 0 restart.
- Runtime digest API PROD : `sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf` MATCH GHCR manifest digest.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- /health HTTP 200 `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}`.
- Startup OK : "Server listening at http://0.0.0.0:3001".
- **Dist runtime markers blockedInfo LIVE** : `blockedStatus=2, blockedNotes=1, PRE_LLM_BLOCKED=6, ESCALATION_DRAFT=14, hasDraft=5`.
- Routes critiques preserve : `autopilot/draft=6, /ai/assist=3, /ai/execute=3, autopilot/settings=12, autopilot/evaluate=3`.
- Guardrails preserve : `autopilotGuardrails=5, refundProtection=31, COMBINED_RISK_HIGH=1`.
- No secret / no hardcode 0/5.
- Logs API PROD : 0 TypeError, 0 ReferenceError, 0 HTTP 500, 0 HTTP 503, 0 unhandled, 0 database error.
- Runtime Client PROD `v3.5.201-register-polish-prod` INCHANGE.
- Runtime API DEV `v3.5.254` INCHANGE LIVE.
- Runtime Client DEV `v3.5.214` INCHANGE LIVE.

**API PROD est maintenant pret a servir blockedInfo aux Clients PROD. L'ancien Client PROD v3.5.201 ne consomme pas encore blockedInfo (compat ascendante).**

STOP avant QA API PROD + promotion Client PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T09:25:24Z |
| kube-context | kubernetes-admin@kubernetes |
| keybuzz-infra HEAD avant | f511bbb |
| keybuzz-infra HEAD apres bump | **2254c8d** |
| Runtime API PROD avant | v3.5.252-meta-capi-emq-prod |
| Runtime Client PROD avant | v3.5.201-register-polish-prod |

## E1 GHCR DIGEST VERIFY

| Item | Valeur | Verdict |
|---|---|---|
| Image GHCR | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod | OK |
| Config digest | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | OK MATCH expected |
| Manifest digest | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | OK MATCH expected |
| OCI revision | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | OK |

## E2 BUMP MANIFEST GITOPS

| Item | Valeur |
|---|---|
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image apres bump | `image: ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod` + annotation PH-20.11C-GUARDRAIL-GUIDANCE-API-APPLY-PROD avec KEY-312/235/231, commit 5070e6a6, parite DEV PH-20.11C-QA-DEV (9cedc19), manifest digest GHCR, rollback |
| Dry-run server | `deployment.apps/keybuzz-api configured (server dry run)` |
| Commit infra | `2254c8d` chore(api): deploy PH-20.11C blockedInfo PROD |
| Push | OK f511bbb..2254c8d main -> main |

## E3 APPLY PROD + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | `deployment.apps/keybuzz-api configured` |
| Rollout status | `deployment "keybuzz-api" successfully rolled out` |
| Pod nouveau unique | **keybuzz-api-56bff5c9c5-qv4jd** Ready 1/1, 0 restart |
| Replicas spec | 1 |
| Replicas ready | 1 |

### Triple match API PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | OK MATCH GHCR |

## E5 SMOKE API PROD

| Endpoint | HTTP | Bytes | Verdict |
|---|---|---|---|
| /health | 200 | 96 | OK `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |

Aucun appel /ai/assist, /ai/execute, /autopilot/draft/consume durant cette phase.

## E6 DIST RUNTIME AUDIT API PROD

### Markers blockedInfo PH-20.11B LIVE

| Marker | Count | Verdict |
|---|---|---|
| blockedStatus | 2 | **LIVE NOUVEAU** |
| blockedNotes | 1 | **LIVE NOUVEAU** |
| PRE_LLM_BLOCKED | 6 | LIVE |
| ESCALATION_DRAFT | 14 | LIVE |
| hasDraft | 5 | LIVE |

### Routes critiques preserve

| Marker | Count | Verdict |
|---|---|---|
| autopilot/draft | 6 | preserve |
| /ai/assist | 3 | preserve |
| /ai/execute | 3 | preserve |
| autopilot/settings | 12 | preserve |
| autopilot/evaluate | 3 | preserve |

### Guardrails preserve

| Marker | Count | Verdict |
|---|---|---|
| autopilotGuardrails | 5 | preserve |
| refundProtection | 31 | preserve |
| COMBINED_RISK_HIGH | 1 | preserve |

### No secret / no hardcode

| Indicateur | Count | Verdict |
|---|---|---|
| sk_live_ / sk_test_ | 0/0 | OK |
| ecomlg-motxke32 / kj44qkxp6b0z250 / SWITAA | 0/0/0 | OK |

## E7 LOGS API PROD

| Pattern | Count | Verdict |
|---|---|---|
| TypeError | 0 | OK |
| ReferenceError | 0 | OK |
| HTTP 500 | 0 | OK |
| HTTP 503 | 0 | OK |
| Unhandled | 0 | OK |
| database error | 0 | OK |
| Startup | "Server listening at http://0.0.0.0:3001" | OK |

## E8 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | PROD | **v3.5.255-ai-draft-blocked-reason-prod** | **NOUVEAU LIVE (cible deployee)** |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-client | DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat runtime PROD | Verdict |
|---|---|---|
| GET /autopilot/draft preserve drafts normaux | route count=6, hasDraft=5 | OK |
| GET /autopilot/draft expose blockedInfo read-only | blockedStatus=2, blockedNotes=1 LIVE | **LIVE** |
| /ai/assist preserve | 3 | OK |
| /ai/execute preserve | 3 | OK |
| /autopilot/settings preserve | 12 | OK |
| /autopilot/evaluate preserve | 3 | OK |
| Autopilot engine preserve | (engine.ts non touche par 5070e6a6) | OK |
| autopilotGuardrails preserve | 5 occurrences | OK |
| refundProtection preserve | 31 occurrences | OK |
| KBActions billing | preserve (aucun changement dans 5070e6a6) | OK |
| Client PROD ancien v3.5.201 contract compat | API ajoute blockedInfo en extension de la reponse ; le Client v3.5.201 ignore les champs inconnus -> compat ascendante | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun appel `/ai/assist` runtime | 0 logs | OK |
| Aucun appel `/ai/execute` runtime | 0 logs | OK |
| Aucun appel `/autopilot/draft/consume` runtime | 0 logs | OK |
| Aucun message marketplace envoye | 0 (rollout only) | OK |
| Aucun event marketing genere | 0 (rollout only) | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun LLM call | 0 | OK |
| Aucune mutation DB hors rollout K8s normal | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy Client PROD (Client PROD INCHANGE v3.5.201).
- AUCUN restart pod hors rollout normal.
- AUCUN kubectl set/patch/edit (GitOps strict apply -f).
- AUCUN changement Backend/Website/Admin.
- AUCUN changement source au-dela commit 5070e6a6.
- AUCUN faux event / register / checkout / lead.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100% (autopilotGuardrails=5 + refundProtection=31 preserves).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PROD DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/keybuzz-api-prod/deployment.yaml -> image v3.5.252-meta-capi-emq-prod
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "ops(api-prod): ROLLBACK PH-20.11C to v3.5.252"
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=300s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Services

| Service | Avant | Apres | Verdict |
|---|---|---|---|
| API PROD | v3.5.252-meta-capi-emq-prod | **v3.5.255-ai-draft-blocked-reason-prod** | OK NOUVEAU LIVE |
| API DEV | v3.5.254 | inchange | OK LIVE |
| Client PROD | v3.5.201 | inchange | OK |
| Client DEV | v3.5.214 | inchange | OK LIVE |

### 2. Manifest + Apply

| Manifest | Commit | Apply | Rollout | Verdict |
|---|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | 2254c8d | OK | successfully rolled out | OK |

### 3. Pod / Digest

| Pod | Digest runtime | Digest GHCR | Match | Verdict |
|---|---|---|---|---|
| keybuzz-api-56bff5c9c5-qv4jd | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | OK | MATCH |

### 4. Dist markers

| Marker | Count | Verdict |
|---|---|---|
| **blockedStatus** | 2 | LIVE NOUVEAU |
| **blockedNotes** | 1 | LIVE NOUVEAU |
| PRE_LLM_BLOCKED | 6 | LIVE |
| ESCALATION_DRAFT | 14 | LIVE |
| hasDraft | 5 | LIVE |
| autopilot/draft | 6 | preserve |
| /ai/assist | 3 | preserve |
| /ai/execute | 3 | preserve |
| autopilot/settings | 12 | preserve |
| autopilot/evaluate | 3 | preserve |
| autopilotGuardrails | 5 | preserve |
| refundProtection | 31 | preserve |
| COMBINED_RISK_HIGH | 1 | preserve |
| No secret / no hardcode | 0 | OK |

### 5. Logs

| Pattern | Count | Verdict |
|---|---|---|
| TypeError / ReferenceError / HTTP 500 / HTTP 503 / Unhandled / database err | 0/0/0/0/0/0 | OK |
| Startup "Server listening at http://0.0.0.0:3001" | OK | OK |
| /health HTTP 200 | OK | OK |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucun build/push run |
| deploy Client PROD | OUI | runtime Client PROD inchange v3.5.201 |
| kubectl set/patch/edit/delete | OUI | uniquement apply -f + get + rollout status |
| restart pod manuel | OUI | rollout normal |
| LLM call / /ai/assist / /draft/consume | OUI | 0 logs |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB hors rollout | OUI | aucun |
| changement Linear statut | OUI | comment only |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **GO APPLY API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE** |
| Bastion | install-v3 46.62.171.61 |
| Source commit API | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Image runtime PROD | v3.5.255-ai-draft-blocked-reason-prod |
| Runtime digest PROD | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf |
| Pod PROD | 56bff5c9c5-qv4jd Ready 1/1 0 restart |
| Triple match | OK |
| Commit infra manifest | 2254c8d push origin/main |
| /health | HTTP 200 |
| Dist blockedInfo LIVE | OK (2/1/6/14/5) |
| Routes critiques preserve | 6/3/3/12/3 |
| Guardrails preserve | 5/31/1 |
| AI feature parity | preserve |
| Logs PROD | 0 erreur, Server listening OK |
| Runtime Client PROD | INCHANGE v3.5.201 |
| Runtime API DEV / Client DEV | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-APPLY-PROD-01.md` |

### Prochaine phrase GO attendue

`GO QA API AI DRAFT BLOCKEDINFO PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

(QA API PROD : probe GET /autopilot/draft sur conv reelle PRE_LLM_BLOCKED PROD, validation contract blockedInfo, control draft normal, no LLM/no KBActions, no message ; puis sequence Client PROD build/push/apply/QA)

STOP. Aucun changement Client PROD, aucun changement Linear statut.
