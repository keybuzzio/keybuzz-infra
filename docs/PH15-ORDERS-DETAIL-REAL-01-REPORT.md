# PH15-ORDERS-DETAIL-REAL-01 â€” DÃ©tail commande rÃ©el + liens "Voir"

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

Remplacer les donnÃ©es mock du dÃ©tail de commande par les donnÃ©es rÃ©elles Amazon via l'API backend existante. Les liens "Voir" dans la liste pointent vers les vrais `orderId`.

---

## Fichiers modifiÃ©s

### Backend (`keybuzz-backend`)

1. **`src/modules/marketplaces/amazon/amazonOrders.service.ts`**
   - Ajout de la fonction `getOrderById(tenantId, orderId)`
   - Retourne les donnÃ©es formatÃ©es pour le frontend

2. **`src/modules/marketplaces/amazon/amazonOrders.routes.ts`**
   - Ajout de la route `GET /api/v1/orders/:orderId`
   - Authentification via `devAuthenticateOrJwt`
   - Scope tenant via `X-Tenant-Id`

3. **`package.json`** : Version bump `1.0.10` â†’ `1.0.11`

### Client (`keybuzz-client`)

1. **`app/api/orders/[orderId]/route.ts`** (NEW)
   - Proxy Next.js pour l'endpoint backend
   - Lecture du cookie `currentTenantId` pour le scope tenant
   - Support Next.js 14 `params` as Promise

2. **`app/orders/[orderId]/page.tsx`**
   - Remplacement du mock data par `fetch('/api/orders/{orderId}')`
   - Gestion des champs PII masquÃ©s
   - Affichage "Client Amazon" ou "Email non disponible (PII)"

3. **`app/orders/page.tsx`**
   - Lien "Voir" pointe vers `/orders/${order.id}` (orderId rÃ©el)

4. **`app/api/auth/select-tenant/route.ts`**
   - Fix: dÃ©finit le cookie `currentTenantId` lors du switch tenant

5. **`app/api/tenant-context/switch/route.ts`**
   - Fix: dÃ©finit le cookie `currentTenantId` lors du switch tenant

6. **`package.json`** : Version bump â†’ `0.2.76-dev`

---

## Preuves E2E (3 commandes diffÃ©rentes)

### Commande #1 : `407-8949262-6149120`

| Champ | Valeur |
|-------|--------|
| **URL** | `/orders/ord_407_8949262_6149120` |
| **Amazon Order ID** | `407-8949262-6149120` |
| **Date** | 22 nov. 2025, 13:00 |
| **Client** | Client Amazon |
| **Email** | `539qbc6prv9q01y@marketplace.amazon.fr` |
| **Adresse** | Toulouse 31300, FR |
| **Total** | **391,84 â‚¬** |

### Commande #2 : `408-2760749-6465943` (AnnulÃ©e)

| Champ | Valeur |
|-------|--------|
| **URL** | `/orders/ord_408_2760749_6465943` |
| **Amazon Order ID** | `408-2760749-6465943` |
| **Date** | 20 nov. 2025, 23:35 |
| **Client** | Client Amazon |
| **Email** | "Email non disponible (PII)" |
| **Adresse** | â€” |
| **Total** | **0,00 â‚¬** |

### Commande #3 : `402-0122851-8807523`

| Champ | Valeur |
|-------|--------|
| **URL** | `/orders/ord_402_0122851_8807523` |
| **Amazon Order ID** | `402-0122851-8807523` |
| **Date** | 19 nov. 2025, 14:29 |
| **Client** | Client Amazon |
| **Email** | `s575697b9p4qyqy@marketplace.amazon.fr` |
| **Adresse** | BREST 29200, FR |
| **Total** | **3 265,18 â‚¬** |

---

## Gestion PII

| Situation | Affichage |
|-----------|-----------|
| Email Amazon disponible | `xxx@marketplace.amazon.fr` |
| Email non disponible | "Email non disponible (PII)" |
| Adresse disponible | Ville + Code postal + Pays |
| Adresse non disponible | "â€”" |
| Nom client | "Client Amazon" (toujours masquÃ©) |

---

## Design

âœ… **Aucune modification du design/UX**
- Layout identique
- Couleurs identiques
- IcÃ´nes identiques
- Actions dÃ©sactivÃ©es avec tooltip "(bientÃ´t)"

---

## Versions dÃ©ployÃ©es

| Service | Version |
|---------|---------|
| `keybuzz-client` | `0.2.76-dev` |
| `keybuzz-backend` | `1.0.11-dev` |

---

## Git Commits

```
keybuzz-backend: feat(orders): add GET /orders/:orderId endpoint
keybuzz-client: feat(orders): real data in order detail page
keybuzz-client: fix(tenant): sync currentTenantId cookie on switch
keybuzz-infra: chore: bump client to 0.2.76-dev, backend to 1.0.11-dev
```

---

## Validation

- [x] API backend `GET /api/v1/orders/:orderId` fonctionne
- [x] Proxy Next.js `/api/orders/[orderId]` fonctionne
- [x] Liens "Voir" pointent vers les vrais orderId
- [x] Page dÃ©tail charge les donnÃ©es rÃ©elles
- [x] PII correctement masquÃ©
- [x] 3 commandes diffÃ©rentes testÃ©es en navigation rÃ©elle
- [x] Aucune modification du design
- [x] Cookie `currentTenantId` synchronisÃ©

---

## Notes

- Les dÃ©tails des produits ne sont pas encore disponibles (Amazon SP-API ne retourne pas les items dans la requÃªte getOrders - nÃ©cessite getOrderItems sÃ©parÃ©)
- Les conversations liÃ©es ne sont pas encore implÃ©mentÃ©es
- Les actions (retour, garantie, remboursement) sont dÃ©sactivÃ©es avec tooltip "bientÃ´t"
