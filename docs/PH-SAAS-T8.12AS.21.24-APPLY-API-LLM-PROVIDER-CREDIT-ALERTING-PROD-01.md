# PH-SAAS-T8.12AS.21.24 - Apply API LLM provider credit alerting PROD

## Verdict

GO APPLY API LLM PROVIDER CREDIT ALERTING PROD GITOPS READY PH-SAAS-T8.12AS.21.24

PROD API was promoted through GitOps strict to:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod`

Runtime pod imageID digest:

`sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6`

Config digest / image ID from PH-21.23:

`sha256:76adfc7b435c0ad7c221b68c955a8ddf34769d0825c65f65162cb5468bb9d72e`

## Sources relues

- `C:\DEV\KeyBuzz\tmp\PH-21.24_CE_MISSION.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.23_CE_RETURN.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.23-PUSH-IMAGE-API-LLM-PROVIDER-CREDIT-ALERTING-PROD-01.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.22_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.21_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.20_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.17_PUSH_CE_RETURN.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`

## Preflight

| check | result | verdict |
| --- | --- | --- |
| bastion | `install-v3` | OK |
| IPv4 | `46.62.171.61` present, forbidden IP absent | OK |
| UTC date | `Mon Jun 1 10:24:49 AM UTC 2026` | OK |
| target GHCR manifest digest | `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | OK |
| target GHCR config digest | `sha256:76adfc7b435c0ad7c221b68c955a8ddf34769d0825c65f65162cb5468bb9d72e` | OK |
| latest digest | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | unchanged |

| repo | branch | HEAD | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | `3344b29a` | `3344b29a` | 0/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | `fee1a1a6` | `fee1a1a6` | 0/0 | 223 known dist deletions | read-only OK |

| service | namespace | image runtime before | ready | restarts | verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-api | keybuzz-api-dev | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-dev` | true | 0 | intact |
| keybuzz-api | keybuzz-api-prod | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod` | true | 0 | expected before |

Manifest before:

- file: `/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
- old PROD tag count: 1
- target PROD tag count: 0
- DEV tag in PROD manifest count: 0

## Snapshot before

Read-only SELECT counters from PROD:

| signal | before |
| --- | ---: |
| ai_suggestion_events | 3654 |
| ai_actions_ledger | 280 |
| ai_usage | 238 |
| conversion_events | 3 |
| outbound_conversion_delivery_logs | 19 |
| tracking_events | 32263 |
| outbound_conversion_destinations | 14 |

No LLM call, no fake event, no voluntary DB mutation.

## GitOps deploy commit

Patch scope:

- changed file: `k8s/keybuzz-api-prod/deployment.yaml`
- change: one image line plus existing inline rollback comment update
- no DEV manifest touched
- no source patch
- no API commit

Dry-run:

| dry-run | result | verdict |
| --- | --- | --- |
| client | `deployment.apps/keybuzz-api configured (dry run)` | OK |
| server | `deployment.apps/keybuzz-api configured (server dry run)` | OK |

Deploy commit:

| commit | scope | pushed | ahead/behind | verdict |
| --- | --- | --- | --- | --- |
| `c9fd30fe` | PROD API manifest only | yes | 0/0 | OK |

Commit message:

`deploy(api): PH-21.24 apply LLM provider credit alerting prod`

## Apply and rollout

Command executed after commit and push:

`kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`

Result:

- `deployment.apps/keybuzz-api configured`
- rollout completed successfully
- old replica terminated
- no DEV apply

## Runtime equality

| service | spec | last-applied | pod | imageID digest | ready | restarts | verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api PROD | target tag | target tag | target tag | `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | true | 0 | OK |

Pod:

`keybuzz-api-79b698d9b9-6cqx8`

Logs summary:

- LiteLLM initialized with `https://llm.keybuzz.io`
- no provider credit exhaustion was triggered
- no voluntary LLM call was executed
- no crash, no restart
- one existing startup warning observed: `must be owner of table ai_journal_events`
- Octopia sync summary stayed at `errors=0`

## Runtime marker audit in pod

| marker | result | verdict |
| --- | --- | --- |
| `/app/dist/services/llm-provider-errors.js` | present | OK |
| `PROVIDER_CREDIT_EXHAUSTED` | 10 matches in dist | OK |
| `/app/dist/tests` | absent | OK |
| `*ph2117*` runtime artifacts | 0 | OK |
| raw `credit balance too low` body marker in dist | 0 | OK |
| no-reply refs | 20 | present |
| KBActions refs | 279 | present |

## Snapshot after

Read-only SELECT counters from PROD:

| signal | before | after | delta | interpretation |
| --- | ---: | ---: | ---: | --- |
| ai_suggestion_events | 3654 | 3654 | 0 | stable |
| ai_actions_ledger | 280 | 280 | 0 | stable |
| ai_usage | 238 | 238 | 0 | stable |
| conversion_events | 3 | 3 | 0 | stable |
| outbound_conversion_delivery_logs | 19 | 19 | 0 | stable |
| tracking_events | 32263 | 32263 | 0 | stable |
| outbound_conversion_destinations | 14 | 14 | 0 | stable |

Conclusion:

- no AI generation caused by this phase
- no KBActions debit caused by this phase
- no tracking or conversion event caused by this phase
- no provider event simulation

## DEV and other services intact

| service | namespace | image |
| --- | --- | --- |
| keybuzz-api | keybuzz-api-dev | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-dev` |
| keybuzz-api | keybuzz-api-prod | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` |
| keybuzz-client | keybuzz-client-dev | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev` |
| keybuzz-client | keybuzz-client-prod | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod` |
| keybuzz-backend | keybuzz-backend-dev | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev` |
| keybuzz-backend | keybuzz-backend-prod | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod` |

Additional worker images remained inventoried and unchanged by this phase.

## Non-regression

- No build.
- No docker push.
- No source patch.
- No DB write by the operator.
- No LLM call.
- No fake metric.
- No fake event.
- No Linear action.
- No DEV apply.
- Latest tag digest unchanged.

## Rollback plan

Rollback was not executed.

If required, rollback is GitOps-only:

1. revert deploy commit `c9fd30fe` in `keybuzz-infra` main;
2. push the revert commit normally;
3. apply `/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`;
4. wait for rollout;
5. verify spec, last-applied, pod image and pod imageID return to the previous PROD runtime.

Previous PROD runtime before PH-21.24:

- tag: `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`
- digest: `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5`

## Limits and debts

- A natural provider credit exhaustion was not simulated and no LLM call was made.
- The route admin historical debt `/admin/ai/usage` exposing raw cost fields remains separate from PH-21.24.
- Dedicated Alertmanager watcher for LLM provider credit remains a separate future phase.
- Startup warning `must be owner of table ai_journal_events` was observed and should stay tracked separately if not already covered.

## Next GO

`GO READONLY VERIFY LLM PROVIDER CREDIT ALERTING PROD PH-SAAS-T8.12AS.21.25`
