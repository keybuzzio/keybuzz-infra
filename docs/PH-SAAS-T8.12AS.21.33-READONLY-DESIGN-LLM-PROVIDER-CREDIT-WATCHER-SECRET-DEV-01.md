# PH-SAAS-T8.12AS.21.33 - Readonly design LLM provider credit watcher secret DEV

## Verdict

GO READONLY DESIGN LLM PROVIDER CREDIT WATCHER SECRET DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.33

Design complet: la strategie recommandee est un secret dedie, materialise via le pattern
ExternalSecret/Vault existant, avec deux Secret Kubernetes namespaced portant le meme nom et la
meme key:

- namespace `keybuzz-api-dev`: Secret `monitoring-llm-provider-credit-token`, key `token`,
  injecte dans l'API DEV via `LLM_PROVIDER_CREDIT_MONITOR_TOKEN`;
- namespace `vault-management`: Secret `monitoring-llm-provider-credit-token`, key `token`,
  consomme par `monitoring-alerts` via `LLM_PROVIDER_CREDIT_TOKEN`.

Verdict `READY_WITH_DEBTS` car la valeur n'a pas ete materialisee, aucun Secret n'a ete cree,
et le watcher n'est pas active runtime. Ces actions doivent rester dans des phases DEV futures
separees avec GO explicite.

## Sources relues

| source | statut | impact |
| --- | --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.32_CE_RETURN.md` | relu | runtime DEV conforme, endpoint protege, secret absent |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.32-READONLY-VERIFY-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | preuves PH-21.32 confirmees |
| `C:\DEV\KeyBuzz\tmp\PH-21.31_CE_RETURN.md` | relu | GitOps API DEV v3.5.263 applique |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.31-APPLY-API-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | commit deploy et digest runtime |
| `C:\DEV\KeyBuzz\tmp\PH-21.28_CE_RETURN.md` | relu | endpoint, envs acceptees, watcher source |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.28-SOURCE-PATCH-LLM-PROVIDER-CREDIT-WATCHER-DEV-01.md` | relu | dette secret watcher runtime |
| `AI_MEMORY/CURRENT_STATE.md` | relu | etat projet |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu | interdits secrets, GitOps, runtime |
| `AI_MEMORY/DOCUMENT_MAP.md` | relu | cartographie docs |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu | standard PH/CE |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | relu | modele prompt canonique |

## Preflight

| check | resultat | verdict |
| --- | --- | --- |
| bastion | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` presente | OK |
| IPv4 interdite | `51.159.99.247` absente | OK |
| UTC | `2026-06-02T08:23:30Z` | OK |
| kube context | `kubernetes-admin@kubernetes` | OK |

## Repos

| repo | branche | HEAD | origin | ahead/behind | dirty | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | `main` | `da4f217961ea` | `da4f217961ea` | `0/0` | clean avant rapport | OK |
| keybuzz-api | `ph147.4/source-of-truth` | `76483e3a0e10` | `76483e3a0e10` | `0/0` | suppressions `dist/` preexistantes | OK, non touche |

## Runtime baseline

| surface | resultat | verdict |
| --- | --- | --- |
| API DEV spec image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev` | OK |
| API DEV pod digest | `sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996` | OK |
| API DEV pod | ready `True`, restarts `0`, generation `501/501` | OK |
| API PROD spec image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod` | OK read-only |
| API PROD pod digest | `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | OK read-only |
| monitoring-alerts runtime | image `curlimages/curl:8.7.1`, schedule `*/2 * * * *`, suspend `False` | OK, ancien runtime |

## Preuves PH-21.28 a PH-21.32

