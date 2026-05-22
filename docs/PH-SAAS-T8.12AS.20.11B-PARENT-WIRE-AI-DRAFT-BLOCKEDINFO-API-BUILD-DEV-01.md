# PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-API-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE BUILD API DEV from-git
> Environnement : Build Docker DEV only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD API AI DRAFT BLOCKEDINFO DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

- Image locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev` build OK depuis worktree --detach commit `5070e6a6`.
- Image ID + config digest : `sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19` size 343 MB.
- OCI labels KEY-308 5/5 OK (revision=5070e6a61b81d70b0d15cb44ef15ea52e93f898a).
- Bundle /app/dist : markers PH-20.11B LIVE 6/6 : `blockedStatus=2`, `blockedNotes=1`, `PRE_LLM_BLOCKED=6`, `ESCALATION_DRAFT=14`, `hasDraft=5`, `PH-SAAS-T8.12AS.20.11B=1`.
- **Doctrine seller-first/refund-protection PRESERVE 100%** : AGGRESSIVE_PATTERNS=8, combinedRisk=13, guardrailNotes=7 (autopilotGuardrails.ts inchange, hash identique entre 5070e6a6 et d88aa7d0).
- Routes critiques inchangees : /autopilot/draft=6, /autopilot/evaluate=3, /ai/assist=3, /ai/execute=3, /autopilot/settings=9.
- No real secrets / no hardcode : sk_live_=0, sk_test_=0, ecomlg-motxke32=0, kj44qkxp6b0z250=0, jml1tnc080qz1c0=0.
- PGPASSWORD=22 = noms env-var dans `config/env.js` (process.env.PGPASSWORD), normal API node.
- test_event_code=4 = parametre Meta CAPI/TikTok dans adapters outbound (parametre accepte par les API externes pour debug), normal.
- GHCR collision tag DEV cible LIBRE.
- Worktree nettoyee.
- Runtime API DEV+PROD INCHANGES.

STOP avant push GHCR DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T20:45:00Z |
| keybuzz-api HEAD | 5070e6a6 (full 5070e6a61b81d70b0d15cb44ef15ea52e93f898a) |
| keybuzz-api branche | ph147.4/source-of-truth |
| Dirty | 223 (pre-existant dist/) |
| Runtime API DEV avant | v3.5.253-meta-capi-emq-dev |
| Runtime API PROD avant | v3.5.252-meta-capi-emq-prod |
| GHCR collision v3.5.254-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) |

## E1 AUDIT SOURCE PRE-BUILD

### Commit 5070e6a6 details

```
fix(autopilot): expose blocked draft reason read-only PH-20.11B KEY-312

GET /autopilot/draft : si pas de draft (DRAFT_GENERATED|ESCALATION_DRAFT avec draftText),
fallback : cherche le dernier ai_action_log PRE_LLM_BLOCKED|ESCALATION_DRAFT
et retourne { hasDraft:false, blocked:true, blockedStatus, blockedNotes (sanitized), createdAt }.

