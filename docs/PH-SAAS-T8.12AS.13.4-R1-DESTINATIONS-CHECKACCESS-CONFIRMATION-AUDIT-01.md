# PH-SAAS-T8.12AS.13.4-R1-DESTINATIONS-CHECKACCESS-CONFIRMATION-AUDIT-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.4-R1-DESTINATIONS-CHECKACCESS-CONFIRMATION-AUDIT-01
> Environnement : DEV + PROD read-only. Aucun patch, build, deploy ou mutation.

---

## 1. VERDICT

GO DESTINATIONS CHECKACCESS CONFIRMED READY
GO R1 CLOSEOUT DECISION READY

Les 6 endpoints HTTP `/outbound-conversions/destinations*` exposes par `keybuzz-api/src/modules/outbound-conversions/routes.ts` sont deja proteges en DEV et PROD par le pattern `checkAccess` local (identique a celui livre par AS.13.1 google-observability). Audit source : 6/6 handlers verifient `x-user-email` + `tenantId` (400 si absent) puis `checkAccess(pool, email, tenantId, x-admin-role)` (403 si non-member et hors `ADMIN_BYPASS_ROLES`) avant toute lecture DB, mutation INSERT/UPDATE/DELETE ou appel webhook tiers. Runtime probes negative-only DEV (8) + PROD (4) confirment l alignement : 400 no-auth, 403 fake/fake non-member sur les 6 endpoints incluant POST `/:id/test` (qui declencherait un webhook vers la destination provider tiers).

DB `outbound_conversion_destinations` PROD : 14 total / 4 active / 3 enabled / 16 delivery logs ; aucune mutation induite par les probes. 0 5xx API PROD 2 min. Protections AS.13.1 / AS.13.2A / AS.13.3A / AS.12.1 preservees (samples DEV+PROD 400/400/400/400/401/401/403).

**0 patch necessaire pour AS.13.4.** R1 surfaces (compat + outbound + destinations + google-observability) sont toutes fermees apres AS.13.1, AS.13.2A, AS.13.3A. Recommandation : KEY-313 eligible au closeout apres GO Ludovic explicite, avec ouverture de tickets de suivi pour R2.2 (outbound UPDATEs scope) et R3 (backend defense-in-depth).

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface auditee | API HTTP `/outbound-conversions/destinations*` (6 endpoints) |
| Module source | `keybuzz-api/src/modules/outbound-conversions/routes.ts` (21598 bytes) |
| Type d audit | Confirmation read-only ; aucun patch, build, deploy, mutation DB, provider call |
| Verdict | 0 patch necessaire. Pattern `checkAccess` deja en place. |
| Hors scope (gaps documentes en section 8) | R2.2 outbound UPDATE WHERE tenant_id, R3 backend defense-in-depth, U2 surveillance logs compat Amazon post-promotion |

---

## 3. SOURCES RELUES

- PH-SAAS-T8.12AS.13.0-R1-OUTBOUND-COMPAT-TENANTGUARD-TRUTH-AUDIT-01.md (truth audit initial)
- PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md (pattern checkAccess origine)
- PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md (pattern tenantGuard global)
- PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-PROD-01.md (pattern PROTECTED_ROUTES static)
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md
- Linear KEY-313

---

## 4. PREFLIGHT

### 4.1 Repos

| Repo | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 8f162dde | OK | dist/ deleted en worktree (cosmetique) | OK lecture |
| keybuzz-infra | main | 3078b654 | OK | clean | OK |

### 4.2 Runtime

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-api | v3.5.189-compat-amazon-tenantguard-dev |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev |
| PROD | keybuzz-api | v3.5.189-compat-amazon-tenantguard-prod |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Tous ready post AS.13.3A-PROD. Aucun rollout en cours.

---

## 5. SOURCE AUDIT DESTINATIONS

Module : `keybuzz-api/src/modules/outbound-conversions/routes.ts`
Mount prefix : `app.register(outboundDestinationsRoutes, { prefix: '/outbound-conversions/destinations' })` (src/app.ts:215).

### 5.1 checkAccess local

