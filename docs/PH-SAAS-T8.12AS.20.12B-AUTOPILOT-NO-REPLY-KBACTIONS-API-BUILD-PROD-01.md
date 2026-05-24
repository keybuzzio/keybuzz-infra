# PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-BUILD-PROD-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; references KEY-312 / KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.12B
> Environnement : BUILD API PROD (no push GHCR, no deploy, no kubectl mutation)

## VERDICT

GO BUILD API AUTOPILOT NO-REPLY KBACTIONS PROD READY PH-SAAS-T8.12AS.20.12B

Prochaine phrase GO recommandee : GO PUSH IMAGE API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B

## Resume executif

Image API PROD construite localement from-git depuis le MEME commit source PH-20.12B que DEV (38c048c0). Aucun push GHCR, aucun deploy, aucun kubectl mutation, aucun runtime change.

PARITE BIT-FOR-BIT DEV/PROD CONFIRMEE via sha256 sur 5 fichiers critiques dist :
- noReplyClassifier.js : sha256 IDENTIQUE `92765d7c8c80591f321a502a09b7b79870dccbe188eb8d5665ed73fb8b81191f`
- modules/autopilot/engine.js : sha256 IDENTIQUE `ffea0ec1ed6f6d91ad61dfa66590144216d75727419c59b24f9d598dbc5b42a3`
- config/kbactions.js : sha256 IDENTIQUE `8fa8b5de4a58cd3e68a5a79141ffba811cc096d5bf6e46d83648de78140c904b`
- tests/ph119-tests.js : sha256 IDENTIQUE `e2b6da3e00fd48dcf682405d5882da8347ed17f7d22877c8a1ebfc282a4c354f`
- services/autopilotGuardrails.js : sha256 IDENTIQUE `74e4da5b6d3700f74d5a96bc27cf96c3ae5d58934ef2c586336abc6194305d86`

Tag PROD immuable :
ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod

Image ID local : sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477
Size : 343 519 201 bytes (IDENTIQUE a DEV v3.5.256, preuve mathematique parite source)
OCI labels 6/6 KEY-308 compliant. KEY-309 tag immuable (jamais :latest).

Doctrine seller-first/refund/PH-20.11C blockedInfo preserves (heritage DEV + verification dist).

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
5. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-READONLY-AUDIT-01.md (0f23944)
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-SOURCE-PATCH-DEV-01.md (84fe251)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-BUILD-DEV-01.md (841d0d8)
8. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-PUSH-IMAGE-DEV-01.md (749a6b1)
9. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-APPLY-DEV-01.md (eb7e96d)
10. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-QA-DEV-01.md (baf7254)

## E0 - Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 09:50 UTC | OK |
| keybuzz-api branche | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| keybuzz-api HEAD | 38c048c0 (PH-20.12B source) | 38c048c07fb98543437228657564ef4de388bdfb | OK |
| keybuzz-api commit cible present | OUI | git rev-parse --verify OK | OK |
| keybuzz-api dirty src | clean (dist/ artefacts hors-tracking deja documentes) | preserve | OK pre-existant |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | baf7254 (PH-20.12B QA report) | baf7254ead6a58b5198fb4ff8cf3a24c182aa98e | OK |

Runtime baseline (preserve E7) :

| Service | Image | Pod | Uptime | Verdict |
|---|---|---|---|---|
| keybuzz-api DEV | v3.5.256-autopilot-no-reply-kbactions-dev | kpbjg | 34m | INCHANGE |
| keybuzz-api PROD | v3.5.255-ai-draft-blocked-reason-prod | qv4jd | 24h | INCHANGE |
| keybuzz-client DEV | v3.5.214-ai-draft-blocked-reason-dev | preserve | preserve | INCHANGE |
| keybuzz-client PROD | v3.5.215-ai-draft-blocked-reason-prod | preserve | preserve | INCHANGE |

## E1 - Collision tag

