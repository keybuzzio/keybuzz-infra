# PH-T8.3.1 — METRICS UI BASIC — Admin V2

> Date : 20 avril 2026
> Statut : **DEV DEPLOYE — EN ATTENTE VALIDATION PROD**
> Version : v2.10.3-ph-t8-3-1-metrics-dev
> PROD : NON TOUCHEE

---

## Objectif

Creer une page `/metrics` dans Admin V2 qui consomme l'endpoint existant `GET /metrics/overview` pour afficher les metriques business/marketing calculees cote API, sans modifier le backend SaaS.

---

## 1. Payload reel /metrics/overview

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 19,
  "customers_by_plan": { "pro": 10, "starter": 2, "autopilot": 7 },
  "revenue": { "mrr": 5952, "currency": "EUR" },
  "spend": {
    "total": 2715,
    "by_channel": [
      { "channel": "google", "spend": 950, "impressions": 40500, "clicks": 1330 },
      { "channel": "meta", "spend": 750, "impressions": 60000, "clicks": 1760 },
      { "channel": "linkedin", "spend": 600, "impressions": 15000, "clicks": 410 },
      { "channel": "tiktok", "spend": 415, "impressions": 75000, "clicks": 980 }
    ],
    "currency": "EUR"
  },
  "cac": 142.89,
  "roas": 2.19,
  "computed_at": "2026-04-20T08:56:22.046Z"
}
```

Audit complet : voir `PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`

---

## 2. Mapping API → UI


| Champ API                      | Element UI               | Format                                             |
| ------------------------------ | ------------------------ | -------------------------------------------------- |
| `spend.total`                  | KPI Card "Spend total"   | EUR format                                         |
| `new_customers`                | KPI Card "New customers" | Nombre                                             |
| `revenue.mrr`                  | KPI Card "MRR"           | EUR format                                         |
| `cac`                          | KPI Card "CAC"           | EUR 2 decimales                                    |
| `roas`                         | KPI Card "ROAS"          | x.xx format                                        |
| `customers_by_plan`            | Bloc barres horizontales | Plan + count + barre                               |
| `revenue.mrr` vs `spend.total` | Bloc Revenue vs Spend    | Barres comparatives + marge + ROAS                 |
| `spend.by_channel`             | Table Spend by Channel   | Channel + Spend + Impressions + Clicks + CTR + CPC |
| `period`                       | Footer + filtres date    | DD/MM/YYYY                                         |
| `computed_at`                  | Badge header             | DD/MM/YYYY HH:MM:SS                                |


---

## 3. RBAC

### Route `/metrics`


| Role              | Acces | Sidebar visible |
| ----------------- | ----- | --------------- |
| `super_admin`     | OUI   | OUI             |
| `account_manager` | OUI   | OUI             |
| `ops_admin`       | NON   | NON             |
| `finance_admin`   | NON   | NON             |
| `agent`           | NON   | NON             |


### Protection


| Couche      | Fichier                    | Methode                            |
| ----------- | -------------------------- | ---------------------------------- |
| Middleware  | `src/middleware.ts`        | Redirect si role non autorise      |
| API route   | `route.ts`                 | 403 Forbidden si role non autorise |
| Navigation  | `src/config/navigation.ts` | Masque l'entree sidebar            |
| RBAC config | `src/config/rbac.ts`       | Matrice des acces                  |


---

## 4. Fichiers crees/modifies

### Nouveaux


| Fichier                                       | Description                           | Taille        |
| --------------------------------------------- | ------------------------------------- | ------------- |
| `src/app/api/admin/metrics/overview/route.ts` | Proxy API vers SaaS /metrics/overview | 1 533 octets  |
| `src/app/(admin)/metrics/page.tsx`            | Page UI complete                      | 15 583 octets |


### Modifies


| Fichier                             | Modification                                             |
| ----------------------------------- | -------------------------------------------------------- |
| `src/config/rbac.ts`                | Ajout `/metrics: ['super_admin', 'account_manager']`     |
| `src/middleware.ts`                 | Ajout `/metrics: ['super_admin', 'account_manager']`     |
| `src/config/navigation.ts`          | Ajout entree Metrics (icone TrendingUp) dans Supervision |
| `src/components/layout/Sidebar.tsx` | Import TrendingUp + version v2.10.3                      |


---

## 5. Architecture

```
[Navigateur admin-dev.keybuzz.io/metrics]
       |
       v
  Page /metrics (client component)
       |
       v
  fetch('/api/admin/metrics/overview?from=...&to=...')
       |
       v
  API route (server-side, RBAC check)
       |
       v
  fetch('https://api-dev.keybuzz.io/metrics/overview?from=...&to=...')
       |
       v
  SaaS API (keybuzz-api) → PostgreSQL
       |
       v
  JSON response → UI rendering