| Phase | preuve | valeur | impact PH-21.33 |
| --- | --- | --- | --- |
| PH-21.28 | endpoint API | `GET /internal/monitoring/llm-provider-credit?windowSeconds=900` | cible watcher |
| PH-21.28 | headers acceptes | `X-KeyBuzz-Monitor-Token`, `X-Internal-Token`, `Authorization: Bearer` | watcher doit utiliser le header dedie |
| PH-21.28 | envs API acceptees | `LLM_PROVIDER_CREDIT_MONITOR_TOKEN`, `KEYBUZZ_MONITORING_INTERNAL_TOKEN`, `KEYBUZZ_INTERNAL_PROXY_TOKEN`, `AD_SPEND_SYNC_INTERNAL_TOKEN` | cartographie requise |
| PH-21.28 | signal DB | `ai_usage.error_code='PROVIDER_CREDIT_EXHAUSTED'` | pas de fake event |
| PH-21.28 | watcher source | `LLM_PROVIDER_CREDIT_DRY_RUN=true`, `LLM_PROVIDER_CREDIT_LOG_ONLY=true` | activation progressive |
| PH-21.28 | secretRef watcher | `monitoring-llm-provider-credit-token`, key `token`, `optional: true` | secret dedie deja prevu |
| PH-21.31 | API DEV runtime | image `v3.5.263`, digest cible | endpoint deploye |
| PH-21.32 | endpoint sans token | `403` | endpoint present et protege |
| PH-21.32 | secret watcher | absent par nom | materialisation future requise |
| PH-21.32 | monitoring-alerts | aucun marker runtime `LLM_PROVIDER_CREDIT` | watcher non active |

## Cartographie API DEV token envs

Inspection runtime Deployment et manifest GitOps. Aucune valeur affichee.

| env var | presente API DEV | source type | secret name | secret key | valeur affichee ? | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | non | absent |  |  | non | manque pour secret dedie |
| `KEYBUZZ_MONITORING_INTERNAL_TOKEN` | non | absent |  |  | non | absent |
| `KEYBUZZ_INTERNAL_PROXY_TOKEN` | non | absent |  |  | non | absent |
| `AD_SPEND_SYNC_INTERNAL_TOKEN` | oui | `secretKeyRef` | `keybuzz-internal-tokens` | `AD_SPEND_SYNC_INTERNAL_TOKEN` | non | existant mais non dedie |

Conclusion DEV: l'API DEV possede deja un token interne accepte, mais il est scoped AD spend.
Le CronJob `monitoring-alerts` ne peut pas le referencer directement car il tourne dans
`vault-management` et les Secrets Kubernetes sont namespaced.

## Cartographie API PROD token envs

Verification read-only minimale pour symetrie future. Aucune valeur affichee.

| env var | presente API PROD | source type | secret name | secret key | valeur affichee ? | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | non | absent |  |  | non | absent |
| `KEYBUZZ_MONITORING_INTERNAL_TOKEN` | non | absent |  |  | non | absent |
| `KEYBUZZ_INTERNAL_PROXY_TOKEN` | oui | inline | `INLINE_VALUE_REDACTED` |  | non | dette preexistante, non touchee |
| `AD_SPEND_SYNC_INTERNAL_TOKEN` | oui | `secretKeyRef` | `keybuzz-internal-tokens` | `AD_SPEND_SYNC_INTERNAL_TOKEN` | non | existant, non dedie |

Conclusion PROD: aucun changement PROD. La presence d'une env inline redacted en PROD est une
dette de hardening separee, hors scope PH-21.33, et ne doit pas servir de modele DEV.

## Cartographie monitoring-alerts

| champ monitoring-alerts | valeur | source | verdict |
| --- | --- | --- | --- |
| namespace runtime | `vault-management` | CronJob runtime | OK |
| schedule runtime | `*/2 * * * *` | CronJob runtime | OK |
| image runtime | `curlimages/curl:8.7.1` | CronJob runtime | OK |
| service account runtime | `keybuzz-monitor` | CronJob runtime | OK |
| envs `LLM_PROVIDER_CREDIT_*` runtime | absentes | CronJob runtime | watcher non active |
| envs `LLM_PROVIDER_CREDIT_*` source | presentes dans manifest | GitOps source | pret pour apply futur |
| `LLM_PROVIDER_CREDIT_TOKEN` source | `secretKeyRef:monitoring-llm-provider-credit-token:token:optional=True` | GitOps source | OK sans valeur |
| debounce source | ConfigMap `monitoring-alert-state` namespace `vault-management` | GitOps source | OK |
| header source | `X-KeyBuzz-Monitor-Token` | GitOps source | OK |
| dry-run/log-only source | valeurs inline redacted | GitOps source | OK |

