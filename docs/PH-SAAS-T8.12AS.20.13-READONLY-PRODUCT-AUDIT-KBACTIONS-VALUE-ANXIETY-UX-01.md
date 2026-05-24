# PH-SAAS-T8.12AS.20.13-READONLY-PRODUCT-AUDIT-KBACTIONS-VALUE-ANXIETY-UX-01

> Date : 2026-05-24
> Linear : KEY-231 primary ; KEY-337 parent PH-20 ; references KEY-348 / KEY-349 / KEY-312 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.13-READONLY-PRODUCT-AUDIT-KBACTIONS-VALUE-ANXIETY-UX
> Environnement : READ-ONLY AUDIT (no runtime change, no source change, no DB, no fake metrics)

## VERDICT

GO READONLY PRODUCT AUDIT KBACTIONS VALUE ANXIETY UX READY PH-SAAS-T8.12AS.20.13

Prochaine action recommandee : **GO PRODUCT DECISION KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13A** (avant tout patch, valider arbitrages produit avec Ludovic sur les recommandations P1).

## Resume executif

Audit read-only de l experience utilisateur autour des KBActions, mesure de l ecart entre l intention produit (brief KEY-231 Ludovic 2026-04-29 : "levier de valeur et d envie d upgrade, sans effet taximetre anxiogene") et l implementation actuelle live PROD v3.5.215 (Client) / v3.5.257 (API).

Constats principaux :
1. **Effet taximetre LIVE** : `AISuggestionSlideOver.tsx` affiche apres chaque generation : "Consommation : X.XX KBActions / Solde restant : Y.YY KBActions" - exactement le format que le brief KEY-231 demande d eviter.
2. **Variance volontaire +/-15%** sur le cout : design intentionnel (`kbactions.ts` : "client can never predict exact cost") - augmente l opacite et l anxiete plutot que la valeur percue.
3. **Fuite USD client** : `AIBudgetBlocked.tsx` ligne 32 expose `$<balanceUsd>` en USD en dur au client - contradiction directe avec le brief ("pas de melange trial avec billing reel") et avec le BFF `wallet/status` qui supprime `balanceUsd`.
4. **Compte a rebours trial pression** : `TrialBanner.tsx` escalation visuelle bleue -> amber -> rouge selon `daysLeftTrial`, sans aucune mention de la valeur produite pendant le trial.
5. **Pas de surface "valeur preparee"** : aucun composant n agrege ou n affiche "X reponses preparees", "Y minutes economisees", "Z notifications skippees gratuitement", "N drafts proteges par les garde-fous". Tous les ai_action_log entries (status/reason) existent en DB mais ne remontent jamais a une narrative utilisateur.
6. **PH-20.12B no-reply skip invisible** : skip = 0 KBA cost LIVE en runtime, mais zero UI ne celebre ce skip comme une protection gratuite - opportunite manquee.
7. **Wording anxiogene** : "Limite d actions IA atteinte", "Credit IA insuffisant", "Ajouter des actions IA", "Continuer sans IA" - vocabulaire token/credit qui infantilise et angoisse.

Bonne nouvelle :
- L architecture backend permet deja la solution (ai_action_log a status/reason/payload riches, KBACTIONS_WEIGHTS table explicite incluant `autopilot_skipped_no_reply=0.0`).
- PH-20.11C (blockedInfo) + PH-20.12B (no-reply skip) ont prepare les briques techniques.
- Plan capabilities (`planCapabilities.ts`) expose deja `kbActionsMonthly` par plan.

Recommandations priorisees (P0 a P3, voir section detaillee) :
- **P1 quick wins copy/UI** (Client only, sans patch backend) : reformuler "Consommation/Solde restant" en "Action preparee / quota restant", supprimer affichage USD `AIBudgetBlocked`, ajouter section "Aujourd hui : N reponses preparees + M notifications ignorees" dans wallet card.
- **P2 product/API light** : exposer breakdown skip vs draft vs blocked depuis ai_action_log deja en DB, sans nouvelle metrique inventee.
- **P3 future observation** : KEY-348 fournira les chiffres reels apres trafic.

Aucune recommandation P0 (faux gains, faux compteurs, backfill) - le brief KEY-231 est explicite : pas de pollution metrics acquisition.

## Sources lues

