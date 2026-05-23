# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-BUILD-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE BUILD API PROD from-git
> Environnement : Build Docker PROD only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod` build OK depuis worktree --detach commit `5070e6a6`.
- Config digest : `sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b` size 343 MB.
- OCI labels KEY-308 5/5 OK (revision=`5070e6a61b81d70b0d15cb44ef15ea52e93f898a`).
- **Markers blockedInfo PH-20.11B LIVE dist** : `blockedStatus=2, blockedNotes=1, PRE_LLM_BLOCKED=6, ESCALATION_DRAFT=14, hasDraft=5`.
- **Routes critiques preserve dist** : `/autopilot/draft=6, /ai/assist=3, /ai/execute=3, /autopilot/settings=12, /autopilot/evaluate=3`.
- **Guardrails / seller-first preserve dist** : `autopilotGuardrails=5, refundProtection=31, COMBINED_RISK_HIGH=1`.
- **Baseline PROD v3.5.252 (avant)** : blockedStatus=0, blockedNotes=0 -> **delta confirme nouveau dans PROD** (parite avec DEV v3.5.254 : 2/1/6).
- No secret / no hardcode tenant : sk_live_=0, sk_test_=0, ecomlg-motxke32=0, kj44qkxp6b0z250=0, SWITAA=0.
- test_event_code=4 : OK (markers GA4 standard du codebase, deja present dans PROD v3.5.252).
- GHCR collision avant build : LIBRE.
- Worktree nettoyee.
- Runtime API/Client PROD+DEV INCHANGES.

STOP avant push GHCR PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T08:20:18Z |
| keybuzz-api HEAD | 5070e6a6 |
| keybuzz-api branche | ph147.4/source-of-truth |
| Dirty avant build | 223 (preexistant non lie au commit cible) |
| Commit cible present | OUI (5070e6a6 fix(autopilot): expose blocked draft reason read-only PH-20.11B KEY-312) |
| GHCR collision v3.5.255-ai-draft-blocked-reason-prod | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Image | Tag | Collision | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api | v3.5.255-ai-draft-blocked-reason-prod | manifest unknown | LIBRE |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-PROD/keybuzz-api |
| Worktree detache sur | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Worktree dirty | 0 (clean) |

## E3 AUDIT SOURCE AVANT BUILD

| Fichier | Marker | Count | Verdict |
|---|---|---|---|
| src/modules/autopilot/routes.ts | blockedStatus | 2 | OK |
| src/modules/autopilot/routes.ts | blockedNotes | 1 | OK |
| src/modules/autopilot/routes.ts | PRE_LLM_BLOCKED | 2 | OK |
| src/modules/autopilot/routes.ts | ESCALATION_DRAFT | 7 | OK |
| src/modules/autopilot/routes.ts | `blocked:` | 1 | OK |
| src/modules/autopilot/routes.ts | hasDraft | 5 | OK |

Source patch PH-20.11B en place dans le worktree. Aucun changement source dans cette phase (build-from-git du commit valide en DEV).

## E4 DOCKER BUILD API PROD

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod |
| Exit code | 0 |
| Image ID + config digest | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b |
| Size | 343 MB |
| Created (label) | 2026-05-23T08:21:53Z |
| Created (registry) | 2026-05-23 08:21:54 UTC |
| Build steps | 32/32 Successfully built |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-23T08:21:53Z | OK |
| org.opencontainers.image.revision | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | OK MATCH commit cible |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |
| org.opencontainers.image.version | v3.5.255-ai-draft-blocked-reason-prod | OK |

## E5 OCI AUDIT LOCAL

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | 14830ddea074 | OK |
| Config digest | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | OK |
| Size | 343 MB | OK |
| OCI revision | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | OK MATCH |
| Tag local | v3.5.255-ai-draft-blocked-reason-prod | OK |

## E6 DIST AUDIT /app/dist

### Markers blockedInfo PH-20.11B LIVE

| Marker | Count v3.5.255-PROD-NEW | Count v3.5.254-DEV baseline | Count v3.5.252-PROD-OLD baseline | Verdict |
|---|---|---|---|---|
| blockedStatus | 2 | 2 | 0 | **NOUVEAU dans PROD (parite DEV)** |
| blockedNotes | 1 | 1 | 0 | **NOUVEAU dans PROD (parite DEV)** |
| PRE_LLM_BLOCKED | 6 | 6 | N/A | OK parite DEV |
| ESCALATION_DRAFT | 14 | N/A | N/A | OK |
| hasDraft | 5 | N/A | N/A | OK |

### Routes critiques preserve dist

| Marker | Count | Verdict |
|---|---|---|
| autopilot/draft | 6 | OK preserve |
| /ai/assist | 3 | OK preserve |
| /ai/execute | 3 | OK preserve |
| autopilot/settings | 12 | OK preserve |
| autopilot/evaluate | 3 | OK preserve |

### Guardrails / seller-first markers preserve

| Marker | Count | Verdict |
|---|---|---|
| autopilotGuardrails | 5 | OK preserve |
| refundProtection | 31 | OK preserve |
| sellerFirst (camelCase) | 0 | normal (la doctrine est implementee via refundProtection + autopilotGuardrails, pas via une fonction nommee sellerFirst) |
| COMBINED_RISK_HIGH | 1 | OK preserve |

### No secret / no hardcode

| Indicateur | Count | Verdict |
|---|---|---|
| sk_live_ | 0 | OK |
| sk_test_ | 0 | OK |
| ecomlg-motxke32 | 0 | OK |
| kj44qkxp6b0z250 | 0 | OK |
| SWITAA (hardcode case user) | 0 | OK |
| test_event_code | 4 | OK markers GA4 standard du codebase (deja present dans v3.5.252) |

## E7 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | PROD | **v3.5.252-meta-capi-emq-prod** | INCHANGE (cible build non deployee) |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-client | DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |

## E8 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-PROD/` | OK |

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Dist v3.5.255 | Verdict |
|---|---|---|
| GET /autopilot/draft preserve drafts normaux | route count=6, hasDraft=5 | OK |
| GET /autopilot/draft expose blockedInfo read-only | blockedStatus=2, blockedNotes=1, PRE_LLM_BLOCKED=6 | **LIVE** |
| /ai/assist preserve | 3 | OK |
| /ai/execute preserve | 3 | OK |
| /autopilot/settings preserve | 12 | OK |
| /autopilot/evaluate preserve | 3 | OK |
| autopilotGuardrails preserve | 5 occurrences | OK |
| refundProtection preserve | 31 occurrences | OK |
| Client contract preserve | API parite v3.5.254-DEV deja LIVE en DEV (QA prouvee dans PH-20.11C-QA-DEV) | OK |
| KBActions billing | preserve (aucun changement dans 5070e6a6) | OK |
| KEY-305 (Client only) | INCHANGE (API ne touche pas cette logique) | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel LLM durant build | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun event marketing | 0 | OK |
| Aucun message marketplace | 0 | OK |
| Audit statique dist uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible LIBRE, attente GO).
- AUCUN deploy DEV/PROD.
- AUCUN kubectl mutation.
- AUCUN restart pod.
- AUCUN patch source au-dela commit 5070e6a6.
- AUCUN changement Client (API only).
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux event/lead/register/checkout.
- AUCUN changement Linear statut.
- Doctrine seller-first INCHANGE 100% (autopilotGuardrails + refundProtection preserves).
- Bastion install-v3 (46.62.171.61) uniquement.

