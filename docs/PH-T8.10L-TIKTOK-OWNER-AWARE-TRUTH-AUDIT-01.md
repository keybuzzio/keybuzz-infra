# PH-T8.10L-TIKTOK-OWNER-AWARE-TRUTH-AUDIT-01 — TERMINÉ

**Verdict : PARTIEL — CAPTURE + LECTURE OWNER PRÊTS, BOUCLE RETOUR SERVER-SIDE NON NATIVE**

| Champ | Valeur |
|---|---|
| Phase | PH-T8.10L |
| Environnement | DEV + PROD (lecture) |
| Date | 2026-04-25 |
| Type | Audit vérité TikTok owner-aware |
| Priorité | P0 |
| Owner DEV | `keybuzz-consulting-mo9y479d` |
| Owner PROD | `keybuzz-consulting-mo9zndlk` |

---

## 1. Préflight

| Point | Résultat |
|---|---|
| API branche | `ph147.4/source-of-truth` — HEAD `ac29fd55` — clean |
| Client branche | `ph148/onboarding-activation-replay` — HEAD `6d5a796` — clean |
| Admin branche | `main` — HEAD `dad2fa5` — clean |
| API PROD | `v3.5.116-marketing-owner-stack-prod` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` |

---

## 2. Audit client TikTok

| Sujet | Emplacement | État actuel |
|---|---|---|
| `ttclid` capturé depuis URL | `src/lib/attribution.ts:123` — `get('ttclid')` | **OK** |
| `ttclid` dans `AttributionContext` | `src/lib/attribution.ts:31,300` | **OK** |
| `ttclid` dans `CLICK_ID_PARAMS` | `src/lib/attribution.ts:61` | **OK** — traité au même niveau que `gclid` et `fbclid` |
| `marketing_owner_tenant_id` + `ttclid` coexistence | `src/lib/attribution.ts:123-128` — même objet | **OK** |
| TikTok Pixel (code source) | `src/components/tracking/SaaSAnalytics.tsx:115-134` | **Présent** dans le code |
| TikTok Pixel (runtime PROD) | `NEXT_PUBLIC_TIKTOK_PIXEL_ID` non fourni au build | **INACTIF** — variable vide, conditionnel `TIKTOK_PIXEL_ID && (...)` |
| Events browser TikTok | `src/lib/tracking.ts:64-68,77,110,136` | **3 events** : `SubmitForm` (signup), `InitiateCheckout` (checkout), `CompletePayment` (purchase) — tous inactifs sans Pixel ID |
| Dockerfile ARG | `Dockerfile:16,26` — `ARG NEXT_PUBLIC_TIKTOK_PIXEL_ID=` | **Prêt** — suffit de fournir la valeur au build |
| `ttclid` transmis au create-signup | Via `attribution` object dans body | **OK** |

### Résumé client
La capture `ttclid` est **complètement fonctionnelle** et coexiste avec `marketing_owner_tenant_id`. Le TikTok Pixel est codé mais inactif en PROD faute de Pixel ID au build.

---

## 3. Audit API TikTok

| Sujet | Source | État actuel |
|---|---|---|
| `ttclid` persisté dans `signup_attribution` | `tenant-context-routes.ts:713,732` | **OK** — colonne et INSERT |
| `ttclid` lu dans l'emitter conversion | `emitter.ts:319,335` | **OK** — inclus dans le payload |
| `tiktok_events` dans `DESTINATION_TYPES` | `routes.ts:12` | **OK** — type valide enregistré |
| Handler TikTok Events API natif | `emitter.ts` | **ABSENT** — pas de `sendToTikTokDest`, aucun handler dédié |
| Fallback delivery TikTok | `emitter.ts:389-392` | **Webhook générique** — `sendToWebhookDestination` |
| Owner-aware routing pour TikTok | `emitter.ts` — `resolveOutboundRoutingTenantId` | **OK** — agnostique du type de destination |
| Destination `tiktok_events` KBC (PROD) | DB query | **0 rows** — aucune destination configurée |
| Destination `tiktok_events` KBC (DEV) | DB query | **0 rows** — aucune destination configurée |
| Payload conversion inclut `ttclid` | `emitter.ts:335` — `attribution.ttclid` | **OK** |
| Payload inclut `email_hash` (SHA-256) | `emitter.ts:340-342` | **OK** — important pour TikTok matching |

### Résumé API

Le pipeline outbound conversion :
1. Lit `ttclid` depuis `signup_attribution` — **OK**
2. L'inclut dans le payload envoyé aux destinations — **OK**
3. Route vers l'owner via `resolveOutboundRoutingTenantId` — **OK**
4. Cherche des destinations pour le owner — **OK**
5. Si type = `meta_capi` → handler Meta natif (`sendToMetaCapiDest`) — **OK**
6. Si type = `tiktok_events` → **FALLBACK webhook générique** — pas de formatting TikTok Events API natif

Le contrat TikTok Events API (`POST https://business-api.tiktok.com/open_api/v1.3/event/track/`) attend un format spécifique avec `pixel_code`, `event`, `properties.contents`, `context.ad.callback` (= ttclid). Le webhook générique envoie le payload KeyBuzz brut, pas le format TikTok.

