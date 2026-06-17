# PH-SAAS-T8.12AS.21.70 - READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY

## 1. Resume executif

Verdict : READY_WITH_DEBTS.

La chaine Website PROD hero copy and body parity est closee en lecture seule. La promotion demarree par le design PH-21.64 et terminee par le verify PH-21.69 est complete : source, build, image GHCR, GitOps, runtime et routes publiques sont coherents. Cette phase n'a execute aucun build, docker push, deploy, kubectl apply, restart, patch source/manifest, event tracking, formulaire, checkout, Webflow ou Linear.

Phrase finale : `GO READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.70`.

Fichier retour CE : `C:\DEV\KeyBuzz\tmp\PH-21.70_CE_RETURN.md`.

## 2. Sources relues

| Source | Statut |
| --- | --- |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Lu |
| Modele PH-T8.10J local | Lu cote Codex avant execution |
| Retours locaux PH-21.64 / PH-21.65 / PH-21.65_PUSH / PH-21.66 / PH-21.67 / PH-21.68 / PH-21.69 | Lus cote Codex avant execution |
| Rapports infra PH-21.64 a PH-21.69 | Lus |
| WEBSITE-AGENT-CONTEXT.md | Lu, exemples imperatifs obsoletes ignores |
| keybuzz-website/docs/BUILD-ARGS.md | Lu |
| Rapports PH-21.01 / PH-21.55 / PH-21.56 | Lus si presents |

## 3. Preflight

| Repo / controle | Branche | HEAD | Origin | Ahead-behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Bastion | install-v3 | IP 46.62.171.61 presente | IP 51.159.99.247 absente | date 2026-06-17T21:10:39Z | kube kubernetes-admin@kubernetes | PASS |
| keybuzz-infra | main | 80a516755f4491cb7590e446e8d57921c32be167 | 80a516755f4491cb7590e446e8d57921c32be167 | 0/0 | 0 | PASS |
| keybuzz-website | main | 4a12cfc801eda3d095bc43a984abc87522d6e41b | 4a12cfc801eda3d095bc43a984abc87522d6e41b | 0/0 | 0 | PASS |
| Source Website commit | main | 4a12cfc801eda3d095bc43a984abc87522d6e41b | present | 0/0 | 0 | PASS |
| Deploy commit PH-21.68 | infra | f4daa43fe4e65e3271878728da8f6a1e0edc6b0a | present | n/a | n/a | PASS |
| Verify commit PH-21.69 | infra | 80a516755f4491cb7590e446e8d57921c32be167 | present | n/a | n/a | PASS |

## 4. Consolidation PH-21.64 a PH-21.69

| Phase | Objet | Reference | Verdict |
| --- | --- | --- | --- |
| PH-21.64 | Design PROD promotion | rapport 4dba4cc | READY_SOURCE_PATCH_REQUIRED |
| PH-21.65 | Source patch PROD | Website 4a12cfc801eda3d095bc43a984abc87522d6e41b, infra 0975b94 | READY_WITH_DEBTS |
| PH-21.65 PUSH | Push source | origin/main 4a12cfc801eda3d095bc43a984abc87522d6e41b | DONE |
| PH-21.66 | Build PROD | Image ID sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 | READY_WITH_DEBTS |
| PH-21.67 | Push image PROD | digest sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | DONE |
| PH-21.68 | Apply GitOps PROD | deploy f4daa43fe4e65e3271878728da8f6a1e0edc6b0a | READY_WITH_DEBTS |
| PH-21.69 | Verify PROD | report 80a516755f4491cb7590e446e8d57921c32be167 | READY_WITH_DEBTS |

Conclusion chaine : COMPLETE. Aucun maillon essentiel absent ou contradictoire.

## 5. Runtime final Website PROD

| Runtime surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| GHCR manifest digest | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | PASS |
| GHCR config digest | sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 | sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 | PASS |
| Manifest file | tag cible une fois | count 1 | PASS |
| Last-applied | tag cible | 1 | PASS |
| Deployment spec | tag cible | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | PASS |
| Pod imageID | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b | tous pods ready match | PASS |
| Ready | 2/2 | 2/2 | PASS |
| Restarts | 0 | 0 | PASS |
| Generation | observed = desired | 37 = 37 | PASS |
| Ancien digest ready | 0 | 0 | PASS |

Pods :

```text
keybuzz-website-54c5f4f658-2gvqd|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
keybuzz-website-54c5f4f658-pvfqb|Running|True|0|ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|ghcr.io/keybuzzio/keybuzz-website@sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b
```

## 6. Routes et feature parity Website PROD

GET passif uniquement, sans navigateur interactif, sans clic, sans formulaire.

| Route | Status | Bytes | Verdict |
| --- | ---: | ---: | --- |
| `/` | 200 | 72766 | PASS |
| `/pricing` | 200 | 71713 | PASS |
| `/contact` | 200 | 28362 | PASS |
| `/privacy` | 200 | 57150 | PASS |
| `/terms` | 200 | 60145 | PASS |
| `/features` | 200 | 64451 | PASS |
| `/amazon` | 200 | 47075 | PASS |
| `/integrations/google-ads` | 200 | 47853 | PASS |
| `/cookies` | 200 | 46103 | PASS |
| `/legal` | 200 | 38859 | PASS |
| `/about` | 200 | 45701 | PASS |
| `/amazon/security` | 200 | 48879 | PASS |
| `/amazon/data-usage` | 200 | 45977 | PASS |

