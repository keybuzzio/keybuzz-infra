# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-APPLY-PROD-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH APPLY PROD
> Environnement : PROD GitOps strict apply (aucun build, aucun docker push)

## VERDICT

GO APPLY WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8

- Manifest `k8s/website-prod/deployment.yaml` bumpe v0.6.19-cta-tracking-prod -> v0.6.20-cmp-mobile-polish-prod.
- Infra commit `576e977` push origin/main avant apply.
- kubectl apply : `deployment.apps/keybuzz-website configured` (+ service unchanged + namespace unchanged).
- Rollout : `deployment "keybuzz-website" successfully rolled out`.
- 2 pods nouveaux Ready : `keybuzz-website-6c866bf844-drcpx` + `keybuzz-website-6c866bf844-v7j7w` (HA Website PROD = 2 replicas).
- Runtime digest PROD : `sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23` MATCH GHCR push.
- readyReplicas 2/2.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes publics 5/5 HTTP 200 : `https://keybuzz.pro/`, `/cookies`, `/privacy`, `/pricing`, `/contact`.
- PH-20.8 nouveaux markers LIVE PROD bundle home : max-h-[60vh]=1, sm:hidden=1, cookies necessaires=1.
- CMP elements preserves LIVE PROD : Nous respectons votre vie=1, Refuser les cookies optionnels=1, politique cookies=1, politique de confidentialit=1.
- Tracking IDs preserves LIVE PROD home : GA G-R3QQDYEBFG=1, SGTM t.keybuzz.pro=1, LinkedIn 9969977=1, marketing_cta_click=1, trackMarketingClick=9.
- Clarity wuk12h9i33 = 0 (baseline website non-bake preservee).
- KEY-263 isolation PROD bundle live : api-dev=0 (aucun leak DEV en PROD), api.keybuzz.io seul=0 sur home (URLs API dans BFF chunks non charges pour `/`, bundle complet PROD = 2 deja audite BUILD PROD).
- Fake events delta home : 0 (Lead/Purchase/Submit/Initiate tous = 0).
- Runtime Website DEV `v0.6.20-cmp-mobile-polish-dev` INCHANGE.
- Runtime Client DEV+PROD INCHANGES.
- Runtime API DEV+PROD INCHANGES.
- AUCUN test register/lead/checkout mutant. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | 629c72f (rapport PUSH IMAGE PROD PH-20.8) |
| keybuzz-website HEAD | bb49798 (PH-20.8 source) |
| Runtime Website DEV avant | v0.6.20-cmp-mobile-polish-dev |
| Runtime Website PROD avant | v0.6.19-cta-tracking-prod |

## E1 VERIFY IMAGE GHCR

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod | OK |
| Config digest GHCR | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e | MATCH expected |

## E2 MANIFEST PROD PATH + BUMP + DRY-RUN

| Etape | Resultat |
|---|---|
| Path manifest PROD trouve | k8s/website-prod/deployment.yaml |
| Substitution Python regex | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.36) apres bump | image: ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod + annotation PH-20.8 |
| kubectl apply --dry-run=server | `deployment configured` + `service unchanged` + `namespace unchanged` |

## E3 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/website-prod/deployment.yaml (1 fichier) |
| Commit | 576e977 chore(website): deploy PH-20.8 CMP mobile polish PROD |
| Push | OK 629c72f..576e977 main -> main |

## E4 KUBECTL APPLY + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | OK configured + 2 resources unchanged |
| Rollout duration | ~30-45s |
| Pods new | 2 (HA replicas Website PROD) |
| Pod 1 | keybuzz-website-6c866bf844-drcpx Ready Running |
| Pod 2 | keybuzz-website-6c866bf844-v7j7w Ready Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 |
| Match GHCR push digest | OK les 2 pods |
| readyReplicas | 2/2 |

## E5 RUNTIME CHECKS TRIPLE MATCH PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod | OK |
| pod imageID (2 pods) | ghcr.io/keybuzzio/keybuzz-website@sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 | OK MATCH expected |

## E6 SMOKES PUBLICS PROD HTTP 200 READ-ONLY

| URL | HTTP | Bytes | Verdict |
|---|---|---|---|
| https://keybuzz.pro/ | 200 | 72659 | OK |
| https://keybuzz.pro/cookies | 200 | 46103 | OK |
| https://keybuzz.pro/privacy | 200 | 57150 | OK |
| https://keybuzz.pro/pricing | 200 | 71713 | OK |
| https://keybuzz.pro/contact | 200 | 28362 | OK |

5/5 smokes HTTP 200 OK. Aucun CTA clique. Aucun formulaire submit. Aucun lead.

## E7 BUNDLE LIVE AUDIT PROD / (13 chunks home page)

### PH-20.8 nouveaux markers LIVE PROD

| Pattern | LIVE | Verdict |
|---|---|---|
| `max-h-[60vh]` (mobile compact CSS) | 1 | **OK marker LIVE PROD** |
| `sm:hidden` (mobile-only copy class) | 1 | **OK LIVE PROD** |
| copy mobile "cookies necessaires au service" | 1 | **OK LIVE PROD** |

### CMP elements preserves LIVE PROD

| Pattern | LIVE | Verdict |
|---|---|---|
| "Nous respectons votre vie" (h2) | 1 | OK preserve |
| "Refuser les cookies optionnels" | 1 | OK preserve |
| "politique cookies" | 1 | OK preserve |
| "politique de confidentialit" | 1 | OK preserve |

