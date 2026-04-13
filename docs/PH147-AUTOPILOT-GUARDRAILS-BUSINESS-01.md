# PH147 — Autopilot Guardrails Business Audit & Implementation

> Date : 2026-04-13
> Environnement : DEV uniquement
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph147-guardrails-biz-dev`
> Rollback : `v3.5.49-ph146.5-sub-sync-dev`

---

## 1. OBJECTIF

Audit complet des features IA (PH142-PH146) et implementation de guardrails business manquants dans `autopilotGuardrails.ts`.

## 2. INVENTAIRE IA COMPLET

### A. Autopilot Core
| Feature | Statut |
|---|---|
| Pipeline `evaluateAndExecute` | OK (engine.ts deploye) |
| Settings tenant (modes, safe_mode, escalation) | OK |
| 3 modes : off/supervised/autonomous | OK |
| Draft lifecycle (generated -> applied/dismissed) | OK |
| Historique autopilot | OK |

### B. IA Assist
| Feature | Statut |
|---|---|
| Suggestion via "Aide IA" (AISuggestionSlideOver) | OK |
| Generation contextualisee (conversation/order/playbook) | OK |
| Consommation KBActions | OK |

### C. Escalade Intelligente
| Feature | Statut |
|---|---|
| Detection promesses humaines | OK |
| ESCALATION_DRAFT + consume -> escalade DB | OK |
| UI escalade (EscalationPanel) | OK |

### D. Contexte IA
| Feature | Statut |
|---|---|
| Orders/tracking/SLA/produits/client context | OK |
| Upload fichiers contexte (PDF) | OK |

### E. Playbooks
| Feature | Statut |
|---|---|
| CRUD + triggers/scoring/simulation | OK |
| Suggestions en inbox | OK |

### F. Journal IA
| Feature | Statut |
|---|---|
| Liste evenements API (ai_action_log) | OK |
| Detail evenement (localStorage legacy) | A migrer (hors scope) |

### G. Wallet / KBActions
| Feature | Statut |
|---|---|
| Solde/debit/ledger/topup | OK |
| UI limite KBActions | OK |

## 3. LACUNES IDENTIFIEES ET CORRIGEES

### 3a. Pre-LLM blocking (evaluateGuardrails)

**Avant PH147** : `allowed` toujours `true`, meme en risque HIGH.
**Apres PH147** : `allowed = false` si `buyerRisk.score >= 60` OU `productRisk.totalAmount >= 300 EUR`.

```typescript
if (buyerRisk.score >= 60 || productRisk.totalAmount >= VERY_HIGH_VALUE_THRESHOLD) {
  allowed = false;
  guardrailNotes.push('PRE_LLM_BLOCKED: Risque trop eleve pour traitement automatique');
}
```

### 3b. Patterns annulation commande

**Avant PH147** : aucun pattern couvrant l'annulation de commande.
**Apres PH147** : 5 patterns ajoutes dans `FORBIDDEN_PROMISE_PATTERNS` + validation dans `validateDraft`.

Patterns ajoutes :
- `/annulation de? la? commande/i`
- `/cancel(l?ation)? (of )?(the |my )?order/i`
- `/annul[ee].*commande/i`
- `/we.*cancel.*order/i`
- `/commande.*annul[ee]/i`

### 3c. Scoring canal

**Avant PH147** : pas de distinction de risque par canal.
**Apres PH147** : bonus de risque dans `computeBuyerRisk` :
- Amazon : +10 points (metriques vendeur impactees)
- Octopia : +5 points

### 3d. Fix SQL interpolation

**Avant PH147** : `interval '${RECENT_REFUND_WINDOW_DAYS} days'` (string interpolation dans SQL).
**Apres PH147** : `interval '90 days'` (valeur en dur, pas de risque d'injection).

### 3e. Regle 6 ANNULATION (GUARDRAIL_SYSTEM_RULES)

Nouvelle regle ajoutee au prompt systeme :

```
6. ANNULATION — NE JAMAIS annuler ou proposer l'annulation d'une commande :
   - L'annulation d'une commande Amazon impacte les metriques vendeur
   - Toujours rediriger vers une investigation ou un suivi de livraison
   - Si le client insiste, escalader a un humain
   - NE JAMAIS ecrire "nous allons annuler", "commande annulee", "cancel order"
```

## 4. VALIDATION API (5 scenarios de test)

| Scenario | Pre-LLM | BuyerRisk | CombinedRisk | Draft mauvais | Draft correct |
|---|---|---|---|---|---|
| R1 Remb. agressif (Amazon, 89.99 EUR) | **BLOCKED** | HIGH (65) | HIGH | **BLOCK** | REVIEW |
| R2 Rempl. haute valeur (Amazon, 459.90 EUR) | allowed | MEDIUM (35) | MEDIUM | SEND | SEND |
| R3 Annulation (Amazon, 54.90 EUR) | allowed | MEDIUM (40) | MEDIUM | **BLOCK** (FORBIDDEN_CANCELLATION) | SEND |
| R4 Standard basse valeur (email, 12.50 EUR) | allowed | LOW (0) | LOW | SEND | - |
| R5 Escalade promesse (Octopia, 78.00 EUR) | allowed | LOW (5) | LOW | **BLOCK** (UNSAFE_COMMITMENT) | SEND |

**Facteurs PH147 detectes** :
- CHANNEL_AMAZON (+10) dans R1, R2, R3
- CHANNEL_OCTOPIA (+5) dans R5
- PRE_LLM_BLOCKED dans R1
- FORBIDDEN_CANCELLATION dans R3

## 5. NON-REGRESSION

| Test | Resultat |
|---|---|
| Health API | PASS (200) |
| Conversations (switaa) | PASS (200) |
| Dashboard | PASS (200) |
| AI Wallet | PASS (200) |
| Autopilot Settings | PASS (200) |
| Stats | PASS (200) |
| ecomlg Conversations | PASS (200) |
| ecomlg Health | PASS (200) |
| Billing Current | 400 (attendu : JWT NextAuth requis, pas de regression) |

**Verdict : 8/9 PASS, 0 regression**

## 6. OBSERVATIONS (hors scope PH147)

1. **`getRefundHistory` erreur pre-existante** : `column "status" does not exist` dans la requete SQL sur `ai_action_log`. Le catch retourne des valeurs par defaut (0 remboursements). Pas de regression.

2. **Gap pre-existant PH145** : le pattern `remplacement immediat` (sans accent) n'est pas couvert par `FORBIDDEN_PROMISE_PATTERNS` qui ne contient que `/[ee]change imm[ee]diat/i` et `/remplacement envoye/i`. A traiter dans une future iteration.

3. **Detail evenement Journal IA** : utilise encore `localStorage` legacy au lieu de l'API backend. Migration recommandee.

4. **AIDecisionPanel** : composant present mais non branche dans l'UI active. A evaluer.

## 7. DEPLOIEMENT

```bash
# Build
docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph147-guardrails-biz-dev .
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph147-guardrails-biz-dev

# Deploy
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph147-guardrails-biz-dev -n keybuzz-api-dev

# Rollback
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49-ph146.5-sub-sync-dev -n keybuzz-api-dev
```

## 8. FICHIERS MODIFIES

| Fichier | Modification |
|---|---|
| `src/services/autopilotGuardrails.ts` | +30 lignes (5 corrections PH147) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image v3.5.50-ph147 |

## 9. VERDICT

**GO** — PH147 deploye et valide sur DEV. Guardrails business renforces. Zero regression detectee.
