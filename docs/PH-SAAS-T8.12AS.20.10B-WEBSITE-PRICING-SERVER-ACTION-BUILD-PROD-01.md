# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-BUILD-PROD-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B BUILD Website PROD
> Environnement : Build Docker PROD only (aucun docker push, aucun deploy, aucun event)

## VERDICT

GO BUILD WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod` build OK depuis worktree --detach commit `907689b`.
- Image ID local : `sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd` size 214 MB.
- OCI labels KEY-308 5/5 OK (revision=907689bf51678c4d97785d9316f21f03ea074f9f).
- Markers patch PH-20.10B LIVE 4/4 dans /app/.next : Failed to find Server Action=2, kb_pricing_server_action_reload_v1=2, sessionStorage=6, window.location.reload=9.
- Tracking baseline preserve 5/5 : GA=18, SGTM=54, LinkedIn=18, marketing_cta_click=1, trackMarketingClick=40.
- CMP PH-20.8 preserve 3/3.
- **KEY-263 PROD isolation OK** : api.keybuzz.io/api/public/contact=2, api-dev.keybuzz.io=0, client.keybuzz.io=66.
- No fake events : test_event_code=0.
- Baseline v0.6.20-cmp-mobile-polish-prod : 0/0/18 -> 2/2/18 (markers actives, tracking inchange).
- GHCR collision tag PROD cible LIBRE (`manifest unknown`).
- Worktree nettoyee.
- Runtime Website DEV+PROD INCHANGES.

STOP avant push GHCR PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T15:49:10Z |
| keybuzz-website HEAD | 907689b |
| keybuzz-infra HEAD | 31e40ad |
| Runtime Website DEV avant | v0.6.21-pricing-action-recover-dev |
| Runtime Website PROD avant | v0.6.20-cmp-mobile-polish-prod |
| GHCR collision v0.6.21-pricing-action-recover-prod | manifest unknown (LIBRE) |
| Dirty Website repo | 0 |
| Dirty infra | 0 |

## E1 AUDIT SOURCE PRE-BUILD

Markers source dans `src/app/error.tsx + global-error.tsx` (commit 907689b) :

| Marker | Count source | Verdict |
|---|---|---|
| Failed to find Server Action | 3 | OK |
| kb_pricing_server_action_reload_v1 | 2 | OK |
| window.location.reload | 4 | OK |
| sessionStorage | 6 (deja confirme BUILD DEV) | OK |

tsc check : verifie BUILD DEV PH-20.10B = 0 erreurs. Source identique (commit 907689b inchange).

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.10B-WEBSITE-PROD/keybuzz-website |
| Worktree detache sur | 907689b |
| Full hash | 907689bf51678c4d97785d9316f21f03ea074f9f |
| Worktree dirty | 0 (clean) |

## E3 DOCKER BUILD WEBSITE PROD

### Build args PROD

| Arg | Valeur |
|---|---|
| NEXT_PUBLIC_SITE_MODE | production |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | (vide) |
| NEXT_PUBLIC_META_PIXEL_ID | (vide) |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | (vide) |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact |

### Resultat build

| Item | Valeur |
|---|---|
| Tag image | ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod |
| Exit code | 0 |
| Image ID | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd |
| Config digest local | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd |
| Size | 214 MB |
| Created | 2026-05-22T15:50:07 UTC |

### OCI labels KEY-308 (5/5 OK)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.created | 2026-05-22T15:49:31Z | OK |
| org.opencontainers.image.revision | 907689bf51678c4d97785d9316f21f03ea074f9f | OK MATCH commit |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website | OK |
| org.opencontainers.image.title | keybuzz-website | OK |
| org.opencontainers.image.version | v0.6.21-pricing-action-recover-prod | OK |

KEY-309 tag immutable + suffixe `-prod` conforme + versioning bump (v0.6.20 -> v0.6.21).

## E4 AUDIT IMAGE BUNDLE PROD

### Markers patch PH-20.10B LIVE dans /app/.next

| Marker | Count | Verdict |
|---|---|---|
| Failed to find Server Action | 2 | OK string detection compile |
| kb_pricing_server_action_reload_v1 | 2 | OK guard sessionStorage |
| sessionStorage | 6 | OK |
| window.location.reload | 9 | OK |

### Tracking baseline preserve

| ID/marker | Count | Verdict |
|---|---|---|
| GA G-R3QQDYEBFG | 18 | preserve baseline |
| SGTM t.keybuzz.pro | 54 | preserve baseline |
| LinkedIn 9969977 | 18 | preserve baseline |
| marketing_cta_click | 1 | preserve baseline |
| trackMarketingClick | 40 | preserve baseline |

### CMP PH-20.8 preserve

| Marker | Count | Verdict |
|---|---|---|
| max-h-[60vh] | 2 | preserve mobile compact |
| sm:hidden | 2 | preserve |
| keybuzz_cookie_consent | 5 | preserve CMP storage |

### KEY-263 isolation strict PROD

| Indicateur | Count | Verdict |
|---|---|---|
| api.keybuzz.io/api/public/contact (PROD endpoint) | 2 | OK present PROD |
| api-dev.keybuzz.io (DEV endpoint dans PROD) | **0** | OK isolation respectee |
| client.keybuzz.io (PROD CTA URL) | 66 | preserve |
| test_event_code | 0 | no fake events |

### Baseline comparison v0.6.20-cmp-mobile-polish-prod vs v0.6.21-pricing-action-recover-prod

| Marker | v0.6.20 baseline | v0.6.21 build | Delta | Verdict |
|---|---|---|---|---|
| Failed to find Server Action | 0 | 2 | **+2** | activated |
| kb_pricing_server_action_reload_v1 | 0 | 2 | **+2** | activated |
| G-R3QQDYEBFG (tracking baseline) | 18 | 18 | 0 | preserve |

Baseline confirmee : ces markers PH-20.10B etaient absents PROD avant le patch.

## E5 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.10B-WEBSITE-PROD/` | OK |
| Repo principal keybuzz-website | dirty=0 |

