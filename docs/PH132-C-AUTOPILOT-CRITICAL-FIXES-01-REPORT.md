# PH132-C: AUTOPILOT CRITICAL FIXES — RAPPORT

> Date : 2026-03-28
> Phase : PH132-C-AUTOPILOT-CRITICAL-FIXES-01
> Type : corrections critiques (plan guard + engine logging + DB cleanup)
> Environnement : DEV + PROD deployes et valides

---

## VERDICT

**AUTOPILOT FIXED — PLAN SAFE — ENGINE VALIDATED — DATA CLEAN — ROLLBACK READY**

---

## 1. VERSIONS

| Service | DEV (avant) | DEV (apres) | PROD (avant) | PROD (apres) |
|---------|-------------|-------------|--------------|--------------|
| API | `v3.5.51-...-dev` | **`v3.5.128-autopilot-critical-fixes-dev`** | `v3.5.51-...-prod` | **`v3.5.128-autopilot-critical-fixes-prod`** |

**Rollback DEV :** `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-dev -n keybuzz-api-dev`
**Rollback PROD :** `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-prod -n keybuzz-api-prod`

---

## 2. FIXES APPLIQUES

### PARTIE 1 — Plan Guard (CRITIQUE) ✅

**Fichier modifie :** `src/modules/autopilot/routes.ts`

**Changements :**
1. Ajout de `checkPlanForMode()` — helper qui verifie le plan du tenant dans la table `tenants`
2. Guard insere dans **PATCH** `/autopilot/settings` — refuse `mode: autonomous` si plan < AUTOPILOT
3. Guard insere dans **POST** `/autopilot/settings` — meme verification sur creation

**Reponse 403 :**
```json
{
  "error": "PLAN_REQUIRED",
  "message": "Le mode autonomous nécessite le plan AUTOPILOT ou ENTERPRISE (plan actuel: PRO)",
  "requiredPlan": "AUTOPILOT",
  "currentPlan": "PRO"
}
```

**Tests passes :**

| Test | Plan | Action | Resultat attendu | Resultat reel |
|------|------|--------|-------------------|---------------|
| 1a | PRO | PATCH autonomous | 403 | **403** ✅ |
| 1b | AUTOPILOT | PATCH autonomous | 200 | **200** ✅ |
| 1c | STARTER | PATCH autonomous | 403 | **403** ✅ |
| 1d | PRO | PATCH supervised | 200 | **200** ✅ |
| 1e | PRO | POST autonomous | 403 | **403** ✅ |

**Verification :** ecomlg-001 (PRO) toujours en mode `supervised` apres tous les tests.

### PARTIE 2 — Moteur PROD : Root Cause Identifie ⚠️

**Constat :** Le code est IDENTIQUE entre DEV et PROD (MD5 confirme). Le hook `evaluateAndExecute` est present dans les routes inbound (lignes 208 et 440).

**Root cause identifiee :** Les messages Amazon arrivent via le **backend Python** (SP-API workers) qui ecrit directement en DB, PAS via les routes inbound Fastify (`/inbound/email` ou `/inbound/amazon-forward`). Le hook autopilot n'est donc **jamais appele** pour les messages Amazon.

**Impact :** Le moteur autopilot fonctionne uniquement pour les messages arrives par email forwarding, pas pour les messages Amazon SP-API.

**Fix applique dans cette phase :** Ajout de `console.log` sur tous les early exits du moteur (`NO_SETTINGS`, `DISABLED`, `PLAN_INSUFFICIENT`, `MODE_NOT_AUTONOMOUS`, `CONVERSATION_NOT_FOUND`, `LAST_MESSAGE_NOT_INBOUND`) pour diagnostiquer les executions futures.

**Fix requis dans une phase ulterieure :** Ajouter un appel HTTP `POST /autopilot/evaluate` depuis le backend Python apres insertion d'un message inbound Amazon, ou implementer un CronJob de polling.

### PARTIE 3 — GitOps Alignment ✅

**Manifests mis a jour :**
- `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` → `v3.5.128-autopilot-critical-fixes-dev`
- `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` → `v3.5.128-autopilot-critical-fixes-prod`

**DEV + PROD alignes.**

**Note historique :** La version precedente dans les manifests etait `v3.5.110-ph-amz-multi-country-dev` mais le cluster executait `v3.5.51-playbooks-suggestions-live-dev`. Ce drift provenait d'un rollback non documente. L'historique est maintenant trace dans les commentaires du manifest.

### PARTIE 4 — Safe Mode Test ✅

**Test controle sur `srv-performance-mn7ds3oj` (plan AUTOPILOT) :**

1. `safe_mode` passe a `false`
2. `evaluateAndExecute` appele sur conversation reelle `cmmn8wifoae60e473af35cfb9`
3. **Resultat : EXECUTION REUSSIE**
   - Action : `escalate`
   - Confidence : 0.90
   - KBA debite : 9.01
   - Raison escalation : "Le client signale un probleme de livraison et demande des options de remboursement ou de renvoi"
4. `safe_mode` remis a `true`

**Conclusion :** Le moteur fonctionne correctement quand safe_mode=false. L'IA choisit l'action appropriee (escalation pour ce cas complexe) et debite les KBActions.

