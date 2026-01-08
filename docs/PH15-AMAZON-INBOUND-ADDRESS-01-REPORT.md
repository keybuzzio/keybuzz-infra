# PH15-AMAZON-INBOUND-ADDRESS-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Implémentation de la génération automatique d'adresse email inbound Amazon après OAuth CONNECTED.

---

## 1. Service Utilisé

### Fichier : `src/modules/inboundEmail/inboundEmailAddress.service.ts`

```typescript
// Format canonique
amazon.<tenantId>.<country>.<token>@inbound.keybuzz.io

// Fonctions
- buildInboundAddress({ marketplace, tenantId, country, token })
- generateToken(length = 6)  // alphanumérique
- ensureInboundConnection({ tenantId, marketplace, countries })
```

---

## 2. Modifications Appliquées

### A) Callback OAuth (`amazon.routes.ts`)

Après `completeAmazonOAuth()`, création automatique de l'adresse :

```typescript
// PH15: Create inbound email address after CONNECTED
try {
  await ensureInboundConnection({
    tenantId: oauthState.tenantId,
    marketplace: "amazon",
    countries: ["FR"],
  });
  console.log("[Amazon OAuth] Inbound address created for", tenantId);
} catch (inboundErr) {
  console.warn("[Amazon OAuth] Failed to create inbound address:", inboundErr);
  // Don't fail the whole callback for this
}
```

### B) Nouvel Endpoint

```
GET /api/v1/marketplaces/amazon/inbound-address
Headers: X-User-Email, X-Tenant-Id
Query: ?country=FR (optional, default FR)

Response (success):
{
  "address": "amazon.kbz-001.fr.a1b2c3@inbound.keybuzz.io",
  "country": "FR",
  "status": "PENDING"
}

Response (not connected):
{
  "error": "Amazon not connected",
  "message": "Connect Amazon first to get inbound address"
}
```

---

## 3. Format Adresse Confirmé

```
amazon.<tenantId>.<country>.<token>@inbound.keybuzz.io
```

Exemple :
```
amazon.kbz-001.fr.x7y8z9@inbound.keybuzz.io
```

- Token : 6 caractères alphanumériques
- Généré une seule fois, persisté en DB

---

## 4. Tables Utilisées

| Table | Champs Clés |
|-------|-------------|
| `InboundConnection` | tenantId, marketplace, countries, status |
| `InboundAddress` | tenantId, marketplace, country, token, emailAddress |

---

## 5. Preuve Endpoint

```bash
# Tenant non connecté
curl backend-dev/api/v1/marketplaces/amazon/inbound-address \
  -H "X-User-Email: ludo.gonthier@gmail.com" \
  -H "X-Tenant-Id: kbz-001"

# Réponse
{"error":"Amazon not connected","message":"Connect Amazon first to get inbound address"}

# Après OAuth CONNECTED → retournerait l'adresse générée
```

---

## 6. Version Déployée

| Composant | Version |
|-----------|---------|
| keybuzz-backend | **v1.0.2-dev** |

---

## 7. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `8bc1790` | feat(PH15): inbound address generation + endpoint |
| keybuzz-infra | `cf79b3a` | feat: backend-dev v1.0.2 inbound address |

---

**Fin du rapport PH15-AMAZON-INBOUND-ADDRESS-01**
