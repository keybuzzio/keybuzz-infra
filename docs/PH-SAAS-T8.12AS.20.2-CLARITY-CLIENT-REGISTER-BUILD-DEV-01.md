# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER BUILD DEV
> Environnement : DEV build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2

- Image Docker locale construite depuis worktree detache propre sur commit `dad5f89`.
- Tag : `ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev`.
- Image ID : `sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2`.
- Build args DEV explicites : NEXT_PUBLIC_APP_ENV=development, NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33.
- OCI labels KEY-308 OK 5/5.
- Bundle DEV : KEY-263 isolation respectee (api-dev=2, api.keybuzz.io seul=0).
- Bundle DEV : Clarity active (wuk12h9i33=1, clarity.ms=1, ms-clarity script id=1).
- Bundle DEV : PH-19.x preserves (data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected emit unique=2).
- Bundle DEV : 0 fake event ajoute (delta vs baseline v3.5.205 strictement = +1 wuk12h9i33, +1 clarity.ms, rien d autre).
- Runtime DEV `v3.5.205-register-state-persistence-dev` INCHANGE.
- Runtime PROD `v3.5.199-register-state-persistence-prod` INCHANGE.
- Aucun docker push effectue.
- Aucun deploy effectue.

STOP avant docker push GHCR.

## E0 PREFLIGHT BASTION + REPOS

### Bastion install-v3

| Indicateur | Valeur |
|---|---|
| hostname | install-v3 |
| IP publique | 46.62.171.61 |
| date UTC | 2026-05-21 11:46:38 |
| Source IP autorisee | OK |

### Repos Git

| Repo | Branche | HEAD | Dirty | Local==Origin | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | dad5f89 feat(client): add route-gated Clarity provider for register | 1 (tsconfig.tsbuildinfo cache hors scope) | OK | OK source PH-20.2 commit |
| keybuzz-infra | main | ee174ec docs(tracking): rapport PH-20.2 Clarity client source | 0 | OK | OK |

### Runtime K8s

| Service | Namespace | Image runtime avant build | Image runtime apres build (verify) |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.205-register-state-persistence-dev | INCHANGE (v3.5.205, build local only) |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | INCHANGE (v3.5.199) |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev / -prod | v2.12.2-media-buyer-lp-domain-qa-dev / -prod | INCHANGE |

### GHCR collision check

| Item | Resultat |
|---|---|
| Tag cible `v3.5.206-clarity-register-dev` | docker manifest inspect : `manifest unknown` (LIBRE, OK) |
| Disk available /opt | 14 GB |
| Existing local images keybuzz-client | v3.5.199-PROD, v3.5.205-DEV, v3.5.204-DEV, v3.5.203-DEV |

## E1 WORKTREE GIT --DETACH PROPRE

| Item | Valeur |
|---|---|
| Path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.2/keybuzz-client |
| HEAD | dad5f89b1e9d511026d168e7ae64a9209151355a |
| Dirty count | 0 |
| Dockerfile lines | 105 (vs 103 avant patch PH-20.2 source : +2 ARG/ENV NEXT_PUBLIC_CLARITY_PROJECT_ID) |
| SaaSAnalytics.tsx lines | 182 (vs 161 avant patch PH-20.2 source : +21 doc + const + shouldLoad + Clarity Script bloc) |
| Pattern NEXT_PUBLIC_CLARITY_PROJECT_ID in Dockerfile | 2 (ARG + ENV) |
| Pattern NEXT_PUBLIC_CLARITY_PROJECT_ID in SaaSAnalytics.tsx | 2 (doc + const) |
| Pattern ms-clarity Script id | 1 |
| Pattern clarity.ms/tag loader | 1 |

## E2 DOCKER BUILD CLIENT DEV

### Build args explicites

| Build arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 |
| GIT_COMMIT_SHA | dad5f89b1e9d511026d168e7ae64a9209151355a |
| BUILD_TIME | 2026-05-21T11:50:57Z |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | omis (iso baseline v3.5.205, ne reactive pas GA4 client) |
| NEXT_PUBLIC_META_PIXEL_ID | omis |
| NEXT_PUBLIC_SGTM_URL | omis |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | omis |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | (Dockerfile default 9969977, heritage non-patch) |

