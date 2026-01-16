# PH-MVP-INBOUND-SOURCE-OF-TRUTH-01 — Adresse Inbound Source of Truth

**Date** : 2026-01-15  
**Statut** : ✅ TERMINÉ

---

## Résumé Exécutif

L'adresse inbound Amazon est maintenant **source of truth persistée en DB**, immuable côté client. Seuls les administrateurs peuvent régénérer une adresse.

---

## 1️⃣ TABLE INBOUND_ADDRESSES

### Structure existante (déjà en place)

```sql
TABLE inbound_addresses (
    id TEXT PRIMARY KEY,
    connectionId TEXT NOT NULL,
    tenantId TEXT NOT NULL,
    marketplace TEXT NOT NULL,      -- 'amazon'
    country TEXT NOT NULL,          -- 'FR', 'DE', etc.
    token TEXT NOT NULL,            -- Token unique généré
    emailAddress TEXT NOT NULL,     -- Adresse complète
    pipelineStatus TEXT,            -- 'PENDING', 'VALIDATED'
    marketplaceStatus TEXT,         -- 'PENDING', 'VALIDATED'
    lastInboundAt TIMESTAMP,        -- Mis à jour à chaque email
    createdAt TIMESTAMP,
    updatedAt TIMESTAMP
)
```

### Contrainte UNIQUE (déjà présente)

```sql
-- Index UNIQUE sur (tenantId, marketplace, country)
inbound_addresses_tenantId_marketplace_country_key
```

**✅ Garantit unicité : 1 seule adresse par tenant/marketplace/country**

---

## 2️⃣ GÉNÉRATION UNIQUE

### Service `ensureInboundConnection`

```typescript
// src/modules/inboundEmail/inboundEmailAddress.service.ts

export async function ensureInboundConnection(params: {
  tenantId: string;
  marketplace: string;
  countries: string[];
}) {
  // 1. Upsert connection (crée si n'existe pas)
  const connection = await prisma.inboundConnection.upsert({...});

  // 2. Pour chaque country, créer adresse SEULEMENT si n'existe pas
  for (const country of countries) {
    const existing = await prisma.inboundAddress.findUnique({
      where: {
        tenantId_marketplace_country: { tenantId, marketplace, country },
      },
    });

    if (!existing) {
      const token = generateToken();
      await prisma.inboundAddress.create({...});
    }
    // Si existe → rien ne change (source of truth)
  }
}
```

**✅ L'adresse est générée UNE SEULE FOIS et jamais modifiée**

---

## 3️⃣ UI AFFICHE ADRESSE PERSISTÉE

### Route GET `/api/v1/marketplaces/amazon/inbound-address`

```typescript
// 1. Cherche adresse existante
const existingAddress = await prisma.inboundAddress.findUnique({
  where: {
    tenantId_marketplace_country: { tenantId, marketplace, country },
  },
});

// 2. Si existe → retourne (pas de régénération)
if (existingAddress) {
  return reply.send({
    address: existingAddress.emailAddress,
    status: existingAddress.pipelineStatus,
  });
}

// 3. Si n'existe pas → crée via ensureInboundConnection
// (UNE SEULE FOIS)
```

### Frontend `StepAmazonMessages`

```typescript
// L'UI fetch l'adresse depuis le backend
const response = await fetch(`/api/amazon/inbound-address?...`);
const data = await response.json();
setInboundEmail(data.address); // Affiche l'adresse persistée
```

**✅ L'UI ne génère jamais d'adresse côté client**

---

## 4️⃣ RÉGÉNÉRATION ADMIN ONLY

### Route protégée (PH-MVP-INBOUND-SOURCE-OF-TRUTH-01)

```typescript
// POST /addresses/:id/regenerate
server.post("/addresses/:id/regenerate", async (request, reply) => {
  const user = request.user;

  // PH-MVP-INBOUND-SOURCE-OF-TRUTH-01: Admin only
  const allowedRoles = ["super_admin", "admin", "owner"];
  if (!allowedRoles.includes(user.role)) {
    return reply.status(403).send({ 
      error: "Forbidden: admin access required for address regeneration",
      message: "Inbound addresses are immutable."
    });
  }

  // ... régénération autorisée pour admin
});
```

