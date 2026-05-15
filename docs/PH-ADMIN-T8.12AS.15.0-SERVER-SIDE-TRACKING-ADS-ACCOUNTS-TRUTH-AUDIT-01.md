# PH-ADMIN-T8.12AS.15.0-SERVER-SIDE-TRACKING-ADS-ACCOUNTS-TRUTH-AUDIT-01

> Date : 2026-05-15
> Linear : KEY-322 (Open). KEY-301 Done. KEY-313 Done. KEY-314 Open (AS.14.2 pause).
> Phase : T8.12AS.15.0 (truth audit READ-ONLY)
> Environnement : DEV + PROD read-only (aucune mutation, aucun provider call, aucun token expose)

---

## 0. VERDICT

NO GO GOOGLE TOKEN RECOVERY REQUIRED.

Audit complet livre. Cause racine business confirmee : le refresh token Google Ads stocke en K8s secret `keybuzz-google-ads` est expire ou revoque depuis ~10-17 jours. Le dernier sync Google reussi est le 2026-04-28T20:50:06Z (jour de creation du compte). Depuis, toutes les tentatives de sync renvoient `GOOGLE_OAUTH_ERROR: 400 invalid_grant Token has been expired or revoked` -> Admin v2 affiche le bandeau d erreur observe par Ludovic. Aucune mutation n a ete declenchee par l audit.

Meta Ads fonctionne (dernier sync 2026-05-15T06:36, 0 erreur, spend 537.52 GBP cumule, 92.32 GBP sur 30j). TikTok + LinkedIn ne sont pas configures cote spend (`ad_platform_accounts` ne contient que Google + Meta) mais leurs destinations CAPI sont configurees et marquees actives ; en revanche, AUCUN delivery log dans les 7 derniers jours -> pipeline conversion emit casse ou simplement aucun event a delivrer. Attribution `fbclid` et `li_fat_id` jamais capturee en `signup_attribution` (Meta et LinkedIn click IDs absents sur 8 signups recents).

Plan d intervention propose en 10 sous-phases (P0-P3), avec AS.15.1 = emergency Google refresh token recovery (runbook manuel par Ludovic) comme priorite absolue.

KEY-322 reste Open. Aucun ticket Linear cree. Aucun token affiche. Aucun secret expose. Aucun event fake.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.15.0 truth audit READ-ONLY) :
- 0 mutation provider (Google, Meta, TikTok, LinkedIn, GA4)
- 0 refresh OAuth
- 0 token affiche
- 0 secret expose dans rapport ou Linear
- 0 event fake / metric fake / replay
- 0 build / docker push / kubectl apply / manifest edit
- 0 mutation DB
- 0 changement Linear statut
- 0 patch source

Actions effectuees :
- SSH read-only via install-v3 (46.62.171.61 confirme)
- git log read-only sur 6 repos
- kubectl get/logs/describe read-only
- DB SELECT read-only via kubectl exec dans le pod API PROD (aucun UPDATE/INSERT/DELETE)
- grep / find / cat sur fichiers source non-secrets
- Lecture AI_MEMORY (4 fichiers cles)

---

## 2. PREFLIGHT

### 2.1 SSH + bastion

| Champ | Valeur |
|---|---|
| Alias SSH | install-v3 |
| Hostname resolu | install-v3 |
| IP serveur | 46.62.171.61 (conforme) |
| IP interdites | 51.159.99.247 (NON CONTACTE) |
| Identity file | C:\Users\ludov\.ssh\id_rsa_keybuzz_v3 |

### 2.2 Repos / branches

