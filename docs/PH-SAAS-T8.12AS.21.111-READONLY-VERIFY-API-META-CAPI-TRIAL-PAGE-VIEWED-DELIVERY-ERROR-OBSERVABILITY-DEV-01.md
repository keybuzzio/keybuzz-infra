# PH-SAAS-T8.12AS.21.111 - Readonly verify API Meta CAPI trial_page_viewed delivery error observability DEV

Date UTC: 2026-06-24T11:49:18Z

## Verdict

GO READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV READY_WITH_LIMITS PH-SAAS-T8.12AS.21.111

Limit: API DEV runtime, digest, equality, health, markers and DB deltas are OK. No natural DEV failed provider delivery was observed during this readonly window, so safe error persistence remains readiness-proven by runtime/source markers and prior PH reports, not by a fresh natural failure.

## GO exact

GO READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.111

## Sources relues

AI memory and prompt standards:

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`
- `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`

Phase reports:

| Rapport | Point repris | Preuve utile pour PH-21.111 | Risque |
|---|---|---|---|
| PH-21.104 | real `/register` created `trial_page_viewed`, delivery failed | confirms original real failure context | PROD case not replayed |
| PH-21.105 | RCA evidence insufficient | confirms error evidence gap | no mutation allowed |
| PH-21.106 | deep RCA requires observability patch | confirms patch reason | none |
| PH-21.107 | source patch | API source `547648fd`, safe normalization/persistence | source only |
| PH-21.108 | build | Image ID `sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0` | no deploy in that phase |
| PH-21.109 | push | GHCR digest `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb`, latest intact | no deploy in that phase |
| PH-21.110 | apply | manifest commit `05b7e71`, report commit `cf4b7aa`, runtime equality OK, no fake event | natural failed delivery not observed |

## Preflight bastion

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| hostname | install-v3 | install-v3 | PASS |
| public IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| forbidden IP | absent | 51.159.99.247 absent | PASS |
| date UTC | captured | 2026-06-24T11:45:51Z | PASS |

## Repo / branche / HEAD / dirty

| Repo | Branche | HEAD | Dirty | Ahead/behind | Verdict |
|---|---|---:|---|---|---|
| keybuzz-infra | main | cf4b7aa | 0 before report | 0/0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 223 tracked dist deletions, non-dist dirty 0 | 0/0 | PASS documented preexisting dist-only debt |

## Runtime API DEV

| Controle | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| manifest image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` | same | PASS |
| rollout | successfully rolled out | deployment `keybuzz-api` successfully rolled out | PASS |
| generation | observed = current | 504 = 504 | PASS |
| ready replicas | 1/1 | 1/1 | PASS |
| updated replicas | 1 | 1 | PASS |
| runtime digest | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | pod imageID contains expected digest | PASS |

## Equality runtime

| Objet | Image | Digest/ImageID | Ready | Restarts | Verdict |
|---|---|---|---|---:|---|
| manifest | v3.5.265-meta-capi-error-observability-dev | n/a | n/a | n/a | PASS |
| last-applied | v3.5.265-meta-capi-error-observability-dev | n/a | n/a | n/a | PASS |
| deployment spec | v3.5.265-meta-capi-error-observability-dev | n/a | 1/1 | n/a | PASS |
| pod spec | v3.5.265-meta-capi-error-observability-dev | `ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | true | 0 | PASS |

## Logs / health

| Controle | Fenetre | Resultat | Verdict |
|---|---|---|---|
| internal health | point-in-time | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` | PASS |
| log lines inspected | last 2h / tail 2000 | 2000 | PASS |
| crash/panic/fatal/uncaught/unhandled | last 2h | 0 | PASS |
| raw secret pattern | last 2h | 0 | PASS |
| CAPI/meta unexpected storm | last 2h | 0 | PASS |
| CAPI/meta count | last 2h | 0 | PASS |
| LLM error count | last 2h | 0 | PASS |

No raw log line containing PII or secret material was copied into this report.

## Runtime markers

| Marker | Attendu | Resultat | Verdict |
|---|---|---|---|
| provider-error-normalizer file | present | PRESENT | PASS |
| meta-capi adapter file | present | PRESENT | PASS |
| emitter file | present | PRESENT | PASS |
| `dist/tests` | absent | ABSENT | PASS |
| tests path artifacts | 0 | 0 | PASS |
| PH-21.107 runtime artifacts | 0 | 0 | PASS |
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
| fixture sensitive count | 0 | 0 | PASS |

Source-side readonly grep across `src`, `test`, and `tests` found 104 occurrences of the relevant observability markers, consistent with PH-21.107/108.

## DB read-only deltas

Both snapshots used `BEGIN TRANSACTION READ ONLY`; `transaction_read_only=on`.

