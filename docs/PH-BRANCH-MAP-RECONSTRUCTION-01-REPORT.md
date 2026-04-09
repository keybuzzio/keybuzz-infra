# PH-BRANCH-MAP-RECONSTRUCTION-01 — RAPPORT

> Date : 1 mars 2026
> Mode : READ-ONLY — Aucune modification executee
> Repo : keybuzz-client

---

## 1. INVENTAIRE DES BRANCHES

### Ancetre commun

Toutes les branches principales divergent du meme commit :

```
bd827a8 fix(orders): restore totalOrders count, fix unicode chars, keep PROD modal text
```

### Branches locales + distantes

| Branche | HEAD local | HEAD remote | Tracking | Statut |
|---|---|---|---|---|
| `main` | `852ef8f` | `852ef8f` | synced | CONTAMINEE (billing rejete) |
| `ph130-plan-gating` | `e20ded6` | `e20ded6` | synced | **BASE STABLE** (= runtime) |
| `d16-settings` | `db8f4a8` | `db8f4a8` | synced | Extension de ph130 (+1 commit) |
| `fix/signup-redirect-v2` | `9d62f99` | `68d4026` | DESYNCHRONISE | Sous-ensemble de ph130 |
| `ph-s01.2d-cookie-domain` | `783dafa` | `783dafa` | synced | Ancienne, autre lignee |

### Relations entre branches

```
bd827a8 (ancetre commun)
├── main (56 commits exclusifs)
│   ├── PH11, PH19, PH59-PH97 (pollution non-client)
│   ├── PH-TD-01..04 (scripts/infra)
│   ├── PH-BILLING-REPAIR-01 + BUILD chain (TOXIQUE)
│   ├── ROLLBACK (revert)
│   └── PH-BILLING-FIX-B1 (isole)
│
├── ph130-plan-gating (42 commits exclusifs)
│   ├── PH32.1, PH34 (suppliers, KPIs)
│   ├── PH-CHANNELS (channels UI)
│   ├── PH-BILLING (payment gates, onboarding)
│   ├── PH117-PH120 (AI dashboard, onboarding)
│   ├── PH121-PH131 (feature phases completes)
│   └── = IMAGE v3.5.100 deployee
│
└── d16-settings (branche de ph130 + 1 commit)
    └── db8f4a8 PH-TD-08: sync bastion + Dockerfile
```

Merge-bases :
- `main` ↔ `ph130-plan-gating` : `bd827a8`
- `main` ↔ `d16-settings` : `bd827a8`
- `ph130-plan-gating` ↔ `d16-settings` : `3e2e6ec` (partagent 13 commits de base)

---

## 2. COMPARAISON STRUCTURELLE : main vs ph130-plan-gating

### Ce que ph130-plan-gating a de bon (42 commits)

Tout le travail feature client reel depuis PH32.1 jusqu'a PH131 :

| Commits | Contenu | Nature |
|---|---|---|
| `2686324`..`95753e9` | PH32.1, PH34 : suppliers SAV, KPIs unifies | Code client |
| `e1d4ce0`..`3e2e6ec` | PH-CHANNELS : refonte UI canaux, billing compute | Code client |
| `c30195c`..`6d32cb6` | PH-BILLING : payment gates, signup, OAuth, UI gates | Code client |
| `61a3116` | PH-I18N : remplacement Unicode echappes | Code client |
| `ac0f8c1`..`5b32aeb` | PH117-PH118 : AI Dashboard, onboarding hardening | Code client |
| `3edc104` | Source of truth fix : sync bastion → Git | Code client |
| `d379f52` | PH120 : revert async tenant reads | Code client |
| `57eee5f`..`e20ded6` | **PH121-PH131 : roles, assignment, escalation, agent queue, priority, AI assist, AI supervision, PH129, PH130 plan gating, PH131 KBActions fix** | Code client |
| `406c60f` | Auth session/logout stability | Code client |

