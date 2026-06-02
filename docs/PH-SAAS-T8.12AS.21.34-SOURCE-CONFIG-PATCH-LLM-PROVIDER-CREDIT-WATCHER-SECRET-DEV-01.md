# PH-SAAS-T8.12AS.21.34 - Source config patch LLM provider credit watcher secret DEV

## Verdict

GO SOURCE CONFIG PATCH LLM PROVIDER CREDIT WATCHER SECRET DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.34

Patch source/config DEV complet et committe localement. Aucun push, aucun build, aucun deploy,
aucun `kubectl apply` reel, aucun Secret runtime cree, aucune valeur de secret lue ou affichee.

Verdict `READY_WITH_DEBTS` car la source GitOps est prete, mais la materialisation de la valeur
dans le secret manager, le push source, les applies GitOps, la verification endpoint authentifiee
et l'activation watcher restent des phases futures separees.

## Sources relues

| source | statut | impact |
| --- | --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.34_CE_MISSION.md` | relu | scope et interdits |
| `C:\DEV\KeyBuzz\tmp\PH-21.33_CE_RETURN.md` | relu | option B+C |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.33-READONLY-DESIGN-LLM-PROVIDER-CREDIT-WATCHER-SECRET-DEV-01.md` | relu | design secret dedie |
| `C:\DEV\KeyBuzz\tmp\PH-21.32_CE_RETURN.md` | relu | runtime API DEV et secret absent |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.32-READONLY-VERIFY-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | endpoint present/protege |
| `C:\DEV\KeyBuzz\tmp\PH-21.31_CE_RETURN.md` | relu | API DEV v3.5.263 appliquee |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.31-APPLY-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | GitOps API DEV |
| `C:\DEV\KeyBuzz\tmp\PH-21.28_CE_RETURN.md` | relu | endpoint, watcher, tests |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.28-SOURCE-PATCH-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | dette secret runtime |
| `AI_MEMORY/CURRENT_STATE.md` | relu | contexte projet |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu | GitOps/secrets/interdits |
| `AI_MEMORY/DOCUMENT_MAP.md` | relu | cartographie docs |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu | protocole CE |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | relu | modele long |

## Preflight

| check | resultat | verdict |
| --- | --- | --- |
| bastion | `install-v3` | OK |
| IP obligatoire | `46.62.171.61` presente | OK |
| IP interdite | `51.159.99.247` absente | OK |
| UTC | `2026-06-02T09:44:28Z` | OK |
| kube context | `kubernetes-admin@kubernetes` | OK |

## Repos

| repo | branche | HEAD avant patch | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | `main` | `4121ee1c20ef` | `4121ee1c20ef` | `0/0` | clean | OK |
| keybuzz-api | `ph147.4/source-of-truth` | `76483e3a0e10` | `76483e3a0e10` | `0/0` | suppressions `dist/` preexistantes | OK, lecture seule |

## Runtime baseline

| surface | observe | verdict |
| --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev`, ready `1`, generation `501` | OK |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod`, ready `1`, generation `422` | OK read-only |
| monitoring-alerts runtime | schedule `*/2 * * * *`, suspend `false`, image `curlimages/curl:8.7.1` | OK |
| Secret watcher runtime | `monitoring-llm-provider-credit-token` absent metadata-only | OK, non cree |

## Preuves PH-21.28 a PH-21.33

