# PH-T8.9A — ONBOARDING FUNNEL CRO TRUTH AUDIT

> Date : 2026-04-26
> Auteur : CE SaaS (Agent Cursor)
> Environnements : DEV + PROD (lecture seule)
> Type : audit vérité funnel/CRO onboarding + architecture de mesure
> Priorité : P0
> Aucune modification effectuée

---

## PRÉFLIGHT

### Repos

| Repo | Branche | HEAD | Clean |
|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `3207caf4` (PH-T8.8G) | ✅ |
| keybuzz-client | `ph148/onboarding-activation-replay` | `bad2e22` (PH-T7.3.2) | ✅ |

### Images déployées

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.107-ad-spend-idempotence-fix-dev` | `v3.5.107-ad-spend-idempotence-fix-prod` |
| Client | `v3.5.83-linkedin-replay-dev` | `v3.5.81-tiktok-attribution-fix-prod` |

### État PROD

Inchangé. Aucune modification effectuée.

---

## 1. CARTOGRAPHIE DU FUNNEL RÉEL

### Séquence complète observée

```
[1]  www.keybuzz.pro/pricing (Webflow, hors périmètre SaaS)
      ↓ clic plan
[2]  /register?plan=PRO&cycle=yearly
      ↓ step plan (si pas de param URL)
[3]  /register step=email — saisie email
      ↓ POST /api/auth/magic/start → envoi OTP
[4]  /register step=code — saisie OTP 6 digits
      ↓ signIn('email-otp') → vérification NextAuth
      ↓     OU
[3b] /register → Google OAuth → /api/auth/callback/google
      ↓ retour avec session → skip email+code → step company
[5]  /register step=company — infos entreprise
[6]  /register step=user — infos personnelles + CGU
      ↓ POST /api/auth/create-signup → crée user + tenant + attribution
      ↓ POST /api/billing/checkout-session → crée session Stripe
      ↓ redirect vers Stripe Checkout
[7]  Stripe Checkout (externe)
      ↓ paiement / trial
[8a] /register/success?session_id=cs_xxx — succès
      ↓ polling entitlement → trackPurchase() → /dashboard
[8b] /register?cancelled=1 — annulation
      ↓ step payment_cancelled → bouton relancer checkout
[9]  /dashboard ou /onboarding
      ↓ OnboardingHub (connexion marketplace)
