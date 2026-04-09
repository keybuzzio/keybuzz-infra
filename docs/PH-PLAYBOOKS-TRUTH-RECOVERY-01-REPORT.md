# PH-PLAYBOOKS-TRUTH-RECOVERY-01 — Rapport Final

> Date : 1er mars 2026
> Agent : Cursor Executor
> Phase : PH-PLAYBOOKS-TRUTH-RECOVERY-01
> Type : audit + fix ciblé produit

---

## Verdict Final

**PLAYBOOKS TRUTH RECOVERED — TENANT SAFE — PLAN SAFE — ROLLBACK READY**

---

## 1. Cause racine exacte

### Problème

La page `/playbooks` était vide pour un tenant récent/re-onboardé parce que :

```
getPlaybooks()
  → getLastTenant().id  ← lit localStorage "kb_prefs:v1" → lastTenantId
  → lastTenantId est null si setLastTenant() n'a jamais été appelé
  → retourne [] (tableau vide)
  → auto-seed ne se déclenche PAS (car tenantId est null)
  → page affiche "Aucun playbook trouvé"
```

**Même classe de bug que PH-BILLING-PLAN-TRUTH-RECOVERY-02** : utilisation de `getLastTenant().id` (localStorage, potentiellement null/stale) au lieu de `useTenant().currentTenantId` (React context TenantProvider, source de vérité).

### Pourquoi `getLastTenant().id` peut être null

`setLastTenant()` est appelé **UNIQUEMENT** dans `select-tenant/page.tsx`.
Si le flux utilisateur contourne `/select-tenant` (OAuth auto-redirect, URL directe, single-tenant auto-redirect), `lastTenantId` reste null dans localStorage.

### Pourquoi ecomlg-001 n'était pas affecté

L'utilisateur principal sur ecomlg-001 est passé par `/select-tenant` historiquement, donc `lastTenantId` était déjà défini dans le localStorage de son navigateur.

---

## 2. Tenant(s) testés

| Tenant | Plan | Rôle | Résultat attendu |
|--------|------|------|-----------------|
| ecomlg-001 | PRO | owner | Playbooks inchangés (aucun overwrite) |
| Tout nouveau tenant | Tout plan | - | 5 starter playbooks auto-seedés |

---

## 3. Plan(s) testés

La matrice `planCapabilities.ts` confirme que **TOUS les plans** ont `hasBasicPlaybooks: true`.
La page `/playbooks` n'a **AUCUN `FeatureGate`** — elle est accessible à tous.
Donc le bug n'est PAS lié au plan.

---

## 4. Fichiers modifiés (4)

### `src/services/playbooks.service.ts`

```typescript
// AVANT
export function getPlaybooks(): Playbook[] {
  const tenantId = getLastTenant().id;  // ← peut être null
  ...
}

// APRÈS (PH-PLAYBOOKS-TRUTH-RECOVERY-01)
export function getPlaybooks(tenantIdOverride?: string): Playbook[] {
  const tenantId = tenantIdOverride || getLastTenant().id;
  ...
}

export function getPlaybook(id: string, tenantIdOverride?: string): Playbook | null {
  const playbooks = getPlaybooks(tenantIdOverride);
  ...
}
```

### `app/playbooks/page.tsx`

```typescript
// AVANT
useEffect(() => {
  setPlaybooks(getPlaybooks());
}, []);

// APRÈS
import { useTenant } from "@/src/features/tenant/TenantProvider";
const { currentTenantId } = useTenant();

useEffect(() => {
  if (currentTenantId) {
    setPlaybooks(getPlaybooks(currentTenantId));
  }
}, [currentTenantId]);
```

### `app/playbooks/[playbookId]/page.tsx`

Même pattern : ajout `useTenant()`, passage de `currentTenantId` à `getPlaybook()`.

### `app/playbooks/[playbookId]/tester/page.tsx`

Même pattern : ajout `useTenant()`, passage de `currentTenantId` à `getPlaybook()`.

---

## 5. Logique exacte de seed / récupération

### Auto-seed (inchangé — fonctionnait déjà, seul le tenantId était le problème)

```
getPlaybooks(currentTenantId)
  → key = "kb_client_playbooks:v1:<currentTenantId>"
  → localStorage.getItem(key) === null?
    → OUI: initStarterPlaybooks(currentTenantId)
      → crée 5 playbooks starter dans localStorage
      → retourne les 5 starters
    → NON: parse et retourne les playbooks existants
```

### 5 starters auto-seedés

1. **Retard livraison - Réponse automatique** (delivery_delay, both, activé)
2. **Où est ma commande ?** (tracking_request, messages, activé)
3. **Produit endommagé - Demande preuve** (damaged_item, both, activé)
4. **Dropshipping - Escalade fournisseur** (supplier_escalation, orders, **désactivé**)
5. **SLA risque - Escalade humain** (unanswered_2h, messages, activé)

---

## 6. Preuves de non-régression

### ecomlg-001 non impacté

- Le fix ne touche PAS les données localStorage existantes
- Il ajoute uniquement un paramètre optionnel `tenantIdOverride`
- Si l'override n'est pas passé, le comportement est identique (fallback `getLastTenant().id`)
- Les playbooks existants d'ecomlg-001 ne sont ni overwritten ni supprimés

### Aucune régression sur gating / billing / tenant

- Aucun changement dans `planCapabilities.ts`
- Aucun changement dans `FeatureGate`
- Aucun changement dans `TenantProvider`
- Aucun changement d'API / backend / DB
- Fix 100% client-side (4 fichiers UI uniquement)

---

## 7. Versions déployées

| Env | Image | Status |
|-----|-------|--------|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.123-playbooks-truth-recovery-dev` | ✅ Running 1/1 |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.123-playbooks-truth-recovery-prod` | ✅ Running 1/1 |

---

## 8. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ph-amz-ui-state-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ph-full-align-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 9. GitOps

| Fichier | Modification |
|---------|-------------|
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.122-ph-amz-ui-state-dev` → `v3.5.123-playbooks-truth-recovery-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.122-ph-full-align-prod` → `v3.5.123-playbooks-truth-recovery-prod` |

---

## 10. Résumé technique

| Aspect | Détail |
|--------|--------|
| **Bug** | Page /playbooks vide pour tenant récent |
| **Cause** | `getLastTenant().id` null quand `setLastTenant()` non appelé |
| **Classe** | Identique à PH-BILLING-PLAN-TRUTH-RECOVERY-02 |
| **Fix** | Passer `useTenant().currentTenantId` à `getPlaybooks()` |
| **Scope** | 4 fichiers client uniquement |
| **Impact DB** | Aucun |
| **Impact API** | Aucun |
| **Impact billing** | Aucun |
| **Impact autopilot** | Aucun |
| **Impact orders/inbox** | Aucun |
| **Multi-tenant** | ✅ Strict, tenant-scoped |

---

## PLAYBOOKS TRUTH RECOVERED — TENANT SAFE — PLAN SAFE — ROLLBACK READY
