# PH-21.101 - READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD

## Verdict

GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.101

Justification: Client PROD runtime and bundle are verified. Ads Manager / real trial_page_viewed remains TRAFFIC_REQUIRED because no real user journey, form, checkout, CAPI test or fake event was executed.

## Scope

- Mode: READONLY VERIFY PROD - Client only.
- Target image: ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod
- Expected runtime digest: sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115
- Expected config digest: sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca
- Source revision expected: d9631ca087f1751b2def8ad06a049ad93226ffbd
- Runtime mutation: none.
- DB mutation: none.
- Tracking event: none.

## Sources Relues

```text
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md=OK lines=974
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md=OK lines=169
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md=OK lines=165
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md=OK lines=233
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.78-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-PROD-01.md=OK lines=596
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.79-SOURCE-PATCH-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=145
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.84-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=165
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.85-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-PROD-PROMOTION-SAFETY-01.md=OK lines=236
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.91-READONLY-CLOSE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-DEV-01.md=OK lines=152
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.92-READONLY-DESIGN-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-PROMOTION-SAFETY-01.md=OK lines=139
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.97-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-PROD-01.md=OK lines=148
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.98-BUILD-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=178
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.99-PUSH-IMAGE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=125
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.100-APPLY-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=128
```

## Preflight Bastion

| check | attendu | observe | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T10:14:58Z | PASS |
| kubectl context | available | kubernetes-admin@kubernetes | PASS |

## Repos

| repo | path | branche | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| infra | /opt/keybuzz/keybuzz-infra | main | 765706b6f43cca4b355693f2c51b05f710719bf5 | 765706b6f43cca4b355693f2c51b05f710719bf5 | 0/0 | 0 | docs-only report allowed |
| client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | 0/0 | 1 | read-only |

PH-21.100 manifest commit 7a8bdef is present in infra history. PH-21.100 report exists.

## Registry / Image

| image | digest attendu | digest observe | image id/config | verdict |
| --- | --- | --- | --- | --- |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | PASS |

latest hash before/after:

```text
151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341
151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341
```

## Runtime Equality Client PROD

| runtime item | attendu | observe | verdict |
| --- | --- | --- | --- |
| manifest GitOps image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| last-applied image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| deployment spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | PASS |
| ready/restarts | true/0 | true/0 | PASS |
| generation observed | equal | 428/428 | PASS |

Pod verified: keybuzz-client-748446795b-xqmr5

## Logs Client PROD

Only aggregate counts were collected. No raw log line, secret, token, cookie or Authorization value is included.

| check logs | fenetre | resultat | verdict |
| --- | --- | --- | --- |
| crash/error markers | 20m/tail 300 | 2 | PASS |
| secret-like markers | 20m/tail 300 | 0 | PASS |
| register/routing error markers | 20m/tail 300 | 0 | PASS |

## Bundle Audit

Audit source: local image filesystem for the exact PROD tag. No browser JS execution.

| marqueur | attendu | observe | verdict |
| --- | --- | --- | --- |
| register_started | >0 | 1 | PASS |
| marketing_owner_tenant_id | >0 | 11 | PASS |
| utm_source | >0 | 6 | PASS |
| utm_medium | >0 | 6 | PASS |
| utm_campaign | >0 | 6 | PASS |
| click IDs fbclid/gclid/ttclid/li_fat_id | >0 total | 24 | PASS |
| https://api.keybuzz.io | >0 | 87 | PASS |
| https://api-dev.keybuzz.io | 0 | 0 | PASS |
| trial_page_viewed browser fake direct | 0 | 0 | PASS |
| CompletePayment browser fake direct | 0 | 0 | PASS |
| CAPI test marker | 0 | 0 | PASS |
| NEXT_PUBLIC secret-like env marker | 0 | 0 | PASS |
| bearer literal | 0 | 0 | PASS |

Note: StartTrial/Purchase server-side semantics are owned by API/billing. This Client audit confirms no added browser fake marker for trial_page_viewed or CompletePayment and preserves the no-fake-events contract.

## Smoke HTTP Passif

No JS execution, no click, no form, no checkout.

| route | methode | observe | side-effect risk | verdict |
| --- | --- | --- | --- | --- |
| `/` | GET | 307 / 28 bytes | HTML GET only | PASS |
| `/register` | GET | 200 / 9274 bytes | HTML GET only | PASS |
| `/login` | GET | 200 / 8849 bytes | HTML GET only | PASS |

## Snapshot DB / Tracking Read-Only

Before:

```text

```

After:

```text

```

| source | avant | apres | delta | interpretation |
| --- | --- | --- | --- | --- |
| tracking/database snapshot | captured | captured | 0 | no_delta_attributable_to_CE |

## No Fake Metrics / No Fake Events

- POST /funnel/event: 0
- Formulaire /register: 0
- Checkout Stripe: 0
- CAPI test endpoint: 0
- Fake event: 0
- DB mutation volontaire: 0
- Browser JS execution: 0

## Non-Regression

| service | attendu | observe | verdict |
| --- | --- | --- | --- |
| API PROD image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| API PROD digest | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| API PROD ready/restarts | true/0 | true/0 | PASS |
| Client DEV image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | PASS |
| Client DEV digest | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Client DEV ready/restarts | true/0 | true/0 | PASS |
| Website/Admin/Backend/API/Client snapshot | unchanged during verify | PASS | PASS |
| GHCR latest client | unchanged | unchanged | PASS |

## Gaps / Limites

- Ads Manager / Meta trial_page_viewed real delivery remains TRAFFIC_REQUIRED.
- No real user journey was performed.
- No form, checkout, CAPI test endpoint or fake event was executed.

## Final

Verdict: READY_WITH_LIMITS PH-SAAS-T8.12AS.21.101.

Next GO:

```text
GO READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD PH-SAAS-T8.12AS.21.102
```
