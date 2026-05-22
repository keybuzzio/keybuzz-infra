# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-APPLY-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B APPLY Website PROD GitOps strict + controle 503
> Environnement : PROD only (aucun build, aucun docker push, aucun event volontaire)

## VERDICT

GO APPLY WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B

- GO PROD Ludovic recu et respecte.
- Manifest `k8s/website-prod/deployment.yaml` bumpe v0.6.20-cmp-mobile-polish-prod -> v0.6.21-pricing-action-recover-prod.
- Infra commit manifest `93d7e84` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-website" successfully rolled out` (rolling 2/2).
- Pods nouveaux : `keybuzz-website-7cf966fd7d-r5jn7` + `keybuzz-website-7cf966fd7d-spxpn` Ready 2/2.
- Runtime digest PROD : `sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b` MATCH GHCR.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes internes pod 6/6 HTTP 200 OK (/, /pricing, /pricing?utm, /cookies, /privacy, /contact).
- 10 markers PH-20.10B LIVE dans /app/.next runtime PROD : Failed to find Server Action=2, kb_pricing_server_action_reload_v1=2, sessionStorage=6, window.location.reload=9.
- Tracking baseline preserve 5/5 (GA=18, SGTM=54, LinkedIn=18, marketing_cta_click=1, trackMarketingClick=40).
- CMP PH-20.8 preserve 3/3.
- KEY-263 PROD isolation OK (api.keybuzz.io=2, api-dev=0, client.keybuzz.io=66).
- Logs Website PROD : 0 Failed to find Server Action nouveau, 0 TypeError/Reference/Chunk/500/503 nouveau, "Ready in 1216ms" + "Ready in 1342ms".
- 503 baseline pre-apply : 0/150 (50 ext /pricing + 50 ext / + 50 int). Pas reproduit dans cette session, mais Ludovic l a observe avant deploy (~1/10 rafale F5).
- 503 post-apply : **0/250** (100 ext /pricing + 50 ext / + 100 int). Pas reproduit non plus apres rollout.
- Runtime API + Client + Admin INCHANGES.

**Note 503** : intermittent confirme (Ludovic l a observe pre-deploy, pas reproductible dans 250 GETs cote bastion). Cause probable : edge Cloudflare, ratelimit, pod saturation a certaines heures, ou load-balancer hiccups occasionnels. **Si 503 persiste cote utilisateurs en condition reelle, ouvrir phase dediee PH-20.10C-503-RCA**.

STOP avant QA navigateur Ludovic ou phase suivante.

## CONTEXTE

GO PROD Ludovic recu dans la conversation courante : "GO APPLY WEBSITE PRICING SERVER ACTION PROD PH-SAAS-T8.12AS.20.10B".

PH-20.10B DEV applique et valide (commit 907689b, image v0.6.21-pricing-action-recover-dev, QA 30/30 OK, ~100 refreshs Ludovic OK).

Image PROD pushee sur GHCR le meme jour : v0.6.21-pricing-action-recover-prod, digest sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T16:19:52Z |
| keybuzz-infra HEAD avant | 2c08b4f |
| keybuzz-infra HEAD apres bump | **93d7e84** |
| Runtime Website PROD avant | v0.6.20-cmp-mobile-polish-prod (digest sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23) |
| GHCR digest cible | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd MATCH (config) |
| Manifest digest GHCR | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| Manifest path verifie | `k8s/website-prod/deployment.yaml` |
| Pods PROD avant | 2/2 Ready (drcpx + v7j7w sur v0.6.20) |

## E1 BASELINE 503 PRE-APPLY

| Test | Runs | 200 | 503 | Timeout | Autres | Verdict |
|---|---|---|---|---|---|---|
| Ext https://keybuzz.pro/pricing | 50 | 50 | 0 | 0 | 0 | OK (intermittent non reproduit) |
| Ext https://keybuzz.pro/ | 50 | 50 | 0 | 0 | 0 | OK |
| Int pod /pricing | 50 | 50 | 0 | 0 | 0 | OK |
| **Total** | **150** | **150** | **0** | **0** | **0** | **0% 503** |

Note : 503 intermittent Ludovic ~1/10 rafale F5 non reproduit dans cette session bastion (pattern occasionnel/edge probable).

## E2 BUMP MANIFEST WEBSITE PROD (GitOps strict)

