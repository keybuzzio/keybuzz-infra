# PH-VAULT-TOKEN-AUTO-ROTATION-01 — Automatisation renouvellement tokens Vault

> Date : 10 avril 2026
> Statut : DEPLOYE et VALIDE
> Environnement : INFRA (DEV + PROD)

---

## Objectif

Automatiser le renouvellement des tokens Vault applicatifs pour eliminer tout risque de panne liee a l'expiration de tokens (incident PH-VAULT-RECOVERY-01).

---

## Contexte

Apres la recovery Vault du 10 avril 2026, deux tokens applicatifs periodiques (768h / 32 jours) ont ete crees et injectes dans K8s. Sans mecanisme de renouvellement automatique, ces tokens expireraient le 12 mai 2026, causant une nouvelle panne Amazon/Shopify/API.

---

## Architecture deployee

### Namespace

`vault-management` — namespace dedie a la gestion des tokens Vault.

### Ressources K8s creees

| Ressource | Nom | Description |
|---|---|---|
| Namespace | `vault-management` | Namespace isole |
| ServiceAccount | `vault-token-renewer` | Identite du CronJob |
| ClusterRole | `vault-token-renewer` | Permissions cross-namespace |
| ClusterRoleBinding | `vault-token-renewer` | Lien SA ↔ ClusterRole |
| Secret | `vault-admin-token` | Root token Vault (cree manuellement, JAMAIS commit) |
| ConfigMap | `vault-renew-script` | Script de renouvellement |
| CronJob | `vault-token-renew` | Execution quotidienne 03:00 UTC |

### Image

`curlimages/curl:8.7.1` — image minimale avec curl, base64, grep, sed.

### RBAC (principe du moindre privilege)

Le ClusterRole autorise uniquement :
- `get` + `patch` sur les secrets : `vault-root-token`, `vault-app-token`, `vault-token`, `vault-admin-token`
- `get` + `patch` sur les deployments : `keybuzz-api`, `keybuzz-backend`, `keybuzz-outbound-worker`, `amazon-orders-worker`, `amazon-items-worker`

---

## Cartographie des tokens

### TOKEN1 — API + Amazon workers

| Deployment | Secret K8s | Cle |
|---|---|---|
| keybuzz-api (DEV+PROD) | `vault-root-token` | `VAULT_TOKEN` |
| amazon-orders-worker (DEV+PROD) | `vault-token` | `VAULT_TOKEN` |
| amazon-items-worker (DEV+PROD) | `vault-token` | `VAULT_TOKEN` |

Propagation en cas de recreation : 8 secrets patches (vault-root-token + vault-app-token + vault-token dans 4 namespaces).

### TOKEN2 — Backend

| Deployment | Secret K8s | Cle |
|---|---|---|
| keybuzz-backend (DEV+PROD) | `vault-app-token` | `token` |

Propagation en cas de recreation : 4 secrets patches (vault-app-token[token] dans 4 namespaces).

### Policies Vault

Chaque token app utilise les policies :
- `keybuzz-app-read` : lecture/liste `secret/data/keybuzz/*` + ecriture tenant credentials
- `keybuzz-backend-rw` : creation/lecture/mise a jour `secret/data/keybuzz/*`

---

## Logique du CronJob

### Schedule

`0 3 * * *` — tous les jours a 03:00 UTC (05:00 CET).

### Algorithme

```
1. Lire root token depuis vault-management/vault-admin-token
2. Verifier validite root token via Vault API
3. Pour chaque groupe de tokens (API, Backend):
   a. Lire le token depuis le K8s secret de reference
   b. Verifier le TTL via Vault API /auth/token/lookup-self
   c. Si TTL > 7 jours → rien a faire (log OK)
   d. Si TTL < 7 jours → vault token renew
   e. Si renew echoue → creer nouveau token + patcher tous les K8s secrets
4. Si un token a ete recree → restart tous les deployments affectes
5. Log resume (renewed / recreated / errors)
```

### Seuils

| Parametre | Valeur | Description |
|---|---|---|
| RENEW_THRESHOLD_SECONDS | 604800 (7 jours) | Seuil de declenchement du renouvellement |
| TOKEN_PERIOD | 768h (32 jours) | Periode du token periodique |
| Schedule | 03:00 UTC quotidien | Frequence de verification |

