# PH-SAAS-T8.12AS.20.47-BUILD-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.47 (BUILD ONLY PROD du correctif PH-20.42-TER)
> Environnement : PROD preparation ; BUILD ONLY (from-git, aucun push, aucun deploy)

## 1. Verdict

GO BUILD AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD READY PH-SAAS-T8.12AS.20.47

Les deux images PROD embarquant le correctif classifier message-level PH-20.42-TER sont
construites localement depuis worktrees Git propres, OCI labels conformes, NON poussees. Audit API
dist OK (helper + garde amazonIds + debitKBActions). Audit Client bundle PROD OK (api.keybuzz.io
inline, api-dev absent, Clarity wuk12h9i33 present, marker skip neutre present, 0 sentinel, KEY-302
respecte). Runtime DEV/PROD inchanges, GHCR tags PROD cibles absents avant et apres.

## 2. Synthese claire pour Ludovic

- Build PROD PRET : keybuzz-api + keybuzz-client en v3.5.259-ai-assist-notification-scope-prod,
  construits depuis Git (commits exacts), images conservees LOCALEMENT (pas de push GHCR).
- Bundle Client PROD pointe bien sur l'API PROD (https://api.keybuzz.io) ; aucune trace de l'API
  DEV ; Clarity wuk12h9i33 present (pas de regression KEY-302/KEY-325).
- API dist : helper de skip message-level + garde amazonIds.messageId + debit KBActions intacts.
- Aucun effet de bord : runtime PROD/DEV inchanges, restarts=0, rien pousse, rien deploye.
- Prochaine action : PH-20.48 PUSH IMAGE PROD (docker push GHCR + pull-back digest match) sur GO
  explicite, puis apply GitOps PROD (phase separee, GO explicite).

## 3. Commits source

| repo | branche | commit | full SHA |
|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 15f0e5e5 | 15f0e5e570c26286bcf394d55718684a5574bec5 |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862 | ad4e862a2e635de251757f382a6d00b8fd063748 |

Worktrees detaches propres (porcelain=0), HEAD = full SHA attendu, retires apres build via
git worktree remove (sans --force).

## 4. Images construites

| service | tag | Image ID | revision | created |
|---|---|---|---|---|
| keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.259-ai-assist-notification-scope-prod | sha256:c0de6f0d9c8b709157a2a480baa5c95b4fa0938fb63ad25ac032be17529a89b0 | 15f0e5e570c26286bcf394d55718684a5574bec5 | 2026-05-27T23:46:29Z |
| keybuzz-client | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | sha256:9f46a7a88f83e15333b4e0106ac740b0571a8e4f38743b6c09d964e4566f5b69 | ad4e862a2e635de251757f382a6d00b8fd063748 | 2026-05-27T23:47:27Z |

OCI labels : org.opencontainers.image.{revision,version,created} conformes sur les deux images.
version = v3.5.259-ai-assist-notification-scope-prod. Aucun tag latest. Aucun push.

## 5. Build args PROD (Client, KEY-302 / KEY-325)

| build arg | valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | production |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 |

GA4 / Meta / SGTM / TikTok : defaults Dockerfile conserves (baseline client PROD les omet
deliberement, cf docs/BUILD-ARGS.md). LinkedIn default 9969977. Guard check-client-build-args.sh
passe (sinon le build aurait echoue). Valeurs NEXT_PUBLIC publiques, aucun secret.

## 6. Tests pre-build

| test | attendu | resultat |
|---|---|---|
| API helper pur determineAiAssistNotificationSkip | 15/15 PASS | 15 passed, 0 failed |
| API tsc --noEmit (projet) | EXIT 0 | EXIT 0 |
| Client tsc --noEmit (worktree neuf) | EXIT 0, 0 erreur fichiers touches | EXIT 0 (pas de .next stale dans worktree neuf) |

Cas helper couverts : notification no-reply -> skip true ; mixte dernier inbound buyer amazonIds
-> skip false (BUYER_AMAZON_IDS_PRESENT) ; mixte dernier inbound notif -> skip true ; buyer
mentionne Amazon sender non no-reply -> skip false ; amazonIds present meme si author notif ->
skip false ; pas de message inbound -> skip false (NO_INBOUND_MESSAGE) ; idempotence ; edge
amazonMessageId blanc -> traite comme absent.

