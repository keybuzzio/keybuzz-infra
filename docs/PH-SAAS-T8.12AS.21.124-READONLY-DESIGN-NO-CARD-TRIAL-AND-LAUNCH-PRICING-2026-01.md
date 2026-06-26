# PH-SAAS-T8.12AS.21.124 - READONLY DESIGN NO-CARD TRIAL AND LAUNCH PRICING 2026

Date UTC: 2026-06-26
Mode: READONLY DESIGN
Verdict: READY_SOURCE_PATCH_API_DEV

## 1. Resume executif

PH-21.124 a audite en lecture seule le passage KeyBuzz vers:

- inscription email-first;
- acces KeyBuzz 14 jours sans carte bancaire;
- paiement/CB seulement a la continuation ou conversion;
- prix de lancement 2026: STARTER 47 EUR/mois, PRO 97 EUR/mois, AUTOPILOT 197 EUR/mois;
- controle KBActions pendant le trial;
- preservation de l'attribution owner/UTM/click IDs et de la chaine Meta CAPI `trial_page_viewed` cloturee en PH-21.123.

Decision recommandee: mettre en place un entitlement trial interne KeyBuzz avant Stripe.
Stripe doit rester le systeme de paiement a la conversion, pas le prerequis d'acces au produit.
Le modele Stripe trial sans payment method n'est pas recommande comme fondation P0 car il conserve une dependance billing/checkout dans le tunnel et complique la promesse "sans carte bancaire".

Le patch suivant peut commencer par l'API DEV: contrat trial no-card, source de verite pricing 2026, event interne dedie, gates billing/trial, KBActions capped trial, tests offline.

Prochain GO recommande:

`GO SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.125`

## 2. Scope et interdits respectes

Actions faites:

- lecture sources et docs;
- lecture runtime Kubernetes;
- lecture schema DB metadata-only;
- lecture source Git;
- creation du present rapport docs-only;
- aucun patch applicatif.

Interdits respectes:

- aucun build;
- aucun docker push;
- aucun deploy;
- aucun `kubectl apply`;
- aucun `kubectl set image/env`, patch, edit ou restart;
- aucun changement Stripe;
- aucune creation checkout;
- aucune mutation DB;
- aucun POST `/funnel/event`;
- aucun fake event;
- aucun formulaire `/register`;
- aucun secret/token/PII affiche;
- aucune modification Webflow;
- aucune modification Linear.

## 3. Sources relues

Sources process lues ou verifiees:

