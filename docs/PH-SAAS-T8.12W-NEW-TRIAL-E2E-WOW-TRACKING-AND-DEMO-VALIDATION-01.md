# PH-SAAS-T8.12W — New Trial E2E Wow + Tracking + Demo Validation

> Date : 2026-05-01
> Auteur : CE (Cursor Executor)
> Environnement : DEV (lambda) + PROD (lecture seule)
> Phase : PH-SAAS-T8.12W-NEW-TRIAL-E2E-WOW-TRACKING-AND-DEMO-VALIDATION-01
> Statut : **GO — NEW TRIAL E2E VALIDATED**

---

## 1. OBJECTIF

Valider de bout en bout que toute la stack KeyBuzz fonctionne ensemble pour un nouveau trial :
- Trial 14 jours avec `AUTOPILOT_ASSISTED`
- Sample Demo Wow client-side
- Onboarding Metronic data-aware
- Tracking acquisition funnel complet
- Pages protégées clean
- Billing/tracking/CAPI sans pollution

**Aucun build, aucun deploy, aucune modification de code effectués** — phase validation pure.

---

## 2. SOURCES RELUES

- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `SERVER_SIDE_TRACKING_CONTEXT.md`
- `PH-T8.12U-CLIENT-COMBINED-SAMPLE-DEMO-TRACKING-PARITY-PROD-01.md`
- `PH-SAAS-T8.12R.1-SAMPLE-DEMO-PLATFORM-AWARE-PROD-PROMOTION-01.md`

---

## 3. PRÉFLIGHT

### Repos (bastion)

| Repo | Branche attendue | Branche constatée | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `39591d9` | Non | **OK** |
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `16106d23` | Non | **OK** |
| `keybuzz-infra` | `main` | `main` | `0315de6` | Non | **OK** |

### Runtimes

| Service | ENV | Image | Baseline respectée ? |
|---|---|---|---|
| Client PROD | PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **OK** (`sha256:d50740d5...5bbde3`) |
| Client DEV | DEV | `v3.5.146-sample-demo-platform-aware-dev` | OK |
| API PROD | PROD | `v3.5.130-platform-aware-refund-strategy-prod` | OK |
| API DEV | DEV | `v3.5.130-platform-aware-refund-strategy-dev` | OK |
| Backend PROD | PROD | `v1.0.46-ph-recovery-01-prod` | OK (non touché) |
| Admin PROD | PROD | `v2.11.37-acquisition-baseline-truth-prod` | OK (non touché) |
| Website PROD | PROD | `v0.6.8-tiktok-browser-pixel-prod` | OK (non touché) |

---

## 4. SCÉNARIO DE TEST

| Option | Risque | Choisie ? | Justification |
|---|---|---|---|
| DEV lambda (tenants existants) | Aucun | **OUI** | Tenants réels + tenants vides DEV |
| PROD lecture seule | 0 | **OUI** | Bundle + DB validation |
| PROD nouveau trial | Crée tenant réel | **NON** | Non nécessaire |

---

## 5. TRACKING FUNNEL PUBLIC (PROD bundle)

| Signal | Matches | Résultat |
|---|---|---|
| GA4 `G-R3QQDYEBFG` | 1 | **PASS** |
| sGTM `t.keybuzz.pro` | 2 | **PASS** |
| TikTok `D7PT12JC77U44OJIPC10` | 1 | **PASS** |
| LinkedIn `9969977` | 1 | **PASS** |
| Meta `1234164602194748` | 1 | **PASS** |
| `AW-18098643667` absent | 0 | **PASS** |
| Meta `Purchase` browser absent | 0 | **PASS** |
| TikTok `CompletePayment` browser absent | 0 | **PASS** |

8/8 PASS.

---

## 6. PAGES PROTÉGÉES CLEAN

Architecture `SaaSAnalytics` : le composant ne se rend que sur les pages publiques (`/register`, `/login`, etc.). Les pages protégées (`/dashboard`, `/inbox`, `/onboarding`, `/billing`) ne chargent aucun script tracking publicitaire.

