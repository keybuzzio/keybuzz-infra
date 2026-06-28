# PH-SAAS-T8.12AS.21.192 - READONLY DESIGN AI RESPONSE HUMANNESS AND AUTO DRAFT QUALITY DEV PROD

Date: 2026-06-28
Mode: READONLY DESIGN
Verdict: READY_SOURCE_PATCH_REQUIRED

## Objectif

Designer l'amelioration de qualite des reponses IA KeyBuzz pour:

- les generations manuelles AI Assist;
- les brouillons auto-generes Autopilot;
- la coherence tonale entre generation ponctuelle, brouillons, guardrails marketplace et signatures.

Hors scope de cette phase:

- aucun patch source;
- aucun build, push image, deploy ou apply;
- aucun appel LLM reel;
- aucun event fake;
- aucune mutation DB;
- aucune modification de KBActions, billing, tracking, Stripe, Website, Client ou Admin.

## Sources relues

- keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
- modele PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01
- keybuzz-api/src/modules/ai/ai-assist-routes.ts
- keybuzz-api/src/modules/autopilot/engine.ts
- keybuzz-api/src/modules/ai/shared-ai-context.ts
- keybuzz-api/src/services/customerToneEngine.ts
- keybuzz-api/src/services/customerEmotionEngine.ts
- keybuzz-api/src/services/tenantPolicyLoader.ts
- keybuzz-api/src/services/marketplacePolicyEngine.ts
- keybuzz-api/src/lib/amazonReplyGuard.ts
- keybuzz-api/src/services/promptStabilityGuard.ts
- keybuzz-api/src/services/playbook-engine.service.ts

## Etat source observe

| Surface | Fichier | Constat |
|---|---|---|
| AI Assist | src/modules/ai/ai-assist-routes.ts | Prompt systeme construit par buildSystemPrompt, puis chatCompletion(feature=assist). |
| Autopilot | src/modules/autopilot/engine.ts | Prompt systeme local duplique, puis chatCompletion(feature=autopilot). |
| Contexte partage | src/modules/ai/shared-ai-context.ts | getScenarioRules, getWritingRules, buildEnrichedUserPrompt deja utilises. |
| Tone engine | src/services/customerToneEngine.ts | Moteur tonal existant, mais non integre comme bloc central obligatoire dans les deux prompts principaux. |
| Emotion engine | src/services/customerEmotionEngine.ts | Guidance emotionnelle existante, mais pas le standard unique de redaction finale. |
| Tenant policy | src/services/tenantPolicyLoader.ts | Peut injecter tone_style/custom_instructions tenant. |
| Marketplace safety | src/services/marketplacePolicyEngine.ts, amazonReplyGuard.ts | Garde-fous Amazon/marketplace presents; ne doivent pas etre affaiblis. |
| Playbooks | src/services/playbook-engine.service.ts | Les playbooks sont surtout templates/actions; ne pas casser activation, KBActions ou read-repair. |

## Diagnostic

Les prompts contiennent deja des consignes utiles:

- "Ton naturel, chaleureux et professionnel";
- phrases courtes;
- pas de promesse impossible;
- ne pas redemander les donnees connues;
- signature tenant;
- garde-fous marketplace et anti-remboursement/anti-promesse.

Mais le systeme reste insuffisant pour obtenir un rendu plus humain de facon fiable:

1. Le bloc de style est trop generique.
2. AI Assist et Autopilot dupliquent une partie des consignes.
3. Le moteur CustomerTone existe mais n'est pas la source de verite unique du style final.
4. Les consignes "humaines" ne distinguent pas assez:
   - empathie courte et utile;
   - absence de phrases robotiques;
   - adaptation a la langue du client;
   - reponse prete a envoyer sans formule artificielle;
   - preservation des faits, guardrails et signatures.
5. La demande de type "/humain" ne doit pas etre implementee comme un mot magique provider-specific. Elle doit etre convertie en politique de redaction deterministe, testable, stable entre modeles.

## Decision produit recommandee

Ajouter un standard KeyBuzz de "reponse humaine marketplace-safe":

- humain, direct, chaleureux, mais jamais familier;
- naturel dans la langue du client;
- empathie precise, pas de boilerplate;
- une reponse qui avance le dossier;
- pas de promesse que KeyBuzz ne peut pas executer;
- pas de re-demande d'information deja connue;
- pas de faux aveu de responsabilite;
- pas de faux engagement de remboursement, investigation ou contact;
- priorite absolue aux donnees de commande, tracking, historique, marketplace et tenant policy;
- signature preservee.

## Patch source recommande

Phase suivante: GO SOURCE PATCH AI RESPONSE HUMANNESS AND AUTO DRAFT QUALITY DEV PH-SAAS-T8.12AS.21.193

Patch API DEV uniquement au depart.

Fichiers probables:

- src/modules/ai/shared-ai-context.ts
- src/modules/ai/ai-assist-routes.ts
- src/modules/autopilot/engine.ts
- src/services/customerToneEngine.ts si besoin d'exposer un helper existant
- nouveau test source PH-21.193

