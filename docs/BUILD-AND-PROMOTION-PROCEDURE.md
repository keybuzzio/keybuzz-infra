# Procedure Build & Promotion — KeyBuzz V3

> Derniere mise a jour : 2026-04-06 (PH143-I)
> Ce document decrit la procedure obligatoire avant tout build et toute promotion PROD.

---

## 1. AVANT CHAQUE BUILD

### Etape 1 : Verifier que le repo est propre

```bash
cd /opt/keybuzz/keybuzz-infra/scripts
bash assert-git-committed.sh
```

**Resultat attendu** : `TOUS LES REPOS PROPRES — BUILD AUTORISE`

Si le script retourne `BUILD INTERDIT`, corriger les fichiers non commites avant de continuer.

### Etape 2 : Builder depuis Git (pas depuis le bastion)

```bash
cd /opt/keybuzz/keybuzz-infra/scripts
bash build-from-git.sh dev v3.5.XXX-feature-name-dev rebuild/ph143-client
```

Ce script :
- Clone proprement depuis GitHub
- Verifie que le clone est clean
- Injecte le Git SHA dans le build
- Utilise `docker build --no-cache`
- Nettoie apres le build

### Etape 3 : Pousser et deployer

```bash
docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 2. AVANT TOUTE PROMOTION PROD

### Etape 1 : Executer pre-prod-check-v2.sh

```bash
cd /opt/keybuzz/keybuzz-infra/scripts
bash pre-prod-check-v2.sh dev
```

**Resultat attendu** : `ALL GREEN — PROD PUSH AUTHORIZED`

Ce script verifie :
- A. Git propre (client + API)
- B. Health externe (API + client)
- C. 15 checks internes API (endpoints + DB)
- D. 6 routes compilees client

### Etape 2 : Validation humaine

**STOP OBLIGATOIRE** : Attendre la validation explicite avant toute promotion PROD.

### Etape 3 : Builder la version PROD

```bash
bash build-from-git.sh prod v3.5.XXX-feature-name-prod main
```

**Important** : Le tag PROD doit finir par `-prod`.

### Etape 4 : Deployer en PROD

```bash
docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

### Etape 5 : Executer pre-prod-check en mode PROD

```bash
bash pre-prod-check-v2.sh prod
```

---

## 3. CE QU'IL NE FAUT JAMAIS FAIRE

1. **JAMAIS** builder depuis le repo bastion (utiliser `build-from-git.sh`)
2. **JAMAIS** utiliser `:latest` comme tag
3. **JAMAIS** pusher en PROD sans `pre-prod-check-v2.sh` ALL GREEN
4. **JAMAIS** pusher en PROD sans validation humaine
5. **JAMAIS** modifier les fichiers sur le bastion sans commit Git
6. **JAMAIS** toucher les secrets dans `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/`

---

## 4. COMMENT VERIFIER QU'IL N'Y A PAS DE DRIFT

### Verification rapide

```bash
bash assert-git-committed.sh
```

### Verification complete

```bash
bash pre-prod-check-v2.sh dev
```

### Verification manuelle du tag deploye

```bash
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## 5. SCRIPTS DISPONIBLES

| Script | Emplacement | Role |
|---|---|---|
| `assert-git-committed.sh` | `keybuzz-infra/scripts/` | Bloque si repo dirty |
| `build-from-git.sh` | `keybuzz-infra/scripts/` | Build depuis clone Git propre |
| `pre-prod-check-v2.sh` | `keybuzz-infra/scripts/` | 25 checks avant promotion |
| `pre-prod-checks-v2.js` | `keybuzz-infra/scripts/` | Checks internes (copie dans pod) |

