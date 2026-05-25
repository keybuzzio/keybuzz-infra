# PH-SAAS-T8.12AS.20.13A-PRODUCT-DECISION-KBACTIONS-VALUE-ANXIETY-UX-01

> Date : 2026-05-25
> Linear : KEY-231 primary ; KEY-337 parent PH-20 ; references KEY-348 / KEY-312 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-349
> Phase : PH-SAAS-T8.12AS.20.13A-PRODUCT-DECISION-KBACTIONS-VALUE-ANXIETY-UX
> Environnement : PRODUCT DECISION / DOCS ONLY (no runtime change, no source change, no DB, no fake metrics)

## VERDICT

GO PRODUCT DECISION KBACTIONS VALUE ANXIETY UX READY PH-SAAS-T8.12AS.20.13A

Decision : les recommandations P1 de l audit PH-20.13 sont APPROUVEES POUR PATCH CLIENT dans leur intention (retirer effet taximetre, retirer fuite USD, wording oriente valeur), MAIS toute formulation chiffree "N reponses preparees" derivee de `callsToday`, `callsToday * 4`, `used7d.kbActionsUsed / cout_moyen` ou tout ratio arbitraire est REFUSEE : verification source prouve que ces compteurs sont semantiquement faux pour "reponses preparees". Le chiffre exact "reponses preparees" est DEFERE en P2 (breakdown ai_action_log reason filter). Les valeurs quota exactes deja exposees (`remaining`, `includedMonthly`, `resetAt`) restent autorisees.

Prochaine phrase GO recommandee : **GO SOURCE PATCH CLIENT KBACTIONS VALUE ANXIETY UX DEV PH-SAAS-T8.12AS.20.13B** (patch Client-only DEV des P1 approuves ci-dessous, sans backend, sans metrique inventee).

## Resume executif

Cette phase transforme l audit read-only PH-20.13 en decision produit exploitable, sans aucun patch. Trois verifications source critiques ont ete refaites en lecture seule sur bastion install-v3 pour ancrer chaque decision sur la realite runtime, pas sur une supposition :

1. Effet taximetre CONFIRME LIVE dans `AISuggestionSlideOver.tsx` (lignes 790, 794, 926, 930, 496). C est bien le format que le brief KEY-231 demande d eviter.
2. `AIBudgetBlocked.tsx` est un composant DORMANT : defini mais JAMAIS importe ni rendu ailleurs dans le code Client (seules ses propres lignes le referencent). La fuite `$balanceUsd` + "Code erreur 402" est donc un RISQUE LATENT / hygiene de code, PAS un bug live. Decision : nettoyer quand meme (P1) pour eviter une reactivation accidentelle, mais requalifie en priorite hygiene, pas incident.
3. Les compteurs `callsToday` / `calls7d` exposes par `/ai/wallet/status` proviennent de `COUNT(*) FROM ai_actions_ledger WHERE reason='ai_generation'`. Or `PRE_LLM_BLOCKED` ecrit aussi un debit `ai_generation` (engine.ts:284) SANS produire de reponse. Donc `callsToday` SURCOMPTE : il inclut des debits garde-fou bloques qui n ont genere aucun brouillon. En deduire "N reponses preparees" serait FAUX. L approximation `callsToday * 4` de l audit (P1.4 / P1.6) est doublement invalide : le compteur de base est faux ET le ratio *4 est invente.

Conclusion produit : on garde l intention P1 (UX moins anxiogene, orientee valeur), on retire les chiffres non prouves, on differe le chiffre exact "reponses preparees" vers un breakdown backend P2 (count exact des entries ai_action_log status draft genere), conforme au brief KEY-231 "pas de pollution metrics, pas de faux event".

## Sources relues