- `AI_MEMORY/CURRENT_STATE.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/DOCUMENT_MAP.md`
- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md`
- `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md`
- `AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md`
- modele prompt `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`

Sources PH recentes verifiees par presence/lecture ciblee:

- PH-21.119, PH-21.121, PH-21.122, PH-21.123 tracking Meta CAPI `trial_page_viewed`
- PH-21.70, PH-21.77 Website PROD
- PH-21.83 a PH-21.84 API DEV `trial_page_viewed`
- PH-21.96 a PH-21.97 API PROD `trial_page_viewed`
- PH-21.101 a PH-21.102 Client PROD `register_started`

Sources historiques pertinentes retrouvees:

- trial / onboarding: PH-SAAS-T8.12C.1, H, I, K, L, L.1, L.2, L.3, M, M.1
- activation: PH-T8.9A, F, G, I, L
- billing/plans: PH129, PH130, PH138, PH145.9, PH146.4, PH146.5
- lifecycle/KBActions: PH-SAAS-T8.12Y.5, Y.8, Y.9A, Z.1
- Website/pricing: PH-WEBSITE-T8.12AQ.* et PH-WEBSITE-T8.11AK

Certains noms exacts historiques demandes par le prompt n'existent plus sous le nom exact, mais les rapports voisins et les sources actuelles ont ete utilises comme verite exploitable.

## 4. Preflight bastion et repos

Bastion:

| Controle | Resultat |
| --- | --- |
| Hostname | `install-v3` |
| IP obligatoire | `46.62.171.61` presente |
| IP interdite | `51.159.99.247` non observee comme cible active |
| Date UTC lue | 2026-06-26 |

Repos:

| Repo | Branche | HEAD | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 0/0 | dist-only preexistant, non-dist 0 | OK lecture |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | 0/0 | 1 dette preexistante | OK lecture |
| keybuzz-admin-v2 | main | 3707c83 | 0/0 | 0 | OK |
| keybuzz-website | main | bd32fc8 | 0/0 | 0 | OK |
| keybuzz-infra | main | e920335 avant rapport | 0/0 | 0 avant rapport | OK docs-only |
| keybuzz-backend | main | c38583a | n/a | 1 dette preexistante | OK lecture |

## 5. Runtime baseline DEV/PROD

| Service | Env | Image | Digest | Ready | Restarts | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| API | PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` | 1/1 | 0 | PH-21.123 OK |
| API | DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | 1/1 | 0 | DEV OK |
| Client | PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` | `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | 1/1 | 0 | PH-21.102 OK |
| Client | DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev` | `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9` | 1/1 | 0 | DEV OK |
| Website | PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod` | `sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4` | 2/2 | 0 | PH-21.77 OK |
| Website | DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | 1/1 | 0 | DEV preview OK |
| Admin | PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod` | `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` | 1/1 | 0 | OK |
| Admin | DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev` | `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` | 1/1 | 0 | OK |
| Backend | PROD | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod` | `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | 1/1 | 0 | OK |
| Backend | DEV | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev` | `sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806` | 1/1 | 0 | OK |

## 6. Cartographie onboarding actuel

| Etape | Surface | Repo/fichier | Etat actuel | Friction | Impact cible |
| --- | --- | --- | --- | --- | --- |
| 1 | Website homepage | `keybuzz-website/src/app/page.tsx` | CTA vers pricing, mentions essai 14 jours | Pas encore "sans CB" explicite partout | Mettre wording no-card |
| 2 | Website pricing | `keybuzz-website/src/app/pricing/page.tsx` | CTA vers `client.keybuzz.io/register?plan=...&cycle=monthly` | Prix actuels 97/297/497 | Prix 47/97/197 + no-card |
| 3 | Attribution | Website `MarketingCTA`, Client attribution libs | Forward owner/UTM/click IDs preserve | Risque de perte si CTA reecrit mal | Conserver contrat Antoine/Webflow |
| 4 | Register Client | `keybuzz-client/app/register/page.tsx` | Step order email/code/company/user/plan/checkout | Email-first existe, mais checkout reste dans le parcours | Remplacer checkout obligatoire par activation trial interne |
| 5 | Tracking arrivee | API/Client funnel | `trial_page_viewed` et `register_started` existent | Ne pas polluer StartTrial | Ajouter event dedie no-card |
| 6 | Checkout | Client BFF + API `/billing/checkout-session` | Cree session Stripe, API applique `trial_period_days: 14` | CB/Stripe toujours dans le tunnel | Checkout seulement apres trial ou upgrade |
| 7 | Tenant / plan | API tenant/billing | effective plan vient subscription active/trialing ou fallback STARTER | Pas d'entitlement no-card explicite | Stocker trial interne et effective plan |
| 8 | Gates billing | Client/API planGuard/tenantGuard | gates par plan/subscription | Risque de blocage avant fin trial | Gates doivent accepter trial actif |
| 9 | KBActions | API ledger/wallet + Client display | credits par plan payant, wallet | Trial full product peut couter si illimite | Cap trial + throttle |
| 10 | Lifecycle emails | docs/sources lifecycle | bases de cron/email existent historiquement | Wording prix/trial obsolete | Revoir apres API/Client |

Conclusion onboarding: le parcours est deja partiellement email-first, mais la friction P0 vient du basculement vers Stripe checkout avant l'acces effectif. La correction doit separer "creation/acces trial" de "paiement".

## 7. Cartographie pricing actuel

| Surface | Prix actuel | Source | Fichier/route/env | Doit changer ? | Risque |
| --- | --- | --- | --- | --- | --- |
| API plan constants | 97/297/497 monthly, 78/238/398 annual equivalent | Source | `keybuzz-api/src/modules/billing/pricing.ts` | Oui | Source pricing backend obsolete |
| API Stripe price refs | env `STRIPE_PRICE_*` | Source/config | `pricing.ts`, manifests/secrets refs | Oui, apres creation Price IDs | Reutiliser mauvais price IDs |
| Website pricing | 97/297/497 monthly | Source | `keybuzz-website/src/app/pricing/page.tsx` | Oui | Copy publique incoherente |
| Website FAQ | "facturation mensuelle demarre" apres 14j | Source | `pricing/page.tsx` | Oui | Contredit no-card |
| Website homepage | "Des 97 EUR/mois" | Source | `keybuzz-website/src/app/page.tsx` | Oui | Ancien prix visible |
| Client pricing | 97/297/497 et annualDiscount 20 | Source | `keybuzz-client/src/features/pricing/config.ts` | Oui | Register affiche mauvais prix |
| Client compare | KBActions 0/1000/2000 | Source | `pricing/config.ts` | Oui partiel | Mismatch Website Autopilot |
| Client capabilities | STARTER/PRO/AUTOPILOT plan caps | Source | `planCapabilities.ts` | Oui pour trial policy | Trial pourrait heriter mauvais droits |
| Admin Stripe products | test product IDs + PRO annual 285600 cents | Source | `keybuzz-admin-v2/src/config/stripe-products.ts` | Oui | Admin/promo obsolete |
| Docs/policies | Pricing historique | Docs | Website docs et rapports | Oui docs futures | Confusion support |

Prix cibles recommandes:

| Plan | Prix mensuel cible | Wording |
| --- | ---: | --- |
| STARTER | 47 EUR/mois | Prix de lancement 2026 |
| PRO | 97 EUR/mois | Prix de lancement 2026 |
| AUTOPILOT | 197 EUR/mois | Prix de lancement 2026 |

Wording public recommande:

- "Essai gratuit 14 jours, sans carte bancaire."
- "Prix de lancement 2026, garantis tant que votre abonnement reste actif."
- "KBActions incluses selon votre plan."

Ne pas afficher de prix barre ou fausse urgence si les prix de reference ne sont pas juridiquement et commercialement defensables.

## 8. Cartographie Stripe / billing

| Brique | Etat actuel | Source | Impact no-card trial | Decision requise |
| --- | --- | --- | --- | --- |
| Plan price IDs | `STRIPE_PRICE_STARTER/PRO/AUTOPILOT_MONTHLY/ANNUAL` | API env refs | Nouveaux Price IDs requis avant paiement aux nouveaux prix | Phase OPS Stripe separee |
| Checkout plan | POST `/billing/checkout-session` | API routes | Ne doit plus etre prerequis pour trial | Garder pour conversion |
| Trial Stripe | `trial_period_days: 14` dans checkout | API routes | Pas compatible avec promesse sans CB si checkout reste obligatoire | Ne plus utiliser comme source trial no-card |
| Billing current | active/trialing subscription puis fallback STARTER | API routes | Doit integrer trial entitlement interne | Patch API |
| Webhooks | `checkout.session.completed`, `trial_will_end`, subscription events | API routes | Restent payment/subscription | Ne pas reutiliser pour no-card event |
| Addons/KBActions checkout | AI actions checkout, Agent KeyBuzz checkout | API routes | Hors tunnel initial | Preserver |
| Promo codes | checkout/promo-preview | API routes | Prix lancement ne doit pas etre un faux coupon | Decider creation Price IDs plutot que promo |

Options:

| Option | Description | Avantages | Risques | Recommandation |
| --- | --- | --- | --- | --- |
| A | Trial interne KeyBuzz 14 jours, Stripe a conversion | Friction minimale, controle gates/KBActions, semantique claire | Demande schema/API/gates solides | Retenue |
| B | Stripe trial sans payment method | Reste pres du billing | Reste checkout-centric, plus fragile UX | Non retenue P0 |
| C | Garder checkout actuel | Peu de code | Ne resout pas le probleme business | Rejete |

## 9. Cartographie KBActions / couts trial

| Plan | KBActions actuel | Trial propose | Risque cout | Guard recommande |
| --- | ---: | ---: | --- | --- |
| STARTER | 0/mois | 100 trial ou feature IA limitee | Faible | wallet trial separe + throttle |
| PRO | 1000/mois | 300 trial | Moyen | hard cap + message upgrade |
| AUTOPILOT_ASSISTED | 1000/mois | 300 a 500 trial | Moyen/eleve | assisted only, pas auto-run illimite |
| AUTOPILOT | 2000/mois Client, 3500/mois Website | 500 trial max recommande | Eleve | cap strict + debounce + logs |
| ENTERPRISE | 10000/mois | sur validation | Eleve | pas d'acces no-card automatique enterprise |

Gaps constates:

- Client compare: AUTOPILOT = 2000 KBActions/mois.
- Website pricing: AUTOPILOT = 3500 KBActions/mois.
- Cette incoherence doit etre corrigee dans les phases pricing.

Politique recommandee:

- full product features visibles pendant 14 jours;
- usage IA controle par wallet/cap trial;
- pas d'exposition cout LLM brut;
- blocage propre a epuisement: "Votre quota d'essai est atteint. Passez a un plan ou contactez l'equipe."
- pas d'execution autonome risquee si le trial n'a pas assez de garde-fous.

## 10. Cartographie tracking / events

| Event | Semantique actuelle | Semantique cible | Outbound ? | Risque historique |
| --- | --- | --- | --- | --- |
| `trial_page_viewed` | arrivee `/register`, CAPI OK en PH-21.123 | Inchange | Oui, deja prouve | Ne pas modifier |
| `register_started` | ouverture register avec owner/UTM/click IDs | Inchange | Peut rester acquisition | Ne pas perdre payload |
| `signup_complete` | inscription/onboarding selon historique | A verifier avant reuse | Potentiel | Risque confusion |
| `checkout_started` | debut checkout Stripe | Reste paiement | Oui selon existant | Ne pas emettre pour trial no-card |
| `StartTrial` | lie au trial/subscription Stripe/historique | Ne pas redefinir sans GO | Oui Meta/Google possible | Pollution attribution si reutilise |
| `Purchase` | paiement reel | Inchange | Oui | Ne jamais faker |
| `CompletePayment` | paiement reel | Inchange | Oui | Ne jamais faker |
| Nouveau `trial_started_no_card` | absent | Creation trial interne sans CB | Mapping a decider separement | Ne pas l'assimiler a Purchase |

Decision recommandee:

- garder `trial_page_viewed` et `register_started`;
- ajouter `trial_started_no_card` cote interne;
- ne pas redefinir `StartTrial` dans le patch initial;
- decider plus tard le mapping outbound Ads: custom event Meta, Lead, CompleteRegistration ou StartTrial seulement si Ludovic/marketing valide explicitement.

## 11. Cartographie Website / copy / CTA

| Page/section | Copy actuel | Copy cible | Tracking/CTA a preserver | Risque |
| --- | --- | --- | --- | --- |
| Homepage hero/body | "14 jours gratuits", "Des 97 EUR/mois" | "14 jours gratuits, sans carte bancaire", "Des 47 EUR/mois" | CTA IDs existants | Mauvais prix visible |
| Pricing cards | 97/297/497, CTA register plan/cycle | 47/97/197 lancement 2026 | UTM suffix + CTA tracking | Perte attribution |
| Pricing FAQ | "facturation mensuelle demarre" | "Aucune facturation sans choix d'abonnement" | Aucun fake event | Contradiction no-card |
| Final CTA pricing | "Commencer essai Autopilot" | "Essayer sans carte bancaire" | `pricing_final_*` | Conversion drop si ambigu |
| Policies/pricing docs | ancien pricing | aligner lancement 2026 | n/a | Support incoherent |

Regle: ne pas changer Webflow/try.keybuzz.io dans une phase applicative sans audit dedie. Les CTA Website doivent continuer de forwarder owner/UTM/click IDs vers Client.

## 12. Cartographie Client SaaS / onboarding UI

| Route/UI | Etat actuel | Changement cible | Build args risk | Test requis |
| --- | --- | --- | --- | --- |
| `/register` | step email par defaut, mais step plan/checkout ensuite | creer trial apres email/OTP/company/user, sans checkout obligatoire | Eleve | bundle DEV/PROD API URL |
| Plan selection | utilise `PRICING_CONFIG` | prix 47/97/197 + lancement 2026 | Moyen | snapshots/copy |
| Checkout step | `fetch('/api/billing/checkout-session')` | seulement conversion volontaire | Moyen | test aucun appel checkout pour trial |
| Payment cancelled | gere retour checkout annule | secondaire apres conversion | Faible | non regression |
| Trial banners | existants | wording no-card/cap KBActions | Moyen | UX tests |
| Billing entitlement | `useEntitlement`, plan capabilities | accepter trial actif | Eleve | unit/integration |
| AI actions | BFF AI routes | respecter cap KBActions trial | Eleve | mock API |
| Attribution | `buildRegisterStartedAttributionProperties` | conserver owner/UTM/click IDs | P0 | payload tests |
| Build args | incident 2026-05-10 | DEV contient api-dev, PROD contient api | P0 | audit bundle obligatoire |

Rappel incident Client 2026-05-10:

- Client DEV v3.5.177/v3.5.178 avaient ete builtees sans build args explicites.
- Le bundle DEV pointait vers API PROD.
- Toute phase Client doit bloquer si:
  - DEV ne contient pas `https://api-dev.keybuzz.io`;
  - DEV contient `https://api.keybuzz.io`;
  - PROD ne contient pas `https://api.keybuzz.io`;
  - PROD contient `https://api-dev.keybuzz.io`.

