# PH-SAAS-T8.12C.1 — Trial Autopilot Assisté Semantics (DEV Only)

> Date : 2026-04-29
> Agent : CE SaaS
> Phase : PH-SAAS-T8.12C.1
> Tickets : KEY-225, KEY-226, KEY-230, KEY-231
> Verdict : **GO**

---

## 1. DOCUMENTS LUS

| Document | Statut |
|---|---|
| PH-SAAS-T8.12C-TRIAL-ENTITLEMENT-SCHEMA-AND-API-DEV-01.md | Lu |
| PH-SAAS-T8.12B-SAAS-SOURCE-OF-TRUTH-AND-TRIAL-WOW-READINESS-LOCK-01.md | Lu |
| PH-SAAS-T8.12A-SAAS-FEATURE-TRUTH-AUDIT-AND-TRIAL-WOW-CONTEXT-01.md | Lu |
| AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md | Lu |
| AI_MEMORY/RULES_AND_RISKS.md | Lu |

---

## 2. PREFLIGHT

| Item | Valeur | Status |
|---|---|---|
| Repo | `/opt/keybuzz/keybuzz-api` | OK |
| Branch | `ph147.4/source-of-truth` | OK |
| HEAD de départ | `3ad30a67` (from T8.12C) | OK |
| Git status | CLEAN (0 files) | OK |
| DEV runtime | `v3.5.126-trial-entitlement-dev` | OK |
| PROD runtime | `v3.5.123-linkedin-capi-native-prod` | OK |

---

## 3. CHOIX SÉMANTIQUE

### Ancienne sémantique (T8.12C)

```
trial_entitlement_plan = 'PRO'
```

Problème : confond le boost trial avec le plan PRO payé. Le client croit être en PRO, pas en "expérience assistée".

### Nouvelle sémantique (T8.12C.1)

```
trial_entitlement_plan = 'AUTOPILOT_ASSISTED'
```

Avantages :
- **Explicite** : jamais confondu avec AUTOPILOT payé ni PRO payé
- **Self-documenting** : le nom dit exactement ce que c'est
- **Pas d'enum contrainte** : PostgreSQL TEXT, PLAN_CAPABILITIES est un Record libre
- **Pas de flag supplémentaire** : pas besoin de `trial_mode = 'assisted'`

### Arbre de décision trial_entitlement_plan

| Plan choisi | selected_plan | trial_entitlement_plan | effectivePlan |
|---|---|---|---|
| STARTER | STARTER | AUTOPILOT_ASSISTED | AUTOPILOT_ASSISTED |
| PRO | PRO | AUTOPILOT_ASSISTED | AUTOPILOT_ASSISTED |
| AUTOPILOT | AUTOPILOT | null | AUTOPILOT |
| ENTERPRISE | ENTERPRISE | null | ENTERPRISE |

---

## 4. CAPABILITIES : AUTOPILOT_ASSISTED vs les autres plans

### Matrice complète

| Capability | STARTER | PRO | AUTOPILOT_ASSISTED | AUTOPILOT (payé) | ENTERPRISE |
|---|---|---|---|---|---|
| canSuggest | false | true | **true** | true | true |
| canAutoReply | false | false | **false** | true | true |
| canAutoAssign | false | false | **false** | true | true |
| canEscalate | false | false | **false** | true | true |
| canEscalateToKeybuzz | false | false | **false** | false | true |
| maxMode | disabled | suggestion | **supervised** | autonomous | autonomous |

### Ce que AUTOPILOT_ASSISTED offre

- IA qui prépare et suggère automatiquement des réponses
- Mode supervisé : l'agent humain voit la suggestion et la valide
- KBActions disponibles pour les suggestions IA
- Expérience "wow" : le client voit l'IA travailler pour lui

### Ce que AUTOPILOT_ASSISTED bloque

- **Aucun envoi automatique** de message (`canAutoReply = false`)
- **Aucune assignation automatique** (`canAutoAssign = false`)
- **Aucune escalade automatique** (`canEscalate = false`)
- **Agent KeyBuzz indisponible** (`canEscalateToKeybuzz = false`)
- **Mode autonome impossible** (`maxMode = supervised`, cap vers supervised si autonomous)

### Différence clé AUTOPILOT vs AUTOPILOT_ASSISTED

