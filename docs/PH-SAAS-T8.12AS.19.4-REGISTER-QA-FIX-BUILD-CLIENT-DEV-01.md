# PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-BUILD-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-BUILD-CLIENT-DEV
> Environnement : DEV build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.202-register-qa-fix-dev` construite from-git depuis `d363c38`
- Image ID local : `sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f`
- Size 280 MB
- 5/5 OCI labels KEY-308 presents (revision/created/version/source/title)
- Bundle DEV verifie : 87 `api-dev.keybuzz.io`, **0** `api.keybuzz.io` (KEY-263 OK), patterns PH-19.4 tous presents
- Clarity client toujours non activee (clarity.ms 0 / NEXT_PUBLIC_CLARITY 0 / wrff07upjx 0)
- Aucun fake event (AW- 0, no Lead/Purchase/StartTrial/CompletePayment ajoute)
- Runtime DEV/PROD inchange (6/6)
- AUCUN docker push, AUCUN deploy, AUCUN kubectl

Prochaine phrase GO attendue : GO PUSH IMAGE CLIENT REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local = origin | d363c38 | OK |
| Client dirty | tsconfig.tsbuildinfo (preexistant) | OK hors scope |
| keybuzz-infra HEAD = origin | c7aa9f4 | OK |
| Infra dirty | aucun | OK |

## GHCR COLLISION CHECK

| Tag cible | Try 1 | Try 2 | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-client:v3.5.202-register-qa-fix-dev | manifest unknown | manifest unknown | tag FREE |

## SOURCE COMMIT VERIFY

| Element | Valeur |
|---|---|
| commit hash | d363c38 |
| commit title | fix(register): corrige selection plan et marketing owner invalide |
| files (2) | app/register/page.tsx, src/features/pricing/config.ts |
| selectedPlan === plan.id (source) | 3 occurrences |
| data-selected (source) | 1 |
| aria-pressed (source) | 1 |
| invalid_marketing_owner_tenant_id (source) | 1 |
| ownerCandidate + basePayload | 3 + 3 |
| emitFunnelStep plan_selected count | 1 (unique canonique) |
| config Autopilot badge + recommended | 2 (sur Autopilot) |
| config Pro badge + recommended | 0 (nettoye) |
| Clarity (clarity.ms / NEXT_PUBLIC_CLARITY) | 0 / 0 partout dans app/src |

## WORKTREE BUILD

| Element | Valeur |
|---|---|
| path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.4/keybuzz-client |
| HEAD detached | d363c387af20c26a400613e3a777d542d368eed4 |
| status | clean |
| Dockerfile sentinelles KEY-302 | NEXT_PUBLIC_APP_ENV, NEXT_PUBLIC_API_URL, NEXT_PUBLIC_API_BASE_URL |

## BUILD ARGS

| Build arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | (vide, iso baseline DEV) |
| NEXT_PUBLIC_META_PIXEL_ID | (vide, iso baseline DEV) |
| NEXT_PUBLIC_SGTM_URL | (vide, iso baseline DEV) |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | (vide, iso baseline DEV) |
| GIT_COMMIT_SHA | d363c387af20c26a400613e3a777d542d368eed4 |
| BUILD_TIME | 2026-05-20T13:54:47Z |
| IMAGE_REVISION | d363c387af20c26a400613e3a777d542d368eed4 |
| IMAGE_CREATED | 2026-05-20T13:54:47Z |
| IMAGE_VERSION | v3.5.202-register-qa-fix-dev |

NB : Clarity (NEXT_PUBLIC_CLARITY*) non passe en build arg : preserve l etat baseline (KEY-325 non activation client.keybuzz.io).

## OCI LABELS KEY-308 (5/5 presents)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | d363c387af20c26a400613e3a777d542d368eed4 |
| org.opencontainers.image.created | 2026-05-20T13:54:47Z |
| org.opencontainers.image.version | v3.5.202-register-qa-fix-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## IMAGE LOCALE

| Element | Valeur |
|---|---|
| Repository tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.202-register-qa-fix-dev |
| Image ID | sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f |
| Size | 279997543 bytes (280 MB) |
| Architecture | amd64 |
| OS | linux |
| Created | 2026-05-20T13:57:29Z |
| Source commit | d363c38 |

Aucun push GHCR effectue (NO docker push).

## BUNDLE DEV VERIFICATION

Bundle extrait depuis /app/.next dans /tmp/bundle-v3.5.202 (9.9 MB), shred apres verification.

### Isolation DEV/PROD (KEY-263)

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| api-dev.keybuzz.io | 87 | > 0 (DEV isolation) | OK |
| api.keybuzz.io (sans -dev) | 0 | 0 (pas de PROD leak) | OK |
| client-dev.keybuzz.io | 3 | DEV cookie/origin | OK |
| client.keybuzz.io (sans -dev) | 3 | template email magic-link preexistant hors scope KEY-263 (concerne api uniquement) | OK documente |

### Tunnel lead-first PH-19.3 preserve

| Pattern | Occurrences (attendu 2 = SSR + chunk) | Verdict |
|---|---|---|
| register-lead-shell | 2 | OK |
| register-reassurance-panel | 2 | OK |
| register-confirm-plan | 2 | OK |
| Confirmer ce plan et activer | 2 | OK |
| Activez votre cockpit SAV | 2 | OK |

### Fix PH-19.4 QA

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| data-selected | 2 | >= 1 | OK SSR + chunk |
| aria-pressed | 2 | >= 1 | OK SSR + chunk |
| invalid_marketing_owner_tenant_id | 2 | >= 1 | OK fallback compile dans le bundle |
| marketing_owner_tenant_id (toutes) | 9 | >= 1 | OK payload + fallback condition |
| Le plus populaire | 7 | >= 1 | OK badge sur Autopilot (SSR + chunks + config bundle) |
| Autopilot (id + nom) | 119 | references multiples | OK plan Autopilot promu |

### PII / Analytics / Clarity

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| data-clarity-mask | 26 | 13 source x 2 (SSR + chunk) | OK PII preserves |
| clarity.ms | 0 | 0 | OK Clarity non activee |
| NEXT_PUBLIC_CLARITY | 0 | 0 | OK |
| wrff07upjx | 0 | 0 | OK Clarity ID Website non leak Client |
| AW-XXXXXXXXXX direct | 0 | 0 | OK no fake Google Ads tag |
| plan_selected | 4 | 1 emit source x (SSR + chunks refs) | OK unique canonique preserve |

## NO FAKE METRICS / NO FAKE EVENTS

- `plan_selected` reste unique cote source (1 emit canonique dans `handleSelectPlan`), 4 occurrences bundle = refs SSR + chunks (pas 4 emits).
- Aucun nouvel event `Lead`, `Purchase`, `StartTrial`, `CompletePayment`, `SubmitForm`, `InitiateCheckout` ajoute par PH-19.4.
- Aucun tag `AW-XXXXXXXXXX` direct present dans le bundle.
- Aucun event "par bouton" ajoute (CTA register_confirm_plan_and_checkout, register_continue_to_plan, register_plan_select_*, register_cycle_toggle restent declaratifs via data-cta-id sans hook event auto).
- data-cta-id + data-plan + data-cycle + data-promo-state + data-selected + aria-pressed preserves pour QA/analytics futurs.
- Clarity client toujours non activee.

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.201-register-lead-first-dev | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

Aucun apply, aucun rollout, aucun manifest infra modifie.

## CONFIRMATIONS NO PUSH / NO DEPLOY

- AUCUN docker push (image locale uniquement, tag GHCR cible reste libre jusqu a la phase PUSH-IMAGE)
- AUCUN nouveau tag autre que `v3.5.202-register-qa-fix-dev`
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV / PROD
- AUCUN changement manifest infra
- AUCUN changement source applicatif
- AUCUN commit applicatif
- AUCUN secret expose dans logs / labels
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement
- Build-from-git (worktree detache propre, pas runtime/pod/dist)

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-335 (primary)** : Image Client DEV v3.5.202-register-qa-fix-dev construite from-git d363c38. Image ID sha256:1a2c23edc0bc... 280 MB. OCI labels 5/5 (revision d363c38, created 2026-05-20T13:54:47Z). Bundle verifie : 87 api-dev / 0 api.keybuzz.io (KEY-263 OK), data-selected 2, aria-pressed 2, invalid_marketing_owner_tenant_id 2 (fallback compile), Le plus populaire 7 (badge sur Autopilot), data-clarity-mask 26 preserves, plan_selected unique (1 emit source). STOP avant docker push GHCR. Prochaine etape : docker push, bump manifest, kubectl apply, smoke.

> **KEY-334** : Image post-QA-fix lead-first construite OK. Patterns tunnel preserves (register-lead-shell 2, register-reassurance-panel 2, register-confirm-plan 2, CTAs "Confirmer ce plan et activer" 2 et "Activez votre cockpit SAV" 2). Pas de regression sur lead-first PH-19.3.

> **KEY-329** : Image build CRO post-QA fix OK. Bundle ne contient toujours aucun fake review / fake logo / fake chiffre.

> **KEY-331** : plan_selected reste emis uniquement dans handleSelectPlan source (1 occurrence). Bundle compte 4 refs = SSR + chunks, pas 4 emits.

> **KEY-330** : No fake events ajoutes par PH-19.4. AW- direct = 0, aucun Lead/Purchase/StartTrial/CompletePayment ajoute.

> **KEY-325** : Clarity client toujours non activee dans l image construite (clarity.ms 0 / NEXT_PUBLIC_CLARITY 0 / wrff07upjx 0). 26 data-clarity-mask PII preserves dans le bundle.

## GAPS

1. Tag `v3.5.202-register-qa-fix-dev` reste libre cote GHCR jusqu a la phase PUSH-IMAGE. Image existe uniquement en local docker daemon sur install-v3.
2. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` toujours present (preexistant phase PH-19.1+, hors scope incident KEY-263 qui concerne api.keybuzz.io dans bundle DEV).
3. tsc 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts` resolues naturellement au build (regenere cache `.next`).
4. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.4/keybuzz-client` reste sur disque pour eventuelle phase PROD ulterieure ; cleanup possible post-PROD.
5. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline `v3.5.201-register-lead-first-dev` matching).
6. Clarity activation client.keybuzz.io reste decision post-QA lead-first + QA-fix.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.201-register-lead-first-dev`
- Digest rollback : `sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de`

Aucun rollback necessaire a ce stade (aucun runtime touche).

## VERDICT FINAL

GO BUILD CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

| Indicateur | Valeur |
|---|---|
| Image locale tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.202-register-qa-fix-dev |
| Image ID local | sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f |
| Size | 280 MB |
| Source commit | d363c38 |
| OCI labels KEY-308 | 5/5 OK |
| Bundle DEV isolation | OK (87 api-dev / 0 api.keybuzz.io) |
| Patterns PH-19.4 fix | OK (data-selected, aria-pressed, invalid_marketing_owner_tenant_id, Le plus populaire sur Autopilot) |
| Clarity | non activee (0/0/0) |
| AW- direct | 0 |
| plan_selected | 1 emit source unique |
| Runtime | 6/6 INCHANGE |
| NO docker push | OK |
| NO deploy | OK |
| NO kubectl | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-BUILD-CLIENT-DEV-01.md (untracked attendu) |

Prochaine phrase GO attendue :

GO PUSH IMAGE CLIENT REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

STOP.
