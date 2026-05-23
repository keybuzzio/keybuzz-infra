# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLOSE-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE CLOSE PROD
> Environnement : Docs only (aucun runtime change)

## VERDICT

GO CLOSE PH-20.11C GUARDRAIL GUIDANCE PROD READY WAIT_VISUAL_VALIDATION PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Closeout technique PROD complet : stack PH-20.11B + PH-20.11C LIVE end-to-end.
- API PROD `v3.5.255-ai-draft-blocked-reason-prod` + Client PROD `v3.5.215-ai-draft-blocked-reason-prod` deployes via GitOps strict, QA PROD read-only prouvee.
- Doctrine seller-first/refund-protection INCHANGE 100%. Aucun LLM/KBActions consomme durant les QA.
- KEY-312 reste en Backlog : validation visuelle navigateur Ludovic PROD non confirmee dans la conversation courante. Linear ticket non passe Done.
- Rapport closeout + CURRENT_STATE.md mis a jour.

## RESUME PROBLEME INITIAL ET RCA

### Symptome utilisateur (Ludovic, 2026-05-22)

Sur conversation client SWITAA Amazon "Rembourse moi tout de suite" :
- Aucun Brouillon IA visible dans le drawer.
- Le user ne savait pas que l'autopilot avait bloque la generation.
- L'agent humain n'avait aucune guidance prete a coller pour repondre prudemment.

### RCA (PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA-DEV-01)

1. Cote API : `GET /autopilot/draft` renvoyait `hasDraft:false` sans plus d'info quand l'autopilot avait bloque (PRE_LLM_BLOCKED / ESCALATION_DRAFT).
2. Cote Client : `AISuggestionSlideOver.tsx` n'avait pas la condition de rendu pour un cas "blocked" (drawer n'ouvrait que sur draftText) -> drawer reste ferme et user voit juste un label "Brouillon IA disponible" trompeur en sidebar Inbox.
3. Pas de guidance humaine prete : seul CTA visible "Generer une suggestion" -> dilemme entre consommer des KBActions ou ne rien repondre.

## PATCHES APPLIQUES

### API (commit `5070e6a6`, branche `ph147.4/source-of-truth`)

Fichier : `src/modules/autopilot/routes.ts`
- Extension read-only de `GET /autopilot/draft` : ajout fallback `blocked:true` + `blockedStatus` (PRE_LLM_BLOCKED / ESCALATION_DRAFT) + `blockedNotes` sanitized (regex `/^[A-Z_]+$/`, max 6).
- Aucun changement engine, guardrails, billing.
- `autopilotGuardrails.ts` hash INCHANGE.

### Client (commits sur `ph148/onboarding-activation-replay`)

Fichier unique : `src/features/ai-ui/AISuggestionSlideOver.tsx`
- `beabcd81` (PH-20.11B parent-wire) : wire de `blockedInfo` via `InboxTripane.tsx` + re-export type `AutopilotBlockedInfo`.
- `d132cc4f` (PH-20.11B autoOpen-fix) : extension condition useEffect autoOpen pour `(initialDraft?.draftText || blockedInfo?.blocked)` -> drawer s'ouvre auto pour blocked. KEY-305 race fix preserve (`draftDismissedRef.current !== conversationId`).
- `1a30ad9` (PH-20.11C guidance) : ajout constante `SAFE_GUIDANCE_TEXT` (trame statique ASCII, non-LLM, no KBActions, ne promet ni remboursement ni remplacement ni delai) + state `safeGuidanceCopied` + handler `handleCopySafeGuidance` (navigator.clipboard.writeText local) + sous-bloc UI dans card amber blockedInfo (visible quand `!activeDraft && blockedInfo.blocked === true`).

## RUNTIME FINAL DEV ET PROD

| Service | DEV | PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.254-ai-draft-blocked-reason-dev | **v3.5.255-ai-draft-blocked-reason-prod** | LIVE PH-20.11C |
| keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | **v3.5.215-ai-draft-blocked-reason-prod** | LIVE PH-20.11C |
| keybuzz-backend | INCHANGE | INCHANGE | preserve |
| keybuzz-website | INCHANGE | INCHANGE | preserve |
| keybuzz-admin-v2 | INCHANGE | INCHANGE | preserve |

| Pod | Env | Digest runtime | Verdict |
|---|---|---|---|
| keybuzz-api-56bff5c9c5-qv4jd | PROD | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | Ready 1/1, 0 restart |
| keybuzz-client-696bcd98c6-92c96 | PROD | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | Ready 1/1, 0 restart |

## QA DEV (recap)

| Phase | Verdict | Preuve |
|---|---|---|
| PH-20.11C-QA-DEV-01 | API + Client DEV : contract blocked OK + bundle 7/7 + AutoOpen pattern compile LIVE + AI parity preserve | commit infra 9cedc19 |
| QA browser Ludovic DEV | observe carte amber + guidance attendue | comment KEY-312 (2026-05-22/23) |

