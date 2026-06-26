# PH-SAAS-T8.12AS.21.141 - APPLY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV GITOPS

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: READY_WITH_DEBTS PH-SAAS-T8.12AS.21.141.

Client DEV applique via GitOps strict:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev`

Digest runtime:

`sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597`

Manifest GitOps:

- Fichier modifie uniquement: `k8s/keybuzz-client-dev/deployment.yaml`
- Commit deploy: `e4bb62dc010c144b51a26f2282c6907f645aa9d3`
- Push avant apply: PASS

Apply:

- `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`
- `rollout status`: successful
- Pod: `keybuzz-client-956c4f894-kxgq9`
- Ready: `1/1`
- Restarts: `0`

Equality runtime:

- manifest Git = last-applied = deployment spec = pod image: PASS
- pod imageID = digest GHCR: PASS

Dette mineure:

- Le script initial PH-21.141 a echoue apres le rollout sur une lecture JSON runtime mal pipee. Une post-verification read-only corrigee a ete executee et confirme le runtime. Aucun rollback requis, aucune dette runtime.

No fake metrics / no fake events:

- Aucun POST `/funnel/event`
- Aucun formulaire
- Aucun checkout Stripe
- Aucun StartTrial/Purchase/CompletePayment fake
- Aucune DB mutation volontaire

Prochain GO:

`GO READONLY VERIFY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.142`

STOP.

## PREFLIGHT

| Controle | Attendu | Resultat |
|---|---|---|
| Repo infra | `/opt/keybuzz/keybuzz-infra` | PASS |
| Branche | `main` | PASS |
| Ahead/behind avant deploy | `0/0` | PASS |
| Manifest modifie | `k8s/keybuzz-client-dev/deployment.yaml` uniquement | PASS |
| Dry-run client | PASS | PASS |
| Dry-run server | PASS | PASS |
| Commit + push avant apply | obligatoire | PASS |

## GITOPS

| Element | Valeur |
|---|---|
| Ancienne image | `v3.5.260-onboarding-register-started-owner-payload-dev` |
| Nouvelle image | `v3.5.261-no-card-trial-onboarding-dev` |
| Deploy commit | `e4bb62dc010c144b51a26f2282c6907f645aa9d3` |
| Manifest digest attendu | `sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597` |
| Rollback image | `v3.5.260-onboarding-register-started-owner-payload-dev` |

## RUNTIME

| Controle | Resultat |
|---|---|
| Deployment image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| Last-applied image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| Generation | `1026/1026` |
| Ready replicas | `1/1` |
| Pod | `keybuzz-client-956c4f894-kxgq9` |
| Pod phase | `Running` |
| Pod ready | `True` |
| Pod restarts | `0` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-client@sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597` |

## NON-REGRESSION

| Surface | Resultat |
|---|---|
| API DEV/PROD | inchanges |
| Client PROD | inchange |
| Website DEV/PROD | inchanges |
| Admin DEV/PROD | inchanges |
| Backend DEV/PROD | inchanges |
| GHCR latest | intact |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| POST `/funnel/event` | `0` |
| Formulaire | `0` |
| Checkout Stripe | `0` |
| CAPI test/replay | `0` |
| DB mutation volontaire | `0` |

## VERDICT

`GO APPLY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.141`

STOP.
