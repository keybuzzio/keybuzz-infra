# PH150 — Amazon Conversation Threading Truth & Order-Centric Recovery

> Date : 13 avril 2026
> Environnement : DEV uniquement
> Image déployée : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph150-thread-fix-dev`
> Verdict : **AMAZON ORDER-CENTRIC THREADING RESTORED**

---

## 1. Logique actuelle de matching (avant fix)

### Architecture réelle

Le système de création de conversations est dans le **keybuzz-backend** (pas le keybuzz-api).

**Fichier source** : `/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts`

**Flux** : Email SES → Webhook → `inboxConversation.service.ts` → DB `conversations` + `messages`

### Logique de groupement (PH15)

Priorité de matching pour rattacher un message à une conversation existante :

1. **threadKey** : extrait des URLs Seller Central (`?t=XXX`), headers, ou fallback `order:XXX-XXXXXXX-XXXXXXX`
2. **orderRef** : extrait du body/subject via regex `\b(\d{3}-\d{7}-\d{7})\b`
3. **Nouvelle conversation** si rien ne matche (ID CUID généré)

### Clés de regroupement réelles


| Clé               | Source                       | Format                                          | Utilisée                     |
| ----------------- | ---------------------------- | ----------------------------------------------- | ---------------------------- |
| `thread_key`      | URLs Seller Central, headers | `sc:AXXXXXXXXXX` ou `order:XXX-XXXXXXX-XXXXXXX` | Oui (priorité 1)             |
| `order_ref`       | Body/Subject parsing         | `XXX-XXXXXXX-XXXXXXX` (format Amazon natif)     | Oui (priorité 2)             |
| `customer_handle` | Email relay Amazon           | `xxx@marketplace.amazon.com`                    | Non utilisé pour le matching |
| `subject`         | Email subject                | Texte libre                                     | Non utilisé pour le matching |


### Bug identifié : filtre `AND status = 'open'`

Les deux requêtes de matching contenaient un filtre fatal :

```sql
-- threadKey matching (AVANT)
SELECT id FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND thread_key = $3 AND status = 'open'

