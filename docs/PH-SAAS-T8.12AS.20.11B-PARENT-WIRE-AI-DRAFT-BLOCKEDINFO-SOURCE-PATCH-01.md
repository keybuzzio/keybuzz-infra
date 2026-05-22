# PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-SOURCE-PATCH-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 (race UI preserve) ; KEY-235 (seller-first preserve) ; KEY-231 (KBActions inchange)
> Phase : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE source patch Client parent wire
> Environnement : source patch only (aucun build, aucun deploy, aucun LLM, aucune KBActions)

## VERDICT

GO SOURCE PATCH CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

- Client commit `beabcd81` (branche `ph148/onboarding-activation-replay`) push origin.
- 2 fichiers patches : `app/inbox/InboxTripane.tsx` (+19 -1) + `src/features/ai-ui/index.ts` (+1 -1).
- tsc Client : 0 erreurs nouvelles (hors `.next/types/debug-env` pre-existant).
- Doctrine seller-first / refund-protection INCHANGE 100% (autopilotGuardrails.ts intact).
- KEY-305 fix race UI PRESERVE (draftDismissedRef + prevConversationIdRef l.153,157,234-235 intacts).
- Aide IA manuelle preserve.
- Aucune mutation runtime.

STOP avant build API DEV (commit 5070e6a6) + build Client DEV (commit beabcd81).

## RCA QA DEV (rappel)

PH-20.11B QA DEV (rapport `*-QA-DEV-01.md`) avait identifie un STOP BLOCKER :
- Le bundle Client v3.5.211 contenait la carte UX (markers LIVE 4/4) mais inerte en runtime.
- Le parent `app/inbox/InboxTripane.tsx` l.357-380 ignorait les nouveaux champs API `data.blocked / data.blockedStatus / data.blockedNotes`.
- Si `!data.hasDraft` -> branche else -> `setAutopilotDraft(null)` -> carte ne s'affiche jamais.
- L'API DEV `v3.5.253-meta-capi-emq-dev` n'avait pas non plus le commit `5070e6a6` (extension GET /draft fallback blocked).

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T20:32:28Z |
| keybuzz-client HEAD avant patch | fb34835 (PH-20.11B Client) |
| keybuzz-client HEAD apres patch | **beabcd81** |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| AutopilotBlockedInfo deja exporte par SlideOver.tsx l.43 | OUI |
| AutopilotBlockedInfo re-exporte par index.ts | NON (a patcher) |

## E1 DESIGN PATCH

| Zone | Changement | Risque | Mitigation |
|---|---|---|---|
| `src/features/ai-ui/index.ts` | re-export type AutopilotBlockedInfo | bas (additif) | re-export type-only |
| `app/inbox/InboxTripane.tsx` import | ajouter `type AutopilotBlockedInfo` au named import barrel | bas | additif |
| `app/inbox/InboxTripane.tsx` state | nouveau `useState<AutopilotBlockedInfo \| null>` | bas | default null = comportement inchange |
| `app/inbox/InboxTripane.tsx` fetchDraft | 3eme branche `else if (data.blocked)` qui hydrate state + setAutoOpen(true) | moyen | scope strict, ne touche pas branche `hasDraft && draftText`, preserve branche else neutre |
| `app/inbox/InboxTripane.tsx` reset | setAutopilotBlockedInfo(null) au switch + catch | bas | symetrique |
| `app/inbox/InboxTripane.tsx` JSX render | nouvelle prop `blockedInfo={autopilotBlockedInfo}` | bas | propagation directe vers SlideOver qui a deja la prop optionnelle |

## E2 PATCH SOURCE (6 patches dans 2 fichiers)

### Fichier 1 : `keybuzz-client/src/features/ai-ui/index.ts` (+1 -1 ligne)

```diff
-export { AISuggestionSlideOver, type AutopilotDraft } from './AISuggestionSlideOver';
+export { AISuggestionSlideOver, type AutopilotDraft, type AutopilotBlockedInfo } from './AISuggestionSlideOver';
```

