# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B BUILD API DEV Meta CAPI EMQ
> Environnement : Build Docker DEV only (aucun docker push, aucun deploy, aucune migration appliquee live)

## VERDICT

GO BUILD API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev` build OK depuis worktree --detach commit `d88aa7d0`.
- Image ID local : `sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f` size 343 MB.
- OCI labels KEY-308 5/5 OK (revision=d88aa7d0b72e6f14874f8cfa87c366139b7c4b17).
- **Markers PH-20.9B audites dans `/app/dist`** : 7/7 OK (client_ip_address, client_user_agent, event_source_url, external_id, metaCapiHash, first_name_hash/last_name_hash/phone_hash/external_id_hash, safeEventSourceUrl, x-forwarded-for, x-real-ip).
- Baseline comparison v3.5.252 vs v3.5.253 : 0/0/0/0/0 -> 8/6/3/6/2 (tous nouveaux markers actives).
- Secret/PII leak scan : 0 token Meta, 0 PGPASSWORD hardcode, 0 Pixel ID hardcode, 0 test_event_code, 0 console.log user_data.
- Migration 032 presente dans source commit mais **NON copiee dans image runtime** (convention Dockerfile API : migrations appliquees out-of-band via migrate.js).
- GHCR collision tag DEV cible LIBRE (`manifest unknown`). Aucun docker push.
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime API PROD `v3.5.251-billing-tenant-id-fallback-prod` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- Worktree nettoyee post-build.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T11:51:49Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD | 6a857c7 (post-rapport PH-20.9B source) |
| Runtime API DEV avant | v3.5.252-billing-tenant-id-fallback-dev |
| Runtime API PROD avant | v3.5.251-billing-tenant-id-fallback-prod |
| GHCR collision v3.5.253-meta-capi-emq-dev | manifest unknown (LIBRE) |
| Dirty API repo principal | 223 (pre-existing dist/ deletions, non touche par PH-20.9B) |
| Dirty infra | 0 |

## E1 AUDIT SOURCE PRE-BUILD (commit d88aa7d0)

### meta-capi.ts markers source

| Marker | Count source | Verdict |
|---|---|---|
| client_ip_address | 4 | OK |
| client_user_agent | 4 | OK |
| event_source_url | 6 | OK |
| external_id | 4 | OK |
| metaCapiHash | 2 | OK helpers exportes |
| safeEventSourceUrl | 2 | OK gate http/https |
| MetaUserData | 3 | OK interface etendue |

### emitter.ts markers source

| Marker | Count source | Verdict |
|---|---|---|
| client_ip_address | 4 | OK |
| client_user_agent | 4 | OK |
| first_name_hash | 2 | OK |
| last_name_hash | 2 | OK |
| phone_hash | 2 | OK |
| external_id_hash | 2 | OK |
| tenant_metadata SELECT | 2 | OK fn/ln/phone fetch |
| metaCapiHash usage | 4 | OK |
| landingUrl variable | 3 | OK event_source_url source |

### tenant-context-routes.ts markers source

| Marker | Count source | Verdict |
|---|---|---|
| x-forwarded-for | 2 | OK proxy header |
| x-real-ip | 2 | OK fallback |
| clientIpAddress | 2 | OK var capture |
| clientUserAgent | 2 | OK var capture |
| client_ip_address (col) | 1 | OK INSERT col |
| client_user_agent (col) | 1 | OK INSERT col |

### Migration 032

| Item | Valeur |
|---|---|
| Fichier | migrations/032_signup_attribution_client_metadata.sql |
| Size | 967 bytes |
| Statement | ALTER TABLE signup_attribution ADD COLUMN IF NOT EXISTS client_ip_address TEXT, client_user_agent TEXT |
| Additive nullable | OUI |
| Reversible | OUI (DROP COLUMN) |
| Apply en live ? | **NON** (sera applique en phase APPLY DEV separee via migrate.js) |

### TSC noEmit project config

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit` | 0 erreurs | OK |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.9B-API-DEV/keybuzz-api |
| Worktree detache sur | d88aa7d0 |
| Worktree dirty | 0 (clean) |
| Full commit hash | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |
| migrations/032_*.sql present | OUI |
| Dockerfile present | OUI |
| Dockerfile build args | IMAGE_REVISION=unknown, IMAGE_CREATED=unknown |

## E3 DOCKER BUILD API DEV

| Item | Valeur |
|---|---|
| Build args utilises | IMAGE_REVISION=d88aa7d0b72e6f14874f8cfa87c366139b7c4b17, IMAGE_CREATED=2026-05-22T11:52:25Z |
| Exit code | 0 |
| Tag image | ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev |
| Image ID | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f |
| Config digest local | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f |
| Size | 343 MB |
| Created | 2026-05-22T11:53:34Z |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T11:52:25Z | OK |
| org.opencontainers.image.revision | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 | OK MATCH commit |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |
| org.opencontainers.image.version | v3.5.253-meta-capi-emq-dev | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E4 AUDIT IMAGE STATIQUE (strings dans /app/dist)

### Meta CAPI markers PH-20.9B presents dans dist compile

| Marker | Count image | Verdict |
|---|---|---|
| client_ip_address | 7 | OK LIVE compile |
| client_user_agent | 7 | OK LIVE compile |
| event_source_url | 6 | OK LIVE compile |
| external_id | 5 | OK LIVE compile |
| metaCapiHash | 6 | OK LIVE compile |
| first_name_hash | 3 | OK LIVE compile |
| last_name_hash | 3 | OK LIVE compile |
| phone_hash | 3 | OK LIVE compile |
| external_id_hash | 3 | OK LIVE compile |
| safeEventSourceUrl | 2 | OK LIVE compile |
| x-forwarded-for | 2 | OK LIVE compile |
| x-real-ip | 2 | OK LIVE compile |