[10] Première session produit utilisable
```

### Tableau des étapes

| # | Étape | Route/UI | Source de vérité actuelle | Observable ? |
|---|---|---|---|---|
| 1 | Landing/Pricing | `www.keybuzz.pro` | GA4 browser (Webflow) | ✅ browser only |
| 2 | Plan selected | `/register?plan=X&cycle=Y` | URL param client | ❌ pas de log backend |
| 3 | Email submitted | `/register` step email | — | ❌ aucun log |
| 3b | Google OAuth start | `signIn('google')` | — | ❌ aucun log |
| 4 | OTP sent | POST `/auth/otp/store` | Redis key `otp:{email}` | ⚠️ éphémère (TTL 10min) |
| 5 | OTP verified | POST `/auth/otp/verify` | Redis delete | ⚠️ éphémère |
| 6 | Company completed | `/register` step company | — | ❌ aucun log |
| 7 | User completed | `/register` step user | — | ❌ aucun log |
| 8 | Tenant created | POST `/tenant-context/create-signup` | `tenants` + `signup_attribution` | ✅ DB |
| 9 | Checkout started | POST `/billing/checkout-session` | `signup_attribution.stripe_session_id` | ✅ DB |
| 10 | Stripe payment | Stripe hosted page | Stripe Dashboard | ✅ Stripe |
| 11 | Trial started | Stripe webhook `checkout.session.completed` | `billing_subscriptions` (trialing) + `conversion_events` (StartTrial) + `billing_events` | ✅ DB + Stripe |
| 12 | Purchase completed | Stripe webhook `subscription.updated` (trialing→active) | `billing_subscriptions` (active) + `conversion_events` (Purchase) + `billing_events` | ✅ DB + Stripe |
| 13 | Onboarding hub | `/onboarding` ou `/start` | — | ❌ aucun log |
| 14 | First marketplace connected | OnboardingHub step 1 | `marketplace_connections` | ✅ DB (indirect) |
| 15 | First session active | — | `conversations` count > 0 | ⚠️ proxy indirect |

---

## 2. AUDIT CLIENT / UX

### Pages et composants du funnel

| Step UI | Fichier/route | Trigger d'entrée | Trigger de sortie | État persistant ? |
|---|---|---|---|---|
| **plan** | `app/register/page.tsx` | URL sans plan param | `setStep('email')` + `trackSignupStart()` | URL params |
| **email** | `app/register/page.tsx` | step=='email' | POST magic/start → `setStep('code')` | useState |
| **code** | `app/register/page.tsx` | step=='code' | `signIn('email-otp')` success → `setStep('company')` | useState |
| **company** | `app/register/page.tsx` | step=='company' | form submit → `setStep('user')` | useState |
| **user** | `app/register/page.tsx` | step=='user' | form submit → `handleUserSubmit()` | useState |
| **checkout** | `app/register/page.tsx` | step=='checkout' | redirect Stripe | — |
| **payment_cancelled** | `app/register/page.tsx` | `?cancelled=1` | retry checkout | URL params |
| **success** | `app/register/success/page.tsx` | `?session_id=cs_xxx` | poll entitlement → redirect /dashboard | — |

### Gestion du state

- **Tout en `useState`** — pas de useReducer, pas de Zustand, pas de context
- **URL params** : `plan`, `cycle`, `step`, `cancelled`, `email`, `oauth`
- **sessionStorage** : `kb_signup_context` (plan + cycle + attribution)
- **sessionStorage** : `kb_attribution_context` (UTMs/click IDs)
- **localStorage** : `kb_attribution_context_backup` (TTL 30min)

### OAuth Google continuity

1. Sauvegarde `sessionStorage.kb_signup_context` (plan, cycle, attribution)
2. `signIn('google', { callbackUrl: '/register?plan=X&cycle=Y&step=company&oauth=google' })`
3. Retour → session active, skip email/code, restauration depuis sessionStorage + URL

### Cas de reprise / abandon

| Cas | Comportement |
|---|---|
| Refresh page | state useState perdu → retour au step détecté par URL params |
| Tab fermée | sessionStorage perdu, localStorage backup 30min |
| OAuth redirect | sessionStorage + callbackUrl préservent plan/cycle |
| Stripe cancel | `/register?cancelled=1` → step `payment_cancelled` |
| Stripe success | `/register/success?session_id=cs_xxx` → polling → redirect |

### `/signup` = simple redirect vers `/register`

`app/signup/page.tsx` redirige immédiatement vers `/register` avec les query params préservés.

### `/workspace-setup` = flow alternatif sans Stripe

Pour les users authentifiés sans tenant. Steps: choice → create → success. Pas de checkout Stripe.

---

## 3. AUDIT ATTRIBUTION CONTINUITY

### Transport des données d'attribution à travers le funnel

| Champ | Landing (Webflow) | /register mount | Step company | Step user submit | Stripe checkout | Trial/Purchase | Persisté où ? |
|---|---|---|---|---|---|---|---|
| `utm_source` | URL param | ✅ capturé `initAttribution()` | ✅ en mémoire | ✅ envoyé create-signup | ✅ metadata Stripe | ✅ payload outbound | `signup_attribution`, Stripe metadata |
| `utm_medium` | URL param | ✅ | ✅ | ✅ | ✅ | ✅ | idem |
| `utm_campaign` | URL param | ✅ | ✅ | ✅ | ✅ | ✅ | idem |
| `utm_term` | URL param | ✅ | ✅ | ✅ | ✅ tronqué | ✅ | idem |
| `utm_content` | URL param | ✅ | ✅ | ✅ | ✅ tronqué | ✅ | idem |
| `gclid` | URL param | ✅ | ✅ | ✅ | ✅ metadata | ✅ payload | `signup_attribution` |
| `fbclid` | URL param | ✅ | ✅ | ✅ | ✅ metadata | ✅ payload | `signup_attribution` |
| `fbc` | reconstruit ou cookie | ✅ | ✅ | ✅ | — | ✅ payload | `signup_attribution` |
| `fbp` | cookie `_fbp` | ✅ | ✅ | ✅ | — | ✅ payload | `signup_attribution` |
| `ttclid` | URL param | ✅ | ✅ | ✅ | ✅ metadata | ✅ payload | `signup_attribution` |
| `plan` | URL param | ✅ | ✅ | ✅ | ✅ sub metadata | ✅ | `signup_attribution`, Stripe |
| `cycle` | URL param | ✅ | ✅ | ✅ | ✅ sub metadata | ✅ | `signup_attribution`, Stripe |
| `landing_url` | — | ✅ `window.location.href` | ✅ | ✅ | — | ✅ payload | `signup_attribution` |
| `referrer` | — | ✅ `document.referrer` | ✅ | ✅ | — | ✅ payload | `signup_attribution` |
| `attribution_id` | — | ✅ généré UUID | ✅ | ✅ | ✅ metadata | ✅ `client_id` GA4 | `signup_attribution` |

### Ce qui est conservé ✅

- **Tout le pipeline attribution est intact** du landing au backend
- La stratégie **first-touch** empêche l'écrasement accidentel
- Le lien `attribution_id ↔ stripe_session_id` est établi dans `signup_attribution`
- L'objet complet est envoyé dans `create-signup` ET `checkout-session`

### Ce qui est perdu ou à risque ⚠️

| Risque | Impact | Gravité |
|---|---|---|
| sessionStorage effacé si le navigateur ferme entre pricing et fin du register | Attribution perdue, mais backup localStorage 30min | Moyen |
| Cross-domain Webflow→SaaS | Les UTMs survivent via URL params. Les cookies first-party (`_fbp`) ne traversent PAS les domaines | Moyen |
| Stripe redirect aller-retour | Les UTMs ne sont PAS dans l'URL Stripe. Le sessionStorage persiste si même onglet | Faible |

### Ce qui est déductible seulement partiellement

- Le parcours exact avant `/register` (pages Webflow visitées) n'est visible que via GA4 browser
- Le `referrer` capturé est celui de la première page SaaS, pas de la première page Webflow

---

## 4. AUDIT BACKEND / DB / STRIPE

### Tables et sources de vérité

| Table | Rôle funnel | Rows DEV | Fiabilité |
|---|---|---|---|
| `tenants` | Tenant créé (step 8) | 20 | ✅ Haute |
| `users` | User créé | 30 | ✅ Haute |
| `user_tenants` | Association user↔tenant | — | ✅ Haute |
| `tenant_metadata` | Trial status, infos company | 18 | ✅ Haute |
| `signup_attribution` | Attribution marketing complète | 6 | ✅ Haute (mais données test vides) |
| `billing_customers` | Lien tenant↔Stripe customer | 17 | ✅ Haute |
| `billing_subscriptions` | Subscription active/trialing/canceled | 16 | ✅ Haute |
| `billing_events` | Audit trail Stripe webhooks | 244 | ✅ Haute |
| `conversion_events` | Events StartTrial/Purchase outbound | 0 (DEV) | ⚠️ Vide en DEV |
| `outbound_conversion_destinations` | Config destinations webhook/CAPI | — | ✅ |
| `outbound_conversion_delivery_logs` | Logs de livraison | — | ✅ |

### Chemin Stripe webhook

```
Stripe → POST /billing/webhook → signature vérifiée
  → checkout.session.completed
    → handleCheckoutCompleted()
      → emitOutboundConversion('StartTrial', tenantId, ...)
      → emitConversionWebhook(session) [GA4 MP]
      → welcome email
  → customer.subscription.created
    → handleSubscriptionChange()
      → upsert billing_subscriptions
      → grant KBActions
      → tenant status → active
  → customer.subscription.updated
    → handleSubscriptionChange()
      → si trialing→active : emitOutboundConversion('Purchase', tenantId, ...)
  → customer.subscription.deleted
    → handleSubscriptionDeleted()
  → invoice.paid / invoice.payment_failed
