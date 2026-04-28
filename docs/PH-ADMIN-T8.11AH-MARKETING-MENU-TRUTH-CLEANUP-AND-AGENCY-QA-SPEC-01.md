# PH-ADMIN-T8.11AH — Marketing Menu Truth Cleanup & Agency QA Spec

> Date : 29 avril 2026
> Auteur : Agent Cursor
> Environnement : DEV uniquement
> PROD : INCHANGÉE

---

## 1. PRÉFLIGHT

| Élément | Valeur | Verdict |
|---|---|---|
| Admin V2 branche | `main` | PASS |
| Admin V2 HEAD avant | `5cf0bda` | PASS |
| Admin V2 upstream sync | ✅ | PASS |
| Admin V2 working tree | clean | PASS |
| Infra branche | `main` | PASS |
| Infra HEAD avant | `0350e2c` | PASS |
| Infra upstream sync | ✅ | PASS |
| DEV runtime avant | `v2.11.29-acquisition-playbook-baseline-dev` | Noté |
| PROD runtime | `v2.11.22-acquisition-playbook-baseline-prod` | Inchangé |

---

## 2. SOURCES RELUES

- `PH-T8.11AF-GOOGLE-ADS-CREDENTIALS-GITOPS-AND-PROD-SYNC-01.md` — Google spend actif via GitOps credentials
- `PH-T8.11AG-GOOGLE-OAUTH-CONSENT-PUBLISH-AND-TOKEN-DURABILITY-01.md` — Token durable, consent screen En production
- `PH-ADMIN-T8.11AD-ACQUISITION-PLAYBOOK-BASELINE-PROD-PROMOTION-01.md` — Baseline analytics opérationnel
- Process-lock et git-source-of-truth rules

---

## 3. AUDIT STATIQUE — RÉSUMÉ

9 pages inspectées. Résultats avant corrections :

| Page | Problèmes trouvés |
|---|---|
| `/marketing/acquisition-playbook` | `codex` ×2, `codex-prod-runtime-check`, "Google = spend en finalisation", "Meta uniquement pour l'instant", "données à venir", "seul Meta" |
| `/marketing/integration-guide` | `utm_source=facebook` ×4 (table + JSON + exemples), Google Ads "Bientôt" ×4, "Non natif" ×2, pixel browser wording |
| `/marketing/google-tracking` | Google spend "Pas encore natif", "Bientôt" ×2 (TikTok + Google spend) |
| `/marketing/ad-accounts` | Description "Meta Ads par tenant" uniquement, pas de badge Google |
| `/marketing/destinations` | LinkedIn CAPI absent du modal de création, pas d'info block |
| `/marketing/delivery-logs` | Icône Meta vs Webhook générique, pas de mapping TikTok/LinkedIn |
| `/metrics` | ✅ Aucun problème (endpoint API, data-driven) |
| `/marketing/funnel` | ✅ Aucun problème (4 canaux corrects) |
| `/marketing/paid-channels` | ✅ Aucun problème (dynamique) |

---

## 4. CORRECTIONS — TABLEAU AVANT / APRÈS

### A. Acquisition Playbook (`acquisition-playbook/page.tsx`)

| Avant | Après |
|---|---|
| Pattern `codex` | `internal-validation` |
| Pattern `codex-prod-runtime-check` | `prod-runtime-check` |
| "Google = spend en finalisation" (amber) | "Google = spend actif. Données réelles importées via Google Ads API." (emerald) |
| "Meta uniquement pour l'instant" | "Meta + Google actifs, TikTok/LinkedIn non connectés" |
| "Meta natif, autres plateformes à venir" | "Meta + Google actifs, TikTok/LinkedIn non connectés" |
| "Spend Google Ads ... données à venir" | "Spend Google Ads volume faible (données réelles importées)" |
| "seul Meta est pleinement opérationnel" | "Meta et Google sont actifs. TikTok bloqué. LinkedIn hors périmètre." |
| "Comptes Meta, Google connectés" | "Comptes Meta + Google connectés (Meta self-service, Google via support)" |
| "métriques CAC et ROAS ... données Meta" | "Meta + Google uniquement. TikTok/LinkedIn non connectés." |

### B. Integration Guide (`integration-guide/page.tsx`)