| objet K8s | namespace | existe | metadata-only | verdict |
| --- | --- | --- | --- | --- |
| ConfigMap `monitoring-alert-state` | `vault-management` | non | oui | OK, pas requis en dry-run |
| Secret `monitoring-llm-provider-credit-token` | `vault-management` | non | oui | dette attendue |

## Audit patterns de secret

| pattern | fichier/source | usage | applicable PH-21.33 | risque |
| --- | --- | --- | --- | --- |
| `ClusterSecretStore vault-backend` | runtime ExternalSecret metadata | store valide ReadWrite | oui | action hors Git requise pour valeur |
| ExternalSecret API DEV | `k8s/keybuzz-api-dev/externalsecret-*.yaml` | materialisation de Secrets API | oui | besoin d'un manifest dedie ou d'une extension cible |
| ExternalSecret API PROD | `k8s/keybuzz-api-prod/externalsecret-*.yaml` | symetrie future | non en PH-21.33 | PROD interdit |
| `keybuzz-internal-tokens` API DEV | `k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml` | token interne existant | reference possible mais non recommandee | scope trop large/non dedie |
| `secretKeyRef` manifests | `k8s/keybuzz-api-dev/deployment.yaml`, `k8s/monitoring-alerts/cronjob.yaml` | injection env depuis Secret | oui | ne jamais afficher valeurs |
| ExternalSecret `vault-management` | non observe pour ce besoin | nouveau besoin watcher | oui en phase future | verifier namespace/RBAC avant apply |

## Options de design

| option | prerequis | mutations futures | exposition secret | complexite | recommandation |
| --- | --- | --- | --- | --- | --- |
| Option A - Reutiliser le token API existant | utiliser `AD_SPEND_SYNC_INTERNAL_TOKEN` deja accepte par API DEV | creer/synchroniser une copie dans `vault-management` ou changer le watcher | valeur non affichee possible, mais scope reutilise | faible technique, risque produit | Non recommandee |
| Option B - Secret dedie watcher + injection API DEV | secret dedie `monitoring-llm-provider-credit-token`, key `token` | env API DEV + Secret watcher + apply GitOps | faible si ExternalSecret et aucun log valeur | moyenne | Recommandee avec Option C |
| Option C - ExternalSecret / secret manager | `vault-backend` valide et pattern deja utilise | ExternalSecrets dans `keybuzz-api-dev` et `vault-management` | faible, aucune valeur en Git | moyenne | Recommandee comme mecanisme |

Decision: appliquer Option B + Option C. Ne pas reutiliser le token AD spend. Ne pas copier de
valeur depuis un Secret existant. Ne pas demander a Ludovic de coller une valeur dans le chat.

## Design recommande

Ce qui est prouve:

- API DEV accepte `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` en priorite.
- API DEV a uniquement `AD_SPEND_SYNC_INTERNAL_TOKEN` parmi les envs acceptees.
- monitoring-alerts source attend deja `monitoring-llm-provider-credit-token`, key `token`,
  dans `vault-management`.
- ExternalSecret/Vault est le pattern infra existant et `vault-backend` est valide.
- Le Secret watcher est absent aujourd'hui et aucun token n'a ete lu.

Ce qui est infere:

- Un secret dedie peut etre synchronise dans deux namespaces via deux ExternalSecrets pointant
  vers la meme entree de secret manager, sans stocker la valeur en Git.
- Le namespace `vault-management` devra etre verifie en phase patch/apply pour compatibilite
  ExternalSecret, car aucun ExternalSecret watcher existant n'a ete observe dans ce namespace.

Ce qui reste a decider par Ludovic:

- Valider la creation d'une entree dediee dans le secret manager pour ce token.
- Valider le nom de chemin remote dans le secret manager si le patch ExternalSecret doit le
  declarer.
- Valider que PH-21.34 reste DEV uniquement.

Design cible DEV:

