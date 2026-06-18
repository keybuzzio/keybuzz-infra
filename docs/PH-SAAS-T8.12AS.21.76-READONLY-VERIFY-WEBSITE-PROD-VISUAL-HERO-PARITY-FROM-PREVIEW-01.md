RESUME LUDOVIC - TERMINAL
PH-21.76 READONLY VERIFY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW : READY_WITH_DEBTS
Runtime PROD : ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod ; digest sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 ; Ready 2/2 ; generation 38/38 ; restarts 0/0.
Equality : manifest=last-applied=deployment spec=pod spec=ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod ; pod imageID digest OK.
Routes publiques : baseline 13 routes GET passif HTTP 200 ; routes hors baseline classees NOT_IN_BASELINE si absentes ; chunks lus=18.
Hero/body : kb2=3, kb2-hero=3, grid-overlay=3, WaveCanvas=0 INFO ; body PROD conserve.
Tracking passif : client/api contact/sGTM/Clarity/GA4/Meta/TikTok/LinkedIn presents ; URLs DEV/prix/KPI/fake triggers absents ; Lead=1 (REVIEWED_NON_BLOCKING).
Fake events : 0 declenche ; aucun navigateur JS, aucun clic, formulaire, checkout, Webflow ou Linear.
Non-regression : Website DEV/API/Client/Backend/Admin/latest inchanges.
Rapport infra : /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.76-READONLY-VERIFY-WEBSITE-PROD-VISUAL-HERO-PARITY-FROM-PREVIEW-01.md
Prochain GO exact : GO READONLY CLOSE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.77
GO READONLY VERIFY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW READY_WITH_DEBTS PH-SAAS-T8.12AS.21.76
STOP

# PH-SAAS-T8.12AS.21.76 - Readonly verify Website PROD visual hero parity from preview

## Scope

READONLY VERIFY strict respecte.

- Aucun patch source.
- Aucun manifest modifie.
- Aucun kubectl apply.
- Aucun rollout/restart/delete.
- Aucun build.
- Aucun docker push/tag/latest.
- Aucun fake event.
- Aucun formulaire.
- Aucun checkout.
- Aucun Webflow.
- Aucun Linear.
- Verification navigateur non utilisee : HTML/chunks passifs uniquement.

## Sources relues

| Source | Statut |
|---|---|
| PH-21.76 mission locale | relue |
| AI_MEMORY CURRENT_STATE | relue |
| AI_MEMORY RULES_AND_RISKS | relue |
| AI_MEMORY DOCUMENT_MAP | relue |
| AI_MEMORY CE_PROMPTING_STANDARD | relue |
| PH-T8.10J modele | relu |
| PH-21.69 retour | relu |
| PH-21.70 retour | relu |
| PH-21.71 retour | relu |
| PH-21.72 retour | relu |
| PH-21.73 retour | relu |
| PH-21.74 retour | relu |
| PH-21.75 retour | relu |
| Rapports bastion PH-21.71 a PH-21.75 | disponibles |
| Website BUILD-ARGS | disponible |

## Preflight

| Controle | Attendu | Observe | Verdict |
|---|---|---|---|
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | present | PASS |
| Kube context | cluster install-v3 | kubernetes-admin@kubernetes | PASS |
| Infra branch | main | main | PASS |
| Infra HEAD before report | descendant c8d7e54a66b5ddb426330afeaa316f2ad1d287a0 | c8d7e54a66b5ddb426330afeaa316f2ad1d287a0 | PASS |
| Infra origin before report | same | c8d7e54a66b5ddb426330afeaa316f2ad1d287a0 | PASS |
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

## Runtime K8s Equality

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Manifest file | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | target count=1 ; dev target count=0 | PASS |
| Last-applied | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Deployment spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Pod spec | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | PASS |
| Pod imageID | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | all final pods match | PASS |
| Ready pods | 2/2 | 2/2 | PASS |
| Generation observed/current | equal | 38/38 | PASS |

Pods finaux :

```text
keybuzz-website-fbbcf885-74tcl|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4
keybuzz-website-fbbcf885-h65s4|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4
```

## Routes publiques passives

GET passifs uniquement, sans navigateur JS, sans clic et sans formulaire.

