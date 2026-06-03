# PH-SAAS-T8.12AS.21.40 - Apply Monitoring-Alerts Email Delivery Safety DEV

## RESUME LUDOVIC

RESUME LUDOVIC - TERMINAL

1. Verdict: GO APPLY MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.40.
2. Manifests appliques: configmap-script.yaml puis cronjob.yaml, via kubectl apply -f uniquement.
3. Runtime log-only confirme: MONITORING_ALERTS_LOG_ONLY=true, ALERT_DELIVERY_MODE=log-only, LLM dry-run/log-only conserve.
4. Run naturel post-apply: observe.
5. Email/Webhook post-apply: Email OK=0, Webhook OK=0, log-only markers=0.
6. Deltas DB/LLM/tracking: snapshots read-only avant/apres, aucun LLM call, aucune DB mutation, aucun fake event.
7. PROD intacte: lecture seule seulement, aucun manifest PROD applique.
8. Rapport docs: commit/push docs-only execute dans keybuzz-infra.
9. Retour complet: C:\DEV\KeyBuzz\tmp\PH-21.40_CE_RETURN.md.
10. Prochain GO recommande: GO READONLY VERIFY MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV PH-SAAS-T8.12AS.21.41.

STOP.

## Verdict

GO APPLY MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.40

## Objectif

Appliquer en DEV uniquement les manifests monitoring-alerts corriges par PH-21.39 afin de rendre effectif le garde-fou global log-only et empecher les deliveries SMTP/webhook pendant que le watcher LLM provider credit reste dry-run/log-only.

Hors scope respecte: aucun build, aucun docker push, aucune mutation DB, aucun LLM call, aucun fake event, aucun trigger manuel CronJob, aucun Linear, aucun PROD.

## Sources relues

| Source | Statut |
| --- | --- |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relus localement avant execution |
| Modele PH-T8.10J | relu localement |
| PH-21.38 / PH-21.38-BIS / PH-21.39 / PH-21.39 PUSH returns | relus localement |
| Rapports distants PH-21.38 / 21.38-BIS / 21.39 | relus sur bastion, extraits captures |
| Manifests monitoring-alerts et tests PH-21.28/21.34/21.39 | audites et testes |

Extraits de relecture distante:

```text
### docs/PH-SAAS-T8.12AS.21.38-APPLY-LLM-PROVIDER-CREDIT-WATCHER-DRY-RUN-DEV-01.md
# PH-SAAS-T8.12AS.21.38 - Apply LLM Provider Credit Watcher Dry Run DEV

## Verdict

GO APPLY LLM PROVIDER CREDIT WATCHER DRY RUN DEV ACTION_REQUIRED_ALERT_RISK PH-SAAS-T8.12AS.21.38

## Objectif

Apply GitOps DEV uniquement du watcher monitoring-alerts LLM provider credit en mode dry-run/log-only. Aucun build, docker push, deploy API, DB mutation, LLM call, fake event, Slack/email/webhook, Linear ou PROD.

## Sources relues

| Source | Statut |
| --- | --- |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relu localement |
| Modele PH-T8.10J | relu selon standard CE |
| PH-21.28 / PH-21.34 / PH-21.35-BIS / PH-21.35-TER / PH-21.36 / PH-21.37 returns | relus |
| Rapports distants PH-21.28 / 21.34 / 21.36 / 21.37 | relus |
| Manifests monitoring-alerts et tests PH-21.28/21.34 | audites |

## Preflight

| Point | Observe | Verdict |
| --- | --- | --- |
| Bastion | install-v3 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 2026-06-03T09:13:46Z  | OK |
| Kube context | kubernetes-admin@kubernetes | OK |

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 70dd1cc102d8 | 70dd1cc102d8 | 0/0 | 1 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a0e10 | 76483e3a0e10 | read-only | 223 preexisting dist deletions | OK |

## Phase lineage

| Phase | Fait prouve | Commit/Image/Digest | Impact PH-21.38 |
| --- | --- | --- | --- |
| PH-21.28 | Endpoint et watcher source ajoutes | API 76483e3a, Infra 00a2958 | source LLM watcher |
| PH-21.34 | Secret source/config prepare et pousse | Infra 41f963b | secretRef dedie |
| PH-21.36 | ExternalSecrets + API env appliques | API DEV digest sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 | token synchronise metadata-only |
| PH-21.37 | Endpoint authentifie 200, response safe | Infra docs 70dd1cc1 | watcher peut appeler API DEV |

## Tests

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.28 monitoring-alerts tests | PASS | PH21.28 monitoring-alerts tests PASS | PASS |
| PH-21.34 manifest tests | PASS | PH21.34 manifest tests PASS | PASS |
| YAML parse monitoring-alerts | PASS | YAML_PARSE=PASS | PASS |
| git diff --check cible | PASS | DIFF_CHECK=PASS | PASS |
| dry-run client/server | non execute | stop pre-apply apres detection SMTP/email active | ACTION_REQUIRED_ALERT_RISK |

## Manifest Audit

| Fichier | Marker/setting | Attendu | Observe | Verdict |
| --- | --- | --- | --- | --- |
 |  | configmap-script.yaml | check_llm_provider_credit | present | present | OK |
 |  | configmap-script.yaml | self-test marker | present | present | OK |
 |  | configmap-script.yaml | monitor header | present | present | OK |
 |  | configmap-script.yaml | LLM dry/log-only return before add_alert | present | present | OK |
 |  | cronjob.yaml | target env | dev | dev | OK |
 |  | cronjob.yaml | dry run | true | true | OK |
 |  | cronjob.yaml | log only | true | true | OK |
 |  | cronjob.yaml | DEV URL | keybuzz-api-dev | http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/internal/monitoring/llm-provider-credit | OK |
 |  | cronjob.yaml | DEV window seconds | 3600 | 3600 | OK |
 |  | cronjob.yaml | DEV threshold | 1 | 1 | OK |
 |  | cronjob.yaml | DEV debounce seconds | 21600 | 21600 | OK |
 |  | cronjob.yaml | token secretRef | monitoring-llm-provider-credit-token/token | monitoring-llm-provider-credit-token/token optional=true | OK |
| configmap-script.yaml | alert delivery global | LLM path must return before add_alert | Existing non-LLM deliver_alerts remains a documented SRE debt; LLM path log-only returns | OK_WITH_DEBT |

## Manifests appliques

| Manifest | Action | Sortie |
| --- | --- | --- |
| k8s/monitoring-alerts/configmap-state.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |
| k8s/monitoring-alerts/configmap-script.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |
| k8s/monitoring-alerts/cronjob.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |

## Dry-run Kubernetes

'''text
### docs/PH-SAAS-T8.12AS.21.38-BIS-READONLY-DESIGN-MONITORING-ALERTS-EMAIL-DELIVERY-SAFETY-DEV-01.md
# PH-SAAS-T8.12AS.21.38-BIS - Readonly Design Monitoring-Alerts Email Delivery Safety DEV

## Verdict

GO READONLY DESIGN MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV CRITICAL_FINDING PH-SAAS-T8.12AS.21.38-BIS

## Objectif

RCA/design du blocage PH-21.38. Cette correction documente aussi un incident CE survenu pendant PH-21.38-BIS: deux commandes kubectl apply presentes dans une phrase Markdown ont ete interpretees par le shell pendant la generation du rapport initial. Aucun rollback runtime n'a ete tente sans GO explicite.

## Sources relues

| Source | Statut |
| --- | --- |
| Mission PH-21.38-BIS | relue |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relus |
| Modele PH-T8.10J | relu localement |
| Retours PH-21.28, PH-21.34 PUSH, PH-21.36, PH-21.37, PH-21.38 | relus |
| Rapport PH-21.38-BIS initial commit 8f667a28 | relu et corrige |

## Preflight

| Point | Observe | Verdict |
| --- | --- | --- |
| Bastion | install-v3 / 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 | OK |
| UTC | 2026-06-03T14:05:14Z | OK |
| Kube context | kubernetes-admin@kubernetes | OK |

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 8f667a28f9f2 | 8f667a28f9f2 | 0/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a0e10 | 76483e3a0e10 | read-only | 223 preexisting dist deletions | OK |

## Reconstitution PH-21.38

| Job | Heure UTC | Alert count | Email marker | Slack/webhook marker | Source naturelle | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| monitoring-alerts-29674920 | 2026-06-03T14:00:00Z | 2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |
| monitoring-alerts-29674922 | 2026-06-03T14:02:00Z | 2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |
| monitoring-alerts-29674924 | 2026-06-03T14:04:00Z | 2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |

PH-21.38 avait deja prouve les jobs 29674628/29674630/29674632 a 09:08/09:10/09:12 UTC avec Sending 2 alerts puis Email OK. Aucun trigger manuel n'a ete cree en PH-21.38-BIS.

## Checks qui envoient les emails

| Check | Condition | Valeur observee | Seuil | Debounce present | Pourquoi email envoye |
| --- | --- | --- | --- | --- | --- |
| worker-restart | restart count >= RESTART_THRESHOLD | amazon-orders-worker crash loop (6x) | RESTART_THRESHOLD=3 | absent globalement | deliver_alerts envoie car ALERT_COUNT>0 et SMTP_HOST present |

## Cartographie email/Slack/webhook

| Channel | Arme runtime | Source env/secret | Valeur masquee | Utilise par deliver_alerts | Risque |
| --- | --- | --- | --- | --- | --- |
| Email SMTP | yes | env SMTP_HOST/SMTP_TO | SMTP_TO present_masked count=1 | yes | high: Email OK observe |
| Slack/Webhook | yes if secret non-empty | WEBHOOK_URL secretRef/env | secretRef name=monitoring-webhook key=url optional=true | yes if non-empty | current logs: webhook_ok=0 |
| LLM provider token | yes | secretRef | secretRef name=monitoring-llm-provider-credit-token key=token optional=true | only LLM endpoint call | no value read |

## Source Git vs runtime live

| Objet | Source Git | Runtime live | Drift | Impact |
| --- | --- | --- | --- | --- |
| check_llm_provider_credit | true | true | runtime changed by incident | now live after accidental apply |
| LLM_PROVIDER_CREDIT_DRY_RUN | true | true | runtime changed by incident | LLM path remains dry-run |
| LLM_PROVIDER_CREDIT_LOG_ONLY | true | true | runtime changed by incident | LLM path remains log-only |
| LLM_PROVIDER_CREDIT_TARGET_ENV | dev | dev | runtime changed by incident | target DEV |
| deliver_alerts | true | true | no | global email delivery remains active |
| global_log_only_guard | false | false | no | missing guard remains the risk |
| SMTP_TO | present masked | present_masked count=1 | no | email can send when ALERT_COUNT>0 |
| WEBHOOK_URL | secretRef optional | secretRef name=monitoring-webhook key=url optional=true | no | webhook armed only if secret has value |

## Incident CE PH-21.38-BIS

| Commande involontaire | Cause | Effet observe | Statut |
| --- | --- | --- | --- |
| kubectl apply -f k8s/monitoring-alerts/configmap-script.yaml | backticks Markdown interpretes dans here-doc shell | ConfigMap live contient maintenant check_llm_provider_credit | CRITICAL_FINDING |
| kubectl apply -f k8s/monitoring-alerts/cronjob.yaml | backticks Markdown interpretes dans here-doc shell | CronJob live contient maintenant LLM_PROVIDER_CREDIT_* dry-run/log-only | CRITICAL_FINDING |
| rollback | non execute | mutation supplementaire interdite sans GO explicite | pending decision |

## Debounce / spam prevention

### docs/PH-SAAS-T8.12AS.21.39-SOURCE-CONFIG-PATCH-MONITORING-ALERTS-EMAIL-DELIVERY-SAFETY-DEV-01.md
# PH-SAAS-T8.12AS.21.39 - Source Config Patch Monitoring-Alerts Email Delivery Safety DEV

## Verdict

GO SOURCE CONFIG PATCH MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.39

## Objectif

Patch source/config DEV uniquement pour ajouter un garde-fou global log-only dans monitoring-alerts. Aucun push, aucun apply runtime reel, aucun trigger CronJob, aucun Slack/email/webhook volontaire, aucun secret lu, aucun build, aucune DB mutation, aucun LLM call, aucun fake event, aucun Linear, aucun PROD.

## Sources relues

| Source | Statut |
| --- | --- |
| Mission PH-21.39 | relue |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relus |
| Modele PH-T8.10J | relu |
| PH-21.28 / PH-21.36 / PH-21.37 / PH-21.38 / PH-21.38-BIS returns | relus |
| Rapport PH-21.38-BIS CRITICAL_FINDING 32026681 | relu |
| Manifests et tests monitoring-alerts | audites |

## Preflight

| Point | Observe | Verdict |
| --- | --- | --- |
| Bastion | install-v3 / 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 | OK |
| UTC | 2026-06-03T14:46:36Z | OK |
| Kube context | kubernetes-admin@kubernetes | OK |

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 583a7ad1a26d | 320266818400 | 1/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a0e10 | 76483e3a0e10 | 0/0 | 223 preexisting dist deletions | OK |

## Rappel PH-21.38-BIS / incident

| Fait PH-21.38-BIS | Impact PH-21.39 |
| --- | --- |
| deliver_alerts global envoie SMTP quand ALERT_COUNT>0 | ajouter un guard global log-only avant webhook/email |
| worker-restart amazon-orders-worker crash loop 6x | source de spam naturel, pas un signal LLM |
| email SMTP arme, webhook SecretRef mais aucun Webhook OK observe | couper les deliveries DEV via log-only, sans lire secret |
| incident CE: ConfigMap script et CronJob appliques involontairement | ne pas rollback ici; patch source uniquement |
| watcher LLM runtime deja live en dry-run/log-only depuis incident | conserver LLM_PROVIDER_CREDIT_DRY_RUN=true et LOG_ONLY=true |

## Patch source/config

| Fichier | Changement | Pourquoi | Risque |
| --- | --- | --- | --- |
| k8s/monitoring-alerts/configmap-script.yaml | ajoute MONITORING_ALERTS_LOG_ONLY, ALERT_DELIVERY_MODE, guard dans deliver_alerts, self-test delivery-safety | empecher SMTP/webhook en mode log-only | erreur shell, couverte par tests |
| k8s/monitoring-alerts/cronjob.yaml | ajoute MONITORING_ALERTS_LOG_ONLY=true et ALERT_DELIVERY_MODE=log-only | activer le garde-fou DEV explicitement | alertes DEV masquees volontairement |
| k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh | test offline ALERT_COUNT>0 log-only | prouver absence Email OK/Webhook OK | coverage limite au self-test |

Fichiers du commit source:

'''text
k8s/monitoring-alerts/configmap-script.yaml
k8s/monitoring-alerts/cronjob.yaml
k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh
'''

## Tests

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.28 monitoring-alerts | PASS | PH21.28 monitoring-alerts tests PASS | PASS |
| PH-21.34 secret config | PASS | PH21.34 manifest tests PASS | PASS |
| PH-21.39 delivery safety | PASS | PH21.39 monitoring-alerts delivery safety tests PASS | PASS |
| YAML parse | PASS | YAML_PARSE=PASS | PASS |
| git diff --check cible | PASS | DIFF_CHECK=PASS | PASS |
| kubectl dry-run client/server | PASS | voir sorties ci-dessous | PASS |

Dry-run outputs, aucun apply reel:

'''text
configmap/monitoring-alert-script configured (dry run)
cronjob.batch/monitoring-alerts configured (dry run)
configmap/monitoring-alert-state configured (dry run)
configmap/monitoring-alert-script configured (server dry run)
cronjob.batch/monitoring-alerts configured (server dry run)
configmap/monitoring-alert-state configured (server dry run)
```

