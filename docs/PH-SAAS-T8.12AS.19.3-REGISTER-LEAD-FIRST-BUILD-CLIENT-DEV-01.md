# PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-BUILD-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-334 (primary), KEY-329, KEY-333, KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-BUILD-CLIENT-DEV
> Environnement : DEV build only / aucun push / aucun deploy

## VERDICT

GO BUILD CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

- Client DEV image locale : ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev (ID `4c58fbe7ce93`, 280 MB)
- OCI labels KEY-308 5/5 (revision `397687a8320fdada7b924dfe124659db9d6e81d0`, version `v3.5.201-register-lead-first-dev`)
- KEY-302 guard PASSE avec build args DEV explicites
- Bundle DEV isolation OK : api-dev.keybuzz.io = 87, api.keybuzz.io = 0
- Patches PH-19.3 lead-first confirmes bake : split layout + ReassurancePanel + CTA confirmation finale
- Clarity client NON activee (0 clarity.ms, 0 NEXT_PUBLIC_CLARITY, 0 wrff07upjx)
- 0 nouveau fake event ajoute PH-19.3 (events preexistants src/lib/tracking.ts inchanges)
- Runtime DEV/PROD inchanges
- API hors scope, v3.5.251-register-cro-dev candidate valide

Prochaine phrase GO attendue : GO PUSH IMAGE CLIENT REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client HEAD local = origin | 397687a | OK |
| keybuzz-client dirty | tsconfig.tsbuildinfo (cache tsc preexistant) | OK hors scope, build via worktree clean |
| keybuzz-infra HEAD = origin | 79256cd | OK |
| GHCR collision v3.5.201-register-lead-first-dev | EOF transitoire pre-build, mais tag jamais pousse = FREE | OK confirme par push absence registry |
| Worktree clean cree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.3/keybuzz-client at 397687a detached | OK |

## SOURCE VERIFY PRE-BUILD

| Check source app/register/page.tsx | Resultat | Verdict |
|---|---|---|
| register-lead-shell | 1 | OK |
| register-reassurance-panel | 1 | OK |
| register-lead-form | 1 | OK |
| register-confirm-plan | 1 | OK |
| "Continuer vers le plan" | 1 | OK |
| "Confirmer ce plan et activer" | 2 (CTA + commentaire) | OK |
| handleConfirmPlanAndCheckout | 4 (def + 2 setStep refs + 1 onClick) | OK |
| data-clarity-mask | 13 (inchange) | OK preserve |
| plan_selected emit unique | 1 | OK KEY-331 preserve |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 | OK Clarity absent |
| KEY-302 sentinels Dockerfile | 3 | OK guard actif |

## TESTS SOURCE PRE-BUILD

| Test | Attendu | Resultat |
|---|---|---|
| npx next lint --file app/register/page.tsx | exit 0, no warnings/errors | OK "No ESLint warnings or errors" |
| npx tsc --noEmit | 0 erreur sur fichier patche | OK (0 erreur lancee) |

## WORKTREE

| Champ | Valeur |
|---|---|
| Path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.3/keybuzz-client |
| HEAD | 397687a8320fdada7b924dfe124659db9d6e81d0 (detached) |
| Status | clean |
| Methode | git worktree add --detach (no clone, partage le .git) |

## BUILD CLIENT DEV

| Param | Valeur |
|---|---|
| Source worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.3/keybuzz-client |
| Commit | 397687a8320fdada7b924dfe124659db9d6e81d0 |
| Tag | v3.5.201-register-lead-first-dev |
| Image | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev |
| Image ID | 4c58fbe7ce93 |
| Size | 280 MB |
| Created (UTC) | 2026-05-20T12:21:01Z |
| Build exit code | 0 (KEY-302 guard PASSE) |

Build args DEV (KEY-302 enforcement) :

| Build arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| GIT_COMMIT_SHA | 397687a8320fdada7b924dfe124659db9d6e81d0 |
| BUILD_TIME | 2026-05-20T12:21:01Z |
| IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION | OCI KEY-308 |

