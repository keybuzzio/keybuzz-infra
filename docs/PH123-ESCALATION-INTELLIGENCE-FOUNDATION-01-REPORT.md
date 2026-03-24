# PH123-ESCALATION-INTELLIGENCE-FOUNDATION-01 — Rapport

> Date : 2026-03-24
> Phase : PH123 — Escalation Intelligence Foundation
> Status : **PH123 ESCALATION FOUNDATION READY**

---

## Objectif

Poser la fondation du systeme d'escalade conversationnelle IA → humain :
- Representer une conversation comme escaladee ou non
- Stocker la raison de l'escalade
- Exposer ce statut a l'UI
- Differencier : conversation IA normale / recommandee pour escalade / escaladee active

---

## Modele d'escalade ajoute

### Colonnes DB (table `conversations`)

| Colonne | Type | Default | Description |
|---------|------|---------|-------------|
| `escalation_status` | TEXT | `'none'` | `none` / `recommended` / `escalated` |
| `escalation_reason` | TEXT | NULL | Raison de l'escalade |
| `escalated_at` | TIMESTAMPTZ | NULL | Date de l'escalade |
| `escalated_by_type` | TEXT | NULL | `ai` / `human` |

Migration executee sur DEV et PROD via Patroni leader (10.0.0.122).

### Raisons d'escalade retenues

| Code | Label FR |
|------|----------|
| `customer_angry` | Client mecontent |
| `refund_sensitive` | Remboursement sensible |
| `complex_case` | Cas complexe |
| `supplier_needed` | Fournisseur requis |
| `manual_review` | Revue manuelle |
| `other` | Autre |

---

## Endpoints crees

### API Backend (Fastify)

| Method | Route | Description |
|--------|-------|-------------|
| PATCH | `/messages/conversations/:id/escalation` | Changer le statut d'escalade |
| GET | `/messages/conversations/:id/escalation` | Lire le statut d'escalade |

Necessite `X-Tenant-Id` header ou `?tenantId=` query param.

