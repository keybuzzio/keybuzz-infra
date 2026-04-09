# PH138-J — Agent KeyBuzz Billing Behavior Audit

> Date : 2026-04-01
> Statut : **AUDIT COMPLETE**
> Auteur : Agent Cursor
> Type : Lecture seule — aucune modification de code, DB, ou Stripe

---

## 1. Objectif

Verifier precisement le comportement Stripe reel de l'add-on Agent KeyBuzz :
facturation immediate ou differee, respect du trial, alignement cycle, proration.

---

## 2. Tenants testes

### DEV (Stripe TEST mode)

| Tenant ID | Nom | Plan DB | Status | Addon DB | Stripe Sub ID |
|-----------|-----|---------|--------|----------|---------------|
| `olyara369-gmail-com-mnfln8nh` | olyara369 | AUTOPILOT | trialing | **true** | `sub_1THHFC...` |
| `w3lg-mnetvabm` | W3LG | AUTOPILOT | active | **true** | `sub_1TH59B...` |
| `switaa-sasu-mnc1x4eq` | SWITAA SASU | AUTOPILOT | trialing | **true** | `sub_1TGNQm...` |
| `gonthier-mnc5ys96` | GONTHIER | PRO | trialing | false | `sub_1TGPCS...` |
| `ecomlg-mmiyygfg` | ecomlg | PRO | active | false | `sub_1T8zyY...` |

### PROD (Stripe LIVE mode)

| Tenant ID | Nom | Plan DB | Status | Addon DB | Stripe Sub ID |
|-----------|-----|---------|--------|----------|---------------|
| `romruais-gmail-com-mn7mc6xl` | romruais | AUTOPILOT | trialing | false | `sub_1TFFic...` |
| `switaa-sasu-mn9c3eza` | SWITAA SASU | AUTOPILOT | trialing | false | `sub_1TFgjR...` |
| `switaa-sasu-mnc1ouqu` | SWITAA SASU | AUTOPILOT | trialing | false | `sub_1TGNLt...` |

---

## 3. Stripe Products et Prices

### Produit Agent KeyBuzz

| Attribut | Valeur |
|----------|--------|
| Product ID | `prod_UFWneeyEEoBCIK` |
| Nom | Agent KeyBuzz |
| Prix monthly | `price_1TH1jjFC0QQLHISRIOPMo7ac` = **797 EUR/mois** |
| Prix annual | `price_1TH1jjFC0QQLHISRuArLsIP9` = **7656 EUR/an** (638 EUR/mois) |
| Mode | **Stripe TEST uniquement** |

### ALERTE CRITIQUE : Produit absent en Stripe LIVE

Le produit `prod_UFWneeyEEoBCIK` et ses prices n'existent **que dans Stripe TEST mode**.
Les variables d'env PROD referecent les memes IDs test :

```
STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ: prod_UFWneeyEEoBCIK  # TEST MODE ID
STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY: price_1TH1jjFC0QQLHISRIOPMo7ac  # TEST MODE ID
```

**Consequence** : toute tentative d'activation Agent KeyBuzz en PROD echouera avec `No such price`.
Aucun tenant PROD n'a l'addon actif (confirme).

---

## 4. Analyse du code — Flow d'activation

### Endpoint : `POST /billing/checkout-agent-keybuzz`

**Chemin primaire (90% des cas)** : Modification directe de la subscription Stripe

```
stripe.subscriptions.update(subId, {
  items: [{ price: addonPriceId }],
  proration_behavior: isTrialing ? 'none' : 'create_prorations',
});
```

- Si trial actif : `proration_behavior: 'none'` → 0 EUR, addon ajoute silencieusement
- Si subscription active : `proration_behavior: 'create_prorations'` → montant prorate debite immediatement
- Retourne `{ activated: true }` → PAS de page Stripe Checkout

**Chemin fallback (si direct update echoue)** : Cree une Checkout Session Stripe avec tous les items (plan + addon) et redirige le user vers Stripe.

### Client : `activateAddon()` dans AutopilotSection.tsx

```
1. POST /api/billing/checkout-agent-keybuzz { tenantId }
2. Si data.activated → toast "Agent KeyBuzz active avec succes" (PAS de checkout)
3. Si data.url → redirect vers Stripe Checkout (fallback uniquement)
4. Si data.alreadyActive → toast "Agent KeyBuzz deja actif"
```

---

## 5. Resultats Stripe detailles (DEV)

### CAS 1 — olyara369 : AUTOPILOT en trial + addon

| Attribut | Valeur |
|----------|--------|
| Status | trialing |
| Trial | 2026-04-01 → 2026-04-15 (14j) |
| Items | 497 EUR Autopilot + **797 EUR Agent KeyBuzz** |
| Latest invoice | 0 EUR (billing_reason: subscription_create) |
| Facturation immediate | **NON** (trial = 0 EUR) |

A la fin du trial (15 avril) : **1294 EUR/mois** sera debite (497 + 797).

