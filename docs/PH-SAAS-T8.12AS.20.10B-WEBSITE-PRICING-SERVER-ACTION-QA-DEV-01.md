# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-QA-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B QA Website DEV post-apply read-only
> Environnement : DEV only (aucun PROD, aucun build, aucun deploy, aucun event)

## VERDICT

GO QA WEBSITE PRICING SERVER ACTION DEV PARTIAL READY PH-SAAS-T8.12AS.20.10B

Partial = QA technique 100% OK ; navigateur externe bloque depuis bastion (preview.keybuzz.pro non resoluble via Cloudflare edge). Recommandation : QA navigateur Ludovic en complement avant build PROD.

- Runtime Website DEV pod `keybuzz-website-f4546fd95-r44wj` Ready 1/1, 0 restart.
- Tag : `v0.6.21-pricing-action-recover-dev`.
- Digest runtime : `sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca` MATCH GHCR push.
- **Stress smoke interne 30/30 HTTP 200** (6 endpoints x 5 repetitions chacun) : /, /pricing, /pricing?utm_source=qa-readonly, /cookies, /privacy, /contact.
- Markers PH-20.10B LIVE 4/4 dans /app/.next runtime.
- Tracking baseline preserve 5/5 (GA/SGTM/LinkedIn/marketing_cta_click/trackMarketingClick).
- CMP PH-20.8 preserve 3/3 (max-h-[60vh], sm:hidden, keybuzz_cookie_consent).
- KEY-263 isolation strict OK (api-dev=2, api.keybuzz.io PROD endpoint=0).
- Logs Website DEV (tail 300) : 0 Failed to find Server Action, 0 TypeError/ReferenceError/ChunkLoadError/500/unhandled, "Ready in 1013ms".
- Runtime Website PROD INCHANGE v0.6.20-cmp-mobile-polish-prod.
- Runtime API + Client + Admin INCHANGES.
- 0 event tracking volontaire. 0 lead/register/checkout/contact submit. 0 clic CTA.

STOP avant build PROD. QA navigateur Ludovic recommandee sur https://preview.keybuzz.pro/pricing pour confirmation visuelle.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T15:40:04Z |
| Pod Website DEV | keybuzz-website-f4546fd95-r44wj |
| Ready | 1/1 |
| Restarts | 0 |
| Tag runtime | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-dev |
| Digest runtime | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Digest expected (GHCR push) | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| MATCH | OK |

## E1 STRESS SMOKE INTERNE DEV

Methode : `kubectl exec` direct dans pod `http://127.0.0.1:3000/` (bastion ne peut atteindre preview.keybuzz.pro externe via Cloudflare edge).

| Endpoint | Runs | HTTP 200 | Errors | Verdict |
|---|---|---|---|---|
| / | 5 | 5 | 0 | OK |
| /pricing | 5 | 5 | 0 | OK |
| /pricing?utm_source=qa-readonly | 5 | 5 | 0 | OK |
| /cookies | 5 | 5 | 0 | OK |
| /privacy | 5 | 5 | 0 | OK |
| /contact | 5 | 5 | 0 | OK |
| **Total** | **30** | **30** | **0** | **100% OK** |

Aucun submit form. Aucun clic CTA. Aucun event marketing genere.

## E2 AUDIT LIVE BUNDLE MARKERS

### Markers patch PH-20.10B LIVE dans /app/.next pod runtime

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

### CMP PH-20.8 preserve

| Marker | Count | Verdict |
|---|---|---|
| max-h-[60vh] | 2 | preserve mobile compact |
| sm:hidden | 2 | preserve |
| keybuzz_cookie_consent | 5 | preserve CMP storage |

### KEY-263 isolation strict DEV

| Indicateur | Count | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 2 | OK isolation DEV |
| api.keybuzz.io/api/public/contact (PROD endpoint dans DEV) | 0 | OK |

## E3 LOGS WEBSITE DEV POST-APPLY (tail 300)

| Pattern | Count | Verdict |
|---|---|---|
| Failed to find Server Action | 0 | OK (10min post-rollout, pas encore de stale bundle observable) |
| TypeError | 0 | OK |
| ReferenceError | 0 | OK |
| ChunkLoadError | 0 | OK |
| 500 | 0 | OK |
| unhandled | 0 | OK |
| Secret leak / token dump | 0 | OK |
| Startup message | "Ready in 1013ms" | OK |