| Avant | Après |
|---|---|
| `"utm_source": "facebook"` (JSON) | `"utm_source": "meta"` |
| "Source de trafic (facebook, google, tiktok...)" | "Source de trafic (meta, google, tiktok, linkedin)" |
| `utm_source=facebook` (URL exemples ×2) | `utm_source=meta` |
| Google Ads "Bientôt" (Ads Accounts) | "Actif" (credentials GitOps) |
| TikTok Ads "Bientôt" (Ads Accounts) | "Bloqué" (credentials Business API) |
| Google Ads "Bientôt" (tableau comparatif ×2) | "Actif" (spend via Google Ads API + conversions via sGTM) |
| TikTok "Bientôt" (tableau comparatif) | "Bloqué" (spend bloqué credentials) |
| Google Ads (incl. YouTube) = ligne séparée | Fusionnée dans "Google / YouTube" |
| Google Ads spend sync "Non natif" (limites) | "Actif" (données réelles importées) |
| TikTok Ads spend sync "Non natif" (limites) | "Bloqué" (credentials Business API) |
| "GA4 + Meta Pixel + TikTok Pixel browser actifs" | "GA4 + LinkedIn actifs. Meta/TikTok browser = gap P2 compensé par CAPI server-side" |

### C. Google Tracking (`google-tracking/page.tsx`)

| Avant | Après |
|---|---|
| "Pas encore natif dans l'Admin" (titre section) | Section séparée : "Spend & conversions — deux chemins" (emerald) + "Non applicable (by design)" |
| Google Ads spend sync `ok={false}` | `ok={true}` "Google Ads spend sync actif via Ads Accounts / Google Ads API" |
| Spend sync Google "Bientôt" (tableau) | "Actif" |
| Spend sync TikTok "Bientôt" (tableau) | "Bloqué" |

### D. Ad Accounts (`ad-accounts/page.tsx`)

| Avant | Après |
|---|---|
| Description "Meta Ads par tenant" | "Meta + Google connectés. Création self-service limitée à Meta. Google via support (credentials GitOps)." |
| PlatformBadge: Meta only | Meta (blue) + Google (red) |
| Empty state "Create a Meta Ads account" | "...Google Ads accounts configured via support interne." |

### E. Destinations (`destinations/page.tsx`)

| Avant | Après |
|---|---|
| Modal création : 3 boutons (Webhook, Meta, TikTok) | + info text "LinkedIn CAPI natif mais configuré par support interne. Google/YouTube via sGTM." |

### F. Delivery Logs (`delivery-logs/page.tsx`)

| Avant | Après |
|---|---|
| Icône Meta vs Webhook générique | Mapping complet : Meta (Facebook icon blue), TikTok (Music icon), LinkedIn (Linkedin icon sky), Webhook (Webhook icon) |
| Colonne Destination : nom seul | + badge type (`Meta CAPI`, `TikTok Events`, `LinkedIn CAPI`, `Webhook`) |

### G. Metrics — Aucune correction

Consomme `/api/admin/metrics/overview` (endpoint API). `/metrics/overview` n'est PAS une page. Google apparaît automatiquement dans Spend by Channel si l'API renvoie des données Google.

### H. Funnel — Aucune correction

Déjà cohérent : "Meta CAPI, TikTok Events API, LinkedIn CAPI et Google via sGTM".

---

## 5. VALIDATION — NO CODEX VISIBLE

### Bundle grep (pod DEV running)

| Terme interdit | Résultat |
|---|---|
| `codex` | **NONE** ✅ |
| `utm_source=facebook` | **NONE** ✅ |
| `Meta uniquement pour` | **NONE** ✅ |
| `en finalisation` | **NONE** ✅ |

### Termes attendus dans le bundle

| Terme | Fichier(s) trouvé(s) | Résultat |
|---|---|---|
| `internal-validation` | acquisition-playbook | ✅ |
| `spend actif` | acquisition-playbook | ✅ |
| `utm_source=meta` | integration-guide, acquisition-playbook | ✅ |
| `LinkedIn CAPI` | delivery-logs, integration-guide, google-tracking | ✅ |
| `credentials GitOps` | ad-accounts, integration-guide | ✅ |

### Pages accessibles (9/9)

Toutes retournent HTTP 307 (redirect vers login — comportement normal, admin protégé).

---

## 6. SPEC CAMPAIGN QA / URL BUILDER AGENCE

### Proposition

Nom : **Campaign QA** ou **URL Builder** (section dédiée ou page autonome dans Marketing)

### Fonctions

