# PH142-E — AUTOPILOT SAFE MODE DRAFT RECOVERY

**Date** : 2026-04-04
**Type** : Correction critique UX autopilot
**Statut** : DEV + PROD deployes

---

## Objectif

Restaurer le comportement correct du mode Autopilot avec validation (safe mode) :
- Affichage clair du brouillon IA
- Validation obligatoire avant envoi
- Coherence avec PH142-C (fausses promesses) et PH142-D (auto-escalation)

## Probleme racine

`AutopilotDraftBanner` existait comme composant complet (avec BFF `/api/autopilot/draft`) mais n'etait **jamais importe ni rendu** dans `InboxTripane.tsx`. Le draft autopilot safe_mode etait genere et stocke dans `ai_action_log` mais invisible pour l'utilisateur.

## Modifications

### Client — `InboxTripane.tsx`
- Import de `AutopilotDraftBanner` (PH142-E)
- Ajout de `sendAutopilotDraft` callback pour envoi direct depuis le brouillon
- Rendu du banner au-dessus de la zone de reponse (textarea)

### Client — `AutopilotDraftBanner.tsx`
- Reecrit avec support escalation :
  - Badge "Escalade prevue" si conversation escaladee
  - Warning "promesse d'action" si `needsHumanAction`
  - Boutons : **Valider et envoyer** / **Modifier** / **Ignorer**
  - Draft TOUJOURS visible, meme en cas d'escalade
- Props : `escalationStatus`, `escalationReason`, `needsHumanAction` supportees

### API — `autopilot/routes.ts`
- `GET /autopilot/draft` enrichi avec JOIN sur `conversations` pour inclure `escalation_status` et `escalation_reason`
- Reponse inclut `escalationStatus`, `escalationReason`, `needsHumanAction`

### API — `autopilot/engine.ts`
- Ajout de `detectFalsePromises()` (coherent avec PH142-C)
- Detection appliquee au draft genere en safe_mode
- Metadonnees `needsHumanAction` et `falsePromisePatterns` ajoutees au payload de log
- `logAction` accepte `extraMeta` optionnel

## Flux corrige

```
1. Message client entrant
2. Autopilot engine evalue (si plan AUTOPILOT + safe_mode)
3. Draft genere -> stocke dans ai_action_log
4. Detection fausses promesses (PH142-C)
5. AutopilotDraftBanner affiche le draft dans l'inbox
6. Agent voit : draft + confiance + warnings eventuels
7. Agent choisit : Valider / Modifier / Ignorer
8. Si "Valider" : envoi direct via sendAutopilotDraft
9. Si "Modifier" : texte copie dans le champ de reponse
10. Si "Ignorer" : draft dismiss
```

## Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.187-autopilot-safe-mode-fix-dev` | `v3.5.187-autopilot-safe-mode-fix-prod` |
| Client | `v3.5.187-autopilot-safe-mode-fix-dev` | `v3.5.187-autopilot-safe-mode-fix-prod` |

## Tests

| Test | Resultat |
|------|----------|
| API health check | OK (HTTP 200) |
| Draft endpoint (no draft) | OK (`hasDraft: false`) |
| Draft endpoint (with escalation join) | OK (SQL OK) |
| Autopilot settings | OK (safe_mode: true) |
| AI Journal non-regression | OK (200) |
| Error clusters non-regression | OK (200) |
| Conversations non-regression | OK (200) |
| Client health | OK (HTTP 200) |

## Rollback

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-auto-escalation-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.185-ai-action-consistency-dev -n keybuzz-client-dev

# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-auto-escalation-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.185-ai-action-consistency-prod -n keybuzz-client-prod
```

## Non-regression

- PH142-A (Quality Loop) : intact
- PH142-B (Error Clustering) : intact
- PH142-C (Action Consistency) : intact + renforce (detection dans autopilot engine)
- PH142-D (Auto Escalation) : intact + visible dans banner
- Autopilot non-securise : non affecte (pas de banner)
- Billing : non touche
- Multi-tenant : strict (tenantId requis partout)
