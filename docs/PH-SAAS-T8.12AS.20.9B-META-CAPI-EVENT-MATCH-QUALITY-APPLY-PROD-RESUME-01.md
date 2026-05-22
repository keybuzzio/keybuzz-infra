# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-PROD-RESUME-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B APPLY PROD RESUME via Patroni leader
> Environnement : PROD GitOps strict apply, migration 032 PROD appliquee via postgres superuser local socket sur Patroni leader

## VERDICT

GO APPLY API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B

Reprise post-blocker reussie. Option B Patroni cadree executee : migration 032 PROD via leader Patroni `db-postgres-02` (10.0.0.121) en `sudo -u postgres psql` peer auth local socket, sans toucher Vault ni afficher secret.

- Migration 032 PROD : 2/2 colonnes `client_ip_address text NULL` + `client_user_agent text NULL` ajoutees sur DB `keybuzz_prod`, 16 rows preserves.
- Manifest `k8s/keybuzz-api-prod/deployment.yaml` bumpe v3.5.251-billing-tenant-id-fallback-prod -> v3.5.252-meta-capi-emq-prod.
- Infra commit `9efd7bd` push origin/main avant apply.
- kubectl apply : `deployment.apps/keybuzz-api configured` -> rollout successfully rolled out.
- Pod nouveau `keybuzz-api-55c768fcfc-xcgld` Ready 1/1.
- Runtime digest PROD : `sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b` MATCH GHCR push.
- Triple match parfait : last-applied = manifest = pod imageID.
- Smoke /health : HTTP 200 OK.
- 10/10 markers PH-20.9B LIVE dans /app/dist runtime pod PROD.
- Logs API PROD : 0 column-not-exist, 0 signup_attribution missing, "Server listening at http://0.0.0.0:3001" OK.
- Runtime API DEV `v3.5.253-meta-capi-emq-dev` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- AUCUN event Meta reel envoye. AUCUN test register/checkout. AUCUNE autre migration. AUCUN secret/PGPASSWORD affiche.

STOP avant observation EMQ Antoine.

## CONTEXTE BLOCKER INITIAL

Tentative initiale APPLY PROD via pod API PROD (user `keybuzz_api_prod`) avait echoue avec :
> ERR must be owner of table signup_attribution

Cause : user app PROD `keybuzz_api_prod` RW seulement, pas owner table. Aucun secret `keybuzz-api-postgres-admin` provisionne en namespace `keybuzz-api-prod` (alors que DEV avait equivalent).

Decision reprise (Option B cadree) :
- Identifier Patroni leader via REST `/cluster` sur :8008 (sans auth).
- SSH au leader via bastion SSH (cle deja en place, host key OK).
- `sudo -u postgres psql` peer auth local socket (pas de password, conventionnel Postgres superuser local).
- Executer uniquement migration 032 SQL.
- NE PAS toucher Vault. NE PAS toucher /opt/keybuzz/secrets ou credentials. NE PAS provisionner ExternalSecret PROD.

GO PROD Ludovic explicit recu et respecte.

## E0 PREFLIGHT REPRISE

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T14:01:43Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD avant | 0b89e5b (post-rapport BLOCKER) |
| Runtime API DEV | v3.5.253-meta-capi-emq-dev INCHANGE |
| Runtime API PROD avant | v3.5.251-billing-tenant-id-fallback-prod (post-blocker, inchange) |
| GHCR config digest cible | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e MATCH |
| GHCR manifest digest cible | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b |

## E1 IDENTIFICATION PATRONI LEADER

| Item | Valeur | Source |
|---|---|---|
| Cluster Patroni members | 3 noeuds 10.0.0.120/121/122 | REST `/cluster` :8008 (sans auth) |
| Leader actuel | `db-postgres-02` (10.0.0.121) state=running role=leader timeline=27 | Patroni REST |
| db-postgres-01 (10.0.0.120) | replica streaming lag=0 | Patroni REST |
| db-postgres-03 (10.0.0.122) | replica (verifie cluster sain) | Patroni REST |
| Acces SSH leader | OK via bastion install-v3 (root, cle in-place) | `ssh 10.0.0.121 hostname` |
| psql client | /usr/bin/psql present sur leader | `which psql` |
| Connexion postgres user | OK via `sudo -u postgres psql` peer auth local socket (pas de password requis, convention KeyBuzz) | sudo + peer authentication |

