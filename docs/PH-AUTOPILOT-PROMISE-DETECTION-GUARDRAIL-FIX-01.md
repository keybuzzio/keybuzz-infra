# PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01

> **Date** : 2026-04-21
> **Auteur** : Agent Cursor
> **Phase** : Fix minimal détection promesses humaines + guardrail consume
> **Environnement** : DEV uniquement — PROD intouchée
> **Priorité** : P0
> **Verdict** : AUTOPILOT PROMISE DETECTION GUARDRAIL FIXED IN DEV — PROD UNTOUCHED

---

## 0. PRÉFLIGHT

| Élément | Valeur | OK |
|---|---|---|
| Repo | `keybuzz-api` (origin: github.com/keybuzzio/keybuzz-api) | ✅ |
| Branche | `ph147.4/source-of-truth` | ✅ |
| HEAD avant | `7265d29a` | ✅ |
| Repo clean | 1 fichier `.bak` non-tracké | ✅ |
| Image API DEV avant | `v3.5.91-autopilot-escalation-handoff-fix-dev` | ✅ |
| Image API PROD | `v3.5.91-autopilot-escalation-handoff-fix-prod` | ✅ |
| Backend | `v1.0.46-ph-recovery-01-dev` — hors scope | ✅ |

---

## 1. FICHIERS MODIFIÉS

| Fichier | Action | Lignes |
|---|---|---|
| `src/lib/promise-detection.ts` | **CRÉÉ** — helper partagé | 66 lignes |
| `src/modules/autopilot/engine.ts` | Modifié — import shared, suppression locale | -24 +2 |
| `src/modules/autopilot/routes.ts` | Modifié — guardrail consume + fix SQL comment | +20 -1 |
| `src/modules/messages/routes.ts` | Modifié — remplacement inline par shared | -40 +3 |
| `src/modules/ai/ai-assist-routes.ts` | Modifié — délégation au shared | -18 +4 |

**Total** : 5 fichiers, +99 -82 lignes

---

## 2. DIFF RÉSUMÉ

### `src/lib/promise-detection.ts` (NOUVEAU)

Module partagé — source de vérité unique pour tous les patterns de détection de promesses.

**Exports** :
- `detectFalsePromises(text: string): string[]` — retourne la liste des labels matchés
- `detectFalsePromisesWithDetails(text: string): { detected: boolean; patterns: string[] }` — idem avec format objet

**37 patterns regex** organisés en 5 catégories :
1. Existants "je vais + infinitif" (23 patterns préservés)
2. Présent indicatif (4 nouveaux)
3. Futur simple (2 nouveaux)
4. 3ème personne / équipe (2 nouveaux)
5. Infinitifs liés à une promesse (4 nouveaux)
6. "nous allons nous assurer" (1 nouveau correctif)

### `src/modules/autopilot/engine.ts`

- Ajout `import { detectFalsePromises } from '../../lib/promise-detection'`
- Suppression de la fonction locale `detectFalsePromises` (14 patterns)
- Le code appelant reste inchangé (`falsePromises = detectFalsePromises(...)`)

### `src/modules/autopilot/routes.ts` (GUARDRAIL)

- Ajout `import { detectFalsePromises } from '../../lib/promise-detection'`
- `wasEscalationDraft` changé de `const` à `let`
- **Guardrail inséré** entre la lecture du draft original et l'UPDATE :

```
if (consumeAction === 'applied' && !wasEscalationDraft && originalDraft exists) {
  → extraire draftText du payload
  → detectFalsePromises(draftText)
  → si matches > 0 : reclassifier wasEscalationDraft = true
  → injecter escalationReason + escalationTarget dans le payload
}
```

- Fix bug SQL existant : suppression du commentaire `// PH-ESCALATION-HANDOFF-FIX-01` qui était à l'intérieur d'une chaîne SQL (causait `syntax error at or near "//"`)

### `src/modules/messages/routes.ts`

- Ajout `import { detectFalsePromises } from '../../lib/promise-detection'`
- Remplacement du bloc de 22 patterns inline + boucle for/of par :
```typescript
const detectedPromises = detectFalsePromises(content);
```

### `src/modules/ai/ai-assist-routes.ts`

- Ajout `import { detectFalsePromisesWithDetails } from '../../lib/promise-detection'`
- Remplacement de la fonction locale `detectFalsePromises` (9 patterns) par un wrapper :
```typescript
function detectFalsePromises(text: string): { detected: boolean; patterns: string[] } {
  return detectFalsePromisesWithDetails(text);
}
```

---

## 3. PHRASES DÉTECTÉES (14 nouveaux patterns)

### Présent indicatif
| Pattern | Exemple | Match |
|---|---|---|
| `je transmets/transmet` | "je transmets immédiatement" | ✅ |
| `je vérifie` + complément | "je vérifie votre dossier" | ✅ |
| `je contacte` + complément | "je contacte immédiatement" | ✅ |
| `je m'assure que/de` | "je m'assure que tout est OK" | ✅ |

