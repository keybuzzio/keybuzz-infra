# PH-SAAS-T8.12AS.21.61 - Apply Website DEV hero copy and PROD body parity GitOps

Date UTC: 2026-06-17
Mode: APPLY WEBSITE DEV GITOPS only
Environment: DEV runtime only
Operator: Codex Executor

## Objective

Deploy via strict GitOps the Website DEV image built and pushed in PH-21.59/PH-21.60:

`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Expected GHCR manifest digest:

`sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b`

Expected image config digest / Image ID:

`sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc`

Expected Website source revision:

`dfb299b6facbbe17cf36d9085aeed2ee8908e151`

## Sources Reviewed

- `AI_MEMORY/CURRENT_STATE.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/DOCUMENT_MAP.md`
- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`
- `PH-21.58_CE_RETURN.md`
- `PH-21.58_PUSH_CE_RETURN.md`
- `PH-21.59_CE_RETURN.md`
- `PH-21.60_CE_RETURN.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.60-PUSH-IMAGE-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`
- `/opt/keybuzz/keybuzz-website/docs/BUILD-ARGS.md`
- `/opt/keybuzz/keybuzz-infra/docs/WEBSITE-AGENT-CONTEXT.md`

Note: `WEBSITE-AGENT-CONTEXT.md` contains older imperative deploy examples. They were not used; PH-21.61 followed the current GitOps strict rules.

## Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | OK |
| Bastion IP | `46.62.171.61` | `46.62.171.61` present | OK |
| Forbidden IP | not `51.159.99.247` | not used | OK |
| Date UTC | current | `2026-06-17T07:39:01Z` | OK |
| GHCR manifest digest | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | same | OK |
| GHCR config digest | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | same | OK |
| Website DEV runtime before | `v0.7.0-redesign-light-dev` | `v0.7.0-redesign-light-dev`, `1/1` | OK |
| Website PROD runtime before | `v0.6.22-clarity-restore-prod` | `v0.6.22-clarity-restore-prod`, `2/2` | OK |
| Infra branch | `main` | `main` | OK |
| Infra HEAD before phase | `8d70d2d` or descendant | `8d70d2d` | OK |
| Infra ahead/behind | `0/0` | `0/0` | OK |
| Infra dirty | `0` | `0` | OK |

## Manifest Diff

Allowed file:

`k8s/website-dev/deployment.yaml`

Only change:

```diff
-        image: ghcr.io/keybuzzio/keybuzz-website:v0.7.0-redesign-light-dev
+        image: ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev
```

| File | Change | Verdict |
| --- | --- | --- |
| `k8s/website-dev/deployment.yaml` | image tag only | OK |

No PROD manifest, env, probes, resources, replicas, service, ingress, namespace, secret or unrelated file was modified by the deploy commit.

## Kubernetes Dry-Run

| Dry-run | Expected | Result | Verdict |
| --- | --- | --- | --- |
| `kubectl apply --dry-run=client -f k8s/website-dev/deployment.yaml` | pass | `deployment.apps/keybuzz-website configured (dry run)` | OK |
| `kubectl apply --dry-run=server -f k8s/website-dev/deployment.yaml` | pass | `deployment.apps/keybuzz-website configured (server dry run)` | OK |

## GitOps Commit And Push Before Apply

| Repo | Commit deploy | Push | Ahead/behind after | Dirty after | Verdict |
| --- | --- | --- | --- | --- | --- |
| `keybuzz-infra` | `00f5e69` | normal push to `origin/main` | `0/0` | `0` | OK |

Commit message:

`gitops(website): PH-21.61 apply dev hero body parity`

Push was completed before the runtime apply.

## Apply And Rollout

Authorized apply command used:

`kubectl apply -f k8s/website-dev/deployment.yaml`

Result:

`deployment.apps/keybuzz-website configured`

Rollout:

`deployment "keybuzz-website" successfully rolled out`

Generation:

| Field | Value |
| --- | --- |
| metadata.generation | `69` |
| status.observedGeneration | `69` |

Note: the first apply verification script selected the old terminating pod after the rollout and stopped on `NotFound`. This happened after apply and rollout had succeeded. A follow-up read-only verification selected the Running pod and completed all runtime checks.

## Runtime Equality

| Surface | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Manifest file | target tag | `v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| Last-applied | target tag | present | OK |
| Deployment spec | target tag | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| Pod spec | target tag | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| Pod imageID | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | `ghcr.io/keybuzzio/keybuzz-website@sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | OK |
| Pod ready | `true` | `true` | OK |
| Restarts | `0` | `0` | OK |

Runtime pod:

`keybuzz-website-78d4c86b87-xs8lz`

## Bundle In-Pod Audit

Read-only audit in `/app/.next` inside the DEV pod.

