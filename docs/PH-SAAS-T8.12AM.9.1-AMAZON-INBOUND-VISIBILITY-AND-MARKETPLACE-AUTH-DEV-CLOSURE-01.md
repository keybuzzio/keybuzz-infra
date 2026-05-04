# PH-SAAS-T8.12AM.9.1 — Amazon Inbound Visibility & Marketplace Auth DEV Closure

> Phase : PH-SAAS-T8.12AM.9.1-AMAZON-INBOUND-VISIBILITY-AND-MARKETPLACE-AUTH-DEV-CLOSURE-01
> Date : 2026-05-04
> Environnement : DEV uniquement
> Type : audit vérité + fix DEV closure
> Priorité : P0

---

## 1. Préflight

| Service | DEV runtime | PROD runtime | Verdict |
|---|---|---|---|
| Backend | `v1.0.43-amazon-oauth-activation-country-dev` | `v1.0.41-amazon-inbound-activation-prod` | PROD inchangé |
| API | `v3.5.149-amazon-activation-country-dev` | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | PROD inchangé |
| Client | `v3.5.153-amazon-activation-country-ux-dev` | `v3.5.150-amazon-inbound-status-ux-prod` | PROD inchangé |

---

## 2. Reproduction — SWITAA amazon-pl

Symptômes observés par Ludovic :
- UI affiche `Amazon connecté : amazon-pl` avec carte `Connecté`
- **Aucune adresse email inbound visible** sur la carte
- Seller Central affichait Allemagne alors que Pologne était sélectionné

### Audit DB API (keybuzz)

| Source | tenant_channels amazon-pl | inbound_email | connection_ref |
|---|---|---|---|
| API DB | status=`active` | **null** | `cmo118x1z019x3m011pufeuar` |

### Audit DB API — inbound_addresses

| Pays | Adresse | Verdict |
|---|---|---|
| FR | `amazon.switaa-sasu-mnc1x4eq.fr.3c29f6@inbound.keybuzz.io` | Ancienne (pré-AM.9) |
| DE | `amazon.switaa-sasu-mnc1x4eq.de.83b6ec@inbound.keybuzz.io` | Ancienne (pré-AM.9) |
| **PL** | **ABSENT** | **Cause du bug** |

### Audit DB Backend (keybuzz_backend)

| Pays | Adresse | Verdict |
|---|---|---|
| PL | `amazon.switaa-sasu-mnc1x4eq.pl.nawohd@inbound.keybuzz.io` | Présente |
| FR | `amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@inbound.keybuzz.io` | Présente |
| ES | `amazon.switaa-sasu-mnc1x4eq.es.zw020z@inbound.keybuzz.io` | Présente |
| SE | `amazon.switaa-sasu-mnc1x4eq.se.n7q9go@inbound.keybuzz.io` | Présente |
| MX | `amazon.switaa-sasu-mnc1x4eq.mx.mng8xe@inbound.keybuzz.io` | Présente |

### Même pattern pour KeyBuzz amazon-it

| Source | Status | inbound_email | Backend DB address IT |
|---|---|---|---|
| API DB tenant_channels | active | **null** | n/a |
| Backend DB inbound_addresses | n/a | n/a | `amazon.keybuzz-mnqnjna8.it.gx0pvh@inbound.keybuzz.io` |
| API DB inbound_addresses IT | **ABSENT** | n/a | n/a |

---

## 3. Cause racine

### Le bridge AM.9 ne synchronise que les connections, pas les addresses

Le fix AM.9 a résolu le problème d'activation (canal passant de `pending` à `active`) en synchronisant `inbound_connections` depuis la Backend DB vers l'API DB. Cependant :

1. **`inbound_addresses`** (qui contiennent les emails par pays) ne sont **PAS synchronisées** par le bridge AM.9
2. Le `POST /channels/activate-amazon` fait un `UPDATE tenant_channels SET status='active'` mais **ne touche PAS la colonne `inbound_email`**
3. L'UI affiche l'email inbound **uniquement si `ch.inbound_email` est non-null** (`channels/page.tsx`)

**Résultat** : canal activé mais email invisible = invariant métier violé.