| Phase | preuve | valeur | impact patch |
| --- | --- | --- | --- |
| PH-21.28 | endpoint | `GET /internal/monitoring/llm-provider-credit?windowSeconds=900` | cible du watcher |
| PH-21.28 | header watcher | `X-KeyBuzz-Monitor-Token` | conserve |
| PH-21.28 | env API prioritaire | `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | ajoute en API DEV |
| PH-21.28 | secretRef watcher | `monitoring-llm-provider-credit-token/token`, optional true | deja correct |
| PH-21.28 | mode watcher | dry-run/log-only | conserve |
| PH-21.32 | endpoint sans token | `403` | endpoint protege |
| PH-21.33 | decision | Option B+C | ExternalSecret dedie |

## Patterns ExternalSecret / secretKeyRef observes

| pattern | fichier | namespace | secret cible | store | remoteRef non sensible | applicable |
| --- | --- | --- | --- | --- | --- | --- |
| Internal token DEV | `k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml` | `keybuzz-api-dev` | `keybuzz-internal-tokens` | `vault-backend` | `secret/keybuzz/<domain>/<env>/<purpose>`, property `value` | oui |
| LiteLLM DEV | `k8s/keybuzz-api-dev/externalsecret-litellm.yaml` | `keybuzz-api-dev` | `keybuzz-litellm-secrets` | `vault-backend` | logical key + property `value` | oui |
| JWT DEV | `k8s/keybuzz-api-dev/externalsecret-jwt.yaml` | `keybuzz-api-dev` | `keybuzz-api-jwt` | `vault-backend` | `keybuzz/dev/<domain>`, named properties | oui |
| Store runtime | `ClusterSecretStore vault-backend` | cluster | n/a | `Valid`, `ReadWrite` | metadata only | oui |
| secretKeyRef API DEV | `k8s/keybuzz-api-dev/deployment.yaml` | `keybuzz-api-dev` | existing Secret refs | n/a | names and keys only | oui |
| secretKeyRef watcher | `k8s/monitoring-alerts/cronjob.yaml` | `vault-management` | `monitoring-llm-provider-credit-token` | n/a | key `token` | deja correct |

Decision: le pattern est suffisamment clair pour preparer un ExternalSecret dedie. Le remoteRef
retenu suit le pattern interne `secret/keybuzz/<domain>/<env>/<purpose>` avec property `value`.
Ce chemin est une reference source, pas une valeur de secret. PH-21.35 devra materialiser la
valeur correspondante dans le secret manager.

## Fichiers patches

| fichier | changement | risque | verdict |
| --- | --- | --- | --- |
| `k8s/keybuzz-api-dev/externalsecret-llm-provider-credit-monitor-token.yaml` | ExternalSecret API DEV vers Secret `monitoring-llm-provider-credit-token`, key `token` | valeur absente tant que PH-21.35 non faite | OK |
| `k8s/monitoring-alerts/externalsecret-llm-provider-credit-token.yaml` | ExternalSecret watcher en `vault-management`, meme source logique | valeur absente tant que PH-21.35 non faite | OK |
| `k8s/keybuzz-api-dev/deployment.yaml` | env `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` via `secretKeyRef` dedie | si Secret absent, env absente | OK, optional true documente |
| `k8s/monitoring-alerts/configmap-state.yaml` | ConfigMap state vide pour debounce futur | aucun contenu sensible | OK |
| `k8s/tests/ph2134-llm-provider-credit-watcher-secret-config-tests.sh` | test source config PH-21.34 | aucun runtime secret lu | OK |

## Pourquoi Option B+C reste retenue

| option | resultat | decision |
| --- | --- | --- |
| Reutiliser `AD_SPEND_SYNC_INTERNAL_TOKEN` | token non dedie, scope lie a un autre workflow, Secret namespaced API DEV | non retenu |
| Secret dedie watcher + API DEV | scope clair, header dedie, env prioritaire API | retenu |
| ExternalSecret/Vault | pattern existant et store valide | retenu |

## ExternalSecrets ajoutes

| namespace | ExternalSecret | target Secret | key | store | remoteRef non sensible |
| --- | --- | --- | --- | --- | --- |
| `keybuzz-api-dev` | `monitoring-llm-provider-credit-token` | `monitoring-llm-provider-credit-token` | `token` | `vault-backend` | `secret/keybuzz/llm_provider_credit/dev/monitor_token`, property `value` |
| `vault-management` | `monitoring-llm-provider-credit-token` | `monitoring-llm-provider-credit-token` | `token` | `vault-backend` | meme source logique |

## API DEV env patch

| env var | source | optional | justification |
| --- | --- | --- | --- |
| `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | `secretKeyRef` `monitoring-llm-provider-credit-token/token` | `true` | boot-safe tant que PH-21.35 n'a pas materialise/synchronise le Secret |

Choix `optional: true`: volontaire et temporaire. Il evite un crash API DEV si un apply futur est
fait avant synchronisation du Secret. Quand PH-21.35 puis PH-21.36 auront materialise et applique
la configuration, le pod API devra etre cree apres presence du Secret pour charger l'env.

## monitoring-alerts

| point | etat source | decision |
| --- | --- | --- |
| `LLM_PROVIDER_CREDIT_TOKEN` | deja en `secretKeyRef` `monitoring-llm-provider-credit-token/token`, optional true | conserve |
| dry-run | `true` | conserve |
| log-only | `true` | conserve |
| target env | `dev` | conserve |
| Slack/email activation LLM provider credit | aucune activation | conserve |

## ConfigMap state

Un manifest source vide `k8s/monitoring-alerts/configmap-state.yaml` a ete ajoute. Raison:
le watcher maintient son debounce via `monitoring-alert-state`. Fournir l'objet en source
evite de dependre d'une creation runtime future et laisse le script faire uniquement les
patchs de timestamp quand l'activation sortira de dry-run. Le ConfigMap ne contient aucune
donnee sensible.

## Tests et validations

| test | attendu | resultat | verdict |
| --- | --- | --- | --- |
| `sh k8s/tests/ph2134-llm-provider-credit-watcher-secret-config-tests.sh` | manifests dedies, env API, watcher, no PROD | `PH21.34 manifest tests PASS` | PASS |
| `sh k8s/tests/ph2128-monitoring-alerts-tests.sh` | watcher source non regresse | `PH21.28 monitoring-alerts tests PASS` | PASS |
| YAML parse | manifests modifies parsables | `YAML_PARSE_PASS` | PASS |
| `git diff --check` | aucune erreur whitespace | OK | PASS |
| `kubectl apply --dry-run=client` | non mutateur | ExternalSecrets/ConfigMap/Deployment acceptes en dry-run | PASS |
| `kubectl apply --dry-run=server` | non mutateur | ExternalSecrets/ConfigMap/Deployment acceptes en server dry-run | PASS |
| PROD diff check | aucun fichier PROD modifie | OK | PASS |

