# Strategie de contexte IA

> Derniere mise a jour : 2026-04-21
> Objectif : garder une memoire fiable sans creer un fichier geant inutilisable.

## Principe

La memoire IA ne doit pas recopier tous les rapports. Elle doit fonctionner comme :

- une carte;
- une synthese;
- un index de sources;
- un systeme de reprise.

Les rapports de phase restent les sources brutes. `AI_MEMORY` sert a savoir lesquels lire et dans quel ordre.

## Fichiers de contexte actuels

| Fichier | Role | Taille cible |
|---|---|---|
| `README.md` | Point d'entree | tres court |
| `CURRENT_STATE.md` | Etat courant et prochaine decision | court |
| `PROJECT_OVERVIEW.md` | Vision globale produit/tech | moyen |
| `OPERATIONAL_SURFACES.md` | Carte client/admin/studio/seller | moyen |
| `PHASES_FEATURES_AND_CURSOR_CONTEXT.md` | Role des PH et agents Cursor | moyen |
| `CLIENT_CONTEXT.md` | Client SaaS + BFF | moyen |
| `API_AUTOPILOT_CONTEXT.md` | API, IA, Autopilot, billing | moyen |
| `ADMIN_CONTEXT.md` | Admin v2 | court/moyen |
| `STUDIO_CONTEXT.md` | Studio + corpus Asphalte/Smoozii | moyen |
| `SELLER_CONTEXT.md` | Seller / seller-dev | court/moyen |
| `INFRA_CONTEXT.md` | Infra, K8s, DB, GitOps | moyen |
| `INFRA_SERVERS_INSTALL_CONTEXT.md` | Serveurs et sommaire installation | moyen/long |
| `FEATURES_DEPLOYED_CONTEXT.md` | Etat features deployees | moyen |
| `MARKETING_CORPUS_INDEX.md` | Index Asphalte/Smoozii pour Studio | moyen |
| `DOCUMENT_MAP.md` | Carte documentaire | moyen |
| `RULES_AND_RISKS.md` | Regles, pieges, stop conditions | court |
| `SOURCE_INDEX.md` | Sources de verite prioritaires | moyen |
| `CURSOR_HANDOFF_PROMPT.md` | Prompt Cursor initial | court |

## Quand creer un nouveau fichier

Creer ou scinder un fichier dedie si un domaine devient trop gros :

- scinder `CLIENT_CONTEXT.md` en `INBOX_CONTEXT.md` si Inbox redevient active;
- scinder `API_AUTOPILOT_CONTEXT.md` en `BILLING_CONTEXT.md` ou `CONNECTORS_CONTEXT.md` si besoin;
- scinder `MARKETING_CORPUS_INDEX.md` par canal si l'ingestion Studio commence.

Ne pas agrandir indefiniment `PROJECT_OVERVIEW.md`.

## Regle de mise a jour apres une phase

Apres chaque nouvelle phase :

1. Ajouter le rapport dans `SOURCE_INDEX.md`.
2. Mettre a jour `CURRENT_STATE.md` si le point de reprise change.
3. Mettre a jour le fichier de domaine seulement si la phase change la comprehension durable.
4. Ne pas recopier le rapport complet.

## Lecture minimale dans une nouvelle conversation

Si le contexte est limite :

1. `CURRENT_STATE.md`
2. `RULES_AND_RISKS.md`
3. `OPERATIONAL_SURFACES.md`
4. `PHASES_FEATURES_AND_CURSOR_CONTEXT.md`
5. le fichier de domaine concerne
6. le rapport de phase le plus recent du domaine

## Lecture complete recommandee

Si on veut comprendre KeyBuzz "par coeur" :

1. Tout `AI_MEMORY`
2. `RECAPITULATIF PHASES.md`
3. `DB-ARCHITECTURE-CONTRACT.md`
4. `FEATURE_TRUTH_MATRIX_V2.md`
5. `feature_registry.json`
6. `STUDIO-MASTER-REPORT.md`
7. `RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md`
8. Les derniers rapports du domaine actif
9. Le code local correspondant
