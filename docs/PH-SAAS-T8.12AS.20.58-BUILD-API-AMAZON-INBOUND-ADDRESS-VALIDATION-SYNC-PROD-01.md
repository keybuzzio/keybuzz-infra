# PH-SAAS-T8.12AS.20.58-BUILD-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-PROD-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.58 (BUILD ONLY - image API PROD du patch sync validation inbound)
> Environnement : PROD preparation / BUILD ONLY ; AUCUN push, deploy, kubectl, mutation DB, trigger, OAuth

## 1. Verdict

GO BUILD API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD READY PH-SAAS-T8.12AS.20.58

Image API PROD construite localement from-git depuis origin 798db37c (patch PH-20.52). tsc --noEmit
exit 0, tests standalone 23/23 PASS. Image locale presente, labels OCI conformes, markers dist du
patch presents, gates worker/messages intacts, AI Assist skip + determineAmazonProvider presents.
GHCR tag PROD cible NON pousse, runtime DEV/PROD inchange, PROD strictement intacte. Reste : revue +
GO PUSH IMAGE PROD (PH-20.59).

## 2. Rappel UX

Pas de bouton de validation Amazon dans Channels (n'existe pas). Le sujet est la synchronisation de
statut Backend -> Product/API DB. Cette phase ne demande aucune action utilisateur, aucun
reconnect OAuth.

## 3. Preflight

| repo/service | branche/image attendue | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth, origin contient 798db37c | origin HEAD = 798db37ca108... | 0 (hors dist) | OK |
| keybuzz-infra | main | main 27eb9fe | dirty 0 | OK |
| API DEV | v3.5.260-amazon-inbound-address-sync-dev | idem (1/1) | - | OK |
| API PROD | v3.5.259-ai-assist-notification-scope-prod | idem (1/1) | restarts=0 | intact |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | idem (1/1) | - | intact |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | idem | - | intact |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | idem | - | intact |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). GHCR tag PROD cible
v3.5.260-amazon-inbound-address-sync-prod : ABSENT avant build. Image locale absente. Aucun manifest
k8s ne reference le tag cible.

## 4. Source Git (commit 798db37c)

Worktree detache propre : /opt/keybuzz/build-worktrees/PH-20.58-api-inbound-address-sync-prod,
git rev-parse HEAD = 798db37ca108c792a79749b939d9f7420120b7a5, git status --porcelain = 0.
node_modules committe present. Retire proprement apres build.

| brique | fichier | point verifie | resultat |
|---|---|---|---|
| helper | src/lib/normalizeInboundValidationStatus.ts | export normalizeInboundValidationStatus | present (1) |
| route | src/modules/channels/channelsRoutes.ts | usage helper | present (2) |
| promote-only | channelsRoutes.ts | ON CONFLICT validationStatus CASE WHEN $7 | present (1) |
| worker gate | src/workers/outboundWorker.ts | validationStatus='VALIDATED' | intact (1) |
| messages gate | src/modules/messages/routes.ts | validationStatus='VALIDATED' | intact (1) |
| provider | src/lib/determineAmazonProvider.ts | export determineAmazonProvider | present (1) |
| AI Assist skip | src/services/noReplyClassifier.ts | export determineAiAssistNotificationSkip | present (1) |
| hardcode tenant/token (route+helper) | - | ecomlg-motxke32/as0yom/ecomlg-001/4xfub8/noreply@ | 0 |

## 5. Tests pre-build

| test | attendu | resultat | verdict |
|---|---|---|---|
| tsc --noEmit (projet) | 0 erreur | exit 0, 0 error TS | OK |
| standalone normalizeInboundValidationStatus.test | 23/23 PASS | 23 passed, 0 failed | OK |

Aucun test ne touche PROD, aucun fake event/KBActions.

## 6. Build from-git PROD

| image | tag | Image ID | revision | created | verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api | v3.5.260-amazon-inbound-address-sync-prod | sha256:ac854f025cdfba6aed7e731fb4839180593a5f6614ac471566d8782cd8239888 | 798db37ca108c792a79749b939d9f7420120b7a5 | 2026-05-28T10:58:20Z | OK |

Build command (worktree propre) : docker build --build-arg IMAGE_REVISION=798db37ca108... --build-arg
IMAGE_VERSION=v3.5.260-amazon-inbound-address-sync-prod --build-arg IMAGE_CREATED=2026-05-28T10:58:20Z
-t ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod .

OCI source label : https://github.com/keybuzzio/keybuzz-api. latest non touche. Pas de push.

