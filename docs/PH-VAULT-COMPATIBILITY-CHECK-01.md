# PH-VAULT-COMPATIBILITY-CHECK-01 — Verification compatibilite Vault rotation

> Date : 10 avril 2026
> Statut : AUDIT COMPLET — COMPATIBLE
> Scope : Ecosysteme KeyBuzz complet

---

## Objectif

Verifier que tous les services de l'ecosysteme KeyBuzz sont 100% compatibles avec le nouveau systeme de rotation automatique des tokens Vault (CronJob `vault-token-renew`).

---

## 1. Architecture du systeme de rotation

| Element | Detail |
|---|---|
| CronJob | `vault-token-renew` dans `vault-management` |
| Schedule | `0 3 * * *` (03:00 UTC quotidien) |
| Seuil renouvellement | 604800s (7 jours) |
| Periode tokens | 768h (32 jours) |
| Logique | Check TTL → renew si < 7j → recreate + patch + restart si renew echoue |
| Statut | DEPLOYE, ACTIF, NON SUSPENDU |

### Tokens geres

| Groupe | Token | Secret K8s source | Services consommateurs |
|---|---|---|---|
| TOKEN1 | API + Amazon | `vault-root-token` (VAULT_TOKEN) | keybuzz-api, amazon-orders-worker, amazon-items-worker |
| TOKEN2 | Backend | `vault-app-token` (token) | keybuzz-backend |

---

## 2. Cartographie complete des usages Vault

### Services utilisant Vault directement (token runtime)

| Service | Namespace | Secret K8s | Cle | Couvert CronJob | Restart auto |
|---|---|---|---|---|---|
| **keybuzz-api** | api-prod / api-dev | `vault-root-token` | `VAULT_TOKEN` | OUI | OUI (si recreation) |
| **keybuzz-backend** | backend-prod / backend-dev | `vault-app-token` | `token` | OUI | OUI (si recreation) |
| **amazon-orders-worker** | backend-prod / backend-dev | `vault-token` | `VAULT_TOKEN` | OUI | OUI (si recreation) |
| **amazon-items-worker** | backend-prod / backend-dev | `vault-token` | `VAULT_TOKEN` | OUI | OUI (si recreation) |

### Services utilisant Vault indirectement (via External Secrets Operator)

| Service | Methode | Impact rotation token | Compatible |
|---|---|---|---|
| **keybuzz-client** | ESO → K8s secrets (auth, postgres) | Aucun — ESO utilise sa propre auth | OUI |
| **keybuzz-admin-v2** | ESO → K8s secrets (bootstrap, postgres) | Aucun | OUI |
| **keybuzz-studio** | K8s secret (DATABASE_URL) | Aucun | OUI |
| **litellm** | ESO → K8s secrets | Aucun | OUI |
| **seller-api** | ESO cree `seller-api-vault` | Secret non reference par deployment — inactif | OUI |

### Services sans aucun lien Vault

| Service | Statut |
|---|---|
| **keybuzz-website** | Pas de Vault |
| **keybuzz-outbound-worker** | Pas de VAULT_TOKEN en env |
| **minio** | Pas de Vault |
| **backfill-scheduler** | CA cert Vault uniquement (pas de token) |

---

## 3. Compatibilite rotation

### Modele d'injection

Tous les services qui consomment un token Vault le recoivent via **variable d'environnement** injectee au demarrage du pod depuis un K8s Secret. Le token est **cache en memoire** dans `process.env` pour la duree du processus Node.js.

### Comportement lors d'une rotation

| Scenario | Action CronJob | Impact service |
|---|---|---|
| TTL > 7 jours | Aucune | Aucun |
| TTL < 7 jours, renew OK | `vault token renew` | Aucun — le token est le meme, TTL prolonge |
| TTL < 7 jours, renew KO | Recreate + patch secrets + restart deployments | Downtime bref (~10s rolling restart) |
| Token invalide/revoque | Recreate + patch secrets + restart deployments | Downtime bref (~10s rolling restart) |

### Verdict compatibilite par service

| Service | Compatible rotation | Supporte sans restart | Necessite restart si recreation | Couvert CronJob |
|---|---|---|---|---|
| keybuzz-api | OUI | OUI (renew) | OUI (recreate → restart auto) | OUI |
| keybuzz-backend | OUI | OUI (renew) | OUI (recreate → restart auto) | OUI |
| amazon-orders-worker | OUI | OUI (renew) | OUI (recreate → restart auto) | OUI |
| amazon-items-worker | OUI | OUI (renew) | OUI (recreate → restart auto) | OUI |
| keybuzz-outbound-worker | N/A | N/A | N/A (pas de Vault) | Restart inclus (redondant) |
| keybuzz-client | OUI | N/A | N/A | N/A (ESO) |
| keybuzz-admin-v2 | OUI | N/A | N/A | N/A (ESO) |
| keybuzz-studio | OUI | N/A | N/A | N/A |
| keybuzz-website | OUI | N/A | N/A | N/A |

---

## 4. Risques identifies

### Risques critiques

**Aucun** risque critique detecte.

### Risques mineurs

