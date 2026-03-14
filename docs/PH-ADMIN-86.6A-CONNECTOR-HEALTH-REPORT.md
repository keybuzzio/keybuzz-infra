# PH-ADMIN-86.6A — Channels & Connector Health — Report

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.12.0-ph86.6a-connector-health`
**Statut** : DEV + PROD deployes

---

## 1. Audit des tables connecteurs

### Tables exploitees

| Table | Lignes DEV | Colonnes cles | Usage |
|---|---|---|---|
| `tenant_channels` | 11 (2 tenants) | tenant_id, provider, marketplace_key, display_name, status, inbound_email, connected_at, disconnected_at | Source principale — vue canaux par tenant |
| `inbound_addresses` | 1 | tenantId, emailAddress, validationStatus, pipelineStatus, marketplaceStatus, lastInboundAt, lastError | Sante inbound email |
| `inbound_connections` | 1 | tenantId, marketplace, status | Connexions inbound (READY/DRAFT) |
| `marketplace_connections` | 0 | tenantId, type, status, lastSyncAt, lastError | Vide en DEV (structuree) |
| `marketplace_sync_states` | 0 | connectionId, tenantId, type, lastPolledAt, lastSuccessAt, lastError | Vide en DEV (structuree) |
| `integrations` | 0 | tenant_id, name, category, status, last_sync_at | Vide en DEV (structuree) |

### Tables non exploitees (hors perimetre)
- `channel_rules` — regles de routage, pas de health check
- `integration_required_credentials` — schema credentials, pas d'etat runtime
- `marketplace_octopia_accounts` — comptes Octopia specifiques

### Donnees reelles en DEV
- **tenant_channels** : 11 canaux (1 actif amazon-fr ecomlg-001, 10 removed)
- **inbound** : 1 adresse validee (amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io)
- **Providers** : amazon (10 canaux, 2 tenants), octopia (1 canal, 1 tenant)

---

## 2. Route API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/connectors` | GET | Overview + providers + tenants + inbound + errors | super_admin, ops_admin, account_manager |

### Payload retourne

```json
{
  "data": {
    "overview": {
      "total_channels": 11, "active_channels": 1, "removed_channels": 10,
      "pending_channels": 0, "total_tenants": 2, "active_tenants": 1,
      "inbound_active": 1, "inbound_validated": 1, "providers": 2
    },
    "providers": [
      { "provider": "amazon", "total": 10, "active": 1, "removed": 9, "pending": 0, "tenants": 2 },
      { "provider": "octopia", "total": 1, "active": 0, "removed": 1, "pending": 0, "tenants": 1 }
    ],
    "tenants": [...],
    "inbound": [...],
    "errors": [...]
  }
}
```

---

## 3. Service backend

**Fichier** : `src/features/connectors/connectors.service.ts`

| Methode | Description | Tables |
|---|---|---|
| `getOverview()` | 9 KPI globaux | tenant_channels, inbound_addresses |
| `getProviderSummary()` | Distribution par provider | tenant_channels |
| `getTenantConnectors()` | Liste tous les canaux avec JOIN tenants | tenant_channels, tenants |
| `getInboundHealth()` | Sante des adresses inbound | inbound_addresses |
| `getRecentErrors(limit)` | Erreurs recentes (deconnexions + erreurs inbound + erreurs sync) | tenant_channels, inbound_addresses, marketplace_sync_states, tenants |

---

## 4. Architecture UI

### Page : `/connectors`

Layout en 5 sections :

1. **KPI** — 5 StatCards (Canaux total, Actifs, Retires/Erreur, Tenants connectes, Inbound valides)
2. **Providers** — Cartes par provider (Amazon, Octopia) avec compteurs actifs/retires/en attente
3. **Inbound Health** — Panneau sante email inbound avec 3 statuts de validation + dernier inbound
4. **Erreurs recentes** — Liste erreurs connecteurs (deconnexions, erreurs inbound, erreurs sync)
5. **Table tenants** — Tableau complet connecteurs par tenant avec statut, email inbound, dates

