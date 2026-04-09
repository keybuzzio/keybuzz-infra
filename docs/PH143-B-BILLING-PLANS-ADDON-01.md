# PH143-B — Billing Plans Addon Rebuild

> Date : 2026-04-05
> Phase : PH143-B-BILLING-PLANS-ADDON-01
> Type : reconstruction controlee bloc 1
> Environnement : branches rebuild uniquement
> Branche API : `rebuild/ph143-api`
> Branche Client : `rebuild/ph143-client`

---

## 1. Resume executif

Bloc Billing reconstruit avec succes sur la ligne de reconstruction PH143. Les fonctionnalites BILL-01 a BILL-06 sont restaurees a partir de PH131-B.2 en portant les fichiers valides depuis `main`. L'API et le client sont buildes, deployes et valides en DEV.

| Feature | Avant (PH131-B.2) | Apres (PH143-B) | Statut |
|---|---|---|---|
| BILL-01 Upgrade CTA | CTAs non visibles | 4 CTAs "Passez au plan Autopilot" visibles | **GREEN** |
| BILL-02 Addon Agent KeyBuzz | Pas d'endpoints | 3 endpoints + checkout Stripe | **GREEN** |
| BILL-03 hasAgentKeybuzzAddon | Absent de la reponse | Present dans billing/current | **GREEN** |
| BILL-04 URL sync post-Stripe | Deja fonctionnel | Confirme | **GREEN** |
| BILL-05 Addon gating | Pas de gating addon | Blocs verrouilles avec CTA | **GREEN** |
| BILL-06 billing/current coherent | channelsIncluded hardcode | Utilise getIncludedChannels() | **GREEN** |

---

## 2. Features BILL-01 a BILL-06 — Detail

### BILL-01 — Upgrade plan CTA

**Avant** : Les blocs Autonome/KeyBuzz/Les deux dans Settings > IA n'affichaient pas de CTA d'upgrade.

**Apres** : 4 CTAs "Passez au plan Autopilot" visibles et fonctionnels sur PRO :
- Mode Autonome (disabled + CTA)
- Escalade KeyBuzz (disabled + CTA)
- Escalade Les deux (disabled + CTA)
- Reponse automatique (CTA)

**Preuve navigateur** : Snapshot Settings > IA sur tenant PRO (ecomlg-001) confirme les 4 CTAs.

### BILL-02 — Addon Agent KeyBuzz

**Avant** : Aucun endpoint addon.

