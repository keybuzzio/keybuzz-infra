# Briefing Agent — Webhook de conversion pour Media Buyer

## Contexte

On travaille avec un Media Buyer qui gère les campagnes pub (Meta Ads, Google Ads, TikTok Ads) pour KeyBuzz. Aujourd'hui il n'a que l'email comme donnée de conversion côté Stripe, ce qui est insuffisant pour alimenter les algorithmes d'optimisation de Facebook (CAPI).

On veut mettre en place un **webhook de conversion** qui envoie un maximum de données au moment où un utilisateur finalise son inscription + paiement, pour que le Media Buyer puisse les exploiter comme signaux de conversion (Facebook CAPI, Google Ads conversions, etc.).

## Ce qui est déjà en place

### UTM Forwarding (site vitrine → app client)

Le site vitrine (`keybuzz.pro/pricing`) forwarde automatiquement les paramètres UTM vers l'app client. Quand un visiteur arrive via une pub :

```
keybuzz.pro/pricing?utm_source=meta&utm_medium=cpc&utm_campaign=launch
```

Et clique sur un CTA, il est redirigé vers :

```
client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=launch
```

Les UTM sont donc **disponibles dans l'URL de `/register`** mais ne sont actuellement ni lus, ni stockés par l'app client.

## Parcours d'inscription actuel

```
/register (page.tsx)
  ├── Step: plan         → choix du plan (ou pré-rempli via URL)
  ├── Step: email        → saisie email (ou Google OAuth)
  ├── Step: code         → OTP 6 chiffres (sauf Google)
  ├── Step: company      → infos entreprise
  ├── Step: user         → infos utilisateur
  └── Step: checkout     → redirect vers Stripe Checkout
        └── /register/success → polling entitlement
```

### Données collectées pendant l'inscription

Voici **toutes les données saisies par le client** avant le paiement Stripe :


| Champ                | Source                            | Obligatoire |
| -------------------- | --------------------------------- | ----------- |
| `plan`               | URL param ou sélection            | Oui         |
| `cycle`              | `monthly` / `yearly`              | Oui         |
| `email`              | Saisie ou Google OAuth            | Oui         |
| `firstName`          | Formulaire step "user"            | Oui         |
| `lastName`           | Formulaire step "user"            | Oui         |
| `phone` (perso)      | Formulaire step "user"            | Non         |
| `name` (nom société) | Formulaire step "company"         | Oui         |
| `siret`              | Formulaire step "company"         | Non         |
| `street`             | Formulaire step "company"         | Non         |
| `zipCode`            | Formulaire step "company"         | Non         |
| `city`               | Formulaire step "company"         | Non         |
| `country`            | Formulaire step "company" (liste) | Oui         |
| `companyPhone`       | Formulaire step "company"         | Non         |
| `supportEmail`       | Formulaire step "company"         | Non         |
| `cguAccepted`        | Checkbox CGU                      | Oui         |


### Données UTM disponibles dans l'URL (pas encore lues)


| Champ          | Exemple                    |
| -------------- | -------------------------- |
| `utm_source`   | `meta`, `google`, `tiktok` |
| `utm_medium`   | `cpc`, `social`            |
| `utm_campaign` | `launch_q2`                |
| `utm_term`     | `support_marketplace`      |
| `utm_content`  | `video_a`                  |


## Fichiers concernés


| Fichier                                     | Rôle                                     |
| ------------------------------------------- | ---------------------------------------- |
| `app/register/page.tsx`                     | Page d'inscription (tous les steps)      |
| `app/api/auth/create-signup/route.ts`       | BFF création tenant (appel backend)      |
| `app/api/billing/checkout-session/route.ts` | BFF création session Stripe              |
| `app/register/success/page.tsx`             | Page post-paiement (polling entitlement) |


## Ce qu'on veut faire — Option B : Webhook de conversion

### Objectif

Au moment où un utilisateur **finalise son inscription** (= paiement Stripe validé, tenant actif), émettre un webhook contenant toutes les données utiles au Media Buyer.

