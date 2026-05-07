# PH-SAAS-T8.12AP.4.2B — Shopify Visible Disabled in Channels PROD Fix

> Phase : PH-SAAS-T8.12AP.4.2B-SHOPIFY-VISIBLE-DISABLED-IN-CHANNELS-PROD-FIX-01
> Date : 7-8 mai 2026
> Ticket : KEY-276
> Type : Patch Client UX correctif + GitOps strict
> Priorité : P1
> Verdict : **GO PROD**

---

## Contexte

AP.4.2A a correctement empêché Shopify d'être connectable dans l'UI. Cependant, l'audit visuel Ludovic a identifié un écart :

| Surface | Attendu | État AP.4.2A |
|---|---|---|
| `/start` | Shopify grisé | ✅ OK |
| `/channels` page | Shopify non connectable | ✅ OK |
| `/channels` modale "Ajouter une marketplace" | Shopify visible dans "Bientôt disponible" | ❌ Shopify absent |

---

## Root Cause

Dans `app/channels/page.tsx`, la fonction `openCatalog()` injecte `shopifyEntry` (avec `coming_soon: true`) dans le tableau `available` → `catalogEntries`.

Le filtrage modal sépare en deux groupes :
- `availableToAdd` = `catalogEntries.filter(!coming_soon)` → section active (Shopify exclu ✓)
- `comingSoon` = `catalogFull.filter(coming_soon)` → section "Bientôt disponible"

**Bug** : `catalogFull` provient de `data.full` (API), mais `shopifyEntry` n'était injecté que dans `available`, **pas dans `catalogFull`**. Shopify n'apparaissait donc dans aucune section du modal.

---

## Fix

**1 fichier modifié** : `app/channels/page.tsx`

**Diff** (+2 lignes, -1 ligne) :
```diff
       if (!available.some((e: CatalogEntry) => e.provider === "shopify")) available.push(shopifyEntry);
       setCatalogEntries(available);
-      setCatalogFull(data.full || []);
+      const full = data.full || [];
+      if (!full.some((e: CatalogEntry) => e.provider === "shopify")) full.push(shopifyEntry);
+      setCatalogFull(full);
```

Shopify est maintenant injecté dans `catalogFull` avec `coming_soon: true`, ce qui le fait apparaître dans la section "Bientôt disponible" du modal.

---

## Validations

### Statique
| Check | Résultat |
|---|---|
| `shopifyEntry.coming_soon = true` | ✅ |
| Exclu de `availableToAdd` | ✅ |
| Présent dans `catalogFull` | ✅ |
| Section "Bientôt disponible" le rend | ✅ |
| 0 "Connecter Shopify" actif | ✅ |
| 0 `setShowShopifyModal(true)` appelé | ✅ |
| `return;` safety dans onClick catalog | ✅ |
| `handleAddChannel` préservé | ✅ |
| OnboardingHub `comingSoon: true` | ✅ |

### Tracking PROD bundle
| Tracker | Count | Status |
|---|---|---|
| GA4 (`G-R3QQDYEBFG`) | 1 | ✅ |
| sGTM (`t.keybuzz.pro`) | 2 | ✅ |
| TikTok (`D7PT12JC77U44OJIPC10`) | 1 | ✅ |
| LinkedIn (`9969977`) | 1 | ✅ |
| Meta (`1234164602194748`) | 1 | ✅ |
| DEV leak (`api-dev.keybuzz.io`) | 0 | ✅ |

### Runtime PROD
| Check | Résultat |
|---|---|
| `/start` HTTP | ✅ 307 (auth redirect) |
| `/channels` HTTP | ✅ 307 (auth redirect) |
| Pod PROD 1/1 Running | ✅ |

---

## Baselines PROD (vérifiées post-deploy)

| Service | Image | Changé ? |
|---|---|---|
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | ✅ Mis à jour |
| API | `v3.5.147-auto-assignment-after-reply-prod` | ❌ Inchangé |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | ❌ Inchangé |
| Website | `v0.6.10-connector-claims-truth-prod` | ❌ Inchangé |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | ❌ Inchangé |

---

## Builds

| Env | Tag | Digest |
|---|---|---|
| DEV | `v3.5.170-shopify-visible-disabled-channels-dev` | `sha256:c5b3da80cfb4de5bd2df5044ffe78f72210792ccea0da5bd7c673f36ab5bd068` |
| PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | `sha256:dc0140f5c8313383b3c2d2cb8a143119887d0085ed3243bc8aff01587ee2c145` |

---

## Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `5e24487` | fix(channels): show Shopify in catalog modal Bientot disponible section (AP.4.2B KEY-276) |
| keybuzz-infra | `main` | `1920a0a` | deploy(client-dev): v3.5.170-shopify-visible-disabled-channels-dev (AP.4.2B KEY-276) |
| keybuzz-infra | `main` | `38d77c0` | deploy(client-prod): v3.5.170-shopify-visible-disabled-channels-prod (AP.4.2B KEY-276) |

---

## Non-régression

| Domaine | Vérifié |
|---|---|
| Amazon connectable | ✅ |
| Cdiscount/Octopia inchangé | ✅ |
| Fnac/Darty/eBay inchangés | ✅ |
| Tracking Client préservé | ✅ |
| Promo funnel préservé | ✅ |
| API/Backend/DB/billing inchangés | ✅ |
| 0 DB mutation | ✅ |
| 0 billing/CAPI drift | ✅ |

---

## Rollback

Client PROD rollback :
```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.169-shopify-disabled-until-approval-prod
```

Procédure :
1. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml`
2. `git commit + push`
3. `kubectl apply -f`
4. `kubectl rollout status`

---

## Linear Updates

| Ticket | Action |
|---|---|
| KEY-276 | Correction AP.4.2B — Shopify visible disabled partout — fermer si PROD OK |
| KEY-273 | Shopify activation reste ouvert — UX disabled propre jusqu'à app approval |
| KEY-271 | AP.4 Shopify UX complètement mitigé |
| KEY-253 | Pre-Ads safe |
| KEY-270 | AP.3 peut reprendre après cette correction |

---

## Verdict

**GO PROD**

SHOPIFY VISIBLE DISABLED STATE LIVE IN PROD — SHOPIFY APPEARS IN START AND CHANNELS AS EN PRÉPARATION — SHOPIFY IS NOT CONNECTABLE UNTIL APP APPROVAL — AMAZON/EMAIL CONNECTORS PRESERVED — CLIENT TRACKING/PROMO/AMAZON GUIDE/DEMO GATING PRESERVED — API/BACKEND/WEBSITE/DB UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
