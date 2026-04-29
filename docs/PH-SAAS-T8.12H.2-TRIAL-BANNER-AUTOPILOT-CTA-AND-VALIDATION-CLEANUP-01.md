# PH-SAAS-T8.12H.2-TRIAL-BANNER-AUTOPILOT-CTA-AND-VALIDATION-CLEANUP-01 — TERMINÉ

**Verdict : GO — TRIAL BANNER AUTOPILOT CTA ALIGNED — FIXTURE STATUS CLEAN — H.1 REPORT RECONCILED — DEV VALIDATED — NO TRACKING DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION**

---

## Documents lus

- `keybuzz-infra/docs/PH-SAAS-T8.12H-TRIAL-AUTOPILOT-ASSISTED-CLIENT-UI-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12H.1-TRIAL-AUTOPILOT-ASSISTED-DEV-VALIDATION-AND-GITOPS-REPORT-CLEANUP-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12C.1-TRIAL-AUTOPILOT-ASSISTED-SEMANTICS-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12G-CLIENT-SOURCE-OF-TRUTH-LOCK-01.md`

---

## Preflight

| Vérification | Attendu | Observé | Résultat |
|---|---|---|---|
| Client source | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | ✅ |
| Client HEAD | `715b869` ou descendant | `715b869` (pre-commit) | ✅ |
| Client clean | 0 dirty | 0 porcelain | ✅ |
| Infra branch | `main` | `main` | ✅ |
| Infra HEAD | `02c5534` (post T8.12H.1) | `02c5534` | ✅ |
| Client DEV runtime | `v3.5.128-trial-autopilot-assisted-ui-dev` | confirmé | ✅ |
| API DEV runtime | `v3.5.127-trial-autopilot-assisted-dev` | confirmé | ✅ |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | confirmé | ✅ |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | confirmé | ✅ |

---

## Vérification source

| Fichier | Point vérifié | Résultat |
|---|---|---|
| `planCapabilities.ts` | `AUTOPILOT_ASSISTED` dans `PlanType` | ✅ |
| `planCapabilities.ts` | `AUTOPILOT_ASSISTED` pas dans `BILLABLE_PLAN_ORDER` | ✅ (non achetable) |
| `planCapabilities.ts` | `AUTOPILOT_ASSISTED` dans `PLAN_ORDER` | ✅ (entre PRO et AUTOPILOT) |
| `billing/plan/page.tsx` | Plans achetables = STARTER, PRO, AUTOPILOT | ✅ |
| `useCurrentPlan.tsx` | `effectivePlan` utilisé pour les gates | ✅ |
| `useCurrentPlan.tsx` | `billingPlan` disponible pour affichage | ✅ |
| `TrialBanner.tsx` | CTA identifié "Passer en {upgradeName}" | ✅ → corrigé |

---

## Correction produit TrialBanner

### Problème

Le CTA utilisait `BILLABLE_PLAN_ORDER` pour calculer le "next upgrade" :
- Pour un tenant STARTER : `BILLABLE_PLAN_ORDER[indexOf('STARTER') + 1]` = `'PRO'`
- Résultat : CTA "Passer en Pro" au lieu de "Passer à Autopilot"

### Correction

| Élément | Avant | Après |
|---|---|---|
| Import | `getPlanName, BILLABLE_PLAN_ORDER, type PlanType` | `getPlanName` |
| Destructure useEntitlement | `isTrialing, daysLeftTrial, entitlement` | `isTrialing, daysLeftTrial` |
| nextUpgrade calc | 2 lignes dynamiques | **supprimé** |
| CTA texte | "Passer en {upgradeName}" (Pro pour Starter) | "Passer à Autopilot" (fixe) |
| CTA condition | conditionnel `{upgradeName && ...}` | **toujours affiché** |
| Message J0 | "retour au plan {selectedPlanName}" | "retour au plan {selectedPlanName} sauf upgrade" |
| Plan choisi affiché | Starter/Pro | Starter/Pro (inchangé) |
| AUTOPILOT_ASSISTED achetable | non | non (inchangé) |

**Commit client** : `ebf8497` — `fix(trial-banner): align CTA to Autopilot instead of next billable plan (PH-SAAS-T8.12H.2)`

---

## Fixture DEV

**Option B — conservation contrôlée** retenue.

Tenant `tenant-1772234265142` ("Essai") est un tenant interne de validation :