```typescript
const ALLOWED_ROLES = ['owner', 'admin'];

async function checkAccess(pool, email, tenantId, adminRole) {
  const ADMIN_BYPASS_ROLES = ['super_admin', 'account_manager', 'media_buyer'];
  if (adminRole && ADMIN_BYPASS_ROLES.includes(adminRole)) return true;
  const result = await pool.query(
    `SELECT ut.role FROM user_tenants ut
     JOIN users u ON u.id = ut.user_id
     WHERE LOWER(u.email) = LOWER($1) AND ut.tenant_id = $2`,
    [email, tenantId]
  );
  if (result.rows.length === 0) return false;
  return ALLOWED_ROLES.includes(result.rows[0].role);
}
```

Pattern identique a AS.13.1 google-observability (cf AS.13.1A audit). ADMIN_BYPASS_ROLES = MARKETING_ROLES Admin v2 (consumer Admin v2 marketing destinations potentielle, bien que non observe ici car le BFF Admin v2 marketing destinations n existe pas dans cette phase).

### 5.2 6 endpoints + checkAccess

| # | Method | Path complet | Handler ligne | Sequence verification | Tables touchees | Mutation risk |
|---|---|---|---|---|---|---|
| D1 | GET | /outbound-conversions/destinations/ (list) | 118 | email + tenantId required (400) -> checkAccess (403) -> SELECT outbound_conversion_destinations WHERE tenant_id=$1 AND deleted_at IS NULL | outbound_conversion_destinations (read) | none |
| D2 | POST | /outbound-conversions/destinations/ (create) | 144 | email + tenantId required (400) -> checkAccess (403) -> validate body -> INSERT outbound_conversion_destinations | outbound_conversion_destinations (INSERT) | local DB mutation |
| D3 | PATCH | /outbound-conversions/destinations/:id (update) | 212 | email + tenantId required (400) -> checkAccess (403) -> SELECT WHERE id=$1 AND tenant_id=$2 -> UPDATE | outbound_conversion_destinations (UPDATE) | local DB mutation |
| D4 | POST | /outbound-conversions/destinations/:id/test (webhook test) | 284 | email + tenantId required (400) -> checkAccess (403) -> SELECT WHERE id=$1 AND tenant_id=$2 -> emit test payload to destination URL | outbound_conversion_destinations (read) ; outbound_conversion_delivery_logs (INSERT log) ; **provider externe webhook fire** | provider external call |
| D5 | DELETE | /outbound-conversions/destinations/:id | 436 | email + tenantId required (400) -> checkAccess (403) -> SELECT WHERE id=$1 AND tenant_id=$2 -> soft delete UPDATE deleted_at=NOW() | outbound_conversion_destinations (UPDATE soft delete) | local DB mutation |
| D6 | GET | /outbound-conversions/destinations/:id/logs | 463 | email + tenantId required (400) -> checkAccess (403) -> SELECT WHERE id=$1 AND tenant_id=$2 -> SELECT delivery_logs WHERE destination_id=$1 | outbound_conversion_destinations (read), outbound_conversion_delivery_logs (read) | none |

Tous les SELECT/UPDATE/DELETE filtrent par `tenant_id = $X` apres checkAccess. Aucun fallback global, aucun bypass dangereux. POST /:id/test (D4) qui declencherait un webhook tiers est ferme avant le fire si checkAccess refuse.

---

## 6. RUNTIME PROBES NEGATIVE-ONLY

### 6.1 DEV probes (8)

| # | Method | Path | Headers | Expected | Actual | Verdict |
|---|---|---|---|---|---|---|
| D1 | GET | /outbound-conversions/destinations | aucun | 400 missing | 400 | OK |
| D2 | GET | /outbound-conversions/destinations | email=probe, tenant=fake | 403 not member | 403 | OK |
| D3 | POST | /outbound-conversions/destinations | aucun | 400 missing | 400 | OK |
| D4 | POST | /outbound-conversions/destinations | email=probe, tenant=fake | 403 | 403 | OK |
| D5 | PATCH | /outbound-conversions/destinations/:fakeid | email=probe, tenant=fake | 403 | 403 | OK |
| D6 | POST | /outbound-conversions/destinations/:fakeid/test (CRITIQUE) | email=probe, tenant=fake | 403 (no webhook fire) | 403 | OK |
| D7 | DELETE | /outbound-conversions/destinations/:fakeid | email=probe, tenant=fake | 403 | 403 | OK |
| D8 | GET | /outbound-conversions/destinations/:fakeid/logs | email=probe, tenant=fake | 403 | 403 | OK |

