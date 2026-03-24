# PH-ADMIN-87.12D — Incidents, Feature Flags, System Health

**Date** : 2026-03-04
**Version** : v2.7.3
**Statut** : TERMINE

---

## 1. Resume executif

Ajout des 3 briques de supervision manquantes dans l'admin KeyBuzz :
- **Incidents** : incidents actifs, incidents IA, erreurs de livraison par tenant
- **Feature Flags** : drapeaux globaux, actifs/inactifs, overrides tenant
- **System Health** : score de sante, conversations, livraisons, queues, sync, IA, billing

Les 3 modules sont tenant-aware, alimentes par la DB reelle, avec empty states honnetes.

---

## 2. Audit DB

| Table | Rows | tenant_id | Utilisation |
|---|---|---|---|
| `incidents` | 0 | NON | Incidents globaux |
| `incident_events` | 0 | NON | Evenements incidents |
| `incident_tenants` | 0 | OUI | Lien incident-tenant |
| `ai_execution_incidents` | 0 | OUI | Incidents execution IA |
| `feature_flags` | 11 | OUI (null=global) | Drapeaux fonctionnels |
| `outbound_deliveries` | 65 | OUI | 64 delivered, 1 failed |
| `ai_action_log` | 48 | OUI | Actions IA (ecomlg) |
| `ai_execution_audit` | 7 | OUI | Audit execution IA |
| `conversations` | 270 | OUI | 136 open, 11 pending, 123 resolved |
| `ai_human_approval_queue` | 2 | OUI | Queue approbation |
| `ai_followup_cases` | 0 | OUI | Cas followup |
| `sync_states` | 2 | OUI | Etat sync connecteurs |
| `billing_events` | 65 | OUI | Evenements Stripe |

---

## 3. Fichiers crees/modifies

### API Routes (Next.js App Router)
| Fichier | Role |
|---|---|
| `src/app/api/admin/tenants/[id]/incidents/route.ts` | GET incidents tenant |
| `src/app/api/admin/tenants/[id]/feature-flags/route.ts` | GET feature flags tenant |
| `src/app/api/admin/tenants/[id]/health/route.ts` | GET health tenant |

### Pages UI
| Fichier | Role |
|---|---|
| `src/app/(admin)/incidents/page.tsx` | Page incidents (3 sections + stat cards) |
| `src/app/(admin)/feature-flags/page.tsx` | Page flags (actifs/inactifs/overrides) |
| `src/app/(admin)/system-health/page.tsx` | Page health (score + 6 blocs) |

### Service
| Fichier | Methodes ajoutees |
|---|---|
| `src/features/users/services/users.service.ts` | `getTenantIncidents()`, `getTenantFeatureFlags()`, `getTenantHealth()` |
| `src/features/users/types.ts` | `TenantIncidentsData`, `TenantFeatureFlagsData`, `TenantHealthData`, etc. |

### Navigation
| Fichier | Modification |
|---|---|
| `src/config/navigation.ts` | Ajout groupe "Surveillance" (Incidents, Feature Flags, System Health) |
| `src/app/(admin)/tenants/[id]/page.tsx` | 3 quicklinks ajoutes dans le cockpit |

---

## 4. Validation PROD

### Tenant riche (ecomlg-001)

| Page | StatCards | Sections | Donnees |
|---|---|---|---|
| `/incidents?tenantId=ecomlg-001` | 0 actifs, 0 recents, 0 IA, **1 erreur livraison** | 3 sections | Reelle (1 failed delivery: "Unknown provider: SMTP") |
| `/feature-flags?tenantId=ecomlg-001` | **11** globaux, **6** actifs, **5** inactifs, 0 overrides | 2 sections | Reelle (11 flags DB) |
| `/system-health?tenantId=ecomlg-001` | **80%** sante, **136** conv ouvertes, **1** echec, **2** approbations | 6 blocs | Reelle |

### Tenant vide (switaa-sasu-mmazd2rd)

| Page | StatCards | Comportement |
|---|---|---|
| `/incidents?tenantId=switaa-...` | Tout a 0 | Empty states honnetes |
| `/system-health?tenantId=switaa-...` | **100%** sante, tout a 0 | Empty states honnetes |

### Navigation sidebar

| Route | Item actif |
|---|---|
| `/incidents` | Incidents (groupe Surveillance) |
| `/feature-flags` | Feature Flags (groupe Surveillance) |
| `/system-health` | System Health (groupe Surveillance) |

---

## 5. Feature Flags reels (PROD)

| Flag | Etat | Description |
|---|---|---|
| `AI_AUTOPILOT_ENABLED` | Inactif | Mode autopilot IA |
| `AI_CASE_AUTOMATION_ENABLED` | **Actif** | Creation auto cas IA |
| `AI_RECOMMENDATIONS_ENABLED` | **Actif** | Recommandations IA |
| `BILLING_ENFORCEMENT_ENABLED` | Inactif | Controle facturation |
| `CONNECTOR_AMAZON_ENABLED` | **Actif** | Connecteur Amazon SP-API |
| `CONNECTOR_OCTOPIA_ENABLED` | **Actif** | Connecteur Octopia/Cdiscount |
| `EMAIL_INBOUND_ENABLED` | **Actif** | Emails entrants |
| `EMAIL_OUTBOUND_ENABLED` | **Actif** | Emails sortants |
| `EXPERIMENTAL_WORKFLOWS_ENABLED` | Inactif | Workflows experimentaux |
| `MAINTENANCE_MODE` | Inactif | Mode maintenance |
| `PLAYBOOK_ENGINE_ENABLED` | Inactif | Moteur playbooks IA |

---

## 6. Health Score (algorithme)

```
score = 100
si deliveries.failed > 0 → -20
si queues.approval_pending > 5 → -15
si sync.total_errors > 0 → -15
si conversations.pending > 20 → -10
score = max(0, score)
```

- >= 80% → Bon (vert)
- >= 50% → Attention (ambre)
- < 50% → Critique (rouge)

---

## 7. Deploiement

| Element | Valeur |
|---|---|
| Commit 1 | `b3477b5` — modules + cockpit + nav |
| Commit 2 | `9dabcf4` — fix useSearchParams |
| Tag DEV | `v2.7.3-ph-admin-87-12d-dev` |
| Tag PROD | `v2.7.3-ph-admin-87-12d-prod` |
| Digest DEV | `sha256:960278b23ffa5cf01c260b69ac82efb04dde2738ab9a5037205c403135539eea` |
| Digest PROD | `sha256:5d5c67478a663c2576867d56f703d183f609ca39c3df1f9c992a3f47693c9fe0` |
| Version runtime | v2.7.3 |

---

## 8. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.2-ph-admin-87-12c-dev \
  -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.2-ph-admin-87-12c-prod \
  -n keybuzz-admin-v2-prod
```

---

## 9. Cockpit quicklinks ajoutes

Le cockpit tenant (`/tenants/[id]`) inclut maintenant 3 liens rapides supplementaires :
- **Incidents du tenant** → `/incidents?tenantId=<id>`
- **Feature Flags** → `/feature-flags?tenantId=<id>`
- **System Health** → `/system-health?tenantId=<id>`

---

## 10. Zero violations

- Zero fake data : toutes les donnees viennent de PostgreSQL
- Zero severity inventee : les incidents sont des tables DB reelles (vides = empty state)
- Zero hardcode : queries parametrees par `tenantId`
- Zero Failed to fetch : toutes les APIs fonctionnent
- Zero faux actif sidebar : navigation correcte
