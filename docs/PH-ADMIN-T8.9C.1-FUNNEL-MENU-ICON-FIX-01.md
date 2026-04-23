# PH-ADMIN-T8.9C.1 — Funnel Menu Icon Fix

**Phase** : PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : micro-fix UI navigation — icone manquante menu Funnel
**Priorite** : P1

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Infra | `main` |
| HEAD Infra | `5479f12` |
| Admin DEV avant | `v2.11.9-funnel-cro-ui-dev` |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` (INCHANGE) |
| HEAD Admin avant | `bc6394f` |
| Repo | clean |

---

## 2. CAUSE RACINE

| Element | Resultat |
|---|---|
| navigation item Funnel | `icon: 'Filter'` (correct) |
| Import Lucide `Filter` dans Sidebar.tsx | **ABSENT** |
| `iconMap['Filter']` dans Sidebar.tsx | **ABSENT** |

Le fichier `src/config/navigation.ts` declarait `icon: 'Filter'` pour Funnel, mais `src/components/layout/Sidebar.tsx` n'importait pas `Filter` de `lucide-react` et ne l'incluait pas dans son `iconMap`. Le composant `iconMap[item.icon]` retournait `undefined`, d'ou aucune icone rendue.

---

## 3. PATCH MINIMAL

**Fichier modifie** : `src/components/layout/Sidebar.tsx`

**Changement** : ajout de `Filter` a deux endroits dans le meme fichier :

1. Import lucide-react (ligne 9) : `..., ScrollText, BookOpen,` → `..., ScrollText, BookOpen, Filter,`
2. `iconMap` (ligne 19) : `..., ScrollText, BookOpen,` → `..., ScrollText, BookOpen, Filter,`

**Commit** : `2c3db25` — `fix(sidebar): add Filter icon to lucide import + iconMap for Funnel menu item`

Rien d'autre n'a ete modifie. Ni la navigation, ni la page, ni les proxies, ni le menu order.

---

## 4. VALIDATION NAVIGATEUR DEV

| Test | Attendu | Resultat |
|---|---|---|
| Menu Marketing visible | 6 items | OK |
| Funnel en position 2 | Apres Metrics | OK |
| Pictogramme Funnel | Icone Filter (entonnoir) | OK — visible |
| Alignement visuel | Coherent avec Metrics, Ads, etc. | OK |
| Page /marketing/funnel | Accessible | OK |
| Aucun overlap | 0 | 0 |
| NaN / undefined / mock | 0 | 0 |
| Autres pictos Marketing | Inchanges | OK |

---

## 5. IMAGE DEV

| Element | Valeur |
|---|---|
| Image DEV avant | `v2.11.9-funnel-cro-ui-dev` |
| Image DEV apres | `v2.11.10-funnel-menu-icon-fix-dev` |
| Commit Admin | `2c3db25` |
| Digest | `sha256:c8211134be5cb35a440cc292839805364ae573b1bc8932002d31574b741546d1` |
| Commit Infra | `36f3389` |
| ROLLBACK DEV | `v2.11.9-funnel-cro-ui-dev` |

---

## 6. NON-REGRESSION

| Page | Resultat |
|---|---|
| /marketing/funnel | OK (page + icone) |
| /marketing/metrics | OK (menu visible) |
| /marketing/ad-accounts | OK |
| /marketing/destinations | OK |
| /marketing/delivery-logs | OK |
| /marketing/integration-guide | OK |
| Menu Marketing ordre | OK (Metrics, Funnel, Ads, Dest, Logs, Guide) |
| Admin PROD | Inchangee (`v2.11.8-agency-tracking-playbook-prod`) |
| API PROD | Inchangee |

---

## 7. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01.md
```

---

**VERDICT** : FUNNEL MENU ICON FIXED IN DEV — MINIMAL SIDEBAR PATCH — NAVIGATION INTACT — PROD UNTOUCHED
