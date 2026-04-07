# PH143-R2 — Clean Release Branch Rebuild

> Date : 2026-04-07
> Type : Reconstruction propre de la ligne release client
> Environnement : DEV uniquement — PROD non touchee
> Strategie : Option A (audit R1) — branche depuis base saine + cherry-pick cible

---

## 1. Branche creee

| Element | Valeur |
|---|---|
| Nom | `release/client-v3.5.220` |
| Repo | `keybuzz-client` (bastion) |
| Base | `e87da0e` (PH143-FR.3) |
| Methode | `git checkout -b release/client-v3.5.220 e87da0e` |

## 2. SHA de base

| Reference | SHA | Commit |
|---|---|---|
| Base saine | `e87da0e` | PH143-FR.3 fix IA accents and real playbooks visibility |
| DEV rollbacke (v3.5.218) | `e87da0e` | Identique |
| PROD actuelle (v3.5.216) | `4d9d736` | PH143-FR francisation complete |

## 3. Commits cherry-pickes

| # | SHA original | SHA sur release | Commit | Fichiers |
|---|---|---|---|---|
| 1 | `e5034ab` | `ac8e63f` | PH-PLAYBOOKS-BACKEND-MIGRATION-02: unify playbooks UI with backend API | 5 |
| 2 | `032f0d0` | `56095eb` | PH-PLAYBOOKS-ENGINE-ALIGNMENT-02B: replace client-side simulator with backend engine BFF | 2 |

### Conflit resolu

Un conflit sur `app/playbooks/page.tsx` :
- **Cause** : la version FR.3 (base) utilisait `getPlaybooks(tenantId)` (localStorage), le commit cible utilisait `usePlaybooks()` (API)
- **Resolution** : prise de la version incoming (API), suppression de l'ancien service
- **Verification** : zero marqueur de conflit residuel, zero import mort

### Commit supplementaire

| SHA | Commit | Fichier |
|---|---|---|
| `4e499b6` | PH143-R2: add Studio exclusions to .dockerignore (contamination guard) | `.dockerignore` |

## 4. `.dockerignore` ajoute

Ajout de 3 exclusions au `.dockerignore` existant :

```
# Studio exclusion — prevent contamination in client builds
keybuzz-studio/
keybuzz-studio-api/
.cursor/rules/studio-rules.mdc
```

Ce garde-fou empeche toute inclusion accidentelle de fichiers Studio dans les builds Docker client, meme si le repo est contamine.

## 5. Diff stat final

**Depuis la base `e87da0e` : 3 commits, 7 fichiers**

```
 .dockerignore                              |   5 +
 app/api/playbooks/[id]/simulate/route.ts   | 262 +++++++++++++
 app/playbooks/[playbookId]/page.tsx        | 114 +++---
 app/playbooks/[playbookId]/tester/page.tsx | 384 ++++++++++--------
 app/playbooks/new/page.tsx                 |  36 +-
 app/playbooks/page.tsx                     |  74 ++--
 src/hooks/usePlaybooks.ts                  | 338 +++++++++++++++
 7 files changed, 931 insertions(+), 282 deletions(-)
```

**Comparaison avec le merge FR.4 (210 fichiers, +39 232 lignes) :**
- R2 : **7 fichiers, +931 lignes** — reduction de **96.7%** du scope

## 6. Preuve absence Studio

| Verification | Resultat |
|---|---|
| `git ls-tree` Studio dans branche | **0 fichiers** |
| `keybuzz-studio/` dans container deploye | **Absent** |
| `keybuzz-studio-api/` dans container deploye | **Absent** |
| `.dockerignore` Studio entries | **Present** (garde-fou actif) |

## 7. Image DEV

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.220-ph143-clean-release-dev
```

| Element | Valeur |
|---|---|
| Digest | `sha256:302a3fbd5630a7004cf82b2b35b504e75ca52e5f21ed612f1e7ec626f652509f` |
| Taille | 279 MB |
| Build | `docker build --no-cache` depuis branche `release/client-v3.5.220` |
| Build args | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` |

## 8. Resultat rollout DEV

| Element | Valeur |
|---|---|
| Methode | `rollback-service.sh client dev v3.5.220-ph143-clean-release-dev` |
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-client-7c8568ddf4-fg76f` — 1/1 Running |
| Image cluster | `v3.5.220-ph143-clean-release-dev` (confirme) |
| GitOps commit | `e0ce6ff` — pushed origin/main |
| PROD intacte | `v3.5.216-ph143-francisation-prod` (non touchee) |

## 9. Validation reelle

### Pages HTTP

| Page | HTTP |
|---|---|
| `/` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/settings` | 200 |
| `/playbooks` | 200 |
| `/billing` | 200 |
| `/orders` | 200 |
| `/ai-journal` | 200 |
| `/channels` | 200 |
| `/suppliers` | 200 |
| `/knowledge` | 200 |

### API Playbooks

| Tenant | Playbooks | Statut |
|---|---|---|
| `ecomlg-001` | **15** | OK |
| `switaa-sasu-mnc1x4eq` | **15** | OK |

### API Non-regression

| Endpoint | Resultat |
|---|---|
| Health | `{"status":"ok"}` |
| Dashboard | 369 conversations |
| Billing | plan PRO, status active |
| Conversations | reponse OK |
| AI Settings | reponse OK |

### Verification structurelle du code deploye

| Verification | Resultat |
|---|---|
| `usePlaybooks`/`fetchPlaybooks` dans les chunks JS | **Present** (4 fichiers playbooks) |
| Ancien service `getPlaybooks`/`kb_client_playbooks` | **Absent** (service localStorage elimine) |
| Fichiers Studio dans le container | **Absent** |

### En attente de validation visuelle humaine

- [ ] Playbooks : starters visibles, Total > 0, refresh OK, recherche OK
- [ ] Settings > Intelligence Artificielle : accents francais corrects
- [ ] Agents : pas d'option KeyBuzz
- [ ] Inbox / Escalade : comportement inchange

## 10. Verdict

```
CLEAN RELEASE BRANCH READY
```

### Resume

| Element | Valeur |
|---|---|
| Branche | `release/client-v3.5.220` |
| Base | `e87da0e` (0 Studio, prouvee stable) |
| Commits ajoutes | 3 (2 cherry-picks playbooks + 1 dockerignore) |
| Fichiers modifies | 7 (vs 210 dans FR.4) |
| Studio | **0** (+ garde-fou `.dockerignore`) |
| Image DEV | `v3.5.220-ph143-clean-release-dev` |
| Pages | 11/11 HTTP 200 |
| Playbooks API | 15/15 pour les 2 tenants |
| PROD | Intacte (`v3.5.216`) |

### Prochaine etape

Attente validation visuelle de Ludovic sur `https://client-dev.keybuzz.io`.
Si GO → PH143-R3 promotion PROD.

### Rollback si necessaire

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.218-ph143-fr-real-fix-dev
```