**100% de ces commits sont du code client reel.**
**Cette branche a construit l'image v3.5.100 deployee en DEV et PROD.**
**Un .dockerignore fonctionnel est present.**

### Ce que main a de plus (56 commits)

| Commits | Contenu | Fichiers touches | Nature |
|---|---|---|---|
| `1876724` | PH11-06C.2 Scheduler | `PH11-06C.2-SCHEDULER_SYSTEMD.md`, `enqueueScheduledJobs.ts` (racine) | **Pollution** : fichiers en vrac a la racine |
| `dbce5f2` | PH11-06B.3.1 SMTP | `PH11-06B.3.1-SMTP_SES_ACTIVATION.md` (racine) | **Pollution** : markdown a la racine |
| `891075b` | PH19 inbox status | `.cursor/worktrees.json`, `011_multi_tenant_schema.sql`... (racine) | **Pollution** : SQL migrations a la racine |
| `0f44cd3` | Invite flow | `keybuzz-client/app/invite/...`, `keybuzz-client/middleware.ts` | **Pollution** : path `keybuzz-client/` imbrique |
| `83e8dd8`..`dabf95f` | PH59-PH63 (8 commits) | `.cursor/rules/`, `keybuzz-api/src/`, `scripts/` | **Non-client** : code API + rules |
| `09933d2` | sendReply fix | `.cursor/rules/`, `keybuzz-infra` submodule | **Non-client** : rules + submodule |
| `5dcb193`..`bd03ead` | PH86 (6 commits) | `.cursor/rules/` uniquement | **Non-client** : documentation |
| `84dc85f`..`1e1211a` | PH92-PH97 (12 commits) | `.cursor/rules/`, `keybuzz-api/src/`, `.tmp_ssh_files/`, `scripts/` | **Non-client** : code API + pollution |
| `e058ab6`..`3b0d99b` | PH-TD-01..04 (14 commits) | `scripts/`, `keybuzz-infra` submodule, `.cursor/rules/` | **Non-client** : scripts infra |
| `8ca1d3d`..`ce4bf6e` | PH-BILLING-REPAIR + BUILD chain (10 commits) | Code client + .dockerignore + tsconfig | **TOXIQUE** : chantier rejete |
| `672d261` | ROLLBACK PH-BILLING | Revert des 10 commits ci-dessus | **TOXIQUE** : cleanup du rejete |
| `852ef8f` | PH-BILLING-FIX-B1 | `src/features/billing/useCurrentPlan.tsx` | **Isole valide** mais sur base toxique |

### Synthese main

| Categorie | Commits | % |
|---|---|---|
| Pollution (fichiers a la racine, paths imbriques) | 4 | 7% |
| Non-client (API code, scripts, rules, docs) | 40 | 71% |
| Toxique (billing rejete + rollback) | 11 | 20% |
| Isole valide (B1 fix) | 1 | 2% |

**Conclusion : main ne contient AUCUN commit de code client reel utile en dehors du fix B1 isole.** Tous les autres commits exclusifs a main sont soit de la pollution, soit du code API/infra place au mauvais endroit, soit le chantier billing rejete.

### Ce que main a de toxique

| SHA | Message | Raison |
|---|---|---|
| `8ca1d3d` | PH-BILLING-REPAIR-01 | Refonte billing massive rejetee |
| `cf59fc8` | PH-BILLING-DEV-BUILD | Suppression 27 .tsx racine |
| `5a05c0b` | PH-BILLING-DEV-BUILD-02 | Suppression 63 .ts racine |
| `75b36c2` | PH-BILLING-DEV-BUILD-03 | .dockerignore + tsconfig hors scope |
| `39e7e71` | PH-BILLING-DEV-BUILD-04 | Fix .dockerignore |
| `f43641c` | PH-BILLING-DEV-BUILD-05 | Comprehensive .dockerignore + tsconfig |
| `d8ededb` | PH-BILLING-DEV-BUILD-06 | Suppression src/main.ts |
| `519f589` | PH-BILLING-DEV-BUILD-07 | Suppression src/modules/tenants/tenants.types.ts |
| `8bb2829` | PH-BILLING-DEV-BUILD-08 | Exclusion *.md docker |
| `ce4bf6e` | PH-BILLING-DEV-BUILD-09 | Exclusion *.ts racine |
| `672d261` | ROLLBACK PH-BILLING | Revert massif |
| `852ef8f` | PH-BILLING-FIX-B1 | Fix valide MAIS applique sur base contaminee |

