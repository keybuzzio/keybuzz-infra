# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-BUILD-PROD-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER BUILD PROD
> Environnement : PROD build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2

- Image Docker locale Client PROD construite depuis worktree detache propre sur commit `dad5f89`.
- Tag : `ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod`.
- Image ID : `sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27`.
- Build args PROD explicites : NEXT_PUBLIC_APP_ENV=production, NEXT_PUBLIC_API_URL=https://api.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io, NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33.
- OCI labels KEY-308 OK 5/5.
- Bundle PROD KEY-263 isolation : api.keybuzz.io=2, api-dev.keybuzz.io=0 (zero leak DEV).
- Bundle PROD Clarity actif : wuk12h9i33=1, clarity.ms=1, ms-clarity=1.
- Delta strict vs baseline PROD v3.5.199 = +1 wuk12h9i33, +1 clarity.ms, +1 ms-clarity (Clarity uniquement, aucun nouveau fake event, aucune regression).
- PH-19.x preserves a l identique.
- Runtime PROD `v3.5.199-register-state-persistence-prod` INCHANGE.
- Runtime DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Aucun docker push.

STOP avant docker push GHCR.

## E0 PREFLIGHT

### Bastion install-v3

| Indicateur | Valeur |
|---|---|
| hostname | install-v3 |
| IP publique | 46.62.171.61 |
| date UTC | 2026-05-21 12:57:04 |

### Repos Git

| Repo | Branche | HEAD | Origin | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | dad5f89 feat(client): add route-gated Clarity provider for register | dad5f89 | 1 (tsconfig.tsbuildinfo cache hors scope) | OK source PH-20.2 commit |
| keybuzz-infra | main | d884fd5 docs(tracking): rapport PH-20.2 Clarity client apply DEV | d884fd5 | 0 | OK |

### Runtime K8s avant build

| Service | Namespace | Image runtime | Ready | Verdict |
|---|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | 1/1 | OK PH-20.2 DEV |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | 1/1 | OK PROD baseline |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | OK |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | OK |
| keybuzz-website | keybuzz-website-dev / -prod | v0.6.18-ga4-cleanup-dev / -prod | 1/1 / 2/2 | OK |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev / -prod | v2.12.2-media-buyer-lp-domain-qa-dev / -prod | 1/1 | OK |

### GHCR collision check

| Tag | GHCR manifest | Verdict |
|---|---|---|
| v3.5.200-clarity-register-prod | `manifest unknown` | LIBRE OK |

## E1 SOURCE VERIFY

| Fichier | Check | Attendu | Observe | Verdict |
|---|---|---|---|---|
| Dockerfile | grep NEXT_PUBLIC_CLARITY_PROJECT_ID | 2 (ARG + ENV) | 2 | OK |
| src/components/tracking/SaaSAnalytics.tsx | grep NEXT_PUBLIC_CLARITY_PROJECT_ID | 2 (doc + const) | 2 | OK |
| src/components/tracking/SaaSAnalytics.tsx | grep ms-clarity | 1 (Script id) | 1 | OK |
| src/components/tracking/SaaSAnalytics.tsx | grep FUNNEL_PREFIXES | 2 | 2 | OK |
| src/components/tracking/SaaSAnalytics.tsx | grep BLOCKED_PREFIXES | 2 | 2 | OK |

## E2 DOCKER BUILD PROD

### Build args explicites

| Build arg | Valeur attendue | Statut |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | production | OK |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | OK |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | OK |
| GIT_COMMIT_SHA | dad5f89b1e9d511026d168e7ae64a9209151355a | OK |
| BUILD_TIME | 2026-05-21T12:57:21Z | OK |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | omis (iso baseline v3.5.199, ne reactive pas GA4 client PROD) | OK |
| NEXT_PUBLIC_META_PIXEL_ID | omis | OK |
| NEXT_PUBLIC_SGTM_URL | omis | OK |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | omis | OK |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | (Dockerfile default 9969977, heritage iso baseline) | OK |

### Build result

| Item | Valeur |
|---|---|
| Build exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod |
| Image ID | sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27 |
| Image size | 280 003 899 bytes (267 MiB) |
| Worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.2-PROD/keybuzz-client (cleanup post-build OK) |

### OCI labels KEY-308

| OCI label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | dad5f89b1e9d511026d168e7ae64a9209151355a | OK |
| org.opencontainers.image.created | 2026-05-21T12:57:21Z | OK |
| org.opencontainers.image.version | v3.5.200-clarity-register-prod | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

