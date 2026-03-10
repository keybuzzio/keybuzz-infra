# PH50 — Merchant Behavior Engine — Rapport

> Date : 9 mars 2026
> Auteur : Agent Cursor (CE)
> Environnement : DEV uniquement
> Image : `v3.5.58-ph50-merchant-behavior-dev`

---

## 1. Objectif

Creer un **Merchant Behavior Engine** qui analyse automatiquement les decisions SAV d'un vendeur (tenant) pour comprendre ses patterns comportementaux. Ces patterns sont injectes dans le prompt IA afin d'adapter les suggestions au style du vendeur.

PH50 est une couche d'**observabilite et apprentissage passif**. Aucune modification du comportement IA existant, aucun appel LLM supplementaire, aucun cout KBActions additionnel.

---

## 2. Architecture Pipeline IA apres PH50

```
1  Base Prompt
2  PH41 SAV Policy (global)
3  PH44 Tenant Policy
4  PH43 Historical Engine
5  PH45 Decision Tree
6  PH46 Response Strategy
7  PH49 Refund Protection
8  PH50 Merchant Behavior Engine   ← NOUVEAU
9  Order Context
10 Supplier Context
11 Tenant Rules
```

---

## 3. Algorithme de classification

### Sources de donnees
| Source | Usage |
|---|---|
| `conversations` (status='resolved') | Total des cas resolus (denominateur) |
| `amazon_returns` (refunded_amount > 0) | Comptage remboursements |
| `amazon_returns` (sans refund) | Comptage remplacements |
| `supplier_cases` | Comptage garanties/fournisseur |
| `conversations` (sans order_ref) | Comptage demandes d'information |
| Calcul | Investigation = total - (refund + replacement + warranty + info) |

### Taux calcules
- `refund_rate` = refund_count / total_cases
- `replacement_rate` = replacement_count / total_cases
- `warranty_rate` = warranty_count / total_cases
- `investigation_rate` = investigation_count / total_cases

### Classification
| Condition | Categorie |
|---|---|
| refund_rate > 0.35 | HIGH_REFUND |
| warranty_rate > refund_rate | WARRANTY_FIRST |
| refund_rate < 0.10 | CONSERVATIVE |
| sinon | BALANCED |

### Resultats DEV (ecomlg-001)
- 70 cas resolus
- 1 remboursement (1.43%)
- 0 remplacement
- 8 garanties (11.43%)
- 21 demandes d'info
- 40 investigations (57.14%)
- **Categorie : WARRANTY_FIRST** (warranty_rate 11.43% > refund_rate 1.43%)

---

## 4. Table DB

```sql
CREATE TABLE merchant_behavior_profiles (
  tenant_id TEXT PRIMARY KEY,
  total_cases INT DEFAULT 0,
  refund_count INT DEFAULT 0,
  replacement_count INT DEFAULT 0,
  warranty_count INT DEFAULT 0,
  investigation_count INT DEFAULT 0,
  info_request_count INT DEFAULT 0,
  refund_rate FLOAT DEFAULT 0,
  replacement_rate FLOAT DEFAULT 0,
  warranty_rate FLOAT DEFAULT 0,
  investigation_rate FLOAT DEFAULT 0,
  avg_resolution_time_hours FLOAT DEFAULT 0,
  category TEXT DEFAULT 'BALANCED',
  last_updated TIMESTAMP DEFAULT NOW()
);
```

Upsert automatique a chaque calcul (ON CONFLICT DO UPDATE).

---

## 5. Cache Redis

- Cle : `merchant_behavior:{tenantId}`
- TTL : 10 minutes (600 secondes)
- Source retournee : `live` (premier appel) ou `cache` (appels suivants)

---

## 6. Fichiers modifies/crees

| Fichier | Action | Description |
|---|---|---|
| `src/services/merchantBehaviorEngine.ts` | **CREE** | Moteur principal : calcul, classification, cache, persistence, prompt block |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE | Import + appel computeMerchantBehavior, injection prompt block, ajout decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE | Import + endpoint GET /merchant-behavior, ajout dans /policy/effective |

---

## 7. Endpoints

### Debug : GET /ai/merchant-behavior
- Parametres : `tenantId` (obligatoire)
- Header : `X-User-Email` (obligatoire)
- Retour : MerchantBehaviorResult complet
- Aucun appel LLM, aucun cout

### Observabilite : GET /ai/policy/effective
- Nouveau champ `merchantBehavior` dans la reponse
- Nouveau champ `merchantBehavior: true` dans `policyLayers`
- Nouvelle section `MERCHANT_BEHAVIOR` dans `finalPromptSections`

### Decision Context
Nouveau champ dans `decisionContext` :
```json
{
  "merchantBehavior": {
    "category": "WARRANTY_FIRST",
    "refundRate": 0.0143,
    "replacementRate": 0,
    "warrantyRate": 0.1143,
    "investigationRate": 0.5714,
    "avgResolutionTimeHours": 478.16,
    "totalCases": 70
  }
}
```

---

## 8. Injection Prompt

Bloc injecte apres PH49 (Refund Protection) et avant Order Context :

```
=== MERCHANT BEHAVIOR ===
Merchant profile: WARRANTY_FIRST
Refund rate: 1%
Replacement rate: 0%
Warranty usage: 11%
Investigation usage: 57%

Guideline:
Adapt response strategy to match merchant behavior patterns.
Avoid suggesting actions rarely used by the merchant.
This merchant prioritizes warranty/supplier resolution. Suggest contacting supplier first.
=== END MERCHANT BEHAVIOR ===
```

---

## 9. Tests E2E (5/5 PASS)

| # | Test | Resultat |
|---|---|---|
| 1 | Tenant avec historique → category valide | PASS (WARRANTY_FIRST, 70 cases) |
| 2 | Rates coherents (0-1) | PASS (tous entre 0 et 1) |
| 3 | Redis cache actif (source=cache) | PASS |
| 4 | Endpoint debug HTTP 200 + tous champs | PASS (14 champs presents) |
| 5 | /policy/effective contient merchantBehavior | PASS (layer + section + data) |

---

## 10. Non-regression

| Module | Statut |
|---|---|
| API Health | OK (`/health` retourne 200) |
| PH41-PH49 | Inchanges (aucun fichier modifie) |
| KBActions | Aucun cout additionnel (pas d'appel LLM) |
| Inbox | Non impacte |
| Orders | Non impacte |

---

## 11. Infra

| Element | Valeur |
|---|---|
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.58-ph50-merchant-behavior-dev` |
| Namespace | `keybuzz-api-dev` |
| Replicas | 1 |
| Rollback | `v3.5.57-ph49-refund-protection-dev` |

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.57-ph49-refund-protection-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 13. Impact Produit

PH50 permet a KeyBuzz de :
- Adapter l'IA au comportement specifique du vendeur
- Sans configuration manuelle
- Sans fine-tuning LLM
- Sans cout supplementaire

---

## STOP POINT

DEV uniquement. Aucun deploiement PROD. Attente validation Ludovic.
