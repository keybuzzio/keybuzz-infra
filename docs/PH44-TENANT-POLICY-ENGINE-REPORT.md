# PH44 — Tenant AI Policy Layer

> Date : 2026-03-08
> Auteur : Cursor Executor (CE)
> Env : DEV uniquement
> Version API : v3.5.50-ph44-tenant-policy-dev
> Status : Deploye DEV, en attente validation avant PROD

---

## 1. Objectif

Ajouter une couche de politique IA configurable par tenant entre la politique globale (PH41) et le moteur historique (PH43), sans modifier le comportement actuel.

### Architecture avant PH44

```
AI System Prompt
     |
PH41 SAV POLICY (globale)
     |
PH43 Historical Engine
     |
LLM
```

### Architecture apres PH44

```
AI System Prompt
     |
PH41 GLOBAL POLICY
     |
PH44 TENANT POLICY (si existe)
     |
PH43 HISTORICAL ENGINE
     |
ANTI PATTERNS
     |
LLM
```

---

## 2. Comportement MVP

- `tenantPolicy = null` pour tous les tenants existants
- Le moteur utilise uniquement `GLOBAL_POLICY + HISTORICAL_DATA`
- Aucun changement visible pour les clients
- La couche tenant ne s'active que si une ligne existe dans `tenant_ai_policies`

---

## 3. Implementation technique

### 3.1 Table `tenant_ai_policies`

```sql
CREATE TABLE tenant_ai_policies (
  tenant_id TEXT PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
  refund_threshold NUMERIC(10,2),
  require_photos BOOLEAN,
  supplier_first BOOLEAN,
  replace_first BOOLEAN,
  diagnostic_required BOOLEAN,
  max_refund_without_return NUMERIC(10,2),
  tone_style TEXT,
  escalation_rules JSONB,
  custom_instructions TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Toutes les colonnes (sauf tenant_id, created_at, updated_at) sont **nullable**.
Aucune valeur par defaut. Seules les valeurs explicitement definies sont injectees.

### 3.2 Fichiers crees/modifies

| Fichier | Action | Lignes |
|---|---|---|
| `src/services/tenantPolicyLoader.ts` | Cree | 97 |
| `src/modules/ai/ai-assist-routes.ts` | Patche | +31 (991 → 1022) |

### 3.3 `tenantPolicyLoader.ts`

- **`loadTenantPolicy(tenantId)`** : charge la policy depuis PostgreSQL avec cache 60s
- **`buildTenantPolicyBlock(policy)`** : genere le bloc prompt textuel
- **`clearPolicyCache(tenantId?)`** : invalide le cache (utile pour l'API de gestion future)
- Cache en memoire avec TTL 60s (pas de requete DB a chaque appel IA)
- Gestion NUMERIC PostgreSQL (conversion `Number()` pour eviter le piege string)
- Fallback safe : si erreur DB, retourne `null` (pas de crash)

### 3.4 Injection dans le prompt

Ordre d'injection dans `buildSystemPrompt()` :

```
1. Base Prompt (regles generales)
2. PH41 SAV Policy (globale, toujours presente)
3. PH44 Tenant Policy (si existe)          <-- NOUVEAU
4. PH43 Historical Engine (si cas trouves)
5. Order Context (si commande liee)
6. Supplier Context (si fournisseur lie)
7. Tenant Channel Rules (si regles canal)
```

### 3.5 Bloc prompt genere (exemple)

```
=== TENANT POLICY ===
Seuil remboursement automatique: 20€
Exiger photos/preuves avant toute decision
Toujours contacter le fournisseur avant remboursement
Diagnostic obligatoire avant toute solution
Remboursement max sans retour produit: 15€
Ton de reponse: Professionnel et empathique
```

### 3.6 Metadata API

Nouveau champ dans la reponse `/ai/assist` :

```json
{
  "tenantPolicy": {
    "used": true,
    "fieldsApplied": ["refundThreshold", "requirePhotos", "supplierFirst", "diagnosticRequired", "maxRefundWithoutReturn", "toneStyle"]
  }
}
```

### 3.7 Logging

```
[AI Assist] <requestId> PH44 Tenant policy loaded for ecomlg-001 fields: refundThreshold,requirePhotos,supplierFirst,diagnosticRequired,maxRefundWithoutReturn,toneStyle
[AI Assist] <requestId> tenant:ecomlg-001 ... ph44TenantPolicy:true
```

---

## 4. Tests

### 4.1 Phase A — Tenant SANS policy (ecomlg-001)

| Test | Status | tenantPolicy.used | fieldsApplied | KBA |
|---|---|---|---|---|
| Article endommage | success | False | (vide) | 9.83 |
| Colis non recu | success | False | (vide) | 9.24 |
| Notification retour | success | False | (vide) | 10.43 |

Comportement identique a PH41+PH43. Aucune regression.

### 4.2 Phase B — Insertion policy test

```sql
INSERT INTO tenant_ai_policies
  (tenant_id, refund_threshold, require_photos, supplier_first,
   diagnostic_required, max_refund_without_return, tone_style)
