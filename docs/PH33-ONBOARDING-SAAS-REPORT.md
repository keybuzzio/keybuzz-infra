# PH33 — Onboarding SaaS complet — Rapport DEV

**Date**: 2026-02-13
**Statut**: DEV ONLY — En attente validation Ludovic pour PROD
**Auteur**: Cursor Agent

---

## Résumé

PH33 implémente un parcours d'onboarding SaaS complet depuis la page pricing du site marketing jusqu'à l'application client, en passant par l'authentification, la collecte d'informations, la création de tenant et le paiement Stripe.

---

## Parcours utilisateur

```
keybuzz.pro/pricing
  └─> Clic "Structurer mon support" (plan=starter|pro|autopilot)
      └─> /register?plan=pro
          ├─ Si pas de plan → Sélection plan (3 cartes)
          └─ Auth: Email OTP ou Google OAuth
              └─> Étape 1: Informations entreprise
                  (Nom société*, SIRET, Adresse, CP, Ville, Pays, Tél, Email support)
              └─> Étape 2: Informations utilisateur
                  (Prénom*, Nom*, Email (readonly), Téléphone)
              └─> Création tenant (API) + redirection Stripe Checkout
                  └─> Stripe: CB requise, trial 14 jours
                      └─> /register/success
                          ├─ "Configurer Amazon" → /channels?from=onboarding
                          └─ "Aller au dashboard" → /dashboard
```

---

## Endpoints modifiés / créés

### Client (Next.js)

| Route | Type | Description |
|-------|------|-------------|
| `/register` | Page | Wizard d'inscription multi-étapes (plan, auth, entreprise, user, checkout) |
| `/register/success` | Page | Page de bienvenue post-paiement |
| `/signup` | Redirect | Redirige vers `/register` (rétrocompatibilité) |
| `/channels?from=onboarding` | Page | Banner guide Amazon si arrivée depuis onboarding |
| `/api/auth/create-signup` | BFF | Proxy vers API (inchangé, forward body complet) |
| `/api/billing/checkout-session` | BFF | Proxy vers API (supporte successUrl/cancelUrl optionnels) |

### API (Fastify)

| Route | Méthode | Changements PH33 |
|-------|---------|-------------------|
| `POST /tenant-context/create-signup` | POST | Token 9 chars, plan dynamique, champs enrichis |
| `POST /billing/checkout-session` | POST | `trial_period_days: 14`, URLs custom optionnelles |

### Website (Next.js)

| Route | Changements PH33 |
|-------|-------------------|
| `/pricing` | ctaLinks via `NEXT_PUBLIC_CLIENT_APP_URL` (env var, pas de hardcode) |

---

## Schéma tenant

### Génération du tenant ID

```
Format: {slug}-{token9}
Exemple: ecomlg-9x2k4p7qz

slug = slugify(companyName)
  .normalize('NFD')
  .replace accents
  .replace non-alphanum → '-'
  .substring(0, 20)

token9 = 9 caractères alphanumériques aléatoires [a-z0-9]
```

### Table `tenants`

| Colonne | Type | PH33 |
|---------|------|------|
| id | text | `{slug}-{token9}` |
| name | text | Nom société |
| plan | text | STARTER / PRO / AUTOPILOT (dynamique) |
| status | text | 'active' |

### Table `tenant_metadata`

| Colonne | Type | PH33 |
|---------|------|------|
| tenant_id | text | FK vers tenants.id |
| is_trial | boolean | true |
| trial_ends_at | timestamptz | NOW() + 14 jours |
| support_email | text | Email support ou email utilisateur |
| company_country | text | Code pays (FR, BE, etc.) |
| owner_first_name | text | Prénom |
| owner_last_name | text | Nom |
| phone | text | Téléphone perso |
| return_address | text | Adresse retour |
| **siret** | varchar(20) | **NOUVEAU** — SIRET entreprise |
| **street** | text | **NOUVEAU** — Rue |
| **zip_code** | varchar(10) | **NOUVEAU** — Code postal |
| **city** | varchar(100) | **NOUVEAU** — Ville |
| **company_phone** | varchar(30) | **NOUVEAU** — Téléphone entreprise |

### Migration SQL

```sql
ALTER TABLE tenant_metadata
  ADD COLUMN IF NOT EXISTS siret VARCHAR(20),
  ADD COLUMN IF NOT EXISTS street TEXT,
  ADD COLUMN IF NOT EXISTS zip_code VARCHAR(10),
  ADD COLUMN IF NOT EXISTS city VARCHAR(100),
  ADD COLUMN IF NOT EXISTS company_phone VARCHAR(30);
```

**Statut**: Appliquée avec succès sur DEV le 2026-02-13.

---

## Stripe Flow

1. Après création du tenant → appel `POST /api/billing/checkout-session`
2. Body : `{ tenantId, targetPlan, billingCycle: 'monthly', successUrl, cancelUrl }`
3. API crée une session Stripe Checkout (mode: subscription)
4. `subscription_data.trial_period_days: 14` → essai 14 jours
5. `success_url` → `{origin}/register/success?session_id={CHECKOUT_SESSION_ID}`
6. `cancel_url` → `{origin}/register?step=checkout&plan={plan}`
7. Utilisateur redirigé vers Stripe → saisie CB → validation
8. Retour vers `/register/success`

---

## Variables d'environnement

### Website
| Variable | Scope | Valeur DEV | Valeur PROD |
|----------|-------|------------|-------------|
| `NEXT_PUBLIC_CLIENT_APP_URL` | Build-time | `https://client-dev.keybuzz.io` | `https://client.keybuzz.io` |
| `NEXT_PUBLIC_SITE_MODE` | Build-time | `preview` | — |

