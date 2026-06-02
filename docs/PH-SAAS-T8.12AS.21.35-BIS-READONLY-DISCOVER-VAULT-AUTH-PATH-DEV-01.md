# PH-SAAS-T8.12AS.21.35-BIS - Readonly Discover Vault Auth Path DEV

## Verdict

Verdict retenu :

`GO READONLY DISCOVER VAULT AUTH PATH LLM PROVIDER CREDIT WATCHER SECRET DEV ACTION_REQUIRED_OPS_AUTH PH-SAAS-T8.12AS.21.35-BIS`

Conclusion : le store, le chemin Vault et le pattern External Secrets sont clairs, mais CE
ne dispose pas d'une authentification Vault admin/ops exploitable pour materialiser le
secret. La prochaine action doit etre une action Ops/admin, hors chat et hors logs.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.35_CE_RETURN.md` | Relue |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.35-MATERIALIZE-LLM-PROVIDER-CREDIT-WATCHER-SECRET-DEV-01.md` | Relue |
| `C:\DEV\KeyBuzz\tmp\PH-21.34_PUSH_CE_RETURN.md` | Relue |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.34-SOURCE-CONFIG-PATCH-LLM-PROVIDER-CREDIT-WATCHER-SECRET-DEV-01.md` | Relue |
| `C:\DEV\KeyBuzz\tmp\PH-21.33_CE_RETURN.md` | Relue |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.33-READONLY-DESIGN-LLM-PROVIDER-CREDIT-WATCHER-SECRET-DEV-01.md` | Relue |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md` | Relue |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md` | Relue |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md` | Relue |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md` | Relue |
| `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Relu |
| `/opt/keybuzz/keybuzz-infra/docs` | Recherche readonly sur termes Vault/ESO |
| `/opt/keybuzz/keybuzz-infra/k8s` | Recherche readonly sur termes Vault/ESO |

## Preflight

| Point | Observe | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IP obligatoire | `46.62.171.61` presente | OK |
| IP interdite | `51.159.99.247` non observee | OK |
| Date UTC | `2026-06-02T12:18:43Z` | OK |
| Kube context | `kubernetes-admin@kubernetes` | OK |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `keybuzz-infra` | `main` | `72300c1a` | `72300c1a` | `0/0` | `0` | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `76483e3a` | `76483e3a` | `0/0` | `223`, tous `dist/` | OK lecture seule |

## Blocage PH-21.35 consolide

| Point | Preuve | Verdict |
| --- | --- | --- |
| Vault | PH-21.35 et verification manuelle Ludovic indiquent Vault joignable et unsealed | OK |
| Auth CE | `vault_auth_exit=2`, `permission denied`, `invalid token` en PH-21.35 | Bloquant |
| Session CE actuelle | `VAULT_ADDR_PRESENT=no`, `VAULT_TOKEN_PRESENT=no`; commandes Vault readonly non exploitables dans cette session | Bloquant |
| Secret materialise | Aucun secret materialise en PH-21.35 | Confirme |
| K8s Secret direct | Aucun Secret Kubernetes cree | Confirme |
| Apply/deploy | Aucun apply/deploy realise | Confirme |
| RemoteRef cible | `secret/keybuzz/llm_provider_credit/dev/monitor_token`, property `value` | Confirme |

Conclusion : ne pas relancer PH-21.35 tel quel. Il manque une authentification Vault
admin/ops officielle et exploitable.

## ExternalSecret / Store / Auth Pattern

| Objet | Namespace | Information non secrete | Impact |
| --- | --- | --- | --- |
| `ClusterSecretStore/vault-backend` | cluster | Ready `True`, reason `Valid` | Store cible confirme |
| `vault-backend` | cluster | KV path `secret`, version `v2` | RemoteRef compatible KV v2 |
| `vault-backend` | cluster | Auth method `kubernetes` | Auth ESO non basee sur un token CE |
| `vault-backend` | cluster | Mount `kubernetes`, role `keybuzz-external-secrets` | Role ESO identifie |
| `vault-backend` | cluster | ServiceAccount `external-secrets` namespace `external-secrets` | Identite ESO identifiee |
| `SecretStore` | all namespaces | Aucun SecretStore namespaced trouve | Pattern principal cluster store |
| `ExternalSecret` watcher | `keybuzz-api-dev` et `vault-management` | Non present au runtime, car PH-21.34 n'a pas ete applique | Conforme au scope |
| `Secret` watcher | `keybuzz-api-dev` et `vault-management` | Absent en metadata-only | Conforme au scope |

## Recherche documentation

| Source | Information utile | Applicable | Risque |
| --- | --- | --- | --- |
| `PH-WEBSITE-T8.12AS.17.1Q-1A-KEY-323-VAULT-VERIFICATION-ROTATION-DESIGN-READONLY-01.md` | Decrit ESO via `vault-backend` / `vault-backend-database`, auth Kubernetes ServiceAccount JWT, sans token statique | Oui pour comprendre le pattern | Ne donne pas a CE un droit d'ecriture |
| `PH-WEBSITE-T8.12AS.17.1Q-1A-KEY-323-VAULT-VERIFICATION-ROTATION-DESIGN-READONLY-01.md` | Signale un token operateur invalide/expire et recommande un re-login Vault par Ludovic/admin | Oui pour le blocage | Action humaine requise |
| `PH-WEBSITE-T8.12AS.17.1Q-1A-bis-KEY-323-...DESIGN...md` | Decrit une procedure future avec token temporaire court TTL et policy dediee creee par Ludovic/Ops | Oui comme pattern officiel d'handoff | Token/policy admin hors scope CE actuel |
| `PH-VAULT-TOKEN-AUTO-ROTATION-01.md` | Decrit `vault-admin-token` utilise par la CronJob `vault-token-renew` | Informatif seulement | Ne doit pas etre lu ni reutilise par CE |
| `k8s/vault-token-renew/*` | Decrit une automation de renouvellement Vault deja separee | Informatif seulement | Pas un chemin sur pour materialiser ce secret |
| `PH-WEBSITE-T8.12AS.17.1Q-1B-0-...KV-SECRETS-ROTATION-PLAN...md` | Decrit un plan de rotation KV par batch avec auth temporaire | Oui comme precedent process | Mutation hors scope de cette phase |

## Conclusion B - Action Required Ops Auth

La procedure exploitable par CE n'est pas disponible dans l'etat actuel. Le chemin sur est
une action Ops/admin : materialiser le secret dans Vault KV v2 via une session Vault privee
et autorisee, sans passer par le chat, sans afficher la valeur, et sans creer de Secret
Kubernetes manuel.

Message minimal a transmettre a Ops :

| Champ | Valeur |
| --- | --- |
| Store attendu | `vault-backend` |
| KV engine | `secret`, version `v2` |
| Chemin | `secret/keybuzz/llm_provider_credit/dev/monitor_token` |
| Property | `value` |
| Valeur | Token fort aleatoire, au moins 32 bytes d'entropie |
| Interdit | Ne pas afficher la valeur, ne pas la coller dans le chat, ne pas creer de Secret Kubernetes direct |
| Verification CE apres Ops | Metadata/status uniquement, aucune lecture de valeur |

Procedure concrete recommandee :

1. Ludovic/Ops restaure une authentification Vault admin/ops dans un canal prive.
2. Ludovic/Ops materialise la property `value` au chemin Vault cible ci-dessus.
3. Ludovic/Ops confirme uniquement que la materialisation est terminee, sans transmettre
   la valeur.
4. CE execute ensuite une phase readonly de verification metadata/status, sans lecture de
   secret.

## Non-regression Readonly

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| API DEV runtime | Inchange | `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev` | OK |
| API PROD runtime | Intact | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` | OK |
| `monitoring-alerts` runtime | Non active | Deployment absent | OK |
| K8s Secret API DEV | Non cree | `monitoring-llm-provider-credit-token` absent | OK |
| K8s Secret vault-management | Non cree | `monitoring-llm-provider-credit-token` absent | OK |
| ExternalSecret API DEV | Non applique | `llm-provider-credit-monitor-token` absent | OK |
| ExternalSecret vault-management | Non applique | `monitoring-llm-provider-credit-token` absent | OK |
| CronJob | Aucun trigger | Aucun trigger execute | OK |
| Slack/email/webhook | Aucun appel | Aucun appel execute | OK |
| DB | Aucune mutation | Aucune commande DB executee | OK |
| LLM | Aucun appel | Aucun appel LLM execute | OK |
| Tracking/event | Aucun event | Aucun event fabrique | OK |
| PROD | Aucune mutation | Verification readonly uniquement | OK |

## No Fake Metrics / No Fake Events

Aucun `ai_usage`, aucun incident `PROVIDER_CREDIT_EXHAUSTED`, aucun appel LLM, aucun
watcher trigger, aucune alerte Slack/email, aucun endpoint tracking et aucune metrique ou
event artificiel n'ont ete crees.

## AI Feature Parity / Anti-Regression

| Feature | Impact PH-21.35-BIS | Preuve | Verdict |
| --- | --- | --- | --- |
| AI Assist | Aucun impact runtime | Phase readonly auth discovery | OK |
| Autopilot | Aucun impact runtime | Aucun code/deploy/API call | OK |
| Returns Analysis | Aucun impact runtime | Aucun code/deploy/API call | OK |
| KBActions | Aucun impact runtime | Aucun LLM call ni billing event | OK |
| `PROVIDER_CREDIT_EXHAUSTED` | Aucun faux signal | Aucun event/metric fabrique | OK |
| Cout LLM client | Aucun cout | Aucun appel LLM | OK |
| Prompt/message/client raw content | Non expose | Aucun endpoint ni logs applicatifs lus | OK |

## Interdits respectes

| Interdit | Statut |
| --- | --- |
| Secret lu/cree/ecrit | `0` |
| Valeur Vault/Kubernetes Secret affichee | `0` |
| `vault kv put/write/get/read secret/...` execute | `0` |
| `vault token create/login` execute | `0` |
| `kubectl apply/set/patch/edit/create/delete secret` execute | `0` |
| Build/docker push/deploy/restart | `0` |
| DB mutation/LLM call/event/alert/Slack/email/Linear | `0` |
| Lecture `/opt/keybuzz/credentials` ou `/opt/keybuzz/secrets` | `0` |

## Prochain GO exact

`ACTION OPS REQUIRED - MATERIALIZE VAULT SECRET secret/keybuzz/llm_provider_credit/dev/monitor_token property value`

Puis, apres confirmation Ops sans secret en clair :

`GO READONLY VERIFY LLM PROVIDER CREDIT WATCHER SECRET MATERIALIZED DEV PH-SAAS-T8.12AS.21.35-TER`

## Fichier retour CE

`C:\DEV\KeyBuzz\tmp\PH-21.35-BIS_CE_RETURN.md`
