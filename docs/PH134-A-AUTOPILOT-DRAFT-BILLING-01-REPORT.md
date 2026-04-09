# PH134-A — Autopilot Draft Billing

> Phase : PH134-A-AUTOPILOT-DRAFT-BILLING-TRUTH-RECOVERY-01
> Date : 2026-03-30
> Statut : **DEV + PROD DEPLOYES**

---

## Probleme

Le moteur Autopilot (PH133-A) generait des brouillons IA via LLM sans consommer de KBActions.
Le chemin `DRAFT_GENERATED` (safe_mode) retournait directement avec `kbActionsDebited: 0` sans jamais appeler `debitKBActions()`, alors que le cout LLM etait deja engage.

Un utilisateur pouvait :
- generer des drafts IA illimites
- copier/coller les reponses
- ne rien payer

## Cause racine

Dans `engine.ts`, le bloc safe_mode (DRAFT_GENERATED) effectuait un `return` premature AVANT les etapes 11 (log) et 12 (debit KBA). Aucun mecanisme de facturation n'etait prevu pour ce chemin.

## Solution

### 1. Ajout du poids `autopilot_draft` dans `kbactions.ts`

```javascript
KBACTIONS_WEIGHTS = {
  // ...
  'playbook_auto':     8.0,  // execution auto
  'autopilot_draft':   8.0,  // draft genere (meme cout LLM)
  // ...
}
```

Meme cout que `playbook_auto` car le travail IA est identique (LLM call, context enrichment, confidence scoring).

### 2. Modification du chemin DRAFT_GENERATED dans `engine.ts`

Avant (PH133-A) :
```
safe_mode + action bloquee → log(kbaCost=0) → return(kbActionsDebited=0)
```

Apres (PH134-A) :
```
safe_mode + action bloquee
  → computeKBActions('autopilot_draft') = ~8.0 KBA
  → debitKBActions(tenantId, requestId, kbaCost, conversationId)
  → si wallet vide → DRAFT_WALLET_EMPTY (aucun draft genere)
  → si debit OK → log(kbaCost) → return(kbActionsDebited=kbaCost)
```

### Idempotence

`debitKBActions()` utilise `requestId` comme cle d'idempotence dans `ai_actions_ledger`. Un meme `requestId` ne peut pas etre debite deux fois.

### Gestion erreurs

| Cas | Comportement |
|---|---|
| Draft genere | Debit KBA via `debitKBActions()` |
| Wallet vide | `DRAFT_WALLET_EMPTY` - pas de draft, pas de debit |
| Erreur IA / escalation / confidence faible | Pas de debit (retour avant le bloc draft) |
| Meme requestId rejoue | Idempotent - pas de double debit |

## Fichiers modifies

| Fichier | Changement |
|---|---|
| `src/config/kbactions.ts` | Ajout `autopilot_draft: 8.0` |
| `src/modules/autopilot/engine.ts` | Debit KBA dans le chemin DRAFT_GENERATED |

## Non-regressions

| Element | Statut |
|---|---|
| Autopilot execution (non safe_mode) | Non touche — debit existant via `playbook_auto` |
| Playbook suggestions | Non touche |
| AI assist / suggestions inbox | Non touche |
| Billing / Stripe | Non touche |
| Wallet management | Utilise le meme `debitKBActions()` |
| Returns decision | Non touche |
| Inbox / Messages | Non touche |
| Health API | OK |

## Validation DEV

- Build compile : OK
- `KBACTIONS_WEIGHTS['autopilot_draft']` = 8 (confirme dans le build)
- API health : OK
- `debitKBActions()` idempotent sur `requestId` : mecanisme existant verifie
- `logAction()` ecrit `kbaCost` dans payload JSON : confirme
- Wallet ecomlg-001 : 4.11 KBA restants (fonctionnel)

## Versions DEV

| Service | Image |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.139-autopilot-draft-billing-dev` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.138-amazon-line-visual-fix-dev -n keybuzz-api-dev
```

## Versions PROD

| Service | Image |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.139-autopilot-draft-billing-prod` |

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.138-amazon-line-visual-fix-prod -n keybuzz-api-prod
```

## Verdict

AUTOPILOT DRAFT BILLING ACTIVE — NO FREE USAGE — IDEMPOTENT — WALLET SAFE — ROLLBACK READY