## No fake metrics / no fake events

| interdit | statut |
| --- | --- |
| fake `ai_usage` | non effectue |
| fake `PROVIDER_CREDIT_EXHAUSTED` | non effectue |
| appel LLM | non effectue |
| endpoint authentifie | non appele |
| trigger CronJob | non effectue |
| Slack/email | non effectue |
| DB mutation | non effectuee |
| event tracking | non effectue |

## AI feature parity / anti-regression

| Feature | Source de verite | Impact PH-21.34 | Risque | Verdict |
| --- | --- | --- | --- | --- |
| AI Assist | PH-21.31/21.32 marker audit | aucun changement source/runtime API | aucun | OK |
| Autopilot | PH-21.31/21.32 marker audit | aucun changement | aucun | OK |
| Returns Analysis | PH-21.31/21.32 marker audit | aucun changement | aucun | OK |
| KBActions | PH-21.32 counters delta 0 | aucun debit | aucun | OK |
| Signal provider credit | PH-21.28 endpoint | env dedie preparee | Secret absent jusqu'a PH-21.35 | dette normale |
| Logs watcher | PH-21.28 response safe | dry-run/log-only conserve | valeur non materialisee | OK |

## Non-regression read-only

| surface | attendu | observe | verdict |
| --- | --- | --- | --- |
| API DEV runtime | image v3.5.263 inchangee | conforme | OK |
| API PROD runtime | image v3.5.262 inchangee | conforme | OK |
| monitoring-alerts runtime | pas de changement runtime | conforme | OK |
| Secret runtime | non cree par CE | absent metadata-only | OK |
| DB | aucune mutation | non touchee | OK |
| LLM | aucun appel | non touche | OK |
| tracking | aucun event | non touche | OK |
| Client/Backend/Admin/Website | aucun fichier modifie | conforme | OK |
| PROD manifests | aucun fichier PROD modifie | conforme | OK |

## Commits locaux

| commit | type | message | push |
| --- | --- | --- | --- |
| `9632411` | source/config | `feat(monitoring): wire LLM provider credit watcher secret config dev (PH-21.34, KEY-337)` | non |
| rapport PH-21.34 | docs | `docs(ai): PH-21.34 source config LLM provider credit watcher secret dev (KEY-337)` | non |

## Rollback source

Rollback source futur si demande explicite:

1. Revert du commit source/config `9632411`.
2. Revert du commit docs PH-21.34 si necessaire.
3. Pas de suppression runtime ici, car aucun apply n'a ete fait en PH-21.34.
4. Si une phase future a applique les manifests, rollback GitOps strict par revert + push + apply
   explicite, jamais par commande imperative.

## Prochaine sequence GO

Prochaine phase attendue:

`GO PUSH SOURCE CONFIG PATCH LLM PROVIDER CREDIT WATCHER SECRET DEV PH-SAAS-T8.12AS.21.34`

Phases suivantes apres push source/config:

1. PH-21.35 materialisation secret DEV dans secret manager, sans valeur dans chat/logs.
2. PH-21.36 apply GitOps DEV ExternalSecrets/API si GO explicite.
3. PH-21.37 verify endpoint authentifie DEV sans afficher le token.
4. PH-21.38 activation watcher DEV dry-run/log-only.
5. PH-21.39 verify watcher DEV no side-effect.

## Gaps et dettes

| dette | impact | prochaine action |
| --- | --- | --- |
| Valeur non materialisee | ExternalSecret ne synchronisera pas tant que la source secret manager manque | PH-21.35 |
| Aucun push | source config non encore partagee remote | PH-21.34 PUSH |
| Aucun apply | runtime inchange | PH-21.36 |
| Endpoint authentifie non teste | normal tant que Secret absent | PH-21.37 |
| Watcher non actif runtime | normal tant que monitoring-alerts non applique | PH-21.38 |

## Texte Linear prepare, non poste

PH-21.34 a prepare la source GitOps DEV du secret dedie du watcher LLM provider credit. Deux
ExternalSecrets source-only materialiseront `monitoring-llm-provider-credit-token/token` dans
`keybuzz-api-dev` et `vault-management` via `vault-backend`; l'API DEV reference maintenant
`LLM_PROVIDER_CREDIT_MONITOR_TOKEN` via ce Secret dedie avec `optional: true`; monitoring-alerts
conserve son secretRef optionnel et dry-run/log-only. Un ConfigMap state vide est ajoute pour
le debounce futur. Tests source, YAML parse, diff-check et dry-runs client/server passent.
Aucun push, build, deploy, apply reel, DB, LLM, event, alert, Secret runtime ou token affiche.

## Retour CE

```text
C:\DEV\KeyBuzz\tmp\PH-21.34_CE_RETURN.md
```

STOP.
