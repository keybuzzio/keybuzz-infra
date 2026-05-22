# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-PROD-BLOCKER-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B APPLY PROD - BLOCKER migration DB PROD role admin DDL
> Environnement : Tentative APPLY PROD interrompue avant bump manifest. Runtime PROD INCHANGE.

## VERDICT

STOP BLOCKER API META CAPI APPLY PROD MIGRATION PH-SAAS-T8.12AS.20.9B

**Cause** : aucun role admin DDL provisionne pour la DB PROD `keybuzz_prod`. Le user app `keybuzz_api_prod` n a que des droits RW (pas owner table `signup_attribution`). Aucun secret `keybuzz-api-postgres-admin` n existe en namespace `keybuzz-api-prod` (alors qu il existe en `keybuzz-api-dev`).

**Resultat** : impossible d appliquer `ALTER TABLE signup_attribution ADD COLUMN client_ip_address TEXT, client_user_agent TEXT` en PROD avec les credentials actuels du pod runtime.

**Action immediate** : aucune mutation DB PROD. Aucun bump manifest. Aucun rollout image. Runtime PROD INCHANGE sur `v3.5.251-billing-tenant-id-fallback-prod`.

GO PROD Ludovic recu et respecte. Stop conservatoire avant ecart runtime/schema.

## E0 PREFLIGHT (OK)

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T13:45:56Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD | d6281b0 (post-rapport PUSH IMAGE PROD) |
| Runtime API DEV | v3.5.253-meta-capi-emq-dev |
| Runtime API PROD | v3.5.251-billing-tenant-id-fallback-prod |
| GHCR config digest cible | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e MATCH OK |
| Manifest digest GHCR | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b |

## E1 MIGRATION SOURCE (OK)

| Item | Resultat |
|---|---|
| Migration 032 fichier | OK present |
| Statement | `ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS client_ip_address TEXT, client_user_agent TEXT;` |
| Destructive SQL executable | 0 |
| Idempotent | OUI |

## E2+E3 BLOCKER : DB PROD ROLE

| Etape | Resultat |
|---|---|
| Pod API PROD identifie | keybuzz-api-5fc84764-fnnqq |
| Connexion DB PROD via Node + pg | OK |
| current_user PROD | `keybuzz_api_prod` |
| current_database PROD | `keybuzz_prod` |
| Owner table `signup_attribution` PROD | **NON CHECK** (try query a echoue avant cette validation a cause de l erreur DDL) |
| Tentative `ALTER TABLE ADD COLUMN IF NOT EXISTS` | **ERR must be owner of table signup_attribution** |
| Migration appliquee | **NON** (rollback automatique - aucune mutation effectuee) |

### Comparaison DEV (a titre de reference)

| Indicateur | DEV | PROD |
|---|---|---|
| current_user | `keybuzz_api_dev` | `keybuzz_api_prod` |
| current_database | `keybuzz` | `keybuzz_prod` |
| Owner `signup_attribution` | `keybuzz_api_dev` (app user = owner) | **PAS OWNER** |
| Secret K8s `keybuzz-api-postgres-admin` | OUI dans namespace `keybuzz-api-dev` (5 keys : PGHOST/PORT/USER/PASSWORD/DATABASE via Vault) | **N EXISTE PAS** dans namespace `keybuzz-api-prod` |
| ExternalSecret admin role | OUI (ClusterSecretStore vault-backend-database, refresh 1h) | **NON** |
| Migration ADD COLUMN | OK applique en APPLY DEV PH-20.9B | bloque |

## CONFIRMATIONS SECURITE

- AUCUNE mutation DB PROD effectuee (ALTER TABLE retourne erreur owner avant tout effet).
- AUCUN bump manifest API PROD (k8s/keybuzz-api-prod/deployment.yaml inchange).
- AUCUN commit/push infra.
- AUCUN kubectl apply.
- AUCUN docker build/push.
- AUCUN secret/token/PGPASSWORD affiche dans logs ni rapport.
- AUCUN PII brute.
- AUCUN event Meta reel envoye.
- AUCUN test register/checkout/Stripe.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME NON-REGRESSION

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api | DEV : v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | PROD : v3.5.251-billing-tenant-id-fallback-prod | INCHANGE (cible v3.5.252 NON deployee) |
| keybuzz-client | DEV+PROD | INCHANGES |
| keybuzz-website | DEV+PROD | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | INCHANGES |

