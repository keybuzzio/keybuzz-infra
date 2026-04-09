# PH135-A — Autopilot Behavior Control

> Phase : PH135-A-AUTOPILOT-BEHAVIOR-CONTROL-01
> Date : 2026-03-30
> Statut : **DEV + PROD DEPLOYES**

---

## Probleme

Le comportement de l'Autopilot etait imprevisible :
- parfois draft, parfois escalation, parfois silence total
- 13 chemins de sortie dont la majorite = noop silencieux
- seuil de confiance trop haut (0.75) → trop d'escalations
- prompt LLM orientait vers `none`/`escalate` plutot que `reply`
- les cas LOW_CONFIDENCE avaient un draft mais celui-ci etait ignore

## Corrections appliquees (4 fixes)

### FIX 1 — Seuil de confiance abaisse

```
AVANT: CONFIDENCE_THRESHOLD = 0.75
APRES: CONFIDENCE_THRESHOLD = 0.60
```

Un draft prudent avec 0.65 de confiance est plus utile qu'une escalation silencieuse.

### FIX 2 — Prompt systeme reecrit (draft-first)

| Avant | Apres |
|---|---|
| "Ne propose JAMAIS une reponse si tu n'es pas sur" | "Tu dois TOUJOURS proposer une reponse sauf cas extreme" |
| actions: reply/assign/escalate/status_change/none | actions: reply/escalate uniquement |
| Pas de raison structuree | `actionReason` obligatoire (TRACKING_REQUEST, DELIVERY_INQUIRY, etc.) |
| Escalade si contexte insuffisant | "Dis-le dans la reponse au lieu d'escalader" |

### FIX 3 — LOW_CONFIDENCE produit un draft

| Avant | Apres |
|---|---|
| confidence < seuil → escalation systematique | confidence < seuil + draft disponible → `LOW_CONFIDENCE_DRAFT` |
| Draft existant perdu | Draft utilise + KBA debite |
| | Pas de draft utilisable → `LOW_CONFIDENCE_ESCALATION` |

### FIX 4 — Conversion action `none` en reply/escalate

| Action LLM | Avant | Apres |
|---|---|---|
| `none` | noop silencieux | Si draft dispo → `reply`, sinon → `escalate` |
| `assign` | noop si pas d'agentId | Si draft dispo → `reply`, sinon → `escalate` |
| `status_change` | noop si pas de status | Si draft dispo → `reply`, sinon → `escalate` |

## Nouvelle hierarchie des comportements

```
1. Message inbound arrive
2. Engine evalue
3. LLM genere suggestion
4. Si confidence >= 0.60 ET action=reply → DRAFT (normal)
5. Si confidence < 0.60 ET draft disponible → LOW_CONFIDENCE_DRAFT (prudent)
6. Si action=none/assign/status_change ET draft → converti en reply
7. Si aucun draft exploitable → ESCALATION (dernier recours)
```

Objectif : **80%+ des messages → draft IA**, escalation = cas rare justifie.

## Cas de sortie restants (legitimes)

| Raison | Comportement | Justification |
|---|---|---|
| NO_SETTINGS | noop | Pas configure |
| DISABLED | noop | Desactive par l'utilisateur |
| PLAN_INSUFFICIENT | noop | Plan < AUTOPILOT |
| MODE_NOT_AUTONOMOUS | noop | Mode supervised/suggestion |
| WALLET_EMPTY | noop | Plus de KBA |
| CONVERSATION_NOT_FOUND | noop | Erreur donnees |
| LAST_MESSAGE_NOT_INBOUND | noop | Message sortant |
| RATE_LIMITED | noop | Protection anti-boucle |
| DRAFT_WALLET_EMPTY | noop | Wallet epuise au moment du draft |
| ERROR | noop | Exception |

Ces cas sont tous **legitimes** (configuration, donnees, ou protection).

## Fichiers modifies

| Fichier | Changement |
|---|---|
| `src/modules/autopilot/engine.ts` | Seuil, prompt, LOW_CONFIDENCE_DRAFT, conversion none→reply |

## Non-regressions

| Element | Statut |
|---|---|
| PH134-A (billing draft) | Conserve — debit via `computeKBActions('autopilot_draft')` |
| PH133-A (draft IA) | Conserve — contexte order/tracking/temporal intact |
| PH133-D (outbound Amazon) | Non touche |
| Playbook suggestions | Non touche |
| Billing / Stripe | Non touche |
| Wallet | Meme `debitKBActions()` |
| Inbox | Non touche |
| Health API | OK |

## Versions DEV

| Service | Image |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.140-autopilot-behavior-control-dev` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.139-autopilot-draft-billing-dev -n keybuzz-api-dev
```

## Versions PROD

| Service | Image |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.140-autopilot-behavior-control-prod` |

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.139-autopilot-draft-billing-prod -n keybuzz-api-prod
```

## Verdict

AUTOPILOT BEHAVIOR CONTROLLED — NO SILENCE — DRAFT FIRST — ESCALATION CONTROLLED — TENANT SAFE — ROLLBACK READY
