# PH-AUDIT-CLIENT-API-PARITY-01 — Audit de verite DEV/PROD

> Date : 20 mars 2026
> Mode : AUDIT LECTURE SEULE
> Environnements : DEV + PROD

---

## 0. Pre-audit : Migration Amazon SP-API v2026-01-01

**Statut : NON EFFECTUEE**

Les workers Amazon utilisent toujours `orders/v0/orders` (5 occurrences dans le bundle compile).
Aucune reference a `v2026-01-01` dans le code.

| Service | Image actuelle |
|---|---|
| Amazon Orders Worker DEV | `v1.0.42-td02-worker-resilience-dev` |
| Amazon Orders Worker PROD | `v1.0.42-td02-worker-resilience-prod` |
| Amazon Items Worker DEV | `v1.0.42-td02-worker-resilience-dev` |
| Amazon Items Worker PROD | `v1.0.42-td02-worker-resilience-prod` |

Le suffixe `amz-v2026` dans les anciennes images etait un nom de branche, pas une migration reelle.

---

## 1. Inventaire des versions reelles

| Env | Service | Image | Digest SHA256 |
|---|---|---|---|
| DEV | Client | `v3.5.59-channels-stripe-sync-dev` | `sha256:d20d5841db8f9814...` |
| PROD | Client | `v3.5.59-channels-stripe-sync-prod` | `sha256:37b2ee535866...` |
| DEV | API | `v3.6.19-ph117-ai-dashboard-dev` | `sha256:ec7ced333411...` |
| PROD | API | `v3.6.19-ph117-ai-dashboard-prod` | `sha256:ec7ced333411...` |
| DEV | Backend | `v1.0.40-pj-fix-dev` | - |
| PROD | Backend | `v1.0.40-pj-fix-prod` | - |
| DEV | Outbound Worker | `v3.6.00-td02-worker-resilience-dev` | - |
| PROD | Outbound Worker | `v3.6.00-td02-worker-resilience-prod` | - |

### Constats :

- **API DEV et PROD ont le MEME digest** (`ec7ced33...`) = **codebase identique** ✅
- **Client DEV et PROD ont des digests DIFFERENTS** = builds differents (URLs build-time differentes, attendu) ✅
- **Backend DEV et PROD alignes** sur `v1.0.40` ✅
- Build date client : `2026-03-19T23:59:22Z`
- Version package.json : `0.5.11-ph29.3-parity`

---

## 2. Audit bundle client reel

### Routes pages (app/)

| Route | DEV | PROD |
|---|---|---|
| `/ai-dashboard` | ❌ **MANQUANT** | ✅ Present |
| `/ai-journal` | ✅ | ✅ |
| `/dashboard` | ✅ | ✅ |
| `/inbox` | ✅ | ✅ |
| `/orders` | ✅ | ✅ |
| `/channels` | ✅ | ✅ |
| `/suppliers` | ✅ | ✅ |
| `/knowledge` | ✅ | ✅ |
| `/playbooks` | ✅ | ✅ |
| `/billing` | ✅ | ✅ |
| `/settings` | ✅ | ✅ |
| Toutes les autres | ✅ Identiques | ✅ Identiques |

### Routes BFF (app/api/)

| Route BFF | DEV | PROD |
|---|---|---|
| `/api/ai/dashboard` | ❌ **MANQUANT** | ✅ Present |
| `/api/ai/assist` | ✅ | ✅ |
| `/api/ai/journal` | ✅ | ✅ |
| `/api/ai/wallet` | ✅ | ✅ |
| `/api/ai/context` | ✅ | ✅ |
| `/api/ai/settings` | ✅ | ✅ |
| `/api/ai/returns` | ✅ | ✅ |
| `/api/ai/learning-control` | ✅ | ✅ |

### URLs API dans le bundle

| Check | DEV | PROD |
|---|---|---|
| `api-dev.keybuzz.io` present | ✅ 1 occurrence | ❌ 0 occurrences |
| `api.keybuzz.io` present | ❌ 0 occurrences | ✅ 1 occurrence |

**Verdict** : Les URLs API build-time sont correctes dans chaque environnement ✅

### i18n / Navigation

| Check | DEV | PROD |
|---|---|---|
| `nav.ai_dashboard` dans i18n | ❌ **ABSENT du bundle** | ✅ Present ("IA Performance") |
| `ai-dashboard` dans ClientLayout | ❌ Absent | ✅ Present |
| Menu focus mode | ✅ Toggle present | ✅ Toggle present |
| Menu burger (mobile) | ✅ | ✅ |
| Menu fixe (desktop) | ✅ Sidebar `w-60` | ✅ Sidebar `w-60` |

