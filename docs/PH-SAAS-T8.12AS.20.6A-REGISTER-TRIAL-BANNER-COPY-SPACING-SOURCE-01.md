# PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6A REGISTER TRIAL BANNER COPY + SPACING SOURCE
> Environnement : SOURCE PATCH Client uniquement (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH REGISTER TRIAL BANNER COPY SPACING READY PH-SAAS-T8.12AS.20.6A

- Source patch unique `app/register/page.tsx` : +13 -14 = -1 net (-12 bytes).
- TrialValueBanner : spacing (mt-8 mb-10), style premium (rounded-2xl, border-2 green/40, bg uni green/10, px-5 py-4) aligne avec grand encart plan, copy humaine orientee benefice.
- Phrase CB retiree du TrialValueBanner (Carte demandee uniquement a l activation. Aucun debit avant la fin de l essai. + Autopilot inclus pendant l essai pour tester toute la valeur).
- ReassurancePanel : intro recentree benefits (KeyBuzz rassemble vos messages...), CB retiree. Footer : ligne 0 EUR/Autopilot retiree (discours paiement reserve etape plan).
- Grand encart etape plan INCHANGE (continue discours 0 EUR + Carte demandee a l activation contextuel pricing).
- Preservations PH-19.x + PH-20.2 OK : data-clarity-mask=13, drafts CGU, plan_selected, SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- 0 fake event delta.
- Commit Client `dbdc46f` push origin `ph148/onboarding-activation-replay` OK.
- Runtime Client DEV `v3.5.207-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Aucun build, aucun deploy, aucune mutation DB/Stripe.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 20:39 |
| keybuzz-client branche/HEAD avant | ph148/onboarding-activation-replay / 3f88217 |
| keybuzz-client dirty | 1 (tsconfig.tsbuildinfo artefact preexistant, hors scope) |
| keybuzz-infra branche/HEAD | main / 074a595 (post APPLY DEV PH-20.6) |
| Runtime Client DEV avant | v3.5.207-register-polish-dev (PH-20.6 live) |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 AUDIT SOURCE CIBLE

| Item | Localisation source PH-20.6 |
|---|---|
| TrialValueBanner data-testid | l.705 (register-trial-value-banner) |
| TrialValueBanner copy CB (a retirer) | l.711 "Carte demandee uniquement a l activation. Aucun debit avant la fin de l essai." |
| TrialValueBanner copy Autopilot (a retirer) | l.712 "Autopilot inclus pendant l essai pour tester toute la valeur." |
| ReassurancePanel intro CB (a retirer) | l.644 "Avant de regarder les plans, voyons ce que vous obtenez. Aucune CB requise tant que vous n avez pas confirme." |
| ReassurancePanel footer 0 EUR (a retirer) | l.666 "0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais" |
| Grand encart plan (a preserver) | l.732+ "0 EUR pendant 14 jours" + "Carte demandee a l activation. Aucun debit avant la fin de l essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot." |

## E2 DESIGN PATCH

### A. TrialValueBanner spacing + style + copy

| Item | Avant | Apres |
|---|---|---|
| Spacing | `mt-6` (colle a la card form en dessous) | `mt-8 mb-10` (vraie respiration) |
| Border-radius | rounded-xl | rounded-2xl (aligne grand encart plan) |
| Background | bg-gradient-to-r from-green-500/10 to-blue-500/10 | bg-green-500/10 (uni, aligne grand encart plan) |
| Border | border border-green-500/30 | border-2 border-green-500/40 (premium, aligne grand encart) |
| Padding | p-3 | px-5 py-4 (aligne grand encart plan) |
| Titre | text-sm font-semibold + Check h-4 | text-base font-bold + Check h-5 (aligne grand encart) |
| Paragraphe principal | mt-1 text-xs text-gray-300 | mt-2 text-sm text-gray-200 (plus lisible) |
| Bullets typo | text-[11px] text-gray-400 + Check h-3 | text-xs text-gray-300 + Check h-3.5 (clarte) |
| Bullets gap | gap-x-3 gap-y-1 | gap-x-4 gap-y-2 (respiration) |
| Copy paragraphe | Carte demandee uniquement a l activation. Aucun debit avant la fin de l essai. + Autopilot inclus pendant l essai pour tester toute la valeur. | Toutes les fonctionnalites cles sont disponibles pendant votre essai, pour voir concretement ce que KeyBuzz peut faire gagner a votre equipe. |
| Bullets | Cockpit SAV marketplace centralise / Connexions Amazon, Fnac, Cdiscount / Copilote IA avec contexte commande / Escalades et garde-fous configurables | Inbox marketplace centralisee / Contexte commande sous les yeux / Reponses IA pretes a valider / Escalades plus claires |

### B. ReassurancePanel intro

| Avant | Apres |
|---|---|
| "Avant de regarder les plans, voyons ce que vous obtenez. Aucune CB requise tant que vous n avez pas confirme." | "KeyBuzz rassemble vos messages marketplace, le contexte commande et les regles de reponse dans un cockpit unique. Votre equipe repond plus vite, avec l IA en soutien et le controle qui reste de votre cote." |

CB retiree (discours paiement reserve etape plan).

### C. ReassurancePanel footer

| Avant | Apres |
|---|---|
| Plan et coupon confirmes avant Stripe / 0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais / Attribution marketing preservee jusqu au checkout | Plan et coupon confirmes avant Stripe / Attribution marketing preservee jusqu au checkout / KeyBuzz prepare le terrain, votre equipe garde la main. |

Ligne 0 EUR/Autopilot retiree du panneau lateral (discours paiement reserve a l etape plan). Ajout muted positif KeyBuzz prepare le terrain.

### D. Grand encart etape plan INCHANGE

Le grand encart `register-autopilot-trial-note` (l.732-740) reste identique :
- "0 EUR pendant 14 jours" (titre vert fort)
- "Carte demandee a l activation. Aucun debit avant la fin de l essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot." (paragraphe)

Le discours paiement/CB contextuel pricing reste a l etape plan, ou il est attendu.

## E3 PATCH SOURCE

| Indicateur | Valeur |
|---|---|
| Fichier touche | `app/register/page.tsx` (1 fichier) |
| Delta lignes | +13 -14 = -1 net (-12 bytes) |
| Script de patch | `/tmp/patch-register-ph206a.py` (substitutions Python deterministes) |

## E4 VERIFICATION DIFF

| Verification | Resultat |
|---|---|
| Diff scope strict | uniquement `app/register/page.tsx` (+ tsconfig.tsbuildinfo non staged) |
| Forbidden phrases pre-plan/banner/right-pane | aucune ("Avant de regarder les plans", "Aucune CB requise", "Autopilot inclus pendant l essai pour tester toute la valeur", "Carte demandee uniquement a l activation. Aucun debit avant la fin de l essai.") |
| Phrase "Carte demandee a l activation" preservee | OK uniquement dans grand encart etape plan (l.732-740 contextuel pricing) |
| Forbidden fake events delta | aucun (Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-) |

## E5 ASSERTIONS PRESERVATION

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| `data-clarity-mask` count | 13 | 13 | **OK preserve** |
| `kb_signup_form_draft_v1` count | 2 | 2 | OK preserve |
| `kb_signup_cgu_accepted` count | 2 | 2 | OK preserve |
| `plan_selected` count | 2 | 2 | OK preserve |
| `register-trial-value-banner` data-testid | 1 | 1 | OK marker present |
| `TrialValueBanner` mot dans source | 0 | 0 | OK commentaire renomme PH-20.6A (marker fonctionnel via data-testid preserve) |
| `0 EUR pendant 14 jours` count | 2 | 2 | OK (1 TrialValueBanner titre + 1 grand encart plan ; retire de ReassurancePanel footer) |
| `SaaSAnalytics.tsx` diff | 0 | 0 | OK Clarity route-gated INCHANGE |
| Fake event scan src/components/tracking | 0 | 0 | OK |

## E6 TESTS

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit --skipLibCheck` global | 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes (baseline PH-19.0 hors scope) ; 0 nouvelle erreur src introduite | OK |

## E7 COMMIT + PUSH CLIENT

| Item | Valeur |
|---|---|
| Stage scope | app/register/page.tsx UNIQUEMENT (tsconfig.tsbuildinfo non staged) |
| Commit hash | dbdc46f7604f0c39eb2affb696937a1d7caf0508 |
| Commit short | dbdc46f |
| Commit title | fix(register): refine trial banner copy and spacing |
| Stats | 1 file changed, 13 insertions(+), 14 deletions(-) |
| Push | OK 3f88217..dbdc46f ph148/onboarding-activation-replay -> origin |
| local == origin | OK |

## RUNTIME DEV/PROD INCHANGES

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.207-register-polish-dev | INCHANGE (aucun build) |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE (aucun build) |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Patch source uniquement. Runtime impact = 0 jusqu au prochain build/deploy explicite.

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply/set/patch/edit.
- AUCUN manifest GitOps modifie.
- AUCUN secret/token affiche.
- AUCUNE mutation DB.
- AUCUN appel Stripe.
- AUCUN faux register DEV/PROD.
- AUCUNE modification API/Website/Admin.
- AUCUN cleanup tenant orphan.
- AUCUN ticket Linear modifie statut automatiquement.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- data-clarity-mask preserves (13).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun tracking GA4/CAPI/Addingwell modifie.
- Comportement PH-19.x preserve : sessionStorage drafts CGU, attribution marketing, marketing_owner_tenant_id, plan_selected emission.

## GAPS

1. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel mobile 360px (vraie respiration + style premium aligne).
2. tsc 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes baseline PH-19.0, hors scope PH-20.6A.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH REGISTER TRIAL BANNER COPY SPACING READY PH-SAAS-T8.12AS.20.6A |
| Bastion | install-v3 46.62.171.61 |
| Commit Client | dbdc46f push origin ph148/onboarding-activation-replay |
| Fichier patche | app/register/page.tsx (+13 -14 = -1 net, -12 bytes) |
| TrialValueBanner spacing | mt-8 mb-10 (respiration) |
| TrialValueBanner style | rounded-2xl, border-2 green/40, bg uni green/10, px-5 py-4 (aligne grand encart plan) |
| TrialValueBanner copy | CB retiree, copy humaine orientee benefice + 4 bullets recentrees client |
| ReassurancePanel intro | CB retiree, recentree benefits cockpit |
| ReassurancePanel footer | ligne 0 EUR/Autopilot retiree (discours paiement reserve etape plan), footer muted KeyBuzz |
| Grand encart etape plan | INCHANGE |
| PH-19.x + PH-20.2 preservations | OK (data-clarity-mask 13, drafts, plan_selected, Clarity route-gated) |
| 0 EUR pendant 14 jours | 4 -> 2 (1 TrialValueBanner + 1 plan banner, ReassurancePanel footer retire) |
| Fake events delta | 0 |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6A`

STOP.
