# PH-ADMIN-87.9A — Real Data Enforcement & Tenants Module Cleanup

> Date : 2026-03-21
> Auteur : Cursor Executor
> Statut : **GO — v2.1.8 VALIDÉ DEV + PROD**

---

## 1. Résumé exécutif

Le module Tenants de l'Admin v2 était intégralement un **placeholder statique** : aucun fetch API, aucune donnée réelle, des KPI vides ("—"), un message "sera connecté plus tard".

**Ce qui a été fait :**
- Suppression complète de tous les placeholders, mocks et faux KPI
- Création de 3 nouveaux endpoints API réels branchés sur PostgreSQL
- Réécriture complète de la page `/tenants` avec données temps réel
- Création de la page `/tenants/[id]` (détail tenant)
- Enrichissement du service avec 4 nouvelles méthodes DB
- Ajout de 2 nouveaux types TypeScript
- Validation triple preuve DB → API → UI sur DEV et PROD
- MRR retiré (non calculable depuis le schéma actuel)

---

## 2. Parasites supprimés

| Fichier | Type de parasite | Action |
|---|---|---|
| `app/(admin)/tenants/page.tsx` | Placeholder complet — 4 KPI statiques "—", message "sera connecté aux tables tenants, subscriptions et wallets" | **Réécrit** — remplacé par composant client avec fetch réel |
| `app/(admin)/tenants/page.tsx` | KPI "MRR" statique | **Retiré** — non calculable depuis le schéma actuel |
| `app/(admin)/tenants/page.tsx` | Texte "Détails tenant, plan actif, solde KBActions, channels connectés, métriques usage" | **Supprimé** — remplacé par table de données réelles |
| `app/(admin)/tenants/page.tsx` | Icône placeholder Building2 centrée sans données | **Supprimé** — remplacé par état vide réel "Aucun tenant enregistré" |
| `components/layout/Sidebar.tsx` | Version hardcodée v2.1.7 | **Mis à jour** → v2.1.8 |

### Pages hors périmètre identifiées comme placeholders (non modifiées, à traiter ultérieurement)

| Page | État |
|---|---|
| `/` (Dashboard) | Placeholder — KPI "—", messages "sera connecté aux endpoints PH81-PH85" |
| `/billing` | Placeholder — KPI "—", message "sera connecté aux tables subscriptions, wallets" |
| `/audit` | Placeholder — KPI "—", message "sera connecté au AI Actions Ledger" |

---

## 3. DB réelle

### DEV — 11 tenants

| ID | Nom | Plan | Statut | Admin users liés |
|---|---|---|---|---|
| ecomlg-mmiyygfg | ecomlg | PRO | active | 0 |
| ecomlg-001 | eComLG | pro | active | 0 |
| essai-mmyupn12 | essai | AUTOPILOT | active | 1 |
| tenant-1772234265142 | Essai | free | active | 1 |
| olyara-mmzxs9r0 | Olyara | PRO | active | 1 |
| switaa-mmyv5fh4 | SWITAA | STARTER | active | 0 |
| switaa-sasu-mmaza85h | SWITAA SASU | PRO | active | 0 |
| test-paywall-402-1771288806263 | Test 402 | PRO | active | 1 |
| test-paywall-lock-1771288805123 | Test Paywall | PRO | active | 1 |
| w3lg-mmyqgmre | W3LG | STARTER | active | 1 |
| w3lg-mmyxgv0k | W3LG | PRO | active | 2 |

**admin_user_tenants** : 8 lignes, 2 utilisateurs distincts.

### PROD — 7 tenants

| ID | Nom | Plan | Statut | Admin users liés |
|---|---|---|---|---|
| coucou-mmyx2cb4 | coucou | STARTER | active | 0 |
| ecomlg-001 | eComLG | pro | active | 0 |
| eeeee-mmynd831 | eeeee | STARTER | active | 0 |
| encoreuntest-mmyuu5hf | encoreuntest | PRO | active | 0 |
| switaa-sasu-mmazd2rd | SWITAA SASU | starter | active | 0 |
| switaa-sasu-mmafod3b | SWITAA SASU | STARTER | active | 0 |
| w3lg-mmyqdxzb | W3LG | STARTER | active | 0 |