---

## 3. Audit UI navigateur

L'acces authentifie (OTP) empeche un audit visuel complet via le navigateur automatise.

| Element | Observation |
|---|---|
| Page login DEV | ✅ Fonctionnelle, OTP OK |
| Page login PROD | ✅ Fonctionnelle, OTP OK |
| Console JS | ⚠️ 3 warnings deprecation (getSession, getCurrentTenantName, getCurrentTenantId) - non bloquants |
| Erreurs reseau | Aucune erreur 4xx/5xx sur les pages publiques |
| Routes protegees | Redirection correcte vers `/login?callbackUrl=...` |

---

## 4. Audit BFF routes Next.js

**Non testable en profondeur** sans session authentifiee. Mais l'existence des fichiers dans le bundle est confirmee (etape 2).

| Route BFF | DEV bundle | PROD bundle |
|---|---|---|
| `/api/ai/dashboard` | ❌ MANQUANT | ✅ Present |
| Toutes les autres | ✅ Identiques | ✅ Identiques |

---

## 5. Audit API backend PH41 → PH117

Test reel depuis les pods (27 endpoints, `x-user-email` + `x-tenant-id` injectes) :

| Endpoint | DEV | PROD | Coherent |
|---|---|---|---|
| `/health` | 200 | 200 | ✅ |
| `/ai/quality-score` | 400 | 400 | ✅ (params manquants) |
| `/ai/self-improvement` | 200 | 200 | ✅ |
| `/ai/governance` | 200 | 200 | ✅ |
| `/ai/knowledge-graph` | 200 | 200 | ✅ |
| `/ai/long-term-memory` | 200 | 200 | ✅ |
| `/ai/strategic-resolution` | 200 | 200 | ✅ |
| `/ai/autonomous-ops` | 200 | 200 | ✅ |
| `/ai/action-dispatcher` | 200 | 200 | ✅ |
| `/ai/connector-abstraction` | 200 | 200 | ✅ |
| `/ai/case-manager` | 200 | 200 | ✅ |
| `/ai/case-state` | 200 | 200 | ✅ |
| `/ai/controlled-execution` | 200 | 200 | ✅ |
| `/ai/controlled-activation` | 200 | 200 | ✅ |
| `/ai/real-execution-monitoring` | 200 | 200 | ✅ |
| `/ai/dashboard` | 200 | 200 | ✅ |
| `/ai/dashboard/metrics` | 200 | 200 | ✅ |
| `/ai/dashboard/execution` | 200 | 200 | ✅ |
| `/ai/dashboard/financial-impact` | 200 | 200 | ✅ |
| `/ai/dashboard/recommendations` | 200 | 200 | ✅ |
| `/ai/real-execution-live` | 400 | 400 | ✅ (params manquants) |
| `/ai/safe-execution` | 200 | 200 | ✅ |
| `/ai/real-execution-plan` | 200 | 200 | ✅ |
| `/ai/real-execution-status` | 200 | 200 | ✅ |
| `/ai/cross-tenant-intelligence` | 400 | 400 | ✅ (params manquants) |
| `/ai/performance-metrics` | 404 | 404 | ✅ (route non existante) |
| `/ai/health-monitoring` | 404 | 404 | ✅ (route non existante) |

**Verdict : API DEV et PROD 100% identiques. 27/27 endpoints avec meme statut.** ✅

---

## 6. Matrice de parite fonctionnelle PH41 → PH117

