# PH-SAAS-T8.12AS.21.16 - Readonly design LLM provider credit alerting DEV PROD

## Verdict

GO READONLY DESIGN LLM PROVIDER CREDIT ALERTING DEV PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.16

Le design est suffisamment clair pour lancer une phase source patch DEV PH-21.17. Les dettes
restantes ne bloquent pas le patch: classification absente aujourd'hui, logs provider trop bruts,
pas d'alerte dediee, et correlation DB KBActions/ai_usage incomplete par requestId.

Prochaine phrase GO recommandee:

`GO SOURCE PATCH LLM PROVIDER CREDIT ALERTING DEV PH-SAAS-T8.12AS.21.17`

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.16_CE_MISSION.md` | lu |
| `AI_MEMORY/CURRENT_STATE.md` | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY\DOCUMENT_MAP.md` | lu |
| `AI_MEMORY\CE_PROMPTING_STANDARD.md` | lu |
| `AI_MEMORY\SERVER_SIDE_TRACKING_CONTEXT.md` | lu |
| `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-20.46-BIS_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-20.46-QUATER_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.01_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.15_CE_RETURN.md` | lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.46-BIS-READONLY-RCA-AI-ASSIST-INTERMITTENT-FAILURES-DEV-PROD-01.md` | lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.46-QUATER-READONLY-VERIFY-AI-ASSIST-REAL-CLICKS-DEV-PROD-01.md` | lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.01-READONLY-VERIFY-TRACKING-CLARITY-FEATURE-PARITY-PROD-01.md` | lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.15-READONLY-CLOSE-CAPI-PLATFORM-TOKEN-ENCRYPTION-PROD-01.md` | lu |

## Faits confirmes

| Sujet | Fait confirme |
| --- | --- |
| PH-20.46 incident | Cause racine = Anthropic/LiteLLM credit provider epuise, HTTP 400 `credit balance too low`, gateway `llm.keybuzz.io`, model groups `kbz-premium` et `kbz-standard`, impact DEV+PROD. |
| Apres recharge | PH-20.46-QUATER confirme DEV+PROD OK, 0 nouvelle erreur credit dans la fenetre observee, debit KBActions seulement sur generation reussie. |
| PH-21.15 | P0 CAPI token encryption clos; dette P1 ouverte = alerting credit LLM + fallback provider. |
| KBActions | Unite client = KBActions seulement; couts LLM reels non exposes au Client. |

## Preflight

| Point | Resultat | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IPv4 | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| Date UTC bastion | `Sat May 30 22:02:06 UTC 2026` | OK |
| Mode | READONLY DESIGN | OK |
| Mutation DB | aucune, SELECT only + ROLLBACK | OK |
| LLM volontaire | aucun appel | OK |
| Event tracking/CAPI | aucun | OK |
| Linear mutation | aucune | OK |

## Repos

| repo | branche | HEAD | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | ph147.4/source-of-truth | 9797bedf | 9797bedf | 0/0 | 223 | OK pour lecture; dirty limite a `dist` hors source analysee |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a | ad4e862a | 0/0 | 1 | OK; `tsconfig.tsbuildinfo` uniquement |
| keybuzz-infra | main | fe9c52df | fe9c52df | 0/0 | 0 | OK, cible rapport docs-only |
| keybuzz-backend | main | c38583a8 | c38583a8 | 0/0 | 1 | OK; backup Amazon hors scope LLM |
| keybuzz-website | main | eba00d81 | eba00d81 | 0/0 | 0 | OK |
| keybuzz-admin-v2 | main | 3707c834 | 3707c834 | 0/0 | 0 | OK |

## Runtime observe

| service | namespace | image runtime | ready | restarts | note |
| --- | --- | --- | --- | ---: | --- |
| keybuzz-api | keybuzz-api-dev | v3.5.261-capi-platform-token-encryption-dev | 1/1 | 0 | OK |
| keybuzz-api | keybuzz-api-prod | v3.5.261-capi-platform-token-encryption-prod | 1/1 | 0 | OK |
| keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | 1/1 | 4 | pre-existant, hors scope |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | 1/1 | 3 | pre-existant, hors scope |
| keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | 1/1 | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | 1/1 | 0 | OK |
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 1/1 | 0 | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 1/1 | 0 | OK |
| keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | 1/1 | 0 | OK |
| keybuzz-client | keybuzz-client-prod | v3.5.259-ai-assist-notification-scope-prod | 1/1 | 0 | OK |

