# PH-INBOUND-TRUTH-VERIFY-02 — Adresse Inbound Amazon ecomlg-001

**Date** : 2026-01-15  
**Statut** : ✅ VÉRIFIÉ ET FONCTIONNEL

---

## 📧 ADRESSE OFFICIELLE

```
amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
```

**Cette adresse est la SEULE valide pour ecomlg-001 / Amazon / FR**

---

## 1️⃣ PREUVE PAR LOGS MAIL

### Logs MX Server (mail-mx-01)

```
2026-01-15T16:53:46 to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io> status=sent
2026-01-15T16:53:55 to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io> status=sent
2026-01-15T16:55:16 to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io> status=sent
```

### Logs Mail-Core (webhook)

```
2026-01-15T17:13:16 INBOUND_RECEIVED 
  from=Ludovic [...]+2a7e7298-a90a-4ad6-962c-77ccae27280a@marketplace.amazon.fr 
  to=amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io 
  messageId=0102019bc293f249-ba1fd0f5-ace2-4140-9346-0087a76a5f36@eu-west-1.amazonses.com
```

---

## 2️⃣ PREUVE PAR WEBHOOK

### Emails traités avec succès

```json
{
  "success": true,
  "amazonForward": true,
  "conversation": {
    "conversationId": "cmmk6as67vd8c7e8551d3fdd3",
    "isNew": false,
    "isThreaded": true
  }
}
```

**3 emails Amazon reçus et traités :**

| MessageId | Résultat |
|-----------|----------|
| 0102019bc293f249-... | ✅ success, amazonForward: true |
| 0102019bc2952dde-... | ✅ success, amazonForward: true |
| 0102019bc293d0bf-... | ✅ success, amazonForward: true |

---

## 3️⃣ ÉTAT EN BASE DE DONNÉES

```sql
SELECT * FROM inbound_addresses WHERE "tenantId" = 'ecomlg-001';
```

| Champ | Valeur |
|-------|--------|
| id | addr_a8a7eead49c66f39c9cab21b4aee4cc7 |
| tenantId | ecomlg-001 |
| marketplace | amazon |
| country | FR |
| token | **3jcpvk** |
| emailAddress | **amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io** |
| pipelineStatus | **VALIDATED** |
| marketplaceStatus | **VALIDATED** |
| lastInboundAt | 2026-01-15 17:22:23.823 |

---

## 4️⃣ PROBLÈMES RÉSOLUS

### A) Adresse non existante en DB

**Avant** : Aucune adresse inbound n'était enregistrée pour ecomlg-001

**Après** : Adresse créée avec contrainte UNIQUE (tenantId, marketplace, country)

### B) Webhook échouait avec "Server configuration error"

**Cause** : `INBOUND_WEBHOOK_KEY` n'était pas configuré dans le backend

**Fix** : 
```bash
kubectl set env deployment/keybuzz-backend -n keybuzz-backend-dev \
  INBOUND_WEBHOOK_KEY=e867f60b660a66e6ac471312090d7a74e3840554e160c53393c529380252dea7
```

---

## 5️⃣ DÉCISION FINALE

| Ancienne adresse | Nouvelle adresse | Décision |
|------------------|------------------|----------|
| ❌ amazon.ecomlg-001.fr.cp2hat@... | ✅ amazon.ecomlg-001.fr.3jcpvk@... | **REGENERATE** |

**Note** : L'adresse `cp2hat` n'était pas enregistrée en DB. L'adresse `3jcpvk` est maintenant la seule adresse officielle.

---

## 6️⃣ INSTRUCTIONS POUR LUDOVIC

### Adresse à configurer dans Amazon Seller Central

```
amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
```

### Vérification

- ✅ Emails arrivent sur le serveur MX
- ✅ Webhook transmet au backend
- ✅ Backend crée les conversations
- ✅ Status VALIDATED en DB

### Preuve de fonctionnement

La conversation `cmmk6as67vd8c7e8551d3fdd3` a été mise à jour avec 3 nouveaux messages Amazon.

---

## 7️⃣ CONFIGURATION FINALE

### Backend keybuzz-backend-dev

```yaml
env:
  - name: INBOUND_WEBHOOK_KEY
    value: "e867f60b660a66e6ac471312090d7a74e3840554e160c53393c529380252dea7"
```

### Serveur Mail (mail-mx-01, mail-core-01)

- MX → relay vers mail-core
- mail-core → webhook vers backend-dev.keybuzz.io

---

## Conclusion

### ✅ ADRESSE VÉRIFIÉE ET FONCTIONNELLE

```
amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
```

- **Logs mail** : Emails reçus ✅
- **Webhook** : Fonctionnel ✅
- **DB** : Status VALIDATED ✅
- **Conversations** : Créées avec amazonForward: true ✅

**Cette adresse est la source de vérité unique pour ecomlg-001 / Amazon / FR.**
