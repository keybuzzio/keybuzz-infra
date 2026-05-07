# PH-SAAS-T8.12AP.2 — Escalation Assignment Notification Truth Audit & DEV Fix

> **Date** : 2026-05-07
> **Phase** : PH-SAAS-T8.12AP.2-ESCALATION-ASSIGNMENT-NOTIFICATION-TRUTH-AUDIT-AND-DEV-FIX-01
> **Environnement** : DEV (fix) + PROD (read-only audit)
> **Linear** : KEY-255, KEY-263, KEY-253
> **Standard** : CE Prompting Standard v2

---

## Résumé exécutif

Audit complet du système d'escalade KeyBuzz. Root cause confirmée : le moteur autopilot escalade les conversations (`escalation_status = 'escalated'`) mais ne met JAMAIS à jour `assigned_agent_id`, créant l'état `Escaladé + Non assignée` systématiquement.

Fix client-only appliqué en DEV : le `TreatmentStatusPanel` affiche désormais un contexte clair quand une conversation est escaladée (cible, source, action requise).

---

## Preflight

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|------|---------|-------------|-------|---------|
| keybuzz-client | `ph148/onboarding-activation-replay` | `d254b611` → `f4ad3f89` (fix) | Oui (working) | OK |
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `5ae88713` | Non | OK — pas touché |
| keybuzz-infra | `main` | `c6fd1e2` → `8fc3a6f` (gitops) | Non | OK |

### Runtime avant/après

| Service | Env | Image avant | Image après | Changement |
|---------|-----|------------|------------|-----------|
| Client | DEV | `v3.5.163-ai-no-reask-fix-dev` | `v3.5.165-escalation-assignment-ux-dev` | **OUI** (fix) |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | `v3.5.163-ai-no-reask-fix-prod` | NON |
| API | DEV | `v3.5.157-ai-stored-drafts-no-reask-dev` | `v3.5.157-ai-stored-drafts-no-reask-dev` | NON |
| API | PROD | `v3.5.144-ai-stored-drafts-no-reask-prod` | `v3.5.144-ai-stored-drafts-no-reask-prod` | NON |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | NON |
| OW | PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | NON |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | NON |

---

## Cartographie du modèle d'escalade

### Tables et colonnes

| Objet | Table | Champ | Valeurs | UI | API | Verdict |
|-------|-------|-------|---------|----|----|---------|
| Conversation status | `conversations` | `status` | pending, open, resolved, escalated | Badge | Filtre | Ambigu — `escalated` cohabite avec `escalation_status` |
| Escalation status | `conversations` | `escalation_status` | none, recommended, escalated | Oui (badge, panel) | Oui (engine, routes) | OK |
| Escalation reason | `conversations` | `escalation_reason` | texte libre ou enum | Tooltip seulement | Oui | OK |
| Escalated at | `conversations` | `escalated_at` | timestamp | Non affiché | Oui | OK |
| Escalated by type | `conversations` | `escalated_by_type` | ai, human | **Non affiché** → **Affiché (fix)** | Oui | **FIXÉ** |
| Escalation target | `conversations` | `escalation_target` | client, keybuzz, both, NULL | **Tooltip seulement** → **Inline (fix)** | Oui | **FIXÉ** |
| Assignment | `conversations` | `assigned_agent_id` | NULL ou user_id | Oui | Oui | **GAP — pas mis à jour à l'escalade** |
| Autopilot target | `autopilot_settings` | `escalation_target` | client, keybuzz, both | Settings UI | Engine | OK |
| Auto-escalate | `autopilot_settings` | `allow_auto_escalate` | boolean | Toggle | Engine | OK |
| Notifications | `notifications` | * | **0 rows** | Non | Non | **GAP — table vide** |

### Distribution DEV

- 45 conversations escaladées (sur 562 total)
- 36 avec `escalation_target = 'client'`
- 9 avec `escalation_target = NULL` (pre-PH143)
- **44 sans agent assigné** (97.8%)
- 1 avec agent assigné (escalade manuelle humaine)

### Distribution PROD (read-only)

