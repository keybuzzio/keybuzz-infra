# PH-T8.9L — Activation Completed — PROD Promotion

> **Date** : 2026-05-01
> **Environnement** : PROD
> **Type** : Promotion PROD du step dérivé `activation_completed`
> **Priorité** : P0
> **Statut** : LIVE

---

## Objectif

Promouvoir en PROD le step dérivé interne `activation_completed`, validé en DEV (PH-T8.9J) et confirmé côté UI Admin DEV (PH-ADMIN-T8.9K). Le funnel CRO PROD passe de 15 à 16 steps canoniques.

---

## Sources de vérité

| Document | Phase |
|---|---|
| `keybuzz-infra/docs/PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01.md` | DEV foundation |
| `keybuzz-infra/docs/PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01.md` | Admin UI validation |
| `keybuzz-infra/docs/PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md` | Précédente promo PROD |

---

## ÉTAPE 0 — Préflight

| Point | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `c0b0f195` — PH-T8.9J activation_completed derived event |
| API DEV | `v3.5.111-activation-completed-model-dev` |
| API PROD (avant) | `v3.5.110-post-checkout-activation-foundation-prod` |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` — inchangé |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` — inchangée |
| Repo clean | Oui |

---

## ÉTAPE 1 — Vérification source

| Point | Résultat |
|---|---|
| Modèle A confirmé | `marketplace_connected AND first_conversation_received` (L86, L96, L103) |
| `tryEmitActivationCompleted()` | Présent L99 |
| Branchement `emitActivationEvent()` | L85-87 — appel conditionnel |
| `activation_completed` dans ALLOWED_EVENTS | L23 — position 16 |
| `ON CONFLICT DO NOTHING` | L110 — idempotence |
| Aucune écriture `conversion_events` | grep → CLEAN |
| Aucune logique outbound | grep → CLEAN |

---

## ÉTAPE 2 — Vérification PROD DB

| Point | Résultat |
|---|---|
| Table `funnel_events` | Existe |
| Contrainte UNIQUE | `funnel_events_funnel_id_event_name_key` — compatible |
| Index | 6 (pkey + unique + 4 perf) — suffisants |
| Migration | **NON** — aucun changement de schéma |

---

## ÉTAPE 3 — Build safe PROD

| Point | Valeur |
|---|---|
| Tag | `v3.5.111-activation-completed-model-prod` |
| Digest | `sha256:22d238e34273a3bd0d18804fec0253291d8b733d6a550b75a351b3c699d8b3ac` |
| Commit | `c0b0f195` |
| Build-from-git | Oui |
| Repo clean | Oui |
| `--no-cache` | Oui |

---

## ÉTAPE 4 — GitOps PROD

| Point | Valeur |
|---|---|
| Commit infra | `c190926` |
| Message | `PH-T8.9L: GitOps PROD — activation_completed derived event — API v3.5.111` |

### Diff

```
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.110-post-checkout-activation-foundation-prod
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.111-activation-completed-model-prod  # rollback: v3.5.110-post-checkout-activation-foundation-prod
```

### Non-modifiés

- Client PROD : inchangé
- Admin PROD : inchangée
- DEV : inchangé

---

## ÉTAPE 5 — Deploy PROD

| Point | Résultat |
|---|---|
| `kubectl apply` | `deployment.apps/keybuzz-api configured` |
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-api-74dd866b9b-m8rc7` Running, 0 restarts |
| Health | `{"status":"ok"}` |
| Image runtime | `v3.5.111-activation-completed-model-prod` |

---

## ÉTAPE 6 — Validation PROD API

### A. Funnel — 16 steps

```
 1. register_started
 2. plan_selected
 3. email_submitted
 4. otp_verified
 5. oauth_started
 6. company_completed
 7. user_completed
 8. tenant_created
 9. checkout_started