### Build result

| Item | Valeur |
|---|---|
| Build exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev |
| Image ID | sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2 |
| Image size | 280 003 567 bytes (267 MiB) |
| Build duration | OK |
| Worktree cleanup post-build | OK |

## E3 OCI LABELS KEY-308

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | dad5f89b1e9d511026d168e7ae64a9209151355a | OK |
| org.opencontainers.image.created | 2026-05-21T11:50:57Z | OK |
| org.opencontainers.image.version | v3.5.206-clarity-register-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

5/5 OK.

## E4 BUNDLE AUDIT

### KEY-263 isolation DEV

| Pattern | Attendu DEV | Observe |
|---|---|---|
| api-dev.keybuzz.io | >= 1 | 2 |
| api.keybuzz.io SEUL (not api-dev) | 0 | 0 |

OK : bundle DEV ne contient aucune URL PROD.

### Clarity active

| Pattern | Attendu | Observe | Verdict |
|---|---|---|---|
| Clarity Project ID `wuk12h9i33` | >= 1 | 1 | OK |
| `clarity.ms/tag` loader | >= 1 | 1 | OK |
| Script id `ms-clarity` | >= 1 | 1 | OK |
| `clarity.ms` total (= loader uniquement) | 1 | 1 | OK pas de duplication |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` literal in bundle | 0 | 0 | OK (build-time env var resolue, pas le nom de var dans le bundle) |

### Bundle isolation Marketing IDs

| Pattern | Observe | Note |
|---|---|---|
| `AW-` direct | 0 | OK |
| GA4 G-* (omis at build) | 0 | OK iso baseline |
| Meta Pixel (omis at build) | 0 | OK iso baseline |
| TikTok ttq.load (omis at build) | 0 | OK iso baseline |
| LinkedIn _linkedin_partner_id (default Dockerfile 9969977 herite) | non-zero possible | non bloquant, iso baseline 205 |

### PH-19.x preservation

| Pattern | Attendu | Observe v3.5.206 | Baseline v3.5.205 | Verdict |
|---|---|---|---|---|
| kb_signup_form_draft_v1 | 2 | 2 | 2 | OK |
| kb_signup_cgu_accepted | 2 | 2 | 2 | OK |
| register-lead-shell | 1 | 1 | 1 | OK |
| register-confirm-plan | 1 | 1 | 1 | OK |
| data-clarity-mask | 13 | 13 | 13 | OK PII protection inchangee |
| register-cgu-accepted-note | 1 | 1 | 1 | OK |
| 0 EUR pendant 14 jours | 2 | 2 | 2 | OK |
| invalid_marketing_owner_tenant_id | 1 | 1 | 1 | OK |
| Le plus populaire | 3 | 3 | 3 | OK |
| plan_selected emit (chunk total) | 2 | 2 | 2 | OK source unique preservee |

### No fake events / no fake metrics

| Pattern | Observe v3.5.206 | Baseline v3.5.205 | Delta | Verdict |
|---|---|---|---|---|
| `"Lead"` | 1 | 1 | 0 | preexistant, non emis comme conversion |
| `"Purchase"` | 0 | 0 | 0 | OK |
| `"StartTrial"` | 0 | 0 | 0 | OK |
| `"CompletePayment"` | 0 | 0 | 0 | OK |
| `"SubmitForm"` | 1 | 1 | 0 | preexistant |
| `"InitiateCheckout"` | 2 | 2 | 0 | preexistant (billing) |

Delta strict vs baseline v3.5.205 = uniquement +1 occurrence `wuk12h9i33` et +1 occurrence `clarity.ms`. Aucun nouvel evenement marketing fabrique.

## E5 SIGNAL TABLE

| Signal | Type | Source | Destination | Statut bundle |
|---|---|---|---|---|
| Clarity session record | UX analytics | SaaSAnalytics.tsx (NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33) | clarity.ms project `wuk12h9i33` | ACTIF on /register et /login uniquement |
| Clarity custom tag | UX | aucun | aucun | INACTIF (no fake tags) |
| GA4 Client | tracking | aucun (omis at build) | aucun | INACTIF iso baseline 205 |
| Meta Pixel Client | tracking | aucun | aucun | INACTIF |
| TikTok Pixel Client | tracking | aucun | aucun | INACTIF |
| Google Ads (AW-) | tracking | aucun | aucun | INACTIF |
| plan_selected | funnel internal | trackSignupStep -> emitFunnelStep | API funnel_events | INCHANGE (preserve) |
| kb_signup_form_draft_v1 | state local | sessionStorage Client | aucun (local only) | INCHANGE PH-19.7 |
| kb_signup_cgu_accepted | state local | sessionStorage Client | aucun (local only) | INCHANGE PH-19.6 |

## E6 RUNTIME INCHANGE VERIFY

| Namespace | Service | Runtime apres build | Verdict |
|---|---|---|---|
| keybuzz-client-dev | keybuzz-client | v3.5.205-register-state-persistence-dev | INCHANGE (build local seulement) |
| keybuzz-client-prod | keybuzz-client | v3.5.199-register-state-persistence-prod | INCHANGE |
| keybuzz-api-dev | keybuzz-api | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api-prod | keybuzz-api | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | keybuzz-website | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | keybuzz-website | v0.6.18-ga4-cleanup-prod | INCHANGE |
| keybuzz-admin-v2-dev / -prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev / -prod | INCHANGE |

Aucun docker push. Aucun deploy. Aucun kubectl apply.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR.
- AUCUN deploy DEV.
- AUCUN deploy PROD.
- AUCUN kubectl apply.
- AUCUN manifest GitOps modifie.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/Google Ads/Clarity (build only).
- AUCUN faux Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement.
- Clarity Project ID `wuk12h9i33` est un identifiant non-secret cote Microsoft Clarity (visible dans la console clarity.ms cote Antoine/owner). Inline dans le bundle JS comme prevu pour tracking client-side.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Le build est local seulement, donc aucun rollback runtime necessaire.

Rollback de la phase :

1. Suppression image locale : `docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev`
2. Le source patch reste sur la branche (commit `dad5f89` deja push), inverser via `git revert dad5f89` si necessaire (mais le code source reste no-op si Clarity ID non fourni au build).

Pour les phases suivantes :

- Rollback tag DEV au runtime : `v3.5.205-register-state-persistence-dev` (digest `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621`).
- Rollback tag PROD au runtime : `v3.5.199-register-state-persistence-prod` (digest `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a`).

## GAPS

1. Build args marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis iso baseline v3.5.205. Decision strategique inchangee (delegation server-side via CAPI).
2. `/login` route inclus dans FUNNEL_PREFIXES : Clarity y sera actif. A QA navigateur DEV : verifier que Clarity masque automatiquement les champs password (default Clarity behavior).
3. tsc 2 erreurs preexistantes `.next/types/app/api/debug-env/route.ts` (cache stale heritage PH-19.0). Hors scope.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | dad5f89 |
| Tag image cible | v3.5.206-clarity-register-dev |
| Image ID local | sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2 |
| Image size | 280 MB |
| OCI labels | 5/5 OK |
| KEY-263 isolation DEV | api-dev=2 / api.keybuzz.io seul=0 |
| Clarity Project ID inline | `wuk12h9i33` (1 occurrence) |
| Clarity loader | `clarity.ms/tag` (1 occurrence) |
| Script id | `ms-clarity` (1 occurrence) |
| PH-19.x preserves | data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected emit=2, register-lead-shell=1, register-confirm-plan=1, "0 EUR pendant 14 jours"=2, "Le plus populaire"=3, "register-cgu-accepted-note"=1, "invalid_marketing_owner_tenant_id"=1 |
| No fake events delta | 0 nouveau Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- |
| Runtime DEV | v3.5.205-register-state-persistence-dev INCHANGE |
| Runtime PROD | v3.5.199-register-state-persistence-prod INCHANGE |
| Worktree cleanup | OK |
| Linear KEY-339 | non touche (build only) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-BUILD-DEV-01.md` (a commit+push si ASCII OK) |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT CLARITY REGISTER DEV PH-SAAS-T8.12AS.20.2`

STOP.
