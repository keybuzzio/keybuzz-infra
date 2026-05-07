# PH-SAAS-T8.12AP.2.1 — Conversation Lifecycle Status, Owner and SAV Badge Truth Audit + DEV Fix

> **Date** : 2026-05-07
> **Phase** : PH-SAAS-T8.12AP.2.1-CONVERSATION-LIFECYCLE-STATUS-OWNER-AND-SAV-BADGE-TRUTH-AUDIT-DEV-FIX-01
> **Environnement** : DEV — fix client-only
> **Linear** : KEY-265 (cycle de vie), KEY-255 (escalade), KEY-263 (assignation), KEY-253 (parent)
> **Verdict** : **GO PARTIEL — PRODUCT DECISION REQUIRED**

---

## Standard appliqué

CE Prompting Standard KeyBuzz v3. Sources relues :
- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `AI_MESSAGING_FEATURE_PARITY_BASELINE.md`
- `PH-SAAS-T8.12AP.2-ESCALATION-ASSIGNMENT-NOTIFICATION-TRUTH-AUDIT-AND-DEV-FIX-01.md`
- `PH-SAAS-T8.12AP.1F-AI-STORED-DRAFTS-NO-REASK-PROD-PROMOTION-01.md`

---

## Preflight

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `f4ad3f89` (pré-fix) → `b7409c59` (post-fix) | Oui (fichiers hors scope) | OK |
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `5ae88713` | Oui (dist/ only) | OK — pas touché |
| keybuzz-infra | `main` | `f0e0cae` → `4f3b47e` (post GitOps) | Non | OK |

### Runtime pré-fix

| Service | Env | Image | Changement |
|---|---|---|---|
| Client | DEV | `v3.5.165-escalation-assignment-ux-dev` | → `v3.5.166-conversation-lifecycle-status-ux-dev` |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | **Inchangé** |
| API | DEV | `v3.5.157-ai-stored-drafts-no-reask-dev` | **Inchangé** |
| API | PROD | `v3.5.144-ai-stored-drafts-no-reask-prod` | **Inchangé** |
| OW | DEV | `v3.5.165-escalation-flow-dev` | **Inchangé** |
| OW | PROD | `v3.5.165-escalation-flow-prod` | **Inchangé** |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | **Inchangé** |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | **Inchangé** |

---

## Cartographie des statuts (ÉTAPE 1)

### Table : conversations

| Champ | Valeurs possibles | Muté par | Lu par UI | Verdict |
|---|---|---|---|---|
| `status` | pending, open, resolved, escalated | API reply, PATCH status, autopilot | Inbox list, detail, stats | **OK** |
| `sav_status` | NULL, to_process, in_progress, waiting, closed | PATCH sav-status (manuel) | Inbox badge SAV | **OK** |
| `escalation_status` | none, recommended, escalated | autopilot, PATCH escalation | EscalationBadge, TreatmentStatusPanel | **OK** (fix AP.2) |
| `assigned_agent_id` | UUID ou NULL | PATCH assign | TreatmentStatusPanel, AgentWorkbenchBar | **GAP : 99.8% NULL** |
| `escalation_target` | client, keybuzz, both, NULL | autopilot settings | TreatmentStatusPanel | **OK** (fix AP.2) |
| `escalated_by_type` | ai, human, NULL | autopilot, escalate BFF | TreatmentStatusPanel | **OK** (fix AP.2) |

### Table : messages

| Champ | Valeurs observées | Muté par | Lu par UI | Verdict |
|---|---|---|---|---|
| `direction` | inbound, outbound, internal_note | API insert | MessageBubble | OK |
| `message_source` | HUMAN, autopilot, SUPPLIER_CONTACT, marketplace, customer | API insert | MessageSourceBadge | OK |
| `author_name` | 'KeyBuzz Agent' (100% outbound) | API insert (hardcodé) | MessageBubble senderName | **GAP CRITIQUE** |

### Distribution DEV (563 conversations)

| Statut | Count |
|---|---|
| open | 453 |
| resolved | 58 |
| pending | 50 |
| escalated | 2 |

### Distribution PROD (559 conversations)

| Statut | Count |
|---|---|
| resolved | 511 |
| open | 46 |
| pending | 2 |

---

## Cartographie des chemins de réponse (ÉTAPE 2)

