# PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-CLIENT-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE PUSH IMAGE Client DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.212-ai-draft-blocked-reason-dev` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:1ce783dc71b407fd5b530d7b9228952fbb7c95303b57c7e93c2c3d9caa3bb1b7`.
- **Manifest digest GHCR** : `sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924` (size 2631).
- 11 layers (6 reused, 5 nouveaux : Next.js bundle avec parent-wire).
- Total compressed ~105 MB (105 266 783 bytes), config.size 12 918 bytes.
- OCI revision preserve : `beabcd81dfeca465c7bddc45a4c09ed9c95b18d7`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime Client DEV `v3.5.211-ai-draft-blocked-reason-dev` INCHANGE.
- Runtime Client PROD `v3.5.201-register-polish-prod` INCHANGE.
- Runtime API DEV `v3.5.254-ai-draft-blocked-reason-dev` LIVE INCHANGE.
- Runtime API PROD INCHANGE.
- Aucun manifest GitOps modifie.

STOP avant APPLY Client DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T21:37:37Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-client:v3.5.212-ai-draft-blocked-reason-dev |
| Image locale ID | 1ce783dc71b4 |
| Config digest local | sha256:1ce783dc71b407fd5b530d7b9228952fbb7c95303b57c7e93c2c3d9caa3bb1b7 MATCH expected |
| Size local | 280 MB |
| OCI revision label | beabcd81dfeca465c7bddc45a4c09ed9c95b18d7 |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 DOCKER PUSH GHCR DEV

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
cb4a8e3a1cbb: Pushed
93e710fa6063: Pushed
6a3ab82d9d35: Pushed
a7882d18462a: Pushed
7cec7aa9cc27: Pushed
v3.5.212-ai-draft-blocked-reason-dev: digest: sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6/11 |
| Layers nouveaux | 5 (Next.js bundle avec parent-wire blockedInfo) |
| Manifest digest GHCR | sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924 |
| Manifest size | 2631 bytes |
| config.size | 12 918 bytes |
| Total layer bytes (compressed) | 105 266 783 (~105 MB) |
| Push exit code | 0 |

## E2 PULL-BACK VERIFY

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:1ce783dc71b407fd5b530d7b9228952fbb7c95303b57c7e93c2c3d9caa3bb1b7 | sha256:1ce783dc71b407fd5b530d7b9228952fbb7c95303b57c7e93c2c3d9caa3bb1b7 | **MATCH OK** |
| Manifest digest | n/a | sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.212-ai-draft-blocked-reason-dev` | OK |
| OCI revision label | beabcd81dfeca465c7bddc45a4c09ed9c95b18d7 | preserve via push | OK |

## E3 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.211-ai-draft-blocked-reason-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | **v3.5.254-ai-draft-blocked-reason-dev** | INCHANGE (LIVE deja deploye PH-20.11B-PARENT-WIRE APPLY API DEV) |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-backend | DEV+PROD | v1.0.47-cross-env-guard-fix | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.21 / v0.6.21-pricing-action-recover-prod | INCHANGES |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11B-PARENT-WIRE-CLIENT-BUILD-DEV audite (config digest match) :
- Markers parent-wire LIVE dans /app/.next : blockedInfo=4 (delta +2 vs v3.5.211), Garde-fou actif=2, Brouillon IA bloque par securite=2, Validation humaine recommandee=2.
- AI feature parity preserve : Brouillon IA=6, Suggestion IA=4, Aide IA=10.
- KEY-263 DEV isolation strict : api-dev.keybuzz.io=87, api.keybuzz.io PROD=0.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- No fake events test_event_code=0, sk_live_/sk_test_=0, hardcode tenant=0.

Aucune divergence introduite par le push.

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Push container Docker uniquement | OK | OK |
| Aucun appel LLM | 0 | OK |
| Aucun event marketing genere | 0 | OK |
| Aucun lead/register/checkout test | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun appel Meta/GA/LinkedIn/TikTok | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD Client DEV PH-20.11B-PARENT-WIRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux register/lead/formulaire/event.
- AUCUN Linear ticket statut modifie.
- AUCUN changement API/Backend/Website/Admin.
- Doctrine seller-first/refund-protection (autopilotGuardrails.ts) INCHANGE 100%.
- KEY-305 fix race UI preserve dans source.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si APPLY DEV provoque regression :
1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.211-ai-draft-blocked-reason-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.11B-PARENT-WIRE to v3.5.211"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.212-ai-draft-blocked-reason-dev |
| Manifest digest GHCR | sha256:7f292c5de77658ab23ad30e1259bd610bf9ce3548287b5edc110f88862d97924 |
| Config digest match local==GHCR | sha256:1ce783dc71b407fd5b530d7b9228952fbb7c95303b57c7e93c2c3d9caa3bb1b7 |
| Manifest size | 2631 |
| Layers | 11 (6 reused, 5 nouveaux Next.js bundle parent-wire) |
| Total compressed bytes | 105 266 783 (~105 MB) |
| OCI revision preserve | beabcd81dfeca465c7bddc45a4c09ed9c95b18d7 |
| Runtime Client DEV/PROD | INCHANGES |
| Runtime API DEV/PROD | INCHANGES (API DEV v3.5.254 LIVE) |
| Runtime Backend/Website/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-CLIENT-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE DEV PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
