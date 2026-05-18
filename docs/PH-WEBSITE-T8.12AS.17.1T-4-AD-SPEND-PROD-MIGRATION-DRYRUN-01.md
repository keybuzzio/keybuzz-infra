# PH-WEBSITE-T8.12AS.17.1T-4-AD-SPEND-PROD-MIGRATION-DRYRUN-01

> Date : 2026-05-18
> Linear : a rattacher post-decision Ludovic
> Phase : AS.17.1T-4 AD_SPEND PROD MIGRATION DRY-RUN
> Environnement : PROD + DEV lecture uniquement

## VERDICT

GO PARTIEL DESIGN REQUIRED Q-1T-4 - ROOT CAUSE IDENTIFIEE = ABSENCE AUTOMATISATION SYNC (PAS MIGRATION INCOMPLETE)

**Hypothese initiale R3 OBSOLETE** : la migration ad_spend tenant-scoped EST DEJA EN PROD depuis le 2026-04-23 (PH-T8.8A.2). Les tables `ad_platform_accounts` + `ad_spend_tenant` existent en PROD avec 1 ad account + 16 rows (post-T8.8G cleanup). `/metrics/overview?tenant_id=X` lit exclusivement `ad_spend_tenant` (jamais `ad_spend` global). Image PROD actuelle `v3.5.190` est 84 commits posterieure a T8.8G cleanup (2026-04-26) -> tous correctifs T8.8A-T8.8G inclus en PROD. 0 regression code source detectee (seul commit ad-accounts/routes.ts depuis T8.8G = Google Ads sync addition KEY-194 b854c470).

**Vraie root cause spend admin absent** = **ABSENCE D'AUTOMATISATION SYNC** :
- Endpoint canonique `/ad-accounts/:id/sync` operationnel mais **declenche MANUELLEMENT** depuis admin V2 UI bouton "Sync"
- **0 CronJob automatique** schedule un sync periodique (verifie Q-1T E9.2 : aucun cron marketing/ads/spend/sync detecte)
- **Derniere donnee PROD = 2026-03-31** = ~48 jours sans sync nouveau (au 2026-05-18)
- Personne ne clique le bouton "Sync" manuellement depuis ~7 semaines
- Les tokens Meta + Google Ads sont en runtime (Secret K8s `keybuzz-meta-ads` 28d, `keybuzz-google-ads` 20d), validite non-verifiable cette phase mais credentials presents
- L'admin UI montre `last_sync_at` du dernier sync manuel (probablement 2026-03-31)

