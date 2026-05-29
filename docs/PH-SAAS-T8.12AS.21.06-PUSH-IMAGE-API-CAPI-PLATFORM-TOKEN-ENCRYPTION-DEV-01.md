# PH-SAAS-T8.12AS.21.06 - Push image API CAPI platform token encryption DEV

Date UTC: 2026-05-29
Executor: Codex Executor
Scope: push image DEV uniquement + pull-back digest match

## Verdict

GO PUSH IMAGE API CAPI PLATFORM TOKEN ENCRYPTION DEV DONE PH-SAAS-T8.12AS.21.06

## Image cible

| Champ | Valeur |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| Image ID attendu | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |
| Revision attendue | `9797bedf1c16ed45467874abb195a87e979be47a` |
| Manifest digest publie | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |

## Sources relues

| Source | Resultat |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.06_CODEX_EXECUTOR_MISSION.md` | Mission lue |
| `C:\DEV\KeyBuzz\tmp\PH-21.05_CE_RETURN.md` | Image locale qualifiee confirmee |
| `C:\DEV\KeyBuzz\tmp\PH-21.04_PUSH_CE_RETURN.md` | Contexte commit source confirme |
| `docs/AI_MEMORY/RULES_AND_RISKS.md` | Regles bastion/GitOps confirmees |
| `docs/AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | Protocole retour fichier confirme |

## Preflight

| Controle | Attendu | Resultat |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IP bastion | `46.62.171.61` | OK |
| IP interdite | `51.159.99.247` | Non utilisee |
| UTC bastion | Lecture seule | `2026-05-29T12:37:13Z` |
| API branch | `ph147.4/source-of-truth` | OK |
| API HEAD | `9797bedf` | OK |
| API origin | `9797bedf` | OK |
| API ahead/behind | `0 0` | OK |
| API dirty total | suppressions `dist/` connues | `223` |
| API dirty hors `dist/` | `0` | OK |
| Infra branch | `main` | OK |
| Infra HEAD avant rapport | `536d97f` | OK |
| Infra origin avant rapport | `536d97f` | OK |
| Infra dirty avant rapport | `0` | OK |

## Controle image locale avant push

| Controle | Resultat |
| --- | --- |
| Image ID locale | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |
| RepoDigests avant push | `[]` |
| Tag local | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| Label revision | `9797bedf1c16ed45467874abb195a87e979be47a` |
| Label created | `2026-05-29T12:14:53Z` |
| Label version | `v3.5.261-capi-platform-token-encryption-dev` |

## Audit contenu image

| Controle | Resultat |
| --- | --- |
| `/app/dist/server.js` | present |
| `/app/dist/tests` | absent |
| Faux tokens / fausse cle de test | `0` |
| Reference `latest` dans dist outbound/server | `0` |
| `platform-token-crypto` | PRESENT |
| `encryptOutboundPlatformTokenForStorage` | PRESENT |
| `decryptOutboundPlatformTokenForProvider` | PRESENT |
| `prepareOutboundPlatformTokenUpdate` | PRESENT |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | PRESENT |
| `aes256gcm` | PRESENT |
| `ADS_ENCRYPTION_KEY` | PRESENT |
| `platform_token_ref` | PRESENT |
| `redactSecrets` | PRESENT |

## GHCR avant push

| Controle | Resultat |
| --- | --- |
| Manifest cible avant push | absent |
| Sortie | `manifest unknown` |
| Collision tag | aucune |
| `latest` avant | present |
| Config digest `latest` avant | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` |

## Push execute

Commande autorisee executee sur le bastion:

```text
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev
```

Resultat:

```text
v3.5.261-capi-platform-token-encryption-dev: digest: sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb size: 2416
```

## GHCR apres push

| Controle | Resultat |
| --- | --- |
| Manifest cible apres push | present |
| Config digest distante | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |
| Match Image ID locale qualifiee | OK |
| Manifest digest | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |

## Pull-back

| Etape | Resultat |
| --- | --- |
| `docker rmi` du tag cible | OK |
| `docker pull` du tag cible | OK |
| Digest annonce au pull | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |
| Image ID apres pull | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |
| RepoDigest apres pull | `ghcr.io/keybuzzio/keybuzz-api@sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |
| Label revision apres pull | `9797bedf1c16ed45467874abb195a87e979be47a` |
| Pull-back digest match | OK |

## Controle `latest`

| Controle | Resultat |
| --- | --- |
| Config digest `latest` avant push | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` |
| Config digest `latest` apres push | `sha256:de958f4453474c3cede91e83bcdca4cfb2a4f6df0a1438810978e6f497e1707f` |
| Mutation de `latest` | aucune |

## GitOps / runtime

| Controle | Resultat |
| --- | --- |
| Build | Non execute |
| Deploy | Non execute |
| `kubectl` | Non execute |
| DB / backfill | Non execute |
| Event tracking | Non execute |
| Manifest GitOps modifie | Non |
| Reference image dans infra | uniquement rapports docs PH-21.03 et PH-21.05 avant ajout du present rapport |

Note: la mission interdit deploy/kubectl/runtime mutation. Aucun controle runtime Kubernetes n'a ete execute. La validation PH-21.06 se limite volontairement au push GHCR et au pull-back digest match.

## Non-regression

| Risque | Verdict |
| --- | --- |
| Tag distant existant avec digest different | OK, tag absent avant push |
| Pousser `latest` | OK, non fait |
| Build accidentel | OK, non fait |
| Deploy accidentel | OK, non fait |
| Tests embarques dans image runtime | OK, absents |
| Faux tokens / fausse cle dans image | OK, absents |
| Chiffrement platform token absent | OK, marqueurs presents |

## Conclusion

L'image DEV API qualifiee en PH-21.05 a ete poussee sur GHCR sous le tag immutable attendu. Le manifest distant pointe vers la config digest `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b`, et le pull-back prouve le RepoDigest `ghcr.io/keybuzzio/keybuzz-api@sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb`.

STOP.
