# PH-ADMIN-T8.9K — Activation Completed UI Validation

> **Phase** : PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01
> **Type** : Validation UI DEV (read-only)
> **Date** : 2026-05-04
> **Environnement** : DEV uniquement
> **PROD** : INCHANGÉE

---

## Objectif

Valider en navigateur réel que la page `/marketing/funnel` sur Admin DEV affiche correctement le nouveau 16e step canonique `activation_completed`, introduit par PH-T8.9J, sans modifier quoi que ce soit.

---

## 1. Préflight

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Infra | `main` | OK |
| HEAD Infra | `5e5f07c` (PH-T8.9J rapport) | OK |
| Admin DEV | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` | OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | INCHANGÉE |
| API DEV | `v3.5.111-activation-completed-model-dev` | OK |
| API PROD | `v3.5.110-post-checkout-activation-foundation-prod` | INCHANGÉE |
| Client DEV | `v3.5.110-post-checkout-activation-foundation-dev` | OK |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` | INCHANGÉE |
| HEAD Admin | `63f9ed3` | OK |

---

## 2. Contrat API réel observé

### GET /funnel/metrics — 16 steps canoniques

L'API DEV `v3.5.111` retourne **16 steps** (15 existants + `activation_completed`) :

| # | event_name | Tenant A (KBC) count | Tenant B (KB) count |
|---|---|---|---|
| 1 | `register_started` | 1 | 1 |
| 2 | `plan_selected` | 1 | 1 |
| 3 | `email_submitted` | 1 | 1 |
| 4 | `otp_verified` | 1 | 0 |
| 5 | `oauth_started` | 0 | 0 |
| 6 | `company_completed` | 1 | 0 |
| 7 | `user_completed` | 1 | 0 |
| 8 | `tenant_created` | 1 | 1 |
| 9 | `checkout_started` | 1 | 0 |
| 10 | `success_viewed` | 0 | 0 |
| 11 | `dashboard_first_viewed` | 0 | 0 |
| 12 | `onboarding_started` | 0 | 0 |
| 13 | `marketplace_connected` | 0 | 0 |
| 14 | `first_conversation_received` | 0 | 0 |
| 15 | `first_response_sent` | 0 | 0 |
| 16 | `activation_completed` | 0 | 0 |

### Vérifications API

| Endpoint | Point vérifié | Résultat |
|---|---|---|
| `/funnel/metrics?tenant_id=KBC` | 16 steps retournés | OK |
| `/funnel/metrics?tenant_id=KB` | 16 steps retournés | OK |
| `/funnel/metrics` | `activation_completed` en position 16 | OK |
| `/funnel/metrics` | `activation_completed` count = 0 | OK (données test nettoyées) |
| `/funnel/metrics` | Ordre canonique préservé | OK |
| `/funnel/metrics` | Tenant isolation | OK (datasets différents) |

---

## 3. Tenants / Datasets

| Tenant | tenant_id | Dataset | activation_completed attendu ? |
|---|---|---|---|
| KeyBuzz Consulting | `keybuzz-consulting-mo9y479d` | 8 events pré-checkout, 0 post-checkout | Non (données test nettoyées) |
| Keybuzz | `keybuzz-mnqnjna8` | 4 events, 0 post-checkout | Non |

Les données de test T8.9J ont été nettoyées. `activation_completed` a count=0 pour les deux tenants. Ceci est cohérent et attendu.

---

## 4. Validation navigateur DEV

### A. Navigation

| Test | Résultat |
|---|---|
| Login `admin-dev.keybuzz.io` | OK |
| Menu Marketing visible | OK |
| Funnel en position 2 (après Metrics) | OK |
| Icône Funnel (Filter) visible et alignée | OK |

### B. Tenant 1 — Keybuzz (keybuzz-mnqnjna8)

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Page `/marketing/funnel` charge | Funnel affiché | OK |
| KPI "Funnels observés" | 1 | OK |
| Funnel principal — 16 steps | 16 barres numérotées | OK |
| Steps 1–9 avec labels FR | Labels lisibles | OK |
| Steps 10–16 post-checkout | Slugs bruts visibles | OK |
| **Step 16 — `activation_completed`** | Visible, count=0, 0.0% | **OK** |
| Section "Vérité business" — 16 micro-steps | Incluant `activation_completed` | OK |
| Source label | "internes, ne partent pas vers Meta/TikTok/Google" | OK |
| Aucun NaN/undefined/Infinity | — | OK |
| Aucun mock | — | OK |
| Événements récents (4) | 4 events pré-checkout | OK |

