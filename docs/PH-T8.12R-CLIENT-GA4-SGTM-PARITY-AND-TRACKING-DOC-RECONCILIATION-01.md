# PH-T8.12R-CLIENT-GA4-SGTM-PARITY-AND-TRACKING-DOC-RECONCILIATION-01

> **Objectif** : Restaurer GA4 + sGTM sur Client funnel PROD, preserver TikTok/LinkedIn, bloquer Meta Pixel Client (STOP DEDUP RISK), reconcilier la documentation.

---

## Sources relues

- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md`
- `PH-T8.12Q-ACQUISITION-TRACKING-PARITY-VISUAL-QA-AND-CLEANUP-01.md`
- `PH-T8.12Q.2-TIKTOK-EVENTS-MANAGER-TEST-CODE-CLOSURE-01.md`
- `PH-T8.12P-TIKTOK-BROWSER-PIXEL-CUTOVER-AND-DEDUP-01.md`
- `PH-T8.11Z-ANALYTICS-BASELINE-CLEAN-READINESS-01.md`
- `PH-GA4-CLIENT-ACTIVATION-01.md`
- `PH-GA4-CLIENT-ACTIVATION-PROD-PROMOTION-01.md`
- `PH-T8.11AF-GOOGLE-ADS-CREDENTIALS-GITOPS-AND-PROD-SYNC-01.md`
- `PH-T8.11AG-GOOGLE-OAUTH-CONSENT-PUBLISH-AND-TOKEN-DURABILITY-01.md` (absent — non trouve dans le repo)
- `PH-T8.11AL-GOOGLE-ADS-SIGNUP-COMPLETE-ACTIVATION-01.md`

---

## Preflight

| Repo | Branche | HEAD | Dirty | Decision |
|------|---------|------|-------|----------|
| keybuzz-infra | `main` | `5d29a37` | Non | OK |
| keybuzz-client (local) | `ph-t72/tiktok-tracking-dev` | `bfb9cdc2` | OUI | NE PAS utiliser |
| keybuzz-client (GitHub) | `ph-t812p/tiktok-browser-pixel` | `3325f03` | Non | Source build |

### Images PROD avant intervention

| Service | Image | Composant |
|---------|-------|-----------|
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.144-tiktok-browser-pixel-prod` | Deployment |
| Website | `ghcr.io/keybuzzio/keybuzz-website:v0.6.8-tiktok-browser-pixel-prod` | Inchange |
| API (principal) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.130-platform-aware-refund-strategy-prod` | Pod principal |
| API (outbound-worker) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod` | Outbound worker |
| Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-prod` | Inchange |

> **Note API** : Le pod principal a evolue de `v3.5.128` (documente dans T8.12Q) a `v3.5.130` entre les phases. L'outbound-worker reste a `v3.5.165`. Les rapports T8.12Q et T8.12Q.2 ont ete corriges pour distinguer les deux pods.

---

## Audit avant Client funnel

| Signal | `/register` | `/login` | Pages protegees | Verdict |
|--------|-------------|----------|-----------------|---------|
| TikTok `D7PT12JC77U44OJIPC10` | ACTIF | ACTIF | Absent | OK |
| LinkedIn `9969977` | ACTIF | ACTIF | Absent | OK |
| GA4 `G-R3QQDYEBFG` | **ABSENT** | **ABSENT** | Absent | A restaurer |
| sGTM `t.keybuzz.pro` | **ABSENT** | **ABSENT** | Absent | A restaurer |
| Meta Pixel | INACTIF | INACTIF | Absent | NE PAS activer |
| CompletePayment browser | ABSENT | ABSENT | N/A | OK (server-only) |

---

## Decision dedup

| Plateforme | Action | Risque doublon | Decision |
|------------|--------|----------------|----------|
| GA4 | Restaurer `G-R3QQDYEBFG` + sGTM | Aucun — pas de CAPI GA4 server-side | **GO** |
| sGTM | Restaurer `https://t.keybuzz.pro` | Aucun — routing layer | **GO** |
| TikTok Pixel | Conserver | Aucun (CompletePayment = server-only) | OK inchange |
| LinkedIn Insight | Conserver | Faible (dedup LinkedIn natif) | OK inchange |
| Meta Pixel | NE PAS activer | **STOP** — Meta CAPI actif, Purchase browser = double comptage | **STOP DEDUP RISK** |
| TikTok CompletePayment | Server-only | Aucun | OK inchange |

---

## Build

### Methode

Build Docker `--no-cache` depuis le bastion (`46.62.171.61`) :
- Source : `ph-t812p/tiktok-browser-pixel` @ `3325f03` (GitHub)
- Zero changement de code — uniquement des `--build-arg`

### Build-args

| Arg | Valeur |
|-----|--------|
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_META_PIXEL_ID` | **NON PASSE** (STOP DEDUP RISK) |

### Artefacts

| Element | Valeur |
|---------|--------|
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.145-client-ga4-sgtm-parity-prod` |
| Digest | `sha256:9239525e6ee33210fd4e360a786b9190301e9122c53cc886e77f39cf1a6df9f4` |
| Source | `ph-t812p/tiktok-browser-pixel` @ `3325f03` |

### Validations bundle

| Signal | Resultat |
|--------|----------|
| GA4 `G-R3QQDYEBFG` | FOUND |
| sGTM `t.keybuzz.pro` | FOUND |
| TikTok `D7PT12JC77U44OJIPC10` | FOUND |
| LinkedIn `9969977` | FOUND |
| Meta `fbq()` | Code conditionnel present mais inactif (`!window.fbq` = return) |
| CompletePayment | ABSENT |

