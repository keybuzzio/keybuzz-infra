# PH-BILLING-SIGNUP-FIX-REDIRECT — Rapport Final

> Date : 20 mars 2026
> Auteur : Agent Cursor (CE)
> Phase : PH-BILLING-SIGNUP-FIX-REDIRECT
> Statut : **DEPLOYE DEV + PROD**

---

## 1. Probleme

Le flow `/signup` bypassait Stripe — il creait un tenant et permettait un acces gratuit au SaaS sans paiement.

Le flow `/register` (page existante sur le bastion depuis PH33.10) fonctionne correctement :
- Selection du plan
- Authentification OTP + OAuth
- Saisie infos societe + utilisateur
- Redirection vers Stripe Checkout
- Page de succes post-paiement

## 2. Cause racine

La page `/signup` (`app/signup/page.tsx`) faisait un appel direct a `/api/auth/create-signup` qui creait un tenant sans exiger de paiement Stripe. Tous les CTA (login, pricing) pointaient vers `/signup` au lieu de `/register`.

## 3. Corrections appliquees

### Fichiers modifies (7 fichiers)

| Fichier | Modification |
|---------|-------------|
| `app/signup/page.tsx` | Remplace par un redirect simple vers `/register` (preserve les query params) |
| `app/login/page.tsx` | L214 : `/signup?email=...` → `/register?email=...`; L372 : href `/signup` → `/register` |
| `src/features/pricing/components/PricingHero.tsx` | L61 : href `/signup` → `/register` |
| `middleware.ts` | Ajoute `/register` dans `PUBLIC_ROUTES` |
| `src/components/auth/AuthGuard.tsx` | Ajoute `/register` et `/signup` dans `PUBLIC_ROUTES` |
| `src/components/layout/ClientLayout.tsx` | Ajoute `/register` et `/signup` dans `PUBLIC_ROUTES` + `/register` dans `ENTITLEMENT_EXEMPT_ROUTES` ; simplifie `EntitlementGuard` (0 args) |
| `src/features/billing/useEntitlement.tsx` | Aligne avec la version bastion (0 args, utilise `useTenant()` en interne) |

### Fichiers copies depuis le bastion (3 fichiers — deja existants)

| Fichier | Description |
|---------|-------------|
| `app/register/page.tsx` | Page d'inscription multi-etapes avec Stripe Checkout |
| `app/register/LegalModal.tsx` | Modal CGU + Politique de confidentialite |
| `app/register/success/page.tsx` | Page de succes post-paiement Stripe |

### Manifests GitOps mis a jour

| Fichier | Ancienne image | Nouvelle image |
|---------|---------------|----------------|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.59-channels-stripe-sync-dev` | `v3.5.60-signup-fix-dev` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.58-channels-billing-prod` | `v3.5.60-signup-fix-prod` |

## 4. Flow canonique apres correction

```
Utilisateur → /signup (ou CTA "Creer un compte")
  ↓ redirect client
/register
  ↓ step 1 : Choix du plan (Starter / Pro / Autopilot)
  ↓ step 2 : Email + OTP
  ↓ step 3 : Info societe (SIRET, adresse, pays)
  ↓ step 4 : Info utilisateur (prenom, nom, CGU)
  ↓ step 5 : POST /api/auth/create-signup → creation tenant
  ↓ step 6 : POST /api/billing/checkout-session → Stripe Checkout
  ↓ paiement Stripe
/register/success → /dashboard
```

## 5. Resultats de validation

### DEV (client-dev.keybuzz.io)

| Test | Resultat |
|------|----------|
| `/signup` redirige vers `/register` | **PASS** |
| `/signup?email=test@example.com` preserve les params | **PASS** |
| Lien "Creer un compte" sur `/login` → `/register` | **PASS** |
| Page `/register` avec plans + toggle | **PASS** |

### PROD (client.keybuzz.io)

| Test | Resultat |
|------|----------|
| `/signup` redirige vers `/register` | **PASS** |
| Page `/register` avec plans + Stripe | **PASS** |
| Lien "Creer un compte" → `/register` | **PASS** |

## 6. Versions deployees

| Env | Image | Pod | Status |
|-----|-------|-----|--------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.60-signup-fix-dev` | keybuzz-client-5484c6794c-* | 1/1 Running |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.60-signup-fix-prod` | keybuzz-client-785cb4f797-* | 1/1 Running |

## 7. Rollback

En cas de probleme, rollback client uniquement :

```bash
# DEV
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.58-channels-billing-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

> Puis reverter les manifests `deployment.yaml` dans keybuzz-infra et git push.

## 8. Note ArgoCD PROD

ArgoCD PROD a un sync bloque (erreur pre-existante : `ExternalSecret v1beta1` vs `v1`). Le deploiement PROD a ete fait via `kubectl set image`. Le manifest Git est a jour — le deploiement sera coherent une fois l'erreur ExternalSecret corrigee.

## 9. Perimetre — ce qui n'a PAS ete touche

- Backend (API Fastify) : aucune modification
- Stripe configuration : aucune modification
- Onboarding wizard : aucune modification
- Base de donnees : aucune modification
- Flows existants fonctionnels : preserves
