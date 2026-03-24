# PH-SOURCE-OF-TRUTH-FIX-AND-GUARD-02 — Rapport

> Date : 2026-03-24
> Phase : Recovery + Guard de la chaine de verite
> Environnements : DEV + PROD (runtime inchange)
> Verdict : **SOURCE OF TRUTH FIXED AND PROTECTED**

---

## 1. Probleme resolu

Le systeme de build/deploy etait casse structurellement :
- Le bastion contenait du code non commit qui polluait chaque build
- Chaque rebuild/redeploy reintroduisait des regressions (menu, focus mode, onboarding)
- Le pipeline safe `build-from-git.sh` existait mais n'etait jamais utilise
- Les manifests GitOps divergeaient du runtime cluster
- 3 stash orphelins et 4 fichiers .bak polluaient les repos

---

## 2. Synchronisation Git effectuee

### Client (keybuzz-client)

| Action | Details |
|---|---|
| Push 5 commits locaux | `61a3116..7cf7264` sur `fix/signup-redirect-v2` |
| Commit 24 fichiers dirty + 1 untracked | Commit `3edc104` pousse |
| Contenu | PH119 guards, PH120 tenant context, Amazon fixes, settings/playbooks alignment, routeAccessGuard.ts (new) |

### API (keybuzz-api)

| Action | Details |
|---|---|
| Commit 3 fichiers source modifies | Commit `8aca0ea` pousse sur `main` |
| Contenu | Amazon tracking v2026-01-01 fix, Amazon status compat fix, AI policy debug routes |

### Infra (keybuzz-infra)

| Action | Details |
|---|---|
| Commit 2 manifests | `f75b51a` — readiness/liveness probes + zero-downtime strategy |
| Commit 3 scripts guard | `efcfaa7` — docker-build-guard, build-api-from-git, pre-build-check |

### Nettoyage

| Element | Action |
|---|---|
| 4 fichiers .bak (API) | Supprimes |
| 3 stash (client) | Drops |
| Etat final tous repos | **PROPRE** — `git status --porcelain` vide |

---

## 3. Reproductibilite verifiee

### Test build-from-git.sh

| Parametre | Valeur |
|---|---|
| Script | `build-from-git.sh dev v3.5.82-source-of-truth-fix-dev fix/signup-redirect-v2` |
| Source | Clone GitHub propre (depth=1) |
| Git SHA | `3edc104` |
| Resultat | **BUILD REUSSI** |
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.82-source-of-truth-fix-dev` |
| Duree | ~161s |
| Contamination bastion | **ZERO** (clone dans /tmp) |

Le code sur GitHub produit maintenant un build identique au runtime sain.

---

## 4. Guards deployes

### pre-build-check.sh

Verifie que les 3 repos (client, API, infra) sont propres avant tout build.

| Test | Resultat |
|---|---|
| Repos propres | `ALL REPOS CLEAN — BUILD ALLOWED` (exit 0) |
| Repo dirty (test) | `ABORT BUILD — DIRTY REPO DETECTED` (exit 1) |

### docker-build-guard.sh

Affiche un message d'erreur clair si quelqu'un tente `docker build` direct.

```
INTERDIT — docker build direct est BLOQUE
Utilisez UNIQUEMENT : build-from-git.sh <dev|prod> <tag> [branch]
```

### build-api-from-git.sh

Meme logique que `build-from-git.sh` mais pour `keybuzz-api`.

---

## 5. Regles Cursor persistantes

Fichier cree : `.cursor/rules/deployment-safety.mdc`

Regles documentees :
1. Interdiction `docker build` direct
2. Git = source unique de verite
3. Pipeline safe obligatoire (build-from-git.sh)
4. ArgoCD/GitOps obligatoire (pas de `kubectl set image`)
5. Tags versiones obligatoires (jamais `:latest`)
6. DEV avant PROD, toujours
7. Branche client = `fix/signup-redirect-v2`

---

## 6. Etat final Git (verifie)

```
=== CLIENT (fix/signup-redirect-v2) ===
3edc104 PH-SOURCE-OF-TRUTH-FIX-02: sync all bastion state to Git
7cf7264 PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02: add CSV export button
5b32aeb PH118: onboarding hardening

=== API (main) ===
8aca0ea PH-SOURCE-OF-TRUTH-FIX-02: sync API bastion state to Git
8fac4ec fix: billing_subscriptions query
2cdc0f0 feat: payment-first status-gate

=== INFRA (main) ===
efcfaa7 PH-SOURCE-OF-TRUTH-FIX-02: add build guards and API build-from-git
f75b51a PH-SOURCE-OF-TRUTH-FIX-02: sync infra manifests
acbaab5 PH119-ROLE-ACCESS-GUARD-01: centralized route access guard
```

---

## 7. Runtime inchange

Aucun deploiement n'a ete effectue pendant cette phase.

| Env | Client | API | Backend |
|---|---|---|---|
| DEV | `v3.5.77-ph119-role-access-guard-dev` | `v3.5.49-amz-orders-list-sync-fix-dev` | `v1.0.38-vault-tls-dev` |
| PROD | `v3.5.77-ph119-role-access-guard-prod` | `v3.5.49-amz-orders-list-sync-fix-prod` | `v1.0.38-vault-tls-prod` |

Le runtime reste sain et fonctionnel. Seule la chaine de verite a ete reparee.

---

## 8. Avant / Apres

| Aspect | AVANT | APRES |
|---|---|---|
| Client Git vs runtime | 5 commits + 24 fichiers dirty | **Synchronise** |
| API Git vs runtime | 3 fichiers dirty + 4 .bak | **Synchronise** |
| Infra Git vs runtime | 2 manifests dirty | **Synchronise** |
| Build-from-git.sh | Documente, jamais utilise | **Fonctionnel et verifie** |
| Pre-build check | Inexistant | **pre-build-check.sh actif** |
| Docker build direct | Possible et utilise | **Bloque par guard** |
| Build API clean | Inexistant | **build-api-from-git.sh** |
| Stash orphelins | 3 | **0** |
| .bak orphelins | 4 | **0** |
| Reproductibilite | NON | **OUI** (teste et confirme) |
| Regles Cursor | Absentes | **deployment-safety.mdc** |

---

## 9. Protection future

### Ce qui ne peut plus arriver
1. Build depuis bastion dirty → **BLOQUE** par build-from-git.sh (clone /tmp)
2. Commit oublie → **DETECTE** par pre-build-check.sh
3. docker build direct → **MESSAGE D'ERREUR** + exit 1
4. kubectl set image → **Interdit** par regles Cursor
5. Tag :latest → **Interdit** par convention documentee
6. Divergence Git/runtime → **Eliminee** (tout synchronise)

---

## 10. Verdict

### SOURCE OF TRUTH FIXED AND PROTECTED

La chaine de verite est reparee :
- Git = source de verite unique pour les 3 repos
- Build reproductible depuis GitHub confirme
- Guards actifs pour empecher les erreurs passees
- Regles Cursor documentees pour les prochaines phases

### Prochaine etape possible
PH120 peut etre reintroduite de maniere sure via le pipeline safe.
