# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking) ; KEY-346 (LP conversion)
> Phase : PH-SAAS-T8.12AS.20.9B APPLY API DEV Meta CAPI EMQ
> Environnement : DEV uniquement (migration DEV 032 appliquee + rollout image)

## VERDICT

GO APPLY API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B

- Migration 032 appliquee sur DB DEV `keybuzz` avant rollout image : colonnes `client_ip_address text NULL` + `client_user_agent text NULL` ajoutees, 10 rows preserves, idempotent.
- Manifest `k8s/keybuzz-api-dev/deployment.yaml` bumpe v3.5.252 -> v3.5.253-meta-capi-emq-dev.
- Infra commit `56b3c30` push origin/main avant apply.
- kubectl apply : `deployment.apps/keybuzz-api configured`.
- Rollout : `deployment "keybuzz-api" successfully rolled out`.
- Pod nouveau `keybuzz-api-86f86f8c58-tpwr2` Ready 1/1.
- Runtime digest DEV : `sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4` MATCH GHCR push.
- Triple match : last-applied = manifest spec = pod imageID.
- Smoke /health : HTTP 200 `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}`.
- 10 markers PH-20.9B LIVE dans `/app/dist` pod runtime : client_ip_address=8, client_user_agent=8, event_source_url=6, external_id_hash=3, metaCapiHash=6, first_name_hash=3, last_name_hash=3, phone_hash=3, safeEventSourceUrl=2, x-forwarded-for=4.
- Logs API DEV : 0 error / 0 column-not-exist.
- Runtime API PROD `v3.5.251` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- 0 event Meta envoye. 0 test register/checkout/Stripe.

STOP avant QA DEV.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T12:30:17Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD avant | b654e9f (post-rapport PUSH IMAGE DEV) |
| Runtime API DEV avant | v3.5.252-billing-tenant-id-fallback-dev |
| Runtime API PROD avant | v3.5.251-billing-tenant-id-fallback-prod |
| GHCR config digest match | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f OK |

## E1 MIGRATION 032 SOURCE + RUNNER

| Item | Resultat | Verdict |
|---|---|---|
| Migration 032 source path | /opt/keybuzz/keybuzz-api/migrations/032_signup_attribution_client_metadata.sql | OK |
| Size | 967 bytes | OK |
| Statement | ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS client_ip_address TEXT, client_user_agent TEXT | OK |
| Destructive SQL | 0 (false positive sur commentaire "Reversible : DROP COLUMN..." dans header) | OK |
| Idempotent | OUI (IF NOT EXISTS) | OK |
| Runner officiel | /opt/keybuzz/keybuzz-api/scripts/migrate.js (applique TOUTES migrations dir, dangereux pour notre cas) | non utilise |
| Convention K8s Job | k8s/keybuzz-api-dev/job-migrate-010.yaml (Job dedicace psql par migration) | reference |
| Strategie choisie | Node + pg script dans pod API DEV existant, applique UNIQUEMENT migration 032 source | OK safe |
| DB cible | DEV confirme via pod API DEV env implicit (PGHOST=10.0.0.10) | OK (secret non affiche) |

## E2 PRE-MIGRATION DB DEV

| Colonne | Avant migration DEV | Verdict |
|---|---|---|
| signup_attribution.client_ip_address | ABSENT | a creer |
| signup_attribution.client_user_agent | ABSENT | a creer |

Schema verification via Node + pg dans pod `keybuzz-api-6cbbfb479c-tk492` (DEV avant rollout). Query `information_schema.columns` : 0 rows pour les colonnes attendues.

## E3 APPLY MIGRATION 032 SUR DB DEV

| Etape | Resultat |
|---|---|
| SCP migration 032 dans pod /tmp/ | OK |
| SCP script Node apply | OK |
| `pool.query(sql)` ALTER TABLE | OK |
| Idempotent IF NOT EXISTS verifie | OK |
| Erreur SQL | aucune |
| Mutation hors schema | 0 (rows preserves) |
| DB target | DEV (PGHOST=10.0.0.10 cluster DEV, PGPASSWORD non affiche) |

## E4 POST-MIGRATION DB DEV VERIFICATION

| Colonne | Type | Nullable | Present apres | Verdict |
|---|---|---|---|---|
| signup_attribution.client_ip_address | text | YES | OUI | OK |
| signup_attribution.client_user_agent | text | YES | OUI | OK |

| Item | Valeur |
|---|---|
| signup_attribution rows total | 10 (preserves, aucune mutation) |
| Schema verify | 2/2 colonnes attendues presentes |
| PII affichee | NON |
| Migration id table (si existe) | non interrogee, hors scope |

## E5 BUMP MANIFEST API DEV (GitOps strict)