## 13. Cartographie API / DB / migrations

Schema DB lu en metadata-only:

| Table | Etat | Colonnes pertinentes |
| --- | --- | --- |
| `tenants` | existe, 23 rows | `plan`, `status`, `selected_plan`, `trial_entitlement_plan`, `marketing_owner_tenant_id` |
| `billing_subscriptions` | existe, 8 rows | `plan`, `billing_cycle`, `status`, `current_period_*`, `stripe_subscription_id` |
| `billing_events` | existe, 197 rows | events billing |
| `ai_actions_ledger` | existe, 431 rows | `delta`, `kb_actions`, `cost_usd`, `decision_context` |
| `ai_usage` | existe, 384 rows | usage IA |
| `funnel_events` | existe, 325 rows | tracking interne |
| `conversion_events` | existe, 3 rows | conversions |
| `outbound_conversion_destinations` | existe, 15 rows | destinations |
| `outbound_conversion_delivery_logs` | existe, 27 rows | delivery logs |
| `trial_entitlements` | absente | besoin possible |
| `trial_lifecycle_emails` | absente | besoin possible |
| `trial_lifecycle_email_events` | absente | besoin possible |

API routes/surfaces:

| Table/route | Etat actuel | Besoin cible | Migration ? | Risque |
| --- | --- | --- | --- | --- |
| `pricing.ts` | prices 97/297/497, env Stripe refs | constants 47/97/197 + launch metadata | Non ou config only | incoherence public/API |
| `/billing/current` | subscription active/trialing ou fallback | inclure trial no-card actif/expire | Oui si schema | gates fausses |
| `/billing/checkout-session` | Stripe trial 14j | conversion seulement | Non initial | friction si laisse obligatoire |
| tenants | `trial_entitlement_plan` existe | ajouter start/end/status/cap si absent | Oui probable | schema incomplet |
| planGuard/tenantGuard | plan/subscription gates | accepter trial actif | Non ou code only | lockout trial |
| KBActions services | ledger/wallet | wallet/cap trial | Oui probable | cout illimite |
| funnel/outbound | events existants | event no-card dedie | Non ou enum/tests | pollution StartTrial |
| lifecycle emails | bases historiques | J0/J7/J13/J14 no-card | Plus tard | mauvais wording |

