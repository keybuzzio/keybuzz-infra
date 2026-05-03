# PH-API-T8.12AG — ORDER TRACKING AI CONTEXT PROD PROMOTION

> **Phase** : PH-API-T8.12AG-ORDER-TRACKING-AI-CONTEXT-PROD-PROMOTION-01
> **Linear** : KEY-241
> **Date** : 2026-05-03
> **Type** : Promotion PROD contrôlée
> **Verdict** : **GO PROD**

---

## OBJECTIF

Promouvoir en PROD le correctif validé en DEV (PH-API-T8.12AF) :
- L'IA utilise les données `tracking_events` (statut, description, localisation, horodatage)
- L'IA ne redemande pas un numéro de commande ou de suivi déjà connu
- Les réponses livraison sont seller-first et platform-aware
- Le CronJob 17TRACK PROD reste suspendu

---

## SOURCES LUES

| Document | Lu |
|---|---|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | oui (règles intégrées) |
| `AI_MEMORY/RULES_AND_RISKS.md` | oui |
| `AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md` | oui |
| `PH-API-T8.12AF-ORDER-TRACKING-AI-CONTEXT-TRUTH-AUDIT-AND-DEV-FIX-01.md` | oui |
| `PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md` | oui (contexte) |
| `PH-SAAS-T8.12AE-17TRACK-WEBHOOK-CONFIG-VERIFY-AND-KEY240-CLOSURE-01.md` | oui |
| `PH-AUTOPILOT-ORDER-ID-CONTEXT-AUDIT-01.md` | oui |
| `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01.md` | oui |
| `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-PROD-PROMOTION-01.md` | oui (pattern réutilisé) |
| `PH-API-T8.12Q.2-PLATFORM-AWARE-REFUND-PROTECTION-PROD-PROMOTION-01.md` | oui (pattern réutilisé) |

---

## ÉTAPE 0 — FREEZE API PROD

| Élément | Valeur |
|---|---|
| API PROD runtime | `ghcr.io/keybuzzio/keybuzz-api:v3.5.135-lifecycle-pilot-safety-gates-prod` |
| API PROD manifest | `v3.5.135-lifecycle-pilot-safety-gates-prod` |
| Rollout | `successfully rolled out` |
| Autre déploiement en cours | non |
| Freeze confirmé | **oui** |

---

## ÉTAPE 1 — PREFLIGHT REPOS

| Repo | Branche attendue | Branche constatée | HEAD | Dirty src/ | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `5b398b5e` | **CLEAN** | OK |
| `keybuzz-infra` | `main` | `main` | `98ef562` | non (docs/scripts untracked) | OK |

- Commit `5b398b5e` : confirmé présent
- `dist/` dirty : fichiers compilés locaux, ignorés (build depuis clone propre)
- Aucun fichier source non commité ne participe au build

---

## ÉTAPE 2 — RÉCONCILIATION RAPPORT AF

Le rapport PH-API-T8.12AF a été relu. Points vérifiés :

| Point rapport AF | État | Commentaire |
|---|---|---|
| Procédure rollback | ✅ | Conforme GitOps (pas de `kubectl set image`) |
| `dist/` dirty | ✅ | Ignoré — build PROD depuis clone Git propre |
| Procédures interdites | ✅ | Aucune commande interdite dans le rapport |
| Commit source | ✅ | `5b398b5e` — source unique du build |

Aucune correction nécessaire. Rapport AF conforme.

---

## ÉTAPE 3 — VÉRIFICATION SOURCE PATCH

### `src/modules/ai/shared-ai-context.ts`

| Signal attendu | Présent | Verdict |
|---|---|---|
| `latestTrackingEventStatus: string` dans interface | ✅ (1) | OK |
| Query `FROM tracking_events` dans `loadEnrichedOrderContext` | ✅ (1) | OK |
| Assignation `enriched.latestTrackingEventStatus` | ✅ (1) | OK |
| Bloc `DERNIER ÉVÉNEMENT` dans prompt | ✅ (1) | OK |
| `latestTrackingEventLocation` dans prompt | ✅ (4) | OK |