## Preflight

| Point | Resultat |
| --- | --- |
| Bastion | install-v3 |
| IPs | 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 |
| UTC | 2026-06-03T15:07:51Z |
| Kube context | kubernetes-admin@kubernetes |

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 27c25d65 | 27c25d65 | 0/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a | 76483e3a | read-only | 223 preexisting | OK |

## Source poussee PH-21.39

| Commit | Fichiers | Verification |
| --- | --- | --- |
| 583a7ad1 | configmap-script.yaml, cronjob.yaml, test PH-21.39 | present dans HEAD, guard global log-only present |
| 27c25d65 | rapport docs PH-21.39 | present dans HEAD/origin |

```text
COMMIT_583A7AD1
583a7ad fix(monitoring): add log-only alert delivery safety (PH-21.39, KEY-337)

k8s/monitoring-alerts/configmap-script.yaml
k8s/monitoring-alerts/cronjob.yaml
k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh
COMMIT_27C25D65
27c25d6 docs(ai): PH-21.39 source config monitoring alerts delivery safety dev (KEY-337)

docs/PH-SAAS-T8.12AS.21.39-SOURCE-CONFIG-PATCH-MONITORING-ALERTS-EMAIL-DELIVERY-SAFETY-DEV-01.md
SOURCE_GUARD_MARKERS
21:    MONITORING_ALERTS_LOG_ONLY="${MONITORING_ALERTS_LOG_ONLY:-false}"
22:    ALERT_DELIVERY_MODE="${ALERT_DELIVERY_MODE:-send}"
409:      if is_true "$MONITORING_ALERTS_LOG_ONLY" || [ "${ALERT_DELIVERY_MODE:-send}" = "log-only" ]; then
410:        log "Alert delivery log-only: suppressed delivery for ${ALERT_COUNT} alert(s)"
CRON_ENV_MARKERS
45:                - name: MONITORING_ALERTS_LOG_ONLY
47:                - name: ALERT_DELIVERY_MODE
51:                - name: LLM_PROVIDER_CREDIT_TARGET_ENV
53:                - name: LLM_PROVIDER_CREDIT_DRY_RUN
55:                - name: LLM_PROVIDER_CREDIT_LOG_ONLY
```

