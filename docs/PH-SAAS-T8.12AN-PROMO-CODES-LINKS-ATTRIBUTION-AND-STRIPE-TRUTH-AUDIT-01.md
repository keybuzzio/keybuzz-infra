# PH-SAAS-T8.12AN — Promo Codes, Links, Attribution et Stripe Truth Audit

> Date : 4 mai 2026
> Type : Audit verite + design technique/produit — LECTURE SEULE
> Priorite : P0
> Environnement : DEV/PROD lecture seule
> Mutations : AUCUNE (pas de code, build, deploy, mutation DB/Stripe)

---

## 0. FREEZE LOGIQUE BILLING

| Element | Valeur |
|---|---|
| Date/heure audit | 2026-05-04 16:15 CEST |
| Scope | Checkout Stripe, coupons, promo codes, attribution, trial |
| Agents paralleles | Aucun detecte sur billing/Stripe/Admin |
| Runtime API PROD | `v3.5.139-amazon-oauth-inbound-bridge-prod` |
| Runtime Client PROD | `v3.5.151-amazon-oauth-inbound-bridge-prod` |
| Runtime Admin PROD | Non deploye (namespace vide) |
| Runtime Website PROD | `v0.6.8-tiktok-browser-pixel-prod` |
| Runtime Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` |

**Engagement** : aucun coupon cree, aucun test checkout, aucune mutation Stripe, aucune mutation DB.

---

## 1. PREFLIGHT REPOS

| Repo | Branche | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `6511ed7c` | dist/ untracked (safe) | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `b2bba25` | clean | OK |
| keybuzz-admin-v2 (bastion: keybuzz-admin) | `main` | `7296872` | clean | OK |
| keybuzz-infra | `main` | `f943166` | clean | OK |
| keybuzz-backend | `main` | `f2afd3e` | clean | OK |
| keybuzz-website | `main` | `0b9d1ea` | clean | OK |

---

## 2. CARTOGRAPHIE CHECKOUT / STRIPE ACTUELLE

### 2.1 Fichiers source billing

Tout le code Stripe est dans `keybuzz-api/src/modules/billing/` :

| Fichier | Role |
|---|---|
| `routes.ts` | Tous les endpoints billing + webhook handler |
| `stripe.ts` | Initialisation client Stripe (SDK v14, apiVersion `2023-10-16`) |
| `pricing.ts` | Mapping plan/cycle -> Stripe Price IDs (env vars) |
| `index.ts` | Export module |

### 2.2 Flows Stripe identifies

| Flow | Endpoint API | Methode Stripe | Mode | `allow_promotion_codes` | Trial | Produits concernes |
|---|---|---|---|---|---|---|
| **Signup / checkout initial** | `POST /billing/checkout-session` | `stripe.checkout.sessions.create` | `subscription` | **OUI** | 14j (`trial_period_days: 14`) | Plan (STARTER/PRO/AUTOPILOT) + channel addons optionnels |
| **KBActions achat** | `POST /billing/ai-actions-checkout` | `stripe.checkout.sessions.create` | `payment` (one-time) | **NON** | Non | KBActions pack (price_data inline) |
| **Agent KeyBuzz addon** | `POST /billing/checkout-agent-keybuzz` | `stripe.checkout.sessions.create` | `subscription` | **OUI** | Preserve trial existant | Plan existant + Agent KeyBuzz addon |
| **Changement plan** | `POST /billing/change-plan` | `stripe.subscriptions.update` | n/a (pas de Checkout) | **NON** (mise a jour directe) | proration_behavior conditionnel | Plan uniquement |
| **Addons canaux** | `POST /billing/update-channels` | `stripe.subscriptions.update` | n/a | **NON** | proration_behavior conditionnel | Channel addon |
| **Desactivation Agent KB** | `POST /billing/update-agent-keybuzz` | `stripe.subscriptions.update` (remove item) | n/a | **NON** | proration_behavior conditionnel | Agent KeyBuzz addon |
| **Portail Stripe** | `POST /billing/portal-session` | `stripe.billingPortal.sessions.create` | n/a | n/a | n/a | Gestion client Stripe |
| **Webhook** | `POST /billing/webhook` | Verification signature | n/a | n/a | n/a | `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted` |

### 2.3 Webhook handlers

| Event Stripe | Handler | Actions |
|---|---|---|
| `checkout.session.completed` | `handleCheckoutCompleted` | Upsert `billing_subscriptions` + `billing_customers` ; emit `StartTrial` (si `trialing`) ; emit GA4 MP conversion ; PH138-K: cancel old sub si type `agent_keybuzz_addon` |
| `customer.subscription.updated` | `handleSubscriptionUpdated` | Update `billing_subscriptions` ; emit `Purchase` (si status passe a `active` depuis `trialing`) ; update `tenants.plan` ; activate `pending_payment` ; grant KBActions ; sync wallet |
| `customer.subscription.deleted` | `handleSubscriptionDeleted` | Update status `canceled` ; reset plan `starter` ; reset KBActions |

### 2.4 Valeur des conversions

| Event | Source valeur | Champ |
|---|---|---|
| StartTrial (GA4 MP) | `session.amount_total / 100` | 0 EUR (trial gratuit) |
| Purchase (outbound) | `subscription.items.data` -> somme `(unit_amount * qty) / 100` | Montant reel Stripe (inclut prorations, addons, **et effet coupons**) |

**Point cle** : la valeur envoyee aux plateformes vient deja de Stripe reel. Un coupon applique reduirait correctement la valeur Purchase sans modification de code.

---

## 3. AUDIT EXISTENCE PROMO / COUPON

| Surface | Existant ? | Preuve | Actif runtime ? | Reutilisable ? |
|---|---|---|---|---|
| Code source API (billing/) | **NON** | grep `promo\|coupon\|discount\|promotion_code` = 0 resultat | n/a | n/a |
| Code source Client | **NON** | grep = 0 (seul `annualDiscount` = affichage prix annuel) | n/a | n/a |
| Code source Admin | **NON** | Pas de page /promo ni endpoint | n/a | n/a |
| Code source Website | **NON** | grep = 0 | n/a | n/a |
| Tables DB | **NON** | Pas de table `promo_codes` ou equivalente | n/a | n/a |
| `allow_promotion_codes` | **OUI** | Actif dans `checkout.sessions.create` (plan + Agent KB) | **OUI** | **OUI** — un client pourrait deja entrer un code promo Stripe dans le Checkout |

**Verdict : ABSENT cote KeyBuzz, mais `allow_promotion_codes: true` est DEJA ACTIF sur Stripe Checkout.**

Cela signifie que si un coupon/promotion_code etait cree dans Stripe Dashboard, un utilisateur pourrait deja l'appliquer manuellement lors du checkout. Aucune modification de code n'est necessaire pour le support basique.

---

## 4. AUDIT PRODUITS STRIPE ET ELIGIBILITE DISCOUNT

### 4.1 Produits identifies (source : `pricing.ts` + deployment manifest)

| Produit KeyBuzz | Type | Stripe product ID | Stripe price(s) | Source |
|---|---|---|---|---|
| STARTER | Plan SaaS | env `STRIPE_PRICE_STARTER_MONTHLY/ANNUAL` | `price_*` | Env vars K8s secret |
| PRO | Plan SaaS | env `STRIPE_PRICE_PRO_MONTHLY/ANNUAL` | `price_*` | Env vars K8s secret |
| AUTOPILOT | Plan SaaS | env `STRIPE_PRICE_AUTOPILOT_MONTHLY/ANNUAL` | `price_*` | Env vars K8s secret |
| Channel addon | Addon subscription | `prod_TpJTEELacYjLGG` (hardcode fallback) | env vars | Manifest PROD |
| Agent KeyBuzz addon | Addon subscription | `prod_UFtAMUaGMjxErY` (PROD) | `price_1THNOUFC0QQLHISR1Tm7B8FW` (monthly), `price_1THNOVFC0QQLHISRmvYEis5A` (annual) | Manifest PROD |
| KBActions pack | One-time payment | Pas de product ID (price_data inline) | Genere dynamiquement | routes.ts |

### 4.2 Prix affiches (reference, `PLAN_PRICES` dans pricing.ts)

| Plan | Monthly | Annual (par mois) | Annual total estime |
|---|---|---|---|
| STARTER | 97 EUR | 78 EUR | ~936 EUR |
| PRO | 297 EUR | 238 EUR | ~2856 EUR |
| AUTOPILOT | 497 EUR | 398 EUR | ~4776 EUR |

### 4.3 Eligibilite discount cible

| Element | Discount autorise ? | Raison |
|---|---|---|
| Forfait SaaS (STARTER/PRO/AUTOPILOT) | **OUI** | Cible principale des promos |
| Upgrade vers forfait superieur | **OUI** | Via `applies_to` sur les plan products |
| KBActions | **NON** | Mode `payment` one-time, pas de `allow_promotion_codes`, pas de product_id fixe |
| Agent KeyBuzz addon | **A EXCLURE** | Meme subscription, mais exclurable via `applies_to` sur coupon |
| Channel addon | **A EXCLURE** | Meme subscription, exclurable via `applies_to` |
| Taxes | Stripe applique les coupons avant taxes | Comportement standard Stripe |
| Prorations | Stripe calcule les prorations APRES application du discount existant | Doc Stripe confirmee |

**Mecanisme Stripe pour exclure addons** : le champ `applies_to.products[]` du coupon limite le discount aux seuls product IDs listes. En listant uniquement les product IDs des plans (STARTER/PRO/AUTOPILOT), les addons (Agent KB, channels) sont automatiquement exclus.

---

## 5. CAS PRODUIT CONCOURS : 1 AN PRO

### 5.1 Objectif

Valeur : equivalent 1 an de forfait PRO.
- Si PRO annuel choisi : 100% couvert
- Si AUTOPILOT annuel choisi : deduction de la valeur PRO, reste a payer
- KBActions/Agent KB/addons exclus
- Attribution marketing propre

### 5.2 Comparaison des options

#### Option A — Coupon 100% `percent_off` sur produit PRO uniquement

| Critere | Evaluation |
|---|---|
| PRO annuel | OK — 100% off |
| AUTOPILOT annuel | **KO** — coupon `applies_to: [PRO product]` ne s'applique pas a AUTOPILOT |
| Addons exclus | OUI (applies_to) |
| Trial safe | A prouver (voir section 6) |
| Tracking safe | OUI — Stripe value = 0 pour PRO |
| Complexite | Faible |
| **Verdict** | **PARTIEL** — ne gere pas l'upgrade vers AUTOPILOT |

#### Option B — Coupon `amount_off` equivalent PRO annuel, `applies_to` tous les plan products

| Critere | Evaluation |
|---|---|
| PRO annuel | OK — ~2856 EUR off = gratuit |
| AUTOPILOT annuel | OK — ~2856 EUR off, reste ~1920 EUR a payer |
| Addons exclus | OUI (applies_to plan products seulement) |
| Trial safe | A prouver (`duration=repeating` 12 mois recommande) |
| Tracking safe | OUI — Stripe value = montant reel apres deduction |
| Complexite | Moyenne |
| **Verdict** | **RECOMMANDE** — gere upgrade, addons exclus |

#### Option C — Promotion Code Stripe `first_time_transaction` + `max_redemptions: 1`

| Critere | Evaluation |
|---|---|
| PRO annuel | OK (base sur coupon Option B) |
| AUTOPILOT annuel | OK (idem) |
| Addons exclus | OUI (via coupon sous-jacent) |
| Trial safe | Meme problematique que B |
| Tracking safe | OUI |
| Complexite | Faible (coupon + promotion code) |
| **Verdict** | **RECOMMANDE comme couche au-dessus de Option B** |

#### Option D — Credit KeyBuzz custom en DB via Stripe customer balance

| Critere | Evaluation |
|---|---|
| PRO annuel | Possible mais complexe |
| AUTOPILOT annuel | Tres complexe (gestion balance/invoices) |
| Addons exclus | Pas nativement — balance s'applique a toute invoice |
| Trial safe | Complexe |
| Tracking safe | Risque — valeur != montant charge |
| Complexite | **TRES ELEVEE** |
| **Verdict** | **A EVITER** — dette technique massive, risque billing |

#### Option E — Lien promo Admin avec `discounts[]` pre-applique dans Checkout

| Critere | Evaluation |
|---|---|
| PRO annuel | OK |
| AUTOPILOT annuel | OK |
| Addons exclus | OUI (via coupon) |
| Trial safe | Meme que B |
| Tracking safe | OUI |
| UX | **Meilleure** — utilisateur ne saisit pas de code, le lien pre-applique |
| Complexite | Moyenne (API modifie pour accepter `discounts[]` OU `promotion_code` depuis le lien) |
| **Verdict** | **RECOMMANDE pour UX optimale** |

### 5.3 Matrice de synthese

| Option | PRO annuel | AUTOPILOT annuel | Addons exclus | Trial safe | Tracking safe | Complexite | Reco |
|---|---|---|---|---|---|---|---|
| A (100% PRO only) | OK | KO | OUI | A prouver | OUI | Faible | NON |
| **B (amount_off plan)** | OK | OK | OUI | A prouver | OUI | Moyenne | **OUI** |
| **C (promotion code)** | OK | OK | OUI | A prouver | OUI | Faible+ | **OUI (couche UX)** |
| D (customer balance) | Possible | Complexe | NON natif | Complexe | Risque | Tres elevee | **NON** |
| **E (discounts[] pre)** | OK | OK | OUI | A prouver | OUI | Moyenne | **OUI (meilleur UX)** |

### 5.4 Recommandation

**Option B + C + E combinee** :

1. Creer un **coupon Stripe** avec `amount_off` = valeur PRO annuel, `duration=repeating`, `duration_in_months=12`, `applies_to.products` = [STARTER product, PRO product, AUTOPILOT product]
2. Creer un **promotion code** Stripe avec `max_redemptions: 1`, `code: CONCOURS-xxx`
3. L'Admin genere un **lien promo** contenant le code
4. Le Client capture le code et le passe a l'API
5. L'API cree le Checkout avec `discounts[0].promotion_code` (pre-applique) OU l'utilisateur le saisit dans le Checkout (`allow_promotion_codes` deja actif)

---

## 6. POINT CRITIQUE TRIAL + COUPON

### 6.1 Risque identifie

Le checkout actuel utilise `subscription_data.trial_period_days: 14`. Stripe cree une subscription `trialing` avec une premiere invoice a 0 EUR.

| Question | Reponse | Source | Risque |
|---|---|---|---|
| Le trial cree-t-il une invoice 0 ? | **OUI** | Code API : `trial_period_days: 14` | Baseline |
| `duration=once` est-il consomme pendant trial ? | **PROBABLEMENT OUI** — la doc Stripe dit "applies only to the first invoice" | Stripe docs: "When duration=once, the coupon applies only to the next invoice and is considered used after the invoice finalizes" | **CRITIQUE** — coupon gaspille sur invoice $0 |
| `duration=repeating` 12 months est-il mieux ? | **OUI** — les 12 mois debutent a la creation, le trial de 14j compte dans le 1er mois, puis 11 mois de facturation gratuite | Stripe docs: `duration_in_months` | **RECOMMANDE** |
| `amount_off` sur subscription avec trial ? | Le discount s'applique mais la premiere invoice est 0, donc pas d'effet visible — pas de gaspillage avec `repeating` | Stripe docs | Safe avec repeating |
| Upgrade pendant trial preserve-t-il le discount ? | **OUI** — `stripe.subscriptions.update` preserve les discounts existants | Stripe docs: "proration and applies any existing discounts" | OK |
| Upgrade apres trial preserve-t-il le discount ? | **OUI** — tant que la `duration_in_months` n'est pas expiree | Stripe docs | OK |

### 6.2 Conclusion

**`duration=once` est DANGEREUX avec le trial 14 jours — coupon consomme sur la facture a 0.**

**`duration=repeating` avec `duration_in_months=12` est la bonne strategie** :
- Le coupon couvre 12 mois de facturation
- Le trial de 14j est inclus dans le premier mois
- Apres le trial, 11+ mois de facturation gratuite (ou avec deduction)
- L'upgrade preserve le discount

### 6.3 Gate

**GO DESIGN ONLY — STRIPE DEV TEST REQUIRED** pour prouver formellement :

1. Que `duration=repeating` + `duration_in_months=12` n'est pas consomme sur l'invoice trial 0
2. Que l'upgrade de PRO vers AUTOPILOT preserve le coupon
3. Que `applies_to` exclut effectivement les addons
4. Que la valeur `Purchase` reflete le montant reel apres deduction

---

## 7. ATTRIBUTION ET LIENS PROMO

### 7.1 Format de lien recommande

```
https://www.keybuzz.pro/pricing?promo=CONCOURS-xxx&utm_source=concours&utm_medium=email&utm_campaign=jeu-concours-2026&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### 7.2 Etat actuel du forwarding

