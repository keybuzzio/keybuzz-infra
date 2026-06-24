# PH-SAAS-T8.12AS.21.112 - Readonly close API Meta CAPI trial_page_viewed delivery error observability DEV

Date UTC: 2026-06-24T13:36:15Z

## Verdict

GO READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV READY_WITH_LIMITS PH-SAAS-T8.12AS.21.112

Reason for READY_WITH_LIMITS: the DEV source/build/push/apply/verify chain is coherent and closed, but no natural DEV failed Meta CAPI provider delivery exercised live safe error persistence during PH-21.111/112.

## GO exact

GO READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.112

## Sources relues

AI memory and prompt standard:

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`
- `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`
- `C:\DEV\KeyBuzz\tmp\PH-21.110_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.111_CE_RETURN.md`

Reports consolidated:

- PH-21.104 observe real traffic PROD.
- PH-21.105 RCA failed delivery.
- PH-21.106 deep RCA observability gap.
- PH-21.107 source patch.
- PH-21.108 build DEV image.
- PH-21.109 push DEV image.
- PH-21.110 apply DEV GitOps.
- PH-21.111 verify DEV read-only.

## Preflight bastion

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| hostname | install-v3 | install-v3 | PASS |
| public IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| forbidden IP | absent | 51.159.99.247 absent | PASS |
| date UTC | captured | 2026-06-24T13:35:15Z | PASS |

## Repo / branche / HEAD / dirty

| Repo | Branche | HEAD | Dirty | Ahead/behind | Verdict |
|---|---|---:|---|---|---|
| keybuzz-infra | main | fe0c65c | 0 before report | 0/0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 223 tracked dist deletions, non-dist dirty 0 | 0/0 | PASS documented preexisting dist-only debt |

## Consolidation PH

| Phase | Verdict | Image/commit/digest | Preuve | Dette |
|---|---|---|---|---|
| PH-21.104 | NO_GO_CAPI_DELIVERY_FAILED | PROD real `trial_page_viewed` failed delivery | real traffic observed, no CE fake event | provider failure cause still insufficient |
| PH-21.105 | READY_RCA_EVIDENCE_INSUFFICIENT | delivery `99541c23fe41` context | read-only RCA, no replay | error evidence insufficient |
| PH-21.106 | READY_DEEP_RCA_OBSERVABILITY_PATCH_REQUIRED | observability gap | error field present but unclassified | patch required |
| PH-21.107 | READY_WITH_DEBTS | API commit `547648fd` | safe normalizer/adapters/emitter/tests | source only, no deploy |
| PH-21.108 | READY | Image ID `sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0` | build from clean Git worktree | no deploy |
| PH-21.109 | DONE | GHCR digest `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | pull-back OK, latest intact | no deploy |
| PH-21.110 | READY_WITH_LIMITS | manifest commit `05b7e71`, docs `cf4b7aa` | GitOps strict apply, runtime equality OK | no natural provider failure |
| PH-21.111 | READY_WITH_LIMITS | docs `fe0c65c` | verify runtime/digest/markers/no fake events | READY_WITH_LIMITS_NO_NATURAL_FAILED_DELIVERY |

## Runtime final API DEV

| Controle | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| manifest image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` | same | PASS |
| last-applied image | same | same | PASS |
| deployment spec image | same | same | PASS |
| pod spec image | same | same | PASS |
| pod imageID digest | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | `ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | PASS |
| generation | observed=current | 504=504 | PASS |
| Ready | true / 1 of 1 | 1/1 | PASS |
| Restarts | 0 or documented | 0 | PASS |
| Health | OK | `{"status":"ok","service":"keybuzz-api"}` | PASS |
| Rollout | successful | deployment successfully rolled out | PASS |

## Runtime markers

