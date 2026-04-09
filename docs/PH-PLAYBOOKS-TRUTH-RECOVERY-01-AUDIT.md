# PH-PLAYBOOKS-TRUTH-RECOVERY-01 — Audit Technique

> Date : 1er mars 2026
> Agent : Cursor Executor
> Environnement : DEV (keybuzz-client-dev)

---

## 1. Où sont stockés les playbooks ?

### Réponse : 100% localStorage (client-side)

| Source | Utilisée ? | Détail |
|--------|-----------|--------|
| **localStorage** | **OUI** | Clé `kb_client_playbooks:v1:<tenantId>` |
| Table DB | NON | Aucune table `playbooks` en DB |
| API Fastify | NON | Aucun endpoint `/playbooks` côté API |
| Routes BFF | EXISTANTES mais INUTILISÉES | `app/api/playbooks/route.ts` appelle le backend mais la page ne l'utilise pas |

La dette technique **D25** confirme : "Simulateur playbooks client-side uniquement | Feature marketing sans backend réel".

---

## 2. Où sont-ils chargés dans le client ?

- `app/playbooks/page.tsx` ligne 29 : `setPlaybooks(getPlaybooks())`
- `getPlaybooks()` défini dans `src/services/playbooks.service.ts`
- Utilise **`getLastTenant().id`** pour construire la clé localStorage

### Chaîne complète :

```
page.tsx useEffect
  → getPlaybooks()
    → getLastTenant().id  ← src/lib/session.ts (lit kb_prefs:v1)
    → localStorage.getItem("kb_client_playbooks:v1:<tenantId>")
    → si vide : initStarterPlaybooks(tenantId)  ← auto-seed 5 starters
    → sinon : parse JSON
```

---

## 3. À quel moment sont-ils initialisés ?

### Auto-seed : oui, mais conditionnel

La logique `initStarterPlaybooks(tenantId)` est déclenchée quand :
1. `typeof window !== "undefined"` (pas SSR)
2. `getLastTenant().id` retourne un ID valide (non null)
3. Aucune donnée n'existe dans localStorage pour `kb_client_playbooks:v1:<tenantId>`

### 5 starter playbooks pré-définis :

| # | Nom | Trigger | Scope | Activé |
|---|-----|---------|-------|--------|
| 1 | Retard livraison - Réponse automatique | `delivery_delay` | both | oui |
| 2 | Où est ma commande ? | `tracking_request` | messages | oui |
| 3 | Produit endommagé - Demande preuve | `damaged_item` | both | oui |
| 4 | Dropshipping - Escalade fournisseur | `supplier_escalation` | orders | **non** |
| 5 | SLA risque - Escalade humain | `unanswered_2h` | messages | oui |

---

## 4. Comment le tenant courant est-il déterminé ?

### Deux sources distinctes (problème identifié) :

| Source | Mécanisme | Fiable ? |
|--------|-----------|----------|
| `getLastTenant().id` | localStorage `kb_prefs:v1` → `lastTenantId` | **NON** — peut être null/stale |
| `useTenant().currentTenantId` | React context via TenantProvider → API `/tenant-context/me` | **OUI** — source de vérité |

### Problème :

`getLastTenant().id` n'est écrit que par `setLastTenant()`, appelé UNIQUEMENT dans :
- `app/select-tenant/page.tsx` (quand l'utilisateur sélectionne un espace)

Si l'utilisateur ne passe PAS par `/select-tenant` (redirect directe, OAuth auto, URL directe),
`lastTenantId` reste null → `getPlaybooks()` retourne `[]` → page vide.

C'est exactement le même bug que **PH-BILLING-PLAN-TRUTH-RECOVERY-02** qui utilisait
`localStorage.currentTenantId` au lieu de `useTenant().currentTenantId`.

---

## 5. Comment le plan courant est-il déterminé ?

Le plan est déterminé par `useCurrentPlan()` qui lit `useTenant().currentTenantId`.
La matrice `planCapabilities.ts` :

| Plan | `hasBasicPlaybooks` | `hasAdvancedPlaybooks` |
|------|---------------------|----------------------|
| STARTER | **true** | false |
| PRO | **true** | **true** |
| AUTOPILOT | **true** | **true** |
| ENTERPRISE | **true** | **true** |

### Gating sur la page /playbooks : **AUCUN**

La page `app/playbooks/page.tsx` n'utilise PAS `FeatureGate`.
Tous les plans, y compris STARTER, peuvent voir les playbooks basiques.

---

## 6. Réponses obligatoires

| Question | Réponse |
|----------|---------|
| Les playbooks sont-ils purement client-side ? | **OUI** — 100% localStorage |
| La source de vérité est-elle ecomlg-001 uniquement ? | **NON** — chaque tenant a ses propres playbooks dans localStorage (clé tenant-scoped) |
| Le tenant SWITAA est-il PRO/AUTOPILOT/ENTERPRISE ? | Non pertinent — le bug est dû au tenantId null, pas au plan |
| La purge SWITAA du 27 mars a-t-elle supprimé la source des playbooks ? | **NON** — les playbooks sont dans le localStorage du NAVIGATEUR, pas en DB. La purge DB n'a aucun impact. |
| L'état vide vient de quoi ? | **Bug de tenantId** — `getLastTenant().id` retourne null quand `setLastTenant()` n'a pas été appelé |

---

## 7. Root cause

**`getPlaybooks()` utilise `getLastTenant().id` (localStorage) au lieu de `useTenant().currentTenantId` (React context TenantProvider).**

Quand `lastTenantId` est null ou stale :
- `getPlaybooks()` retourne `[]`
- La page affiche "Aucun playbook trouvé"
- L'auto-seed ne se déclenche pas (car `tenantId` est null)

C'est la même classe de bug que PH-BILLING-PLAN-TRUTH-RECOVERY-02.

---

## 8. Fix appliqué

### Fichiers modifiés (4)

1. `src/services/playbooks.service.ts` : ajout paramètre `tenantIdOverride?` à `getPlaybooks()` et `getPlaybook()`
2. `app/playbooks/page.tsx` : utilise `useTenant().currentTenantId` au lieu de `getLastTenant().id`
3. `app/playbooks/[playbookId]/page.tsx` : idem
4. `app/playbooks/[playbookId]/tester/page.tsx` : idem

### Diff minimal — zéro régression :
- Aucun changement de logique d'auto-seed
- Aucun changement de structure de données
- Aucun changement de routes BFF
- Aucun changement d'API backend
- Les playbooks existants (ecomlg-001) ne sont pas touchés

---

## 9. Images

| Env | Avant | Après |
|-----|-------|-------|
| DEV | `v3.5.122-ph-amz-ui-state-dev` | `v3.5.123-playbooks-truth-recovery-dev` |
| PROD | `v3.5.122-ph-full-align-prod` | En attente validation DEV |

Rollback DEV : `kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ph-amz-ui-state-dev -n keybuzz-client-dev`
