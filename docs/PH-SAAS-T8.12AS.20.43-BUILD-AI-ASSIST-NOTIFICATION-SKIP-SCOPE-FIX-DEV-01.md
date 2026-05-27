# PH-SAAS-T8.12AS.20.43-BUILD-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.43 (BUILD ONLY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV)
> Environnement : DEV preparation, BUILD ONLY ; aucun push/deploy/kubectl/DB/fake event

## 1. Verdict

GO BUILD AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV READY PH-SAAS-T8.12AS.20.43

Les 2 images DEV embarquant le correctif PH-20.42-TER (skip AI Assist message-level + garde
amazonIds, Client skip neutre) sont construites localement depuis des worktrees Git detaches
propres, OCI labels conformes, NON poussees. API dist audite (helper + garde amazonIds +
skip message-level + debitKBActions intact). Client bundle DEV audite par le script
autoritaire verify-client-bundle-api-url.sh : api-dev.keybuzz.io seul (api.keybuzz.io PROD =
0 occurrence), Clarity wuk12h9i33 present (parite DEV courante), marker skipped + texte neutre
present. Runtime DEV/PROD inchanges, GHCR sans les tags cibles, latest intact. PH-20.43
promotion PROD reste bloque jusqu'a push/apply/verify DEV.

## 2. Commits source + images

| repo | branche | commit source (full) | image locale | Image ID |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 15f0e5e570c26286bcf394d55718684a5574bec5 | ghcr.io/keybuzzio/keybuzz-api:v3.5.259-ai-assist-notification-scope-dev | sha256:499993fdb18d... |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a2e635de251757f382a6d00b8fd063748 | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | sha256:8f41c7a48896... |

OCI labels (les deux) : revision=<full SHA ci-dessus>, version=v3.5.259-ai-assist-notification-scope-dev,
created=2026-05-27T19:37:37Z (api) / 2026-05-27T19:39:09Z (client). source/title conformes.
GHCR : les 2 tags etaient ABSENTS avant build ; aucun docker push effectue. Aucune collision
locale ; aucun manifest GitOps ne reference v3.5.259.

## 3. Tests pre-build

| test | attendu | resultat |
|---|---|---|
| API helper determineAiAssistNotificationSkip (tsc standalone + node) | 15/15 | 15 passed, 0 failed |
| API projet complet tsc --noEmit (worktree) | EXIT 0 | EXIT 0 |
| Client tsc --noEmit (worktree, build-metadata genere, node_modules symlink temporaire) | 0 erreur fichiers touches | EXIT 0 |

Toolchain : keybuzz-api sans jest/ts-node/tsx ; test helper execute par compilation
standalone tsc 5.9.3 + node (meme methode PH-20.42-TER). Client : les seules erreurs initiales
(@/src/lib/build-metadata) venaient du fichier GENERE par le hook prebuild absent d'un worktree
neuf ; apres generation (scripts/generate-build-metadata.py) -> EXIT 0. Symlink node_modules
retire AVANT docker build (lecon PH-20.18) ; worktree restaure porcelain=0.

## 4. Audit API dist (dans l'image)

| marker dist | attendu | resultat |
|---|---|---|
| determineAiAssistNotificationSkip | present | present (noReplyClassifier.js + ai-assist-routes.js) |
| garde amazonIds (BUYER_AMAZON_IDS_PRESENT) | present | present |
| skip message-level (direction='inbound') | present | present |
| reponse skip (NO_REPLY_PLATFORM_NOTIFICATION) | present | present |
| debitKBActions (chemin normal) | present | present |
| hardcode tenant/order/token | absent | absent |

## 5. Audit Client bundle DEV

Script autoritaire scripts/verify-client-bundle-api-url.sh <image> development :
- api-dev.keybuzz.io occurrences : 2
- api.keybuzz.io occurrences : 0
- verdict : OK bundle inlined https://api-dev.keybuzz.io only (EXIT 0)

| marker bundle | attendu | resultat |
|---|---|---|
| https://api-dev.keybuzz.io (base DEV) | >=1 | 2 |
| https://api.keybuzz.io (base PROD) | 0 | 0 |
| Clarity wuk12h9i33 | present (parite DEV) | present |
| marker skipped | present | present |
| texte neutre "Notification systeme" | present | present |
| localhost | benin / baseline | http://localhost:3000/api/auth = fallback interne NextAuth, PRESENT aussi dans l'image DEV courante v3.5.214 (baseline) ; non lie a la base API client |

Incident KEY-302/KEY-263 evite : aucune API PROD inlinee comme base DEV. Incident KEY-325
(Clarity) evite : Clarity wuk12h9i33 conserve, parite avec le runtime DEV courant.

## 6. Build args DEV (Client)

Conformes a docs/BUILD-ARGS.md (guard check-client-build-args.sh passe au build) :
- NEXT_PUBLIC_APP_ENV=development
- NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io
- NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io
- NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33 (passe explicitement pour parite avec le bundle DEV
  courant qui l'embarque deja ; le guard ne l'exige pas en DEV mais l'omettre regresserait Clarity)
- GIT_COMMIT_SHA + IMAGE_REVISION/VERSION/CREATED (OCI)

Autres NEXT_PUBLIC_* (GA4/Meta/SGTM/TikTok) : defauts Dockerfile conserves (convention
BUILD-ARGS.md : seul Clarity est enforce, PROD-only). Aucune valeur secrete (NEXT_PUBLIC =
public).

## 7. No side-effect

- Aucun docker push, deploy, kubectl, DB mutation, migration, fake event/KBActions/ledger.
- GHCR : tags v3.5.259 ABSENTS (verifies post-build).
- Runtime inchange : api-dev v3.5.258, api-prod v3.5.257, client-dev v3.5.214, client-prod
  v3.5.217 (PROD intacte).
- Aucun manifest ne reference v3.5.259. latest non touche.
- Worktrees retires proprement (git worktree remove sans --force, donc clean).
- Backend / autopilot / amzmsg / outbound / tenantGuard non touches (hors scope de ce build).
- message_source=SYSTEM non introduit.

## 8. Limites

- LiteLLM/Anthropic credits DEV : hors scope (action environnement separee) ; la validation
  AI Assist buyer reelle en DEV reste tributaire des credits.
- Aucun deploy : le correctif n'est pas encore actif au runtime DEV.
- Validation runtime (tag platformNotification + skip message-level + parite buyer + UX skip
  neutre) a refaire APRES push image + apply DEV.

## 9. Rollback futur (theorique)

Le build ne modifie aucun runtime : rien a rollback. Au deploiement futur (PH-20.45 apply),
rollback = revert du bump manifest DEV vers v3.5.258 (api) / v3.5.214 (client) + apply.

## 10. Prochaine etape

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV PH-SAAS-T8.12AS.20.44 :
- docker push GHCR + pull-back digest match pour :
  - keybuzz-api:v3.5.259-ai-assist-notification-scope-dev (Image ID sha256:499993fdb18d...)
  - keybuzz-client:v3.5.259-ai-assist-notification-scope-dev (Image ID sha256:8f41c7a48896...)
- latest intact ; puis apply DEV (PH-20.45) + verify runtime. PROD reste bloque jusque-la.

## 11. Phrase cible

GO BUILD AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV READY PH-SAAS-T8.12AS.20.43

STOP.
