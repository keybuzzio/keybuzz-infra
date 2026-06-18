RESUME LUDOVIC - TERMINAL
PH-21.75 APPLY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW GITOPS : READY_WITH_DEBTS
Manifest GitOps : k8s/website-prod/deployment.yaml modifie image only, commit deploy 0b44af2ba18b42ac5c3a3d2a19ef5326300acf8d pousse avant apply.
Image PROD : ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod -> ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod
Digest runtime : sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 ; config/Image ID : sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2
Rollout : successful ; Ready 2/2 ; generation 38/38
Equality : manifest=last-applied=spec=pod image OK ; pod imageID digest OK.
Smoke/bundle/tracking : /, /pricing, /contact OK ; kb2/kb2-hero OK ; tracking PROD conserve ; URLs DEV/prix/KPI/fake triggers absents ; Lead=1 (REVIEWED_NON_BLOCKING)
Non-regression : Website DEV/API/Client/Backend/Admin/latest inchanges ; aucun build/docker push/formulaire/checkout/event/Webflow/Linear
Rapport infra : /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.75-APPLY-WEBSITE-PROD-VISUAL-HERO-PARITY-FROM-PREVIEW-GITOPS-01.md
Prochain GO exact : GO READONLY VERIFY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.76
GO APPLY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.75
STOP

# PH-SAAS-T8.12AS.21.75 - Apply Website PROD visual hero parity from preview GitOps

## Scope

GITOPS PROD strict respecte.

- Manifest modifie : k8s/website-prod/deployment.yaml uniquement.
- Commit + push manifest avant apply : 0b44af2ba18b42ac5c3a3d2a19ef5326300acf8d.
- Dry-run client et server effectues avant apply.
- Apply effectue uniquement par kubectl apply -f k8s/website-prod/deployment.yaml.
- Rollout status effectue.
- Aucun build.
- Aucun docker push.
- Aucun retag/latest.
- Aucun autre service modifie.
- Aucun fake event, formulaire, checkout, Webflow ou Linear.

## Sources relues

| Source | Statut |
|---|---|
| PH-21.75 mission locale | relue |
| AI_MEMORY CURRENT_STATE | relue |
| AI_MEMORY RULES_AND_RISKS | relue |
| AI_MEMORY DOCUMENT_MAP | relue |
| AI_MEMORY CE_PROMPTING_STANDARD | relue |
| PH-T8.10J modele | relu |
| PH-21.68 retour | relu |
| PH-21.72 retour | relu |
| PH-21.73 retour | relu |
| PH-21.74 retour | relu |
| PH-21.71/21.72/21.73/21.74 docs bastion | disponibles |
| Website BUILD-ARGS | disponible |

## Preflight

| Controle | Attendu | Observe | Verdict |
|---|---|---|---|
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | present | PASS |
| Kube context | cluster install-v3 | kubernetes-admin@kubernetes | PASS |
| Infra branch | main | main | PASS |
| Infra HEAD before report | deploy commit | 0b44af2ba18b42ac5c3a3d2a19ef5326300acf8d | PASS |
| Infra origin before report | deploy commit | 0b44af2ba18b42ac5c3a3d2a19ef5326300acf8d | PASS |
| Infra ahead/behind before report | 0/0 | 0/0 | PASS |
| Infra dirty before report | 0 | 0 | PASS |
| Website branch | main | main | PASS |
| Website HEAD | bd32fc8bc9d9554770cc611f0712998b111473ff | bd32fc8bc9d9554770cc611f0712998b111473ff | PASS |
| Website origin | bd32fc8bc9d9554770cc611f0712998b111473ff | bd32fc8bc9d9554770cc611f0712998b111473ff | PASS |
| Website ahead/behind | 0/0 | 0/0 | PASS |
| Website dirty | 0 | 0 | PASS |
| GHCR target manifest | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | PASS |
| GHCR target config | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | PASS |
| latest baseline | unchanged | present:sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8:sha256:8b129ecf1ee364284cdf9b0dc4f94ed2cda99fc38aa4d5492cc1d9fe928f5ace | PASS |

## Manifest

| Fichier | Changement | Commit | Push avant apply | Verdict |
|---|---|---|---|---|
| k8s/website-prod/deployment.yaml | image tag only | 0b44af2ba18b42ac5c3a3d2a19ef5326300acf8d | oui | PASS |

Deploy commit files:

```text
k8s/website-prod/deployment.yaml
```

## Dry-run / Apply

| Action | Attendu | Resultat | Verdict |
|---|---|---|---|
| dry-run client | OK | deployment.apps/keybuzz-website configured (dry run)
service/keybuzz-website configured (dry run)
namespace/keybuzz-website-prod configured (dry run) | PASS |
| dry-run server | OK | deployment.apps/keybuzz-website configured (server dry run)
service/keybuzz-website unchanged (server dry run)
namespace/keybuzz-website-prod unchanged (server dry run) | PASS |
| kubectl apply -f | OK | deployment.apps/keybuzz-website configured
service/keybuzz-website unchanged
namespace/keybuzz-website-prod unchanged | PASS |
| rollout status | successful | Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-website" successfully rolled out | PASS |