## Cartographie LLM source

| fichier | fonction / route | appel LLM | debit KBActions | handling erreur actuel | risque |
| --- | --- | --- | --- | --- | --- |
| `keybuzz-api/src/services/litellm.service.ts` | `chatCompletion` | central, `LITELLM_BASE_URL` ou `https://llm.keybuzz.io`, model via plan | aucun debit KBActions direct; log `ai_usage` | log raw `errorText`, 400 devient `REQUEST_FAILED` | risque principal: pas de classification provider credit, logs trop bruts, pas d'alerte |
| `keybuzz-api/src/modules/ai/ai-assist-routes.ts` | `POST /ai/assist` | oui via `chatCompletion(..., feature=assist)` | debit apres `result.success` seulement | `status=limited`, `provider=fallback`, UI peut afficher erreur generique | pas de message specifique "provider indisponible, 0 KBActions" |
| `keybuzz-api/src/modules/autopilot/engine.ts` | `getAISuggestion` | oui via `chatCompletion(..., feature=autopilot)` | debit seulement apres brouillon/action utilisable; no-reply skip = 0 | si LLM fail: action none/confidence 0 | echec provider silencieux pour l'ops hors logs/ai_usage |
| `keybuzz-api/src/modules/ai/returns-decision-routes.ts` | returns analysis | oui via `chatCompletion(..., feature=returns_analysis)` | debit conditionnel apres reponse parseable et valeur decisionnelle | 500 avec erreur generique ou `aiResult.error` | doit recevoir classification/sanitization comme les autres chemins |
| `keybuzz-client/app/api/ai/assist/route.ts` | BFF AI Assist | pas de LLM direct | aucun | recopie details API tronques sur non-OK | eviter propagation future d'un message provider brut |
| `keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx` | UI AI Assist | pas de LLM direct | affiche KBActions uniquement | `status=limited` tombe dans erreur generique | UX a durcir pour provider unavailable sans cout reel |
| `keybuzz-backend/src/modules/ai/aiProviders.service.ts` | legacy/secondary provider | potentiel si `KEYBUZZ_AI_PROVIDER=litellm` | pas KBActions KeyBuzz API | throw `LiteLLM error status: raw body` | env runtime ne l'active pas aujourd'hui, mais dette future si active |

## Configuration runtime LLM/AI

| env | service | env names observes | conclusion |
| --- | --- | --- | --- |
| DEV | keybuzz-api | `LITELLM_BASE_URL`, `LITELLM_MASTER_KEY`, `AI_REAL_EXECUTION_ENABLED`, `AI_REAL_EXECUTION_TENANTS` | API DEV utilise LiteLLM; valeurs non affichees |
| PROD | keybuzz-api | `LITELLM_BASE_URL`, `LITELLM_MASTER_KEY` | API PROD utilise LiteLLM; valeurs non affichees |
| DEV/PROD | keybuzz-backend | pas de `KEYBUZZ_AI_PROVIDER`, pas de `KEYBUZZ_AI_API_KEY` observe dans les noms env filtres | provider legacy backend non actif d'apres env names |

## Logs runtime

Fenetre lue: logs `keybuzz-api` DEV+PROD, 72h, tail 50000, sans coller de contenu.

| env | service | fenetre | erreurs credit | autres erreurs LLM | conclusion |
| --- | --- | --- | ---: | ---: | --- |
| DEV | keybuzz-api | 72h | 0 | 0 `LiteLLM error/failed`, 0 `Anthropic`, 0 `fallback` | pas de recurrence visible apres recharge |
| PROD | keybuzz-api | 72h | 0 | 0 `LiteLLM error/failed`, 0 `Anthropic`, 1 ligne model `kbz-*`, 0 `fallback` | pas de recurrence visible apres recharge |

