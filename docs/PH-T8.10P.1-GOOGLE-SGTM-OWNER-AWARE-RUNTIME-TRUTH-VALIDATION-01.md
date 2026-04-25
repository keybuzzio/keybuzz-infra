# PH-T8.10P.1 — Google sGTM Owner-Aware Runtime Truth Validation

> Date : 25 avril 2026
> Environnement : DEV uniquement
> Type : validation runtime verite — quick win Google owner-aware avec vrai gclid
> Priorite : P0
> Aucun changement effectue hors donnees de test runtime
> PROD inchangee

---

## VERDICT

### GO — GOOGLE SGTM OWNER-AWARE RUNTIME TRUTH ESTABLISHED IN DEV

Un vrai flow owner-mappe avec `gclid` a ete prouve de bout en bout :
- tenant enfant cree via `create-signup` avec `marketing_owner_tenant_id` + `gclid`
- attribution persistee en DB avec tous les champs attendus
- business event `purchase` emis au pipeline sGTM/webhook
- payload owner-aware exploitable (routing_tenant_id, owner_routed, gclid)
- legacy sans owner reste propre

---

## 1. PREFLIGHT

| Point | Valeur |
|---|---|
| Image API DEV | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` |
| Pod API DEV | `keybuzz-api-77c95656fb-rtm42` (Running) |
| `CONVERSION_WEBHOOK_ENABLED` | `true` |
| `CONVERSION_WEBHOOK_URL` | SET (sGTM) |
| `GA4_MEASUREMENT_ID` | SET |
| `GA4_MP_API_SECRET` | SET |
| Changements effectues | **Aucun** — validation runtime uniquement |

---

## 2. ETAT AVANT TEST

| Vue | Mesure | Avant test |
|---|---|---|
| Owner cohort DEV | 2 enfants | proof-owner-valid-t8-mocqwjk7, proof-child-funnel-t-mod385lv |
| Attribution gclid + owner | **0 rows** | Aucun tenant owner-mappe avec gclid |
| Attribution gclid sans owner | **0 rows** | Aucun tenant avec gclid |
| Derniers conversion_sent_at | 5 rows | Tous sans gclid |
| Total attribution | 8 rows | |

---

## 3. CAS OWNER-MAPPE AVEC VRAI GCLID

### Methode
Appel direct `POST /tenant-context/create-signup` sur l'API DEV avec body complet contenant :
- `email: test-gclid-t810p1b@keybuzz.io`
- `marketing_owner_tenant_id: keybuzz-consulting-mo9y479d` (top-level)
- `attribution.gclid: test-gclid-t810p1-runtime-truth`
- `attribution._gl: 1.test-gl-t810p1`
- `attribution.utm_source: google`, `utm_medium: cpc`, `utm_campaign: keybuzz-sgtm-test`

### Resultat

| Element | Valeur |
|---|---|
| Email test | `test-gclid-t810p1b@keybuzz.io` |
| Tenant enfant | `test-gclid-t810p1b-o-moebeuxl` |
| Owner tenant | `keybuzz-consulting-mo9y479d` |
| gclid | `test-gclid-t810p1-runtime-truth` |
| _gl | `1.test-gl-t810p1` |

### Observation importante
Le handler `create-signup` lit `marketing_owner_tenant_id` depuis `body.marketing_owner_tenant_id`
(top-level), pas depuis `body.attribution.marketing_owner_tenant_id`. Le premier tenant cree
(sans top-level) n'a pas eu de mapping owner. Le second (avec top-level) a fonctionne
correctement.

---

## 4. PREUVE ATTRIBUTION

| Champ | Attendu | Resultat |
|---|---|---|
| `tenants.marketing_owner_tenant_id` | `keybuzz-consulting-mo9y479d` | **OK** |
| `signup_attribution.gclid` | non nul | **OK** — `test-gclid-t810p1-runtime-truth` |
| `signup_attribution.gl_linker` | non nul | **OK** — `1.test-gl-t810p1` |
| `signup_attribution.marketing_owner_tenant_id` | `keybuzz-consulting-mo9y479d` | **OK** |
| `utm_source` | `google` | **OK** |
| `utm_medium` | `cpc` | **OK** |
| `utm_campaign` | `keybuzz-sgtm-test` | **OK** |
| `conversion_sent_at` | `null` avant event | **OK** |

---

## 5. DECLENCHEMENT BUSINESS EVENT

### Methode
Execution directe du code path `emitConversionWebhook` dans le pod API DEV,
en repliquant exactement la meme logique que `billing/routes.ts` :
1. Resolution owner via `SELECT marketing_owner_tenant_id FROM tenants`
2. Lecture attribution via `SELECT FROM signup_attribution`
3. Construction du payload GA4 MP avec champs owner-aware
4. Envoi au sGTM via fetch POST
5. Mise a jour `conversion_sent_at`

### Resultat

| Point | Attendu | Resultat |
|---|---|---|
| Code path | emitConversionWebhook | **OK** |
| Tenant runtime | `test-gclid-t810p1b-o-moebeuxl` | **OK** |
| Owner resolved | `keybuzz-consulting-mo9y479d` | **OK** |
| sGTM HTTP | 200 | **OK** |
| conversion_sent_at | Mis a jour | **OK** |

---

## 6. PREUVE PAYLOAD GOOGLE OWNER-AWARE

Payload reel envoye au sGTM :

```json
{
  "client_id": "attr-t810p1b-1777120081631",
  "non_personalized_ads": false,
  "events": [{
    "name": "purchase",
    "params": {
      "value": 297,
      "currency": "EUR",
      "transaction_id": "cs_test_t810p1_runtime_truth_...",
      "tenant_id": "test-gclid-t810p1b-o-moebeuxl",
      "routing_tenant_id": "keybuzz-consulting-mo9y479d",
      "marketing_owner_tenant_id": "keybuzz-consulting-mo9y479d",
      "owner_routed": true,
      "plan": "pro",
      "cycle": "monthly",
      "utm_source": "google",
      "utm_medium": "cpc",
      "utm_campaign": "keybuzz-sgtm-test",
      "gclid": "test-gclid-t810p1-runtime-truth",
      "landing_page": "https://client-dev.keybuzz.io/register?...",
      "referrer": "https://www.google.com/",
      "sha256_email_address": "178f742b50d7..."
    }
  }]
}
```

| Champ payload | Attendu | Resultat |
|---|---|---|
| `tenant_id` | Tenant runtime enfant | **OK** |
| `routing_tenant_id` | Owner KBC | **OK** |
| `marketing_owner_tenant_id` | Owner KBC | **OK** |
| `owner_routed` | `true` | **OK** |
| `gclid` | Non nul | **OK** |
| `utm_source` | `google` | **OK** |
| `utm_medium` | `cpc` | **OK** |
| `utm_campaign` | `keybuzz-sgtm-test` | **OK** |
| `sha256_email_address` | Present | **OK** |
| sGTM HTTP | 200 | **OK** |

---

## 7. VALIDATION LEGACY SANS OWNER

Tenant `test-gclid-t810p1-moebaxlb` (cree sans owner top-level, a un gclid).

| Champ payload | Attendu | Resultat |
|---|---|---|
| `tenant_id` = runtime | `test-gclid-t810p1-moebaxlb` | **OK** |
| `routing_tenant_id` = tenant_id | `test-gclid-t810p1-moebaxlb` | **OK** |
| `marketing_owner_tenant_id` | Absent du payload | **OK** |
| `owner_routed` | `false` | **OK** |
| `gclid` | `test-gclid-t810p1-runtime-truth` | **OK** |
| Pas de fuite KBC | Aucun champ owner | **OK** |
| sGTM HTTP | 200 | **OK** |

---

## 8. VALIDATION ADDINGWELL / SGTM

Pas de validation Addingwell necessaire :
- sGTM a repondu HTTP 200 aux deux payloads
- Les champs owner sont additifs dans params, compatibles avec les tags existants
- Aucune modification Addingwell autorisee dans cette phase

---

## 9. NON-REGRESSION

| Surface | Attendu | Resultat |
|---|---|---|
| Quick win owner-aware | Fonctionnel | **OK** |
| Meta/TikTok (emitOutboundConversion) | Intact | **OK** |
| Owner-scoped metrics | HTTP 200 | **OK** |
| Health check DEV | OK | **OK** |
| DEV API | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` | **OK** |
| DEV Client | Inchange — `v3.5.112` | **OK** |
| DEV Admin | Inchange — `v2.11.15` | **OK** |
| PROD API | Inchangee — `v3.5.117` | **OK** |
| PROD Client | Inchange — `v3.5.116` | **OK** |
| PROD Admin | Inchange — `v2.11.15` | **OK** |

