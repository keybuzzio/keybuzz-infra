# PH-SAAS-T8.12AS.20.15B-BUILD-WEBSITE-CLARITY-FIX-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; reference KEY-323 restored
> Phase : PH-SAAS-T8.12AS.20.15B (BUILD WEBSITE PROD ONLY)
> Environnement : PROD preparation (build local from-git ; aucun push, deploy, kubectl)

## 1. Verdict

GO BUILD WEBSITE CLARITY FIX PROD READY PH-SAAS-T8.12AS.20.15B

Image locale v0.6.22-clarity-restore-prod construite from-git depuis HEAD 907689b avec les build-args iso baseline saine v0.6.19. Clarity restaure (wrff07upjx + clarity.ms/tag = 2 occurrences chacun dans le bundle, pattern identique au build sain v0.6.19). Decouverte : le build casse v0.6.21 (PH-20.10B) avait droppe NON SEULEMENT Clarity mais AUSSI le Meta Pixel et le TikTok Pixel (tous vides) ; v0.6.22 les restaure tous les trois (Meta 1234164602194748 + TikTok D7PT12JC77U44OJIPC10 presents). Image ID sha256:619afbd95b82. Aucun push, aucun deploy, GHCR v0.6.22 absent, runtime PROD reste v0.6.21. Worktree retire proprement. Pret pour la phase push (15C).

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 19:18.

| Repo/service | branch/runtime | HEAD/image | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-website | main | 907689b = origin (= HEAD attendu) | clean | OK |
| keybuzz-infra | main | ee1e1af = origin | clean | OK |
| runtime website PROD | v0.6.21-pricing-action-recover-prod | 2/2 ready | - | inchange (cible du fix) |
| tag v0.6.22 local docker | - | ABSENT | - | OK (pas de collision) |
| tag v0.6.22 GHCR | - | ABSENT (docker manifest inspect KO) | - | OK (pas de collision) |
| manifests infra ref v0.6.22 | - | ABSENT | - | OK |

## 3. Source Clarity (E1)

| File | expected env | current behavior | verdict |
|---|---|---|---|
| src/components/ClarityProvider.tsx L12 | process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID | const CLARITY_PROJECT_ID = env | OK |
| ClarityProvider.tsx L50 | if (!CLARITY_PROJECT_ID) return null | no-op si ID vide | confirme cause PH-20.15 |
| ClarityProvider.tsx L54 | if (!consentGranted) return null | gate consent opt-in | OK (comportement attendu) |
| ClarityProvider.tsx L57-63 | Script clarity.ms/tag/${ID} | injection inline IIFE | OK |
| Dockerfile L28/L41 | ARG + ENV NEXT_PUBLIC_CLARITY_PROJECT_ID | consomme le build-arg | OK (patch 2f684f9 deja en place) |

Aucun patch source necessaire : la source est intacte et correcte ; seul le build-arg manquait au build v0.6.21.

## 4. Build args (E2)

Liste exacte iso baseline saine v0.6.19 (PH-20.3) ; v0.6.21 (PH-20.10B) avait vide CLARITY + META + TIKTOK.

| Build arg | value | source | verdict |
|---|---|---|---|
| NEXT_PUBLIC_SITE_MODE | production | v0.6.19 + v0.6.21 | OK |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io | v0.6.19 + v0.6.21 | OK |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG | v0.6.19 + v0.6.21 | OK |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | v0.6.19 + v0.6.21 | OK |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | v0.6.19 (v0.6.21 = VIDE, restaure) | RESTAURE |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | v0.6.19 (v0.6.21 = VIDE, restaure) | RESTAURE |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | v0.6.19 + v0.6.21 | OK |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx | v0.6.19 (v0.6.21 = VIDE, cause incident) | RESTAURE (cible) |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact | v0.6.19 + v0.6.21 | OK |
| IMAGE_REVISION | 907689bf51678c4d97785d9316f21f03ea074f9f | HEAD full | OK (label OCI) |
| IMAGE_VERSION | v0.6.22-clarity-restore-prod | tag | OK (label OCI) |
| IMAGE_CREATED | 2026-05-26T19:19:54Z | UTC build | OK (label OCI) |

