# PH-T8.11AJ — MARKETING-OWNER-TENANT-ID-CLIENT-AND-PLAYBOOK-CLOSURE-01

**Date** : 29 avril 2026
**Ticket** : KEY-222
**Phase précédente** : PH-T8.11AI

---

## 1. Préflight

| Élément | Valeur | Status |
|---------|--------|--------|
| API PROD | `v3.5.123-linkedin-capi-native-prod` | inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | inchangé |
| Admin PROD avant | `v2.11.23-marketing-menu-truth-cleanup-prod` | → mis à jour |
| Admin DEV avant | `v2.11.30-marketing-menu-truth-cleanup-dev` | → mis à jour |
| API PROD health | `{"status":"ok"}` | ✅ |
| Client bastion | `ph148/onboarding-activation-replay` @ `8961023` (clean) | ✅ |
| Admin bastion | `main` @ `5cf0bda` → `7296872` (clean) | ✅ |
| Infra | `main` @ `95fa183` → `2e59486` | ✅ |

### Rapports lus

| Rapport | Verdict |
|---------|---------|
| PH-T8.11AI | Attribution qualifiée, `signup_complete` HIDDEN, gap owner P2 |
| PH-T8.11X | GA4↔Ads liaison faite, pas de tag AW |
| PH-T8.11Y | Register console cleanup done |
| PH-T8.11Z | Baseline GO 29 avril 2026 |
| PH-ADMIN-T8.11AH.1 | Marketing menu truth cleanup PROD |

---

## 2. Audit Client — État avant patch

### Découverte majeure

Le code client **contient déjà** `marketing_owner_tenant_id` dans le flux d'attribution — implémenté dans les commits suivants (branche `ph148/onboarding-activation-replay`) :

| Commit | Description |
|--------|-------------|
| `6d5a796` | PH-T8.10B: capture `marketing_owner_tenant_id` from URL params |
| `ce23377` | PH-T8.10W: add `li_fat_id` to attribution capture |

### Fichiers impactés (déjà déployés en PROD)

**`src/lib/attribution.ts`** :
- Interface `AttributionContext` inclut `marketing_owner_tenant_id: string | null`
- Interface `AttributionContext` inclut `li_fat_id: string | null`
- `captureAttribution()` lit `marketing_owner_tenant_id` depuis `URLSearchParams`
- `li_fat_id` ajouté à `CLICK_ID_PARAMS`
- `hasSignals()` inclut `li_fat_id`
- Contexte minimal inclut les deux champs

**`app/register/page.tsx`** :
- POST body inclut `marketing_owner_tenant_id: currentAttribution?.marketing_owner_tenant_id || undefined` (top-level)

### Vérification PROD

Le bundle Client PROD (`v3.5.125`) contient `marketing_owner_tenant_id` dans :
- 3 fichiers du bundle `.next/`
- 1 occurrence dans `/app/.next/server/app/register/page.js`

**CONCLUSION** : Aucun patch client nécessaire. ÉTAPE 2 annulée.

---

## 3. Extraction API

Le endpoint `POST /tenant-context/create-signup` extrait `marketing_owner_tenant_id` depuis **deux sources** :

1. **Top-level body** : `const marketingOwnerTenantId = body.marketing_owner_tenant_id || null;` — utilisé pour `tenants.marketing_owner_tenant_id`
2. **INSERT signup_attribution** : `$19 = marketingOwnerTenantId` (la variable top-level, pas `attribution.marketing_owner_tenant_id`)

Le client envoie correctement le champ au top-level du POST body.

---

## 4. Audit Website (keybuzz.pro)

### Forwarding `/pricing` → `/register`

**Fichier** : `keybuzz-website/src/app/pricing/page.tsx` (ligne 275)

```javascript
const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid", "ttclid"];
```

**GAP IDENTIFIÉ** : `marketing_owner_tenant_id`, `li_fat_id` et `_gl` ne sont **PAS** dans la liste de forwarding.

### Impact

- Un utilisateur arrivant sur `keybuzz.pro/pricing?...&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk` puis cliquant le CTA plan → l'URL `/register` **ne contiendra pas** `marketing_owner_tenant_id`
- L'attribution owner-scoped sera perdue via ce chemin

### Contournement documenté

Le playbook Admin recommande d'utiliser directement `client.keybuzz.io/register?...` avec tous les paramètres en attendant le fix website.

### Recommandation

Créer un ticket website P2 pour ajouter `marketing_owner_tenant_id`, `li_fat_id` et `_gl` à `utmKeys`.

---

## 5. Patch Admin Playbook

### Fichier modifié

`keybuzz-admin-v2/src/app/(admin)/marketing/acquisition-playbook/page.tsx`

### Changements (16 insertions, 4 suppressions)

1. **Encart owner-aware** : ajout d'un bloc violet expliquant le rôle de `marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk`
2. **4 URLs de campagne** : ajout de `&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk` aux URLs Meta, Google, TikTok et LinkedIn
3. **Checklist** : ajout de l'item `marketing_owner_tenant_id` présent dans l'URL
4. **Résumé opérationnel** :
   - "Prêt" : ajout de "Attribution owner-scoped via marketing_owner_tenant_id"
   - "Pas encore prêt" : ajout de la note sur le forwarding website avec contournement

### Vérifications