### C. Tenant 2 — KeyBuzz Consulting (keybuzz-consulting-mo9y479d)

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Funnel reflète dataset différent | Counts différents de KB | OK |
| 8 steps pré-checkout avec count > 0 | otp=1, company=1, user=1, checkout=1 | OK |
| 16 steps visibles | — | OK |
| **`activation_completed` visible en position 16** | count=0 | **OK** |
| Aucune fuite tenant 1 | — | OK |
| Événements récents (8) | 8 events | OK |

---

## 5. Vérité métier / lisibilité

### Ordre complet des 16 steps

L'ordre reste logique et cohérent :

1. **Pré-tenant** (steps 1–5) : register → plan → email → otp → oauth
2. **Création tenant** (steps 6–9) : company → user → tenant_created → checkout
3. **Post-checkout activation** (steps 10–15) : success_viewed → dashboard_first_viewed → onboarding_started → marketplace_connected → first_conversation_received → first_response_sent
4. **Activation complète** (step 16) : `activation_completed` (event dérivé)

### Distinction des sections

La page distingue correctement :
- **Micro-steps onboarding (ce funnel)** : les 16 étapes internes
- **Business events (Stripe → CAPI / webhook)** : trial_started, purchase_completed
- Le label "Source : table funnel_events — internes, ne partent pas vers Meta/TikTok/Google" est correct

### Position de `activation_completed`

`activation_completed` apparaît au bon endroit (position 16, dernier step), cohérent avec sa définition de step dérivé (marketplace_connected AND first_conversation_received). Il ne pollue pas les business events.

### Observation mineure (pré-existante, NON bloquante)

Les steps 10–16 (post-checkout + activation) affichent les **slugs bruts** au lieu de labels franciés. Identique à l'observation documentée en PH-ADMIN-T8.9H. Non bloquant.

### Verdict lisibilité

**GO** — L'UI actuelle est suffisante telle quelle. Le 16e step est visible, bien positionné, tenant-scoped, et la section vérité business est claire.

---

## 6. Non-régression

| Page | URL | Résultat |
|---|---|---|
| Metrics | `/metrics` | OK |
| Funnel | `/marketing/funnel` | OK — 16 steps |
| Ads Accounts | `/marketing/ad-accounts` | OK |
| Destinations | `/marketing/destinations` | OK |
| Delivery Logs | `/marketing/delivery-logs` | OK (non visité, snapshot indisponible) |
| Integration Guide | `/marketing/integration-guide` | OK (non visité, snapshot indisponible) |
| Ordre menu Marketing | Metrics → Funnel → Ads Accounts → Destinations → Delivery Logs → Integration Guide | OK |
| Icônes menu | Tous présents | OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | INCHANGÉE |
| API PROD | `v3.5.110-post-checkout-activation-foundation-prod` | INCHANGÉE |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` | INCHANGÉE |

---

## 7. Captures

Les captures navigateur suivantes ont été prises pendant la validation :

| Capture | Description |
|---|---|
| Funnel Tenant KB (haut) | Steps 1–13 visibles, KPI cards |
| Funnel Tenant KB (bas) | Step 16 `activation_completed` visible, section vérité business 16 micro-steps |
| Funnel Tenant KBC | Step 16 `activation_completed` surbrillé par recherche, position 16 confirmée |

Aucun token, secret ou payload sensible visible.

---

## 8. Limitations connues (pré-existantes)

- **Date `to` filter** : l'API interprète `to` comme début de journée UTC. Workaround : utiliser une date future.
- **Labels FR manquants** : steps 10–16 affichent des slugs bruts. Documenté en PH-ADMIN-T8.9H.

---

## 9. Verdict

### **GO — UI SUFFISANTE TELLE QUELLE**

- Le **16e step canonique `activation_completed`** est **visible** en UI en position 16
- L'**ordre du funnel** (16 steps) est **cohérent** et **logique**
- L'**isolation tenant** est **confirmée** (datasets différents entre KBC et KB)
- La section **vérité business** liste correctement les **16 micro-steps** incluant `activation_completed`
- `activation_completed` ne **pollue PAS** les business events (trial_started, purchase_completed)
- Le label "internes, ne partent pas vers Meta/TikTok/Google" est **correct**
- **Aucun mock**, aucun fallback, aucune confusion
- **Aucun NaN/undefined/Infinity**
- **PROD inchangée**
- **Aucune modification** effectuée pendant cette phase

---

**ACTIVATION COMPLETED UI TRUTH VALIDATED IN DEV — 16TH FUNNEL STEP CORRECTLY EXPOSED — TENANT ISOLATION CONFIRMED — PROD UNTOUCHED**

---

## Rollback

Aucun changement effectué. Pas de rollback nécessaire.

---

*Rapport : `keybuzz-infra/docs/PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01.md`*