## E2 PRE-MIGRATION DB PROD READ-ONLY (via leader Patroni)

| Colonne | Avant migration PROD | Verdict |
|---|---|---|
| signup_attribution.client_ip_address | ABSENT | a creer |
| signup_attribution.client_user_agent | ABSENT | a creer |
| signup_attribution rows total | 16 | baseline |

## E3 APPLY MIGRATION 032 SUR DB PROD

| Etape | Resultat |
|---|---|
| SSH leader 10.0.0.121 | OK |
| `sudo -u postgres psql -d keybuzz_prod` | peer auth OK (PGPASSWORD jamais affiche) |
| Statement execute | `ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS client_ip_address TEXT, ADD COLUMN IF NOT EXISTS client_user_agent TEXT;` |
| Sortie psql | `ALTER TABLE` |
| Erreur SQL | aucune |
| Autres migrations executees | 0 |
| Mutation hors schema | 0 |
| Secret/PGPASSWORD affiche | 0 |

## E4 POST-MIGRATION DB PROD VERIFICATION

| Colonne | Type | Nullable | Present apres | Verdict |
|---|---|---|---|---|
| signup_attribution.client_ip_address | text | YES | OUI | OK |
| signup_attribution.client_user_agent | text | YES | OUI | OK |

| Indicateur | Avant | Apres | Verdict |
|---|---|---|---|
| signup_attribution rows total | 16 | 16 | preserves |
| Schema verify | 0/2 | 2/2 | OK |
| PII affichee | NON | NON | OK |

## E5 BUMP MANIFEST API PROD (GitOps strict)

