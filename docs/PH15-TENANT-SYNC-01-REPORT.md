# PH15-TENANT-SYNC-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Implémentation d'endpoints de synchronisation tenant entre les deux bases de données :
- **keybuzz** (product) : tenants côté application
- **keybuzz_backend** (marketplace) : tenants côté intégrations marketplace

---

## 1. Endpoints Créés

### POST /api/v1/tenants/sync

Synchronise un tenant individuel avec création optionnelle d'inbound address.

**Payload** :
```json
{
  "tenantId": "ecomlg-001",
  "createInboundAddress": true,
  "country": "FR"
}
```

**Réponse** :
```json
{
  "success": true,
  "tenant": {
    "id": "ecomlg-001",
    "name": "eComLG",
    "plan": "PRO",
    "status": "ACTIVE"
  },
  "inboundAddress": "amazon.ecomlg-001.fr.cp2hat@inbound.keybuzz.io"
}
```

### POST /api/v1/tenants/sync-all

Synchronise tous les tenants de la DB product vers la DB marketplace.

**Réponse** :
```json
{
  "success": true,
  "total": 6,
  "results": {
    "created": ["kbz-003", "kbz-004"],
    "updated": [],
    "skipped": ["kbz-001", "kbz-002", "ecomlg-001", "tenant_test_dev"],
    "errors": []
  }
}
```

### GET /api/v1/tenants/status/:tenantId

Vérifie le statut de synchronisation d'un tenant.

**Réponse** :
```json
{
  "tenantId": "ecomlg-001",
  "product": {
    "exists": true,
    "name": "eComLG",
    "plan": "pro",
    "status": "active"
  },
  "marketplace": {
    "exists": true,
    "name": "eComLG",
    "plan": "PRO",
    "status": "ACTIVE"
  },
  "inSync": true,
  "inboundAddresses": [
    {
      "marketplace": "AMAZON",
      "country": "FR",
      "email": "amazon.ecomlg-001.fr.cp2hat@inbound.keybuzz.io",
      "status": "PENDING"
    }
  ],
  "marketplaceConnections": []
}
```

---

## 2. Fichiers Créés/Modifiés

| Fichier | Action |
|---------|--------|
| `src/modules/tenants/tenantSync.routes.ts` | CRÉÉ |
| `src/main.ts` | MODIFIÉ (import + register) |
| `package.json` | MODIFIÉ (version 1.0.5) |

---

## 3. Comportement du Sync

### Création Tenant

1. Vérifie si le tenant existe dans DB product (`keybuzz.tenants`)
2. Si absent → erreur 404
3. Si présent mais absent de DB marketplace → crée le tenant
4. Si déjà présent → update si changements (name, plan, status)

### Création Inbound Address (si `createInboundAddress: true`)

1. Crée `inbound_connections` si absent
2. Crée `inbound_addresses` avec :
   - Token généré (6 chars)
   - Email format : `amazon.<tenantId>.<country>.<token>@inbound.keybuzz.io`
   - Status : PENDING

---

## 4. État Avant/Après Sync

### Avant Sync

| DB Product | DB Marketplace |
|------------|----------------|
| ecomlg-001 ✓ | ecomlg-001 ✓ |
| kbz-001 ✓ | kbz-001 ✓ |
| kbz-002 ✓ | kbz-002 ✓ |
| **kbz-003 ✓** | ❌ |
| **kbz-004 ✓** | ❌ |
| tenant_test_dev ✓ | tenant_test_dev ✓ |

### Après Sync-All

| DB Product | DB Marketplace |
|------------|----------------|
| ecomlg-001 ✓ | ecomlg-001 ✓ |
| kbz-001 ✓ | kbz-001 ✓ |
| kbz-002 ✓ | kbz-002 ✓ |
| kbz-003 ✓ | **kbz-003 ✓** |
| kbz-004 ✓ | **kbz-004 ✓** |
| tenant_test_dev ✓ | tenant_test_dev ✓ |

---

## 5. Authentification

- Mode DEV (`KEYBUZZ_DEV_MODE=true`) : pas de clé requise
- Mode PROD : `X-Internal-Key` header requis

---

## 6. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-backend | v1.0.5-dev |
| Commit | ec926dd |

---

## 7. Usage Recommandé

### Lors de l'onboarding

Après création d'un tenant dans keybuzz (product), appeler :
```bash
POST /api/v1/tenants/sync
{
  "tenantId": "nouveau-tenant-001",
  "createInboundAddress": true,
  "country": "FR"
}
```

### Sync manuel (maintenance)

Pour synchroniser tous les tenants :
```bash
POST /api/v1/tenants/sync-all
```

### Vérification

Pour vérifier le statut d'un tenant :
```bash
GET /api/v1/tenants/status/{tenantId}
```

---

## 8. Points d'Amélioration (PROD)

| Point | Recommandation |
|-------|----------------|
| Webhook de création | Appeler sync automatiquement lors de création tenant product |
| Event-driven | Utiliser un event bus (Redis Pub/Sub) pour la sync |
| Multi-country | Créer les addresses pour tous les pays actifs |
| Archivage | Répercuter `status=archived` côté marketplace |

---

**Fin du rapport PH15-TENANT-SYNC-01**
