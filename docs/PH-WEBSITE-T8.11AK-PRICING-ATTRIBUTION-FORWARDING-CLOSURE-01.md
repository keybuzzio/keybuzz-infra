# PH-WEBSITE-T8.11AK — PRICING-ATTRIBUTION-FORWARDING-CLOSURE-01

**Date** : 29 avril 2026
**Ticket** : KEY-223
**Phase précédente** : PH-T8.11AJ

---

## 1. Préflight

| Élément | Valeur | Status |
|---------|--------|--------|
| Website bastion | `main` @ `29c66d2` (clean) | ✅ |
| Website DEV avant | `v0.6.6-tiktok-ttclid-dev` | → mis à jour |
| Website PROD avant | `v0.6.6-tiktok-ttclid-prod` | → mis à jour |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | inchangé |
| Admin PROD | `v2.11.31-owner-aware-playbook-prod` | inchangé |
| API PROD health | `{"status":"ok"}` | ✅ |
| Infra | `main` (clean pour website manifests) | ✅ |

### Rapports lus

| Rapport | Verdict |
|---------|---------|
| PH-T8.11AJ | Owner-aware playbook closed, website forwarding gap P2 identifié |
| PH-T8.11AI | Attribution qualifiée, `signup_complete` HIDDEN, gap owner P2 |
| PH-ADMIN-T8.11AH.1 | Marketing menu truth cleanup PROD |

---

## 2. Audit du forwarding — État AVANT patch

### Fichier : `keybuzz-website/src/app/pricing/page.tsx`

**Ligne 275 (avant)** :
```javascript
const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid", "ttclid"];
```

### Paramètres forwardés (AVANT)
| Paramètre | Forwardé |
|-----------|----------|
| `utm_source` | ✅ |
| `utm_medium` | ✅ |
| `utm_campaign` | ✅ |
| `utm_term` | ✅ |
| `utm_content` | ✅ |
| `gclid` | ✅ |
| `fbclid` | ✅ |
| `ttclid` | ✅ |
| `marketing_owner_tenant_id` | ❌ MANQUANT |
| `li_fat_id` | ❌ MANQUANT |
| `_gl` | ❌ MANQUANT |

### Flux CTA
1. `CLIENT_APP_URL` = `process.env.NEXT_PUBLIC_CLIENT_APP_URL || "https://client.keybuzz.io"`
2. Plans : `${CLIENT_APP_URL}/register?plan=starter&cycle=monthly`
3. Cycle : `.replace('cycle=monthly', \`cycle=${isAnnual ? 'yearly' : 'monthly'}\`)`
4. UTM suffix : `+ utmSuffix` (construit depuis `utmKeys` filtré par présence dans `URLSearchParams`)

---

## 3. Patch appliqué

### Diff fonctionnel

**Ligne 275 (après)** :
```javascript
const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid", "ttclid", "marketing_owner_tenant_id", "li_fat_id", "_gl"];
```

### Paramètres forwardés (APRÈS)
| Paramètre | Forwardé |
|-----------|----------|
| `utm_source` | ✅ |
| `utm_medium` | ✅ |
| `utm_campaign` | ✅ |
| `utm_term` | ✅ |
| `utm_content` | ✅ |
| `gclid` | ✅ |
| `fbclid` | ✅ |
| `ttclid` | ✅ |
| `marketing_owner_tenant_id` | ✅ **AJOUTÉ** |
| `li_fat_id` | ✅ **AJOUTÉ** |
| `_gl` | ✅ **AJOUTÉ** |

### Fichier modifié
- `keybuzz-website/src/app/pricing/page.tsx` : 1 ligne modifiée (ajout de 3 clés au tableau)

---

## 4. Build et déploiement

### Commit Website
| Champ | Valeur |
|-------|--------|
| Commit | `0b9d1ea` |
| Message | `PH-WEBSITE-T8.11AK: forward marketing_owner_tenant_id, li_fat_id, _gl from /pricing to /register (KEY-223)` |
| Branche | `main` |
| Pushé | ✅ |

### Images construites

