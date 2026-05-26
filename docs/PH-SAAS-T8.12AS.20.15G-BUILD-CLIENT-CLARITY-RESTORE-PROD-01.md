# PH-SAAS-T8.12AS.20.15G-BUILD-CLIENT-CLARITY-RESTORE-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322/KEY-325 Clarity tracking ; KEY-339 client funnel
> Phase : PH-SAAS-T8.12AS.20.15G (BUILD CLIENT PROD ONLY)
> Environnement : PROD preparation (build local from-git ; aucun push, deploy, kubectl, manifest)

## 1. Verdict

GO BUILD CLIENT CLARITY RESTORE PROD READY PH-SAAS-T8.12AS.20.15G

Image locale v3.5.217-clarity-client-restore-prod construite from-git depuis HEAD ef239e8 (ph148/onboarding-activation-replay) avec build-args iso baseline saine v3.5.200-clarity-register-prod + Clarity restaure. Bundle : wuk12h9i33=2, clarity.ms/tag=2, ms-clarity=2, data-clarity-mask=2 (Clarity client funnel restaure, project ID client distinct). Safeguards KEY-263/KEY-302 verifies : api.keybuzz.io=87, api-dev.keybuzz.io=0, MUST_BE_SET_BY_BUILD_ARG=0, wrff07upjx (ID website) absent=0. Image ID sha256:6a20d9b79bf6. Aucun push, aucun deploy, GHCR v3.5.217 absent, runtime client PROD reste v3.5.215. Worktree retire proprement. Pret pour la phase push (15H).

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 20:21.

| Repo/service | branch/runtime | HEAD/image | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | ef239e8 = origin | clean (hors tsbuildinfo) | OK |
| keybuzz-infra | main | 4ab6d50 = origin | clean | OK |
| runtime client PROD | v3.5.215-ai-draft-blocked-reason-prod | - | ready | Clarity absent (cible) |
| tag v3.5.217 local docker | - | ABSENT | - | OK |
| tag v3.5.217 GHCR | - | ABSENT | - | OK |
| manifests infra ref v3.5.217 | - | ABSENT | - | OK |

## 3. Source Clarity client (E1)

| File | expected env | current behavior | verdict |
|---|---|---|---|
| src/components/tracking/SaaSAnalytics.tsx L31 | const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID \|\| '' | route-gated funnel-only | OK |
| SaaSAnalytics L55/L87 | shouldLoad = !isBlockedPage && isFunnelPage && (... \|\| CLARITY_PROJECT_ID) ; if (!shouldLoad) return null | no-op si ID vide ET hors funnel | confirme cause 15F |
| SaaSAnalytics L165-175 | {CLARITY_PROJECT_ID && (<Script id=ms-clarity> clarity.ms/tag/${ID})} | injection conditionnelle funnel | OK |
| Dockerfile L24/ENV | ARG + ENV NEXT_PUBLIC_CLARITY_PROJECT_ID= (defaut vide) | consomme build-arg | OK (intact) |

Source intacte : aucun patch necessaire ; seul le build-arg manquait depuis v3.5.201.

## 4. Build args (E2)

Liste exacte iso baseline saine v3.5.200-clarity-register-prod (PH-20.2-PROD) + Clarity restaure ; HEAD courant ef239e8.

| Build arg | value | source | verdict |
|---|---|---|---|
| NEXT_PUBLIC_APP_ENV | production | v3.5.200 | OK |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io | v3.5.200 (anti KEY-263/302) | OK |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | v3.5.200 (anti KEY-263/302) | OK |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | v3.5.200 (RESTAURE) | cible |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | v3.5.200 / Dockerfile default | OK |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | (omis) | iso baseline client PROD (jamais actif) | OK |
| NEXT_PUBLIC_META_PIXEL_ID | (omis) | iso baseline | OK |
| NEXT_PUBLIC_SGTM_URL | (omis) | iso baseline | OK |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | (omis) | iso baseline | OK |
| GIT_COMMIT_SHA | ef239e898887ba052ede3f9592991e1093f74985 | HEAD | OK |
| BUILD_TIME | 2026-05-26T20:22:59Z | UTC | OK |
| IMAGE_REVISION | ef239e898887ba052ede3f9592991e1093f74985 | HEAD (label OCI) | OK |
| IMAGE_VERSION | v3.5.217-clarity-client-restore-prod | tag (label OCI) | OK |
| IMAGE_CREATED | 2026-05-26T20:22:59Z | UTC (label OCI) | OK |