Conclusion logs: le probleme n'est pas actif au moment de l'audit, mais le code actuel ne produirait
pas un signal classe propre si l'erreur revient. PH-20.46 prouve que l'erreur etait visible en logs
bruts, pas transformee en alerte.

## DB read-only KBActions / events

Script utilise: `C:\DEV\KeyBuzz\tmp\ph2116_db_select_only.js`, mention `SELECT only`, transaction
`BEGIN TRANSACTION READ ONLY`, `ROLLBACK` confirme DEV et PROD.

| env | table | signal | resultat | conclusion |
| --- | --- | --- | --- | --- |
| DEV | ai_usage | total | 637 rows | table centrale presente |
| PROD | ai_usage | total | 237 rows | table centrale presente |
| DEV | ai_usage last30d | errors | 8 `REQUEST_FAILED` dont assist/autopilot, cout interne 0 | erreurs provider non typees |
| PROD | ai_usage last30d | errors | 7 `REQUEST_FAILED` dont assist/autopilot, cout interne 0 | erreurs provider non typees |
| DEV | ai_usage PH-20.46 window | errors | 7 `REQUEST_FAILED` | correspond a l'incident credit |
| PROD | ai_usage PH-20.46 window | errors | 2 `REQUEST_FAILED` | correspond a l'incident credit |
| DEV | ai_usage after PH-20.46 last7d | success | 5 assist success, 0 error | apres recharge OK |
| PROD | ai_usage after PH-20.46 last7d | success | 12 autopilot + 3 assist success, 0 error | apres recharge OK |
| DEV | ai_actions_ledger | last30d ai_generation | 49 debits reels | KBActions actif |
| PROD | ai_actions_ledger | last30d ai_generation | 96 debits reels | KBActions actif |
| DEV | ai_provider_usage | total | 0 | table non exploitee aujourd'hui |
| PROD | ai_provider_usage | total | 0 | table non exploitee aujourd'hui |
| DEV | ai_budget_alerts | total | 3 | budget alerts existent mais pas alerting provider |
| PROD | ai_budget_alerts | total | 0 | idem |

Point important: la jointure directe `ai_usage.request_id` -> `ai_actions_ledger.request_id` ne
fonctionne pas comme preuve universelle, car AI Assist genere un requestId route et `chatCompletion`
genere un autre requestId interne. La source reste donc la preuve principale du "pas de debit sur
provider failure": les debits KBActions sont apres `result.success` / brouillon usable, tandis que
`chatCompletion` loggue les erreurs avec cout interne 0. Dette a corriger: propager un
`parentRequestId` ou `llmRequestId` pour correlation ops sans exposer d'ID client.

## Mecanismes d'alerte existants

| mecanisme | repo/fichier | env | deja utilise pour | reutilisable pour LLM credit ? | risque |
| --- | --- | --- | --- | --- | --- |
| Prometheus/Alertmanager | `keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml` | cluster | routes log-only, Slack DEV, email | oui si signal metric disponible | pas de Loki/log metric identifie |
| AlertmanagerConfig | `keybuzz-infra/k8s/observability/alertmanager/alertmanager-config-dev.yaml` | observability | critical/warning vers Slack/email/log-only | oui | config DEV nommee, verifier couverture PROD avant promotion |
| PrometheusRule infra | `keybuzz-infra/k8s/observability/keybuzz-infra-alerts.yaml` | cluster | nodes, deployments, DB infra | partiel | pas de signal applicatif LLM |
| PrometheusRule workers | `keybuzz-worker-alerts` runtime | cluster | crashloop/restarts | non direct | pas de logs LLM |
| CronJob monitoring-alerts | `keybuzz-infra/k8s/monitoring-alerts/configmap-script.yaml` | `vault-management`, toutes les 2 min | Vault, Amazon, Shopify, Autopilot errors, API 500, restarts | oui, meilleur levier court terme: grep structured logs API | script actuel `ALERT_ENV=prod`; besoin design DEV-first/dedup |
| Email SMTP alerts | `k8s/monitoring-alerts/cronjob.yaml` | cluster | alert email via `10.0.0.160:25` vers SRE | oui | pas exposer payload provider brut |
| Slack/webhook | `monitoring-webhook` optional + Alertmanager Slack secret | cluster | alert channel optionnel | oui | secret non lu; payload doit etre masque |
| AI budget alerts | `ai-credits.service.ts` + `ai_budget_alerts` | API/DB | alertes quota tenant 50/80/100 | non recommande pour provider credit global | fonction non appelee hors lecture; pas delivery externe |
| ai_usage | `litellm.service.ts` | API/DB | usage success/blocked/error | oui, pour signal DB read-only | error_code trop generique aujourd'hui |
| ai_journal_events | `ai-journal-routes.ts` | API/DB | journal produit | non recommande pour incident provider global | ne pas creer de faux events produit |

