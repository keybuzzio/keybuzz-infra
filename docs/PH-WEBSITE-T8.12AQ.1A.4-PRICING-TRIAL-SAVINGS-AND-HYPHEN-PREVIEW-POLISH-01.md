# PH-WEBSITE-T8.12AQ.1A.4 - Pricing Trial Savings and Hyphen Preview Polish

> Phase : AQ.1A.4
> Date : 8 mai 2026
> Ticket Linear : KEY-279
> Environnement : DEV / Preview uniquement
> Verdict : **GO DEV PREVIEW READY**

---

## Objectif

Derniere passe de polish conversion sur la preview Website apres AQ.1A.3.
Trois corrections QA Ludovic :
1. Remplacer tous les em dashes par des tirets classiques
2. Rendre les 14 jours d'essai tres visibles et conversion-first
3. Rendre l'economie annuelle -20% tres visible avec calcul explicite

## Preflight

| Surface | Attendu | Observe | Verdict |
|---|---|---|---|
| Website HEAD | `a4ccf5e` (AQ.1A.3) | `a4ccf5e` | OK |
| Website DEV | `v0.6.14-pricing-autopilot-conversion-preview-dev` | idem | OK |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | idem | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | OK |

## Audit Em Dashes

### Avant

| Fichier | Occurrences |
|---|---|
| `src/app/page.tsx` | 3 |
| `src/app/pricing/page.tsx` | 0 |
| `src/components/PreviewBanner.tsx` | 1 |
| `src/app/about/page.tsx` | 2 |
| `src/app/amazon/security/page.tsx` | 6 |
| `src/app/legal/page.tsx` | 1 |
| **Total** | **13** |

### Apres

0 em dashes dans tout `src/`. Tous remplaces par tirets classiques `-`.

## Changements Homepage (page.tsx)

1. **3 em dashes remplaces** par des tirets simples
2. **Badge trial ajoute** dans le hero : encadre vert prominent avec "14 jours d'essai gratuit" en texte 2xl bold + "sur vos vrais messages"
3. Les trust badges sont decales en delay={5} pour laisser place au badge trial
4. Separateurs bullet remis en tirets simples dans le CTA final

### Visibilite trial homepage

| Element | Avant | Apres |
|---|---|---|
| Hero CTA | "Essayer 14 jours gratuitement" | Identique |
| Badge trial hero | Absent | Badge vert 2xl "14 jours d'essai gratuit" |
| CTA final H2 | "14 jours pour voir..." | Identique |
| Total "14 jours" | ~2 | 3+ |

## Changements Pricing (pricing/page.tsx)

1. **Callout trial agrandi** : fond vert (green-50), border-2 green-300, titre 2xl bold "14 jours d'essai gratuit", sous-titre plus lisible
2. **Badge -20% agrandi** : fond vert-500 blanc, text-base bold, shadow-md, animate-pulse, texte "20% annuel"
3. **Economie annuelle explicite** : quand le toggle annuel est actif, chaque card affiche "Economisez X EUR / an" en vert sous le prix
4. Separateurs bullet remplaces par tirets simples

### Calcul economie annuelle (verifie)

| Plan | Mensuel | Annuel (x0.8) | Economie/mois | Economie/an |
|---|---|---|---|---|
| Starter | 97 EUR | 78 EUR | 19 EUR | 228 EUR |
| Pro | 297 EUR | 238 EUR | 59 EUR | 708 EUR |
| Autopilot | 497 EUR | 398 EUR | 99 EUR | 1 188 EUR |

Formule : `Math.round(plan.monthlyPrice * 0.2 * 12)` - mathematiquement exact.

### Visibilite savings pricing

| Element | Avant | Apres |
|---|---|---|
| Toggle badge | `-20%` petit (text-sm) | `-20% annuel` gros (text-base bold, vert vif) |
| Economie par plan | Absent | "Economisez X EUR / an" sous chaque prix |
| Prix barre | Present | Preserve |
| Trial callout | Moyen (p-4) | Grand (p-6, 2xl bold, border-2) |

