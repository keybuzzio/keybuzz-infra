# PH-SHOPIFY-02.1 — UX Channels conforme + Activation réelle OAuth Shopify

> Date : 2026-04-09
> Env : DEV uniquement
> Images : API `v3.5.228-ph-shopify-021-scopes-dev` | Client `v3.5.227-ph-shopify-021-dev`
> PROD : inchangée (`v3.5.225-ph-playbooks-v2-prod`)

---

## 1. État initial

- API/Client DEV sur `v3.5.226-ph-shopify-02-dev` (PH-SHOPIFY-02)
- Tables `shopify_connections` et `shopify_webhook_events` existantes (vides)
- Shopify affiché comme **bloc autonome** toujours visible dans `/channels` — non conforme au pattern UX standard
- `SHOPIFY_CLIENT_ID` et `SHOPIFY_CLIENT_SECRET` vides → OAuth non fonctionnel
- Vault : **ACTIF** (changement depuis le contexte doc)
- ESO : **Fonctionnel** (2 ClusterSecretStores Valid/Ready)

---

## 2. Correction UX Channels

### Problème
Shopify était affiché comme un bloc dédié (~60 lignes JSX) toujours visible dans la page `/channels`, indépendamment du flow standard.

### Correction appliquée
1. **Supprimé** le bloc Shopify autonome (61 lignes)
2. **Intégré** Shopify dans le catalogue "Ajouter une marketplace" — click → ouvre un modal de connexion
3. **Ajouté** un modal Shopify (pattern identique au modal Octopia) : saisie domaine + bouton Connecter
4. **Ajouté** boutons Shopify dans les channel cards :
   - `pending` → bouton "Connecter Shopify" (ouvre le modal)
   - `active` → badge connecté avec shop domain
5. **Ajouté** disconnect Shopify automatique lors du retrait d'un canal
6. **API callback** : active automatiquement le `tenant_channel` après OAuth réussi (`addChannel` + `activateChannel`)
7. **API disconnect** : désactive le `tenant_channel` lors de la déconnexion

### Preuve UX conforme
Shopify suit maintenant le même flow que Amazon/Octopia :
- Catalogue → sélection → modal config → OAuth → canal actif dans la liste

---

## 3. Stratégie secrets

### Vault/ESO
- **Vault : ACTIF** (service `vault.service` = active)
- **ESO : Fonctionnel** (ClusterSecretStores `vault-backend` et `vault-backend-database` = Valid/Ready)

### Stratégie retenue : K8s Secret (`keybuzz-shopify`)
Pattern identique aux autres secrets du projet (`keybuzz-stripe`, `keybuzz-api-postgres`, `redis-credentials`, etc.) :
- Secret K8s `keybuzz-shopify` créé dans namespace `keybuzz-api-dev`
- Contient : `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_ENCRYPTION_KEY`
- Deployment YAML référence via `secretKeyRef` (aucun secret en clair dans le code/manifests)
- Les valeurs non-sensibles (`SHOPIFY_REDIRECT_URI`, `SHOPIFY_CLIENT_REDIRECT_URL`) restent en `value:`

### Pourquoi K8s Secret et pas Vault direct
Le pattern opérationnel du projet utilise K8s Secrets comme mécanisme de livraison, même avec Vault/ESO disponible. Tous les autres secrets (Stripe, Postgres, Redis, MinIO, JWT, Auth) suivent ce pattern. Cohérence > complexité.

---

## 4. Flow OAuth réel validé

### App Shopify utilisée
- Nom : **KeyBuzz DEV**
- Redirect URL : `https://api-dev.keybuzz.io/shopify/callback`
- Scopes V1 : `read_orders,read_customers,read_fulfillments,read_returns`

### Flow testé (succès)
1. `/channels` → "Ajouter une marketplace" → Shopify → modal s'ouvre
2. Domaine saisi : `keybuzz-dev.myshopify.com`
3. "Connecter" → redirection Shopify OAuth
4. Autorisation accordée dans Shopify
5. Callback API → HMAC vérifié → token échangé → connexion sauvée
6. `tenant_channel` créé et activé automatiquement
7. Redirection `/channels?shopify_connected=true`
8. Bannière "Shopify connecté avec succès !" affichée
9. Shopify visible dans la liste des canaux comme canal normal

---

## 5. Preuve DB

### `shopify_connections`
```
id: 0a23fd59-0805-4308-9d2b-0fae04452952
tenant_id: keybuzz-mnqnjna8
shop_domain: keybuzz-dev.myshopify.com
status: active
created_at: 2026-04-08T23:02:38.138Z
```