---

## GitOps

| Element | Valeur |
|---------|--------|
| Fichier modifie | `k8s/keybuzz-client-prod/deployment.yaml` |
| Infra commit | `3fa7acf` |
| Push | `main → origin/main` |
| `kubectl apply` | `deployment.apps/keybuzz-client configured` |
| Rollout | `successfully rolled out` |
| Manifest = Runtime | `v3.5.145-client-ga4-sgtm-parity-prod` |

---

## Validation visuelle IDE — CONFIRMEE PAR HAR

**Validee par Ludovic via HAR exports (2026-05-01).**

### `/register` (HAR : `client.keybuzz.io(register).har`)
- [x] GA4 : `t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` charge + hits `imtzze` avec `dl=.../register`
- [x] sGTM : requetes vers `t.keybuzz.pro` (collecteur + service_worker)
- [x] TikTok : `analytics.tiktok.com/i18n/pixel/events.js?sdkid=D7PT12JC77U44OJIPC10` charge, evenement `EngagedSession`
- [x] LinkedIn : `snap.licdn.com/li.lms-analytics/insight.min.js` + `px.ads.linkedin.com/collect?pid=9969977`
- [x] Meta : **aucun** `connect.facebook.net` — absent
- [x] CompletePayment : aucun evenement reseau

### `/login` (HAR : `client.keybuzz.io(login).har`)
- [x] GA4 : hits `imtzze` avec `dl=.../login` via `t.keybuzz.pro`
- [x] sGTM : requetes vers `t.keybuzz.pro`
- [x] TikTok : `analytics.tiktok.com` charge, pixel `D7PT12JC77U44OJIPC10`
- [x] LinkedIn : `px.ads.linkedin.com/collect?pid=9969977` + `attribution_trigger`
- [x] Meta : absent
- [x] CompletePayment : absent

### `/dashboard` — page protegee (HAR : `client.keybuzz.io(dashboard).har`)
- [x] **Aucun tracking publicitaire** apres chargement `page_3` (dashboard)
- [x] Pas de nouveau `t.keybuzz.pro`, `analytics.tiktok.com`, `snap.licdn.com`, `px.ads.linkedin.com` dans le waterfall `page_3`
- [x] Les entrees tracking dans le HAR sont exclusivement heritees des pages register/login anterieures

> Note : le HAR dashboard contient l'historique register/login dans les pages precedentes. La fenetre `page_3` (dashboard) est propre.

---

## Reconciliation docs

| Rapport | Correction | Detail |
|---------|-----------|--------|
| PH-T8.12Q (ligne 53) | API → API (principal) + outbound-worker | Deux pods distincts documentes |
| PH-T8.12Q (ligne 270) | API PROD → API PROD (principal) + outbound-worker | Deux images distinctes |
| PH-T8.12Q.2 (ligne 107) | API → API (principal) + outbound-worker | Deux pods distincts documentes |

---

## Non-regression

| Composant | Statut | Detail |
|-----------|--------|--------|
| Client PROD | **MIS A JOUR** | `v3.5.145-client-ga4-sgtm-parity-prod` |
| Website PROD | Inchange | `v0.6.8-tiktok-browser-pixel-prod` |
| API PROD (principal) | Inchange (hors scope) | `v3.5.130-platform-aware-refund-strategy-prod` |
| API PROD (outbound-worker) | Inchange | `v3.5.165-escalation-flow-prod` |
| Admin PROD | Inchange | `v2.11.35-agency-launch-kit-prod` |
| TikTok Events API | ACTIF | Derniere livraison HTTP 200 (ViewContent) |
| Meta CAPI | ACTIF | Derniere livraison HTTP 200 (StartTrial) |
| LinkedIn CAPI | ACTIF | Derniere livraison HTTP 201 (StartTrial) |
| Client `/register` HTTP | 200 | Accessible |
| Faux events | Aucun | Derniers logs = test ViewContent + StartTrial reels |
| Fake spend | Aucun | Pas de Purchase/CompletePayment dans logs recents |
| Secrets exposes | Aucun | Aucun secret dans rapport ou logs |

### Destinations actives

| Type | Active | Nom |
|------|--------|-----|
| `tiktok_events` | OUI | KeyBuzz Consulting — TikTok — 2026-05 cutover |
| `meta_capi` | OUI | KeyBuzz Consulting — Meta CAPI |
| `linkedin_capi` | OUI | KeyBuzz Consulting — LinkedIn CAPI |

---

## Rollback (GitOps strict)

```bash
# 1. Revert le commit GitOps dans keybuzz-infra
cd keybuzz-infra
git revert 3fa7acf
git push origin main

# 2. Appliquer les manifests revertes
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod

# Image rollback : v3.5.144-tiktok-browser-pixel-prod
```

---

## Gaps restants

| Priorite | Gap | Detail |
|----------|-----|--------|
| P1 | Meta Pixel Client bloque | STOP DEDUP RISK — Meta CAPI actif, Purchase browser non deduplique |
| P2 | TikTok payload `content_id` | Test Events signale `content_id` manquant sur ViewContent |
| P3 | GA4 key events import Google Ads | `signup_complete` importe mais completion funnel a surveiller |

---

## Verdict

**GO CLIENT GA4 SGTM RESTORED — VISUAL QA DONE**

**CLIENT FUNNEL GA4 SGTM RESTORED — TIKTOK AND LINKEDIN PRESERVED — META CLIENT STILL BLOCKED BY DEDUP RISK — NO FAKE EVENT — NO FAKE SPEND — GITOPS STRICT — VISUAL QA DONE**