### Tracking IDs preserves LIVE PROD home

| Pattern | LIVE | Verdict |
|---|---|---|
| GA G-R3QQDYEBFG | 1 | OK preserve (baseline /app/.next entier = 18) |
| SGTM t.keybuzz.pro | 1 | OK preserve (baseline = 39) |
| LinkedIn 9969977 | 1 | OK preserve (baseline = 18) |
| Clarity wuk12h9i33 | 0 | OK baseline website non-bake (KEY-302 Client uniquement) |
| marketing_cta_click (PH-20.3) | 1 | OK preserve |
| trackMarketingClick (PH-20.3) | 9 | OK preserve (baseline = 15) |

Note : counts live home page sont sous-ensemble des counts bundle complet /app/.next car seuls les chunks charges pour `/` sont audites en live. Audit BUILD PROD deja confirme baseline 100 preserve dans /app/.next entier.

### KEY-263 isolation PROD bundle live home

| Pattern | LIVE | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 0 | **OK isolation PROD stricte (pas de leak DEV)** |
| api.keybuzz.io seul (PROD URL) | 0 sur home | NORMAL (URLs API dans BFF chunks non charges pour `/` ; baseline /app/.next entier = 2 deja audite BUILD PROD) |

### Fake events scan home page (avec word boundary)

| Pattern | LIVE | Verdict |
|---|---|---|
| `\bLead\b` | 0 | OK |
| `\bPurchase\b` | 0 | OK |
| StartTrial | 0 | OK |
| CompletePayment | 0 | OK |
| SubmitForm | 0 | OK |
| InitiateCheckout | 0 | OK |

0 fake event LIVE home page PROD. Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.

## E8 NON-REGRESSION SERVICES

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-admin-v2 | v2.12.2-* | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

- 0 fake event delta vs baseline v0.6.19 PROD deja audite en BUILD PROD.
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads touche.
- Aucun checkout reel.
- Aucun lead cree.
- Aucun formulaire submit.
- Aucune mutation DB.
- Aucun tracking GA4/CAPI ajoute.
- "Lead" pattern detecte avec \b boundary = 0 sur home page PROD (les `leading-*` Tailwind classes sont filtrees).

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja sur GHCR depuis PH-20.8 PUSH IMAGE PROD).
- AUCUN deploy DEV.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register / checkout / lead.
- AUCUN ticket Linear cree/ferme automatiquement.
- AUCUN changement IDs analytics.
- AUCUN changement logique consentement tracking.
- AUCUN changement Client/API/Admin/Backend.
- Bastion install-v3 (46.62.171.61) uniquement.
- GO PROD explicit Ludovic dans la conversation courante.

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-prod | **v0.6.20-cmp-mobile-polish-prod** | **NOUVEAU PROD PH-20.8** |
| keybuzz-website | keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-api | keybuzz-api-dev/-prod | v3.5.252 / v3.5.251 | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

## ROLLBACK PROD DOCUMENTE (non execute)

1. Editer `k8s/website-prod/deployment.yaml` -> image `v0.6.19-cta-tracking-prod`.
2. `git add + commit -m "ops(website-prod): ROLLBACK PH-20.8 to v0.6.19"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/website-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-prod deploy/keybuzz-website --timeout=180s`.
6. Verifier digest runtime precedent (sha256 baseline v0.6.19-cta-tracking-prod).

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic en PROD recommandee mobile + desktop sur https://keybuzz.pro pour valider visuel CMP : tester viewports 360px (iPhone SE), 414px (iPhone 14 Pro), 768px (tablet portrait), 1024px+ (desktop). Verifier hero KeyBuzz visible sous le bandeau mobile, copy compacte LIVE, Accepter/Refuser equilibres, liens politiques accessibles, close X handleRefuse preserve.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8 |
| keybuzz-infra HEAD apres apply | 576e977 (ops manifest) |
| Website PROD runtime tag | v0.6.20-cmp-mobile-polish-prod |
| Website PROD runtime digest | sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 |
| Pods PROD | 2/2 Ready (HA replicas) |
| Source commit Website | bb49798 (PH-20.8) |
| Smokes publics /, /cookies, /privacy, /pricing, /contact | 5/5 HTTP 200 |
| PH-20.8 markers LIVE PROD | max-h-[60vh]=1, sm:hidden=1, cookies necessaires=1 |
| CMP elements preserves LIVE PROD | Nous respectons=1, Refuser=1, politique cookies=1, politique confidentialite=1 |
| Tracking IDs preserves LIVE PROD home | GA=1, SGTM=1, LinkedIn=1, marketing_cta_click=1, trackMarketingClick=9, Clarity=0 (baseline) |
| KEY-263 isolation PROD bundle live | OK (api-dev=0) |
| Fake events delta home | 0 |
| Triple match (last-applied=manifest=pod imageID) | OK 2 pods |
| Runtime Website DEV | v0.6.20-cmp-mobile-polish-dev INCHANGE |
| Runtime Client+API+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag PROD | v0.6.19-cta-tracking-prod |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-APPLY-PROD-01.md` |

### Prochaine phrase GO attendue

`GO QA WEBSITE CMP MOBILE POLISH PROD PH-SAAS-T8.12AS.20.8`

QA navigateur Ludovic recommandee mobile + desktop sur https://keybuzz.pro pour valider visuel CMP final.

STOP apres rapport + Linear. Pas de QA mutante, pas de lead test, pas de deploy supplementaire.
