# PH-T8.9D — Funnel Foundation PROD Promotion

> **Date** : 2026-04-23  
> **Auteur** : Cursor Executor (CE)  
> **Phase** : PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01  
> **Environnement** : PROD  
> **Type** : Promotion PROD — fondation Funnel / CRO onboarding  
> **Priorité** : P0  

---

## 1. OBJECTIF

Promouvoir en PROD la fondation Funnel/CRO validée en DEV (PH-T8.9B + PH-T8.9B.1), incluant :

- Table `funnel_events` avec contrainte UNIQUE et index
- `POST /funnel/event` (capture micro-steps idempotente)
- `GET /funnel/events` (listing avec cohort stitching)
- `GET /funnel/metrics` (agrégation avec cohort stitching)
- Instrumentation client `/register` (9 micro-steps)
- Émission BFF `email_submitted` / `otp_verified`
- Émission API `tenant_created` / `checkout_started`

**Périmètre strict** : API + Client uniquement. Admin V2 inchangée.

---

## 2. PREFLIGHT (ÉTAPE 0)

### API — `keybuzz-api`

| Élément | Valeur |
|---------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `2a61895e` — PH-T8.9B.1: funnel metrics tenant scope |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-dev` |
| Image PROD avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.107-ad-spend-idempotence-fix-prod` |
| Repo clean | ✅ |

### Client — `keybuzz-client`

| Élément | Valeur |
|---------|--------|
| Branche | `ph148/onboarding-activation-replay` |
| HEAD | `9d8b9a0` — PH-T8.9B: add funnel instrumentation |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-dev` |
| Image PROD avant | `ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-prod` |
| Repo clean | ✅ |

### Confirmation source finale

- **API** : `2a61895e` ✅
- **Client** : `9d8b9a0` ✅

---

## 3. VÉRIFICATION SOURCE (ÉTAPE 1)

### API

| Composant | Point | Résultat |
|-----------|-------|----------|
| Table | `funnel_events` | ✅ CREATE TABLE IF NOT EXISTS dans routes.ts |
| Contrainte | `UNIQUE(funnel_id, event_name)` | ✅ ON CONFLICT DO NOTHING |
| Route | `POST /funnel/event` | ✅ Enregistré dans app.ts sous `/funnel` |
| Route | `GET /funnel/events` | ✅ Avec filtres funnel_id, tenant_id, from, to |
| Route | `GET /funnel/metrics` | ✅ Agrégation 9 steps avec conversion rates |
| Cohort | Tenant stitching sur `/metrics` | ✅ `resolveTenantFunnelCohort()` |
| Cohort | Tenant stitching sur `/events` | ✅ Même helper de cohort |
| Emit | `email_submitted` (otp-routes) | ✅ Ligne 38 |
| Emit | `otp_verified` (otp-routes) | ✅ Ligne 72 |
| Emit | `tenant_created` (tenant-context-routes) | ✅ Ligne 724 |
| Emit | `checkout_started` (billing/routes) | ✅ Ligne 400 |
| Registration | `funnelRoutes` dans app.ts | ✅ Ligne 61 import, ligne 202 register |

### Client

| Composant | Point | Résultat |
|-----------|-------|----------|
| Helper | `src/lib/funnel.ts` | ✅ `emitFunnelStep` + `getFunnelId` |
| BFF | `app/api/funnel/event/route.ts` | ✅ Proxy vers `/funnel/event` |
| Step | `register_started` (useEffect mount) | ✅ Ligne 140-143 |
| Step | `plan_selected` (handleSelectPlan) | ✅ Ligne 503-504 |
| Step | `email_submitted` (BFF magic/start) | ✅ Ligne 51 |
| Step | `otp_verified` (handleVerifyCode) | ✅ Ligne 184-185 |
| Step | `oauth_started` (handleGoogleAuth) | ✅ Ligne 195-196 |
| Step | `company_completed` (handleCompanySubmit) | ✅ Ligne 204-205 |
| Step | `user_completed` (handleUserSubmit) | ✅ Ligne 219-220 |
| Continuité | plan/cycle/OAuth inchangée | ✅ funnel_id passé dans magic/start body |

---

## 4. STRATÉGIE PROD DB (ÉTAPE 2)

### État initial

- `funnel_events` n'existait **PAS** en PROD

### Création

Table créée en PROD via `kubectl exec` avec schéma identique DEV :

```sql
CREATE TABLE IF NOT EXISTS funnel_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  funnel_id TEXT NOT NULL,
  event_name TEXT NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('client', 'api', 'stripe_webhook')),
  tenant_id TEXT,
  attribution_id TEXT,
  plan TEXT,
  cycle TEXT,
  properties JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(funnel_id, event_name)
);
```

### Index PROD

| Index | Colonnes |
|-------|----------|
| `funnel_events_pkey` | `id` (PK) |
| `funnel_events_funnel_id_event_name_key` | `funnel_id, event_name` (UNIQUE) |
| `idx_funnel_events_funnel` | `funnel_id` |
| `idx_funnel_events_tenant` | `tenant_id` (WHERE tenant_id IS NOT NULL) |
| `idx_funnel_events_name` | `event_name` |
| `idx_funnel_events_created` | `created_at` |

### Impact

- Opération **additive uniquement** (CREATE IF NOT EXISTS)
- **Aucun impact** sur les tables business existantes
- **Aucune migration destructive**
- **Entièrement réversible** (DROP TABLE IF EXISTS)

---

## 5. BUILD SAFE PROD (ÉTAPE 3)

### API PROD

| Élément | Valeur |
|---------|--------|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-prod` |
| Commit | `2a61895e` |
| Branche | `ph147.4/source-of-truth` |
| Build | `docker build --no-cache` depuis `/opt/keybuzz/keybuzz-api` |
| Digest | `sha256:b6af128335edaecc97baa0109b4b8ed56bc1a6c674cbd4b8e50ef62630926db4` |
| Repo clean | ✅ |
| Build-from-git | ✅ |

