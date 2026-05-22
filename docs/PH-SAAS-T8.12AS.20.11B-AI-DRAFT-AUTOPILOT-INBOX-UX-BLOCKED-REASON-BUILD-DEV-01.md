# PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 (race UI preserve) ; KEY-235 (seller-first preserve) ; KEY-231 (KBActions inchange) ; KEY-302 (build args) ; KEY-308 (OCI labels) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B BUILD Client DEV from-git
> Environnement : Build Docker DEV only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV READY PH-SAAS-T8.12AS.20.11B

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev` build OK depuis worktree --detach commit `fb348356`.
- Image ID local + config digest : `sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3` size 280 MB.
- OCI labels KEY-308 5/5 OK (revision=fb348356a42c09b4494f7c5454f14b47e223e466).
- Bundle /app/.next : markers PH-20.11B LIVE 4/4 : `blockedInfo=2`, `Garde-fou actif=2`, `Brouillon IA bloque par securite=2`, `Validation humaine recommandee=2`.
- AI feature parity LIVE : Brouillon IA=6, Suggestion IA=4, Aide IA=10 (preserve).
- **KEY-263 DEV isolation parfaite** : `api-dev.keybuzz.io=87`, `api.keybuzz.io` PROD=0 (regex `[^-]api\.keybuzz\.io` exclut match dans api-dev).
- Build args KEY-302 injectes correctement : `__MUST_BE_SET_BY_BUILD_ARG__=0` (sentinel absent).
- No fake events : `test_event_code=0`.
- No hardcode tenant/case user : 0/3.
- No secret/PII/key : 0/6 (PGPASSWORD, sk_live_, sk_test_).
- GHCR collision tag DEV cible LIBRE (`manifest unknown`).
- Worktree nettoyee.
- Runtime Client DEV `v3.5.210-register-polish-dev` INCHANGE.

STOP avant push GHCR DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T18:49:28Z |
| keybuzz-client HEAD | fb34835 (full fb348356a42c09b4494f7c5454f14b47e223e466) MATCH expected |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| Dirty | 1 (pre-existing, non lie au patch) |
| Runtime Client DEV avant | v3.5.210-register-polish-dev |
| GHCR collision v3.5.211-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) |

## E1 AUDIT SOURCE PRE-BUILD

| Marker source | Count `src/features/ai-ui/AISuggestionSlideOver.tsx` | Verdict |
|---|---|---|
| blockedInfo | 7 | OK |
| AutopilotBlockedInfo | 2 (interface + reference) | OK |
| Garde-fou actif | 1 | OK |
| Brouillon IA bloque par securite | 1 | OK |
| Validation humaine recommandee | 1 | OK |
| PH-SAAS-T8.12AS.20.11B (marker phase) | 3 | OK |

### KEY-305 fix preserve

| Marker | Count | Verdict |
|---|---|---|
| `prevConversationIdRef` + `draftDismissedRef` source | 8 (4+4) | preserve l.153, 157, 234-235 |

### No hardcode tenant/case user dans src/

| Token | Files | Verdict |
|---|---|---|
| ecomlg-motxke32 | 0 | OK |
| kj44qkxp6b0z250 | 0 | OK |
| jml1tnc080qz1c0 | 0 | OK |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-CLIENT-DEV/keybuzz-client |
| Worktree detache sur | fb348356 |
| Full hash | fb348356a42c09b4494f7c5454f14b47e223e466 |
| Worktree dirty | 0 (clean) |

## E3 DOCKER BUILD CLIENT DEV

### Build args (KEY-302 conformes check-client-build-args.sh)

| Arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| GIT_COMMIT_SHA | fb348356a42c09b4494f7c5454f14b47e223e466 |
| BUILD_TIME | 2026-05-22T18:50:09Z |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 (default Dockerfile) |
| autres NEXT_PUBLIC_* | defaults Dockerfile (vides) |

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev |
| Exit code | 0 |
| Image ID + config digest | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 |
| Size | 280 MB |
| Created (label) | 2026-05-22T18:50:09Z |
| Created (registry) | 2026-05-22 18:52:57 UTC |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T18:50:09Z | OK |
| org.opencontainers.image.revision | fb348356a42c09b4494f7c5454f14b47e223e466 | OK MATCH commit |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |
| org.opencontainers.image.version | v3.5.211-ai-draft-blocked-reason-dev | OK |

KEY-309 tag immutable + suffixe `-dev` conforme + versioning bump (v3.5.210 -> v3.5.211).

## E3 AUDIT IMAGE BUNDLE (/app/.next)

### Markers patch PH-20.11B LIVE

| Marker | Count | Verdict |
|---|---|---|
| blockedInfo | 2 | OK LIVE prop component |
| Garde-fou actif | 2 | OK LIVE badge UX |
| Brouillon IA bloque par securite | 2 | OK LIVE titre PRE_LLM_BLOCKED |
| Validation humaine recommandee | 2 | OK LIVE titre ESCALATION_DRAFT |

### AI feature parity preserve

| Marker | Count | Verdict |
|---|---|---|
| Brouillon IA (titre mode draft) | 6 | preserve |
| Suggestion IA (titre mode sans draft) | 4 | preserve |
| Aide IA (label fallback manuel) | 10 | preserve |
| AISuggestionSlideOver | 0 (name minifie par Next/SWC en prod build) | normal |
| AutopilotBlockedInfo | 0 (interface TS, stripped en JS prod) | normal |
| prevConversationIdRef / draftDismissedRef | 0 (useRef identifiers minifies par Next) | normal - fix preserve source |

### KEY-263 DEV isolation strict

| Indicateur | Count | Verdict |
|---|---|---|
| api-dev.keybuzz.io (DEV endpoint) | 87 | OK present DEV |
| api.keybuzz.io (PROD endpoint dans DEV, regex `[^-]api\.keybuzz\.io`) | **0** | OK isolation respectee |

### Build args sentinel + no fake events

| Indicateur | Count | Verdict |
|---|---|---|
| `__MUST_BE_SET_BY_BUILD_ARG__` sentinel | 0 | OK KEY-302 conforme |
| test_event_code | 0 | OK no fake events |

## E4 SECRET / PII SCAN

| Token | Count | Verdict |
|---|---|---|
| ecomlg-motxke32 (tenant ID hardcode) | 0 | OK |
| kj44qkxp6b0z250 (Guilhem case) | 0 | OK |
| jml1tnc080qz1c0 (Nordine case) | 0 | OK |
| PGPASSWORD | 0 | OK |
| sk_live_ (Stripe live key) | 0 | OK |
| sk_test_ (Stripe test key) | 0 | OK |

Aucun secret. Aucune PII. Aucun hardcode tenant/case user.

## E5 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.11B-CLIENT-DEV/` | OK |
| Repo principal keybuzz-client | dirty=1 (pre-existant, non lie patch) |

