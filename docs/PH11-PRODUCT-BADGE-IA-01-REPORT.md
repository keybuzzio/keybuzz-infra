# PH11-PRODUCT-BADGE-IA-01 â€” Rapport Final

## RÃ©sumÃ©

**Status:** âœ… RÃ‰SOLU
**Date:** 2026-01-04

## Cause Racine

L'API ne retournait pas les champs `visibility` et `message_source` dans les messages.

**Raison technique:**
1. Le code source Ã©tait correct (SELECT incluait ces colonnes)
2. La DB avait les donnÃ©es correctes
3. **MAIS** : L'image Docker sur GHCR Ã©tait en cache avec une ancienne version
4. Les tags Docker (v0.1.47-dev, v0.1.48-dev) Ã©taient dÃ©jÃ  utilisÃ©s avec des anciennes images
5. Kubernetes pullait les anciennes images mises en cache

**Solution:**
1. Rebuild avec un nouveau tag unique (v0.1.49-dev)
2. Push vers GHCR
3. Rollout avec le nouveau tag

## Preuves

### Avant le fix (API ne retourne pas les champs)

```json
{
  "id": "msg-001",
  "conversation_id": "conv-001",
  "direction": "inbound",
  "author_name": "Marie Dubois",
  "body": "...",
  "created_at": "...",
  "attachments": []
}
```

**Champs manquants:** visibility, message_source

### AprÃ¨s le fix (API retourne les champs)

```json
{
  "id": "msg-001",
  "conversation_id": "conv-001",
  "direction": "inbound",
  "visibility": "public",
  "message_source": "HUMAN",
  "author_name": "Marie Dubois",
  "body": "...",
  "created_at": "...",
  "attachments": []
}
```

### DB (source de vÃ©ritÃ©)

```sql
SELECT message_source, COUNT(*) FROM messages GROUP BY 1;
-- HUMAN: 95 messages
-- (Pas de AI car aucune action IA n'a Ã©tÃ© exÃ©cutÃ©e)
```

## Ã‰tat Actuel des Badges

| message_source | Nombre | Badge UI attendu |
|----------------|--------|------------------|
| HUMAN | 95 | ðŸ‘¤ Humain |
| AI | 0 | ðŸ¤– KeyBuzz IA |
| SYSTEM | 0 | âš™ï¸ SystÃ¨me |
| TEMPLATE | 0 | ðŸ“„ Template |

**Conclusion:** Tous les messages sont HUMAN, donc pas de badge IA visible â€” **c'est NORMAL**.

## Mapping UI (dÃ©jÃ  correct)

```typescript
// keybuzz-client/src/services/conversations.service.ts:120
authorType: m.message_source === 'AI' ? 'ai' : 
           (m.message_source === 'SYSTEM' ? 'system' : 
           (m.author_type || m.authorType || 
           (m.direction === 'inbound' ? 'customer' : 'agent')))
```

## Commits

| Repo | Commit | Description |
|------|--------|-------------|
| keybuzz-infra | 8cf338c | API v0.1.49-dev force new image |
| keybuzz-infra | 9909c17 | API v0.1.48-dev fix visibility+message_source |
| keybuzz-infra | db8c4dc | API v0.1.47-dev avec visibility + message_source |

## Versions DÃ©ployÃ©es

| Service | Version | Digest |
|---------|---------|--------|
| keybuzz-api | v0.1.49-dev | sha256:1f318b0ece77... |
| keybuzz-client | v0.2.14-dev | sha256:ab9efea8... |
| keybuzz-admin | v1.0.55-dev | sha256:d1a6eba3... |

## Prochaines Ã‰tapes

Pour voir un badge IA:
1. ExÃ©cuter une action IA via POST /ai/execute
2. Le message crÃ©Ã© aura message_source='AI'
3. L'UI affichera le badge ðŸ¤–

## Contraintes RespectÃ©es

- âœ… DEV ONLY (PROD intact)
- âœ… GitOps (commits dans keybuzz-infra)
- âœ… Pas de donnÃ©es demo modifiÃ©es
- âœ… Pas de hack UI

---

**PH11-PRODUCT-BADGE-IA-01 â€” TERMINÃ‰**