#### Formulaire
- **Plateforme** : `meta` / `google` / `tiktok` / `linkedin`
- **Acteur** : media buyer / agency / keybuzz → préfixe auto `mb-` / `ag-` / `kb-`
- **Campaign theme** : texte libre (slug auto)
- **Period** : sélecteur Q1/Q2/etc. ou date
- **Creative/Content** : texte libre (utm_content)
- **Audience/Term** : texte libre (utm_term)
- **Landing page** : `/pricing` par défaut, dropdown des pages validées

#### Génération URL
```
https://www.keybuzz.pro/pricing?utm_source=meta&utm_medium=cpc&utm_campaign=mb-launch-q2&utm_content=video-a&utm_term=founders
```

#### Validations
- ❌ Pas de homepage sauf override admin
- ❌ Pas de bit.ly
- ❌ Pas de click ID manuel (fbclid, gclid, ttclid, li_fat_id)
- ✅ `utm_source` doit être une plateforme valide
- ✅ `utm_campaign` doit commencer par `mb-` / `ag-` / `kb-`
- ✅ Google + YouTube → `utm_source=google`
- ✅ Meta → `utm_source=meta` (pas `facebook`)

#### Actions
- **Copier URL** (clipboard)
- **Ouvrir URL** (nouvel onglet)
- **Checklist post-lancement** (vérifier Delivery Logs, Funnel, Ads Manager)

#### Test non destructif
- Ne JAMAIS envoyer StartTrial/Purchase
- Vérifier uniquement que les query params sont présents
- Guider vers GA4 Realtime ou Funnel Admin pour la vérification
- Ne jamais polluer les plateformes avec de faux business events

### Décision Linear
Créer un ticket séparé : **"Campaign QA / URL Builder agence"** (P2, pas bloquant pour le lancement).

---

## 7. FICHIERS MODIFIÉS

| Fichier | Type | Corrections |
|---|---|---|
| `src/app/(admin)/marketing/acquisition-playbook/page.tsx` | Admin V2 | codex→internal-validation, Google spend actif, Meta+Google |
| `src/app/(admin)/marketing/integration-guide/page.tsx` | Admin V2 | utm_source=meta, Google Actif, TikTok Bloqué, pixel browser gap P2 |
| `src/app/(admin)/marketing/google-tracking/page.tsx` | Admin V2 | Spend sync actif, dual path spend/conversions |
| `src/app/(admin)/marketing/ad-accounts/page.tsx` | Admin V2 | Description Meta+Google, PlatformBadge Google |
| `src/app/(admin)/marketing/destinations/page.tsx` | Admin V2 | LinkedIn CAPI info dans modal création |
| `src/app/(admin)/marketing/delivery-logs/page.tsx` | Admin V2 | Mapping icône/badge par destination_type |
| `k8s/keybuzz-admin-v2-dev/deployment.yaml` | Infra | Image → v2.11.30 |

---

## 8. ARTEFACTS

| Élément | Valeur |
|---|---|
| Admin commit | `fee1a7d` |
| Admin tag DEV | `v2.11.30-marketing-menu-truth-cleanup-dev` |
| Digest | `sha256:26cebfe6008d01412424f46157489dbc2d3e2d28c45d3703d6ff1b32cd56103d` |
| Infra commit | `b9d0f6c` |
| Rollback DEV | `v2.11.29-acquisition-playbook-baseline-dev` |
| PROD | Inchangée (`v2.11.22-acquisition-playbook-baseline-prod`) |

---

## 9. ROLLBACK

Rollback **uniquement via GitOps** :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` → image `v2.11.29-acquisition-playbook-baseline-dev`
2. `git commit -m "rollback Admin DEV to v2.11.29"` + `git push origin main`
3. `kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev`

> **Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`, `kubectl set env`.

---

## 10. LINEAR

| Ticket | Action |
|---|---|
| Campaign QA / URL Builder | À créer (P2) — spec dans section 6 |
| KEY-217 (signup_complete sync) | Reste ouvert si pas définitivement synced |
| TikTok spend | Reste bloqué (business/API) |
| LinkedIn spend | Reste hors scope |

---

## 11. VERDICT

**MARKETING MENU TRUTH CLEANED IN DEV — NO CODEX VISIBLE TO AGENCIES — GOOGLE SPEND/KPI WORDING UPDATED — UTM CONVENTIONS ALIGNED — DESTINATIONS/LOGS LABELS CLARIFIED — CAMPAIGN QA SPEC READY — PROD UNCHANGED**
