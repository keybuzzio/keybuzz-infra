# PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-APPLY-DEV-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6A REGISTER POLISH QA FIX APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.207-register-polish-dev -> v3.5.208-register-polish-dev.
- Infra commit `706afe6` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-client configured`.
- Rollout : `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau : `keybuzz-client-84d767874f-fh6vt` Ready, Running.
- Runtime digest DEV : `sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0` MATCH GHCR push.
- readyReplicas 1/1.
- Smokes 4/4 HTTP 200 : `/register` (9188 b), `/register?plan=starter`, `/register?plan=autopilot`, `/login` (8763 b).
- Bundle live LIVE : register-trial-value-banner=1, Toutes les fonctionnalit=1, Inbox marketplace=1, Contexte commande sous les yeux=1, KeyBuzz rassemble=1, Clarity wuk12h9i33=1, data-clarity-mask=13.
- **Phrases interdites pre-plan TOUTES ABSENTES LIVE** : Autopilot inclus=0, Avant de regarder les plans=0, Aucune CB requise=0, ancien Cockpit SAV marketplace banner=0.
- KEY-263 isolation DEV : api.keybuzz.io seul=0.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- AUCUN test register mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | 5343c9c (rapport PUSH IMAGE DEV PH-20.6A) |
| keybuzz-infra HEAD apres | 706afe6 (ops apply DEV) |
| Runtime Client DEV avant | v3.5.207-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |
| Image GHCR target | v3.5.208-register-polish-dev (manifest digest sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-client-dev/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.77) apres bump | image: ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev + annotation PH-20.6A |
| Annotation commentaire | commit client dbdc46f, KEY-345 QA fix spacing+style+copy, phrases interdites retirees, KEY-263 isolation, KEY-302 Clarity, PH-19.x preserves, 0 fake event, rollback, digest GHCR |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-client configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-client-dev/deployment.yaml (1 fichier) |
| Commit | 706afe6 ops(client-dev): deploy v3.5.208-register-polish-dev |
| Push | OK 5343c9c..706afe6 main -> main |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-client configured
deployment "keybuzz-client" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-45s |
| Pod new | keybuzz-client-84d767874f-fh6vt |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Match GHCR push digest | **OK** |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 | **MATCH GHCR push** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | (inchange) | OK PROD INTACT |

| Deployment status DEV | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 SMOKES NON-MUTANTS (via port-forward pod direct)

| URL (http://127.0.0.1:13002) | HTTP | Bytes | Verdict |
|---|---|---|---|
| /register | 200 | 9188 | OK |
| /register?plan=starter | 200 | 9188 | OK |
| /register?plan=autopilot | 200 | 9188 | OK |
| /login | 200 | 8763 | OK |

4/4 smokes HTTP 200 OK.

## E6 BUNDLE LIVE AUDIT (register chunks - 13 chunks scannes)

### PH-20.6A nouvelles copies LIVE

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| register-trial-value-banner (marker) | >= 1 | 1 | **OK marker LIVE** |
| Toutes les fonctionnalit (banner copy) | >= 1 | 1 | **OK nouvelle copy humaine LIVE** |
| Inbox marketplace (banner bullet) | >= 1 | 1 | **OK nouveau bullet LIVE** |
| Contexte commande sous les yeux (banner bullet) | >= 1 | 1 | **OK nouveau bullet LIVE** |
| KeyBuzz rassemble (ReassurancePanel intro) | >= 1 | 1 | **OK ReassurancePanel intro LIVE** |

### Preserves

| Pattern | LIVE | Verdict |
|---|---|---|
| data-clarity-mask | 13 | OK preserve LIVE |
| Clarity wuk12h9i33 | 1 | OK Clarity preserve LIVE |

### KEY-263 + phrases interdites pre-plan (doivent etre 0)

| Pattern | Attendu | Observe LIVE | Verdict |
|---|---|---|---|
| api.keybuzz.io seul (PROD URL) | 0 | 0 | **OK KEY-263 isolation DEV** |
| Autopilot inclus pendant (interdit pre-plan) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |
| Avant de regarder les plans (interdit) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |
| Aucune CB requise (interdit pre-plan) | 0 | 0 | **OK PHRASE INTERDITE ABSENTE LIVE** |
| Cockpit SAV marketplace (ancien banner bullet) | 0 | 0 | **OK retire (remplace par Inbox marketplace)** |

Note technique : `api-dev.keybuzz.io` count LIVE = 0 sur chunks /register specifiques est attendu (URL utilisee dans chunks helpers BFF non charges sur /register HTML, chemins relatifs `/api/*` via BFF Next.js). Verifie en BUILD DEV PH-20.6A : 87 occurrences dans le bundle complet.

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- nouveau (0 delta vs baseline v3.5.207).
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
| keybuzz-client | keybuzz-client-dev | **v3.5.208-register-polish-dev** | **NOUVEAU DEV** |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja construite + pushe en BUILD + PUSH IMAGE DEV PH-20.6A).
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

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.207-register-polish-dev`.
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-20.6A to v3.5.207"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic recommandee :
   - port-forward `kubectl port-forward -n keybuzz-client-dev deploy/keybuzz-client 13002:3000` -> http://127.0.0.1:13002/register
   - mobile 360px : verifier vraie respiration entre TrialValueBanner et card "Creez votre compte" (mt-8 mb-10)
   - desktop : verifier style premium aligne grand encart plan (rounded-2xl, border-2 green/40, bg uni)
   - lire les nouvelles copies (Toutes les fonctionnalites cles + 4 bullets recentres)
   - verifier ReassurancePanel volet droit : nouveau texte KeyBuzz rassemble vos messages + footer muted
   - confirmer absence CB pre-plan (etapes email/code/company/user)
   - sur etape plan : verifier grand encart preserve (continue de parler 0 EUR + Carte demandee a l activation contextuel)
2. preview.keybuzz.pro Client DEV ingress public peut etre indisponible (cert TLS connu depuis PH-20.1). Smokes validation deja faits via port-forward direct au pod = OK.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A |
| keybuzz-infra HEAD apres apply | 706afe6 (ops manifest) |
| Client DEV runtime tag | v3.5.208-register-polish-dev |
| Client DEV runtime digest | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Pod | keybuzz-client-84d767874f-fh6vt Ready 1/1 |
| Source commit Client | dbdc46f |
| Smokes /register + variants + /login | 4/4 HTTP 200 |
| Bundle live nouvelles copies PH-20.6A | trial-banner=1, Toutes fonctionnalit=1, Inbox marketplace=1, Contexte commande=1, KeyBuzz rassemble=1 |
| Bundle live phrases interdites pre-plan | TOUTES ABSENTES (Autopilot=0, Avant de regarder=0, Aucune CB=0, ancien Cockpit SAV=0) |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=1, data-clarity-mask=13) |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v3.5.207-register-polish-dev |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6A`

QA navigateur Ludovic recommandee mobile 360px + desktop pour valider visuel spacing + style premium + copy humaine + absence CB pre-plan.

STOP.