### Fichier 2 : `keybuzz-client/app/inbox/InboxTripane.tsx` (+19 -1 lignes)

#### Patch 2a : import (l.21)
```diff
-import { MessageSourceBadge, detectMessageSource, AISuggestionSlideOver, TemplatePickerSlideOver, type AutopilotDraft } from "@/src/features/ai-ui";
+import { MessageSourceBadge, detectMessageSource, AISuggestionSlideOver, TemplatePickerSlideOver, type AutopilotDraft, type AutopilotBlockedInfo } from "@/src/features/ai-ui";
```

#### Patch 2b : state apres autopilotAutoOpen (l.345-347)
```diff
 const [autopilotDraft, setAutopilotDraft] = useState<AutopilotDraft | null>(null);
 const [autopilotAutoOpen, setAutopilotAutoOpen] = useState(false);
+// PH-SAAS-T8.12AS.20.11B-PARENT-WIRE KEY-312: surface guardrail block reason
+const [autopilotBlockedInfo, setAutopilotBlockedInfo] = useState<AutopilotBlockedInfo | null>(null);
```

#### Patch 2c : reset au no-selectedId (l.351-355)
```diff
 if (!selectedId || !currentTenantId) {
   setAutopilotDraft(null);
   setAutopilotAutoOpen(false);
+  setAutopilotBlockedInfo(null);
   return;
 }
```

#### Patch 2d : 3eme branche blocked dans fetchDraft (l.357-380)
```diff
 if (data.hasDraft && data.draftText) {
   setAutopilotDraft({ ... });
   setAutopilotAutoOpen(true);
+  setAutopilotBlockedInfo(null);
+} else if (data.blocked) {
+  // PH-SAAS-T8.12AS.20.11B-PARENT-WIRE KEY-312: hydrate blocked guardrail reason
+  setAutopilotDraft(null);
+  setAutopilotAutoOpen(true);
+  setAutopilotBlockedInfo({
+    blocked: true,
+    blockedStatus: data.blockedStatus ?? 'PRE_LLM_BLOCKED',
+    blockedNotes: Array.isArray(data.blockedNotes) ? data.blockedNotes : [],
+    createdAt: data.createdAt ?? null,
+  });
 } else {
   setAutopilotDraft(null);
   setAutopilotAutoOpen(false);
+  setAutopilotBlockedInfo(null);
 }
```

#### Patch 2e : catch reset
```diff
 } catch {
   if (!cancelled) {
     setAutopilotDraft(null);
     setAutopilotAutoOpen(false);
+    setAutopilotBlockedInfo(null);
   }
 }
```

#### Patch 2f : prop passe a SlideOver (l.1596+)
```diff
 initialDraft={autopilotDraft}
 autoOpen={autopilotAutoOpen}
+blockedInfo={autopilotBlockedInfo}
 />
```

