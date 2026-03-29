# PH132-E: NEW TENANT AUTOPILOT BOOTSTRAP — RAPPORT

> Date : 2026-03-29
> Phase : PH132-E-NEW-TENANT-AUTOPILOT-BOOTSTRAP-TRUTH-RECOVERY-01
> Type : correction critique bootstrap nouveaux tenants
> Environnement : DEV deploye et valide | PROD en attente validation

---

## VERDICT

**NEW TENANT AUTOPILOT BOOTSTRAP RECOVERED — NO HARDCODE — SAME BEHAVIOR AS LEGACY TENANTS — ROLLBACK READY**

---

## 1. VERSIONS

| Service | DEV (avant) | DEV (apres) | PROD (inchange) |
|---------|-------------|-------------|-----------------|
| API | `v3.5.129-autopilot-trigger-fix-dev` | **`v3.5.130-bootstrap-fix-dev`** | `v3.5.129-autopilot-trigger-fix-prod` |
| Client | `v3.5.127-kba-checkout-fix-dev` | (inchange) | `v3.5.127-kba-checkout-fix-prod` |
| Backend | `v1.0.42-ph-oauth-persist-dev` | (inchange) | `v1.0.42-ph-oauth-persist-prod` |

**Rollback DEV :** `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.129-autopilot-trigger-fix-dev -n keybuzz-api-dev`

---

## 2. REPRODUCTION DU BUG

### Tenant affecte : `switaa-sasu-mnc1x4eq` (AUTOPILOT)

| Critere | Etat constate |
|---------|---------------|
| Plan | AUTOPILOT |
| Starters ai_rules | **15 disabled, 0 active** |
| autopilot_settings | is_enabled=true, mode=autonomous, safe_mode=true |
| Comportement attendu | Suggestions sur messages entrants |
| Comportement reel | Aucune suggestion (0 regles actives) |

**Bug reproduit : OUI**

### Tenant supplementaire affecte : `test-amz-truth02-1774522668158`

| Critere | Etat constate |
|---------|---------------|
| Plan | PRO |
| Starters ai_rules | **0** (aucun seed) |
| autopilot_settings | MISSING |

---

## 3. CAUSE RACINE PROUVEE

### Le seed `playbook-seed.service.ts` cree TOUT en `disabled`

**Fichier :** `src/services/playbook-seed.service.ts` (ligne 269)

```typescript
// AVANT (code bugue)
INSERT INTO ai_rules (..., mode, status, ...)
VALUES ($1, $2, $3, $4, 'suggest', 'disabled', ...)
//                                  ^^^^^^^^^^
// TOUS les 15 starters sont crees comme 'disabled'
```

### PH-PLAYBOOKS-STARTERS-ACTIVATION-03 = one-shot SQL, pas de fix code

La phase PH03 a active 8 starters via un UPDATE SQL sur les tenants existants :

```sql
UPDATE ai_rules SET status = 'active'
WHERE is_starter = true
  AND trigger_type IN ('tracking_request', 'delivery_delay', ...)
  AND status = 'disabled';
```

Ce SQL a corrige les 7 tenants existants a l'epoque, mais le code `seedStarterPlaybooks()` n'a **jamais** ete modifie. Tout nouveau tenant cree apres PH03 recoit 15 starters tous `disabled`.

### Difference anciens / nouveaux tenants

| Tenant | Cree | Starters actifs | Raison |
|--------|------|----------------|--------|
| ecomlg-001 (ancien) | Avant PH03 | 8 | PH03 SQL one-shot |
| switaa-sasu-mn9if5n2 (ancien) | Avant PH03 | 8 | PH03 SQL one-shot |
| **switaa-sasu-mnc1x4eq** (nouveau) | **Apres PH03** | **0** | **Seed bugue** |

**Aucun hardcode tenant, aucun traitement special** : la difference est purement chronologique (avant/apres le one-shot SQL).

---

## 4. FIX APPLIQUE

### Modification du seed (`playbook-seed.service.ts`)

Le INSERT utilise maintenant un CASE SQL pour determiner le statut en fonction du `trigger_type` :

