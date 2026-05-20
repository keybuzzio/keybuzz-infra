# PH-SAAS-T8.12AS.19.1-REGISTER-CRO-BUILD-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-331, KEY-332, KEY-325, KEY-330
> Phase : PH-SAAS-T8.12AS.19.1-REGISTER-CRO-BUILD-DEV-01
> Environnement : DEV build only / aucun push / aucun deploy

## VERDICT

GO BUILD REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

- API DEV image locale : ghcr.io/keybuzzio/keybuzz-api:v3.5.251-register-cro-dev (ID 85d1ef9f2e84, 343 MB)
- Client DEV image locale : ghcr.io/keybuzzio/keybuzz-client:v3.5.199-register-cro-dev (ID f4dae38ff884, 280 MB)
- OCI labels KEY-308 5/5 sur chacune.
- Tags GHCR : manifest unknown (FREE), aucun push.
- Bundle DEV isolation OK : api-dev.keybuzz.io = 87 occurrences ; api.keybuzz.io = 0.
- patch API tenant_created confirme dans dist (post-COMMIT chemin succes, non-bloquant).
- patch Client PlanRecapCard + plan_selected + data-clarity-mask confirmes dans bundle.
- Clarity client NON activee (clarity.ms = 0, NEXT_PUBLIC_CLARITY = 0, wrff07upjx = 0).
- Runtime DEV/PROD inchanges (6/6 deployments preserve).
- Prochaine phrase GO attendue : GO PUSH IMAGE REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-api HEAD local = origin | 39e332ea | OK |
| keybuzz-client HEAD local = origin | 1b29903 | OK |
| keybuzz-infra HEAD local = origin | 6bf9bbb | OK |
| Worktree principal API dirty | dist/*.js deletes preexistants | hors scope, NOT used pour build |
| Worktree principal Client dirty | tsconfig.tsbuildinfo cache | hors scope, NOT used pour build |
| GHCR collision API v3.5.251-register-cro-dev | manifest unknown | tag FREE |
| GHCR collision Client v3.5.199-register-cro-dev | manifest unknown | tag FREE |

## SOURCES DE BUILD PROPRES (worktrees detached)

| Repo | Path worktree | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-api | 39e332eaa49a53433f403742837e56a75dda49cc | clean | OK |
| keybuzz-client | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-client | 1b29903db0a6544f88c9050618d7fc75237f320c | clean | OK |

Worktrees crees via git worktree add (detached HEAD). Aucun git reset --hard, aucun git clean.

## AUDIT SOURCE PRE-BUILD

| Repo | Check | Attendu | Resultat |
|---|---|---|---|
| api worktree | tenant_created in catch (l.752-756) | 0 | OK 0 |
| api worktree | tenant_created post-COMMIT | 1 emit | OK 1 |
| api worktree | emitFunnelEvent non-bloquant try/catch | present | OK |
| api worktree | ON CONFLICT (funnel_id, event_name) DO NOTHING | present | OK |
| client worktree | plan_selected dans handleSelectPlan | 1 | OK 1 |
| client worktree | plan_selected dans "Utiliser un autre email" | 0 | OK 0 |
| client worktree | PlanRecapCard defini + 4 usages | 1 + 4 | OK |
| client worktree | data-clarity-mask | 13 | OK 13 |
| client worktree | clarity.ms | 0 | OK 0 |
| client worktree | NEXT_PUBLIC_CLARITY | 0 | OK 0 |
| client worktree | promo, _gl, marketing_owner_tenant_id | preserves | OK |

## BUILD API DEV

| Param | Valeur |
|---|---|
| Source worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-api |
| Commit | 39e332eaa49a53433f403742837e56a75dda49cc |
| Tag | v3.5.251-register-cro-dev |
| Image | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-register-cro-dev |
| Image ID | 85d1ef9f2e84 |
| Size | 343 MB |
| Created (UTC) | 2026-05-20T06:58:49Z |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Exit code | 0 |

OCI labels KEY-308 (5/5) :

| Label | Valeur |
|---|---|
| revision | 39e332eaa49a53433f403742837e56a75dda49cc |
| created | 2026-05-20T06:58:49Z |
| version | v3.5.251-register-cro-dev |
| source | https://github.com/keybuzzio/keybuzz-api |
| title | keybuzz-api |

## BUILD CLIENT DEV

| Param | Valeur |
|---|---|
| Source worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-client |
| Commit | 1b29903db0a6544f88c9050618d7fc75237f320c |
| Tag | v3.5.199-register-cro-dev |
| Image | ghcr.io/keybuzzio/keybuzz-client:v3.5.199-register-cro-dev |
| Image ID | f4dae38ff884 |
| Size | 280 MB |
| Created (UTC) | 2026-05-20T07:00:12Z |
| Exit code | 0 (KEY-302 guard PASSE) |

Build args critiques DEV (KEY-302 enforcement) :

| Build arg | Valeur | Source |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | KEY-302 sentinel obligatoire |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | KEY-302 sentinel obligatoire |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | KEY-302 sentinel obligatoire |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | Dockerfile default explicite |
| GIT_COMMIT_SHA | 1b29903... | traceability |
| BUILD_TIME | 2026-05-20T07:00:12Z | traceability |
| IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION | (KEY-308) | OCI labels |

Build args optionnels OMIS (iso v3.5.198 actuel runtime DEV) :

| Build arg | Statut | Justification |
|---|---|---|
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | omis | Bundle v3.5.198 runtime DEV = 0 occurrence GA4 bake : iso conserve, pas de nouvelle activation cette phase |
| NEXT_PUBLIC_META_PIXEL_ID | omis | idem |
| NEXT_PUBLIC_SGTM_URL | omis | idem |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | omis | idem |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | omis | KEY-325 : Clarity NON activee cette phase, mask DOM only |

OCI labels KEY-308 (5/5) :

| Label | Valeur |
|---|---|
| revision | 1b29903db0a6544f88c9050618d7fc75237f320c |
| created | 2026-05-20T07:00:12Z |
| version | v3.5.199-register-cro-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## VERIFY IMAGE API

| Check API image | Resultat |
|---|---|
| dist/modules/auth/tenant-context-routes.js existe | OK |
| tenant_created compte dans tenant-context-routes.js | 2 (commentaire + emit) |
| Bloc emitFunnelEvent('tenant_created') apres COMMIT (chemin succes) | confirme dans dist |
| Bloc absent du catch attribution | confirme |
| emitFunnelEvent non-bloquant (try/catch dans funnel/routes.js) | confirme dans dist |
| Aucun secret dans labels | OK (5 labels OCI uniquement) |

## VERIFY IMAGE CLIENT / BUNDLE

DEV isolation API (KEY-263 / KEY-302) :

| Check Client bundle | Attendu | Resultat |
|---|---|---|
| api-dev.keybuzz.io | present | OK 87 |
| api.keybuzz.io (sans -dev) | absent | OK 0 |
| client-dev.keybuzz.io | present | OK 3 |

Register patch :

| Check | Attendu | Resultat |
|---|---|---|
| plan_selected | present | OK 4 (bundle + chunk + server) |
| data-clarity-mask | 13 attributs source | OK 26 (SSR + chunk dupliques) |
| PlanRecapCard textes stables - "Votre selection" | present | OK 2 |
| PlanRecapCard textes stables - "Connexion Amazon via OAuth officiel" | present | OK 2 |
| PlanRecapCard textes stables - "Essai gratuit 14 jours - sans engagement" | present | OK 2 |
| Utiliser un autre email | preserve | OK 12 (label dans login + register, ne contient plus emit) |

Clarity :

| Check | Attendu | Resultat |
|---|---|---|
| clarity.ms script | absent | OK 0 |
| NEXT_PUBLIC_CLARITY | absent | OK 0 |
| wrff07upjx (project ID website) | absent du client | OK 0 |

Attribution preservee :

| Check | Resultat |
|---|---|
| promo | 4 occurrences |
| _gl | 32 occurrences |
| marketing_owner_tenant_id | 7 occurrences |

No fake events (events existants src/lib/tracking.ts, NON ajoutes par cette phase) :

| Pattern | Occurrences bundle | Source | Statut |
|---|---|---|---|
| Lead (fbq track) | 96 (large match minified) | trackSignupStart src/lib/tracking.ts ligne 73 | preexistant |
| SubmitForm | 2 | trackSignupStart src/lib/tracking.ts ligne 74 | preexistant |
| InitiateCheckout | 4 | trackBeginCheckout src/lib/tracking.ts | preexistant |
| CompleteRegistration | 2 | trackSignupComplete src/lib/tracking.ts | preexistant |
| AW-XXXXXXXXXX direct | 0 | n/a | OK |

Note KEY-330 : ces events ads existaient avant cette phase, ne sont pas ajoutes par 1b29903. Decision produit a prendre pour retrait/migration server-side.

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.198-debug-env-disabled-dev | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.250-ad-spend-sync-all-dev | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker push GHCR | NON execute |
| kubectl apply | NON execute |
| kubectl set / patch / edit | NON execute |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun |

## GAPS

1. client.keybuzz.io literal apparait 3x dans le bundle DEV : il s agit de l URL hardcodee de l image logo dans le template email envoye par app/api/auth/magic/start/route.ts. Preexistant, non modifie par 1b29903. Le bundle v3.5.198 actuel contient les memes 3 occurrences (verification par re-extraction /app complet, vs precedent grep limite a .next/static qui ne couvrait pas .next/server). Non bloquant. Pourrait etre nettoye dans une phase ulterieure (utiliser une URL DEV-specifique pour les emails de magic-link DEV).
2. Marketing tracking IDs (GA4 / Meta / TikTok / SGTM) omis du build args DEV pour iso v3.5.198. Si Ludovic veut activer GA4 DEV (commentaire manifest dit "GA4 activated"), il faudra rebuild avec --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG. Decision a prendre apres validation runtime DEV de cette phase.
3. Events ads browser-side (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) restent presents - decision KEY-330 / KEY-331 a confirmer avant retrait.
4. tsconfig.tsbuildinfo cache local du worktree principal Client : artefact tsc, non scope, jamais commit.
5. dist/*.js deletes preexistants dans worktree principal API : build artefacts trackes mais regenerables, non scope.

## LINEAR BROUILLONS (NON postes, attente GO Ludovic)

> KEY-329 (primary - Register CRO recap) : Build DEV local pret. API ghcr.io/keybuzzio/keybuzz-api:v3.5.251-register-cro-dev (ID 85d1ef9f2e84). Client ghcr.io/keybuzzio/keybuzz-client:v3.5.199-register-cro-dev (ID f4dae38ff884). OCI labels KEY-308 5/5. Bundle DEV verifie : api-dev.keybuzz.io = 87 occurrences, api.keybuzz.io = 0 (isolation), PlanRecapCard recap CRO confirme (Votre selection, Connexion Amazon via OAuth officiel, Essai gratuit 14 jours). STOP avant push GHCR.

> KEY-331 (Register funnel tracking plan_selected) : Bundle Client confirme plan_selected emit dans handleSelectPlan, absent du bouton "Utiliser un autre email". Events ads browser-side preexistants (Meta Lead 96 references minifiees, TikTok SubmitForm 2, Meta+TikTok InitiateCheckout 4, Meta CompleteRegistration 2) documentes, NON modifies par 1b29903, decision retrait/migration server-side a prendre.

> KEY-332 (API funnel tenant_created post-COMMIT) : Image API dist/modules/auth/tenant-context-routes.js confirme emitFunnelEvent('tenant_created') emis APRES await client.query(COMMIT), absent du catch (attrErr). emitFunnelEvent reste non-bloquant (try/catch + UPSERT DO NOTHING dans funnel/routes.js).

> KEY-325 (Clarity client.keybuzz.io apres refonte register) : Image Client confirme NEXT_PUBLIC_CLARITY = 0, clarity.ms = 0, wrff07upjx = 0. data-clarity-mask = 26 occurrences (13 attributs source x 2 SSR + chunk). Clarity client toujours NON activee. Prochaine activation possible via build arg NEXT_PUBLIC_CLARITY_PROJECT_ID dans une phase ulterieure si Ludovic decide.

> KEY-330 (GA4 taxonomy reporting) : Build DEV v3.5.199 omet GA4/Meta/TikTok/SGTM marketing IDs (iso v3.5.198 runtime DEV qui les omettait deja). Decision taxonomie + activation reseaux ads server-side a prendre.

## CONFIRMATIONS NO BUILD / NO PUSH / NO DEPLOY EXTERIEUR

- AUCUN docker push GHCR
- AUCUN kubectl apply / set / patch / edit
- AUCUN git push (worktrees detached, pas de remote interaction)
- AUCUN commit additionnel (rapport docs reste untracked dans keybuzz-infra local)
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN secret expose dans logs / labels / rapport
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion : install-v3 (46.62.171.61) uniquement

## ROLLBACK

Source-only + image locale only :
- Suppression images locales : docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.251-register-cro-dev ghcr.io/keybuzzio/keybuzz-client:v3.5.199-register-cro-dev
- Suppression worktrees : git worktree remove /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-api && git worktree remove /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.1/keybuzz-client (depuis chaque repo parent)
- Aucune action runtime requise.

INTERDIT : git reset --hard, git clean.

## VERDICT FINAL

GO BUILD REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

| Composant | Tag | Image ID | Status |
|---|---|---|---|
| API DEV | v3.5.251-register-cro-dev | 85d1ef9f2e84 | local OK, NOT pushed |
| Client DEV | v3.5.199-register-cro-dev | f4dae38ff884 | local OK, NOT pushed |

- bundle DEV isolation API OK (api-dev=87, api.keybuzz.io=0) ;
- Clarity client non activee ;
- Runtime DEV/PROD inchanges (6/6 deployments preserve) ;
- no docker push, no deploy ;
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.1-REGISTER-CRO-BUILD-DEV-01.md (untracked) ;

Prochaine phrase GO attendue :

GO PUSH IMAGE REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

STOP.