| element | valeur cible | justification |
| --- | --- | --- |
| Secret API DEV | `monitoring-llm-provider-credit-token` | secret dedie, namespaced |
| Secret watcher | `monitoring-llm-provider-credit-token` | deja attendu par source monitoring-alerts |
| key | `token` | deja attendu par source monitoring-alerts |
| namespace API | `keybuzz-api-dev` | API Deployment |
| namespace watcher | `vault-management` | CronJob monitoring-alerts |
| env API cible | `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` | priorite 1 de l'endpoint |
| env watcher cible | `LLM_PROVIDER_CREDIT_TOKEN` | source watcher PH-21.28 |
| header watcher | `X-KeyBuzz-Monitor-Token` | header dedie |
| mode initial watcher | dry-run/log-only | aucun Slack/email |

## Sequence future proposee

1. `PH-21.34` - SOURCE/CONFIG PATCH DEV: ajouter les manifests ExternalSecret DEV dedies et
   l'env API DEV `LLM_PROVIDER_CREDIT_MONITOR_TOKEN` via `secretKeyRef`. Verifier que
   monitoring-alerts garde le secretRef optionnel. Aucun apply.
2. `PH-21.35` - MATERIALISATION SECRET DEV: materialiser la valeur dans le secret manager,
   user-assisted si necessaire, sans affichage, sans copie dans le chat, sans Secret K8s manuel
   si ExternalSecret est retenu.
3. `PH-21.36` - APPLY GITOPS DEV: appliquer uniquement les ExternalSecrets DEV et l'API DEV,
   puis verifier rollout API. Ne pas activer monitoring-alerts si l'endpoint authentifie n'est
   pas encore verifie.
4. `PH-21.37` - READONLY VERIFY AUTH ENDPOINT DEV: verifier metadata-only que les Secrets
   existent, puis appeler l'endpoint depuis le pod API avec l'env pod, sans afficher le token,
   sortie limitee au status HTTP et aux agregats safe.
5. `PH-21.38` - APPLY/ACTIVATE WATCHER DEV DRY-RUN LOG-ONLY: appliquer monitoring-alerts en
   DEV-first, dry-run/log-only, pas Slack/email.
6. `PH-21.39` - READONLY VERIFY WATCHER DEV: verifier logs, absence d'effet de bord, pas de
   DB/LLM/event/Slack/email et aucun fake incident.

Fusion de phases non recommandee: materialisation, apply API, verification endpoint et
activation watcher doivent rester separes pour eviter une activation avec token absent ou
mauvais scope.

## Verification endpoint authentifiee future sans afficher le token

Methode recommandee en phase future seulement:

- ne pas lire `.data` de Secret;
- ne pas afficher l'env;
- ne pas executer `printenv`;
- executer depuis le pod API une commande qui utilise la variable d'environnement deja injectee
  et n'affiche que le code HTTP et la reponse aggregatee safe;
- interdire `set -x`;
- filtrer les logs contre toute fuite obvious avant rapport.

Cette methode implique un GET authentifie mais aucune mutation DB et aucun appel LLM.

## Rollback

Rollback GitOps futur, non execute en PH-21.33:

1. Revert du commit manifest qui ajoute l'env API et/ou les ExternalSecrets.
2. Push normal non-force.
3. `kubectl apply -f` uniquement sur les manifests concernes, avec GO explicite.
4. Rollout status API DEV si Deployment touche.
5. Revert monitoring-alerts si le watcher a ete applique.
6. Suppression ou desactivation du Secret dedie uniquement dans une phase explicite dediee,
   sans afficher sa valeur.

Ne jamais rollback API DEV vers une image qui ne contient pas l'endpoint si le watcher est
active et depend de lui.

## STOP conditions futures

- bastion ou IP non conforme;
- repo dirty inattendu;
- ExternalSecret non synchronise ou store invalide;
- Secret watcher absent apres materialisation;
- API DEV n'a pas `LLM_PROVIDER_CREDIT_MONITOR_TOKEN`;
- endpoint authentifie ne retourne pas un status attendu;
- token ou valeur env affichee dans un log;
- watcher quitte dry-run/log-only sans GO explicite;
- Slack/email appele avant phase d'activation explicite;
- incident `PROVIDER_CREDIT_EXHAUSTED` simule;
- PROD touche sans GO explicite.