| Source | Type | Utilite | Verdict |
|---|---|---|---|
| `keybuzz-api/src/config/kbactions.ts` | Source backend | KBACTIONS_WEIGHTS table + variance +/-15% + design intent "client never sees weights" | LU |
| `keybuzz-api/src/services/ai-actions.service.ts` | Source backend | getActionsWallet + debitKBActions + getPlanIncludedKBActions + topup | LU |
| `keybuzz-api/src/modules/autopilot/engine.ts` | Source backend | debit points (autopilot_draft x4, playbook_auto x2) + Step 6.5 no-reply skip (0 debit) + ai_action_log logAction signature | LU |
| `keybuzz-api/src/modules/ai/ai-assist-routes.ts` | Source backend | /ai/assist endpoint debit logic | LU partial |
| `keybuzz-api/src/modules/ai/credits-routes.ts` | Source backend | wallet/status endpoint, includedMonthly/remaining/purchasedRemaining exposure | LU |
| `keybuzz-api/src/modules/ai/returns-decision-routes.ts` | Source backend | heavy_decision debit point (20 KBA) | LU |
| `keybuzz-api/src/modules/autopilot/routes.ts` | Source backend | ai_action_log read query + status/reason taxonomy | LU |
| `keybuzz-api/src/services/entitlement.service.ts` | Source backend | plan/billingPlan/selectedPlan/trial_entitlement_plan resolution | LU |
| `keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx` | Source Client UX | Consumption display tax-meter + actionsRemaining state + AIBudgetBlocked usage | LU (focus lignes 186, 389-390, 490-496, 735, 792-794, 910-940) |
| `keybuzz-client/src/components/ai/AIBudgetBlocked.tsx` | Source Client UX | Expose `$<balanceUsd>` USD au client (FUITE) | LU (59 lignes) |
| `keybuzz-client/src/features/ai-ui/AIActionsLimit.tsx` | Source Client UX | Block "Limite d actions IA atteinte" + AIActionPacksModal (3 packs 50/200/500 KBA) | LU (262 lignes, focus 38-67) |
| `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` | Source Client UX | Pas de mention KBA value/anxiete | LU partial (0 hit) |
| `keybuzz-client/app/api/ai/wallet/status/route.ts` | BFF Client | strip `balanceUsd` + `_internal` pour client (bonne pratique) | LU |
| `keybuzz-client/app/billing/page.tsx` | Page Client | AIWalletCard : remaining + usedToday | LU |
| `keybuzz-client/app/billing/ai/page.tsx` | Page Client | AIWalletPage : kbActions full state + ACTION_PACKS | LU (396 lignes, focus 1-100) |
| `keybuzz-client/src/features/billing/components/TrialBanner.tsx` | Source Client UX | Escalation visuelle compte a rebours bleu -> amber -> rouge | LU |
| `keybuzz-client/src/features/billing/planCapabilities.ts` | Source Client config | kbActionsMonthly + hasAIAssistant + canAutoExecute par plan | LU partial (focus 1-60) |
| `keybuzz-client/src/features/pricing/config.ts` | Source Client config | Pricing plans Starter 97 / Pro 297 / Autopilot 497 EUR | LU partial |
| Linear KEY-231 | Description + 5 commentaires recents | Brief produit Ludovic 2026-04-29 (cite verbatim ci-dessous) | LU |
| Linear KEY-337 | Parent PH-20 context | LU | LU |
| Linear KEY-348 | Observation differee | LU | LU |
| Linear KEY-312 | PH-20.11C blockedInfo Done | LU partial via comments | LU |
| `keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md` | Operational state | Sections PH-20.11C / PH-20.12B | LU |
| `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` | Operational source | Sections 4 runtime + 4b PH milestones + 5 anchors + 8b PH147 hardening + 13 tickets | LU |
| `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-CLOSE-01.md` | Phase close report | Heritage technique PH-20.12B | LU |

## E0 - Preflight + runtime preserve

| Service | Runtime DEV | Runtime PROD | Dirty/source | Verdict |
|---|---|---|---|---|
| keybuzz-api | v3.5.256-autopilot-no-reply-kbactions-dev | v3.5.257-autopilot-no-reply-kbactions-prod | branche ph147.4/source-of-truth HEAD 38c048c0 = origin, src clean 0, dist dirty 223 (dette read-only documentee section 8b PH147 hardening) | LIVE PRESERVE |
| keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | v3.5.215-ai-draft-blocked-reason-prod | branche ph148/onboarding-activation-replay HEAD 1a30ad9, dirty 1 (tsconfig.tsbuildinfo artefact) | LIVE PRESERVE |
| keybuzz-infra | main | main | HEAD ce5f3b7 (cleanup no-force), dirty 0 | OK ready commit |
| Pods | preserve | tlwgp 10h / 92c96 34h Running 1/1 0 restart | INCHANGE | OK |