### CAS 2 — w3lg : AUTOPILOT active + addon

| Attribut | Valeur |
|----------|--------|
| Status | active |
| Trial | aucun |
| Items | 497 EUR Autopilot + **797 EUR Agent KeyBuzz** |
| Latest invoice | **797 EUR paid** (billing_reason: subscription_create) |
| Facturation immediate | **OUI** (797 EUR debites) |

2 invoices dans l'historique :
1. `in_...pKVqXzhn` : 0 EUR (subscription initiale/trial)
2. `in_...9k6GD1LQ` : 797 EUR (creation nouvelle subscription via fallback checkout)

### CAS 3 — switaa-sasu-mnc1x4eq : AUTOPILOT en trial + addon

| Attribut | Valeur |
|----------|--------|
| Status | trialing |
| Trial | 2026-03-29 → 2026-04-12 (14j) |
| Items | 497 EUR Autopilot + **797 EUR Agent KeyBuzz** |
| Latest invoice | 0 EUR (billing_reason: subscription_create) |
| Facturation immediate | **NON** (trial = 0 EUR) |

### CAS 4 — gonthier : PRO trial, sans addon (reference)

| Attribut | Valeur |
|----------|--------|
| Status | trialing |
| Items | 297 EUR Pro uniquement |
| Latest invoice | 0 EUR |

### CAS 5 — ecomlg-mmiyygfg : PRO active, sans addon (reference)

| Attribut | Valeur |
|----------|--------|
| Status | active |
| Items | 297 EUR Pro + 2x50 EUR canaux |
| Latest invoice | 397 EUR (subscription_cycle) |

---

## 6. Verification des 4 points critiques

### 1. Facturation immediate

| Scenario | Facturation immediate | Montant | Confirmation user |
|----------|-----------------------|---------|-------------------|
| Trial + addon (chemin primaire) | **NON** | 0 EUR | **Aucune** (toast seulement) |
| Active + addon (chemin primaire) | **OUI** | Montant prorate | **Aucune** (toast seulement) |
| Fallback checkout | OUI (apres validation) | Prix complet | **OUI** (page Stripe) |

**PROBLEME** : Le chemin primaire n'affiche jamais le prix. L'utilisateur ne voit pas le 797 EUR/mois avant activation.

### 2. Respect du trial

| Scenario | Trial respecte | Charge pendant trial |
|----------|---------------|---------------------|
| Addon pendant trial | **OUI** (proration: none) | 0 EUR |
| Addon apres trial | N/A | Prorated |

**PROBLEME** : L'addon est ajoute silencieusement pendant le trial. A la fin du trial, le user sera facture 497 + 797 = **1294 EUR/mois** sans avoir vu le prix de 797 EUR.

### 3. Alignement cycle

| Attribut | Plan principal | Addon |
|----------|---------------|-------|
| billing_cycle_anchor | Meme | Meme (herite de la subscription) |
| Periode | Meme | Meme |
| Cycle (monthly) | Meme | Meme |

**OK** : L'addon est un item additionnel sur la meme subscription, donc meme cycle.

### 4. Proration

| Scenario | Proration | Correct |
|----------|-----------|---------|
| Trial | `none` | OUI (pas de charge pendant trial) |
| Active | `create_prorations` | OUI (montant au prorata du temps restant) |

**OK** : La logique de proration est correcte.

---

## 7. Coherence DB

### DEV — billing_subscriptions vs Stripe

| Tenant | DB has_addon | Stripe has addon item | Coherent |
|--------|-------------|----------------------|----------|
| olyara369 | true | true (797 EUR item) | OUI |
| w3lg | true | true (797 EUR item) | OUI |
| switaa-sasu-mnc1x4eq | true | true (797 EUR item) | OUI |
| gonthier | false | false | OUI |

### PROD — billing_subscriptions

| Tenant | DB has_addon | Stripe has addon item | Coherent |
|--------|-------------|----------------------|----------|
| romruais | false | false | OUI |
| switaa-sasu (x2) | false | false | OUI |

---

## 8. Verification UX

| Element | Comportement actuel | Probleme |
|---------|-------------------|----------|
| Clic "Activer Agent KeyBuzz" | Appel API direct → toast "active" | **Aucun prix affiche** |
| Confirmation prix | Absente | **CRITIQUE** |
| Indication 797 EUR/mois | Absente dans le flow | **CRITIQUE** |
| Page Stripe Checkout | Uniquement en fallback | Non atteinte normalement |
| Toast succes | "Agent KeyBuzz active avec succes" | OK mais insuffisant |
| Mention impact trial | Absente | L'user ne sait pas qu'il sera facture 1294 EUR a la fin |

---

## 9. Synthese comportement reel

| Cas | Facturation | Confirmation | Prix affiche | Alignement cycle | UX coherente |
|-----|-------------|-------------|--------------|-----------------|-------------|
| Trial + addon | 0 EUR (trial) puis 1294 EUR/mois | **NON** | **NON** | OUI | **NON** |
| Active + addon | Prorated immediatement | **NON** | **NON** | OUI | **NON** |
| PROD | **IMPOSSIBLE** (product absent en live) | N/A | N/A | N/A | N/A |

