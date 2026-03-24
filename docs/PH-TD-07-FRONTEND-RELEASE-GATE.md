# PH-TD-07 — Frontend Release Gate / Safe Promotion Guardrail

## Probleme resolu

L'incident PH117 a montre qu'un build client pouvait etre promu en PROD avec une regression silencieuse (focus mode ON par defaut), cassant l'onboarding, le menu et la perception SaaS. Aucun mecanisme n'empechait cette promotion.

PH-TD-07 rend ce scenario **impossible** en imposant un gate obligatoire avant toute promotion PROD.

---

## Checks obligatoires

### A. Image disponibilite
- L'image doit exister dans le GHCR

### B. Routes critiques (10 routes)
| Route | Obligatoire |
|---|---|
| `/login` | OUI |
| `/signup` | OUI |
| `/pricing` | OUI |
| `/onboarding` | OUI |
| `/start` | OUI |
| `/locked` | OUI |
| `/dashboard` | OUI |
| `/inbox` | OUI |
| `/channels` | OUI |
| `/billing` | OUI |

### C. Focus mode default OFF
Le gate verifie dans le bundle minifie que la logique `getFocusMode` retourne `false` quand localStorage est vide.

| Pattern | Signification | Verdict |
|---|---|---|
| `null!==x&&"true"===x` | Retourne `false` si null → OFF par defaut | **PASS** |
| `null===x\|\|"true"===x` | Retourne `true` si null → ON par defaut | **FAIL** |

### D. Paywall invariants
- Lock reasons : TRIAL_EXPIRED, PAST_DUE, CANCELED, NO_SUBSCRIPTION
- Hook `isLocked` present

### E. API URL safety
| Env | Doit contenir | Ne doit PAS contenir |
|---|---|---|
| `prod` | `api.keybuzz.io` | `api-dev.keybuzz.io` |
| `dev` | `api-dev.keybuzz.io` | `api.keybuzz.io` |

### F. Navigation items
- `/start`, `/dashboard`, `/inbox`, `/channels`, `/billing` dans le layout

---

## Procedure DEV

```bash
# Avant build, verifier le code source
bash scripts/frontend-release-gate.sh dev ghcr.io/keybuzzio/keybuzz-client:<tag-dev>

# Apres deploiement DEV
bash scripts/frontend-runtime-gate.sh dev
```

## Procedure PROD — OBLIGATOIRE

```bash
# AVANT TOUTE PROMOTION PROD :
bash scripts/frontend-release-gate.sh prod ghcr.io/keybuzzio/keybuzz-client:<tag-prod>

# Resultat attendu : PROMOTION READY: true
# Si PROMOTION REFUSED → NE PAS DEPLOYER

# APRES DEPLOIEMENT PROD :
bash scripts/frontend-runtime-gate.sh prod
```

**Regle : aucune promotion PROD client sans `promotionReady: true`.**

---

## Exemple PASS

```
Image: ghcr.io/keybuzzio/keybuzz-client:v3.5.58-channels-billing-prod
Total checks: 24
Passed: 24
Failed: 0
promotionReady: true
```

## Exemple FAIL

```
Image: ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod
Total checks: 24
Passed: 23
Failed: 1
  ✗ Focus mode default is ON (regression: null===x||"true"===x)
promotionReady: false
```

---

## Rollback

Si une promotion PROD echoue ou si un probleme est detecte apres deploiement :

```bash
# Revenir a la derniere image saine
kubectl set image deploy/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:<last-known-good-tag> \
  -n keybuzz-client-prod
```

Puis mettre a jour le manifest GitOps.
