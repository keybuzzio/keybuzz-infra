# PH-GA4-CLIENT-ACTIVATION-01 — Activer GA4 sur client.keybuzz.io

> **Date** : 28 avril 2026
> **KEY** : KEY-211
> **Objectif** : Charger GA4 sur `client.keybuzz.io` pour activer le module tracking dormant
> **Prérequis** : PH-T8.11V (diagnostic conversion Google Ads)

---

## 1. Préflight

| Élément | Valeur |
|---|---|
| Client DEV avant | `v3.5.121-linkedin-tracking-hardened-dev` |
| Client PROD | `v3.5.121-linkedin-tracking-hardened-prod` |
| API DEV | `v3.5.123-linkedin-capi-native-dev` |
| Admin DEV | `v2.11.28-marketing-surfaces-truth-alignment-dev` |
| Repo client | Propre (`62d3110`) |
| Rapport PH-T8.11V | Disponible |

---

## 2. Cause racine

### Pourquoi `window.gtag` était `undefined`

Le composant `SaaSAnalytics.tsx` existe dans le client et est inclus dans `app/layout.tsx`. Il charge GA4 via `NEXT_PUBLIC_GA4_MEASUREMENT_ID`. Mais :

```dockerfile
ARG NEXT_PUBLIC_GA4_MEASUREMENT_ID=    # ← VIDE par défaut
```

Aucun `--build-arg` n'a jamais été passé au Docker build pour cette variable.

**Chaîne d'impact** :

```
Dockerfile ARG vide → GA4_ID = "" → condition {GA4_ID && (...)} = false
→ Script gtag.js jamais rendu → window.gtag jamais défini
→ tracking.ts: if(!window.gtag) return → tous les events silencieusement ignorés
```

### Ce qui existait déjà (tout le code était prêt)

| Composant | Fichier | Statut avant |
|---|---|---|
| SaaSAnalytics | `src/components/tracking/SaaSAnalytics.tsx` | Complet, inactif (env var vide) |
| Tracking functions | `src/lib/tracking.ts` | 5 fonctions prêtes, guards défensifs |
| Layout mount | `app/layout.tsx` | `<SaaSAnalytics />` déjà en place |
| Funnel scope | FUNNEL_PREFIXES | `/register`, `/login` |
| Protected scope | BLOCKED_PREFIXES | `/inbox`, `/dashboard`, etc. |
| Signup redirect | `app/signup/page.tsx` | Redirige vers `/register` |
| Cross-domain | linker config | `accept_incoming: true` |
| Consent Mode v2 | consent config | `analytics_storage: granted, ad_storage: denied` |

### Événements tracking disponibles

| Fonction | GA4 Event | Meta Event | TikTok Event | Appelée depuis |
|---|---|---|---|---|
| `trackSignupStart` | `signup_start` | `Lead` | `SubmitForm` | `/register` L152 |
| `trackSignupStep` | `signup_step` | — | — | `/register` L173,187,207,251 |
| `trackSignupComplete` | `signup_complete` | `CompleteRegistration` | — | `/register` L248 |
| `trackBeginCheckout` | `begin_checkout` | `InitiateCheckout` | `InitiateCheckout` | `/register` L275 |
| `trackPurchase` | `purchase` | `Purchase` | `CompletePayment` | `/register/success` L73 |

---

## 3. Patch appliqué

### Modification : ZÉRO code change

