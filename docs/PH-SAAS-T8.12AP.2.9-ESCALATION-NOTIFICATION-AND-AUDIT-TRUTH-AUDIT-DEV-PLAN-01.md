# PH-SAAS-T8.12AP.2.9 — Escalation Notification & Audit — Truth Audit + Design

> Phase : PH-SAAS-T8.12AP.2.9-ESCALATION-NOTIFICATION-AND-AUDIT-TRUTH-AUDIT-DEV-PLAN-01
> Ticket : KEY-263
> Tickets liés : KEY-253, KEY-265, KEY-268
> Date : 2026-05-07
> Environnement : DEV audit + PROD read-only
> Type : audit vérité + décision design

---

## Objectif

Auditer le système d'alerte/notification lors d'une escalade de conversation.
Déterminer si une notification/alerte existe déjà, si le journal IA trace l'escalade,
et si l'UI rend l'escalade actionnable.

---

## Sources relues

| Document | Vérifié |
|---|---|
| CE_PROMPTING_STANDARD.md | OUI |
| RULES_AND_RISKS.md | OUI |
| AI_MESSAGING_FEATURE_PARITY_BASELINE.md | OUI |
| PH-SAAS-T8.12AP.2.8 (auto-assignment PROD) | OUI |
| PH-SAAS-T8.12AP.2.7 (auto-assignment DEV) | OUI |
| PH-SAAS-T8.12AP.2.5 (lifecycle PROD) | OUI |
| PH-SAAS-T8.12AP.2.6 (cleanup PROD) | OUI |
| PH-SAAS-T8.12AP.2 (escalation audit initial) | OUI |

---

