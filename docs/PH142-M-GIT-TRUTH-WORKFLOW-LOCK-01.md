# PH142-M — Git Truth Workflow Lock

> Date : 1 mars 2026
> Type : securisation process (aucune feature produit)
> Prerequis : PH142-L (cause racine identifiee)

---

## 1. Cause racine recapitulative

Le rapport PH142-L a demontre que **5 features client majeures** (PH138-B a PH138-L, PH141-E) ont ete perdues silencieusement. La cause racine est un **contournement du workflow Git** :

```
Script Python sur bastion → modifie fichiers source
→ docker build direct depuis le repo dirty → deploiement OK
→ MAIS : jamais de git commit
→ rebuild ulterieur depuis repo Git → fichiers resets → features perdues
```

**Paradoxe** : les scripts de protection existaient deja (PH-TD-08 : `build-from-git.sh`, `docker-build-guard.sh`, `pre-build-check.sh`). Ils n'ont simplement pas ete utilises.

---

## 2. Failles du workflow actuel

### Faille 1 : Scripts Python ecrivent hors Git

Les phases PH138-* modifiaient les fichiers via des scripts Python (`scp` + `ssh python3`) directement dans `/opt/keybuzz/keybuzz-client/`. Ces modifications existaient **uniquement sur le filesystem du bastion**, pas dans Git.

**Preuve** :
```
$ git log --oneline -3 -- src/features/ai-ui/AutopilotSection.tsx
8542bf0 PH131-B.2    ← dernier commit = AVANT PH138
7ff4170 PH131-B.1
73c06ac PH131-B
```

### Faille 2 : Build Docker depuis le repo dirty

Le `docker build` utilise `COPY app ./app` et `COPY src ./src` — il copie tout le working directory, **y compris les modifications non commitees**. Le build fonctionne, l'image est correcte, mais le code source n'est pas dans Git.

### Faille 3 : Rebuild ecrase les modifications

Lors d'un `git pull` ou d'un nouveau cycle de modification, les fichiers modifies sont **ecrases** par la version Git (qui ne contient pas les modifications PH138/PH141).

### Faille 4 : Pas de check de presence des features

Le `pre-prod-check.sh` (PH142-I) verificait uniquement la sante API (endpoints HTTP + DB counts), pas la **presence des features client** (CTAs, deep-links, addon gating).

### Etat reel constate (1 mars 2026)

```
keybuzz-client/  → 3 fichiers M (modifies non commites)
                   21 fichiers ?? (untracked)
                   dont: SignatureTab.tsx, routes BFF addon, AutopilotDraftBanner.tsx

keybuzz-api/     → 18 fichiers M (modifies non commites)
                   11 fichiers ?? (untracked)
                   dont: signatureResolver.ts, ai-mode-engine.ts, shared-ai-context.ts
```

Les features deployes **existent sur le bastion** comme modifications non commitees, mais sont invisibles pour Git.

---

## 3. Regles verrouillees

### Regle 1 : Git = seule source de verite
Toute modification durable du code source DOIT exister dans Git avant le build Docker.

### Regle 2 : Commit obligatoire avant build
Apres chaque modification (script Python, edition manuelle, patch), le Cursor Executor DOIT :
```bash
git add -A
git commit -m "PH-XXX: description"
git push origin main
```

### Regle 3 : Build depuis clone Git frais uniquement
Utiliser `build-from-git.sh` qui :
1. Clone depuis GitHub dans `/tmp/`
2. Verifie que le clone est propre
3. Build Docker depuis le clone
4. Supprime le clone apres build

### Regle 4 : Interdiction du docker build direct
Le script `docker-build-guard.sh` bloque tout `docker build` direct dans les repos `/opt/keybuzz/keybuzz-*`.

### Regle 5 : Cursor rule permanente
Fichier `.cursor/rules/git-source-of-truth.mdc` documente et impose le workflow pour le Cursor Executor.

---

## 4. Scripts/checks ajoutes

### `assert-git-committed.sh` (nouveau)

Verifie que tous les repos sont propres avant build. Affiche les fichiers en cause et bloque si dirty.

```bash
./assert-git-committed.sh                    # verifie client + api
./assert-git-committed.sh /opt/keybuzz/keybuzz-client  # verifie un repo
```

Comportement :
- Liste les fichiers Modifies et Untracked (hors .bak, dist, node_modules)
- Affiche la commande exacte pour corriger
- `exit 1` si dirty, `exit 0` si propre

### Scripts existants (rappel PH-TD-08)

| Script | Role | Statut |
|---|---|---|
| `build-from-git.sh` | Build client depuis clone Git frais | Existant, operationnel |
| `build-api-from-git.sh` | Build API depuis clone Git frais | Existant, operationnel |
| `docker-build-guard.sh` | Bloque docker build direct | Existant |
| `pre-build-check.sh` | Verifie repos propres (ancienne version) | Existant |

