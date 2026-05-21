# PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-APPLY-DEV-01

> Date : 2026-05-21
> Linear : KEY-342 (accents FR) ; KEY-345 (0 EUR every step + benefits) ; KEY-343 (UX billing error) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6 REGISTER POLISH APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.206-clarity-register-dev -> v3.5.207-register-polish-dev.
- Infra commit `6a121f3` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-79b78584bd-b44sz` Ready, Running.
- Runtime digest DEV : `sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1` MATCH GHCR push.
- readyReplicas 1/1.
- Smokes 4/4 HTTP 200 : `/register`, `/register?plan=starter`, `/register?plan=autopilot`, `/login`.
- Bundle live LIVE : register-trial-value-banner=1, Cockpit SAV marketplace=1, "Votre espace a bien"=1, Clarity wuk12h9i33=1, data-clarity-mask=13, api.keybuzz.io seul=0 (KEY-263 isolation DEV OK).
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV/PROD INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | c4508f7 (rapport PUSH IMAGE DEV) |
| keybuzz-infra HEAD apres | 6a121f3 (ops apply DEV) |
| Runtime Client DEV avant | v3.5.206-clarity-register-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |
| Image GHCR target | v3.5.207-register-polish-dev (manifest digest sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres bump | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev + annotation PH-20.6 |
| Annotation commentaire | commit client 3f88217, KEY-342/345/343, KEY-263 isolation, KEY-302 Clarity, PH-19.x preserves, SaaSAnalytics INCHANGE, 0 fake event, nouveaux markers, rollback, digest |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | 6a121f3 ops(client-dev): deploy v3.5.207-register-polish-dev |
| Push | OK c4508f7..6a121f3 main -> main |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-client configured
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-45s |
| Pod new | keybuzz-client-79b78584bd-b44sz |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 |
| Match GHCR push digest | **OK** |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.207-register-polish-dev | sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 | **MATCH GHCR push** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | (inchange) | OK PROD INTACT |

| Deployment status DEV | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 SMOKES NON-MUTANTS (via port-forward pod direct)

| URL (http://127.0.0.1:13001) | HTTP | Bytes | Verdict |
|---|---|---|---|
| /register | 200 | 9188 | OK |
| /register?plan=starter | 200 | 9188 | OK |
| /register?plan=autopilot | 200 | 9188 | OK |
| /login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK.

## E6 BUNDLE LIVE AUDIT (register chunks)

Audit live via curl chunks Next.js sur /register :

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| Chunks /register | >= 5 | 13 | OK |
| register-trial-value-banner | >= 1 | 1 | **OK marker PH-20.6 LIVE** |
| Cockpit SAV marketplace | >= 1 | 1 | **OK benefits recap LIVE** |
| Votre espace a bien (UX billing) | >= 1 | 1 | **OK message UX LIVE** |
| data-clarity-mask | >= 13 (source) | 13 | OK preserve LIVE |
| Clarity wuk12h9i33 | >= 1 | 1 | OK Clarity LIVE |
| api-dev.keybuzz.io chunks /register | 0+ | 0 | OK (URL utilisee dans chunks helpers BFF non charges sur /register HTML, chemin relatifs `/api/auth/*` via BFF Next.js) |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | **OK KEY-263 isolation DEV** |

Note technique : `api-dev.keybuzz.io` count LIVE = 0 sur chunks /register specifiques est attendu car les API calls passent par routes Next.js relatives `/api/auth/create-signup` (BFF cote Client qui forward vers l'API). Le NEXT_PUBLIC_API_URL est inlined dans des chunks helpers (verifies en BUILD DEV : 87 occurrences dans le bundle complet). Aucun risque KEY-263.

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- nouveau (0 delta vs baseline v3.5.206).
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads touche.
- Aucun checkout Stripe live ou test.
- Aucun appel API Stripe.
- Aucun faux register PROD ou DEV execute.
- Aucune mutation DB.
- Aucun tracking GA4/CAPI ajoute.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.

## RUNTIME PRESERVE

| Service | Namespace | Image runtime | Preserve |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.207-register-polish-dev** | **NOUVEAU DEV** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja construite + pushe en BUILD + PUSH IMAGE DEV).
- AUCUN PROD touche.
- AUCUN `kubectl set image / set env / patch / edit` (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN faux register.
- AUCUN ticket Linear cree/ferme automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.206-clarity-register-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.6 to v3.5.206"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic recommandee en mobile (360px) et desktop pour visuel TrialValueBanner.
2. preview.keybuzz.pro Client DEV ingress public peut etre indisponible (cert TLS connu depuis PH-20.1). Smokes validation deja faits via port-forward direct au pod = OK.
3. Aucun gap technique sur l apply lui-meme.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6 |
| keybuzz-infra HEAD apres apply | 6a121f3 (ops manifest) |
| Client DEV runtime tag | v3.5.207-register-polish-dev |
| Client DEV runtime digest | sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 |
| Pod | keybuzz-client-79b78584bd-b44sz Ready 1/1 |
| Source commit Client | 3f88217 |
| Smokes /register + variants + /login | 4/4 HTTP 200 |
| Bundle live markers | trial-banner=1, Cockpit SAV=1, UX billing=1, Clarity=1, data-clarity-mask=13 |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v3.5.206-clarity-register-dev |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6`

QA navigateur Ludovic recommandee :
- Port-forward `kubectl port-forward -n keybuzz-client-dev deploy/keybuzz-client 13001:3000` -> http://127.0.0.1:13001/register
- Verifier mobile 360px : TrialValueBanner compact + responsive
- Verifier desktop : TrialValueBanner present + ReassurancePanel sticky preserve
- Cliquer sur differents steps (email, code, company, user, plan, payment) -> verifier accents FR sur tous les libelles
- Tester nom societe `@@@` -> verifier que tenantId fallback fonctionne et message billing error ameliore s affiche (si Stripe DEV fail)

STOP.
