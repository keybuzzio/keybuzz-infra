# PH-INBOUND-PIPELINE-TRUTH-04 — Correction Pipeline Inbound

> Date : 2026-03-27
> Type : correction critique — pipeline inbound
> Image : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph-inbound-pipeline-fix-dev`

---

## Verdict : INBOUND PIPELINE FIXED

Le pipeline inbound est maintenant fonctionnel de bout en bout :
- Email entrant → Postfix → Backend webhook → Conversation creee → **Autopilot declenche** → Action executee

---

## Probleme identifie

### Architecture du pipeline (avant correction)

```
Amazon → Email → Postfix (10.0.0.160) → postfix_webhook.sh
  → POST https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email
  → keybuzz-backend cree conversation + message en DB
  → FIN (pas d'appel autopilot)
```

Le hook autopilot (`evaluateAndExecute`) se trouve UNIQUEMENT dans l'API Fastify (`keybuzz-api`), dans les routes `/inbound/email` et `/inbound/amazon/forward`. Mais les messages arrivent via le **backend** (`keybuzz-backend`), pas via l'API. Les deux services sont distincts avec des bases de code separees.

### Cause racine #1 — Autopilot jamais declenche

Le backend cree les conversations dans la DB mais ne notifie jamais l'API pour evaluer l'autopilot. Le hook autopilot n'est jamais appele.

### Cause racine #2 — lastInboundAt jamais mis a jour (PH-04B)

Le code utilisait `MarketplaceType.AMAZON` (= `"AMAZON"`, majuscules) pour le WHERE clause Prisma, mais la DB stocke `marketplace = "amazon"` (minuscules). Le `updateMany` trouvait 0 lignes.

### Cause racine #3 — Mauvaise base de donnees (PH-04C)

Le code utilisait `prisma.inboundAddress.updateMany(...)` qui se connecte a la DB `keybuzz_backend`. Mais la table `inbound_addresses` est dans la DB `keybuzz` (product DB). Le query n'avait aucune ligne a mettre a jour car la table dans `keybuzz_backend` est vide pour ce tenant.

---

## Corrections appliquees

### Fix #1 — PH-INBOUND-PIPELINE-TRUTH-04 : Trigger autopilot

**Fichier** : `keybuzz-backend/src/modules/webhooks/inboundEmailWebhook.routes.ts`

Apres la creation de conversation par `createInboxConversation()`, un callback fire-and-forget est envoye a l'API :

```typescript
// PH-INBOUND-PIPELINE-TRUTH-04: Trigger autopilot evaluation (fire-and-forget)
if (conversationResult && conversationResult.conversationId) {
  const apiHost = process.env.API_INTERNAL_URL || "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001";
  fetch(`${apiHost}/autopilot/evaluate`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Tenant-Id": tenantId,
    },
    body: JSON.stringify({ conversationId: conversationResult.conversationId }),
  })
    .then(async (res) => {
      const body = await res.text();
      console.log(`[Webhook] Autopilot trigger: status=${res.status} conv=...`);
    })
    .catch((err) => console.error("[Webhook] Autopilot trigger error:", err.message));
}
```

L'API a deja un endpoint `POST /autopilot/evaluate` qui appelle `evaluateAndExecute(conversationId, tenantId, 'manual')`.

### Fix #2 — PH-04B : Marketplace case mismatch

```typescript
// Avant (bug) :
marketplace: MarketplaceType.AMAZON,  // "AMAZON" ← ne matche pas "amazon" en DB

// Apres (fix) :
marketplace: marketplace,  // PH-04B-FIX: utilise la valeur parsee (minuscules)
```

### Fix #3 — PH-04C : Mauvaise base de donnees

```typescript
// Avant (bug) : utilise prisma (keybuzz_backend DB — 0 lignes)
await prisma.inboundAddress.updateMany({ ... });

