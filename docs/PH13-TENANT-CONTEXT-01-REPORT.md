# PH13-TENANT-CONTEXT-01 — Rapport Multi-Tenant

**Date:** 2026-01-06  
**Environnement:** DEV uniquement  
**Statut:** ✅ COMPLET (API + Client)

---

## 1. Résumé

✅ **API Multi-tenant fonctionnelle**  
✅ **Client Multi-tenant fonctionnel** (TenantProvider, TenantSwitcher)

L'API expose des endpoints pour la gestion multi-tenant via le header `X-User-Email` (DEV bridge).  
Le client intègre un `TenantProvider` et un `TenantSwitcher` pour la gestion du tenant courant.

---

## 2. Schéma DB

Tables créées (PostgreSQL DEV) :

```sql
-- users: stocke les utilisateurs
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- user_tenants: mapping utilisateurs ↔ tenants
CREATE TABLE user_tenants (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id VARCHAR(50) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'agent' CHECK (role IN ('owner', 'admin', 'agent')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, tenant_id)
);

-- user_preferences: préférences utilisateur (tenant courant)
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_tenant_id VARCHAR(50),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 3. Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/tenant-context/me` | GET | Retourne l'utilisateur et ses tenants |
| `/tenant-context/tenants` | GET | Liste des tenants de l'utilisateur |
| `/tenant-context/switch` | POST | Change le tenant courant |

### Header requis

```
X-User-Email: <email>
```

### Exemple de réponse `/tenant-context/me`

```json
{
  "user": {
    "id": "a958e819-483f-41c2-8750-6343436dd62c",
    "email": "demo@keybuzz.io",
    "name": "demo"
  },
  "tenants": [
    { "id": "kbz-001", "name": "KeyBuzz Demo", "role": "owner" },
    { "id": "kbz-002", "name": "KeyBuzz Test", "role": "admin" }
  ],
  "currentTenantId": "kbz-001"
}
```

---

## 4. Composants Client

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `src/lib/apiClient.ts` | Client API avec injection `X-User-Email` |
| `src/features/tenant/TenantProvider.tsx` | Provider React pour le contexte tenant |
| `src/features/tenant/components/TenantSwitcher.tsx` | Dropdown pour changer de tenant |
| `src/features/tenant/index.ts` | Exports |

### Usage

```tsx
import { TenantProvider, useTenant, TenantSwitcher } from '@/src/features/tenant';

// Dans le layout
<TenantProvider>
  <App />
</TenantProvider>

// Dans un composant
const { currentTenantId, tenants, setCurrentTenant } = useTenant();

// Dans la topbar
<TenantSwitcher />
```

---

## 5. DEV Bootstrap

En environnement DEV, si un utilisateur n'existe pas ou n'a pas de tenant mappé :
- L'utilisateur est automatiquement créé
- Les tenants `kbz-001` et `kbz-002` sont automatiquement assignés

---

## 6. Versions Déployées

| Service | Version | Image |
|---------|---------|-------|
| keybuzz-api | v0.1.59-dev | ghcr.io/keybuzzio/keybuzz-api:v0.1.59-dev |
| keybuzz-client | v0.2.30-dev | ghcr.io/keybuzzio/keybuzz-client:v0.2.30-dev |

---

## 7. TODO (Phase suivante)

- [ ] Intégrer `TenantProvider` dans le layout global
- [ ] Ajouter `TenantSwitcher` dans la topbar
- [ ] Supprimer les `kbz-001` hardcodés
- [ ] Remplacer le header `X-User-Email` par JWT serveur (PROD)

---

## 8. Sécurité

- ⚠️ Le header `X-User-Email` est un bridge DEV uniquement
- ✅ Aucun secret exposé
- TODO: Remplacer par JWT serveur en PROD

---

**Fin du rapport PH13-TENANT-CONTEXT-01**
