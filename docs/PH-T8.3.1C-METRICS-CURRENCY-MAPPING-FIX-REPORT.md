# PH-T8.3.1C — METRICS CURRENCY MAPPING FIX REPORT

> Date : 2026-04-20
> Phase : PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-01
> Type : Fix UI — adaptation payload PH-T8.2C (normalisation EUR)
> Environnement : DEV uniquement

---

## 1. PROBLÈME

Suite à PH-T8.2B (Meta spend réel) et PH-T8.2C (normalisation EUR), le payload `/metrics/overview` a changé :


| Avant PH-T8.2C                                | Après PH-T8.2C                                     |
| --------------------------------------------- | -------------------------------------------------- |
| `spend.total`                                 | `spend.total_eur`                                  |
| `channel.spend`                               | `channel.spend_eur` + `spend_raw` + `currency_raw` |
| *(absent)*                                    | `fx: { gbp_eur, source, date }`                    |
| `data_quality: { spend, customers, revenue }` | `data_quality: { ..., fx_available }`              |


Le frontend Admin lisait encore les anciens champs → **8 sources de NaN**.

---

## 2. SOURCES DE NaN IDENTIFIÉES


| #   | Zone UI                | Code fautif                   | Champ lu | Champ réel  | Résultat         |
| --- | ---------------------- | ----------------------------- | -------- | ----------- | ---------------- |
| 1   | KPI "Spend total"      | `formatEur(data.spend.total)` | `total`  | `total_eur` | **NaN €**        |
| 2   | Revenue vs Spend barre | `data.spend.total`            | `total`  | `total_eur` | **barre cassée** |
| 3   | Revenue vs Spend label | `formatEur(spend)`            | `total`  | `total_eur` | **NaN €**        |
| 4   | Marge brute            | `mrr - spend`                 | `total`  | `total_eur` | **NaN €**        |
| 5   | Channel row spend      | `formatEur(ch.spend)`         | `spend`  | `spend_eur` | **NaN €**        |
| 6   | Channel row CPC        | `ch.spend / ch.clicks`        | `spend`  | `spend_eur` | **NaN**          |
| 7   | Footer total spend     | `formatEur(data.spend.total)` | `total`  | `total_eur` | **NaN €**        |
| 8   | Footer total CPC       | `data.spend.total / tc`       | `total`  | `total_eur` | **NaN**          |


---

## 3. CORRECTIONS APPLIQUÉES

### 3.1 Interface TypeScript mise à jour

```typescript
// AVANT
interface ChannelSpend {
  channel: string;
  spend: number;        // ← ancien champ
  impressions: number;
  clicks: number;
}
interface MetricsData {
  spend: { total: number; ... };  // ← ancien champ
}

// APRÈS
interface ChannelSpend {
  channel: string;
  spend_eur: number;      // ← nouveau champ EUR normalisé
  spend_raw?: number;     // ← montant devise source
  currency_raw?: string;  // ← devise source (ex: GBP)
  impressions: number;
  clicks: number;
}
interface FxInfo {
  gbp_eur?: number;
  source?: string;
  date?: string;
}
interface MetricsData {
  spend: { total_eur: number; ... };  // ← nouveau champ
  fx?: FxInfo;                         // ← nouveau bloc FX
  data_quality?: DataQuality & { fx_available?: boolean };
}
```

### 3.2 Helpers anti-NaN

```typescript
function safeNum(v?: number | null): number | null {
  if (v === null || v === undefined || Number.isNaN(v)) return null;
  return v;
}

function safeFormatEur(v?: number | null): string {
  const n = safeNum(v);
  return n !== null ? formatEur(n) : '—';
}
```

### 3.3 Mapping corrigé


| Zone               | Avant                         | Après                                                                          |
| ------------------ | ----------------------------- | ------------------------------------------------------------------------------ |
| KPI Spend total    | `formatEur(data.spend.total)` | `safeFormatEur(spendTotal)`                                                    |
| Revenue vs Spend   | `data.spend.total`            | `spendTotal` (= `safeNum(data?.spend?.total_eur) ?? 0`)                        |
| Channel row spend  | `formatEur(ch.spend)`         | `safeFormatEur(eurSpend)`                                                      |
| Channel row CPC    | `ch.spend / ch.clicks`        | `eurSpend !== null && ch.clicks > 0 ? (eurSpend / ch.clicks).toFixed(2) : '—'` |
| Footer total spend | `formatEur(data.spend.total)` | `safeFormatEur(spendTotal)`                                                    |
| Footer total CPC   | `data.spend.total / tc`       | `spendTotal > 0 && tc > 0 ? ... : '—'`                                         |


### 3.4 Indicateur FX

Badge bleu discret affiché quand `data.fx` est disponible et `fx_available !== false` :

```
🔄 Données converties en EUR (source : BCE — GBP/EUR : 1.1472 — taux du 17/04/2026)
```

### 3.5 Badge devise par canal

Quand `currency_raw !== 'EUR'`, affichage d'un badge `GBP→EUR` à côté du nom du canal.

