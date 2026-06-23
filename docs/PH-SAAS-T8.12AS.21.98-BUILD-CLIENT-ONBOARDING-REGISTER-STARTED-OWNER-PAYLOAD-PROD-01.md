# PH-SAAS-T8.12AS.21.98 - BUILD CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD

Date UTC: 2026-06-23T08:43:24Z
Mode: BUILD CLIENT PROD local uniquement
Verdict: READY

## Objectif

Construire localement l'image Client PROD depuis Git propre pour promouvoir plus tard le payload register_started enrichi valide en DEV.

Image cible locale:

- ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod

Source:

- repo: keybuzz-client
- branche: ph148/onboarding-activation-replay
- commit: d9631ca087f1751b2def8ad06a049ad93226ffbd
- build-from-git propre: /tmp/ph2198-client-build-20260623T084324Z

## Sources relues

- C:\DEV\KeyBuzz\tmp\PH-21.98_CE_MISSION.md
- AI_MEMORY/CURRENT_STATE.md
- AI_MEMORY/RULES_AND_RISKS.md
- AI_MEMORY/DOCUMENT_MAP.md
- AI_MEMORY/CE_PROMPTING_STANDARD.md
- PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01
- PH-21.86 / PH-21.86_PUSH / PH-21.87 / PH-21.88 / PH-21.89 / PH-21.90 / PH-21.91 / PH-21.92 / PH-21.97 returns
- Docs infra PH-21.86, PH-21.87, PH-21.88, PH-21.91, PH-21.92, PH-21.97

## Preflight bastion

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| host | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| hostname -I | sans IP interdite | 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 | PASS |
| UTC | date affichee | 2026-06-23T08:43:24Z | PASS |
| kube context | lu read-only | kubernetes-admin@kubernetes | PASS |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | https://github.com/keybuzzio/keybuzz-client.git | 0/0 | 1 dont tracked=1 | PASS, dette tsconfig connue non utilisee pour build |
| keybuzz-infra | main | 8192fb1b05d0c52ab18243db1d56c7989894e9fa | https://github.com/keybuzzio/keybuzz-infra.git | 0/0 | 0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | n/a | 0/0 | 223 | PASS read-only |

## Registry precheck

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Commit source | present dans origin/ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |
| Tag cible distant | absent | absent_rc_1 | PASS |
| latest before | note | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | PASS |
| rollback Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod / sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | documente | PASS |

## Source de build propre

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Worktree | /tmp/ph2198-* | /tmp/ph2198-client-build-20260623T084324Z | PASS |
| Commit | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |
| Status initial | clean | clean | PASS |
| Remote | keybuzz-client officiel | https://github.com/keybuzzio/keybuzz-client.git | PASS |
| Tracked dirty apres tests | 0 | 0 | PASS |

## Build args PROD explicites

Build args declares par Dockerfile: NEXT_PUBLIC_APP_ENV NEXT_PUBLIC_API_URL NEXT_PUBLIC_API_BASE_URL NEXT_PUBLIC_GA4_MEASUREMENT_ID NEXT_PUBLIC_META_PIXEL_ID NEXT_PUBLIC_SGTM_URL NEXT_PUBLIC_TIKTOK_PIXEL_ID NEXT_PUBLIC_LINKEDIN_PARTNER_ID NEXT_PUBLIC_CLARITY_PROJECT_ID GIT_COMMIT_SHA BUILD_TIME IMAGE_REVISION IMAGE_CREATED IMAGE_VERSION

| Build arg | Valeur | Secret? | Source |
| --- | --- | --- | --- |
| NEXT_PUBLIC_APP_ENV | production | non | Dockerfile guard |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io | non | Dockerfile guard + manifest PROD |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | non | Dockerfile guard |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | G-R3QQDYEBFG | non public id | manifest PROD comments |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | non public id | manifest PROD comments |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | non | manifest PROD comments |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | non public id | manifest PROD comments |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | non public id | Dockerfile/manifest comments |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | non public id | Dockerfile guard/manifest comment |
| GIT_COMMIT_SHA | d9631ca087f1751b2def8ad06a049ad93226ffbd | non | source commit |
| IMAGE_REVISION | d9631ca087f1751b2def8ad06a049ad93226ffbd | non | OCI label |
| IMAGE_CREATED | 2026-06-23T08:43:24Z | non | OCI label |
| IMAGE_VERSION | v3.5.260-onboarding-register-started-owner-payload-prod | non | OCI label |

## Tests pre-build

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| git diff --check | PASS | rc=0 | PASS |
| payload attribution | PASS | rc=0 | PASS |
| lint cible | PASS | rc=0 | PASS |
| tsc cible attribution | PASS | rc=0 | PASS |
| generate build metadata | PASS | rc=0 | PASS |
| tsc global | PASS ou dette documentee | PASS | PASS/DEBT |

## Build image locale

| Image | Source commit | Image ID | Taille | Labels OCI | Verdict |
| --- | --- | --- | --- | --- | --- |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | d9631ca087f1751b2def8ad06a049ad93226ffbd | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | 280023048 | revision=d9631ca087f1751b2def8ad06a049ad93226ffbd version=v3.5.260-onboarding-register-started-owner-payload-prod source=https://github.com/keybuzzio/keybuzz-client | PASS |

RepoDigest absent attendu: aucun docker push effectue.

## Audit bundle/image PROD

| Controle image/bundle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| register_started | present | 1 | PASS |
| marketing_owner_tenant_id | present | 3 | PASS |
| UTM | present | source=1 medium=1 campaign=1 content=1 term=1 | PASS |
| click IDs | present | fbclid=1 ttclid=1 gclid=1 li_fat_id=1 | PASS |
| API PROD | present | 87 | PASS |
| API DEV | absent | 0 | PASS |
| fake CompletePayment browser marker | absent | 0 | PASS |
| StartTrial/Purchase markers | pas de fake cree, audit statique | StartTrial=0 Purchase=7 InitiateCheckout=2 | PASS |
| secret-like raw markers publics | absent | public_private_key=0 public_bearer=0 internal_token_assignment=0 | PASS |

STOP bundle non declenche: API PROD presente et API DEV absente.

## Registry postcheck

| Controle registry | Avant | Apres | Verdict |
| --- | --- | --- | --- |
| Tag cible distant | absent_rc_1 | absent_rc_1 | PASS |
| latest | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | PASS |
| Docker push | interdit | non execute | PASS |

## Runtime read-only non-regression

| Service | Env | Image attendue | Observe | Pod summary | Verdict |
| --- | --- | --- | --- | --- | --- |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | digest sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 present | PASS |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | digest sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 present | PASS |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | digest sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad present | PASS |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | digest sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 present | PASS |

## No fake metrics / no fake events

| Surface | Resultat |
| --- | --- |
| docker push | 0 |
| deploy / kubectl apply | 0 |
| kubectl set image/env/patch/edit | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| formulaire /register | 0 |
| checkout Stripe | 0 |
| CAPI test | 0 |
| fake event | 0 |
| Linear | 0 |

## Rollback Client PROD documente

- image rollback actuelle: ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod
- digest rollback actuel: sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791
- aucun rollback execute.

## Limites

- Image locale uniquement, aucun RepoDigest tant que PH-21.99 ne pousse pas l'image.
- L'event Antoine n'est pas encore prouve de bout en bout tant que Client PROD n'est pas promu et qu'un vrai parcours /register n'arrive pas.

## Verdict

READY

Phrase finale:

GO BUILD CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD READY PH-SAAS-T8.12AS.21.98

## Prochain GO

GO PUSH IMAGE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD PH-SAAS-T8.12AS.21.99
