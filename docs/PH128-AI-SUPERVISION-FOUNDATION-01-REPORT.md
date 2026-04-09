# PH128-AI-SUPERVISION-FOUNDATION-01 — Rapport Final

> Date : 25 mars 2026
> Phase precedente : PH127-SAFE-AI-ASSIST-01 (validee)
> Verdict : **PH128 AI SUPERVISION READY**

---

## 1. Objectif

Ajouter une couche de supervision IA permettant de tracker les suggestions
proposees aux agents (PH127) et leur feedback (applique, ignore, vu).

Aucune modification du comportement existant. Tracking uniquement.

---

## 2. Ce qui a ete fait

### 2.1 Table PostgreSQL

Table `ai_suggestion_events` creee sur DEV et PROD :

| Colonne | Type | Description |
|---------|------|-------------|
| id | TEXT PK | Identifiant unique (ais-...) |
| conversation_id | TEXT NOT NULL | ID de la conversation |
| tenant_id | TEXT NOT NULL | ID du tenant |
| type | TEXT CHECK | assign, escalate, status, reply, priority |
| suggested_at | TIMESTAMPTZ | Date de la suggestion |
| action | TEXT CHECK | applied, dismissed, none |
| acted_at | TIMESTAMPTZ | Date de l'action (nullable) |
| user_id | TEXT | Agent qui a agi (nullable) |
| confidence | NUMERIC(4,3) | Score de confiance |
| label | TEXT | Label de la suggestion |
| reason | TEXT | Raison de la suggestion |

Index : tenant_id, conversation_id, type, action.

### 2.2 Routes API Backend (Fastify)

Fichier : `src/modules/ai/suggestion-tracking-routes.ts`

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/ai/suggestions/track` | Enregistre un evenement suggestion |
| GET | `/ai/suggestions/stats` | Retourne les statistiques agregees |

Stats retournees : totalSuggestions, applied, dismissed, ignored,
acceptanceRate (%), byType (breakdown), recent (20 derniers).

Filtres : tenantId (obligatoire), period (24h, 7d, 30d).

### 2.3 Routes BFF Client (Next.js)

| Route BFF | Proxie vers |
|-----------|-------------|
| POST `/api/ai/suggestions/track` | `POST /ai/suggestions/track` |
| GET `/api/ai/suggestions/stats` | `GET /ai/suggestions/stats` |

### 2.4 Hook useAISupervision

Fichier : `src/features/inbox/hooks/useAISupervision.ts`

Fonctions :
- `trackSuggestion(conversationId, type, confidence, label, reason)` — suggestion affichee
- `trackApply(conversationId, type, confidence, label)` — suggestion appliquee
- `trackDismiss(conversationId, type, confidence, label)` — suggestion ignoree

Deduplication via `useRef` pour eviter les doubles envois.
Fire-and-forget : les erreurs de tracking ne bloquent jamais l'UI.

### 2.5 Integration AISuggestionsPanel

Modifications additives :
- Import `useAISupervision` hook
- Nouvelle prop `tenantId` (passee depuis InboxTripane)
- Tracking automatique des suggestions affichees (`none`)
- Tracking a l'application (`applied`)
- Tracking a l'ignorance (`dismissed`)

Aucune modification de la logique des suggestions ou des actions existantes.

### 2.6 Vue Statistiques

Fichier : `src/features/inbox/components/AISuggestionStats.tsx`
Page : `/settings/ai-supervision`

Affiche :
- 4 KPIs : Total, Appliquees, Ignorees, Taux d'acceptation
- Breakdown par type (barres de progression)
- Evenements recents (20 derniers)
- Filtrage par periode (24h, 7d, 30d)
- Bouton rafraichir

Protege par `PermissionGate requires="canAccessSettings"`.

---

## 3. Ce qui n'a PAS ete modifie

- Logique des suggestions IA (aiSuggestions.ts) — inchangee
- Actions existantes (assign, escalate, status, reply) — inchangees
- InboxTripane.tsx — une seule prop ajoutee (`tenantId`), zero rewrite
- PH122 (roles/assignment) — intact
- PH123 (escalation) — intact
- PH124 (workbench) — intact
- PH125 (agent queue) — intact
- PH126 (priorites) — intact
- PH127 (suggestions IA) — intact
- Fournisseurs — intacts
- Commandes — intactes
- Billing/Onboarding — intacts

---

## 4. Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.51-ph128-ai-supervision-dev` | `v3.5.51-ph128-ai-supervision-prod` |
| Client | `v3.5.98-ph128-ai-supervision-dev` | `v3.5.98-ph128-ai-supervision-prod` |