```typescript
// APRES (code corrige)
INSERT INTO ai_rules (..., mode, status, ...)
VALUES ($1, $2, $3, $4, 'suggest',
  CASE WHEN $6 IN (
    'tracking_request','delivery_delay','return_request',
    'defective_product','payment_declined','invoice_request',
    'order_cancelled'
  ) THEN 'active' ELSE 'disabled' END,
  ...)
```

### Matrice appliquee (identique a PH03)

**Actifs (8)** — cas e-commerce standard, 0 KBA, mode suggest :

| # | Nom | trigger_type | min_plan |
|---|-----|-------------|----------|
| 1 | Ou est ma commande ? | tracking_request | starter |
| 2 | Suivi indisponible | tracking_request | starter |
| 3 | Retard de livraison | delivery_delay | starter |
| 4 | Demande de retour | return_request | starter |
| 5 | Produit defectueux | defective_product | starter |
| 6 | Paiement refuse | payment_declined | starter |
| 7 | Demande de facture | invoice_request | starter |
| 8 | Annulation de commande | order_cancelled | starter |

**Desactives (7)** — actions IA payantes ou triggers incomplets :

| # | Nom | trigger_type | min_plan | Raison |
|---|-----|-------------|----------|--------|
| 9 | Client agressif | negative_sentiment | pro | prefill_reply = 6 KBA |
| 10 | Mauvaise description | wrong_description | pro | trigger_ai_analysis = 14 KBA |
| 11 | Produit incompatible | incompatible_product | pro | prefill_reply = 6 KBA |
| 12 | Message hors sujet | off_topic | pro | Faux positifs |
| 13 | Client VIP | vip_client | pro | Trigger vide |
| 14 | Message sans reponse | unanswered_timeout | starter | Trigger vide |
| 15 | Escalade vers support | escalation_needed | autopilot | Action lourde |

---

## 5. BACKFILL DEV

### Tenants backfilles

| Tenant | Plan | Avant | Apres | Action |
|--------|------|-------|-------|--------|
| switaa-sasu-mnc1x4eq | AUTOPILOT | 0 active, 15 disabled | 8 active, 7 disabled | SQL UPDATE |
| test-amz-truth02-1774522668158 | PRO | 0 starters | 8 active, 7 disabled | DELETE + re-seed |

### Tenants deja corrects (non touches)

ecomlg-001, ecomlg07, ecomlg-mmiyygfg, srv-performance, switaa-mn9ioy5j, switaa-sasu-mn9if5n2, tenant-1772234265142 — tous 8 active + 7 disabled.

---

## 6. VALIDATION DEV

### Etat final tous tenants DEV

| Tenant | Plan | Active | Disabled | Status |
|--------|------|--------|----------|--------|
| ecomlg-001 | PRO | 8 | 7 | OK |
| ecomlg07-gmail-com-mn7pn69e | AUTOPILOT | 8 | 7 | OK |
| ecomlg-mmiyygfg | PRO | 8 | 7 | OK |
| srv-performance-mn7ds3oj | AUTOPILOT | 8 | 7 | OK |
| switaa-mn9ioy5j | AUTOPILOT | 8 | 7 | OK |
| switaa-sasu-mn9if5n2 | AUTOPILOT | 8 | 7 | OK |
| switaa-sasu-mnc1x4eq | AUTOPILOT | 8 | 7 | OK |
| tenant-1772234265142 | STARTER | 8 | 7 | OK |
| test-amz-truth02-1774522668158 | PRO | 8 | 7 | OK |

**9/9 tenants corrects. Distribution uniforme.**

### Autopilot evaluate

| Tenant | Plan | Resultat |
|--------|------|----------|
| switaa-sasu-mnc1x4eq | AUTOPILOT | 200 OK (CONVERSATION_NOT_FOUND — test ID factice, engine tourne) |

### Playbooks API

| Tenant | Active | Disabled | Coherent |
|--------|--------|----------|----------|
| ecomlg-001 (ancien) | 8 | 7 | OUI |
| switaa-sasu-mnc1x4eq (nouveau, backfille) | 8 | 7 | OUI |

### Non-regressions

