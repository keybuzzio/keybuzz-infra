# PH-T8.8C — TENANT SECRET STORE ADS CREDENTIALS

> Date : 2026-04-25
> Agent : Cursor Executor (CE)
> Environnement : **DEV uniquement**
> Priorité : P0
> Branche API : `ph147.4/source-of-truth`
> Branche Infra : `main`
> Prérequis : PH-T8.8B (Meta Ads tenant sync foundation)

---

## VERDICT

**TENANT ADS SECRET STORE READY IN DEV — TOKEN_REF RESOLVABLE — NO GLOBAL META TOKEN DEPENDENCY — PROD UNTOUCHED**

---

## 0 — PRÉFLIGHT

| Élément | Valeur |
|---------|--------|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API (avant) | `a5797352` (PH-T8.8B) |
| HEAD API (après) | `e6733567` |
| Image DEV (avant) | `v3.5.104-meta-ads-tenant-sync-foundation-dev` |
| Image DEV (après) | `v3.5.105-tenant-secret-store-ads-dev` |
| Image PROD | `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |
| Repo API clean | Oui ✓ |
| Repo Infra clean | Oui ✓ |

### Rapports relus

| Rapport | Lu |
|---------|-----|
| PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md | ✓ |
| PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md | ✓ |
| PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md | ✓ (pattern `redactSecrets` réutilisé) |

### État avant

| Donnée | Valeur |
|--------|--------|
| KBC DEV `token_ref` | `NULL` — non exploitable |
| Fallback legacy | Actif — `META_ACCESS_TOKEN` env var pour account `1485150039295668` |
| Encryption helpers | Aucun existant |
| Vault | **DOWN** — inutilisable |

---

## 1 — AUDIT SECRET STRATEGY

### Options évaluées

| Option | Viable | Raison |
|--------|--------|--------|
| Vault transit | **Non** | Vault DOWN depuis janvier 2026 |
| Vault KV tenant-scoped | **Non** | Vault DOWN |
| DB chiffrement AES-256-GCM | **Oui** | crypto Node.js natif, clé via K8s secret |
| Env vars par tenant | **Non** | Ne scale pas, pas multi-tenant |

### Décision retenue

**AES-256-GCM en DB, clé d'encryption via K8s secret `ADS_ENCRYPTION_KEY`.**

Raisons :
1. Vault est DOWN — pas fiable pour PROD ni DEV
2. Pattern K8s secret déjà validé dans le projet (`SHOPIFY_ENCRYPTION_KEY`)
3. AES-256-GCM = chiffrement authentifié standard, résistant aux manipulations
4. Clé 256 bits (64 hex) générée par `openssl rand -hex 32`
5. Compatible PROD : il suffit de créer le même K8s secret en namespace PROD

### Compatibilité PROD

Pour promouvoir en PROD :
1. Créer le secret `keybuzz-ads-encryption` dans `keybuzz-api-prod`
2. Ajouter `ADS_ENCRYPTION_KEY` env var dans `deployment.yaml` PROD
3. Chiffrer le token Meta PROD avec la clé PROD
4. Stocker le token chiffré dans `ad_platform_accounts` PROD

### Prévention des fuites

| Surface | Protection |
|---------|------------|
| Réponse API GET | `maskToken()` → `(encrypted)` |
| Réponse API sync | Aucun champ token |
| Logs pod | `redactSecrets()` sur toutes les erreurs Meta |
| `last_error` DB | `redactSecrets()` avant INSERT |
| `token_ref` DB | Chiffré AES-256-GCM, jamais en clair |
| Rapport | Aucun token mentionné |

---

## 2 — TOKEN_REF EXPLOITABLE

### Fichier créé

`src/lib/ads-crypto.ts` (44 lignes)

### API

| Fonction | Signature | Usage |
|----------|-----------|-------|
| `encryptToken(plaintext)` | `string → string` | Chiffre un token → `aes256gcm:iv:tag:ciphertext` (base64) |
| `decryptToken(tokenRef)` | `string → string` | Déchiffre un `token_ref` chiffré → token original |
| `isEncryptedToken(tokenRef)` | `string → boolean` | Vérifie si le format est `aes256gcm:...` |

### Format stocké

```
aes256gcm:<iv_base64>:<tag_base64>:<ciphertext_base64>
```

- **IV** : 16 octets aléatoires (unique par chiffrement)
- **Tag** : 16 octets (authentification GCM)
- **Ciphertext** : token chiffré

### Clé d'encryption

| Propriété | Valeur |
|-----------|--------|
| Algorithme | AES-256-GCM |
| Taille clé | 256 bits (64 caractères hex) |
| Source | `ADS_ENCRYPTION_KEY` env var |
| Stockage | K8s secret `keybuzz-ads-encryption` |
| Génération | `openssl rand -hex 32` |

---

## 3 — AD ACCOUNTS API ADAPTATION

### Modifications

| Route | Modification |
|-------|-------------|
| `POST /ad-accounts` | Accepte `access_token` dans le body → `encryptToken()` → stocke `token_ref` |
| `PATCH /ad-accounts/:id` | Accepte `access_token` pour rotation → `encryptToken()` → met à jour `token_ref` |
| `GET /ad-accounts` | `maskToken()` retourne `(encrypted)` pour les refs chiffrées |
| `DELETE /ad-accounts/:id` | Inchangé (soft-delete) |

### Champ `access_token` (écriture)

Le champ `access_token` est accepté dans le body des requêtes POST et PATCH. Il est :
1. Chiffré immédiatement via `encryptToken()`
2. Stocké dans `token_ref` au format `aes256gcm:...`
3. **Jamais retourné** dans la réponse — la réponse montre `token_ref: "(encrypted)"`

### Champ `token_ref` (lecture)

Le champ `token_ref` n'est plus directement modifiable via l'API. Seul `access_token` permet de le mettre à jour.

---

## 4 — FALLBACK LEGACY SUPPRIMÉ

### Avant (PH-T8.8B)

```typescript
function resolveToken(accountId: string, tokenRef: string | null): string {
  if (accountId === LEGACY_FALLBACK_ACCOUNT_ID && !tokenRef && META_ACCESS_TOKEN_GLOBAL) {
    return META_ACCESS_TOKEN_GLOBAL;
  }
  throw new Error('TOKEN_NOT_RESOLVABLE');
}
```

### Après (PH-T8.8C)

```typescript
function resolveToken(tokenRef: string | null): string {
  if (!tokenRef) {
    throw new Error('TOKEN_NOT_SET: no token_ref configured for this ad account');
  }
  if (isEncryptedToken(tokenRef)) {
    return decryptToken(tokenRef);
  }
  throw new Error('TOKEN_FORMAT_INVALID: token_ref must be an encrypted reference');
}
```

### Changements clés

| Aspect | Avant | Après |
|--------|-------|-------|
| `META_ACCESS_TOKEN_GLOBAL` | Utilisé comme fallback | **Supprimé** du fichier |
| `LEGACY_FALLBACK_ACCOUNT_ID` | Hardcodé `1485150039295668` | **Supprimé** |
| `resolveToken` signature | `(accountId, tokenRef)` | `(tokenRef)` — plus besoin de `accountId` |
| Source du token | Env var globale ou token_ref | **Uniquement** `token_ref` chiffré |

La sync KBC DEV utilise désormais exclusivement le token chiffré stocké dans `ad_platform_accounts.token_ref`.

---

## 5 — VALIDATION DEV KEYBUZZ CONSULTING

| Cas | Attendu | Résultat |
|-----|---------|----------|
| A. GET /ad-accounts KBC | token masqué `(encrypted)` | ✓ `token_ref=(encrypted)` |
| B. GET /ad-accounts ecomlg | 0 comptes | ✓ 0 comptes |
| C. Sync KBC via token_ref | completed, no token | ✓ `sync=completed`, 0 rows, no token |
| D. ad_spend inchangé | 16 rows | ✓ 16 rows |
| E. ad_spend_tenant KBC | 16 rows, 445.20 | ✓ 16 rows, 445.20 GBP |
| F. Metrics overview KBC | source=ad_spend_tenant | ✓ 512.29 EUR, no NaN |
| G. Cross-tenant sync | 404 | ✓ HTTP 404 |

### Note sur la sync

`rows_upserted=0` : la Meta Marketing API ne retourne pas de données de dépenses pour la période avril 2026 (campagne inactive ou budget épuisé). Le token est bien résolu et l'appel API Meta est effectué avec succès — il n'y a simplement pas de données à importer. Les totaux (16 rows, 445.20 GBP, 512.29 EUR) proviennent du backfill historique PH-T8.8A.

---

## 6 — TOKEN SAFETY

| Surface | Token absent ? | Preuve |
|---------|----------------|--------|
| Réponse GET /ad-accounts | ✓ | `token_ref=(encrypted)` |
| Réponse POST /ad-accounts/:id/sync | ✓ | 0 pattern `EAA*` dans JSON |
| Logs pod (tail 200) | ✓ | 0 tokens bruts |
| `last_error` DB | ✓ | Aucune erreur stockée |
| `token_ref` DB | ✓ | Format `aes256gcm:...` (328 chars), **jamais en clair** |
| Code source | ✓ | `resolveToken` n'accepte que les refs chiffrées |
| Ce rapport | ✓ | Aucun token mentionné |

---

## 7 — NON-RÉGRESSION DEV

| Check | Résultat |
|-------|----------|
| Health API | ✓ `{"status":"ok"}` |
| `/metrics/overview` global | ✓ source=ad_spend_global, 512.29 EUR |
| `/metrics/overview?tenant_id=ecomlg-001` | ✓ source=no_data, scope=tenant, 0 EUR |
| `/metrics/overview?tenant_id=keybuzz-consulting-mo9y479d` | ✓ source=ad_spend_tenant, 512.29 EUR |
| `/metrics/import/meta` sans tenant | ✓ 400 TENANT_ID_REQUIRED |
| `ad_spend` global | ✓ 16 rows (inchangé) |
| `ad_spend_tenant` KBC | ✓ 16 rows, 445.20 GBP |
| Cross-tenant blocked | ✓ 404 |
| PROD API | ✓ `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |
| Admin V2 | ✓ Non modifié |
| Client SaaS | ✓ Non modifié |
| Stripe/billing | ✓ Non modifié |
| Outbound destinations | ✓ Non modifié |

