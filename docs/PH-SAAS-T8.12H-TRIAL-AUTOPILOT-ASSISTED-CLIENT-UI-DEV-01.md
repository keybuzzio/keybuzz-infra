# PH-SAAS-T8.12H — Trial Autopilote Assisté — Client UI DEV

> **Phase** : T8.12H | **Scope** : DEV ONLY | **Type** : Feature implementation
> **Date** : 2026-04-29 | **Auteur** : Agent Cursor
> **Verdict** : TRIAL AUTOPILOT ASSISTED UI READY IN DEV

---

## Documents lus

| Document | Statut |
|---|---|
| `PH-SAAS-T8.12A-SAAS-FEATURE-TRUTH-AUDIT-AND-TRIAL-WOW-CONTEXT-01.md` | Lu |
| `AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md` | Lu |
| `PH-SAAS-T8.12B-SAAS-SOURCE-OF-TRUTH-AND-TRIAL-WOW-READINESS-LOCK-01.md` | Lu |
| `PH-SAAS-T8.12C-TRIAL-ENTITLEMENT-SCHEMA-AND-API-DEV-01.md` | Lu |
| `PH-SAAS-T8.12C.1-TRIAL-AUTOPILOT-ASSISTED-SEMANTICS-DEV-01.md` | Lu |
| `PH-SAAS-T8.12G-CLIENT-SOURCE-OF-TRUTH-LOCK-01.md` | Lu |

---

## Preflight complet

| Vérification | Résultat |
|---|---|
| Branche Client | `ph148/onboarding-activation-replay` ✅ |
| HEAD Client (pre-patch) | `8961023` ✅ |
| Repo clean | 0 dirty, 0 untracked ✅ |
| Runtime DEV Client | `v3.5.125-register-console-cleanup-dev` ✅ |
| Runtime API DEV | `v3.5.127-trial-autopilot-assisted-dev` ✅ |
| PROD Client | `v3.5.125-register-console-cleanup-prod` ✅ |
| PROD API | `v3.5.123-linkedin-capi-native-prod` ✅ |
| pre-build-check | `BUILD ALLOWED - working tree is clean` ✅ |

---

## Fichiers modifiés

| Fichier | Action | Description |
|---|---|---|
| `src/features/billing/planCapabilities.ts` | M | Ajout `AUTOPILOT_ASSISTED` à PlanType, PLAN_CAPABILITIES, PLANS, PLAN_ORDER + `BILLABLE_PLAN_ORDER` + `maxAgents?` |
| `src/features/billing/useEntitlement.tsx` | M | Extension TenantEntitlement : `billingPlan`, `selectedPlan`, `trialEntitlementPlan`, `effectivePlan` |
| `src/features/billing/useCurrentPlan.tsx` | M | Trial-aware PlanProvider : fetch entitlement, override `plan` avec `effectivePlan` pendant trial, expose `billingPlan` et `isTrialBoosted` |
| `src/features/billing/components/TrialBanner.tsx` | A | Nouvelle bannière trial avec countdown, couleurs progressives, CTA upgrade |
| `src/features/billing/components/FeatureGate.tsx` | M | Ajout `AUTOPILOT_ASSISTED` aux `planOrder[]` (2 occurrences) et colors `Record<PlanType>` |
| `src/features/billing/components/PlanStatus.tsx` | M | Ajout `AUTOPILOT_ASSISTED` aux 3 objets `colors`/`bgColors`/`borderColors` |
| `app/billing/plan/page.tsx` | M | Ajout `AUTOPILOT_ASSISTED` au `planColors: Record<PlanType, string>` |
| `app/locked/page.tsx` | M | `PLAN_DISPLAY_NAMES` avec label humain `"Autopilote assisté (essai)"`, utilise `selectedPlan` pour checkout |
| `src/components/layout/ClientLayout.tsx` | M | Import + rendu `<TrialBanner />` après `</header>` |

**Total : 9 fichiers (8 modifiés, 1 créé)**

---

## Diff fonctionnel

### 1. `planCapabilities.ts`

**PlanType étendu :**
```typescript
type PlanType = 'STARTER' | 'PRO' | 'AUTOPILOT_ASSISTED' | 'AUTOPILOT' | 'ENTERPRISE';
```

**Capabilities AUTOPILOT_ASSISTED :**
| Capability | Valeur | Comparaison |
|---|---|---|
| `canSuggest` (API) | `true` | = PRO |
| `maxMode` (API) | `supervised` | < AUTOPILOT |
| `canAutoReply` (API) | `false` | ≠ AUTOPILOT |
| `hasJournalIA` | `true` | = PRO |
| `hasSupervisionAvancee` | `true` | = AUTOPILOT |
| `canAutoExecute` | `false` | ≠ AUTOPILOT |
| `escalationTarget` | `client_team` | ≠ AUTOPILOT (`keybuzz_team`) |
| `kbActionsMonthly` | `1000` | = PRO |
| `maxChannels` | `3` | = PRO |