### BFF (Next.js)

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/conversations/escalate` | Escalader une conversation |
| POST | `/api/conversations/deescalate` | Retirer l'escalade |
| GET | `/api/conversations/escalation-status` | Lire le statut |

Tous proteges par NextAuth (401 sans session).

---

## Fichiers modifies

### API (keybuzz-api)

| Fichier | Changement |
|---------|-----------|
| `src/modules/messages/routes.ts` | +2 routes PATCH/GET escalation, +colonnes escalation dans 2 SELECTs |

### Client (keybuzz-client)

| Fichier | Changement | Type |
|---------|-----------|------|
| `src/services/conversations.service.ts` | +8 lignes (4 champs interface, 4 mappings) | Patch additif |
| `app/inbox/InboxTripane.tsx` | +15 lignes (import, interface, mapping, EscalationBadge, EscalationPanel) | Patch additif |
| `src/features/inbox/config/escalationReasons.ts` | Nouveau fichier — types + labels | Nouveau |
| `src/features/inbox/hooks/useConversationEscalation.ts` | Nouveau fichier — hook escalation | Nouveau |
| `src/features/inbox/components/EscalationPanel.tsx` | Nouveau fichier — panel + badge | Nouveau |
| `app/api/conversations/escalate/route.ts` | Nouveau fichier — BFF escalate | Nouveau |
| `app/api/conversations/deescalate/route.ts` | Nouveau fichier — BFF deescalate | Nouveau |
| `app/api/conversations/escalation-status/route.ts` | Nouveau fichier — BFF get status | Nouveau |

---

## Comportement escalade <> assignation (PH122)

### Regles de coherence

| Cas | assignedType | escalationStatus |
|-----|-------------|-----------------|
| Conversation IA normale | `ai` | `none` |
| IA recommande escalade | `ai` | `recommended` |
| Humain prend + escalade | `human` | `escalated` |

### Transition "Relacher" (unassign)

Comportement retenu : **l'escalation_status est independant de l'assignation**.
- Relacher une conversation ne change PAS son statut d'escalade
- L'escalade doit etre retiree explicitement via "Retirer escalade"
- Justification : une conversation escaladee peut etre en attente de reprise par un autre agent

### Non-interference

- PH122 `ASSIGN/UNASSIGN` fonctionne toujours (200 OK DEV + PROD)
- Les badges IA/Humain restent inchanges
- Les badges escalade sont ADDITIFS (ne remplacent rien)

---

## Permissions

Reutilisation de PH121 via `usePermissions()` :
- `owner` → peut escalader / desescalader
- `admin` → peut escalader / desescalader
- `agent` → peut escalader / desescalader
- `viewer` → lecture seule (pas de boutons)

---

## Validations DEV

| Test | Resultat |
|------|---------|
| Pages (/, /inbox, /dashboard, /orders, /suppliers, /channels, /settings, /billing, /login) | 200 OK |
| BFF auth (/api/conversations/escalate, /deescalate) | 401 (protege) |
| ESCALATE conversation | 200 OK |
| GET escalation status | 200 OK, `escalated` |
| DEESCALATE conversation | 200 OK |
| GET apres deescalate | 200 OK, `none` |
| PH122 ASSIGN (self) | 200 OK |
| PH122 UNASSIGN | 200 OK |
| Conversations list | OK |
| Suppliers | OK |
| Orders | OK |
| Dashboard | OK |
| Health | OK |

**PH123 ESCALATE DEV = OK**
**PH123 DEESCALATE DEV = OK**
**PH123 DEV NO REGRESSION = OK**

---

## Validations PROD

| Test | Resultat |
|------|---------|
| Pages (/, /inbox, /dashboard, /orders, /suppliers, /channels, /settings, /billing, /login) | 200 OK |
| BFF auth (/api/conversations/escalate, /deescalate) | 401 (protege) |
| ESCALATE conversation | 200 OK |
| GET escalation status | 200 OK, `escalated` |
| DEESCALATE conversation | 200 OK |
| GET apres deescalate | 200 OK, `none` |
| PH122 ASSIGN (self) | 200 OK |
| PH122 UNASSIGN | 200 OK |
| Conversations list | OK |
| Suppliers | OK |
| Orders | OK |
| Dashboard | OK |
| Health | OK |

**PH123 ESCALATE PROD = OK**
**PH123 DEESCALATE PROD = OK**
**PH123 PROD NO REGRESSION = OK**

---

## Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.50-ph123-escalation-foundation-dev` | `v3.5.50-ph123-escalation-foundation-prod` |
| Client | `v3.5.91-ph123-escalation-foundation-dev` | `v3.5.91-ph123-escalation-foundation-prod` |

---

## Rollback

### Client DEV
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.90-ph122-assignment-self-agent-fix-dev -n keybuzz-client-dev
```

### Client PROD
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.90-ph122-assignment-self-agent-fix-prod -n keybuzz-client-prod
```

### API DEV
```
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49-amz-orders-list-sync-fix-dev -n keybuzz-api-dev
```

### API PROD
```
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49-amz-orders-list-sync-fix-prod -n keybuzz-api-prod
```

Note : les colonnes DB `escalation_*` restent en place meme apres rollback (valeurs par defaut inoffensives).

---

## Preparation PH124/PH125

Structure posee pour l'avenir (sans implementation) :

```typescript
escalation = {
  status: "none" | "recommended" | "escalated",
  reason: EscalationReason | null,
  createdAt: string | null,
  createdByType: "ai" | "human" | null,
  assignedAgentId: string | null  // via PH122
}
```

Non implemente :
- Workflow avance d'escalade
- File d'attente agent
- SLA humain specifique
- Automatisation IA d'escalade

---

## Verdict final

# PH123 ESCALATION FOUNDATION READY
