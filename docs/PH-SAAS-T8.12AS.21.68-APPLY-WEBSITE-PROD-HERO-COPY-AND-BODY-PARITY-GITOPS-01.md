# PH-SAAS-T8.12AS.21.68 - Apply Website PROD hero copy and body parity GitOps

Date UTC: 2026-06-17T15:58:46Z
Mode: APPLY WEBSITE PROD GITOPS strict
Environment: PROD runtime
Verdict: READY_WITH_DEBTS

## Executive summary

PH-21.68 promoted Website PROD from:

`ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod`

to:

`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod`

using GitOps strict. Deploy commit `f4daa43fe4e65e3271878728da8f6a1e0edc6b0a` was pushed before apply.
Client/server dry-runs passed, `kubectl apply -f k8s/website-prod/deployment.yaml` was used, rollout
completed successfully, and final runtime equality is OK.

No build, docker push, latest mutation, other service change, fake tracking event, form
submit, checkout, Webflow or Linear action was performed.

Verdict is READY_WITH_DEBTS because the runtime is healthy while pre-existing Website
lint/npm audit debts remain open from PH-21.65/PH-21.66.

## Sources reread

| Source | Status |
| --- | --- |
| PH-21.68 mission | Read |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Read |
| PH-T8.10J model prompt | Read |
| PH-21.65 / PH-21.66 / PH-21.67 local returns | Read |
| Remote PH-21.65 / PH-21.66 / PH-21.67 reports | Read |
| WEBSITE-AGENT-CONTEXT.md | Read; obsolete imperative examples ignored |
| keybuzz-website/docs/BUILD-ARGS.md | Read |
| PH-21.01 / PH-21.55 / PH-21.56 tracking reports | Read |

## Preflight and target image

| Check | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Bastion | install-v3 | install-v3 | OK |
| Required IP | 46.62.171.61 | present | OK |
| Forbidden IP | absent | 51.159.99.247 absent | OK |
| Kube context | kubernetes-admin@kubernetes | kubernetes-admin@kubernetes | OK |
| Infra HEAD | deploy commit | f4daa43fe4e65e3271878728da8f6a1e0edc6b0a | OK |
| GHCR target manifest | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | OK |
| GHCR target config | sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 | sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 | OK |
| Image source Git | 4a12cfc801eda3d095bc43a984abc87522d6e41b | 4a12cfc801eda3d095bc43a984abc87522d6e41b | OK |

## Manifest patch and deploy commit

| Field | Value |
| --- | --- |
| Manifest | k8s/website-prod/deployment.yaml |
| Namespace | keybuzz-website-prod |
| Deployment | keybuzz-website |
| Image before | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod |
| Image after | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod |
| Deploy commit | f4daa43fe4e65e3271878728da8f6a1e0edc6b0a |
| Commit message | gitops(website): PH-21.68 apply prod body parity |
| Push before apply | OK |

The deploy diff was one file, one line, with one deletion and one insertion on the image
line only.

## Dry-run and apply

| Action | Result | Verdict |
| --- | --- | --- |
| kubectl apply --dry-run=client -f k8s/website-prod/deployment.yaml | OK | PASS |
| kubectl apply --dry-run=server -f k8s/website-prod/deployment.yaml | OK | PASS |
| kubectl apply -f k8s/website-prod/deployment.yaml | OK | PASS |

Apply output:

```text
deployment.apps/keybuzz-website configured
service/keybuzz-website unchanged
namespace/keybuzz-website-prod unchanged
```

## Rollout

Rollout output:

```text
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-website" successfully rolled out
```

| Check | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Ready | 2/2 | 2/2 | OK |
| Updated | 2 | 2 | OK |
| Available | 2 | 2 | OK |
| Generation | observed = desired | 37 / 37 | OK |
| Pod restarts | 0 | 0 | OK |

Note: the first immediate runtime check saw one old pod while it was still terminating
right after rollout. A subsequent convergence check shows only two target pods, both
Running, Ready, restarts 0, with the expected digest.

## Runtime equality