## E1 - Linear context

### KEY-231 (Todo, P3) - brief produit Ludovic 2026-04-29 verbatim cite

> But : utiliser les KBActions pendant le trial comme levier de valeur et d envie d upgrade, sans effet taximetre anxiogene.
>
> Direction produit :
> - Les KBActions doivent etre disponibles pendant le trial Autopilote assiste.
> - Elles doivent aider le client a comprendre que KeyBuzz travaille pour lui.
> - Messaging souhaite : temps gagne, actions preparees, valeur operationnelle.
> - Frustration positive : montrer qu un plan superieur permet plus de volume, plus d autonomie, ou moins de contraintes.
>
> A eviter :
> - Donner l impression que chaque clic coute cher.
> - Faire peur avec une jauge trop agressive.
> - Melanger KBActions trial avec billing reel sans explication.
>
> A concevoir :
> - Quota trial raisonnable.
> - Message de valeur apres usage : "KeyBuzz vient de preparer X reponses / economise Y minutes".
> - Message d upgrade : "Avec Autopilote, vous gardez ce niveau de puissance et pouvez aller plus loin."
> - Separation tracking produit vs conversion marketing.
>
> Contraintes :
> - Pas de faux purchase.
> - Pas de faux event CAPI.
> - Pas de pollution /metrics acquisition.

Brief tres explicite. Le present audit mesure l ecart entre cette intention et l implementation live.

### KEY-337 (Backlog, P1) - parent PH-20

Parent acquisition tracking + GO agence. Cadre la priorite PMF + campagnes Ads. PH-20.13 s inscrit dans cette logique : reduire les frictions UX qui freineraient les upgrades trial -> paid pendant les campagnes payantes.

### KEY-348 (Backlog, P3) - observation differee PH-20.12C

Trace differee pour observer en read-only les economies KBActions no-reply PROD quand trafic reel disponible. Heritage parfait pour P3 du present audit (numbers reels viendront de KEY-348, pas de PH-20.13).

### KEY-312 (Done) - PH-20.11C blockedInfo

Doctrine seller-first preserve. Garde-fou guidance statique deja LIVE. Reference pour la narrative "KeyBuzz protege votre boutique".

## E2 - API KBActions map

### A. KBACTIONS_WEIGHTS table (verifie 2026-05-24, kbactions.ts)

| Source | Cout (KBA) | Note |
|---|---|---|
| inbox_suggestion | 6.0 | "1 standard AI suggestion" (165 msg/month max @ 1000 KBA Pro) |
| inbox_contextualized | 10.0 | Reponse avec order/history context (plus lourd) |
| inbox_regenerate | 3.0 | Regenerer suggestion existante (context cached) |
| playbook_auto | 8.0 | Reponse playbook automatique |
| playbook_simulation | 4.0 | Simulation playbook (interne) |
| attachment_analysis | 14.0 | Analyse pj uploaded |
| sentiment_analysis | 6.0 | Analyse sentiment message |
| heavy_decision | 20.0 | Analyse complexe multi-step (returns) |
| **autopilot_skipped_no_reply** | **0.0** | **PH-20.12B sentinel - skip gratuit notif Amazon** |
| default | 6.0 | Fallback (ne devrait pas etre utilise) |

Variance volontaire +/-15% sur tous (`applyVariance`) : "client can never predict exact cost". Choix design conscient pour anti-gaming, mais accentue l opacite percue.

Plan -> KBA monthly (commentaire kbactions.ts) :
- Starter 97 EUR/mois -> 0 KBActions (pas d IA)
- Pro 297 EUR/mois -> 1000 KBActions
- Autopilot 497 EUR/mois -> 2000 KBActions

Trial Autopilote Assiste : pendant 14 jours, le tenant a un `trial_entitlement_plan` qui surpasse le `billingPlan` (souvent STARTER -> AUTOPILOT temporaire) - quota KBActions trial = quota plan boosted (`getPlanIncludedKBActions(plan)` resout via entitlement.service.ts).

### B. KBActions debit points (engine.ts + autres)

