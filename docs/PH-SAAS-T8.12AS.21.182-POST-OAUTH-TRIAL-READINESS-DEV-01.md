# PH-SAAS-T8.12AS.21.182 - Post-OAuth trial readiness DEV

## Verdict

READY_DEV_APPLIED.

DEV a ete corrige, build, pousse, applique et verifie pour les points observes apres onboarding no-card trial:

- compteur canaux mis a jour immediatement apres retour OAuth Amazon;
- synchronisation initiale des commandes Amazon sur 3 mois en arriere-plan apres OAuth;
- playbooks IA starter actifs en mode suggestion pour les nouveaux essais;
- reparation automatique des playbooks starter existants inactifs lors de la lecture `/playbooks`;
- suppression du bouton "Choisir mon forfait" dans le bandeau d'essai quand la carte est deja ajoutee;
- infobulle Focus mode au premier affichage;
- runtime DEV API/Client verifie par GitOps strict.

PROD n'a pas ete modifiee pendant cette phase. Promotion PROD requiert un GO explicite.

## Source

| Repo | Branche | Commit | Statut |
| --- | --- | --- | --- |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `f349118c09db2228847575322669fae3c7577000` | push OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `85c580a9dc4727edc1b742a1fbde62adbae5d0e7` | push OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `485a3f5a4f33daa006a03e02a4d1d15d10e767f6` | push OK |
| `keybuzz-infra` | `main` | `2d3e240` | manifest API 276 + Client 268 |
| `keybuzz-infra` | `main` | `fdd2b42` | manifest API 277 |

## Patch Client

| Fichier | Changement |
| --- | --- |
| `app/channels/page.tsx` | compteur base sur les canaux actifs affiches, refetch plan, refresh differe post-OAuth, sync commandes 3 mois en fond |
| `src/services/amazon.service.ts` | `startAmazonInitialOrdersSync(3)` via `/api/orders/sync-all`, nettoyage `expected_channel` |
| `src/features/billing/components/TrialBanner.tsx` | CTA affiche uniquement si `requiresCheckout=true`; plus de "Choisir mon forfait" apres CB |
| `src/components/layout/ClientLayout.tsx` | hint Focus mode auto-dismiss 7s, memorise par tenant |
| `scripts/ph21182-post-oauth-trial-ux.test.cjs` | test source anti-regression |

## Patch API

| Fichier | Changement |
| --- | --- |
| `src/services/playbook-seed.service.ts` | starters crees `active` en mode `suggest`; repair scoped no-card trial si tous starters inactifs |
| `src/modules/playbooks/routes.ts` | `GET /playbooks` appelle le seed/repair avant lecture |
| `src/tests/ph21182-starter-playbook-activation-tests.ts` | test seed active/safe |
| `src/tests/ph21182-playbooks-read-repair-tests.ts` | test repair au chargement `/playbooks` |

## Tests source

| Repo | Test | Resultat |
| --- | --- | --- |
| Client | `node scripts/ph21182-post-oauth-trial-ux.test.cjs` | PASS |
| Client | `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| Client | `npx eslint ...fichiers touches...` | PASS |
| Client | `npx tsc --noEmit --incremental false --pretty false` | PASS |
| API | `npx ts-node src/tests/ph21182-starter-playbook-activation-tests.ts` | PASS |
| API | `npx ts-node src/tests/ph21182-playbooks-read-repair-tests.ts` | PASS |
| API | `npx ts-node src/tests/ph21177-activate-amazon-idempotent-tests.ts` | PASS |
| API | `npx ts-node src/tests/ph21172-start-latency-tests.ts` | PASS |
| API | `npx tsc --noEmit` | PASS |
| Tous | `git diff --check` | PASS |

Note: `scripts/ph21160-register-no-plan-selection.test.cjs` reste stale/preexistant car il attend une redirection dashboard directe, remplacee par PH-21.172.

## Images DEV

| Service | Image | Digest GHCR | Source |
| --- | --- | --- | --- |
| API DEV final | `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-dev` | `sha256:2786b32176cf9727050e7b69117a2685da77b75eaded1f68af825d72d8fbf45a` | `485a3f5a4f33daa006a03e02a4d1d15d10e767f6` |
| Client DEV final | `ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-dev` | `sha256:c6a6c43c8b4a20c082eb2974a8024a7631e139e302f1ce334e248c84bb512a0b` | `f349118c09db2228847575322669fae3c7577000` |

Image API intermediaire `v3.5.276-post-oauth-trial-readiness-dev` poussee puis remplacee par API 277 avant cloture DEV.

## Image audits

| Controle | Resultat |
| --- | --- |
| API seed active/suggest present | PASS |
| API playbooks read repair present | PASS |
| API dist/tests absent | PASS |
| Client API DEV marker present | PASS |
| Client API PROD marker absent | PASS |
| Client `amazon_oauth_initial_sync` present | PASS |
| Client `Mode Focus actif` present | PASS |

## GitOps DEV

| Fichier | Changement final |
| --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.275` -> `v3.5.277-playbooks-read-repair-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.267` -> `v3.5.268-post-oauth-trial-readiness-dev` |

