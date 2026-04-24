# PH-AUTOPILOT-PROD-DIAGNOSTIC-01 — Rapport de Diagnostic

> **Date** : 2026-03-01
> **Type** : Diagnostic critique P0
> **Environnements** : DEV + PROD (lecture seule)
> **Aucune modification appliquee**

---

## 1. CAUSE RACINE

**Le trigger automatique de l'autopilot est ABSENT du pipeline inbound dans l'image deployee.**

Le commit `8849e45d` (PH131-C) ajoute un appel `evaluateAndExecute()` dans `src/modules/inbound/routes.ts` apres chaque message entrant. Ce commit existe sur la branche `main` mais n'a **JAMAIS ete porte** vers la branche deployee `ph147.4/source-of-truth`.

L'image deployee (`v3.5.88-test-control-safe-`*) est construite depuis `ph147.4/source-of-truth` qui ne contient PAS le trigger inbound.

---

## 2. PREUVE TECHNIQUE

### 2.1 Code DEPLOYE (ph147.4/source-of-truth) — PAS DE TRIGGER

```
# Dans src/modules/inbound/routes.ts (image v3.5.88)
$ grep -n 'evaluateAndExecute|autopilot' src/modules/inbound/routes.ts
(aucun resultat)
```

Le module inbound appelle `evaluatePlaybooksForConversation()` (ligne 279 et 560) mais n'appelle **JAMAIS** `evaluateAndExecute()`.

### 2.2 Code sur main — TRIGGER PRESENT

```
$ git show main:src/modules/inbound/routes.ts | grep -n 'evaluateAndExecute|autopilot'
1:import { evaluateAndExecute } from '../autopilot/engine';
356:          evaluateAndExecute(conversationId, body.tenantId, 'inbound')
664:          evaluateAndExecute(conversationId, inboundPayload.tenantId, 'inbound')
```

Le trigger (fire-and-forget) est present apres chaque handler inbound (email + Amazon forward).

### 2.3 Commits manquants

3 commits de `main` apportent le trigger et ne sont PAS sur `ph147.4/source-of-truth` :


| Commit     | Description                                                                          |
| ---------- | ------------------------------------------------------------------------------------ |
| `8849e45d` | PH131-C: autopilot engine — safe controlled execution with **inbound trigger**       |
| `a0623c6f` | PH131-C: fix compilation — chatCompletion signature, routes scope, **inbound hooks** |
| `64391bb1` | PH132-D: Add autopilot trigger for **Octopia** import conversations                  |


### 2.4 Divergence des branches

```
Point de divergence : 06f833b1
main HEAD            : 5eccf7ed (14 commits apres divergence)
ph147.4 HEAD         : 0c44b718 (30 commits apres divergence)
```

La branche `ph147.4/source-of-truth` a reconstruit l'autopilot engine via `43bc922f PH143-E rebuild autopilot engine+routes`, mais le **trigger inbound n'a pas ete inclus** dans cette reconstruction.

---

## 3. CHAINE COMPLETE AUTOPILOT (code path)

```
incoming message
  → POST /inbound/email   OU   POST /inbound/amazon-forward
    → INSERT message + UPDATE conversation
    → evaluatePlaybooksForConversation()    ← OK (appele)
    → evaluateAndExecute()                  ← MANQUANT ⚠️
      → loadSettings(tenantId)
      → resolveIAMode(tenantId)             (plan + mode check)
      → canUseAutopilot(iaMode)             (supervised ou autonomous)
      → checkActionsAvailable(tenantId)     (wallet KBActions)
      → loadFullConversationContext()
      → evaluateGuardrails()
      → getAISuggestion()                   (LLM call)
      → validateDraft()
      → executeReply() / escalateConversation()
      → logAction() + debitKBActions()
```

Seul le trigger initial est absent. Le reste de la chaine (engine, guardrails, LLM, execution) fonctionne.

---

## 4. DIFF DEV vs PROD

### 4.1 Images


