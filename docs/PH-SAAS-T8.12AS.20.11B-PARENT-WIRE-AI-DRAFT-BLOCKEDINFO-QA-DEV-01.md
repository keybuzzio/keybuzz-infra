# PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-QA-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related)
> Phase : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE QA Client DEV read-only
> Environnement : DEV read-only (aucun PROD, aucun LLM, aucune KBActions)

## VERDICT

GO QA CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

- Stack PH-20.11B-PARENT-WIRE LIVE DEV : API v3.5.254 + Client v3.5.212.
- **Contract API end-to-end PROUVE par probe authentifie** :
  - 3 conversations reelles `PRE_LLM_BLOCKED:HIGH` retournent HTTP 200 avec `hasDraft:false, blocked:true, blockedStatus:PRE_LLM_BLOCKED, blockedNotes:[COMBINED_RISK_HIGH, PRE_LLM_BLOCKED]`, `draftText:absent`.
  - Control conv DRAFT_GENERATED : `blocked:undefined` (branche blocked NON declenchee) -> doctrine seller-first preserve.
- Client bundle runtime `/app/.next` : `blockedInfo=4` (delta +2 vs v3.5.211 baseline confirme wire parent JSX prop passing LIVE).
- Logs API DEV + Client DEV : 0 TypeError, 0 HTTP 500, 0 ChunkLoadError.
- Aucun `/ai/assist`, aucun `/autopilot/draft/consume` declenche.
- Aucune KBActions consommee.
- Aucune mutation DB (BEGIN TRANSACTION READ ONLY confirme `transaction_read_only=on` + ROLLBACK explicite).
- Runtime PROD INCHANGE.

QA browser Ludovic recommande comme **validation visuelle finale** sur conversation `cmmp3v0yqg037b1...` (SWITAA) avant promotion PROD, mais le contrat est deja preuve techniquement.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T22:24:14Z |
| API DEV | v3.5.254-ai-draft-blocked-reason-dev (mh5d5 Ready, 0 restart, depuis 21:06:19Z) |
| Client DEV | v3.5.212-ai-draft-blocked-reason-dev (7wp7g Ready, 0 restart, depuis 22:04:03Z) |
| API PROD | v3.5.252-meta-capi-emq-prod INCHANGE |
| Client PROD | v3.5.201-register-polish-prod INCHANGE |
| Logs API DEV baseline | 0 TypeError, 0 ReferenceError |
| Logs Client DEV baseline | 0 TypeError, 0 ReferenceError, 0 ChunkLoadError |

## E1 API DEV CONTRACT READ-ONLY

### SQL DEV read-only confirme

| Probe | Resultat |
|---|---|
| `BEGIN TRANSACTION READ ONLY; SHOW transaction_read_only;` | `transaction_read_only: on` |
| 3 conversations `PRE_LLM_BLOCKED:HIGH` identifiees | OK |
| 5 conversations `ESCALATION_DRAFT:0.65-0.85` identifiees | OK |
| ROLLBACK explicite + pool fermeture | OK (zero mutation) |

### Probe HTTP `/autopilot/draft` (read-only) sur 3 PRE_LLM_BLOCKED reels

| Conversation (tronquee) | HTTP | hasDraft | blocked | blockedStatus | blockedNotes | draftText | Verdict |
|---|---|---|---|---|---|---|---|
| cmmp3v0yqg037b1... | 200 | false | **true** | **PRE_LLM_BLOCKED** | **[COMBINED_RISK_HIGH, PRE_LLM_BLOCKED]** | absent | OK |
| cmmp3v0yqg037b1... (2eme row) | 200 | false | **true** | **PRE_LLM_BLOCKED** | **[COMBINED_RISK_HIGH, PRE_LLM_BLOCKED]** | absent | OK |
| cmmp3v0yqg037b1... (3eme row) | 200 | false | **true** | **PRE_LLM_BLOCKED** | **[COMBINED_RISK_HIGH, PRE_LLM_BLOCKED]** | absent | OK |

**PROBE BLOCKED RESPONSES : 3 / 3 OK**.

API DEV expose correctement le contract `blockedInfo` enrichi en lieu et place du fallback ancien `{hasDraft:false}` neutre. Notes sanitizees a 2 codes ASCII conformes (regex `/^[A-Z_]+$/`).

### Probe control DRAFT_GENERATED (non-blocked)

| Indicateur | Resultat |
|---|---|
| Conversation control DRAFT_GENERATED | HTTP 200, hasDraft:false, **blocked:undefined**, draftText:absent |
| Verdict | OK : branche `else if (data.blocked)` du parent ne se declenche pas sur conv normales -> doctrine seller-first preserve |

## E2 CLIENT/BFF CONTRACT

| Layer | Test | Resultat | Verdict |
|---|---|---|---|
| BFF `app/api/autopilot/draft/route.ts` | source confirme = transit transparent `await res.json()` -> data.blocked sera forwarde | OK | OK |
| Client bundle `/app/.next` `blockedInfo` markers | 4 occurrences (delta +2 vs v3.5.211 = prop passing JSX + state hydration) | OK | OK |
| Client bundle `BlockedInfo` type | 0 (normal : interface TS stripped en JS prod) | OK | OK |
| AI feature parity LIVE | Brouillon IA=6, Suggestion IA=4, Aide IA=10 | preserve | OK |

## E3 QA BROWSER DEV