| Marker | Expected | Count | Verdict |
| --- | ---: | ---: | --- |
| `Reprenez le contr` | >0 | 3 | OK |
| `marges` | >0 | 3 | OK |
| `Vous validez` | >0 | 9 | OK |
| `automatisez seulement` | >0 | 3 | OK |
| `Si vous vendez sur marketplace` | >0 | 3 | OK |
| `Comment` | >0 | 25 | OK |
| `Ce que KeyBuzz change` | >0 | 3 | OK |
| `protection` | >0 | 16 | OK |
| `Marketplaces` | >0 | 32 | OK |
| `Questions` | >0 | 32 | OK |
| `client-dev.keybuzz.io` | >0 | 3 | OK |
| `api-dev.keybuzz.io/api/public/contact` | >0 | 2 | OK |
| `api.keybuzz.io/api/public/contact` | 0 | 0 | OK |
| `49 EUR` | 0 | 0 | OK |
| `199 EUR` | 0 | 0 | OK |
| `49 €/mois` | 0 | 0 | OK |
| `199 €/mois` | 0 | 0 | OK |
| `49e/mois` | 0 | 0 | OK |
| `199e/mois` | 0 | 0 | OK |
| `-84` | 0 | 0 | OK |
| `StartTrial` | 0 | 0 | OK |
| `Purchase` | 0 | 0 | OK |
| `CompletePayment` | 0 | 0 | OK |
| `InitiateCheckout` | 0 | 0 | OK |
| `AW-` | 0 | 0 | OK |
| `G-R3QQDYEBFG` | 0 | 0 | OK |
| `9969977` | 0 | 0 | OK |
| `1234164602194748` | 0 | 0 | OK |
| `D7PT12JC77U44OJIPC10` | 0 | 0 | OK |
| `wrff07upjx` | 0 | 0 | OK |

Note on `49e`: a raw substring scan returned false positives from chunk/hash filenames such as `68a088aa49e6124a.js`. The runtime audit therefore used price-like forms (`49 EUR`, `49 €/mois`, `49e/mois`) and all were absent.

## Internal HTTP Smoke

No browser was launched and no JS/browser event was triggered.

| Smoke | Expected | Result | Verdict |
| --- | --- | --- | --- |
| GET `http://127.0.0.1:3000/` inside the pod | HTTP 200, non-empty HTML | `HTTP_STATUS=200`, `HTML_BYTES=84126` | OK |

## PROD And Other Services Preserved

| Surface | Before | After | Verdict |
| --- | --- | --- | --- |
| Website PROD runtime | `v0.6.22-clarity-restore-prod` | `v0.6.22-clarity-restore-prod`, ready `2/2` | OK |
| Website PROD manifest | unchanged | no diff in deploy commit | OK |
| API runtime | no action | read-only only | OK |
| Client runtime | no action | read-only only | OK |
| Backend runtime | no action | read-only only | OK |
| Admin runtime | no action | read-only only | OK |
| DB / LLM / tracking / KBActions | no action | no mutation executed | OK |

Deploy commit scope:

```text
00f5e69 gitops(website): PH-21.61 apply dev hero body parity
k8s/website-dev/deployment.yaml
```

## No Fake Events / No Fake Metrics

| Interdit | Result |
| --- | --- |
| Docker build / Docker push / retag / latest | `0` |
| Manifest PROD | `0` |
| `kubectl set image/env`, `kubectl patch/edit` | `0` |
| DB mutation | `0` |
| Fake event / form / checkout / signup / trial | `0` |
| CAPI / GA4 / Meta / TikTok / LinkedIn test event | `0` |
| Webflow | `0` |
| Linear | `0` |
| PROD mutation | `0` |

## Rollback Documentation Only

Do not execute without explicit GO.

Rollback GitOps DEV:

1. `cd /opt/keybuzz/keybuzz-infra`
2. `git revert 00f5e69`
3. `git push origin main`
4. `kubectl apply -f k8s/website-dev/deployment.yaml`
5. `kubectl -n keybuzz-website-dev rollout status deployment/keybuzz-website`
6. Verify runtime returns to `ghcr.io/keybuzzio/keybuzz-website:v0.7.0-redesign-light-dev`.

No `kubectl set image`, `kubectl set env`, `kubectl patch` or `kubectl edit`.

## Debts

| Debt | Status |
| --- | --- |
| Visual/browser QA for `preview.keybuzz.pro` desktop/mobile | deferred to PH-21.62 |
| Public preview Basic Auth/browser checks | deferred to PH-21.62 |
| PROD promotion | out of scope |

## Verdict

READY_WITH_DEBTS.

Website DEV GitOps apply is complete. Runtime equality, GHCR digest, bundle in-pod audit, internal smoke and PROD preservation are OK.

Final phrase:

`GO APPLY WEBSITE DEV HERO COPY AND PROD BODY PARITY GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.61`

Next recommended GO:

`GO READONLY VERIFY WEBSITE DEV HERO COPY AND PROD BODY PARITY PH-SAAS-T8.12AS.21.62`