| Image | Local | GHCR | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod | absent (No such image) | absent (manifest unknown) | LIBRE |

KEY-309 tag immuable respecte (version unique reservee, jamais :latest).

## E2 - Worktree build-from-git

| Item | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-PROD/keybuzz-api |
| HEAD detache | 38c048c07fb98543437228657564ef4de388bdfb |
| Commit message | feat(autopilot): skip no-reply platform notifications before KBActions PH-20.12B |
| Status post-checkout | clean (0 dirty) |
| Files updated | 17599 |

## E3 - Audit source dans worktree PROD

| Marker | Fichier | Count | Verdict |
|---|---|---|---|
| PH-SAAS-T8.12AS.20.12B (tag) | src/services/noReplyClassifier.ts | 1 | OK |
| PH-SAAS-T8.12AS.20.12B (tag) | src/modules/autopilot/engine.ts | 2 | OK |
| PH-SAAS-T8.12AS.20.12B (tag) | src/config/kbactions.ts | 3 | OK |
| PH-SAAS-T8.12AS.20.12B (tag) | src/modules/ai/shared-ai-context.ts | 1 | OK |
| PH-SAAS-T8.12AS.20.12B (tag) | src/tests/ph119-tests.ts | 2 | OK |
| classifyNoReplyPlatformNotification (export) | classifier | OK | exported |
| NoReplySubtype + NoReplyResult | classifier | OK | exported |
| classifyNoReplyPlatformNotification (call) | engine.ts:226 | OK | wired |
| Step 6.5 boundary | engine.ts:222 | OK | between Step 6 + Step 6b |
| NO_REPLY_PLATFORM_NOTIFICATION reason | engine.ts:234 | OK | logAction reason |
| autopilot_skipped_no_reply (entry) | kbactions.ts:53 | OK | 0.0 cost |
| PRE_LLM_BLOCKED dans engine.ts | 3 | PRESERVE | PH-20.11C path intact |
| PRE_LLM_BLOCKED dans guardrails.ts | 1 | PRESERVE | doctrine intact |
| PRE_LLM_BLOCKED dans routes.ts | 2 | PRESERVE | blockedInfo expose |
| autopilotGuardrails.ts source hash | 3b85a2763f5b359774d2c8b276026df63537bed03e35aac4aeddd0eadc6c1fea | INCHANGE | doctrine seller-first preserve 100% |

Parite source DEV vs PROD : worktree PROD = worktree DEV = commit 38c048c0 = MEMES markers, MEMES counts, MEME hash autopilotGuardrails.

## E4 - Docker build PROD

| Item | Valeur |
|---|---|
| Dockerfile utilise | Dockerfile (multi-stage : node:lts builder + node:lts-alpine runner) |
| Cache | --no-cache (build froid intentionnel) |
| Push | NON (build local only) |
| Build result | Successfully built 6a426a52780a |
| Tag applique | ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod |
| Duree | ~90s (similaire DEV) |

Labels OCI ajoutes pendant build :
- org.opencontainers.image.revision=38c048c07fb98543437228657564ef4de388bdfb
- org.opencontainers.image.source=https://github.com/keybuzzio/keybuzz-api
- org.opencontainers.image.version=v3.5.257-autopilot-no-reply-kbactions-prod
- org.opencontainers.image.created=2026-05-24T09:51:51Z
- org.opencontainers.image.title=keybuzz-api
- org.opencontainers.image.description=Skip Autopilot no-reply platform notifications before KBActions PH-20.12B PROD

## E5 - OCI audit

