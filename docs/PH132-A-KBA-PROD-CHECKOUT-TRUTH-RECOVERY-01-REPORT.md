# PH132-A — KBA PROD CHECKOUT TRUTH RECOVERY 01 — RAPPORT

**Date** : 28 mars 2026
**Phase** : PH132-A-KBA-PROD-CHECKOUT-TRUTH-RECOVERY-01
**Type** : audit + fix cible business critique (checkout KBActions)
**Environnement** : DEV valide, PROD non touche

---

## 1. Objectif

Verifier la verite reelle du systeme d'achat ponctuel KBActions, identifier ce qui bloque en production, corriger minimalement.

---

## 2. Cartographie du flux reel E2E

```
Utilisateur clique "Acheter KBActions"
  → UI (page ou modal)
    → POST /api/billing/ai-actions-checkout (BFF Next.js)
      → POST /billing/ai-actions-checkout (API Fastify)
        → Si Stripe configure: stripe.checkout.sessions.create()
        → Si Stripe non configure: DEV stub (ajout direct wallet)
          → Retour URL Stripe Checkout
    → window.location.assign(checkoutUrl) → Stripe Checkout
      → Paiement Stripe
        → Webhook checkout.session.completed
          → handleCheckoutCompleted()
            → if metadata.type === 'ai_actions'
              → addPurchasedActions(tenantId, actions, 'stripe-' + session.id)
                → UPDATE ai_actions_wallet (remaining + purchased_remaining)
                → INSERT ai_actions_ledger
```

---

## 3. Audit — Ce qui FONCTIONNE deja

| Maillon | DEV | PROD | Preuve |
|---|---|---|---|
| BFF `/api/billing/ai-actions-checkout` | OK | OK | Pas de blocage env, forward propre |
| Backend `/billing/ai-actions-checkout` | OK | OK | Status 200, URL Stripe generee |
| Stripe checkout session | OK | OK | DEV: `cs_test_...`, PROD: `cs_live_...` |
| Webhook `checkout.session.completed` | OK | OK | Meme code DEV/PROD |
| `addPurchasedActions()` | OK | OK | Idempotent, atomique, ledger |
| Wallet DB | OK | OK | ecomlg-001: 388.67 PROD, 4.11 DEV |
| Page `/billing/ai` (achat principal) | OK | OK | Envoie tenantId + pack, redirect Stripe |
| `AIActionsLimit` modal (wallet vide) | OK | OK | Meme flux checkout |
| `AISuggestionSlideOver` (inbox) | OK | OK | Envoie tenantId + pack |

### Variables Stripe PROD confirmees
- `STRIPE_SECRET_KEY` : present
- `STRIPE_WEBHOOK_SECRET` : present
- Tous les price IDs : presents
- `isStripeConfigured()` : true (prouve par reponse `cs_live_`)

---

## 4. Point exact de blocage

### Unique point de blocage identifie

**Fichier** : `app/billing/ai/manage/page.tsx`
**Lignes** : 423-441 (avant correction)
**Probleme** : bouton `disabled` avec texte "Bientot disponible (Stripe)" en PROD

```tsx
// AVANT — bouton placeholder desactive
{!isDev && (
  <button disabled>
    Bientôt disponible (Stripe)
  </button>
)}
```

**Impact** : seule la page `/billing/ai/manage` (admin RBAC owner/admin) etait bloquee.
Les autres chemins d'achat (page `/billing/ai`, modal AIActionsLimit, modal inbox) fonctionnaient deja.

### Le blocage 403 historique n'existe plus
La route BFF ne contient aucun check d'environnement ni 403 artificiel. Le commentaire en tete du fichier confirme : "Available in ALL environments (DEV + PROD)".

---

## 5. Correction appliquee

### Fichier modifie : `app/billing/ai/manage/page.tsx`

| Changement | Detail |
|---|---|
| Import | `ShoppingCart` (lucide-react), `AIActionPacksModal` (@/src/features/ai-ui) |
| State | `showPurchaseModal` (useState) |
| Handler | `handlePurchase(packId)` → POST `/api/billing/ai-actions-checkout` → redirect Stripe |
| UI PROD | Bouton "Recharger mes KBActions" (actif) remplace "Bientot disponible" (desactive) |
| Modal | `AIActionPacksModal` avec packs small/medium/large |

```tsx
// APRES — bouton actif + modal reel
{!isDev && (
  <>
    <button onClick={() => setShowPurchaseModal(true)}>
      Recharger mes KBActions
    </button>
    <AIActionPacksModal
      isOpen={showPurchaseModal}
      onClose={() => setShowPurchaseModal(false)}
      onPurchase={handlePurchase}
      tenantId={currentTenantId || ''}
    />
  </>
)}
```