| Service         | DEV                             | PROD                             | Identique           |
| --------------- | ------------------------------- | -------------------------------- | ------------------- |
| API             | `v3.5.88-test-control-safe-dev` | `v3.5.88-test-control-safe-prod` | OUI (meme codebase) |
| Outbound Worker | `v3.5.165-escalation-flow-dev`  | `v3.5.165-escalation-flow-prod`  | OUI                 |


### 4.2 Code


| Fichier                           | DEV                            | PROD                           | Identique |
| --------------------------------- | ------------------------------ | ------------------------------ | --------- |
| `src/modules/inbound/routes.ts`   | Pas de trigger autopilot       | Pas de trigger autopilot       | OUI       |
| `src/modules/autopilot/engine.ts` | `evaluateAndExecute()` present | `evaluateAndExecute()` present | OUI       |
| `src/modules/autopilot/routes.ts` | `POST /evaluate` (manuel)      | `POST /evaluate` (manuel)      | OUI       |


**Le code est strictement identique entre DEV et PROD.** L'autopilot ne fonctionne automatiquement dans **AUCUN** des deux environnements.

### 4.3 Seul point d'appel de `evaluateAndExecute()`

```
$ grep -rn 'evaluateAndExecute' src/ --include='*.ts' | grep -v tests/
src/modules/autopilot/engine.ts:170:export async function evaluateAndExecute(
src/modules/autopilot/routes.ts:1:import { evaluateAndExecute } from './engine';
src/modules/autopilot/routes.ts:179:      const result = await evaluateAndExecute(conversationId, tenantId, 'manual');
```

**UNE SEULE invocation** : route manuelle `POST /autopilot/evaluate`.

---

## 5. CONFIGURATION

### 5.1 Variables d'environnement


| Variable            | DEV                      | PROD                     | Impact                                       |
| ------------------- | ------------------------ | ------------------------ | -------------------------------------------- |
| `NODE_ENV`          | `development`            | `production`             | Pas d'impact sur autopilot                   |
| `PH113_SAFE_MODE`   | `true`                   | Non definie              | Pas reference dans autopilot engine          |
| `LITELLM_BASE_URL`  | `https://llm.keybuzz.io` | `https://llm.keybuzz.io` | Identique                                    |
| `AUTOPILOT_ENABLED` | Non definie              | Non definie              | N'existe pas dans le code                    |
| `SAFE_MODE`         | Non definie              | Non definie              | Geree en DB (`autopilot_settings.safe_mode`) |


Aucune env var ne bloque l'autopilot.

### 5.2 autopilot_settings (DB)


| Tenant                          | Env  | mode       | is_enabled | plan      | safe_mode | allow_auto_reply |
| ------------------------------- | ---- | ---------- | ---------- | --------- | --------- | ---------------- |
| `switaa-sasu-mnc1x4eq`          | DEV  | autonomous | true       | AUTOPILOT | true      | true             |
| `compta-ecomlg-gmail--mnkjttw7` | DEV  | autonomous | true       | AUTOPILOT | true      | true             |
| `ecomlg-001`                    | DEV  | supervised | true       | pro       | true      | true             |
| `switaa-sasu-mnc1ouqu`          | PROD | autonomous | true       | AUTOPILOT | true      | true             |
| `compta-ecomlg-gmail--mnvu4649` | PROD | autonomous | true       | AUTOPILOT | true      | **false**        |
| `ecomlg-001`                    | PROD | supervised | true       | PRO       | true      | **false**        |


Les tenants avec plan=AUTOPILOT et mode=autonomous sont correctement configures.

### 5.3 resolveIAMode (ai-mode-engine.ts)


| Plan                                      | caps.maxMode | Mode resolu | canUseAutopilot() |
| ----------------------------------------- | ------------ | ----------- | ----------------- |
| STARTER                                   | disabled     | disabled    | false             |
| PRO                                       | suggestion   | suggestion  | **false**         |
| AUTOPILOT (enabled+supervised)            | autonomous   | supervised  | **true**          |
| AUTOPILOT (enabled+autonomous+safe_mode)  | autonomous   | supervised  | **true**          |
| AUTOPILOT (enabled+autonomous+!safe_mode) | autonomous   | autonomous  | **true**          |


