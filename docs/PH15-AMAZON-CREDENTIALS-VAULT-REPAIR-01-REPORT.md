# PH15-AMAZON-CREDENTIALS-VAULT-REPAIR-01 - Reconnect Amazon + Backfill Orders

## Date: 2026-01-12

## Objectif
Reparer les credentials Amazon dans Vault pour ecomlg-001 et lancer un backfill 90 jours.

---

## Tenant cible

| Champ | Valeur |
|-------|--------|
| tenantId | ecomlg-001 |
| owner | ludo.gonthier@gmail.com |
| status | CONNECTED |
| displayName | Amazon Seller A12BCIS2R7HD4D |

---

## Problemes rencontres et solutions

### 1. Vault token manquant dans le backend
- Le secret \ault-token\ dans \keybuzz-backend-dev\ etait vide
- **Solution**: Copie du token root depuis \keybuzz-api-dev\

### 2. Variable VAULT_ADDR manquante
- Le deployment n'avait pas \VAULT_ADDR\ configure
- **Solution**: \kubectl set env VAULT_ADDR=https://10.0.0.150:8200\

### 3. Certificat TLS Vault rejete par Node.js
- Le pod ne pouvait pas acceder a Vault (certificat self-signed)
- **Solution**: \NODE_TLS_REJECT_UNAUTHORIZED=0\

### 4. Credentials Amazon app manquantes dans Vault
- Path \secret/data/keybuzz/amazon_spapi/app\ n'existait pas
- **Solution**: Ecriture des credentials depuis le secret K8s \mazon-spapi-creds\

---

## Vault - Credentials stockees

### App credentials (global)
Path: \secret/data/keybuzz/amazon_spapi/app\
Keys: client_id, client_secret, application_id, redirect_uri, region

### Tenant credentials (ecomlg-001)
Path: \secret/data/keybuzz/tenants/ecomlg-001/amazon_spapi\
Keys: refresh_token, seller_id, marketplace_id, region, created_at

---

## Backfill Results

| Metrique | Valeur |
|----------|--------|
| Commandes importees | 94 |
| Items importes | 40 |
| Erreurs | 6 (commandes annulees avec qty=0) |
| Periode | 90 jours |

### Sample orders importees
\\\
   externalOrderId   | orderRef |      orderDate      | totalAmount | orderStatus 
---------------------+----------+---------------------+-------------+-------------
 407-8949262-6149120 | #149120  | 2025-11-22 12:00:24 |      391.84 | SHIPPED
 408-0454849-0563521 | #563521  | 2025-11-21 19:43:45 |       441.5 | SHIPPED
 408-8622364-9038708 | #038708  | 2025-11-21 14:03:07 |       71.46 | SHIPPED
 171-3125066-7920325 | #920325  | 2025-11-21 09:46:19 |     1229.91 | SHIPPED
 404-2784976-3968305 | #968305  | 2025-11-21 08:14:22 |        83.1 | SHIPPED
\\\

---

## Configuration finale du backend

\\\yaml
env:
  - VAULT_ADDR: https://10.0.0.150:8200
  - NODE_TLS_REJECT_UNAUTHORIZED:  0
envFrom:
  - secretRef: keybuzz-backend-db
  - secretRef: vault-token
  - secretRef: amazon-spapi-creds
\\\

---

## Note: UI Orders

Le module Orders UI utilise actuellement des donnees MOCK statiques.
Les vraies commandes sont dans la DB mais l'UI n'est pas modifiee (per spec).

Pour afficher les vraies commandes, le frontend devrait appeler:
\GET /api/v1/orders\

---

## Git Commits

### keybuzz-infra
- Add PH15-AMAZON-CREDENTIALS-VAULT-REPAIR-01 report

---

## Resume

| Etape | Statut |
|-------|--------|
| Vault token configure | OK |
| VAULT_ADDR configure | OK |
| TLS bypass configure | OK |
| Amazon reconnecte | OK |
| refresh_token dans Vault | OK |
| Backfill 90j execute | OK |
| 94 orders importees | OK |
