# PH-ADMIN-87.4A — Queue Inspector & Worker Monitoring — Rapport

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.20.0-ph87.4a-queue-inspector`
**Statut** : DEPLOYE DEV + PROD

---

## 1. Audit des sources

6 pipelines identifies a partir de 6 tables reelles :

| Pipeline | Table source | Lignes DEV | Champs exploites |
|---|---|---|---|
| IA Processing | `ai_action_log` | 1254 | action_type, status, blocked, blocked_reason, created_at |
| Email Outbound | `outbound_deliveries` | 202 | status (delivered/failed/pending), attempt_count, last_error, next_retry_at |
| Message Processing | `message_events` | 364 | type, conversation_id, created_at |
| Marketplace Sync | `sync_states` | 3 | status, total_expected/processed/errors, percent_complete |
| Billing Processing | `billing_events` | 61 | processed (true/false), event_type, created_at |
| IA Approval Queue | `ai_human_approval_queue` | 1 | queue_status (OPEN/IN_REVIEW/CLOSED) |

Aucune table simulee. Toutes les metriques viennent de donnees reelles.

---

## 2. Service `queue-inspector.service.ts`

3 methodes :
- `getPipelines()` — statut de chaque pipeline avec compteurs (total, success, pending, failed, retry, recent_24h, recent_1h, last_activity). Statut automatique via `determinePipelineStatus()`.
- `getRecentJobs(limit)` — jobs recents depuis 4 sources (ai_action_log, outbound_deliveries, message_events, billing_events), tries par date, normalises.
- `getBacklog()` — backlog par pipeline (pending, failed, retry).

`safeQuery()` pour resilience si table manquante (PROD vs DEV).

Logique statut pipeline :
- **healthy** : activite recente, pas d'erreur
- **warning** : pending > 10 OU failed > 0
- **error** : failed > 5 OU taux erreur > 15%
- **idle** : total > 0 mais aucune activite recente
- **unknown** : table manquante

---

## 3. Route API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/queues-inspector` | GET | Pipelines + jobs + backlog | super_admin, ops_admin |

Retourne les 3 jeux de donnees en un appel via `Promise.all`.

---

## 4. Page `/queues-inspector`

### KPI globaux (4 cartes)
- Pipelines actifs
- En attente (ambre si > 0, emeraude sinon)
- En erreur (rouge si > 0, emeraude sinon)
- En retry (bleu)

### Cartes pipelines (grille 3 colonnes)
Chaque carte affiche :
- Icone et nom du pipeline
- Badge statut colore (healthy/warning/error/idle)
- 3 compteurs : traites, en attente, erreurs
- Footer : total, activite 24h, derniere activite

Icones par pipeline :
- IA Processing = Brain
- Email Outbound = Mail
- Message Processing = MessageSquare
- Marketplace Sync = ShoppingBag
- Billing Processing = CreditCard
- IA Approval Queue = Zap

### Backlog (barre de progression)
Visible uniquement si des items sont en attente/erreur/retry. Barres colorees proportionnelles (rouge = failed, bleu = retry, ambre = pending).

### Jobs recents (tableau scrollable)
- 50 derniers jobs depuis 4 sources
- Colonnes : pipeline, statut, type, tenant, erreur, date
- Filtre par pipeline
- Badges colores par statut

---

## 5. Navigation

Entree "Queue Inspector" ajoutee dans la section "Systeme" avec icone `Gauge`.

---

## 6. Deploiement

| Env | Image | Pod | Status |
|---|---|---|---|
| DEV | v0.20.0-ph87.4a-queue-inspector | 1/1 Running | OK |
| PROD | v0.20.0-ph87.4a-queue-inspector | 1/1 Running | OK |
| Client DEV | — | — | 307 OK |
| Client PROD | — | — | 307 OK |

---

## 7. Non-regression

- `client-dev.keybuzz.io` : HTTP 307 OK
- `client.keybuzz.io` : HTTP 307 OK
- Aucune modification du backend API ni du client KeyBuzz

---

## 8. Limitations

- Pas de metriques worker individuelles (pas de table worker_status)
- Le pipeline Message Processing n'a pas de champ status/erreur — tous les events sont consideres comme traites
- `sync_states` n'a pas de colonne `last_sync_at` — utilisation de `updated_at` a la place
- Pas de graphique historique (time-series) — seuls les compteurs courants sont affiches
