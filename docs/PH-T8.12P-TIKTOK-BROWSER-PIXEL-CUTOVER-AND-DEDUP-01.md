# PH-T8.12P — TikTok Browser Pixel Cutover & Deduplication

> Date : 2026-05-01
> Statut : **TERMINE — GO**

---

## Objectif

Activer le TikTok Browser Pixel (`D7PT12JC77U44OJIPC10`) sur Client PROD et Website PROD, avec deduplication securisee vis-a-vis du TikTok Events API server-side deja actif.

---

## Verdict

**GO** — TikTok Browser Pixel actif sur Client et Website PROD. CompletePayment desactive cote browser (server-side only). Zero regression sur Meta CAPI, LinkedIn CAPI, GA4, sGTM.

---

## Decision de deduplication

### Probleme identifie

| Propriete | Browser (Client) | Server (API) |
|---|---|---|
| Evenement | `CompletePayment` | `CompletePayment` |
| `event_id` | `params.transactionId` (Stripe Checkout Session ID) | `conv_<tenant>_Purchase_<stripe_sub_id>` |
| **Format** | **Different** | **Different** |

TikTok ne peut pas dedupliquer deux evenements `CompletePayment` avec des `event_id` differents. Double comptage garanti.

### Decision

`CompletePayment` = **server-side only** via Events API. Le call `trackTikTok('CompletePayment', ...)` a ete supprime de `src/lib/tracking.ts` (commit `3325f03`).

### Evenements browser autorises

| Evenement | Fonction | Surface | Equivalent serveur | Risque dedup |
|---|---|---|---|---|
| PageView | `ttq.page()` | /register, /login | Aucun | Zero |
| SubmitForm | `trackSignupStart` | /register | Aucun | Zero |
| InitiateCheckout | `trackBeginCheckout` | Checkout | Aucun | Zero |
| ~~CompletePayment~~ | ~~`trackPurchase`~~ | ~~Post-paiement~~ | **Events API** | **Supprime** |

---

## Artefacts

### Client

| Element | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.144-tiktok-browser-pixel-prod` |
| Digest | `sha256:e7bbaadfd912a54f2ec29d9987777b7893a1b180f4978b09d464323e6907faa9` |
| Source | `3325f03` (`ph-t812p/tiktok-browser-pixel`) |
| Build-args | `NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10`, `NEXT_PUBLIC_APP_ENV=production`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |
| Rollback | `v3.5.142-sample-demo-wow-prod` |

### Website

| Element | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-website:v0.6.8-tiktok-browser-pixel-prod` |
| Digest | `sha256:478bf6b47561d14bf8a1340406b2ae1377e878b0960b7cca5280570780396039` |
| Source | `0b9d1ea` (`main`) |
| Build-args | Tous existants + `NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10` |
| Rollback | `v0.6.7-pricing-attribution-forwarding-prod` |

### GitOps

| Element | Valeur |
|---|---|
| Commit infra | `69d4e5e` |
| Fichiers modifies | `k8s/keybuzz-client-prod/deployment.yaml`, `k8s/website-prod/deployment.yaml` |

### Code source

| Element | Valeur |
|---|---|
| Commit client | `3325f03` |
| Branche | `ph-t812p/tiktok-browser-pixel` |
| Fichier modifie | `src/lib/tracking.ts` — suppression `trackTikTok('CompletePayment', ...)` |

---

## Validation PROD

### Client PROD — 5/5 PASS

| Check | Resultat |
|---|---|
| TikTok Pixel ID (`D7PT12JC77U44OJIPC10`) dans bundle | PASS |
| `TiktokAnalyticsObject` dans bundle | PASS |
| `CompletePayment` absent du bundle | PASS |
| `SubmitForm` present | PASS |
| LinkedIn `9969977` non regresse | PASS |

### Website PROD — 4/4 PASS

| Check | Resultat |
|---|---|
| TikTok Pixel ID dans bundle | PASS |
| GA4 `G-R3QQDYEBFG` non regresse | PASS |
| Meta Pixel `1234164602194748` non regresse | PASS |
| SGTM `t.keybuzz.pro` non regresse | PASS |

### Server-side — Non-regression confirmee

| Destination | Type | Statut |
|---|---|---|
| KeyBuzz Consulting — TikTok — 2026-05 cutover | `tiktok_events` | **ACTIF** |
| KeyBuzz Consulting — Meta CAPI | `meta_capi` | ACTIF |
| KeyBuzz Consulting — LinkedIn CAPI | `linkedin_capi` | ACTIF |
| KeyBuzz Consulting — TikTok (ancien) | `tiktok_events` | Inactif |

---

## Protection des pages

`SaaSAnalytics.tsx` ne charge les scripts tracking que sur les pages funnel :
- `FUNNEL_PREFIXES = ['/register', '/login']`
- `BLOCKED_PREFIXES` = 12 chemins proteges (inbox, dashboard, orders, settings, channels, suppliers, knowledge, playbooks, ai-journal, billing, onboarding, workspace-setup, start, help)
- Double garde : `shouldLoad = !isBlockedPage(pathname) && isFunnelPage(pathname)`

Aucun pixel publicitaire ne se charge sur les pages protegees de l'application.

---

## Etat post-cutover — Matrice tracking TikTok

| Couche | Surface | Evenements | Statut |
|---|---|---|---|
| Browser Pixel | Website (keybuzz.pro) | PageView | ACTIF |
| Browser Pixel | Client (/register, /login) | PageView, SubmitForm, InitiateCheckout | ACTIF |
| Browser Pixel | Client (pages protegees) | Aucun | BLOQUE |
| Events API | Server-side (API) | Subscribe (StartTrial), CompletePayment (Purchase) | ACTIF |
| Spend/KPI | Non connecte | — | BLOQUE (Business API approval pending) |

---

## Build-args reference (pour tout rebuild futur)

### Client PROD

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10 \
  -t ghcr.io/keybuzzio/keybuzz-client:<tag> .
```

Note : LinkedIn (`9969977`) est dans le default du Dockerfile.

### Website PROD

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10 \
  -t ghcr.io/keybuzzio/keybuzz-website:<tag> .
```

---

## Rollback (GitOps strict)

```bash
# 1. Revert le commit GitOps dans keybuzz-infra
cd keybuzz-infra
git revert 69d4e5e
git push origin main

# 2. Appliquer les manifests revertis
# Client
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod

# Website
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-website -n keybuzz-website-prod

# Images rollback :
#   Client  → v3.5.142-sample-demo-wow-prod
#   Website → v0.6.7-pricing-attribution-forwarding-prod
```

---

## Ecarts identifies (hors scope)

| Ecart | Severite | Description |
|---|---|---|
| GA4 absent du Client PROD | P2 | `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG` non passe en build-arg depuis plusieurs versions. Restauration dans un prochain rebuild. |
| Meta Pixel absent du Client PROD | P2 | `NEXT_PUBLIC_META_PIXEL_ID` jamais passe en build-arg Client (absent du Dockerfile defaults). Website l'a via `1234164602194748`. |
| SGTM absent du Client PROD | P2 | `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro` non passe. GA4 sans sGTM proxy. |
| Admin wording | P3 | `paid-channels/page.tsx` mis a jour localement pour preciser "CompletePayment server-side only". Commit/deploy Admin a faire separement. |
| `event_id` alignment | P3 | Si dedup browser + server est souhaitee a terme, aligner le format `event_id` entre `tracking.ts` (browser) et l'adaptateur TikTok (server). |
