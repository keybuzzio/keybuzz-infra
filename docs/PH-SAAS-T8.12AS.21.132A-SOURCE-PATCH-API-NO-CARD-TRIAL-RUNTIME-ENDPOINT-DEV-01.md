# PH-SAAS-T8.12AS.21.132A - SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV

Date UTC: 2026-06-26T18:39:58Z
Worker: Codex technical worker, CE-equivalent limited phase
Scope: SOURCE PATCH API DEV local only
Verdict: READY_WITH_DEBTS

## RESUME LUDOVIC

1. Endpoint runtime API ajoute localement: `POST /tenant-context/no-card-trial`.
2. API commit local: `3ded430d1925a41eee4d35a84d64533bd97b40e4`.
3. Le endpoint active un tenant signup existant `pending_payment` en trial no-card interne, sans Stripe, sans checkout, sans event outbound.
4. Le raccord entitlement a ete corrige: `tenant_metadata.is_trial + trial_ends_at` est lu comme `billingStatus="trialing"`.
5. Tests obligatoires PASS: `git diff --check`, `tsc --noEmit`, PH-21.125, PH-21.132A.
6. Aucun push, build, docker push, deploy, kubectl, DB runtime write, Stripe call, fake event, Linear, Webflow ou PROD mutation.
7. Dette conservee: dirty API preexistant limite a `dist/` supprime, non stage, non touche.
8. Prochain GO: `GO PUSH SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.132A`.

## VERDICT

`READY_WITH_DEBTS`

Phrase finale:

`GO SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.132A`

## SOURCES RELUES

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.132A_CE_MISSION.md` | LU |
| `C:\DEV\KeyBuzz\tmp\PH-21.131_CE_RETURN.md` | LU |
| `C:\DEV\KeyBuzz\tmp\PH-21.130_CE_RETURN.md` | LU |
| `C:\DEV\KeyBuzz\tmp\PH-21.125_CE_RETURN.md` | LU |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.131-READONLY-DESIGN-CLIENT-NO-CARD-TRIAL-ONBOARDING-AND-LAUNCH-PRICING-2026-DEV-01.md` | LU |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.130-READONLY-CLOSE-API-NO-CARD-TRIAL-ENTITLEMENT-AND-LAUNCH-PRICING-2026-DEV-01.md` | LU |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.125-SOURCE-PATCH-API-NO-CARD-TRIAL-ENTITLEMENT-AND-LAUNCH-PRICING-2026-DEV-01.md` | LU |
| `AI_MEMORY/CURRENT_STATE.md` | LU |
| `AI_MEMORY/RULES_AND_RISKS.md` | LU |
| `AI_MEMORY/DOCUMENT_MAP.md` | LU |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | LU |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | LU |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | LU |

## PREFLIGHT

| Repo | Branche | HEAD avant | Origin | Dirty avant | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-api | `ph147.4/source-of-truth` | `962c0c8d62861f5642212935dda485768ca3325d` | `962c0c8d62861f5642212935dda485768ca3325d` | dette `dist/` supprime | OK avec dette connue |
| keybuzz-infra | `main` | `a3f1f0ac82680590a3f7c9a07660d1137515f0e7` | `a3f1f0ac82680590a3f7c9a07660d1137515f0e7` | clean | OK |

| Check bastion | Resultat |
| --- | --- |
| Host SSH | `install-v3` |
| IP obligatoire | `46.62.171.61` presente |
| IP interdite | `51.159.99.247` non ciblee |
| Date UTC preflight | `Fri Jun 26 06:18:51 PM UTC 2026` |

## AUDIT SOURCE

