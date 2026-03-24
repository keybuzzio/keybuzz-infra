# PH-PROD-LAST-KNOWN-GOOD-RESTORE — Rapport

> Date : 2026-03-20
> Mode : AUDIT + RESTORE SAFE
> Environnement : PROD uniquement
> Verdict : **PROD RESTORED**

---

## 1. Timeline des versions PROD client

| Ordre | Image | Focus mode default | Paywall /locked | Routes | Observations |
|---|---|---|---|---|---|
| 1 | `v3.4.0-ph3311g-prod-1` | **OFF** | NON | 40 | PH33.11g — "focus off default" explicite |
| 2 | `v3.5.48-white-bg-prod` | **OFF** | OUI | 47 | Fond blanc, paywall ajoute |
| 3 | `v3.5.54-channels-safety-prod` | **OFF** | OUI | ~47 | Channels safety |
| 4 | `v3.5.57-channels-fix-prod` | **OFF** | OUI | ~47 | Channels fix accents FR |
| 5 | **`v3.5.58-channels-billing-prod`** | **OFF** | **OUI** | **47** | **LAST KNOWN GOOD** |
| 6 | `v3.5.59-channels-stripe-sync-prod` | **ON** ← regression | OUI | 48 | Stripe sync + ai-dashboard (PH117) |

### Preuve technique de la regression

**v3.5.58** (sain) — code minifie dans le bundle layout :
```
null!==t&&"true"===t
```
→ Retourne `false` si localStorage vide. Focus mode OFF par defaut.

**v3.5.59** (casse) — code minifie dans le bundle layout :
```
null===t||"true"===t
```
→ Retourne `true` si localStorage vide. Focus mode ON par defaut.

La regression a ete introduite dans le build `v3.5.59-channels-stripe-sync` en modifiant la logique `getFocusMode()` dans `ClientLayout.tsx` sur le bastion.

---

## 2. Version saine identifiee

**`v3.5.58-channels-billing-prod`**

| Critere | Resultat |
|---|---|
| Focus mode OFF par defaut | ✅ Prouve par analyse bundle |
| Page `/locked` (paywall) | ✅ Presente |
| Page `/onboarding` | ✅ Presente |
| Page `/signup` | ✅ Presente |
| Page `/pricing` | ✅ Presente |
| Routes totales | 47 (toutes essentielles) |
| API URLs | `api.keybuzz.io` uniquement (0 refs `api-dev`) |
| Image GHCR | ✅ Presente (`sha256:...`) |
| Digest | `sha256:...` (verifiable) |

---

## 3. Diagnostic paiement/onboarding

### Le paiement est-il correctement gere ?

**OUI.** Le systeme de paywall fonctionne :

| Composant | Statut | Preuve |
|---|---|---|
| Page `/locked` | Presente | Fichiers SSR confirmes |
| `useEntitlement()` hook | Actif | Bundle minifie contient `isLocked`, `lockReason`, polling |
| Raisons de blocage | 4 cas | TRIAL_EXPIRED, PAST_DUE, CANCELED, NO_SUBSCRIPTION |
| Redirect Stripe | Actif | Bouton "Souscrire un abonnement" → `/billing/plan` |
| Tenant ecomlg-001 | Exempt | `tenant_billing_exempt` reason=`internal_admin` |

### L'onboarding est-il fonctionnel ?

**OUI.** Apres le restore :
- Route `/onboarding` presente
- Route `/start` presente (item nav "Demarrage")
- Item "Demarrage" visible dans le menu (focus mode OFF = tous les items affiches)
- `OnboardingBanner` actif si `!state.completed`

### Y a-t-il un bypass paiement ?

**NON pour les vrais utilisateurs.** Le flux est :
1. Signup → creation tenant (plan free, trial 14j)
2. Entitlement check automatique via `useEntitlement()`
3. Si trial expire sans souscription → `isLocked = true` → redirect `/locked`
4. Seul `tenant_billing_exempt` bypasse (usage admin interne)

---

## 4. Restore applique

### Choix : CAS A — Rollback client seul

L'API PROD (`v3.6.17-ph115-real-execution-prod`) n'a pas ete modifiee. Le probleme etait 100% client-side.

### Images avant/apres

| Composant | Avant | Apres |
|---|---|---|
| Client PROD | `v3.5.59-channels-stripe-sync-prod` | **`v3.5.58-channels-billing-prod`** |
| API PROD | `v3.6.17-ph115-real-execution-prod` | `v3.6.17-ph115-real-execution-prod` (inchange) |

### GitOps

