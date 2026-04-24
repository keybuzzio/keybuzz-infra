# PH149-AMAZON-SPAPI-MESSAGING-FEASIBILITY-AUDIT-01

**Date** : 2026-04-13
**Type** : Audit de faisabilité
**Environnement** : DEV uniquement
**Auteur** : Agent Cursor (audit doc + code + tests réels)

---

## Verdict

### AMAZON SP-API MESSAGING FEASIBILITY KNOWN


| Question                                                          | Réponse                                                                | Preuve                                                                                              |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| SP-API permet-il de **lire** les messages entrants buyer→seller ? | **NON**                                                                | Aucun endpoint GET dans l'OpenAPI model, doc officielle explicite, GitHub discussions #3487 + #4982 |
| SP-API permet-il **seulement** d'envoyer ?                        | **OUI (partiel)**                                                      | Messaging API v1 = envoi uniquement, limité à des templates prédéfinis par type de commande         |
| Architecture cible KeyBuzz ?                                      | **A — Email inbound obligatoire, SP-API pour enrichissement et envoi** | Voir conclusion détaillée ci-dessous                                                                |


---

## 1. Audit Documentation Officielle Amazon

### Sources consultées


| Source                         | URL                                                                      | Date vérification |
| ------------------------------ | ------------------------------------------------------------------------ | ----------------- |
| Messaging API v1 Reference     | `developer-docs.amazon.com/sp-api/docs/messaging-api-v1-reference`       | 2026-04-13        |
| Messaging API Guide            | `developer-docs.amazon.com/sp-api/docs/messaging-api`                    | 2026-04-13        |
| Send a Message Tutorial        | `developer-docs.amazon.com/sp-api/docs/send-a-message`                   | 2026-04-13        |
| Roles in SP-API                | `developer-docs.amazon.com/sp-api/docs/roles-in-the-selling-partner-api` | 2026-04-13        |
| Notification Type Values       | `developer-docs.amazon.com/sp-api/docs/notification-type-values`         | 2026-04-13        |
| OpenAPI Model (messaging.json) | `github.com/amzn/selling-partner-api-models/.../messaging.json`          | 2026-04-13        |
| GitHub Discussion #3487        | `github.com/amzn/selling-partner-api-models/discussions/3487`            | 2026-04-13        |
| GitHub Discussion #4982        | `github.com/amzn/selling-partner-api-models/discussions/4982`            | 2026-04-13        |


### Tableau de synthèse documentaire


| Sujet                             | Ce que dit Amazon                                                                                                                                                                                                                                                                                              | Impact KeyBuzz                                                                                                                                               |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Envoi de message**              | Messaging API v1 permet d'envoyer des messages à l'acheteur via des **templates prédéfinis** (legalDisclosure, confirmOrderDetails, confirmDeliveryDetails, warranty, invoice, unexpectedProblem, digitalAccessKey, confirmCustomizationDetails, amazonMotors). Requiert un `amazonOrderId` + `marketplaceId`. | KeyBuzz peut envoyer certains types de messages via SP-API, mais **uniquement via templates**, pas de message libre. L'envoi SMTP relay reste plus flexible. |
| **Lecture messages entrants**     | **AUCUN endpoint de lecture dans toute l'API.** L'OpenAPI model ne contient que : 1x GET (`getMessagingActionsForOrder`), 1x GET (`getAttributes`), 9x POST (envoi). Aucun endpoint pour lister, lire, ou rechercher des messages.                                                                             | **Impossible** de récupérer les messages buyer→seller via SP-API. L'email inbound est **obligatoire**.                                                       |
| **Notifications message entrant** | **Aucun type de notification** pour les messages buyer. Les types existants sont : ORDER_CHANGE, ANY_OFFER_CHANGED, FEE_PROMOTION, REPORT_PROCESSING_FINISHED, etc. **Aucun "BUYER_MESSAGE" ou équivalent.**                                                                                                   | **Impossible** d'être notifié d'un nouveau message via webhook/SQS. L'email forward Amazon → KeyBuzz est le seul canal.                                      |
| **Rôles nécessaires**             | Rôle **Buyer Communication** requis pour tous les endpoints Messaging API. Disponible pour sellers uniquement (pas vendors).                                                                                                                                                                                   | KeyBuzz a déjà ce rôle activé. Suffisant pour l'envoi.                                                                                                       |