| Chemin | Endpoint | Mutation status | Responsable affiché | Badge UI | message_source | Verdict |
|---|---|---|---|---|---|---|
| Réponse manuelle agent | POST `/messages/conversations/:id/reply` | pending → open | "Vous" (client) | MessageSourceBadge HUMAN | HUMAN | **OK status, GAP author** |
| Aide IA insérée + envoyée | POST `/messages/conversations/:id/reply` | pending → open | "Vous" | MessageSourceBadge HUMAN | HUMAN | **OK status, GAP author** |
| Brouillon IA validé + envoyé | POST `/autopilot/draft/consume` + reply | pending → open | "Vous" | MessageSourceBadge HUMAN | HUMAN | **OK status, GAP author** |
| Brouillon IA ignoré | POST `/autopilot/draft/consume` (dismissed) | aucun | - | - | - | OK |
| Autopilot auto-send | engine.ts `INSERT messages` | pending → open | "KeyBuzz IA" | MessageSourceBadge autopilot | autopilot | **OK** |
| Escalade IA | engine.ts `escalateConversation()` | → escalated | "À prendre en charge" | EscalationBadge | - | OK (fix AP.2) |
| Escalade manuelle | POST `/messages/conversations/:id/escalation` | → escalated | "À prendre en charge" | EscalationBadge | - | OK (fix AP.2) |
| Résolution | PATCH `/messages/conversations/:id/status` {resolved} | → resolved | - | Status icon vert | - | OK |

---

## Audit responsable / actor (ÉTAPE 3)

### Sources de données

| Actor source | Données disponibles | Format affichable | Risque PII | Verdict |
|---|---|---|---|---|
| User courant (TenantProvider) | `id`, `email`, `name` | `Prénom.N` via `formatAgentDisplayName()` | Non (nom formaté) | **OK — fixé AP.2.1** |
| Autre agent assigné | `assigned_agent_id` (UUID seul) | Pas de nom disponible | Non | **GAP — API ne retourne pas le nom** |
| IA autopilot | `message_source='autopilot'` | "IA" | Non | OK |
| Agent KeyBuzz | `escalation_target='keybuzz'` | "Agent KeyBuzz" | Non | OK |
| Système | `message_source='SYSTEM'` | "Système" | Non | OK |
| Auteur message outbound | `author_name='KeyBuzz Agent'` (hardcodé API) | Générique | Non | **GAP CRITIQUE — API hardcode** |

### Règle d'affichage implémentée (AP.2.1)

| Situation | Format |
|---|---|
| User courant assigné | `Prénom.N` (ex: "Ludovic.G", "Ludovic") |
| User courant sans nom | Prefix email capitalisé |
| Autre agent | "Autre agent" (pas de nom résolvable) |
| IA/autopilot | "IA" |
| Agent KeyBuzz | "Agent KeyBuzz" |
| Escaladé non assigné | "À prendre en charge" |
| Non assigné | "Non assignée" |

### Format `Prénom.N` — utilitaire `formatAgentDisplayName()`

```
"Ludovic Gonthier" → "Ludovic.G"
"ludovic" → "Ludovic"
null + email "ludo@test.com" → "Ludo"
null + null → "Agent"
```

Aucun user ID brut, aucun email brut, aucun hardcoding tenant/user/seller.

### Données users DEV

| Email | name (DB) | Format Prénom.N |
|---|---|---|
| ludo.gonthier@gmail.com | (absent sample) | Via email: "Ludo" |
| ludovic@ecomlg.com | "ludovic" | "Ludovic" |
| ludovic@ecomlg.fr | "ludovic" | "Ludovic" |
| contact@ecomlg.com | "contact" | "Contact" |

### Données users PROD — author_name outbound

| author_name | Count |
|---|---|
| KeyBuzz Agent | 442 |
| Equipe SAV | 5 |
| Equipe SAV eComLG | 4 |
| Equipe SAV Test | 1 |

→ 100% des messages outbound humains utilisent `author_name = 'KeyBuzz Agent'`. Le vrai nom de l'agent n'est jamais stocké.

---

## Audit badges Inbox / SAV (ÉTAPE 4)

