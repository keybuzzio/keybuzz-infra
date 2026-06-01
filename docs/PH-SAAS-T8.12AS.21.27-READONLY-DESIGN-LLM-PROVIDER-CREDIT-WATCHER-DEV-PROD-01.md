# PH-SAAS-T8.12AS.21.27 - Read-only design LLM provider credit watcher DEV PROD

## Verdict

GO READONLY DESIGN LLM PROVIDER CREDIT WATCHER DEV PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.27

The watcher design is ready for a DEV source patch.

Verdict is `READY_WITH_DEBTS` because the design is clear, but the existing monitoring path has known operational debt:

- `monitoring-alerts` currently sends repeated emails every 2 minutes for existing worker restart alerts;
- `monitoring-webhook` is not present in `vault-management`;
- Alertmanager exists with Slack/email/log-only receivers, but the current `monitoring-alerts` CronJob sends direct email rather than using Alertmanager;
- no natural `PROVIDER_CREDIT_EXHAUSTED` event exists yet, so live alert behavior must be validated later without fake PROD events.

Recommended next GO:

`GO SOURCE PATCH LLM PROVIDER CREDIT WATCHER DEV PH-SAAS-T8.12AS.21.28`

## Sources relues

Local returns:

- `C:\DEV\KeyBuzz\tmp\PH-21.16_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.17_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.20_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.21_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.24_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.25_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.26_CE_RETURN.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`

Infra reports PH-21.16 to PH-21.26 were confirmed present in:

`/opt/keybuzz/keybuzz-infra/docs`

## Preflight

| check | result | verdict |
| --- | --- | --- |
| bastion | `install-v3` | OK |
| required IPv4 | `46.62.171.61` present | OK |
| forbidden IPv4 | `51.159.99.247` absent | OK |
| UTC date | `Mon Jun 1 12:17:51 PM UTC 2026` | OK |

| repo | branch | HEAD | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | `6ef96413` | `6ef96413` | 0/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | `fee1a1a6` | `fee1a1a6` | 0/0 | 223 known dist deletions | read-only OK |
| keybuzz-backend | main | `c38583a8` | `c38583a8` | 0/0 | 1 known dirty backup | read-only OK |
| keybuzz-client | ph148/onboarding-activation-replay | `ad4e862a` | `ad4e862a` | 0/0 | 1 known tsbuildinfo | read-only OK |
| keybuzz-admin-v2 | main | `3707c834` | `3707c834` | 0/0 | 0 | OK |
| keybuzz-website | main | `eba00d81` | `eba00d81` | 0/0 | 0 | OK |

Runtime API:

| env | image | ready | desired | verdict |
| --- | --- | ---: | ---: | --- |
| DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-dev` | 1 | 1 | OK |
| PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` | 1 | 1 | OK |

## PH-21.16 to PH-21.26 synthesis

| phase | decision useful for watcher |
| --- | --- |
| PH-21.16 | Root cause confirmed: provider credit failures were previously generic `REQUEST_FAILED`; watcher should be separate from source classifier. |
| PH-21.17 | Stable code `PROVIDER_CREDIT_EXHAUSTED` added; safe propagation and raw body sanitization implemented. |
| PH-21.20 | DEV runtime deployed through GitOps; DB counters stable. |
| PH-21.21 | DEV verification found no natural provider-credit incident; runtime markers OK. |
| PH-21.24 | PROD runtime deployed through GitOps; digest aligned. |
| PH-21.25 | PROD verification found no natural provider-credit incident; warning `ai_journal_events` remains non-blocking. |
| PH-21.26 | Source/runtime line closed DEV+PROD; watcher remains next P1 debt. |

Confirmed:

- source signal is stable;
- DEV and PROD runtimes are active;
- no fake LLM call was used;
- watcher is the correct next debt before multi-provider fallback.

## Existing monitoring map

| mechanism | location | env/ns | status | reusable | risk |
| --- | --- | --- | --- | --- | --- |
| `monitoring-alerts` CronJob | `k8s/monitoring-alerts/cronjob.yaml` | `vault-management` | active every 2 min | yes | currently direct email, repeated alerts without debounce |
| `monitoring-alert-script` ConfigMap | `k8s/monitoring-alerts/configmap-script.yaml` | `vault-management` | active | yes | shell/curl only, no DB client |
| `keybuzz-monitor` RBAC | `k8s/monitoring-alerts/rbac.yaml` | cluster role | active | partly | pods/log allowed, no direct DB; configmap state permissions exist |
| Alertmanager | `observability` | pod running | active | yes | separate from `monitoring-alerts` direct email path |
| AlertmanagerConfig | `observability/keybuzz-dev-alerting` | `observability` | active | yes | labelled DEV; routes Slack/email/log-only |
| Slack receiver | secret ref `alerting-slack-dev/webhook_url` | `observability` | configured by secret ref | yes | do not expose webhook; not used by current CronJob |
| Email receiver | Alertmanager email config | `observability` | configured | yes | direct email also exists in CronJob |
| `monitoring-webhook` secret | `vault-management` | absent | not active | optional | webhook path not currently usable |
| Prometheus/Grafana/Loki | `observability` | pods running | active | future option | DB signal not currently exported as metric |

