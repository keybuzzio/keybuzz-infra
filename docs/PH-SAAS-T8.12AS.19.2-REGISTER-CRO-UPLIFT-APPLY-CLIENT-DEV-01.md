# PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-APPLY-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-333 (benchmark), KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-APPLY-CLIENT-DEV
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

- keybuzz-infra HEAD : `7d62687` (ops(client-dev): deploy v3.5.200-register-cro-uplift-dev)
- Client DEV runtime : `v3.5.200-register-cro-uplift-dev` digest `sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18` (pod vw87k Ready 0 restarts)
- API DEV runtime : `v3.5.251-register-cro-dev` (INCHANGE, candidate valide)
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH

Prochaine phrase GO attendue : GO QA REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | e82d798 | OK |
| 2 rapports PH untracked attendus | docs/PH-19.2-BUILD + PUSH-IMAGE | OK |
| GHCR Client v3.5.200 digest expected | sha256:6b199ef2e548... | OK pulled-back match |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image | Verdict |
|---|---|---|---|
| keybuzz-client | v3.5.199-register-cro-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-api | v3.5.251-register-cro-dev | v3.5.250-ad-spend-sync-all-prod | preserve |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | preserve |

## MANIFEST MODIFIE

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.199-register-cro-dev | image v3.5.200-register-cro-uplift-dev | 1 ligne (image + commentaire PH-19.2 + rollback + digest) |

Commentaire manifest :
- phase PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-APPLY-CLIENT-DEV (2026-05-20)
- commit Client 20737fd
- KEY-329 + KEY-333 register CRO benchmark uplift (BabyLoveGrowth/Taap/Blabla/Gojiberry patterns sans copie)
- headline "Activez votre cockpit SAV marketplace" + bloc 3 etapes + PlanRecapCard design plus marque + 8 data-testid + 2 data-cta-id
- KEY-325 data-clarity-mask 13 inputs PII preserves (Clarity NON activee)
- KEY-331 plan_selected preserve unique
- KEY-330 no fake events ajoutes
- rollback v3.5.199-register-cro-dev (digest sha256:969558287b908ab4...)
- new digest sha256:6b199ef2e548...

## ROLLBACK DIGEST EXTRAIT PRE-PATCH

| Tag | Manifest digest GHCR |
|---|---|
| v3.5.199-register-cro-dev (rollback) | sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c |
| v3.5.200-register-cro-uplift-dev (new) | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 |

## DRY-RUN SERVER

| Manifest | Resultat |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files staged (3) | k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-19.2-BUILD-CLIENT-DEV-01.md (A), docs/PH-19.2-PUSH-IMAGE-CLIENT-DEV-01.md (A) |
| commit hash | 7d62687 |
| commit title | ops(client-dev): deploy v3.5.200-register-cro-uplift-dev |
| insertions/deletions | +406 / -1 |
| push exit | 0 |
| origin HEAD post-push | 7d62687 (e82d798 -> 7d62687 main -> main) |

## APPLY CLIENT DEV

| Etape | Resultat |
|---|---|
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client DEV | v3.5.200-register-cro-uplift-dev | v3.5.200-register-cro-uplift-dev | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 | 1/1 (vw87k) | 0 | OK manifest = tag = digest |

## SMOKE DEV /REGISTER

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes (shell client Next.js use-client hydration) | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |

Note SSR : page /register est rendue via use client hydration cote browser - shell HTML 9188 bytes, composants register (PlanRecapCard, data-testid, data-cta-id, data-clarity-mask) sont dans les chunks JS lazy hydrates apres charge. Patterns deja verifies dans le bundle pre-deploy (phase BUILD-CLIENT-DEV-01). QA browser Ludovic confirmera visuellement post-apply.

## API DEV PRESERVE (read-only)

| Cluster | Image | Ready | Verdict |
|---|---|---|---|
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE (candidate valide KEY-332 tenant_created) |

Aucun apply API DEV.

## NON-REGRESSION PROD

| Service | Image PROD | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

Verifie cote source (phase 19.2 source patch + push) et bundle (phase BUILD-CLIENT-DEV-01) :

- plan_selected preserve unique dans handleSelectPlan (KEY-331)
- Pas d event par bouton (data-cta-id register_plan_select_<plan>, register_cycle_toggle + data-plan/cycle/promo-state)
- Boutons identifiables via attributes
- Clarity client toujours NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0)
- Aucune fake review / fake metric / fake chiffre
- Pas d event Lead/Purchase/StartTrial/CompletePayment ajoute par PH-19.2
- Events ads existants src/lib/tracking.ts inchanges - decision retrait/migration server-side KEY-330/KEY-331 reste a prendre

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-329 (primary)** : DEV applied Client v3.5.200-register-cro-uplift-dev. Infra commit 7d62687. Runtime digest sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 pod vw87k Ready. Smoke /register HTTP 200 + API /health 200. API v3.5.251-register-cro-dev preserve (candidate valide). PROD inchange. STOP avant QA/PROD.

> **KEY-333 (benchmark)** : Benchmark uplift live DEV. Bundle PH-19.2 deja verifie phase BUILD-CLIENT-DEV-01 (headline + bloc 3 etapes + PlanRecapCard + data-testid + data-cta-id). QA browser Ludovic confirmera visuellement.

> **KEY-325 (Clarity)** : Clarity client still absent (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0). data-clarity-mask 13 source / 26 bundle preserves.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique. data-cta-id + data-plan + data-cycle + data-promo-state ready pour futurs hooks analytics sans pollution event. Events ads browser-side preexistants tracking.ts inchanges, decision retrait/migration server-side a prendre.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tag GHCR v3.5.200 deja pousse phase PUSH-IMAGE-CLIENT-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN apply API DEV (manifest API DEV inchange)
- AUCUN apply Website
- AUCUN changement source Client/API (commits 20737fd + 39e332ea deja pousses)
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT

Si necessaire, rollback strict GitOps :

1. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.199-register-cro-dev (digest sha256:969558287b908ab4...)
2. git add + commit -m "ops(client-dev): ROLLBACK PH-19.2 to v3.5.199"
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
6. Verifier runtime digest = sha256:969558287b908ab4...

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. HTML SSR /register vide en checks bruts (Next.js use client hydration) - QA visuelle browser Ludovic requise pour confirmer headline + bloc 3 etapes + PlanRecapCard + data-testid hydratees.
2. Events ads browser-side preexistants (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) inchanges - decision KEY-330/KEY-331 a confirmer.
3. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope - hors PH-19.2.
4. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build (iso baseline) - activation GA4 DEV ulterieure si Ludovic le souhaite.
5. Clarity activation client.keybuzz.io reste decision post-QA register.

## VERDICT FINAL

GO APPLY CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD | 7d62687 |
| Client DEV runtime tag | v3.5.200-register-cro-uplift-dev |
| Client DEV runtime digest | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 |
| Smoke /register | HTTP 200 |
| Smoke API /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD | 3/3 INCHANGE |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-APPLY-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO QA REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

STOP.