**Note importante** : la presence du marker recover dans le bundle ne peut etre testee qu en condition reelle (utilisateur avec onglet ouvert avant deploy + Server Action invoke). Pas reproductible en QA DEV immediat. La validation reelle aura lieu naturellement au prochain deploy Website ulterieur. Pour confirmer l UX de recover, un test browser DevTools manuel sera possible (forcer error.message contenant "Failed to find Server Action").

## E4 BROWSER QA DEV - LIMITATION

| Item | Resultat |
|---|---|
| Tentative bastion -> preview.keybuzz.pro/pricing | timeout (HTTP 000) - Cloudflare edge bloque depuis bastion (comportement attendu et confirme depuis sessions precedentes) |
| Service ClusterIP | 10.103.199.176:80 (interne K8s seulement) |
| Ingress | keybuzz-website-preview -> preview.keybuzz.pro |

**Recommandation** : QA navigateur Ludovic en complement :
1. Ouvrir https://preview.keybuzz.pro/pricing en fresh context (Ctrl+Shift+N).
2. Verifier que la page se charge sans erreur.
3. Reload 5 fois desktop + 5 fois mobile (DevTools responsive).
4. Verifier console errors = 0 nouvelle.
5. **Optionnel test recover** : DevTools -> Application -> sessionStorage : verifier que `kb_pricing_server_action_reload_v1` n est PAS present apres reload normal (le guard ne s active que si l erreur est detectee).
6. Ne pas cliquer CTA ni submit form.

## E5 RUNTIME NON-REGRESSION

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-website | DEV : v0.6.21-pricing-action-recover-dev | NOUVEAU |
| keybuzz-website | PROD : v0.6.20-cmp-mobile-polish-prod | INCHANGE |
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
| Browser session reelle | 0 (kubectl exec only depuis bastion) | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN deploy PROD.
- AUCUN restart pod.
- AUCUN kubectl set / patch / edit / apply.
- AUCUN changement API / Client / Admin.
- AUCUN changement source.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## GAPS

1. **QA browser externe non realisable depuis bastion** : preview.keybuzz.pro bloque par Cloudflare edge depuis l IP bastion. QA navigateur Ludovic recommandee en complement.
2. **Test recover end-to-end non reproductible immediat** : le mecanisme auto-reload sur "Failed to find Server Action" sera observable de facon naturelle au prochain deploy Website ulterieur (changement de Server Action ID), pas en QA DEV immediat. Test DevTools possible si Ludovic souhaite forcer l erreur via console.
3. Aucun gap technique. Apply DEV propre, smokes 30/30, markers + tracking + CMP + KEY-263 OK, logs clean, runtime preserve.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO QA WEBSITE PRICING SERVER ACTION DEV PARTIAL READY PH-SAAS-T8.12AS.20.10B (technique 100% OK ; browser externe recommande Ludovic) |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | 907689b |
| Image runtime DEV | v0.6.21-pricing-action-recover-dev |
| Runtime digest DEV | sha256:8bdfb7a7479fed9de0b62106ca13077a75df19ad067ea11825adc7f8a51ab5ca |
| Pod DEV | keybuzz-website-f4546fd95-r44wj Ready 1/1 0 restarts |
| Stress smoke interne | 30/30 HTTP 200 (6 endpoints x 5 runs) |
| Markers PH-20.10B LIVE | 4/4 OK |
| Tracking baseline | 5/5 preserve |
| CMP PH-20.8 | 3/3 preserve |
| KEY-263 isolation | OK |
| Logs DEV | 0 erreur, Ready in 1013ms |
| Website PROD | INCHANGE v0.6.20 |
| API + Client + Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-QA-DEV-01.md` |

### Prochaine phrase GO attendue

`GO BUILD WEBSITE PRICING SERVER ACTION PROD PH-SAAS-T8.12AS.20.10B`

Si Ludovic souhaite QA navigateur avant build PROD : ouvrir https://preview.keybuzz.pro/pricing en fresh context, reload desktop + mobile, verifier 0 console error, retour confirmation.

STOP. Aucun PROD, aucun event Meta, aucun register/checkout, aucun changement Linear statut.