| Endpoint | Status |
|----------|--------|
| Health | 200 OK |
| Billing | 200 OK |
| AI settings | 200 OK |
| Conversations | 200 OK |
| Autopilot settings | 200 OK |
| Playbooks | 200 OK |

### Plan guard

PRO → autonomous = 403 BLOCKED (correct)

### Seed compile

`CASE WHEN` present dans `/app/dist/services/playbook-seed.service.js` (ligne 249-250)

---

## 7. ETAT PROD (audit, PAS de modification)

| Tenant PROD | Plan | Active | Disabled | Status |
|-------------|------|--------|----------|--------|
| ecomlg-001 | PRO | 8 | 7 | OK |
| ecomlg-mn3rdmf6 | AUTOPILOT | 8 | 7 | OK |
| ecomlg-mn3roi1v | PRO | 8 | 7 | OK |
| romruais-gmail-com-mn7mc6xl | AUTOPILOT | 8 | 7 | OK |
| switaa-sasu-mn9c3eza | AUTOPILOT | 8 | 7 | OK |
| **switaa-sasu-mnc1ouqu** | **AUTOPILOT** | **0** | **15** | **NEEDS BACKFILL** |

**1 tenant PROD affecte** : `switaa-sasu-mnc1ouqu` (AUTOPILOT, 15 disabled)

---

## 8. ACTIONS PROD (en attente validation)

### 1. Build + deploy API PROD

```bash
cd /opt/keybuzz/keybuzz-api
docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-prod .
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-prod
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-prod -n keybuzz-api-prod
```

### 2. Backfill PROD (1 tenant)

```sql
UPDATE ai_rules
SET status = 'active', updated_at = NOW()
WHERE is_starter = true
  AND trigger_type IN (
    'tracking_request', 'delivery_delay', 'return_request',
    'defective_product', 'payment_declined', 'invoice_request',
    'order_cancelled'
  )
  AND status = 'disabled'
  AND tenant_id IN (
    SELECT ar2.tenant_id
    FROM ai_rules ar2
    WHERE ar2.is_starter = true
    GROUP BY ar2.tenant_id
    HAVING COUNT(*) FILTER (WHERE ar2.status = 'active') = 0
  );
```

### 3. Verifier

Health, non-regressions, distribution 8/7 pour tous tenants PROD.

---

## 9. FICHIERS MODIFIES

| Fichier | Type | Description |
|---------|------|-------------|
| `keybuzz-api/src/services/playbook-seed.service.ts` | FIX | CASE WHEN sur trigger_type: 8 active, 7 disabled |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | GITOPS | Image tag v3.5.130-bootstrap-fix-dev |

---

## 10. ROLLBACK

```bash
# API DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.129-autopilot-trigger-fix-dev -n keybuzz-api-dev

# Rollback backfill DEV (remettre disabled)
# Via pod API DEV:
# UPDATE ai_rules SET status = 'disabled', updated_at = NOW()
# WHERE is_starter = true AND trigger_type IN ('tracking_request','delivery_delay','return_request','defective_product','payment_declined','invoice_request','order_cancelled')
# AND tenant_id IN ('switaa-sasu-mnc1x4eq', 'test-amz-truth02-1774522668158');

# API PROD (si deploye)
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.129-autopilot-trigger-fix-prod -n keybuzz-api-prod
```

---

## VERDICT FINAL

```
NEW TENANT AUTOPILOT BOOTSTRAP RECOVERED — DEV DEPLOYE — PROD EN ATTENTE

Cause racine : seedStarterPlaybooks() creait 15 starters 'disabled'
Fix : CASE WHEN sur trigger_type -> 8 active, 7 disabled (durable)
Backfill DEV : 2 tenants corriges (switaa-sasu-mnc1x4eq + test-amz)
Distribution DEV : 9/9 tenants = 8 active + 7 disabled (uniforme)
PROD : 1 tenant a backfiller (switaa-sasu-mnc1ouqu)
Aucun hardcode tenant
Comportement identique anciens / nouveaux tenants
Non-regressions : tous endpoints 200 OK
Plan guard : PRO->autonomous 403 BLOCKED
Rollback : documente et pret
```