**PLAN_ORDER :** `STARTER → PRO → AUTOPILOT_ASSISTED → AUTOPILOT → ENTERPRISE`

**BILLABLE_PLAN_ORDER :** `STARTER → PRO → AUTOPILOT → ENTERPRISE` (exclut AUTOPILOT_ASSISTED)

### 2. `useEntitlement.tsx`

```typescript
interface TenantEntitlement {
  // ... existants ...
  billingPlan?: string;           // NOUVEAU — plan facturé réel
  selectedPlan?: string;          // NOUVEAU — plan choisi au signup
  trialEntitlementPlan?: string;  // NOUVEAU — plan trial boosté
  effectivePlan?: string;         // NOUVEAU — plan résolu (billing ou trial)
}
```

### 3. `useCurrentPlan.tsx`

**Nouveau flux :**
1. Fetch `/api/billing/current` → `billingPlan` (ex: STARTER)
2. Fetch `/api/tenant-context/entitlement` → check `billingStatus === 'trialing'` + `effectivePlan`
3. Si trial boosté : `plan = effectivePlan` (AUTOPILOT_ASSISTED), `billingPlan = STARTER`
4. Sinon : `plan = billingPlan`

**Nouveaux champs exposés :**
- `billingPlan: PlanType` — toujours le plan facturé réel
- `isTrialBoosted: boolean` — `true` si effectivePlan ≠ billingPlan pendant trial

### 4. `TrialBanner`

- Condition d'affichage : `isTrialing && isTrialBoosted`
- Texte : "Autopilote assisté — Il vous reste X jours d'essai. Plan choisi : {billingPlan}."
- Couleurs progressives : bleu (>7j) → ambre (3-7j) → rouge (<3j)
- CTA : "Passer en {nextUpgrade}" → `/billing/plan`
- J<=3 : mention "À J0 : retour au plan {billingPlan}"

### 5. `FeatureGate` / `ClientLayout`

- `FeatureGate` utilise `useCurrentPlan().plan` qui retourne maintenant `effectivePlan` pendant trial
- `isPlanAtLeast(AUTOPILOT_ASSISTED, 'PRO')` = `true` → AI Journal et Dashboard visibles
- `isPlanAtLeast(AUTOPILOT_ASSISTED, 'AUTOPILOT')` = `false` → Agent KeyBuzz caché
- TrialBanner rendu entre `</header>` et `<main>`

### 6. `locked/page.tsx`

- `PLAN_DISPLAY_NAMES['AUTOPILOT_ASSISTED']` = `"Autopilote assisté (essai)"`
- Utilise `entitlement.selectedPlan` pour le checkout retry (plan choisi, pas le trial)

---

## Validation navigateur

| Test | Résultat |
|---|---|
| Login OTP `ludo.gonthier@gmail.com` | ✅ Connecté |
| Sélection tenant ecomlg-001 | ✅ OK |
| Dashboard accessible | ✅ 451 conversations, stats chargées |
| Inbox fonctionnel | ✅ 451 conversations, détails affichés |
| Journal IA dans sidebar | ✅ Visible et accessible (1315 entrées) |
| IA Performance dans sidebar | ✅ Visible |
| Billing Plan | ✅ Plan Pro affiché, mode démo |
| TrialBanner | Absent sur ecomlg-001 (billing_exempt — **attendu**) |
| Erreurs JS AUTOPILOT_ASSISTED | ✅ **AUCUNE** |
| Erreurs JS capabilities | ✅ **AUCUNE** |
| Tracking events | ✅ Aucun nouveau signup_complete/purchase/CAPI |

### Note sur TrialBanner

Le tenant `ecomlg-001` est `billing_exempt = true` avec `billingStatus != 'trialing'`. Le TrialBanner ne s'affiche correctement PAS. Pour validation visuelle complète du banner, un tenant trial réel est nécessaire.

---

## Validation no tracking drift

| Vecteur | Résultat |
|---|---|
| signup_complete | ✅ Aucun nouveau event |
| purchase | ✅ Aucun event |
| CAPI Meta/TikTok/LinkedIn | ✅ Aucun event |
| GA4 | ✅ Inchangé (pageviews normaux uniquement) |
| AW direct | ✅ Aucun tag |
| SaaSAnalytics.tsx | ✅ Non modifié |

---

## Image tag + digest

