# PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-SOURCE-PATCH-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 (race UI) ; KEY-235 (seller-first) ; KEY-231 (KBActions)
> Phase : PH-SAAS-T8.12AS.20.11B source patch UX blocked reason
> Environnement : source patch only (aucun build, aucun deploy, aucun runtime mutation)

## VERDICT

GO SOURCE PATCH AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON READY PH-SAAS-T8.12AS.20.11B

- API : commit `5070e6a6` sur `ph147.4/source-of-truth` push origin -> etend GET /autopilot/draft avec fallback blocked info.
- Client : commit `fb348356` sur `ph148/onboarding-activation-replay` push origin -> AISuggestionSlideOver affiche carte explicative quand guardrail bloque.
- tsc API : 0 erreurs.
- tsc Client : 0 erreurs hors `.next/types/app/api/debug-env/route.ts` (auto-genere, pre-existant, non lie au patch).
- Doctrine seller-first / refund-protection (PH147.2) INCHANGE.
- KEY-305 fix race UI (l.230-242 useEffect hydratation) PRESERVE.
- Aucune mutation guardrails. Aucune consommation KBActions ajoutee.
- Aucun secret/PII/draftText complet ajoute.
- AI feature parity preserve.

STOP avant build DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T18:30:00Z |

### Repos / branches

| Repo | Branche | HEAD avant | HEAD apres | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | d88aa7d0 | **5070e6a6** | 223 (pre-existing dist/) | OK scope strict |
| keybuzz-client | ph148/onboarding-activation-replay | be45f1d | **fb348356** | 1 (pre-existing) | OK scope strict |
| keybuzz-infra | main | 6205cdd | 6205cdd (avant rapport) | 0 | clean |

## E1 RELIRE AUDIT PH-20.11

| Source | Fait prouve | Impact patch |
|---|---|---|
| PH-20.11 RCA | guardrail bloque -> PRE_LLM_BLOCKED, KBActions debitee, pas de draftText, UI bascule mode Suggestion IA sans expliquer | gap UX a fix via surface blocked_reason |
| autopilotGuardrails.ts | combinedRisk HIGH -> allowed=false (doctrine PH147.2) | NE PAS toucher guardrails |
| AISuggestionSlideOver.tsx KEY-305 | fix race preserve (l.216-235) | preserve dans patch |
| ai_action_log schema | blocked, blocked_reason, payload.guardrailNotes existent deja en DB | extension API read-only suffit |
| GET /autopilot/draft existante l.213 | retourne hasDraft:false sans expliquer si pas de draftText | extension minimale possible |

## E2 DESIGN PATCH

### Decision finale

| Surface | Option | Risque | Choix retenu |
|---|---|---|---|
| API GET /autopilot/draft | etendre fallback hasDraft:false avec query secondaire pour blocked info | bas (read-only, retro-compat) | RETENU |
| API nouvelle route /draft-or-blocked | duplication API | redondance | rejete |
| Client extend AutopilotDraft interface | combiner draft + blocked dans un seul type | confusion typage | rejete |
| Client nouveau type AutopilotBlockedInfo + prop separe blockedInfo | type clair separe | propre | RETENU |
| Client hardcoded copy backend | doit changer si guardrail bouge | mauvais | rejete |
| Modify guardrail thresholds | casse doctrine seller-first | DANGEREUX | REJETE explicite |

### Forme retenue

1. **API** : si la 1ere query (DRAFT_GENERATED|ESCALATION_DRAFT avec draftText) ne retourne rien, faire une 2eme query qui cherche le dernier ai_action_log `PRE_LLM_BLOCKED%` ou `ESCALATION_DRAFT%`. Si trouve, retourner `{ hasDraft:false, blocked:true, blockedStatus, blockedNotes:[sanitized], createdAt }`. Sinon, retourner `{ hasDraft:false }` comme avant.
2. **Client** : nouveau type `AutopilotBlockedInfo`, nouvelle prop optionnelle `blockedInfo`. Render conditionnel d une carte UX explicative dans le mode "Suggestion IA" quand `!activeDraft && blockedInfo.blocked`. Copy distincte selon `blockedStatus`.

## E3 PATCH SOURCE

### keybuzz-api / src/modules/autopilot/routes.ts (commit 5070e6a6)

| Fichier | Changement | Lignes | Risque | Mitigation |
|---|---|---|---|---|
| `src/modules/autopilot/routes.ts` | extend GET /autopilot/draft fallback : 2eme query DB read-only sur ai_action_log filtre blocked_reason LIKE PRE_LLM_BLOCKED% OR ESCALATION_DRAFT%, retourne blockedStatus, blockedNotes (sanitized regex `/^[A-Z_]+$/`, max 6), createdAt | +29 / -1 | retro-compat OK (if blockedRow.rows.length === 0 -> ancien hasDraft:false) | sanitization stricte, codes uniquement, pas de PII, pas de body client |

