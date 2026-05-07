# PRE-ADS AP BASELINE — Mémoire Durable

> Créé : 8 mai 2026
> Phase : PH-SAAS-T8.12AP.3
> Statut : **LOCKED**
> Objectif : empêcher toute régression des corrections AP avant lancement Ads

---

## 1. BASELINES PROD VERROUILLÉES (8 mai 2026)

| Service | Image PROD | Digest connu |
|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | — |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | `sha256:dc0140f5c831...` |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | — |
| Website | `v0.6.10-connector-claims-truth-prod` | — |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | — |
| Admin | `v2.12.1-promo-codes-foundation-prod` | — |

### Branches source (lecture seule pour référence)

| Repo | Branche source PROD |
|---|---|
| keybuzz-api | `ph147.4/source-of-truth` |
| keybuzz-client | `ph148/onboarding-activation-replay` |
| keybuzz-website | `main` |

### Règle absolue

**Tout futur build DOIT être fait depuis la branche source documentée ci-dessus ou une branche qui en hérite. Un build depuis une branche vide, un main non mergé, ou un checkout destructif ANNULE les corrections AP et crée des régressions invisibles.**

---

## 2. INVARIANTS IA / MESSAGING — NON RÉGRESSABLES

| # | Invariant | Source/Rapport | Risque si régression |
|---|---|---|---|
| IA-1 | Aide IA ne redemande pas commande/suivi si `orderRef` connu | AP.1A, AP.1B (KEY-256) | Expérience client dégradée, perte confiance trial |
| IA-2 | Brouillon IA auto ne redemande pas commande/suivi | AP.1C, AP.1D (KEY-256) | Idem IA-1 |
| IA-3 | Brouillons stockés pré-fix invalidés si patterns reask + order_ref | AP.1E, AP.1F (KEY-256) | Anciens brouillons périmés servis |
| IA-4 | Contexte order/tracking/17TRACK injecté côté serveur | AP.1, AMAZON_SPAPI_BASELINE | IA sans contexte → reask |
| IA-5 | IA seller-first / platform-aware préservée | T8.12O.1, T8.12Q | Messages inappropriés à la marketplace |
| IA-6 | Human validation préservée (pas d'auto-send ajouté) | AP.1, TRIAL_WOW_BASELINE | Messages envoyés sans validation humaine |
| IA-7 | STARTER reste KBActions-gated (0 inclus) | AP.1 audit plan gates | Feature gratuite non prévue |
| IA-8 | PRO/AUTOPILOT_ASSISTED/AUTOPILOT gates préservés | AP.1 | Accès IA hors plan |
| MSG-1 | `author_name` humain réel (Prénom.N) pour nouveaux messages | AP.2.2, AP.2.3, AP.2.3.1 (KEY-266) | Messages signés "KeyBuzz Agent" |
| MSG-2 | Legacy `KeyBuzz Agent` (442 msgs) documenté, non muté | AP.2.3.1 | Historique altéré |
| MSG-3 | Auto-assignment après réponse humaine actif | AP.2.7, AP.2.8 (KEY-268) | Conversations sans assigné |
| MSG-4 | Résolution future clear `escalation_status` → none | AP.2.4, AP.2.5 (KEY-265) | resolved+escalated incohérent |
| MSG-5 | resolved+escalated historique nettoyé (18 IDs) | AP.2.6 | Données historiques incohérentes |
| MSG-6 | Notification proactive escalade ABSENTE = dette volontaire KEY-263 | AP.2.9 | Non bloquant pré-Ads |

---

## 3. INVARIANTS CONNECTEURS

| # | Invariant | Source/Rapport | Risque si régression |
|---|---|---|---|
| CON-1 | Amazon FULL : OAuth, inbound email, Seller Central guide, orders, messaging | AO.5→AO.10.3, AMAZON_SPAPI_BASELINE | Perte connecteur principal |
| CON-2 | Email FULL | AP.4 matrice | Perte canal email |
| CON-3 | 17TRACK : signature = SHA256(body + "/" + API_KEY), pas de webhook secret séparé | AP.4.3 (KEY-274) | Confusion sur la sécurité webhook |
| CON-4 | 17TRACK carrier-tracking-poll PROD suspendu (`suspend: true`) | AP.4.3 | Polling non souhaité |
| CON-5 | Shopify visible mais désactivé (coming_soon + return safety) | AP.4.2A, AP.4.2B (KEY-276) | OAuth lancé sans app approval |
| CON-6 | Octopia/Cdiscount partial, pas de claim "FULL" | AP.4 matrice | Marketing trompeur |
| CON-7 | Fnac/Darty "Bientôt" | AP.4.1 | Marketing trompeur |
| CON-8 | eBay absent, non claimé comme disponible | AP.4.1 (KEY-272) | Risque légal/marketing |
| CON-9 | Website claims corrigés (v0.6.10) | AP.4.1 | Claims trompeurs si rebuild |
| CON-10 | Sample Demo masquée dès canal réel connecté | TRIAL_WOW_BASELINE | Données démo polluantes |

---

## 4. INVARIANTS TRACKING / ACQUISITION

| # | Invariant | Source/Rapport | Risque si régression |
|---|---|---|---|
| TRK-1 | GA4 (`G-R3QQDYEBFG`) dans bundle PROD | AP.4.2B tracking check | Perte analytics |
| TRK-2 | sGTM (`t.keybuzz.pro`) dans bundle PROD | AP.4.2B | Perte server-side tracking |
| TRK-3 | TikTok pixel (`D7PT12JC77U44OJIPC10`) dans bundle PROD | AP.4.2B | Perte attribution TikTok |
| TRK-4 | LinkedIn (`9969977`) dans bundle PROD | AP.4.2B | Perte attribution LinkedIn |
| TRK-5 | Meta pixel (`1234164602194748`) dans bundle PROD | AP.4.2B | Perte attribution Meta |
| TRK-6 | Meta Purchase browser ABSENT | TRIAL_WOW_BASELINE | Double-fire events |
| TRK-7 | TikTok CompletePayment browser ABSENT | TRIAL_WOW_BASELINE | Double-fire events |
| TRK-8 | Pages protégées clean (pas de tracking sur auth/login) | TRIAL_WOW_BASELINE | PII dans analytics |
| TRK-9 | DEV leak (`api-dev.keybuzz.io`) = 0 dans bundle PROD | AP.4.2B | Requêtes DEV depuis PROD |
| TRK-10 | Website promo forwarding préservé | AP.4.1 | Perte attribution promo |

---

## 5. INVARIANTS BILLING / PROMO

| # | Invariant | Source/Rapport | Risque si régression |
|---|---|---|---|
| BIL-1 | Stripe source de vérité | TRIAL_WOW_BASELINE | Drift facturation |
| BIL-2 | Codes promo plan-only | TRIAL_WOW_BASELINE | Coupons appliqués sur addons |
| BIL-3 | KBActions / Agent / addons exclus des coupons plan | TRIAL_WOW_BASELINE | Rabais non prévu |
| BIL-4 | Aucun fake checkout | Interdit absolu | Pollution Stripe |

---

## 6. DETTES RESTANTES (NON BLOQUANTES ADS)

| Ticket | Sujet | Priorité | Bloquant Ads ? |
|---|---|---|---|
| KEY-273 | Shopify activation réelle (app review + secrets + OAuth) | P2 | Non — visible disabled suffit |
| KEY-275 | 17TRACK raw body signature verification hardening | P3 | Non — API_KEY signing fonctionne |
| KEY-263 | Notification proactive escalade / NotificationBell | P2 | Non — UI message_events suffit pré-Ads |
| — | Agent KeyBuzz workflow humain réel | P3 | Non — label documenté |
| — | 442 legacy `KeyBuzz Agent` author_name | P4 | Non — histo non muté |
| — | 193 conversations historiques non assignées | P4 | Non — comportement futur OK |
| — | Procédure `kubectl set image` dans anciens rapports vs GitOps strict | P4 | Non — dette documentaire |

---

## 7. RÈGLE REBUILD

Avant tout futur build Client/API/Website, vérifier que :

1. La branche source contient TOUS les commits AP (no-reask, lifecycle, author_name, auto-assign, Shopify disabled, website claims)
2. Les build-args tracking sont injectés (GA4, sGTM, TikTok, LinkedIn, Meta)
3. `NEXT_PUBLIC_API_URL` et `NEXT_PUBLIC_API_BASE_URL` correspondent à l'environnement
4. Le bundle résultant passe les vérifications tracking (cf. AP.4.2B checklist)
5. Aucun `api-dev.keybuzz.io` dans le bundle PROD

**Si un build ne peut pas prouver le respect de ces invariants, il ne doit PAS être déployé.**