| Item | PROD valeur | DEV valeur | Verdict |
|---|---|---|---|
| Image ID (config digest) | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | IDs different (normal, metadata/tag/labels different) |
| **Size** | **343 519 201 bytes** | **343 519 201 bytes** | **IDENTIQUE** preuve mathematique parite source/Dockerfile |
| Created | 2026-05-24T09:53:18Z | 2026-05-23T23:20:17Z | OK |
| OCI revision | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c0... | **IDENTIQUE** MATCH commit source |
| OCI source label | https://github.com/keybuzzio/keybuzz-api | idem | IDENTIQUE |
| OCI version label | v3.5.257-autopilot-no-reply-kbactions-prod | v3.5.256-autopilot-no-reply-kbactions-dev | DIFFERENT (tag env-specifique attendu) |
| OCI title | keybuzz-api | keybuzz-api | IDENTIQUE |
| OCI description | "...PH-20.12B PROD" | "...PH-20.12B" | DIFFERENT (suffix PROD) |
| OCI created | 2026-05-24T09:51:51Z | 2026-05-23T23:18:49Z | DIFFERENT (build time) |
| Labels OCI 6/6 | OK | OK | KEY-308 COMPLIANT |
| Tag KEY-309 immuable | OK (v3.5.257-...-prod jamais :latest) | OK | COMPLIANT |

## E6 - Dist runtime audit + parite DEV bit-for-bit

Extraction dist via `docker create + docker cp /app/dist`, conteneur supprime apres.

| Marker | Fichier dist PROD | Count | Verdict |
|---|---|---|---|
| noReplyClassifier.js | /app/dist/services/noReplyClassifier.js | present 5407 bytes | NEW LIVE |
| ph119-tests.js | /app/dist/tests/ph119-tests.js | present 12014 bytes | NEW LIVE |
| NO_REPLY_PLATFORM_NOTIFICATION | engine.js x1 + classifier x3 | 4 markers | OK |
| autopilot_skipped_no_reply | kbactions.js x1 | 1 marker | OK weight 0.0 compile |
| classifyNoReplyPlatformNotification | classifier x2 + engine x1 | 3 markers | OK wired |
| PH-20.11C blockedInfo (PRE_LLM_BLOCKED + blockedStatus + blockedNotes + guardrailNotes) | engine.js x5 | 5 | PRESERVE |
| PH-20.11C dans autopilotGuardrails.js | 2 | PRESERVE | |
| PH-20.11C dans routes.js | 5 | PRESERVE | |
| refundProtectionLayer.js | present | preserve | PRESERVE doctrine |
| ai-assist-routes.js | present | preserve | PRESERVE |
| autopilot/routes.js | present | preserve | PRESERVE |

**Parite bit-for-bit DEV vs PROD (sha256)** :

| Fichier dist | sha256 DEV | sha256 PROD | Verdict |
|---|---|---|---|
| services/noReplyClassifier.js | 92765d7c8c80591f321a502a09b7b79870dccbe188eb8d5665ed73fb8b81191f | 92765d7c8c80591f321a502a09b7b79870dccbe188eb8d5665ed73fb8b81191f | **IDENTIQUE** |
| modules/autopilot/engine.js | ffea0ec1ed6f6d91ad61dfa66590144216d75727419c59b24f9d598dbc5b42a3 | ffea0ec1ed6f6d91ad61dfa66590144216d75727419c59b24f9d598dbc5b42a3 | **IDENTIQUE** |
| config/kbactions.js | 8fa8b5de4a58cd3e68a5a79141ffba811cc096d5bf6e46d83648de78140c904b | 8fa8b5de4a58cd3e68a5a79141ffba811cc096d5bf6e46d83648de78140c904b | **IDENTIQUE** |
| tests/ph119-tests.js | e2b6da3e00fd48dcf682405d5882da8347ed17f7d22877c8a1ebfc282a4c354f | e2b6da3e00fd48dcf682405d5882da8347ed17f7d22877c8a1ebfc282a4c354f | **IDENTIQUE** |
| services/autopilotGuardrails.js | 74e4da5b6d3700f74d5a96bc27cf96c3ae5d58934ef2c586336abc6194305d86 | 74e4da5b6d3700f74d5a96bc27cf96c3ae5d58934ef2c586336abc6194305d86 | **IDENTIQUE** |