5/5 OK.

## E3 BUNDLE VERIFY PROD

### KEY-263 isolation PROD

| Pattern | Attendu PROD | Observe | Verdict |
|---|---|---|---|
| api.keybuzz.io (PROD URL) | >= 1 | 2 | OK |
| api-dev.keybuzz.io (DEV URL) | 0 | 0 | OK zero leak DEV |

### Clarity active

| Pattern | Attendu | Observe | Verdict |
|---|---|---|---|
| Clarity Project ID `wuk12h9i33` | >= 1 | 1 | OK |
| `clarity.ms/tag` loader | >= 1 | 1 | OK |
| Script id `ms-clarity` | >= 1 | 1 | OK |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` literal in bundle | 0 | 0 | OK (resolved at build time) |

### PH-19.x preservation (delta vs baseline v3.5.199)

| Pattern | v3.5.199 baseline | v3.5.200 new | Delta | Verdict |
|---|---|---|---|---|
| api.keybuzz.io | 2 | 2 | 0 | OK isolation PROD |
| api-dev.keybuzz.io | 0 | 0 | 0 | OK |
| wuk12h9i33 | 0 | **1** | **+1** | OK Clarity ID inline |
| clarity.ms | 0 | **1** | **+1** | OK loader |
| ms-clarity | 0 | **1** | **+1** | OK Script id |
| data-clarity-mask | 13 | 13 | 0 | OK PII protection preservee |
| kb_signup_form_draft_v1 | 2 | 2 | 0 | OK PH-19.7 |
| kb_signup_cgu_accepted | 2 | 2 | 0 | OK PH-19.6 |
| plan_selected | 2 | 2 | 0 | OK KEY-331 emit unique |
| register-cgu-accepted-note | 1 | 1 | 0 | OK PH-19.6 |
| register-lead-shell | 1 | 1 | 0 | OK PH-19.3 |
| register-confirm-plan | 1 | 1 | 0 | OK PH-19.3 |
| invalid_marketing_owner_tenant_id | 1 | 1 | 0 | OK PH-19.4 fallback |
| 0 EUR pendant 14 jours | 2 | 2 | 0 | OK PH-19.6 copy F.9 |
| Le plus populaire | 3 | 3 | 0 | OK PH-19.4 Autopilot badge |
| data-selected | 1 | 1 | 0 | OK PH-19.4 |
| aria-pressed | 1 | 1 | 0 | OK PH-19.4 |

### No fake metrics / no fake events

| Pattern | v3.5.199 baseline | v3.5.200 new | Delta | Verdict |
|---|---|---|---|---|
| `"Lead"` | 1 | 1 | 0 | preexistant, OK |
| `"Purchase"` | 0 | 0 | 0 | OK |
| `"StartTrial"` | 0 | 0 | 0 | OK |
| `"CompletePayment"` | 0 | 0 | 0 | OK |
| `"SubmitForm"` | 1 | 1 | 0 | preexistant, OK |
| `"InitiateCheckout"` | 2 | 2 | 0 | preexistant, OK |
| `AW-` direct (Google Ads tag) | 0 | 0 | 0 | OK |
| fbq | 0 (omis baseline) | 0 | 0 | OK iso baseline |
| ttq | 0 (omis baseline) | 0 | 0 | OK iso baseline |

DELTA STRICT v3.5.200 - v3.5.199 = uniquement +1 wuk12h9i33, +1 clarity.ms, +1 ms-clarity. AUCUN nouvel evenement marketing fabrique. AUCUNE regression.

## E4 RUNTIME PRESERVE

| Service | Image runtime | Ready | Preserve |
|---|---|---|---|
| keybuzz-client (dev) | v3.5.206-clarity-register-dev | 1/1 | INCHANGE |
| keybuzz-client (prod) | v3.5.199-register-state-persistence-prod | 1/1 | INCHANGE |
| keybuzz-api (dev) | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api (prod) | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website (dev) | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website (prod) | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |
| keybuzz-admin-v2 (dev/prod) | v2.12.2-media-buyer-lp-domain-qa-* | 1/1 | INCHANGE |

Aucun docker push effectue. Aucun kubectl apply. Aucun manifest GitOps modifie.

## E5 SIGNAL TABLE PROD

| Signal | Type | Source | Destination | Statut bundle PROD |
|---|---|---|---|---|
| Clarity session replay PROD | UX analytics | SaaSAnalytics.tsx (NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33) | clarity.ms project wuk12h9i33 | ARMEE en source (a deployer en APPLY PROD) |
| GA4/Meta/TikTok/LinkedIn Client PROD | tracking | aucun (omis at build, iso baseline v3.5.199) | aucun | INCHANGE INACTIF |
| plan_selected emit | funnel internal | trackSignupStep -> API funnel_events | DB funnel_events | INCHANGE source unique |
| kb_signup_form_draft_v1 | state local | sessionStorage Client | aucun (local only) | INCHANGE PH-19.7 |
| kb_signup_cgu_accepted | state local | sessionStorage Client | aucun (local only) | INCHANGE PH-19.6 |
| Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- | tracking publicitaire | aucun emit cote Client (preexistants comme labels) | aucun | INACTIF, INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR.
- AUCUN deploy DEV.
- AUCUN deploy PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/Google Ads/Clarity (build only).
- AUCUN faux Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement.
- Clarity Project ID `wuk12h9i33` est inline dans le bundle JS (comportement attendu pour tracking client-side, ID non-secret visible cote Microsoft Clarity).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Build local seulement, aucun rollback runtime necessaire.

Rollback de la phase build :

1. Suppression image locale : `docker rmi ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod`.

Pour les phases ulterieures (apres APPLY PROD) :

- Rollback tag PROD au runtime actuel : `v3.5.199-register-state-persistence-prod` (digest `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a`).

## GAPS

1. Build args marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis iso baseline v3.5.199. Decision strategique inchangee (delegation server-side via CAPI).
2. /login route inclus dans FUNNEL_PREFIXES : Clarity y sera actif en PROD egalement apres APPLY. Default Clarity masque automatiquement les champs password ; verification a QA navigateur Ludovic.

## LINEAR KEY-339

Brouillon comment pour KEY-339 (a poster apres validation rapport et avant phase PUSH IMAGE) :

```
PH-SAAS-T8.12AS.20.2 build Client PROD READY (2026-05-21).

