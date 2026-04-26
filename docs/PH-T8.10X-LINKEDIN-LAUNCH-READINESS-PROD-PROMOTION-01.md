# PH-T8.10X-LINKEDIN-LAUNCH-READINESS-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO**

## KEY

**KEY-188** — promouvoir en PROD le minimum LinkedIn utile au lancement KeyBuzz, sans prétendre qu'on a déjà une boucle conversion LinkedIn complète.

---

## Préflight

| Point | Valeur |
|---|---|
| Client branche | `ph148/onboarding-activation-replay` |
| Client HEAD | `ce23377` — PH-T8.10W li_fat_id |
| Client clean | Oui |
| API branche | `ph147.4/source-of-truth` |
| API HEAD | `4941379a` — PH-T8.10W li_fat_id persist |
| API clean | Oui |
| Client PROD avant | `v3.5.116-marketing-owner-stack-prod` |
| API PROD avant | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Client DEV (validé PH-T8.10W) | `v3.5.120-linkedin-launch-readiness-dev` |
| API DEV (validé PH-T8.10W) | `v3.5.120-linkedin-launch-readiness-dev` |
| Admin PROD | Inchangé |

---

## Source vérifiée

| Point | Attendu | Résultat |
|---|---|---|
| `li_fat_id` dans `AttributionContext` | champ `string \| null` | **OK** — ligne 32 |
| `li_fat_id` dans `CLICK_ID_PARAMS` | inclus | **OK** — ligne 62 |
| `li_fat_id` dans `captureAttribution()` | `get('li_fat_id')` | **OK** — ligne 125 |
| `li_fat_id` dans `hasSignals()` | condition | **OK** — ligne 152 |
| `li_fat_id` dans fallback | `null` | **OK** — ligne 302 |
| Insight Tag conditionnel | `LINKEDIN_PARTNER_ID` gate | **OK** — SaaSAnalytics.tsx:140 |
| Dockerfile build-arg | `ARG NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | **OK** — ligne 17 |
| API INSERT `li_fat_id` | colonne + valeur | **OK** — lignes 713, 734 |
| API SELECT billing | `li_fat_id` | **OK** — ligne 1885 |
| Owner-aware intact | `marketing_owner_tenant_id` unchanged | **OK** |

---

## Build PROD

| Service | Tag | Commit | Branch | Digest |
|---|---|---|---|---|
| API | `v3.5.120-linkedin-launch-readiness-prod` | `4941379a` | `ph147.4/source-of-truth` | `sha256:3a160320894f23d4dbdec828b73f719ddc57bab5ebb40b687dbe3fdccf8d1620` |
| Client | `v3.5.120-linkedin-launch-readiness-prod` | `ce23377` | `ph148/onboarding-activation-replay` | `sha256:51515a17028a899f32dd44999213672039962dab38ab587e62e9e49059db9d4a` |

Build-args Client PROD :
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=production`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-0YV7HTJGPC`
- `NEXT_PUBLIC_META_PIXEL_ID=1343212073411990`
- `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.io`
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=CT7F5ABC4C3LSJ57LQOG`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`

---

## GitOps PROD

### Manifests modifiés

| Manifest | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` | `v3.5.120-linkedin-launch-readiness-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.116-marketing-owner-stack-prod` | `v3.5.120-linkedin-launch-readiness-prod` |

### DB migration PROD

```sql
ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS li_fat_id TEXT;
```

Exécutée via `sudo -u postgres psql keybuzz_prod` sur `db-postgres-01` (10.0.0.120) — additive, nullable, zero downtime.

