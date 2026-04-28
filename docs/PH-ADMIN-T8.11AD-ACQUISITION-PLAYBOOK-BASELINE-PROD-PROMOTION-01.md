# PH-ADMIN-T8.11AD-ACQUISITION-PLAYBOOK-BASELINE-PROD-PROMOTION-01 — TERMINÉ

Verdict : **GO**

**KEY-219** — Acquisition Playbook baseline promu en PROD

---

## Préflight

| Point | Attendu | Constaté | Verdict |
|---|---|---|---|
| Admin branche | `main` | `main` | ✅ |
| Admin HEAD | `5cf0bda` | `5cf0bda` | ✅ |
| Admin upstream | `5cf0bda` | `5cf0bda` | ✅ |
| Admin clean | 0 fichiers | 0 fichiers | ✅ |
| Infra branche | `main` | `main` | ✅ |
| Infra HEAD = upstream | oui | `f55d470` = `f55d470` | ✅ |
| Infra dirty scope PROD | non | hors scope uniquement | ✅ |
| PROD image avant | `v2.11.21-marketing-surfaces-truth-alignment-prod` | confirmé | ✅ |
| PROD pod avant | Running 1/1 | Running 1/1 | ✅ |
| DEV image | `v2.11.29-acquisition-playbook-baseline-dev` | confirmé | ✅ |

---

## Sources relues

| Document | Relu |
|---|---|
| `process-lock.mdc` | ✅ |
| `git-source-of-truth.mdc` | ✅ (session précédente AC.1) |
| `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md` | ✅ (session précédente AC.1) |
| `AI_MEMORY/RULES_AND_RISKS.md` | ✅ (session précédente AC.1) |
| Rapport PH-ADMIN-T8.11AC | ✅ (session précédente AC.1) |
| Rapport PH-ADMIN-T8.11AC.1 | ✅ (session précédente AC.2) |

---

## Build PROD strict

| Point | Attendu | Constaté | Verdict |
|---|---|---|---|
| Script | `build-admin-from-git.sh` | `build-admin-from-git.sh` | ✅ |
| Méthode | clone temporaire | `/tmp/build-admin-4061610/repo` | ✅ |
| Repo source | `keybuzz-admin-v2` | `github.com/keybuzzio/keybuzz-admin-v2.git` | ✅ |
| Branche | `main` | `main` | ✅ |
| Commit | `5cf0bda` | `5cf0bda9d9f80397a21d137bfa98b445c6460e5d` | ✅ |
| Working tree | CLEAN | CLEAN | ✅ |
| `--no-cache` | oui | oui | ✅ |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` | `https://api.keybuzz.io` | ✅ |
| `NEXT_PUBLIC_APP_ENV` | `production` | `production` | ✅ |
| Compiled | success | ✅ 45/45 pages | ✅ |
| Tag | `v2.11.22-acquisition-playbook-baseline-prod` | ✅ | ✅ |
| Digest | documenté | `sha256:468781c91a26f1a9384d3f21f1fb6e5da302558d728dee8245599f43cd48d25b` | ✅ |
| Push GHCR | success | ✅ | ✅ |
| Cleanup `/tmp` | oui | oui | ✅ |
| Aucun `git reset --hard` | oui | oui — clone frais | ✅ |
| Aucun repo persistant | oui | oui — `/tmp/` uniquement | ✅ |

---

## GitOps PROD

| Élément | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `v2.11.20-acquisition-playbook-hotfix-prod` (manifest) / `v2.11.21-marketing-surfaces-truth-alignment-prod` (runtime) |
| Image après | `v2.11.22-acquisition-playbook-baseline-prod` |
| Rollback | `v2.11.21-marketing-surfaces-truth-alignment-prod` |
| Commit infra | `2f7e437` — `gitops(prod): promote Admin v2.11.22-acquisition-playbook-baseline-prod (KEY-219)` |
| Push | ✅ `f55d470..2f7e437 main -> main` |
| Deploy method | `kubectl apply -f` (GitOps strict) |
| Rollout | `successfully rolled out` |

**Note** : un drift pré-existant a été observé — le manifest PROD indiquait `v2.11.20` alors que le runtime était à `v2.11.21`. Ce drift provenait d'une promotion antérieure (PH-ADMIN-T8.11R.1) qui avait utilisé une commande impérative sans mettre à jour le manifest. Ce drift est maintenant résolu : manifest, runtime et annotation pointent tous vers `v2.11.22`.

---

## Runtime/Manifest/Annotation PROD

| Point | Valeur | Verdict |
|---|---|---|
| Runtime image | `v2.11.22-acquisition-playbook-baseline-prod` | ✅ |
| Annotation image | `v2.11.22-acquisition-playbook-baseline-prod` | ✅ |
| Match runtime/annotation | YES | ✅ |
| Pod | 1/1 Running, 0 restarts | ✅ |

---

## Validation PROD (contenu Playbook)