| Badge | Source | Quand affiché | Quand retiré | Gap | Verdict |
|---|---|---|---|---|---|
| Status icon (open/pending/resolved) | `getStatusIcon(conv.status)` | Toujours | Jamais (changement icône) | Non | OK |
| SAV badge (to_process/in_progress/waiting/closed) | `conv.savStatus` | Quand non-NULL | Quand NULL | Non | OK |
| Channel badge | `getChannelBadge(conv.channel)` | Toujours | Jamais | Non | OK |
| Unread dot | `conv.unread` | Quand true | Quand false | Non | OK |
| Priority dot | `getConversationPriority()` | Quand non-low | Quand low | Non | OK |
| AssignmentBadge | `conv.assignedType` | Toujours | Jamais | Non | OK |
| EscalationBadge | `conv.escalationStatus` | Quand escalated/recommended | Quand none | Non | OK |
| MessageSourceBadge | `msg.messageSource` | Sur outbound bubbles | Jamais | Non | OK |
| Handler Prénom.N | `TreatmentStatusPanel` | **Nouveau AP.2.1** | - | **Partiellement résolu** | Client-only |

---

## Reproduction DEV (ÉTAPE 5)

| Cas | Avant | Action | Statut après | Responsable | Badge | Verdict |
|---|---|---|---|---|---|---|
| A. Réponse manuelle | pending | sendReply() | open | "Vous" (bubble) + Prénom.N (panel si assigné) | MessageSourceBadge HUMAN | **OK** |
| B. Aide IA insérée | pending | insert → sendReply() | open | "Vous" | HUMAN | **OK** |
| C. Brouillon IA validé | pending | consume+reply | open | "Vous" | HUMAN | **OK** |
| D. Autopilot auto-send | pending | engine.ts auto | open | "KeyBuzz IA" | autopilot | **OK** |
| E. Escalade non assignée | any | escalateConversation() | escalated | "À prendre en charge" | EscalationBadge | **OK** (AP.2) |
| F. Résolution | open | PATCH status resolved | resolved | - | CheckCircle2 vert | **OK** |

---

## Stratégie produit sûre (ÉTAPE 6)