---

## 4. Audit Admin

| Surface Admin | TikTok utile aujourd'hui ? | Gap |
|---|---|---|
| **Destinations** (create/edit) | **NON** | Type selector UI : `'webhook' \| 'meta_capi'` uniquement. `tiktok_events` absent du type union. Pas d'icône TikTok. Pas de formulaire dédié (pixel_code, access_token). |
| **Delivery logs** | Partiellement générique | Afficherait les logs si une destination existait, mais pas de filtre/icône TikTok spécifique. |
| **Ad accounts** | **NON** | Uniquement Meta Ads implémenté. Pas de sync TikTok Ads (spend/campagnes). |
| **Metrics** | **OUI** | KPI owner-scoped fonctionnent indépendamment de la plateforme. CAC/ROAS calculables manuellement. |
| **Funnel** | **OUI** | Funnel owner-scoped fonctionne. Les events funnel sont internes KeyBuzz, pas liés à une plateforme. |
| **Integration guide** | Doc existante | TikTok marqué "Bientôt" + "Via webhook → agence mappe vers TikTok Events API". |

### Résumé Admin
L'Admin cockpit owner est **utile pour piloter** (metrics, funnel, delivery logs génériques). Mais il ne permet pas de **configurer** une destination TikTok native ni de **synchroniser** le spend TikTok automatiquement.

---

## 5. Vérité end-to-end

| Question | Réponse | Preuve |
|---|---|---|
| **Un clic TikTok avec `ttclid` + owner mapping peut-il être capturé sous KBC ?** | **OUI** | `ttclid` dans `attribution.ts:123`, `marketing_owner_tenant_id` dans `attribution.ts:128`, tous deux persistés dans `signup_attribution` |
| **Le lead/tenant enfant remonte-t-il dans le cockpit owner KBC ?** | **OUI** | Prouvé en PH-T8.10J.1 — `owner_cohort.children`, funnel stitching, metrics owner-scoped |
| **Une conversion business peut-elle être renvoyée à TikTok ?** | **PARTIELLEMENT** — via webhook intermédiaire uniquement | `ttclid` est dans le payload webhook (`emitter.ts:335`). Pas de handler TikTok Events API natif. L'agence doit mapper le webhook vers TikTok Events API via un outil intermédiaire (Make, Zapier, custom). |
| **L'agence peut-elle se contenter de TikTok Ads + bonnes URLs ?** | **OUI pour capture + lecture.** **NON pour retour server-side natif.** | La boucle capture → cockpit est prouvée. Le retour conversion → TikTok nécessite un webhook intermédiaire. L'agence doit ajouter cette brique elle-même ou attendre le handler natif. |

### Schéma du flux actuel

```
TikTok Ad Click ──→ Landing Page (?ttclid=xxx&marketing_owner_tenant_id=KBC)
                         │
                    ┌────▼────┐
                    │ Client  │ capture ttclid + owner_tenant_id
                    │ /register│ dans AttributionContext
                    └────┬────┘
                         │ POST /create-signup
                    ┌────▼────┐
                    │   API   │ signup_attribution: ttclid + marketing_owner_tenant_id
                    │         │ tenants: marketing_owner_tenant_id
                    └────┬────┘
                         │
              ┌──────────▼──────────┐
              │ Owner cockpit (Admin)│ ← scope=owner → KBC voit le lead
              └──────────┬──────────┘
                         │ Stripe webhook → StartTrial / Purchase
                    ┌────▼────┐
                    │ Emitter │ resolveOutboundRoutingTenantId → KBC
                    │         │ payload contient attribution.ttclid
                    └────┬────┘
                         │
               ┌─────────▼──────────┐
               │ Destination lookup  │ → destinations KBC
               └─────────┬──────────┘
                         │
          ┌──────────────▼──────────────┐
          │ Meta CAPI → handler natif ✅ │
          │ TikTok   → ??? ❌           │
          │ Webhook  → brut ✅ (agence   │
          │            mappe elle-même)  │
          └──────────────────────────────┘
```