## No fake metrics / no fake events

| interdit | statut PH-21.33 |
| --- | --- |
| fake `ai_usage` | non effectue |
| fake `PROVIDER_CREDIT_EXHAUSTED` | non effectue |
| appel LLM | non effectue |
| trigger CronJob | non effectue |
| event tracking | non effectue |
| Slack/email | non effectue |
| appel endpoint authentifie | non effectue |

## AI feature parity / anti-regression

| Feature | Source de verite | Impact PH-21.33 | Risque | Verdict |
| --- | --- | --- | --- | --- |
| AI Assist | PH-21.31/21.32 marker audit | aucun changement | aucun | OK |
| Autopilot | PH-21.31/21.32 marker audit | aucun changement | aucun | OK |
| Returns Analysis | PH-21.31/21.32 marker audit | aucun changement | aucun | OK |
| KBActions | PH-21.32 counters delta 0 | aucun debit | aucun | OK |
| Signal provider credit | PH-21.28 endpoint design | reste classification depuis `ai_usage` | mauvais token futur | controle par secret dedie |
| Logs watcher | PH-21.28 response safe | aucune exposition raw content | fuite si `set -x` futur | STOP condition |

## Non-regression

| surface | attendu | observe | verdict |
| --- | --- | --- | --- |
| API DEV runtime | `v3.5.263` + digest PH-21.31 | conforme | OK |
| API PROD runtime | `v3.5.262` + digest PH-21.24 | conforme read-only | OK |
| monitoring-alerts runtime | pas encore active LLM provider credit | conforme | OK |
| Secret watcher | absent | absent metadata-only | OK |
| ConfigMap state | non requis maintenant | absent metadata-only | OK |
| DB | aucune mutation | non touchee | OK |
| LLM | aucun appel | non touche | OK |
| Slack/email | aucun envoi | non touche | OK |
| Linear | aucun appel | non touche | OK |

## Gaps et dettes

| dette | impact | recommandation |
| --- | --- | --- |
| Valeur dediee non materialisee | watcher ne peut pas appeler l'endpoint | PH-21.35 user-assisted/ExternalSecret |
| API DEV n'a pas encore l'env dediee | endpoint accepterait seulement le token AD spend | PH-21.34 patch env API DEV |
| watcher runtime ancien | source non appliquee | PH-21.38 apres verification endpoint |
| ExternalSecret `vault-management` absent pour ce besoin | compatibilite a confirmer | PH-21.34/21.36 |
| env inline redacted observee en PROD | dette hardening separee | ne pas repliquer, traiter plus tard |

## Texte Linear prepare, non poste

PH-21.33 a concu la strategie sure pour le secret runtime du watcher LLM provider credit DEV.
L'API DEV v3.5.263 expose l'endpoint et refuse sans token. API DEV ne possede pas encore
`LLM_PROVIDER_CREDIT_MONITOR_TOKEN`; elle possede seulement un token interne AD spend non dedie.
Le watcher source attend deja `monitoring-llm-provider-credit-token` key `token` en
`vault-management`, optionnel, et le runtime monitoring-alerts n'est pas active. Recommandation:
creer un secret dedie via ExternalSecret/Vault, synchronise dans `keybuzz-api-dev` et
`vault-management`, puis phases separees patch, materialisation, apply API, verify endpoint,
activation dry-run/log-only. Aucun secret lu/cree, aucun token affiche, aucune DB/LLM/event/alert.

## Rapport et retour CE

Remote report:

```text
/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.33-READONLY-DESIGN-LLM-PROVIDER-CREDIT-WATCHER-SECRET-DEV-01.md
```

Local return:

```text
C:\DEV\KeyBuzz\tmp\PH-21.33_CE_RETURN.md
```

## Prochaine phrase GO recommandee

`GO SOURCE CONFIG PATCH LLM PROVIDER CREDIT WATCHER SECRET DEV PH-SAAS-T8.12AS.21.34`

STOP.
