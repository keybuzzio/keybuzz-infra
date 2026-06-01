# PH-SAAS-T8.12AS.21.28 - Source patch LLM provider credit watcher DEV

## Verdict

GO SOURCE PATCH LLM PROVIDER CREDIT WATCHER DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.28

Patch source DEV complet:

- endpoint API interne ajoute: `GET /internal/monitoring/llm-provider-credit?windowSeconds=900`;
- watcher source ajoute dans `monitoring-alerts`;
- debounce source via ConfigMap `monitoring-alert-state`;
- mode `dry-run/log-only` par defaut;
- tests API et infra OK;
- commits locaux uniquement;
- aucun push, build, deploy, DB mutation, LLM call, fake event, trigger alert ou Linear.

Verdict `READY_WITH_DEBTS` car l'activation runtime future devra materialiser le secret `monitoring-llm-provider-credit-token` dans `vault-management` avec une valeur correspondant a un token interne accepte par l'API. En PH-21.28, le secret est reference en `optional: true` et aucun secret reel n'a ete lu ni cree.

Prochaine phrase GO recommandee:

`GO PUSH SOURCE PATCH LLM PROVIDER CREDIT WATCHER DEV PH-SAAS-T8.12AS.21.28`

## Sources relues

| source | statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.28_CE_MISSION.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.27_CE_RETURN.md` | relu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.27-READONLY-DESIGN-LLM-PROVIDER-CREDIT-WATCHER-DEV-PROD-01.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.26_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.17_CE_RETURN.md` | relu |
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| `keybuzz-api` routes internes et auth token patterns | audite |
| `keybuzz-api` `ai_usage` queries et `litellm.service.ts` | audite |
| `keybuzz-infra` `monitoring-alerts` ConfigMap/CronJob/RBAC | audite |

## Preflight

