# PH-T8.8E — Metrics Tenant Currency and CAC Exclusion Controls API

> **Date** : 2026-04-23
> **Environnement** : DEV uniquement
> **Image** : `v3.5.106-metrics-settings-currency-exclusion-dev`
> **Digest** : `sha256:62ac263126847c9e7dbbbc95f51657be5fd4ea07ea4e0c15abeda9f78ec2165a`
> **Branche** : `ph147.4/source-of-truth`
> **Commit** : `808f2dae`
> **PROD** : INCHANGÉE (`v3.5.105-tenant-secret-store-ads-prod`)

---

## 1. OBJECTIF

Créer la fondation API/DB pour :
1. Permettre à chaque tenant de choisir la devise d'affichage de `/metrics`
2. Permettre au Super Admin de contrôler l'exclusion/inclusion CAC/ROAS par tenant
3. Préparer CE Admin à ajouter : sélecteur devise, contrôle exclusion CAC, masquage bandeau interne

---

## 2. PRÉFLIGHT

| Élément | Valeur |
|---------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `808f2dae` |
| Image DEV précédente | `v3.5.105-tenant-secret-store-ads-dev` |
| Image PROD | `v3.5.105-tenant-secret-store-ads-prod` |
| Repo clean | Oui |
| PROD touchée ? | Non |

---

## 3. AUDIT METRICS ACTUEL

| Sujet | Source avant PH-T8.8E | Problème | Décision |
|-------|----------------------|----------|----------|
| Exclusion CAC | `tenant_billing_exempt` uniquement | Pas de contrôle granulaire Super Admin | Ajout `metrics_tenant_settings.exclude_from_cac` |
| data_quality | Visible par tous dans la réponse API | Les tenants normaux voient "X compte test exclu" | Ajout `internal_only: true` pour masquage Admin UI |
| Devise affichage | Hardcodé EUR | KBC dépense en GBP mais affiche EUR | Ajout `display_currency` query param + préférence tenant |
| FX | GBP→EUR seulement via frankfurter/ECB | Pas de support USD ni EUR→GBP | Refactorisé en EUR-based rates (EUR/GBP/USD) |
| Spend tenant | `ad_spend_tenant` (depuis PH-T8.8A) | OK | Conservé, pas de changement |
| Spend global | `ad_spend` (mode global) | OK | Conservé, pas de changement |

---

## 4. SOURCE DE VÉRITÉ EXCLUSION CAC

### Table créée : `metrics_tenant_settings`

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

### Logique d'exclusion combinée

Un tenant est exclu des calculs CAC/ROAS si :
- `tenant_billing_exempt.exempt = true` (existant) **OU**
- `metrics_tenant_settings.exclude_from_cac = true` (nouveau)

Les deux sources coexistent : `tenant_billing_exempt` pour l'exemption billing, `metrics_tenant_settings` pour le contrôle fin Super Admin.

---

## 5. API SUPER ADMIN EXCLUSION CAC

### Endpoints créés

| Method | Route | RBAC | Description |
|--------|-------|------|-------------|
| GET | `/metrics/settings/tenants` | `super_admin`, `account_manager`, `media_buyer` | Liste tous les settings metrics |
| GET | `/metrics/settings/tenants/:tenant_id` | idem | Settings d'un tenant (defaults si absent) |
| PATCH | `/metrics/settings/tenants/:tenant_id` | `super_admin` uniquement | Modifier exclusion CAC / devise |

### Headers attendus (contrat CE Admin)

| Header | Usage |
|--------|-------|
| `x-user-email` | Obligatoire — identifie l'utilisateur |
| `x-admin-role` | Obligatoire — `super_admin` pour écriture, marketing roles pour lecture |
| `x-tenant-id` | Non requis (tenant_id dans URL params) |

### Réponse PATCH exemple

```json
{
  "setting": {
    "tenant_id": "ecomlg-001",
    "metrics_display_currency": "EUR",
    "exclude_from_cac": true,
    "exclude_reason": "test_account_excluded_from_cac",
    "updated_by": "ludo.gonthier@gmail.com",
    "updated_at": "2026-04-23T09:34:22.386Z",
    "tenant_name": "eComLG",
    "plan": "pro",
    "status": "active"
  },
  "updated": true
}
```

