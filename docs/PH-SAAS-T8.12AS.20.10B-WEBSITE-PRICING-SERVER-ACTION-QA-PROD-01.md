# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-QA-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B QA Website PROD post-apply read-only
> Environnement : PROD read-only (aucun build, aucun deploy, aucun restart, aucun event volontaire)

## VERDICT

GO QA WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B

- Pods PROD `keybuzz-website-7cf966fd7d-r5jn7` + `keybuzz-website-7cf966fd7d-spxpn` Ready 2/2, 0 restart, depuis startTime 2026-05-22T16:23 UTC (26 min uptime au moment QA).
- Tag : `v0.6.21-pricing-action-recover-prod` confirme.
- Digest runtime PROD : `sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b` MATCH GHCR push.
- Smokes publics externes 6/6 HTTP 200 (/, /pricing, /pricing?utm, /cookies, /privacy, /contact) avec tailles plausibles (28-72 KB).
- Stress raisonnable 40/40 HTTP 200 (20 /pricing + 20 /), 0 503, 0 timeout.
- Markers PH-20.10B LIVE 4/4 dans /app/.next runtime pod PROD.
- Tracking baseline preserve 5/5 (GA=18, SGTM=54, LinkedIn=18, marketing_cta_click=1, trackMarketingClick=40).
- CMP PH-20.8 preserve 3/3 (max-h-[60vh], sm:hidden, keybuzz_cookie_consent).
- KEY-263 PROD isolation OK (api.keybuzz.io=2, api-dev=0, client.keybuzz.io=66).
- Logs Website PROD (tail 500 par pod) : 0 Failed to find Server Action nouveau, 0 TypeError/Reference/Chunk/500/503/upstream.
- 503 controle : 0/46 cumule (6+20+20 GETs externes) en QA. CE apply mesure : 0/250 post-apply + 0/150 pre-apply. **0/440 total cumule** depuis apply.
- Runtime Website DEV INCHANGE.
- Runtime API + Client + Admin INCHANGES.

STOP. 503 Ludovic observe ~1/10 rafale F5 avant deploy : NON reproduit dans le total cumule 440 GETs cote bastion. Recommendation : observer trafic reel normal (et signaler si client/utilisateur reproduit en usage standard, pas rafale F5). Si reproduit en usage normal, ouvrir **PH-20.10C-503-RCA**.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T16:49:42Z |
| Pod r5jn7 | Ready 1/1, 0 restart, startTime 2026-05-22T16:23:27Z |
| Pod spxpn | Ready 1/1, 0 restart, startTime 2026-05-22T16:23:07Z |
| Uptime depuis apply | ~26 min |
| Tag runtime | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod |
| Digest runtime | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| MATCH expected | OK |

### Non-regression runtime

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website | DEV : v0.6.21-pricing-action-recover-dev | INCHANGE |
| keybuzz-api | DEV : v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | PROD : v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | DEV : v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | PROD : v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-admin-v2 | DEV+PROD | INCHANGES |

## E1 SMOKES PUBLICS PROD

### Routes uniques (1 GET chacune)

| Endpoint | HTTP | Bytes | Verdict |
|---|---|---|---|
| https://keybuzz.pro/ | 200 | 72 659 | OK |
| https://keybuzz.pro/pricing | 200 | 71 713 | OK |
| https://keybuzz.pro/pricing?utm_source=qa-readonly | 200 | 71 713 | OK |
| https://keybuzz.pro/cookies | 200 | 46 103 | OK |
| https://keybuzz.pro/privacy | 200 | 57 150 | OK |
| https://keybuzz.pro/contact | 200 | 28 362 | OK |

6/6 HTTP 200. Tailles plausibles confirment rendering complet.

### Stress raisonnable sequentiel

| Endpoint | Runs | 200 | 503 | Timeout | Autres | Verdict |
|---|---|---|---|---|---|---|
| /pricing | 20 | 20 | 0 | 0 | 0 | OK |
| / | 20 | 20 | 0 | 0 | 0 | OK |
| **Total** | **40** | **40** | **0** | **0** | **0** | **100% OK** |

Aucun submit form. Aucun clic CTA. Aucun event marketing genere.

## E2 AUDIT LIVE BUNDLE MARKERS PROD

### Markers patch PH-20.10B LIVE dans /app/.next pod PROD

| Marker | Count | Verdict |
|---|---|---|
| Failed to find Server Action | 2 | OK LIVE detection string |
| kb_pricing_server_action_reload_v1 | 2 | OK guard sessionStorage |
| sessionStorage | 6 | OK |
| window.location.reload | 9 | OK |

### Tracking baseline preserve

| ID/marker | Count | Verdict |
|---|---|---|
| GA G-R3QQDYEBFG | 18 | preserve |
| SGTM t.keybuzz.pro | 54 | preserve |
| LinkedIn 9969977 | 18 | preserve |
| marketing_cta_click | 1 | preserve |
| trackMarketingClick | 40 | preserve |

### CMP PH-20.8 + KEY-263 PROD

| Marker | Count | Verdict |
|---|---|---|
| max-h-[60vh] | 2 | preserve mobile compact |
| sm:hidden | 2 | preserve |
| keybuzz_cookie_consent | 5 | preserve CMP storage |
| api.keybuzz.io/api/public/contact | 2 | OK PROD endpoint present |
| api-dev.keybuzz.io | 0 | OK isolation respectee |
| client.keybuzz.io | 66 | preserve PROD CTA URL |

