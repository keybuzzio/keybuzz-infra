# Index corpus marketing / Studio

> Derniere mise a jour : 2026-04-21
> Role : orienter l'ingestion Studio du corpus Asphalte/Smoozii sans tout charger en un prompt.

## Principe

Le dossier `C:\DEV\KeyBuzz\V3\marketing` est un corpus d'alimentation pour KeyBuzz Studio.

Il ne sert pas a trancher :

- architecture infra;
- etat runtime;
- DB;
- plan gate;
- deploiement.

Il sert a nourrir :

- Knowledge;
- Learning;
- Templates;
- Strategy;
- Client Intelligence;
- Content Generation;
- Quality Engine;
- briefs et prompts Studio.

## Source pivot

`C:\DEV\KeyBuzz\V3\marketing\RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md`

Ce rapport compile 62 DOCX et donne une vision structuree :

- marketing;
- branding;
- contenu;
- automatisation;
- scaling;
- Asphalte comme modele;
- Smoozii comme transposition B2B acquisition/conversion;
- adaptation a KeyBuzz/Studio.

## Dossiers principaux observes

Sous `V3\marketing\Marketing` :

- `Automatisations`
- `Branding`
- `Branding\Asphalte`
- `Branding\Asphalte\Emails`
- `Branding\Asphalte\Lancement - Claire Gerbier`
- `Branding\Asphalte\Pages`
- `Branding\Asphalte\Transcriptions`
- `Content`
- `Content\Ads`
- `Content\Formulaires`
- `Content\Global`
- `Content\Landing Pages`
- `Content\Leads Magnet`
- `Content\Message marketing (SMS-Mail-Chat)`
- `Content\Videos`
- `Design`
- `Design\Personnages`
- `Design\Site`
- `Scalling`
- `Smoozii vs Asphalte`
- `Smoozii vs Asphalte\Email Asphalte`
- `yann-leonardi-transcripts`

## Mapping Studio

| Corpus | Usage Studio |
|---|---|
| Brand book / plateforme / manifeste | Knowledge, strategy, client profiles |
| SWOT / archetype | Strategy, quality criteria, positioning |
| Emails Asphalte | Templates, hooks, swipe files, learning sources |
| Landing pages | Templates, page generation, audit funnel |
| Ads / media buyer | Campaign briefs, ad templates, client intelligence |
| Lead magnets / formulaires | Conversion assets, funnel templates |
| Workflows n8n | Automations, process templates |
| Transcriptions Yann Leonardi | Learning, angles, long-form content |
| Smoozii vs Asphalte | Adaptation model, strategic reasoning |

## Methode d'ingestion recommandee

Pour chaque source :

1. Identifier le type : email, landing, ad, brand, workflow, transcript, form.
2. Extraire cible, promesse, douleur, angle, ton, structure, CTA.
3. Classer en knowledge/learning/template.
4. Ajouter tags : marque, canal, niveau funnel, intention, format.
5. Produire une version adaptee KeyBuzz/Studio.
6. Ne pas copier le texte brut sans adaptation.

## Attention

- Asphalte est un modele d'inspiration, pas une marque a cloner.
- Smoozii est une base strategique utile, pas forcement le produit final.
- KeyBuzz Studio doit transformer ce corpus en systeme exploitable pour plusieurs clients.
- Eviter un import massif non structure : preferer petits lots verifies.