## Baselines PROD (lecture seule confirmée)

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.147-auto-assignment-after-reply-prod` | OUI |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | OUI |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | OUI |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | OUI |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | OUI |

---

## Preflight repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `9521fb35` | dist/ uniquement | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `abef1bc4` | N/A (audité sur bastion) | OK |
| keybuzz-infra | `main` | `919a8e7` | propre | OK |

---

## ÉTAPE 1 — Cartographie complète des sources d'escalade

### 5 chemins d'escalade identifiés

| # | Source | Fichier | Trigger | Champs DB modifiés | Notification table ? | Audit (message_events) ? | Audit (ai_action_log) ? |
|---|---|---|---|---|---|---|---|
| 1 | **Autopilot engine** | `engine.ts:882` | Confiance IA insuffisante | escalation_status, target, reason, escalated_at, by_type=`ai`, status=`escalated` | **NON** | OUI (`autopilot_escalate`) | OUI (`autopilot_escalate`) |
| 2 | **Autopilot draft consume** | `autopilot/routes.ts:368` | Humain valide un brouillon d'escalade | Mêmes champs, by_type=`ai` | **NON** | OUI (`autopilot_escalate`) | OUI (`draft_applied`) |
| 3 | **Reply promise detection** | `messages/routes.ts:600` | Fausses promesses détectées dans la réponse | escalation_status, target=`client`, by_type=`system` | **NON** | OUI (`auto_escalate_false_promise`) | NON |
| 4 | **AI assist needsHumanAction** | `ai-assist-routes.ts:975` | IA détecte action humaine nécessaire | escalation_status, target=`human_agent`, by_type=`ai_auto` | **NON** | **NON** (gap) | OUI (`AI_AUTO_ESCALATED`) |
| 5 | **Escalade manuelle** | `messages/routes.ts:1040` | Bouton "Escalader" dans l'UI | escalation_status, reason, by_type=`human` | **NON** | OUI (`escalation_change`) | NON |

### Fonction centrale : `escalateConversation()` (engine.ts:882)

```typescript
async function escalateConversation(conversationId, tenantId, target, reason) {
  // 1. UPDATE conversations SET escalation_status = 'escalated', ...
  // 2. INSERT INTO message_events (type='autopilot_escalate')
  // PAS de INSERT INTO notifications
}
```

### Gap identifié

Le chemin #4 (AI assist) n'écrit PAS dans `message_events`. Impact mineur (7 occurrences PROD).

---

## ÉTAPE 2 — Audit DB DEV

| Signal | Count | Commentaire |
|---|---|---|
| Conversations escalated | 45 | Par statut/cible/source ci-dessous |
| Escalated + assigned NULL | 44 | "À prendre en charge" |
| Escalated + assigned NOT NULL | 1 | 1 seule assignée |
| resolved + escalated | 3 | Artefacts de test pré-AP.2.4 (DEV) |
| `message_events` escalation | 65 | 34 autopilot + 16 false_promise + 15 manual |
| `ai_action_log` escalation | 43 | autopilot_escalate |
| Notifications | **0** | Table vide |
| `conversation_events` | 0 lignes | Table vide |

### Détail conversations escaladées DEV

| Status | escalation_status | target | by_type | Count |
|---|---|---|---|---|
| open | escalated | client | ai | 19 |
| open | escalated | client | system | 11 |
| open | escalated | NULL | ai | 7 |
| resolved | escalated | client | system | 3 |
| escalated | escalated | client | ai | 2 |
| pending | escalated | client | ai | 1 |
| pending | escalated | NULL | human | 1 |
| pending | escalated | NULL | ai | 1 |

---

## ÉTAPE 3 — Audit PROD read-only

| Signal | Count | Risque |
|---|---|---|
| open + escalated | 16 | Normal |
| open/escalated/client/ai | 8 | Autopilot |
| open/escalated/client/system | 6 | Promise detection |
| open/escalated/human_agent/ai_auto | 2 | AI assist |
| Escalated + assigned NULL | 16 | "À prendre en charge" |
| Escalated + assigned NOT NULL | 0 | Aucun |
| resolved + escalated | **0** | Clean (AP.2.6) |
| pending + escalated | 0 | Clean |
| `message_events` escalation | 44 | 10 autopilot + 21 false_promise + 13 manual |
| `ai_action_log` escalation | 20 | 13 autopilot_escalate + 7 AI_AUTO_ESCALATED |
| Notifications | **0** | Table vide |
| billing_events | 160 | Inchangé |
| Total conversations | 561 | Inchangé |
| Total messages | 1661 | Inchangé |

---

## ÉTAPE 4 — Audit UI

| Surface UI | Fichier | Affichage actuel | Suffisant ? | Patch requis ? |
|---|---|---|---|---|
| Badge escalade | `TreatmentStatusPanel.tsx` | Point rouge + "Escaladée" en rouge | OUI | NON |
| Cible escalade | `TreatmentStatusPanel.tsx` | "→ Votre équipe" / "→ Agent KeyBuzz" / "→ Votre équipe + KeyBuzz" | OUI | NON |
| Source escalade | `TreatmentStatusPanel.tsx` | "(par l'IA)" / "(manuellement)" | OUI | NON |
| Raison escalade | `TreatmentStatusPanel.tsx` | Texte tronqué sous le badge | OUI | NON |
| Non assigné + escaladé | `TreatmentStatusPanel.tsx` | "À prendre en charge" (orange gras) | OUI | NON |
| Filtre "pickup" | `InboxTripane.tsx:842` | `escalationStatus === "escalated" && !assignedAgentId` | OUI | NON |
| Tri prioritaire | `InboxTripane.tsx:854` | Escalated = prio 0 (en haut) | OUI | NON |
| Bouton Escalader | `useConversationEscalation.ts` | Escalate/Deescalate via BFF | OUI | NON |
| Raisons config | `escalationReasons.ts` | 6 raisons prédéfinies | OUI | NON |
| Plans/capabilities | `planCapabilities.ts` | escalationTarget par plan | OUI | NON |
| Journal IA / ai-journal | `/ai-journal` | Lit `ai_action_log` — entries `autopilot_escalate` présentes | OUI | NON |

---

## ÉTAPE 5 — Audit Notification / Alerting

| Mécanisme | État | Détail |
|---|---|---|
| Table `notifications` | **Existe, 0 lignes** | 11 colonnes, schéma complet (id, tenant_id, conversation_id, channel, level, title, body, status, created_at, delivered_at, acknowledged_at) |
| Module `notificationsRoutes` | **Enregistré dans app.ts** | CRUD + simulate (GET list, GET detail, PATCH ack, POST simulate) |
| Écriture dans `notifications` | **ABSENTE** | Aucun code d'escalade n'écrit dans cette table |
| WebSocket / SSE | **ABSENT** | 0 référence dans le code API |
| Email interne | **ABSENT** | Aucun envoi d'email sur escalade |
| Slack / Teams | **ABSENT** | Aucune intégration |
| Composant NotificationBell client | **ABSENT** | Pas de cloche, pas de badge count |
| Polling notifications client | **ABSENT** | Aucun hook de polling `/notifications` |
| Settings > Notifications | **Existe** | Tab dans settings, mais config email/desktop, pas lié à la table |

### Classification

| Mécanisme | Verdict |
|---|---|
| Table notifications DB | Existe mais **non alimentée** |
| API CRUD notifications | Existe mais **jamais appelée** par l'app |
| UI consumption notifications | **Absente** |
| Push/realtime | **Absent** |
| Email on-escalade | **Absent** — dangereux sans consentement |
| External webhook | **Absent** |

---

## ÉTAPE 6 — Décision d'implémentation

### Questions produit tranchées

| Question | Réponse |
|---|---|
| Quand l'IA escalade, où est-ce stocké ? | `conversations` (5 colonnes escalade) + `message_events` + `ai_action_log` — **SUFFISANT** |
| L'escalade est visible dans l'UI ? | OUI : badge rouge, cible, source, raison, filtre "pickup", tri prioritaire — **SUFFISANT** |
| Quelqu'un reçoit une notification ? | **NON** — aucune notification in-app, email ou push |
| Le journal IA trace l'escalade ? | OUI : `ai_action_log` (autopilot_escalate, AI_AUTO_ESCALATED) visible dans /ai-journal — **SUFFISANT** |
| Agent KeyBuzz est un vrai destinataire ? | **NON** — label de destination d'escalade, pas un workflow humain réel |
| Module Agent KeyBuzz gating existe ? | OUI (`hasAgentKeybuzzAddon` dans `useCurrentPlan.tsx`) — boolean simple, pas de module avec queue/routing |
| Plans respectent les droits ? | OUI : STARTER=none, PRO/AUTOPILOT_ASSISTED=client_team, AUTOPILOT/ENTERPRISE=keybuzz_team |

### Analyse coût/bénéfice du patch notification DB

| Option | Effort | Risque | Valeur visible |
|---|---|---|---|
| Écrire dans `notifications` table sur escalade (API patch ~10 lignes) | Faible | Nul | **ZÉRO** — aucun composant client ne lit cette table |
| Ajouter NotificationBell client + polling | Moyen (Client + API) | Faible | **HAUTE** — alerte visuelle pour l'agent |
| WebSocket/SSE push | Élevé | Moyen | Optimal mais heavy |

### Décision

**NE PAS PATCHER EN DEV MAINTENANT.**

Justification :
1. L'audit trail est complet et tracé dans `message_events` + `ai_action_log`
2. L'UI inbox rend les escalades visibles, actionnables et prioritaires (badge + filtre + tri)
3. Écrire dans `notifications` sans consumer côté client = zéro valeur utilisateur
4. Le vrai besoin est un **système de notification complet** (API write + Client bell + badge count + liste) = feature dédiée
5. Pour le lancement Ads, les escalades sont déjà opérationnelles dans l'inbox

### Feature notification recommandée (phase future)

```
1. API : INSERT INTO notifications (tenant_id, conversation_id, level='warning', 
   title='Escalade', body=reason) lors de chaque escalade
