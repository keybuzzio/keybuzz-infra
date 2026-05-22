# PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-SOURCE-PATCH-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related)
> Phase : PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX source patch Client only
> Environnement : Source patch only (aucun build, aucun deploy, aucun LLM, aucune KBActions)

## VERDICT

GO SOURCE PATCH CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX

- Patch source minimal applique sur `src/features/ai-ui/AISuggestionSlideOver.tsx` (+9 / -4 lignes).
- Client commit `d132cc4f` push origin `ph148/onboarding-activation-replay`.
- Condition useEffect d'auto-ouverture etendue pour inclure `blockedInfo?.blocked` -> le drawer s'ouvre desormais aussi pour les cas `PRE_LLM_BLOCKED` / `ESCALATION_DRAFT`.
- KEY-305 race UI fix preserve : `draftDismissedRef.current !== conversationId` toujours respecte (user qui a ferme manuellement le drawer pour cette conversation ne le voit pas se rouvrir).
- Doctrine seller-first INCHANGE 100% (`autopilotGuardrails.ts` hash inchange, aucun changement API).
- AI feature parity preserve : Brouillon IA normal (draftText), Suggestion IA, Aide IA.
- tsc Client exit 0 (0 erreur nouvelle).
- Aucun fichier hors AISuggestionSlideOver.tsx modifie.

NE PAS rebuild/push/deploy dans cette phase. Sequence prochaine : build Client DEV depuis d132cc4f.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T23:24:49Z |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| keybuzz-client HEAD avant | beabcd8 |
| keybuzz-client HEAD apres | **d132cc4f** |
| Dirty avant patch | 1 (`tsconfig.tsbuildinfo` cache pre-existant, non lie) |
| Commit parent-wire (beabcd81) present | OUI |

## E1 AUDIT SOURCE AVANT PATCH

### Markers source initiaux (AISuggestionSlideOver.tsx)

| Marker | Count avant | Verdict |
|---|---|---|
| `blockedInfo?.blocked` | 0 | absent dans le useEffect (BUG confirme) |
| `draftDismissedRef` | 5 | KEY-305 preserve |
| `prevConversationIdRef` | 3 | KEY-305 preserve |
| `AutopilotBlockedInfo` | 2 | interface + prop type OK |
| `Garde-fou actif` | 1 | texte UX carte amber OK |

### Code initial (l.238)

```typescript
if (initialDraft?.draftText && autoOpen && conversationId) {
  if (draftDismissedRef.current !== conversationId) {
    setActiveDraft(initialDraft);
    setIsOpen(true);
  }
} else if (!initialDraft) {
  setActiveDraft(null);
}
```

Condition exclut le cas blocked (initialDraft=null) -> drawer ne s'ouvre PAS.

## E2 PATCH MINIMAL APPLIQUE

### `src/features/ai-ui/AISuggestionSlideOver.tsx` (+9 / -4 lignes)

```diff
- if (initialDraft?.draftText && autoOpen && conversationId) {
-   if (draftDismissedRef.current !== conversationId) {
-     setActiveDraft(initialDraft);
-     setIsOpen(true);
-   }
- } else if (!initialDraft) {
-   setActiveDraft(null);
- }
- }, [initialDraft, autoOpen, conversationId]);
+ // PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX KEY-312: ouvre aussi le drawer quand blockedInfo.blocked est true (PRE_LLM_BLOCKED / ESCALATION_DRAFT)
+ const shouldAutoOpen =
+   Boolean(autoOpen) && Boolean(conversationId) && Boolean(initialDraft?.draftText || blockedInfo?.blocked);
+ if (shouldAutoOpen) {
+   if (draftDismissedRef.current !== conversationId) {
+     if (initialDraft?.draftText) {
+       setActiveDraft(initialDraft);
+     }
+     setIsOpen(true);
+   }
+ } else if (!initialDraft && !blockedInfo?.blocked) {
+   setActiveDraft(null);
+ }
+ }, [initialDraft, autoOpen, conversationId, blockedInfo]);
```

### Logique apres patch

