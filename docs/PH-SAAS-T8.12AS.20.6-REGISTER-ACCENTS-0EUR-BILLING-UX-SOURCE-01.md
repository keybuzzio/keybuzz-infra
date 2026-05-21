# PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-342 (accents FR primary) ; KEY-345 (0 EUR every step + benefits primary) ; KEY-343 (UX billing error related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6 REGISTER ACCENTS + 0EUR EVERY STEP + UX BILLING ERROR SOURCE
> Environnement : SOURCE PATCH Client uniquement (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH REGISTER ACCENTS 0EUR BILLING UX READY PH-SAAS-T8.12AS.20.6

- Source patch unique `app/register/page.tsx` : +39 lignes / -19 lignes = +20 net.
- 18/18 accents FR substitutions appliquees.
- TrialValueBanner ajoute (`data-testid=register-trial-value-banner`) visible step email/code/company/user (sauf plan/checkout/payment_cancelled).
- UX billing error l.558 reecrite (messages plus rassurant + actionable, sans pretendre que paiement actif).
- PH-19.x + PH-20.2 preservations TOUTES OK : data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected emission unique, SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- 0 fake events delta : aucun Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- Aucun changement API endpoint, event id, storage key.
- Commit Client `3f88217` push origin `ph148/onboarding-activation-replay` OK.
- Aucun build. Aucun deploy. Aucune mutation DB/Stripe.
- KEY-343 root fix (tenantId fallback) deja live PROD via PH-20.5.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 18:46 |
| keybuzz-client branche/HEAD avant | ph148/onboarding-activation-replay / dad5f89 |
| keybuzz-client dirty | 1 (tsconfig.tsbuildinfo artefact preexistant, hors scope) |
| keybuzz-infra branche/HEAD | main / f8dba5b (post APPLY PROD) |
| keybuzz-infra dirty | 0 |
| Runtime Client DEV | v3.5.206-clarity-register-dev |
| Runtime Client PROD | v3.5.200-clarity-register-prod |

## E1 AUDIT SOURCE REGISTER

| Item | Resultat |
|---|---|
| `app/register/page.tsx` lignes | 1124 |
| Billing error setError ligne 558 (espace cree) | present |
| Billing error setError ligne 600 (retry support) | present, non touche PH-20.6 |
| `0 EUR` occurrences avant patch | 3 (l.666 ReassurancePanel + l.736 plan banner + l.711 microcopy) |
| `data-clarity-mask` avant patch | 13 |
| `kb_signup_form_draft_v1` | 2 (read + write) |
| `kb_signup_cgu_accepted` | 2 (read + write) |
| `plan_selected` emission | 1 + 1 commentaire = 2 occurrences textuelles |
| ReassurancePanel (desktop only `hidden lg:flex`) | l.635 |
| Progress stepper data-testid | register-step-progress l.688 |
| Steps order | email -> code -> company -> user -> plan -> checkout -> payment_cancelled |

## E2 PATCH DESIGN

### A. Accents FR (KEY-342) - 18 substitutions

| Scope | Avant | Apres |
|---|---|---|
| PlanCard footer | resiliable a tout moment | resiliable a tout moment (e aigu + a grave) |
| nextStepText label | Prochaine etape : | Prochaine etape (e aigu) |
| PlanCard guarantees | Compte vendeur non modifie | non modifie -> e aigu |
| PlanCard guarantees | Donnees limitees au strict necessaire | 3 accents aigus |
| ReassurancePanel intro | Ce que KeyBuzz va gerer | gerer (e aigu) |
| ReassurancePanel h2 | Votre cockpit SAV centralise, sous controle | centralise (aigu) + controle (circonflexe) |
| ReassurancePanel intro txt | n avez pas confirme | confirme (aigu) |
| ReassurancePanel item 2 | Copilote IA - votre equipe garde le controle | equipe + controle |
| ReassurancePanel item 4 | Donnees sensibles masquees, non modifie | 4 accents |
| ReassurancePanel footer 1 | Plan et coupon confirmes avant Stripe | confirmes (aigu) |
| ReassurancePanel footer 2 | Essai active avec Autopilot | active (aigu) |
| ReassurancePanel footer 3 | Attribution marketing preservee | preservee (aigus) |
| Header sub | qui prepare le contexte commande | prepare (aigu) |
| Header sub block | Vos equipes gardent le controle | equipes + controle |
| Plan microcopy step 1 | Votre choix fixe le plan apres l essai | apres (grave) |
| Plan microcopy step 2 | Creez votre espace | Creez (aigu) |
| Plan microcopy step 2 | Email professionnel + societe. Vos donnees sensibles restent masquees | 3 accents |
| Plan banner detail | Carte demandee a l activation. Aucun debit. Pendant 14 jours, capacites Autopilot | demandee, a, debit, capacites (4 accents) |

Aucune valeur technique touchee (ids, classNames, data-testid, event ids `plan_selected/kb_signup_*`, storage keys, API field names).

### B. TrialValueBanner (KEY-345)

| Item | Valeur |
|---|---|
| Position | Apres progress stepper, dans le header div, AVANT `{/* ===== PLAN SELECTION ===== */}` |
| Condition d affichage | `step !== 'checkout' && step !== 'plan' && step !== 'payment_cancelled'` |
| Steps cibles | email, code, company, user |
| data-testid | register-trial-value-banner |
| Layout | rounded-xl, gradient green-to-blue subtle, border green-500/30, padding 3, max-w-md mx-auto |
| Mobile responsive | grid-cols-1 sm:grid-cols-2 pour benefits list |
| Copy principal | "0 EUR pendant 14 jours" + "Carte demandee uniquement a l activation. Aucun debit avant la fin de l essai." + "Autopilot inclus pendant l essai pour tester toute la valeur." (accentue UTF-8) |
| Benefits list (4) | Cockpit SAV marketplace centralise / Connexions Amazon, Fnac, Cdiscount / Copilote IA avec contexte commande / Escalades et garde-fous configurables (accentues UTF-8) |
| Coexistence | step plan garde grand bandeau vert fort existant (l.732-740). step payment_cancelled garde Retry flow distinct. Desktop ReassurancePanel inchange. |

### C. UX billing error (KEY-343)

| Avant | Apres |
|---|---|
| "Impossible de creer la session de paiement. Votre espace a ete cree, rendez-vous dans Facturation." | "Votre espace a bien ete cree, mais la session de paiement n a pas pu etre ouverte automatiquement. Connectez-vous puis allez dans Facturation pour finaliser l activation, ou contactez le support si besoin." |

Message setError l.600 retry support inchange.

Root fix tenantId fallback API live PROD via PH-20.5 (commit api 6850427c + runtime v3.5.251-billing-tenant-id-fallback-prod).

## E3 PATCH SOURCE

| Item | Valeur |
|---|---|
| Fichier touche | `app/register/page.tsx` (1 fichier) |
| Delta lignes | +39 -19 = +20 net |
| Delta bytes | +1947 |
| Script de patch | `/tmp/patch-register-ph206.py` (substitutions Python deterministes) |

## E4 VERIFICATION DIFF

| Verification | Resultat |
|---|---|
| diff stat scope | uniquement `app/register/page.tsx` (+ tsconfig.tsbuildinfo non staged) |
| Forbidden fake events scan | aucun (Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-) |
| Forbidden API change scan | aucun (fetch / /api/ / tenantId= / emitFunnelStep non modifies) |
| Retrait data-clarity-mask | aucun |
| Retrait Clarity route-gating | aucun |
| Hardcode secret/token | aucun |

## E5 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit --skipLibCheck` global | 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes (PH-19.0 baseline, hors scope) ; 0 nouvelle erreur src introduite | OK |
| package.json test/lint scripts disponibles | uniquement `build`, `lint`, `prebuild` | OK |
| Lint targeted | n/a (eslint accepte mais hors scope) | OK |

Pas de framework de tests automatises. Verification visuelle differee a phase BUILD DEV + QA navigateur Ludovic.

## E6 ASSERTIONS PH-19.x + PH-20.2 PRESERVES

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| `data-clarity-mask` count | 13 | 13 | **OK preserve** |
| `kb_signup_form_draft_v1` count | 2 | 2 | OK preserve |
| `kb_signup_cgu_accepted` count | 2 | 2 | OK preserve |
| `plan_selected` count | 2 (1 emission + 1 commentaire) | 2 | OK preserve |
| `0 EUR pendant 14 jours` count | 3 -> 4 (nouveau TrialValueBanner) | 4 | OK delta attendu |
| `register-trial-value-banner` | 1 nouveau | 1 | OK |
| `SaaSAnalytics.tsx` diff | 0 | 0 | OK Clarity route-gated INCHANGE |
| Fake event scan src/components/tracking | 0 | 0 | OK |

## E7 COMMIT + PUSH CLIENT

| Item | Valeur |
|---|---|
| Stage scope | app/register/page.tsx UNIQUEMENT (tsconfig.tsbuildinfo non staged) |
| Commit hash | 3f882173b8e491a835cd58849665b483e9408041 |
| Commit short | 3f88217 |
| Commit title | fix(register): polish french copy trial banner and billing error |
| Stats | 1 file changed, 39 insertions(+), 19 deletions(-) |
| Push | OK dad5f89..3f88217 ph148/onboarding-activation-replay -> origin |
| local == origin | OK |

## RUNTIME DEV/PROD INCHANGES

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE (aucun build) |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE (aucun build) |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE (PH-20.5 deja live) |
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
- AUCUNE modification API.
- AUCUNE modification Website/Admin.
- AUCUN cleanup tenant orphan.
- AUCUN ticket Linear statut modifie.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- data-clarity-mask preserves (13).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun tracking GA4/CAPI/Addingwell modifie.
- Comportement PH-19.x preserve : sessionStorage drafts CGU, attribution marketing, marketing_owner_tenant_id, plan_selected emission.
- TrialValueBanner = bloc UI texte only, sans tracking event ajoute.

## GAPS

1. Pas de framework de tests automatises Jest/Vitest cote keybuzz-client pour valider rendering visuel TrialValueBanner. QA navigateur Ludovic recommandee en phase APPLY DEV (mobile 360px + desktop responsive).
2. UX billing error C4 actuelle est copy-only. Une amelioration future possible : ajouter action "Aller a Facturation" cliquable si auth deja active. Hors scope PH-20.6 (necessite audit auth flow).
3. tsc 2 erreurs `.next/types/app/api/debug-env/route.ts` preexistantes baseline PH-19.0 - sans rapport avec PH-20.6, deja documentees PH-19.x.
4. Tenant orphan PROD `-mpfmgx09` Antoine reste a cleaner en PH-20.7 (decision destructive separee).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH REGISTER ACCENTS 0EUR BILLING UX READY PH-SAAS-T8.12AS.20.6 |
| Bastion | install-v3 46.62.171.61 |
| Commit Client | 3f88217 push origin ph148/onboarding-activation-replay |
| Fichier patche | app/register/page.tsx (+39 -19 = +20 net, +1947 bytes) |
| Accents FR (KEY-342) | 18/18 substitutions OK |
| TrialValueBanner (KEY-345) | insere, visible 4 steps (email/code/company/user) |
| UX billing error (KEY-343) | message reecrit l.558, root fix API deja live PROD PH-20.5 |
| PH-19.x preservations | data-clarity-mask 13, drafts 2/2, plan_selected 1, Clarity route-gated INCHANGE |
| 0 EUR pendant 14 jours | 3 -> 4 (+TrialValueBanner) |
| Fake events delta | 0 |
| Runtime Client DEV+PROD | INCHANGES (aucun build) |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6`

STOP.