| Source | Type | Utilite | Verdict |
|---|---|---|---|
| `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.13-READONLY-PRODUCT-AUDIT-KBACTIONS-VALUE-ANXIETY-UX-01.md` | Audit phase precedente | Recommandations P0/P1/P2/P3 a arbitrer | RELU (370 lignes) |
| `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-CLOSE-01.md` | Phase close | Heritage technique no-reply skip | RELU partiel |
| `keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md` | Etat runtime | Baselines runtime API/Client DEV/PROD | RELU sections recentes |
| `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` | Source operationnelle | Sections 4/4b/5/8b/13 | RELU |
| `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` | Regles absolues | DEV avant PROD, GitOps strict, no fake metrics | RELU |
| Linear KEY-231 | Brief produit Ludovic 2026-04-29 | Intention "levier valeur sans taximetre", contraintes anti-fake | RELU (audit cite verbatim) |
| Linear KEY-337 / KEY-348 | Parent PH-20 + observation differee | Cadre PMF + Ads, observation reelle differee | RELU |
| `keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx` | Source Client | Taximetre wording revalide | RELU (lignes 490-496, 735-755, 790-794, 920-935) |
| `keybuzz-client/src/components/ai/AIBudgetBlocked.tsx` | Source Client | Usage reel verifie (DORMANT) | RELU (greps imports) |
| `keybuzz-client/src/features/ai-ui/AIActionsLimit.tsx` | Source Client | Wording limite atteinte | RELU (lignes 45-56) |
| `keybuzz-client/app/api/ai/wallet/status/route.ts` | BFF Client | strip balanceUsd confirme (ligne 49) | RELU |
| `keybuzz-client/app/billing/ai/manage/page.tsx` | Page Client | 2e ref balanceUsd = champ interface non rendu | RELU (grep) |
| `keybuzz-api/src/config/kbactions.ts` | Source API | autopilot_skipped_no_reply 0.0 + default 6.0 | RELU (lignes 37/53/56/82/91) |
| `keybuzz-api/src/modules/autopilot/engine.ts` | Source API | Step 6.5 skip 0 KBA + PRE_LLM_BLOCKED debit + GUARDRAIL_BLOCKED debit | RELU (lignes 222-293, 312-314) |
| `keybuzz-api/src/modules/ai/credits-routes.ts` | Source API | semantique callsToday/calls7d (ledger reason ai_generation) | RELU (lignes 150-230) |

## Verifications source critiques (read-only)

| # | Point a verifier | Resultat verifie | Implication decision |
|---|---|---|---|
| V1 | Taximetre reel dans `AISuggestionSlideOver` | CONFIRME LIVE : L790 "Consomme des KBActions IA", L794 "KBActions restantes : X", L926 "Consommation : X KBActions", L930 "Solde restant : Y KBActions", L496 actionsRemaining toFixed(2) | P1.2 / P1.3 APPROUVES (reformulation reelle) |
| V2 | `AIBudgetBlocked` utilise ou dormant | DORMANT : 0 import dans src/app/components ; seules les lignes internes du fichier le referencent (interface L5/6, fonction L11, export L59). Affiche `${balanceUsd.toFixed(2)}` L29 + "Code erreur: 402 Payment Required" L53 | P1.1 requalifie HYGIENE / risque latent (pas bug live). APPROUVE quand meme pour eviter reactivation |
| V3 | 2e reference balanceUsd | `app/billing/ai/manage/page.tsx:14` = `balanceUsd?: number` propriete d interface UNIQUEMENT, jamais rendue (aucun `$` ni `USD` dans la page), BFF strip balanceUsd L49 | Champ mort. Inclure dans nettoyage hygiene P1.1, non urgent |
| V4 | no-reply skip 0 KBA preserve | PRESERVE : kbactions.ts:53 `autopilot_skipped_no_reply: 0.0` ; engine.ts:222-249 Step 6.5 `noReply.isNoReply` -> logAction source `autopilot_skipped_no_reply` cout 0 | INCHANGE - aucun patch backend cette phase |
| V5 | PRE_LLM_BLOCKED debit reel preserve | PRESERVE REEL : engine.ts:283-285 `blockKba = computeKBActions('autopilot_draft')` (=6.0 default +/-15%) debite AVANT le block, LLM NON appele. logAction reason PRE_LLM_BLOCKED, blocked=false cote log mais noopResult retourne | P2.2 = decision produit DEFEREE (gratuit vs debite) |
| V6 | Autre debit garde-fou | engine.ts:312-314 GUARDRAIL_BLOCKED debite aussi ~6 KBA mais APRES appel LLM (cout LLM reellement engage) | Nuance P2.2 : PRE_LLM_BLOCKED (sans LLM) candidat gratuit ; GUARDRAIL_BLOCKED (avec LLM) debit justifie |
| V7 | Semantique callsToday/calls7d | `COUNT(*) FROM ai_actions_ledger WHERE reason='ai_generation'` (credits-routes.ts:163-186). PRE_LLM_BLOCKED ecrit un debit ai_generation sans reponse -> callsToday SURCOMPTE | "N reponses preparees" via callsToday = SEMANTIQUEMENT FAUX -> REFUSE |
| V8 | Donnees exactes deja exposees safe | `kbActions.remaining`, `kbActions.includedMonthly`, `kbActions.resetAt`, `usedToday`, `used7d`, `callsToday` (label exact = "actions IA", PAS "reponses preparees") | Quota chiffre AUTORISE ; "reponses preparees" chiffre REFUSE jusqu a P2.1 |