Delta strict vs runtime v3.5.215 = +NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33. GA4/Meta/SGTM/TikTok deliberement omis (client PROD ne les a jamais actives, seul Clarity funnel l'etait). Aucun arg requis inconnu.

## 5. Build (E3/E4/E5)

| Item | valeur |
|---|---|
| Worktree | /opt/keybuzz/build-worktrees/PH-20.15G (detache ef239e8, porcelain=0) |
| Precheck | next build interne stage builder Docker (pattern builds client ; exit 0) |
| Tag image | ghcr.io/keybuzzio/keybuzz-client:v3.5.217-clarity-client-restore-prod |
| Build exit code | 0 (Successfully built) |
| Warning build-arg non consomme | aucun |
| Image ID | sha256:6a20d9b79bf65ca44e77a61624614af6f7da910989b68bed00fd02dedad2a6ea |
| OCI revision | ef239e898887ba052ede3f9592991e1093f74985 |
| OCI version | v3.5.217-clarity-client-restore-prod |
| OCI created | 2026-05-26T20:22:59Z |
| Push | AUCUN (build local uniquement) |

## 6. Bundle markers (E6)

Audit dans l'image (/app/.next), grep -rl (nb fichiers) sauf api.keybuzz.io (occurrences).

| Marker | expected | result | verdict |
|---|---|---|---|
| wuk12h9i33 (Clarity ID client) | present | 2 | RESTAURE |
| clarity.ms/tag | present | 2 | OK |
| ms-clarity | present | 2 | OK |
| data-clarity-mask (masques PII) | present | 2 | OK |
| https://api.keybuzz.io (API PROD) | present | 87 | OK |
| https://api-dev.keybuzz.io (LEAK) | 0 | 0 | OK (anti KEY-263/302) |
| MUST_BE_SET_BY_BUILD_ARG | 0 | 0 | OK (args set) |
| wrff07upjx (ID website) | 0 | 0 | OK (pas de contamination) |
| CSS assets | present | 2 | OK |
| JS chunks | present | 83 | OK |

Pattern identique a v3.5.200-clarity-register-prod (wuk12h9i33 + clarity.ms + ms-clarity). Clarity client restaure, API PROD correct, 0 fuite DEV.

## 7. No side-effect (E7)

| Signal | etat | verdict |
|---|---|---|
| GHCR tag v3.5.217 | ABSENT (non pousse) | OK |
| runtime client PROD | v3.5.215-ai-draft-blocked-reason-prod (inchange) | OK |
| manifest infra ref v3.5.217 | ABSENT | OK |
| repo infra | 0 dirty | clean |
| kubectl / deploy / fake event | aucun | OK |
| website / Amazon | non touches | OK |
| worktree | retire proprement (git worktree remove sans --force) | OK |

## 8. Rollback

| Niveau | action |
|---|---|
| Image locale | v3.5.217 locale uniquement ; docker rmi sans impact runtime |
| Runtime PROD | reste v3.5.215-ai-draft-blocked-reason-prod (aucun changement) |
| GHCR | rien pousse ; aucun rollback registry |
| Promotion future | phase apply (15I) conservera v3.5.215 comme rollback documente |

## 9. Prochaine phase

GO PUSH IMAGE CLIENT CLARITY RESTORE PROD PH-SAAS-T8.12AS.20.15H : docker push v3.5.217-clarity-client-restore-prod vers GHCR + verif digest (pull-back) ; puis GitOps apply PROD (15I) bump client v3.5.215 -> v3.5.217 + rollout + QA consent funnel (avant consent 0 requete ; sur /register apres consent requete clarity.ms/tag/wuk12h9i33). Durcissement recommande : ajouter les build-args Clarity (client wuk12h9i33 + website wrff07upjx) aux scripts de build standard des deux repos.

## 10. Phrase cible

GO BUILD CLIENT CLARITY RESTORE PROD READY PH-SAAS-T8.12AS.20.15G

STOP.