10. success_viewed
11. dashboard_first_viewed
12. onboarding_started
13. marketplace_connected
14. first_conversation_received
15. first_response_sent
16. activation_completed        ← NEW
```

### B-D. Validation complète

| Cas | Attendu | Résultat |
|---|---|---|
| B1. 1 prérequis seul | 0 `activation_completed` | **0** |
| B2. Les 2 prérequis | 1 `activation_completed` | **1** |
| B3. Idempotence | Re-insert SKIPPED | **SKIPPED** |
| C. Tenant incomplet | 0 `activation_completed` | **0** |
| D. `conversion_events` | 0 activation events | **0** |
| D. outbound_destinations | 10 (inchangé) | **10** |
| D. delivery_logs | 4 (inchangé) | **4** |
| D. signup_attribution | 3 (inchangé) | **3** |
| D. billing_events | 127 (inchangé) | **127** |

---

## ÉTAPE 7 — Validation consommateur read-only

L'Admin PROD (`v2.11.11`) consomme `/funnel/metrics` via son proxy et itère dynamiquement sur les steps retournés. L'API PROD expose maintenant 16 steps — l'Admin affichera automatiquement `activation_completed` sans redéploiement. Confirmé par PH-ADMIN-T8.9K en DEV.

---

## ÉTAPE 8 — Preuves DB / SQL

| Preuve | Résultat |
|---|---|
| Dérivation contrôlée | 2 prérequis → 1 `activation_completed` |
| Idempotence | Re-insert SKIPPED (`ON CONFLICT DO NOTHING`) |
| Tenant incomplet | 1 prérequis → 0 `activation_completed` |
| `conversion_events` | 0 activation events |
| Outbound destinations | 10 (inchangé) |
| Delivery logs | 4 (inchangé) |
| Données de test | Nettoyées après validation |

---

## ÉTAPE 9 — Non-régression

| Point | Résultat |
|---|---|
| `funnel/metrics` | 16 steps |
| 15 steps existants | Tous présents |
| `activation_completed` | 16e step canonique |
| `conversion_events` | 0 (intact) |
| Outbound conversions | Inchangées |
| `signup_attribution` | 3 (intact) |
| `billing_events` | 127 (intact) |
| Client PROD | `v3.5.110` (inchangé) |
| Admin PROD | `v2.11.11` (inchangée) |
| API DEV | `v3.5.111` (inchangé) |

---

## ÉTAPE 10 — Gaps restants

| Gap | Description | Phase correctrice |
|---|---|---|
| `billing_events.tenant_id = NULL` | Couture billing → tenant impossible | Future phase billing |
| `OnboardingWizard` | Code mort | Nettoyage technique |
| `OnboardingHub` | Statique | Évolution produit |
| Labels Admin `activation_completed` | Affiché brut | Dette cosmétique |
| Modèle A = signal simultané | Les 2 prérequis toujours émis ensemble | Acceptable MVP |
| Modèle B non implémenté | `first_response_sent` pas prérequis | Future phase |

---

## ÉTAPE 11 — Rollback PROD

| Service | Rollback tag |
|---|---|
| API PROD | `v3.5.110-post-checkout-activation-foundation-prod` |

Procédure : modifier manifest → commit → push → pull bastion → `kubectl apply`. Pas de DDL à reverter.

---

## Images PROD — Avant / Après

| Service | Avant | Après |
|---|---|---|
| API | `v3.5.110-post-checkout-activation-foundation-prod` | `v3.5.111-activation-completed-model-prod` |
| Client | `v3.5.110-post-checkout-activation-foundation-prod` | Inchangé |
| Admin | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | Inchangée |

### Digests

| Service | Digest |
|---|---|
| API PROD | `sha256:22d238e34273a3bd0d18804fec0253291d8b733d6a550b75a351b3c699d8b3ac` |

---

## Verdict

**ACTIVATION COMPLETED LIVE IN PROD — 16TH FUNNEL STEP CANONICALIZED — NO ADS POLLUTION — CLIENT AND ADMIN UNCHANGED**

---

## Rapport

`keybuzz-infra/docs/PH-T8.9L-ACTIVATION-COMPLETED-PROD-PROMOTION-01.md`
