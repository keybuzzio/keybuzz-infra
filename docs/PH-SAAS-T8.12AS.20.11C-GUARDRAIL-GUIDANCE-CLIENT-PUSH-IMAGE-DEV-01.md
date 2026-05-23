# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-DEV-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 / KEY-231 / KEY-305 (related) ; KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE PUSH IMAGE Client DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4`.
- **Manifest digest GHCR** : `sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff` (size 2631).
- 11 layers (6 reused, 5 nouveaux : Next.js bundle avec guidance PH-20.11C).
- Total compressed ~105 MB (105 268 500 bytes), config.size 12 915 bytes.
- OCI revision preserve : `1a30ad925fed3fb0b237e7b82694c2f839bc0778`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime Client DEV `v3.5.213-ai-draft-blocked-reason-dev` INCHANGE.
- Runtime Client PROD INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun manifest GitOps modifie.

STOP avant APPLY Client DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T01:23:15Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev |
| Image locale ID | 74d13025bd24 |
| Config digest local | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 MATCH expected |
| Size local | 280 MB |
| OCI revision label | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Tag | GHCR avant push | Verdict |
|---|---|---|
| v3.5.214-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) | OK |

## E2 DOCKER PUSH GHCR DEV

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
74266e55d559: Pushed
c3374fd0af2b: Pushed
472e53188eb8: Pushed
467e1d18eea3: Pushed
2fdde3ac441f: Pushed
v3.5.214-ai-draft-blocked-reason-dev: digest: sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6/11 |
| Layers nouveaux | 5 (Next.js bundle avec guidance PH-20.11C) |
| Manifest digest GHCR | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff |
| Manifest size | 2631 bytes |
| config.size | 12 915 bytes |
| Total layer bytes (compressed) | 105 268 500 (~105 MB) |
| Push exit code | 0 |

## E3 PULL-BACK VERIFY

| Controle | Attendu | Resultat | Verdict |
|---|---|---|---|
| Config digest local | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | identique | **MATCH OK** |
| Config digest GHCR | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | identique | **MATCH OK** |
| Manifest digest GHCR | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | OK | OK |
| Repo digest pulled-back | `ghcr.io/keybuzzio/keybuzz-client@sha256:072e22e4d95d...` | identique | OK |
| Pull idempotence | `Image is up to date` | identique | OK |
| OCI revision label | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | preserve | OK |

## E4 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.213-ai-draft-blocked-reason-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | **v3.5.254-ai-draft-blocked-reason-dev** | INCHANGE LIVE |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11C-GUARDRAIL-GUIDANCE-CLIENT-BUILD-DEV audite (config digest match) :
- Guidance PH-20.11C LIVE 7/7 markers (Trame=2, Point de depart=2, sans generation IA=2, consommation KBActions=2, ne peux pas confirmer=2, remboursement remplacement=2, Copier la trame=4).
- AutoOpen PH-20.11B pattern compile preserve.
- Markers PH-20.11B preserve (blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque=2, Validation humaine=2).
- AI feature parity (6/4/10) preserve.
- KEY-263 isolation strict (api-dev=87, PROD=0).
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

- AUCUN docker build (image deja construite en BUILD Client DEV PH-20.11C).
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
- KEY-305 fix race UI preserve dans bundle compile.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si APPLY DEV provoque regression :
1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.213-ai-draft-blocked-reason-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.11C-GUARDRAIL-GUIDANCE to v3.5.213"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Image push

| Image | Tag | Config digest local | Config digest GHCR | Manifest digest | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | MATCH OK |

### 2. Layers

| Layers | Reused | New | Compressed size | Verdict |
|---|---|---|---|---|
| 11 | 6 | 5 | 105 268 500 bytes (~105 MB) | OK |

### 3. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client DEV | v3.5.213-ai-draft-blocked-reason-dev | INCHANGE |
| Client PROD | v3.5.201-register-polish-prod | INCHANGE |
| API DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| API PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

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
| Verdict | GO PUSH IMAGE CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev |
| Manifest digest GHCR | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff |
| Config digest match local==GHCR | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 |
| Manifest size | 2631 |
| Layers | 11 (6 reused, 5 nouveaux Next.js bundle guidance) |
| Total compressed bytes | 105 268 500 (~105 MB) |
| OCI revision preserve | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Runtime Client DEV/PROD | INCHANGES |
| Runtime API DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT GUARDRAIL GUIDANCE DEV PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