---

## 5. Pre-prod-check V2

### Ajouts par rapport a V1 (PH142-I)

| # | Check V1 | Type |
|---|---|---|
| 1 | API health | HTTP |
| 2 | Client health | HTTP |
| 3 | Inbox API endpoint | HTTP interne |
| 4 | Dashboard API endpoint | HTTP interne |
| 5 | AI Settings endpoint | HTTP interne |
| 6 | AI Journal endpoint | HTTP interne |
| 7 | Autopilot draft endpoint | HTTP interne |
| 8 | Signature config in DB | SQL |
| 9 | Orders count > 0 | SQL |
| 10 | Channels count > 0 | SQL |

| # | Check V2 (nouveau) | Type |
|---|---|---|
| 11 | Git clean: keybuzz-client | Git status |
| 12 | Git clean: keybuzz-api | Git status |
| 13 | Billing current endpoint | HTTP interne |
| 14 | Agent KeyBuzz status API | HTTP interne |
| 15 | DB has_agent_keybuzz_addon column | SQL schema |
| 16 | Addon API structure valid | HTTP parse |
| 17 | billing/current hasAddon field | HTTP parse |
| 18 | Agents API endpoint | HTTP interne |
| 19 | Signature API endpoint | HTTP interne |
| 20-23 | Client feature presence (upgradePlan, activateAddon, useSearchParams, SignatureTab) | grep in client pod |

### Fichiers

- `pre-prod-check-v2.sh` : script bash principal
- `pre-prod-checks-v2.js` : checks Node.js internes (execute dans le pod API)

---

## 6. Procedure standard de build/deploy

### Procedure normale (CE modifie du code)

```bash
# 1. Modifier le code sur le bastion
ssh root@46.62.171.61 -i ~/.ssh/id_rsa_keybuzz_v3
cd /opt/keybuzz/keybuzz-client  # ou keybuzz-api

# 2. Appliquer les modifications (script Python, edition, patch)
python3 /tmp/ph-xxx-modify.py

# 3. OBLIGATOIRE : commiter
git add -A
git commit -m "PH-XXX: description des changements"
git push origin main

# 4. Verifier que le repo est propre
./keybuzz-infra/scripts/assert-git-committed.sh

# 5. Build depuis Git propre
cd /opt/keybuzz/keybuzz-infra/scripts
./build-from-git.sh dev v3.5.XXX-feature-name-dev main

# 6. Push image
docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-dev

# 7. Deploy
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# 8. Pre-prod check V2
./pre-prod-check-v2.sh dev
```

### Procedure PROD (promotion DEV → PROD)

```bash
# 1. Pre-prod check V2 sur DEV
./pre-prod-check-v2.sh dev

# 2. Build PROD depuis Git
./build-from-git.sh prod v3.5.XXX-feature-name-prod main

# 3. Push + deploy PROD
docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-name-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod

# 4. Pre-prod check V2 sur PROD
./pre-prod-check-v2.sh prod

# 5. GitOps : mettre a jour deployment.yaml
```

### Procedure d'urgence (hotfix)

Meme procedure que ci-dessus, mais :
1. Le commit message prefixe avec `HOTFIX:`
2. Le tag Docker utilise `-hotfix-` au lieu de `-feature-`
3. Le pre-prod-check V2 reste obligatoire

---

## 7. Rollback process

### Rollback image

```bash
# Identifier l'image precedente
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'

# Rollback
kubectl rollout undo deployment/keybuzz-client -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### Rollback Git

```bash
# Identifier le commit precedent
git log --oneline -5

# Revert le dernier commit
git revert HEAD --no-edit
git push origin main

# Rebuild depuis le commit reverted
./build-from-git.sh dev v3.5.XXX-rollback-dev main
```

---

## 8. Diagnostic : pourquoi les scripts existants n'ont pas ete utilises

| Script existant | Raison du contournement |
|---|---|
| `build-from-git.sh` | Le CE utilisait `docker build .` directement car plus rapide |
| `docker-build-guard.sh` | N'est pas un alias de `docker` — le CE appelait `docker build` directement |
| `pre-build-check.sh` | N'etait pas execute systematiquement avant les builds |

### Solution

1. **Cursor rule** : `.cursor/rules/git-source-of-truth.mdc` impose le workflow au CE
2. **assert-git-committed.sh** : check explicite et rapide, message d'erreur clair
3. **pre-prod-check V2** : detecte les regressions apres deploiement

Le probleme n'etait pas l'absence d'outils, mais l'absence d'une regle Cursor forcant leur utilisation.

---

## Verdict

**GIT IS SOURCE OF TRUTH — NO MORE BASTION-ONLY FEATURES — REBUILDS SAFE — SILENT REGRESSIONS PREVENTED**
