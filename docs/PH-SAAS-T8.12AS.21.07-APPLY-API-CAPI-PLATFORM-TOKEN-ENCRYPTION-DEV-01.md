# PH-SAAS-T8.12AS.21.07 - Apply API CAPI platform token encryption DEV GitOps

Date UTC: 2026-05-29
Executor: Codex Executor
Scope: GitOps API DEV uniquement. Aucun backfill, aucune DB mutation, aucun event tracking, aucune PROD.

## Verdict

GO APPLY API CAPI PLATFORM TOKEN ENCRYPTION DEV GITOPS READY PH-SAAS-T8.12AS.21.07

## Image cible

| Champ | Valeur |
| --- | --- |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| Manifest digest GHCR | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |
| Config/Image ID | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |
| Source API | `9797bedf1c16ed45467874abb195a87e979be47a` |
| Rollback DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev` |

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.07_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.05_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.06_CE_RETURN.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.05-BUILD-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.06-PUSH-IMAGE-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `docs/AI_MEMORY/CURRENT_STATE.md` | lu |
| `docs/AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` | lu |

PH-21.06 confirme: image GHCR poussee, pull-back OK, RepoDigest `ghcr.io/keybuzzio/keybuzz-api@sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb`.

## Preflight

| Controle | Attendu | Resultat |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IP bastion | `46.62.171.61` | OK |
| IP interdite | `51.159.99.247` | non utilisee |
| Date bastion | lecture UTC | `2026-05-29T13:10:14Z` |
| API branch | `ph147.4/source-of-truth` | OK |
| API HEAD/origin | `9797bedf` / `9797bedf` | OK |
| API ahead/behind | `0 0` | OK |
| API dirty hors `dist/` | `0` | OK |
| Infra branch | `main` | OK |
| Infra HEAD/origin avant patch | `40ec04f` / `40ec04f` | OK |
| Infra ahead/behind avant patch | `0 0` | OK |
| Infra dirty avant patch | `0` | OK |

## GHCR

| Controle | Resultat |
| --- | --- |
| `docker manifest inspect --verbose` | OK |
| Descriptor digest | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` |
| Config digest | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |

## Runtime before

| Env | Spec image | Last-applied image | Pod image digest | Ready | Restarts |
| --- | --- | --- | --- | --- | --- |
| DEV | `v3.5.260-amazon-inbound-address-sync-dev` | `v3.5.260-amazon-inbound-address-sync-dev` | `sha256:b05da3d78801a432851d2cd14c58cc6a4141f314c8539c12cc3a126b821b7a7e` | `1/1` | `0` |
| PROD | `v3.5.260-amazon-inbound-address-sync-prod` | `v3.5.260-amazon-inbound-address-sync-prod` | `sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8` | `1/1` | `0` |

## Snapshot before

| Compteur DEV | Before |
| --- | ---: |
| `outbound_conversion_delivery_logs` | 7 |
| `conversion_events` | 0 |
| `ai_actions_ledger` | 550 |
| `ai_suggestion_events` | 2728 |
| `outbound_deliveries` | 310 |

## Patch manifest DEV

| Fichier | Changement | Risque |
| --- | --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | ligne `image:` DEV remplacee par `v3.5.261-capi-platform-token-encryption-dev` | faible, changement GitOps cible uniquement |

Diff verifie:

| Controle | Resultat |
| --- | --- |
| Fichiers modifies | 1 |
| Lignes modifiees | 1 insertion / 1 deletion |
| PROD modifiee | non |
| Env/secret modifie | non |
| `git diff --check` | OK |

Note execution: une tentative initiale `git apply --check` avec patch local a ete refusee par Git sans mutation repo. Le remplacement final a ete execute par script exact-match: la ligne source devait etre trouvee exactement une seule fois, puis le diff Git a confirme un seul changement de ligne image.

## Dry-run

| Commande | Resultat |
| --- | --- |
| `kubectl apply --dry-run=client -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured (dry run)` |
| `kubectl apply --dry-run=server -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured (server dry run)` |

## Commit + push avant apply

