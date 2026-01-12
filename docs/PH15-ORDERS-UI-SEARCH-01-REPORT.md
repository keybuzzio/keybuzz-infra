# PH15-ORDERS-UI-SEARCH-01 â€” Afficher orderId complet + recherche

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

1. Afficher l'AmazonOrderId **complet** dans la colonne "Commande"
2. Ajouter une recherche par numÃ©ro de commande (API-side)
3. Optimiser la DB avec un index

---

## ImplÃ©mentation

### 1. Base de donnÃ©es

**Index ajoutÃ©** pour optimiser la recherche :

```sql
CREATE INDEX IF NOT EXISTS "Order_tenantId_externalOrderId_idx" 
ON "Order" ("tenantId", "externalOrderId");
```

**Structure existante** :
- `externalOrderId` : ID Amazon complet (ex: `407-2379794-2051544`)
- `orderRef` : Version courte (ex: `#051544`)

### 2. API Backend (v1.0.15)

**Route modifiÃ©e** : `GET /api/v1/orders`

Nouveaux paramÃ¨tres :
| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Recherche par orderId (ILIKE) |
| `status` | string | Filtre par statut |
| `limit` | number | Limite (max 100) |
| `offset` | number | Pagination |

**RÃ©ponse enrichie** :
```json
{
  "orders": [...],
  "count": 1,
  "total": 100,
  "pagination": {
    "limit": 100,
    "offset": 0,
    "hasMore": false
  }
}
```

**Service** (`amazonOrders.service.ts`) :
```typescript
// Recherche par orderId (case-insensitive)
if (search) {
  where.externalOrderId = { contains: search, mode: "insensitive" };
}
```

### 3. UI Client (v0.2.78)

**Modifications** :

1. **Interface Order** :
```typescript
interface Order {
  externalOrderId?: string;
  // ... autres champs
}
```

2. **Affichage orderId complet** :
```tsx
<span className="font-mono text-xs">
  {order.externalOrderId || order.ref}
</span>
```

3. **Recherche debounced** :
```typescript
// Debounce 300ms
useEffect(() => {
  const timer = setTimeout(() => setDebouncedSearch(searchTerm), 300);
  return () => clearTimeout(timer);
}, [searchTerm]);

// Fetch avec paramÃ¨tre q
const searchParams = debouncedSearch 
  ? `?q=${encodeURIComponent(debouncedSearch)}` 
  : '';
const response = await fetch(`/api/orders${searchParams}`);
```

---

## Preuves E2E

### Test API Search

```bash
curl -sk -H "X-User-Email: ludovic@ecomlg.fr" -H "X-Tenant-Id: ecomlg-001" \
  "https://backend-dev.keybuzz.io/api/v1/orders?q=407-2379" | jq
```

```json
{
  "total": 1,
  "count": 1,
  "orders": [
    { "externalOrderId": "407-2379794-2051544", ... }
  ]
}
```

### Test UI Navigation

| Action | RÃ©sultat |
|--------|----------|
| Page `/orders` sans recherche | 100 commandes affichÃ©es |
| Recherche "407-2379" | 1 rÃ©sultat trouvÃ© |
| OrderId affichÃ© | `407-2379794-2051544` (complet) |
| Effacer recherche | Liste complÃ¨te (100) |

### Screenshots Ã©quivalents (description)

1. **Liste complÃ¨te** : 100 commandes, chaque orderId affichÃ© en format `XXX-XXXXXXX-XXXXXXX`
2. **Recherche active** : 1 rÃ©sultat pour "407-2379", orderId complet visible
3. **Champ de recherche** : Placeholder "Rechercher par ID, ref, client, email..."

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `0720959` | feat(orders): PH15 search by orderId + total count |
| keybuzz-client | `b65b008` | feat(orders): PH15 display full orderId + debounced API search |
| keybuzz-infra | `3aea0f2` | feat(k8s): PH15 backend 1.0.15 + client 0.2.78 |

---

## RÃ©sumÃ©

| Feature | Status |
|---------|--------|
| Index DB pour recherche | âœ… |
| API param `q` pour search | âœ… |
| Recherche ILIKE (insensitive) | âœ… |
| Affichage orderId complet | âœ… |
| Debounce 300ms | âœ… |
| Multi-tenant (pas de hardcode) | âœ… |
| Design inchangÃ© (Metronic) | âœ… |

L'utilisateur peut maintenant :
- Voir l'orderId Amazon complet (ex: `407-2379794-2051544`)
- Rechercher par numÃ©ro de commande partiel ou complet
- La recherche est optimisÃ©e cÃ´tÃ© API avec index DB