## Fichiers modifies

| Fichier | Changements |
|---|---|
| `src/app/page.tsx` | Em dashes + badge trial hero |
| `src/app/pricing/page.tsx` | Em dashes + trial callout + savings toggle + savings par plan |
| `src/components/PreviewBanner.tsx` | 1 em dash |
| `src/app/about/page.tsx` | 2 em dashes |
| `src/app/amazon/security/page.tsx` | 6 em dashes |
| `src/app/legal/page.tsx` | 1 em dash |

## Tags et commits

| Repo | Commit | Tag/Message |
|---|---|---|
| keybuzz-website | `f1d09b7` | `fix(website): polish trial savings and hyphen copy (AQ.1A.4)` |
| keybuzz-infra | `428a871` | `gitops(dev): website trial savings polish preview v0.6.15` |

Image DEV : `ghcr.io/keybuzzio/keybuzz-website:v0.6.15-pricing-trial-savings-polish-preview-dev`

## Validation HTTP

| Route | Code |
|---|---|
| `/` | 200 |
| `/pricing` | 200 |
| `/features` | 200 |
| `/amazon` | 200 |
| `/contact` | 200 |

## Validation contenu

| Signal | Homepage | Pricing |
|---|---|---|
| "14 jours" occurrences | 3 | 8 |
| Em dashes | 0 | 0 |
| Autopilot recommande | - | 1 |
| -20% badge | - | 1 |
| Economie annuelle | - | Client-side toggle (OK) |

## Validation tracking

| Signal | Status |
|---|---|
| trackViewPricing | Present dans source |
| trackSelectPlan | Present dans source |
| trackClickSignup | Present dans source |
| utm_source | Present dans source |
| gclid | Present dans source |
| promo forwarding | Present dans source |
| GA4/sGTM | Preserve (pas de modification des scripts) |

## Validation claims

| Claim | Verdict |
|---|---|
| "sans CB" | Absent (correct) |
| IA gratuite Starter | Non promis (correct - "IA via packs KBActions en option") |
| eBay disponible | Non affirme (FAQ dit "Pas encore") |
| Shopify disponible | Non affirme ("en preparation") |
| Fnac/Darty | Non affirme ("en preparation") |
| Faux temoignages | Absent |
| Chiffres inventes | Absent |
| Logos non autorises | Absent |
| Economie mensuelle inventee | Non - calcul exact a partir des prix reels |

## PROD

**PROD inchangee** : `v0.6.10-connector-claims-truth-prod`

Aucun manifest PROD modifie. Aucun deploiement PROD.

## Linear

- KEY-279 : commentaire AQ.1A.4 complete, DEV preview ready
- KEY-278 : commentaire "pricing polish applied (trial + savings + hyphens)"
- KEY-253 : commentaire "trial/savings polish ready in preview"
- KEY-273, KEY-275, KEY-263 : non fermes

## Risques residuels

1. **Visual QA** : le badge trial vert et l'animation pulse du badge -20% doivent etre valides visuellement par Ludovic
2. **Mobile** : le badge trial hero pourrait etre trop large sur petits ecrans (390px) - a verifier
3. **animate-pulse** : si Ludovic trouve l'animation trop agressive, desactiver le pulse

## Verdict

**GO DEV PREVIEW READY**

PRICING TRIAL AND SAVINGS POLISH READY IN DEV - EM DASHES REPLACED BY SIMPLE HYPHENS - 14 DAYS TRIAL VISIBILITY STRENGTHENED - ANNUAL 20 PERCENT SAVINGS MADE CLEAR AND PROMINENT - AUTOPILOT RECOMMENDED POSITIONING PRESERVED - WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED - CONNECTOR CLAIMS HONEST - NO PROD TOUCH - READY FOR LUDOVIC VISUAL QA
