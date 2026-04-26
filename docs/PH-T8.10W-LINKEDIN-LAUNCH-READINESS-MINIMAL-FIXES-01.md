# PH-T8.10W-LINKEDIN-LAUNCH-READINESS-MINIMAL-FIXES-01 — TERMINÉ

**Verdict : GO**

## KEY

**KEY-188** — rendre LinkedIn assez prêt pour le lancement KeyBuzz sans prétendre qu'on a déjà une boucle conversion complète.

---

## Préflight

| Point | Valeur |
|---|---|
| Client branche | `ph148/onboarding-activation-replay` |
| Client HEAD avant | `6d5a796` (PH-T8.10B) |
| Client clean | Oui |
| API branche | `ph147.4/source-of-truth` |
| API HEAD avant | `6e0dac5e` (google-observability) |
| API clean | Oui |
| Client DEV avant | `v3.5.112-marketing-owner-mapping-foundation-dev` |
| API DEV avant | `v3.5.119-google-observability-dev` |
| PROD | Inchangée |

---

## Audit exact du changement minimal

### Client (`keybuzz-client`)

| Sujet | Emplacement | Changement |
|---|---|---|
| `AttributionContext` interface | `src/lib/attribution.ts:32` | Ajout `li_fat_id: string \| null` |
| `CLICK_ID_PARAMS` | `src/lib/attribution.ts:62` | `['gclid', 'fbclid', 'ttclid', 'li_fat_id']` |
| `captureAttribution()` | `src/lib/attribution.ts:125` | `li_fat_id: get('li_fat_id')` |
| `hasSignals()` | `src/lib/attribution.ts:152` | `ctx.li_fat_id` ajouté à la condition |
| Fallback minimal | `src/lib/attribution.ts:302` | `li_fat_id: null` |
| Insight Tag | `src/components/tracking/SaaSAnalytics.tsx` | Déjà en code, activé par build-arg |
| Dockerfile | `Dockerfile:17` | `ARG NEXT_PUBLIC_LINKEDIN_PARTNER_ID=` (existant) |

### API (`keybuzz-api`)

| Sujet | Emplacement | Changement |
|---|---|---|
| DB migration | `signup_attribution` | `ALTER TABLE signup_attribution ADD COLUMN li_fat_id TEXT` |
| INSERT | `tenant-context-routes.ts:713` | Colonne #20 `li_fat_id` + `$20` + valeur |
| SELECT billing | `billing/routes.ts:1885` | `li_fat_id` ajouté au SELECT |

---

## Design retenu

| Point | Décision |
|---|---|
| Capture `li_fat_id` | 5 micro-patches dans `attribution.ts` — même pattern que `gclid`/`fbclid`/`ttclid` |
| Persistance DB | `ALTER TABLE ADD COLUMN li_fat_id TEXT` — additive, nullable, zero downtime |
| Impact owner-aware | Zéro — `marketing_owner_tenant_id` reste inchangé |
| Activation Insight Tag | Build-arg `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977` |
| CAPI LinkedIn | Non implémenté — hors scope, terrain préparé |
| Backward compat | Oui — colonne nullable, champ optionnel |

---

## Patch Client

**Commit** : `ce23377` — `PH-T8.10W: add li_fat_id to attribution capture for LinkedIn launch readiness (KEY-188)`

**Diff** : 5 insertions, 3 suppressions dans `src/lib/attribution.ts`

Changements :
1. Interface `AttributionContext` : +`li_fat_id: string | null`
2. `CLICK_ID_PARAMS` : +`'li_fat_id'`
3. `captureAttribution()` : +`li_fat_id: get('li_fat_id')`
4. `hasSignals()` : +`ctx.li_fat_id`
5. Fallback minimal : +`li_fat_id: null`

---

## Patch API

**Commit** : `4941379a` — `PH-T8.10W: persist li_fat_id in signup_attribution for LinkedIn launch readiness (KEY-188)`

**Diff** : 4 insertions, 3 suppressions dans 2 fichiers

Changements :
1. `tenant-context-routes.ts` : INSERT `li_fat_id` colonne #20
2. `billing/routes.ts` : SELECT `li_fat_id` ajouté

**Migration DB** : `ALTER TABLE signup_attribution ADD COLUMN li_fat_id TEXT` — exécutée avec succès.

---

## Build DEV