| Aspect | AUTOPILOT (payé) | AUTOPILOT_ASSISTED (trial) |
|---|---|---|
| Auto-send messages | OUI | NON |
| Auto-assign conversations | OUI | NON |
| Auto-escalade | OUI | NON |
| Mode max | autonomous | supervised |
| Agent KeyBuzz | NON (addon) | NON |
| Suggestions IA | OUI | OUI |
| Validation humaine | Optionnelle | **OBLIGATOIRE** |

---

## 5. FICHIERS MODIFIÉS

| Fichier | Changements | Lignes |
|---|---|---|
| `src/modules/ai/ai-mode-engine.ts` | +AUTOPILOT_ASSISTED caps, +supervised cap guard | +13 |
| `src/modules/auth/tenant-context-routes.ts` | PRO → AUTOPILOT_ASSISTED (2 occurrences) | 2 modifiées |
| `src/services/entitlement.service.ts` | **AUCUN** (pass-through correct) | 0 |

### Fichiers NON modifiés (invariants)

- `src/modules/billing/routes.ts` — 0
- `src/modules/outbound-conversions/emitter.ts` — 0
- Client / Admin / Website — 0

**Total : 2 fichiers, 15 insertions, 2 modifications**

---

## 6. VALIDATION DEV (CAS A-E)

| Cas | Description | selectedPlan | trialEntitlementPlan | effectivePlan | canSuggest | canAutoReply | Résultat |
|---|---|---|---|---|---|---|---|
| A | Starter trial | STARTER | AUTOPILOT_ASSISTED | AUTOPILOT_ASSISTED | true | false | **PASS** |
| B | PRO trial | PRO | AUTOPILOT_ASSISTED | AUTOPILOT_ASSISTED | true | false | **PASS** |
| C | AUTOPILOT trial | AUTOPILOT | null | AUTOPILOT | true | true | **PASS** |
| D | Tenant existant | PRO | null | PRO | - | - | **PASS** |
| E | Trial expiré | STARTER | AUTOPILOT_ASSISTED | STARTER | false | false | **PASS** |

### Tests supplémentaires

| Test | Résultat |
|---|---|
| Supervised cap (autonomous → supervised) | **PASS** |
| AUTOPILOT_ASSISTED capabilities complètes | **PASS** |
| Aucun faux event conversion | **PASS** |
| API health | **PASS** |

**10/10 tests PASS**

---

## 7. TRACKING INVARIANTS

| Invariant | Status |
|---|---|
| signup_complete = selected plan | Non modifié (client-side) |
| purchase = Stripe webhook | Non modifié |
| conversion_events | 2 existants, 0 ajouté |
| outbound_conversion_delivery_logs | 7 existants, 0 ajouté |
| CAPI Meta/TikTok/LinkedIn | Inchangé |
| GA4 | Inchangé |
| marketing_owner_tenant_id | Inchangé |
| Baseline analytics | Préservée |

---

## 8. NON-RÉGRESSION

| Check | Résultat |
|---|---|
| API health DEV | `{"status":"ok"}` |
| Entitlement DEV | Nouveaux champs (billingPlan, effectivePlan, selectedPlan, trialEntitlementPlan) |
| billing/current DEV | Plan PRO, 3 channels |
| create-signup DEV | Route active (400 validation) |
| Stripe webhook | Route active (erreur signature) |
| conversion_events | 2 total, inchangé |
| delivery_logs | 7 total, inchangé |
| PROD API | `v3.5.123-linkedin-capi-native-prod` **INCHANGÉE** |
| PROD Client | `v3.5.125-register-console-cleanup-prod` **INCHANGÉE** |
| PROD Website | `v0.6.7-pricing-attribution-forwarding-prod` **INCHANGÉE** |
| Secrets dans logs | 0 matches |

---

## 9. BUILD & DEPLOY

