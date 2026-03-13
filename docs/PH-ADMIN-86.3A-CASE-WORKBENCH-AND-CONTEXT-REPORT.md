# PH-ADMIN-86.3A — Case Workbench & Context

## Objectif

Transformer `/cases/[id]` en workbench operationnel avec contexte riche, timeline, panneaux structures et feedback agent-friendly.

## Audit des champs backend reellement disponibles

### Disponible et utilise

| Source | Endpoint | Champs utilises | Statut |
|---|---|---|---|
| Case detail | `GET /ai/human-approval-queue/:id` | id, tenant_id, conversation_id, order_ref, queue_type, queue_status, priority, recommended_action, recommended_owner, reason, risk_summary, decision_context, created_at, updated_at | **200 STABLE** |
| Tenant info | `GET /tenants/:id` | id, name, domain, plan, status, created_at, updated_at | **200 STABLE** |

### Non disponible (correctement indique dans l'UI)

| Donnee | Endpoint teste | Resultat |
|---|---|---|
| Messages conversation | `GET /conversations/:id` | **404** — route inexistante |
| AI actions log | `GET /ai/actions-log?conversationId=x` | **404** — route inexistante |
| AI executions | `GET /ai/executions?conversationId=x` | **404** — route inexistante |
| AI decision journal | Table `ai_decision_journal` | **Table inexistante** |
| Commande / livraison detail | Aucun endpoint identifie | Non disponible |

**Aucune donnee inventee.** Les panneaux non disponibles affichent un message explicite.

## Architecture UI du workbench

### Layout desktop-first 2 colonnes

```
┌──────────────────────────────────────────────┐
│ CaseHeader (breadcrumb, badges, refresh)     │
├────────────────────────────┬─────────────────┤
│ CaseSummary (alerte)       │ CaseActionPanel │
│ ContextSection (cas)       │ (assign, resolve│
│ ContextSection (tenant)    │  snooze, status)│
│ ContextSection (convo)     │ CaseMetaPanel   │
│ ContextSection (commande)  │ (technique,     │
│ CaseTimeline               │  repliable)     │
└────────────────────────────┴─────────────────┘
```

### Composants crees

| Composant | Fichier | Description |
|---|---|---|
| `CaseHeader` | `src/features/ops/components/CaseHeader.tsx` | Breadcrumb, titre, badges statut/priorite/type, assignation, refresh |
| `CaseSummary` | `src/features/ops/components/CaseSummary.tsx` | Alerte coloree (severite), resume raison + action recommandee + risque |
| `CaseTimeline` | `src/features/ops/components/CaseTimeline.tsx` | Timeline verticale avec icones (created, assigned, snoozed, resolved) |
| `CaseActionPanel` | `src/features/ops/components/CaseActionPanel.tsx` | Actions assign/resolve/snooze/status avec RBAC, extraites en composant |
| `CaseMetaPanel` | `src/features/ops/components/CaseMetaPanel.tsx` | Panneau technique repliable (IDs, timestamps, risk, decision_context) |
| `ContextSection` | `src/features/ops/components/ContextSection.tsx` | Composant generique de contexte (titre, icone, champs, message indisponible) |

### Panneaux de contexte

| Panneau | Donnees affichees | Source |
|---|---|---|
| **Resume du cas** | Raison lisible, action recommandee, risques, report | `CaseDetail` |
| **Contexte du cas** | Type, raison, action, assignation, dates, ref commande | `CaseDetail` |
| **Contexte tenant** | Nom, ID, plan (badge), statut (badge), domaine, inscription | `GET /tenants/:id` |
| **Contexte conversation** | ID conversation + message "non disponible" | `CaseDetail.conversation_id` |
| **Commande / Livraison** | Ref commande + categorie valeur ou "non disponible" | `CaseDetail.order_ref` + `risk_summary` |
| **Chronologie** | Evenements ordonnes (creation, assignation, report, resolution) | Reconstruit depuis `CaseDetail` |
| **Donnees techniques** | IDs, timestamps precis, risk_summary, decision_context | `CaseDetail` (repliable) |

### Timeline

La timeline est reconstruite a partir des champs reels du cas :
- `created_at` → evenement "Cas cree"
- `recommended_owner` → evenement "Assigne"
- `decision_context.snoozedUntil` → evenement "Reporte"
- `queue_status` terminal (CLOSED/APPROVED/REJECTED) → evenement "Ferme/Approuve/Rejete"
- `queue_status` non-terminal (IN_REVIEW) → evenement "Statut change"

Aucun evenement invente. Chaque point correspond a un champ reel.

## Fichiers crees

- `src/features/ops/components/CaseHeader.tsx`
- `src/features/ops/components/CaseSummary.tsx`
- `src/features/ops/components/CaseTimeline.tsx`
- `src/features/ops/components/CaseActionPanel.tsx`
- `src/features/ops/components/CaseMetaPanel.tsx`
- `src/features/ops/components/ContextSection.tsx`

## Fichiers modifies

- `src/app/(admin)/cases/[id]/page.tsx` — restructure en workbench multi-panneaux
- `src/features/ops/types.ts` — ajout TenantInfo + TimelineEvent
- `src/features/ops/services/ops.service.ts` — ajout getTenantInfo
- `src/config/endpoints.ts` — ajout tenants.detail

## Actions ops existantes (verification)

Toutes les actions PH86.2B restent fonctionnelles :

| Action | Statut |
|---|---|
| Assign | ✅ Fonctionne (ConfirmDialog + toast + refetch) |
| Resolve | ✅ Fonctionne |
| Snooze | ✅ Fonctionne (selection duree) |
| Update status | ✅ Fonctionne (select + apply) |
| RBAC | ✅ Boutons desactives si role insuffisant |
| Protection double-clic | ✅ Bouton disabled pendant mutation |

## Non-regression

| URL | HTTP | Impact |
|---|---|---|
| admin-dev.keybuzz.io | **307** | ✅ Aucun impact |
| admin.keybuzz.io | **307** | ✅ Aucun impact |
| client-dev.keybuzz.io | **307** | ✅ Aucun impact |
| client.keybuzz.io | **307** | ✅ Aucun impact |
| /queues | **307** | ✅ Navigation vers /cases/[id] toujours OK |
| /approvals | **307** | ✅ Navigation vers /cases/[id] toujours OK |

## Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.8.0-ph86.3a-case-workbench-dev` | Running 1/1 | ✅ |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.8.0-ph86.3a-case-workbench-prod` | Running 1/1 | ✅ |

## Limites documentees

1. **Conversation** : pas d'endpoint `/conversations/:id` cote backend ops. L'UI affiche l'ID et un message explicite.
2. **Commande/Livraison** : pas d'endpoint dedie. L'UI affiche `order_ref` si present et `orderValueCategory` du risk_summary.
3. **AI Journal** : table `ai_decision_journal` n'existe pas, `ai_actions_ledger` est vide pour ce cas. Pas de timeline IA disponible.
4. **Timeline** : reconstruite a partir des champs existants, pas d'audit trail dedie dans le backend.

## Criteres de validation

| Critere | Statut |
|---|---|
| /cases/[id] est un vrai workbench lisible | ✅ |
| Contextes reellement disponibles bien affiches | ✅ |
| Aucune donnee inventee | ✅ |
| Timeline utile | ✅ |
| Actions ops restent fonctionnelles | ✅ |
| Aucune regression client | ✅ |

## Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.7.0-ph86.2b-ops-actions-dev \
  -n keybuzz-admin-v2-dev

# PROD
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.7.0-ph86.2b-ops-actions-prod \
  -n keybuzz-admin-v2-prod
```