| Risque | Severite | Detail | Recommandation |
|---|---|---|---|
| Restart outbound-worker inutile | FAIBLE | Le CronJob restart `keybuzz-outbound-worker` lors d'une recreation TOKEN1, mais ce service n'utilise pas VAULT_TOKEN | Retirer de la liste des restarts (optimisation, pas urgent) |
| vault-emergency-token orphelin | FAIBLE | Secret `vault-emergency-token` dans `keybuzz-api-dev`, cree le 2026-02-06, non utilise | Supprimer (`kubectl delete secret vault-emergency-token -n keybuzz-api-dev`) |
| seller-api ESO non cable | INFO | L'ExternalSecret `seller-api-vault` cree un secret `VAULT_TOKEN` mais le deployment ne le consomme pas | A cAbler si le seller-api doit un jour lire Vault directement |
| Reloader non deploye partout | INFO | `reloader.stakater.com/auto: true` uniquement sur outbound-worker DEV | Non necessaire — le CronJob gere les restarts explicitement |

### Verifications hardcode

| Element | Resultat |
|---|---|
| Token `hvs.*` dans le code source | NON — uniquement dans des rapports/docs |
| `VAULT_TOKEN=` dans des `.env` | NON |
| Token stocke localement (fichier) | NON |
| Token non renouvelable | NON — tous periodiques (768h, renewable) |
| Dependance ancien Vault | NON |

---

## 5. Test reel

### Test CronJob manuel

```
Job: vault-compat-test-01
Status: Complete (1/1)
Duration: 9s

Logs:
[2026-04-10 20:44:35 UTC] === VAULT TOKEN AUTO-ROTATION START ===
[2026-04-10 20:44:35 UTC] VAULT_ADDR: http://vault.default.svc.cluster.local:8200
[2026-04-10 20:44:35 UTC] THRESHOLD: 604800s (7d)
[2026-04-10 20:44:36 UTC] OK: Root token read (28 chars)
[2026-04-10 20:44:36 UTC] OK: Root token valid (ttl=0, 0=never)
[2026-04-10 20:44:38 UTC] TOKEN1: ttl=2761838s (767h) → OK: Healthy
[2026-04-10 20:44:39 UTC] TOKEN2: ttl=2762055s (767h) → OK: Healthy
[2026-04-10 20:44:39 UTC] === COMPLETE: renewed=0 recreated=0 errors=0 ===
```

### Etat services apres test

| Service | Namespace | Status | Restarts |
|---|---|---|---|
| keybuzz-api | api-prod | Running | 0 |
| keybuzz-api | api-dev | Running | 0 |
| keybuzz-backend | backend-prod | Running | 0 |
| keybuzz-backend | backend-dev | Running | 0 |
| amazon-orders-worker | backend-prod | Running | 0 |
| amazon-items-worker | backend-prod | Running | 0 |
| keybuzz-outbound-worker | api-prod | Running | 0 |
| keybuzz-admin-v2 | admin-prod | Running | 0 |
| keybuzz-client | client-prod | Running | 0 |
| keybuzz-studio | studio-prod | Running | 0 |

### External Secrets Operator

- **30/30 ExternalSecrets** : `SecretSynced` = `True`
- ClusterSecretStore `vault-backend` : operationnel

---

## 6. Corrections appliquees

**Aucune correction necessaire.** Le systeme est compatible tel quel.

### Recommandations non bloquantes (a planifier)

1. **Supprimer** `vault-emergency-token` dans `keybuzz-api-dev` (orphelin)
2. **Retirer** `keybuzz-outbound-worker` de la liste des restarts du CronJob (optimisation)
3. **Cabler** `seller-api-vault` dans le deployment si le seller-api doit lire Vault un jour

---

## 7. Verdict

### COMPATIBLE — Aucun risque de panne lie a la rotation des tokens Vault

| Critere | Resultat |
|---|---|
| Tokens rotatifs | OUI — 768h periodiques, renouvelables |
| Renouvellement automatique | OUI — CronJob quotidien 03:00 UTC |
| Fallback recreation | OUI — recreate + patch secrets + restart |
| Aucun secret hardcode | OUI |
| Multi-tenant strict | OUI — memes tokens, isolation par policy Vault |
| Services non-Vault isoles | OUI — admin, client, studio, website |
| ESO independant | OUI — 30/30 synced, auth separee |
| Rollback possible | OUI — `kubectl patch cronjob ... suspend=true` |

### Prochaine expiration naturelle

TOKEN1 et TOKEN2 ont ete crees le 10 avril 2026 avec TTL 768h (32 jours).
- **Expiration sans renouvellement** : ~12 mai 2026
- **Premier renouvellement automatique** : ~5 mai 2026 (quand TTL < 7j)
- **Le CronJob verifie chaque jour a 03:00 UTC** — aucune intervention manuelle requise

---

## 8. Fichiers de reference

| Fichier | Role |
|---|---|
| `k8s/vault-token-renew/configmap-script.yaml` | Script de renouvellement |
| `k8s/vault-token-renew/cronjob.yaml` | Definition CronJob |
| `k8s/vault-token-renew/rbac.yaml` | RBAC (SA + ClusterRole) |
| `k8s/vault-token-renew/secret-admin-template.yaml` | Template secret admin |
| `docs/PH-VAULT-TOKEN-AUTO-ROTATION-01.md` | Rapport deploiement rotation |
