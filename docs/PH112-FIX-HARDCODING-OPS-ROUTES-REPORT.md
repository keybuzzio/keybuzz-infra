# PH112-FIX - Correction Hardcodage + Routes Ops Manquantes (Admin V2)

> Date : 17 mars 2026
> Environnement : DEV
> API Image : `ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-dev`
> Admin Image : `ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix`

---

## Contexte

Le deploiement PH112 initial (API `v3.6.14`, Admin `v2.1.4`) contenait plusieurs problemes :

1. **Hardcodage** : `TENANT_ID = 'ecomlg-001'` en dur dans les 5 pages PH112
2. **Version figee** : `v2.1.4` en dur dans `Sidebar.tsx`
3. **Routes API manquantes** : 4 pages operations (Ops, Queues, Approbations, Follow-ups) appelaient des endpoints inexistants
4. **Race condition** : `useApiData` lancait les appels API avant que le tenant soit charge
5. **Authentification API** : header `X-User-Email` non transmis (corrige en session precedente, v2.1.5)

---

## Audit Hardcodage Complet

### Scan effectue

```
grep -rn 'ecomlg|hardcode|localhost:3|localhost:5' src/ --include='*.ts' --include='*.tsx'
grep -rn 'api-dev.keybuzz|api.keybuzz|keybuzz.io' src/ --include='*.ts' --include='*.tsx'
grep -rn 'v2.1.4' src/ --include='*.ts' --include='*.tsx'
```

### Resultats

| Type | Fichier | Valeur hardcodee | Statut |
|------|---------|------------------|--------|
| Tenant ID | `ai-control/page.tsx` | `const TENANT_ID = 'ecomlg-001'` | CORRIGE |
| Tenant ID | `ai-control/activation/page.tsx` | `const TENANT_ID = 'ecomlg-001'` | CORRIGE |
| Tenant ID | `ai-control/policies/page.tsx` | `const TENANT_ID = 'ecomlg-001'` | CORRIGE |
| Tenant ID | `ai-control/monitoring/page.tsx` | `const TENANT_ID = 'ecomlg-001'` | CORRIGE |
| Tenant ID | `ai-control/debug/page.tsx` | `const TENANT_ID = 'ecomlg-001'` | CORRIGE |
| Version | `components/layout/Sidebar.tsx` | `v2.1.4` | CORRIGE -> `v2.1.5` |
| URL API | `config/env.ts` | `process.env.NEXT_PUBLIC_API_URL \|\| 'https://api-dev.keybuzz.io'` | OK (env var + fallback) |
| URL Admin | `api/admin/users/route.ts` | `process.env.NEXTAUTH_URL \|\| 'https://admin-dev.keybuzz.io'` | OK (env var + fallback) |
| Placeholder | `login/page.tsx` | `admin@keybuzz.io` | OK (placeholder UX) |

---

## Corrections Appliquees

### 1. Suppression du TENANT_ID hardcode

**Avant :**
```typescript
const TENANT_ID = 'ecomlg-001';
// ...
const [tenantId] = useState(TENANT_ID);
```

**Apres :**
```typescript
import { useTenantSelector } from '@/hooks/useTenantSelector';

const { tenants, selectedTenantId: tenantId, selectTenant, loading: tenantsLoading } = useTenantSelector();
```

Le hook `useTenantSelector` :
- Appelle `GET /api/admin/tenants` (endpoint interne Next.js existant) pour charger les tenants depuis la DB
- Persiste la selection dans `localStorage` (`kb-admin-selected-tenant`)
- Expose un etat `ready` pour eviter les appels API prematures

### 2. Correction de la race condition useApiData

**Avant :**
```typescript
const { data } = useApiData(() => aiControlService.getGovernance(tenantId));
// Probleme : tenantId = '' au premier render -> API retourne "tenantId required"
```

**Apres :**
```typescript
const { data } = useApiData<any>(
  () => tenantId ? aiControlService.getGovernance(tenantId) : Promise.resolve({ data: null } as any),
  [tenantId]
);
// Le guard ternaire empeche l'appel si tenantId est vide
// Le [tenantId] en deps relance le fetch quand le tenant est selectionne
```

