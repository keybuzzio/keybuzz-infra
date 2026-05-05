# PH-SAAS-T8.12AO.4 — Amazon OAuth Activation Bridge PROD Truth Audit and Fix

> Phase : PH-SAAS-T8.12AO.4-AMAZON-OAUTH-ACTIVATION-BRIDGE-PROD-TRUTH-AUDIT-AND-FIX-01
> Date : 5 mai 2026
> Environnement : DEV-first fix, promotion PROD
> Type : audit verite PROD + correction ciblee Backend-only
> Priorite : P0
> Ticket : KEY-248
> Phase precedente : PH-SAAS-T8.12AO.3 (PROD Backend AO.2 promotion)
> Verdict : **GO PARTIEL — USER OAUTH VALIDATION PENDING**

---

## Phrase cible

AMAZON OAUTH ACTIVATION BRIDGE FIXED — FK VIOLATION ROOT CAUSE IDENTIFIED AND RESOLVED — TENANT AUTO-PROVISIONED IN BACKEND DB — INBOUND CONNECTION AND ADDRESS CREATED FOR BON-KB — ECOMLG/SWITAA PRESERVED — NO TENANT HARDCODING — BACKEND-ONLY FIX — API/CLIENT UNCHANGED — GITOPS STRICT — AWAITING USER E2E OAUTH TEST

---

## 1. Preflight PROD

### Images AVANT promotion

| Service | Image manifest | Image runtime | Restarts | Verdict |
|---|---|---|---|---|
| Backend | `v1.0.45-amazon-oauth-returnto-guard-prod` | `v1.0.45-amazon-oauth-returnto-guard-prod` | 0 | A promouvoir |
| API | `v3.5.142-promo-retry-email-prod` | `v3.5.142-promo-retry-email-prod` | 0 | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | `v3.5.153-promo-visible-price-prod` | 0 | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | 0 | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | 7 (preexist.) | Non touche |

### Env vars critiques Backend PROD

| Variable | Valeur | Verdict |
|---|---|---|
| CLIENT_APP_URL | `https://client.keybuzz.io` | OK (AO.3) |
| AMAZON_SPAPI_REDIRECT_URI | `https://backend.keybuzz.io/.../callback` | OK |
| NODE_ENV | production | OK |
| AMAZON_BACKEND_URL (Client) | `http://keybuzz-backend...local:4000` | OK |

---

## 2. Audit logs OAuth PROD — tentatives Ludovic

### Logs Backend PROD (3 tentatives recentes)

| # | State | returnTo | expected_channel | tenant_id | callback OK | ensureInbound | redirect | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | `bdc66ff1-...` | `client.keybuzz.io/channels?...amazon-fr` | amazon-fr | bon-kb-mosf283z | OUI | **FK VIOLATION** | `client.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-fr` | **FAIL INBOUND** |
| 2 | `fad8f5b4-...` | `/start` | (none) | bon-kb-mosf283z | OUI | **FK VIOLATION** | `client.keybuzz.io/start?amazon_connected=true` | **FAIL INBOUND** |
| 3 | `2f0f4357-...` | `client.keybuzz.io/channels?...amazon-es` | amazon-es | bon-kb-mosf283z | OUI | **FK VIOLATION** | `client.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-es` | **FAIL INBOUND** |

### Erreur exacte

```
[Amazon OAuth] Failed to create inbound address: PrismaClientKnownRequestError:
Invalid `prisma.inboundConnection.upsert()` invocation:
Foreign key constraint violated on the constraint: `inbound_connections_tenantId_fkey`
```

### Logs Client BFF

```
[Amazon Activate] Backend inbound-connection check failed: 404
```
(6 occurrences — toutes les tentatives echouent au meme point)

### Analyse

- Le retour OAuth est correct (AO.2/AO.3 fix fonctionne)
- `expected_channel` est preserve dans le redirect
- `tenant_id` est preserve
- L'echec est **avant** le BFF bridge — c'est le Backend callback lui-meme qui echoue a creer la connection
- Ensuite le BFF obtient 404 car aucune connection n'existe

