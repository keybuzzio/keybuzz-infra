# PH-T8.8C-PROD-PROMOTION — Ad Accounts + Secret Store PROD

> **Date** : 23 avril 2026
> **Environnement** : PROD
> **Type** : promotion cumulative PH-T8.8B + PH-T8.8C
> **Tenant pilote** : KeyBuzz Consulting PROD (`keybuzz-consulting-mo9zndlk`)

---

## RÉSUMÉ

Promotion en PROD des routes `/ad-accounts` (CRUD + sync tenant-scoped Meta Ads) et du chiffrement AES-256-GCM des credentials ads. KBC PROD peut désormais synchroniser ses dépenses Meta Ads sans aucune dépendance à un token global.

---

## PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| Commit source | `e6733567` |
| Repo clean | Oui |
| Image API DEV validée | `v3.5.105-tenant-secret-store-ads-dev` |
| Image API PROD avant | `v3.5.103-ad-spend-global-import-lock-prod` |
| Admin PROD | `v2.11.3-metrics-tenant-scope-fix-prod` (inchangée) |
| Admin DEV | `v2.11.5-ad-accounts-ui-hardening-dev` (inchangé) |
| PROD /ad-accounts avant | Inexistant (404) |
| PROD ADS_ENCRYPTION_KEY | Non présent |
| PROD ad_platform_accounts | 1 row KBC, `has_token: false` |

## SOURCES RELUES

- `PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md`
- `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md`
- `PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md`
- `PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md`

---

## ÉTAPE 1 — SECRET PROD

| Attribut | Valeur |
|---|---|
| Namespace | `keybuzz-api-prod` |
| Secret name | `keybuzz-ads-encryption` |
| Key | `ADS_ENCRYPTION_KEY` |
| Algorithme | AES-256-GCM (256 bits / 64 hex) |
| Clé PROD ≠ DEV | Oui — générée avec `openssl rand -hex 32` |
| Clé dans rapport | Non — jamais exposée |

---

## ÉTAPE 2 — TOKEN_REF PROD KBC

| Attribut | Valeur |
|---|---|
| Tenant PROD | `keybuzz-consulting-mo9zndlk` |
| Account ID | `1485150039295668` |
| DB ID | `b8b89a18-aa86-4e34-9488-b53fc404b96a` |
| Procédure | Déchiffrement DEV → PATCH PROD via API |
| token_ref DB | `aes256gcm:...` (328 chars, chiffré) |
| GET /ad-accounts | `(encrypted)` |
| Token brut exposé | Jamais |

---

## ÉTAPE 3 — IMAGE PROD

| Attribut | Valeur |
|---|---|
| **Tag** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.105-tenant-secret-store-ads-prod` |
| **Digest** | `sha256:27d32ac3c05d5f2e2858a32052295ed4574cf271b2c2dc104f7332c52b8f97b1` |
| **Commit source** | `e6733567` |
| **Build** | `--no-cache`, build-from-git |

---

## ÉTAPE 4 — GITOPS PROD

| Fichier | Modification |
|---|---|
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | Image → `v3.5.105-tenant-secret-store-ads-prod` |
| idem | Ajout `ADS_ENCRYPTION_KEY` via secret `keybuzz-ads-encryption` |
| idem | Rollback commenté → `v3.5.103-ad-spend-global-import-lock-prod` |

Déploiement via `kubectl apply -f deployment.yaml` uniquement.

---

## ÉTAPE 5 — VALIDATION PROD API

| Test | Résultat | Détail |
|---|---|---|
| Health | **PASS** | `{"status":"ok"}` |
| GET /ad-accounts KBC | **PASS** | 1 compte, `token_ref: (encrypted)`, status: active |
| Cross-tenant eComLG | **PASS** | 0 comptes |
| POST /ad-accounts/:id/sync KBC | **PASS** | 16 rows, 445.20 GBP |
| ad_spend_tenant KBC rows | **PASS** | 16 rows, total 445.20 |
| ad_spend global | **PASS** | 0 nouvelles écritures |
| Metrics overview KBC | **PASS** | 200, données complètes (cac, roas, spend) |
| Metrics eComLG | **PASS** | Pas de fuite spend KBC |
| Import meta sans tenant | **PASS** | 400 `TENANT_ID_REQUIRED` |
| Legacy fallback META_ACCESS_TOKEN | **PASS** | Env existe mais non lu par le code (fallback supprimé) |

---

## ÉTAPE 6 — TOKEN SAFETY PROD

| Surface | Token absent ? | Preuve |
|---|---|---|
| GET /ad-accounts response | ✅ | `token_ref: (encrypted)` |
| PATCH /ad-accounts response | ✅ | `token_ref: (encrypted)` |
| Pod logs (tail 100) | ✅ | Aucun pattern `EAAG`/`EAAx` |
| last_error | ✅ | `null` |
| token_ref DB | ✅ | Commence par `aes256gcm:`, 328 chars |
| Rapport | ✅ | Aucun token brut |
| Fallback global | ✅ | Code `resolveToken()` ne lit plus `META_ACCESS_TOKEN` |

---

## ÉTAPE 7 — NON-RÉGRESSION PROD

| Vérification | Résultat |
|---|---|
| Health OK | ✅ |
| Metrics global | ✅ |
| Metrics tenant KBC | ✅ |
| Metrics eComLG | ✅ — pas de fuite |
| /metrics/import/meta sans tenant | ✅ — 400 |
| Outbound destinations | ✅ — intact |
| Admin PROD | ✅ — `v2.11.3-metrics-tenant-scope-fix-prod` |
| Client SaaS | ✅ — inchangé |
| DEV API | ✅ — `v3.5.105-tenant-secret-store-ads-dev` |

---

## ÉTAPE 8 — ROLLBACK PROD

### Procédure GitOps uniquement

```yaml
# keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.103-ad-spend-global-import-lock-prod
```

```bash
# Retirer ADS_ENCRYPTION_KEY du deployment.yaml si rollback complet
# Commit + push
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "ROLLBACK: PH-T8.8C-PROD → v3.5.103"
git push origin main

# Deploy
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

Le secret `keybuzz-ads-encryption` peut rester (non lu par l'ancienne image).
Le `token_ref` chiffré dans `ad_platform_accounts` restera mais sera ignoré.

---

## PROCHAINE ÉTAPE

- Promotion Admin PROD `v2.11.5-ad-accounts-ui-hardening-dev` → Admin PROD
- Documentation `/marketing/integration-guide` pour les Ads Accounts
- Planification scheduler automatique de sync

---

## VERDICT

**TENANT ADS SECRET STORE LIVE IN PROD — AD ACCOUNTS API READY — KBC META ADS SYNC TENANT-SCOPED — NO GLOBAL TOKEN DEPENDENCY — ADMIN PROD UNBLOCKED**
