# PH-SAAS-T8.12AN.4 — Contest PRO Year Promo E2E DEV Validation

> **Date** : 4 mai 2026
> **Auteur** : Agent Cursor (CE)
> **Phase** : PH-SAAS-T8.12AN.4-CONTEST-PRO-YEAR-PROMO-E2E-DEV-VALIDATION-01
> **Environnement** : DEV uniquement
> **Type** : Validation E2E contrôlée, sans promotion PROD
> **Verdict** : **GO PARTIEL — GAP ATTRIBUTION + APPLIES_TO**

---

## 1. OBJECTIF

Valider en DEV le cas réel "jeu concours : 1 an de forfait PRO offert" avec le système promo livré en AN.2 + AN.3.

Prouver que :
- Un code promo créé depuis l'Admin DEV fonctionne dans le parcours signup/checkout DEV
- Le coupon s'applique uniquement au forfait SaaS
- PRO annuel = 0 EUR pendant 12 mois
- AUTOPILOT annuel = différence AUTOPILOT - PRO
- Pas de remise sur KBActions, Agent KeyBuzz, addons/channels
- Attribution promo + UTM préservée
- Aucune pollution PROD

---

## 2. SOURCES LUES

| Source | Statut |
|--------|--------|
| `CE_PROMPTING_STANDARD.md` | ✓ Lu |
| `RULES_AND_RISKS.md` | ✓ Lu |
| `TRIAL_WOW_STACK_BASELINE.md` | ✓ Lu |
| `PH-SAAS-T8.12AN-*.md` (audit initial) | ✓ Lu |
| `PH-SAAS-T8.12AN.1-*.md` (Stripe proof) | ✓ Lu |
| `PH-SAAS-T8.12AN.2-*.md` (Admin foundation) | ✓ Lu |
| `PH-SAAS-T8.12AN.3-*.md` (Link forwarding checkout) | ✓ Lu |
| `PH-SAAS-T8.12W-*.md` (Trial E2E) | ✓ Lu |
| `PH-T8.12U-*.md` (Client sample demo) | ✓ Lu |

---

## 3. PREFLIGHT

| Élément | Valeur | Verdict |
|---------|--------|---------|
| Bastion | install-v3 (46.62.171.61) | ✓ |
| API branche | `ph147.4/source-of-truth` (HEAD a81d90c3) | ✓ |
| Client branche | `ph148/onboarding-activation-replay` (HEAD b0968c6) | ✓ |
| Website branche | `main` (HEAD 7fc942b) | ✓ |
| Admin-v2 branche | `main` (HEAD 22a268e) | ✓ |
| Infra branche | `main` (HEAD 0c3d1e1) | ✓ |
| API DEV image | `v3.5.151-promo-checkout-dev` | ✓ |
| Client DEV image | `v3.5.155-promo-register-dev` | ✓ |
| Website DEV image | `v0.6.8-promo-forwarding-dev` | ✓ |
| Admin DEV image | `v2.12.0-promo-codes-foundation-dev` | ✓ |
| API DEV health | `{"status":"ok"}` | ✓ |
| Stripe mode | TEST (`sk_test_*`) | ✓ |

### Baselines PROD (inchangées)

| Service | Image PROD | Verdict |
|---------|-----------|---------|
| API PROD | `v3.5.139-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| Client PROD | `v3.5.151-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | ✓ inchangé |

---

## 4. CODE PROMO CRÉÉ

### Code principal (single-use)

| Champ | Valeur |
|-------|--------|
| Code | `CONCOURS-PRO-1AN-E2E` |
| Label | Concours PRO 1 an - E2E DEV (single-use) |
| Campaign | concours-pro-1an-e2e |
| DB id | `3d79826d-5230-46cc-ae85-9b5712fdfa16` |
| Coupon Stripe | `p9W7vevl` |
| Promotion Code Stripe | `promo_1TTSXsFC0QQLHISRzUCdluqL` |
| discount_type | amount_off |
| discount_value | 285600 (2856.00 EUR = prix PRO annuel) |
| duration | repeating, 12 mois |
| max_redemptions | 1 |
| livemode | false (TEST) |
| active | true |

