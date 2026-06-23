# PH-21.105 - READONLY RCA META CAPI TRIAL_PAGE_VIEWED DELIVERY FAILED PROD

## Verdict

GO READONLY RCA META CAPI TRIAL_PAGE_VIEWED DELIVERY FAILED PROD READY_RCA_EVIDENCE_INSUFFICIENT PH-SAAS-T8.12AS.21.105

RCA was read-only. CE did not retry or replay the delivery, did not POST /funnel/event, did not call the CAPI test endpoint, did not mutate DB/runtime/source/config/secrets and did not call Meta manually.

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
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.104-READONLY-OBSERVE-ONBOARDING-TRIAL-PAGE-VIEWED-REAL-TRAFFIC-PROD-01.md=OK lines=184 summary=GO READONLY OBSERVE ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC PROD NO_GO_CAPI_DELIVERY_FAILED PH-SAAS-T8.12AS.21.104
/opt/keybuzz/keybuzz-infra/docs/PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01.md=OK lines=259 summary=META CAPI REAL VALIDATION OK  READY FOR PROD
/opt/keybuzz/keybuzz-infra/docs/PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md=OK lines=234 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md=OK lines=168 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md=OK lines=167 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01.md=OK lines=226 summary=**MARKETING OWNER STACK LIVE IN PROD  OWNER MAPPING AND OWNER-SCOPED API READY  OUTBOUND OWNER-AWARE PRESERVED  ADMIN PROD UNCHANGED**
```

## Preflight Bastion Et Repos

| check | attendu | observe | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T14:23:11Z | PASS |
| kubectl context | available | kubernetes-admin@kubernetes | PASS |

| repo | path | branche | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| infra | /opt/keybuzz/keybuzz-infra | main | d864eb82158535e4993a9e6e9f9ec2eb29627fd4 | d864eb82158535e4993a9e6e9f9ec2eb29627fd4 | 0/0 | 0 | docs-only report allowed |
| API | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 0/0 | 223 | read-only |
| Client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | 0/0 | 1 | read-only |

## Runtime API / Client PROD

| service | image attendue | digest attendu | image observee | ready/restarts | verdict |
| --- | --- | --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | true/0 | PASS |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | true/0 | PASS |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | true/0 | PASS |

## Artefacts PH-21.104

| artefact | id safe | timestamp UTC | status | remarque |
| --- | --- | --- | --- | --- |
| register_started | ac48ffff5e17 | 2026-06-23T13:24:04.38856+00:00 | found | owner/campaign matched in PH-21.104 |
| trial_page_viewed | 99541c23fe41 | 2026-06-23T13:24:25.239328+00:00 | found | KeyBuzz/API event exists |
| Meta CAPI delivery | 99541c23fe41 | n/a | failed / http=unknown | provider=meta_hint attempts=unknown destination=11112186c0f1 |

## Introspection DB Read-Only

| table | colonnes utiles | existe | commentaire |
| --- | --- | --- | --- |
| funnel_events | id:uuid,funnel_id:text,event_name:text,source:text,tenant_id:text,attribution_id:text,plan:text,cycle:text,properties:jsonb,created_at:timestamp with time zone | True | metadata-only |
| conversion_events | id:uuid,event_id:text,tenant_id:text,event_name:text,payload:jsonb,status:text,attempts:integer,last_attempt_at:timestamp with time zone,created_at:timestamp with time zone | True | metadata-only |
| outbound_conversion_deliveries | n/a | False | metadata-only |
| outbound_deliveries | id:text,tenant_id:text,conversation_id:text,message_id:text,channel:text,target_address:text,provider:text,status:text,attempt_count:integer,last_error:text,created_at:timestamp with time zone,updated_at:timestamp with time zone,delivery_trace:jsonb,delivered_at:timestamp with time zone,next_retry_at:timestamp with time zone | True | metadata-only |
| outbound_conversion_delivery_logs | id:uuid,destination_id:uuid,event_name:text,event_id:text,attempt:integer,status:text,http_status:integer,error_message:text,delivered_at:timestamp with time zone,created_at:timestamp with time zone | True | metadata-only |
| outbound_conversion_destinations | id:uuid,tenant_id:text,name:text,destination_type:text,endpoint_url:text,secret:REDACTED_COLUMN,is_active:boolean,created_by:text,updated_by:text,created_at:timestamp with time zone,updated_at:timestamp with time zone,last_test_at:timestamp with time zone,last_test_status:text,platform_account_id:text,platform_pixel_id:text,platform_token_ref:REDACTED_COLUMN,mapping_strategy:text,deleted_at:timestamp with time zone | True | metadata-only |
| ad_platform_accounts | id:uuid,tenant_id:text,platform:text,account_id:text,account_name:text,currency:text,timezone:text,token_ref:REDACTED_COLUMN,status:text,last_sync_at:timestamp with time zone,last_error:text,created_by:text,created_at:timestamp with time zone,updated_at:timestamp with time zone,deleted_at:timestamp with time zone | True | metadata-only |
| tenants | id:text,name:text,domain:text,plan:text,status:text,created_at:timestamp with time zone,updated_at:timestamp with time zone,marketing_owner_tenant_id:text,selected_plan:text,trial_entitlement_plan:text | True | metadata-only |
| signup_attribution | id:uuid,tenant_id:text,user_email:text,utm_source:text,utm_medium:text,utm_campaign:text,utm_term:text,utm_content:text,gclid:text,fbclid:text,fbc:text,fbp:text,gl_linker:text,plan:text,cycle:text,landing_url:text,referrer:text,attribution_id:text | True | metadata-only |

## Chaine Event -> Delivery

```text
artifacts:
  register_started_count_safe=1
    id=ac48ffff5e17 ts=2026-06-23T13:24:04.38856+00:00 owner=OK campaign=OK
  trial_page_viewed_count_safe=1
    id=99541c23fe41 ts=2026-06-23T13:24:25.239328+00:00 owner=MISSING campaign=MISSING
