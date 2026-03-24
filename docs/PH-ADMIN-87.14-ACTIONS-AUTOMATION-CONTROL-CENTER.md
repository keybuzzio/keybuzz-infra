# PH-ADMIN-87.14 — ACTIONS & AUTOMATION CONTROL CENTER

> Date : 2026-03-23
> Statut : TERMINE
> Version : v2.9.0

---

## 1. Resume executif

Le Control Center est devenu un centre d'action operationnel permettant de :
- Activer/desactiver le mode maintenance global (feature flag MAINTENANCE_MODE)
- Geler/reactiver l'IA globale (feature flags AI_CASE_AUTOMATION + AI_RECOMMENDATIONS)
- Scanner les incidents a la demande
- Creer des broadcasts d'alerte admin internes
- Executer des quick actions depuis chaque incident (cockpit, connecteurs, audit, diagnostic)
- Consulter le diagnostic assiste pour chaque type d'incident

Toutes les actions sont auditees en DB (audit_logs), securisees super_admin, avec confirmation modale obligatoire.

---

## 2. Audit des actions possibles

| Action | Backend ? | Scope | Non-destructive ? | Exploitable ? |
|---|---|---|---|---|
| Maintenance mode | OUI (feature_flag `MAINTENANCE_MODE`) | global | OUI (toggle) | OUI |
| AI freeze | OUI (flags `AI_CASE_AUTOMATION` + `AI_RECOMMENDATIONS`) | global | OUI (toggle) | OUI |
| Refresh incidents | OUI (re-query API + audit log) | global | OUI | OUI |
| Broadcast alert | OUI (table `notifications`) | global | OUI | OUI |
| Open tenant cockpit | OUI (lien) | tenant | OUI | OUI |
| Open connecteurs | OUI (lien) | tenant | OUI | OUI |
| Open audit tenant | OUI (lien) | tenant | OUI | OUI |
| Acknowledge incident | NON (pas de champ ack) | - | - | EXCLUS |
| Retry email | NON (pas d'endpoint retry) | - | - | EXCLUS |

---

## 3. Endpoints ajoutes

### GET /api/admin/global/control-state
Retourne l'etat des controles globaux (maintenance, AI freeze, derniere action, actions recentes).

### POST /api/admin/global/actions/maintenance-mode
Payload : `{ "enabled": true|false }`
Toggle le flag `MAINTENANCE_MODE`, audit log obligatoire.

### POST /api/admin/global/actions/ai-freeze
Payload : `{ "enabled": true|false }`
Toggle `AI_CASE_AUTOMATION_ENABLED` + `AI_RECOMMENDATIONS_ENABLED`, audit log.

### POST /api/admin/global/actions/refresh-incidents
Re-scanne les incidents, audit log `GLOBAL_INCIDENT_SCAN_TRIGGERED`.

### POST /api/admin/global/actions/broadcast-alert
Payload : `{ "title": "...", "message": "...", "severity": "info|warning|critical" }`
Cree notification admin, audit log `GLOBAL_BROADCAST_CREATED`.

---

## 4. UI enrichie

### Panneau Controles globaux
- Toggle maintenance mode (avec confirmation modale)
- Toggle AI freeze (avec confirmation modale)
- Bouton Scanner incidents
- Bouton Broadcast (formulaire inline)
- Badges etat : Maintenance ON/OFF, IA ACTIVE/GELEE
- Actions admin recentes (3 dernieres)

### Incidents enrichis
- Badge severite (critical/warning/info)
- Diagnostic hint derive du type d'incident
- Quick actions contextuelles (Cockpit, Connecteurs, Audit tenant)

### Diagnostic assiste
| Type incident | Cause probable | Liens |
|---|---|---|
| EMAIL_FAILED | Provider non configure/en erreur | Cockpit, Connecteurs, Audit |
| AI_INCIDENT | Erreur execution IA | IA tenant, Debug IA, Feature Flags |
| QUEUE_BACKLOG | Approbations en accumulation | Queues, Approbations |
| INCIDENT | Incident systeme ouvert | Incidents |

---

## 5. RBAC

Toutes les actions globales : **super_admin uniquement**.
- Verification backend `session.user.role !== 'super_admin'` → 403
- Liens de diagnostic visibles par role existant (non destructifs)

---

## 6. Audit log

Types ajoutes :
- `GLOBAL_MAINTENANCE_ENABLED` / `GLOBAL_MAINTENANCE_DISABLED`
- `GLOBAL_AI_FREEZE_ENABLED` / `GLOBAL_AI_FREEZE_DISABLED`
- `GLOBAL_INCIDENT_SCAN_TRIGGERED`
- `GLOBAL_BROADCAST_CREATED`

Metadata : actor, old/new value, timestamp.

### Preuve DB reelle (PROD)
```
GLOBAL_INCIDENT_SCAN_TRIGGERED — ludovic@keybuzz.pro — 2026-03-23T00:30:26Z
GLOBAL_MAINTENANCE_DISABLED — ludovic@keybuzz.pro — 2026-03-23T00:30:02Z — {previous: true, new_value: false}
GLOBAL_MAINTENANCE_ENABLED — ludovic@keybuzz.pro — 2026-03-23T00:29:33Z — {previous: false, new_value: true}
```

---

## 7. Preuve DB → API → UI → Action

### Maintenance mode
- Etat avant : OFF (feature_flags 6/11)
- Toggle ON : modale confirme → feature_flags 7/11, timeline `GLOBAL_MAINTENANCE_ENABLED`
- Toggle OFF : modale confirme → feature_flags 6/11, timeline `GLOBAL_MAINTENANCE_DISABLED`
- Audit log cree en DB : confirme

### Refresh incidents
- Clic Scanner → timeline `GLOBAL_INCIDENT_SCAN_TRIGGERED`
- Incidents re-affiches (1 EMAIL_FAILED confirme)

### Quick action incident
- Clic Cockpit sur incident EMAIL_FAILED → navigation `/tenants/ecomlg-001`
- Cockpit affiche avec donnees reelles du tenant

---

## 8. Deploiement

| Champ | Valeur |
|---|---|
| Commit SHA source | `fefa48ac1bbd6ad6aad360474503525884ca8711` |
| Tag DEV | `v2.9.0-ph-admin-87-14-dev` |
| Digest DEV | `sha256:2ca7e15ff3e266efe019d4f3b9bbdc6f2ee43160cb1f03591e2c371fce28fe08` |
| Tag PROD | `v2.9.0-ph-admin-87-14-prod` |
| Digest PROD | `sha256:2ca7e15ff3e266efe019d4f3b9bbdc6f2ee43160cb1f03591e2c371fce28fe08` |
| Version runtime | v2.9.0 |
| Pod image | `ghcr.io/keybuzzio/keybuzz-admin:v2.9.0-ph-admin-87-14-prod` |

---

## 9. Rollback

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.8.0-ph-admin-87-13-prod -n keybuzz-admin-v2-prod
```

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.8.0-ph-admin-87-13-dev -n keybuzz-admin-v2-dev
```

---

## 10. Dettes restantes

| ID | Description |
|---|---|
| D1 | Acknowledge incident : necessite ajout colonne `acknowledged_at` dans table incidents |
| D2 | Retry email : necessite endpoint de retry dans le service outbound |
| D3 | AI freeze devrait aussi affecter AI_AUTOPILOT_ENABLED (actuellement deja false) |
| D4 | Broadcast notifications : pas encore de systeme de consultation cote UI admin |
| D5 | Les actions globales ne declenchent pas encore de websocket/SSE pour refresh temps reel multi-onglets |