## Tests avant apply

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.28 monitoring-alerts | PASS | PH21.28 monitoring-alerts tests PASS | PASS |
| PH-21.34 secret config | PASS | PH21.34 manifest tests PASS | PASS |
| PH-21.39 delivery safety | PASS | PH21.39 monitoring-alerts delivery safety tests PASS | PASS |
| YAML parse | PASS | YAML_PARSE_OK k8s/monitoring-alerts/configmap-script.yaml / YAML_PARSE_OK k8s/monitoring-alerts/cronjob.yaml | PASS |
| git diff --check | PASS | no_output | PASS |
| dry-run client configmap | PASS | configmap/monitoring-alert-script configured (dry run) | PASS |
| dry-run client cronjob | PASS | cronjob.batch/monitoring-alerts configured (dry run) | PASS |
| dry-run server configmap | PASS | configmap/monitoring-alert-script configured (server dry run) | PASS |
| dry-run server cronjob | PASS | cronjob.batch/monitoring-alerts configured (server dry run) | PASS |

## Snapshot before

| Signal | Before | Commentaire |
| --- | --- | --- |
| CronJob monitoring-alerts | NAME=monitoring-alerts / IMAGE=curlimages/curl:8.7.1 / SCHEDULE=*/2 * * * * | details ci-dessous |
| ConfigMap script | guard=false, LLM=true | read-only |
| Jobs naturels recents | Email OK=3, Webhook OK=0, log-only=0 | avant apply |
| API DEV pod | POD=keybuzz-api-77cd59c478-jd994 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 / RESTARTS=0 | read-only |
| API PROD pod | POD=keybuzz-api-79b698d9b9-6cqx8 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 / RESTARTS=0 | read-only |
| DB counters DEV | DB_SNAPSHOT=SKIPPED_NO_DATABASE_URL | read-only |

