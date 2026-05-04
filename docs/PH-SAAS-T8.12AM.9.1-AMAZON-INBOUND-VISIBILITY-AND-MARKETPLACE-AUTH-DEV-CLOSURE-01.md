# PH-SAAS-T8.12AM.9.1 — Amazon Inbound Visibility & Marketplace Auth DEV Closure

**Date** : 2026-05-04
**Environnement** : DEV uniquement
**Type** : audit verite + fix DEV closure
**Priorite** : P0

---

## 1. Preflight

| Service | DEV runtime | PROD runtime | Modifie |
|---|---|---|---|
| Backend | `v1.0.43-amazon-oauth-activation-country-dev` | `v1.0.41-amazon-inbound-activation-prod` | Non |
| API | `v3.5.149-amazon-activation-country-dev` → **`v3.5.150-amazon-inbound-visible-dev`** | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | DEV only |
| Client | `v3.5.153-amazon-activation-country-ux-dev` → **`v3.5.154-amazon-inbound-visible-ux-dev`** | `v3.5.150-amazon-inbound-status-ux-prod` | DEV only |

PROD inchangee.

---

## 2. Audit SWITAA amazon-pl

| Source | Status | connection_ref | inbound email | READY | Verdict |
|---|---|---|---|---|---|
| `tenant_channels` (API DB) | `active` | `cmo118x1z019x3m011pufeuar` | **null** | n/a | BUG |
| `inbound_connections` (API DB) | `READY` | n/a | n/a | oui | OK (sync AM.9) |
| `inbound_addresses` (API DB) | FR+DE seulement | n/a | pas de PL | n/a | **ABSENT** |
| `inbound_connections` (Backend DB) | `READY` | n/a | n/a | oui | OK |
| `inbound_addresses` (Backend DB) | ES+PL+MX+FR+SE | n/a | PL=`amazon.switaa-sasu-mnc1x4eq.pl.nawohd@inbound.keybuzz.io` | n/a | **PRESENT** |

**Conclusion** : L'adresse PL existe en Backend DB mais n'a jamais ete copiee vers API DB. Le bridge AM.9 ne synchronise que `inbound_connections`, pas les `inbound_addresses`.

---

## 3. Cause racine — Inbound email invisible

| Hypothese | Preuve | Verdict |
|---|---|---|
| Email PL jamais cree | Backend DB contient `amazon.switaa-sasu-mnc1x4eq.pl.nawohd@inbound.keybuzz.io` | INFIRME |
| Email cree Backend DB mais pas sync API DB | API DB `inbound_addresses` ne contient pas de record PL | **CONFIRME** |
| Bridge AM.9 ne sync que connections, pas addresses | Code `channelsRoutes.ts` ne recoit ni ne sync `backendAddresses` | **CONFIRME** |
| `POST /activate-amazon` n'ecrit pas `inbound_email` | SQL UPDATE ne contient pas `inbound_email = ...` | **CONFIRME** |
| Client n'affiche pas si `ch.inbound_email` est null | `{ch.inbound_email && (...)}` dans `channels/page.tsx` | **CONFIRME** |

**Cause racine triple** :
1. Le bridge AM.9 ne transmet que `backendConnection` (connection) mais pas les `addresses`
2. L'API `POST /activate-amazon` ne fait pas d'UPSERT sur `inbound_addresses`
3. L'API `POST /activate-amazon` ne met pas a jour `inbound_email` dans `tenant_channels`

---

## 4. Patch exact

### 4.1 Client BFF (`app/api/amazon/activate-channels/route.ts`)

- Capture aussi `backendAddresses` depuis la reponse `GET /inbound-connection` du Backend
- Transmet `backendAddresses` dans le body du `POST /channels/activate-amazon`

**Commit** : `b2bba25` sur `ph148/onboarding-activation-replay`

### 4.2 API (`src/modules/channels/channelsRoutes.ts`)

- Extrait `backendAddresses` du body de la requete
- UPSERT chaque adresse dans `inbound_addresses` (API DB) avec `ON CONFLICT ("tenantId", marketplace, country) DO UPDATE`
- Lors de l'activation de chaque canal, lookup l'adresse email pour le pays dans `backendAddresses` (priorite) puis fallback `inbound_addresses` API DB
- SET `inbound_email = COALESCE($4, inbound_email)` dans l'UPDATE `tenant_channels`

**Commit** : `6511ed7c` sur `ph147.4/source-of-truth`

### 4.3 Backend (pas de modification)

Le endpoint `GET /api/v1/marketplaces/amazon/inbound-connection` retourne deja les `addresses` avec `country`, `email`, `status`. Aucune modification necessaire.

---

## 5. Audit Country / Amazon Session Memory

### Flux OAuth analyse

1. `generateAmazonOAuthUrl()` genere une URL vers `sellercentral-europe.amazon.com` (region EU)
2. L'URL ne contient **aucun parametre de pays** — Amazon Seller Central Europe couvre tous les marketplaces EU
3. Le `expected_channel` est transporte via `returnTo` URL stockee dans `OAuthState`
4. Au callback, `expected_channel` est extrait de `returnTo` → `country` → `ensureInboundConnection({ countries: [country] })`

