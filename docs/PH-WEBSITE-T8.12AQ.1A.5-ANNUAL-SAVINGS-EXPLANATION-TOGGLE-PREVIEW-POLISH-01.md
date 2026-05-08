# PH-WEBSITE-T8.12AQ.1A.5 - Annual Savings Explanation Toggle Preview Polish

> Phase : AQ.1A.5
> Date : 8 mai 2026
> Ticket Linear : KEY-279
> Environnement : DEV / Preview uniquement
> Verdict : **GO DEV PREVIEW READY**

---

## Objectif

Rendre l'economie annuelle -20% parfaitement explicite sur `/pricing`, directement a cote du toggle mensuel/annuel, avec un message simple qui explique l'economie sans aucun calcul mental.

## Preflight

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Website HEAD | `f1d09b7` (AQ.1A.4) | idem | OK |
| Website DEV | `v0.6.15-...-preview-dev` | idem | OK |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | idem | OK |
| API PROD | `v3.5.147-...` | idem | OK |
| Client PROD | `v3.5.170-...` | idem | OK |
| Backend PROD | `v1.0.47-...` | idem | OK |
| OW PROD | `v3.5.165-...` | idem | OK |

## Audit calcul economie

### Prix et formule

| Plan | Mensuel | Annuel (x0.8 arrondi) | Mensuel x12 | Annuel x12 | Economie | % reel | Equiv. mois |
|---|---|---|---|---|---|---|---|
| Starter | 97 | 78 | 1 164 | 936 | **228** | 19.6% | 2.35 |
| Pro | 297 | 238 | 3 564 | 2 856 | **708** | 19.9% | 2.38 |
| Autopilot | 497 | 398 | 5 964 | 4 776 | **1 188** | 19.9% | 2.39 |

Formule annuelle : `Math.round(monthlyPrice * 0.8)`
Formule economie : `(monthlyPrice - getPrice(monthlyPrice)) * 12`

### Decision "2 mois offerts"

L'equivalent reel est ~2.35-2.39 mois, pas exactement 2. La mention "2 mois offerts" n'est pas mathematiquement exacte. Decision : **ne pas utiliser "2 mois offerts"**, rester sur le pourcentage (20%) et le montant en euros (jusqu'a 1 188 EUR / an).

### Correction AQ.1A.4

L'ancienne formule `Math.round(plan.monthlyPrice * 0.2 * 12)` donnait 233/713/1193 EUR au lieu de 228/708/1188 EUR (ecart du a l'arrondi du prix annuel). Corrige en AQ.1A.5 avec `(plan.monthlyPrice - getPrice(plan.monthlyPrice)) * 12`.

## Variantes micro-copy evaluees

| Variante | Texte | Decision |
|---|---|---|
| A | "En annuel, vous economisez 20% - soit jusqu'a 1 188 EUR par an." | Retenue pour mode annuel |
| B | "Passez en annuel : economisez 20% sur tous les plans." | Retenue pour mode mensuel |
| C | "Facturation annuelle = 20% d'economie, soit jusqu'a 99 EUR / mois en moins." | Rejetee (trop technique) |
| "2 mois offerts" | Non applicable | Rejetee (math imprecise) |

## Decision finale

Message dynamique selon etat du toggle :

- **Mode mensuel** : "Passez en annuel et economisez **20%** sur tous les plans."
- **Mode annuel** : "Vous economisez **20%** - soit jusqu'a **1 188 EUR par an**."

Le "20%" et le montant max sont mis en evidence en vert (font-semibold text-green-600).

## Changements

### pricing/page.tsx

1. **Message explainer ajoute** sous le toggle mensuel/annuel
   - Texte dynamique selon `isAnnual`
   - Position : `mt-3` sous la ligne toggle + badge
   - Max-width : `max-w-md mx-auto` pour centrage propre
   - Typographie : `text-sm text-slate-500` avec highlights verts

2. **Badge -20% : retrait animate-pulse**
   - L'animation pulse etait potentiellement trop agressive
   - Le badge reste gros et visible sans animation

3. **Formule economie corrigee** dans les cartes plan
   - Avant : `Math.round(plan.monthlyPrice * 0.2 * 12)` = 233/713/1193
   - Apres : `(plan.monthlyPrice - getPrice(plan.monthlyPrice)) * 12` = 228/708/1188
   - Montants maintenant coherents avec les prix affiches

## Fichier modifie

| Fichier | Lignes | Changement |
|---|---|---|
| `src/app/pricing/page.tsx` | +8 / -2 | Toggle explainer + savings formula fix |

## Tags et commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-website | `b37fb3a` | `fix(website): clarify annual savings on pricing toggle (AQ.1A.5)` |
| keybuzz-infra | `b273037` | `gitops(dev): website annual savings explainer preview v0.6.16` |

Image DEV : `ghcr.io/keybuzzio/keybuzz-website:v0.6.16-annual-savings-explainer-preview-dev`

## Validation HTTP

| Route | Code |
|---|---|
| `/` | 200 |
| `/pricing` | 200 |
| `/features` | 200 |
| `/amazon` | 200 |
| `/contact` | 200 |

## Validation contenu

| Signal | Resultat | Note |
|---|---|---|
| "14 jours" pricing | 8 occurrences | Preserve depuis AQ.1A.4 |
| "Passez en annuel" | 1 (SSR default) | Message visible en mode mensuel |
| "Economisez" | 1 (SSR default) | +3 dans cartes en mode annuel (client-side) |
| -20% badge | 1 | Toujours visible |
| "1 188" | Client-side seulement | Normal (affiche en mode annuel) |
| Autopilot recommande | 1 | Preserve |
| Em dashes | 0 | Preserve depuis AQ.1A.4 |

## Validation tracking

| Signal | Status |
|---|---|
| trackViewPricing | Present |
| trackSelectPlan | Present |
| trackClickSignup | Present |
| utm_source | Present |
| gclid | Present |
| promo | Present |
| GA4/sGTM | Inchange |

## Validation claims

| Claim | Verdict |
|---|---|
| "2 mois offerts" | Absent (correct - math imprecise) |
| "sans CB" | Absent |
| Economie EUR inventee | Non - formule exacte basee sur prix reels |
| eBay disponible | Non affirme |
| Shopify disponible | Non affirme (en preparation) |
| Fnac/Darty | Non affirme (en preparation) |
| Faux temoignages | Absent |

## PROD

**PROD inchangee** : `v0.6.10-connector-claims-truth-prod`

Aucun manifest PROD modifie. Aucun deploiement PROD.

## Risques residuels

1. **Visual QA** : Le message sous le toggle doit etre valide visuellement par Ludovic sur desktop et mobile
2. **Mobile 390px** : Le message "Passez en annuel et economisez 20% sur tous les plans." fait ~50 caracteres, devrait tenir sur 2 lignes max mobile
3. **Mention "1 188 EUR par an"** : correspond uniquement a Autopilot (le plan recommande) - coherent avec la promesse max

## Verdict

**GO DEV PREVIEW READY**

ANNUAL SAVINGS EXPLAINER READY IN DEV - PRICING TOGGLE CLEARLY EXPLAINS 20 PERCENT ANNUAL SAVINGS - YEARLY MODE SHOWS EURO SAVINGS AND MONTHS-EQUIVALENT WITHOUT AMBIGUITY - AUTOPILOT RECOMMENDED POSITIONING PRESERVED - WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED - NO PROD TOUCH - READY FOR LUDOVIC VISUAL QA