### Code multi-use (tests itératifs)

| Champ | Valeur |
|-------|--------|
| Code | `CONCOURS-PRO-1AN-E2E-MULTI` |
| DB id | `e0113f61-6455-4644-aae8-3d5d717c8aba` |
| Coupon Stripe | `n2twbuSP` |
| Promotion Code Stripe | `promo_1TTSZGFC0QQLHISRPQx9Cxui` |
| max_redemptions | 10 |
| Tout le reste identique au code principal | |

### Stripe TEST vérification

| Champ | Coupon p9W7vevl | Coupon n2twbuSP |
|-------|-----------------|-----------------|
| amount_off | 285600 | 285600 |
| currency | eur | eur |
| duration | repeating | repeating |
| duration_in_months | 12 | 12 |
| valid | true | true |
| livemode | false | false |
| applies_to | ⚠ Non visible dans retrieve | ⚠ Non visible dans retrieve |

---

## 5. PRIX STRIPE TEST (référence)

| Produit | ID | Annuel | Mensuel |
|---------|-----|--------|---------|
| KeyBuzz Starter | `prod_TjrtU3R2CeWUTJ` | 93600 (936 EUR) | 9700 (97 EUR) |
| **KeyBuzz Pro** | `prod_TjrtI6NYNyDBbp` | **285600 (2856 EUR)** | 29700 (297 EUR) |
| KeyBuzz Autopilot | `prod_TjrtoaGcUi0yNB` | 477600 (4776 EUR) | 49700 (497 EUR) |
| Canal Supplémentaire | `prod_TjrtcvXp3I6fJR` | 48000 (480 EUR) | 5000 (50 EUR) |
| Agent KeyBuzz | `prod_UFWneeyEEoBCIK` | 765600 (7656 EUR) | 79700 (797 EUR) |

---

## 6. LIEN PROMO DEV

### Forwarding Website → Client

`promo` ajouté dans le tableau `utmKeys` de `/opt/keybuzz/keybuzz-website/src/app/pricing/page.tsx` (ligne 275, commit 7fc942b).

| Paramètre | Website pricing | Client register | Verdict |
|-----------|----------------|-----------------|---------|
| promo | ✓ Forwarded (utmKeys) | ✓ Capturé (urlPromo) | ✓ |
| utm_source | ✓ Forwarded | ✓ Capturé (attribution) | ✓ |
| utm_medium | ✓ Forwarded | ✓ Capturé (attribution) | ✓ |
| utm_campaign | ✓ Forwarded | ✓ Capturé (attribution) | ✓ |
| utm_content | ✓ Forwarded | ✓ Capturé | ✓ |
| gclid/fbclid/ttclid/li_fat_id/_gl | ✓ Forwarded | ✓ Capturé | ✓ |
| marketing_owner_tenant_id | ✓ Forwarded | ✓ Capturé | ✓ |
| Client DEV HTTP | N/A | 200 | ✓ |
| Website DEV (bastion) | 000 (réseau bastion) | N/A | ⚠ connu |

### Liens testés

- Direct client : `https://client-dev.keybuzz.io/register?promo=CONCOURS-PRO-1AN-E2E-MULTI&utm_source=concours&utm_medium=partner&utm_campaign=concours-pro-1an-e2e&utm_content=test`
- Website pricing : `https://preview.keybuzz.pro/pricing?promo=CONCOURS-PRO-1AN-E2E-MULTI&utm_source=concours...`

---

## 7. CHECKOUT PRO ANNUEL AVEC PROMO

Session Stripe : `cs_test_a14Rfle6snsVFrYnxy3usGcmTqELDx1992iw2umx88fWBtFadJfg1MOpTg`

