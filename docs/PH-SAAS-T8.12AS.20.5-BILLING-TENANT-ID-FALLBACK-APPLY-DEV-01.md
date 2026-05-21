# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-APPLY-DEV-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5

- Manifest `k8s/keybuzz-api-dev/deployment.yaml` bumpe v3.5.251-register-cro-dev -> v3.5.252-billing-tenant-id-fallback-dev.
- Infra commit `06fdc24` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-api configured`.
- Rollout : `deployment "keybuzz-api" successfully rolled out`.
- Pod nouveau : `keybuzz-api-6cbbfb479c-tk492` Ready, Running.
- Runtime digest DEV : `sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea` MATCH GHCR push.
- **TEST EN RUNTIME REUSSI** : name=`@@@` -> tenantId=`tenant-mpfrggik` (fallback active) -> checkout-session 200 OK + URL Stripe cs_test_.
- Test regression normal : name=`KeyBuzz Test SAS` -> tenantId=`keybuzz-test-sas-mpfrghns` (pattern OK preserve).
- Runtime API PROD `v3.5.250-ad-spend-sync-all-prod` INCHANGE.
- Runtime Client + Website DEV/PROD INCHANGES.
- Cause racine KEY-343 corrigee en DEV. Tenant orphan PROD `-mpfmgx09` Antoine non touche (cleanup PH-20.7 separe).

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | 7cce3d5 (rapport PUSH IMAGE) |
| keybuzz-infra HEAD apres | 06fdc24 (ops apply DEV) |
| Runtime API DEV avant | v3.5.251-register-cro-dev |
| Runtime API PROD avant | v3.5.250-ad-spend-sync-all-prod |
| Image GHCR target | v3.5.252-billing-tenant-id-fallback-dev (manifest digest sha256:5dc670ab8690b77f...) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-api-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.321) apres bump | `image: ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev` + annotation PH-20.5 |
| Annotation commentaire | commit api 6850427c, KEY-343 fix tenantId malforme, fallback slug 'tenant' + defense regex, cas Antoine prevenu, tsc 0 + 10/10 logic tests, rollback v3.5.251, digest |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-api configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-api-dev/deployment.yaml (1 fichier) |
| Commit | 06fdc24 ops(keybuzz-api-dev): deploy v3.5.252-billing-tenant-id-fallback-dev |
| Push | OK 7cce3d5..06fdc24 main -> main |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-api configured
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-api" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | < 60s |
| Pod new | keybuzz-api-6cbbfb479c-tk492 |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea |
| Match GHCR push digest | **OK** |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea | **MATCH GHCR push** |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | (inchange) | OK PROD INTACT |

| Deployment status DEV | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 TEST RUNTIME E2E (port-forward pod 3001)

Test execute via port-forward direct au pod nouveau pour valider le comportement runtime live.

### TEST 1 - name="@@@" (cas Antoine reproductible)

```bash
curl -X POST http://127.0.0.1:18080/tenant-context/create-signup \
  -H "Content-Type: application/json" \
  -H "X-User-Email: ce-test-ph205-tenant-fallback@keybuzz.dev.local" \
  -d '{"name":"@@@","firstName":"CE","lastName":"Test","country":"FR","plan":"starter"}'
```

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| HTTP status | 201 | 201 | OK |
| tenantId returned | tenant-XXX (fallback) | `tenant-mpfrggik` | **FALLBACK ACTIVE OK** |
| Pattern regex billing | match `^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$` | MATCH | OK |
| tenant.name | "@@@" (preserve raw) | "@@@" | OK (raw name conservee en DB) |

### TEST 2 - checkout-session avec tenantId fallback

```bash
curl -X POST http://127.0.0.1:18080/billing/checkout-session \
  -H "Content-Type: application/json" \
  -d '{"tenantId":"tenant-mpfrggik","targetPlan":"STARTER","billingCycle":"monthly","successUrl":...,"cancelUrl":...}'
```

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| HTTP status | 200 (avant: 400 Invalid tenantId format) | 200 | **FIX CONFIRME** |
| Response key | url | url present | OK |
| URL prefix | https://checkout.stripe.com/c/pay/cs_test_ | https://checkout.stripe.com/c/pay/cs_test_b1LJqI5gWposBc6mKNHB7IFXVov... | OK (Stripe DEV cs_test_) |
| Aucun "Invalid tenantId format" | absent | absent | OK |

### TEST 3 - Regression normal name "KeyBuzz Test SAS"

```bash
curl -X POST http://127.0.0.1:18080/tenant-context/create-signup \
  -H "Content-Type: application/json" \
  -H "X-User-Email: ce-test-ph205-normal@keybuzz.dev.local" \
  -d '{"name":"KeyBuzz Test SAS","firstName":"CE","lastName":"Test","country":"FR","plan":"starter"}'