Verdict : GO BUILD CLIENT CLARITY REGISTER PROD READY.

Image tag : v3.5.200-clarity-register-prod
Image ID local : sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27
Source commit : dad5f89
Clarity ID inline : wuk12h9i33

Bundle PROD verify :
- KEY-263 isolation PROD : api.keybuzz.io=2, api-dev=0 (zero leak DEV).
- Clarity active : wuk12h9i33=1, clarity.ms=1, ms-clarity=1.
- Route-gated (FUNNEL_PREFIXES /register + /login ; BLOCKED_PREFIXES /inbox /dashboard /orders /settings /channels /suppliers /knowledge /playbooks /ai-journal /billing /onboarding /workspace-setup /start /help).
- Delta strict vs v3.5.199 baseline = +Clarity uniquement (0 fake event).
- PH-19.x preserves : data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected=2, "0 EUR pendant 14 jours"=2, "Le plus populaire"=3.

Runtime PROD v3.5.199 INCHANGE. Aucun docker push. Aucun deploy.

Prochaine phrase GO : GO PUSH IMAGE CLIENT CLARITY REGISTER PROD PH-SAAS-T8.12AS.20.2
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | dad5f89 |
| Tag image cible | v3.5.200-clarity-register-prod |
| Image ID local | sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27 |
| Image size | 280 MB |
| OCI labels | 5/5 OK |
| KEY-263 isolation PROD | api.keybuzz.io=2 / api-dev.keybuzz.io=0 |
| Clarity Project ID inline | wuk12h9i33 (1 occurrence) |
| Clarity loader | clarity.ms/tag (1 occurrence) |
| Clarity Script id | ms-clarity (1 occurrence) |
| Delta vs baseline PROD v3.5.199 | +1 wuk12h9i33 +1 clarity.ms +1 ms-clarity ; 0 nouveau fake event |
| PH-19.x preserves | data-clarity-mask=13, kb_signup_form_draft_v1=2, kb_signup_cgu_accepted=2, plan_selected=2, 0 EUR pendant 14 jours=2, Le plus populaire=3, register-lead-shell=1, register-confirm-plan=1, register-cgu-accepted-note=1, invalid_marketing_owner_tenant_id=1, data-selected=1, aria-pressed=1 |
| Runtime PROD | v3.5.199-register-state-persistence-prod INCHANGE |
| Runtime DEV | v3.5.206-clarity-register-dev INCHANGE |
| Worktree cleanup | OK |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT CLARITY REGISTER PROD PH-SAAS-T8.12AS.20.2`

STOP.
