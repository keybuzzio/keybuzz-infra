# PH-SAAS-T8.12AS.21.69 - READONLY VERIFY WEBSITE PROD HERO COPY AND BODY PARITY

## 1. Resume executif

Verdict : READY_WITH_DEBTS.

Verification READONLY PROD post PH-21.68 terminee sans mutation runtime. Website PROD sert le tag cible, le digest GHCR attendu, le contenu hero/body parity, les URLs/IDs tracking PROD et les routes publiques critiques. Aucun build, docker push, deploy, kubectl apply, restart, fake event, formulaire, checkout, Webflow ou Linear n'a ete execute.

Prochain GO recommande : `GO READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.70`.

## 2. Sources relues

| Source | Statut |
| --- | --- |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Lu |
| Modele PH-T8.10J local | Lu cote Codex avant execution |
| Retours locaux PH-21.65_PUSH / PH-21.66 / PH-21.67 / PH-21.68 | Lus cote Codex avant execution |
| Rapports remote PH-21.65 / PH-21.66 / PH-21.67 / PH-21.68 | Lus |
| WEBSITE-AGENT-CONTEXT.md | Lu, exemples imperatifs obsoletes ignores |
| keybuzz-website/docs/BUILD-ARGS.md | Lu |
| Rapports PH-21.01 / PH-21.55 / PH-21.56 | Optionnels lus si presents |

## 3. Preflight

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Bastion | install-v3 | install-v3 | PASS |
| IP | 46.62.171.61 | presente dans `hostname -I` | PASS |
| IP interdite | non utilisee | 51.159.99.247 absente | PASS |
| Date UTC | actuelle | 2026-06-17T20:12:50Z | PASS |
| Kube context | lecture seule | kubernetes-admin@kubernetes | PASS |
| Infra branch | main | main | PASS |
| Infra HEAD | origin/main | f8fb7aabfbaa0ad0110dc9ee23dd99b6209604a6 | PASS |
| Infra ahead/behind | 0/0 | 0/0 | PASS |
| Infra dirty | 0 | 0 | PASS |
| Deploy commit present | f4daa43fe4e65e3271878728da8f6a1e0edc6b0a | present | PASS |
| Report PH-21.68 present | f8fb7aabfbaa0ad0110dc9ee23dd99b6209604a6 | present | PASS |
| GHCR tag target | present | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | PASS |
| GHCR digest target | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | PASS |
| latest baseline | unchanged expected | descriptor sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8 / raw sha c7421b789865f2f8768178c9ffa6588c249b430ceeee4352cb35322688e1a439 | PASS |

## 4. Runtime equality

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Manifest file | tag cible | count 1 | PASS |
| Last-applied | tag cible | 1 | PASS |
| Deployment spec | tag cible | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | PASS |
| Pod spec | tag cible | target on ready pods | PASS |
| Pod imageID | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | all ready pods match | PASS |
| Ready | 2/2 | 2/2 | PASS |
| Updated / available | 2 / 2 | 2 / 2 | PASS |
| Restarts | 0 | 0 | PASS |
| Old digest ready pods | 0 | 0 | PASS |
| Generation | observed = desired | 37 = 37 | PASS |

Pods :

```text
keybuzz-website-54c5f4f658-2gvqd|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
keybuzz-website-54c5f4f658-pvfqb|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
```

## 5. Routes publiques

GET passif uniquement, sans navigateur, sans JS volontaire, sans clic, sans formulaire.

| Route | Status | Bytes | Error marker | Verdict |
| --- | ---: | ---: | ---: | --- |
| `/` | 200 | 72766 | 0 | PASS |
| `/pricing` | 200 | 71713 | 0 | PASS |
| `/contact` | 200 | 28362 | 0 | PASS |
| `/privacy` | 200 | 57150 | 0 | PASS |
| `/terms` | 200 | 60145 | 0 | PASS |
| `/features` | 200 | 64451 | 0 | PASS |
| `/amazon` | 200 | 47075 | 0 | PASS |
| `/integrations/google-ads` | 200 | 47853 | 0 | PASS |
| `/cookies` | 200 | 46103 | 0 | PASS |
| `/legal` | 200 | 38859 | 0 | PASS |
| `/about` | 200 | 45701 | 0 | PASS |
| `/amazon/security` | 200 | 48879 | 0 | PASS |
| `/amazon/data-usage` | 200 | 45977 | 0 | PASS |

## 6. Homepage / pricing / contact

| Brique | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Hero | present | Reprenez le contr=2, marges=2, Vous validez=6, automatisez seulement=2 | PASS |
| Body parity | present | Ce que KeyBuzz change=2, Si vous vendez sur marketplace=2, Marketplaces=24, Questions=14 | PASS |
| Pricing obsolete | absent | 49 EUR=0, 199 EUR=0, 49e/mois=0, 199e/mois=0 | PASS |
| KPI non prouve | absent | -84=0 | PASS |
| CTA/forwarding | preserve | utm/gclid/fbclid/ttclid/li_fat_id/_gl/promo/marketing_owner_tenant_id presents | PASS |
| Direct Stripe link | absent | checkout.stripe.com=0 | PASS |
| Contact PROD | present | api.keybuzz.io/api/public/contact=1 | PASS |
| Contact DEV | absent | api-dev.keybuzz.io=0 | PASS |

Chunks statiques recuperes passivement : 28.

## 7. Tracking / Clarity passive audit

