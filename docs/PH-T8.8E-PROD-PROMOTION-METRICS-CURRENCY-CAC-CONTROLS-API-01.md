# PH-T8.8E-PROD — Promotion PROD Metrics Tenant Currency + CAC Exclusion Controls API

> **Date** : 2026-04-23
> **Environnement** : PROD
> **Image PROD** : `v3.5.106-metrics-settings-currency-exclusion-prod`
> **Digest** : `sha256:c415cf0272f53a86593f0ee68cdc8800151d71d92f7f89ac6f3fc2f5efcb7177`
> **Commit** : `808f2dae` (branche `ph147.4/source-of-truth`)
> **Image PROD précédente** : `v3.5.105-tenant-secret-store-ads-prod`
> **Admin PROD** : INCHANGÉ

---

## 1. PRÉFLIGHT

| Élément | Valeur |
|---------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `808f2dae` (PH-T8.8E) |
| Image API DEV validée | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| Image API PROD avant | `v3.5.105-tenant-secret-store-ads-prod` |
| Repo clean | Oui |
| Admin PROD | Inchangé |

---

## 2. VÉRIFICATION SOURCE

| Point | Résultat |
|-------|----------|
| `settings-routes.ts` présent | ✅ 6788 octets |
| `display_currency` dans routes.ts | ✅ 8 occurrences |
| RBAC `requireSuperAdmin` PATCH | ✅ 2 occurrences |
| `data_quality.internal_only` | ✅ `internal_only: true` |
| `VALID_DISPLAY_CURRENCIES` = EUR, GBP, USD | ✅ |
| `metricsSettingsRoutes` enregistré app.ts | ✅ import + register |
| Aucun `INSERT INTO ad_spend ` (global) | ✅ 0 occurrences routes + settings |

---

## 3. DB PROD

Table `metrics_tenant_settings` créée en PROD via `kubectl exec` :

```sql
CREATE TABLE IF NOT EXISTS metrics_tenant_settings (
  tenant_id TEXT PRIMARY KEY,
  metrics_display_currency TEXT NOT NULL DEFAULT 'EUR',
  exclude_from_cac BOOLEAN NOT NULL DEFAULT false,
  exclude_reason TEXT,
  updated_by TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

- Table additive, aucune migration destructive
- 0 rows avant déploiement

---

## 4. IMAGE PROD

| Élément | Valeur |
|---------|--------|
| Tag | `v3.5.106-metrics-settings-currency-exclusion-prod` |
| Digest | `sha256:c415cf0272f53a86593f0ee68cdc8800151d71d92f7f89ac6f3fc2f5efcb7177` |
| Commit | `808f2dae` |
| Build | `docker build --no-cache` (build-from-git) |
| Push | `ghcr.io/keybuzzio/keybuzz-api` |

---

## 5. GITOPS

- `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` mis à jour
- Déploiement via `kubectl apply -f` (pas de `kubectl set image`)
- Rollout OK : `deployment "keybuzz-api" successfully rolled out`

---

## 6. VALIDATION PROD

### 6.1 Settings Endpoints

| Test | Attendu | Résultat |
|------|---------|----------|
| GET /metrics/settings/tenants (vide) | `settings: []` | ✅ |
| PATCH KBC GBP (super_admin) | `metrics_display_currency: GBP` | ✅ `updated: true` |
| PATCH (media_buyer) | 403 rejeté | ✅ `super_admin role required` |
| GET single KBC | `source: database`, `GBP` | ✅ |
| PATCH exclude_from_cac=true | `exclude_from_cac: true` | ✅ |
| PATCH restore exclude=false | `exclude_from_cac: false, null` | ✅ restauré |
| Settings list après PATCH | 1 entry KBC | ✅ |

### 6.2 Devises KBC PROD

KBC PROD = `keybuzz-consulting-mo9zndlk` — spend réel : 760.76 GBP (24 jours, Meta Ads)

| Devise | total_display | total_eur | currency.display | currency.source | display_currency_source |
|--------|---------------|-----------|------------------|-----------------|-------------------------|
| EUR (query) | 875.41 | 875.41 | EUR | GBP | `query_param` |
| GBP (query) | 760.76 | 875.41 | GBP | GBP | `query_param` |
| USD (query) | — | — | USD | — | `query_param` |
| Sans param | 760.76 | 875.41 | GBP | GBP | `tenant_preference` |
| XXX | 400 `invalid_display_currency` | — | — | — | — |

**Conversion vérifiée** : 760.76 GBP × (1/0.86903 EUR/GBP) = 875.41 EUR ✅

### 6.3 Isolation

| Test | Résultat |
|------|----------|
| KBC scope `tenant` — source `ad_spend_tenant` | ✅ |
| romrauis non trouvé en PROD | ✅ |
| Global overview — `ad_spend_global` source | ✅ |
| `data_quality.internal_only: true` | ✅ |
| FX ECB — `eur_rates: {EUR:1, GBP:0.86903, USD:1.1733}` | ✅ |

### 6.4 Sécurité / Non-régression

| Test | Attendu | Résultat |
|------|---------|----------|
| Health | `{"status":"ok"}` | ✅ |
| Import meta sans tenant_id | 400 `TENANT_ID_REQUIRED` | ✅ |
| ad_spend global | 16 rows (inchangé) | ✅ |
| ad_spend_tenant | 24 rows | ✅ |
| Ad-accounts KBC | 1 account, token `(encrypted)` | ✅ |
| Ad-accounts token masqué | `token_ref: (encrypted)` | ✅ |
| KBC last_sync_at | `2026-04-23T09:01:19.214Z` | ✅ (sync récent) |
| DEV inchangé | `v3.5.106-metrics-settings-currency-exclusion-dev` | ✅ |

---

## 7. PREUVES ANTI-WRITE AD_SPEND GLOBAL

- 0 occurrences `INSERT INTO ad_spend ` dans le code
- `ad_spend` PROD : 16 rows avant et après déploiement
- Import meta sans `tenant_id` : bloqué 400
- Tout le spend KBC dans `ad_spend_tenant` (24 rows)

---

## 8. ROLLBACK PROD

### Via GitOps uniquement

```yaml
# Dans keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml :
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.105-tenant-secret-store-ads-prod
```

Puis :
```bash
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
```

- Table `metrics_tenant_settings` conservée (additive, pas de suppression)
- Les settings existants restent valides avec l'ancienne image (ignorés)

---

## 9. ÉTAT FINAL PROD

| Service | Image |
|---------|-------|
| API PROD | `v3.5.106-metrics-settings-currency-exclusion-prod` |
| API DEV | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| Admin PROD | Inchangé |
| Admin DEV | Inchangé |

### KBC PROD — État post-validation

| Setting | Valeur |
|---------|--------|
| `metrics_display_currency` | `GBP` |
| `exclude_from_cac` | `false` |
| `exclude_reason` | `null` |
| `updated_by` | `ludo.gonthier@gmail.com` |

---

## 10. PROCHAINE ÉTAPE

**Promotion Admin v2.11.6 en PROD** — l'API PROD est maintenant prête avec :
- `/metrics/settings/tenants` (GET, GET/:id, PATCH/:id)
- `display_currency` sur `/metrics/overview`
- `data_quality.internal_only` pour masquage bandeau
- `exclude_from_cac` pour contrôle Super Admin

L'Admin peut consommer ces endpoints sans modification API supplémentaire.

---

## VERDICT

**METRICS TENANT CURRENCY AND CAC EXCLUSION CONTROLS LIVE IN PROD — API READY FOR ADMIN V2.11.6**
