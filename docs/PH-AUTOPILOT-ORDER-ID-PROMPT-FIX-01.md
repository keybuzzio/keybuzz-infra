# PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01 — TERMINÉ

**Verdict : GO**

**Date** : 2026-04-20
**Environnement** : DEV uniquement (PROD non touchée)
**Type** : Fix minimal prompt Autopilot — ne pas redemander un numéro déjà présent

---

## Préflight

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD avant patch | `4f60aad5` |
| Repo clean | OUI |
| Image DEV avant | `v3.5.89-autopilot-inbound-trigger-dev` |
| Image PROD | `v3.5.89-autopilot-inbound-trigger-prod` (non touchée) |

---

## Preuve de non-utilisation initiale de `getScenarioRules()`

```
$ grep -n 'getScenarioRules' src/modules/autopilot/engine.ts

30:  getScenarioRules,   ← import uniquement
```

**1 seule occurrence** dans `engine.ts` = l'import à la ligne 30.
**0 appel** dans le corps des fonctions.
La "RÈGLE PRIORITAIRE ABSOLUE" (ne jamais redemander une info du message) n'était jamais injectée dans le prompt Autopilot.

---

## Diff minimal appliqué

```diff
diff --git a/src/modules/autopilot/engine.ts b/src/modules/autopilot/engine.ts
index 810b23c4..b0e355f1 100644
--- a/src/modules/autopilot/engine.ts
+++ b/src/modules/autopilot/engine.ts
@@ -684,6 +684,9 @@ CAS 7 — Simple remerciement ou confirmation du client:
     // PH145: Inject business guardrail rules into system prompt
     systemPrompt += '\n\n' + GUARDRAIL_SYSTEM_RULES;
 
+    // PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01: inject shared scenario rules (anti-redundancy)
+    systemPrompt += '\n\n' + getScenarioRules();
+
     // PH133-A: Build enriched user prompt
     let userPrompt = `Canal: ${context.channel}
```

**+2 lignes utiles** (1 commentaire + 1 appel). 0 suppression. 1 fichier modifié.

---

## Commit source

| Element | Valeur |
|---|---|
| Commit | `1adbf73b` |
| Message | `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01: inject getScenarioRules() into autopilot prompt to prevent re-asking info already in message` |
| Fichier | `src/modules/autopilot/engine.ts` |
| Branche | `ph147.4/source-of-truth` |

---

## Image DEV

| Element | Valeur |
|---|---|
| Image avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-dev` |
| Image après | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-dev` |
| Digest | `sha256:79d14a1779eb66c48803136082c57d9a03a1b9c3cabfea9b520378c17a5b10b2` |
| Build type | `docker build --no-cache` (build-from-git) |
| TypeScript | Compilation OK |
| Manifest infra | Commit `9b9b03f` |

---

## Validation DEV réelle

### CAS A — Email avec numéro de commande dans le body

| Element | Valeur |
|---|---|
| Tenant | `switaa-sasu-mnc1x4eq` (plan AUTOPILOT) |
| Message | "Bonjour, je voudrais savoir ou en est ma commande numero 402-1234567-8901234..." |
| Conversation | `conv-4e6aefb6` |
| ai_action_log | 112→113 (+1) |
| action_type | `autopilot_reply` / `DRAFT_GENERATED` |

**Draft généré :**
> "Bonjour, Je vous remercie pour votre message concernant votre commande **402-1234567-8901234**. Je comprends votre préoccupation concernant le retard de livraison..."

**Vérifications :**
- Draft contient `402-1234567` : **OUI**
- Draft redemande le numéro : **NON**

**VERDICT CAS A : PASS**

### CAS B — Email sans numéro de commande

| Element | Valeur |
|---|---|
| Message | "Bonjour, je n'ai toujours pas recu mon colis. Merci de me donner un suivi." |
| Conversation | `conv-bb94ec59` |

**Draft généré :**
> "...pourriez-vous me communiquer votre numéro de commande ou votre numéro de suivi ?..."

- Draft demande correctement le numéro (car absent du message) : **OUI**

**VERDICT CAS B : PASS**

### CAS C — Plan PRO (gating)

| Element | Valeur |
|---|---|
| Tenant | `ecomlg-001` (plan PRO) |
| ai_action_log | 1315→1315 (inchangé) |
| Logs | `MODE_NOT_AUTOPILOT:suggestion` |

**VERDICT CAS C : PASS**

### Tableau de synthèse

| Test | Attendu | Résultat |
|---|---|---|
| CAS A — Email avec numéro | Draft utilise le numéro, ne le redemande pas | **PASS** |
| CAS B — Email sans numéro | Draft peut demander le numéro | **PASS** |
| CAS C — Plan PRO gating | Pas d'exécution, MODE_NOT_AUTOPILOT | **PASS** |

---

## Non-régression DEV

| Endpoint | HTTP Status |
|---|---|
| `/health` | 200 |
| `/messages/conversations` | 200 |
| `/tenant-context/me` | 200 |
| `/dashboard/summary` | 200 |
| `/autopilot/settings` | 200 |
| `/billing/current` | 200 |
| `/metrics/overview` | 200 |

### Confirmations

| Element | Impact |
|---|---|
| Tracking | Aucun |
| Billing / Stripe | Aucun |
| Metrics | Aucun |
| Client SaaS | Aucun |
| Admin | Aucun |
| `inbound/routes.ts` | Non touché |
| `amazonForward.ts` | Non touché |

---

## Rollback DEV

| Element | Valeur |
|---|---|
| Image précédente | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-dev` |
| Image actuelle | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-dev` |

Procédure : modifier `deployment.yaml` DEV → `v3.5.89-autopilot-inbound-trigger-dev` → `kubectl apply`

---

## État PROD

**PROD NON TOUCHÉE.**

- Image PROD : `v3.5.89-autopilot-inbound-trigger-prod` (inchangée)
- Manifest PROD : inchangé
- Aucun build PROD effectué

**Promotion PROD en attente de validation explicite.**

---

## Conclusion

- 1 fichier modifié : `src/modules/autopilot/engine.ts`
- 2 lignes ajoutées : injection de `getScenarioRules()` après `GUARDRAIL_SYSTEM_RULES`
- Effet : le prompt Autopilot contient maintenant la "RÈGLE PRIORITAIRE ABSOLUE" qui empêche de redemander une info déjà dans le message
- Validation : le draft utilise le numéro de commande du message au lieu de le redemander
- Aucun impact sur les autres fonctionnalités

---

## VERDICT FINAL

**AUTOPILOT PROMPT NO-LONGER-REDASKS ORDER-ID — MINIMAL FIX — PROD UNTOUCHED**
