# PH-SAAS-T8.12AS.21.11 - PUSH IMAGE API CAPI PLATFORM TOKEN ENCRYPTION PROD

Date UTC : 2026-05-29
Projet : KeyBuzz SaaS
Service : keybuzz-api
Environnement : PROD image registry only
Type : docker push GHCR + pull-back digest verification
Verdict : GO PUSH IMAGE API CAPI PLATFORM TOKEN ENCRYPTION PROD DONE PH-SAAS-T8.12AS.21.11

## Resume

Image API PROD PH-21.10 poussee sur GHCR, puis repullee avec digest match.

Tag :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`

Image ID / config digest :

`sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45`

Manifest digest GHCR :

`sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5`

Aucun build, aucun deploy, aucun `kubectl`, aucune DB/backfill, aucun event tracking et aucune mutation Linear.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.11_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.10_CE_RETURN.md` | lu |
| rapport PH-21.10 infra docs | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | lu |

## Preflight

| Point | Resultat | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IPv4 | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| Start UTC | `2026-05-29T20:24:57Z` | OK |
| End UTC | `2026-05-29T20:25:11Z` | OK |

| Repo | Branche | HEAD local | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `/opt/keybuzz/keybuzz-api` | `ph147.4/source-of-truth` | `9797bedf` | `9797bedf` | `0/0` | 0 hors `dist` | OK |
| `/opt/keybuzz/keybuzz-infra` | `main` | `aa28705` avant rapport | `aa28705` avant rapport | `0/0` | 0 avant action | OK |

Runtime baseline :

PH-21.11 interdit `kubectl`. Aucune commande Kubernetes n'a ete executee. La verification runtime repose sur les rapports read-only precedents et sur les manifests GitOps inchanges.

| Env | Image attendue inchangee | Source | Verdict |
| --- | --- | --- | --- |
| DEV | `v3.5.261-capi-platform-token-encryption-dev` | PH-21.09 + manifest | OK |
| PROD | `v3.5.260-amazon-inbound-address-sync-prod` | PH-21.09 + manifest | OK |

Manifests GitOps observes :

| Manifest | Image |
| --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod` |

Le tag `v3.5.261-capi-platform-token-encryption-prod` est absent des manifests DEV/PROD.

## Local image audit

| Check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Tag local present | oui | oui | OK |
| Image ID | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` | idem | OK |
| OCI revision | `9797bedf1c16ed45467874abb195a87e979be47a` | idem | OK |
| OCI version | `v3.5.261-capi-platform-token-encryption-prod` | idem | OK |
| OCI created | PH-21.10 UTC | `2026-05-29T15:10:58Z` | OK |
| Local RepoDigests avant push | vide | `[]` | OK |

| Marker/check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| `/app/dist/server.js` | present | present | OK |
| `/app/dist/tests` | absent | absent | OK |
| fake tokens PH-21.02 | absent | absent | OK |
| `latest` runtime outbound/server | absent | absent | OK |
| `platform-token-crypto` | present | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present | OK |
| `aes256gcm` | present | present | OK |
| `ADS_ENCRYPTION_KEY` | nom present, valeur non affichee | present | OK |
| `redactSecrets` | present | present | OK |

## GHCR collision

| Controle | Resultat | Verdict |
| --- | --- | --- |
| Tag cible GHCR avant push | absent | OK |
| Collision remote | aucune | OK |
| `latest` avant push manifest | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | observe |
| `latest` avant push config | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` | observe |

## Push image

Commande executee :

```bash
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod
```

Log push :

`/tmp/ph2111-docker-push-20260529T202457Z.log`

Resultat :

| Signal | Valeur |
| --- | --- |
| Push status | PASS |
| Manifest digest pousse | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` |
| Remote config digest apres push | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` |

## Pull-back

Procedure :

1. `docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`
2. `docker pull ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`
3. `docker image inspect`

Log pull :

`/tmp/ph2111-docker-pull-20260529T202457Z.log`

| Signal | Local PH-21.10 | Remote / pull-back | Verdict |
| --- | --- | --- | --- |
| Image ID / config digest | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` | OK |
| Manifest digest | n/a avant push | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | OK |
| RepoDigest pulled | n/a avant push | `ghcr.io/keybuzzio/keybuzz-api@sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | OK |
| OCI revision | `9797bedf1c16ed45467874abb195a87e979be47a` | idem | OK |
| OCI version | `v3.5.261-capi-platform-token-encryption-prod` | idem | OK |
| OCI created | `2026-05-29T15:10:58Z` | idem | OK |

## Latest

| Controle | Avant | Apres | Verdict |
| --- | --- | --- | --- |
| `latest` manifest | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | OK |
| `latest` config | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` | OK |

## No side effect

| Interdit / controle | Resultat |
| --- | --- |
| Build Docker | non execute |
| Push `latest` | non execute |
| Retag `latest` | non execute |
| Deploy | non execute |
| `kubectl` | non execute |
| SQL mutation | non execute |
| DB/backfill | non execute |
| Rotation token | non execute |
| Event tracking / test endpoint CAPI | non execute |
| Git source/API mutation | non execute |
| Manifests GitOps | inchanges |
| Linear mutation | non execute |
| Secret/token/env value affiche | non |
| `/opt/keybuzz/credentials` | non touche |
| `/opt/keybuzz/secrets` | non touche |

## Artefacts

| Artefact | Chemin |
| --- | --- |
| Script mission | `/tmp/ph2111_execute.sh` |
| Push log | `/tmp/ph2111-docker-push-20260529T202457Z.log` |
| Pull log | `/tmp/ph2111-docker-pull-20260529T202457Z.log` |
| Manifest apres push | `/tmp/ph2111-manifest-after-20260529T202457Z.json` |

## Rollback

Aucun rollback runtime n'est necessaire : aucun deploy et aucun manifest n'ont ete modifies.

Le tag PROD actuel en runtime reste :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod`

Toute promotion future doit rester GitOps stricte dans une phase separee.

## Verdict

GO PUSH IMAGE API CAPI PLATFORM TOKEN ENCRYPTION PROD DONE PH-SAAS-T8.12AS.21.11

STOP.