## E3 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit` Client | 0 erreurs nouvelles (1 pre-existant `.next/types/debug-env` non lie) | OK |
| grep markers parent-wire dans InboxTripane.tsx | 10 occurrences (autopilotBlockedInfo, setAutopilotBlockedInfo, AutopilotBlockedInfo, PH-SAAS-T8.12AS.20.11B-PARENT-WIRE, blockedInfo={) | OK |
| grep AutopilotBlockedInfo dans index.ts | 1 occurrence (re-export) | OK |
| KEY-305 fix preserve (control) | 8 occurrences (draftDismissedRef + prevConversationIdRef l.153,157,234-235) | OK |
| Aucun fetch `/ai/assist` ajoute | 0 | OK |
| Aucun /autopilot/draft/consume ajoute | 0 | OK |
| Aucun hardcode tenant/conversation/cas user | 0 | OK |

## E4 DIFF / COMMIT / PUSH

| Fichier | Diff | Commit |
|---|---|---|
| `app/inbox/InboxTripane.tsx` | +19 / -1 | `beabcd81` |
| `src/features/ai-ui/index.ts` | +1 / -1 | `beabcd81` |

Commit message : `fix(inbox): wire blocked AI draft reason into slide-over PH-20.11B KEY-312`

Push : `ph148/onboarding-activation-replay` (fb34835..beabcd81).

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat patch | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED existe | preserve (1ere branche inchangee, juste ajout `setAutopilotBlockedInfo(null)` pour reset symetrique) | OK |
| Suggestion IA mode sans draft ni blocked | preserve (branche else neutre) | OK |
| Aide IA manuelle | preserve (composant rend toujours le bouton "Generer une suggestion") | OK |
| Nouvelle carte "Garde-fou actif" affichee quand blocked | desormais CABLE en runtime | OK |
| KEY-305 fix race UI (l.153, 157, 234-235 SlideOver) | inchange | OK |
| Doctrine seller-first/refund-protection (autopilotGuardrails.ts) | INCHANGE 100% | OK |
| autopilot engine.ts (decision tree, guardrails) | INCHANGE | OK |
| send/reply/consume/billing | INCHANGE | OK |
| Pas de hardcode tenant/conversation/case user | OK | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun event marketing ajoute | 0 | OK |
| Aucun appel LLM ajoute | 0 | OK |
| Aucune KBActions consommee ajoutee | 0 | OK |
| Aucun message marketplace | 0 | OK |
| Aucun `/ai/assist` / `/autopilot/draft/consume` / `/ai/execute` | 0 | OK |
| Aucune mutation DB | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUNE mutation DB.
- AUCUN fake event/metric/conversation/message.
- AUCUN secret/token/PGPASSWORD/PII brut/draftText complet.
- AUCUN hardcode tenant/eComLG/Guilhem/Nordine/SWITAA.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- AUCUN backend inbound modifie.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE (aucun changement)

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | v3.5.211-ai-draft-blocked-reason-dev | INCHANGE (cible BUILD futur depuis beabcd81 -> v3.5.212-...) |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.253-meta-capi-emq-dev | INCHANGE (cible BUILD futur depuis 5070e6a6 -> v3.5.254-...) |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-backend | DEV+PROD | v1.0.47 | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.21 | INCHANGES |

## PROCHAINES ETAPES REQUISES

Pour que la carte UX s'affiche reellement en DEV/PROD, 2 builds + 2 apply sont necessaires :

### Sequence DEV
1. **PH-20.11B-PARENT-WIRE BUILD API DEV** depuis commit API `5070e6a6` -> nouveau tag `v3.5.254-ai-draft-blocked-reason-dev` (apporte GET /autopilot/draft etendu).
2. **PUSH IMAGE API DEV**.
3. **APPLY API DEV** (GitOps strict).
4. **BUILD Client DEV** depuis commit Client `beabcd81` -> nouveau tag `v3.5.212-ai-draft-blocked-reason-dev` (apporte wire parent).
5. **PUSH IMAGE Client DEV**.
6. **APPLY Client DEV** (GitOps strict).
7. **QA browser Ludovic** : ouvrir conversation reelle bloquee (ex : SWITAA Rembourse moi immediatement!) -> verifier carte amber + Garde-fou actif + copy distincte.

### Sequence PROD (apres validation QA DEV explicite Ludovic)
8. BUILD API PROD `5070e6a6` -> `v3.5.254-ai-draft-blocked-reason-prod`
9. BUILD Client PROD `beabcd81` -> `v3.5.212-ai-draft-blocked-reason-prod`
10. PUSH + APPLY PROD API + Client
11. QA browser Ludovic PROD

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE |
| Bastion | install-v3 46.62.171.61 |
| Client commit | beabcd81 push ph148/onboarding-activation-replay |
| Client diff | +20 / -2 lignes (2 fichiers) |
| tsc Client | 0 erreurs nouvelles |
| Doctrine seller-first | preserve 100% |
| KEY-305 race UI fix | preserve |
| Aide IA manuelle | preserve |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD API AI DRAFT BLOCKEDINFO DEV PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

STOP. Aucun build, aucun push image, aucun deploy, aucun LLM, aucune KBActions consommee, aucun changement Linear statut.