| Brique | Fichier | Constat | Decision |
| --- | --- | --- | --- |
| Routes tenant | `src/modules/auth/tenant-context-routes.ts` | Module reel sous `auth`, prefixe `/tenant-context` dans `app.ts` | Ajouter endpoint ici |
| Signup | `src/modules/auth/tenant-context-routes.ts` | `create-signup` cree ou reutilise un tenant `pending_payment` et preserve attribution/owner/funnel | Ne pas modifier le flow signup |
| Entitlement route | `src/modules/auth/tenant-context-routes.ts` | Lit `tenant_metadata`, mais gardait `billingStatus=no_subscription` pour trial interne | Corriger la lecture trialing |
| Entitlement service | `src/services/entitlement.service.ts` | Fallback ancien `tenants.created_at+14d`, pas de lecture metadata trial | Preferer `tenant_metadata.trial_ends_at`, garder fallback |
| Billing helper | `src/modules/billing/no-card-trial.ts` | Contrat PH-21.125 present, sans route runtime | Etendre helper pour validation/response runtime |
| Stripe billing | `src/modules/billing/routes.ts` | StartTrial/Purchase restent lies au checkout/webhook Stripe | Ne pas modifier |
| Funnel/outbound | `src/modules/funnel/routes.ts`, `src/modules/outbound-conversions/*` | `register_started`, `trial_page_viewed`, StartTrial/Purchase preserves | Ne pas brancher `trial_started_no_card` |

## DESIGN RETENU

| Decision | Choix | Raison |
| --- | --- | --- |
| Endpoint | `POST /tenant-context/no-card-trial` | Endpoint recommande PH-21.131, meme surface auth/tenant |
| Auth | `X-User-Email` + verification `user_tenants` | Pattern local tenant-context |
| Plan | STARTER/PRO/AUTOPILOT seulement | Preserve plans canoniques |
| Cycle | `monthly` par defaut, `monthly/annual` acceptes | Validation stricte sans Stripe |
| Activation | `tenants.status: pending_payment -> active` | Leve le verrou payment-first |
| Trial source | `tenant_metadata.is_trial=true`, `trial_ends_at=now+14j` | Source runtime existante |
| Entitlement | Route + service lisent le trial metadata comme `trialing` | Contrat Client coherent |
| Idempotence | Si deja trialing no-card, retour etat courant | Pas de duplication trial/grant |
| Subscription protection | 409 si `billing_subscriptions` active/trialing/past_due/incomplete/unpaid | Pas de downgrade payant |
| KBActions | Grant interne idempotent via wallet/ledger, cap plan | KBActions conservees comme monnaie client |
| Tracking | Aucun event envoye | No fake events |

## ENDPOINT CONTRACT

```text
POST /tenant-context/no-card-trial
Body: { tenantId, plan, cycle?, attribution?, funnel_id? }
```

Reponse succes:

```json
{
  "success": true,
  "tenantId": "<tenant>",
  "plan": "PRO",
  "selectedPlan": "PRO",
  "effectivePlan": "AUTOPILOT_ASSISTED",
  "billingStatus": "trialing",
  "trialStartedAt": "<iso>",
  "trialEndsAt": "<iso>",
  "daysLeftTrial": 14,
  "requiresCardAtStart": false,
  "stripeRequiredAtStart": false,
  "nextPath": "/dashboard"
}
```

## DB / SOURCE SCHEMA DECISION

Aucune migration source ajoutee.

Le patch reutilise les tables/colonnes existantes:

| Table | Colonnes utilisees | Action source |
| --- | --- | --- |
| `tenants` | `status`, `plan`, `selected_plan`, `trial_entitlement_plan` | update seulement par endpoint runtime futur |
| `tenant_metadata` | `is_trial`, `trial_ends_at` | insert/update par endpoint runtime futur |
| `billing_subscriptions` | `status` | lecture protection abonnement |
| `ai_actions_wallet` | `remaining`, `included_monthly` | grant KBActions interne idempotent |
| `ai_actions_ledger` | `reason`, `request_id` | idempotence grant interne |

Cette phase n'a applique aucune mutation DB runtime.

## FICHIERS MODIFIES

| Fichier | Changement | Raison | Risque |
| --- | --- | --- | --- |
| `src/modules/auth/tenant-context-routes.ts` | Ajout endpoint `POST /no-card-trial`; correction entitlement route | Runtime no-card trial + billingStatus coherent | Moyen, couvert par tsc/tests |
| `src/modules/billing/no-card-trial.ts` | Helpers validation plan/cycle, effective plan, response runtime | Centraliser contrat no-card | Faible |
| `src/modules/billing/index.ts` | Exports helpers no-card | Usage route/tests | Faible |
| `src/services/entitlement.service.ts` | Lecture `tenant_metadata.trial_ends_at` avant fallback `created_at+14d` | Coherence service IA/API | Moyen, fallback preserve |
| `src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts` | Tests offline endpoint/entitlement/safety | Couverture PH-21.132A | Faible |

