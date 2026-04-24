# PH-ADMIN-T8.10F-OWNER-COCKPIT-UI-FOUNDATION-01 — TERMINÉ

**Verdict : GO**

---

## Préflight

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Admin | `main` | ✅ |
| HEAD Admin avant | `63f9ed3` | ✅ |
| Admin DEV avant | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` | ✅ |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | ✅ INCHANGÉE |
| API DEV | `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` | ✅ |
| Repo Admin | clean sur `main` | ✅ |

---

## Contrat actuel (avant patch)

| Surface | Route UI | Proxy Admin | Endpoint backend | Params avant | `scope` avant |
|---|---|---|---|---|---|
| Metrics | `/metrics` | `/api/admin/metrics/overview` | `/metrics/overview` | `from`, `to`, `tenant_id`, `display_currency` | **ABSENT** |
| Funnel metrics | `/marketing/funnel` | `/api/admin/marketing/funnel/metrics` | `/funnel/metrics` | `from`, `to`, `tenant_id` | **ABSENT** |
| Funnel events | `/marketing/funnel` | `/api/admin/marketing/funnel/events` | `/funnel/events` | `from`, `to`, `tenant_id`, `limit` | **ABSENT** |

---

## Design retenu

| Point | Décision |
|---|---|
| Mode par défaut metrics | `scope=owner` toujours envoyé |
| Mode par défaut funnel | `scope=owner` toujours envoyé |
| Toggle présent ? | Non — pas nécessaire dans cette phase |
| Affichage cohorte owner | Badge indigo + résumé cohorte quand `owner_cohort.total > 1` |
| Comportement non-owner | L'API retourne self-only, bandeau masqué, UI propre |

**Justification** : pour un vrai tenant owner, la vue agrégée est utile immédiatement. Pour un tenant non-owner, l'API retourne `self-only` proprement (pas de fuite, pas de confusion).

---

## Patch Metrics

### Proxy `src/app/api/admin/metrics/overview/route.ts`

```diff
+  params.set('scope', 'owner');
```

### Page `src/app/(admin)/metrics/page.tsx`

1. **Interface `MetricsData`** : ajout `scope?: string` et `owner_cohort?: { owner: string; children: string[]; total: number }`
2. **Import** : ajout `Building2` depuis `lucide-react`
3. **Bandeau owner** : div indigo conditionnel `data?.scope === 'owner' && data?.owner_cohort?.total > 1` affichant :
   - Icône Building2
   - "Vue agrégée owner — cohorte de {total} tenants"
   - "Owner : {owner_id} • {n} enfants"
   - Badge "owner-scoped"

---

## Patch Funnel

### Proxy `src/app/api/admin/marketing/funnel/metrics/route.ts`

```diff
+  apiParams.set('scope', 'owner');
```

### Proxy `src/app/api/admin/marketing/funnel/events/route.ts`

```diff
+  apiParams.set('scope', 'owner');
```

### Page `src/app/(admin)/marketing/funnel/page.tsx`

1. **Interface `FunnelMetrics`** : ajout `scope?: string`, `cohort_size?: number`, `owner_cohort?: { owner: string; children: string[]; total: number }`
2. **Import** : ajout `Building2` depuis `lucide-react`
3. **Bandeau owner** : div indigo conditionnel identique, avec ajout de `{cohort_size} funnels`
4. **STEP_LABELS** : ajout des 7 labels post-checkout (`success_viewed`, `dashboard_first_viewed`, `onboarding_started`, `marketplace_connected`, `first_conversation_received`, `first_response_sent`, `activation_completed`)

---

## Validation navigateur DEV

URL : `https://admin-dev.keybuzz.io`

### Cas A — Owner KBC DEV / Metrics

| Test | Attendu | Résultat |
|---|---|---|
| Tenant sélectionné | KeyBuzz Consulting | ✅ |
| Bandeau owner visible | "Vue agrégée owner — cohorte de 3 tenants" | ✅ |
| Owner ID | `keybuzz-consulting-mo9y479d` | ✅ |
| Enfants | 2 | ✅ |
| Badge | "owner-scoped" | ✅ |
| Spend total | 445 £GB | ✅ cohérent API |
| New customers | 2 | ✅ |
| MRR | 0 £GB | ✅ |
| CAC paid | 222.60 £ | ✅ |
| NaN/undefined/Infinity | Aucun | ✅ |

### Cas B — Owner KBC DEV / Funnel