Dry-run client/server: PASS API + Client.

Apply:

- `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`
- `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`
- rollout API DEV successful
- rollout Client DEV successful

## Runtime DEV final

| Service | Image runtime | Digest runtime | Ready | Restarts | Generation |
| --- | --- | --- | --- | --- | --- |
| API DEV | `v3.5.277-playbooks-read-repair-dev` | `sha256:2786b32176cf9727050e7b69117a2685da77b75eaded1f68af825d72d8fbf45a` | 1/1 | 0 | 518/518 |
| Client DEV | `v3.5.268-post-oauth-trial-readiness-dev` | `sha256:c6a6c43c8b4a20c082eb2974a8024a7631e139e302f1ce334e248c84bb512a0b` | 1/1 | 0 | 1032/1032 |

Equality:

- manifest Git = deployment spec = last-applied = pod image digest: PASS.

Smoke passif:

| Route | Resultat |
| --- | --- |
| API `/health` interne | OK |
| `https://client-dev.keybuzz.io/register` | 200 |
| `https://client-dev.keybuzz.io/login` | 200 |
| `https://client-dev.keybuzz.io/start` hors session | 307 attendu |

Logs critiques 5 min:

- API DEV: 0
- Client DEV: 0

## No fake metrics / no fake events

- 0 formulaire lance par CE.
- 0 checkout Stripe.
- 0 POST `/funnel/event`.
- 0 fake StartTrial/Purchase/CompletePayment.
- 0 event media buyer.
- 0 mutation DB volontaire hors comportement applicatif attendu.
- 0 Webflow / Meta Ads / Linear.
- 0 secret lu/affiche volontairement.

## Points produit couverts

| Demande | Statut DEV |
| --- | --- |
| Compteur canaux a jour apres retour Amazon | Corrige cote Client |
| Sync commandes 3 derniers mois en fond apres Amazon | Corrige cote Client, non bloquant |
| Garder sync manuelle avec choix de duree | Preserve |
| 15 playbooks IA actifs | Corrige pour nouveaux essais + repair au chargement `/playbooks` |
| Agent KeyBuzz gate apres CB | Non modifie, comportement PROD deja valide par Ludovic |
| Focus mode hint | Ajoute |
| Bandeau essai apres CB sans bouton choix plan | Corrige |

## Limites

- La verification automatique de repair playbooks avec appel direct pod retourne 401 hors session applicative; c'est attendu. Le chemin reel passe par Client BFF avec session utilisateur.
- PROD non modifiee dans cette phase.

## Rollback DEV

| Service | Rollback |
| --- | --- |
| API DEV | `v3.5.276-post-oauth-trial-readiness-dev` puis `v3.5.275-ai-journal-startup-ddl-dev` si besoin |
| Client DEV | `v3.5.267-start-onboarding-latency-dev` |

Procedure rollback: patch manifest, commit + push infra, `kubectl apply -f`, rollout status, verify runtime.

## Prochaine phase

Si validation DEV OK: `GO READONLY DESIGN POST-OAUTH TRIAL READINESS PROD PROMOTION SAFETY PH-SAAS-T8.12AS.21.183`.

STOP.