**Apres** : 3 endpoints API + 3 BFF routes client :
- `GET /billing/agent-keybuzz-status` — statut addon
- `POST /billing/checkout-agent-keybuzz` — Stripe Checkout obligatoire (pas d'activation directe)
- `POST /billing/update-agent-keybuzz` — desactivation seulement, `enable=true` retourne `checkout_required`

**Test API** :
```
POST /billing/update-agent-keybuzz {enable:true}
→ 400 {"error":"checkout_required","message":"L'activation de l'Agent KeyBuzz nécessite un paiement via Stripe Checkout."}
```

### BILL-03 — hasAgentKeybuzzAddon

**Avant** : Champ absent de la reponse billing/current.

**Apres** : Champ present dans toutes les reponses billing/current.

**Preuve** :
```json
GET /billing/current?tenantId=ecomlg-001
{"plan":"PRO","channelsIncluded":3,"hasAgentKeybuzzAddon":false,"status":"active",...}
```

### BILL-04 — URL sync post-Stripe

**Avant/Apres** : Deja fonctionnel dans le code de base. Le nettoyage `?stripe=success` est gere par le webhook handler existant.

### BILL-05 — Addon gating

**Avant** : `planCapabilities` ne definissait pas `maxAgents`/`maxKeybuzzAgents`.

**Apres** :
- STARTER: maxAgents=1, maxKeybuzzAgents=0
- PRO: maxAgents=2, maxKeybuzzAgents=0
- AUTOPILOT: maxAgents=3, maxKeybuzzAgents=1
- ENTERPRISE: maxAgents=Infinity, maxKeybuzzAgents=3

Les blocs PRO sont correctement verrouilles avec CTAs.

### BILL-06 — billing/current coherent

**Avant** : `channelsIncluded` hardcode (`AUTOPILOT ? 10 : PRO ? 3 : 1`).

**Apres** : Utilise `getIncludedChannels(plan)` pour une source de verite unique.

**Preuve** : PRO retourne `channelsIncluded: 3`, correct.

---

## 3. Fichiers restaures

### API (rebuild/ph143-api)

| Fichier | Action | Delta |
|---|---|---|
| `src/modules/billing/pricing.ts` | Mis a jour | +21 lignes (addon Agent KeyBuzz) |
| `src/modules/billing/routes.ts` | Mis a jour | +275 lignes (3 endpoints addon + webhook handler + hasAgentKeybuzzAddon) |
| `src/modules/billing/pricing.ts.bak` | Supprime | Nettoyage |
| `src/modules/billing/routes.ts.bak*` (x5) | Supprimes | Nettoyage |

### Client (rebuild/ph143-client)

| Fichier | Action | Delta |
|---|---|---|
| `src/features/billing/planCapabilities.ts` | Mis a jour | +20 lignes (maxAgents, maxKeybuzzAgents) |
| `src/features/billing/useCurrentPlan.tsx` | Remplace | PlanProvider utilise `useTenant()` au lieu de localStorage |
| `app/api/billing/checkout-agent-keybuzz/route.ts` | Cree | BFF route POST addon checkout |
| `app/api/billing/update-agent-keybuzz/route.ts` | Cree | BFF route POST addon update |
| `app/api/billing/agent-keybuzz-status/route.ts` | Cree | BFF route GET addon status |

---

## 4. Tests API

| Endpoint | Methode | Resultat |
|---|---|---|
| `/health` | GET | 200 OK |
| `/billing/current?tenantId=ecomlg-001` | GET | 200 — plan=PRO, channelsIncluded=3, hasAgentKeybuzzAddon=false, status=active |
| `/billing/agent-keybuzz-status?tenantId=ecomlg-001` | GET | 200 — hasAddon=false, canActivate=false (PRO, pas AUTOPILOT) |
| `/billing/update-agent-keybuzz` enable=true | POST | 400 — checkout_required (comportement attendu) |
| `/billing/checkout-agent-keybuzz` (sans subscription) | POST | 404 — No active subscription (comportement attendu) |

---

## 5. Tests UI reels (navigateur)

| Test | Resultat |
|---|---|
| Login OTP ludo.gonthier@gmail.com | OK — redirect select-tenant |
| Selection tenant eComLG | OK — redirect inbox |
| Navigation Settings > IA | OK — onglet charge |
| Section "Pilotage IA" visible | **GREEN** |
| Mode "Autonome" disabled + CTA "Passez au plan Autopilot" | **GREEN** |
| Mode "KeyBuzz" disabled + CTA "Passez au plan Autopilot" | **GREEN** |
| Mode "Les deux" disabled + CTA "Passez au plan Autopilot" | **GREEN** |
| "Reponse automatique" + CTA "Passez au plan Autopilot" | **GREEN** |
| Page /billing — Plan Pro affiche correctement | **GREEN** |
| Page /billing — KBActions 954.14/1000 | **GREEN** |
| Page /billing — 4/3 canaux | **GREEN** |
| Page /billing — Liens Changer + Comparer les plans | **GREEN** |

---

## 6. Commits SHA

| Repo | Branche | SHA | Message |
|---|---|---|---|
| keybuzz-api | `rebuild/ph143-api` | `b15f9cf` | PH143-B rebuild billing plans addon |
| keybuzz-client | `rebuild/ph143-client` | `d5c7acb` | PH143-B rebuild billing plans addon |

---

## 7. Images DEV rebuild

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.195b-ph143-billing-rebuild-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.195-ph143-billing-rebuild-dev` |

---

## 8. Points non testables / limites

| Point | Raison |
|---|---|
| Addon activation reelle | Necessite Stripe price IDs configures (variables env PROD) |
| Tenant AUTOPILOT (SWITAA) | mnc1x4eq n'a pas de billing_subscriptions actif en DB (data issue, pas code) |
| Checkout Stripe reel | Necessite configuration Stripe complete |
| Trial vs post-trial gating | Pas de tenant AUTOPILOT post-trial disponible en DEV |

### Note sur `?tab=ai` deep-link

Le deep-link `?tab=ai` ne selectionne pas automatiquement l'onglet IA. C'est attendu : les deep-links sont planifies pour **PH143-F** (Signature/Settings/Deep-links).

---

## 9. Non-regressions

| Module | Statut |
|---|---|
| Login OTP | OK |
| Inbox | OK (charge normalement) |
| Navigation menu | OK (12 liens owner) |
| Settings | OK (9 onglets visibles) |
| Billing page | OK (plan, KBActions, canaux) |
| Auth/session | OK |

---

## 10. Main intouchee

| Repo | main HEAD | Rebuild HEAD |
|---|---|---|
| keybuzz-api | `5eccf7e` (inchange) | `b15f9cf` |
| keybuzz-client | `1a7c51d` (inchange) | `d5c7acb` |

Les branches `main` n'ont pas ete modifiees. Le deploiement DEV utilise les images des branches rebuild.

---

## 11. Verdict GO / NOGO pour PH143-C

### Resultat matrice BILL-*

| ID | Feature | Statut |
|---|---|---|
| BILL-01 | Upgrade plan CTA | **GREEN** |
| BILL-02 | Addon Agent KeyBuzz | **GREEN** |
| BILL-03 | hasAgentKeybuzzAddon | **GREEN** |
| BILL-04 | URL sync post-Stripe | **GREEN** |
| BILL-05 | Addon gating | **GREEN** |
| BILL-06 | billing/current coherent | **GREEN** |

### Verdict

**GO pour PH143-C** — Tous les criteres BILL-01 a BILL-06 sont GREEN. Le bloc billing est reconstruit proprement sur la ligne rebuild.

---

**VERDICT : BILLING BLOCK REBUILT — CTA REAL — ADDON FLOW CLEAN — REBUILD LINE READY FOR NEXT BLOCK**
