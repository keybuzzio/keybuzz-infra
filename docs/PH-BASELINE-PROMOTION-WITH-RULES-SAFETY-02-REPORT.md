# PH-BASELINE-PROMOTION-WITH-RULES-SAFETY-02 — RAPPORT

> Date : 1 mars 2026
> Mode : CONTROLLED CHANGE — Promotion Git executee, zero build, zero deploy

---

## 1. INVENTAIRE DES RULES CURSOR

### Fichiers .cursor/ sur le bastion (Git)

| Fichier | Ancien `main` | Nouveau `main` (ex-ph130) | Action |
|---|---|---|---|
| `.cursor/rules/ai-engine-ph43-ph44.mdc` | PRESENT (194 lines) | ABSENT | Preserve dans `main-archived` |
| `.cursor/rules/ai-engines-ph90-ph96.mdc` | PRESENT (305 lines) | ABSENT | Preserve dans `main-archived` |
| `.cursor/rules/amazon-sc-extraction-rules.mdc` | PRESENT (235 lines) | ABSENT | Preserve dans `main-archived` |
| `.cursor/rules/keybuzz-v3-latest-state.mdc` | PRESENT (690 lines) | ABSENT | Preserve dans `main-archived` |
| `.cursor/rules/playbooks-ia-rules.mdc` | PRESENT (480 lines) | ABSENT | Preserve dans `main-archived` |
| `.cursor/worktrees.json` | PRESENT (5 lines) | ABSENT | Preserve dans `main-archived` |

### Fichiers .cursor/ sur le workspace local Windows

| Fichier | Present localement | Tracke par Git local | Status Git |
|---|---|---|---|
| `ai-engine-ph43-ph44.mdc` | OUI (11 Ko) | OUI | Clean |
| `ai-engines-ph90-ph96.mdc` | OUI (10 Ko) | OUI | Clean |
| `amazon-sc-extraction-rules.mdc` | OUI (10 Ko) | OUI | Clean |
| `keybuzz-v3-latest-state.mdc` | OUI (53 Ko) | OUI | **Modified** (non committe) |
| `playbooks-ia-rules.mdc` | OUI (20 Ko) | OUI | Clean |
| `amazon-spapi-roles-rules.mdc` | OUI (8 Ko) | NON | **Untracked** (nouveau) |
| `deployment-safety.mdc` | OUI (4 Ko) | NON | **Untracked** (nouveau) |
| `worktrees.json` | OUI (53 bytes) | OUI | Clean |

### Rules "always applied" (chargees par Cursor)

Les 3 rules suivantes sont chargees par Cursor comme "always applied workspace rules" :
- `repricing-rules.mdc`
- `keybuzz-v3-context.mdc`
- `ecomlg-saas-context.mdc`

Ces fichiers sont dans la **configuration projet Cursor** et ne sont PAS dans le depot Git. Ils ne sont PAS affectes par la promotion de baseline.

---

## 2. GARDE-FOU RULES

### Aucune rule perdue definitivement

| Source | Etat apres promotion |
|---|---|
| Fichiers `.cursor/` sur `main-archived` | **PRESERVES** — branche archivee accessible |
| Fichiers `.cursor/` sur le workspace local Windows | **INTACTS** — la promotion est sur le bastion uniquement |
| Rules Cursor "always applied" | **INTACTES** — configuration Cursor, pas Git |

### Plan de recuperation des rules

Les 5 fichiers .mdc qui existaient dans l'ancien `main` sont preserves dans `main-archived` et peuvent etre recuperes a tout moment :

```bash
# Pour recuperer un fichier depuis main-archived :
git show main-archived:.cursor/rules/ai-engine-ph43-ph44.mdc > .cursor/rules/ai-engine-ph43-ph44.mdc
```

Si necessaire, un commit separe "rules only" pourra ajouter ces fichiers au nouveau `main` plus tard. Cette operation n'a PAS ete faite dans cette phase (hors scope).

---

## 3. COMMANDES EXECUTEES

Toutes les commandes ont ete executees sur le bastion (`/opt/keybuzz/keybuzz-client`) :

| # | Commande | Resultat |
|---|---|---|
| 1 | `git fetch --all` | OK |
| 2 | Verification branche = `ph130-plan-gating` @ `e20ded6` | Confirme |
| 3 | `git branch -m main main-archived` | OK — ancien main renomme |
| 4 | `git branch -m ph130-plan-gating main` | OK — ph130 promu |
| 5 | `git push origin main-archived` | OK — nouvelle branche archivee creee sur remote |
| 6 | `git push origin main --force` | OK — `852ef8f...e20ded6 main -> main (forced update)` |
| 7 | `git branch -u origin/main main` | OK — tracking re-etabli |
| 8 | `git push origin :ph130-plan-gating` | OK — branche obsolete supprimee du remote |

