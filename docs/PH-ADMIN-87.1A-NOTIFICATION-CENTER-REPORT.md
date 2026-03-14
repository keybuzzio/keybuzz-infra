# PH-ADMIN-87.1A — Notification Center & Alerts Inbox

## Statut : TERMINEE

## Date : 2026-03-14

## Image Docker
`ghcr.io/keybuzzio/keybuzz-admin-v2:v0.17.0-ph87.1a-notifications`

---

## 1. Table admin_notifications

Creee en DEV et PROD avec :
- 14 colonnes : id (UUID), created_at, type, severity, source, title, description, tenant_id, resource_id, read, metadata (JSONB), fingerprint
- 5 index : created_at DESC, read, type, severity, fingerprint (unique partiel)
- Deduplication via fingerprint (unique constraint WHERE NOT NULL)

## 2. Sources d'alertes (6 sources reelles)

| Source | Type | Description |
|---|---|---|
| Email sortant | SYSTEM_HEALTH_ALERT | Taux d'echec outbound_deliveries > 5% (warning) ou > 15% (critical) |
| Connecteurs | CONNECTOR_ERROR | Canaux deconnectes dans tenant_channels (7 derniers jours) |
| Billing - souscription | BILLING_ALERT | Tenant avec plan non-free sans souscription active |
| Billing - usage | BILLING_ALERT | KBActions restants < 10% du quota inclus |
| IA - cas critiques | AI_ANOMALY | >= 5 cas critiques ouverts dans les 24h |
| IA - saturation | AI_ANOMALY | >= 20 cas ouverts en file d'approbation |

Toutes les sources interrogent des tables reelles existantes.
Aucune alerte n'est inventee.

## 3. Deduplication

Chaque notification generee porte un `fingerprint` unique par source + date.
Format : `{source}-{context}-{YYYY-MM-DD}`
La contrainte UNIQUE sur fingerprint empeche les doublons.
Plusieurs scans le meme jour ne creent pas de doublons.

## 4. Service notification.service.ts

7 methodes :
- `list(filters)` — liste paginee avec filtres (type, severity, tenant, read)
- `getUnreadCount()` — compteur non-lues (utilise par la Topbar)
- `markAsRead(id)` — marquer une notification comme lue
- `markAllAsRead()` — marquer toutes comme lues
- `create(notif)` — creation avec deduplication fingerprint
- `generateFromSources()` — scan des 6 sources et creation d'alertes
- `safeQuery()` — resilience si table manquante

## 5. Routes API

| Route | Methode | Description |
|---|---|---|
| `/api/admin/notifications` | GET | Liste avec filtres (type, severity, tenant_id, read) |
| `/api/admin/notifications/unread-count` | GET | Compteur non-lues |
| `/api/admin/notifications/[id]/read` | PATCH | Marquer une notification comme lue |
| `/api/admin/notifications/mark-all-read` | POST | Marquer toutes comme lues |
| `/api/admin/notifications/generate` | POST | Scanner les sources et generer des alertes |

RBAC : toutes les routes necessitent une session authentifiee.

## 6. Page /notifications

5 sections :
1. **KPI** — 4 StatCards (Total, Non lues, Critiques, Avertissements)
2. **Filtres** — Type, Severite, Statut lecture
3. **Bouton Scanner** — Declenche generateFromSources() manuellement
4. **Bouton Tout marquer lu** — Apparait si notifications non lues
5. **Liste alertes** — Chaque alerte affiche :
   - Icone par type (HeartPulse, Plug, CreditCard, Zap, Shield)
   - Couleur par severite (rouge/ambre/bleu)
   - Titre + description
   - Badges type + severite
   - Tenant ID si applicable
   - Date formatee
   - Bouton "Marquer lu"
   - Indicateur bleu si non lue

## 7. Badge Topbar

- Icone Bell dans la Topbar avec lien vers /notifications
- Compteur non-lues (badge rouge, max 99+)
- Polling automatique toutes les 60 secondes
- Disparait si aucune notification non lue

## 8. Navigation

Entree "Notifications" ajoutee dans la sidebar (section Supervision, icone Bell).

## 9. Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | v0.17.0-ph87.1a-notifications | 1/1 Running | OK |
| PROD | v0.17.0-ph87.1a-notifications | 1/1 Running | OK |

## 10. Non-regression client

- `client-dev.keybuzz.io` : 307 OK
- `client.keybuzz.io` : 307 OK

## 11. Limitations

- Pas de notifications push (WebSocket) — polling 60s
- Pas de notifications email vers les admins
- Scan manuel uniquement (pas de cron automatique)
- Pas de notification SECURITY_EVENT generee automatiquement (reserved pour integration future avec audit_logs)
