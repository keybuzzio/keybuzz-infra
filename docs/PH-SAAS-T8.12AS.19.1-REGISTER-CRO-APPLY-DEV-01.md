# PH-SAAS-T8.12AS.19.1-REGISTER-CRO-APPLY-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-331, KEY-332, KEY-325, KEY-330
> Phase : PH-SAAS-T8.12AS.19.1-REGISTER-CRO-APPLY-DEV-01
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

- keybuzz-infra HEAD : `ef75ebc` (ops(register-dev): deploy PH-SAAS-T8.12AS.19.1 images)
- API DEV runtime : `v3.5.251-register-cro-dev` digest `sha256:a05e9b83d3d7a48fd261b37eaa4533ea4d55c96eadfd1fca31fb0e6f28b8706a` (pod xq9ln Ready 0 restarts)
- Client DEV runtime : `v3.5.199-register-cro-dev` digest `sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c` (pod vzpf2 Ready 0 restarts)
- Smoke /register HTTP 200 ; API /health HTTP 200 ; BFF /api/funnel/event HTTP 201 + persiste
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH

Prochaine phrase GO attendue : GO QA REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | 6bf9bbb | OK |
| keybuzz-infra status pre | 2 rapports PH untracked | OK |
| GHCR api digest expected | sha256:a05e9b83d3d7a48f... | OK pulled-back match |
| GHCR client digest expected | sha256:969558287b908ab4... | OK pulled-back match |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image avant | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-prod | OK |
| keybuzz-client | v3.5.198-debug-env-disabled-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | OK |

## MANIFESTS MODIFIES

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml (l.321) | image v3.5.250-ad-spend-sync-all-dev | image v3.5.251-register-cro-dev | 1 ligne (image + commentaire rollback/digest) |
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.198-debug-env-disabled-dev | image v3.5.199-register-cro-dev | 1 ligne (image + commentaire rollback/digest) |

Commentaires manifest inclus :
- API : PH-SAAS-T8.12AS.19.1-REGISTER-CRO-APPLY-DEV (2026-05-20), commit 39e332ea, KEY-332 fix tenant_created post-COMMIT, rollback v3.5.250-ad-spend-sync-all-dev (digest sha256:8ee7ebad...), digest sha256:a05e9b83...
- Client : PH-SAAS-T8.12AS.19.1-REGISTER-CRO-APPLY-DEV (2026-05-20), commit 1b29903, KEY-329 PlanRecapCard + KEY-331 plan_selected + KEY-325 data-clarity-mask (Clarity NON activee), rollback v3.5.198-debug-env-disabled-dev (digest sha256:8a2df627...), digest sha256:969558...

## DRY-RUN SERVER

| Manifest | kubectl apply --dry-run=server |
|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | deployment.apps/keybuzz-api configured (server dry run) |
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files ajoutes (4) | k8s/keybuzz-api-dev/deployment.yaml (M), k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-SAAS-T8.12AS.19.1-REGISTER-CRO-BUILD-DEV-01.md (A), docs/PH-SAAS-T8.12AS.19.1-REGISTER-CRO-PUSH-IMAGE-DEV-01.md (A) |
| commit hash | ef75ebc |
| commit title | ops(register-dev): deploy PH-SAAS-T8.12AS.19.1 images |
| insertions/deletions | +445 / -2 |
| push exit | 0 |
| origin HEAD post-push | ef75ebc (6bf9bbb -> ef75ebc main -> main) |

## APPLY DEV

| Etape | Resultat |
|---|---|
| kubectl apply api-dev | deployment.apps/keybuzz-api configured |
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status api-dev | successfully rolled out (timeout 300s) |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api DEV | v3.5.251-register-cro-dev | v3.5.251-register-cro-dev | sha256:a05e9b83d3d7a48fd... | 1/1 (xq9ln) | 0 | OK |
| keybuzz-client DEV | v3.5.199-register-cro-dev | v3.5.199-register-cro-dev | sha256:969558287b908ab4... | 1/1 (vzpf2) | 0 | OK |

Manifest tag = runtime tag = digest GHCR : congruent strict.

## SMOKE DEV

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |
| https://client-dev.keybuzz.io/api/funnel/event (POST funnel_id=test-smoke-PH-19.1 event_name=register_started) | POST | HTTP 201, persiste en DB (id=9530841c-9e83-40a9-ba6d-365f9cd2a8f9) | OK BFF + API funnel chain operationnel |

Note HTML SSR : la page /register est rendue via `use client` Next.js hydration cote browser - HTML retourne est le shell client (9188 bytes, title=KeyBuzz Client Portal), les chunks contiennent les composants register (PlanRecapCard, data-clarity-mask, plan_selected) verifies pre-deploy dans la phase BUILD-DEV-01. QA browser Ludovic confirmera visuellement le rendu hydrate.

