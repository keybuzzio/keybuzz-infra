# PH-T8.10D-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-AGGREGATION-FOUNDATION-01 — TERMINÉ

**Verdict : GO**

> OWNER-SCOPED FUNNEL AND ACTIVATION AGGREGATION FOUNDATION READY IN DEV — OWNER TENANT CAN READ AGGREGATED FUNNELS AND ACTIVATION — LEGACY PRESERVED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API (avant) | `aea58793` (PH-T8.10C) |
| Image API DEV (avant) | `v3.5.114-owner-scoped-business-aggregation-dev` |
| Image API PROD | `v3.5.111-activation-completed-model-prod` (inchangée) |
| Repo clean | Oui |

---

## Contrat actuel funnel (audit)

### Endpoints

| Endpoint | Paramètres actuels | Scope actuel | Notes |
|---|---|---|---|
| `GET /funnel/metrics` | `tenant_id`, `from`, `to` | Cohort stitching par `funnel_id` | Résout les funnel_ids du tenant, agrège ALL events incl. pré-tenant |
| `GET /funnel/events` | `funnel_id`, `tenant_id`, `from`, `to`, `limit` | Cohort stitching par `funnel_id` | Même logique de résolution |
| `POST /funnel/event` | body: funnel_id, event_name, source... | N/A (write) | Non modifié |

### Logique de cohort stitching existante

1. `resolveTenantFunnelCohort(pool, tenantId)` → `SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = $1`
2. Puis `WHERE funnel_id = ANY(cohort)` capture les steps pré-tenant (tenant_id=NULL) liés au même funnel
3. Les 16 steps suivent un ordre canonique fixe défini dans `ALLOWED_EVENTS`

### 16 steps canoniques

| # | Nom | Phase |
|---|---|---|
| 1 | `register_started` | Pré-tenant |
| 2 | `plan_selected` | Pré-tenant |
| 3 | `email_submitted` | Pré-tenant |
| 4 | `otp_verified` | Pré-tenant |
| 5 | `oauth_started` | Pré-tenant |
| 6 | `company_completed` | Pré-tenant |
| 7 | `user_completed` | Pré-tenant |
| 8 | `tenant_created` | Création tenant |
| 9 | `checkout_started` | Checkout |
| 10 | `success_viewed` | Post-checkout |
| 11 | `dashboard_first_viewed` | Post-checkout |
| 12 | `onboarding_started` | Post-checkout |
| 13 | `marketplace_connected` | Activation |
| 14 | `first_conversation_received` | Activation |
| 15 | `first_response_sent` | Activation |
| 16 | `activation_completed` | Activation (dérivé) |

---

## Design owner-scoped retenu

| Point | Décision retenue |
|---|---|
| Paramètre explicite | `scope=owner` (query param, cohérent avec `/metrics/overview`) |
| Comportement sans paramètre | Legacy inchangé — tenant-scoped via cohort stitching |
| Cohorte owner | `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1` |
| Owner inclus lui-même ? | Oui |
| Non-owner avec `scope=owner` | Cohorte = [self], 0 enfants, résultat propre, pas de fuite |

---

## Design agrégation funnel owner-scoped

