# PH-SAAS-T8.12AS.21.125 - SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV

## 1. Resume Ludovic

Verdict: READY_WITH_DEBTS.

Le patch source API DEV est localement committe dans `keybuzz-api`. Il ajoute un contrat API/source pour un trial no-card interne de 14 jours, sans Stripe subscription ni carte au demarrage, et centralise les prix de lancement 2026 STARTER 47 EUR, PRO 97 EUR, AUTOPILOT 197 EUR en cents.

Les routes Stripe existantes, `checkout-session`, webhooks billing et outbound conversions ne sont pas modifiees. `StartTrial`, `Purchase`, `CompletePayment`, `trial_page_viewed` et `register_started` ne sont pas redefinis.

Dette documentee: le repo API avait avant phase une dette dirty massive limitee a `dist/` supprime. Les sources `src/` ciblees etaient propres avant patch et sont propres apres commit.

Prochain GO recommande: `GO PUSH SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.125`.

## 2. Verdict

`READY_WITH_DEBTS`

Phrase cible:

`GO SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.125`

## 3. Sources relues

| Source | Statut | Note |
|---|---|---|
| `AI_MEMORY/CURRENT_STATE.md` | LU | Contexte KeyBuzz courant |
| `AI_MEMORY/RULES_AND_RISKS.md` | LU | Regles build, GitOps, no fake events |
| `AI_MEMORY/DOCUMENT_MAP.md` | LU | Carte documentaire |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | LU | Standard CE |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | LU | Protocole retour |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | LU | Modele prompt |
| `PH-21.124_CE_RETURN.md` | LU | Verdict READY_SOURCE_PATCH_API_DEV |
| `PH-SAAS-T8.12AS.21.124-READONLY-DESIGN...md` | PRESENT | Source immediate confirmee |
| `PH-SAAS-T8.12C-TRIAL-ENTITLEMENT-SCHEMA-AND-API-DEV-01.md` | LU | Trial entitlement existant, colonnes tenants |
| `PH-SAAS-T8.12X-TRIAL-WOW-STACK-CLOSURE...md` | LU | Baseline trial wow |
| `PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md` | LU | StartTrial lie Stripe/subscription |
| `PH-BILLING-PLAN-TRUTH-RECOVERY-02-REPORT.md` | LU | Coherence billing/current |
| `PH129-PLAN-AUDIT-01-REPORT.md` | LU | Plans et gating |
| `FEATURE_TRUTH_MATRIX_V2.md` | LU | KBActions, Autopilot, gates IA |

Aucune contradiction source recente detectee.

## 4. Preflight repo / bastion

| Repo | Branche | HEAD avant | HEAD apres | Dirty avant | Dirty apres | Ahead/behind | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | `547648fd1fcb05d291157a5119cd35d141905cdf` | `962c0c8d62861f5642212935dda485768ca3325d` | Oui, `dist/` supprime preexistant; `src/` propre | Oui, meme dette `dist/`; `src/` PH propre | ahead 1 / behind 0 | OK avec dette |
| keybuzz-infra | main | `c4f15137df7f3af2d9b2e4ce86e776626fbbbd60` | ce commit docs local | propre | propre attendu apres commit | ahead 1 / behind 0 attendu | OK |

Bastion:

| Check | Resultat |
|---|---|
| hostname | `install-v3` |
| IP obligatoire | `46.62.171.61` presente |
| IP interdite | `51.159.99.247` non observee |
| date UTC | `Fri Jun 26 02:51:38 PM UTC 2026` |

## 5. Baseline runtime lue en read-only

Baselines imposees preservees, aucune mutation runtime:

| Service | Baseline imposee | Resultat |
|---|---|---|
| API DEV | `v3.5.265-meta-capi-error-observability-dev` digest `sha256:a19fbf42...` | inchange, non deploye |
| API PROD | `v3.5.265-meta-capi-error-observability-prod` digest `sha256:ca11a4e...` | inchange, non deploye |
| Client DEV/PROD | baselines PH-21.124 | non touche |
| Website DEV/PROD | baselines PH-21.124 | non touche |

## 6. Audit source API

