# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B PUSH IMAGE Website DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE WEBSITE PRICING SERVER ACTION DEV READY PH-SAAS-T8.12AS.20.10B

- Image Docker `ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev` pushee sur GHCR.
- Config digest MATCH local == GHCR : `sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775`.
- Manifest digest GHCR : `sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca`.
- 11 layers total (8 reused, 3 nouveaux = bundle Next.js patch error.tsx + global-error.tsx).
- Total compressed ~74 MB (74 396 767 bytes), config.size 12 813 bytes, manifest size 2619 bytes.
- OCI revision preserve : `907689bf51678c4d97785d9316f21f03ea074f9f`.
- Runtime Website DEV `v0.6.20-cmp-mobile-polish-dev` INCHANGE.
- Runtime Website PROD `v0.6.20-cmp-mobile-polish-prod` INCHANGE.
- Runtime API + Client + Admin INCHANGES.

STOP avant APPLY DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T15:22:51Z |
| Tag image cible | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev |
| Image ID local | 8008501c61fd (sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775) |
| Size local | 214 MB |
| OCI revision label | 907689bf51678c4d97785d9316f21f03ea074f9f |

## E1 GHCR COLLISION CHECK

| Tag | Inspect avant push | Verdict |
|---|---|---|
| v0.6.21-pricing-action-recover-dev | manifest unknown | LIBRE OK |

## E2 DOCKER PUSH GHCR DEV

```
2b9a2f2ce418: Layer already exists
7b97cad5e745: Layer already exists
ad82ae140432: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
90b4749a28b4: Pushed
272139dd8809: Pushed
4530515e88d6: Pushed
v0.6.21-pricing-action-recover-dev: digest: sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca size: 2619
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 8/11 |
| Layers nouveaux | 3 (bundle Next.js avec patch error.tsx + global-error.tsx) |
| Manifest digest GHCR | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Manifest size | 2619 bytes |
| config.size | 12 813 bytes |
| Total layer bytes (compressed) | 74 396 767 (~74 MB) |
| Push exit code | 0 |

## E3 VERIFICATION GHCR

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775 | sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775 | **MATCH OK** |
| Manifest digest | n/a | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev` | OK |
| OCI revision label | 907689bf51678c4d97785d9316f21f03ea074f9f | preserve via push | OK |

## E4 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | **v0.6.20-cmp-mobile-polish-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-website | keybuzz-website-prod | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun restart pod. Aucun manifest GitOps modifie.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- Aucun event marketing genere.
- Aucun appel Meta Graph API / GA Measurement Protocol / LinkedIn API.
- Aucun lead/register/checkout test.
- Aucun fake event delta (deja audite BUILD DEV).

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV PH-20.10B).
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
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si apply DEV provoque regression :
1. Editer `k8s/keybuzz-website-dev/deployment.yaml` -> image `v0.6.20-cmp-mobile-polish-dev`.
2. `git add + commit -m "ops(website-dev): ROLLBACK PH-20.10B to v0.6.20"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-website-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-dev deploy/keybuzz-website --timeout=180s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Aucun. Push GHCR DEV clean, digest match, runtime inchange, OCI revision preserve.
2. Le patch resout l UX (auto-recover transparent UNE fois) mais ne supprime pas les logs serveur (cause inherente Next.js + bots). Comportement documente dans PH-20.10B source patch rapport.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE WEBSITE PRICING SERVER ACTION DEV READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev |
| Manifest digest GHCR | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Config digest match local==GHCR | sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775 |
| Manifest size | 2619 |
| Layers | 11 (8 reused, 3 nouveaux pour patch error boundaries) |
| Total compressed bytes | 74 396 767 (~74 MB) |
| OCI revision preserve | 907689bf51678c4d97785d9316f21f03ea074f9f |
| Runtime Website DEV/PROD | INCHANGES |
| Runtime API/Client/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY WEBSITE PRICING SERVER ACTION DEV PH-SAAS-T8.12AS.20.10B`

STOP. Aucun deploy, aucun event Meta, aucun register/checkout, aucun changement Linear statut.