| Surface | Avant | Apres | Delta | Interpretation | Verdict |
|---|---:|---:|---:|---|---|
| funnel_events total | 113 | 113 | 0 | no CE event | PASS |
| funnel_events trial_page_viewed | 0 | 0 | 0 | no CE event | PASS |
| funnel_events StartTrial | 0 | 0 | 0 | no fake trial | PASS |
| funnel_events Purchase | 0 | 0 | 0 | no fake purchase | PASS |
| conversion_events total | 0 | 0 | 0 | no conversion pollution | PASS |
| conversion_events trial_page_viewed | 0 | 0 | 0 | no CE event | PASS |
| outbound_conversion_delivery_logs total | 7 | 7 | 0 | no delivery mutation | PASS |
| outbound_conversion_delivery_logs trial_page_viewed | 0 | 0 | 0 | no CE delivery | PASS |
| outbound_conversion_delivery_logs failed_total | 5 | 5 | 0 | no retry/replay | PASS |
| outbound_conversion_delivery_logs error_message_not_null | 5 | 5 | 0 | no mutation | PASS |
| outbound_conversion_delivery_logs failed_2h | 0 | 0 | 0 | no natural failed DEV delivery | READY_WITH_LIMITS |
| outbound_conversion_delivery_logs error_message_not_null_2h | 0 | 0 | 0 | no natural new error | READY_WITH_LIMITS |
| ai_usage total | 637 | 637 | 0 | no LLM call | PASS |
| ai_actions_ledger total | 565 | 565 | 0 | no KBActions mutation | PASS |
| ai_suggestion_events total | 2740 | 2740 | 0 | no AI event mutation | PASS |

## Delivery error observability readiness

| Capacite | Preuve read-only | Resultat | Verdict |
|---|---|---|---|
| Safe normalization exists | runtime marker + PH-21.107 source | `normalizeMetaCapiProviderError=4` | PASS |
| Safe message builder exists | runtime marker + PH-21.107 source | `buildSafeMetaCapiDeliveryErrorMessage=3` | PASS |
| Meta adapter path exists | runtime file marker | adapter PRESENT | PASS |
| Emitter persistence path exists | runtime markers | emitter PRESENT, `outbound_conversion_delivery_logs=19`, `error_message=16` | PASS |
| Safe classifications exist | runtime markers | `META_MISSING_USER_DATA=1`, `UNKNOWN_SAFE_ERROR=3` | PASS |
| Runtime tests excluded | in-pod audit | `dist/tests` absent, test artifacts 0 | PASS |
| Fresh natural failed DEV delivery | DB readonly 2h window | 0 | READY_WITH_LIMITS_NO_NATURAL_FAILED_DELIVERY |

No provider error was provoked, no delivery was replayed, and delivery `99541c23fe41` was not touched.

## No fake events

| Surface | Delta attendu | Delta observe | Verdict |
|---|---:|---:|---|
| POST `/funnel/event` | 0 | 0 CE command | PASS |
| fake trial_page_viewed | 0 | 0 DB delta | PASS |
| fake StartTrial/Purchase | 0 | 0 DB delta | PASS |
| retry/replay delivery | 0 | 0 failed_total delta | PASS |
| CAPI test endpoint | 0 | 0 CE command | PASS |
| metrics pollution | 0 | conversion_events delta 0 | PASS |

## Secret / PII

| Surface | Controle | Exposure | Verdict |
|---|---|---:|---|
| Kubernetes Secret.data | not read / not decoded | 0 | PASS |
| Vault secret values | not read | 0 | PASS |
| `/opt/keybuzz/credentials/` | not accessed | 0 | PASS |
| `/opt/keybuzz/secrets/` | not accessed | 0 | PASS |
| token / Authorization / cookie | log-count only, no raw values printed | 0 | PASS |
| email / phone / user_data | no row-level data selected | 0 | PASS |
| report payloads | no raw Meta payload copied | 0 | PASS |

## AI feature parity / anti-regression

| Feature | Controle | Resultat | Verdict |
|---|---|---|---|
| LLM provider credit signal | runtime marker | `PROVIDER_CREDIT_EXHAUSTED=13` | PASS |
| LLM provider errors route/marker | runtime marker | `llm-provider-errors=4` | PASS |
| AI usage | DB read-only delta | 637 -> 637, delta 0 | PASS |
| AI actions ledger | DB read-only delta | 565 -> 565, delta 0 | PASS |
| AI suggestion events | DB read-only delta | 2740 -> 2740, delta 0 | PASS |
| API health | internal health | OK | PASS |
| LLM logs | count only | 0 LLM error count | PASS |

## Non-regression

| Service | Attendu | Observe | Verdict |
|---|---|---|---|
| API DEV | v3.5.265 Meta CAPI observability DEV | same, ready 1/1 | PASS |
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
| secrets/jobs/monitoring | no mutation | no mutation | PASS |

## Gaps / limites

| Limite | Impact | Suite |
|---|---|---|
| No natural DEV failed Meta CAPI delivery in the observation window | safe error persistence not proven by a new live failure | close DEV as READY_WITH_LIMITS or wait for authorized natural/validation traffic |
| PROD delivery `99541c23fe41` not replayed | historical failure remains RCA context only | do not replay without explicit GO |
| Ads Manager / Events Manager not checked | external attribution not proven | future traffic validation phase if required |

## Conclusion

PH-21.111 confirms API DEV is still on the PH-21.110 image, with expected digest, equality, health, runtime markers, no tests embedded, no crash/token/CAPI storm in logs, DB/AI deltas at 0, and no non-regression issue on DEV/PROD services. Verdict is `READY_WITH_LIMITS` only because no natural failed provider delivery occurred in the readonly observation window.

Return file:

`C:\DEV\KeyBuzz\tmp\PH-21.111_CE_RETURN.md`

## Prochain GO

GO READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.112