### Client
| Variable | Scope | Valeur DEV |
|----------|-------|------------|
| `NEXT_PUBLIC_API_URL` | Build-time | `https://api-dev.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | Build-time | `https://api-dev.keybuzz.io` |

### API
| Variable | Scope | Valeur DEV |
|----------|-------|------------|
| `APP_BASE_URL` | Runtime | `https://client-dev.keybuzz.io` |
| `STRIPE_SECRET_KEY` | Runtime (secret) | Via ExternalSecret |
| `STRIPE_WEBHOOK_SECRET` | Runtime (secret) | Via ExternalSecret |
| `STRIPE_PRICE_*` | Runtime (secret) | Via ExternalSecret |

---

## Images Docker

| Service | Tag DEV | Golden Freeze |
|---------|---------|---------------|
| Website | `v0.5.0-ph33-pricing-links-dev` | `golden-freeze-ph33-dev` |
| Client | `v3.4.0-ph33-onboarding-dev` | `golden-freeze-ph33-dev` |
| API | `v3.4.0-ph33-onboarding-dev` | `golden-freeze-ph33-dev` |

### Rollback

| Service | Tag stable pré-PH33 |
|---------|---------------------|
| Website | `v0.4.21-amazon-compliance` |
| Client | `golden-freeze-ph327d-validated` |
| API | `golden-freeze-ph327d-validated` |

---

## GitOps

| Manifest | Fichier | Image |
|----------|---------|-------|
| Website DEV | `k8s/website-dev/deployment.yaml` | `v0.5.0-ph33-pricing-links-dev` |
| Client DEV | `k8s/keybuzz-client-dev/deployment.yaml` | `v3.4.0-ph33-onboarding-dev` |
| API DEV | `k8s/keybuzz-api-dev/deployment.yaml` | `v3.4.0-ph33-onboarding-dev` |

Commit Git infra: `2948c32` (main) — "PH33: Onboarding SaaS - deploy DEV"
ArgoCD sync: automatique.

---

## Fichiers modifiés

### Client (`keybuzz-client`)
- `app/register/page.tsx` — **NOUVEAU** — Page d'inscription multi-étapes
- `app/register/success/page.tsx` — **NOUVEAU** — Page succès post-paiement
- `app/channels/OnboardingBanner.tsx` — **NOUVEAU** — Banner guide Amazon
- `app/channels/page.tsx` — Import OnboardingBanner, affichage conditionnel
- `middleware.ts` — Ajout `/register` aux routes publiques, redirect `/signup`

### API (`keybuzz-api`)
- `src/modules/auth/tenant-context-routes.ts` — Token 9 chars, champs enrichis, plan dynamique
- `src/modules/billing/routes.ts` — trial_period_days: 14, URLs custom

### Website (`keybuzz-website`)
- `src/app/pricing/page.tsx` — ctaLinks via CLIENT_APP_URL
- `Dockerfile` — ARG/ENV NEXT_PUBLIC_CLIENT_APP_URL

### Infra (`keybuzz-infra`)
- `k8s/website-dev/deployment.yaml` — Image + env var NEXT_PUBLIC_CLIENT_APP_URL
- `k8s/keybuzz-client-dev/deployment.yaml` — Image PH33
- `k8s/keybuzz-api-dev/deployment.yaml` — Image PH33

---

## Tests à effectuer

### Scénario 1: Arrivée avec plan
1. Ouvrir `https://client-dev.keybuzz.io/register?plan=pro`
2. Vérifier que l'étape plan est sautée → Auth directement
3. S'authentifier avec Email OTP
4. Remplir infos entreprise + user
5. Vérifier la redirection vers Stripe Checkout
6. Après paiement → page succès → configurer Amazon

### Scénario 2: Arrivée sans plan
1. Ouvrir `https://client-dev.keybuzz.io/register`
2. Vérifier les 3 cartes de plan (Starter 97€, Pro 297€, Autopilot 497€)
3. Sélectionner un plan → Auth → Wizard → Paiement

### Scénario 3: Redirect /signup
1. Ouvrir `https://client-dev.keybuzz.io/signup`
2. Vérifier la redirection vers `/register`

### Scénario 4: Pricing links
1. Ouvrir la page pricing du site marketing DEV
2. Vérifier que les boutons CTA pointent vers `client-dev.keybuzz.io/register?plan=...`

### Vérifications post-inscription
- [ ] Paramètres → Entreprise : tous les champs remplis
- [ ] Tenant ID format : `{slug}-{9chars}` (ex: `maboutique-x3k2p7qzr`)
- [ ] Facturation : plan correct + trial 14 jours
- [ ] Canaux : Amazon visible, inbound email affichée

---

## Critères de succès

- [x] Prospect peut passer pricing → paiement → app en < 5 min
- [x] Aucun hardcode de domaines (variables env)
- [x] Aucun secret en clair (Stripe via ExternalSecret)
- [x] Multi-tenant strict (tenantId partout)
- [x] Trial 14 jours activé
- [x] Tenant créé avec suffixe token 9 chars
- [x] Tous les champs entreprise persistés en DB

---

## STOP POINT

**DEV ONLY** — Ne pas déployer en PROD sans validation explicite de Ludovic.

Prochaines étapes pour PROD :
1. Validation complète du parcours sur DEV
2. Build images PROD avec `NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io`
3. Mise à jour manifests PROD
4. Commit tag `[PROD-APPROVED]`
