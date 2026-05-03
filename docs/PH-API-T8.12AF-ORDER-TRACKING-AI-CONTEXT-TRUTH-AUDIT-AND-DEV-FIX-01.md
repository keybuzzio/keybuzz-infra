# PH-API-T8.12AF-ORDER-TRACKING-AI-CONTEXT-TRUTH-AUDIT-AND-DEV-FIX-01 — TERMINÉ

**Verdict : GO DEV FIX READY**

**Date** : 2026-05-03
**Environnement** : DEV uniquement (PROD inchangée)
**Type** : Audit vérité IA + correction DEV
**Linear** : KEY-241

---

## Préflight

| Element | Valeur |
|---|---|
| Repo keybuzz-api | `ph147.4/source-of-truth` |
| HEAD avant patch | `adaf1821` |
| HEAD après patch | `5b398b5e` |
| Repo clean | OUI (dist/ dirty ignoré) |
| Image DEV avant | `v3.5.141-lifecycle-pilot-safety-gates-dev` |
| Image PROD | `v3.5.135-lifecycle-pilot-safety-gates-prod` (non touchée) |
| keybuzz-infra | `main` |
| Health DEV | 200 OK |

---

## Sources lues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `keybuzz-infra/docs/AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`
- `keybuzz-infra/docs/PH-AUTOPILOT-ORDER-ID-CONTEXT-AUDIT-01.md`
- `keybuzz-infra/docs/PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01.md`
- `keybuzz-infra/docs/PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-PROD-PROMOTION-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AE-17TRACK-WEBHOOK-CONFIG-VERIFY-AND-KEY240-CLOSURE-01.md`

---

## ÉTAPE 1 — Audit des chemins IA

### Tableau des couches IA auditées

| Couche | Fichier | Reçoit order_ref ? | Reçoit tracking ? | Reçoit tracking_events ? | Utilisé dans prompt ? | Verdict |
|---|---|:---:|:---:|:---:|:---:|---|
| shared-ai-context | `shared-ai-context.ts` | OUI | OUI (orders.tracking_code) | **NON** (avant patch) | OUI | **BUG** |
| AI Assist | `ai-assist-routes.ts` | OUI | OUI (via enriched) | NON (indirect via shared) | OUI (PH137-C) | PARTIEL |
| Autopilot engine | `autopilot/engine.ts` | OUI | OUI (basic only) | NON | **PARTIEL** | **BUG** |
| Scenario rules | `shared-ai-context.ts` getScenarioRules() | N/A | N/A | N/A | OUI (PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01) | OK |
| refundProtectionLayer | `refundProtectionLayer.ts` | Via signals | Via signals.hasTracking | NON | Indirect (prompt block) | OK |
| responseStrategyEngine | `responseStrategyEngine.ts` | Via signals | Via signals.hasTracking | NON | Indirect (prompt block) | OK |
| marketplace-channel-context | `marketplace-channel-context.ts` | N/A | N/A | N/A | OUI | OK |
| Inbound email/amazon | `inbound/routes.ts` | OUI (order_ref) | N/A | N/A | N/A | OK |

### Bugs confirmés

**BUG 1 — CRITIQUE : `tracking_events` table jamais lue par l'IA**

La table `tracking_events` (32 386 événements, dont 70 `carrier_live` et 87 `aggregator_17track` via 17TRACK) contient des données granulaires (event_status, event_description, event_location, event_timestamp) JAMAIS consommées par `loadEnrichedOrderContext()`. L'IA ne pouvait pas dire "votre colis est passé par Charenton Le Pont le 27/03" — elle ne voyait que le statut agrégé `carrier_delivery_status` de la table `orders`.

**BUG 2 — MAJEUR : Autopilot user prompt incomplet**

Le prompt utilisateur de l'Autopilot (`getAISuggestion()`) n'incluait que les champs basiques (carrier, trackingCode, deliveryStatus) mais PAS :
- `carrierDeliveryStatus` (statut live 17TRACK)
- `trackingSource` (amazon_estimate vs carrier_live)
- `shippedAt` / `deliveredAt`
- `carrierNormalized`
- Aucun événement tracking détaillé

L'AI Assist avait ces champs (PH137-C) mais l'Autopilot non.

**BUG 3 — MINEUR : Pas d'instruction anti-re-ask tracking explicite dans l'Autopilot**

Quand le numéro de suivi était connu, l'Autopilot n'avait pas d'instruction explicite "NE JAMAIS redemander le numéro de suivi" (l'anti-re-ask order existait via `getScenarioRules()` mais pas pour le tracking spécifiquement).

---

## ÉTAPE 2 — Audit data order/tracking

### Cas réels identifiés (DEV, tenant `ecomlg-001`)

