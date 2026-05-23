# PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable) ; KEY-263 (DEV/PROD isolation)
> Phase : PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX BUILD Client DEV from-git
> Environnement : Build Docker DEV only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev` build OK depuis worktree --detach commit `d132cc4f`.
- Image ID + config digest : `sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb` size 280 MB.
- OCI labels KEY-308 5/5 OK (revision=`d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6`).
- **Pattern AUTOOPEN-FIX compile LIVE dans bundle** : la condition compilee `A&&d&&((null==w?void 0:w.draftText)||(null==S?void 0:S.blocked))?es.current!==d&&(...(w.draftText)&&er(w),R(!0)):w||(null==S?void 0:S.blocked)||er(null)` est presente dans le chunk minifie -> patch source d132cc4f effectif au runtime.
- v3.5.212 baseline : pattern absent (0 occurrences) -> delta confirme par hash chunk different.
- Bundle markers PH-20.11B preserve : `blockedInfo=4`, `Garde-fou actif=2`, `Brouillon IA bloque par securite=2`, `Validation humaine recommandee=2`.
- AI feature parity preserve : `Brouillon IA=6`, `Suggestion IA=4`, `Aide IA=10`.
- KEY-263 DEV isolation strict : `api-dev.keybuzz.io=87`, `api.keybuzz.io` PROD pattern = 0.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- No fake events : `test_event_code=0`.
- No hardcode tenant/case user / no real secret : 0/0/0/0/0.
- GHCR collision : LIBRE.
- Worktree nettoyee.
- Runtime DEV+PROD INCHANGES.

STOP avant push GHCR DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T23:49:42Z |
| keybuzz-client HEAD | d132cc4f (full d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6) |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| Dirty avant build | 1 (tsconfig.tsbuildinfo cache, pre-existant non lie) |
| GHCR collision v3.5.213-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Image | Tag | Collision | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.213-ai-draft-blocked-reason-dev | manifest unknown | LIBRE |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-DEV/keybuzz-client |
| Worktree detache sur | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 |
| Worktree dirty | 0 (clean) |

## E3 BUILD ARGS DEV KEY-302

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | OK |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | OK |
| GIT_COMMIT_SHA | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | OK |
| BUILD_TIME | 2026-05-22T23:50:00Z | OK |

## E4 DOCKER BUILD CLIENT DEV

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev |
| Exit code | 0 |
| Image ID + config digest | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb |
| Size | 280 MB |
| Created (label) | 2026-05-22T23:50:00Z |
| Created (registry) | 2026-05-22 23:52:47 UTC |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T23:50:00Z | OK |
| org.opencontainers.image.revision | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | OK MATCH commit cible |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |
| org.opencontainers.image.version | v3.5.213-ai-draft-blocked-reason-dev | OK |

## E5 OCI AUDIT LOCAL

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | 3158c38651e1 | OK |
| Config digest local | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | OK |
| Size | 280 MB | OK |
| Created label | 2026-05-22T23:50:00Z | OK |
| OCI revision label | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | OK MATCH |
| Tag local | v3.5.213-ai-draft-blocked-reason-dev | OK |

## E6 BUNDLE AUDIT /app/.next

### Markers AUTOOPEN-FIX

| Marker | Count v3.5.213 | Count v3.5.212 baseline | Verdict |
|---|---|---|---|
| `shouldAutoOpen` (identifier locale) | 0 | 0 | normal (minifie par SWC en build prod) |
| `blockedInfo` (nom prop conserve) | 4 | 4 | OK preserve |
| `Garde-fou actif` (texte UX) | 2 | 2 | preserve |
| `Brouillon IA bloque par securite` | 2 | 2 | preserve |
| `Validation humaine recommandee` | 2 | 2 | preserve |

### Pattern compile NEW (delta vrai par bundle hash)

| Item | v3.5.213 | v3.5.212 baseline | Verdict |
|---|---|---|---|
| Chunk hash `static/chunks/1024-*.js` (contient SlideOver minifie) | `9df58625a64f17553d24bfdd0adddc03` (1024-48da8054419efe05.js) | `52cc7091eca63855e8cc9bea78b9dc54` (1024-242ac26bb4328793.js) | **DIFFERENT** = bundle effectivement recompile |
| Pattern compile autoOpen + draftText OR blocked | **PRESENT** : `A&&d&&((null==w?void 0:w.draftText)\|\|(null==S?void 0:S.blocked))?es.current!==d&&(...(w.draftText)&&er(w),R(!0)):w\|\|(null==S?void 0:S.blocked)\|\|er(null)` | absent (0 occurrence pattern) | **OK fix LIVE** |

**Le pattern compile correspond exactement au patch source** :
- `A` = `autoOpen`, `d` = `conversationId`, `w` = `initialDraft`, `S` = `blockedInfo`
- Condition `autoOpen && conversationId && (initialDraft?.draftText || blockedInfo?.blocked)` confirmee compile
- `es.current !== d` = `draftDismissedRef.current !== conversationId` (KEY-305 preserve)
- `(w.draftText)&&er(w)` = setActiveDraft uniquement si draftText present
- `R(!0)` = setIsOpen(true)
- `w||(null==S?void 0:S.blocked)||er(null)` = else reset uniquement si ni draft ni blocked

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
| api.keybuzz.io PROD pattern (`[^-]api\.keybuzz\.io`) | **0** | OK isolation respectee |

### KEY-302 sentinel + no fake events + no hardcode + no secret

| Indicateur | Count | Verdict |
|---|---|---|
| `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | OK |
| test_event_code | 0 | OK |
| ecomlg-motxke32 / kj44qkxp6b0z250 / jml1tnc080qz1c0 | 0/0/0 | OK |
| sk_live_ / sk_test_ | 0/0 | OK |

