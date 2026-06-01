# PH-SAAS-T8.12AS.21.31 - Apply API LLM provider credit watcher DEV

## Verdict

GO APPLY API LLM PROVIDER CREDIT WATCHER DEV GITOPS READY PH-SAAS-T8.12AS.21.31

## Scope execute

- Mode APPLY GITOPS DEV respecte.
- Manifest API DEV modifie sur la ligne image uniquement.
- Commit GitOps pousse avant apply.
- `kubectl apply -f` execute uniquement sur le manifest API DEV.
- Rollout API DEV OK.
- Aucun build.
- Aucun docker push.
- Aucun apply PROD.
- Aucun apply monitoring-alerts.
- Aucun secret runtime cree ou lu.
- Aucune mutation DB volontaire.
- Aucun appel LLM.
- Aucun event tracking.
- Aucun trigger alert/CronJob.
- Aucun Slack/email.
- Aucun Linear.
- Aucun patch source.
- Aucun commit API.

## Sources relues

| source | statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.31_CE_MISSION.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.30_CE_RETURN.md` | relu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.30-PUSH-IMAGE-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.29_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.28_PUSH_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.28_CE_RETURN.md` | relu |
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |

## Preflight

| check | resultat | verdict |
| --- | --- | --- |
| host | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` presente | OK |
| IPv4 interdite | `51.159.99.247` absente | OK |
| UTC | `2026-06-01T20:48:41Z` | OK |

## Repos

| repo | branche | HEAD | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra before | `main` | `a752fd0cd9b51d3fe29ee68cf972878d272c1a2b` | `a752fd0cd9b51d3fe29ee68cf972878d272c1a2b` | `0/0` | clean | OK |
| keybuzz-api read-only | `ph147.4/source-of-truth` | `76483e3a0e1073740586035f14b86ed9bcec07b9` | `76483e3a0e1073740586035f14b86ed9bcec07b9` | `0/0` | suppressions `dist/` preexistantes | OK |

## GHCR / runtime before

| signal | attendu | resultat | verdict |
| --- | --- | --- | --- |
| target manifest digest | `sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996` | identique | OK |
| target config digest | `sha256:4f9af83f12937f3b24dbf8cb469b2b08ebbe062c13fde8819739bb1fef00babf` | identique | OK |
| latest descriptor | intact | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | OK |
| DEV API before | `v3.5.262-llm-provider-credit-alerting-dev` | ready `1/1`, restarts `0`, digest `sha256:f6be25608e769afa32d4d0408d808ccefd4bc14af98e5b36de2dba900b3ad891` | OK |
| PROD API before | `v3.5.262-llm-provider-credit-alerting-prod` | ready `1/1`, restarts `0`, digest `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | OK |

## Snapshot before

SELECT-only via pod API DEV, sans affichage de secret.

| signal | before |
| --- | --- |
| `ai_suggestion_events` | `2732` |
| `ai_actions_ledger` | `550` |
| `ai_usage` | `637` |
| `conversion_events` | `0` |
| `outbound_conversion_delivery_logs` | `7` |
| `tracking_events` | `32434` |

## Patch manifest

File changed:

```text
k8s/keybuzz-api-dev/deployment.yaml
```

Diff scope:

- 1 fichier.
- Ligne image API DEV uniquement.
- Commentaire rollback de la meme ligne mis a jour.
- Aucun manifest PROD modifie.
- Aucun manifest monitoring-alerts modifie.
- Aucune env, secret, resource, command, probe, label ou namespace modifie.

Image before:

```text
ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-dev
```

Image after:

```text
ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev
```

## Dry-run

| check | resultat | verdict |
| --- | --- | --- |
| `kubectl apply --dry-run=client -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured (dry run)` | OK |
| `kubectl apply --dry-run=server -f k8s/keybuzz-api-dev/deployment.yaml` | `deployment.apps/keybuzz-api configured (server dry run)` | OK |

## GitOps deploy commit

| commit | scope | pushed | ahead/behind | verdict |
| --- | --- | --- | --- | --- |
| `31c4258f51dbe8474c0bf3b5146ef2a01c9a33c8` | manifest API DEV only | oui | `0/0` | OK |

Commit message:

```text
deploy(api): PH-21.31 apply LLM provider credit watcher dev
```

## Apply / rollout

Commandes executees:

```text
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev --timeout=240s
```

Resultat rollout final:

```text
deployment "keybuzz-api" successfully rolled out
```

Note operationnelle: une premiere verification automatique a lu un ancien pod pendant
la transition du rollout. Sans action manuelle ni suppression, l'ancien pod a disparu et
la verification finale a porte sur le seul pod API DEV courant.

## Runtime equality API DEV