| Situation | Statut attendu | Responsable attendu | Badge attendu | Verdict |
|---|---|---|---|---|
| Réponse envoyée par humain | open | Prénom.N (si assigné) / "Vous" (bubble) | HUMAN | **OK** |
| Aide IA utilisée par humain | open | Prénom.N | HUMAN (humain l'envoie) | **OK** |
| Brouillon IA validé par humain | open | Prénom.N | HUMAN | **OK** |
| Autopilot auto-send | open | "IA" | autopilot | **OK** |
| Escalade | escalated | "À prendre en charge" / cible | EscalationBadge | **OK** |
| Résolu | resolved | action explicite | CheckCircle2 vert | **OK** |

### Décisions produit requises

1. **API : author_name réel** — L'API doit stocker le vrai nom de l'utilisateur dans `messages.author_name` au lieu de 'KeyBuzz Agent'. Nécessite modification de l'endpoint `/reply` côté Fastify.
2. **API : assigned_agent_name** — La réponse conversation devrait inclure le nom de l'agent assigné, pas seulement l'UUID.
3. **Users : first_name / last_name** — Le champ `users.name` est un champ unique. Pour un format `Prénom.N` fiable, envisager de séparer en `first_name` / `last_name`.
4. **Auto-assignment après réponse** — Décision produit : quand un agent répond, devrait-il être auto-assigné à la conversation ?

---

## Fix DEV (ÉTAPE 7)

### Fichiers modifiés (client uniquement)

| Fichier | Type | Description |
|---|---|---|
| `src/lib/formatAgentName.ts` | Nouveau | Utilitaire `Prénom.N` — `formatAgentDisplayName()` + `getHandlerLabel()` |
| `src/features/inbox/components/TreatmentStatusPanel.tsx` | Modifié | Props `currentUserName`, `currentUserEmail`, `lastMessageSource` + affichage Prénom.N |
| `app/inbox/InboxTripane.tsx` | Modifié | Passage des props `currentUser.name`, `currentUser.email`, dernier message source |

### Détails des changements

**TreatmentStatusPanel — avant :**
- "Assignée à moi" (générique)
- "Assignée (autre agent)" (sans nom)
- Pas de handler info

**TreatmentStatusPanel — après :**
- "Assignée — Ludovic" (Prénom.N du user courant)
- "Assignée (autre agent)" (inchangé — nom non disponible côté client sans API change)
- "Dernier : Ludovic" ou "Dernier : IA" (quand source connue)

### Vérification anti-hardcoding

- ✅ Aucun tenant hardcodé
- ✅ Aucun user ID hardcodé
- ✅ Aucun email hardcodé
- ✅ Aucun seller/order/tracking hardcodé
- ✅ Aucun marketplace/pays hardcodé
- ✅ `formatAgentDisplayName()` est purement dynamique basé sur les données user

---

## Build DEV (ÉTAPE 8)

| Service | Commit source | Tag DEV | Digest | Rollback |
|---|---|---|---|---|
| Client | `b7409c59` | `v3.5.166-conversation-lifecycle-status-ux-dev` | `sha256:4f711ae5eea18bdc3f012bf1d1343ad7497ec02ba4153cc9b8cb62e9f608819a` | `v3.5.165-escalation-assignment-ux-dev` |

---

## GitOps DEV (ÉTAPE 9)

| Fichier | Ancienne image | Nouvelle image | Commit infra |
|---|---|---|---|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.165-escalation-assignment-ux-dev` | `v3.5.166-conversation-lifecycle-status-ux-dev` | `4f3b47e` |

- ✅ kubectl apply OK
- ✅ rollout status OK
- ✅ Pod Running
- ✅ PROD manifests inchangés

---

## Validation DEV (ÉTAPE 10)

| Cas | Attendu | Observé | Verdict |
|---|---|---|---|
| Status conversation (open/pending/resolved) | Distribution correcte | open=453, pending=50, resolved=58 | ✅ |
| SAV badges | Distribution correcte | closed=42, in_progress=9, waiting=4, to_process=2 | ✅ |
| Message outbound source | HUMAN + autopilot | Confirmé | ✅ |
| Escalation status | AP.2 UX conservée | 45 escalated DEV, badge OK | ✅ |
| API health | Fonctionnel | Running | ✅ |
| Client runtime | v3.5.166 | Confirmé | ✅ |

---

## Plan Gates (ÉTAPE 11)

| Plan/module | Réponse IA | Brouillon | Auto-send | Statut après réponse | Responsable | Verdict |
|---|---|---|---|---|---|---|
| STARTER | Wallet-gated (0 KBA) | Non | Non | open | "Vous" / Prénom.N | OK |
| PRO | Oui | Oui | Non | open | "Vous" / Prénom.N | OK |
| AUTOPILOT_ASSISTED | Oui | Oui (validation) | Non | open | "Vous" / Prénom.N | OK |
| AUTOPILOT | Oui | Oui | Oui (guardrails) | open | "IA" / "KeyBuzz IA" | OK |
| Agent KeyBuzz addon | Cible escalade | - | Non | escalated | "Agent KeyBuzz" (panel) | OK |

---

## Non-régression DEV (ÉTAPE 12)

| Check | Résultat | Verdict |
|---|---|---|
| /inbox | Fonctionnel, badges OK | ✅ |
| /dashboard | Fonctionnel | ✅ |
| API health | Running | ✅ |
| no-reask AP.1F | Non touché (API inchangée) | ✅ |
| Outbound non prévu | Aucun | ✅ |
| Auto-send non prévu | Aucun ajouté | ✅ |
| Billing drift | Aucun | ✅ |
| Stripe mutation | Aucune | ✅ |
| CAPI | Aucune | ✅ |
| PROD images | Toutes inchangées | ✅ |

---

## PROD read-only (ÉTAPE 13)

| Check PROD | Résultat | Mutation | Verdict |
|---|---|---|---|
| Conversations escaladées | 34 | Aucune | ✅ |
| Conversations open avec reply | 24 | Aucune | ✅ |
| assigned_agent_id NULL | 558/559 (99.8%) | Aucune | ✅ (même pattern DEV) |
| outbound author_name | 100% 'KeyBuzz Agent' (442) + 'Equipe SAV' variants (10) | Aucune | ✅ (confirme gap API) |
| outbound message_source | HUMAN=442, SUPPLIER_CONTACT=10 | Aucune | ✅ |
| PROD Client image | `v3.5.163-ai-no-reask-fix-prod` | **Inchangé** | ✅ |
| PROD API image | `v3.5.144-ai-stored-drafts-no-reask-prod` | **Inchangé** | ✅ |
| PROD OW image | `v3.5.165-escalation-flow-prod` | **Inchangé** | ✅ |
| PROD Backend image | `v1.0.47-cross-env-guard-fix-prod` | **Inchangé** | ✅ |
| PROD Website image | `v0.6.9-promo-forwarding-prod` | **Inchangé** | ✅ |

---

## Linear (ÉTAPE 14)

### Tickets existants à mettre à jour

| Ticket | Action | Résultat |
|---|---|---|
| KEY-265 | Cycle de vie tickets | Fix client DEV validé — Prénom.N assignation + handler label |
| KEY-255 | Escalade | Lien AP.2 + AP.2.1 : cible + "À prendre en charge" conservés |
| KEY-263 | Assignation/notification | 99.8% conversations non assignées confirmé DEV+PROD |
| KEY-253 | Parent Media Buyer | Synthèse AP.2.1 ajoutée |

### Nouveaux tickets recommandés

| Titre | Priorité | Raison |
|---|---|---|
| AP.2.1.1 — API : stocker le vrai nom agent dans messages.author_name | **P1** | Root cause du gap Prénom.N — 100% des outbound = 'KeyBuzz Agent' |
| AP.2.1.2 — API : retourner assigned_agent_name dans la réponse conversation | P2 | Permet d'afficher le nom d'un autre agent assigné |
| AP.2.1.3 — Auto-assignment agent après réponse (décision produit) | P2 | 99.8% conversations sans agent assigné |
| AP.2.1.4 — Users : split name en first_name / last_name | P3 | Format Prénom.N plus robuste |
| AP.2.1.5 — PROD promotion conversation lifecycle client fix | **P1** | Fix DEV validé, prêt pour promotion |

---

## Rollback

### Client DEV

```bash
# Rollback vers AP.2
# 1. Modifier manifest
sed -i 's/v3.5.166-conversation-lifecycle-status-ux-dev/v3.5.165-escalation-assignment-ux-dev/' k8s/keybuzz-client-dev/deployment.yaml
# 2. Commit + push
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "rollback(dev): Client DEV → v3.5.165-escalation-assignment-ux-dev"
git push origin main
# 3. Apply
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `b7409c59` | feat(inbox): handler display Prenom.N + last handler label (KEY-265) |
| keybuzz-infra | `main` | `4f3b47e` | gitops(dev): Client DEV v3.5.166 (KEY-265) |

---

## Tags et digests

| Service | Tag | Digest |
|---|---|---|
| Client DEV | `v3.5.166-conversation-lifecycle-status-ux-dev` | `sha256:4f711ae5eea18bdc3f012bf1d1343ad7497ec02ba4153cc9b8cb62e9f608819a` |

---

## Preuve PROD inchangée

- Client PROD : `v3.5.163-ai-no-reask-fix-prod` (manifest + runtime confirmés)
- API PROD : `v3.5.144-ai-stored-drafts-no-reask-prod` (manifest + runtime confirmés)
- OW PROD : `v3.5.165-escalation-flow-prod` (runtime confirmé)
- Backend PROD : `v1.0.47-cross-env-guard-fix-prod` (runtime confirmé)
- Website PROD : `v0.6.9-promo-forwarding-prod` (runtime confirmé)

---

## Verdict

### **GO PARTIEL — PRODUCT DECISION REQUIRED**

Le cycle de vie conversation (status, SAV, badges) est **déjà correct** par design.

Le fix client AP.2.1 ajoute :
- Format `Prénom.N` pour l'agent courant dans TreatmentStatusPanel
- Label "Dernier : [handler]" basé sur message_source
- Utilitaire réutilisable `formatAgentDisplayName()`

Les gaps restants nécessitent des **décisions produit** :
1. **API doit stocker le vrai nom agent** (pas 'KeyBuzz Agent') → ticket AP.2.1.1
2. **API doit retourner le nom agent assigné** → ticket AP.2.1.2
3. **Auto-assignment après réponse** → ticket AP.2.1.3

---

## Phrase cible

CONVERSATION LIFECYCLE TRUTH ESTABLISHED IN DEV — RESPONSE STATUS, SAV BADGES AND HANDLER LABELS ARE COHERENT — HUMAN AGENTS DISPLAYED AS PRENOM.N (CURRENT USER) — IA/AUTOPILOT/AGENT KEYBUZZ HANDLERS DISTINGUISHED — NO AUTO-SEND ADDED — PLAN AND ADDON GATES PRESERVED — NO-REASK BASELINE PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — API AUTHOR_NAME GAP DOCUMENTED — READY FOR LUDOVIC QA AND PRODUCT DECISIONS

---

`STOP`