## TESTS

| Test | Commande | Attendu | Resultat |
| --- | --- | --- | --- |
| Diff check | `git diff --check -- src/modules/auth/tenant-context-routes.ts src/modules/billing/index.ts src/modules/billing/no-card-trial.ts src/services/entitlement.service.ts src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts` | 0 whitespace error | PASS |
| TypeScript | `/opt/keybuzz/keybuzz-api/node_modules/.bin/tsc --noEmit --project /opt/keybuzz/keybuzz-api/tsconfig.json` | compile complet | PASS |
| PH-21.125 | `tsc ... ph21125... && node /tmp/keybuzz-ph21125-tests/tests/ph21125-no-card-trial-pricing-tests.js` | 31 assertions | PASS, 31/31 |
| PH-21.132A | `tsc ... ph21132a... && node /tmp/keybuzz-ph21132a-tests/tests/ph21132a-no-card-trial-runtime-endpoint-tests.js` | no-card endpoint/entitlement/safety | PASS, 75/75 |

## NO FAKE METRICS / NO FAKE EVENTS

| Interdit | Resultat |
| --- | --- |
| `StartTrial` cree ou redefini | Non |
| `Purchase` cree ou redefini | Non |
| `CompletePayment` cree ou redefini | Non |
| `trial_page_viewed` cree | Non |
| `register_started` cree | Non |
| POST `/funnel/event` | Non |
| CAPI/GA4/TikTok/LinkedIn call | Non |
| Stripe call / checkout | Non |
| Outbound adapters modifies | Non |

`trial_started_no_card` reste un event product lifecycle interne source; aucun branchement outbound/funnel ajoute.

## AI FEATURE PARITY / ANTI-REGRESSION

| Point | Resultat |
| --- | --- |
| KBActions comme monnaie client | Preserve, grant via `getPlanIncludedKBActions()` |
| Cout LLM expose au client | Non modifie |
| STARTER/PRO/AUTOPILOT plans canoniques | Preserve |
| AUTOPILOT global | Non ouvert; STARTER/PRO utilisent `AUTOPILOT_ASSISTED` trial guardrail |
| `PROVIDER_CREDIT_EXHAUSTED` | Source preservee, non modifiee |
| Meta CAPI observability | Source preservee, non modifiee |
| Inbox/messages/IA | Non touches hors entitlement service utilise en lecture |

## NO SIDE-EFFECT

| Surface | Resultat |
| --- | --- |
| Push API/infra | 0 |
| Build / docker push | 0 |
| Deploy / kubectl apply | 0 |
| `kubectl set image/env/patch/edit` | 0 |
| DB runtime write | 0 |
| Stripe live call | 0 |
| Fake event / replay / CAPI retry | 0 |
| Client / Website / Admin / Backend patch | 0 |
| Webflow / Linear | 0 |
| PROD mutation | 0 |

## COMMITS LOCAUX

| Repo | Commit local | Message | Push |
| --- | --- | --- | --- |
| keybuzz-api | `3ded430d1925a41eee4d35a84d64533bd97b40e4` | `feat(onboarding): add no-card trial runtime endpoint` | Non |
| keybuzz-infra | commit docs local de ce rapport, hash exact dans le retour CE final | `docs(PH-21.132A): source patch API no-card trial runtime endpoint` | Non |

## DETTES

| Dette | Impact | Suite |
| --- | --- | --- |
| Dirty API preexistant `dist/` supprime | Dette process, non source | Cleanup dedie sans `git reset --hard` ni `git clean` |
| Aucun build/deploy dans cette phase | Normal, hors scope | GO push puis build/deploy DEV separes |
| Client pas encore patche | Trial no-card pas consomme par UI | Phase Client apres endpoint API pousse/deploye |

## ETAT FINAL ATTENDU

| Repo | Etat final attendu |
| --- | --- |
| keybuzz-api | ahead 1 / behind 0, dirty seulement dette `dist/` preexistante |
| keybuzz-infra | ahead 1 / behind 0 apres commit rapport, clean |

## PROCHAIN GO

`GO PUSH SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.132A`

STOP