-- orderRef matching (AVANT)
SELECT id FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND order_ref = $3 AND status = 'open'
```

**Conséquence** : quand une conversation était résolue (`status = 'resolved'`), tout nouveau message Amazon pour la même commande créait une NOUVELLE conversation au lieu de rattacher au fil existant.

### Code secondaire (non utilisé en production)

Le fichier `keybuzz-api/src/modules/inbound/routes.ts` contient une logique alternative basée sur `SHA1(tenantId + channel + from + subject)` qui produit des IDs `conv-XXXXXXXX`. Ce code est déployé mais n'est PAS le chemin réel des emails Amazon. Seules 20 conversations de test utilisent ce format (vs 369 conversations CUID créées par le backend).

Le `extractOrderRef()` dans `amazonForward.ts` (API) ne matche PAS le format Amazon (cherche `ORDER-\d+` au lieu de `\d{3}-\d{7}-\d{7}`). Ce code est hors du chemin critique.

---

## 2. Preuves DB réelles

### Duplicats identifiés

**19 commandes** avaient des conversations fragmentées, totalisant **81 messages éparpillés** sur **39 conversations** (au lieu de 19).


| order_ref           | nb conv avant | nb msgs total | pattern                                                                 |
| ------------------- | ------------- | ------------- | ----------------------------------------------------------------------- |
| 171-4627483-3447564 | 3             | 9             | Buyer inquiry → resolved → remboursement crée 2e conv → relance crée 3e |
| 402-6921264-3662739 | 2             | 5             | Colis non arrivé → resolved → Re: crée 2e conv                          |
| 403-4385690-2637922 | 2             | 6             | Inquiry → resolved → même inquiry crée 2e conv                          |
| 405-4867060-5480332 | 2             | 9             | Inquiry → resolved → décision réclamation crée 2e conv                  |
| 408-8653326-4102730 | 2             | 7             | Endommagé → resolved → même sujet 6 semaines après crée 2e conv         |
| ... (14 autres)     | 2             | 2-6           | Même pattern                                                            |


### Stats globales


| Métrique                     | Valeur                                    |
| ---------------------------- | ----------------------------------------- |
| Conversations Amazon totales | 388                                       |
| Avec `order_ref` renseigné   | 311 (80%)                                 |
| Sans `order_ref`             | 77 (20%)                                  |
| Commandes avec duplicats     | 19                                        |
| Conversations secondaires    | 20                                        |
| Messages déplacés (backfill) | 36                                        |
| Format `order_ref`           | 100% Amazon natif (`XXX-XXXXXXX-XXXXXXX`) |


### Cause commune

**19/19 duplicats** suivent le même pattern :

1. Conversation 1 créée et passe en `resolved`
2. Nouveau message Amazon arrive (même commande)
3. Le matching cherche `status = 'open'` → ne trouve rien
4. Nouvelle conversation créée

---

## 3. Typologie des messages Amazon

### Classification


| Type                           | Exemples                                                | Nb  | Action                                 |
| ------------------------------ | ------------------------------------------------------- | --- | -------------------------------------- |
| **BUYER: Inquiry**             | "Demande de renseignements de la part du client Amazon" | 91  | Rattacher au fil commande              |
| **AUTO: Return Authorization** | "Notification d'autorisation de retour"                 | 65  | Rattacher au fil commande              |
| **OTHER (buyer)**              | "Article endommagé", "Le colis n'est pas arrivé"        | 69  | Rattacher au fil commande              |
| **BUYER: Cancel Request**      | "Demande d'annulation de commande"                      | 20  | Rattacher au fil commande              |
| **AUTO: Refund Initiated**     | "Remboursement initié pour la commande XXX"             | ~15 | Rattacher au fil commande              |
| **AUTO: Claim Decision**       | "Décision concernant la réclamation"                    | ~10 | Rattacher au fil commande              |
| **REPLY: Thread Continue**     | "Re: Le colis n'est pas arrivé"                         | 2   | Rattacher par threadKey                |
| **SYSTEM: Business Strategy**  | "Définissez une stratégie de..."                        | 1   | Conversation séparée (pas d'order_ref) |


### Règle appliquée

- **Tous les types avec `order_ref`** → rattachés au fil principal de la commande
- Les notifications automatiques Amazon (retour, remboursement, réclamation) font partie du dossier client
- Les messages système sans `order_ref` restent en conversations séparées

---

## 4. Règle produit cible

```
SI même tenant_id + channel amazon + même order_ref → MÊME conversation
SI même tenant_id + channel amazon + même thread_key → MÊME conversation
SI conversation trouvée est 'resolved' → la repasser en 'pending'
SI aucun match → nouvelle conversation
```

**1 commande = 1 conversation principale, quel que soit le statut.**

---

## 5. Fix appliqué

### Modifications dans `inboxConversation.service.ts`

**Fichier** : `/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts`
**Backup** : `.pre-ph150`

#### 5.1 Retrait du filtre `status = 'open'`

```sql
-- AVANT
SELECT id FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND thread_key = $3 AND status = 'open'

