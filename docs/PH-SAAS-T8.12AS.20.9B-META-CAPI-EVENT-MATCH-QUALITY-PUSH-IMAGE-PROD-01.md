# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-PUSH-IMAGE-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B PUSH IMAGE API PROD Meta CAPI EMQ
> Environnement : Push GHCR PROD only (aucun build, aucun deploy, aucune migration PROD)

## VERDICT

GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod` pushee sur GHCR.
- Config digest MATCH local == GHCR : `sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e`.
- Manifest digest GHCR : `sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b`.
- 10 layers (10/10 reused car meme commit source d88aa7d0 que image DEV deja sur GHCR ; seul le tag differe).
- Total compressed ~112 MB (112 042 855 bytes), config.size 12 482 bytes.
- OCI revision preserve : `d88aa7d0b72e6f14874f8cfa87c366139b7c4b17`.
- Runtime API PROD `v3.5.251-billing-tenant-id-fallback-prod` INCHANGE.
- Runtime API DEV `v3.5.253-meta-capi-emq-dev` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie. Aucune migration PROD appliquee.

STOP avant APPLY PROD. **GO PROD explicit Ludovic requis + RGPD review IP/UA valide + migration 032 PROD avant rollout**.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T13:29:01Z |
| Tag image cible | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod |
| Image ID local | 5f1e13278b8b (sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e) |
| Size local | 343 MB |
| OCI revision label | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |

## E1 GHCR COLLISION CHECK

| Tag | Inspect avant push | Verdict |
|---|---|---|
| v3.5.252-meta-capi-emq-prod | manifest unknown | LIBRE OK |

## E2 DOCKER PUSH GHCR PROD

```
5df05835a6c6: Layer already exists
c8b0f2c8a629: Layer already exists
d3901d53f250: Layer already exists
eb5831b8cbeb: Layer already exists
161cc9e6fa43: Layer already exists
e61d2a995383: Layer already exists
1162d08df74c: Layer already exists
9cc01943aa82: Layer already exists
29df493baa13: Layer already exists
7a7517ab2e5a: Layer already exists
v3.5.252-meta-capi-emq-prod: digest: sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total | 10 |
| Layers reused | 10/10 |
| Layers nouveaux | 0 (meme commit source d88aa7d0 que image DEV deja pushee, seul le tag differe) |
| Manifest digest GHCR | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b |
| Manifest size | 2416 bytes |
| config.size | 12 482 bytes |
| Total layer bytes (compressed) | 112 042 855 (~112 MB) |
| Push exit code | 0 |

## E3 VERIFICATION GHCR

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e | **MATCH OK** |
| Manifest digest | n/a | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod` | OK |
| OCI revision label | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 | preserve via push | OK |

## E4 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | **v3.5.251-billing-tenant-id-fallback-prod** | INCHANGE (cible PUSH non deployee) |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun manifest GitOps modifie. Aucune migration PROD appliquee.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- 0 fake event delta (deja audite BUILD PROD).
- Aucun appel Meta Graph API.
- Aucun test_event_code.
- Aucune mutation DB.
- Aucun register/checkout test.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD PROD PH-20.9B).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token / pixel ID affiche.
- AUCUNE mutation DB / Stripe.
- AUCUNE migration PROD appliquee (032 reste fichier source uniquement, sera applique avec GO Ludovic).
- AUCUN faux register / lead / formulaire / event Meta.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si apply PROD + rollout provoquent regression :

### Etape 1 : rollback image GitOps
1. Editer `k8s/keybuzz-api-prod/deployment.yaml` -> image `v3.5.251-billing-tenant-id-fallback-prod`.
2. `git add + commit -m "ops(api-prod): ROLLBACK PH-20.9B to v3.5.251"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=180s`.

### Etape 2 (optionnelle, si schema PROD instable)
- `ALTER TABLE signup_attribution DROP COLUMN client_ip_address, DROP COLUMN client_user_agent;` (additive nullable, reversible).
- Note : code v3.5.251 ne lit pas ces colonnes (sont absentes en source pre-PH-20.9B), donc DROP optionnel mais propre.

INTERDIT : kubectl set image / git reset --hard / git clean.

## SEQUENCING APPLY PROD (a venir, GO explicit Ludovic requis)

1. **GO PROD explicit Ludovic** dans la conversation courante + **RGPD review valide** sur capture IP/UA server-side.
2. **Appliquer migration 032 sur DB PROD `keybuzz_prod`** via tooling dedie (Node + pg script idempotent, ou Job K8s migration). DB cible PROD doit etre confirmee sans afficher PGPASSWORD.
3. Verifier `SELECT column_name FROM information_schema.columns WHERE table_name='signup_attribution' AND column_name IN ('client_ip_address', 'client_user_agent')` PROD retourne 2 lignes.
4. Bump manifest `k8s/keybuzz-api-prod/deployment.yaml` v3.5.251 -> v3.5.252-meta-capi-emq-prod.
5. Commit infra + push origin/main.
6. kubectl apply -f + rollout status timeout 180s.
7. Smoke /health PROD + triple match (last-applied = manifest = pod imageID = sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e).
8. Audit markers /app/dist runtime pod PROD.
9. Observation 24-48h EMQ Meta Events Manager Antoine.

## GAPS

1. Aucun. Push GHCR PROD clean, digest match, runtime inchange, OCI revision preserve.
2. **Sequencing critique pour APPLY PROD** : migration 032 doit etre appliquee AVANT rollout pour eviter degradation silencieuse (try/catch non-blocking degrade vers fallback null si colonne absente, pas de crash mais EMQ pas enrichi en PROD).
3. EMQ score Meta final visible Antoine Events Manager apres 24-48h trafic reel post-apply.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY PROD READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-meta-capi-emq-prod |
| Manifest digest GHCR | sha256:adad89b008180bf27238e79e0a8271aa3366f429f785e72a4beab64777ea929b |
| Config digest match local==GHCR | sha256:5f1e13278b8b5b1d18a44544c17e2c15a1c6f16c63420125960e4eadc7169b7e |
| Manifest size | 2416 |
| Layers | 10 (10/10 reused, meme commit source) |
| Total compressed bytes | 112 042 855 (~112 MB) |
| OCI revision preserve | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |
| Runtime API DEV/PROD | v3.5.253 / v3.5.251 INCHANGES |
| Runtime Client/Website/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API META CAPI EVENT MATCH QUALITY PROD PH-SAAS-T8.12AS.20.9B`

Rappel critique APPLY PROD :
- GO PROD explicit Ludovic obligatoire.
- RGPD review IP/UA capture valide.
- Migration 032 sur DB PROD AVANT rollout image.
- GitOps strict (NO kubectl set/patch/edit).
- Aucun event Meta reel pendant apply.

STOP. Aucun deploy, aucun kubectl apply, aucune migration PROD appliquee, aucun event Meta reel.
