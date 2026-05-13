# PH-SAAS-T8.12AS.13.0-R1-OUTBOUND-COMPAT-TENANTGUARD-TRUTH-AUDIT-01

> Date : 2026-05-13
> Linear : KEY-313 (parent epic KEY-301 Done)
> Phase : T8.12 AS.13.0 -- R1 outbound + compat truth audit (READ-ONLY strict)
> Environnement : DEV + PROD read-only

---

## 1. VERDICT

GO PARTIAL R1 AUDIT READY WITH UNKNOWNS

Audit truth livre. 18 endpoints inventories sur 4 sous-modules `compat` + `outbound` + `outbound-conversions/destinations` + `outbound-conversions/google-observability`. Probes safe (GET, no-auth, payloads fictifs) confirment trois zones a risque :

| Zone | Endpoints | Risque cross-tenant | tenantGuard recommande |
|---|---|---|---|
| `compat` (legacy Amazon proxy) | 6 | HIGH (tenantId arbitraire query/header, NO membership) | OUI |
| `outbound/deliveries` | 5 (3 mutations DB) | HIGH (preHandler tenantId required mais NO membership) | OUI |
| `outbound-conversions/google-observability` | 1 | **CRITICAL (leak multi-tenant global si tenantId manquant)** | OUI URGENT |
| `outbound-conversions/destinations` | 6 | LOW (deja protege par `checkAccess` interne via user_tenants) | NON requis -- verify confirmatif only |

Decoupage propose AS.13.1 -> AS.13.4, **plus petite scope d abord avec plus haut risque/plus faible blast radius** = AS.13.1 google-observability (1 endpoint, 1 patch ligne pour rendre tenantId obligatoire + adminGuard alternative).

Recommandation : **GO design AS.13.1**, scope minimal d abord pour neutraliser le leak global non-authentifie, puis AS.13.2/13.3 pour outbound + compat, puis AS.13.4 verification confirmatif destinations.

KEY-313 reste Open. Aucun patch / build / deploy / mutation runtime durant cette phase d audit.

---

## 2. Scope

Inclus (audit truth READ-ONLY) :
- Preflight repos + runtime tous services DEV + PROD.
- Inventaire source 4 modules : compat, outbound, outbound-conversions/destinations, outbound-conversions/google-observability.
- Mapping handlers (method, path, source file, tenantId source, membership check, consumers).
- Classification routes.
- Probes safe GET runtime PROD (no-auth, payloads fictifs, no mutation).
- Risk matrix disclosure-controlled.
- Decoupage AS.13.1..AS.13.4 propose.
- Texte Linear KEY-313 prepare.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Aucun patch source / build / docker push / deploy / manifest.
- Aucune mutation DB.
- Aucun POST / PATCH / DELETE / PUT positif (mutations outbound /retry /simulate-deliver /simulate-fail interdit).
- Aucune simulation qui ecrit (simulate-deliver et simulate-fail ecrivent DB -> interdits).
- Aucune trigger provider externe (Amazon OAuth start, disconnect, webhook test).
- Aucun envoi outbound reel.
- Aucun PoC exploitable, aucun payload reproducible dans le rapport.
- Aucun secret / token affiche.
- Aucune PII / customer body / tracking complet / draftText.
- Aucune promotion PROD.
- Aucun changement Linear status (KEY-313 reste Open).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.3-KEY-301-TENANTGUARD-CLOSEOUT-TRUTH-AUDIT-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.3A-KEY-301-LINEAR-CLOSEOUT-01.md`.
- `keybuzz-api/src/app.ts` (mounts compat + outbound + outbound-conversions).
- `keybuzz-api/src/modules/compat/routes.ts` (proxy generique Amazon, fonction `getTenantId` + `proxyToLegacyBackend`).
- `keybuzz-api/src/modules/outbound/routes.ts` (5 endpoints + preHandler local tenantId required, pas de membership).
- `keybuzz-api/src/modules/outbound-conversions/routes.ts` (6 endpoints + `checkAccess` via user_tenants).
- `keybuzz-api/src/modules/outbound-conversions/google-observability.ts` (1 endpoint, tenantId optionnel).
- `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES actuelles + EXEMPT_PREFIXES).
- `keybuzz-client/app/api/amazon/*` (8 BFF NextAuth + X-User-Email + X-Tenant-Id).
- `keybuzz-client/src/lib/api-client.ts` (callers /api/v1/marketplaces/amazon/oauth/start).
- `keybuzz-backend/src/modules/marketplaces/amazon/amazon.routes.ts` (target compat proxy).
- `keybuzz-backend/src/lib/devAuthMiddleware.ts` (KEYBUZZ_INTERNAL_PROXY_TOKEN check cote backend).

