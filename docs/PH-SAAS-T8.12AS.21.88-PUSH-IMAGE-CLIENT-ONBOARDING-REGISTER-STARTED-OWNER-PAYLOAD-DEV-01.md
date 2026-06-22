# PH-SAAS-T8.12AS.21.88 - Push image Client onboarding register_started owner payload DEV

Date UTC: 2026-06-22T13:20:12Z

Verdict: DONE

Phrase finale:

`GO PUSH IMAGE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV DONE PH-SAAS-T8.12AS.21.88`

## Resume Ludovic

Image Client DEV PH-21.87 poussee sur GHCR et verifiee par pull-back. Manifest digest: `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9`. Pull-back OK avec RepoDigest matching et Image ID `sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e`. `latest` est intact. Runtime Client DEV/PROD inchange. Aucun rebuild, deploy, GitOps, DB mutation, event, formulaire, checkout, Webflow ou Linear.

## Sources relues

- Mission PH-21.88.
- AI_MEMORY: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD.
- Retour PH-21.87 local/bastion.
- Rapport PH-21.87 Infra.
- Retour PH-21.86 PUSH.

## Preflight bastion

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Hostname | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| Date UTC | actuelle | 2026-06-22T13:20:12Z | PASS |
| Docker | disponible | Docker version 29.1.3, build 29.1.3-0ubuntu3~24.04.2 | PASS |
| GHCR auth | OK sans token affiche | push/pull OK | PASS |

## Repos

| Repo | Branche | Remote | HEAD | Origin HEAD | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | origin/ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 |  M tsconfig.tsbuildinfo | PASS |
| keybuzz-infra avant rapport | main | origin/main | 7fc818b3c64b | 7fc818b3c64b | 0/0 | 0 | PASS |

## Confirmation PH-21.87

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Verdict PH-21.87 | READY | confirme | PASS |
| Image locale | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | presente | PASS |
| Image ID | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | PASS |
| Source Git | d9631ca087f1 | d9631ca087f1 | PASS |
| API DEV bundle | presente | confirme PH-21.87 | PASS |
| API PROD bundle | absente | confirme PH-21.87 | PASS |
| Fake triggers | absents | confirme PH-21.87 | PASS |
| No side-effect | 0 | confirme PH-21.87 | PASS |

## Image locale

| Tag | Image ID attendu | Image ID observe | Revision | Verdict |
| --- | --- | --- | --- | --- |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |

Labels locaux:

| Label | Valeur |
| --- | --- |
| org.opencontainers.image.revision | d9631ca087f1751b2def8ad06a049ad93226ffbd |
| org.opencontainers.image.version | v3.5.260-onboarding-register-started-owner-payload-dev |
| org.opencontainers.image.created | 2026-06-22T12:25:54Z |

## Registry

| Item | Avant push | Apres push | Verdict |
| --- | --- | --- | --- |
| tag cible DEV | absent_or_unavailable_rc_1 | digest=sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9, config=sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | PASS |
| latest | sha256:a4d599b416f1f82b9a97e577be4eb249b99dbefa6ec082a3108469cfc6b80e8a | sha256:a4d599b416f1f82b9a97e577be4eb249b99dbefa6ec082a3108469cfc6b80e8a | INTACT |

## Push GHCR

| Image | Push result | Manifest digest |
| --- | --- | --- |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | OK | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 |

## Pull-back

| Verification | Attendu | Resultat |
| --- | --- | --- |
| RepoDigest | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 |
| Image ID / config digest | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e |
| Revision label | d9631ca087f1751b2def8ad06a049ad93226ffbd si disponible | d9631ca087f1751b2def8ad06a049ad93226ffbd |
| Version label | v3.5.260-onboarding-register-started-owner-payload-dev si disponible | v3.5.260-onboarding-register-started-owner-payload-dev |
| Created label | documente si disponible | 2026-06-22T12:25:54Z |

## Runtime read-only

| Service | Image avant | Image apres | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-client-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | 1/1/1/1 | keybuzz-client-5757fcd8fc-lt5bm:0/keybuzz-client-5757fcd8fc-lt5bm:0 | INCHANGE |
| keybuzz-client-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | 1/1/1/1 | keybuzz-client-778b4879bf-dtrpj:0/keybuzz-client-778b4879bf-dtrpj:0 | INCHANGE |

## No fake metrics / no fake events

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Rebuild Docker | 0 | 0 |
| Docker push autre tag/latest | 0 | 0 |
| Deploy / kubectl apply | 0 | 0 |
| DB mutation | 0 | 0 |
| POST /funnel/event | 0 | 0 |
| Event reel/fake | 0 | 0 |
| Formulaire /register | 0 | 0 |
| Checkout Stripe | 0 | 0 |
| Webflow / Linear | 0 | 0 |

## Logs push/pull rediges

Push tail:

```text
4983b93ee796: Preparing
29df493baa13: Preparing
1eb7d16f8d55: Waiting
afa543f85b46: Waiting
e10358715ead: Waiting
4983b93ee796: Waiting
29df493baa13: Waiting
1ae21f0d35b3: Waiting
60d54b643e80: Pushed
ce7c334faaae: Pushed
beb6cbace314: Pushed
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
1eb7d16f8d55: Pushed
29df493baa13: Layer already exists
1ae21f0d35b3: Pushed
e31a9e6e22ce: Pushed
1c06237333cc: Pushed
v3.5.[REDACTED_LONG_VALUE]: digest: sha256:[REDACTED_LONG_VALUE] size: 2631
```

Pull-back tail:

```text
0284d5a387f5: Verifying Checksum
372c1f88c7a7: Verifying Checksum
372c1f88c7a7: Download complete
0284d5a387f5: Pull complete
4ca0fb4d792b: Verifying Checksum
4ca0fb4d792b: Download complete
396424c43a0d: Verifying Checksum
396424c43a0d: Download complete
8514fee94809: Verifying Checksum
8514fee94809: Download complete
aa053b73d73c: Verifying Checksum
aa053b73d73c: Download complete
396424c43a0d: Pull complete
372c1f88c7a7: Pull complete
8514fee94809: Pull complete
4ca0fb4d792b: Pull complete
aa053b73d73c: Pull complete
Digest: sha256:[REDACTED_LONG_VALUE]
Status: Downloaded newer image for ghcr.io/keybuzzio/keybuzz-client:v3.5.[REDACTED_LONG_VALUE]
ghcr.io/keybuzzio/keybuzz-client:v3.5.[REDACTED_LONG_VALUE]
```

## Dettes / limites

- Image poussee uniquement; aucun deploiement DEV encore effectue.
- Aucun test live Ads Manager ou navigation `/register`.
- Le prochain GO doit passer par GitOps DEV separe.

## Prochain GO

`GO APPLY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV GITOPS PH-SAAS-T8.12AS.21.89`