| Endroit | Source | Cout effectif | Trigger |
|---|---|---|---|
| engine.ts:283-284 | autopilot_draft | ~6 KBA +/-15% | PRE_LLM_BLOCKED (guardrails risque HIGH) - DEBITE meme si blocked |
| engine.ts:312-313 | autopilot_draft | ~6 KBA | Validation draft (path 2) |
| engine.ts:339-340 | autopilot_draft | ~6 KBA | Draft generation success |
| engine.ts:366-367 | autopilot_draft | ~6 KBA | Draft generation (path 2) |
| engine.ts:389-390 | playbook_auto | ~8 KBA | Playbook execute |
| engine.ts:423-425 | autopilot_draft | ~6 KBA | Draft path final |
| engine.ts:517-522 | playbook_auto | ~8 KBA si executed sinon 0 | Conditional debit playbook |
| ai-assist-routes.ts:791 | (via checkActionsAvailable) | NA | /ai/assist endpoint - manual brouillon |
| returns-decision-routes.ts:774-782 | heavy_decision | ~20 KBA +/-15% | Returns decision endpoint |
| engine.ts:225 | (none, comment seulement) | 0 | PH-20.12B Step 6.5 no-reply skip - NO debit |

Observation : meme un PRE_LLM_BLOCKED (guardrails block) debite ~6 KBA. Pendant un trial, un compte qui recoit beaucoup de messages a risque eleve voit son compteur baisser SANS recevoir de draft IA - effet taximetre pur, opposable au brief KEY-231 "ne pas donner l impression que chaque clic coute cher".

### C. KBActions exposition endpoints

| Endpoint | Fichier | Expose | Note |
|---|---|---|---|
| GET /ai/wallet/status | credits-routes.ts:81-229 | balance (USD interne), kbActions{remaining, includedMonthly, purchasedRemaining, resetAt, usedToday, used7d, callsToday, calls7d}, today, last7d | Backward compat USD + KBA |
| BFF /api/ai/wallet/status | wallet/status/route.ts | strip `balanceUsd` + `_internal` | Bonne pratique BFF |
| GET /ai/credits | credits-routes.ts:508-519 | walletRemaining, includedMonthly | Read-only |
| POST /ai/wallet/topup | credits-routes.ts:397 | DEV only - balanceUsd | DEV path |
| POST /billing/ai-actions-checkout | billing/routes.ts | Stripe checkout pack actions | Production |
| GET /autopilot/draft (PH-20.11C) | autopilot/routes.ts | blockedInfo si conv bloquee | Path lecture-only |

### D. ai_action_log status/reason taxonomy

| status | reason possible | Trigger | KBA cost |
|---|---|---|---|
| `skipped` blocked=true | `NO_SETTINGS` | autopilot_settings absent | 0 |
| `skipped` blocked=true | `DISABLED` | autopilot_settings.is_enabled=false | 0 |
| `skipped` blocked=true | `MODE_NOT_AUTOPILOT:<mode>` | iaMode pas autopilot | 0 |
| `skipped` blocked=true | `WALLET_EMPTY` | checkActionsAvailable fail | 0 |
| `skipped` blocked=true | `CONVERSATION_NOT_FOUND` | DB miss | 0 |
| `skipped` blocked=true | `LAST_MESSAGE_NOT_INBOUND` | message direction != inbound | 0 |
| **`skipped` blocked=true** | **`NO_REPLY_PLATFORM_NOTIFICATION:<subtype>`** | **PH-20.12B Step 6.5 no-reply skip** | **0** |
| `skipped` blocked=true | `PRE_LLM_BLOCKED:<combinedRisk>` | guardrails block HIGH risk | ~6 KBA (DEBITE !) |
| `skipped` blocked=true | `DRAFT_WALLET_EMPTY` | wallet empty pendant debit | 0 |
| `skipped` blocked=true | `DRAFT_GENERATED` | draft cree et stocke | ~6 KBA |
| `skipped` blocked=true | `ESCALATION_DRAFT:<confidence>` | escalation declenchee | ~6 KBA |
| `skipped` blocked=true | `DRAFT_APPLIED` / `DRAFT_MODIFIED` / `DRAFT_DISMISSED` | actions humaines sur draft | variable |
| `completed` blocked=false | (action effective) | draft execute ou playbook applique | ~6 ou ~8 KBA |

**Insight critique** : la DB contient deja toute la matiere pour distinguer skip gratuit / draft prepare / draft bloque protege / action executee. Mais aucune surface UI n agrege ces signaux en narrative valeur.

### E. Trial/plan gating

| Plan | KBActions mensuelles | Trial boost |
|---|---|---|
| STARTER (97 EUR) | 0 | Trial Autopilote Assiste 14j -> kbActionsMonthly = 2000 temporaire via trial_entitlement_plan |
| PRO (297 EUR) | 1000 | NA |
| AUTOPILOT (497 EUR) | 2000 | NA |
| ENTERPRISE | sur devis | NA |

