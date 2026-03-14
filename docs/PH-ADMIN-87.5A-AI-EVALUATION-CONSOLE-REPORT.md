# PH-ADMIN-87.5A — AI Evaluation & Training Console — RAPPORT

**Date** : 2026-03-14
**Image** : ghcr.io/keybuzzio/keybuzz-admin-v2:v0.21.0-ph87.5a-ai-evaluations
**Statut** : DEPLOYE DEV + PROD

---

## 1. Table ai_evaluations

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant unique |
| created_at | TIMESTAMPTZ | Date creation |
| case_id | TEXT | Reference vers le cas |
| tenant_id | TEXT | Tenant concerne |
| ai_recommendation | TEXT | Recommandation IA originale |
| human_decision | TEXT | Decision humaine |
| evaluation_result | TEXT | correct / incorrect / partially_correct |
| reviewer_user_id | TEXT | Email du reviewer |
| comment | TEXT | Commentaire justificatif |
| metadata | JSONB | Donnees additionnelles |

**Index** : case_id, tenant_id, evaluation_result, created_at DESC, reviewer_user_id

---

## 2. API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| /api/admin/ai-evaluations | GET | Liste + stats (filtres: tenant_id, evaluation_result, reviewer) | super_admin, ops_admin, account_manager |
| /api/admin/ai-evaluations | POST | Creer une evaluation | super_admin, ops_admin, account_manager |
| /api/admin/ai-evaluations/[caseId] | GET | Historique evaluations par cas | super_admin, ops_admin, account_manager |
| /api/admin/ai-evaluations/export | GET | Export dataset JSON ou CSV | super_admin uniquement |

---

## 3. Page /ai-evaluations

- 5 KPI : Total, Correctes, Incorrectes, Partielles, Precision IA (%)
- Barre de repartition (correct / partiel / incorrect)
- Filtres : evaluation_result, tenant_id
- Tableau 7 colonnes : Cas, Tenant, Recommandation IA, Decision humaine, Resultat, Reviewer, Date
- Etat vide : message explicite ("Aucune evaluation IA disponible")
- Navigation : section IA du sidebar (icone GraduationCap)

---

## 4. Panneau AI Evaluation (Case Workbench)

Integre dans /cases/[id] (sidebar droite) :
- 3 boutons : Correct / Partiel / Incorrect
- Champ decision humaine (optionnel)
- Champ commentaire (optionnel)
- Historique des evaluations precedentes avec badge + date + reviewer

---

## 5. Export Dataset

**Format JSON** :
```json
{
  "data": [{
    "case_id": "...",
    "tenant_id": "...",
    "ai_recommendation": "...",
    "human_decision": "...",
    "evaluation_result": "correct",
    "comment": "...",
    "reviewer": "email@...",
    "evaluated_at": "2026-03-14T..."
  }],
  "exported_at": "...",
  "count": 0
}
```

**Format CSV** : Memes colonnes, telechargement automatique.

---

## 6. Donnees

- Aucune donnee inventee
- Toutes les evaluations proviennent de cas reels existants (via case_id)
- Le panneau dans le Case Workbench utilise les donnees du cas affiche
- L'export ne contient que des evaluations humaines reelles

---

## 7. Non-regression client

| Service | Namespace | Statut |
|---|---|---|
| client-dev.keybuzz.io | keybuzz-client-dev | Running |
| client.keybuzz.io | keybuzz-client-prod | Running |
| api-dev | keybuzz-api-dev | Running |
| api-prod | keybuzz-api-prod | Running |
| admin-dev | keybuzz-admin-v2-dev | Running |
| admin-prod | keybuzz-admin-v2-prod | Running |

Aucun pod impacte. Aucune modification aux pipelines existants.

---

## 8. Fichiers crees ou modifies

| Fichier | Action |
|---|---|
| src/features/ai-evaluations/ai-evaluation.service.ts | CREE — Service CRUD + stats + export |
| src/features/ai-evaluations/EvaluationPanel.tsx | CREE — Panneau evaluation pour Case Workbench |
| src/app/api/admin/ai-evaluations/route.ts | CREE — GET list + POST create |
| src/app/api/admin/ai-evaluations/[caseId]/route.ts | CREE — GET evaluations par cas |
| src/app/api/admin/ai-evaluations/export/route.ts | CREE — GET export JSON ou CSV |
| src/app/(admin)/ai-evaluations/page.tsx | CREE — Page dashboard evaluations |
| src/app/(admin)/cases/[id]/page.tsx | MODIFIE — Ajout EvaluationPanel |
| src/config/navigation.ts | MODIFIE — Ajout lien AI Evaluations |
| src/components/layout/Sidebar.tsx | MODIFIE — Ajout icone GraduationCap |

---

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.20.0-ph87.4a-queue-inspector -n keybuzz-admin-v2-dev
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.20.0-ph87.4a-queue-inspector -n keybuzz-admin-v2-prod
```