| Surface | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Manifest file | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | image: ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod  # PH-SAAS-T8.12AS.20.15D (2026-05-26) KEY-322/KEY-337 : restore Clarity wrff07upjx + Meta 1234164602194748 + TikTok D7PT12JC77U44OJIPC10 (v0.6.21 build PH-20.10B avait droppe ces 3 build-args NEXT_PUBLIC) ; commit website 907689b ; manifest digest GHCR sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac ; config sha256:619afbd95b82 ; GA G-R3QQDYEBFG/SGTM t.keybuzz.pro/LinkedIn 9969977 preserves ; rollback v0.6.21-pricing-action-recover-prod | OK |
| Last-applied | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | OK |
| Deployment spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | OK |
| Pod spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | all pods | OK |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | all pods | OK |
| Old digest ready pods | 0 | 0 | OK |

Runtime pods:

```text
spec=ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod
ready=2/2
keybuzz-website-54c5f4f658-2gvqd|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
keybuzz-website-54c5f4f658-pvfqb|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
```

## Smoke and bundle checks

| Check | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| GET / | 200 non-empty | / 200 72766 | OK |
| GET /pricing | 200 non-empty | /pricing 200 71713 | OK |
| GET /contact | 200 non-empty | /contact 200 28362 | OK |
| Contact static chunks fetched | > 0 | 12 | OK |
| Hero/body markers | present | PASS | OK |
| PROD tracking IDs | present | PASS | OK |
| DEV URLs | absent | PASS | OK |
| Old pricing/KPI | absent | PASS | OK |
| Fake conversion trigger | absent | PASS | OK |

Selected marker counts:

| Marker | Count |
| --- | ---: |
| Reprenez le contr | 1 |
| marges | 1 |
| Vous validez | 2 |
| automatisez seulement | 1 |
| client.keybuzz.io | 6 |
| api.keybuzz.io/api/public/contact | 1 |
| t.keybuzz.pro | 5 |
| wrff07upjx | 1 |
| G-R3QQDYEBFG | 5 |
| 1234164602194748 | 1 |
| D7PT12JC77U44OJIPC10 | 1 |
| 9969977 | 5 |

Forbidden marker counts are zero for DEV URLs, old prices and old KPI marker. Direct
Lead tracking pattern count is 0; the standalone Lead word count is
1 and is treated as non-blocking guard/comment text.

## No fake metrics / no fake events

| Surface | Result |
| --- | --- |
| Browser event intentionally triggered | 0 |
| Server-side event intentionally triggered | 0 |
| StartTrial fake | 0 |
| Purchase fake | 0 |
| CompletePayment fake | 0 |
| Lead fake | 0 |
| InitiateCheckout fake | 0 |
| Form submit | 0 |
| Checkout opened | 0 |
| CAPI/GA/Meta/TikTok/LinkedIn test endpoint | 0 |

HTTP checks used curl only. No browser JavaScript execution, CTA click, form submit or
checkout flow was performed.

## Non-regression other services

| Surface | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Website DEV | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | unchanged | OK |
| API DEV/PROD | unchanged | unchanged | OK |
| Client DEV/PROD | unchanged | unchanged | OK |
| Backend DEV/PROD | unchanged | unchanged | OK |
| Admin DEV/PROD | unchanged | unchanged | OK |
| latest | unchanged | 706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5 / sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8 | OK |
| Other manifests | unchanged | only k8s/website-prod/deployment.yaml changed | OK |

## Rollback plan, not executed

Rollback must remain GitOps strict:

1. edit k8s/website-prod/deployment.yaml back to ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod;
2. commit the rollback manifest;
3. push origin main;
4. run `kubectl apply -f k8s/website-prod/deployment.yaml`;
5. run rollout status;
6. verify pod imageID `ghcr.io/keybuzzio/keybuzz-website@sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac`.

No rollback was executed in PH-21.68.

## Debts and risks

1. Global Website lint debt remains from PH-21.65/PH-21.66.
2. npm audit dependency debt remains from PH-21.66.
3. Client GA4 runtime parity remains separate.
4. Webflow try.keybuzz.io owner forwarding remains separate.
5. SRE backfill-scheduler debt remains separate.

## Verdict

GO APPLY WEBSITE PROD HERO COPY AND BODY PARITY GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.68

Next GO:

GO READONLY VERIFY WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.69