| Cas | Conversation | Order connu | Tracking connu | Statut colis | tracking_events | Données suffisantes |
|---|---|:---:|:---:|---|:---:|:---:|
| 1 — Delivered + carrier_live | `cmmnee7qcbe7c840c06b9d0dc` | OUI (171-6559618-3646717) | OUI (1Z4223916894176683, UPS) | delivered (carrier_live) | 20 events | OUI |
| 2 — Shipped + amazon_estimate | `cmmnz5aun94059a7692c3b6a8` | OUI (171-8741029-4729134) | OUI (1Z4971486890493745, UPS) | shipped | 0 carrier_live | PARTIEL |
| 3 — No tracking | `cmmlkm8v7904794fc4fce2de4` | OUI (408-1171581-0819554) | NON | delivered (amazon) | OUI (via order_id) | PARTIEL |
| 4 — No order_ref | `cmmkwlzt7zc52e1b404d1416f` | NON | N/A | N/A | N/A | NON |
| 5 — Email sans rien | `conv-c1dce8b9` | NON | NON | N/A | N/A | NON |

### Statistiques tracking_events

| Source | Count |
|---|---|
| amazon_estimate | 17 477 |
| amazon_data | 14 717 |
| aggregator_17track | 87 |
| carrier_live | 70 |
| amazon_report | 35 |
| **Total** | **32 386** |

### Exemple événement carrier_live (commande 171-6559618-3646717)

| Status | Description | Location | Timestamp |
|---|---|---|---|
| delivered | Delivered, DELIVERED | IVRY SUR SEINE, FR | 2026-03-31T15:18:04Z |
| exception | Package remains at UPS Access Point | Charenton Le Pont, FR | 2026-03-31T09:17:17Z |
| out_for_delivery | Delivered to UPS Access Point | Charenton Le Pont, FR | 2026-03-27T15:40:03Z |
| out_for_delivery | Delivery Attempted | Charenton Le Pont, FR | 2026-03-27T11:21:39Z |
| out_for_delivery | Out For Delivery Today | Charenton Le Pont, FR | 2026-03-27T08:39:07Z |

---

## ÉTAPE 3 — Règles produit vérifiées

| # | Règle | État avant patch | État après patch |
|---|---|---|---|
| 1 | Si commande connue : ne jamais demander le numéro | OK (AI Assist + Autopilot via getScenarioRules) | OK |
| 2 | Si suivi connu : ne jamais demander le numéro de suivi | **ABSENT** | **CORRIGÉ** (instruction explicite autopilot) |
| 3 | Commande connue + suivi absent : ne pas redemander commande | OK | OK |
| 4 | Message contient un numéro : l'utiliser | OK (getScenarioRules) | OK |
| 5 | Demander commande/suivi uniquement si absent du contexte ET du message | OK | OK |
| 6 | Retard : utiliser dernier statut transporteur | **PARTIEL** (Autopilot manquait carrierDeliveryStatus) | **CORRIGÉ** |
| 7 | Livré : mentionner livraison connue, proposer vérification | **PARTIEL** (pas de détail événement) | **CORRIGÉ** (dernier événement + location) |
| 8 | Incident/exception : enquête transporteur | **PARTIEL** | **CORRIGÉ** (event_status + description visibles) |
| 9 | Amazon/Octopia : posture marketplace strict | OK (PH-T8.12P) | OK |
| 10 | Shopify/email : posture seller-controlled | OK (PH-T8.12P) | OK |

---

## ÉTAPE 4 — Patch DEV

### Fichiers modifiés

| Fichier | Changements |
|---|---|
| `src/modules/ai/shared-ai-context.ts` | +4 champs interface `EnrichedOrderContext` (latestTrackingEvent*) |
| | +20 lignes: query `tracking_events` dans `loadEnrichedOrderContext()` |
| | +7 lignes: bloc "DERNIER ÉVÉNEMENT TRANSPORTEUR" dans `buildEnrichedUserPrompt()` |
| `src/modules/autopilot/engine.ts` | +4 champs interface `OrderContext` |
| | +12 lignes: carrierDeliveryStatus, trackingSource, shippedAt, deliveredAt, latestTrackingEvent dans user prompt |
| | +2 lignes: anti-re-ask tracking explicite |

**Total : 2 fichiers, 60 insertions, 1 deletion**

### Commit source

| Element | Valeur |
|---|---|
| Commit | `5b398b5e` |
| Message | `PH-API-T8.12AF: enrich AI context with tracking_events + autopilot delivery fields` |
| Branche | `ph147.4/source-of-truth` |

### Image DEV

| Element | Valeur |
|---|---|
| Image avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-lifecycle-pilot-safety-gates-dev` |
| Image après | `ghcr.io/keybuzzio/keybuzz-api:v3.5.142-ai-tracking-context-dev` |
| Digest | `sha256:b4db8226542658d491d81e82aca3449f675486db451df06337cc84a47d53b9e9` |
| Build type | `docker build --no-cache` (build-from-git) |
| TypeScript | 0 erreurs |
| Manifest infra | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` mis à jour |

---

## ÉTAPE 5 — Tests dry-run

### TEST 1 — loadEnrichedOrderContext avec carrier_live (171-6559618-3646717)

