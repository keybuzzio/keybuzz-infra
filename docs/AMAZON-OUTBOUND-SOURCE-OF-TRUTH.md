# AMAZON OUTBOUND — SOURCE DE VÉRITÉ

**Date de création** : 2026-01-16  
**Dernière mise à jour** : 2026-01-16  
**Statut** : 🔒 **VERROUILLÉ** — Toute modification requiert un test de non-régression

---

## 📋 Résumé Exécutif

Ce document définit la **logique officielle KeyBuzz** pour l'envoi de messages vers Amazon.
Il est la **source de vérité** et doit être consulté en cas de doute ou de régression.

---

## 🔒 Logique Officielle KeyBuzz

### Règle 1: Amazon AVEC commande → SP-API

```
SI conversation.channel === "amazon"
ET conversation.order_ref IS NOT NULL
ET conversation.order_ref !== ""
ALORS provider = SPAPI_ORDER
```

**Comportement** :
- Utilise Amazon SP-API Messaging
- Envoie directement dans le thread Amazon lié à la commande
- **Fallback autorisé** : Si SP-API échoue, on peut essayer SMTP

### Règle 2: Amazon SANS commande → SMTP Relay

```
SI conversation.channel === "amazon"
ET conversation.order_ref IS NULL
ET conversation.customer_handle CONTAINS "@marketplace.amazon"
ALORS provider = SMTP_AMAZON_NONORDER
```

**Comportement** :
- Utilise SMTP via mail.keybuzz.io (Postfix)
- Envoie à l'adresse relay Amazon (ex: `43vfy...@marketplace.amazon.fr`)
- Amazon route le message vers le bon thread
- **C'est NORMAL et LÉGITIME** (eDesk/Zendesk font pareil)

### Règle 3: Fallback générique → SMTP

```
SI conversation.channel === "amazon"
ET order_ref IS NULL
ET customer_handle NOT CONTAINS "@marketplace.amazon"
ET target_address IS VALID EMAIL
ALORS provider = SMTP_FALLBACK
```

### Règle 4: Aucun provider → ERREUR FATALE

```
SI aucune des règles ci-dessus ne s'applique
ALORS throw Error("[FATAL] Impossible de déterminer le provider")
```

**JAMAIS** de provider "Unknown" ou de silence.

---

## ❓ Pourquoi le fallback SMTP est NORMAL

### Amazon ne supporte pas SP-API pour les non-order

L'API Amazon Messaging (`messaging/v1`) **requiert un orderId**.
Pour les messages sans commande (ex: questions générales pré-achat), Amazon utilise un système de relay SMTP.

### Comment ça marche

1. L'acheteur envoie un message via Amazon
2. Amazon génère une adresse relay unique : `<random>@marketplace.amazon.<tld>`
3. Cette adresse est incluse dans l'email forward reçu par KeyBuzz
4. KeyBuzz répond à cette adresse via SMTP
5. Amazon route la réponse vers le bon thread

### Preuves que ça fonctionne

Voici un exemple de log Postfix prouvant la livraison :

```
2026-01-09T00:36:21+00:00 mail-core-01 postfix/smtp:
  to=<43vfy537czcw8nq+2a7e7298-a90a-4ad6-962c-77ccae27280a@marketplace.amazon.fr>
  relay=inbound-smtp.eu-west-1.amazonaws.com[54.155.140.59]:25
  dsn=2.0.0
  status=sent (250 OK l4197s426n35rjco8q207aobl54evg15sn65oog1)
```

**Code 250 OK** = Amazon a accepté le message.

---

## 🔍 Checklist "Si ça casse"

### Symptôme 1: "Unknown provider: spapi"

**Cause probable** : Image worker déployée trop ancienne

