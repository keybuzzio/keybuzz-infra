# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-SOURCE-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER CTA TRIAL COPY SOURCE
> Environnement : SOURCE PATCH Client uniquement (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH REGISTER CTA TRIAL COPY READY PH-SAAS-T8.12AS.20.6C

- Source patch unique `app/register/page.tsx` : +27 -17 = +10 net (-324 bytes net).
- CTA final etape plan : label remplace par "Demarrer mon essai gratuit - 0 EUR aujourd hui".
- Microcopy sous CTA : remplace par "Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez." via IIFE PLANS.find + isAnnual ? getAnnualPrice.
- Bloc PH-20.6B des cards RETIRE du source (revert vers PH-20.6A pricing block PH33.11 strikethrough annuel + displayPrice/mois + Economisez X EUR/an).
- PH-20.6A markers PRESERVES : TrialValueBanner + ReassurancePanel benefits + grand encart 0 EUR pendant 14 jours.
- Preservations PH-19.x + PH-20.2 OK : data-clarity-mask=13, drafts CGU, plan_selected, SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- Logique pricing INCHANGE : PRICING_CONFIG, PLANS, ANNUAL_DISCOUNT, getAnnualPrice, isAnnual toggle, handleConfirmPlanAndCheckout.
- 0 fake event delta.
- Aucune mention "Payez 0 EUR" (interdit brief).
- Commit Client `be45f1d` push origin `ph148/onboarding-activation-replay` OK.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Aucun build, aucun deploy, aucune mutation DB/Stripe.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-client branche/HEAD avant | ph148/onboarding-activation-replay / 97bdd5b (PH-20.6B source) |
| keybuzz-client dirty | 1 (tsconfig.tsbuildinfo preexistant, hors scope) |
| keybuzz-infra branche/HEAD | main / 1b9c858 (post ROLLBACK PH-20.6B->PH-20.6A) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev (rollback PH-20.6A live) |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 AUDIT SOURCE CTA + CARDS

| Item | Localisation |
|---|---|
| CTA button label | l.854 (avant patch) : `Confirmer ce plan et activer l essai 14 jours` |
| Microcopy sous CTA | l.857-859 (avant patch) : "A la fin de l essai..." generique |
| Plan cards pricing block PH-20.6B (a retirer) | l.792-806 (avant patch) : register-plan-trial-pricing data-testid |
| handleConfirmPlanAndCheckout | l.479 (inchange) |
| Grand encart 0 EUR pendant 14 jours (a preserver) | l.732-740 (preserve) |

## E2 DESIGN PATCH RETENU

### A. CTA label

| Avant | Apres |
|---|---|
| Confirmer ce plan et activer l essai 14 jours | Demarrer mon essai gratuit - 0 EUR aujourd hui (e aigu sur Demarrer, apostrophe HTML &apos;) |

### B. Microcopy sous CTA

| Avant | Apres |
|---|---|
| A la fin de l essai, le plan selectionne devient actif si vous continuez. Vous pouvez changer de plan ou annuler avant cette date. (statique, generique) | Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez. (dynamique via IIFE) |

Implementation IIFE :
```tsx
{(() => {
  const sp = PLANS.find(p => p.id === selectedPlan);
  if (!sp || sp.price === null) return null;
  const dp = isAnnual ? getAnnualPrice(sp.price as number) : (sp.price as number);
  return (
    <p className="text-center text-gray-400 text-xs mt-3">
      Puis <span className="font-semibold text-gray-200">{sp.name}</span> a <span className="font-semibold text-gray-200">{dp} EUR/mois</span> dans 14 jours, seulement si vous continuez.
    </p>
  );
})()}
```

Garde-fou : retourne `null` si plan introuvable ou prix null (cas plan custom enterprise sans prix fixe).

### C. Abandon PH-20.6B (revert source cards)

| Avant (PH-20.6B en source) | Apres (PH-20.6A original restaure) |
|---|---|
| h3 plan.name mb-3 + bloc register-plan-trial-pricing (0 EUR maintenant + puis X EUR/mois dans 14 jours + ligne annuel) | h3 plan.name mb-1 + PH33.11 strikethrough annuel + displayPrice/mois + Economisez X EUR/an |

Raison : PH-20.6B rendu cards non retenu par Ludovic (cf rollback runtime DEV PH-20.6B->PH-20.6A). Source aligne sur le runtime stable PH-20.6A.

## E3 PATCH SOURCE

| Indicateur | Valeur |
|---|---|
| Fichier touche | `app/register/page.tsx` (1 fichier) |
| Delta lignes | +27 -17 = +10 net (-324 bytes total) |
| Script de patch | `/tmp/patch-register-ph206c.py` (CTA) + `/tmp/patch-register-ph206c-revert-cards.py` (revert PH-20.6B cards) |

Repartition delta :
- Revert PH-20.6B cards : -14 / +14 (PH-20.6A pricing block restaure, count identique)
- CTA label : -1 / +1
- Microcopy IIFE : -3 / +11 (statique -> dynamique avec garde-fou null)

## E4 VERIFICATION DIFF

| Verification | Resultat |
|---|---|
| Diff scope strict | uniquement `app/register/page.tsx` (+ tsconfig.tsbuildinfo non staged) |
| Phrase interdite brief "Payez 0 EUR" | absente (none) |
| PH-20.6B markers (register-plan-trial-pricing, 0 EUR maintenant, Tarif annuel) | absents (revert OK) |
| Nouveaux markers PH-20.6C | "Demarrer mon essai gratuit" + "seulement si vous continuez" + IIFE PLANS.find |
| Forbidden fake events delta | aucun (Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-) |

## E5 ASSERTIONS PRESERVATION

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| `data-clarity-mask` count | 13 | 13 | **OK preserve** |
| `kb_signup_form_draft_v1` count | 2 | 2 | OK preserve |
| `kb_signup_cgu_accepted` count | 2 | 2 | OK preserve |
| `plan_selected` count | 2 | 2 | OK preserve |
| `register-trial-value-banner` (PH-20.6A) | 1 | 1 | OK preserve |
| `Toutes les fonctionnalit` (PH-20.6A) | 1 | 1 | OK preserve |
| `Inbox marketplace` (PH-20.6A) | 1 | 1 | OK preserve |
| `KeyBuzz rassemble` (PH-20.6A) | 1 | 1 | OK preserve |
| `0 EUR pendant 14 jours` (grand encart preserve) | 2 | 2 | OK preserve |
| `register-confirm-plan` (data-testid) | 1 | 1 | OK preserve |
| `register-plan-trial-pricing` (PH-20.6B retire) | 0 | 0 | OK retire |
| `SaaSAnalytics.tsx` diff | 0 | 0 | OK Clarity route-gated INCHANGE |
| Fake event scan src/components/tracking | 0 | 0 | OK |

## E6 TESTS

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit --skipLibCheck` | 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes (baseline PH-19.0 hors scope) ; 0 nouvelle erreur src introduite | OK |

## E7 COMMIT + PUSH CLIENT

| Item | Valeur |
|---|---|
| Stage scope | app/register/page.tsx UNIQUEMENT (tsconfig.tsbuildinfo non staged) |
| Commit hash | be45f1d70c72a1c7431f8e40ace733e85258d3b6 |
| Commit short | be45f1d |
| Commit title | fix(register): refine plan CTA copy and trial microcopy |
| Stats | 1 file changed, 27 insertions(+), 17 deletions(-) |
| Push | OK 97bdd5b..be45f1d ph148/onboarding-activation-replay -> origin |
| local == origin | OK |

## RUNTIME DEV/PROD INCHANGES

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev (PH-20.6A live) | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
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
- Logique pricing business INCHANGE (PRICING_CONFIG/PLANS/getAnnualPrice/ANNUAL_DISCOUNT intacts).
- Aucun changement billing/Stripe/API endpoint.
- handleConfirmPlanAndCheckout (handler create-signup + checkout-session) INCHANGE.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun tracking GA4/CAPI/Addingwell modifie.
- Comportement PH-19.x preserve : sessionStorage drafts CGU, attribution marketing, marketing_owner_tenant_id, plan_selected emission funnel step.
- PH-20.5 (KEY-343) tenantId fallback API live PROD INCHANGE.

## GAPS

1. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel :
   - CTA "Demarrer mon essai gratuit - 0 EUR aujourd hui" (lisibilite, contraste, alignement)
   - Microcopy "Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez." (dynamique : tester les 3 plans + mensuel/annuel pour valider que le prix change bien)
   - Cards plan : verifier que le rendu PH-20.6A est restaure (line-through annuel + Economisez green)
   - Grand encart "0 EUR pendant 14 jours" : preserve en haut step plan
2. PlanRecapCard preview (l.314-380, autres steps email/code/company/user/payment_cancelled) : non touche. Garde son design existant. Hors scope PH-20.6C.
3. tsc 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes baseline PH-19.0, hors scope.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH REGISTER CTA TRIAL COPY READY PH-SAAS-T8.12AS.20.6C |
| Bastion | install-v3 46.62.171.61 |
| Commit Client | be45f1d push origin ph148/onboarding-activation-replay |
| Fichier patche | app/register/page.tsx (+27 -17 = +10 net, -324 bytes) |
| CTA label | "Demarrer mon essai gratuit - 0 EUR aujourd hui" (remplace "Confirmer ce plan et activer l essai 14 jours") |
| Microcopy CTA | IIFE dynamique "Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez." |
| PH-20.6B cards | RETIRE source (revert PH-20.6A pricing PH33.11) |
| PH-20.6A markers source preserves | TrialValueBanner=1, Toutes fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1, grand encart=2 |
| Logique pricing | INCHANGE (PRICING_CONFIG, getAnnualPrice, isAnnual toggle, plan_selected emission, handleConfirmPlanAndCheckout) |
| PH-19.x + PH-20.2 preservations | OK (data-clarity-mask 13, drafts, plan_selected, Clarity route-gated) |
| Fake events delta | 0 |
| Phrase interdite "Payez 0 EUR" | absente |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6C`

STOP.
