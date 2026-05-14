# PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01
> Environnement : DEV + PROD read-only. Aucune mutation, aucun appel mutationnel des 3 endpoints POST, aucun provider call.

---

## 1. VERDICT

GO OUTBOUND DELIVERIES DESIGN READY

Les 5 endpoints `/outbound/deliveries*` peuvent etre couverts en un seul patch AS.13.2A (1 fichier source `keybuzz-api/src/plugins/tenantGuard.ts` + 0 fichier consumer cote Client / Admin v2 / worker). Aucun split A/B requis : tous les consumers HTTP de ces endpoints sont absents (Client BFF = 0 consumer, Client UI = aucune page, Admin v2 = SQL direct, worker outbound = DB direct, cron = 0). Le pattern propose est aligne avec KEY-301 AS.11/AS.12 (matchers dynamiques dans tenantGuard `fp()`), pas avec le pattern `checkAccess` local AS.13.1 (qui exigeait un bypass admin marketing -- non applicable ici).

Aucun patch, aucun build, aucun deploy, aucune mutation DB, aucun provider call n a ete effectue dans cette phase.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface visee | API HTTP `/outbound/deliveries*` (5 endpoints) |
| Module source | `keybuzz-api/src/modules/outbound/routes.ts` (~10 KB, 1 fichier) |
| Module patch propose | `keybuzz-api/src/plugins/tenantGuard.ts` (matchers dynamiques) |
| Hors scope | Worker outbound (consume DB direct), Admin v2 (SQL direct), Client UI/BFF (0 consumer), cron, autres modules outbound-conversions/* (deja couverts ou AS.13.4) |
| Tag cible DEV (futur) | v3.5.188-outbound-deliveries-tenantguard-dev |
| Tag cible PROD (futur) | v3.5.188-outbound-deliveries-tenantguard-prod |
| Rollback | v3.5.187-google-observability-tenantguard-{dev,prod} |

---

## 3. PREFLIGHT

### 3.1 Repos

| Repo | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 1c8b6b18 | OK | dist/ deleted en worktree (cosmetique, build-from-git fresh clone) | OK lecture |
| keybuzz-infra | main | 5ce0d22 | OK | clean | OK |

### 3.2 Runtime

| Service | DEV | PROD | Restart |
|---|---|---|---|
| keybuzz-api | v3.5.187-google-observability-tenantguard-dev | v3.5.187-google-observability-tenantguard-prod | 1/1 ready |
| keybuzz-outbound-worker (image keybuzz-api) | v3.5.165-escalation-flow-dev | v3.5.165-escalation-flow-prod | 1/1 ready |
| keybuzz-client | v3.5.196-ai-rules-bff-dev | v3.5.196-ai-rules-bff-prod | 1/1 ready |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 ready |

Tous les services ready post AS.13.1. Aucun rollout en cours.

---

## 4. INVENTAIRE SOURCE - 5 endpoints outbound/deliveries

Module : `keybuzz-api/src/modules/outbound/routes.ts`
Registration : `app.register(outboundRoutes, { prefix: '/outbound' })` dans `src/app.ts:159`

### 4.1 preHandler local actuel

Le module declare un `app.addHook('preHandler', ...)` qui exige UNIQUEMENT que `tenantId` soit present en query ou header :

```typescript
app.addHook('preHandler', async (request, reply) => {
  const tid = (request.query as any)?.tenantId || request.headers?.['x-tenant-id'];
  if (!tid) {
    reply.status(400).send({ error: 'tenantId is required', code: 'TENANT_ID_MISSING' });
    return;
  }
});
```

Faille : aucune verification de membership (`user_tenants`), aucune verification d identite (`x-user-email`). Toute requete munie d un tenantId valide est acceptee, quelle que soit l identite reelle de l appelant. Pas d auth, pas d access control.

### 4.2 Endpoints

| Id | Method | Path | Tenant source | Tables lues | Tables ecrites | Mutation actuelle | Risque |
|---|---|---|---|---|---|---|---|
| O1 | GET | /outbound/deliveries | query.tenantId | outbound_deliveries | aucune | SELECT WHERE tenant_id=$1 + filter status + LIMIT 50 | HIGH cross-tenant read |
| O2 | GET | /outbound/deliveries/:id | query.tenantId or header x-tenant-id | outbound_deliveries | aucune | SELECT WHERE id=$1 AND tenant_id=$2 | HIGH cross-tenant read |
| O3 | POST | /outbound/deliveries/:id/simulate-deliver | query.tenantId or header x-tenant-id | outbound_deliveries (SELECT pre-check) | outbound_deliveries (UPDATE status=delivered) | UPDATE outbound_deliveries SET status=delivered, last_error=NULL, updated_at=now() WHERE id=$1 | HIGH cross-tenant mutation |
| O4 | POST | /outbound/deliveries/:id/simulate-fail | query.tenantId or header x-tenant-id | outbound_deliveries (SELECT pre-check) | outbound_deliveries (UPDATE status=failed) | UPDATE outbound_deliveries SET status=failed, last_error=$2, updated_at=now() WHERE id=$1 | HIGH cross-tenant mutation |
| O5 | POST | /outbound/deliveries/:id/retry | query.tenantId or header x-tenant-id | outbound_deliveries (SELECT pre-check) | outbound_deliveries (UPDATE status=queued, attempt_count++) | UPDATE outbound_deliveries SET status=queued, attempt_count=$2, last_error=NULL WHERE id=$1 + worker pickup (REAL provider send) | CRITICAL cross-tenant real outbound send |

### 4.3 Gap secondaire defense-in-depth (note pour AS.13.2-followup, hors scope immediat)

Les 3 UPDATEs (O3, O4, O5) utilisent uniquement `WHERE id = $1` au lieu de `WHERE id = $1 AND tenant_id = $2`. Le SELECT initial filtre bien sur tenant_id, donc en pratique la mutation ne peut etre declenchee que si l appelant connait deja le bon tenant_id. Mais une fois tenantGuard membership applique, ce gap defense-in-depth devient moins critique. A traiter en suivi (R2.2 outbound deliveries UPDATEs scope hardening), pas bloquant pour AS.13.2A.

---

## 5. CONSUMERS

Recherche exhaustive code base au 2026-05-14.

| Consumer potentiel | Repertoire scanne | Resultat |
|---|---|---|
| Client BFF Next.js | keybuzz-client/src/app/api/, keybuzz-client/src/lib/ | 0 reference `/outbound/deliveries` |
| Client UI pages | keybuzz-client/src/app/ | 0 page deliveries dans l UX produit |
| Admin v2 BFF | keybuzz-admin-v2/src/ | 0 appel HTTP. Admin v2 lit `outbound_deliveries` via SQL direct dans users.service.ts (count failed, last 10, top tenants...) -- non affecte par protection HTTP |
| Worker outbound (intra-API) | keybuzz-api/src/workers/outboundWorker.ts | Consume `outbound_deliveries` via DB direct (SELECT/UPDATE), pas via HTTP. Non affecte. |
| Cron / scheduler | keybuzz-api/src/ | 0 reference |
| Internal API self-call | keybuzz-api/src/ | 0 `fetch(/outbound/deliveries...)` ni axios ni httpClient |

### 5.1 Conclusion consumers

Tableau :

| Consumer | Route appelee | Headers injectes | Session/auth | Risque tenantGuard rollout |
|---|---|---|---|---|
| (aucun consumer HTTP legitime) | n/a | n/a | n/a | NUL : la protection ne casse aucune chain UX |
| Admin v2 marketing/ops dashboards | (lecture DB directe, non HTTP) | n/a | NextAuth admin server-side | non affecte |
| Worker outbound | (DB direct) | n/a | service-account local | non affecte |

Effet attendu de l ajout de tenantGuard sur ces endpoints : casser tout appel direct externe par curl/Postman/test (= exactement ce qu on cherche). Aucune UI prod, aucun flux client, aucune action support n est concernee.

---

## 6. DESIGN PATCH PROPOSE (AS.13.2A IMPL)

### 6.1 Pattern retenu : tenantGuard global avec matchers dynamiques

Aligne avec KEY-301 AS.11.1A-F, AS.12.1A-B, AS.12.2A-D, AS.12.2C-1..5B.
Non aligne avec AS.13.1 `checkAccess` local (qui exigeait bypass admin marketing -- non applicable ici car Admin v2 ne consomme pas la surface HTTP).

Fichier patche : `keybuzz-api/src/plugins/tenantGuard.ts`

Ajout de 2 fonctions matcher (squelette indicatif, sans patch reel applique) :
- `isOutboundDeliveriesGet(method, path)` : retourne true pour
  - `GET /outbound/deliveries` (exact)
  - `GET /outbound/deliveries/<id>` (1 segment apres /outbound/deliveries/, pas `simulate-*` ni `retry`)
- `isOutboundDeliveryAction(method, path)` : retourne true pour
  - `POST /outbound/deliveries/<id>/simulate-deliver`
  - `POST /outbound/deliveries/<id>/simulate-fail`
  - `POST /outbound/deliveries/<id>/retry`

Ajouter `if (isOutboundDeliveriesGet(method, path)) return true;` et `if (isOutboundDeliveryAction(method, path)) return true;` dans `isProtectedRoute(method, path)`.

Aucune modification de PROTECTED_ROUTES static (chemins parametriques, donc dynamic matcher est plus propre).

### 6.2 Effet runtime apres patch

| Cas | Avant AS.13.2A | Apres AS.13.2A |
|---|---|---|
| Pas de tenantId, pas de email | 400 TENANT_ID_MISSING (module preHandler) | 400 (tenantGuard preHandler intercepte avant module preHandler) ou 400 module si tenantGuard laisse passer faute de tenantId. **Verifier ordre fastify-plugin parent scope** (cf AS.11.1A doc dans tenantGuard.ts). Resultat attendu : 400. |
| tenantId valide, pas de email | 200 (faille actuelle) | 400 Missing x-user-email (tenantGuard required headers) |
| tenantId valide, email valide, non-member | 200 | 403 Forbidden (membership check via user_tenants) |
| tenantId valide, email valide, member owner/admin | 200 | 200 (handler tourne avec verification membership cache 30s) |
| tenantId valide, email valide, member viewer (si tel role existe) | 200 | 200 ou 403 selon ALLOWED_ROLES du tenantGuard. **A verifier au moment du patch IMPL** : KEY-301 tenantGuard accepte n importe quel membership ou applique un role-check. |

Reference : `extractTenantId()` (query > header > body) deja prevu dans tenantGuard, compatible avec les patterns des 5 endpoints (`query.tenantId || header x-tenant-id`).

### 6.3 Pas de modification module-local

Le `preHandler` local du module (qui demande tenantId only) peut etre conserve tel quel : il devient redondant avec tenantGuard mais ne casse rien. Une seconde option (out-of-scope AS.13.2A, possible AS.13.2A-followup) serait de le retirer pour simplifier.

### 6.4 Decision split

AS.13.2A unique :
- 1 patch fichier `tenantGuard.ts`
- 0 patch source modifie (`outbound/routes.ts` inchange)
- 0 patch consumer (aucun consumer HTTP)
- Blast radius : nul cote UX (aucun consumer HTTP legitime)
- Test plan : negative-only ; mutations testees uniquement en rejet pre-handler (jamais d UPDATE positif)

Pas de split AS.13.2A read vs AS.13.2B mutations parce que :
1. Aucun consumer legitime n appelle ces endpoints, donc aucun risque de regression UX entre lecture et mutation
2. Les matchers sont 2 fonctions independantes mais une seule revue suffit
3. Le worker outbound (qui pourrait depiler du retry) n est PAS un consumer HTTP, donc le retry endpoint n est jamais appele par lui-meme

---

## 7. VALIDATION PLAN (FUTUR AS.13.2A IMPL ; AUCUNE EXECUTION DANS CETTE PHASE)

Toutes les probes sont negative-only ou rejet pre-handler. Aucun POST positif sur les 3 mutations.

### 7.1 Probes negative-only (DEV puis PROD)

| Probe | Method + Path | Headers | Verdict attendu |
|---|---|---|---|
| N1 | GET /outbound/deliveries | aucun | 400 tenantId missing |
| N2 | GET /outbound/deliveries?tenantId=fake | aucun | 400 missing x-user-email (tenantGuard apres patch) |
| N3 | GET /outbound/deliveries?tenantId=fake | x-user-email=probe@invalid | 403 not a member |
| N4 | GET /outbound/deliveries/:fakeid | x-user-email=probe@invalid + x-tenant-id=fake | 403 |
| N5 | POST /outbound/deliveries/:fakeid/simulate-deliver | aucun body, aucun headers | 400 ou 401 (rejet pre-handler) |
| N6 | POST /outbound/deliveries/:fakeid/simulate-deliver | x-user-email=probe@invalid + x-tenant-id=fake | 403 (rejet tenantGuard avant handler) |
| N7 | POST /outbound/deliveries/:fakeid/simulate-fail | x-user-email=probe@invalid + x-tenant-id=fake | 403 |
| N8 | POST /outbound/deliveries/:fakeid/retry | x-user-email=probe@invalid + x-tenant-id=fake | 403 (CRITIQUE : aucun retry reel ne doit etre declenche) |

Aucun POST avec un tenantId reel + email reel ne sera fait. Validation positive (200) sur les reads (O1/O2) eventuellement realisee uniquement avec un compte de test legitime DEV, si necessaire, et pas en PROD.

### 7.2 DB snapshot pre/post

Comptage avant probes (PROD ou DEV) :

```sql
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status='queued') AS queued,
  COUNT(*) FILTER (WHERE status='delivered') AS delivered,
  COUNT(*) FILTER (WHERE status='failed') AS failed,
  SUM(attempt_count) AS attempts
FROM outbound_deliveries;
```

Re-runner apres probes. Delta attendu = 0 sur toutes les colonnes. Toute deviation = NO GO.

### 7.3 Logs / provider call

- Logs API DEV/PROD pendant les probes : 0 5xx, 0 stacktrace.
- Logs worker outbound : aucun pickup nouveau, aucun appel provider declenche par les probes (les rejets pre-handler ne touchent jamais le pool DB).
- Aucun fake event GA4/CAPI/TikTok/LinkedIn.
- Aucun appel provider externe.

### 7.4 Non-regression services hors API

- Client PROD inchange (aucun consumer)
- Admin v2 PROD inchange (lectures SQL directes)
- Worker outbound PROD inchange (DB direct, ne consume pas HTTP)

---

## 8. DISCLOSURE CONTROLEE

Aucun PoC, aucun payload reproducible, aucun token, aucun secret, aucun draftText IA, aucun email/order_ref/customer_ref reel, aucune URL provider externe sensible n est inclus dans ce rapport ni ne sera publie en commentaire Linear. Les exemples de probes sont sous forme generique (fake uuid `00000000-...`, email `probe@invalid`, aucun ID PROD reel).

---

## 9. PROD READ-ONLY

Aucune mutation, aucun POST, aucun PATCH, aucun DELETE, aucun build, aucun docker push, aucun kubectl apply.

Lectures effectuees uniquement :
- `git rev-parse`, `git log`, `git status` (repos read-only)
- `kubectl get`, `kubectl describe` (read-only)
- `git --no-pager grep`, `cat`, `head`, `sed -n` (source read-only)
- Aucune execution sur DB

---

## 10. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled) :

```
PH-SAAS-T8.12AS.13.2-R1 design audit livre.

Scope : 5 endpoints /outbound/deliveries* (2 GET + 3 mutations : simulate-deliver, simulate-fail, retry).
preHandler local actuel : verifie tenantId only, AUCUNE verification membership. Cross-tenant read + cross-tenant mutation + cross-tenant real outbound send via retry confirmes (read confirme via AS.13.0 probes safe, mutations decrites par famille sans tests positifs).

Decision design :
- Pattern tenantGuard global avec matchers dynamiques (aligne KEY-301 AS.11/12).
- Pas de pattern checkAccess admin-bypass : Admin v2 ne consume pas la surface HTTP, il lit outbound_deliveries en SQL direct. Aucune chain Admin v2 ne sera cassee.
- AS.13.2A unique (pas de split A/B) : 1 fichier tenantGuard.ts a patcher, 0 consumer HTTP existant.
- Validation negative-only future : aucun POST positif sur les 3 mutations (regle absolue retry-real-send).

Consumers HTTP : 0 cote Client BFF, 0 cote Admin v2, 0 cote worker, 0 cote cron.
Worker outbound DB direct, non affecte par la protection HTTP.

Gap secondaire (suivi, hors scope AS.13.2A) : les 3 UPDATEs filtrent `WHERE id=$1` seulement, le SELECT initial filtre tenant_id mais la defense en profondeur peut etre durcie (R2.2).

Tag cible futur : v3.5.188-outbound-deliveries-tenantguard-{dev,prod}. Rollback : v3.5.187.

KEY-313 reste Open. KEY-301 reste Done. Aucun build, aucun deploy, aucune mutation effectuee dans cette phase.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 11. NEXT PHASES (en attente GO Ludovic explicite)

| Phase | Scope | Pre-requis |
|---|---|---|
| AS.13.2A IMPL DEV | Patch tenantGuard.ts (matchers isOutboundDeliveriesGet + isOutboundDeliveryAction) + build DEV + GitOps DEV apply + validation negative-only + DB snapshot pre/post | GO Ludovic explicite |
| AS.13.2A PROD | Build PROD + push + GitOps PROD + validation negative-only + DB snapshot pre/post + QA Ludovic | GO Ludovic explicite + AS.13.2A DEV OK |
| AS.13.3 | compat /api/v1/marketplaces/amazon/* (6 endpoints proxy backend, X-Internal-Token) | Apres AS.13.2A PROD |
| AS.13.4 | outbound-conversions/destinations (6 endpoints, audit confirmatif checkAccess) | Apres AS.13.3 |
| R2.2 suivi | Defense-in-depth : ajouter `AND tenant_id = $X` dans les 3 UPDATEs outbound_deliveries | Backlog, hors scope KEY-313 strict |

---

## 12. VERDICTS AUTORISES

- GO OUTBOUND DELIVERIES DESIGN READY (verdict retenu)
- GO PARTIAL OUTBOUND DELIVERIES DESIGN READY WITH UNKNOWNS
- NO GO OUTBOUND DELIVERIES MUTATION RISK UNCLEAR

---

## 13. PHRASE CIBLE FINALE

GO OUTBOUND DELIVERIES DESIGN READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.2A IMPL sans GO Ludovic explicite.

STOP.