```

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| HTTP status | 201 | 201 | OK |
| tenantId returned | keybuzz-test-sas-XXX | `keybuzz-test-sas-mpfrghns` | **REGRESSION OK** (pattern normal preserve) |
| Pattern regex billing | match | MATCH | OK |
| tenant.name | "KeyBuzz Test SAS" | "KeyBuzz Test SAS" | OK |

## E6 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Preserve |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | **v3.5.252-billing-tenant-id-fallback-dev** | **NOUVEAU DEV** |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout fabrique.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Le TEST 2 a cree une session Stripe TEST `cs_test_` (mode test DEV, pas reel ; aucun debit possible).
- Aucune mutation tracking GA4/CAPI.
- 2 tenants test crees en DB DEV :
  - `tenant-mpfrggik` (user `ce-test-ph205-tenant-fallback@keybuzz.dev.local`) status pending_payment
  - `keybuzz-test-sas-mpfrghns` (user `ce-test-ph205-normal@keybuzz.dev.local`) status pending_payment
- Cleanup tenants test DEV optionnel, non bloquant.

## CONFIRMATIONS SECURITE

- AUCUN docker build supplementaire (image deja sur GHCR apres PUSH IMAGE).
- AUCUN PROD touche en dehors du runtime preserve check.
- AUCUN `kubectl set image / set env / patch / edit` (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB PROD.
- AUCUN ticket Linear cree, ferme, ou statut modifie.
- Tenant orphan PROD `-mpfmgx09` non touche.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-api-dev/deployment.yaml` -> image `v3.5.251-register-cro-dev`.
2. `git add + commit -m "ops(keybuzz-api-dev): ROLLBACK PH-20.5 to v3.5.251"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-dev deploy/keybuzz-api --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Branche `existingPending` (UPDATE tenant existant) reste non patchee. Les tenantId malformes deja en DB orphan ne sont pas mutes par ce patch. Mitigation = cleanup PH-20.7 separe (avec GO Ludovic + confirmation Antoine).
2. 2 tenants test crees en DB DEV pour validation runtime. Pas bloquant, peuvent etre supprimes en cleanup PH-20.7 si souhaite.
3. Session Stripe TEST `cs_test_b1LJqI5gWposBc6mKNHB7IFXVov...` reste creee en mode test, non-debitable. Cleanup Stripe non requis (sessions test expirent automatiquement).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5 |
| keybuzz-infra HEAD apres apply | 06fdc24 (ops manifest) |
| API DEV runtime tag | v3.5.252-billing-tenant-id-fallback-dev |
| API DEV runtime digest | sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea |
| Pod | keybuzz-api-6cbbfb479c-tk492 Ready 1/1 |
| Source commit API | 6850427c |
| **TEST 1 name=@@@ -> tenantId=tenant-mpfrggik** | **FALLBACK ACTIVE OK** |
| **TEST 2 checkout-session 200 OK URL Stripe cs_test_** | **FIX CONFIRME RUNTIME** |
| **TEST 3 regression name normal** | OK pattern preserve |
| API PROD runtime | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Client+Website+Admin DEV+PROD | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v3.5.251-register-cro-dev |
| Tenant orphan PROD -mpfmgx09 | NON TOUCHE (PH-20.7) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA REGISTER BILLING TENANT_ID FALLBACK DEV PH-SAAS-T8.12AS.20.5`

QA navigateur Ludovic recommandee :
- Ouvrir Client DEV register flow (preview ou port-forward Client DEV).
- Tester register avec nom societe = `@@@` ou caracteres speciaux uniquement.
- Verifier que checkout-session reussit (redirection Stripe TEST).
- Verifier flow normal `KeyBuzz Test` non regresse.

Ou bundle Client polish :

`GO BUILD API BILLING TENANT_ID FALLBACK PROD PH-SAAS-T8.12AS.20.5`

`GO PATCH REGISTER ACCENTS + 0EUR + UX BILLING ERROR SOURCE PH-SAAS-T8.12AS.20.6`

STOP.