```

### Business events émis

| Event | Trigger | Destination | DB proof |
|---|---|---|---|
| StartTrial | `checkout.session.completed` | outbound destinations + GA4 MP | `conversion_events` + `billing_events` |
| Purchase | `subscription.updated` (trialing→active) | outbound destinations | `conversion_events` + `billing_events` |

### Valeur Stripe réelle

Depuis PH-T8.4.1 :
- **StartTrial** : `session.amount_total / 100` + `session.currency` (valeur réelle)
- **Purchase** : `subscription.items[*].price.unit_amount * quantity / 100` (valeur réelle)

---

## 5. MATRICE D'OBSERVABILITÉ RÉELLE

| Étape funnel | Comptable aujourd'hui ? | Source de vérité | Granularité | Trou principal |
|---|---|---|---|---|
| **Landing/Pricing** | ⚠️ Partiel | GA4 browser (Webflow) | Session browser | Pas de lien avec le funnel SaaS |
| **Plan selected** | ❌ Non | — | — | Aucun log. URL param pas tracké |
| **Register started** | ❌ Non | — | — | `trackSignupStart()` browser seulement (GA4 Pixel), pas en DB |
| **Email submitted** | ❌ Non | — | — | Aucun log backend ou client |
| **OTP sent** | ⚠️ Éphémère | Redis `otp:{email}` (TTL 10min) | Par email | Disparaît après 10min |
| **OTP verified** | ⚠️ Éphémère | Redis delete | — | Aucune persistance |
| **Google OAuth start** | ❌ Non | — | — | Aucun log |
| **Google OAuth success** | ⚠️ Indirect | Session NextAuth créée | — | Pas de log funnel dédié |
| **Company completed** | ❌ Non | — | — | Aucun log |
| **User completed** | ❌ Non | — | — | Aucun log |
| **Tenant created** | ✅ Oui | `tenants` + `signup_attribution` | Par tenant_id | Fiable |
| **Checkout started** | ✅ Oui | `signup_attribution.stripe_session_id` | Par tenant_id | Fiable |
| **Stripe payment** | ✅ Oui | Stripe Dashboard | Par session_id | Fiable |
| **Trial started** | ✅ Oui | `billing_subscriptions` (status=trialing) + `conversion_events` (StartTrial) + `billing_events` | Par tenant_id | Fiable |
| **Purchase completed** | ✅ Oui | `billing_subscriptions` (status=active) + `conversion_events` (Purchase) + `billing_events` | Par tenant_id | Fiable |
| **Onboarding hub viewed** | ❌ Non | — | — | Aucun log |
| **First marketplace connected** | ⚠️ Indirect | `marketplace_connections` | Par tenant_id | Pas de timestamp événement dédié |
| **First session active** | ⚠️ Indirect | `conversations` count > 0 | Proxy | Pas un vrai événement |

### Résumé des gaps

| Zone | Steps sans observabilité | Impact CRO |
|---|---|---|
| **Pré-tenant** (steps 2-7) | plan_selected, email_submitted, otp_sent, otp_verified, company_completed, user_completed | **CRITIQUE** — impossible de mesurer la perdition dans le formulaire d'inscription |
| **Post-checkout** (steps 13-15) | onboarding_viewed, marketplace_connected, first_session | **MOYEN** — activation product non mesurée |
| **Cross-domain** | Webflow → SaaS transition | **MOYEN** — pas de stitching propre |

### Ce qui fonctionne bien

| Zone | Qualité |
|---|---|
| Attribution marketing (UTMs/click IDs) | ✅ Pipeline complet landing→DB→Stripe→outbound |
| Business events (StartTrial, Purchase) | ✅ Fiables, valeur réelle Stripe, dedup par event_id |
| Outbound conversions (Meta CAPI, webhook) | ✅ Architecture multi-destination opérationnelle |
| tenant_id stitching | ✅ Cohérent de bout en bout |

---

## 6. MODÈLE CIBLE FUNNEL / CRO

### A. Dictionnaire d'événements funnel canonique

| Event canonique | Propriétaire | Description |
|---|---|---|
| `register_started` | Client (browser) | Le composant `/register` est monté et initialisé |
| `plan_selected` | Client (browser) | Un plan a été sélectionné dans le step plan |
| `email_submitted` | API | OTP envoyé avec succès (POST `/auth/otp/store` 200) |
| `otp_verified` | API | OTP vérifié avec succès (POST `/auth/otp/verify` 200) |
| `oauth_started` | Client (browser) | Redirect Google/Microsoft initié |
| `oauth_completed` | API | Session OAuth créée pour un flow register (first login) |
| `company_completed` | Client (browser) | Form company soumis avec succès |
| `user_completed` | Client (browser) | Form user soumis avec succès |
| `tenant_created` | API | INSERT `tenants` + `signup_attribution` |
| `checkout_started` | API | Stripe session créée (POST `/billing/checkout-session`) |
| `checkout_completed` | Stripe webhook | `checkout.session.completed` |
| `trial_started` | Stripe webhook | Subscription status = `trialing` |
| `purchase_completed` | Stripe webhook | Subscription `trialing` → `active` |
| `onboarding_viewed` | Client (browser) | OnboardingHub monté |
| `marketplace_connected` | API | Marketplace connection activée |
| `first_conversation_viewed` | Client (browser) | Premier accès inbox avec messages |

### B. Propriétaire de chaque événement

| Propriétaire | Events | Raison |
|---|---|---|
| **Client (browser)** | register_started, plan_selected, company_completed, user_completed, oauth_started, onboarding_viewed, first_conversation_viewed | Étapes UX visibles uniquement côté client |
| **API (backend)** | email_submitted, otp_verified, oauth_completed, tenant_created, checkout_started | Actions vérifiables avec certitude côté serveur |
| **Stripe (webhook)** | checkout_completed, trial_started, purchase_completed | Source de vérité financière |

### C. Identifiants de stitching

| Identifiant | Portée | Créé quand | Utilisé pour |
|---|---|---|---|
| `attribution_id` | Cross-session pré-signup | `initAttribution()` (UUID v4) | Lier browser anonymous → tenant |
| `session_id` | Session browser | NextAuth JWT | Lier les actions authentifiées |
| `tenant_id` | Post-signup | `create-signup` | Stitching principal post-tenant |
| `stripe_customer_id` | Post-checkout | Stripe webhook | Lien Stripe ↔ tenant |
| `stripe_subscription_id` | Post-checkout | Stripe webhook | Dedup business events |
| `event_id` | Par event | `conv_{tenantId}_{event}_{subId}` | Idempotence outbound |
| `funnel_id` | **À créer** | `initAttribution()` ou register mount | Lier toutes les étapes pré et post signup |

Le `funnel_id` est le chaînon manquant. Actuellement, `attribution_id` joue ce rôle partiellement mais il n'est pas systématiquement propagé entre les steps browser et le backend.

### D. Règle anti-doublon

1. **Un seul propriétaire par step** — pas de double-emit client+serveur pour le même événement
2. **Micro-steps funnel ≠ conversions publicitaires** :
   - `register_started`, `email_submitted`, `plan_selected` → **CRO interne uniquement**, JAMAIS envoyé vers Meta/TikTok/Google
   - `trial_started` → **StartTrial** → envoyé vers plateformes ads (événement business)
   - `purchase_completed` → **Purchase** → envoyé vers plateformes ads (événement business)
3. Les micro-steps funnel servent exclusivement à l'analyse de perdition produit
4. Les conversions publicitaires restent limitées à StartTrial + Purchase (validé PH-T8.7A)

### E. Stockage recommandé

**Option recommandée : nouvelle table dédiée `funnel_events`**

Justification :
- Les étapes pré-tenant n'ont pas de `tenant_id` fiable (l'utilisateur n'est pas encore créé)
- Les events existants (`conversion_events`, `billing_events`) servent un autre but
- La table `signup_attribution` capture un snapshot unique, pas un flux d'événements
- Un flux chronologique d'événements permet l'analyse de cohortes et de perdition

```sql
CREATE TABLE funnel_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  funnel_id TEXT NOT NULL,           -- lien cross-step (attribution_id)
  event_name TEXT NOT NULL,          -- dictionnaire canonique ci-dessus
  tenant_id TEXT,                    -- NULL avant create-signup
  user_email TEXT,                   -- disponible à partir de email_submitted
  properties JSONB DEFAULT '{}',    -- plan, cycle, oauth_provider, etc.
  source TEXT NOT NULL,              -- 'client' | 'api' | 'stripe_webhook'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- dedup par funnel_id + event_name (un seul par step par funnel)
  UNIQUE(funnel_id, event_name)
);