| service | spec | last-applied | pod | imageID digest | ready | restarts | verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api DEV | tag cible | tag cible | tag cible | `sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996` | `1/1` | `0` | OK |

Details:

```text
spec_image=ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev
last_applied_image=ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev
pod=keybuzz-api-698766ccc6-k82nk
pod_image=ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev
pod_image_id=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996
pod_count=1
pod_restarts=0
```

Boot logs:

- grep `fatal|unhandled|uncaught|exception|error` a remonte 1 ligne non bloquante:
  `Completed: tenants=0 imported=0 skipped=0 errors=0`.
- Aucun crash, aucune exception boot, aucun restart.

## Runtime marker audit in-pod

| marker | resultat | verdict |
| --- | --- | --- |
| endpoint route interne | present | OK |
| `llm-provider-credit-monitoring` | present | OK |
| `monitoring/llm-provider-credit` | present | OK |
| `x-keybuzz-monitor-token` | present | OK |
| `x-internal-token` | present | OK |
| `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | present | OK |
| `PROVIDER_CREDIT_EXHAUSTED` | present | OK |
| AI Assist refs | present | OK |
| Autopilot refs | present | OK |
| Returns refs | present | OK |
| KBActions refs | present | OK |
| `dist/tests` | absent | OK |
| test file PH-21.28 | absent | OK |
| webhook Slack complet | absent | OK |

Resultat:

```text
RUNTIME_MARKERS_PASS
```

## Endpoint auth refusal check

Check sans token, depuis le pod API DEV:

| check | expected | result | verdict |
| --- | --- | --- | --- |
| `GET /internal/monitoring/llm-provider-credit?windowSeconds=900` sans token | `401` ou `403` | `403` | OK |

Aucun vrai token fourni. Aucun secret cree. Aucun appel monitoring-alerts.

## Snapshot after

| signal | before | after | delta | interpretation |
| --- | --- | --- | --- | --- |
| `ai_suggestion_events` | `2732` | `2732` | `0` | aucun event CE |
| `ai_actions_ledger` | `550` | `550` | `0` | aucun debit KBActions CE |
| `ai_usage` | `637` | `637` | `0` | aucun appel LLM CE |
| `conversion_events` | `0` | `0` | `0` | aucun event conversion CE |
| `outbound_conversion_delivery_logs` | `7` | `7` | `0` | aucune livraison outbound CE |
| `tracking_events` | `32434` | `32434` | `0` | aucun tracking event CE |

## PROD / monitoring-alerts / autres services intacts

| service | before | after | verdict |
| --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` | identique | OK |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev` | identique | OK |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod` | identique | OK |
| Backend DEV | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev` | identique | OK |
| Backend PROD | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod` | identique | OK |
| monitoring-alerts CronJob | `monitoring-alerts|*/2 * * * *|false|curlimages/curl:8.7.1` | identique | OK |
| secret `monitoring-llm-provider-credit-token` | absent | absent | OK |
| latest API descriptor | `sha256:2149f748f362fc23beabe69e83fa7785563e8c8967ede78f56bec256de9c09e4` | identique | OK |

## Non-regression

| interdit | statut |
| --- | --- |
| build / docker build | non effectue |
| docker push | non effectue |
| apply PROD | non effectue |
| apply monitoring-alerts | non effectue |
| `kubectl set image/env/patch/edit` | non effectue |
| secret runtime | non cree, non lu |
| DB mutation | non effectuee |
| LLM call | non effectue |
| fake metric / fake event | non effectue |
| trigger alert/CronJob | non effectue |
| Slack/email | non effectue |
| Linear | non effectue |
| API source | non modifie |

## Rollback documente, non execute

Rollback GitOps uniquement si demande explicite:

1. Revert du deploy commit `31c4258f51dbe8474c0bf3b5146ef2a01c9a33c8`.
2. Push normal non-force du revert.
3. `kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`.
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev`.
5. Verifier runtime = manifest = last-applied = rollback image.

Rollback image documentee:

```text
ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-dev
```

## Limites / dettes

- Secret runtime `monitoring-llm-provider-credit-token` toujours non cree/non lu.
- Watcher `monitoring-alerts` source deja pousse mais non applique/deploye.
- Cette phase expose l'endpoint dans API DEV seulement; elle n'active pas le watcher.
- Prochaine phase recommandee: verification read-only API DEV.

## Rapport

Remote report:

```text
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.31-APPLY-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md
```

Local return:

```text
C:\DEV\KeyBuzz\tmp\PH-21.31_CE_RETURN.md
```

## Prochaine phrase GO

`GO READONLY VERIFY API LLM PROVIDER CREDIT WATCHER DEV PH-SAAS-T8.12AS.21.32`

STOP.
