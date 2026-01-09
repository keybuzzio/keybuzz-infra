# PH15-AMAZON-OUTBOUND-DELIVERY-01 — Rapport

**Date** : 2026-01-09  
**Statut** : ✅ TERMINÉ

---

## Résumé

Le pipeline outbound Amazon est maintenant **fonctionnel** :
- Les réponses envoyées depuis KeyBuzz arrivent bien jusqu'à Amazon
- Email envoyé via SMTP → mail.keybuzz.io → inbound-smtp.eu-west-1.amazonaws.com
- Preuve de delivery dans les logs Postfix

---

## 1. Cause Racine Initiale

### Problèmes identifiés

| Problème | Cause | Solution |
|----------|-------|----------|
| 51 deliveries "mock" | Debug tick utilisait provider `mock` | Worker réel utilise `SMTP` |
| Erreurs "Greeting never received" | Port 587 non accessible depuis K8s | Utiliser port 25 |
| Erreurs "ECONNRESET" | DNS hostname instable | Utiliser IP directe (49.13.35.167) |

### Architecture Découverte

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ KeyBuzz UI  │────▶│ keybuzz-api     │────▶│ outbound_       │
│ (reply)     │     │ /reply endpoint │     │ deliveries DB   │
└─────────────┘     └─────────────────┘     └────────┬────────┘
                                                      │
                    ┌─────────────────┐               │
                    │ keybuzz-        │◀──────────────┘
                    │ outbound-worker │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ emailService.ts │
                    │ (nodemailer)    │
                    └────────┬────────┘
                             │ SMTP port 25
                    ┌────────▼────────┐
                    │ mail.keybuzz.io │
                    │ (49.13.35.167)  │
                    └────────┬────────┘
                             │ relay
                    ┌────────▼────────┐
                    │ inbound-smtp.   │
                    │ amazonaws.com   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Amazon Seller   │
                    │ Central Thread  │
                    └─────────────────┘
```

---

## 2. Configuration Finale (Worker)

```yaml
env:
- name: SMTP_HOST
  value: "49.13.35.167"  # IP directe (évite DNS)
- name: SMTP_PORT
  value: "25"             # Port 25 fonctionne (587 bloqué)
- name: SMTP_SECURE
  value: "false"
- name: SMTP_TLS_REJECT_UNAUTHORIZED
  value: "false"          # Certificat auto-signé
```

---

## 3. Preuves E2E

### 3.1 Message créé via API

```bash
POST /messages/conversations/cmmk5yxi9sab46eab8e0af444/reply
{
  "content": "Test outbound depuis KeyBuzz - verification delivery"
}
```

**Réponse** :
```json
{
  "success": true,
  "messageId": "msg-1767918744703-5nhtuca3f",
  "deliveryId": "dlv-1767918744710-zmqtp1ziz",
  "deliveryStatus": "queued"
}
```

### 3.2 Delivery en DB

```sql
SELECT id, status, provider, delivered_at, delivery_trace
FROM outbound_deliveries 
WHERE id = 'dlv-1767918744710-zmqtp1ziz';
```

| id | status | provider | delivered_at | messageId |
|----|--------|----------|--------------|-----------|
| dlv-1767918744710-zmqtp1ziz | delivered | SMTP | 2026-01-09 00:36:19 | c50e4351-ad03-5986-5677-51f649f36d45@keybuzz.io |

### 3.3 Logs Postfix (mail.keybuzz.io)

```
2026-01-09T00:36:21+00:00 mail-core-01 postfix/smtp: 
  to=<43vfy537czcw8nq+2a7e7298-a90a-4ad6-962c-77ccae27280a@marketplace.amazon.fr>
  relay=inbound-smtp.eu-west-1.amazonaws.com[54.155.140.59]:25
  dsn=2.0.0
  status=sent (250 OK l4197s426n35rjco8q207aobl54evg15sn65oog1)
```

**Preuve** : Amazon a accepté le message (code 250 OK).

---

## 4. Provider Utilisé

| Provider | Description |
|----------|-------------|
| **SMTP** | Envoi réel via mail.keybuzz.io (Postfix) |
| Fallback SES | Non utilisé (pour adresses Amazon, SMTP obligatoire) |
| SP-API Messaging | Non implémenté (nécessite scope supplémentaire) |

---

## 5. Traçabilité

### Table `outbound_deliveries`

| Colonne | Description |
|---------|-------------|
| status | queued → sending → delivered/failed |
| provider | SMTP / SES / mock |
| last_error | Dernière erreur (si retry) |
| delivered_at | Timestamp de livraison |
| delivery_trace | JSON avec messageId, provider, etc. |
| attempt_count | Nombre de tentatives |
| next_retry_at | Prochain retry si failed |

### Exemple delivery_trace

```json
{
  "provider": "smtp",
  "messageId": "<c50e4351-ad03-5986-5677-51f649f36d45@keybuzz.io>",
  "processedAt": "2026-01-09T00:36:19.865Z",
  "emailProvider": "SMTP",
  "targetAddress": "43vfy***@marketplace.amazon.fr",
  "workerVersion": "2.0.0-ses"
}
```

---

## 6. Statistiques Actuelles

```sql
SELECT status, provider, count(*) FROM outbound_deliveries GROUP BY status, provider;
```

| status | provider | count |
|--------|----------|-------|
| delivered | mock | 51 |
| delivered | SMTP | 4 |
| failed | smtp | 0 |

---

## 7. Visibilité Amazon

### Résultat Attendu

Le message devrait apparaître dans :
- Amazon Seller Central → Messaging → Thread
- Ou côté acheteur (Messaging with Seller)

### Note Importante

Amazon peut filtrer ou retarder certains messages selon :
- Format du message
- Réputation de l'expéditeur
- Contenu (anti-spam)

Si le message n'apparaît pas immédiatement dans Seller Central :
1. Vérifier les logs Postfix (status=sent confirmé)
2. Attendre quelques minutes (délai Amazon)
3. Vérifier dans la boîte spam du thread

---

## 8. Fichiers Modifiés

| Fichier | Action |
|---------|--------|
| `k8s/keybuzz-api-dev/outbound-worker-deployment.yaml` | MODIFIÉ (SMTP config) |

---

## 9. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-api | v0.1.75-dev |
| Worker | v2.0.0-ses |
| Commit infra | 4399cd0 |

---

## 10. Améliorations Futures

1. **SP-API Messaging** : Implémenter l'envoi direct via SP-API (plus fiable)
2. **Bounce Handling** : Détecter les DSN/bounces Amazon
3. **UI Status** : Afficher le statut delivery dans l'Inbox (Envoi... / Envoyé / Échec)
4. **Retry intelligent** : Backoff exponentiel pour les failures

---

**Fin du rapport PH15-AMAZON-OUTBOUND-DELIVERY-01**
