# AI Messaging Feature Parity Baseline

> Derniere mise a jour : 2026-05-06
> Statut : regle obligatoire pour prompts CE touchant IA, Inbox, messaging, connecteurs, commandes, tracking colis, playbooks, escalades ou autopilot.

## Objectif

Eviter les regressions invisibles ou les rebuilds "a vide" sur les features IA KeyBuzz deja construites dans les phases PH precedentes.

Avant tout patch, build, promotion ou audit lie aux messages/IA, CE doit prouver la realite actuelle de chaque brique impliquee :

- source Git propre;
- runtime aligne avec GitOps;
- rapport PH recent;
- comportement API/runtime;
- comportement UI;
- ticket Linear si ecart.

## Regles obligatoires

1. Rechercher les rapports PH pertinents dans `keybuzz-infra/docs` avant toute conclusion.
2. Ne pas supposer qu'une feature existe parce que l'UI l'affiche.
3. Ne pas supposer qu'une feature est absente parce qu'un cas utilisateur echoue.
4. Verifier la chaine complete : conversation -> commande -> tracking -> contexte IA -> brouillon -> garde-fous -> escalade -> audit.
5. STOP si la source de build ne peut pas etre prouvee ou si runtime et Git divergent.
6. Creer ou mettre a jour Linear pour chaque gap confirme, avec acceptance criteria.
7. Ne jamais hardcoder tenant, seller, marketplace, pays, user, email de test, nom de client ou compte externe.

## Points a verifier systematiquement

### Ne pas redemander les donnees connues

L'IA ne doit pas demander au client final un numero de commande ou de suivi si KeyBuzz peut deja le connaitre via :

- conversation.order_ref;
- orders.external_order_id;
- orders.tracking_code;
- tracking_events.tracking_code;
- fallback Amazon order ID dans les messages;
- fallback UPS/transporteur distinctif dans les messages;
- lien conversation -> commande restaure par les phases PH-API-T8.12AF/AH/AH.1/AI.

Toute regression sur ce point est P0 avant lancement Ads.

### Escalade

Toute escalade doit etre lisible et assignable :

- escalade vers agent du client si le plan/module le prevoit;
- escalade vers Agent KeyBuzz uniquement si le module Agent KeyBuzz est achete et active dans les parametres;
- responsable nomme ou file d'attente explicite;
- statut et destination visibles dans l'Inbox ou le journal;
- pas de claim "Equipe KeyBuzz gere" sans veritable workflow humain documente.

### Seller-first et platform-aware

Verifier que les suggestions IA conservent :

- doctrine seller-first;
- pas de remboursement premature;
- protection marge;
- posture marketplace_strict pour Amazon/Octopia;
- posture direct_seller_controlled pour Shopify/email;
- blocage auto-send sur cas risques.

### Audit complet IA

Les audits doivent couvrir au minimum :

- prompt et contexte IA;
- refund protection;
- response strategy;
- buyer risk/reputation;
- tracking/livraison;
- pieces jointes/preuves;
- playbooks;
- KBActions;
- score de confiance;
- journal IA;
- Autopilot/Agent KeyBuzz;
- Inbox UI.

## Prompt CE obligatoire

Tout prompt CE concerne doit inclure une section :

`AI feature parity / anti-regression`

avec une matrice :

| Feature documentee | Rapport/source | Source actuelle | Runtime | UI | Gap | Linear |
|---|---|---|---|---|---|---|

## Linear

Tout gap confirme doit etre inscrit dans Linear avant de passer a une autre grande feature.

Priorite recommandee :

- P0 : regression visible client, claim marketing faux, risque de perte d'argent vendeur;
- P1 : feature vendue partielle, besoin avant Ads;
- P2 : roadmap produit importante;
- P3 : polish/documentation.