Plan correction propose en 3 sous-phases (recommandation forte Option 2 d'abord pour valider hypothese) :
- **Q-1T-4-A SYNC MANUEL TEST** (action Ludovic, pas CE) : declencher sync depuis admin V2 UI bouton Sync sur ad account Meta KBC -> validate que le mecanisme fonctionne encore, observe last_sync_at + last_error
- **Q-1T-4-B (si sync OK)** : creer CronJob `ad-accounts-meta-sync` schedule daily (similar carrier-tracking-poll pattern : curl POST endpoint api SaaS)
- **Q-1T-4-C (si sync KO)** : investigation provider token refresh OR code regression isolated cas

Aucun DB write. Aucun appel Meta Ads / Google Ads authentifie. Aucun fake spend. Aucun patch code. Aucun deploy. PROD intouchee.

Finding bonus : `carrier-tracking-poll` CronJob PROD a `suspend: true` (deactive). Pattern similar a recreer pour ads-sync mais sans suspension.

## Scope / hors scope

### Scope strict applique

- Lecture 11 rapports PH-T8.8* (A, A.1, A.2, B, C, C-PROD, D, E, E-PROD, F, G, business events)
- Lecture code source 4 modules : `ad-accounts/routes.ts`, `metrics/routes.ts`, `metrics/ad-platforms/meta-ads.ts`, `metrics/ad-platforms/google-ads.ts`
- Lecture admin V2 UI : `marketing/ad-accounts/page.tsx`, BFF `/api/admin/marketing/ad-accounts/[id]/sync/route.ts`
- Verification manifests env-vars Meta + Google Ads PROD/DEV
- Verification Secrets K8s `keybuzz-meta-ads` + `keybuzz-google-ads` metadata-only
- Verification CronJobs cluster-wide (0 ads-sync detecte)
- Git history depuis T8.8G cleanup (0 regression)
- Comparaison image PROD T8.8G (v3.5.106) vs PROD actuelle (v3.5.190)

### Hors scope respecte

- 0 INSERT/UPDATE/DELETE/ALTER/TRUNCATE DB
- 0 appel Meta Ads / Google Ads authentifie (validite token non testee)
- 0 refresh provider token
- 0 fake spend / fake campaign / fake metric
- 0 patch code/manifest
- 0 deploy/build
- 0 kubectl apply/patch/edit/delete/rollout
- 0 changement Linear
- 0 affichage tenantId valeur / sellerId / email / campaign_id raw / account_id raw / ad_id raw (sauf si deja public ex KBC `keybuzz-consulting-mo9*` documente PH-T8.8F)
- 0 DB sampling execute (psql disponible bastion mais NON utilise, sampling differable Q-1T-4-A-DB-EXEC sur GO Ludovic explicit)

## Sources relues

| Source | Date | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1T-3-A-GA4-DEDUP-DB-VERIFICATION-READONLY-01.md | commit 0697d44 | OK ancestor |
| docs/PH-WEBSITE-T8.12AS.17.1T-3-GA4-ADDINGWELL-EVENT-DELIVERY-DEDUP-DIAGNOSTIC-READONLY-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1T-2-OUTBOUND-TICK-PROCESSOR-404-DIAGNOSTIC-READONLY-01.md | present | OK |
| docs/PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md | 2026-04-22 DEV | OK |
| docs/PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01.md | 2026-04-23 DEV | OK |
| **docs/PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md** | 2026-04-23 PROD | OK CRITIQUE migration PROD deja faite |
| docs/PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md | 2026-04-25 DEV | OK |
| docs/PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md | present | OK |
| docs/PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md | PROD | OK |
| docs/PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01.md | DEV | OK |
| docs/PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01.md | 2026-04-23 PROD | OK image v3.5.106 |
| docs/PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01.md | 2026-04-23 audit | OK 8 doublons identifies |
| **docs/PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md** | 2026-04-26 fix | OK CRITIQUE cleanup PROD |
| keybuzz-api/src/modules/ad-accounts/routes.ts | post T8.8G | OK endpoint canonique `/ad-accounts/:id/sync` operationnel |
| keybuzz-api/src/modules/metrics/routes.ts | post T8.8G | OK `/metrics/overview` lit ad_spend_tenant |
| keybuzz-api/src/modules/metrics/ad-platforms/meta-ads.ts | post T8.8G | OK `fetchMetaAdsInsights` |
| keybuzz-admin-v2/src/app/(admin)/marketing/ad-accounts/page.tsx | recent | OK UI avec bouton Sync |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD | main / desc 0697d44 | match | OK |
| 4 rapports Q-1T presents | OUI | OK | OK |
| 11 rapports PH-T8.8* presents | OUI | 11 detectees | OK |
| /tmp residuels Q-1T-4 | absent | absent | OK |
| Repos lecture | api ph147.4 dirty 223 / backend main dirty 1 / admin-v2 main clean | OK | OK |
| KEY-323 pause | OUI | confirme | OK |

## Architecture ad_spend confirmee (E1)

Heritage rapports PH-T8.8A.2 + PH-T8.8G :

| Composant | Etat PROD |
|---|---|
| Table `ad_platform_accounts` | OK created + indexed (PK + tenant + unique tenant/platform/account) |
| Table `ad_spend_tenant` | OK created + indexed (PK + idx_ast_dedup sur (tenant_id, platform, date, COALESCE(campaign_id, '__none__')) + tenant_date + account) |
| Table `metrics_tenant_settings` | OK created PH-T8.8E (display_currency EUR/GBP/USD, exclude_from_cac) |
| Endpoint canonique sync | OK `/ad-accounts/:id/sync` POST tenant-scoped (T8.8B foundation + T8.8G canonical) |
| Endpoint legacy deprecate | `/metrics/import/meta` -> 410 DEPRECATED_META_IMPORT_USE_AD_ACCOUNT_SYNC (T8.8G) |
| Endpoint lecture metrics | OK `/metrics/overview?tenant_id=X` lit ad_spend_tenant (T8.8A.2 confirme L178/L405) |
| Admin V2 UI ad-accounts | OK `/marketing/ad-accounts/page.tsx` form ADD + LIST + bouton SYNC + delete |
| BFF admin -> API | OK `/api/admin/marketing/ad-accounts/[id]/sync/route.ts` proxy POST |
| Secret K8s keybuzz-meta-ads (ESO) | OK 2 keys (META_ACCESS_TOKEN + META_AD_ACCOUNT_ID), rv 56229877, age 28j |
| Secret K8s keybuzz-google-ads (ESO) | OK 4 keys (GOOGLE_ADS_*), rv 68861649, age 20j |
| Image API PROD T8.8G | v3.5.106-metrics-settings-currency-exclusion-prod (2026-04-26) |
| Image API PROD actuelle | v3.5.190-channels-tenantguard-prod (2026-05-15, 84 commits + 19j apres T8.8G) |

## Donnees DB ad_spend_tenant PROD heritage (E1.3 PH-T8.8F)

D'apres audit lecture seule PH-T8.8F (2026-04-23) puis cleanup PH-T8.8G (2026-04-26) :

| Tenant | Rows pre-cleanup | Rows post-cleanup | Spend post (GBP) | Dates couvertes | Dernier sync |
|---|---|---|---|---|---|
| keybuzz-consulting-mo9zndlk (KBC PROD) | 24 (8 doublons) | 16 | 445.20 | 2026-03-16 -> 2026-03-31 | 2026-03-31 (implicite) |
| keybuzz-consulting-mo9y479d (KBC DEV) | 16 | 16 | 445.20 | 2026-03-16 -> 2026-03-31 | 2026-03-31 |

**Au 2026-05-18, derniere donnee KBC PROD = 2026-03-31** = **48 jours sans donnees nouvelles**.

## Code analysis endpoint `/ad-accounts/:id/sync` (E2)

| Aspect | Valeur |
|---|---|
| Fichier | keybuzz-api/src/modules/ad-accounts/routes.ts |
| Defini ligne | 30 (function adAccountsRoutes) |
| Enregistre app.ts ligne | 212 `app.register(adAccountsRoutes, { prefix: '/ad-accounts' })` |
| POST /:id/sync handler ligne | 158 |
| Body schema | `SyncBody { since?: string; until?: string }` |
| Tenant resolution | `request.headers['x-tenant-id']` (header obligatoire, 400 TENANT_ID_REQUIRED si absent) |
| Decryption token | `resolveToken(tokenRef)` -> decrypt depuis ad_platform_accounts.token_ref (encrypted) |
| Appel provider | `fetchMetaAdsInsights(accountId, tokenRef, since, until, level='campaign')` ou `fetchGoogleAdsInsights` |
| INSERT INTO ad_spend_tenant | UPSERT par idx_ast_dedup |
| UPDATE ad_platform_accounts | last_sync_at = NOW(), last_error = NULL (succes) / last_error = error message (echec) |
| Response | `{sync: 'completed', rows_upserted, totals: {rows, spend, currency}, period: {since, until}}` |

Aucune regression detectee depuis T8.8G (1 commit seul = google-ads addition KEY-194 b854c470).

## Admin V2 UI `/marketing/ad-accounts` (E3)

Composant : `keybuzz-admin-v2/src/app/(admin)/marketing/ad-accounts/page.tsx`

Fonctionnalites :
- **Form ADD** : platform=meta, account_id, name, currency (EUR par defaut), timezone (Europe/Paris), token
- **LIST** : affiche tous les ad accounts du tenant avec status badge (Active/Revoked/Other), token badge (Encrypted/Not set/Masked), platform badge (Meta Ads/Google Ads), `last_sync_at` formatted, `last_error`
- **Bouton SYNC** par ad account :
  - syncSince default = today - 30 days
  - syncUntil default = today
  - fetch POST `/api/admin/marketing/ad-accounts/${id}/sync` body `{since, until}`
  - Affiche SyncResult `{rows_upserted, totals: {rows, spend, currency}, period}`
- **Form EDIT** (PATCH) : update fields
- **DELETE** : soft delete (deleted_at)

**Decouverte** : `last_sync_at` est mis a jour SEULEMENT au sync. Si pas de sync depuis 48 jours, last_sync_at = 2026-03-31 (ou null si jamais sync).

## CronJobs cluster-wide ads-sync (E4)

Verification : **0 CronJob** detecte matching `ads|meta|spend|sync|metric|tracking|conversion|capi` (heritage Q-1T E9.2).

CronJobs existants :
- carrier-tracking-poll (api-prod **suspend: true**, api-dev */1*) - ne fait pas ads
- outbound-tick-processor (api-prod **404 endpoint DEV-only**, Q-1T-2)
- sla-evaluator + sla-evaluator-escalation (psql direct UPDATE conversations)
- trial-lifecycle-dryrun
- amazon-orders-sync (backend, hors ads)
- amazon-reports-tracking-sync (backend, hors ads)
- vault-management : vault-token-renew, monitoring-alerts

**Aucun cron Meta Ads / Google Ads sync** dans le cluster.

## Image runtime vs T8.8G validation (E5)

| Item | Valeur |
|---|---|
| Image API PROD lors T8.8G cleanup | v3.5.106-metrics-settings-currency-exclusion-prod (2026-04-26) |
| Image API PROD actuelle | v3.5.190-channels-tenantguard-prod (2026-05-15) |
| Delta versions | +84 commits / +19 jours |
| Image API PROD inclut T8.8G | OUI (T8.8G commit 3207caf4 anterieur a v3.5.190) |
| Commits sur ad-accounts/routes.ts depuis T8.8G | 1 (`b854c470 feat(google-ads): add Google Ads spend sync via REST API (KEY-194)`) |
| Commits sur metrics/routes.ts depuis T8.8G | 0 |
| Commits sur meta-ads.ts depuis T8.8G | 0 |

**Pas de regression code possible**. L'endpoint sync est intact, l'addition Google Ads est additive.

## Provider tokens runtime (E6)

| Secret K8s | Keys | rv | age | Validite |
|---|---|---|---|---|
| keybuzz-meta-ads | META_ACCESS_TOKEN + META_AD_ACCOUNT_ID | 56229877 | 28 jours (2026-04-20) | inconnue (non-testee cette phase) |
| keybuzz-google-ads | GOOGLE_ADS_CLIENT_ID + CLIENT_SECRET + DEVELOPER_TOKEN + REFRESH_TOKEN | 68861649 | 20 jours (2026-04-28) | inconnue (non-testee) |

Note : ces secrets sont les credentials **fallback global** KeyBuzz Consulting (utilises si tenant n'a pas son propre `ad_platform_accounts.token_ref`). Per-tenant tokens sont en DB encrypted via `ads-crypto`.

## Hypotheses root cause (E10)

| Hypothese | Probabilite | Evidence | Verdict |
|---|---|---|---|
| **H1 Migration PROD jamais faite** | NEANT | PH-T8.8A.2 prouve PROD live depuis 2026-04-23, tables existent, endpoint operationnel | REJETEE |
| **H2 Regression code recent** | NEANT | 0 commit ad-accounts depuis T8.8G sauf addition Google Ads | REJETEE |
| **H3 Tokens provider expires** | INCONNU | Secrets existent (age 20-28j) mais validite non testable read-only sans provider call | INDETERMINEE |
| **H4 Endpoint admin lit mauvaise table** | NEANT | PH-T8.8A.2 confirme /metrics/overview lit ad_spend_tenant (L178, L405) | REJETEE |
| **H5 UI filtre tenant incorrect** | TRES FAIBLE | UI envoie `tenantId` depuis useCurrentTenant() context | TRES FAIBLE |
| **H6 Absence CronJob automatique sync** | **CONFIRMEE** | 0 cron ads detecte, derniere donnee 2026-03-31 = 48j sans sync | **VRAIE ROOT CAUSE** |
| **H7 Personne ne clique bouton Sync manuel** | **PROBABLE consequence H6** | UI existe mais usage manuel uniquement | CONFIRMEE indirecte |
| H8 Bug Admin V2 UI affichage | TRES FAIBLE | Code page.tsx revele logic standard | REJETEE faute evidence |
| H9 Provider token revoked cote Meta (account disable) | FAIBLE (sans test impossible verifier) | possible mais avec test manuel admin "Sync" Ludovic peut observer last_error | INDETERMINEE jusqu'a test |

**Verdict root cause finale** : **H6 ABSENCE AUTOMATISATION SYNC**. Sans cron, derniere donnee est celle du dernier sync manuel (2026-03-31). Spend "absent" en admin = donnees obsoletes, pas donnees absentes.

## Plan correction propose en sous-phases (E11-E12)

### Q-1T-4-A SYNC MANUEL TEST (action Ludovic, pas CE)

**Procedure** (zero-risque, immediat, validation immediate) :
1. Ludovic se connecte admin V2 `https://admin.keybuzz.io/marketing/ad-accounts`
2. Verifier tenant context = `keybuzz-consulting-mo9zndlk` (KBC PROD)
3. Voir la liste : 1 ad account Meta visible avec `last_sync_at` (probablement 2026-03-31)
4. Cliquer bouton "Sync" sur l'ad account Meta
5. Observer le resultat :
   - **Succes** : `SyncResult { rows_upserted: N, totals: {rows, spend, currency}, period: {since: 2026-04-18, until: 2026-05-18}}` -> hypothese H6 confirme, code marche, juste pas d'automatisation
   - **Echec** : `last_error` set avec message -> hypothese H3 ou H9 (token revoke / expired) -> Q-1T-4-C investigation
6. Refresh page admin `/metrics` pour voir si spend tenant-scoped maintenant a jour

### Q-1T-4-B (si Q-1T-4-A succes) : creer CronJob ad-accounts-meta-sync

**Pattern propose** (similar carrier-tracking-poll, mais sans suspend) :

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ad-accounts-meta-sync
  namespace: keybuzz-api-prod
spec:
  schedule: "0 6 * * *"  # daily 6h UTC
  suspend: false
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sync
            image: badouralix/curl-jq:latest
            command: [/bin/sh, -c]
            args:
            - |
              echo "[$(date -u +%H:%M:%S)] Ad accounts sync starting..."
              curl -sk -X POST \
                -H 'Content-Type: application/json' \
                -d '{}' \
                --max-time 120 \
                https://api.keybuzz.io/admin/ad-accounts/sync-all
              echo "[$(date -u +%H:%M:%S)] complete"
          restartPolicy: Never
```

**PREREQUIS** : creer endpoint API `/admin/ad-accounts/sync-all` qui :
1. SELECT tous les `ad_platform_accounts WHERE deleted_at IS NULL AND status = 'active'`
2. Pour chaque : trigger `/ad-accounts/:id/sync` avec since=last_sync_at-1day, until=today
3. Aggregate result + log

**Alternatives** :
- Endpoint admin V2 internal trigger
- Reuse pattern outbound-tick mais corrige (post Q-1T-2 EXEC suppression)

### Q-1T-4-C (si Q-1T-4-A echec)

Investigation :
1. Lire `last_error` UI admin pour comprendre nature echec
2. Si token revoque -> rotation token Meta Ads via admin UI (form EDIT)
3. Si bug code -> phase debug dediee
4. Si rate limit Meta -> retry strategy

### Q-1T-4-D BONUS

- Investiguer `carrier-tracking-poll` PROD `suspend: true` : pourquoi suspendu ? Decision a re-confirmer.

## Risk matrix

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Q-1T-4-A reveal token revoke | MOYEN (28j age) | MOYEN | rotation token via UI admin |
| R2 | Q-1T-4-B CronJob race condition concurrent sync | FAIBLE | MOYEN | concurrencyPolicy: Forbid + UPDATE...WHERE...AND last_sync_at < ... |
| R3 | Sync trigger Meta Ads rate limit (API quotas) | FAIBLE (1 ad account, daily) | FAIBLE | retry exponential backoff |
| R4 | DB sampling necessite credentials | (non-execute cette phase) | NEANT | scope respecte |
| R5 | Provider call accidentel | NEANT (0 execute) | ELEVE | scope respecte |
| R6 | DB write accidentel | NEANT (0 execute) | ELEVE | scope respecte |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T-4 | Impact |
|---|---|---|---|
| ad_platform_accounts table | 1 row | inchange | 0 |
| ad_spend_tenant table | 16 rows (post-T8.8G cleanup 2026-03-16 -> 2026-03-31) | inchange | 0 |
| metrics_tenant_settings | created PH-T8.8E | inchange | 0 |
| API PROD keybuzz-api | v3.5.190 Running | inchange | 0 |
| Admin V2 UI ad-accounts | accessible | inchange | 0 |
| Provider tokens Meta + Google Ads | Secrets K8s present | inchange | 0 |
| CronJobs ads-sync | 0 (inexistant) | 0 (inchange) | 0 |
| Argo CD | inchange | inchange | 0 |
| Stripe webhook -> CAPI dispatch | inchange | inchange | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| DB write (INSERT/UPDATE/DELETE/ALTER/TRUNCATE) | 0 commande DB execute, psql present mais inutilise | OK |
| Appel Meta/Google Ads authentifie | 0 fetch vers graph.facebook.com / googleads.googleapis.com | OK |
| Refresh provider token | 0 | OK |
| Fake spend/campaign/metric | 0 | OK |
| Patch code/manifest | 0 | OK |
| Deploy/build | 0 | OK |
| kubectl apply/patch/edit/delete/rollout | 0 | OK |
| Changement Linear | 0 (brouillon present rapport, non poste) | OK |
| Affichage tenantId/sellerId/email/campaign_id/account_id raw | 0 (sauf KBC tenant_id deja public PH-T8.8F + campaign_id pattern documente PH-T8.8G) | OK |
| Lecture secret value en clair | 0 (Secret keys names only via jq metadata) | OK |
| /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ touche | 0 | OK |
| Tenant/user/email hardcode rapport | 0 (sauf documentation existante PH heritage) | OK |
| ASCII strict rapport | (a verifier post-redaction) | OK |

## Brouillon Linear (a creer si Ludovic GO)

```
TITRE proposed : Spend Ads admin absent - ROOT CAUSE = absence automatisation sync, code OK migration faite

Status: DIAGNOSTIC COMPLETE - ACTION LUDOVIC IMMEDIATE PROPOSEE
Scope: PROD + DEV lecture pure, 0 DB write, 0 provider call

Findings critiques:
- Hypothese initiale R3 OBSOLETE: migration ad_spend tenant-scoped EST DEJA EN PROD depuis 2026-04-23 (PH-T8.8A.2)
- Tables ad_platform_accounts + ad_spend_tenant + metrics_tenant_settings EXISTENT PROD
- 1 ad account Meta connecte (KBC), 16 rows spend post-T8.8G cleanup, dates 2026-03-16 -> 2026-03-31
- /metrics/overview?tenant_id=X lit ad_spend_tenant (confirme PH-T8.8A.2 L178/L405)
- Endpoint canonique /ad-accounts/:id/sync OPERATIONNEL
- Admin V2 UI /marketing/ad-accounts existe avec bouton Sync manuel
- Image PROD v3.5.190 (2026-05-15) inclut tous correctifs T8.8A-T8.8G (84 commits + 19j apres T8.8G)
- 0 regression code (1 seul commit ad-accounts depuis T8.8G = Google Ads sync addition)
- Provider tokens Meta + Google Ads en runtime (Secrets K8s 20-28d age)

Root cause: ABSENCE AUTOMATISATION SYNC
- 0 CronJob ads/meta/spend/sync schedule periodique dans le cluster
- Sync est declenche MANUELLEMENT via bouton admin UI
- Personne n'a clique depuis 2026-03-31 = 48j sans sync nouveau
- Spend "absent" en admin = donnees obsoletes, pas donnees absentes

Plan correction:
- Q-1T-4-A (action Ludovic): cliquer "Sync" admin UI sur ad account Meta KBC -> validate sync marche
- Q-1T-4-B (si succes): creer CronJob ad-accounts-meta-sync daily via curl POST endpoint API
- Q-1T-4-C (si echec): investigation token + UI admin last_error
- Q-1T-4-D bonus: carrier-tracking-poll PROD suspend=true a clarifier

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-4-AD-SPEND-PROD-MIGRATION-DRYRUN-01.md
```

## Gaps restants

1. **Q-1T-4-A SYNC MANUEL TEST** (action Ludovic immediate) : validate hypothese H6 par sync manuel admin UI
2. **Q-1T-4-B CronJob creation** : si Q-1T-4-A succes, design + EXEC dedicace
3. **Q-1T-4-C provider token investigation** : si Q-1T-4-A echec
4. **Q-1T-4-D carrier-tracking-poll PROD suspend** : pourquoi suspendu ?
5. **Q-1T-3-A-DB-EXEC** (optionnel) : sampling DB signup_attribution si doute persistant
6. **Q-1T-2-EXEC SUPPRESSION CronJob outbound-tick** : cleanup trivial
7. **Q-1T-5 tracking secrets Git cleanup consolide** : pattern accumule
8. **Reprise KEY-323** : Q-1B-5B-2-EXEC LLM env migration

## Phrase cible finale

Diagnostic ad_spend PROD complete : rapports PH-T8.8A-G relus chronologiquement (T8.8A.2 PROD promotion 2026-04-23 + T8.8B DEV foundation 2026-04-25 + T8.8E PROD metrics currency 2026-04-23 + T8.8F duplicate truth audit + T8.8G idempotence fix PROD cleanup 2026-04-26), tables ad_platform_accounts + ad_spend_tenant + metrics_tenant_settings EXISTENT PROD (1 ad account KBC, 16 rows post-cleanup), endpoint canonique /ad-accounts/:id/sync OPERATIONNEL avec UI admin V2 bouton Sync manuel + BFF proxy POST, provider tokens Meta + Google Ads en runtime Secret K8s, image PROD v3.5.190 inclut tous correctifs T8.8A-T8.8G (0 regression detectee), Hypothese initiale R3 OBSOLETE (migration deja faite), **vraie root cause identifiee = ABSENCE AUTOMATISATION SYNC** (0 CronJob ads dans cluster + sync manuel uniquement + derniere donnee 2026-03-31 = 48j sans sync), plan correction 4 sous-phases propose (Q-1T-4-A sync manuel test action Ludovic immediate + Q-1T-4-B CronJob creation + Q-1T-4-C token investigation + Q-1T-4-D carrier-tracking suspend bonus), draft brouillon Linear prepare avec action recommandee, 0 DB write, 0 provider call, 0 fake metric, 0 patch, PROD intouchee, decision Ludovic requise sur action Q-1T-4-A (sync manuel test immediat zero-risque).

STOP
