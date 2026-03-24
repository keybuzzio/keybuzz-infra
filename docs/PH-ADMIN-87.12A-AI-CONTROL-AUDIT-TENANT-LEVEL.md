# PH-ADMIN-87.12A — AI CONTROL & AI AUDIT TENANT-LEVEL

## 1. Resume executif

### Ce qui a ete ajoute
| Composant | Description |
|---|---|
| `GET /api/admin/tenants/[id]/ai` | Regles IA, activite, execution audit, evaluations, settings, queue d'approbation |
| Page `/ai` | Nouvelle page tenant-aware Intelligence IA avec 5 sections reelles |
| `useTenantSelector` ameliore | Respecte `tenantId` du query string pour pre-selection automatique |
| Suspense boundaries | Ajoutees aux 5 pages AI control (page, monitoring, policies, debug, activation) |
| Cockpit QuickLinks | "Intelligence IA du tenant", "AI Control Center", "Monitoring IA" |
| Sidebar navigation | "IA Tenant" ajoute dans Intelligence IA |
| Version | Bump v2.6.0 → v2.7.0 |

### Ce qui est reellement branche
- `ai_rules` : 15 regles par tenant (seed onboarding), toutes disabled par defaut
- `ai_action_log` : 48 actions IA pour ecomlg-001 (PROD), 1285 en DEV
- `ai_execution_audit` : 7 audits pour ecomlg-001 (PROD)
- `ai_settings` : config IA pour ecomlg-001 (mode supervised, ai_enabled true, safe_mode true)
- `ai_human_approval_queue` : 2 items pour ecomlg-001 (PROD)

### Ce qui reste non alimente
- `ai_evaluations` : 0 partout — table existe, pas encore de feedback humain enregistre
- `tenant_ai_policies` : 0 partout — policies tenant non encore configurees

---

## 2. Cartographie des sources IA

| Table | Tenant-scope | DEV | PROD | Exploitable |
|---|---|---|---|---|
| `ai_rules` | Oui (`tenant_id`) | 105 (7x15) | 45 (3x15) | Oui |
| `ai_rule_conditions` | Via `rule_id` | 28 | 12 | Oui (lie aux rules) |
| `ai_rule_actions` | Via `rule_id` | 252 | 108 | Oui (lie aux rules) |
| `ai_action_log` | Oui (`tenant_id`) | 1285 (ecomlg) | 48 (ecomlg) | Oui |
| `ai_execution_audit` | Oui (`tenant_id`) | 5 (ecomlg) | 7 (ecomlg) | Oui |
| `ai_evaluations` | Oui (`tenant_id`) | 0 | 0 | Empty state |
| `tenant_ai_policies` | Oui (`tenant_id`) | 0 | 0 | Empty state |
| `ai_settings` | Oui (`tenant_id`) | 1 (ecomlg) | 1 (ecomlg) | Oui |
| `ai_global_settings` | Global | 1 | 1 | Contexte (non tenant) |
| `ai_human_approval_queue` | Oui (`tenant_id`) | 1 | 2 (ecomlg) | Oui |

---

## 3. Endpoint IA tenant

### `GET /api/admin/tenants/[id]/ai`

**Payload reel (ecomlg-001 PROD)** :
```json
{
  "data": {
    "rules": { "total": 15, "active": 0, "items": [15 regles starter...] },
    "activity": { "actions_total": 48, "recent_actions": [10 entries AI_DECISION_TRACE...] },
    "execution_audit": { "total": 7, "recent": [7 entries...] },
    "evaluations": { "total": 0, "correct": 0, "incorrect": 0, "partial": 0, "recent": [] },
    "settings": {
      "mode": "supervised", "ai_enabled": true, "safe_mode": true,
      "kill_switch": false, "auto_disabled": false, "max_actions_per_hour": 20, "daily_budget": 0
    },
    "approval_queue": { "total": 2, "pending": 0 }
  }
}
```

