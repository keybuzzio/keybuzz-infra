# PH-TENANT-ISOLATION-ORDER-PANEL-CRITICAL-01 — Rapport

> Date : 2026-03-27
> Gravite : CRITIQUE — fuite de donnees inter-tenant
> Environnements : DEV + PROD

---

## 1. Probleme

Depuis le tenant SWITAA, le panneau commandes a droite de l'inbox retrouvait et affichait des commandes appartenant au tenant eComLG. Des emails forwardes ("TR: Confirmation de commande...") contenant des references de commandes eComLG declenchaient l'auto-import, qui creait des ordres fantomes dans le tenant SWITAA.

### Scenario reproduit

1. SWITAA recoit un email forwarde contenant une reference de commande eComLG (ex: `404-9154083-2636361`)
2. La conversation est creee dans SWITAA avec `order_ref = 404-9154083-2636361`
3. L'utilisateur ouvre la conversation dans l'inbox
4. Le `OrderSidePanel` detecte l'`orderRef` et lance `resolveOrderId`
5. Pas de resultat → l'auto-import se declenche → `POST /api/orders/import-one`
6. L'import appelle Amazon SP-API avec les credentials SWITAA
7. SP-API retourne HTTP 200 mais avec un **payload vide** `{ payload: {} }`
8. Le code fait `if (amzData && amzData.order)` — l'objet vide `{}` est **truthy**
9. Un phantom order est cree avec `status: Unknown`, `amount: 0`, `products: []`
10. Le panneau affiche ce phantom order

### Evidence DB

**Phantom orders SWITAA (avant fix) :**

| ID | Ref (eComLG) | Status | Amount | Products |
|---|---|---|---|---|
| ord-mn9797t9-bc3a0m | 404-9154083-2636361 | Unknown | 0.00 | [] |
| ord-mn97991f-ckhlyc | 404-9154083-2636361 | Unknown | 0.00 | [] |
| ord-mn9739c2-97mm89 | 406-9765346-1305900 | Unknown | 0.00 | [] |
| ord-mn979zg7-ibr228 | 407-1807346-9057122 | Unknown | 0.00 | [] |

**Vrais orders SWITAA (preserves) :**

| ID | Ref | Status | Amount |
|---|---|---|---|
| ord-mn97ahlm-bnl9zw | 406-1698997-0724356 | Shipped | 87.27 |
| ord-mn97ai71-tu6pde | 403-9026935-3766764 | Unshipped | 118.96 |

**eComLG memes refs (donnees reelles) :**

| Ref | Status | Amount |
|---|---|---|
| 404-9154083-2636361 | Unshipped | 869.00 |
| 406-9765346-1305900 | Unshipped | 265.97 |

---

## 2. Chaine complete tracee

```
UI: OrderSidePanel (composant React)
  → resolveOrderId() → GET /api/orders?q=<orderRef>
  → auto-import si non trouve → POST /api/orders/import-one

BFF: app/api/orders/route.ts
  → lit currentTenantId depuis cookie
  → passe X-Tenant-Id header au backend

BFF: app/api/orders/import-one/route.ts
  → forward POST vers BACKEND_URL/api/v1/orders/import-one
  → passe X-Tenant-Id + X-User-Email

API: src/modules/orders/routes.ts
  → POST /api/v1/orders/import-one handler
  → check existing → check active channel → fetchAmazonOrder() → import ou stub

API: fetchAmazonOrder()
  → lit credentials Vault pour le tenant
  → appelle SP-API GET /orders/v0/orders/{orderRef}
  → retourne { order: payload, items: [], packages: [] }
```

### Garde-fous tenant existants

| Point | Filtre tenant | Status |
|---|---|---|
| GET /api/v1/orders (search) | `WHERE tenant_id = $1` | OK |
| GET /api/v1/orders/:orderId | `WHERE id = $1 AND tenant_id = $2` | OK |
| POST /api/v1/orders/import-one (existing check) | `WHERE tenant_id = $1 AND external_order_id = $2` | OK |
| POST /api/v1/orders/import-one (channel check) | `WHERE tenant_id = $1 AND provider = 'amazon' AND status = 'active'` | OK |
| POST /api/v1/orders/import-one (SP-API validation) | **ABSENT — ROOT CAUSE** | FIX APPLIQUE |

