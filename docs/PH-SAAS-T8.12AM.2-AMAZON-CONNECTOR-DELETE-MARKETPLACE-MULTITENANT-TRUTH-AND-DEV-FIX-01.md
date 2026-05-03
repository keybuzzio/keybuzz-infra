# PH-SAAS-T8.12AM.2 — Amazon Connector Delete & Marketplace Multi-tenant Truth — DEV Fix

> Phase : PH-SAAS-T8.12AM.2
> Date : 2026-05-04
> Type : audit vérité + correction DEV P0
> Verdict : **GO DEV FIX READY**

---

## Contexte utilisateur

Ludovic observe des régressions sur le tenant SWITAA SASU :
1. Connecteur Amazon FR supprimé, mais réapparaît après navigation
2. Deuxième suppression nécessaire pour disparition
3. Après ré-ajout, statut passe de "En attente" à "Connecté" sans nouveau OAuth
4. `/orders` continue d'échouer
5. OAuth Amazon ouvre Mexique au lieu de FR
6. Le connecteur affiché ne représente pas une autorisation exploitable

---

## Preflight

### Branches

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-api | `ph147.4/source-of-truth` | `7de73e7a` | Non | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `8942716` | Non | OK |
| keybuzz-infra | `main` | `000edbe` | Non | OK |

### Runtimes

| Service | DEV image | PROD image | Verdict |
|---------|-----------|------------|---------|
| API | `v3.5.148-amazon-connector-delete-marketplace-fix-dev` | `v3.5.137-conversation-order-tracking-link-prod` | OK — PROD inchangé |
| Client | `v3.5.150-amazon-connector-status-ux-dev` | `v3.5.148-shopify-official-logo-tracking-parity-prod` | OK — PROD inchangé |

### Health

- API DEV : `{"status":"ok"}` ✓
- PROD : runtimes vérifiés, images inchangées ✓

---

## Sources relues

- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `PH-SAAS-T8.12AM-AMAZON-ORDERS-SYNC-400-TRUTH-AUDIT-AND-DEV-FIX-01.md`
- `PH-SAAS-T8.12AM.1-AMAZON-CONNECTOR-PENDING-AFTER-OAUTH-TRUTH-AUDIT-AND-DEV-FIX-01.md`

---

## Cause racine

### Le self-healing AM.1 est un anti-pattern

Le patch AM.1 a introduit un self-healing dans le endpoint `GET /api/v1/marketplaces/amazon/status` :
- À chaque appel (lecture !), il cherche `inbound_connections` READY
- Si trouvé, il promeut automatiquement tout channel `pending` en `active`
- **AUCUNE garde** sur :
  - L'ancienneté des données `inbound_connections` (stale depuis 35 jours)
  - L'historique de suppression du channel
  - Le marketplace/pays mismatch
  - La validité réelle des tokens OAuth

### Chaîne de résurrection

```
1. User supprime channel → status = 'removed', disconnected_at = NOW()
2. User ré-ajoute Amazon FR → addChannel() UPSERT: 'removed' → 'pending'
3. Page reload → /status appelé → self-healing: 'pending' + READY → 'active' !!!
4. Channel "Connecté" SANS nouveau OAuth, données stale
```

### Données stale observées SWITAA

| Source | Timestamp | Âge |
|--------|-----------|-----|
| `inbound_connections.updatedAt` | 2026-03-29 | **35 jours** |
| `inbound_connections.countries` | `["FR","DE"]` | Peut être obsolète |
| Vault `created_at` | 2026-05-03 | Frais (OAuth récent) |

Le self-healing utilisait `inbound_connections` stale pour activer des channels.

---

## Audit DB sanitized

### SWITAA `tenant_channels` (6 rows)

| Channel | Status | disconnected_at | connection_ref | Verdict |
|---------|--------|----------------|---------------|---------|
| amazon-fr | active | NULL | conn_2e62... | Restauré (OK) |
| amazon-de | removed | 2026-04-20 | conn_2e62... | OK |
| shopify-global | removed | 2026-04-08 | NULL | OK |
| octopia-cdiscount-fr | removed | 2026-04-14 | NULL | OK |
| amazon-mx | removed | 2026-04-16 | cmo118... | MX historique |
| amazon-ie | removed | 2026-04-29 | NULL | OK |

### eComLG `tenant_channels` (7 active Amazon)

| Channel | Status | connection_ref | Verdict |
|---------|--------|---------------|---------|
| amazon-be | active | cmk5ty3... | OK — inchangé |
| amazon-es | active | cmk5ty3... | OK — inchangé |
| amazon-fr | active | cmk5ty3... | OK — inchangé |
| amazon-it | active | cmk5ty3... | OK — inchangé |
| amazon-nl | active | cmk5ty3... | OK — inchangé |
| amazon-pl | active | cmk5ty3... | OK — inchangé |
| amazon-uk | active | cmk5ty3... | OK — inchangé |