## QA PROD (recap)

| Phase | Verdict | Preuve |
|---|---|---|
| PH-20.11C-API-QA-PROD-01 | API PROD HTTP 200 blocked:true sur conv reelle SWITAA cmmph7bhmgcb..., notes COMBINED_RISK_HIGH/PRE_LLM_BLOCKED | commit infra 0da3385 |
| PH-20.11C-CLIENT-QA-PROD-01 | Client PROD bundle runtime 7/7 GUIDANCE + AutoOpen pattern compile LIVE + KEY-263 strict 87/0 + AI parity 6/4/10 + logs 0/0/0/0/0/0 + 0 /ai/assist + 0 /draft/consume | commit infra a59d357 |
| Browser QA Ludovic PROD | EN ATTENTE | - |

## NO LLM / NO KBACTIONS / NO MUTATION

Toutes les QA DEV et PROD ont prouve :
- 0 `/ai/assist`, 0 `/ai/execute`, 0 `/autopilot/draft/consume` durant probes.
- 0 KBActions consommee.
- 0 mutation DB : BEGIN TRANSACTION READ ONLY + ROLLBACK confirme `transaction_read_only=on` sur keybuzz_dev et keybuzz_prod.
- 0 fake event marketing, 0 fake lead/register/checkout, 0 message marketplace.
- 0 secret/token affiche, emails masques (ex sw***@gmail.com, ol***@gmail.com).

## DOCTRINE SELLER-FIRST PRESERVE

| Indicateur | Etat |
|---|---|
| autopilotGuardrails.ts hash | INCHANGE 100% |
| refundProtection markers (dist) | 31 occurrences preserve |
| COMBINED_RISK_HIGH | preserve |
| PRE_LLM_BLOCKED eligible au draft auto | **NON** (le patch est read-only, aucun draft genere) |
| Trame statique promet | **NI remboursement, NI remplacement, NI delai** (ne promet rien avant verification) |
| KBActions billing impacte | NON (trame statique = clipboard local, 0 API) |
| KEY-305 race UI fix | preserve (pattern compile `es.current!==d` LIVE) |
| KEY-263 isolation DEV/PROD | strict (api-dev=0 en PROD bundle) |
| KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 |

## RAPPORTS PRODUITS (chemins keybuzz-infra/docs/)

| Rapport | Commit infra | Phase |
|---|---|---|
| PH-SAAS-T8.12AS.20.11B-AUTOOPEN-RCA-DEV-01.md | 79dca5b | RCA |
| PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-SOURCE-PATCH-01.md | 552cae1 | Source patch Client autoOpen |
| PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-BUILD-DEV-01.md | c3092cc | Build Client DEV |
| PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-PUSH-IMAGE-DEV-01.md | ba4f4f6 | Push Client DEV |
| PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-APPLY-DEV-01.md | a527389 | Apply Client DEV |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-SOURCE-PATCH-01.md | 56957fe | Source patch Client guidance |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-DEV-01.md | 04f69cc | Build Client DEV guidance |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-DEV-01.md | c73fe69 | Push Client DEV guidance |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-DEV-01.md | 83d7fcc | Apply Client DEV guidance |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-QA-DEV-01.md | 9cedc19 | QA DEV stack complete |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-BUILD-PROD-01.md | 810ea39 | Build API PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-PUSH-IMAGE-PROD-01.md | f511bbb | Push API PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-APPLY-PROD-01.md | 6a0fb8a | Apply API PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-QA-PROD-01.md | 0da3385 | QA API PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-PROD-01.md | 769f15b | Build Client PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-PROD-01.md | 4b6f39c | Push Client PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-PROD-01.md | 2d7f8ea | Apply Client PROD |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-QA-PROD-01.md | a59d357 | QA Client PROD final |
| PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLOSE-PROD-01.md | (cette phase) | CLOSE |

## LINEAR STATUS FINAL

| Ticket | Statut final | Action |
|---|---|---|
| KEY-312 | Backlog (INCHANGE) | Comment closeout poste. **NE PAS** passer Done sans validation visuelle navigateur Ludovic PROD (en attente). |
| KEY-235 | INCHANGE | Aucun changement statut (doctrine seller-first preserve 100%). |
| KEY-231 | INCHANGE | Aucun changement statut. |
| KEY-305 | INCHANGE | Aucun changement statut (race UI fix preserve). |
| KEY-337 | INCHANGE | Parent epic PH-20. |

## RECOMMANDATIONS PRODUIT POST-CLOSEOUT

1. **Validation visuelle Ludovic PROD** : ouvrir Inbox PROD sur conversation reelle bloquee SWITAA `cmmph7bhmgcb...` pour confirmer l'auto-ouverture du drawer + carte amber + sous-bloc trame + bouton "Copier la trame".
2. **Surveillance 24-48h** : monitorer les usages reels de la guidance.
   - Combien de fois la carte amber est-elle vue ?
   - Le bouton "Copier la trame" est-il utilise (instrumentation client local sans envoi serveur si possible) ?
   - Y a-t-il regression des metriques "Brouillon IA visible" / "Generer une suggestion" cliques ?