2. Client : NotificationBell dans la topbar
   - Polling GET /notifications?status=unread&limit=10 toutes les 30s
   - Badge count
   - Dropdown avec liste
   - Click → navigate vers conversation
3. Client : Ack on click (PATCH /notifications/:id/ack)
4. Optionnel futur : WebSocket/SSE pour push temps réel
```

---

## AI Feature Parity / Anti-regression Matrix

| Feature documentée | Rapport/source | Source actuelle | Runtime | UI | Gap | Linear |
|---|---|---|---|---|---|---|
| No-reask commande/suivi | AP.1F | `REASK_PATTERNS` présent | PROD v3.5.147 | Client v3.5.168 | AUCUN | — |
| author_name Prénom.N | AP.2.2/2.3.1 | `formatAgentDisplayName` présent | PROD v3.5.147 | Client v3.5.168 | AUCUN | — |
| resolved clears escalation | AP.2.4/2.5 | `CASE WHEN` présent | PROD v3.5.147 | — | AUCUN | — |
| Historical cleanup | AP.2.6 | — | 0 resolved+escalated PROD | — | AUCUN | — |
| Auto-assignment reply | AP.2.7/2.8 | `assigned_agent_id IS NULL` | PROD v3.5.147 | — | AUCUN | — |
| Escalade audit trail | AP.2.9 | message_events + ai_action_log | DEV+PROD | /ai-journal | AUCUN | — |
| Escalade UI visible | AP.2.9 | — | — | TreatmentStatusPanel | AUCUN | — |
| Notification on-escalade | AP.2.9 | **ABSENTE** | — | **ABSENTE** | P2 | KEY-263 |
| Agent KeyBuzz workflow | AP.2.9 | Label seulement | — | Label honnête | P3 | à créer |

---

## Pas de patch DEV, pas de build, pas de deploy

Aucune modification de code, build ou déploiement dans cette phase.

---

## Linear

| Ticket | Mise à jour |
|---|---|
| KEY-263 | Audit complet réalisé. Notification on-escalade absente. Table `notifications` existe mais non alimentée. UI inbox suffisante pour Ads. Recommandation : phase dédiée NotificationBell (API + Client). Prio P2. NE PAS FERMER. |
| KEY-265 | Cycle conversation lifecycle quasi-complet. Escalade visible et actionnable. Notification proactive = seul gap (KEY-263). |
| KEY-253 | Progression avant Ads : no-reask + author_name + lifecycle + auto-assignment + escalade visible = tous PROD. Notification proactive = P2, non bloquant Ads. |
| KEY-268 | Auto-assignment PROD actif. Confirmé préservé. |

### Ticket recommandé à créer

**KEY-NEW : Système de notification in-app (NotificationBell)**
- Priorité : P2
- Scope : API (write notifications on escalade) + Client (bell + badge + dropdown + polling)
- Dépendance : aucune bloquante
- Critères : notification visible in-app en <30s après escalade, ack on click, 0 email non consenti

---

## Gaps restants

1. **Notification proactive on-escalade** : absente, phase dédiée recommandée (P2)
2. **Agent KeyBuzz workflow** : label seulement, pas de routage humain réel (P3, décision produit)
3. **`ai-assist-routes.ts` n'écrit pas dans `message_events`** : gap mineur dans l'audit trail (7 occurrences PROD)
4. **3 conversations DEV `resolved + escalated`** : artefacts de test, non bloquant

---

## Rollback

Aucun rollback nécessaire — phase d'audit sans modification de code ni déploiement.

---

## Verdict

### GO DESIGN READY — IMPLEMENTATION DEFERRED

L'audit prouve que :
- L'escalade est **stockée** correctement (conversations + message_events + ai_action_log)
- L'escalade est **visible** dans l'UI (badge rouge + cible + source + raison)
- L'escalade est **actionnable** (filtre "pickup" + tri prioritaire + bouton Prendre)
- L'escalade est **traçable** (journal IA + message_events)
- L'escalade est **honnête** (Agent KeyBuzz = label, pas de faux claim humain)
- La notification proactive est **absente** mais non bloquante pour le lancement Ads
- Le système de notification nécessite une **feature dédiée** (API + Client), pas un patch minimal

ESCALATION AUDIT COMPLETE — CONVERSATIONS ARE VISIBLE, ACTIONABLE AND TRACEABLE — AUDIT TRAIL IN MESSAGE_EVENTS + AI_ACTION_LOG — UI BADGE + FILTER + PRIORITY SORT FUNCTIONAL — NOTIFICATION PROACTIVE ABSENT BUT NON-BLOCKING FOR ADS — AGENT KEYBUZZ IS HONEST LABEL NOT FAKE HUMAN WORKFLOW — NO PATCH APPLIED — NO BUILD — NO DEPLOY — PROD UNCHANGED — NOTIFICATION SYSTEM DEFERRED TO DEDICATED PHASE (KEY-263)