| Manifest | Avant | Apres | Verdict |
|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml l.106 | v3.5.251-billing-tenant-id-fallback-prod | **v3.5.252-meta-capi-emq-prod** + annotation PH-20.9B | OK |
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) | OK | scope strict |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-api configured (server dry run)` | OK |

| Item | Valeur |
|---|---|
| Commit infra | 9efd7bd chore(api): bump PROD Meta CAPI EMQ image PH-20.9B |
| Push | OK 0b89e5b..9efd7bd main -> main |

## E6 APPLY PROD + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply -f | OK `deployment.apps/keybuzz-api configured` |
| Rollout duration | ~30-45s |
| Rollout status | `deployment "keybuzz-api" successfully rolled out` |
| Pod ancien (terminating) | keybuzz-api-5fc84764-fnnqq (digest 25fc2c... v3.5.251) |
| Pod nouveau Ready | **keybuzz-api-55c768fcfc-xcgld** |
| Pod imageID nouveau | `sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b` |
| readyReplicas | 1/1 |

### Triple match PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b | OK MATCH expected |

## E7 SMOKES READ-ONLY PROD

| Endpoint | HTTP | Body | Verdict |
|---|---|---|---|
| /health (via pod exec) | 200 | `{"status":"ok","timestamp":"2026-05-22T14:09:08.371Z","service":"keybuzz-api","version":"1.0.0"}` | OK |

Aucun appel mutateur. Aucun register. Aucun checkout. Aucun event Meta.

## E8 AUDIT RUNTIME MARKERS PH-20.9B PROD

| Marker | Count /app/dist | Verdict |
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

10/10 markers LIVE. Logs filtres `column does not exist` = 0. Server listening at http://0.0.0.0:3001 confirme.

## E9 NON-REGRESSION RUNTIME

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
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
| DB mutation hors migration 032 | 0 | OK (16 rows signup_attribution preserves) |
| DEV touched | 0 | OK |
| test_event_code | 0 | OK |
| Browser Pixel ajoute | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN DEV touche.
- AUCUN kubectl set image/set env/patch/edit (GitOps strict apply -f).
- AUCUN secret/token/PGPASSWORD affiche (peer auth local socket = pas de mot de passe en CLI).
- AUCUN PII brut (emails masques, IP/UA jamais loggees).
- AUCUN event Meta reel envoye.
- AUCUN faux register/lead/checkout.
- AUCUN Linear ticket statut modifie.
- AUCUNE autre migration appliquee.
- AUCUN touche /opt/keybuzz/credentials ni /opt/keybuzz/secrets.
- AUCUN touche Vault.
- Migration appliquee uniquement DB PROD `keybuzz_prod` via Patroni leader.
- Bastion install-v3 (46.62.171.61) uniquement.
- GO PROD Ludovic respecte (et reprise Option B Patroni cadree).

## ROLLBACK PROD DOCUMENTE (non execute)

Si regression observee post-apply :

### Etape 1 : rollback image GitOps strict
1. Editer `k8s/keybuzz-api-prod/deployment.yaml` -> image `v3.5.251-billing-tenant-id-fallback-prod`.
2. `git add + commit -m "ops(api-prod): ROLLBACK PH-20.9B to v3.5.251"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=180s`.

### Etape 2 (optionnelle - migration additive peut rester)
- Si schema PROD instable : `sudo -u postgres psql -d keybuzz_prod -c "ALTER TABLE signup_attribution DROP COLUMN client_ip_address, DROP COLUMN client_user_agent;"` via Patroni leader.
- Note : code v3.5.251 ne lit pas ces colonnes (sont absentes en source pre-PH-20.9B), donc DROP optionnel mais propre.

INTERDIT : kubectl set image, git reset --hard, git clean.

## OBSERVATION EMQ 24-48H

- EMQ score visible Antoine dans Meta Events Manager (destination Meta CAPI active sur tenant keybuzz-consulting-mo9zndlk).
- Necessite trafic reel (signups + Stripe webhooks Purchase/StartTrial).
- Amelioration directionnelle attendue : payload enrichi avec em + fn + ln + ph + external_id + fbc + fbp + client_ip_address + client_user_agent + event_source_url (vs em + fbc + fbp baseline pre-PH-20.9B).
- Audit read-only delivery_logs + conversion_events JSONB possible apres 24-48h pour mesurer impact.

## GAPS

1. Aucun. Apply PROD propre via Patroni cadree.
2. Gap structurel documente pour le futur : pas d ExternalSecret PROD admin DDL en convention K8s. Recommande Option A (rapport BLOCKER) pour migrations PROD futures. Mais Option B Patroni utilisable de maniere conservative.
3. EMQ score final observable Antoine post-trafic reel 24-48h.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Migration DB PROD | 032 appliquee via Patroni leader db-postgres-02, 2/2 colonnes, 16 rows preserves |
| Manifest commit | 9efd7bd push origin/main |
| API PROD runtime tag | v3.5.252-meta-capi-emq-prod |
| API PROD runtime digest | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b |
| Pod PROD nouveau | keybuzz-api-55c768fcfc-xcgld Ready 1/1 |
| Source commit | d88aa7d0 |
| Triple match | OK |
| Smoke /health | HTTP 200 OK |
| Markers PH-20.9B LIVE | 10/10 OK |
| Logs API PROD | 0 column-not-exist, Server listening |
| Runtime API DEV | INCHANGE |
| Runtime Client+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-PROD-RESUME-01.md` |

### Prochaine phrase GO attendue

`GO OBSERVE META CAPI EVENT MATCH QUALITY PROD PH-SAAS-T8.12AS.20.9B`

Observation 24-48h trafic reel post-apply :
- Aucun event artificiel.
- Antoine verifie Events Manager : EMQ score, event coverage, diagnostics.
- Audit read-only delivery_logs + conversion_events JSONB possible apres trafic reel.

STOP. Aucun event Meta, aucun register/checkout, aucun deploy supplementaire, aucun changement Linear statut.