delivery_failed:
  id_safe=99541c23fe41
  event_name=trial_page_viewed
  provider=meta_hint
  status=failed
  http_status=unknown
  attempts=unknown
  destination_safe=11112186c0f1
  timestamp_utc=2026-06-23T13:24:25.239328+00:00
  next_retry=none
classification:
  motif=UNKNOWN_SAFE_ERROR
  confidence=LOW
  error_code_safe=unknown
  error_safe=max attempts reached (meta_capi)
  sensitive_detected=0
historical_successes:
  count=0
destinations:
  id=0a1ee579e574 table=outbound_conversion_destinations owner=owner_match platform=unknown active=false token_ref=sensitive_columns_present_redacted
  id=80b09393ceeb table=outbound_conversion_destinations owner=owner_match platform=unknown active=true token_ref=sensitive_columns_present_redacted
  id=224c8323e631 table=outbound_conversion_destinations owner=owner_not_visible platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=adf11fbf8a8b table=outbound_conversion_destinations owner=owner_not_visible platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=5e2ca44a9a8e table=outbound_conversion_destinations owner=owner_not_visible platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=a1d4efc4a91f table=outbound_conversion_destinations owner=owner_not_visible platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=11112186c0f1 table=outbound_conversion_destinations owner=owner_match platform=meta_hint active=true token_ref=sensitive_columns_present_redacted
  id=4ac1dfe89b3e table=outbound_conversion_destinations owner=owner_not_visible platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=dee3f544996e table=outbound_conversion_destinations owner=owner_match platform=meta_hint active=false token_ref=sensitive_columns_present_redacted
  id=a24964a85cda table=outbound_conversion_destinations owner=owner_match platform=unknown active=false token_ref=sensitive_columns_present_redacted
