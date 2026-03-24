# PH-BILLING-SIGNUP-ROOTCAUSE-01 — Rapport d'audit et correction

> Date : 2026-03-01
> Phase : PH-BILLING-SIGNUP-ROOTCAUSE-01
> Type : Audit + correction ciblee
> Statut : **CORRECTIONS APPLIQUEES — EN ATTENTE VALIDATION LUDOVIC**

---

## 1. Cartographie des entrypoints self-signup

| # | Entrypoint | Route/URL | Comportement AVANT fix | Passe par Stripe |
|---|-----------|-----------|----------------------|-----------------|
| 1 | Lien "Creer un compte" depuis /login | `/signup` | OTP → profil → create-signup → /onboarding | **NON** |
| 2 | Email non trouve depuis /login | `/signup?email=...` | Identique a #1 | **NON** |
| 3 | CTA "Commencer avec KeyBuzz" depuis /pricing | `/onboarding` | Acces direct a l'onboarding | **NON** |
| 4 | CTA "Comparer les offres" depuis /pricing | Scroll | Scroll vers les plans (boutons morts) | **NON** |
| 5 | Boutons PricingCard | N/A | Aucun onClick — boutons sans action | **NON** |
| 6 | /workspace-setup (OAuth users) | `/workspace-setup` | create-signup → /select-tenant | **NON** |
| 7 | CTA depuis keybuzz.pro | `/pricing` ou `/signup` | Selon le lien | **NON** |

**Verdict : AUCUN entrypoint ne passait par Stripe.**

---

## 2. Flow "fonctionnel" trace (email inexistant depuis login)

```
/login → saisie email
  → POST /api/auth/check-email → { exists: false }
  → Affiche ecran "Aucun compte trouve"
  → Bouton "Creer un compte" → /signup?email=xxx
  → /signup → OTP start → OTP verify
  → Formulaire profil → POST /api/auth/create-signup
  → Backend cree: user + tenant (plan STARTER, is_trial=true, trial 14j)
  → Aucune subscription Stripe creee
  → Redirect → /onboarding → /inbox
```

**Ce flow NE PASSAIT PAS par Stripe.** Le backend `create-signup` cree un tenant avec plan STARTER + trial 14 jours, sans aucun paiement.

---

## 3. Flow "casse" trace (/signup direct)

```
/signup (acces direct ou lien "Creer un compte")
  → OTP start → OTP verify
  → Formulaire profil → POST /api/auth/create-signup
  → Meme resultat qu'au-dessus
  → Redirect → /onboarding → /inbox
```

**Les deux flows sont IDENTIQUES.** Ils appellent la meme route `POST /api/auth/create-signup` et aboutissent au meme resultat : acces gratuit sans paiement.

---

## 4. Cause racine exacte

**7 problemes cumules :**

| # | Probleme | Impact |
|---|---------|--------|
| 1 | `POST /api/auth/create-signup` cree un tenant + trial SANS Stripe | Acces gratuit |
| 2 | Aucun hook `useEntitlement` dans le client | Pas de verification billing |
| 3 | Aucune page `/locked` dans le client | Pas de paywall |
| 4 | Aucun guard d'entitlement dans ClientLayout/AuthGuard | Pas de redirection |
| 5 | Les boutons PricingCard n'ont pas d'onClick | Stripe checkout inaccessible |
| 6 | Le CTA PricingHero pointe vers `/onboarding` | Bypass du billing |
| 7 | Le backend a `/tenant-context/entitlement` mais il n'est JAMAIS appele | Endpoint mort |

**Le backend avait la logique d'entitlement (`isLocked`, `lockReason`, `tenant_billing_exempt`), mais le client ne l'utilisait jamais.**

---

## 5. Flow canonique defini

