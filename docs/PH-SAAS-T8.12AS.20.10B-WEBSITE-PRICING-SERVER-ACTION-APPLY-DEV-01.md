# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-APPLY-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B APPLY Website DEV GitOps strict
> Environnement : DEV only (aucun PROD, aucun build, aucun event tracking volontaire)

## VERDICT

GO APPLY WEBSITE PRICING SERVER ACTION DEV READY PH-SAAS-T8.12AS.20.10B

- Manifest `k8s/website-dev/deployment.yaml` bumpe v0.6.20-cmp-mobile-polish-dev -> v0.6.21-pricing-action-recover-dev.
- Infra commit manifest `cfd6118` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-website" successfully rolled out`.
- Pod nouveau `keybuzz-website-f4546fd95-r44wj` Ready 1/1.
- Runtime digest DEV : `sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca` MATCH GHCR.
- Triple match : last-applied = manifest spec = pod imageID.
- Smokes internes pod 5/5 HTTP 200 OK (/, /pricing, /cookies, /privacy, /contact).
- 10 markers PH-20.10B LIVE dans /app/.next runtime pod : Failed to find Server Action=2, kb_pricing_server_action_reload_v1=2, sessionStorage=6, window.location.reload=9.
- Tracking baseline preserve 5/5 (GA G-R3QQDYEBFG=18, SGTM=54, LinkedIn=18, marketing_cta_click=1, trackMarketingClick=40).
- CMP PH-20.8 preserve 3/3 (max-h-[60vh]=2, sm:hidden=2, keybuzz_cookie_consent=5).
- KEY-263 isolation OK (api-dev=2, api.keybuzz.io PROD endpoint=0).
- Logs Website DEV pod : 0 Failed to find Server Action, 0 TypeError/ReferenceError/ChunkLoadError/500/unhandled, "Ready in 1013ms".
- Runtime Website PROD `v0.6.20-cmp-mobile-polish-prod` INCHANGE.
- Runtime API + Client + Admin INCHANGES.

STOP avant QA DEV PH-20.10B.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T15:29:44Z |
| keybuzz-infra HEAD avant | ea03af3 |
| keybuzz-infra HEAD apres | **cfd6118** (post-bump) |
| Runtime Website DEV avant | v0.6.20-cmp-mobile-polish-dev |
| GHCR digest cible | sha256:8008501c61fd5b17465dab7ca522a1d7ab6f8be6b1fb553482f22d5c71907775 MATCH (config) |
| Manifest digest GHCR | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Manifest path verifie | `k8s/website-dev/deployment.yaml` (PH-20.8 confirme) |

## E1 BUMP MANIFEST WEBSITE DEV (GitOps strict)

| Manifest | Avant | Apres | Verdict |
|---|---|---|---|
| `k8s/website-dev/deployment.yaml` l.23 | v0.6.20-cmp-mobile-polish-dev | **v0.6.21-pricing-action-recover-dev** + annotation PH-20.10B | OK |
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) | scope strict |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-website configured (server dry run)` | OK |

| Item | Valeur |
|---|---|
| Commit infra | `cfd6118` chore(website): bump DEV pricing action recover PH-20.10B |
| Push | OK ea03af3..cfd6118 main -> main |

## E2 APPLY DEV + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply -f | OK `deployment.apps/keybuzz-website configured` |
| Rollout status | `deployment "keybuzz-website" successfully rolled out` |
| Pod ancien | (terminated) |
| Pod nouveau Ready | **keybuzz-website-f4546fd95-r44wj** |
| Pod imageID | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Time to ready | "Ready in 1013ms" |

### Triple match DEV

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca | OK MATCH expected |

## E3 SMOKES WEBSITE DEV

Note : bastion ne peut pas resoudre/atteindre directement preview.keybuzz.pro (probable Cloudflare bot protection edge). Test smoke effectue via `kubectl exec` direct dans pod sur `http://127.0.0.1:3000/`.

| Endpoint | HTTP | Verdict |
|---|---|---|
| /  (pod local) | 200 | OK |
| /pricing | 200 | OK |
| /cookies | 200 | OK |
| /privacy | 200 | OK |
| /contact | 200 | OK |