---

## 4. Preflight repos + runtime

### 4.1 Repos

| Repo | Path | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 05bb57cd | 0-0 | 0 (dist/ exclus) | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970 | 0-0 | 0 | OK |
| keybuzz-backend | /opt/keybuzz/keybuzz-backend | main | b183817d | 0-0 | 0 | OK |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 2677d21 | 0-0 | 0 | OK |
| keybuzz-admin-v2 | /opt/keybuzz/keybuzz-admin-v2 | main | 3707c834 | 0-0 | 0 | OK |

### 4.2 Runtime DEV + PROD

| Env | Service | Image | Verdict |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-dev | OK baseline AS.12.2C-5B |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev | OK baseline AS.12.2C-5A |
| DEV | keybuzz-api/outbound-worker | v3.5.165-escalation-flow-dev | OK (inchange ancien) |
| PROD | keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-prod | OK baseline AS.12.2C-5B-PROD |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod | OK baseline AS.12.2C-5A-PROD |
| PROD | keybuzz-api/outbound-worker | v3.5.165-escalation-flow-prod | OK (inchange ancien) |
| (DEV+PROD x 6) | backend services | v1.0.40 / 42 / 47 + admin-v2 v2.12.2 + studio v0.8.0 + studio-api v0.8.1 + website v0.6.12 | OK inchanges |

Tous les services en place. Aucun drift detecte.

---

## 5. Source inventory

### 5.1 Module `compat` (mount no prefix, `src/modules/compat/routes.ts`)

| # | Method | Path | Handler comportement | Tenant source | Membership |
|---|---|---|---|---|---|
| C1 | GET | /api/v1/marketplaces/amazon/status | LOCAL DB query `inbound_connections` WHERE "tenantId"=$1 | query `tenantId` ou header `X-Tenant-Id` | NON |
| C2 | POST | /api/v1/marketplaces/amazon/disconnect | proxyToLegacyBackend (keybuzz-backend) | header forward | NON |
| C3 | GET | /api/v1/marketplaces/amazon/oauth/start | proxyToLegacyBackend + query string forward | header forward | NON |
| C4 | POST | /api/v1/marketplaces/amazon/oauth/start | proxyToLegacyBackend | header forward | NON |
| C5 | GET | /api/v1/marketplaces/amazon/inbound-address | proxyToLegacyBackend | header forward | NON |
| C6 | POST | /api/v1/marketplaces/amazon/inbound-address/send-validation | proxyToLegacyBackend | header forward | NON |

Note proxy : `proxyToLegacyBackend` injecte automatiquement `X-Internal-Token` depuis `KEYBUZZ_INTERNAL_PROXY_TOKEN` env var si pas fourni par le client. Le backend cible (`LEGACY_BACKEND_URL`) trust ce token comme proxy authentifie (cf `keybuzz-backend/src/lib/devAuthMiddleware.ts` ligne 104). Le compat agit donc comme bridge authentifie qui forward tenantId arbitraire au backend.