**5/5 fichiers critiques bit-for-bit IDENTIQUES DEV/PROD.** Preuve la plus forte possible de parite source : meme commit + meme Dockerfile + meme node + meme tsc -> meme JS output.

## E7 - Non-regression runtime preserve

| Service | Avant build | Pendant build | Apres build | Verdict |
|---|---|---|---|---|
| keybuzz-api DEV | v3.5.256 pod kpbjg 34m Running 0 restart | INCHANGE | v3.5.256 pod kpbjg 34m+ Running 0 restart | PRESERVE |
| keybuzz-api PROD | v3.5.255 pod qv4jd 24h Running 0 restart | INCHANGE | v3.5.255 pod qv4jd 24h+ Running 0 restart | PRESERVE |
| keybuzz-client DEV | v3.5.214 | INCHANGE | v3.5.214 | PRESERVE |
| keybuzz-client PROD | v3.5.215 | INCHANGE | v3.5.215 | PRESERVE |
| Manifests GitOps | INCHANGE | INCHANGE | INCHANGE | PRESERVE |
| Pod restarts | 0 | 0 | 0 | PRESERVE |

Aucun push GHCR (manifest unknown remote reste vrai). Aucun deploy. Aucun kubectl mutation.

## E8 - Cleanup

| Element | Action | Verdict |
|---|---|---|
| Worktree PH-20.12B-API-PROD | git worktree remove --force + rm -rf parent dir | OK supprime |
| Worktree autres (PH-SAAS-T8.12AS.19.1, main keybuzz-api) | NON touche | OK preserve |
| Tmp dist DEV/PROD (/tmp/ph2012b-*-build-dist) | rm -rf | OK supprime |
| Image locale PROD v3.5.257 | NON supprimee (preserve pour push futur) | OK preserve |
| Image locale DEV v3.5.256 | NON supprimee (preserve) | OK preserve |
| Worktree list final | /opt/keybuzz/keybuzz-api + /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-api seulement | OK |

## AI feature parity / anti-regression

