# PH-SAAS-T8.12AS.21.131 - READONLY DESIGN CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV

Date UTC: 2026-06-26
Worker: Codex technical worker, CE-equivalent limited phase
Scope: READONLY DESIGN DEV + infra docs-only report
Verdict: READY_API_ENDPOINT_REQUIRED_BEFORE_CLIENT

## RESUME LUDOVIC

1. Verdict: READY_API_ENDPOINT_REQUIRED_BEFORE_CLIENT.
2. Le Client actuel est bien email-first, mais il cree ensuite un tenant `pending_payment`, appelle `/api/billing/checkout-session`, emet `trackBeginCheckout`, puis redirige vers Stripe.
3. L'API PH-21.130 expose le pricing 2026 et un contrat source `no-card-trial.ts`, mais aucun endpoint runtime ne cree/active un trial no-card consommable par le Client.
4. Un patch Client seul serait dangereux: sans checkout, le tenant resterait `pending_payment` et l'entitlement Client/API le verrouillerait avec `PENDING_PAYMENT`.
5. Decision API/BFF: petite phase API DEV obligatoire avant Client pour creer/activer un trial interne no-card idempotent, conserver attribution/funnel et retourner la cible de redirection.
6. Pricing Client a aligner ensuite: `pricing/config.ts` et `billing/planCapabilities.ts` affichent encore 97/297/497 au lieu de 47/97/197.
7. Tracking: preserver `trial_page_viewed`, `register_started`, owner/UTM/click IDs; ne pas creer `StartTrial`, `Purchase`, `CompletePayment`, checkout ou event Ads fake.
8. Build safety future Client: build args DEV explicites, bundle DEV contient `https://api-dev.keybuzz.io` et ne contient pas `https://api.keybuzz.io`.
9. Prochain GO: `GO SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.132A`.

## VERDICT

`READY_API_ENDPOINT_REQUIRED_BEFORE_CLIENT`

Phrase finale:

`GO READONLY DESIGN CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV READY_API_ENDPOINT_REQUIRED_BEFORE_CLIENT PH-SAAS-T8.12AS.21.131`

Prochain GO exact:

`GO SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.132A`

## SOURCES RELUES

