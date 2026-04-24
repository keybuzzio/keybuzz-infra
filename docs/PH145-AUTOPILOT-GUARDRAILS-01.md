# PH145-AUTOPILOT-GUARDRAILS-01 — Garde-fous Métier Autopilot

> Date : 10 avril 2026
> Mise à jour : 10 avril 2026 (PH145-PROD-PREP-01 — clarification runtime + version)
> Statut : **PH145 READY FOR PROD PROMOTION — RUNTIME SOURCE CONFIRMED — VERSIONING CLEAN**
> Image DEV : `v3.5.240-ph145-guardrails-dev`
> PROD : Non modifiée (`v3.5.239-ph-autopilot-shopify-prod`)

---

## 1. Objectif

Ajouter des garde-fous métier à l'Autopilot pour protéger les vendeurs contre les décisions IA trop permissives : remboursements non justifiés, promesses risquées, absence d'investigation.

---

## 2. Audit Initial — Constats

### Ce qui existait AVANT PH145


| Composant            | État                                    | Problème                                     |
| -------------------- | --------------------------------------- | -------------------------------------------- |
| System prompt        | Basique (15 règles génériques)          | Aucune règle sur remboursements ou promesses |
| Scoring risque       | `strategicResolutionEngine.ts` existant | **Non connecté** au moteur Autopilot         |
| Safe mode            | Bloque l'action `reply`                 | Ne valide pas le **contenu** du draft        |
| Confidence threshold | 0.75 minimum                            | Auto-évalué par le LLM, pas fiable           |
| Validation post-LLM  | Inexistante                             | Le draft était accepté tel quel              |


### Décisions trop permissives identifiées

1. L'IA pouvait proposer "remboursement immédiat" sans investigation
2. Aucune vérification du montant commande avant de proposer un remboursement
3. Aucune vérification de l'historique de remboursements du client
4. Aucune détection de langage agressif ou de manipulation
5. Un produit à 500€ traité identiquement qu'un produit à 5€

---

## 3. Garde-fous Implémentés

### 3.1 Scoring Risque Client (BuyerRiskAssessment)

Scoring additif déterministe (0-100) → LOW / MEDIUM / HIGH.


| Facteur                | Points | Description                                   |
| ---------------------- | ------ | --------------------------------------------- |
| `REPEAT_REFUND`        | +30    | 3+ remboursements historiques                 |
| `PRIOR_REFUND`         | +10    | 1-2 remboursements                            |
| `RECENT_REFUND_SPIKE`  | +25    | 2+ remboursements dans les 90 derniers jours  |
| `OPEN_RETURN`          | +15    | Retour Amazon ouvert en cours                 |
| `AGGRESSIVE_LANGUAGE`  | +30    | 3+ patterns agressifs (avocat, arnaque, etc.) |
| `ELEVATED_TONE`        | +15    | 1-2 patterns agressifs                        |
| `DEMANDS_IMMEDIATE`    | +10    | Demande action immédiate                      |
| `FIRST_CONTACT_REFUND` | +15    | Demande remboursement dès le 1er message      |
| `HIGH_REFUND_HISTORY`  | +10    | Historique remboursement > 200€               |


**Niveaux** : 0-24 = LOW, 25-49 = MEDIUM, 50+ = HIGH

### 3.2 Scoring Risque Produit (ProductRiskAssessment)


| Facteur                   | Points      | Description                                |
| ------------------------- | ----------- | ------------------------------------------ |
| `VERY_HIGH_VALUE`         | +40         | Commande ≥ 300€                            |
| `HIGH_VALUE`              | +25         | Commande ≥ 100€                            |
| `MULTI_PRODUCT`           | +10         | 4+ articles                                |
| `PRIOR_REFUND_ON_ACCOUNT` | +20         | Remboursement antérieur sur le compte      |
| `FBM_FULFILLMENT`         | +5          | Expédié par le vendeur (risque plus élevé) |
| `NO_ORDER_DATA`           | 40 (défaut) | Pas de données commande → prudence         |


### 3.3 Règles Prompt Système (injectées dans chaque appel LLM)

5 catégories de règles strictes ajoutées au prompt système :

1. **REMBOURSEMENT** : Interdiction sans preuve, contrôle tracking, ou investigation
2. **PROMESSES INTERDITES** : Liste explicite de formulations bannies
3. **PRIORITÉ D'ACTION** : Information → Investigation → Preuve → Proposition → Escalation
4. **TON** : Professionnel, empathique, prudent. Pas d'excuse excessive ni d'aveu de faute
5. **MONTANTS ÉLEVÉS** : Commandes > 100€ → escalation recommandée, pas de remboursement intégral auto

### 3.4 Validation Post-LLM (DraftValidation)