## Design recommande DEV-first

### 1. Classification provider credit

Ajouter dans l'API un helper pur, teste sans appel LLM:

- fichier propose: `src/lib/llm-provider-errors.ts`
- entree: HTTP status, body texte/json, provider/gateway, model group, feature;
- sortie: `{ code, severity, retryable, safeUserMessage, sanitizedDetails }`;
- detection:
  - status 400/402/429 selon gateway/provider;
  - `credit balance too low`;
  - `insufficient credit`, `insufficient quota`, `billing`, `quota`;
  - `AnthropicException` uniquement comme metadata interne sanitisee;
- code canonique: `PROVIDER_CREDIT_EXHAUSTED`;
- fallback generique: `LITELLM_HTTP_<status>` ou `LITELLM_REQUEST_FAILED`;
- jamais de body provider brut dans logs/API.

### 2. Logs et ai_usage

Modifier `chatCompletion`:

- remplacer `console.error("[LiteLLM] Error status:", errorText)` par un log structure masque;
- log ligne stable: `LLM_PROVIDER_CREDIT_EXHAUSTED` avec env, feature, modelGroup, status, provider
  si connu, requestId interne, sans prompt, sans message, sans token, sans cout;
- `ai_usage.error_code = PROVIDER_CREDIT_EXHAUSTED` pour ce cas;
- `provider = litellm`, `status = error`, tokens = 0, cout interne = 0;
- conserver les success logs existants mais eviter toute exposition client des couts;
- propager optionnellement `classification.code` dans la reponse interne `chatCompletion`.

### 3. UX/API

AI Assist:

- si `result.errorCode === PROVIDER_CREDIT_EXHAUSTED`, repondre avec un etat client safe:
  `status = provider_unavailable`, `error = AI_PROVIDER_TEMPORARILY_UNAVAILABLE`,
  `kbActionsConsumed = 0`, `actionsConsumed = 0`;
- message client: "Le service IA est temporairement indisponible. Aucune KBActions n'a ete debitee.";
- ne jamais exposer "credit balance", "Anthropic", cout USD, tokens ou solde provider au Client;
- le Client doit afficher cet etat comme incident temporaire, pas comme quota KBActions.

Autopilot:

- si provider failure, conserver `action=none`, `kbActionsDebited=0`;
- ajouter un log ops structure `LLM_PROVIDER_CREDIT_EXHAUSTED` feature `autopilot`;
- ne pas auto-escalader ni envoyer un message client sur panne provider;
- ne pas incrementer des erreurs tenant qui auto-desactivent un client pour une panne globale provider.

Returns analysis:

- transformer le retour provider credit en erreur API safe;
- ne pas debiter KBActions;
- ne pas sauver une analyse cachee ou journal produit sur un echec provider.

### 4. Alerting

Phase PH-21.17 source:

- produire le signal structure log + `ai_usage.error_code`;
- tests unitaires du classifier et du chemin `chatCompletion` avec `fetch` mocke;
- aucune generation reelle.

Phase suivante infra si PH-21.17 valide:

