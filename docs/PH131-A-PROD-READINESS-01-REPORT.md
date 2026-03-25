# PH131-A-PROD-READINESS-01 — Rapport

> Date : 2026-03-25
> Phase : PH131-A-PROD-READINESS-01
> Type : stabilisation + promotion PROD

---

## Objectif

Rendre PH131-A (agents system) propre, complete et deployable en production sans ajout de logique metier.

---

## Etape 1 — Source de verite API

| Verification | Resultat |
|---|---|
| Commit PH131-A present | `8d88dd2` sur `main` |
| Push GitHub | **Etait manquant** → push effectue (`3658328..8d88dd2`) |
| Diff HEAD vs bastion | Aucun (`git status` clean) |
| Image DEV correspond | `v3.5.101-ph131-agents-dev` (buildee depuis ce commit) |

**API SOURCE OF TRUTH = OK** (apres correction du push manquant)

---

## Etape 2 — DB Access

| Verification | Resultat |
|---|---|
| `10.0.0.120` dans le code | **Aucune reference** |
| `10.0.0.121` dans le code | **Aucune reference** |
| `10.0.0.122` dans le code | **Aucune reference** |
| PGHOST en pod | `10.0.0.10` (HAProxy LB) |
| `database.ts` | Lit secrets K8s ou env vars |

**DB ACCESS = OK** — aucun hardcode Patroni

---

## Etape 3 — Navigation UI

Modification : `app/settings/page.tsx`

- Import `UserCog` (lucide-react), `useIsOwnerOrAdmin`, `useRouter`
- Ajout bouton "Agents" dans la barre d'onglets settings
- Visible uniquement pour `owner` et `admin`
- Navigation vers `/settings/agents` (page separee)
- Style coherent avec les onglets existants

Commit client : `3dc9eb2` — `PH131-A-PROD: add Agents navigation link in settings (owner/admin)`

---

## Etape 4 — Assignation reelle

| Verification | Resultat |
|---|---|
| `assigned_agent_id` dans conversations | Colonne presente |
| Handler PATCH `/conversations/:id/assign` | Fonctionnel (ligne 798 messages/routes.ts) |
| Mapping user → agent | `GET /agents/by-user/:userId` retourne l'agent lie |
| Conversations assignees DEV | 0/281 (normal, jamais utilisee avant PH131-A) |
| Fallback silencieux | Aucun — valeur NULL si non assigne |

**ASSIGNATION = OK**

---

## Etape 5 — Tests endpoints

| Endpoint | Status | Resultat |
|---|---|---|
| `GET /agents?tenantId=ecomlg-001` | 200 | 3 agents retournes |
| `GET /agents/33` | 200 | Agent specifique |
| `GET /agents/by-user/:userId` | 200 | Agent lie au user |
| `GET /teams?tenant_id=ecomlg-001` | 200 | Array vide (pas de teams) |
| `POST /agents` | 201 | Agent cree (id=36) |
| `POST /teams` | 201 | Team creee |
| `PATCH /agents/:id` | 200 | Agent desactive |
| Tenant isolation | 200 | Array vide pour fake tenant |

Donnees de test nettoyees apres validation.

**ENDPOINTS = OK**

---

## Etape 6 — Permissions

| Role | Gestion agents | Assignation | Lecture |
|---|---|---|---|
| owner | oui (`canManageAgents: true`) | oui | oui |
| admin | oui (`canManageAgents: true`) | oui | oui |
| agent | non | oui | oui |
| viewer | non | non | oui |

Tenant guard isole les donnees par tenant.

**PERMISSIONS = OK**

---

## Etape 7 — Validation DEV complete

| Test | Resultat |
|---|---|
| Health API | 200 |
| Agents endpoint | 3 agents |
| Inbox | Conversations OK |
| Dashboard | 200 |
| Billing | 200 |
| Auth check-user | 200, exists/hasTenants |
| Stabilite pods | 0 restarts |
| PROD intacte | Verifie |

**PH131-A DEV READY = OK**

---

## Etape 8 — Build DEV

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.102-ph131-agents-prod-ready-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.102-ph131-agents-prod-ready-dev` |

Builds depuis :
- API : commit `8d88dd2` (main)
- Client : commit `3dc9eb2` (main)

---

## Etape 9 — Validation post-build DEV

Tous les tests de l'etape 7 re-executes apres le deploiement du build.
Resultat identique : **tous OK**.

---

## Etape 10 — Promotion PROD

### Migration DB PROD (keybuzz_prod)

Le schema PROD ne contenait pas les colonnes PH131-A.

Migration executee sur `db-postgres-03` (10.0.0.122, leader Patroni) :

| Operation | Resultat |
|---|---|
| `ALTER TABLE agents ADD COLUMN user_id TEXT` | OK |
| `ALTER TABLE agents ADD COLUMN type VARCHAR(20) DEFAULT 'client'` | OK |
| `ALTER TABLE agents ADD COLUMN is_active BOOLEAN DEFAULT true` | OK |
| `CREATE TABLE team_members` | OK |
| `GRANT ... TO keybuzz_api_prod` | OK |
| `ALTER TABLE conversations ADD COLUMN escalation_target VARCHAR(20)` | OK |
| Seed agent admin (Ludovic Gonthier) | OK (id=1) |

### Images PROD

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.102-ph131-agents-prod-ready-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.102-ph131-agents-prod-ready-prod` |

Builds depuis le meme code source que DEV, avec :
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=production`

---

## Etape 11 — Validation PROD

| Test | Resultat |
|---|---|
| Health API | 200 |
| Agents endpoint | 200, 1 agent (admin) |
| Inbox | 200, conversations OK |
| Dashboard | 200 |
| Billing | 200 |
| Auth check-user | 200, exists/hasTenants |
| API restarts | 0 |
| Client restarts | 0 |

**PROD VALIDATION = OK**

---

## Non-regressions

| Systeme | Impact |
|---|---|
| Inbox | Aucun — conversations fonctionnent normalement |
| Billing / Stripe | Aucun — endpoint 200, pas de modification code billing |
| Auth / OTP | Aucun — check-user fonctionne |
| KBActions / AI | Aucun — pas de modification |
| Escalade PH123 | Aucun — colonne `escalation_target` ajoutee sans modification logique |
| Gating PH130 | Aucun — planGuard non modifie |
| Outbound worker | Aucun — pas de modification |

---

## Commits

| Repo | SHA | Message |
|---|---|---|
| keybuzz-api | `8d88dd2` | PH131-A: agents/teams CRUD routes (push corrige) |
| keybuzz-client | `3dc9eb2` | PH131-A-PROD: add Agents navigation link in settings |
| keybuzz-infra | (GitOps) | PH131-A-PROD-READINESS: GitOps update DEV + PROD v3.5.102 |

---

## Images deployees

| Env | Service | Image |
|---|---|---|
| DEV | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.102-ph131-agents-prod-ready-dev` |
| DEV | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.102-ph131-agents-prod-ready-dev` |
| PROD | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.102-ph131-agents-prod-ready-prod` |
| PROD | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.102-ph131-agents-prod-ready-prod` |

---

## Note Patroni

Leader Patroni confirme : `db-postgres-03` (10.0.0.122).
`db-postgres-01` (10.0.0.120) est replica (`pg_is_in_recovery = true`).

---

## Verdict

**PH131-A PROD READY**

---

## Stop point

- Ne pas implementer autopilot
- Ne pas ajouter logique IA
- Ne pas modifier escalade
- Ne pas toucher KBActions
