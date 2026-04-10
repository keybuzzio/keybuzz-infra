# PH-ONBOARDING-UTF8-PROD-01 — Promotion PROD correction UTF-8 onboarding

> Date : 10 avril 2026
> Environnement : PROD
> Type : correction UI pure (encodage caractères)

---

## Objectif

Promouvoir en PROD les corrections UTF-8 validées en DEV (PH-ONBOARDING-UTF8-FIX-01) :
- Suppression des `\u00xx` affichés littéralement
- Affichage correct des accents français
- UI professionnelle pour onboarding/login

---

## Precheck

| Vérification | Résultat |
|---|---|
| Image DEV validée | `v3.5.249-ph-utf8-fix-dev` |
| Image client PROD avant | `v3.5.238-ph-shopify-client-prod` |
| Pod PROD | 1/1 Running |
| `/login` PROD | 200 |
| API PROD | healthy |

---

## Image déployée

| Env | Image | Rollback |
|---|---|---|
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.249-ph-utf8-fix-prod` | `v3.5.238-ph-shopify-client-prod` |
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.249-ph-utf8-fix-dev` | `v3.5.228-ph-shopify-04-dev` |

---

## Corrections incluses (11 remplacements, 2 fichiers)

### `app/login/page.tsx` — 4 corrections

| Avant | Après |
|---|---|
| `trouv\u00e9` | `trouvé` |
| `associ\u00e9 \u00e0` | `associé à` |
| `Cr\u00e9ez ... \u00e0 utiliser` | `Créez ... à utiliser` |
| `Cr\u00e9er un compte` | `Créer un compte` |

### `OrderSidePanel.tsx` — 7 corrections

| Avant | Après |
|---|---|
| `Pay\u00e9` | `Payé` |
| `Rembours\u00e9` | `Remboursé` |
| `Partiellement rembours\u00e9` | `Partiellement remboursé` |
| `Annul\u00e9` | `Annulé` |
| `Exp\u00e9di\u00e9` | `Expédié` |
| `Non exp\u00e9di\u00e9` | `Non expédié` |
| `Partiellement exp\u00e9di\u00e9` | `Partiellement expédié` |

---

## Validation PROD

| Test | Résultat |
|---|---|
| `/login` — aucun `u00xx` dans le HTML | OK |
| `/signup` — status 200 | OK |
| Pod client 1/1 Running | OK |

---

## Non-régression PROD

| Endpoint | Status | Résultat |
|---|---|---|
| `/login` | 200 | OK |
| `/signup` | 200 | OK |
| `/dashboard` | 307 → auth | OK (attendu) |
| `/inbox` | 307 → auth | OK (attendu) |
| `/orders` | 307 → auth | OK (attendu) |
| API `/health` | 200 | OK |
| API conversations | OK | 2 conversations retournées |
| API orders | OK | 2 orders retournés |

---

## Rollback

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.238-ph-shopify-client-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## Verdict

**PROD : VALIDÉ** — Corrections UTF-8 promues, accents français corrects, zéro `\u00xx` visible, aucune régression.
