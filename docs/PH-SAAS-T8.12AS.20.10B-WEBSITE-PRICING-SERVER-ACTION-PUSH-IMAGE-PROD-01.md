# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-PUSH-IMAGE-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B PUSH IMAGE Website PROD GHCR
> Environnement : Push GHCR PROD only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B

- Image Docker `ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod` pushee sur GHCR.
- Config digest MATCH local == GHCR : `sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd`.
- Manifest digest GHCR : `sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b`.
- 11 layers (8 reused, 3 nouveaux = bundle Next.js PROD avec patch error.tsx + global-error.tsx).
- Total compressed ~74 MB (74 395 062 bytes), config.size 12 818 bytes, manifest size 2619 bytes.
- OCI revision preserve : `907689bf51678c4d97785d9316f21f03ea074f9f`.
- Runtime Website DEV `v0.6.21-pricing-action-recover-dev` INCHANGE.
- Runtime Website PROD `v0.6.20-cmp-mobile-polish-prod` INCHANGE.
- Runtime API + Client + Admin INCHANGES.

STOP avant APPLY PROD. Le prompt APPLY PROD devra integrer GO PROD explicit Ludovic + controle pre/post 503 nginx sur /pricing.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T16:02:12Z |
| Tag image cible | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod |
| Image ID local | 92d8fd2a4532 (sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd) |
| Size local | 214 MB |
| OCI revision label | 907689bf51678c4d97785d9316f21f03ea074f9f |

## E1 GHCR COLLISION CHECK

| Tag | Inspect avant push | Verdict |
|---|---|---|
| v0.6.21-pricing-action-recover-prod | manifest unknown | LIBRE OK |

## E2 DOCKER PUSH GHCR PROD

```
2b9a2f2ce418: Layer already exists
7b97cad5e745: Layer already exists
ad82ae140432: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
1a5356470f84: Pushed
53d138bca7e0: Pushed
ca218c5ba4ff: Pushed
v0.6.21-pricing-action-recover-prod: digest: sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b size: 2619
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 8/11 |
| Layers nouveaux | 3 (bundle Next.js PROD avec patch error boundaries + build args production-specific) |
| Manifest digest GHCR | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| Manifest size | 2619 bytes |
| config.size | 12 818 bytes |
| Total layer bytes (compressed) | 74 395 062 (~74 MB) |
| Push exit code | 0 |

## E3 VERIFICATION GHCR

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd | **MATCH OK** |
| Manifest digest | n/a | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod` | OK |
| OCI revision label | 907689bf51678c4d97785d9316f21f03ea074f9f | preserve via push | OK |

## E4 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.21-pricing-action-recover-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | **v0.6.20-cmp-mobile-polish-prod** | INCHANGE (cible PUSH non deployee) |
| keybuzz-api | keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun restart pod. Aucun manifest GitOps modifie.

## NOTE 503 PROD - HORS SCOPE PUSH

Contexte signale par Ludovic avant deploy PH-20.10B :
- PROD https://keybuzz.pro/pricing : 503 nginx intermittent observe en rafale F5 (~1 sur 10).
- DEV preview.keybuzz.pro stable sur ~100 refreshs PH-20.10B.
- Capture : "503 Service Temporarily Unavailable nginx".

Analyse rapide :
- Le 503 nginx **n est PAS** le meme probleme que "Failed to find Server Action".
- Le patch PH-20.10B corrige uniquement le stale Server Action mismatch via error boundary client.
- Le 503 nginx releve probablement de l edge / ingress / upstream / keepalive / rate limit / pods saturation.

**Cette phase PUSH ne fait AUCUN diagnostic 503**. Note documentee pour APPLY PROD :
1. Controle pre-deploy : compter 503 sur /pricing PROD baseline (10 rafales F5).
2. Controle post-deploy : memes controles apres rollout.
3. Logs ingress-nginx pendant rafale F5 si accessibles.
4. Logs Website PROD pods pendant rafale F5.
5. Si 503 PROD persiste post-PH-20.10B : phase dediee PH-20.10C 503-rca a creer.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- Aucun event marketing genere.
- Aucun appel Meta Graph API / GA Measurement Protocol / LinkedIn API.
- Aucun lead/register/checkout test.
- Aucun fake event delta.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD PROD PH-20.10B).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token / Pixel ID affiche.
- AUCUN PII brut.
- AUCUN faux register / lead / formulaire / event Meta.
- AUCUN ticket Linear modifie statut.
- AUCUN changement API/Client/Admin.
- AUCUN diagnostic destructif 503.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si apply PROD provoque regression :
1. Editer `k8s/keybuzz-website-prod/deployment.yaml` (chemin a confirmer) -> image `v0.6.20-cmp-mobile-polish-prod`.
2. `git add + commit -m "ops(website-prod): ROLLBACK PH-20.10B to v0.6.20"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-website-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-prod deploy/keybuzz-website --timeout=180s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Aucun gap technique sur le push GHCR. Digest match, runtime inchange, OCI revision preserve.
2. **503 PROD non corrige par PH-20.10B** : note ci-dessus, APPLY PROD devra integrer controle pre/post 503 + decision d ouvrir PH-20.10C-503-rca si persiste.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod |
| Manifest digest GHCR | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| Config digest match local==GHCR | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd |
| Manifest size | 2619 |
| Layers | 11 (8 reused, 3 nouveaux pour bundle PROD) |
| Total compressed bytes | 74 395 062 (~74 MB) |
| OCI revision preserve | 907689bf51678c4d97785d9316f21f03ea074f9f |
| Runtime Website DEV/PROD | INCHANGES |
| Runtime API/Client/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY WEBSITE PRICING SERVER ACTION PROD PH-SAAS-T8.12AS.20.10B`

Important pour APPLY PROD :
- GO PROD explicite Ludovic dans la conversation courante.
- Controle pre/post des 503 nginx sur /pricing.
- Logs ingress/website si accessibles.
- GitOps strict (NO kubectl set/patch/edit).
- Si 503 persiste : phase dediee PH-20.10C-503-rca.

STOP. Aucun deploy, aucun event Meta, aucun register/checkout, aucun changement Linear statut.
