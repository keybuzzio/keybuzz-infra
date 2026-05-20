# PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-APPLY-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-334 (primary), KEY-329, KEY-333, KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-APPLY-CLIENT-DEV
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

- keybuzz-infra HEAD : `8bb6bb6` (ops(client-dev): deploy v3.5.201-register-lead-first-dev)
- Client DEV runtime : `v3.5.201-register-lead-first-dev` digest `sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de` (pod lr6x7 Ready 0 restarts)
- API DEV runtime : `v3.5.251-register-cro-dev` (INCHANGE, candidate valide)
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH

Prochaine phrase GO attendue : GO QA REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | 79256cd | OK |
| 2 rapports PH untracked attendus | docs/PH-19.3-BUILD + PUSH-IMAGE | OK |
| GHCR Client v3.5.201 digest expected | sha256:8d82660f52af... | OK pulled-back match |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image | Verdict |
|---|---|---|---|
| keybuzz-client | v3.5.200-register-cro-uplift-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-api | v3.5.251-register-cro-dev | v3.5.250-ad-spend-sync-all-prod | preserve |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | preserve |

## MANIFEST MODIFIE

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.200-register-cro-uplift-dev | image v3.5.201-register-lead-first-dev | 1 ligne (image + commentaire PH-19.3 + rollback + digest) |

Commentaire manifest :
- phase PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-APPLY-CLIENT-DEV (2026-05-20)
- commit Client 397687a
- KEY-334 tunnel lead-first (default step email, plan apres user, layout split + ReassurancePanel)
- email/code/company/user/plan/checkout/Stripe
- handleConfirmPlanAndCheckout cree tenant + Stripe a la confirmation explicite du plan
- ReassurancePanel proof factuelle KeyBuzz uniquement
- KEY-329 + KEY-333 benchmark signup Gojiberry/BabyLoveGrowth/Taap/Blabla patterns sans copie
- KEY-325 data-clarity-mask 13 inputs PII preserves (Clarity NON activee)
- KEY-331 plan_selected emit unique
- KEY-330 no fake events ajoutes
- attribution complete preservee
- rollback v3.5.200-register-cro-uplift-dev (digest sha256:6b199ef2e548...)
- new digest sha256:8d82660f52af...

## ROLLBACK DIGEST PRE-PATCH

| Tag | Manifest digest GHCR |
|---|---|
| v3.5.200-register-cro-uplift-dev (rollback) | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 |
| v3.5.201-register-lead-first-dev (new) | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de |

## DRY-RUN SERVER

| Manifest | Resultat |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files staged (3) | k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-19.3-BUILD-CLIENT-DEV-01.md (A), docs/PH-19.3-PUSH-IMAGE-CLIENT-DEV-01.md (A) |
| commit hash | 8bb6bb6 |
| commit title | ops(client-dev): deploy v3.5.201-register-lead-first-dev |
| insertions/deletions | +419 / -1 |
| push exit | 0 |
| origin HEAD post-push | 8bb6bb6 (79256cd -> 8bb6bb6 main -> main) |

## APPLY CLIENT DEV

| Etape | Resultat |
|---|---|
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client DEV | v3.5.201-register-lead-first-dev | v3.5.201-register-lead-first-dev | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de | 1/1 (lr6x7) | 0 | OK manifest = tag = digest |

## SMOKE DEV /REGISTER

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes (shell client Next.js use-client hydration) | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |

Note SSR : page /register est rendue via use client hydration cote browser - shell HTML 9188 bytes, composants register lead-first (register-lead-shell + register-reassurance-panel + register-confirm-plan + CTAs "Continuer vers le plan" / "Confirmer ce plan et activer") sont dans les chunks JS lazy hydrates apres charge. Patterns deja verifies bundle pre-deploy (phase BUILD-CLIENT-DEV-01). QA browser Ludovic confirmera visuellement post-apply.