Cron before:

```text
NAME=monitoring-alerts
IMAGE=curlimages/curl:8.7.1
SCHEDULE=*/2 * * * *
SUSPEND=False
GENERATION=2
LAST_SCHEDULE=
ENV_NAMES=VAULT_ADDR,ALERT_ENV,LOG_WINDOW,RESTART_THRESHOLD,ERROR_RATE_THRESHOLD,LLM_PROVIDER_CREDIT_ENABLED,LLM_PROVIDER_CREDIT_TARGET_ENV,LLM_PROVIDER_CREDIT_DRY_RUN,LLM_PROVIDER_CREDIT_LOG_ONLY,LLM_PROVIDER_CREDIT_STATE_CONFIGMAP,LLM_PROVIDER_CREDIT_STATE_NAMESPACE,LLM_PROVIDER_CREDIT_DEV_URL,LLM_PROVIDER_CREDIT_PROD_URL,LLM_PROVIDER_CREDIT_DEV_WINDOW_SECONDS,LLM_PROVIDER_CREDIT_PROD_WINDOW_SECONDS,LLM_PROVIDER_CREDIT_DEV_THRESHOLD,LLM_PROVIDER_CREDIT_PROD_THRESHOLD,LLM_PROVIDER_CREDIT_DEV_DEBOUNCE_SECONDS,LLM_PROVIDER_CREDIT_PROD_DEBOUNCE_SECONDS,LLM_PROVIDER_CREDIT_TOKEN,SMTP_HOST,SMTP_PORT,SMTP_FROM,SMTP_TO,WEBHOOK_URL
ENV_ALERT_ENV=prod
ENV_LOG_WINDOW=180
ENV_RESTART_THRESHOLD=3
ENV_LLM_PROVIDER_CREDIT_TARGET_ENV=dev
ENV_LLM_PROVIDER_CREDIT_DRY_RUN=true
ENV_LLM_PROVIDER_CREDIT_LOG_ONLY=true
ENV_LLM_PROVIDER_CREDIT_TOKEN=secretRef:monitoring-llm-provider-credit-token/token optional=True
ENV_SMTP_FROM=present_masked
ENV_SMTP_TO=present_masked
ENV_WEBHOOK_URL=secretRef:monitoring-webhook/url optional=True
ENV_ALERT_DELIVERY_MODE=<absent>
ENV_API_INTERNAL_URL=<absent>
ENV_LLM_PROVIDER_CREDIT_DEBOUNCE_SECONDS=<absent>
ENV_LLM_PROVIDER_CREDIT_THRESHOLD=<absent>
ENV_LLM_PROVIDER_CREDIT_WINDOW_SECONDS=<absent>
ENV_MONITORING_ALERTS_LOG_ONLY=<absent>
```

ConfigMap before:

```text
CM_NAME=monitoring-alert-script
CM_KEYS=monitoring-alerts.sh
HAS_CHECK_LLM_PROVIDER_CREDIT=true
HAS_DRYRUN_LOGONLY=true
HAS_GLOBAL_LOG_ONLY_GUARD=false
HAS_DELIVER_ALERTS=true
```

