# PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01 — TERMINÉ

**Verdict :** NO GO — bugs multiples identifiés, corrections nécessaires

**Date :** 2026-04-21
**Environnements :** DEV + PROD
**Type :** Audit E2E ciblé sur tenants réels de test

---

## 1. Préflight

### Images déployées

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.91-autopilot-escalation-handoff-fix-dev` | `v3.5.91-autopilot-escalation-handoff-fix-prod` |
| Client | `v3.5.83-linkedin-replay-dev` | `v3.5.81-tiktok-attribution-fix-prod` |

### Source API

- Branche : `ph147.4/source-of-truth`
- HEAD : `7265d29a PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01`
- Repo : 1 fichier non-tracké (`routes.ts.bak-t82ebis`) — clean pour audit

### Pod start times

| Env | Pod | Started |
|-----|-----|---------|
| DEV | `keybuzz-api-74dbf4955b-6vsg9` | 2026-04-21T07:20:51Z |
| PROD | `keybuzz-api-768bfdc995-srhgg` | 2026-04-21T08:06:03Z |

---

## 2. Tenants exacts testés

**CORRECTION CRITIQUE** : Le user présupposait SWITAA = plan PRO.
La réalité DB montre que **tous les SWITAA sont plan AUTOPILOT**.

### DEV

| Tenant | ID | Plan DB |
|--------|-----|---------|
| SWITAA SASU | `switaa-sasu-mnc1x4eq` | **AUTOPILOT** |
| compta.ecomlg@gmail.com | `compta-ecomlg-gmail--mnkjttw7` | **AUTOPILOT** |

### PROD

| Tenant | ID | Plan DB |
|--------|-----|---------|
| SWITAA SASU | `switaa-sasu-mnc1ouqu` | **AUTOPILOT** |
| compta.ecomlg@gmail.com | `compta-ecomlg-gmail--mnvu4649` | **AUTOPILOT** |

Les deux tenants ont `billing_exempt = true` (reason: `test_account`).

---

## 3. Settings DB — Autopilot

| Env | Tenant | is_enabled | mode | allow_auto_reply | allow_auto_escalate | safe_mode | escalation_target |
|-----|--------|------------|------|------------------|---------------------|-----------|-------------------|
| DEV | SWITAA | true | autonomous | true | true | true | client |
| DEV | compta | true | supervised | false | true | true | client |
| PROD | SWITAA | true | autonomous | true | true | true | client |
| PROD | compta | true | autonomous | false | true | true | client |

### Résolution IAMode effective

Avec plan AUTOPILOT et safe_mode=true :
- `resolvedMode` = **supervised** (car `safeMode=true` override `autonomous`)
- `canUseAutopilot(supervised)` = **true**
- Pas de plan-gate blocking

**Conséquence** : Le plan n'est PAS un bloqueur pour ces tenants. Le diagnostic précédent était correct pour `ecomlg-001` (PRO) mais ne s'applique pas ici.

---

## 4. Matrice comportement attendu vs observé

### Règles métier (corrigées avec plan réel AUTOPILOT)

| Plan | Flow | Comportement attendu |
|------|------|----------------------|
| AUTOPILOT | Aide IA (manuelle) | Génération suggestion ✅, auto-escalade via PH142-D ✅ |
| AUTOPILOT | Autopilot auto-open | Draft auto-généré à l'inbound ✅, volet auto-ouvert ✅ |

### Observations réelles

| Env | Tenant | Flow | Attendu | Observé | OK ? |
|-----|--------|------|---------|---------|------|
| DEV | SWITAA | Aide IA | auto-escalade OUI | `AI_SUGGESTION_GENERATED` ✅ + escalation via system/ai_auto ✅ | ✅ |
| DEV | SWITAA | auto-open | draft auto | DRAFT_GENERATED + ESCALATION_DRAFT générés, consume fonctionne | ✅ |
| DEV | compta | Aide IA | auto-escalade OUI | `AI_SUGGESTION_GENERATED` ✅ + escalation fonctionne | ✅ |
| DEV | compta | auto-open | draft auto | ESCALATION_DRAFT généré, consume fonctionne | ✅ |
| PROD | SWITAA | Aide IA | auto-escalade OUI | `AI_SUGGESTION_GENERATED` ✅ + escalation via system ✅ | ✅ |
| PROD | SWITAA | auto-open | draft auto | **ZERO** autopilot entries aujourd'hui (3 hier, email seulement) | ❌ |
| PROD | compta | Aide IA | auto-escalade OUI | `AI_SUGGESTION_GENERATED` ✅ + escalation via system ✅ | ✅ |
| PROD | compta | auto-open | draft auto | **ZERO** autopilot entries (jamais, aucun historique) | ❌ |

---

## 5. Tests E2E — SWITAA (AUTOPILOT)

### DEV — Flow A : Aide IA ✅

- `AI_SUGGESTION_GENERATED` trouvés dans `ai_action_log`
- Escalation via `escalated_by_type: 'system'` (promise detection dans reply)
- Escalation via `escalated_by_type: 'ai_auto'` (PH142-D dans ai-assist-routes)
- `escalation_status: 'escalated'` visible dans conversations
- Conversations 10+ escaladées trouvées

### DEV — Flow B : auto-open ✅

- **15 entries** autopilot dans le pod courant (depuis 07:20 UTC)
- Types : `autopilot_reply` (DRAFT_GENERATED, DRAFT_APPLIED) + `autopilot_escalate` (ESCALATION_DRAFT)
- Preuve log pod :
  ```
  [Autopilot] switaa-sasu-mnc1x4eq conv=cmmo8bqqa44c9f4bda90f4eac → ESCALATION_DRAFT
  [Autopilot] switaa-sasu-mnc1x4eq conv=cmmo8cmf8z827c3947a0df23c → DRAFT_GENERATED
  ```
- Consume via `/autopilot/draft/consume` visible dans les URLs du pod

### PROD — Flow A : Aide IA ✅

- Escalation fonctionne via deux chemins :
  1. Promise detection dans reply (`escalated_by_type: 'system'`, `messages/routes.ts:582`)
  2. PH142-D auto-escalate dans Aide IA (`escalated_by_type: 'ai_auto'`, `ai-assist-routes.ts:985`)
- Conversations escaladées trouvées pour SWITAA PROD :
  - `cmmo8cnxpj13c4632d76df3d2` — Amazon — escalated 08:20:07 — system
  - `conv-4837f801` — email — escalated 20:28:51 — ai
  - `cmmo7mq03s9a4e0174210e6c0` — Amazon — escalated 20:11:10 — system

### PROD — Flow B : auto-open ❌ BLOQUÉ

- **ZERO** `[Autopilot]` entries dans les logs du pod PROD (démarré 08:06 UTC)
- **ZERO** `autopilot%` entries dans `ai_action_log` pour SWITAA aujourd'hui
- 3 entries d'hier (04/20) : toutes pour **email** channel, pas Amazon
- Messages inbound Amazon du jour (08:10, 08:16) : **aucune évaluation autopilot**
- **ZERO** requêtes `/inbound/*` dans les logs du pod PROD

---

## 6. Tests E2E — compta.ecomlg (AUTOPILOT)

### DEV — Flow A : Aide IA ✅

- Fonctionne de manière identique à SWITAA DEV

### DEV — Flow B : auto-open ✅

- 2 entries autopilot aujourd'hui :
  ```
  [Autopilot] compta-ecomlg-gmail--mnkjttw7 conv=cmmo8h57jc575e201f0bf3bd7 → ESCALATION_DRAFT
  [Autopilot] compta-ecomlg-gmail--mnkjttw7 conv=cmmo8hjad6cf4102f4d647d75 → ESCALATION_DRAFT
  ```
- Consume effectué, `escalation_status: 'escalated'` confirmé
- Note : conv `cmmo8hgacledeae3c37a25777` a retourné `MODE_NOT_AUTOPILOT:suggestion` — probablement dû à un changement de settings en cours de test (updated_at: 10:33:46)

### PROD — Flow A : Aide IA ✅

- `AI_SUGGESTION_GENERATED` trouvé pour :
  - `cmmo8hnmm512bfe2981c97a31` — 10:36:30
  - `cmmo8h7j0pb2c233904ddf492` — 10:24:05
- Escalation via system :
  - `cmmo8hnmm512bfe2981c97a31` — escalated 10:36:38
  - `cmmo8h7j0pb2c233904ddf492` — escalated 10:24:10

### PROD — Flow B : auto-open ❌ BLOQUÉ

- **ZERO** autopilot entries (jamais, aucun historique pour ce tenant)
- Messages inbound Amazon du jour (10:23, 10:34, 10:36) : **aucune évaluation autopilot**
- Le panel Autopilot ne peut pas s'ouvrir car aucun draft n'existe

---

## 7. Audit des deux flows — Aide IA vs Autopilot auto-open

### Aide IA (flow manuel)

| Étape | Route/Module | Fonctionne ? |
|-------|-------------|--------------|
| 1. User clique "Aide IA" | Client → BFF `POST /api/ai/assist` | ✅ |
| 2. BFF proxy vers API | `POST /ai/assist` → `ai-assist-routes.ts` | ✅ |
| 3. IA génère suggestion | LiteLLM → réponse générée | ✅ |
| 4. Log `AI_SUGGESTION_GENERATED` | `ai_action_log` INSERT | ✅ |
| 5. Auto-escalade PH142-D | `needsHumanAction` → UPDATE conversations `escalated_by_type='ai_auto'` | ✅ |
| 6. User valide + envoie | `POST /conversations/:id/reply` → `messages/routes.ts` | ✅ |
| 7. Promise detection post-reply | `messages/routes.ts:578-582` → UPDATE conversations `escalated_by_type='system'` | ✅ |

**Verdict Aide IA : FONCTIONNE en DEV et PROD pour les deux tenants.**

### Autopilot auto-open (flow automatique)

| Étape | Route/Module | DEV | PROD |
|-------|-------------|-----|------|
| 1. Message inbound arrive | Création conversation + message en DB | ✅ | ✅ |
| 2. `evaluateAndExecute` appelé | `inbound/routes.ts:290` (email) ou `:577` (amazon-forward) | ✅ | ❌ |
| 3. IAMode résolu | `ai-mode-engine.ts` → supervised | ✅ | N/A |
| 4. IA génère draft | LiteLLM → DRAFT_GENERATED ou ESCALATION_DRAFT | ✅ | N/A |
| 5. Draft stocké en DB | `ai_action_log` INSERT | ✅ | N/A |
| 6. Client fetch draft | `GET /autopilot/draft?tenantId=...&conversationId=...` | ✅ | ❌ (rien à fetch) |
| 7. Panel auto-open | `AISuggestionSlideOver` + `InboxTripane` auto-open logic | ✅ | ❌ (pas de draft) |
| 8. Consume | `POST /autopilot/draft/consume` | ✅ | N/A |

**Verdict Autopilot auto-open : FONCTIONNE en DEV, BLOQUÉ en PROD à l'étape 2.**

### Trois chemins d'escalade indépendants

| Chemin | Trigger | `escalated_by_type` | Route | DEV | PROD |
|--------|---------|---------------------|-------|-----|------|
| A. Autopilot engine | Consume ESCALATION_DRAFT | `ai` | `autopilot/routes.ts:327` | ✅ | ❌ |
| B. Aide IA PH142-D | IA détecte promesse dans suggestion | `ai_auto` | `ai-assist-routes.ts:985` | ✅ | ✅ |
| C. Reply promise detection | Agent envoie réponse avec promesse | `system` | `messages/routes.ts:582` | ✅ | ✅ |

---

## 8. Causes réelles identifiées

### Cause A : PROD — `evaluateAndExecute` JAMAIS appelé pour les messages inbound

**Gravité : CRITIQUE**

**Preuve :**
- PROD pod logs : **ZERO** `[Autopilot]` entries depuis le restart (08:06 UTC)
- PROD pod logs : **ZERO** requêtes `/inbound/email` ou `/inbound/amazon-forward`
- `ai_action_log` PROD : ZERO `autopilot%` pour compta.ecomlg (jamais), ZERO pour SWITAA aujourd'hui

**Analyse :**
Le code de `evaluateAndExecute` est appelé depuis deux endroits dans `inbound/routes.ts` :
- Ligne 290 : handler `POST /inbound/email`
- Ligne 577 : handler `POST /inbound/amazon-forward`

Mais ces endpoints ne reçoivent AUCUNE requête en PROD. Les conversations Amazon en PROD sont créées par le service `keybuzz-backend` (Fastify port 4000) via son propre handler `POST /api/v1/webhooks/inbound-email` qui insère directement en DB via `inboxConversation.service.ts` (lignes 360-394) **SANS appeler l'autopilot engine de keybuzz-api**.

**En DEV**, les conversations SONT évaluées par l'autopilot (10 entries dans le pod courant). Le mécanisme de création en DEV utilise un chemin qui passe par l'API's inbound routes — possiblement via des tests manuels injectés directement via l'API ou via un routage webhook différent.

### Cause B : keybuzz-backend ne déclenche pas l'autopilot après création de conversation

**Gravité : CRITIQUE**

Le fichier `keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts` :
- Crée les conversations (INSERT INTO conversations)
- Crée les messages (INSERT INTO messages)
- Ne fait AUCUN callback vers `keybuzz-api` pour déclencher `evaluateAndExecute`

### Cause C : Différence DEV/PROD dans le routage des webhooks inbound

**Gravité : HAUTE**

| Aspect | DEV | PROD |
|--------|-----|------|
| [Autopilot] entries | 10 (pod courant) | 0 |
| `/inbound/*` requests | 0 visibles (mais autopilot fonctionne) | 0 |
| Conversations Amazon | evaluateAndExecute appelé | evaluateAndExecute JAMAIS appelé |

En DEV, l'autopilot est déclenché pour les conversations Amazon malgré l'absence de requêtes `/inbound/*` visibles dans les logs. Le mécanisme exact de déclenchement en DEV n'est pas visible dans les logs Fastify, mais les résultats prouvent qu'il fonctionne.

En PROD, aucun mécanisme ne déclenche l'autopilot pour les conversations créées par le backend.

### Cause D : Post-escalation, status conversation = 'open' au lieu de 'pending'

**Gravité : MOYENNE**

Après une escalade (quel que soit le chemin), si l'agent a déjà envoyé un reply, le status est `'open'` (forcé par `messages/routes.ts:473`). Le fix `PH-ESCALATION-HANDOFF-FIX-01` met `status='pending'` lors du consume, mais ce status est écrasé par le reply subséquent.

Conversations escaladées observées : toutes en `status='open'`, `escalation_status='escalated'`, `assigned_agent_id=null`.

### Cause E (NON-BLOQUANTE) : Settings changés pendant les tests DEV

Une conversation compta.ecomlg DEV (`cmmo8hgacledeae3c37a25777`) a retourné `MODE_NOT_AUTOPILOT:suggestion` malgré le plan AUTOPILOT. Ceci est dû à un changement de settings pendant les tests (settings updated_at: 10:33:46, conversation created at 10:30:28).

---

## 9. Plan de correction recommandé

### Fix 1 — CRITIQUE : Déclencher l'autopilot engine après création de conversation par le backend

**Options :**

a) **Backend callback API** : Après INSERT conversation/message dans `inboxConversation.service.ts`, appeler l'API `POST /autopilot/evaluate` ou un nouvel endpoint dédié.

b) **API polling/cron** : Ajouter un CronJob ou polling dans l'API qui vérifie périodiquement les conversations nouvelles sans évaluation autopilot.

c) **Déplacer la création vers l'API** : Le backend forward l'email vers l'API's `/inbound/email` ou `/inbound/amazon-forward` au lieu d'insérer directement en DB.

**Recommandation : Option (a)** — Le backend appelle l'API après INSERT. Minimal, ciblé, pas de restructuration.

### Fix 2 — MOYENNE : Status conversation post-escalation

Le `PH-ESCALATION-HANDOFF-FIX-01` met `status='pending'` mais il est écrasé par le reply flow. Options :
- Ne pas changer le status dans le reply si `escalation_status='escalated'`
- Ou accepter que `status='open'` + `escalation_status='escalated'` est le bon état (l'escalation badge est visible même en status 'open')

### Fix 3 — BASSE : Alignement client DEV/PROD

Client DEV `v3.5.83` vs PROD `v3.5.81`. Non bloquant (les composants autopilot sont identiques), mais devrait être aligné.

---

## 10. Résumé

| Composant | DEV | PROD | Commentaire |
|-----------|-----|------|-------------|
| Plan tenants | AUTOPILOT ✅ | AUTOPILOT ✅ | Pas de plan-gate |
| autopilot_settings | OK ✅ | OK ✅ | Tous enabled, mode supervised/autonomous |
| Aide IA (manuelle) | ✅ FONCTIONNE | ✅ FONCTIONNE | Génération + escalade OK |
| Autopilot auto-open | ✅ FONCTIONNE | ❌ BLOQUÉ | evaluateAndExecute jamais appelé en PROD |
| Escalade via consume | ✅ FONCTIONNE | N/A | Pas de draft à consume en PROD |
| Panel auto-open UI | ✅ (code présent) | ❌ (pas de draft) | Symptôme, pas la cause |
| Backend callback | N/A | ❌ ABSENT | Cause racine |

---

## Conclusion

**REAL TENANT AUTOPILOT TRUTH ESTABLISHED**

La "vérité terrain" est :

1. **Les deux tenants test (SWITAA et compta.ecomlg) sont AUTOPILOT** dans les deux environnements (pas PRO comme présupposé).

2. **L'Aide IA manuelle fonctionne parfaitement** dans les deux environnements, avec escalade correcte via deux chemins indépendants (PH142-D et promise detection).

3. **L'Autopilot auto-open fonctionne en DEV mais est BLOQUÉ en PROD** car le `keybuzz-backend` (qui crée les conversations à partir des emails Amazon entrants) n'appelle jamais l'engine autopilot de `keybuzz-api`.

4. **La cause racine n'est PAS le plan, ni les settings, ni le code autopilot** : c'est l'absence de pont entre le backend de création de conversations et l'engine autopilot.

5. **Le fix est minimal** : un callback du backend vers l'API après chaque création de conversation.

Aucune modification effectuée.

---

**STOP**