## OPTIONS POUR DEBLOQUER (necessite intervention Ludovic)

### Option A : provisioner role admin DDL PROD via Vault + ESO

1. Creer un role Postgres `keybuzz_api_prod_admin` (ou utiliser le superuser/owner deja existant) avec privileges ALTER TABLE sur `keybuzz_prod`.
2. Vault put credentials : `vault kv put kv/database/keybuzz-api-prod-admin PGHOST=... PGPORT=... PGUSER=keybuzz_api_prod_admin PGPASSWORD=... PGDATABASE=keybuzz_prod`.
3. Creer ExternalSecret `keybuzz-api-postgres-admin` dans namespace `keybuzz-api-prod` pointant vers ce chemin (modele identique a celui qui existe en DEV).
4. Creer un Job K8s `keybuzz-api-migrate-032-prod` (modele identique a `job-migrate-010.yaml` DEV) qui execute la migration 032 via psql avec les credentials admin.
5. Verifier success Job + schema apres-coup.

### Option B : appliquer migration via Patroni leader / postgres super-user

1. Identifier le leader Patroni du cluster PostgreSQL PROD.
2. SSH sur le pod patroni-X / connexion via psql avec role super-user.
3. Executer `\c keybuzz_prod` puis `ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS client_ip_address TEXT, client_user_agent TEXT;`.
4. Verifier le schema apres-coup.
5. Documenter dans rapport.

### Option C : ALTER OWNER + DDL grant temporaire

1. Connexion avec super-user.
2. `GRANT pg_write_all_data ON DATABASE keybuzz_prod TO keybuzz_api_prod` OU `ALTER TABLE signup_attribution OWNER TO ...` temporaire.
3. Appliquer la migration.
4. REVOKE le grant.

**Option A recommandee** (conventionnel KeyBuzz, persiste pour futures migrations, audit-able via Vault).

## ROLLBACK

Pas de rollback necessaire :
- Aucune mutation DB PROD effectuee.
- Aucun manifest GitOps modifie.
- Aucun runtime change.
- L image PROD `v3.5.252-meta-capi-emq-prod` reste sur GHCR prete a deployer une fois la migration appliquee.

## GAPS

1. **BLOCKER** : pas de role admin DDL provisionne pour PROD DB. Ludovic doit choisir Option A/B/C ci-dessus.
2. **Note securite** : KeyBuzz a une bonne pratique de droits restreints en PROD (RW only pour l app). C est la migration 032 (additive nullable, non-destructive) qui exige une escalade ponctuelle.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | STOP BLOCKER API META CAPI APPLY PROD MIGRATION PH-SAAS-T8.12AS.20.9B |
| GO PROD Ludovic | recu et respecte (stop conservatoire avant ecart) |
| Migration DB PROD | NON appliquee (erreur owner attendue, aucun effet) |
| Manifest API PROD | NON modifie |
| Image API PROD GHCR | OK pushee v3.5.252-meta-capi-emq-prod (prete a deployer post-migration) |
| Runtime API PROD | v3.5.251-billing-tenant-id-fallback-prod INCHANGE |
| Cause | Role admin DDL absent pour DB PROD, app user n est pas owner |
| Solution | Provisionner role admin via Vault + ExternalSecret + Job K8s migration (Option A recommandee) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-APPLY-PROD-BLOCKER-01.md` |

### Prochaine phrase GO attendue

`GO PROVISIONER ADMIN ROLE PROD POUR PH-SAAS-T8.12AS.20.9B`

OU si Ludovic prefere appliquer directement via Patroni :

`GO APPLY MIGRATION 032 PROD VIA PATRONI SUPERUSER PH-SAAS-T8.12AS.20.9B`

STOP. Aucune mutation DB PROD, aucun deploy, aucun event Meta, aucun changement Linear statut.