### Client PROD

| Élément | Valeur |
|---------|--------|
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-prod` |
| Commit | `9d8b9a0` |
| Branche | `ph148/onboarding-activation-replay` |
| Build | `docker build --no-cache` avec `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |
| Digest | `sha256:e144be27ecbb7193e5790c529dcf0b8638e48ab6449dc6537813103f17c79729` |
| Repo clean | ✅ |
| Build-from-git | ✅ |

---

## 6. GITOPS PROD (ÉTAPE 4)

### Manifests modifiés

| Fichier | Image avant | Image après |
|---------|-------------|-------------|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.107-ad-spend-idempotence-fix-prod` | `v3.5.109-funnel-metrics-tenant-scope-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.63-ph151.2-case-summary-clean-prod` | `v3.5.108-funnel-pretenant-foundation-prod` |

### Commit infra

- **Commit** : `6c03abb`
- **Message** : `PH-T8.9D: promote funnel foundation to PROD — API v3.5.109 + Client v3.5.108`
- **Push** : `f093d08..6c03abb main -> main`

### Non-modification confirmée

- ❌ Aucun changement DEV
- ❌ Aucun changement Admin
- ❌ Aucun changement outbound-worker

---

## 7. DEPLOY PROD (ÉTAPE 5)

### Rollout

| Service | Status | Durée |
|---------|--------|-------|
| API PROD | ✅ `successfully rolled out` | ~30s |
| Client PROD | ✅ `successfully rolled out` | ~20s |

### Pods

| Pod | Status | Restarts |
|-----|--------|----------|
| `keybuzz-api-584dbfd685-fvvts` | Running | 0 |
| `keybuzz-client-86894895dd-pmmrx` | Running | 0 |

### Runtime images

- API PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-prod` ✅
- Client PROD : `ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-prod` ✅

### Health

```json
{"status":"ok","timestamp":"2026-04-23T21:46:24.591Z","service":"keybuzz-api","version":"1.0.0"}
```

---

## 8. VALIDATION PROD (ÉTAPE 6)

### A. Routes API

| Route | Résultat |
|-------|----------|
| `POST /funnel/event` | ✅ `{"status":"recorded","id":"10d27f3c-...","event_name":"register_started"}` |
| `GET /funnel/events?funnel_id=test-prod-validation-t89d` | ✅ 1 événement retourné (plan=pro, cycle=monthly, tenant_id=null) |
| `GET /funnel/metrics` | ✅ 9 steps retournés (register_started=1, reste=0) |

### B. Validation funnel PROD contrôlée