Logs naturels before, extraits safe:

```text
### monitoring-alerts-29674982 2026-06-03T15:02:00Z
[2026-06-03 15:02:05 UTC] CHECK 6: Autopilot errors
[2026-06-03 15:02:06 UTC]   OK (errors=0)
[2026-06-03 15:02:10 UTC] CHECK 9: LLM provider credit
[2026-06-03 15:02:11 UTC]   OK (provider_credit_count=0, request_failed=0)
[2026-06-03 15:02:12 UTC] Sending 2 alerts
[2026-06-03 15:02:12 UTC]   Email OK

### monitoring-alerts-29674984 2026-06-03T15:04:00Z
[2026-06-03 15:04:05 UTC] CHECK 6: Autopilot errors
[2026-06-03 15:04:06 UTC]   OK (errors=0)
[2026-06-03 15:04:10 UTC] CHECK 9: LLM provider credit
[2026-06-03 15:04:11 UTC]   OK (provider_credit_count=0, request_failed=0)
[2026-06-03 15:04:11 UTC] Sending 2 alerts
[2026-06-03 15:04:12 UTC]   Email OK

### monitoring-alerts-29674986 2026-06-03T15:06:00Z
[2026-06-03 15:06:05 UTC] CHECK 6: Autopilot errors
[2026-06-03 15:06:06 UTC]   OK (errors=0)
[2026-06-03 15:06:11 UTC] CHECK 9: LLM provider credit
[2026-06-03 15:06:12 UTC]   OK (provider_credit_count=0, request_failed=0)
[2026-06-03 15:06:13 UTC] Sending 2 alerts
[2026-06-03 15:06:13 UTC]   Email OK
```

DB before:

```text
DB_SNAPSHOT=SKIPPED_NO_DATABASE_URL
```

## Manifests appliques

Timestamp apply UTC: 2026-06-03T15:08:00Z

| Manifest | Commande | Sortie |
| --- | --- | --- |
| k8s/monitoring-alerts/configmap-script.yaml | kubectl apply -f | configmap/monitoring-alert-script configured |
| k8s/monitoring-alerts/cronjob.yaml | kubectl apply -f | cronjob.batch/monitoring-alerts configured |

Aucun apply de configmap-state.yaml. Aucun autre apply. Aucun trigger CronJob manuel.

## Runtime immediate after

| Runtime setting | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| MONITORING_ALERTS_LOG_ONLY | true | true | OK |
| ALERT_DELIVERY_MODE | log-only | log-only | OK |
| LLM_PROVIDER_CREDIT_TARGET_ENV | dev | dev | OK |
| LLM_PROVIDER_CREDIT_DRY_RUN | true | true | OK |
| LLM_PROVIDER_CREDIT_LOG_ONLY | true | true | OK |
| ConfigMap guard global | true | true | OK |

Cron after immediate:

```text
NAME=monitoring-alerts
IMAGE=curlimages/curl:8.7.1
SCHEDULE=*/2 * * * *
SUSPEND=False
GENERATION=3
LAST_SCHEDULE=
ENV_NAMES=VAULT_ADDR,ALERT_ENV,LOG_WINDOW,RESTART_THRESHOLD,ERROR_RATE_THRESHOLD,MONITORING_ALERTS_LOG_ONLY,ALERT_DELIVERY_MODE,LLM_PROVIDER_CREDIT_ENABLED,LLM_PROVIDER_CREDIT_TARGET_ENV,LLM_PROVIDER_CREDIT_DRY_RUN,LLM_PROVIDER_CREDIT_LOG_ONLY,LLM_PROVIDER_CREDIT_STATE_CONFIGMAP,LLM_PROVIDER_CREDIT_STATE_NAMESPACE,LLM_PROVIDER_CREDIT_DEV_URL,LLM_PROVIDER_CREDIT_PROD_URL,LLM_PROVIDER_CREDIT_DEV_WINDOW_SECONDS,LLM_PROVIDER_CREDIT_PROD_WINDOW_SECONDS,LLM_PROVIDER_CREDIT_DEV_THRESHOLD,LLM_PROVIDER_CREDIT_PROD_THRESHOLD,LLM_PROVIDER_CREDIT_DEV_DEBOUNCE_SECONDS,LLM_PROVIDER_CREDIT_PROD_DEBOUNCE_SECONDS,LLM_PROVIDER_CREDIT_TOKEN,SMTP_HOST,SMTP_PORT,SMTP_FROM,SMTP_TO,WEBHOOK_URL
ENV_ALERT_ENV=prod
ENV_LOG_WINDOW=180
ENV_RESTART_THRESHOLD=3
ENV_MONITORING_ALERTS_LOG_ONLY=true
ENV_ALERT_DELIVERY_MODE=log-only
ENV_LLM_PROVIDER_CREDIT_TARGET_ENV=dev
ENV_LLM_PROVIDER_CREDIT_DRY_RUN=true
ENV_LLM_PROVIDER_CREDIT_LOG_ONLY=true
ENV_LLM_PROVIDER_CREDIT_TOKEN=secretRef:monitoring-llm-provider-credit-token/token optional=True
ENV_SMTP_FROM=present_masked
ENV_SMTP_TO=present_masked
ENV_WEBHOOK_URL=secretRef:monitoring-webhook/url optional=True
ENV_API_INTERNAL_URL=<absent>
ENV_LLM_PROVIDER_CREDIT_DEBOUNCE_SECONDS=<absent>
ENV_LLM_PROVIDER_CREDIT_THRESHOLD=<absent>
ENV_LLM_PROVIDER_CREDIT_WINDOW_SECONDS=<absent>
```