### Test de protection

```bash
# Agent normal → 403 Forbidden
curl -X POST /api/v1/inbound-email/addresses/:id/regenerate
# → {"error":"Forbidden: admin access required for address regeneration"}

# Admin → 200 OK (peut régénérer)
```

**✅ Seuls admin/owner/super_admin peuvent régénérer**

---

## 5️⃣ VALIDATION AUTOMATIQUE

### Mise à jour `lastInboundAt`

Quand un email arrive sur l'adresse inbound :

```typescript
// Dans inbound.service.ts
await prisma.inboundAddress.update({
  where: { id: address.id },
  data: {
    pipelineStatus: 'VALIDATED',
    lastInboundAt: new Date(),
    lastInboundMessageId: messageId,
  },
});
```

**✅ `lastInboundAt` sert de preuve de validation**

---

## 6️⃣ FLUX COMPLET

```
┌─────────────────────────────────────────────────────────────────┐
│                    GÉNÉRATION ADRESSE                           │
├─────────────────────────────────────────────────────────────────┤
│ 1. Tenant connecte Amazon                                       │
│ 2. Backend appelle ensureInboundConnection()                    │
│ 3. Vérifie si adresse existe → findUnique()                     │
│    ├─ Existe    → Retourne existante (pas de changement)        │
│    └─ N'existe pas → Génère token + crée en DB                  │
│ 4. Contrainte UNIQUE garantit unicité                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    AFFICHAGE UI                                 │
├─────────────────────────────────────────────────────────────────┤
│ 1. UI fetch GET /api/v1/marketplaces/amazon/inbound-address     │
│ 2. Backend retourne adresse persistée                           │
│ 3. UI affiche l'adresse (jamais de génération côté client)      │
│ 4. Pas de bouton "Régénérer" visible pour agent                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    RÉGÉNÉRATION (ADMIN ONLY)                    │
├─────────────────────────────────────────────────────────────────┤
│ 1. Admin POST /addresses/:id/regenerate                         │
│ 2. Backend vérifie role ∈ [super_admin, admin, owner]           │
│ 3. Agent → 403 Forbidden                                        │
│ 4. Admin → Nouveau token généré, emailAddress mis à jour        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7️⃣ VERSION DÉPLOYÉE

| Composant | Version | Notes |
|-----------|---------|-------|
| keybuzz-backend | 1.0.27 | + protection admin /regenerate |
| DB | Inchangée | Contrainte UNIQUE existante |

---

## 8️⃣ TESTS DE VALIDATION

### Test 1: Unicité garantie

```sql
-- Tentative de création dupliquée
INSERT INTO inbound_addresses (tenantId, marketplace, country, ...)
VALUES ('tenant1', 'amazon', 'FR', ...);
-- → ERROR: duplicate key violates unique constraint
```

### Test 2: UI n'appelle pas régénération

```javascript
// Frontend StepAmazonMessages.tsx
// Pas de bouton "Régénérer" pour l'utilisateur
// Uniquement fetch GET pour afficher l'adresse existante
```

### Test 3: Route protégée

```bash
# Sans admin role
curl -X POST .../addresses/123/regenerate -H "Authorization: Bearer <agent_token>"
# → 403 Forbidden

# Avec admin role
curl -X POST .../addresses/123/regenerate -H "Authorization: Bearer <admin_token>"
# → 200 OK (régénération autorisée)
```

---

## Conclusion

### ✅ OBJECTIFS ATTEINTS

1. **Table avec UNIQUE constraint** : `(tenantId, marketplace, country)` ✅
2. **Génération une seule fois** : `findUnique` avant create ✅
3. **UI affiche adresse persistée** : Fetch depuis backend ✅
4. **Client ne peut pas régénérer** : Pas de bouton, route protégée ✅
5. **Admin only pour regenerate** : Role check ajouté ✅
6. **lastInboundAt mis à jour** : À chaque email reçu ✅

### PRODUCTION READY ✅

L'adresse inbound Amazon est maintenant une source of truth immuable côté client. Seuls les administrateurs peuvent la modifier en cas de besoin.
