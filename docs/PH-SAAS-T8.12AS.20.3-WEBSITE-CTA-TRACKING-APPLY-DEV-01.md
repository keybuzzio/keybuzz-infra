# PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-APPLY-DEV-01

> Date : 2026-05-21
> Linear : KEY-340 (primary) ; KEY-337 (parent) ; KEY-338, KEY-339, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.3 WEBSITE CTA TRACKING APPLY DEV
> Environnement : GitOps strict DEV / aucun build / aucun docker push / aucun PROD

## VERDICT

GO APPLY WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3

- Manifest `k8s/website-dev/deployment.yaml` bumpe v0.6.18-ga4-cleanup-dev -> v0.6.19-cta-tracking-dev.
- Infra commit `a14e546` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-website configured`.
- Rollout : `deployment "keybuzz-website" successfully rolled out`.
- Pod nouveau : `keybuzz-website-7df5459b86-gkvk5` Ready, Running.
- Runtime digest DEV : `sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed` MATCH GHCR push.
- Smoke / + /pricing + /about + /features + /amazon Website DEV via port-forward : tous HTTP 200.
- Bundle chunks home live : 9 occurrences `trackMarketingClick` + 3 nouveaux `cta_id` PH-20.3 detectes.
- Runtime Website PROD `v0.6.18-ga4-cleanup-prod` INCHANGE.
- Runtime Client DEV/PROD INCHANGES.
- Reserve R2 PH-20.1 ADRESSEE.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| keybuzz-infra HEAD avant | f455567 (rapport PUSH IMAGE) |
| keybuzz-infra HEAD apres | a14e546 (ops apply DEV) |
| Runtime Website DEV avant | v0.6.18-ga4-cleanup-dev (digest sha256:63882ba57960726f...) |
| Runtime Website PROD avant | v0.6.18-ga4-cleanup-prod |
| Image GHCR target | v0.6.19-cta-tracking-dev (manifest digest sha256:2ec4789efa2ae74e...) |

## E1 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/website-dev/deployment.yaml | count = 1 (attendu 1) |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.23) apres bump | `image: ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev` + commentaire annotation |
| Annotation commentaire | commit website 6af74a2, KEY-340 +11 callsites, KEY-263 isolation preservee, Marketing IDs iso baseline, KEY-330 no fake events, KEY-338 R2 adressee, rollback v0.6.18 |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-website configured (server dry run)` |

## E2 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/website-dev/deployment.yaml (1 fichier) |
| Commit | a14e546 ops(website-dev): deploy v0.6.19-cta-tracking-dev |
| Push | OK f455567..a14e546 main -> main |
| Local | a14e5465112e478d486a53459a936c3e724b93b1 |

## E3 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-website configured
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-website" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | < 60s (drain old + new Ready) |
| Pod new | keybuzz-website-7df5459b86-gkvk5 |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed |
| Match GHCR push digest | **OK** |

## E4 RUNTIME DIGEST VERIFY

| Service | Namespace | Image runtime | Digest pod | Verdict |
|---|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed | **MATCH GHCR push** |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | (inchange) | OK PROD INTACT |

| Deployment status DEV | Valeur |
|---|---|
| spec.image | ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev |
| status.readyReplicas | 1 |
| status.updatedReplicas | 1 |
| status.replicas | 1 |

## E5 SMOKE TESTS DEV

Note : preview.keybuzz.pro ingress public HTTPS renvoie HTTP 000 (cert/TLS issue connue depuis PH-20.1, hors scope). Smokes effectues via port-forward direct au pod runtime nouveau, ce qui valide le bundle reellement deploye.