Questions tranchees pour le patch API DEV:

- Stocker le trial no-card cote KeyBuzz, pas Stripe.
- Effective plan pendant trial: plan choisi ou plan par defaut `AUTOPILOT_ASSISTED` selon decision produit, mais avec KBActions cap.
- A J+14: passer en `trial_expired`/checkout required sans supprimer tenant.
- Upgrade avant J+14: creer checkout Stripe puis subscription active.
- KBActions epuisees: bloquer/throttle IA, pas l'acces lecture au produit.

## 14. Cartographie Admin / support ops

| Admin surface | Etat actuel | Besoin cible | Priorite | Risque |
| --- | --- | --- | --- | --- |
| Billing page | plan/status/subscription/wallet | afficher trial no-card status/end/cap | P1 apres API/Client | support aveugle |
| Tenant detail | tenant plan/status | trial fields visibles | P1 | confusion support |
| Stripe products config | TEST IDs + PRO annual amount old | update apres Stripe price OPS | P1 | promos/links obsoletes |
| Metrics/funnel | depend events actuels | inclure no-card trial event | P1/P2 | KPI faux |
| Controls ops | pas de controle trial dedie observe | extend/expire/convert si besoin | P2 | operations manuelles |

Admin ne bloque pas le premier patch API DEV, mais doit etre planifie avant PROD si support/client success doit suivre les trials.

