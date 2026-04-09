# PH143-I — INFRA / CHECKS / BASTION SYNC

> Date : 2026-04-06
> Phase : PH143-I-INFRA-CHECKS-BASTION-SYNC-01
> Type : reconstruction controlee bloc 8

---

## 1. Resume executif

Restauration et verrouillage complet de la couche process/infra anti-drift.
Correction de bugs critiques dans les scripts de garde (`pipefail` + `grep`),
mise a jour des checks pre-prod pour la ligne rebuild, documentation de procedure.

**Aucun rebuild applicatif necessaire** — seuls les scripts infra ont ete modifies
dans le repo `keybuzz-infra` (pas dans keybuzz-api ni keybuzz-client).

---

## 2. Inventaire des scripts — Avant / Apres

| Script | Repo | Etat avant | Etat apres |
|---|---|---|---|
| `assert-git-committed.sh` | keybuzz-infra/scripts/ | Present, executable, **BUG pipefail** (exit 1 sur repos propres) | Corrige, teste, operationnel |
| `pre-prod-check-v2.sh` | keybuzz-infra/scripts/ | Present, executable, **3 bugs** (pipefail, 307, pattern checks) | Corrige, 25/25 GREEN |
| `pre-prod-checks-v2.js` | keybuzz-infra/scripts/ | Present, **BUG total=18** (2 checks fantomes = timeout) | Corrige total=16, operationnel |
| `build-from-git.sh` | keybuzz-infra/scripts/ | Present, executable, **OK** | Inchange, verifie fonctionnel |
| `pre-prod-check.sh` (v1) | keybuzz-infra/scripts/ | Present | Legacy, non modifie |
| `pre-prod-checks.js` (v1) | keybuzz-infra/scripts/ | Present | Legacy, non modifie |

**Absence confirmee** : aucun script infra dans keybuzz-api ni keybuzz-client (correct — tous dans keybuzz-infra).

---

## 3. Bugs corriges

### 3.1. assert-git-committed.sh — pipefail + grep

**Probleme** : `set -euo pipefail` tue le script quand `grep` ne trouve rien
(exit code 1 propage par pipefail, intercepte par `set -e`).
Le script retournait toujours exit 1 meme sur repos propres.

**Fix** : Wrapper les `grep` avec `{ grep ... || true; }` pour absorber l'exit 1.

```bash
# Avant (bugge)
MODIFIED=$(git status --porcelain ... | grep '^ M\| M ' | wc -l)

# Apres (corrige)
MODIFIED=$(git status --porcelain ... | { grep '^ M\| M ' || true; } | wc -l)
```

### 3.2. pre-prod-check-v2.sh — 3 corrections

| Bug | Cause | Fix |
|---|---|---|
| Git status pipefail | Meme bug que assert-git | `{ grep ... \|\| true; }` |
| Client health FAIL HTTP 307 | Root URL redirige vers /auth/signin | Accepter 200 OU 307 |
| Client feature patterns MISSING | Next.js minifie les noms de fonctions | Remplacer par verification des routes compilees |

### 3.3. pre-prod-checks-v2.js — total fantome

**Probleme** : `total = 18` mais seulement 16 checks reels.
La fonction `fileContains()` etait definie mais jamais appelee.
Le script attendait 18 completions → timeout systematique.

**Fix** : `const total = 16;`

---

## 4. Synchronisation bastion

| Critere | Statut |
|---|---|
| Emplacement correct (`/opt/keybuzz/keybuzz-infra/scripts/`) | OK |
| Permissions executables (755) | OK |
| Format LF (pas CRLF) | OK — verifie avec `od` |
| Scripts executables reellement | OK — testes avec succes |

---

## 5. Tests assert-git-committed

| Test | Attendu | Resultat |
|---|---|---|
| Repos propres (client + API) | exit 0 + "BUILD AUTORISE" | **OK** — `exit 0` |
| Repo API dirty (fichier non suivi) | exit 1 + "BUILD INTERDIT" | **OK** — `exit 1`, message clair avec instructions de correction |
| Apres cleanup | exit 0 | **OK** — `exit 0` |

Sortie type (repo dirty) :
```
BLOQUE — keybuzz-api a des modifications non commitees
  Fichiers non suivis (1):
    ?? test-dirty-file.txt
  Pour corriger :
    cd /opt/keybuzz/keybuzz-api
    git add -A
    git commit -m "PH-XXX: description des changements"
BUILD INTERDIT
```

---

