# PH-AMZ-MULTI-COUNTRY-CONNECTOR-TRUTH-03 — Rapport

> Date : 2026-03-26
> Auteur : Agent Cursor
> Phase : PH-AMZ-MULTI-COUNTRY-CONNECTOR-TRUTH-03
> Verdict : **AMZ MULTI-COUNTRY FIXED AND VALIDATED**

---

## 1. Reproduction du bug

Le bug est reproduit exactement :

```
Step 1: Tenant a uniquement Amazon FR → appel GET /status → FR provisionne → active ✅
Step 2: Tenant ajoute Amazon ES → appel GET /status → ES reste PENDING ❌
Step 3: Tenant ajoute Amazon IT → appel GET /status → IT reste PENDING ❌
```

Le premier connecteur fonctionne, les suivants restent bloques en "En attente".

---

## 2. Root cause

Le status endpoint (TRUTH-02) avait la structure :

```
1. Query inbound_connections WHERE tenantId AND marketplace='amazon'
2. IF found AND status=READY:
     → sync first address to tenant_channels
     → return CONNECTED  ← RETURN PREMATURE
3. IF NOT found:
     → auto-provision ALL pending channels  ← JAMAIS ATTEINT si FR existe deja
4. return DISCONNECTED
```

**Le `return` a l'etape 2 empeche l'etape 3 de s'executer.** Quand FR est deja provisionne, le endpoint retourne immediatement CONNECTED sans jamais regarder les channels ES/IT pending.

---

## 3. Verification contraintes DB

```
inbound_connections:
  PK: id (text)
  UNIQUE: ("tenantId", marketplace) ← 1 seule row par tenant+marketplace
  FK: "tenantId" → tenants(id)

inbound_addresses:
  PK: id (text)
  UNIQUE: ("tenantId", marketplace, country) ← 1 row par tenant+marketplace+country
  FK: "connectionId" → inbound_connections(id)
  FK: "tenantId" → tenants(id)
```

Le champ `marketplace` vaut toujours `'amazon'` — il n'est PAS differencie par pays. Les pays sont geres par :
- `inbound_addresses.country` (FR, ES, IT, etc.)
- `inbound_connections.countries` (JSONB array)

---

## 4. Verification hardcoding

| Verification | Resultat |
|---|---|
| tenantId en dur | **NON** |
| country en dur | **NON** — itere `tenant_channels WHERE provider='amazon' AND status='pending'` |
| marketplace en dur | **NON** — toujours `'amazon'` (correct par design) |
| condition speciale ancien compte | **NON** |

---

## 5. Correction appliquee (1 fichier)

### API `src/modules/compat/routes.ts`

Restructuration du `GET /api/v1/marketplaces/amazon/status` :

**Avant (TRUTH-02) :**
```
1. Query inbound_connections
2. IF READY → sync FIRST address → RETURN CONNECTED  ← bug: skip pending channels
3. Query pending channels → auto-provision → return CONNECTED
4. return DISCONNECTED
```

**Apres (TRUTH-03) :**
```
1. Query ALL pending Amazon channels
2. For EACH pending channel:
   - IF address exists → sync to tenant_channels
   - ELSE → provision new address + connection + activate
3. Query final inbound_connections state
4. IF READY → return CONNECTED (with all countries)
5. return DISCONNECTED
```

L'auto-provision tourne **TOUJOURS** en premier, **avant** de verifier l'etat. Plus de return premature.

---

## 6. Validations DEV

| Test | Resultat | Detail |
|---|---|---|
| T1 — Sequential FR→ES→IT | **PASS** | 3/3 active, 3 adresses, connection `[FR,ES,IT]` |
| T2 — Batch 6 pays (FR,DE,ES,IT,NL,BE) | **PASS** | 6/6 active, 6 adresses, connection `[BE,DE,ES,FR,IT,NL]` |
| T3 — Legacy ecomlg-001 | **PASS** | Inchange |
| T4 — Non-regression (Health/Agents/Conv/Autopilot) | **PASS** | Tous 200 |

---

## 7. Validations PROD

| Test | Resultat |
|---|---|
| Health | 200 |
| AMZ Status | 200, CONNECTED, `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` |
| Agents | 200 |
| Conversations | 200 |
| Autopilot | 200 |
| Auth | 200 |
| Billing | 200 |
| AI | 200 |
| Pod restarts | 0 |

**Verdicts PROD :**
- AMZ LEGACY PROD = **OK**
- AMZ PROD NO REGRESSION = **OK**

---

## 8. Images deployees

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.110-ph-amz-multi-country-dev` | `v3.5.110-ph-amz-multi-country-prod` |
| Client | `v3.5.109-ph-amz-inbound-truth02-dev` (inchange) | `v3.5.109-ph-amz-inbound-truth02-prod` (inchange) |

Note : seule l'API a ete modifiee. Le client n'a pas change.

---

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.109-ph-amz-inbound-truth02-prod -n keybuzz-api-prod
```

---

## 10. Evolution des fix TRUTH-01 → TRUTH-02 → TRUTH-03

| Phase | Bug corrige | Limite restante |
|---|---|---|
| TRUTH-01 | Provisioning local (plus de proxy backend) | Hardcode FR, passif, ON CONFLICT mauvais |
| TRUTH-02 | ON CONFLICT corrige, auto-provision actif, suppression hardcode FR | Return premature dans status si connexion existante |
| TRUTH-03 | Auto-provision tourne TOUJOURS avant le return | Aucune connue |