### Ce que ph130-plan-gating n'a PAS

| Element manquant | Impact reel |
|---|---|
| Commits PH59-PH97 (AI engines) | **ZERO** : code API, pas client |
| Commits PH-TD-01..04 (tech debt) | **ZERO** : scripts shell, pas client |
| Commits PH86 (admin docs) | **ZERO** : cursor rules, pas client |
| Fix B1 (`852ef8f`) | **A EVALUER** : correction `useCurrentPlan.tsx` pour `channelsUsed` |
| Fix sendReply (`09933d2`) | **ZERO** : seuls cursor rules + submodule modifies |
| Fix invite (`0f44cd3`) | **A EVALUER** : code dans path imbrique `keybuzz-client/app/` |

---

## 3. MAPPING PAR PHASE

### Phases PH121-PH131 (le travail feature)

| Phase | Branche | Commit(s) | Statut |
|---|---|---|---|
| **PH121** : Role & Agent Foundation | `ph130-plan-gating` | `57eee5f` | **PRESENT** |
| **PH122** : Assignment | `ph130-plan-gating` | `e48788f`, `e418fc2` | **PRESENT** |
| **PH123** : Escalation | `ph130-plan-gating` | `430f56f`, `6c615a0` | **PRESENT** |
| **PH124** : Agent Workbench | `ph130-plan-gating` | `156d121`, `617d4c0` | **PRESENT** |
| **PH125** : Agent Queue | `ph130-plan-gating` | `e263d09` | **PRESENT** |
| **PH126** : Agent Priority | `ph130-plan-gating` | `e9899d2` | **PRESENT** |
| **PH127** : AI Assist | `ph130-plan-gating` | `0aba1fd` | **PRESENT** |
| **PH128** : AI Supervision | `ph130-plan-gating` | `6eea762` | **PRESENT** |
| **PH129** : Enterprise Normalization | `ph130-plan-gating` | `9d62f99` | **PRESENT** |
| **PH130** : Plan Gating | `ph130-plan-gating` | `b6d5b22`, `f470378`, `9bb175c` | **PRESENT** |
| **PH131-FIX** : KBActions Fix | `ph130-plan-gating` | `e20ded6` | **PRESENT** |

**Resultat : 11/11 phases presentes sur `ph130-plan-gating`. 0/11 sur `main`.**

### Phases anterieures (travail pre-divergence ou sur ph130)

| Phase | Branche | Statut |
|---|---|---|
| PH32.1 (Suppliers) | `ph130-plan-gating` | PRESENT (6 commits) |
| PH34 (KPIs unifies) | `ph130-plan-gating` | PRESENT |
| PH-CHANNELS | `ph130-plan-gating` | PRESENT (4 commits) |
| PH117 (AI Dashboard) | `ph130-plan-gating` | PRESENT (3 commits) |
| PH118 (Onboarding) | `ph130-plan-gating` | PRESENT |
| PH120 (Tenant reads) | `ph130-plan-gating` | PRESENT |

### Phases sur main (non-client)

| Phase | Fichiers touches | Code client reel ? |
|---|---|---|
| PH59-PH63 | `keybuzz-api/src/`, `.cursor/rules/`, `scripts/` | **NON** |
| PH86 | `.cursor/rules/` uniquement | **NON** |
| PH92-PH97 | `keybuzz-api/src/`, `.cursor/rules/`, `.tmp_ssh_files/` | **NON** |
| PH-TD-01..04 | `scripts/`, `keybuzz-infra` submodule | **NON** |

