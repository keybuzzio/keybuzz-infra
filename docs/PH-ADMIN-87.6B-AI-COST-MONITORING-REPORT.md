# PH-ADMIN-87.6B — AI Cost Monitoring & Provider Spend — RAPPORT

**Date** : 2026-03-14
**Image** : ghcr.io/keybuzzio/keybuzz-admin-v2:v0.23.0-ph87.6b-ai-cost-monitoring
**Statut** : DEPLOYE DEV + PROD

---

## 1. Audit sources donnees IA

### Tables auditees

| Table | Lignes | Provider | Model | Tokens | Cost USD | Exploitable |
|---|---|---|---|---|---|---|
| ai_action_log | 1255 | NON (dans payload.kbSource) | OUI (payload.model = "kbz-standard") | NON | NON | Requetes, modeles internes, workflows |
| ai_actions_ledger | 275 | NON | OUI (decision_context.model) | NON | Colonne existe mais NULL | KBA delta, consommation |
| ai_budget_settings | 3 | NON | NON | NON | NON | Caps budget uniquement |
| ai_actions_wallet | 3 | NON | NON | NON | NON | Soldes KBA uniquement |
| ai_provider_usage | 0 (CREEE) | OUI | OUI | OUI | OUI | Pret pour instrumentation |

### Constats

- Les couts provider reels (OpenAI, Anthropic) ne sont **pas encore persistes** dans la DB
- Le champ `cost_usd` dans `ai_actions_ledger` existe mais est systematiquement NULL
- Le champ `model` contient un alias interne ("kbz-standard") et non le modele LLM reel
- Les requetes IA sont tracees dans `ai_action_log` (1255 entries) avec action_type, workflow, scenario

### Limitations documentees

- **Pas de cout USD reel** : le pipeline IA n'enregistre pas encore les tokens/couts provider
- **Pas de detail provider** : OpenAI vs Anthropic non distingue dans les logs actuels
- **Pas de comparaison revenus/couts** : les revenus par plan sont connus mais les couts provider sont absents

---

## 2. Table ai_provider_usage (CREEE)

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant unique |
| created_at | TIMESTAMPTZ | Date enregistrement |
| tenant_id | TEXT | Tenant concerne |
| provider | TEXT | openai, anthropic, etc. |
| model | TEXT | gpt-4o, claude-3-haiku, etc. |
| input_tokens | INTEGER | Tokens en entree |
| output_tokens | INTEGER | Tokens en sortie |
| estimated_cost_usd | NUMERIC(10,6) | Cout estime USD |
| workflow | TEXT | Type de workflow IA |
| metadata | JSONB | Donnees additionnelles |

**4 index** : tenant_id, provider, model, created_at DESC

Table creee DEV + PROD. Actuellement vide. Se remplira quand le pipeline IA sera instrumente.

---

## 3. API AI Costs

| Route | Methode | Description | RBAC |
|---|---|---|---|
| /api/admin/finance/ai-costs/overview | GET | KPI globaux (requetes, KBA, couts si disponibles) | super_admin, finance_admin |
| /api/admin/finance/ai-costs/providers | GET | Couts par provider (fallback: kbSource depuis ai_action_log) | super_admin, finance_admin |
| /api/admin/finance/ai-costs/models | GET | Couts par modele (fallback: payload.model depuis ai_action_log) | super_admin, finance_admin |
| /api/admin/finance/ai-costs/tenants | GET | Top 10 tenants consommation IA | super_admin, finance_admin |
| /api/admin/finance/ai-costs/timeline | GET | Timeline requetes/couts par jour (7/30/90j) | super_admin, finance_admin |

### Strategie fallback

Le service utilise une strategie double :
1. **Priorite** : donnees `ai_provider_usage` (couts reels, tokens, provider)
2. **Fallback** : donnees `ai_action_log` (requetes, modele interne, sans couts USD)

Cela garantit que l'onglet affiche toujours les donnees disponibles sans inventer de metriques.

---

## 4. Onglet AI Costs dans /finance

### Section 1 — Overview (4 KPI)
- Requetes IA total (depuis ai_action_log)
- KBA consommes (depuis ai_actions_ledger)
- Cout IA 30j (si ai_provider_usage a des donnees)
- Cout IA total (si ai_provider_usage a des donnees)
- Message explicite si couts non disponibles

### Section 2 — Provider Costs
- Tableau 4 colonnes : Provider/Source, Requetes, Tokens, Cout estime
- Fallback vers kbSource (ex: "inbox_contextualized") si pas de provider reel

### Section 3 — Model Costs
- Tableau 4 colonnes : Modele, Requetes, Tokens, Cout estime
- Affiche "kbz-standard" actuellement (modele interne)

### Section 4 — Tenant Consumption
- Top 10 tenants par consommation
- Colonnes : Tenant, Requetes, KBA consommes, Cout estime

### Section 5 — Timeline
- Graphique en barres (chart CSS natif)
- Periodes selectionnables : 7j, 30j, 90j
- Tooltip au hover avec date, requetes, cout
- Resume total en bas

### Section 6 — Revenue vs Cost
- Message explicite : "Les couts provider USD ne sont pas encore instrumentes"
- Mentionne que la table ai_provider_usage est prete
- S'affichera automatiquement quand les donnees seront disponibles

---

## 5. Donnees

- **Aucune donnee inventee**
- Toutes les metriques proviennent de tables reelles
- Les couts USD affichent "—" quand non disponibles (jamais un faux montant)
- Le message "Couts USD provider non encore instrumentes" est affiche clairement

---

## 6. Non-regression client

| Service | Namespace | Statut |
|---|---|---|
| client-dev.keybuzz.io | keybuzz-client-dev | Running |
| client.keybuzz.io | keybuzz-client-prod | Running |
| api-dev | keybuzz-api-dev | Running |
| api-prod | keybuzz-api-prod | Running |
| admin-dev | keybuzz-admin-v2-dev | Running |
| admin-prod | keybuzz-admin-v2-prod | Running |

Aucun pod impacte. Aucune modification aux pipelines IA existants.

---

## 7. Fichiers crees ou modifies

| Fichier | Action |
|---|---|
| src/features/ai-costs/ai-costs.service.ts | CREE — Service (overview, providers, models, tenants, timeline) |
| src/app/api/admin/finance/ai-costs/overview/route.ts | CREE |
| src/app/api/admin/finance/ai-costs/providers/route.ts | CREE |
| src/app/api/admin/finance/ai-costs/models/route.ts | CREE |
| src/app/api/admin/finance/ai-costs/tenants/route.ts | CREE |
| src/app/api/admin/finance/ai-costs/timeline/route.ts | CREE |
| src/app/(admin)/finance/page.tsx | MODIFIE — Ajout onglet AI Costs (6 sections) |

---

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.22.0-ph87.6a-finance-dashboard -n keybuzz-admin-v2-dev
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.22.0-ph87.6a-finance-dashboard -n keybuzz-admin-v2-prod
```
