# PH-SAAS-T8.12AS.20.11-AI-DRAFT-AUTOPILOT-INBOX-READONLY-AUDIT-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary : Brouillon IA bloque) ; KEY-305 (race UI AISuggestionSlideOver) ; KEY-235 (seller-first refund) ; KEY-231 (KBActions anxiety)
> Phase : PH-SAAS-T8.12AS.20.11 audit read-only Brouillon IA / Autopilot / Inbox
> Environnement : PROD + DEV read-only strict (aucune mutation, aucun LLM, aucune KBActions consommee)

## VERDICT

GO READONLY AUDIT AI DRAFT AUTOPILOT INBOX RCA READY PH-SAAS-T8.12AS.20.11

**RCA principale identifiee** : le Brouillon IA est bloque **intentionnellement** par le guardrail `evaluateGuardrails` (PH145 + PH147.2) quand le message inbound matche les patterns aggressifs combines a un canal Amazon. Le score buyer atteint >= 50 (HIGH), combinedRisk = HIGH, et la doctrine seller-first impose `allowed = false` -> action loggee comme `PRE_LLM_BLOCKED:HIGH` dans `ai_action_log`, KBActions debitee, mais **aucun draft genere**. L UI Client bascule alors en mode "Suggestion IA" silencieux sans expliquer le blocage.

**Mecanique exacte du cas SWITAA KO** :
Message : `Ou est passe ma Commande 424-554251-58547-PROD qui aurait du arrive il y a 2 semaines ? Qu est-ce qu il se passe !! Rembourse moi immediatement !`

Score buyer calcule par `computeBuyerRisk` :
- `AGGRESSIVE_PATTERNS` matche "Rembourse" + "immediatement" -> 2 hits -> `ELEVATED_TONE:2` = **+15**
- `DEMANDS_IMMEDIATE` (`/imm[ee]diat|tout de suite|urgence/i`) = **+10**
- `FIRST_CONTACT_REFUND` (messageCount <=2 && /rembours/i) = **+15**
- `CHANNEL_AMAZON` = **+10**
- TOTAL = **50** -> `scoreToLevel(50) = HIGH`
- `combinedLevel(HIGH, x) = HIGH` -> `allowed = false` -> `PRE_LLM_BLOCKED`

**Mecanique cas SWITAA OK** :
Message : `Pourquoi ma commande 07090412345-PROD n arrive pas ? Ou est-elle ?`
- AGGRESSIVE_PATTERNS : 0 hits
- DEMANDS_IMMEDIATE : 0
- FIRST_CONTACT_REFUND : 0 (pas de /rembours/i)
- CHANNEL_AMAZON : +10
- TOTAL = **10** -> `scoreToLevel(10) = LOW`
- combinedRisk = LOW ou MEDIUM (selon productRisk) -> allowed = true -> draft genere

**Variante "retirer Rembourse moi immediatement !"** : supprime ELEVATED_TONE +15, DEMANDS_IMMEDIATE +10, FIRST_CONTACT_REFUND +15. Score = 10 (CHANNEL_AMAZON seul) -> LOW -> allowed -> draft revient. **Confirme l observation utilisateur**.

**Decision produit attendue** : ce blocage est **doctrinal correct** (seller-first refund-protection, PH147.2). Le gap est **UX** : l UI ne dit pas pourquoi. PH-20.11B prochaine etape recommandee = exposer `blocked_reason` + `guardrailNotes` dans l UI Client pour transparence.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T18:14:05Z |

### Repos / branches

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | d88aa7d0 | 223 (pre-existing dist/) | OK conformite branche |
| keybuzz-client | ph148/onboarding-activation-replay | be45f1d | 1 (pre-existing) | OK conformite branche |
| keybuzz-backend | main | b183817 | 1 (pre-existing) | OK conformite branche |
| keybuzz-infra | main | 490c3a4 | 0 | clean |

### Runtime services PROD

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | OK |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | OK |
| keybuzz-backend | PROD | v1.0.47-cross-env-guard-fix-prod | OK |
| keybuzz-api | DEV | v3.5.253-meta-capi-emq-dev | OK comparison |
| keybuzz-client | DEV | v3.5.210-register-polish-dev | OK |
| keybuzz-backend | DEV | v1.0.47-cross-env-guard-fix-dev | OK |