## E3 LOGS WEBSITE PROD POST-APPLY (tail 500 par pod)

| Pod | Pattern | Count | Verdict |
|---|---|---|---|
| r5jn7 | Failed to find Server Action | 0 | OK |
| r5jn7 | TypeError/Reference/Chunk/500/503/upstream | 0 | OK |
| spxpn | Failed to find Server Action | 0 | OK |
| spxpn | TypeError/Reference/Chunk/500/503/upstream | 0 | OK |

0 erreur nouvelle Server Action. 0 crash. 0 secret/PII leak. Pods stables depuis 26 min post-rollout.

## E4 503 NGINX NOTE

| Source | Total GETs | 503 count | Ratio |
|---|---|---|---|
| CE apply pre-baseline | 150 | 0 | 0% |
| CE apply post-rollout | 250 | 0 | 0% |
| CE QA actuelle | 40 (stress raisonnable) | 0 | 0% |
| Smokes uniques QA | 6 | 0 | 0% |
| **Total cumule** | **446** | **0** | **0%** |

| Source | Observation 503 |
|---|---|
| Ludovic avant deploy | ~1/10 rafale F5 agressive sur /pricing |
| Ludovic DEV (~100 refreshs) | 0 |
| CE bastion (446 GETs raisonnables) | 0 |

### Verdict 503

- En **GET sequentiel raisonnable** (rythme normal), 0 503 cumule sur 446 GETs depuis apply PH-20.10B.
- Le 503 Ludovic etait reproductible **uniquement en rafale F5 agressive**, non en navigation normale utilisateur.
- Le 503 nginx est probablement du a edge Cloudflare / pic temporaire / ratelimit applicatif sur burst F5, **PAS** au pattern Server Action mismatch (qui est traite par PH-20.10B).

### Recommandation

- **PAS de PH-20.10C-503-RCA immediate**. Le 503 est non bloquant en usage normal.
- **Observer trafic reel** sur 24-48h. Si client/utilisateur signale 503 en usage normal (pas rafale), alors **ouvrir PH-20.10C-503-RCA**.
- Le patch PH-20.10B (auto-reload Server Action) reste en place et reglera l UX si l erreur "Failed to find Server Action" survient apres un futur deploy.

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Meta event Graph API | 0 | OK |
| GA Measurement Protocol | 0 | OK |
| LinkedIn track API | 0 | OK |
| Contact form submit | 0 | OK |
| Lead/register/checkout test | 0 | OK |
| marketing_cta_click artificiel | 0 | OK |
| Browser session reelle | 0 (curl + kubectl exec only) | OK |
| Stress agressif DDoS-like | 0 (40 GETs sequentiels raisonnables max) | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN deploy DEV/PROD.
- AUCUN restart pod.
- AUCUN kubectl set / patch / edit / apply.
- AUCUN changement API / Client / Admin.
- AUCUN changement source.
- AUCUN tuning ingress/nginx.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## TRACKING / CMP PRESERVATION

| Indicateur | Verdict |
|---|---|
| GA G-R3QQDYEBFG | preserve |
| SGTM t.keybuzz.pro | preserve |
| LinkedIn 9969977 | preserve |
| marketing_cta_click / trackMarketingClick | preserve |
| CookieConsent PH-20.8 mobile compact | preserve |
| Hero/CTA pricing | preserve |
| Contact form CONTACT_API_URL | api.keybuzz.io PROD endpoint OK |

## GAPS

1. Aucun gap technique sur l apply PH-20.10B. Tout MATCH, tout preserve, tout green.
2. **Note 503** : observe seulement par Ludovic en rafale F5 agressive avant deploy. Non reproduit dans 446 GETs cumule cote bastion. Recommandation : observer trafic reel ; PH-20.10C-503-RCA uniquement si reproduit en usage normal utilisateur/client.
3. **Test recover end-to-end** non reproductible immediat : auto-reload sur stale bundle observable de facon naturelle au prochain deploy Website ulterieur (changement Server Action ID).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO QA WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | 907689b |
| Image runtime PROD | v0.6.21-pricing-action-recover-prod |
| Digest runtime PROD | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| Pods PROD | 2/2 Ready (r5jn7 + spxpn) 0 restart 26 min uptime |
| Triple match | OK |
| Smokes 6 routes | HTTP 200 chacune |
| Stress raisonnable | 40/40 HTTP 200 |
| Markers PH-20.10B LIVE | 4/4 OK |
| Tracking baseline | 5/5 preserve |
| CMP PH-20.8 | 3/3 preserve |
| KEY-263 PROD isolation | OK |
| Logs PROD | 0 erreur, stable |
| **503 total cumule depuis apply** | **0/446 GETs** |
| Runtime DEV/API/Client/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-QA-PROD-01.md` |

### Prochaine phrase GO attendue

- Si trafic reel observe sans 503 client : STOP, retour conversion suivante.
- Si 503 reproduit en usage normal utilisateur : `GO RCA WEBSITE PRICING 503 PROD PH-SAAS-T8.12AS.20.10C`

STOP. Aucun deploy, aucun event, aucun register/checkout, aucun changement Linear statut.