- **Cas Brouillon IA normal** (`initialDraft.draftText` existe) : auto-open + setActiveDraft preserve (comportement v3.5.211/v3.5.212 inchange).
- **Cas blocked PRE_LLM_BLOCKED / ESCALATION_DRAFT** (`blockedInfo.blocked=true`, `initialDraft=null`) : auto-open du drawer SANS setActiveDraft (pas de fake draft) -> la carte amber `Garde-fou actif` est rendue (l.691 condition `!activeDraft && blockedInfo && blockedInfo.blocked`).
- **Cas neutre** (ni draft ni blocked) : reset activeDraft a null comme avant.
- **KEY-305 race fix** : `draftDismissedRef.current !== conversationId` preserve - si user a ferme manuellement le drawer pour cette conversation, il ne se rouvre pas.
- **dependency array** : `blockedInfo` ajoute pour re-evaluer le useEffect quand le state parent change.

## E3 TESTS SOURCE

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| tsc Client | `npx tsc --noEmit` | exit 0 | OK |
| 0 erreur nouvelle | filtree hors `.next/types/debug-env` pre-existant | 0 | OK |

## E4 ANTI-REGRESSION SOURCE POST-PATCH

| Controle | Avant | Apres | Verdict |
|---|---|---|---|
| `blockedInfo?.blocked` dans SlideOver | 0 | 2 (1 dans `shouldAutoOpen`, 1 dans `else if`) | OK active |
| `draftDismissedRef` (KEY-305 race fix) | 5 | 5 | preserve |
| `prevConversationIdRef` (KEY-305) | 3 | 3 | preserve |
| `shouldAutoOpen` | 0 | 2 (declaration + use) | OK |
| Carte UX `Garde-fou actif` | 1 | 1 | preserve |
| Carte UX `Brouillon IA bloque` | 1 | 1 | preserve |
| Carte UX `Validation humaine recommandee` | 1 | 1 | preserve |
| AI feature parity (Aide IA + Suggestion IA + Brouillon IA total) | 15 | 15 | preserve |
| `autopilotGuardrails.ts` modifie | NON | NON | OK |
| `engine.ts` API modifie | NON | NON | OK |
| `app/api/autopilot/draft` BFF modifie | NON | NON | OK |
| `app/inbox/InboxTripane.tsx` modifie | NON | NON | OK (deja patche beabcd81) |
| `aiSuggestions.ts` modifie | NON | NON | OK (independant) |

## E5 DIFF REVIEW

| Fichier | + | - | Justification | Risque |
|---|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | 9 | 4 | etendre condition useEffect pour inclure blockedInfo | bas (logique additive + tests passes) |

Aucun autre fichier modifie. Scope strict respecte.

## E6 COMMIT + PUSH

| Repo | Branche | Commit | Push | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | **d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6** | OK beabcd8..d132cc4 | OK |

Message commit : `fix(inbox): auto-open blocked AI draft drawer PH-20.11B KEY-312`

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Avant patch | Apres patch | Verdict |
|---|---|---|---|
| Brouillon IA normal (DRAFT_GENERATED) | drawer auto-ouvre si draftText | drawer auto-ouvre si draftText (inchange) | OK |
| Brouillon IA blocked (PRE_LLM_BLOCKED) | drawer reste FERME | drawer s'ouvre automatiquement + carte amber visible | **FIX** |
| Brouillon IA blocked (ESCALATION_DRAFT) | drawer reste FERME si pas de draftText | drawer s'ouvre automatiquement + carte amber visible | **FIX** |
| Suggestion IA fallback (sans draft) | accessible via "Ouvrir l'assistant" | accessible via "Ouvrir l'assistant" inchange | preserve |
| Aide IA manuelle | accessible | accessible | preserve |
| Autopilot guardrails | INCHANGE (autopilotGuardrails.ts hash 5e62bbbe) | INCHANGE | preserve 100% |
| Escalation flow | INCHANGE | INCHANGE | preserve |
| KBActions billing | INCHANGE | INCHANGE | preserve |
| KEY-305 race UI fix | `draftDismissedRef` + `prevConversationIdRef` 5/3 | preserve 5/3 | OK |
| KEY-235 refund protection | INCHANGE | INCHANGE | OK |
| KEY-231 no anxiety billing | INCHANGE | INCHANGE | OK |
| KEY-263 DEV/PROD isolation | INCHANGE (aucun changement endpoint) | INCHANGE | OK |
| KEY-302 build args | INCHANGE (Dockerfile/build args inchanges) | INCHANGE | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun event marketing genere | 0 | OK |
| Aucun fake lead/register/checkout | 0 | OK |
| Aucun fake message | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun appel LLM | 0 | OK |
| Aucune mutation DB | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN restart pod.
- AUCUN kubectl mutation.
- AUCUN changement API.
- AUCUN changement guardrails seller-first.
- AUCUN changement billing/KBActions.
- AUCUN changement `aiSuggestions.ts`.
- AUCUN changement `app/inbox/InboxTripane.tsx` (deja patche en beabcd81).
- AUCUN changement BFF `app/api/autopilot/draft/route.ts`.
- AUCUN clic UI Generer/Valider/Ignorer.
- AUCUN /ai/assist /ai/execute /autopilot/draft/consume.
- AUCUN changement Linear statut.
- AUCUN secret/token/PII brut.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix race UI preserve (draftDismissedRef + prevConversationIdRef).
- KEY-263 isolation DEV/PROD respectee (aucun endpoint touche).
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | v3.5.212-ai-draft-blocked-reason-dev | INCHANGE (patch source seulement) |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-backend / Website | DEV+PROD | inchanges | INCHANGES |

