# PH-21.104 - READONLY OBSERVE ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC PROD

## Verdict

GO READONLY OBSERVE ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC PROD NO_GO_CAPI_DELIVERY_FAILED PH-SAAS-T8.12AS.21.104

Observation was read-only. CE did not open the URL, did not execute browser JS, did not POST /funnel/event, did not submit a form, did not start checkout, did not call a CAPI test endpoint and did not mutate DB/runtime.

## Test Window

| champ | valeur | source | confiance |
| --- | --- | --- | --- |
| Europe/Paris | 2026-06-23 15:24 Europe/Paris | PH-21.104_TEST_WINDOW.md | HIGH |
| UTC point | 2026-06-23 13:24 UTC | PH-21.104_TEST_WINDOW.md | HIGH |
| primary window | 2026-06-23T13:19:00Z -> 2026-06-23T13:34:00Z | PH-21.104_TEST_WINDOW.md | HIGH |
| expanded window | 2026-06-23T13:14:00Z -> 2026-06-23T13:44:00Z | PH-21.104_TEST_WINDOW.md | HIGH |
| URL expected | redacted-to-contract, campaign=ph21104_trial_page_viewed_validation | PH-21.104_TEST_WINDOW.md | HIGH |
| source type | direct manual open, not confirmed Meta ad click | PH-21.104_TEST_WINDOW.md | HIGH |
| handoff sha256 | d35dabb52c84c8fe1f0fe457fc55f4e61432aa88376e78cfc407e174276f34ee | /tmp/PH-21.104_TEST_WINDOW.md | HIGH |

## Sources Relues

```text
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md=OK lines=974 summary=KEY-312 : Done (cloture 2026-05-23 post validation visuelle Ludovic, ref PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-LINEAR-DONE-01.md).
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md=OK lines=169 summary=present
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md=OK lines=165 summary=present
/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md=OK lines=233 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.55-READONLY-RCA-SERVER-SIDE-TRACKING-STARTTRIAL-DEV-PROD-01.md=OK lines=343 summary=GO READONLY RCA SERVER SIDE TRACKING STARTTRIAL DEV PROD TRAFFIC_REQUIRED PH-SAAS-T8.12AS.21.55
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.56-READONLY-VERIFY-WEBSITE-TO-STRIPE-PRECHECKOUT-TRACKING-PROD-01.md=OK lines=286 summary=GO READONLY VERIFY WEBSITE TO STRIPE PRECHECKOUT TRACKING PROD EXPECTED_ABSENT_STARTTRIAL PH-SAAS-T8.12AS.21.56
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.78-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-PROD-01.md=OK lines=596 summary=PH-21.78 READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PROD : READY_SOURCE_PATCH_REQUIRED
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.79-SOURCE-PATCH-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=145 summary=Verdict: READY_WITH_DEBTS - SOURCE PATCH DEV LOCAL DONE PH-SAAS-T8.12AS.21.79
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.84-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md=OK lines=165 summary=- Verdict: READY_WITH_LIMITS.
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.91-READONLY-CLOSE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-DEV-01.md=OK lines=152 summary=Verdict: READY_WITH_LIMITS
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.97-READONLY-CLOSE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-PROD-01.md=OK lines=148 summary= PH-21.92  READY_API_PROD_FIRST  API first, Client second order decided  Client PROD to follow 
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.100-APPLY-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=128 summary=Verdict: READY_WITH_LIMITS
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.101-READONLY-VERIFY-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=181 summary=GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.101
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.102-READONLY-CLOSE-CLIENT-ONBOARDING-REGISTER-STARTED-OWNER-PAYLOAD-PROD-01.md=OK lines=198 summary=GO READONLY CLOSE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.102
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.103-READONLY-DESIGN-ONBOARDING-TRIAL-PAGE-VIEWED-REAL-TRAFFIC-VALIDATION-PROD-01.md=OK lines=210 summary=GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC VALIDATION PROD READY_FOR_REAL_TRAFFIC_WINDOW PH-SAAS-T8.12AS.21.103
/opt/keybuzz/keybuzz-infra/docs/PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md=OK lines=220 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01.md=OK lines=226 summary=**MARKETING OWNER STACK LIVE IN PROD  OWNER MAPPING AND OWNER-SCOPED API READY  OUTBOUND OWNER-AWARE PRESERVED  ADMIN PROD UNCHANGED**
```

## Preflight Bastion Et Repos

| check | attendu | observe | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T13:31:47Z | PASS |
| kubectl context | available | kubernetes-admin@kubernetes | PASS |

| repo | path | branche | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| infra | /opt/keybuzz/keybuzz-infra | main | 57f59b97383625442c74753178e2992fadd22b5e | 57f59b97383625442c74753178e2992fadd22b5e | 0/0 | 0 | docs-only report allowed |
| API | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 0/0 | 223 | read-only |
| Client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | 0/0 | 1 | read-only |

## Runtime API + Client PROD

| service | image attendue | digest attendu | image observee | ready/restarts | verdict |
| --- | --- | --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | true/0 | PASS |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | true/0 | PASS |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | true/0 | PASS |

## DB Baseline Et Candidats

The observation queried only the explicit primary and expanded test windows. Raw payloads were not written to this report.

