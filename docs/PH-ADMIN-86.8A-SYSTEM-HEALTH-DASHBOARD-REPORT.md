# PH-ADMIN-86.8A — System Health & Infrastructure Dashboard — Report

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.14.0-ph86.8a-system-health`
**Statut** : DEV + PROD deployes

---

## 1. Audit des sources de donnees

### Tables exploitees

| Table | Lignes | Usage sante systeme |
|---|---|---|
| `ai_action_log` | 1253 | Moteur IA : volume, activite, blocages |
| `outbound_deliveries` | 202 | Email sortant : taux livraison/echec |
| `message_events` | 364 | Traitement messages : volume, derniere activite |
| `sync_states` | 3 | Sync marketplace : statut, progression, erreurs |
| `inbound_connections` | 1 | Pipeline inbound email : statut connexion |
| `inbound_addresses` | 1 | Adresses inbound : validation, derniere reception |
| `ai_execution_audit` | 5 | Audit decisions IA |
| `billing_events` | 61 | Billing Stripe : traitement, erreurs |
| `tenant_channels` | 6 | Canaux tenant : actifs/retires |
| `ai_human_approval_queue` | existant | File approbation IA : pending/resolved |

### Donnees NON disponibles
- Pods Kubernetes (pas d'appel k8s depuis l'UI)
- CPU/RAM/reseau (pas de metriques Prometheus exposees)
- Logs applicatifs en temps reel
- Healthcheck HTTP externe des services

---

## 2. Architecture service

**Fichier** : `src/features/system-health/system-health.service.ts`

| Methode | Description |
|---|---|
| `getComponentsHealth()` | Evalue 7 composants avec statut healthy/warning/degraded/unknown |
| `getOverview(components)` | Agregation globale des statuts |
| `getQueuesHealth()` | 3 files de traitement avec pending/failed/processed |
| `getRecentErrors(limit)` | Erreurs recentes depuis 3 sources (email, billing, IA) |

### 7 composants surveilles

| Composant | Source | Logique statut |
|---|---|---|
| Moteur IA | `ai_action_log` | healthy si activite 7j, warning sinon |
| Email sortant | `outbound_deliveries` | degraded si >20% echec, warning >5%, healthy sinon |
| Email entrant | `inbound_connections` + `inbound_addresses` | healthy si READY, warning sinon |
| Sync marketplace | `sync_states` | warning si erreurs, healthy sinon |
| Billing / Stripe | `billing_events` | warning si erreurs, healthy sinon |
| Traitement messages | `message_events` | healthy si donnees, unknown sinon |
| Canaux tenant | `tenant_channels` | healthy si canaux actifs, warning sinon |

### 3 files de traitement

| File | Source |
|---|---|
| File approbation IA | `ai_human_approval_queue` |
| File envoi email | `outbound_deliveries` |
| File billing Stripe | `billing_events` |

### Sources d'erreurs

| Source | Table | Condition |
|---|---|---|
| Email sortant | `outbound_deliveries` | `status = 'failed'` |
| Billing | `billing_events` | `error_message IS NOT NULL` |
| IA bloquee | `ai_action_log` | `blocked = true` |

---

## 3. Route API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/system-health` | GET | Overview + composants + files + erreurs | super_admin, ops_admin |

### Structure reponse

```json
{
  "data": {
    "overview": { "totalComponents": 7, "healthy": 5, "warning": 1, "degraded": 0, "unknown": 1 },
    "components": [{ "name": "...", "slug": "...", "status": "...", "lastActivity": "...", "details": {} }],
    "queues": [{ "name": "...", "pending": 0, "failed": 17, "processed": 185, "lastActivity": "..." }],
    "errors": [{ "source": "...", "message": "...", "tenant_id": "...", "created_at": "..." }]
  }
}
```

---

## 4. Architecture UI

### Page : `/system-health`

Layout 4 sections :
1. **System Status** — 4 cartes colorees (Sain/Attention/Degrade/Inconnu) + derniere verification
2. **Composants** — Tableau expandable avec statut, derniere activite, details au clic
3. **Files de traitement** — 3 cartes avec pending/failed/processed + barres de progression
4. **Erreurs recentes** — Tableau des dernieres erreurs systeme avec source, message, tenant, date

### 4 composants crees

| Composant | Fichier | Role |
|---|---|---|
| `SystemStatusCards` | `components/SystemStatusCards.tsx` | 4 cartes resume statut global |
| `ComponentHealthTable` | `components/ComponentHealthTable.tsx` | Tableau expandable des composants |
| `QueueHealthPanel` | `components/QueueHealthPanel.tsx` | 3 cartes files de traitement |
| `SystemErrorList` | `components/SystemErrorList.tsx` | Liste erreurs recentes |

### Fonctionnalites
- Indicateur global en header (Systeme operationnel / Attention requise / Systeme degrade)
- Bouton Actualiser avec animation
- Expansion detail composant au clic
- Barres de progression sur les files
- Etat vide gere (Aucune erreur systeme recente)
- Labels lisibles en francais

### Navigation
- Entree "Sante systeme" ajoutee dans la sidebar (section Systeme, icone HeartPulse)

---

## 5. RBAC

| Role | Acces |
|---|---|
| super_admin | Complet |
| ops_admin | Complet |
| account_manager | Bloque (403) |
| support_agent | Bloque (403) |
| viewer | Bloque (403) |

---

## 6. Non-regression client

| Service | Code | Statut |
|---|---|---|
| `client-dev.keybuzz.io` | 307 | OK |
| `client.keybuzz.io` | 307 | OK |

---

## 7. Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `v0.14.0-ph86.8a-system-health` | 1/1 Running | OK |
| PROD | `v0.14.0-ph86.8a-system-health` | 1/1 Running | OK |

---

## 8. Limitations

| Limitation | Raison |
|---|---|
| Pas de monitoring pods K8s | Pas d'appel kubectl/k8s API depuis l'UI |
| Pas de metriques CPU/RAM | Pas de Prometheus/Grafana expose |
| Pas de healthcheck HTTP externe | Pas d'endpoint health backend expose |
| Pas d'alerting temps reel | Pas de websocket/SSE |
| Pas d'historique sante | Snapshots ponctuels, pas de serie temporelle |

---

## 9. Fichiers crees / modifies

### Crees
- `src/features/system-health/system-health.service.ts` — Service 7 composants + 3 files + erreurs
- `src/app/api/admin/system-health/route.ts` — API GET
- `src/features/system-health/components/SystemStatusCards.tsx` — Cartes statut
- `src/features/system-health/components/ComponentHealthTable.tsx` — Tableau composants
- `src/features/system-health/components/QueueHealthPanel.tsx` — Files de traitement
- `src/features/system-health/components/SystemErrorList.tsx` — Erreurs recentes
- `src/app/(admin)/system-health/page.tsx` — Page principale

### Modifies
- `src/config/navigation.ts` — Ajout entree "Sante systeme"
- `src/components/layout/Sidebar.tsx` — Ajout icone HeartPulse