### `tenant_channels`
```
id: 7b5a9e6f-12f2-4a39-95c0-18faa2bc7d84
tenant_id: keybuzz-mnqnjna8
marketplace_key: shopify-global
provider: shopify
display_name: Shopify
status: active
connected_at: 2026-04-08T23:02:38.198Z
connection_ref: 0a23fd59-... (lié à shopify_connections.id)
```

---

## 6. Multi-tenant

| Tenant | Shopify status | Résultat |
|--------|---------------|----------|
| `keybuzz-mnqnjna8` | `connected: true` | Connexion active |
| `ecomlg-001` | `connected: false` | Aucune connexion |
| `tenant-1772234265142` | `connected: false` | Aucune connexion |

- Isolation confirmée : 1 seul tenant a une connexion
- Aucune fuite cross-tenant de `shop_domain` ou `access_token`
- `connection_ref` lie correctement `tenant_channels` ↔ `shopify_connections`

---

## 7. Webhook reçu et logué

### Test HMAC invalide
- Requête avec HMAC factice → rejet `{"error":"HMAC verification failed"}` ✓

### Test HMAC valide
- HMAC calculé avec le vrai `SHOPIFY_CLIENT_SECRET`
- Topic : `orders/create`
- Résultat : `{"ok":true}` ✓

### DB `shopify_webhook_events`
```
id: 3ff58748-af88-4bfe-acff-97bab3fb5d9e
tenant_id: keybuzz-mnqnjna8
connection_id: 0a23fd59-0805-4308-9d2b-0fae04452952
topic: orders/create
processed: false
created_at: 2026-04-08T23:05:35.572Z
```
Total events : 1

---

## 8. Non-régression

| Endpoint | Résultat |
|----------|----------|
| `/health` | OK |
| `/messages/conversations` | OK (1+ conversations) |
| `/api/v1/orders` | OK (1+ orders) |
| `/ai/wallet/status` | OK (KBA: 931.3) |
| Channels catalog | Shopify présent (`coming_soon: false`) |
| PROD API | `v3.5.225-ph-playbooks-v2-prod` (inchangée) |
| PROD Client | `v3.5.225-ph-playbooks-v2-prod` (inchangée) |

---

## 9. Rollback

### Si rollback nécessaire
```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.227-ph-shopify-021-dev -n keybuzz-api-dev
# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.226-ph-shopify-02-dev -n keybuzz-client-dev
# Supprimer secret
kubectl delete secret keybuzz-shopify -n keybuzz-api-dev
```

### Nettoyage connexion test
```sql
UPDATE shopify_connections SET status='disconnected' WHERE tenant_id='keybuzz-mnqnjna8';
UPDATE tenant_channels SET status='removed' WHERE tenant_id='keybuzz-mnqnjna8' AND marketplace_key='shopify-global';
```

---

## 10. Reconnexion avec scopes V1

### Correction scopes (v3.5.228)

Les scopes initiaux (`read_orders,read_products,read_customers`) ont été mis à jour vers les scopes V1 demandés :

```
read_orders,read_customers,read_fulfillments,read_returns
```

- Image API : `v3.5.228-ph-shopify-021-scopes-dev`
- Le user s'est reconnecté avec les nouveaux scopes via l'UI

### Validation finale (2026-04-09 post-reconnexion)

| Check | Résultat |
|-------|---------|
| shopify_connections | `keybuzz-dev.myshopify.com`, status=active, id=`8f980a4f` |
| tenant_channels | `shopify-global`, status=active, connection_ref=`8f980a4f` |
| Multi-tenant ecomlg-001 | `connected: false` — isolation OK |
| Health | OK |
| Conversations | OK |
| Orders | OK |
| AI Wallet | OK (KBA: 931.3) |
| PROD | inchangée (`v3.5.225-ph-playbooks-v2-prod`) |

---

## 11. Verdict

**SHOPIFY UX NORMALIZED — REAL OAUTH ACTIVE — SCOPES V1 OK — DEV READY FOR PH-SHOPIFY-03**

### Prochaine étape

**PH-SHOPIFY-03** : Sync commandes Shopify → table `orders` + conversation auto-create

Prérequis remplis :
- [x] Shopify App créée (KeyBuzz DEV)
- [x] OAuth fonctionnel avec scopes V1 (`read_orders,read_customers,read_fulfillments,read_returns`)
- [x] Webhook reception validée
- [x] Connexion persistée en DB
- [x] Multi-tenant prouvé
- [x] UX Channels conforme (flow standard, pas de bloc dédié)