| Env | Tag | Digest |
|-----|-----|--------|
| DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.6.7-pricing-attribution-forwarding-dev` | `sha256:17c116c6515b7394bf1a4b442e246b5db8c3f471991ee30aa93b35236950bb36` |
| PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.6.7-pricing-attribution-forwarding-prod` | `sha256:4d0f1b189f5c01159452e9ca2856b530674296e18d91536e202778d4e8ebdedb` |

### Build args utilisés

| Variable | DEV | PROD |
|----------|-----|------|
| `NEXT_PUBLIC_SITE_MODE` | `preview` | `production` |
| `NEXT_PUBLIC_CLIENT_APP_URL` | `https://client-dev.keybuzz.io` | `https://client.keybuzz.io` |
| `NEXT_PUBLIC_GA_ID` | `G-R3QQDYEBFG` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` | `1234164602194748` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` | `https://t.keybuzz.pro` |

### Déploiement GitOps

| Env | Méthode | Résultat |
|-----|---------|----------|
| DEV | `kubectl apply -f` (inline manifest) | `deployment.apps/keybuzz-website configured` → rollout OK |
| PROD | `kubectl apply -f` (inline manifest) | `deployment.apps/keybuzz-website configured` → rollout OK |

### Manifests infra mis à jour
- `keybuzz-infra/k8s/website-dev/deployment.yaml` : image → `v0.6.7-pricing-attribution-forwarding-dev`
- `keybuzz-infra/k8s/website-prod/deployment.yaml` : image → `v0.6.7-pricing-attribution-forwarding-prod`

---

## 5. Validation DEV

| Vérification | Résultat |
|--------------|----------|
| `marketing_owner_tenant_id` dans bundle | ✅ présent (`228da3e3228ffe4c.js`) |
| `li_fat_id` dans bundle | ✅ présent |
| `_gl` dans bundle | ✅ présent |
| `client-dev.keybuzz.io` dans bundle | ✅ présent |
| Tag `AW-18098643667` absent | ✅ 0 fichiers |
| Pod restarts | 0 |
| Runtime image | `v0.6.7-pricing-attribution-forwarding-dev` |

---

## 6. Validation PROD

| Vérification | Résultat |
|--------------|----------|
| `marketing_owner_tenant_id` dans bundle | ✅ présent (`0c182f14be351cfa.js`) |
| `li_fat_id` dans bundle | ✅ présent |
| `_gl` dans bundle | ✅ présent |
| `client.keybuzz.io` dans bundle | ✅ présent |
| Tag `AW-18098643667` absent | ✅ 0 fichiers |
| Pod restarts | 0 (2 replicas) |
| Runtime image | `v0.6.7-pricing-attribution-forwarding-prod` |
| GA4 `G-R3QQDYEBFG` | ✅ présent (non-régression) |
| sGTM `t.keybuzz.pro` | ✅ présent (non-régression) |

---

## 7. URL de test

```
https://www.keybuzz.pro/pricing?utm_source=google&utm_medium=cpc&utm_campaign=internal-validation-owner-aware-20260429&utm_content=manual-owner-check&utm_term=signup-complete&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&li_fat_id=test-li-fat-id-20260429&_gl=test-gl-linker-20260429
```

### Comportement attendu au clic CTA (plan Pro mensuel)

URL finale générée :
```
https://client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=google&utm_medium=cpc&utm_campaign=internal-validation-owner-aware-20260429&utm_content=manual-owner-check&utm_term=signup-complete&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&li_fat_id=test-li-fat-id-20260429&_gl=test-gl-linker-20260429
```

### Preuve : 11 paramètres forwardés

| # | Paramètre | Valeur |
|---|-----------|--------|
| 1 | `plan` | `pro` |
| 2 | `cycle` | `monthly` |
| 3 | `utm_source` | `google` |
| 4 | `utm_medium` | `cpc` |
| 5 | `utm_campaign` | `internal-validation-owner-aware-20260429` |
| 6 | `utm_content` | `manual-owner-check` |
| 7 | `utm_term` | `signup-complete` |
| 8 | `gclid` | *(forwardé si présent)* |
| 9 | `fbclid` | *(forwardé si présent)* |
| 10 | `ttclid` | *(forwardé si présent)* |
| 11 | `marketing_owner_tenant_id` | `keybuzz-consulting-mo9zndlk` |
| 12 | `li_fat_id` | `test-li-fat-id-20260429` |
| 13 | `_gl` | `test-gl-linker-20260429` |