Les tenants AUTOPILOT passeraient `canUseAutopilot()` — le engine fonctionnerait **s'il etait declenche**.

---

## 6. LOGS AUTOPILOT

### DEV (10 dernieres entrees)


| Date       | Tenant               | Action   | Status    | Blocked Reason        |
| ---------- | -------------------- | -------- | --------- | --------------------- |
| 2026-04-20 | switaa-sasu-mnc1x4eq | reply    | skipped   | DRAFT_GENERATED       |
| 2026-04-20 | switaa-sasu-mnc1x4eq | escalate | skipped   | ESCALATION_DRAFT:0.85 |
| 2026-04-19 | switaa-sasu-mnc1x4eq | reply    | skipped   | GUARDRAIL_BLOCKED     |
| 2026-04-15 | switaa-sasu-mnc1x4eq | escalate | skipped   | ESCALATION_DRAFT:0.75 |
| 2026-04-14 | switaa-sasu-mnc1x4eq | escalate | skipped   | DRAFT_APPLIED         |
| 2026-04-14 | switaa-sasu-mnc1x4eq | escalate | skipped   | DRAFT_APPLIED         |
| 2026-04-11 | switaa-sasu-mnc1x4eq | reply    | completed | (null)                |
| 2026-04-11 | switaa-sasu-mnc1x4eq | reply    | skipped   | GUARDRAIL_BLOCKED     |
| 2026-04-11 | switaa-sasu-mnc1x4eq | escalate | skipped   | DRAFT_APPLIED         |
| 2026-04-11 | switaa-sasu-mnc1x4eq | reply    | skipped   | GUARDRAIL_BLOCKED     |


**Conclusion** : Les logs DEV prouvent que le engine fonctionne correctement. Ces entrees ont ete creees via des appels **manuels** (`POST /autopilot/evaluate`).

### PROD (3 entrees totales)


| Date       | Tenant               | Action   | Status  | Blocked Reason        |
| ---------- | -------------------- | -------- | ------- | --------------------- |
| 2026-04-11 | switaa-sasu-mnc1ouqu | reply    | skipped | DRAFT_APPLIED         |
| 2026-04-10 | ecomlg-001           | reply    | skipped | DRAFT_GENERATED       |
| 2026-04-10 | ecomlg-001           | escalate | skipped | ESCALATION_DRAFT:0.75 |


**Conclusion** : Seulement 3 logs en PROD, tous generes par des tests manuels (aucun trigger automatique possible).

---

## 7. GUARDRAILS


