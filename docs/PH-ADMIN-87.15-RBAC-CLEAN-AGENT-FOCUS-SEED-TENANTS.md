# PH-ADMIN-87.15 — RBAC CLEAN + AGENT FOCUS + SEED TENANTS CLEANUP

> Date : 2026-03-23
> Statut : TERMINE
> Version : v2.10.1

---

## 1. Resume executif

- RBAC role-based implemente : navigation + middleware + API filtres par role
- Mode agent focus defini : acces limite a Control Center (vue reduite) + Parametres/Profil
- Seed tenants : aucun Acme/Tech en DB — zero nettoyage necessaire
- Identite utilisateur : sidebar affiche email reel + nom au lieu de "KeyBuzz Admin"
- Controles globaux : visibles uniquement pour super_admin
- Middleware securise : redirection automatique pour roles non autorises

---

## 2. Matrice RBAC reelle

| Route | super_admin | ops_admin | finance_admin | account_manager | agent |
|---|---|---|---|---|---|
| `/` (Control Center) | FULL | FULL (sans controles) | FULL (sans controles) | FULL (sans controles) | Vue reduite |
| `/ops` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/queues` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/approvals` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/followups` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/ai` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/ai-control/*` | OK | BLOQUE | BLOQUE | BLOQUE | BLOQUE |
| `/incidents` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/feature-flags` | OK | BLOQUE | BLOQUE | BLOQUE | BLOQUE |
| `/system-health` | OK | OK | BLOQUE | BLOQUE | BLOQUE |
| `/audit` | OK | OK | OK | OK | BLOQUE |
| `/tenants` | OK | OK | BLOQUE | OK | BLOQUE |
| `/billing` | OK | BLOQUE | OK | BLOQUE | BLOQUE |
| `/connectors` | OK | OK | BLOQUE | OK | BLOQUE |
| `/users` | OK | BLOQUE | BLOQUE | BLOQUE | BLOQUE |
| `/settings` | OK | OK | OK | OK | OK |
| `/settings/profile` | OK | OK | OK | OK | OK |

---

## 3. Fichiers crees / modifies

### Crees
- `src/config/rbac.ts` — Matrice RBAC, `canAccessRoute()`, `getAgentFallbackRoute()`

### Modifies
- `src/config/navigation.ts` — Ajout `roles` par item, export `navigationWithRoles`
- `src/components/layout/Sidebar.tsx` — Filtrage menu par role + identite utilisateur reelle
- `src/middleware.ts` — Verification role + redirection agent
- `src/app/(admin)/page.tsx` — Controles globaux conditionnes par `isSuperAdmin`

---

## 4. RBAC Backend (middleware)

Le middleware Next.js verifie le role JWT pour chaque route protegee :
- Routes non autorisees → redirection vers `/` (admin) ou `/settings/profile` (agent)
- La matrice est dupliquee dans `ROUTE_ROLES` du middleware pour securite backend
- Les API endpoints globaux restent proteges par `super_admin` check cote serveur

---

## 5. Seed tenants

| Element | Etat |
|---|---|
| DB `tenants` | 3 tenants reels (eComLG, SWITAA x2) — zero Acme/Tech |
| Selecteur tenant | Aucun seed visible |
| Flows invitation | Table `invitations` n'existe pas encore |
| Onboarding | Pas de faux tenant propose |

Aucun nettoyage necessaire. Pas de seed tenants en DB PROD.

---

## 6. Identite utilisateur

| Zone | Avant | Apres |
|---|---|---|
| Sidebar (bas) | "KeyBuzz Admin" + "v2.9.0" | `ludovic` + `ludovic@keybuzz.pro` |
| Topbar | `ludovic` + `ludovic@keybuzz.pro` | Inchange (deja correct) |
| Avatar sidebar | "KB" fixe | Initiale du nom (`L`) |

---

## 7. Validation navigateur PROD

### Super admin (ludovic@keybuzz.pro)
- Login : OK
- Menu complet : 22 items visibles
- Email affiche sidebar : `ludovic` + `ludovic@keybuzz.pro`
- Email affiche topbar : `ludovic` + `ludovic@keybuzz.pro`
- Controles globaux : toggles maintenance/IA, scanner, broadcast — visibles
- KPIs : 11 metriques reelles
- Incidents : quick actions (Cockpit, Connecteurs, Audit)
- Timeline : 15 entrees reelles
- Tenants : 3 tenants, liens "Voir"
- Aucun Acme/Tech nulle part

### Agent (non teste — aucun agent en DB)
- Le RBAC est en place (navigation filtree + middleware redirect)
- A tester lors de la creation du premier agent

---

## 8. Deploiement

| Champ | Valeur |
|---|---|
| Commit SHA 1 | `ff1cacd0c9797f1642758a50596fc190831ae68d` (RBAC principal) |
| Commit SHA 2 | fix control-state fetch timing |
| Tag DEV | `v2.10.1-ph-admin-87-15b-dev` |
| Digest DEV | `sha256:52c6c1379d84d4bf08c62574bf854ba401bb75c84ae0a8456a658bfc983678ba` |
| Tag PROD | `v2.10.1-ph-admin-87-15b-prod` |
| Digest PROD | `sha256:52c6c1379d84d4bf08c62574bf854ba401bb75c84ae0a8456a658bfc983678ba` |
| Version runtime | v2.10.0 (affichee) |
| Pod DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.1-ph-admin-87-15b-dev` |
| Pod PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.1-ph-admin-87-15b-prod` |

---

## 9. Rollback

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.9.0-ph-admin-87-14-prod -n keybuzz-admin-v2-prod
```

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.9.0-ph-admin-87-14-dev -n keybuzz-admin-v2-dev
```

---

## 10. Dettes restantes

| ID | Description |
|---|---|
| D1 | Pas d'agent en DB pour tester le RBAC agent en conditions reelles |
| D2 | Table `invitations` n'existe pas — flows invitation non testes |
| D3 | `admin_user_tenants` est vide — pas de liaison admin-tenant utilisee |
| D4 | Le RBAC API individuel (par endpoint) n'est securise que pour les routes globales — les routes tenant-specific n'ont pas de check role generique |
| D5 | Le version affichee dans la sidebar est hardcodee a v2.10.0, pas synchronisee avec le tag reel |
