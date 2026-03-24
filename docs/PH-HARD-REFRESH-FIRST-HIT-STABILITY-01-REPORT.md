# PH-HARD-REFRESH-FIRST-HIT-STABILITY-01 — Rapport

**Date** : 23 mars 2026
**Phase** : PH-HARD-REFRESH-FIRST-HIT-STABILITY-01
**Type** : Correction infrastructure — zero-downtime rollout
**Environnements** : DEV + PROD

---

## Probleme observe

Apres reconnexion ou pendant un deploiement, le product owner constate :
- **503 Service Temporarily Unavailable (nginx)** sur le premier chargement
- Affecte toutes les routes internes : `/inbox?id=...`, `/orders`, `/billing`, `/api/*`
- Un simple refresh suffit a retablir la page
- Aggrave par Ctrl+Shift+R (hard refresh)
- Observe en DEV et PROD

---

## Root cause exacte

### Diagnostic des logs nginx ingress

```
17:35:04 GET /billing?_rsc=kprxj                  → 503  upstream: []  0.000s
17:35:04 GET /inbox?id=cmmmkr2xicd1af20cda5cdd1d   → 503  upstream: []  0.000s
17:35:04 GET /api/channel-rules/amazon              → 503  upstream: []  0.000s
17:35:51 GET /orders/ord-mm4frfen-nscy7t            → 503  upstream: []  0.000s
```

**`upstream: []`** = nginx n'a aucun backend disponible. Le pod est absent ou pas pret.

### Cause infrastructure

Les deployments `keybuzz-client` (DEV et PROD) avaient :

| Parametre | Valeur avant | Probleme |
|---|---|---|
| **readinessProbe** | **AUCUNE** | K8s ne sait pas quand le pod est pret |
| **livenessProbe** | **AUCUNE** | K8s ne detecte pas les crashes |
| **maxUnavailable** | 25% (= 1 pod avec 1 replica) | L'ancien pod est tue AVANT que le nouveau soit pret |
| **minReadySeconds** | 0 | Pas de buffer de securite |

Avec 1 replica et `maxUnavailable: 25%` :
1. K8s tue le vieux pod immediatement (pas de probe a attendre)
2. Le nouveau pod demarre mais Next.js prend ~5-10s a initialiser
3. Pendant cette fenetre : **aucun upstream** → nginx renvoie 503

C'est un probleme **purement infrastructure**, pas applicatif.

---

## Correction appliquee