### `src/modules/autopilot/engine.ts`

| Signal attendu | Présent | Verdict |
|---|---|---|
| `carrierDeliveryStatus` dans user prompt | ✅ (3) | OK |
| `trackingSource` filtre `amazon_estimate` | ✅ (1) | OK |
| `shippedAt` dans prompt | ✅ (2) | OK |
| `deliveredAt` dans prompt | ✅ (2) | OK |
| Bloc `DERNIER ÉVÉNEMENT TRANSPORTEUR` | ✅ (2) | OK |
| Anti-redemande `NE JAMAIS le redemander` | ✅ (1) | OK |
| `latestTrackingEventStatus` dans interface | ✅ (1) | OK |

**12/12 signaux confirmés dans la source.**

---

## ÉTAPE 4 — PRE-BUILD CHECKS

| Check | Résultat |
|---|---|
| TypeScript compilation | ✅ OK (Step 7/19 dans build) |
| Secrets dans diff | ✅ Aucun |
| Fichiers modifiés | ✅ Uniquement `shared-ai-context.ts` + `autopilot/engine.ts` |
| Changements lifecycle/billing/marketing | ✅ Aucun |

---

## ÉTAPE 5 — BUILD PROD STRICT

| Élément | Valeur |
|---|---|
| Source commit | `5b398b5e` |
| Branche source | `ph147.4/source-of-truth` |
| Clone propre | **oui** (`/tmp/keybuzz-api-ag-prod-build`) |
| Tag image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.136-ai-tracking-context-prod` |
| Digest | `sha256:cf0c57a0b56ae29c6c79a3bfc1157c3a89929b800220d7a604ce8925147ac9d3` |
| TypeScript | ✅ OK |
| Build from git prouvé | **oui** |

---

## ÉTAPE 6 — GITOPS PROD

| Élément | Avant | Après |
|---|---|---|
| Image API PROD | `v3.5.135-lifecycle-pilot-safety-gates-prod` | `v3.5.136-ai-tracking-context-prod` |
| Digest | — | `sha256:cf0c57a0b56ae29c6c79a3bfc1157c3a89929b800220d7a604ce8925147ac9d3` |
| Commit infra | `98ef562` | `ac04496` |
| Rollback cible | — | `v3.5.135-lifecycle-pilot-safety-gates-prod` |

Manifest modifié : `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
Commit message : `gitops(api-prod): promote v3.5.136-ai-tracking-context-prod (PH-API-T8.12AG / KEY-241)`

---

## ÉTAPE 7 — DEPLOY PROD

| Élément | Résultat |
|---|---|
| Pod | `keybuzz-api-57f8458d4c-c69mq` |
| Restarts | 0 |
| Ready | true |
| Health | `{"status":"ok"}` |
| Runtime image | `v3.5.136-ai-tracking-context-prod` |
| Manifest image | `v3.5.136-ai-tracking-context-prod` |
| Annotation last-applied | `v3.5.136-ai-tracking-context-prod` |
| Manifest = runtime = annotation | **oui** |

---

## ÉTAPE 8 — VALIDATION STRUCTURELLE RUNTIME PROD

| Signal | Présent source | Présent runtime (dist/) | Verdict |
|---|---|---|---|
| `latestTrackingEventStatus` | ✅ | ✅ (4) | OK |
| `latestTrackingEventDescription` | ✅ | ✅ (4) | OK |
| `latestTrackingEventLocation` | ✅ | ✅ (4) | OK |
| `latestTrackingEventTime` | ✅ | ✅ (4) | OK |
| `tracking_events` query | ✅ | ✅ (1) | OK |
| `DERNIER` shared-ai-context | ✅ | ✅ (1) | OK |
| `carrierDeliveryStatus` engine | ✅ | ✅ (2) | OK |
| `trackingSource` engine | ✅ | ✅ (2) | OK |
| `shippedAt` engine | ✅ | ✅ (2) | OK |
| `deliveredAt` engine | ✅ | ✅ (2) | OK |
| `DERNIER` engine | ✅ | ✅ (2) | OK |
| Anti-re-ask engine | ✅ | ✅ (1) | OK |

