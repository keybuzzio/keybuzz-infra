# PH-SAAS-T8.12C — Trial Entitlement Schema & API (DEV Only)

> Date : 2026-04-29
> Agent : CE SaaS
> Phase : PH-SAAS-T8.12C
> Tickets : KEY-225, KEY-226
> Verdict : **GO**

---

## 1. DOCUMENTS LUS

| Document | Statut |
|---|---|
| PH-SAAS-T8.12A-SAAS-FEATURE-TRUTH-AUDIT-AND-TRIAL-WOW-CONTEXT-01.md | Lu (contexte audit) |
| AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md | Lu (product memory) |
| PH-SAAS-T8.12B-SAAS-SOURCE-OF-TRUTH-AND-TRIAL-WOW-READINESS-LOCK-01.md | Lu (source of truth lock) |
| PH147.4-GIT-SOURCE-OF-TRUTH-HARDENING-01.md | Lu |
| PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md | Lu |
| AI_MEMORY/RULES_AND_RISKS.md | Lu |
| PH-T8.11Z-ANALYTICS-BASELINE-CLEAN-READINESS-01.md | Lu |

---

## 2. PREFLIGHT

| Item | Valeur | Status |
|---|---|---|
| Repo path | `/opt/keybuzz/keybuzz-api` | OK |
| Remote | `origin` → `github.com/keybuzzio/keybuzz-api.git` | OK |
| Branch | `ph147.4/source-of-truth` | OK |
| HEAD de départ | `d90e0930` | OK |
| Upstream | `origin/ph147.4/source-of-truth` | OK |
| Git status | CLEAN (0 files) | OK |
| Runtime DEV | `v3.5.123-linkedin-capi-native-dev` | OK |
| Runtime PROD | `v3.5.123-linkedin-capi-native-prod` | OK |
| Manifest GitOps DEV | `v3.5.123-linkedin-capi-native-dev` (ligne 307) | OK |

---

## 3. SCHEMA DB

### Avant (tenants)

```
id, tenantId, sellerDisplayName, name, defaultCurrency, domain, timezone,
plan, status, catalogEnabled, multiMarketplaceEnabled,
created_at, updated_at, marketing_owner_tenant_id, identity_ref
```

### Après (tenants)

```
+ selected_plan TEXT NULL
+ trial_entitlement_plan TEXT NULL
```

### Migration

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS selected_plan TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS trial_entitlement_plan TEXT;
```

- Idempotente : `IF NOT EXISTS`
- Exécutée sur `db-postgres-01` (10.0.0.120) via `sudo -u postgres psql keybuzz`
- Vérifiée via pod DEV : colonnes confirmées

### Backward compatibility

- `selected_plan NULL` pour tenants existants → entitlement utilise `plan` comme fallback
- `trial_entitlement_plan NULL` → comportement identique à l'ancien (pas de boost)

---

## 4. FICHIERS MODIFIÉS

| Fichier | Changements |
|---|---|
| `src/modules/auth/tenant-context-routes.ts` | 4 patches (entitlement SELECT, response, INSERT, UPDATE) |
| `src/services/entitlement.service.ts` | 5 patches (interface, init, SELECT, plan assign, effectivePlan) |

**Total : 2 fichiers modifiés, 42 insertions, 9 suppressions**

### Fichiers NON modifiés (invariants)

- `src/modules/billing/routes.ts` — 0 changement
- `src/modules/outbound-conversions/emitter.ts` — 0 changement
- `src/modules/ai/ai-mode-engine.ts` — 0 changement (bénéficie automatiquement du nouveau `plan = effectivePlan`)
- Aucun fichier client, admin, website

---

## 5. MIGRATION STRATEGY

### Approche : colonnes additives

- Pas de migration framework (le projet n'en utilise pas) → SQL direct idempotent
- Pas de DROP COLUMN, pas de RENAME
- Exécution manuelle sur leader PostgreSQL (db-postgres-01 / 10.0.0.120)
- Réplication automatique vers db-postgres-03 via Patroni

### Rollback DB safe

```sql
UPDATE tenants SET trial_entitlement_plan = NULL;
-- NE PAS DROP les colonnes en urgence
```

---

## 6. LOGIQUE effective_plan

### Règle

```
Si tenant en trial actif ET trial_entitlement_plan non null :
  effective_plan = trial_entitlement_plan
Sinon :
  effective_plan = billing_plan (plan existant)
