# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-APPLY-DEV-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER APPLY DEV
> Environnement : GitOps strict DEV uniquement / aucun PROD

## VERDICT

GO APPLY CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.205-register-state-persistence-dev -> v3.5.206-clarity-register-dev.
- Infra commit `a304016` push origin/main.
- kubectl apply -f manifest : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out` (1 old replica drained, 1 new pod Ready).
- Pod nouveau : `keybuzz-client-8566958968-4s8mf` Ready 1/1, 0 restart.
- Runtime digest DEV : `sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d` MATCH GHCR push.
- Smoke /register DEV HTTP 200 (3 plans testes). Smoke /login DEV HTTP 200.
- Clarity injection LIVE chunk `app/layout-f6f4b71a7c61021d.js` : wuk12h9i33=1, clarity.ms/tag=1, ms-clarity=1.
- PROD `v3.5.199-register-state-persistence-prod` INCHANGE.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | 0920993 (rapport PUSH-IMAGE) |
| keybuzz-infra HEAD apres | a304016 (ops apply DEV) |
| Runtime Client DEV avant | v3.5.205-register-state-persistence-dev (digest be24d91500c2) |
| Runtime Client PROD avant | v3.5.199-register-state-persistence-prod (digest dbeb9d53966d) |
| Image GHCR target | v3.5.206-clarity-register-dev (manifest digest sha256:16e95517b0c45fda) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-dev/deployment.yaml | count = 1 (attendu 1) |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres bump | `image: ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev` + commentaire annotation |
| Annotation commentaire | commit Client dad5f89, KEY-339 Clarity wuk12h9i33, KEY-263 isolation, PH-19.x preserves, no fake events, rollback v3.5.205 |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | a304016 ops(client-dev): deploy v3.5.206-clarity-register-dev |
| Push | OK 0920993..a304016 main -> main |
| Local == Origin | OK a304016ee38fcd9d1adff413833cb07cc15d3462 |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-client configured
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | < 90s (drain old + new Ready) |
| Pod new | keybuzz-client-8566958968-4s8mf |
| Pod ready | true |
| Pod restarts | 0 |
| Pod creationTimestamp | 2026-05-21T12:18:30Z |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d |
| Match GHCR push digest | OK |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d | MATCH GHCR push |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | (inchange) | OK PROD INTACT |

| Deployment status | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 SMOKE TESTS DEV

| URL | Code |
|---|---|
| https://client-dev.keybuzz.io/register | 200 |
| https://client-dev.keybuzz.io/register?plan=starter | 200 |
| https://client-dev.keybuzz.io/register?plan=autopilot | 200 |
| https://client-dev.keybuzz.io/login | 200 |

## E6 CLARITY INJECTION LIVE CHUNK VERIFY

13 chunks JS scannes dans /register?plan=autopilot. Pattern Clarity attendu UNIQUEMENT dans le chunk layout (SaaSAnalytics est monte dans `app/layout.tsx`).

| Chunk | wuk12h9i33 | clarity.ms/tag | ms-clarity |
|---|---|---|---|
| `app/layout-f6f4b71a7c61021d.js` | **1** | **1** | **1** |
| `app/register/page-f7808baeb00480d2.js` | 0 | 0 | 0 |
| 11 autres chunks | 0 | 0 | 0 |
| **TOTAL bundle live runtime** | **1** | **1** | **1** |

Clarity actif uniquement sur les routes /register et /login (FUNNEL_PREFIXES), confirme par la presence du loader dans le chunk layout charge par toutes les routes mais avec gate runtime `isFunnelPage(pathname) && !isBlockedPage(pathname)` dans le code SaaSAnalytics.

### Chunk register PH-19.x preservation

| Pattern | Observe | Verdict |
|---|---|---|
| kb_signup_form_draft_v1 | 2 | OK PH-19.7 preserve |
| kb_signup_cgu_accepted | 2 | OK PH-19.6 preserve |
| data-clarity-mask | 13 | OK PII protection inchangee |
| plan_selected emit | 1 unique | OK KEY-331 preserve |

Note : le chunk register hash `page-f7808baeb00480d2.js` est inchange vs v3.5.205, ce qui confirme que aucune modification de la source register n a ete effectuee dans cette phase (le patch Clarity n a touche que `src/components/tracking/SaaSAnalytics.tsx` + `Dockerfile`).

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Clarity actif uniquement sur funnel pre-auth (/register, /login).
- 0 `clarity.set(...)` avec PII en source.
- 0 nouveau Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout dans le bundle delta.
- Marketing IDs GA4/Meta/TikTok/SGTM/AW toujours omis cote Client DEV (iso baseline v3.5.205).
- plan_selected emit unique preserve.

## CONFIRMATIONS SECURITE

- AUCUN docker push (image deja sur GHCR avant cette phase).
- AUCUN build.
- AUCUN PROD touche (runtime PROD v3.5.199 INCHANGE).
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN ticket Linear cree, ferme, ou statut modifie automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.205-register-state-persistence-dev` (digest `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621`).
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.2 to v3.5.205"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. /login route inclus dans FUNNEL_PREFIXES : Clarity y est actif. A QA navigateur DEV par Ludovic : verifier que Clarity masque automatiquement le champ password (default Clarity behavior + Antoine console Clarity verification).
2. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis DEV iso baseline.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2 |
| keybuzz-infra HEAD apres apply | a304016 |
| Client DEV runtime tag | v3.5.206-clarity-register-dev |
| Client DEV runtime digest | sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d |
| Pod | keybuzz-client-8566958968-4s8mf Ready 1/1, 0 restart |
| Source commit Client | dad5f89 |
| Smoke /register DEV | HTTP 200 (3 plans testes) |
| Smoke /login DEV | HTTP 200 |
| Clarity chunk live | app/layout-f6f4b71a7c61021d.js : wuk12h9i33=1, clarity.ms/tag=1, ms-clarity=1 |
| PH-19.x preserves | data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected emit unique |
| No fake events delta | 0 |
| Runtime PROD | v3.5.199-register-state-persistence-prod INCHANGE |
| NO kubectl set/patch/edit | OK (GitOps strict) |
| Rollback tag DEV | v3.5.205-register-state-persistence-dev digest sha256:be24d91500c2... |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA CLIENT CLARITY REGISTER DEV PH-SAAS-T8.12AS.20.2` (QA navigateur Ludovic / Antoine : verifier session Clarity capturee + masking inputs PII)

STOP.