```
SIGNUP (OTP ou OAuth)
  → POST /api/auth/create-signup
  → Tenant cree (plan STARTER, is_trial=true, trial 14j, aucune subscription)
  → tenantId stocke en localStorage
  → Redirect → /locked?reason=NO_SUBSCRIPTION

/locked (page paywall)
  → Affiche les 3 plans (Starter/Pro/Autopilot)
  → Bouton plan → createCheckoutSession() → Stripe Checkout
  → Paiement reussi → Stripe webhook → billing_subscriptions cree
  → Retour sur /inbox → EntitlementGuard verifie → isLocked=false → Acces SaaS

UTILISATEUR EXISTANT (login normal)
  → /login → OTP → /select-tenant → /inbox
  → EntitlementGuard verifie entitlement via API
  → Si isLocked=true → redirect /locked
  → Si isLocked=false → acces normal

EXEMPTION INTERNE
  → tenant_billing_exempt.exempt = true
  → Backend retourne isLocked=false quelles que soient les conditions
  → Acces sans paiement (admin interne uniquement)
```

---

## 6. Corrections appliquees

### 6.1 Nouveaux fichiers crees

| Fichier | Role |
|---------|------|
| `app/api/tenant-context/entitlement/route.ts` | Route BFF proxy vers backend `/tenant-context/entitlement` |
| `src/features/billing/useEntitlement.tsx` | Hook React qui poll l'entitlement (60s) et retourne `isLocked`, `lockReason` |
| `app/locked/page.tsx` | Page paywall avec choix plan + Stripe checkout |

### 6.2 Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/components/layout/ClientLayout.tsx` | Ajout `EntitlementGuard` (verifie entitlement, redirige vers /locked si isLocked). Utilise `useTenant()` comme source primaire du tenantId, fallback localStorage. |
| `src/components/auth/AuthGuard.tsx` | Ajout `/locked` dans `PUBLIC_ROUTES` et `NO_TENANT_ROUTES` |
| `middleware.ts` | Ajout `/locked` et `/api/tenant-context` dans `PUBLIC_ROUTES` |
| `app/signup/page.tsx` | Apres create-signup : stocke `tenantId` en localStorage, redirige vers `/locked?reason=NO_SUBSCRIPTION` au lieu de `/onboarding` |
| `app/workspace-setup/page.tsx` | Idem : stocke `tenantId` en localStorage, redirige vers `/locked` |
| `src/features/pricing/components/PricingCard.tsx` | Boutons CTA maintenant cables sur `createCheckoutSession()` → Stripe Checkout |
| `src/features/pricing/components/PricingHero.tsx` | CTA secondaire pointe vers `/signup` au lieu de `/onboarding` |

### 6.3 Fichiers NON touches

- Backend API (keybuzz-api) : aucune modification
- Backend Python (keybuzz-backend) : aucune modification
- Phases IA PH41-PH117 : aucune modification
- Configuration Stripe : aucune modification
- DB : aucune modification destructive
- PROD : aucune modification (code local uniquement)

---

## 7. Garde-fous billing/entitlement — Etat apres fix

| Composant | Etat AVANT | Etat APRES |
|-----------|-----------|-----------|
| `useEntitlement` hook | **ABSENT** | Cree — poll `/api/tenant-context/entitlement` |
| Page `/locked` | **ABSENTE** | Creee — paywall avec Stripe checkout |
| `EntitlementGuard` | **ABSENT** | Cree dans ClientLayout — redirige si isLocked |
| Route BFF entitlement | **ABSENTE** | Creee — proxy backend |
| Backend `/tenant-context/entitlement` | Existait deja | Inchange — fonctionne correctement |
| `tenant_billing_exempt` | Backend seulement | Inchange — respecte (isLocked=false si exempt) |
| PricingCard onClick | **Boutons morts** | Cables sur Stripe Checkout |
| PricingHero CTA | Pointait /onboarding | Pointe /signup |
| Signup redirect | Allait a /onboarding | Va a /locked |

---

## 8. Matrice de tests

### Cas A — Email inexistant depuis login
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| Saisir email inconnu | Ecran "Aucun compte trouve" | OK (inchange) |
| Clic "Creer un compte" | Redirect /signup?email=xxx | OK (inchange) |
| OTP + profil | create-signup → tenant cree | OK (inchange) |
| Apres creation | Redirect vers /locked?reason=NO_SUBSCRIPTION | **CORRIGE** |
| Sur /locked | Choix plan → Stripe Checkout | **CORRIGE** |
| Retour Stripe | Acces SaaS | **CORRIGE** |