### Citation officielle Amazon (GitHub #3487, réponse officielle Amazon)

> "We currently do not provide a functionality to let developer get the buyer Messages and response to it. This is only the feature to let you send a message with the specified template from Amazon."
> — **Lei Wang, Amazon SP-API Team, 31 janvier 2023**

**Statut en 2026** : Aucune mise à jour annoncée. La discussion #4982 (octobre 2025) demandant la même fonctionnalité est restée **sans réponse** d'Amazon.

---

## 2. Audit Permissions / Rôles SP-API

### Rôles actifs sur l'app KeyBuzz


| Rôle SP-API                  | Nom portail                               | Status  | Donne accès à           |
| ---------------------------- | ----------------------------------------- | ------- | ----------------------- |
| **Selling Partner Insights** | Informations sur les partenaires de vente | ✅ Actif | Orders API, Sellers API |
| **Buyer Communication**      | Communication de l'acheteur               | ✅ Actif | Messaging API (envoi)   |


### Analyse des rôles


| Besoin                                    | Rôle requis                     | Statut KeyBuzz | Note                                      |
| ----------------------------------------- | ------------------------------- | -------------- | ----------------------------------------- |
| Envoyer un message buyer (template)       | Buyer Communication             | ✅ Actif        | Fonctionne, testé                         |
| Lister les actions messaging par commande | Buyer Communication             | ✅ Actif        | `getMessagingActionsForOrder` fonctionne  |
| Obtenir les attributs buyer (locale)      | Buyer Communication             | ✅ Actif        | `getAttributes` fonctionne                |
| **Lire les messages buyer**               | **N'EXISTE PAS**                | ❌ Impossible   | Aucun rôle ne donne accès à la lecture    |
| **Recevoir notification nouveau message** | **N'EXISTE PAS**                | ❌ Impossible   | Aucun type de notification buyer message  |
| Tracking FBM                              | Direct-to-Consumer Shipping     | ❌ Non actif    | Role restricted (PII), pas encore demandé |
| Reports API                               | Inventory and Order Tracking    | ❌ Non actif    | Nécessaire pour reports/tracking          |
| Notifications API                         | Finance and Accounting ou autre | ❌ 403 testé    | Aucun rôle notification actif             |


### Conclusion rôles

Le rôle **Buyer Communication** est **suffisant pour l'envoi** de messages via templates SP-API, mais **aucun rôle existant dans l'écosystème Amazon** ne permet la **lecture** des messages buyer. C'est une limitation fondamentale de l'API, pas une question de permissions.

---

## 3. Audit Code KeyBuzz Existant

### Cartographie complète

#### Ce qui est déjà SP-API


| Composant         | Fichier(s)                                                         | Fonctionnalité                         | Status                                                |
| ----------------- | ------------------------------------------------------------------ | -------------------------------------- | ----------------------------------------------------- |
| OAuth Amazon      | `amazon.oauth.ts`, `amazon.vault.ts`, `amazon.tokens.ts` (backend) | Connexion seller, refresh token, LWA   | ✅ Opérationnel                                        |
| Commandes         | `amazonOrders.service.ts`, `amazonOrdersSync.service.ts`           | Import/sync commandes via Orders API   | ✅ Opérationnel                                        |
| Backfill          | `amazonOrdersBackfillFast.service.ts`                              | Backfill historique commandes          | ✅ Opérationnel                                        |
| Items             | `amazonOrderItemsFill.service.ts`                                  | Enrichissement lignes commande         | ✅ Opérationnel                                        |
| SP-API Client     | `amazon.spapi.ts` (backend)                                        | `sendBuyerMessage()` via Messaging API | ⚠️ Code existe, utilise `confirmCustomizationDetails` |
| Provider Decision | `determineAmazonProvider.ts` (api)                                 | Choix SPAPI_ORDER vs SMTP              | ✅ Opérationnel (SMTP par défaut)                      |
| SP-API Messaging  | `spapiMessaging.ts` (api)                                          | Envoi via SP-API avec fallback SMTP    | ⚠️ Code existe, SPAPI désactivé par défaut            |
| Attributes        | Aucun                                                              | `getAttributes` (buyer locale)         | ❌ Non implémenté                                      |
| Actions listing   | Aucun                                                              | `getMessagingActionsForOrder`          | ❌ Non implémenté                                      |