### Validation devise

Currencies supportées : `EUR`, `GBP`, `USD`. Toute autre valeur → 400 `invalid_currency`.

---

## 6. DEVISE D'AFFICHAGE TENANT

### Stockage

Champ `metrics_display_currency` dans `metrics_tenant_settings` (défaut : `EUR`).

### Résolution sur `/metrics/overview`

Priorité :
1. Query param `display_currency` → `"query_param"`
2. Préférence tenant dans `metrics_tenant_settings` → `"tenant_preference"`
3. Fallback `EUR` → `"default"`

### FX multi-devise

Taux ECB via `api.frankfurter.app/latest?from=EUR&to=GBP,USD` :
- Cache 6h
- Conversion : `source → EUR → display` via rates EUR-based
- Fallback hardcodé si API indisponible

---

## 7. ADAPTATION `/metrics/overview`

### Nouveau bloc `currency` dans la réponse

```json
{
  "currency": {
    "display": "GBP",
    "source": "GBP",
    "fx_applied": true,
    "rate": 0.86903,
    "rate_date": "2026-04-22",
    "provider": "ECB",
    "display_currency_source": "tenant_preference"
  }
}
```

### Nouveaux champs ajoutés (backward-compatible)

| Champ | Description |
|-------|-------------|
| `currency` | Bloc complet FX (display, source, rate, provider) |
| `revenue.mrr_display` | MRR converti en devise display |
| `revenue.currency_eur` | Rappel devise EUR pour MRR source |
| `spend.total_display` | Spend converti en devise display |
| `spend.by_channel[].spend_display` | Spend par canal en devise display |
| `cac_detail.blended` / `cac_detail.paid` | CAC en devise display |
| `fx.eur_rates` | Taux EUR-based (EUR, GBP, USD) |
| `data_quality.internal_only` | `true` → masquage recommandé pour non-Super Admin |

### Champs conservés (non-régression)

| Champ | Status |
|-------|--------|
| `spend.total_eur` | Conservé |
| `spend.by_channel[].spend_eur` | Conservé |
| `revenue.mrr` | Conservé (toujours EUR) |
| `cac` | Conservé (devise display) |
| `roas` | Conservé (devise display) |
| `data_quality.test_data_excluded` | Conservé |
| `data_quality.test_accounts_count` | Conservé |

---

## 8. DATA QUALITY / BANDEAU SUPER ADMIN

### `data_quality.internal_only: true`

Ce flag indique à l'Admin UI que les détails `test_data_excluded` et `test_accounts_count` sont **internes** et ne doivent être affichés qu'au Super Admin.

### Contrat CE Admin

- Si `data_quality.internal_only === true` ET rôle ≠ `super_admin` → masquer le bandeau "Données réelles — X compte test exclu"
- Le calcul reste correct en backend quel que soit le rôle
- L'affichage détaillé est réservé Super Admin

---

## 9. VALIDATION DEV

| Cas | Attendu | Résultat |
|-----|---------|----------|
| A — KBC display EUR | Spend source GBP, converti EUR (512.30€) | ✅ `total_eur: 512.3`, `total_display: 512.3`, `currency.display: EUR` |
| B — eComLG (pas de spend) | Aucun spend, aucune fuite KBC | ✅ `spend_available: false`, `total_eur: 0`, aucune fuite |
| C — KBC display GBP | Spend en GBP natif (445.20£), pas de conversion forcée | ✅ `total_display: 445.2`, `currency.display: GBP` |
| D — devise invalide XXX | Erreur 400 | ✅ `invalid_display_currency`, `Supported: EUR, GBP, USD` |
| E1 — Settings GET (marketing) | Liste vide initialement | ✅ `settings: []` |
| E2 — Settings PATCH (super_admin) | Exclusion CAC créée | ✅ `exclude_from_cac: true`, `updated_by: ludo.gonthier@gmail.com` |
| E3 — Settings PATCH (media_buyer) | Rejeté 403 | ✅ `super_admin role required` |
| E4 — Settings GET single | Retourne settings mises à jour | ✅ `source: database`, `exclude_from_cac: true` |
| E5 — Settings PATCH devise KBC | GBP enregistré | ✅ `metrics_display_currency: GBP` |
| E6 — KBC sans display_currency | Utilise préférence tenant (GBP) | ✅ `display_currency_source: tenant_preference`, `currency.display: GBP` |
| F1 — Global overview (non-régression) | CAC/ROAS calculés, spend global | ✅ `cac: 512.3`, `roas: 0.97`, `source: ad_spend_global` |
| F2 — ad_spend_tenant intègre | 16 rows, zéro write global | ✅ `ad_spend_tenant: 16`, `ad_spend: 16` (inchangé) |
| F3 — PROD inchangée | Image PROD = v3.5.105 | ✅ `v3.5.105-tenant-secret-store-ads-prod` |

