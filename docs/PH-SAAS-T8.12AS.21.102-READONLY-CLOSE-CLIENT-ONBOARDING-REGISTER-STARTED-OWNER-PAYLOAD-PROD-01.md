# PH-21.102 - READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD

## Verdict

GO READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.102

The PROD chain is technically closed: API PROD contains the server-side trial_page_viewed path from register_started and Client PROD contains the register_started owner/attribution payload. The remaining limit is TRAFFIC_REQUIRED for real Ads Manager / Meta proof.

## Context And Scope

- GO: GO READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD PH-SAAS-T8.12AS.21.102
- Mode: READONLY CLOSE PROD.
- Runtime mutation: none.
- Kubernetes mutation: none.
- DB mutation: none.
- Tracking event: none.
- Form/checkout/CAPI test: none.
- Webflow/Linear: none.
- Allowed mutation: docs-only report in keybuzz-infra.

## Sources Relues

```text
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md=OK lines=974 summary=present
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md=OK lines=169 summary=present
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md=OK lines=165 summary=present
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md=OK lines=233 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.78-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-PROD-01.md=OK lines=596 summary=GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PROD READY_SOURCE_PATCH_REQUIRED PH-SAAS-T8.12AS.21.78
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.79-SOURCE-PATCH-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=145 summary=Verdict: READY_WITH_DEBTS - SOURCE PATCH DEV LOCAL DONE PH-SAAS-T8.12AS.21.79
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.84-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=165 summary=- Verdict: READY_WITH_LIMITS.
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.85-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-PROD-PROMOTION-SAFETY-01.md=OK lines=236 summary=Verdict: READY_FOR_SOURCE_PATCH
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.91-READONLY-CLOSE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-DEV-01.md=OK lines=152 summary=Verdict: READY_WITH_LIMITS
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.92-READONLY-DESIGN-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-PROMOTION-SAFETY-01.md=OK lines=139 summary=Verdict: READY_API_PROD_FIRST.
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.97-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-PROD-01.md=OK lines=148 summary=GO BUILD CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD PH-SAAS-T8.12AS.21.98
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.98-BUILD-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=178 summary=Verdict: READY
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.99-PUSH-IMAGE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=125 summary=Verdict: DONE
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.100-APPLY-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=128 summary=Verdict: READY_WITH_LIMITS
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.101-READONLY-VERIFY-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=181 summary=GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.101
```

## Preflight Bastion

| check | attendu | observe | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T11:25:46Z | PASS |
| kubectl context | available | kubernetes-admin@kubernetes | PASS |

## Repos

| repo | path | branche | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| infra | /opt/keybuzz/keybuzz-infra | main | 57c5bccd925a2b00924b6b176d0d38e210f3e6e8 | 57c5bccd925a2b00924b6b176d0d38e210f3e6e8 | 0/0 | 0 | docs-only report allowed |
| API | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 0/0 | 223 | read-only |
| Client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | 0/0 | 1 | read-only |

## Consolidation PH-21.78 -> PH-21.101

| phase | objet | preuve principale | verdict | dette/limite |
| --- | --- | --- | --- | --- |
| PH-21.78 | design trial_page_viewed | server-side CAPI from register_started selected over browser-only snippet | READY/DESIGN | real traffic still required |
| PH-21.79 | API source patch DEV | API patch for trial_page_viewed from register_started | source pushed in chain | no runtime PROD yet at that time |
| PH-21.84 | API DEV close | DEV API verified and closed | closed | PROD promotion still pending then |
| PH-21.85 | PROD safety design | owner routing / URL / CAPI destination checked | ready for ordered promotion | Client PROD pending then |
| PH-21.91 | Client DEV close | Client DEV owner/UTM/click IDs closed | closed | PROD promotion pending then |
| PH-21.92 | PROD promotion order | API PROD first, Client PROD second | READY_API_PROD_FIRST | none blocking |
| PH-21.97 | API PROD close | API PROD image/digest/markers closed | READY_WITH_LIMITS | real traffic not proven |
| PH-21.98 | Client PROD build | Client PROD image built from clean Git | READY | not pushed/applied then |
| PH-21.99 | Client PROD push | GHCR digest and pull-back verified | DONE | not live then |
| PH-21.100 | Client PROD apply | GitOps apply and runtime equality verified | READY_WITH_LIMITS | real traffic not proven |
| PH-21.101 | Client PROD verify | runtime, bundle, passive routes, no fake events verified | READY_WITH_LIMITS | real traffic not proven |

No blocking contradiction was detected across the required reports.

## Runtime API PROD

| API item | attendu | observe | verdict |
| --- | --- | --- | --- |
| deployment image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| pod image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| pod imageID digest | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| ready/restarts | true/0 | true/0 | PASS |
| generation | observed | 424/424 | PASS |
| trial_page_viewed marker | >0 | 8 | PASS |
| Meta mapping marker | >0 | 87 | PASS |
| StartTrial marker | >0 | 11 | PASS |
| Purchase marker | >0 | 40 | PASS |
| PROVIDER_CREDIT_EXHAUSTED marker | >0 | 14 | PASS |
| dist/tests | 0 | 0 | PASS |

## Runtime Client PROD

| Client runtime item | attendu | observe | verdict |
| --- | --- | --- | --- |
| manifest GitOps image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| last-applied image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| deployment spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod imageID digest | ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | PASS |
| ready/restarts | true/0 | true/0 | PASS |
| generation | observed | 428/428 | PASS |

## Bundle Audit Client PROD

Audit source: in-pod read-only grep count under /app. No browser JS execution.

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

## Logs

Only aggregate counts were collected. No raw log line is included.

| service | fenetre | crash/error markers | secret-like markers | verdict |
| --- | --- | --- | --- | --- |
| API PROD | 20m/tail 300 | 1 | 0 | PASS |
| Client PROD | 20m/tail 300 | 0 | 0 | PASS |

## Smoke Passif

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
| Client DEV image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | PASS |
| Client DEV digest | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Client DEV ready/restarts | true/0 | true/0 | PASS |
| Website/Admin/Backend/API/Client deployment snapshot | unchanged during close | PASS | PASS |
| Client latest | unchanged | unchanged | PASS |
| API latest | unchanged | unchanged | PASS |

## Dettes / Limites Finales

- Ads Manager / trial_page_viewed reel remains TRAFFIC_REQUIRED.
- Real proof requires a true journey through the Antoine/Meta URL, without CE fake event.
- Webflow / try.keybuzz.io must preserve marketing_owner_tenant_id, UTM and click IDs.
- Test onboarding without card is outside this chain.
- Recommended next technical work is design of real traffic validation, not a new patch.

## Final

Verdict: READY_WITH_LIMITS PH-SAAS-T8.12AS.21.102.

Next GO recommended:

```text
GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC VALIDATION PROD PH-SAAS-T8.12AS.21.103
```