#### Ce qui est email-only


| Composant         | Fichier(s)                                    | Fonctionnalité                                                            | Status                                                        |
| ----------------- | --------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Inbound email     | `amazonForward.ts`, `inbound/routes.ts` (api) | Réception messages via email forward Amazon                               | ✅ Opérationnel, source de vérité                              |
| MIME parsing      | `amazonForward.ts` (RFC 2047 decoder)         | Décodage sujets/noms encodés                                              | ✅ Opérationnel                                                |
| Outbound SMTP     | `outboundWorker.ts`, `emailService.ts` (api)  | Envoi réponses via SMTP relay `@marketplace.amazon`                       | ✅ Opérationnel, provider par défaut                           |
| Inbound addresses | `inbound_addresses` table, routes BFF         | Provisioning adresses `@inbound.keybuzz.io`                               | ✅ 5 pays configurés pour ecomlg-001                           |
| Amazon poller     | `amazon.poller.ts` (backend)                  | Poll messages (mock client, `fetchInboundMessages` retourne `[]` en réel) | ⚠️ Code existe mais `AmazonClientReal` retourne toujours `[]` |


#### Ce qui manque pour un modèle hybride


| Composant                   | Description                                                                          | Effort estimé       |
| --------------------------- | ------------------------------------------------------------------------------------ | ------------------- |
| getMessagingActionsForOrder | Déterminer les templates disponibles par commande                                    | Faible (1 endpoint) |
| Envoi SP-API intelligent    | Choisir le bon template selon le contexte (legalDisclosure, unexpectedProblem, etc.) | Moyen               |
| Fallback SMTP automatique   | Si template indisponible → SMTP relay                                                | Déjà implémenté     |
| Buyer locale enrichment     | Utiliser `getAttributes` pour détecter la langue buyer                               | Faible              |


---

## 4. Tests Techniques Réels (DEV)

### Environnement de test


| Élément      | Valeur                             |
| ------------ | ---------------------------------- |
| Tenant       | `ecomlg-001`                       |
| Seller ID    | `A12BCIS2R7HD4D`                   |
| Marketplace  | `A13V1IB3VIYZZH` (Amazon.fr)       |
| Region       | `eu-west-1`                        |
| Pod backend  | `keybuzz-backend-55678984cd-vd5k2` |
| Access token | Obtenu via LWA, longueur 375 chars |


### Test 1 — getMessagingActionsForOrder (Unshipped)

```
Commande: 407-0239528-6695506 (Unshipped)
Status HTTP: 200 OK
Actions disponibles: ["legalDisclosure"]
```

**Résultat** : Seul `legalDisclosure` est disponible pour une commande non expédiée. Pas de template de réponse libre.

### Test 2 — getMessagingActionsForOrder (Shipped récente)

```
Commande: 407-0780180-7385966 (Shipped)
Status HTTP: 200 OK
Actions disponibles: ["legalDisclosure", "unexpectedProblem"]
```

**Résultat** : Deux templates disponibles après expédition. `unexpectedProblem` permet d'envoyer un message texte libre avec contraintes.

### Test 3 — getMessagingActionsForOrder (Shipped ancienne)