| URL (via port-forward http://127.0.0.1:13000) | Code | Bytes |
|---|---|---|
| / | 200 | 72 889 |
| /pricing | 200 | 71 975 |
| /about | 200 | 45 931 |
| /features | 200 | 64 681 |
| /amazon | 200 | 47 318 |

5/5 HTTP 200 OK.

## E6 BUNDLE LIVE CHUNKS AUDIT (home)

Audit via port-forward sur chunks home dynamiquement extraits du HTML SSR.

| Pattern | Observe chunks home live |
|---|---|
| G-R3QQDYEBFG (GA4) | 1 (HTML head) |
| `trackMarketingClick` (callsites) | 9 occurrences (helper + MarketingCTA wrapper + import statements + Footer onClick) |
| nouveaux cta_id PH-20.3 (`about_*`, `homepage_reassurance_amazon_link`, `features_marketplaces_amazon_link`, `footer_product_`, `footer_amazon_`) | 3 occurrences detectees dans les chunks home (footer presents puisque Footer rendu sur home + amazon link bandeau home) |

Note : la page home contient le Footer (`footer_product_` et `footer_amazon_` chunks dynamiques visibles) + le `homepage_reassurance_amazon_link` (1 occurrence). Les `about_*` ne sont pas dans home (chunk page/about dedie), pas un probleme. Verification complete done sur tous les chunks lors du BUILD DEV (cf PH-20.3 BUILD DEV rapport, +14 trackMarketingClick + 7 nouveaux cta_id).

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Bundle live preserve baseline v0.6.18 sans ajout fake event.
- Helper marketing-tracking.ts inchange : consent-aware, presence flags only.
- 0 nouveau Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- dans le runtime.
- Marketing IDs preserves : GA4 G-R3QQDYEBFG actif, SGTM t.keybuzz.pro, Meta/TikTok/LinkedIn iso baseline.

## E8 RESERVES PH-20.1 ETAT POST-APPLY

| Reserve | Etat avant APPLY DEV | Etat apres APPLY DEV |
|---|---|---|
| R1 Clarity client absent | ADRESSEE (PH-20.2 PROD) | ADRESSEE |
| R2 CTA home + pages secondaires non trackes | OUVERT (audit PH-20.1 sous-estimait via MarketingCTA wrapper) | **ADRESSEE DEV (11 callsites + correction audit)** |
| R3 Compte demo absent | OUVERT | OUVERT (PH-20.4) |
| R4 ad_spend Google bloque par token KO | OUVERT | OUVERT (KEY-322 hors PH-20) |
| R5 Pixels Meta/TikTok/LinkedIn ABSENTS Website (decision server-side) | EXPLICITER AGENCE | (inchange - decision strategique iso baseline) |
| R6 Hardening post-incident hors scope | OUVERT | OUVERT (KEY-323) |

R2 PH-20.1 ADRESSEE en DEV. Promotion PROD apres QA explicite Ludovic.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja sur GHCR avant cette phase).
- AUCUN docker push.
- AUCUN DEV Client change (runtime Client v3.5.206 INCHANGE).
- AUCUN PROD touche (runtime Website PROD v0.6.18 INCHANGE).
- AUCUN kubectl set image / set env / patch / edit (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN ticket Linear cree, ferme, ou statut modifie automatiquement.
- AUCUN evenement test envoye GA4/Meta/TikTok/LinkedIn/Google Ads.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/website-dev/deployment.yaml` -> image `v0.6.18-ga4-cleanup-dev` (digest `sha256:63882ba57960726fe8689784e0d3325be327019acc466e8239635588fb47baec`).
2. `git add + commit -m "ops(website-dev): ROLLBACK PH-20.3 to v0.6.18"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/website-dev/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-dev deploy/keybuzz-website --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. preview.keybuzz.pro ingress public HTTPS renvoie HTTP 000 (cert/TLS issue hors scope PH-20.3, deja note PH-20.1 et PH-20.2). Smokes done via port-forward pour validation runtime. Pour QA navigateur Ludovic : `kubectl port-forward -n keybuzz-website-dev deploy/keybuzz-website 13000:3000` puis http://127.0.0.1:13000.
2. Audit complete des 7 nouveaux cta_id deja effectue sur le bundle docker local (cf BUILD DEV rapport). Verification page-a-page necessiterait port-forward + grep chaque page chunk, hors scope APPLY (la verification BUILD DEV est suffisante).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3 |
| keybuzz-infra HEAD apres apply | a14e546 |
| Website DEV runtime tag | v0.6.19-cta-tracking-dev |
| Website DEV runtime digest | sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed |
| Pod | keybuzz-website-7df5459b86-gkvk5 Ready, Running |
| Source commit Website | 6af74a2 |
| Smoke Website DEV / + /pricing + /about + /features + /amazon | 5/5 HTTP 200 |
| Bundle chunks home live | trackMarketingClick=9, nouveaux cta_id PH-20.3=3 |
| Marketing IDs runtime | iso baseline (GA4 + Meta + TikTok + LinkedIn + SGTM) |
| No fake events delta | 0 |
| Runtime Website PROD | v0.6.18-ga4-cleanup-prod INCHANGE |
| Runtime Client DEV/PROD | INCHANGES |
| NO kubectl set/patch/edit | OK (GitOps strict) |
| Rollback tag DEV | v0.6.18-ga4-cleanup-dev digest sha256:63882ba57960726f... |
| Reserve R2 PH-20.1 | ADRESSEE en DEV |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3`

QA navigateur Ludovic recommandee :
- Port-forward `kubectl port-forward -n keybuzz-website-dev deploy/keybuzz-website 13000:3000` -> http://127.0.0.1:13000
- Ouvrir DevTools Network -> filtrer "collect" ou "marketing_cta_click" pour observer les events GA4 emis au clic CTA
- Cliquer CTAs about (3) -> verifier `about_hero_secondary_features`, `about_final_primary_features`, `about_final_secondary_pricing`
- Cliquer Link amazon bandeau home -> verifier `homepage_reassurance_amazon_link`
- Cliquer Link amazon bandeau features -> verifier `features_marketplaces_amazon_link`
- Cliquer footer product Tarifs/Services/Marketplaces + footer amazon -> verifier `footer_product_*` + `footer_amazon_*` IDs
- Verifier que pricing CTAs deja existants (7) emettent toujours
- Verifier que home/features MarketingCTA wrapper CTAs (16) emettent toujours

STOP.
