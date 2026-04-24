# PH-T8.3.1B — METRICS NO-DATA UI FIX

> Date : 20 avril 2026
> Statut : **DEV DEPLOYE — EN ATTENTE VALIDATION PROD**
> Version : v2.10.4-ph-t8-3-1b-metrics-no-data-fix-dev
> PROD : NON TOUCHEE

---

## Contexte

PH-T8.2 a introduit un mode strict sur l'API `/metrics/overview` :

- Les mock data ont ete purgees de `ad_spend`
- `cac` et `roas` retournent `null` quand `spend = 0`
- `spend.source` = `"no_data"` quand aucune donnee reelle
- Bloc `data_quality` ajoute

La page `/metrics` deployee en PH-T8.3.1 ne gerait pas ces cas et crashait.

---

## 1. Erreur console exacte

### Crash

```
TypeError: Cannot read properties of null (reading 'toFixed')
```

### Lignes fautives (3 occurrences)


| #   | Composant            | Code fautif            | Cause             |
| --- | -------------------- | ---------------------- | ----------------- |
| 1   | KPI card CAC         | `data.cac.toFixed(2)`  | `cac` est `null`  |
| 2   | KPI card ROAS        | `data.roas.toFixed(2)` | `roas` est `null` |
| 3   | Revenue vs Spend box | `data.roas.toFixed(2)` | `roas` est `null` |


### Problemes visuels supplementaires


| #   | Zone                   | Probleme                                                |
| --- | ---------------------- | ------------------------------------------------------- |
| 4   | Spend by Channel table | tbody vide + tfoot affiche (visuellement casse)         |
| 5   | Interface TypeScript   | `cac: number` au lieu de `number                        |
| 6   | Aucune indication      | L'utilisateur ne sait pas pourquoi les donnees manquent |


---

## 2. Cause racine

Le composant `/metrics/page.tsx` v2.10.3 supposait que tous les champs numeriques seraient toujours des `number` valides. Apres PH-T8.2, l'API retourne `null` pour `cac` et `roas` quand `spend.total = 0`.

---

## 3. Corrections appliquees

### A. Interface TypeScript

```diff
- cac: number;
- roas: number;
- spend: { total: number; by_channel: ChannelSpend[]; currency: string };
+ cac: number | null;
+ roas: number | null;
+ spend: { total: number; by_channel: ChannelSpend[]; currency: string; source?: string };
+ data_quality?: DataQuality;
```

### B. Guards null-safe

```diff
- value={`${data.cac.toFixed(2)} €`}
+ value={data.cac != null ? `${data.cac.toFixed(2)} €` : '—'}

- value={`${data.roas.toFixed(2)}x`}
+ value={data.roas != null ? `${data.roas.toFixed(2)}x` : '—'}
```

### C. Detection no-data

```typescript
const spendAvailable = data?.data_quality?.spend_available !== false
  && (data?.spend?.source !== 'no_data');