---

## 10. PREUVES ANTI-FUITE SPEND GLOBAL

- `ad_spend` : 16 rows (identique avant/après)
- `ad_spend_tenant` : 16 rows (identique avant/après)
- Aucun nouveau write dans `ad_spend` pendant la validation
- Import Meta verrouillé sans `tenant_id` (400 `TENANT_ID_REQUIRED`)

---

## 11. PREUVES RBAC SUPER ADMIN

| Action | super_admin | media_buyer | Aucun header |
|--------|-------------|-------------|--------------|
| GET /metrics/settings/tenants | ✅ 200 | ✅ 200 | ❌ 403 |
| PATCH /metrics/settings/tenants/:id | ✅ 200 | ❌ 403 | ❌ 403 |

---

## 12. IMAGE DEV

| Élément | Valeur |
|---------|--------|
| Tag | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| Digest | `sha256:62ac263126847c9e7dbbbc95f51657be5fd4ea07ea4e0c15abeda9f78ec2165a` |
| Commit | `808f2dae` |
| Build | `docker build --no-cache` (build-from-git) |

---

## 13. ROLLBACK DEV

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.105-tenant-secret-store-ads-dev \
  -n keybuzz-api-dev
```

---

## 14. PROCHAINES ÉTAPES CE ADMIN

### À implémenter dans Admin V2

1. **Sélecteur devise** sur la page Metrics
   - API : `PATCH /metrics/settings/tenants/:tenant_id` avec `{ metrics_display_currency: "GBP" }`
   - UI : dropdown EUR/GBP/USD, enregistrement automatique
   - Query : passer `display_currency=` à `/metrics/overview` OU laisser la préférence tenant

2. **Contrôle exclusion CAC** dans le panneau Super Admin
   - API : `GET /metrics/settings/tenants` pour lister
   - API : `PATCH /metrics/settings/tenants/:tenant_id` avec `{ exclude_from_cac: true, exclude_reason: "..." }`
   - UI : toggle par tenant, champ raison optionnel

3. **Masquage bandeau "données de test"**
   - Condition : si `data_quality.internal_only === true` ET rôle ≠ `super_admin` → masquer
   - Le bandeau reste visible pour Super Admin

4. **Ordre menu Marketing** (correction optionnelle)

### Contrat API complet pour CE Admin

```
GET  /metrics/settings/tenants              → { settings: [...] }
GET  /metrics/settings/tenants/:tenant_id   → { setting: {...}, source: "database"|"default" }
PATCH /metrics/settings/tenants/:tenant_id  → { setting: {...}, updated: true }

Headers requis: x-user-email, x-admin-role
Lecture: super_admin, account_manager, media_buyer
Écriture: super_admin uniquement
```

---

## 15. FICHIERS MODIFIÉS

| Fichier | Action |
|---------|--------|
| `src/modules/metrics/settings-routes.ts` | **CRÉÉ** — routes settings tenants |
| `src/modules/metrics/routes.ts` | **MODIFIÉ** — display_currency, exclude_from_cac, multi-FX |
| `src/app.ts` | **MODIFIÉ** — import + register metricsSettingsRoutes |
| `metrics_tenant_settings` (table DB) | **CRÉÉE** — source de vérité exclusion + devise |

---

## VERDICT

**METRICS TENANT CURRENCY AND CAC EXCLUSION CONTROLS READY IN DEV — API SOURCE OF TRUTH ESTABLISHED — ADMIN UI READY TO CONNECT**