## 7. Audit API dist (image PROD)

| marker | attendu | resultat |
|---|---|---|
| determineAiAssistNotificationSkip | present | 2 fichiers (noReplyClassifier.js + ai-assist-routes.js) |
| BUYER_AMAZON_IDS_PRESENT (garde amazonIds.messageId) | present | 1 |
| NO_REPLY_PLATFORM_NOTIFICATION | present | 4 |
| debitKBActions (ai-assist-routes.js, hors skip) | present | 1 |
| hardcode tenant/order (ecomlg/switaa/171-8133751/35212521252558) | absent | 0 |

Skip base sur le DERNIER message inbound (requete direction='inbound' ORDER BY created_at DESC
LIMIT 1) ; classifier classifyNoReplyPlatformNotification utilise sans elargissement de patterns ;
debitKBActions sur le chemin normal (l.1105), jamais sur le chemin skip.

## 8. Audit Client bundle PROD (/app/.next/static)

| marker bundle | attendu | resultat |
|---|---|---|
| https://api.keybuzz.io | present | 2 occurrences |
| https://api-dev.keybuzz.io | absent | 0 |
| Clarity wuk12h9i33 | present | 1 fichier |
| sentinel __MUST_BE_SET_BY_BUILD_ARG__ | absent | 0 |
| localhost:3000/3001 | absent | 0 |
| marker skip neutre ("brouillon IA" / "Notification systeme") | present | 1 fichier chacun |
| chemin erreur reelle ("Impossible de g[enerer]") | present | 1 fichier |

Script officiel scripts/verify-client-bundle-api-url.sh production : "OK: bundle inlined
https://api.keybuzz.io only" (api-dev=0, api.keybuzz.io=2). Aucune API DEV inlinee dans le bundle
PROD -> incident KEY-302 evite. Etat neutre skipped + chemin erreur reelle tous deux compiles.

## 9. No side-effect

- GHCR tags PROD cibles : ABSENTS avant et apres (api + client). Aucun docker push.
- Images PROD presentes LOCALEMENT uniquement : api c0de6f0d9c8b, client 9f46a7a88f83.
- Runtime PROD inchange : api v3.5.257-autopilot-no-reply-kbactions-prod, client
  v3.5.217-clarity-client-restore-prod ; restarts=0. Runtime DEV inchange (v3.5.259-...-dev).
- Manifests DEV/PROD ne referencent PAS les tags PROD cibles.
- Aucun kubectl, aucune DB mutation, aucun fake event/KBActions, latest non touche.
- Worktrees retires proprement (git worktree remove sans --force, donc clean). Repos principaux
  intacts (api HEAD 15f0e5e5, client HEAD ad4e862, dirty pre-existant tolere uniquement :
  api dist/, client tsconfig.tsbuildinfo).

## 10. Limites

- NO DEPLOY : cette phase ne pousse ni ne deploie. Les images ne sont pas sur GHCR.
- PUSH + APPLY PROD a faire dans des phases separees avec GO explicite de Ludovic
  (PH-20.48 push ; puis apply GitOps PROD API + Client).
- Hardening LiteLLM (alerting credit + fallback multi-provider) reste une phase separee
  (cf PH-20.46-BIS/TER/QUATER), hors scope de ce build.

## 11. Rollback futur theorique (post-deploy, hors scope ici)

Au moment de l'apply PROD (phase separee) : conserver en commentaire les tags precedents
(api v3.5.257-autopilot-no-reply-kbactions-prod, client v3.5.217-clarity-client-restore-prod) ;
rollback = git revert du bump manifest + kubectl apply -f. Aucune migration DB associee a ce
correctif (classifier + UX uniquement).

## 12. Prochaine etape

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD PH-SAAS-T8.12AS.20.48 :
- docker push GHCR + pull-back digest match pour les deux images
  v3.5.259-ai-assist-notification-scope-prod (api + client), GO explicite requis.

## 13. Phrase cible

GO BUILD AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD READY PH-SAAS-T8.12AS.20.47

STOP.