5/5 HTTP 200. Aucun submit form, aucun clic CTA.

| Ingress | Hosts | Service ClusterIP |
|---|---|---|
| keybuzz-website-preview | preview.keybuzz.pro | 10.103.199.176:80 |

## E4 AUDIT LIVE BUNDLE MARKERS PH-20.10B

| Marker | Count /app/.next runtime pod | Verdict |
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

### CMP PH-20.8 preserve

| Marker | Count | Verdict |
|---|---|---|
| max-h-[60vh] | 2 | preserve mobile compact |
| sm:hidden | 2 | preserve |
| keybuzz_cookie_consent | 5 | preserve CMP storage |

### KEY-263 isolation strict

| Indicateur | Count | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 2 | OK isolation DEV |
| api.keybuzz.io/api/public/contact (PROD endpoint dans DEV) | 0 | OK |

## E5 LOGS WEBSITE DEV POD (tail 200)

| Pattern | Count | Verdict |
|---|---|---|
| Failed to find Server Action | 0 | OK (rollout frais, pas encore de stale bundle) |
| TypeError | 0 | OK |
| ReferenceError | 0 | OK |
| ChunkLoadError | 0 | OK |
| 500 | 0 | OK |
| unhandled | 0 | OK |
| Startup message | "Ready in 1013ms" | OK |
| Secret leak / token dump | 0 | OK |

Note : la persistence du pattern "Failed to find Server Action" sera observable lors de futures sessions navigateur ayant un bundle stale d un deploy precedent. La phase QA DEV pourra simuler ce scenario.

## E6 RUNTIME NON-REGRESSION

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website | DEV : v0.6.21-pricing-action-recover-dev | NOUVEAU |
| keybuzz-website | PROD : v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-api | DEV : v3.5.253-meta-capi-emq-dev | INCHANGE |
| keybuzz-api | PROD : v3.5.252-meta-capi-emq-prod | INCHANGE |
| keybuzz-client | DEV : v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | PROD : v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | INCHANGES |

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
| Browser session reelle | 0 (curl/kubectl uniquement) | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN deploy PROD.
- AUCUN restart pod hors rollout normal.
- AUCUN kubectl set image / set env / patch / edit (GitOps strict apply -f).
- AUCUN changement API / Client / Admin.
- AUCUN changement tracking IDs / CMP / copy / design / pricing.
- AUCUN faux event / register / checkout / lead.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PROD/DEV DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/website-dev/deployment.yaml -> image v0.6.20-cmp-mobile-polish-dev
git add k8s/website-dev/deployment.yaml
git commit -m "ops(website-dev): ROLLBACK PH-20.10B to v0.6.20"
git push origin main
kubectl apply -f k8s/website-dev/deployment.yaml
kubectl rollout status -n keybuzz-website-dev deploy/keybuzz-website --timeout=180s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Aucun. Apply DEV propre, triple match parfait, smokes 5/5, markers live + tracking + CMP + KEY-263 OK, logs clean, runtime PROD+API+Client preserves.
2. Note : la valeur reelle du fix (auto-reload sur bundle stale) ne peut etre observee qu apres un deploy ulterieur (Server Action ID change) + utilisateur avec ancien onglet ouvert. Pas reproductible en QA DEV immediat. Sera observable de facon naturelle au prochain deploy Website.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY WEBSITE PRICING SERVER ACTION DEV READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | 907689b |
| Image runtime DEV | v0.6.21-pricing-action-recover-dev |
| Runtime digest DEV | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Pod DEV nouveau | keybuzz-website-f4546fd95-r44wj Ready 1/1 |
| Triple match | OK |
| Commit infra manifest | cfd6118 push origin/main |
| Smokes pod | 5/5 HTTP 200 |
| Markers PH-20.10B LIVE | 4/4 OK |
| Tracking + CMP + KEY-263 | preserves |
| Logs DEV | 0 erreur, Ready in 1013ms |
| Website PROD | INCHANGE |
| API + Client + Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA WEBSITE PRICING SERVER ACTION DEV PH-SAAS-T8.12AS.20.10B`

STOP. Aucun PROD, aucun event, aucun register/checkout, aucun changement Linear statut.