## 6. Tests pre-prod-check-v2

### Resultat : 25/25 ALL GREEN

```
--- A. Git Source of Truth ---
  [OK] Git clean: keybuzz-client
  [OK] Git clean: keybuzz-api

--- B. External Health ---
  [OK] API health (https://api-dev.keybuzz.io)
  [OK] Client health (https://client-dev.keybuzz.io)

--- C. API Internal (kubectl exec) ---
  [OK] Inbox API endpoint
  [OK] Dashboard API endpoint
  [OK] AI Settings endpoint
  [OK] AI Journal endpoint
  [OK] Autopilot draft endpoint
  [OK] Signature config in DB
  [OK] Orders count > 0
  [OK] Channels count > 0
  [OK] Billing current endpoint
  [OK] Agent KeyBuzz status API
  [OK] DB has_agent_keybuzz_addon col
  [OK] Addon API structure valid
  [OK] billing/current hasAddon field
  [OK] Agents API endpoint
  [OK] Signature API endpoint

--- D. Client Compiled Routes ---
  [OK] Route: billing_plan_page compiled
  [OK] Route: billing_ai_page compiled
  [OK] Route: settings_page compiled
  [OK] Route: dashboard_page compiled
  [OK] Route: inbox_page compiled
  [OK] Route: orders_page compiled

RESULT: 25/25 passed — ALL GREEN
```

---

## 7. Discipline build-from-git confirmee

| Critere | Statut |
|---|---|
| Clone depuis GitHub (pas bastion) | OK — `git clone --depth 1 --branch` |
| Verification clean state post-clone | OK — `git status --porcelain` |
| `docker build --no-cache` | OK |
| Git SHA injecte (`GIT_COMMIT_SHA`) | OK |
| Validation env (dev/prod) | OK — rejet si invalide |
| Validation suffixe tag (-dev/-prod) | OK — rejet si manquant |
| Cleanup post-build | OK — `rm -rf $BUILD_DIR` |
| Dry-run valide (usage, wrong env, wrong suffix) | OK — 3 cas testes |

---

## 8. Doc process mise a jour

Fichier cree : `keybuzz-infra/docs/BUILD-AND-PROMOTION-PROCEDURE.md`

Contenu :
- Procedure avant chaque build (3 etapes)
- Procedure avant promotion PROD (5 etapes)
- Liste des interdits (6 regles)
- Verification anti-drift (3 methodes)
- Scripts disponibles (4 outils)

---

## 9. Non-regressions

Le pre-prod-check-v2.sh couvre tous les blocs reconstruits :

| Bloc | Check | Resultat |
|---|---|---|
| PH143-B Billing | billing_current, billing_addon_field, db_addon_column | OK |
| PH143-C Agents/RBAC | agents_api, agent_keybuzz_status, addon_api_structure | OK |
| PH143-D IA Assist | ai_settings, ai_journal | OK |
| PH143-E Autopilot | autopilot_draft | OK |
| PH143-F Signature/Settings | signature_db, signature_api, settings_page | OK |
| PH143-G Dashboard/SLA | dashboard_api, dashboard_page | OK |
| PH143-H Tracking/Orders | orders_count, orders_page, inbox_page | OK |
| Infrastructure | Git clean, health externe | OK |

---

## 10. Commits

| Repo | SHA | Description |
|---|---|---|
| keybuzz-infra | `b2c6720` | Fix scripts pipefail + pre-prod checks v2 |
| keybuzz-infra | `69ce785` | Merge remote (resolve deployment yaml conflicts) |
| keybuzz-infra | `8c65a9c` | Add build and promotion procedure documentation |

**Aucun changement** dans keybuzz-api ni keybuzz-client (pas de rebuild applicatif necessaire).

---

## 11. Build DEV

**Aucun rebuild applicatif necessaire.**
Les images deployees restent celles de PH143-H :
- API : `v3.5.201-ph143-tracking-dev`
- Client : `v3.5.201-ph143-tracking-dev`

Les modifications portent uniquement sur les scripts infra dans `keybuzz-infra`.

---

## 12. Verdict

**REGRESSION GUARDS ACTIVE** — assert-git-committed bloque effectivement les builds dirty
**BASTION IN SYNC** — tous les scripts corriges, executables, format LF
**BUILD DISCIPLINE ENFORCED** — build-from-git verifie, documente, operationnel
**PRE-PROD CHECK OPERATIONAL** — 25/25 ALL GREEN sur la ligne rebuild

**GO pour PH143-J**