| Manifest | Avant | Apres | Verdict |
|---|---|---|---|
| `k8s/website-prod/deployment.yaml` l.36 | v0.6.20-cmp-mobile-polish-prod | **v0.6.21-pricing-action-recover-prod** + annotation PH-20.10B | OK |
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) | scope strict |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-website configured (server dry run)` | OK |

| Item | Valeur |
|---|---|
| Commit infra | `93d7e84` chore(website): bump PROD pricing action recover PH-20.10B |
| Push | OK 2c08b4f..93d7e84 main -> main |

## E3 APPLY PROD + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply -f | OK `deployment.apps/keybuzz-website configured` |
| Rollout status | `deployment "keybuzz-website" successfully rolled out` (rolling 2/2) |
| Pod 1 nouveau | **keybuzz-website-7cf966fd7d-r5jn7** Ready 1/1, startTime 2026-05-22T16:23:27Z, Ready in 1216ms |
| Pod 2 nouveau | **keybuzz-website-7cf966fd7d-spxpn** Ready 1/1, startTime 2026-05-22T16:23:07Z, Ready in 1342ms |
| Pod imageID | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| readyReplicas | 2/2 |

### Triple match PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b | OK MATCH expected |

## E4 SMOKES READ-ONLY WEBSITE PROD

Test via `kubectl exec` direct dans pod sur http://127.0.0.1:3000/ (bastion ne resout pas keybuzz.pro externe via Cloudflare edge pour test direct DNS).

| Endpoint | HTTP | Verdict |
|---|---|---|
| / | 200 | OK |
| /pricing | 200 | OK |
| /pricing?utm_source=qa-readonly | 200 | OK |
| /cookies | 200 | OK |
| /privacy | 200 | OK |
| /contact | 200 | OK |

6/6 HTTP 200. Aucun submit form. Aucun clic CTA.

## E5 AUDIT LIVE BUNDLE MARKERS PROD

| Marker | Count /app/.next runtime PROD | Verdict |
|---|---|---|
| Failed to find Server Action | 2 | OK LIVE |
| kb_pricing_server_action_reload_v1 | 2 | OK LIVE |
| sessionStorage | 6 | OK LIVE |
| window.location.reload | 9 | OK LIVE |

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

## E6 LOGS WEBSITE PROD POST-ROLLOUT (tail 300 par pod)

| Pod | Pattern | Count | Verdict |
|---|---|---|---|
| r5jn7 | Failed to find Server Action | 0 | OK (rollout frais) |
| r5jn7 | TypeError/Reference/Chunk/500/503/upstream | 0 | OK |
| r5jn7 | Startup | "Ready in 1216ms" | OK |
| spxpn | Failed to find Server Action | 0 | OK |
| spxpn | TypeError/Reference/Chunk/500/503/upstream | 0 | OK |
| spxpn | Startup | "Ready in 1342ms" | OK |

0 erreur nouvelle. 0 secret/PII leak.

## E7 CONTROLE 503 POST-APPLY

| Test | Runs | 200 | 503 | Timeout | Autres | Verdict |
|---|---|---|---|---|---|---|
| Ext https://keybuzz.pro/pricing | 100 | 100 | 0 | 0 | 0 | OK 0% 503 |
| Ext https://keybuzz.pro/ | 50 | 50 | 0 | 0 | 0 | OK |
| Int pod /pricing | 100 | 100 | 0 | 0 | 0 | OK |
| **Total** | **250** | **250** | **0** | **0** | **0** | **0% 503** |

### Comparaison pre vs post apply

| Phase | Total | 200 | 503 | Ratio 503 |
|---|---|---|---|---|
| Pre-apply | 150 | 150 | 0 | 0% |
| Post-apply | 250 | 250 | 0 | 0% |
| Delta | n/a | n/a | 0 | inchange |

**Note importante** : Ludovic a observe 503 intermittent ~1/10 rafale F5 avant ce deploy. Cette session bastion ne reproduit pas le 503 (0/400 total cumule pre+post). Le pattern observe par Ludovic est probablement :
- soit specifique a son IP/edge Cloudflare (POP regional, ratelimit, browser cache);
- soit pic temporaire deja resorbe (pods saturation/load) ;
- soit ratelimit applicatif sur F5 agressif.

**Le 503 nginx n est PAS lie au patch PH-20.10B** (qui adresse uniquement le pattern Server Action ID mismatch via error boundary client). Si Ludovic reproduit le 503 post-apply en navigateur reel, ouvrir **phase PH-20.10C-503-RCA** dediee.

## E8 RUNTIME NON-REGRESSION

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website | DEV : v0.6.21-pricing-action-recover-dev | INCHANGE |
| keybuzz-website | PROD : v0.6.21-pricing-action-recover-prod | **NOUVEAU** |
| keybuzz-api | DEV : v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | PROD : v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | DEV : v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | PROD : v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-admin-v2 | DEV+PROD | INCHANGES |

Aucun deploy supplementaire. Aucun kubectl set/patch/edit.

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Meta event Graph API | 0 | OK |
| GA Measurement Protocol | 0 | OK |
| LinkedIn track API | 0 | OK |
| Contact form submit | 0 | OK |
| Lead/register/checkout test | 0 | OK |
| marketing_cta_click artificiel | 0 | OK |
| Stress GET only (no POST mutateur) | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN deploy DEV.
- AUCUN restart pod hors rollout normal.
- AUCUN kubectl set / patch / edit (GitOps strict apply -f).
- AUCUN changement API / Client / Admin.
- AUCUN changement tracking IDs / CMP / copy / design / pricing.
- AUCUN faux event / register / checkout / lead.
- AUCUN secret/token/PII affiche.
- AUCUN tuning ingress/nginx.
- AUCUN diagnostic destructif 503.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PROD DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/website-prod/deployment.yaml -> image v0.6.20-cmp-mobile-polish-prod
git add k8s/website-prod/deployment.yaml
git commit -m "ops(website-prod): ROLLBACK PH-20.10B to v0.6.20"
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status -n keybuzz-website-prod deploy/keybuzz-website --timeout=180s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. **503 intermittent non reproduit** dans cette session bastion (0/400 cumule pre+post). Si Ludovic le voit toujours en navigateur reel, ouvrir PH-20.10C-503-RCA dediee (out of scope PH-20.10B qui adresse uniquement Server Action mismatch).
2. **Test recover end-to-end non reproductible immediat** : auto-reload sur "Failed to find Server Action" sera observable de facon naturelle au prochain deploy Website ulterieur (changement de Server Action ID), pas en QA immediat. Test DevTools manuel possible si Ludovic veut forcer l erreur via console.
3. Aucun gap technique sur l apply lui-meme.

## DECISION

| Aspect | Decision |
|---|---|
| PH-20.10B apply PROD | **OK** (apply propre, smokes 6/6, markers 4/4, tracking/CMP preserve, 250/250 HTTP 200 sans 503) |
| PH-20.10C 503-RCA | **EN ATTENTE retour Ludovic** : a ouvrir si 503 persiste cote utilisateur reel |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| GO PROD Ludovic | recu et respecte |
| Source commit Website | 907689b |
| Image runtime PROD | v0.6.21-pricing-action-recover-prod |
| Runtime digest PROD | sha256:8fefca2e6384d35c2309c02c70c829e756f72b99001c71d8db68d5c78abe009b |
| Pods PROD | 2/2 Ready (r5jn7 + spxpn) |
| Triple match | OK |
| Commit infra manifest | 93d7e84 push origin/main |
| Smokes pod 6/6 | HTTP 200 |
| Markers PH-20.10B LIVE | 4/4 OK |
| Tracking + CMP + KEY-263 PROD | preserves |
| Logs PROD | 0 erreur, Ready in 1216ms + 1342ms |
| 503 pre-apply | 0/150 |
| 503 post-apply | **0/250** |
| Runtime DEV/API/Client/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-APPLY-PROD-01.md` |

### Prochaine phrase GO attendue

Si Ludovic ne reproduit plus 503 en navigateur reel :
`GO QA WEBSITE PRICING SERVER ACTION PROD PH-SAAS-T8.12AS.20.10B`

Si Ludovic reproduit toujours 503 en navigateur reel :
`GO RCA WEBSITE PRICING 503 PROD PH-SAAS-T8.12AS.20.10C`

STOP. Aucun deploy supplementaire, aucun event Meta, aucun register/checkout, aucun tuning ingress, aucun changement Linear statut.