### 6.2 PROD probes (4)

| # | Method | Path | Headers | Expected | Actual | Verdict |
|---|---|---|---|---|---|---|
| P1 | GET | /outbound-conversions/destinations | aucun | 400 | 400 | OK |
| P2 | GET | /outbound-conversions/destinations | email=probe, tenant=fake | 403 | 403 | OK |
| P3 | POST | /outbound-conversions/destinations | email=probe, tenant=fake | 403 | 403 | OK |
| P4 | POST | /outbound-conversions/destinations/:fakeid/test (CRITIQUE) | email=probe, tenant=fake | 403 (no webhook fire) | 403 | OK |

Aucun POST/PATCH/DELETE positif. Aucun webhook tiers declenche. Aucun provider externe contacte par les probes.

### 6.3 DB / provider no-mutation (PROD)

| Counter | Avant probes | Apres probes | Delta |
|---|---|---|---|
| outbound_conversion_destinations total | 14 | 14 | 0 |
| outbound_conversion_destinations deleted_at IS NULL | 4 | 4 | 0 |
| outbound_conversion_destinations is_active=true | 3 | 3 | 0 |
| outbound_conversion_delivery_logs total | 16 | 16 | 0 |

| Surveillance | Resultat |
|---|---|
| Provider externe (Meta CAPI / TikTok / LinkedIn / webhook custom) | 0 call declenche par les probes |
| API PROD 5xx (2 min) | 0 |
| Fake event GA4 / CAPI / TikTok / LinkedIn | 0 |
| Fake conversion | 0 |

Conforme `no fake metrics / no fake events / no fake conversion / no fake destination / no fake provider response`.

---

## 7. PRESERVE SAMPLES (DEV + PROD)

| Famille | Sample | DEV | PROD |
|---|---|---|---|
| AS.13.1 google-observability | `GET /outbound-conversions/google-observability` no headers | 400 | 400 |
| AS.13.2A outbound deliveries | `GET /outbound/deliveries` no headers | 400 | 400 |
| AS.13.3A compat Amazon | `GET /api/v1/marketplaces/amazon/status?tenantId=fake` no headers | 401 | 401 |
| AS.12.1A messages/conversations | `GET /messages/conversations` fake/fake | (deja teste AS.13.3A) | 403 |

Toutes les protections KEY-301 + AS.13 livrees restent actives apres l audit AS.13.4.

---

## 8. DECISION KEY-313

### 8.1 Etat R1 surfaces (recap)

| Surface | Phase | Statut | Image runtime PROD |
|---|---|---|---|
| google-observability (1 endpoint) | AS.13.1 | Done DEV+PROD | v3.5.187 puis v3.5.188+ |
| outbound/deliveries (5 endpoints) | AS.13.2A | Done DEV+PROD | v3.5.188 puis v3.5.189 |
| compat Amazon (6 endpoints) | AS.13.3A | Done DEV+PROD | v3.5.189 |
| outbound-conversions/destinations (6 endpoints) | AS.13.4 | 0 patch (deja safe) | inchange |

Total R1 protege : 18 endpoints couverts.

### 8.2 Recommandation closeout KEY-313

Eligible au closeout :
- R1 surfaces toutes fermees ;
- AS.13.4 confirme 0 gap restant ;
- aucun patch additionnel necessaire dans le scope KEY-313 strict.

Action proposee (sous GO Ludovic explicite, pas declenchee dans cette phase) :
- Poster commentaire de closeout KEY-313 disclosure-controlled ;
- Ouvrir tickets de suivi separes :
  - **R2.2** : defense-in-depth outbound deliveries UPDATEs (ajouter `AND tenant_id = $X` dans les 3 UPDATEs simulate-deliver, simulate-fail, retry de outbound/routes.ts) ;
  - **R3** : backend defense-in-depth (network segmentation keybuzz-backend + rotation `KEYBUZZ_INTERNAL_PROXY_TOKEN`) ;
  - **U2** : surveillance continue logs API PROD 401/403 sur `/api/v1/marketplaces/amazon/*` pour detecter d eventuels consumers externes legitimes inattendus.