Implementation proposee:

1. Ajouter un helper central dans shared-ai-context, par exemple buildHumanReplyQualityRules(signatureText?).
2. Faire utiliser ce helper par:
   - buildSystemPrompt dans ai-assist-routes.ts;
   - le systemPrompt Autopilot dans autopilot/engine.ts.
3. Eviter toute divergence de style entre assist et autopilot.
4. Garder getScenarioRules, getWritingRules, GUARDRAIL_SYSTEM_RULES, marketplacePolicyEngine, amazonReplyGuard et tenantPolicyLoader actifs.
5. Ne pas modifier les contrats JSON Autopilot.
6. Ne pas changer model, temperature, KBActions, budget, billing, tracking ni dispatch.

## Regles de redaction cible

Le bloc central doit imposer:

- Ecrire comme un agent support humain experimente, pas comme un chatbot.
- Premier paragraphe court: reconnaissance de la demande + fait utile.
- Puis action ou information concrete.
- Eviter les formules creuses:
  - "Je comprends votre frustration" repete mecaniquement;
  - "Nous sommes desoles pour la gene occasionnee" sans suite utile;
  - "Je vais investiguer" si l'IA ne peut pas le faire;
  - "Je reviens vers vous" si aucun follow-up n'est reellement cree.
- Remplacer les promesses impossibles par une transmission claire a l'equipe humaine si necessaire.
- Ne jamais inventer date, transporteur, statut, geste commercial, remboursement ou politique vendeur.
- Ne pas redemander numero de commande/tracking si connu.
- Si aucune commande n'est liee, demander uniquement l'information minimale utile.
- Adapter le ton:
  - POLITE: courtois, simple, utile;
  - EMPATHETIC: reconnaitre le probleme, puis proposer une etape claire;
  - NEUTRAL: factuel et methodique;
  - FIRM: calme, cadrant, sans confrontation;
  - LEGAL_SAFE: strictement factuel, sans admission de responsabilite.
- Respecter la langue du client.
- Respecter la signature tenant exacte si fournie.

## AI feature parity / anti-regression

Le patch ne doit pas casser:

- AI Assist manuel;
- brouillons Autopilot;
- signatures tenant;
- KBActions;
- playbooks IA actifs;
- mode Focus;
- Agent KeyBuzz;
- human approval queue;
- guardrails marketplace;
- refund protection;
- no-reply classifier;
- false promise detection;
- Amazon/system message guard;
- on-demand order import;
- budget/credits checks;
- logs/audit existants.

Les tests doivent prouver:

- le bloc human quality est present dans AI Assist;
- le bloc human quality est present dans Autopilot;
- Autopilot conserve le schema JSON;
- les guardrails restent injectes;
- les signatures restent injectees;
- les interdictions de promesse impossible restent presentes;
- aucun call LLM reel n'est lance par les tests;
- aucune mutation DB n'est necessaire.

## No fake metrics / no fake events

Interdits pour cette chaine:

- pas de faux message client en PROD;
- pas de POST /funnel/event;
- pas d'appel CAPI;
- pas de checkout Stripe;
- pas de fake conversion;
- pas de faux KBActions;
- pas de trigger Autopilot reel sans GO explicite;
- pas d'appel LLM live pendant design/source tests.

## Tests recommandes pour PH-21.193

| Test | Attendu |
|---|---|
| git diff --check | PASS |
| test unitaire PH-21.193 prompt AI Assist | Human quality block present, guardrails presents |
| test unitaire PH-21.193 prompt Autopilot | Human quality block present, JSON contract preserved |
| test signature | Signature instruction preserved |
| test anti-promesse | Promesses impossibles toujours interdites |
| test marketplace | Amazon/channel block preserved |
| npx tsc --noEmit | PASS |

## Plan DEV -> PROD

1. PH-21.193 source patch API DEV.
2. PH-21.194 push source patch.
3. PH-21.195 build API DEV.
4. PH-21.196 push image API DEV.
5. PH-21.197 apply API DEV GitOps.
6. PH-21.198 read-only verify DEV.
7. PH-21.199 close DEV.
8. Promotion PROD separee seulement si DEV est stable et avec GO explicite.

## Risques

| Risque | Mitigation |
|---|---|
| Reponses plus humaines mais moins safe | Garder guardrails, marketplace policy, false promise detection et refund protection au-dessus du style. |
| Divergence Assist/Autopilot | Helper central partage. |
| Output Autopilot JSON casse | Tests specifiques schema JSON. |
| Trop de chaleur/familiarite | Instructions: chaleureux mais professionnel, pas familier. |
| Regression signatures | Test signature obligatoire. |

## Verdict

READY_SOURCE_PATCH_REQUIRED.

La qualite/humanisation IA doit etre traitee par un patch API DEV centralise dans les prompts, sans changer les modeles, sans mutation business et sans affaiblir les garde-fous.

Prochain GO recommande:

GO SOURCE PATCH AI RESPONSE HUMANNESS AND AUTO DRAFT QUALITY DEV PH-SAAS-T8.12AS.21.193

STOP.
