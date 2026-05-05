# Amazon SP-API Connector Baseline

> Derniere mise a jour : 2026-05-05 (AO.6.1 reconciliation)
> Scope : Amazon connector, OAuth, marketplaces, inbound email, orders, AI order/tracking context
> Statut : memoire durable a relire avant toute phase Amazon

## Pourquoi ce document existe

Les phases AM/AO ont montre que le connecteur Amazon peut regresser de facon invisible quand une nouvelle image Backend/API/Client est reconstruite depuis une source incomplete ou quand une logique multi-DB n'est pas prise en compte.

Ce document verrouille les invariants Amazon SP-API a respecter pour KeyBuzz.

## Sources officielles Amazon a relire

- Website Authorization Workflow : https://developer-docs.amazon.com/sp-api/lang-es_ES/docs/website-authorization-workflow
- Selling Partner Appstore Authorization Workflow : https://developer-docs.amazon.com/sp-api/docs/selling-partner-appstore-authorization-workflow
- Seller Central URLs : https://developer-docs.amazon.com/sp-api/docs/seller-central-urls
- SP-API Endpoints : https://developer-docs.amazon.com/sp-api/lang-en_US/docs/sp-api-endpoints
- Marketplace IDs : https://developer-docs.amazon.com/sp-api/lang-US/docs/marketplace-ids
- Usage Plans and Rate Limits : https://developer-docs.amazon.com/sp-api/docs/usage-plans-and-rate-limits
- Amazon outbound source of truth KeyBuzz : `keybuzz-infra/docs/AMAZON-OUTBOUND-SOURCE-OF-TRUTH.md`

## Invariants OAuth

1. Le `redirect_uri` Amazon doit rester une URL enregistree dans l'application Amazon.
2. En PROD, le callback OAuth doit pointer vers Backend PROD :
   - `https://backend.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback`
3. En DEV, le callback OAuth doit pointer vers Backend DEV :
   - `https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback`
4. Ne jamais laisser une URL DEV dans un runtime PROD.
5. Ne jamais prendre une valeur Vault partagee DEV/PROD avant une env var runtime specifique a l'environnement.
6. `state` doit etre unique, court-vivant, stocke, valide au callback, puis consomme.
7. Le contexte KeyBuzz doit etre porte dans le state ou dans un storage associe au state :
   - `tenant_id`
   - `returnTo`
   - `expected_channel`
   - marketplace/country choisi si applicable
8. Le code `spapi_oauth_code` doit etre echange rapidement. Amazon documente une expiration courte et un risque de rupture du workflow si le processus dure trop longtemps.

## Seller Central host vs marketplace vs SP-API endpoint

Ne pas confondre ces trois concepts.

### Seller Central authorization host

Le host de consentement Amazon peut varier selon le marketplace. Source officielle : Seller Central URLs.

Exemples Europe :

| Marketplace | Seller Central URL documentee |
|---|---|
| FR | `https://sellercentral-europe.amazon.com` |
| ES | `https://sellercentral-europe.amazon.com` |
| DE | `https://sellercentral-europe.amazon.com` |
| IT | `https://sellercentral-europe.amazon.com` |
| UK | `https://sellercentral-europe.amazon.com` |
| PL | `https://sellercentral.amazon.pl` |
| SE | `https://sellercentral.amazon.se` |
| NL | `https://sellercentral.amazon.nl` |
| BE | `https://sellercentral.amazon.com.be` |
| IE | `https://sellercentral.amazon.ie` |

Conclusion : "Europe" n'est pas toujours suffisant pour l'URL Seller Central. Pour un travail durable, KeyBuzz doit utiliser une table officielle `marketplaceKey -> sellerCentralAuthorizeHost`.

### SP-API endpoint

Pour les appels API, Amazon documente des endpoints regionaux :

| Region | Endpoint |
|---|---|
| Europe | `https://sellingpartnerapi-eu.amazon.com` |
| North America | `https://sellingpartnerapi-na.amazon.com` |
| Far East | `https://sellingpartnerapi-fe.amazon.com` |

Conclusion : plusieurs pays EU partagent le meme endpoint SP-API, meme si leur Seller Central URL visible peut differer.

### Marketplace ID

Les operations Orders, Messaging, etc. doivent utiliser le marketplace ID correct.

Exemples importants :

| Pays | Marketplace ID |
|---|---|
| FR | `A13V1IB3VIYZZH` |
| ES | `A1RKKUPIHCS9HS` |
| DE | `A1PA6795UKMFR9` |
| IT | `APJ6JRA9NG5V4` |
| PL | `A1C3SOZRARQ6R3` |
| SE | `A2NODRKZP88ZB9` |
| NL | `A1805IZSGTT6HS` |
| BE | `AMEN7PMS3EDWL` |
| UK | `A1F83G8C2ARO7P` |