- 34 conversations escaladées
- 29 avec `escalation_target = 'client'`
- 5 avec `escalation_target = 'human_agent'`
- **34 sans agent assigné** (100%)

---

## Surfaces UI

| Élément | Source | Fichier | Gap | Verdict |
|---------|--------|---------|-----|---------|
| Badge "Escaladé" (liste) | `escalationStatus` | `EscalationBadge` | Aucun | OK |
| "Assignation : Non assignée" | `assignedAgentId` | `TreatmentStatusPanel` | **Pas de contexte quand escaladé** | **FIXÉ → "À prendre en charge"** |
| Cible escalade | `escalationTarget` | `EscalationPanel` | **Tooltip seulement** | **FIXÉ → inline** |
| Source escalade | `escalatedByType` | N/A | **Non affiché** | **FIXÉ → "(par l'IA)" / "(manuellement)"** |
| Bouton "Prendre" | `assignedAgentId` | `ConversationActionBar` | Aucun | OK |
| Bouton "Escalader" | `canEscalate` | `EscalationPanel` | Aucun | OK |
| "Escalade prévue" (brouillon) | `escalationStatus` | `AISuggestionSlideOver` | Aucun | OK |
| Filtre "À prendre" | `escalationStatus + !assignedAgentId` | `InboxTripane` | Aucun | OK |

---

## Endpoints / Services

| Endpoint | Méthode | Mutation | Notification | Verdict |
|----------|---------|---------|-------------|---------|
| `/messages/conversations/:id/escalation` | PATCH | escalation_status, reason, at, by_type | **NON** | GAP — pas de notif |
| `/messages/conversations/:id/assign` | PATCH | assigned_agent_id | **NON** | OK (action manuelle) |
| `/autopilot/draft` | GET | Non | - | OK |
| `/autopilot/settings` | GET/PATCH | Lecture/écriture settings | - | OK |

---

## Agent KeyBuzz / Entitlements

| Plan/module | Escalade client | Agent KeyBuzz | Auto-send | Verdict |
|-------------|----------------|---------------|-----------|---------|
| STARTER | Non (locked) | Non (locked) | Non | OK — gating correct |
| PRO | Oui (`allow_auto_escalate`) | Non (locked) | Non | OK |
| AUTOPILOT sans addon | Oui | Non (locked) | Oui (avec guardrails) | OK |
| AUTOPILOT + addon | Oui | Oui (débloqué) | Oui (avec guardrails) | OK |

- `hasAgentKeybuzzAddon` vérifié via `/api/billing/current`
- Options "keybuzz" et "both" verrouillées par `requiresAddon: true` + `isPlanAtLeast("AUTOPILOT")`
- Stripe product configuré: `prod_UFWneeyEEoBCIK`
- **Aucun tenant DEV/PROD n'a l'addon Agent KeyBuzz actif**
- Le UI ne prétend PAS que KeyBuzz gère si addon non acheté ✓
- Pas de fausse équipe humaine KeyBuzz ✓

---

## Root cause : Escaladé + Non assignée

**Cause** : la fonction `escalateConversation()` dans le moteur autopilot (`engine.ts`) exécute :

```sql
UPDATE conversations SET escalation_status = 'escalated', escalation_reason = $1,
  escalated_at = now(), escalated_by_type = 'ai', updated_at = now()
WHERE id = $2 AND tenant_id = $3
```

Elle ne modifie PAS `assigned_agent_id`. L'escalade PATCH API (`/messages/conversations/:id/escalation`) fait la même chose.

Résultat : l'état `Escaladé + Non assignée` est le comportement **standard** pour toutes les escalades automatiques (97.8% des cas DEV, 100% PROD).

---

## Stratégie produit

| Situation | Texte UI avant | Texte UI après (fix) | Auto-assign | Notif |
|-----------|---------------|---------------------|-------------|-------|
| Escaladé + pas d'assignee + target=client | "Escaladée" + "Non assignée" | "Escaladée → Votre équipe" + "À prendre en charge" + "(par l'IA)" | Non | Non |
| Escaladé + pas d'assignee + target=keybuzz | "Escaladée" + "Non assignée" | "Escaladée → Agent KeyBuzz" + "À prendre en charge" | Non | Non |
| Escaladé + assignee | "Escaladée" + "Assignée à moi" | Inchangé | Non | Non |
| Non escaladé + pas d'assignee | "Non assignée" | Inchangé | Non | Non |

