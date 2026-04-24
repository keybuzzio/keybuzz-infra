# PH-T8.10E-OUTBOUND-ROUTING-OWNER-AWARE-01 — TERMINÉ

**Verdict : GO**

> OUTBOUND ROUTING OWNER-AWARE READY IN DEV — BUSINESS CONVERSIONS ROUTE VIA MARKETING OWNER WHEN PRESENT — LEGACY PRESERVED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API (avant) | `f43642d8` |
| Image API DEV (avant) | `v3.5.112-marketing-owner-mapping-foundation-dev` |
| Image API PROD | `v3.5.111-activation-completed-model-prod` |
| Repo clean | Oui |
| Source | `ph147.4/source-of-truth` confirmé |
| DEV uniquement | Oui |
| PROD inchangée | Oui |

---

## Routing actuel (audit)

| Sujet | Emplacement code | Comportement actuel |
|---|---|---|
| StartTrial émis | `billing/routes.ts:1564` | `emitOutboundConversion('StartTrial', tenantId, ...)` — tenantId = runtime |
| Purchase émis | `billing/routes.ts:1713` | `emitOutboundConversion('Purchase', tenantId, ...)` — tenantId = runtime |
| Résolution destinations | `emitter.ts:getActiveDestinations(pool, tenantId)` | `SELECT ... FROM outbound_conversion_destinations WHERE tenant_id = $1` — toujours le runtime tenant |
| Gap critique | `emitter.ts` | Aucune résolution `marketing_owner_tenant_id` — un enfant marketing sans destinations propres = événement perdu |

---

## Design retenu

| Point | Décision retenue |
|---|---|
| Tenant du business event | **Runtime tenant** — inchangé dans `conversion_events` et `payload` |
| Tenant de lookup destination | **`marketing_owner_tenant_id`** si présent, sinon runtime tenant |
| Fallback legacy | Si `marketing_owner_tenant_id` est `NULL` → comportement identique à aujourd'hui |
| Comportement owner manquant | Si le SELECT retourne `NULL` ou aucune ligne → fallback au tenantId d'entrée |

---

## Patch exact appliqué

**Fichier modifié** : `src/modules/outbound-conversions/emitter.ts` (1 fichier, +23 -3 lignes)

### 1. Nouveau helper `resolveOutboundRoutingTenantId`

Ajouté après `let tableChecked = false;` (ligne 48) :

```typescript
async function resolveOutboundRoutingTenantId(
  pool: any, runtimeTenantId: string
): Promise<{ routingTenantId: string; isOwnerRouted: boolean }> {
  try {
    const result = await pool.query(
      'SELECT marketing_owner_tenant_id FROM tenants WHERE id = $1',
      [runtimeTenantId]
    );
    const ownerTenantId = result.rows[0]?.marketing_owner_tenant_id || null;
    if (ownerTenantId) {
      console.log(`[OutboundConv] Owner-aware routing: runtime=${runtimeTenantId} -> owner=${ownerTenantId}`);
      return { routingTenantId: ownerTenantId, isOwnerRouted: true };
    }
  } catch (err: any) {
    console.warn(`[OutboundConv] resolveOutboundRoutingTenantId failed: ${err.message?.substring(0, 100)}`);
  }
  return { routingTenantId: runtimeTenantId, isOwnerRouted: false };
}
```

### 2. Modification dans `emitOutboundConversion`

Remplacement de :
```typescript
const destinations = await getActiveDestinations(pool, tenantId);
```
Par :
```typescript
const { routingTenantId, isOwnerRouted } = await resolveOutboundRoutingTenantId(pool, tenantId);
const destinations = await getActiveDestinations(pool, routingTenantId);
```

### 3. Logs enrichis

Les logs "No destinations" et "FAILED" incluent maintenant le tenant de routing et si c'est un routing owner.

### Ce qui n'a PAS changé

- `billing/routes.ts` — appels `emitOutboundConversion` strictement inchangés
- `conversion_events.tenant_id` — reste le runtime tenant
- Payload — `customer.tenant_id` reste le runtime tenant
- `event_id` — format inchangé, idempotence préservée
- Schéma DB — aucune migration

---

## Validation DEV détaillée

### Cas A — Owner-mappé, routing owner attendu

| Point | Résultat |
|---|---|
| Tenant enfant | `proof-owner-valid-t8-mocqwjk7` |
| `marketing_owner_tenant_id` | `keybuzz-consulting-mo9y479d` |
| Destination de test créée sur owner | `b413a353-3d54-4c76-b292-d0e7ee57823e` (webhook httpbin.org) |
| Log routing | `[OutboundConv] Owner-aware routing: runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d` |
| Delivery | `StartTrial sent to T810E-routing-test: HTTP 200 (attempt 1)` |
| `conversion_events.tenant_id` | `proof-owner-valid-t8-mocqwjk7` (runtime — correct) |
| `conversion_events.status` | `sent` |
| `delivery_logs.status` | `delivered` (http_status: 200) |

### Cas B — Legacy sans owner