---

## 4. NOUVEL ETAT DES BRANCHES

### Bastion (local)

| Branche | HEAD | Tracking | Statut |
|---|---|---|---|
| **`main`** (active) | `e20ded6` PH131-FIX | `origin/main` — up to date | **NOUVELLE BASE SAINE** |
| `main-archived` | `852ef8f` PH-BILLING-FIX-B1 | `origin/main` — ahead 58, behind 45 | Archive, ne pas utiliser |
| `d16-settings` | `db8f4a8` PH-TD-08 | `origin/d16-settings` | A evaluer plus tard |
| `fix/signup-redirect-v2` | `9d62f99` PH129 | local desync | Obsolete |
| `ph-s01.2d-cookie-domain` | `783dafa` | `origin/ph-s01.2d-cookie-domain` | Obsolete |

### Remote (GitHub)

| Branche | HEAD | Statut |
|---|---|---|
| `origin/main` | `e20ded6` | **PROMUE — branche par defaut** |
| `origin/main-archived` | `852ef8f` | Archive (nouveau) |
| `origin/d16-settings` | `db8f4a8` | Inchange |
| `origin/fix/signup-redirect-v2` | `68d4026` | Inchange |
| `origin/ph-s01.2d-cookie-domain` | `783dafa` | Inchange |
| `origin/ph130-plan-gating` | — | **SUPPRIMEE** |

### Working tree

```
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

---

## 5. ETAT RUNTIME (ZERO IMPACT)

| Environnement | Image | Pod | Restarts | Impact |
|---|---|---|---|---|
| **DEV** | `v3.5.100-ph131-fix-kbactions-dev` | `1/1 Running` | 0 | **AUCUN** |
| **PROD** | `v3.5.100-ph131-fix-kbactions-prod` | `1/1 Running` | 0 | **AUCUN** |

---

## 6. PREUVE DE REVERSIBILITE

### Archive accessible

| Element | Valeur |
|---|---|
| Branche archivee | `main-archived` (locale + remote) |
| SHA | `852ef8f5a1d897fc7b57ec6236d5352a86de70e2` |
| Contenu | 56 commits exclusifs (dont billing rejete + TD scripts) |
| Fichiers `.cursor/` | Presents dans `main-archived` |

### Procedure de retour (si necessaire)

```bash
cd /opt/keybuzz/keybuzz-client
git branch -m main ph130-restored
git branch -m main-archived main
git push origin main --force
git branch -u origin/main main
```

### Les rules sont aussi sur le workspace local

Les 7 fichiers `.cursor/rules/*.mdc` existent sur le workspace Windows `c:\DEV\KeyBuzz\V3\.cursor\rules\` et n'ont pas ete touches par cette operation.

---

## 7. IMPACT SUR LE WORKSPACE LOCAL WINDOWS

La promotion a ete executee sur le bastion uniquement. Le workspace local Windows est **inchange**.

| Element | Etat |
|---|---|
| Branche locale | Toujours sur ancien `main` (local) |
| Fichiers `.cursor/rules/` | Tous presents, intacts |
| `keybuzz-v3-latest-state.mdc` | Modifications locales preservees |
| `amazon-spapi-roles-rules.mdc` | Fichier non tracke preserve |
| `deployment-safety.mdc` | Fichier non tracke preserve |

**Note importante** : quand le workspace local sera synchronise avec le nouveau `origin/main`, il faudra :
1. Sauvegarder les fichiers `.cursor/rules/` locaux (ils ne sont pas dans le nouveau `main`)
2. Faire un `git fetch origin` + `git reset --hard origin/main` pour aligner
3. Re-ajouter les fichiers `.cursor/rules/` (soit comme commit, soit comme fichiers non trackes)

Cette synchronisation locale est **hors scope** de cette phase et peut etre faite plus tard.

---

## 8. VERDICT FINAL

### BASELINE PROMOTED SAFELY — RULES PRESERVED OR RECOVERABLE

| Verification | Resultat |
|---|---|
| `main` pointe sur la base saine (`e20ded6`) | **OUI** |
| `main-archived` existe (local + remote) | **OUI** |
| `ph130-plan-gating` supprimee du remote | **OUI** |
| Tracking `main` -> `origin/main` correct | **OUI** |
| Working tree clean | **OUI** |
| DEV runtime inchange | **OUI** |
| PROD runtime inchange | **OUI** |
| Rules Cursor preservees localement | **OUI** |
| Rules Cursor recuperables depuis `main-archived` | **OUI** |
| Rules "always applied" (Cursor config) intactes | **OUI** |
| Retour arriere possible | **OUI** — procedure documentee |

---

*STOP POINT. Aucun build. Aucun deploiement. Aucune correction produit.*