Le hook `useApiData` a ete enrichi pour accepter un tableau de dependances en second parametre.

### 3. Routes API Ops manquantes

**Probleme :** Les services backend existaient (`opsActionCenterEngine.ts`, `aiControlCenterEngine.ts`) mais leurs routes HTTP n'etaient pas enregistrees dans Fastify.

**Solution :** Creation de `src/modules/ai/ops-routes.ts` avec 18 routes :

| Methode | Route | Service utilise | Usage |
|---------|-------|-----------------|-------|
| GET | `/ai/ops-dashboard` | `getOpsDashboard()` | Dashboard ops (page `/ops`) |
| GET | `/ai/human-approval-queue` | `getPendingApprovals()` | File d'attente (page `/queues`) |
| GET | `/ai/ops/pending-approvals` | `getPendingApprovals()` | Approbations (page `/approvals`) |
| GET | `/ai/ops/followups` | `getFollowupWorkload()` | Follow-ups bruts |
| GET | `/ai/ops/escalations` | `getEscalationCases()` | Cas en escalade |
| POST | `/ai/ops/assign` | `assignCase()` | Assigner un cas |
| POST | `/ai/ops/resolve` | `resolveCase()` | Resoudre un cas |
| POST | `/ai/ops/snooze` | `snoozeCase()` | Reporter un cas |
| GET | `/ai/followups` | `getFollowupWorkload()` | Liste follow-ups |
| GET | `/ai/followup-scheduler` | `getFollowupWorkload()` | Scheduler (transforme en SchedulerReport) |
| GET | `/ai/followup-scheduler/overdue` | `getFollowupWorkload()` | Follow-ups en retard |
| GET | `/ai/followup-scheduler/priorities` | `getFollowupWorkload()` | Priorites |
| GET | `/ai/followup-scheduler/timeline` | `computeTimelineSummary()` | Timeline |
| GET | `/ai/control-center` | `computeControlCenterOverview()` | Vue globale control center |
| GET | `/ai/control-center/queues` | `computeOperationalQueues()` | Queues operationnelles |
| GET | `/ai/control-center/workflows` | `computeWorkflowSummary()` | Workflows |
| GET | `/ai/control-center/timeline` | `computeTimelineSummary()` | Timeline |
| GET/POST | `/ai/human-approval-queue/:id[/status]` | Direct | Detail/update queue item |

La route `/ai/followup-scheduler` transforme le resultat brut de `getFollowupWorkload()` (tableau) en objet `SchedulerReport` attendu par la page (`totals`, `urgencyDistribution`, `typeDistribution`, `actionsRecommended`).

Enregistrement dans `app.ts` :
```typescript
import { opsRoutes } from './modules/ai/ops-routes';
app.register(opsRoutes, { prefix: '/ai' });
```

### 4. Version sidebar

```
v2.1.4 -> v2.1.5
```

---

## Fichiers modifies

### keybuzz-api

| Fichier | Action |
|---------|--------|
| `src/modules/ai/ops-routes.ts` | CREE (299 lignes, 18 routes) |
| `src/app.ts` | MODIFIE (import + register opsRoutes) |

### keybuzz-admin-v2

| Fichier | Action |
|---------|--------|
| `src/hooks/useTenantSelector.ts` | CREE (hook de selection tenant dynamique) |
| `src/hooks/useApiData.ts` | MODIFIE (support deps en 2nd parametre) |
| `src/components/ui/TenantSelector.tsx` | CREE (dropdown de selection tenant) |
| `src/components/layout/Sidebar.tsx` | MODIFIE (version v2.1.4 -> v2.1.5) |
| `src/app/(admin)/ai-control/page.tsx` | MODIFIE (TENANT_ID -> useTenantSelector + guard) |
| `src/app/(admin)/ai-control/activation/page.tsx` | MODIFIE (idem) |
| `src/app/(admin)/ai-control/policies/page.tsx` | MODIFIE (idem) |
| `src/app/(admin)/ai-control/monitoring/page.tsx` | MODIFIE (idem + type any) |
| `src/app/(admin)/ai-control/debug/page.tsx` | MODIFIE (idem) |