| Domaine | Fichiers source | Constats | Risque | Decision patch |
|---|---|---|---|---|
| Billing Stripe | `src/modules/billing/routes.ts`, `pricing.ts`, `stripe.ts` | `/billing/checkout-session` cree Stripe Checkout avec `trial_period_days: 14` et `payment_method_collection: always` | Friction CB conservee tant que Client appelle checkout | Ne pas modifier checkout; ajouter contrat source no-card separe |
| Onboarding tenant | `src/services/entitlement.service.ts`, rapports T8.12C | `tenants.trial_entitlement_plan` existe deja; fallback trial 14j via `created_at` | Pas encore endpoint create trial no-card | Poser contrat minimal source testable |
| Trial entitlement | `src/services/entitlement.service.ts` | `trialing` sans subscription deja modelise en fallback | Confusion avec Stripe trial possible | Module dedie `no-card-trial.ts` explicite |
| Pricing | `src/modules/billing/pricing.ts` | `PLAN_PRICES` exposait 97/297/497 | Ancien pricing dans source API | Centraliser `LAUNCH_PRICING_2026` 4700/9700/19700 |
| KBActions | `src/config/kbactions.ts` | limites canoniques: starter 0, pro 1000, autopilot 2000 | Trial illimite si cap absent | Reutiliser `getPlanIncludedKBActions()` |
| Funnel/tracking | `src/modules/funnel/routes.ts`, `outbound-conversions/emitter.ts` | `register_started` peut emettre `trial_page_viewed`; outbound = `StartTrial`/`Purchase` + `trial_page_viewed` | Pollution conversion si nouvel event branche | `trial_started_no_card` interne seulement, pas allowlist funnel/outbound |

## 7. Design patch retenu

| Decision | Choix retenu | Justification | Risque residuel |
|---|---|---|---|
| Trial no-card model | Module source `buildNoCardTrialContract()` | Contrat clair sans DB runtime ni Stripe | Endpoint create trial a faire phase suivante |
| Pricing source | `LAUNCH_PRICING_2026` en cents + `PLAN_PRICES` mensuels alignes | Source API visible 47/97/197 | Annual display garde convention 20% existante |
| KBActions cap | `getPlanIncludedKBActions(plan)` | Reutilise limites existantes, pas illimite | Commentaires historiques KBActions restent a nettoyer hors source billing |
| Event semantics | `trial_started_no_card` interne/lifecycle, non branche | Ne redefinit pas StartTrial | Emission produit a integrer avec GO Client/API futur |
| Stripe continuity | `checkout-session` non modifiee | Preserve paid conversion, webhooks, promo, upgrades | Client appellera encore checkout tant que phase Client non faite |

## 8. Fichiers modifies

| Fichier | Changement | Risque | Test associe |
|---|---|---|---|
| `src/modules/billing/pricing.ts` | Ajout `LAUNCH_PRICING_2026`, `getLaunchPricing2026`, alignement `PLAN_PRICES` mensuels | Faible; source API pricing uniquement | PH-21.125 pricing |
| `src/modules/billing/no-card-trial.ts` | Nouveau contrat no-card trial 14j, statut, dates, no Stripe/card, cap KBActions | Faible; non branche runtime | PH-21.125 trial/KBActions |
| `src/modules/billing/index.ts` | Exports du contrat pricing/trial | Faible | `tsc --noEmit` |
| `src/tests/ph21125-no-card-trial-pricing-tests.ts` | Test offline dedie | Faible | test PH-21.125 |

## 9. Contrat pricing 2026

| Plan | Prix attendu | Prix source apres patch | Devise | Verdict |
|---|---:|---:|---|---|
| STARTER | 47 | 4700 cents / 47 display | EUR | PASS |
| PRO | 97 | 9700 cents / 97 display | EUR | PASS |
| AUTOPILOT | 197 | 19700 cents / 197 display | EUR | PASS |

## 10. Contrat trial entitlement

| Element | Attendu | Source apres patch | Verdict |
|---|---|---|---|
| duree trial | 14 jours | `NO_CARD_TRIAL_DAYS = 14` | PASS |
| CB requise au debut | non | `requiresCardAtStart: false` | PASS |
| Stripe au debut | non | `stripeRequiredAtStart: false`, `stripeSubscriptionId: null` | PASS |
| upgrade payant | conserve | checkout Stripe existant non modifie | PASS |
| KBActions cap | present ou dette documentee | `getPlanIncludedKBActions(plan)` | PASS |

## 11. Event safety

