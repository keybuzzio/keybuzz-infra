# PH-SAAS-T8.12AS.21.83 - Readonly verify API onboarding trial_page_viewed Meta tracking DEV

## Resume

- Verdict: READY_WITH_LIMITS.
- API DEV image attendue: ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev.
- Digest runtime attendu: sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669.
- Mode: READONLY VERIFY DEV, aucun event reel/fake, aucun formulaire, aucun checkout, aucun build, aucun deploy.
- Limite: aucun trial_page_viewed naturel observe pendant la fenetre, donc preuve Ads Manager/CAPI reelle non produite.

## Sources relues

| Source | Statut |
| --- | --- |
| PH-21.83 mission locale | relue |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | relues |
| Modele PH-T8.10J | relu |
| PH-21.78 a PH-21.82 retours locaux | relus |

## Preflight

| Controle | Resultat | Verdict |
| --- | --- | --- |
| Host | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | PASS |
| Date UTC | 2026-06-22T07:55:33Z | PASS |
| Kube context | kubernetes-admin@kubernetes | PASS |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b | 35673e3b | 0 0 | 223 | OK |
| keybuzz-infra | main | cc783bdf | cc783bdf | 0 0 | 0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a | ad4e862a | 0 0 | 1 | OK |
| keybuzz-website | main | bd32fc8b | bd32fc8b | 0 0 | 0 | OK |
| keybuzz-admin-v2 | main | 3707c834 | 3707c834 | 0 0 | 0 | OK |
| keybuzz-backend | main | c38583a8 | c38583a8 | 0 0 | 1 | OK |

## Runtime API DEV

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Manifest Git image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | PASS |
| Last-applied image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | PASS |
| Deployment spec image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | PASS |
| Pod spec image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | PASS |
| Pod imageID digest | sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | PASS |
| Ready | 1/1 | 1/1 | PASS |
| Restarts | 0 stable | 0 | PASS |
| Health | OK | {"status":"ok","timestamp":"2026-06-22T07:55:34.012Z","service":"keybuzz-api","version":"1.0.0"} | PASS |

Pod actif: keybuzz-api-79cf988674-b4cfj.

## Marker audit in-pod

| Marker | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| trial_page_viewed | present | 7 | PASS |
| Helper PH-21.79 | present | 3 | PASS |
| Meta custom mapping | present | 3 | PASS |
| StartTrial | present | 9 | PASS |
| Purchase | present | 31 | PASS |
| /app/dist/tests | absent | 0 | PASS |
| Test PH-21.79 | absent | 0 | PASS |
| Secret/token brut obvious | absent | 0 | PASS |
| Owner env runtime | absent | false | PASS |
| Hardcode tenant owner dist | absent | 0 | PASS |
| Skip safe markers | present/documented | 119 | PASS |

## Config owner / skip safe

| Point | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Env TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID manifest | absent ou documentee | count=0 | PASS |
| Hardcode tenant owner manifest | absent | count=0 | PASS |
| Owner env runtime | absent | voir table markers | PASS/DEBT connue |
| Skip safe owner absent | present/documente | voir table markers | PASS |

Dette non bloquante conservee: TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID n'est pas configure en DEV; le helper doit rester skip-safe si owner absent.

## Logs API DEV read-only

| Pattern | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Crash/fatal | 0 | 0 | PASS |
| Restarts | stable | 0 | PASS |
| trial_page_viewed naturel | 0 ou naturel documente | 0 | TRAFFIC_REQUIRED |
| CAPI send inattendu | 0 | 0 | PASS |
| Token brut | 0 | 0 | PASS |
| Erreur Meta non masquee | 0 | 0 | PASS |

## DB snapshots read-only

Snapshots effectues via transaction BEGIN TRANSACTION READ ONLY puis ROLLBACK. Aucune valeur de secret affichee.

| Table | Signal | Count avant | Count apres | Delta | Verdict |
| --- | --- | ---: | ---: | ---: | --- |
| funnel_events | total | 113 | 113 | 0 | PASS |
| funnel_events | trial_page_viewed | 0 | 0 | 0 | PASS |
| funnel_events | register_started_24h | 0 | 0 | 0 | PASS |
| conversion_events | total | 0 | 0 | 0 | PASS |
| conversion_events | trial_page_viewed | 0 | 0 | 0 | PASS |
| outbound_conversion_delivery_logs | total | 7 | 7 | 0 | PASS |
| outbound_conversion_delivery_logs | trial_page_viewed | 0 | 0 | 0 | PASS |

## Non-regression services

| Surface | Observe | Ready | Generation | Verdict |
| --- | --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | 1/1 | 503/503 | OBSERVED |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | 1/1 | 423/423 | OBSERVED |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | 1/1 | 1024/1024 | OBSERVED |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | 1/1 | 427/427 | OBSERVED |
| Website DEV | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | 1/1 | 69/69 | OBSERVED |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | 2/2 | 38/38 | OBSERVED |
| Admin DEV | NOT_FOUND | NA | NA | OBSERVED |
| Admin PROD | NOT_FOUND | NA | NA | OBSERVED |
| Backend DEV | ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev | 1/1 | 214/214 | OBSERVED |
| Backend PROD | ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod | 1/1 | 34/34 | OBSERVED |
| GHCR latest API | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | NA | PASS |

## Tracking contract verification

| Contrat | Attendu | Resultat |
| --- | --- | --- |
| trial_page_viewed | custom Meta CAPI high-funnel | present en runtime, pas observe naturellement |
| Source | premier register_started insere par /funnel/event | confirme par marqueurs source/runtime; aucun POST execute |
| Duplicate | pas d'emission si already_recorded | couvert par patch PH-21.79, non re-teste par event reel |
| Business conversion | pas de row conversion_events | count trial_page_viewed = 0 |
| StartTrial | reste Stripe trial/subscription valide | marker present, pas modifie |
| Purchase | reste paiement/subscription business | marker present, pas modifie |
| Owner routing | properties/env si present, skip safe sinon | env owner absente, dette connue |
| Snippet browser Antoine | non retenu comme mecanisme principal | conserve comme decision PH-21.78 |

## Gaps et limites

| Gap | Impact | Action recommandee |
| --- | --- | --- |
| NO_NATURAL_TRAFFIC trial_page_viewed | CAPI/Ads Manager non prouves par trafic reel | phase de vrai trafic separee si Ludovic l'autorise |
| TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID absent | emission skip-safe si properties owner absentes | phase config dediee si decision produit |
| Ads Manager Antoine | hors preuve read-only | verifier seulement avec trafic reel |

## No fake metrics / no fake events

| Interdit | Resultat |
| --- | --- |
| POST /funnel/event | non execute |
| Formulaire /register | non execute |
| Checkout Stripe | non execute |
| Endpoint CAPI test | non appele |
| Build / docker push / deploy | non execute |
| DB mutation | non executee |
| Linear | non touche |

## Rapport et commit docs

- Rapport: /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.83-READONLY-VERIFY-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md.
- Retour local attendu: C:\DEV\KeyBuzz\tmp\PH-21.83_CE_RETURN.md.

## Verdict final

GO READONLY VERIFY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV READY_WITH_LIMITS PH-SAAS-T8.12AS.21.83

Prochain GO recommande: GO READONLY CLOSE API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.84

STOP