Consumers Client : `app/api/amazon/status/route.ts`, `app/api/amazon/oauth/start/route.ts`, `app/api/amazon/disconnect/route.ts`, `app/api/amazon/inbound-address/route.ts`, `app/api/amazon/inbound-address/send-validation/route.ts`, `app/api/amazon/activate-channels/route.ts`, `app/api/debug-amazon-connect/route.ts`. Tous injectent NextAuth `session.user.email` + `tenant_id` query/header. Le BFF est "session-bound" mais ne verifie pas membership user_tenants -- si attaquant authentifie passe `tenant_id` arbitraire, le BFF forward sans check.

### 5.2 Module `outbound` (mount `/outbound`, `src/modules/outbound/routes.ts`)

| # | Method | Path | Handler comportement | Tenant source | Membership | Mutation DB |
|---|---|---|---|---|---|---|
| O1 | GET | /outbound/deliveries | SQL SELECT FROM outbound_deliveries WHERE tenant_id=$1 | query `tenantId` ou header `x-tenant-id` | NON (preHandler require tenantId only) | non |
| O2 | GET | /outbound/deliveries/:id | SQL SELECT WHERE id AND tenant_id | idem | NON | non |
| O3 | POST | /outbound/deliveries/:id/simulate-deliver | UPDATE outbound_deliveries SET status='delivered' WHERE id (verifie tenant_id avant) | idem | NON | **oui** |
| O4 | POST | /outbound/deliveries/:id/simulate-fail | UPDATE outbound_deliveries SET status='failed', last_error | idem | NON | **oui** |
| O5 | POST | /outbound/deliveries/:id/retry | UPDATE outbound_deliveries SET status='queued', attempt_count++ (declenche re-envoi par outbound-worker) | idem | NON | **oui** + side effect outbound-worker pickup |

PreHandler local en place :
```
app.addHook('preHandler', async (request, reply) => {
  const tid = (request.query as any)?.tenantId || request.headers?.['x-tenant-id'];
  if (!tid) { reply.status(400).send({error:'tenantId is required'}); return; }
});
```
Cela protege contre l absence de tenantId mais **PAS contre tenantId arbitraire**. Le SQL `WHERE tenant_id = $1` retourne ce que le tenant_id passe demande, sans verifier que l utilisateur authentifie est membre de ce tenant.

Risk specifique pour /retry : declenche `outbound-worker` qui peut tenter de re-envoyer un message client (provider externe Amazon/Shopify/email). Cross-tenant retry = envoi reel par tenant cible.

Consumers : aucun BFF `/api/outbound/*` cote Client (recherche exhaustive). Endpoints probablement utilises via admin UI ou direct API.

### 5.3 Module `outbound-conversions/destinations` (mount `/outbound-conversions/destinations`, `src/modules/outbound-conversions/routes.ts`)

| # | Method | Path | Handler comportement | Membership |
|---|---|---|---|---|
| OD1 | GET | /outbound-conversions/destinations | SQL SELECT FROM outbound_conversion_destinations WHERE tenant_id | **OUI** via `checkAccess` |
| OD2 | POST | /outbound-conversions/destinations | INSERT outbound_conversion_destinations | **OUI** |
| OD3 | PATCH | /outbound-conversions/destinations/:id | UPDATE | **OUI** |
| OD4 | POST | /outbound-conversions/destinations/:id/test | trigger webhook EXTERNE (test destination URL avec event factice) | **OUI** |
| OD5 | DELETE | /outbound-conversions/destinations/:id | DELETE soft (deleted_at) | **OUI** |
| OD6 | GET | /outbound-conversions/destinations/:id/logs | SQL SELECT logs | **OUI** |

`checkAccess` (ligne 74-83) :
```
SELECT ... FROM user_tenants ut
JOIN users u ON ...
WHERE LOWER(u.email) = LOWER($1) AND ut.tenant_id = $2
```
C est strictement le meme pattern que tenantGuard. Module **deja protege correctement**. Necessite seulement audit confirmatif runtime + verifie que `x-user-email` est bien injecte par les consumers (BFF? client direct? admin?).

Consumers a verifier : aucun BFF dedie identifie dans Client. Probablement admin-v2 ou usage direct API admin.