## 15. Decisions recommandees

| Decision | Options | Recommandation | Bloquant patch ? |
| --- | --- | --- | --- |
| Trial sans CB implementation | internal vs Stripe trial | Internal KeyBuzz entitlement first | Non, prochaine phase API peut commencer |
| Event no-card trial | custom vs StartTrial | `trial_started_no_card` interne, mapping outbound separe | Non |
| Prix | lancement 2026 vs permanent | Prix de lancement 2026 garantis tant que l'abonnement reste actif | Non |
| KBActions trial cap | unlimited vs capped | Capped trial, valeurs par defaut prudentes | Non si cap provisoire valide |
| Stripe Price IDs | reuse vs create new | Creer nouveaux Price IDs DEV/PROD en phase OPS separee | Oui avant paiement PROD, pas avant API foundation |
| Annual pricing | garder 20% vs monthly-only | garder mensuel d'abord, annual a recalculer avec 20% apres validation Stripe | Non pour API foundation |
| Plan trial default | selected plan vs Autopilot assisted | selected plan si choisi, sinon Autopilot assisted controle | A valider avant Client UX |

## 16. Todo / phases recommandees

| Ordre | Phase | Repo/service | Type | Gate | Rollback |
| ---: | --- | --- | --- | --- | --- |
| 1 | PH-21.124 | Infra docs | READONLY DESIGN | rapport docs-only | n/a |
| 2 | PH-21.125 | API DEV | SOURCE PATCH | tests offline, no DB mutation runtime | revert commit avant build |
| 3 | PH-21.125 PUSH | API/Infra docs | PUSH SOURCE | HEAD=origin, dirty maitrise | n/a |
| 4 | PH-21.126 | API DEV | BUILD ONLY | build-from-git, image audit | no push |
| 5 | PH-21.127 | API DEV | PUSH IMAGE | pull-back digest | no deploy |
| 6 | PH-21.128 | API DEV | APPLY GITOPS | commit+push manifest, `kubectl apply -f` | GitOps rollback only |
| 7 | PH-21.129 | API DEV | READONLY VERIFY | runtime, logs, no fake event | n/a |
| 8 | PH-21.130 | API DEV | READONLY CLOSE | close API foundation | n/a |
| 9 | PH-21.131 | Client DEV | SOURCE PATCH | no checkout for trial, attribution preserved | revert source before build |
| 10 | PH-21.132-135 | Client DEV | build/push/apply/verify | bundle API URL audit mandatory | GitOps rollback |
| 11 | PH-21.136 | Website DEV | SOURCE PATCH | copy/pricing/CTA tracking | revert source before build |
| 12 | PH-21.137-140 | Website DEV | build/push/apply/verify | visual + passive tracking | GitOps rollback |
| 13 | PH-21.141 | Admin DEV | SOURCE PATCH if needed | trial support view | revert source before build |
| 14 | PH-21.142 | Stripe/config DEV | OPS/DESIGN/APPLY separate | no secret print, no checkout | config rollback |
| 15 | PH-21.143 | DEV E2E | real no-card test | no fake conversion, controlled data | n/a |
| 16 | PH-21.144+ | PROD promotion | API then Client then Website/Admin | DEV closure required | GitOps rollback only |