## Doctrine KeyBuzz pour `/start`

Le ticket KEY-249 doit etre traite comme une clarification produit et technique.

`/start` ne doit pas lancer Amazon OAuth a l'aveugle.

Attendu :

1. Afficher un choix explicite du pays Amazon.
2. Construire un `expected_channel` clair : `amazon-fr`, `amazon-es`, `amazon-it`, etc.
3. Stocker ce choix dans le state OAuth.
4. Utiliser le Seller Central host documente pour ce marketplace.
5. Garder le callback `redirect_uri` unique et environnement-aware.
6. Au retour, activer uniquement le channel choisi ou echouer honnetement.
7. Afficher le pays choisi dans KeyBuzz, meme si Amazon Seller Central affiche un autre contexte de session.

## Table source unique requise

Toute future phase Amazon doit verifier ou creer une source unique contenant au minimum :

| Champ | Exemple |
|---|---|
| `marketplaceKey` | `amazon-fr` |
| `countryCode` | `FR` |
| `label` | `Amazon France` |
| `marketplaceId` | `A13V1IB3VIYZZH` |
| `region` | `EU` |
| `spApiEndpoint` | `https://sellingpartnerapi-eu.amazon.com` |
| `sellerCentralAuthorizeHost` | `https://sellercentral-europe.amazon.com` |
| `supported` | `true` |

Interdit :

- duplicer une liste dans `/start` et une autre dans `/channels`
- hardcoder FR comme fallback invisible
- utiliser `sellercentral-europe.amazon.com` pour tous les pays sans verifier la table officielle
- choisir un channel different de celui affiche a l'utilisateur

## Audit AO.6.1 — Reconciliation officielle (2026-05-05)

### Résultats clés

1. **KeyBuzz a des credentials EU (region eu-west-1)**. Seuls les marketplaces EU sont connectables.
2. **NA/APAC marketplaces** (US, CA, MX, AU, JP, SG) nécessitent des enregistrements app séparés. Filtrés dans `/start` depuis AO.6.1.
3. **Seller Central host** : le Backend utilise `REGION_SELLER_CENTRAL["eu-west-1"]` = `sellercentral-europe.amazon.com` pour TOUS les pays EU. Ceci est correct pour l'OAuth car Amazon autorise l'access cross-EU depuis ce portail unifié. Les URLs pays-spécifiques (PL, SE, NL, BE, IE) sont des alternatives d'accès, pas des pré-requis OAuth.
4. **redirect_uri** : env-aware. PROD a un override explicite dans deployment.yaml. Cross-env guard actif dans amazon.oauth.ts.
5. **expected_channel** : le callback Backend extrait le pays depuis `expected_channel` dans `returnTo`. Patché dans AO.6.1 pour `/start`.

### Table officielle vérifiée (Amazon docs 2026)

| marketplace_key | country | marketplace_id | region | sellerCentralHost | spApiEndpoint | supported |
|---|---|---|---|---|---|---|
| amazon-fr | FR | A13V1IB3VIYZZH | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | oui |
| amazon-de | DE | A1PA6795UKMFR9 | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | oui |
| amazon-es | ES | A1RKKUPIHCS9HS | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | oui |
| amazon-it | IT | APJ6JRA9NG5V4 | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | oui |
| amazon-nl | NL | A1805IZSGTT6HS | EU | sellercentral.amazon.nl | sellingpartnerapi-eu.amazon.com | oui |
| amazon-be | BE | AMEN7PMS3EDWL | EU | sellercentral.amazon.com.be | sellingpartnerapi-eu.amazon.com | oui |
| amazon-gb | GB | A1F83G8C2ARO7P | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | oui |
| amazon-se | SE | A2NODRKZP88ZB9 | EU | sellercentral.amazon.se | sellingpartnerapi-eu.amazon.com | oui |
| amazon-pl | PL | A1C3SOZRARQ6R3 | EU | sellercentral.amazon.pl | sellingpartnerapi-eu.amazon.com | oui |
| amazon-ie | IE | A28R8C7NBKEWEA | EU | sellercentral.amazon.ie | sellingpartnerapi-eu.amazon.com | oui |
| amazon-us | US | ATVPDKIKX0DER | NA | sellercentral.amazon.com | sellingpartnerapi-na.amazon.com | non (credentials NA requis) |
| amazon-ca | CA | A2EUQ1WTGCTBG2 | NA | sellercentral.amazon.ca | sellingpartnerapi-na.amazon.com | non |
| amazon-mx | MX | A1AM78C64UM0Y8 | NA | sellercentral.amazon.com.mx | sellingpartnerapi-na.amazon.com | non |
| amazon-au | AU | A39IBJ37TRP1C6 | FE | sellercentral.amazon.com.au | sellingpartnerapi-fe.amazon.com | non |
| amazon-jp | JP | A1VC38T7YXB528 | FE | sellercentral.amazon.co.jp | sellingpartnerapi-fe.amazon.com | non |
| amazon-sg | SG | A19VAU5U5O7RUS | FE | sellercentral.amazon.sg | sellingpartnerapi-fe.amazon.com | non |

