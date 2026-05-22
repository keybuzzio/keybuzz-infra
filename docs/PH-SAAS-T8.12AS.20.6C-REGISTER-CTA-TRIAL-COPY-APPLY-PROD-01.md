# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-APPLY-PROD-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER POLISH APPLY PROD
> Environnement : PROD GitOps strict apply (aucun build, aucun docker push)

## VERDICT

GO APPLY CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C

- Manifest `k8s/keybuzz-client-prod/deployment.yaml` bumpe v3.5.200-clarity-register-prod -> v3.5.201-register-polish-prod.
- Infra commit `b472c54` push origin/main avant apply.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-85cf55f58d-s4c8p` Ready, Running.
- Runtime digest PROD : `sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5` **MATCH GHCR push**.
- readyReplicas 1/1.
- **Triple match parfait** : last-applied annotation = manifest spec = pod imageID.
- Smokes publics 4/4 HTTP 200 : `https://client.keybuzz.io/register` (9188 b), `/register?plan=starter`, `/register?plan=autopilot`, `/login` (8763 b).
- PH-20.6C nouveaux markers PROD LIVE : "Demarrer mon essai gratuit"=1, "seulement si vous continuez"=1, "dans 14 jours"=1.
- PH-20.6A markers promote PROD LIVE : register-trial-value-banner=1, Toutes les fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1.
- PH-20.6B markers ABSENTS PROD : register-plan-trial-pricing=0, Tarif annuel=0.
- data-clarity-mask=13, Clarity wuk12h9i33=1 preserves PROD.
- KEY-263 isolation PROD bundle live : api-dev=0 (aucun leak DEV en PROD).
- Phrases interdites TOUTES ABSENTES LIVE : Autopilot=0, Avant de regarder=0, Aucune CB=0, Payez 0=0.
- Runtime Client DEV `v3.5.210-register-polish-dev` INCHANGE.
- Runtime API DEV+PROD `v3.5.252` / `v3.5.251` INCHANGES.
- Runtime Website DEV+PROD `v0.6.19-cta-tracking-*` INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | f091a78 (rapport PUSH IMAGE PROD PH-20.6C) |
| keybuzz-infra HEAD apres | b472c54 (ops apply PROD) |
| keybuzz-client HEAD | be45f1d (PH-20.6C source) |
| Runtime Client DEV avant | v3.5.210-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 VERIFY IMAGE GHCR

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod | OK |
| Config digest GHCR | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d | MATCH expected |
| Manifest digest GHCR | sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 | MATCH expected |
| Layers | 11 | OK |

## E2 BUMP MANIFEST PROD + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex k8s/keybuzz-client-prod/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.76) apres bump | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod + annotation PH-20.6C |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E3 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-prod/deployment.yaml (1 fichier) |
| Commit | b472c54 ops(client-prod): deploy v3.5.201-register-polish-prod |
| Push | OK f091a78..b472c54 main -> main |

## E4 KUBECTL APPLY + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~45-60s |
| Pod new | keybuzz-client-85cf55f58d-s4c8p |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 |
| Match GHCR push digest | **OK** |
| readyReplicas | 1/1 |

## E5 SMOKES NON-MUTANTS PROD PUBLICS

| URL | HTTP | Bytes | Verdict |
|---|---|---|---|
| https://client.keybuzz.io/register | 200 | 9188 | OK |
| https://client.keybuzz.io/register?plan=starter | 200 | 9188 | OK |
| https://client.keybuzz.io/register?plan=autopilot | 200 | 9188 | OK |
| https://client.keybuzz.io/login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK. Aucun register/checkout test execute.

## E6 BUNDLE LIVE AUDIT PROD /register (13 chunks)

### PH-20.6C nouveaux markers PROD LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| "Demarrer mon essai gratuit" (CTA) | 1 | **OK CTA LIVE PROD** |
| "seulement si vous continuez" (microcopy) | 1 | **OK microcopy LIVE PROD** |
| "dans 14 jours" | 1 | OK |

### PH-20.6A markers promote PROD LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| register-trial-value-banner | 1 | OK promote PROD |
| Toutes les fonctionnalit | 1 | OK promote PROD |
| Inbox marketplace | 1 | OK promote PROD |
| KeyBuzz rassemble | 1 | OK promote PROD |

### Preserves PH-19.x + PH-20.2

| Pattern | LIVE | Verdict |
|---|---|---|
| data-clarity-mask | 13 | OK preserve |
| Clarity wuk12h9i33 | 1 | OK KEY-302 preserve |

