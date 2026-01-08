# PH15-INBOUND-TO-CONVERSATION-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Les emails Amazon inbound créent maintenant automatiquement des conversations et messages dans l'Inbox KeyBuzz.

**Flux complet** :
```
Email Amazon → Postfix → Webhook backend-dev → ExternalMessage (keybuzz_backend)
                                              → Conversation + Message (keybuzz product)
```

---

## 1. Handler Webhook Modifié

**Fichier** : `keybuzz-backend/src/modules/webhooks/inboundEmailWebhook.routes.ts`

**Modification** : Ajout de l'appel à `createInboxConversation()` après création de l'ExternalMessage.

```typescript
// PH15: Create Inbox conversation + message (product DB)
const conversationResult = await createInboxConversation({
  tenantId,
  marketplace: 'amazon',
  from: payload.from,
  subject: payload.subject || 'Message Amazon',
  body: payload.body || '',
  messageId: payload.messageId,
  receivedAt: new Date(payload.receivedAt),
});
```

---

## 2. Nouveau Service

**Fichier** : `keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts`

**Fonctionnalités** :
- Connexion à DB product (`keybuzz`) via `productDb.ts`
- Extraction automatique de l'orderRef (formats Amazon)
- Extraction du nom client depuis le champ `from`
- Création idempotente (check messageId existant)
- Création conversation si inexistante
- Création message inbound
- Mise à jour stats conversation (last_message_preview, last_inbound_at, messages_24h)
- Calcul SLA (24h)

---

## 3. Tables Touchées

### DB `keybuzz` (product)

| Table | Action |
|-------|--------|
| `conversations` | INSERT (nouvelle conversation) ou UPDATE (ajout message) |
| `messages` | INSERT (message inbound) |

### DB `keybuzz_backend` (marketplace)

| Table | Action |
|-------|--------|
| `ExternalMessage` | INSERT (email brut) |
| `InboundAddress` | UPDATE (lastInboundAt) |

---

## 4. Idempotency

- **ExternalMessage** : Clé unique `(type, connectionId, externalId)` via Prisma
- **Messages** : Check SQL sur `messageId` avant INSERT
- Si déjà traité → retourne `{ success: true, message: "Already processed" }`

---

## 5. Preuves E2E

### Requête Test

```bash
curl -X POST https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email \
  -H "Content-Type: application/json" \
  -H "X-Internal-Key: ***" \
  -d '{
    "from": "TestClient3 test3+amazon@marketplace.amazon.fr",
    "to": "amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io",
    "subject": "Question sur commande 111-2222222-3333333",
    "messageId": "test-conv-003@eu-west-1.amazonses.com",
    "receivedAt": "2026-01-08T19:05:00+00:00",
    "body": "Bonjour, je souhaite savoir quand ma commande sera livrée."
  }'
```

### Réponse

```json
{
  "success": true,
  "messageId": "cmk5t9gen00027k01mimteqgt",
  "externalId": "test-conv-003@eu-west-1.amazonses.com",
  "amazonForward": true,
  "conversation": {
    "conversationId": "cmmk5t9gg086d3a9ebe0edf2a",
    "messageId": "cmmk5t9gg7fc8511f49f78b6b",
    "isNew": true
  }
}
```

### Vérification DB (keybuzz product)

```sql
-- Conversation créée
SELECT id, tenant_id, subject, channel, status, customer_name, created_at
FROM conversations WHERE tenant_id = 'tenant_test_dev';

            id             |    tenant_id    |                  subject                  | channel | status |      customer_name       
---------------------------+-----------------+-------------------------------------------+---------+--------+--------------------------
 cmmk5t9gg086d3a9ebe0edf2a | tenant_test_dev | Question sur commande 111-2222222-3333333 | amazon  | open   | TestClient3 test3+amazon

-- Message créé
SELECT id, conversation_id, direction, author_name, created_at
FROM messages WHERE tenant_id = 'tenant_test_dev';

            id             |      conversation_id      | direction |       author_name        
---------------------------+---------------------------+-----------+--------------------------
 cmmk5t9gg7fc8511f49f78b6b | cmmk5t9gg086d3a9ebe0edf2a | inbound   | TestClient3 test3+amazon
```

---

## 6. Prérequis Tenant

**Important** : Le tenantId doit exister dans les DEUX bases de données :
- `keybuzz_backend.Tenant` (pour les connexions marketplace)
- `keybuzz.tenants` (pour les conversations Inbox)

**Action effectuée** :
```sql
INSERT INTO tenants (id, name, plan, status, created_at, updated_at)
VALUES ('tenant_test_dev', 'Test Tenant DEV', 'pro', 'active', NOW(), NOW());
```

---

## 7. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-backend | v1.0.4-dev |
| Image Docker | ghcr.io/keybuzzio/keybuzz-backend:v1.0.4-dev |
| Commit | 42702fb |

---

## 8. Fichiers Modifiés

| Fichier | Action |
|---------|--------|
| `src/lib/productDb.ts` | CRÉÉ - Connexion DB product |
| `src/modules/webhooks/inboxConversation.service.ts` | CRÉÉ - Service création conversation |
| `src/modules/webhooks/inboundEmailWebhook.routes.ts` | MODIFIÉ - Appel service |
| `package.json` | MODIFIÉ - Version 1.0.4 |

---

## 9. Comportement Attendu

1. **Email Amazon arrive** → Postfix le reçoit
2. **postfix_webhook.sh** → Parse et POST vers backend-dev
3. **Backend** :
   - Authentifie via X-Internal-Key
   - Parse destinataire (tenantId, marketplace, country)
   - Vérifie email validation (si KeyBuzz Validation)
   - Met à jour marketplaceStatus si Amazon forward
   - Crée ExternalMessage (idempotent)
   - Met à jour InboundAddress.lastInboundAt
   - **NOUVEAU** : Crée Conversation + Message dans DB product
4. **Inbox UI** → Affiche la nouvelle conversation

---

## 10. Limitations Connues

| Limitation | Impact |
|------------|--------|
| Body limité à 10KB par postfix_webhook.sh | Gros emails tronqués |
| Pas de pièces jointes | Images/PDFs non gérés |
| SLA fixé à 24h | Pas de personnalisation par tenant |
| Pas de threading | Chaque email = nouvelle conversation si orderRef différent |

---

**Fin du rapport PH15-INBOUND-TO-CONVERSATION-01**
