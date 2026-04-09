# PH-AMZ-CONNECTOR-FALSE-CONNECTED-TRUTH-04 — Rapport

**Date** : 26 mars 2026  
**Phase** : PH-AMZ-CONNECTOR-FALSE-CONNECTED-TRUTH-04  
**Verdict** : **AMZ FALSE CONNECTED FIXED AND VALIDATED**

---

## 1. Reproduction du Bug

**Sequence** :
1. Creer un connecteur Amazon via /channels (ex: `ecomlg07-gmail-com-mn7n1okb`)
2. Ne PAS completer le flux OAuth Amazon
3. Quitter la page
4. Revenir sur /channels
5. Le connecteur affiche "Connecte" avec une adresse inbound generee
6. Sur /orders, cliquer "Synchroniser Amazon" → erreur "Identifiants Amazon non configures"

**Bug reproduit** : OUI en DEV et PROD

---

## 2. Separation des 4 Etats Metier

| Etat | Table/Champ | Signal |
|---|---|---|
| **Channel cree** | `tenant_channels` row, `status='pending'` | Utilisateur a ajoute un pays Amazon |
| **Inbound provisionne** | `inbound_connections.status='READY'` + `inbound_addresses` | Email inbound genere (pour recevoir les messages client) |
| **OAuth Amazon actif** | `marketplace_connections` row avec credentials OU `inbound_addresses.lastInboundAt IS NOT NULL` (legacy) | Tenant reellement lie a un compte Amazon |
| **Sync commandes disponible** | OAuth actif + credentials Vault valides | SP-API fonctionnel pour orders/reports |

---

## 3. Root Cause

Le handler `GET /api/v1/marketplaces/amazon/status` dans `compat/routes.ts` avait **deux bugs** :

### Bug A — Auto-promotion aveugle
A chaque appel du status endpoint, l'auto-provisioning :
1. Trouvait les `tenant_channels` en `status='pending'`
2. Creait `inbound_connections` + `inbound_addresses`
3. **Mettait `tenant_channels.status = 'active'`**

Resultat : un simple chargement de /channels suffisait a passer le canal a "Connecte".

### Bug B — Retour `connected: true` sans verification
Le Step 2 du handler retournait `connected: true` des que `inbound_connections.status = 'READY'`, sans verifier l'existence de credentials Amazon (OAuth, Vault, ou messages recus).

Le handler `GET /inbound-address` avait le meme Bug A.

---

## 4. Comparaison Vrai vs Faux Connecteur

| Champ | ecomlg-001 (VRAI) | ecomlg07 (FAUX) |
|---|---|---|
| `tenant_channels.status` | `active` | `active` (auto-promu) |
| `inbound_connections.status` | `READY` | `READY` |
| `inbound_addresses.lastInboundAt` | **2026-01-15** (messages recus) | **NULL** |
| `marketplace_connections` | (vide — credentials legacy Vault) | (vide) |
| `tenant_channels.activated_at` | **Set** (FR) | **NULL** |
| Sync commandes | **OK** | **KO — "Identifiants non configures"** |

**Donnee manquante dans le faux positif** : aucune preuve de connexion reelle (pas de `lastInboundAt`, pas de `marketplace_connections`, pas de `activated_at`).

---

## 5. Corrections Appliquees

### Fix 1 — Ne plus auto-promouvoir a `active`
Dans les deux handlers (status + inbound-address), retire `status = 'active'` et `connected_at = COALESCE(...)` des UPDATE tenant_channels. L'auto-provisioning continue de creer l'email inbound et de setter `inbound_email` + `connection_ref`, mais le status reste `pending`.

### Fix 2 — Verification de connexion reelle
Le retour du status endpoint verifie 3 signaux avant de retourner `connected: true` :
```sql
has_messages: inbound_addresses.lastInboundAt IS NOT NULL
has_oauth: marketplace_connections.type = 'AMAZON'
has_legacy_active: tenant_channels.activated_at IS NOT NULL
```
Si aucun signal n'est positif → `connected: false, status: 'INBOUND_ONLY'`

### Fix 3 — Nettoyage des faux positifs
Script de cleanup : reset a `pending` les channels qui etaient `active` avec `activated_at IS NULL` et sans messages reels.

---

## 6. Validation DEV

| Test | Verdict |
|---|---|
| ecomlg-001 (vraie connexion) → `connected: true, CONNECTED` | **OK** |
| srv-performance (faux positif) → `connected: false, INBOUND_ONLY` | **OK** |
| ecomlg07 (nouveau tenant) → `connected: false, INBOUND_ONLY` | **OK** |
| ecomlg-001 channels restent `active` (4/4) | **OK** |
| Faux positifs corriges a `pending` (srv: 3, ecomlg07: 3, test: 1) | **OK** |
| Nouveau channel test ne se promote plus a `active` | **OK** |

**AMZ FALSE CONNECTED DEV = OK**  
**AMZ REAL CONNECTED DEV = OK**  
**AMZ SYNC STATE DEV = OK**  
**DEV NO REGRESSION = OK**

---

## 7. Validation PROD

| Test | Verdict |
|---|---|
| ecomlg-001 PROD → `connected: true, CONNECTED` | **OK** |
| romruais (faux positif) → reset a `pending` | **OK** |
| Health check | **OK** |

**AMZ FALSE CONNECTED PROD = OK**  
**AMZ REAL CONNECTED PROD = OK**  
**AMZ SYNC STATE PROD = OK**  
**PROD NO REGRESSION = OK**

---

## 8. Flash "Connexion instable"

**Non lie au bug Amazon.** Ce message provient de `app/select-tenant/page.tsx` et apparait uniquement apres 3 echecs consecutifs de chargement des espaces (`/api/tenant-context/tenants`). C'est un mecanisme de resilience auth/session, pas un probleme Amazon.

---

## 9. Deploiements

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.115-ph-amz-false-connected-dev` | `v3.5.115-ph-amz-false-connected-prod` |

---

## 10. Rollback

> **CORRIGE PH-ROLLBACK-METADATA-TRUTH-01** : le rollback original pointait vers `v3.5.47-vault-tls-fix` (image pre-mars 2026). Le tag correct est `v3.5.111-ph-billing-truth` (image deployee juste avant TRUTH-04).

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.111-ph-billing-truth-dev -n keybuzz-api-dev

# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.111-ph-billing-truth-prod -n keybuzz-api-prod
```

---

## 11. Verdict Final

## AMZ FALSE CONNECTED FIXED AND VALIDATED