- ajouter un check `check_llm_provider_credit` dans `monitoring-alerts.sh`;
- source du check: grep de `LLM_PROVIDER_CREDIT_EXHAUSTED` sur logs API;
- seuil DEV: warning si >= 1 sur 5 minutes, repeat/dedup 60 minutes;
- seuil PROD: critical si >= 1 sur 5 minutes, repeat/dedup 30 minutes;
- payload masque: env, count, feature counts, model groups, window, no tenant, no prompt, no body;
- route: webhook/email existants; Alertmanager/Slack si integration retenue;
- no fake metrics: validation par unit test + grep logs, pas de faux `ai_suggestion_events`.

### 5. KBActions

Invariants a garder:

- debit uniquement apres generation reussie et exploitable;
- provider failure = 0 KBActions;
- no-reply notification skip = 0 KBActions;
- client ne voit que KBActions, jamais cout LLM reel;
- ajouter la correlation ops sans exposer les IDs: `parentRequestId` ou `llmRequestId` interne pour
  relier `ai_usage` et `ai_actions_ledger` dans les rapports read-only.

### 6. Fallback provider

Ne pas l'implementer en PH-21.17. Le fallback multi-provider doit etre une phase separee car il
demande:

- credentials provider alternatifs;
- model group LiteLLM reellement separe du meme wallet Anthropic;
- politique de cout/qualite;
- tests anti-regression seller-first;
- limites par feature (assist/autopilot/returns);
- observabilite et rollback dedies.

## Options

| option | scope | avantage | risque | recommandation |
| --- | --- | --- | --- | --- |
| Classifier + logs structures API | PH-21.17 source DEV | rapide, central, couvre assist/autopilot/returns | n'alerte pas seul sans watcher | RECOMMANDE maintenant |
| `ai_usage.error_code=PROVIDER_CREDIT_EXHAUSTED` | PH-21.17 source DEV | DB read-only exploitable, pas fake event | necessite migration seulement si enum absente; ici text donc OK | RECOMMANDE |
| Client provider_unavailable | PH-21.17 ou phase Client dediee | UX claire, 0 cout expose | touche Client si inclus | RECOMMANDE si scope PH-21.17 autorise Client, sinon phase suivante |
| monitoring-alerts grep structured logs | infra DEV apres source | alerte rapide email/webhook | script actuel prod-oriented; besoin dedup | RECOMMANDE phase infra apres signal source |
| Prometheus metric API | phase plus large | alertmanager propre | demande endpoint/instrumentation | PLUS TARD |
| Reuse ai_budget_alerts | API/DB | table existe | mauvais domaine, pas delivery externe | NON |
| Fallback multi-provider | phase separee | resilience forte | credentials/routing/regression | SEPARER |

## AI feature parity / anti-regression

| Feature | Verification design |
| --- | --- |
| AI Assist manuel | classifier central, UX provider unavailable, 0 KBActions provider failure |
| Autopilot | echec provider reste no-action, pas de message automatique, 0 KBActions |
| Notification no-reply skip | skip reste avant LLM, donc aucun appel LLM et 0 KBActions |
| KBActions | debit apres succes uniquement, provider failure sans debit |
| Client | pas de cout USD/token/provider balance expose; KBActions seulement |
| Amazon outbound | hors scope, aucun chemin outbound touche |
| CAPI/tracking | hors scope, aucun fake event, aucun provider event |
| Returns analysis | meme classification centrale, pas de cache/journal sur panne provider |

## Dettes restantes

| Dette | Severite | Bloque PH-21.17 ? | Note |
| --- | --- | --- | --- |
| Logs provider brut dans `litellm.service.ts` | P1 | non | a corriger en PH-21.17 |
| Error code generique `REQUEST_FAILED` | P1 | non | a remplacer par code classe |
| Aucune alerte credit LLM dediee | P1 | non | source signal d'abord, watcher ensuite |
| `ai_provider_usage` vide | P2 | non | ne pas baser l'alerte dessus |
| `checkAndCreateAlerts` budget non appele pour provider | P2 | non | domaine quota tenant, pas provider global |
| RequestId usage/ledger non correlable | P2 | non | ajouter parent/llm request id |
| Backend legacy provider non hardene | P2 | non | runtime non actif, a couvrir si activation future |
| Fallback multi-provider absent | P1/P2 | non | phase separee |

## Non-regression / hors scope confirme