| Guardrail                 | Etat                               | Bloque ?                              |
| ------------------------- | ---------------------------------- | ------------------------------------- |
| Plan AUTOPILOT requis     | Plans corrects pour tenants cibles | Non                                   |
| safe_mode                 | true partout                       | Non (genere draft au lieu d'executer) |
| KBActions wallet          | Non verifie en detail              | Non bloquant                          |
| Rate limit (20/h)         | Max 10 logs en DEV                 | Non atteint                           |
| kill_switch (ai_settings) | false                              | Non                                   |
| auto_disabled             | false                              | Non                                   |


Aucun guardrail ne bloque l'autopilot. Le probleme est en AMONT : le engine n'est jamais appele.

---

## 8. TRIGGER

### Question : `inbound` appelle-t-il `evaluateAndExecute` ?

**NON.** L'appel est ABSENT du code deploye.


| Handler inbound                | evaluatePlaybooks | evaluateAndExecute |
| ------------------------------ | ----------------- | ------------------ |
| `POST /inbound/email`          | OUI (ligne 279)   | **NON**            |
| `POST /inbound/amazon-forward` | OUI (ligne 560)   | **NON**            |


### Code path execute

```
incoming message → INSERT message → UPDATE conversation
  → evaluatePlaybooksForConversation()  ← EXECUTE
  → (rien d'autre)                       ← AUTOPILOT JAMAIS APPELE
```

### Code path attendu (present sur main)

```
incoming message → INSERT message → UPDATE conversation
  → evaluatePlaybooksForConversation()  ← EXECUTE
  → evaluateAndExecute(convId, tenantId, 'inbound')  ← DEVRAIT ETRE LA
```

---

## 9. VERDICT

### Cause racine unique

```
TRIGGER INBOUND MANQUANT
```

Le trigger `evaluateAndExecute()` (PH131-C, commit `8849e45d`) a ete ajoute sur la branche `main` mais n'a **JAMAIS ete fusionne** dans la branche deployee `ph147.4/source-of-truth`.

Lors de la reconstruction PH143-E de l'autopilot engine+routes (`43bc922f`), seuls le engine et les routes ont ete reconstruits — le hook dans `src/modules/inbound/routes.ts` a ete oublie.

### Impact


| Environnement | Autopilot automatique      | Autopilot manuel        |
| ------------- | -------------------------- | ----------------------- |
| DEV           | **CASSE** (pas de trigger) | OK (via POST /evaluate) |
| PROD          | **CASSE** (pas de trigger) | OK (via POST /evaluate) |


### Tableau synoptique


| Zone                   | Etat                                                   | Diff DEV/PROD                                   |
| ---------------------- | ------------------------------------------------------ | ----------------------------------------------- |
| Image API              | v3.5.88                                                | Identique                                       |
| Image Worker           | v3.5.165                                               | Identique                                       |
| autopilot/engine.ts    | OK — fonctionnel                                       | Identique                                       |
| autopilot/routes.ts    | OK — /evaluate existe                                  | Identique                                       |
| inbound/routes.ts      | **TRIGGER MANQUANT**                                   | Identique (manquant partout)                    |
| autopilot_settings     | Configures correctement                                | Tenants differents mais configs OK              |
| ai-mode-engine.ts      | OK — canUseAutopilot correct                           | Identique                                       |
| autopilotGuardrails.ts | OK                                                     | Identique                                       |
| CronJobs               | Aucun CronJob autopilot                                | Aucun                                           |
| Client BFF             | /api/autopilot/evaluate existe mais jamais appele auto | Identique                                       |
| Client UI              | Fetch drafts uniquement, aucun trigger auto            | Identique                                       |
| Env vars               | Aucune env var autopilot                               | PH113_SAFE_MODE en DEV seulement (pas d'impact) |


---

## 10. CORRECTION REQUISE

**STOP — Ce rapport est un DIAGNOSTIC UNIQUEMENT. Aucune correction n'a ete appliquee.**

La correction consiste a ajouter dans `src/modules/inbound/routes.ts` :

```typescript
// A ajouter en haut du fichier
import { evaluateAndExecute } from '../autopilot/engine';

// A ajouter apres chaque evaluatePlaybooksForConversation() (lignes ~279 et ~560)
if (body.tenantId && conversationId) {
  evaluateAndExecute(conversationId, body.tenantId, 'inbound')
    .catch(err => console.error('[Autopilot] Engine error:', err.message));
}
```

### Fichiers impactes

1. `src/modules/inbound/routes.ts` — ajouter le trigger (2 points d'injection)

### Pas de changement requis sur

- `src/modules/autopilot/engine.ts` — fonctionne deja
- `src/modules/autopilot/routes.ts` — fonctionne deja
- `autopilot_settings` (DB) — deja configure
- Variables d'environnement — aucune nouvelle var requise

---

## 11. CONCLUSION

```
AUTOPILOT BROKEN ROOT CAUSE IDENTIFIED

Cause : trigger inbound manquant (PH131-C non fusionne dans ph147.4)
Impact : autopilot JAMAIS declenche automatiquement (DEV ET PROD)
Engine : fonctionnel (prouve par logs manuels)
Config : correcte (plans AUTOPILOT, settings enabled)
Guardrails : non bloquants
Correction : 1 import + 2 appels fire-and-forget dans inbound/routes.ts
```

**STOP**