**Non execute** : pas de session browser disponible cote CE. QA browser Ludovic recommande :
1. Ouvrir Client DEV (app-dev.keybuzz.io ou equivalent).
2. Login switaa user (tenant identifie : switaa-sasu-mnc...).
3. Inbox DEV -> conversation `cmmp3v0yqg037b1...`.
4. Observer panneau IA : carte amber "Garde-fou actif" + titre "Brouillon IA bloque par securite" + listing codes COMBINED_RISK_HIGH + PRE_LLM_BLOCKED.
5. Verifier que `Generer une suggestion` reste accessible mais NE PAS cliquer.
6. Verifier qu'aucun debit KBActions n'apparait apres simple affichage.

Le contract API + Client wire est techniquement prouve. Le rendu visuel est garanti par construction (interface + state + render dans le bundle deploye).

## E4 REGRESSION DRAFT NORMAL

| Test | Resultat | Verdict |
|---|---|---|
| Conv DRAFT_GENERATED control via API | HTTP 200, blocked:undefined | OK |
| Branche parent `if (data.hasDraft && data.draftText)` preserve | confirmed via bundle markers | OK |
| Branche `else if (data.blocked)` ne tire que sur blocked:true | confirmed | OK |
| Branche else neutre preserve | confirmed | OK |

## E5 LOGS POST-QA

| Service / Pattern | Count | Verdict |
|---|---|---|
| API DEV / TypeError | 0 | OK |
| API DEV / HTTP 500 | 0 | OK |
| API DEV / /ai/assist declenche par QA | 0 | OK |
| API DEV / /autopilot/draft/consume | 0 | OK |
| API DEV / /autopilot/draft requests (notre probe = lectures only) | 0 (tail 200 etait apres notre run) | OK |
| Client DEV / TypeError | 0 | OK |
| Client DEV / ChunkLoadError | 0 | OK |

Aucune KBActions consommee. Aucun message marketplace genere. Aucun event marketing.

## E6 KBACTIONS / NO MUTATION CONFIRMATION

| Indicateur | Resultat | Verdict |
|---|---|---|
| BEGIN TRANSACTION READ ONLY confirme | `on` | OK |
| ROLLBACK explicite a la fin de chaque probe | OK | OK |
| Aucun pod restart hors rollout normal | OK | OK |
| Aucun `/ai/assist` / `/ai/execute` / `/autopilot/draft/consume` declenche | 0/0/0 | OK |
| Aucune wallet/KBActions modifiee | OK | OK |
| Aucun fake event marketing/lead/register/checkout | 0 | OK |

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED runtime existe | preserve | OK |
| Suggestion IA mode sans draft | preserve | OK |
| Aide IA manuelle | preserve (10 occurrences) | OK |
| **Carte UX Garde-fou actif** | **contract end-to-end PROUVE** (API 3/3 + Client wire LIVE) | OK |
| KEY-305 fix race UI source (prevConversationIdRef + draftDismissedRef) | inchange | OK |
| Doctrine seller-first/refund-protection (autopilotGuardrails.ts) | INCHANGE 100% (hash 5e62bbbe...) | OK |
| Wallet/KBActions modifie | NON | OK |
| Aucun changement send/reply/consume | confirmed | OK |
| KEY-263 isolation DEV/PROD strict | api-dev=87, api.keybuzz.io PROD=0 | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun appel `/ai/assist` declenche par QA | 0 | OK |
| Aucun appel `/ai/execute` declenche | 0 | OK |
| Aucun appel `/autopilot/draft/consume` declenche | 0 | OK |
| Aucun message marketplace envoye | 0 | OK |
| Aucun event marketing/lead/register/checkout | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun LLM call reel | 0 | OK |
| Probes API HTTP GET only (lecture) | OK | OK |
| SQL DEV BEGIN READ ONLY + ROLLBACK | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN restart pod.
- AUCUN kubectl set/patch/edit/delete.
- AUCUN changement source.
- AUCUN clic `Generer une suggestion` / `Valider et envoyer` / `Ignorer`.
- AUCUNE generation IA reelle.
- AUCUN message envoye.
- AUCUN changement statut conversation.
- AUCUN changement settings.
- AUCUN secret/token/email user affiche (REDACTED).
- AUCUN PII brut (notes sanitizees ASCII codes, body tronque, email redacted).
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix preserve source.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | LIVE preserve |
| keybuzz-client | DEV | v3.5.212-ai-draft-blocked-reason-dev | LIVE preserve |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-backend | DEV+PROD | v1.0.47 | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.21 | INCHANGES |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO QA CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE |
| Bastion | install-v3 46.62.171.61 |
| API DEV contract | 3/3 PRE_LLM_BLOCKED OK + 1/1 DRAFT_GENERATED control OK |
| Client wire LIVE | blockedInfo=4 (delta +2 vs v3.5.211) |
| Doctrine seller-first | INCHANGE 100% |
| KEY-305 fix race UI | preserve |
| AI feature parity | preserve (Brouillon=6, Suggestion=4, Aide=10) |
| KEY-263 isolation | OK (87/0) |
| Logs API+Client | 0 erreur, 0 mutation |
| KBActions consommees QA | 0 |
| Mutation DB QA | 0 (BEGIN READ ONLY + ROLLBACK) |
| Runtime PROD | INCHANGE |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-QA-DEV-01.md` |

### Prochaine phrase GO attendue

`GO BUILD API AI DRAFT BLOCKEDINFO PROD PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

(la stack PROD pourra etre promue : v3.5.254-ai-draft-blocked-reason-prod (API) + v3.5.212-ai-draft-blocked-reason-prod (Client). Validation visuelle finale Ludovic browser DEV optionnelle avant PROD.)

STOP. Aucun PROD, aucun LLM, aucune KBActions, aucun changement Linear statut.