**admin_user_tenants** : 0 lignes.

### KPI réellement calculables

| KPI | Source | DEV | PROD |
|---|---|---|---|
| Total tenants | `COUNT(*) FROM tenants` | 11 | 7 |
| Tenants actifs | `COUNT(*) WHERE status='active'` | 11 | 7 |
| Utilisateurs admin liés | `COUNT(*) FROM admin_user_tenants` | 8 | 0 |
| Plans Pro+ | `COUNT(*) WHERE UPPER(plan) IN ('PRO','AUTOPILOT')` | 8 | 2 |
| MRR | **NON CALCULABLE** — pas de table subscriptions/payments | N/A | N/A |

---

## 4. Endpoints API

### GET /api/admin/tenants

- Existait avant, retournait `id, name, plan, status`
- **Enrichi** avec `?enriched=true` pour retourner : `id, name, domain, plan, status, created_at, updated_at, admin_user_count`
- Sans paramètre : comportement identique (rétro-compatible pour `/users/new`)

### GET /api/admin/tenants/stats (NOUVEAU)

Retour réel :
```json
{
  "data": {
    "total": 11,
    "active": 11,
    "plans": { "PRO": 6, "STARTER": 2, "AUTOPILOT": 1, "FREE": 1, "pro": 1 },
    "total_admin_users": 8
  }
}
```

### GET /api/admin/tenants/[id] (NOUVEAU)

Retour réel pour un tenant :
```json
{
  "data": {
    "id": "w3lg-mmyxgv0k",
    "name": "W3LG",
    "domain": null,
    "plan": "PRO",
    "status": "active",
    "created_at": "2026-03-20T13:21:25.440781+00:00",
    "updated_at": "2026-03-20T13:22:40.375753+00:00",
    "admin_user_count": 2,
    "admin_users": [
      { "id": "...", "email": "user1@...", "role": "super_admin", "created_at": "..." },
      { "id": "...", "email": "user2@...", "role": "viewer", "created_at": "..." }
    ]
  }
}
```

---

## 5. Preuve DB → API → UI

### DEV

| Étape | Résultat |
|---|---|
| DB `SELECT count(*) FROM tenants` | 11 |
| API `GET /api/admin/tenants/stats` → `total` | 11 |
| UI `/tenants` → KPI "Total tenants" | **11** |
| DB `SELECT count(*) FROM admin_user_tenants` | 8 |
| API `GET /api/admin/tenants/stats` → `total_admin_users` | 8 |
| UI `/tenants` → KPI "Utilisateurs admin liés" | **8** |
| DB tenant w3lg-mmyxgv0k admin_user_count | 2 |
| UI `/tenants/w3lg-mmyxgv0k` → "Utilisateurs admin liés" | **(2)** |
| DB tenant ecomlg-mmiyygfg admin_user_count | 0 |
| UI `/tenants/ecomlg-mmiyygfg` → "Utilisateurs admin liés" | **(0)** |

### PROD

| Étape | Résultat |
|---|---|
| DB `SELECT count(*) FROM tenants` | 7 |
| API `GET /api/admin/tenants/stats` → `total` | 7 |
| UI `/tenants` → KPI "Total tenants" | **7** |
| DB `SELECT count(*) FROM admin_user_tenants` | 0 |
| UI `/tenants` → KPI "Utilisateurs admin liés" | **0** |
| DB `PRO` tenants count | 2 |
| UI `/tenants` → KPI "Plans Pro+" | **2** |
| UI `/tenants/ecomlg-001` → nom | **eComLG** |
| UI `/tenants/ecomlg-001` → "Utilisateurs admin liés" | **(0)** |

---

## 6. Déploiement

### Source

