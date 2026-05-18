# PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01

> Date : 2026-05-18
> Linear : a rattacher post-decision Ludovic (KEY-323 en pause, candidat nouveau ticket tracking)
> Phase : AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY
> Environnement : PROD + DEV lecture uniquement

## VERDICT

GO READY Q-1T TRACKING SERVER-SIDE ROOT CAUSES IDENTIFIED (multiples, classifies)

3 root causes distinctes identifiees, aucune lie a un sGTM proxy KeyBuzz "casse" (il n'a jamais ete deploye par design) :

1. **R1 CONFUSION ARCHITECTURE** : `/gtm/debug` n'existe pas par design dans le website ni le client SaaS. 0 ligne source detectee dans keybuzz-website et keybuzz-client pour ce path. Aucun container Google Tag Manager Server (sGTM) n'est deploye dans le cluster (0 ingress / 0 service / 0 deployment / 0 pod matching gtm/server-side). Architecture tracking server-side KeyBuzz = **Meta CAPI direct + GA4 Measurement Protocol direct** via API SaaS server-to-server vers `https://t.keybuzz.io/mp/collect` (hors cluster, IP Google Cloud LB 34.120.158.38) + Meta Graph API CAPI direct via env `META_*` tenant-scoped. Le 404 sur www.keybuzz.pro et le 307 redirect signin sur client.keybuzz.io pour `/gtm/debug` sont **comportements nominaux**.

2. **R2 CRITIQUE BLOCKER OUTBOUND-TICK-PROCESSOR** : Le CronJob `keybuzz-api-prod/outbound-tick-processor` (`*/1 * * * *`) appelle un endpoint API qui retourne `404 Route POST:/debug/outbound/tick not found` a chaque tick (verifie sur job `outbound-tick-processor-29651860`). L'endpoint a ete refactore ou supprime dans l'API SaaS PROD v3.5.190 mais le CronJob pointe encore vers l'ancien path. Pattern d'exposition de drift Git/runtime similaire a Q-1B-5B-2A STAKATER. Ce drift bloque potentiellement le pipeline outbound conversion/spend selon ce que faisait l'endpoint historique. Investigation deep requise.

3. **R3 AD_SPEND TENANT-SCOPED MIGRATION PROD INCOMPLETE** : Heritage Q-1B-5A SERVER_SIDE_TRACKING_CONTEXT et PH-T8.8A indiquent explicitement "PROD inchangee" pour la migration `ad_spend` global vers `ad_spend_tenant`. Tables `ad_platform_accounts` + `ad_spend_tenant` deployees en DEV (commit API `f4c3d910`, image `v3.5.102-ad-spend-tenant-safety-dev`) mais jamais promues PROD. Consequence : `/metrics/overview?tenant_id=X` en PROD lit potentiellement encore `ad_spend` global au lieu de la table tenant-scoped, donc l'admin V2 `/metrics` + `/marketing/ad-accounts` n'affiche pas le spend pour les tenants non-keybuzz-consulting. PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP existe (a relire pour etat actuel exact).

Pipeline tracking server-side complet inventorie (env-vars + secrets + endpoints + CronJobs + CSP). Aucun appel provider authentifie. Aucune lecture de valeur secret en clair (manifests env-vars lues metadata-only via grep). Aucun fake event. Aucun appel proxy LiteLLM. PROD intouchee.

Plan correction propose en 4 sous-phases dediees (Q-1T-1 documentation alignment, Q-1T-2 outbound-tick-processor fix, Q-1T-3 ad_spend PROD migration, Q-1T-4 sGTM evaluation si demande).

## Scope / hors scope

### Scope strict applique

- HTTP HEAD/GET sans credentials vers domaines KeyBuzz publics (www.keybuzz.pro, client.keybuzz.io, admin.keybuzz.io, api.keybuzz.io, t.keybuzz.io, et 6 subdomains tracking-related testes)
- DNS resolution publique (dig +short)
- Cluster K8s lecture pure : ingress, services, deployments, pods, cronjobs, jobs, logs CronJob outbound-tick-processor (filtre)
- Source code grep dans 6 repos (website, client, api, backend, admin-v2, infra) pour patterns tracking/GTM/spend/ads/Meta/GA4
- Lecture rapports AI_MEMORY (SERVER_SIDE_TRACKING_CONTEXT.md 1888 lignes header + sections, MEDIA_BUYER_LP_TRACKING_CONTRACT.md complet)
- Lecture manifests env-vars Deployments api-dev + api-prod (filtres tracking)

### Hors scope respecte

- Aucun patch website / client / admin / API / backend
- Aucun build / deploy / kubectl apply / patch / edit / delete / rollout
- Aucun test d'achat
- Aucun fake event / fake metric
- Aucun envoi event GA4 / Meta / TikTok / LinkedIn
- Aucun appel API provider authentifie Meta / Google / GA4 / GTM (uniquement HEAD/GET publics)
- Aucun changement DNS
- Aucun commentaire Linear
- Aucune lecture valeur secret en clair (.data jamais affichee, aucun base64 -d)
- Pas de provider authenticated call

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-EXEC-...01.md | commit d85ee5e | OK ancestor confirme (pause KEY-323) |
| docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md | 1888 lignes, derniere maj 2026-04-24 | OK lu sections cles |
| docs/AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md | version 1.0 du 2026-05-09 KEY-285/284 | OK lu complet |
| docs/PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md | present | OK indique PROD inchangee |
| docs/PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md | present | OK foundation deployee |
| docs/PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md | present | OK PROD secret store ads |
| docs/PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md | present | NOT yet read, candidat lecture pre-Q-1T-3 |
| docs/PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md | present | OK Meta CAPI deja PROD |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc d85ee5e / clean | match | OK |
| /tmp residuels Q-1T | absent | absent | OK |
| keybuzz-website branch / dirty | main / 0 | match | OK |
| keybuzz-client branch / dirty | ph148/onboarding-activation-replay / 0 | match | OK |
| keybuzz-api branch / dirty | ph147.4/source-of-truth / 223 (dev actif documente) | match | OK lecture |
| keybuzz-backend branch / dirty | main / 1 | match | OK lecture |
| keybuzz-admin-v2 branch / dirty | main / 0 | match | OK |
| AI_MEMORY tracking docs disponibles | SERVER_SIDE_TRACKING + MEDIA_BUYER_LP | present | OK |

## HTTP reproductions publiques (E2)

| URL | HTTP code | Notes |
|---|---|---|
| https://www.keybuzz.pro/ | 200 | website Next.js prod OK (x-nextjs-cache: HIT) |
| https://www.keybuzz.pro/gtm/debug | **404** | Next.js prerender HIT confirme page absente du build (aucune route /gtm/debug) |
| https://www.keybuzz.pro/api/health | 404 | endpoint pas implemente cote website |
| https://www.keybuzz.pro/robots.txt | 200 | sitemap.xml declare |
| https://client.keybuzz.io/ | 307 redirect /auth/signin?callbackUrl=%2F | nominal SaaS login required |
| https://client.keybuzz.io/gtm/debug | **307** redirect /auth/signin?callbackUrl=%2Fgtm%2Fdebug | nominal middleware Next.js redirige path inconnu vers signin |
| https://client.keybuzz.io/api/health | 307 redirect signin | nominal |
| https://admin.keybuzz.io/ | 307 redirect /login | nominal admin, CSP visible |
| https://api.keybuzz.io/health | 200 application/json | API SaaS PROD healthy |
| https://t.keybuzz.io/ | **400** server: Google Frontend, via: 1.1 google | endpoint GCP-hosted, repond mais 400 sans payload valide |
| https://t.keybuzz.io/healthz | **400** Google Frontend | idem |
| https://t.keybuzz.io/gtm/debug | **404** text/plain Google Frontend | NOT a working sGTM proxy preview endpoint |

CSP admin (analyse) :
- connect-src whitelisted : `https://api.keybuzz.io https://api-dev.keybuzz.io https://admin-api.keybuzz.io https://admin-api-dev.keybuzz.io`
- **ANOMALY** : `admin-api.keybuzz.io` referenced in CSP **NXDOMAIN** (cannot resolve)
- admin parle donc en realite uniquement a `api.keybuzz.io` + `api-dev.keybuzz.io`

## DNS reproductions tracking-related subdomains (E2.6)

| Domain | DNS Resolution |
|---|---|
| www.keybuzz.pro | 49.13.42.76, 138.199.132.240 (cluster ingress nodes) |
| keybuzz.pro | 138.199.132.240, 49.13.42.76 (idem) |
| client.keybuzz.io | 138.199.132.240, 49.13.42.76 (idem) |
| admin.keybuzz.io | 138.199.132.240, 49.13.42.76 (idem) |
| api.keybuzz.io | 49.13.42.76, 138.199.132.240 (idem) |
| **t.keybuzz.io** | **34.120.158.38 (Google Cloud Load Balancer, HORS cluster)** |
| sgtm.keybuzz.pro | NXDOMAIN |
| gtm.keybuzz.pro | NXDOMAIN |
| server.keybuzz.pro | NXDOMAIN |
| collect.keybuzz.pro | NXDOMAIN |
| track.keybuzz.pro | NXDOMAIN |
| admin-api.keybuzz.io | NXDOMAIN (declare CSP admin) |

**Insight** : aucun subdomain dedie sGTM/server-side tracking n'est configure. `t.keybuzz.io` pointe vers GCP, probablement endpoint GA4 Measurement Protocol custom domain alias OU sGTM heberge GCP mal configure.

## Cluster K8s inventory tracking (E3)

| Resource | Count | Notes |
|---|---|---|
| ingress matching tracking/gtm/sgtm/server-side | 0 | aucun |
| service matching tracking/gtm | 0 | aucun |
| deployment matching tracking/gtm/meta-capi | 0 | aucun |
| pod image matching gtm/google-tag/tagmanager/meta-capi | 0 | aucun |
| CronJob marketing/ads/spend/sync/conversion/capi | 0 | aucun (mais 6 CronJobs total existants : carrier-tracking-poll x2, amazon-orders-sync x2, amazon-reports-tracking-sync x2, outbound-tick-processor, sla-evaluator x3, trial-lifecycle-dryrun, monitoring-alerts, vault-token-renew) |

**Conclusion** : architecture tracking server-side N'EST PAS un container deploye dans le cluster. Elle est entierement implementee dans le code de l'API SaaS (keybuzz-api) qui communique server-to-server avec `t.keybuzz.io/mp/collect` (GA4 MP) + Meta Graph API CAPI direct + Google Ads API.

## Source code grep findings (E4-E8)

### Website (keybuzz-website)
- `/gtm/debug`, `gtm/debug`, `/gtm`, `GTM_SERVER`, `NEXT_PUBLIC_GTM`, `sgtm` : **0 occurrence** pour tous patterns
- **Confirme : aucune route /gtm/debug par design**

### Client SaaS (keybuzz-client)
- `/gtm/debug`, `gtm/debug`, `/gtm`, `GTM_SERVER`, `NEXT_PUBLIC_GTM` : **0 occurrence**
- `middleware.ts` existe (responsable du redirect 307 vers signin pour paths inconnus)
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID` consume par `SaaSAnalytics.tsx` (client-side GA4 standard)

### API SaaS (keybuzz-api)
- `CONVERSION_WEBHOOK_URL` : 1 usage actif `src/modules/billing/routes.ts:2076`
- `GA4_MP_API_SECRET` : 1 usage actif `src/modules/billing/routes.ts:2167`
- `GA4_MEASUREMENT_ID` : 1 usage actif `src/modules/billing/routes.ts:2077`
- `ad_spend` (snake case = colonnes SQL) : 2 files (`src/modules/ad-accounts/routes.ts`, `src/modules/metrics/routes.ts`)
- `ad-accounts` endpoints : 2 files

### Admin V2 (keybuzz-admin-v2)
- 11 files matching "spend"
- UI marketing complete : `/marketing/ad-accounts`, `/marketing/campaign-qa`, `/marketing/integration-guide`, `/marketing/google-tracking`, `/marketing/acquisition-playbook`, `/marketing/destinations`, `/metrics`, `/audit`
- BFF API admin : `/api/admin/admin-api/marketing/destinations`, `/api/admin/marketing/funnel/metrics`, `/api/admin/metrics`

## Manifest Deployments tracking env-vars (E9)

### api-prod (manifest k8s/keybuzz-api-prod/deployment.yaml post Q-1B-5B-2A-EXEC)

| Env var | Source | Value |
|---|---|---|
| OUTBOUND_CONVERSIONS_WEBHOOK_URL | value plain | "" (vide PROD) |
| OUTBOUND_CONVERSIONS_WEBHOOK_SECRET | value plain | "" |
| TRACKING_17TRACK_API_KEY | secretKeyRef tracking-17track | (secret) |
| CONVERSION_WEBHOOK_ENABLED | value plain | "true" |
| **CONVERSION_WEBHOOK_URL** | value plain | "https://t.keybuzz.io/mp/collect" |
| **GA4_MP_API_SECRET** | value plain | "BqL-nFtvTc6osZ57A2REKA" (expose plain-text Git !) |
| CONVERSION_WEBHOOK_SECRET | value plain | "ph-t4-dev-hmac-secret" (expose !) |
| **GA4_MEASUREMENT_ID** | value plain | "G-R3QQDYEBFG" (mesurement id GA4) |
| META_AD_ACCOUNT_ID | secretKeyRef keybuzz-meta-ads | (secret) |
| META_ACCESS_TOKEN | secretKeyRef keybuzz-meta-ads | (secret) |
| GOOGLE_ADS_DEVELOPER_TOKEN | secretKeyRef keybuzz-google-ads | (secret) |
| GOOGLE_ADS_CLIENT_ID | secretKeyRef keybuzz-google-ads | (secret) |
| GOOGLE_ADS_CLIENT_SECRET | secretKeyRef keybuzz-google-ads | (secret) |
| GOOGLE_ADS_REFRESH_TOKEN | secretKeyRef keybuzz-google-ads | (secret) |

**ALERTE EXPOSITION NOUVELLE** : `GA4_MP_API_SECRET` + `CONVERSION_WEBHOOK_SECRET` exposes en `value:` plain-text dans Git PROD manifest. Pattern identique LITELLM_MASTER_KEY (Q-1B-5A) et STAKATER_VAULT_ROOT_TOKEN_SECRET (Q-1B-5B-2A). Candidat phase ulterieure Q-1T-5 (migration ESO ou ce mode Secret K8s).

### api-dev manifest

| Env var | Statut |
|---|---|
| TRACKING_17TRACK_API_KEY | OK secretKeyRef |
| GOOGLE_ADS_* (4 envs) | OK secretKeyRef |
| OUTBOUND_CONVERSIONS_WEBHOOK_URL/SECRET | "" |
| **CONVERSION_WEBHOOK_URL / GA4_MP_API_SECRET / GA4_MEASUREMENT_ID / META_*** | **ABSENT en DEV** (tracking server-side actif PROD uniquement) |

## CronJobs tracking-related (E9.2)

Aucun CronJob marketing/ads/spend/sync/conversion/capi detecte. Le CronJob `outbound-tick-processor` (`*/1 * * * *`) appelle `https://api.keybuzz.io/debug/outbound/tick` qui retourne **404 Route POST:/debug/outbound/tick not found** -> drift critique.

## Root cause R2 - outbound-tick-processor drift critique (E10.1-E10.2)

| Field | Value |
|---|---|
| CronJob name | keybuzz-api-prod/outbound-tick-processor |
| Schedule | */1 * * * * (toutes les minutes) |
| Suspended | false |
| Image | badouralix/curl-jq@sha256:554222a9... |
| Command | /bin/sh -c |
| Args | echo "[$(date)] Tick starting..."; curl -sk -X POST https://api.keybuzz.io/debug/outbound/tick --max-time 10; echo; echo "[$(date)] Tick complete" |
| Last job | outbound-tick-processor-29651860 |
| Last response body | {"message":"Route POST:/debug/outbound/tick not found","error":"Not Found","statusCode":404} |

**Hypothese root cause** : l'endpoint `/debug/outbound/tick` a ete refactore (probable renomme en `/admin/outbound/tick`, `/api/outbound/tick`, ou similaire) ou supprime dans une version API SaaS posterieure a la creation du CronJob. Le CronJob n'a pas ete mis a jour.

**Impact** :
- Le tick processor ne tourne PAS reellement depuis X temps (a determiner via log historique).
- Si l'endpoint declenche : conversion dispatch, ad spend sync, marketing destination delivery, ou similaire => tout cela est bloque.
- L'absence de spend dans admin V2 est probablement CONSEQUENCE directe de ce drift (pas root cause distincte).

**Necessite Q-1T-2** : investigation source code API SaaS pour identifier le bon endpoint actuel, plus patch CronJob args OU re-implementation endpoint.

## Root cause R3 - ad_spend PROD migration incomplete (E10.7)

| Heritage | Etat documente |
|---|---|
| PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01 | "DEV termine, PROD inchangee" (citation 2026-04-22 SERVER_SIDE_TRACKING_CONTEXT) |
| API commit DEV | f4c3d910 |
| Image DEV | v3.5.102-ad-spend-tenant-safety-dev |
| Digest DEV | sha256:5178f39c5df537a7d0cb1b5c726bc3a9a289c76ff63d799eeaa0ce1e32c42601 |
| Tables DEV deployees | ad_platform_accounts, ad_spend_tenant |
| Backfill DEV | 16 rows ad_spend global migrees vers ad_spend_tenant pour keybuzz-consulting-mo9y479d |
| API runtime PROD actuel | v3.5.190-channels-tenantguard-prod (donc 88 versions plus recente) |
| PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP | present, NOT yet read - probable PROD partiellement migrate |

**Necessite Q-1T-3** : lecture PH-T8.8G en details + verification runtime PROD si tables tenant-scoped + sample query `/metrics/overview?tenant_id=<test>` pour confirmer si le drift est encore actif.

## Hypotheses root cause par question Ludovic

### Q1 : Pourquoi www.keybuzz.pro/gtm/debug retourne 404

**REPONSE** : DESIGN. Le website Next.js n'a aucune route `/gtm/debug` (verifie par grep 0 occurrence dans keybuzz-website). C'est attendu. Aucun bug. **Pas un sGTM proxy KeyBuzz par design** (architecture choisie : CAPI direct).

### Q2 : Pourquoi client.keybuzz.io/gtm/debug -> login SaaS

**REPONSE** : DESIGN. Le middleware Next.js du client SaaS redirige tout path non-reconnu vers `/auth/signin?callbackUrl=<path>` (default behavior). Comportement nominal pour une app authentifiee.

### Q3 : Server-side tracking attendu cote cluster (ingress/service/container/website rewrites/GTM endpoint)

**REPONSE** : AUCUN container sGTM/GTM Server deploye dans le cluster Kubernetes. Architecture reelle :
- API SaaS (keybuzz-api) -> Meta Graph API CAPI direct via `META_ACCESS_TOKEN` + `META_AD_ACCOUNT_ID` tenant-scoped
- API SaaS -> GA4 Measurement Protocol via `https://t.keybuzz.io/mp/collect` + `GA4_MP_API_SECRET` + `GA4_MEASUREMENT_ID`
- API SaaS -> Google Ads API via `GOOGLE_ADS_*` (4 env vars secretKeyRef)
- API SaaS -> LinkedIn CAPI (mentioned PH-T8.11Q)
- Client SaaS -> GA4 client-side via `NEXT_PUBLIC_GA4_MEASUREMENT_ID` + `SaaSAnalytics.tsx`
- Webhook outbound destinations : `OUTBOUND_CONVERSIONS_WEBHOOK_URL` (vide PROD, pas configure pour client)

### Q4 : Container GTM mal route, absent, ou mauvais host ?

**REPONSE** : Le container n'existe pas, par choix architectural. La confusion vient du fait que Ludovic peut s'attendre a sGTM (Google Tag Manager Server, hosted container avec /gtm/debug preview UI), alors que l'architecture KeyBuzz est CAPI direct sans intermediaire sGTM.

### Q5 : Pourquoi le spend publicitaire ne se met pas a jour dans l'admin

**REPONSE** : 2 root causes cumulees probables :
- **R2 Bloquant** : `outbound-tick-processor` CronJob retourne 404 toutes les minutes (endpoint `/debug/outbound/tick` introuvable). Si cet endpoint declenchait le spend sync, le pipeline est bloque depuis X temps.
- **R3 Architecture** : migration ad_spend tenant-scoped jamais promue PROD (T8.8A DEV uniquement). Si l'admin V2 lit `ad_spend_tenant` mais PROD n'a pas cette table peuplee, affichage vide pour tous tenants.

## Plan correction propose en sous-phases (E11)

### Q-1T-1 DOCUMENTATION ALIGNMENT (zero-risk, immediat)

- Mettre a jour AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md pour clarifier "aucun sGTM proxy KeyBuzz par design, architecture CAPI direct"
- Documenter dans CURRENT_STATE.md que `/gtm/debug` n'existe pas
- Decision Ludovic : maintien architecture CAPI direct OU evaluation sGTM (Q-1T-4 separe)

### Q-1T-2 OUTBOUND-TICK-PROCESSOR DRIFT INVESTIGATION + FIX (URGENT - P0)

DRY-RUN d'abord :
- Grep API SaaS source code (`keybuzz-api/src`) pour identifier le bon endpoint actuel (probable `/admin/outbound/tick`, `/internal/outbound/tick`, `/api/v1/outbound/tick`)
- Verifier logs job historique pour determiner depuis quand l'endpoint retourne 404
- Identifier l'impact : conversion dispatch, spend sync, destination delivery, autre
- Verifier si pattern similaire existe pour sla-evaluator + sla-evaluator-escalation + carrier-tracking-poll (autre CronJobs `*/1 * * * *` peuvent etre cassees aussi)

EXEC Mode B SAFE PROD :
- Patch CronJob args avec bon endpoint OU restaurer endpoint API (selon decision)
- Verify next tick succes
- Monitor impact spend sync admin V2

### Q-1T-3 AD_SPEND PROD MIGRATION + RUNTIME VERIFICATION

- Lecture complete PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md
- Verifier en DB PROD si `ad_spend_tenant` existe + est peuplee
- Verifier endpoint `/metrics/overview?tenant_id=<test>` en PROD retourne spend correct
- Si manquant : preparation phase migration PROD T8.8A + reactivation `/metrics/import/meta` automatique tenant-par-tenant
- Decision Ludovic priorite vs Q-1T-2

### Q-1T-4 sGTM EVALUATION (optionnel, si Ludovic veut vraiment sGTM)

- Phase cost-benefit deploy Google Tag Manager Server container (sGTM) :
  - Costs : 1 container Node.js GCP/K8s, 1 subdomain DNS, configuration Google Tag Manager workspace, maintenance
  - Benefits : Preview UI `/gtm/debug` fonctionnel, server-side container management UI, plus de flexibilite event mapping
  - Comparison : architecture actuelle CAPI direct = simple, pas d'intermediaire, performant
- Recommandation : NON SAUF besoin specifique (ex : multi-platform tracking centralise UI). L'architecture CAPI direct est suffisante pour KeyBuzz.

### Q-1T-5 (NOUVELLE proposee) - TRACKING SECRETS GIT EXPOSURE CLEANUP

Pattern d'exposition Git plain-text identique a Q-1B-5A LITELLM_MASTER_KEY + Q-1B-5B-2A STAKATER :
- `GA4_MP_API_SECRET = "BqL-nFtvTc6osZ57A2REKA"` plain-text manifest PROD
- `CONVERSION_WEBHOOK_SECRET = "ph-t4-dev-hmac-secret"` plain-text manifest PROD
- Migration recommandee vers ESO + Vault path (similar a Q-1B-5B-0/1 pattern)

## Risk matrix

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Lecture accidentelle valeur secret dans output | TRES FAIBLE (jamais affichee, grep metadata-only) | ELEVE | safety check final 0 leak |
| R2 | Provider authenticated call accidentel | NEANT (uniquement HEAD/GET publics sans creds) | ELEVE | interdiction stricte respectee |
| R3 | Mutation accidentelle PROD | NEANT (0 kubectl create/patch/edit/apply/delete) | ELEVE | scope read-only |
| R4 | Confusion alignement Ludovic vs architecture | MOYEN si pas explique correctement | MOYEN | Q-1T-1 documentation alignment |
| R5 | Q-1T-2 fix CronJob casse autre pipeline | MOYEN | ELEVE | DRY-RUN obligatoire avant EXEC |
| R6 | Q-1T-3 migration PROD ad_spend casse `/metrics/overview` | MOYEN | ELEVE | tester en DEV puis Mode B SAFE PROD |
| R7 | sGTM evaluation Q-1T-4 conclut deploy mais cout maintenance > benefit | FAIBLE | MOYEN | decision Ludovic eclairee |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T diagnostic | Impact |
|---|---|---|---|
| website-prod | Running | inchange | 0 (read-only) |
| client-prod | Running | inchange | 0 |
| admin-v2-prod | Running | inchange | 0 |
| api-prod (keybuzz-api jx6m7 puis 4zr29 Q-1B-5B-2A-EXEC) | Running | inchange | 0 |
| backend-prod | Running | inchange | 0 |
| studio-api-prod | Running | inchange | 0 |
| LiteLLM keybuzz-ai 2 pods | Running 0 restart | inchanges | 0 |
| Vault KV PROD | non touche | non touche | 0 |
| Argo CD applications | inchange | inchange | 0 |
| Providers Meta/Google/GA4/GTM | 0 call authentifie | 0 | 0 |
| t.keybuzz.io endpoint | 0 mp/collect envoy | 0 (HEAD/GET only) | 0 |
| Manifests Git source | inchanges | inchanges | 0 |
| Git history | HEAD d85ee5e | HEAD d85ee5e | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| Patch website/client/admin/API/backend | 0 modification source | OK |
| Build / deploy | 0 | OK |
| kubectl apply/patch/edit/delete/rollout | 0 | OK |
| Fake event / fake metric | 0 envoi | OK |
| Envoi event GA4/Meta authenticated | 0 (uniquement HEAD/GET publics, 400/404 normaux) | OK |
| Appel API provider authentifie | 0 | OK |
| Changement DNS | 0 | OK |
| Lecture valeur secret en clair via .data / base64 | 0 (grep metadata source uniquement) | OK |
| Affichage gtm_auth ou URL preview avec token | N/A (aucune URL preview detectee) | OK |
| Linear comment | 0 | OK |
| /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ touche | 0 | OK |
| Tenant/user/email hardcode dans rapport | 0 | OK |

12/12 contraintes read-only respectees.

## Brouillon Linear (a creer si Ludovic GO)

```
TITRE proposed : Diagnostic tracking server-side - root causes identifies (R1 confusion arch, R2 outbound-tick drift critique, R3 ad_spend PROD migration incomplete)

Status: COMPLETE - DECISION LUDOVIC REQUISE PLAN CORRECTION
Scope: PROD + DEV lecture pure

Findings:
- R1 CONFUSION ARCHITECTURE: /gtm/debug n'existe pas par design (0 ligne source detectee). Architecture tracking server-side = Meta CAPI direct + GA4 MP direct via API SaaS, PAS de container sGTM dans le cluster.
- R2 CRITIQUE outbound-tick-processor CronJob retourne 404 Route POST:/debug/outbound/tick not found a chaque tick (1/min). Endpoint refactore ou supprime dans API v3.5.190, CronJob non mis a jour.
- R3 AD_SPEND tenant-scoped migration PROD incomplete (T8.8A documente "DEV termine, PROD inchangee"). admin V2 /metrics n'affiche pas spend tenants probablement consequence.
- ALERTE BONUS: GA4_MP_API_SECRET + CONVERSION_WEBHOOK_SECRET exposes plain-text manifest Git PROD (pattern Q-1B-5A LITELLM, Q-1B-5B-2A STAKATER).

Plan correction propose:
- Q-1T-1 Documentation alignment (immediat)
- Q-1T-2 OUTBOUND-TICK-PROCESSOR DRIFT FIX (URGENT P0)
- Q-1T-3 AD_SPEND PROD migration + verification
- Q-1T-4 sGTM evaluation (optionnel)
- Q-1T-5 Tracking secrets Git exposure cleanup (Pattern similaire Q-1B-5A/5B-2A)

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01.md
```

## Gaps restants

1. **PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md** : non lu en details cette phase, prerequis Q-1T-3.
2. **Logs historique outbound-tick-processor** : depuis quand le 404 ? prerequis Q-1T-2.
3. **Endpoint API actuel correct pour outbound tick** : grep source code keybuzz-api requis pour Q-1T-2.
4. **Decision Ludovic priorisation Q-1T-2 vs Q-1T-3** : les 2 sont importants mais Q-1T-2 plus urgent (bloque le pipeline general).
5. **Q-1T-4 sGTM evaluation** : optionnel, depend si Ludovic veut maintenir architecture CAPI direct OU deployer sGTM.
6. **Q-1T-5 tracking secrets Git exposure cleanup** : pattern accumule (LITELLM + STAKATER + GA4_MP + CONVERSION_WEBHOOK + STAKATER pluriels). Candidate phase consolidee.
7. **KEY-323 reprise** : apres Q-1T resolution, decision si reprendre Q-1B-5B-2-EXEC LLM env migration ou autres phases.
8. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue.

## Phrase cible finale

Diagnostic tracking server-side complete : reproduction HTTP documentee (404 sur www.keybuzz.pro/gtm/debug = DESIGN aucun chemin source, 307 redirect client.keybuzz.io/gtm/debug = middleware nominal, 400/404 sur t.keybuzz.io = endpoint GCP non-sGTM), routing www.keybuzz.pro/client.keybuzz.io cartographie via cluster ingress + CSP admin, presence ou absence server-side GTM identifiee (0 container sGTM/GTM dans le cluster par design, architecture CAPI direct + GA4 MP direct), spend admin pipeline inventorie (3 root causes : R1 confusion architecture, R2 outbound-tick-processor CronJob HTTP 404 chaque minute drift critique pattern similar Q-1B-5B-2A STAKATER, R3 ad_spend PROD migration tenant-scoped incomplete T8.8A documente "PROD inchangee"), pattern d'exposition secret plain-text Git etendu identifie (GA4_MP_API_SECRET + CONVERSION_WEBHOOK_SECRET plain manifest api-prod, candidat Q-1T-5), hypotheses classees, plan correction propose en 5 sous-phases (Q-1T-1 docs / Q-1T-2 outbound-tick-fix URGENT / Q-1T-3 ad_spend migration / Q-1T-4 sGTM eval optionnel / Q-1T-5 secrets cleanup), 0 mutation, 0 fake event, 0 provider authenticated call, 0 lecture valeur secret en clair, PROD intouchee - decision Ludovic requise sur priorisation Q-1T-2 vs Q-1T-3 + maintien architecture CAPI direct vs evaluation sGTM Q-1T-4.

STOP