## TABLEAUX FINAUX

### 1. Repo / Git

| Repo | Branche | Commit | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | 0 (worktree clean) | OK |

### 2. Image

| Image | Tag | Digest local | OCI revision | Size | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api | v3.5.255-ai-draft-blocked-reason-prod | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | 343 MB | OK |

### 3. Dist markers

| Marker | Count | Verdict |
|---|---|---|
| **blockedStatus** | **2** | NOUVEAU dans PROD (delta vs v3.5.252=0) |
| **blockedNotes** | **1** | NOUVEAU dans PROD (delta vs v3.5.252=0) |
| PRE_LLM_BLOCKED | 6 | OK parite v3.5.254-DEV |
| ESCALATION_DRAFT | 14 | OK |
| hasDraft | 5 | OK |
| /autopilot/draft | 6 | preserve |
| /ai/assist | 3 | preserve |
| /ai/execute | 3 | preserve |
| /autopilot/settings | 12 | preserve |
| /autopilot/evaluate | 3 | preserve |
| autopilotGuardrails | 5 | preserve |
| refundProtection | 31 | preserve |
| COMBINED_RISK_HIGH | 1 | preserve |
| sk_live_ / sk_test_ / hardcode tenant / SWITAA | 0/0/0/0/0 | OK |

### 4. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| API PROD | v3.5.252 | INCHANGE |
| API DEV | v3.5.254 | INCHANGE LIVE |
| Client PROD | v3.5.201 | INCHANGE |
| Client DEV | v3.5.214 | INCHANGE LIVE |

### 5. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker push | OUI | aucun push commande |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement docker build/get |
| restart pod | OUI | uptime preserve |
| build dirty | OUI | worktree --detach clean |
| build from pod/runtime | OUI | from-git worktree |
| tag latest | OUI | tag immuable v3.5.255-ai-draft-blocked-reason-prod |
| secrets logs | OUI | aucun secret display |
| fake event/metric/KBActions | OUI | 0 |
| appel LLM | OUI | aucun |
| mutation DB | OUI | aucun acces DB |
| modification Client | OUI | aucune image Client touchee |
| changement Linear statut | OUI | comment only |

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L'image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Source commit | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Tag image | v3.5.255-ai-draft-blocked-reason-prod |
| Config digest local | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b |
| Markers blockedInfo dist | 2/1/6/14/5 (NEW dans PROD vs v3.5.252=0/0) |
| Routes critiques preserve | 6/3/3/12/3 |
| Guardrails preserve | 5/31/1 |
| No secret / no hardcode | 0/0/0/0/0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime API/Client DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API AI DRAFT BLOCKEDINFO PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun docker push, aucun deploy, aucun changement Linear statut.