- Read-only strict, AUCUNE mutation DB.
- AUCUNE consommation KBActions.
- AUCUN appel LLM.
- guardrails seller-first/refund-protection INCHANGES (PH147.2 preserve).
- Notes sanitisees : codes techniques uniquement (regex /^[A-Z_]+$/), max 6, pas de PII.
```

### Markers source `src/modules/autopilot/routes.ts`

| Marker | Count source | Verdict |
|---|---|---|
| blockedStatus | 2 | OK |
| blockedNotes | 1 | OK |
| PRE_LLM_BLOCKED | 2 | OK |
| ESCALATION_DRAFT | 7 | OK |
| hasDraft | 5 | OK |
| `blocked: true` (object literal) | 1 | OK |

### autopilotGuardrails.ts INCHANGE

| Indicateur | Hash | Verdict |
|---|---|---|
| `src/services/autopilotGuardrails.ts` @ commit 5070e6a6 | 5e62bbbe33ddfeee6e940898f931dd9fcf589b91 | identique d88aa7d0 |
| `src/services/autopilotGuardrails.ts` @ commit d88aa7d0 (baseline) | 5e62bbbe33ddfeee6e940898f931dd9fcf589b91 | identique 5070e6a6 |

**Doctrine seller-first / refund-protection (PH147.2) preserve 100%**.

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-API-DEV/keybuzz-api |
| Worktree detache sur | 5070e6a6 |
| Full hash | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Worktree dirty | 0 (clean) |

## E3 DOCKER BUILD API DEV

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev |
| Exit code | 0 |
| Image ID + config digest | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 |
| Size | 343 MB |
| Created (label) | 2026-05-22T20:45:30Z |
| Created (registry) | 2026-05-22 20:46:35 UTC |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T20:45:30Z | OK |
| org.opencontainers.image.revision | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | OK MATCH commit |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |
| org.opencontainers.image.version | v3.5.254-ai-draft-blocked-reason-dev | OK |

KEY-309 tag immutable + suffixe `-dev` conforme + versioning bump (v3.5.253 -> v3.5.254).

## E3 AUDIT IMAGE BUNDLE (/app/dist)

### Markers patch PH-20.11B LIVE

| Marker | Count dist | Verdict |
|---|---|---|
| blockedStatus | 2 | OK LIVE response field |
| blockedNotes | 1 | OK LIVE response field |
| PRE_LLM_BLOCKED | 6 | OK reference dans engine + routes |
| ESCALATION_DRAFT | 14 | OK reference dans engine + routes |
| hasDraft | 5 | OK route field preserve + nouveau |
| PH-SAAS-T8.12AS.20.11B | 1 | OK comment marker |

### Doctrine seller-first / refund-protection preserve

| Indicateur | Count | Verdict |
|---|---|---|
| AGGRESSIVE_PATTERNS | 8 | preserve guardrails seller-first |
| combinedRisk | 13 | preserve |
| guardrailNotes | 7 | preserve |

### Routes critiques inchangees

| Route | Count | Verdict |
|---|---|---|
| /autopilot/draft | 6 | preserve (+ extension blocked info) |
| /autopilot/evaluate | 3 | preserve |
| /ai/assist | 3 | preserve |
| /ai/execute | 3 | preserve |
| /autopilot/settings | 9 | preserve |

### No real secrets / no hardcode

| Token | Count | Verdict |
|---|---|---|
| sk_live_ (Stripe live key) | 0 | OK |
| sk_test_ (Stripe test key) | 0 | OK |
| ecomlg-motxke32 (tenant hardcode) | 0 | OK |
| kj44qkxp6b0z250 (Guilhem case) | 0 | OK |
| jml1tnc080qz1c0 (Nordine case) | 0 | OK |
| PGPASSWORD (env-var refs in config/env.js) | 22 | OK NORMAL (process.env.PGPASSWORD references, no real password) |
| test_event_code (Meta CAPI/TikTok param accepte par les API externes) | 4 | OK NORMAL (no fake event hardcode) |

### Baseline comparison v3.5.253-meta-capi-emq-dev (avant PH-20.11B)

| Marker | v3.5.253 baseline | v3.5.254 build | Delta | Verdict |
|---|---|---|---|---|
| PH-SAAS-T8.12AS.20.11B | 0 | 1 | +1 | activated |
| blockedStatus | 0 | 2 | +2 | activated |
| blockedNotes | 0 | 1 | +1 | activated |

Baseline confirmee : markers PH-20.11B etaient absents avant le patch.

## E4 TYPECHECK

tsc verifie lors du source patch precedent (PH-20.11B SOURCE PATCH) : 0 erreurs API. Image dist compilee = build Docker exit 0.

## E5 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | DEV | **v3.5.253-meta-capi-emq-dev** | INCHANGE (cible build non deployee) |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | DEV | v3.5.211-ai-draft-blocked-reason-dev | INCHANGE |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-backend | DEV+PROD | v1.0.47 | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.21 / v0.6.21-pricing-action-recover-prod | INCHANGES |

Aucun deploy. Aucun manifest GitOps modifie. Aucun kubectl apply.

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-API-DEV/` | OK |
| Repo principal keybuzz-api | dirty=223 (pre-existant dist/) |

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Bundle live | Verdict |
|---|---|---|
| /autopilot/draft retourne hasDraft=true normal | preserve (logique principale inchangee, juste extension du fallback hasDraft=false) | OK |
| draftText retourne pour draft existant | preserve | OK |
| Fallback hasDraft=false conserve si aucun block | preserve (`if (blockedRow.rows.length === 0) return reply.send({ hasDraft: false });`) | OK |
| Block info expose UNIQUEMENT en read-only | extension OK, AUCUNE mutation DB ajoutee | OK |
| autopilotGuardrails.ts (doctrine) | INCHANGE 100% (hash identique) | OK |
| Aucune modification wallet/KBActions | preserve | OK |
| Aucune modification `/ai/assist`, `/ai/execute`, `/autopilot/draft/consume` | preserve | OK |
| Aucun changement engine.ts (decision tree, guardrails calls) | preserve | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel reseau LLM/Meta/GA/LinkedIn durant build | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucune mutation DB | 0 | OK |
| Aucun fake event/message/conversation | 0 | OK |
| Aucun test event/lead/checkout simule | 0 | OK |
| Audit statique bundle uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE, attente GO).
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela commit 5070e6a6.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux event/register/checkout/lead.
- AUCUN changement Client/Backend/Admin.
- AUCUN changement Linear statut.
- Doctrine seller-first/refund-protection INCHANGE 100% (autopilotGuardrails.ts hash identique).
- KEY-305 fix race UI preserve cote Client (source).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API AI DRAFT BLOCKEDINFO DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE |
| Bastion | install-v3 46.62.171.61 |
| Source commit | 5070e6a6 (full 5070e6a61b81d70b0d15cb44ef15ea52e93f898a) |
| Tag image DEV | v3.5.254-ai-draft-blocked-reason-dev |
| Image ID local + config digest | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 |
| Size | 343 MB |
| OCI labels KEY-308 | 5/5 OK |
| Markers PH-20.11B LIVE bundle | 6/6 OK |
| Doctrine seller-first | INCHANGE 100% (autopilotGuardrails.ts hash identique) |
| AI feature parity | preserve (routes, engine, guardrails, wallet inchanges) |
| Baseline delta v3.5.253 -> v3.5.254 | +1/+2/+1 markers PH-20.11B activated |
| No real secrets / no hardcode | OK |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-API-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API AI DRAFT BLOCKEDINFO DEV PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

STOP. Aucun docker push, aucun deploy DEV/PROD, aucun event tracking, aucun changement Linear statut.