## Decisions P0 / P1 / P2 / P3

### P0 - REFUSE / NE PAS FAIRE (contraintes brief KEY-231 + verifications source)

| ID | Reco / proposition | Decision | Justification |
|---|---|---|---|
| P0.1 | "KeyBuzz a deja prepare N reponses" via `callsToday` ou `last7d.calls` | REFUSE | V7 : callsToday compte les debits ai_generation incluant PRE_LLM_BLOCKED sans reponse -> chiffre semantiquement faux |
| P0.2 | Approximation `callsToday * 4` ou `used7d / cout_moyen` | REFUSE | Ratio invente + base fausse (V7). Brief KEY-231 : pas de metric approximee |
| P0.3 | "X minutes economisees" | REFUSE | Aucune donnee temps en DB, invention pure |
| P0.4 | "X notifications ignorees gratuitement ce mois" (CHIFFRE) | REFUSE en chiffre maintenant | Donnee non exposee par wallet/status ; necessite query ai_action_log reason LIKE 'NO_REPLY...' -> DEFER P2.1. Version NON chiffree autorisee (voir P1) |
| P0.5 | "Avec Autopilot +X% / Y de plus" (CHIFFRE) | REFUSE | Aucune donnee comparative reelle ; KEY-348 fournira l observation future |
| P0.6 | Modifier KBACTIONS_WEIGHTS / variance +/-15% | REFUSE | Design produit Ludovic, hors scope, confirme preserve PH-20.12B |
| P0.7 | Backfill ai_action_log / fake event CAPI/GA4 | REFUSE | Brief KEY-231 : pas de pollution metrics acquisition |

### P1 - APPROUVE POUR PATCH CLIENT (PH-20.13B, Client-only, sans backend, sans metrique inventee)

