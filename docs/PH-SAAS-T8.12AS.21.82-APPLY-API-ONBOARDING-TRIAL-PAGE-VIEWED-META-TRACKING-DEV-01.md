# PH-SAAS-T8.12AS.21.82 - APPLY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV

## RESUME LUDOVIC - TERMINAL

Verdict: READY_WITH_DEBTS - API DEV DEPLOYED VIA GITOPS PH-SAAS-T8.12AS.21.82

API DEV deployee via GitOps strict sur `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev`.

Manifest GitOps commit/push avant apply: `388bbaf deploy(api-dev): apply trial_page_viewed meta tracking image`.

Apply execute uniquement avec `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`; rollout successful.

Runtime conforme: manifest = last-applied = deployment spec = pod spec, pod imageID digest `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`.

API DEV Ready `1/1`, pod `keybuzz-api-79cf988674-b4cfj`, restarts `0`, health OK.

Markers in-pod OK: `trial_page_viewed` present, helper present, `StartTrial/Purchase` presents, `dist/tests` absent.

DB/tracking delta zero: aucun `trial_page_viewed`, aucun event reel/fake, aucun formulaire, aucun checkout, aucune DB mutation.

Prochain GO recommande: GO READONLY VERIFY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.83

STOP

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.82_CE_MISSION.md` | Lu |
| `AI_MEMORY/CURRENT_STATE.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu |
| `AI_MEMORY/DOCUMENT_MAP.md` | Lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.81_CE_RETURN.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.80_CE_RETURN.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.79_CE_RETURN.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.79_PUSH_CE_RETURN.md` | Lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.81-PUSH-IMAGE-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md` | Lu |

## Preflight

Bastion: `install-v3`.

IP publique: `46.62.171.61`.

Kube context: `kubernetes-admin@kubernetes`.

Timestamp preflight UTC: `2026-06-21T22:10:27Z`.

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-infra | `main` | `c45fe935` puis `388bbaf0` manifest | `388bbaf0` apres push | `0 0` apres push | 0 apres push | OK |
| keybuzz-api | `ph147.4/source-of-truth` | `35673e3b` | `35673e3b` | `0 0` | 223 | OK, dist preexistant |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ad4e862a` | `ad4e862a` | `0 0` | 1 | Read-only |
| keybuzz-website | `main` | `bd32fc8b` | `bd32fc8b` | `0 0` | 0 | Read-only |
| keybuzz-admin-v2 | `main` | `3707c834` | `3707c834` | `0 0` | 0 | Read-only |
| keybuzz-backend | `main` | `c38583a8` | `c38583a8` | `0 0` | 1 | Read-only |

API source_status: `0`.

API dist dirty: `223`, suppressions `dist/` preexistantes.

## Runtime baseline avant apply

| Service | Env | Manifest/spec image | Pod imageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| API | DEV | `v3.5.263-llm-provider-credit-watcher-dev` | `sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996` | 1/1 | 0 | Baseline OK |
| API | PROD | `v3.5.262-llm-provider-credit-alerting-prod` | `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | 1/1 | 0 | Inchange |
| Client | DEV | `v3.5.259-ai-assist-notification-scope-dev` | n/a | 1/1 | 0 | Inchange |
| Client | PROD | `v3.5.259-ai-assist-notification-scope-prod` | n/a | 1/1 | 0 | Inchange |
| Website | DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | n/a | 1/1 | 0 | Inchange |
| Website | PROD | `v0.7.2-visual-hero-parity-prod` | n/a | 2/2 | 0 | Inchange |
| Admin | DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | n/a | 1/1 | 0 | Inchange |
| Admin | PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | n/a | 1/1 | 0 | Inchange |
| Backend | DEV/PROD | images existantes | n/a | visibles | n/a | Read-only |

Deployment API DEV avant:

- generation `502`
- observedGeneration `502`
- spec image `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev`
- last-applied image `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev`

## DB snapshot read-only avant

Requete executee depuis le pod API DEV via Node/pg avec `BEGIN TRANSACTION READ ONLY`, puis `ROLLBACK`.

