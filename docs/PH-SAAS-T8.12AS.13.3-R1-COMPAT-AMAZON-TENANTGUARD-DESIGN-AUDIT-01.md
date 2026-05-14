# PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01
> Environnement : DEV + PROD read-only. Aucun patch, build, deploy ou mutation.

---

## 1. VERDICT

GO COMPAT AMAZON DESIGN READY

Les 6 endpoints HTTP `/api/v1/marketplaces/amazon/*` exposes par le compat module de `keybuzz-api` peuvent etre couverts en un seul patch AS.13.3A via 6 entrees `PROTECTED_ROUTES` static dans `keybuzz-api/src/plugins/tenantGuard.ts`. Le runtime PROD confirme la faille AS.13.0 (probe safe `GET /api/v1/marketplaces/amazon/status?tenantId=fake` no headers -> 200 `DISCONNECTED`). Aucun consumer Client moderne n appelle le compat keybuzz-api : les BFF Next.js `app/api/amazon/*/route.ts` ainsi que `src/lib/api-client.ts:fetchBackend` ciblent directement `BACKEND_URL` (keybuzz-backend). Le compat keybuzz-api est donc une surface legacy abandonnee mais toujours exposee publiquement, ce qui rend la protection sans risque de regression UX. Aucun bypass admin / OAuth callback / internal n est requis. Validation future strictement negative-only (aucun OAuth start, disconnect, inbound-address send-validation positif). KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Surface visee | `keybuzz-api` compat module : 6 endpoints `/api/v1/marketplaces/amazon/*` |
| Module source | `keybuzz-api/src/modules/compat/routes.ts` (182 lignes) |
| Patch propose | `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES static, 6 entrees ajoutees) |
| Hors scope | keybuzz-backend cible (les routes /api/v1/marketplaces/amazon/* cote backend acceptent X-Internal-Token et sont protegees au niveau network ; voir gap U1) ; OAuth callback Amazon (ne passe pas par le compat keybuzz-api) ; Client BFF (n appelle pas le compat) ; Admin v2 (aucun consumer) ; worker outbound (aucun appel HTTP compat) ; cron (aucun) |
| Tag cible DEV (futur) | v3.5.189-compat-amazon-tenantguard-dev |
| Tag cible PROD (futur) | v3.5.189-compat-amazon-tenantguard-prod |
| Rollback | v3.5.188-outbound-deliveries-tenantguard-{dev,prod} |

---

## 3. SOURCES

- PH-SAAS-T8.12AS.13.0-R1-OUTBOUND-COMPAT-TENANTGUARD-TRUTH-AUDIT-01.md (truth audit initial, identifie 6 endpoints + classification + probes safe)
- PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01.md (pattern matchers dynamiques recent)
- PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md (livraison precedente R1)
- PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md (pattern checkAccess local)
- Linear KEY-313

---

## 4. PREFLIGHT

### 4.1 Repos

| Repo | Path | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 55ab4bd6 | OK | dist/ deleted en worktree (cosmetique) | OK lecture |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970fb3b4 | OK | clean | OK read-only |
| keybuzz-backend | /opt/keybuzz/keybuzz-backend | main | b183817d3bf6 | OK | 1 fichier dirty (hors scope read-only audit, signaler en gap) | OK lecture |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | a35c9b25 | OK | clean | OK |

### 4.2 Runtime

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-dev |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev |
| DEV | keybuzz-backend (4 deploys) | v1.0.40 / v1.0.42 / v1.0.47 (-dev) |
| DEV | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev |
| PROD | keybuzz-api | v3.5.188-outbound-deliveries-tenantguard-prod |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod |
| PROD | keybuzz-backend (4 deploys) | v1.0.40 / v1.0.42 / v1.0.47 (-prod) |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Tous ready post AS.13.2A-PROD. Pas de rollout en cours.

---

## 5. ENDPOINT INVENTORY

Module : `keybuzz-api/src/modules/compat/routes.ts`.
Registration : `app.register(compatRoutes)` sans prefix (les routes sont mountees au full path `/api/v1/marketplaces/amazon/*`).

`getTenantId(request)` lit `query.tenantId || header X-Tenant-Id`. `proxyToLegacyBackend(request, reply, path, method)` forwarde X-Tenant-Id, X-User-Email, X-Internal-Token (et injecte automatiquement `KEYBUZZ_INTERNAL_PROXY_TOKEN` si absent) puis fetch sur `${LEGACY_BACKEND_URL}${path}`.

| # | Method | Path | Handler comportement | Tenant source | Auth actuelle | Membership |
|---|---|---|---|---|---|---|
| C1 | GET | /api/v1/marketplaces/amazon/status | LOCAL DB query `inbound_connections` WHERE `"tenantId" = $1 AND marketplace = 'amazon'` + fallback prefix LIKE | query `tenantId` ou header `X-Tenant-Id` | (aucune) | NON |
| C2 | POST | /api/v1/marketplaces/amazon/disconnect | proxyToLegacyBackend POST | header forward | (aucune ; X-Internal-Token injecte) | NON |
| C3 | GET | /api/v1/marketplaces/amazon/oauth/start | proxyToLegacyBackend GET + querystring forward | header forward | (aucune) | NON |
| C4 | POST | /api/v1/marketplaces/amazon/oauth/start | proxyToLegacyBackend POST | header forward | (aucune) | NON |
| C5 | GET | /api/v1/marketplaces/amazon/inbound-address | proxyToLegacyBackend GET | header forward | (aucune) | NON |
| C6 | POST | /api/v1/marketplaces/amazon/inbound-address/send-validation | proxyToLegacyBackend POST | header forward | (aucune) | NON |

Tables/objets potentiellement lus :
- `inbound_connections` (C1 SELECT).
- Backend distant : routes `/api/v1/marketplaces/amazon/{status,disconnect,oauth/start,inbound-address,inbound-address/send-validation}` (gerees par `keybuzz-backend/src/modules/marketplaces/amazon/amazon.routes.ts`).

Tables/objets potentiellement mutes :
- backend cote : MarketplaceConnection / OAuth state / SP-API credentials (C2 disconnect, C3/C4 oauth/start si l etape genere un row state, C6 send-validation declenche un email).

Provider externe :
- C3/C4 oauth/start : peut initier le flow OAuth Amazon SP-API (redirect URL + state generes par le backend).
- C6 send-validation : peut envoyer un email reel a l adresse marketplace de validation.
- C2 disconnect : revoque le token OAuth chez Amazon SP-API potentiellement.

---

## 6. BACKEND PROXY MAPPING

Le compat keybuzz-api forwarde **integralement** vers `${LEGACY_BACKEND_URL}` (keybuzz-backend) avec `X-Internal-Token` automatiquement injecte si absent. Le backend `keybuzz-backend/src/lib/devAuthMiddleware.ts` accepte ce token comme proxy authentifie.

| Path API | Path backend | Forwarded headers | Mutation side effect |
|---|---|---|---|
| C1 GET status | (non, C1 est LOCAL DB query) | n/a | none (read inbound_connections) |
| C2 POST disconnect | `${LEGACY_BACKEND_URL}/api/v1/marketplaces/amazon/disconnect` | X-Tenant-Id, X-User-Email, X-Internal-Token | revocation OAuth potentielle backend |
| C3 GET oauth/start | `${LEGACY_BACKEND_URL}/api/v1/marketplaces/amazon/oauth/start${qs}` | idem | OAuth state generation, redirect URL |
| C4 POST oauth/start | idem (method POST) | idem | OAuth state generation |
| C5 GET inbound-address | `${LEGACY_BACKEND_URL}/api/v1/marketplaces/amazon/inbound-address` | idem | none (probable read) |
| C6 POST send-validation | `${LEGACY_BACKEND_URL}/api/v1/marketplaces/amazon/inbound-address/send-validation` | idem | email envoye reel |

Confiance backend : l attaquant qui passe par le compat keybuzz-api herite des privileges du token interne. Donc la protection cote API compat est suffisante pour bloquer l acces externe. La protection du backend en direct (acces network/X-Internal-Token brute force) reste hors scope KEY-313 (gap U1 documente ci-dessous).

---

## 7. CONSUMER MAPPING

| Consumer | Route appelee | Cible reelle | Auth/session | Headers | Risk si tenantGuard ajoute au compat |
|---|---|---|---|---|---|
| Client BFF `app/api/amazon/status/route.ts` | `${BACKEND_URL}/api/v1/marketplaces/amazon/status` | **backend direct** | NextAuth getServerSession | X-User-Email, X-Tenant-Id, X-Internal-Token | NUL (n appelle pas le compat) |
| Client BFF `app/api/amazon/oauth/start/route.ts` | `${BACKEND_URL}/api/v1/marketplaces/amazon/oauth/start` | **backend direct** | NextAuth | idem | NUL |
| Client BFF `app/api/amazon/disconnect/route.ts` | `${BACKEND_URL}/api/v1/marketplaces/amazon/disconnect` | **backend direct** | NextAuth | idem | NUL |
| Client BFF `app/api/amazon/inbound-address/*` (2 routes) | `${BACKEND_URL}/api/v1/marketplaces/amazon/inbound-address[/send-validation]` | **backend direct** | NextAuth | idem | NUL |
| Client BFF `app/api/amazon/activate-channels` | `${AMAZON_BACKEND_URL}/api/v1/marketplaces/amazon/inbound-connection` (note : route distincte) | **backend direct** | NextAuth | idem | NUL |
| Client BFF `app/api/debug-amazon-connect` | `${AMAZON_BACKEND_URL}/api/v1/marketplaces/amazon/{status,oauth/start,inbound-address}` | **backend direct** | NextAuth (debug) | idem | NUL |
| Client `src/lib/api-client.ts:fetchBackend('/api/v1/marketplaces/amazon/oauth/start')` | `${BACKEND_URL || API_URL_INTERNAL || API_URL}${path}` (BACKEND_URL prend precedence) | **backend direct** (BACKEND_URL configure) | n/a internal helper | n/a | NUL |
| `keybuzz-client/src/services/amazon.service.ts` | `/api/amazon/*` (Next.js BFF interne) | -> BFF -> backend | NextAuth via BFF | injected by BFF | NUL |
| Admin v2 | (aucun grep match `/api/v1/marketplaces/amazon`) | n/a | n/a | n/a | NUL (aucun consumer) |
| keybuzz-backend internal | self-routing `/api/v1/marketplaces/amazon/*` cote backend (8+ routes dans amazon.routes.ts) | self | INTERNAL_TOKEN | n/a | NUL (n appelle pas le compat keybuzz-api) |
| External / unknown | aucun consumer documente du compat keybuzz-api `/api/v1/marketplaces/amazon/*` | n/a | n/a | n/a | NUL probable, voir gap U2 |

### 7.1 Conclusion consumers

Aucun consumer Client / Admin / worker / cron / backend n appelle le compat keybuzz-api `/api/v1/marketplaces/amazon/*`. Le compat est un "ghost surface" : techniquement expose en runtime (et exploitable comme confirme par AS.13.0), mais sans appelant legitime moderne. La protection tenantGuard ne casse aucune chain UX.

---

## 8. RISK MATRIX

Conforme AS.13.0 R1.2.

| # | Endpoint | Classification | Probed AS.13.0 | Risque cross-tenant | Required guard | Exemption ? |
|---|---|---|---|---|---|---|
| C1 | GET /api/v1/marketplaces/amazon/status | read DB tenant-scoped | OUI (200 fake tenantId -> DISCONNECTED) | HIGH (real tenantId leak connection status) | tenantGuard membership | NON |
| C2 | POST disconnect | provider mutation (revoque OAuth backend) | NOT_PROBED_MUTATION_RISK | HIGH (deconnecter Amazon tenant cible) | tenantGuard membership | NON |
| C3 | GET oauth/start | provider mutation (genere state OAuth) | NOT_PROBED_MUTATION_RISK | HIGH (initier OAuth pour tenant cible) | tenantGuard membership | NON |
| C4 | POST oauth/start | provider mutation | NOT_PROBED_MUTATION_RISK | HIGH | tenantGuard membership | NON |
| C5 | GET inbound-address | read backend tenant-scoped | NOT_PROBED (probable read-only) | MEDIUM (lire adresse SES tenant cible) | tenantGuard membership | NON |
| C6 | POST send-validation | provider mutation (envoie email reel) | NOT_PROBED_MUTATION_RISK | HIGH (envoyer email validation tenant cible) | tenantGuard membership | NON |

Aucun endpoint compat n est OAuth callback (le callback Amazon SP-API arrive directement sur le backend, voir `keybuzz-backend/src/modules/marketplaces/amazon/amazon.routes.ts`). Aucun endpoint n est public legitime. Aucun n est destine a un worker/cron. Donc aucune exemption necessaire.

---

## 9. PROPOSED AS.13.3A DESIGN

### 9.1 Pattern retenu : tenantGuard global, PROTECTED_ROUTES static

Aligne avec KEY-301 AS.11/AS.12 (entrees exact-path). Choisi sur AS.13.2 matchers dynamiques parce que les 6 paths sont fixes (pas de `:id`), donc la liste blanche statique est plus simple et plus auditable. Une future route amazon dans le compat necessitera un patch explicite (defense en profondeur).

Fichier patche : `keybuzz-api/src/plugins/tenantGuard.ts`.

Ajout de 6 entrees a `PROTECTED_ROUTES` :

```typescript
{ method: 'GET',  path: '/api/v1/marketplaces/amazon/status' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/disconnect' },
{ method: 'GET',  path: '/api/v1/marketplaces/amazon/oauth/start' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/oauth/start' },
{ method: 'GET',  path: '/api/v1/marketplaces/amazon/inbound-address' },
{ method: 'POST', path: '/api/v1/marketplaces/amazon/inbound-address/send-validation' },
```

Aucun nouveau matcher dynamique. Aucun changement de `isProtected` (les 6 entrees sont prises par la verification `PROTECTED_ROUTES.some(...)` existante ligne 478).

### 9.2 Effet runtime apres patch

| Cas | Avant AS.13.3A | Apres AS.13.3A |
|---|---|---|
| Pas de tenantId, pas de email | C1 retourne 200 disconnected ; C2-C6 proxy au backend (qui peut accepter ou rejeter selon X-Internal-Token) | 400 missing tenantId / 401 missing email (tenantGuard avant handler) |
| tenantId valide, pas de email | 200 leak / proxy ouvert | 400/401 (tenantGuard required headers) |
| tenantId valide, email valide, non-member | 200 / proxy ouvert | 403 Forbidden |
| tenantId valide, email valide, member owner/admin | 200 / proxy normal | 200 / proxy normal (handler tourne avec verification membership cache 30s) |
| Bypass admin role (super_admin / account_manager / media_buyer) | n/a | NON applicable : tenantGuard pur. Aucun admin marketing consumer du compat. |

### 9.3 Pas de modification handler ni Client

`compat/routes.ts` reste inchange. Aucun BFF Client a modifier (les consumers Client moderne contournent deja le compat). Aucun Admin v2 a modifier (zero consumer).

### 9.4 Decision split

AS.13.3A unique :
- 1 patch fichier `tenantGuard.ts` (+6 entrees PROTECTED_ROUTES)
- 0 patch source `compat/routes.ts`
- 0 patch Client / Admin v2 / backend / worker
- Blast radius UX : nul (aucun consumer HTTP legitime moderne)
- Test plan : negative-only strict ; AUCUN POST positif (OAuth start/disconnect/send-validation sont des mutations provider qui ne doivent jamais etre declenchees pendant validation)

Pas de split A/B parce que :
1. Aucun consumer legitime, donc aucune chain UX a preserver entre read et mutations.
2. Les 6 entrees sont 6 lignes dans le meme tableau, une seule revue suffit.
3. La protection est uniforme (membership owner/admin avant proxy/handler).

---

## 10. VALIDATION PLAN (FUTUR AS.13.3A IMPL ; AUCUNE EXECUTION DANS CETTE PHASE)

### 10.1 Probes negative-only (DEV puis PROD)

Toutes les probes sont rejet pre-handler. AUCUN POST positif sur C2/C3/C4/C6 (ce sont des mutations provider externe).

| Probe | Method + Path | Headers | Verdict attendu |
|---|---|---|---|
| N1 | GET /api/v1/marketplaces/amazon/status?tenantId=fake | aucun | 400 tenantId missing OU 401 missing email (tenantGuard) |
| N2 | GET /api/v1/marketplaces/amazon/status?tenantId=fake | x-user-email=probe@invalid | 403 not a member |
| N3 | POST /api/v1/marketplaces/amazon/disconnect | aucun | 400/401 (rejet pre-handler, AUCUN proxy backend declenche) |
| N4 | POST /api/v1/marketplaces/amazon/disconnect | email=probe@invalid + tenant=fake | 403 (AUCUN OAuth revoke declenche) |
| N5 | GET /api/v1/marketplaces/amazon/oauth/start?tenantId=fake | aucun | 400/401 |
| N6 | GET /api/v1/marketplaces/amazon/oauth/start?tenantId=fake | email=probe@invalid | 403 (AUCUN OAuth state genere) |
| N7 | POST /api/v1/marketplaces/amazon/oauth/start | email=probe@invalid + tenant=fake | 403 |
| N8 | GET /api/v1/marketplaces/amazon/inbound-address?tenantId=fake | aucun | 400/401 |
| N9 | POST /api/v1/marketplaces/amazon/inbound-address/send-validation | email=probe@invalid + tenant=fake | 403 (AUCUN email reel envoye) |

### 10.2 DB / provider snapshot

| Counter | Comment surveiller | Delta attendu |
|---|---|---|
| `inbound_connections` total | SELECT COUNT(*) avant vs apres | 0 |
| OAuth state rows (backend) | SELECT COUNT(*) FROM oauth_state si table existe | 0 |
| MarketplaceConnection count (backend) | SELECT COUNT(*) FROM "MarketplaceConnection" | 0 |
| Email envoyes (validation) | log SES backend / email service | 0 |
| Worker outbound logs | grep amazon | 0 ligne correlee aux probes |
| API DEV/PROD logs | 5xx, 400, 401, 403 sequence | conforme aux probes ci-dessus |

### 10.3 Preserve sample protections

| Famille | Sample | Verdict attendu |
|---|---|---|
| AS.13.2A outbound/deliveries | GET /outbound/deliveries (no headers) | 400 TENANT_ID_MISSING preserve |
| AS.13.1 google-observability | GET /outbound-conversions/google-observability (no headers) | 400 preserve |
| AS.12.1A messages/conversations | GET /messages/conversations fake/fake | 403 preserve |

---

## 11. NO-MUTATION PROOF

Pour cette phase de design audit, aucune execution mutationnelle :
- Aucun POST envoye contre `/api/v1/marketplaces/amazon/disconnect`, `oauth/start`, `inbound-address/send-validation`.
- Aucun OAuth state genere.
- Aucune deconnexion provider declenchee.
- Aucun email de validation envoye.
- Aucune trace cote backend liee a cette phase.

Une seule probe safe a ete relancee (cf section 5/7 pour la confirmation runtime de la faille AS.13.0 toujours active) :
- `GET https://api.keybuzz.io/api/v1/marketplaces/amazon/status?tenantId=00000000-0000-0000-0000-000000000000` no headers -> 200 `{connected: false, status: "DISCONNECTED"}`. Lecture DB read-only confirme (handler local read uniquement).

Conforme `no fake metrics / no fake events / no fake conversion / no fake provider response`.

---

## 12. LINEAR

KEY-313 reste Open. KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans secret, sans client_id/client_secret) :

```
PH-SAAS-T8.12AS.13.3-R1 design audit livre.

Scope : 6 endpoints HTTP /api/v1/marketplaces/amazon/* exposes par le compat module de keybuzz-api (GET status + POST disconnect + GET/POST oauth/start + GET inbound-address + POST inbound-address/send-validation). Aucun a actuellement de verification membership ; preHandler/handler accepte tenantId arbitraire en query/header puis proxy au backend via X-Internal-Token injecte.

Verification runtime PROD : GET /api/v1/marketplaces/amazon/status?tenantId=fake no headers retourne 200 (faille AS.13.0 confirmee toujours active).

Decision design :
- Pattern tenantGuard global, PROTECTED_ROUTES static (6 entrees ajoutees) - aligne KEY-301 AS.11/12.
- Pas de matchers dynamiques (les 6 paths sont fixes, pas de :id).
- Pas de bypass admin (aucun consumer Admin v2 du compat).
- Pas de bypass OAuth callback (le callback Amazon SP-API arrive directement sur le backend, pas via le compat).
- AS.13.3A unique (pas de split read/mutations) : 1 patch tenantGuard.ts, 0 patch compat/routes.ts, 0 patch Client/Admin/backend/worker.

Consumers du compat keybuzz-api : 0 dans le code base actuel. Les BFF Client modernes (app/api/amazon/*) ainsi que src/lib/api-client.ts:fetchBackend ciblent directement BACKEND_URL (keybuzz-backend), pas le compat keybuzz-api. Le compat est une surface legacy abandonnee mais toujours exposee runtime.

Validation future strictement negative-only : aucun POST positif sur disconnect / oauth-start / send-validation (mutations provider externe). DB snapshot inbound_connections + MarketplaceConnection backend + email logs unchanged. Aucun OAuth state genere, aucun email reel envoye, aucune deconnexion declenchee pendant validation.

Tag cible futur : v3.5.189-compat-amazon-tenantguard-{dev,prod}. Rollback : v3.5.188.

KEY-313 reste Open. KEY-301 reste Done. Aucun build, aucun deploy, aucune mutation dans cette phase.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 13. GAPS / UNKNOWNS

| # | Gap | Impact | Action |
|---|---|---|---|
| U1 | Backend keybuzz-backend trust X-Internal-Token comme proxy authentifie. Si l attaquant peut atteindre le backend directement (network segmentation faillible) il bypasse le compat. Network/segmentation defense-in-depth est hors scope KEY-313. | Low | Documente comme "internal-only network responsibility". A traiter en backlog infra. |
| U2 | Aucun consumer Client moderne n appelle le compat keybuzz-api. Mais une integration tierce externe ou un script ancien pourrait l appeler (non observable dans le code base). | Low | Apres patch, surveiller les logs API 401/403 pour detecter d eventuels consumers legitimes. |
| U3 | keybuzz-backend repo dirty=1 (1 fichier non-committe au moment du preflight). Hors scope read-only audit. | Low | Signaler ; ne pas toucher. |
| U4 | Le compat C1 status repond meme avec tenantId arbitraire en LOCAL DB (sans proxy). Apres patch, ce read sera ferme cote API mais le backend reste accessible si l attaquant a un acces direct (cf U1). | Low | Defense-in-depth backend en R3 ou plus tard. |
| U5 | C5 inbound-address marquee `NOT_PROBED` car non probee. Si elle se revele ecrire en DB, la classification deviendrait mutation. Aucune action positive ne sera faite pendant la validation, donc le risque est nul. | Negligeable | Probe negative-only confirmera le rejet pre-handler. |

---

## 14. NEXT PHASES (en attente GO Ludovic explicite)

| Phase | Scope | Pre-requis |
|---|---|---|
| AS.13.3A IMPL DEV | Patch tenantGuard.ts (+6 entrees PROTECTED_ROUTES) + build DEV + GitOps DEV + validation negative-only + DB/provider snapshot | GO Ludovic explicite |
| AS.13.3A PROD | Build PROD + push + GitOps PROD + validation negative-only + QA Ludovic | GO Ludovic + AS.13.3A DEV OK |
| AS.13.4 | outbound-conversions/destinations (6 endpoints, audit confirmatif checkAccess deja en place ; probable 0 patch) | Apres AS.13.3A PROD |
| R3 backend defense-in-depth | network segmentation backend + X-Internal-Token rotation (gap U1) | Backlog hors KEY-313 strict |
| KEY-312 (GP1) | PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 garde-fous metier | Hors scope KEY-313 |

---

## 15. VERDICTS AUTORISES

- GO COMPAT AMAZON DESIGN READY (verdict retenu)
- GO PARTIAL COMPAT AMAZON DESIGN READY WITH UNKNOWNS
- NO GO COMPAT AMAZON MUTATION RISK UNCLEAR
- NO GO SOURCE/RUNTIME DRIFT

---

## 16. PHRASE CIBLE FINALE

GO COMPAT AMAZON DESIGN READY. KEY-313 reste Open. KEY-301 reste Done. Aucun enchainement vers AS.13.3A IMPL sans GO Ludovic explicite.

STOP.