| Marker / event | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| t.keybuzz.pro | present | 14 | PASS |
| wrff07upjx | present | 1 | PASS |
| G-R3QQDYEBFG | present | 14 | PASS |
| 1234164602194748 | present | 1 | PASS |
| D7PT12JC77U44OJIPC10 | present | 1 | PASS |
| 9969977 | present | 14 | PASS |
| client-dev.keybuzz.io | absent | 0 | PASS |
| api-dev.keybuzz.io | absent | 0 | PASS |
| preview.keybuzz.pro | absent sauf garde non navigante | count=1, guard=1, link=0 | PASS_WITH_DEBT |
| StartTrial direct trigger | absent | marker=0 direct=0 | PASS |
| Purchase direct trigger | absent | marker=0 direct=0 | PASS |
| CompletePayment direct trigger | absent | marker=0 direct=0 | PASS |
| InitiateCheckout direct trigger | absent | marker=0 direct=0 | PASS |
| Lead direct trigger | absent/non-blocking text only | word=2 direct=0 | PASS |

Rappel : PH-21.55 et PH-21.56 distinguent StartTrial CAPI reel, signup_complete GA4/Google, trial/billing produit, et confirment qu'un arret Stripe sans paiement finalise doit rester EXPECTED_ABSENT_STARTTRIAL.

## 8. No fake metrics / no fake events

| Interdit | Resultat |
| --- | --- |
| Browser event volontaire | 0 |
| Server-side event volontaire | 0 |
| StartTrial/Purchase fake | 0 |
| CompletePayment/Lead/InitiateCheckout fake | 0 |
| Form submit | 0 |
| Checkout Stripe | 0 |
| CTA register/checkout click | 0 |
| Test endpoint CAPI/GA/Meta/TikTok/LinkedIn | 0 |

## 9. Non-regression autres services

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Website DEV | tag/digest DEV inchanges | tag count=2 digest count=1 | PASS |
| Website PROD restarts | stable | 0 | PASS |
| API | aucune action PH-21.69, runtime lu seulement | voir snapshot ci-dessous | PASS |
| Client | aucune action PH-21.69, runtime lu seulement | voir snapshot ci-dessous | PASS |
| Backend | aucune action PH-21.69, runtime lu seulement | voir snapshot ci-dessous | PASS |
| Admin | aucune action PH-21.69, runtime lu seulement | voir snapshot ci-dessous | PASS |
| latest | unchanged | descriptor sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8 / raw sha c7421b789865f2f8768178c9ffa6588c249b430ceeee4352cb35322688e1a439 | PASS |
| Other manifests | unchanged depuis deploy PH-21.68 | k8s diff count=0 | PASS |

Snapshot deployments KeyBuzz lu en read-only :

```text
keybuzz-admin-v2-dev	keybuzz-admin-v2	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev
keybuzz-admin-v2-prod	keybuzz-admin-v2	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod
keybuzz-ai	litellm	2/2	updated=2	available=2	ghcr.io/berriai/litellm:main-v1.81.14-stable
keybuzz-api-dev	keybuzz-api	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev
keybuzz-api-dev	keybuzz-outbound-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev
keybuzz-api-prod	keybuzz-api	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod
keybuzz-api-prod	keybuzz-outbound-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod
keybuzz-backend-dev	amazon-items-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-dev
keybuzz-backend-dev	amazon-orders-worker	2/2	updated=2	available=2	ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-dev
keybuzz-backend-dev	backfill-scheduler	0/1	updated=1	available=0	ghcr.io/keybuzzio/keybuzz-backend:v1.0.42-td02-worker-resilience-dev
keybuzz-backend-dev	jobs-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev
keybuzz-backend-dev	keybuzz-backend	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev
keybuzz-backend-prod	amazon-items-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-prod
keybuzz-backend-prod	amazon-orders-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-prod
keybuzz-backend-prod	backfill-scheduler	0/1	updated=1	available=0	ghcr.io/keybuzzio/keybuzz-backend:v1.0.42-td02-worker-resilience-prod
keybuzz-backend-prod	jobs-worker	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod
keybuzz-backend-prod	keybuzz-backend	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod
keybuzz-client-dev	keybuzz-client	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev
keybuzz-client-prod	keybuzz-client	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod
keybuzz-seller-dev	seller-api	1/1	updated=1	available=1	ghcr.io/keybuzzio/seller-api:v2.0.5-ph-prod-ftp-02
keybuzz-seller-dev	seller-client	1/1	updated=1	available=1	ghcr.io/keybuzzio/seller-client:v2.0.7-ph-prod-ftp-02b
keybuzz-studio-api-dev	keybuzz-studio-api	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-dev
keybuzz-studio-api-prod	keybuzz-studio-api	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-prod
keybuzz-studio-dev	keybuzz-studio	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-studio:v0.8.0-dev
keybuzz-studio-prod	keybuzz-studio	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-studio:v0.8.0-prod
keybuzz-website-dev	keybuzz-website	1/1	updated=1	available=1	ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev
keybuzz-website-prod	keybuzz-website	2/2	updated=2	available=2	ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod
```

## 10. Dettes et risques

Dettes non bloquantes deja documentees :

- lint global Website FAIL_PREEXISTING.
- npm audit Website signale des vulnerabilites deja connues.
- Webflow try.keybuzz.io owner forwarding separe.
- Client GA4 runtime parity separee.
- dette SRE backfill-scheduler separee.
- `preview.keybuzz.pro` est present une fois dans le bundle en garde `PreviewBanner` basee sur `window.location.hostname.includes(...)`, sans lien, src, action, endpoint ou navigation vers preview.

## 11. Prochain GO

`GO READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.70`

## 12. Verdict

GO READONLY VERIFY WEBSITE PROD HERO COPY AND BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.69

STOP.
