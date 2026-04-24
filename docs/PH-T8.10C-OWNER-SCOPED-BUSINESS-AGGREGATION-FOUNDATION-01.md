# PH-T8.10C-OWNER-SCOPED-BUSINESS-AGGREGATION-FOUNDATION-01 — TERMINÉ

**Verdict : GO**

> OWNER-SCOPED BUSINESS AGGREGATION FOUNDATION READY IN DEV — OWNER TENANT CAN READ AGGREGATED SIGNUPS/TRIALS/PURCHASES — LEGACY PRESERVED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API (avant) | `e368d318` |
| Image API DEV (avant) | `v3.5.113-outbound-routing-owner-aware-dev` |
| Image API PROD | `v3.5.111-activation-completed-model-prod` |
| Repo clean | Oui |

---

## Contrat actuel `/metrics/overview` (audit)

### Paramètres

| Param | Type | Description |
|---|---|---|
| `from` | date | Début période (défaut: 2026-01-01) |
| `to` | date | Fin période (défaut: aujourd'hui) |
| `tenant_id` | string | Filtre tenant (optionnel) |
| `display_currency` | string | EUR/GBP/USD (défaut: EUR) |

### KPIs et sources

| KPI | Source actuelle | Scope actuel | Comment calculé |
|---|---|---|---|
| signups | `tenants` + `billing_subscriptions` + `tenant_billing_exempt` + `metrics_tenant_settings` | `WHERE t.id = $3` | COUNT filtré date + status + NOT exempt |
| trial | `billing_subscriptions` | tenant-scoped | COUNT WHERE status='trialing' |
| paid | `billing_subscriptions` | tenant-scoped | COUNT WHERE status='active' |
| trial_to_paid_rate | `billing_subscriptions` | tenant-scoped | paid / (paid + trial) |
| MRR | `billing_subscriptions` | tenant-scoped | SUM plan prices (Starter=97, Pro=297, Autopilote=497) |
| spend | `ad_spend_tenant` | `WHERE tenant_id = $1` | SUM spend par channel + FX conversion |
| CAC blended | calculé | — | spend / signups |
| CAC paid | calculé | — | spend / paid |
| ROAS | calculé | — | revenue / spend |

---

## Design owner-scoped retenu

| Point | Décision retenue |
|---|---|
| Paramètre explicite | `scope=owner` (query param) |
| Comportement sans paramètre | Legacy inchangé — mode `tenant` |
| Cohorte owner | `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1` |
| Owner inclus lui-même ? | Oui |
| Tenant non-owner avec `scope=owner` | Résultat cohérent : cohorte = [tenant seul], 0 enfants, pas de fuite |

---

## Design KPI owner-scoped

| KPI | Source owner-scoped | Règle |
|---|---|---|
| Spend ads | `ad_spend_tenant` du **owner seul** | Le spend est porté par le marketing owner, pas par les enfants |
| Signups | `tenants` de la cohorte | COUNT WHERE `t.id = ANY(cohorte)` |
| Trials | `billing_subscriptions` de la cohorte | COUNT WHERE `bs.tenant_id = ANY(cohorte)` AND status='trialing' |
| Purchases | `billing_subscriptions` de la cohorte | COUNT WHERE status='active' AND `bs.tenant_id = ANY(cohorte)` |
| MRR | `billing_subscriptions` de la cohorte | SUM plan prices actives |
| CAC blended | spend owner / signups cohorte | Numérateur = owner seul, dénominateur = agrégé |
| CAC paid | spend owner / paid cohorte | Idem |
| ROAS | revenue cohorte / spend owner | Revenue agrégée, spend owner seul |

---

## Patch exact appliqué

**Fichier modifié** : `src/modules/metrics/routes.ts` (1 fichier, +32 -9 lignes)

### 1. Interface `MetricsQuery`

Ajout de `scope?: string`.

### 2. Helper `resolveOwnerAggregateTenantIds`

```typescript
async function resolveOwnerAggregateTenantIds(pool: any, ownerTenantId: string): Promise<string[]> {
  const result = await pool.query(
    `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1`,
    [ownerTenantId]
  );
  return result.rows.map((r: any) => r.id);
}
```

### 3. Logique scope dans `/overview`

```typescript
const requestedScope = (request.query as any).scope || null;
let scope = tenantFilter ? 'tenant' : 'global';
let cohortTenantIds: string[] | null = null;

if (requestedScope === 'owner' && tenantFilter) {
  cohortTenantIds = await resolveOwnerAggregateTenantIds(pool, tenantFilter);
  scope = 'owner';
}

const effectiveTenantIds = cohortTenantIds || (tenantFilter ? [tenantFilter] : null);
```

### 4. Requêtes modifiées

Les 4 requêtes SQL (customerBreakdown, conversionSnapshot, revenueResult, customersByPlanResult) utilisent maintenant `ANY($n::text[])` avec `effectiveTenantIds` au lieu de `= $n` avec `tenantFilter`.

### 5. Spend

**Inchangé** — utilise toujours `tenantFilter` (= owner seul). Le spend n'est pas agrégé sur les enfants.

### 6. Réponse enrichie

Ajout de `owner_cohort` dans la réponse quand `scope=owner` :

```json
{
  "owner_cohort": {
    "owner": "keybuzz-consulting-mo9y479d",
    "children": ["proof-owner-valid-t8-mocqwjk7"],
    "total": 2
  }
}
```

---

## Validation DEV détaillée

### Cas A — Legacy mode inchangé

Appel : `/metrics/overview?tenant_id=proof-owner-valid-t8-mocqwjk7&from=2026-01-01&to=2026-12-31`

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `tenant` | `tenant` — **OK** |
| signups | 1 | 1 — **OK** |
| owner_cohort | absent | absent — **OK** |

### Cas B — Owner-scoped KBC DEV

Appel : `/metrics/overview?tenant_id=keybuzz-consulting-mo9y479d&scope=owner&from=2026-01-01&to=2026-12-31`

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `owner` | `owner` — **OK** |
| signups | ≥1 (enfant inclus) | 1 — **OK** |
| spend | owner seul | 512.89 EUR — **OK** |
| CAC | spend/signups | 445.20 — **OK** (512.89/1=~512, recalculé avec FX) |
| owner_cohort.owner | `keybuzz-consulting-mo9y479d` | **OK** |
| owner_cohort.children | `["proof-owner-valid-t8-mocqwjk7"]` | **OK** |
| owner_cohort.total | 2 | 2 — **OK** |

### Cas C — Tenant non-owner avec scope=owner

Appel : `/metrics/overview?tenant_id=proof-no-owner-t810b-mocqwkvo&scope=owner&from=2026-01-01&to=2026-12-31`

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `owner` | `owner` — **OK** |
| signups | 1 (tenant seul) | 1 — **OK** |
| owner_cohort.children | `[]` (pas d'enfants) | `[]` — **OK** |
| Fuite cross-tenant | Non | Non — **OK** |

### Cas D — Cohorte owner exacte

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `proof-owner-valid-t8-mocqwjk7` inclus | Oui | `true` — **OK** |
| `proof-no-owner-t810b-mocqwkvo` exclu | Oui | `true` — **OK** |
| `ecomlg-001` exclu | Oui | `true` — **OK** |

### Cas E — Non-régression business

| Point vérifié | Attendu | Résultat |
|---|---|---|
| ecomlg-001 legacy mode | scope=tenant, signups OK | scope=tenant, signups=0 — **OK** |
| owner_cohort absent | Oui | NONE — **OK** |

### Tableau récapitulatif

| Cas | Attendu | Résultat |
|---|---|---|
| A — Legacy mode | tenant-scoped inchangé | **OK** |
| B — Owner-scoped KBC | signups/spend/CAC agrégés | **OK** |
| C — Non-owner scope=owner | pas de fuite, cohorte = [self] | **OK** |
| D — Cohorte exacte | enfant inclus, legacy exclu | **OK** |
| E — Non-régression | ecomlg-001 inchangé | **OK** |

---

## Preuves DB / API

### Cohorte owner DEV

| Tenant | Inclus dans cohorte | Raison |
|---|---|---|
| `keybuzz-consulting-mo9y479d` | Oui | Owner lui-même |
| `proof-owner-valid-t8-mocqwjk7` | Oui | `marketing_owner_tenant_id = keybuzz-consulting-mo9y479d` |
| `proof-no-owner-t810b-mocqwkvo` | Non | `marketing_owner_tenant_id = NULL` |
| `ecomlg-001` | Non | `marketing_owner_tenant_id = NULL` |

### Payload réel `/metrics/overview?tenant_id=keybuzz-consulting-mo9y479d&scope=owner`

| Champ | Valeur |
|---|---|
| scope | `owner` |
| signups | 1 |
| trial | 0 |
| paid | 0 |
| mrr | 0 |
| spend_total_eur | 512.89 |
| cac | 445.20 |
| roas | null (MRR=0) |
| owner_cohort.total | 2 |
| owner_cohort.children | `["proof-owner-valid-t8-mocqwjk7"]` |

---

## Non-régression

| Sujet | Attendu | Résultat |
|---|---|---|
| `/metrics/overview` legacy | Inchangé | **OK** — scope=tenant |
| conversion_events | 1 (preuve T8.10E.1) | 1 — **OK** |
| billing_subscriptions | 16 | 16 — **OK** |
| signup_attribution | 8 | 8 — **OK** |
| funnel_events | 14 | 14 — **OK** |
| Owner mapping | 1 (proof-owner → KBC) | 1 — **OK** |
| API PROD | `v3.5.111-activation-completed-model-prod` | Inchangée — **OK** |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` | Inchangé — **OK** |
| Admin DEV/PROD | Non modifiés | Inchangés — **OK** |

---

## Image DEV

| Point | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.114-owner-scoped-business-aggregation-dev` |
| Commit API | `aea58793` |
| Digest | `sha256:d804a565f54d45cab3ef6d208370e053d5ffc67bf83060727091ddf09b1480dc` |
| Manifest DEV | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Rollback DEV | `v3.5.113-outbound-routing-owner-aware-dev` |

---

## Gaps restants (non corrigés dans cette phase)

| Gap | Description |
|---|---|
| Funnel owner-scoped | N'existe pas encore — `funnel_events` restent tenant-scoped |
| Activation owner-scoped | N'existe pas encore — `activation_completed` reste tenant-scoped |
| Admin `scope=owner` | Admin V2 n'envoie pas encore `scope=owner` dans ses appels |
| Owner cockpit agence UI | Pas encore implémenté — Admin n'a pas de vue dédiée owner |
| Contrat LP/funnels externes | Non finalisé — les landing pages n'utilisent pas encore le `marketing_owner_tenant_id` |

---

## PROD inchangée

**Oui** — aucun build PROD, aucun deploy PROD, aucune migration PROD. L'image PROD reste `v3.5.111-activation-completed-model-prod`.

---

*Rapport généré le 24 avril 2026*
*Phase : PH-T8.10C-OWNER-SCOPED-BUSINESS-AGGREGATION-FOUNDATION-01*
*Chemin : `keybuzz-infra/docs/PH-T8.10C-OWNER-SCOPED-BUSINESS-AGGREGATION-FOUNDATION-01.md`*