### Comparaison baseline v3.5.252 vs build v3.5.253 (occurrences /app/dist)

| Indicateur | v3.5.252 | v3.5.253 | Delta | Verdict |
|---|---|---|---|---|
| client_ip_address | 0 | 8 | **+8** | activated |
| event_source_url | 0 | 6 | **+6** | activated |
| external_id_hash | 0 | 3 | **+3** | activated |
| metaCapiHash | 0 | 6 | **+6** | activated |
| x-forwarded-for (tenant-context) | 0 | 2 | **+2** | activated |

Baseline confirmee : ces strings n existaient pas avant PH-20.9B.

### Migration 032 presence dans image

| Path | Present | Verdict |
|---|---|---|
| /app/migrations/032_*.sql | NON | NORMAL - Dockerfile API ne copie pas `migrations/` dans runtime (convention out-of-band via migrate.js).  |

Application migration : sera faite via `node migrate.js` ou script `ph11_*_migrate.sh` dans phase APPLY DEV, AVANT rollout image API DEV.

### Secret/PII leak scan

| Pattern | Count image | Verdict |
|---|---|---|
| Meta token EAA[A-Z]* (50+ chars) | 0 | OK |
| PGPASSWORD hardcode | 0 | OK |
| Pixel ID hardcode (numeric 15+) | 0 | OK |
| test_event_code hardcode | 0 | OK |
| console.log user_data | 0 | OK |

## E5 NON-REGRESSION TRACKING / SECURITY

| Controle | Resultat | Verdict |
|---|---|---|
| Fake events ajoutes (Lead/Purchase/StartTrial nouveaux strings hors code existant) | 14 occurrences mais ce sont les NOMS STANDARD Meta (META_EVENT_MAPPING) preserves baseline, pas ajout de fake events | OK faux positif documente |
| Hardcoded Meta token | 0 | OK |
| Hardcoded Pixel ID | 0 | OK |
| Logs user_data complet | 0 | OK (commentaire explicite dans code) |
| Mutation DB executee | 0 | OK (aucun script execute) |
| Migration appliquee live | 0 | OK (fichier present source, pas execute) |

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.9B-API-DEV/` | OK |
| Repo principal keybuzz-api clean apres cleanup | dirty=223 (pre-existing dist/ unchanged, aucun nouveau dirty introduit) |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-website | keybuzz-website-dev/-prod | v0.6.20-cmp-mobile-polish-* | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- Aucun nouvel event Meta genere.
- Aucun appel reseau Meta Graph API.
- Aucun test_event_code envoye.
- event_id stable preserve dans code (deduplication intacte).
- 0 fake event delta verifie via comparaison baseline.
- Tests = audit statique strings + tsc + diff (sans reseau).

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela commit d88aa7d0.
- AUCUN secret / token / pixel ID affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux event / register / checkout / lead.
- AUCUN test event Meta reel.
- AUCUN appel marketing mutateur.
- AUCUN changement IDs analytics.
- AUCUN changement Client/Website/Admin.
- AUCUN changement Linear statut.
- AUCUNE migration appliquee live.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK / PREVENTION

### Rollback build (avant push GHCR)

Pas de rollback necessaire : aucune action irreversible. L image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev
```

### Rollback runtime (anticipation post-deploy futur)

Si apply DEV provoque regression :
1. Rollback tag DEV actuel `v3.5.252-billing-tenant-id-fallback-dev`.
2. Procedure GitOps : editer `k8s/keybuzz-api-dev/deployment.yaml` -> revenir v3.5.252 + commit + push + apply.
3. Optionnel : DROP COLUMN migration 032 si schema instable.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, markers PH-20.9B presents, 0 secret/PII leak, runtime inchanges.
2. **Sequencing critique pour APPLY DEV** : la migration 032 doit etre appliquee sur DB DEV `keybuzz` AVANT le rollout image API DEV v3.5.253. Sinon les SELECT etendus dans emitter.ts retourneront error column not exist, mais le try/catch non-blocking degradera silencieusement vers fallback null (pas de crash mais EMQ pas enrichi). L application doit etre faite via `node migrate.js` ou tooling dedie.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Source commit API | d88aa7d0 |
| Tag image cible DEV | v3.5.253-meta-capi-emq-dev |
| Image ID local | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f |
| Image size | 343 MB |
| OCI labels KEY-308 | 5/5 OK |
| Markers PH-20.9B dans /app/dist | 12 patterns OK (delta vs baseline +8/+6/+3/+6/+2) |
| Secret/PII leak | 0 |
| Migration 032 dans image | NON (convention out-of-band, applique en APPLY DEV) |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime API DEV+PROD | INCHANGES |
| Runtime Client+Website+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY DEV PH-SAAS-T8.12AS.20.9B`

Puis dans la phase APPLY DEV separee :
1. Appliquer migration 032 sur DB DEV `keybuzz` via `node migrate.js` ou tooling dedie.
2. Verifier `SELECT column_name FROM information_schema.columns WHERE table_name=signup_attribution AND column_name IN (client_ip_address, client_user_agent)` retourne 2 lignes.
3. GitOps apply manifest API DEV vers v3.5.253-meta-capi-emq-dev.
4. Rollout + validation runtime + smoke logs Meta CAPI delivery.

STOP. Aucun docker push, aucun deploy, aucune migration appliquee live, aucun event Meta reel.
