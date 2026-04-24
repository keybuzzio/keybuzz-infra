# Contexte KeyBuzz Studio

> Derniere mise a jour : 2026-04-21
> Role : relier Studio au corpus Asphalte/Smoozii et eviter de le traiter comme bruit.

## Definition

KeyBuzz Studio est un Marketing Operating System autonome pour centraliser :

- idees de contenu;
- contenu et versions;
- calendrier editorial;
- assets;
- knowledge base;
- templates;
- learning sources;
- generations IA;
- client intelligence;
- strategy;
- automations;
- reports.

Il est separe du SaaS client, de l'admin, du seller et de l'API support/orders.

## Stack

Front :

- `C:\DEV\KeyBuzz\V3\keybuzz-studio`
- Next.js 16.0.2, React 19.2, TypeScript 5.9, Tailwind 4, Metronic Tailwind React, React Query, dnd-kit.

API :

- `C:\DEV\KeyBuzz\V3\keybuzz-studio-api`
- Fastify 5, TypeScript, PostgreSQL 17, modules par domaine.

Modules API trouves :

- `ai`
- `assets`
- `auth`
- `automation`
- `calendar`
- `client`
- `content`
- `dashboard`
- `generation`
- `health`
- `ideas`
- `knowledge`
- `learning`
- `reporting`
- `templates`

Routes/pages front trouvees :

- auth : `/login`, `/setup`
- studio : `/dashboard`, `/ideas`, `/content`, `/calendar`, `/assets`, `/knowledge`, `/learning`, `/templates`, `/client`, `/strategy`, `/automations`, `/reports`, `/settings`

## Etat documentaire Studio

Sources majeures :

- `STUDIO-ARCHITECTURE.md`
- `STUDIO-MASTER-REPORT.md`
- `STUDIO-RULES.md`
- `STUDIO-WORKFLOW.md`
- rapports `PH-STUDIO-*`

`STUDIO-MASTER-REPORT.md` indique une progression jusqu'a :

- foundation;
- bootstrap DEV/PROD;
- auth OTP/session;
- knowledge/ideas/content MVP;
- assets/calendar/editorial workflow;
- learning engine;
- templates;
- content generation;
- AI gateway text-only;
- multi-model pipeline;
- client intelligence;
- quality engine;
- feedback loop/learning system;
- hotfix insights.

Les manifests locaux peuvent etre en decalage avec ces rapports. Pour Studio, ne jamais conclure depuis les seuls manifests.

## Corpus Asphalte/Smoozii

Le dossier `C:\DEV\KeyBuzz\V3\marketing` est un corpus d'alimentation Studio.

Il contient notamment :

- rapport complet `RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md`;
- 62 documents DOCX analyses dans ce rapport;
- 202 PDFs emails Asphalte dupliques/reprises dans deux dossiers;
- brand books, plateforme de marque, SWOT, manifeste, archetype Smoozii;
- corpus Yann Leonardi;
- landing pages, ads, lead magnets, formulaires, workflows n8n;
- cahiers des charges de produit branding automatise.

Interpretation correcte :

- Asphalte = modele d'inspiration marketing/copywriting/funnel.
- Smoozii = ancien/projet complementaire d'acquisition/conversion automatisee.
- Ces documents alimentent Studio : knowledge, learning sources, templates, client intelligence, strategy, content generation.
- Ils ne doivent pas etre classes comme simple bruit marketing.

## Principes strategiques du corpus

D'apres `RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md` :

- Asphalte sert de modele : precommande, questionnaire, communaute, ton direct, transparence, lean/MVB.
- Smoozii transpose ces principes au B2B acquisition/conversion.
- Le questionnaire est un point d'entree central.
- Le contenu doit etre direct, differenciant, construit autour d'ennemis, armes, ton, manifeste, funnel.
- Le corpus doit etre adapte a KeyBuzz, pas copie tel quel.

## Utilisation dans Studio

Mapping probable :

| Corpus | Module Studio |
|---|---|
| Brand books / plateformes | Knowledge, client profiles, strategy |
| Emails Asphalte | Learning sources, templates, hooks, swipe files |
| Yann Leonardi transcripts | Learning sources, content angles |
| Landing pages / Ads | Templates, content generation, strategy |
| Workflows n8n | Automations |
| Brief Media Buyer KeyBuzz | Client intelligence, ads, tracking |
| Smoozii manifesto/SWOT | Strategy examples, tone system |

## Risques Studio

- Ne pas confondre Studio et client SaaS : bases, API et auth sont separees.
- NEXT_PUBLIC vars sont build-time : PROD front doit etre rebuild avec URL API PROD, pas re-tag de DEV.
- Ne pas exposer de cles LLM dans docs/logs.
- Ne pas importer tout le corpus brut en un seul prompt : preferer ingestion par sources/categories.
- Ne pas appliquer la tonalite Smoozii brute a KeyBuzz sans adaptation produit.

## Strategie d'ingestion Studio recommandee

1. Creer un index des sources marketing.
2. Classer par type : brand, swipe email, funnel, ad, landing, workflow, transcript.
3. Extraire pour chaque source : promesse, cible, angle, ton, structure, hooks, CTA, exemples.
4. Stocker dans Studio comme knowledge/learning source.
5. Generer des templates KeyBuzz adaptes : LinkedIn, Reddit, email, landing, ads, media buyer.