### Stop conditions AO.6.1

- STOP si un marketplace NA/APAC est affiché dans `/start` sans credentials régionales séparées
- STOP si `redirect_uri` est par pays ou contient un suffixe pays
- STOP si `expected_channel` est absent du `returnTo` pour un flow marketplace-specific
- STOP si une image DEV utilise un `redirect_uri` PROD ou vice-versa

## Multi-DB Backend/API

Les phases AO ont prouve que les tenants peuvent exister dans l'API DB `keybuzz` sans exister dans la Backend DB `keybuzz_backend`.

Invariant :

- Toute creation d'inbound connection cote Backend doit garantir que le tenant existe dans Backend DB.
- Le fix AO.4 `prisma.tenant.upsert()` dans `ensureInboundConnection()` est une baseline.
- Ne jamais retirer ce comportement sans remplacer par une synchronisation tenant explicite et testee.

## Inbound email

Un channel Amazon ne doit jamais etre considere connecte si l'adresse inbound n'est pas visible.

Activation valide =

- Backend inbound connection READY
- Backend inbound addresses presentes
- API DB synchronisee
- `tenant_channels.status = active`
- `tenant_channels.inbound_email` renseigne
- UI affiche l'adresse inbound

## Suppression / reactivation

Invariants AM.3+ :

- `GET /status` reste read-only.
- Aucune lecture ne doit re-activer un connecteur.
- `removeChannel()` doit nettoyer les references stale.
- La reactivation doit passer par un endpoint explicite post-OAuth.

## Messages et commandes Amazon

Source de verite : `AMAZON-OUTBOUND-SOURCE-OF-TRUTH.md`.

- Amazon avec commande : SP-API Messaging.
- Amazon sans commande : SMTP relay Amazon si adresse relay presente.
- Fallback SMTP autorise si SP-API echoue.
- Jamais de provider silencieux ou unknown.

## Orders / tracking / AI

Invariants T8.12AF-AI :

- L'IA doit lire le contexte commande connu.
- L'IA doit lire le dernier event transporteur si disponible.
- L'IA ne doit pas redemander un numero de commande ou de suivi deja connu.
- Amazon order ID fallback et tracking fallback doivent rester tenant-scoped, exact-match, non ambigus.

## Rate limits et robustesse

Amazon SP-API utilise un modele token bucket. Les limites dependent notamment de l'operation, du couple selling partner/app et des regions/marketplaces.

Implications KeyBuzz :

- pas de polling agressif
- backoff sur throttling
- logs PII-safe
- classification claire des erreurs 401/403/429/400
- UI honnête : "connexion expiree/revoquee" quand l'autorisation est invalide

## Stop conditions pour futures phases Amazon

STOP si :

- URL DEV trouvee en PROD
- `redirect_uri` ne correspond pas a l'env runtime
- state non valide ou non retrouve
- `expected_channel` absent alors que le flow est marketplace-specific
- activation possible sans inbound email visible
- lecture qui ecrit en DB
- hardcoding tenant/seller/email/pays
- build depuis workspace dirty
- Client build sans verification tracking
- rollback/deploy documente avec des commandes runtime directes interdites au lieu de GitOps strict

## Phases recentes a relire avant changement Amazon

- `PH-SAAS-T8.12AM.10-AMAZON-OAUTH-INBOUND-BRIDGE-PROD-PROMOTION-01.md`
- `PH-SAAS-T8.12AO.4-AMAZON-OAUTH-ACTIVATION-BRIDGE-PROD-TRUTH-AUDIT-AND-FIX-01.md`
- `PH-SAAS-T8.12AO.5-AMAZON-OAUTH-KEY248-CLOSURE-AND-START-COUNTRY-CHOICE-HANDOFF-01.md`
- `PH-API-T8.12AI-CONVERSATION-ORDER-TRACKING-LINK-PROD-PROMOTION-01.md`