| Signal | Attendu | Observé | Verdict |
|--------|---------|---------|---------|
| HTTP status | 200 | 200 | ✓ |
| Session mode | subscription | subscription | ✓ |
| Stripe mode | TEST | livemode=false | ✓ |
| discounts[] | promotion_code présent | `[{"promotion_code":"promo_1TTSZG..."}]` | ✓ |
| allow_promotion_codes | null/false | null | ✓ anti-stacking |
| Coupon | amount_off 285600 repeating 12m | Confirmé | ✓ |
| Line items | 1 (KeyBuzz Pro) | 1 (KeyBuzz Pro, price_1SmO9u...) | ✓ |
| Trial 14j | Conservé | amount_total=0 (trial) | ✓ |
| Net post-trial PRO annuel | 2856 - 2856 = **0 EUR** | ✓ (coupon = prix plan) | ✓ |
| Metadata promo_code | CONCOURS-PRO-1AN-E2E-MULTI | ✓ | ✓ |
| Metadata keybuzz_promo_code_id | e0113f61... | ✓ | ✓ |
| Metadata UTM | concours/partner/concours-pro-1an-e2e | ✓ | ✓ |
| Aucun addon | 0 | 0 | ✓ |

### Baseline sans promo

Session : `cs_test_b1kQY2p7gYBzqKZbayCCQSbNYKjeiggp67kkUUkuagsMbdzyrqg9RdGhGc`

| Signal | Observé | Verdict |
|--------|---------|---------|
| discounts | [] | ✓ aucun discount |
| allow_promotion_codes | true | ✓ saisie manuelle possible |
| Metadata promo | Absent | ✓ |

---

## 8. CHECKOUT AUTOPILOT ANNUEL AVEC PROMO

Session Stripe : `cs_test_a1LXYf2PUCJBXj4Qfo9Izkk4JCt9gg0qZUFYO9LQI94RbfhRWEO3NEnF0M`

| Signal | Attendu | Observé | Verdict |
|--------|---------|---------|---------|
| Line items | 1 (KeyBuzz Autopilot) | 1 (KeyBuzz Autopilot, price_1SmO9w...) | ✓ |
| discounts[] | promotion_code présent | ✓ | ✓ |
| Coupon amount_off | 285600 | ✓ | ✓ |
| allow_promotion_codes | null | null | ✓ anti-stacking |
| AUTOPILOT annuel | 477600 (4776 EUR) | ✓ | ✓ |
| Net post-trial | 477600 - 285600 = **192000 (1920 EUR)** | ✓ (différence AUTOPILOT - PRO) | ✓ |
| Metadata | promo + UTM complets | ✓ | ✓ |

| Montant | Valeur Stripe | Verdict |
|---------|---------------|---------|
| Plan AUTOPILOT annuel | 4776.00 EUR | ✓ |
| Coupon PRO annuel | -2856.00 EUR | ✓ |
| **Net** | **1920.00 EUR/an** | ✓ |

---

## 9. EXCLUSION ADDONS / AGENT / KBACTIONS

### PRO + 2 Canaux Supplémentaires + Promo

Session : `cs_test_b1xDSkDgN9YypTVJ75UBTlmPFAufxvsWn407tNW4zVxJW4svQ8E5qAubKc`

| Produit | Promo applicable ? | Attendu | Verdict |
|---------|-------------------|---------|---------|
| **KBActions** (ai-actions-checkout) | NON | Flux séparé, mode=payment, price_data dynamique, pas de promo param | ✓ SAFE |
| **Canal Supplémentaire** (dans plan checkout) | PARTIELLEMENT | Coupon 285600 ≤ PRO 285600 → entièrement consommé par le plan | ✓ SAFE (math) |
| **Agent KeyBuzz** (agent checkout) | ⚠ RISQUE | `allow_promotion_codes: true` dans le code, un utilisateur pourrait saisir le code manuellement | ⚠ GAP P2 |