| Feature | Image DEV v3.5.256 validee QA 25/25 PASS | Image PROD v3.5.257 build | Verdict |
|---|---|---|---|
| noReplyClassifier dist sha256 | 92765d7c8c80... | 92765d7c8c80... IDENTIQUE | PARITE BIT-FOR-BIT |
| engine.js dist sha256 | ffea0ec1ed6f... | ffea0ec1ed6f... IDENTIQUE | PARITE BIT-FOR-BIT |
| kbactions.js dist sha256 | 8fa8b5de4a58... | 8fa8b5de4a58... IDENTIQUE | PARITE BIT-FOR-BIT |
| ph119-tests.js dist sha256 | e2b6da3e00fd... | e2b6da3e00fd... IDENTIQUE | PARITE BIT-FOR-BIT |
| autopilotGuardrails.js dist sha256 | 74e4da5b6d37... | 74e4da5b6d37... IDENTIQUE | PARITE BIT-FOR-BIT (doctrine preserve) |
| KBActions skip no-reply 0 (config) | 0 exact (test QA) | 0 (kbactions.js IDENTIQUE) | PARITE |
| inbox_suggestion 6.0 +/-15% | 6.16 (QA) | preserve (kbactions.js IDENTIQUE) | PARITE |
| inbox_contextualized 10.0 +/-15% | 9.79 (QA) | preserve | PARITE |
| Step 6.5 wired engine | OK QA 25/25 | OK (engine.js IDENTIQUE) | PARITE |
| Sender pattern detection 5 subtypes | 16/16 QA PASS | classifier IDENTIQUE | PARITE attendue |
| Control vrais clients NOT classified | 4/4 QA PASS | classifier IDENTIQUE | PARITE attendue |
| HIGH risk customer NOT no-reply | 1/1 QA PASS | classifier IDENTIQUE | PARITE attendue |
| PH-20.11C blockedInfo | preserve QA | preserve (engine.js + routes.js dist) | PARITE |
| refundProtectionLayer | preserve QA | preserve dist | PARITE |
| KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 | preserves | preserves | PARITE |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Fake event tracking | aucun ajout (build = image construction, hors runtime apps) | OK |
| Fake lead/register/checkout | aucun | OK |
| Fake message marketplace | aucun envoi | OK |
| Fake KBActions debit | aucun (dist contient cout 0.0 sentinel) | OK |
| Fake conversation INSERT | aucune (build local Docker, aucune connexion DB) | OK |
| Fake KPI / dashboard | aucun | OK |
| Mutation DB pendant build | aucune | OK |
| Backfill stats | aucun | OK |
| Build consomme wallet ou LLM | NON (docker build local) | OK |

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker push | OUI | 0 commande push, manifest GHCR reste unknown |
| docker tag latest / push d autre tag | OUI | jamais utilise |
| kubectl apply / set / patch / edit / delete / rollout restart | OUI | uniquement kubectl get pour preflight + runtime preserve |
| deploy DEV/PROD | OUI | runtime INCHANGE, pods uptime preserves |
| restart pod | OUI | 0 |
| modifier manifest GitOps | OUI | aucun keybuzz-infra/k8s/ touche |
| modifier source applicatif | OUI | aucun edit pendant build (worktree lecture seule) |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| mutation DB | OUI | 0 |
| message marketplace | OUI | 0 |
| fake event/metric/KBActions/conversation | OUI | 0 |
| secret/token/PII brut | OUI | aucun dans logs build |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| dump env de pods | OUI | 0 (kubectl get + docker create/cp uniquement) |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| git destructive (reset --hard / clean) | OUI | 0 |
| Modification Client/Admin/Website/Backend | OUI | uniquement keybuzz-api build (source deja committe PH-20.12B) |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition |

## Rollback

| Element | Plan |
|---|---|
| Image locale PROD v3.5.257 | `docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod` si besoin (rien ne depend du tag, pas push GHCR) |
| Worktree | DEJA cleanup (E8) |
| Commit source 38c048c0 | `git revert 38c048c0` sur ph147.4/source-of-truth + push (phase separee si requise) |
| Runtime DEV/PROD | N/A (aucun deploy) |
| Manifest GitOps PROD | N/A (aucun modifie) |
| Stack PROD | INCHANGEE (qv4jd v3.5.255 24h+ Running 0 restart) |

## Linear

Commentaires sur tickets pertinents (statut INCHANGE 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : build PROD success
- KEY-231 (KBActions trial value/anxiety) : image PROD preparee, pas encore runtime
- KEY-270 (cloture audits IA) : court rattachement etape BUILD PROD done
- KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 : NON commentes (preserves)

## Gaps restants / V2 ideas (NON engages)

1. Push GHCR PROD : phase PH-20.12B-PUSH-PROD (GO Ludovic requis avant docker push irreversible)
2. Manifest GitOps PROD + apply + rollout : phase PH-20.12B-APPLY-PROD (GO Ludovic explicite)
3. Validation negative read-only smoke PROD post-deploy
4. QA browser Ludovic PROD sur conv reelle bloquee / notif Amazon entrante
5. Observation runtime 24-48h PROD : compter via SQL read-only les ai_action_log nouveaux entries avec reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype> et confirmer kbaCost=0
6. Closeout PH-20.12B end-to-end + transition KEY-337 / KEY-270 / KEY-231 statut (avec GO Ludovic explicite)
7. Client UI enrichissement noReplyInfo dans AISuggestionSlideOver (PH-20.12B-CLIENT optionnel)
8. V2 metric dashboard "Notifications skippees ce mois"

## Prochaine phrase GO

**GO PUSH IMAGE API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B**

STOP.