Marker source : `PH-SAAS-T8.12AS.20.11B KEY-312` (1 occurrence).

### keybuzz-client / src/features/ai-ui/AISuggestionSlideOver.tsx (commit fb348356)

| Fichier | Changement | Lignes | Risque | Mitigation |
|---|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | 4 patches : (1) export interface `AutopilotBlockedInfo`, (2) prop optionnelle `blockedInfo?: AutopilotBlockedInfo \| null`, (3) destructure `blockedInfo` dans component args, (4) carte UX render conditionnelle dans mode Suggestion IA juste avant bloc Pre-generation info | +44 / -0 | optional prop, default null = comportement inchange | aucun changement si parent ne passe pas blockedInfo |

Carte UX render details :
- ShieldCheck icon amber 5x5 + titre semibold (PRE_LLM_BLOCKED : "Brouillon IA bloque par securite" ; ESCALATION_DRAFT : "Validation humaine recommandee")
- Badge "Garde-fou actif" pill amber
- Copy explicative simple, oriente vers Aide IA manuelle ou validation humaine
- Notes sanitisees affichees en monospace tags (codes techniques uniquement)
- Bouton "Generer une suggestion" reste accessible juste apres comme fallback Aide IA manuelle

Marker source `PH-SAAS-T8.12AS.20.11B KEY-312` (4 occurrences).

### Fichiers NON touches

- `src/services/autopilotGuardrails.ts` (CORE doctrine seller-first preserve)
- `src/modules/autopilot/engine.ts` (decision tree preserve)
- `src/lib/promise-detection.ts` (post-LLM patterns preserve)
- billing / wallet / KBActions modules
- backend inbound callback
- send reply / consume / execute

## E4 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| keybuzz-api `npx tsc --noEmit` | 0 erreurs | OK |
| keybuzz-client `npx tsc --noEmit` filtered out `.next/types/app/api/debug-env/route.ts` (pre-existing auto-gen) | 0 erreurs nouvelles | OK |
| keybuzz-client `.next/types/app/api/debug-env/route.ts` error TS2307 | pre-existant dirty file, non lie patch | DOCUMENTE |
| grep PH-SAAS-T8.12AS.20.11B markers Client | 13 occurrences | OK |
| grep PH-SAAS-T8.12AS.20.11B + blockedRow + blockedStatus + blockedNotes markers API | 7 occurrences | OK |
| Aucun fetch('/ai/assist') ajoute | 0 | OK |
| Aucun /autopilot/draft/consume ajoute | 0 | OK |
| Aucun /ai/execute ajoute | 0 | OK |
| Aucun secret/token | 0 | OK |
| Aucun tenant hardcode | 0 | OK |

## E5 NON-REGRESSION SOURCE

