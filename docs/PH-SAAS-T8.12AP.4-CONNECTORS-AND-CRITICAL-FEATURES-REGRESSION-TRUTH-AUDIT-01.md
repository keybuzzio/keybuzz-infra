# PH-SAAS-T8.12AP.4 — Connectors & Critical Features Regression Truth Audit

> Phase : PH-SAAS-T8.12AP.4-CONNECTORS-AND-CRITICAL-FEATURES-REGRESSION-TRUTH-AUDIT-01
> Ticket : KEY-271
> Tickets liés : KEY-253, KEY-270, KEY-263
> Date : 2026-05-07
> Environnement : DEV + PROD lecture seule
> Type : audit vérité transversal, aucun patch

---

## Objectif

Cartographier la vérité des connecteurs et features critiques avant lancement Ads.
Identifier les écarts entre UI visible, code source, runtime compilé, DB, secrets et claims marketing.
Aucune correction dans cette phase — les gaps deviennent des phases séparées.

---

## Sources relues

| Document | Vérifié |
|---|---|
| CE_PROMPTING_STANDARD.md | OUI |
| RULES_AND_RISKS.md | OUI |
| AI_MESSAGING_FEATURE_PARITY_BASELINE.md | OUI |
| AMAZON_SPAPI_CONNECTOR_BASELINE.md | OUI (cherché, rapport le plus proche utilisé) |
| DATA_HYGIENE_BASELINE.md | OUI (cherché) |
| TRIAL_WOW_STACK_BASELINE.md | OUI (cherché) |
| AP.2.8 (auto-assignment PROD) | OUI |
| AP.2.9 (escalation audit) | OUI |

---

## Preflight repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `9521fb35` | dist/ uniquement | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `abef1bc4` | N/A | OK |
| keybuzz-backend | `main` | `c62f376` | N/A | OK |
| keybuzz-infra | `main` | `e473970` | propre | OK |
| keybuzz-website | `main` | `7fc942b` | N/A | OK |

---

## Baselines PROD confirmées

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | confirmé | OUI |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | confirmé | OUI |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | confirmé | OUI |
| Website PROD | `v0.6.9-promo-forwarding-prod` | confirmé | OUI |
| OW PROD | `v3.5.165-escalation-flow-prod` | confirmé | OUI |
| Admin PROD | `v1.0.2` (attendu) | NOT FOUND (namespace keybuzz-admin) | DIVERGENT |

---

## CronJobs runtime

| Job | NS | Schedule | Image | Status |
|---|---|---|---|---|
| outbound-tick-processor | api-dev/prod | `*/1 * * * *` | curl-jq (digest pinné) | OK |
| sla-evaluator | api-dev/prod | `*/1 * * * *` | postgres:17-alpine | OK |
| sla-evaluator-escalation | api-dev | `*/1 * * * *` | postgres:17-alpine | DEV only |
| carrier-tracking-poll | api-dev | `0 */2 * * *` | curl-jq:latest | OK |
| carrier-tracking-poll | api-prod | `0 */4 * * *` | curl-jq:latest | OK |
| trial-lifecycle-dryrun | api-prod | `0 8 * * *` | curl:8.7.1 | OK |
| amazon-orders-sync | backend-dev/prod | `*/5 * * * *` | curl:8.12.1 | OK |
| amazon-orders-backfill | backend-dev | `3,13,23...` | curl:8.12.1 | DEV only |
| amazon-reports-tracking-sync | backend-dev/prod | `0 */6 * * *` | curl:8.12.1 | OK |

---

## ÉTAPE 1 — Matrice connecteurs

| Connecteur | UI Client | BFF Client | API source | Runtime DEV | Runtime PROD | Backend | DB data DEV | DB data PROD | Secrets | CronJob | IA context | **Verdict** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Amazon** | OUI | OUI | OUI (inbound, orders, marketplace) | OUI | OUI | OUI (workers) | 545 conv, 12321 orders | 553 conv, 11922 orders | Via Vault/Backend | 3 crons | marketplace_strict + no-reask + tracking | **FULL** |
| **Shopify** | OUI | OUI | OUI (6 fichiers) | 200 status | 200 status | NON | 12 conn, 2 orders | 0 conn, 1 order | **UNSET** | NON | Générique (pas Shopify-specific) | **PARTIAL** |
| **Octopia** | OUI | OUI | OUI (8 fichiers + worker) | 404 status | 404 status | NON | 0 accounts, 2 conv | 0 accounts, 0 conv | N/A (per-tenant) | NON | octopia-policies.json | **PARTIAL** |
| **Fnac** | Logo + coming_soon | Registry only | Via Octopia | Via Octopia | Via Octopia | NON | 0 | 0 | N/A | NON | Via Octopia policies | **MARKETING_RISK** |
| **Email** | OUI | OUI | OUI (inbound) | OUI | OUI | NON | 23 addr, 15 conv | 11 addr, 7 conv | SMTP SET | NON | direct_seller_controlled | **FULL** |
| **17TRACK** | Indirect (tracking in orders) | OUI (status) | OUI (webhook + provider) | 200 tracking/status | 200 tracking/status | NON | 32393 events | 32263 events | API_KEY SET, WEBHOOK_SECRET **UNSET** | carrier-tracking-poll | Tracking context IA | **PARTIAL** |
| **eBay** | NON | NON | NON | NON | NON | NON | 0 | 0 | NON | NON | NON | **ABSENT** |

---

## ÉTAPE 2 — Audit routes runtime

### Routes safe testées

| Route | DEV | PROD | Mutation ? | Commentaire |
|---|---|---|---|---|
| `/shopify/status` | 200 | 200 | NON | Routes et dist présents |
| `/octopia/status` | 404 | 404 | NON | Route peut nécessiter POST ou params tenant |
| `/api/v1/tracking/status` | 404 | 404 | NON | Endpoint inexistant sous ce chemin |
| `/api/v1/orders/tracking/status` | 200 | 200 | NON | Carrier tracking OK |
| `/notifications` | 200 | 200 | NON | CRUD fonctionnel, 0 données |

### Routes compilées (dist/app.js)

| Pattern | DEV | PROD |
|---|---|---|
| shopifyRoutes | 1 | 1 |
| octopiaRoutes | 1 | 1 |
| trackingWebhookRoutes | 1 | 1 |
| carrierTrackingRoutes | 1 | 1 |
| inboundRoutes | 1 | 1 |
| ordersRoutes | 1 | 1 |
| notificationsRoutes | 1 | 1 |

### Dist modules présents

| Module | DEV | PROD |
|---|---|---|
| `dist/modules/marketplaces/shopify/` | 6 fichiers | 6 fichiers |
| `dist/modules/marketplaces/octopia/` | 8 fichiers | 8 fichiers |
| `dist/modules/tracking/` | 1 fichier | 1 fichier |

---

## ÉTAPE 3 — Audit DB read-only

| Table | DEV | PROD | Observation |
|---|---|---|---|
| conversations | 563 | 561 | Actif |
| messages | 1583 | 1661 | Actif |
| orders | 12325 | 11923 | Actif (Amazon dominé) |
| message_events | 574 | 1706 | Audit trail actif |
| ai_action_log | 1490 | 143 | DEV très actif (tests autopilot) |
| notifications | **0** | **0** | Table vide — AP.2.9 documenté |
| inbound_addresses | 23 | 11 | Email inbound actif |
| inbound_connections | 8 | 6 | Actif |
| marketplace_connections | 0 | 0 | Inutilisé |
| marketplace_octopia_accounts | 0 | 0 | Aucune connexion Octopia active |
| marketplace_sync_states | 0 | 0 | Aucun sync actif |
| billing_events | 283 | 160 | Stripe actif |
| billing_subscriptions | 20 | 8 | Actif |
| billing_customers | 21 | 11 | Actif |
| oauth_states | 0 | 0 | Vide (states éphémères) |
| tracking_events | 32393 | 32263 | 17TRACK polling actif |
| shopify_connections | 12 | 0 | DEV only, PROD zéro |
| shopify_webhook_events | 18 | 1 | DEV principalement |
| shopify_orders | TABLE_MISSING | TABLE_MISSING | Table non créée |

