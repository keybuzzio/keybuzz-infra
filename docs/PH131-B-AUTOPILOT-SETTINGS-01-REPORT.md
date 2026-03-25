# PH131-B — AUTOPILOT SETTINGS — RAPPORT

> Date : 25 mars 2026
> Phase : PH131-B-AUTOPILOT-SETTINGS-01
> Environnements : DEV + PROD

---

## Objectif

Creer un systeme de configuration complet pour l'autopilot, permettant au client de definir le niveau d'autonomie de l'IA, les actions autorisees, la cible d'escalade et le mode securise — sans activer d'automatisation.

---

## Etape 1 — Modele DB

### Table `autopilot_settings`

| Colonne | Type | Default |
|---|---|---|
| id | SERIAL PK | auto |
| tenant_id | VARCHAR(255) UNIQUE | - |
| is_enabled | BOOLEAN | false |
| mode | VARCHAR(20) CHECK | 'off' |
| escalation_target | VARCHAR(20) CHECK | 'client' |
| allow_auto_reply | BOOLEAN | false |
| allow_auto_assign | BOOLEAN | false |
| allow_auto_escalate | BOOLEAN | false |
| safe_mode | BOOLEAN | true |
| created_at | TIMESTAMPTZ | now() |
| updated_at | TIMESTAMPTZ | now() |

- Contrainte CHECK sur `mode`: `off`, `supervised`, `autonomous`
- Contrainte CHECK sur `escalation_target`: `client`, `keybuzz`, `both`
- Unique sur `tenant_id`
- GRANT aux deux users DB (`keybuzz_api_dev`, `keybuzz_api_prod`)

**Statut** : OK (DEV + PROD)

---

## Etape 2 — Seeder

Seed initial pour `ecomlg-001` :
- `is_enabled = false`, `mode = off`, `escalation_target = client`
- Tous auto-actions desactives, safe_mode active

**Statut** : OK (DEV + PROD)

---

## Etape 3 — API Endpoints

### Routes creees

| Methode | Route | Description |
|---|---|---|
| GET | `/autopilot/settings?tenantId=xxx` | Lire la config (retourne defaults si pas de row) |
| POST | `/autopilot/settings?tenantId=xxx` | Creer/upsert config |
| PATCH | `/autopilot/settings?tenantId=xxx` | Mise a jour partielle (champs dynamiques) |

### Fichiers

- `keybuzz-api/src/modules/autopilot/routes.ts` — routes Fastify
- `keybuzz-api/src/app.ts` — enregistrement prefix `/autopilot`

### Commits API

| Hash | Message |
|---|---|
| `877ea2b` | PH131-B: autopilot settings API (GET/POST/PATCH) |
| `06f833b` | PH131-B: fix await getPool |

**Statut** : OK

---

## Etape 4 — Integration Gating PH130

Gating integre dans le composant `AutopilotSection` :

| Plan | Acces Autopilot | Mode supervise | Mode autonome | Auto-actions |
|---|---|---|---|---|
| STARTER | Bloque (message + lien upgrade) | Non | Non | Non |
| PRO | Oui | Oui | Bloque (lock + message) | Partiellement (assign/escalate oui, reply non) |
| AUTOPILOT | Oui | Oui | Oui | Oui |
| ENTERPRISE | Oui | Oui | Oui | Oui |

Utilise `isPlanAtLeast()` de `planCapabilities.ts` comme source de verite.

**Statut** : OK

---

## Etape 5 — UI Settings

### Composant `AutopilotSection`

Localisation : `src/features/ai-ui/AutopilotSection.tsx`

Sections :
1. **Header** avec toggle activation ON/OFF
2. **Mode** — cartes selectionables (Suggestions / Supervise / Autonome)
3. **Escalade** — cible (Votre equipe / KeyBuzz / Les deux)
4. **Actions autorisees** — toggles (auto-reply, auto-assign, auto-escalate)
5. **Safe mode** — toggle vert avec avertissement si desactive

Integration : ajoute dans `AITab.tsx` entre `AISettingsSection` et `LearningControlSection`.

### Fichiers modifies

| Fichier | Action |
|---|---|
| `src/features/ai-ui/AutopilotSection.tsx` | **CREE** — composant principal |
| `src/features/ai-ui/index.ts` | **MODIFIE** — export ajoute |
| `app/settings/components/AITab.tsx` | **MODIFIE** — integration AutopilotSection |