---

## 3. Root Cause

**Deux defauts dans `import-one` :**

### Defaut 1 : Pas de validation du payload SP-API

`fetchAmazonOrder` retournait `{ order: {}, items: [], packages: [] }` quand SP-API repondait 200 avec un payload vide (ordre non accessible pour ce vendeur). L'objet vide `{}` passait le check `if (amzData && amzData.order)` car un objet vide est truthy en JavaScript.

### Defaut 2 : Fallback stub trop permissif

Quand SP-API echouait (retour null), le handler creait un ordre "stub" minimal dans le tenant courant au lieu de retourner une erreur 404. Cela creait des phantom orders pour n'importe quelle reference de commande mentionnee dans un email.

---

## 4. Corrections appliquees

### Fix 1 : Validation payload vide dans `fetchAmazonOrder`

Fichier : `/opt/keybuzz/keybuzz-api/src/modules/orders/routes.ts`

```javascript
const orderData = (await orderRes.json() as any).payload;
if (!orderData || Object.keys(orderData).length === 0) {
  console.warn(`[Orders] SP-API returned empty order payload for ${orderRef}`);
  return null;
}
```

### Fix 2 : Validation OrderStatus dans `import-one`

```javascript
// AVANT (BUG) :
if (amzData && amzData.order) {

// APRES (FIX) :
if (amzData && amzData.order && amzData.order.OrderStatus) {
```

### Fix 3 : Suppression du fallback stub

```javascript
// AVANT : creation d'un stub order
} else {
  const convResult = await client.query(...);
  await client.query('INSERT INTO orders ...');
  return reply.send({ source: 'stub' });
}

// APRES : retour 404
} else {
  return reply.status(404).send({
    error: 'Commande introuvable sur Amazon pour ce compte',
    code: 'ORDER_NOT_FOUND_FOR_TENANT'
  });
}
```

### Fix 4 : Nettoyage des phantom orders

- **DEV** : 4 phantom orders supprimes (SWITAA)
- **PROD** : 1 phantom order supprime (SWITAA)
- eComLG : 0 ordres touches (11914 DEV, 11814 PROD inchanges)

---

## 5. Images deployees

| Service | DEV | PROD |
|---|---|---|
| keybuzz-api | `v3.5.50-ph-tenant-iso-dev` | `v3.5.50-ph-tenant-iso-prod` |

---

## 6. Validation DEV

| Test | Resultat |
|---|---|
| SWITAA phantom orders = 0 | OK |
| SWITAA real orders preserves (2) | OK |
| eComLG orders intactes (11914) | OK |
| Cross-tenant SWITAA↔eComLG = 0 | OK |
| API health | OK |

**Verdicts DEV :**
- TENANT ISOLATION DEV = **OK**
- ORDER PANEL DEV = **OK**
- NO CROSS-TENANT DEV = **OK**
- DEV NO REGRESSION = **OK**

---

## 7. Validation PROD

| Test | Resultat |
|---|---|
| SWITAA phantom orders = 0 | OK |
| SWITAA real orders preserves (2) | OK |
| eComLG orders intactes (11814) | OK |
| Cross-tenant SWITAA↔eComLG = 0 | OK |
| API health | OK |

**Verdicts PROD :**
- TENANT ISOLATION PROD = **OK**
- ORDER PANEL PROD = **OK**
- NO CROSS-TENANT PROD = **OK**
- PROD NO REGRESSION = **OK**

---

## 8. Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-import-isolation-dev -n keybuzz-api-dev

# PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-import-isolation-prod -n keybuzz-api-prod
```

Note : le rollback restaure le code mais pas les phantom orders supprimes. Les phantom orders ne seront pas recrees car ils necessitaient un auto-import actif.

---

## 9. Verdict Final

### TENANT ISOLATION RESTORED AND VALIDATED

Les trois niveaux de protection sont en place :
1. **Requetes SQL** : filtre `tenant_id` sur search, detail, import (pre-existant, OK)
2. **Validation SP-API** : rejet des payloads vides et des ordres sans OrderStatus (NOUVEAU)
3. **Suppression stub** : plus de creation de phantom orders sur echec SP-API (NOUVEAU)