### Données à inclure dans le webhook

```json
{
  "event": "conversion.signup_completed",
  "timestamp": "2026-04-14T19:30:00Z",
  "user": {
    "email": "jean@exemple.fr",
    "firstName": "Jean",
    "lastName": "Dupont",
    "phone": "+33612345678"
  },
  "company": {
    "name": "EcomLG SARL",
    "country": "FR",
    "city": "Paris",
    "zipCode": "75001"
  },
  "subscription": {
    "plan": "pro",
    "cycle": "monthly",
    "amount": 297,
    "currency": "EUR",
    "trialEnd": "2026-04-28T19:30:00Z"
  },
  "attribution": {
    "utm_source": "meta",
    "utm_medium": "cpc",
    "utm_campaign": "launch_q2",
    "utm_term": null,
    "utm_content": "video_a"
  }
}
```

### Architecture proposée

```
[Visiteur]
    │
    ▼
keybuzz.pro/pricing?utm_source=meta&utm_campaign=launch
    │ (clic CTA)
    ▼
client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=meta&utm_campaign=launch
    │
    │  1. Lire les UTM du query string au mount du /register
    │  2. Les stocker (sessionStorage ou state)
    │  3. Les inclure dans le payload POST /api/auth/create-signup
    │
    ▼
Backend: create-signup
    │  4. Stocker les UTM en base (table tenant ou user_attribution)
    │
    ▼
Stripe Checkout
    │  5. Passer les UTM dans metadata de la session Stripe
    │
    ▼
Stripe Webhook (payment_intent.succeeded ou checkout.session.completed)
    │  6. Récupérer metadata + données tenant/user depuis la base
    │  7. Émettre le webhook de conversion
    │
    ▼
[Endpoint Media Buyer]  →  Facebook CAPI / Google Ads / CRM
```

## Questions à trancher

1. **Où stocker les UTM côté client ?**
  - Option A : `sessionStorage` (simple, perdu si l'user ferme le tab)
  - Option B : Passer dans le body de `create-signup` (persisté en base)
  - Recommandé : **Option B** — les UTM passent dans le payload `create-signup` avec les autres données
2. **Où stocker les UTM côté backend ?**
  - Champs sur la table `tenant` (simple)
  - Table dédiée `user_attribution` (plus propre, extensible)
  - À voir avec l'agent backend
3. **Quel événement déclenche le webhook ?**
  - `checkout.session.completed` (Stripe webhook existant ?) — au premier paiement
  - Ou un événement interne backend quand `entitlement.isLocked` passe à `false`
  - Le webhook Stripe `checkout.session.completed` est le plus fiable
4. **Destination du webhook ?**
  - URL fournie par le Media Buyer (endpoint Facebook CAPI ou intermédiaire type Zapier/Make)
  - Configurable dans les settings admin ou hardcodé en env var pour commencer
5. **Faut-il aussi un événement `trial_started` distinct de `subscription_created` ?**
  - À confirmer avec le Media Buyer

## Ce qui est hors scope

- Le site vitrine (`keybuzz-website`) — déjà fait, les UTM sont forwardés
- Studio, Admin — aucun impact
- Modification de la logique Stripe existante (juste ajout de metadata)

## Résumé pour l'agent

**Mission** : Faire en sorte que quand un utilisateur s'inscrit via une pub, toutes ses données (identité, société, plan, montant, UTM) soient envoyées via webhook au Media Buyer pour l'attribution des conversions.

**Étapes techniques** :

1. Lire les UTM du query string dans `register/page.tsx`
2. Les inclure dans le payload `create-signup`
3. Les stocker en base côté backend
4. Les passer dans les `metadata` de la session Stripe Checkout
5. Au `checkout.session.completed`, émettre un webhook avec toutes les données agrégées (user + company + plan + UTM)

**Contrainte** : aucune donnée ne doit être perdue entre le clic pub et la conversion. Les UTM doivent survivre au parcours complet register → Stripe → success.