| Route | Attendu | Observe | Verdict |
|---|---|---|---|
| / | 200, HTML non vide | 200 / 84125 bytes | PASS |
| /pricing | 200, HTML non vide | 200 / 71713 bytes | PASS |
| /contact | 200, HTML non vide | 200 / 28362 bytes | PASS |
| /privacy | 200, HTML non vide | 200 / 57150 bytes | PASS |
| /terms | 200, HTML non vide | 200 / 60145 bytes | PASS |
| /cookies | 200, HTML non vide | 200 / 46103 bytes | PASS |
| /legal | 200, HTML non vide | 200 / 38859 bytes | PASS |
| /features | 200, HTML non vide | 200 / 64451 bytes | PASS |
| /amazon | 200, HTML non vide | 200 / 47075 bytes | PASS |
| /integrations/google-ads | 200, HTML non vide | 200 / 47853 bytes | PASS |
| /about | 200, HTML non vide | 200 / 45701 bytes | PASS |
| /amazon/security | 200, HTML non vide | 200 / 48879 bytes | PASS |
| /amazon/data-usage | 200, HTML non vide | 200 / 45977 bytes | PASS |
| /security | 200 si route baseline, sinon NOT_IN_BASELINE | 404 / 23120 bytes | NOT_IN_BASELINE |
| /marketplaces | 200 si route baseline, sinon NOT_IN_BASELINE | 404 / 23120 bytes | NOT_IN_BASELINE |
| /integrations | 200 si route baseline, sinon NOT_IN_BASELINE | 404 / 23120 bytes | NOT_IN_BASELINE |
| /faq | 200 si route baseline, sinon NOT_IN_BASELINE | 404 / 23120 bytes | NOT_IN_BASELINE |
| /blog | 200 si route baseline, sinon NOT_IN_BASELINE | 404 / 23120 bytes | NOT_IN_BASELINE |

## Cache / CDN / public truth

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| K8s runtime | tag/digest cible | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod ; sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | PASS |
| Public www.keybuzz.pro | markers PH-21.72/21.75 presents | kb2=3 ; kb2-hero=3 | PASS |
| Headers cache | documentes | see below | INFO |

```text
date: Thu, 18 Jun 2026 13:23:49 GMT
cache-control: s-maxage=31536000
etag: "z0se8o2k2l1sr6"
```

## Homepage hero visual parity structural audit

| Marker | Attendu | Observe | Verdict |
|---|---|---:|---|
| kb2 | present | 3 | PASS |
| kb2-hero | present | 3 | PASS |
| grid-overlay | present/equivalent | 3 | INFO |
| WaveCanvas | present or INFO if tree-shake/minified | 0 | INFO |
| Reprenez le contr | present | 2 | PASS |
| marges | present | 2 | PASS |
| Vous validez | present | 6 | PASS |
| automatisez seulement | present | 2 | PASS |

## Body PROD / feature parity

| Marker | Attendu | Observe | Verdict |
|---|---|---:|---|
| Ce que KeyBuzz change | present | 2 | PASS |
| Si vous vendez sur marketplace | present | 2 | PASS |
| SP-API | present | 8 | PASS |
| Questions frequentes | present | 7 | PASS |
| benefices / reassurance | present if known | 0 | INFO |
| CTA final / Voir les plans | present if known | 0 | INFO |

## Tracking PROD passive audit

| Marker | Attendu | Observe | Verdict |
|---|---|---:|---|
| client.keybuzz.io | present | 21 | PASS |
| api.keybuzz.io/api/public/contact | present | 1 | PASS |
| t.keybuzz.pro | present | 19 | PASS |
| wrff07upjx | present | 1 | PASS |
| G-R3QQDYEBFG | present | 19 | PASS |
| 1234164602194748 | present | 1 | PASS |
| D7PT12JC77U44OJIPC10 | present | 1 | PASS |
| 9969977 | present | 19 | PASS |

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
| raw sk_live marker | absent | 0 | PASS |
| raw xoxb marker | absent | 0 | PASS |
| raw ghp marker | absent | 0 | PASS |
| Lead | absent or reviewed non-blocking | 1 (REVIEWED_NON_BLOCKING) | PASS |

## Non-regression services/runtime

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Website PROD | v0.7.2 cible live | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod ; ready 2/2 ; gen 38/38 | PASS |
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

## No fake metrics / no fake events

| Interdit | Resultat |
|---|---|
| StartTrial | aucun event declenche |
| Purchase | aucun event declenche |
| CompletePayment | aucun event declenche |
| InitiateCheckout | aucun event declenche |
| Lead | aucun event declenche ; marker statique classe REVIEWED_NON_BLOCKING |
| CAPI / GA4 / Meta / TikTok / LinkedIn | aucun appel volontaire ; aucun navigateur JS |
| Formulaire | aucun |
| Checkout | aucun |
| Webflow | aucune mutation |

## Limites

- Pas de verification navigateur visuelle pour eviter tout risque de faux event tracking.
- Verification visuelle finale possible par Ludovic dans un vrai navigateur.
- Les routes hors baseline PH-21.69/21.70 sont classees NOT_IN_BASELINE si absentes, sans bloquer.

## Dettes restantes

1. Verification visuelle utilisateur finale possible par Ludovic dans un vrai navigateur.
2. Dettes Website connues : lint global et npm audit dependencies.
3. Webflow try.keybuzz.io et attribution Meta reelle restent sujets separes.
4. Client GA4 parity reste dette separee.
5. Backfill-scheduler reste dette SRE separee.
6. PreviewBanner guard reste dette non bloquante documentee.
7. Close read-only separe PH-21.77 requis.

## Verdict

READY_WITH_DEBTS.

Prochain GO exact :

```
GO READONLY CLOSE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.77
```