| Scenario | Attendu | Source preuve |
|---|---|---|
| Conversation avec DRAFT_GENERATED | Brouillon IA s'ouvre comme avant | `activeDraft` hydrate depuis initialDraft preserve (l.224-228) ; render mode Bot + titre "Brouillon IA" (l.451-452) preserve |
| Conversation sans draft ni blocked | mode Suggestion IA actuel, bouton "Generer une suggestion" actif | bloc l.680 inchange (Sparkles + "Obtenir une suggestion") |
| Conversation PRE_LLM_BLOCKED | nouvelle carte UX amber + Garde-fou actif + bouton "Generer une suggestion" en fallback | nouveau bloc l.679-712 (avant Pre-generation info) |
| Conversation ESCALATION_DRAFT | nouvelle carte avec copy "Validation humaine recommandee" | meme bloc, branching par blockedStatus |
| Race UI KEY-305 | preserve (draftDismissedRef + prevConversationIdRef inchanges) | grep confirme l.153, 157, 234-235 |
| autoOpen / initialDraft | inchanges | aucune modif l.55-56, 128-129 |
| Aide IA manuelle | reste accessible | bouton "Generer une suggestion" inchange |
| API GET /draft sans blocage | retourne hasDraft:false inchange | `if (blockedRow.rows.length === 0) { return reply.send({ hasDraft: false }); }` retro-compat |
| API GET /draft existing draft | retourne hasDraft:true + draftText comme avant | logique inchangee apres la 1ere query (l.245+) |

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat patch | Verdict |
|---|---|---|
| Brouillon IA auto-open quand DRAFT_GENERATED existe | preserve | OK |
| Aide IA manuelle fonctionne | preserve (bouton Generer une suggestion inchange) | OK |
| KEY-305 fix race UI present | preserve (l.234-235 reset draftDismissedRef au switch conv) | OK |
| Pas de reset activeDraft regressif | preserve | OK |
| Pas de confusion Brouillon IA vs Suggestion IA | nouvelle carte est un 3eme etat lisible (Garde-fou actif) | OK |
| Guardrails seller-first/refund-protection | INCHANGE 100% | OK |
| Pas de remboursement/promesse automatique dangereuse | inchange (post-LLM guard preserve) | OK |
| Pas de regression no-reask commande/suivi | inchange (logique stale draft AP.1E preserve) | OK |
| Pas de changement PRO vs AUTOPILOT | iaMode logic intacte | OK |
| Escalade humaine reste lisible | RENFORCEE (blockedStatus=ESCALATION_DRAFT explicite via UI) | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Event marketing | 0 | OK |
| Conversion | 0 | OK |
| billing_event | 0 | OK |
| KBActions consommees | 0 | OK |
| `/ai/assist` appel | 0 | OK |
| `/autopilot/draft/consume` appel | 0 | OK |
| `/ai/execute` appel | 0 | OK |
| LLM call | 0 (pas d ajout) | OK |
| DB mutation ajoutee | 0 (lecture seule supplementaire) | OK |
| Test event_code | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN build Docker.
- AUCUN docker push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply/set/patch/edit.
- AUCUN restart pod.
- AUCUN tuning ingress/nginx.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUNE mutation DB.
- AUCUN fake event/metric/conversation/message.
- AUCUN secret/token/PGPASSWORD/PII brut affiche.
- AUCUN draftText complet lu.
- AUCUN hardcode tenant/eComLG/Guilhem/Nordine/SWITAA.
- AUCUN changement billing/wallet.
- AUCUN changement seuils guardrails.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- AUCUN changement backend inbound.
- AUCUN message marketplace envoye.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE (aucun changement)

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | DEV | v3.5.253-meta-capi-emq-dev | INCHANGE (source patch only) |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | DEV | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-backend | DEV+PROD | v1.0.47-cross-env-guard-fix | INCHANGE |
| keybuzz-website | DEV+PROD | v0.6.21 / v0.6.21-pricing-action-recover-prod | INCHANGE |

## LIMITES

1. **Parent Client qui injecte `initialDraft` et appelle GET /api/autopilot/draft** : non localise dans `keybuzz-client/src/` par grep direct. Probablement consume via dynamic import ou repo `keybuzz-admin-v2` ou compile distincte. Cette phase ne touche pas le parent. Si le parent ne passe pas `blockedInfo`, la carte UX ne s'affiche pas (default null = comportement inchange). Le parent sera adapte dans une phase suivante PH-20.11B-PARENT-WIRE si necessaire (lire la response API et passer blockedInfo).
2. **Pas de QA navigateur PROD** dans cette phase (source patch only). QA UX visuel sera fait apres build DEV.
3. **AISuggestionSlideOver.tsx grep n a pas trouve de `<AISuggestionSlideOver>` consumer dans `src/`** : cela peut indiquer que le composant est consume par admin-v2 ou un autre repo. Le patch reste valide car le composant exporte ses types publiquement via `index.ts`.

## OPTIONS PROCHAINES PHASES

### Recommande : PH-20.11B-BUILD-DEV

`GO BUILD CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV PH-SAAS-T8.12AS.20.11B`
- Build API DEV from commit 5070e6a6 + Client DEV from commit fb348356
- Pas de PROD avant validation Ludovic

### Optionnel : PH-20.11B-PARENT-WIRE (a confirmer)

Si le parent qui appelle GET /api/autopilot/draft n est pas reactif au champ `blocked` retourne, il faudra le patcher pour :
- Lire `data.blocked` + `data.blockedStatus` + `data.blockedNotes`
- Passer `blockedInfo` au composant AISuggestionSlideOver

A faire dans une phase ulterieure si la QA browser PH-20.11B-DEV revele que la carte ne s'affiche pas.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON READY PH-SAAS-T8.12AS.20.11B |
| Bastion | install-v3 46.62.171.61 |
| API commit | 5070e6a6 push ph147.4/source-of-truth |
| Client commit | fb348356 push ph148/onboarding-activation-replay |
| API diff | +29 / -1 ligne (1 fichier) |
| Client diff | +44 / 0 ligne (1 fichier) |
| tsc API | 0 erreurs |
| tsc Client | 0 erreurs nouvelles (1 pre-existant non lie patch) |
| Doctrine seller-first | preserve 100% |
| KEY-305 race UI fix | preserve |
| Aide IA manuelle | preserve |
| Runtime DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV PH-SAAS-T8.12AS.20.11B`

STOP. Aucun build, aucun push image, aucun deploy, aucun LLM, aucune KBActions consommee, aucun changement Linear statut.
