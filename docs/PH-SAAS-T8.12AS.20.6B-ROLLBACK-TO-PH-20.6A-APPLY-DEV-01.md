# PH-SAAS-T8.12AS.20.6B-ROLLBACK-TO-PH-20.6A-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6B ROLLBACK DEV CLIENT vers PH-20.6A
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO ROLLBACK CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B -> PH-20.6A

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` ROLLBACK v3.5.209-register-polish-dev -> v3.5.208-register-polish-dev.
- Infra commit `efb90e3` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-84d767874f-7bjvf` Ready, Running.
- Runtime digest DEV : `sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0` MATCH attendu (PH-20.6A v3.5.208).
- readyReplicas 1/1.
- Smokes 4/4 HTTP 200 : `/register` (9188 b), `/register?plan=starter`, `/register?plan=autopilot`, `/login` (8763 b).
- **PH-20.6B markers RETIRES du runtime DEV** : register-plan-trial-pricing=0, dans 14 jours=0, Tarif annuel=0.
- **PH-20.6A markers PRESERVES LIVE** : register-trial-value-banner=1, Toutes les fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1.
- data-clarity-mask=13, Clarity wuk12h9i33=1 preserves.
- KEY-263 isolation DEV : api.keybuzz.io seul=0.
- Phrases interdites pre-plan TOUTES ABSENTES LIVE (Autopilot=0, Avant de regarder=0, Aucune CB=0).
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

**PH-20.6B abandonne** car rendu cards non retenu par Ludovic. Runtime DEV revient stable sur PH-20.6A v3.5.208-register-polish-dev.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | abfee84 (rapport APPLY DEV PH-20.6B) |
| keybuzz-infra HEAD apres | efb90e3 (ops ROLLBACK DEV) |
| Runtime Client DEV avant rollback | v3.5.209-register-polish-dev |
| Runtime Client DEV apres rollback | v3.5.208-register-polish-dev |
| Runtime Client PROD | v3.5.200-clarity-register-prod (INCHANGE PROD) |

## E1 ROLLBACK BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres rollback | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev + annotation ROLLBACK |
| Annotation commentaire | PH-20.6B abandonne, rollback DEV vers PH-20.6A v3.5.208, commit client dbdc46f, markers PH-20.6B retires runtime, KEY-263 isolation, KEY-302 Clarity, PH-19.x preserves, 0 fake event, manifest digest GHCR cible |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA (ROLLBACK)

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | efb90e3 ops(client-dev): ROLLBACK to v3.5.208-register-polish-dev (PH-20.6A) |
| Push | OK abfee84..efb90e3 main -> main |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-client configured
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~45-60s |
| Pod new | keybuzz-client-84d767874f-7bjvf |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Match digest attendu (PH-20.6A v3.5.208) | **OK** |
| readyReplicas | 1/1 |

## RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.208-register-polish-dev** | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 | **ROLLBACK PH-20.6A OK** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | (inchange) | OK PROD INTACT |

## E4 SMOKES NON-MUTANTS (via port-forward pod direct)