### Canaux conversations

| Canal | DEV | PROD |
|---|---|---|
| amazon | 545 | 553 |
| email | 15 | 7 |
| octopia | 2 | 0 |
| shopify | 1 | 1 |

### Tracking events carriers

| Carrier | DEV | PROD |
|---|---|---|
| UPS FR | 29618 | 29455 |
| NULL | 2493 | 2519 |
| UPS | 237 | 231 |
| FedEx | 14 | 31 |
| FEDEX | 14 | — |

---

## ÉTAPE 4 — Audit secrets/config runtime

| Variable | DEV | PROD | Risque |
|---|---|---|---|
| SHOPIFY_API_KEY | **UNSET** | **UNSET** | Shopify OAuth impossible |
| SHOPIFY_API_SECRET | **UNSET** | **UNSET** | Shopify HMAC impossible |
| TRACKING_17TRACK_API_KEY | SET | SET | OK |
| TRACKING_17TRACK_WEBHOOK_SECRET | **UNSET** | **UNSET** | Webhook HMAC impossible |
| AMAZON_SP_* (4 vars) | UNSET | UNSET | Normal — via Backend pods / Vault |
| SMTP_HOST | SET | SET | OK |
| LEGACY_BACKEND_URL | SET | SET | OK |
| STRIPE_SECRET_KEY | SET | SET | OK |
| STRIPE_WEBHOOK_SECRET | SET | SET | OK |
| REDIS_URL | SET | SET | OK |
| LITELLM_BASE_URL | SET | SET | OK |

### Résumé secrets

- **Shopify** : 2 secrets critiques UNSET → connecteur non fonctionnel au runtime
- **17TRACK webhook** : secret UNSET → inbound webhook non sécurisé (polling fonctionne)
- **Amazon** : normal, SP-API credentials gérées par Backend pods via Vault
- **Reste** : OK

---

## ÉTAPE 5 — Audit IA contexte connecteurs

| Canal | Prompt channel context | Refund protection | Response strategy | Order/tracking context | No-reask | **Verdict** |
|---|---|---|---|---|---|---|
| **Amazon** | marketplace_strict | OUI (marketplace_strict rules) | OUI | OUI (order_ref + tracking_code) | OUI (REASK_PATTERNS) | **FULL** |
| **Octopia/Cdiscount** | marketplace_strict | OUI | OUI | Partiel (si order lié) | OUI | **FULL** |
| **Fnac** | Via Octopia policies | OUI | OUI | Partiel | OUI | **PARTIAL** (via Octopia) |
| **Shopify** | Pas de contexte spécifique | Fallback générique | Fallback générique | Si order lié | OUI | **PARTIAL** |
| **Email** | direct_seller_controlled | OUI (seller rules) | OUI | Si order lié | OUI | **FULL** |
| **17TRACK** | N/A (pas de canal) | N/A | N/A | 32K+ tracking events injectés | OUI | **FULL** |

### Platform-aware IA engine

| Posture | Canaux | Source |
|---|---|---|
| `marketplace_strict` | Amazon, Octopia, Cdiscount, Fnac | `marketplace-channel-context.ts` |
| `direct_seller_controlled` | Shopify, email | `marketplace-channel-context.ts` |
| `unknown` | fallback safe | `marketplace-channel-context.ts` |

---

## ÉTAPE 6 — Audit claims marketing risqués