| Repo | Branche reelle | Branche imposee | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 7a09c005 (AS.14.1) | dist/* (cache build hors source) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | idem | 3fe90ab (AS.14.1-FIX) | clean | OK |
| keybuzz-admin-v2 | main | main | 3707c83 (KEY-308 OCI) | clean | OK |
| keybuzz-backend | main | main | b183817 | amazon.routes.ts.bak untracked (left-over PH-SAAS-T8.12AO.2) | OK (hors scope) |
| keybuzz-infra | main | main | 9b7cd3b (AS.14.1-PROD rapport) | clean | OK |
| keybuzz-website | main | main | 660dc60 | clean | OK |

### 2.3 Runtime images

| Service | DEV | PROD |
|---|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-prod |
| keybuzz-client | v3.5.197-channels-bff-userauth-dev | v3.5.197-channels-bff-userauth-prod |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod |

Aucune divergence Git / runtime / manifest.

---

## 3. CHRONOLOGIE "LATEST-WINS"

### 3.1 Google Ads + OAuth

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-26 | PH-T8.11D | Google Spend/KPI truth audit | GO |
| 2026-04-26 | PH-T8.11E | Google Ads Spend sync impl (KEY-194) | NO GO (prereq business) |
| 2026-04-26 | PH-T8.11E.1 | Credentials recovery | GO PARTIEL (3/5 creds) |
| 2026-04-27 | PH-T8.11AE | PROD Closure (code, credentials absent K8s) | NO GO |
| 2026-04-28 | PH-T8.11AF | Credentials GitOps + PROD sync (KEY-194) | GO (4 secrets configured) |
| 2026-04-28 | PH-T8.11AG | OAuth consent publish + token durability (KEY-220) | GO |
| 2026-04-29 | PH-T8.11AL | Google Ads Signup_Complete activation (KEY-217) | GO (GA4 import primary lead) |
| 2026-04-29 | PH-T8.11AM | Post-propagation verify | GO PARTIEL (Cas B, pending 4-24h) |

**Conclusion** : credentials Google Ads charges en K8s secret `keybuzz-google-ads` le 2026-04-28. Refresh token genere et stocke. Sync reussi UNE seule fois le 2026-04-28T20:50:06Z. Depuis : echec systematique.

### 3.2 Meta Ads

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-23 | PH-T8.8A.x | Ad spend global import lock + safety hygiene | GO |
| 2026-04-25 | PH-T8.8B | Meta Ads tenant sync foundation (DEV) | GO DEV |
| 2026-04-25 | PH-T8.8C | Tenant secret store ADS credentials (AES-256-GCM) | GO DEV |
| 2026-04-23 | PH-T8.8C (PROD) | Ad Accounts + secret store PROD | GO PROD |
| 2026-04-26 | PH-ADMIN-T8.11B | Paid Channels dynamic Meta truth (KEY-192) | GO |
| 2026-04-26 | PH-ADMIN-T8.11C | Paid Channels Meta PROD promotion | GO |

Meta operationnel depuis 2026-04-25.

### 3.3 TikTok

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-26 | PH-T8.10L/M/N | TikTok native owner-aware foundation + PROD | GO |
| 2026-05-01 | PH-T8.12P | TikTok browser pixel cutover + dedup (pixel D7PT12JC77U44OJIPC10) | GO (server-side CompletePayment) |
| 2026-05-01 | PH-T8.12Q | Acquisition tracking parity visual QA | GO WITH DOCUMENTED GAPS |
| 2026-05-01 | PH-T8.12Q.1/Q.2 | Events Manager closure | GO CLOSED |

TikTok CAPI configure (destination `KeyBuzz Consulting - TikTok - 2026-05 cutover` active). Spend sync **PAS implemente** (pas dans `ad_platform_accounts`).

### 3.4 LinkedIn

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-26 | PH-T8.10V/W/X | LinkedIn launch readiness minimal fixes + PROD | GO PARTIEL (workaround acceptable) |

LinkedIn Insight Tag `9969977` live. LinkedIn CAPI destination active. Spend sync **PAS implemente** (pas dans `ad_platform_accounts`). CAPI/conversion loop documente comme gap P2.

### 3.5 GA4 / sGTM / Addingwell

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-26 | PH-T8.10O/P/Q | Google sGTM owner-aware + webhook PROD | GO |
| 2026-04-26 | PH-ADMIN-T8.10S/T | Google Admin visibility PROD | GO PARTIEL |
| 2026-04-26 | PH-ADMIN-T8.10U | Addingwell observability foundation | GO |
| 2026-05-01 | PH-T8.12R | Client GA4 + sGTM parity (GA4 G-R3QQDYEBFG, sGTM t.keybuzz.pro) | GO |
| 2026-05-01 | PH-T8.12U | Combined sample demo + tracking parity PROD | GO COMBINED PROD |

GA4 + sGTM live. Pas de write GA4 from backend (server-side via signup_attribution.conversion_sent_at observability only).

### 3.6 Admin v2 marketing surfaces

| Date | Phase | Livrable | Statut |
|---|---|---|---|
| 2026-04-26 | PH-ADMIN-T8.8D + D.1 + D.2 | Ad Accounts Meta Ads UI + PROD | GO |
| 2026-04-28 | PH-ADMIN-T8.10Y/Z | Ad Accounts multi-platform KPI foundation + Paid channels PROD | GO |
| 2026-05-01 | PH-ADMIN-T8.12V | Tracking truth docs + Admin wording alignment | GO AUDIT |
| 2026-05-01 | PH-ADMIN-T8.12W | Admin acquisition baseline spend + runtime truth cleanup | GO CLEANUP |

---

## 4. CARTOGRAPHIE TECHNIQUE

### 4.1 Pages Admin v2 marketing

| URL | Fichier source | BFF | API endpoint | Role |
|---|---|---|---|---|
| /marketing/ad-accounts | admin-v2/src/app/(admin)/marketing/ad-accounts/page.tsx | /api/admin/marketing/ad-accounts[/:id/sync] | keybuzz-api:/ad-accounts | Master spend sync Meta + Google |
| /marketing/destinations | admin-v2/.../destinations/page.tsx | /api/admin/marketing/destinations | keybuzz-api:/outbound-conversions | CAPI mgmt (Meta, TikTok, LinkedIn, Webhook) |
| /marketing/delivery-logs | admin-v2/.../delivery-logs/page.tsx | /api/admin/marketing/delivery-logs | keybuzz-api:/outbound-conversions/delivery-logs | Delivery status events |
| /marketing/google-tracking | admin-v2/.../google-tracking/page.tsx | /api/admin/marketing/google-observability | keybuzz-api:/outbound-conversions/google-observability | gclid + conversion_sent_at telemetry |
| /marketing/funnel | admin-v2/.../funnel/page.tsx | (BFF implicit) | keybuzz-api:/funnel | Pre-tenant funnel events |
| /marketing/metrics | (probable) | (BFF implicit) | keybuzz-api:/metrics | Spend aggregations |
| /marketing/paid-channels | (probable) | (BFF implicit) | (channels) | Channel rules + spend attribution |

### 4.2 Modules keybuzz-api lies tracking

| Module | Endpoints cles | Provider cible | Tables DB |
|---|---|---|---|
| ad-accounts | GET/POST/PATCH /:id/DELETE /:id/POST /:id/sync | Meta Graph API v21.0, Google Ads API v24 | ad_platform_accounts, ad_spend_tenant |
| metrics + ad-platforms/{google-ads.ts, meta-ads.ts} | (internal fetchMeta/fetchGoogle) | Meta, Google Ads | ad_spend_tenant |
| outbound-conversions + adapters/{meta-capi, tiktok-events, linkedin-capi} | GET/POST/PATCH/DELETE + /delivery-logs + /google-observability | Meta CAPI, TikTok Events, LinkedIn CAPI | outbound_conversion_destinations, outbound_conversion_delivery_logs, signup_attribution |
| tracking | POST /webhook/17track | 17Track aggregator | tracking_events, orders |
| funnel | POST /funnel/emit, /funnel/checkout-completed | (internal) | funnel_events |
| dashboard | GET /dashboard/metrics | (aggregate) | ad_spend_tenant, funnel_events |

### 4.3 keybuzz-backend lies tracking

Aucun module ad-accounts ni metrics dans keybuzz-backend. Le backend ne fait pas de sync spend. Tout le pipeline spend + CAPI est sur keybuzz-api.

### 4.4 Workers / cron / jobs

| Worker | Path | Frequence | Provider | Statut |
|---|---|---|---|---|
| outboundWorker | api/src/workers/outboundWorker.ts | on demand | (generic) | active |
| octopiaSyncWorker | api/src/workers/octopiaSyncWorker.ts | periodic | Octopia | active |
| slaBatchWorker | api/src/workers/slaBatchWorker.ts | scheduled | SLA enforcement | active |
| trackingWebhook 17track | api/src/modules/tracking/trackingWebhook.routes.ts | event-driven | 17Track | active |
| **Ad Spend Sync periodic** | **AUCUN CRONJOB K8S** | Manual via Admin UI button | Meta, Google | **MANUAL ONLY** |

Constat critique : il n y a AUCUN CronJob Kubernetes pour le sync periodique des ad_platform_accounts. Le sync est declenche uniquement par clic dans Admin v2 -> POST `/ad-accounts/:id/sync`. Donc si le bouton n est pas clique, aucune donnee n est rafraichie.

### 4.5 Secrets K8s ads/tracking (NAMES ONLY)

| Secret | Type | AGE creation | Keys |
|---|---|---|---|
| keybuzz-google-ads | Opaque | 2026-04-28 (17j) | GOOGLE_ADS_CLIENT_ID, GOOGLE_ADS_CLIENT_SECRET, GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_REFRESH_TOKEN |
| keybuzz-meta-ads | Opaque | 2026-04-20 (24j) | META_ACCESS_TOKEN, META_AD_ACCOUNT_ID |
| keybuzz-ads-encryption | Opaque | 2026-04-23 | (encryption key AES-256-GCM pour tokens DB) |
| tracking-17track | Opaque | 2026-03-31 | TRACKING_17TRACK_API_KEY |
| (autres non-ads) | divers | varies | ghcr-cred, keybuzz-api-jwt, keybuzz-api-postgres, keybuzz-stripe, keybuzz-ses, keybuzz-shopify, keybuzz-litellm, octopia-credentials, redis-credentials, minio-credentials, vault-* |

Cles env vars API PROD lies tracking (NAMES ONLY) :
ADS_ENCRYPTION_KEY, GA4_MEASUREMENT_ID, GA4_MP_API_SECRET, GOOGLE_ADS_CLIENT_ID, GOOGLE_ADS_CLIENT_SECRET, GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_REFRESH_TOKEN, META_ACCESS_TOKEN, META_AD_ACCOUNT_ID, TRACKING_17TRACK_API_KEY.

Gaps notables :
- **AUCUNE env var TikTok au manifest** (tokens stockes en DB encryptes)
- **AUCUNE env var LinkedIn au manifest**
- **AUCUNE env var ADDINGWELL ou GTM_*** (sGTM webhook URL probablement en code ou config non-secret)
- **AUCUN GOOGLE_ADS_LOGIN_CUSTOMER_ID** dans le secret K8s (peut etre code default ou param par account_id)

---

## 5. DIAGNOSTIC GOOGLE invalid_grant

### 5.1 Compte Google Ads (DB ad_platform_accounts)

| Champ | Valeur |
|---|---|
| id | 1d813de7-5c9b-4c98-95fe-66f082c874bc |
| tenant_id | keybuzz-consulting-mo9zndlk |
| account_id | 5947963982 (Google Ads Customer ID : 594-796-3982) |
| platform | google |
| status | active |
| **last_sync_at** | **2026-04-28T20:50:06Z** (= 17 jours ago, jour de creation) |
| **last_error** | `GOOGLE_OAUTH_ERROR: 400 invalid_grant Token has been expired or revoked` |
| currency | GBP |
| created_at | 2026-04-28T20:30:43Z |
| updated_at | 2026-05-15T06:37:02Z (mise a jour il y a quelques minutes = sync tente recemment) |

### 5.2 Logs API PROD recents

Erreurs logs (24h) :
```
{"err":"GOOGLE_OAUTH_ERROR: 400 - {\n  \"error\": \"invalid_grant\",\n  \"error_description\": \"Token has been expired or revoked.\"\n}","msg":"[AdAccounts] sync error"}
```
2 occurrences confirmees dans les dernieres 24h.

### 5.3 Hypotheses cause racine refresh token mort

| Hypothese | Probabilite | Preuve / contre-preuve |
|---|---|---|
| **H1. App OAuth en TESTING (refresh token expire apres 7j)** | TRES PROBABLE | Token genere 2026-04-28, mort vers 2026-05-05 ; aujourd hui 2026-05-15 = 10j apres expiration. PH-T8.11AG date du meme jour (2026-04-28) mais le token a pu etre genere AVANT que l app soit publiee en PRODUCTION |
| H2. Token revoque manuellement par admin Google Workspace | Faible | Aucune raison documentee, mais possible si Ludovic a teste un autre flow |
| H3. Scope manquant (ads.readonly absent) | Faible | Le sync initial du 04-28 a fonctionne, donc scope etait OK a l origine |
| H4. Rotation client_secret (revoke implicite des refresh tokens) | Faible | Pas de modification visible secret K8s depuis 17j |
| H5. Refresh token corrompu en transit GitOps | Tres faible | Sync initial OK, donc base64 propre |

**Verdict** : H1 dominante. Necessite re-OAuth manuel par Ludovic depuis un navigateur connecte au compte Google Ads owner. Une fois la nouvelle valeur en main, mise a jour du secret K8s `keybuzz-google-ads` cle `GOOGLE_ADS_REFRESH_TOKEN` + restart pod API PROD.

### 5.4 Verdict Google

**GOOGLE_TOKEN_EXPIRED_OR_REVOKED**.

Note importante : la page Admin v2 `/marketing/ad-accounts` peut declencher un sync mutationnel (POST /ad-accounts/:id/sync), donc il faut **eviter de cliquer "Sync"** tant que le token n est pas renouvele (chaque clic genere un appel OAuth qui echoue et update `last_error`).

---

## 6. DIAGNOSTIC META

### 6.1 Compte Meta Ads (DB)

| Champ | Valeur |
|---|---|
| id | b8b89a18-aa86-4e34-9488-b53fc404b96a |
| tenant_id | keybuzz-consulting-mo9zndlk |
| account_id | 1485150039295668 |
| platform | meta |
| status | active |
| **last_sync_at** | **2026-05-15T06:36:55Z** (= il y a quelques minutes, OK) |
| **last_error** | null |
| currency | GBP |
| created_at | 2026-04-22 |

### 6.2 Spend Meta

| Periode | Rows | Total spend |
|---|---|---|
| Toute la periode (2026-03-16 -> 2026-05-15) | 19 | 537.52 GBP |
| 30 derniers jours | 3 | 92.32 GBP |

### 6.3 Meta CAPI destination

| Champ | Valeur |
|---|---|
| id | 87f8dc49-5f62-460d-971e-2243c77e1192 |
| tenant_id | keybuzz-consulting-mo9zndlk |
| name | KeyBuzz Consulting - Meta CAPI |
| endpoint_url | https://graph.facebook.com/v21.0/1234164602194748/events |
| platform_pixel_id | 1234164602194748 |
| platform_account_id | 1485150039295668 |
| is_active | true |
| last_test_at | 2026-04-23T15:13Z |
| last_test_status | success |

### 6.4 Gap Meta

- Sync spend OK
- CAPI destination OK
- **AUCUNE delivery log dans les 7 derniers jours** (cf section 9)
- **fbclid = 0 sur 8 signups recents** (cf section 9) -> attribution Meta browser non capturee

**Verdict Meta** : `META_SYNC_OK + META_CAPI_PIPELINE_UNCONFIRMED + ATTRIBUTION_FBCLID_MISSING`.

---

## 7. DIAGNOSTIC TIKTOK

### 7.1 ad_platform_accounts

**Aucun compte TikTok dans `ad_platform_accounts`**. Spend sync TikTok jamais implemente / jamais connecte.

### 7.2 Destinations TikTok CAPI

| id | Name | pixel | account | is_active | last_test |
|---|---|---|---|---|---|
| d5832725 | TikTok PROD Staging - Credentials Pending | PENDING_PIXEL_CODE | PENDING_ADVERTISER_ID | false | 2026-04-25 failed |
| 07b03162 | KeyBuzz Consulting - TikTok (legacy) | D7HQO0JC77U2ODPGMDI0 | 7629719710579130369 | false (disabled apres cutover) | 2026-04-25 success |
| **75a3c56a** | **KeyBuzz Consulting - TikTok - 2026-05 cutover** | **D7PT12JC77U44OJIPC10** | 7634494806858252304 | **true** | 2026-05-01 success |

### 7.3 Verdict TikTok

- **Spend non connecte** (volontaire P2 hors scope KEY-322)
- **CAPI active** (destination cutover du 2026-05-01)
- ttclid attribution : 1 / 8 signups
- **AUCUN delivery log 7j**

`TIKTOK_CAPI_CONFIGURED_BUT_SPEND_NOT_CONNECTED + TIKTOK_DELIVERY_LOG_EMPTY`.

---

## 8. DIAGNOSTIC LINKEDIN

### 8.1 ad_platform_accounts

**Aucun compte LinkedIn dans `ad_platform_accounts`**. Spend sync LinkedIn jamais implemente / jamais connecte. Coherent avec gap P2 documente PH-T8.10X.

### 8.2 Destination LinkedIn CAPI

| Champ | Valeur |
|---|---|
| id | b530ffdc-9415-4072-8bae-5f34087076c2 |
| name | KeyBuzz Consulting - LinkedIn CAPI |
| endpoint_url | https://api.linkedin.com/rest/conversionEvents |
| platform_account_id | 514471703 |
| conversion URNs | StartTrial=27491313, Purchase=27491305 |
| is_active | true |
| last_test_at | 2026-04-27T15:57Z success |

### 8.3 Attribution LinkedIn

- li_fat_id = 0 / 8 signups (aucune attribution)
- utm_source=linkedin : 0 / 8 (last 30d)

### 8.4 Verdict LinkedIn

`LINKEDIN_CAPI_CONFIGURED_BUT_SPEND_NOT_CONNECTED + ATTRIBUTION_LI_FAT_ID_MISSING + ADS_REPORTING_NOT_INTEGRATED`.

---

## 9. GA4 / sGTM / ADDINGWELL / CONVERSIONS

### 9.1 Configuration runtime

- GA4 Measurement ID : `G-R3QQDYEBFG` (env GA4_MEASUREMENT_ID)
- GA4 MP API Secret : configure (env GA4_MP_API_SECRET, valeur non affichee)
- sGTM domain : `https://t.keybuzz.pro` (depuis PH-T8.12R)
- Addingwell : observability configuree (PH-ADMIN-T8.10U)

### 9.2 signup_attribution (DB read-only)

| Indicateur | Valeur |
|---|---|
| Total signups | 8 |
| Last 30 days | 8 |
| with_gclid | 2 |
| with_fbclid | **0** |
| with_ttclid | 1 |
| with_li_fat_id | **0** |
| conversion_sent_at NOT NULL | 3 |

Distribution utm_source last 30d :
- google : 3
- tiktok : 1
- concours : 1
- cursor-validation : 1 (test interne)
- null : 2

### 9.3 outbound_conversion_delivery_logs

**0 delivery log dans les 7 derniers jours**, alors que :
- 8 signups recents (dont 3 avec conversion_sent_at)
- 3 destinations actives (Meta, TikTok cutover, LinkedIn)

**Possibilites** :
- Le `conversion_sent_at` est marque mais le delivery via destinations CAPI n est pas declenche
- OU les destinations ont des conditions de filtrage (event_name, tenant_id) qui excluent les signups recents
- OU le pipeline emission est casse depuis quelques jours

### 9.4 Verdict GA4 / sGTM

- GA4 ID + MP secret configures : OK runtime
- sGTM cutover 2026-05-01 : OK
- **Pipeline conversion -> CAPI destinations : 0 delivery 7j** : a investiguer
- **fbclid + li_fat_id = 0 capture** : tracking landing page incomplet pour Meta + LinkedIn

---

## 10. ADMIN V2 UX TRUTH

### 10.1 Page /marketing/ad-accounts

UI elements observes (via cartographie source) :
- Liste des comptes (Meta + Google)
- Indicateur status, last_sync_at, last_error
- Bouton "Sync" (POST /ad-accounts/:id/sync) -> declenche mutation provider

### 10.2 Messages trompeurs identifies

| UI element | Etat actuel | Probleme | Correction proposee |
|---|---|---|---|
| Affichage `last_error` | Affiche JSON brut `GOOGLE_OAUTH_ERROR: 400 - {"error": "invalid_grant",...}` | Message technique non-actionable | Sanitize + libelle clair "Token Google expire, reconnexion requise" + CTA bouton "Reconnect" |
| Status `active` malgre invalid_grant | active alors que pas de sync 17j | Faussement rassurant | Ajouter etat derive `auth_failing` + badge rouge |
| Bouton "Sync" actif sur compte cassse | Permet clic qui re-echoue + update last_error | Pollue les logs + retentative inutile | Desactiver bouton si last_error contient OAUTH_ERROR ; afficher "Reconnect first" |
| TikTok / LinkedIn absents de la liste | Pas affiches du tout | Donne l illusion qu ils sont en cours alors qu ils ne sont pas connectes | Afficher placeholders "Non connecte - configurer" si tracking destinations existent mais pas spend |
| Currency GBP vs EUR | Affichage brut GBP | Si dashboard reporte EUR, conversion FX manquante | Normaliser ou afficher conversion explicite |

### 10.3 Bouton sync = mutation provider

Le clic "Sync" declenche :
1. POST keybuzz-api:/ad-accounts/:id/sync
2. UPDATE ad_platform_accounts SET last_sync_at, last_error
3. Google : POST oauth2.googleapis.com/token (refresh) puis googleads.googleapis.com/v24/.../searchStream
4. Meta : GET graph.facebook.com/v21.0/act_X/insights
5. INSERT INTO ad_spend_tenant (upsert daily)

**Risque** : chaque clic compte vers les quotas API Google + Meta, et pour Google peut etre comptabilise comme tentative de refresh non-autorisee. Eviter clics multiples.

---

## 11. DB READ-ONLY SUMMARY

| Table | Rows total | Rows 7j/30j recent | Plateformes presentes | Notes |
|---|---|---|---|---|
| ad_platform_accounts | 2 | 1 sync recent (Meta) | Google + Meta | TikTok / LinkedIn absents |
| ad_spend_tenant | 21 | 3 last 30d (Meta) | google=2 rows 2026-04-28 only, meta=19 spread | Google fige depuis 17j |
| outbound_conversion_destinations | 14 (8 inactive + 6 actives) | n/a | Meta CAPI, TikTok x2, LinkedIn CAPI, Webhook | 3 actifs : Meta + TikTok cutover + LinkedIn |
| outbound_conversion_delivery_logs | (count not exposed) | **0 last 7d** | n/a | pipeline conversion -> CAPI semble inactif |
| signup_attribution | 8 (last 30d = 8) | gclid=2 ttclid=1 fbclid=0 li_fat_id=0 conv_sent=3 | google, tiktok, concours, cursor-validation, null | fbclid + li_fat_id non captures |
| funnel_events | (non interroge) | n/a | n/a | hors scope direct invalid_grant |
| tracking_events | (non interroge - 17track) | n/a | 17Track | hors scope |

---

## 12. RISK MATRIX

| ID | Cause | Plateforme | Impact business | Preuve | Mutation requise | Priorite |
|---|---|---|---|---|---|---|
| R1 | Refresh token Google Ads expired/revoked | Google Ads | Pas de spend Google depuis 17j -> KPI Admin invalide, CAC/ROAS Google biaises | last_sync_at=2026-04-28, last_error=invalid_grant | OUI (Ludovic OAuth flow + GitOps secret rotate) | P0 critique |
| R2 | OAuth app statut TESTING vs PRODUCTION incertain | Google Ads | Si TESTING, prochain refresh token re-expire dans 7j -> recurrence | PH-T8.11AG date du meme jour que generation token | NON (verif Google Cloud Console) | P0 lie R1 |
| R3 | GOOGLE_ADS_LOGIN_CUSTOMER_ID absent du secret K8s | Google Ads | Si MCC requis, requests echouent silencieusement | secret keys list n inclut pas LOGIN_CUSTOMER_ID | OUI (GitOps add) si MCC en jeu | P1 conditionnel R1 |
| R4 | 0 delivery log CAPI 7j alors que destinations actives | Meta + TikTok + LinkedIn CAPI | Conversions client-side declarees mais non delivrees -> dashboards ads biaises | outbound_conversion_delivery_logs 7d = 0 | NON (debug pipeline emit) | P1 |
| R5 | with_fbclid = 0 sur 8 signups | Meta attribution | Pas d attribution Meta capturee -> ROAS Meta inutilisable | DB query confirmee | NON (audit LP + Client) | P1 |
| R6 | with_li_fat_id = 0 sur 8 signups | LinkedIn attribution | Pas d attribution LinkedIn | DB query confirmee | NON (audit LP) | P2 |
| R7 | TikTok absent de ad_platform_accounts | TikTok spend | Spend TikTok pas importe alors que pubs tournent (si elles tournent) | DB query confirmee | OUI (Admin UI add account) | P2 |
| R8 | LinkedIn absent de ad_platform_accounts | LinkedIn spend | Idem TikTok | DB query confirmee | OUI (Admin UI add account si Ads Reporting approved) | P2 |
| R9 | Aucun CronJob K8s spend sync periodique | All platforms | Sync manuel uniquement -> si bouton non clique, donnees stale | kubectl get cronjobs vide pour ce besoin | OUI (GitOps add) | P2 |
| R10 | UX Admin last_error JSON brut + bouton Sync actif sur compte casse | Admin v2 UX | Operateur peut pas comprendre la nature de l erreur + retentatives inutiles | Cartographie source | NON (code change Admin v2 DEV first) | P2 |
| R11 | currency GBP vs EUR display | Cross-platform reporting | KPIs cumules en monnaie heterogene si dashboard EUR | DB query confirmee | NON (audit FX normalization) | P3 |
| R12 | Addingwell + sGTM webhook reception non verifie en runtime | GA4/sGTM | Pas de preuve actuelle que les events arrivent en GA4 PROD | Pas de tools de probe ds cette phase | NON (audit dedie) | P2 |

---

## 13. PLAN CORRECTIF PROPOSE (10 sous-phases)

### AS.15.1 - EMERGENCY Google Ads refresh token recovery (P0)

- **Type** : runbook manuel (PAS DEV first car OAuth flow user-side)
- **Acteur** : Ludovic (proprietaire du compte Google Ads)
- **Steps** :
  1. Ouvrir Google Cloud Console -> Project KeyBuzz Ads -> APIs & Services -> OAuth consent screen
  2. Verifier statut : doit etre **PUBLISHED IN PRODUCTION**. Si TESTING -> publier + soumettre verification si scopes sensibles
  3. OAuth Playground (developers.google.com/oauthplayground) ou app KeyBuzz : re-faire le flow OAuth2 avec scope `https://www.googleapis.com/auth/adwords`
  4. Recuperer nouveau refresh_token (sans le coller dans le chat)
  5. Update K8s secret `keybuzz-google-ads` cle `GOOGLE_ADS_REFRESH_TOKEN` (via kubectl edit secret OU GitOps si manage)
  6. Restart pod API PROD : `kubectl -n keybuzz-api-prod rollout restart deploy/keybuzz-api` (graceful, traffic preserve)
  7. Cliquer "Sync" dans Admin v2 -> doit reussir + spend Google s importe
- **Fichiers probables** : `k8s/keybuzz-api-prod/deployment.yaml` (si manifest reference secret) ; secret K8s
- **Risques** : si secret rotate via kubectl direct sans GitOps, drift vs commit ; preferer commit + push externalSecret si geree par external-secrets-operator (a verifier)
- **Tests** : sync DEV puis sync PROD avec Ludovic, controler last_sync_at + ad_spend_tenant rows
- **Rollback** : remettre l ancien refresh_token (impossible si revoque) ; sinon attendre re-auth + escalade Google support
- **GO required** : OUI (Ludovic owns OAuth credentials)
- **Token / provider access requis** : OUI Ludovic
- **Impact PROD** : restart pod API (5s downtime tolere) + sync provider Google Ads

### AS.15.2 - OAuth app PROD status verification + LOGIN_CUSTOMER_ID audit (P0/P1)

- **Type** : audit + GitOps potentiel
- **Steps** :
  1. Confirmer OAuth app statut PUBLISHED (audit Google Cloud Console)
  2. Verifier si GOOGLE_ADS_LOGIN_CUSTOMER_ID est requis (MCC manager account ID)
  3. Si oui : ajouter au secret K8s + manifest env var
- **Rollback** : remove env var
- **GO required** : OUI

### AS.15.3 - Outbound CAPI delivery pipeline diagnosis (P1)

- **Type** : audit READ-ONLY puis fix DEV first si bug
- **Steps** :
  1. Tracer chain : signup_attribution.conversion_sent_at -> emit conversion -> destination resolver -> CAPI delivery -> delivery_logs INSERT
  2. Verifier si l emitter (worker ou route) tourne en PROD
  3. Verifier conditions de filtrage : event_name, tenant_id, is_active
  4. Si pas de delivery alors qu il devrait y en avoir : identifier le break
- **Risques** : si fix code, scope keybuzz-api worker / outbound-conversions service
- **GO required** : pour fix code -> OUI ; pour audit only -> non

### AS.15.4 - fbclid + li_fat_id attribution capture audit (P1)

- **Type** : audit Client + Webflow LPs
- **Steps** :
  1. Verifier MEDIA_BUYER_LP_TRACKING_CONTRACT.md compliance sur LPs Webflow
  2. Verifier que Client capture `fbclid` et `li_fat_id` au signup
  3. Verifier que ces champs sont propages a signup_attribution
- **Pas de patch dans cette phase**
- **GO required** : non (audit)

### AS.15.5 - TikTok + LinkedIn ad_platform_accounts connection (P2)

- **Type** : Admin UI action
- **Acteur** : Ludovic via Admin v2 /marketing/ad-accounts
- **Steps** :
  1. Si pubs TikTok / LinkedIn tournent : ajouter compte via Admin
  2. Necessite tokens TikTok Business API + LinkedIn Ads Reporting API approved
- **Risques** : LinkedIn Ads Reporting necessite approval LinkedIn

### AS.15.6 - Spend sync periodic CronJob (P2)

- **Type** : GitOps add CronJob
- **DEV first**
- **Steps** :
  1. Definir CronJob hourly qui iterate ad_platform_accounts active
  2. POST internal /ad-accounts/:id/sync (avec service account token interne)
  3. Email/Slack alert on consecutive failures
- **Rollback** : remove CronJob manifest
- **GO required** : OUI (modifie comportement scheduled)

### AS.15.7 - Admin v2 UX improvements (P2)

- **Type** : Code change Admin v2 DEV first
- **Steps** :
  1. Sanitize `last_error` display + libelles humains
  2. Add CTA "Reconnect" pour OAuth-related errors
  3. Add "Last successful sync" + freshness indicator (badge rouge si > 24h)
  4. Disable Sync button si oauth_failing
- **Rollback** : revert manifest Admin v2

### AS.15.8 - FX normalization audit (P3)

- **Type** : audit
- **Steps** :
  1. Verifier comment Admin v2 dashboard agrege EUR + GBP
  2. Si FX manquant : proposer integration ECB rates (deja code existant par "FX rates (ECB API)" mention dans Agent E2)

### AS.15.9 - GA4 / sGTM / Addingwell parity runtime audit (P2)

- **Type** : audit GA4 PROD + sGTM webhook + Addingwell
- **Steps** :
  1. Verifier GA4 Realtime sur dashboard `G-R3QQDYEBFG`
  2. Verifier sGTM container `t.keybuzz.pro` receit events
  3. Verifier Addingwell logs
- **Pas de patch sans GO**

### AS.15.10 - Media buyer documentation update (P3)

- **Type** : docs only
- **Steps** :
  1. Update MEDIA-BUYER-TRACKING-GUIDE.md avec statut actuel
  2. Ajouter runbook recovery Google refresh token

---

## 14. LINEAR (commentaire propose KEY-322)

```
PH-ADMIN-T8.12AS.15.0 truth audit livre.

Cause racine identifiee bandeau Admin /marketing/ad-accounts : refresh token Google Ads expire/revoque depuis ~10-17 jours. Dernier sync reussi 2026-04-28T20:50, jour de creation du compte (cf PH-T8.11AF). Depuis : echec systematique avec GOOGLE_OAUTH_ERROR 400 invalid_grant. Hypothese dominante : OAuth app etait en TESTING au moment de la generation du refresh token, expire 7 jours plus tard ; PH-T8.11AG devait publier l app mais possiblement apres generation token.

Etat plateformes :
- Google Ads : SPEND BLOQUE depuis 17j. Account 5947963982 (594-796-3982), tenant keybuzz-consulting-mo9zndlk, currency GBP. 2 rows ad_spend_tenant total (0.06 GBP), datees 2026-04-28 uniquement.
- Meta Ads : OK. Account 1485150039295668, sync 2026-05-15T06:36 success, 19 rows ad_spend_tenant cumules (537.52 GBP total, 92.32 GBP sur 30j). Pixel CAPI 1234164602194748 active, test success 2026-04-23.
- TikTok : spend non connecte (volontaire P2). CAPI cutover destination pixel D7PT12JC77U44OJIPC10 active depuis 2026-05-01.
- LinkedIn : spend non connecte (Ads Reporting non integre, gap P2). CAPI active pour conversions urn:lla:llaPartnerConversion (StartTrial=27491313 + Purchase=27491305).
- GA4 + sGTM : configures runtime (G-R3QQDYEBFG, t.keybuzz.pro).

Findings annexes :
- 0 delivery log CAPI sur 7 derniers jours malgre 3 destinations actives (Meta + TikTok + LinkedIn) - pipeline conversion -> CAPI a investiguer.
- with_fbclid = 0 et with_li_fat_id = 0 sur 8 signups recents - attribution Meta + LinkedIn non capturee cote landing page.
- Aucun CronJob K8s spend sync periodique : sync manuel uniquement (clic Admin button).
- Aucune env var GOOGLE_ADS_LOGIN_CUSTOMER_ID dans le secret K8s keybuzz-google-ads.

Plan d intervention propose (10 sous-phases) :
- P0 AS.15.1 emergency Google refresh token recovery (runbook manuel, Ludovic OAuth flow + secret rotate + pod restart)
- P0 AS.15.2 OAuth app statut PUBLISHED + LOGIN_CUSTOMER_ID audit
- P1 AS.15.3 CAPI delivery pipeline diagnosis (0 delivery 7j)
- P1 AS.15.4 fbclid + li_fat_id LP attribution capture audit
- P2 AS.15.5 TikTok + LinkedIn ad_platform_accounts connection (si pubs tournent)
- P2 AS.15.6 Spend sync periodic CronJob K8s
- P2 AS.15.7 Admin v2 UX improvements (sanitize last_error + CTA Reconnect)
- P2 AS.15.9 GA4 / sGTM / Addingwell parity runtime audit
- P3 AS.15.8 FX normalization audit (GBP vs EUR)
- P3 AS.15.10 Media buyer documentation update

Hors scope :
- AS.14.2 suppliers reste pause sur KEY-314 jusqu a fin KEY-322
- Aucun token affiche, aucun secret expose, aucun event fake
- Aucune mutation provider declenchee par cet audit

Tickets follow-up proposes (pour creation manuelle apres GO Ludovic) :
- KEY-322.1 (P0) Google Ads refresh token recovery + OAuth app PROD publish
- KEY-322.2 (P1) CAPI delivery pipeline restoration (Meta/TikTok/LinkedIn)
- KEY-322.3 (P1) Landing pages fbclid + li_fat_id capture parity
- KEY-322.4 (P2) Ad spend sync periodic scheduler
- KEY-322.5 (P2) Admin v2 ad-accounts UX hardening
- KEY-322.6 (P2) GA4/sGTM/Addingwell runtime parity audit
- KEY-322.7 (P3) FX normalization + media buyer docs

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.15.0-SERVER-SIDE-TRACKING-ADS-ACCOUNTS-TRUTH-AUDIT-01.md
```

Aucun changement de statut Linear effectue par cette phase.

---

## 15. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 mutation provider (Google, Meta, TikTok, LinkedIn)
- 0 refresh OAuth declenche
- 0 token expose dans le rapport ou dans Linear
- 0 secret valeur exposee (seuls noms de cles env/secret K8s)
- 0 PII / payload sensible / customer data
- 0 conversion fake
- 0 spend fake
- 0 click fake
- 0 attribution falsifiee
- 0 event GA4 / CAPI / TikTok / LinkedIn declenche
- 0 webhook test
- 0 INSERT/UPDATE/DELETE DB
- 0 build / push / apply / manifest edit
- 0 Linear status change / commentaire poste

Toutes les valeurs DB rapportees sont des SELECT read-only purs.

---

## 16. NON-REGRESSION PROD

Aucune modification PROD pendant l audit. Etat avant = etat apres :

| Service | Image PROD | Statut |
|---|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-prod | UNCHANGED |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod | UNCHANGED |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

DEV egalement inchange.

---

## 17. GAPS / UNKNOWNS

| Gap | Statut |
|---|---|
| OAuth app Google statut TESTING vs PUBLISHED non confirme cote console | A verifier par Ludovic dans Google Cloud Console |
| Pipeline conversion -> CAPI delivery (0 log 7j) cause exacte | Necessite audit code emitter dedie (AS.15.3) |
| Webflow LP capture fbclid + li_fat_id | Necessite audit LP externes |
| LinkedIn Ads Reporting API approval status | Inconnu, a verifier sur LinkedIn Marketing Developer Platform |
| Addingwell + sGTM runtime delivery (events reels) | Necessite probes safe GA4 Realtime + sGTM logs (AS.15.9) |
| ad_spend_tenant currency GBP vs UI EUR | Affichage UI a verifier (AS.15.8) |

Aucun gap bloquant pour la decision : AS.15.1 (emergency Google recovery) est la priorite absolue P0 et peut commencer des aujourd hui sous GO Ludovic.

---

## 18. PHRASE CIBLE FINALE

Audit READ-ONLY complet livre. Cause racine bandeau Admin /marketing/ad-accounts confirmee : refresh token Google Ads expire/revoque depuis 17 jours, sync echoue avec GOOGLE_OAUTH_ERROR 400 invalid_grant. Meta operationnel. TikTok + LinkedIn CAPI configures sans spend sync (gap P2 connu). Pipeline conversion CAPI 0 delivery 7j a investiguer. Attribution fbclid + li_fat_id non capturee. Plan d intervention en 10 sous-phases propose, AS.15.1 emergency Google recovery en priorite P0. Aucune mutation, aucun secret expose, aucun event fake. PROD strictement inchangee.

STOP
