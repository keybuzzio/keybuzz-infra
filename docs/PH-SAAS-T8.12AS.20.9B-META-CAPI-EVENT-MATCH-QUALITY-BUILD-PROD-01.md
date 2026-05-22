# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-BUILD-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B BUILD API PROD Meta CAPI EMQ
> Environnement : Build Docker PROD only (aucun docker push, aucun deploy, aucune migration PROD)

## VERDICT

GO BUILD API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod` build OK depuis worktree --detach commit `d88aa7d0`.
- Image ID local : `sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e` size 343 MB.
- OCI labels KEY-308 5/5 OK (revision=d88aa7d0b72e6f14874f8cfa87c366139b7c4b17).
- Markers PH-20.9B LIVE dans `/app/dist` (12 patterns) : client_ip_address=8, client_user_agent=8, event_source_url=6, external_id_hash=3, metaCapiHash=6, first_name_hash=3, last_name_hash=3, phone_hash=3, safeEventSourceUrl=2, x-forwarded-for=4, x-real-ip=2, META_EVENT_MAPPING=3.
- Baseline comparison v3.5.251-billing-tenant-id-fallback-prod vs build v3.5.252-meta-capi-emq-prod : 0/0/0/0 -> 8/6/3/6 (tous nouveaux markers actives).
- Secret/PII leak scan : 0 Meta token, 0 PGPASSWORD, 0 Pixel ID hardcode, 0 test_event_code, 0 console.log user_data.
- Migration 032 presente source mais **NON copiee dans image runtime** (convention Dockerfile API : migrations appliquees out-of-band via migrate.js).
- GHCR collision tag PROD cible LIBRE (`manifest unknown`). Aucun docker push.
- Runtime API PROD `v3.5.251-billing-tenant-id-fallback-prod` INCHANGE.
- Runtime API DEV `v3.5.253-meta-capi-emq-dev` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- Worktree nettoyee post-build.

STOP avant docker push GHCR PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T13:15:15Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD | 96b1b0e (post-rapport QA DEV) |
| Runtime API DEV avant | v3.5.253-meta-capi-emq-dev |
| Runtime API PROD avant | v3.5.251-billing-tenant-id-fallback-prod |
| GHCR collision v3.5.252-meta-capi-emq-prod | manifest unknown (LIBRE) |
| Dirty API repo principal | 223 (pre-existing dist/ deletions, non touche par PH-20.9B) |
| Dirty infra | 0 |

## E1 AUDIT SOURCE PRE-BUILD (commit d88aa7d0)

### Source markers PH-20.9B

| Fichier | Marker | Count | Verdict |
|---|---|---|---|
| meta-capi.ts + emitter.ts + create-signup | client_ip_address | 10 | OK |
| meta-capi.ts + emitter.ts + create-signup | client_user_agent | 10 | OK |
| meta-capi.ts + emitter.ts | event_source_url | 8 | OK |
| meta-capi.ts + emitter.ts | metaCapiHash | 6 | OK helpers exportes + used |
| meta-capi.ts | safeEventSourceUrl | 2 | OK gate http/https |
| emitter.ts + meta-capi.ts | first_name_hash | 4 | OK |
| emitter.ts + meta-capi.ts | last_name_hash | 4 | OK |
| emitter.ts + meta-capi.ts | phone_hash | 4 | OK |
| emitter.ts + meta-capi.ts | external_id_hash | 4 | OK |
| migrations/032_*.sql | present | OUI | additive nullable, non applique PROD |

### TSC

Verifie en BUILD DEV PH-20.9B = 0 erreurs project config. Commit source d88aa7d0 inchange depuis. Note : nouvelle execution `npx tsc --noEmit` est skippee ici pour eviter delai et car deja verifiee, mais source est identique a BUILD DEV.

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.9B-API-PROD/keybuzz-api |
| Worktree detache sur | d88aa7d0 |
| Worktree dirty | 0 (clean) |
| Full commit hash | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |
| migrations/032_*.sql present | OUI |
| Dockerfile present | OUI |

## E3 DOCKER BUILD API PROD

| Item | Valeur |
|---|---|
| Build args utilises | IMAGE_REVISION=d88aa7d0b72e6f14874f8cfa87c366139b7c4b17, IMAGE_CREATED=2026-05-22T13:15:45Z |
| Exit code | 0 |
| Tag image | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod |
| Image ID | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e |
| Config digest local | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e |
| Size | 343 MB |
| Created | 2026-05-22T13:15:48Z |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T13:15:45Z | OK |
| org.opencontainers.image.revision | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 | OK MATCH commit |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |
| org.opencontainers.image.version | v3.5.252-meta-capi-emq-prod | OK |

KEY-309 tag immutable + suffixe `-prod` conforme + sequence PROD versioning (v3.5.252 apres baseline v3.5.251).

## E4 AUDIT IMAGE STATIQUE PROD (strings dans /app/dist)

### Meta CAPI markers PH-20.9B presents dans dist compile

| Marker | Count PROD build v3.5.252 | Verdict |
|---|---|---|
| client_ip_address | 8 | OK LIVE compile |
| client_user_agent | 8 | OK LIVE compile |
| event_source_url | 6 | OK LIVE compile |
| external_id_hash | 3 | OK LIVE compile |
| metaCapiHash | 6 | OK LIVE compile |
| first_name_hash | 3 | OK LIVE compile |
| last_name_hash | 3 | OK LIVE compile |
| phone_hash | 3 | OK LIVE compile |
| safeEventSourceUrl | 2 | OK LIVE compile |
| x-forwarded-for | 4 | OK LIVE compile |
| x-real-ip | 2 | OK LIVE compile |
| META_EVENT_MAPPING (preserve) | 3 | OK preserve baseline |

### Comparaison baseline PROD v3.5.251 vs build v3.5.252

| Marker | v3.5.251-billing-tenant-id-fallback-prod (baseline) | v3.5.252-meta-capi-emq-prod (build) | Delta | Verdict |
|---|---|---|---|---|
| client_ip_address | 0 | 8 | **+8** | activated |
| event_source_url | 0 | 6 | **+6** | activated |
| external_id_hash | 0 | 3 | **+3** | activated |
| metaCapiHash | 0 | 6 | **+6** | activated |
| x-forwarded-for | 2 (pre-existing fastify/middleware) | 4 | +2 | nouveau code create-signup |

Baseline confirmee : ces patterns Meta CAPI EMQ etaient absents PROD avant PH-20.9B.

### Secret/PII leak scan

| Pattern | Count image | Verdict |
|---|---|---|
| Meta token EAA[A-Z]* (50+ chars) | 0 | OK |
| PGPASSWORD hardcode | 0 | OK |
| Pixel ID hardcode (numeric 15+) | 0 | OK |
| test_event_code hardcode | 0 | OK |
| console.log user_data | 0 | OK |

### Migration 032 dans image

| Path | Present | Verdict |
|---|---|---|
| /app/migrations/032_*.sql | NON | NORMAL - Dockerfile API ne copie pas `migrations/` (convention out-of-band via migrate.js) |

Application migration : sera faite via `node migrate.js` / Job K8s migration / Node+pg script dans phase APPLY PROD, AVANT rollout image API PROD. **GO PROD Ludovic explicit requis** + RGPD review valide.

## E5 NON-REGRESSION TRACKING / SECURITY

| Controle | Resultat | Verdict |
|---|---|---|
| Fake events strings ajoutees hors code existant | 0 (META_EVENT_MAPPING preserve, pas de nouvel event_name ajoute) | OK |
| Hardcoded Meta token | 0 | OK |
| Hardcoded Pixel ID | 0 | OK |
| Logs user_data complet | 0 (commentaire explicite dans code) | OK |
| Migration appliquee live PROD | 0 | OK (fichier present source, pas execute) |
| Appel Meta network | 0 (aucun fetch durant audit) | OK |

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.9B-API-PROD/` | OK |
| Repo principal keybuzz-api | dirty=223 (pre-existing dist/ unchanged, aucun nouveau dirty introduit) |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | **v3.5.251-billing-tenant-id-fallback-prod** | INCHANGE (cible BUILD non deployee) |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-website | keybuzz-website-dev/-prod | v0.6.20-cmp-mobile-polish-* | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun deploy PROD. Aucun kubectl apply. Aucun docker push. Aucune migration PROD.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- Aucun appel Meta Graph API.
- Aucun test_event_code envoye.
- event_id stable preserve dans code (deduplication intacte).
- 0 fake event delta verifie via comparaison baseline.
- Tests = audit statique strings + diff baseline (sans reseau).

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible LIBRE).
- AUCUN deploy DEV ni PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela commit d88aa7d0.
- AUCUN secret / token / pixel ID affiche.
- AUCUNE mutation DB / Stripe.
- AUCUNE migration PROD appliquee.
- AUCUN faux event / register / checkout / lead.
- AUCUN test event Meta reel.
- AUCUN changement IDs analytics.
- AUCUN changement Client/Website/Admin.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK / PREVENTION