-- APRÈS (PH150)
SELECT id, status FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND thread_key = $3
```

Idem pour le matching par `order_ref`.

#### 5.2 Réouverture des conversations résolues

Ajout de la logique PH150 après chaque match :

```typescript
const threadConvStatus = existingByThread.rows[0].status;
if (threadConvStatus === 'resolved') {
  await productDb.query(
    `UPDATE conversations SET status = 'pending', updated_at = NOW() WHERE id = $1`,
    [conversationId]
  );
  console.log(`[InboxConversation PH150] Reopened resolved conversation ${conversationId} to pending`);
}
```

#### 5.3 Backfill des duplicats existants

Script one-shot exécuté en DEV :

- Pour chaque `order_ref` dupliqué : garder la conversation la plus ancienne (primary)
- Déplacer les messages des secondaires vers le primary (`UPDATE messages SET conversation_id = $1`)
- Supprimer les conversations secondaires vides
- Mettre à jour les stats du primary

**Résultat** : 20 conversations secondaires fusionnées, 36 messages déplacés, 0 duplicats restants.

### Image déployée

```
ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph150-thread-fix-dev
```

---

## 6. Validation IA / contexte

Après la fusion, la conversation `171-4627483-3447564` contient **9 messages** en ordre chronologique :

1. Demande initiale (bacs manquants imprimante)
2. Relance du client
3. Coordonnées pour enlèvement
4. Horaires du client
5. Note interne agent (retour FedEx)
6. Confirmation colis prêt
7. Réponse agent (Mélanie)
8. **Notification Amazon : remboursement 299,55 EUR** (anciennement dans une conversation séparée)
9. **Relance client** (anciennement dans une 3e conversation séparée)

L'IA charge les 10 derniers messages (`SELECT direction, body FROM messages WHERE conversation_id = $1 ORDER BY created_at DESC LIMIT 10`). Après la fusion, elle voit l'intégralité du dossier SAV incluant le remboursement et la relance.

---

## 7. Validation UI

**URL validée** : `https://client-dev.keybuzz.io/inbox?id=cmmmbvxa0y224e0755d19b0e2`

Vérifications :

- 1 seule conversation pour la commande 171-4627483-3447564
- 9 messages affichés dans l'ordre chronologique
- Notification Amazon (remboursement) visible dans le fil
- Panneau commande affiche les détails (299,55 EUR, Brother HL-L5210DNTT)
- Suggestions IA actives avec contexte complet
- Recherche par numéro de commande fonctionne

---

## 8. Non-régression


| Fonctionnalité        | Statut | Preuve                                  |
| --------------------- | ------ | --------------------------------------- |
| Inbox                 | OK     | 378 conversations, filtres fonctionnels |
| Amazon messages       | OK     | Messages reçus et affichés              |
| Aide IA / Suggestions | OK     | Suggestions actives sur conversations   |
| Orders                | OK     | 11 924 commandes affichées              |
| Channels              | OK     | 7 canaux Amazon connectés               |
| Dashboard             | OK     | Stats correctes (378 conv, Amazon 98%)  |
| Backend pod           | OK     | Running, 0 restarts                     |
| API pod               | OK     | Running, 0 restarts                     |
| Shopify               | N/A    | Non impacté (scope Amazon uniquement)   |


---

## 9. Verdict final

### AMAZON ORDER-CENTRIC THREADING RESTORED

Le threading conversationnel Amazon est maintenant centré sur la commande :

- **1 commande = 1 conversation** quel que soit le statut
- Les conversations résolues sont rouvertes automatiquement sur nouveau message
- Les 19 duplicats existants ont été fusionnés (backfill)
- L'IA a accès au contexte complet du dossier
- Aucune régression détectée

### Métriques d'impact


| Avant                                  | Après                                  |
| -------------------------------------- | -------------------------------------- |
| 19 commandes fragmentées               | 0 duplicat                             |
| 81 messages éparpillés                 | Tous dans leur conversation principale |
| IA avec contexte partiel               | IA avec contexte complet               |
| Conversations résolues = dossier fermé | Conversations résolues = réouvrables   |


### Ce qui n'a PAS été modifié (hors scope)

- Code de l'API (`keybuzz-api`) — inchangé
- Code du client (`keybuzz-client`) — inchangé
- Billing, Agents, Shopify, Amazon OAuth — inchangés
- Aucun push PROD

---

## STOP

- Aucun push PROD effectué
- Aucune modification hors scope threading/messages
- Image DEV uniquement : `v1.0.41-ph150-thread-fix-dev`

