# PH-SAAS-T8.12AS.20.15F-READONLY-CLIENT-CLARITY-STATUS-AUDIT-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; KEY-325 client Clarity ; KEY-339 client funnel tracking
> Phase : PH-SAAS-T8.12AS.20.15F (READONLY CLIENT CLARITY STATUS AUDIT)
> Environnement : PROD (lecture seule ; aucun patch/build/deploy/fake event)

## 1. Verdict

GO READONLY CLIENT CLARITY STATUS AUDIT READY PH-SAAS-T8.12AS.20.15F

CURRENT_STATUS = ABSENT_REGRESSION. Preuve : client.keybuzz.io PROD a EU Microsoft Clarity ACTIF (project ID client distinct wuk12h9i33, funnel-only) du 2026-05-21 13:27 UTC (deploy v3.5.200-clarity-register-prod, PH-20.2/KEY-339) au 2026-05-22 00:45 UTC (deploy v3.5.201-register-polish-prod, PH-20.6C) ou le build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID a ete OMIS -> Clarity dead-code-elimine. Tous les builds client PROD suivants (jusqu'au runtime actuel v3.5.215-ai-draft-blocked-reason-prod) sont sortis sans le build-arg -> Clarity absent depuis ~2026-05-22. Live client.keybuzz.io/register : 0 clarity.ms/tag, 0 ms-clarity. Ludovic a raison : client.keybuzz.io etait bien enregistre/actif dans Clarity (wuk12h9i33). C'est une regression (meme footgun NEXT_PUBLIC build-arg que website v0.6.21 PH-20.15), PAS l'etat "jamais active / KEY-325 differe" annonce a tort en PH-20.15/D/E (correction explicite ci-dessous). Fix minimal = rebuild client PROD avec --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33. Aucun patch source. Microsoft dashboard non requis pour trancher (preuve git+build). Aucun fake event.

## 2. Correction d'une affirmation anterieure

En PH-20.15, PH-20.15D et PH-20.15E le CE a ecrit "client.keybuzz.io n'a jamais eu Clarity active (KEY-325 differe)". CETTE AFFIRMATION ETAIT FAUSSE. Elle reposait sur les notes KEY-325 (phases AS.19.x register CRO, AVANT activation) sans croiser PH-20.2/KEY-339 qui a active Clarity client. La verite etablie par preuves : Clarity client a ete active en PROD (v3.5.200) puis perdu par regression de build (v3.5.201). Les conclusions website de PH-20.15 a 15E restent valides (website = wrff07upjx, separe).

## 3. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 20:14.

| Repo/service | branch/runtime | HEAD/image | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | ef239e8 = origin | clean (hors tsbuildinfo) | OK |
| keybuzz-infra | main | (post 15E) | clean | OK |
| runtime client PROD | v3.5.215-ai-draft-blocked-reason-prod | - | ready | Clarity absent |
| runtime client DEV | v3.5.214-ai-draft-blocked-reason-dev | - | ready | a verifier (hors scope strict PROD) |

## 4. Live audit client.keybuzz.io (E1)

| Check | result | verdict |
|---|---|---|
| GET / | HTTP 307 -> /auth/signin | login gate (attendu) |
| GET /register (funnel public) | HTTP 200 | OK |
| wrff07upjx (mauvais ID, website) dans bundle | 0 | n/a (ID website) |
| clarity.ms/tag dans bundle /register | 0 | Clarity ABSENT |
| ms-clarity / clarity init | 0 | Clarity ABSENT |
| data-clarity-mask | present (masques PII en place) | provisionne |

## 5. Source audit keybuzz-client (E2)

| File | occurrence | interpretation | verdict |
|---|---|---|---|
| src/components/tracking/SaaSAnalytics.tsx | const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID \|\| '' ; route-gated funnel-only (shouldLoad = !isBlockedPage && isFunnelPage && (... \|\| CLARITY_PROJECT_ID)) ; Script id=ms-clarity | provisionne, no-op si ID vide | source OK, intacte |
| data-clarity-mask | sur 13 inputs PII (register) | masquage PII pret | OK |

Source intacte : aucun patch necessaire pour reactiver, seul le build-arg manque.

## 6. Build / manifests audit client (E3)

| Source | setting | value/source | verdict |
|---|---|---|---|
| client Dockerfile | ARG + ENV NEXT_PUBLIC_CLARITY_PROJECT_ID= (defaut vide) | consomme le build-arg (patch PH-20.2) | mecanisme OK |
| build v3.5.200-clarity-register-prod (PH-20.2-PROD) | NEXT_PUBLIC_CLARITY_PROJECT_ID = wuk12h9i33 | bundle Clarity actif (wuk12h9i33=1, clarity.ms=1, ms-clarity=1) | Clarity ON |
| build v3.5.201-register-polish-prod (PH-20.6C) | NEXT_PUBLIC_CLARITY_PROJECT_ID = (vide/omis) | Clarity dead-code-elimine | Clarity OFF (debut regression) |
| builds suivants -> v3.5.215 (runtime actuel) | clarity vide | Clarity absent | OFF persistant |
| manifest runtime env client-prod | aucune var CLARITY | non pertinent (NEXT_PUBLIC inline au build) | - |

Deploys GitOps (k8s/keybuzz-client-prod/deployment.yaml) : 13175da deploy v3.5.200 (2026-05-21 13:27 UTC, Clarity ON) -> b472c54 deploy v3.5.201 (2026-05-22 00:45 UTC, Clarity OFF). Fenetre active Clarity client PROD ~ 11h.

## 7. Historical docs / Linear (E4)

| Document/ticket | claim | evidence | verdict |
|---|---|---|---|
| PH-20.2-CLARITY-CLIENT-REGISTER-BUILD/APPLY-PROD (KEY-339) | client Clarity active wuk12h9i33 | bundle + deploy v3.5.200 confirmes | ACTIVE confirme |
| KEY-325 (AS.19.x register CRO) | "Clarity client NON activee, data-clarity-mask only" | etat AVANT activation (masques poses, ID pas encore fourni) | etat anterieur, perime depuis PH-20.2 |
| AS.16.0.1 decision #6 | project ID client meme ou separe = defere AS.16.2 | PH-20.2/KEY-339 a tranche : ID separe wuk12h9i33 | tranche |
| PH-20.6C BUILD-PROD | clarity vide (v3.5.201) | regression confirmee | regression |

## 8. Microsoft dashboard handoff (E5)

Non requis pour trancher le statut (preuve git+build+live suffit). Confirmation OPTIONNELLE par Ludovic dans Microsoft Clarity : projet wuk12h9i33 -> Settings/Setup domaine client.keybuzz.io ; les recordings client devraient montrer des sessions ~2026-05-21 13:27 -> 2026-05-22 00:45 UTC puis ARRET (coherent avec la regression). Ne pas se connecter cote CE.

## 9. RCA / decision (E6)

CURRENT_STATUS : ABSENT_REGRESSION (haute confiance).
- Cause : build client PROD v3.5.201 (PH-20.6C, 2026-05-22) et suivants omettent --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33 ; ClarityProvider/SaaSAnalytics no-op si ID vide ; footgun NEXT_PUBLIC identique a website v0.6.21.
- Project IDs : website = wrff07upjx (restaure PH-20.15D) ; client = wuk12h9i33 (SEPARE, a restaurer).
- Fix minimal (phase ulterieure, GO requis) : rebuild client PROD from-git (HEAD courant ph148) AVEC --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33 + tous les autres build-args client PROD iso baseline courante (NEXT_PUBLIC_APP_ENV=production, API_URL/API_BASE_URL=https://api.keybuzz.io, LINKEDIN_PARTNER_ID=9969977, etc.) ; aucun patch source. Puis push + GitOps apply + QA consent funnel (clarity.ms/tag/wuk12h9i33 200 sur /register apres consent).
- Durcissement : ajouter NEXT_PUBLIC_CLARITY_PROJECT_ID (client wuk12h9i33 + website wrff07upjx + Meta/TikTok) au script de build standard des deux repos.

Prochaine phase recommandee : GO BUILD CLIENT CLARITY RESTORE PROD PH-SAAS-T8.12AS.20.15G (rebuild client avec wuk12h9i33), puis PUSH (15H) + APPLY (15I), schema identique a website 15B/C/D. Decision produit prealable : confirmer que la reactivation Clarity client funnel est souhaitee maintenant (etait active jusqu'au 2026-05-22, donc reactivation = retour a l'etat voulu, pas nouvelle feature).

## 10. No fake metrics / no fake events (E7)

| Garantie | etat |
|---|---|
| fake Clarity event / pageview / session | 0 |
| synthetic conversion | 0 |
| consent force | 0 |
| analytics backfill | 0 |
| trafic artificiel | 0 (curl read-only ponctuel) |
| patch / build / deploy / kubectl | 0 (lecture seule) |

## 11. Anti-regression

| Garantie | etat |
|---|---|
| website keybuzz.pro Clarity wrff07upjx | preserve (PH-20.15D, runtime v0.6.22, non touche) |
| KEY-323 Amazon ecomlg-001 FR | preserve |
| doublons Amazon | differes (PH-20.16) |
| client/API/backend runtime | non touches (lecture seule) |

## 12. Phrase cible

GO READONLY CLIENT CLARITY STATUS AUDIT READY PH-SAAS-T8.12AS.20.15F

STOP.