Current `monitoring-alerts` facts:

- schedule: `*/2 * * * *`
- image: `curlimages/curl:8.7.1`
- service account: `keybuzz-monitor`
- env: `ALERT_ENV=prod`, `LOG_WINDOW=180`, `RESTART_THRESHOLD=3`, `ERROR_RATE_THRESHOLD=5`
- optional webhook from secret ref `monitoring-webhook/url`
- SMTP values configured in manifest; exact addresses omitted here
- recent jobs complete successfully
- recent logs show 2 direct email alerts per run for existing worker restart thresholds

Design implication:

Do not add a provider-credit alert without debounce. Otherwise a real outage could produce repeated alerts every 2 minutes.

## Signal DB/logs map

`ai_usage` exists in DEV and PROD.

Columns available in both environments:

`id`, `tenant_id`, `user_id`, `feature`, `provider`, `model`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `cost_usd_est`, `status`, `error_code`, `request_id`, `created_at`

Useful watcher columns:

`tenant_id`, `feature`, `provider`, `model`, `status`, `error_code`, `request_id`, `created_at`

| env | source | useful columns | provider credit count | request failed recent | verdict |
| --- | --- | --- | ---: | ---: | --- |
| DEV | `ai_usage` | present | 0 all-time / 0 last 24h | 0 last 24h | OK |
| PROD | `ai_usage` | present | 0 all-time / 0 last 24h | 0 last 24h | OK |

Recent provider/model:

- DEV: none in last 24h.
- PROD: `provider=litellm`, `model=kbz-premium`, count 2 in last 24h.

Logs:

- DEV and PROD contain runtime marker support.
- No natural `PROVIDER_CREDIT_EXHAUSTED`, `credit balance too low`, or `REQUEST_FAILED` recurrence was observed.
- Logs are useful as a secondary signal, but DB is more robust because it survives pod rotation and gives structured `error_code`.

## Recommended watcher design

| decision | recommendation | reason | risk |
| --- | --- | --- | --- |
| Primary source | `ai_usage.error_code = 'PROVIDER_CREDIT_EXHAUSTED'` | stable source introduced by PH-21.17 and live DEV/PROD | requires DB-safe access path |
| Access path | add internal API monitoring endpoint that queries `ai_usage`, then call it from `monitoring-alerts` | avoids copying DB credentials into monitoring namespace; reuses existing API DB env | requires API source patch |
| Endpoint format | one-line key/value text plus JSON optional | shell script can parse without `jq` | endpoint must be auth guarded |
| Auth | `X-KeyBuzz-Monitor-Token` from secret ref, per env | prevents public/internal abuse | token management needed |
| PROD window | 15 minutes | catches real outages quickly without one-minute noise | misses very old historical incidents by design |
| DEV window | 60 minutes | lower priority, useful during testing | may be disabled/log-only in noisy DEV |
| PROD threshold | `count >= 1` immediate critical | provider credit exhaustion blocks all LLM users | must debounce |
| DEV threshold | `count >= 1` warning/log-only | useful for DEV validation, not production outage | avoid Slack/email spam |
| Debounce | suppress same env/provider/model key for 60 minutes in PROD, 6 hours in DEV | existing CronJob runs every 2 minutes | state bugs can hide repeat incidents if too broad |
| State | `monitoring-alert-state` ConfigMap keyed by `llm_provider_credit:{env}:{provider}:{model}` | existing RBAC already targets this ConfigMap concept | may need RBAC adjustment for update/patch |
| Alert payload | env, count, window, first_seen, last_seen, provider/model, feature counts, distinct tenant count, runbook link | operationally actionable and safe | do not include prompt/message/client content |
| Request IDs | do not send IDs by default; include count only | request IDs are not needed for first-line alert | deeper audit can query manually |
| Channels | PROD: current email + optional webhook; DEV: log-only by default | matches existing path and avoids surprise Slack/email | Slack integration remains separate if webhook absent |
| Secondary signal | logs for `PROVIDER_CREDIT_EXHAUSTED` count only | helps if DB write fails | not primary because logs rotate |

Proposed internal endpoint:

`GET /internal/monitoring/llm-provider-credit?windowSeconds=900`