### 5.4 Module `outbound-conversions/google-observability` (mount `/outbound-conversions`, `src/modules/outbound-conversions/google-observability.ts`)

| # | Method | Path | Handler comportement | tenantId | Membership |
|---|---|---|---|---|---|
| GO1 | GET | /outbound-conversions/google-observability | 3 queries paralleles sur `signup_attribution` : agreges (gclid_count, google_utm_count, conversions_sent, total_signups) + last gclid + last conversion | **OPTIONNEL** | NON |

Comportement critique : si `tenantId` query absent, **le filtre WHERE n est pas applique** -> les queries retournent les statistiques **TOUS tenants confondus** + le dernier gclid avec son `tenant_id` + la derniere conversion. C est un leak inter-tenant non-authentifie.

Verifie en runtime PROD section 7.

---

## 6. Route classification

| Route family | Classification | Justification | Protection actuelle | Action recommandee |
|---|---|---|---|---|
| compat `/api/v1/marketplaces/amazon/*` (6) | **tenant-scoped a proteger** | utilise par UI tenants pour OAuth Amazon + status + disconnect | NON | tenantGuard via PROTECTED_ROUTES exact OU matcher + BFF safe (deja fait cote Client mais sans verification membership) |
| outbound `/deliveries*` (5) | **tenant-scoped a proteger** | data deliveries tenants + mutation declencheable | preHandler tenantId required (pas membership) | tenantGuard via matcher dynamique + retirer preHandler ou le complementer |
| outbound-conversions `/destinations*` (6) | tenant-scoped DEJA protege | webhook destinations tenant | `checkAccess(email, tenantId)` interne via user_tenants | audit confirmatif uniquement ; rien a patcher sauf si checkAccess n est pas applique a 100% (verify) |
| outbound-conversions `/google-observability` (1) | **tenant-scoped a proteger URGENT** | leak global si tenantId omis | NON | tenantId required + (optionnel) adminGuard global si scope=owner |
| debug `/debug/outbound/*` | internal-only | dev-only, deja EXEMPT prefix `/debug` | EXEMPT (tenantGuard skip) | conserver EXEMPT, non scope KEY-313 |
| health `/health/outbound/*` (2) | public legitime (health checks K8s + ingress) | exposed health probes | EXEMPT prefix `/health` | conserver EXEMPT, non scope KEY-313 |
| backend `/api/v1/marketplaces/amazon/*` direct | internal-only (target proxy) + provider callback OAuth | accede via X-Internal-Token + reception OAuth callback Amazon | INTERNAL_TOKEN cote backend | hors scope cette phase (KEY-313 vise compat proxy api, pas backend cible) |

---

## 7. Runtime read-only evidence

### 7.1 Probes safe GET no-auth PROD

UUIDs fictifs : `tenantId=00000000-0000-0000-0000-000000000000`.

| Probe | Method | Env | Expected (security ideal) | Actual (observed) | Mutation risk | Verdict |
|---|---|---|---|---|---|---|
| /api/v1/marketplaces/amazon/status?tenant_id=fake | GET | PROD | 401 / 403 | **200** (returns DISCONNECTED for fake but real tenant_id would leak status) | non (read DB only) | RISQUE confirme |
| /outbound/deliveries?tenantId=fake | GET | PROD | 401 / 403 | **200** (returns [] for fake, real tenant_id would leak deliveries) | non (read DB) | RISQUE confirme |
| /outbound/deliveries (no tenant) | GET | PROD | 400 ou 401 | 400 (preHandler) | non | OK preHandler |
| /outbound-conversions/destinations (no auth) | GET | PROD | 400 / 401 | 400 (`checkAccess` rejette x-user-email manquant) | non | OK |
| /outbound-conversions/google-observability (no tenant) | GET | PROD | 401 / 400 | **200** (returns aggregate ALL tenants : gclid_count, google_utm_count, conversions_sent, total_signups + last gclid + last conversion incl. tenant_id) | non (read SQL) | **CRITICAL LEAK confirme** |