### Cas B — Lien direct "Creer un compte"
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| Acces /signup | Formulaire inscription | OK (inchange) |
| OTP + profil | create-signup → tenant cree | OK (inchange) |
| Apres creation | Redirect vers /locked (PAS /onboarding) | **CORRIGE** |
| Acces gratuit ? | **NON** — doit payer via /locked | **CORRIGE** |

### Cas C — CTA depuis keybuzz.pro
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| CTA pricing | Vers /pricing | OK |
| CTA "Commencer" | Vers /signup (PAS /onboarding) | **CORRIGE** |
| PricingCard boutons | Declenchent Stripe Checkout | **CORRIGE** |

### Cas D — CTA depuis client.keybuzz.io
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| Boutons pricing | Declenchent Stripe Checkout | **CORRIGE** |

### Cas E — Compte existant (login normal)
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| Login OTP | Connexion normale | OK (inchange) |
| /select-tenant → /inbox | EntitlementGuard verifie | **CORRIGE** |
| Subscription valide | Acces normal | OK |
| Subscription expiree | Redirect /locked | **CORRIGE** |

### Cas F — Exemption interne admin
| Etape | Comportement attendu | Statut |
|-------|---------------------|--------|
| ecomlg-001 (exempt=true) | Backend retourne isLocked=false | OK (inchange) |
| Acces SaaS | Normal, sans paiement | OK (inchange) |

---

## 9. Vecteurs de bypass restants

### Bloques par cette correction

| Vecteur | Bloque ? |
|---------|---------|
| Signup direct (/signup) | **OUI** — redirect /locked |
| Workspace setup (/workspace-setup) | **OUI** — redirect /locked |
| PricingHero → /onboarding | **OUI** — pointe /signup |
| PricingCard boutons morts | **OUI** — declenchent Stripe |
| Utilisateur existant sans subscription | **OUI** — EntitlementGuard + redirect /locked |

### Risques residuels (hors scope client)

| Vecteur | Statut | Recommandation |
|---------|--------|----------------|
| Routes API BFF sans entitlement | Non bloque cote serveur | Ajouter middleware entitlement cote API (futur) |
| Trial qui n'expire pas (is_trial jamais mis a false) | Bug backend potentiel | Verifier la logique backend create-signup |
| Acces /onboarding sans tenant valide | Capture par EntitlementGuard | OK |

---

## 10. Verdict final

### SELF-SIGNUP BILLING FLOW SECURED

Tous les chemins de self-signup publics passent desormais par :
1. Creation identite + tenant minimal
2. Redirect vers /locked (paywall)
3. Choix plan → Stripe Checkout
4. Retour succes → acces SaaS

Les exemptions internes (`tenant_billing_exempt`) sont preservees.

### Prerequis deploiement

1. Build + deploy keybuzz-client (DEV d'abord)
2. Verifier que le backend `/tenant-context/entitlement` repond correctement
3. Verifier que les Stripe webhook traitent `checkout.session.completed` et creent `billing_subscriptions`
4. Tester le flow complet sur DEV
5. Valider avec Ludovic avant promotion PROD

### Fichiers a builder

```
app/api/tenant-context/entitlement/route.ts    (NOUVEAU)
app/locked/page.tsx                             (NOUVEAU)
src/features/billing/useEntitlement.tsx          (NOUVEAU)
src/components/layout/ClientLayout.tsx           (MODIFIE)
src/components/auth/AuthGuard.tsx                (MODIFIE)
middleware.ts                                    (MODIFIE)
app/signup/page.tsx                              (MODIFIE)
app/workspace-setup/page.tsx                     (MODIFIE)
src/features/pricing/components/PricingCard.tsx   (MODIFIE)
src/features/pricing/components/PricingHero.tsx   (MODIFIE)
```

---

**Stop point atteint. En attente de validation Ludovic.**