### Futur simple
| Pattern | Exemple | Match |
|---|---|---|
| `je ___rai` (7 verbes) | "je transmettrai", "je vérifierai", "je contacterai" | ✅ |
| `nous ___rons` (7 verbes) | "nous organiserons", "nous procéderons" | ✅ |

### 3ème personne / équipe
| Pattern | Exemple | Match |
|---|---|---|
| `notre équipe va/devra` | "notre équipe va vérifier" | ✅ |
| `notre service/support va` | "notre service va traiter" | ✅ |

### Infinitifs liés
| Pattern | Exemple | Match |
|---|---|---|
| `et/pour (vous) recontacter` | "et vous recontacter rapidement" | ✅ |
| `afin de revenir/recontacter/rappeler` | "afin de revenir vers vous" | ✅ |
| `procéder à une vérification` | "procéder à une vérification complète" | ✅ |
| `s'assurer que vous` | "s'assurer que vous receviez" | ✅ |
| `nous allons (nous) assurer` | "nous allons nous assurer" | ✅ |

---

## 4. FAUX POSITIFS ÉVITÉS

| Phrase | Match ? | Raison |
|---|---|---|
| "votre commande est en cours de livraison par le transporteur" | ❌ NON | Information factuelle sans engagement |
| "le transporteur indique une livraison prévue demain" | ❌ NON | Information tiers, pas de promesse |
| "vous pouvez vérifier votre suivi sur le site du transporteur" | ❌ NON | Suggestion au client, pas d'engagement agent |

Les patterns ciblent spécifiquement les formes verbales avec sujet humain (je/nous/notre équipe) suivi d'un verbe d'action. Les descriptions factuelles et les suggestions ne matchent pas.

---

## 5. GUARDRAIL CONSUME

### Comportement

