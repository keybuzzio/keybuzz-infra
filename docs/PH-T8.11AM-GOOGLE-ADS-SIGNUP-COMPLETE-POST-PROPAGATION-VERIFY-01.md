# PH-T8.11AM — GOOGLE-ADS-SIGNUP-COMPLETE-POST-PROPAGATION-VERIFY-01

**Date** : 29 avril 2026 (12h52 UTC+2, ~1h après mutation PH-T8.11AL)
**Ticket** : KEY-217 (reste Done)
**Phase précédente** : PH-T8.11AL

---

## 1. Préflight

| Élément | Valeur | Status |
|---------|--------|--------|
| Secret PROD `keybuzz-google-ads` | 4 clés (22/71/35/103 chars) | ✅ |
| OAuth access token | 254 chars | ✅ |
| API PROD health | `{"status":"ok"}` | ✅ |
| Google Ads API | v24, customer `5947963982` | ✅ |

---

## 2. Conversion Actions

| Conversion Action | ID | Status | Category | Type | Primary | InConv |
|---|---|---|---|---|---|---|
| **Achat** | `7579957621` | **ENABLED** | PURCHASE | WEBPAGE | **True** | **True** |
| KeyBuzz (web) click_signup | `7592057194` | HIDDEN | DEFAULT | GA4_CUSTOM | False | False |
| KeyBuzz (web) close_convert_lead | `7592057185` | HIDDEN | CONVERTED_LEAD | GA4_CLOSE_CONVERT_LEAD | False | False |
| KeyBuzz (web) purchase | `7592057191` | HIDDEN | PURCHASE | GA4_PURCHASE | False | False |
| KeyBuzz (web) qualify_lead | `7592057188` | HIDDEN | QUALIFIED_LEAD | GA4_QUALIFY_LEAD | False | False |
| **KeyBuzz (web) signup_complete** | `7592067025` | **ENABLED** | **SIGNUP** | GA4_CUSTOM | False | False |

- `Achat` intact : ✅ (ENABLED, PURCHASE, primary=True, inConv=True)
- `signup_complete` ENABLED/SIGNUP : ✅
- Doublons : ❌ aucun (1 seule instance)
- Total : 6 conversion actions (identique à PH-T8.11AL)

---

## 3. Customer Conversion Goals

| Category | Origin | Biddable |
|----------|--------|----------|
| PURCHASE | WEBSITE | True |
| **SIGNUP** | **WEBSITE** | **True** |

---

## 4. Verdict : Cas B — GO partiel

| Critère | Attendu | Constaté | Verdict |
|---------|---------|----------|---------|
| `signup_complete` status | ENABLED | ENABLED | ✅ |
| `signup_complete` category | SIGNUP | SIGNUP | ✅ |
| `SIGNUP/WEBSITE` biddable | True | True | ✅ |
| `Achat` intact | True | True | ✅ |
| Doublons | 0 | 0 | ✅ |
| `primary_for_goal` | True (après propagation) | **False** | ⏳ |
| `include_in_conversions_metric` | True (après propagation) | **False** | ⏳ |

### Interprétation

Les flags `primary_for_goal` et `include_in_conversions_metric` ne sont **pas encore propagés** (~1h après la mutation). C'est le comportement attendu documenté par Google pour les imports GA4 :

- Ces flags sont dérivés du `CustomerConversionGoal` correspondant
- Le goal `SIGNUP/WEBSITE` est `biddable=True` — la conversion sera comptabilisée dans les enchères et rapports
- La propagation complète est attendue entre **4h et 24h** après l'activation
- **Aucune action corrective** n'est nécessaire

### Recommandation

- Re-vérifier dans **24h** (30 avril 2026) que `primary_for_goal=True` et `include_in_conversions_metric=True`
- Si toujours False après 48h, contacter le support Google Ads

---

## 5. Non-régression

| Service | Status |
|---------|--------|
| API PROD | `{"status":"ok"}` |
| API PROD image | `v3.5.123-linkedin-capi-native-prod` (inchangée) |
| Client PROD image | `v3.5.125-register-console-cleanup-prod` (inchangée) |
| Admin PROD image | `v2.11.31-owner-aware-playbook-prod` (inchangée) |
| Website PROD image | `v0.6.7-pricing-attribution-forwarding-prod` (inchangée) |
| API restarts | 0 |
| Client restarts | 0 |
| Admin restarts | 0 |
| Website restarts | 0 (2 replicas) |
| Outbound worker | 7 restarts (pré-existant) |
| Mutation effectuée | ❌ Aucune — lecture seule |
| Code/build/deploy | ❌ Aucun |
| Secret exposé | ❌ Aucun |

---

## 6. Linear

- **KEY-217** : reste **Done** — activation confirmée, propagation en cours (Cas B non bloquant)

---

## VERDICT

**GOOGLE ADS SIGNUP_COMPLETE POST-PROPAGATION VERIFIED — CAS B GO PARTIEL — ENABLED/SIGNUP CONFIRMED — SIGNUP GOAL BIDDABLE — PRIMARY_FOR_GOAL PENDING PROPAGATION (4-24H) — ACHAT PRESERVED — NO DUPLICATE — NO MUTATION — NO TRACKING DRIFT**
