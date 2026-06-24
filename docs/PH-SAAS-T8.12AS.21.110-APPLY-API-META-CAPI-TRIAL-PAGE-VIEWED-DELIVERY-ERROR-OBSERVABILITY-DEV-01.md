# PH-SAAS-T8.12AS.21.110 - Apply API Meta CAPI trial_page_viewed delivery error observability DEV

Date UTC: 2026-06-24T10:33:08Z

## Verdict

GO APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV GITOPS READY_WITH_LIMITS PH-SAAS-T8.12AS.21.110

Limit: this phase proves DEV runtime, digest, equality and markers. It does not force or replay a Meta CAPI failure, so persistence of a future real provider error remains to be observed in a later read-only/traffic-authorized phase.

## GO exact

GO APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV GITOPS PH-SAAS-T8.12AS.21.110

## Scope

Applied only the API DEV GitOps manifest to deploy:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev`

Expected GHCR digest:

`sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb`

Expected image ID / config digest:

`sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0`

Source API revision:

`547648fd`

## Sources relues

AI memory and prompt standards:

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`
- `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`

Phase reports:

- PH-21.79 source patch: API commit `35673e3b`, server-side `trial_page_viewed`, no fake event.
- PH-21.82 apply DEV: API DEV v3.5.264 deployed via GitOps, digest `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`.
- PH-21.84 close DEV: API DEV closed with limits, runtime equality OK, no natural traffic.
- PH-21.92 design: API PROD first, Client PROD second.
- PH-21.95 apply PROD: API PROD v3.5.264 deployed via GitOps, digest `sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad`.
- PH-21.97 close PROD: API PROD closed with limits, Client PROD not yet promoted at that time.
- PH-21.102 close Client PROD: Client owner payload chain closed with limits.
- PH-21.103 design real traffic: real traffic validation needs explicit window.
- PH-21.104 observe: real `/register` path produced `trial_page_viewed`; delivery failed.
- PH-21.105 RCA: delivery failed evidence insufficient.
- PH-21.106 deep RCA: observability gap confirmed, error field unclassified.
- PH-21.107 source patch: Meta CAPI safe provider error normalization and persistence, API commit `547648fd`.
- PH-21.108 build: DEV image built from clean Git worktree, Image ID `sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0`.
- PH-21.109 push: GHCR digest `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb`, pull-back OK, latest intact.

## Preflight bastion

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| hostname | install-v3 | install-v3 | PASS |
| public IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| forbidden IP | absent | 51.159.99.247 absent | PASS |
| date UTC | captured | 2026-06-24T10:26:48Z | PASS |

## Repo / branche / HEAD / dirty

| Repo | Branche | HEAD | Dirty | Ahead/behind | Verdict |
|---|---|---:|---|---|---|
| keybuzz-infra before patch | main | f280f41 | 0 | 0/0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 223 tracked dist deletions, non-dist dirty 0 | 0/0 | PASS documented preexisting dist-only debt |
| keybuzz-infra after manifest push | main | 05b7e71 | 0 | 0/0 | PASS |

## Registry precheck

| Image | Tag | Manifest digest attendu | Digest observe | Image ID attendu | Image ID observe | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | v3.5.265-meta-capi-error-observability-dev | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | RepoDigest local ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | PASS |

Latest API manifest JSON hash:

`71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549`

## Snapshots avant apply

| Surface | Snapshot avant | Methode | Mutation possible | Verdict |
|---|---|---|---|---|
| API DEV manifest | v3.5.264-onboarding-trial-page-viewed-meta-dev | grep manifest | none | PASS |
| API DEV deployment/last-applied | v3.5.264-onboarding-trial-page-viewed-meta-dev | kubectl get deploy jsonpath | none | PASS |
| API DEV pod | digest sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669, ready true, restarts 0 | kubectl get pod | none | PASS |
| DB DEV counters | funnel_events 113, conversion_events 0, outbound_conversion_delivery_logs 7 | transaction read only in API pod | none | PASS |
| API PROD | v3.5.264-onboarding-trial-page-viewed-meta-prod | kubectl get deploy/pod | none | PASS |
| Client DEV/PROD | v3.5.260 owner payload images | kubectl get deploy | none | PASS |
| Website/Admin/Backend | observed unchanged baseline | kubectl get deploy | none | PASS |

## Manifest / GitOps

| Fichier | Changement | Commit | Push avant apply | Verdict |
|---|---|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | one `image:` line changed from v3.5.264 DEV to v3.5.265 DEV | 05b7e71 | yes, ahead/behind 0/0 before apply | PASS |

Diff summary:

```diff
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev
```

Validation:

- `git diff --check`: PASS.
- Diff limited to `k8s/keybuzz-api-dev/deployment.yaml`: PASS.
- No manifest PROD changed: PASS.
- No Secret/ConfigMap/env/service/ingress/resource/namespace changed: PASS.
- No `latest`: PASS.

## Apply / rollout

| Commande | Namespace | Resultat | Verdict |
|---|---|---|---|
| `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` | keybuzz-api-dev | `deployment.apps/keybuzz-api configured` | PASS |
| `kubectl -n keybuzz-api-dev rollout status deployment/keybuzz-api --timeout=300s` | keybuzz-api-dev | `deployment "keybuzz-api" successfully rolled out` | PASS |

No `kubectl set image`, `kubectl set env`, `kubectl patch`, `kubectl edit`, or rollout restart was used.

## Equality runtime

| Controle | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| manifest image | ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev | same | PASS |
| last-applied image | same | same | PASS |
| deployment spec image | same | same | PASS |
| pod spec image | same | same | PASS |
| pod imageID digest | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | PASS |
| Ready | true / 1 of 1 | true / 1 of 1 | PASS |
| Restarts after rollout | 0 | 0 | PASS |
| Health | OK | `{"status":"ok","service":"keybuzz-api"}` | PASS |

