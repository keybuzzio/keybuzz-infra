# PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-BUILD-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-333 (benchmark), KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-BUILD-CLIENT-DEV
> Environnement : DEV build only / aucun push / aucun deploy

## VERDICT

GO BUILD CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

- Client DEV image locale : ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev (ID `64143df05da4`, 280 MB)
- OCI labels KEY-308 5/5 presents (revision `20737fd0aa8ee793ac7b522df6884c394caa5615`, version `v3.5.200-register-cro-uplift-dev`)
- KEY-302 guard PASSE avec build args DEV explicites
- Tag GHCR FREE (manifest unknown pre-push)
- Bundle DEV isolation OK : api-dev.keybuzz.io = 87, api.keybuzz.io = 0
- Patches PH-19.2 confirmes bake : headline + bloc 3 etapes + PlanRecapCard + data-testid + data-cta-id + data-promo-state
- Clarity client NON activee (0 clarity.ms, 0 NEXT_PUBLIC_CLARITY, 0 wrff07upjx)
- 0 nouveau fake event ajoute PH-19.2 (events preexistants src/lib/tracking.ts inchanges)
- Runtime DEV/PROD inchanges
- API hors scope, v3.5.251-register-cro-dev reste candidate valide

Prochaine phrase GO attendue : GO PUSH IMAGE CLIENT REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD local = origin | 20737fd | OK |
| keybuzz-client dirty | tsconfig.tsbuildinfo (cache tsc preexistant) | OK hors scope, build via worktree clean |
| keybuzz-infra HEAD = origin | e82d798 | OK |
| GHCR collision v3.5.200-register-cro-uplift-dev | manifest unknown | tag FREE |
| Worktree clean cree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.2/keybuzz-client at 20737fd detached | OK |

## SOURCE VERIFY PRE-BUILD

| Check source app/register/page.tsx | Resultat | Verdict |
|---|---|---|
| Activez votre cockpit SAV marketplace | 1 | OK |
| Comment ca se passe (commentaire ou bloc) | 1 | OK |
| register-plan-card | 1 | OK |
| register-cycle-toggle | 1 | OK |
| register-plan-recap | 1 | OK |
| data-clarity-mask | 13 | OK preserve |
| data-cta-id | 2 | OK |
| data-promo-state | 1 | OK |
| plan_selected emit unique | 1 | OK KEY-331 preserve |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 | OK Clarity absent |
| KEY-302 sentinels Dockerfile | 3 | OK guard actif |

## TESTS SOURCE PRE-BUILD

| Test | Attendu | Resultat |
|---|---|---|
| npx next lint --file app/register/page.tsx | exit 0, no warnings/errors | OK "No ESLint warnings or errors" |
| npx tsc --noEmit | 0 erreur sur fichier patche | OK app/register/page.tsx 0 erreur (2 erreurs preexistantes .next/types/app/api/debug-env hors scope) |

## BUILD CLIENT DEV

| Param | Valeur |
|---|---|
| Source worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.2/keybuzz-client |
| Commit | 20737fd0aa8ee793ac7b522df6884c394caa5615 |
| Tag | v3.5.200-register-cro-uplift-dev |
| Image | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev |
| Image ID | 64143df05da4 |
| Size | 280 MB |
| Created (UTC) | 2026-05-20T09:51:03Z |
| Build exit code | 0 (KEY-302 guard PASSE) |

Build args DEV (KEY-302 enforcement) :

| Build arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| GIT_COMMIT_SHA | 20737fd0aa8ee793ac7b522df6884c394caa5615 |
| BUILD_TIME | 2026-05-20T09:51:03Z |
| IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION | OCI KEY-308 |

Build args optionnels OMIS (iso v3.5.198/v3.5.199 baseline runtime DEV) :

