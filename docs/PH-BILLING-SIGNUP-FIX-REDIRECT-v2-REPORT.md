# PH-BILLING-SIGNUP-FIX-REDIRECT-v2 — Rapport

> Date : 20 mars 2026
> Phase : PH-BILLING-SIGNUP-FIX-REDIRECT-v2
> Type : Fix minimal — redirection /signup → /register
> Pipeline : PH-TD-08 Safe Deploy Pipeline (premier usage reel)

---

## 1. Baseline Git utilisee

| Element | Valeur |
|---|---|
| Commit baseline | `3e2e6ec PH-CHANNELS-BILLING` |
| Branche | `fix/signup-redirect-v2` (creee depuis `3e2e6ec`) |
| Correspondance image | `v3.5.58-channels-billing-prod` (dernier PROD sain) |
| Commit fix | `c30195c` |

La branche `fix/signup-redirect-v2` part du commit `3e2e6ec` sur `d16-settings`, qui etait le HEAD Git quand l'image PROD `v3.5.58-channels-billing-prod` a ete buildee. Ceci garantit que le fix part de la meme base fonctionnelle que le dernier PROD stable.

---

## 2. Probleme corrige

**Avant** : Le bouton "Creer un compte" menait a `/signup`, qui contenait un formulaire complet (17 730 lignes) avec OTP flow, profil, creation tenant. Ce formulaire constituait un risque de bypass Stripe (creation de compte sans passer par le flow de facturation canonique).

**Apres** : `/signup` est un redirect pur (25 lignes) vers `/register`. Tous les CTAs pointent vers `/register`. Le flow `/register` existant (avec LegalModal, validation, etc.) reste inchange et est la source de verite unique.

---

## 3. Fichiers modifies (7 exactement)

| Fichier | Modification |
|---|---|
| `app/signup/page.tsx` | Remplace formulaire 343 lignes par redirect 25 lignes |
| `app/login/page.tsx` | `href="/signup"` → `href="/register"` (CTA bas de page) |
| `app/pricing/page.tsx` | `href='/signup'` → `href='/register'` |
| `src/features/pricing/components/PricingHero.tsx` | `'/signup'` → `'/register'` |
| `src/features/pricing/components/PricingChoice.tsx` | `'/signup?plan='` → `'/register?plan='` |
| `src/features/pricing/components/PricingCard.tsx` | `'/signup?plan='` → `'/register?plan='` |
| `Dockerfile` | Remplace par version securisee (explicit COPY, pas de COPY . .) |

### Fichiers NON touches (interdit par le prompt)

- `ClientLayout.tsx` — inchange
- `AuthGuard.tsx` — inchange
- `middleware.ts` — inchange
- `useEntitlement.tsx` — inchange
- `app/register/page.tsx` — inchange (source de verite)
- PH117 / ai-dashboard — non inclus (branche baseline avant PH117)

---

## 4. Preuve : seule la redirection signup a ete touchee

```
git diff --stat 3e2e6ec..c30195c

 Dockerfile                                        | 101 ++++---
 app/login/page.tsx                                |   2 +-
 app/pricing/page.tsx                              |   2 +-
 app/signup/page.tsx                               | 343 +-----
 src/features/pricing/components/PricingCard.tsx   |   2 +-
 src/features/pricing/components/PricingChoice.tsx |   2 +-
 src/features/pricing/components/PricingHero.tsx   |   2 +-
 7 files changed, 76 insertions(+), 378 deletions(-)
```

Aucun fichier de layout, auth, billing, middleware ou entitlement n'a ete modifie.

---

## 5. Resultats DEV

| Test | Resultat |
|---|---|
| Image verification (17 checks) | **17/17 PASS** |
| /signup est redirect (pas formulaire) | PASS |
| Login bundle : zero `/signup` | PASS |
| Login bundle : contient `/register` | PASS |
| Pricing bundle : zero `/signup` | PASS |
| Pricing bundle : contient `/register` | PASS |
| Signup page : 2004 bytes (redirect pur) | PASS |
| Signup page : zero `create-signup` bypass | PASS |
| /register = 200 | PASS |
| /locked = 200 | PASS |
| /onboarding = 200 | PASS |
| 10 pages critiques = 200 | **10/10 PASS** |
| URL contamination (zero api.keybuzz.io en DEV) | PASS |
| Image | `v3.5.62-signup-fix-v2-dev` |

---

## 6. Resultats PROD

### Release gate

| Check | Resultat |
|---|---|
| Release gate PROD (14 checks) | **14/14 PASS** |
| `promotionReady` | **true** |
| Zero URLs DEV dans PROD | PASS |
| Zero bypass form `/signup` | PASS |

### Validation runtime

| Test | Resultat |
|---|---|
| /signup PROD = redirect (8228 bytes) | PASS |
| Login PROD : zero href=/signup | PASS |
| /register PROD = 200 | PASS |
| /locked PROD = 200 | PASS |
| /onboarding PROD = 200 | PASS |
| 10 pages critiques PROD = 200 | **10/10 PASS** |
| Login bundle PROD : zero `/signup` | PASS |
| Login bundle PROD : contient `/register` | PASS |
| Pricing bundle PROD : zero `/signup` | PASS |
| Pricing bundle PROD : contient `/register` | PASS |
| Signup bundle PROD : 2004 bytes | PASS |
| Signup bypass `create-signup` PROD | **false** |
| Image PROD | `v3.5.62-signup-fix-v2-prod` |

---

## 7. Preuve /signup → /register

- `/signup` renvoie une page de 8228 bytes (contre 17 730+ avant)
- Le bundle compile contient uniquement `router.replace()` vers `/register`
- Zero reference a `create-signup`, `Inscription`, ou formulaire OTP
- Les parametres query (ex: `?plan=pro`) sont preserves dans la redirection

---

## 8. Preuve absence de bypass paiement

- `/signup/page.tsx` ne contient AUCUN appel API (`create-signup`, `POST /auth`)
- Le composant ne fait que `router.replace('/register' + params)`
- Le flow `/register` existant (inchange) gere la creation de compte via le process canonique avec validation Stripe
- Aucun `useEntitlement` modifie, aucun `FeatureGate` contourne

---

## 9. Pipeline utilise

Premier deploiement reel utilisant PH-TD-08 Safe Deploy Pipeline :

1. Clone Git fresh depuis `fix/signup-redirect-v2` sur GitHub
2. Build Docker `--no-cache` avec explicit COPY (Dockerfile securise)
3. Verification image (17 checks non-regression)
4. Release gate PROD (14 checks)
5. Push GHCR
6. Update GitOps manifest (keybuzz-infra)
7. ArgoCD sync automatique

Zero `kubectl set image`. Zero build depuis bastion dirty. Zero contamination.

---

## 10. Etat deploye

| Env | Image | ArgoCD | Pod |
|---|---|---|---|
| DEV | `v3.5.62-signup-fix-v2-dev` | Synced + Healthy | Running 1/1 |
| PROD | `v3.5.62-signup-fix-v2-prod` | Synced + Healthy | Running 1/1 |

---

## 11. Rollback disponible

| Env | Image rollback |
|---|---|
| DEV | `v3.5.61-td08-safe-dev` |
| PROD | `v3.5.58-channels-billing-prod` |

Rollback via : modifier `deployment.yaml` dans `keybuzz-infra`, commit, push, ArgoCD sync.

---

## 12. Verdict final

### SIGNUP FLOW FIXED

- `/signup` → redirect `/register` (DEV + PROD)
- Zero bypass paiement
- Zero regression UX
- Zero fichier interdit modifie
- Pipeline safe PH-TD-08 valide en conditions reelles
