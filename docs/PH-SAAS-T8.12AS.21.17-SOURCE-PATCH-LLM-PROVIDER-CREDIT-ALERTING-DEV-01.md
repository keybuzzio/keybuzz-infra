# PH-SAAS-T8.12AS.21.17 - SOURCE PATCH LLM PROVIDER CREDIT ALERTING DEV

Date UTC: 2026-05-31
Executor: Codex CE
Mode: SOURCE PATCH DEV
Linear: KEY-337
Verdict: READY_WITH_DEBTS

## Scope

- API DEV source patch only.
- Local commits only.
- No push.
- No Docker build.
- No deploy.
- No DB mutation.
- No backfill.
- No LLM/provider call.
- No provider event tracking.

## Bastion Preflight

| Check | Result |
| --- | --- |
| SSH target | install-v3 |
| Required IPv4 | 46.62.171.61 present |
| Forbidden IPv4 | 51.159.99.247 absent |
| UTC time observed | Sun May 31 11:38:58 UTC 2026 |

## Repository Preflight

| Repo | Branch | HEAD before | Origin before | Dirty count | Notes |
| --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 9797bedf | 9797bedf | 223 | Pre-existing dist/ deletions; source target paths clean before patch |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a | ad4e862a | 1 | Existing tsconfig.tsbuildinfo dirty, out of scope |
| keybuzz-infra | main | 00494aea | 00494aea | 0 | Clean before report |
| keybuzz-backend | main | c38583a8 | c38583a8 | 1 | Existing amazon.routes.ts.bak untracked, out of scope |
| keybuzz-website | main | eba00d81 | eba00d81 | 0 | Out of scope |
| keybuzz-admin-v2 | main | 3707c834 | 3707c834 | 0 | Out of scope |

## Source Changes

| File | Change | Risk |
| --- | --- | --- |
| keybuzz-api/src/services/llm-provider-errors.ts | Added deterministic LLM provider error classifier and safe redaction/fingerprint helper | Low |
| keybuzz-api/src/services/litellm.service.ts | Classified non-OK provider responses and request failures; logs safe metadata only; writes ai_usage.error_code with PROVIDER_CREDIT_EXHAUSTED where detected | Medium |
| keybuzz-api/src/modules/ai/ai-assist-routes.ts | Propagates safe provider_unavailable response with errorCode and 0 KBActions on provider credit exhaustion | Low |
| keybuzz-api/src/modules/ai/returns-decision-routes.ts | Propagates safe 503/errorCode and 0 KBActions before any debit on provider credit exhaustion | Low |
| keybuzz-api/src/tests/ph2117-llm-provider-errors-tests.ts | Added classifier coverage for positive/negative/redaction cases | Low |

## Detection Rules

Positive matches:

- credit balance too low
- insufficient credit / insufficient credits
- insufficient_quota / insufficient quota
- quota exceeded
- billing hard limit

Negative coverage:

- timeout
- temporary rate limit
- invalid API key/auth
- model overloaded
- content policy
- malformed request
- tenant KBActions exhausted
- ordinary customer message containing store credit

## Safety Properties

- Raw provider error bodies are not logged.
- Logs contain requestId, feature, provider, model, providerStatus, code, reason and sanitized fingerprint only.
- Public responses do not expose provider balance, raw body, token, authorization, password or secret values.
- KBActions debit remains after successful generation/parsing paths only.
- AI Assist no-reply skip path unchanged.
- Autopilot behavior unchanged except central chatCompletion error classification.
- Returns Analysis preserves value-based debit rules.

## Validation

| Test | Expected | Result |
| --- | --- | --- |
| Standalone classifier compilation and node execution | PASS | PASS |
| `./node_modules/.bin/tsc --noEmit` in keybuzz-api | PASS | PASS |
| Target source path status after API commit | Clean | PASS |

Standalone test command:

```bash
mkdir -p /tmp/ph2117-tests && ./node_modules/.bin/tsc --target ES2022 --module commonjs --moduleResolution node --esModuleInterop --types node --skipLibCheck --outDir /tmp/ph2117-tests src/services/llm-provider-errors.ts src/tests/ph2117-llm-provider-errors-tests.ts && node /tmp/ph2117-tests/tests/ph2117-llm-provider-errors-tests.js
```

Output:

```text
PH21.17 llm-provider-errors tests PASS
```

## Commits

| Repo | Commit | Message | Push |
| --- | --- | --- | --- |
| keybuzz-api | fee1a1a6 | fix(ai): classify LLM provider credit exhaustion (PH-21.17, KEY-337) | No |
| keybuzz-infra | Pending at report write | docs(ai): PH-21.17 provider credit alerting source patch (KEY-337) | No |

## Residual Debts

- keybuzz-api still has pre-existing dist/ deletions outside PH-21.17 scope. They were not staged or committed. Any later build phase must start from a clean build-from-git checkout/HEAD as required by KeyBuzz rules.
- No runtime alert watcher/event creation was implemented in this source patch phase; this is expected for PH-21.17.

## Rollback

No deploy occurred.

Local source rollback, if explicitly requested later:

```bash
cd /opt/keybuzz/keybuzz-api
git revert fee1a1a6
```

Docs rollback, if explicitly requested later:

```bash
cd /opt/keybuzz/keybuzz-infra
git revert <infra-doc-commit>
```

## Next GO

GO PUSH SOURCE PATCH LLM PROVIDER CREDIT ALERTING DEV PH-SAAS-T8.12AS.21.17

STOP.