Pendant trial : `getPlanIncludedKBActions(plan)` resout d abord via `trial_entitlement_plan` si actif, sinon `billingPlan`. C est bien fait techniquement.

## E3 - Client UX KBActions matrice

| Zone | Wording actuel | Risque anxiety | Opportunite valeur | Reco |
|---|---|---|---|---|
| **1. Trial onboarding** | StepTrialLimits + TrialBanner "Il vous reste X jours d essai" / "A J0 retour au plan Starter sauf upgrade" | Compte a rebours pression pure, escalation visuelle bleu->amber->rouge (<=3j) | Aucune mention valeur produite pendant trial | P1 : ajouter "Pendant cet essai, KeyBuzz a deja prepare N reponses pour vous" (donnee deja en `last7d.kbActionsUsed` + `callsToday`) |
| **2. Inbox / AI drawer (AISuggestionSlideOver)** | "Consommation : X.XX KBActions / Solde restant : Y.YY KBActions" affiche apres chaque generation (lignes 920-935) | **EFFET TAXIMETRE direct** - exactement le format que le brief KEY-231 demande d eviter ("ne pas donner l impression que chaque clic coute cher") | Pas de mention "reponse preparee en N secondes" ou "temps gagne" | **P1 critique** : reformuler en "Reponse preparee. Quota restant : Y.YY KBActions" avec icone verte au lieu de mauve, deplacer le compteur en haut subtilement au lieu de centre apres action |
| **3. Brouillon IA (AISuggestionSlideOver)** | "KBActions restantes : X" header (ligne 794) + drawer ouvert sur conv | Compteur visible des l ouverture meme avant action - taximetre attente | Le draft est la valeur visible, pas le compteur | P1 : header drawer affiche "Brouillon IA disponible - quota X actions ce mois" avec accent sur "disponible" pas "restant" |
| **4. Suggestion IA** | Idem AISuggestionSlideOver | Idem | Idem | P1 : meme reformulation que zone 2 |
| **5. Aide IA manuelle** | Idem - debit ai-assist-routes.ts | Idem | Pas de mention "draft prepare pour validation humaine" | P1 : message post-generation "Brouillon prepare pour vous - validez ou modifiez avant envoi" |
| **6. Guardrail blocked (PH-20.11C)** | AISuggestionSlideOver:735 "KeyBuzz n a pas genere de brouillon automatique car ce message demande une action sensible..." | Bon wording ! Met en avant la protection sans culpabiliser | Pourrait celebrer la protection comme valeur ajoutee | P1 : ajouter discrete "Protection garde-fou activee gratuitement" / "Ce blocage protege votre boutique" - confirmer KBA debit ici (qui reste a ~6 KBA actuellement, voir engine.ts:283 - candidat P2 patch source) |
| **7. No-reply skip (PH-20.12B)** | Aucune UI - skip invisible | Pas anxiogene (silencieux) mais opportunite MANQUEE valeur | "Aujourd hui : N notifications Amazon ignorees gratuitement par KeyBuzz" | P1 : agreger dans wallet card "Notifications systeme : X ignorees ce mois (gratuit)" via query ai_action_log filter reason LIKE 'NO_REPLY_PLATFORM_NOTIFICATION:%' |
| **8. Billing / usage / wallet (billing/page + billing/ai/page)** | AIWalletCard : "Plan : X, remaining: Y.YY, usedToday: Z.ZZ" / AIWalletPage : breakdown complet + ACTION_PACKS (50/200/500 KBA = 24.90/69.90/149.90 EUR) | Acceptable mais transactionnel - manque storytelling valeur | Section "Ce que KeyBuzz a fait pour vous" avec breakdown skip/draft/blocked/protege | P2 : nouvelle section "Aujourd hui : N reponses preparees, M notifications ignorees, K drafts proteges par garde-fous" basee sur ai_action_log query existante |
| **9. AIBudgetBlocked (limite atteinte)** | "Credit IA insuffisant / Solde actuel: $X.XX / Code erreur: 402 Payment Required" | **FUITE USD CRITIQUE** + jargon technique 402 + wording "credit" anxiogene | "Recharger" CTA est dans la bonne direction | **P1 critique** : supprimer `$balanceUsd`, remplacer par "Quota IA atteint - rechargez un pack ou attendez la prochaine periode (resetAt: <date>)", retirer "Code erreur: 402 Payment Required" du UI client |
| **10. AIActionsLimit (limit reached)** | "Limite d actions IA atteinte / Vous pouvez continuer a repondre manuellement ou ajouter des actions IA pour poursuivre sans interruption" | OK acceptable, suggere alternative manuelle | Pas de mention valeur deja produite ce mois | P1 mineur : ajouter "Pendant cette periode, KeyBuzz a deja prepare N reponses pour vous" |
| **11. Dashboard / stats** | Absent specifique KBA | NA | Page dediee "Ce que KeyBuzz fait pour vous ce mois" - reponses preparees, temps gagne estime, notifications ignorees, drafts proteges | P2/P3 : roadmap V2 metric dashboard (KEY-348 fournira donnees reelles) |
| **12. Emails / notifications email** | Pas audite cette phase | NA | Email weekly recap "Cette semaine KeyBuzz a..." | P3 : V2 weekly digest seller-centric |