| Table | Signal | Count avant | Note |
| --- | --- | ---: | --- |
| `funnel_events` | total | 113 | read-only |
| `funnel_events` | `trial_page_viewed` | 0 | column `event_name` |
| `conversion_events` | total | 0 | read-only |
| `conversion_events` | `trial_page_viewed` | 0 | column `event_name` |
| `outbound_conversion_delivery_logs` | total | 7 | read-only |
| `outbound_conversion_delivery_logs` | `trial_page_viewed` | 0 | column `event_name` |

Snapshot UTC: `2026-06-21T22:10:34.358Z`.

## Manifest patch

Manifest API DEV exact:

`k8s/keybuzz-api-dev/deployment.yaml`

Les autres candidats (`outbound-worker`, `prod`, `seller`, `studio`) ont ete exclus du scope.

| Fichier | Champ | Avant | Apres | Verdict |
| --- | --- | --- | --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | container image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev` | PASS |
| `k8s/keybuzz-api-dev/deployment.yaml` | rollback commentaire | `v3.5.262-llm-provider-credit-alerting-dev` | `v3.5.263-llm-provider-credit-watcher-dev` | PASS documentaire |
| `k8s/keybuzz-api-dev/deployment.yaml` | `TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID` | absent | absent | PASS |

Diff final: `1 insertion`, `1 deletion`, uniquement la ligne image/commentaire.

## Validation manifest

| Validation | Resultat | Verdict |
| --- | --- | --- |
| `git diff --check -- k8s/keybuzz-api-dev/deployment.yaml` | OK | PASS |
| Absence env `TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID` | absent | PASS |
| Dry-run client | `deployment.apps/keybuzz-api configured (dry run)` | PASS |
| Dry-run server | `deployment.apps/keybuzz-api configured (server dry run)` | PASS |

## Commit + push GitOps

| Repo | Commit | Fichiers inclus | HEAD=origin | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-infra | `388bbaf deploy(api-dev): apply trial_page_viewed meta tracking image` | `k8s/keybuzz-api-dev/deployment.yaml` | oui | 0 | PASS |

Avant commit: HEAD `c45fe935`, origin `c45fe935`, ahead/behind `0 0`, dirty `1`.

Apres push: HEAD `388bbaf0`, origin `388bbaf0`, ahead/behind `0 0`, dirty `0`.

## Apply GitOps DEV

| Action | Commande | Resultat | Verdict |
| --- | --- | --- | --- |
| Apply manifest API DEV | `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured` | PASS |
| Rollout API DEV | `kubectl -n keybuzz-api-dev rollout status deployment/keybuzz-api --timeout=300s` | `successfully rolled out` | PASS |

Aucun autre manifest applique.

Generation avant: `502`.

Generation apres: `503`.

## Runtime verify API DEV

| Controle runtime | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Manifest Git image | tag `v3.5.264` | tag `v3.5.264` ligne 329 | PASS |
| Last-applied image | tag `v3.5.264` | tag `v3.5.264` | PASS |
| Deployment spec image | tag `v3.5.264` | tag `v3.5.264` | PASS |
| Pod spec image | tag `v3.5.264` | tag `v3.5.264` | PASS |
| Pod imageID digest | `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | `ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | PASS |
| Ready | 1/1 | 1/1 | PASS |
| Restarts | 0 attendu | 0 | PASS |
| Health | OK | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` | PASS |
| Logs boot | no crash | server listening, no crash/fatal observed in filtered probe | PASS |

Pod final:

`keybuzz-api-79cf988674-b4cfj`

Started at: `2026-06-21T22:14:08Z`.

## Marker audit in-pod

Audit statique uniquement dans `/app/dist`; aucun endpoint event appele.

| Marker | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| `trial_page_viewed` | present | count 7 | PASS |
| Helper PH-21.79 | present | count 3 | PASS |
| Meta CAPI/custom mapping files | present | count 2 | PASS |
| `StartTrial` | present | count 9 | PASS |
| `Purchase` | present | count 31 | PASS |
| `dist/tests` | absent | 0 fichier | PASS |
| Test PH-21.79 | absent | 0 fichier | PASS |
| Token brut simple grep | absent | 0 pattern | PASS |