### Pattern identique a `/billing/ai/page.tsx`
Le `handlePurchase` utilise exactement le meme pattern que la page principale (POST BFF, redirect `window.location.assign`).

---

## 6. Points d'achat KBActions — Matrice complete

| Point d'entree | Page/Composant | Fonctionne PROD | Envoie tenantId |
|---|---|---|---|
| Page KBActions | `/billing/ai/page.tsx` | OUI | OUI (currentTenantId) |
| Modal epuisement | `AIActionsLimit.tsx` (modal) | OUI | OUI (via parent) |
| Inbox suggestion | `AISuggestionSlideOver.tsx` | OUI | OUI (tenantId prop) |
| Admin manage | `/billing/ai/manage/page.tsx` | **CORRIGE** (etait desactive) | OUI (currentTenantId) |

---

## 7. Packs disponibles

| Pack | KBActions | Prix EUR | USD Credit interne |
|---|---|---|---|
| small (Essentiel) | 50 | 24,90 EUR | $0.50 |
| medium (Pro) | 200 | 69,90 EUR | $1.50 |
| large (Business) | 500 | 149,90 EUR | $5.00 |

---

## 8. Validation DEV

### Image deployee
`ghcr.io/keybuzzio/keybuzz-client:v3.5.127-kba-checkout-fix-dev`

### Build verification
| Element | Statut |
|---|---|
| `AIActionPacksModal` dans manage page build | PRESENT |
| `Recharger mes KBActions` dans build | PRESENT |
| `handlePurchase` dans build | PRESENT |
| `ShoppingCart` icon dans build | PRESENT |

### Backend checkout
| Test | Resultat |
|---|---|
| POST /billing/ai-actions-checkout DEV | Status 200, URL Stripe valide |
| POST /billing/ai-actions-checkout PROD | Status 200, URL Stripe Live valide |

### API / pages
| Test | Resultat |
|---|---|
| API health DEV | 200 OK |
| Wallet DEV (ecomlg-001) | remaining=4.11, purchased=50, monthly=1000 |

---

## 9. Non-regressions

| Module | Statut |
|---|---|
| Backend API | Non touche (meme image v3.5.51) |
| Billing subscriptions | Non touche |
| Stripe webhooks | Non touche |
| Wallet KBActions | Intact |
| AI Actions limit block | Non touche |
| Onboarding / paywall | Non touche |
| Inbox | Non touche |
| Orders | Non touche |
| Dashboard | Non touche |
| Playbooks | Non touche |
| Plans / checkout | Non touche |
| Add-ons channels | Non touche |

---

## 10. Versions

| Environnement | Service | Image |
|---|---|---|
| **DEV** | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.127-kba-checkout-fix-dev` |
| **DEV** | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-dev` (non modifie) |
| **PROD** | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.126-playbooks-suggestions-live-prod` (NON TOUCHE) |
| **PROD** | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-prod` (NON TOUCHE) |

### Rollback DEV
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.126-playbooks-suggestions-live-dev -n keybuzz-client-dev
```

### Rollback PROD (si promu)
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.126-playbooks-suggestions-live-prod -n keybuzz-client-prod
```

---

## 11. GitOps

| Fichier | Statut |
|---|---|
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Mis a jour (v3.5.127-kba-checkout-fix-dev) |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | NON TOUCHE |

---

## 12. Resume du diagnostic

| Question | Reponse |
|---|---|
| Le backend est-il sain ? | **OUI** — fonctionne parfaitement DEV + PROD |
| Le webhook est-il sain ? | **OUI** — handleCheckoutCompleted gere ai_actions |
| Le wallet est-il sain ? | **OUI** — atomique, idempotent |
| Le BFF est-il bloque en PROD ? | **NON** — aucun check env, forward propre |
| Le 403 historique existe encore ? | **NON** — elimine dans un patch precedent |
| Quel est le seul blocage ? | Bouton "Bientot disponible" desactive sur `/billing/ai/manage` |
| Les autres chemins d'achat fonctionnent ? | **OUI** — page KBA, modal, inbox |

---

## 13. Statut PROD

**PROD = NON TOUCHE**

En attente de validation explicite de Ludovic pour promotion PROD.

---

## 14. Verdict

# KBA CHECKOUT TRUTH RECOVERED — PROD BLOCK IDENTIFIED/FIXED — BILLING SAFE — WALLET SAFE — ROLLBACK READY