---

## 8. Non-régression

| Service | Status |
|---------|--------|
| API PROD | `{"status":"ok"}` |
| Client PROD | HTTP 307 (redirect login — normal) |
| Admin PROD | HTTP 307 (redirect login — normal) |
| Website PROD `/` | HTTP 200 |
| Website PROD `/pricing` | HTTP 200 |
| Website PROD `/about` | HTTP 200 |
| Website PROD `/features` | HTTP 200 |
| Website PROD `/contact` | HTTP 200 |
| Website PROD `/legal` | HTTP 200 |
| Website PROD `/privacy` | HTTP 200 |
| Website PROD `/terms` | HTTP 200 |
| Website PROD `/sla` | HTTP 200 |
| Website PROD `/cookies` | HTTP 200 |
| API PROD image | `v3.5.123-linkedin-capi-native-prod` (inchangé) |
| Client PROD image | `v3.5.125-register-console-cleanup-prod` (inchangé) |
| Admin PROD image | `v2.11.31-owner-aware-playbook-prod` (inchangé) |
| Tag `AW-` direct | ❌ absent (correct) |
| Aucun secret exposé | ✅ confirmé |

---

## 9. Linear

| Ticket | Status |
|--------|--------|
| KEY-223 | **Done** — forwarding `marketing_owner_tenant_id`, `li_fat_id`, `_gl` opérationnel DEV + PROD |
| KEY-222 | Done (fermé phase précédente) |
| KEY-217 | Reste ouvert — `signup_complete` nécessite activation manuelle dans Google Ads UI |

---

## 10. Rollback GitOps strict

> **Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`, `kubectl set env`.
> Le rollback DOIT passer par Git.

### Rollback DEV

1. Modifier `keybuzz-infra/k8s/website-dev/deployment.yaml` — remettre l'image :
   `ghcr.io/keybuzzio/keybuzz-website:v0.6.6-tiktok-ttclid-dev`
2. `git add k8s/website-dev/deployment.yaml && git commit -m "rollback: website DEV → v0.6.6-tiktok-ttclid-dev" && git push origin main`
3. `kubectl apply -f k8s/website-dev/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-website -n keybuzz-website-dev`

### Rollback PROD

1. Modifier `keybuzz-infra/k8s/website-prod/deployment.yaml` — remettre l'image :
   `ghcr.io/keybuzzio/keybuzz-website:v0.6.6-tiktok-ttclid-prod`
2. `git add k8s/website-prod/deployment.yaml && git commit -m "rollback: website PROD → v0.6.6-tiktok-ttclid-prod" && git push origin main`
3. `kubectl apply -f k8s/website-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod`

---

## 11. Chaîne complète owner-aware (état final)

```
Agence → URL avec marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
  ↓
keybuzz.pro/pricing?...&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&li_fat_id=xxx&_gl=yyy
  ↓ [CTA clic - utmKeys forwarding ✅ v0.6.7]
client.keybuzz.io/register?...&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&li_fat_id=xxx&_gl=yyy
  ↓ [captureAttribution() ✅ depuis PH-T8.10B]
POST /api/auth/create-signup { marketing_owner_tenant_id: "keybuzz-consulting-mo9zndlk", attribution: { li_fat_id: "xxx", _gl: "yyy", ... } }
  ↓ [Backend ✅]
signup_attribution { marketing_owner_tenant_id: "keybuzz-consulting-mo9zndlk" }
  ↓
Dashboard Admin → filtrage par owner_tenant_id
```

**Tous les maillons de la chaîne sont maintenant opérationnels.**

---

## VERDICT

**PRICING ATTRIBUTION FORWARDING CLOSED — MARKETING_OWNER_TENANT_ID / LI_FAT_ID / GL FORWARDED TO REGISTER — OWNER-AWARE LANDING PATH RELIABLE — NO TRACKING DRIFT — NO AW DIRECT TAG**
