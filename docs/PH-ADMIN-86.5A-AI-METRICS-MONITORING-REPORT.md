# PH-ADMIN-86.5A — AI Metrics & Monitoring — Report

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.11.0-ph86.5a-ai-metrics`
**Statut** : DEV + PROD deployes

---

## 1. Audit des donnees

### Table source : `ai_human_approval_queue`

| Colonne | Type | Exploitable |
|---|---|---|
| `id` | uuid | Oui (comptage) |
| `tenant_id` | text | Oui (groupement tenant) |
| `conversation_id` | text | Non utilise directement |
| `order_ref` | text | Non utilise directement |
| `queue_type` | text | Oui (distribution workflows) |
| `queue_status` | text | Oui (KPI + distribution statuts) |
| `priority` | text | Oui (KPI + distribution priorites) |
| `recommended_action` | text | Non utilise (deja dans Case Workbench) |
| `recommended_owner` | text | Oui (comptage assignes) |
| `reason` | text | Non utilise directement |
| `risk_summary` | jsonb | Non utilise (deja dans AI Panel) |
| `decision_context` | jsonb | Oui (detection snoozed via `snoozedUntil`) |
| `created_at` | timestamptz | Oui (timeline creation) |
| `updated_at` | timestamptz | Oui (timeline resolution) |

### Index exploites
- `idx_ahaq_status` — filtre statut
- `idx_ahaq_priority` — filtre priorite
- `idx_ahaq_tenant` — groupement tenant
- `idx_ahaq_created` — timeline

### Donnees non disponibles
- Score de confiance IA
- Journal IA detaille
- KBActions consommes
- Metriques temps de resolution
- Taux d'acceptation suggestions

---

## 2. Routes API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/ai-metrics` | GET | Overview + distributions + timeline + tenants | super_admin, ops_admin, account_manager |

Parametre query : `?days=7|14|30|90` (defaut: 30)

### Payload retourne

```json
{
  "data": {
    "overview": { "total": N, "open": N, "resolved": N, "critical": N, "assigned": N, "snoozed": N },
    "workflows": [{ "label": "LEGAL_REVIEW", "count": N }],
    "priorities": [{ "label": "CRITICAL", "count": N }],
    "statuses": [{ "label": "CLOSED", "count": N }],
    "timeline": [{ "day": "2026-03-01", "created": N, "resolved": N }],
    "tenants": [{ "tenant_id": "...", "tenant_name": "...", "total": N, "open": N, "critical": N }]
  }
}
```

---

## 3. Service backend

**Fichier** : `src/features/ai-metrics/metrics.service.ts`

| Methode | Description |
|---|---|
| `getOverview()` | 6 KPI globaux via COUNT + FILTER |
| `getWorkflowDistribution()` | GROUP BY queue_type |
| `getPriorityDistribution()` | GROUP BY priority |
| `getStatusDistribution()` | GROUP BY queue_status |
| `getTimeline(days)` | Serie temporelle via generate_series + LEFT JOIN |
| `getTenantImpact(limit)` | Top N tenants avec JOIN tenants |

---

## 4. Architecture UI

### Page : `/ai-metrics`

Layout en 4 sections :

1. **KPI** — 6 StatCards (Total, Ouverts, Resolus, Critiques, Assignes, Reportes)
2. **Distributions** — 3 barres horizontales (Workflows, Priorites, Statuts)
3. **Timeline** — Graphique barres double (crees vs resolus par jour)
4. **Tenants** — Tableau Top 10 tenants impactes

### Composants crees

| Composant | Fichier | Role |
|---|---|---|
| `DistributionChart` | `src/features/ai-metrics/components/DistributionChart.tsx` | Barres horizontales avec pourcentages |
| `TimelineChart` | `src/features/ai-metrics/components/TimelineChart.tsx` | Barres verticales doubles (crees/resolus) |
| `TenantImpactTable` | `src/features/ai-metrics/components/TenantImpactTable.tsx` | Tableau tenants avec badges et liens |

### Composants reutilises

- `StatCard` — KPI cards
- `PageHeader` — Header avec actions
- `LoadingState` / `ErrorState` / `EmptyState` — Etats UI
- `StatusBadge` — Badges colores dans le tableau

### Navigation

- Entree ajoutee dans la sidebar : **AI Metrics** (icone BarChart3)
- Section : Supervision (entre Tenants et Facturation)

---

## 5. Fonctionnalites

### Selecteur periode
- 7, 14, 30 ou 90 jours
- Rafraichissement automatique au changement

### Bouton Actualiser
- Refetch complet des donnees

### Labels lisibles
- `LEGAL_REVIEW` → "Revue juridique"
- `FRAUD_CHECK` → "Verification fraude"
- `CRITICAL` → "Critique"
- `OPEN` → "Ouvert"
- etc.

### Etat vide
- Si aucune donnee IA : message explicite "Aucune activite IA enregistree"
- Pas de graphiques vides confusants

---

## 6. RBAC

Acces autorise :
- `super_admin` : acces complet
- `ops_admin` : acces complet
- `account_manager` : acces complet

Autres roles : 403

Aucun role hardcode dans les composants. RBAC applique cote API.

---

## 7. Non-regression client

| Service | Code | Statut |
|---|---|---|
| `client-dev.keybuzz.io` | 307 | OK |
| `client.keybuzz.io` | 307 | OK |

Aucun impact sur les applications client.

---

## 8. Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `v0.11.0-ph86.5a-ai-metrics` | 1/1 Running | OK |
| PROD | `v0.11.0-ph86.5a-ai-metrics` | 1/1 Running | OK |

### Manifestes K8s mis a jour
- `k8s/keybuzz-admin-v2-dev/deployment.yaml`
- `k8s/keybuzz-admin-v2-prod/deployment.yaml`

---

## 9. Limitations

| Limitation | Raison |
|---|---|
| Pas de score de confiance IA | Champ non disponible en base |
| Pas de temps moyen de resolution | Necessite audit_log detaille |
| Pas de taux acceptation | Pas de journal decision agent |
| Pas de graphique circulaire (donut) | CSS-only, pas de lib chart externe |
| Timeline resolution approximative | Basee sur updated_at des cas fermes |
| 1 seul cas en DEV | Donnees reelles limitees en environnement dev |

---

## 10. Fichiers crees / modifies

### Crees
- `src/features/ai-metrics/metrics.service.ts`
- `src/app/api/admin/ai-metrics/route.ts`
- `src/features/ai-metrics/components/DistributionChart.tsx`
- `src/features/ai-metrics/components/TimelineChart.tsx`
- `src/features/ai-metrics/components/TenantImpactTable.tsx`
- `src/app/(admin)/ai-metrics/page.tsx`

### Modifies
- `src/config/navigation.ts` — ajout entree AI Metrics
- `src/components/layout/Sidebar.tsx` — ajout icone BarChart3