## DB snapshot read-only apres

Requete executee depuis le nouveau pod API DEV via Node/pg avec `BEGIN TRANSACTION READ ONLY`, puis `ROLLBACK`.

Snapshot UTC: `2026-06-21T22:16:02.291Z`.

| Table | Signal | Count avant | Count apres | Delta | Verdict |
| --- | --- | ---: | ---: | ---: | --- |
| `funnel_events` | total | 113 | 113 | 0 | PASS |
| `funnel_events` | `trial_page_viewed` | 0 | 0 | 0 | PASS |
| `conversion_events` | total | 0 | 0 | 0 | PASS |
| `conversion_events` | `trial_page_viewed` | 0 | 0 | 0 | PASS |
| `outbound_conversion_delivery_logs` | total | 7 | 7 | 0 | PASS |
| `outbound_conversion_delivery_logs` | `trial_page_viewed` | 0 | 0 | 0 | PASS |

## Non-regression services

| Surface | Avant | Apres | Verdict |
| --- | --- | --- | --- |
| API DEV | `v3.5.263-llm-provider-credit-watcher-dev` | `v3.5.264-onboarding-trial-page-viewed-meta-dev` | Changement attendu |
| API DEV worker | `v3.5.165-escalation-flow-dev` | inchange | PASS |
| API PROD | `v3.5.262-llm-provider-credit-alerting-prod` | inchange | PASS |
| API PROD worker | `v3.5.165-escalation-flow-prod` | inchange | PASS |
| Client DEV | `v3.5.259-ai-assist-notification-scope-dev` | inchange | PASS |
| Client PROD | `v3.5.259-ai-assist-notification-scope-prod` | inchange | PASS |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | inchange | PASS |
| Website PROD | `v0.7.2-visual-hero-parity-prod` | inchange | PASS |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | inchange | PASS |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | inchange | PASS |
| Backend DEV/PROD | images existantes | inchangees | PASS |
| GHCR `latest` | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | meme hash | PASS |

## No fake metrics / no fake events

| Surface | Resultat |
| --- | --- |
| Event Meta/TikTok/LinkedIn/GA4/sGTM reel | Non execute |
| Endpoint test CAPI | Non appele |
| Event `trial_page_viewed` reel | Non execute |
| Event `StartTrial` reel | Non execute |
| Event `Purchase` reel | Non execute |
| Fake event | Non execute |
| Formulaire `/register` | Non soumis |
| Checkout Stripe | Non execute |
| DB mutation | Non executee |
| `conversion_events` delta | 0 |
| `funnel_events` delta | 0 |
| `outbound_conversion_delivery_logs` delta | 0 |

## Interdits respectes

| Interdit | Resultat |
| --- | --- |
| Docker build | Non execute |
| Docker push | Non execute |
| PROD deploy | Non execute |
| Changement Client/Website/Admin/Backend | Non execute |
| Changement Webflow/Linear | Non execute |
| Changement secret | Non execute |
| Env owner `TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID` | Non ajoute |
| Hardcode owner tenant | Non ajoute |
| Commandes kubectl imperatives hors apply/rollout/read-only | Non executees |

## Rollback DEV documentaire

Rollback futur GitOps si requis, non execute dans PH-21.82:

1. Modifier `k8s/keybuzz-api-dev/deployment.yaml` pour revenir a `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev`.
2. Commit + push.
3. Appliquer le manifest API DEV exact.
4. Attendre le rollout.
5. Verifier runtime = manifest = last-applied.

## Dettes et prochain GO

| Dette | Priorite | Prochain GO |
| --- | --- | --- |
| Verification read-only post-deploy sur fenetre separee | Normale | `GO READONLY VERIFY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.83` |
| Observation d'un vrai `trial_page_viewed` naturel | Traffic required | Phase read-only/real traffic, aucun fake event |
| Configuration owner tenant explicite non ajoutee | Hors scope volontaire | Phase config dediee si decision produit |

## Verdict final

GO APPLY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.82

STOP
