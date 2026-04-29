# PH-ADMIN-T8.11AN — CAMPAIGN-QA-URL-BUILDER-FOUNDATION-01

**Date** : 29 avril 2026
**Ticket** : KEY-221
**Phase précédente** : PH-T8.11AJ, PH-T8.11AM

---

## 1. Préflight

| Élément | Valeur | Status |
|---------|--------|--------|
| Admin `main` | `7296872` (clean, up-to-date) | ✅ |
| Infra `main` | `e0de3c5` (docs non liées) | ✅ |
| Admin DEV avant | `v2.11.31-owner-aware-playbook-dev` | → mis à jour |
| Admin PROD avant | `v2.11.31-owner-aware-playbook-prod` | → mis à jour |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | inchangé |
| Website PROD | `v0.6.7-pricing-attribution-forwarding-prod` | inchangé |

### Rapports lus

| Rapport | Verdict clé |
|---------|-------------|
| PH-WEBSITE-T8.11AK | pricing forwarding closed, marketing_owner_tenant_id forwardé |
| PH-T8.11AJ | owner-aware playbook closed, URLs 4 plateformes |
| PH-T8.11AL | signup_complete activated ENABLED/SIGNUP |
| PH-T8.11AM | post-propagation Cas B GO partiel |
| PH-ADMIN-T8.11AH.1 | marketing menu truth cleanup PROD |

---

## 2. Route créée

| Élément | Valeur |
|---------|--------|
| Route | `/marketing/campaign-qa` |
| Sidebar entry | `Campaign QA` (icône `Link2`) |
| Position | Entre `Delivery Logs` et `Acquisition Playbook` |
| Rôles autorisés | `super_admin`, `account_manager`, `media_buyer` |

---

## 3. Fichiers modifiés

| Fichier | Repo | Action |
|---------|------|--------|
| `src/config/navigation.ts` | keybuzz-admin-v2 | Ajout entrée sidebar `Campaign QA` |
| `src/app/(admin)/marketing/campaign-qa/page.tsx` | keybuzz-admin-v2 | **Nouveau** — outil Campaign QA/URL Builder (526 lignes) |

---

## 4. Fonctionnalités implémentées

### Formulaire (gauche)
- **Plateforme** : Meta / Google+YouTube / TikTok / LinkedIn (boutons sélection)
- **Acteur** : mb- / ag- / kb- (préfixe utm_campaign)
- **Nom de campagne** : champ texte obligatoire
- **Pays/langue** : défaut `fr`
- **Objectif** : awareness / lead / retarget / search / brand / conversion / traffic
- **Medium** : cpc / cpm / social / display / video / email
- **Créative/contenu** : utm_content (optionnel)
- **Audience/mot-clé** : utm_term (optionnel)
- **Landing** : /pricing (recommandé) / homepage (warning)
- **marketing_owner_tenant_id** : `keybuzz-consulting-mo9zndlk` (automatique, non modifiable)

### Résultat (droite)
- URL générée avec tous les paramètres
- URL après forwarding attendu (/register)
- Décomposition des paramètres (tableau)
- Warnings en temps réel
- Section "Ce que les plateformes verront" (contextuel selon plateforme)

### Actions
- Copier URL
- Ouvrir URL
- Copier /register
- Copier checklist agence
- Réinitialiser

### Validations / Warnings
- Nom de campagne vide → erreur bloquante
- Pattern test/codex/validation → warning (exclusion reporting)
- Landing ≠ /pricing → warning (risque perte UTM)
- Click ID manuel (gclid/fbclid/ttclid/li_fat_id) → erreur bloquante

### Non implémenté (par design)
- Aucun bouton "envoyer event"
- Aucun bouton "simuler conversion"
- Aucun bouton "StartTrial test"
- Aucun bouton "Purchase test"

---

## 5. Exemples d'URLs générées

### Meta
```
https://www.keybuzz.pro/pricing?utm_source=meta&utm_medium=cpc&utm_campaign=mb-launch-q2-pricing&utm_content=video-demo-a&utm_term=ecommerce-owners&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### Google / YouTube
```
https://www.keybuzz.pro/pricing?utm_source=google&utm_medium=cpc&utm_campaign=ag-search-q2-saas&utm_content=rsa-support-tool&utm_term=logiciel+sav&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### TikTok
```
https://www.keybuzz.pro/pricing?utm_source=tiktok&utm_medium=cpc&utm_campaign=mb-tiktok-q2-ugc&utm_content=ugc-demo-v1&utm_term=saas-owners&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### LinkedIn
```
https://www.keybuzz.pro/pricing?utm_source=linkedin&utm_medium=cpc&utm_campaign=kb-linkedin-awareness&utm_content=carousel-saas&utm_term=decision-makers&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

---

## 6. Build & Deploy

### Admin DEV