Aucun arg requis inconnu (tous documentes dans PH-20.3 / PH-20.10B).

## 5. Build (E3/E4/E5)

| Item | valeur |
|---|---|
| Worktree | /opt/keybuzz/build-worktrees/PH-20.15B (detache 907689b, porcelain=0) |
| Precheck | next build interne au stage builder Docker (pattern builds website ; exit 0) |
| Tag image | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod |
| Build exit code | 0 (Successfully built) |
| Warning build-arg non consomme | aucun |
| Image ID | sha256:619afbd95b82eca17f3fc7af0005ab5d7566b4e0835a7e096c11c49340841568 |
| OCI revision | 907689bf51678c4d97785d9316f21f03ea074f9f |
| OCI version | v0.6.22-clarity-restore-prod |
| OCI created | 2026-05-26T19:19:54Z |
| Push | AUCUN (build local uniquement) |

## 6. Bundle markers (E6)

Audit dans l'image (/app/.next), grep -rl (nb de fichiers).

| Marker | expected | result | verdict |
|---|---|---|---|
| wrff07upjx | present | 2 | OK (Clarity ID inline) |
| clarity.ms/tag | present | 2 | OK |
| ms-clarity / clarity-init | present | 2 | OK (script id) |
| NEXT_PUBLIC_CLARITY vide | absent | n/a (ID present) | OK |
| Meta pixel 1234164602194748 | present (iso v0.6.19) | 2 | RESTAURE |
| TikTok D7PT12JC77U44OJIPC10 | present (iso v0.6.19) | 2 | RESTAURE |
| GA G-R3QQDYEBFG | present | 18 | OK |
| CSS assets (.next/static/chunks/*.css) | present | 1 | OK |
| JS chunks | present | 17 | OK |
| api-dev.keybuzz leak | 0 | 0 | OK (pas de domaine DEV) |

Pattern identique au build sain v0.6.19 (Clarity wrff07upjx 2 occurrences). Le `clarity.ms/tag/` + variable est l'IIFE Clarity standard (ID `wrff07upjx` passe en argument runtime, present en literal a part).

## 7. No side-effect (E7)

| Signal | etat | verdict |
|---|---|---|
| GHCR tag v0.6.22 | ABSENT (non pousse) | OK |
| runtime website PROD | v0.6.21-pricing-action-recover-prod (inchange) | OK |
| manifests infra modifies | 0 | OK |
| kubectl apply / set / patch | aucun | OK |
| deploy | aucun | OK |
| fake Clarity event / pageview / conversion | aucun | OK |
| client.keybuzz.io | non touche (Clarity reste desactive, KEY-325) | OK |
| Amazon runtime / doublons | non touches (KEY-323 preserve) | OK |
| worktree | retire proprement (git worktree remove sans --force) | OK |

## 8. Rollback

| Niveau | action |
|---|---|
| Image locale | v0.6.22 locale uniquement ; supprimable via docker rmi sans impact runtime |
| Runtime PROD | reste v0.6.21-pricing-action-recover-prod (aucun changement) |
| GHCR | rien pousse ; aucun rollback registry necessaire |
| Promotion future | la phase apply (15D) conservera v0.6.21 comme rollback documente |

## 9. Prochaine phase

GO PUSH IMAGE WEBSITE CLARITY FIX PROD PH-SAAS-T8.12AS.20.15C : docker push de v0.6.22-clarity-restore-prod vers GHCR + verification digest (pull-back) ; puis GitOps apply PROD (15D) bump deployment website v0.6.21 -> v0.6.22 + rollout + QA consent (avant consent 0 requete, apres consent requete clarity.ms/tag/wrff07upjx) + nouveau recording AVEC CSS. Durcissement recommande : ajouter les build-args Clarity/Meta/TikTok au script de build website standard pour eviter une nouvelle perte silencieuse.

## 10. Phrase cible

GO BUILD WEBSITE CLARITY FIX PROD READY PH-SAAS-T8.12AS.20.15B

STOP.