### Composants crees

| Composant | Fichier | Role |
|---|---|---|
| `ConnectorProviderCards` | `src/features/connectors/components/ConnectorProviderCards.tsx` | Cartes par provider avec icones et couleurs |
| `ConnectorTenantTable` | `src/features/connectors/components/ConnectorTenantTable.tsx` | Tableau connecteurs par tenant |
| `ConnectorErrorList` | `src/features/connectors/components/ConnectorErrorList.tsx` | Liste erreurs avec source et date |
| `InboundHealthPanel` | `src/features/connectors/components/InboundHealthPanel.tsx` | Sante inbound avec 3 validations |

### Composants reutilises
- `StatCard` — KPI cards
- `PageHeader` — Header avec bouton Actualiser
- `LoadingState` / `ErrorState` / `EmptyState` — Etats UI
- `StatusBadge` — Badges colores (Actif/Retire/En attente/Valide)
- `Card` / `CardHeader` / `CardTitle` — Conteneurs

### Navigation
- Entree ajoutee dans la sidebar : **Connecteurs** (icone Plug)
- Section : Supervision (entre AI Metrics et Facturation)

---

## 5. Fonctionnalites

### Detection providers
- Amazon : icone ShoppingBag, couleur amber
- Octopia/Cdiscount : icone Store, couleur blue
- Autres : fallback generique

### Sante inbound
- 3 niveaux de validation : Validation, Pipeline, Marketplace
- Badge colore par statut (VALIDATED = vert, PENDING = jaune, FAILED = rouge)
- Dernier inbound at + erreur si presente

### Detection erreurs
- Canaux deconnectes (`status = 'removed'` avec `disconnected_at`)
- Erreurs inbound (`lastError` non null)
- Erreurs sync marketplace (`lastError` non null)
- Tri par date descendante, limite 20

### Tableau tenants
- Tri par statut (actifs en premier)
- Email inbound en font-mono
- Dates formatees FR
- Lien vers `/tenants/[id]`

---

## 6. RBAC

Acces autorise :
- `super_admin` : acces complet
- `ops_admin` : acces complet
- `account_manager` : acces complet

Autres roles : 403

---

## 7. Non-regression client

| Service | Code | Statut |
|---|---|---|
| `client-dev.keybuzz.io` | 307 | OK |
| `client.keybuzz.io` | 307 | OK |

---

## 8. Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `v0.12.0-ph86.6a-connector-health` | 1/1 Running | OK |
| PROD | `v0.12.0-ph86.6a-connector-health` | 1/1 Running | OK |

---

## 9. Limitations

| Limitation | Raison |
|---|---|
| `marketplace_connections` vide | Donnees probablement migrees vers `tenant_channels` |
| `marketplace_sync_states` vide | Aucune synchro recente en DEV |
| `integrations` vide | Table preparee mais pas encore utilisee |
| Pas de webhook monitoring | Table `webhook_events` inexistante |
| Pas de latence synchro | Pas de metriques temporelles detaillees |
| Pas de statut OAuth token | Tokens dans Vault, pas accessibles via DB |

---

## 10. Fichiers crees / modifies

### Crees
- `src/features/connectors/connectors.service.ts`
- `src/app/api/admin/connectors/route.ts`
- `src/features/connectors/components/ConnectorProviderCards.tsx`
- `src/features/connectors/components/ConnectorTenantTable.tsx`
- `src/features/connectors/components/ConnectorErrorList.tsx`
- `src/features/connectors/components/InboundHealthPanel.tsx`
- `src/app/(admin)/connectors/page.tsx`

### Modifies
- `src/config/navigation.ts` — ajout entree Connecteurs
- `src/components/layout/Sidebar.tsx` — ajout icone Plug