| URL (http://127.0.0.1:13005) | HTTP | Bytes | Verdict |
|---|---|---|---|
| /register | 200 | 9188 | OK |
| /register?plan=starter | 200 | 9188 | OK |
| /register?plan=autopilot | 200 | 9188 | OK |
| /login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK.

## E5 BUNDLE LIVE AUDIT (register chunks - 13 chunks scannes)

### PH-20.6B markers RETIRES (doivent etre 0)

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| register-plan-trial-pricing (data-testid PH-20.6B) | 0 | 0 | **OK RETIRE** |
| dans 14 jours (copy PH-20.6B) | 0 | 0 | **OK RETIRE** |
| Tarif annuel (ligne annuel PH-20.6B) | 0 | 0 | **OK RETIRE** |

### PH-20.6A markers PRESERVES LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| register-trial-value-banner (PH-20.6A) | 1 | OK preserve |
| Toutes les fonctionnalit (PH-20.6A banner copy) | 1 | OK preserve |
| Inbox marketplace (PH-20.6A banner bullet) | 1 | OK preserve |
| KeyBuzz rassemble (PH-20.6A ReassurancePanel intro) | 1 | OK preserve |

### Preserves PH-19.x + PH-20.2

| Pattern | LIVE | Verdict |
|---|---|---|
| data-clarity-mask | 13 | OK preserve |
| Clarity wuk12h9i33 | 1 | OK KEY-302 preserve |

### KEY-263 + phrases interdites pre-plan

| Pattern | LIVE | Verdict |
|---|---|---|
| api.keybuzz.io seul (PROD URL) | 0 | **KEY-263 isolation DEV OK** |
| Autopilot inclus pendant | 0 | **OK ABSENT** |
| Avant de regarder les plans | 0 | **OK ABSENT** |
| Aucune CB requise | 0 | **OK ABSENT** |

Runtime DEV est revenu sur l etat stable PH-20.6A v3.5.208-register-polish-dev. Toutes les ameliorations PH-20.6A sont LIVE et toutes les modifications PH-20.6B sont retirees du runtime DEV.

## E6 NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- nouveau (rollback vers image deja audite PH-20.6A).
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads touche.
- Aucun checkout Stripe live ou test.
- Aucun appel API Stripe.
- Aucun faux register PROD ou DEV execute.
- Aucune mutation DB.
- Aucun tracking GA4/CAPI modifie.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.

## RUNTIME PRESERVE

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.208-register-polish-dev** | **ROLLBACK PH-20.6A** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image v3.5.208 deja sur GHCR depuis PH-20.6A PUSH IMAGE DEV).
- AUCUN PROD touche.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN faux register.
- AUCUN ticket Linear cree/ferme automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## STATUT FORWARD

- **Image v3.5.209-register-polish-dev (PH-20.6B)** : reste publiee sur GHCR (manifest digest sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622). Disponible pour redeploy si un design alternatif est decide. Aucun retrait GHCR effectue.
- **Commit Client 97bdd5b (PH-20.6B source)** : reste sur branche `ph148/onboarding-activation-replay`. Aucun revert source effectue.
- **Si redesign futur** : repartir depuis commit `dbdc46f` (PH-20.6A) pour creer une nouvelle phase PH-20.6C avec design pricing cards alternatif (autre approche que le bloc vert teste).

## GAPS

1. PH-20.6B rendu pricing cards non retenu visuellement par Ludovic apres APPLY DEV. Phase abandonnee runtime DEV.
2. Pas de gap technique sur le rollback (clean GitOps, digest match, runtime stable PH-20.6A).
3. Si une nouvelle approche pricing cards est decidee, ouvrir PH-20.6C avec design distinct.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO ROLLBACK CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B -> PH-20.6A |
| keybuzz-infra HEAD apres rollback | efb90e3 (ops manifest) |
| Client DEV runtime tag | v3.5.208-register-polish-dev (PH-20.6A) |
| Client DEV runtime digest | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Pod | keybuzz-client-84d767874f-7bjvf Ready 1/1 |
| Source commit Client live runtime | dbdc46f (PH-20.6A) |
| Smokes /register + variants + /login | 4/4 HTTP 200 |
| PH-20.6B markers retires LIVE | trial-pricing=0, dans 14 jours=0, Tarif annuel=0 |
| PH-20.6A markers preserves LIVE | trial-banner=1, Toutes fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1 |
| Bundle phrases interdites pre-plan | TOUTES ABSENTES |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=1) |
| data-clarity-mask preserve | 13 |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Image v3.5.209 sur GHCR | preservee (non retiree, dispo redeploy) |
| Commit Client 97bdd5b PH-20.6B source | preserve (pas de revert source) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6B-ROLLBACK-TO-PH-20.6A-APPLY-DEV-01.md` |

STOP avant QA navigateur Ludovic. Aucun PROD touche.