### Fallback securise

Si le `vault token renew` echoue (token revoque, corrompu, etc.), le script :
1. Cree un NOUVEAU token via `vault token create`
2. Patche TOUS les K8s secrets concernes via l'API K8s
3. Redemarre TOUS les deployments affectes via annotation restart
4. Logue le detail de chaque operation

---

## Monitoring

### Logs

Tous les logs sont emis sur stdout et collectes par Promtail/Loki :

```bash
# Voir les logs du dernier run
kubectl logs -n vault-management -l app.kubernetes.io/component=vault-token-renew --tail=50

# Historique des jobs
kubectl get jobs -n vault-management
```

### Format des logs

```
[2026-04-10 20:32:53 UTC] === VAULT TOKEN AUTO-ROTATION START ===
[2026-04-10 20:32:53 UTC] VAULT_ADDR: http://vault.default.svc.cluster.local:8200
[2026-04-10 20:32:53 UTC] THRESHOLD: 604800s (7d)
[2026-04-10 20:32:54 UTC] OK: Root token read (28 chars)
[2026-04-10 20:32:54 UTC] OK: Root token valid (ttl=0, 0=never)
[2026-04-10 20:32:55 UTC] TOKEN1: ttl=2762540s (767h)
[2026-04-10 20:32:55 UTC] OK: Healthy
[2026-04-10 20:32:56 UTC] TOKEN2: ttl=2762757s (767h)
[2026-04-10 20:32:56 UTC] OK: Healthy
[2026-04-10 20:32:56 UTC] === COMPLETE: renewed=0 recreated=0 errors=0 ===
```

### Alerting

Le CronJob a `failedJobsHistoryLimit: 5`. Un echec apparait dans les events K8s et peut etre capte par les alertes existantes (`PodCrashLoop`, job failed events).

---

## Fichiers GitOps

```
keybuzz-infra/k8s/vault-token-renew/
  rbac.yaml                    # Namespace + SA + ClusterRole + Binding
  configmap-script.yaml        # Script vault-renew-tokens.sh
  cronjob.yaml                 # CronJob definition
  secret-admin-template.yaml   # Template (JAMAIS commit le token reel)
```

---

## Operations manuelles

### Creer le secret admin (premiere fois ou apres rotation root)

```bash
kubectl create secret generic vault-admin-token \
  --namespace=vault-management \
  --from-literal=token=<ROOT_TOKEN> \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Declencher un run manuel

```bash
kubectl create job --from=cronjob/vault-token-renew vault-renew-manual -n vault-management
```

### Voir les resultats

```bash
kubectl get jobs -n vault-management
POD=$(kubectl get pods -n vault-management -l job-name=vault-renew-manual -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -n vault-management
```

### Rollback

Si le CronJob cause des problemes :

```bash
# Suspendre le CronJob
kubectl patch cronjob vault-token-renew -n vault-management -p '{"spec":{"suspend":true}}'

# Reprendre
kubectl patch cronjob vault-token-renew -n vault-management -p '{"spec":{"suspend":false}}'
```

---

## Validation

### Test manuel (10 avril 2026)

```
Job: vault-token-renew-test5 → STATUS: Complete (1/1)
TOKEN1 TTL: 2762540s (767h) → OK: Healthy
TOKEN2 TTL: 2762757s (767h) → OK: Healthy
Errors: 0 | Renewed: 0 | Recreated: 0
```

### Non-regression

- Aucun pod redemarre (tokens sains, pas de recreation)
- API PROD : vault_read=200
- Backend PROD : vault_read=200
- Amazon import-one : 200 OK
- Amazon workers : Running

---

## Risques residuels

| Risque | Mitigation |
|---|---|
| Root token invalide | Le CronJob echoue avec exit 1 → alerte K8s |
| Vault cluster down | Les tokens existants continuent de fonctionner jusqu'a expiration (32j) |
| RBAC trop restrictif | Les resourceNames sont explicitement listes |
| Image :latest | Image `curlimages/curl:8.7.1` avec tag fixe |

---

## Prochaines ameliorations possibles

1. Alertmanager rule specifique pour les echecs du CronJob
2. Dashboard Grafana pour TTL tokens Vault
3. Migration vers K8s auth (eliminer le root token du CronJob)
4. Token unification (1 seul token partage au lieu de 2)