3. **Feedback wording trame** : recolter avis Ludovic + 1-2 utilisateurs reels sur :
   - le ton (assez chaleureux ? trop formel ?)
   - la longueur (trop court ? trop long ?)
   - la pertinence Amazon vs Cdiscount vs eBay
4. **Future iteration possible** : V2 guidance avec template parametrable par tenant (sans LLM, avec slot dynamique commande/order) si volume des cas blocked grandit.
5. **KEY-312 statut Linear** : passer Done apres validation visuelle Ludovic OU laisser ouvert pour suivre les iterations wording V2.

## ROLLBACK PLAN PROD DOCUMENTE (non execute)

Si regression PROD detectee :
```
cd /opt/keybuzz/keybuzz-infra
# Client PROD rollback
# Editer k8s/keybuzz-client-prod/deployment.yaml -> image v3.5.201-register-polish-prod
# API PROD rollback (si necessaire)
# Editer k8s/keybuzz-api-prod/deployment.yaml -> image v3.5.252-meta-capi-emq-prod
git add k8s/keybuzz-client-prod/deployment.yaml k8s/keybuzz-api-prod/deployment.yaml
git commit -m "ops: ROLLBACK PH-20.11B PH-20.11C PROD"
git push origin main
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s
kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=300s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Services

| Service | DEV | PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.254-ai-draft-blocked-reason-dev | v3.5.255-ai-draft-blocked-reason-prod | LIVE end-to-end |
| keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | v3.5.215-ai-draft-blocked-reason-prod | LIVE end-to-end |

### 2. Composants

| Composant | Changement | Runtime final | Verdict |
|---|---|---|---|
| API routes.ts | Extension GET /autopilot/draft fallback blocked read-only | v3.5.255 PROD live | DONE |
| Client AISuggestionSlideOver.tsx | parent-wire blockedInfo + autoOpen patch + guidance statique + Copier la trame | v3.5.215 PROD live | DONE |
| autopilotGuardrails.ts | INCHANGE 100% | preserve | OK |
| engine.ts | INCHANGE | preserve | OK |
| billing/KBActions wallet | INCHANGE | preserve | OK |

### 3. Rapports

| Rapport | Path (keybuzz-infra/docs/) | Commit | Verdict |
|---|---|---|---|
| QA DEV final | PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-QA-DEV-01.md | 9cedc19 | OK |
| QA API PROD | PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-QA-PROD-01.md | 0da3385 | OK |
| QA Client PROD | PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-QA-PROD-01.md | a59d357 | OK |
| Close PROD (cette phase) | PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLOSE-PROD-01.md | (commit final) | A pousser |

### 4. Linear

| Linear | Action | Statut final | Verdict |
|---|---|---|---|
| KEY-312 | Comment closeout poste | Backlog (INCHANGE) | OK attente validation visuelle Ludovic |
| KEY-235 | (aucune action) | INCHANGE | OK |
| KEY-231 | (aucune action) | INCHANGE | OK |
| KEY-305 | (aucune action) | INCHANGE | OK |
| KEY-337 | (aucune action) | INCHANGE | OK |

### 5. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucune commande durant CLOSE |
| deploy DEV/PROD | OUI | runtime INCHANGE |
| kubectl mutation | OUI | uniquement get |
| restart pod | OUI | uptime preserve |
| modifier k8s manifests | OUI | aucun k8s/ touche |
| modifier API/Client source | OUI | aucun commit applicatif |
| LLM call | OUI | aucun |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB durant CLOSE |
| message marketplace | OUI | aucun |
| secret/token/PII dans logs | OUI | aucun |
| Linear status change non autorise | OUI | KEY-312 reste Backlog |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO CLOSE PH-20.11C GUARDRAIL GUIDANCE PROD READY WAIT_VISUAL_VALIDATION PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Stack PROD live | API v3.5.255 + Client v3.5.215 |
| Commits applicatifs | API 5070e6a6 + Client beabcd81 d132cc4f 1a30ad9 |
| Doctrine seller-first | INCHANGE 100% |
| KBActions consommees durant QA | 0 |
| LLM calls durant QA | 0 |
| Mutation DB durant QA | 0 |
| Rapports infra | 18 rapports PH-20.11B + PH-20.11C (chronologie complete documentee) |
| Linear KEY-312 | Backlog (INCHANGE) attente validation visuelle Ludovic |

### Prochaine etape

Si Ludovic valide visuellement le rendu PROD : `GO CLOSE LINEAR KEY-312 DONE PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`.

Sinon : surveiller usage 24-48h, recolter feedback wording trame, iterer si necessaire.

STOP PH-20.11C COMPLETE (technique). WAIT validation visuelle Ludovic pour fermeture Linear KEY-312.
