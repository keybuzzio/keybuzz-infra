# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8

- Manifest `k8s/website-dev/deployment.yaml` bumpe v0.6.19-cta-tracking-dev -> v0.6.20-cmp-mobile-polish-dev.
- Infra commit `a5cdc1f` push origin/main avant apply.
- kubectl apply : `deployment.apps/keybuzz-website configured`.
- Rollout : `deployment "keybuzz-website" successfully rolled out`.
- Pod nouveau : `keybuzz-website-6b87f6fddf-t8rxb` Ready, Running.
- Runtime digest DEV : `sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe` MATCH GHCR push.
- readyReplicas 1/1.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes publics 5/5 HTTP 200 : `/`, `/cookies`, `/privacy`, `/pricing`, `/contact`.
- PH-20.8 nouveaux markers LIVE bundle home : max-h-[60vh]=1, sm:hidden=1, copy mobile "cookies necessaires"=1.
- CMP elements preserves LIVE : "Nous respectons votre vie"=1, "Refuser les cookies optionnels"=1, "politique cookies"=1, "politique de confidentialit"=1.
- Tracking IDs preserves LIVE home page : GA G-R3QQDYEBFG=1, SGTM t.keybuzz.pro=1, LinkedIn 9969977=1, marketing_cta_click=1, trackMarketingClick=9.
- Clarity wuk12h9i33 = 0 (baseline website non-bake = preservee).
- KEY-263 isolation home page : api-dev=0, api-prod seul=0 (NORMAL : URLs API referencees dans BFF chunks non charges pour home ; bundle complet DEV = 2/0 deja audite BUILD DEV).
- Fake events delta home page : 0 (Lead/Purchase/Submit/Initiate tous = 0).
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Runtime Client DEV+PROD INCHANGES.
- Runtime API DEV+PROD INCHANGES.
- Runtime Admin DEV+PROD INCHANGES.
- AUCUN test register/checkout mutant. AUCUN Stripe call. AUCUNE mutation DB.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-infra HEAD avant | 8dd0c4a (rapport PUSH IMAGE DEV PH-20.8) |
| keybuzz-infra HEAD apres | a5cdc1f (ops apply DEV) |
| keybuzz-website HEAD | bb49798 (PH-20.8 source) |
| Runtime Website DEV avant | v0.6.19-cta-tracking-dev |
| Runtime Website PROD avant | v0.6.19-cta-tracking-prod |

## E1 VERIFY IMAGE GHCR

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev | OK |
| Config digest GHCR | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 | MATCH expected |
| Manifest digest GHCR | sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe | MATCH expected |

## E2 BUMP MANIFEST DEV + DRY-RUN