### Changements dans les manifests (DEV + PROD)

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0    # ancien: 25% → nouveau pod DOIT etre pret avant suppression ancien
      maxSurge: 1           # permet 2 pods simultanes pendant la transition
  minReadySeconds: 5        # buffer de 5s apres readiness avant progression
  template:
    spec:
      containers:
        - readinessProbe:
            tcpSocket:
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
            successThreshold: 1
          livenessProbe:
            tcpSocket:
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 3
```

### Impact

| Parametre | Avant | Apres |
|---|---|---|
| readinessProbe | aucune | tcpSocket:3000, delay=5s, period=5s |
| livenessProbe | aucune | tcpSocket:3000, delay=15s, period=20s |
| maxUnavailable | 25% (= 1) | **0** |
| maxSurge | 25% (= 0) | **1** |
| minReadySeconds | 0 | **5** |

### Comportement apres correction

1. Nouveau pod demarre a cote de l'ancien
2. K8s attend que le nouveau pod passe la readiness probe (tcpSocket:3000)
3. Apres 5s supplementaires (`minReadySeconds`), le nouveau pod est declare Ready
4. ALORS seulement l'ancien pod est termine
5. **Zero fenetre sans backend** = zero 503

---

## Fichiers modifies

| Fichier | Changement |
|---|---|
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Ajout readiness/liveness probes + strategy zero-downtime |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Ajout readiness/liveness probes + strategy zero-downtime |

**Aucun fichier de code applicatif modifie.**
**Aucun build Docker necessaire.**

---

## Validation DEV

### Test zero-downtime (rollout restart pendant requetes)

```
t+2s:  HTTP=200  running=1  total=2  ← nouveau pod demarre, ancien sert
t+4s:  HTTP=200  running=2  total=2  ← les deux servent
t+6s:  HTTP=200  running=2  total=2
t+8s:  HTTP=200  running=2  total=2
t+10s: HTTP=200  running=2  total=2
t+12s: HTTP=200  running=1  total=2  ← ancien termine
t+14s: HTTP=200  running=1  total=1  ← stabilise
...
t+30s: HTTP=200  running=1  total=1
```

**15/15 requetes = HTTP 200. Zero 503 pendant le rollout.**

### Test pages (first hit + hard refresh)

| Route | Status | Temps |
|---|---|---|
| `/login` | 200 | 0.197s |
| `/inbox?id=cmmmkr2xicd1af20cda5cdd1d` | 200 | 0.368s |
| `/dashboard` | 200 | 0.139s |
| `/orders` | 200 | 0.222s |
| `/ai-dashboard` | 200 | 0.142s |
| `/api/auth/providers` | 200 | 0.144s |
| Hard refresh `/inbox?id=...` (no-cache) | 200 | 0.136s |

### Verdicts DEV

- **FIRST HIT DEV = OK**
- **HARD REFRESH DEV = OK**
- **DEEP LINK DEV = OK**

---

## Validation PROD

### Test zero-downtime (rollout restart pendant requetes)

```
t+2s:  HTTP=200  running=1  total=2  ← nouveau pod demarre
t+4-16s: HTTP=200 running=1  ← ancien sert toujours
t+18s: HTTP=200  running=2  total=2  ← nouveau Ready
t+20-26s: HTTP=200 running=2  ← les deux servent
t+28s: HTTP=200  running=1  total=1  ← ancien termine
t+30s: HTTP=200  running=1  total=1  ← stabilise
```

**15/15 requetes = HTTP 200. Zero 503 pendant le rollout PROD.**

### Test pages

| Route | Status | Temps |
|---|---|---|
| `/login` | 200 | 0.572s |
| `/inbox` | 200 | 0.392s |
| `/dashboard` | 200 | 0.137s |
| `/orders` | 200 | 0.156s |
| `/ai-dashboard` | 200 | 0.213s |
| `/api/auth/providers` | 200 | 0.137s |
| Hard refresh `/inbox` (no-cache) | 200 | 0.146s |

### Non-regression

| Service | Status |
|---|---|
| API health | `{"status":"ok"}` |
| Amazon status | `connected: true, CONNECTED` |
| Login | 200 |
| Dashboard | 200 |
| Orders | 200 |
| AI Dashboard | 200 |

### Verdicts PROD

- **FIRST HIT PROD = OK**
- **HARD REFRESH PROD = OK**
- **DEEP LINK PROD = OK**

---

## Images deployees

Aucune image modifiee — memes images qu'avant, seuls les manifests K8s ont change.

| Env | Image client | Changement |
|---|---|---|
| DEV | `v3.5.77-ph119-role-access-guard-dev` | Inchangee |
| PROD | `v3.5.77-ph119-role-access-guard-prod` | Inchangee |

---

## Rollback

Le rollback est trivial : retirer les probes et la strategy des manifests.
Cependant, **il est fortement deconseille de rollback** car cela reintroduirait les 503 transitoires.

---

## Verdict final

### FIRST HIT AND HARD REFRESH STABILITY FIXED AND VALIDATED

- Root cause identifiee : absence de readiness probe + maxUnavailable:25% + 1 replica
- Correction : readiness/liveness probes + maxUnavailable:0 + minReadySeconds:5
- Zero build Docker necessaire
- Zero code applicatif modifie
- Valide en DEV : 15/15 HTTP 200 pendant rollout
- Valide en PROD : 15/15 HTTP 200 pendant rollout
- Non-regression confirmee : toutes les pages et API fonctionnent