| Test | Attendu | Résultat |
|---|---|---|
| Bandeau owner visible | "Vue agrégée owner — cohorte de 3 tenants" | ✅ |
| Funnels count | "2 funnels" | ✅ |
| 16 steps | Tous affichés avec labels FR | ✅ |
| activation_completed | Step 16, count 0 | ✅ |
| Events récents | 8 events | ✅ |
| NaN/undefined/Infinity | Aucun | ✅ |

### Cas C — Non-owner (Proof No Owner T810B1)

| Test | Attendu | Résultat |
|---|---|---|
| Bandeau owner | ABSENT (pas de confusion) | ✅ |
| Données | "Aucune donnée funnel" (propre) | ✅ |
| Fuite cross-tenant | Aucune | ✅ |

### Cas D — Régression visuelle

| Test | Résultat |
|---|---|
| Overlap | Aucun | ✅ |
| Texte tronqué | Aucun gênant | ✅ |
| Mock | Aucun | ✅ |
| NaN/undefined/Infinity | Aucun | ✅ |

---

## Validation contrat API / proxy

| Couche | Point vérifié | Résultat |
|---|---|---|
| UI → Proxy | `scope=owner` transmis dans les 3 proxies | ✅ |
| Proxy → API metrics | `/metrics/overview?scope=owner&tenant_id=<id>` retourne `owner_cohort` | ✅ |
| Proxy → API funnel metrics | `/funnel/metrics?scope=owner&tenant_id=<id>` retourne `owner_cohort` | ✅ |
| Proxy → API funnel events | `/funnel/events?scope=owner&tenant_id=<id>` retourne events agrégés | ✅ |
| Tenant selector | Fonctionne correctement | ✅ |

---

## Non-régression

| Point | Résultat |
|---|---|
| `/marketing/ad-accounts` | ✅ OK |
| `/marketing/destinations` | ✅ Non touché |
| `/marketing/delivery-logs` | ✅ Non touché |
| `/marketing/integration-guide` | ✅ Non touché |
| Menu Marketing | ✅ Ordre et icônes intacts |
| Token safety | ✅ |
| Admin PROD | ✅ INCHANGÉE — `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| API DEV | ✅ `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` |
| API PROD | ✅ INCHANGÉE — `v3.5.111-activation-completed-model-prod` |
| Client DEV | ✅ INCHANGÉ — `v3.5.112-marketing-owner-mapping-foundation-dev` |
| Client PROD | ✅ INCHANGÉ — `v3.5.110-post-checkout-activation-foundation-prod` |

---

## Image DEV

- **Tag** : `v2.11.12-owner-cockpit-ui-foundation-dev`
- **Commit Admin** : `0332465` (fix unicode + enfants) sur `11f2646` (feat owner cockpit)
- **Digest** : `sha256:ca557b148bfe65844d536892e0289dfb44ce22be3b1f6ecb80c8a878cd0c83f0`
- **Manifest DEV** : `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`
- **Rollback DEV** : `v2.11.11-funnel-metrics-tenant-proxy-fix-dev`

---

## Gaps restants

1. **RBAC agence owner-specific** : pas encore durci — tout utilisateur admin peut voir tout tenant, pas de restriction owner-only spécifique
2. **Ad Accounts / Destinations / Delivery Logs** : n'ont pas encore de storytelling owner cockpit dédié, ne passent pas `scope=owner`
3. **Contrat LP/funnels externes owner-scoped** : pas encore finalisé
4. **Polish UI labels owner** : le bandeau est fonctionnel mais pourrait être enrichi (noms résolus des tenants enfants, lien vers détail enfant, etc.)
5. **Existing-user paths non-owner** : un tenant non-owner reçoit `scope=owner` mais l'API retourne self-only (`total=1`) — le bandeau ne s'affiche pas, aucune fuite
6. **Counts funnel agrégés** : reflètent les events réels (seul `proof-child-funnel-t-mod385lv` a des events funnel), cohérent avec la vérité API

---

## PROD inchangée

**Oui** — aucune modification PROD. Toutes les images PROD sont identiques avant et après cette phase.

---

## Conclusion

**OWNER COCKPIT UI FOUNDATION READY IN DEV — ADMIN MARKETING PAGES NOW CONSUME OWNER-SCOPED DATA — LEGACY PRESERVED — PROD UNTOUCHED**

Rapport : `keybuzz-infra/docs/PH-ADMIN-T8.10F-OWNER-COCKPIT-UI-FOUNDATION-01.md`