Safe response fields:

- `ok`
- `env`
- `windowSeconds`
- `count`
- `firstSeen`
- `lastSeen`
- `providerModelCounts`
- `featureCounts`
- `distinctTenantCount`
- `requestFailedCount`

Do not return:

- prompt
- message content
- customer data
- provider body
- provider balance
- raw token/API key/webhook/DSN
- real LLM cost to Client

Recommended query shape:

```sql
SELECT COUNT(*) AS total,
       MIN(created_at) AS first_seen,
       MAX(created_at) AS last_seen,
       COUNT(DISTINCT tenant_id) AS distinct_tenants
FROM ai_usage
WHERE created_at >= NOW() - ($1::int * INTERVAL '1 second')
  AND status = 'error'
  AND error_code = 'PROVIDER_CREDIT_EXHAUSTED';
```

Group details should aggregate only by safe dimensions:

- provider
- model
- feature

## Implementation options for PH-21.28

| option | advantages | risks | effort | recommendation |
| --- | --- | --- | --- | --- |
| 1. Log-only check in existing `monitoring-alerts` | fastest; no API patch; uses pods/log RBAC | less robust, loses data on log rotation, not DB-backed | low | not recommended as primary |
| 2. Internal API endpoint + existing `monitoring-alerts` check | DB-backed without DB secrets in monitoring namespace; reuses current CronJob/channels | needs API source patch and script parsing; must add debounce | medium | recommended |
| 3. Dedicated CronJob in API namespaces querying DB directly | isolated from existing noisy monitor; can use API namespace DB secret refs | duplicates alert delivery/channel config; more manifests; more secret surface | medium-high | fallback if option 2 is rejected |
| 4. Prometheus/Alertmanager native metric/rule | clean SRE model; Alertmanager grouping/repeat logic | needs metric/exporter path first; higher blast radius | high | later evolution |

Recommended PH-21.28 scope:

1. API DEV source patch:
   - add guarded internal endpoint;
   - pure query helper for `ai_usage`;
   - unit tests for query/result shaping and auth guard.
2. Infra DEV source patch:
   - extend `monitoring-alerts` script with `check_llm_provider_credit`;
   - add env knobs for endpoint URLs, token secret refs, thresholds and debounce;
   - add state/debounce helpers using `monitoring-alert-state`;
   - DEV default log-only/dry-run unless explicit alert GO is later given.
3. No build/deploy in source patch phase.

## Security and no-fake-events

The design must preserve:

- no raw DB secrets in logs;
- no webhook URL printed;
- no Slack/email test during source patch;
- no prompt/message/customer content in alert payload;
- no provider body or provider balance in alert;
- no fake `ai_usage`;
- no fake conversion/tracking/provider event;
- no LLM call;
- no KBActions debit;
- no Amazon outbound impact;
- no CAPI/tracking impact.

Testing strategy:

- unit-test the API query/result formatter with fixtures;
- unit-test shell parser/debounce helpers offline;
- dry-run `monitoring-alerts` in log-only mode in DEV after build/deploy phases;
- validate with synthetic local fixture only, not PROD DB mutation;
- wait for natural real incident to validate live provider-credit alerting.

## Remaining debts

| debt | priority | status | next action |
| --- | --- | --- | --- |
| LLM provider credit watcher implementation | P1 | design ready | PH-21.28 source patch DEV |
| Existing `monitoring-alerts` email spam for worker restarts | P1 | observed | include debounce/state hygiene in watcher patch or separate SRE patch |
| `monitoring-webhook` absent in `vault-management` | P2 | observed | decide whether to configure webhook or keep email/log-only |
| Multi-provider fallback | P2 | open | after watcher |
| PROD `ai_journal_events` ownership warning | P2 | open | separate DB ownership audit |
| Historical admin cost fields | P2 | open | separate privacy hardening |
| Live provider credit incident observation | P2 | pending | observe without fake LLM |

## Linear text prepared, not posted

KEY-337 draft:

PH-21.27 completed the read-only design for the LLM provider credit watcher. Recommended implementation is an authenticated internal API monitoring endpoint backed by `ai_usage.error_code='PROVIDER_CREDIT_EXHAUSTED'`, consumed by the existing `monitoring-alerts` CronJob with mandatory debounce/state. PROD threshold should alert on count >= 1 over 15 minutes; DEV should be log-only or low-priority over 60 minutes. No fake LLM call, DB mutation, alert trigger, event tracking or Linear mutation was performed. Next phase: PH-21.28 source patch DEV.

## Next GO

`GO SOURCE PATCH LLM PROVIDER CREDIT WATCHER DEV PH-SAAS-T8.12AS.21.28`