| check | resultat | verdict |
| --- | --- | --- |
| bastion | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` presente | OK |
| IPv4 interdite | `51.159.99.247` absente | OK |
| UTC observe | `2026-06-01T15:05:10Z` | OK |

| repo | branche | HEAD avant | origin avant | dirty avant | verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-api | `ph147.4/source-of-truth` | `fee1a1a6` | `fee1a1a6` | suppressions `dist/` preexistantes | OK, non touchees |
| keybuzz-infra | `main` | `b452fbf` | `b452fbf` | 0 | OK |

## Design implemente

### API

Endpoint ajoute:

`GET /internal/monitoring/llm-provider-credit?windowSeconds=900`

Implementation:

- route interne enregistree sous `/internal`;
- auth obligatoire par token interne;
- headers acceptes: `X-KeyBuzz-Monitor-Token`, fallback `X-Internal-Token`, fallback `Authorization: Bearer`;
- tokens attendus par priorite env: `LLM_PROVIDER_CREDIT_MONITOR_TOKEN`, `KEYBUZZ_MONITORING_INTERNAL_TOKEN`, `KEYBUZZ_INTERNAL_PROXY_TOKEN`, `AD_SPEND_SYNC_INTERNAL_TOKEN`;
- comparaison `timingSafeEqual`;
- si token absent ou faux: `403 FORBIDDEN_INTERNAL_MONITORING`;
- source DB: `ai_usage`;
- filtre principal: `status='error'` et `error_code='PROVIDER_CREDIT_EXHAUSTED'`;
- contexte separe: `requestFailedCount` sur `error_code='REQUEST_FAILED'`;
- `windowSeconds` borne entre `60` et `86400`, defaut `900`;
- agregats safe uniquement par provider/model et feature.

Response safe:

- `ok`;
- `env`;
- `windowSeconds`;
- `count`;
- `firstSeen`;
- `lastSeen`;
- `distinctTenantCount`;
- `requestFailedCount`;
- `providerModelCounts`;
- `featureCounts`.

Non retournes:

- prompt;
- message client;
- request raw body;
- provider raw body;
- token/API key/webhook/DSN;
- provider balance;
- cout LLM brut client;
- tenant ids et request ids.

### Infra

`monitoring-alerts` etendu avec:

- `check_llm_provider_credit`;
- URLs DEV/PROD explicites;
- windows DEV/PROD: `3600s` / `900s`;
- thresholds DEV/PROD: `1` / `1`;
- debounce DEV/PROD: `21600s` / `3600s`;
- cible source patch: `LLM_PROVIDER_CREDIT_TARGET_ENV=dev`;
- `LLM_PROVIDER_CREDIT_DRY_RUN=true`;
- `LLM_PROVIDER_CREDIT_LOG_ONLY=true`;
- token optionnel via Secret `monitoring-llm-provider-credit-token`, key `token`;
- state ConfigMap: `monitoring-alert-state` en namespace `vault-management`;
- cle de debounce par `env/provider/model`, fallback aggregate;
- self-test local `MONITORING_ALERTS_SELF_TEST=llm-provider-credit`;
- fixtures JSON locales, sans reseau ni alerte reelle.

Le script n'envoie pas d'alerte LLM provider credit tant que `dry-run` ou `log-only` reste vrai. En PH-21.28, aucun CronJob n'a ete lance.

## Fichiers modifies

| repo | fichier | changement | risque | verdict |
| --- | --- | --- | --- | --- |
| keybuzz-api | `src/app.ts` | enregistrement route interne monitoring | faible | OK |
| keybuzz-api | `src/modules/internal/monitoring-routes.ts` | route interne authentifiee | faible | OK |
| keybuzz-api | `src/services/llm-provider-credit-monitoring.ts` | helper/query/agregats safe | moyen | teste |
| keybuzz-api | `src/tests/ph2128-llm-provider-credit-monitoring-tests.ts` | tests unitaires purs | faible | OK |
| keybuzz-infra | `k8s/monitoring-alerts/configmap-script.yaml` | watcher + debounce + self-test | moyen | teste |
| keybuzz-infra | `k8s/monitoring-alerts/cronjob.yaml` | env DEV-first dry-run/log-only | faible | OK |
| keybuzz-infra | `k8s/tests/ph2128-monitoring-alerts-tests.sh` | test offline du script | faible | OK |

## Commits locaux

| repo | branche | commit | message |
| --- | --- | --- | --- |
| keybuzz-api | `ph147.4/source-of-truth` | `76483e3a` | `feat(ai): add internal LLM provider credit monitoring endpoint (PH-21.28, KEY-337)` |
| keybuzz-infra | `main` | `00a2958` | `feat(monitoring): add LLM provider credit watcher source (PH-21.28, KEY-337)` |

Le commit docs de ce rapport est separe et local uniquement.

## Tests

| test | resultat | verdict |
| --- | --- | --- |
| API standalone compile + test `ph2128-llm-provider-credit-monitoring-tests` | PASS | OK |
| API `./node_modules/.bin/tsc --noEmit` | PASS | OK |
| API `git diff --check` cible | PASS | OK |
| Infra `sh k8s/tests/ph2128-monitoring-alerts-tests.sh` | PASS | OK |
| Infra YAML parse via Python/PyYAML | PASS | OK |
| Infra `git diff --check` cible | PASS | OK |

Test API couvre:

- `windowSeconds` default/min/max;
- count 0;
- count > 0 avec fixtures;
- `requestFailedCount` separe;
- provider/model/feature aggregates;
- absence de champs sensibles dans la reponse;
- auth interne requise.

Test infra couvre:

- extraction du script depuis le ConfigMap;
- `sh -n`;
- fixture count 0;
- fixture count 1 en dry-run/log-only;
- debounce offline via state file;
- presence des env vars et du header interne;
- aucune alerte Slack/email reelle.

## Non-regression

| surface | statut |
| --- | --- |
| AI Assist | non modifie |
| Autopilot | non modifie |
| Returns Analysis | non modifie |
| KBActions | non modifie |
| no-reply skip | non modifie |
| Client UI | non modifie |
| Backend | non modifie |
| Admin | non modifie |
| Website | non modifie |
| Amazon outbound | non modifie |
| CAPI/tracking | non modifie |
| DB schema/data | non modifie |
| Kubernetes runtime | non modifie |

## Side effects interdits verifies

| interdit | statut |
| --- | --- |
| push Git | non effectue |
| build Docker | non effectue |
| docker push | non effectue |
| deploy GitOps / `kubectl apply` | non effectue |
| `kubectl set image/env/patch/edit` | non effectue |
| DB mutation/migration | non effectue |
| LLM call | non effectue |
| fake `ai_usage` | non effectue |
| fake event/metric/tracking | non effectue |
| trigger CronJob | non effectue |
| envoi Slack/email | non effectue |
| Linear | non effectue |
| secret brut lu ou affiche | non effectue |

## Limites et dettes

| dette | impact | recommandation |
| --- | --- | --- |
| Secret watcher `monitoring-llm-provider-credit-token` absent/non materialise | le watcher source saute l'appel runtime si token absent | phase suivante doit pousser source puis preparer activation DEV avec secret aligne au token interne API, sans log de secret |
| `monitoring-alerts` existant envoie deja des emails repetes pour worker restarts | dette SRE preexistante | patch dedie debounce global hors PH-21.28 |
| Alertmanager non utilise par ce chemin direct email | architecture monitoring heterogene | dette SRE separee |
| Aucun incident naturel `PROVIDER_CREDIT_EXHAUSTED` observe | live alert non prouve sans fake event | observer un vrai incident naturel plus tard |

## Texte Linear prepare, non poste

PH-21.28 a ajoute le patch source du watcher LLM provider credit. Cote API, un endpoint interne authentifie `GET /internal/monitoring/llm-provider-credit` expose uniquement des agregats safe issus de `ai_usage.error_code='PROVIDER_CREDIT_EXHAUSTED'`, avec tests et `tsc --noEmit` OK. Cote infra, `monitoring-alerts` sait appeler l'endpoint en mode DEV-first `dry-run/log-only`, avec debounce via state ConfigMap `monitoring-alert-state` et tests offline OK. Aucun push, build, deploy, DB mutation, LLM call, fake event, trigger alert ou Linear n'a ete effectue. Dette restante: materialiser le secret watcher runtime avant activation reelle.

## Next GO

`GO PUSH SOURCE PATCH LLM PROVIDER CREDIT WATCHER DEV PH-SAAS-T8.12AS.21.28`

STOP.
