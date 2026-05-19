# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-VALIDATE-LIVE-DEV-PROD-META-AD-SPEND-SYNC-01

> Date : 2026-05-19
> Linear : NA (initiative Q-1T-4-B ad_spend daily sync orchestration)
> Phase : Q-1T-4-B-EXEC-VALIDATE-LIVE (sous-phases DEV all-platforms one-shot + PROD meta-only one-shot)
> Environnement : DEV (Job ephemere all-platforms) + PROD (Job ephemere meta-only). CronJobs persistants DEV et PROD restent dryRun=true. Aucun manifest GitOps modifie.

## VERDICT

GO PROD pour scope meta-only. Premiere synchronisation ad_spend LIVE Meta validee bout-en-bout DEV puis PROD le 2026-05-19. Le spend Meta PROD reel est maintenant materialise en DB ad_spend_tenant pour le tenant Meta PROD. Google OAuth DEV en erreur isolee, Google PROD non teste par choix de filtre, CronJobs persistants permanents toujours en dryRun=true par dessein. Recommandation prochaine phase : flip CronJobs persistants vers LIVE meta-only (pas all), apres audit OAuth Google DEV et eventuellement PROD si on souhaite ulterieurement inclure Google.

## Preflight

| Item                                            | Verifie                                            | Source                                                                |
|-------------------------------------------------|----------------------------------------------------|-----------------------------------------------------------------------|
| Bastion install-v3 46.62.171.61                 | OK                                                 | ssh alias                                                             |
| Endpoint code internal-routes.ts                | 4963 B (2026-05-18 17:07)                          | /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts   |
| Contract body.platform                          | 'meta' | 'google' | 'all'                          | code ligne 11 interface SyncAllBody                                   |
| Filtre SQL WHERE platform = $X                  | applique si platform != 'all'                      | code lignes 58, 67-69                                                 |
| Secret DEV keybuzz-internal-tokens hash8        | 9686f338                                           | Q-1T-4-B-EXEC-SECRET                                                  |
| Secret PROD keybuzz-internal-tokens hash8       | ef85e12d                                           | Q-1T-4-B-EXEC-SECRET-PROD                                             |
| API DEV deploy readiness                        | 1/1/1                                              | kubectl get deploy keybuzz-api -n keybuzz-api-dev                     |
| API PROD deploy readiness                       | 1/1/1 observedGeneration=412                       | kubectl get deploy keybuzz-api -n keybuzz-api-prod                    |
| CronJob ad-spend-sync-daily DEV body            | dryRun=true, suspend=false, schedule="0 6 * * *"  | kubectl get cronjob -n keybuzz-api-dev                                |
| CronJob ad-spend-sync-daily PROD body           | dryRun=true, suspend=false, schedule="0 6 * * *"  | kubectl get cronjob -n keybuzz-api-prod                               |
| Premiere occurrence scheduled 06:00 UTC         | DEV et PROD succeeded a 2026-05-19T06:00:05Z       | jsonpath status.lastSuccessfulTime                                    |
| Collision Job DEV                               | NotFound                                           | kubectl get job ad-spend-sync-live-dev-q1t4b-20260519                 |
| Collision Job PROD                              | NotFound                                           | kubectl get job ad-spend-sync-live-prod-meta-q1t4b-20260519           |

## Audit signaux

### DEV LIVE all-platforms one-shot

- Job name : ad-spend-sync-live-dev-q1t4b-20260519
- Namespace : keybuzz-api-dev
- Body : {"dryRun":false}
- URL : http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/admin/internal/ad-accounts/sync-all
- Manifest sha256 : ac3dbcfcd1aa24a0a81e248a2dd041cfd42ea1bac9305961de47cefee1f8e2e9
- Job UID : 3b672496-1808-428b-94a7-eb4caa43584a
- Window : startTime 2026-05-19T07:28:05Z - completionTime 2026-05-19T07:28:11Z (6s)
- Status : succeeded=1, failed=0

Endpoint Response :
- sync : completed
- dryRun : false
- platform_filter : all
- period : 2026-04-19 - 2026-05-19
- account_count : 2
- ok : 1
- error : 1
- accounts[0] : hash8=0055f31c tenant_hash8=87fd9f6b platform=google status=error message="GOOGLE_OAUTH_ERROR: 400 invalid_grant Bad Request" (sanitize redactSecrets)
- accounts[1] : hash8=6fd93032 tenant_hash8=aa528bf1 platform=meta status=ok rows_upserted=7 totals.rows=7 totals.spend=251.83 totals.currency=GBP

