# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 / KEY-231 / KEY-305 (related) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE BUILD Client PROD from-git
> Environnement : Build Docker PROD only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod` build OK depuis worktree --detach commit `1a30ad9`.
- Config digest : `sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1` size 280 MB.
- OCI labels KEY-308 5/5 OK (revision=`1a30ad925fed3fb0b237e7b82694c2f839bc0778`).
- **KEY-263 PROD isolation STRICT** : `api.keybuzz.io PROD=87, api-dev.keybuzz.io DEV=0`.
- **GUIDANCE PH-20.11C LIVE bundle 7/7** : Trame=2, Point depart=2, sans generation IA=2, consommation KBActions=2, ne peux pas confirmer=2, remboursement remplacement=2, Copier la trame=4.
- **AutoOpen PH-20.11B preserve** : pattern compile `.draftText)||(null==S?void 0:S.blocked` PRESENT + blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque=2, Validation humaine=2.
- AI feature parity preserve : Brouillon IA=6, Suggestion IA=4, Aide IA=10.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- No fake events / no secrets / no hardcode : 0/0/0/0/0/0/0.
- **Baseline v3.5.201-PROD-OLD** : Trame=0, Copier la trame=0 -> NOUVEAU dans PROD confirme.
- **Baseline v3.5.214-DEV** : 2/4 parite (le bundle PROD a meme guidance que DEV mais endpoint different).
- GHCR collision LIBRE.
- Worktree nettoyee.
- Runtime DEV+PROD INCHANGES.

STOP avant push GHCR PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T10:18:42Z |
| keybuzz-client HEAD | 1a30ad9 |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| Dirty avant build | 1 (tsconfig.tsbuildinfo cache pre-existant, non lie) |
| Commit cible present | OUI |
| GHCR collision v3.5.215-ai-draft-blocked-reason-prod | manifest unknown (LIBRE) |

### Runtime baseline

| Service | Runtime actuel | Verdict |
|---|---|---|
| API PROD | v3.5.255-ai-draft-blocked-reason-prod | LIVE PH-20.11C |
| Client PROD | v3.5.201-register-polish-prod | INCHANGE (cible build) |
| API DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| Client DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |

## E1 GHCR COLLISION

| Image | Tag | Collision | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.215-ai-draft-blocked-reason-prod | manifest unknown | LIBRE |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PROD/keybuzz-client |
| Worktree detache sur | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Worktree dirty | 0 (clean) |

## E3 BUILD ARGS PROD KEY-302

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | **production** | OK |
| NEXT_PUBLIC_API_URL | **https://api.keybuzz.io** | OK PROD |
| NEXT_PUBLIC_API_BASE_URL | **https://api.keybuzz.io** | OK PROD |
| GIT_COMMIT_SHA | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |
| BUILD_TIME | 2026-05-23T10:19:05Z | OK |

## E4 DOCKER BUILD CLIENT PROD

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod |
| Exit code | 0 |
| Image ID + config digest | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 |
| Size | 280 MB |
| Created (label) | 2026-05-23T10:19:05Z |
| Created (registry) | 2026-05-23 10:22:00 UTC |
| Build steps | 67/67 Successfully built |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-23T10:19:05Z | OK |
| org.opencontainers.image.revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK MATCH commit cible |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |
| org.opencontainers.image.version | v3.5.215-ai-draft-blocked-reason-prod | OK |

## E5 OCI AUDIT LOCAL

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | 38474f0835c1 | OK |
| Config digest | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | OK |
| Size | 280 MB | OK |
| OCI revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK MATCH |
| Tag local | v3.5.215-ai-draft-blocked-reason-prod | OK |

## E6 BUNDLE AUDIT /app/.next

### Markers GUIDANCE PH-20.11C LIVE

| Marker | Count v3.5.215 PROD | Count v3.5.214 DEV | Count v3.5.201 PROD-OLD | Verdict |
|---|---|---|---|---|
| Trame de reponse securisee | 2 | 2 | 0 | **NOUVEAU dans PROD** |
| Point de depart humain | 2 | (parite) | NA | LIVE |
| sans generation IA | 2 | (parite) | NA | LIVE |
| consommation de KBActions | 2 | (parite) | NA | LIVE |
| ne peux pas confirmer immediatement | 2 | (parite) | NA | LIVE |
| remboursement ou un remplacement avant verification | 2 | (parite) | NA | LIVE |
| Copier la trame | 4 | 4 | 0 | **NOUVEAU dans PROD** |

### Pattern compile AutoOpen PH-20.11B LIVE

```
.draftText)||(null==S?void 0:S.blocked
```

PRESENT runtime bundle PROD -> drawer s'ouvre auto pour blocked.

### Markers AutoOpen + parent-wire PH-20.11B preserve

| Marker | Count | Verdict |
|---|---|---|
| blockedInfo | 4 | preserve |
| Garde-fou actif | 2 | preserve |
| Brouillon IA bloque par securite | 2 | preserve |
| Validation humaine recommandee | 2 | preserve |

### AI feature parity preserve

| Marker | Count | Verdict |
|---|---|---|
| Brouillon IA | 6 | preserve |
| Suggestion IA | 4 | preserve |
| Aide IA | 10 | preserve |

### KEY-263 PROD isolation STRICT

| Indicateur | Count | Verdict |
|---|---|---|
| **api.keybuzz.io PROD pattern** | **87** | OK PROD endpoint LIVE |
| **api-dev.keybuzz.io DEV pattern** | **0** | OK isolation strict (PROD ne pointe PAS vers DEV) |

Baseline comparison :
- v3.5.214-DEV : api-dev=87 (DEV pointe vers DEV)
- v3.5.201-PROD-OLD : api.keybuzz.io PROD=87 (PROD pointe vers PROD)
- v3.5.215-PROD-NEW : api.keybuzz.io PROD=87, api-dev=0 (PROD pointe vers PROD, parite v3.5.201)

### KEY-302 sentinel + no fake/secret/hardcode

| Indicateur | Count | Verdict |
|---|---|---|
| `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | OK |
| test_event_code | 0 | OK |
| ecomlg-motxke32 / kj44qkxp6b0z250 / SWITAA | 0/0/0 | OK |
| sk_live_ / sk_test_ | 0/0 | OK |

## E7 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | PROD | **v3.5.201-register-polish-prod** | INCHANGE (cible build non deployee) |
| keybuzz-api | PROD | v3.5.255-ai-draft-blocked-reason-prod | INCHANGE LIVE PH-20.11C |
| keybuzz-client | DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |

## E8 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PROD/` | OK |

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Bundle v3.5.215 PROD | Verdict |
|---|---|---|
| Brouillon IA normal (DRAFT_GENERATED) | preserve | OK |
| Brouillon IA blockedInfo auto-open PH-20.11B | pattern compile LIVE + 4/2/2/2 | preserve |
| **Trame de reponse securisee PH-20.11C** | LIVE 7/7 markers | **enrichissement** |
| Copier la trame (clipboard local) | 4 occurrences LIVE | LIVE |
| Suggestion IA | 4 | preserve |
| Aide IA | 10 | preserve |
| Doctrine seller-first (autopilotGuardrails.ts non touche) | INCHANGE 100% | preserve |
| KBActions billing | INCHANGE | preserve |
| KEY-305 race fix (`es.current!==d`) | preserve dans compile | OK |
| KEY-263 PROD isolation | OK (87/0) | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel LLM | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun event marketing | 0 | OK |
| Aucun message marketplace | 0 | OK |
| Audit statique bundle uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl mutation.
- AUCUN restart pod.
- AUCUN patch source au-dela commit 1a30ad9.
- AUCUN changement API.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux event/lead/register/checkout.
- AUCUN changement Linear statut.
- KEY-302 sentinel 0.
- KEY-263 isolation PROD/DEV respectee STRICT.
- KEY-305 fix race preserve dans bundle compile.
- Doctrine seller-first INCHANGE 100%.
- Bastion install-v3 (46.62.171.61) uniquement.

## TABLEAUX FINAUX

### 1. Repo / Git

| Repo | Branche | Commit | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | 0 (worktree clean) | OK |

### 2. Image

| Image | Tag | Digest local | OCI revision | Size | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.215-ai-draft-blocked-reason-prod | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | 280 MB | OK |

### 3. Build args PROD

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | production | OK |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io | OK PROD |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | OK PROD |
| GIT_COMMIT_SHA | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| **GUIDANCE PH-20.11C (Trame/Point depart/sans IA/consommation KBActions/ne peux pas confirmer/remboursement remplacement/Copier la trame)** | **2/2/2/2/2/2/4** | LIVE NOUVEAU PROD (delta vs v3.5.201=0/0) |
| Pattern compile autoOpen `draftText \|\| blocked` | PRESENT | LIVE preserve |
| blockedInfo / Garde-fou actif / Brouillon IA bloque / Validation humaine | 4/2/2/2 | preserve |
| Brouillon IA / Suggestion IA / Aide IA | 6/4/10 | preserve |
| api.keybuzz.io PROD / api-dev.keybuzz.io DEV | 87/0 | KEY-263 STRICT |
| KEY-302 sentinel | 0 | OK |
| No fake events / secrets / hardcode | 0 | OK |

### 5. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client PROD | v3.5.201 | INCHANGE |
| API PROD | v3.5.255 | INCHANGE LIVE |
| Client DEV | v3.5.214 | INCHANGE LIVE |
| API DEV | v3.5.254 | INCHANGE LIVE |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker push | OUI | aucun push commande |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement docker build/get |
| restart pod | OUI | uptime preserve |
| build dirty | OUI | worktree --detach clean |
| build from pod/runtime | OUI | from-git worktree |
| tag latest | OUI | tag immuable v3.5.215-ai-draft-blocked-reason-prod |
| secrets logs | OUI | aucun secret display |
| fake event/metric/KBActions | OUI | 0 |
| appel LLM | OUI | aucun |
| mutation DB | OUI | aucun acces DB |
| modification API | OUI | aucune image API touchee |
| changement Linear statut | OUI | comment only |

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L'image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **GO BUILD CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE** |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Tag image | v3.5.215-ai-draft-blocked-reason-prod |
| Config digest local | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 |
| Markers GUIDANCE LIVE bundle | 7/7 (Trame=2, Copier la trame=4) |
| AutoOpen PH-20.11B preserve | OK (pattern compile + 4/2/2/2) |
| AI feature parity | preserve (6/4/10) |
| KEY-263 PROD isolation | OK strict (87/0) |
| KEY-302 sentinel | 0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun docker push, aucun deploy, aucun changement Linear statut.