const hasChannels = (data?.spend?.by_channel?.length ?? 0) > 0;
```

### D. Banner d'alerte

Quand `spendAvailable = false`, affichage d'un banner ambre :

- "Aucune donnee reelle de depenses publicitaires disponible"
- "Les metriques CAC et ROAS seront disponibles une fois les APIs publicitaires connectees"

### E. KPI Spend card

```diff
- value={formatEur(data.spend.total)}
+ value={spendAvailable ? formatEur(data.spend.total) : '—'}
```

### F. Revenue vs Spend

- Barre Ad Spend : affiche "Donnees indisponibles — APIs publicitaires non connectees" au lieu d'une barre a 0%
- Box marge/ROAS : affiche "Marge et ROAS indisponibles sans donnees de depenses"

### G. Spend by Channel table

```diff
- <table>...</table>  (toujours affichee, meme vide)
+ {hasChannels ? <table>...</table> : <EmptyState ... />}
```

Empty state : "Les donnees par canal seront disponibles une fois les APIs publicitaires connectees"

---

## 4. Comportement final no-data

### Payload API actuel (DEV)

```json
{
  "cac": null,
  "roas": null,
  "spend": { "total": 0, "by_channel": [], "source": "no_data" },
  "data_quality": { "spend_available": false },
  "new_customers": 19,
  "revenue": { "mrr": 5952 }
}
```

### Rendu UI


| Element            | Affichage                                                   |
| ------------------ | ----------------------------------------------------------- |
| Banner             | "Aucune donnee reelle de depenses publicitaires disponible" |
| Spend total card   | "—"                                                         |
| New customers card | 19                                                          |
| MRR card           | 5 952 EUR                                                   |
| CAC card           | "—"                                                         |
| ROAS card          | "—"                                                         |
| Customers by Plan  | Pro: 10, Starter: 2, Autopilot: 7 (barres et total)         |
| Revenue vs Spend   | Barre MRR visible, barre Spend remplacee par message        |
| Marge/ROAS box     | "Marge et ROAS indisponibles sans donnees de depenses"      |
| Spend by Channel   | EmptyState : "Les donnees par canal seront disponibles..."  |


### Ce qui est preserve

- `new_customers` : affiche normalement
- `revenue.mrr` : affiche normalement
- `customers_by_plan` : barres et compteurs normaux
- `computed_at` : badge timestamp normal
- Filtres date : fonctionnels
- Bouton rafraichir : fonctionnel

### Ce qui est protege

- Pas de NaN
- Pas de Infinity
- Pas de barre cassee (width: NaN%)
- Pas de table vide avec footer
- Pas de null.toFixed()
- Pas de donnee fake reintroduite
- Pas de CAC/ROAS calcule localement

---

## 5. Fichiers modifies


| Fichier                             | Modification                                          |
| ----------------------------------- | ----------------------------------------------------- |
| `src/app/(admin)/metrics/page.tsx`  | Fix complet no-data (158 insertions, 94 suppressions) |
| `src/components/layout/Sidebar.tsx` | Version v2.10.3 → v2.10.4                             |


---

## 6. Deploiement DEV


| Element         | Valeur                                                                    |
| --------------- | ------------------------------------------------------------------------- |
| Admin commit    | `fd8a8531a65137f8e13856e34b70381672c5fbf4`                                |
| Infra commit    | `06673d1812bb9711bcb110cb6c3519e8067d7828`                                |
| Tag DEV         | `v2.10.4-ph-t8-3-1b-metrics-no-data-fix-dev`                              |
| Digest DEV      | `sha256:a1da397be18fbbb4349fd974e5d216639978745e308d46e8418102818a64c2b8` |
| Pages compilees | 37                                                                        |
| Middleware      | 49.7 KB                                                                   |
| Pod             | Running 1/1, 0 restarts                                                   |
| Build           | `build-admin-from-git.sh` (clean GitHub)                                  |


### Non-regression


| Page          | Statut                       |
| ------------- | ---------------------------- |
| `/login`      | 200 OK                       |
| `/`           | 307 (redirect login, normal) |
| `/metrics`    | 307 (RBAC redirect, normal)  |
| API sans auth | 307 (protege)                |


---

## 7. PROD

**NON TOUCHEE.**


| Element       | Valeur                        |
| ------------- | ----------------------------- |
| Image PROD    | `v2.10.2-ph-admin-87-16-prod` |
| Manifest PROD | Inchange                      |


---

## 8. Rollback DEV

```bash
sed -i 's|v2.10.4-ph-t8-3-1b-metrics-no-data-fix-dev|v2.10.3-ph-t8-3-1-metrics-dev|' \
  k8s/keybuzz-admin-v2-dev/deployment.yaml
git add -A && git commit -m "rollback admin DEV to v2.10.3" && git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
```

Image de rollback : `ghcr.io/keybuzzio/keybuzz-admin:v2.10.3-ph-t8-3-1-metrics-dev`

---

## 9. Documents lus


| Document                                | Present |
| --------------------------------------- | ------- |
| PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md     | OUI     |
| PH-T8.3.1-METRICS-UI-BASIC-REPORT.md    | OUI     |
| PH-T8.2-REAL-SPEND-TRUTH-01.md          | OUI     |
| PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md | OUI     |
| PH-ADMIN-87.16-LOGIN-SLOWNESS-FIX.md    | OUI     |


---

## Verdict

**METRICS NO-DATA UI SAFE — NO FAKE DATA — ADMIN V2 STABLE — ROLLBACK READY**

- TypeError null.toFixed() corrige (3 occurrences)
- Table vide geree (EmptyState)
- Banner informatif quand spend indisponible
- Donnees reelles preservees (MRR, customers)
- Aucune donnee fake reintroduite
- Aucun calcul CAC/ROAS cote frontend
- PROD intacte
- En attente validation Ludovic pour promotion PROD