---

## Verification Finale -- 15 Pages Testees

| Page | Route | Statut | Commentaire |
|------|-------|--------|-------------|
| Dashboard | `/` | OK | Placeholder statique |
| Ops Center | `/ops` | OK | 4 stats (cas, followups, retards, critiques) |
| Queues | `/queues` | OK | File d'attente avec compteurs |
| Approbations | `/approvals` | OK | 4 stats + liste vide |
| Follow-ups | `/followups` | OK | 5 compteurs (ouverts, a venir, bientot, retard, critiques) |
| AI Control Center | `/ai-control` | OK | Gouvernance NOMINAL, Autonomie ASSISTED_ONLY |
| Activation | `/ai-control/activation` | OK | Matrice 0 actions |
| Policies | `/ai-control/policies` | OK | 0 policies, bouton Ajouter |
| Monitoring | `/ai-control/monitoring` | OK | Sante, Activation, Journal |
| Debug IA | `/ai-control/debug` | OK | 15 endpoints inspectables |
| Audit | `/audit` | OK | Placeholder statique |
| Tenants | `/tenants` | OK | Placeholder statique |
| Facturation | `/billing` | OK | Placeholder statique |
| Utilisateurs | `/users` | OK | Fonctionnel (donnees dynamiques) |
| Mon profil | `/settings/profile` | OK | Fonctionnel (donnees dynamiques) |

---

## Non-regression

- Pipeline IA PH41 -> PH111 intact
- Aucun endpoint existant modifie (uniquement ajout)
- Aucun comportement IA modifie
- Aucun impact KBActions
- Auth `X-User-Email` fonctionnel (corrige en v2.1.5)
- Sessions NextAuth stables

---

## Deploiement

### API DEV
```bash
docker build -t ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-dev -f Dockerfile .
docker push ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-dev
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-dev -n keybuzz-api-dev
```

### Admin DEV
```bash
docker build --build-arg NEXT_PUBLIC_APP_ENV=dev --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  -t ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix -f Dockerfile .
docker push ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix
kubectl rollout restart deploy/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

---

## Rollback

### API
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.14-ph112-ai-control-center-dev -n keybuzz-api-dev
```

### Admin
```bash
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.5-ph112-fix-auth-v2 -n keybuzz-admin-v2-dev
```

---

## Points d'attention pour PROD

1. **Variables d'environnement** : `NEXT_PUBLIC_API_URL` doit pointer sur `https://api.keybuzz.io` (pas api-dev)
2. **Build Admin PROD** : utiliser `--build-arg NEXT_PUBLIC_APP_ENV=production --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
3. **Namespace PROD** : `keybuzz-api-prod` et `keybuzz-admin-v2-prod`
4. **Tenants PROD** : le hook `useTenantSelector` chargera automatiquement les tenants PROD depuis la DB PROD
5. **GitOps** : les manifests K8s dans `keybuzz-infra/k8s/keybuzz-admin-dev/` sont `.disabled` -- deploiement manuel via `kubectl set image`

---

## Historique des images

| Version | Contenu | Date |
|---------|---------|------|
| Admin `v2.1.3-ws` | Base pre-PH112 | ~13 mars |
| Admin `v2.1.4-ph112-ai-control-center` | PH112 initial (TENANT_ID hardcode, auth manquante) | 17 mars |
| Admin `v2.1.5-ph112-fix-auth-v2` | Fix auth `X-User-Email` + `ApiAuthSync` | 17 mars |
| Admin `v2.1.6-ph112-all-fix` | Fix hardcodage + deps + types | 17 mars |
| API `v3.6.14-ph112-ai-control-center-dev` | PH112 initial | 17 mars |
| API `v3.6.15-ph112-ops-fix-dev` | Ajout ops-routes.ts (18 routes) | 17 mars |
