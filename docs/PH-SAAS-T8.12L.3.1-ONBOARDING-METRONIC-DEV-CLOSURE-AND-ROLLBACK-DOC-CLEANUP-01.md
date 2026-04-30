# PH-SAAS-T8.12L.3.1 — Onboarding Metronic DEV Closure & Rollback Doc Cleanup

> **Phase** : PH-SAAS-T8.12L.3.1-ONBOARDING-METRONIC-DEV-CLOSURE-AND-ROLLBACK-DOC-CLEANUP-01
> **Date** : 2026-04-30
> **Type** : Correction DEV post L.3 + validation lambda + conformité rapport
> **Priorité** : P0 avant promotion PROD
> **Environnement** : DEV uniquement — PROD strictement inchangée

---

## 1. Objectif

Clôturer proprement PH-SAAS-T8.12L.3 avant toute promotion PROD :

- Corriger la documentation rollback L.3 (supprimer les procédures impératives interdites)
- Résoudre le gap G1 profil `companyName`
- Corriger le layout mobile 390px (G2)
- Valider visuellement le tenant trial lambda (G3)
- Confirmer `/onboarding` candidat PROD après correction
- Ne toucher ni PROD, ni billing, ni tracking, ni CAPI

---

## 2. Sources relues

| Document | Chemin | Relu |
|---|---|---|
| L — Wizard Activation | `keybuzz-infra/docs/PH-SAAS-T8.12L-ONBOARDING-WIZARD-ACTIVATION-DEV-01.md` | Oui |
| L.1 — Truth Audit | `keybuzz-infra/docs/PH-SAAS-T8.12L.1-ONBOARDING-DATA-AWARE-TRUTH-AUDIT-AND-REDESIGN-SPEC-01.md` | Oui |
| L.2 — Read Model | `keybuzz-infra/docs/PH-SAAS-T8.12L.2-ONBOARDING-READ-MODEL-AND-INBOUND-TRUTH-DEV-01.md` | Oui |
| L.3 — Metronic UI | `keybuzz-infra/docs/PH-SAAS-T8.12L.3-ONBOARDING-METRONIC-DATA-AWARE-UI-DEV-01.md` | Oui |
| Trial WOW Context | `keybuzz-infra/docs/AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md` | Oui |
| CE Prompting Standard | `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` | Oui |
| Rules & Risks | `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` | Oui |

---

## 3. Preflight

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `fix(onboarding): responsive mobile + profile mapping` | Non | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | (lecture seule) | Non | OK |
| `keybuzz-infra` | `main` | `main` | `9f06a98 GitOps: Client DEV v3.5.137` | Non | OK |

### Runtime DEV/PROD

| Service | Manifest | Runtime | Verdict |
|---|---|---|---|
| Client DEV | `v3.5.137-onboarding-mobile-fix-dev` | `v3.5.137-onboarding-mobile-fix-dev` | OK |
| API DEV | `v3.5.127-trial-autopilot-assisted-dev` | `v3.5.127-trial-autopilot-assisted-dev` | OK |
| Client PROD | `v3.5.131-trial-effectiveplan-client-prod` | `v3.5.131-trial-effectiveplan-client-prod` | OK — INCHANGÉ |
| API PROD | `v3.5.128-trial-autopilot-assisted-prod` | `v3.5.128-trial-autopilot-assisted-prod` | OK — INCHANGÉ |

---

## 4. Correction rapport L.3 (ÉTAPE 1)

### Problème

La section "10. Rollback" du rapport L.3 contenait des procédures impératives interdites par les règles GitOps.

### Correction

Le bloc rollback a été remplacé par une procédure GitOps stricte :

```
1. Modifier deployment.yaml (image tag)
2. git add && git commit
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status
```

### Vérification post-correction

Vérification par recherche exhaustive des commandes interdites dans les rapports L.3 et L.3.1 : **0 occurrence** après nettoyage L.3.2. Conforme.

---

## 5. Résolution Gap G1 — Profil companyName (ÉTAPE 2)

### Diagnostic

L'API `/tenant-context/profile/ecomlg-001` retourne bien `companyName: "eComLG"`, mais enveloppé dans un objet `profile` :

```json
{
  "profile": {
    "companyName": "eComLG",
    "shopName": null,
    "companyCountry": "FR",
    "supportEmail": "contact@ecomlg.com"
  }
}
```

Le hook `useOnboardingStatus.ts` cherchait `data.companyName` au lieu de `data.profile.companyName`.

### Fix

Fichier : `keybuzz-client/src/features/onboarding/hooks/useOnboardingStatus.ts`

```typescript
// Avant (bug)
const name = data?.companyName || data?.shopName || data?.name || null;

// Après (fix)
const name = data?.profile?.companyName || data?.companyName || data?.shopName || data?.name || null;
```

### Validation navigateur