ConfigMap after immediate:

```text
CM_NAME=monitoring-alert-script
CM_KEYS=monitoring-alerts.sh
HAS_CHECK_LLM_PROVIDER_CREDIT=true
HAS_DRYRUN_LOGONLY=true
HAS_GLOBAL_LOG_ONLY_GUARD=true
HAS_DELIVER_ALERTS=true
```

SecretRefs metadata-only:

```text
WATCHER_EXTERNALSECRET
NAME                                   STORETYPE            STORE           REFRESH INTERVAL   STATUS         READY
monitoring-llm-provider-credit-token   ClusterSecretStore   vault-backend   1h                 SecretSynced   True
WATCHER_SECRET_METADATA
NAME                                   TYPE     DATA   AGE
monitoring-llm-provider-credit-token   Opaque   1      7h45m
WEBHOOK_SECRET_METADATA
Error from server (NotFound): secrets "monitoring-webhook" not found
STATE_CONFIGMAP_METADATA
NAME                     DATA   AGE
monitoring-alert-state   0      7h45m
```

## Run naturel post-apply

| Job | Start UTC | Post-apply | Alert count | Log-only marker | Email OK | Webhook OK | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
monitoring-alerts-29674990 | 2026-06-03T15:10:00Z | yes | 0 | 0 | 0 | 0 | OK

Observation trace:

```text
2026-06-03T15:08:06Z wait_no_post_apply_job elapsed=0s
2026-06-03T15:08:21Z wait_no_post_apply_job elapsed=15s
2026-06-03T15:08:37Z wait_no_post_apply_job elapsed=31s
2026-06-03T15:08:52Z wait_no_post_apply_job elapsed=46s
2026-06-03T15:09:07Z wait_no_post_apply_job elapsed=61s
2026-06-03T15:09:22Z wait_no_post_apply_job elapsed=76s
2026-06-03T15:09:38Z wait_no_post_apply_job elapsed=92s
2026-06-03T15:09:53Z wait_no_post_apply_job elapsed=107s
```

Extraits safe post-apply:

```text
### monitoring-alerts-29674990 2026-06-03T15:10:00Z
[2026-06-03 15:10:05 UTC] CHECK 6: Autopilot errors
[2026-06-03 15:10:05 UTC]   OK (errors=0)
```

## Snapshot after / deltas

| Signal | Before | After | Delta | Verdict |
| --- | --- | --- | --- | --- |
| ai_usage | not_captured | not_captured | n/a | OK_READONLY |
| ai_actions_ledger | not_captured | not_captured | n/a | OK_READONLY |
| ai_suggestion_events | not_captured | not_captured | n/a | OK_READONLY |
| Email OK post-apply | n/a | 0 | 0 expected | OK |
| Webhook OK post-apply | n/a | 0 | 0 expected | OK |
| API DEV pod | POD=keybuzz-api-77cd59c478-jd994 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 / RESTARTS=0 | POD=keybuzz-api-77cd59c478-jd994 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 / RESTARTS=0 | read-only | OK |
| API PROD pod | POD=keybuzz-api-79b698d9b9-6cqx8 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 / RESTARTS=0 | POD=keybuzz-api-79b698d9b9-6cqx8 / IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 / RESTARTS=0 | read-only | OK |

DB after:

```text
DB_SNAPSHOT=SKIPPED_NO_DATABASE_URL
```

## No fake metrics / no fake events