**Limites reelles** :
- Evaluations toujours vides (aucun feedback humain collecte)
- Policies tenant toujours vides (non encore configurees)
- Rules toutes disabled (aucune activee par l'utilisateur)

---

## 4. UI

### Page `/ai` (Intelligence IA Tenant)
- **Bandeau etat IA** : mode, ai_enabled, safe_mode, kill_switch, auto_disabled
- **StatCards** : Regles IA (total), Regles actives, Actions IA, Audits execution, Evaluations
- **Table regles IA** : nom, description, trigger, mode, statut, niveau intelligence, plan min
- **Activite IA recente** : 10 dernieres actions avec action_type, status, summary, date
- **Audits d'execution** : action_type, workflow_stage, fraud_risk, order_value_category, date
- **Evaluations humaines** : compteurs correct/incorrect/partiel + liste (empty state si 0)
- **File d'approbation** : total + en attente
- **TenantFilterBanner** avec "Retour au cockpit tenant"

### Pages AI Control tenant-aware
- `useTenantSelector` ameliore pour respecter `tenantId` du query string
- Pre-selection automatique du tenant depuis les liens cockpit
- Toutes les pages AI control (page, monitoring, policies, debug, activation) beneficient de Suspense boundaries

### Cockpit tenant
- QuickLink "Intelligence IA du tenant" → `/ai?tenantId=<id>`
- QuickLink "AI Control Center" → `/ai-control?tenantId=<id>`
- QuickLink "Monitoring IA" → `/ai-control/monitoring?tenantId=<id>`

### Sidebar
- "IA Tenant" ajoute dans la section Intelligence IA

---

## 5. Pages IA tenant-aware

| Page | Tenant-aware | Methode |
|---|---|---|
| `/ai` | Oui | Nouvelle page, `tenantId` query param, API dediee |
| `/ai-control` | Oui | `useTenantSelector` + `tenantId` query param |
| `/ai-control/monitoring` | Oui | `useTenantSelector` + `tenantId` query param |
| `/ai-control/policies` | Oui | `useTenantSelector` + `tenantId` query param |
| `/ai-control/debug` | Oui | `useTenantSelector` + `tenantId` query param |
| `/ai-control/activation` | Oui | `useTenantSelector` + `tenantId` query param |

Toutes les pages AI control sont tenant-aware grace au `useTenantSelector` ameliore.

---

## 6. Preuve DB → API → UI → navigation

### PROD — ecomlg-001 (tenant riche)

| Section | DB | API | UI |
|---|---|---|---|
| Regles IA | 15 rows `ai_rules` | `rules.total: 15` | 15 regles listees avec noms/descriptions |
| Regles actives | 0 active | `rules.active: 0` | "0" affiche |
| Actions IA | 48 rows `ai_action_log` | `activity.actions_total: 48` | 10 recentes avec summaries |
| Audits execution | 7 rows `ai_execution_audit` | `execution_audit.total: 7` | 7 audits avec dates |
| Evaluations | 0 rows | `evaluations.total: 0` | "Aucune evaluation humaine" |
| Settings | 1 row supervised/enabled | `settings.ai_enabled: true` | Bandeau "IA activee / Mode supervised / Safe mode" |
| Queue | 2 rows | `approval_queue.total: 2` | "Total: 2, En attente: 0" |
| AI Control | — | — | Pre-selection ecomlg-001 via URL |

### PROD — switaa-sasu-mmazd2rd (tenant sparse)

| Section | DB | API | UI |
|---|---|---|---|
| Regles IA | 15 rows (seed) | `rules.total: 15` | 15 regles listees |
| Regles actives | 0 | `rules.active: 0` | "0" |
| Actions IA | 0 | `activity.actions_total: 0` | "Aucune activite IA" |
| Audits | 0 | `execution_audit.total: 0` | "Aucun audit d'execution" |
| Evaluations | 0 | `evaluations.total: 0` | "Aucune evaluation humaine" |
| Settings | null | `settings: null` | "Aucune configuration IA specifique" |

---

## 7. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA | `01b4919ff8d21a3badf2e29d49d0f801aa0689b9` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-dev` |
| Digest DEV | `sha256:7bd57398d578db78bb6b683d67630a6cd0fe522867a73f698744dfaeeb36ac8e` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-prod` |
| Digest PROD | `sha256:68c3b2983c0eeee1d82115d813ac6784554091f6d6621f4385518f1abfc37eb2` |
| Version runtime | v2.7.0 |

---

## 8. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.6.0-ph-admin-87-11b-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## 9. Dettes restantes

| Dette | Description | Priorite |
|---|---|---|
| `ai_evaluations` vide | Table existe, aucun feedback humain collecte — necessite integration cote client inbox | Moyenne |
| `tenant_ai_policies` vide | Table existe, aucune policy tenant configuree — necessite onboarding IA | Moyenne |
| Regles toutes disabled | Les 15 playbooks seed sont disabled — l'utilisateur doit les activer | Basse (design) |
| `ai_settings` absent pour tenants sparse | Seul ecomlg-001 a des settings IA — les autres tenants n'ont pas de config | Basse |
| AI Control pages actions | Les pages `/ai-control/*` sont maintenant tenant-aware via URL mais n'ont pas de `TenantFilterBanner` — elles utilisent le selector dropdown existant | Basse |