Analyse du texte généré par le LLM **avant** envoi ou affichage :


| Pattern détecté                                         | Action                         |
| ------------------------------------------------------- | ------------------------------ |
| "remboursement immédiat"                                | **BLOCK**                      |
| "nous allons vous rembourser"                           | **BLOCK**                      |
| "je m'engage à"                                         | **BLOCK**                      |
| "remboursement intégral" (commande > 100€)              | **BLOCK**                      |
| Mention remboursement sans mention investigation/preuve | **REVIEW** (draft pour humain) |
| Risque combiné HIGH                                     | **REVIEW**                     |


### 3.5 Logique d'Escalation Automatique


| Condition                                        | Action                                       |
| ------------------------------------------------ | -------------------------------------------- |
| Draft contient pattern interdit                  | Escalation humaine + log `GUARDRAIL_BLOCKED` |
| Risque combiné = HIGH                            | Force mode draft (même si safe_mode = off)   |
| Draft contient mention remboursement sans preuve | Force review humain                          |


---

## 4. Intégration dans le Pipeline Autopilot

```
Avant PH145:
  Context → LLM → Confidence check → Execute/Draft

Après PH145:
  Context → RISK SCORING → LLM (avec prompt enrichi) → DRAFT VALIDATION → Confidence check → Execute/Draft/Block
```

Le pipeline enrichi ajoute 3 points de contrôle :

1. **Pré-LLM** : `evaluateGuardrails()` calcule les scores risque et génère le bloc de contexte
2. **Prompt** : Les règles métier (`GUARDRAIL_SYSTEM_RULES`) + le contexte risque sont injectés dans l'appel LLM
3. **Post-LLM** : `validateDraft()` vérifie le draft contre les patterns interdits

### Log structuré

Chaque exécution logge dans `ai_action_log` :

- `buyerRisk`, `productRisk`, `combinedRisk`
- `draftValidation` (SEND / REVIEW / BLOCK)
- `guardrailNotes` (facteurs de risque détectés)
- Raison du blocage si applicable (`GUARDRAIL_BLOCKED:FORBIDDEN_PROMISE:...`)

---

## 5. Fichiers Créés/Modifiés

### Clarification Runtime (PH145-PROD-PREP-01)

**Problème identifié** : L'intégration initiale ciblait `scripts/ph133a-engine-new.ts` et créait
un fichier `autopilotEngine.ts` — mais `routes.ts` importait de `./engine`, pas de `./autopilotEngine`.
Le code guardrails n'était donc **pas actif en runtime**.

**Correction** : Les garde-fous ont été intégrés directement dans le vrai fichier runtime
`src/modules/autopilot/engine.ts`. Le fichier mort `autopilotEngine.ts` a été supprimé.

### Fichier runtime réel

`**src/modules/autopilot/engine.ts`** est LE fichier runtime de l'Autopilot.

- C'est le seul fichier importé par `routes.ts` (`import { evaluateAndExecute } from './engine'`)
- Il est compilé en `dist/modules/autopilot/engine.js` et chargé par Node.js au démarrage
- **Preuve** : vérifié dans le pod running, `engine.js` contient `evaluateGuardrails` et `GUARDRAIL_BLOCKED`

### Chaîne de chargement

```
app.ts → app.register(autopilotRoutes, { prefix: '/autopilot' })
  → routes.ts → import { evaluateAndExecute } from './engine'
    → engine.ts → import { evaluateGuardrails, validateDraft, GUARDRAIL_SYSTEM_RULES } from '../../services/autopilotGuardrails'
```

### Fichiers


