# PH-ADMIN-T8.11AH.1 — Marketing Menu Truth Cleanup — PROD Promotion

> Date : 29 avril 2026
> Auteur : Agent Cursor
> Source : PH-ADMIN-T8.11AH (DEV validé)
> Cible : PROD

---

## 1. PRÉFLIGHT

| Élément | Valeur | Verdict |
|---|---|---|
| Admin V2 branche | `main` | PASS |
| Admin V2 HEAD | `fee1a7d` (exact, attendu) | PASS |
| Admin V2 upstream | sync | PASS |
| Admin V2 working tree | clean | PASS |
| Infra branche | `main` | PASS |
| Infra HEAD | `4e09f56` | PASS |
| Admin DEV runtime | `v2.11.30-marketing-menu-truth-cleanup-dev` | Inchangé |
| Admin PROD runtime avant | `v2.11.22-acquisition-playbook-baseline-prod` | Confirmé |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | Inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | Inchangé |

---

## 2. CORRECTION DOCUMENTAIRE

Le rapport PH-ADMIN-T8.11AH contenait un rollback avec `kubectl set image` (commande impérative).

**Correction appliquée** : section rollback remplacée par une procédure GitOps stricte.
- Commit : `3461279` (infra)
- Contenu : modifier manifest → commit → push → `kubectl apply -f`

---

## 3. BUILD PROD

