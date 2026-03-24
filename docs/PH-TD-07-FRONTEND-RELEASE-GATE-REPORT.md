# PH-TD-07 — Frontend Release Gate — Rapport d'implementation

> Date : 2026-03-20
> Phase : PH-TD-07
> Type : hardening process / anti-regression

---

## 1. Scripts crees

| Script | Chemin | Role |
|---|---|---|
| **frontend-release-gate.sh** | `scripts/frontend-release-gate.sh` | Gate principal : verifie le bundle AVANT promotion |
| **frontend-runtime-gate.sh** | `scripts/frontend-runtime-gate.sh` | Gate runtime : verifie l'etat APRES deploiement |

Les deux scripts sont sur le bastion dans `/opt/keybuzz/keybuzz-infra/scripts/`.

---

## 2. Checks implementes (24 checks dans le release gate)

| Section | Checks | Description |
|---|---|---|
| A. Image | 1 | Existence de l'image dans GHCR |
| B. Routes critiques | 10 | /login, /signup, /pricing, /onboarding, /start, /locked, /dashboard, /inbox, /channels, /billing |
| C. Focus mode | 1 | Verification pattern minifie : `null!==x&&` = OFF (PASS), `null===x\|\|` = ON (FAIL) |
| D. Paywall | 5 | 4 lock reasons + isLocked hook |
| E. API URLs | 2 | Cross-env contamination check |
| F. Navigation | 5 | /start, /dashboard, /inbox, /channels, /billing dans le layout |

Runtime gate : 12 checks (pod health, 9 routes HTTP, API health).

---

## 3. Tests — Preuve que le gate bloque PH117

### Test 1 : Image saine v3.5.58 → PASS

```
Image: ghcr.io/keybuzzio/keybuzz-client:v3.5.58-channels-billing-prod
Total checks: 24
Passed: 24 / Failed: 0
promotionReady: true
Exit code: 0
```

### Test 2 : Image regressive v3.5.59 → FAIL

```
Image: ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod
Total checks: 24
Passed: 23 / Failed: 1
  ✗ Focus mode default is ON (regression: null===x||"true"===x)
promotionReady: false
Exit code: 1
```

**Le gate aurait bloque la catastrophe PH117.** La regression du focus mode est detectee automatiquement par l'analyse du pattern minifie dans le bundle layout.

### Test 3 : Runtime gate v3.5.58 PROD → HEALTHY

```
Total checks: 12
Passed: 12 / Failed: 0
Routes: /login (200), /signup (200), /pricing (200),
        /onboarding (307), /locked (307), /dashboard (307),
        /inbox (307), /channels (307), /billing (307)
API: /health reachable
RUNTIME: HEALTHY
```

---

## 4. Methode de detection du focus mode

La methode la plus robuste identifiee est l'analyse du pattern minifie par Webpack/Next.js dans le layout chunk.

La fonction `getFocusMode()` en TypeScript :
```typescript
function getFocusMode(tenantId: string): boolean {
  const stored = localStorage.getItem(getFocusModeKey(tenantId));
  if (stored === null) return <DEFAULT>;
  return stored === "true";
}
```

Se minifie en :
- **OFF default** : `null!==t&&"true"===t` (retourne `false` si null)
- **ON default** : `null===t||"true"===t` (retourne `true` si null)

Le gate cherche exactement ces patterns dans le layout JS chunk.

---

## 5. Limitations

| Limitation | Impact | Mitigation |
|---|---|---|
| Detection focus mode basee sur pattern minifie | Un refactoring du minifier pourrait changer le pattern | Mise a jour du regex si necessaire |
| Pas de test d'interaction utilisateur reel | Ne teste pas le rendu visuel | Navigateur headless possible en futur |
| Routes protegees renvoient 307 | Normal (redirect vers login) | Accepte comme valide |
| Ne teste pas le contenu des pages | Verifie presence, pas contenu | Suffisant pour gate de base |

---

## 6. Non-regression

Le gate est hors chemin runtime metier :
- Aucun impact utilisateur
- Aucune modification API
- Aucune modification DB
- Purement un verrou de build/release
- PH41 → PH116 strictement inchanges

---

## 7. Rollback

Si le gate doit etre desactive temporairement :
- Il suffit de ne pas l'executer
- Aucun impact sur le fonctionnement des services
- Les scripts sont independants du pipeline de deploiement
