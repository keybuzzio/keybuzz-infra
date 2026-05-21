# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-APPLY-PROD-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER APPLY PROD
> Environnement : GitOps strict PROD / aucun build / aucun docker push / aucun DEV change

## VERDICT

GO APPLY CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2

- Manifest `k8s/keybuzz-client-prod/deployment.yaml` bumpe v3.5.199-register-state-persistence-prod -> v3.5.200-clarity-register-prod.
- Infra commit `13175da` push origin/main.
- kubectl apply -f manifest : `deployment.apps/keybuzz-client configured`.
- Rollout PROD : `deployment "keybuzz-client" successfully rolled out` (1 old replica drained, 1 new pod Ready).
- Pod nouveau : `keybuzz-client-56c4fc6d54-f4mhw` Ready, Running.
- Runtime digest PROD : `sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987` MATCH GHCR push.
- Smoke /register PROD HTTP 200 (3 plans testes). Smoke /login PROD HTTP 200.
- Clarity injection LIVE PROD chunk `app/layout-f5c5d79eb8d37f18.js` : wuk12h9i33=1, clarity.ms/tag=1, ms-clarity=1.
- PH-19.x preserves chunk register : data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2.
- Runtime DEV `v3.5.206-clarity-register-dev` INCHANGE.
- API DEV/PROD INCHANGES.
- Website DEV/PROD INCHANGES.
- Reserve R1 PH-20.1 (Clarity Client absent) ADRESSEE.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | 47ec45d (rapport PUSH-IMAGE PROD) |
| keybuzz-infra HEAD apres | 13175da (ops apply PROD) |
| Runtime Client DEV avant | v3.5.206-clarity-register-dev |
| Runtime Client PROD avant | v3.5.199-register-state-persistence-prod (digest sha256:dbeb9d53966d...) |
| Image GHCR target | v3.5.200-clarity-register-prod (manifest digest sha256:f22413551a3cf2c7...) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-prod/deployment.yaml | count = 1 (attendu 1) |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.76) apres bump | `image: ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod` + commentaire annotation |
| Annotation commentaire | commit Client dad5f89, KEY-339 Clarity wuk12h9i33, KEY-263 isolation PROD, PH-19.x preserves, no fake events, KEY-338 reserve R1 adressee, rollback v3.5.199 |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-prod/deployment.yaml (1 fichier) |
| Commit | 13175da ops(client-prod): deploy v3.5.200-clarity-register-prod |
| Push | OK 47ec45d..13175da main -> main |
| Local | 13175da736c328f0763bbc520b7498e9d451cac8 |

## E3 KUBECTL APPLY + ROLLOUT PROD