| Marker | Attendu | Resultat | Verdict |
|---|---|---|---|
| provider-error-normalizer file | present | PRESENT | PASS |
| meta-capi adapter file | present | PRESENT | PASS |
| emitter file | present | PRESENT | PASS |
| `normalizeMetaCapiProviderError` | present | 4 | PASS |
| `buildSafeMetaCapiDeliveryErrorMessage` | present | 3 | PASS |
| `outbound_conversion_delivery_logs` | present | 19 | PASS |
| `error_message` | present | 16 | PASS |
| `trial_page_viewed` | present | 7 | PASS |
| `StartTrial` | present | 9 | PASS |
| `Purchase` | present | 31 | PASS |
| `PROVIDER_CREDIT_EXHAUSTED` | present | 13 | PASS |
| `llm-provider-errors` | present | 4 | PASS |
| `META_MISSING_USER_DATA` | present | 1 | PASS |
| `UNKNOWN_SAFE_ERROR` | present | 3 | PASS |
| `dist/tests` | absent | ABSENT | PASS |
| tests path artifacts | 0 | 0 | PASS |
| PH-21.107 runtime artifacts | 0 | 0 | PASS |
| fixture sensitive count | 0 | 0 | PASS |

## Logs de cloture

| Controle | Fenetre | Resultat | Verdict |
|---|---|---|---|
| API DEV logs inspected | last 2h / tail 2000 | 2000 lines | PASS |
| crash/panic/fatal/uncaught/unhandled | last 2h | 0 | PASS |
| raw secret pattern | last 2h | 0 | PASS |
| CAPI/meta unexpected storm | last 2h | 0 | PASS |
| CAPI/meta count | last 2h | 0 | PASS |
| LLM error count | last 2h | 0 | PASS |

No raw log line with PII or secret material was copied.

## DB read-only de cloture

Reference: PH-21.111 after snapshot at 2026-06-24T11:49:18Z.

Current: PH-21.112 close snapshot at 2026-06-24T13:36:15Z.

Both snapshots were read-only (`transaction_read_only=on` in current snapshot).

| Surface | Reference | Actuel | Delta | Verdict |
|---|---:|---:|---:|---|
| funnel_events total | 113 | 113 | 0 | PASS |
| funnel_events trial_page_viewed | 0 | 0 | 0 | PASS |
| funnel_events StartTrial | 0 | 0 | 0 | PASS |
| funnel_events Purchase | 0 | 0 | 0 | PASS |
| conversion_events total | 0 | 0 | 0 | PASS |
| conversion_events trial_page_viewed | 0 | 0 | 0 | PASS |
| outbound_conversion_delivery_logs total | 7 | 7 | 0 | PASS |
| outbound_conversion_delivery_logs trial_page_viewed | 0 | 0 | 0 | PASS |
| outbound_conversion_delivery_logs failed_total | 5 | 5 | 0 | PASS |
| outbound_conversion_delivery_logs error_message_not_null | 5 | 5 | 0 | PASS |
| outbound_conversion_delivery_logs failed_2h | 0 | 0 | 0 | READY_WITH_LIMITS |
| outbound_conversion_delivery_logs error_message_not_null_2h | 0 | 0 | 0 | READY_WITH_LIMITS |
| ai_usage total | 637 | 637 | 0 | PASS |
| ai_actions_ledger total | 565 | 566 | +1 | NATURAL_OR_EXTERNAL_ACTIVITY, not CE; ai_usage delta 0 |
| ai_suggestion_events total | 2740 | 2740 | 0 | PASS |

Additional aggregate check:

- `ai_actions_ledger recent_3h=1`
- `ai_usage recent_3h=0`

The +1 ledger row is not attributed to CE: no LLM call was made, no tracking event was submitted, and no API mutation was executed by CE.

## No fake events

| Surface | Delta attendu | Delta observe | Verdict |
|---|---:|---:|---|
| POST `/funnel/event` | 0 | 0 CE command | PASS |
| fake trial_page_viewed | 0 | 0 DB delta | PASS |
| fake StartTrial/Purchase | 0 | 0 DB delta | PASS |
| replay delivery | 0 | 0 outbound failed_total delta | PASS |
| CAPI test endpoint | 0 | 0 CE command | PASS |
| metrics pollution | 0 | conversion_events delta 0 | PASS |
| DB mutation volontaire | 0 | 0 CE command | PASS |

## Secret / PII

