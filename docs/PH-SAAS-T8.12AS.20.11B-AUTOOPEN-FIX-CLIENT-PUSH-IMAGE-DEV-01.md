# PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-PUSH-IMAGE-DEV-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX PUSH IMAGE Client DEV GHCR
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucun restart pod)

## VERDICT

GO PUSH IMAGE CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev` pushee sur GHCR.
- **Config digest MATCH local == GHCR** : `sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb`.
- **Manifest digest GHCR** : `sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462` (size 2631).
- 11 layers (6 reused, 5 nouveaux : Next.js bundle avec patch autoOpen).
- Total compressed ~105 MB (105 266 239 bytes), config.size 12 913 bytes.
- OCI revision preserve : `d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6`.
- Pull-back idempotence OK (`Image is up to date`).
- Runtime Client DEV `v3.5.212-ai-draft-blocked-reason-dev` INCHANGE.
- Runtime Client PROD INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun manifest GitOps modifie.

STOP avant APPLY Client DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T00:06:57Z |
| Tag cible | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev |
| Image locale ID | 3158c38651e1 |
| Config digest local | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb MATCH expected |
| Size local | 280 MB |
| OCI revision label | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 |
| GHCR collision avant push | manifest unknown (LIBRE) |

## E1 GHCR COLLISION

| Tag | GHCR avant push | Verdict |
|---|---|---|
| v3.5.213-ai-draft-blocked-reason-dev | manifest unknown (LIBRE) | OK |

## E2 DOCKER PUSH GHCR DEV

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
c5f4be7c1382: Pushed
1a0ae14253a9: Pushed
556250c12d74: Pushed
d82036affe4a: Pushed
3f5ae7e1c9a6: Pushed
v3.5.213-ai-draft-blocked-reason-dev: digest: sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6/11 |
| Layers nouveaux | 5 (Next.js bundle avec patch autoOpen) |
| Manifest digest GHCR | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 |
| Manifest size | 2631 bytes |
| config.size | 12 913 bytes |
| Total layer bytes (compressed) | 105 266 239 (~105 MB) |
| Push exit code | 0 |

## E3 PULL-BACK VERIFY

| Controle | Attendu | Resultat | Verdict |
|---|---|---|---|
| Config digest local | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | identique | **MATCH OK** |
| Config digest GHCR | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | identique | **MATCH OK** |
| Manifest digest GHCR | (calcule) | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | OK |
| Repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:f7c4615aa1cb... | identique | OK |
| Pull idempotence | `Image is up to date` | identique | OK |
| OCI revision label | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | preserve | OK |

## E4 RUNTIME NON-REGRESSION POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.212-ai-draft-blocked-reason-dev** | INCHANGE (cible PUSH non deployee) |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | **v3.5.254-ai-draft-blocked-reason-dev** | INCHANGE LIVE |
| keybuzz-api | keybuzz-api-prod | v3.5.252-meta-capi-emq-prod | INCHANGE |

Aucun kubectl apply/set/patch/edit. Aucun restart pod. Aucun manifest GitOps modifie.

## AI FEATURE PARITY / ANTI-REGRESSION

Image pushee correspond exactement au build PH-20.11B-AUTOOPEN-FIX-CLIENT-BUILD-DEV audite (config digest match) :
- Pattern compile autoOpen `draftText || blocked` PRESENT dans bundle (preuve PH-20.11B-AUTOOPEN-FIX-CLIENT-BUILD-DEV-01).
- Bundle markers PH-20.11B : blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque par securite=2, Validation humaine recommandee=2.
- AI feature parity preserve : Brouillon IA=6, Suggestion IA=4, Aide IA=10.
- KEY-263 isolation strict : api-dev.keybuzz.io=87, api.keybuzz.io PROD=0.
- KEY-302 sentinel : 0.
- KEY-305 race fix preserve dans bundle compile (`es.current!==d`).
- Doctrine seller-first INCHANGE 100% (autopilotGuardrails.ts non touche dans cette phase).

Aucune divergence introduite par le push.

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Push container Docker uniquement | OK | OK |
| Aucun appel LLM | 0 | OK |
| Aucun event marketing | 0 | OK |
| Aucun lead/register/checkout test | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun appel Meta/GA/LinkedIn/TikTok | 0 | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD Client DEV PH-20.11B-AUTOOPEN-FIX).
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
- KEY-305 fix race UI preserve dans bundle compile.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si APPLY DEV provoque regression :
1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.212-ai-draft-blocked-reason-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.11B-AUTOOPEN-FIX to v3.5.212"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Image push

| Image | Tag | Config digest local | Config digest GHCR | Manifest digest | Verdict |
|---|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client | v3.5.213-ai-draft-blocked-reason-dev | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | MATCH OK |

### 2. Layers

| Layers | Reused | New | Compressed size | Verdict |
|---|---|---|---|---|
| 11 | 6 | 5 | 105 266 239 bytes (~105 MB) | OK |

### 3. Runtime

| Service | Runtime actuel | Verdict |
|---|---|---|
| Client DEV | v3.5.212-ai-draft-blocked-reason-dev | INCHANGE |
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
| Verdict | GO PUSH IMAGE CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev |
| Manifest digest GHCR | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 |
| Config digest match local==GHCR | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb |
| Manifest size | 2631 |
| Layers | 11 (6 reused, 5 nouveaux Next.js bundle autoOpen) |
| Total compressed bytes | 105 266 239 (~105 MB) |
| OCI revision preserve | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 |
| Runtime Client DEV/PROD | INCHANGES |
| Runtime API DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT AI DRAFT AUTOOPEN ESCALATION DEV PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX`

STOP. Aucun deploy, aucun kubectl, aucun build supplementaire, aucun changement Linear statut.