```
deployment.apps/keybuzz-client configured
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | < 90s (drain old + new Ready) |
| Pod new | keybuzz-client-56c4fc6d54-f4mhw |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 |
| Match GHCR push digest | OK |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 | **MATCH GHCR push** |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | (inchange) | OK DEV INCHANGE |

| Deployment status PROD | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 SMOKE TESTS PROD

| URL | Code |
|---|---|
| https://client.keybuzz.io/register | 200 |
| https://client.keybuzz.io/register?plan=starter | 200 |
| https://client.keybuzz.io/register?plan=autopilot | 200 |
| https://client.keybuzz.io/login | 200 |

## E6 CLARITY INJECTION LIVE PROD CHUNK VERIFY

13 chunks JS scannes dans /register?plan=autopilot. Clarity attendu uniquement dans chunk layout (SaaSAnalytics monte dans `app/layout.tsx`).

| Chunk | wuk12h9i33 | clarity.ms/tag | ms-clarity |
|---|---|---|---|
| `app/layout-f5c5d79eb8d37f18.js` | **1** | **1** | **1** |
| `app/register/page-f7808baeb00480d2.js` | 0 | 0 | 0 |
| 11 autres chunks | 0 | 0 | 0 |
| **TOTAL bundle live runtime PROD** | **1** | **1** | **1** |

Note : chunk layout hash PROD `f5c5d79eb8d37f18.js` different du DEV `f6f4b71a7c61021d.js` (build args distincts : `api.keybuzz.io` PROD vs `api-dev.keybuzz.io` DEV). Clarity actif uniquement sur les routes FUNNEL_PREFIXES /register et /login via gate runtime `isFunnelPage(pathname) && !isBlockedPage(pathname)`.

### Chunk register PH-19.x preservation runtime

| Pattern | Observe runtime | Verdict |
|---|---|---|
| kb_signup_form_draft_v1 | 2 | OK PH-19.7 preserve |
| kb_signup_cgu_accepted | 2 | OK PH-19.6 preserve |
| data-clarity-mask | 13 | OK PII protection inchangee |
| plan_selected (chunk register) | 1 | OK source emit unique preserve |

Note : chunk register hash `page-f7808baeb00480d2.js` identique a v3.5.199 PROD et v3.5.206 DEV, ce qui confirme que aucune modification de la source register n a ete effectuee dans cette phase (le patch Clarity n a touche que `src/components/tracking/SaaSAnalytics.tsx` + `Dockerfile`).

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Clarity actif uniquement sur funnel pre-auth (/register, /login) en PROD.
- 0 `clarity.set(...)` avec PII en source.
- 0 nouveau Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout dans le bundle delta vs v3.5.199.
- Marketing IDs GA4/Meta/TikTok/SGTM/AW toujours omis cote Client PROD (iso baseline v3.5.199).
- plan_selected emit unique preserve.

## E8 RESERVES PH-20.1 ETAT POST-APPLY

| Reserve | Etat avant APPLY PROD | Etat apres APPLY PROD |
|---|---|---|
| R1 Clarity client absent | NON ACTIVE | **ADRESSEE - Clarity active sur /register et /login PROD** |
| R2 CTA home + pages secondaires non trackes | OUVERT | OUVERT (PH-20.3) |
| R3 Compte demo absent | OUVERT | OUVERT (PH-20.4) |
| R4 ad_spend Google bloque par token KO | OUVERT | OUVERT (KEY-322) |
| R5 Pixels Meta/TikTok/LinkedIn ABSENTS Website (decision server-side only) | EXPLICITER AGENCE | EXPLICITER AGENCE (inchange par decision strategique) |
| R6 Hardening post-incident hors scope | OUVERT | OUVERT (KEY-323) |

R1 PH-20.1 ADRESSEE. Le tunnel register PROD est desormais instrumente avec Microsoft Clarity (UX analytics : heatmaps, session replay, rage clicks, dead clicks). Antoine peut commencer a observer les sessions des prospects sur /register et /login.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja sur GHCR avant cette phase).
- AUCUN docker push.
- AUCUN DEV change (runtime DEV v3.5.206 INCHANGE).
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN ticket Linear cree, ferme, ou statut modifie automatiquement.
- Clarity Project ID `wuk12h9i33` inline dans le bundle JS PROD (comportement attendu pour tracking client-side, ID non-secret visible cote Microsoft Clarity).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT PROD

1. Editer `k8s/keybuzz-client-prod/deployment.yaml` -> image `v3.5.199-register-state-persistence-prod` (digest `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a`).
2. `git add + commit -m "ops(client-prod): ROLLBACK PH-20.2 to v3.5.199"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. /login route inclus dans FUNNEL_PREFIXES : Clarity y est actif PROD. Default Clarity behavior masque automatiquement les champs password. A QA navigateur Ludovic/Antoine sur PROD.
2. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis Client PROD iso baseline.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2 |
| keybuzz-infra HEAD apres apply | 13175da |
| Client PROD runtime tag | v3.5.200-clarity-register-prod |
| Client PROD runtime digest | sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 |
| Pod | keybuzz-client-56c4fc6d54-f4mhw Ready, Running |
| Source commit Client | dad5f89 |
| Smoke /register PROD | HTTP 200 (3 plans testes) |
| Smoke /login PROD | HTTP 200 |
| Clarity chunk live PROD | app/layout-f5c5d79eb8d37f18.js : wuk12h9i33=1, clarity.ms/tag=1, ms-clarity=1 |
| PH-19.x preserves | data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected emit unique preserve |
| No fake events delta vs v3.5.199 | 0 |
| Runtime DEV | v3.5.206-clarity-register-dev INCHANGE |
| Runtime API/Website/Admin | INCHANGES |
| NO kubectl set/patch/edit | OK (GitOps strict) |
| Rollback tag PROD | v3.5.199-register-state-persistence-prod digest sha256:dbeb9d53966d... |
| Reserve R1 PH-20.1 (Clarity Client absent) | ADRESSEE |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-APPLY-PROD-01.md` |

### Prochaine phrase GO attendue

`GO QA CLIENT CLARITY REGISTER PROD PH-SAAS-T8.12AS.20.2`

QA navigateur Ludovic + Antoine recommandee sur PROD :

- Ouvrir `https://client.keybuzz.io/register?plan=autopilot` -> verifier console Clarity Network : `clarity.ms/tag/wuk12h9i33` charge, sans erreur.
- Verifier session capturee dans projet Clarity Antoine pour PROD.
- Verifier masking inputs PII via `data-clarity-mask` (email, password, company, phone, address, firstName, lastName, siret, supportEmail, street, zipCode, city, country, companyPhone).
- Verifier que `/inbox`, `/dashboard`, `/onboarding`, `/billing`, `/settings`, `/orders`, `/channels`, `/suppliers`, `/knowledge`, `/playbooks`, `/ai-journal`, `/workspace-setup`, `/start`, `/help` post-auth N EMETTENT PAS de session Clarity (routes blocked).
- Verifier que /login Clarity actif mais champ password masque automatiquement par defaut.

STOP.
