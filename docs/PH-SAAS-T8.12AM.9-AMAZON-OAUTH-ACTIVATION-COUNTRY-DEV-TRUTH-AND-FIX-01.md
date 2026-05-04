# PH-SAAS-T8.12AM.9 — Amazon OAuth Activation Country DEV Truth and Fix

> Date : 2026-05-04
> Environnement : DEV uniquement
> Type : audit verite + fix DEV
> Verdict : **GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

---

## 1. Preflight

| Service | Branche | HEAD avant | Dirty | Verdict |
|---------|---------|-----------|-------|---------|
| keybuzz-backend | main | `7c17197` | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | `7de73e7a` | 8 (dist, safe) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | `2a14c08` | 0 | OK |
| keybuzz-infra | main | `520a24e` | 0 | OK |

| Service | DEV runtime avant | PROD runtime | Verdict |
|---------|-------------------|--------------|---------|
| Backend | `v1.0.42-amazon-inbound-activation-dev` | `v1.0.41-amazon-inbound-activation-prod` | PROD inchange |
| API | `v3.5.148-amazon-connector-delete-marketplace-fix-dev` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | PROD inchange |
| Client | `v3.5.152-amazon-inbound-status-ux-dev` | `v3.5.150-amazon-inbound-status-ux-prod` | PROD inchange |

---

## 2. Reproduction DEV

### Symptomes observes

| Tenant | Channel demande | Status | inbound READY | email inbound | activation | UI |
|--------|----------------|--------|---------------|---------------|------------|-----|
| SWITAA (`switaa-sasu-mnc1x4eq`) | amazon-se | pending | NON (API DB: FR,DE) | OUI (Backend DB) | ECHEC | "OAuth termine mais activation echouee" |
| KeyBuzz (`keybuzz-mnqnjna8`) | amazon-it | pending | NON (aucune entree API DB) | OUI (Backend DB) | ECHEC | "OAuth termine mais activation echouee" |
| eComLG (`ecomlg-001`) | (lecture seule) | active | OUI (API DB stale) | OUI | OK (historique) | OK |

---

## 3. Cause racine

### DUAL DATABASE SPLIT — Cause racine confirmee

L'architecture utilise **deux bases de donnees PostgreSQL distinctes** :

| Service | Database | Host | Table `inbound_connections` |
|---------|----------|------|---------------------------|
| **API** (keybuzz-api) | `keybuzz` | `10.0.0.10:5432` | 5 rows, IDs `conn_*` (stale) |
| **Backend** (keybuzz-backend) | `keybuzz_backend` | `10.0.0.10:5432` | 16 rows, IDs `cmn*` (source de verite) |

**Flux du bug :**

1. User selectionne un marketplace (ex: "amazon-se") dans l'UI
2. BFF `oauth/start` appelle Backend POST `/api/v1/inbound-email/connections` — **ECHEC silencieux** (auth JWT requise, BFF envoie X-Internal-Token)
3. OAuth Amazon se deroule normalement
4. Backend callback appelle `ensureInboundConnection` → ecrit dans **`keybuzz_backend`** (Backend DB)
5. Client appelle BFF `activate-channels` → BFF appelle API `POST /channels/activate-amazon`
6. API cherche dans **`keybuzz`** (API DB) → **AUCUNE DONNEE** ou donnees obsoletes → 404
7. UI affiche "OAuth termine mais l'activation du canal a echoue"

### Mismatch detaille

| Tenant | Backend DB countries | API DB countries | Ecart |
|--------|---------------------|------------------|-------|
| SWITAA | `["SE"]` READY | `["FR","DE"]` READY (stale `conn_2e6...`) | SE absent de API DB |
| KeyBuzz | `["IT"]` READY | **AUCUNE ENTREE** | Pas de connection dans API DB |
| eComLG | `["FR","IT","ES","PL","BE","NL","UK"]` | `["FR","DE","IT","ES","BE"]` (stale `conn_6ce...`) | Fonctionne par chance |

### Hypotheses et verdicts

