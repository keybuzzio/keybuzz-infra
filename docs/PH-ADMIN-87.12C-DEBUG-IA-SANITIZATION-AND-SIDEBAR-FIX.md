# PH-ADMIN-87.12C — DEBUG IA SANITIZATION & SIDEBAR EXACT ACTIVE FIX

> Date : 2026-03-04
> Version : v2.7.2
> Commit : `d4d8396e419633209a5d2fd720708811d0d75b0c`

---

## 1. Resume executif

### Bug sidebar corrige
- **Avant** : AI Control Center restait visuellement actif sur `/ai-control/debug`, `/ai-control/monitoring`, `/ai-control/policies`, `/ai-control/activation`
- **Apres** : exactement un seul item actif par route — le plus specifique

### Debug IA nettoye
- **Avant** : 15 endpoints dans une liste plate, 14 retournant "Route not found", bouton "Tout charger" declenchant une pluie d'erreurs
- **Apres** : 3 sections classifiees (disponibles / params requis / non deployes), bouton "Charger les endpoints disponibles" ne fetche que les 8 endpoints reels

### Environnements valides
- DEV : valide
- PROD : valide — navigation complete + Debug IA teste

---

## 2. Diagnostic sidebar

### Cause racine
```typescript
// PH-ADMIN-87.12B avait corrige startsWith(href) en:
pathname === item.href || pathname.startsWith(item.href + '/')

// Mais cela rendait TOUJOURS actifs:
// - /ai-control (via startsWith('/ai-control/'))
// - /ai-control/debug (via exact match)
// Car /ai-control/debug.startsWith('/ai-control/') === true
```

### Difference active vs open
- **Active** = item qui doit etre stylistiquement selectionne (un seul a la fois)
- **Open** = groupe qui peut etre deploye/visible (plusieurs groupes possibles)
- Le probleme etait que le parent `/ai-control` matchait comme "actif" via `startsWith` alors qu'un enfant plus specifique existait

### Solution appliquee
```typescript
// Calculer le href le plus specifique (le plus long) parmi tous les matchs
const activeHref = (() => {
  const allHrefs = navigation.flatMap((g) => g.items.map((i) => i.href));
  const matching = allHrefs.filter((h) =>
    h === '/' ? pathname === '/' : pathname === h || pathname.startsWith(h + '/')
  );
  return matching.reduce((best, h) => (h.length > best.length ? h : best), '');
})();

// Puis pour chaque item:
const isActive = item.href === activeHref;
```

---

## 3. Diagnostic endpoints debug

### Audit endpoint par endpoint (PROD `api.keybuzz.io`)

| Label | Endpoint | HTTP | Existe | Categorie |
|---|---|---|---|---|
| Health Monitoring | `/ai/health-monitoring` | 200 | Oui | disponible |
| Performance Metrics | `/ai/performance-metrics` | 200 | Oui | disponible |
| Execution Audit | `/ai/execution-audit` | 200 (avec tenantId) | Oui | disponible |
| Ops Dashboard | `/ai/ops-dashboard` | 200 | Oui | disponible |
| Human Approval Queue | `/ai/human-approval-queue` | 200 | Oui | disponible |
| Followup Scheduler | `/ai/followup-scheduler` | 200 | Oui | disponible |
| Pending Approvals | `/ai/ops/pending-approvals` | 200 | Oui | disponible |
| Followups | `/ai/ops/followups` | 200 | Oui | disponible |
| Policy Effective | `/ai/policy/effective` | 400 | Oui | params requis (`tenantId` + `conversationId`) |
| Governance | `/ai/governance` | 404 | Non | non deploye |
| Action Dispatcher | `/ai/action-dispatcher` | 404 | Non | non deploye |
| Connector Abstraction | `/ai/connector-abstraction` | 404 | Non | non deploye |
| Autonomous Ops | `/ai/autonomous-ops` | 404 | Non | non deploye |
| Case Manager | `/ai/case-manager` | 404 | Non | non deploye |
| Case State | `/ai/case-state` | 404 | Non | non deploye |
| Quality Score | `/ai/quality-score` | 404 | Non | non deploye |
| Self-Improvement | `/ai/self-improvement` | 404 | Non | non deploye |
| Knowledge Graph | `/ai/knowledge-graph` | 404 | Non | non deploye |
| Long-Term Memory | `/ai/long-term-memory` | 404 | Non | non deploye |
| Strategic Resolution | `/ai/strategic-resolution` | 404 | Non | non deploye |
| Cross-Tenant Intel. | `/ai/cross-tenant-intelligence` | 404 | Non | non deploye |
| Controlled Execution | `/ai/controlled-execution` | 404 | Non | non deploye |
| Controlled Activation | `/ai/controlled-activation` | 404 | Non | non deploye |