### Rollback build (avant push GHCR)

Pas de rollback necessaire : aucune action irreversible. L image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod
```

### Rollback runtime (anticipation post-deploy PROD futur)

Si apply PROD provoque regression :
1. Rollback tag PROD actuel `v3.5.251-billing-tenant-id-fallback-prod`.
2. Procedure GitOps : editer `k8s/keybuzz-api-prod/deployment.yaml` -> revenir v3.5.251 + commit + push + apply.
3. Optionnel : DROP COLUMN migration 032 PROD si schema instable (reversible).

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, 12 markers PH-20.9B presents, 0 secret/PII leak, baseline comparison confirme nouveaux markers actives, runtime preserve.
2. **Sequencing critique pour APPLY PROD** : migration 032 doit etre appliquee sur DB PROD `keybuzz_prod` AVANT rollout image API PROD v3.5.252. Sinon SELECT etendu emitter retourne column-not-exist, try/catch non-blocking degrade silencieusement vers fallback null (pas de crash mais EMQ pas enrichi).
3. **GO PROD explicit Ludovic requis** avant migration 032 PROD + RGPD review IP/UA capture.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Source commit API | d88aa7d0 |
| Tag image cible PROD | v3.5.252-meta-capi-emq-prod |
| Image ID local | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e |
| Image size | 343 MB |
| OCI labels KEY-308 | 5/5 OK (revision=d88aa7d0b72e6f14874f8cfa87c366139b7c4b17) |
| Markers PH-20.9B dans /app/dist | 12 patterns OK (delta vs baseline +8/+6/+3/+6/+2) |
| Secret/PII leak | 0 |
| Migration 032 dans image | NON (convention out-of-band, applique en APPLY PROD avec GO Ludovic) |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime API DEV+PROD | INCHANGES |
| Runtime Client+Website+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY PROD PH-SAAS-T8.12AS.20.9B`

Puis dans la phase APPLY PROD separee (GO PROD explicit Ludovic requis) :
1. Appliquer migration 032 sur DB PROD `keybuzz_prod` via tooling dedie.
2. Verifier signup_attribution.client_ip_address + client_user_agent presents en PROD.
3. GitOps apply manifest API PROD vers v3.5.252-meta-capi-emq-prod.
4. Rollout + validation runtime + smoke /health PROD.
5. Observation 24-48h EMQ Meta Events Manager Antoine.

STOP. Aucun docker push, aucun deploy PROD, aucune migration PROD appliquee, aucun event Meta reel.