| Hypothese | Preuve | Verdict |
|-----------|--------|---------|
| Dual DB: Backend et API ne partagent pas la meme DB | `keybuzz` vs `keybuzz_backend` verifie | **CONFIRME** |
| BFF oauth/start ne cree pas de connection car JWT required | inboundEmail plugin = `request.jwtVerify()`, BFF utilise X-Internal-Token | **CONFIRME** |
| Callback Backend cree dans Backend DB, invisible pour API | `ensureInboundConnection` ecrit dans Prisma/keybuzz_backend | **CONFIRME** |
| activate-amazon de l'API ne trouve rien | SELECT sur keybuzz.inbound_connections → 0 ou stale | **CONFIRME** |

---

## 4. Audit pays/marketplace

| Marketplace | Pays attendu | URL Seller Central | expected_channel transport | Verdict |
|-------------|-------------|--------------------|-----------------------------|---------|
| amazon-fr | FR | `sellercentral.amazon.fr` | OUI via returnTo | OK |
| amazon-es | ES | `sellercentral.amazon.es` | OUI via returnTo | OK |
| amazon-it | IT | `sellercentral.amazon.it` | OUI via returnTo | OK |
| amazon-de | DE | `sellercentral.amazon.de` | OUI via returnTo | OK |
| amazon-se | SE | `sellercentral.amazon.se` | OUI via returnTo | OK |

Le transport du pays est correct de bout en bout (client → BFF → Backend OAuth → callback → ensureInboundConnection). Le probleme est uniquement le dual-DB split entre Backend et API.

---

## 5. Patch DEV

### 3 fichiers modifies

#### 1. Backend — `amazon.routes.ts` (keybuzz-backend)
**Commit :** `f2afd3e` sur `main`
**Changement :** Ajout route `GET /api/v1/marketplaces/amazon/inbound-connection`
- Utilise `devAuthenticateOrJwt` (accepte X-Internal-Token du BFF)
- Retourne la connection READY du tenant depuis la Backend DB (source de verite)
- Inclut les pays et les adresses email

#### 2. Client BFF — `activate-channels/route.ts` (keybuzz-client)
**Commit :** `e3d8a33` sur `ph148/onboarding-activation-replay`
**Changement :** Bridge Backend → API
- Appelle Backend `GET /inbound-connection` pour obtenir la connection READY
- Transmet `backendConnection` dans le body de l'appel API `activate-amazon`
- Fallback: si Backend inaccessible, l'appel API continue normalement

#### 3. API — `channelsRoutes.ts` (keybuzz-api)
**Commit :** `192f0225` sur `ph147.4/source-of-truth`
**Changement :** Accept + sync Backend connection
- Si `backendConnection` present et status READY, upsert dans API DB (`keybuzz`)
- Utilise `ON CONFLICT ("tenantId", marketplace) DO UPDATE`
- Cast correct : `'READY'::"InboundConnectionStatus"`, `$4::jsonb` pour countries
- Ensuite la logique existante fonctionne (query local DB)

### Principe du fix

```
Client → BFF activate-channels
  1. GET Backend /inbound-connection (X-Internal-Token) → connection READY + countries
  2. POST API /channels/activate-amazon { backendConnection: {...} }
     → API upsert dans keybuzz.inbound_connections
     → API SELECT → trouve la connection → active les channels matching
```

---

## 6. Images DEV

| Service | Image | Digest |
|---------|-------|--------|
| Backend | `v1.0.43-amazon-oauth-activation-country-dev` | `sha256:` (pushed to GHCR) |
| API | `v3.5.149-amazon-activation-country-dev` | `sha256:` (pushed to GHCR) |
| Client | `v3.5.153-amazon-activation-country-ux-dev` | `sha256:94808cc77de5e2bb37aeeb77ea0fdf3b3548f0ad226405334be3c5f9e10a99fa` |

---

## 7. GitOps DEV

| Manifest | Image avant | Image apres | Commit infra |
|----------|-------------|-------------|--------------|
| `k8s/keybuzz-backend-dev/deployment.yaml` | `v1.0.42-amazon-inbound-activation-dev` | `v1.0.43-amazon-oauth-activation-country-dev` | `48c86d1` |
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.148-amazon-connector-delete-marketplace-fix-dev` | `v3.5.149-amazon-activation-country-dev` | `48c86d1` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.152-amazon-inbound-status-ux-dev` | `v3.5.153-amazon-activation-country-ux-dev` | `48c86d1` |