## E4 - Trial / wow narrative

Doctrine PH-20.11C : "Brouillon IA bloque par securite - Garde-fou actif - Trame de reponse securisee - Copier la trame" -> wording exemplaire qui met en avant la protection. C est l ADN seller-first.

Cette doctrine doit s etendre au narratif KBActions :
- Pas "vous consommez", mais "KeyBuzz a prepare pour vous"
- Pas "il vous reste X credits", mais "votre quota cette periode X actions"
- Pas "limite atteinte", mais "quota max ce mois atteint - vous reprenez le control manuel ou ajoutez des actions"
- Pas "credit insuffisant", mais "quota epuise temporairement"

## E5 - Risques anxiety

| Risque | Source actuelle | Severite | Recommandation |
|---|---|---|---|
| Effet taximetre apres chaque action | AISuggestionSlideOver:920-935 "Consommation/Solde restant" | HAUT | P1 reformulation immediate |
| USD leak client | AIBudgetBlocked:32 `$<balanceUsd>` | HAUT (contradiction brief + doctrine BFF) | P1 supprimer immediatement |
| Variance +/-15% opacite | kbactions.ts applyVariance | MOYEN (design intentionnel mais effet pervers) | P0 - NE PAS modifier le backend (design Ludovic), mais P1 sur UI : afficher quota total non-decimal "quota 1000 ce mois" plutot que "remaining 487.62" |
| Compteur permanent visible drawer | AISuggestionSlideOver:794 header | MOYEN | P1 reformulation header |
| TrialBanner pression jours | TrialBanner.tsx | MOYEN | P2 : ajouter mention valeur produite |
| Pas de celebration skip gratuit | Absent UI | OPPORTUNITE perdue | P1 quick win : "X notifications ignorees gratuitement ce mois" |
| Pas de celebration protection garde-fou | Absent UI hors PH-20.11C wording | OPPORTUNITE perdue | P1 wording + P2 metric |
| Jargon technique "Code erreur 402" | AIBudgetBlocked:55 | MOYEN | P1 supprimer du UI client |

## E6 - Analyse produit complete (matrice 12 zones cf E3)

Voir tableau detaille section E3 ci-dessus. Synthese :
- 5 zones HAUT risque P1 quick wins (zones 2, 9, et reformulation generale wording 1, 3, 4)
- 4 zones OPPORTUNITE valeur P1 (zones 5, 6, 7, 8 - celebrer protections deja existantes)
- 2 zones futures P2/P3 (zones 11, 12 - V2 dashboard / weekly digest)
- 1 zone neutre OK (zone 10 - acceptable apres ajout mineur)

## E7 - Recommandations P0/P1/P2/P3

### P0 - NE PAS FAIRE (contraintes brief KEY-231)

| Action interdite | Raison |
|---|---|
| Inventer chiffre "X minutes economisees" sans donnees reelles | Brief : "Pas de pollution /metrics acquisition", "Pas de faux event CAPI" |
| Backfill ai_action_log avec entries fictives | Pas de fake data |
| Modifier KBACTIONS_WEIGHTS table (cout vrais drafts) | Design Ludovic preserve - PH-20.12B audit precedent a confirme costs preservation |
| Modifier la variance +/-15% (anti-gaming intentionnel) | Decision produit existante |
| Promesse chiffree "Avec Autopilot, X% de plus" sans donnees | Pas de fake metric |
| Dashboard avec metrics inventes | KEY-348 fournira donnees reelles plus tard |

### P1 - Quick wins copy/UI Client only (sans patch backend)

