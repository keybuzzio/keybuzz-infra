# PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B PUSH IMAGE Client DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV READY PH-SAAS-T8.12AS.20.11B

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3`.
- **Manifest digest GHCR** : `sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d` (size 2631).
- 11 layers (6 reused, 5 nouveaux bundle Next.js DEV avec patch PH-20.11B AISuggestionSlideOver).
- Total compressed ~105 MB (105 265 923 bytes), config.size 12 915 bytes.
- OCI revision preserve : `fb348356a42c09b4494f7c5454f14b47e223e466`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime Client DEV `v3.5.210-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.201-register-polish-prod` INCHANGE.
- Runtime API + Backend + Website + Admin INCHANGES.
- Aucun manifest GitOps modifie.
- Aucune mutation runtime.

STOP avant APPLY DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T19:09:10Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev |
| Image locale ID | b74b52d60609 |
| Config digest local | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 MATCH expected |
| Size local | 280 MB |
| OCI revision label | fb348356a42c09b4494f7c5454f14b47e223e466 |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 DOCKER PUSH GHCR DEV

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
5ca998bc3e3f: Pushed
46c6a50c19f9: Pushed
eab731ba1d7e: Pushed
73ef6e5d0424: Pushed
514f3694b2a8: Pushed
v3.5.211-ai-draft-blocked-reason-dev: digest: sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6/11 |
| Layers nouveaux | 5 (bundle Next.js DEV avec patch PH-20.11B) |
| Manifest digest GHCR | sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d |
| Manifest size | 2631 bytes |
| config.size | 12 915 bytes |
| Total layer bytes (compressed) | 105 265 923 (~105 MB) |
| Push exit code | 0 |

## E2 PULL-BACK VERIFY

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 | **MATCH OK** |
| Manifest digest | n/a | sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev` | OK |
| OCI revision label | fb348356a42c09b4494f7c5454f14b47e223e466 | preserve via push | OK |

## E3 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.210-register-polish-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.21-pricing-action-recover-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.21-pricing-action-recover-prod | INCHANGE |
| keybuzz-backend | keybuzz-backend-dev | v1.0.47-cross-env-guard-fix-dev | INCHANGE |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Bundle audite avant push (PH-20.11B BUILD DEV rapport) :
- `Brouillon IA` = 6, `Suggestion IA` = 4, `Aide IA` = 10 (preserve).
- Markers PH-20.11B LIVE 4/4 : `blockedInfo=2`, `Garde-fou actif=2`, `Brouillon IA bloque par securite=2`, `Validation humaine recommandee=2`.
- KEY-263 DEV isolation : `api-dev.keybuzz.io=87`, `api.keybuzz.io` PROD=0.

L'image pushee correspond exactement au build audite (config digest match). Aucune divergence introduite par le push.

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

- AUCUN docker build (image deja construite PH-20.11B BUILD DEV).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token / Pixel ID affiche.
- AUCUN PII brut.
- AUCUN faux register / lead / formulaire / event.
- AUCUN ticket Linear modifie statut.
- AUCUN changement API/Backend/Website/Admin.
- Doctrine seller-first/refund-protection (autopilotGuardrails.ts) INCHANGE 100%.
- KEY-305 fix race UI preserve dans source.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si APPLY DEV provoque regression :
1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.210-register-polish-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.11B to v3.5.210"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=180s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV READY PH-SAAS-T8.12AS.20.11B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ai-draft-blocked-reason-dev |
| Manifest digest GHCR | sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d |
| Config digest match local==GHCR | sha256:b74b52d606094fc1ad9d372291318113159c0cc6c791c9ba64857ee9322558b3 |
| Manifest size | 2631 |
| Layers | 11 (6 reused, 5 nouveaux pour bundle DEV) |
| Total compressed bytes | 105 265 923 (~105 MB) |
| OCI revision preserve | fb348356a42c09b4494f7c5454f14b47e223e466 |
| Runtime Client DEV/PROD | INCHANGES |
| Runtime API/Backend/Website/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT AI DRAFT AUTOPILOT INBOX UX BLOCKED REASON DEV PH-SAAS-T8.12AS.20.11B`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