Note : le premier smoke interne via ClusterIP depuis le bastion a expire apres le rollout. Les smokes finaux ont donc ete faits en GET passif via https://www.keybuzz.pro, sans execution JS, sans clic, sans formulaire.

## Runtime Equality

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Manifest file | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | target count=1 old count=0 | PASS |
| Last-applied | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Deployment spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Pod spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Pod imageID | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | all final pods match | PASS |
| Ready | 2/2 | 2/2 | PASS |
| Generation | observed=current | 38/38 | PASS |

Pods finaux :

```text
keybuzz-website-fbbcf885-74tcl|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4
keybuzz-website-fbbcf885-h65s4|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4
```

## Smoke HTTP passif

| Route | Attendu | Observe | Verdict |
|---|---|---|---|
| / | 200, HTML non vide | 84125 bytes | PASS |
| /pricing | 200, HTML non vide | 71713 bytes | PASS |
| /contact | 200, HTML non vide | 28362 bytes | PASS |
| chunks statiques | lus passivement | 16 paths | PASS |

## Bundle / tracking passive audit

| Marker | Attendu | Observe | Verdict |
|---|---|---:|---|
| kb2 | present | 3 | PASS |
| kb2-hero | present | 3 | PASS |
| grid-overlay | present/equivalent | 3 | INFO |
| Reprenez le contr | present | 2 | PASS |
| marges | present | 2 | PASS |
| Vous validez | present | 4 | PASS |
| automatisez seulement | present | 2 | PASS |
| Ce que KeyBuzz change | present | 2 | PASS |
| Si vous vendez sur marketplace | present | 2 | PASS |
| SP-API | present | 4 | PASS |
| Questions frequentes | present | 4 | PASS |
| client.keybuzz.io | present | 6 | PASS |
| api.keybuzz.io/api/public/contact | present | 1 | PASS |
| t.keybuzz.pro | present | 4 | PASS |
| wrff07upjx | present | 1 | PASS |
| G-R3QQDYEBFG | present | 4 | PASS |
| 1234164602194748 | present | 1 | PASS |
| D7PT12JC77U44OJIPC10 | present | 1 | PASS |
| 9969977 | present | 4 | PASS |

## Forbidden marker audit

| Marker | Attendu | Observe | Verdict |
|---|---|---:|---|
| client-dev.keybuzz.io | absent | 0 | PASS |
| api-dev.keybuzz.io | absent | 0 | PASS |
| v0.7.1-hero-copy-prod-body-parity-dev | absent | 0 | PASS |
| 49 EUR | absent | 0 | PASS |
| 199 EUR | absent | 0 | PASS |
| 49e/mois | absent | 0 | PASS |
| 199e/mois | absent | 0 | PASS |
| -84 | absent | 0 | PASS |
| StartTrial direct fake trigger | absent | 0 | PASS |
| Purchase direct fake trigger | absent | 0 | PASS |
| CompletePayment direct fake trigger | absent | 0 | PASS |
| InitiateCheckout direct fake trigger | absent | 0 | PASS |
| Lead | absent or reviewed non-blocking | 1 (REVIEWED_NON_BLOCKING) | PASS |

## Non-regression

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Website PROD | target live | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Website DEV | inchange | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev ; ready 1/1 ; gen 69/69 | PASS |
| API DEV/PROD | inchange | PASS | PASS |
| Client DEV/PROD | inchange | PASS | PASS |
| Backend DEV/PROD | inchange | PASS | PASS |
| Admin DEV/PROD | inchange | PASS | PASS |
| GHCR latest | inchange | present:sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8:sha256:8b129ecf1ee364284cdf9b0dc4f94ed2cda99fc38aa4d5492cc1d9fe928f5ace | PASS |
| DB | aucune mutation volontaire | PASS | PASS |
| Tracking | aucun event volontaire | PASS | PASS |
| Webflow | aucune mutation | PASS | PASS |
| Linear | aucune mutation | PASS | PASS |

## Rollback GitOps documente seulement

Sous GO separe uniquement :

1. Remettre k8s/website-prod/deployment.yaml sur ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod.
2. Commit + push.
3. kubectl apply -f k8s/website-prod/deployment.yaml.
4. kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod.
5. Verifier manifest=last-applied=spec=pod image et digest sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b.

Aucun rollback execute dans PH-21.75.

## Dettes restantes

1. Verification visuelle utilisateur post-deploy possible apres PH-21.75.
2. Read-only verify separe PH-21.76 requis.
3. Dettes Website connues : lint global et npm audit dependencies.
4. Webflow try.keybuzz.io et attribution Meta reelle restent sujets separes.
5. Client GA4 parity reste dette separee.
6. Backfill-scheduler reste dette SRE separee.
7. PreviewBanner guard reste dette non bloquante documentee.

## Verdict

READY_WITH_DEBTS.

Prochain GO exact :

```
GO READONLY VERIFY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.76
```
