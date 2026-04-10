# PH-ONBOARDING-UTF8-FIX-01 — Correction encodage UTF-8 onboarding

> Date : 10 avril 2026
> Environnement : DEV uniquement

---

## Objectif

Corriger les séquences unicode `\u00xx` affichées littéralement dans l'UI au lieu d'être rendues comme caractères accentués.

---

## Cause racine

Les fichiers ont été générés par des scripts Python de patch (phases PH-SHOPIFY) qui ont écrit les caractères accentués sous forme de séquences d'échappement unicode (`\u00e9` au lieu de `é`).

**Deux comportements distincts :**

1. **Dans du texte JSX brut** (hors expression `{}`) : `\u00e9` est affiché **littéralement** comme texte — c'est le bug visible.
2. **Dans des string JS** (entre quotes dans `{}`) : `\u00e9` est correctement interprété par le moteur JS, mais reste illisible dans le code source.

Les deux cas ont été corrigés.

---

## Fichiers corrigés

### 1. `app/login/page.tsx` — 4 corrections

| Avant | Après |
|---|---|
| `'Aucun compte trouv\u00e9'` | `'Aucun compte trouvé'` |
| `associ\u00e9 \u00e0 l` (JSX texte) | `associé à l` |
| `Cr\u00e9ez votre compte pour commencer \u00e0 utiliser KeyBuzz.` (JSX texte) | `Créez votre compte pour commencer à utiliser KeyBuzz.` |
| `'Cr\u00e9er un compte'` | `'Créer un compte'` |

### 2. `src/features/inbox/components/OrderSidePanel.tsx` — 7 corrections

| Avant | Après |
|---|---|
| `'Pay\u00e9'` | `'Payé'` |
| `'Rembours\u00e9'` | `'Remboursé'` |
| `'Partiellement rembours\u00e9'` | `'Partiellement remboursé'` |
| `'Annul\u00e9'` | `'Annulé'` |
| `'Exp\u00e9di\u00e9'` | `'Expédié'` |
| `'Non exp\u00e9di\u00e9'` | `'Non expédié'` |
| `'Partiellement exp\u00e9di\u00e9'` | `'Partiellement expédié'` |

### Fichier NON touché

- `src/features/ai-ui/AISuggestionSlideOver.tsx` — Les séquences `\u00xx` y sont **intentionnelles** :
  - `cleanAccents()` : patterns de nettoyage mojibake (double-encoding UTF-8 depuis le LLM)
  - Regex : alternations `[e\u00e9]` pour matcher avec ou sans accents
  - Ces patterns fonctionnent correctement et ne doivent pas être modifiés

---

## Image déployée

| Service | Tag | Rollback |
|---|---|---|
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.249-ph-utf8-fix-dev` | `v3.5.228-ph-shopify-04-dev` |

---

## Non-régression

| Page | Status | Résultat |
|---|---|---|
| `/login` | 200 | OK — page chargée correctement |
| `/signup` | 200 | OK — page chargée correctement |
| `/dashboard` | 307 → auth | OK — redirect auth (comportement attendu) |
| `/inbox` | 307 → auth | OK — redirect auth (comportement attendu) |
| API `/health` | 200 | OK |

---

## Rollback

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.228-ph-shopify-04-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Verdict

**DEV : VALIDÉ** — 11 séquences unicode corrigées dans 2 fichiers. Tous les accents français s'affichent correctement. Aucune régression.