---

## 4. COMMITS A EXCLURE (JAMAIS REMERGER)

### Categorie TOXIQUE — Chantier billing rejete

| SHA | Message | Action |
|---|---|---|
| `8ca1d3d` | PH-BILLING-REPAIR-01 | **NE JAMAIS REMERGER** |
| `cf59fc8` | PH-BILLING-DEV-BUILD | **NE JAMAIS REMERGER** |
| `5a05c0b` | PH-BILLING-DEV-BUILD-02 | **NE JAMAIS REMERGER** |
| `75b36c2` | PH-BILLING-DEV-BUILD-03 | **NE JAMAIS REMERGER** |
| `39e7e71` | PH-BILLING-DEV-BUILD-04 | **NE JAMAIS REMERGER** |
| `f43641c` | PH-BILLING-DEV-BUILD-05 | **NE JAMAIS REMERGER** |
| `d8ededb` | PH-BILLING-DEV-BUILD-06 | **NE JAMAIS REMERGER** |
| `519f589` | PH-BILLING-DEV-BUILD-07 | **NE JAMAIS REMERGER** |
| `8bb2829` | PH-BILLING-DEV-BUILD-08 | **NE JAMAIS REMERGER** |
| `ce4bf6e` | PH-BILLING-DEV-BUILD-09 | **NE JAMAIS REMERGER** |
| `672d261` | ROLLBACK PH-BILLING | **NE JAMAIS REMERGER** |

### Categorie POLLUANT — Fichiers hors scope dans le repo client

| SHA | Message | Raison |
|---|---|---|
| `1876724` | PH11-06C.2 Scheduler | Markdown + .ts a la racine |
| `dbce5f2` | PH11-06B.3.1 SMTP | Markdown a la racine |
| `891075b` | PH19 inbox status | SQL migrations a la racine |
| `0f44cd3` | Invite flow | Path `keybuzz-client/` imbrique |
| Tous les PH59-PH97 | AI engines | Code `keybuzz-api/` dans repo client |
| Tous les PH-TD | Tech debt | Scripts shell uniquement |
| `1e1211a` (PH97) | Multi-Order Context | `.tmp_ssh_files/` inclus |

### Categorie A EVALUER — Potentiellement recuperable

| SHA | Message | Contenu | Decision |
|---|---|---|---|
| `852ef8f` | PH-BILLING-FIX-B1 | Fix `useCurrentPlan.tsx` channelsUsed | **Le fix est valide** mais doit etre re-applique proprement sur `ph130-plan-gating` via un nouveau commit incremental |

---

## 5. BASE SAINE RECOMMANDEE

### Verdict sans ambiguite

**La base saine est `ph130-plan-gating` au commit `e20ded6`.**

Justification :
1. C'est la source exacte de l'image `v3.5.100` deployee en DEV et PROD
2. Elle contient 100% des phases feature PH121-PH131
3. Elle contient 100% du travail client reel (PH32.1, PH34, PH-CHANNELS, PH117-PH120)
4. Son `.dockerignore` est fonctionnel (builds propres possibles)
5. Son working tree est clean
6. Elle ne contient aucun commit toxique
7. Elle ne contient aucune pollution non-client

**La branche `main` ne doit PAS servir de base.** Elle est contaminee par :
- 11 commits du chantier billing rejete
- 40+ commits de code non-client (API, scripts, docs, SQL, fichiers temporaires)
- Des fichiers polluants a la racine qui cassent les builds

---

## 6. STRATEGIE DE REUNIFICATION PROPOSEE

### Plan en 3 etapes (A NE PAS EXECUTER MAINTENANT)

#### Etape A — Promotion de ph130-plan-gating