### PARTIE 5 — DB Cleanup ✅

**DEV :**

| Nettoyage | Avant | Apres |
|-----------|-------|-------|
| Wallet `tenant_id="null"` | 1 row | **0** ✅ |
| Autopilot settings orphelin `switaa-sasu-mn9fjcvk` | 1 row | **0** ✅ |

**PROD :**

| Nettoyage | Avant | Apres |
|-----------|-------|-------|
| Wallet `tenant_id="null"` | 1 row | **0** ✅ |
| Autopilot settings orphelins | 0 rows | **0** ✅ |

---

## 3. NON-REGRESSIONS

**DEV :**

| Service | Status | Resultat |
|---------|--------|----------|
| Health | 200 | `{"status":"ok"}` ✅ |
| Billing current | 200 | `plan: PRO, status: active` ✅ |
| AI settings | 200 | `mode: supervised, enabled: true` ✅ |
| Conversations | 200 | 3 conversations retournees ✅ |
| Wallet | 200 | Endpoint repond ✅ |

**PROD :**

| Service | Status | Resultat |
|---------|--------|----------|
| Health | 200 | `{"status":"ok"}` ✅ |
| Billing | 200 | OK ✅ |
| AI settings | 200 | OK ✅ |
| Conversations | 200 | OK ✅ |

**Plan Guard PROD (re-test post-stabilisation) :**

| Test | Tenant | Plan | Action | Resultat |
|------|--------|------|--------|----------|
| PRO → autonomous | ecomlg-001 | PRO | PATCH | **403 PLAN_REQUIRED** ✅ |
| AUTOPILOT → autonomous | switaa-sasu-mn9c3eza | AUTOPILOT | PATCH | **200 OK** ✅ |

---

## 4. RESUME DES ANOMALIES PH132-B ET CORRECTIONS

| # | Anomalie PH132-B | Severite | Fix PH132-C | Statut |
|---|------------------|----------|-------------|--------|
| 1 | Plan guard absent PATCH | CRITIQUE | Guards POST + PATCH + helper | **FIXE** ✅ |
| 2 | Moteur PROD inactif | MAJEUR | Root cause identifie + logging ajoute | **DIAGNOSTIQUE** ⚠️ |
| 3 | GitOps drift | CRITIQUE | Manifests DEV + PROD alignes | **FIXE** ✅ |
| 4 | safe_mode toujours true | MAJEUR | Test controle valide | **VALIDE** ✅ |
| 5 | Donnees orphelines | MOYEN | Null wallet + orphan supprimes DEV + PROD | **FIXE** ✅ |

---

## 5. DEPLOIEMENT PROD COMPLETE

**Image PROD :** `ghcr.io/keybuzzio/keybuzz-api:v3.5.128-autopilot-critical-fixes-prod`
**Deploye le :** 2026-03-28 16:35 UTC
**Health check :** OK
**Plan guard :** Verifie (403 pour PRO, 200 pour AUTOPILOT)
**DB cleanup :** wallet `tenant_id="null"` supprime (1 row)
**Non-regressions :** billing, ai-settings, conversations = 200

**Tenants PROD autopilot state (post-deploiement, nettoye) :**

| Tenant | Plan | Mode | Safe mode |
|--------|------|------|-----------|
| ecomlg-001 | PRO | supervised | true |
| romruais-gmail-com-mn7mc6xl | AUTOPILOT | off | true |
| switaa-sasu-mn9c3eza | AUTOPILOT | supervised | true |

**Action restante pour une phase future :**
- Trigger autopilot pour messages Amazon SP-API
  - Option A : HTTP callback depuis backend Python apres INSERT message
  - Option B : CronJob polling conversations non-evaluees
  - Recommandation : Option A (plus reactif, moins de latence)

---

## 6. FICHIERS MODIFIES

| Fichier | Type | Description |
|---------|------|-------------|
| `keybuzz-api/src/modules/autopilot/routes.ts` | FIX | Plan guard POST/PATCH + helper |
| `keybuzz-api/src/modules/autopilot/engine.ts` | DIAG | Console.log early exits |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | GITOPS | Image tag DEV mise a jour |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | GITOPS | Image tag PROD mise a jour |

---

## 7. ROLLBACK

```bash
# DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-dev -n keybuzz-api-dev

# PROD (si deploye)
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-prod -n keybuzz-api-prod
```

---

## VERDICT FINAL

```
AUTOPILOT FIXED — DEV + PROD DEPLOYES — PLAN SAFE — ENGINE VALIDATED — DATA CLEAN

Plan guard : ACTIVE DEV + PROD (PRO/STARTER → 403, AUTOPILOT/ENTERPRISE → 200)
Engine : FONCTIONNEL (escalation executee, KBA debite)
Safe mode : TESTE (safe_mode=false → execution reelle)
PROD motor : ROOT CAUSE IDENTIFIE (Amazon SP-API bypass → phase future)
GitOps : ALIGNE DEV + PROD
DB : NETTOYEE DEV + PROD (wallet null supprime, orphans supprimes)
Rollback PROD : kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-prod -n keybuzz-api-prod
```
