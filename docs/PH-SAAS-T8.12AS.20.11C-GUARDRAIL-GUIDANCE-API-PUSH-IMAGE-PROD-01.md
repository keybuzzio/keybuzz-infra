# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-PUSH-IMAGE-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 / KEY-231 / KEY-305 (related) ; KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE PUSH IMAGE API PROD GHCR
> Environnement : Push GHCR PROD only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b`.
- **Manifest digest GHCR** : `sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf` (size 2416).
- 10 layers TOUS reused (parite parfaite avec v3.5.254-DEV : meme commit 5070e6a6 from-git -> meme layers).
- Total compressed ~112 MB (112 043 173 bytes), config.size 12 473 bytes.
- OCI revision preserve : `5070e6a61b81d70b0d15cb44ef15ea52e93f898a`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime API PROD `v3.5.252-meta-capi-emq-prod` INCHANGE.
- Runtime API DEV + Client DEV + Client PROD INCHANGES.
- Aucun manifest GitOps modifie.

STOP avant APPLY API PROD GitOps strict.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T09:08:15Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod |
| Image locale ID | 14830ddea074 |
| Config digest local | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b MATCH expected |
| Size local | 343 MB |
| OCI revision label | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Tag | GHCR avant push | Verdict |
|---|---|---|
| v3.5.255-ai-draft-blocked-reason-prod | manifest unknown (LIBRE) | OK |

## E2 DOCKER PUSH GHCR PROD

```
c8b0f2c8a629: Layer already exists
ea0823cdd979: Layer already exists
d3901d53f250: Layer already exists
9d55dbb71ff7: Layer already exists
b5a1b5795798: Layer already exists
9cc01943aa82: Layer already exists
e61d2a995383: Layer already exists
7a7517ab2e5a: Layer already exists
1162d08df74c: Layer already exists
29df493baa13: Layer already exists
v3.5.255-ai-draft-blocked-reason-prod: digest: sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total | 10 |
| Layers reused | 10/10 (TOUS - parite avec v3.5.254-DEV deja sur GHCR) |
| Layers nouveaux | 0 |
| Manifest digest GHCR | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf |
| Manifest size | 2416 bytes |
| config.size | 12 473 bytes |
| Total layer bytes (compressed) | 112 043 173 (~112 MB) |
| Push exit code | 0 |

Note : zero layer nouveau car le build PROD partage la meme structure d'image avec le build DEV (meme commit source `5070e6a6` from-git, meme Dockerfile, meme dist). Seul le tag/manifest/labels changent.

## E3 PULL-BACK VERIFY

| Controle | Attendu | Resultat | Verdict |
|---|---|---|---|
| Config digest local | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | identique | **MATCH OK** |
| Config digest GHCR | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | identique | **MATCH OK** |
| Manifest digest GHCR | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | OK | OK |
| Repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-api@sha256:8d3b4d093f087b... | identique | OK |
| Pull idempotence | `Image is up to date` | identique | OK |
| OCI revision label | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a | preserve | OK |

## E4 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | **v3.5.252-meta-capi-emq-prod** | INCHANGE (cible PUSH non deployee) |
| keybuzz-api | keybuzz-api-dev | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11C-GUARDRAIL-GUIDANCE-API-BUILD-PROD audite (config digest match) :
- Markers blockedInfo PH-20.11B LIVE dist (blockedStatus=2, blockedNotes=1, PRE_LLM_BLOCKED=6, ESCALATION_DRAFT=14, hasDraft=5).
- Routes critiques preserve (autopilot/draft=6, /ai/assist=3, /ai/execute=3, autopilot/settings=12, autopilot/evaluate=3).
- Guardrails preserve (autopilotGuardrails=5, refundProtection=31, COMBINED_RISK_HIGH=1).
- No secret / no hardcode 0/5.
- Doctrine seller-first INCHANGE 100%.

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

- AUCUN docker build (image deja construite en BUILD API PROD PH-20.11C).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN faux register/lead/formulaire/event.
- AUCUN Linear ticket statut modifie.
- AUCUN changement Client/Backend/Website/Admin.
- Doctrine seller-first/refund-protection INCHANGE 100%.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si APPLY PROD provoque regression :
1. Editer `k8s/keybuzz-api-prod/deployment.yaml` -> image `v3.5.252-meta-capi-emq-prod`.
2. `git add + commit -m "ops(api-prod): ROLLBACK PH-20.11C to v3.5.252"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Image push

| Image | Tag | Config digest local | Config digest GHCR | Manifest digest | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api | v3.5.255-ai-draft-blocked-reason-prod | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf | MATCH OK |

### 2. Layers

| Layers | Reused | New | Compressed size | Verdict |
|---|---|---|---|---|
| 10 | 10 (TOUS) | 0 | 112 043 173 bytes (~112 MB) | OK parite DEV |

### 3. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| API PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| API DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| Client PROD | v3.5.201-register-polish-prod | INCHANGE |
| Client DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |

### 4. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build | OUI | aucun build run |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl set/patch/edit/delete | OUI | uniquement get |
| restart pod | OUI | uptime preserve |
| manifest GitOps change | OUI | aucune commande git en infra |
| appel LLM | OUI | aucun |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB |
| changement Linear statut | OUI | comment only |
| secrets/tokens dans logs | OUI | aucun token displayed |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API AI DRAFT BLOCKEDINFO PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod |
| Manifest digest GHCR | sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf |
| Config digest match local==GHCR | sha256:14830ddea074ae41748ea4071b27c92987aeddab79f48fbe1fedf80ceb847a0b |
| Manifest size | 2416 |
| Layers | 10 (TOUS reused, parite v3.5.254-DEV from-git) |
| Total compressed bytes | 112 043 173 (~112 MB) |
| OCI revision preserve | 5070e6a61b81d70b0d15cb44ef15ea52e93f898a |
| Runtime API DEV+PROD | INCHANGES |
| Runtime Client DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-API-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API AI DRAFT BLOCKEDINFO PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