| Hypothèse | Preuve | Verdict |
|---|---|---|
| Email jamais créé | Backend DB contient l'adresse PL | REJETÉ |
| Email créé en Backend DB mais pas sync vers API DB | API DB `inbound_addresses` ne contient pas PL | **CONFIRMÉ** |
| Email créé en API DB mais pas renvoyé | API DB vide pour PL | REJETÉ |
| `activate-amazon` ne set pas `inbound_email` | Code SQL ne touche pas cette colonne | **CONFIRMÉ** |
| Mapping champ incorrect | UI lit `ch.inbound_email`, API retourne `inbound_email` | REJETÉ |

---

## 4. Patch DEV

### 4.1 BFF — `keybuzz-client/app/api/amazon/activate-channels/route.ts`

**Changement** : capturer et transmettre les `backendAddresses` (array d'adresses email par pays) depuis la réponse du Backend `GET /inbound-connection` vers l'API `POST /activate-amazon`.

- Ajout de `backendAddresses` dans le body JSON envoyé à l'API
- Le Backend retournait déjà les addresses dans sa réponse (champ `addresses[]`), le BFF les ignorait

**Commit** : `b2bba25` sur `ph148/onboarding-activation-replay`

### 4.2 API — `keybuzz-api/src/modules/channels/channelsRoutes.ts`

**Changements** :

1. **Sync addresses** : boucle sur `backendAddresses` reçues, UPSERT chaque adresse dans `inbound_addresses` API DB avec `ON CONFLICT ("tenantId", marketplace, country) DO UPDATE`
2. **Set inbound_email lors de l'activation** : pour chaque pays activé, lookup l'email dans `backendAddresses` (prioritaire) puis fallback sur `inbound_addresses` API DB. L'UPDATE `tenant_channels` inclut désormais `inbound_email = COALESCE($4, inbound_email)`

**Commit** : `6511ed7c` sur `ph147.4/source-of-truth`

### Backend — Pas de modification

Le Backend retournait déjà les addresses dans `GET /api/v1/marketplaces/amazon/inbound-connection`. Aucun changement nécessaire.

---

## 5. Audit Country / Amazon Session Memory

### Architecture OAuth

L'URL OAuth Amazon est générée avec `sellercentral-europe.amazon.com` (EU unique). Amazon n'a PAS de paramètre pays dans l'URL OAuth. Le pays affiché par Seller Central dépend de la **session utilisateur Amazon externe**.

| Signal | Valeur attendue | Valeur observée | Verdict |
|---|---|---|---|
| OAuth URL base | `sellercentral-europe.amazon.com` | `sellercentral-europe.amazon.com` | OK - URL EU unique |
| Paramètre pays dans OAuth URL | Aucun | Aucun | Conforme SP-API |
| `expected_channel` dans returnTo | `amazon-pl` | `amazon-pl` (via OAuthState) | OK |
| Pays affiché par Amazon | PL | DE (session Amazon) | **Externe** |
| `ensureInboundConnection` country | PL (depuis `expected_channel`) | PL | OK |
| Canal activé | `amazon-pl` | `amazon-pl` | OK |

**Conclusion** : Amazon Seller Central Europe conserve une session pays indépendante de l'OAuth KeyBuzz. C'est un comportement **externe Amazon** et non un bug KeyBuzz. KeyBuzz utilise correctement le `expected_channel` pour créer l'adresse inbound et activer le bon canal.

### SP-API Marketplace Validation

Non effectuée dans cette phase — nécessiterait un appel `GetMarketplaceParticipations` avec les credentials du seller. Documenté comme amélioration future possible.

---

## 6. Validation DEV

### Test SWITAA amazon-pl

1. Channel reset à `pending` (inbound_email=null)
2. Appel activation bridge (Backend → BFF → API)
3. Backend retourne 5 addresses (ES, PL, MX, FR, SE)
4. API sync 5 addresses dans `inbound_addresses` API DB
5. API active `amazon-pl` avec `inbound_email = amazon.switaa-sasu-mnc1x4eq.pl.nawohd@inbound.keybuzz.io`

**Résultat** : `inbound_email` peuplé et visible.

### Test KeyBuzz amazon-it

1. Channel reset à `pending`
2. Appel activation bridge
3. Backend retourne 4 addresses (ES, IT, FR, DE)
4. API sync 4 addresses
5. API active `amazon-it` avec `inbound_email = amazon.keybuzz-mnqnjna8.it.gx0pvh@inbound.keybuzz.io`

**Résultat** : `inbound_email` peuplé et visible.

### Checks obligatoires

| Check | SWITAA | KeyBuzz | eComLG |
|---|---|---|---|
| Inbound email visible si connecté | PL: nawohd@, FR: ulnllr@ | IT: gx0pvh@, FR: wwjhvb@, ES: fags2q@ | 7 canaux avec emails |
| Aucun active sans inbound email | OK | shopify-global (normal) | OK |
| No resurrection après suppression | OK (SE/ES/AU removed) | OK (DE/PL removed) | OK (DE/US removed) |
| Channel attendu conservé | amazon-pl activé | amazon-it activé | n/a |
| eComLG inchangé | n/a | n/a | 7 canaux identiques |
| Aucun hardcode | data-driven | data-driven | n/a |

---

## 7. Images DEV + Digests

| Service | Tag | Digest |
|---|---|---|
| API | `v3.5.150-amazon-inbound-visible-dev` | `7634b4f92056` (local) |
| Client | `v3.5.154-amazon-inbound-visible-ux-dev` | `sha256:7f88aea60241fffbe01d029b1a7dd011be5014922f7fb7f87feb57fe8f73f392` |
| Backend | Inchangé (`v1.0.43-amazon-oauth-activation-country-dev`) | n/a |

---

## 8. GitOps DEV

| Manifest | Image | Commit |
|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.150-amazon-inbound-visible-dev` | `dfda406` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.154-amazon-inbound-visible-ux-dev` | `dfda406` |

Rollout vérifié : les images runtime matchent les manifests.

---

## 9. No-Hardcoding Audit

| Élément | Hardcodé ? | Preuve |
|---|---|---|
| tenant_id | Non | `tenantId` from headers/body |
| country | Non | `addr.country` from Backend addresses |
| marketplace_key | Non | `amazon-${country.toLowerCase()}` dérivé |
| seller_id | Non | jamais référencé dans le patch |
| email address | Non | `addr.email` from Backend response |
| connection_ref | Non | `conn.id` from DB query |

---

## 10. Non-régression

| Check | Résultat |
|---|---|
| API DEV health | 200 OK |
| eComLG canaux inchangés | 7 canaux actifs avec emails identiques |
| PROD API image inchangée | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` |
| PROD Client image inchangée | `v3.5.150-amazon-inbound-status-ux-prod` |
| PROD Backend image inchangée | `v1.0.41-amazon-inbound-activation-prod` |
| Shopify inchangé | KeyBuzz shopify-global present, non touché |
| Billing inchangé | Aucune modification billing |
| No CAPI drift | Aucune modification tracking |
| No fake event | Aucun événement créé |
| No secret exposure | Aucun secret dans logs/rapport |

---

## 11. Rollback GitOps DEV

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.149-amazon-activation-country-dev -n keybuzz-api-dev

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.153-amazon-activation-country-ux-dev -n keybuzz-client-dev
```

---

## 12. Décision PROD next

Le fix AM.9.1 est prêt pour promotion PROD. Cependant, la PROD a un gap plus important :
- PROD API (`v3.5.138`) n'a PAS le bridge AM.9 (qui est en `v3.5.149` DEV seulement)
- PROD Backend (`v1.0.41`) n'a PAS le endpoint `GET /inbound-connection`

La promotion PROD nécessiterait de promouvoir AM.9 + AM.9.1 ensemble :
- Backend : `v1.0.43` → build PROD
- API : `v3.5.150` → build PROD
- Client : `v3.5.154` → build PROD

---

## VERDICT

**GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

AMAZON INBOUND VISIBILITY FIXED IN DEV — CONNECTED STATUS REQUIRES VISIBLE INBOUND EMAIL — SELECTED MARKETPLACE VALIDATED OR HONESTLY GUARDED — NO ACTIVE CHANNEL WITHOUT READY INBOUND CONNECTION — NO TENANT HARDCODING — SWITAA/KEYBUZZ VALIDATED — ECOMLG PRESERVED — PROD UNCHANGED
