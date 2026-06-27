# PH-SAAS-T8.12AS.21.170 - Readonly verify no-card trial billing conversion real user path PROD

## Resume Ludovic

Verdict: NO_GO_DEBTS_FOUND.

Compte verifie: `ludovic+test-prod-20260627@ecomlg.fr` masque dans les sorties publiques. Verification effectuee en lecture seule sur PROD via pod API et DB `keybuzz_prod` en transaction `BEGIN READ ONLY`.

Le parcours commercial principal fonctionne:

- utilisateur trouve;
- tenant cree;
- trial sans CB cree;
- acces SaaS observe;
- Checkout Stripe cree puis complete;
- subscription Stripe PROD en `trialing`;
- plan Autopilot mensuel a 197 EUR/mois confirme par webhook Stripe;
- `billing/current` expose `status=trialing`, `source=db`, `hasStripeSubscription=true`, `requiresCheckout=false`;
- KBActions Autopilot initialisees a 2000.

Mais la phase ne peut pas etre cloturee en zero dette car deux dettes reelles ont ete observees:

1. `billing_events.tenant_id` reste `NULL` pour les webhooks Stripe alors que `tenant_id` est present dans le payload metadata. Impact: observabilite et requetes tenant-scoped billing incompletes.
2. Route Octopia status incoherente: le Client/BFF appelle `/marketplaces/octopia/status`, l'API expose effectivement `/octopia/marketplaces/octopia/status`. Impact: 404 observe sur les appels dashboard/onboarding Octopia.

## Preflight

| Point | Resultat |
| --- | --- |
| Bastion | `install-v3` |
| IP | `46.62.171.61` |
| DB | `keybuzz_prod` |
| Transaction | `READ ONLY = on` |
| Secret / token affiche | 0 |
| Fake event / POST CE / checkout CE | 0 |

## Runtime PROD

| Service | Image | Digest | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` | `sha256:2e54cfa32d91fe19bc10514157fe270b55ea10220226c1c5f0a2559c093158ca` | 1/1 | 0 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` | `sha256:93509dab8b9c18fd0c2d13ed6a159aa853a91df14f83d8374bb060bd5f240190` | 1/1 | 0 |

## Compte et tenant

| Point | Resultat |
| --- | --- |
| User email | trouve, masque |
| User created_at | `2026-06-27T10:30:05.837Z` |
| Tenant | `ecomlg-mqw7xv6f` |
| Tenant name | `eComLG` |
| Role | `owner` |
| Tenant plan | `AUTOPILOT` |
| Tenant status | `active` |

## Trial et billing

| Point | Resultat |
| --- | --- |
| `tenant_metadata.is_trial` | `true` |
| `tenant_metadata.trial_ends_at` | `2026-07-11T10:30:06.162Z` |
| `billing_subscriptions.status` | `trialing` |
| `billing_subscriptions.plan` | `AUTOPILOT` |
| `billing_subscriptions.billing_cycle` | `monthly` |
| Stripe subscription | presente, masquee |
| `current_period_end` | `2026-07-11T15:21:44.000Z` |
| `billing/current.status` | `trialing` |
| `billing/current.source` | `db` |
| `billing/current.hasStripeSubscription` | `true` |
| `billing/current.requiresCheckout` | `false` |

## Stripe pricing

| Point | Resultat |
| --- | --- |
| Webhook `checkout.session.completed` | recu et processed |
| Webhook `customer.subscription.created` | recu et processed |
| Stripe livemode | `true` |
| Prix Autopilot monthly | `19700` cents |
| Currency | `eur` |
| Metadata Stripe | `plan=AUTOPILOT`, `cycle=monthly`, `launch_pricing_2026=true` |
| Invoice initiale | amount `0`, trial period |

## KBActions

| Point | Resultat |
| --- | --- |
| `ai_actions_wallet` | 1 row tenant |
| Logs wallet | `kbActions remaining: 2000.00`, included monthly `2000` |
| Ledger | 3 rows tenant |
| Achat KBActions payant | 0 observe |

