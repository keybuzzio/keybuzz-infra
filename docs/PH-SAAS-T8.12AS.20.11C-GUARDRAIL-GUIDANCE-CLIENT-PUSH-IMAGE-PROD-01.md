# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 / KEY-231 / KEY-305 (related) ; KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE PUSH IMAGE Client PROD GHCR
> Environnement : Push GHCR PROD only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1`.
- **Manifest digest GHCR** : `sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77` (size 2631).
- 11 layers (6 reused, 5 nouveaux : Next.js bundle PROD avec guidance PH-20.11C + endpoint api.keybuzz.io).
- Total compressed ~105 MB (105 266 910 bytes), config.size 12 921 bytes.
- OCI revision preserve : `1a30ad925fed3fb0b237e7b82694c2f839bc0778`.
- Pull-back idempotence OK.
- Runtime Client PROD `v3.5.201-register-polish-prod` INCHANGE.
- Runtime API PROD `v3.5.255-ai-draft-blocked-reason-prod` INCHANGE LIVE.
- Runtime DEV (Client + API) INCHANGE LIVE.
- Aucun manifest GitOps modifie.

STOP avant APPLY Client PROD GitOps strict.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T10:40:23Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod |
| Image locale ID | 38474f0835c1 |
| Config digest local | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 MATCH expected |
| Size local | 280 MB |
| OCI revision label | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Tag | GHCR avant push | Verdict |
|---|---|---|
| v3.5.215-ai-draft-blocked-reason-prod | manifest unknown (LIBRE) | OK |

## E2 DOCKER PUSH GHCR PROD

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
a60df57ea450: Pushed
9556ddc2a1d6: Pushed
2ca6b883e056: Pushed
2f4d8255bc48: Pushed
f6828c5ae5cd: Pushed
v3.5.215-ai-draft-blocked-reason-prod: digest: sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6/11 |
| Layers nouveaux | 5 (Next.js bundle PROD avec guidance + api.keybuzz.io endpoint) |
| Manifest digest GHCR | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 |
| Manifest size | 2631 bytes |
| config.size | 12 921 bytes |
| Total layer bytes (compressed) | 105 266 910 (~105 MB) |
| Push exit code | 0 |

## E3 PULL-BACK VERIFY

| Controle | Attendu | Resultat | Verdict |
|---|---|---|---|
| Config digest local | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | identique | **MATCH OK** |
| Config digest GHCR | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | identique | **MATCH OK** |
| Manifest digest GHCR | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | OK | OK |
| Repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:ae312d263c91... | identique | OK |
| Pull idempotence | `Image is up to date` | identique | OK |
| OCI revision label | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | preserve | OK |

## E4 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-prod | **v3.5.201-register-polish-prod** | INCHANGE (cible PUSH non deployee) |
| keybuzz-api | keybuzz-api-prod | v3.5.255-ai-draft-blocked-reason-prod | INCHANGE LIVE PH-20.11C |
| keybuzz-client | keybuzz-client-dev | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | keybuzz-api-dev | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-PROD audite (config digest match) :
- Guidance PH-20.11C LIVE 7/7 markers.
- AutoOpen PH-20.11B pattern compile preserve LIVE.
- AI feature parity preserve (6/4/10).
- KEY-263 PROD isolation strict (api.keybuzz.io=87, api-dev=0).
- KEY-302 sentinel=0.
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

- AUCUN docker build (image deja construite en BUILD Client PROD PH-20.11C).
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
- Doctrine seller-first/refund-protection INCHANGE 100%.
- KEY-263 PROD isolation respectee.
- KEY-302 sentinel preserve.
- KEY-305 fix race UI preserve dans bundle compile.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si APPLY PROD provoque regression :
1. Editer `k8s/keybuzz-client-prod/deployment.yaml` -> image `v3.5.201-register-polish-prod`.
2. `git add + commit -m "ops(client-prod): ROLLBACK PH-20.11C to v3.5.201"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Image push

| Image | Tag | Config digest local | Config digest GHCR | Manifest digest | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.215-ai-draft-blocked-reason-prod | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | MATCH OK |

### 2. Layers

| Layers | Reused | New | Compressed size | Verdict |
|---|---|---|---|---|
| 11 | 6 | 5 | 105 266 910 bytes (~105 MB) | OK |

### 3. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client PROD | v3.5.201-register-polish-prod | INCHANGE |
| API PROD | v3.5.255-ai-draft-blocked-reason-prod | INCHANGE LIVE |
| Client DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| API DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |

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
| Verdict | GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod |
| Manifest digest GHCR | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 |
| Config digest match local==GHCR | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 |
| Manifest size | 2631 |
| Layers | 11 (6 reused, 5 nouveaux Next.js bundle PROD guidance) |
| Total compressed bytes | 105 266 910 (~105 MB) |
| OCI revision preserve | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT GUARDRAIL GUIDANCE PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
