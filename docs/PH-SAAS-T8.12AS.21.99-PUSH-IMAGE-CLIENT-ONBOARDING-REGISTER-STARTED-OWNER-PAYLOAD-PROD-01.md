# PH-SAAS-T8.12AS.21.99 - PUSH IMAGE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD

Date UTC: 2026-06-23T08:59:49Z
Mode: PUSH IMAGE CLIENT PROD uniquement
Verdict: DONE

## Objectif

Pousser vers GHCR l'image Client PROD construite localement en PH-21.98, sans rebuild, sans deploy et sans event tracking.

## Sources relues

- C:\DEV\KeyBuzz\tmp\PH-21.99_CE_MISSION.md
- C:\DEV\KeyBuzz\tmp\PH-21.98_CE_RETURN.md
- AI_MEMORY/CURRENT_STATE.md
- AI_MEMORY/RULES_AND_RISKS.md
- AI_MEMORY/DOCUMENT_MAP.md
- AI_MEMORY/CE_PROMPTING_STANDARD.md
- PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01
- PH-21.87 / PH-21.88 / PH-21.91 returns
- Docs infra PH-21.86, PH-21.87, PH-21.88, PH-21.91, PH-21.97, PH-21.98

## Preflight bastion

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| host | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| hostname -I | sans IP interdite | 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 | PASS |
| UTC | date affichee | 2026-06-23T08:59:49Z | PASS |
| kube context | lu read-only | kubernetes-admin@kubernetes | PASS |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1751b2def8ad06a049ad93226ffbd | https://github.com/keybuzzio/keybuzz-client.git | 0/0 | 1 | PASS, dirty connu non nettoye |
| keybuzz-infra | main | 6841229f4aade43a00bb9717ccc463b81d770cf9 | https://github.com/keybuzzio/keybuzz-infra.git | 0/0 | 0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | n/a | 0/0 | 223 | PASS read-only |

## Image locale pre-push

| Controle image locale | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Tag local | present | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| Image ID | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | PASS |
| OCI revision | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |
| OCI version | v3.5.260-onboarding-register-started-owner-payload-prod | v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| OCI source | keybuzz-client | https://github.com/keybuzzio/keybuzz-client | PASS |
| RepoDigest local | absent avant push ou documente | [] | PASS |

## Audit image avant push

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| register_started | present | 1 | PASS |
| marketing_owner_tenant_id | present | 3 | PASS |
| UTM | present | source=1 medium=1 campaign=1 content=1 term=1 | PASS |
| click IDs | present | fbclid=1 ttclid=1 gclid=1 li_fat_id=1 | PASS |
| API PROD | present | 87 | PASS |
| API DEV | absent | 0 | PASS |
| fake CompletePayment marker | absent | 0 | PASS |
| secret-like public markers | absent | private_key=0 bearer=0 internal_token_assignment=0 | PASS |

## Registry push / pull-back

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Tag cible distant avant push | absent | absent_rc_1 | PASS |
| Docker push | tag cible exact uniquement | rc=0 | PASS |
| Manifest digest GHCR | sha256 | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | PASS |
| Manifest inspect apres push | OK | hash json=153ca609b8bc0c1c4e240a7fb41a89c006c906a04779bf6263670f4defa3343e | PASS |
| Pull-back | OK | rc=0 | PASS |
| RepoDigest | contient sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ["ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115"] | PASS |
| Image ID pull-back | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | PASS |
| OCI revision pull-back | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |
| OCI version pull-back | v3.5.260-onboarding-register-started-owner-payload-prod | v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| latest | intact | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 -> 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | PASS |

## Runtime read-only non-regression

| Service | Env | Image attendue | Observe | Pod digest attendu | Verdict |
| --- | --- | --- | --- | --- | --- |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | PASS |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | PASS |

## No fake metrics / no fake events

| Surface | Resultat |
| --- | --- |
| docker build / rebuild | 0 |
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

- image runtime actuelle: ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod
- digest runtime actuel: sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791
- aucun rollback execute.

## Limites

- Image publiee uniquement. Client PROD runtime reste v3.5.259 tant que PH-21.100 GitOps n'est pas executee.
- L'event Antoine n'est pas encore prouve de bout en bout tant que Client PROD n'est pas deployee et qu'un vrai parcours /register n'arrive pas.

## Verdict

DONE

Phrase finale:

GO PUSH IMAGE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD DONE PH-SAAS-T8.12AS.21.99

## Prochain GO

GO APPLY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD GITOPS PH-SAAS-T8.12AS.21.100
