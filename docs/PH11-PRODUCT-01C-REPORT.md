# PH11-PRODUCT-01C - Garde-fous IA, SÃ©curitÃ©, Limites & Kill Switch

## RÃ©sumÃ©

Phase de sÃ©curisation de l'IA KeyBuzz avant montÃ©e en puissance. Mise en place de garde-fous, limites et mÃ©canismes de contrÃ´le pour garantir qu'aucune automatisation ne puisse nuire au client, Ã  la rÃ©putation ou Ã  la stabilitÃ© du systÃ¨me.

## Livrables

### 1. Backend (keybuzz-api v0.1.48-dev)

#### Migration DB (016_ai_guardrails.sql)
- **ai_settings** : nouvelles colonnes
  - `kill_switch` - dÃ©sactivation tenant
  - `max_actions_per_hour` (dÃ©faut: 20)
  - `max_auto_replies_per_conversation` (dÃ©faut: 3)
  - `max_consecutive_ai_actions` (dÃ©faut: 2)
  - `auto_disabled` - dÃ©sactivation automatique
  - `auto_disabled_reason` - raison de l'auto-dÃ©sactivation
  - `consecutive_errors` - compteur d'erreurs

- **ai_action_log** : nouvelles colonnes d'audit
  - `confidence_score` - score de confiance (0.00-1.00)
  - `confidence_level` - niveau (high/medium/low)
  - `blocked` - action bloquÃ©e oui/non
  - `blocked_reason` - raison du blocage
  - `blocked_by` - source du blocage
  - `validated_by` - qui a validÃ©
  - `validated_at` - timestamp validation

- **ai_global_settings** : nouvelle table
  - `global_kill_switch` - dÃ©sactivation globale
  - `global_kill_switch_reason` - raison
  - `system_health_ok` - Ã©tat systÃ¨me

#### Nouveaux Endpoints
| Endpoint | Description |
|----------|-------------|
| `GET /ai/global/settings` | RÃ©cupÃ¨re les paramÃ¨tres globaux |
| `PATCH /ai/global/settings` | Modifie le kill switch global |
| `POST /ai/guard/check` | VÃ©rifie les garde-fous avant action |

#### Middleware de garde-fous (checkGuardrails)
VÃ©rifie dans l'ordre :
1. Kill switch global
2. Ã‰tat systÃ¨me (system_health_ok)
3. Kill switch tenant
4. Auto-dÃ©sactivation (erreurs consÃ©cutives)
5. IA activÃ©e pour le tenant
6. Limite actions/heure (20 par dÃ©faut)
7. Limite rÃ©ponses/conversation (3 par dÃ©faut)
8. Limite actions consÃ©cutives sans humain (2 par dÃ©faut)

### 2. Admin UI (keybuzz-admin v0.1.54-dev)

#### ai.service.ts enrichi
- Nouveaux types : `AIGlobalSettings`, `AIGuardCheck`
- Nouvelles fonctions : `getAIGlobalSettings()`, `checkAIGuard()`
- Helpers : `getConfidenceEmoji()`, `getConfidenceBadgeColor()`

#### AIDecisionPanel enrichi
- Affichage du mode IA avec badge colorÃ©
- Gestion des Ã©tats bloquÃ©s
- Affichage du score de confiance avec emoji (ðŸŸ¢ðŸŸ¡ðŸ”´)

### 3. Client UI (keybuzz-client v0.2.8-dev)

#### AIDecisionPanel enrichi
- Panneau orange quand IA bloquÃ©e
- Message explicatif clair ("KeyBuzz en pause")
- Raison du blocage affichÃ©e
- Score de confiance avec badge colorÃ©
- Bouton "Appliquer" dÃ©sactivÃ© si confiance faible (ðŸ”´)
- Message d'avertissement pour confiance faible

## Tests E2E ValidÃ©s

### Kill Switch Global
```
âœ… PATCH /ai/global/settings {global_kill_switch: true}
   â†’ global_kill_switch_at: "2026-01-04T05:14:05.515Z"

âœ… POST /ai/evaluate (avec kill switch actif)
   â†’ status: "blocked"
   â†’ blocked_reason: "IA desactivee globalement: Test E2E"
   â†’ blocked_by: "global_kill_switch"
```

### Kill Switch Tenant
```
âœ… PATCH /ai/settings?tenantId=kbz-001 {kill_switch: true}
   â†’ kill_switch: true

âœ… POST /ai/evaluate (avec kill switch tenant)
   â†’ status: "blocked"
   â†’ blocked_reason: "IA desactivee pour ce compte"
   â†’ blocked_by: "tenant_kill_switch"
```

### Journal IA Audit
```
âœ… GET /ai/journal?tenantId=kbz-001&blocked=true
   â†’ 3 entrÃ©es bloquÃ©es avec:
     - blocked_reason
     - blocked_by
     - timestamp
     - conversation_id
```

### Frontends
```
âœ… admin-dev.keybuzz.io â†’ HTTP 200
âœ… client-dev.keybuzz.io â†’ HTTP 200
```

## Comportement des garde-fous

| Situation | RÃ©sultat |
|-----------|----------|
| Kill switch global ON | IA bloquÃ©e partout |
| Kill switch tenant ON | IA bloquÃ©e pour ce tenant |
| > 20 actions/heure | IA passe en mode suggestion |
| > 3 rÃ©ponses/conversation | IA passe en mode suggestion |
| > 2 actions consÃ©cutives | IA attend rÃ©ponse humaine |
| Confiance faible (ðŸ”´) | Bouton "Appliquer" dÃ©sactivÃ© |
| Erreurs consÃ©cutives | Auto-dÃ©sactivation |

## Messages UX (sans jargon technique)

- "KeyBuzz en pause" (panneau bloquÃ©)
- "IA dÃ©sactivÃ©e globalement"
- "IA dÃ©sactivÃ©e pour ce compte"
- "KeyBuzz attend une rÃ©ponse humaine"
- "Limite horaire atteinte (20 actions/heure)"
- "KeyBuzz vous propose une rÃ©ponse, mais n'agit plus automatiquement"
- "Confiance faible - KeyBuzz recommande une vÃ©rification humaine"

## Aucune rÃ©gression

- âœ… API /ai/settings fonctionne
- âœ… API /ai/evaluate fonctionne
- âœ… API /ai/execute fonctionne
- âœ… API /ai/journal fonctionne
- âœ… Admin UI accessible
- âœ… Client UI accessible

## Fichiers modifiÃ©s

### Backend
- `keybuzz-api/migrations/016_ai_guardrails.sql` (crÃ©Ã©)
- `keybuzz-api/src/modules/ai/routes.ts` (mis Ã  jour)

### Admin
- `keybuzz-admin/src/config/ai.service.ts` (mis Ã  jour)
- `keybuzz-admin/src/features/ai/components/AIDecisionPanel.tsx` (mis Ã  jour)

### Client
- `keybuzz-client/src/services/ai.service.ts` (mis Ã  jour)
- `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` (mis Ã  jour)

## Images Docker dÃ©ployÃ©es

| Image | Tag |
|-------|-----|
| keybuzz-api | v0.1.48-dev |
| keybuzz-admin | v0.1.54-dev |
| keybuzz-client | v0.2.8-dev |

## DEV Only - PROD untouched

Toutes les modifications sont en environnement DEV uniquement.

---

**PH11-PRODUCT-01C - TerminÃ©**

Date: 2026-01-04