## NON-REGRESSION PROD

| Service | Image PROD | Ready | Verdict |
|---|---|---|---|
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

- `plan_selected` interne corrige (KEY-331) emis dans handleSelectPlan source (verifie bundle BUILD-DEV-01).
- `tenant_created` (KEY-332) emis post-COMMIT API : non-bloquant, verifie dist BUILD-DEV-01.
- `data-clarity-mask` 13 attributs source / 26 occurrences bundle - Clarity NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0).
- Events ads browser-side preexistants src/lib/tracking.ts (trackSignupStart Meta Lead + TikTok SubmitForm, trackSignupComplete Meta CompleteRegistration, trackBeginCheckout Meta+TikTok InitiateCheckout) inchanges, NON ajoutes par 1b29903. Decision KEY-330 a prendre avant retrait/migration server-side.
- 0 AW-XXXXXXXXXX direct.

## LINEAR BROUILLONS (NON postes, token hors-chat)

> KEY-329 (primary) : DEV applied. Infra commit ef75ebc. API DEV v3.5.251-register-cro-dev digest sha256:a05e9b83... runtime OK. Client DEV v3.5.199-register-cro-dev digest sha256:969558... runtime OK. Smoke /register HTTP 200 + API /health 200 + BFF funnel/event 201 (event persiste DB). PROD inchange. STOP avant build PROD.

> KEY-331 : plan_selected DEV runtime emis dans handleSelectPlan (bundle pre-deploy verifie). Bundle contient plan_selected x4 occurrences (SSR + chunks). QA Ludovic browser DEV pour valider declenchement reel cote DevTools Network /api/funnel/event POST event_name=plan_selected au clic plan.

> KEY-332 : API DEV runtime v3.5.251 contient tenant_created emit post-COMMIT (verifie dist BUILD-DEV-01). Test runtime tenant_created requiert creation tenant (non-fake) - QA Ludovic ou test integration ulterieur.

> KEY-325 : Clarity client.keybuzz.io toujours NON activee. data-clarity-mask 26 occurrences bundle. Aucun script clarity.ms, aucun NEXT_PUBLIC_CLARITY_PROJECT_ID. Quand Ludovic decidera d activer Clarity, masques deja en place.

> KEY-330 : No fake event ajoute par la phase. Events ads browser-side preexistants documentes BUILD-DEV-01. Decision taxonomie + retrait/migration server-side a prendre.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tags GHCR deja pousses en phase PUSH-IMAGE-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN changement source API/Client (commits 39e332ea + 1b29903 deja pousses)
- AUCUN changement Website / Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps

Si necessaire, rollback strict GitOps (PAS de kubectl set image) :

1. Editer k8s/keybuzz-api-dev/deployment.yaml -> image v3.5.250-ad-spend-sync-all-dev (digest sha256:8ee7ebad...)
2. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.198-debug-env-disabled-dev (digest sha256:8a2df627...)
3. git add + commit -m "ops(register-dev): ROLLBACK PH-SAAS-T8.12AS.19.1 to v3.5.250/v3.5.198"
4. git push origin main
5. kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
6. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
7. kubectl rollout status timeout=300s pour chaque

INTERDIT : git reset --hard, git clean.

## GAPS

1. HTML SSR /register vide en checks bruts car Next.js use client hydration : QA visuelle browser Ludovic requise pour confirmer PlanRecapCard, plan_selected (DevTools Network), data-clarity-mask sur inputs.
2. Test runtime API tenant_created requiert creation tenant DB : non-fake, ulterieurement via QA Ludovic ou test integration.
3. Events ads browser-side (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) restent presents : decision KEY-330 / KEY-331 a confirmer.
4. Marketing tracking IDs (GA4 / Meta / TikTok / SGTM) omis du build args DEV : iso v3.5.198 actuel, GA4 DEV optionnel future activation possible via rebuild + --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG.
5. client.keybuzz.io literal 3 occurrences dans bundle (email logo magic-link template) preexistant phase BUILD-DEV-01, non scope.

## VERDICT FINAL

GO APPLY REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

- keybuzz-infra HEAD : ef75ebc
- API DEV runtime tag + digest : v3.5.251-register-cro-dev + sha256:a05e9b83d3d7a48fd261b37eaa4533ea4d55c96eadfd1fca31fb0e6f28b8706a (Ready 1/1)
- Client DEV runtime tag + digest : v3.5.199-register-cro-dev + sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c (Ready 1/1)
- Smoke : /register HTTP 200 + API /health 200 + BFF funnel HTTP 201 (event persiste)
- PROD inchange (3/3)
- NO BUILD
- NO DOCKER PUSH

Prochaine phrase GO attendue :

GO QA REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

STOP.