---

## 4. Correctifs appliques

### Fichier 1 : `src/components/layout/Sidebar.tsx`
- **Logique active** : calcul du `activeHref` le plus specifique via `reduce` sur tous les hrefs
- **Resultat** : un seul item actif par route, le parent n'est jamais faussement selectionne
- **Version** : `v2.7.1` → `v2.7.2`

### Fichier 2 : `src/app/(admin)/ai-control/debug/page.tsx`
- **Reecrit integralement** avec 3 categories d'endpoints :
  - `AVAILABLE_ENDPOINTS` (8) : endpoints reels, fetchables
  - `PARAMS_REQUIRED_ENDPOINTS` (1) : endpoint existant mais necessitant des params specifiques
  - `NOT_DEPLOYED_ENDPOINTS` (14) : endpoints roadmap, non fetches, message honnete
- **Bouton** : "Charger les endpoints disponibles" ne fetch que les 8 endpoints reels
- **Badges visuels** : "Disponible" (vert), "Params requis" (orange), "Non deploye" (gris)
- **Tenant context** : affiche le tenant courant dans le header si selectionne
- **Non-deployes** : message "Cet endpoint n'est pas encore deploye dans le backend"
- **Params requis** : message "Parametres requis : tenantId, conversationId"

---

## 5. Validation runtime PROD

### Sidebar — matrice route → item actif

| Route | Item actif | AI Control Center actif ? | IA Tenant actif ? |
|---|---|---|---|
| `/ai` | IA Tenant | NON | OUI |
| `/ai-control` | AI Control Center | OUI | NON |
| `/ai-control/activation` | Activation | NON | NON |
| `/ai-control/policies` | Policies | NON | NON |
| `/ai-control/monitoring` | Monitoring | NON | NON |
| `/ai-control/debug` | Debug IA | NON | NON |

### Debug IA — "Charger les endpoints disponibles"

| Endpoint | Resultat | Badge |
|---|---|---|
| Health Monitoring | OK | Disponible |
| Performance Metrics | OK | Disponible |
| Execution Audit | tenantId required (HTTP 400) | Disponible |
| Ops Dashboard | OK | Disponible |
| Human Approval Queue | OK | Disponible |
| Followup Scheduler | OK | Disponible |
| Pending Approvals | OK | Disponible |
| Followups | OK | Disponible |
| Policy Effective | — (non fetche) | Params requis |
| Governance → Controlled Activation (14) | — (non fetches) | Non deploye |

**Aucun "Route not found"**
**Aucun "Failed to fetch"**
**Aucune pluie d'erreurs au clic "Charger"**

### Endpoints non deployes — comportement
- Clic ouvre le panneau avec message honnete
- Pas de bouton refresh (pas de fetch possible)
- Pas d'appel reseau

---

## 6. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA source | `d4d8396e419633209a5d2fd720708811d0d75b0c` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.2-ph-admin-87-12c-dev` |
| Digest DEV | `sha256:4b4e68642aba382c663f9587d0b4c844c5049b076ce09c675860568d089a336f` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.2-ph-admin-87-12c-prod` |
| Digest PROD | `sha256:29bfd55c940cb773091d31dc4331181a872a89eca4d1fed36b3f3b661efe5c09` |
| Version runtime | v2.7.2 |
| Build-arg DEV | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io` |
| Build-arg PROD | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-dev \
  -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-prod \
  -n keybuzz-admin-v2-prod
```

| Env | Image stable precedente |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-prod` |

---

## 8. Dettes restantes

| ID | Description | Impact |
|---|---|---|
| D1 | 14 endpoints IA non deployes (governance, case-manager, etc.) | Roadmap backend — a implementer quand les fonctionnalites existent |
| D2 | `/ai/execution-audit` retourne 400 sans tenantId | Comportement correct mais UX ameliorable (pre-selection tenant) |
| D3 | Pages AI Control (activation, policies) utilisent des endpoints non deployes | Affichent empty states honnetes mais les donnees seront disponibles quand le backend les implementera |