## E7 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | **v3.5.212-ai-draft-blocked-reason-dev** | INCHANGE (cible build non deployee) |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

## E8 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-DEV/` | OK |

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Bundle live v3.5.213 | Verdict |
|---|---|---|
| Brouillon IA normal (DRAFT_GENERATED) | conditional path preserve : `(w.draftText)&&er(w)` | OK |
| **Blocked auto-open (PRE_LLM_BLOCKED/ESCALATION_DRAFT)** | **pattern compile LIVE : condition `||(null==S?void 0:S.blocked)` ajoute** | **FIX** |
| Carte UX Garde-fou actif visible blocked | preserve (l.691 SlideOver `!activeDraft && blockedInfo && blockedInfo.blocked`) | OK |
| KEY-305 race fix (`es.current !== d` = `draftDismissedRef.current !== conversationId`) | preserve | OK |
| Brouillon IA / Suggestion IA / Aide IA | 6 / 4 / 10 preserve | OK |
| Doctrine seller-first (autopilotGuardrails.ts hash) | INCHANGE 100% | OK |
| KEY-263 isolation DEV/PROD | api-dev=87, PROD=0 | OK |
| KEY-302 build args sentinel | 0 | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel LLM | 0 | OK |
| Aucun event marketing | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun message marketplace | 0 | OK |
| Audit statique bundle uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE, attente GO).
- AUCUN deploy DEV/PROD.
- AUCUN kubectl mutation.
- AUCUN restart pod.
- AUCUN patch source au-dela d132cc4f.
- AUCUN changement API.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux event/lead/register/checkout.
- AUCUN changement Linear statut.
- KEY-302 sentinel 0 occurrences.
- KEY-305 fix race preserve dans bundle compile.
- KEY-263 isolation DEV/PROD respectee.
- Doctrine seller-first INCHANGE 100%.
- Bastion install-v3 (46.62.171.61) uniquement.

## TABLEAUX FINAUX

### 1. Repo / Git

| Repo | Branche | Commit | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | 0 (worktree clean) | OK |

### 2. Image

| Image | Tag | Digest local | OCI revision | Size | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.213-ai-draft-blocked-reason-dev | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | 280 MB | OK |

### 3. Build args

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | OK |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | OK |
| GIT_COMMIT_SHA | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | OK |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| `blockedInfo` | 4 | preserve |
| `Garde-fou actif` | 2 | preserve |
| `Brouillon IA bloque par securite` | 2 | preserve |
| `Validation humaine recommandee` | 2 | preserve |
| Pattern compile `draftText \|\| blocked` autoOpen | PRESENT (delta vs 212) | **OK FIX LIVE** |
| Chunk 1024 hash | 9df58625a64f17553d24bfdd0adddc03 (different de 212) | OK recompile |
| api-dev.keybuzz.io | 87 | OK KEY-263 |
| api.keybuzz.io PROD pattern | 0 | OK isolation |
| KEY-302 sentinel | 0 | OK |
| No hardcode/no secret/no fake events | 0/5 | OK |

### 5. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client DEV | v3.5.212 | INCHANGE |
| Client PROD | v3.5.201 | INCHANGE |
| API DEV | v3.5.254 | INCHANGE LIVE |
| API PROD | v3.5.252 | INCHANGE |
| Backend / Website | inchanges | INCHANGES |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker push | OUI | aucun push commande |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement docker build |
| restart pod | OUI | uptime preserve |
| build dirty | OUI | worktree --detach clean |
| build from pod/runtime | OUI | from-git worktree |
| tag latest | OUI | tag immuable v3.5.213-ai-draft-blocked-reason-dev |
| secrets logs | OUI | aucun secret display |
| fake event/metric/KBActions | OUI | 0 |
| appel LLM | OUI | aucun |
| mutation DB | OUI | aucun acces DB |
| modification API | OUI | aucune image API touchee |
| changement Linear statut | OUI | comment only |

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L'image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX |
| Bastion | install-v3 46.62.171.61 |
| Source commit | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 |
| Tag image | v3.5.213-ai-draft-blocked-reason-dev |
| Config digest local | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb |
| Pattern AUTOOPEN-FIX dans bundle | LIVE (draftText \|\| blocked compile dans chunk 1024) |
| KEY-305 race fix preserve | OK (es.current!==d dans compile) |
| AI feature parity | preserve (6/4/10) |
| KEY-263 isolation | OK (87/0) |
| KEY-302 sentinel | 0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT AI DRAFT AUTOOPEN ESCALATION DEV PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX`

STOP. Aucun docker push, aucun deploy, aucun changement Linear statut.