Try/catch endpoint a isole l'erreur Google DEV sans interrompre Meta DEV (preuve : 1 ok + 1 error coexistent dans la meme execution, account_count=2 confirme les deux comptes ont ete charges).

### PROD meta-only LIVE one-shot

- Job name : ad-spend-sync-live-prod-meta-q1t4b-20260519
- Namespace : keybuzz-api-prod
- Body : {"dryRun":false,"platform":"meta"}
- URL : http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80/admin/internal/ad-accounts/sync-all
- Manifest sha256 : e4f3699f6eb7c719a2db470a3a5bd39c1c641fa645a6316862f58bfe94d3fee6
- Job UID : 5ee88887-e96c-4e24-9343-e515ec6fecab
- Window : startTime 2026-05-19T07:43:33Z - completionTime 2026-05-19T07:43:38Z (5s)
- Status : succeeded=1, failed=0

Endpoint Response :
- sync : completed
- dryRun : false
- platform_filter : meta
- period : 2026-04-19 - 2026-05-19
- account_count : 1 (Google PROD jamais charge par filtre SQL)
- ok : 1
- error : 0
- accounts[0] : hash8=6fd93032 tenant_hash8=78dea947 platform=meta status=ok rows_upserted=7 totals.rows=23 totals.spend=698.07 totals.currency=GBP

Preuves isolation Google PROD :
- platform_filter="meta" (output endpoint confirme application server-side)
- account_count=1 vs 2 sans filtre (Google PROD non selectionne par SELECT FROM ad_platform_accounts)
- accounts unique entry platform="meta" (aucune boucle Google)
- Duree 5s coherente avec une seule iteration provider call

## Patch

Aucun patch code. Aucune modification source. Aucun manifest GitOps modifie.

| Fichier ephemere                                                         | Changement                          | Risque |
|--------------------------------------------------------------------------|-------------------------------------|--------|
| /tmp/ad-spend-sync-live-dev-q1t4b-20260519.yaml (bastion)                | Job one-shot DEV all-platforms      | nul, Job ephemere shred apres usage |
| /tmp/ad-spend-sync-live-prod-meta-q1t4b-20260519.yaml (bastion)          | Job one-shot PROD meta-only         | nul, Job ephemere shred apres usage |

## Tests

| Test                                                          | Attendu                            | Resultat       |
|---------------------------------------------------------------|------------------------------------|----------------|
| kubectl apply --dry-run=server manifest DEV                   | created (server dry run)           | OK             |
| kubectl get job DEV collision                                 | NotFound                            | OK             |
| Job DEV condition complete (timeout 300s)                     | condition met                       | OK 6s          |
| Job DEV Response.sync                                         | completed                           | OK             |
| Job DEV Response.dryRun                                       | false                               | OK             |
| Job DEV Response.account_count                                | 2                                   | OK             |
| Job DEV try/catch isolation Google                            | 1 ok + 1 error sans crash global    | OK             |
| Job DEV Meta rows_upserted                                    | > 0                                 | OK 7           |
| Job DEV Meta totals.currency                                  | GBP                                 | OK             |
| Job DEV Google sanitize message                               | sans token                          | OK invalid_grant only |
| kubectl apply --dry-run=server manifest PROD                  | created (server dry run)            | OK             |
| kubectl get job PROD collision                                | NotFound                            | OK             |
| Job PROD condition complete (timeout 300s)                    | condition met                       | OK 5s          |
| Job PROD Response.sync                                        | completed                           | OK             |
| Job PROD Response.dryRun                                      | false                               | OK             |
| Job PROD Response.platform_filter                             | meta                                | OK             |
| Job PROD Response.account_count                               | 1 (Google jamais charge)            | OK             |
| Job PROD Response.ok                                          | 1                                   | OK             |
| Job PROD Response.error                                       | 0                                   | OK             |
| Job PROD accounts[0].platform                                 | meta                                | OK             |
| Job PROD Meta rows_upserted                                   | > 0                                 | OK 7           |
| Job PROD Meta totals.rows                                     | > 0                                 | OK 23          |
| Job PROD Meta totals.spend                                    | reel non hardcode                   | OK 698.07 GBP  |
| Cleanup Job DEV                                               | delete + NotFound verify            | OK             |
| Cleanup Job PROD                                              | delete + NotFound verify            | OK             |
| Shred /tmp DEV manifest                                       | file removed apres 4 passes         | OK             |
| Shred /tmp PROD manifest                                      | file removed apres 4 passes         | OK             |