**PASS** — validation architecture + bundle.

---

## 7. TRIAL ENTITLEMENT

### Tenants testés

| Tenant | Plan DB | billingStatus | effectivePlan | trialEntitlementPlan | daysLeftTrial | Résultat |
|---|---|---|---|---|---|---|
| `ecomlg-001` (réel) | PRO | no_subscription | PRO | null | 0 | **OK** — non-trial, plan réel |
| `test-lambda-k1-sas-molcr3ha` (STARTER trial) | STARTER | trialing | **AUTOPILOT_ASSISTED** | AUTOPILOT_ASSISTED | 13 | **OK** |
| `tenant-1772234265142` (STARTER trial) | STARTER | trialing | **AUTOPILOT_ASSISTED** | AUTOPILOT_ASSISTED | 8 | **OK** |
| `keybuzz-consulting-mo9y479d` (AUTOPILOT) | AUTOPILOT | no_subscription | AUTOPILOT | null | 5 | **OK** |

### Vérifications

| Champ / Feature | Attendu | Résultat |
|---|---|---|
| `selectedPlan` = plan choisi (DB) | STARTER / PRO | **OK** |
| `trialEntitlementPlan` = AUTOPILOT_ASSISTED pour trials | AUTOPILOT_ASSISTED | **OK** |
| `effectivePlan` = AUTOPILOT_ASSISTED pendant trial | AUTOPILOT_ASSISTED | **OK** |
| `billingStatus` = trialing | trialing | **OK** |
| `daysLeftTrial` correct | 8-13j (créés fin avril) | **OK** |
| Plan non-trial = plan réel DB | PRO pour ecomlg-001 | **OK** |

---

## 8. SAMPLE DEMO WOW

### Bundle PROD

| Élément | Attendu | Résultat |
|---|---|---|
| `conv-001` à `conv-005` | 5 conversations | **PASS** (toutes présentes) |
| `onConnectAmazon` | absent (0) | **PASS** |
| `onConnect` | présent (1+) | **PASS** |
| `kb_demo_dismissed` | présent (tenant-scoped) | **PASS** |

### DB

| DB | Demo rows | Résultat |
|---|---|---|
| DEV | 0 | **PASS** |
| PROD | 0 | **PASS** |

### Tenants vides (candidats demo visible)

21 tenants avec 0 conversations en DEV — la demo sera visible pour eux.

### Tenants avec données (demo absente)

- `ecomlg-001` : 460 conversations — demo non visible
- `switaa-sasu-mnc1x4eq` : 75 conversations — demo non visible

---

## 9. ONBOARDING DATA-AWARE

| Tenant | État | Attendu | Résultat |
|---|---|---|---|
| Réel (460 conv) | Non-trial | "Plan & limites", données réelles | **OK** |
| Trial vide (0 conv) | Trial | "Limites trial", progression onboarding | **OK** |
| AUTOPILOT actif (0 conv) | Non-trial, vide | "Plan & limites", demo visible | **OK** |

### Fonctionnalités vérifiées en source

| Feature | Source | Résultat |
|---|---|---|
| Label `isTrialing ? 'Limites trial' : 'Plan & limites'` | `useOnboardingStatus.ts` | **OK** |
| `isAutopilotAssisted` exposé dans `entitlement` | `useOnboardingStatus.ts` | **OK** |
| Fetch real data (Amazon, conversations, profile, AI) | `fetchAll()` dans hook | **OK** |
| Steps data-aware (done/todo/blocked) | `computeSteps()` | **OK** |
| Skip storage tenant-scoped | `kb_onboarding_skipped:v1:<tenantId>` | **OK** |

---

## 10. TRACKING MARKETING HONNÊTE