| ID | Fichier | Changement approuve | Type | Phase |
|---|---|---|---|---|
| P1.1 | `AIBudgetBlocked.tsx` (L29/L53) + champ mort `billing/ai/manage/page.tsx:14` | Supprimer `${balanceUsd}` + "Code erreur: 402 Payment Required" ; reword "Credit IA insuffisant" -> "Quota IA atteint pour cette periode" ; retirer champ interface balanceUsd mort | HYGIENE / latent (composant dormant) | PH-20.13B |
| P1.2 | `AISuggestionSlideOver.tsx` L926/L930 | "Consommation : X KBActions / Solde restant : Y KBActions" -> "Reponse preparee. Quota restant cette periode : Y actions." (Y = kbActionsRemaining exact) + accent visuel positif | UX taximetre | PH-20.13B |
| P1.3 | `AISuggestionSlideOver.tsx` L794 | "KBActions restantes : X" -> "Brouillon IA disponible - quota restant : X actions cette periode" | UX header | PH-20.13B |
| P1.4 | `AISuggestionSlideOver.tsx` L790 | "Consomme des KBActions IA" -> "Utilise votre quota d actions IA" (neutre, non culpabilisant) | UX wording | PH-20.13B |
| P1.5 | `AISuggestionSlideOver.tsx` L735/L747 (blocked PH-20.11C) | Ajouter ligne discrete NON chiffree "Protection garde-fou KeyBuzz activee - votre boutique est protegee." sous le wording existant | UX valeur protection | PH-20.13B |
| P1.6 | `AIActionsLimit.tsx` L45/L48 | "Limite d actions IA atteinte" -> "Quota IA epuise pour cette periode" ; conserver l alternative manuelle existante ; AUCUN chiffre "N reponses preparees" | UX wording | PH-20.13B |
| P1.7 | `TrialBanner.tsx` | Ajouter ligne secondaire NON chiffree : "Pendant l essai, testez les aides IA sur de vrais messages. Les notifications systeme sont ignorees gratuitement." | UX trial valeur | PH-20.13B |
| P1.8 | Surface no-reply (texte educatif statique, p.ex. tooltip wallet ou aide) | Texte STATIQUE non chiffre : "KeyBuzz ignore les notifications systeme (Amazon Seller Central, A-Z, no-reply) sans consommer votre quota." Pas un compteur | UX valeur statique | PH-20.13B |

Tous les P1 sont strictement Client-only, sans nouvel endpoint, sans backend, sans metrique inventee. Les seuls chiffres affiches restent les valeurs quota deja exposees et exactes (`remaining`, `includedMonthly`, `resetAt`).

### P2 - DEFER API / PRODUCT (apres GO + decision produit dediee)

| ID | Cible | Changement | Pourquoi defere |
|---|---|---|---|
| P2.1 | `credits-routes.ts` GET /ai/wallet/status | Ajouter `breakdown: { draft_generated_30d, skipped_no_reply_30d, blocked_guardrail_30d, draft_applied_30d }` via query read-only sur ai_action_log (deja en DB) | SEULE source semantiquement correcte pour un futur chiffre EXACT "N reponses preparees" (= count DRAFT_GENERATED) et "N notifications ignorees". Touche l API -> phase dediee |
| P2.2 | engine.ts:283-285 PRE_LLM_BLOCKED debit | DECISION PRODUIT : continuer a debiter ~6 KBA quand le garde-fou bloque AVANT tout appel LLM ? Argument gratuit : aucun cout LLM engage. Argument debit : cout audit/guardrail. NB : GUARDRAIL_BLOCKED (L312, LLM appele) reste debite justifie | Touche le brief produit + couts ; arbitrage Ludovic requis avant tout patch |
| P2.3 | Client nouvelle surface ValueDashboard | Section "Ce que KeyBuzz fait pour vous" agregeant le breakdown P2.1 | Depend de P2.1 (data exacte) ; nouvelle surface UI |

### P3 - DEFER DATA OBSERVATION (KEY-348 / V2)

| ID | Action | Quand |
|---|---|---|
| P3.1 | KEY-348 PH-20.12C observation read-only economies no-reply PROD reelles | Quand trafic client reel suffisant |
| P3.2 | V2 dashboard metric "notifications ignorees" chiffre | Apres P2.1 + KEY-348 donnees reelles |
| P3.3 | V2 weekly email digest seller-centric | Apres P2.1 stabilise |
| P3.4 | V2 workflow specifique litige A-Z (subtype AMAZON_ATOZ_NOREPLY) | Si volume justifie |

## Wording approuve pour patch Client

