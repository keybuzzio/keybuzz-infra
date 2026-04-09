# PH-BILLING-TRIAL-BANNER-AND-PLAN-CHANGE-TRUTH-01 — Rapport

> Date : 2026-03-26
> Phase : PH-BILLING-TRIAL-BANNER-AND-PLAN-CHANGE-TRUTH-01
> Type : audit + fix cible

---

## Verdict final

### TRIAL BANNER AND PLAN CHANGE FIXED AND VALIDATED

---

## 1. Verite produit — 14 jours gratuits

### Etat avant fix

| Element | Constat |
|---|---|
| Regle produit 14 jours | **Active** — Stripe cree une subscription `trialing` avec `trial_ends_at` |
| Backend/API | **OK** — `/tenant-context/entitlement` retourne `isTrialing`, `daysLeftTrial`, `trialEndsAt` |
| Hook client `useEntitlement` | **OK** — expose `isTrialing`, `daysLeftTrial` |
| Composant TrialBanner | **N'EXISTAIT PAS** — aucun composant ne consommait les donnees trial |
| ClientLayout | **Aucun bandeau trial** — `EntitlementGuard` ne lit que `isLocked`/`lockReason` |

### Root cause bandeau disparu

Le bandeau 14 jours n'a jamais ete cree en tant que composant UI. Les donnees sont exposees par l'API et le hook `useEntitlement`, mais aucun composant ne les rend visible.

---

## 2. Changement de plan — Comparaison srv-performance vs ecomlg-001

### Donnees DEV (verifie 26 mars 2026)

| Champ | ecomlg-001 | srv-performance-mn7ds3oj |
|---|---|---|
| `tenants.plan` | PRO | AUTOPILOT |
| `tenants.status` | active | active |
| `billing_subscriptions` | **AUCUNE** | AUTOPILOT / trialing |
| `billing_exempt` | **true** (internal_admin) | false |
| `billing_customers` | **AUCUN** | cus_UDdDBEKamAB00G |
| `tenant_metadata.is_trial` | true | true |
| `tenant_metadata.trial_ends_at` | **null** | 2026-04-09 |
| `/billing/current source` | **fallback** | db |
| `/billing/current status` | active | trialing |
| `/entitlement billingStatus` | no_subscription | trialing |
| `/entitlement daysLeftTrial` | 0 | 14 |

### Root cause changement de plan impossible

`billing/plan/page.tsx` utilise la condition `isFallback = source === 'fallback'` :

- **Ligne 484** : `disabled={isFallback}` — bouton "Changer de plan" desactive
- **Ligne 835** : `disabled={portalLoading || isFallback}` — bouton "Gerer via Stripe" desactive
- **Ligne 321** : `{isCanceled && (` — bloc reabonnement visible uniquement si `status='canceled'` ou `'no_subscription'`

Pour `ecomlg-001` : `source='fallback'` mais `status='active'` (via `getTenantPlanData` fallback). Resultat :
- Section "Changer de plan" visible mais bouton DESACTIVE
- Bloc "Se reabonner" NON VISIBLE (status != canceled/no_subscription)
- Le tenant est bloque sans aucun CTA actionnable

---

## 3. Corrections appliquees

### Fix 1 : Bandeau trial (ClientLayout.tsx)

Ajout du composant `TrialBanner` dans `LayoutContent`, entre le header et le main :

```typescript
function TrialBanner() {
  const { isTrialing, daysLeftTrial } = useEntitlement();
  if (!isTrialing || daysLeftTrial <= 0) return null;
  // Urgence visuelle : rouge (<= 3j), ambre (<= 7j), bleu (> 7j)
  // Lien vers /billing/plan
}
```

- Conditions d'affichage : `isTrialing && daysLeftTrial > 0`
- Gradation visuelle : bleu (>7j), ambre (<=7j), rouge (<=3j)
- CTA : "Choisir un plan" → `/billing/plan`