---

## 3. Audit DB PROD cible Bon KB

### Backend DB (`keybuzz_backend`)

| Element | Attendu | Trouve | Verdict |
|---|---|---|---|
| Tenant `bon-kb-mosf283z` | Present | **NOT FOUND** | **ROOT CAUSE** |
| `inbound_connections` pour bon-kb | Au moins 1 READY | **AUCUNE** | Consequence FK |
| `inbound_addresses` pour bon-kb | Au moins 1 | **AUCUNE** | Consequence FK |

Tenants existants dans Backend DB PROD (4 seulement) :
- `ecomlg-001`
- `compta-ecomlg-gmail--mnvu4649`
- `ludo-gonthier-ga4mpf-mo5ldw59`
- `ecomlg-mo4h93e7`

### API DB (`keybuzz`)

| Element | Attendu | Trouve | Verdict |
|---|---|---|---|
| Tenant `bon-kb-mosf283z` | Present | `{"id":"bon-kb-mosf283z","name":"Bon KB","status":"active"}` | OK (existe ici) |
| `inbound_connections` pour bon-kb | Au moins 1 | **AUCUNE** | Pas de bridge data |

### Synthese

Le tenant `bon-kb-mosf283z` a ete cree via l'API (promo flow) dans la DB API (`keybuzz`), mais n'a **jamais ete cree** dans la Backend DB (`keybuzz_backend`). Le schema Prisma du Backend a une foreign key `inbound_connections.tenantId -> tenants.id` qui empeche la creation de connections pour des tenants inexistants.

---

## 4. Root cause

| Hypothese | Preuve | Verdict | Fix requis |
|---|---|---|---|
| Tenant absent de Backend DB → FK violation | `findUnique("bon-kb-mosf283z")` = NOT FOUND, log FK error | **CONFIRME** | OUI |
| Backend ne synchronise pas les tenants de l'API DB | Backend DB a 4 tenants, API DB en a beaucoup plus | **CONFIRME** | OUI |
| Pas d'inbound connection → BFF 404 → pas de bridge → API can't activate | Logs client: `Backend inbound-connection check failed: 404` | **CONFIRME** | Consequence |
| `expected_channel` perdu | Non — preserve correctement dans redirect | **REFUTE** | Non |
| returnTo incorrect | Non — fix AO.2/AO.3 fonctionne | **REFUTE** | Non |

### Classification

**BACKEND ONLY** — Le Backend echoue a creer la connection car le tenant n'existe pas dans sa propre DB. La solution est d'auto-provisionner le tenant dans la Backend DB avant l'upsert connection.

---

## 5. Contrat expected_channel

| Entree | Source expected_channel | Transport | Fallback | Verdict |
|---|---|---|---|---|
| `/channels` | Clic utilisateur sur connecteur | `returnTo` URL param + OAuth state | Reconstruit depuis URL | OK |
| `/start` | Bouton "Connecter Amazon" | `returnTo=/start` sans channel explicite | `/start` ne transporte pas de channel | **NOTE** |

Note `/start` : le flow `/start` ne transporte pas de `expected_channel` explicite. Le Backend callback detecte le pays depuis le `selling_partner_id` Amazon et l'utilise pour creer la connection. C'est un comportement correct car `/start` est un flow generique.

---

## 6. Patch

### Fichier unique modifie

| Fichier | Changement | Pourquoi | Risque |
|---|---|---|---|
| `src/modules/inboundEmail/inboundEmailAddress.service.ts` | Ajout `prisma.tenant.upsert()` avant `inboundConnection.upsert()` dans `ensureInboundConnection()` | Auto-provisionner le tenant dans Backend DB si absent | Faible — upsert idempotent, `update: {}` ne change rien pour les tenants existants |

### Diff