---

## 10. Problemes identifies (gravite decroissante)

### P1 — CRITIQUE : Produit Agent KeyBuzz absent en Stripe LIVE

Le produit `prod_UFWneeyEEoBCIK` n'existe qu'en mode test. Les env vars PROD pointent vers des IDs test. Toute activation en PROD echouera.

**Action requise** : Creer le produit et les prix en Stripe LIVE mode, puis mettre a jour les env vars PROD.

### P2 — CRITIQUE : Aucune confirmation de prix avant activation

Le chemin primaire active l'addon en 1 clic sans jamais afficher le prix (797 EUR/mois). C'est problematique pour :
- **Legal** : le RGPD et la directive UE 2011/83 exigent une confirmation de prix avant engagement
- **UX** : l'utilisateur ne sait pas combien il va payer
- **Business** : risque de litiges, chargebacks, perte de confiance

### P3 — MAJEUR : Addon silencieux pendant trial

L'addon est ajoute sans indication du cout futur. A la fin du trial :
- Sans addon : 497 EUR/mois
- Avec addon : 1294 EUR/mois (+160%)

L'utilisateur risque un choc de facturation.

### P4 — MINEUR : findPlanItem() ne filtre pas Agent KeyBuzz

```typescript
export function findPlanItem(items: any[]): any | null {
  return items.find((item: any) => {
    const pid = ...;
    return pid !== CHANNEL_ADDON_PRODUCT_ID;  // ne filtre PAS AGENT_KEYBUZZ
  }) || null;
}
```

Pourrait identifier l'addon comme un plan item. Attenue par le fallback metadata.

---

## 11. Recommandation

### Option B recommandee : Checkout Stripe obligatoire

| Critere | Option A (Direct) | Option B (Checkout) | Option C (Confirmation) |
|---------|-------------------|---------------------|------------------------|
| Legal EU | **INTERDIT** | Conforme | Conforme |
| UX | 1 clic | 2-3 clics | 2 clics |
| Prix visible | NON | OUI (Stripe) | OUI (modal custom) |
| Chargebacks | Risque eleve | Protege | Moyen |
| Implementation | Existant | Faible effort | Moyen effort |
| Codes promo | Non | OUI (allow_promotion_codes) | Non |

**Justification** :

1. **Legal** : La directive UE 2011/83 (vente a distance) exige que le prix soit clairement affiche AVANT le clic d'engagement. Le chemin primaire actuel viole cette regle.

2. **Business** : Un checkout Stripe affiche le prix, accepte les codes promo, genere un recu, et protege contre les chargebacks. Le flow actuel ne fait rien de tout cela.

3. **Implementation** : Le fallback checkout existe deja dans le code. Il suffit de supprimer le chemin primaire (`stripe.subscriptions.update`) et de toujours utiliser le checkout session.

### Actions concretes proposees

1. **Creer Product + Prices Agent KeyBuzz en Stripe LIVE** (bloquant PROD)
2. **Supprimer le chemin primaire** : toujours passer par Stripe Checkout Session
3. **Ajouter dans le Checkout** : `subscription_data.trial_end` pour aligner le trial de l'addon avec le trial existant (si applicable)
4. **Corriger `findPlanItem()`** : exclure aussi `AGENT_KEYBUZZ_ADDON_PRODUCT_ID`
5. **Ajouter indication prix** dans le CTA : "Activer Agent KeyBuzz (797 EUR/mois)"

---

## 12. Rollback

Aucune modification effectuee — audit lecture seule.

---

## 13. Preuves

### Stripe DEV — Subscription olyara369 (trial + addon)
```
status: trialing
trial: 2026-04-01 → 2026-04-15
items: [497 EUR Autopilot, 797 EUR Agent KeyBuzz]
latest_invoice: 0 EUR (subscription_create)
```

### Stripe DEV — Subscription w3lg (active + addon)
```
status: active
items: [497 EUR Autopilot, 797 EUR Agent KeyBuzz]
latest_invoice: 797 EUR paid (subscription_create)
```

### Stripe PROD — Aucun addon actif
```
romruais: 1 item (497 EUR Autopilot), no addon
switaa-sasu (x2): 1 item (497 EUR Autopilot), no addon
Agent KeyBuzz product: ABSENT en Stripe LIVE
```

### Code — Chemin primaire (pas de checkout)
```
// billing/routes.ts ligne 1009
stripe.subscriptions.update(subId, {
  items: [{ price: addonPriceId }],
  proration_behavior: isTrialing ? 'none' : 'create_prorations',
});
// → activated: true → toast client → PAS de page Stripe
```

### ENV PROD (meme IDs que DEV = TEST mode)
```
STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ: prod_UFWneeyEEoBCIK (TEST)
STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY: price_1TH1jjFC0QQLHISRIOPMo7ac (TEST)
```