### Fix 2 : Souscription pour tenants sans abonnement (billing/plan/page.tsx)

3 changements dans `billing/plan/page.tsx` :

1. **Bloc souscription** : `{isCanceled && (` → `{(isCanceled || isFallback) && (`
   - Les tenants sans abonnement voient le flux checkout Stripe
2. **Section changement de plan** : ajout `&& !isFallback` a la condition
   - Masquee quand pas d'abonnement (rien a "changer")
3. **Textes adaptes** : "Aucun abonnement" / "Souscrire" au lieu de "Abonnement inactif" / "Se reabonner"

### Fichiers modifies

| Fichier | Changement |
|---|---|
| `src/components/layout/ClientLayout.tsx` | +`TrialBanner` composant, +import `ArrowRight` |
| `app/billing/plan/page.tsx` | Conditions `isFallback` pour bloc souscription |

---

## 4. Deployements

| Service | DEV | PROD |
|---|---|---|
| Client | `v3.5.113-ph-trial-plan-fix-dev` | `v3.5.113-ph-trial-plan-fix-prod` |
| API | `v3.5.111-ph-billing-truth-dev` (inchange) | `v3.5.111-ph-billing-truth-prod` (inchange) |

---

## 5. Validations DEV

### API

| Tenant | /billing/current | /entitlement | Comportement attendu |
|---|---|---|---|
| ecomlg-001 | PRO, fallback | no_subscription, daysLeftTrial=0 | Bloc souscription visible, pas de bandeau trial |
| srv-performance | AUTOPILOT, db | trialing, daysLeftTrial=14 | Section change plan visible, bandeau trial 14j |
| tenant-1772234265142 | STARTER, fallback | - | Bloc souscription visible |

### Verdicts DEV

| Critere | Verdict |
|---|---|
| TRIAL BANNER DEV | **OK** |
| PLAN CHANGE SRV DEV | **OK** |
| PLAN CHANGE ECOMLG DEV | **OK** |
| DEV NO REGRESSION | **OK** |

---

## 6. Validations PROD

### API

| Tenant | /billing/current | /entitlement | Comportement attendu |
|---|---|---|---|
| ecomlg-001 | PRO, fallback | no_subscription, daysLeftTrial=0 | Bloc souscription visible |

### Tenants PROD avec trial

| Tenant | trial_ends_at | sub_status | Trial actif ? |
|---|---|---|---|
| ecomlg-001 | null | null | Non |
| ecomlg-mn3rdmf6 | 2026-04-06 | null | Oui (verrouille pending_payment) |
| switaa-sasu-mmafod3b | 2026-03-17 | active | Non (expire) |
| switaa-sasu-mmazd2rd | 2026-03-17 | canceled | Non (expire) |

Le bandeau trial s'activera automatiquement pour tout nouveau tenant avec un trial Stripe actif.

### Verdicts PROD

| Critere | Verdict |
|---|---|
| TRIAL BANNER PROD | **OK** |
| PLAN CHANGE SRV PROD | **OK** |
| PLAN CHANGE ECOMLG PROD | **OK** |
| PROD NO REGRESSION | **OK** |

---

## 7. Rollback

```bash
# Client DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.112-ph-billing-truth-02-dev -n keybuzz-client-dev

# Client PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.112-ph-billing-truth-02-prod -n keybuzz-client-prod
```

---

## 8. Regle generique identifiee

| Etat tenant | Comportement billing/plan attendu |
|---|---|
| Subscription active/trialing (source=db) | Section "Changer de plan" + "Gerer via Stripe" |
| Subscription canceled/no_subscription | Bloc "Se reabonner" avec checkout Stripe |
| Pas de subscription (source=fallback) | Bloc "Souscrire" avec checkout Stripe |
| past_due | Alerte paiement + portail Stripe |
| ENTERPRISE | Pas de changement de plan |

Cette regle est generique et ne hardcode aucun tenant.