**Statut** : OK

---

## Etape 6 — UX Blocage Plan

- Plan STARTER : bloc amber avec icone Lock + texte explicatif + lien `/billing/plan`
- Mode autonome sur PRO : carte avec Lock + texte "Plan Autopilot requis"
- Auto-reply sur PRO : lock + texte "Plan Autopilot requis"
- Rien n'est cache — tout est montre et explique

**Statut** : OK

---

## Etape 7 — Permissions

| Role | Modifier | Lire |
|---|---|---|
| owner | Oui | Oui |
| admin | Oui | Oui |
| agent | Non (toggles disabled) | Oui |
| viewer | Non (toggles disabled) | Oui |

Controle via `useIsOwnerOrAdmin()` — les toggles et boutons sont `disabled` pour les non-admin.

**Statut** : OK

---

## Etape 8 — BFF Route

| Fichier | Methodes |
|---|---|
| `app/api/autopilot/settings/route.ts` | GET, POST, PATCH |

Pattern identique aux autres BFF (proxy vers API backend via Cookie forwarding).

**Statut** : OK

---

## Etape 9 — Validation DEV

| Test | Resultat |
|---|---|
| GET /autopilot/settings (ecomlg-001) | 200 — donnees correctes |
| PATCH mode=supervised, is_enabled=true | 200 — persistance OK |
| Verify apres PATCH | is_enabled=true, mode=supervised |
| Reset mode=off | 200 — retour etat initial |
| Non-reg agents | 200 |
| Non-reg health | 200 |
| PROD non touche | Confirme (v3.5.102 / v3.5.103) |

**PH131-B DEV = OK**

---

## Etape 10 — Validation Post-Build

| Verification | Resultat |
|---|---|
| API image DEV | `v3.5.104-ph131-autopilot-settings-dev` |
| Client image DEV | `v3.5.104-ph131-autopilot-settings-dev` |
| Pods running | 1/1 API, 1/1 Client |
| Aucune regression PH121–PH131-A | Confirme |
| Aucune action automatique | Confirme |

**Statut** : OK

---

## Etape 11 — Promotion PROD

| Element | Resultat |
|---|---|
| API image PROD | `v3.5.104-ph131-autopilot-settings-prod` |
| Client image PROD | `v3.5.104-ph131-autopilot-settings-prod` |
| Rollout API | Successfully rolled out |
| Rollout Client | Successfully rolled out |
| GET /autopilot/settings PROD | 200 — donnees correctes |
| Non-reg agents PROD | 200 |
| Non-reg health PROD | 200 |

**Statut** : OK

---

## GitOps

| Fichier | Tag |
|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.104-ph131-autopilot-settings-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.104-ph131-autopilot-settings-dev` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.104-ph131-autopilot-settings-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.104-ph131-autopilot-settings-prod` |

Commit infra : `526c868`

---

## Commits

| Repo | Hash | Message |
|---|---|---|
| keybuzz-api | `877ea2b` | PH131-B: autopilot settings API (GET/POST/PATCH) |
| keybuzz-api | `06f833b` | PH131-B: fix await getPool |
| keybuzz-client | (auto) | PH131-B: autopilot settings UI + BFF route |
| keybuzz-infra | `526c868` | PH131-B: GitOps update v3.5.104 |

---

## Images Deployees

| Env | Service | Image |
|---|---|---|
| DEV | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.104-ph131-autopilot-settings-dev` |
| DEV | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.104-ph131-autopilot-settings-dev` |
| PROD | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.104-ph131-autopilot-settings-prod` |
| PROD | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.104-ph131-autopilot-settings-prod` |

---

## Non-Regressions Confirmees

- Health API : 200 (DEV + PROD)
- Agents endpoint : 200 (DEV + PROD)
- Inbox : non touche
- Billing / Stripe : non touche
- Auth / OTP : non touche
- KBActions : non touche
- Assignation : non touche
- Escalade : non touche

---

## Stop Points

- Autopilot engine NON implemente
- Aucune automatisation active
- Aucun routage automatique
- Configuration uniquement — pas d'execution

---

## Verdict

### PH131-B AUTOPILOT SETTINGS READY
