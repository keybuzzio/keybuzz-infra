# PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-API-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE PUSH IMAGE API DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE API AI DRAFT BLOCKEDINFO DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19`.
- **Manifest digest GHCR** : `sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628` (size 2416).
- 10 layers (7 reused, 3 nouveaux dist API avec extension GET /autopilot/draft).
- Total compressed ~112 MB (112 043 173 bytes), config.size 12 469 bytes.
- OCI revision preserve : `5070e6a61b81d70b0d15cb44ef15ea52e93f898a`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime API DEV `v3.5.253-meta-capi-emq-dev` INCHANGE.
- Runtime API PROD `v3.5.252-meta-capi-emq-prod` INCHANGE.
- Runtime Client + Backend + Website INCHANGES.
- Aucun manifest GitOps modifie.

STOP avant APPLY API DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T20:54:04Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev |
| Image locale ID | c033a96e8aa1 |
| Config digest local | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 MATCH expected |
| Size local | 343 MB |
| OCI revision label | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 DOCKER PUSH GHCR DEV

```
c8b0f2c8a629: Layer already exists
d3901d53f250: Layer already exists
e61d2a995383: Layer already exists
7a7517ab2e5a: Layer already exists
9cc01943aa82: Layer already exists
1162d08df74c: Layer already exists
29df493baa13: Layer already exists
ea0823cdd979: Pushed
b5a1b5795798: Pushed
9d55dbb71ff7: Pushed
v3.5.254-ai-draft-blocked-reason-dev: digest: sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total | 10 |
| Layers reused | 7/10 |
| Layers nouveaux | 3 (dist API avec extension GET /autopilot/draft fallback blocked) |
| Manifest digest GHCR | sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 |
| Manifest size | 2416 bytes |
| config.size | 12 469 bytes |
| Total layer bytes (compressed) | 112 043 173 (~112 MB) |
| Push exit code | 0 |

## E2 PULL-BACK VERIFY

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 | **MATCH OK** |
| Manifest digest | n/a | sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev` | OK |
| OCI revision label | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | preserve via push | OK |

## E3 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | **v3.5.253-meta-capi-emq-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.211-ai-draft-blocked-reason-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-backend | keybuzz-backend-dev | v1.0.47-cross-env-guard-fix-dev | INCHANGE |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.21-pricing-action-recover-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.21-pricing-action-recover-prod | INCHANGE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11B-PARENT-WIRE-BUILD-DEV audite (config digest match) :
- Markers PH-20.11B LIVE dans /app/dist : blockedStatus=2, blockedNotes=1, PRE_LLM_BLOCKED=6, ESCALATION_DRAFT=14, hasDraft=5, PH marker=1.
- Doctrine seller-first / refund-protection (autopilotGuardrails.ts) INCHANGE 100% (hash identique 5e62bbbe...).
- Routes critiques inchangees : /autopilot/draft, /autopilot/evaluate, /ai/assist, /ai/execute, /autopilot/settings.

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

- AUCUN docker build (image deja construite en BUILD DEV PH-20.11B-PARENT-WIRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux register/lead/formulaire/event.
- AUCUN Linear ticket statut modifie.
- AUCUN changement Client/Backend/Admin.
- Doctrine seller-first/refund-protection (autopilotGuardrails.ts) INCHANGE 100%.
- KEY-305 fix race UI preserve dans source Client.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si APPLY DEV provoque regression :
1. Editer `k8s/keybuzz-api-dev/deployment.yaml` -> image `v3.5.253-meta-capi-emq-dev`.
2. `git add + commit -m "ops(api-dev): ROLLBACK PH-20.11B-PARENT-WIRE to v3.5.253"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-dev deploy/keybuzz-api --timeout=180s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API AI DRAFT BLOCKEDINFO DEV READY PH-SAAS-T8.12AS.20.11B-PARENT-WIRE |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev |
| Manifest digest GHCR | sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 |
| Config digest match local==GHCR | sha256:c033a96e8aa1b95630d7f96ed29ee197af42532b83d0ffd7b7db06532d43db19 |
| Manifest size | 2416 |
| Layers | 10 (7 reused, 3 nouveaux dist API) |
| Total compressed bytes | 112 043 173 (~112 MB) |
| OCI revision preserve | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Runtime API DEV/PROD | INCHANGES |
| Runtime Client/Backend/Website | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-PARENT-WIRE-AI-DRAFT-BLOCKEDINFO-API-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API AI DRAFT BLOCKEDINFO DEV PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