## API DEV PRESERVE (read-only)

| Cluster | Image | Ready | Verdict |
|---|---|---|---|
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE (candidate valide) |

Aucun apply API DEV.

## NON-REGRESSION PROD

| Service | Image PROD | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

Verifie cote source PH-19.3 + bundle BUILD-CLIENT-DEV-01 :

- plan_selected emit unique preserve dans handleSelectPlan (KEY-331)
- Preselection plan/cycle via URL ne declenche pas plan_selected automatiquement (handler appele uniquement sur clic)
- Pas d event par bouton (data-cta-id register_continue_to_plan + register_confirm_plan_and_checkout + register_plan_select_<plan> + register_cycle_toggle)
- Boutons identifiables via data-cta-id + data-plan + data-cycle + data-promo-state
- Clarity client NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0)
- Aucune fake review / fake metric / fake chiffre
- Pas d event Lead/Purchase/StartTrial/CompletePayment ajoute par PH-19.3
- Events ads existants src/lib/tracking.ts inchanges - decision KEY-330/KEY-331 reste a prendre

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-334 (primary)** : DEV applied Client v3.5.201-register-lead-first-dev. Infra commit 8bb6bb6. Runtime digest sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de pod lr6x7 Ready. Smoke /register HTTP 200 + API /health 200. STOP avant QA navigateur Ludovic.

> **KEY-329** : Register lead-first live DEV. Bundle PH-19.3 deja verifie phase BUILD-CLIENT-DEV-01 (register-lead-shell + register-reassurance-panel + register-confirm-plan + CTAs "Continuer vers le plan" / "Confirmer ce plan et activer" + ReassurancePanel "Ce que KeyBuzz va gerer"). API v3.5.251-register-cro-dev preserve. PROD inchange.

> **KEY-333 (benchmark)** : Signup benchmark live DEV (Gojiberry/BabyLoveGrowth/Taap/Blabla patterns sans copie). QA browser Ludovic confirmera visuellement layout split desktop + ReassurancePanel sticky droite + grille plans cachee first screen.

> **KEY-325 (Clarity)** : Clarity client still absent live DEV (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0). data-clarity-mask 13 source / 26 bundle preserves visibles.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique. params/data IDs ready (data-cta-id + data-plan + data-cycle + data-promo-state) pour futurs hooks analytics sans pollution event. Events ads browser-side preexistants tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tag GHCR v3.5.201 deja pousse phase PUSH-IMAGE-CLIENT-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN apply API DEV (manifest API DEV inchange)
- AUCUN apply Website
- AUCUN changement source Client/API (commits 397687a + 39e332ea deja pousses)
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT

Si necessaire, rollback strict GitOps :

1. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.200-register-cro-uplift-dev (digest sha256:6b199ef2e548...)
2. git add + commit -m "ops(client-dev): ROLLBACK PH-19.3 to v3.5.200"
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
6. Verifier runtime digest = sha256:6b199ef2e548...

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. HTML SSR /register vide en checks bruts (Next.js use client hydration) - QA visuelle browser Ludovic requise pour confirmer lead-first + split layout + ReassurancePanel sticky droite + grille plans cachee first screen + CTAs / data-testid hydratees.
2. Events ads browser-side preexistants - decision KEY-330/KEY-331 a confirmer.
3. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope.
4. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build (iso baseline).
5. Clarity activation client.keybuzz.io reste decision post-QA lead-first.
6. Lead enrichment fields (marketplaces, volume commandes, urgence) : dette documentee pour future API PH-19.4-LEAD-ENRICHMENT.

## VERDICT FINAL

GO APPLY CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD | 8bb6bb6 |
| Client DEV runtime tag | v3.5.201-register-lead-first-dev |
| Client DEV runtime digest | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de |
| Smoke /register | HTTP 200 |
| Smoke API /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD | 3/3 INCHANGE |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-APPLY-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO QA REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

STOP.