| Élément | Valeur |
|---|---|
| Méthode | Clone temporaire propre (`/tmp/ah1-admin-prod-$$`) |
| Commit source | `fee1a7d` (vérifié en detached HEAD) |
| Working tree | clean (vérifié avant build) |
| Build flags | `--no-cache`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.23-marketing-menu-truth-cleanup-prod` |
| Digest | `sha256:5cbcd0e6dee330f022a6fd120f1e1807a628bb3fb443b0a1200d364bca14046f` |
| Cleanup | Clone temporaire supprimé après push |

Aucun build depuis repo persistant bastion.

---

## 4. GITOPS PROD

| Étape | Résultat |
|---|---|
| Manifest modifié | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image | `v2.11.23-marketing-menu-truth-cleanup-prod` |
| Rollback annoté | `v2.11.22-acquisition-playbook-baseline-prod` |
| Commit infra | `bb3370f` |
| Push | `origin main` |
| `kubectl apply -f` | `deployment.apps/keybuzz-admin-v2 configured` |
| Rollout status | `successfully rolled out` |
| Runtime image | `v2.11.23-marketing-menu-truth-cleanup-prod` ✅ |
| Annotation image | `v2.11.23-marketing-menu-truth-cleanup-prod` ✅ |
| Pod | `1/1 Running`, 0 restarts |

Aucune commande impérative utilisée.

---

## 5. VALIDATION PROD — PAGES

### Reachability (9/9)

| Page | HTTP | Résultat |
|---|---|---|
| `/metrics` | 307 | ✅ (redirect login, normal) |
| `/marketing/funnel` | 307 | ✅ |
| `/marketing/ad-accounts` | 307 | ✅ |
| `/marketing/paid-channels` | 307 | ✅ |
| `/marketing/destinations` | 307 | ✅ |
| `/marketing/google-tracking` | 307 | ✅ |
| `/marketing/delivery-logs` | 307 | ✅ |
| `/marketing/acquisition-playbook` | 307 | ✅ |
| `/marketing/integration-guide` | 307 | ✅ |

### Bundle grep — termes interdits (PROD pod)

| Terme | Résultat |
|---|---|
| `codex` | **NONE** ✅ |
| `utm_source=facebook` | **NONE** ✅ |
| `Meta uniquement pour` | **NONE** ✅ |
| `en finalisation` | **NONE** ✅ |

### Bundle grep — termes attendus (PROD pod)

| Terme | Fichier(s) | Résultat |
|---|---|---|
| `internal-validation` | acquisition-playbook | ✅ |
| `spend actif` | acquisition-playbook | ✅ |
| `utm_source=meta` | integration-guide, acquisition-playbook | ✅ |
| `LinkedIn CAPI` | delivery-logs, integration-guide, google-tracking | ✅ |
| `credentials GitOps` | ad-accounts, integration-guide | ✅ |

### API URL

| Check | Résultat |
|---|---|
| `api-dev.keybuzz.io` dans bundle PROD | **NONE** ✅ |

### `/metrics/overview`

`/metrics/overview` est un endpoint API (`/api/admin/metrics/overview`), pas une page Admin. La page Admin est `/metrics`. Confirmé dans le bundle : aucune route de page `/metrics/overview`.

---

## 6. VALIDATION PROD — DATA

### Ad Accounts PROD

| Platform | Account ID | Status | Last Sync |
|---|---|---|---|
| google | `5947963982` | active | 2026-04-28T20:50:06 |
| meta | `1485150039295668` | active | 2026-04-23T09:01:19 |

### Spend PROD

| Platform | Rows | Total Spend |
|---|---|---|
| meta | 16 | £445.20 |
| google | 2 | £0.0628 |

Meta spend conservé ✅. Google spend réel conservé ✅.

### API Health

```json
{"status":"ok","service":"keybuzz-api","version":"1.0.0"}
```

---

## 7. NON-RÉGRESSION

| Check | Résultat |
|---|---|
| Pod PROD | `1/1 Running` |
| Restarts | 0 |
| API PROD image | `v3.5.123-linkedin-capi-native-prod` (inchangé) |
| Client PROD image | `v3.5.125-register-console-cleanup-prod` (inchangé) |
| Admin DEV image | `v2.11.30-marketing-menu-truth-cleanup-dev` (inchangé) |
| Secrets exposés | **AUCUN** |
| Commandes impératives | **AUCUNE** |

---

## 8. LINEAR

| Ticket | Action |
|---|---|
| Campaign QA / URL Builder | À créer (P2) — spec dans rapport PH-ADMIN-T8.11AH section 6 |
| KEY-217 (signup_complete sync) | Reste ouvert |
| TikTok spend | Bloqué (business/credentials) |
| LinkedIn spend | Hors scope (Ads Reporting approval) |

---

## 9. FICHIERS MODIFIÉS

| Fichier | Repo | Action |
|---|---|---|
| `k8s/keybuzz-admin-v2-prod/deployment.yaml` | keybuzz-infra | Image → v2.11.23-marketing-menu-truth-cleanup-prod |
| `docs/PH-ADMIN-T8.11AH-...md` | keybuzz-infra | Correction rollback impératif → GitOps |

Aucune modification API, Client, ou Website.

---

## 10. ROLLBACK GITOPS

En cas de problème PROD :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` → image `v2.11.22-acquisition-playbook-baseline-prod`
2. `git commit -m "rollback Admin PROD to v2.11.22"` + `git push origin main`
3. `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod`

> **Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`, `kubectl set env`.

---

## 11. ARTEFACTS

| Élément | Valeur |
|---|---|
| Admin commit source | `fee1a7d` |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.23-marketing-menu-truth-cleanup-prod` |
| Digest PROD | `sha256:5cbcd0e6dee330f022a6fd120f1e1807a628bb3fb443b0a1200d364bca14046f` |
| Infra commit doc fix | `3461279` |
| Infra commit GitOps PROD | `bb3370f` |
| Infra commit rapport | (ce commit) |
| Rollback PROD | `v2.11.22-acquisition-playbook-baseline-prod` |
| DEV | Inchangé (`v2.11.30-marketing-menu-truth-cleanup-dev`) |

---

## 12. VERDICT

**MARKETING MENU TRUTH CLEANUP LIVE IN PROD — GOOGLE SPEND/KPI ALIGNED — GOOGLE/YOUTUBE CLARIFIED — TIKTOK BLOCKED HONESTLY — LINKEDIN CAPI NATIVE LABELED — NO CODEX VISIBLE — GITOPS STRICT — NO TRACKING DRIFT**