### Rollback PROD

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod -n keybuzz-api-prod

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.116-marketing-owner-stack-prod -n keybuzz-client-prod
```

Note : la colonne `li_fat_id` en DB est additive et nullable — pas de rollback DB nécessaire.

---

## Déploiement PROD

| Point | Valeur |
|---|---|
| API rollout | `deployment "keybuzz-api" successfully rolled out` |
| Client rollout | `deployment "keybuzz-client" successfully rolled out` |
| API pod | `keybuzz-api-5f96d99c7-zklbd` — Running (k8s-worker-01) |
| Client pod | `keybuzz-client-6c9d846d75-4lkfn` — Running (k8s-worker-02) |
| Restarts | 0 |
| API health | `{"status":"ok"}` |
| Client health | HTTP 200 |

---

## Validation runtime PROD

| Cas | Attendu | Résultat |
|---|---|---|
| **A — Insight Tag** | Partner ID `9969977` + `_linkedin_partner_id` + `li.lms-analytics` | **OK** — tous présents dans le layout chunk PROD |
| **A — li_fat_id capture** | `li_fat_id` dans le bundle attribution | **OK** — chunk 6654 |
| **B — API INSERT** | `li_fat_id` dans code PROD compilé | **OK** — 2 occurrences tenant-context-routes.js |
| **B — API SELECT** | `li_fat_id` dans billing PROD | **OK** — 1 occurrence billing/routes.js |
| **B — DB PROD** | `li_fat_id TEXT` | **OK** — colonne confirmée |
| **C — Google** | GA4 `G-0YV7HTJGPC` | **OK** |
| **C — Meta** | Pixel `1343212073411990` | **OK** |
| **C — TikTok** | Pixel `CT7F5ABC4C3LSJ57LQOG` | **OK** |
| **C — Owner-aware** | Logic intacte | **OK** |

---

## Preuves DB / runtime

| Champ | Valeur |
|---|---|
| DB `li_fat_id` colonne PROD | `TEXT` — existe |
| Rows PROD | 9 — toutes `li_fat_id: null` (aucun signup LinkedIn encore) |
| Owner PROD dans rows | `keybuzz-consulting-mo9zndlk` présent |
| API PROD image | `v3.5.120-linkedin-launch-readiness-prod` |
| Client PROD image | `v3.5.120-linkedin-launch-readiness-prod` |
| API PROD health | `{"status":"ok"}` |
| Client PROD | HTTP 200 |
| LinkedIn Insight Tag | `9969977` baked dans bundle PROD |
| `_linkedin_partner_id` | Présent dans layout chunk |
| `li.lms-analytics` | Présent dans layout chunk |
| `li_fat_id` capture | Présent dans attribution chunk |
| Google GA4 | `G-0YV7HTJGPC` — intact |
| Meta Pixel PROD | `1343212073411990` — intact |
| TikTok Pixel PROD | `CT7F5ABC4C3LSJ57LQOG` — intact |
| Note honnête | LinkedIn CAPI **non active** — seul l'Insight Tag browser est actif, pas de boucle conversion complète |

---

## Gaps restants

| # | Gap | Impact |
|---|---|---|
| 1 | CAPI LinkedIn non active (token absent, approbation LinkedIn requise) | Pas de conversion serveur-à-serveur |
| 2 | Tag sGTM LinkedIn non configuré dans Addingwell | Événements GA4 MP non forwarded vers LinkedIn |
| 3 | Pas d'observabilité LinkedIn dans l'Admin | Pas de visibilité spend/conversion LinkedIn |
| 4 | Pas de connecteur natif LinkedIn (handler générique webhook) | Adaptateur CAPI nécessaire pour intégration complète |
| 5 | KPI/spend multi-plateforme = KEY-190 (hors scope) | Dashboard multi-canal séparé |

---

## Conclusion

**Cas A — GO**

LinkedIn minimal readiness est maintenant live en PROD. Le lancement acquisition LinkedIn est possible avec un niveau de tracking raisonnable :

- **Insight Tag actif** — le browser tracker LinkedIn est chargé sur les pages funnel PROD
- **`li_fat_id` capturé** — le click ID LinkedIn est extrait des URL params et stocké dans le contexte attribution
- **`li_fat_id` persisté** — la colonne existe en PROD et l'INSERT/SELECT sont actifs
- **Owner-aware préservé** — le modèle `marketing_owner_tenant_id` fonctionne pour LinkedIn identiquement à Google/Meta/TikTok
- **4 plateformes coexistent** — Google GA4, Meta Pixel, TikTok Pixel, LinkedIn Insight Tag dans le même bundle sans interférence
- **Aucune fausse affirmation** — LinkedIn CAPI n'est PAS active, la boucle conversion complète reste un gap documenté

---

## Admin PROD inchangé

**Oui** — aucune modification Admin dans cette phase.

---

## Rapport

`keybuzz-infra/docs/PH-T8.10X-LINKEDIN-LAUNCH-READINESS-PROD-PROMOTION-01.md`

---

**LINKEDIN MINIMAL LAUNCH READINESS LIVE IN PROD — INSIGHT TAG ACTIVE — LI_FAT_ID CAPTURED AND PERSISTED — OWNER-AWARE PRESERVED — NO FALSE CLAIM OF FULL LINKEDIN CAPI**
