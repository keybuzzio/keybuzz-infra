# PH138-A — Stripe Add-on Billing : Agent KeyBuzz

> Date : 2026-03-31
> Auteur : Cursor Executor (CE)
> Environnement : DEV uniquement
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-dev`

---

## 1. Objectif

Mettre en place la facturation complète du module **Agent KeyBuzz** en tant qu'add-on Stripe :
- 1 seule subscription Stripe par tenant (plan principal + add-on combinés)
- Aucun doublon produit/price
- Aucun placeholder
- Gating IA réel basé sur l'addon billing

---

## 2. Audit Stripe (état initial)

### Produits existants
| Product ID | Nom | Type |
|---|---|---|
| `prod_TjrtU3R2CeWUTJ` | KeyBuzz Starter | Plan |
| `prod_TjrtI6NYNyDBbp` | KeyBuzz Pro | Plan |
| `prod_TjrtoaGcUi0yNB` | KeyBuzz Autopilot | Plan |
| `prod_TjrtcvXp3I6fJR` | KeyBuzz Canal Supplementaire | Addon |

**Aucun produit "Agent KeyBuzz" n'existait.**

### Structure subscription
- 1 subscription par tenant avec plan price + optionnel channel addon
- Pattern existant : `subscription.items = [plan_price, channel_addon_price?]`

---

## 3. Produit Stripe créé

### Product
| Champ | Valeur |
|---|---|
| ID | `prod_UFWneeyEEoBCIK` |
| Nom | Agent KeyBuzz |
| Description | Module IA avancé avec escalade vers l'équipe KeyBuzz |
| Metadata | `kb_type: addon_agent_keybuzz` |

### Prices
| ID | Montant | Cycle |
|---|---|---|
| `price_1TH1jjFC0QQLHISRIOPMo7ac` | 797 EUR | Mensuel |
| `price_1TH1jjFC0QQLHISRuArLsIP9` | 7 656 EUR | Annuel |

---

## 4. Modifications backend

### 4.1 Migration DB
```sql
ALTER TABLE billing_subscriptions
ADD COLUMN IF NOT EXISTS has_agent_keybuzz_addon BOOLEAN DEFAULT false;
```
Exécuté sur le leader Patroni (db-postgres-03, 10.0.0.122).

### 4.2 `pricing.ts` — Nouveaux helpers
- `AGENT_KEYBUZZ_ADDON_PRODUCT_ID` : constante produit
- `getAgentKeybuzzAddonPriceId(cycle)` : retourne le price ID selon le cycle
- `findAgentKeybuzzAddonItem(items)` : trouve l'item addon dans une subscription

### 4.3 `routes.ts` — Modifications
**Interface `BillingData`** : ajout `hasAgentKeybuzzAddon: boolean`

**GET `/billing/current`** :
- SELECT enrichi avec `COALESCE(s.has_agent_keybuzz_addon, false)`
- Retourne `hasAgentKeybuzzAddon` dans la réponse

**`handleSubscriptionChange()`** :
- Détecte automatiquement l'item Agent KeyBuzz dans `subscription.items`
- Persiste `has_agent_keybuzz_addon` dans `billing_subscriptions`

**Nouveaux endpoints :**

| Method | Route | Description |
|---|---|---|
| POST | `/billing/update-agent-keybuzz` | Active/désactive l'addon |
| GET | `/billing/agent-keybuzz-status` | Statut addon + éligibilité |

### 4.4 `ai-mode-engine.ts` — Gating réel
- `canEscalateToKeybuzz` vérifie maintenant `has_agent_keybuzz_addon` dans `billing_subscriptions`
- Plus de gating uniquement par plan ENTERPRISE
- Message d'erreur : "Cette fonctionnalité nécessite le module Agent KeyBuzz. Activez-le depuis Facturation > Agent KeyBuzz."

---

## 5. Variables d'environnement

| Variable | Valeur | Source |
|---|---|---|
| `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` | `prod_UFWneeyEEoBCIK` | Deployment env |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` | `price_1TH1jjFC0QQLHISRIOPMo7ac` | Deployment env |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` | `price_1TH1jjFC0QQLHISRuArLsIP9` | Deployment env |

Ajoutées directement dans le deployment (pas dans le secret ExternalSecrets, Vault étant DOWN).

---

## 6. Tests DEV

### Test 1 : GET /billing/current
```
Status: 200
hasAgentKeybuzzAddon: false
Plan: PRO
```
✅ Champ correctement retourné

### Test 2 : GET /billing/agent-keybuzz-status (sans subscription)
```
hasAddon: false, canActivate: false, reason: "no_subscription"
```
✅ Tenant sans sub = pas activable

### Test 3 : GET /billing/agent-keybuzz-status (avec subscription AUTOPILOT)
```
hasAddon: false, plan: "AUTOPILOT", canActivate: true, monthlyPrice: 797
```
✅ Tenant AUTOPILOT avec sub = activable

### Test 4 : POST /billing/update-agent-keybuzz (enable)
```
Status: 200, action: "enabled", hasAgentKeybuzzAddon: true
```
✅ Addon ajouté à la subscription Stripe

### Test 5 : Vérification après activation
```
hasAddon: true
```
✅ Persisté en DB

### Test 6 : POST /billing/update-agent-keybuzz (disable)
```
Status: 200, action: "disabled", hasAgentKeybuzzAddon: false
```
✅ Addon supprimé de la subscription Stripe

### Test 7 : Vérification Stripe directe
```
Subscription items: [price_1SmO9vFC0QQLHISRk0Pob4j9 (Autopilot)] — Agent KeyBuzz: 0
```
✅ Subscription clean après disable

---

## 7. Non-régression DEV

| Endpoint | Résultat |
|---|---|
| `/health` | ✅ 200 |
| `/billing/current` | ✅ 200 |
| `/billing/agent-keybuzz-status` | ✅ 200 |
| `/billing/status` | ✅ 200 |
| `/messages/conversations` | ✅ 200 |
| `/api/v1/orders` | ✅ 200 |
| `/dashboard/summary` | ✅ 200 |
| `/tenant-context/check-user` | ✅ 200 |
| Client `/login` | ✅ 200 |
| Client `/inbox` | ✅ 200 |
| Client `/dashboard` | ✅ 200 |
| Client `/billing` | ✅ 200 |
| Client `/orders` | ✅ 200 |

**8/8 API + 5/5 Client = 13/13 OK**

---

## 8. Structure subscription finale

```
subscription.items = [
  main_plan_price,                    // Starter / Pro / Autopilot
  channel_addon_price? (qty=N),       // Canaux supplémentaires
  agent_keybuzz_addon_price? (qty=1)  // Agent KeyBuzz (optionnel)
]
```

**1 client = 1 subscription = N items**

---

## 9. Flux webhook

Le `handleSubscriptionChange()` existant détecte automatiquement l'addon :
1. Stripe webhook `customer.subscription.updated` → arrive
2. Parse `subscription.items` avec `findAgentKeybuzzAddonItem()`
3. Persiste `has_agent_keybuzz_addon = true/false` dans DB
4. Le gating IA dans `ai-mode-engine.ts` réagit immédiatement

---

## 10. Cluster Patroni (bonus)

Observation lors de la migration DB :
- **db-postgres-03** (10.0.0.122) = **Leader** (changement depuis le dernier audit)
- **db-postgres-01** (10.0.0.120) = Replica (streaming, lag=0)
- **db-postgres-02** (10.0.0.121) = Replica (streaming, lag=0) ← **RECOVERED**

Le cluster Patroni est maintenant à **1 leader + 2 replicas** (HA restaurée).

---

## 11. Déploiement PROD

### Images
| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-prod` |
| Worker | `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-prod` |

