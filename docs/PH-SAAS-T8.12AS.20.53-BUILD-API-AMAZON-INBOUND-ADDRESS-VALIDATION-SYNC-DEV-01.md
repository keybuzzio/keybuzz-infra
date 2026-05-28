# PH-SAAS-T8.12AS.20.53-BUILD-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.53 (BUILD ONLY - image API DEV du patch sync validation inbound)
> Environnement : DEV preparation / BUILD ONLY ; AUCUN push image, deploy, kubectl, mutation DB, backfill

## 1. Verdict

GO BUILD API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.53

Image API DEV construite localement from-git depuis origin 798db37c (patch PH-20.52). tsc --noEmit
propre (exit 0), tests standalone 23/23 PASS. Image locale presente, labels OCI conformes, markers
dist du patch presents, gates worker/messages intacts. GHCR tag cible non pousse, runtime DEV/PROD
inchange. Reste : revue + GO PUSH IMAGE DEV (PH-20.54).

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels et cette phase n'en cree aucun. Le sujet
est la construction du correctif source de synchronisation de statut Backend -> product DB API.

## 3. Preflight

| repo | branche | HEAD | origin | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 798db37c | origin contient 798db37c (= origin HEAD) | 0 (hors dist) | OK |
| keybuzz-infra | main | 7ced03e | origin | 0 | OK |

Bastion : install-v3, IP 46.62.171.61 (aucune trace 51.159.99.247), date UTC 2026-05-28 ~09:00Z.
GHCR tag cible v3.5.260-amazon-inbound-address-sync-dev : ABSENT avant build. Image locale : ABSENTE
avant build. Aucun manifest k8s ne reference le tag cible.

Runtime avant (inchange par cette phase) : API PROD v3.5.259-ai-assist-notification-scope-prod (1/1,
restarts=0), keybuzz-outbound-worker v3.5.165-escalation-flow-prod (1/1), API DEV
v3.5.259-ai-assist-notification-scope-dev (1/1).

## 4. Source commit

- Repo keybuzz-api, branche ph147.4/source-of-truth.
- Commit exact : 798db37ca108c792a79749b939d9f7420120b7a5 (798db37c).
- Worktree detache propre : /opt/keybuzz/build-worktrees/PH-20.53-api-inbound-address-sync-dev,
  git rev-parse HEAD = 798db37ca108... , git status --porcelain = 0. node_modules committe present.

## 5. Audit source (worktree)

| marker | attendu | resultat |
|---|---|---|
| helper normalizeInboundValidationStatus exporte | present | 1 (src/lib/normalizeInboundValidationStatus.ts) |
| route utilise le helper | present | 2 occurrences (import + appel) |
| ON CONFLICT promote-only validationStatus CASE | present | 1 |
| INSERT VALUES propage $7 (statut) au lieu de PENDING fige | present | 1 |
| worker gate validationStatus='VALIDATED' (outboundWorker) | intact | 1 |
| determineAmazonProvider | present/non modifie | 1 |
| determineAiAssistNotificationSkip (PH-20.49/42-TER) | present | 1 |
| hardcode tenant/token route+helper | 0 | 0 |

## 6. Tests pre-build

| test | attendu | resultat | commentaire |
|---|---|---|---|
| standalone normalizeInboundValidationStatus.test | 23/23 PASS | 23 passed, 0 failed | truth-table + invariants source (promote-only, gates, no hardcode) |
| tsc --noEmit (projet complet) | 0 erreur | exit 0, 0 error TS | node_modules committe, pas de symlink |

## 7. Image

| tag | Image ID | OCI revision | OCI version | created |
|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev | sha256:87c8d01b49fad6862565fb0aed8020dbd6779ece3d217fa113b8b23779d88632 | 798db37ca108c792a79749b939d9f7420120b7a5 | v3.5.260-amazon-inbound-address-sync-dev | 2026-05-28T09:01:21Z |

Build command (depuis worktree propre) :
docker build --build-arg IMAGE_REVISION=798db37ca108... --build-arg
IMAGE_VERSION=v3.5.260-amazon-inbound-address-sync-dev --build-arg IMAGE_CREATED=2026-05-28T09:01:21Z
-t ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev .

OCI source label : https://github.com/keybuzzio/keybuzz-api. latest non touche.

## 8. Markers dist (dans l'image)

| marker | count/resultat | verdict |
|---|---|---|
| dist/lib/normalizeInboundValidationStatus.js | 2 | present |
| dist/modules/channels/channelsRoutes.js utilise le helper | 2 | present |
| ON CONFLICT promote-only validationStatus CASE (channelsRoutes.js) | 1 | present |
| marketplaceStatus (channelsRoutes.js) | 2 | present |
| worker gate validationStatus='VALIDATED' (outboundWorker.js) | 1 | intact |
| determineAmazonProvider (dist) | 3 | present/non modifie |
| determineAiAssistNotificationSkip (dist) | 2 | present |
| hardcode tenant/token dans les 2 fichiers du patch (channelsRoutes.js + helper) | 0 | OK |

Note transparence (hardcode dist-wide) : un grep dist-wide remonte 8 occurrences de tokens, TOUTES
pre-existantes et hors patch PH-20.52 :
- dist/tests/ph115/116/117-tests.js : ecomlg-001 (fixtures de tests historiques) ;
- dist/tests/ph119-tests.js : noreply@ (fixture) ;
- dist/services/safeRealExecutionEngine.js : ecomlg-001 (pre-existant) ;
- dist/services/emailService.js, dist/modules/public/contact.js,
  dist/modules/auth/space-invites-routes.js : noreply@ (defauts email SaaS generiques, sans rapport
  avec le From Amazon qui reste l'adresse connecteur validee).
Les 2 fichiers reellement modifies/ajoutes par le patch (channelsRoutes.js, helper) contiennent 0
token. Le patch n'introduit aucun hardcode ni noreply. Ces 8 occurrences sont identiques a l'image
v3.5.259 (le patch ne change que channelsRoutes.js + ajoute le helper).

## 9. AI feature parity / anti-regression

| invariant | etat |
|---|---|
| PH-20.49 AI Assist (determineAiAssistNotificationSkip) | present dans dist, non touche |
| reply path / route messages gate validationStatus | intact |
| outbound worker gate validationStatus='VALIDATED' | intact (non affaibli) |
| determineAmazonProvider | present, non modifie |
| noreply@ comme From Amazon | non introduit (From = adresse connecteur validee) |
| KBActions / couts LLM | non touches |
| Client / backend / outbound-worker runtime | hors scope, non touches |

## 10. No side-effect

| signal | attendu | resultat | verdict |
|---|---|---|---|
| GHCR tag cible | absent (non pousse) | absent | OK |
| docker push | aucun | aucun | OK |
| deploy / kubectl mutation | aucun | aucun (kubectl get read-only seulement) | OK |
| DB write / backfill | aucun | aucun | OK |
| runtime API PROD | inchange | v3.5.259, 1/1, restarts=0 | OK |
| runtime API DEV | inchange | v3.5.259, 1/1 | OK |
| manifests k8s | sans tag cible | aucun ref | OK |
| worktree | retire proprement | removed (0 restant) | OK |
| image locale | conservee | 87c8d01b49fa presente | OK |
| fake metric/event | aucun | aucun | OK |

## 11. Rollback / no runtime

Aucun changement runtime dans cette phase (BUILD ONLY). Rien a rollback. L'image locale peut etre
supprimee sans impact (docker rmi) si le build doit etre refait. Aucune image PROD/DEV deployee
n'est modifiee.

## 12. Prochaine action

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV PH-SAAS-T8.12AS.20.54 : docker push du
tag v3.5.260-amazon-inbound-address-sync-dev sur GHCR + pull-back digest, puis (phase separee)
GitOps apply DEV, re-test envoi ecomlg-motxke32, backfill Option A (re-declenchement du sync, zero
SQL manuel). PROD reste bloquee jusqu'a validation DEV complete.

## 13. Phrase cible

GO BUILD API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.53

STOP.