**Vérification** :
```bash
kubectl get deploy keybuzz-outbound-worker -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Solution** : Redéployer avec une version récente contenant le support `spapi`

### Symptôme 2: Messages non délivrés

**Vérifications** :
1. **DB** : `SELECT status, provider, last_error FROM outbound_deliveries WHERE id = '...'`
2. **Worker** : `kubectl logs deploy/keybuzz-outbound-worker -n keybuzz-api-dev --tail=100`
3. **Postfix** : `ssh mail-core-01 "tail -100 /var/log/mail.log | grep marketplace.amazon"`

### Symptôme 3: Messages livrés mais non visibles sur Amazon

**Causes possibles** :
- Délai Amazon (attendre 5-10 min)
- Format du message rejeté par Amazon (vérifier headers)
- Réputation expéditeur

**Vérifications** :
- Postfix montre `status=sent (250 OK)` → Amazon a accepté
- Vérifier Subject, In-Reply-To, References
- Vérifier que l'adresse From est autorisée

### Symptôme 4: Healthcheck KO

```bash
curl -s https://api-dev.keybuzz.io/health/outbound/amazon | jq
```

**Si unhealthy** :
1. Vérifier `.checks.providerValidation` → Provider non supporté
2. Vérifier `.checks.dbConnection` → Problème DB
3. Vérifier `.checks.smtpConfig` → SMTP_HOST manquant

---

## 📂 Fichiers Clés

| Fichier | Rôle |
|---------|------|
| `keybuzz-api/src/lib/determineAmazonProvider.ts` | Logique de sélection du provider |
| `keybuzz-api/src/lib/determineAmazonProvider.test.ts` | Tests de non-régression |
| `keybuzz-api/src/workers/outboundWorker.ts` | Worker qui traite les deliveries |
| `keybuzz-api/src/modules/health/outboundHealthcheck.ts` | Healthcheck endpoint |
| `keybuzz-infra/docs/AMAZON-OUTBOUND-SOURCE-OF-TRUTH.md` | Ce document |

---

## 📊 Providers Supportés

| Provider | Description | Quand utilisé |
|----------|-------------|---------------|
| `mock` | Simulation (dev/test) | Tests uniquement |
| `spapi` | Amazon SP-API Messaging | Conversation avec orderId |
| `SPAPI_ORDER` | Alias interne pour SP-API | Après traitement |
| `SMTP_AMAZON_NONORDER` | SMTP vers relay Amazon | Conversation sans orderId |
| `SMTP_FALLBACK` | SMTP générique | Fallback |
| `smtp` | SMTP standard | Emails non-Amazon |
| `email_forward` | Forward email | Legacy |

---

## 🧪 Tests de Non-Régression

Ces tests **DOIVENT** passer à chaque build :

```bash
cd keybuzz-api
npm test -- --grep "Amazon"
```

| Test | Description | Provider attendu |
|------|-------------|------------------|
| TEST 1 | Amazon sans commande | SMTP_AMAZON_NONORDER |
| TEST 2 | Amazon avec commande | SPAPI_ORDER |
| TEST 3 | Provider inconnu | ERREUR FATALE |
| TEST 4 | Canal incorrect | ERREUR FATALE |
| TEST 5 | Données insuffisantes | ERREUR FATALE |
| TEST 6 | Fallback SMTP | SMTP_FALLBACK |

**Si un test échoue → BUILD BLOQUÉ**

---

## 📜 Historique des Incidents

### 2026-01-15: Régression "Unknown provider: spapi"

**Cause** : Image worker déployée (v0.1.75-dev) ne supportait pas `spapi`
**Impact** : Messages Amazon non délivrés
**Solution** : Redéploiement avec v0.1.102-dev
**Prévention** : Tests de non-régression + healthcheck

---

## ✅ Checklist Avant Déploiement PROD

- [ ] Tests de non-régression passent
- [ ] Healthcheck `/health/outbound/amazon` retourne `status: healthy`
- [ ] Version worker correspond au code source
- [ ] SMTP_HOST configuré
- [ ] Postfix fonctionnel (test manuel)

---

**FIN DU DOCUMENT — SOURCE DE VÉRITÉ AMAZON OUTBOUND**