### 7.2 Endpoints mutationnels (NOT_PROBED_MUTATION_RISK)

Conformement au scope READ-ONLY, les endpoints suivants n ont **pas ete probes** car ils ecrivent DB ou declenchent provider externe :

- POST /outbound/deliveries/:id/simulate-deliver (UPDATE outbound_deliveries SET status='delivered')
- POST /outbound/deliveries/:id/simulate-fail (UPDATE SET status='failed')
- POST /outbound/deliveries/:id/retry (UPDATE SET status='queued' + outbound-worker pickup -> potentiel re-send reel)
- POST /api/v1/marketplaces/amazon/disconnect (proxy backend, peut deconnecter OAuth Amazon reel)
- GET/POST /api/v1/marketplaces/amazon/oauth/start (proxy backend, peut initier flow OAuth)
- POST /api/v1/marketplaces/amazon/inbound-address/send-validation (proxy backend, peut envoyer email validation)
- POST /outbound-conversions/destinations (INSERT destination)
- PATCH /outbound-conversions/destinations/:id (UPDATE)
- POST /outbound-conversions/destinations/:id/test (trigger webhook EXTERNE)
- DELETE /outbound-conversions/destinations/:id (soft DELETE)

### 7.3 Logs + health

| Source | Filtre | Count | Verdict |
|---|---|---|---|
| /health DEV+PROD | -- | 200 (acquis sessions precedentes) | OK |
| API PROD `statusCode 5xx` | 10min | 0 | PASS |
| outbound-worker PROD pods ready | -- | 1/1 | OK |

---

## 8. Risk matrix disclosure-controlled