### KEY-263 isolation PROD bundle live

| Pattern | LIVE | Verdict |
|---|---|---|
| api.keybuzz.io PROD URL | 0 dans chunks /register | NORMAL (URLs API referencees dans BFF/helpers chunks non charges sur HTML /register render ; bundle complet PROD = 87 occurrences deja audite BUILD PROD) |
| api-dev.keybuzz.io | 0 | **OK isolation PROD stricte** (pas de leak DEV) |

### PH-20.6B markers ABSENTS PROD

| Pattern | LIVE | Verdict |
|---|---|---|
| register-plan-trial-pricing | 0 | **OK absent** |
| Tarif annuel | 0 | **OK absent** |

### Phrases interdites TOUTES ABSENTES LIVE PROD

| Pattern | LIVE | Verdict |
|---|---|---|
| Autopilot inclus pendant | 0 | OK absent |
| Avant de regarder les plans | 0 | OK absent |
| Aucune CB requise | 0 | OK absent |
| **Payez 0** (INTERDIT brief PH-20.6C) | 0 | **OK ABSENT** |

## E7 RUNTIME CHECKS TRIPLE MATCH + NON-REGRESSION

### Triple match PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 | OK MATCH expected |

### Non-regression services

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-client DEV | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-api DEV | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api PROD | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website DEV | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website PROD | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-admin-v2 | v2.12.2-* | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

- 0 fake event delta vs baseline v3.5.200 (Lead=6, Purchase=7, SubmitForm=2, InitiateCheckout=2, StartTrial=0, CompletePayment=0 - audite BUILD PROD).
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads touche.
- Aucun checkout Stripe live ou test.
- Aucun appel API Stripe.
- Aucun faux register PROD ou DEV execute.
- Aucune mutation DB.
- Aucun tracking GA4/CAPI/Addingwell ajoute.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-prod | **v3.5.201-register-polish-prod** | **NOUVEAU PROD PH-20.6C** |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image v3.5.201-register-polish-prod deja sur GHCR depuis PH-20.6C PUSH IMAGE PROD).
- AUCUN deploy DEV.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN faux register.
- AUCUN ticket Linear cree/ferme automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT PROD

1. Editer `k8s/keybuzz-client-prod/deployment.yaml` -> image `v3.5.200-clarity-register-prod`.
2. `git add + commit -m "ops(client-prod): ROLLBACK PH-20.6C to v3.5.200"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic en PROD recommandee post-deploy : naviguer https://client.keybuzz.io/register jusqu'a step plan, verifier CTA "Demarrer mon essai gratuit - 0 EUR aujourd hui" + microcopy dynamique "Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez." sur les 3 plans (starter/pro/autopilot) en mensuel ET annuel. SANS creer de compte.
2. Verifier que TrialValueBanner premium + ReassurancePanel benefits + grand encart "0 EUR pendant 14 jours" + line-through annuel cards PH-20.6A sont LIVE PROD comme attendu.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C |
| keybuzz-infra HEAD apres apply | b472c54 (ops manifest) |
| Client PROD runtime tag | v3.5.201-register-polish-prod |
| Client PROD runtime digest | sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 |
| Pod | keybuzz-client-85cf55f58d-s4c8p Ready 1/1 |
| Source commit Client | be45f1d (PH-20.6C) |
| Smokes publics /register + variants + /login | 4/4 HTTP 200 |
| PH-20.6C markers LIVE | Demarrer=1, seulement si vous continuez=1, dans 14 jours=1 |
| PH-20.6A markers promote PROD LIVE | trial-banner=1, Toutes fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1 |
| PH-20.6B ABSENTS LIVE | register-plan-trial-pricing=0, Tarif annuel=0 |
| Phrase interdite "Payez 0" | ABSENTE |
| Phrases interdites pre-plan | ABSENTES |
| KEY-263 isolation PROD bundle live | OK (api-dev=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=1) |
| data-clarity-mask preserve | 13 |
| Triple match (last-applied = manifest = pod imageID) | OK |
| Runtime Client DEV | v3.5.210-register-polish-dev INCHANGE |
| Runtime API DEV+PROD | INCHANGES |
| Runtime Website DEV+PROD | INCHANGES |
| Runtime Admin DEV+PROD | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag PROD | v3.5.200-clarity-register-prod |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-APPLY-PROD-01.md` |

STOP apres rapport + Linear. Pas de QA mutante, pas de cleanup tenant, pas de deploy supplementaire.
