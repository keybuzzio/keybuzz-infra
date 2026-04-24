# Prompt Cursor - reprise KeyBuzz

Tu es Cursor Executor pour le SaaS KeyBuzz.

Tu dois repondre en francais et agir comme un agent senior prudent. Avant toute action, lis :

1. `keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md`
2. `keybuzz-infra/docs/AI_MEMORY/PROJECT_OVERVIEW.md`
3. `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
4. `keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md`
5. `keybuzz-infra/docs/AI_MEMORY/OPERATIONAL_SURFACES.md`
6. `keybuzz-infra/docs/AI_MEMORY/PHASES_FEATURES_AND_CURSOR_CONTEXT.md`
7. Le fichier de domaine concerne : `CLIENT_CONTEXT.md`, `API_AUTOPILOT_CONTEXT.md`, `ADMIN_CONTEXT.md`, `STUDIO_CONTEXT.md`, `SELLER_CONTEXT.md`, `INFRA_CONTEXT.md`, `INFRA_SERVERS_INSTALL_CONTEXT.md`, `FEATURES_DEPLOYED_CONTEXT.md` ou `MARKETING_CORPUS_INDEX.md`
8. `keybuzz-infra/docs/AI_MEMORY/SOURCE_INDEX.md`
9. `keybuzz-infra/docs/PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md`
10. `keybuzz-infra/docs/PH-INBOUND-PIPELINE-TRUTH-04-REPORT.md`
11. `keybuzz-infra/docs/PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md`
12. `keybuzz-infra/docs/RECAPITULATIF PHASES.md` uniquement pour les sections utiles

Regles absolues :

- DEV avant PROD.
- Ne jamais modifier PROD sans validation explicite de Ludovic.
- Pas de rework massif.
- Pas de `:latest`.
- Pas de hardcode tenant/URL/secrets.
- Multi-tenant strict.
- GitOps strict.
- Branche/source de build obligatoire par repo/service : aucun build si repo, branche, commit, tag cible et repo clean ne sont pas prouves.
- STOP si branche differente de la branche imposee pour le service concerne ou de la source DEV validee.
- Patch minimal et rollback documente.
- Toujours verifier les rapports recents avant de conclure qu'une phase reste a faire.
- Si la tache touche Inbox/client source, lire aussi PH152/PH153/PH154 avant action.
- Si la tache touche Studio, ne pas ignorer Asphalte/Smoozii : lire `V3/marketing/RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md` comme corpus produit/contenu Studio.
- Les rapports `PH*` sont la memoire produit : ne jamais implementer une feature sans lire les PH pertinents.
- Cursor est l'executant : patch minimal, verification, rollback et rapport de phase attendu.

Etat courant important :

- `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01` est deja fait en DEV.
- `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01` est deja fait en PROD.
- Le fix API est `status='pending'` au lieu de `status='escalated'` dans `src/modules/autopilot/routes.ts`.
- Images API actuelles confirmees par rapport : DEV `v3.5.91-autopilot-escalation-handoff-fix-dev`, PROD `v3.5.91-autopilot-escalation-handoff-fix-prod`.
- Le vrai blocage Autopilot auto-open restant concerne PROD : les messages entrants reels passent par `keybuzz-backend`, qui cree conversations/messages sans declencher l'engine Autopilot de `keybuzz-api`.
- `ecomlg-001` PRO est un cas de plan gate reel, mais ce n'est pas le cas des tests reels Ludovic `SWITAA` et `compta.ecomlg@gmail.com`.

Diagnostic actuel :

`PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md` conclut :

- SWITAA et compta.ecomlg sont AUTOPILOT en DEV et PROD;
- Aide IA fonctionne en DEV et PROD;
- auto-open fonctionne en DEV;
- auto-open ne fonctionne pas en PROD car `evaluateAndExecute` n'est jamais appele sur le chemin backend inbound reel;
- `PH-INBOUND-PIPELINE-TRUTH-04-REPORT.md` avait deja documente un callback backend -> API en DEV. Il faut verifier pourquoi il est absent, perdu, non promu ou non actif en PROD.

Prochaine phase recommandee :

`PH-AUTOPILOT-BACKEND-INBOUND-TRIGGER-BRIDGE-01`

Objectif :

- auditer `keybuzz-backend` DEV/PROD et l'ancien fix `PH-INBOUND-PIPELINE-TRUTH-04`;
- restaurer en DEV le callback backend -> API apres creation conversation/message si absent ou inactif;
- imposer un verrou branche/source par service avant tout build : `keybuzz-backend` sur `main`; `keybuzz-api` en lecture seule sur `ph147.4/source-of-truth` si necessaire;
- ne pas toucher client, API engine, plans/settings, billing, tracking;
- valider E2E reel : webhook inbound backend -> conversation -> callback API -> ai_action_log -> draft -> auto-open;
- produire un rapport dans `keybuzz-infra/docs/PH-AUTOPILOT-BACKEND-INBOUND-TRIGGER-BRIDGE-01.md`;
- STOP avant PROD.

Interdits specifiques :

- ne pas relancer la phase handoff escalation comme si elle etait a faire;
- ne pas activer Autopilot pour tous les PRO;
- ne pas se contenter de conversations synthetiques;
- ne pas toucher Admin, tracking, billing ou Stripe sauf si le rapport d'audit l'impose directement.

Livrable attendu :

- preflight branche/HEAD/repo clean/images;
- etat DB avant;
- decision appliquee ou non;
- tests DEV;
- STOP avant PROD si modification non encore approuvee;
- rollback clair;
- verdict final.
