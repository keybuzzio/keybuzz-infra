# Phases, features et agents Cursor

> Derniere mise a jour : 2026-04-21
> Role : expliquer comment utiliser les rapports `PH*` pour comprendre KeyBuzz et piloter les agents Cursor.

## Verite importante

Les fichiers `PH*` dans `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs` ne sont pas de simples notes.

Ils sont l'historique de creation, correction, audit, validation et promotion des features KeyBuzz avec des agents ChatGPT/Cursor. Ils forment la memoire produit operationnelle.

Un agent qui ignore les `PH*` risque de :

- refaire une phase deja terminee;
- casser une regle produit validee;
- confondre DEV/PROD;
- utiliser une ancienne source de verite;
- prompt Cursor sans rollback ni preuves;
- oublier une contrainte historique acquise douloureusement.

## Role de Codex et des agents Cursor

Modele de travail voulu par Ludovic :

- Codex local lit, structure, retient le contexte, controle les sources et produit des prompts detailles.
- Les agents Cursor sont les mains d'execution sur le SaaS.
- Les prompts Cursor doivent etre precis, bornes, sources, avec fichiers a lire, interdits, tests, rollback et rapport attendu.

Cette logique est deja documentee dans :

- `PROMPT-NOUVEL-AGENT.md`
- `PH147.RULES-CURSOR-PROCESS-LOCK-01.md`
- `.cursor/rules/process-lock.mdc`
- `.cursor/rules/git-source-of-truth.mdc`
- `.cursor/rules/deployment-safety.mdc`

## Inventaire PH

Passe locale du 2026-04-21 :

- `docs` contient 1 005 fichiers directs.
- 956 fichiers commencent par `PH`.
- `RECAPITULATIF PHASES.md` recense les grandes familles de phases.
- `FEATURE_TRUTH_MATRIX_V2.md` et `feature_registry.json` donnent la matrice produit/feature.

Comptage approximatif par nom de fichier, avec recouvrements possibles :

| Domaine | Nombre approx. |
|---|---:|
| Infra / SRE / GitOps | 195 |
| IA engines / IA | 138 |
| Inbox / Client UI | 97 |
| Auth / RBAC / Agents | 73 |
| Billing / Stripe / KBActions | 71 |
| Orders / SLA / tracking colis | 56 |
| Amazon | 54 |
| Autopilot | 48 |
| Admin v2 | 48 |
| Tracking marketing | 43 |
| Seller | 38 |
| Features truth / registry | 23 |
| DB / migration | 22 |
| Studio | 17 |
| Shopify | 17 |
| Octopia | 13 |

Ces chiffres sont des aides de navigation, pas des limites strictes : une phase peut toucher plusieurs domaines.

## Carte chronologique utile

Source principale : `RECAPITULATIF PHASES.md`.

| Famille | Contenu durable |
|---|---|
| PH0-PH19 | Auth, espaces, SES/mail, Stripe, tenant context, Amazon foundations, inbound/outbound, orders, RBAC. |
| PH24-PH37 | UI, Amazon/Octopia, orders, KBActions, suppliers, tracking, parity DEV/PROD, audit global. |
| PH42-PH69 | Premiers moteurs IA SAV : historique, policy tenant, decision tree, risk, refund protection, memory, compression, escalation, stability guard. |
| PH70-PH86 | Orchestration, case autopilot, execution, approval queue, followup, ops center, debut admin v2. |
| PH90-PH117 | Moteurs IA avances : cost, buyer reputation, marketplace policy, optimizer, learning, seller DNA, governance, knowledge graph, real execution, AI dashboard. |
| PH118-PH126 | Role access, agent foundation, escalation, assignment, workbench, priorite. |
| PH127-PH135 | AI assist, supervision IA, plans, gating, autopilot settings/engine/drafts, email pipeline, Amazon threading. |
| PH136-PH139 | GitOps rollback, tracking transporteur, coherence IA, signature/identite. |
| PH140-PH143 | Agents, invitations, supervision, feature registry, validation, rebuild, francisation, release line, promotions PROD. |
| PH145-PH152 | Autopilot truth recovery, guardrails, source-of-truth, recovery DEV depuis PROD, Inbox/client reconstruction. |
| PH-T* | Tracking marketing/SaaS, Addingwell/SGTM, spend, metrics admin trial/paid. |
| PH-STUDIO* | Studio : foundation, auth, knowledge, ideas, content, calendar, learning, templates, AI gateway, client intelligence, quality. |
| PH-S* | Seller : foundations, catalog sources, FTP/matching, seller client/API. |
| PH-INFRA / PH-SRE / PH-VAULT | Firewalls, K8s, Vault, observability, hardening, bastions, install. |
| PH-ADMIN* | Admin v2, metrics, feature flags, internal API, control center. |

## Regle de lecture pour prompt Cursor

Avant de rediger un prompt Cursor :

1. Identifier le domaine : client, API, admin, Studio, seller, infra, billing, tracking, IA, Autopilot.
2. Lire `AI_MEMORY/CURRENT_STATE.md`.
3. Lire le fichier domaine `AI_MEMORY/*_CONTEXT.md`.
4. Lire `RECAPITULATIF PHASES.md` sur la tranche concernee.
5. Lire les rapports PH recents du domaine, pas seulement leur nom.
6. Verifier si une phase plus recente annule, corrige ou promeut une phase plus ancienne.
7. Donner a Cursor une liste de fichiers source a lire avant modification.
8. Exiger DEV avant PROD, rollback, validation et rapport PH final.

## Structure obligatoire d'un prompt Cursor

Un prompt Cursor KeyBuzz doit contenir :

- role : agent senior KeyBuzz, reponse en francais;
- contexte : ce que KeyBuzz fait et quelle surface est concernee;
- sources obligatoires : `AI_MEMORY` + rapports PH precis + fichiers code/manifests;
- objectif unique de la phase;
- verrou branche/source de build si la phase peut builder : repo exact, branche autorisee, commit attendu, repo clean, tag cible, digest, rollback;
- interdits explicites;
- plan de verification;
- stop conditions;
- livrable attendu : patch, tests, image/tag si deploy, rollback, rapport dans `keybuzz-infra/docs`.

## Stop conditions heritees PH147

Arreter et demander validation si :

- source de verite douteuse;
- repo dirty non explique;
- divergence Git/runtime;
- page blanche ou regression visible;
- besoin PROD non valide explicitement par Ludovic;
- secret/credential necessaire non disponible;
- changement trop large par rapport a la phase.

## Limite de cette memoire

Cette fiche integre la carte et le mode d'emploi des 956 phases, mais elle ne remplace pas les rapports bruts.

Pour une action concrete, l'agent doit relire les PH sources du domaine. La memoire sert a savoir quoi lire, dans quel ordre, et quels pieges ne pas oublier.