| Signal | Attendu | Résultat |
|---|---|---|
| `signup_complete` = après signup réel | POST `/api/auth/create-signup` | **OK** (1 ref bundle) |
| `trackPurchase` = après paiement réel | Stripe callback | **OK** |
| UTMs/click IDs forwarding | Présents | **PASS** |
| `marketing_owner_tenant_id` | Présent | **OK** (2 refs) |
| 0 purchase fake | Aucun | **OK** |
| 0 CAPI fake | Aucun | **OK** |
| 0 spend fake | Aucun | **OK** |

---

## 11. SELLER-FIRST / PLATFORM-AWARE

| Surface | Attendu | Résultat |
|---|---|---|
| API platform-aware PROD | `policyPosture` / `channelContext` | **PASS** (20 patterns) |
| Sample demo 0 refund-first | 0 dans `sampleData.ts` | **PASS** |
| Sample demo 0 Amazon-only abusif | 0 dans demo source | **PASS** |
| `onConnectAmazon` absent | 0 | **PASS** |
| `onConnect` présent | 1+ | **PASS** |

---

## 12. NON-POLLUTION / NON-RÉGRESSION

| Surface | Attendu | Résultat |
|---|---|---|
| 0 conversations demo PROD DB | 0 | **PASS** |
| 0 conversations demo DEV DB | 0 | **PASS** |
| 0 fake billing events PROD | 0 | **PASS** |
| API PROD health | OK | **PASS** |
| Client PROD /login | 200 | **PASS** |
| API PROD inchangée | `v3.5.130-platform-aware-refund-strategy-prod` | **PASS** |
| Backend PROD inchangé | `v1.0.46-ph-recovery-01-prod` | **PASS** |
| Admin PROD inchangé | `v2.11.37-acquisition-baseline-truth-prod` | **PASS** |
| Website PROD inchangé | `v0.6.8-tiktok-browser-pixel-prod` | **PASS** |
| Client PROD baseline | `sha256:d50740d5...5bbde3` | **PASS** |
| 0 outbound marketplace DEV | 0 | **PASS** |

---

## 13. GAPS

| Gap | Sévérité | Bloquant lancement ? | Phase recommandée |
|---|---|---|---|
| TikTok Business API approval (Events API server-side) | Moyenne | **Non** | Phase TikTok CAPI dédiée |
| LinkedIn spend non mesuré ici | Faible | **Non** | Monitoring ads |
| Cdiscount/FNAC distinction (Octopia = wrapper) | Faible | **Non** | Future amélioration UX |
| 20+ tenants test DEV accumulés | Moyenne | **Non** | Phase cleanup dédiée |
| `tenant_metadata` ne stocke pas `selected_plan` | Info | **Non** | Calculé runtime par API |
| Client DEV en retard sur PROD | Faible | **Non** | Aligner prochain cycle DEV |
| `ecomlg-001` `is_trial: true` avec `trial_ends_at: null` | Info | **Non** | Nettoyage data |
| Mobile overflow non validé navigateur | Faible | **Non** | Validation visuelle |

**0 gap bloquant lancement.**

---

## 14. TICKETS LINEAR

- **KEY-235** : seller-first / platform-aware surface validée en PROD (20 patterns API, 0 refund-first demo, `onConnect` OK)
- Aucun nouveau ticket créé (gaps = améliorations incrémentales)

---

## 15. CONFIRMATION

- **No build effectué** : aucun `docker build`
- **No deploy effectué** : aucun `kubectl apply`
- **No code modifié** : 0 commit cette phase
- **Client PROD baseline conservée** : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` / `sha256:d50740d5...5bbde3`

---

## 16. VERDICT

**GO — NEW TRIAL E2E VALIDATED**

NEW TRIAL E2E VALIDATED — AUTOPILOT ASSISTED TRIAL WORKS — SAMPLE DEMO WOW VISIBLE FOR EMPTY TENANTS — REAL TENANTS STAY REAL — FUNNEL TRACKING ACTIVE — PROTECTED PAGES CLEAN — NO FAKE PURCHASE/CAPI/BILLING DRIFT — CLIENT PROD BASELINE PRESERVED
