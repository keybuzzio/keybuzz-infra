# PH-SAAS-T8.12AS.21.90 - Readonly verify Client onboarding register_started owner payload DEV

Date UTC: 2026-06-22T15:17:16Z

Verdict: READY_WITH_LIMITS

Phrase finale:

`GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV READY_WITH_LIMITS PH-SAAS-T8.12AS.21.90`

## Resume Ludovic

Client DEV runtime conforme sur `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev` avec digest `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9`. Equality OK: manifest = last-applied = deployment spec = pod spec; pod ready et restarts documentes. Audit bundle/pod OK: `register_started`, `marketing_owner_tenant_id`, UTM/click IDs et API DEV presents; API PROD absente; aucun fake trigger direct. Logs sans crash critique ni POST `/funnel/event` attribuable CE. Limite normale: pas de trafic naturel/Ads Manager prouve sans vrai parcours.

## Sources relues

- Mission PH-21.90.
- AI_MEMORY: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD.
- Retours PH-21.89, PH-21.88, PH-21.87.
- Rapports PH-21.89, PH-21.88, PH-21.87, PH-21.86.

## Preflight bastion

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Hostname | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| Date UTC | actuelle | 2026-06-22T15:17:16Z | PASS |
| Kube context | present | kubernetes-admin@kubernetes | PASS |
| Infra branch/dirty | main / 0 | main / 0 | PASS |
| Client branch/HEAD | ph148 / d9631ca087f1 | ph148/onboarding-activation-replay / d9631ca087f1 | PASS |

## Confirmation PH-21.89

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Verdict PH-21.89 | READY | confirme | PASS |
| Manifest | k8s/keybuzz-client-dev/deployment.yaml | present | PASS |
| Runtime tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | PASS |
| Runtime digest | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| No fake events | 0 | confirme par logs/bundle | PASS |

## Runtime equality

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Manifest image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Last-applied image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Deployment spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Pod spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Pod imageID | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 |
| Ready | 1/1 | 1/1 |
| Restarts | documentes | keybuzz-client-5c6f75bf8-7skff:0 |
| Generation / observedGeneration | alignees | 1025 / 1025 |
| Rollout conditions | Available/Progressing OK | Available=True:MinimumReplicasAvailable;Progressing=True:NewReplicaSetAvailable; |

## Logs read-only

| Check | Attendu | Resultat |
| --- | --- | --- |
| Crash critique | 0 | 0 |
| Stack trace / erreurs JS | 0 critique | 0 |
| POST /funnel/event attribuable CE | 0 | 0 |
| Tracking actif inattendu | 0 critique | 0 |
| Secret/token brut candidat | 0 | 0 |

Logs tail redige:

```text
  ▲ Next.js 14.2.35
  - Local:        http://localhost:3000
  - Network:      http://0.0.0.0:3000

 ✓ Starting...
 ✓ Ready in 450ms
```

## Bundle / pod audit

| Marker | Attendu | Resultat | Classification |
| --- | --- | --- | --- |
| https://api-dev.keybuzz.io | present | 87 | PASS |
| https://api.keybuzz.io | absent | 0 | PASS |
| register_started | present | 1 | PASS |
| marketing_owner_tenant_id | present | 3 | PASS |
| utm_source / utm_medium / utm_campaign | present | 1/1/1 | PASS |
| fbclid / gclid / ttclid / li_fat_id | present | 1/1/1/1 | PASS |
| fbq trackCustom trial_page_viewed | absent direct trigger | 0 | PASS |
| StartTrial direct trigger | absent fake trigger | 0 | PASS |
| Purchase direct trigger | absent fake trigger | 0 | PASS |
| CompletePayment direct trigger | absent fake trigger | 0 | PASS |
| complete private key markers | absent | END=0, RSA=0, OPENSSH=0 | PASS |
| token candidates applicatifs | absent | sk_live=0, ghp=0, xoxb=0, EAAG-app=0 | PASS |

## HTTP GET passif

| URL/service | Methode | Attendu | Resultat |
| --- | --- | --- | --- |
| https://client-dev.keybuzz.io/register | GET passif curl sans JS | 200/non vide ou limite documentee | rc_0 http_code=200 size=9285 final_url=https://client-dev.keybuzz.io/register; html_size=9285; next_errors=0 |

## Tracking / DB read-only

| Surface | Avant | Apres | Delta | Verdict |
| --- | --- | --- | --- | --- |
| funnel_events / conversion_events | non lu | non lu | n/a | DB_READONLY_SKIPPED_SAFE_SCOPE |
| Trafic naturel trial_page_viewed | non prouve | non prouve | n/a | NO_NATURAL_TRAFFIC_NOT_PROVEN |

## Non-regression

| Service | Attendu | Resultat |
| --- | --- | --- |
| Client PROD | inchange | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod; ready=1/1; restarts=keybuzz-client-778b4879bf-dtrpj:0 |
| API/Website/Admin/Backend/autres deployments | inchanges | 0 |
| GHCR latest en runtime | absent | count=0 |
| DB mutation | 0 | DB_READONLY_SKIPPED_SAFE_SCOPE |

## No fake metrics / no fake events

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Build Docker | 0 | 0 |
| Docker push | 0 | 0 |
| Deploy / runtime mutation | 0 | 0 |
| Manifest mutation | 0 | 0 |
| DB mutation | 0 | 0 |
| POST /funnel/event | 0 | 0 |
| Event reel/fake | 0 | 0 |
| Formulaire /register | 0 | 0 |
| Checkout Stripe | 0 | 0 |
| Browser JS | 0 | 0 |
| Webflow / Linear | 0 | 0 |

## Dettes / limites

- DB_READONLY_SKIPPED_SAFE_SCOPE: evite toute manipulation DB ou exposition de secret pour cette verification runtime.
- NO_NATURAL_TRAFFIC_NOT_PROVEN: aucune preuve Ads Manager ou vrai parcours utilisateur sans trafic naturel.
- PH-21.90 ne lance pas la cloture PH-21.91.

## Prochain GO

`GO READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.91`