---

## 5. Validation DEV

| Test | Resultat |
|------|----------|
| API health | OK |
| POST /ai/suggestions/track | OK (`{"ok":true,"id":"ais-..."}`) |
| GET /ai/suggestions/stats | OK (total, applied, dismissed, byType) |
| Stats coherence (3 events) | OK (1 applied, 1 dismissed, 1 ignored = 33% acceptance) |
| String "Supervision IA" dans chunks | PASS |
| String "trackSuggestion" dans chunks | PASS |
| String "Suggestions IA" (PH127) | PASS |
| String "Prendre la main" (PH127) | PASS |
| String "Prioritaires" (PH126) | PASS |
| String "Voir le fournisseur" | PASS |
| /inbox → 200 | OK (225ms) |
| /dashboard → 200 | OK (182ms) |
| /orders → 200 | OK (128ms) |
| /suppliers → 200 | OK (180ms) |
| /settings/ai-supervision → 200 | OK (140ms) |

**PH128 DEV = OK**

---

## 6. Validation PROD

| Test | Resultat |
|------|----------|
| API health | OK |
| POST /ai/suggestions/track | OK |
| GET /ai/suggestions/stats | OK |
| String "Supervision IA" dans chunks | PASS |
| String "trackSuggestion" dans chunks | PASS |
| String "Suggestions IA" (PH127) | PASS |
| String "Prendre la main" (PH127) | PASS |
| String "Prioritaires" (PH126) | PASS |
| String "Voir le fournisseur" | PASS |
| /inbox → 200 | OK (142ms) |
| /dashboard → 200 | OK (121ms) |
| /orders → 200 | OK (132ms) |
| /suppliers → 200 | OK (118ms) |
| /channels → 200 | OK (153ms) |

**PH128 PROD = OK**

---

## 7. Rollback

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph123-escalation-foundation-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph123-escalation-foundation-prod -n keybuzz-api-prod

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.97-ph127-safe-ai-assist-dev -n keybuzz-client-dev
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.97-ph127-safe-ai-assist-prod -n keybuzz-client-prod
```

La table `ai_suggestion_events` peut rester (zero impact si les routes ne sont plus appelees).

---

## 8. Stop Points (hors perimetre PH128)

- Quotas de suggestions par plan
- Pricing des suggestions
- Limitations par plan
- Dashboard IA avance (graphiques temporels, heatmaps)
- Scoring ML des suggestions

---

## 9. Fichiers crees/modifies

### API (keybuzz-api)
- `src/modules/ai/suggestion-tracking-routes.ts` — NOUVEAU (144 lignes)
- `src/app.ts` — import + register (2 lignes ajoutees)

### Client (keybuzz-client)
- `app/api/ai/suggestions/track/route.ts` — NOUVEAU (24 lignes)
- `app/api/ai/suggestions/stats/route.ts` — NOUVEAU (24 lignes)
- `src/features/inbox/hooks/useAISupervision.ts` — NOUVEAU (67 lignes)
- `src/features/inbox/components/AISuggestionStats.tsx` — NOUVEAU (188 lignes)
- `app/settings/ai-supervision/page.tsx` — NOUVEAU (22 lignes)
- `src/features/inbox/components/AISuggestionsPanel.tsx` — MODIFIE (ajout tracking, ~15 lignes)
- `app/inbox/InboxTripane.tsx` — MODIFIE (ajout prop tenantId, 1 ligne)

### DB
- Table `ai_suggestion_events` — NOUVELLE (DEV + PROD)

---

# PH128 AI SUPERVISION READY