Le guardrail s'active dans `/autopilot/draft/consume` **uniquement** quand :
1. `action = 'applied'` (l'utilisateur valide le draft)
2. `wasEscalationDraft = false` (le draft était classé `DRAFT_GENERATED`)
3. Le texte du draft contient au moins une promesse détectée

### Actions si détection positive
- `wasEscalationDraft` reclassifié à `true`
- `escalationReason` = "Promesse d'action détectée (guardrail): [labels]"
- `escalationTarget` = "client"
- Le flux existant d'escalade s'exécute :
  - `conversations.escalation_status = 'escalated'`
  - `conversations.status = 'pending'`
  - `conversations.escalated_at = now()`
  - `conversations.escalated_by_type = 'ai'`
  - `message_events` → `autopilot_escalate`

### Ce qui n'est PAS fait
- Pas d'assignation auto
- Pas de notification
- Pas de changement UI
- Le draft est quand même marqué `DRAFT_APPLIED`

---

## 6. IMAGE DEV

| Élément | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.92-autopilot-promise-detection-guardrail-dev` |
| Digest | `sha256:27fbc3dd71d831ef3ff81f0e8438e30ebc276cb1188fe5301f2ce018363dc303` |
| Branche | `ph147.4/source-of-truth` |
| Commit API | `fcf8d67c` (2 commits : `f833b4c8` patch + `fcf8d67c` fix SQL) |
| Build | `--no-cache`, build-from-git |
| TS compilation | Propre, 0 erreurs |

---

## 7. VALIDATION E2E DEV

### Cas B — Guardrail consume (DRAFT_GENERATED avec promesse)

| Étape | Résultat |
|---|---|
| Draft inséré | `test-guardrail-1776790597547`, type `DRAFT_GENERATED` |
| Texte draft | "je transmets immédiatement votre demande [...] recontacter rapidement" |
| Consume `POST /autopilot/draft/consume` | 200 `{"consumed":true,"action":"applied","escalated":true}` |
| `escalation_status` | **`escalated`** ✅ |
| `status` | **`pending`** ✅ |
| `escalation_reason` | "Promesse d'action détectée (guardrail): je transmets (présent), et recontacter" ✅ |
| `escalated_by_type` | `ai` ✅ |
| `escalation_target` | `client` ✅ |
| `message_events` | `evt-...-kxmhn69y0` type `autopilot_escalate` ✅ |

### Cas C — Non-promesse (ne doit PAS escalader)

| Étape | Résultat |
|---|---|
| Draft inséré | `test-nopromise-...`, type `DRAFT_GENERATED` |
| Texte draft | "votre commande est en cours de livraison [...] arriver demain" |
| Consume | 200 `{"consumed":true,"action":"applied","escalated":false}` |
| `escalation_status` | `none` ✅ |
| Faux positif | **NON** ✅ |

### Tableau récapitulatif

| Cas | Draft type | Promise detected | Consume | Escalation DB | Status |
|---|---|---|---|---|---|
| B — Guardrail | DRAFT_GENERATED | "je transmets, et recontacter" | applied, escalated:true | `escalated` ✅ | `pending` ✅ |
| C — Non-promesse | DRAFT_GENERATED | aucune | applied, escalated:false | `none` ✅ | inchangé ✅ |

### Test unitaire patterns (15/15)

| # | Phrase | Détectée ? | Labels |
|---|---|---|---|
| 1 | "je transmets immédiatement votre demande" | ✅ | je transmets (présent) |
| 2 | "je transmettrai votre dossier" | ✅ | futur simple (je ___rai) |
| 3 | "je vérifierai auprès du transporteur" | ✅ | futur simple (je ___rai) |
| 4 | "notre équipe va vérifier" | ✅ | notre équipe va... |
| 5 | "notre équipe va investiguer" | ✅ | notre équipe va... |
| 6 | "nous organiserons une nouvelle livraison" | ✅ | futur simple (nous ___rons) |
| 7 | "nous procéderons à une vérification" | ✅ | nous allons effectuer, futur simple |
| 8 | "nous allons nous assurer que vous receviez" | ✅ | nous allons nous assurer |
| 9 | "je vais m assurer que votre dossier" | ✅ | je vais m'assurer |
| 10 | Cas PROD réel complet | ✅ | je transmets, et recontacter |
| 11 | "je vais contacter le transporteur" (legacy) | ✅ | je vais contacter |
| 12 | "je vais vérifier votre commande" (legacy) | ✅ | je vais vérifier |
| NEG1 | "votre commande est en cours de livraison" | ❌ | - |
| NEG2 | "le transporteur indique une livraison" | ❌ | - |
| NEG3 | "vous pouvez vérifier votre suivi" | ❌ | - |

---

## 8. NON-RÉGRESSION DEV

| Vérification | Résultat |
|---|---|
| API Health | ✅ `{"status":"ok"}` |
| Backend Health | ✅ `{"status":"ok"}` |
| API Pod | ✅ Running, 0 restarts |
| Backend callback | ✅ `v1.0.46-ph-recovery-01-dev` (inchangé) |
| Outbound worker | ✅ Running |
| Inbound DEV | ✅ Health interne OK |
| Autopilot draft | ✅ Route fonctionnelle |
| AI Assist | ✅ 400 (route active, params manquants = normal) |
| Reply classique | ✅ 400 (route active, conv inexistante = normal) |
| Billing/KBActions | ✅ Wallets intacts |
| CrashLoopBackOff | ✅ Aucun |
| Metrics | ✅ Non impacté (aucun fichier metrics modifié) |
| Tracking | ✅ Non impacté |

---

## 9. ROLLBACK DEV

```bash
# Rollback immédiat :
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.91-autopilot-escalation-handoff-fix-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

GitOps infra : restaurer la ligne dans `k8s/keybuzz-api-dev/deployment.yaml` vers `v3.5.91-autopilot-escalation-handoff-fix-dev`.

---

## 10. PROD NON TOUCHÉE

| Vérification | Résultat |
|---|---|
| Image PROD | `v3.5.91-autopilot-escalation-handoff-fix-prod` ✅ |
| Pod PROD | Running, 0 restarts, 9h+ uptime ✅ |
| Manifest PROD | Non modifié ✅ |
| Build PROD | Non effectué ✅ |
| Deploy PROD | Non effectué ✅ |

---

## 11. COMMITS

| Hash | Message |
|---|---|
| `f833b4c8` | PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01: shared promise detection + consume guardrail |
| `fcf8d67c` | fix: remove JS comment inside SQL template literal causing syntax error |

GitOps infra :
| Hash | Message |
|---|---|
| `2a97085` | GitOps: API DEV → v3.5.92-autopilot-promise-detection-guardrail-dev |

---

## 12. BUG EXISTANT CORRIGÉ

En plus du fix principal, un bug existant a été découvert et corrigé :

**Bug** : Un commentaire JavaScript `// PH-ESCALATION-HANDOFF-FIX-01: use valid workflow status` était à l'intérieur d'une chaîne SQL template literal dans `routes.ts` ligne 351. PostgreSQL recevait le `//` comme partie de la requête SQL et retournait `syntax error at or near "//"`.

**Impact** : L'escalade via `ESCALATION_DRAFT` ne fonctionnait pas du tout depuis le commit `7265d29a` (PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01) — la requête SQL échouait systématiquement.

**Fix** : Suppression du commentaire de la chaîne SQL.

---

## VERDICT

**AUTOPILOT PROMISE DETECTION GUARDRAIL FIXED IN DEV — PROD UNTOUCHED**

### Résumé

1. **Helper partagé** `src/lib/promise-detection.ts` : source de vérité unique pour 37 patterns regex, couvrant présent, futur simple, 3ème personne, et infinitifs liés.

2. **Guardrail consume** : re-détection des promesses dans les `DRAFT_GENERATED` au moment du consume. Si des promesses sont détectées, le draft est reclassifié et l'escalade est écrite en DB.

3. **Bug SQL corrigé** : le commentaire JS à l'intérieur de la requête SQL empêchait l'escalade `ESCALATION_DRAFT` de fonctionner.

4. **Validation E2E** : guardrail fonctionne (DRAFT_GENERATED avec promesse → escalation=escalated, status=pending), pas de faux positif (DRAFT_GENERATED sans promesse → pas d'escalade).

5. **Non-régression** : tous les systèmes DEV fonctionnent normalement, PROD strictement intouchée.

**STOP — Attendre validation explicite de Ludovic : "Tu peux push PROD"**