KEY-301 reste Done. KEY-313 reste Open jusqu a GO Ludovic explicite pour le closeout.

---

## 9. LINEAR

Texte propose pour commentaire KEY-313 closeout (disclosure-controlled, sans PoC, sans payload, sans secret) :

```
PH-SAAS-T8.12AS.13.4-R1 confirmation audit livre.

Surface auditee : outbound-conversions/destinations (6 endpoints).
Verdict : 0 patch necessaire. Pattern checkAccess local deja en place sur 6/6 handlers (identique a AS.13.1 google-observability). Source : ALLOWED_ROLES owner/admin + ADMIN_BYPASS_ROLES super_admin/account_manager/media_buyer + JOIN user_tenants ; sequence email+tenantId required (400) -> checkAccess (403) -> handler avec WHERE tenant_id=$X.

Probes runtime DEV (8) + PROD (4) confirmes : 400 no-auth, 403 fake/fake non-member sur les 6 endpoints incluant POST /:id/test (webhook tiers ferme avant fire). DB outbound_conversion_destinations PROD inchange (14/4/3) + outbound_conversion_delivery_logs inchange (16). 0 provider call externe declenche par les probes.

Preserve : AS.13.1 + AS.13.2A + AS.13.3A + AS.12 protections operationnelles DEV+PROD.

R1 surfaces fermees recap :
- AS.13.1 google-observability : 1 endpoint, checkAccess admin-bypass (Done DEV+PROD)
- AS.13.2A outbound/deliveries : 5 endpoints (2 reads + 3 mutations), tenantGuard matchers dynamiques (Done DEV+PROD)
- AS.13.3A compat Amazon : 6 endpoints, tenantGuard PROTECTED_ROUTES static (Done DEV+PROD)
- AS.13.4 outbound-conversions/destinations : 6 endpoints, checkAccess deja en place (0 patch)

Total R1 : 18 endpoints proteges.

Recommandation : KEY-313 eligible au closeout sous GO Ludovic explicite. Tickets de suivi proposes :
- R2.2 defense-in-depth outbound UPDATEs (AND tenant_id dans simulate-deliver/fail/retry)
- R3 backend defense-in-depth (network segmentation + X-Internal-Token rotation)
- U2 surveillance logs PROD compat Amazon 401/403

KEY-301 reste Done. KEY-313 reste Open jusqu a GO Ludovic pour closeout.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.4-R1-DESTINATIONS-CHECKACCESS-CONFIRMATION-AUDIT-01.md
```

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

---

## 10. GAPS / UNKNOWNS

| # | Gap | Categorie | Action |
|---|---|---|---|
| R2.2 | outbound deliveries UPDATEs filtrent `WHERE id = $1` seulement (SELECT initial filtre bien tenant_id, defense-in-depth a renforcer) | Backlog hors KEY-313 | Ticket separe |
| R3 | Backend trust `X-Internal-Token` ; network segmentation + rotation token a verifier au niveau infra | Backlog hors KEY-313 | Ticket separe |
| U2 | Surveillance logs API PROD 401/403 sur `/api/v1/marketplaces/amazon/*` pour detecter d eventuels consumers externes inattendus apres AS.13.3A | Continu | Suivi operationnel |
| U6 | Admin v2 BFF marketing destinations n a pas ete observe dans le code base (admin destinations dashboard probablement non-implemente). Si Admin v2 marketing destinations apparait plus tard, la chain ADMIN_BYPASS_ROLES = MARKETING_ROLES est deja alignee (cf AS.13.1A) -- aucun travail supplementaire previsible | Confirmation future | Surveiller futur Admin v2 marketing destinations |

---

## 11. VERDICTS AUTORISES

- GO DESTINATIONS CHECKACCESS CONFIRMED READY (verdict retenu)
- GO R1 CLOSEOUT DECISION READY (verdict retenu)
- NO GO DESTINATIONS GAP FOUND
- NO GO SOURCE/RUNTIME DRIFT

---

## 12. PHRASE CIBLE FINALE

GO DESTINATIONS CHECKACCESS CONFIRMED READY. GO R1 CLOSEOUT DECISION READY. KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear KEY-313 sans GO Ludovic explicite.

STOP.