## Funnel / tracking

| Point | Resultat |
| --- | --- |
| `signup_attribution.marketing_owner_tenant_id` | `NULL` |
| UTM / click IDs | `NULL` |
| Landing URL | `https://client.keybuzz.io/register` |
| Funnel events tenant | `tenant_created`, `onboarding_started`, `dashboard_first_viewed` |
| `conversion_events` tenant | 0 |
| CAPI delivery tenant | 0 |
| Log StartTrial | `No destinations for ecomlg-mqw7xv6f, skipping StartTrial` |

Interpretation: pour ce compte de test direct/non media-buyer, l'absence de StartTrial CAPI n'est pas une pollution ni une preuve de casse media. Le tenant client n'a pas de destination outbound. Le test media-owner doit utiliser un lien avec `marketing_owner_tenant_id`.

## Dette 1 - billing_events tenant_id NULL

Preuve:

- `billing_events` contient les webhooks `checkout.session.completed`, `invoice.paid`, `customer.subscription.created`;
- ces lignes sont `processed=true`;
- leur payload contient `metadata.tenant_id=ecomlg-mqw7xv6f`;
- mais la colonne `billing_events.tenant_id` reste `NULL`;
- le code source logge actuellement les webhooks avec:
  `INSERT INTO billing_events (stripe_event_id, event_type, payload, processed, created_at)`
  sans renseigner `tenant_id`.

Impact:

- les requetes tenant-scoped sur `billing_events` renvoient 0 pour ce tenant;
- l'audit billing par tenant est incomplet;
- dette d'observabilite/data quality, pas un blocage du paiement.

Patch requis:

- extraire un `tenant_id` safe depuis `event.data.object.metadata.tenant_id`, ou via subscription/customer fallback selon type webhook;
- inserer `tenant_id` dans `billing_events`;
- eventuellement backfill metadata-only/read-only design puis migration controlee pour anciennes lignes.

## Dette 2 - route Octopia status incoherente

Preuve source/runtime:

- Client/BFF: `app/api/octopia/status/route.ts` appelle `${API_URL}/marketplaces/octopia/status?tenantId=...`;
- API: `app.register(octopiaRoutes, { prefix: '/octopia', pool })`;
- route API interne: `app.get('/marketplaces/octopia/status', ...)`;
- chemin reel expose: `/octopia/marketplaces/octopia/status`.

Tests passifs:

| URL API interne | Resultat |
| --- | --- |
| `/octopia/status?tenantId=ecomlg-mqw7xv6f` | 404 |
| `/marketplaces/octopia/status?tenantId=ecomlg-mqw7xv6f` | 404 |
| `/octopia/marketplaces/octopia/status?tenantId=ecomlg-mqw7xv6f` | 200 |

Impact:

- appels dashboard/onboarding Octopia peuvent remonter 404;
- dette feature connecteur, a corriger avant declaration zero dette.

Patch requis:

- corriger l'API pour exposer le chemin attendu sans double prefix, ou corriger le BFF Client;
- privilegier une correction API backward-compatible si plusieurs clients historiques appellent deja `/marketplaces/octopia/status`;
- verifier Amazon/Shopify/Octopia route parity apres patch.

## Non-regression verifiee

- aucun fake event;
- aucun checkout cree par CE;
- aucune mutation DB volontaire;
- aucun secret ou token affiche;
- API/Client PROD restent sur les images durcies PH-21.169;
- pricing Autopilot launch 2026 reel confirme par Stripe webhook;
- no-card trial converti en subscription Stripe trialing;
- `billing/current` ne retourne plus `requiresCheckout=true` apres Stripe, attendu.

## Verdict

GO READONLY VERIFY NO-CARD TRIAL BILLING CONVERSION REAL USER PATH PROD NO_GO_DEBTS_FOUND PH-SAAS-T8.12AS.21.170

Prochain GO recommande:

GO SOURCE PATCH BILLING EVENTS TENANT ID AND OCTOPIA STATUS ROUTE DEV PH-SAAS-T8.12AS.21.171

STOP
