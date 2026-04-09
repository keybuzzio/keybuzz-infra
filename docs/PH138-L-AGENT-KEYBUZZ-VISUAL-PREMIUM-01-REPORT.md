# PH138-L — Agent KeyBuzz Visual Premium UX

> Date : 2026-04-01
> Statut : **DEV + PROD VALIDE**

---

## Objectif

Ameliorer la differenciation visuelle des options premium liees a l'add-on Agent KeyBuzz dans les Parametres IA.

## Probleme identifie

| Etat | Avant PH138-L | Apres PH138-L |
|---|---|---|
| Carte premium active | Aucune couronne, style indigo generique | Crown purple + bordure/fond purple |
| Carte premium dispo (addon present, non selectionnee) | Aucune couronne | Crown purple muted |
| Addon absent, plan OK | Crown amber (lock) | Crown amber (inchange) |
| Plan insuffisant | Lock gris seul | Lock gris + Crown gris muted |
| Badge addon actif | Vert generique | Purple premium avec label "Premium" |

## Modifications

### Fichier modifie

`keybuzz-client/src/features/ai-ui/AutopilotSection.tsx`

### Detail des changements

1. **Icone top-right : Crown toujours visible sur cartes premium**
   - Avant : Crown affichee uniquement quand `locked && addonLocked && !planLocked`
   - Apres : Crown affichee systematiquement pour `opt.requiresAddon`, avec couleur contextuelle :
     - `active` → `text-purple-500`
     - `hasKeybuzzAddon && !locked` → `text-purple-400`
     - `addonLocked && !planLocked` → `text-amber-500`
     - `planLocked` → `text-gray-300` + Lock a cote

2. **Bordure et fond des cartes premium actives**
   - Avant : `border-indigo-500 bg-indigo-50` (identique aux cartes non-premium)
   - Apres : `border-purple-500 bg-purple-50` pour `opt.requiresAddon`

3. **Couleur texte label des cartes premium actives**
   - Avant : `text-indigo-700` (identique)
   - Apres : `text-purple-700` pour `opt.requiresAddon`

4. **Badge addon actif**
   - Avant : fond vert (`bg-green-50`, `text-green-700`)
   - Apres : fond purple (`bg-purple-50`, `text-purple-700`) + label "Premium"

### Elements NON modifies

- Logique de gating (planLocked, addonLocked) : inchangee
- `activateAddon()` : inchange
- `upgradePlan()` : inchange
- CTA textes : inchanges
- Banner addon : inchange
- Billing backend : aucun changement
- Stripe : aucun changement
- DB : aucun changement

## Images deployees

| Service | Environnement | Image |
|---|---|---|
| Client DEV | keybuzz-client-dev | `v3.5.161-agent-keybuzz-premium-ux-dev` |
| Client PROD | keybuzz-client-prod | `v3.5.161-agent-keybuzz-premium-ux-prod` |
| API PROD | keybuzz-api-prod | `v3.5.160-stripe-checkout-final-prod` (inchangee) |

## Tests DEV

| Test | Resultat |
|---|---|
| Health API | `{"status":"ok"}` |
| Client pages (login, settings, billing, inbox, dashboard) | 200 |
| PH138-C enforcement | `checkout_required` |
| Patch verifie (border-purple-500) | present |
| Patch verifie (text-purple-700) | present |
| Patch verifie (Crown text-purple) | present |
| Pod Running | 1/1 |

## Tests PROD

| Test | Resultat |
|---|---|
| Health API | `{"status":"ok"}` |
| Client pages (login, settings, billing, inbox, dashboard, orders) | 200 |
| PH138-C enforcement | `checkout_required` |
| API logs | Clean (aucune erreur) |
| Pods | Running 1/1 |

## Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.160-stripe-checkout-final-dev -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.160-stripe-checkout-final-prod -n keybuzz-client-prod
```

## GitOps

| Fichier | Ancien | Nouveau |
|---|---|---|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.160-stripe-checkout-final-dev` | `v3.5.161-agent-keybuzz-premium-ux-dev` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.160-stripe-checkout-final-prod` | `v3.5.161-agent-keybuzz-premium-ux-prod` |