// Apres (fix) : utilise productDb (keybuzz DB — table reelle)
const updateResult = await productDb.query(
  `UPDATE inbound_addresses SET "lastInboundAt" = $1, "lastInboundMessageId" = $2, "pipelineStatus" = 'VALIDATED'
   WHERE "tenantId" = $3 AND marketplace = $4 AND country = $5`,
  [new Date(), payload.messageId, tenantId, marketplace, country]
);
```

### Env var ajoutee

`API_INTERNAL_URL=http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001` ajoute au deployment `keybuzz-backend` dans `keybuzz-backend-dev`.

---

## Validation

### Test : envoi webhook simule

```
POST https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email
To: amazon.srv-performance-mn7ds3oj.fr.79bebe@inbound.keybuzz.io
```

### Resultats

| Checkpoint | Statut | Detail |
|---|---|---|
| Webhook accepte | ✓ | HTTP 200, conversation threadee |
| ExternalMessage cree | ✓ | `cm642437175bc5d03353193e` |
| InboundAddress.lastInboundAt mis a jour | ✓ | `2026-03-27T12:39:59.977Z` (FR) |
| lastInboundMessageId mis a jour | ✓ | `test-pipeline-fix-1774615199@keybuzz.io` |
| Autopilot trigger envoye | ✓ | `POST /autopilot/evaluate` vu dans logs API |
| Autopilot execute | ✓ | `executed=true, action=status_change, confidence=1` |
| KBActions debites | ✓ | `6.87 KBA` |
| ai_action_log enregistre | ✓ | `autopilot_status_change, status=completed` |

### Logs backend confirmant le pipeline complet

```
[Webhook] Amazon forward detected, marketplaceStatus updated for srv-performance-mn7ds3oj/FR
[Webhook] ExternalMessage created: cm642437175bc5d03353193e
[Webhook] InboundAddress updated: 1 rows (tenant=srv-performance-mn7ds3oj, country=FR)
[Webhook] Inbox conversation created: { conversationId: 'cmmn8vp94l333732313581005', ... }
[Webhook] Autopilot trigger: status=200 conv=cmmn8vp94l333732313581005
  body={"executed":true,"action":"status_change","reason":"EXECUTED","confidence":1,...}
```

### Logs API confirmant la reception

```
[Autopilot] srv-performance-mn7ds3oj conv=cmmn8vp94l333732313581005
  action=status_change executed=true confidence=1 elapsed=3225ms
```

---

## Architecture corrigee

```
Amazon → Email → Postfix (10.0.0.160) → postfix_webhook.sh
  → POST https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email
  → keybuzz-backend :
      1. Parse recipient (tenantId, marketplace, country)
      2. Cree ExternalMessage (dedup)
      3. Met a jour InboundAddress.lastInboundAt  ← FIX PH-04C (productDb)
      4. Cree Conversation + Message via createInboxConversation()
      5. Envoie callback autopilot                ← FIX PH-04 (fire-and-forget)
           → POST http://keybuzz-api:3001/autopilot/evaluate
  → keybuzz-api :
      6. evaluateAndExecute(conversationId, tenantId, 'manual')
      7. AI suggestion → action → execution
      8. Log dans ai_action_log
```

---

## Deploiement

| Element | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph-inbound-pipeline-fix-dev` |
| Pod | `keybuzz-backend-868566b57f-llq5c` |
| Namespace | `keybuzz-backend-dev` |
| Status | Running, 0 restarts |
| Env var ajoutee | `API_INTERNAL_URL` |

---

## Ce qui n'a PAS ete touche

- Autopilot engine (`evaluateAndExecute`) : inchange
- Routes API `/inbound/*` : inchangees
- UI / Client : inchange
- Billing / KBActions : inchange
- Postfix / mail server : inchange
- Schema DB : inchange

---

## Notes pour PROD

Pour deployer en PROD :

1. Modifier `API_INTERNAL_URL` :
   ```
   http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80
   ```

2. Builder avec tag PROD :
   ```
   v1.0.41-ph-inbound-pipeline-fix-prod
   ```

3. Deployer dans `keybuzz-backend-prod`