| Zone | Ancien wording (live) | Nouveau wording approuve | Patch futur |
|---|---|---|---|
| AIBudgetBlocked (dormant) | "Credit IA insuffisant" + "$X.XX" + "Code erreur: 402 Payment Required" | "Quota IA atteint pour cette periode. Rechargez un pack d actions ou attendez le renouvellement (le {resetAt})." (resetAt exact deja expose) | P1.1 |
| AISuggestionSlideOver post-action | "Consommation : X KBActions / Solde restant : Y KBActions" | "Reponse preparee. Quota restant cette periode : Y actions." | P1.2 |
| AISuggestionSlideOver header | "KBActions restantes : X" | "Brouillon IA disponible - quota restant : X actions cette periode" | P1.3 |
| AISuggestionSlideOver warning | "Consomme des KBActions IA" | "Utilise votre quota d actions IA" | P1.4 |
| AISuggestionSlideOver blocked | (wording PH-20.11C existant) | + "Protection garde-fou KeyBuzz activee - votre boutique est protegee." | P1.5 |
| AIActionsLimit | "Limite d actions IA atteinte" | "Quota IA epuise pour cette periode" (alternative manuelle conservee) | P1.6 |
| TrialBanner | (compte a rebours seul) | + "Pendant l essai, testez les aides IA sur de vrais messages. Les notifications systeme sont ignorees gratuitement." | P1.7 |
| No-reply (nouveau, statique) | (aucune surface) | "KeyBuzz ignore les notifications systeme (Amazon Seller Central, A-Z, no-reply) sans consommer votre quota." | P1.8 |

## Wording refuse

| Proposition refusee | Raison refus | Alternative |
|---|---|---|
| "KeyBuzz a deja prepare N reponses pour vous" (chiffre via callsToday/last7d) | callsToday surcompte (inclut PRE_LLM_BLOCKED sans reponse) - semantiquement faux (V7) | Non chiffre maintenant ; chiffre exact via P2.1 (count DRAFT_GENERATED) |
| "callsToday * 4" / "used7d / cout_moyen" | Ratio invente + base fausse | DEFER P2.1 breakdown exact |
| "X minutes economisees" | Aucune donnee temps en DB | Aucune (ou P3 observation) |
| "X notifications ignorees gratuitement ce mois" (chiffre) | Donnee non exposee par wallet/status | Wording statique non chiffre P1.8 ; chiffre via P2.1 |
| "Avec Autopilot +X%" (chiffre) | Aucune donnee comparative reelle | Message qualitatif "gardez ce niveau et allez plus loin" |

## Questions deferrees (arbitrage Ludovic)

1. P2.2 : `PRE_LLM_BLOCKED` doit-il rester debite (~6 KBA) alors qu aucun LLM n est appele et aucun brouillon n est rendu ? (GUARDRAIL_BLOCKED post-LLM reste debite justifie.)
2. P2.1 : exposer un breakdown read-only ai_action_log dans wallet/status pour permettre un chiffre EXACT "reponses preparees" / "notifications ignorees" (sans fake) - GO phase API dediee ?
3. P2.3 : creer une surface ValueDashboard "Ce que KeyBuzz fait pour vous" une fois P2.1 disponible ?
4. P1.8 : valider le texte educatif statique no-reply (libelle exact + emplacement UI).

## Prochaine phase recommandee

| Option | Description | Recommandation |
|---|---|---|
| **PH-20.13B SOURCE PATCH CLIENT** | Implementer P1.1 a P1.8 Client-only DEV (wording approuve ci-dessus), sans backend, sans metrique inventee | RECOMMANDE (apres ce GO decision) |
| PH-20.13C API BREAKDOWN | Implementer P2.1 (breakdown read-only ai_action_log) + decision P2.2 PRE_LLM_BLOCKED | Apres arbitrage Ludovic questions deferrees |
| PH-20.12C OBSERVE (KEY-348) | Observation reelle economies no-reply PROD | Quand trafic client reel suffisant |

### Prochaine phrase GO recommandee

**GO SOURCE PATCH CLIENT KBACTIONS VALUE ANXIETY UX DEV PH-SAAS-T8.12AS.20.13B**