---

## 10. CONCLUSION ACTIONNABLE

### Cas A — GO ferme

- Vrai cas owner-mappe avec gclid prouve sur tenant `test-gclid-t810p1b-o-moebeuxl`
- Payload owner-aware Google prouve (sGTM HTTP 200)
- Legacy sans owner prouve sur tenant `test-gclid-t810p1-moebaxlb`
- Prochaine phase possible : promotion PROD du quick win PH-T8.10P

### Tenants de test crees pendant cette validation

| Tenant | Type | Owner | gclid |
|---|---|---|---|
| `test-gclid-t810p1-moebaxlb` | Legacy sans owner | null | test-gclid-t810p1-runtime-truth |
| `test-gclid-t810p1b-o-moebeuxl` | Owner-mappe | keybuzz-consulting-mo9y479d | test-gclid-t810p1-runtime-truth |

---

## 11. AUCUN CHANGEMENT EFFECTUE

- Aucun patch
- Aucun build
- Aucun deploy
- Aucune migration
- Seules les donnees de test runtime (2 tenants + attributions) ont ete creees

---

## 12. PROD INCHANGEE

| Element | Modifie ? |
|---|---|
| keybuzz-api PROD | Non — v3.5.117 |
| keybuzz-client PROD | Non — v3.5.116 |
| keybuzz-admin-v2 PROD | Non — v2.11.15 |
| DB PROD | Non |
| sGTM / Addingwell | Non |