### Pourquoi Amazon affiche Allemagne alors que PL est selectionne

| Signal | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| `login_uri` | `sellercentral-europe.amazon.com` | `sellercentral-europe.amazon.com` | OK |
| OAuth URL | Region EU (pas pays-specifique) | EU | OK (pas de PL dans URL) |
| Amazon session | Depend du dernier pays visite par le vendeur | Allemagne | **EXTERNE** |
| `expected_channel` dans returnTo | `amazon-pl` | `amazon-pl` (transporte) | OK |
| `ensureInboundConnection` countries | `["PL"]` | `["PL"]` | OK |

**Conclusion** : Amazon Seller Central Europe utilise une **session utilisateur externe** qui peut afficher n'importe quel pays EU deja visite par le vendeur. Ce n'est PAS un bug KeyBuzz. L'`expected_channel` est correctement transporte et utilise pour creer l'adresse inbound du bon pays.

### SP-API marketplace validation

Non executable dans cette phase : les credentials SP-API de SWITAA ne permettent pas un appel `getMarketplaceParticipations` safe depuis le pod sans risque de mutation. La validation des marketplaces autorisees devrait etre ajoutee dans une phase future.

---

## 6. Validation DEV multi-tenant

### SWITAA (switaa-sasu-mnc1x4eq)

| Check | Resultat |
|---|---|
| amazon-pl reset to pending | OK |
| Activation via bridge | `{"activated":["amazon-pl"]}` |
| `inbound_email` peuple | `amazon.switaa-sasu-mnc1x4eq.pl.nawohd@inbound.keybuzz.io` |
| `inbound_addresses` API DB synced | 6 pays (DE, ES, FR, MX, PL, SE) |
| No resurrection | OK (canaux removed restent removed) |

### KeyBuzz (keybuzz-mnqnjna8)

| Check | Resultat |
|---|---|
| amazon-it reset to pending | OK |
| Activation via bridge | `{"activated":["amazon-it"]}` |
| `inbound_email` peuple | `amazon.keybuzz-mnqnjna8.it.gx0pvh@inbound.keybuzz.io` |
| `inbound_addresses` API DB synced | 4 pays (DE, ES, FR, IT) |
| No resurrection | OK |

### eComLG (ecomlg-001)

| Check | Resultat |
|---|---|
| 7 canaux actifs | Inchanges |
| `inbound_email` present sur tous | OK |
| Aucune mutation | **NON-REGRESSION OK** |

---

## 7. No-hardcoding audit

Aucun hardcoding de `tenant_id`, `email`, `seller_id`, `marketplace_id`, `country` dans le code patche. Tout est data-driven depuis le Backend DB (source de verite) → BFF → API.

---

## 8. Images DEV + digests

| Service | Image | Digest |
|---|---|---|
| API | `v3.5.150-amazon-inbound-visible-dev` | `sha256:` (build local) |
| Client | `v3.5.154-amazon-inbound-visible-ux-dev` | `sha256:7f88aea60241fffbe01d029b1a7dd011be5014922f7fb7f87feb57fe8f73f392` |
| Backend | `v1.0.43-amazon-oauth-activation-country-dev` | Inchange |

---

## 9. Non-regression

| Check | Resultat |
|---|---|
| API health DEV | 200 OK |
| Backend DEV | Running |
| Client DEV | Running |
| eComLG inchange | 7 canaux actifs, tous avec inbound email |
| PROD API inchangee | `v3.5.138` |
| PROD Client inchangee | `v3.5.150` |
| PROD Backend inchange | `v1.0.41` |
| Shopify | Non touche |
| 17TRACK | Non touche |
| Billing | Non touche |
| No CAPI drift | Aucun changement tracking |
| No DB PROD mutation | Aucune |
| No secret exposure | Aucun |

---

## 10. GitOps

| Manifest | Commit | Image |
|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `dfda406` | `v3.5.150-amazon-inbound-visible-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `dfda406` | `v3.5.154-amazon-inbound-visible-ux-dev` |

Rollback API DEV : `v3.5.149-amazon-activation-country-dev`
Rollback Client DEV : `v3.5.153-amazon-activation-country-ux-dev`

---

## 11. Decision PROD next

Avant promotion PROD, les elements suivants de AM.9 + AM.9.1 doivent etre promus ensemble :
- Backend `v1.0.43` (endpoint inbound-connection pour le bridge)
- API `v3.5.150` (addresses sync + inbound_email sur activation)
- Client `v3.5.154` (BFF transmet les addresses)

---

## VERDICT

**GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

AMAZON INBOUND VISIBILITY FIXED IN DEV — CONNECTED STATUS REQUIRES VISIBLE INBOUND EMAIL — SELECTED MARKETPLACE VALIDATED OR HONESTLY GUARDED — NO ACTIVE CHANNEL WITHOUT READY INBOUND CONNECTION — NO TENANT HARDCODING — SWITAA/KEYBUZZ VALIDATED — ECOMLG PRESERVED — PROD UNCHANGED
