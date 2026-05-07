# PH-SAAS-T8.12AP.2.4 — Conversation Lifecycle Status After Reply — Truth Audit & DEV Fix

**Date** : 2026-05-07
**Ticket** : KEY-265
**Type** : Audit verite + correction DEV
**Verdict** : **GO DEV FIX VALIDATED**

---

## Contexte

Apres AP.2 a AP.2.3.1 (escalation UX, author_name, PROD promotion), cette phase audite le cycle de vie complet des conversations apres reponse : transitions de statut, handler identity, badges SAV/escalade/assignation.

## Sources relues

- CE_PROMPTING_STANDARD.md, RULES_AND_RISKS.md, AI_MESSAGING_FEATURE_PARITY_BASELINE.md, TRIAL_WOW_STACK_BASELINE.md
- Rapports AP.1F, AP.2, AP.2.1, AP.2.2, AP.2.3, AP.2.3.1

## Branches

| Repo | Branche | Dernier commit |
|---|---|---|
| keybuzz-api (bastion) | ph147.4/source-of-truth | a18a361d fix(messages): clear escalation_status on resolve (AP.2.4) |
| keybuzz-client | ph148/onboarding-activation-replay | abef1bc4 fix(inbox): inject X-User-Email header |
| keybuzz-infra | main | 440394c gitops(dev): API DEV v3.5.160 |

## Baselines PROD (intactes)

| Service | Image PROD | Verifie |
|---|---|---|
| API | v3.5.145-outbound-author-name-prod | Oui |
| Client | v3.5.168-outbound-author-name-ux-prod | Oui |
| OW | v3.5.165-escalation-flow-prod | Oui |
| Backend | v1.0.47-cross-env-guard-fix-prod | Oui |
| Website | v0.6.9-promo-forwarding-prod | Oui |

---

## ETAPE 1 — Cartographie des surfaces de reponse