---

## 8 — IMAGE DEV

| Élément | Valeur |
|---------|--------|
| Tag | `v3.5.105-tenant-secret-store-ads-dev` |
| Digest | `sha256:906e232f830efd67b220cf3a6af34411ff2c65e235c54f7508410081b61db032` |
| Build source | Commit `e6733567` (branche `ph147.4/source-of-truth`) |
| Build method | `docker build --no-cache` |
| Repo clean au build | Oui |
| tsc --noEmit | 0 erreurs |
| Commit infra | `44f0ebc` (keybuzz-infra main) |
| Restarts | 0 |

### Contenu cumulé

| Feature | Description |
|---------|-------------|
| PH-T8.8A | `/metrics/overview?tenant_id=X` lit `ad_spend_tenant` uniquement |
| PH-T8.8A.1 | `/metrics/import/meta` sans `tenant_id` → 400 |
| PH-T8.8B | CRUD `/ad-accounts` + adapter `meta-ads.ts` + sync tenant |
| **PH-T8.8C** | **AES-256-GCM secret store — token_ref résolvable, fallback legacy supprimé** |

### K8s Secret DEV

| Secret | Namespace | Clé |
|--------|-----------|-----|
| `keybuzz-ads-encryption` | `keybuzz-api-dev` | `ADS_ENCRYPTION_KEY` (256 bits, 64 hex) |

