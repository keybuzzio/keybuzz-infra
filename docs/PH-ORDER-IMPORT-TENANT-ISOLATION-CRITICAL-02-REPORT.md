# PH-ORDER-IMPORT-TENANT-ISOLATION-CRITICAL-02 — RAPPORT

> Date : 2026-03-27
> Auteur : Agent Cursor
> Gravite : CRITIQUE
> Environnements : DEV + PROD

---

## 1. PROBLEME

Depuis le tenant SRV Performance (DEV), des commandes Amazon appartenant a eComLG apparaissaient dans la page commandes et le panneau de droite, alors que SRV Performance **n'a pas de compte Amazon reellement connecte via OAuth**.

Le fix precedent (PH-TENANT-ISOLATION-CRITICAL-01) avait corrige la fuite sur `GET /orders/:orderId` mais les orders etaient **deja presentes en base** et pouvaient etre re-importees.

---

## 2. REPRODUCTION EXACTE

### Etat des connecteurs SRV Performance (DEV)
| Element | Valeur |
|---|---|
| `marketplace_connections` | **AUCUNE** |
| `tenant_channels` | 3 channels Amazon (FR/ES/IT), tous `status = 'pending'`, `activated_at = NULL` |
| `inbound_addresses` | 3 adresses validees (FR/ES/IT), `lastInboundAt` set sur FR |
| `oauth_states` | **AUCUN** |

### Orders trouvees dans SRV Performance
**10 orders** avec `raw_data = true` et statuts Amazon reels (`Unshipped`, `Shipped`) :

| external_order_id | status | total | created_at |
|---|---|---|---|
| 405-3162676-0395538 | Unshipped | 18.72 EUR | 2026-03-26 11:31 |
| 408-0959811-1781943 | Unshipped | 862.12 EUR | 2026-03-26 11:32 |
| 407-8671004-0086716 | Unshipped | 200.14 EUR | 2026-03-26 12:25 |
| 171-1342911-9909157 | Unshipped | 76.59 EUR | 2026-03-27 06:39 |
| 408-0197665-7570718 | Shipped | 289.48 EUR | 2026-03-27 08:32 |
| 405-1234567-8901234 | Unknown | 0.00 EUR | 2026-03-27 10:46 |
| 404-3436907-4242729 | Shipped | 161.47 EUR | 2026-03-27 12:49 |
| 405-1234567-8905678 | Unknown | 0.00 EUR | 2026-03-27 13:05 |
| 405-1234567-8909012 | Unknown | 0.00 EUR | 2026-03-27 14:31 |
| 406-9765346-1305900 | Unshipped | 265.97 EUR | 2026-03-27 15:22 |

**3 de ces orders existent aussi dans eComLG** (doublons inter-tenant confirmes).

---

## 3. ROOT CAUSE

### Cause 1 — Credentials Vault partagees
Le secret Vault `keybuzz/tenants/srv-performance-mn7ds3oj/amazon_spapi` contenait des credentials **identiques** a celles d'eComLG :
- `seller_id: A12BCIS2R7HD4D` (meme compte Amazon)
- `marketplace_id: A13V1IB3VIYZZH` (meme marketplace)
- `refresh_token` valide

Vault etait accessible depuis les pods K8s (`vault.default.svc.cluster.local:8200`, status 200).

### Cause 2 — import-one sans verification de canal actif
L'endpoint `POST /api/v1/orders/import-one` :
1. Recevait un `tenantId` via header/body
2. Appelait `getAmazonTenantCreds(tenantId)` pour obtenir les credentials Vault
3. Fetachait les donnees Amazon SP-API **sans verifier** si le tenant avait un canal Amazon actif
4. Creait l'order dans la DB du tenant demandeur

### Cause 3 — sync-all sans verification de canal actif
L'endpoint `POST /api/v1/orders/sync-all` acceptait egalement les requetes de tenants sans canal actif.

### Chaine complete
```
1. Conversations Amazon arrivent sur l'adresse inbound SRV Perf (provisionnee lors du setup)
2. OrderSidePanel detecte order_ref dans la conversation
3. Appel POST /api/orders/import-one avec tenantId = srv-performance
4. import-one → getAmazonTenantCreds("srv-performance") → Vault retourne les creds eComLG
5. fetchAmazonOrder() → SP-API retourne les vraies donnees Amazon
6. Order creee dans la table orders avec tenant_id = "srv-performance"
→ SRV Performance voit des orders eComLG avec donnees reelles
```