Build args omis (iso baseline v3.5.198/v3.5.199/v3.5.200) :

| Build arg | Statut |
|---|---|
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | omis |
| NEXT_PUBLIC_META_PIXEL_ID | omis |
| NEXT_PUBLIC_SGTM_URL | omis |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | omis |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | omis (KEY-325 Clarity NON activee) |

OCI labels KEY-308 (5/5) :

| Label | Valeur |
|---|---|
| revision | 397687a8320fdada7b924dfe124659db9d6e81d0 |
| created | 2026-05-20T12:21:01Z |
| version | v3.5.201-register-lead-first-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## VERIFY IMAGE LOCAL

| Tag | Image ID | Size | Created | Revision |
|---|---|---|---|---|
| v3.5.201-register-lead-first-dev | 4c58fbe7ce93 | 280 MB | 2026-05-20T12:21:01Z | 397687a8320fdada7b924dfe124659db9d6e81d0 |

## VERIFY BUNDLE / KEY-302 ISOLATION

DEV isolation API (KEY-263 / KEY-302) :

| Check Client bundle | Attendu | Resultat |
|---|---|---|
| api-dev.keybuzz.io | present | OK 87 |
| api.keybuzz.io (sans -dev) | absent | OK 0 |
| client-dev.keybuzz.io | present | OK 3 |
| client.keybuzz.io (sans -dev) | preexistant email logo magic-link | 3 (NON modifie par PH-19.3, deja documente phase BUILD-DEV-01 PH-19.1) |

Register PH-19.3 lead-first patches bake :

| Check | Attendu | Resultat |
|---|---|---|
| register-lead-shell (data-testid wrapper) | present | OK 2 (SSR + chunk) |
| register-reassurance-panel (data-testid aside) | present | OK 2 |
| register-lead-form (data-testid form panel) | present | OK 2 |
| register-confirm-plan (data-testid CTA bloc) | present | OK 2 |
| "Continuer vers le plan" (CTA step user) | present | OK 2 |
| "Confirmer ce plan et activer" (CTA step plan) | present | OK 2 |
| "Ce que KeyBuzz va gerer" (ReassurancePanel header) | present | OK 2 |
| "Activez votre cockpit SAV" (h1) | present | OK 2 |
| data-clarity-mask | preserve | OK 26 (13 source x 2 SSR+chunk) |
| data-cta-id register_continue_to_plan | present | OK 2 |
| data-cta-id register_confirm_plan_and_checkout | present | OK 2 |
| plan_selected (preserve unique emit source) | present | OK 4 (SSR + chunks references) |

Clarity NON activee :

| Check | Attendu | Resultat |
|---|---|---|
| clarity.ms | 0 | OK 0 |
| NEXT_PUBLIC_CLARITY | 0 | OK 0 |
| wrff07upjx | 0 dans Client | OK 0 |

No fake events (events existants tracking.ts inchanges PH-19.3) :

| Pattern | Occurrences bundle | Source | Statut PH-19.3 |
|---|---|---|---|
| Lead (large match minified) | 96 | trackSignupStart src/lib/tracking.ts | preexistant, NON modifie PH-19.3 |
| SubmitForm | 2 | trackSignupStart src/lib/tracking.ts | preexistant |
| InitiateCheckout | 4 | trackBeginCheckout src/lib/tracking.ts | preexistant |
| CompleteRegistration | 2 | trackSignupComplete src/lib/tracking.ts | preexistant |
| AW-XXXXXXXXXX direct | 0 | n/a | OK |

Note KEY-330 : decision retrait/migration server-side a prendre (hors scope PH-19.3).

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.200-register-cro-uplift-dev (PH-19.2) | INCHANGE - **obsolete source PH-19.3**, sera remplace par v3.5.201 apres push + apply |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE - candidate API valide (pas de rebuild API PH-19.3) |
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