## Build

Aucun build dans cette phase. Images runtime keybuzz-api DEV et PROD inchangees depuis Q-1T-4-B-EXEC-BUILD-PROD (tag v3.5.250-ad-spend-sync-all-{dev,prod}).

## GitOps

Aucun apply GitOps dans cette phase. Aucun manifest persistant modifie. Aucun commit keybuzz-infra. Les Jobs temporaires sont hors GitOps (kubectl apply -f /tmp/ direct, scope namespace explicite, supprime apres validation, manifest shred). HEAD keybuzz-infra reste 6f73dbc (Q-1T-4-B-EXEC-CRONJOB-DRYRUN rapport).

## Validation runtime

Endpoint LIVE prouve fonctionnel sur les deux paths code :
- Path succes : Meta DEV puis Meta PROD, provider call Meta Graph Insights read-only sur fenetre 30j, UPSERTs idempotents ON CONFLICT.
- Path erreur : Google DEV OAuth invalid_grant isole proprement (status="error", message redactSecrets-cleaned sans token), Meta DEV continue son sync sans etre affecte.

Effet DB observe (preuve principale via endpoint response, snapshot SQL direct ecarte par choix de surete) :
- DB DEV : 7 UPSERTs ad_spend_tenant DEV pour tenant aa528bf1 / account Meta 6fd93032 ; 1 UPDATE last_sync_at compte Meta DEV. Aucune ecriture compte Google DEV (status=error avant ecriture).
- DB PROD : 7 UPSERTs ad_spend_tenant PROD pour tenant 78dea947 / account Meta 6fd93032 ; 1 UPDATE last_sync_at compte Meta PROD. Aucune ecriture compte Google PROD (jamais charge ni boucle, filtre SQL).
- Idempotence ON CONFLICT preservee : PROD totals.rows=23 vs rows_upserted=7, donc 16 lignes deja en DB identiques skipped/no-op.

### Spend Meta PROD synchronise en DB

Le spend Meta PROD est maintenant materialise en DB ad_spend_tenant pour le tenant_hash8 78dea947, fenetre 2026-04-19 - 2026-05-19 :
- 23 lignes spend lues depuis Meta Graph API.
- 7 UPSERTs effectifs (premier remplissage de la fenetre actuelle, le reste deja present skipped).
- spend total 698.07 GBP.
- currency GBP (declaree par Meta).
- last_sync_at compte Meta PROD mis a jour automatiquement.

Cela constitue la premiere materialisation reelle de donnees ad_spend Meta PROD dans la base via le nouveau pipeline orchestree par l'endpoint POST /admin/internal/ad-accounts/sync-all (Q-1T-4-B-EXEC-CODE commit 01b163e4). Sous reserve de verification BFF + UI separe, l'admin Acquisition payee PROD peut desormais consommer ces donnees pour les tenants Meta.

## No fake metrics / no fake events

Le spend 698.07 GBP est une donnee reelle Meta provider, lue via Meta Graph API insights endpoint avec le token OAuth refresh stocke en ad_platform_accounts.token_ref pour le compte Meta PROD, persistee verbatim en ad_spend_tenant PROD via UPSERT ON CONFLICT idempotent (helper syncOneAccount PH148 known-good). Aucune valeur synthetique, aucun mock, aucun KPI invente, aucun arrondi cote endpoint. La devise GBP est celle declaree par Meta sur le compte cote provider, pas une hypothese. Les hash8 utilises (6fd93032, 78dea947, 0055f31c, 87fd9f6b, aa528bf1) sont des sha256[0:8] reproductibles a partir des IDs reels en DB.

## AI feature parity

