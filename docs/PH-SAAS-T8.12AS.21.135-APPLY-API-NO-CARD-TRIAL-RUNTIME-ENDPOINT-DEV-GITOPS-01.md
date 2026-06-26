# PH-SAAS-T8.12AS.21.135 - APPLY API NO-CARD TRIAL RUNTIME ENDPOINT DEV GITOPS

Date UTC: 2026-06-26T19:32:00Z
Scope: APPLY API DEV GitOps only
Verdict: READY_WITH_DEBTS

## RESUME LUDOVIC

1. API DEV appliquee via GitOps strict: `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev`.
2. Manifest GitOps commit/push avant apply: `3995c873ddc5f859e64689770fd0ce03281b3e4d`.
3. Apply execute uniquement avec `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`; rollout successful.
4. Runtime digest OK: `sha256:508054e5cb15790a284a750cea813b71874128e4a5a2775d0c5a78061b3a5da4`.
5. Equality OK: manifest Git = last-applied = deployment spec = pod spec = pod imageID.
6. API DEV Ready 1/1, pod `keybuzz-api-54f7b654fb-58fxb`, Running, restarts 0, health OK.
7. Markers in-pod OK: no-card-trial, trialing, KBActions, StartTrial/Purchase/CompletePayment, PROVIDER_CREDIT_EXHAUSTED.
8. Logs: pas de crash/fatal/panic; mention benign `mounted secrets` sans valeur sensible.
9. Non-regression: API PROD, Client DEV/PROD, Website DEV/PROD, Admin, Backend inchanges; backfill-scheduler dette SRE separee.
10. Aucun build, docker push, DB runtime write volontaire, Stripe call, fake event, Webflow, Linear ou PROD mutation.
11. Prochain GO: `GO READONLY VERIFY API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.136`.

## VERDICT

`READY_WITH_DEBTS`

Phrase finale:

`GO APPLY API NO-CARD TRIAL RUNTIME ENDPOINT DEV GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.135`

## GITOPS

| Check | Resultat |
| --- | --- |
| Manifest modifie | `k8s/keybuzz-api-dev/deployment.yaml` uniquement |
| Image avant | `v3.5.266-no-card-trial-launch-pricing-dev` |
| Image apres | `v3.5.267-no-card-trial-runtime-endpoint-dev` |
| Rollback documente | `v3.5.266-no-card-trial-launch-pricing-dev` |
| Commit deploy | `3995c873ddc5f859e64689770fd0ce03281b3e4d` |
| Dry-run client/server | PASS |
| Apply | `kubectl apply -f` uniquement |
| Rollout | successful |

## RUNTIME

| Champ | Resultat |
| --- | --- |
| Deployment image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev` |
| Last-applied image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev` |
| Pod image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:508054e5cb15790a284a750cea813b71874128e4a5a2775d0c5a78061b3a5da4` |
| Ready | `1/1` |
| Generation | `506/506` |
| Pod | `keybuzz-api-54f7b654fb-58fxb` |
| Restarts | `0` |
| Health | OK |

## MARKERS IN-POD

| Marker | Resultat |
| --- | --- |
| `no-card-trial` | OK |
| `requiresCardAtStart` | OK |
| `stripeRequiredAtStart` | OK |
| `billingStatus` | OK |
| `trialing` | OK |
| `trial_ends_at` | OK |
| `getPlanIncludedKBActions` | OK |
| `StartTrial` | OK |
| `Purchase` | OK |
| `CompletePayment` | OK |
| `PROVIDER_CREDIT_EXHAUSTED` | OK |

## NO FAKE METRICS / NO FAKE EVENTS

| Surface | Resultat |
| --- | --- |
| StartTrial/Purchase/CompletePayment | Aucun event cree ou redefini par CE |
| POST `/funnel/event` | 0 |
| CAPI/GA4/TikTok/LinkedIn | 0 |
| Stripe/checkout | 0 |
| DB runtime write volontaire | 0 |

## AI FEATURE PARITY / ANTI-REGRESSION

| Point | Resultat |
| --- | --- |
| KBActions | Marker `getPlanIncludedKBActions` present in-pod |
| Provider credit watcher | Marker `PROVIDER_CREDIT_EXHAUSTED` present in-pod |
| StartTrial/Purchase/CompletePayment | Markers presents in-pod |
| Meta CAPI observability | Non modifiee |
| Inbox/messages/connecteurs | Non touches |

## NON-REGRESSION

| Service | Resultat |
| --- | --- |
| API DEV | image attendue v3.5.267, Ready 1/1 |
| API PROD | inchange v3.5.265-meta-capi-error-observability-prod |
| Client DEV/PROD | inchange v3.5.260 |
| Website DEV/PROD | inchange |
| Admin DEV/PROD | inchange |
| Backend DEV/PROD | inchange hors dette backfill-scheduler deja connue |

## NO SIDE-EFFECT

Aucun build, docker push, kubectl set image/env/patch/edit, DB runtime write volontaire, Stripe live call, checkout, fake event, replay, Webflow, Linear ou mutation PROD.

## DETTES

| Dette | Suite |
| --- | --- |
| Dirty API `dist/` preexistant | Cleanup dedie separe |
| Client pas encore branche sur endpoint no-card | Phase Client suivante |
| Backfill-scheduler ready `<none>/1` | Dette SRE separee, hors scope |

## PROCHAIN GO

`GO READONLY VERIFY API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.136`

STOP
