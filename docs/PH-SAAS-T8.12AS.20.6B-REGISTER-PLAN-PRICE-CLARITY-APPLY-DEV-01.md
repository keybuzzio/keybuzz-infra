# PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6B REGISTER PLAN PRICE CLARITY APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.208-register-polish-dev -> v3.5.209-register-polish-dev.
- Infra commit `7712327` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-5877dfcc94-qn8xd` Ready, Running.
- Runtime digest DEV : `sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622` MATCH GHCR push.
- readyReplicas 1/1.
- Smokes 4/4 HTTP 200 : `/register` (9188 b), `/register?plan=starter`, `/register?plan=autopilot`, `/login` (8763 b).
- Bundle live PH-20.6B markers LIVE : register-plan-trial-pricing=1, dans 14 jours=1, Tarif annuel=1, 0 EUR=6, maintenant=1.
- Bundle live preserves : register-trial-value-banner=1, data-clarity-mask=13, Clarity wuk12h9i33=1.
- KEY-263 isolation DEV : api.keybuzz.io seul=0.
- Phrases interdites pre-plan TOUTES ABSENTES LIVE : Autopilot inclus=0, Avant de regarder=0, Aucune CB=0.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | bfac338 (rapport PUSH IMAGE DEV PH-20.6B) |
| keybuzz-infra HEAD apres | 7712327 (ops apply DEV) |
| keybuzz-client HEAD | 97bdd5b (PH-20.6B QA fix source) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 GHCR MANIFEST VERIFY

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev |
| config digest GHCR | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 |
| Match config attendu | OK |
| Layers count | 11 |
| Manifest size (layers compressed) | 105 265 295 bytes |

## E2 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres bump | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev + annotation PH-20.6B |
| Annotation commentaire | commit client 97bdd5b, KEY-345 QA fix bloc pricing, design unique sans double prix barre, logique pricing INCHANGE, preserves PH-20.6A, KEY-263 isolation, KEY-302 Clarity, PH-19.x preserves, 0 fake event, rollback v3.5.208, digest GHCR |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E3 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | 7712327 ops(client-dev): deploy v3.5.209-register-polish-dev |
| Push | OK bfac338..7712327 main -> main |

## E4 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-client configured
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-45s |
| Pod new | keybuzz-client-5877dfcc94-qn8xd |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 |
| Match GHCR push digest | **OK** |
| readyReplicas | 1/1 |

## RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.209-register-polish-dev | sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 | **MATCH GHCR push** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | (inchange) | OK PROD INTACT |

## E5 SMOKES NON-MUTANTS (via port-forward pod direct)

| URL (http://127.0.0.1:13003) | HTTP | Bytes | Verdict |
|---|---|---|---|
| /register | 200 | 9188 | OK |
| /register?plan=starter | 200 | 9188 | OK |
| /register?plan=autopilot | 200 | 9188 | OK |
| /login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK.

## E6 BUNDLE LIVE AUDIT (register chunks - 13 chunks scannes)

### PH-20.6B nouveaux markers LIVE

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| register-plan-trial-pricing (data-testid) | >= 1 | 1 | **OK marker LIVE** |
| dans 14 jours (nouvelle copy) | >= 1 | 1 | **OK copy LIVE** |
| Tarif annuel (ligne annuel discrete) | >= 1 | 1 | **OK ligne annuel LIVE** |
| 0 EUR (presence bundle) | >= 1 | 6 | **OK 0 EUR present multi-occurrences** |
| maintenant | >= 1 | 1 | **OK "maintenant" LIVE** |

### Preserves PH-20.6A + PH-19.x

| Pattern | LIVE | Verdict |
|---|---|---|
| register-trial-value-banner (PH-20.6A marker) | 1 | OK preserve |
| data-clarity-mask | 13 | OK preserve LIVE |
| Clarity wuk12h9i33 | 1 | OK Clarity preserve LIVE |

### KEY-263 + phrases interdites pre-plan (doivent etre 0)

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| api.keybuzz.io seul (PROD URL) | 0 | 0 | **OK KEY-263 isolation DEV** |
| Autopilot inclus pendant (interdit pre-plan) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |
| Avant de regarder les plans (interdit) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |
| Aucune CB requise (interdit pre-plan) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |

Note technique : `api-dev.keybuzz.io` count LIVE = 0 sur chunks /register specifiques est attendu (URL utilisee dans chunks helpers BFF non charges sur /register HTML, chemins relatifs `/api/*` via BFF Next.js). Verifie en BUILD DEV PH-20.6B : 87 occurrences dans le bundle complet.

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- nouveau (0 delta vs baseline v3.5.208).
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
| keybuzz-client | keybuzz-client-dev | **v3.5.209-register-polish-dev** | **NOUVEAU DEV** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja construite + pushee en BUILD + PUSH IMAGE DEV PH-20.6B).
- AUCUN PROD touche.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN faux register.
- AUCUN ticket Linear cree/ferme automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.208-register-polish-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.6B to v3.5.208"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic recommandee :
   - port-forward `kubectl port-forward -n keybuzz-client-dev deploy/keybuzz-client 13003:3000` -> http://127.0.0.1:13003/register
   - mobile 360px + desktop
   - naviguer jusqu a l etape `plan`
   - en mensuel : verifier sur les 3 cards (starter/pro/autopilot) le bloc "0 EUR maintenant" + "puis X EUR/mois dans 14 jours" en vert clair
   - basculer en annuel : verifier que le prix affiche reste coherent (displayPrice annuel) + ligne discrete "Tarif annuel : economisez X EUR/an vs mensuel" SANS double prix barre
   - confirmer absence CB/Autopilot inclus dans le bloc (deja absent confirme bundle)
   - verifier preserve grand encart "0 EUR pendant 14 jours" en haut step plan
2. preview.keybuzz.pro Client DEV ingress public peut etre indisponible (cert TLS connu). Smokes deja faits via port-forward direct au pod = OK.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B |
| keybuzz-infra HEAD apres apply | 7712327 (ops manifest) |
| Client DEV runtime tag | v3.5.209-register-polish-dev |
| Client DEV runtime digest | sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 |
| Pod | keybuzz-client-5877dfcc94-qn8xd Ready 1/1 |
| Source commit Client | 97bdd5b |
| Smokes /register + variants + /login | 4/4 HTTP 200 |
| Bundle live nouveaux markers PH-20.6B | trial-pricing=1, dans 14 jours=1, Tarif annuel=1, 0 EUR=6, maintenant=1 |
| Bundle live preserves | trial-banner=1, data-clarity-mask=13, Clarity=1 |
| Bundle live phrases interdites pre-plan | TOUTES ABSENTES |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=1) |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v3.5.208-register-polish-dev |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA REGISTER PLAN PRICE CLARITY DEV PH-SAAS-T8.12AS.20.6B`

QA navigateur Ludovic recommandee mobile 360px + desktop pour valider visuel cards (3 plans starter/pro/autopilot en mensuel ET annuel) + verifier vraie clarte pricing essai vs prix futur sur chaque card.

STOP.