- Zero `codex` ✅
- `utm_source=meta` (pas `facebook`) ✅
- Pas de tag `AW-` direct ✅ (seule référence = texte d'instruction "Ne pas installer")
- Pas de secret exposé ✅

---

## 6. Build & Deploy

### Admin DEV

| Élément | Valeur |
|---------|--------|
| Source commit | `7296872` |
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.31-owner-aware-playbook-dev` |
| Digest | `sha256:f9d7058284fa13942d3d217c6bf2d9ec7869284807812e37bed56502a8b1a475` |
| Build | clone temporaire, `docker build --no-cache` |
| Deploy | `kubectl apply -f` (GitOps strict) |
| Rollout | success, 0 restarts |

### Admin PROD

| Élément | Valeur |
|---------|--------|
| Source commit | `7296872` |
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.31-owner-aware-playbook-prod` |
| Digest | `sha256:5ffcd2fe662405f711d5e797f9be1827350f18ed56f94b9c81328a5bfc719c8c` |
| Build | clone temporaire, `docker build --no-cache --build-arg NEXT_PUBLIC_APP_ENV=production --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |
| Deploy | `kubectl apply -f` (GitOps strict) |
| Rollout | success, 0 restarts |

---

## 7. Validation PROD

### Admin Playbook Bundle

| Check | Résultat |
|-------|----------|
| `marketing_owner_tenant_id` dans le bundle | 1 occurrence ✅ |
| `keybuzz-consulting-mo9zndlk` dans le bundle | 1 occurrence ✅ |
| `codex` | 0 ✅ |
| `utm_source=facebook` | 0 ✅ |

### Client Register Bundle

| Check | Résultat |
|-------|----------|
| `marketing_owner_tenant_id` dans register page | 1 occurrence ✅ |

### Services PROD

| Service | Status | Restarts |
|---------|--------|----------|
| keybuzz-api | Running, ready | 0 |
| keybuzz-outbound-worker | Running, ready | 7 (pré-existant) |
| keybuzz-client | Running, ready | 0 |
| keybuzz-admin-v2 | Running, ready | 0 |

### DB PROD — signup_attribution

Total : **10 lignes** | Avec `marketing_owner_tenant_id` : **3 lignes**

Les 3 lignes avec owner (toutes `keybuzz-consulting-mo9zndlk`) :
- `test-owner-runtime-prod@keybuzz.io` (24 avr, cursor-validation)
- `ludovic+gclidprodcodex250425b@keybuzz.pro` (25 avr, google)
- `romruais+codex-test@gmail.com` (25 avr, google)

---

## 8. GitOps Commits

| Repo | Commit | Message |
|------|--------|---------|
| `keybuzz-admin-v2` | `7296872` | PH-T8.11AJ: owner-aware playbook — add marketing_owner_tenant_id to campaign URLs and checklist (KEY-222) |
| `keybuzz-infra` | `2e59486` | PH-T8.11AJ: GitOps — Admin v2.11.31 owner-aware playbook DEV+PROD, Client v3.5.125 manifest alignment (KEY-222) |

---

## 9. Rollback GitOps

### Admin DEV

```bash
# Manifest: k8s/keybuzz-admin-v2-dev/deployment.yaml
# Rollback image: v2.11.30-marketing-menu-truth-cleanup-dev
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml  # après avoir restauré l'image
```

### Admin PROD

```bash
# Manifest: k8s/keybuzz-admin-v2-prod/deployment.yaml
# Rollback image: v2.11.23-marketing-menu-truth-cleanup-prod
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml  # après avoir restauré l'image
```

---

## 10. Linear

| Ticket | Action | Status |
|--------|--------|--------|
| **KEY-222** | Client + Playbook + DB validation OK en PROD | **Done** |
| **KEY-217** | NE PAS fermer — activation Google Ads `signup_complete` toujours requise manuellement | Ouvert |
| **Nouveau** | Website forwarding `marketing_owner_tenant_id` — P2 | À créer |
| **Nouveau (opt)** | Delivery Logs info banner Google absent (by design) — P3 | Optionnel |

---

## 11. Non-régression

| Vérification | Résultat |
|-------------|----------|
| API PROD pods stable | ✅ 0 restarts |
| Client PROD pods stable | ✅ 0 restarts |
| Admin PROD pods stable | ✅ 0 restarts |
| Aucun tag AW direct | ✅ |
| Aucun secret exposé | ✅ |
| `codex` absent | ✅ |
| `utm_source=meta` correct | ✅ |
| DB données historiques intactes | ✅ (10 lignes, 3 avec owner) |
| Meta/TikTok/LinkedIn/Google spend non régressés | ✅ (services inchangés) |

---

## 12. Images PROD finales

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.123-linkedin-capi-native-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.125-register-console-cleanup-prod` |
| Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.31-owner-aware-playbook-prod` |

---

## VERDICT

**OWNER-AWARE ATTRIBUTION CLOSED — MARKETING_OWNER_TENANT_ID CAPTURED BY CLIENT — KEYBUZZ CONSULTING CAMPAIGN URLS DOCUMENTED — DB SIGNUP ATTRIBUTION OWNER-SCOPED — NO TRACKING DRIFT — NO AW DIRECT TAG**

- Client code (PH-T8.10B, commit `6d5a796`) **déjà déployé en PROD** (`v3.5.125`) — capture `marketing_owner_tenant_id` et `li_fat_id` depuis les URL params, envoie au top-level du POST body.
- Admin Playbook mis à jour avec les 4 URLs owner-aware + encart explicatif + checklist item.
- Website keybuzz.pro ne forwarde **PAS** `marketing_owner_tenant_id` — gap documenté, contournement via liens directs `/register`, ticket website P2 recommandé.
- DB PROD contient 3 lignes `signup_attribution` avec `marketing_owner_tenant_id = keybuzz-consulting-mo9zndlk`.
- Aucune modification API. Aucun tag AW direct. Aucun secret exposé.