| Controle | Resultat |
| --- | --- |
| Commit infra | `89c62c3` |
| Message | `deploy(api): apply CAPI platform token encryption to DEV (PH-21.07)` |
| Push origin main | OK |
| Infra HEAD/origin apres push | `89c62c3` / `89c62c3` |
| Ahead/behind apres push | `0 0` |
| Dirty apres push | `0` |

## Apply DEV

| Commande | Resultat |
| --- | --- |
| `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev --timeout=300s` | `deployment "keybuzz-api" successfully rolled out` |

Commandes interdites non utilisees: `kubectl set image`, `kubectl set env`, `kubectl patch`, `kubectl edit`.

## Runtime after

| Env | Spec image | Last-applied image | Pod image digest | Ready | Restarts |
| --- | --- | --- | --- | --- | --- |
| DEV | `v3.5.261-capi-platform-token-encryption-dev` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` |
| PROD | `v3.5.260-amazon-inbound-address-sync-prod` | `v3.5.260-amazon-inbound-address-sync-prod` | `sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8` | `1/1` | `0` |

Runtime DEV = manifest DEV = last-applied DEV = GHCR manifest digest cible.

## Logs boot

| Controle | Resultat |
| --- | --- |
| Pod verifie | `keybuzz-api-5b6cc7fff9-hdg58` |
| `kubectl logs` status | `0` |
| Lignes critiques (`fatal|uncaught|unhandled|panic|error`) | `0` |
| stderr logs | `0` |

## Markers runtime in-pod

| Controle | Resultat |
| --- | --- |
| `/app/dist/server.js` | present |
| `/app/dist/tests` | absent |
| Faux tokens PH-21.02 / fausse cle | `0` |
| `platform-token-crypto` | PRESENT |
| `encryptOutboundPlatformTokenForStorage` | PRESENT |
| `decryptOutboundPlatformTokenForProvider` | PRESENT |
| `prepareOutboundPlatformTokenUpdate` | PRESENT |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | PRESENT |
| `aes256gcm` | PRESENT |
| `ADS_ENCRYPTION_KEY` | PRESENT |
| `platform_token_ref` | PRESENT |
| `redactSecrets` | PRESENT |

## Snapshot after / no side effect

| Compteur DEV | Before | After | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 7 | 7 | 0 |
| `conversion_events` | 0 | 0 | 0 |
| `ai_actions_ledger` | 550 | 550 | 0 |
| `ai_suggestion_events` | 2728 | 2728 | 0 |
| `outbound_deliveries` | 310 | 310 | 0 |

Verdict no side effect: aucun event tracking cree, aucun backfill, aucun compteur suspect observe.

## Non-regression / hors scope

| Interdit | Resultat |
| --- | --- |
| Build Docker | non execute |
| Docker push | non execute |
| SQL mutation | non execute |
| Backfill | non execute |
| Rotation token | non execute |
| Event tracking / endpoint CAPI | non execute |
| PROD apply | non execute |
| `latest` | non utilise |
| Linear mutation | non execute |
| Secrets/credentials | non affiches, non modifies |

## Rollback GitOps

Rollback autorise uniquement par GitOps:

1. Remettre `k8s/keybuzz-api-dev/deployment.yaml` sur `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev`.
2. Commit + push `main`.
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`.
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev`.
5. Verifier manifest = last-applied = runtime digest rollback.

Ne pas utiliser `kubectl set image`, `kubectl patch`, `kubectl edit` ou `latest`.

## Conclusion

L'image API DEV `v3.5.261-capi-platform-token-encryption-dev` est deployee en DEV par GitOps strict. Le runtime DEV est aligne sur le manifest et l'annotation last-applied, avec digest `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb`. Les marqueurs de chiffrement sont presents in-pod, `/app/dist/tests` est absent, les compteurs read-only n'ont pas varie, et PROD est restee inchangee.

Phrase finale:

GO APPLY API CAPI PLATFORM TOKEN ENCRYPTION DEV GITOPS READY PH-SAAS-T8.12AS.21.07

STOP.