## TABLEAUX FINAUX

### 1. Repos / Git

| Repo | Branche | HEAD avant | HEAD apres | Dirty avant | Dirty apres | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | beabcd8 | **d132cc4f** | 1 (tsbuildinfo cache) | 0 sur source | OK |
| keybuzz-api | ph147.4/source-of-truth | 5070e6a6 | inchange | NA | NA | OK |
| keybuzz-infra | main | 79dca5b | (apres push rapport) | 0 | 0 | OK |

### 2. Fichiers changes

| Fichier | Changement | Risque | Mitigation |
|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | useEffect autoOpen elargi a blockedInfo + dep array | bas | tsc OK + KEY-305 preserve + scope strict |

### 3. Tests

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| tsc Client | 0 erreur nouvelle | exit 0 | PASS |
| Markers patch | shouldAutoOpen=2, blockedInfo?.blocked=2 | OK | PASS |
| KEY-305 preserve | draftDismissedRef=5, prevConversationIdRef=3 | OK | PASS |
| Carte UX preserve | Garde-fou actif=1, Brouillon IA bloque=1, Validation humaine=1 | OK | PASS |
| Scope strict | 1 fichier modifie | OK | PASS |

### 4. Features IA

| Feature | Avant | Apres | Verdict |
|---|---|---|---|
| Draft normal auto-open | OK | OK | preserve |
| Blocked auto-open | KO (bug) | OK (fix) | FIX |
| KEY-305 dismiss preserve | OK | OK | preserve |
| Guardrails seller-first | OK | OK | preserve 100% |
| KBActions billing | OK | OK | preserve |

### 5. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucune commande build |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement get/exec read-only |
| restart pod | OUI | uptime pods preserve |
| /ai/assist /ai/execute /draft/consume | OUI | aucun appel |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB dans cette phase |
| modification API | OUI | aucune commit API |
| modification autopilotGuardrails.ts | OUI | hash 5e62bbbe inchange |
| modification engine.ts | OUI | inchange |
| changement Linear statut | OUI | comment only |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **GO SOURCE PATCH CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX** |
| Bastion | install-v3 46.62.171.61 |
| Client commit | d132cc4f push ph148/onboarding-activation-replay |
| Client diff | +9 / -4 (1 fichier : AISuggestionSlideOver.tsx) |
| tsc Client | exit 0 |
| KEY-305 race fix | preserve (draftDismissedRef + prevConversationIdRef intacts) |
| Doctrine seller-first | preserve 100% (autopilotGuardrails.ts hash inchange) |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT AI DRAFT AUTOOPEN ESCALATION DEV PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX`

(build Client DEV depuis commit d132cc4f -> nouveau tag v3.5.213-ai-draft-blocked-reason-dev, push GHCR, apply DEV via GitOps strict, QA browser Ludovic)

STOP. Aucun build, aucun push image, aucun deploy, aucun LLM, aucune KBActions consommee, aucun changement Linear statut.