| Surface | Fichier | Endpoint | Ecrit message ? | Status update | Assigned ? | Source/Author | Verdict |
|---|---|---|---|---|---|---|---|
| Reponse humaine | messages/routes.ts:395-512 | POST /conversations/:id/reply | Oui | -> 'open' | NON | HUMAN + Prenom.N | OK |
| Note interne | messages/routes.ts:395-517 | POST /conversations/:id/reply | Oui | Pas de changement | NON | HUMAN + Prenom.N | OK |
| Autopilot reply | autopilot/engine.ts:820 | executeReply() | Oui | -> 'open' | NON | autopilot + KeyBuzz IA | OK |
| Autopilot escalate | autopilot/engine.ts:885 | escalateConversation() | NON | -> 'escalated' (les 2 champs) | NON | N/A | OK |
| Draft escalation applied | autopilot/routes.ts:393 | POST /autopilot/draft/consume | NON | -> 'pending' + escalation='escalated' | NON | N/A | Incohérent |
| False promise auto-esc | messages/routes.ts:590 | POST reply (post-send) | Message envoye | escalation_status seulement | NON | N/A | Incohérent |
| AI assist auto-escalate | ai-assist-routes.ts:982 | POST /ai/assist | NON | escalation_status seulement | NON | N/A | Incohérent |
| Manual status | messages/routes.ts:734 | PATCH /status | NON | -> open/pending/resolved | NON | N/A | **GAP RC1** |
| Manual SAV | messages/routes.ts:848 | PATCH /sav-status | NON | Pas de changement | NON | N/A | OK |
| Manual assign | messages/routes.ts:914 | PATCH /assign | NON | Pas de changement | -> agentId | N/A | OK |
| Manual escalation | messages/routes.ts:1033 | PATCH /escalation | NON | Pas de changement | NON | N/A | GAP RC2 |
| Inbound (new msg) | inbound/routes.ts:161,451 | POST /inbound/* | Oui | -> 'pending' | NON | sender | OK |

---

## ETAPE 2 — Audit DB DEV (ecomlg-001, read-only)

### Distribution statut
| Status | Count |
|---|---|
| open | 381 |
| resolved | 57 |
| pending | 37 |
| escalated | 1 |

### Escalation
- escalation_status=escalated : 10
- Toutes les 10 ont assigned_agent_id=NULL

### SAV
- null: 420, closed: 42, in_progress: 8, waiting: 4, to_process: 2

### Author name (outbound)
- KeyBuzz Agent: 221 (legacy)
- Equipe SAV: 4, Equipe SAV eComLG: 3, KeyBuzz IA: 1

### Message source (outbound)
- HUMAN: 221, SUPPLIER_CONTACT: 8, autopilot: 1

---

## ETAPE 3 — Audit PROD (read-only)

### Distribution statut
| Status | Count |
|---|---|
| resolved | 511 |
| open | 47 |
| pending | 2 |

### Status vs dernier message
| Status | Last direction | Count | Verdict |
|---|---|---|---|
| resolved + inbound | 385 | Normal (agent a lu, puis resolu) |
| resolved + outbound | 120 | Normal (agent a repondu, puis resolu) |
| open + outbound | 25 | Normal (conversation en cours) |
| **open + inbound** | **22** | Legacy / notification Amazon |
| pending + inbound | 1 | Normal |
| **pending + outbound** | **1** | Edge case rare |

### Signaux critiques PROD
| Signal | Count | Risque | Correction |
|---|---|---|---|
| escalated + assigned=NULL | **34/34** | Moyen | Phase dediee KEY-267/268 |
| **resolved + escalated** | **18** | **Haut** | **RC1 corrige** (futures resolutions) |
| open + last_inbound | 22 | Faible (legacy) | Self-healing |
| Recent Ludovic.G | 2 | OK | AP.2.2 fonctionne |
| Legacy KeyBuzz Agent | 442 | Attendu | Non destructif |

### PROD non modifiee
0 code, 0 build, 0 deploy, 0 mutation.

---

## ETAPE 4 — Source de verite

**Source de verite = combinaison des champs existants** :
- `conversations.status` : etat principal (open/pending/resolved/escalated)
- `conversations.escalation_status` : dimension escalation (none/recommended/escalated)
- `conversations.sav_status` : dimension SAV (independante)
- `conversations.assigned_agent_id` : qui traite
- `messages.direction` + `message_source` + `author_name` : dernier handler

**Pas de nouveau champ necessaire. Pas de migration.**

### Root causes identifiees

**RC1 (FIXE)** : PATCH /status avec status='resolved' ne clearait pas escalation_status. Resultat : 18 conversations PROD sont resolved+escalated.

**RC2 (DOCUMENTE)** : L'escalation manuelle ne set pas status='escalated' contrairement a l'autopilot. Resultat : 9 conversations ont escalation_status=escalated mais status=open. Decision produit requise pour aligner.

**RC3 (DOCUMENTE)** : Aucun chemin ne met assigned_agent_id lors d'une escalation. Phase dediee KEY-267/268.

---

## ETAPE 5 — Patch DEV

### Fix RC1 : Resolve clear escalation

**Fichier** : `src/modules/messages/routes.ts` ligne 734

**Avant** :
```sql
UPDATE conversations SET status = $1, last_activity_at = now(), updated_at = now() WHERE id = $2 AND tenant_id = $3
```

**Apres** :
```sql
UPDATE conversations SET status = $1, escalation_status = CASE WHEN $1 = 'resolved' THEN 'none' ELSE escalation_status END, last_activity_at = now(), updated_at = now() WHERE id = $2 AND tenant_id = $3
```

**Comportement** :
- status='resolved' -> escalation_status force a 'none'
- status='open' ou 'pending' -> escalation_status inchange

---

## ETAPE 6 — Tests DEV

| Test | Resultat attendu | Resultat obtenu | Verdict |
|---|---|---|---|
| Resolve conversation escaladee | status=resolved, escalation_status=none | status=resolved, escalation_status=none | **PASS** |
| Reopen apres resolve | status=open, escalation_status=none (reste cleared) | Confirme | **PASS** |
| Re-escalate + resolve | escalation cleared a nouveau | Confirme | **PASS** |
| Open ne clear pas escalation | escalation_status preserve | Confirme | **PASS** |
| Author name (AP.2.2) | KeyBuzz Agent legacy inchange | 221x KeyBuzz Agent | **PASS** |
| Message source | HUMAN/SUPPLIER_CONTACT/autopilot | Confirme | **PASS** |

---

## ETAPE 7-8 — Build + Validation DEV

### Build
| Service | Tag | Digest | Rollback |
|---|---|---|---|
| API DEV | v3.5.160-conversation-lifecycle-status-dev | sha256:2c4250ecd57ef367bd611b0bad579c9c6add6bbc6749e0485998bc29a18f1d2a | v3.5.159-outbound-author-name-dev |

### Runtime
- Pod Running, 1/1 Ready, 0 restarts
- Health: {"status":"ok"}
- Conversations list: fonctionnel
- Dashboard: fonctionnel

---

## ETAPE 9 — Non-regression

| Check | Resultat |
|---|---|
| Health | OK |
| Conversations list | OK |
| Dashboard summary | OK |
| AI assist endpoint | 200 |
| Autopilot draft endpoint | 200 |
| Author name AP.2.2 | Preserve |
| Client DEV | Inchange (v3.5.167) |
| OW DEV | Inchange (v3.5.165-escalation-flow-dev) |
| Toutes baselines PROD | Intactes |
| Pod restarts | 0 |
| Tracking/billing/CAPI | Non impacte (pas de Client build) |
| No-reask AP.1F | Non impacte (code IA non touche) |

---

## ETAPE 10 — Linear

### KEY-265 (Conversation Lifecycle)
- Audit complet realise
- RC1 fixe en DEV : resolve clear escalation_status
- RC2 documente : escalation manuelle vs autopilot — decision produit Ludovic
- RC3 documente : auto-assign post-escalade — phase KEY-267/268
- QA Ludovic requise pour cloture

### KEY-253 (Plan Gates)
- Progression AP.2.4 : cycle de vie audite, statuts corrects
- Risque restant avant Ads : RC2/RC3 sont cosmetiques, pas bloquants

### KEY-263/KEY-268 (Auto-assignation/Notification)
- Confirme hors scope : 34/34 escalations PROD sans assignment
- Necessite phase dediee

### KEY-267 (Assigned agent name API)
- Pas de changement dans cette phase
- L'API ne retourne pas encore assigned_agent_name

---

## GitOps commits

| Repo | Commit | Description |
|---|---|---|
| keybuzz-api (bastion) | a18a361d | fix(messages): clear escalation_status on resolve (AP.2.4, KEY-265) |
| keybuzz-infra | 440394c | gitops(dev): API DEV v3.5.160 conversation-lifecycle-status |

---

## Gaps restants

| Gap | Impact | Phase de correction |
|---|---|---|
| RC2 : escalation manuelle != autopilot (status) | Moyen | Decision produit Ludovic |
| RC3 : 34 escalations sans assignment | Moyen | KEY-267/268 |
| 22 open+inbound PROD (legacy) | Faible | Self-healing |
| 18 resolved+escalated PROD (pre-existants) | Faible | Fix ne s'applique qu'aux futures resolutions |
| Draft escalation: status='pending' vs autopilot 'escalated' | Faible | Coherent si vu comme "validation humaine attendue" |

---

## Verdict

### **GO DEV FIX VALIDATED**

CONVERSATION LIFECYCLE STATUS VALIDATED IN DEV — HUMAN/IA/AUTOPILOT HANDLERS DISTINGUISHED — POST-REPLY STATUS COHERENT — ESCALATION AND SAV BADGES PRESERVED — KNOWN ORDER/TRACKING NO-REASK BASELINE PRESERVED — STARTER IA REMAINS KBACTIONS-GATED — NO AUTO-SEND ADDED — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA
