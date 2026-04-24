# PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01 — TERMINE

> **Date** : 2026-04-20
> **Type** : Recovery cible P0
> **Environnement** : DEV uniquement (PROD non touchee)
> **Verdict** : **GO**

---

## Cause racine (rappel)

Le trigger `evaluateAndExecute()` (PH131-C) n'a jamais ete porte de `main` vers `ph147.4/source-of-truth`.
L'autopilot engine fonctionne, mais n'etait jamais appele automatiquement apres un message entrant.

---

## Preflight


| Element            | Valeur                                       |
| ------------------ | -------------------------------------------- |
| Branche            | `ph147.4/source-of-truth`                    |
| HEAD avant patch   | `0c44b718`                                   |
| Repo clean         | OUI (1 `.bak` non-tracke)                    |
| Image DEV avant    | `v3.5.88-test-control-safe-dev`              |
| Image PROD         | `v3.5.88-test-control-safe-prod` (inchangee) |
| Manifest DEV avant | `v3.5.88-test-control-safe-dev`              |
| Manifest PROD      | `v3.5.88-test-control-safe-prod` (inchange)  |


### Preuve du manque initial

```
$ grep -c 'evaluateAndExecute' src/modules/inbound/routes.ts
0
```

---

## Patch


| Element            | Valeur                                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Fichier modifie    | `src/modules/inbound/routes.ts`                                                                                    |
| Import ajoute      | `import { evaluateAndExecute } from '../autopilot/engine';`                                                        |
| Injection 1        | Apres `evaluatePlaybooksForConversation()` dans handler `/inbound/email` (var: `body.tenantId`)                    |
| Injection 2        | Apres `evaluatePlaybooksForConversation()` dans handler `/inbound/amazon-forward` (var: `inboundPayload.tenantId`) |
| Total insertions   | 13 lignes                                                                                                          |
| Total suppressions | 0 lignes                                                                                                           |
| Autres changements | AUCUN                                                                                                              |


### Diff

```diff
+import { evaluateAndExecute } from '../autopilot/engine';

 // Handler /inbound/email (ligne ~285)
+        // PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01
+        if (body.tenantId && conversationId) {
+          evaluateAndExecute(conversationId, body.tenantId, 'inbound')
+            .catch(err => console.error('[Autopilot] Engine error:', err.message));
+        }

 // Handler /inbound/amazon-forward (ligne ~572)
+        // PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01
+        if (inboundPayload.tenantId && conversationId) {
+          evaluateAndExecute(conversationId, inboundPayload.tenantId, 'inbound')
+            .catch(err => console.error('[Autopilot] Engine error:', err.message));
+        }
```

### Commit source


| Element | Valeur                                                                                       |
| ------- | -------------------------------------------------------------------------------------------- |
| Commit  | `4f60aad5`                                                                                   |
| Message | `PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01: add evaluateAndExecute() fire-and-forget trigger` |
| Branche | `ph147.4/source-of-truth`                                                                    |


---

## Image DEV


| Element    | Valeur                                                                    |
| ---------- | ------------------------------------------------------------------------- |
| Tag        | `v3.5.89-autopilot-inbound-trigger-dev`                                   |
| Digest     | `sha256:c5d9123eb7304e431839834fa1d31fee3140aab36c2d938ee82c8a89f38fbed2` |
| Build      | `docker build --no-cache` (build-from-git)                                |
| TypeScript | Compilation OK (tsc)                                                      |
| Registry   | `ghcr.io/keybuzzio/keybuzz-api`                                           |


---

## Validation DEV

### CAS A — Trigger automatique inbound (tenant AUTOPILOT)


| Etape                          | Resultat                                                                 |
| ------------------------------ | ------------------------------------------------------------------------ |
| Tenant                         | `switaa-sasu-mnc1x4eq` (plan=AUTOPILOT, mode=autonomous, safe_mode=true) |
| Message inbound envoye         | `POST /inbound/email` → HTTP 200                                         |
| `evaluateAndExecute` declenche | **OUI** (automatiquement, fire-and-forget)                               |
| ai_action_log avant            | 60 entrees                                                               |
| ai_action_log apres            | 61 entrees (+1)                                                          |
| Derniere entree                | `autopilot_escalate` / `ESCALATION_DRAFT:0.75`                           |
| Guardrails                     | `buyer=LOW(0), product=MEDIUM(40), combined=MEDIUM`                      |
| Draft LLM genere               | OUI (342 caracteres)                                                     |
| Fausse promesse detectee       | OUI ("je vais verifier") → reclassement ESCALATION_DRAFT                 |
| **Resultat**                   | **PASS**                                                                 |


### CAS B — Plan PRO (pas d'execution autopilot complete)


| Etape                          | Resultat                                                        |
| ------------------------------ | --------------------------------------------------------------- |
| Tenant                         | `ecomlg-001` (plan=pro, mode=supervised)                        |
| Message inbound envoye         | `POST /inbound/email` → HTTP 200                                |
| `evaluateAndExecute` declenche | OUI (appele, mais sort immediatement)                           |
| Raison                         | `MODE_NOT_AUTOPILOT:suggestion` (plan PRO → maxMode=suggestion) |
| ai_action_log                  | 7 → 7 (pas de nouvelle entree — sortie avant log)               |
| LLM appele                     | NON (sortie avant l'appel LLM)                                  |
| **Resultat**                   | **PASS**                                                        |


### CAS C — Logs pod


| Recherche               | Resultat                                                                         |
| ----------------------- | -------------------------------------------------------------------------------- |
| `[Autopilot]` dans logs | 3 lignes trouvees                                                                |
| Risk scoring            | `buyer=LOW(0) product=MEDIUM(40) combined=MEDIUM`                                |
| Draft generation        | `ESCALATION_DRAFT (safe_mode, false_promises=je vais verifier, draft=342 chars)` |
| Mode gating PRO         | `MODE_NOT_AUTOPILOT:suggestion`                                                  |
| **Resultat**            | **PASS**                                                                         |


---

## Non-regression DEV


| Endpoint                  | HTTP | Resultat          |
| ------------------------- | ---- | ----------------- |
| `/health`                 | 200  | `{"status":"ok"}` |
| `/messages/conversations` | 200  | OK                |
| `/tenant-context/me`      | 200  | OK                |
| `/dashboard/summary`      | 200  | OK                |
| `/autopilot/settings`     | 200  | OK                |
| `/billing/current`        | 200  | OK                |
| `/metrics/overview`       | 200  | OK                |


### Confirmations

- Aucun impact tracking
- Aucun impact billing
- Aucun impact Stripe
- Aucun impact metrics
- Aucun impact client SaaS
- Aucun impact admin

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.88-test-control-safe-dev \
  -n keybuzz-api-dev
```

---

## Etat PROD


| Element          | Valeur                                           |
| ---------------- | ------------------------------------------------ |
| Image PROD       | `v3.5.88-test-control-safe-prod` (**INCHANGEE**) |
| Manifest PROD    | `v3.5.88-test-control-safe-prod` (**INCHANGE**)  |
| Deploiement PROD | AUCUN                                            |


---

## Manifest GitOps


| Fichier                                              | Commit                                                                     |
| ---------------------------------------------------- | -------------------------------------------------------------------------- |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`  | `9053f8b` — image mise a jour vers `v3.5.89-autopilot-inbound-trigger-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | **NON MODIFIE**                                                            |


---

## Conclusion

```
AUTOPILOT INBOUND TRIGGER RESTORED IN DEV — MINIMAL PATCH — PROD UNTOUCHED

Patch : 1 import + 2 appels fire-and-forget (13 lignes ajoutees, 0 supprimee)
Build : v3.5.89-autopilot-inbound-trigger-dev (build-from-git, commit 4f60aad5)
Validation : CAS A (PASS) + CAS B (PASS) + CAS C (PASS)
Non-regression : 7/7 endpoints OK
PROD : non touchee (v3.5.88-test-control-safe-prod)

Aucune autre action effectuee.
En attente de validation explicite pour promotion PROD.
```

**STOP**