| Feature parity | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Hero PH-21.58 | present | Reprenez le contr=2, marges=2, Vous validez=6, automatisez seulement=2 | PASS |
| Body PROD conserve | present | Ce que KeyBuzz change=2, Si vous vendez sur marketplace=2 | PASS |
| Pricing obsolete | absent | 49 EUR=0, 199 EUR=0, 49e/mois=0, 199e/mois=0 | PASS |
| KPI non prouve | absent | -84=0 | PASS |
| Contact PROD | present | api.keybuzz.io/api/public/contact=1 | PASS |
| Contact DEV | absent | api-dev.keybuzz.io=0 | PASS |

Chunks statiques recuperes passivement : 28.

## 7. Tracking / Clarity / CTA passive audit

| Tracking marker / event | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| t.keybuzz.pro | present | 14 | PASS |
| wrff07upjx | present | 1 | PASS |
| G-R3QQDYEBFG | present | 14 | PASS |
| 1234164602194748 | present | 1 | PASS |
| D7PT12JC77U44OJIPC10 | present | 1 | PASS |
| 9969977 | present | 14 | PASS |
| client.keybuzz.io | present | 44 | PASS |
| client-dev.keybuzz.io | absent | 0 | PASS |
| api-dev.keybuzz.io | absent | 0 | PASS |
| checkout.stripe.com direct | absent | 0 | PASS |
| StartTrial direct trigger | absent | marker=0 direct=0 | PASS |
| Purchase direct trigger | absent | marker=0 direct=0 | PASS |
| CompletePayment direct trigger | absent | marker=0 direct=0 | PASS |
| InitiateCheckout direct trigger | absent | marker=0 direct=0 | PASS |
| Lead direct trigger | absent/non-blocking text only | word=2 direct=0 | REVIEWED_NON_BLOCKING |
| preview.keybuzz.pro | garde PreviewBanner uniquement | count=1, guard=1, link=0 | REVIEWED_NON_BLOCKING |

Distinction tracking : les marqueurs browser publics sont presents. Aucun nouvel event server-side CAPI n'a ete emis. L'attribution Meta reelle et StartTrial reel restent a observer uniquement via vrai trafic campagne et vrai checkout/trial.

## 8. No fake metrics / no fake events

| Interdit | Resultat |
| --- | --- |
| Browser event volontaire | 0 |
| Server-side event volontaire | 0 |
| StartTrial fake | 0 |
| Purchase fake | 0 |
| CompletePayment fake | 0 |
| Lead fake | 0 |
| InitiateCheckout fake | 0 |
| Form submit | 0 |
| Checkout Stripe ouvert ou complete | 0 |
| Endpoint CAPI/test event appele | 0 |
| KPI invente ou conversion extrapolee | 0 |

## 9. Non-regression

| Non-regression surface | Etat | Verdict |
| --- | --- | --- |
| Website DEV | tag v0.7.1-hero-copy-prod-body-parity-dev, digest sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b present | PASS |
| Website PROD | tag cible, Ready 2/2, restarts 0 | PASS |
| API DEV/PROD | lu read-only uniquement, aucune action PH-21.70 | PASS |
| Client DEV/PROD | lu read-only uniquement, aucune action PH-21.70 | PASS |
| Backend DEV/PROD | lu read-only uniquement, aucune action PH-21.70 | PASS |
| Admin DEV/PROD | lu read-only uniquement, aucune action PH-21.70 | PASS |
| Website latest | descriptor sha256:adf911803a649337d2a8c5ea5d2158ffeb7c4ea4f5cf176a1d3ed10cc02c76c8 | PASS |
| Manifests hors Website PROD | k8s diff depuis PH-21.68 = 0 | PASS |

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

## 10. Dettes figees

| Dette | Impact | Phase recommandee |
| --- | --- | --- |
| Website lint global FAIL_PREEXISTING 275 problemes | Dette qualite hors patch | GO READONLY DESIGN WEBSITE LINT AND NPM AUDIT DEBT PH-SAAS-T8.12AS.21.71C |
| npm audit Website 9 vulnerabilites PH-21.66 | Dette dependances | PH-21.71C ou phase secu dediee |
| Webflow try.keybuzz.io owner forwarding/campaign URLs | LP externe separee | GO READONLY DESIGN WEBFLOW TRY KEYBUZZ OWNER FORWARDING AND CAMPAIGN URLS PH-SAAS-T8.12AS.21.71 |
| Attribution Meta reelle | Necessite vrai trafic pub et vrai checkout/trial | Observation trafic reel uniquement |
| Client GA4 runtime parity | Dette tracking separee | GO READONLY DESIGN CLIENT GA4 RUNTIME PARITY PH-SAAS-T8.12AS.21.71B |
| SRE backfill-scheduler | Service 0/1 deja observe, hors Website | Phase SRE dediee |
| preview.keybuzz.pro guard | Reference bundle non navigante PreviewBanner | Garder documente ou traiter en hygiene Website |

## 11. Rollback documente, non execute

| Rollback step | Commande GitOps / action | Statut |
| --- | --- | --- |
| 1 | Modifier `k8s/website-prod/deployment.yaml` vers `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod` | Documente seulement |
| 2 | Commit GitOps du manifest | Documente seulement |
| 3 | Push normal non-force | Documente seulement |
| 4 | `kubectl apply -f k8s/website-prod/deployment.yaml` | Documente seulement |
| 5 | `kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod` | Documente seulement |
| 6 | Verifier digest `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac` | Documente seulement |

Aucune commande rollback n'a ete executee. Aucune procedure imperative `kubectl set image`, `kubectl set env`, `kubectl patch` ou `kubectl edit` n'est documentee comme rollback.

## 12. Verdict final

GO READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.70

STOP.