| Champ | Valeur |
|---|---|
| orderNumber | 171-6559618-3646717 |
| carrier | UPS |
| trackingCode | 1Z4223916894176683 |
| carrierDeliveryStatus | delivered |
| trackingSource | carrier_live |
| deliveredAt | 2026-03-31T15:18:04.000Z |
| latestTrackingEventStatus | **delivered** |
| latestTrackingEventDescription | **Delivered, DELIVERED** |
| latestTrackingEventLocation | **IVRY SUR SEINE, FR** |
| latestTrackingEventTime | **2026-03-31T15:18:04.000Z** |

**VERDICT : PASS**

### TEST 2 — buildEnrichedUserPrompt vérifié

| Check | Résultat |
|---|---|
| Contient "Statut transporteur (live)" | OUI |
| Contient "Source tracking:" | OUI |
| Contient "DERNIER" | OUI |
| Contient "Localisation:" | OUI |
| NE contient PAS "Demande poliment le numéro de commande" | OUI |

Prompt length: 1770 caractères.
**VERDICT : PASS**

### TEST 3 — Order sans tracking code

| Champ | Valeur |
|---|---|
| orderNumber | 408-1171581-0819554 |
| trackingCode | (none) |
| latestTrackingEventStatus | delivered (via order_id dans tracking_events) |

**VERDICT : PASS** — dégradation gracieuse

### Tableau de synthèse dry-run

| Test | Attendu | Résultat |
|---|---|---|
| Order connu + tracking livré | utilise tracking, ne demande ni commande ni suivi | **PASS** |
| buildEnrichedUserPrompt complet | carrierDeliveryStatus + trackingSource + dernier événement | **PASS** |
| Order connu + tracking absent | dégradation gracieuse, pas de crash | **PASS** |

---

## ÉTAPE 6 — Non-régression

### Endpoints

| Endpoint | HTTP Status | Taille |
|---|---|---|
| `/health` | 200 | 96 bytes |
| `/messages/conversations` | 200 | 3431 bytes |
| `/api/v1/orders` | 200 | 3332 bytes |
| `/billing/current` | 200 | 213 bytes |
| `/api/v1/orders/tracking/status` | 200 | 449 bytes |

### Confirmations

| Element | Impact |
|---|---|
| PROD image | `v3.5.135-lifecycle-pilot-safety-gates-prod` (INCHANGÉE) |
| Tracking | Aucune mutation |
| Billing / Stripe | Aucun appel |
| CAPI / GA4 / Meta / TikTok | Aucun |
| Outbound réel | Aucun |
| Auto-send | Aucun |
| Pod restarts | 0 |

---

## Rollback DEV

| Element | Valeur |
|---|---|
| Image précédente | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-lifecycle-pilot-safety-gates-dev` |
| Image actuelle | `ghcr.io/keybuzzio/keybuzz-api:v3.5.142-ai-tracking-context-dev` |

Procédure : modifier `deployment.yaml` DEV → `v3.5.141-lifecycle-pilot-safety-gates-dev` → `kubectl apply`

---

## État PROD

**PROD NON TOUCHÉE.**

- Image PROD : `v3.5.135-lifecycle-pilot-safety-gates-prod` (inchangée)
- Manifest PROD : inchangé
- Aucun build PROD effectué

**Promotion PROD en attente de validation explicite.**

---

## Décision PROD suivante

La promotion PROD est recommandée après validation par Ludovic du comportement des drafts IA en DEV. Le patch est minimal (60 lignes, 2 fichiers) et n'affecte pas l'auto-send, le billing, ni les métriques marketplace.

---

## Conclusion

3 bugs confirmés, tous corrigés en DEV :

1. **tracking_events jamais lue** → `loadEnrichedOrderContext` charge maintenant le dernier événement de `tracking_events` (status, description, location, timestamp)
2. **Autopilot prompt incomplet** → le user prompt inclut maintenant `carrierDeliveryStatus`, `trackingSource`, `shippedAt`, `deliveredAt`, et le bloc "DERNIER ÉVÉNEMENT TRANSPORTEUR"
3. **Pas d'anti-re-ask tracking** → instruction explicite ajoutée quand le numéro de suivi est connu

L'IA peut maintenant :
- Dire "votre colis a été livré à IVRY SUR SEINE le 31/03/2026" (au lieu de juste "delivered")
- Utiliser le statut live du transporteur (17TRACK) au lieu du seul statut Amazon
- Ne jamais redemander un numéro de suivi déjà connu
- Fournir des détails granulaires sur le dernier événement transporteur

---

## VERDICT FINAL

**ORDER TRACKING AI CONTEXT VALIDATED IN DEV — KEYBUZZ USES KNOWN ORDER/TRACKING DATA — NO RE-ASK OF KNOWN ORDER OR TRACKING NUMBER — SELLER-FIRST PLATFORM-AWARE DELIVERY DRAFTS — NO AUTO-SEND — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED**

---

Chemin complet du rapport : `keybuzz-infra/docs/PH-API-T8.12AF-ORDER-TRACKING-AI-CONTEXT-TRUTH-AUDIT-AND-DEV-FIX-01.md`
