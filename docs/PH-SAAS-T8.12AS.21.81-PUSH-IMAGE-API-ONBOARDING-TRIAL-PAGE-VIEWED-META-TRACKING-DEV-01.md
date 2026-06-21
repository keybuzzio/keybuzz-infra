# PH-SAAS-T8.12AS.21.81 - PUSH IMAGE API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV

## RESUME LUDOVIC - TERMINAL

Verdict: DONE - PUSH IMAGE API DEV DONE PH-SAAS-T8.12AS.21.81

Image poussee: `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev`.

Manifest digest GHCR: `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`.

Pull-back OK: RepoDigest `ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`, Image ID `sha256:f98799240b29e0da0535acdc55849519c4b31b63bfe4ef355d7061541056d541`.

Labels OCI OK: revision `35673e3b16f4843d6144c24a0ad9926e28525ed4`, version `v3.5.264-onboarding-trial-page-viewed-meta-dev`.

`latest` inchange: hash `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549`.

Aucun rebuild, aucun deploy/kubectl apply, aucune DB mutation, aucun event reel/fake.

Prochain GO recommande: GO APPLY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV GITOPS PH-SAAS-T8.12AS.21.82

STOP

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.81_CE_MISSION.md` | Lu |
| `AI_MEMORY/CURRENT_STATE.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu |
| `AI_MEMORY/DOCUMENT_MAP.md` | Lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.80_CE_RETURN.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.79_CE_RETURN.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.79_PUSH_CE_RETURN.md` | Lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.80-BUILD-API-ONBOARDING-TRIAL-PAGE-VIEWED-META-TRACKING-DEV-01.md` | Relu via PH-21.80 return et remote docs context |

## Preflight

Bastion: `install-v3`.

IP publique: `46.62.171.61`.

Kube context read-only: `kubernetes-admin@kubernetes`.

Timestamp preflight: `2026-06-21T21:55:17Z`.

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | `ph147.4/source-of-truth` | `35673e3b` | `35673e3b` | `0 0` | 223 | OK, dirty dist preexistant |
| keybuzz-infra | `main` | `b7ba11d7` | `b7ba11d7` | `0 0` | 0 | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ad4e862a` | `ad4e862a` | `0 0` | 1 | Read-only |
| keybuzz-website | `main` | `bd32fc8b` | `bd32fc8b` | `0 0` | 0 | Read-only |
| keybuzz-admin-v2 | `main` | `3707c834` | `3707c834` | `0 0` | 0 | Read-only |

API source_status PH-21.79: `0`.

API dist dirty preexistant: `223`.

| Service | Env | Image | Ready | Restarts | Verdict |
| --- | --- | --- | --- | ---: | --- |
| API | DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev` | 1/1 | 0 | Inchange avant push |
| API | PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` | 1/1 | 0 | Inchange avant push |
| Client | DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev` | 1/1 | 0 | Inchange avant push |
| Client | PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod` | 1/1 | 0 | Inchange avant push |
| Website | DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | 1/1 | 0 | Inchange avant push |
| Website | PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod` | 2/2 | 0 | Inchange avant push |
| Admin | DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev` | 1/1 | 0 | Inchange avant push |
| Admin | PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod` | 1/1 | 0 | Inchange avant push |

## Image locale precheck

| Controle local image | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Tag local | present | present | PASS |
| Image ID | `sha256:f98799240b29e0da0535acdc55849519c4b31b63bfe4ef355d7061541056d541` | `sha256:f98799240b29e0da0535acdc55849519c4b31b63bfe4ef355d7061541056d541` | PASS |
| Created | documente | `2026-06-21T21:35:14.727091618Z` | PASS |
| OCI revision | `35673e3b16f4843d6144c24a0ad9926e28525ed4` | `35673e3b16f4843d6144c24a0ad9926e28525ed4` | PASS |
| OCI version | `v3.5.264-onboarding-trial-page-viewed-meta-dev` | `v3.5.264-onboarding-trial-page-viewed-meta-dev` | PASS |
| OCI source | GitHub API repo | `https://github.com/keybuzzio/keybuzz-api` | PASS |
| `trial_page_viewed` | present | count 7 | PASS |
| Helper PH-21.79 | present | count 3 | PASS |
| `StartTrial` | present | count 9 | PASS |
| `Purchase` | present | count 31 | PASS |
| `/app/dist/tests` | absent | absent, 0 fichier | PASS |
| Test PH-21.79 | absent | 0 fichier | PASS |

Marker files:

- `modules/outbound-conversions/adapters/meta-capi.js`
- `modules/outbound-conversions/emitter.js`
- `modules/funnel/routes.js`

Note: un premier affichage de labels a ete mal echappe dans le script de precheck, mais les controles bloquants Image ID/labels ont ete refaits proprement avant push.

## Registry precheck

| Image | Etat registry avant | Decision |
| --- | --- | --- |
| `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev` | absent, `manifest unknown` | GO push |
| `ghcr.io/keybuzzio/keybuzz-api:latest` | hash `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | Capturer pour comparaison post-push |

## Push image

Action executee:

`docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev`

Aucun autre `docker push` execute.

| Image | Action | Manifest digest | Resultat |
| --- | --- | --- | --- |
| `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev` | `docker push` tag cible seul | `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | PASS |

Push UTC: `2026-06-21T21:58:04Z`.

## Pull-back verification

Pour forcer le pull-back depuis GHCR, seul le tag local cible a ete retire:

`docker image rm ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev`

La commande a supprime le tag local cible et les layers locaux devenus non references, puis `docker pull` a repulle l'image depuis GHCR. Aucun tag `latest`, PROD ou autre image applicative n'a ete retire.

| Controle pull-back | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Pull tag cible | OK | OK | PASS |
| Digest pull | digest push | `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | PASS |
| RepoDigest | contient digest push | `ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | PASS |
| Image ID/config digest | `sha256:f98799240b29e0da0535acdc55849519c4b31b63bfe4ef355d7061541056d541` | `sha256:f98799240b29e0da0535acdc55849519c4b31b63bfe4ef355d7061541056d541` | PASS |
| OCI revision | `35673e3b16f4843d6144c24a0ad9926e28525ed4` | `35673e3b16f4843d6144c24a0ad9926e28525ed4` | PASS |
| OCI version | `v3.5.264-onboarding-trial-page-viewed-meta-dev` | `v3.5.264-onboarding-trial-page-viewed-meta-dev` | PASS |
| `trial_page_viewed` | present | count 7 | PASS |
| Helper PH-21.79 | present | count 3 | PASS |
| `StartTrial` | present | count 9 | PASS |
| `Purchase` | present | count 31 | PASS |
| `/app/dist/tests` | absent | 0 fichier | PASS |
| Test PH-21.79 | absent | 0 fichier | PASS |

## Registry postcheck

| Controle registry | Avant | Apres | Verdict |
| --- | --- | --- | --- |
| Tag cible | absent | present | PASS |
| Manifest digest cible | absent | `sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669` | PASS |
| Target manifest JSON hash | n/a | `6461fb9a54307be342819e57f9fe73d62b29a297192ed4cb48fb82901e6327a3` | INFO |
| `latest` hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | PASS |
| PROD tag | hors scope | non touche | PASS |

Note: une premiere comparaison `latest` a retourne un faux `NO_GO_LATEST_CHANGED` car le fichier contenait le prefixe `latest_hash_before=`. La comparaison corrigee prouve `latest` inchange.

## Runtime non-regression read-only

| Surface | Avant | Apres | Delta | Verdict |
| --- | --- | --- | --- | --- |
| API DEV deployment | `v3.5.263-llm-provider-credit-watcher-dev`, ready 1/1 | meme image, ready 1/1 | 0 | PASS |
| API DEV pod | digest `sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996`, restarts 0 | meme digest, restarts 0 | 0 | PASS |
| API PROD deployment | `v3.5.262-llm-provider-credit-alerting-prod`, ready 1/1 | meme image, ready 1/1 | 0 | PASS |
| API PROD pod | digest `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6`, restarts 0 | meme digest, restarts 0 | 0 | PASS |
| Client DEV | `v3.5.259-ai-assist-notification-scope-dev` | inchange | 0 | PASS |
| Client PROD | `v3.5.259-ai-assist-notification-scope-prod` | inchange | 0 | PASS |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | inchange | 0 | PASS |
| Website PROD | `v0.7.2-visual-hero-parity-prod` | inchange | 0 | PASS |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | inchange | 0 | PASS |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | inchange | 0 | PASS |
| Manifest GitOps | aucun changement | aucun changement | 0 | PASS |
| DB / app events | aucun appel applicatif CE | aucun appel applicatif CE | 0 CE action | PASS |

Les jobs Cron naturels visibles pendant la fenetre sont independants du push image. Aucun trigger manuel n'a ete execute.

## No fake metrics / no fake events

| Surface | Resultat |
| --- | --- |
| Event Meta reel | Non execute |
| Event TikTok reel | Non execute |
| Event LinkedIn reel | Non execute |
| Event GA4/sGTM reel | Non execute |
| Endpoint test CAPI | Non appele |
| Formulaire `/register` | Non soumis |
| Checkout Stripe | Non execute |
| DB mutation | Non executee |
| `conversion_events` | Non touche par CE |
| `funnel_events` | Non touche par CE |
| `outbound_conversion_delivery_logs` | Non touche par CE |

## Interdits respectes

| Interdit | Resultat |
| --- | --- |
| Docker build / rebuild | Non execute |
| Retag `latest` | Non execute |
| Push `latest` | Non execute |
| Push autre tag | Non execute |
| Deploy / kubectl apply | Non execute |
| `kubectl set image/env`, patch, edit | Non execute |
| DB mutation | Non executee |
| Event reel/fake | Non execute |
| Formulaire / checkout | Non execute |
| Webflow / Linear | Non touche |
| Secret/token brut | Non affiche |
| PROD mutation | Non |

## Rollback futur documentaire

Rollback futur DEV a documenter/appliquer uniquement dans une phase GitOps explicite si necessaire:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev`

Aucun rollback execute dans PH-21.81.

## Dettes et prochain GO

| Dette | Priorite | Prochain GO |
| --- | --- | --- |
| Image DEV poussee mais non deployee | Normal, hors scope PH-21.81 | `GO APPLY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV GITOPS PH-SAAS-T8.12AS.21.82` |
| Observation runtime de `trial_page_viewed` | Apres deploy DEV et trafic/control flow approuve | Phase verify separee |
| Alerte parsing script `latest_hash_before=` | Mineure, corrigee dans postcheck | Aucune action runtime |

## Verdict final

GO PUSH IMAGE API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV DONE PH-SAAS-T8.12AS.21.81

STOP
