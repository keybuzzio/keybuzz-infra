# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-DEV-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE BUILD Client DEV from-git
> Environnement : Build Docker DEV only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev` build OK depuis worktree --detach commit `1a30ad9`.
- Image ID + config digest : `sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4` size 280 MB.
- OCI labels KEY-308 5/5 OK (revision=`1a30ad925fed3fb0b237e7b82694c2f839bc0778`).
- **Markers GUIDANCE PH-20.11C LIVE 7/7** dans bundle :
  - `Trame de reponse securisee=2`
  - `Point de depart humain=2`
  - `sans generation IA=2`
  - `consommation de KBActions=2`
  - `ne peux pas confirmer immediatement=2`
  - `remboursement ou un remplacement avant verification=2`
  - `Copier la trame=4` (icone + tooltip + label + check copie)
- **AutoOpen PH-20.11B preserve** : pattern compile `.draftText)||(null==S?void 0:S.blocked` + reset conditionnel preserve.
- AI feature parity preserve : `Brouillon IA=6`, `Suggestion IA=4`, `Aide IA=10`.
- KEY-263 DEV isolation strict : `api-dev.keybuzz.io=87`, `api.keybuzz.io` PROD=0.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- No fake events / no secrets / no hardcode : 0/0/0/0/0/0/0.
- **Baseline v3.5.213** : `Trame de reponse securisee=0`, `Copier la trame=0` -> guidance bel et bien nouvelle.
- GHCR collision tag DEV cible LIBRE.
- Worktree nettoyee.
- Runtime DEV+PROD INCHANGES.

STOP avant push GHCR DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T00:58:44Z |
| keybuzz-client HEAD | 1a30ad9 (full 1a30ad925fed3fb0b237e7b82694c2f839bc0778) |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| Dirty avant build | 1 (tsconfig.tsbuildinfo cache pre-existant, non lie) |
| GHCR collision v3.5.214-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Image | Tag | Collision | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | manifest unknown | LIBRE |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-DEV/keybuzz-client |
| Worktree detache sur | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Worktree dirty | 0 (clean) |

## E3 BUILD ARGS DEV KEY-302

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | OK |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | OK |
| GIT_COMMIT_SHA | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |
| BUILD_TIME | 2026-05-23T00:59:04Z | OK |

## E4 DOCKER BUILD CLIENT DEV

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev |
| Exit code | 0 |
| Image ID + config digest | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 |
| Size | 280 MB |
| Created (label) | 2026-05-23T00:59:04Z |
| Created (registry) | 2026-05-23 01:02:03 UTC |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-23T00:59:04Z | OK |
| org.opencontainers.image.revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK MATCH |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |
| org.opencontainers.image.version | v3.5.214-ai-draft-blocked-reason-dev | OK |

## E5 OCI AUDIT LOCAL

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | 74d13025bd24 | OK |
| Config digest | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | OK |
| Size | 280 MB | OK |
| OCI revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK MATCH |
| Tag local | v3.5.214-ai-draft-blocked-reason-dev | OK |

## E6 BUNDLE AUDIT /app/.next

### Markers GUIDANCE PH-20.11C LIVE

| Marker | Count v3.5.214 | Count v3.5.213 baseline | Verdict |
|---|---|---|---|
| `Trame de reponse securisee` (titre UX) | 2 | 0 | **NOUVEAU LIVE** |
| `Point de depart humain` (sous-texte) | 2 | NA | **NOUVEAU LIVE** |
| `sans generation IA` (sous-texte) | 2 | NA | **NOUVEAU LIVE** |
| `consommation de KBActions` (sous-texte) | 2 | NA | **NOUVEAU LIVE** |
| `ne peux pas confirmer immediatement` (corps trame) | 2 | NA | **NOUVEAU LIVE** |
| `remboursement ou un remplacement avant verification` (corps trame) | 2 | NA | **NOUVEAU LIVE** |
| `Copier la trame` (bouton + tooltip + label + check copie) | 4 | 0 | **NOUVEAU LIVE** |

### Pattern AUTOOPEN PH-20.11B preserve (anti-regression)

| Marker | Count v3.5.214 | Verdict |
|---|---|---|
| blockedInfo | 4 | preserve |
| Garde-fou actif | 2 | preserve |
| Brouillon IA bloque par securite | 2 | preserve |
| Validation humaine recommandee | 2 | preserve |
| Pattern compile autoOpen `(draftText)\|\|(blocked)` | PRESENT (2 occurrences) | preserve |

Le pattern compile est trouve dans le chunk minifie : `.draftText)||(null==S?void 0:S.blocked` + `.draftText)&&es(w),R(!0)):w||(null==S?void 0:S.blocked`. AUTOOPEN-FIX preserve LIVE.

### AI feature parity preserve

| Marker | Count | Verdict |
|---|---|---|
| Brouillon IA | 6 | preserve |
| Suggestion IA | 4 | preserve |
| Aide IA | 10 | preserve |

### KEY-263 DEV isolation strict

| Indicateur | Count | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 87 | OK present DEV |
| api.keybuzz.io PROD pattern | **0** | OK isolation respectee |

### KEY-302 sentinel + no fake/secret/hardcode

| Indicateur | Count | Verdict |
|---|---|---|
| `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | OK |
| test_event_code | 0 | OK |
| ecomlg-motxke32 / kj44qkxp6b0z250 / jml1tnc080qz1c0 | 0/0/0 | OK |
| sk_live_ / sk_test_ | 0/0 | OK |
| SWITAA (hardcode case user) | 0 | OK |

## E7 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | **v3.5.213-ai-draft-blocked-reason-dev** | INCHANGE (cible build non deployee) |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

## E8 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-DEV/` | OK |

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Bundle v3.5.214 | Verdict |
|---|---|---|
| Brouillon IA normal (DRAFT_GENERATED) | preserve | OK |
| Brouillon IA blockedInfo auto-open PH-20.11B | preserve (pattern compile LIVE) | OK |
| **Trame de reponse securisee (NOUVEAU PH-20.11C)** | **LIVE 7/7 markers** | **FIX/UX enrichissement** |
| Suggestion IA | preserve | OK |
| Aide IA | preserve (10) | OK |
| Doctrine seller-first (autopilotGuardrails.ts non touche) | INCHANGE 100% | OK |
| KBActions billing | INCHANGE | OK |
| KEY-305 race fix (`es.current!==d` compile) | preserve | OK |
| KEY-263 DEV isolation | OK (87/0) | OK |
| KEY-302 sentinel | 0 | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel LLM/Meta/GA/LinkedIn durant build | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun event marketing | 0 | OK |
| Aucun message marketplace | 0 | OK |
| Audit statique bundle uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE, attente GO).
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
- KEY-305 fix race preserve dans bundle compile (autoOpen).
- KEY-263 isolation DEV/PROD respectee.
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
| ghcr.io/keybuzzio/keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | 280 MB | OK |

