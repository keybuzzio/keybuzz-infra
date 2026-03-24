# PH-ADMIN-87.11B — CONNECTORS & FOLLOWUPS TENANT-AWARE

## 1. Resume executif

### Ce qui a ete ajoute
| Composant | Description |
|---|---|
| `GET /api/admin/tenants/[id]/connectors` | Channels, inbound connections, inbound addresses, marketplace counts |
| `GET /api/admin/tenants/[id]/followups` | Followup cases tenant-scope (total, open, closed, items) |
| Page `/connectors` | Nouvelle page tenant-aware avec StatCards, table channels, inbound connections, inbound addresses |
| Page `/followups` enrichie | Mode tenant-aware ajoute avec TenantFollowupsPanel quand `tenantId` present |
| Cockpit QuickLinks | "Connecteurs du tenant" + "Follow-ups du tenant" |
| Sidebar navigation | "Connecteurs" ajoute dans la section Supervision |
| Version | Bump v2.5.0 → v2.6.0 |

### Ce qui est reellement branche
- `tenant_channels` : 2 channels pour ecomlg-001 (PROD), 7 pour ecomlg-001 (DEV), 2 pour switaa-sasu-mmazd2rd (PROD)
- `inbound_connections` : 1 connexion READY pour ecomlg-001 (amazon FR)
- `inbound_addresses` : 1 adresse VALIDATED (`amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`)
- `ai_followup_cases` : 0 partout (table existe, pas encore alimentee par le scheduler)

### Ce qui reste non exploitable
- `integrations` : table vide (0 lignes DEV + PROD)
- `marketplace_connections` : table vide (0 lignes DEV + PROD)
- `marketplace_sync_states` : table vide (0 lignes DEV + PROD)
- Mode global followups : le scheduler global endpoint n'est pas accessible depuis l'admin (pre-existant)

---

## 2. Cartographie des sources reelles

| Table | Tenant-scope | DEV | PROD | Exploitable |
|---|---|---|---|---|
| `tenant_channels` | Oui (`tenant_id`) | 7 rows (ecomlg-001) | 4 rows (2 ecomlg, 2 switaa) | Oui |
| `inbound_addresses` | Oui (`tenantId`) | 1 row (ecomlg-001) | 1 row (ecomlg-001) | Oui |
| `inbound_connections` | Oui (`tenantId`) | 1 row (ecomlg-001) | 1 row (ecomlg-001) | Oui |
| `integrations` | Oui (`tenant_id`) | 0 | 0 | Empty state |
| `marketplace_connections` | Oui (`tenantId`) | 0 | 0 | Empty state |
| `marketplace_sync_states` | Oui (`tenantId`) | 0 | 0 | Empty state |
| `ai_followup_cases` | Oui (`tenant_id`) | 0 | 0 | Empty state |
| `channel_rules` | Existe | Non audite | Non audite | Non utilise |

---

## 3. Endpoint connectors

### `GET /api/admin/tenants/[id]/connectors`

**Payload reel (ecomlg-001 PROD)** :
```json
{
  "data": {
    "channels": { "total": 2, "active": 1, "items": [
      { "id": "...", "provider": "amazon", "country_code": "FR", "display_name": "Amazon France", "status": "active", "billing_status": "included" },
      { "id": "...", "provider": "octopia", "country_code": "FR", "display_name": "CDiscount France", "status": "removed", "billing_status": "included" }
    ]},
    "inbound": {
      "connections": [{ "id": "conn_...", "marketplace": "amazon", "countries": ["FR"], "status": "READY" }],
      "addresses": [{ "id": "addr_...", "marketplace": "amazon", "country": "FR", "email_address": "amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io", "validation_status": "VALIDATED", "pipeline_status": "VALIDATED", "marketplace_status": "VALIDATED" }]
    },
    "marketplaces_total": 0,
    "sync_states_total": 0
  }
}
```

**Limites reelles** :
- `marketplace_connections` et `marketplace_sync_states` retournent 0 — tables vides
- `integrations` non incluse — table vide
- Aucune donnee inventee

---

## 4. Endpoint followups

### `GET /api/admin/tenants/[id]/followups`

**Methode** : requete directe PostgreSQL sur `ai_followup_cases` filtree par `tenant_id`

