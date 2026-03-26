# PH-AMZ-INBOUND-ADDRESS-TRUTH-02 — Rapport

> Date : 2026-03-26
> Auteur : Agent Cursor
> Phase : PH-AMZ-INBOUND-ADDRESS-TRUTH-02
> Verdict : **AMZ INBOUND ADDRESS REALLY FIXED AND VALIDATED**

---

## 1. Reproduction du bug

Le fix precedent (PH-AMZ-INBOUND-ADDRESS-TRUTH-01) etait **insuffisant**. Le product owner a reproduit le probleme sur plusieurs connecteurs/pays.

### Bugs reproduits en audit :

| Bug | Description | Preuve |
|---|---|---|
| **BUG 1** (CRITIQUE) | Multi-country crash : `ON CONFLICT ON CONSTRAINT inbound_connections_pkey` ne gere que la PK (`id`), pas le unique `("tenantId", marketplace)` | `500: duplicate key violates unique constraint "inbound_connections_tenantId_marketplace_key"` |
| **BUG 2** | Hardcoding `'FR'` dans `channels/page.tsx` : seul FR est provisionne apres OAuth | `getAmazonInboundAddress(currentTenantId, 'FR')` — code client |
| **BUG 3** | Provisioning passif : ne se declenche QUE si `checkOAuthCallback()` detecte `amazon_connected=true` | Si callback absent/refresh page, provisioning jamais execute |

### Tenants testes :
- `srv-performance-mn7ce0h7` : `pending`, `inbound_email=null`, 0 rows `inbound_connections`, 0 rows `inbound_addresses`
- `ecomlg-001` (legacy) : `active`, adresse OK — fonctionne car provisionne manuellement

---

## 2. Flow post-OAuth trace

```
1. User ajoute Amazon FR/DE/ES → tenant_channels (status=pending, inbound_email=null)
2. User clique "Connecter Amazon" → OAuth keybuzz-backend
3. OAuth callback → /channels?amazon_connected=true (PAS GARANTI)
4. channels/page.tsx verifie checkOAuthCallback()
   → SI amazon_connected=true : appelle getAmazonInboundAddress(tenantId, 'FR') ← BUG: HARDCODE FR
   → SI absent : RIEN ne se passe ← BUG: PASSIF
5. Status endpoint : lit inbound_connections — pas de provisioning si absent ← BUG: PASSIF
```

---

## 3. Absence de hardcoding dans le fix TRUTH-02

| Verification | Resultat |
|---|---|
| tenantId en dur | **NON** — `getTenantId(request)` dynamique |
| country en dur | **NON** — itere `tenant_channels WHERE provider='amazon' AND status='pending'` |
| fallback ecomlg-001 | **NON** — aucune condition speciale |
| condition "si existe deja" masquant le bug | **NON** — provisioning actif pour CHAQUE channel pending |

---

## 4. Root cause exacte

3 causes combinees :

1. **ON CONFLICT mauvaise contrainte** : `inbound_connections_pkey` (PK=id) au lieu de `("tenantId", marketplace)` (unique)
2. **Provisioning passif** : l'auto-provision n'etait PAS dans le status endpoint — dependait d'un appel explicite `getAmazonInboundAddress()` via le callback OAuth
3. **Country hardcode** : `getAmazonInboundAddress(currentTenantId, 'FR')` ignorait DE, ES, IT, etc.

---

## 5. Correction appliquee (3 fichiers)

### API `src/modules/compat/routes.ts`
- **Fix ON CONFLICT** : `ON CONFLICT ("tenantId", marketplace) DO UPDATE SET ...`
- **Auto-provision dans GET /status** : quand appele, itere TOUS les `tenant_channels` Amazon pending et :
  - Si adresse existante → sync vers `tenant_channels` (activate + set email)
  - Si aucune adresse → genere token, cree `inbound_connections` + `inbound_addresses`, active `tenant_channels`
  - Fonctionne pour TOUS les pays (FR, DE, ES, IT, NL, BE, UK)
  - Fonctionne pour TOUS les tenants (pas de hardcoding)

### Client `app/channels/page.tsx`
- **Supprime hardcode FR** : plus de `getAmazonInboundAddress(currentTenantId, 'FR')`
- **Supprime dependance OAuth callback** : `refreshProviderStatus()` → status endpoint → auto-provision
- Simple chargement de la page declenche le provisioning de tous les channels pending

### Client `src/services/amazon.service.ts`
- Import `getAmazonInboundAddress` retire des imports du channels page (plus utilise)

---

## 6. Validations DEV

| Test | Resultat | Detail |
|---|---|---|
| T1 — Fresh tenant FR seul | **PASS** | `pending → active`, adresse generee, status CONNECTED |
| T2 — Multi-country FR+DE+ES | **PASS** | 3/3 channels `active`, 3 adresses uniques, 1 connection `countries=[DE,ES,FR]` |
| T3 — Legacy ecomlg-001 | **PASS** | Inchange, `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` |
| T4 — Vrai tenant pending | **PASS** | `srv-performance-mn7ce0h7` auto-provisionne |
| T5 — Non-regression | **PASS** | Health, Agents, Conversations, Autopilot : 200 |

**Verdicts DEV :**
- AMZ NEW CONNECTOR DEV = **OK**
- AMZ MULTI-COUNTRY DEV = **OK**
- AMZ LEGACY DEV = **OK**
- AMZ DEV NO REGRESSION = **OK**

---

## 7. Validations PROD

| Test | Resultat | Detail |
|---|---|---|
| T1 — Health | **200** | OK |
| T2 — Legacy status | **200 CONNECTED** | `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` |
| T3 — Agents | **200** | OK |
| T4 — Conversations | **200** | OK |
| T5 — Autopilot | **200** | OK |
| T6 — Auth | **200** | OK |
| T7 — Billing | **200** | OK |
| T8 — AI Settings | **200** | OK |
| Pod restarts | **0** | |

**Verdicts PROD :**
- AMZ LEGACY PROD = **OK**
- AMZ PROD NO REGRESSION = **OK**

---

## 8. Images deployees

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.109-ph-amz-inbound-truth02-dev` | `v3.5.109-ph-amz-inbound-truth02-prod` |
| Client | `v3.5.109-ph-amz-inbound-truth02-dev` | `v3.5.109-ph-amz-inbound-truth02-prod` |

---

## 9. Rollback

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.108-ph-amz-inbound-address-prod -n keybuzz-api-prod
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.108-ph-amz-inbound-address-prod -n keybuzz-client-prod
```

---

## 10. Difference cle entre TRUTH-01 et TRUTH-02

| Aspect | TRUTH-01 (insuffisant) | TRUTH-02 (corrige) |
|---|---|---|
| ON CONFLICT | `inbound_connections_pkey` (PK id) | `("tenantId", marketplace)` (unique reel) |
| Multi-country | FR seul, DE crash 500 | TOUS les pays : itere `tenant_channels` |
| Provisioning | Passif (attend callback OAuth) | **Actif** (status endpoint auto-provision) |
| Hardcoding | `'FR'` hardcode dans channels page | Aucun hardcoding |
| Dependance callback | Oui (amazon_connected=true) | Non (chargement page suffit) |