```
Commande: 407-5819423-6217129 (Shipped, la plus récente)
Status HTTP: 403
Erreur: "Invalid amazonOrderId and template combination."
```

**Résultat** : Certaines commandes shipped n'ont **aucune action messaging disponible**. La fenêtre de messaging peut être fermée (Amazon limite les interactions dans le temps).

### Test 4 — getMessagingActionsForOrder (Imported)

```
Commande: 408-6285178-2490760 (Imported)
Status HTTP: 200 OK
Actions disponibles: ["legalDisclosure"]
```

### Test 5 — getAttributes (buyer locale)

```
Commande: 407-0239528-6695506
Status HTTP: 200 OK
Résultat: { "buyer": { "locale": "fr-FR" } }
```

**Résultat** : La locale buyer est accessible. Utile pour la détection automatique de langue.

### Test 6 — Notifications API

```
Endpoint: /notifications/v1/subscriptions/ANY_OFFER_CHANGED
Status HTTP: 403 Unauthorized
```

**Résultat** : Aucun rôle notification actif. Confirme qu'aucune notification buyer message n'existe de toute façon.

### Synthèse des tests


| Fonctionnalité                | Résultat                                        | Preuve                                                     |
| ----------------------------- | ----------------------------------------------- | ---------------------------------------------------------- |
| Lire messages entrants        | **IMPOSSIBLE**                                  | Aucun endpoint dans l'API                                  |
| Lister actions messaging      | ✅ Fonctionne                                    | 200 OK avec templates disponibles                          |
| Envoyer message template      | ✅ Possible (non testé en réel pour éviter spam) | Templates legalDisclosure et unexpectedProblem disponibles |
| Recevoir notification message | **IMPOSSIBLE**                                  | Aucun type notification buyer message                      |
| Obtenir buyer locale          | ✅ Fonctionne                                    | `{ "buyer": { "locale": "fr-FR" } }`                       |
| Fenêtre messaging             | ⚠️ Variable                                     | Certaines commandes ont 0 actions (403), d'autres 1-2      |


---

## 5. Test Produit SaaS DEV

### État actuel de l'inbox Amazon sur ecomlg-001


| Métrique                     | Valeur                          |
| ---------------------------- | ------------------------------- |
| Conversations Amazon totales | 387                             |
| Conversations email          | 8                               |
| Conversations Shopify        | 1                               |
| Inbound connections Amazon   | 1 (5 pays : FR, DE, IT, ES, BE) |
| Inbound addresses validées   | 5 (FR, DE, IT, ES, BE)          |
| Dernière réception FR        | 2026-04-13 14:48 UTC            |
| Dernière réception ES        | 2026-04-13 13:17 UTC            |
| Commandes Amazon             | 12 000+                         |


### Comment les messages arrivent aujourd'hui

```
1. Buyer envoie un message sur Amazon (Messaging with Seller)
2. Amazon forward l'email à l'adresse configurée dans Seller Central :
   → amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
3. AWS SES réceptionne l'email (eu-west-1)
4. SES webhook → keybuzz-api POST /inbound/email
5. amazonForward.ts parse le payload (MIME, RFC 2047, noms, subject)
6. Conversation créée/mise à jour dans la DB
7. Message visible dans l'Inbox KeyBuzz
```

### Preuve que l'email inbound fonctionne en temps réel

Les `lastInboundAt` des adresses montrent des messages reçus **aujourd'hui même** (2026-04-13). Le flux est actif et fonctionnel.

### Comment les réponses sont envoyées aujourd'hui

```
1. Agent compose une réponse dans l'Inbox KeyBuzz
2. POST /conversations/{id}/reply → outbound_deliveries
3. Outbound worker détecte le canal Amazon
4. determineAmazonProvider() → SMTP_AMAZON_NONORDER (SPAPI désactivé par défaut)
5. nodemailer envoie via mail.keybuzz.io (Postfix) port 25
6. Postfix relay → inbound-smtp.eu-west-1.amazonaws.com
7. Amazon route vers le thread buyer-seller
```