```diff
+  // PH-SAAS-T8.12AO.4: Ensure tenant exists in Backend DB (new tenants may only exist in API DB)
+  try {
+    await prisma.tenant.upsert({
+      where: { id: tenantId },
+      create: {
+        id: tenantId,
+        slug: tenantId,
+        name: tenantId,
+      },
+      update: {},
+    });
+  } catch (tenantErr: any) {
+    if (tenantErr?.code === 'P2002') {
+      logger.info(`[InboundEmail] Tenant ${tenantId} already exists (slug conflict), skipping`);
+    } else {
+      logger.warn(`[InboundEmail] Failed to ensure tenant ${tenantId} in Backend DB:`, tenantErr);
+    }
+  }
```

### Principe

1. Avant chaque `inboundConnection.upsert`, verifier si le tenant existe dans Backend DB
2. Si absent, le creer avec id=tenantId, slug=tenantId, name=tenantId (placeholders)
3. Si le tenant existe deja (par id), `update: {}` = no-op (aucune modification)
4. Si conflit slug (P2002), log info et continuer (le tenant existe sous un autre id)
5. L'upsert connection peut alors s'executer normalement

### No-hardcoding audit

| Pattern | Occurrences | Verdict |
|---|---|---|
| `bon-kb-mosf283z` | 0 | CLEAN |
| `ecomlg-001` | 0 | CLEAN |
| `switaa` | 0 | CLEAN |
| `A13V1IB3` | 0 | CLEAN |
| `sellercentral` hardcode | 0 | CLEAN |
| country hardcode | 0 | CLEAN |

---

## 7. Images

### DEV

| Service | Tag | Digest | Source commit |
|---|---|---|---|
| Backend DEV | `v1.0.46-amazon-oauth-activation-bridge-dev` | `sha256:1e00eb9f96c46ba4823194348005075234efd766caca35e12365beb3dbfb3174` | `d7f48fc` |

### PROD

| Service | Tag | Digest | Source commit | Change |
|---|---|---|---|---|
| Backend | `v1.0.46-amazon-oauth-activation-bridge-prod` | `sha256:4a3529d3b4a4453a272a20c14e8651b2ec7abd37ebf5b4a2de2d1d3ff448bc3c` | `d7f48fc` | **PROMU** |
| API | `v3.5.142-promo-retry-email-prod` | (inchange) | — | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | (inchange) | — | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | (inchange) | — | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | (inchange) | — | Non touche |

---

## 8. GitOps

| Manifest | Image avant | Image apres | Commit infra |
|---|---|---|---|
| `k8s/keybuzz-backend-dev/deployment.yaml` | `v1.0.45-amazon-oauth-returnto-guard-dev` | `v1.0.46-amazon-oauth-activation-bridge-dev` | `5a58d74` |
| `k8s/keybuzz-backend-prod/deployment.yaml` | `v1.0.45-amazon-oauth-returnto-guard-prod` | `v1.0.46-amazon-oauth-activation-bridge-prod` | `3c13d2a` |

### Rollback

```yaml
# k8s/keybuzz-backend-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-amazon-oauth-returnto-guard-prod
```
Puis `git commit` + `git push` + `git pull` bastion + `kubectl apply -f` + `kubectl rollout status`.

---

## 9. Validation DEV

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| Nouveau tenant non-existant → ensureInboundConnection | Connection READY + address creee | SUCCESS — tenant auto-cree, connection READY, address FR | **PASS** |
| ecomlg-001 idempotence | slug/name inchanges apres upsert | `{slug:"ecomlg",name:"eComLG"}` → identique | **PASS** |
| Cleanup test | Tenant test supprime proprement | OK | **PASS** |

---

## 10. Validation structurelle PROD

| Check | Resultat | Verdict |
|---|---|---|
| Backend PROD image runtime | `v1.0.46-amazon-oauth-activation-bridge-prod` | **PASS** |
| Patch `tenant.upsert` present dans dist | OUI (verifie via `node -e`) | **PASS** |
| `slug: tenantId` present | OUI | **PASS** |
| `P2002` handler present | OUI | **PASS** |
| Health OK (uptime 78s, 0 restarts) | OUI | **PASS** |
| CLIENT_APP_URL | `https://client.keybuzz.io` | **PASS** |
| AMAZON_SPAPI_REDIRECT_URI | `https://backend.keybuzz.io/.../callback` | **PASS** |
| NODE_ENV | production | **PASS** |
| API PROD inchange | `v3.5.142-promo-retry-email-prod` | **PASS** |
| Client PROD inchange | `v3.5.153-promo-visible-price-prod` | **PASS** |