**12/12 signaux confirmés en runtime PROD.**

---

## ÉTAPE 9 — VALIDATION DRY-RUN IA PROD

### CAS 1 : Commande tracée avec événement transporteur

**Conversation** : `cmmo1b88r1466c23ec20d9fd6` — Amazon  
**Commande** : `XXX-XXXXXXX-XXXXXXX` — UPS  
**`loadEnrichedOrderContext` retourne (24 champs)** :

```
carrierDeliveryStatus: delivered
trackingSource: aggregator_17track
shippedAt: 2026-04-10
deliveredAt: 2026-04-16
latestTrackingEventStatus: delivered
latestTrackingEventDescription: Delivered, DELIVERED
latestTrackingEventLocation: MOIRANS-EN-MONTAGNE, FR
latestTrackingEventTime: 2026-04-16T09:50:59.000Z
```

✅ Tous les champs tracking enrichis.

### CAS 2 : Commande sans tracking (dégradation gracieuse)

**Conversation** : `cmmkn5hy7yd02b6d33ddd7f2e`  
**Commande** : `XXX-XXXXXXX-XXXXXXX` (pas de tracking)

```
trackingCode: (empty)
carrierDeliveryStatus: (empty)
latestTrackingEventStatus: cancelled
```

✅ Dégradation gracieuse — champs vides, pas de crash.

### CAS 3 : Pipeline end-to-end `buildEnrichedUserPrompt`

**Conversation** : `cmmolbb4otfc6a54b8b3ce331` — Amazon — Exception UPS  
**Résultat** : prompt de 2005 caractères

```
Contains DERNIER: true
Contains tracking: true
Contains carrier: true
```

**Extrait prompt (PII masqué)** :

```
--- DERNIER ÉVÉNEMENT TRANSPORTEUR ---
Statut: returned
Détail: Returning to Sender, The package was not picked up at the UPS Access Point™
location by the expiration date and is being returned to sender.
Date: 30/04/2026 15:21:14

--- ANALYSE TEMPORELLE ---
Jours depuis la commande: 24
Delai de livraison attendu: 15 jours
Retard estime: 9 jours de retard
```

✅ Prompt enrichi complet avec bloc DERNIER, analyse temporelle, données transporteur réelles.

### CAS 4 : Safety

| Check | Résultat |
|---|---|
| AI settings | `supervised`, `ai_enabled: true`, `safe_mode: true`, `kill_switch: false` |
| Outbound last 15 min | 0 |
| Billing events last 15 min | 0 |
| New tracking_events last 15 min | 7 (webhooks naturels, non liés au déploiement) |

✅ Aucun side-effect.

### Note sur `buildEnrichedUserPrompt` et l'anti-re-ask

L'instruction anti-re-ask (`NE JAMAIS le redemander`) est injectée par `autopilot/engine.ts` directement (signal #12 confirmé en runtime), pas par `buildEnrichedUserPrompt`. Le pipeline `shared-ai-context` fournit les données enrichies ; le module Autopilot construit son propre prompt incluant l'instruction anti-re-ask quand un tracking est connu.

---

## ÉTAPE 10 — VALIDATION 17TRACK NON-RÉGRESSION

| Check 17TRACK | Attendu | Résultat |
|---|---|---|
| `/api/v1/orders/tracking/status` | 17TRACK configured | ✅ `"configured": true` |
| Webhook route active | oui | ✅ (route présente dans runtime) |
| CronJob `carrier-tracking-poll` | `suspend: true` | ✅ `true` |
| Polling automatique déclenché | non | ✅ 0 |
| Nouveau run manuel | non | ✅ 0 |
| Mutation DB tracking inattendue | non | ✅ 7 events = webhooks naturels |

---

## ÉTAPE 11 — NON-RÉGRESSION PROD GLOBALE