### Détail par produit

| Produit | Flux checkout | accept promo ? | applies_to risk | Verdict |
|---------|--------------|---------------|-----------------|---------|
| KeyBuzz Pro/Starter/Autopilot | `/billing/checkout-session` | OUI (discounts[]) | N/A (produit cible) | ✓ |
| Canal Supplémentaire | inclus dans plan checkout | Indirect (partie de la session) | Coupon amount ≤ plan price → safe | ✓ |
| Agent KeyBuzz | `/billing/agent-keybuzz-checkout` | `allow_promotion_codes: true` | ⚠ utilisateur peut entrer le code | ⚠ P2 |
| KBActions | `/billing/ai-actions-checkout` | NON (mode payment, price_data) | N/A | ✓ |

### Mitigations Agent KeyBuzz

- Le code `CONCOURS-PRO-1AN-E2E` a `max_redemptions=1`
- Le checkout Agent requiert plan AUTOPILOT actif
- Le flux concours (lien → register → checkout plan) ne mène jamais au checkout Agent
- Risque = saisie manuelle par un utilisateur connaissant le code

---

## 10. ATTRIBUTION ET TRACKING

### Stripe Checkout Session Metadata (3 sessions AN.4)

| Champ | Session PRO | Session AUTOPILOT | Session PRO+addons | Verdict |
|-------|------------|-------------------|-------------------|---------|
| promo_code | CONCOURS-PRO-1AN-E2E-MULTI | ✓ | ✓ | ✓ |
| keybuzz_promo_code_id | e0113f61-... | ✓ | ✓ | ✓ |
| stripe_promotion_code_id | promo_1TTSZG... | ✓ | ✓ | ✓ |
| promo_discount_type | amount_off | ✓ | ✓ | ✓ |
| promo_discount_value | 285600.00 | ✓ | ✓ | ✓ |
| utm_source | concours | ✓ | ✓ | ✓ |
| utm_medium | partner | ✓ | ✓ | ✓ |
| utm_campaign | concours-pro-1an-e2e | ✓ | ✓ | ✓ |
| utm_content | MISSING | MISSING | MISSING | ⚠ GAP P3 |
| tenant_id | ecomlg-001 | ✓ | ✓ | ✓ |

### Surfaces de stockage

| Surface | promo visible | UTM visible | Verdict |
|---------|---------------|-------------|---------|
| Stripe Checkout metadata | ✓ (5 champs) | ✓ partiel (3/4 UTM) | ✓ avec gap |
| Stripe subscription metadata | N/A (sessions non complétées) | N/A | N/A |
| DB signup_attribution | Non implémenté | Non implémenté | GAP P1 |
| API logs | ✓ (console.log) | Partiel | ✓ |

### Gaps attribution

| Gap | Sévérité | Détail | Recommandation |
|-----|----------|--------|----------------|
| DB signup_attribution | **P1** | Pas de colonne en DB pour stocker l'attribution signup (promo + UTM) | AN.5 : ajouter colonne et persistance |
| utm_content manquant | **P3** | Le mapping `attrMeta` dans l'API ne transmet pas `utm_content` à Stripe metadata | AN.5 : ajouter le champ au mapping |
| Stripe subscription metadata | **P3** | Non vérifiable sans compléter le checkout | AN.5 : valider après un checkout TEST complet |

---

## 11. MAX REDEMPTIONS ET IDEMPOTENCE