| Étape du design | Décision retenue |
|---|---|
| Owner → tenants | `resolveOwnerAggregateTenantIds(pool, ownerTenantId)` → [owner, enfant1, enfant2...] |
| Tenants → funnels | `SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = ANY(tenantIds)` |
| Inclusion pré-tenant | Oui — via `WHERE funnel_id = ANY(funnelIds)` qui capture les steps avec tenant_id=NULL |
| Inclusion post-checkout | Oui — mêmes funnel_ids |
| Inclusion activation_completed | Oui — mêmes funnel_ids (step #16) |

### Chaîne de résolution

```
owner_tenant_id
    → resolveOwnerAggregateTenantIds → [owner, child_1, child_2, ...]
        → resolveOwnerFunnelCohort → { funnelIds: [f1, f2, ...], tenantIds: [...] }
            → WHERE funnel_id = ANY(funnelIds)
                → inclut steps pré-tenant (tenant_id=NULL)
                → inclut steps post-checkout (tenant_id=child_x)
                → inclut activation_completed (tenant_id=child_x)
```

---

## Patch exact appliqué

**Fichier modifié** : `src/modules/funnel/routes.ts` (1 fichier, +63 -8 lignes)

### 1. Helper `resolveOwnerAggregateTenantIds`

```typescript
async function resolveOwnerAggregateTenantIds(pool: any, ownerTenantId: string): Promise<string[]> {
  const result = await pool.query(
    `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1`,
    [ownerTenantId]
  );
  return result.rows.map((r: any) => r.id);
}
```

### 2. Helper `resolveOwnerFunnelCohort`

```typescript
async function resolveOwnerFunnelCohort(pool: any, ownerTenantId: string): Promise<{ funnelIds: string[]; tenantIds: string[] }> {
  const tenantIds = await resolveOwnerAggregateTenantIds(pool, ownerTenantId);
  const result = await pool.query(
    `SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = ANY($1::text[])`,
    [tenantIds]
  );
  return { funnelIds: result.rows.map((r: any) => r.funnel_id), tenantIds };
}
```

### 3. Modifications `GET /funnel/events`

- Ajout `scope?: string` dans le Querystring
- Si `scope=owner` : utilise `resolveOwnerFunnelCohort` au lieu de `resolveTenantFunnelCohort`
- Ajout `owner_cohort` et `scope: 'owner'` dans la réponse

### 4. Modifications `GET /funnel/metrics`

- Ajout `scope?: string` dans le Querystring
- Si `scope=owner` : utilise `resolveOwnerFunnelCohort` au lieu de `resolveTenantFunnelCohort`
- Ajout `owner_cohort` et `scope: 'owner'` dans la réponse
- Variable `cohortSize` unifiée pour les deux modes

### 5. Inchangé

- `POST /funnel/event` : aucune modification (write path)
- `emitFunnelEvent()` : inchangé
- `emitActivationEvent()` : inchangé
- `tryEmitActivationCompleted()` : inchangé
- Ordre canonique des 16 steps : inchangé

---

## Validation DEV détaillée

### Cas A — Legacy mode inchangé

**`/funnel/metrics?tenant_id=proof-owner-valid-t8-mocqwjk7`**

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | absent (legacy) | absent — **OK** |
| owner_cohort | absent | absent — **OK** |
| steps_count | 16 | 16 — **OK** |

**`/funnel/events?tenant_id=proof-owner-valid-t8-mocqwjk7`**

| Point vérifié | Attendu | Résultat |
|---|---|---|
| scope | absent | absent — **OK** |
| owner_cohort | absent | absent — **OK** |

### Cas B — Owner-scoped KBC DEV

**`/funnel/metrics?tenant_id=keybuzz-consulting-mo9y479d&scope=owner`**

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `owner` | `owner` — **OK** |
| owner_cohort.owner | `keybuzz-consulting-mo9y479d` | **OK** |
| owner_cohort.children | `["proof-owner-valid-t8-mocqwjk7"]` | **OK** |
| owner_cohort.total | 2 | 2 — **OK** |
| cohort_size (funnels) | ≥1 | 1 — **OK** |
| steps_count | 16 | 16 — **OK** |
| last_step | `activation_completed` | `activation_completed` — **OK** |
| Non-zero steps | pré-tenant + checkout inclus | 8 steps non-zero — **OK** |

Steps non-zero détectés : `register_started=1, plan_selected=1, email_submitted=1, otp_verified=1, company_completed=1, user_completed=1, tenant_created=1, checkout_started=1`

**`/funnel/events?tenant_id=keybuzz-consulting-mo9y479d&scope=owner`**

| Point vérifié | Attendu | Résultat |
|---|---|---|
| count | 8 events | 8 — **OK** |
| scope | `owner` | `owner` — **OK** |
| Pré-tenant inclus | 6 events (tenant_id=NULL) | 6 events NULL — **OK** |
| Post-tenant inclus | 2 events (tenant_id=KBC) | 2 events KBC — **OK** |

### Cas C — Non-owner avec scope=owner

**`/funnel/metrics?tenant_id=proof-no-owner-t810b-mocqwkvo&scope=owner`**

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `owner` | `owner` — **OK** |
| owner_cohort.children | `[]` | `[]` — **OK** |
| owner_cohort.total | 1 | 1 — **OK** |
| cohort_size | 0 | 0 — **OK** |
| Fuite cross-tenant | Non | Non — **OK** |

### Cas D — Cohorte exacte

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `proof-owner-valid-t8-mocqwjk7` inclus | Oui | `true` — **OK** |
| `proof-no-owner-t810b-mocqwkvo` exclu | Oui | `true` — **OK** |
| `ecomlg-001` exclu | Oui | `true` — **OK** |

### Cas E — Non-régression funnel order

| Point vérifié | Attendu | Résultat |
|---|---|---|
| 16 steps | 16 | 16 — **OK** |
| Step #16 = `activation_completed` | Oui | `true` — **OK** |
| Step #1 = `register_started` | Oui | `true` — **OK** |
| Step #9 = `checkout_started` | Oui | `true` — **OK** |
| Ordre canonique préservé | Oui | **OK** |

### Tableau récapitulatif

| Cas | Attendu | Résultat |
|---|---|---|
| A — Legacy mode | tenant-scoped inchangé, pas de scope | **OK** |
| B — Owner-scoped KBC | funnels agrégés, pré-tenant+checkout inclus | **OK** |
| C — Non-owner scope=owner | cohorte=[self], 0 enfants, pas de fuite | **OK** |
| D — Cohorte exacte | enfant inclus, legacy exclu | **OK** |
| E — Non-régression funnel order | 16 steps, activation_completed en #16 | **OK** |

---

## Preuves DB / API

### Cohorte owner DEV

| Tenant | Inclus | Raison |
|---|---|---|
| `keybuzz-consulting-mo9y479d` | Oui | Owner |
| `proof-owner-valid-t8-mocqwjk7` | Oui | `marketing_owner_tenant_id = KBC` |
| `proof-no-owner-t810b-mocqwkvo` | Non | `marketing_owner_tenant_id = NULL` |
| `ecomlg-001` | Non | `marketing_owner_tenant_id = NULL` |

### Funnel_ids inclus dans la cohorte owner

1 funnel_id résolu (celui du funnel d'inscription KBC), contenant 8 events dont 6 pré-tenant (tenant_id=NULL).

### Payload réel `/funnel/events?tenant_id=keybuzz-consulting-mo9y479d&scope=owner`

```
8 events total :
1. register_started (tenant_id=NULL)
2. plan_selected (tenant_id=NULL)
3. email_submitted (tenant_id=NULL)
4. otp_verified (tenant_id=NULL)
5. company_completed (tenant_id=NULL)
6. user_completed (tenant_id=NULL)
7. tenant_created (tenant_id=keybuzz-consulting-mo9y479d)
8. checkout_started (tenant_id=keybuzz-consulting-mo9y479d)
```

Preuve que les steps pré-tenant sont bien conservés via funnel_id stitching : 6/8 events ont `tenant_id=NULL` mais sont inclus car leur `funnel_id` est associé au tenant owner.

### Preuve d'exclusion legacy

`proof-no-owner-t810b-mocqwkvo` avec `scope=owner` retourne `cohort_size: 0` et `owner_cohort.children: []` — aucune fuite cross-tenant.

---

## Non-régression

| Sujet | Attendu | Résultat |
|---|---|---|
| `/funnel/metrics` legacy | Inchangé | **OK** |
| `/funnel/events` legacy | Inchangé | **OK** |
| `/metrics/overview` owner-scoped | scope=owner, cohort intact | **OK** |
| conversion_events | 1 | 1 — **OK** |
| billing_subscriptions | 16 | 16 — **OK** |
| signup_attribution | 8 | 8 — **OK** |
| funnel_events | 14 | 14 — **OK** |
| API PROD | `v3.5.111-activation-completed-model-prod` | Inchangée — **OK** |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` | Inchangé — **OK** |
| Admin DEV/PROD | Non modifiés | Inchangés — **OK** |

---

## Image DEV

| Point | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.115-owner-scoped-funnel-activation-aggregation-dev` |
| Commit API | `3162056a` |
| Digest | `sha256:07b6d363450f68308c126598cabe7da677b79a94eccad202ca8d689b90f7e00c` |
| Manifest DEV | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Rollback DEV | `v3.5.114-owner-scoped-business-aggregation-dev` |

---

## Gaps restants (non corrigés dans cette phase)

| Gap | Description |
|---|---|
| Admin `scope=owner` | Admin V2 n'envoie pas encore `scope=owner` dans ses appels funnel |
| Cockpit agence owner UI | Pas encore implémenté dans l'Admin |
| Contrat LP/funnels externes | Non finalisé — les landing pages n'utilisent pas encore `marketing_owner_tenant_id` |
| LinkedIn/Google/TikTok cockpit | Pas encore branché |
| Signups existing-user path | Si un utilisateur existant rejoint un nouveau tenant via invite, le funnel peut ne pas avoir de steps pré-tenant — limitation existante, non introduite par cette phase |

---

## PROD inchangée

**Oui** — aucun build PROD, aucun deploy PROD. L'image PROD reste `v3.5.111-activation-completed-model-prod`.

---

*Rapport généré le 24 avril 2026*
*Phase : PH-T8.10D-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-AGGREGATION-FOUNDATION-01*
*Chemin : `keybuzz-infra/docs/PH-T8.10D-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-AGGREGATION-FOUNDATION-01.md`*
