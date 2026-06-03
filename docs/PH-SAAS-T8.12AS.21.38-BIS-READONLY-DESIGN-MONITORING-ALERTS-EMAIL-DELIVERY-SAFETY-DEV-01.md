# PH-SAAS-T8.12AS.21.38-BIS - Readonly Design Monitoring-Alerts Email Delivery Safety DEV

## Verdict

GO READONLY DESIGN MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.38-BIS

## Objectif

RCA/design read-only du blocage PH-21.38: le CronJob monitoring-alerts envoyait deja des emails avant l'apply du watcher LLM provider credit. La phase identifie le chemin email, les checks responsables, le drift source/runtime, puis recommande un patch source/config DEV-first.

## Sources relues

| Source | Statut |
| --- | --- |
| Mission PH-21.38-BIS | relue |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relus |
| Modele PH-T8.10J | relu localement |
| Retours PH-21.28, PH-21.34 PUSH, PH-21.36, PH-21.37, PH-21.38 | relus |
| Rapports distants PH-21.28, PH-21.36, PH-21.37, PH-21.38 | relus via dossier docs |
| Manifests monitoring-alerts et tests PH-21.28/PH-21.34 | audites read-only |

## Preflight

```text
HOSTNAME=install-v3
HOST_IPS=46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1  
UTC=2026-06-03T14:01:39Z
KUBE_CONTEXT=kubernetes-admin@kubernetes
```

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 3b8aee005388 | 3b8aee005388 | 0/0 | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a0e10 | 76483e3a0e10 | read-only | 223 preexisting dist deletions | OK |

## Reconstitution PH-21.38

| Job | Heure UTC | Alert count | Email marker | Slack/webhook marker | Source naturelle | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| monitoring-alerts-29674916 | 2026-06-03T13:56:00Z | alerts=2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |
| monitoring-alerts-29674918 | 2026-06-03T13:58:00Z | alerts=2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |
| monitoring-alerts-29674920 | 2026-06-03T14:00:00Z | alerts=2 | email_ok=1 | webhook_ok=0 | CronJob naturel | OK |

Preuve PH-21.38 historique: jobs 29674628/29674630/29674632 a 09:08/09:10/09:12 UTC avec Sending 2 alerts puis Email OK. Aucun apply PH-21.38, aucun trigger manuel.

## Checks qui envoient les emails

| Check | Condition | Valeur observee | Seuil | Debounce present | Pourquoi email envoye |
| --- | --- | --- | --- | --- | --- |
| worker-restart | restart count >= RESTART_THRESHOLD | amazon-orders-worker crash loop (6x) | RESTART_THRESHOLD=3 | absent globally | deliver_alerts sends because ALERT_COUNT>0 and SMTP_HOST set |

## Cartographie email/Slack/webhook

| Channel | Arme runtime | Source env/secret | Valeur masquee | Utilise par deliver_alerts | Risque |
| --- | --- | --- | --- | --- | --- |
| Email SMTP | yes | env SMTP_HOST/SMTP_TO | SMTP_TO present_masked count=1 | yes | high: natural jobs send Email OK |
| Slack/Webhook | yes | WEBHOOK_URL secretRef/env | secretRef name=monitoring-webhook key=url optional=true | yes if non-empty | low/current: Webhook OK markers absent |
| LLM provider token | yes | secretRef monitoring-llm-provider-credit-token/token | metadata-only, value not read | used only by LLM endpoint call | no leak observed |

## Source Git vs runtime live

| Objet | Source Git | Runtime live | Drift | Impact |
| --- | --- | --- | --- | --- |
| check_llm_provider_credit | True | False | yes | watcher source exists but is not live yet |
| LLM_PROVIDER_CREDIT_DRY_RUN | True | False | yes | watcher source exists but is not live yet |
| LLM_PROVIDER_CREDIT_LOG_ONLY | True | False | yes | watcher source exists but is not live yet |
| deliver_alerts | True | True | no | global delivery path remains active |
| global_log_only_guard | False | False | no | missing guard blocks safe apply |
| SMTP_HOST | True | True | no | email can send when ALERT_COUNT>0 |
| SMTP_TO | present_masked count=1 | present_masked count=1 | no | email can send when ALERT_COUNT>0 |
| WEBHOOK_URL | secretRef name=monitoring-webhook key=url optional=true | secretRef name=monitoring-webhook key=url optional=true | no | no direct issue |

## Debounce / spam prevention

| Mecanisme | Existe | Scope | Fonctionne runtime | Manque |
| --- | --- | --- | --- | --- |
| ConfigMap state | oui source/runtime object existe | LLM provider credit only | live old script does not use it | global checks not covered |
| LLM debounce | oui source PH-21.28 | provider/model/env | not live yet | apply blocked by email risk |
| Global delivery log-only | non | all checks | no | required for DEV safety |
| Per-check debounce | non global | worker/api/vault checks | no | causes repeated emails every schedule |
| Silence/TTL | non | all checks | no | no suppression window |
| DEV/PROD separation | partielle | ALERT_ENV and LLM target env | ALERT_ENV runtime currently prod in source/live old cron | should isolate DEV delivery mode |

## Options de remediation