- Tenant `ecomlg-001` : **"Profil entreprise eComLG"** avec badge **"Terminé"** — VALIDÉ
- Tenant `tenant-1772234265142` (Essai) : **"Profil entreprise Essai"** avec badge **"Terminé"** — VALIDÉ

---

## 6. Résolution Gap G2 — Mobile 390px (ÉTAPE 3)

### Diagnostic

Le stepper latéral avec `flex-shrink-0` empêchait le `flex-col` de stacker correctement sur mobile.

### Fix CSS

Fichier : `keybuzz-client/src/features/onboarding/components/OnboardingDataAware.tsx`

| Élément | Avant | Après |
|---|---|---|
| Container principal | `px-4 py-8` | `px-3 sm:px-4 py-4 sm:py-8` |
| Titre h1 | `text-2xl` | `text-lg sm:text-2xl` |
| Stepper sidebar | `lg:w-72 flex-shrink-0` | `w-full lg:w-72 lg:flex-shrink-0` |
| Flex container | `flex flex-col lg:flex-row gap-6` | `flex flex-col lg:flex-row gap-4 sm:gap-6 overflow-hidden` |
| Stepper buttons | `gap-3 px-4 py-3` | `gap-2 sm:gap-3 px-3 py-2.5 sm:px-4 sm:py-3` |
| Content panel | `p-6` | `p-4 sm:p-6` |
| Icon box | `w-8 h-8` | `w-7 h-7 sm:w-8 sm:h-8` |

### Statut validation

Les CSS responsive sont appliquées et déployées. La validation visuelle au viewport 390px n'a **pas pu être effectuée** par l'outil d'automatisation navigateur (le `browser_resize` ne redimensionne pas effectivement le viewport de rendu). **Validation manuelle sur Chrome DevTools requise avant promotion PROD.**

---

## 7. Résolution Gap G3 — Trial Lambda (ÉTAPE 4)

### Tenant testé

| Champ | Valeur |
|---|---|
| Tenant ID | `tenant-1772234265142` |
| Nom | Essai |
| Plan | STARTER |
| Trial | Actif — 10 jours restants |
| Accès via | `ludo.gonthier@gmail.com` (admin) |

### Validation navigateur

| Élément | Attendu | Résultat |
|---|---|---|
| TrialBanner | Visible | **OK** — "Autopilote assisté — Il vous reste **10 jours** d'essai. Plan choisi : Starter." |
| AUTOPILOT_ASSISTED | Affiché | **OK** — "Votre expérience : Autopilote assisté" |
| CTA Autopilot | Présent | **OK** — "Passer à Autopilot →" (2 occurrences) |
| Auto-send indisponible | Mentionné | **OK** — "Envoi automatique des réponses IA" (verrouillé) |
| Agent KeyBuzz indisponible | Mentionné | **OK** — "Agent KeyBuzz autonome" (verrouillé) |
| Validation humaine | Mentionné | **OK** — "Validation humaine obligatoire avant envoi" |
| Steps runtime | Calculés | **OK** — 38% (3/8 done) |
| Profil entreprise | Nom affiché | **OK** — "Profil entreprise Essai" + "Terminé" |
| Étapes restantes | Cohérentes | **OK** — Amazon "Optionnel", Inbound "Bloqué", Messages "À faire", IA "À faire" |

---

## 8. Fichiers modifiés (ÉTAPE 5)

| Fichier | Changement | Pourquoi | Risque |
|---|---|---|---|
| `keybuzz-client/src/features/onboarding/hooks/useOnboardingStatus.ts` | Ajout `data?.profile?.companyName` dans fetchTenantProfile | G1 — L'API wrap dans `profile` | Faible — fallback chaîné |
| `keybuzz-client/src/features/onboarding/components/OnboardingDataAware.tsx` | CSS responsive Tailwind | G2 — Mobile 390px | Faible — breakpoints SM/LG |
| `keybuzz-infra/docs/PH-SAAS-T8.12L.3-ONBOARDING-METRONIC-DATA-AWARE-UI-DEV-01.md` | Rollback GitOps strict | Conformité doc | Nul |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image v3.5.137 | GitOps deploy | Faible — DEV only |

---

## 9. Builds & Deploys DEV

### Build 1 : v3.5.136-onboarding-metronic-closure-dev

- Fix G1 (profil mapping) + fix G2 initial
- Commit client : `fix(onboarding): profile companyName mapping + responsive (PH-SAAS-T8.12L.3.1)`
- Build sur bastion depuis clone propre
- Deploy GitOps : manifest → commit → push → apply

### Build 2 : v3.5.137-onboarding-mobile-fix-dev

- Fix G2 raffiné (sidebar `w-full lg:flex-shrink-0`, `overflow-hidden`)
- Commit client : `fix(onboarding): responsive mobile + profile mapping (PH-SAAS-T8.12L.3.1)`
- Build sur bastion depuis clone propre
- Deploy GitOps : manifest → commit → push → apply