- Commit : `9b63229` → `18185a5` (apres rebase)
- Message : `RESTORE PROD client to v3.5.58-channels-billing-prod (last known good, focus mode OFF)`
- Push : `origin/main` OK
- kubectl apply : OK
- Rollout : `deployment "keybuzz-client" successfully rolled out` (14s)

---

## 5. Tests onboarding

| Test | Resultat |
|---|---|
| Route `/onboarding` presente dans bundle | ✅ |
| Route `/start` presente dans bundle | ✅ |
| Item "Demarrage" visible dans le menu | ✅ (focus mode OFF) |
| Redirect vers login si non authentifie | ✅ (callbackUrl preserve) |
| OnboardingBanner composant | ✅ Present dans le bundle |

---

## 6. Tests paiement

| Test | Resultat |
|---|---|
| Page `/locked` presente | ✅ |
| `useEntitlement()` actif | ✅ |
| 4 cas de blocage geres | ✅ TRIAL_EXPIRED, PAST_DUE, CANCELED, NO_SUBSCRIPTION |
| Bouton "Souscrire" → `/billing/plan` | ✅ |
| `/billing/current` API → 200 | ✅ plan PRO, status active |
| Tenant exempt fonctionne | ✅ ecomlg-001, reason=internal_admin |

---

## 7. Tests navigation

| Page | Resultat |
|---|---|
| `/login` | ✅ OK — OTP + Google + Microsoft + lien signup |
| `/signup` | ✅ OK — formulaire + OAuth + lien login |
| `/pricing` | ✅ OK — 4 plans, FAQ, CTA |
| `/onboarding` | ✅ OK — redirect login si non auth |
| Menu complet | ✅ 11 items visibles (focus OFF) |
| Mode Focus toggle | ✅ Visible en bas de sidebar |
| Burger mobile | ✅ lg:hidden present dans bundle |

---

## 8. Tests API / IA

| Endpoint | Resultat |
|---|---|
| `/health` | ✅ 200 |
| `/ai/governance` | ✅ 200 |
| `/ai/quality-score` | 400 (param manquant, non bloquant) |
| `/ai/self-improvement` | ✅ 200 |
| `/ai/knowledge-graph` | ✅ 200 |
| `/ai/long-term-memory` | ✅ 200 |
| `/ai/strategic-resolution` | ✅ 200 |
| `/ai/autonomous-ops` | ✅ 200 |
| `/ai/action-dispatcher` | ✅ 200 |
| `/ai/connector-abstraction` | ✅ 200 |
| `/ai/case-manager` | ✅ 200 |
| `/ai/controlled-execution` | ✅ 200 |
| `/ai/controlled-activation` | ✅ 200 |
| **POST `/ai/assist`** | ✅ 200 — **1 suggestion, 45 couches decisionContext** |

---

## 9. Ce qui est perdu avec le rollback

Le passage de v3.5.59 a v3.5.58 retire :
1. **Stripe channels sync** — synchronisation automatique des canaux avec Stripe
2. **Route `/ai-dashboard`** — page PH117 (dashboard IA client-facing)

Ces fonctionnalites pourront etre restaurees dans un futur build corrige.

---

## 10. Verdict final

### **PROD RESTORED**

| Critere | Statut |
|---|---|
| Focus mode OFF par defaut | ✅ |
| Menu complet visible | ✅ |
| Onboarding accessible | ✅ |
| Paywall fonctionnel | ✅ |
| API saine | ✅ |
| Pipeline IA intact (45 couches) | ✅ |
| Aucun bypass paiement | ✅ |
| Rollback reversible | ✅ (`v3.5.59-channels-stripe-sync-prod`) |

### Cause racine de la casse

La regression focus mode a ete introduite dans le build `v3.5.59-channels-stripe-sync` par une modification de la fonction `getFocusMode()` dans `ClientLayout.tsx` sur le bastion. La logique a ete inversee de :
- `null!==stored && "true"===stored` (retourne `false` si pas de valeur = OFF par defaut)
- A : `null===stored || "true"===stored` (retourne `true` si pas de valeur = ON par defaut)

### Recommandation pour futur build

Avant tout nouveau build client :
1. Verifier que `getFocusMode()` retourne `false` quand localStorage est vide
2. Verifier que `/locked`, `/onboarding`, `/start` sont dans le bundle
3. Verifier les API URLs (PROD = `api.keybuzz.io`, DEV = `api-dev.keybuzz.io`)

---

## 11. Rollback de securite

Pour revenir a l'etat precedent si necessaire :

```
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod -n keybuzz-client-prod
```