| Service | Image | Digest |
|---|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.120-linkedin-launch-readiness-dev` | `sha256:840e68a6000ae759933db61128f169b6665346e43ef69414a55df6a0f538dc8d` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.120-linkedin-launch-readiness-dev` | `sha256:cb93d734590a35904934f58aff1497b7595cdd5b5041981fbed942a5cc62ee54` |

Build-args Client DEV :
- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=development`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-0YV7HTJGPC`
- `NEXT_PUBLIC_META_PIXEL_ID=651abortedfake`
- `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.io`
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=CT7Fabortfake`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`

---

## Validation DEV

| Cas | Attendu | Résultat |
|---|---|---|
| **A — Insight Tag** | Bundle contient Partner ID `9969977` + script `insight.min.js` | **OK** — `u="9969977"`, `_linkedin_partner_id`, `snap.licdn.com/li.lms-analytics/insight.min.js` |
| **A — li_fat_id capture** | `li_fat_id` dans CLICK_ID_PARAMS, captureAttribution, hasSignals | **OK** — `li_fat_id:r("li_fat_id")`, `o.li_fat_id` |
| **B — API INSERT** | `li_fat_id` dans INSERT SQL | **OK** — `tenant-context-routes.js:552` + `:572` |
| **B — API SELECT** | `li_fat_id` dans SELECT billing | **OK** — `billing/routes.js:1564` |
| **B — DB colonne** | `li_fat_id TEXT` dans signup_attribution | **OK** — 24ème colonne |
| **C — Google** | GA4 ID intact | **OK** — `G-0YV7HTJGPC` |
| **C — Meta** | Pixel ID intact | **OK** — `651abortedfake` |
| **C — TikTok** | Pixel ID intact | **OK** — `CT7Fabortfake` |
| **C — sGTM** | URL intacte | **OK** — `https://t.keybuzz.io` |
| **C — Owner-aware** | Aucune modification | **OK** |

---

## Preuves DB / runtime

| Champ | Valeur |
|---|---|
| DB `li_fat_id` colonne | `TEXT` — existe dans `signup_attribution` |
| Rows existantes | 10 — toutes `li_fat_id: null` (pas de signup LinkedIn encore) |
| Owner dans rows | `keybuzz-consulting-mo9y479d` présent |
| API DEV image | `v3.5.120-linkedin-launch-readiness-dev` |
| Client DEV image | `v3.5.120-linkedin-launch-readiness-dev` |
| API PROD | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` (inchangée) |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` (inchangée) |
| API health | `{"status":"ok"}` |
| Pod API | `keybuzz-api-544b87fc7-c7lqh` Running |
| Insight Tag | Partner ID `9969977` baked dans bundle JS |

---

## Gaps restants

| # | Gap | Impact |
|---|---|---|
| 1 | CAPI LinkedIn non active (token absent) | Pas de conversion serveur-à-serveur |
| 2 | Tag sGTM LinkedIn non configuré dans Addingwell | Événements GA4 MP non forwarded vers LinkedIn |
| 3 | Pas d'observabilité LinkedIn dans l'Admin | Pas de visibilité spend/conversion LinkedIn |
| 4 | Pas de connecteur natif LinkedIn (handler générique webhook) | Adaptateur CAPI nécessaire pour intégration complète |
| 5 | KPI/spend multi-plateforme = KEY-190 (hors scope) | Dashboard multi-canal séparé |
| 6 | `sha256_email_address` pas relayé vers LinkedIn via sGTM | Pas d'enrichissement user-match serveur |
| 7 | Pas de test signup réel avec `li_fat_id` | Prouvé par code review + schema, pas e2e |

---

## Rollback DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.119-google-observability-dev -n keybuzz-api-dev

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.112-marketing-owner-mapping-foundation-dev -n keybuzz-client-dev
```

Note : la colonne `li_fat_id` en DB est additive et nullable — elle ne nécessite pas de rollback.

---

## PROD inchangée

**Oui** — aucune modification PROD dans cette phase.

- API PROD : `v3.5.118-google-sgtm-owner-aware-quick-win-prod`
- Client PROD : `v3.5.116-marketing-owner-stack-prod`

---

## Conclusion

**LINKEDIN LAUNCH READINESS IMPROVED IN DEV — INSIGHT TAG ACTIVE — LI_FAT_ID CAPTURED AND PERSISTED — OWNER-AWARE FLOW PRESERVED — PROD UNTOUCHED**

Rapport : `keybuzz-infra/docs/PH-T8.10W-LINKEDIN-LAUNCH-READINESS-MINIMAL-FIXES-01.md`