| Build arg | Statut |
|---|---|
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | omis (iso baseline) |
| NEXT_PUBLIC_META_PIXEL_ID | omis |
| NEXT_PUBLIC_SGTM_URL | omis |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | omis |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | omis (KEY-325 Clarity NON activee) |

OCI labels KEY-308 (5/5) :

| Label | Valeur |
|---|---|
| revision | 20737fd0aa8ee793ac7b522df6884c394caa5615 |
| created | 2026-05-20T09:51:03Z |
| version | v3.5.200-register-cro-uplift-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## VERIFY IMAGE LOCAL

| Check | Attendu | Resultat |
|---|---|---|
| Image ID local | non-empty | 64143df05da4 |
| Size | non-zero | 280 MB |
| OCI labels | 5/5 | OK |

## VERIFY BUNDLE / KEY-302 ISOLATION

DEV isolation API (KEY-263 / KEY-302) :

| Check Client bundle | Attendu | Resultat |
|---|---|---|
| api-dev.keybuzz.io | present | OK 87 |
| api.keybuzz.io (sans -dev) | absent | OK 0 |
| client-dev.keybuzz.io | present | OK 3 |
| client.keybuzz.io (sans -dev, preexistant email logo) | preexistant | 3 (email magic-link template `<img src="https://client.keybuzz.io/branding/keybuzz-icon.png" ...>`, NON modifie par PH-19.2, deja documente phase BUILD-DEV-01 PH-19.1) |

Register PH-19.2 patches bake :

| Check | Attendu | Resultat |
|---|---|---|
| Activez votre cockpit SAV marketplace | present | OK 2 (SSR + chunk) |
| Choisissez votre plan (etape 1 + h2) | present | OK 6 |
| Creez votre espace (etape 2) | present | OK 2 |
| Lancez l essai 14 jours (etape 3) | present | OK 2 (`Lancez l'essai 14 jours` apostrophe HTML decoded) |
| essai 14 jours (suffix) | present | OK 6 |
| register-how-it-works (data-testid bloc 3 etapes) | present | OK 2 |
| register-plan-card | present | OK 2 |
| register-cycle-toggle | present | OK 2 |
| register-plan-recap | present | OK 2 |
| data-clarity-mask | preserve | OK 26 (13 source x 2 SSR+chunk) |
| data-cta-id register_plan_select | present | OK 2 |
| data-cta-id register_cycle_toggle | present | OK 2 |
| data-promo-state | present | OK 2 |
| plan_selected (preserve unique source) | present | OK 4 (SSR + chunks references) |

Clarity NON activee :

| Check | Attendu | Resultat |
|---|---|---|
| clarity.ms | 0 | OK 0 |
| NEXT_PUBLIC_CLARITY | 0 | OK 0 |
| wrff07upjx (project ID website) | 0 dans Client | OK 0 |

No fake events (events existants src/lib/tracking.ts inchanges) :

| Pattern | Occurrences bundle | Source | Statut PH-19.2 |
|---|---|---|---|
| Lead (large match minified) | 96 | trackSignupStart src/lib/tracking.ts | preexistant, NON modifie PH-19.2 |
| SubmitForm | 2 | trackSignupStart src/lib/tracking.ts | preexistant |
| InitiateCheckout | 4 | trackBeginCheckout src/lib/tracking.ts | preexistant |
| CompleteRegistration | 2 | trackSignupComplete src/lib/tracking.ts | preexistant |
| AW-XXXXXXXXXX direct | 0 | n/a | OK |