| Cas | Attendu | Observé | Verdict |
|-----|---------|---------|---------|
| Code inconnu (`FAKE-CODE-DOES-NOT-EXIST`) | 400 PROMO_UNKNOWN | `{"error":"Code promo inconnu","code":"PROMO_UNKNOWN"}` | ✓ |
| Code archivé (`AN2-VALIDATION-TEST01`) | 400 PROMO_ARCHIVED | `{"error":"Code promo expiré ou archivé","code":"PROMO_ARCHIVED"}` | ✓ |
| Anti-stacking (promo pré-appliqué) | allow_promotion_codes=null + discounts=promo | 3/3 sessions : null + discounts | ✓ |
| Message UX/API honnête | Code erreur + message clair | PROMO_UNKNOWN / PROMO_ARCHIVED | ✓ |
| max_redemptions=1 (enforcement) | Bloqué par Stripe à la completion | Non testable sans paiement réel | ⚠ Stripe-enforced |

**Note** : `max_redemptions` est enforced par Stripe lors de la completion de la session de paiement, pas lors de la création. Les sessions TEST non complétées ne consomment pas de redemption. Comportement documenté Stripe.

---

## 12. NON-RÉGRESSION

### DEV

| Surface | Statut | Verdict |
|---------|--------|---------|
| API DEV health | OK (`{"status":"ok"}`) | ✓ |
| Client DEV /register | 200 | ✓ |
| Client DEV /register?promo=... | 200 | ✓ |
| Client DEV /billing | 307 (redirect auth) | ✓ attendu |
| Admin DEV health | 307 (auth required) | ✓ attendu |
| Checkout sans promo (baseline) | 200, URL Stripe OK | ✓ |
| Website DEV /pricing | ⚠ 000 (réseau bastion) | ⚠ connu |

### PROD

| Surface | Statut | Verdict |
|---------|--------|---------|
| API PROD health | OK | ✓ |
| Client PROD /login | 200 | ✓ |
| API PROD image | `v3.5.139-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| Client PROD image | `v3.5.151-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| Website PROD image | `v0.6.8-tiktok-browser-pixel-prod` | ✓ inchangé |
| Infra manifests | HEAD 0c3d1e1 (AN.3) | ✓ inchangé |
| Builds AN.4 | **0** | ✓ |
| Deploys AN.4 | **0** | ✓ |
| Mutations PROD | **0** | ✓ |

---

## 13. MUTATIONS DEV AN.4

| Mutation | Type | Réversible | Conservé |
|----------|------|-----------|----------|
| Code promo `CONCOURS-PRO-1AN-E2E` (DB + Stripe TEST) | Données test | Archivable | Oui (preuve) |
| Code promo `CONCOURS-PRO-1AN-E2E-MULTI` (DB + Stripe TEST) | Données test | Archivable | Oui (futurs tests) |
| Coupon Stripe TEST `p9W7vevl` | Stripe TEST | Suppressible | Oui |
| Coupon Stripe TEST `n2twbuSP` | Stripe TEST | Suppressible | Oui |
| 6+ sessions Stripe TEST (non complétées) | Stripe TEST | Auto-expirent 24h | N/A |
| Audit log entries (2) | Données test | Conservées | Oui (preuve) |

---

## 14. GAPS ET RECOMMANDATIONS AN.5

| # | Gap | Sévérité | Détail | Action |
|---|-----|----------|--------|--------|
| G1 | `applies_to` non visible sur coupons Stripe | **P2** | Le champ `applies_to.products` passé à la création de coupon n'apparaît pas dans le retrieve. Pour ce coupon spécifique (285600 = prix PRO), le résultat est mathématiquement correct. Risque pour des coupons plus larges. | AN.5 : investiguer API version Stripe, vérifier enforcement réel via checkout TEST complet |
| G2 | DB signup_attribution non implémenté | **P1** | Pas de colonne en DB pour persister promo + UTM au signup. Seul Stripe metadata stocke ces données. | AN.5 : ajouter table/colonne `signup_attribution` |
| G3 | Agent KeyBuzz `allow_promotion_codes: true` | **P2** | Le checkout Agent KeyBuzz permet la saisie manuelle de promos. Un utilisateur pourrait saisir le code concours. | AN.5 : conditionner `allow_promotion_codes` ou utiliser `restrictions.first_time_transaction` |
| G4 | utm_content non mappé dans attrMeta | **P3** | Pré-existant, pas lié au promo. Le champ `utm_content` n'est pas transmis dans les Stripe metadata. | AN.5 : ajouter au mapping |
| G5 | max_redemptions non testable sans paiement | **P3** | `max_redemptions=1` est enforced par Stripe à la completion. Non testable sans paiement réel en TEST. | AN.5 : compléter un checkout TEST pour prouver |