- Événement test créé avec `funnel_id=test-prod-validation-t89d`
- Step pré-tenant (`tenant_id=null`) correctement enregistré
- Idempotence fonctionnelle (UNIQUE constraint)
- **Nettoyé après validation** : 1 row test supprimée

### C. Non-régression onboarding

- `/register` : charge avec instrumentation funnel (build-arg PROD correctement injecté)
- plan/cycle : continuité via `getFunnelId()` et propagation dans `magic/start` body
- OAuth : continuité intacte (pas de modification du flow Google/Azure)
- `create-signup` : intact
- `checkout-session` : intact

### D. Tenant scope

Le cohort stitching est fonctionnel (validé code-level et en DEV). En PROD, aucun funnel réel n'existe encore (0 signups depuis le déploiement). Le premier vrai signup PROD validera automatiquement le parcours complet.

---

## 9. NON-RÉGRESSION (ÉTAPE 7)

| Point de vérification | Résultat |
|-----------------------|----------|
| `conversion_events` | ✅ 0 événements récents — aucune pollution funnel→conversion |
| Meta / webhook outbound | ✅ Micro-steps funnel ne sont PAS routés vers les destinations outbound |
| `signup_attribution` | ✅ Intact (3 rows, lecture seule) |
| Business events StartTrial / Purchase | ✅ Inchangés (chemin `conversion_events` séparé) |
| Health API | ✅ `{"status":"ok"}` |
| Health Client | ✅ Pod Running, 0 restarts |
| Pollution ads | ✅ Zéro — micro-steps sont internes uniquement |
| Admin PROD | ✅ Inchangée (pas dans le périmètre) |
| Metrics marketing existantes | ✅ Inchangées — `/metrics/overview`, `/ad-accounts` non modifiés |

---

## 10. LIMITATION CONNUE (ÉTAPE 8)

### Filtre `to` traité comme minuit exclusif

Le paramètre `to` sur `GET /funnel/events` et `GET /funnel/metrics` traite la date comme `YYYY-MM-DD 00:00:00`, ce qui exclut les événements de la journée `to`.

**Workaround actuel** : passer `to = lendemain` pour inclure tous les événements du jour souhaité.

**Exemple** : pour les événements jusqu'au 23 avril inclus, utiliser `to=2026-04-24`.

**Phase ultérieure** : si nécessaire, convertir `to` en `YYYY-MM-DD 23:59:59.999` côté API.

**Non corrigé dans cette phase** — conformément aux consignes.

---

## 11. ROLLBACK PROD (ÉTAPE 9)

### Procédure documentée (non exécutée)

**API Rollback** :
```yaml
# keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.107-ad-spend-idempotence-fix-prod
```

**Client Rollback** :
```yaml
# keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-prod
```

**Table** : `funnel_events` peut rester en PROD (aucun impact si non utilisée) ou être supprimée via :
```sql
DROP TABLE IF EXISTS funnel_events;
```

---

## 12. RÉSUMÉ IMAGES

| Service | AVANT | APRÈS |
|---------|-------|-------|
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` | `v3.5.109-funnel-metrics-tenant-scope-prod` |
| Client PROD | `v3.5.63-ph151.2-case-summary-clean-prod` | `v3.5.108-funnel-pretenant-foundation-prod` |
| Admin PROD | Inchangée | Inchangée |
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | Inchangée |
| Client DEV | `v3.5.108-funnel-pretenant-foundation-dev` | Inchangée |

### Digests PROD

| Image | Digest |
|-------|--------|
| API | `sha256:b6af128335edaecc97baa0109b4b8ed56bc1a6c674cbd4b8e50ef62630926db4` |
| Client | `sha256:e144be27ecbb7193e5790c529dcf0b8638e48ab6449dc6537813103f17c79729` |

---

## 13. DOCUMENTS DE RÉFÉRENCE

| Document | Chemin |
|----------|--------|
| Audit funnel CRO | `keybuzz-infra/docs/PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md` |
| Fondation pré-tenant DEV | `keybuzz-infra/docs/PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md` |
| Tenant scope DEV | `keybuzz-infra/docs/PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md` |
| **Ce rapport** | `keybuzz-infra/docs/PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md` |

---

## VERDICT

**FUNNEL FOUNDATION LIVE IN PROD — PRE-TENANT EVENTS CAPTURED — TENANT COHORT STITCHING ACTIVE — NO ADS POLLUTION — ADMIN UNCHANGED**