### Test `bon-kb-mosf283z` en PROD

| Etape | Resultat | Verdict |
|---|---|---|
| Tenant avant | NOT FOUND | (attendu) |
| `ensureInboundConnection({tenantId, marketplace:"amazon", countries:["FR"]})` | SUCCESS | **PASS** |
| Tenant apres | `{"id":"bon-kb-mosf283z","slug":"bon-kb-mosf283z"}` | **PASS** |
| Connection | `[{status:"READY", countries:["FR"]}]` | **PASS** |
| Address | `amazon.bon-kb-mosf283z.fr.fq7fep@inbound.keybuzz.io` | **PASS** |

---

## 11. Non-regression

### Services

| Service | Image | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | `v1.0.46-amazon-oauth-activation-bridge-prod` | 0 | **PROMU** |
| API PROD | `v3.5.142-promo-retry-email-prod` | 0 | **INCHANGE** |
| Client PROD | `v3.5.153-promo-visible-price-prod` | 0 | **INCHANGE** |
| Website PROD | `v0.6.9-promo-forwarding-prod` | 0 | **INCHANGE** |
| OW PROD | `v3.5.165-escalation-flow-prod` | 7 (preexist.) | **INCHANGE** |

### Donnees

| Element | Valeur | Verdict |
|---|---|---|
| ecomlg-001 Backend DB | 5 pays READY, 5 addresses | **INCHANGE** |
| SWITAA connections API DB | 2 connections READY (FR, ES/FR/BE) | **INCHANGE** |
| Billing subscriptions | 7 | **INCHANGE** |

### CronJobs

| Job | Active | Verdict |
|---|---|---|
| outbound-tick-processor | OUI | **PASS** |
| sla-evaluator | OUI | **PASS** |
| trial-lifecycle-dryrun | OUI | **PASS** |
| carrier-tracking-poll | OUI | **PASS** |
| amazon-orders-sync | OUI | **PASS** |
| amazon-reports-tracking-sync | OUI | **PASS** |

### Surfaces intouchees

| Surface | Modifie | Verification |
|---|---|---|
| Billing / Stripe | NON | 7 subs inchangees |
| Promo codes | NON | Aucune modification |
| Lifecycle emails | NON | Aucune modification |
| 17TRACK | NON | Aucune modification |
| Client tracking (GA4/sGTM/TikTok/LinkedIn/Meta) | NON | Client non rebuilt |
| Admin | NON | Non touche |
| Website | NON | Non touche |
| CAPI | NON | Aucun faux event |

---

## 12. Test utilisateur OAuth PROD

### Test /channels (EN ATTENTE)

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| Client PROD /channels → Connecter Amazon FR | URL OAuth Amazon generee | **EN ATTENTE** | PENDING |
| Callback host | `backend.keybuzz.io` | **EN ATTENTE** | PENDING |
| ensureInboundConnection | Tenant auto-cree + connection READY | **EN ATTENTE** | PENDING |
| Retour final | `client.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-fr` | **EN ATTENTE** | PENDING |
| BFF activation bridge | Backend connection → API upsert | **EN ATTENTE** | PENDING |
| Channel status | Connecte + inbound email visible | **EN ATTENTE** | PENDING |

### Test /start (EN ATTENTE)

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| Client PROD /start → Connecter Amazon | URL OAuth Amazon generee | **EN ATTENTE** | PENDING |
| Retour | `client.keybuzz.io/start?amazon_connected=true` | **EN ATTENTE** | PENDING |
| Pas de 404 backend /start | Pas de 404 | **EN ATTENTE** | PENDING |

**Note** : La connection READY et l'adresse inbound existent deja dans Backend DB PROD (creees lors du test structurel). La prochaine tentative OAuth de Ludovic devrait donc reussir de bout en bout, car le BFF bridge trouvera la connection et la transmettra a l'API pour activation.