```text
funnel_events: rows=1 register_started=1 trial_page_viewed=1 starttrial=0 purchase=0 completepayment=0
conversion_events: rows=0 register_started=0 trial_page_viewed=0 starttrial=0 purchase=0 completepayment=0
outbound_conversion_deliveries: rows=0 register_started=0 trial_page_viewed=0 starttrial=0 purchase=0 completepayment=0
outbound_conversion_delivery_logs: rows=1 register_started=0 trial_page_viewed=1 starttrial=0 purchase=0 completepayment=0
best_candidate:
  id=ac48ffff5e17
  timestamp_utc=2026-06-23T13:24:04.38856+00:00
  owner=OK
  utm_source=OK
  utm_medium=OK
  campaign=OK
  utm_content=OK
  utm_term=OK
  click_id_present=MISSING_DIRECT_MANUAL_OK
  route_register=UNKNOWN
  confidence=HIGH
delivery_summary:
  count=2
  success=0
  failed=1
  pending=0
  example=funnel_events id=ac48ffff5e17 event=trial_page_viewed provider=meta_hint status=unknown http=unknown verdict=UNKNOWN error_safe=none
  example=outbound_conversion_delivery_logs id=99541c23fe41 event=trial_page_viewed provider=meta_hint status=failed http=unknown verdict=FAILED error_safe=error_present_masked
```

| source | filtre | count | ids safe | verdict |
| --- | --- | --- | --- | --- |
| funnel_events | register_started expanded window + expected campaign/owner scoring | 1 | ac48ffff5e17 | FOUND |
| all observed tables | trial_page_viewed expanded window | 2 | safe hashed IDs only | FOUND |
| outbound delivery tables | trial_page_viewed delivery expanded window | 2 | safe hashed IDs only | FAILED |

## Candidat register_started

| candidat | timestamp UTC | event_name | owner | utm_source | campaign | click_id_present | confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ac48ffff5e17 | 2026-06-23T13:24:04.38856+00:00 | register_started | OK | OK | OK | MISSING_DIRECT_MANUAL_OK | HIGH |

Interpretation: the handoff says this was a direct manual open, not a confirmed Meta ad click. Missing fbclid/click_id is therefore not a blocker for KeyBuzz DB/API/CAPI proof.

## Verification trial_page_viewed KeyBuzz/API

| preuve | attendu | observe | verdict |
| --- | --- | --- | --- |
| register_started captured | >0 | 1 | FOUND |
| owner payload | keybuzz-consulting-mo9zndlk | OK | OK |
| UTM source/medium/campaign | meta / paid_social / ph21104_trial_page_viewed_validation | OK / OK / OK | OK |
| trial_page_viewed | >0 if register_started captured | 2 | FOUND |
| StartTrial/Purchase/CompletePayment pollution | 0 / 0 / 0 | 0 / 0 / 0 | PASS |

## Verification Meta CAPI Delivery

| metric | observe | verdict |
| --- | --- | --- |
| delivery rows trial_page_viewed | 2 | FAILED |
| success | 0 | informational |
| failed | 1 | informational |
| pending | 0 | informational |

Ads Manager / Events Manager: NOT_AVAILABLE in this CE observation. Because this was a direct manual open, Ads Manager attribution can remain not applicable without a real Meta click/fbclid.

## Logs Runtime Safe

Only aggregate counts were collected. No raw log lines were included.

| service | pattern | count | interpretation |
| --- | --- | --- | --- |
| API PROD | trial_page_viewed/CAPI/Meta/conversion markers last 2h | 4 | informational only |
| API PROD | secret-like markers last 2h | 0 | PASS |
| Client PROD | register/funnel/error markers last 2h | 0 | informational only |
| Client PROD | secret-like markers last 2h | 0 | PASS |

## Pollution Check

| event/type | avant | apres | delta | interpretation |
| --- | --- | --- | --- | --- |
| StartTrial | window count | 0 | 0 | expected 0 for no checkout |
| Purchase | window count | 0 | 0 | expected 0 for no checkout |
| CompletePayment | window count | 0 | 0 | expected 0 for no checkout |
| CE fake event | 0 | 0 | 0 | CE did not trigger traffic |

## No Fake Metrics / No Fake Events

- POST /funnel/event by CE: 0
- Formulaire /register by CE: 0
- Checkout Stripe by CE: 0
- CAPI test endpoint by CE: 0
- Fake event by CE: 0
- DB mutation volontaire: 0
- Browser JS execution by CE: 0
- Public ad click by CE: 0
- Webflow/Meta change: 0

## Non-Regression

| check | resultat | verdict |
| --- | --- | --- |
| API PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad / true/0 | PASS |
| Client PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 / true/0 | PASS |
| Client DEV runtime unchanged | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 / true/0 | PASS |
| Website/Admin/Backend deployment snapshot | PASS | PASS |
| API/Client latest manifest hash | PASS | PASS |
| ai_usage total | 353 | read-only observed |
| ai_actions_ledger total | 400 | read-only observed |

## Gaps / Limites

- This was a direct manual open, not a confirmed Meta ad click.
- fbclid/click ID can be missing without invalidating KeyBuzz DB/API/CAPI proof.
- Ads Manager attribution remains PENDING/NOT_AVAILABLE unless Antoine/Ludovic confirms Meta evidence or a real Meta click is performed.
- No correction/rollback was executed.

## Final

Verdict: NO_GO_CAPI_DELIVERY_FAILED PH-SAAS-T8.12AS.21.104.