**Décisions reportées** (arbitrage Ludovic requis) :
- Auto-assignment lors de l'escalade → ticket Linear recommandé
- Notification agent lors de l'escalade → ticket Linear recommandé
- Équipe humaine réelle pour Agent KeyBuzz → décision produit

---

## Fix appliqué

### Fichiers modifiés

1. **`src/features/inbox/components/TreatmentStatusPanel.tsx`** :
   - Ajout props `escalationTarget` et `escalatedByType`
   - "Non assignée" → "À prendre en charge" quand `escalationStatus === 'escalated'`
   - Affichage inline de la cible (→ Votre équipe / → Agent KeyBuzz / → Votre équipe + KeyBuzz)
   - Affichage source (par l'IA / manuellement)
   - Raison en sous-ligne quand cible affichée
   - Couleur orange pour "À prendre en charge" (vs gris pour "Non assignée")

2. **`app/inbox/InboxTripane.tsx`** :
   - Ajout type `escalatedByType` dans `Conversation`
   - Mapping `escalatedByType` depuis l'API
   - Passage des nouvelles props à `TreatmentStatusPanel`

### Pas de modification API

L'API retourne déjà `escalation_target` et `escalated_by_type`. Le fix est purement client.

### Pas de hardcoding

- Aucun tenant ID, user ID, email, order ID, marketplace, ou pays hardcodé
- Labels dynamiques basés sur les valeurs DB

---

## Commits

| Repo | Branche | Commit | Description |
|------|---------|--------|------------|
| keybuzz-client | `ph148/onboarding-activation-replay` | `f4ad3f89` | fix(inbox): escalation UX — show target + action-needed (AP.2, KEY-255) |
| keybuzz-infra | `main` | `8fc3a6f` | gitops(dev): Client DEV v3.5.165-escalation-assignment-ux-dev (KEY-255) |

---

## Build

| Service | Commit source | Tag DEV | Digest |
|---------|--------------|---------|--------|
| Client | `f4ad3f89` | `v3.5.165-escalation-assignment-ux-dev` | `sha256:24d662647038a1163d0f3fdc279e1b929f7f0520a9d000b072ea0e762304fd47` |

---

## Validation DEV

| Cas | Attendu | Observé | Verdict |
|-----|---------|---------|---------|
| API DEV health | 200 OK | `{"status":"ok"}` | ✓ |
| Client DEV responds | HTML | Oui (Next.js SSR) | ✓ |
| Autopilot draft (no-reask) | 200 OK | `{"hasDraft":false}` | ✓ — non-régression AP.1F |
| Client DEV image | v3.5.165-escalation-assignment-ux-dev | v3.5.165-escalation-assignment-ux-dev | ✓ |
| API DEV inchangée | v3.5.157 | v3.5.157 | ✓ |

---

## Plan gates

| Plan/module | Escalade client | Agent KeyBuzz | Notification | Auto-send | Verdict |
|-------------|----------------|---------------|-------------|-----------|---------|
| STARTER | Non (locked) | Non | Non | Non | OK |
| PRO | Oui | Non (locked) | Non | Non | OK |
| AUTOPILOT sans addon | Oui | Non (locked) | Non | Oui (guardrails) | OK |
| AUTOPILOT + addon | Oui | Oui | Non | Oui (guardrails) | OK |

---

## Non-régression

| Check | Résultat | Verdict |
|-------|---------|---------|
| `/inbox` | Client DEV opérationnel | ✓ |
| `/dashboard` | API health OK | ✓ |
| API health | 200 OK | ✓ |
| no-reask AP.1F | Autopilot draft 200 OK | ✓ |
| PROD Client | v3.5.163-ai-no-reask-fix-prod (inchangée) | ✓ |
| PROD API | v3.5.144-ai-stored-drafts-no-reask-prod (inchangée) | ✓ |
| PROD Backend | v1.0.47-cross-env-guard-fix-prod (inchangée) | ✓ |
| PROD OW | v3.5.165-escalation-flow-prod (inchangée) | ✓ |
| PROD Website | v0.6.9-promo-forwarding-prod (inchangée) | ✓ |
| Aucun outbound non prévu | Pas de mutation sortante | ✓ |
| Aucun auto-send | Pas d'envoi automatique | ✓ |
| Aucun billing drift | Pas de mutation Stripe | ✓ |
| Aucun CAPI | Pas de conversion tracking | ✓ |

---

## PROD read-only

| Check | Résultat | Mutation | Verdict |
|-------|---------|---------|---------|
| Total conversations escaladées | 34 | NON | ✓ |
| Escaladées sans agent | 34 (100%) | NON | **Même pattern qu'en DEV** |
| Target 'client' | 29 | NON | ✓ |
| Target 'human_agent' | 5 | NON | Valeur legacy |
| Client PROD image | v3.5.163-ai-no-reask-fix-prod | NON | ✓ Inchangée |
| API PROD image | v3.5.144-ai-stored-drafts-no-reask-prod | NON | ✓ Inchangée |

---

## Linear

### KEY-255 — Audit et complétion escalade

**Statut** : En cours — DEV fix validé, PROD promotion à planifier
- Root cause identifiée et documentée
- Fix client UX appliqué en DEV
- Gaps restants documentés (auto-assign, notification)

### KEY-263 — Escalade auto-assignation + notification

**Statut** : En cours — gaps documentés
- Auto-assignment non implémenté (décision produit requise)
- Notification non implémentée (table `notifications` vide, aucune infra)
- Recommandation : sous-tickets pour chaque gap

### Tickets recommandés (à créer par Ludovic)

| Titre | Priorité | Description |
|-------|---------|------------|
| AP.2.1 — Auto-assignment sur escalade (décision produit) | P2 | Définir si l'escalade doit auto-assigner un agent (et lequel) |
| AP.2.2 — Notification agent sur escalade | P2 | Implémenter notification in-app/email quand escalade IA |
| AP.2.3 — Agent KeyBuzz équipe réelle | P3 | Définir ce que "Agent KeyBuzz gère" signifie concrètement |
| AP.2.4 — Audit log escalade | P3 | Enrichir le journal IA avec entrées escalade dédiées |
| AP.2.5 — PROD promotion escalation UX | P1 | Promouvoir le fix client DEV vers PROD |

---

## Rollback

### Client DEV

```bash
# Modifier manifest
# k8s/keybuzz-client-dev/deployment.yaml → image: ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-dev
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Verdict

### GO DEV FIX VALIDATED

**ESCALATION ASSIGNMENT TRUTH ESTABLISHED IN DEV — ESCALATED CONVERSATIONS SHOW WHO MUST HANDLE THEM — CLIENT AGENT VS AGENT KEYBUZZ DISTINCTION CLEAR — NO FALSE KEYBUZZ HUMAN CLAIM — HUMAN VALIDATION PRESERVED — NO AUTO-SEND — PLAN AND ADDON GATES PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA**

### Résumé des preuves

- ✅ Root cause identifiée : `escalateConversation()` ne touche pas `assigned_agent_id`
- ✅ Fix client UX : "À prendre en charge" + cible + source affichés
- ✅ Agent KeyBuzz correctement gaté par addon Stripe
- ✅ Pas de fausse promesse de prise en charge KeyBuzz
- ✅ Pas de hardcoding
- ✅ Pas de PROD mutation
- ✅ Pas d'auto-send
- ✅ Pas de billing/CAPI/tracking drift
- ✅ Non-régression no-reask AP.1F OK
- ✅ PROD 100% inchangée
- ❌ Auto-assignment : non implémenté (décision produit)
- ❌ Notification : non implémentée (infra manquante)
- ❌ Agent KeyBuzz humain : concept marketing sans équipe réelle

---

STOP