Creer une nouvelle branche de travail depuis `ph130-plan-gating@e20ded6` :
```
git checkout ph130-plan-gating
git checkout -b stable-baseline
```

Cette branche devient la nouvelle base de tout travail futur.
`main` est gelee / archivee — elle ne sera plus jamais utilisee comme base de build.

#### Etape B — Cherry-pick selectif (plus tard, si necessaire)

Le seul commit de `main` potentiellement utile est le fix B1 (`852ef8f`).
Il devra etre re-applique proprement :
- Verifier que le fix est toujours pertinent sur `ph130-plan-gating`
- `ph130-plan-gating` a deja `3e2e6ec PH-CHANNELS-BILLING: billing-compute BFF, useCurrentPlan channelsUsed` qui pourrait deja inclure ce fix
- Si le fix est encore necessaire : un nouveau commit minimal, teste, deploye incrementalement

#### Etape C — Nettoyage de main (optionnel, beaucoup plus tard)

Options :
1. **Archiver** : renommer `main` en `main-archived-pre-reunification`
2. **Force-push** : remplacer `main` par `ph130-plan-gating` (destructif, necessite coordination)
3. **Ignorer** : garder `main` telle quelle, travailler uniquement depuis la nouvelle base

Recommandation : option 1 (archiver) puis option 2 (force-push) quand le moment sera venu.

### Risques de la strategie

| Risque | Mitigation |
|---|---|
| `main` reference dans CI/CD ou scripts | Verifier avant de renommer |
| D'autres contributeurs travaillent sur `main` | Coordonner le changement |
| Le fix B1 est perdu | Il sera re-applique proprement |

---

## 7. VALIDATION RUNTIME vs GIT

| Element | Valeur | Coherent ? |
|---|---|---|
| Repo bastion branche | `ph130-plan-gating` | OUI |
| Repo bastion HEAD | `e20ded6` | OUI |
| Repo working tree | `nothing to commit, working tree clean` | OUI |
| DEV image | `v3.5.100-ph131-fix-kbactions-dev` | OUI — construite depuis `e20ded6` |
| DEV pod | `1/1 Running`, 0 restarts | OUI |
| PROD image | `v3.5.100-ph131-fix-kbactions-prod` | OUI — meme codebase |
| PROD pod | `1/1 Running`, 0 restarts | OUI |
| Drift Git/runtime | **AUCUN** | OUI |

---

## 8. BRANCHES SECONDAIRES

### d16-settings

- Partage 13 commits avec `ph130-plan-gating` (PH32.1 → PH-CHANNELS-BILLING)
- A 1 commit supplementaire : `db8f4a8 PH-TD-08: sync bastion state + securise Dockerfile`
- NE contient PAS PH121-PH131
- Potentiellement utile pour le commit PH-TD-08 (Dockerfile securise)
- A evaluer plus tard

### fix/signup-redirect-v2

- Sous-ensemble de `ph130-plan-gating` (s'arrete a PH129)
- Local desynchronise du remote (local = `9d62f99`, remote = `68d4026`)
- Obsolete — tout son contenu est deja dans `ph130-plan-gating`
- Peut etre supprimee

### ph-s01.2d-cookie-domain

- Lignee completement differente (Sprint work, CX, cookie domain)
- Contient du travail ancien (Sprint 4-5, D22-D30)
- Pas pertinente pour la base actuelle
- Peut etre archivee

---

## 9. VERDICT FINAL

### GIT BRANCH MAP UNDERSTOOD — SAFE RECONSTRUCTION PLAN READY

Faits etablis :
1. `ph130-plan-gating@e20ded6` = seule base saine, = source de l'image deployee
2. `main` = contaminee, 0 commit client utile (sauf B1 isole a re-appliquer)
3. PH121-PH131 = 100% sur `ph130-plan-gating`, 0% sur `main`
4. Aucune ambiguite Git/runtime
5. Strategie de reunification identifiee, non executee, prete

---

*Aucune modification executee. Lecture seule uniquement.*