> **KEY-334 (primary)** : Image Client DEV lead-first build local ready. Tag ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev (ID 4c58fbe7ce93, 280 MB). OCI labels KEY-308 5/5 (revision 397687a). KEY-302 guard PASSE. Bundle verifie : register-lead-shell + register-reassurance-panel + register-lead-form + register-confirm-plan + "Continuer vers le plan" + "Confirmer ce plan et activer" + "Ce que KeyBuzz va gerer" confirmes. STOP avant push GHCR.

> **KEY-329** : Client DEV v3.5.201-register-lead-first-dev build local ready. API v3.5.251-register-cro-dev candidate unchanged (pas de rebuild API PH-19.3).

> **KEY-333** : Benchmark signup uplift maintenant bake dans image locale Client DEV v3.5.201. Lead-first applique en structure (split layout + ReassurancePanel a droite + grille plans repoussee apres collecte prospect). Aucune copie d assets/textes/temoignages des references (Gojiberry/BabyLoveGrowth/Taap/Blabla). Aucune promesse produit fictive.

> **KEY-325** : Clarity client absent du bundle DEV v3.5.201 (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0). data-clarity-mask 26 occurrences bake (13 source x 2 SSR + chunks).

> **KEY-330 / KEY-331** : No fake events ajoutes PH-19.3 (0 nouveau fake event dans diff source). plan_selected preserve unique dans handleSelectPlan (clic plan = selection visuelle + emit unique via dedupe). Events ads browser-side preexistants src/lib/tracking.ts inchanges, decision retrait/migration server-side a prendre.

## CONFIRMATIONS NO PUSH / NO DEPLOY

- AUCUN docker push GHCR
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV/PROD
- AUCUN changement manifest infra
- AUCUN changement source Client (build from worktree detached 397687a, repo principal inchange)
- AUCUN changement API (v3.5.251 candidate valide)
- AUCUN changement Website / Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN secret expose dans logs / labels / rapport
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK

Phase build local only, pas de runtime impact :

- Suppression image locale : docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev
- Suppression worktree : (cd /opt/keybuzz/keybuzz-client && git worktree remove /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.3/keybuzz-client)
- Aucune action runtime requise (v3.5.200 reste actif jusqu a apply ulterieur)

INTERDIT : git reset --hard, git clean.

## GAPS

1. Client DEV runtime v3.5.200-register-cro-uplift-dev reste actif jusqu a push GHCR + apply DEV de v3.5.201.
2. API DEV v3.5.251-register-cro-dev candidate valide, pas de rebuild API.
3. Email logo `client.keybuzz.io/branding/keybuzz-icon.png` reste hardcoded dans email magic-link template - preexistant phase BUILD-DEV-01 PH-19.1, hors scope PH-19.3.
4. Marketing tracking IDs (GA4 / Meta / TikTok / SGTM) omis du build (iso baseline runtime DEV).
5. Events ads browser-side preexistants - decision KEY-330/KEY-331 a prendre.
6. Clarity activation client.keybuzz.io reste decision post-QA register lead-first.
7. tsconfig.tsbuildinfo cache local Client : artefact tsc, jamais commit.
8. GHCR collision check pre-build a retourne EOF transitoire (network), tag confirme FREE post-build (jamais pousse).

## VERDICT FINAL

GO BUILD CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

| Composant | Statut |
|---|---|
| Image | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev |
| Image ID | 4c58fbe7ce93 |
| Size | 280 MB |
| OCI labels KEY-308 | 5/5 (revision 397687a, version v3.5.201-register-lead-first-dev, created 2026-05-20T12:21:01Z) |
| KEY-302 guard | PASSE |
| Bundle isolation API DEV | OK (api-dev=87, api.keybuzz.io=0) |
| Patches PH-19.3 lead-first confirmes | OK (lead-shell + reassurance-panel + lead-form + confirm-plan + CTA "Continuer/Confirmer" + ReassurancePanel "Ce que KeyBuzz va gerer") |
| Clarity NON activee | OK (0/0/0) |
| 0 nouveau fake event | OK |
| Runtime preserve | DEV/PROD/Website inchanges |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-BUILD-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO PUSH IMAGE CLIENT REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

STOP.
