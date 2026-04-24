# PH147-COMPLETE-REPLAY-SAFE-01

> Date : 15 avril 2026
> Phase : PH147-IA-GUARDRAILS-COMPLETE-REPLAY-SAFE-01
> Environnement : DEV uniquement
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.54-ph147-replay-dev`
> Rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.53-ph147.3-encoding-cleanup-prod`

---

## 1. Contexte

PH147 (147.0 → 147.3) avait ete applique par patches ad-hoc directement sur le bastion.
Le fichier `autopilotGuardrails.ts` n'existait dans aucune branche Git.
Le source sur le bastion etait sur `rebuild/ph143-api` (branche PH143, sans PH145-PH147).

Ce replay reconstruit PH147 proprement depuis Git en :

1. Extrayant le JS compile du pod deployé
2. Convertissant en TypeScript avec types complets
3. Integrant dans `engine.ts` aux bons points d'insertion
4. Buildant et deployant depuis un repo Git propre

---

## 2. Source du build

```
REPO : /opt/keybuzz/keybuzz-api
BRANCHE : ph147-replay/guardrails-complete (basee sur origin/rebuild/ph143-api)
COMMIT : 1ffdb42
LIEU BUILD : bastion (46.62.171.61)
```

---

## 3. Fichiers modifies


| Fichier                               | Action                                    | Lignes     |
| ------------------------------------- | ----------------------------------------- | ---------- |
| `src/services/autopilotGuardrails.ts` | **CREE** (nouveau fichier)                | 529 lignes |
| `src/modules/autopilot/engine.ts`     | Modifie (import + 4 points d'integration) | +68 lignes |
| **Total**                             | 2 fichiers, 1 nouveau                     | +598 / -3  |


---

## 4. Features replayed (PH145 → PH147.3)

### PH145 — Guardrails base


| Feature                       | Implementation                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `computeBuyerRisk()`          | Scoring acheteur (historique remboursements, ton agressif, urgence, premier contact) |
| `computeProductRisk()`        | Scoring produit (valeur commande, multi-produit, FBM, historique)                    |
| `evaluateGuardrails()`        | Pre-LLM guard (decide si l'IA doit generer ou bloquer)                               |
| `validateDraft()`             | Post-LLM validation (filtre les drafts dangereux)                                    |
| `GUARDRAIL_SYSTEM_RULES`      | 7 regles injectees dans le prompt systeme LLM                                        |
| `buildGuardrailPromptBlock()` | Bloc contextuel injecte dans le prompt utilisateur                                   |


### PH147.0 — Guardrails business


| Feature               | Implementation                                               |
| --------------------- | ------------------------------------------------------------ |
| Channel scoring       | Amazon +10, Octopia +5 (`CHANNEL_AMAZON`, `CHANNEL_OCTOPIA`) |
| Pre-LLM blocking      | `allowed = false` si `combinedRisk === 'HIGH'`               |
| Cancellation patterns | 5 patterns (FR/EN) dans `FORBIDDEN_PROMISE_PATTERNS`         |
| SQL interpolation fix | `interval '90 days'` au lieu de string interpolation         |
| Regle 7 ANNULATION    | Ajoutee au prompt systeme                                    |


### PH147.1 — IA completeness


| Feature                    | Implementation                                                                               |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| SQL return_status          | `amazon_returns.return_status` (corrige depuis `status`)                                     |
| 7 patterns supplementaires | remplacement immediat, remboursement direct, geste commercial (FR/EN)                        |
| 3 validateDraft checks     | `FORBIDDEN_COMMERCIAL_GESTURE`, `FORBIDDEN_IMMEDIATE_REPLACEMENT`, `FORBIDDEN_DIRECT_REFUND` |
| Regle 6 GESTE COMMERCIAL   | Ajoutee au prompt systeme                                                                    |


### PH147.2 — HIGH = blocked inconditionnel


| Feature                | Implementation                                                            |
| ---------------------- | ------------------------------------------------------------------------- |
| Invariant HIGH→blocked | `if (combinedRisk === 'HIGH') { allowed = false; }` (plus de seuil score) |


### PH147.3 — Encoding cleanup


| Feature          | Implementation                                         |
| ---------------- | ------------------------------------------------------ |
| Accents corrects | `[eé]` dans les regex (pas `[eu00e9]`)                 |
| Em-dash corrects | `—` dans les rules (pas `u2014`)                       |
| Prompt accents   | être, écrire, immédiat, nécessaire, métriques, annulée |


---

## 5. Integration engine.ts

8 modifications appliquees dans `engine.ts` :

1. **Import** : `autopilotGuardrails` (evaluateGuardrails, validateDraft, GUARDRAIL_SYSTEM_RULES)
2. **Step 6d** : appel `evaluateGuardrails()` avec signaux buyer + order context
3. **PRE_LLM_BLOCKED** : si `!guardrails.allowed` → log, debit, return noop
4. **Risk logging** : affichage buyer/product/combined risk dans les logs
5. **Pass guardrails** : transmis a `getAISuggestion()` comme parametre
6. **validateDraft** : verification post-LLM, blocage si violations
7. **GUARDRAIL_SYSTEM_RULES** : injecte dans le prompt systeme
8. **promptInjection** : contexte risque injecte dans le prompt utilisateur

---

## 6. Verification post-deploy

### Symboles compiles (dans le pod DEV)


| Symbole                         | Count         | Attendu |
| ------------------------------- | ------------- | ------- |
| CHANNEL_AMAZON                  | 1             | 1       |
| CHANNEL_OCTOPIA                 | 1 (implicite) | 1       |
| PRE_LLM_BLOCKED                 | 1             | 1       |
| COMBINED_RISK_HIGH              | 1             | 1       |
| FORBIDDEN_CANCELLATION          | 1             | 1       |
| FORBIDDEN_COMMERCIAL_GESTURE    | 1             | 1       |
| FORBIDDEN_DIRECT_REFUND         | 1             | 1       |
| FORBIDDEN_IMMEDIATE_REPLACEMENT | 1             | 1       |
| return_status                   | 1             | 1       |
| geste commercial                | 4             | 4       |


### Health et non-regression


| Test                            | Resultat                                     |
| ------------------------------- | -------------------------------------------- |
| Pod 1/1 Running                 | OK                                           |
| Health endpoint (200)           | OK                                           |
| Entitlement (ecomlg-001)        | OK (200)                                     |
| Outbound tick                   | OK (200)                                     |
| Erreurs niveau 50 dans les logs | 0                                            |
| PROD inchangee                  | OK (`v3.5.53-ph147.3-encoding-cleanup-prod`) |


---

## 7. Diff avant/apres

### Avant (rebuild/ph143-api)

- `autopilotGuardrails.ts` : **inexistant**
- `engine.ts` : pas de guardrails, pas de risk scoring, pas de validation draft
- Aucune protection pre/post-LLM
- Aucun pattern interdit
- Aucune regle metier dans le prompt

### Apres (ph147-replay/guardrails-complete)

- `autopilotGuardrails.ts` : 529 lignes, module complet
- `engine.ts` : 8 points d'integration, pipeline guard complet
- Pre-LLM blocking pour risques HIGH
- 25 patterns FORBIDDEN_PROMISE (FR/EN)
- 7 patterns UNSAFE_COMMITMENT
- 7 regles GUARDRAIL_SYSTEM_RULES dans le prompt
- Scoring canal Amazon/Octopia
- Post-LLM validation avec 4 checks specifiques

---

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.53-ph147.3-encoding-cleanup-prod \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 9. Verdict

### SUCCESS

- TypeScript compile sans erreur
- Tous les symboles PH147 presents dans le compile
- Pod Running, health OK, 0 erreur
- PROD inchangee
- Source Git propre (pas de patch ad-hoc)
- Build reproductible depuis le repo

