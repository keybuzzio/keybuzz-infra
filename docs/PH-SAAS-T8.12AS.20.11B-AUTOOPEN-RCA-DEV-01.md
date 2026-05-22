# PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related)
> Phase : PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA Client DEV read-only
> Environnement : DEV read-only (aucun PROD, aucun LLM, aucune KBActions, aucune mutation DB)

## VERDICT

**STOP BUG CLIENT AUTOOPEN PATCH REQUIRED PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA**

- Cas Ludovic DEV reproduit cote API : conversation `cmmphi008y8f98ba07...` (SWITAA Amazon, order `4114-8854552147-0200022141-DEV`, message "Rembourse moi tout de suite") -> `ai_action_log = autopilot_reply status:skipped blocked:true reason:PRE_LLM_BLOCKED:HIGH`.
- API DEV `/autopilot/draft` retourne correctement : HTTP 200, `hasDraft:false, blocked:true, blockedStatus:PRE_LLM_BLOCKED, draftText absent`.
- Le wire parent `InboxTripane.tsx` l.357-385 appelle bien `setAutopilotAutoOpen(true)` dans la branche `else if (data.blocked)`.
- **MAIS** : `AISuggestionSlideOver.tsx` l.238 a une condition d'auto-ouverture `initialDraft?.draftText && autoOpen && conversationId` qui **exclut le cas blocked** (parce que `initialDraft = null` dans ce cas) -> le drawer ne s'ouvre PAS automatiquement.
- L'utilisateur voit uniquement le label "Brouillon IA disponible" + bouton "Ouvrir l'assistant" generes par `aiSuggestions.ts` l.93 (fallback independant base sur `(isPending || isOpen) && lastIsInbound`), pas la carte UX "Garde-fou actif" PH-20.11B.
- Cause primary : **D - AISuggestionSlideOver ignore autoOpen quand activeDraft existe pas (regression PH-20.11B-PARENT-WIRE incomplete).**

Patch minimal recommande : etendre la condition useEffect SlideOver l.238 pour inclure `blockedInfo?.blocked`. NE PAS appliquer dans cette phase (read-only RCA).

NE PAS promouvoir Client v3.5.212 en PROD : la carte UX reste non visible pour les cas blocked en auto-ouverture.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T22:51:30Z |
| kube-context | kubernetes-admin@kubernetes |
| API DEV runtime | v3.5.254-ai-draft-blocked-reason-dev (mh5d5 Ready, 0 restart) |
| Client DEV runtime | v3.5.212-ai-draft-blocked-reason-dev (7wp7g Ready, 0 restart) |
| API PROD runtime | v3.5.252-meta-capi-emq-prod INCHANGE |
| Client PROD runtime | v3.5.201-register-polish-prod INCHANGE |

## E1 IDENTIFICATION CONVERSATION DEV LUDOVIC