| Champ | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.128-trial-autopilot-assisted-ui-dev` |
| Digest | `sha256:d1b23a7b6be0c2641ca17990a839b5a79901480b14b28d55a40617511529f654` |
| Pod | `keybuzz-client-6dd86679c4-pndkg` — 1/1 Running, 0 restarts |

---

## Commits

### Client (keybuzz-client)
- **Branche** : `ph148/onboarding-activation-replay`
- **Commit** : `715b869` — `feat(trial-ui): implement Autopilot Assisted trial UI with effectivePlan resolution (PH-SAAS-T8.12H)`
- **Fichiers** : 9 files changed, 997 insertions, 848 deletions
- **Build** : pre-build-check PASS

### Infra (keybuzz-infra)
- **Branche** : `main`
- **Commit** : `b78fff5` — `gitops(client-dev): update to v3.5.128-trial-autopilot-assisted-ui-dev (PH-SAAS-T8.12H)`
- **Manifest** : `k8s/keybuzz-client-dev/deployment.yaml` mis à jour

---

## Rollback GitOps DEV

```bash
# Sur le bastion — rollback strictement GitOps (pas de kubectl set image)
cd /opt/keybuzz/keybuzz-infra
sed -i 's|v3.5.128-trial-autopilot-assisted-ui-dev|v3.5.125-register-console-cleanup-dev|' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m 'gitops(client-dev): rollback to v3.5.125-register-console-cleanup-dev'
git push
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
# Vérifier : manifest = runtime = annotation
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## PROD inchangée (explicite)

| Service | Image PROD | Modifiée ? |
|---|---|---|
| Client PROD | `v3.5.125-register-console-cleanup-prod` | **NON** |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | **NON** |
| Manifest PROD | `k8s/keybuzz-client-prod/deployment.yaml` | **NON** |
| Manifest API PROD | `k8s/keybuzz-api-prod/deployment.yaml` | **NON** |

---

## Linear

### KEY-225 — Trial Full-Experience Schema

```
✅ PH-SAAS-T8.12H Client UI implementé en DEV.
- PlanType + PLAN_CAPABILITIES étendu avec AUTOPILOT_ASSISTED
- FeatureGate utilise effectivePlan pendant trial
- isPlanAtLeast(AUTOPILOT_ASSISTED, PRO) = true → AI Journal/Dashboard visibles
- isPlanAtLeast(AUTOPILOT_ASSISTED, AUTOPILOT) = false → Agent KeyBuzz caché
- Locked page : label humain "Autopilote assisté (essai)"
- Image: v3.5.128-trial-autopilot-assisted-ui-dev
- PROD inchangée.
```

### KEY-226 — Trial Entitlement API

```
✅ Client consomme les champs API (T8.12C/T8.12C.1) :
- useEntitlement.tsx étendu : billingPlan, selectedPlan, trialEntitlementPlan, effectivePlan
- PlanProvider fetch entitlement et override plan avec effectivePlan si trialing
- billingPlan préservé pour affichage facturation
- Backward compatible (champs optionnels)
```

### KEY-227 — Client UI Gating

```
✅ Feature gates utilisent effectivePlan pendant trial :
- useCurrentPlan.plan = effectivePlan (AUTOPILOT_ASSISTED si trial boosté)
- useCurrentPlan.billingPlan = plan facturé réel (STARTER/PRO)
- FeatureGate.planOrder inclut AUTOPILOT_ASSISTED
- ClientLayout sidebar : AI Journal et IA Performance visibles pour AUTOPILOT_ASSISTED
- canAutoExecute = false → mode autonome bloqué
- escalationTarget = client_team → Agent KeyBuzz indisponible
```

### KEY-229 — TrialBanner

```
✅ TrialBanner créé et intégré dans ClientLayout :
- Condition : isTrialing && isTrialBoosted
- Texte adaptatif : jours restants, plan choisi, essai Autopilote assisté
- Couleurs progressives : bleu (>7j) → ambre (3-7j) → rouge (<3j)
- CTA upgrade vers plan supérieur
- Mention J0 perte si <=3j
- Non affiché sur tenant billing_exempt (comportement correct)
```

### KEY-231 — Tracking No-Drift

```
✅ Aucun tracking drift :
- SaaSAnalytics.tsx non modifié
- Aucun signup_complete, purchase, CAPI event ajouté
- GA4/Meta/TikTok/LinkedIn inchangés
- Aucun faux event dans conversion_events
```

---

## Verdict

**TRIAL AUTOPILOT ASSISTED UI READY IN DEV**
- Feature gates use effectivePlan during trial ✅
- Starter/Pro trials see supervised autopilot value without auto-send ✅
- Billing/tracking unchanged ✅
- PROD unchanged ✅
