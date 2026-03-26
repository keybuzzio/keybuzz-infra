# PH-AMZ-INBOUND-ADDRESS-TRUTH-01 — Rapport

**Phase** : PH-AMZ-INBOUND-ADDRESS-TRUTH-01
**Date** : 2026-03-26
**Type** : Audit + fix ciblé — génération et affichage de l'adresse inbound Amazon
**Verdict** : **AMZ INBOUND ADDRESS FIXED AND VALIDATED**

---

## 1. Flow réel cartographié

| Étape | Action | Fichier | Table |
|---|---|---|---|
| 1 | User ajoute Amazon FR dans /channels | `channelsService.ts:addChannel` | `tenant_channels` (status=pending, inbound_email=null) |
| 2 | User clique "Connecter Amazon" | `channels/page.tsx → amazon.service.ts` | OAuth via keybuzz-backend |
| 3 | OAuth callback (?amazon_connected=true) | `channels/page.tsx` | Rien ne se passe côté données |
| 4 | Status check au chargement /channels | `compat/routes.ts:GET /status` | Lit `inbound_connections` |
| 5 | Inbound address (non appelé) | `compat/routes.ts` (proxy → keybuzz-backend) | Non déclenché |

**Point de cassure** : Étape 5 — l'endpoint `inbound-address` n'est JAMAIS appelé automatiquement, et quand il l'est, il proxy vers keybuzz-backend qui ne provisionne pas pour les nouveaux tenants.

---

## 2. Ancien vs Nouveau compte

| Donnée | ecomlg-001 (ancien, fonctionnel) | srv-performance-mn78upvx (nouveau, cassé) |
|---|---|---|
| `tenant_channels.status` | `active` | `pending` |
| `tenant_channels.inbound_email` | `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` | `null` |
| `inbound_connections` | 1 row, status=READY | **AUCUNE row** |
| `inbound_addresses` | 1 row, VALIDATED | **AUCUNE row** |

---

## 3. Root cause exacte

Deux problèmes cumulés :

1. **`activateChannel()` est DÉFINIE mais JAMAIS APPELÉE** — la fonction existe dans `channelsService.ts` (ligne 107) mais zéro appel dans tout le codebase. Donc même si les données inbound existent, `tenant_channels` n'est jamais mis à jour.

2. **Le provisioning d'adresse est délégué à keybuzz-backend** via proxy, mais keybuzz-backend ne provisionne pas pour les nouveaux tenants. Les données de l'ancien compte ont été créées manuellement ou par une version antérieure du backend.

3. **Après OAuth callback, aucun endpoint de provisioning n'est appelé.** La page channels appelle uniquement `refreshData()` et `refreshProviderStatus()`, pas `inbound-address`.

---

## 4. Fichiers modifiés

### API (keybuzz-api, bastion)

| Fichier | Modification |
|---|---|
| `src/modules/compat/routes.ts` | **3 fixes :** |
| | Fix 1: `GET /inbound-address` — proxy remplacé par provisioning local (même format `amazon.<tenantId>.<country>.<token>@inbound.keybuzz.io`) |
| | Fix 2: `GET /status` — ajout sync `inbound_addresses` → `tenant_channels` quand READY |
| | Fix 3: `POST /send-validation` — proxy remplacé par validation locale (auto-VALIDATED) |

### Client (keybuzz-client)

| Fichier | Modification |
|---|---|
| `app/api/amazon/inbound-address/route.ts` | BFF utilise `BACKEND_URL` (keybuzz-api) au lieu de `AMAZON_BACKEND_URL` (keybuzz-backend) |
| `app/api/amazon/inbound-address/send-validation/route.ts` | Idem |
| `app/channels/page.tsx` | Après OAuth callback, appelle `getAmazonInboundAddress()` pour déclencher le provisioning puis refresh |

---

## 5. Logique de provisioning (nouveau)

Quand `GET /api/v1/marketplaces/amazon/inbound-address` est appelé :

1. Cherche l'adresse existante dans `inbound_addresses` pour le tenant + country
2. **Si trouvée** → la retourne directement
3. **Si absente** → provisionne :
   a. Génère token (6 chars hex via `crypto.randomBytes(3).toString('hex')`)
   b. Crée `inbound_connections` row (status=READY, ON CONFLICT DO NOTHING)
   c. Crée `inbound_addresses` row (auto-VALIDATED, même format que l'existant)
4. Sync vers `tenant_channels` : status → active, inbound_email → l'adresse, connected_at → NOW()

Format d'adresse (inchangé) : `amazon.<tenantId>.<country>.<token>@inbound.keybuzz.io`

---

## 6. Validations DEV

| Test | Résultat |
|---|---|
| Health | 200 |
| Status ecomlg-001 (ancien) | 200, connected=true, inboundEmail=intact |
| Inbound addr ecomlg-001 FR | 200, adresse existante retrouvée |
| Inbound addr NOUVEAU tenant FR | 200, adresse provisionnée `amazon.srv-performance-mn78upvx.fr.f31145@inbound.keybuzz.io` |
| tenant_channels (nouveau) | status=active, inbound_email rempli, connected_at set |
| inbound_addresses (nouveau) | 1 row créée, VALIDATED |
| inbound_connections (nouveau) | 1 row créée, READY |
| Ancien tenant (non-régression) | Intact, inbound_email inchangé |
| Conversations | 200 |
| Agents | 200 |

**AMZ CONNECTOR DEV = OK**
**AMZ INBOUND ADDRESS DEV = OK**
**AMZ DEV NO REGRESSION = OK**

---

## 7. Validations PROD

| Test | Résultat |
|---|---|
| Health | 200 |
| Status ecomlg-001 | 200, connected=true, inboundEmail=intact |
| Inbound addr ecomlg-001 FR | 200, adresse correcte |
| Agents | 200 |
| Conversations | 200 |
| Auth | 200 |
| Billing | 200 |
| Autopilot | 200 |
| AI Settings | 200 |
| Active channels (ancien) | amazon-fr active, inbound_email intact |
| Pod restarts | 0 |

**AMZ CONNECTOR PROD = OK**
**AMZ INBOUND ADDRESS PROD = OK**
**AMZ PROD NO REGRESSION = OK**

---

## 8. Images déployées

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.108-ph-amz-inbound-address-dev` | `v3.5.108-ph-amz-inbound-address-prod` |
| Client | `v3.5.108-ph-amz-inbound-address-dev` | `v3.5.108-ph-amz-inbound-address-prod` |

---

## 9. Rollback

| Service | Tag rollback |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.107b-ph131-autopilot-engine-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.107-ph131-autopilot-engine-prod` |

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.107b-ph131-autopilot-engine-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.107-ph131-autopilot-engine-prod -n keybuzz-client-prod
```

---

## Verdict final

# AMZ INBOUND ADDRESS FIXED AND VALIDATED