| Point | Résultat |
|---|---|
| Tenant | `proof-no-owner-t810b-mocqwkvo` |
| `marketing_owner_tenant_id` | `NULL` |
| Log routing | `[OutboundConv] No destinations for proof-no-owner-t810b-mocqwkvo, skipping StartTrial` |
| Fallback legacy | Correct — lookup sur le tenant runtime |

### Cas C — Destination owner absente

| Point | Résultat |
|---|---|
| Scénario | Owner résolu mais 0 destinations actives |
| Comportement | Skip propre — pas de crash, log explicite |
| Preuve | Cas A sans la destination temporaire montre le même comportement |

### Cas D — Non-régression business

| Point | Résultat |
|---|---|
| StartTrial | Intact |
| Purchase | Intact |
| conversion_events | 0 (propre — test data nettoyée) |
| billing_subscriptions | 16 (inchangé) |
| signup_attribution | 8 (inchangé) |
| funnel_events | 14 (inchangé) |

### Tableau récapitulatif

| Cas | Attendu | Résultat |
|---|---|---|
| A — Owner-mappé | Routing via `keybuzz-consulting-mo9y479d` | **OK** — delivery HTTP 200 |
| B — Legacy sans owner | Routing via runtime tenant | **OK** — fallback correct |
| C — Owner sans destination | Skip propre | **OK** — pas de crash |
| D — Non-régression | Aucune donnée altérée | **OK** — tous compteurs intacts |

---

## Preuves logs/delivery

### Log owner-aware routing (stdout pod)

```
[OutboundConv] Owner-aware routing: runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d
[OutboundConv] StartTrial sent to T810E-routing-test: HTTP 200 (attempt 1)
```

### conversion_events (avant cleanup)

```json
{
  "event_id": "conv_proof-owner-valid-t8-mocqwjk7_StartTrial_sub_test_t810e_routing",
  "tenant_id": "proof-owner-valid-t8-mocqwjk7",
  "event_name": "StartTrial",
  "status": "sent"
}
```

Le `tenant_id` dans `conversion_events` reste le tenant enfant runtime — seul le lookup des destinations passe par le owner.

### outbound_conversion_delivery_logs (avant cleanup)

```json
{
  "destination_id": "b413a353-3d54-4c76-b292-d0e7ee57823e",
  "event_name": "StartTrial",
  "event_id": "conv_proof-owner-valid-t8-mocqwjk7_StartTrial_sub_test_t810e_routing",
  "status": "delivered",
  "http_status": 200
}
```

La destination `b413a353-...` appartient au owner `keybuzz-consulting-mo9y479d` — preuve que le routing a bien ciblé le owner.

### Données de test nettoyées

Toutes les données de test (destination temporaire, conversion_events, delivery_logs) ont été supprimées après validation.

---

## Non-régression

| Sujet | Résultat |
|---|---|
| conversion_events | 0 (propre) |
| billing_subscriptions | 16 (inchangé) |
| signup_attribution | 8 (inchangé) |
| funnel_events | 14 (inchangé) |
| tenants total | 22 (dont 1 avec owner) |
| Tenant legacy sans owner | OK — comportement inchangé |
| Admin DEV/PROD | Inchangés |
| Client DEV/PROD | Inchangés |
| PROD | `v3.5.111-activation-completed-model-prod` — inchangée |

---

## Image DEV

| Point | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.113-outbound-routing-owner-aware-dev` |
| Commit API | `e368d318` |
| Digest | `sha256:4a741f0ecf46467d588c1186d7f0c969e3dd39c6433cddfb9d7277aac7a614e2` |
| Manifest DEV | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Rollback DEV | `v3.5.112-marketing-owner-mapping-foundation-dev` |

---

## Gaps restants (non corrigés dans cette phase)

| Gap | Description |
|---|---|
| `/metrics/overview` owner-aggregated | N'existe pas encore — les métriques sont toujours tenant-scoped |
| Funnel/activation owner-aggregated | N'existe pas encore — les funnel_events sont tenant-scoped |
| Admin owner cockpit dédié | N'existe pas encore — Admin V2 n'a pas de vue agrégée par owner |
| Contrat LP/funnels externes owner-scoped | Non finalisé — les landing pages externes n'utilisent pas encore le `marketing_owner_tenant_id` |
| Destinations Meta CAPI owner DEV | Aucune destination active sur le owner DEV — à configurer via Admin |

---

## État final

| Sujet | État final |
|---|---|
| Branch API | `ph147.4/source-of-truth` |
| HEAD API | `e368d318` |
| Image DEV | `v3.5.113-outbound-routing-owner-aware-dev` |
| Image PROD | `v3.5.111-activation-completed-model-prod` (inchangée) |
| Working tree API | Clean |
| Runtime | Inchangé pour PROD, DEV mis à jour |

---

## PROD inchangée

**Oui** — aucun build PROD, aucun deploy PROD, aucune migration PROD. L'image PROD reste `v3.5.111-activation-completed-model-prod`.

---

*Rapport généré le 1 mars 2026*
*Phase : PH-T8.10E-OUTBOUND-ROUTING-OWNER-AWARE-01*
*Chemin : `keybuzz-infra/docs/PH-T8.10E-OUTBOUND-ROUTING-OWNER-AWARE-01.md`*