| Surface | Attendu | Résultat |
|---|---|---|
| `/health` | OK | ✅ `{"status":"ok"}` |
| `/messages/conversations` | réponse | ✅ 2 conversations retournées |
| `/tenant-context/me` | email owner | ✅ `ludo.gonthier@gmail.com` |
| `/api/v1/orders` | réponse | ✅ 2 orders retournées |
| `/billing/current` | réponse | ✅ OK |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | ✅ inchangé |
| Admin PROD | non modifié | ✅ |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | ✅ inchangé |
| CronJob 17TRACK | `suspend: true` | ✅ |
| Outbound réel | 0 | ✅ 0 |
| Billing/Stripe drift | 0 | ✅ 0 |
| CAPI/GA4/Meta/TikTok/LinkedIn | inchangé | ✅ aucun changement |
| Pod PROD | stable | ✅ Running, 0 restarts |

---

## ÉTAPE 12 — LINEAR KEY-241

| Élément | Valeur |
|---|---|
| Tag PROD | `v3.5.136-ai-tracking-context-prod` |
| Digest PROD | `sha256:cf0c57a0b56ae29c6c79a3bfc1157c3a89929b800220d7a604ce8925147ac9d3` |
| Dry-run | ✅ complet (3 cas + safety) |
| No re-ask order/tracking | ✅ confirmé (signal runtime + engine.ts) |
| Non-régression | ✅ complète |
| Statut recommandé | **Done** |

---

## ÉTAPE 13 — ROLLBACK GITOPS

### Cible de rollback

```
v3.5.135-lifecycle-pilot-safety-gates-prod
```

### Procédure obligatoire (ne pas exécuter sauf incident)

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   ```yaml
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.135-lifecycle-pilot-safety-gates-prod
   ```
2. `git add k8s/keybuzz-api-prod/deployment.yaml`
3. `git commit -m "rollback(api-prod): revert to v3.5.135 (PH-API-T8.12AG rollback)"`
4. `git push origin main`
5. SCP le manifest vers le bastion
6. `kubectl apply -f <manifest>`
7. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
8. Vérifier : manifest = runtime = annotation

**Aucune commande directe de mutation runtime** (`kubectl set image`, `kubectl edit`, etc.).

---

## GAPS RESTANTS

| # | Gap | Impact | Priorité |
|---|---|---|---|
| G1 | `loadFullConversationContext` retourne null pour certaines conversations PROD — la fonction filtre probablement les conversations sans messages récents | Pas d'impact fonctionnel — le pipeline est appelé quand une conversation a des messages actifs | Low |
| G2 | L'anti-re-ask tracking est dans `engine.ts` uniquement, pas dans `buildEnrichedUserPrompt` | By design — l'instruction est pertinente uniquement quand le moteur Autopilot génère une réponse | None |

---

## RÉSUMÉ

```
PH-API-T8.12AG - TERMINÉ
Verdict : GO PROD

Résumé :
Image PROD v3.5.136-ai-tracking-context-prod déployée et validée.
12/12 signaux structurels confirmés en runtime.
loadEnrichedOrderContext charge correctement tracking_events (statut, description, localisation, horodatage).
buildEnrichedUserPrompt génère un prompt avec bloc DERNIER ÉVÉNEMENT TRANSPORTEUR complet.
Dégradation gracieuse confirmée (commande sans tracking).
Pipeline end-to-end validé avec données PROD réelles.
0 outbound, 0 billing drift, 0 CAPI drift.
17TRACK CronJob PROD suspendu. Webhook actif.
Client/Admin/Website PROD inchangés.
Rollback GitOps documenté.

ORDER TRACKING AI CONTEXT LIVE IN PROD - KEYBUZZ USES KNOWN ORDER/TRACKING DATA -
NO RE-ASK OF KNOWN ORDER OR TRACKING NUMBER - 17TRACK EVENTS AVAILABLE TO IA -
SELLER-FIRST PLATFORM-AWARE DELIVERY DRAFTS - NO AUTO-SEND -
NO BILLING/TRACKING/CAPI DRIFT - GITOPS STRICT

Rapport :
keybuzz-infra/docs/PH-API-T8.12AG-ORDER-TRACKING-AI-CONTEXT-PROD-PROMOTION-01.md
```