| Parametre | Website forward | Client capture | API persist | Stripe metadata | Tracking/reporting |
|---|---|---|---|---|---|
| `promo` | **NON** | **NON** | **NON** | **NON** | **NON** |
| `utm_source` | OUI (T8.11AK) | OUI (attribution.ts) | OUI (signup_attribution) | OUI (checkout metadata) | OUI |
| `utm_medium` | OUI | OUI | OUI | OUI | OUI |
| `utm_campaign` | OUI | OUI | OUI | OUI | OUI |
| `utm_term` | OUI | OUI | OUI | NON | OUI |
| `utm_content` | OUI | OUI | OUI | NON | OUI |
| `marketing_owner_tenant_id` | OUI (T8.11AK) | OUI (attribution.ts) | OUI (tenants.marketing_owner_tenant_id) | NON direct | OUI (owner-aware routing) |
| `gclid/fbclid/ttclid/li_fat_id` | OUI | OUI | OUI | OUI (partiel) | OUI |

### 7.3 Actions necessaires

1. **Website** : ajouter `promo` au forwarding `/pricing` -> `/register`
2. **Client** : capturer `promo` dans `attribution.ts`, le transmettre dans `create-signup` body et `checkout-session` body
3. **API** : accepter `promo` dans le body checkout-session, le passer comme `discounts[0].promotion_code` (resolution Stripe) OU le stocker dans `signup_attribution`
4. **Stripe metadata** : ajouter `promo_code` aux metadata de session
5. **DB** : stocker `promo_code` dans `signup_attribution` pour reporting

