# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER CTA TRIAL COPY APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.208-register-polish-dev -> v3.5.210-register-polish-dev.
- Infra commit `5409b0b` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-64bc5d64b4-wqf49` Ready, Running.
- Runtime digest DEV : `sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281` MATCH GHCR push.
- readyReplicas 1/1.
- Smokes 4/4 HTTP 200 : `/register` (9188 b), `/register?plan=starter`, `/register?plan=autopilot`, `/login` (8763 b).
- PH-20.6C nouveaux markers LIVE : "Demarrer mon essai gratuit"=1, "seulement si vous continuez"=1, "dans 14 jours"=1.
- PH-20.6A preserves LIVE : register-trial-value-banner=1, Toutes les fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1.
- PH-20.6B markers ABSENTS LIVE : register-plan-trial-pricing=0, Tarif annuel=0.
- data-clarity-mask=13, Clarity wuk12h9i33=1 preserves.
- KEY-263 isolation : api.keybuzz.io seul=0.
- Phrases interdites TOUTES ABSENTES LIVE : Autopilot=0, Avant de regarder=0, Aucune CB=0, Payez 0 EUR=0.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | 8ad7600 (rapport PUSH IMAGE DEV PH-20.6C) |
| keybuzz-infra HEAD apres | 5409b0b (ops apply DEV) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex k8s/keybuzz-client-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres bump | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev + annotation PH-20.6C |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | 5409b0b ops(client-dev): deploy v3.5.210-register-polish-dev |
| Push | OK 8ad7600..5409b0b main -> main |

## E3 KUBECTL APPLY + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-45s |
| Pod new | keybuzz-client-64bc5d64b4-wqf49 |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 |
| Match GHCR push digest | **OK** |
| readyReplicas | 1/1 |

## RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | **v3.5.210-register-polish-dev** | sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 | **MATCH GHCR push** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | (inchange) | OK PROD INTACT |

## E4 SMOKES NON-MUTANTS (via port-forward pod direct)

| URL (http://127.0.0.1:13006) | HTTP | Bytes | Verdict |
|---|---|---|---|
| /register | 200 | 9188 | OK |
| /register?plan=starter | 200 | 9188 | OK |
| /register?plan=autopilot | 200 | 9188 | OK |
| /login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK.

## E5 BUNDLE LIVE AUDIT (register chunks - 13 chunks scannes)

### PH-20.6C nouveaux markers LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| "Demarrer mon essai gratuit" (CTA) | 1 | **OK marker LIVE** |
| "seulement si vous continuez" (microcopy) | 1 | **OK microcopy LIVE** |
| "dans 14 jours" | 1 | OK |

### PH-20.6A preserves LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| register-trial-value-banner | 1 | OK preserve |
| Toutes les fonctionnalit | 1 | OK preserve |
| Inbox marketplace | 1 | OK preserve |
| KeyBuzz rassemble | 1 | OK preserve |

### PH-20.6B markers ABSENTS LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| register-plan-trial-pricing | 0 | **OK absent** |
| Tarif annuel | 0 | **OK absent** |

### Preserves + KEY-263

| Pattern | LIVE | Verdict |
|---|---|---|
| data-clarity-mask | 13 | OK preserve |
| Clarity wuk12h9i33 | 1 | OK KEY-302 preserve |
| api.keybuzz.io seul (PROD URL) | 0 | **OK KEY-263 isolation DEV** |

### Phrases interdites TOUTES ABSENTES LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| Autopilot inclus pendant | 0 | OK absent |
| Avant de regarder les plans | 0 | OK absent |
| Aucune CB requise | 0 | OK absent |
| **Payez 0 EUR (INTERDIT brief PH-20.6C)** | 0 | **OK absent** |

## E6 NO FAKE METRICS / NO FAKE EVENTS

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
| keybuzz-client | keybuzz-client-dev | **v3.5.210-register-polish-dev** | **NOUVEAU DEV PH-20.6C** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja construite + pushee en BUILD + PUSH IMAGE DEV PH-20.6C).
- AUCUN PROD touche.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f).
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN faux register.
- AUCUN ticket Linear cree/ferme automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.208-register-polish-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.6C to v3.5.208"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel :
   - CTA "Demarrer mon essai gratuit - 0 EUR aujourd hui" (lisibilite, contraste, alignement)
   - Microcopy dynamique "Puis {plan.name} a {displayPrice} EUR/mois dans 14 jours, seulement si vous continuez." (tester les 3 plans starter/pro/autopilot + mensuel/annuel pour valider que prix change correctement)
   - Cards plan : verifier que le rendu PH-20.6A est restaure (line-through annuel + Economisez green)
   - Grand encart "0 EUR pendant 14 jours" : preserve en haut step plan
   - Etapes pre-plan : TrialValueBanner + ReassurancePanel intact
2. preview.keybuzz.pro Client DEV ingress public peut etre indisponible (cert TLS connu). Smokes deja faits via port-forward direct au pod = OK.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C |
| keybuzz-infra HEAD apres apply | 5409b0b (ops manifest) |
| Client DEV runtime tag | v3.5.210-register-polish-dev |
| Client DEV runtime digest | sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 |
| Pod | keybuzz-client-64bc5d64b4-wqf49 Ready 1/1 |
| Source commit Client | be45f1d (PH-20.6C) |
| Smokes /register + variants + /login | 4/4 HTTP 200 |
| PH-20.6C markers LIVE | Demarrer=1, seulement si vous continuez=1, dans 14 jours=1 |
| PH-20.6A preserves LIVE | trial-banner=1, Toutes fonctionnalit=1, Inbox marketplace=1, KeyBuzz rassemble=1 |
| PH-20.6B ABSENTS LIVE | register-plan-trial-pricing=0, Tarif annuel=0 |
| Phrase interdite "Payez 0 EUR" | ABSENTE |
| Phrases interdites pre-plan (Autopilot, Avant de regarder, Aucune CB) | ABSENTES |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=1) |
| data-clarity-mask preserve | 13 |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v3.5.208-register-polish-dev |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA REGISTER CTA TRIAL COPY DEV PH-SAAS-T8.12AS.20.6C`

QA navigateur Ludovic recommandee mobile 360px + desktop pour valider visuel CTA + microcopy dynamique sur les 3 plans en mensuel ET annuel.

STOP.