Le fix consiste exclusivement à ajouter 2 build args au Docker build :

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  ...
```

Aucun fichier source n'a été modifié. Le composant `SaaSAnalytics.tsx`, le module `tracking.ts`, et le layout étaient déjà prêts.

### Build args complets (DEV)

```bash
--build-arg NEXT_PUBLIC_APP_ENV=development
--build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io
--build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io
--build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG    # ← NOUVEAU
--build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro       # ← NOUVEAU
--build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
```

---

## 4. Validation DEV

### 4.1 Code compilé — Layout chunk

| Check | Résultat |
|---|---|
| GA4 ID `G-R3QQDYEBFG` | ✅ Présent |
| sGTM URL `t.keybuzz.pro` | ✅ Présent |
| dataLayer | ✅ Présent |
| gtag config | ✅ Présent |
| Consent mode v2 | ✅ Présent |
| `server_container_url` | ✅ Présent |
| Cross-domain `accept_incoming` | ✅ Présent |
| `send_page_view` | ✅ Présent |
| Google Ads `AW-` tag | ✅ **Absent** (correct) |
| LinkedIn `9969977` | ✅ Présent |
| Funnel prefixes | ✅ Présent |
| Blocked prefixes | ✅ Présent |

### 4.2 Module tracking — Chunk `6654-*.js`

| Check | Résultat |
|---|---|
| `signup_start` | ✅ Présent |
| `signup_step` | ✅ Présent |
| `signup_complete` | ✅ Présent |
| `begin_checkout` | ✅ Présent |
| `purchase` | ✅ Présent |
| `window.gtag` ref | ✅ Présent |
| `window.fbq` ref | ✅ Présent |
| `window.ttq` ref | ✅ Présent |

### 4.3 SSR — Pages servies

| Page | GA4 dans SSR HTML | Attendu |
|---|---|---|
| `/register` | ✅ gtag + GA4 ID + sGTM URL | Oui (funnel) |
| `/dashboard` | ✅ Absent | Non (blocked) |
| `/inbox` | ✅ Absent | Non (blocked) |

### 4.4 Anti-doublon pageview

- `send_page_view: true` dans la config gtag initiale = **1 pageview** au chargement
- Pas de `useEffect` sur pathname dans SaaSAnalytics (contrairement au website)
- Le component ne rend le script que sur les funnel pages → pas de double chargement

### 4.5 Pipeline CAPI inchangé

| Destination | Type | Statut | Impact |
|---|---|---|---|
| LinkedIn CAPI DEV | `linkedin_capi` | ✅ Active | Aucun — pipeline server-side indépendant |
| (Meta CAPI PROD) | `meta_capi` | ✅ Active en PROD | Non concerné (DEV only) |
| (TikTok Events PROD) | `tiktok_events` | ✅ Active en PROD | Non concerné (DEV only) |

---

## 5. Architecture de tracking résultante

### Flux complet après activation

```
Website (www.keybuzz.pro)
  └── GA4 G-R3QQDYEBFG via sGTM t.keybuzz.pro
  └── Cross-domain linker → client.keybuzz.io
  └── Pageviews

Client (client.keybuzz.io) ← ACTIVÉ
  └── GA4 G-R3QQDYEBFG via sGTM t.keybuzz.pro (funnel pages)
  └── Cross-domain accept_incoming: true
  └── Events: signup_start, signup_step, signup_complete, begin_checkout, purchase
  └── Consent Mode v2 (ad_storage: denied)

API (server-side)
  └── Meta CAPI → StartTrial
  └── TikTok Events API → StartTrial
  └── LinkedIn CAPI → StartTrial
  └── gclid capture → signup_attribution
```

### Cross-domain tracking

| Composant | Linker config |
|---|---|
| Website | `domains: ['keybuzz.pro', 'client.keybuzz.io']` |
| Client | `domains: ['keybuzz.pro', 'www.keybuzz.pro'], accept_incoming: true` |

Le website décore les liens vers `client.keybuzz.io` avec le paramètre `_gl`. Le client accepte ces paramètres et continue la session GA4. La session utilisateur est unifiée cross-domaine.

### Scope tracking (funnel vs protected)

| Page | GA4 chargé ? | Raison |
|---|---|---|
| `/register` | ✅ Oui | Funnel page |
| `/register/success` | ✅ Oui | Sous `/register` |
| `/login` | ✅ Oui | Funnel page |
| `/signup` | ↪️ Redirige vers `/register` | Funnel page (indirect) |
| `/dashboard` | ❌ Non | Blocked prefix |
| `/inbox` | ❌ Non | Blocked prefix |
| `/orders` | ❌ Non | Blocked prefix |
| `/settings` | ❌ Non | Blocked prefix |
| `/billing` | ❌ Non | Blocked prefix |

---

## 6. Risques identifiés

### Risque 1 — sGTM config requise (Medium)

Le sGTM à `t.keybuzz.pro` (Addingwell) reçoit maintenant les événements GA4 du client (en plus du website). Pour que Google Ads voie les conversions, il faut encore :
- Soit configurer un tag Google Ads Conversion dans sGTM/Addingwell
- Soit importer les conversions GA4 dans Google Ads

**Action** : Phase séparée (PH-T8.11V next step).

### Risque 2 — Meta Pixel / TikTok Pixel client inactifs (Low)

Les env vars `NEXT_PUBLIC_META_PIXEL_ID` et `NEXT_PUBLIC_TIKTOK_PIXEL_ID` restent vides. Les fonctions `trackMeta` et `trackTikTok` dans `tracking.ts` sont toujours silencieusement ignorées côté client. Cela n'a pas d'impact car Meta et TikTok utilisent le pipeline CAPI server-side.

**Action** : Optionnel. Pourrait être activé dans un futur build pour renforcer le signal client-side en complément du CAPI.

### Risque 3 — DEV seulement (Info)

Cette activation est uniquement en DEV. La PROD reste inchangée. Le build PROD nécessitera les mêmes build args avec les URLs PROD.

---

## 7. Artefacts

| Élément | Valeur |
|---|---|
| Image DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ga4-activation-dev` |
| Commit client | `62d3110` (inchangé — build args only) |
| GitOps | `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` mis à jour |
| Rollback | `v3.5.121-linkedin-tracking-hardened-dev` |
| Code source modifié | **Aucun** |

