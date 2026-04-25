# PH-T8.10P — Google sGTM Webhook Owner-Aware Quick Win

> Date : 25 avril 2026
> Environnement : DEV uniquement
> Type : quick win owner-aware sur pipeline legacy sGTM/Google
> Priorite : P0
> PROD inchangee

---

## VERDICT

### GO — GOOGLE SGTM WEBHOOK OWNER-AWARE QUICK WIN READY IN DEV

Le pipeline legacy `emitConversionWebhook` (GA4 Measurement Protocol -> sGTM -> Google Ads)
est desormais owner-aware. Le tenant runtime enfant est preserve comme verite business,
l'owner KBC est visible dans le payload, et le fallback legacy sans owner reste propre.

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD avant patch | `acf5536d` |
| Image API DEV avant | `v3.5.117-tiktok-native-owner-aware-dev` |
| Image API PROD | `v3.5.117-tiktok-native-owner-aware-prod` (INCHANGEE) |
| Repo clean | Oui |
| Source confirmee | `ph147.4/source-of-truth` |
| Perimetre | DEV uniquement, API uniquement |

---

## 2. AUDIT EXACT DU PIPELINE LEGACY GOOGLE

### Avant le patch

| Sujet | Emplacement code | Comportement |
|---|---|---|
| Definition | `billing/routes.ts:1849` | Fonction locale `emitConversionWebhook(session)` |
| Appel | `billing/routes.ts:1581` | Sur `checkout.session.completed` (StartTrial) |
| tenantId source | `session.metadata?.tenant_id` | Tenant brut (enfant) |
| Attribution source | `signup_attribution WHERE tenant_id = $1` | Correct (lit l'attribution du runtime) |
| Env vars | `CONVERSION_WEBHOOK_ENABLED`, `CONVERSION_WEBHOOK_URL`, `GA4_MEASUREMENT_ID`, `GA4_MP_API_SECRET` | Toutes configurees DEV+PROD |
| Owner-aware | **NON** | Aucune resolution `marketing_owner_tenant_id` |
| Payload `tenant_id` | Tenant brut dans `params` | Pas de routing owner |
| Vs `emitOutboundConversion` | Pipeline moderne dans `emitter.ts` | Le moderne est owner-aware, le legacy ne l'etait pas |

### Risque identifie
Sur un tenant enfant owner-mappe, le sGTM recevait le tenant enfant comme seul identifiant.
L'agence KBC ne pouvait pas distinguer un lead venant d'un enfant owner-mappe d'un lead standalone.

---

## 3. DESIGN RETENU

| Point | Decision |
|---|---|
| Tenant runtime conserve | **Oui** — `params.tenant_id` reste le tenant enfant |
| Owner visible dans le payload | **Oui** — `routing_tenant_id` + `marketing_owner_tenant_id` + `owner_routed` |
| Helper de resolution | Logique inline (meme pattern que `resolveOutboundRoutingTenantId`) |
| Fallback legacy | `routing_tenant_id = tenant_id`, `owner_routed = false`, pas de champ `marketing_owner_tenant_id` |
| Compatibilite webhook/sGTM | Backward-compatible — champs additifs, rien supprime |
| `emitOutboundConversion` touche | Non |
| Schema DB | Aucun changement |

---

## 4. PATCH EXACT APPLIQUE

**Fichier** : `src/modules/billing/routes.ts`
**Commit** : `ec56782b`
**Diff** : +22 insertions, -1 deletion

### Changement 1 — Resolution owner (apres extraction tenantId)
```typescript
// PH-T8.10P: Owner-aware routing for sGTM/Google pipeline
let routingTenantId = tenantId;
let ownerTenantId: string | null = null;
let isOwnerRouted = false;
try {
  const pool = await getDbPool();
  const ownerRow = await pool.query(
    'SELECT marketing_owner_tenant_id FROM tenants WHERE id = $1',
    [tenantId]
  );
  ownerTenantId = ownerRow.rows[0]?.marketing_owner_tenant_id || null;
  if (ownerTenantId) {
    routingTenantId = ownerTenantId;
    isOwnerRouted = true;
    console.log(`[Conversion] Owner-aware sGTM routing: runtime=${tenantId} -> owner=${ownerTenantId}`);
  }
} catch { /* non-blocking */ }
```

### Changement 2 — Champs owner dans params GA4 MP
```typescript
routing_tenant_id: routingTenantId,
...(ownerTenantId ? { marketing_owner_tenant_id: ownerTenantId } : {}),
owner_routed: isOwnerRouted,
```

### Changement 3 — Log enrichi
```typescript
console.log(`[Conversion] GA4 MP sent to ${webhookUrl}: ${res.status} client_id=${clientId}${isOwnerRouted ? ` owner=${ownerTenantId}` : ''}`);
```

---

## 5. VALIDATION DEV

### Cas A — Owner-mappe (proof-owner-valid-t8-mocqwjk7)

| Attendu | Resultat |
|---|---|
| Owner-aware routing | **OK** — `runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d` |
| tenant_id (runtime) preserve | **OK** — `proof-owner-valid-t8-mocqwjk7` |
| routing_tenant_id = owner | **OK** — `keybuzz-consulting-mo9y479d` |
| marketing_owner_tenant_id present | **OK** — `keybuzz-consulting-mo9y479d` |
| owner_routed = true | **OK** |
| gclid present | **OK** — `test_gclid_t810p_001` |
| sGTM HTTP response | **OK** — HTTP 200 |

### Cas B — Legacy sans owner (proof-no-owner-t810b-mocqwkvo)

| Attendu | Resultat |
|---|---|
| Pas d'owner | **OK** — `marketing_owner_tenant_id: null` |
| routing_tenant_id = tenant_id | **OK** — `proof-no-owner-t810b-mocqwkvo` |
| owner_routed = false | **OK** |
| Pas de champ marketing_owner_tenant_id | **OK** — absent du payload |
| Pas de crash | **OK** |

### Cas C — Non-regression pipeline moderne

| Attendu | Resultat |
|---|---|
| emitOutboundConversion importable | **OK** — `function` |
| Owner-aware routing | **OK** — `runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d` |
| Destinations KBC DEV | Aucune active — `skipping StartTrial` (attendu) |

---

## 6. PREUVES PAYLOAD

### Payload owner-aware (Cas A) envoye au sGTM

```json
{
  "client_id": "test-proof-owner-valid-t8-mocqwjk7",
  "non_personalized_ads": false,
  "events": [{
    "name": "purchase",
    "params": {
      "value": 297,
      "currency": "EUR",
      "transaction_id": "test_t810p_owner_aware_1777118131492",
      "tenant_id": "proof-owner-valid-t8-mocqwjk7",
      "routing_tenant_id": "keybuzz-consulting-mo9y479d",
      "marketing_owner_tenant_id": "keybuzz-consulting-mo9y479d",
      "owner_routed": true,
      "plan": "PRO",
      "cycle": "monthly",
      "utm_source": "google",
      "utm_medium": "cpc",
      "gclid": "test_gclid_t810p_001"
    }
  }]
}
```

Reponse sGTM : **HTTP 200**

### Payload legacy sans owner (Cas B)

```json
{
  "tenant_id": "proof-no-owner-t810b-mocqwkvo",
  "routing_tenant_id": "proof-no-owner-t810b-mocqwkvo",
  "owner_routed": false,
  "plan": "starter",
  "cycle": "monthly",
  "utm_source": "google",
  "gclid": "test_gclid_no_owner_001"
}
```

Pas de champ `marketing_owner_tenant_id` — fallback propre.

---

## 7. VALIDATION ADDINGWELL

Validation Addingwell non necessaire dans cette phase :
1. sGTM a repondu HTTP 200 au payload owner-aware
2. Les champs ajoutes sont dans `params` du GA4 MP — arrivent comme custom parameters
3. Les tags Google Ads, GA4, Meta CAPI lisent les params dynamiquement — pas de modification sGTM requise
4. Aucune modification Addingwell autorisee dans cette phase

---

## 8. NON-REGRESSION

| Surface | Attendu | Resultat |
|---|---|---|
| Meta/TikTok owner-aware (emitOutboundConversion) | Intact | **OK** |
| Owner-scoped metrics | HTTP 200 | **OK** |
| Owner-scoped funnel | HTTP 200 | **OK** |
| Health check DEV | OK | **OK** |
| DEV Client | Inchange | **OK** — v3.5.112 |
| DEV Admin | Inchange | **OK** — v2.11.15 |
| PROD API | Inchangee | **OK** — v3.5.117 |
| PROD Client | Inchange | **OK** — v3.5.116 |
| PROD Admin | Inchange | **OK** — v2.11.15 |

---

## 9. IMAGE DEV

| Element | Valeur |
|---|---|
| Tag | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` |
| Commit API | `ec56782b` |
| Digest | `sha256:b4858eebdc46e547d4edea106f70139b971dd6733da5800c3b0eccc7e0731dd2` |
| Manifest DEV | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Rollback DEV | `v3.5.117-tiktok-native-owner-aware-dev` |

---

## 10. GAPS RESTANTS (documentes, non corriges)

| # | Gap | Impact | Phase suivante suggeree |
|---|---|---|---|
| G1 | Pas de destination native `google_ads` first-class | google_ads tombe dans fallback webhook dans emitOutboundConversion | PH-T8.10Q |
| G2 | Google non visible dans l'UI Destinations Admin | DestinationType = webhook / meta_capi / tiktok_events seulement | PH-T8.10Q |
| G3 | Ads Accounts Google = "Bientot" | Ad accounts Admin supporte Meta uniquement | Future phase |
| G4 | GA4 browser PROD inactif | `NEXT_PUBLIC_GA4_MEASUREMENT_ID` non injecte au build PROD client | Rebuild client avec build-arg |
| G5 | Integration Guide desynchronisee | TikTok outbound = "Non natif" alors qu'il est now natif | Mise a jour doc |

---

## 11. PROD INCHANGEE

| Element | Modifie ? |
|---|---|
| keybuzz-api PROD | Non — v3.5.117 |
| keybuzz-client PROD | Non — v3.5.116 |
| keybuzz-admin-v2 PROD | Non — v2.11.15 |
| DB PROD | Non |
| sGTM / Addingwell | Non |
| K8s PROD deployments | Non |

---

## 12. RESUME

```
PH-T8.10P-GOOGLE-SGTM-WEBHOOK-OWNER-AWARE-QUICK-WIN-01 — TERMINE
Verdict : GO

Preflight
  API : ph147.4/source-of-truth @ acf5536d (clean)
  Image DEV avant : v3.5.117-tiktok-native-owner-aware-dev

Audit
  emitConversionWebhook : non owner-aware (tenant brut de Stripe metadata)
  emitOutboundConversion : owner-aware (reference)

Design
  Ajout resolution owner inline dans emitConversionWebhook
  Champs additifs : routing_tenant_id, marketing_owner_tenant_id, owner_routed
  Backward-compatible, fallback legacy propre

Patch
  Commit : ec56782b (+22 insertions, -1 deletion)
  Fichier : src/modules/billing/routes.ts

Validation DEV
  Cas A owner-mappe : sGTM HTTP 200, owner=keybuzz-consulting-mo9y479d, runtime preserve
  Cas B legacy sans owner : fallback propre, owner_routed=false
  Cas C non-regression : emitOutboundConversion intact

Preuves
  Payload GA4 MP avec routing_tenant_id + owner_routed envoye et accepte par sGTM
  gclid present et fonctionnel

Addingwell
  Non necessaire — HTTP 200 confirme, champs additifs compatibles

Non-regression
  Meta/TikTok intact, metrics/funnel intact, Client/Admin inchanges, PROD intacte

Image DEV
  v3.5.118-google-sgtm-owner-aware-quick-win-dev
  Digest : sha256:b4858eebdc46e547d4edea106f70139b971dd6733da5800c3b0eccc7e0731dd2
  Rollback : v3.5.117-tiktok-native-owner-aware-dev

Gaps restants
  G1: pas de destination native google_ads
  G2: Google absent UI Destinations Admin
  G3: Ads Accounts Google = "Bientot"
  G4: GA4 browser PROD inactif
  G5: Integration Guide desynchronisee

PROD inchangee
  OUI
```

Rapport : `keybuzz-infra/docs/PH-T8.10P-GOOGLE-SGTM-WEBHOOK-OWNER-AWARE-QUICK-WIN-01.md`

---

GOOGLE SGTM WEBHOOK OWNER-AWARE QUICK WIN READY IN DEV — KBC OWNER TRUTH NOW FLOWS THROUGH LEGACY GOOGLE PIPELINE — META/TIKTOK PRESERVED — PROD UNTOUCHED

**STOP**