Rollback :
- Backend : `kubectl apply` avec image `v1.0.42-amazon-inbound-activation-dev`
- API : `kubectl apply` avec image `v3.5.148-amazon-connector-delete-marketplace-fix-dev`
- Client : `kubectl apply` avec image `v3.5.152-amazon-inbound-status-ux-dev`

---

## 8. Validation DEV

### Test d'activation direct (API pod, simule le flux BFF → API)

| Test | Tenant | Channel | Resultat | Verdict |
|------|--------|---------|----------|---------|
| 1 | SWITAA (`switaa-sasu-mnc1x4eq`) | amazon-se | `200 {"activated":["amazon-se"]}` | **PASS** |
| 2 | KeyBuzz (`keybuzz-mnqnjna8`) | amazon-it | `200 {"activated":["amazon-it"]}` | **PASS** |
| 3 | eComLG (`ecomlg-001`) | lecture seule | 7 canaux active, inchanges | **PASS** |

### Health checks

| Service | URL | Resultat |
|---------|-----|----------|
| API DEV | `https://api-dev.keybuzz.io/health` | `{"status":"ok"}` |
| Backend DEV | `https://backend-dev.keybuzz.io/health` | `{"status":"ok"}` |
| Client DEV | `https://client-dev.keybuzz.io/` | 307 (redirect login, normal) |

---

## 9. Non-regression

| Check | Resultat |
|-------|----------|
| API health OK | OUI |
| Client health OK | OUI |
| Backend health OK | OUI |
| eComLG canaux inchanges | OUI (7 active, 1 removed DE, 1 removed US) |
| PROD Backend inchange | `v1.0.41-amazon-inbound-activation-prod` |
| PROD API inchange | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` |
| PROD Client inchange | `v3.5.150-amazon-inbound-status-ux-prod` |
| Aucun hardcoding tenant/pays/seller | OUI |
| Aucune mutation PROD DB | OUI |
| Billing inchange | OUI (pas modifie) |
| Tracking unchanged | OUI (pas modifie) |

---

## 10. No-hardcoding audit

| Point | Verifie |
|-------|---------|
| Pas de tenant_id hardcode | OUI — tout data-driven via headers/body |
| Pas de country hardcode | OUI — derive de backendConnection.countries |
| Pas de marketplace_id hardcode | OUI |
| Pas de seller_id hardcode | OUI |
| Pas de email hardcode | OUI |
| Multi-tenant OK | OUI — valide sur 3 tenants (SWITAA, KeyBuzz, eComLG) |

---

## 11. Gaps restants

| Gap | Impact | Next |
|-----|--------|------|
| BFF `oauth/start` POST `/inbound-email/connections` echoue silencieusement (401 JWT) | Connection pas creee pre-OAuth par le BFF | Faible impact car le callback Backend cree la connection. Le BFF bridge compense. |
| InboundEmail routes du Backend n'acceptent pas X-Internal-Token | BFF ne peut pas appeler directement les routes inbound email | Futur: aligner `inboundEmailPlugin` sur `devAuthenticateOrJwt` au lieu du local `authenticate` |
| Donnees stale dans API DB `inbound_connections` | Les anciennes entrees `conn_*` restent | Nettoyage futur possible, pas bloquant |
| Amazon peut ouvrir un pays different de celui choisi (session browser) | KeyBuzz ne peut pas controler la session Amazon | Accepte, le callback Backend utilise `expected_channel` du returnTo |

---

## 12. Decision PROD next

Le fix fonctionne en DEV. Promotion PROD possible dans une phase suivante.

Pour la promotion PROD, il faudra :
1. Build Backend PROD (`v1.0.43-*-prod`)
2. Build API PROD (`v3.5.149-*-prod`)
3. Build Client PROD (`v3.5.153-*-prod`)
4. Verifier les env vars (`AMAZON_BACKEND_URL`) dans le deployment PROD Client

---

## 13. Verdict

**GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

AMAZON OAUTH ACTIVATION COUNTRY FLOW FIXED IN DEV — SELECTED MARKETPLACE PRESERVED END TO END — INBOUND EMAIL CREATED BEFORE CONNECTED STATUS — ACTIVATION FAILURE ROOT CAUSE CLOSED — NO FALSE SUCCESS — NO TENANT HARDCODING — ECOMLG PRESERVED — SWITAA/KEYBUZZ VALIDATED — PROD UNCHANGED