**Payload reel (tous tenants PROD)** :
```json
{ "data": { "total": 0, "open": 0, "closed": 0, "items": [] } }
```

**Preuve de filtrage reel** : la requete SQL utilise `WHERE tenant_id = $1` — pas de filtrage cosmétique.

---

## 5. UI

### Page `/connectors`
- StatCards : Channels total, Channels actifs, Connexions inbound, Adresses inbound
- Table channels : marketplace, provider, pays, statut (badge couleur), billing, date connexion
- Panneau inbound connections : marketplace, countries, statut
- Panneau inbound addresses : email, statuts validation/pipeline/marketplace, dernier inbound, erreurs
- Sans `tenantId` : "Selectionnez un tenant"
- TenantFilterBanner avec "Retour au cockpit tenant"

### Page `/followups` (enrichie)
- Quand `tenantId` present : TenantFollowupsPanel avec StatCards (Total, Ouverts, Fermes) + table
- Quand pas de `tenantId` : comportement global existant (scheduler report)
- Empty state honnete : "Aucun follow-up enregistre pour ce tenant."
- TenantFilterBanner avec "Retour au cockpit tenant"

### Cockpit tenant
- QuickLink "Connecteurs du tenant" → `/connectors?tenantId=<id>`
- QuickLink "Follow-ups du tenant" → `/followups?tenantId=<id>`

### Sidebar
- "Connecteurs" ajoute dans la section Supervision

---

## 6. Preuve DB → API → UI → navigation

### PROD — ecomlg-001 (tenant riche)

| Section | DB | API | UI |
|---|---|---|---|
| Channels total | 2 rows `tenant_channels` | `channels.total: 2` | "2" affiche |
| Channels actifs | 1 active | `channels.active: 1` | "1" affiche |
| Connexions inbound | 1 row `inbound_connections` READY | `inbound.connections: [1]` | "amazon — FR / READY" |
| Adresses inbound | 1 row VALIDATED | `inbound.addresses: [1]` | Email + badges VALIDATED |
| Followups | 0 rows | `total: 0, open: 0` | "Aucun follow-up" |
| Navigation cockpit | — | — | QuickLinks visibles, TenantFilterBanner OK |

### PROD — switaa-sasu-mmazd2rd (tenant sparse)

| Section | DB | API | UI |
|---|---|---|---|
| Channels total | 2 rows (both removed) | `channels.total: 2` | "2" affiche |
| Channels actifs | 0 active | `channels.active: 0` | "0" affiche |
| Connexions inbound | 0 rows | `inbound.connections: []` | "Aucune connexion inbound" |
| Adresses inbound | 0 rows | `inbound.addresses: []` | "Aucune adresse email inbound" |
| Followups | 0 rows | `total: 0` | "Aucun follow-up" |

---

## 7. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA feature | `0fd770f8d187c56df27e1e2b0793ffccda88c9b3` |
| Commit SHA fix | `9a434de9ab9c6b5e1bf9e84c019cd8c8e29073cb` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-dev` |
| Digest DEV | `sha256:f2532455ed16f59efefbd31361b08e3c1b5aefa55fa0dd69e435cc50dfdb4a98` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-prod` |
| Digest PROD | `sha256:2bdf23d803d77df8e6ce7a2fcb08487b1b8371bdff06fe6043e7055dac1efa46` |
| Version runtime | v2.6.0 |
| Pods DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-dev` |
| Pods PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-prod` |

---

## 8. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.5.0-ph-admin-87-11a-fix2-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.5.0-ph-admin-87-11a-fix2-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## 9. Dettes restantes

| Dette | Description | Priorite |
|---|---|---|
| `integrations` vide | Table existe mais jamais alimentee — pas de connecteur hors marketplace | Basse |
| `marketplace_connections` vide | Table existe mais aucune connexion marketplace directe | Basse |
| `ai_followup_cases` vide | Le scheduler de followups n'alimente pas encore cette table | Moyenne |
| Scheduler global | L'endpoint scheduler global n'est pas accessible depuis l'admin PROD (pre-existant) | Basse |
| QuickLinks cockpit | Les liens ne naviguent pas via `Link` Next.js — ils utilisent `href` standard, ce qui fonctionne mais sans transition SPA | Basse |
