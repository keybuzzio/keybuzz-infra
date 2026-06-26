# PH-SAAS-T8.12AS.21.128 - Apply API no-card trial entitlement and launch pricing 2026 DEV GitOps

Date UTC: 2026-06-26
Worker: CE technical worker
Scope: GitOps strict API DEV runtime only

## RESUME LUDOVIC

Verdict: READY_WITH_DEBTS

API DEV appliquee via GitOps strict avec l'image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev`

Digest runtime pod:

`sha256:d8a2c18b441aaabb876e735e5f43dd890aef0f4b8eff746f9a43331d9e59d5ab`

Egalite validee: manifest = last-applied = deployment spec = pod spec = pod imageID digest.

Runtime API DEV: ready 1/1, pod Running, restarts 0, health OK, audit markers PASS.

Aucun build, aucun docker push, aucun patch source, aucun DB write volontaire, aucun Stripe live call, aucun fake event, aucune mutation PROD.

Prochain GO recommande:

`GO READONLY VERIFY API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.129`

## Sources relues

- `C:\DEV\KeyBuzz\tmp\PH-21.128_CE_MISSION.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.127_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.126_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.125_PUSH_CE_RETURN.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_FILE_HANDOFF_PROTOCOL.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.127-PUSH-IMAGE-API-NO-CARD-TRIAL-ENTITLEMENT-AND-LAUNCH-PRICING-2026-DEV-01.md`

Aucune contradiction bloquante detectee.

## Preflight

| Controle | Resultat |
| --- | --- |
| Bastion | `install-v3` |
| IP obligatoire | `46.62.171.61` presente |
| IP interdite | `51.159.99.247` non utilisee |
| Date UTC | `2026-06-26T15:32:27Z` |
| Infra branch | `main` |
| Infra HEAD preflight | `90947bfd5d247d03c9e74e82459ee21dc1fa134d` |
| Infra origin/main preflight | `90947bfd5d247d03c9e74e82459ee21dc1fa134d` |
| Infra ahead/behind | `0/0` |
| Infra dirty | clean |
| Manifest API DEV avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` |
| Runtime API DEV avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` |
| Runtime API PROD avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Image cible GHCR | presente |
| Digest cible GHCR | `sha256:d8a2c18b441aaabb876e735e5f43dd890aef0f4b8eff746f9a43331d9e59d5ab` |
| `latest` avant | `sha256:71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |

## Snapshot read-only avant

| Element | Avant |
| --- | --- |
| Pod | `keybuzz-api-8fc76d898-jsjmk` |
| Deploy image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` |
| Ready | `1/1` |
| Pod phase | `Running` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` |
| Pod restarts | `0` |
| Health | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| Log secret pattern count | `0` |

Compteurs DB read-only avant:

| Table | Avant |
| --- | ---: |
| `funnel_events` | 114 |
| `conversion_events` | 0 |
| `outbound_conversion_delivery_logs` | 7 |
| `billing_events` | 405 |
| `subscriptions` | missing |

## Manifest diff

Fichier modifie:

`/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`

| Fichier | Avant | Apres | Verdict |
| --- | --- | --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` | OK, une seule ligne `image:` modifiee |

Commit deploy GitOps:

- Commit: `b3e5e711b2c99ef3e01acad0e39cf6e783090bb4`
- Message: `deploy(api-dev): apply no-card trial launch pricing image`
- Push: PASS
- Infra avant apply: HEAD = origin/main = `b3e5e711b2c99ef3e01acad0e39cf6e783090bb4`, ahead/behind `0/0`, dirty clean

## Apply GitOps strict

Commande executee:

```bash
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
```

Sortie:

```text
deployment.apps/keybuzz-api configured
```

Rollout:

```bash
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev --timeout=180s
```

Resultat:

```text
deployment "keybuzz-api" successfully rolled out
```

Aucun `kubectl set image`, `kubectl set env`, `kubectl patch`, `kubectl edit`, ni `kubectl rollout restart`.

## Runtime verify DEV

| Verification | Attendu | Resultat |
| --- | --- | --- |
| Pod | nouveau pod API DEV | `keybuzz-api-65fd596689-wxs46` |
| Manifest image | image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| Last-applied image | image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| Deployment spec image | image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| Pod spec image | image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| Pod imageID digest | `sha256:d8a2c18b441aaabb876e735e5f43dd890aef0f4b8eff746f9a43331d9e59d5ab` | `ghcr.io/keybuzzio/keybuzz-api@sha256:d8a2c18b441aaabb876e735e5f43dd890aef0f4b8eff746f9a43331d9e59d5ab` |
| Generation observed | generation = observed | `505 = 505` |
| Ready | `1/1` | `1/1` |
| Pod phase | `Running` | `Running` |
| Pod ready | `true` | `true` |
| Restarts | `0` | `0` |
| Health | OK | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| Fatal/crash logs | `0` | `0` |
| Secret pattern logs | `0` | `0` |