Note : l'image API ne contient pas de build-arg d'environnement (URL/cle) - contrairement au client.
Le dist PROD est donc fonctionnellement identique a l'image DEV v3.5.260 deja validee (PH-20.53/55/56,
meme commit 798db37c) ; seuls le label OCI version et le created different.

## 7. Audit image / dist markers

| marker | attendu | resultat | verdict |
|---|---|---|---|
| dist/lib/normalizeInboundValidationStatus.js | present | 2 | OK |
| route utilise le helper (channelsRoutes.js) | present | 2 | OK |
| ON CONFLICT promote-only validationStatus CASE | present | 1 | OK |
| validationStatus propagation (route) | present | 2 | OK |
| worker gate validationStatus='VALIDATED' (outboundWorker.js) | present | 1 | OK |
| messages gate validationStatus='VALIDATED' (routes.js) | present | 1 | OK |
| determineAmazonProvider | present | 3 | OK |
| determineAiAssistNotificationSkip (AI Assist skip) | present | 2 | OK |
| message_source=SYSTEM introduit par erreur (route) | absent | 0 | OK |
| hardcode tenant/token dans les 2 fichiers du patch | 0 | 0 | OK |

Note transparence : un grep dist-wide remonte les memes ~8 occurrences pre-existantes hors patch que
PH-20.53 (fixtures de tests ph115-119 + defauts email SaaS generiques emailService/contact/
space-invites) ; les 2 fichiers reellement touches par le patch (channelsRoutes.js, helper) = 0 token.

## 8. No side-effect

| signal | before | after | delta | verdict |
|---|---|---|---|---|
| GHCR tag cible PROD | absent | absent | 0 | OK (non pousse) |
| latest API (sha256sum manifest) | 71d7e988869441ff... | 71d7e988869441ff... | 0 | OK (intact) |
| runtime API PROD | v3.5.259, 1/1, restarts=0 | idem | 0 | OK |
| runtime API DEV | v3.5.260-dev | idem | 0 | OK |
| Client/Backend/outbound-worker PROD+DEV | inchanges | inchanges | 0 | OK |
| manifests GitOps | sans tag cible | aucun ref | 0 | OK |
| mutation DB / trigger / outbound / OAuth | aucun | aucun | 0 | OK |
| fake metric/event/KBActions | aucun | aucun | 0 | OK |

worktree retire (0 restant), image locale conservee (ac854f025cdf).

## 9. AI feature parity / anti-regression

| feature | source de verite | preuve build/image | verdict |
|---|---|---|---|
| advisory lock Amazon inbound (PH-20.26/34-BIS) | backend (hors API) | ce build API ne le touche pas | OK |
| AI Assist notification skip message-level (PH-20.42-TER/49) | noReplyClassifier | determineAiAssistNotificationSkip present dist (2) | OK |
| generation AI Assist + KBActions (PH-20.46-QUATER) | ai-assist | rien dans ce build ne modifie credits/provider | OK |
| worker outbound gate VALIDATED (PH-20.50/51) | outboundWorker | gate present dist (1), non contourne | OK |
| determineAmazonProvider | provider unifie SMTP | present dist (3) | OK |
| Client UI / Autopilot / billing / tracking | hors scope | non touches (API only) | OK |
| bouton validation Channels | n/a | aucun invente | OK |

## 10. Limites

- BUILD ONLY : aucune preuve runtime PROD (image non poussee/non deployee). Le fix PROD ne prend
  effet qu'apres push (PH-20.59) + apply GitOps PROD (phase dediee, GO explicite) + trigger bridge
  PROD (flux produit/session, GO explicite).
- as0yom PROD reste non corrige ; ne pas conclure que l'outbound ecomlg-motxke32 est repare.

## 11. Rollback futur

Aucun rollback runtime necessaire dans PH-20.58 (aucun deploy). Si deploy PROD futur : rollback GitOps
par revert du commit manifest futur vers v3.5.259-ai-assist-notification-scope-prod ; jamais
kubectl set image.

## 12. Prochain GO recommande

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD PH-SAAS-T8.12AS.20.59 : docker push du
tag v3.5.260-amazon-inbound-address-sync-prod sur GHCR + pull-back digest match. Puis (phases dediees,
GO explicite) GitOps apply API PROD, puis trigger bridge PROD as0yom via le flux produit (session),
before/after DB, 0 SQL manuel.

## 13. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.58_CE_RETURN.md

## 14. Phrase cible

GO BUILD API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD READY PH-SAAS-T8.12AS.20.58

STOP.