| Fichier                                    | Action       | Description                                                           |
| ------------------------------------------ | ------------ | --------------------------------------------------------------------- |
| `src/services/autopilotGuardrails.ts`      | **CRÉÉ**     | Module garde-fous (505 lignes, scoring + validation + prompt)         |
| `src/modules/autopilot/engine.ts`          | **MODIFIÉ**  | Intégration guardrails dans le vrai pipeline runtime (913→994 lignes) |
| `src/modules/autopilot/autopilotEngine.ts` | **SUPPRIMÉ** | Code mort (n'était pas importé par routes.ts)                         |
| `src/tests/ph145-guardrails-tests.ts`      | **CRÉÉ**     | Tests unitaires                                                       |


---

## 6. Exemples de Comportement

### Cas 1 : Demande remboursement simple, client normal, 25€

- Buyer risk: LOW (0)
- Product risk: LOW (0)
- Combined: LOW
- LLM reçoit les règles métier → propose investigation/information
- Draft validé → SEND

### Cas 2 : Produit endommagé, premier contact, 150€

- Buyer risk: LOW (0)
- Product risk: MEDIUM (25 — HIGH_VALUE)
- Combined: MEDIUM
- LLM reçoit contexte "prudence renforcée"
- Si draft mentionne "remboursement" sans "preuve/photo" → REVIEW

### Cas 3 : Client agressif, demande remboursement immédiat, 400€, retour ouvert

- Buyer risk: HIGH (60+ — AGGRESSIVE + DEMANDS_IMMEDIATE + OPEN_RETURN)
- Product risk: HIGH (60+ — VERY_HIGH_VALUE + PRIOR_REFUND)
- Combined: HIGH
- Pipeline force mode draft (même si safe_mode = off)
- Si LLM écrit "nous allons vous rembourser" → **GUARDRAIL_BLOCKED** + escalation humaine

### Cas 4 : Livraison retardée, client patient, 30€ Amazon FBA

- Buyer risk: LOW (0)
- Product risk: LOW (0)
- Combined: LOW
- LLM fournit information tracking factuelle → SEND

---

## 7. Non-Régression DEV (revalidation PROD-PREP)

**15/15 checks passés — 0 échecs — 0 warnings**


| #   | Check                                           | Résultat             |
| --- | ----------------------------------------------- | -------------------- |
| 1   | `/health`                                       | PASS (HTTP 200)      |
| 2   | Image tag `v3.5.240`                            | PASS (confirmé)      |
| 3   | `/messages/conversations`                       | PASS (HTTP 200)      |
| 4   | `/api/v1/orders`                                | PASS (HTTP 200)      |
| 5   | `/dashboard/summary`                            | PASS (HTTP 200)      |
| 6   | `/stats/conversations`                          | PASS (HTTP 200)      |
| 7   | `/autopilot/settings`                           | PASS (HTTP 200)      |
| 8   | `/ai/wallet/status`                             | PASS (HTTP 200)      |
| 9   | `engine.js` dans pod                            | PASS                 |
| 10  | `autopilotGuardrails.js` dans pod               | PASS                 |
| 11  | `autopilotEngine.js` absent (code mort nettoyé) | PASS                 |
| 12  | `GUARDRAIL_BLOCKED` dans engine.js compilé      | PASS (3 occurrences) |
| 13  | `evaluateGuardrails` dans engine.js compilé     | PASS (1 occurrence)  |
| 14  | Logs startup sans erreurs                       | PASS                 |
| 15  | PROD image inchangée (`v3.5.239`)               | PASS                 |


---

## 8. Convention de Versioning

### Problème identifié

L'image initiale PH145 utilisait `v3.5.49` alors que la ligne PROD était à `v3.5.239`.
Cela créait une incohérence de versioning.

### Correction


| Ancien tag (incorrect)         | Nouveau tag (correct)           |
| ------------------------------ | ------------------------------- |
| `v3.5.49-ph145-guardrails-dev` | `v3.5.240-ph145-guardrails-dev` |


**Règle** : le numéro de patch suit la ligne PROD. PROD = `v3.5.239` → DEV suivant = `v3.5.240`.
Format : `v3.5.<PROD_PATCH+1>-<feature>-<env>`

### Tag PROD prévu (après validation)

`v3.5.240-ph145-guardrails-prod`

---

## 9. Rollback

```bash
# Rollback DEV immédiat
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# Restaurer engine.ts original
cp /opt/keybuzz/keybuzz-api/src/modules/autopilot/engine.ts.pre-ph145.bak \
   /opt/keybuzz/keybuzz-api/src/modules/autopilot/engine.ts
```

---

## 10. Prochaines Étapes (après validation Ludovic)

1. **PROD** : Build `v3.5.240-ph145-guardrails-prod` et déploiement
2. **Monitoring** : Surveiller les logs `GUARDRAIL_BLOCKED` et `DRAFT_GUARDRAIL_REVIEW`
3. **Tuning** : Ajuster les seuils de scoring si trop/pas assez restrictif
4. **Dashboard** : Afficher le risk level dans le panel autopilot du client

---

## 11. Verdict Final

**PH145 READY FOR PROD PROMOTION — RUNTIME SOURCE CONFIRMED — VERSIONING CLEAN**

- Source runtime prouvée : `src/modules/autopilot/engine.ts` (importé par `routes.ts`)
- Code mort nettoyé : `autopilotEngine.ts` supprimé du build
- Guardrails actifs en runtime : vérifiés dans le pod (3 occurrences `GUARDRAIL_BLOCKED` dans engine.js compilé)
- Version alignée : `v3.5.240` (PROD = v3.5.239, cohérent)
- Non-régression : 15/15 checks passés
- PROD : intacte à `v3.5.239`

Attente validation explicite de Ludovic avant promotion PROD.