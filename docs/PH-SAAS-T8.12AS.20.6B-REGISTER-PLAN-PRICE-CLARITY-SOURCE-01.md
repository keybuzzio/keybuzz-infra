# PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6B REGISTER PLAN PRICE CLARITY SOURCE
> Environnement : SOURCE PATCH Client uniquement (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH REGISTER PLAN PRICE CLARITY READY PH-SAAS-T8.12AS.20.6B

- Source patch unique `app/register/page.tsx` : +13 -15 = -2 net (+324 bytes).
- Bloc pricing vert clair par card plan : "0 EUR maintenant" + "puis {displayPrice} EUR/mois dans 14 jours" + ligne discrete annuel.
- Design : un seul bloc, evite double prix barre confus vs remise annuelle existante.
- Preservations PH-19.x + PH-20.2 OK : data-clarity-mask=13, drafts CGU, plan_selected, SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- Preserve grand encart "0 EUR pendant 14 jours" l.755 (reassurance globale step plan).
- Preserve markers : register-plan-card, register-plan-grid, register-plan-trial-pricing.
- 0 fake event delta.
- Logique pricing existante INCHANGE : displayPrice/isAnnual/getAnnualPrice/PRICING_CONFIG/PLANS/ANNUAL_DISCOUNT.
- Commit Client `97bdd5b` push origin `ph148/onboarding-activation-replay` OK.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Aucun build, aucun deploy, aucune mutation DB/Stripe.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 21:40 |
| keybuzz-client branche/HEAD avant | ph148/onboarding-activation-replay / dbdc46f |
| keybuzz-client dirty | 1 (tsconfig.tsbuildinfo artefact preexistant, hors scope) |
| keybuzz-infra branche/HEAD | main / ef9c79e (post APPLY DEV PH-20.6A) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev (PH-20.6A live) |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 AUDIT PRICING CARDS REGISTER

| Item | Localisation source |
|---|---|
| Plan grid data-testid | l.765 register-plan-grid |
| Plan card data-testid | l.771 register-plan-card |
| Section pricing AVANT patch | l.793-806 |
| Grand encart 0 EUR pendant 14 jours (preserve) | l.732-740 |
| PRICING_CONFIG / PLANS / ANNUAL_DISCOUNT | l.38 ANNUAL_DISCOUNT, PRICING_CONFIG importe |
| Helper getAnnualPrice / displayPrice | l.767 isAnnual ? getAnnualPrice(plan.price) : plan.price |
| PlanRecapCard preview (autres steps email/code/company/user) | l.314-380 (HORS SCOPE PH-20.6B, contexte different) |

## E2 DESIGN PATCH

### Design retenu

Bloc vert premium par plan card, sous le nom du plan, AVANT la description :

```
[badge "Le plus populaire" si highlighted]
{plan.name}

+--------------------------------------+  bloc vert premium PH-20.6B
| 0 EUR                                |  text-2xl bold green-400 leading-tight
| maintenant                           |  text-sm font-semibold white -mt-0.5
| puis {displayPrice} EUR/mois         |  text-xs gray-300 leading-relaxed
|   dans 14 jours                      |  ({displayPrice} en font-semibold white)
| Tarif annuel : economisez X EUR/an   |  (si annuel uniquement, text-[11px] green-400/80)
|   vs mensuel                         |
+--------------------------------------+

{plan.description}
{plan.features list}
```

### Alternative rejetee

Garder le line-through annuel existant ET ajouter le nouveau bloc 0 EUR par-dessus :
- Cree DOUBLE mecanique prix barre confuse pour utilisateur en annuel (prix barre + bloc 0 EUR = 2 reductions visuelles superposees)
- Le brief Ludovic dit explicitement : "Ne pas barrer tous les prix si cela cree une confusion avec la remise annuelle. Preferer un bloc 0 EUR / maintenant / puis <prix> dans 14 jours"
- REJETE pour cette raison.

### Design retenu - justification

UN SEUL bloc vert qui contient :
1. La promesse essai (0 EUR maintenant) - hero
2. Le prix futur (puis X EUR/mois dans 14 jours) - integre dans la meme zone
3. La remise annuelle (si applicable, ligne discrete inferieure) - SANS line-through redondant

L info "remise annuelle vs mensuel" reste lisible mais sans confusion prix barre.

### Code changement

| Avant (PH33.11 strikethrough) | Apres (PH-20.6B bloc vert) |
|---|---|
| h3 plan.name mb-1 | h3 plan.name mb-3 |
| isAnnual ? span line-through plan.price : null | (retire, integre via ligne discrete dans bloc) |
| div displayPrice/mois (text-3xl bold) | bloc vert div register-plan-trial-pricing |
| isAnnual ? p green Economisez X/an : null | (integre dans bloc vert si annuel) |

## E3 PATCH SOURCE

| Indicateur | Valeur |
|---|---|
| Fichier touche | `app/register/page.tsx` (1 fichier) |
| Delta lignes | +13 -15 = -2 net (+324 bytes : annotation longue + classes Tailwind etendues) |
| Script de patch | `/tmp/patch-register-ph206b.py` (substitution Python deterministe) |

## E4 VERIFICATION DIFF

| Verification | Resultat |
|---|---|
| Diff scope strict | uniquement `app/register/page.tsx` (+ tsconfig.tsbuildinfo non staged) |
| Key strings nouveaux PH-20.6B | "0 EUR maintenant"=1, "register-plan-trial-pricing"=1, "Tarif annuel : economisez"=1 (avec accent), "puis displayPrice EUR/mois...dans 14 jours" |
| Forbidden fake events delta | aucun (Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-) |

## E5 ASSERTIONS PRESERVATION

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| `0 EUR maintenant` count | 1 nouveau | 1 | **OK nouveau marker present** |
| `register-plan-trial-pricing` data-testid | 1 nouveau | 1 | **OK** |
| `dans 14 jours` count | 2 (grand encart + nouveau bloc plan card) | 2 | OK delta attendu |
| `0 EUR pendant 14 jours` count | 2 (preserve : TrialValueBanner + grand encart plan) | 2 | OK preserve |
| `data-clarity-mask` count | 13 | 13 | **OK preserve** |
| `kb_signup_form_draft_v1` count | 2 | 2 | OK |
| `kb_signup_cgu_accepted` count | 2 | 2 | OK |
| `plan_selected` count | 2 | 2 | OK |
| `register-plan-card` data-testid | 1 | 1 | OK preserve |
| `register-plan-grid` data-testid | 1 | 1 | OK preserve |
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
| Commit hash | 97bdd5bf9f197807283c09e4a41e93e5fce11b5b |
| Commit short | 97bdd5b |
| Commit title | fix(register): clarify trial pricing on plan cards |
| Stats | 1 file changed, 13 insertions(+), 15 deletions(-) |
| Push | OK dbdc46f..97bdd5b ph148/onboarding-activation-replay -> origin |
| local == origin | OK |

## RUNTIME DEV/PROD INCHANGES

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev | INCHANGE (aucun build) |
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
- Logique pricing business INCHANGE (PRICING_CONFIG/PLANS/ANNUAL_DISCOUNT/getAnnualPrice intacts).
- Aucun changement event tracking (plan_selected emission unique preservee).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun tracking GA4/CAPI/Addingwell modifie.
- Comportement PH-19.x preserve : sessionStorage drafts CGU, attribution marketing, marketing_owner_tenant_id, plan_selected emission funnel step.
- PH-20.5 (KEY-343) tenantId fallback API live PROD INCHANGE.

## GAPS

1. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel cards (3 plans starter/pro/autopilot en mensuel ET annuel, mobile 360px + desktop).
2. PlanRecapCard preview (l.314-380, autres steps que `plan`) reste sur l ancien design line-through annuel. Hors scope PH-20.6B (cible specifique = step plan grid cards). Si Ludovic souhaite aussi clarifier ce preview, ce sera PH-20.6C dedie.
3. tsc 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes baseline PH-19.0, hors scope.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH REGISTER PLAN PRICE CLARITY READY PH-SAAS-T8.12AS.20.6B |
| Bastion | install-v3 46.62.171.61 |
| Commit Client | 97bdd5b push origin ph148/onboarding-activation-replay |
| Fichier patche | app/register/page.tsx (+13 -15 = -2 net, +324 bytes) |
| Design retenu | bloc vert unique par card (titre 0 EUR, sous-titre maintenant, ligne puis X EUR/mois dans 14 jours, ligne annuel discrete sans line-through redondant) |
| Alternative rejetee | double prix barre annuel + bloc 0 EUR superpose (confusion utilisateur) |
| Logique pricing | INCHANGE (displayPrice/isAnnual/getAnnualPrice/PRICING_CONFIG) |
| Nouveaux markers | 0 EUR maintenant=1, register-plan-trial-pricing=1, Tarif annuel : economisez=1 (avec accent) |
| PH-19.x + PH-20.2 preservations | OK (data-clarity-mask 13, drafts, plan_selected, Clarity route-gated) |
| Markers preserves | register-plan-card=1, register-plan-grid=1, grand encart 0 EUR pendant 14 jours=2 |
| Fake events delta | 0 |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6B`

STOP.