| # | Fichier | Changement | Impact UX | Risque | Phase proposee |
|---|---|---|---|---|---|
| P1.1 | `AIBudgetBlocked.tsx:32+55` | Supprimer `${balanceUsd.toFixed(2)}` + "Code erreur: 402 Payment Required" / Remplacer "Credit IA insuffisant" par "Quota IA atteint pour cette periode" / Ajouter resetAt si dispo | CRITIQUE : retire fuite USD client + jargon technique | Faible | PH-20.13B-CLIENT |
| P1.2 | `AISuggestionSlideOver.tsx:920-935` | Reformuler "Consommation : X.XX KBActions / Solde restant : Y.YY" en "Reponse preparee pour vous - Quota restant : Y.YY actions ce mois" / Icone verte au lieu de mauve / Deplacer subtilement en bas du drawer post-action | HAUT : retire effet taximetre central | Faible | PH-20.13B-CLIENT |
| P1.3 | `AISuggestionSlideOver.tsx:794` | Header drawer "KBActions restantes : X" -> "Brouillon IA disponible - quota X actions cette periode" | MOYEN : valorise disponibilite | Faible | PH-20.13B-CLIENT |
| P1.4 | `AIActionsLimit.tsx:38-67` | "Limite d actions IA atteinte" -> "Quota IA epuise pour cette periode" + ajouter "KeyBuzz a prepare N reponses pour vous ce mois" si data dispo via wallet/status `used7d.kbActionsUsed` (N = `used7d / cost_avg_estimate` ou simplement `callsToday` * 4) | MOYEN : montre valeur deja produite | Faible | PH-20.13B-CLIENT |
| P1.5 | `TrialBanner.tsx` | Ajouter ligne secondaire "KeyBuzz a deja prepare X reponses pendant votre essai" (data via wallet/status `last7d.calls`) | MOYEN : positive trial story | Faible | PH-20.13B-CLIENT |
| P1.6 | `billing/page.tsx AIWalletCard` | Ajouter section "Aujourd hui : X reponses preparees" (data `today.calls`) + "Ce mois : Y reponses, Z actions" (`last7d` * 4) | MOYEN : narrative valeur dashboard | Faible | PH-20.13B-CLIENT |
| P1.7 | `AISuggestionSlideOver.tsx:735` (blocked path PH-20.11C) | Ajouter discrete "Protection garde-fou activee - votre boutique est protegee" sous le wording existant | MINEUR : celebre protection deja LIVE | Faible | PH-20.13B-CLIENT |

Tous P1 sont strictement Client only, sans backend, sans nouveau endpoint, basees sur donnees deja exposees via `/api/ai/wallet/status`. Aucun fake metric.

### P2 - Product/API light (apres GO + decision produit)

| # | Fichier API | Changement | Impact | Risque |
|---|---|---|---|---|
| P2.1 | `credits-routes.ts` GET /ai/wallet/status | Ajouter dans response : `breakdown: { skipped_no_reply_30d: N, blocked_guardrail_30d: M, draft_generated_30d: K, draft_applied_30d: L }` via query existante sur `ai_action_log` (deja en DB) | Permet section "Ce que KeyBuzz fait pour vous" cote Client SANS fake metric | Faible (read-only) |
| P2.2 | engine.ts:283-284 PRE_LLM_BLOCKED debit | EVALUATION : faut-il continuer a debiter ~6 KBA quand garde-fou bloque ? Brief KEY-231 dit "ne pas donner l impression que chaque clic coute cher". Le debit actuel sur blocked peut etre vu comme : (a) cout LLM evite donc devrait etre gratuit, ou (b) cout audit/guardrail justifie. Decision produit a prendre | Si decision = gratuit : reduit debits ~12 KBA/30j PROD additionnels economises | Decision produit avant patch |
| P2.3 | Client UI nouvelle section dashboard `app/billing/page.tsx` ou nouveau composant ValueDashboard | Section "Ce que KeyBuzz fait pour vous ce mois" agrege breakdown P2.1 | HAUT : storytelling produit | Moyen (nouvelle UI surface) |

### P3 - Future observation / data

| # | Action | Quand |
|---|---|---|
| P3.1 | KEY-348 PH-20.12C observation read-only 24-48h | Quand trafic reel client suffisant - mesurer economie KBActions no-reply reelle vs baseline ~30 KBA/30j |
| P3.2 | V2 metric dashboard "Notifications skippees ce mois" | Apres KEY-348 donnees reelles |
| P3.3 | V2 weekly email digest seller-centric | Apres P2 backend breakdown stabilise |
| P3.4 | V2 atoz-guarantee workflow specifique Litige A-Z | Subtype AMAZON_ATOZ_NOREPLY deja prepare PH-20.12B - V2 si volume justifie |

