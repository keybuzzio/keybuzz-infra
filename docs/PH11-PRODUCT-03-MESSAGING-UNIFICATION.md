# PH11-PRODUCT-03 - Messaging Unification (Client + Admin)

## Resume

Finalisation et unification du coeur du messaging entre Client UI et Admin UI.

**Objectif:** Un agent support et un client voient le meme ecran avec les memes reperes visuels.

## Modifications implementees

### 1. Notes internes - Position et Labels

| Interface | Position | Label |
|-----------|----------|-------|
| Client UI | Droite (justify-end) | "Vous - Note interne" |
| Admin UI | Droite (justify-end) | "Agent - Note interne" |

**Regles:**
- Une note interne n'est JAMAIS visible cote client final
- TOUJOURS rendue comme INTERNAL_NOTE
- Garde sa couleur, position et badge apres reload
- Ne change JAMAIS de type

### 2. Message Source & Badges

**Source unique de verite:**
```typescript
message_type      // INBOUND | OUTBOUND | INTERNAL_NOTE
message_source    // HUMAN | AI | SYSTEM | TEMPLATE  
visibility        // public | internal_note
```

**Badges identiques Client & Admin:**
| Source | Badge |
|--------|-------|
| Reponse humaine | ðŸ‘¤ |
| Reponse IA | ðŸ¤– |
| Regle automatique | ðŸ“„ |
| Modele de reponse | ðŸ“˜ |
| Action systeme | âš™ï¸ |

### 3. Zone de saisie - UX

**Comportement clavier:**
- `Enter` â†’ Envoyer le message
- `Shift + Enter` â†’ Saut de ligne

**Textarea:**
- Auto-grow vertical (Client UI)
- Min 40px, max 120px
- Texte wrap, pas de scroll horizontal

### 4. Auto-scroll

**Apres:**
- Envoi d'une reponse
- Envoi d'une note interne
- Action IA executee

â†’ **Auto-scroll TOUJOURS vers le dernier message**

### 5. Tri-pane unifie

| Pane | Contenu |
|------|---------|
| Gauche | Filtres (statut, canal, fournisseur, non-lu) |
| Centre | Liste conversations |
| Droite | Detail conversation |

**Meme structure Client & Admin.**

## Tests E2E

### Test 1: Creation note interne
```
POST /messages/conversations/conv-001/reply
{"content":"Test E2E PH11-03","visibility":"internal"}
â†’ âœ… Note created: msg-1767531227500-4vixqm3ia
```

### Test 2: Verification persistance
```
GET /messages/conversations/conv-001
â†’ âœ… visibility: internal_note
â†’ âœ… message_source: HUMAN
â†’ âœ… direction: internal_note
```

### Test 3: Frontends accessibles
```
âœ… Client UI: HTTP 200
âœ… Admin UI: HTTP 200
```

## Fichiers modifies

### Client UI (keybuzz-client)
| Fichier | Modifications |
|---------|---------------|
| `app/inbox/InboxTripane.tsx` | Position notes (justify-end), labels "Vous", textarea auto-grow, auto-scroll |

### Admin UI (keybuzz-admin)
| Fichier | Modifications |
|---------|---------------|
| `src/features/messages/components/ConversationActionsOptimistic.tsx` | Enter to send, hint updated |
| `src/features/messages/components/MessageBubble.tsx` | Notes on right, label "Agent - Note interne" |

## Images Docker deployees

| Service | Version |
|---------|---------|
| keybuzz-api | v0.1.49-dev |
| keybuzz-client | v0.2.11-dev |
| keybuzz-admin | v0.1.56-dev |

## Commits Git

```
keybuzz-client: b585fda - PH11-PRODUCT-03: Messaging unification - labels, position, scroll, textarea
keybuzz-admin:  445afbc - PH11-PRODUCT-03: Messaging unification - Enter to send, note position, labels
```

## Checklist de validation

- [x] Une note reste une note pour toujours
- [x] Client et admin voient la meme logique
- [x] Aucun badge errone
- [x] UX fluide, claire, sans surprise
- [x] Code documente + rapport livre

## Ce qui N'a PAS ete fait (hors scope)

- âŒ Nouvelles features metier
- âŒ Hacks temporaires
- âŒ TODOs laisses
- âŒ Fallbacks silencieux

---

**PH11-PRODUCT-03 - Termine**

Date: 2026-01-04
