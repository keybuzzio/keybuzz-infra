# PH-SAAS-T8.12AP.3 — Pre-Ads Feature Baseline Memory and Linear Closure

> Phase : PH-SAAS-T8.12AP.3-PRE-ADS-FEATURE-BASELINE-MEMORY-AND-LINEAR-CLOSURE-01
> Date : 8 mai 2026
> Ticket : KEY-270
> Type : Documentation-only, NO CODE / NO BUILD / NO DEPLOY / NO MUTATION
> Priorité : P0
> Verdict : **GO PRE-ADS BASELINE LOCKED**

---

## 1. Preflight

### Repo keybuzz-infra
- Branche : `main`
- HEAD : `7091bb4` — docs: rapport AP.4.2B
- État : clean (5 fichiers modifiés d'autres phases, 60+ fichiers untracked d'autres phases, aucun lié à AP.3)

### Runtimes PROD vérifiés (read-only, 8 mai 2026 00:30 UTC+2)

| Service | Image attendue | Image runtime | Verdict |
|---|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.147-auto-assignment-after-reply-prod` | ✅ |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | `v3.5.170-shopify-visible-disabled-channels-prod` | ✅ |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | ✅ |
| Website | `v0.6.10-connector-claims-truth-prod` | `v0.6.10-connector-claims-truth-prod` | ✅ |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | ✅ |
| Admin | `v2.12.1-promo-codes-foundation-prod` | `v2.12.1-promo-codes-foundation-prod` | ✅ |
| carrier-tracking-poll PROD | Suspendu | `suspend: true` | ✅ |
| trial-lifecycle-dryrun PROD | Dry-run | `curlimages/curl:8.7.1`, schedule `0 8 * * *` | ✅ |

**0 écart baseline. Toutes les images runtime correspondent aux attentes.**

---

## 2. Sources relues

### Mémoires durables (6/6)

| Fichier | Statut |
|---|---|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | ✅ Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | ✅ Lu |
| `AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` | ✅ Lu |
| `AI_MEMORY/AMAZON_SPAPI_CONNECTOR_BASELINE.md` | ✅ Lu |
| `AI_MEMORY/AI_MESSAGING_FEATURE_PARITY_BASELINE.md` | ✅ Lu |
| `AI_MEMORY/DATA_HYGIENE_BASELINE.md` | ✅ Lu |

### Rapports AP (15/15)

| Rapport | Verdict | Résumé |
|---|---|---|
| AP — Media Buyer Brief | GO PARTIEL | 45 promesses auditées, 12 blocs, P0/P1 identifiés |
| AP.1A — AI no-reask Client DEV | GO DEV | Client v3.5.163, orderRef injecté, instruction anti-reask |
| AP.1B — AI no-reask Client PROD | GO PARTIEL | PROD v3.5.163, bundle structurel OK, QA Ludovic pending |
| AP.1D — AI auto-draft no-reask API PROD | GO PARTIEL | API v3.5.143, anti-reask brouillon auto dans engine |
| AP.1F — AI stored drafts no-reask PROD | GO PROD | API v3.5.144, invalidation GET brouillons périmés |
| AP.2.3.1 — Author name QA DB | GO | 2 msgs QA Ludovic.G, 442 legacy inchangés |
| AP.2.5 — Lifecycle status PROD | GO PROD | API v3.5.146, resolved→escalation_status=none |
| AP.2.6 — Historical cleanup PROD | GO CLEANUP COMPLETE | 18 IDs resolved+escalated nettoyés |
| AP.2.8 — Auto-assignment PROD | GO PROD | API v3.5.147, assignation auto au répondant humain |
| AP.2.9 — Escalation notification audit | GO DESIGN READY | 5 chemins cartographiés, implémentation différée KEY-263 |
| AP.4 — Connectors regression audit | GO PARTIEL | Matrice complète Amazon/Email/Shopify/17TRACK/Octopia/Fnac/eBay |
| AP.4.1 — Website claims correction | GO PROD | Website v0.6.10, eBay retiré, badges honnêtes |
| AP.4.2A — Shopify disabled | GO PROD | Client v3.5.169, coming_soon + return safety |
| AP.4.2B — Shopify visible disabled fix | GO PROD | Client v3.5.170, Shopify dans "Bientôt disponible" modal |
| AP.4.3 — 17TRACK webhook secret | GO FULL POSTURE | Pas de secret séparé, API_KEY = signing key |

---

## 3. Synthèse AP.1 → AP.4.2B

### Bloc AP.1 — IA no-reask (3 couches)

Problème initial : l'IA redemandait au client son numéro de commande/suivi même quand disponible en contexte.

Corrections appliquées :
1. **Aide IA** (AP.1A/1B) : `orderRef` toujours injecté dans le contexte même sans `savStatus`, instruction anti-reask explicite
2. **Brouillon auto** (AP.1C/1D) : même correction dans `engine` + `shared-ai-context`
3. **Brouillons stockés** (AP.1E/1F) : invalidation à la lecture si patterns reask + order_ref connu (`REASK_PATTERNS`)

Images : API progressivement v3.5.143 → v3.5.144, Client v3.5.163

### Bloc AP.2 — Messaging lifecycle (5 corrections)

1. **Author name** (AP.2.2/2.3) : `author_name` réel (Prénom.N) stocké pour les nouveaux messages sortants
2. **Lifecycle status** (AP.2.4/2.5) : `resolved` clear `escalation_status` → `none`
3. **Historical cleanup** (AP.2.6) : 18 conversations `resolved+escalated` → `resolved+none`
4. **Auto-assignment** (AP.2.7/2.8) : assignation automatique au premier répondant humain si `assigned_agent_id` NULL
5. **Escalation notification** (AP.2.9) : audit complet, design ready, implémentation différée (KEY-263)

Images : API progressivement v3.5.145 → v3.5.146 → v3.5.147

### Bloc AP.4 — Connecteurs et claims (5 corrections)

1. **Website claims** (AP.4.1) : eBay retiré, Fnac/Shopify/WooCommerce badges honnêtes, Cdiscount "(Octopia)"
2. **Shopify disabled** (AP.4.2A) : `coming_soon: true`, return safety, onboarding grisé
3. **Shopify visible fix** (AP.4.2B) : injection dans `catalogFull` pour section "Bientôt disponible"
4. **17TRACK secret audit** (AP.4.3) : clarification que API_KEY = signing key, pas de webhook secret séparé
5. **Matrice connecteurs** (AP.4) : audit complet de tous les connecteurs

Images : Client v3.5.169 → v3.5.170, Website v0.6.10

---

## 4. Matrice des invariants non régressables

### IA / Messaging

| # | Invariant | Source | Risque si régression | Statut |
|---|---|---|---|---|
| IA-1 | Aide IA ne redemande pas commande/suivi si connu | AP.1A/1B | UX dégradée, perte trial | ✅ Verrouillé |
| IA-2 | Brouillon IA auto ne redemande pas commande/suivi | AP.1C/1D | Idem | ✅ Verrouillé |
| IA-3 | Brouillons stockés pré-fix invalidés si reask + order_ref | AP.1E/1F | Brouillons périmés servis | ✅ Verrouillé |
| IA-4 | Contexte order/tracking/17TRACK injecté serveur | AP.1, AMAZON_BASELINE | IA sans contexte | ✅ Verrouillé |
| IA-5 | IA seller-first / platform-aware | T8.12O.1, T8.12Q | Messages inappropriés | ✅ Verrouillé |
| IA-6 | Human validation (pas d'auto-send ajouté) | AP.1, TRIAL_WOW | Envois sans validation | ✅ Verrouillé |
| IA-7 | STARTER KBActions-gated (0 inclus) | AP.1 plan gates | Feature gratuite | ✅ Verrouillé |
| IA-8 | PRO/AUTOPILOT gates préservés | AP.1 | Accès hors plan | ✅ Verrouillé |
| MSG-1 | `author_name` humain réel (Prénom.N) nouveaux msgs | AP.2.2/2.3 | Signature "KeyBuzz Agent" | ✅ Verrouillé |
| MSG-2 | Legacy 442 `KeyBuzz Agent` non muté | AP.2.3.1 | Historique altéré | ✅ Verrouillé |
| MSG-3 | Auto-assignment après réponse humaine | AP.2.7/2.8 | Conversations orphelines | ✅ Verrouillé |
| MSG-4 | Résolution clear escalation_status | AP.2.4/2.5 | Incohérence états | ✅ Verrouillé |
| MSG-5 | 18 resolved+escalated nettoyés | AP.2.6 | Histo incohérent | ✅ Verrouillé |
| MSG-6 | Notification escalade absente = dette KEY-263 | AP.2.9 | Non bloquant Ads | ⚠️ Dette P2 |

### Connecteurs

| # | Invariant | Source | Risque si régression | Statut |
|---|---|---|---|---|
| CON-1 | Amazon FULL (OAuth + inbound + orders + messaging) | AO.5→AO.10.3 | Perte connecteur principal | ✅ Verrouillé |
| CON-2 | Email FULL | AP.4 | Perte canal email | ✅ Verrouillé |
| CON-3 | 17TRACK signature = SHA256(body+"/"+API_KEY) | AP.4.3 | Confusion sécurité | ✅ Verrouillé |
| CON-4 | 17TRACK PROD suspendu | AP.4.3 | Polling non souhaité | ✅ Verrouillé |
| CON-5 | Shopify visible disabled (coming_soon) | AP.4.2A/2B | OAuth sans app approval | ✅ Verrouillé |
| CON-6 | Octopia/Cdiscount partial | AP.4 | Marketing trompeur | ✅ Documenté |
| CON-7 | Fnac/Darty "Bientôt" | AP.4.1 | Marketing trompeur | ✅ Documenté |
| CON-8 | eBay absent, non claimé | AP.4.1 | Risque légal | ✅ Verrouillé |
| CON-9 | Website claims corrigés (v0.6.10) | AP.4.1 | Claims trompeurs si rebuild | ✅ Verrouillé |
| CON-10 | Sample Demo masquée dès canal réel | TRIAL_WOW | Pollution démo | ✅ Verrouillé |

### Tracking / Acquisition

| # | Invariant | Source | Risque si régression | Statut |
|---|---|---|---|---|
| TRK-1 | GA4 dans bundle PROD | AP.4.2B | Perte analytics | ✅ Verrouillé |
| TRK-2 | sGTM dans bundle PROD | AP.4.2B | Perte server-side | ✅ Verrouillé |
| TRK-3 | TikTok pixel dans bundle PROD | AP.4.2B | Perte attribution | ✅ Verrouillé |
| TRK-4 | LinkedIn dans bundle PROD | AP.4.2B | Perte attribution | ✅ Verrouillé |
| TRK-5 | Meta pixel dans bundle PROD | AP.4.2B | Perte attribution | ✅ Verrouillé |
| TRK-6 | Meta Purchase browser ABSENT | TRIAL_WOW | Double-fire | ✅ Verrouillé |
| TRK-7 | TikTok CompletePayment browser ABSENT | TRIAL_WOW | Double-fire | ✅ Verrouillé |
| TRK-8 | Pages protégées clean | TRIAL_WOW | PII leak | ✅ Verrouillé |
| TRK-9 | DEV leak = 0 dans bundle PROD | AP.4.2B | Requêtes DEV | ✅ Verrouillé |
| TRK-10 | Website promo forwarding | AP.4.1 | Perte attribution | ✅ Verrouillé |

### Billing / Promo

| # | Invariant | Source | Risque si régression | Statut |
|---|---|---|---|---|
| BIL-1 | Stripe source de vérité | TRIAL_WOW | Drift facturation | ✅ Verrouillé |
| BIL-2 | Codes promo plan-only | TRIAL_WOW | Coupons sur addons | ✅ Verrouillé |
| BIL-3 | KBActions/Agent exclus des coupons plan | TRIAL_WOW | Rabais non prévu | ✅ Verrouillé |
| BIL-4 | 0 fake checkout | Interdit absolu | Pollution Stripe | ✅ Verrouillé |

---

## 5. Dettes restantes

| Ticket | Sujet | Priorité | Bloquant Ads ? | Justification | Phase recommandée |
|---|---|---|---|---|---|
| KEY-273 | Shopify activation réelle | P2 | Non | Visible disabled suffit ; nécessite app review Shopify + secrets | Après app review |
| KEY-275 | 17TRACK raw body signature hardening | P3 | Non | API_KEY signing fonctionne, faux positifs possibles mais non bloquants | Phase sécurité |
| KEY-263 | Notification proactive escalade | P2 | Non | UI message_events + ai_action_log suffisent pré-Ads | Phase notifs |
| — | Agent KeyBuzz = label technique | P3 | Non | Pas de claim "équipe humaine" active | Décision produit |
| — | 442 legacy `KeyBuzz Agent` author_name | P4 | Non | Historique documenté, nouveaux msgs OK | Backfill optionnel |
| — | 193 conversations historiques non assignées | P4 | Non | Comportement futur OK (auto-assign) | Backfill optionnel |
| — | Procédure `kubectl set image` dans anciens rapports | P4 | Non | Dette documentaire vs GitOps strict | Harmonisation docs |
| — | `carrier-tracking-poll` PROD suspendu | P3 | Non | Fonctionnel DEV, PROD volontairement suspendu | Décision ops |
| — | Approbation TikTok API Events | P2 | Non (tracking browser OK) | Server-side complet après approbation | Phase tracking |
| — | Attribution LinkedIn server-side | P2 | Non (pixel browser OK) | CAPI implémentée, attribution en cours | Monitoring |

---

## 6. Linear

| Ticket | État avant AP.3 | Action | État après | Commentaire |
|---|---|---|---|---|
| KEY-253 | Open | Commenter "pre-Ads baseline locked" | Open | Fermeture décision produit |
| KEY-270 | Open | Commenter AP.3 closure + verdict GO | Done | AP.3 clôturé |
| KEY-271 | Open | Commenter "AP.4 P0/P1 mitigés, dettes non-bloquantes" | Done | Tous P0/P1 AP.4 résolus |
| KEY-272 | Done | Confirmer | Done | Website claims corrigés |
| KEY-273 | Open | Confirmer ouvert | Open | Shopify activation bloquée par app review |
| KEY-274 | Done | Confirmer | Done | 17TRACK secret posture clarifiée |
| KEY-275 | Open | Confirmer ouvert | Open | Raw body hardening P3 |
| KEY-276 | Done | Confirmer | Done | Shopify visible disabled |
| KEY-268 | Done | Confirmer | Done | Auto-assignment |
| KEY-266 | Done | Confirmer | Done | Author name |
| KEY-265 | Done | Confirmer | Done | Lifecycle status |
| KEY-263 | Open | Confirmer ouvert | Open | Notification escalade P2 |

---

## 7. Interdits respectés

| Interdit | Respecté |
|---|---|
| 0 build | ✅ |
| 0 deploy | ✅ |
| 0 `kubectl apply/set image/edit/patch/set env` | ✅ |
| 0 DB mutation | ✅ |
| 0 Stripe mutation | ✅ |
| 0 email envoyé | ✅ |
| 0 CAPI event | ✅ |
| 0 secret touché | ✅ |
| 0 `git reset --hard` / `git clean` | ✅ |
| 0 modification code source | ✅ |
| 0 manifest runtime modifié | ✅ |

---

## 8. Risques résiduels

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Rebuild depuis branche sans commits AP | Moyenne | Critique — régressions invisibles | Règle rebuild dans PRE_ADS_AP_BASELINE.md |
| Shopify OAuth lancé malgré disabled | Faible | Moyen — erreur auth | 3 couches protection (coming_soon + return + pas de setShowShopifyModal) |
| 17TRACK faux positif signature | Faible | Faible — non bloquant, warning log | Dette P3 KEY-275 |
| Notification escalade manquante | Certaine | Faible pré-Ads | UI audit trail suffisant |
| Build-args tracking oubliés | Moyenne | Critique — perte attribution | Checklist dans PRE_ADS_AP_BASELINE.md |

---

## 9. Go / No-Go Ads

### Critères pré-Ads vérifiés

| Critère | Vérifié |
|---|---|
| IA ne redemande pas info connue | ✅ |
| Messages lifecycle cohérent | ✅ |
| Amazon connector FULL | ✅ |
| Email connector FULL | ✅ |
| Website claims honnêtes | ✅ |
| Shopify non connectable mais visible | ✅ |
| Tracking complet dans bundle PROD | ✅ |
| Billing/promo préservés | ✅ |
| Baselines PROD vérifiées | ✅ |
| 0 P0 bloquant | ✅ |
| 0 P1 bloquant | ✅ |
| Dettes restantes documentées et non bloquantes | ✅ |

**Verdict : GO PRE-ADS BASELINE LOCKED**

---

## 10. Rollback documentaire

Pour retrouver les baselines précédentes en cas d'urgence :

| Service | Baseline actuelle | Rollback vers |
|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.146-lifecycle-status-clear-escalation-prod` |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | `v3.5.169-shopify-disabled-until-approval-prod` |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | Image pré-AP.4.1 à identifier dans git log |

Procédure : modifier manifest GitOps → commit → push → kubectl apply → rollout status.

---

## 11. Fichiers créés/modifiés cette phase

| Fichier | Action |
|---|---|
| `docs/AI_MEMORY/PRE_ADS_AP_BASELINE.md` | Créé — mémoire durable |
| `docs/PH-SAAS-T8.12AP.3-PRE-ADS-FEATURE-BASELINE-MEMORY-AND-LINEAR-CLOSURE-01.md` | Créé — rapport final |

---

## Verdict

**GO PRE-ADS BASELINE LOCKED**

PRE-ADS FEATURE BASELINE LOCKED — IA NO-REASK / MESSAGING LIFECYCLE / AMAZON CONNECTOR / EMAIL / 17TRACK / PROMO / WEBSITE CLAIMS / SHOPIFY DISABLED STATE DOCUMENTED — PROD BASELINES VERIFIED — LINEAR UPDATED — REMAINING DEBTS EXPLICIT AND NON-BLOCKING — NO CODE — NO BUILD — NO DEPLOY — NO MUTATION — READY FOR ADS FINAL CHECK