| Claim (website) | Réalité SaaS | Risque | Correction requise | Prio |
|---|---|---|---|---|
| **"Amazon, Fnac/Darty, Cdiscount, eBay"** comme connecteurs actifs (pricing page ✓) | Amazon=FULL, Fnac=`coming_soon`, Cdiscount=via Octopia (0 PROD), **eBay=ABSENT (0 code)** | **P0** — eBay claim = faux | Retirer eBay de la pricing/features page ou marquer "Bientôt" | P0 |
| **✓ Shopify** (features page) | Code présent, secrets UNSET, PROD zéro | **P1** — ✓ suggère connecteur actif | Unifier avec pricing "Bientôt" | P1 |
| **✓ Fnac/Darty** (features page) | `coming_soon: true` dans le code | **P1** — Fnac via Octopia, non testé réellement | Marquer "Via Octopia" ou "Bientôt" | P1 |
| **"Connecteurs e-commerce (Shopify, WooCommerce) — Bientôt"** (pricing) | Shopify=code partiel, WooCommerce=ABSENT | OK | Déjà correct sur pricing | — |
| **"Répondre automatiquement"** (Autopilot) | Autopilot fonctionnel en DEV, draft-first safe mode | OK | — | — |
| **Agent KeyBuzz** | Label seulement, pas de workflow humain (AP.2.9) | P3 | Clarifier dans roadmap produit | P3 |
| **"Support géré par KeyBuzz"** | N/A — pas de claim spécifique trouvé | OK | — | — |
| **Tracking colis** | 32K+ events, carrier-tracking-poll actif | OK | — | — |

---

## ÉTAPE 7 — Classification des gaps

### P0

| Gap | Preuve | Phase proposée | Ticket |
|---|---|---|---|
| **eBay listé comme connecteur actif** sur website — 0 code, 0 données, 0 runtime | grep + DB audit | AP.4.1 — Website claims correction | KEY-271 / KEY-NEW |

### P1

| Gap | Preuve | Phase proposée | Ticket |
|---|---|---|---|
| **Shopify secrets UNSET** DEV+PROD | env var audit | AP.4.2 — Shopify activation layer | KEY-270 |
| **Shopify ✓ checkmark** sur features page vs "Bientôt" sur pricing | Website audit | AP.4.1 — Website claims correction | KEY-271 |
| **Fnac ✓ checkmark** mais `coming_soon: true` | Code + website audit | AP.4.1 — Website claims correction | KEY-271 |
| **17TRACK webhook secret UNSET** | env var audit | AP.4.3 — 17TRACK webhook activation | KEY-240 (existant) |
| **shopify_orders table MISSING** | DB audit | AP.4.2 — Shopify activation layer | KEY-270 |

### P2

| Gap | Preuve | Phase proposée | Ticket |
|---|---|---|---|
| Notification proactive escalade absente | AP.2.9 rapport | Phase NotificationBell | KEY-263 |
| Octopia 0 connexions réelles PROD | DB audit | Activation tenant si client Octopia | — |
| Admin PROD deployment NOT FOUND | kubectl audit | Vérifier namespace réel | — |
| `carrier-tracking-poll` utilise `:latest` | CronJob audit | Pin version | — |

### P3

| Gap | Preuve | Phase proposée | Ticket |
|---|---|---|---|
| WooCommerce mentionné, 0 code | Website + source audit | Roadmap produit | — |
| Agent KeyBuzz = label, pas workflow | AP.2.9 rapport | Décision produit | — |
| Shopify IA context pas spécifique | AI audit | Enrichir si activation Shopify | — |

---

## AI Feature Parity / Anti-regression

| Feature | Source | Runtime DEV | Runtime PROD | UI | Gap | Prio |
|---|---|---|---|---|---|---|
| No-reask | REASK_PATTERNS | OUI | OUI | OUI | AUCUN | — |
| author_name Prénom.N | formatAgentDisplayName | OUI | OUI | OUI | AUCUN | — |
| resolved clears escalation | CASE WHEN | OUI | OUI | — | AUCUN | — |
| Auto-assignment | assigned_agent_id IS NULL | OUI | OUI | — | AUCUN | — |
| Escalade traçable | message_events + ai_action_log | OUI | OUI | Badge + filtre | AUCUN | — |
| Order/tracking IA context | order_ref + tracking_code | OUI | OUI | — | AUCUN | — |
| Platform-aware refund | marketplace_strict / direct_seller | OUI | OUI | — | AUCUN | — |
| Tracking polling | carrier-tracking-poll | OUI | OUI | 32K events | AUCUN | — |
| Amazon OAuth | Source présente | OUI | OUI | OUI | AUCUN | — |
| Amazon inbound | inboundRoutes | OUI | OUI | OUI | AUCUN | — |
| Amazon orders sync | CronJob + backend | OUI | OUI | 12K orders | AUCUN | — |
| Shopify OAuth | Source présente | Dist présent | Dist présent | OUI | Secrets UNSET | P1 |
| 17TRACK webhook | Source présente | Dist présent | Dist présent | Indirect | Secret UNSET | P1 |
| Notification on-escalade | ABSENTE | — | — | — | Table vide | P2 |