---

## 8. ARCHITECTURE ADMIN RECOMMANDEE

### 8.1 Emplacement

| Emplacement | Avantages | Inconvenients | Reco |
|---|---|---|---|
| `/billing/promo-codes` | Proximite billing, coherence | Surcharge page billing | **Moyen** |
| `/marketing/promo-codes` | Separation marketing, coherence Campaign QA | Nouvelle section | **RECOMMANDE** |

**Recommandation : `/marketing/promo-codes`** — coherent avec le Campaign QA URL Builder existant.

### 8.2 Fonctions minimales

1. Liste des codes avec statut, usage, type
2. Creer code (type, discount, duree, produits, max, expiration)
3. Generer lien promo avec UTMs et `marketing_owner_tenant_id`
4. Copier lien
5. Voir usage (vues, signups, checkouts, tenants crees, montant Stripe reel)
6. Desactiver / archiver code
7. Audit log

### 8.3 Modele de champs

| Champ | Type | Obligatoire | Source verite | Notes |
|---|---|---|---|---|
| `id` | UUID | OUI | KeyBuzz DB | Cle primaire |
| `code` | string | OUI | Stripe promotion_code.code | Affiche a l'utilisateur |
| `label` | string | OUI | KeyBuzz DB | Nom interne (ex: "Concours TikTok 2026") |
| `campaign` | string | NON | KeyBuzz DB | Lien avec utm_campaign |
| `type` | enum | OUI | KeyBuzz DB | concours, agence, vip, campagne |
| `stripe_coupon_id` | string | OUI | Stripe | Coupon sous-jacent |
| `stripe_promotion_code_id` | string | OUI | Stripe | Promotion Code Stripe |
| `discount_type` | enum | OUI | Stripe | percent_off, amount_off |
| `discount_value` | numeric | OUI | Stripe | Montant ou pourcentage |
| `currency` | string | Si amount_off | Stripe | EUR |
| `duration` | enum | OUI | Stripe | once, repeating, forever |
| `duration_in_months` | int | Si repeating | Stripe | Ex: 12 |
| `applies_to_products` | string[] | OUI | Stripe | Product IDs plans uniquement |
| `max_redemptions` | int | NON | Stripe | Ex: 1 pour concours |
| `expires_at` | timestamp | NON | Stripe | Date expiration |
| `owner_tenant_id` | string | NON | KeyBuzz DB | marketing_owner_tenant_id |
| `created_by` | string | OUI | KeyBuzz DB | Email admin createur |
| `active` | boolean | OUI | Les deux | Synchronise avec Stripe |
| `archived_at` | timestamp | NON | KeyBuzz DB | Archivage logique |

