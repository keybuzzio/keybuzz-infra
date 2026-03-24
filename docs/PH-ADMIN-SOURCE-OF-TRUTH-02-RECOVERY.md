# PH-ADMIN-SOURCE-OF-TRUTH-02 — RECOVERY EXECUTION

> Date : 2026-03-24
> Statut : TERMINE — Git = source de verite unique
> Prerequis : PH-ADMIN-SOURCE-OF-TRUTH-01 (audit)

---

## 1. Alignement GitOps

### Avant

| Env | Manifest image | Runtime image | Drift |
|---|---|---|---|
| DEV | `v2.1.4-ph112-ai-control-center` | `v2.10.1-ph-admin-87-15b-dev` | 8+ versions |
| PROD | `v2.1.4-ph112-ai-control-center-prod` | `v2.10.1-ph-admin-87-15b-prod` | 8+ versions |

### Apres

| Env | Manifest image | Runtime image | Drift |
|---|---|---|---|
| DEV | `v2.10.1-ph-admin-87-15b-dev` | `v2.10.1-ph-admin-87-15b-dev` | AUCUN |
| PROD | `v2.10.1-ph-admin-87-15b-prod` | `v2.10.1-ph-admin-87-15b-prod` | AUCUN |

### Actions

1. Mise a jour des image tags dans les manifests (commit `06f94a5`)
2. Nettoyage complet des manifests : suppression des metadonnees stales (resourceVersion, uid, creationTimestamp, generation, last-applied-configuration annotation, status section) → format declaratif propre (commit `5f934eb`)
3. `kubectl apply -f` sur les deux manifests : **aucun rollout** declenche (meme image deja en cours)

### Diff Git

```diff
-        image: ghcr.io/keybuzzio/keybuzz-admin:v2.1.4-ph112-ai-control-center
+        image: ghcr.io/keybuzzio/keybuzz-admin:v2.10.1-ph-admin-87-15b-dev
```

```diff
-        image: ghcr.io/keybuzzio/keybuzz-admin:v2.1.4-ph112-ai-control-center-prod
+        image: ghcr.io/keybuzzio/keybuzz-admin:v2.10.1-ph-admin-87-15b-prod
```

---

## 2. Runtime vs Git — Preuve egalite

| Element | Manifest Git | Cluster runtime | Match |
|---|---|---|---|
| DEV image tag | `v2.10.1-ph-admin-87-15b-dev` | `v2.10.1-ph-admin-87-15b-dev` | OUI |
| PROD image tag | `v2.10.1-ph-admin-87-15b-prod` | `v2.10.1-ph-admin-87-15b-prod` | OUI |
| DEV digest | `sha256:52c6c1379d84...` | `sha256:52c6c1379d84...` | OUI |
| PROD digest | `sha256:52c6c1379d84...` | `sha256:52c6c1379d84...` | OUI |
| DEV pod status | — | Running, 0 restarts, 20h | SAIN |
| PROD pod status | — | Running, 0 restarts, 20h | SAIN |

**ArgoCD** : admin N'EST PAS gere par ArgoCD. Pas de risque de sync auto.

---

## 3. Build Script

### Fichier : `keybuzz-infra/scripts/build-admin-from-git.sh`

**Usage :**
```bash
./build-admin-from-git.sh <dev|prod> <tag> [branch|sha]
./build-admin-from-git.sh dev v2.10.2-my-feature-dev main
./build-admin-from-git.sh prod v2.10.2-my-feature-prod main
```

**Logique :**
1. Clone le repo `keybuzzio/keybuzz-admin-v2` dans `/tmp/build-admin-$$`
2. Checkout branche/tag/SHA specifie
3. Verifie `git status --porcelain` → ABORT si dirty
4. `docker build --no-cache` avec build-args corrects :
   - DEV : `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=development`
   - PROD : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
5. `docker push` vers `ghcr.io/keybuzzio/keybuzz-admin:<tag>`
6. Cleanup du repertoire temporaire

**Securites :**
- Clone frais depuis GitHub (pas de fichiers locaux)
- Verification clean avant build
- `--no-cache` pour eviter les layers stales
- Repertoire temporaire isole (`/tmp/build-admin-$$`)

### `.dockerignore` ajoute au repo admin

```
.git
.gitignore
node_modules
.next
.env
.env.*
*.md
LICENSE
.cursor
.vscode
tmp
.tmp
*.log
Dockerfile
.dockerignore
```

Commit admin : `4f22ae5` — push OK
Commit infra : `e68089c` — push OK

---

## 4. Test rebuild reproductible

