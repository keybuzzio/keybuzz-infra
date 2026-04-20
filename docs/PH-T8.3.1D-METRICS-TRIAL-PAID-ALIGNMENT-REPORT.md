# PH-T8.3.1D — Metrics Trial/Paid Alignment Report

**Date** : 2026-04-20
**Phase** : PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-01
**Environnement** : DEV déployé — PROD en attente validation
**Type** : Amélioration UI business metrics (aucune modif backend)

---

## 1. Résumé

Alignement de la page `/metrics` Admin V2 avec les données business introduites par :
- **PH-T8.2B** — Meta spend réel
- **PH-T8.2C** — EUR normalization
- **PH-T8.2D** — Trial vs Paid
- **PH-T8.2F** — Test account exclusion

---

## 2. Mapping Avant / Après

| KPI | Avant (champ) | Après (champ) | Impact |
|-----|--------------|---------------|--------|
| CAC | `data.cac` (blended) | `data.cac_detail.paid_eur ?? data.cac` | CAC réel business (paid only) |
| ROAS | `data.roas` | `data.roas_detail.value ?? data.roas` | Source explicite |
| Customers | `data.new_customers` (total seul) | `data.customers.signups/trial/paid` | Breakdown complet |
| Conversion | — (absent) | `data.conversion.trial_to_paid_rate` | Nouveau KPI |
| Data Quality | — (absent) | `data.data_quality.test_data_excluded` | Fiabilité visible |
| Test count | — (absent) | `data.data_quality.test_accounts_count` | Transparence |

---

## 3. Nouveaux Blocs UI

### 3.1 Data Quality Banner (vert, haut de page)
- Condition : `data.data_quality.test_data_excluded === true`
- Affichage : "Données réelles — X comptes test exclus"
- Icône : ShieldCheck (emerald)

### 3.2 KPI CAC (paid)
- Label : "CAC (paid)"
- Valeur : `cac_detail.paid_eur` (fallback `cac`)
- Format : `XXX.XX €`

### 3.3 KPI ROAS
- Source : `roas_detail.value` (fallback `roas`)
- Format : `X.XXx`

### 3.4 Customers Breakdown Card
- Barres horizontales : Signups / Trial / Paid
- Proportions relatives (max = signups)
- Couleurs : blue (signups) / amber (trial) / emerald (paid)

### 3.5 Trial → Paid Conversion
- Section dans le card Customers Breakdown
- Source : `data.conversion.trial_to_paid_rate`
- Format : pourcentage

---

## 4. Éléments Conservés (non-régression)

- Spend total (EUR)
- MRR
- New customers KPI
- Customers by Plan
- Revenue vs Spend (barres + marge + ROAS)
- Spend by Channel (table complète)
- FX conversion banner (bleu)
- No spend data banner (ambre)
- Filtres de dates
- Rafraîchissement
- Période info
- RBAC (super_admin, account_manager)

---

## 5. Interfaces TypeScript Ajoutées

```typescript
interface CacDetail {
  blended_eur: number | null;
  paid_eur: number | null;
  currency?: string;
}

interface RoasDetail {
  value: number | null;
  currency?: string;
}

interface CustomersBreakdown {
  signups: number;
  trial: number;
  paid: number;
  no_subscription?: number;
}

interface ConversionInfo {
  trial_to_paid_rate: number | null;
  snapshot?: { paid_all_time?: number; trial_all_time?: number };
}

// DataQuality étendu :
interface DataQuality {
  spend_available: boolean;
  customers_available: boolean;
  revenue_available: boolean;
  fx_available?: boolean;
  test_data_excluded?: boolean;
  test_accounts_count?: number;
  paid_customers_available?: boolean;
}
```

---

## 6. Preuves — Code Compilé DEV

| Vérification | Résultat |
|-------------|----------|
| `cac_detail` dans chunks | PRESENT |
| `paid_eur` dans chunks | PRESENT |
| `roas_detail` dans chunks | PRESENT |
| `test_data_excluded` dans chunks | PRESENT |
| `trial_to_paid_rate` dans chunks | PRESENT |
| Label `CAC (paid)` dans chunks | PRESENT |
| `Customers Breakdown` dans chunks | PRESENT |
| Version `v2.10.6` dans layout | PRESENT |
| Ancien `spend.total` (sans `_eur`) | ABSENT (clean) |

---

## 7. Preuves — API DEV Payload

```json
{
  "customers": { "signups": 1, "trial": 0, "paid": 1 },
  "conversion": { "trial_to_paid_rate": 1 },
  "cac_detail": { "blended_eur": 511.45, "paid_eur": 511.45 },
  "roas_detail": { "value": 0.97 },
  "data_quality": { "test_data_excluded": true, "test_accounts_count": 18 }
}
```

---

## 8. Version DEV

| Champ | Valeur |
|-------|--------|
| Tag | `v2.10.6-ph-t8-3-1d-metrics-trial-paid-dev` |
| Commit | `6485d185b4c5ead8da95549f6a9361d11a7a7a76` |
| Digest | `sha256:d0f910e0ac30eeff6a13496315b467fde146ba1b5eebf931fbcac61c3aa52d84` |
| Pod | `keybuzz-admin-v2-7c447f5995-59ffz` |
| Status | Running, 0 restarts |

---

## 9. Non-Régression DEV

| URL | Code | Attendu |
|-----|------|---------|
| `admin-dev.keybuzz.io/` | 307 | 307 (auth redirect) |
| `admin-dev.keybuzz.io/login` | 200 | 200 |
| `admin-dev.keybuzz.io/metrics` | 307 | 307 (RBAC) |
| `admin-dev.keybuzz.io/billing` | 307 | 307 |

---

## 10. PROD — Non Impactée

| Champ | Valeur |
|-------|--------|
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod` |
| Status | Running, stable |

---

## 11. Rollback DEV

```bash
# Image précédente DEV
TAG_PREV="v2.10.5-ph-t8-3-1c-metrics-currency-fix-dev"
cd /opt/keybuzz/keybuzz-infra
sed -i "s|image: ghcr.io/keybuzzio/keybuzz-admin:.*|image: ghcr.io/keybuzzio/keybuzz-admin:${TAG_PREV}|" k8s/keybuzz-admin-v2-dev/deployment.yaml
git add k8s/keybuzz-admin-v2-dev/deployment.yaml
git commit -m "ROLLBACK DEV: revert to ${TAG_PREV}"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev --timeout=120s
```

---

## 12. Verdict

**DEV OPÉRATIONNEL — CAC PAID — ROAS BUSINESS — TRIAL/PAID — DATA QUALITY — NO NAN — GITOPS SAFE — ROLLBACK READY**

En attente validation Ludovic pour PROD.