---

## 9. DB / STRIPE / WEBHOOK DESIGN

### 9.1 Strategie recommandee

**Stripe = source financiere. KeyBuzz DB = source marketing/attribution/audit.**

La DB KeyBuzz ne doit JAMAIS etre la source du montant final facture. Elle stocke :
- Le code promo et ses metadonnees marketing
- Le lien avec `signup_attribution`
- Le snapshot de l'usage (via Stripe API en lecture)

### 9.2 Diagramme de flux

```
Admin creates promo (Admin UI)
  -> API cree coupon Stripe (stripe.coupons.create)
  -> API cree promotion_code Stripe (stripe.promotionCodes.create)
  -> API cree record promo_codes dans KeyBuzz DB
  -> Admin genere lien promo (URL avec ?promo=CODE + UTMs)

User clique lien promo
  -> Website /pricing recoit ?promo=CODE
  -> Website forward promo vers /register?promo=CODE + UTMs
  -> Client /register capture promo dans attribution
  -> Client envoie promo dans create-signup body
  -> API stocke promo dans signup_attribution
  -> Client demande checkout-session avec promo
  -> API passe discounts[0].promotion_code au Stripe Checkout
       (OU laisse allow_promotion_codes pour saisie manuelle)
  -> Stripe Checkout affiche le discount applique
  -> User confirme paiement (ou trial)

Stripe webhook checkout.session.completed
  -> handleCheckoutCompleted : upsert billing_subscriptions
  -> emit StartTrial (amount = 0 si trial)
  -> emit GA4 MP conversion (value = session.amount_total = REEL Stripe)

Stripe webhook subscription.updated (trialing -> active)
  -> handleSubscriptionUpdated : emit Purchase
  -> value = somme items * qty / 100 (REEL Stripe, apres coupon)

Outbound conversions -> Meta CAPI, TikTok, LinkedIn, GA4
  -> value = montant REEL Stripe (jamais estime)
```

