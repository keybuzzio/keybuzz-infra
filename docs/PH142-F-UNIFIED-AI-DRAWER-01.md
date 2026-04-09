# PH142-F — Unified AI Drawer

> Date : 1 mars 2026
> Phase : PH142-F-UNIFIED-AI-DRAWER-01
> Statut : DEV + PROD deployes

---

## Objectif

Remplacer le `AutopilotDraftBanner` (PH142-E) par un systeme unifie integre dans le volet droit "Aide IA" (`AISuggestionSlideOver`), supprimant la duplication d'interfaces et offrant une UX coherente.

## Avant / Apres

| Aspect | Avant (PH142-E) | Apres (PH142-F) |
|--------|------------------|------------------|
| Affichage draft | Banner inline au-dessus du textarea | Drawer lateral droit "Aide IA" |
| Composants | AutopilotDraftBanner + AISuggestionSlideOver (2 composants) | AISuggestionSlideOver unifie (1 seul) |
| Ouverture | Toujours visible si draft present | Auto-ouverture du drawer quand draft existe |
| Fermeture | Dismiss banner | Ferme le drawer, ne reouvre pas automatiquement |
| Generation IA manuelle | Bouton separe "Aide IA" | Meme drawer, option "Generer une nouvelle suggestion" |

## Modifications

### AISuggestionSlideOver.tsx

- Ajout interface exportee `AutopilotDraft` (draftText, confidence, escalation, needsHumanAction)
- Nouvelles props : `initialDraft`, `autoOpen`, `onDirectSend`
- Etat interne `activeDraft` + `draftDismissedRef` (ne reouvre pas si dismiss)
- Effets auto-open : quand initialDraft arrive et non dismiss → ouvre le drawer
- Reset dismissed ref quand la conversation change
- Block d'affichage draft : confiance, escalade, warning, texte, boutons
- Boutons : "Valider et envoyer", "Modifier", "Ignorer"
- Option "Generer une nouvelle suggestion" pour passer au mode suggestion classique
- Header adaptatif : icone Bot + titre "Brouillon IA" en mode draft vs icone Sparkles + "Suggestion IA" en mode normal

### InboxTripane.tsx

- Import `AutopilotDraft` type depuis AISuggestionSlideOver
- Suppression import et rendu de `AutopilotDraftBanner`
- Ajout etat `autopilotDraft` + effect fetch vers `/api/autopilot/draft`
- Passage des props `initialDraft`, `autoOpen`, `onDirectSend` au drawer
- Conservation de `sendAutopilotDraft` pour envoi direct valide

### UX : Non-intrusif

- Si l'utilisateur ferme le drawer → `draftDismissedRef` enregistre le conversationId
- Le drawer ne se reouvre PAS automatiquement pour cette conversation
- Changement de conversation → reset du ref
- La lecture de la conversation n'est jamais bloquee

## Tests DEV

| Test | Resultat |
|------|----------|
| Draft endpoint `/autopilot/draft` | 200 OK |
| AI settings | 200 OK |
| AI journal (PH142-A) | 200 OK |
| Error clusters (PH142-B) | 200 OK |
| Health client-dev | 200 OK |
| Health api-dev | 200 OK |

## Images deployees

| Service | Env | Image |
|---------|-----|-------|
| Client | DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.188-ai-drawer-unified-dev` |
| Client | PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.188-ai-drawer-unified-prod` |
| API | DEV | inchangee (`v3.5.187-autopilot-safe-mode-fix-dev`) |
| API | PROD | inchangee (`v3.5.187-autopilot-safe-mode-fix-prod`) |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.187-autopilot-safe-mode-fix-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.187-autopilot-safe-mode-fix-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

## Non-regression

- PH142-A (Quality Loop) : OK
- PH142-B (Error Clustering) : OK
- PH142-C (Action Consistency) : OK
- PH142-D (Auto Escalation) : OK
- PH142-E (Safe Mode) : remplace par PH142-F (backward compatible)
- Autopilot non-securise : inchange (pas de draft → drawer normal)
- Billing : non touche
- Multi-tenant : strict (tenantId dans toutes les requetes)