---

## 13. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend | `d7f48fc` | PH-SAAS-T8.12AO.4: auto-provision tenant in Backend DB before inbound connection — fix FK violation for new tenants |
| keybuzz-infra | `5a58d74` | gitops(dev): AO.4 Backend v1.0.46-amazon-oauth-activation-bridge-dev |
| keybuzz-infra | `3c13d2a` | gitops(prod): AO.4 Backend v1.0.46-amazon-oauth-activation-bridge-prod |
| keybuzz-infra | (ce rapport) | docs: PH-SAAS-T8.12AO.4 rapport final |

---

## 14. Chronologie Amazon OAuth complete

| Phase | Description | Backend | Verdict |
|---|---|---|---|
| AM.3 | Delete marketplace connector | v1.0.38 | DONE |
| AM.6 | Callback reads expected_channel from returnTo | v1.0.39 | DONE |
| AM.7 | ensureInboundConnection creates with READY | v1.0.40 | DONE |
| AM.9 | Dual DB fix — GET inbound-connection route for BFF bridge | v1.0.41 | DONE |
| AM.10 | PROD promotion AM.9 | v1.0.42 | DONE |
| AO | DEV fix — env var overrides Vault redirect_uri + cross-env guard | v1.0.44 | DONE |
| AO.1 | PROD promotion AO — Backend + LEGACY_BACKEND_URL fix | v1.0.44 | DONE |
| AO.2 | DEV fix — safe returnTo redirect + CLIENT_APP_URL + open redirect guard | v1.0.45 | DONE |
| AO.3 | PROD promotion AO.2 | v1.0.45 | DONE |
| **AO.4** | **Fix FK violation — auto-provision tenant in Backend DB** | **v1.0.46** | **DEPLOYED, USER VALIDATION PENDING** |

---

## 15. Gaps restants

### 15.1 Test utilisateur OAuth PROD

La validation structurelle et le test direct `ensureInboundConnection` en PROD passent. Le test utilisateur reel avec Amazon Seller Central est recommande pour confirmer le flux E2E complet.

### 15.2 Backend DB tenant desynchronisation

Le fix corrige le symptome (auto-creation) mais la cause racine (les deux DBs ne sont pas synchronisees) subsiste. Pour chaque nouveau tenant cree via l'API, il n'existe pas dans le Backend DB tant qu'il n'a pas fait un OAuth. Le fix `ensureInboundConnection` compense ce gap.

### 15.3 Vault DOWN

Vault est toujours DOWN depuis janvier 2026. Les services utilisent les secrets K8s caches.

### 15.4 OW PROD 7 restarts

Le outbound worker PROD a 7 restarts preexistants (non lie a cette phase).

---

## VERDICT

**GO PARTIEL — USER OAUTH VALIDATION PENDING**

AMAZON OAUTH ACTIVATION BRIDGE FK VIOLATION FIX DEPLOYED — ROOT CAUSE: `bon-kb-mosf283z` ABSENT DE BACKEND DB (`keybuzz_backend`) CAUSANT FK CONSTRAINT VIOLATION SUR `inbound_connections_tenantId_fkey` — FIX: AUTO-PROVISION TENANT VIA `prisma.tenant.upsert()` DANS `ensureInboundConnection()` — BACKEND DB PROD: TENANT CREE, CONNECTION READY, ADDRESS `amazon.bon-kb-mosf283z.fr.fq7fep@inbound.keybuzz.io` — API/CLIENT UNCHANGED — ECOMLG 5 PAYS READY UNCHANGED — SWITAA 2 CONNECTIONS UNCHANGED — BILLING 7 SUBS UNCHANGED — ALL CRONJOBS ACTIVE — NO HARDCODING — GITOPS STRICT — AWAITING USER E2E OAUTH TEST TO CLOSE KEY-248

---

**Rapport :** `keybuzz-infra/docs/PH-SAAS-T8.12AO.4-AMAZON-OAUTH-ACTIVATION-BRIDGE-PROD-TRUTH-AUDIT-AND-FIX-01.md`