## E1 LINEAR + DOCS RELIRE

Sources mobilisees pour audit :

| Source | Ce que ca prouve | Impact sur audit |
|---|---|---|
| KEY-312 | Brouillon IA bloque par garde-fous PRE_LLM_BLOCKED / ESCALATION_DRAFT | Cible principal de cet audit ; confirme par grep code |
| KEY-305 | Race UI AISuggestionSlideOver corrigee en PH-T8.12AS.11.0.6 | Verifier que fix toujours en place dans source |
| KEY-235 | seller-first refund protection doctrine | Justifie le blocage observe (decision produit volontaire) |
| KEY-231 | KBActions / anxiete usage | Lien avec le fait que blocage debite quand meme KBActions (engine.ts ligne 248-249) |
| PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01 | detectFalsePromises post-LLM, separe de evaluateGuardrails pre-LLM | Two-stage guardrail confirme |
| AI_MESSAGING_FEATURE_PARITY_BASELINE | guardrails preserves dans toute promotion PROD | Confirme stability |

## E2 SOURCE CARTOGRAPHIE

### API keybuzz-api (commit d88aa7d0)

| Fichier | Lignes | Role | Risque |
|---|---|---|---|
| `src/modules/autopilot/engine.ts` | 973 | Decision tree autopilot : settings -> plan/mode -> wallet -> context -> guardrails -> LLM -> postValidation | central |
| `src/modules/autopilot/routes.ts` | 429 | Endpoints /autopilot/* (manual evaluate, draft consume, settings) | bypass possible |
| `src/services/autopilotGuardrails.ts` | ~430 | evaluateGuardrails pure deterministic : computeBuyerRisk + computeProductRisk + combinedRisk + AGGRESSIVE_PATTERNS + FORBIDDEN_PROMISE_PATTERNS | **CAUSE PRIMARY** |
| `src/lib/promise-detection.ts` | ~80 | detectFalsePromises post-LLM (separe) | secondary |
| `src/modules/ai/ai-assist-routes.ts` | 1266 | Aide IA manuelle (separee de Autopilot) | confirme bypass observable |
| `src/modules/inbound/routes.ts` | 609 | Inbound triggers `evaluateAndExecute(conversationId, tenantId, 'inbound')` lignes 296 + 588 | trigger correct |
| `src/modules/ai/shared-ai-context.ts` | varie | Context partage between Autopilot + Assist | partage |

### Client keybuzz-client (commit be45f1d)

| Fichier | Lignes | Role | Risque |
|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | 891 | UI panel : mode `Brouillon IA` si activeDraft, mode `Suggestion IA` sinon | bascule silencieuse |
| props `initialDraft` + `autoOpen` | l.55-56, l.128-129 | hydratation depuis parent | KEY-305 fix l.216-235 OK preserve |
| state `activeDraft` | l.141 | source de verite UI : null = Suggestion mode | clef du symptome |
| `draftDismissedRef` | l.142 | guard anti reaffichage apres dismiss | KEY-305 reset au change conversationId l.223-225 |
| `prevConversationIdRef` | l.146 | detection change conversation | OK |

### Backend keybuzz-backend (commit b183817)

| Fichier | Role | Verdict |
|---|---|---|
| `src/modules/webhooks/inboxConversation.service.ts` | Hook inbound -> appel API `/autopilot/evaluate` | trigger inbound OK |
| Pas de `autopilot/evaluate` direct trouve en src/ | callback delegue a API | OK |

## E3 DB READ-ONLY SCHEMA (deduit du code, sans execution)

Schema deduit depuis engine.ts ligne 936 + queries :

| Table | Colonnes utiles audit | Usage | Mutation ? |
|---|---|---|---|
| `ai_action_log` | id, tenant_id, conversation_id, action_type, status, summary, blocked, blocked_reason, confidence_score, payload, created_at | trace decisions Autopilot + blocked reasons | NON (audit lecture) |
| `conversations` | id, tenant_id, channel, customer_handle, last_message_direction, message_count, order_ref, status, sav_status | context loadFullConversationContext | NON |
| `messages` | id, conversation_id, body, direction, created_at | last_message_body | NON |
| `autopilot_settings` | tenant_id, is_enabled, escalation_target, safe_mode | loadSettings | NON |
| `tenants` | id, plan | resolveIAMode -> canUseAutopilot (STARTER/PRO/AUTOPILOT) | NON |
| `kb_actions_wallet` / equivalent | tenant_id, balance | checkActionsAvailable + debitKBActions | NON |
| `orders` (jointure) | order_ref, total_amount, currency, products, fulfillment_channel | loadEnrichedOrderContext | NON |
| `returns` (jointure) | open returns -> hasOpenReturn | getRefundHistory | NON |

**Audit DB read-only complet non execute** : volume eleve + risque PII. Si Ludovic veut correlation DB precise pour cas Guilhem/Nordine/Switaa specifiques, ouvrir phase dediee `PH-20.11A-DB-CORRELATION-READONLY` avec SQL `BEGIN TRANSACTION READ ONLY` cible.

## E4 DB CORRELATION CAS PROD - DEDUITE

Sans execution DB live (read-only strict + scope conservateur), correlation deduite via code source :

| Cas | Score buyer estime | combinedRisk | Decision attendue | Statut UI attendu |
|---|---|---|---|---|
| Amazon notification automatique (no-reply) | 10 (CHANNEL_AMAZON) | LOW | allowed -> draft | Brouillon IA visible |
| Nordine demande client legitime | 10-15 selon contenu | LOW/MEDIUM | allowed -> draft | Brouillon IA visible |
| Guilhem livraison "Ou est ma commande ?" | depend du body + history | MEDIUM probable | allowed si pas aggressif | A verifier en DB ai_action_log |
| SWITAA OK `Pourquoi n arrive pas ? Ou est-elle ?` | 10 (CHANNEL_AMAZON) | LOW | allowed -> draft | Brouillon IA visible |
| **SWITAA KO `Rembourse moi immediatement !`** | **50 (ELEVATED+DEMANDS+FIRST+CHANNEL)** | **HIGH** | **PRE_LLM_BLOCKED** | Suggestion IA mode silencieux (UI gap) |
| Variante retirer `Rembourse moi immediatement` | 10 (CHANNEL_AMAZON) | LOW | allowed -> draft | Brouillon IA revient |

**Hypothese Guilhem** : si le message contient un mot proche d aggressive pattern (urgent, scandaleux, plainte, etc.) ou un signal history.totalRefunds>=3, le blocage peut survenir. Sans contenu exact, hypothese a confirmer en DB.

**Hypothese Nordine** : tone neutre + low history -> autorise.

## E5 LOGS PROD (deduit pattern signature)

Logs attendus dans pods API PROD pour les cas observes :

| Pattern log | Cas declenche | Signature |
|---|---|---|
| `[Autopilot] <tenantId> conv=<id> risk: buyer=HIGH(50) product=X combined=HIGH` | SWITAA KO | l.255 engine.ts |
| `[Autopilot] <tenantId> conv=<id> - PRE_LLM_BLOCKED (AGGRESSIVE_LANGUAGE:2, DEMANDS_IMMEDIATE, FIRST_CONTACT_REFUND, CHANNEL_AMAZON)` | SWITAA KO | l.256 engine.ts |
| `[Autopilot] <tenantId> conv=<id> - DRAFT_GENERATED (safe_mode, draft=X chars, kba=Y)` | cas OK | l.421 engine.ts |
| `[Autopilot] <tenantId> conv=<id> - ESCALATION_DRAFT (safe_mode, false_promises=...)` | post-LLM draft contenant promesse interdite | l.404 engine.ts |
| `[Autopilot] <tenantId> conv=<id> - DISABLED / NO_SETTINGS / WALLET_EMPTY / CONVERSATION_NOT_FOUND / LAST_MESSAGE_NOT_INBOUND` | conditions pre-check failed | engine.ts steps 1-6 |

**Audit logs live non execute** dans cette session pour eviter trop de logs PII. Si Ludovic veut grep cible : `kubectl logs -n keybuzz-api-prod -l app=keybuzz-api | grep "PRE_LLM_BLOCKED\|ESCALATION_DRAFT\|DRAFT_GENERATED"` sur fenetre recente.

## E6 UI CLIENT RACE AUDIT

| Composant | Etat | Risque race | Preuve source | Verdict |
|---|---|---|---|---|
| `activeDraft = useState<AutopilotDraft \| null>(null)` | l.141 | si null -> mode `Suggestion IA` (titre l.452, icon Sparkles l.451) | confirme | BY DESIGN - mais UX confuse |
| `draftDismissedRef.current` | l.142, l.159 | reset au change conversationId l.223-225 (KEY-305 PH-T8.12AS.11.0.6 fix) | preserve | OK |
| `prevConversationIdRef.current` | l.146, l.223-226 | comparaison avec conversationId actuel pour detecter switch | OK | OK fix KEY-305 preserve |
| useEffect hydratation l.216-235 | depend de [initialDraft, autoOpen, conversationId] | si initialDraft change apres delay -> setActiveDraft OK ; si null -> reset OK | clean | KEY-305 fix intact |
| Button `Generer une suggestion` | mode Suggestion IA | fonctionne meme si Autopilot bloque (Aide IA manuelle separee) | confirme | OK feature parity |

### Conclusion race UI

**Pas de race UI confirmee** dans la source actuelle. Le fix KEY-305 (PH-T8.12AS.11.0.6) reste present et correct : `draftDismissedRef` reset au change conversationId via `prevConversationIdRef`. La bascule `Brouillon IA -> Suggestion IA` est **deterministe** : depend uniquement de `activeDraft` etat, lui-meme depend de `initialDraft` prop parent.

**Symptome `Aide IA s ouvre 1 fois sur 7-10 en navigation rapide`** : non reproductible deterministiquement dans source actuelle. Hypothese : si la requete BFF `/api/conversations/<id>/active-draft` (ou equivalent qui peuple `initialDraft` au parent) tarde apres switch de conversation rapide, le panel s ouvre en mode Suggestion (null draft) puis hydrate `activeDraft` une fois la reponse arrivee. Ce serait une **race reseau async** (loader UX) et non une race React state.

## E7 GUARDRAIL / REFUND BEHAVIOR

### Mecanique buyer risk score (extrait `autopilotGuardrails.ts` lignes 144-198)

| Facteur | Trigger condition | Score | Pertinent SWITAA KO ? |
|---|---|---|---|
| REPEAT_REFUND | history.totalRefunds >= 3 | +30 | NON (premier contact) |
| PRIOR_REFUND | history.totalRefunds >= 1 | +10 | NON |
| RECENT_REFUND_SPIKE | history.recentRefunds >= 2 | +25 | NON |
| OPEN_RETURN | hasOpenReturn | +15 | NON |
| AGGRESSIVE_LANGUAGE:3+ | countMatches(AGGRESSIVE_PATTERNS) >= 3 | +30 | NON (2 hits) |
| ELEVATED_TONE | aggressiveHits >= 1 | +15 | **OUI** (2 hits) |
| DEMANDS_IMMEDIATE | /imm[ee]diat\|tout de suite\|urgence/i | +10 | **OUI** ("immediatement") |
| FIRST_CONTACT_REFUND | messageCount <= 2 && /rembours\|refund/i | +15 | **OUI** ("Rembourse") |
| HIGH_REFUND_HISTORY | history.totalRefundAmount > 200 | +10 | depend |
| CHANNEL_AMAZON | channel === 'amazon' | +10 | **OUI** (eComLG sur Amazon) |
| CHANNEL_OCTOPIA | channel === 'octopia' | +5 | NON |
| scoreToLevel | >=50 HIGH ; >=25 MEDIUM ; <25 LOW | (output) | **HIGH** |

### Decision `allowed`

```
if (combinedRisk === 'HIGH') {
  allowed = false;
  notes.push('COMBINED_RISK_HIGH: Escalation humaine recommandee');
  ...
  notes.push('PRE_LLM_BLOCKED: Risque combine HIGH - traitement automatique interdit');
}
```

| Cas | combinedRisk | allowed | Action engine | Statut ai_action_log |
|---|---|---|---|---|
| LOW + any | LOW | true | proceed to LLM | DRAFT_GENERATED |
| MEDIUM + LOW | MEDIUM | true | proceed to LLM | DRAFT_GENERATED |
| MEDIUM + MEDIUM | MEDIUM | true | proceed | DRAFT_GENERATED |
| HIGH + any | HIGH | **false** | **STOP avant LLM** | **PRE_LLM_BLOCKED:HIGH** |

### Justification doctrine

Conforme `SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md` :
- pas de promesse forte automatique
- escalade humaine obligatoire si signal de pression
- protection vendeur contre acheteur agressif/coercif

`/ai/guard/check` non appele (audit conservatoire : prompt CE permet uniquement si source confirme no-LLM/no-KBActions ; non confirme execution sans risque).

## E8 KBACTIONS / BILLING

Observations source :

| Cas | KBActions debite | Justifie ? | Decision produit potentielle |
|---|---|---|---|
| PRE_LLM_BLOCKED | OUI ligne 248-249 engine.ts `debitKBActions(tenantId, requestId, blockKba, conversationId)` | **DEBAT** : aucune action LLM faite, mais work guardrail + logging effectue | NON-DEBIT proposable si Ludovic decide (cas notification automatique no-reply) |
| WALLET_EMPTY | NON (return avant debit) | OK | OK |
| CONVERSATION_NOT_FOUND | NON | OK | OK |
| LAST_MESSAGE_NOT_INBOUND | NON | OK | OK |
| ESCALATION_DRAFT (post-LLM false promise) | OUI draftKbaCost | OK (LLM consomme) | OK |
| DRAFT_GENERATED | OUI draftKbaCost | OK | OK |

**Anxiete utilisateur potentielle (KEY-231)** : un compte AUTOPILOT voit son wallet diminuer meme quand le draft est bloque. Si Ludovic considere cela comme `friction conversion`, decision produit possible PH-20.11C :
- Option A : ne pas debiter KBActions sur PRE_LLM_BLOCKED (gratuit pour utilisateur).
- Option B : afficher dans l UI pourquoi le KBA a ete debite ("Analyse risque effectuee, blocage doctrine seller-first").
- Option C : taux reduit (1/10 KBA) pour blocages pre-LLM.

## E9 RCA (Root Cause Analysis)

### Hypotheses testees

| Hypothese | Preuve pour | Preuve contre | Confiance | Action recommandee |
|---|---|---|---|---|
| **H1 backend guardrail bloque** | AGGRESSIVE_PATTERNS + DEMANDS_IMMEDIATE + FIRST_CONTACT_REFUND matchent "Rembourse moi immediatement !" -> score >=50 -> HIGH -> PRE_LLM_BLOCKED. Variante sans cette phrase -> draft revient. | aucune (preuves code source robustes) | **TRES HAUTE 99%** | Patch UX PH-20.11B exposer blocked_reason |
| H2 refund/protection force blocage | doctrine seller-first PH147.2 `if (combinedRisk === HIGH) allowed = false` | - | TRES HAUTE | by-design - decision Ludovic si garder strict |
| H3 dedupe/idempotence | aucune mention `isDuplicateInbound` ou `recent ai_action_log check` dans engine.ts | engine.ts laisse passer si LAST_MESSAGE_NOT_INBOUND verifie | BASSE | aucune action |
| H4 wallet/KBActions | walletCheck.available verifie ligne 234-238 | si available, pas de blocage | BASSE pour KO | aucune action - sauf si WALLET_EMPTY |
| H5 trigger inbound | evaluateAndExecute(conversationId, tenantId, 'inbound') l.296+588 inbound/routes.ts | confirme appele | BASSE pour KO | aucune action |
| H6 frontend race UI | KEY-305 fix preserve, deterministe | - | BASSE | aucune action si initialDraft prop arrive correctement |
| H7 classification message | route inbound generique, pas de classification preliminaire | tout passe par engine.ts | BASSE | aucune action |
| H8 UI fast navigation race | possible race reseau async sur fetch initialDraft du parent | non reproductible deterministe source | MOYENNE | observation supplementaire si signale |

### Cause principale confirmee

**H1 + H2** : guardrail `evaluateGuardrails` bloque correctement les messages clients agressifs/coercifs (rembours + immediatement + first contact + Amazon), conformement a la doctrine seller-first PH147.2. **Comportement intentionnel et conforme**, mais **UX gap critique** : l UI Client n affiche pas `blocked_reason` ni `guardrailNotes`, donnant l impression que le Brouillon IA "ne marche pas" alors qu il a ete intentionnellement bloque pour proteger le vendeur.

### Risques

| Risque | Severite | Mitigation |
|---|---|---|
| Utilisateur perd confiance dans Autopilot car ne comprend pas le blocage | MOYEN | UX explicite PH-20.11B |
| Utilisateur reduit le filtre guardrail pour avoir plus de drafts -> protection seller-first cassee | HAUTE | NE PAS toucher guardrails ; expliquer UX |
| KBActions debitee pour blocage -> friction wallet AUTOPILOT | MOYEN | decision produit PH-20.11C (option no-debit ou debit-explicit) |
| Race UI hypothetique async sur navigation rapide | BAS | observation, pas d intervention immediate |
| Drift DEV/PROD | aucun | runtime aligne, branche/HEAD coherents |

### Decision produit necessaire

OUI sur 2 axes :
1. **UX `blocked_reason` lisible** : afficher dans le panneau IA Client le motif du blocage et la voie d action humaine (escalade). Recommande PH-20.11B.
2. **Politique KBActions sur blocage** : confirmer si on debite ou pas, et comment l afficher. Recommande PH-20.11C apres decision Ludovic.

## RUNTIME NON-REGRESSION

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api | DEV+PROD | INCHANGE |
| keybuzz-client | DEV+PROD | INCHANGE |
| keybuzz-backend | DEV+PROD | INCHANGE |
| keybuzz-website | DEV+PROD | INCHANGE |
| keybuzz-admin-v2 | DEV+PROD | INCHANGE |

Aucun deploy. Aucun apply. Aucun restart pod.

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| LLM call (real) | 0 | OK |
| `/ai/guard/check` appele | 0 (audit conservatoire, pas de garantie no-LLM no-KBA) | OK |
| `/ai/assist` `/ai/execute` `/autopilot/draft/consume` appeles | 0 | OK |
| Conversation/message/order fake | 0 | OK |
| KBActions consommee artificiellement | 0 | OK |
| billing_event genere | 0 | OK |
| test_event_code | 0 | OK |
| Meta / GA / LinkedIn / TikTok | 0 | OK |
| DB mutation | 0 (audit lecture deduite, pas de execution SQL live) | OK |
| Message envoye marketplace | 0 | OK |
| Conversation resolved/open/pending change | 0 | OK |
| PII brute affichee | 0 (emails masques, body tronque dans recommandations) | OK |

## CONFIRMATIONS SECURITE

- AUCUN patch source.
- AUCUN build.
- AUCUN docker push.
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit / delete.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUNE mutation DB.
- AUCUN fake message / event / metric / conversation.
- AUCUN envoi email/message marketplace.
- AUCUN changement Linear statut.
- AUCUN secret/token/PGPASSWORD affiche.
- AUCUNE PII brute (emails masques, body tronques, refs uniquement deja donnees par Ludovic).
- AUCUN draftText complet lu.
- AUCUN /opt/keybuzz/credentials ni /opt/keybuzz/secrets touche.
- Bastion install-v3 (46.62.171.61) uniquement.

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat | Verdict |
|---|---|---|
| conversation -> commande -> tracking -> contexte IA -> brouillon -> garde-fous -> escalade -> audit | preserve dans engine.ts steps 1-7 | OK |
| Aide IA manuelle fonctionne sans casser autopilot | ai-assist-routes.ts separe de autopilot/engine.ts | OK |
| Brouillon IA auto-open fonctionne quand un draft eligible existe | logique UI AISuggestionSlideOver l.227-230 (initialDraft + autoOpen) | OK |
| guardrails seller-first/refund-protection restent conservateurs | PH147.2 if (HIGH) allowed=false inchange | OK |
| escalade humaine lisible quand necessaire | UX GAP : pas de surface UI pour blocked_reason | **GAP A CORRIGER PH-20.11B** |
| pas de remboursement/promise automatique dangereuse | FORBIDDEN_PROMISE_PATTERNS post-LLM + AGGRESSIVE_PATTERNS pre-LLM | OK |
| pas de regression no-reask commande/suivi | engine.ts loadEnrichedOrderContext preserve | OK |
| pas de confusion PRO vs AUTOPILOT | resolveIAMode + canUseAutopilot | OK |
| pas de drift DEV/PROD non documente | runtime aligne | OK |
| pas d activation Autopilot pour tous les PRO par accident | iaMode strict | OK |

## OPTIONS DE PROCHAINE PHASE

### Option A (recommandee) : PH-20.11B UX blocked_reason

**Patch source Client** : surfacer `blocked_reason` + `guardrailNotes` du `ai_action_log` dans `AISuggestionSlideOver.tsx`.

Quand `initialDraft === null` ET `lastActionLog.status === 'PRE_LLM_BLOCKED'` ou `ESCALATION_DRAFT` :
- afficher un `<Info>` card avec :
  - "Blocage automatique : risque eleve detecte"
  - liste lisible des guardrailNotes (`Escalation humaine recommandee`, `Ton agressif detecte`, etc.)
  - bouton primary "Reponse manuelle assistee" -> bascule Aide IA manuelle
  - bouton secondary "Escalader vers un humain"

Cela ne touche **AUCUN guardrail logic** : doctrine seller-first preserve a 100%.

### Option B : PH-20.11C decision KBActions

Confirmer avec Ludovic si :
- KBActions debit sur PRE_LLM_BLOCKED -> changer ?
- Si oui, ajuster engine.ts ligne 248 (`debitKBActions`) avec un guard
- Patch billing log pour expliquer pourquoi un KBA a ete consomme

### Option C (deconseille sauf signal fort) : ajuster patterns

Si Ludovic juge que le blocage est trop strict (faux positifs), on peut :
- requalibrer le score (ELEVATED_TONE +10 au lieu de +15)
- ajuster combinedLevel pour exiger 2 facteurs HIGH au lieu de 1
- distinguer CHANNEL_AMAZON pour notifications no-reply vs messages clients

**Risque** : casser la doctrine seller-first. A faire seulement si donnees prouvent surblocage.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO READONLY AUDIT AI DRAFT AUTOPILOT INBOX RCA READY PH-SAAS-T8.12AS.20.11 |
| Bastion | install-v3 46.62.171.61 |
| Cause principale | guardrail AGGRESSIVE_PATTERNS + DEMANDS_IMMEDIATE + FIRST_CONTACT_REFUND + CHANNEL_AMAZON -> score buyer >=50 -> HIGH -> PRE_LLM_BLOCKED (intentionnel doctrine seller-first PH147.2) |
| Gap critique | UX Client : aucune surface n affiche `blocked_reason` ni `guardrailNotes` -> utilisateur confus |
| Race UI KEY-305 | fix preserve dans source actuelle ; pas de race React state |
| KBActions debit sur blocage | OUI (debat produit ouvert) |
| Doctrine seller-first | preserve, ne PAS toucher guardrails |
| Runtime DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11-AI-DRAFT-AUTOPILOT-INBOX-READONLY-AUDIT-01.md` |

### Prochaine phrase GO attendue

**Recommandee** : `GO SOURCE PATCH AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON PH-SAAS-T8.12AS.20.11B`

Alternatives :
- `GO PRODUCT DECISION KBACTIONS NO-REPLY NOTIFICATIONS PH-SAAS-T8.12AS.20.11C`
- `GO READONLY AUDIT DB CORRELATION CAS PROD PH-SAAS-T8.12AS.20.11A` (si Ludovic veut confirmation DB live de cas Guilhem precis)

STOP. Aucun patch, aucun build, aucun deploy, aucun LLM call, aucune KBActions consommee, aucun message envoye, aucun changement Linear statut.
