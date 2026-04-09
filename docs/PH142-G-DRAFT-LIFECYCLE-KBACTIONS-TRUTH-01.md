# PH142-G — Draft Lifecycle & KBActions Truth

> Date : 1 mars 2026
> Phase : PH142-G-DRAFT-LIFECYCLE-KBACTIONS-TRUTH-01
> Statut : DEV + PROD deployes

---

## Objectif

Eliminer les "ghost drafts" (drafts autopilot qui reapparaissent apres action utilisateur) et verifier la verite du debit KBActions.

## Cause racine (ghost drafts)

| Probleme | Detail |
|----------|--------|
| Source verite | `ai_action_log.blocked_reason = 'DRAFT_GENERATED'` |
| Frontend | Actions "Envoyer/Modifier/Ignorer" ne faisaient que mettre a jour un `useRef` local |
| Rechargement | Le ref est perdu, le `GET /autopilot/draft` re-fetche le meme draft intact |
| Backend | Aucun endpoint pour marquer un draft comme consomme |

## Solution : Source de verite backend

### Nouveau endpoint : `POST /autopilot/draft/consume`

| Param | Type | Description |
|-------|------|-------------|
| tenantId | string | Tenant ID |
| conversationId | string | Conversation ID |
| logId | string | ID de l'entree ai_action_log |
| action | string | `applied` / `dismissed` / `modified` |

**Comportement :**
1. UPDATE `ai_action_log` SET `blocked_reason` = `DRAFT_APPLIED` / `DRAFT_DISMISSED` / `DRAFT_MODIFIED` WHERE `blocked_reason = 'DRAFT_GENERATED'`
2. Ajout `consumedAt` dans le payload JSONB
3. INSERT trace `draft_applied` / `draft_dismissed` / `draft_modified` dans `ai_action_log`
4. Le `GET /autopilot/draft` ne retourne plus ce draft (filtre `blocked_reason = 'DRAFT_GENERATED'` ne matche plus)

### Frontend

Le drawer unifie (`AISuggestionSlideOver`) appelle `consumeDraft()` apres chaque action :
- "Valider et envoyer" → `consumeDraft('applied')`
- "Modifier" → `consumeDraft('modified')`
- "Ignorer" → `consumeDraft('dismissed')`

La fonction `consumeDraft` fait un POST vers `/api/autopilot/draft/consume` + met a jour le ref local.

## Table de verite KBActions

| Etape | Debit KBActions | Source |
|-------|----------------|--------|
| Generation du draft | OUI — `debitKBActions()` ligne 295 de engine.ts | Debit a la generation, idempotent sur `requestId` |
| Validation et envoi | NON — envoi du message seulement | Pas de double-debit |
| Modification et envoi | NON — copie dans textarea | Pas de debit supplementaire |
| Ignore | NON — aucune action IA | Pas de debit |
| Regeneration (nouveau) | OUI — nouvelle generation IA | Nouveau `requestId`, nouveau debit |

**Verdict : Pas de double-debit. Pas d'oubli. Le debit est correct et idempotent.**

## Avant / Apres

| Scenario | Avant | Apres |
|----------|-------|-------|
| Envoyer puis revenir | Draft reapparait | Draft marque `DRAFT_APPLIED`, ne reapparait plus |
| Ignorer puis revenir | Draft reapparait | Draft marque `DRAFT_DISMISSED`, ne reapparait plus |
| Modifier puis revenir | Draft reapparait | Draft marque `DRAFT_MODIFIED`, ne reapparait plus |
| Rechargement page | Draft reapparait | Backend est la source de verite |
| Changement conversation | OK (ref reset) | OK (ref reset + backend) |

## Trace d'audit

Chaque action utilisateur cree une entree dans `ai_action_log` :

| action_type | status | payload |
|-------------|--------|---------|
| `draft_applied` | completed | `{ originalLogId, action: "applied", source: "user_action" }` |
| `draft_dismissed` | completed | `{ originalLogId, action: "dismissed", source: "user_action" }` |
| `draft_modified` | completed | `{ originalLogId, action: "modified", source: "user_action" }` |

## Modifications

### Backend (keybuzz-api)
- `src/modules/autopilot/routes.ts` : ajout `POST /autopilot/draft/consume`

### Frontend (keybuzz-client)
- `src/features/ai-ui/AISuggestionSlideOver.tsx` :
  - `AutopilotDraft` : ajout champ `logId`
  - Ajout helper `consumeDraft(action)`
  - 3 boutons appellent `consumeDraft()` avant de fermer
- `app/inbox/InboxTripane.tsx` : passage du `logId` dans le draft
- `app/api/autopilot/draft/consume/route.ts` : route BFF (proxy POST)

## Tests DEV

| Test | Resultat |
|------|----------|
| API health | 200 |
| Consume (draft inexistant) | 200 `consumed: false` |
| Consume (params manquants) | 400 |
| GET /autopilot/draft | 200 |
| AI settings (PH142-A) | 200 |
| AI journal (PH142-A) | 200 |
| Error clusters (PH142-B) | 200 |
| Client DEV health | 200 |

## Images deployees

| Service | Env | Image |
|---------|-----|-------|
| API | DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.189-draft-lifecycle-kbactions-dev` |
| Client | DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.189-draft-lifecycle-kbactions-dev` |
| API | PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.189-draft-lifecycle-kbactions-prod` |
| Client | PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.189-draft-lifecycle-kbactions-prod` |

## Rollback DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.187-autopilot-safe-mode-fix-dev -n keybuzz-api-dev

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.188-ai-drawer-unified-dev -n keybuzz-client-dev
```

## Rollback PROD

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.187-autopilot-safe-mode-fix-prod -n keybuzz-api-prod

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.188-ai-drawer-unified-prod -n keybuzz-client-prod
```

## Non-regression

- PH142-A (Quality Loop) : OK
- PH142-B (Error Clustering) : OK
- PH142-C (Action Consistency) : OK
- PH142-D (Auto Escalation) : OK
- PH142-E (Safe Mode) : OK (backward compat)
- PH142-F (Unified Drawer) : OK
- Autopilot non-securise : inchange
- Billing : non touche
- Multi-tenant : strict