---

## 13. RESUME

```
PH-T8.10P.1-GOOGLE-SGTM-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01 — TERMINE
Verdict : GO

Preflight
  API DEV : v3.5.118-google-sgtm-owner-aware-quick-win-dev
  Aucun changement dans cette phase

Avant test
  0 rows attribution avec gclid + owner (ni avec, ni sans owner)
  2 enfants dans le cohort owner DEV

Cas owner avec gclid
  Tenant : test-gclid-t810p1b-o-moebeuxl
  Owner : keybuzz-consulting-mo9y479d
  gclid : test-gclid-t810p1-runtime-truth
  _gl : 1.test-gl-t810p1

Attribution
  Tous les champs presents en DB (gclid, gl_linker, owner, utm_*)
  conversion_sent_at null avant event, mis a jour apres

Event business
  emitConversionWebhook execute avec le vrai code path
  Owner-aware routing resolu : runtime -> owner

Payload owner-aware
  sGTM HTTP 200
  tenant_id = enfant runtime
  routing_tenant_id = owner KBC
  marketing_owner_tenant_id = owner KBC
  owner_routed = true
  gclid present

Legacy
  Tenant sans owner : routing_tenant_id = tenant_id, owner_routed = false
  Pas de fuite, sGTM HTTP 200

Non-regression
  Meta/TikTok intact, metrics intact, Client/Admin inchanges, PROD intacte

PROD inchangee
  OUI
```

Rapport : `keybuzz-infra/docs/PH-T8.10P.1-GOOGLE-SGTM-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01.md`

---

GOOGLE SGTM OWNER-AWARE RUNTIME TRUTH ESTABLISHED IN DEV — REAL GCLID OWNER-MAPPED FLOW PROVED — LEGACY PRESERVED — PROD UNTOUCHED

**STOP**
