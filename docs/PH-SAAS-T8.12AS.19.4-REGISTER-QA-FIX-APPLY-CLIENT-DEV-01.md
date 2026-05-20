# PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-APPLY-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-APPLY-CLIENT-DEV
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

- keybuzz-infra HEAD : `4f5d7ba` (ops(client-dev): deploy v3.5.202-register-qa-fix-dev)
- Client DEV runtime : `v3.5.202-register-qa-fix-dev` digest `sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40` (pod wptw7 Ready 1/1, 0 restart)
- API DEV runtime : `v3.5.251-register-cro-dev` (INCHANGE, candidate preserve)
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH, NO kubectl set/patch/edit

Prochaine phrase GO attendue : GO QA REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | c7aa9f4 (origin=local) | OK |
| 2 rapports PH-19.4 untracked attendus | BUILD + PUSH-IMAGE | OK |
| GHCR config digest verify | sha256:1a2c23edc0bc... | OK match expected |
| GHCR manifest digest | sha256:b2bc34a2f6c6... | OK |
| GHCR layers count | 11 | OK |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image | Verdict |
|---|---|---|---|
| keybuzz-client | v3.5.201-register-lead-first-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-api | v3.5.251-register-cro-dev | v3.5.250-ad-spend-sync-all-prod | preserve |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | preserve |

## MANIFEST MODIFIE

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.201-register-lead-first-dev | image v3.5.202-register-qa-fix-dev | 1 ligne (image + commentaire PH-19.4 + rollback + digest) |

Commentaire manifest :
- phase PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-APPLY-CLIENT-DEV (2026-05-20)
- commit Client d363c38
- KEY-335 QA fix (selectedPlan === plan.id, Autopilot popular, retry safe sans marketing_owner_tenant_id)
- KEY-334 tunnel lead-first preserve
- KEY-329 + KEY-333 benchmark signup preserve
- KEY-325 data-clarity-mask preserve (Clarity NON activee)
- KEY-331 plan_selected unique preserve
- KEY-330 no fake events
- attribution UTM/click IDs/_gl/promo preservee (marketing_owner_tenant_id retire seulement si erreur API)
- rollback v3.5.201-register-lead-first-dev (digest sha256:8d82660f52af...)
- new digest sha256:b2bc34a2f6c6...

## ROLLBACK DIGEST PRE-PATCH

| Tag | Manifest digest GHCR |
|---|---|
| v3.5.201-register-lead-first-dev (rollback) | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de |
| v3.5.202-register-qa-fix-dev (new) | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 |

## DRY-RUN SERVER

| Manifest | Resultat |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files staged (3) | k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-19.4-BUILD-CLIENT-DEV-01.md (A), docs/PH-19.4-PUSH-IMAGE-CLIENT-DEV-01.md (A) |
| commit hash | 4f5d7ba |
| commit title | ops(client-dev): deploy v3.5.202-register-qa-fix-dev |
| insertions/deletions | +435 / -1 |
| push exit | 0 |
| origin HEAD post-push | 4f5d7ba (c7aa9f4 -> 4f5d7ba main -> main) |

## APPLY CLIENT DEV

| Etape | Resultat |
|---|---|
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise (GitOps strict) |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client DEV | v3.5.202-register-qa-fix-dev | v3.5.202-register-qa-fix-dev | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 | 1/1 (wptw7) | 0 | OK manifest = tag = digest |

## SMOKE DEV /REGISTER

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=autopilot&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes (shell client Next.js use-client hydration) | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |

Note SSR : page /register est rendue via use client hydration cote browser - shell HTML 9188 bytes contient `<!DOCTYPE html>` + Next.js precompiled CSS + script preload. Patterns lead-first + QA fix (register-lead-shell + register-reassurance-panel + register-confirm-plan + data-selected + aria-pressed + invalid_marketing_owner_tenant_id + "Le plus populaire" sur Autopilot + data-clarity-mask) sont dans les chunks JS lazy hydrates apres charge. Tous deja verifies bundle pre-deploy (phase BUILD-CLIENT-DEV-01 : 87 api-dev / 0 api.keybuzz.io / 2 data-selected / 2 aria-pressed / 2 invalid_marketing_owner_tenant_id / 7 "Le plus populaire" / 26 data-clarity-mask / 0 clarity.ms / 0 NEXT_PUBLIC_CLARITY). QA browser Ludovic confirmera visuellement post-apply.

## API DEV PRESERVE (read-only)

| Cluster | Image | Ready | Verdict |
|---|---|---|---|
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE (candidate preserve) |

Aucun apply API DEV.