### Migration DB PROD
```sql
ALTER TABLE billing_subscriptions ADD COLUMN IF NOT EXISTS has_agent_keybuzz_addon BOOLEAN DEFAULT false;
```
Exécuté sur le leader Patroni (db-postgres-03, 10.0.0.122) sur la base `keybuzz_prod`.

### Env vars ajoutées PROD
| Variable | Valeur |
|---|---|
| `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` | `prod_UFWneeyEEoBCIK` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` | `price_1TH1jjFC0QQLHISRIOPMo7ac` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` | `price_1TH1jjFC0QQLHISRuArLsIP9` |

### Pods PROD post-deploy
```
keybuzz-api-5d7c4c4cfc-9d6wx               1/1     Running
keybuzz-outbound-worker-5dfd7c757f-dj4bh   1/1     Running
```

### Non-régression PROD
| Endpoint | Résultat |
|---|---|
| `/health` | ✅ 200 |
| `/billing/current` (hasAgentKeybuzzAddon=false) | ✅ 200 |
| `/billing/agent-keybuzz-status` | ✅ 200 |
| `/messages/conversations` | ✅ 200 |
| `/api/v1/orders` | ✅ 200 |
| `/dashboard/summary` | ✅ 200 |
| `/tenant-context/check-user` | ✅ 200 |
| Client `/login` | ✅ 200 |
| Client `/inbox` | ✅ 200 |
| Client `/dashboard` | ✅ 200 |
| Client `/billing` | ✅ 200 |
| Client `/orders` | ✅ 200 |

**7/7 API + 5/5 Client = 12/12 OK — Zero erreur dans les logs**

---

## 12. Rollback

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.150-ai-mode-engine-dev -n keybuzz-api-dev

# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.150-ai-mode-engine-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.150-ai-mode-engine-prod -n keybuzz-api-prod

# La colonne DB has_agent_keybuzz_addon est ignorée (COALESCE + DEFAULT false)
# Aucun rollback DB nécessaire
```

---

## 13. Prochaines étapes (hors scope PH138-A)

- [ ] UI client : page Agent KeyBuzz dans `/billing/ai` ou `/settings`
- [ ] BFF route `/api/billing/agent-keybuzz-status`
- [ ] CTA "Activer Agent KeyBuzz" dans les paramètres IA

---

## 14. Verdict

**STRIPE ADDON BILLING LIVE — DEV + PROD — SINGLE SUBSCRIPTION — NO DUPLICATE — NO PLACEHOLDER — GATING REAL — READY FOR SALES**