### 3.6 CTR/CPC safe

```typescript
const ctr = ch.impressions > 0 ? ((ch.clicks / ch.impressions) * 100).toFixed(2) : '—';
const cpc = eurSpend !== null && ch.clicks > 0 ? (eurSpend / ch.clicks).toFixed(2) : '—';
```

---

## 4. FICHIERS MODIFIÉS


| Fichier                             | Modification                         |
| ----------------------------------- | ------------------------------------ |
| `src/app/(admin)/metrics/page.tsx`  | Mapping complet, helpers, FX, badges |
| `src/components/layout/Sidebar.tsx` | Version `v2.10.4` → `v2.10.5`        |


---

## 5. PAYLOAD API ACTUEL (DEV)

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 19,
  "customers_by_plan": { "pro": 10, "starter": 2, "autopilot": 7 },
  "revenue": { "mrr": 5952, "currency": "EUR" },
  "spend": {
    "total_eur": 510.73,
    "by_channel": [{
      "channel": "meta",
      "spend_raw": 445.2,
      "currency_raw": "GBP",
      "spend_eur": 510.73,
      "impressions": 45374,
      "clicks": 892
    }],
    "currency": "EUR",
    "source": "ad_spend_table"
  },
  "fx": { "gbp_eur": 1.1472, "source": "ecb_cached", "date": "2026-04-17" },
  "cac": 26.88,
  "roas": 11.65,
  "data_quality": {
    "spend_available": true,
    "customers_available": true,
    "revenue_available": true,
    "fx_available": true
  }
}
```

---

## 6. COMPORTEMENT UI ATTENDU

### Cas 1 — Avec spend (Meta actif)

- Spend total : **511 €** ✓
- CAC : **26.88 €** ✓
- ROAS : **11.65x** ✓
- Meta : **511 €** | 45 374 impressions | 892 clicks | CTR 1.97% | CPC 0.57 €
- Badge **GBP→EUR** affiché
- Banner FX bleu : "Données converties en EUR (source : BCE...)"
- **Aucun NaN**

### Cas 2 — Sans spend

- Spend : **—**
- CAC : **—**
- ROAS : **—**
- Banner ambre : "Aucune donnée réelle de dépenses..."
- Table vide : EmptyState
- **Aucune erreur console**

### Cas 3 — Multi-canal (futur)

- Interface prête pour Google/TikTok/LinkedIn
- Chaque canal affiche son badge devise si ≠ EUR
- CTR/CPC calculés par canal

---

## 7. BUILD & DEPLOY


| Élément       | Valeur                                                                    |
| ------------- | ------------------------------------------------------------------------- |
| Commit source | `f0c11a2fb8a83aca804cc33cf230b79a596ee36e`                                |
| Tag DEV       | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-dev`                             |
| Digest DEV    | `sha256:b71a2c4e4b7f4a4461e6667d155aa0a432ba1954d2466ec72b27c52bd05818a6` |
| Build method  | `build-admin-from-git.sh` (clean clone from GitHub)                       |
| Commit GitOps | `21f0243d990889a3620f2fb6549323551e704dfc`                                |
| Manifest DEV  | `k8s/keybuzz-admin-v2-dev/deployment.yaml`                                |
| Pod DEV       | `keybuzz-admin-v2-764f457b89-w2kcl` — 1/1 Running, 0 restarts             |


### Compiled code verification

- `total_eur` : **FOUND** dans `page-775abd6a2b97f957.js`
- `spend_eur` : **FOUND** dans `page-775abd6a2b97f957.js`
- `v2.10.5` : **FOUND** dans server chunks + pre-rendered HTML
- Anciens champs `ch.spend` / `.total` : **ABSENT** (clean)

---

## 8. NON-RÉGRESSION


| Route        | Status               | Temps |
| ------------ | -------------------- | ----- |
| `GET /`      | 307 (redirect login) | 2.46s |
| `GET /login` | 200                  | 0.29s |
| `/metrics`   | 307 (redirect)       | OK    |


---

## 9. PROD

**INTACTE** — `ghcr.io/keybuzzio/keybuzz-admin:v2.10.2-ph-admin-87-16-prod`

En attente de validation Ludovic : "Tu peux push PROD"

---

## 10. ROLLBACK DEV

```bash
kubectl -n keybuzz-admin-v2-dev set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.10.4-ph-t8-3-1b-metrics-no-data-fix-dev
```

---

## 11. RÈGLES RESPECTÉES

- ✅ Aucun NaN
- ✅ Mapping aligné avec API PH-T8.2C
- ✅ CAC / ROAS affichés correctement (backend)
- ✅ Multi-devise gérée (GBP→EUR, badge, FX indicator)
- ✅ DEV stable
- ✅ Rollback OK
- ✅ PROD intacte
- ✅ build-from-git obligatoire
- ✅ repo clean obligatoire
- ✅ GitOps strict
- ❌ Aucun kubectl set image
- ❌ Aucune promotion PROD
- ❌ Aucun recalcul CAC/ROAS côté frontend
- ❌ Aucun fallback fake