### Commande executee
```bash
./build-admin-from-git.sh prod v2.10.1-sot02-rebuild-test-prod main
```

### Resultats

| Element | Valeur |
|---|---|
| Commit source | `4f22ae5` (main, includes `.dockerignore`) |
| Build | OK — 36 pages, middleware 49.7KB, toutes routes API presentes |
| Push | OK vers `ghcr.io/keybuzzio/keybuzz-admin:v2.10.1-sot02-rebuild-test-prod` |
| Digest rebuild | `sha256:10c2af8819c9191f...` |
| Digest runtime | `sha256:52c6c1379d84d4bf...` |

### Verdict

**FONCTIONNELLEMENT REPRODUCTIBLE** — le rebuild compile avec succes, produit les memes 36 pages, meme middleware, memes routes API.

**Digests differents** — attendu car :
- Commit different (`4f22ae5` vs `06c0c79` — ajout `.dockerignore`)
- Docker builds non-deterministes (timestamps, layer IDs)
- Contexte build different (`.dockerignore` exclut `.git`, `node_modules`)

Le prochain build de feature utilisera ce script et produira des images tracables.

---

## 5. Corrections appliquees

| # | Action | Fichier | Commit |
|---|---|---|---|
| 1 | Aligner image tags manifests | `k8s/keybuzz-admin-v2-dev/deployment.yaml` | `06f94a5` |
| 2 | Aligner image tags manifests | `k8s/keybuzz-admin-v2-prod/deployment.yaml` | `06f94a5` |
| 3 | Nettoyer manifests (format declaratif) | Memes fichiers | `5f934eb` |
| 4 | Creer `.dockerignore` | `keybuzz-admin-v2/.dockerignore` | `4f22ae5` |
| 5 | Creer build script safe | `keybuzz-infra/scripts/build-admin-from-git.sh` | `e68089c` |

---

## 6. Rules Cursor mises a jour

**Fichier** : `.cursor/rules/keybuzz-v3-latest-state.mdc`

**Changements** :
- Admin v2 : `v0.23.0-ph87.6b` → `v2.10.1-ph-admin-87-15b` (DEV + PROD)
- Ajout rollback tags admin
- Ajout section "Admin v2 — Build Pipeline" avec interdiction `docker build` direct et obligation `build-admin-from-git.sh`
- Date mise a jour : 24 mars 2026

**Fichier** : `.cursor/rules/deployment-safety.mdc` (deja a jour depuis PH-SOURCE-OF-TRUTH-FIX-AND-GUARD-02)

---

## 7. Validation DEV / PROD

### Cluster

| Env | Image | Pod | Restarts | Uptime | Apply impact |
|---|---|---|---|---|---|
| DEV | `v2.10.1-ph-admin-87-15b-dev` | Running 1/1 | 0 | 20h | Aucun rollout |
| PROD | `v2.10.1-ph-admin-87-15b-prod` | Running 1/1 | 0 | 20h | Aucun rollout |

### Navigateur

| URL | DEV | PROD |
|---|---|---|
| `admin-dev.keybuzz.io/login` | OK — page login accessible | — |
| `admin.keybuzz.io/login` | — | OK — page login accessible |

### Git repos

| Repo | Branche | Sync remote | Dirty | Untracked |
|---|---|---|---|---|
| `keybuzz-admin-v2` | main | `4f22ae5` = remote | 0 | 0 |
| `keybuzz-infra` | main | `e68089c` = remote | 1 (`client-dev` non admin) | 0 |

---

## 8. Rollback

| Env | Image de rollback |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.4-ph112-ai-control-center` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.4-ph112-ai-control-center-prod` |

**Procedure** :
1. Modifier `deployment.yaml` avec l'image de rollback
2. `git add + commit + push`
3. `kubectl apply -f deployment.yaml`

---

## 9. Etat final — Source of Truth

| Critere | Avant SOT-02 | Apres SOT-02 |
|---|---|---|
| Manifests = runtime | NON (8+ versions d'ecart) | OUI |
| Build script safe | NON (inexistant) | OUI (`build-admin-from-git.sh`) |
| `.dockerignore` | NON | OUI |
| Admin repo clean | OUI | OUI |
| Infra repo clean (admin) | OUI (mais manifests faux) | OUI |
| Rules Cursor a jour | NON (`v0.23.0`) | OUI (`v2.10.1`) |
| Rebuild reproductible | Non verifie | VERIFIE — fonctionnellement OK |
| `kubectl apply` safe | DANGEREUX (revert v2.1.4) | SAFE (applique v2.10.1) |

### VERDICT : SOURCE OF TRUTH OK