---

## 4. CORRECTIONS APPLIQUEES

### Fix 1 — Guard canal actif sur import-one
Fichier : `/opt/keybuzz/keybuzz-api/src/modules/orders/routes.ts`

Avant l'appel `fetchAmazonOrder()`, verification que le tenant a au moins un `tenant_channels` avec `provider = 'amazon'` ET `status = 'active'` :
- Si aucun canal actif → retour 400 `NO_ACTIVE_CHANNEL`
- Si canal actif → import normal via SP-API

### Fix 2 — Guard canal actif sur sync-all
Meme verification ajoutee a l'endpoint `POST /api/v1/orders/sync-all`.
Si aucun canal Amazon actif → retour 400.

### Fix du PH-01 conserve
Le fix precedent sur `GET /api/v1/orders/:orderId` (filtre `tenant_id` obligatoire) reste en place.

### Discriminant utilise
`tenant_channels.status = 'active'` :
- eComLG FR : `status = 'active'`, `activated_at = 2026-01-15` → AUTORISE
- SRV Performance FR/ES/IT : `status = 'pending'`, `activated_at = NULL` → BLOQUE

---

## 5. NETTOYAGE DES DONNEES POLLUEES

### DEV — SRV Performance
- **10 orders supprimees** (toutes illegitimes, importees avec les credentials eComLG)
- eComLG intact : 11 888 orders verifiees

### PROD
- SRV Performance n'existe pas en PROD
- SWITAA SASU a 4 orders avec canaux `removed` → surveiller mais pas de nettoyage automatique (pourrait etre des donnees legitimes anterieures)

---

## 6. VALIDATIONS DEV

| Cas | Description | Resultat |
|---|---|---|
| A | eComLG recherche ses commandes | **OK** (200, orders trouvees) |
| B | SRV Perf import-one | **OK** (400, NO_ACTIVE_CHANNEL) |
| C | SRV Perf recherche order eComLG | **OK** (0 resultats) |
| D | Page commandes SRV Perf | **OK** (0 orders) |
| E | eComLG import-one | **OK** (200, source: cache) |
| F | SRV Perf sync-all | **OK** (400, rejete) |

**ORDER IMPORT ISOLATION DEV = OK**
**ORDER PANEL ISOLATION DEV = OK**
**NO INVALID AMAZON DATA DEV = OK**
**DEV NO REGRESSION = OK**

---

## 7. VALIDATIONS PROD

| Cas | Description | Resultat |
|---|---|---|
| Import tenant sans channel actif | `ecomlg-mn3rdmf6` import-one | **OK** (400, NO_ACTIVE_CHANNEL) |
| eComLG search | Recherche commandes | **OK** (200, orders trouvees) |
| eComLG import-one | Import commande | **OK** (200, source: cache) |
| Tenants avec orders | Seul ecomlg-001 (11814) + switaa-sasu (4 legacy) | **OK** |

**ORDER IMPORT ISOLATION PROD = OK**
**ORDER PANEL ISOLATION PROD = OK**
**NO INVALID AMAZON DATA PROD = OK**
**PROD NO REGRESSION = OK**

---

## 8. DEPLOIEMENT

| Env | Image | Tag |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.50-import-isolation-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.50-import-isolation-prod` |

GitOps : `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` et `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` mis a jour.

---

## 9. ROLLBACK

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49-tenant-isolation-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49-tenant-isolation-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

---

## 10. RECOMMANDATIONS

1. **Supprimer le secret Vault** `keybuzz/tenants/srv-performance-mn7ds3oj/amazon_spapi` pour eviter toute reutilisation
2. **Auditer les autres secrets Vault** par tenant pour verifier qu'aucun autre tenant de test n'a de credentials Amazon copiees
3. **A terme** : stocker les credentials Amazon dans `marketplace_connections` (table actuellement vide) plutot que dans Vault par convention de path

---

## VERDICT FINAL

# ORDER TENANT ISOLATION FULLY RESTORED