---

## Audit delete connector

| Action | Avant AM.2 | Après AM.2 |
|--------|-----------|------------|
| `removeChannel()` set status | `removed` | `removed` |
| `removeChannel()` set disconnected_at | NOW() | NOW() |
| `removeChannel()` clear connection_ref | ❌ Non | ✅ Oui — `NULL` |
| Ancien READY peut résurrection | ❌ Oui via self-healing | ✅ Non — self-healing supprimé |

---

## Audit self-healing AM.1

| Condition | Présente dans AM.1 | Suffisante | Décision AM.2 |
|-----------|-------------------|-----------|---------------|
| Channel `pending` | ✅ | ❌ (trop large) | Self-healing SUPPRIMÉ |
| `disconnected_at` vérifié | ❌ | N/A | N/A — supprimé |
| `inbound_connections` récent | ❌ | N/A | N/A — supprimé |
| Marketplace match | ❌ | N/A | N/A — supprimé |
| Callback OAuth récent | ❌ | N/A | N/A — supprimé |

**Décision** : Self-healing entièrement supprimé. Remplacé par un endpoint explicite `POST /channels/activate-amazon` appelé uniquement après callback OAuth.

---

## Audit marketplace / pays

### Données Vault SWITAA

| Clé | Valeur |
|-----|--------|
| marketplace_id | A13V1IB3VIYZZH (= Amazon FR) |
| region | eu-west-1 |
| seller_id | Présent |
| refresh_token | Présent |

### Historique MX

Le channel `amazon-mx` a été créé le 2026-04-16 et supprimé le même jour. La connexion OAuth a pu ouvrir un marketplace NA (Mexique) car Amazon renvoie les autorisations basées sur le **compte seller** connecté, pas sur le marketplace demandé par KeyBuzz.

### Conclusion marketplace

Le Vault contient les bonnes credentials FR. Le problème MX est un problème de compte Amazon du seller (ses credentials couvrent NA+EU). Le fix correct est dans le flow OAuth côté `keybuzz-backend` (hors scope de cette phase, lecture seule backend).

---

## Audit multi-tenant / hardcode

Recherche exhaustive effectuée dans :
- `compat/routes.ts` : aucun tenant/seller/marketplace hardcodé
- `channelsRoutes.ts` : aucun hardcode
- `channelsService.ts` : aucun hardcode
- `channels/page.tsx` : aucun hardcode
- `amazon.service.ts` : aucun hardcode

**Verdict** : Pas de hardcode trouvé. Le code est tenant-scoped via headers `X-Tenant-Id`.

---

## Patch appliqué

### API (3 fichiers)

| Fichier | Changement | Pourquoi |
|---------|-----------|----------|
| `compat/routes.ts` | Suppression self-healing AM.1 (25 lignes) | Un GET ne doit JAMAIS écrire en DB |
| `channelsRoutes.ts` | Ajout `POST /channels/activate-amazon` (57 lignes) | Activation explicite après OAuth |
| `channelsService.ts` | `removeChannel()` clear `connection_ref` | Empêcher référence stale |

### Client (3 fichiers)

| Fichier | Changement | Pourquoi |
|---------|-----------|----------|
| `app/channels/page.tsx` | Appel `activateAmazonChannels()` après `amazon_connected=true` | Activation explicite |
| `src/services/amazon.service.ts` | Ajout `activateAmazonChannels()` (32 lignes) | Service d'activation |
| `app/api/amazon/activate-channels/route.ts` | Nouvelle route BFF proxy (53 lignes) | Proxy vers API backend |

---

## Validation DEV

| Test | Attendu | Résultat |
|------|---------|----------|
| Status read-only (removed channel) | Pas de résurrection | **PASS** |
| Pending stays pending (no self-healing) | Status ne promeut pas | **PASS** |
| Explicit activate-amazon | Active le channel pending | **PASS** |
| Delete stable (connection_ref cleared) | Status removed, ref null | **PASS** |
| eComLG unchanged (7 channels) | 7 active Amazon | **PASS** |
| No resurrection after remove | Status ne ressuscite pas | **PASS** |
| eComLG status call safe | CONNECTED retourné | **PASS** |

---

## Non-régression

| Surface | Vérifié | Résultat |
|---------|---------|----------|
| eComLG Amazon connectors | ✅ | 7 active, inchangés |
| PROD API image | ✅ | `v3.5.137-conversation-order-tracking-link-prod` |
| PROD Client image | ✅ | `v3.5.148-shopify-official-logo-tracking-parity-prod` |
| Billing | ✅ | Aucune mutation |
| 17TRACK | ✅ | CronJob PROD non modifié |
| IA context | ✅ | Aucune modification |
| Shopify | ✅ | Logo Client PROD inchangé |
| Lifecycle | ✅ | Aucune modification |