| Check | Attendu | Résultat |
|---|---|---|
| "Baseline de lecture" | ≥ 1 occurrence | ✅ 3 occurrences |
| "29 avril 2026" | ≥ 1 | ✅ 3 |
| "prod_tiktok_launch" | ≥ 1 | ✅ 3 |
| "codex-prod-runtime-check" | ≥ 1 | ✅ 3 |
| "445 GBP" | ≥ 1 | ✅ 3 |
| "import GA4" | ≥ 1 | ✅ 3 |
| "signup_complete" | ≥ 1 | ✅ 3 |
| "missing Google tag" | ≥ 1 | ✅ 3 |
| "CAPI native" | ≥ 1 | ✅ 3 |
| AW-18098643667 (secret) | 0 | ✅ 0 |
| D7HQO0JC77U2ODPGMDI0 (secret) | 0 | ✅ 0 |

---

## Non-régression Marketing PROD

### Pages présentes

| Page | Taille HTML | Verdict |
|---|---|---|
| `/marketing/acquisition-playbook` | 81 866 octets | ✅ |
| `/marketing/paid-channels` | 73 017 octets | ✅ |
| `/marketing/google-tracking` | 36 166 octets | ✅ |
| `/marketing/integration-guide` | 98 055 octets | ✅ |
| `/marketing/destinations` | 36 162 octets | ✅ |
| `/marketing/funnel` | 35 839 octets | ✅ |
| `/marketing/ad-accounts` | 36 154 octets | ✅ |
| `/marketing/delivery-logs` | 36 111 octets | ✅ |
| `/metrics` | 37 275 octets | ✅ |
| `/login` | 6 861 octets | ✅ |

### Contenu clé

| Vérification | Résultat |
|---|---|
| "LinkedIn CAPI" présent dans paid-channels, destinations, integration-guide, google-tracking, funnel | ✅ 13 fichiers |
| "CAPI native" présent dans acquisition-playbook | ✅ 3 fichiers |
| "sGTM" référencé | ✅ 16 fichiers |

### Services non touchés

| Service | Image | Verdict |
|---|---|---|
| API PROD | `v3.5.123-linkedin-capi-native-prod` | ✅ inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | ✅ inchangé |
| Admin DEV | `v2.11.29-acquisition-playbook-baseline-dev` | ✅ inchangé |

---

## Rollback GitOps (documenté, non exécuté)

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` — image → `v2.11.21-marketing-surfaces-truth-alignment-prod`
2. `git commit -m "rollback(prod): Admin v2.11.21-marketing-surfaces-truth-alignment-prod"` + `git push`
3. Bastion : `git pull origin main && kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=180s`

---

## Linear

### KEY-219 — fermable

| Critère | Statut |
|---|---|
| DEV validé | ✅ PH-ADMIN-T8.11AC |
| Process audit | ✅ PH-ADMIN-T8.11AC.1 + AC.2 |
| PROD build conforme | ✅ `build-admin-from-git.sh`, clone temporaire, commit `5cf0bda` |
| PROD déployé | ✅ GitOps strict, `kubectl apply -f` |
| Contenu vérifié | ✅ 11 checks PASS, 0 secrets |
| Non-régression | ✅ 8 pages marketing + login + metrics |
| Rollback documenté | ✅ GitOps strict |
| PROD runtime = manifest = annotation | ✅ |

**Réserve** : le build DEV (PH-ADMIN-T8.11AC) avait utilisé une méthode non conforme (repo persistant), documentée dans AC.1. Le build PROD est pleinement conforme (clone temporaire via `build-admin-from-git.sh`).

### KEY-217

Non modifié — `signup_complete` toujours en propagation côté Google Ads.

---

## Gaps restants

| # | Gap | Priorité |
|---|---|---|
| 1 | `signup_complete` Google Ads non synced (KEY-217) — à mettre à jour dans le Playbook quand GO | P1 |
| 2 | Fichiers infra hors scope non committés (30+ rapports de phases diverses) | P3 |

---

## Artefacts

| Élément | Valeur |
|---|---|
| Admin source commit | `5cf0bda` (`main`) |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.22-acquisition-playbook-baseline-prod` |
| Digest PROD | `sha256:468781c91a26f1a9384d3f21f1fb6e5da302558d728dee8245599f43cd48d25b` |
| Build method | `build-admin-from-git.sh` — clone temporaire, commit vérifié, clean state |
| Commit infra | `2f7e437` — `gitops(prod): promote Admin v2.11.22-acquisition-playbook-baseline-prod (KEY-219)` |
| Manifest PROD | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Rollback PROD | `v2.11.21-marketing-surfaces-truth-alignment-prod` |
| Image DEV | `v2.11.29-acquisition-playbook-baseline-dev` — inchangée |
| API PROD | inchangée |
| Client PROD | inchangé |
| Rapport | `keybuzz-infra/docs/PH-ADMIN-T8.11AD-ACQUISITION-PLAYBOOK-BASELINE-PROD-PROMOTION-01.md` |

---

**VERDICT : ACQUISITION PLAYBOOK BASELINE LIVE IN PROD — BUILD FROM CLEAN GIT CLONE — GITOPS STRICT — RUNTIME MATCHES MANIFEST — AGENCY READING RULE AVAILABLE — NO TRACKING DRIFT — NO PROD REGRESSION**