| Manifest | Avant | Apres | Verdict |
|---|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml l.321 | image: ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev | image: ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev | OK +annotation PH-20.9B |
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) | OK | scope strict |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-api configured (server dry run)` | OK |

| Item | Valeur |
|---|---|
| Commit infra | 56b3c30 chore(api): bump DEV Meta CAPI EMQ image PH-20.9B |
| Push | OK b654e9f..56b3c30 main -> main |

## E6 APPLY DEV + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply -f | OK `deployment.apps/keybuzz-api configured` |
| Rollout duration | ~30-45s |
| Rollout status | `deployment "keybuzz-api" successfully rolled out` |
| Pod ancien (terminating) | keybuzz-api-6cbbfb479c-tk492 (digest 5dc670ab... v3.5.252) |
| Pod nouveau Ready | keybuzz-api-86f86f8c58-tpwr2 (digest sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4) |
| readyReplicas | 1/1 |

### Triple match PROD-STD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 | OK MATCH expected |

## E7 SMOKES READ-ONLY

| Endpoint | HTTP | Resultat | Verdict |
|---|---|---|---|
| http://127.0.0.1:3001/health (via pod exec) | 200 | `{"status":"ok","timestamp":"2026-05-22T12:33:16.523Z","service":"keybuzz-api","version":"1.0.0"}` | OK |

Aucun appel mutateur. Aucun register. Aucun checkout. Aucun event Meta.

## E8 AUDIT RUNTIME PH-20.9B MARKERS LIVE

| Marker | Count `/app/dist` runtime | Verdict |
|---|---|---|
| client_ip_address | 8 | OK LIVE |
| client_user_agent | 8 | OK LIVE |
| event_source_url | 6 | OK LIVE |
| external_id_hash | 3 | OK LIVE |
| metaCapiHash | 6 | OK LIVE |
| first_name_hash | 3 | OK LIVE |
| last_name_hash | 3 | OK LIVE |
| phone_hash | 3 | OK LIVE |
| safeEventSourceUrl | 2 | OK LIVE |
| x-forwarded-for | 4 | OK LIVE |

Logs API DEV `--tail=20` filtres error/column-not-exist : **0 occurrences**.

## E9 NON-REGRESSION SERVICES

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website-prod | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-admin-v2 | v2.12.2-* | INCHANGES |

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Meta event sent | 0 | OK |
| Register test | 0 | OK |
| Checkout test | 0 | OK |
| Stripe mutation | 0 | OK |
| DB mutation hors migration 032 | 0 | OK (10 rows signup_attribution preserves) |
| PROD touched | 0 | OK |
| test_event_code | aucun envoye | OK |
| Browser Pixel ajoute | aucun | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN PROD touche (manifest, runtime, DB, Stripe).
- AUCUN kubectl set image / set env / patch / edit (GitOps strict apply -f).
- AUCUN secret / token / pixel ID / PGPASSWORD affiche.
- AUCUN PII brut affiche (emails masques, IP/UA jamais loggees).
- AUCUN event Meta reel envoye.
- AUCUN faux register / lead / checkout.
- AUCUN Linear ticket statut modifie.
- Migration appliquee uniquement sur DB DEV (PGHOST cluster DEV verifie).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK DEV DOCUMENTE (non execute)

Si regression observee post-apply :

### Etape 1 : rollback image GitOps
1. Editer `k8s/keybuzz-api-dev/deployment.yaml` -> image `v3.5.252-billing-tenant-id-fallback-dev`.
2. `git add + commit -m "ops(api): ROLLBACK PH-20.9B to v3.5.252"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-dev deploy/keybuzz-api --timeout=180s`.

### Etape 2 (optionnelle, si schema instable)
- `ALTER TABLE signup_attribution DROP COLUMN client_ip_address, DROP COLUMN client_user_agent;` (additive nullable initialement, reversible).
- Note : code v3.5.252 ne lit pas ces colonnes (sont absentes en source pre-PH-20.9B), donc DROP optionnel mais propre.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Migration appliquee proprement, rollout OK, triple match, markers LIVE, smoke /health OK, 0 error logs.
2. **EMQ score Meta** : amelioration directionnelle attendue mais score final visible Events Manager Antoine apres 24-48h trafic reel (avec destination Meta CAPI active sur tenant keybuzz-consulting-mo9zndlk).
3. La QA DEV devra rester sans event Meta reel : preferer inspection payload via DB JSONB conversion_events ou tests interne ai.service mock.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Migration DB DEV | 032 appliquee 2/2 colonnes OK 10 rows preserves |
| keybuzz-infra HEAD apres apply | 56b3c30 (manifest) |
| API DEV runtime tag | v3.5.253-meta-capi-emq-dev |
| API DEV runtime digest | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 |
| Pod DEV | keybuzz-api-86f86f8c58-tpwr2 Ready 1/1 |
| Source commit | d88aa7d0 (PH-20.9B) |
| Smokes /health | HTTP 200 OK |
| PH-20.9B markers LIVE pod /app/dist | 10 patterns OK |
| Triple match | OK |
| Runtime API PROD | INCHANGE |
| Runtime Client+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA API META CAPI EVENT MATCH QUALITY DEV PH-SAAS-T8.12AS.20.9B`

QA DEV recommandee :
- Inspection DB JSONB conversion_events (events futurs) pour verifier nouveaux champs payload (client_ip_address, client_user_agent, event_source_url, fn/ln/ph/external_id_hash).
- Inspection emitter logs API DEV pour validation read tenant_metadata + signup_attribution IP/UA.
- Aucun event Meta reel envoye sauf GO explicit (preferer test_event_code en environnement test Meta dedie).

STOP. Aucun PROD, aucun event Meta reel, aucun register/checkout test, aucun deploy supplementaire.
