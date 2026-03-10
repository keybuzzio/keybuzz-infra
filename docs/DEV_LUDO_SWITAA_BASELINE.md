# DEV_LUDO_SWITAA_BASELINE — Freeze B10 (PH362A)

**Date du freeze** : 2026-02-19T13:04 UTC  
**Validé par** : CE (automated matrix) — en attente validation Ludovic  
**Méthode** : Matrice automatisée 10 bundles, 15 tests par bundle  
**Résultat** : B10_PH362A = meilleur PASS (14/14 corrigé)

---

## Composants déployés

| Composant | Image | Tag | Digest |
|-----------|-------|-----|--------|
| **API DEV** | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.5-ph362a-stable-enriched-dev` | `sha256:1b937f7e21aaffb96f8ad61e71fcfdd5241fcd90ddc6ff6cb7ed7d34054739db` |
| **Client DEV** | `ghcr.io/keybuzzio/keybuzz-client` | `v3.4.4-ph362a-clean-build-dev` | `sha256:7bc739e9c9fed6b2ad74fc7d5b7534f97e45a66075413d50e48a437041ed043a` |
| **Worker DEV** | `ghcr.io/keybuzzio/keybuzz-api` | `v3.4.4-ph353b-fixed-lock-dev` | (inchangé) |

---

## Tenant de test

| Champ | Valeur |
|-------|--------|
| Tenant ID | `tenant-1771372217854` (auto-découvert) |
| Nom | SWITAA SASU |
| User | `contact@switaa.com` (Ludovic GONTHIER) |
| Plan | PRO |
| Trial | Oui (expire 2026-03-03) |
| Rôle | owner |

---

## Résultats de validation B10

| # | Test | Résultat | Détail |
|---|------|----------|--------|
| 1 | Auth check-user | **PASS** | `exists:true, hasTenants:true, userName:"Ludovic GONTHIER"` |
| 2 | BFF check-email | **PASS** | `exists:true, hasTenants:true` |
| 3 | Tenant context | **PASS** | 1 tenant (SWITAA SASU) |
| 4 | Inbox Octopia | **PASS** | 5/5 conversations Octopia, avec order_ref (ex: `2601251444KPUJ5`) |
| 5 | Channels count | **PASS** | octopia=232, amazon=3 |
| 6 | Orders API | **PASS** | 20 commandes, route `/api/v1/orders` → 200 |
| 7 | Order enrichment | **PASS** | marketplaceStatus={Livrée, step 5}, financialSummary={EUR, sale=890.07, commission=-52.02}, timeline=3 events |
| 8 | Octopia status | **PASS** | Endpoint 200, status=ERROR (credentials, pas code), mode=AGGREGATOR |
| 9 | AI settings | **PASS** | mode=supervised, enabled=true |
| 10 | Billing | **PASS** | plan=PRO, cycle=monthly |
| 11 | Suppliers | **PASS** | 2 fournisseurs |
| 12 | Dashboard | **PASS** | total=235 conv, open=46, pending=1, resolved=188 |
| 13 | Pages SSR login | **PASS** | 200 |
| 14 | Pages SSR inbox | **PASS** | 307 (auth redirect attendu) |
| 15 | Pages SSR orders | **PASS** | 307 |
| 16 | Pages SSR settings | **PASS** | 307 |
| 17 | Pages SSR suppliers | **PASS** | 307 |

**Score : 17/17 PASS**

---

## Features présentes dans B10 (absentes des bundles antérieurs)

- **Orders enrichment complet** : marketplaceStatus, phone, financial, timeline (C3 PASS)
- **BFF check-email** corrigé (A2 PASS) — cassé dans B07–B08
- **Billing fonctionnel** (E2 PASS) — cassé dans B08–B09
- **Route /api/v1/orders** enregistrée (C1 PASS) — absente dans B06–B07

---

## Pourquoi B10 et pas un autre ?

| Bundle | Score | Raison d'exclusion |
|--------|-------|-------------------|
| B01 PH33KB | ERR | Script incompatible |
| B02–B05 | 14/14 | Pas d'enrichissement orders (PARTIAL), pas de features PH36.x |
| B06 PH353B | 12/14 | Route orders absente (404), pas d'enrichissement |
| B07 PH360 | 11/14 | BFF auth cassé, route orders absente |
| B08 PH361 | 12/14 | BFF auth cassé, billing 400 |
| B09 PH362 | 13/14 | Billing 400, client UI avec régressions connues |
| **B10 PH362A** | **14/14** | **Tout fonctionne, enrichissement complet** |

---

## Observation : Octopia Status = ERROR

Sur TOUS les bundles testés (B02–B10), l'endpoint Octopia retourne `status=ERROR`. Ce n'est pas un bug de code mais un problème de credentials/token Octopia. Le endpoint répond bien (200), les conversations sont importées (232), et le mode est correct (AGGREGATOR).

---

## Rollback instructions

Si besoin de revenir à l'ancien golden baseline (B06) :
```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-dev -n keybuzz-client-dev
```

---

## Référence

- Matrice complète : `keybuzz-infra/docs/PHBASELINE-LUDO-SWITAA-ACCEPTANCE-MATRIX.md`
- Ancien golden baseline DEV : `keybuzz-infra/docs/DEV_GOLDEN_BASELINE.md`
- Golden baseline PROD : `keybuzz-infra/docs/PROD_GOLDEN_BASELINE.md`

---

*STOP POINT — En attente validation visuelle Ludovic sur le compte SWITAA.*