## NON-REGRESSION PROD

| Service | Image PROD | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

Verifie cote source PH-19.4 + bundle BUILD-CLIENT-DEV-01 :

- plan_selected emit unique preserve dans handleSelectPlan (KEY-331) : 1 source emit, 4 refs bundle = SSR + chunks
- Selection plan UI fix : className conditionnel sur selectedPlan === plan.id + data-selected + aria-pressed
- Badge "Le plus populaire" maintenant sur Autopilot (badge + recommended deplaces depuis Pro dans `src/features/pricing/config.ts`)
- Fallback safe marketing_owner_tenant_id : retry une seule fois sans le champ sur erreur API specifique invalid_marketing_owner_tenant_id ; attribution UTM/click IDs/_gl/promo TOUJOURS preservee
- Pas d event par bouton (data-cta-id register_confirm_plan_and_checkout + register_plan_select_<plan> + register_cycle_toggle restent declaratifs)
- Boutons identifiables via data-cta-id + data-plan + data-cycle + data-promo-state + nouveaux data-selected + aria-pressed
- Clarity client NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0 bundle)
- Aucune fake review / fake metric / fake chiffre
- Pas d event Lead/Purchase/StartTrial/CompletePayment ajoute par PH-19.4
- Events ads existants src/lib/tracking.ts inchanges - decision KEY-330/KEY-331 reste a prendre

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : PH-19.4 DEV applied. Client DEV runtime = v3.5.202-register-qa-fix-dev, digest sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40. Pod wptw7 Ready 1/1, 0 restart. Infra commit 4f5d7ba. QA fix deployed : (1) plan selection uses selectedPlan === plan.id (data-selected + aria-pressed visibles au DOM), (2) Autopilot devient le plan "Le plus populaire", (3) retry safe sans marketing_owner_tenant_id sur erreur API invalid_marketing_owner_tenant_id. Smoke /register HTTP 200 + API /health 200. PROD unchanged. STOP avant QA navigateur Ludovic.

> **KEY-334** : Register lead-first preserve apres QA fix. Bundle PH-19.4 deja verifie phase BUILD-CLIENT-DEV-01 (register-lead-shell + register-reassurance-panel + register-confirm-plan + CTAs "Continuer vers le plan" / "Confirmer ce plan et activer" + ReassurancePanel "Ce que KeyBuzz va gerer"). API v3.5.251-register-cro-dev preserve. PROD inchange.

> **KEY-329** : Register CRO benchmark preserve apres QA fix. Decision produit Autopilot = plan le plus populaire desormais reflectee live DEV.

> **KEY-325 (Clarity)** : Clarity client still absent live DEV (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0 bundle). 26 data-clarity-mask PII preserves bundle.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique (1 emit source canonique). marketing_owner_tenant_id retire du payload seulement sur erreur API specifique, jamais en preventif. Events ads browser-side preexistants tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tag GHCR v3.5.202 deja pousse phase PUSH-IMAGE-CLIENT-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN apply API DEV (manifest API DEV inchange)
- AUCUN apply Website
- AUCUN changement source Client/API (commits d363c38 + 39e332ea deja pousses)
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT

Si necessaire, rollback strict GitOps :

1. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.201-register-lead-first-dev (digest sha256:8d82660f52af...)
2. git add + commit -m "ops(client-dev): ROLLBACK PH-19.4 to v3.5.201"
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
6. Verifier runtime digest = sha256:8d82660f52af...

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. HTML SSR /register reste vide en checks bruts (Next.js use client hydration) - QA visuelle browser Ludovic requise pour confirmer (a) clic Starter/Pro/Autopilot active visuellement la card cliquee, (b) badge "Le plus populaire" sur Autopilot, (c) URL ?marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk ne bloque plus le checkout.
2. Events ads browser-side preexistants - decision KEY-330/KEY-331 a confirmer.
3. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope.
4. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline matching v3.5.201).
5. Clarity activation client.keybuzz.io reste decision post-QA lead-first + QA fix.
6. Lead enrichment fields (marketplaces, volume commandes, urgence) : dette PH-19.x ulterieure.
7. Worktree build `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.4/keybuzz-client` reste sur disque : cleanup possible apres eventuelle phase PROD.

## VERDICT FINAL

GO APPLY CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD | 4f5d7ba |
| Client DEV runtime tag | v3.5.202-register-qa-fix-dev |
| Client DEV runtime digest | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 |
| Smoke /register | HTTP 200 |
| Smoke API /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD | 3/3 INCHANGE |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl set/patch/edit | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-APPLY-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO QA REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

STOP.