| Point | Resultat |
| --- | --- |
| Code source modifie | non |
| Runtime modifie | non |
| Build | non |
| Docker push | non |
| Deploy / kubectl apply | non |
| DB mutation | non |
| LLM volontaire | non |
| Tracking/CAPI event | non |
| Amazon outbound | non touche |
| Linear | non modifie |
| Secrets/logs sensibles | aucun secret, token, cookie, Authorization header, connection string ou valeur env affiche |

## Plan PH-21.17 propose

1. Preflight repo/runtimes identique, DEV only.
2. Patch source API:
   - helper `llm-provider-errors`;
   - sanitization logs provider;
   - `ai_usage.error_code=PROVIDER_CREDIT_EXHAUSTED`;
   - propagation interne `errorCode`;
   - AI Assist/Autopilot/Returns safe handling.
3. Tests sans appel LLM:
   - classifier unit;
   - mocked fetch 400 credit;
   - mocked fetch 500;
   - success path non-regression;
   - KBActions non-debit sur provider failure.
4. Aucun fake event, aucun vrai appel LLM.
5. Commit source DEV only, puis build/deploy uniquement si la mission PH-21.17 l'autorise explicitement.

## Texte Linear prepare, non poste

```text
PH-21.16 readonly design termine.

Constat: le risque PH-20.46 est bien centralise dans le chemin LiteLLM API. Les erreurs provider
credit sont aujourd'hui visibles comme logs bruts et `REQUEST_FAILED`, sans classification ni alerte
dediee. KBActions reste conforme: source et rapports precedents prouvent pas de debit sur provider
failure; les debits restent apres generation reussie. Les mecanismes d'alerte reutilisables existent
(monitoring-alerts CronJob, Alertmanager Slack/email), mais aucun check LLM credit n'existe encore.

Verdict: READY_WITH_DEBTS.
Prochaine phase recommandee: GO SOURCE PATCH LLM PROVIDER CREDIT ALERTING DEV PH-SAAS-T8.12AS.21.17.
```

## Resume terminal

RESUME LUDOVIC - TERMINAL
1. PH-21.16 executee en READONLY DESIGN strict: aucun code source modifie, aucun build, deploy, DB mutation, LLM call, tracking event ou Linear mutation.
2. Bastion OK: install-v3 / 46.62.171.61; API DEV+PROD tourne en v3.5.261 et pods API ready 1/1 restarts 0.
3. Cartographie LLM confirmee: `chatCompletion` central couvre AI Assist, Autopilot et Returns Analysis; backend legacy LiteLLM non actif d'apres env names.
4. Cause PH-20.46 confirmee par rapports: Anthropic/LiteLLM credit exhausted via llm.keybuzz.io; apres recharge, 0 recurrence visible dans logs 72h.
5. Faiblesse actuelle: `litellm.service.ts` loggue le body provider brut et transforme les 400 credit en `REQUEST_FAILED`, sans code `PROVIDER_CREDIT_EXHAUSTED`.
6. DB SELECT-only: `ai_usage` montre les erreurs PH-20.46 en `REQUEST_FAILED` cout 0; KBActions reste debit apres succes seulement, mais correlation requestId usage/ledger est une dette.
7. Alerting reutilisable existe: Alertmanager Slack/email/log-only et CronJob `monitoring-alerts`; aucun check dedie LLM credit aujourd'hui.
8. Design recommande: classifier/sanitizer provider credit, logs structures `LLM_PROVIDER_CREDIT_EXHAUSTED`, `ai_usage.error_code`, UX safe 0 KBActions, puis watcher alerting dedie.
9. Fallback multi-provider a separer d'une phase ulterieure; PH-21.17 doit rester source patch DEV sans fake event ni appel LLM reel.
10. Verdict: GO READONLY DESIGN LLM PROVIDER CREDIT ALERTING DEV PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.16; prochain GO: GO SOURCE PATCH LLM PROVIDER CREDIT ALERTING DEV PH-SAAS-T8.12AS.21.17.
Fichier retour: C:\DEV\KeyBuzz\tmp\PH-21.16_CE_RETURN.md
STOP.