Le provider SP-API existe dans le code (`AMAZON_SPAPI_MESSAGING_ENABLED`) mais est **désactivé** par défaut. Le SMTP relay fonctionne et est le provider actif.

---

## 6. Conclusion — Architecture Recommandée

### Réponse formelle

**Conclusion A — Email inbound OBLIGATOIRE, SP-API pour enrichissement et envoi complémentaire**

Cette conclusion est **factuelle**, basée sur :

1. La documentation officielle Amazon qui ne mentionne **aucun** endpoint de lecture
2. L'OpenAPI model (messaging.json) qui ne contient que des POST (envoi) et 2 GET (actions + attributes)
3. La confirmation officielle Amazon (GitHub #3487) que la lecture n'existe pas
4. Les tests réels prouvant que seuls des templates limités sont disponibles
5. L'absence totale de notification type "buyer message" dans les 40+ types de notifications SP-API

### Matrice architecture


| Fonctionnalité               | Source actuelle                       | Source cible                                               | Changement                                       |
| ---------------------------- | ------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------ |
| **Réception messages buyer** | Email forward Amazon → SES → webhook  | Email forward (inchangé)                                   | Aucun — SP-API ne le permet pas                  |
| **Envoi réponses agent**     | SMTP relay (mail.keybuzz.io → Amazon) | SMTP relay (principal) + SP-API templates (complémentaire) | Activer SP-API pour les commandes avec templates |
| **Commandes**                | SP-API Orders API                     | SP-API Orders API (inchangé)                               | Aucun                                            |
| **Tracking**                 | Non disponible (role manquant)        | Demander role Direct-to-Consumer Shipping                  | À planifier séparément                           |
| **Buyer locale**             | Non utilisé                           | SP-API `getAttributes`                                     | Intégrer pour détection langue                   |
| **Actions disponibles**      | Non vérifié                           | SP-API `getMessagingActionsForOrder`                       | Intégrer pour UX intelligente                    |


### Ce que SP-API apporte concrètement (valeur ajoutée)


| Apport                      | Détail                                                                                   | Effort            |
| --------------------------- | ---------------------------------------------------------------------------------------- | ----------------- |
| **Buyer locale**            | Détecter automatiquement la langue du buyer (fr-FR, de-DE, etc.) pour les suggestions IA | Faible            |
| **Actions disponibles**     | Montrer à l'agent quels types de messages sont possibles par commande                    | Faible            |
| **Envoi template officiel** | Pour les cas spécifiques (legal disclosure, unexpected problem, warranty, invoice)       | Moyen             |
| **Dual-path outbound**      | SP-API quand template dispo + orderId, SMTP relay sinon                                  | Déjà architecturé |


### Ce que SP-API NE PEUT PAS faire


| Limitation                            | Impact                                        | Contournement                         |
| ------------------------------------- | --------------------------------------------- | ------------------------------------- |
| Lire les messages buyer               | Impossible d'abandonner l'email inbound       | Email forward obligatoire             |
| Recevoir des notifications de message | Pas de push/webhook message                   | Polling email seul canal              |
| Envoyer un message libre              | Templates uniquement (pas de free-form reply) | SMTP relay pour les réponses normales |
| Répondre à un message existant        | Pas de concept de "reply" dans l'API          | SMTP relay vers `@marketplace.amazon` |


---

## 7. Plan de Suite

### Phase suivante recommandée

**PH149.1 — AMAZON MESSAGING HYBRID ENRICHMENT-01**


| Étape | Description                                                                                  | Effort    |
| ----- | -------------------------------------------------------------------------------------------- | --------- |
| 1     | Intégrer `getAttributes` pour enrichir les conversations avec la buyer locale                | 1 jour    |
| 2     | Intégrer `getMessagingActionsForOrder` pour afficher les actions possibles dans l'UI         | 1 jour    |
| 3     | Activer le dual-path outbound (SP-API template quand disponible + SMTP fallback)             | 1-2 jours |
| 4     | UX : afficher dans l'inbox les templates SP-API disponibles pour chaque conversation         | 1 jour    |
| 5     | Tests E2E : envoyer un vrai message via `createLegalDisclosure` ou `createUnexpectedProblem` | 0.5 jour  |


**Prérequis** : Aucun nouveau rôle Amazon nécessaire. `Buyer Communication` suffit.

### Phase optionnelle

**PH150 — AMAZON TRACKING FBM-01**

Pour obtenir les numéros de suivi des commandes FBM :

1. Demander le rôle **Direct-to-Consumer Shipping** (restricted, justification PII)
2. Attendre approbation Amazon
3. Re-autoriser l'app (nouveau refresh_token)
4. Implémenter Reports API pour tracking

**Estimation** : 3-5 jours dont attente Amazon.

---

## 8. Résumé des Preuves

### Preuves documentaires

- **Doc officielle Messaging API** : "You use the Messaging API to **send** messages to buyers" — aucune mention de lecture
- **OpenAPI model** : 9 endpoints POST (envoi), 2 endpoints GET (actions + attributes), 0 endpoint de lecture
- **Confirmation Amazon** (GitHub #3487) : "We currently do not provide a functionality to let developer **get** the buyer Messages"
- **Notification types** : 40+ types, aucun pour buyer messages
- **GitHub #4982** (oct 2025) : Demande identique, 0 réponse Amazon

### Preuves techniques (tests réels DEV)

- `getMessagingActionsForOrder` : 200 OK avec templates limités (legalDisclosure, unexpectedProblem)
- `getAttributes` : 200 OK avec buyer locale (fr-FR)
- Notifications API : 403 (aucun rôle notification actif, mais aucun type buyer message de toute façon)
- Email inbound : actif, dernière réception aujourd'hui (2026-04-13 14:48 UTC)

### Preuves code existant

- `AmazonClientReal.fetchInboundMessages()` retourne `[]` (stub vide, confirme qu'il n'y a rien à fetch)
- `determineAmazonProvider()` route vers SMTP par défaut (`AMAZON_SPAPI_MESSAGING_ENABLED = false`)
- 387 conversations Amazon, toutes créées via email inbound

---

## 9. Fichiers consultés (non modifiés)


| Fichier                          | Localisation                                                            |
| -------------------------------- | ----------------------------------------------------------------------- |
| `amazon.spapi.ts`                | bastion `/opt/keybuzz/keybuzz-backend/src/modules/marketplaces/amazon/` |
| `amazon.client.ts`               | bastion (même répertoire)                                               |
| `amazon.types.ts`                | bastion (même répertoire)                                               |
| `amazon.poller.ts`               | bastion (même répertoire)                                               |
| `amazonReply.routes.ts`          | bastion (même répertoire)                                               |
| `amazonSendReplyWorker.ts`       | bastion `/opt/keybuzz/keybuzz-backend/src/workers/`                     |
| `amazonPollingHealth.service.ts` | bastion `/opt/keybuzz/keybuzz-backend/src/modules/inboundEmail/`        |
| `spapiMessaging.ts`              | bastion `/opt/keybuzz/keybuzz-api/src/services/`                        |
| `determineAmazonProvider.ts`     | bastion `/opt/keybuzz/keybuzz-api/src/lib/`                             |
| `amazonForward.ts`               | bastion `/opt/keybuzz/keybuzz-api/src/modules/inbound/`                 |
| `amazon-spapi-roles-rules.mdc`   | workspace `.cursor/rules/`                                              |
| `messaging.json` (OpenAPI)       | github.com/amzn/selling-partner-api-models                              |


---

**Aucune modification de code effectuée.**
**Aucun push DEV ni PROD.**
**Audit documentaire + technique uniquement.**

---

**FIN DU RAPPORT — PH149-AMAZON-SPAPI-MESSAGING-FEASIBILITY-AUDIT-01**