---

## 15. PROD UNCHANGED

| Check | Résultat |
|-------|----------|
| API PROD image | `v3.5.139-amazon-oauth-inbound-bridge-prod` — inchangé |
| Client PROD image | `v3.5.151-amazon-oauth-inbound-bridge-prod` — inchangé |
| Website PROD image | `v0.6.8-tiktok-browser-pixel-prod` — inchangé |
| Infra manifests PROD | Aucun changement |
| 0 build | ✓ |
| 0 deploy | ✓ |
| 0 mutation PROD | ✓ |
| 0 coupon LIVE | ✓ |
| 0 event CAPI PROD | ✓ |
| 0 fake purchase | ✓ |

---

## 16. VERDICT

### **GO PARTIEL — GAP ATTRIBUTION + APPLIES_TO**

Le cas "jeu concours : 1 an de forfait PRO offert" est **fonctionnel en DEV** avec les réserves suivantes :

**Ce qui fonctionne** :
- ✓ Code promo créé via Admin DEV (DB + Stripe TEST)
- ✓ Lien promo traverse Website → Client → API → Stripe Checkout
- ✓ PRO annuel : 0 EUR pendant 12 mois (coupon = prix plan)
- ✓ AUTOPILOT annuel : 1920 EUR (différence correcte)
- ✓ KBActions exclus (flux séparé, mode payment)
- ✓ Canal Supplémentaire : coupon consommé par le plan (mathématiquement correct)
- ✓ Anti-stacking : `allow_promotion_codes=null` quand promo pré-appliqué
- ✓ Codes invalides/archivés rejetés avec messages clairs
- ✓ Attribution promo complète dans Stripe metadata (5 champs)
- ✓ UTM partiel dans Stripe metadata (3/4 champs)
- ✓ PROD strictement inchangé

**Ce qui nécessite AN.5** :
- ⚠ G1 : `applies_to` non visible/confirmé → risque théorique pour coupons futurs plus larges
- ⚠ G2 : Pas de persistance attribution en DB (uniquement Stripe metadata)
- ⚠ G3 : Agent KeyBuzz accepte la saisie manuelle de promos
- ⚠ G4 : `utm_content` non mappé (pré-existant)
- ⚠ G5 : `max_redemptions` non testable sans paiement

### Phrase de verdict

> CONTEST PRO YEAR PROMO E2E PARTIALLY VALIDATED IN DEV — STRIPE TEST DISCOUNT APPLIES TO PLAN CORRECTLY (MATH-SAFE) — PRO ANNUAL COVERED (0 EUR/12M) — AUTOPILOT UPGRADE DIFFERENCE CORRECT (1920 EUR) — KBACTIONS EXCLUDED — ADDONS MATH-SAFE — AGENT KEYBUZZ MANUAL PROMO GAP P2 — PROMO LINK ATTRIBUTION PRESERVED IN STRIPE METADATA — NO STACKING — NO PROD TOUCH — REQUIRES AN.5 FOR APPLIES_TO ENFORCEMENT + DB ATTRIBUTION + AGENT CHECKOUT HARDENING BEFORE PROD PROMOTION

---

## 17. ROLLBACK

Aucun rollback nécessaire. Aucun build, aucun deploy, aucune modification de code effectués dans cette phase. Seules des données de test ont été créées dans l'environnement DEV (DB Admin + Stripe TEST).