---

## 6. Diagnostic final

### Verdict : Cas B — TikTok presque prêt

**Ce qui fonctionne (5/7 briques) :**

| # | Brique | Status |
|---|---|---|
| 1 | `ttclid` capture depuis URL | **OK** |
| 2 | `ttclid` persisté dans `signup_attribution` | **OK** |
| 3 | `marketing_owner_tenant_id` + `ttclid` coexistence | **OK** |
| 4 | Tenant enfant visible dans cockpit owner | **OK** |
| 5 | Payload conversion inclut `ttclid` | **OK** |

**Ce qui manque (2/7 briques) :**

| # | Brique | Status | Impact |
|---|---|---|---|
| 6 | Handler TikTok Events API natif | **ABSENT** | Pas de retour direct KeyBuzz → TikTok. Workaround = webhook intermédiaire. |
| 7 | Destination `tiktok_events` configurable dans Admin | **ABSENT** | L'Admin UI ne propose pas le type `tiktok_events`. L'API l'accepte mais l'Admin ne permet pas de le créer. |

**Workaround immédiat (0 code)** :
1. Créer une destination `webhook` sous KBC (via API ou Admin)
2. Pointer vers un Make/Zapier/custom qui reformate le payload vers TikTok Events API
3. Le `ttclid` est déjà dans `attribution.ttclid` du payload
4. L'`email_hash` SHA-256 est déjà dans `customer.email_hash`

**Bonus manquant (non bloquant)** :
- TikTok Pixel ID non fourni au build PROD → events browser inactifs
- TikTok Ads spend sync absent dans l'Admin

---

## 7. Plus petit chantier suivant

| Option | Impact | Taille | Verdict |
|---|---|---|---|
| **C. Doc opérationnelle webhook→TikTok agence** | Débloque l'agence immédiatement, 0 code | Très petit | **PLUS PETIT CHANTIER — recommandé** |
| **D. TikTok Pixel ID build-arg PROD** | Active events browser TikTok | Petit (1 rebuild client) | Second plus petit |
| **B. Admin UI `tiktok_events` type selector** | Permet la config via Admin | Petit (UI only) | Utile si handler natif prévu |
| **A. Handler TikTok Events API natif** | Boucle fermée complète comme Meta CAPI | Moyen (handler + token + mapping) | Objectif idéal |

### Recommandation

1. **Immédiat (0 code)** : documenter le workaround webhook → TikTok Events API pour l'agence, avec le mapping des champs KeyBuzz → TikTok
2. **Court terme** : activer le TikTok Pixel ID dans le build PROD client
3. **Moyen terme** : handler natif `sendToTikTokDest` dans l'emitter + Admin UI type selector

---

## 8. Aucune modification effectuée

- Aucun patch
- Aucun build
- Aucun deploy
- PROD inchangée
- DEV inchangée
- Aucune donnée modifiée

---

## 9. Conclusion

**TIKTOK OWNER-AWARE TRUTH ESTABLISHED — CAPTURE + OWNER-SCOPED READ READY — SERVER-SIDE RETURN REQUIRES WEBHOOK INTERMEDIARY OR NATIVE HANDLER — MINIMAL NEXT STEP = AGENCY WEBHOOK DOC — PROD UNCHANGED**

La boucle TikTok est **fonctionnelle à 70%** :
- Le lead TikTok est capturé avec `ttclid` et `marketing_owner_tenant_id`
- Le tenant enfant remonte dans le cockpit owner KBC
- Le payload conversion inclut `ttclid` et `email_hash`
- Le routing owner-aware fonctionne pour toutes les destinations

Le gap restant est le **retour server-side natif vers TikTok Events API** :
- Pas de handler dédié `sendToTikTokDest`
- L'Admin ne permet pas de configurer une destination `tiktok_events`
- L'agence peut contourner avec un webhook + Make/Zapier

---

**Rapport** : `keybuzz-infra/docs/PH-T8.10L-TIKTOK-OWNER-AWARE-TRUTH-AUDIT-01.md`