| Item | Valeur |
|---|---|
| Commit SHA | `258696031a3ac310b4a3167d15e77b6a64d0361b` |
| Repo | `https://github.com/keybuzzio/keybuzz-admin-v2.git` |
| Branche | `main` |
| Message | `feat(ph-admin-87.9a): real data enforcement — tenants module` |

### Images

| Env | Tag | Digest |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.8-ph-admin-87-9a-dev` | `sha256:40aaee689459ba3f428f7b3efd4387a9b6ca90986ca1415ddc1e878d42222673` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.8-ph-admin-87-9a-prod` | `sha256:40aaee689459ba3f428f7b3efd4387a9b6ca90986ca1415ddc1e878d42222673` |

### Pods

| Env | Namespace | Pod | Image confirmée |
|---|---|---|---|
| DEV | `keybuzz-admin-v2-dev` | `keybuzz-admin-v2-884f9cfbd-7znmf` | `v2.1.8-ph-admin-87-9a-dev` |
| PROD | `keybuzz-admin-v2-prod` | `keybuzz-admin-v2-6d7849f4bd-k2smf` | `v2.1.8-ph-admin-87-9a-prod` |

### Version runtime

- Sidebar DEV : **v2.1.8** ✓
- Sidebar PROD : **v2.1.8** ✓

---

## 7. Rollback

### DEV

```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.7-ph878c-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD

```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.7-ph878c-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

Images précédentes stables :
- DEV : `ghcr.io/keybuzzio/keybuzz-admin:v2.1.7-ph878c-dev`
- PROD : `ghcr.io/keybuzzio/keybuzz-admin:v2.1.7-ph878c-prod`

---

## 8. Fichiers modifiés / créés

| Fichier | Action |
|---|---|
| `src/features/users/types.ts` | Modifié — ajout `TenantRecordFull`, `TenantsStats` |
| `src/features/users/services/users.service.ts` | Modifié — ajout `listTenantsEnriched`, `getTenantsStats`, `getTenantById`, `getTenantAdminUsers` |
| `src/app/api/admin/tenants/route.ts` | Modifié — support `?enriched=true` |
| `src/app/api/admin/tenants/stats/route.ts` | **Créé** — endpoint stats réel |
| `src/app/api/admin/tenants/[id]/route.ts` | **Créé** — endpoint détail tenant |
| `src/app/(admin)/tenants/page.tsx` | **Réécrit** — page réelle avec fetch, KPI, table |
| `src/app/(admin)/tenants/[id]/page.tsx` | **Créé** — page détail tenant |
| `src/components/layout/Sidebar.tsx` | Modifié — version v2.1.7 → v2.1.8 |

---

## 9. Reste éventuel (dettes identifiées)

| Élément | État | Criticité |
|---|---|---|
| Dashboard (`/`) | Placeholder — KPI statiques, messages PH81-PH85 | Moyen |
| Billing (`/billing`) | Placeholder — KPI statiques, non branché | Moyen |
| Audit (`/audit`) | Placeholder — KPI statiques, non branché | Moyen |
| Plans non normalisés en DB | Mix `PRO`/`pro`, `STARTER`/`starter` | Faible |
| `admin_user_tenants` PROD vide | Aucun user lié en PROD | Attendu (à relier quand nécessaire) |
| MRR non affichable | Pas de table subscriptions/payments en DB admin | Par design — à connecter quand billing sera branché |
| Warning next-auth CLIENT_FETCH_ERROR transient | Connu, transitoire lors du premier chargement | Faible |

---

## 10. Conclusion

**GO — ADMIN v2.1.8 VALIDÉ DEV + PROD**

Le module Tenants est désormais un vrai cockpit branché sur les données réelles :
- **Zéro placeholder** dans le périmètre traité
- **Zéro mock** — chaque nombre affiché vient d'une requête PostgreSQL
- **Zéro hardcodage** tenant/plan/URL
- **Triple preuve** DB → API → UI confirmée sur les deux environnements
- **Aucune régression** sur `/users/new` (11 tenants DEV, 7 tenants PROD)
- **Rollback documenté** et exécutable immédiatement
- **Tags immuables** — aucun tag réutilisé ou écrasé