## Runtime / image avant-apres

| Service | Avant | Apres | Digest avant | Digest apres | Verdict |
|---|---|---|---|---|---|
| API DEV | v3.5.264-onboarding-trial-page-viewed-meta-dev | v3.5.265-meta-capi-error-observability-dev | sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | EXPECTED_CHANGE |
| API PROD | v3.5.264-onboarding-trial-page-viewed-meta-prod | same | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | same | PASS |
| Client DEV | v3.5.260-onboarding-register-started-owner-payload-dev | same | n/a | n/a | PASS |
| Client PROD | v3.5.260-onboarding-register-started-owner-payload-prod | same | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | same | PASS |
| Website DEV | v0.7.1-hero-copy-prod-body-parity-dev | same | n/a | n/a | PASS |
| Website PROD | v0.7.2-visual-hero-parity-prod | same | n/a | n/a | PASS |
| Admin DEV | v2.12.2-media-buyer-lp-domain-qa-dev | same | n/a | n/a | PASS |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | same | n/a | n/a | PASS |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod for main backend/jobs-worker | same | n/a | n/a | PASS |
| GHCR latest API | manifest JSON hash 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | same | n/a | n/a | PASS |

## Tests / audits

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| provider-error-normalizer file | present | PRESENT | PASS |
| Meta CAPI adapter file | present | PRESENT | PASS |
| emitter file | present | PRESENT | PASS |
| `dist/tests` | absent | ABSENT | PASS |
| tests path artifacts | 0 | 0 | PASS |
| PH-21.107 artifacts | 0 | 0 | PASS |
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

## No fake events

| Surface | Delta attendu | Delta observe | Verdict |
|---|---:|---:|---|
| funnel_events total | 0 | 0 (113 -> 113) | PASS |
| funnel_events trial_page_viewed | 0 | 0 (0 -> 0) | PASS |
| conversion_events total | 0 | 0 (0 -> 0) | PASS |
| conversion_events trial_page_viewed | 0 | 0 (0 -> 0) | PASS |
| outbound_conversion_delivery_logs total | 0 | 0 (7 -> 7) | PASS |
| outbound_conversion_delivery_logs trial_page_viewed | 0 | 0 (0 -> 0) | PASS |
| POST /funnel/event | 0 | 0 CE command | PASS |
| retry/replay | 0 | 0 CE command | PASS |
| CAPI test endpoint | 0 | 0 CE command | PASS |

No fake `StartTrial`, `Purchase`, `CompletePayment`, `Lead`, `InitiateCheckout`, or `trial_page_viewed` was generated.

## Secret / PII

| Surface | Controle | Exposure | Verdict |
|---|---|---:|---|
| Kubernetes Secret.data | not read / not decoded | 0 | PASS |
| Vault secret values | not read | 0 | PASS |
| `/opt/keybuzz/credentials/` | not accessed | 0 | PASS |
| `/opt/keybuzz/secrets/` | not accessed | 0 | PASS |
| token / Authorization / cookie | not displayed | 0 | PASS |
| email / phone / user_data | not displayed | 0 | PASS |
| report payloads | no raw Meta payload | 0 | PASS |

## AI feature parity / anti-regression

| Feature | Controle | Resultat | Verdict |
|---|---|---|---|
| LLM provider credit signal | runtime marker | `PROVIDER_CREDIT_EXHAUSTED=13` | PASS |
| LLM provider errors route/marker | runtime marker | `llm-provider-errors=4` | PASS |
| AI usage | DB read-only via no fake event counters and no LLM call | no CE LLM call, no ai_usage mutation command | PASS |
| API health | internal `/health` on port 3001 | OK | PASS |
| Client/Admin/Website/Backend | deployment images unchanged | unchanged | PASS |

## Non-regression

| Service | Attendu | Observe | Verdict |
|---|---|---|---|
| API PROD | unchanged v3.5.264 PROD | unchanged | PASS |
| Client DEV | unchanged v3.5.260 DEV | unchanged | PASS |
| Client PROD | unchanged v3.5.260 PROD | unchanged | PASS |
| Website DEV | unchanged v0.7.1 DEV | unchanged | PASS |
| Website PROD | unchanged v0.7.2 PROD | unchanged | PASS |
| Admin DEV | unchanged v2.12.2 DEV | unchanged | PASS |
| Admin PROD | unchanged v2.12.2 PROD | unchanged | PASS |
| Backend DEV/PROD | unchanged observed images | unchanged | PASS |
| GHCR latest API | unchanged hash | unchanged | PASS |
| PROD manifests | not modified | not modified | PASS |
| monitoring/jobs/secrets | not modified | not modified | PASS |

## Rollback

ROLLBACK_NOT_EXECUTED.

Rollback reference if a later explicit GO requires it:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev`

Expected rollback digest:

`sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`

Rollback must remain GitOps strict only.

## Dettes / limites

- No real Meta CAPI failed delivery was forced or replayed in this phase.
- Persistence of a future real safe provider error must be verified later without fake events.
- Verdict remains `READY_WITH_LIMITS` by design because traffic validation is out of scope.

## Conclusion

API DEV now runs the Meta CAPI delivery error observability image via strict GitOps. Runtime digest, equality, markers, health and DB deltas are conforming. No fake event, DB mutation, build, docker push, PROD mutation, secret exposure or Linear mutation occurred.

Return file:

`C:\DEV\KeyBuzz\tmp\PH-21.110_CE_RETURN.md`

## Prochain GO

GO READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.111