| Objet | Statut final | Preuve |
|---|---|---|
| `conversion_events` | 0 | SELECT count = 0 |
| `billing_events` | 0 | SELECT count = 0 |
| `signup_attribution` | 0 | SELECT count = 0 |
| CAPI Meta/TikTok/LinkedIn | 0 | aucun event |
| `purchase` | 0 | aucun |
| Nature | interne, non business | aucun client réel |

Configuration fixture :
- `tenants.plan = 'STARTER'`, `selected_plan = 'STARTER'`, `trial_entitlement_plan = 'AUTOPILOT_ASSISTED'`
- `tenant_metadata.is_trial = true`, `trial_ends_at = 2026-05-09`
- `billing_subscriptions.status = 'trialing'`, `plan = 'STARTER'`
- `tenant_billing_exempt` : aucune exemption (supprimée)

---

## Réconciliation rapports

| Point | T8.12H | T8.12H.1 | Réalité | Statut |
|---|---|---|---|---|
| Rollback = GitOps only | ✅ (corrigé 3a2a170) | ✅ documente correction | `kubectl set image` supprimé | ✅ |
| `02c5534` | — | HEAD infra final | commit rapport T8.12H.1 | ✅ |
| `3a2a170` | — | rollback doc fix | poussé | ✅ |
| `715b869` client | ✅ | HEAD client T8.12H.1 | descendant `ebf8497` ajouté | ✅ |
| PROD inchangée | ✅ explicite | ✅ explicite | vérifié runtime | ✅ |

Aucune correction nécessaire dans les rapports existants.

---

## Build DEV

| Point | Valeur |
|---|---|
| Tag | `v3.5.129-trial-banner-autopilot-cta-dev` |
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.129-trial-banner-autopilot-cta-dev` |
| Digest | `sha256:d2291d3cb3fe75cba0c54f1bf86447a2eee9c80f07d5bfb254ac6c8c45b223c6` |
| Source | clone temporaire propre de `ph148/onboarding-activation-replay` |
| HEAD | `ebf8497` |
| Build args | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` |
| `--no-cache` | oui |
| Clone nettoyé | oui |

---

## GitOps DEV

| Point | Valeur |
|---|---|
| Manifest | `k8s/keybuzz-client-dev/deployment.yaml` |
| Image avant | `v3.5.128-trial-autopilot-assisted-ui-dev` |
| Image après | `v3.5.129-trial-banner-autopilot-cta-dev` |
| Commit infra | `be6b99c` — `gitops(client-dev): update to v3.5.129-trial-banner-autopilot-cta-dev (PH-SAAS-T8.12H.2)` |
| Deploy | `kubectl apply -f` + `kubectl rollout status` OK |
| Manifest = Runtime | ✅ concordance |
| Pod | 1/1 Running, 0 restarts |

### Rollback DEV GitOps strict