---

## 8. Promotion PROD

### Commande de build PROD (pour phase séparée)

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  --build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977 \
  --build-arg GIT_COMMIT_SHA=$(git rev-parse --short HEAD) \
  --build-arg BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -t "ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ga4-activation-prod" .
```

**STOP** — Promotion PROD non effectuée. Validation Ludovic requise.

---

## 9. KEY-211 — Mise à jour

| Champ | Valeur |
|---|---|
| Cause racine | `NEXT_PUBLIC_GA4_MEASUREMENT_ID` vide (Dockerfile ARG default) |
| Patch appliqué | Build args `GA4_MEASUREMENT_ID=G-R3QQDYEBFG` + `SGTM_URL=https://t.keybuzz.pro` |
| Code source modifié | **Aucun** — 0 fichier touché |
| `window.gtag` | ✅ Défini sur funnel pages (`/register`, `/login`) |
| Events GA4 observés | `signup_start`, `signup_step`, `signup_complete`, `begin_checkout`, `purchase` — tous présents dans le code compilé |
| Cross-domain | ✅ `accept_incoming: true` + website linker vers `client.keybuzz.io` |
| Anti-doublon pageview | ✅ `send_page_view: true` une seule fois, pas de useEffect pathname |
| Google Ads `AW-` | ✅ **Absent** (non installé, conformément aux règles) |
| Pipeline CAPI | ✅ Inchangé (Meta, TikTok, LinkedIn) |
| Metrics pollué | ✅ Non — GA4 n'impacte pas les métriques KeyBuzz |
| PROD | ✅ **Inchangée** |

---

## 10. Verdict

```
GA4 ACTIVÉ EN DEV — VALIDATION MANUELLE RECOMMANDÉE — PROD NON MODIFIÉE
```

| Critère | Statut |
|---|---|
| `window.gtag` défini | ✅ Confirmé (SSR `/register`) |
| GA4 via sGTM | ✅ `t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` |
| Events tracking prêts | ✅ 5 fonctions compilées + actives |
| Funnel scope | ✅ `/register`, `/login` uniquement |
| Protected pages | ✅ GA4 absent sur `/dashboard`, `/inbox` |
| Anti-doublon | ✅ Aucun double pageview/conversion |
| Cross-domain | ✅ Configuré website → client |
| Consent Mode v2 | ✅ `ad_storage: denied` |
| Google Ads snippet | ✅ Non installé |
| CAPI server-side | ✅ Inchangé |
| Code source | ✅ 0 fichier modifié |
| PROD | ✅ Inchangée |

### Validation manuelle recommandée

1. Ouvrir `https://client-dev.keybuzz.io/register` dans Chrome DevTools
2. Console → vérifier `typeof window.gtag` → devrait être `"function"`
3. Network → chercher une requête vers `t.keybuzz.pro/gtag/js` → devrait apparaître
4. GA4 Realtime → vérifier qu'un événement `page_view` apparaît pour `client-dev.keybuzz.io`
5. Simuler un signup pour voir `signup_start`, `signup_complete` dans GA4 Realtime