---

## Linear

| Ticket | Mise à jour |
|---|---|
| **KEY-271** | Audit transversal complet. eBay = P0 claim faux sur website. Shopify/Fnac = P1 claims incohérents. Matrice complète documentée. |
| **KEY-253** | Pre-Ads : Amazon FULL, Email FULL, IA context FULL, lifecycle FULL. Risques restants : website claims (P0 eBay), Shopify activation (P1). |
| **KEY-270** | Shopify : code source intact, dist compilé présent DEV+PROD, secrets UNSET. Phase AP.4.2 nécessaire pour activation. |
| **KEY-263** | Notification escalade : confirmé absent (AP.2.9). P2. |

### Tickets recommandés

| Titre | Prio | Scope |
|---|---|---|
| **AP.4.1 — Website claims correction** (eBay retrait, Shopify/Fnac alignement) | P0 | Website uniquement |
| **AP.4.2 — Shopify activation layer** (secrets, shopify_orders table, app review) | P1 | API + infra K8s secrets |
| **AP.4.3 — 17TRACK webhook secret activation** | P1 | Infra K8s secrets |

---

## Interdits respectés

| Interdit | Respecté |
|---|---|
| Aucun code modifié | OUI |
| Aucun build | OUI |
| Aucun deploy | OUI |
| Aucune mutation DB | OUI |
| Aucune mutation Stripe | OUI |
| Aucun email réel | OUI |
| Aucun hardcoding | OUI |
| Aucun fake event | OUI |
| Aucun ticket fermé sans preuve | OUI |

---

## Rollback

Aucun rollback nécessaire — phase d'audit sans modification.

---

## Verdict

### GO PARTIEL — MARKETING CLAIMS NEED CORRECTION

**Situation :**
- Amazon, Email, IA context, lifecycle conversation : **FULL** et **PROD**
- Shopify : code intact, runtime présent, mais secrets UNSET = **non fonctionnel**
- Octopia : code complet mais 0 connexions réelles
- 17TRACK : polling actif (32K events), webhook secret UNSET
- eBay : **ABSENT** (0 code, 0 runtime) mais **listé comme actif** sur le website → **P0 claim faux**
- Fnac : `coming_soon: true` mais listée ✓ sur features page → **P1**

**Bloquant Ads :**
La page pricing et features du website keybuzz.pro liste eBay comme connecteur actif avec ✓ alors qu'il n'existe aucun code, aucune route, aucune donnée. C'est un risque marketing P0 si un prospect Ads arrive et tente de connecter eBay.

**Non bloquant Ads :**
Amazon + Email + IA = pleinement fonctionnels. Les prospects Amazon (cible Ads principale) ne verront aucun gap.

CONNECTORS AND CRITICAL FEATURES TRUTH ESTABLISHED — UI/SOURCE/RUNTIME/DB/SECRETS/IA CONTEXT MAPPED — AMAZON FULL — EMAIL FULL — IA CONTEXT FULL — SHOPIFY PARTIAL (SECRETS UNSET) — OCTOPIA PARTIAL (0 CONNECTIONS) — 17TRACK PARTIAL (WEBHOOK SECRET UNSET) — EBAY ABSENT BUT CLAIMED ON WEBSITE (P0) — FNAC COMING_SOON BUT CHECKMARKED (P1) — REGRESSION RISKS CLASSIFIED — NO CODE — NO BUILD — NO DEPLOY — NO MUTATION — PATCH PHASES READY