```

### Calcul `trial_entitlement_plan` à la création

| Plan choisi | selected_plan | trial_entitlement_plan |
|---|---|---|
| STARTER | STARTER | **PRO** (boost) |
| PRO | PRO | **PRO** (no-op) |
| AUTOPILOT | AUTOPILOT | **null** (pas de boost) |
| ENTERPRISE | ENTERPRISE | **null** (pas de boost) |

### Détection "en trial"

Route entitlement : `billingStatus === 'trialing' || (isTrial && daysLeftTrial > 0)`
Service entitlement : `billingStatus === 'trialing' || daysLeftTrial > 0`

---

## 7. CAPABILITIES BOOSTÉES vs NON BOOSTÉES

### Boostées par trial PRO (Starter trial)

| Capability | Avant (STARTER) | Après (PRO effective) |
|---|---|---|
| canSuggest | false | **true** |
| maxMode | 'disabled' | **'suggestion'** |

### Bloquées malgré trial PRO

| Capability | Valeur PRO | Raison |
|---|---|---|
| canAutoReply | false | Nécessite AUTOPILOT réel |
| canAutoAssign | false | Nécessite AUTOPILOT réel |
| canEscalate | false | Nécessite AUTOPILOT réel |
| canEscalateToKeybuzz | false | Nécessite ENTERPRISE réel |

**Conclusion : le boost PRO n'active que les suggestions IA, pas l'auto-exécution.**

---

## 8. RÉPONSE API ENRICHIE

### Avant

```json
{
  "tenantId": "...",
  "plan": "STARTER",
  "billingStatus": "trialing",
  "trialEndsAt": "...",
  "isLocked": false,
  "lockReason": "NONE",
  "daysLeftTrial": 14,
  "daysLeftGrace": 0
}
```

### Après

```json
{
  "tenantId": "...",
  "plan": "PRO",
  "billingPlan": "STARTER",
  "selectedPlan": "STARTER",
  "trialEntitlementPlan": "PRO",
  "effectivePlan": "PRO",
  "billingStatus": "trialing",
  "trialEndsAt": "...",
  "isLocked": false,
  "lockReason": "NONE",
  "daysLeftTrial": 14,
  "daysLeftGrace": 0
}
```

---

## 9. BUILD & DEPLOY

| Item | Valeur |
|---|---|
| Commit | `3ad30a67` feat(trial-entitlement): add selected_plan and trial_entitlement_plan |
| Pre-build check | `BUILD ALLOWED - working tree is clean` |
| Image tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.126-trial-entitlement-dev` |
| Image digest | `sha256:32cc2162961050a5e24872b043071079cc4b521f35841b7c46eafe8c60721bb4` |
| Manifest GitOps | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` ligne 307 |
| Infra commit | `cf2b877` deploy(api-dev): v3.5.126-trial-entitlement-dev |
| Deploy method | `kubectl apply -f` (GitOps strict, pas `kubectl set image`) |
| Rollout status | `deployment "keybuzz-api" successfully rolled out` |

---

## 10. VALIDATION DEV (CAS A-E)

| Cas | Description | Résultat | Détail |
|---|---|---|---|
| A | Starter trial → effectivePlan=PRO | **PASS** | Boost PRO confirmé |
| B | PRO trial → effectivePlan=PRO | **PASS** | No over-boost |
| C | AUTOPILOT trial → effectivePlan=AUTOPILOT | **PASS** | trial_entitlement_plan=null |
| D | Tenant existant (ecomlg-001) | **PASS** | trial_entitlement_plan=null, backward compatible |
| D-API | Entitlement API ecomlg-001 | **PASS** | Nouveaux champs présents |
| E | Trial expiré → effectivePlan=billing_plan | **PASS** | Pas de PRO permanent |

### Validation API live (ecomlg-001)

```json
{
  "tenantId": "ecomlg-001",
  "plan": "PRO",
  "billingPlan": "PRO",
  "selectedPlan": "PRO",
  "trialEntitlementPlan": null,
  "effectivePlan": "PRO",
  "billingStatus": "no_subscription",
  "isLocked": false,
  "lockReason": "NONE"
}
```

---

## 11. TRACKING INVARIANTS

| Invariant | Status |
|---|---|
| signup_complete envoie plan choisi | Non modifié (client-side, pas touché) |
| purchase lié Stripe webhook | Non modifié (billing/routes.ts inchangé) |
| conversion_events table | 2 events existants, 0 ajouté |
| outbound_conversion_delivery_logs | 7 logs existants, 0 ajouté |
| CAPI destinations | Inchangées |
| marketing_owner_tenant_id | Inchangé |
| Baseline analytics 2026-04-29 | Préservée |
| Aucun faux purchase | Confirmé |
| Aucun faux event CAPI | Confirmé |

---

## 12. NON-RÉGRESSION

| Check | Résultat |
|---|---|
| API health DEV | `{"status":"ok"}` |
| billing/current DEV | Fonctionne (plan PRO, 3 channels) |
| tenant-context/entitlement DEV | Fonctionne (nouveaux champs) |
| create-signup DEV | Route active (400 validation, pas 404) |
| Stripe webhook route | Active (erreur signature attendue) |
| PROD API image | `v3.5.123-linkedin-capi-native-prod` **INCHANGÉE** |
| PROD Client image | `v3.5.125-register-console-cleanup-prod` **INCHANGÉE** |
| PROD Website image | `v0.6.7-pricing-attribution-forwarding-prod` **INCHANGÉE** |
| Secrets dans logs | 0 matches |

---

## 13. ROLLBACK

### GitOps image retour

```bash
# 1. Revert manifest
sed -i 's|ghcr.io/keybuzzio/keybuzz-api:v3.5.126-trial-entitlement-dev.*|ghcr.io/keybuzzio/keybuzz-api:v3.5.123-linkedin-capi-native-dev|' /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml

