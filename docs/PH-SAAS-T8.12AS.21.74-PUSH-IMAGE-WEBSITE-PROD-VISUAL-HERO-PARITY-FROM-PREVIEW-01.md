RESUME LUDOVIC - TERMINAL
PH-21.74 PUSH IMAGE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW : DONE
Tag pousse : ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod
Manifest digest GHCR : sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4
Config digest / Image ID : sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2
Pull-back : OK ; RepoDigest=ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 ; Image ID=sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2
Latest : intact (present:706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5)
Runtime DEV/PROD : inchanges, aucun deploy/kubectl apply/manifest
Rapport infra : /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.74-PUSH-IMAGE-WEBSITE-PROD-VISUAL-HERO-PARITY-FROM-PREVIEW-01.md
Prochain GO exact : GO APPLY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW GITOPS PH-SAAS-T8.12AS.21.75
GO PUSH IMAGE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW DONE PH-SAAS-T8.12AS.21.74
STOP

# PH-SAAS-T8.12AS.21.74 - Push image Website PROD visual hero parity from preview

## Scope

PUSH IMAGE ONLY respecte.

- Aucun build.
- Aucun rebuild.
- Aucun retag.
- Aucun push latest.
- Aucun deploy.
- Aucun kubectl apply.
- Aucun manifest modifie.
- Aucun formulaire.
- Aucun checkout Stripe.
- Aucun fake event tracking.
- Aucun Webflow.
- Aucun Linear.

## Sources relues

| Source | Statut |
|---|---|
| PH-21.74 mission locale | relue |
| AI_MEMORY CURRENT_STATE | relue |
| AI_MEMORY RULES_AND_RISKS | relue |
| AI_MEMORY DOCUMENT_MAP | relue |
| AI_MEMORY CE_PROMPTING_STANDARD | relue |
| PH-T8.10J modele | relu |
| PH-21.72 retour | relu |
| PH-21.73 retour | relu |
| PH-21.71/21.72/21.73 docs bastion | disponibles dans keybuzz-infra/docs |
| Website BUILD-ARGS | disponible dans keybuzz-website/docs |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
|---|---|---|---|---|---|---|
| Website | main | bd32fc8bc9d9554770cc611f0712998b111473ff | bd32fc8bc9d9554770cc611f0712998b111473ff | 0/0 / 0/0 | 0 / 0 | PASS |
| Infra before report | main | d52ad35fd60b9ea5b13a9984fbd34437b7d2d49e | d52ad35fd60b9ea5b13a9984fbd34437b7d2d49e | 0/0 | 0 | PASS |

## Image locale

| Champ | Attendu | Observe | Verdict |
|---|---|---|---|
| Tag local present | oui | oui | PASS |
| Image ID | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | PASS |
| OCI revision | bd32fc8bc9d9554770cc611f0712998b111473ff | bd32fc8bc9d9554770cc611f0712998b111473ff | PASS |
| OCI version | v0.7.2-visual-hero-parity-prod | v0.7.2-visual-hero-parity-prod | PASS |
| OCI title | keybuzz-website | keybuzz-website | PASS |
| OCI source | https://github.com/keybuzzio/keybuzz-website | https://github.com/keybuzzio/keybuzz-website | PASS |

## Registry

| Check | Avant | Apres | Verdict |
|---|---|---|---|
| Tag cible GHCR | absent | present:0863f7c1200ea9974dd8fcbbc23b2065a0f55a084208309289a25b6338440062 | PASS |
| Manifest digest GHCR | absent | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | PASS |
| Config digest | n/a | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | PASS |
| latest hash | present:706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5 | present:706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5 | PASS |
| GitOps refs target | 0 | 0 | PASS |

## Push cible unique

| Action | Resultat | Verdict |
|---|---|---|
| docker push tag cible seul | execute | PASS |
| Manifest digest retourne | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | PASS |
| Autre tag pousse | non | PASS |
| latest pousse | non | PASS |
| build/rebuild execute | non | PASS |
| retag execute | non | PASS |

## Pull-back

| Check | Attendu | Observe | Verdict |
|---|---|---|---|
| Manifest digest GHCR | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | PASS |
| Config digest | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | PASS |
| Image ID repullee | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 | PASS |
| RepoDigest | ghcr.io/keybuzzio/keybuzz-website@sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | present | PASS |
| OCI revision | bd32fc8bc9d9554770cc611f0712998b111473ff | bd32fc8bc9d9554770cc611f0712998b111473ff | PASS |
| OCI version | v0.7.2-visual-hero-parity-prod | v0.7.2-visual-hero-parity-prod | PASS |
| OCI title | keybuzz-website | keybuzz-website | PASS |
| OCI source | https://github.com/keybuzzio/keybuzz-website | https://github.com/keybuzzio/keybuzz-website | PASS |

## Runtime read-only

| Service | Namespace | Image avant | Image apres | Ready | Restarts | Digest observe | Verdict |
|---|---|---|---|---|---|---|---|
| Website PROD | keybuzz-website-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod | 2/2 | 0 0 | sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b count=2 | PASS |
| Website DEV | keybuzz-website-dev | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | 1/1 | 0 | sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b count=1 | PASS |

## No fake metrics / no fake events

| Interdit | Resultat |
|---|---|
| StartTrial | aucun event |
| Purchase | aucun event |
| CompletePayment | aucun event |
| InitiateCheckout | aucun event |
| Lead | aucun event |
| CAPI / GA4 / Meta / TikTok / LinkedIn | aucun appel |
| Formulaire / checkout | aucun |

## Non-regression passive

| Surface | Attendu | Resultat |
|---|---|---|
| Website PROD runtime | inchange | PASS |
| Website DEV runtime | inchange | PASS |
| GitOps manifests | aucun changement | PASS |
| DB | aucune mutation | PASS |
| Tracking | aucun event | PASS |
| Webflow | aucune mutation | PASS |
| Linear | aucune mutation | PASS |

## Dettes restantes

1. PROD GitOps apply separee PH-21.75 requise pour rendre le hero visuel live.
2. Dettes Website connues : lint global, npm audit dependencies.
3. Webflow try.keybuzz.io et attribution Meta reelle restent sujets separes.
4. Client GA4 parity reste dette separee.
5. Backfill-scheduler reste dette SRE separee.
6. PreviewBanner guard reste dette non bloquante documentee.

## Verdict

DONE.

Prochain GO exact :

```
GO APPLY WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW GITOPS PH-SAAS-T8.12AS.21.75
```
