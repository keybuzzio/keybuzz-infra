# PH-ADMIN-87.2A — Feature Flags & Runtime Controls — Rapport

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.18.0-ph87.2a-feature-flags`
**Statut** : DEPLOYE DEV + PROD

---

## 1. Table `feature_flags`

Creee en DEV et PROD via `kubectl exec` + script Node.js.

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID | Cle primaire |
| `key` | TEXT | Identifiant unique du flag |
| `description` | TEXT | Description lisible |
| `enabled` | BOOLEAN | Etat du flag |
| `scope` | TEXT | `global` ou `tenant` |
| `tenant_id` | TEXT | Tenant cible (NULL si global) |
| `created_at` | TIMESTAMPTZ | Date creation |
| `updated_at` | TIMESTAMPTZ | Derniere modification |
| `created_by` | TEXT | Email admin createur |
| `metadata` | JSONB | Options supplementaires |

**Index** :
- `idx_ff_key_scope` : UNIQUE sur (key, scope, COALESCE(tenant_id, '__global__'))
- `idx_ff_key` : index sur key
- `idx_ff_tenant` : index partiel sur tenant_id (WHERE NOT NULL)

---

## 2. Registre central des flags

11 flags initiaux seedees :

| Flag | Label | Categorie | Sensible | Etat initial |
|---|---|---|---|---|
| `AI_AUTOPILOT_ENABLED` | Mode Autopilot IA | IA | Oui | Desactive |
| `AI_RECOMMENDATIONS_ENABLED` | Recommandations IA | IA | Non | Active |
| `AI_CASE_AUTOMATION_ENABLED` | Automation cas IA | IA | Non | Active |
| `CONNECTOR_AMAZON_ENABLED` | Connecteur Amazon | Connecteurs | Non | Active |
| `CONNECTOR_OCTOPIA_ENABLED` | Connecteur Octopia | Connecteurs | Non | Active |
| `EMAIL_OUTBOUND_ENABLED` | Email sortant | Email | Non | Active |
| `EMAIL_INBOUND_ENABLED` | Email entrant | Email | Non | Active |
| `BILLING_ENFORCEMENT_ENABLED` | Controle facturation | Billing | Oui | Desactive |
| `EXPERIMENTAL_WORKFLOWS_ENABLED` | Workflows experimentaux | Experimental | Oui | Desactive |
| `PLAYBOOK_ENGINE_ENABLED` | Moteur Playbooks | IA | Non | Desactive |
| `MAINTENANCE_MODE` | Mode maintenance | Systeme | Oui | Desactive |

Les flags sensibles (Autopilot, Billing Enforcement, Experimental, Maintenance) sont desactives par defaut et necessitent une confirmation explicite pour activation.

---

## 3. Architecture service

### `feature-flags.service.ts`
- `getAllFlags()` : liste complete triee (global d'abord, puis tenant)
- `getFlag(key, tenantId?)` : resolution avec priorite tenant > global
- `isEnabled(key, tenantId?)` : helper boolean pour integration runtime
- `setFlag(key, enabled, updatedBy?)` : toggle global
- `setTenantFlag(tenantId, key, enabled, updatedBy?)` : override tenant (upsert)
- `removeTenantOverride(tenantId, key)` : suppression override
- `getTenantOverrides(tenantId)` : liste overrides d'un tenant

### `flag-registry.ts`
Registre client-safe (sans import `pg`) pour les labels, categories et indicateurs de sensibilite.

---

## 4. API routes

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/feature-flags` | GET | Liste tous les flags | super_admin |
| `/api/admin/feature-flags/[key]` | PATCH | Toggle un flag global | super_admin |
| `/api/admin/feature-flags/tenant` | POST | Creer/modifier override tenant | super_admin |
| `/api/admin/feature-flags/tenant` | DELETE | Supprimer override tenant | super_admin |

---

## 5. Page `/feature-flags`

### KPI (4 cartes)
- Total flags
- Actifs (emeraude)
- Desactives
- Overrides tenant (bleu)

### Flags par categorie
- Groupes : IA, Connecteurs, Email, Billing, Experimental, Systeme
- Chaque flag affiche : label, description, badge sensible, toggle, badge overrides
- Expandable : dates, auteur, overrides tenant existants
- Formulaire inline pour creer un override tenant
- Suppression d'overrides existants

### Confirmation sensible
Modal ambre avant activation de flags marques comme sensibles.

---

## 6. Integration runtime

Le helper `isFeatureEnabled(key, tenantId?)` permet aux modules backend de verifier dynamiquement si un flag est actif :
1. Verifie d'abord l'override tenant
2. Sinon verifie le flag global
3. Retourne `false` par defaut si le flag n'existe pas

---

## 7. Navigation

Entree "Feature Flags" ajoutee dans la section "Systeme" du sidebar avec icone `ToggleRight`.

---

## 8. Deploiement

| Env | Image | Pod | Status |
|---|---|---|---|
| DEV | v0.18.0-ph87.2a-feature-flags | 1/1 Running | OK |
| PROD | v0.18.0-ph87.2a-feature-flags | 1/1 Running | OK |
| Client DEV | — | — | 307 OK |
| Client PROD | — | — | 307 OK |

---

## 9. Non-regression

- `client-dev.keybuzz.io` : HTTP 307 OK
- `client.keybuzz.io` : HTTP 307 OK
- Aucune modification du backend API ni du client KeyBuzz

---

## 10. Limitations

- Le helper `isFeatureEnabled()` n'est pas encore integre dans les modules backend existants (integration prevue dans les phases suivantes)
- Pas de propagation cache (chaque appel lit la base directement)
- Pas d'historique des modifications (les changements sont traces dans `audit_logs` via les routes admin si l'audit est integre)