| Indicateur | Valeur (tronquee) |
|---|---|
| tenant | switaa-sasu-mnc... |
| conversation_id | cmmphi008y8f98ba07... |
| order_ref | NULL au niveau conversation (l'order est dans subject/preview body) |
| channel | amazon |
| status | open |
| sav_status | null |
| escalation_status | **none** (note : UI affiche "Escalade" via autre mecanisme) |
| last_inbound_at | 2026-05-22 22:35:26 UTC (= 2026-05-23 00:35:26 Paris) |
| preview60 | "--_000_a8ecac53839c4cadb086047d189f0e60switaacom_ ... Pourquoi" |
| Match keyword "Rembourse" | OUI |

Confirmation : c'est bien la conversation observee dans le screenshot Ludovic.

## E2 CONTRACT API SUR CETTE CONVERSATION

### ai_action_log

| Indicateur | Valeur |
|---|---|
| Nombre de rows pour cette conv | 1 |
| action_type | `autopilot_reply` |
| status | **skipped** |
| blocked | **true** |
| blocked_reason | `PRE_LLM_BLOCKED:HIGH` |
| confidence_score | 0.00 |
| confidence_level | null |
| created_at | 2026-05-22 22:35:27 |

### API GET /autopilot/draft (probe authentifie HTTP)

| Indicateur | Resultat |
|---|---|
| HTTP | **200** |
| hasDraft | **false** |
| blocked | **true** |
| blockedStatus | **PRE_LLM_BLOCKED** |
| confidence | undefined |
| needsHumanAction | undefined |
| escalationStatus | undefined |
| createdAt | 2026-05-22T22:35:27.146Z |
| logId | null |
| draftText length | 0 (absent) |

API contract OK : retourne bien le blocked info.

## E3 CLIENT/BFF CONTRACT

| Layer | Etat | Verdict |
|---|---|---|
| `app/api/autopilot/draft/route.ts` | transit transparent `await res.json()` -> forward natural | OK |
| Bundle Client `/app/.next` `blockedInfo` markers | 4 occurrences | OK |
| Bundle Client `data.hasDraft / data.blocked` (minifie : .hasDraft/.blocked) | present indirectement | OK |
| Wire parent InboxTripane.tsx | `else if (data.blocked)` appelle `setAutopilotBlockedInfo({...})` + `setAutopilotAutoOpen(true)` | OK |

Le contrat API+BFF+state parent est CORRECT. Le bug n'est pas la.

## E4 AUDIT SOURCE PARENT AUTO-OPEN

### `app/inbox/InboxTripane.tsx` l.357-385 (extrait reel)

```typescript
if (data.hasDraft && data.draftText) {
  setAutopilotDraft({...});
  setAutopilotAutoOpen(true);
  setAutopilotBlockedInfo(null);
} else if (data.blocked) {
  // PH-SAAS-T8.12AS.20.11B-PARENT-WIRE KEY-312: hydrate blocked guardrail reason
  setAutopilotDraft(null);
  setAutopilotAutoOpen(true);              // <-- autoOpen=true LIVE
  setAutopilotBlockedInfo({
    blocked: true,
    blockedStatus: data.blockedStatus ?? 'PRE_LLM_BLOCKED',
    ...
  });
}
```

Parent OK : `autopilotAutoOpen = true` + `autopilotBlockedInfo = {blocked: true, ...}`.

### `src/features/ai-ui/AISuggestionSlideOver.tsx` l.234-247 (extrait reel)

```typescript
useEffect(() => {
  if (prevConversationIdRef.current !== conversationId) {
    draftDismissedRef.current = null;
    prevConversationIdRef.current = conversationId;
  }
  if (initialDraft?.draftText && autoOpen && conversationId) {  // <-- CONDITION RESTRICTIVE
    if (draftDismissedRef.current !== conversationId) {
      setActiveDraft(initialDraft);
      setIsOpen(true);                                          // <-- OUVERTURE ICI
    }
  } else if (!initialDraft) {
    setActiveDraft(null);
  }
}, [initialDraft, autoOpen, conversationId]);
```

**LE BUG** : la condition d'auto-ouverture requiert `initialDraft?.draftText`. Quand `data.blocked=true`, le parent met `autopilotDraft = null` -> `initialDraft = null` -> `null?.draftText = undefined` -> condition false -> **drawer ne s'ouvre PAS**.

Resultat : utilisateur voit UNIQUEMENT le label fallback "Brouillon IA disponible" (du fichier `aiSuggestions.ts`) et doit cliquer manuellement "Ouvrir l'assistant" -> alors seulement la carte amber "Garde-fou actif" s'affiche.

### `src/features/inbox/utils/aiSuggestions.ts` l.89-97 (source du label visible Ludovic)

```typescript
if ((isPending || isOpen) && lastIsInbound) {
  suggestions.push({
    id: 'reply-' + conv.id,
    type: 'reply',
    label: 'Brouillon IA disponible',
    reason: 'L\'assistant IA peut generer un brouillon de reponse pour cette conversation',
    confidence: 0.6,
    actionLabel: 'Ouvrir l\'assistant',
  });
}
```

INDEPENDANT de notre patch PH-20.11B : `aiSuggestions.ts` cree ce label en proactif des qu'une conversation est ouverte+inbound, sans verifier le status reel du draft/block.

### Table audit source

| Fichier | Ligne | Condition | Effet actuel | Risque | Verdict |
|---|---|---|---|---|---|
| `InboxTripane.tsx` | 357-385 | `else if (data.blocked)` | hydrate state OK | aucun | OK |
| **`AISuggestionSlideOver.tsx`** | **238** | **`initialDraft?.draftText && autoOpen`** | **drawer reste ferme pour blocked** | **regression UX PH-20.11B incomplete** | **BUG** |
| `aiSuggestions.ts` | 89-97 | `(isPending \|\| isOpen) && lastIsInbound` | label "Brouillon IA disponible" + "Ouvrir l'assistant" | independant - confond avec le drawer | secondaire (UX) |

## E5 AUDIT NAVIGATEUR

Non execute (CE pas de session browser disponible). RCA suffisante par audit source + probe API authentifie.

## E6 HYPOTHESES TRANCHEES

| # | Hypothese | Statut | Preuve d'exclusion / Confirmation |
|---|---|---|---|
| A | API contract incorrect | EXCLUE | API HTTP 200 + blocked:true correct |
| B | BFF droppe des champs | EXCLUE | `app/api/autopilot/draft/route.ts` = transit transparent `await res.json()` |
| C | Parent InboxTripane n'appelle pas setAutopilotAutoOpen | EXCLUE | l.385 `setAutopilotAutoOpen(true)` cable dans la branche blocked |
| **D** | **AISuggestionSlideOver ignore autoOpen sans activeDraft** | **CONFIRMEE PRIMARY** | l.238 condition `initialDraft?.draftText && autoOpen` exclut blocked |
| E | Race KEY-305 regression | EXCLUE | draftDismissedRef + prevConversationIdRef preserve, hash autopilotGuardrails.ts inchange |
| F | Produit volontaire | EXCLUE | l'intent PH-20.11B etait exactement d'afficher la raison automatiquement |
| G | Cache/stale route | EXCLUE | rollout 0 restart 7wp7g, bundle `blockedInfo=4` LIVE, runtime digest match GHCR |
| H | Autre | NA | NA |

**Cause primary D confirmee** : regression UX PH-20.11B-PARENT-WIRE incomplete - l'extension de la condition d'auto-ouverture du SlideOver pour inclure `blockedInfo?.blocked` a ete oubliee.

## E7 PATCH RECOMMANDE (a ne pas executer dans cette phase)

### Patch minimal AISuggestionSlideOver.tsx l.238

```diff
- if (initialDraft?.draftText && autoOpen && conversationId) {
-   if (draftDismissedRef.current !== conversationId) {
-     setActiveDraft(initialDraft);
-     setIsOpen(true);
-   }
- } else if (!initialDraft) {
-   setActiveDraft(null);
- }
+ const shouldAutoOpen =
+   (initialDraft?.draftText || blockedInfo?.blocked) && autoOpen && conversationId;
+ if (shouldAutoOpen) {
+   if (draftDismissedRef.current !== conversationId) {
+     if (initialDraft?.draftText) setActiveDraft(initialDraft);
+     setIsOpen(true);
+   }
+ } else if (!initialDraft && !blockedInfo?.blocked) {
+   setActiveDraft(null);
+ }
```

Plus le dep array : `[initialDraft, autoOpen, conversationId, blockedInfo]`.

Promesses respectees :
- KEY-305 race UI fix preserve : `draftDismissedRef.current !== conversationId` toujours respecte (user qui a ferme manuellement le drawer pour cette conv ne le voit pas se rouvrir).
- Brouillon IA normal preserve : `initialDraft?.draftText && autoOpen` continue de fonctionner.
- Suggestion IA manuelle preserve.
- Aide IA preserve.
- Aucun changement guardrails seller-first.
- Aucun changement billing/KBActions.
- Aucun changement source API (commit 5070e6a6 deja deploye, ne pas rebuilder).

Build cycle requis ensuite :
1. patch source Client (nouveau commit Client `<sha>`)
2. build Client DEV `v3.5.213-ai-draft-blocked-reason-dev`
3. push GHCR
4. apply DEV (GitOps)
5. QA browser Ludovic visuel
6. promotion PROD si visuel OK

## E8 LOGS POST-PROBE

| Pattern | Count | Verdict |
|---|---|---|
| API DEV TypeError | 0 | OK |
| API DEV HTTP 500 | 0 | OK |
| API DEV /ai/assist declenche | 0 | OK |
| API DEV /draft/consume declenche | 0 | OK |
| Client DEV TypeError | 0 | OK |
| Client DEV ChunkLoadError | 0 | OK |

Aucune KBActions consommee. Aucun appel LLM volontaire. Aucun message marketplace. Aucun event marketing.

## TABLEAUX FINAUX

### 1. Repos / Git

| Repo | Branche | HEAD avant | Dirty avant | Dirty apres | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 5070e6a6 | NA (read-only audit) | NA | OK |
| keybuzz-client | ph148/onboarding-activation-replay | beabcd81 | NA (read-only audit) | NA | OK |
| keybuzz-infra | main | 69769b1 | 0 | 0 (apres push rapport) | OK |

### 2. Runtime services

| Service | Runtime DEV | Runtime PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.254-ai-draft-blocked-reason-dev | v3.5.252-meta-capi-emq-prod | inchanges |
| keybuzz-client | v3.5.212-ai-draft-blocked-reason-dev | v3.5.201-register-polish-prod | inchanges |
| keybuzz-backend | v1.0.47 | v1.0.47 | inchanges |
| keybuzz-website | v0.6.21 | v0.6.21-pricing-action-recover-prod | inchanges |

### 3. Conversation matrice

| Conversation | API hasDraft | API blocked | action status | UI observee | Verdict |
|---|---|---|---|---|---|
| cmmphi008y8f98ba07... | false | true | autopilot_reply skipped (PRE_LLM_BLOCKED:HIGH) | "Brouillon IA disponible" + drawer ferme | BUG client autoOpen |

### 4. Audit source matrice

| Fichier | Ligne | Cause potentielle | Decision |
|---|---|---|---|
| InboxTripane.tsx | 385 | setAutopilotAutoOpen(true) dans branche blocked | OK (deja correct) |
| AISuggestionSlideOver.tsx | 238 | condition `initialDraft?.draftText && autoOpen` ignore blockedInfo | **PATCH REQUIS** |
| aiSuggestions.ts | 93 | label "Brouillon IA disponible" fallback proactif independant | independant (peut preter e confusion mais pas a fixer dans le scope PH-20.11B) |

### 5. Tests matrice

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| API contract `/autopilot/draft` sur conv blocked | blocked:true | OK | PASS |
| Client bundle blockedInfo present | >= 2 occurrences | 4 | PASS |
| Parent state hydration `data.blocked` | setAutopilotBlockedInfo + setAutopilotAutoOpen(true) | OK | PASS |
| SlideOver auto-open quand blocked | drawer ouvre | NO | **FAIL (bug confirme)** |
| Logs 0 erreur | 0/0/0/0 | OK | PASS |
| KBActions consommee QA | 0 | 0 | PASS |
| Mutation DB QA | 0 | 0 (BEGIN READ ONLY + ROLLBACK) | PASS |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| Aucun docker build/push | OUI | aucune commande build |
| Aucun deploy DEV/PROD | OUI | aucun kubectl apply |
| Aucun kubectl set/patch/edit/delete | OUI | uniquement get/exec read-only |
| Aucun restart pod | OUI | uptime pods preserve (mh5d5 21:06:19Z, 7wp7g 22:04:03Z) |
| Aucun clic Generer/Valider/Ignorer | OUI | CE pas de session browser |
| Aucun /ai/assist /ai/execute /draft/consume | OUI | logs count = 0 |
| Aucun envoi marketplace | OUI | NA |
| Aucun fake event/metric/KBActions | OUI | confirme par logs |
| Aucune mutation DB hors READ ONLY/ROLLBACK | OUI | BEGIN READ ONLY + ROLLBACK explicite |
| Aucun secret/token/PII brut | OUI | email REDACTED, IDs tronques, body tronque |
| Aucun changement Linear statut | OUI | comment only |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN restart pod.
- AUCUN kubectl mutation.
- AUCUN changement source.
- AUCUN clic Generer/Valider/Ignorer.
- AUCUNE generation IA reelle.
- AUCUNE KBActions consommee.
- AUCUN message envoye.
- AUCUN changement statut conversation.
- AUCUN changement Linear statut.
- AUCUN secret/token/PII brut.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix preserve source.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **STOP BUG CLIENT AUTOOPEN PATCH REQUIRED PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA** |
| Cause primary | D - AISuggestionSlideOver.tsx l.238 ignore blockedInfo dans la condition d'auto-ouverture |
| API contract | CORRECT (HTTP 200, blocked:true, blockedStatus:PRE_LLM_BLOCKED) |
| BFF transit | CORRECT (forward transparent) |
| Parent wire | CORRECT (setAutopilotAutoOpen(true) + setAutopilotBlockedInfo cable) |
| SlideOver auto-open | **INCOMPLET pour le cas blocked** |
| Doctrine seller-first | preserve 100% |
| KEY-305 race fix | preserve |
| Runtime DEV/PROD | INCHANGES (read-only audit) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA-DEV-01.md` |

### Prochaine phrase GO attendue

`GO SOURCE PATCH CLIENT AI DRAFT AUTOOPEN ESCALATION DEV PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX`

(patch source AISuggestionSlideOver.tsx + commit + rebuild Client v3.5.213-ai-draft-blocked-reason-dev + push + apply DEV + QA visuel Ludovic + promotion PROD si OK)

STOP. Aucun PROD, aucun LLM, aucune KBActions, aucun changement Linear statut.
