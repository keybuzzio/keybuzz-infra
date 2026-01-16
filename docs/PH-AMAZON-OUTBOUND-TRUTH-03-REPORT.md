# PH-AMAZON-OUTBOUND-TRUTH-03 — Outbound Amazon visible Seller Central

**Date** : 2026-01-16  
**Statut** : ✅ **SUCCÈS COMPLET**  
**Worker** : v4.1.0-from-fix (image v0.1.105-dev)

---

## 🎯 Objectif

Rendre les messages outbound Amazon (sans commande) visibles dans Seller Central, pas seulement acceptés par Postfix (250 OK).

---

## 🔍 Diagnostic

### Problème initial

| Élément | Valeur | Résultat |
|---------|--------|----------|
| From address | `noreply@keybuzz.io` | ❌ Non visible Seller Central |
| DKIM | ✅ Signé (keybuzz.io) | Accepté |
| Postfix | 250 OK | Accepté |

### Cause identifiée

Amazon exige que le vendeur réponde depuis **l'adresse email autorisée** dans son compte Seller Central.

Le message Amazon inbound contient :
> "Lorsque vous répondez à ce message, Amazon.fr **remplace votre adresse électronique** par une adresse fournie par Amazon.fr"

L'adresse `noreply@keybuzz.io` n'était pas reconnue par Amazon comme appartenant au vendeur.

---

## ✅ Solution implémentée

### 1. Modification du worker (`outboundWorker.ts`)

Ajout de la fonction `getInboundAddressForTenant()` qui récupère l'adresse inbound générée :

```typescript
async function getInboundAddressForTenant(client: PoolClient, tenantId: string): Promise<string | null> {
    const result = await client.query(
        `SELECT "emailAddress" FROM inbound_addresses 
         WHERE "tenantId" = $1 AND marketplace = 'amazon' AND "validationStatus" = 'VALIDATED'
         ORDER BY "updatedAt" DESC LIMIT 1`,
        [tenantId]
    );
    return result.rows.length > 0 ? result.rows[0].emailAddress : null;
}
```

### 2. Utilisation dans l'envoi SMTP

```typescript
const inboundFromAddress = await getInboundAddressForTenant(client, delivery.tenant_id);
const emailResult = await sendEmail({
    to: customerHandle,
    from: inboundFromAddress || undefined,  // ← Adresse inbound comme From
    subject: emailSubject,
    text: messageBody,
    // ...
});
```

---

## 📊 Preuves

### Message de test

- **Contenu** : `TEST FROM-FIX v4.1.0 - 1768601150`
- **Conversation** : `cmmkfq1qp83d5d8146f80a1c2`
- **Delivery ID** : `dlv-1768597549189-wgwvunr41`

### Logs Worker

```
[Worker] Using From address: amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
[EmailService] SMTP sending to ...@marketplace.amazon.fr from amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
[Worker] dlv-1768597549189-wgwvunr41 delivered via SMTP_AMAZON_NONORDER
```

### Logs Postfix

```
2026-01-16T21:05:52 opendkim: C4406402DD: DKIM-Signature field added (s=kbz1, d=inbound.keybuzz.io)
2026-01-16T21:05:52 postfix/qmgr: C4406402DD: from=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io>, size=859, nrcpt=1
2026-01-16T21:05:54 postfix/smtp: C4406402DD: to=<43vfy...@marketplace.amazon.fr>, 
    relay=inbound-smtp.eu-west-1.amazonaws.com,
    dsn=2.0.0, status=sent (250 OK 0bj6h9o5vlt5t6hug8b40eo1q4o9fk5ql6gj23o1)
```

### Confirmation Ludovic

> "J'ai bien reçu 'TEST FROM-FIX v4.1.0 - 1768601150' sur mon interface Amazon"

**✅ Message visible dans Amazon Seller Central !**

---

## 📈 Comparaison Avant/Après

| Élément | Avant (v4.0.1) | Après (v4.1.0) |
|---------|----------------|----------------|
| **From address** | `noreply@keybuzz.io` | `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` |
| **DKIM domain** | `keybuzz.io` | `inbound.keybuzz.io` |
| **Postfix status** | 250 OK | 250 OK |
| **Visible Seller Central** | ❌ Non | ✅ Oui |

---

## 🔧 Déploiement

| Composant | Version |
|-----------|---------|
| Worker | v4.1.0-from-fix |
| Image Docker | `ghcr.io/keybuzzio/keybuzz-api:v0.1.105-dev` |
| GitOps | `keybuzz-infra/k8s/keybuzz-api-dev/outbound-worker-deployment.yaml` |

---

## 📋 Checklist finale

- [x] Adresse From = adresse inbound générée du tenant
- [x] DKIM signé pour `inbound.keybuzz.io`
- [x] Postfix 250 OK
- [x] Message visible dans Amazon Seller Central
- [x] Worker v4.1.0-from-fix déployé
- [x] GitOps mis à jour

---

## 🎯 Impact

### Pour les clients KeyBuzz

- Les réponses envoyées via KeyBuzz sont **désormais visibles** dans Amazon Seller Central
- Le client n'a rien à configurer de plus - l'adresse inbound générée est automatiquement utilisée
- Fonctionne pour toutes les conversations Amazon sans commande

### Logique finale

1. Client configure son adresse inbound KeyBuzz dans Amazon Seller Central
2. Amazon envoie les messages à cette adresse
3. KeyBuzz répond **depuis cette même adresse**
4. Amazon reconnaît l'expéditeur et affiche le message

---

## ✅ VERDICT FINAL

**🟢 OUTBOUND AMAZON VISIBLE SELLER CENTRAL — VALIDÉ**

Le fix `v4.1.0-from-fix` résout définitivement le problème de visibilité des réponses Amazon.
