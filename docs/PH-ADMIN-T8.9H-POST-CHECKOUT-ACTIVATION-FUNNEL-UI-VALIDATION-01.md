# PH-ADMIN-T8.9H — Post-Checkout Activation Funnel UI Validation

> **Phase** : PH-ADMIN-T8.9H-POST-CHECKOUT-ACTIVATION-FUNNEL-UI-VALIDATION-01
> **Type** : Validation UI DEV (read-only)
> **Date** : 2026-04-24
> **Environnement** : DEV uniquement
> **PROD** : INCHANGÉE

---

## Objectif

Valider en navigateur réel que la page `/marketing/funnel` sur Admin DEV affiche correctement les 6 nouveaux events post-checkout/activation introduits par PH-T8.9G, sans modifier quoi que ce soit.

---

## 1. Préflight

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Infra | `main` | OK |
| HEAD Infra | `eb61084` (PH-T8.9G) | OK |
| Admin DEV | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` | OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | INCHANGÉE |
| API DEV | `v3.5.110-post-checkout-activation-foundation-dev` | OK |
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` | INCHANGÉE |
| Client DEV | `v3.5.110-post-checkout-activation-foundation-dev` | OK |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` | INCHANGÉE |
| HEAD Admin | `63f9ed3` | OK |
| Repo k8s/ | clean | OK |

---

## 2. Contrat API réel observé

### GET /funnel/metrics — Tenant A (KeyBuzz Consulting)

L'API retourne **15 steps** (9 originaux + 6 nouveaux post-checkout) :

| # | event_name | count | conversion_rate_from_previous |
|---|---|---|---|
| 1 | `register_started` | 1 | 100% |
| 2 | `plan_selected` | 1 | 100% |
| 3 | `email_submitted` | 1 | 100% |
| 4 | `otp_verified` | 1 | 100% |
| 5 | `oauth_started` | 0 | 0% |
| 6 | `company_completed` | 1 | 0% |
| 7 | `user_completed` | 1 | 100% |
| 8 | `tenant_created` | 1 | 100% |
| 9 | `checkout_started` | 1 | 100% |
| 10 | `success_viewed` | 0 | 0% |
| 11 | `dashboard_first_viewed` | 0 | 0% |
| 12 | `onboarding_started` | 0 | 0% |
| 13 | `marketplace_connected` | 0 | 0% |
| 14 | `first_conversation_received` | 0 | 0% |
| 15 | `first_response_sent` | 0 | 0% |

### GET /funnel/metrics — Tenant B (Keybuzz)

| # | event_name | count | conversion_rate_from_previous |
|---|---|---|---|
| 1 | `register_started` | 1 | 100% |
| 2 | `plan_selected` | 1 | 100% |
| 3 | `email_submitted` | 1 | 100% |
| 4 | `otp_verified` | 0 | 0% |
| 5 | `oauth_started` | 0 | 0% |
| 6 | `company_completed` | 0 | 0% |
| 7 | `user_completed` | 0 | 0% |
| 8 | `tenant_created` | 1 | 0% |
| 9 | `checkout_started` | 0 | 0% |
| 10–15 | (6 post-checkout) | 0 | 0% |

### Vérifications API

| Endpoint | Point vérifié | Résultat |
|---|---|---|
| `/funnel/metrics?tenant_id=KBC` | 15 steps retournés | OK |
| `/funnel/metrics?tenant_id=KB` | 15 steps retournés | OK |
| `/funnel/metrics` | 6 nouveaux events post-checkout présents | OK (count=0, pas d'events réels encore) |
| `/funnel/metrics` | Ordre canonique | Correct (pré-tenant → checkout → post-checkout) |
| `/funnel/metrics` | Tenant isolation | OK (datasets différents) |
| `/funnel/events?tenant_id=KBC` | 8 events (pré-checkout) | OK |

---

## 3. Tenants / Datasets

| Tenant | tenant_id | Dataset | Particularité |
|---|---|---|---|
| KeyBuzz Consulting | `keybuzz-consulting-mo9y479d` | 8 events pré-checkout | Funnel complet pré-checkout |
| Keybuzz | `keybuzz-mnqnjna8` | 4 events (register, plan, email, tenant_created) | Funnel partiel |

Les 6 nouveaux events post-checkout ont count=0 pour les deux tenants (pas encore d'events réels injectés).

---

## 4. Validation navigateur DEV

### A. Navigation

| Test | Résultat |
|---|---|
| Login `admin-dev.keybuzz.io` | OK |
| Menu Marketing visible | OK |
| Funnel en position 2 (après Metrics) | OK |
| Icône Funnel (Filter) visible et alignée | OK |

### B. Tenant 1 — KeyBuzz Consulting

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Page `/marketing/funnel` charge | Funnel affiché | OK |
| KPI "Funnels observés" | 1 | OK |
| KPI "Dernière étape" | 0 | OK |
| KPI "Conversion globale" | 0.0% | OK |
| KPI "Plus gros drop-off" | -1 | OK |
| Funnel principal — 15 steps | 15 barres numérotées | OK — tous visibles |
| Steps 1–9 avec labels FR | Labels lisibles | OK |
| Steps 10–15 post-checkout | Slugs bruts visibles | OK (voir observation mineure) |
| Section "Vérité business" | Micro-steps + Business events | OK |
| Micro-steps = 15 entries | Incluant 6 nouveaux | OK |
| Business events | trial_started, purchase_completed | OK |
| Source label | "internes, ne partent pas vers Meta/TikTok/Google" | OK |
| Aucun NaN/undefined/Infinity | — | OK |
| Aucun mock | — | OK |
| Aucun overlap | — | OK |
| Événements récents (8) | 8 events pré-checkout | OK |

### C. Tenant 2 — Keybuzz

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Funnel reflète dataset différent | Counts différents de KBC | OK |
| register_started / plan_selected / email_submitted = 1 | — | OK |
| tenant_created = 1 (skip otp→company→user) | — | OK |
| Aucune fuite tenant 1 | — | OK |
| 15 steps visibles | — | OK |
| Événements récents (4) | 4 events | OK |

---

## 5. Vérité métier / lisibilité

### Ordre du funnel

L'ordre reste logique après ajout du post-checkout :

1. **Pré-tenant** (steps 1–5) : register → plan → email → otp → oauth
2. **Création tenant** (steps 6–9) : company → user → tenant_created → checkout
3. **Post-checkout activation** (steps 10–15) : success_viewed → dashboard_first_viewed → onboarding_started → marketplace_connected → first_conversation_received → first_response_sent

### Distinction des sections

La page distingue correctement :
- **Micro-steps onboarding** : les 15 étapes internes (ce funnel)
- **Business events** : trial_started et purchase_completed (Stripe → CAPI)
- Le label "Source : table funnel_events — internes, ne partent pas vers Meta/TikTok/Google" est correct et clair

### Observation mineure (NON bloquante)

Les steps 10–15 (post-checkout) affichent les **slugs bruts** comme labels (`success_viewed`, `dashboard_first_viewed`...) au lieu de labels franciés comme les steps 1–9 (`Inscription démarrée`, `Plan sélectionné`...).

**Impact** : cosmétique uniquement. Les données sont correctes. L'UI est exploitable.
**Recommandation** : ajouter des labels FR pour les 6 nouveaux events dans une phase future (non bloquant pour cette validation).

### Verdict lisibilité

**GO** — L'UI actuelle est suffisante telle quelle. Les 15 steps sont visibles, ordonnés logiquement, tenant-scoped, et la section vérité business est claire.

---

## 6. Non-régression

| Page | URL | Résultat |
|---|---|---|
| Metrics | `/metrics` | OK — charge |
| Funnel | `/marketing/funnel` | OK — 15 steps |
| Ads Accounts | `/marketing/ad-accounts` | OK — charge |
| Destinations | `/marketing/destinations` | OK — charge |
| Delivery Logs | `/marketing/delivery-logs` | OK — charge |
| Integration Guide | `/marketing/integration-guide` | OK — contenu complet |
| Ordre menu Marketing | Metrics → Funnel → Ads Accounts → Destinations → Delivery Logs → Integration Guide | OK |
| Icônes menu | Tous présents | OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | INCHANGÉE |
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` | INCHANGÉE |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` | INCHANGÉE |

---

## 7. Captures

Les captures navigateur suivantes ont été prises pendant la validation :

| Capture | Description |
|---|---|
| Funnel Tenant 1 (KBC) | 15 steps, barres, KPI cards, section vérité business |
| Funnel Tenant 2 (Keybuzz) | 15 steps, dataset différent, isolation confirmée |

Aucun token, secret ou payload sensible visible.

---

## 8. Limitation connue (pré-existante)

- **Date `to` filter** : l'API interprète `to=2026-04-23` comme `2026-04-23 00:00:00Z`, excluant les events du jour même. Workaround : utiliser `to=2026-04-25`. Documenté dans PH-ADMIN-T8.9C.3.

---

## 9. Verdict

### **GO — UI SUFFISANTE TELLE QUELLE**

- Les **15 steps canoniques** (9 originaux + 6 post-checkout) sont **tous visibles** en UI
- L'**ordre du funnel** est **cohérent** (pré-tenant → checkout → post-checkout activation)
- L'**isolation tenant** est **confirmée** (datasets différents entre KBC et Keybuzz)
- La section **vérité business** distingue correctement micro-steps vs business events
- Le label "internes, ne partent pas vers Meta/TikTok/Google" est **correct**
- **Aucun mock**, aucun fallback, aucune confusion
- **Aucun NaN/undefined/Infinity**
- **PROD inchangée**
- **Aucune modification** effectuée pendant cette phase

### Observation mineure pour phase future
Labels FR manquants pour les 6 nouveaux events post-checkout (steps 10–15). Non bloquant.

---

**POST-CHECKOUT ACTIVATION FUNNEL UI TRUTH VALIDATED IN DEV — NEW ACTIVATION EVENTS CORRECTLY EXPOSED — TENANT ISOLATION CONFIRMED — PROD UNTOUCHED**

---

## Rollback (si nécessaire)

Aucun changement effectué. Pas de rollback nécessaire.

---

*Rapport : `keybuzz-infra/docs/PH-ADMIN-T8.9H-POST-CHECKOUT-ACTIVATION-FUNNEL-UI-VALIDATION-01.md`*
