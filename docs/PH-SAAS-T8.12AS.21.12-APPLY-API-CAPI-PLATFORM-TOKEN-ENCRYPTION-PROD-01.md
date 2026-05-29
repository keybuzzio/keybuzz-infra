# PH-SAAS-T8.12AS.21.12 - APPLY API CAPI PLATFORM TOKEN ENCRYPTION PROD GITOPS

Date UTC : 2026-05-29
Projet : KeyBuzz SaaS
Service : keybuzz-api
Environnement : PROD runtime
Type : GitOps strict API PROD
Verdict : GO APPLY API CAPI PLATFORM TOKEN ENCRYPTION PROD GITOPS READY PH-SAAS-T8.12AS.21.12

## Resume

Image API PROD qualifiee en PH-21.11 deployee en PROD par GitOps strict.

Image cible :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`

Manifest digest GHCR :

`sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5`

Config/Image ID :

`sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45`

Commit GitOps manifest :

`ecb1712 deploy(api): apply CAPI platform token encryption to PROD (PH-21.12)`

Aucun build Docker, aucun docker push, aucun `kubectl set image`, aucune DB mutation, aucun backfill PROD et aucun event tracking.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.12_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.11_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.10_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` | lu |
| rapports PH-21.09 / 21.10 / 21.11 | lus via retours/docs |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | lu |

## Preflight

| Controle | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | OK |
| IPv4 | `46.62.171.61` | `46.62.171.61` | OK |
| IP interdite | `51.159.99.247` absente | absente | OK |
| Date UTC preflight | informatif | `2026-05-29T21:31:22Z` | OK |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `/opt/keybuzz/keybuzz-api` | `ph147.4/source-of-truth` | `9797bedf` | `9797bedf` | `0/0` | 0 hors `dist` | OK |
| `/opt/keybuzz/keybuzz-infra` | `main` | `65714d3` avant patch | `65714d3` avant patch | `0/0` | 0 | OK |

GHCR :

| Signal | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Manifest digest | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | idem | OK |
| Config digest | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` | idem | OK |

## Runtime before

| Env | Service | Spec image | Last-applied image | Pod imageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PROD | `keybuzz-api` | `v3.5.260-amazon-inbound-address-sync-prod` | `v3.5.260-amazon-inbound-address-sync-prod` | `sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8` | `1/1` | `0` | OK |
| DEV | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-dev` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` | OK |

PROD pod before :

`keybuzz-api-cf778495d-pfmls`

## Snapshot before

Read-only only. Aucun token, PII ou secret affiche.

| Compteur PROD | Before |
| --- | ---: |
| `outbound_conversion_delivery_logs` | 19 |
| `conversion_events` | 3 |
| `ai_actions_ledger` | 276 |
| `ai_suggestion_events` | 3642 |
| `outbound_deliveries` | 314 |

## Patch manifest PROD

Fichier modifie :

`k8s/keybuzz-api-prod/deployment.yaml`

Changement :

| Fichier | Changement | Risque |
| --- | --- | --- |
| `k8s/keybuzz-api-prod/deployment.yaml` | 1 ligne image API PROD remplacee par `v3.5.261-capi-platform-token-encryption-prod` | faible, GitOps strict, rollback indique |

Diff fonctionnel :

```diff
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod
```

Controle diff :

| Controle | Resultat |
| --- | --- |
| Fichiers modifies avant commit | 1 |
| Fichier modifie | `k8s/keybuzz-api-prod/deployment.yaml` |
| DEV modifie | non |
| env/secret modifie | non |
| `git diff --check` | OK |

## Dry-run

| Commande | Resultat |
| --- | --- |
| `kubectl apply --dry-run=client -f k8s/keybuzz-api-prod/deployment.yaml` | OK, `deployment.apps/keybuzz-api configured (dry run)` |
| `kubectl apply --dry-run=server -f k8s/keybuzz-api-prod/deployment.yaml` | OK, `deployment.apps/keybuzz-api configured (server dry run)` |

## Commit + push avant apply

| Signal | Resultat |
| --- | --- |
| Commit GitOps manifest | `ecb1712 deploy(api): apply CAPI platform token encryption to PROD (PH-21.12)` |
| Push origin main | OK |
| Infra HEAD/origin apres push | `ecb1712` / `ecb1712` |
| Ahead/behind apres push | `0/0` |

## Apply PROD

Commandes executees :

```bash
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod --timeout=180s
```

Resultat :

| Commande | Resultat |
| --- | --- |
| `kubectl apply -f` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `deployment "keybuzz-api" successfully rolled out` |

Commandes interdites non executees :

- `kubectl set image`
- `kubectl set env`
- `kubectl patch`
- `kubectl edit`

## Runtime after

Un snapshot immediat a vu l'ancien pod encore present pendant sa terminaison. Apres attente courte, le runtime final ne contient plus que le nouveau pod cible.

| Env | Service | Spec image | Last-applied image | Pod imageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PROD | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-prod` | `v3.5.261-capi-platform-token-encryption-prod` | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | `1/1` | `0` | OK |
| DEV | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-dev` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` | OK, inchange |

PROD pod final :

`keybuzz-api-5b444cbc99-lkcnv`

Critical log pattern count after rollout :

`0`

## In-pod markers PROD

| Marker/check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| `/app/dist/server.js` | present | present | OK |
| `/app/dist/tests` | absent | absent | OK |
| fake tokens PH-21.02 | absent | absent | OK |
| `platform-token-crypto` | present | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present | OK |
| `aes256gcm` | present | present | OK |
| `ADS_ENCRYPTION_KEY` | nom present, valeur non affichee | present | OK |
| `redactSecrets` | present | present | OK |

## Snapshot after / no side effect

Read-only only. Aucun provider event, aucun test endpoint CAPI et aucun backfill.

| Compteur PROD | Before | After | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 19 | 19 | 0 |
| `conversion_events` | 3 | 3 | 0 |
| `ai_actions_ledger` | 276 | 276 | 0 |
| `ai_suggestion_events` | 3642 | 3642 | 0 |
| `outbound_deliveries` | 314 | 314 | 0 |

## No side effect

| Interdit / controle | Resultat |
| --- | --- |
| Build Docker | non execute |
| Docker push | non execute |
| `kubectl set image` | non execute |
| `kubectl set env` | non execute |
| `kubectl patch` | non execute |
| `kubectl edit` | non execute |
| SQL mutation | non execute |
| Backfill PROD | non execute |
| Rotation token | non execute |
| Event tracking / test endpoint CAPI | non execute |
| Latest | non utilise |
| Linear mutation | non execute |
| Secret/token/env value dans rapport | non |
| `/opt/keybuzz/credentials` | non touche |
| `/opt/keybuzz/secrets` | non touche |

## Artefacts

| Artefact | Chemin |
| --- | --- |
| Helper execution | `/tmp/ph2112_tools.sh` |
| Patch GitOps | `/tmp/ph2112-prod-manifest.patch` |
| Message commit | `/tmp/ph2112_commitmsg.txt` |
| Rapport remote | `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.12-APPLY-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-PROD-01.md` |

## Rollback

Rollback GitOps strict uniquement si necessaire dans une phase dediee :

1. Modifier `k8s/keybuzz-api-prod/deployment.yaml` pour remettre :
   `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod`
2. Commit + push.
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`.
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`.
5. Verifier manifest = last-applied = runtime.

Ne pas utiliser `kubectl set image`.

## Verdict

GO APPLY API CAPI PLATFORM TOKEN ENCRYPTION PROD GITOPS READY PH-SAAS-T8.12AS.21.12

STOP.