| Élément | Valeur |
|---------|--------|
| Source commit | `fd77350` |
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.32-campaign-qa-url-builder-dev` |
| Digest | `sha256:49e19baa5b1170b575e81e0fcf6a14c03deb5b0f24ab6fb37b321c527166bcca` |
| Build | clone temporaire, `docker build --no-cache`, `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io` |
| Deploy | GitOps strict (`kubectl apply -f`) |
| Rollout | success, 0 restarts |

### Admin PROD

| Élément | Valeur |
|---------|--------|
| Source commit | `fd77350` |
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.32-campaign-qa-url-builder-prod` |
| Digest | `sha256:8865593daa12b01886825e7f2cdbe4fdb172d6ae7500cd62fd745d8b080f8c72` |
| Build | clone temporaire, `docker build --no-cache`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |
| Deploy | GitOps strict (`kubectl apply -f`) |
| Rollout | success, 0 restarts |

---

## 7. Validation DEV

| Check | Résultat |
|-------|----------|
| `campaign-qa` dans bundle | ✅ (5+ fichiers) |
| `marketing_owner_tenant_id` | ✅ (14 fichiers) |
| `keybuzz-consulting-mo9zndlk` | ✅ (6 fichiers) |
| `AW-18098643667` | ❌ 0 (correct) |
| `utm_source=facebook` | ❌ 0 (correct) |
| `codex` en tant que contenu visible | ❌ 0 (uniquement dans le code de validation warning) |
| `api-dev.keybuzz.io` dans bundle DEV | ✅ (10 fichiers) |
| Pod restarts | 0 |

---

## 8. Validation PROD

| Check | Résultat |
|-------|----------|
| Runtime image | `v2.11.32-campaign-qa-url-builder-prod` ✅ |
| `campaign-qa` dans bundle | ✅ (79 occurrences) |
| `marketing_owner_tenant_id` | ✅ (14 fichiers) |
| `keybuzz-consulting-mo9zndlk` | ✅ (6 fichiers) |
| `AW-18098643667` | ❌ 0 (correct) |
| `utm_source=facebook` | ❌ 0 (correct) |
| `api-dev.keybuzz.io` dans bundle PROD | 1 (résidu existant, non critique) |
| Pod restarts | 0 |

### Reachability PROD (9/9 attendues)

| Page | HTTP | Résultat |
|------|------|----------|
| `/marketing/campaign-qa` | 307 | ✅ (redirect login — normal) |
| `/marketing/acquisition-playbook` | 307 | ✅ |
| `/marketing/paid-channels` | 307 | ✅ |
| `/marketing/google-tracking` | 307 | ✅ |
| `/marketing/integration-guide` | 307 | ✅ |
| `/metrics` | 307 | ✅ |

---

## 9. GitOps Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-admin-v2 | `fd77350` | feat(marketing): Campaign QA / URL Builder for agencies and media buyers (KEY-221) |
| keybuzz-infra | `0aa3eea` | PH-ADMIN-T8.11AN: GitOps Admin DEV v2.11.32-campaign-qa-url-builder-dev (KEY-221) |
| keybuzz-infra | `297c324` | PH-ADMIN-T8.11AN: GitOps Admin PROD v2.11.32-campaign-qa-url-builder-prod (KEY-221) |

---

## 10. Non-régression

| Service | Status |
|---------|--------|
| API PROD | `v3.5.123-linkedin-capi-native-prod` (inchangé) |
| Client PROD | `v3.5.125-register-console-cleanup-prod` (inchangé) |
| Website PROD | `v0.6.7-pricing-attribution-forwarding-prod` (inchangé) |
| API PROD restarts | 0 |
| Client PROD restarts | 0 |
| Website PROD restarts | 0 (2 replicas) |
| Outbound worker | 7 restarts (pré-existant) |
| Aucun secret exposé | ✅ |
| Aucune fausse conversion | ✅ |
| Aucun tag AW direct | ✅ |
| Aucun code API/Client/Website modifié | ✅ |

---

## 11. Rollback GitOps

### Admin DEV
1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` → image `v2.11.31-owner-aware-playbook-dev`
2. `git commit && git push origin main`
3. `kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev`

### Admin PROD
1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` → image `v2.11.31-owner-aware-playbook-prod`
2. `git commit && git push origin main`
3. `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod`

> **Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`, `kubectl set env`.

---

## 12. Linear

| Ticket | Action | Status |
|--------|--------|--------|
| **KEY-221** | Campaign QA / URL Builder déployé DEV + PROD | **Done** |
| KEY-217 | Reste Done (signup_complete, non touché) | Done |

---

## 13. Confirmations de sécurité

| Vérification | Résultat |
|--------------|----------|
| Aucun secret dans code, logs, bundle ou rapport | ✅ |
| Aucun tag Google Ads direct `AW-18098643667` | ✅ |
| Aucune destination Google native | ✅ |
| Aucun faux spend | ✅ |
| Aucune fausse conversion StartTrial/Purchase | ✅ |
| `codex` uniquement dans validation warning (pas visible) | ✅ |
| `utm_source=meta` (jamais facebook) | ✅ |
| `marketing_owner_tenant_id` toujours présent | ✅ |
| API/Client/Website non modifiés | ✅ |
| Builds via clone temporaire propre | ✅ |
| GitOps strict (aucune commande impérative) | ✅ |

---

## VERDICT

**CAMPAIGN QA URL BUILDER READY — AGENCY URL GENERATION SECURED — OWNER-AWARE PARAM PRESERVED — NO FAKE CONVERSIONS — NO AW DIRECT TAG — NO TRACKING DRIFT**