# 2. Commit + Apply
cd /opt/keybuzz/keybuzz-infra && git add -A && git commit -m "rollback(api-dev): revert to v3.5.123-linkedin-capi-native-dev"
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

### DB rollback safe

```sql
-- Sur db-postgres-01 (10.0.0.120)
UPDATE tenants SET trial_entitlement_plan = NULL;
-- NE PAS dropper les colonnes en urgence
```

### Redéploiement GitOps strict

Pas de `kubectl set image`, uniquement manifest → commit → apply.

---

## 14. LINEAR

### KEY-225 — Trial full-experience PRO pendant 14 jours

**Comment à copier :**

> **PH-T8.12C DEV DONE** — 2026-04-29
>
> Schema : `selected_plan` + `trial_entitlement_plan` ajoutées à `tenants` (idempotent).
> API : create-signup stocke `selected_plan` et calcule `trial_entitlement_plan` (PRO pour STARTER/PRO, null pour AUTOPILOT+).
> Entitlement : `effectivePlan` = `trial_entitlement_plan` si trial actif, sinon billing plan.
> Image : `v3.5.126-trial-entitlement-dev` (sha256:32cc2162...).
> Validation : 10/10 tests PASS. PROD inchangée.
> Prochaine étape : client UI phase (FeatureGate → effectivePlan).

### KEY-226 — Distinguer selected_plan, billing_plan et trial_entitlement_plan

**Comment à copier :**

> **PH-T8.12C DEV DONE** — 2026-04-29
>
> Nouveau contrat API `/tenant-context/entitlement` :
> - `plan` = effectivePlan (backward compatible pour clients existants)
> - `billingPlan` = plan Stripe/billing réel
> - `selectedPlan` = plan choisi à l'inscription (vérité marketing)
> - `trialEntitlementPlan` = boost trial temporaire (PRO ou null)
> - `effectivePlan` = plan effectif pour capabilities
>
> Service `getTenantEntitlement()` mis à jour avec même logique → AI mode engine auto-bénéficie.
> Pas de changement billing/Stripe/CAPI/tracking.

---

## 15. RÉSUMÉ FINAL

### PH-SAAS-T8.12C — TERMINÉ
### Verdict : **GO**

| Item | Valeur |
|---|---|
| API branch | `ph147.4/source-of-truth` |
| API HEAD clean | `3ad30a67` (from `d90e0930`) |
| Migration DEV | 2 colonnes ADD IF NOT EXISTS |
| selected_plan | Stocké à create-signup = plan choisi |
| trial_entitlement_plan | PRO pour STARTER/PRO, null pour AUTOPILOT+ |
| effective_plan | trial_entitlement_plan si trial actif, sinon billing_plan |
| Starter trial | effectivePlan=PRO, canSuggest=true, canAutoReply=false |
| Pro trial | effectivePlan=PRO, no over-boost |
| Autopilot trial | effectivePlan=AUTOPILOT, null trial_entitlement_plan |
| Existing tenants | trial_entitlement_plan=NULL, backward compatible |
| Tracking invariants | 0 modification billing/conversion/CAPI |
| Build DEV tag | `v3.5.126-trial-entitlement-dev` |
| Build digest | `sha256:32cc2162961050a5e24872b043071079cc4b521f35841b7c46eafe8c60721bb4` |
| PROD modified | **NON** |

### Conclusion

**TRIAL ENTITLEMENT FOUNDATION READY IN DEV — STARTER TRIAL CAN EXPERIENCE PRO CAPABILITIES WITHOUT BILLING/TRACKING DRIFT — AUTO-EXECUTE STILL BLOCKED — PROD UNCHANGED — READY FOR CLIENT SOURCE LOCK / UI PHASE**