### 9.3 Tables DB

**Table `promo_codes`** (nouvelle) :

```sql
CREATE TABLE promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) NOT NULL,
  label VARCHAR(200) NOT NULL,
  campaign VARCHAR(200),
  type VARCHAR(50) NOT NULL, -- concours, agence, vip, campagne
  stripe_coupon_id VARCHAR(100) NOT NULL,
  stripe_promotion_code_id VARCHAR(100) NOT NULL,
  discount_type VARCHAR(20) NOT NULL, -- percent_off, amount_off
  discount_value NUMERIC(12,2) NOT NULL,
  currency VARCHAR(3),
  duration VARCHAR(20) NOT NULL, -- once, repeating, forever
  duration_in_months INT,
  applies_to_products TEXT[],
  max_redemptions INT,
  expires_at TIMESTAMPTZ,
  owner_tenant_id VARCHAR(100),
  created_by VARCHAR(200) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Colonne `signup_attribution`** (ajout) :

```sql
ALTER TABLE signup_attribution ADD COLUMN promo_code VARCHAR(50);
```

---

## 10. RISQUES ET STOP CONDITIONS

| Risque | Severite | Mitigation |
|---|---|---|
| Coupon `duration=once` consomme sur invoice trial 0 | **CRITIQUE** | Utiliser `duration=repeating` avec `duration_in_months` |
| Discount applique aux addons (Agent KB, channels) | **HAUTE** | `applies_to.products` limite aux plan products |
| Discount applique aux KBActions | **NULLE** | KBActions = `mode: payment`, pas de `allow_promotion_codes` |
| Discount perdu lors upgrade plan | **MOYENNE** | Stripe preserve les discounts sur `subscriptions.update` — a verifier en TEST |
| Discount stacke avec un autre code | **FAIBLE** | Stripe Checkout supporte max 1 coupon/promotion_code |
| User reutilise le code | **FAIBLE** | `max_redemptions: 1` sur le promotion_code |
| Code public partage | **MOYENNE** | `max_redemptions` + `first_time_transaction` + `expires_at` |
| Attribution perdue entre Website et Stripe | **MOYENNE** | `promo` doit etre ajoute au forwarding chain (Website -> Client -> API -> Stripe metadata) |
| Valeur conversion fausse | **NULLE** | Valeur vient de Stripe reel (deja implemente PH-T8.4.1) |
| Admin cree coupon LIVE par erreur | **HAUTE** | Separation Stripe TEST / LIVE ; confirmation obligatoire ; phase DEV d'abord |
| Secret Stripe expose | **HAUTE** | Jamais afficher en UI ; masquer dans logs ; secret dans K8s secrets |
| Tenant/code hardcode | **HAUTE** | Architecture data-driven, pas de code promo hardcode |
| PROD build ecrase Client tracking | **HAUTE** | Build args obligatoires (8 parametres documentes) |

---

## 11. ROADMAP PHASEE

| Phase | Objectif | Mutation | Environnement | Gate |
|---|---|---|---|---|
| **AN.1** | Stripe DEV behavior proof : creer coupons TEST, prouver trial + repeating + applies_to + upgrade | Stripe TEST only | DEV | Preuve formelle du comportement coupon/trial/upgrade |
| **AN.2** | Promo foundation API/Admin DEV : endpoints CRUD, table `promo_codes`, page Admin | Code + DB | DEV | Endpoints fonctionnels, page Admin visible |
| **AN.3** | Promo link + signup attribution DEV : Website forwarding promo, Client capture, Stripe metadata | Code | DEV | Lien promo E2E capture jusqu'a Stripe |
| **AN.4** | Contest coupon E2E DEV : code concours 1 an PRO, PRO annual, AUTOPILOT deduction, addons exclus, tracking verifie | Stripe TEST + code | DEV | Checkout complet avec valeur correcte |
| **AN.5** | PROD promotion foundation : systeme promo live, pas de coupon public | Code + DB | PROD | Admin fonctionnel, pas de coupon actif |
| **AN.6** | First controlled contest coupon PROD : creer le vrai code gagnant, envoyer lien, verifier usage | Stripe LIVE | PROD | Gagnant active son compte |

---

## 12. LINEAR TICKETS (PRETS A COPIER)

### KEY-AN1 — Promo Codes — Stripe Truth and Checkout Behavior

**Titre** : Promo Codes — Prouver le comportement Stripe coupon/trial/upgrade en DEV TEST

**Description** : Creer des coupons Stripe TEST pour prouver formellement :
- `duration=repeating` + `duration_in_months=12` n'est pas consomme sur l'invoice trial 0 EUR
- L'upgrade de PRO vers AUTOPILOT preserve le coupon actif
- `applies_to.products` exclut effectivement Agent KeyBuzz et channel addons
- La valeur `Purchase` dans les webhooks reflete le montant reel apres deduction coupon

**Criteres d'acceptation** :
- [ ] Coupon `amount_off` cree en Stripe TEST avec `repeating/12/applies_to`
- [ ] Checkout avec trial 14j : coupon non consomme sur invoice 0
- [ ] Premiere facture payante : deduction correcte
- [ ] Upgrade PRO -> AUTOPILOT : coupon preserve
- [ ] Agent KeyBuzz addon : pas de deduction
- [ ] Rapport de preuve avec screenshots/logs

**Risques** : Comportement Stripe non documente explicitement pour trial + repeating + applies_to
**Dependances** : Aucune
**Lien rapport** : `keybuzz-infra/docs/PH-SAAS-T8.12AN-PROMO-CODES-LINKS-ATTRIBUTION-AND-STRIPE-TRUTH-AUDIT-01.md`

---

### KEY-AN2 — Admin Promo Codes — Create/List/Archive/Link Generator

**Titre** : Admin — Page /marketing/promo-codes avec CRUD et generateur de liens

**Description** : Implementer la page Admin pour gerer les codes promo :
- Liste des codes avec statut, usage, type
- Creation (type, discount, duree, produits eligibles, max, expiration)
- Appel API Stripe pour creer coupon + promotion_code
- Generateur de lien promo avec UTMs et marketing_owner_tenant_id
- Desactivation/archivage

**Criteres d'acceptation** :
- [ ] Table `promo_codes` creee
- [ ] Endpoints API CRUD fonctionnels
- [ ] Page Admin fonctionnelle
- [ ] Lien promo generable et copiable
- [ ] Desactivation synchronisee avec Stripe

**Risques** : Separation Stripe TEST/LIVE ; pas de mutation LIVE accidentelle
**Dependances** : KEY-AN1 (comportement Stripe prouve)

---

### KEY-AN3 — Promo Links — Website/Client Forwarding and Signup Attribution

**Titre** : Promo Links — Forwarding Website + capture Client + Stripe metadata

**Description** : Ajouter le parametre `promo` au pipeline d'attribution :
- Website : forward `?promo=` de /pricing vers /register
- Client : capturer `promo` dans attribution.ts
- Client : transmettre `promo` dans create-signup et checkout-session
- API : passer `discounts[0].promotion_code` dans Stripe Checkout
- API : stocker `promo_code` dans signup_attribution

**Criteres d'acceptation** :
- [ ] Lien `keybuzz.pro/pricing?promo=CODE` forward vers register
- [ ] Code promo visible dans signup_attribution
- [ ] Code promo dans Stripe session metadata
- [ ] Checkout affiche le discount pre-applique

**Risques** : Regression attribution existante ; build args Client
**Dependances** : KEY-AN1, KEY-AN2

---

### KEY-AN4 — Contest Coupon — 1 Year PRO Equivalent E2E Validation

**Titre** : Concours — Validation E2E code "1 an PRO" en DEV

**Description** : Creer et valider le code concours complet :
- Coupon `amount_off` = valeur PRO annuel, `repeating/12`, `applies_to` plans only
- Promotion code `max_redemptions: 1`
- PRO annuel : gratuit (0 EUR apres trial)
- AUTOPILOT annuel : deduction valeur PRO, reste a payer
- Agent KeyBuzz : pas de deduction
- Tracking : valeur Purchase = montant reel Stripe

**Criteres d'acceptation** :
- [ ] PRO annuel avec code : 0 EUR apres trial
- [ ] AUTOPILOT annuel avec code : deduction correcte
- [ ] Agent KeyBuzz : prix plein
- [ ] KBActions : prix plein
- [ ] Purchase event : valeur correcte

**Risques** : Calcul exact du montant PRO annuel
**Dependances** : KEY-AN1, KEY-AN2, KEY-AN3

---

### KEY-AN5 — Promo Reporting — Usage, Plan Selected, Stripe Real Value

**Titre** : Reporting promo — usage, plan, valeur Stripe reelle, attribution

**Description** : Dashboard de suivi des codes promo dans l'Admin :
- Nombre de vues lien
- Nombre de signups
- Nombre de checkouts completes
- Plan choisi (PRO/AUTOPILOT)
- Montant Stripe reel
- Attribution complete (UTMs, owner)

**Criteres d'acceptation** :
- [ ] Tableau de bord par code promo
- [ ] Donnees issues de Stripe + signup_attribution
- [ ] Pas de montant invente

**Risques** : Volume de donnees ; jointures DB
**Dependances** : KEY-AN2, KEY-AN3, KEY-AN4

---

## 13. INTERDITS RESPECTES

| Interdit | Respecte |
|---|---|
| Pas de code modifie | OUI |
| Pas de build | OUI |
| Pas de deploy | OUI |
| Pas de mutation DB | OUI |
| Pas de mutation Stripe | OUI |
| Pas de coupon cree | OUI |
| Pas de fake checkout | OUI |
| Pas de fake event | OUI |
| Pas de secret expose | OUI |
| Pas de tenant hardcode | OUI |

---

## 14. VERDICT

### GO DESIGN ONLY — STRIPE DEV TEST REQUIRED

L'architecture est claire. Le point critique (coupon `duration=once` consomme sur invoice trial 0) est identifie et la mitigation (`duration=repeating` + `duration_in_months=12`) est recommandee. Ce comportement doit etre prouve formellement en Stripe TEST (phase AN.1) avant toute implementation.

**PROMO CODES AND LINKS TRUTH ESTABLISHED — STRIPE REMAINS FINANCIAL SOURCE OF TRUTH — CONTEST PRO-YEAR USE CASE MAPPED — PLAN-ONLY DISCOUNT REQUIRED — KBACTIONS/AGENT/ADDONS EXCLUDED — ATTRIBUTION PATH DEFINED — NO CODE — NO BUILD — NO DEPLOY — READY FOR STRIPE DEV BEHAVIOR PROOF**

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12AN-PROMO-CODES-LINKS-ATTRIBUTION-AND-STRIPE-TRUTH-AUDIT-01.md
```