Note logs: un compteur large du mot `error` vaut `1` dans les logs recents, sans fatal/crash et sans pattern secret. Non bloquant, documente en dette/bruit d'observabilite.

## Runtime markers

Audit dans le pod API DEV:

```text
PRICING_2026:9
NO_CARD_TRIAL:9
START_TRIAL:6
PURCHASE:4
COMPLETE_PAYMENT:1
TRIAL_PAGE_VIEWED:7
REGISTER_STARTED:7
PROVIDER_CREDIT_EXHAUSTED:13
META_CAPI_OBSERVABILITY:15
PROVIDER_ERROR_NORMALIZER_OK
OUTBOUND_EMITTER_OK
META_CAPI_ADAPTER_OK
TEST_PH21125_ABSENT_OK
NO_ENV_FILE_OK
NO_SECRET_PATTERN_OK
```

Resultat: PASS.

AI feature parity / anti-regression:

- pricing/no-card presents.
- `StartTrial`, `Purchase`, `CompletePayment` presents.
- `trial_page_viewed`, `register_started` presents.
- `PROVIDER_CREDIT_EXHAUSTED` present.
- Meta CAPI observability preservee.
- Tests PH-21.125 absents du runtime.
- Pas de fichier `.env` detecte.
- Pas de pattern secret evident detecte dans l'audit realise.

## Snapshot read-only apres

| Element | Apres |
| --- | --- |
| Pod | `keybuzz-api-65fd596689-wxs46` |
| Deploy image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| Ready | `1/1` |
| Pod phase | `Running` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:d8a2c18b441aaabb876e735e5f43dd890aef0f4b8eff746f9a43331d9e59d5ab` |
| Pod restarts | `0` |
| Health | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| Log secret pattern count | `0` |

Compteurs DB read-only apres:

| Table | Avant | Apres | Delta |
| --- | ---: | ---: | ---: |
| `funnel_events` | 114 | 114 | 0 |
| `conversion_events` | 0 | 0 | 0 |
| `outbound_conversion_delivery_logs` | 7 | 7 | 0 |
| `billing_events` | 405 | 405 | 0 |
| `subscriptions` | missing | missing | n/a |

No fake metrics / no fake events: PASS.

- Aucun `StartTrial` cree.
- Aucun `Purchase` cree.
- Aucun `CompletePayment` cree.
- Aucun `trial_page_viewed` cree.
- Aucun `register_started` cree.
- Aucun POST `/funnel/event`.
- Aucun CAPI/GA4/TikTok/LinkedIn call.
- Aucun Stripe call.
- Aucun checkout.

## Non-regression services

| Service | Image apres |
| --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` |
| Admin DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev` |
| Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod` |
| Website DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` |
| Website PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod` |
| Backend DEV | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev` |
| Backend PROD | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod` |

`latest` GHCR apres:

`sha256:71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549`

`latest` intact: PASS.

## No side-effect

- Aucun build/rebuild.
- Aucun docker push.
- Aucun patch source API.
- Aucun patch Client/Website/Admin/Backend.
- Aucun apply PROD.
- Aucun `kubectl set image`.
- Aucun `kubectl set env`.
- Aucun `kubectl patch`.
- Aucun `kubectl edit`.
- Aucun `kubectl rollout restart`.
- Aucun DB write volontaire.
- Aucun Stripe live call.
- Aucun checkout.
- Aucun fake event.
- Aucun CAPI retry/replay.
- Aucun secret/token affiche volontairement.
- Aucun Webflow.
- Aucune mutation Linear.

## Rollback documente

Rollback DEV documente, non execute:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev`

Si necessaire dans une phase separee avec GO explicite: rollback uniquement par GitOps strict manifest -> commit -> push -> `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout status -> verify.

## Dettes / points d'attention

| Dette | Impact | Action proposee |
| --- | --- | --- |
| Workspace principal API dirty avec suppressions `dist/` preexistantes, documente en PH-21.126 | Non bloquant pour PH-21.128; aucune source API touchee, aucun build | Ne pas nettoyer sans GO explicite |
| `npm audit` PH-21.126 signalait 14 vulnerabilites, dont 9 high | Dette dependencies preexistante, pas liee au deploy GitOps | Planifier audit dependencies hors PH-21.128 |
| Logs API DEV recents contiennent 1 occurrence du mot `error`, mais `fatal/crash=0`, restarts `0`, health OK | Bruit d'observabilite non bloquant | Relire en phase readonly PH-21.129 si besoin |

## Verdict

READY_WITH_DEBTS

API DEV deployee via GitOps strict, egalite manifest/last-applied/spec/pod/digest OK, health OK, markers runtime PASS, deltas DB/tracking 0, services hors scope inchanges.

Phrase finale:

`GO APPLY API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.128`

Prochain GO recommande:

`GO READONLY VERIFY API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.129`

STOP.
