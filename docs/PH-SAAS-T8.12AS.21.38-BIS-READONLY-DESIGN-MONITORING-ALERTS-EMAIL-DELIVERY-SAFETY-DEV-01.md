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

| Mecanisme | Existe | Scope | Fonctionne runtime | Manque |
| --- | --- | --- | --- | --- |
| ConfigMap state | oui | LLM provider credit only | object existe | global checks non couverts |
| LLM debounce | oui | provider/model/env | live depuis incident, dry-run/log-only | preuve complete a refaire apres decision |
| Global delivery log-only | non | all checks | no | necessaire pour DEV safety |
| Per-check debounce | non global | worker/api/vault checks | no | emails repetes toutes les 2 min |
| Silence/TTL | non | all checks | no | pas de suppression window |

## Options de remediation

| Option | Changement | Avantage | Risque | Tests | Rollback | Recommandation |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Global delivery safety | Ajouter ALERT_DELIVERY_MODE=log-only ou MONITORING_ALERTS_LOG_ONLY=true et guard au debut de deliver_alerts | minimal, coupe SMTP/webhook DEV | masque alertes DEV pendant log-only | test offline avec ALERT_COUNT>0 sans Email OK/Webhook OK | revert GitOps + apply avec GO | RECOMMANDEE |
| 2. CronJob LLM dedie | separer watcher LLM sans deliver_alerts global | blast radius faible | plus de manifests/RBAC | tests CronJob dedie | revert/delete GitOps avec GO | option future |
| 3. Debounce checks existants | debounce par check | reduit spam sans couper email | plus complexe | tests par check | revert GitOps | dette apres guard |

## Recommandation

Recommandation: traiter PH-21.39 en SOURCE CONFIG PATCH DEV avec un garde-fou global de delivery log-only. La fonction deliver_alerts doit logguer une suppression log-only avec le nombre d'alertes puis retourner avant webhook/email quand MONITORING_ALERTS_LOG_ONLY=true ou ALERT_DELIVERY_MODE=log-only. Garder LLM_PROVIDER_CREDIT_DRY_RUN=true et LLM_PROVIDER_CREDIT_LOG_ONLY=true. Ajouter un test qui force ALERT_COUNT>0 et prouve que Email OK et Webhook OK sont absents en log-only.

## Plan PH-21.39

| Fichier | Changement propose | Test attendu | Risque |
| --- | --- | --- | --- |
| k8s/monitoring-alerts/configmap-script.yaml | ajouter defaults delivery log-only et guard dans deliver_alerts | shell self-test alert fixture sans Email/Webhook OK | syntaxe shell |
| k8s/monitoring-alerts/cronjob.yaml | ajouter MONITORING_ALERTS_LOG_ONLY=true ou ALERT_DELIVERY_MODE=log-only pour DEV | YAML/env check | alertes DEV masquees volontairement |
| k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh | test offline ALERT_COUNT>0 log-only | PASS | couverture incomplete |
| docs rapport PH-21.39 | documenter incident, rollback et apply separe | ASCII PASS | none |

Phase apply separee apres patch source: dry-run client/server, commit+push source, puis kubectl apply -f des manifests monitoring-alerts autorises avec GO explicite. Rollback: revert commit source/config, push, apply des manifests revenus par Git avec GO explicite.

## No fake metrics / no fake events

| Interdit | Statut |
| --- | --- |
| fake ai_usage/provider credit | non effectue |
| fake tracking/conversion/KBActions | non effectue |
| fake email/Slack | non effectue par CE; emails naturels existaient |
| DB mutation | non effectuee |
| TRAFFIC_REQUIRED / NO_NATURAL_PROVIDER_CREDIT_INCIDENT | aucun incident provider credit naturel constate |

## AI feature parity / anti-regression

| Surface IA | Point verifie | Source/log/runtime | Resultat |
| --- | --- | --- | --- |
| API DEV | image v3.5.263 watcher | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502 / ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 | OK |
| API PROD | image v3.5.262 alerting | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422 / ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | OK |
| Endpoint watcher | PH-21.37 200 auth safe | rapport PH-21.37 | OK |
| PROVIDER_CREDIT_EXHAUSTED | signal source | PH-21.28/PH-21.37 | OK |
| LLM/KBActions | aucun appel volontaire | scope read-only sauf incident apply manifests | OK_NO_LLM |
| AI Assist/Autopilot/Returns Analysis | non modifies | aucun patch source API | OK |
| Inbox/Amazon inbound/outbound | aucun trigger manuel | no create job/no event | OK |

## Non-regression DEV/PROD

| Service | Namespace | Image/runtime | Ready | Restarts | Changement CE | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | keybuzz-api-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502 | 1/1 | 0 | none | OK |
| keybuzz-api | keybuzz-api-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422 | 1/1 | 0 | none | OK |
| monitoring-alerts | vault-management | curlimages/curl:8.7.1 schedule */2 * * * * generation 2 | cron active | n/a | configmap+cronjob applied involuntarily | CRITICAL_FINDING |

## Interdits respectes / non respectes

| Interdit | Statut |
| --- | --- |
| kubectl apply | NON RESPECTE: 2 apply involontaires pendant rapport initial |
| kubectl set/env/patch/edit/replace | 0 |
| trigger CronJob manuel | 0 |
| Secret.data/base64/Vault value | 0 |
| recipient brut/webhook/token affiche | 0, sorties masquees |
| build/docker push/DB/LLM/fake event/Linear/PROD mutation | 0 |

## Rapport / Git

Correction docs-only apres commit initial 8f667a28. Aucun rollback runtime execute.

## Prochain GO recommande

GO SOURCE CONFIG PATCH MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV PH-SAAS-T8.12AS.21.39

## LINEAR_PREPARED_TEXT

PH-21.38-BIS a identifie le risque email monitoring-alerts, mais un incident CE a applique involontairement le ConfigMap script et le CronJob monitoring-alerts pendant la generation du rapport. Runtime: watcher LLM maintenant present en dry-run/log-only, mais global email delivery reste actif. Recommandation: PH-21.39 source/config pour ajouter un delivery log-only global avant toute nouvelle phase apply/verify.