```

---

## 6. UI

### Header

- Titre : "Metrics"
- Description : "Metriques business et marketing — donnees API temps reel"
- Filtre date (from / to) avec inputs type date
- Bouton Rafraichir (avec animation spin pendant le chargement)
- Badge computed_at

### KPI Cards (5 colonnes)

- Spend total (DollarSign)
- New customers (Users)
- MRR (TrendingUp)
- CAC (Target)
- ROAS (BarChart3)

### Customers by Plan

- Barres horizontales (Starter: bleu, Pro: vert, Autopilot: ambre)
- Pourcentage visuel
- Total

### Revenue vs Spend

- Barre MRR (vert emeraude)
- Barre Ad Spend (rose)
- Marge brute calculee (vert si positif, rouge si negatif)
- ROAS affiche

### Spend by Channel

- Table complete avec colonnes : Channel, Spend, Impressions, Clicks, CTR, CPC
- Pastille couleur par canal (Google: bleu, Meta: bleu fonce, LinkedIn: bleu LinkedIn, TikTok: noir)
- Ligne Total en pied de table
- CTR et CPC calcules a partir des donnees API (pas de logique metier ajoutee)

### UX States

- Loading : indicateur de chargement
- Error : message + bouton retry
- Empty : message informatif
- Refresh : animation spin sur le bouton

---

## 7. Deploiement DEV


| Element         | Valeur                                                                    |
| --------------- | ------------------------------------------------------------------------- |
| Commit admin    | `dfcf23157b9ace7e82e47b7cef0cf25e913af1a8`                                |
| Commit infra    | `179070760a9af5ce6676c4bac90859d100600659`                                |
| Tag DEV         | `v2.10.3-ph-t8-3-1-metrics-dev`                                           |
| Digest DEV      | `sha256:27a66f68991be15c2dd4cda3030a07b87670515ddb6526e2f3fa016d0fea2286` |
| Pages compilees | 37 (36 existantes + /metrics)                                             |
| Middleware      | 49.7 KB                                                                   |
| Pod             | Running 1/1, 0 restarts                                                   |
| Build method    | `build-admin-from-git.sh` (clone propre GitHub)                           |


### Non-regression


| Page            | Statut                            |
| --------------- | --------------------------------- |
| `/login`        | 200 OK                            |
| `/` (dashboard) | 307 → login (normal sans session) |
| `/metrics`      | 307 → login (RBAC OK)             |
| API sans auth   | 307 (protection middleware OK)    |


---

## 8. PROD

**NON TOUCHEE.**


| Element       | Valeur                        |
| ------------- | ----------------------------- |
| Image PROD    | `v2.10.2-ph-admin-87-16-prod` |
| Manifest PROD | Inchange                      |
| Impact PROD   | AUCUN                         |


---

## 9. Rollback DEV

```bash
# 1. Modifier manifest DEV
sed -i 's|v2.10.3-ph-t8-3-1-metrics-dev|v2.10.2-ph-admin-87-16-dev|' \
  k8s/keybuzz-admin-v2-dev/deployment.yaml

# 2. Commit + push
git add -A && git commit -m "rollback admin DEV to v2.10.2" && git push origin main

# 3. Apply
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
```

Image de rollback : `ghcr.io/keybuzzio/keybuzz-admin:v2.10.2-ph-admin-87-16-dev`

---

## 10. Documents lus


| Document                                              | Present | Utilise                                  |
| ----------------------------------------------------- | ------- | ---------------------------------------- |
| PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md           | OUI     | Payload de reference, formules, schema   |
| PH-T7.2.4-GA4-MP-CONFIG-PROD-FINAL-01.md              | OUI     | Context canaux tracking                  |
| PH-T7.2.3-SAAS-API-TIKTOK-PROD-PROMOTION-01.md        | OUI     | Context TikTok canal                     |
| PH-T7.3.2-REPLAY-LINKEDIN-ON-VALID-BRANCHES-DEV-01.md | OUI     | Context LinkedIn canal                   |
| PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md               | OUI     | Pipeline build, GitOps, version actuelle |
| PH-ADMIN-87.16-LOGIN-SLOWNESS-FIX.md                  | OUI     | Derniere version admin (v2.10.2)         |


---

## Verdict

**METRICS UI BASIC READY — ADMIN V2 SAFE — BUILD SAFE — ROLLBACK READY**

- Page /metrics deployee en DEV
- Consomme proprement l'endpoint SaaS existant
- RBAC super_admin + account_manager
- Aucune modification backend SaaS
- PROD intacte
- En attente validation Ludovic pour promotion PROD