| Interdit | Statut |
| --- | --- |
| fake ai_usage/provider credit | non effectue |
| fake tracking/conversion/KBActions | non effectue |
| fake email/Slack/webhook | non effectue |
| DB mutation | non effectuee |
| LLM call | non effectue |
| trigger CronJob manuel | non effectue |

## AI feature parity / anti-regression

| Surface IA | Point verifie | Source/log/runtime | Resultat |
| --- | --- | --- | --- |
| API DEV | reste v3.5.263 watcher | deployment/pod snapshot | OK |
| API PROD | reste v3.5.262 alerting | deployment/pod snapshot | OK |
| PROVIDER_CREDIT_EXHAUSTED | signal non modifie | API non modifiee, monitoring source seulement | OK |
| Endpoint watcher | non modifie | aucun build/deploy API | OK |
| Watcher LLM | DRY_RUN=true, LOG_ONLY=true | CronJob live | OK |
| KBActions/LLM | aucun appel/debit volontaire | DB snapshot read-only | OK |
| AI Assist/Autopilot/Returns Analysis | aucune source/runtime modifiee | scope monitoring-alerts only | OK |
| Inbox/Amazon inbound/outbound | aucun trigger/event | no manual job, no fake event | OK |

## Non-regression DEV/PROD

| Service | Namespace | Image/runtime | Ready | Restarts | Changement CE | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev | 1/1 | see pod if API | read-only | OK |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 | see pod if API | read-only | OK |
| keybuzz-api | keybuzz-api-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev | 1/1 | see pod if API | read-only | OK |
| keybuzz-api | keybuzz-api-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | 1/1 | see pod if API | read-only | OK |
| keybuzz-backend | keybuzz-backend-dev | ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev | 1/1 | see pod if API | read-only | OK |
| keybuzz-backend | keybuzz-backend-prod | ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod | 1/1 | see pod if API | read-only | OK |
| keybuzz-client | keybuzz-client-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | 1/1 | see pod if API | read-only | OK |
| keybuzz-client | keybuzz-client-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | 1/1 | see pod if API | read-only | OK |
| keybuzz-website | keybuzz-website-dev | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev | 1/1 | see pod if API | read-only | OK |
| keybuzz-website | keybuzz-website-prod | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod | 2/2 | see pod if API | read-only | OK |

API DEV pod after:

```text
POD=keybuzz-api-77cd59c478-jd994
IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996
RESTARTS=0
```

API PROD pod after:

```text
POD=keybuzz-api-79b698d9b9-6cqx8
IMAGE_IDS=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6
RESTARTS=0
```

## Interdits respectes

| Interdit | Statut |
| --- | --- |
| kubectl set image/env/patch/edit/replace | non effectue |
| apply hors scope | non effectue |
| configmap-state apply | non effectue |
| trigger CronJob manuel | non effectue |
| secret/token/recipient/webhook brut affiche | non effectue; outputs masques/metadata-only |
| build/docker push | non effectue |
| DB mutation/LLM call/fake event/Linear | non effectue |
| PROD mutation | non effectuee |
| heredoc non quote pour rapport | non utilise; generation rapport via Python heredoc quote |

## Rollback GitOps

Rollback interdit sans GO explicite separe. Rollback attendu si necessaire: revert ou commit correctif GitOps, push normal, puis kubectl apply -f uniquement sur configmap-script.yaml et cronjob.yaml revenus par Git. Aucun kubectl patch/edit/set/replace.

## Dettes restantes

- Dette historique PH-21.38-BIS: mutation involontaire documentee, runtime maintenant aligne par PH-21.40.
- Dette SRE separee: le check worker-restart amazon-orders-worker peut encore produire des alertes, mais elles sont log-only en DEV.
- Dette monitoring future: phase read-only PH-21.41 recommandee pour confirmer la stabilite sur plusieurs runs naturels.

## Git docs-only

Pre-rapport:

```text
HEAD_BEFORE_REPORT=27c25d65
ORIGIN_BEFORE_REPORT=27c25d65
AHEAD_BEHIND_BEFORE_REPORT=0/0
DIRTY_BEFORE_REPORT=0
```

Commit docs-only final:

```text
DOC_COMMIT=e2aca28e
HEAD=e2aca28e
ORIGIN=e2aca28e
AHEAD_BEHIND=0/0
DIRTY=0
```

## Prochain GO recommande

GO READONLY VERIFY MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV PH-SAAS-T8.12AS.21.41

## LINEAR_PREPARED_TEXT

PH-21.40 a applique en DEV monitoring-alerts avec le garde-fou global log-only. Verifier en PH-21.41 sur plusieurs runs naturels que Email OK et Webhook OK restent absents, sans trigger manuel ni event artificiel.

STOP.