## AI feature parity / anti-regression

| Element | Etat | Preuve |
|---|---|---|
| engine.ts | INCHANGE | aucun patch, lecture seule |
| noReplyClassifier.ts | INCHANGE | aucun patch |
| kbactions.ts | INCHANGE | aucun patch (autopilot_skipped_no_reply 0.0 verifie L53) |
| autopilotGuardrails.ts (doctrine seller-first) | INCHANGE | aucun patch |
| AISuggestionSlideOver.tsx | INCHANGE | aucun patch (audit lecture seule) |
| PH-20.11C blockedInfo / guidance | PRESERVE | wording L735/L747 verifie present |
| PH-20.12B no-reply skip 0 KBA | PRESERVE | Step 6.5 engine.ts:222-249 verifie |
| Appel /ai/assist | AUCUN | 0 appel |
| Appel /ai/execute | AUCUN | 0 appel |
| Appel /autopilot/draft/consume | AUCUN | 0 appel |
| KBActions consommee | AUCUNE | 0 |
| Message marketplace | AUCUN | 0 |

## No fake metrics / no fake events

| Element | Etat |
|---|---|
| Fake ai_action_log | AUCUN |
| Faux compteur KBActions | AUCUN |
| Backfill | AUCUN |
| Event marketing (GA4/CAPI/TikTok/LinkedIn) | AUCUN |
| Fake lead/register/checkout | AUCUN |
| Fake dashboard | AUCUN |
| Toute future metrique visible client | devra etre exacte et issue de donnees reelles (P2.1) |
| Observation reelle | KEY-348 reste la phase dediee |

## Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Patch source | OUI | 0 modification source applicatif |
| Build | OUI | 0 docker build |
| Push Docker | OUI | 0 docker push |
| Deploy | OUI | runtime preserve (DEV v3.5.256+214 / PROD v3.5.257+215) |
| Manifest GitOps | OUI | aucun k8s/ touche |
| kubectl mutation | OUI | uniquement git read-only + grep ; aucun kubectl mutation |
| Mutation DB | OUI | aucune (audit source uniquement, aucune SQL executee) |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| Message marketplace | OUI | 0 |
| Fake event/metric/conversation/KBActions | OUI | 0 |
| Backfill | OUI | 0 |
| Secret/token/PII brut | OUI | aucun affiche |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| Dump env pods | OUI | 0 |
| Cleanup repo / git destructif / worktree remove | OUI | aucune commande destructive |
| Linear statut change | OUI | 0 transition |
| Linear ticket cree | OUI | 0 ticket cree |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |

## Repos / runtimes

| Service | Branche/source | Runtime DEV | Runtime PROD | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth HEAD 38c048c0 = origin, src clean 0, dist dirty 223 (dette read-only documentee) | v3.5.256-autopilot-no-reply-kbactions-dev | v3.5.257-autopilot-no-reply-kbactions-prod | LIVE PRESERVE |
| keybuzz-client | ph148/onboarding-activation-replay HEAD 1a30ad9, dirty 1 (tsconfig artefact) | v3.5.214-ai-draft-blocked-reason-dev | v3.5.215-ai-draft-blocked-reason-prod | LIVE PRESERVE |
| keybuzz-infra | main HEAD 6247df6 -> commit decision | main | main | OK |

## Linear

Commentaires postes (statuts INCHANGES, 0 ticket cree) :
- KEY-231 (primary) : decision P0/P1/P2/P3 + verifications source + prochaines phases.
- KEY-337 (parent PH-20) : resume decision closing.
- KEY-348 (observation differee) : rappel court que les chiffres reels viennent de KEY-348 / P2.1.

Pas de commentaire KEY-349 (pas de rotation secret cette phase) ni KEY-235/263/270/302/305/308/309/312 (preserves).

## Rollback

N/A docs-only. Aucun runtime impact. Seul revert possible : revert du commit docs si erreur dans le rapport.

STOP.