| Surface | Controle | Exposure | Verdict |
|---|---|---:|---|
| Kubernetes Secret.data | not read / not decoded | 0 | PASS |
| Vault secret values | not read | 0 | PASS |
| `/opt/keybuzz/credentials/` | not accessed | 0 | PASS |
| `/opt/keybuzz/secrets/` | not accessed | 0 | PASS |
| token / Authorization / cookie | log-count only, no raw values printed | 0 | PASS |
| email / phone / user_data | no row-level PII selected | 0 | PASS |
| raw Meta payload | not copied | 0 | PASS |

## AI feature parity / anti-regression

| Feature | Controle | Resultat | Verdict |
|---|---|---|---|
| LLM provider credit signal | runtime marker | `PROVIDER_CREDIT_EXHAUSTED=13` | PASS |
| LLM provider errors marker | runtime marker | `llm-provider-errors=4` | PASS |
| API health | internal health endpoint | OK | PASS |
| LLM logs | count only | 0 LLM error count | PASS |
| AI usage | read-only aggregate | `ai_usage` 637 -> 637, delta 0 | PASS |
| AI actions ledger | read-only aggregate | 565 -> 566, +1 external/natural; no ai_usage delta | NON_BLOCKING |

## Non-regression

| Service | Attendu | Observe | Verdict |
|---|---|---|---|
| API DEV | v3.5.265 Meta CAPI observability DEV | same, ready 1/1, restarts 0 | PASS |
| API PROD | v3.5.264 onboarding trial_page_viewed Meta PROD | same, ready 1/1 | PASS |
| API outbound workers | unchanged | unchanged observed images | PASS |
| Client DEV | v3.5.260 onboarding register_started owner payload DEV | same, ready 1/1 | PASS |
| Client PROD | v3.5.260 onboarding register_started owner payload PROD | same, ready 1/1 | PASS |
| Website DEV | v0.7.1 hero copy prod body parity DEV | same, ready 1/1 | PASS |
| Website PROD | v0.7.2 visual hero parity PROD | same, ready 2/2 | PASS |
| Admin DEV | v2.12.2 media buyer LP domain QA DEV | same, ready 1/1 | PASS |
| Admin PROD | v2.12.2 media buyer LP domain QA PROD | same, ready 1/1 | PASS |
| Backend DEV/PROD | observed baselines | unchanged observed images | PASS |
| GHCR latest API | hash `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | same | PASS |
| PROD manifests | no mutation | no mutation | PASS |
| jobs/cron/monitoring/secrets | no mutation | no mutation | PASS |

## Dettes / limites

| Dette / limite | Impact | Suite |
|---|---|---|
| No natural DEV failed Meta CAPI provider delivery during PH-21.111/112 | live safe persistence not exercised in DEV | keep READY_WITH_LIMITS and verify with future natural/authorized validation traffic |
| PROD failed delivery `99541c23fe41` not replayed | historical RCA remains context only | do not replay without explicit GO |
| Ads Manager / Events Manager not proved by this DEV chain | external attribution not closed | separate validation if needed |
| PROD promotion of this observability | not done in this chain | next phase should design PROD promotion safety |
| API repo tracked `dist/` deletions | preexisting local repo debt | do not clean/revert in unrelated phases |
| ai_actions_ledger +1 since PH-21.111 | non-tracking external/natural activity, no ai_usage delta | monitor only if recurring; not caused by CE |

## Conclusion

The DEV chain PH-21.107 -> PH-21.111 is coherent and closed:

- source patch: `547648fd`;
- build Image ID: `sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0`;
- push digest: `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb`;
- GitOps manifest commit: `05b7e71`;
- verify docs commit: `fe0c65c`;
- final runtime digest/equality/markers/health/no-fake-events are conforming.

The closure remains `READY_WITH_LIMITS` because no natural failed provider delivery occurred in DEV to prove live persistence of a fresh safe provider error.

Return file:

`C:\DEV\KeyBuzz\tmp\PH-21.112_CE_RETURN.md`

## Prochain GO

GO READONLY DESIGN META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PROMOTION SAFETY PH-SAAS-T8.12AS.21.113
