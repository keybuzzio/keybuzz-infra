# PH-ADMIN-87.3A — Incident Management — Rapport

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.19.0-ph87.3a-incidents`
**Statut** : DEPLOYE DEV + PROD

---

## 1. Tables creees

### `incidents`
| Colonne | Type | Description |
|---|---|---|
| `id` | UUID | Cle primaire |
| `created_at` | TIMESTAMPTZ | Date creation |
| `updated_at` | TIMESTAMPTZ | Derniere modification |
| `title` | TEXT | Titre de l'incident |
| `description` | TEXT | Description detaillee |
| `status` | TEXT | OPEN, INVESTIGATING, MITIGATED, RESOLVED, CLOSED |
| `severity` | TEXT | LOW, MEDIUM, HIGH, CRITICAL |
| `created_by` | TEXT | Email admin createur |
| `resolved_at` | TIMESTAMPTZ | Date resolution |
| `metadata` | JSONB | Donnees additionnelles |

Index : status, severity, created_at DESC

### `incident_events` (timeline)
| Colonne | Type | Description |
|---|---|---|
| `id` | UUID | Cle primaire |
| `incident_id` | UUID | FK → incidents(id) CASCADE |
| `created_at` | TIMESTAMPTZ | Date evenement |
| `actor_user_id` | TEXT | Admin ayant agi |
| `event_type` | TEXT | Type d'evenement |
| `description` | TEXT | Description lisible |
| `metadata` | JSONB | Donnees additionnelles |

Index : incident_id, created_at DESC

### `incident_tenants`
| Colonne | Type | Description |
|---|---|---|
| `incident_id` | UUID | FK → incidents(id) CASCADE |
| `tenant_id` | TEXT | Identifiant tenant |

PK composite (incident_id, tenant_id). Index sur tenant_id.

---

## 2. Service `incident.service.ts`

8 methodes :
- `list(filters?)` — liste triee (ouverts d'abord) avec sous-requete tenant_count
- `getById(id)` — detail + tenants lies
- `create(data)` — creation + event INCIDENT_CREATED + ajout tenants
- `update(id, data, actor)` — mise a jour statut/severite/description + events automatiques
- `getEvents(incidentId)` — timeline chronologique
- `addEvent(incidentId, data)` — ajout evenement timeline
- `addTenant/removeTenant` — gestion tenants impactes + events automatiques
- `getStats()` — compteurs par statut + critiques actifs

7 types d'evenements : INCIDENT_CREATED, STATUS_CHANGED, SEVERITY_CHANGED, TENANT_ADDED, TENANT_REMOVED, NOTE_ADDED, INCIDENT_RESOLVED

---

## 3. API routes

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/incidents` | GET | Liste + stats, filtres status/severity | super_admin, ops_admin |
| `/api/admin/incidents` | POST | Creation incident | super_admin |
| `/api/admin/incidents/[id]` | GET | Detail + events | super_admin, ops_admin |
| `/api/admin/incidents/[id]` | PATCH | Update statut/severite/description | super_admin, ops_admin |
| `/api/admin/incidents/[id]/events` | POST | Ajout note timeline | super_admin, ops_admin |
| `/api/admin/incidents/[id]/tenants` | POST | Ajout tenant impacte | super_admin, ops_admin |
| `/api/admin/incidents/[id]/tenants` | DELETE | Retrait tenant | super_admin, ops_admin |

---

## 4. Page `/incidents`

- **5 KPI** : Total, Ouverts, En investigation, Mitiges, Critiques actifs
- **Formulaire creation** : titre, severite, description, tenants impactes (virgules)
- **Filtres** : statut, severite
- **Tableau** : titre, badges statut/severite, date, createur, nombre tenants, lien detail
- **Etat vide** : icone + message "Aucun incident en cours"

## 5. Page `/incidents/[id]`

Layout desktop-first 2 colonnes :

### Colonne principale
- **Header** : titre, badges statut/severite, dates, createur
- **Description** : texte pre-formate
- **Timeline** : evenements chronologiques avec icones colorees par type, acteur, date
- **Ajout note** : champ texte + bouton envoi (Enter ou clic)

### Sidebar
- **Statuts** : workflow lineaire OPEN → INVESTIGATING → MITIGATED → RESOLVED → CLOSED avec confirmation modale
- **Tenants impactes** : liste avec liens `/tenants/[id]`, boutons ajout/suppression
- **Informations** : ID, createur, dates, nombre d'evenements

---

## 6. Navigation

Entree "Incidents" ajoutee dans la section "Operations" avec icone `Siren`.

---

## 7. Deploiement

| Env | Image | Pod | Status |
|---|---|---|---|
| DEV | v0.19.0-ph87.3a-incidents | 1/1 Running | OK |
| PROD | v0.19.0-ph87.3a-incidents | 1/1 Running | OK |
| Client DEV | — | — | 307 OK |
| Client PROD | — | — | 307 OK |

---

## 8. Non-regression

- `client-dev.keybuzz.io` : HTTP 307 OK
- `client.keybuzz.io` : HTTP 307 OK
- Aucune modification du backend API ni du client KeyBuzz

---

## 9. Limitations

- Pas de creation automatique d'incident depuis les alertes (integration future)
- Pas d'envoi de notification lors de la creation d'incident (integration possible via notification.service)
- Pas de lien bidirectionnel incident → cas ops (incident_id non present dans ai_human_approval_queue)