## No fake metrics / no fake events / no fake KBActions

Tous P1 / P2 / P3 RESPECTENT strictement :
- Aucun fake event tracking
- Aucune fake KBActions debitee/creditee
- Aucune fake conversation/lead/register/checkout
- Aucun KPI invente
- Aucune mutation DB hors lectures
- Aucun backfill ai_action_log
- Toute donnee affichee provient de DB existante (`ai_action_log`, `ai_actions_wallet`, conversations, messages)
- KEY-348 reste la source pour observation reelle future
- Recommandations chiffrees ("X reponses preparees") strictement basees sur data wallet/status existante (`today.calls`, `last7d.calls`, `kbActions.usedToday`)
- Aucun "Avec Autopilot vous gagnez Y%" sans observation reelle KEY-348

## Confirmations securite (read-only audit)

| Interdit | Respecte | Preuve |
|---|---|---|
| Patch source | OUI | 0 modification source applicatif (api/client/backend/admin-v2/website) |
| Build | OUI | 0 docker build |
| Push Docker | OUI | 0 docker push |
| Deploy | OUI | runtime preserve (DEV v3.5.256+214, PROD v3.5.257+215) |
| Manifest GitOps | OUI | aucun k8s/ touche |
| kubectl mutation | OUI | uniquement kubectl get pour preflight |
| Cleanup repo / git destructive | OUI | aucune commande destructive |
| Worktree remove | OUI | aucun `git worktree remove` execute |
| LLM call | OUI | 0 appel runtime (audit source uniquement) |
| KBActions consommee | OUI | 0 (audit lecture only) |
| Message marketplace | OUI | 0 envoi |
| Mutation DB | OUI | aucune (audit source uniquement) |
| Fake event/metric/conversation/KBActions | OUI | 0 fake genere, audit pure |
| Backfill | OUI | 0 |
| Secret/token/PII brut | OUI | aucun affiche dans rapport |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| Dump env pods | OUI | 0 |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel |
| Linear statut change | OUI | 0 transition |
| Linear ticket cree | OUI | 0 ticket cree |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| Regles absolues operational doc | PRESERVES | aucune modification AI_MEMORY sauf rapport docs |

## Rollback

N/A docs-only audit. Aucun runtime impact. Aucun rollback prevu sauf revert commit docs si erreur dans rapport.

## Linear

Commentaires postes (statuts INCHANGES 100%, 0 ticket cree) :
- KEY-231 (primary) : commentaire long avec verdict audit + risques + recommandations P1/P2/P3
- KEY-337 (parent PH-20) : commentaire resume audit closing
- KEY-348 (observation differee) : commentaire court rappelant que les chiffres reels viendront de KEY-348

Pas de commentaire KEY-349 (cette phase n implique pas la rotation secret) ni KEY-235/263/270/302/305/308/309/312 (preserves).

## Proposition prochaine phase

| Option | Description | Recommandation |
|---|---|---|
| **PH-20.13A PRODUCT DECISION KBACTIONS VALUE ANXIETY UX** | Valider arbitrages produit avec Ludovic : reformulation wording, supprimer USD leak, position compteur, breakdown narrative | **RECOMMANDE** avant tout patch |
| PH-20.13B SOURCE PATCH CLIENT KBACTIONS VALUE ANXIETY UX DEV | Implementer P1 quick wins Client DEV apres decision PH-20.13A | Apres GO PH-20.13A |
| PH-20.12C OBSERVE | KEY-348 observation differee KBActions no-reply savings PROD | Quand trafic client reel suffisant (independant PH-20.13) |
| GO CLEANUP API DIST DEBT PH147 | Phase dediee cleanup `D dist/*.js` canonical repo | Optionnel, peu prioritaire |

### Prochaine phrase GO recommandee

**GO PRODUCT DECISION KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13A**

Pour permettre a Ludovic d arbitrer les recommandations P1 / P2 (notamment la decision sur debit PRE_LLM_BLOCKED P2.2 qui touche brief produit) avant tout patch source.

Verdict PH-20.13 : audit READY, narrative ecart entre brief KEY-231 et implementation documentee, recommandations priorisees disponibles, aucun fake metric, aucune mutation runtime.

STOP.