Note KEY-330 : events ads browser-side preexistants - decision retrait/migration server-side a prendre (hors scope PH-19.2).

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.199-register-cro-dev (PH-19.1) | INCHANGE - **obsolete source PH-19.2** (sera remplace par v3.5.200 apres push + apply) |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE - candidate API valide (pas de rebuild API PH-19.2) |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker push GHCR | NON execute |
| kubectl apply | NON execute |
| kubectl set / patch / edit | NON execute |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun (rapport docs PH restera untracked apres mv) |
| Modification source Client | aucune |

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-329 (primary)** : Image Client DEV build local ready. Tag ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev (ID 64143df05da4, 280 MB). OCI labels KEY-308 5/5 (revision 20737fd). KEY-302 guard PASSE. Bundle verifie : Activez votre cockpit SAV marketplace + bloc 3 etapes (Choisissez plan / Creez espace / Lancez essai) + PlanRecapCard + data-testid + data-cta-id confirmes. API v3.5.251 candidate unchanged. STOP avant push GHCR.

> **KEY-333 (benchmark)** : Benchmark uplift maintenant bake dans image locale Client DEV v3.5.200. Headline + bloc 3 etapes + PlanRecapCard design plus marque + 8 data-testid + 2 data-cta-id confirmes bundle. Aucune copie d assets/textes/temoignages des references (BabyLoveGrowth/Taap/Blabla/Gojiberry). Aucune promesse produit fictive.

> **KEY-325 (Clarity)** : Clarity client absent du bundle DEV v3.5.200 (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0). data-clarity-mask 26 occurrences bake (13 source x 2 SSR + chunks).

> **KEY-330 / KEY-331** : No fake events ajoutes PH-19.2 (0 nouveau fake event dans diff source). plan_selected preserve unique dans handleSelectPlan. Events ads browser-side preexistants src/lib/tracking.ts (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) inchanges, decision retrait/migration server-side a prendre.

## CONFIRMATIONS NO PUSH / NO DEPLOY

- AUCUN docker push GHCR
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV/PROD
- AUCUN changement manifest infra
- AUCUN changement source Client (build from worktree detached 20737fd, repo principal inchange)
- AUCUN changement API (v3.5.251 candidate valide)
- AUCUN changement Website / Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN secret expose dans logs / labels / rapport
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK

Phase build local only, pas de runtime impact :

- Suppression image locale : docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev
- Suppression worktree : (cd /opt/keybuzz/keybuzz-client && git worktree remove /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.2/keybuzz-client)
- Aucune action runtime requise (v3.5.199 reste actif jusqu a apply ulterieur)

INTERDIT : git reset --hard, git clean.

## GAPS

1. Client DEV runtime v3.5.199-register-cro-dev reste actif jusqu a push GHCR + apply DEV de v3.5.200.
2. API DEV v3.5.251-register-cro-dev candidate valide, pas de rebuild API.
3. Email logo `client.keybuzz.io/branding/keybuzz-icon.png` reste hardcoded dans email magic-link template - preexistant phase BUILD-DEV-01 PH-19.1, hors scope PH-19.2.
4. Marketing tracking IDs (GA4 / Meta / TikTok / SGTM) omis du build (iso baseline runtime DEV v3.5.198/v3.5.199 qui les omettait).
5. Events ads browser-side preexistants - decision KEY-330/KEY-331 a prendre.
6. tsconfig.tsbuildinfo cache local Client : artefact tsc, jamais commit.

## VERDICT FINAL

GO BUILD CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

| Composant | Statut |
|---|---|
| Image | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev |
| Image ID | 64143df05da4 |
| Size | 280 MB |
| OCI labels KEY-308 | 5/5 (revision 20737fd, version v3.5.200-register-cro-uplift-dev, created 2026-05-20T09:51:03Z) |
| KEY-302 guard | PASSE |
| Bundle isolation API DEV | OK (api-dev=87, api.keybuzz.io=0) |
| Patches PH-19.2 confirmes | OK (headline + 3 etapes + PlanRecapCard + data-testid + data-cta-id + data-promo-state) |
| Clarity NON activee | OK (0/0/0) |
| 0 nouveau fake event | OK |
| Runtime preserve | DEV/PROD/Website inchanges |
| GHCR tag | manifest unknown (FREE) |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-BUILD-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO PUSH IMAGE CLIENT REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

STOP.