### Commits infra

```
9f06a98 GitOps: Client DEV v3.5.137-onboarding-mobile-fix-dev (PH-SAAS-T8.12L.3.1)
ddc375a GitOps: Client DEV v3.5.136-onboarding-metronic-closure-dev (PH-SAAS-T8.12L.3.1)
```

### Runtime vérifié

```
Manifest  : v3.5.137-onboarding-mobile-fix-dev
Runtime   : v3.5.137-onboarding-mobile-fix-dev
Pod       : keybuzz-client-674dd6b478-69kw4  1/1 Running
```

---

## 10. Non-régression (ÉTAPE 8)

| Surface | Attendu | Résultat |
|---|---|---|
| Dashboard | KPIs, SLA, canaux, activité | **OK** — 459 conv, 393 SLA, 4 canaux |
| Inbox | Conversations, tri-pane | **OK** — Chargé avec conversations |
| Onboarding eComLG | Data-aware, profil "eComLG" | **OK** — "Prêt !", profil affiché |
| Onboarding trial | AUTOPILOT_ASSISTED, TrialBanner | **OK** — 10j trial, CTA Autopilot |
| Billing | Plan Pro 297€/mois | **OK** — Entitlements corrects |
| Login/session | Authentifié, multi-tenant | **OK** — Switch tenant fonctionnel |
| API health DEV | `{"status":"ok"}` | **OK** |
| API health PROD | `{"status":"ok"}` | **OK** |
| Client pod DEV | Running | **OK** — 1/1 Running |
| Runtime PROD client | `v3.5.131-trial-effectiveplan-client-prod` | **OK — INCHANGÉ** |
| Runtime PROD API | `v3.5.128-trial-autopilot-assisted-prod` | **OK — INCHANGÉ** |

---

## 11. Tracking / Billing / CAPI — Invariants

| Vérification | Résultat |
|---|---|
| `signup_complete` envoyé | **NON** — Aucun signup réel |
| `purchase` envoyé | **NON** — Aucun achat |
| CAPI déclenché | **NON** |
| Stripe modifié | **NON** |
| Secret exposé | **NON** |
| Hardcodage tenant/email/plan | **NON** |
| PROD touchée | **NON** |

---

## 12. Gaps restants (ÉTAPE 9)

| Gap | Statut | Prochaine action |
|---|---|---|
| G1 — Profil companyName | **RÉSOLU** | — |
| G2 — Mobile 390px | **CSS APPLIQUÉ, validation manuelle requise** | Validation Chrome DevTools 390px/430px avant L.4 |
| G3 — Trial lambda | **RÉSOLU** | — |
| G4 — Ancien wizard | **HORS SCOPE** | Nettoyage en phase ultérieure |

---

## 13. Rollback GitOps strict

```bash
# Rollback vers v3.5.136 (build L.3.1 intermédiaire)
# 1. Modifier keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml :
#    image: ghcr.io/keybuzzio/keybuzz-client:v3.5.136-onboarding-metronic-closure-dev
# 2. git add && git commit -m "Rollback: Client DEV v3.5.136"
# 3. git push origin main
# 4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
# 5. kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# Rollback vers v3.5.135 (L.3 baseline)
# 1. Modifier deployment.yaml :
#    image: ghcr.io/keybuzzio/keybuzz-client:v3.5.135-onboarding-metronic-fix-dev
# 2. git add && git commit -m "Rollback: Client DEV v3.5.135"
# 3. git push origin main
# 4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
# 5. kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 14. Verdict

### **GO PARTIEL**

**Critères GO remplis :**

- Rapport L.3 ne contient plus aucune procédure impérative interdite (nettoyé en L.3.1)
- G1 résolu : profil `companyName` correctement mappé via `data.profile.companyName`
- G3 résolu : tenant trial "Essai" valide AUTOPILOT_ASSISTED, TrialBanner, CTA, limites
- Non-régression complète : dashboard, inbox, billing, API health, session
- 0 tracking / 0 billing / 0 CAPI drift
- PROD strictement inchangée (client `v3.5.131`, API `v3.5.128`)

**Gap résiduel :**

- G2 : CSS mobile responsive appliqué et déployé, mais validation visuelle 390px impossible par outil automatisé. Les CSS sont conformes aux best practices Tailwind (`w-full lg:w-72 lg:flex-shrink-0`, responsive padding, `overflow-hidden`). **Validation manuelle Chrome DevTools requise avant promotion PROD.**

**Condition promotion L.4 / PROD :**

- Valider manuellement le mobile 390px + 430px sur Chrome DevTools
- Si conforme → GO PROD
- Si écarts → micro-fix CSS avant PROD

---

## 15. Rapport

```
keybuzz-infra/docs/PH-SAAS-T8.12L.3.1-ONBOARDING-METRONIC-DEV-CLOSURE-AND-ROLLBACK-DOC-CLEANUP-01.md
```