| Item | Valeur |
|---|---|
| API commit | `91b860b2` feat(trial-entitlement): change trial semantics from PRO to AUTOPILOT_ASSISTED |
| Pre-build check | `BUILD ALLOWED - working tree is clean` |
| Image tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.127-trial-autopilot-assisted-dev` |
| Image digest | `sha256:ed4d1d208c7c1386ed1247dd0000ff845a98717a1bfb8a3e4b44707acf72cdd6` |
| Infra commit | `d431ed2` deploy(api-dev): v3.5.127-trial-autopilot-assisted-dev |
| Deploy method | GitOps strict (manifest + commit + kubectl apply -f) |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |

---

## 10. ROLLBACK

### GitOps image retour

```bash
sed -i 's|ghcr.io/keybuzzio/keybuzz-api:v3.5.127-trial-autopilot-assisted-dev.*|ghcr.io/keybuzzio/keybuzz-api:v3.5.126-trial-entitlement-dev|' /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
cd /opt/keybuzz/keybuzz-infra && git add -A && git commit -m "rollback(api-dev): revert to v3.5.126-trial-entitlement-dev"
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

### DB rollback safe (optionnel, ne casse rien)

```sql
UPDATE tenants SET trial_entitlement_plan = NULL WHERE trial_entitlement_plan = 'AUTOPILOT_ASSISTED';
```

---

## 11. LINEAR

### KEY-225 — Trial Autopilote Assisté pendant 14 jours

> **PH-T8.12C.1 DEV DONE** — 2026-04-29
>
> Sémantique corrigée : trial = AUTOPILOT_ASSISTED (pas PRO).
> IA suggère, humain valide. Aucun auto-send. Aucun Agent KeyBuzz.
> PLAN_CAPABILITIES.AUTOPILOT_ASSISTED : canSuggest=true, maxMode=supervised, all auto=false.
> Image : `v3.5.127-trial-autopilot-assisted-dev` (sha256:ed4d1d20...).
> PROD inchangée.

### KEY-226 — selected_plan / billing_plan / trial_entitlement_plan

> **PH-T8.12C.1 DEV DONE** — 2026-04-29
>
> Contrat API enrichi :
> - `selectedPlan` = plan choisi au signup (vérité marketing)
> - `billingPlan` = plan Stripe réel
> - `trialEntitlementPlan` = AUTOPILOT_ASSISTED pendant trial
> - `effectivePlan` = AUTOPILOT_ASSISTED pendant trial, billingPlan après

### KEY-230 — Tracking upgrade pendant trial sans drift

> **PH-T8.12C.1 INVARIANT CONFIRMÉ** — 2026-04-29
>
> 0 modification billing/conversions/tracking.
> conversion_events inchangé (2). delivery_logs inchangé (7).
> signup_complete et purchase restent liés au plan choisi / Stripe.
> Aucun faux event CAPI/GA4.

### KEY-231 — KBActions trial : montrer la valeur sans anxiété

> **PH-T8.12C.1 FOUNDATION** — 2026-04-29
>
> AUTOPILOT_ASSISTED active canSuggest=true → les suggestions IA consomment des KBActions.
> L'allocation trial et le messaging UX sont à définir dans la phase Client.
> Aucun changement billing/wallet dans cette phase API.

---

## 12. RÉSUMÉ FINAL

### PH-SAAS-T8.12C.1 — TERMINÉ
### Verdict : **GO**

| Item | Ancienne valeur | Nouvelle valeur |
|---|---|---|
| trial_entitlement_plan | `PRO` | `AUTOPILOT_ASSISTED` |
| API branch | ph147.4/source-of-truth | ph147.4/source-of-truth |
| API HEAD | 3ad30a67 | `91b860b2` |
| selectedPlan | Inchangé | Inchangé |
| billingPlan | Inchangé | Inchangé |
| effectivePlan (trial) | PRO | **AUTOPILOT_ASSISTED** |
| canSuggest (trial) | true | true |
| canAutoReply (trial) | false | false |
| maxMode (trial) | suggestion | **supervised** |
| Agent KeyBuzz | false | false |
| Tracking invariants | Inchangé | Inchangé |
| Build DEV | v3.5.126 | `v3.5.127-trial-autopilot-assisted-dev` |
| Build digest | - | `sha256:ed4d1d208c7c1386ed1247dd0000ff845a98717a1bfb8a3e4b44707acf72cdd6` |
| PROD modified | NON | **NON** |

### Conclusion

**TRIAL SEMANTICS CORRECTED TO AUTOPILOT ASSISTED IN DEV — STARTER/PRO TRIALS SEE HIGH-VALUE ASSISTED AUTOPILOT WITHOUT AUTO-SEND — BILLING/TRACKING/CAPI UNCHANGED — PROD UNCHANGED — READY FOR CLIENT SOURCE LOCK**