### 3. Build args

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | OK |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | OK |
| GIT_COMMIT_SHA | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| **Trame de reponse securisee** | 2 | NOUVEAU LIVE |
| **Point de depart humain** | 2 | NOUVEAU LIVE |
| **sans generation IA** | 2 | NOUVEAU LIVE |
| **consommation de KBActions** | 2 | NOUVEAU LIVE |
| **ne peux pas confirmer immediatement** | 2 | NOUVEAU LIVE |
| **remboursement ou un remplacement avant verification** | 2 | NOUVEAU LIVE |
| **Copier la trame** | 4 | NOUVEAU LIVE |
| blockedInfo (autoOpen PH-20.11B) | 4 | preserve |
| Garde-fou actif | 2 | preserve |
| Brouillon IA bloque par securite | 2 | preserve |
| Validation humaine recommandee | 2 | preserve |
| Pattern compile autoOpen (draftText \|\| blocked) | PRESENT | preserve |
| Brouillon IA / Suggestion IA / Aide IA | 6/4/10 | preserve |
| api-dev / api.keybuzz.io PROD | 87/0 | KEY-263 OK |
| KEY-302 sentinel | 0 | OK |
| Fake events / secrets / hardcode | 0 | OK |

### 5. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client DEV | v3.5.213 | INCHANGE |
| Client PROD | v3.5.201 | INCHANGE |
| API DEV | v3.5.254 | INCHANGE LIVE |
| API PROD | v3.5.252 | INCHANGE |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker push | OUI | aucun push commande |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement docker build/get |
| restart pod | OUI | uptime preserve |
| build dirty | OUI | worktree --detach clean |
| build from pod/runtime | OUI | from-git worktree |
| tag latest | OUI | tag immuable v3.5.214 |
| secrets logs | OUI | aucun secret display |
| fake event/metric/KBActions | OUI | 0 |
| appel LLM | OUI | aucun |
| mutation DB | OUI | aucun acces DB |
| modification API | OUI | aucune image API touchee |
| changement Linear statut | OUI | comment only |

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L'image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Source commit | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Tag image | v3.5.214-ai-draft-blocked-reason-dev |
| Config digest local | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 |
| Markers GUIDANCE LIVE bundle | 7/7 (2/2/2/2/2/2/4) |
| AutoOpen PH-20.11B preserve | OK (pattern compile + 4/2/2/2) |
| AI feature parity | preserve (6/4/10) |
| KEY-263 isolation | OK (87/0) |
| KEY-302 sentinel | 0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE DEV PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun docker push, aucun deploy, aucun changement Linear statut.