| Feature | Phase | API DEV | API PROD | Client DEV | Client PROD | Couche cassee |
|---|---|---|---|---|---|---|
| AI Assist | PH41+ | ✅ | ✅ | ✅ | ✅ | - |
| Quality Score | PH98 | ✅ | ✅ | N/A | N/A | - |
| Self-Improvement | PH99 | ✅ | ✅ | N/A | N/A | - |
| Governance | PH100 | ✅ | ✅ | N/A | N/A | - |
| Knowledge Graph | PH101 | ✅ | ✅ | N/A | N/A | - |
| Long-Term Memory | PH102 | ✅ | ✅ | N/A | N/A | - |
| Strategic Resolution | PH103 | ✅ | ✅ | N/A | N/A | - |
| Cross-Tenant Intel | PH104 | ✅ | ✅ | N/A | N/A | - |
| Autonomous Ops | PH105 | ✅ | ✅ | N/A | N/A | - |
| Action Dispatcher | PH106 | ✅ | ✅ | N/A | N/A | - |
| Connector Abstraction | PH107 | ✅ | ✅ | N/A | N/A | - |
| Case Manager | PH108 | ✅ | ✅ | N/A | N/A | - |
| Case State Persistence | PH109 | ✅ | ✅ | N/A | N/A | - |
| Controlled Execution | PH110 | ✅ | ✅ | N/A | N/A | - |
| Controlled Activation | PH111 | ✅ | ✅ | N/A | N/A | - |
| AI Control Panel | PH112 | ✅ | ✅ | Admin V2 | Admin V2 | - |
| Safe Connector | PH113 | ✅ | ✅ | N/A | N/A | - |
| Connector Scaling | PH114 | ✅ | ✅ | N/A | N/A | - |
| Real Execution | PH115 | ✅ | ✅ | N/A | N/A | - |
| Exec Monitoring | PH116 | ✅ | ✅ | N/A | N/A | - |
| **AI Dashboard** | **PH117** | ✅ | ✅ | ❌ **MANQUANT** | ✅ | **CLIENT DEV** |
| Channels/Billing | PH-CHANNELS | ✅ | ✅ | ✅ | ✅ | - |

---

## 7. Diagnostic final

### Cas identifie : **Cas A modifie**

> **DEV client en retard, PROD client a jour, API 100% alignee**

**Explication** :

1. Le client DEV (`v3.5.59-channels-stripe-sync-dev`) a ete build **AVANT** que les fichiers PH117 soient ajoutes au code source sur le bastion
2. Le client PROD (`v3.5.59-channels-stripe-sync-prod`) a ete build **APRES** l'ajout des fichiers PH117
3. Les deux images portent le meme tag base (`v3.5.59-channels-stripe-sync`) mais leur contenu est different
4. L'API est parfaitement alignee (meme digest SHA256) avec tous les endpoints PH41-PH117 fonctionnels

### Impact

| Aspect | Gravite |
|---|---|
| PROD client | ✅ OK - fonctionne avec PH117 |
| DEV client | ⚠️ MEDIUM - manque `/ai-dashboard` et BFF |
| API DEV/PROD | ✅ OK - 100% identique |
| Backend DEV/PROD | ✅ OK - aligne |
| Fonctionnalites core (inbox, orders, etc.) | ✅ OK - identiques |

**Gravite globale : MEDIUM** — Le probleme est localise au client DEV uniquement, pour la seule feature PH117.

---

## 8. Recommandation (sans agir)

### Plan de correction minimal

1. **Rebuilder le client DEV** depuis le meme code source (avec les fichiers PH117 en place) :
   ```bash
   cd /opt/keybuzz/keybuzz-client
   docker build --no-cache \
     --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
     --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
     -t ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev .
   docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev
   kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev -n keybuzz-client-dev
   ```

2. **Verifier visuellement** que le menu "IA Performance" apparait en DEV

3. **Mettre a jour GitOps** avec le nouveau tag

### Ordre des operations

1. Rebuild client DEV (5 min)
2. Deploy client DEV (1 min)
3. Verification visuelle (2 min)
4. GitOps update (1 min)

### Rollback de securite

- DEV : `kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-dev -n keybuzz-client-dev`
- PROD : `kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod -n keybuzz-client-prod`

---

## 9. Points d'attention supplementaires

### Amazon SP-API v2026-01-01
La migration vers la nouvelle API Amazon Orders n'a pas ete faite. Les workers utilisent `orders/v0/orders`. Amazon a annonce la deprecation de v0 — cette migration devrait etre planifiee.

### Routes API inexistantes (404)
- `/ai/performance-metrics` — 404 en DEV et PROD
- `/ai/health-monitoring` — 404 en DEV et PROD

Ces routes n'existent pas dans l'API actuelle. Si elles etaient prevues, elles restent a implementer.

### Dette technique client
- 3 warnings de deprecation (`getSession()`, `getCurrentTenantName()`, `getCurrentTenantId()`)
- Le focus mode est `true` par defaut (stocke en localStorage par tenant)

---

## Conclusion

**L'infrastructure est saine.** Le seul desalignement identifie est le client DEV qui n'a pas ete rebuild apres l'ajout des fichiers PH117 sur le bastion. La correction est triviale (un rebuild + deploy). L'API, le backend, et tous les endpoints PH41-PH117 sont 100% identiques entre DEV et PROD.
