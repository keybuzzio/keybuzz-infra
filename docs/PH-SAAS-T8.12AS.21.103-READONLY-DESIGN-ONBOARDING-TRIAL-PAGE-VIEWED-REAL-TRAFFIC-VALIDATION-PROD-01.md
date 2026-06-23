# PH-21.103 - READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC VALIDATION PROD

## Verdict

GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC VALIDATION PROD READY_FOR_REAL_TRAFFIC_WINDOW PH-SAAS-T8.12AS.21.103

The technical chain is ready for a real traffic window. CE did not execute the journey and did not trigger any event. The next phase must be an observation-only run after Ludovic/Antoine choose the exact URL and time window.

## Context And GO

- GO: GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC VALIDATION PROD PH-SAAS-T8.12AS.21.103
- Objective: design the PROD real-traffic validation for Antoine's requested event trial_page_viewed on https://client.keybuzz.io/register.
- No browser JS, click, form, checkout, CAPI test, POST /funnel/event, DB mutation, Webflow change, Meta change or Linear change was executed by CE.

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
/opt/keybuzz/keybuzz-infra/docs/PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md=OK lines=220 summary=present
/opt/keybuzz/keybuzz-infra/docs/PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01.md=OK lines=226 summary=**MARKETING OWNER STACK LIVE IN PROD  OWNER MAPPING AND OWNER-SCOPED API READY  OUTBOUND OWNER-AWARE PRESERVED  ADMIN PROD UNCHANGED**
```

Missing optional reports, if any, are not blocking because PH-21.102 and current runtime checks are sufficient for this design. They must not be treated as proof beyond the reports listed as OK.

## Preflight Bastion Et Repos

| check | attendu | observe | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T11:43:29Z | PASS |
| kubectl context | available | kubernetes-admin@kubernetes | PASS |

| repo | path | branche | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| infra | /opt/keybuzz/keybuzz-infra | main | 17204018bcbe0cdfa53c5bcb7f78e5879072ebbe | 17204018bcbe0cdfa53c5bcb7f78e5879072ebbe | 0/0 | 1 | phase_report_rewrite_allowed |
| API | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 0/0 | 223 | read-only |
| Client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | 0/0 | 1 | read-only |

## Etat Runtime Actuel

| service | image attendue | digest attendu | image observee | ready/restarts | verdict |
| --- | --- | --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | true/0 | PASS |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | true/0 | PASS |

## Consolidation PH-21.78 -> PH-21.102

| phase | preuve | verdict | consequence pour le test reel |
| --- | --- | --- | --- |
| PH-21.55 | StartTrial RCA / distinction event produit | read-only evidence chain | Do not expect StartTrial without real trial/subscription Stripe. |
| PH-21.56 | Website to Stripe precheckout journey | read-only evidence chain | A visit without finalized Stripe payment must not become StartTrial. |
| PH-21.78 | Design trial_page_viewed | server-side CAPI from register_started selected | Validate trial_page_viewed, not StartTrial. |
| PH-21.79 | API source patch | trial_page_viewed source path added | API can map first register_started into CAPI custom event. |
| PH-21.84 | API DEV close | DEV verified | DEV proof established before PROD. |
| PH-21.91 | Client DEV close | owner/UTM/click IDs payload verified | Client payload model validated before PROD. |
| PH-21.97 | API PROD close | API PROD v3.5.264 runtime closed | API is ready to receive real register_started. |
| PH-21.100 | Client PROD apply | GitOps runtime equality verified | Client PROD is live on owner payload image. |
| PH-21.101 | Client PROD verify | bundle/routes/no fake events verified | Technical Client side is ready. |
| PH-21.102 | Client PROD close | API + Client chain consolidated | Only real traffic proof remains. |

## URL_CONTRACT

Owner tenant PROD:

```text
keybuzz-consulting-mo9zndlk
```

Direct technical validation URL template:

```text
https://client.keybuzz.io/register?marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&utm_source=meta&utm_medium=paid_social&utm_campaign=<campaign>&utm_content=<ad_or_creative>&utm_term=<adset_or_audience>
```

Meta Ads "URL parameters" recommended value:

```text
marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&utm_source=meta&utm_medium=paid_social&utm_campaign={{campaign.name}}&utm_content={{ad.name}}&utm_term={{adset.name}}
```

Notes:
- fbclid is normally appended automatically by Meta on a real ad click.
- If the ad lands on try.keybuzz.io first, Webflow must preserve the full query string when sending the visitor to client.keybuzz.io/register.
- If query params are lost between try.keybuzz.io and client.keybuzz.io/register, the Ads Manager validation can fail even if KeyBuzz runtime is correct.
- To isolate KeyBuzz first, use the direct client.keybuzz.io/register URL with the parameters above.

| scenario | URL/source | parametres requis | risque | recommendation |
| --- | --- | --- | --- | --- |
| direct client register | client.keybuzz.io/register | marketing_owner_tenant_id + utm_source/medium/campaign/content/term; click IDs if available | no fbclid if not Meta click | best initial technical validation |
| Meta ad final URL direct | client.keybuzz.io/register from Meta | same UTM params via URL parameters; fbclid added by Meta | Meta delay/attribution window | preferred Ads validation path |
| Meta ad to try.keybuzz.io then CTA | try.keybuzz.io then Webflow CTA | all query params must be forwarded to client register | query loss in Webflow CTA | requires Antoine/Webflow confirmation |
| direct visit without fbclid | typed/shared direct URL | UTM + owner only | Ads Manager attribution may be absent | acceptable for KeyBuzz DB/CAPI logic, not enough for Ads attribution |

## Validation Levels

| niveau | preuve | qui observe | outil | delai possible | verdict possible |
| --- | --- | --- | --- | --- | --- |
| A - Runtime KeyBuzz technique | register_started row with owner/UTM/click IDs; trial_page_viewed mapped/outbound if destination accepts | CE read-only after real test | DB SELECT-only, safe API logs, outbound delivery status | minutes | PASS / TRAFFIC_NOT_FOUND / ROUTING_MISSING / DELIVERY_PENDING |
| B - Meta Events Manager | trial_page_viewed visible as custom event | Antoine/Ludovic | Meta Events Manager | minutes to hours | PASS / META_DELAY / NOT_VISIBLE |
| C - Ads Manager attribution | event associated with ad/campaign | Antoine | Ads Manager | hours to days, depending attribution | PASS / ATTRIBUTION_DELAY / CLICK_ID_LOST |

## Runbook Prochain Test Reel

Before test:
- Choose one exact time window in Europe/Paris and UTC.
- Choose one unique campaign marker, for example ph21103_trial_page_viewed_validation_YYYYMMDD_HHMM.
- Choose path: direct client.keybuzz.io/register or try.keybuzz.io then CTA.
- If using try.keybuzz.io, Antoine must confirm query forwarding before relying on Ads attribution.
- CE does not click and only observes after the real visit.

During test:
- Ludovic or Antoine opens the real link once in a normal/incognito browser.
- Wait until https://client.keybuzz.io/register is loaded.
- Do not submit the register form.
- Do not go to checkout.
- Do not pay.
- Record exact local time, URL used, browser and approximate country if useful.
- Antoine checks Events Manager / Ads Manager according to Meta delays.

After test:
- CE runs a read-only observation phase.
- CE checks DB SELECT-only, safe logs and outbound delivery status.
- CE does not POST /funnel/event, does not use CAPI test endpoint and does not simulate a visitor.

## Observations Read-Only Prevues Pour PH-21.104

SELECT-only intentions, no secret and no PII display:
- Search register_started in the test window.
- Verify properties contain marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk.
- Verify UTM fields and click IDs if available.
- Search matching trial_page_viewed conversion/outbound delivery.
- Verify provider/status HTTP if stored.
- Verify StartTrial/Purchase/CompletePayment are absent during the test if no checkout occurred.
- Check duplicate count and debounce/dedup behavior.
- Classify natural unrelated traffic separately and never claim it as CE action.

## Webflow / try.keybuzz.io Passive Design

Passive GET only, no JS, no click, no form.

| surface | observation passive | conclusion | action demandee a Antoine |
| --- | --- | --- | --- |
| https://try.keybuzz.io/ | HTTP 200, html_bytes=118494, client_register_refs=10, query_forwarding_hints=11 | PASS_PASSIVE_HINTS | Confirm Webflow CTA preserves full query string to client.keybuzz.io/register before using try.keybuzz.io for Ads validation. |

If Webflow remains UNKNOWN, the next real test should use the direct client.keybuzz.io/register URL first.

## MESSAGE_ANTOINE_PROPOSE

Bonjour Antoine,

Pour valider le nouvel evenement, le signal attendu est trial_page_viewed lorsque la page https://client.keybuzz.io/register est chargee. StartTrial ne doit apparaitre qu'apres une vraie activation trial/subscription Stripe, donc il ne faut pas attendre StartTrial sur une simple visite /register.

URL de validation directe recommandee :

```text
https://client.keybuzz.io/register?marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&utm_source=meta&utm_medium=paid_social&utm_campaign=ph21103_trial_page_viewed_validation_<YYYYMMDD_HHMM>&utm_content=<ad_or_creative>&utm_term=<adset_or_audience>
```

Si la publicite passe d'abord par try.keybuzz.io, il faut confirmer que Webflow conserve tous les query params jusqu'a client.keybuzz.io/register. Merci de nous donner une fenetre de test precise, avec l'heure Europe/Paris, l'URL exacte utilisee et si possible la campagne/ad/adset concernes.

## No Fake Metrics / No Fake Events

- POST /funnel/event: 0
- Formulaire /register: 0
- Checkout Stripe: 0
- CAPI test endpoint: 0
- Fake event: 0
- DB mutation volontaire: 0
- Browser JS execution: 0
- Public ad click by CE: 0
- Webflow/Meta change: 0

## Non-Regression

| check | resultat | verdict |
| --- | --- | --- |
| API PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad / true/0 | PASS |
| Client PROD runtime unchanged | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod / ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 / true/0 | PASS |
| Website/Admin/Backend deployment snapshot | PASS | PASS |

## Gaps / Limites

- Ads Manager / Meta real proof remains pending until Ludovic/Antoine execute a real visit.
- Webflow/try.keybuzz.io query forwarding is PASS_PASSIVE_HINTS from passive HTML only.
- Test without card is outside this chain.
- No new code patch is recommended by this design unless the future observation proves query loss or routing failure.

## Final

Verdict: READY_FOR_REAL_TRAFFIC_WINDOW PH-SAAS-T8.12AS.21.103.

Next GO:

```text
GO READONLY OBSERVE ONBOARDING TRIAL_PAGE_VIEWED REAL TRAFFIC PROD PH-SAAS-T8.12AS.21.104
```
