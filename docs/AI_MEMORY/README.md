# Memoire IA KeyBuzz

> Derniere mise a jour : 2026-04-21
> Objectif : permettre a Codex/Cursor/agent IA de reprendre KeyBuzz sans repartir de zero.

## Lecture obligatoire

Avant de produire un prompt Cursor ou de modifier le projet, lire dans cet ordre :

1. `CURRENT_STATE.md` - etat courant synthetique et point de reprise.
2. `PROJECT_OVERVIEW.md` - vision produit/tech globale.
3. `RULES_AND_RISKS.md` - regles absolues et pieges connus.
4. `DOCUMENT_MAP.md` - carte des familles documentaires.
5. `OPERATIONAL_SURFACES.md` - carte des apps/services : client, admin, Studio, seller, API.
6. `PHASES_FEATURES_AND_CURSOR_CONTEXT.md` - role des PH, features et agents Cursor.
7. Le fichier de domaine concerne : `CLIENT_CONTEXT.md`, `API_AUTOPILOT_CONTEXT.md`, `ADMIN_CONTEXT.md`, `STUDIO_CONTEXT.md`, `SELLER_CONTEXT.md`, `INFRA_CONTEXT.md`, `INFRA_SERVERS_INSTALL_CONTEXT.md`, `FEATURES_DEPLOYED_CONTEXT.md` ou `MARKETING_CORPUS_INDEX.md`.
8. `CONTEXT_STRATEGY.md` - strategie pour garder la memoire lisible malgre le volume.
9. `SOURCE_INDEX.md` - sources de verite et documents a consulter.
10. `CURSOR_HANDOFF_PROMPT.md` - prompt pret a donner a un agent Cursor.
11. Les rapports de phase cites dans `CURRENT_STATE.md`.

## Regle de maintenance

Apres chaque nouvelle phase importante :

- ajouter le rapport source dans `SOURCE_INDEX.md`;
- mettre a jour le point de reprise dans `CURRENT_STATE.md`;
- si la suite attendue change, mettre a jour `CURSOR_HANDOFF_PROMPT.md`;
- ne jamais remplacer les rapports de phase par la memoire : la memoire est un index, pas la source brute.

## Statut de cette memoire

Cette premiere version consolide les documents locaux trouves le 2026-04-21, avec focus sur :

- conversation complete `KeyBuzz_2026_complet_2026-04-21.txt`;
- recapitulatif des phases;
- rapports recents Autopilot, Inbox, Source-of-truth, Playbooks, Tracking, Metrics/Admin;
- documents structurants DB, Feature matrix, Studio, Admin, Marketing, Seller;
- corpus Asphalte/Smoozii comme alimentation Studio, pas comme bruit documentaire;
- 956 rapports `PH*` comme memoire produit/feature et base des prompts Cursor;
- prompt historique pour nouvel agent.

Volume inventorie hors dependances/builds : 2 119 documents.