| Etape | Resultat |
|---|---|
| Path manifest | k8s/website-dev/deployment.yaml (correction prompt initial qui referencait keybuzz-website-dev/deployment.yaml inexistant) |
| Substitution Python regex | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.23) apres bump | image: ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev + annotation PH-20.8 |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-website configured (server dry run)` |

## E3 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/website-dev/deployment.yaml (1 fichier) |
| Commit | a5cdc1f chore(website): deploy PH-20.8 CMP mobile polish DEV |
| Push | OK 8dd0c4a..a5cdc1f main -> main |

## E4 KUBECTL APPLY + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-40s |
| Pod new | keybuzz-website-6b87f6fddf-t8rxb |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe |
| Match GHCR push digest | OK |
| readyReplicas | 1/1 |

## E5 RUNTIME CHECKS TRIPLE MATCH

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe | OK MATCH expected |

## E6 SMOKES NON-MUTANTS DEV (via port-forward pod direct)

| URL (http://127.0.0.1:13008) | HTTP | Bytes | Verdict |
|---|---|---|---|
| / | 200 | 72889 | OK |
| /cookies | 200 | 46333 | OK |
| /privacy | 200 | 57380 | OK |
| /pricing | 200 | 71975 | OK |
| /contact | 200 | 28592 | OK |

5/5 smokes HTTP 200 OK. Aucun CTA marketing clique. Aucun formulaire submit. Aucun lead cree.

## E7 BUNDLE LIVE AUDIT DEV / (13 chunks home page)

### PH-20.8 nouveaux markers LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| `max-h-[60vh]` (mobile compact CSS) | 1 | OK marker LIVE |
| `sm:hidden` (mobile-only copy class) | 1 | OK LIVE |
| copy mobile "cookies necessaires au service" | 1 | OK LIVE |

### CMP elements preserves LIVE

| Pattern | LIVE | Verdict |
|---|---|---|
| "Nous respectons votre vie" (h2) | 1 | OK preserve |
| "Refuser les cookies optionnels" | 1 | OK preserve |
| "politique cookies" (link) | 1 | OK preserve |
| "politique de confidentialit" (link) | 1 | OK preserve |
| ">Accepter<" (pattern strict avec brackets) | 0 | NORMAL (JSX compile en `{children:["Accepter"]}` ou React.createElement, pas literal HTML `>Accepter<` ; bouton Accepter LIVE confirme via build /app/.next audit a 1 occurrence) |

### Tracking IDs preserves LIVE home page

| Pattern | LIVE | Verdict |
|---|---|---|
| GA G-R3QQDYEBFG | 1 | OK preserve (1 occurrence sur home, baseline /app/.next entier = 18) |
| SGTM t.keybuzz.pro | 1 | OK preserve (1 sur home, baseline = 39) |
| LinkedIn 9969977 | 1 | OK preserve (1 sur home, baseline = 18) |
| Clarity wuk12h9i33 | 0 | OK baseline website non-bake (KEY-302 Client uniquement) |
| marketing_cta_click (PH-20.3) | 1 | OK preserve |
| trackMarketingClick (PH-20.3) | 9 | OK preserve (9 sur home, baseline /app/.next = 15) |

Note : counts live home page sont sous-ensemble des counts bundle complet /app/.next car seuls les chunks charges pour `/` sont audites en live. Audit BUILD DEV deja confirme baseline 100% preserve dans /app/.next entier (GA=18, SGTM=39, LinkedIn=18, marketing_cta_click=1, trackMarketingClick=15).

### KEY-263 isolation DEV bundle live home

| Pattern | LIVE | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 0 | NORMAL (URLs API dans BFF chunks non charges pour `/` ; baseline /app/.next entier = 2 deja audite BUILD DEV) |
| api.keybuzz.io seul (PROD URL) | 0 | **OK isolation DEV stricte** (pas de leak PROD) |

### Fake events scan home page

| Pattern | LIVE | Verdict |
|---|---|---|
| `\bLead\b` | 0 | OK (`leading-*` Tailwind classes filtrees par \b boundary) |
| `\bPurchase\b` | 0 | OK |
| StartTrial | 0 | OK |
| CompletePayment | 0 | OK |
| SubmitForm | 0 | OK |
| InitiateCheckout | 0 | OK |

0 fake event LIVE home page. Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.

## E8 NON-REGRESSION SERVICES

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-admin-v2 | v2.12.2-* | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

- 0 fake event delta vs baseline v0.6.19 deja audite en BUILD DEV.
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads touche.
- Aucun checkout reel.
- Aucun lead cree.
- Aucun formulaire submit.
- Aucune mutation DB.
- Aucun tracking GA4/CAPI ajoute.
- "Lead" pattern detecte avec \b boundary = 0 sur home page (les `leading-*` Tailwind classes sont filtrees).

## CONFIRMATIONS SECURITE

- AUCUN docker build/push (image deja sur GHCR depuis PH-20.8 PUSH IMAGE DEV).
- AUCUN PROD touche.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register / checkout / lead.
- AUCUN ticket Linear cree/ferme automatiquement.
- AUCUN changement IDs analytics.
- AUCUN changement logique consentement tracking.
- AUCUN changement Client/API/Admin/Backend.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK DEV DOCUMENTE (non execute)

1. Editer `k8s/website-dev/deployment.yaml` -> image `v0.6.19-cta-tracking-dev`.
2. `git add + commit -m "ops(website-dev): ROLLBACK PH-20.8 to v0.6.19"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/website-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-dev deploy/keybuzz-website --timeout=180s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. QA navigateur Ludovic mobile + desktop recommandee post-apply pour valider visuel CMP : tester viewports 360px (iPhone SE), 414px (iPhone 14 Pro), 768px (tablet portrait), 1024px+ (desktop). Verifier hero KeyBuzz visible sous le bandeau mobile, copy compacte LIVE, Accepter et Refuser equilibres, liens politiques accessibles.
2. Note ingress public DEV : smokes via port-forward pod direct car preview.keybuzz.pro DEV peut etre indisponible (cert TLS connu, pas de gap CMP).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8 |
| keybuzz-infra HEAD apres apply | a5cdc1f (ops manifest) |
| Website DEV runtime tag | v0.6.20-cmp-mobile-polish-dev |
| Website DEV runtime digest | sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe |
| Pod | keybuzz-website-6b87f6fddf-t8rxb Ready 1/1 |
| Source commit Website | bb49798 (PH-20.8) |
| Smokes /, /cookies, /privacy, /pricing, /contact | 5/5 HTTP 200 |
| PH-20.8 markers LIVE home | max-h-[60vh]=1, sm:hidden=1, copy mobile=1 |
| CMP elements preserves LIVE | Nous respectons=1, Refuser=1, politique cookies=1, politique confidentialite=1 |
| Tracking IDs preserves LIVE home | GA=1, SGTM=1, LinkedIn=1, marketing_cta_click=1, trackMarketingClick=9, Clarity=0 (baseline) |
| KEY-263 isolation DEV bundle live | OK (api.keybuzz.io seul=0) |
| Fake events delta home | 0 |
| Triple match (last-applied=manifest=pod imageID) | OK |
| Runtime Website PROD | v0.6.19-cta-tracking-prod INCHANGE |
| Runtime Client+API+Admin | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag DEV | v0.6.19-cta-tracking-dev |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA WEBSITE CMP MOBILE POLISH DEV PH-SAAS-T8.12AS.20.8`

QA navigateur Ludovic recommandee mobile + desktop pour valider visuel CMP.

STOP apres rapport + Linear. Pas de build, pas de PROD, pas de QA mutante.
