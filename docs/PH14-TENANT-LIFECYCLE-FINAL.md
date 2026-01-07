# PH14-TENANT-LIFECYCLE — Rapport Final

**Date**: 2026-01-07  
**Status**: ✅ COMPLETED  
**API Version**: v0.1.70-dev → v0.1.71-dev  
**Client Version**: v0.2.33-dev

---

## 📋 Résumé Exécutif

PH14 implémente le cycle de vie complet des tenants dans KeyBuzz avec trois états :
- **active** : Tenant pleinement opérationnel
- **archived** : Tenant désactivé, données préservées, réactivation possible
- **deleted** : Tenant supprimé (soft-delete), réactivation interdite via UI

---

## 🔧 Endpoints API

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/tenant-lifecycle/:id/status` | Récupérer le statut du tenant |
| POST | `/tenant-lifecycle/:id/archive` | Archiver le tenant |
| POST | `/tenant-lifecycle/:id/reactivate` | Réactiver un tenant archivé |
| POST | `/tenant-lifecycle/:id/soft-delete` | Supprimer le tenant (soft) |

### Règles métier

```
active → archive → archived ✓
archived → reactivate → active ✓
active → soft-delete → deleted ✓
archived → soft-delete → deleted ✓
deleted → reactivate → INTERDIT (400) ✗
deleted → archive → INTERDIT (400) ✗
```

---

## 🔐 Sécurité DEV/PROD

### DEV_SKIP_AUTH Guard

```typescript
// Actif uniquement en DEV
const DEV_SKIP_AUTH = process.env.NODE_ENV !== 'production';

if (!DEV_SKIP_AUTH && !userEmail) {
  return reply.status(401).send({ error: 'Authentication required' });
}
```

En production (`NODE_ENV=production`) :
- `DEV_SKIP_AUTH` est toujours `false`
- L'authentification par header `x-user-email` est obligatoire
- La route `force-reset` n'existe pas (supprimée)

---

## ✅ Tests E2E Validés

| # | Action | Résultat | Status |
|---|--------|----------|--------|
| 1 | GET /status (initial) | `active` | ✅ |
| 2 | POST /archive | `archived` | ✅ |
| 3 | GET /status | `archived_at` défini | ✅ |
| 4 | POST /reactivate | `active` | ✅ |
| 5 | GET /status | `archived_at` null | ✅ |
| 6 | POST /soft-delete | `deleted` | ✅ |
| 7 | GET /status | `deleted_at` défini | ✅ |
| 8 | POST /reactivate (deleted) | 400 Error | ✅ |

---

## 📦 Déploiement

### API
- **Namespace**: `keybuzz-api-dev`
- **Image**: `ghcr.io/keybuzzio/keybuzz-api:v0.1.71-dev`
- **Fichier modifié**: `src/modules/tenants/tenant-lifecycle-routes.ts`

### Client
- **Namespace**: `keybuzz-client-dev`
- **Page**: `/settings/tenant`
- **Fichier modifié**: `app/settings/tenant/page.tsx`

---

## 📝 Schéma DB

```sql
-- Table tenants
ALTER TABLE tenants ADD COLUMN status VARCHAR(20) DEFAULT 'active';
ALTER TABLE tenants ADD CONSTRAINT tenants_status_check 
  CHECK (status IN ('active', 'archived', 'deleted'));
CREATE INDEX idx_tenants_status ON tenants (status);
```

---

## 🎯 Prochaines étapes (PROD)

1. [ ] Implémenter vérification des rôles admin (`hasAdminAccess`)
2. [ ] Configurer header `x-user-email` via ingress/middleware
3. [ ] Ajouter annulation Stripe lors de l'archivage
4. [ ] Filtrer les tenants non-active dans TenantSwitcher
5. [ ] Rediriger automatiquement si tenant courant devient archived/deleted

---

## Commits Git

| Repository | Message |
|------------|---------|
| keybuzz-api | `fix(PH14): guard dev skip auth + remove force reset v0.1.71-dev` |
| keybuzz-client | `PH14-TENANT-LIFECYCLE-02: Fix client URLs` |
| keybuzz-infra | `docs(PH14): finalize tenant lifecycle report` |

---

**PH14 CLÔTURÉE** ✅