| Risk ID | Family | Impact | Severity | Confidence | Mitigation proposed | Disclosure level |
|---|---|---|---|---|---|---|
| R1.1 | google-observability tenantId optionnel | leak aggregate marketing data tous tenants (counts gclid + utm + conversions + last attribution row) sans auth | **CRITICAL** | confirmed via 200 runtime | rendre tenantId obligatoire + adminGuard si scope=owner | famille + comportement decrits, **aucun payload exploitable diffuse** |
| R1.2 | compat /api/v1/marketplaces/amazon/* | cross-tenant lecture status / declenchement OAuth disconnect / OAuth start / inbound-address d un tenant cible si tenantId arbitraire passe en query/header | HIGH | confirmed via 200 status | tenantGuard membership check sur les 6 routes (matcher exact ou dynamic) | famille + endpoints listes, pas de PoC |
| R1.3 | outbound /deliveries reads | cross-tenant lecture list/detail deliveries arbitraires (data minimaliste mais peut contenir order_ref ou customer_ref selon schema) | HIGH | confirmed via 200 | tenantGuard membership check (matcher /outbound/deliveries + /outbound/deliveries/:id) | famille + endpoints, pas de schema affiche |
| R1.4 | outbound /deliveries mutations (simulate-deliver/fail) | cross-tenant marquer arbitrairement deliveries d un tenant cible comme delivered ou failed (pollution metrique SAV + alarmes) | HIGH | not-probed-mutation | tenantGuard membership check | comportement decrit, pas testes |
| R1.5 | outbound /deliveries/:id/retry | cross-tenant declencher re-envoi REEL via outbound-worker -> message client envoye par tenant cible | **CRITICAL** | not-probed-mutation | tenantGuard membership check obligatoire avant tout test positif | comportement decrit, pas teste |
| R1.6 | outbound-conversions/destinations | cross-tenant lecture/creation/edit/delete/test webhook destinations | MEDIUM | apparently mitigated by `checkAccess` (audit confirmatif requis) | audit confirmatif que `checkAccess` couvre 100% des handlers + verify x-user-email injection consumers | famille decrite, mitigation noted |
| R1.7 | outbound-conversions/destinations/:id/test | trigger webhook externe avec event factice vers URL destination de tenant cible | LOW (deja protege checkAccess) | mitigated | audit confirmatif | -- |

**Disclosure level** : aucun payload reproductible, aucun PoC, aucun secret, aucun draftText, aucune URL provider externe sensible, aucun token expose. Les risques sont decrits par famille + impact pour permettre le decoupage en sous-phases sans donner de recette exploitable.

---

## 9. Proposed AS.13.x sequencing

Decoupage DEV first, plus petit scope avec plus haut risque + plus faible blast radius en premier :

| Phase | Scope | Priority | Code repos | Build needed | QA required | Rollback target |
|---|---|---|---|---|---|---|
| **AS.13.1** | google-observability : 1 endpoint, rendre tenantId obligatoire + tenantGuard. Si `scope=owner` -> adminGuard (a clarifier produit). | P0 URGENT | keybuzz-api | API only | QA browser admin dashboard si endpoint utilise | v3.5.186-prod |
| **AS.13.2** | outbound /deliveries : 5 endpoints (2 GET + 3 mutations). tenantGuard matcher dynamique `isOutboundDeliveriesGet` + `isOutboundDeliveryAction`. Aucun test positif mutation. | P0 | keybuzz-api | API only | QA browser admin deliveries panel si existe | v3.5.187 issue de AS.13.1 |
| **AS.13.3** | compat /api/v1/marketplaces/amazon/* : 6 endpoints. Choix design : (a) tenantGuard membership avant proxyToLegacyBackend ; (b) refactor pour utiliser BFF Client safe pattern partout. Recommande (a) pour scope minimal. | P0 | keybuzz-api | API only (BFF Client deja safe-bound session) | QA browser channels Amazon (status + oauth/start sans cliquer + disconnect read-only) | v3.5.188 issue de AS.13.2 |
| **AS.13.4** | outbound-conversions/destinations : 6 endpoints. Audit confirmatif `checkAccess` couvre 100% des handlers. Verify x-user-email injection cote consumers. Patch optionnel si gaps detectes. | P2 | keybuzz-api uniquement si gap detecte | none probable | QA destinations panel si existe | v3.5.189 |

Chaque sous-phase suit le pattern AS.11/12 standard :
- Patch minimal (PROTECTED_ROUTES exact + matchers si dynamic).
- Commit + push AVANT build.
- Build from-git via scripts AS.12.2C-3.1 (OCI labels KEY-308 + KEY-309 immuables + KEY-302 si Client touche).
- Validation negative-only (401 no-auth, 403 cross-tenant, 400 missing fields).
- DB no-mutation snapshot pre/post (outbound_deliveries, signup_attribution, outbound_conversion_destinations counts).
- QA Ludovic navigateur DEV puis PROD sur URL correcte (`https://client-dev.keybuzz.io` / `https://client.keybuzz.io`).
- Rollback GitOps strict vers tag precedent.

Total endpoints a proteger apres AS.13.4 :
- AS.13.1 : +1 endpoint
- AS.13.2 : +5 endpoints (2 GET + 3 mutations)
- AS.13.3 : +6 endpoints (2 GET + 4 POST)
- AS.13.4 : 0 si checkAccess OK / sinon a definir

Bonus : si AS.13.4 confirme que destinations est deja safe, total NEW endpoints proteges = 12 sur R1.

---

## 10. No-mutation proof

| Item | Statut |
|---|---|
| Aucun patch source applique | OK |
| Aucun build / docker push | OK |
| Aucun deploy K8s / manifest infra touche | OK |
| Aucun POST/PATCH/PUT/DELETE positif vers API | OK |
| Aucun appel mutationnel simulate-deliver/fail/retry | OK |
| Aucun appel OAuth start / disconnect / send-validation | OK |
| Aucun appel webhook destination test | OK |
| Aucune mutation DB de notre fait | OK |
| Aucune fixture / fake event / fake conversion | OK |
| Aucun secret / token / cookie / PII display | OK |
| Aucun draftText | OK |
| Aucun changement Linear status (KEY-313 reste Open) | OK |
| KEY-301 non rouvert | OK |
| Bastion install-v3 only | OK |
| READ-ONLY strict respecte | OK |

---

## 11. Linear text prepared (KEY-313 disclosure-controlled)

### 11.1 KEY-313 commentaire cible

```
## AS.13.0 R1 outbound + compat truth audit -- GO PARTIAL with UNKNOWNS

Read-only audit completed across DEV + PROD. 18 endpoints inventoried across 4 sub-modules :

- compat (legacy Amazon proxy) : 6 endpoints, tenantId query/header arbitrary, NO membership.
- outbound/deliveries : 5 endpoints (3 mutations), local preHandler requires tenantId but NO membership.
- outbound-conversions/destinations : 6 endpoints, **already protected** by internal `checkAccess` via user_tenants (audit confirmatif requis).
- outbound-conversions/google-observability : 1 endpoint, tenantId optional -> **CRITICAL multi-tenant leak** if omitted (no auth required, returns aggregate marketing data all tenants).

Safe GET probes PROD (no-auth, fictif UUID) confirm :
- amazon/status?tenant_id=fake -> 200
- outbound/deliveries?tenantId=fake -> 200
- google-observability (no tenant) -> 200 with global aggregate
- destinations (no auth) -> 400 (checkAccess OK)

No mutation endpoints probed (simulate-deliver/fail/retry, oauth/start, disconnect, send-validation, webhook test) per READ-ONLY scope.

**Recommended sequencing** (DEV first, smallest blast radius first) :
- AS.13.1 : google-observability tenantId required + adminGuard if scope=owner (P0 URGENT, 1 endpoint, smallest patch).
- AS.13.2 : outbound/deliveries 5 endpoints tenantGuard matcher (P0, 2 GET + 3 mutations).
- AS.13.3 : compat 6 endpoints tenantGuard membership before proxy (P0, OAuth + status + disconnect + inbound-address).
- AS.13.4 : outbound-conversions/destinations audit confirmatif checkAccess (P2, likely 0 patch).

No patch / build / deploy / DB / runtime mutation in this phase. KEY-313 stays Open.

Disclosure controle : no PoC, no payload reproducible, no PII, no draftText, no secret, no exploit recipe.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.0-R1-OUTBOUND-COMPAT-TENANTGUARD-TRUTH-AUDIT-01.md
```

Note : backlog ~37 jeux de commentaires Linear KEY-* en attente methode token API (script bash bloque sur Done state resolution durant AS.12.3A ; resolu en partie par outils Linear directs).

---

## 12. Gaps / unknowns

| # | Gap | Severite | Plan |
|---|---|---|---|
| U1 | `outbound-conversions/destinations` consumers : pas de BFF Client detecte ; probablement admin-v2 ou usage direct API. Verifier que `x-user-email` est bien injecte par consumers reels avant declarer "deja safe". | Low | A clarifier durant AS.13.4 audit confirmatif. |
| U2 | google-observability `scope=owner` semantique produit : si scope=owner avec tenantId, le filter inclut `marketing_owner_tenant_id`. Necessite decision produit pour decider si adminGuard requis ou seulement tenantGuard tenant-scoped. | Medium | A clarifier durant AS.13.1 design. |
| U3 | Backend cible (`LEGACY_BACKEND_URL`) trust X-Internal-Token. Si le compat proxy est protege par tenantGuard cote keybuzz-api, le backend reste accessible si l attaquant a un acces direct (network). Hors scope KEY-313 (network segmentation a verifier au niveau infra). | Low | Documente comme "internal-only network responsibility". |
| U4 | outbound-worker (`v3.5.165-escalation-flow`) image ancienne. Si l image contient des routes outbound non protegees, le worker peut consommer/declencher operations dans la cible. A verifier si le worker expose des routes HTTP ou si c est uniquement un consumer Redis/queue. | Low | A clarifier ; probablement consumer-only sans surface HTTP exposee. |
| U5 | Routes mutationnelles non probees : simulate-deliver/fail/retry, OAuth start/disconnect/send-validation, webhook destination test. Comportement attendu inference, mais pas de probe runtime safe disponible sans mutation. | Medium | Trust source analysis + DB no-mutation snapshot pre/post lors des phases d implementation. |

---

## 13. Recommendation

**Verdict** : GO PARTIAL R1 AUDIT READY WITH UNKNOWNS (U1-U5 documente).

**Prochaine action proposee** : lancement **AS.13.1** (google-observability) -- la plus URGENTE des 4 sous-phases car :
1. Leak observable **sans authentification** sur PROD (probe runtime confirmee).
2. Donnees affectees : `signup_attribution` aggregate (gclid_count, utm, conversions_sent, total_signups) + dernier gclid avec son `tenant_id` + derniere conversion -- impact marketing data inter-tenant.
3. Patch minimal estimable : ajouter check `if (!tenantId) reply.status(400/401)` + (decision produit) si `scope=owner` -> adminGuard ; sinon strictement tenantGuard.
4. Aucun build Client requis (handler API only).
5. Aucune mutation DB impliquee (handler purement read SQL).
6. Validation negative-only complete possible (400/401 sans tenantId, 403 cross-tenant si tenantGuard membership applique).

KEY-313 reste Open. Aucun changement Linear status durant cette phase.

---

## 14. Phrase cible finale

AS.13.0 R1 audit livre : inventaire complete 4 modules outbound + compat avec 18 endpoints (compat 6 endpoints proxy Amazon `/api/v1/marketplaces/amazon/*` sans membership check + outbound 5 endpoints `/deliveries*` dont 3 mutations DB sans membership check + outbound-conversions/destinations 6 endpoints DEJA proteges via `checkAccess` user_tenants + outbound-conversions/google-observability 1 endpoint **LEAK CRITIQUE** si tenantId omis) ; classification security : compat HIGH tenant-scoped non protege, outbound HIGH tenant-scoped non protege (preHandler tenantId required mais sans membership), destinations LOW deja protege checkAccess, google-observability CRITICAL leak non-authentifie ; probes safe GET PROD no-auth confirme runtime risques (amazon/status?tenantId=fake -> 200, outbound/deliveries?tenantId=fake -> 200, google-observability no-tenant -> 200 avec data aggregate tous tenants, destinations no-auth -> 400 OK) ; aucun endpoint mutationnel probe (simulate-deliver/fail/retry, OAuth start/disconnect, webhook test marques NOT_PROBED_MUTATION_RISK) ; logs API PROD 10min 0 5xx + outbound-worker 1/1 ready ; decoupage propose 4 sous-phases DEV first plus petit scope plus haut risque blast radius minimal en premier : AS.13.1 google-observability tenantId required + adminGuard scope=owner P0 URGENT 1 endpoint, AS.13.2 outbound/deliveries 5 endpoints tenantGuard matcher P0, AS.13.3 compat 6 endpoints tenantGuard membership avant proxy P0, AS.13.4 outbound-conversions/destinations audit confirmatif P2 ; risk matrix disclosure-controlled : R1.1 CRITICAL google-observability leak + R1.2 HIGH compat cross-tenant + R1.3 HIGH outbound reads + R1.4 HIGH simulate-deliver/fail pollution + R1.5 CRITICAL retry cross-tenant declenche provider externe + R1.6 MEDIUM destinations (mitige checkAccess) + R1.7 LOW destinations test ; aucun PoC / payload / PII / draftText / secret diffuse ; aucune mutation source / build / docker push / deploy K8s / manifest / DB / runtime ; aucun changement Linear status (KEY-313 reste Open, KEY-301 reste Done) ; PROD strictement read-only ; gaps U1-U5 documentes (consumers destinations, scope owner semantique, network segmentation backend, outbound-worker surface, routes mutationnelles non probees) ; verdict AS.13.0 GO PARTIAL R1 AUDIT READY WITH UNKNOWNS.

STOP. AS.13.0 R1 audit livre. Aucun patch, build, deploy ou mutation. Aucun enchainement vers AS.13.1 sans GO Ludovic.