---

## Build DEV

### API

- **Tag** : `ghcr.io/keybuzzio/keybuzz-api:v3.5.148-amazon-connector-delete-marketplace-fix-dev`
- **Digest** : `sha256:145c78ba038a1dd92f3a6e4c2c361efbd6fdbb6ad6435c0a25722bb50e959a1e`
- **Commit** : `7de73e7a` (branche `ph147.4/source-of-truth`)
- **Rollback** : `v3.5.147-amazon-oauth-pending-status-fix-dev`

### Client

- **Tag** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.150-amazon-connector-status-ux-dev`
- **Digest** : `sha256:0c87a9af58c6b684cab104da0ff587682ae955e86adbd0ec27f7ee2a11afa90c`
- **Commit** : `8942716` (branche `ph148/onboarding-activation-replay`)
- **Rollback** : `v3.5.148-shopify-official-logo-dev`

---

## GitOps DEV

| Manifest | Image mise à jour | Rollback |
|----------|------------------|----------|
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.148-amazon-connector-delete-marketplace-fix-dev` | `v3.5.147-amazon-oauth-pending-status-fix-dev` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.150-amazon-connector-status-ux-dev` | `v3.5.148-shopify-official-logo-dev` |

---

## Chemin de reconnexion SWITAA

1. Aller sur `/channels`
2. Si Amazon FR est supprimé : cliquer "Ajouter un canal" → "Amazon FR"
3. Cliquer "Connecter Amazon" → OAuth Amazon
4. Sélectionner le compte Amazon FR correct
5. Après callback, le client appelle `POST /channels/activate-amazon`
6. Le channel passe de `pending` à `active`
7. `/orders` pourra synchroniser si les credentials Vault sont valides pour FR

**Note** : Si Amazon ouvre le mauvais pays (MX au lieu de FR), c'est un problème côté compte Amazon du seller. Le channel restera `pending` et ne sera pas activé pour le mauvais marketplace.

---

## Gaps restants

| Gap | Impact | Priorité |
|-----|--------|----------|
| Le callback OAuth (`keybuzz-backend`) ne touche pas `tenant_channels` | L'activation dépend du client | Moyen — l'endpoint explicite compense |
| Pas de validation marketplace dans le callback | MX peut être stocké dans Vault | Moyen — hors scope (backend) |
| `inbound_connections` n'est pas invalidé par `removeChannel()` | Ancien READY reste en DB | Faible — ne cause plus de problème sans self-healing |

---

## Décision PROD future

**GO DEV FIX READY** — Prompt PROD séparé requis.

### Recommandations PROD

1. Build API PROD : `v3.5.148-amazon-connector-delete-marketplace-fix-prod`
2. Build Client PROD : `v3.5.150-amazon-connector-status-ux-prod`
3. Déployer API PROD en premier, puis Client PROD
4. Valider eComLG 7 channels active après deploy API
5. Valider SWITAA reconnect path après deploy Client
6. Rollback API : `v3.5.137-conversation-order-tracking-link-prod`
7. Rollback Client : `v3.5.148-shopify-official-logo-tracking-parity-prod`

---

## Résumé final

**AMAZON CONNECTOR DELETE AND MARKETPLACE TRUTH FIXED IN DEV — NO CONNECTOR RESURRECTION — OAUTH SELF-HEALING REMOVED — EXPLICIT ACTIVATION ENDPOINT — ECOMLG PRESERVED — SWITAA RECONNECT PATH HONEST — NO HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED**

| Critère | Résultat |
|---------|----------|
| Image API DEV | `v3.5.148-amazon-connector-delete-marketplace-fix-dev` |
| Digest API | `sha256:145c78ba...` |
| Image Client DEV | `v3.5.150-amazon-connector-status-ux-dev` |
| Digest Client | `sha256:0c87a9af...` |
| Commits API | `7de73e7a` |
| Commits Client | `8942716` |
| Commits Infra | Mis à jour |
| PROD inchangée | Oui |
| eComLG préservé | Oui — 7 channels active |
| SWITAA reconnect path | Oui — clair et honnête |
| Suppression stable | Oui — no resurrection |
| Self-healing supprimé | Oui — remplacé par activation explicite |
| Hardcoding | Aucun trouvé |
| Billing/tracking drift | Aucun |
| Rapport | `keybuzz-infra/docs/PH-SAAS-T8.12AM.2-AMAZON-CONNECTOR-DELETE-MARKETPLACE-MULTITENANT-TRUTH-AND-DEV-FIX-01.md` |