## E6 RUNTIME NON-REGRESSION

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.210-register-polish-dev** | INCHANGE (cible build non deployee) |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV+PROD | v3.5.253 / v3.5.252 | INCHANGES |
| keybuzz-backend | DEV+PROD | v1.0.47 | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.21 / v0.6.21-pricing-action-recover-prod | INCHANGES |

Aucun deploy. Aucun manifest GitOps modifie. Aucun kubectl apply.

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Bundle live | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED | preserve (6 occurrences string) | OK |
| Suggestion IA visible mode sans draft | preserve (4) | OK |
| Aide IA manuelle | preserve (10) | OK |
| KEY-305 fix race UI source preserve | l.153,157,234-235 source intacte | OK (identifiers minifies en bundle, normal) |
| Carte UX "Garde-fou actif" + copy distincte | 2/2 active | OK |
| Aucun changement send/reply/consume | confirmed (4 patches scope strict AISuggestionSlideOver.tsx uniquement) | OK |
| doctrine seller-first/refund-protection | INCHANGE 100% (autopilotGuardrails.ts intact) | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Build container Docker uniquement | OK | OK |
| Aucun appel reseau LLM/Meta/GA/LinkedIn durant build | 0 | OK |
| 0 test_event_code dans bundle | OK | OK |
| Aucun lead/register/checkout test | 0 | OK |
| Aucun appel `/ai/assist` / `/ai/execute` / `/autopilot/draft/consume` | 0 | OK |
| Aucune KBActions debit/reservation simule | 0 | OK |
| Audit statique bundle uniquement | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE, attente GO).
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela commit fb348356.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux event/register/checkout/lead.
- AUCUN changement API/Backend/Admin.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.
- KEY-302 build args sentinel 0 occurrences dans bundle.

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV READY PH-SAAS-T8.12AS.20.11B |
| Bastion | install-v3 46.62.171.61 |
| Source commit | fb348356 (full fb348356a42c09b4494f7c5454f14b47e223e466) |
| Tag image DEV | v3.5.211-ai-draft-blocked-reason-dev |
| Image ID local + config digest | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 |
| Size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| Markers PH-20.11B LIVE bundle | 4/4 OK |
| AI feature parity | preserve (Brouillon=6, Suggestion=4, Aide=10) |
| KEY-263 DEV isolation | OK (api-dev=87, api.keybuzz.io PROD=0) |
| KEY-302 build args sentinel | 0 (conforme) |
| No fake events / no secret / no PII / no hardcode | 0/0/0/0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV PH-SAAS-T8.12AS.20.11B`

STOP. Aucun docker push, aucun deploy DEV/PROD, aucun event tracking, aucun changement Linear statut.