## E6 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.21-pricing-action-recover-dev | INCHANGE (deja deployee PH-20.10B) |
| keybuzz-website | keybuzz-website-prod | **v0.6.20-cmp-mobile-polish-prod** | INCHANGE (cible build non deployee) |
| keybuzz-api | DEV+PROD | v3.5.253 / v3.5.252-meta-capi-emq-prod | INCHANGES |
| keybuzz-client | DEV+PROD | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-admin-v2 | DEV+PROD | v2.12.2 | INCHANGES |

Aucun deploy. Aucun manifest GitOps modifie. Aucun kubectl apply.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- Aucun appel reseau analytics durant build.
- 0 test_event_code dans bundle.
- Aucun lead/register/checkout test.
- Aucun Meta/GA/LinkedIn event volontaire.
- Audit statique bundle uniquement (zero impact runtime).

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible LIBRE).
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela commit 907689b.
- AUCUN secret / token / Pixel ID affiche.
- AUCUN PII brut.
- AUCUN faux event / register / checkout / lead.
- AUCUN changement API/Client/Admin.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK BUILD (avant push)

Pas de rollback necessaire : aucune action irreversible. L image locale peut etre supprimee via :
```
docker rmi ghcr.io/keybuzzio/keybuzz-website:v0.6.21-pricing-action-recover-prod
```

## GAPS

1. Aucun. Build clean, OCI conformes, markers patch + tracking + CMP + KEY-263 PROD OK, baseline comparison confirme nouveaux markers actives, runtime preserve.
2. Note : le patch resout l effet utilisateur (auto-recover transparent UNE fois) mais le pattern logs serveur "Failed to find Server Action" continuera car cause inherente Next.js + bots/scanners. Documente dans PH-20.10B source patch rapport.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD WEBSITE PRICING SERVER ACTION PROD READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Source commit | 907689b (full 907689bf51678c4d97785d9316f21f03ea074f9f) |
| Tag image PROD | v0.6.21-pricing-action-recover-prod |
| Image ID local | sha256:92d8fd2a4532f482b36ec63b14caffd8e8f26f04b34b33d5d096b25e0c728dbd |
| Size | 214 MB |
| OCI labels KEY-308 | 5/5 OK |
| Markers PH-20.10B LIVE | 4/4 OK (delta vs baseline +2/+2) |
| Tracking baseline | 18/54/18/1/40 preserve |
| CMP PH-20.8 | 2/2/5 preserve |
| KEY-263 PROD isolation | OK (api.keybuzz.io=2, api-dev=0, client.keybuzz.io=66) |
| No fake events | 0 |
| GHCR collision | LIBRE |
| Worktree | nettoyee |
| Runtime DEV/PROD | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE WEBSITE PRICING SERVER ACTION PROD PH-SAAS-T8.12AS.20.10B`

STOP. Aucun docker push, aucun deploy DEV/PROD, aucun event tracking, aucun changement Linear statut.