| Source | Statut | Note |
| --- | --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.124_CE_RETURN.md` | LU | Design initial no-card/pricing |
| `C:\DEV\KeyBuzz\tmp\PH-21.130_CE_RETURN.md` | LU | API DEV close, dette endpoint runtime |
| `C:\DEV\KeyBuzz\tmp\PH-21.129_CE_RETURN.md` | LU | Verify API DEV |
| `C:\DEV\KeyBuzz\tmp\PH-21.128_CE_RETURN.md` | LU | Apply API DEV |
| `C:\DEV\KeyBuzz\tmp\PH-21.125_CE_RETURN.md` | LU | Source patch API |
| `AI_MEMORY/CURRENT_STATE.md` | LU | Contexte KeyBuzz |
| `AI_MEMORY/RULES_AND_RISKS.md` | LU | Regles build/GitOps/no fake events |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | LU | Standard CE |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | LU | Retour par fichier |
| `PH-SAAS-T8.12AS.21.124...md` | LU | Design no-card |
| `PH-SAAS-T8.12AS.21.130...md` | LU | Close API no-card/pricing |
| `PH-SAAS-T8.12AS.21.125...md` | LU | Contrat source API |
| `PH-SAAS-T8.12AS.21.86...md` | LU | Client register_started owner payload |
| `PH-SAAS-T8.12AS.21.91...md` | LU | Close Client DEV owner payload |
| `PH-SAAS-T8.12AS.21.102...md` | LU | Close Client PROD owner payload |
| `PH-T8.9A...md` | LU | Audit funnel onboarding |
| `PH-T8.9B...md` | LU | Fondation pre-tenant |
| `PH-T8.9D...md` | LU | Promotion PROD funnel |
| `PH-T8.9F...md` | LU | Audit activation post-checkout |
| `PH-T8.9G...md` | LU | Events activation DEV |
| `PH-T8.9I...md` | LU | Events activation PROD |
| `PH-WEBSITE-T8.11AK...md` | LU | Forwarding owner/UTM/click IDs |
| `PH-WEBSITE-T8.12AQ-PRICING-PAGE-PLAN-AWARE-AUDIT-01.md` | ABSENT | Aucun fichier exact; variantes T8.12AQ trouvees |

## PREFLIGHT READ-ONLY

| Controle | Resultat |
| --- | --- |
| SSH config host | `install-v3` -> `46.62.171.61` |
| Hostname bastion | `install-v3` |
| IP obligatoire | `46.62.171.61` presente |
| IP interdite | `51.159.99.247` non utilisee comme cible |
| Date UTC | `Fri Jun 26 06:05:47 PM UTC 2026` |

| Repo | Branche attendue | Branche observee | HEAD | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `d9631ca087f1751b2def8ad06a049ad93226ffbd` | `M tsconfig.tsbuildinfo` | OK lecture, dirty build artifact compris |
| keybuzz-api | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `962c0c8d62861f5642212935dda485768ca3325d` | `D dist/...` preexistant | OK lecture, dette dist comprise |
| keybuzz-infra | `main` | `main` | `0584bc42d2e53fe84599d405ecc39352dae1811c` | clean avant rapport | OK docs-only |

Runtime read-only:

| Service | Image observee |
| --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.266-no-card-trial-launch-pricing-dev` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` |

## FLOW CLIENT ACTUEL

| Etape actuelle | Fichier/source | API appelee | Tracking | Probleme pour no-card |
| --- | --- | --- | --- | --- |
| Arrivee `/register` | `app/register/page.tsx` | aucune au mount | `emitFunnelStep('register_started')` avec properties owner/UTM/click IDs | A preserver |
| Email submit | `app/register/page.tsx`, `app/api/auth/magic/start/route.ts` | BFF auth magic start | `email_submitted` via BFF/API | OK |
| OTP verify | `app/register/page.tsx`, `app/api/auth/magic/verify/route.ts` | NextAuth / BFF verify | `otp_verified` | OK |
| Company/user | `app/register/page.tsx` | aucune jusqu'au submit final | `company_completed`, `user_completed` | OK |
| Plan select final | `app/register/page.tsx` | promo preview possible | `plan_selected`, `trackSignupStart`, Meta `Lead`, TikTok `SubmitForm` | A revoir: browser Lead existe deja; ne pas ajouter fake conversion no-card |
| Creation tenant | `app/register/page.tsx`, `app/api/auth/create-signup/route.ts` | API `/tenant-context/create-signup` | `trackSignupComplete`, API `tenant_created` | API cree `status='pending_payment'` |
| Checkout initial | `app/register/page.tsx`, `app/api/billing/checkout-session/route.ts` | API `/billing/checkout-session` | `trackBeginCheckout`, `InitiateCheckout` browser | Bloquant no-card: Stripe reste obligatoire |
| Stripe redirect | `window.location.href = stripeData.url` | Stripe hosted checkout | checkout externe | CB demandee a l'activation |
| Success | `app/register/success/page.tsx` | `/api/auth/me`, `/api/tenant-context/entitlement` | `success_viewed`, `trackPurchase` GA4 browser | Page depend de `session_id`; no-card ne doit pas passer par cette page telle quelle |
| Product entry | `/dashboard`, `/start` | API tenant/dashboard | activation events internes | OK si tenant entitlement non lock |

Constat: le Client est email-first mais pas no-card. Le chemin actuel "register -> create-signup -> checkout -> Stripe -> success -> dashboard" est structurellement checkout-first pour l'acces produit.

## PRICING CLIENT ACTUEL

| Surface Client | Prix actuel | Prix cible | Fichier | Risque |
| --- | ---: | ---: | --- | --- |
| Register plan cards | 97 / 297 / 497 | 47 / 97 / 197 | `src/features/pricing/config.ts` via `app/register/page.tsx` | Mauvais prix affiches au signup |
| Pricing page Client | 97 / 297 / 497 | 47 / 97 / 197 | `app/pricing/page.tsx`, `src/features/pricing/*` | Incoherence SaaS |
| Billing plan | 97 / 297 / 497 | 47 / 97 / 197 | `app/billing/plan/page.tsx`, `planCapabilities.ts` | Upsell/upgrade mauvais |
| Plan capability info | 97 / 297 / 497 | 47 / 97 / 197 | `src/features/billing/planCapabilities.ts` | Entitlement UI et billing status incoherents |
| KBActions compare | 0 / 1000 / 2000 | A confirmer avec caps API | `src/features/pricing/config.ts`, `planCapabilities.ts` | Garder caps, ne pas promettre illimite |
| Copy CB/facturation | "Carte demandee a l'activation", Stripe, paiement | No-card au debut, Stripe seulement upgrade/conversion | `app/register/page.tsx`, `LegalModal.tsx`, billing pages | Contradiction promesse no-card |

## API/BFF NECESSAIRES

Questions obligatoires:

1. Existe-t-il deja un endpoint API/BFF permettant de creer un tenant trial sans checkout ?
   Non. Le Client a BFF `create-signup` et `checkout-session`; l'API a `create-signup`, `entitlement`, `checkout-session`, mais pas endpoint runtime dedie no-card.
2. Le contrat `no-card-trial.ts` est-il expose runtime ou uniquement source helper ?
   Uniquement helper/source exporte dans le module billing. Aucun grep n'a trouve de route qui appelle `buildNoCardTrialContract()`.
3. Le Client doit-il appeler un endpoint existant ou faut-il une phase API endpoint ?
   Phase API endpoint requise avant Client.
4. Comment conserver `signup_attribution`, owner/UTM/click IDs et `funnel_id` ?
   Reutiliser le payload `create-signup` existant et/ou un endpoint API idempotent qui consomme `tenantId`, `plan`, `cycle`, `attribution`, `funnel_id`.
5. Comment rediriger apres creation trial ?
   L'API doit retourner un tenant unlocked/trialing et un next path cible (`/dashboard` ou `/start`). Le Client ne doit pas reutiliser `/register/success?session_id=...` sans session Stripe.
6. Comment gerer expiration/upgrade sans Stripe au debut ?
   API doit poser un statut trial interne, une date de fin, un lock apres J+14 et garder Stripe checkout pour conversion/upgrade.

| Besoin Client | Endpoint/BFF existant | Suffisant | Gap |
| --- | --- | --- | --- |
| Creer tenant + user + attribution | BFF `/api/auth/create-signup` -> API `/tenant-context/create-signup` | Partiel | Cree `pending_payment`, pas trial active no-card |
| Activer trial no-card | Aucun endpoint dedie | Non | Endpoint runtime API manquant |
| Lire entitlement trial | BFF/API `/tenant-context/entitlement` | Partiel | Verrouille `pending_payment`; doit reconnaitre no-card active |
| Preserver funnel | BFF `/api/funnel/event` | Oui pour events existants | Ajouter event no-card seulement si interne et decide |
| Checkout conversion | BFF `/api/billing/checkout-session` | Oui | Doit rester upgrade/conversion, pas trial initial |
| Pricing 2026 | API `pricing.ts` runtime | Oui cote API | Client source pas alignee |

Conclusion: `API_ENDPOINT_REQUIRED_BEFORE_CLIENT`.

## FLOW CIBLE CLIENT

| Etape cible | UI | API/BFF | Tracking | Gate |
| --- | --- | --- | --- | --- |
| 1. Arrivee `/register` | Email-first avec params owner/UTM/click IDs | aucune | `trial_page_viewed` et `register_started` preserves | aucun |
| 2. Email/OTP/OAuth | steps actuels | auth BFF actuels | `email_submitted`, `otp_verified`, `oauth_started` | aucun |
| 3. Company/user | steps actuels | aucun jusqu'au submit | `company_completed`, `user_completed` | CGU |
| 4. Plan | prix 47/97/197, copy lancement 2026 | promo preview si conserve | `plan_selected` interne | pas de CB |
| 5. Creation trial | CTA "Demarrer l'essai sans carte" | Nouveau endpoint API/BFF no-card | `trial_started_no_card` product/lifecycle interne si GO | KBActions/caps |
| 6. Redirection | `/dashboard` ou `/start` | entitlement unlocked | `dashboard_first_viewed`/`onboarding_started` existants | tenant/currentTenantId OK |
| 7. Upgrade/conversion | CTA billing/locked/upgrade | `/api/billing/checkout-session` | checkout/Stripe uniquement ici | Stripe |
| 8. Expiration | locked page ou billing plan | entitlement API | aucun fake event | lock `TRIAL_EXPIRED` |

## DESIGN PHASE API OBLIGATOIRE AVANT CLIENT

| Fichier futur | Changement futur | Test futur | Risque |
| --- | --- | --- | --- |
| `keybuzz-api/src/modules/auth/tenant-context-routes.ts` ou module billing trial | Ajouter endpoint idempotent no-card trial runtime | unit/offline + API mock | Multi-tenant/entitlement |
| `keybuzz-api/src/services/entitlement.service.ts` | Reconnaitre trial no-card active/expired sans subscription Stripe | tests lock/unlock J0/J14 | Tenant verrouille a tort |
| `keybuzz-api/src/modules/billing/no-card-trial.ts` | Reutiliser helper existant pour response contract | tests contrat | Divergence helper/runtime |
| `keybuzz-api/src/modules/funnel/routes.ts` ou lifecycle interne | Ajouter `trial_started_no_card` si event interne decide | grep outbound/conversion 0 | Pollution Ads si mal branche |
| `keybuzz-api/src/config/kbactions.ts` / wallet logic | Cap KBActions trial selon plan | tests cap/exhausted | Cout IA illimite |
| `keybuzz-client/app/api/...` futur | BFF proxy vers endpoint no-card | mock BFF | Auth/cookie tenant |

Endpoint propose:

```text
POST /tenant-context/no-card-trial
Body: { tenantId, plan, cycle, attribution?, funnel_id? }
Response: {
  success: true,
  tenantId,
  plan,
  selectedPlan,
  effectivePlan,
  billingStatus: "trialing",
  trialStartedAt,
  trialEndsAt,
  daysLeftTrial,
  requiresCardAtStart: false,
  stripeRequiredAtStart: false,
  nextPath: "/dashboard"
}
```

Principes:

- idempotent par tenant;
- refuse cross-tenant;
- conserve `signup_attribution` deja posee par create-signup;
- met fin au statut `pending_payment` pour le trial actif ou introduit un statut no-card clair que l'entitlement sait lire;
- ne cree aucun customer Stripe, aucune session Stripe, aucun billing event fake;
- n'alimente pas `conversion_events`;
- event `trial_started_no_card` uniquement product/lifecycle interne si necessaire.

## DESIGN PATCH CLIENT DEV APRES API

| Fichier futur | Changement futur | Test futur | Risque |
| --- | --- | --- | --- |
| `app/register/page.tsx` | Remplacer `handleConfirmPlanAndCheckout` par create trial no-card, sans Stripe initial | test aucun fetch checkout dans flow trial | P0 flow |
| `app/register/page.tsx` | Copy "sans carte", "prix lancement 2026", "KBActions sous garde-fous" | snapshot/static grep | Copy trompeuse |
| `src/features/pricing/config.ts` | 47/97/197 | unit/static grep | Divergence Website/API |
| `src/features/billing/planCapabilities.ts` | 47/97/197 | unit/static grep | Billing UI |
| `app/register/success/page.tsx` | Garder Stripe success seulement conversion; ne pas reutiliser pour no-card | route test | Redirect casse |
| `app/locked/page.tsx` | CTA checkout conserve apres expiration/pending conversion | mock entitlement | Blocage post-trial |
| `src/lib/tracking.ts` | Ne pas appeler `trackBeginCheckout` ni `StartTrial` pour no-card | grep/test spies | Fake conversions |

## BUILD SAFETY FUTURE CLIENT

| Controle futur | Attendu | Raison |
| --- | --- | --- |
| Build args DEV explicites | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` | Incident 2026-05-10 |
| Bundle DEV API DEV | present | Client DEV doit parler API DEV |
| Bundle DEV API PROD | absent | Eviter Inbox DEV vide / prod inline |
| Repo clean avant build | 0 dirty source, dirty compris sinon STOP | Build-from-git |
| Commit + push avant build | oui | Source prouvee |
| Pricing 47/97/197 | present dans surfaces modifiees | Lancement 2026 |
| Ancien pricing 297/497 | absent des surfaces modifiees | Coherence commerciale |
| Checkout initial | absent du flow trial no-card | Promesse sans CB |
| Checkout upgrade | conserve | Conversion payante |
| register_started owner payload | present | Attribution Antoine/owner |
| Fake events | 0 | No fake metrics |

## AI FEATURE PARITY / ANTI-REGRESSION

| Surface | Verification design | Risque | Gate future |
| --- | --- | --- | --- |
| tenant/currentTenantId | Redirection doit poser cookie/current tenant comme aujourd'hui | SaaS inaccessible | test `/dashboard` auth |
| Dashboard | `dashboard_first_viewed` preserve | activation invisible | no fake event |
| Inbox | Bundle API DEV strict | Inbox DEV casse si API PROD inline | audit bundle |
| IA assist | Entitlement trial doit ouvrir features selon plan/cap | lock ou cout illimite | KBActions cap |
| KBActions | Trial sous garde-fous | promesse "illimite" fausse | copy + tests |
| Autopilot gates | Ne pas activer globalement hors plan/cap | Auto-run non controle | planGuard |
| Messages/connecteurs | No-card ne doit pas modifier channels/inbox | activation casse | smoke routes |

## NO FAKE METRICS / NO FAKE EVENTS

Confirme pour cette phase:

- aucun POST `/funnel/event`;
- aucun `StartTrial` cree;
- aucun `Purchase` cree;
- aucun `CompletePayment` cree;
- aucun `trial_page_viewed` cree;
- aucun `register_started` cree;
- aucun CAPI/GA4/TikTok/LinkedIn call;
- aucun Stripe call;
- aucun checkout;
- aucun KPI invente.

Events a preserver:

| Event | Statut |
| --- | --- |
| `trial_page_viewed` | arrival `/register`, preserve |
| `register_started` | premier event client, preserve owner/UTM/click IDs |
| `plan_selected`, `email_submitted`, `otp_verified`, `tenant_created` | micro-steps internes, preserve |
| `trial_started_no_card` | propose product/lifecycle interne, pas outbound par defaut |
| `StartTrial`, `Purchase`, `CompletePayment` | interdits sans decision explicite |

## NON-REGRESSION READ-ONLY

| Verification | Resultat |
| --- | --- |
| Patch source Client/API/Website/Admin/Backend | 0 |
| Build | 0 |
| Docker push | 0 |
| Deploy / rollout / restart | 0 |
| `kubectl apply` | 0 |
| `kubectl set image/env`, `patch`, `edit` | 0 |
| DB write | 0 |
| Stripe live call | 0 |
| Checkout | 0 |
| Fake event / CAPI replay | 0 |
| Webflow | 0 |
| Linear | 0 |
| PROD mutation | 0 |
| Fichier infra modifie | uniquement ce rapport docs-only |

## DETTES

| Dette | Severite | Suite |
| --- | --- | --- |
| Endpoint runtime no-card trial absent | P0 | PH-21.132A API |
| Client checkout obligatoire | P0 | Client patch apres PH-21.132A |
| Pricing Client ancien 97/297/497 | P0 | Client patch apres API |
| Copy CB/Stripe dans register | P0 | Client patch apres API |
| `trackSignupStart` browser Meta Lead existant sur plan select | P1 tracking | Ne pas amplifier; decision tracking separee si besoin |
| Website T8.12AQ audit exact absent | P2 docs | Documente absent |
| Dirty Client `tsconfig.tsbuildinfo` | Process | Ne pas toucher hors scope |
| Dirty API `dist/` supprime | Process | Cleanup dedie si necessaire |
| Stripe Price IDs 2026 | P0 avant PROD paiement | Phase OPS/config separee |
| Admin statut trial no-card | P1 ops | Phase Admin apres API/Client |

## PROCHAIN GO

```text
GO SOURCE PATCH API NO-CARD TRIAL RUNTIME ENDPOINT DEV PH-SAAS-T8.12AS.21.132A
```

STOP