Exact next GO:

`GO SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.125`

## 17. Risques et gates

Risques P0:

| Risque | Impact | Gate obligatoire |
| --- | --- | --- |
| Checkout reste obligatoire | La promesse sans CB est fausse | test aucun appel checkout dans trial |
| StartTrial redefini sans decision | Historique Ads/Meta pollue | event dedie `trial_started_no_card` |
| KBActions trial illimitees | cout IA non controle | cap dur + throttle |
| Stripe Price IDs obsoletes | mauvais prix facture | phase OPS Stripe dediee |
| Client build args DEV/PROD | fuite API PROD dans DEV ou inverse | audit bundle obligatoire |
| Website/Client pricing divergent | perte confiance | source de verite pricing partagee |
| Attribution owner/UTM perdue | Antoine/Meta CAPI casse | tests payload |
| Admin non prepare | support aveugle | phase Admin avant PROD |
| DB trial fields incomplets | gates incoherents | migration source + tests |

AI feature parity / anti-regression:

| Surface | Risque | Gate |
| --- | --- | --- |
| AI Assist | trial bloque ou illimite | entitlement + cap KBActions |
| Autopilot | actions auto hors controle | assisted mode ou cap strict pendant trial |
| Provider credit watcher | regression API v3.5.265 | markers/runtime non touches |
| KBActions | cout brut expose | UI/API sans cout LLM client |
| Inbox | mauvais build Client | bundle URL audit |
| Connecteurs | onboarding simplifie casse returnTo | tests route activation |
| Lifecycle emails | mauvais wording/prix | phase email dediee |

No fake metrics / no fake events:

- `trial_page_viewed` reste event arrivee.
- `register_started` reste event ouverture/engagement register.
- `trial_started_no_card` doit etre ajoute mais pas fake.
- `StartTrial`, `Purchase`, `CompletePayment` restent reserves aux semantics decidees et aux paiements reels.

## 18. Prochain GO exact

```text
GO SOURCE PATCH API NO-CARD TRIAL ENTITLEMENT AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.125
```

Scope recommande pour PH-21.125:

- API source patch DEV uniquement;
- aucun push initial;
- aucun build;
- aucun deploy;
- aucune DB mutation runtime;
- aucun Stripe write;
- aucun checkout;
- aucun fake event;
- ajouter/normaliser contrat pricing 2026;
- ajouter trial entitlement no-card interne;
- ajouter event interne `trial_started_no_card`;
- integrer gates billing/trial;
- integrer KBActions capped trial;
- tests offline/mock;
- rapport docs local.

Verdict final:

`GO READONLY DESIGN NO-CARD TRIAL AND LAUNCH PRICING 2026 READY_SOURCE_PATCH_API_DEV PH-SAAS-T8.12AS.21.124`