| Event | Semantique attendue | Change par PH-21.125 | Verdict |
|---|---|---|---|
| trial_page_viewed | page register | non casse | PASS |
| register_started | micro-step register | non casse | PASS |
| StartTrial | Stripe/subscription historique | non redefini | PASS |
| Purchase | paiement reel | non redefini | PASS |
| CompletePayment | paiement reel | non redefini | PASS |
| trial_started_no_card | lifecycle interne si ajoute | contrat interne, pas outbound | PASS |

## 12. Tests executes

| Test | Commande | Resultat | Commentaire |
|---|---|---|---|
| git diff --check | `git diff --check -- src/modules/billing/index.ts src/modules/billing/pricing.ts src/modules/billing/no-card-trial.ts src/tests/ph21125-no-card-trial-pricing-tests.ts` | PASS | Source patch propre |
| tsc | `npx tsc --noEmit` | PASS | Aucun appel reseau/runtime |
| PH-21.125 pricing/trial/tracking | `npx tsc ... --outDir /tmp/keybuzz-ph21125-tests ... && node /tmp/keybuzz-ph21125-tests/tests/ph21125-no-card-trial-pricing-tests.js` | PASS | 31 assertions, 0 failed |
| grep old billing prices | `grep -R monthly:297/497... src/modules/billing` | PASS | 0 occurrence |
| grep no-card outbound/funnel | `grep -R trial_started_no_card src/modules/outbound-conversions src/modules/funnel` | PASS | 0 occurrence |

## 13. Non-regression

| Verification | Resultat | Preuve |
|---|---|---|
| StartTrial preserved | PASS | `outbound-conversions/emitter.ts` non modifie |
| Purchase preserved | PASS | `outbound-conversions/emitter.ts` non modifie |
| CompletePayment preserved | PASS | adapters non modifies |
| trial_page_viewed preserved | PASS | `TRIAL_PAGE_VIEWED_EVENT_NAME` non modifie |
| register_started preserved | PASS | funnel allowlist non modifiee |
| No tenant hardcode | PASS | Aucun tenant/email hardcode ajoute |
| No secret | PASS | Aucun secret/env ajoute |
| API-only patch | PASS | Seuls fichiers `keybuzz-api/src` et rapport infra docs |

## 14. No side-effect

| Surface | Attendu | Resultat |
|---|---|---|
| Push | 0 | 0 |
| Build | 0 | 0 |
| Docker push | 0 | 0 |
| Deploy/kubectl apply | 0 | 0 |
| DB runtime write | 0 | 0 |
| Stripe live call | 0 | 0 |
| Checkout | 0 | 0 |
| Fake event | 0 | 0 |
| CAPI retry/replay | 0 | 0 |
| Client/Website/Admin/Backend patch | 0 | 0 |
| PROD mutation | 0 | 0 |

## 15. Commits locaux

| Repo | Commit local | Message | Push |
|---|---|---|---|
| keybuzz-api | `962c0c8d62861f5642212935dda485768ca3325d` | `feat(billing): add no-card trial entitlement and launch pricing contract` | non |
| keybuzz-infra | commit contenant ce rapport | `docs(PH-21.125): source patch API no-card trial and launch pricing 2026` | non |

## 16. Dirty / ahead / behind final

| Repo | Dirty final | Ahead/behind | Note |
|---|---|---|---|
| keybuzz-api | dette preexistante `dist/` supprime; sources PH propres | ahead 1 / behind 0 | Ne pas revert, ne pas clean |
| keybuzz-infra | propre attendu apres commit docs | ahead 1 / behind 0 | Rapport local seulement |

## 17. Dettes et limites

| Dette | Severite | Suite |
|---|---|---|
| API dirty preexistante `dist/` supprime | Moyenne process | Nettoyage dedie sans `git reset --hard` ni `git clean` |
| Pas encore endpoint runtime create no-card trial | Normale, hors scope | Phase Client/API integration suivante |
| `checkout-session` garde Stripe trial et carte obligatoire | P0 produit mais preserve volontairement | Phase Client DEV supprimera checkout obligatoire |
| Stripe Price IDs launch 2026 non crees/verifies | Hors scope OPS | Phase Stripe/config dediee |
| Commentaires historiques KBActions avec anciens prix possibles hors billing | Faible docs/code comments | Alignement docs/source non fonctionnel futur |

## 18. Prochain GO recommande

`GO PUSH SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.125`

STOP