```bash
# Sur le bastion — rollback strictement GitOps (pas de kubectl set image)
cd /opt/keybuzz/keybuzz-infra
sed -i 's|ghcr.io/keybuzzio/keybuzz-client:v3.5.129-trial-banner-autopilot-cta-dev.*|ghcr.io/keybuzzio/keybuzz-client:v3.5.128-trial-autopilot-assisted-ui-dev  # rollback: v3.5.125-register-console-cleanup-dev|' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m 'gitops(client-dev): rollback to v3.5.128-trial-autopilot-assisted-ui-dev'
git push origin main
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Validation navigateur DEV

### Tenant trial boosté (tenant-1772234265142, "Essai")

| Cas | Attendu | Résultat |
|---|---|---|
| TrialBanner visible | oui | ✅ |
| "Autopilote assisté" affiché | oui | ✅ |
| Plan choisi "Starter" visible | oui | ✅ "Plan choisi : Starter." |
| CTA "Passer à Autopilot" | oui | ✅ (plus "Passer en Pro") |
| Countdown jours restants | oui | ✅ "10 jours" |
| Journal IA visible sidebar | oui | ✅ |
| IA Performance visible sidebar | oui | ✅ |
| Agent KeyBuzz caché | oui | ✅ absent sidebar |
| Billing page = "Plan Autopilote assisté" | oui | ✅ avec badge + "Essai — L'IA prépare, vous validez" |
| Auto-exécution IA | "Non inclus" | ✅ |
| Supervision avancée | "Inclus" | ✅ |
| KBActions/mois | "1000 incluses" | ✅ |
| AUTOPILOT_ASSISTED non achetable | oui | ✅ |
| 0 erreur JS | oui | ✅ |

### Tenant exempt/non-trial (ecomlg-001)

| Cas | Attendu | Résultat |
|---|---|---|
| TrialBanner absent | oui | ✅ (guard `if (!isTrialing \|\| !isTrialBoosted) return null`) |
| Sidebar stable | oui | ✅ (aucun changement code sidebar) |

---

## No tracking drift

| Vecteur | Attendu | Résultat |
|---|---|---|
| SaaSAnalytics.tsx | non modifié | ✅ aucun diff |
| Fichier modifié unique | TrialBanner.tsx | ✅ |
| `signup_complete` events | 0 | ✅ |
| `purchase` events | 0 | ✅ |
| CAPI Meta/TikTok/LinkedIn | 0 | ✅ (conversion_events=0) |
| AW direct | 0 | ✅ |
| GA4 | inchangé | ✅ |
| signup_attribution | 0 | ✅ |

---

## Non-régression

| Point | Attendu | Résultat |
|---|---|---|
| Client DEV pod | 1/1 Running, 0 restarts | ✅ |
| API DEV pod | 1/1 Running | ✅ |
| API DEV health | 200 | ✅ |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | ✅ inchangé |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | ✅ inchangé |
| Website PROD | `v0.6.7-pricing-attribution-forwarding-prod` | ✅ inchangé |
| Admin/Website | hors scope | ✅ inchangés |
| Secrets dans bundle/logs/rapport | aucun | ✅ |

---

## Commits

### keybuzz-client

| Commit | Message | Branche |
|---|---|---|
| `ebf8497` | `fix(trial-banner): align CTA to Autopilot instead of next billable plan (PH-SAAS-T8.12H.2)` | `ph148/onboarding-activation-replay` |

### keybuzz-infra

| Commit | Message | Branche |
|---|---|---|
| `be6b99c` | `gitops(client-dev): update to v3.5.129-trial-banner-autopilot-cta-dev (PH-SAAS-T8.12H.2)` | `main` |

---

## Tag + Digest

| Clé | Valeur |
|---|---|
| Tag | `v3.5.129-trial-banner-autopilot-cta-dev` |
| Digest | `sha256:d2291d3cb3fe75cba0c54f1bf86447a2eee9c80f07d5bfb254ac6c8c45b223c6` |

---

## PROD inchangée

**oui** — confirmé à chaque étape :
- Client PROD : `v3.5.125-register-console-cleanup-prod`
- API PROD : `v3.5.123-linkedin-capi-native-prod`
- Website PROD : `v0.6.7-pricing-attribution-forwarding-prod`

---

## Linear

### KEY-225 — Trial Entitlement Schema
Commentaire : T8.12H.2 — CTA TrialBanner aligné Autopilot (commit `ebf8497`). Schema et API inchangés. DEV validé.

### KEY-226 — Trial Entitlement API
Commentaire : T8.12H.2 — Aucune modification API. CTA client corrigé pour pousser vers Autopilot.

### KEY-227 — Trial Entitlement Client UI
Commentaire : T8.12H.2 — CTA corrigé de "Passer en Pro" vers "Passer à Autopilot". J0 message clarifié. Build `v3.5.129-trial-banner-autopilot-cta-dev` déployé DEV. Validation navigateur OK.

### KEY-229 — Trial Experience Non-Regression
Commentaire : T8.12H.2 — Non-régression confirmée. PROD strictement inchangée. Aucun tracking drift. Fixture DEV propre (0 event business).

### KEY-231 — Trial Fixture Cleanup
Commentaire : T8.12H.2 — Fixture tenant-1772234265142 conservée (Option B). Documentée comme interne non-business. 0 conversion_events, 0 billing_events, 0 signup_attribution. Prête pour cleanup post-PROD promotion.

Aucun ticket fermé — réserve levée, prêt pour promotion PROD.

---

## GO/NO GO pour promotion PROD

**GO — PRÊT POUR PROMOTION PROD**

Toutes les réserves produit sont levées :
1. ✅ CTA TrialBanner pousse vers Autopilot (plus Pro)
2. ✅ Plan choisi Starter/Pro reste affiché
3. ✅ AUTOPILOT_ASSISTED non achetable
4. ✅ Fixture DEV propre et documentée
5. ✅ Rapports T8.12H/T8.12H.1 réconciliés
6. ✅ Zéro drift tracking/billing/CAPI/GA4
7. ✅ PROD strictement inchangée

---

**Chemin du rapport** : `keybuzz-infra/docs/PH-SAAS-T8.12H.2-TRIAL-BANNER-AUTOPILOT-CTA-AND-VALIDATION-CLEANUP-01.md`