---

## ROLLBACK DEV

### Procédure GitOps uniquement

1. Modifier `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`
2. Remettre l'image précédente :

```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.104-meta-ads-tenant-sync-foundation-dev
```

3. Retirer l'env var `ADS_ENCRYPTION_KEY` si rollback complet
4. Commit + push keybuzz-infra
5. `kubectl apply -f` le manifest
6. Vérifier rollout

**AUCUN `kubectl set image` autorisé.**

### Note rollback

En cas de rollback vers T8.8B, le fallback legacy se réactivera automatiquement pour KBC DEV (account `1485150039295668`). Le token chiffré dans `token_ref` sera ignoré car T8.8B ne déchiffre pas, il utilise les env vars.

---

## COMMITS

| Repo | Hash | Message |
|------|------|---------|
| keybuzz-api | `e6733567` | PH-T8.8C: tenant secret store for ads credentials |
| keybuzz-infra | `44f0ebc` | PH-T8.8C: DEV deploy tenant-secret-store-ads v3.5.105 + ADS_ENCRYPTION_KEY env |

---

## HISTORIQUE IMAGES

| Env | Avant | Après |
|-----|-------|-------|
| DEV | `v3.5.104-meta-ads-tenant-sync-foundation-dev` | `v3.5.105-tenant-secret-store-ads-dev` |
| PROD | `v3.5.103-ad-spend-global-import-lock-prod` | Inchangé |

---

## FICHIERS CRÉÉS/MODIFIÉS

| Fichier | Action | Lignes |
|---------|--------|--------|
| `src/lib/ads-crypto.ts` | **Nouveau** | 44 |
| `src/modules/metrics/ad-platforms/meta-ads.ts` | Modifié | 91 (resolveToken sans fallback, import decryptToken) |
| `src/modules/ad-accounts/routes.ts` | Modifié | 239 (import encryptToken, access_token dans POST/PATCH) |

---

## PRÉREQUIS PROD

Pour promouvoir PH-T8.8C en PROD :

| Étape | Action |
|-------|--------|
| 1 | Créer K8s secret `keybuzz-ads-encryption` dans `keybuzz-api-prod` |
| 2 | Ajouter env var `ADS_ENCRYPTION_KEY` dans `deployment.yaml` PROD |
| 3 | Chiffrer le token Meta PROD avec la clé PROD (différente de DEV) |
| 4 | Stocker token chiffré dans `ad_platform_accounts` pour KBC PROD |
| 5 | Build image PROD avec le même code source |
| 6 | Déployer et valider |

**Important** : la clé PROD doit être **différente** de la clé DEV. Chaque environnement a sa propre clé de chiffrement.

---

## PROCHAINES ÉTAPES RECOMMANDÉES

| Phase | Description | Priorité |
|-------|-------------|----------|
| PH-T8.8C-PROD | Promotion PROD (secret store + chiffrement token KBC PROD) | P0 |
| PH-T8.8D | Scheduler auto-sync (CronJob par tenant) | P2 |
| PH-T8.8E | Google Ads adapter | P3 |
| PH-T8.8F | TikTok/LinkedIn adapters | P3 |
| PH-T8.8G | UI Admin V2 gestion comptes ads + rotation token | P2 |
| PH-VAULT-MIGRATION | Migration vers Vault transit quand Vault sera restauré | P3 |