| Option | Changement | Avantage | Risque | Tests | Rollback | Recommandation |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Global delivery safety | Ajouter ALERT_DELIVERY_MODE=log-only ou MONITORING_ALERTS_LOG_ONLY=true et faire logguer deliver_alerts sans SMTP/webhook quand actif | minimal, reduit risque pour tous checks DEV, permet apply watcher dry-run | peut masquer alertes DEV reelles tant que log-only actif | tests shell offline Email/Webhook not sent, source YAML, live logs | revert commit puis kubectl apply -f source en phase apply | RECOMMANDEE |
| 2. CronJob LLM dedie | Isoler watcher LLM dans un CronJob separe log-only sans deliver_alerts global | blast radius tres faible | plus de manifests/RBAC, plus long | tests nouveaux CronJob + endpoint safe | delete/revert GitOps dedie | option future si isolation stricte voulue |
| 3. Debounce checks existants | Garder email actif mais ajouter debounce par check | preserve alerting utile | plus complexe et risque de spam pendant patch | tests par check et ConfigMap state | revert source + apply | dette SRE apres garde-fou global |

## Recommandation

Recommander PH-21.39 en SOURCE CONFIG PATCH DEV: ajouter un garde-fou global de delivery log-only dans monitoring-alerts DEV.  doit logguer  avec nombre d'alertes, puis return avant webhook/email quand  ou . Garder  et . Ne relancer PH-21.38 apply qu'apres ce patch, tests et push.

## Plan PH-21.39

| Fichier | Changement propose | Test attendu | Risque |
| --- | --- | --- | --- |
| k8s/monitoring-alerts/configmap-script.yaml | Ajouter env defaults MONITORING_ALERTS_LOG_ONLY/ALERT_DELIVERY_MODE et guard au debut de deliver_alerts apres body safe | self-test prouve no Email/Webhook OK en log-only | erreur shell dans script |
| k8s/monitoring-alerts/cronjob.yaml | Ajouter MONITORING_ALERTS_LOG_ONLY=true ou ALERT_DELIVERY_MODE=log-only pour DEV monitoring-alerts | YAML + env check | masquer alerting DEV tant que actif |
| k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh | Test offline avec alert fixture, verifie  absent ou suppressed, / absents | PASS | test incomplet si ne couvre pas ALERT_COUNT>0 |
| docs rapport PH-21.39 | Documenter rollback GitOps et next apply | ASCII/pass | none |

Phase apply separee apres source patch: dry-run client/server, commit+push source, puis configmap/monitoring-alert-script configured et cronjob.batch/monitoring-alerts configured uniquement avec GO explicite. Rollback: revert commit source/config, push, apply des manifests revenus par Git.

## No fake metrics / no fake events

| Interdit | Statut |
| --- | --- |
| fake ai_usage/provider credit | non effectue |
| fake tracking/conversion/KBActions | non effectue |
| fake email/Slack | non effectue |
| DB mutation | non effectuee |
| TRAFFIC_REQUIRED / NO_NATURAL_PROVIDER_CREDIT_INCIDENT | aucun incident provider credit naturel constate |

## AI feature parity / anti-regression

| Surface IA | Point verifie | Source/log/runtime | Resultat |
| --- | --- | --- | --- |
| API DEV | image v3.5.263 watcher conservee | runtime read-only | OK |
| API PROD | image v3.5.262 alerting conservee | runtime read-only | OK |
| Endpoint watcher | authentifie 200 en PH-21.37 | rapport PH-21.37 | OK |
| PROVIDER_CREDIT_EXHAUSTED | signal source | PH-21.28/PH-21.37 | OK |
| LLM/KBActions | aucun appel/debit | scope read-only | OK |
| AI Assist/Autopilot/Returns Analysis | non modifies | aucun patch source | OK |
| Inbox/Amazon inbound/outbound | aucun trigger | no create job/no event | OK |

## Non-regression DEV/PROD

| Service | Namespace | Image/runtime | Ready | Restarts | Changement CE | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | keybuzz-api-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502 | 1/1 | 0 | none | OK |
| keybuzz-api | keybuzz-api-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422 | 1/1 | 0 | none | OK |
| monitoring-alerts | vault-management | curlimages/curl:8.7.1 schedule */2 | cron active | n/a | none | OK_READONLY |

Runtime status:

```text
API_DEV_DEPLOY=ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502

API_DEV_IMAGEID=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996

API_DEV_RESTARTS=0

API_PROD_DEPLOY=ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422

API_PROD_IMAGEID=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6

API_PROD_RESTARTS=0

NAME                SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
monitoring-alerts   */2 * * * *   <none>     False     0        102s            53d

NAME                                   STORETYPE            STORE           REFRESH INTERVAL   STATUS         READY
monitoring-llm-provider-credit-token   ClusterSecretStore   vault-backend   1h                 SecretSynced   True

NAME                                   TYPE     DATA   AGE
monitoring-llm-provider-credit-token   Opaque   1      6h39m
```

## Interdits respectes

| Interdit | Statut |
| --- | --- |
| kubectl apply/set/env/patch/edit/replace | 0 |
| trigger CronJob manuel | 0 |
| Secret.data/base64/Vault value | 0 |
| recipient brut/webhook/token affiche | 0, sorties masquees |
| build/docker push/DB/LLM/fake event/Linear/PROD mutation | 0 |

## Rapport / Git

| Repo | HEAD | Origin | Ahead/Behind | Dirty |
| --- | --- | --- | --- | --- |
| keybuzz-infra | 3b8aee005388 | 3b8aee005388 | 0/0 | 0 avant commit rapport |

## Prochain GO recommande

GO SOURCE CONFIG PATCH MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV PH-SAAS-T8.12AS.21.39

## LINEAR_PREPARED_TEXT

PH-21.38-BIS a identifie que monitoring-alerts envoie deja des emails via deliver_alerts global quand ALERT_COUNT>0. Les checks existants sont responsables, pas le watcher LLM. Recommandation: patch source/config DEV-first pour ajouter un mode global log-only avant de relancer l'apply watcher dry-run.