VALUES
  ('ecomlg-001', 20.00, true, true, true, 15.00, 'Professionnel et empathique');
```

### 4.3 Phase C — Tenant AVEC policy

| Test | Status | tenantPolicy.used | fieldsApplied | KBA |
|---|---|---|---|---|
| Article endommage | success | True | 6 champs | 8.78 |
| Colis non recu | success | True | 6 champs | 11.00 |
| Notification retour | success | True | 6 champs | 9.19 |

Les 6 champs configures sont correctement detectes et injectes dans le prompt.

### 4.4 Phase D — Cleanup

Policy supprimee. Etat propre restaure. Aucune policy active en production.

---

## 5. Safety

| Scenario | Comportement |
|---|---|
| Pas de row dans `tenant_ai_policies` | `loadTenantPolicy()` retourne `null`, aucun bloc injecte |
| Erreur PostgreSQL | Catch + log warning, retourne `null` (fallback safe) |
| Tous les champs `null` | Bloc vide genere, non injecte |
| Table n'existe pas | Erreur catchee, fallback transparent |
| Cache expire | Rechargement automatique apres 60s |

---

## 6. Vision produit (futur)

### Plan tarifaire

| Plan | Policy |
|---|---|
| Starter | Globale uniquement |
| Pro | Globale + reglages simples (seuil, photos, ton) |
| Autopilote | Politique avancee (escalation, instructions custom) |

### UX future (Settings > IA > Politique SAV)

```
Seuil remboursement automatique: [20] €
[x] Exiger photos du produit
[x] Contacter le fournisseur avant remboursement
[ ] Privilegier le remplacement
Ton de reponse: [Professionnel v]
Instructions specifiques: [textarea]
```

### API CRUD (a creer dans une phase future)

```
GET    /tenant-ai-policies/:tenantId
PUT    /tenant-ai-policies/:tenantId
DELETE /tenant-ai-policies/:tenantId
```

---

## 7. Ce qui n'a PAS ete fait (volontairement)

- Pas de fine-tuning LLM par client
- Pas de regles en dur dans le prompt
- Pas de moteurs IA differents par tenant
- Pas d'API CRUD (phase future)
- Pas d'UI Settings (phase future)
- Pas de deploiement PROD

---

## 8. Rollback

```bash
# Rollback API DEV
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.49b-ph43-historical-dev \
  -n keybuzz-api-dev

# La table tenant_ai_policies peut rester (pas de donnees, pas d'impact)
```

---

## 9. Fichiers deployes

| Fichier | Chemin bastion |
|---|---|
| tenantPolicyLoader.ts | `/opt/keybuzz/keybuzz-api/src/services/tenantPolicyLoader.ts` |
| ai-assist-routes.ts | `/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts` |
| Backup pre-PH44 | `/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts.bak-pre-ph44` |

---

## STOP POINT

Aucun deploiement PROD.
Attente validation Ludovic avant promotion PROD ou PH45.