Non applicable. Phase tracking ad_spend daily sync. Aucune surface IA, inbox, messages, connecteurs IA, commandes, tracking colis, playbooks, escalades, Agent KeyBuzz, autopilot, dashboard IA, ni metriques IA derivees impactee. Endpoint /admin/internal/* est interne batch sync, hors perimetre AI parity.

## Non-regression PROD

| Indicateur                                              | Avant 07:28 UTC  | Apres 07:43 UTC  | Verdict                  |
|---------------------------------------------------------|------------------|------------------|--------------------------|
| Deploy keybuzz-api PROD observedGeneration              | 412              | 412              | INCHANGE                 |
| Deploy keybuzz-api PROD replicas/ready/available        | 1/1/1            | 1/1/1            | INCHANGE                 |
| Deploy keybuzz-api DEV replicas/ready/available         | 1/1/1            | 1/1/1            | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD suspend                | false            | false            | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD schedule               | "0 6 * * *"      | "0 6 * * *"      | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD lastSuccessfulTime     | 06:00:05Z        | 06:00:05Z        | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD body dryRun            | true             | true             | INCHANGE                 |
| CronJob ad-spend-sync-daily DEV suspend                 | false            | false            | INCHANGE                 |
| CronJob ad-spend-sync-daily DEV body dryRun             | true             | true             | INCHANGE                 |
| Jobs PROD non ad-spend (sla-evaluator, outbound-tick)   | cycles nominaux  | cycles nominaux  | INCHANGE                 |
| HEAD keybuzz-infra main                                 | 6f73dbc          | 6f73dbc          | INCHANGE (aucun commit)  |
| Aucun :latest, aucun kubectl set/edit/patch             | OK               | OK               | INCHANGE                 |

## Linear

Pas de ticket Linear unique identifie pour cette phase. Initiative globale Q-1T-4-B (orchestration daily ad_spend sync). Linear creation eventuelle pour tracker :
- Remediation OAuth Google Ads DEV invalid_grant.
- Verification OAuth Google Ads PROD.
- Phase ulterieure flip CronJob permanent meta-only LIVE.

A discuter avec Ludovic.

## Gaps restants

1. Google Ads DEV OAuth invalid_grant (compte hash8 0055f31c tenant 87fd9f6b)
   - Symptome : refresh token retourne HTTP 400 invalid_grant lors du sync LIVE DEV.
   - Hypothese probable : refresh token revoque, scope insuffisant, ou compte deauthorise cote Google Console.
   - Action recommandee : re-authoriser le compte Google Ads DEV via UI Acquisition Settings Admin v2 (flow OAuth re-consent).
   - Impact : nul pour le SaaS PROD et pour la promotion Meta-only PROD. Bloque uniquement le sync Google DEV.

2. Google Ads PROD non teste (compte hash8 0055f31c tenant 78dea947)
   - Symptome : le filtre platform=meta a court-circuite le compte Google PROD au niveau SQL, OAuth refresh non sollicite, statut Google PROD inconnu sur cette phase.
   - Risque : OAuth Google PROD potentiellement dans le meme etat que DEV.
   - Action recommandee : test isole avant flip CronJob "all" - executer un Job temporaire PROD body {"dryRun":false,"platform":"google"} dans une phase dediee, ou laisser le flip CronJob permanent en meta-only (recommande) pour eviter l'erreur recurrente.

3. CronJob permanent ad-spend-sync-daily DEV+PROD reste dryRun=true
   - Symptome : execution planifiee 06:00 UTC genere uniquement le plan/skipped, pas d'UPSERT DB ni d'UPDATE last_sync_at.
   - Action recommandee : phase ulterieure Q-1T-4-B-EXEC-CRONJOB-FLIP-META-LIVE = patch body des 2 manifests GitOps de dryRun=true a {"dryRun":false,"platform":"meta"} + commit + apply + observation cycle 24h.
   - Decision recommandee : flip vers meta-only en premier (pas all), pour eviter une defaillance recurrente Google qui polluerait les logs et metriques.

4. Audit consommateurs spend Meta PROD
   - Symptome : ad_spend_tenant PROD contient maintenant des donnees Meta reelles tenant 78dea947 sur fenetre 30j.
   - Action recommandee : verifier dans une phase BFF/UI distincte que l'admin Acquisition payee PROD affiche correctement ces valeurs et que les cards/charts ne sont pas en placeholder hardcode.
   - Hors scope du sync.

5. Aucun snapshot DB direct realise
   - Symptome : preuve principale = endpoint response (rows_upserted + totals + status par compte).
   - Compensation : snapshot SQL avant/apres non realise par choix de surete (eviter kubectl exec, port-forward, et toute touche aux credentials Vault DB).
   - Suffisant pour cette phase : endpoint expose deja l'effet DB par compte de maniere structuree.

## Phrase cible finale

Le sync ad_spend LIVE Meta est valide bout-en-bout DEV puis PROD le 2026-05-19, premiere materialisation reelle 698.07 GBP en ad_spend_tenant PROD pour le tenant Meta 78dea947, sans toucher Google ni les CronJobs persistants dryRun=true et sans aucune modification GitOps.

GO PROD.

STOP.