```

| step | id safe | event_name | timestamp | status | correlation | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| register_started | ac48ffff5e17 | register_started | 2026-06-23T13:24:04.38856+00:00 | found | campaign=ph21104_trial_page_viewed_validation | PASS |
| trial_page_viewed | 99541c23fe41 | trial_page_viewed | 2026-06-23T13:24:25.239328+00:00 | found | from PH-21.104 window | PASS |
| delivery | 99541c23fe41 | trial_page_viewed | n/a | failed | destination=11112186c0f1 | FAILED |

## Error Classification Safe

| motif | preuve safe | confiance | action probable |
| --- | --- | --- | --- |
| UNKNOWN_SAFE_ERROR | code=unknown; message=max attempts reached (meta_capi) | LOW | GO READONLY RCA META CAPI TRIAL_PAGE_VIEWED DELIVERY FAILED PROD PH-SAAS-T8.12AS.21.105 |

Secret/PII exposure in report: 0. Raw provider error handling note: 0.

## Comparaison Failed trial_page_viewed vs Meta Successes Historiques

| item | resultat |
| --- | --- |
| successes historiques Meta trouvees | 0 |
| comparaison | no_meta_success_history_found |

Difference cle: historical successes, when present, are used only as category-level evidence. No payload raw values were copied. If StartTrial/Purchase successes contain user_data categories that trial_page_viewed lacks, the likely fix is payload/source mapping for pre-form page-view events, not a replay.

## Audit Source API Read-Only

| fichier/source | point verifie | resultat | risque |
| --- | --- | --- | --- |
| keybuzz-api | trial_page_viewed markers | count=11 files=keybuzz-api/src/modules/funnel/routes.ts,keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts,keybuzz-api/src/modules/outbound-conversions/emitter.ts,keybuzz-api/src/tests/ph2179-trial-page-viewed-meta-tests.ts | verify mapping before patch |
| keybuzz-api | Meta markers | count=125 | Meta path present |
| keybuzz-api | action_source markers | count=2 files=keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts | absent/low count can explain Meta schema failure |
| keybuzz-api | event_source_url markers | count=11 | absent/low count can explain Meta schema failure |
| keybuzz-api | fbc markers | count=24 files=keybuzz-api/src/modules/auth/tenant-context-routes.ts,keybuzz-api/src/modules/billing/routes.ts,keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts,keybuzz-api/src/modules/outbound-conversions/emitter.ts,keybuzz-api/src/tests/ph2179-trial-page-viewed-meta-tests.ts | direct manual test may miss fbc |
| keybuzz-api | fbp markers | count=16 | direct manual test may miss fbp |
| keybuzz-api | user_data markers | count=6 files=keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts,keybuzz-api/src/tests/ph2179-trial-page-viewed-meta-tests.ts | compare StartTrial/Purchase vs trial_page_viewed |

## Audit Destination / Config Read-Only

Destination rows were read with sensitive columns excluded. Token values were not selected or printed.

See "destinations" in the RCA summary above for safe hashed ids, owner/platform/active status and token_ref_status.

## Logs API / Worker Safe

| service | pattern | count | extrait safe/motif | verdict |
| --- | --- | --- | --- | --- |
| API PROD | trial_page_viewed/Meta/CAPI/delivery/error last 3h | 15 | aggregate only | PASS |
| API PROD | secret-like markers last 3h | 0 | none copied | PASS |
| Client PROD | register/funnel/error markers last 3h | 0 | aggregate only | PASS |
| Client PROD | secret-like markers last 3h | 0 | none copied | PASS |

## Absence De Pollution / No Fake Events

- retry/replay by CE: 0
- POST /funnel/event by CE: 0
- CAPI test endpoint by CE: 0
- DB mutation volontaire: 0
- StartTrial/Purchase/CompletePayment in PH-21.104 window: 0/0/0
- Webflow/Meta change: 0
- Linear: 0

## Non-Regression

| check | resultat | verdict |
| --- | --- | --- |
| API PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad / true/0 | PASS |
| Client PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 / true/0 | PASS |
| Client DEV runtime unchanged | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 / true/0 | PASS |
| Website/Admin/Backend deployment snapshot | PASS | PASS |
| API/Client latest manifest hash | PASS | PASS |

## Decision RCA

Verdict: READY_RCA_EVIDENCE_INSUFFICIENT.

Cause classee: UNKNOWN_SAFE_ERROR, confiance=LOW.

Prochain GO exact:

```text
GO READONLY RCA META CAPI TRIAL_PAGE_VIEWED DELIVERY FAILED PROD PH-SAAS-T8.12AS.21.105
```