CREATE INDEX idx_funnel_events_funnel ON funnel_events(funnel_id);
CREATE INDEX idx_funnel_events_name ON funnel_events(event_name);
CREATE INDEX idx_funnel_events_created ON funnel_events(created_at);
CREATE INDEX idx_funnel_events_tenant ON funnel_events(tenant_id) WHERE tenant_id IS NOT NULL;
```

---

## 7. PLAN D'IMPLÉMENTATION RECOMMANDÉ

### Phase B1 — Instrumentation client onboarding (DEV)

**Scope** : ajouter les émissions d'événements côté client

| Événement | Où émettre | Comment |
|---|---|---|
| `register_started` | `app/register/page.tsx` useEffect mount | POST `/api/funnel/event` |
| `plan_selected` | `app/register/page.tsx` handlePlanSelect | POST `/api/funnel/event` |
| `company_completed` | `app/register/page.tsx` handleCompanySubmit success | POST `/api/funnel/event` |
| `user_completed` | `app/register/page.tsx` handleUserSubmit success | POST `/api/funnel/event` |
| `oauth_started` | `app/register/page.tsx` handleGoogleAuth | POST `/api/funnel/event` |
| `onboarding_viewed` | `OnboardingHub.tsx` useEffect mount | POST `/api/funnel/event` |

Le `funnel_id` = `attribution_id` existant, propagé via les mêmes canaux.

**Effort** : 1 jour

### Phase B2 — Capture API / persistance (DEV)

**Scope** : créer la table `funnel_events` et les endpoints de capture

| Action | Détail |
|---|---|
| Table `funnel_events` | CREATE TABLE (schema ci-dessus) |
| Route `POST /funnel/event` | Accepte `{ funnel_id, event_name, tenant_id?, email?, properties, source }` |
| Route `GET /funnel/events` | Admin-only, filtres par funnel_id/tenant_id/date |
| Enrichir OTP routes | Émettre `email_submitted` après OTP store success |
| Enrichir OTP routes | Émettre `otp_verified` après OTP verify success |
| Enrichir create-signup | Émettre `tenant_created` |
| Enrichir checkout-session | Émettre `checkout_started` |
| Enrichir webhook handler | Émettre `checkout_completed`, `trial_started`, `purchase_completed` |

**Effort** : 1-2 jours

### Phase B3 — Agrégation metrics funnel (DEV)

**Scope** : endpoint d'agrégation pour le dashboard CRO

| Action | Détail |
|---|---|
| Route `GET /funnel/metrics` | Agrège `funnel_events` par event_name, avec comptage et taux de conversion inter-step |
| Filtres | `from`, `to`, `utm_source`, `plan` |
| Format retour | `{ steps: [{ name, count, conversion_rate_from_previous }], period, filters }` |

**Effort** : 1 jour

### Phase B4 — UI Admin funnel/CRO

**Scope** : page Admin V2 pour visualiser le funnel

| Action | Détail |
|---|---|
| Page `/marketing/funnel` | Graphique funnel en barres horizontales décroissantes |
| Filtres | Période, source, plan |
| Métriques | Drop-off par step, conversion rate global, identification du step le plus perdant |

**Effort** : 1-2 jours (Agent Admin V2)

### Phase B5 — Promotion PROD

**Scope** : déployer le pipeline funnel complet en PROD

| Action | Détail |
|---|---|
| Table PROD | CREATE TABLE `funnel_events` |
| API PROD | Build + deploy via GitOps |
| Client PROD | Build + deploy via GitOps |
| Admin PROD | Build + deploy (si UI prête) |
| Validation | Vérifier qu'un vrai signup PROD alimente `funnel_events` |

**Effort** : 1 jour

### Phase B6 — Exploitation agence/media buyer

**Scope** : pas d'envoi automatique des micro-steps vers les plateformes ads

| Action | Détail |
|---|---|
| Funnel CRO interne | Accessible uniquement dans Admin V2 |
| Plateformes ads | Continuent à recevoir uniquement StartTrial + Purchase (inchangé) |
| Rapport agence | Export optionnel du funnel en CSV/PDF si demandé |

**Distinction claire** :

| Usage | Events concernés | Destination |
|---|---|---|
| **CRO produit** | Tous les 16 events funnel | `funnel_events` → Admin UI |
| **Reporting acquisition** | StartTrial, Purchase | `conversion_events` → destinations outbound |
| **NE DOIT PAS partir vers ads** | register_started, email_submitted, otp_verified, company_completed, user_completed | Jamais |

---

## 8. GAPS EXACTS

### Gap critique : le trou noir pré-tenant

**6 étapes** entre le premier contact SaaS et la création du tenant ne sont pas observables en base :

```
plan_selected → email_submitted → otp_sent → otp_verified → company_completed → user_completed
```

C'est ici que se trouve la perdition funnel la plus importante. On sait combien de tenants sont créés (`tenants` table), mais on ne sait pas combien ont *commencé* le formulaire sans le finir.

### Gap moyen : le trou post-checkout

L'activation produit (connexion marketplace, premier message) n'est pas tracée de façon structurée. On peut le déduire indirectement mais sans chronologie précise.

### Gap mineur : cross-domain stitching

Le passage Webflow → SaaS perd les cookies first-party (notamment `_fbp`). Les UTMs survivent via URL params. Le GA4 cross-domain linker (`_gl`) est capturé mais son exploitation est limitée.

---

## CONCLUSION

### Ce qui fonctionne bien

- ✅ Pipeline attribution complet (UTMs → DB → Stripe → outbound)
- ✅ Business events fiables (StartTrial, Purchase) avec valeur Stripe réelle
- ✅ Outbound conversions multi-destination opérationnelles
- ✅ Deduplication par event_id
- ✅ tenant_id stitching cohérent de bout en bout

### Ce qui manque

- ❌ **Zéro observabilité** sur les 6 étapes pré-tenant du formulaire d'inscription
- ❌ **Pas de table funnel_events** — impossible de mesurer les abandons
- ❌ **Pas de funnel_id** dédié pour stitcher les steps anonymes → authentifiés
- ❌ **Pas d'activation tracking** structuré post-checkout

### Aucune modification effectuée

Ce rapport est strictement en lecture seule. Aucun fichier modifié, aucun build, aucun deploy, aucune donnée créée.

---

## VERDICT

**ONBOARDING FUNNEL CRO TRUTH ESTABLISHED — STEP OBSERVABILITY KNOWN — IMPLEMENTATION PLAN READY**

- GO pour implémentation phases B1-B6
- Le gap critique est le trou noir pré-tenant (6 steps non observables)
- L'architecture existante (attribution, outbound conversions) est solide et ne nécessite pas de refactor
- La nouvelle table `funnel_events` est la pièce manquante
