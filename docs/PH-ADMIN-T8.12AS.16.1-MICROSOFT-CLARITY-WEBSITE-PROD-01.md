# PH-ADMIN-T8.12AS.16.1-MICROSOFT-CLARITY-WEBSITE-PROD-01

> Date : 2026-05-15
> Linear : KEY-322 related. Parent AS.16.0 + AS.16.0.1 + AS.16.1 DEV
> Phase : T8.12AS.16.1-PROD (Microsoft Clarity website PROD activation)
> Environnement : PROD (www.keybuzz.pro + keybuzz.pro). DEV preserve.

---

## 0. VERDICT

GO CLARITY WEBSITE PROD ACTIVATED.

Microsoft Clarity active en PROD sur les surfaces marketing publiques keybuzz.pro + www.keybuzz.pro avec Project ID `wrff07upjx`. Consentement opt-in strict via CookieConsent banner v2. QA Ludovic confirmee : page charge sans erreur, banner Clarity visible, avant consent 0 requete clarity.ms, apres clic Accepter requete `clarity.ms/tag/wrff07upjx` visible, /cookies texte OK, GA4 + Meta + TikTok + LinkedIn preserves, aucune regression homepage.

Anti-regression cross-services PROD strictement preservee : Client, API, Admin v2, Backend tous inchanges. Website DEV (v0.6.13-clarity-website-dev no-op) preserve.

Un patch Dockerfile supplementaire a ete necessaire (commit `2f684f9` ajoutant `ARG NEXT_PUBLIC_CLARITY_PROJECT_ID` + `ENV NEXT_PUBLIC_CLARITY_PROJECT_ID=$NEXT_PUBLIC_CLARITY_PROJECT_ID` dans le stage builder) pour que Next.js consomme effectivement le build-arg cote bundle compile. Sans ce patch, l image PROD aurait ete techniquement identique au DEV no-op (warning Docker "build-arg not consumed" detecte au premier essai). Le patch a ete commit + push + re-build avant push GHCR.

KEY-322 reste Open. Aucun ticket Linear cree. Aucun token / secret expose. Aucun event Clarity fake (les sessions arrivent uniquement de visiteurs reels acceptant le consentement).

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.16.1-PROD activation) :
- 1 patch source supplementaire Dockerfile (commit `2f684f9` : ARG + ENV NEXT_PUBLIC_CLARITY_PROJECT_ID)
- 1 image GHCR build + pushed (v0.6.13-clarity-website-prod depuis commit 2f684f9)
- 1 manifest infra patche (k8s/website-prod/deployment.yaml)
- 1 kubectl apply + rollout website PROD
- 0 patch source code applicatif additionnel (ClarityProvider.tsx + CookieConsent v2 + /cookies + layout.tsx restent identiques a AS.16.1 DEV commit 29bafcf inclus dans 2f684f9)
- 0 patch Client / API / Admin / Backend
- 0 modification DEV
- 0 NEXT_PUBLIC_CLARITY_PROJECT_ID dans le manifest runtime (la valeur est inline au bundle au build time, non necessaire en env runtime)
- 0 ticket Linear cree
- 0 token / secret expose
- 0 mutation provider hors visiteurs reels post-consent

---

## 2. PREFLIGHT

### 2.1 Repos / commits

| Repo | Branche | HEAD avant AS.16.1-PROD | HEAD apres |
|---|---|---|---|
| keybuzz-website | main | 29bafcf (AS.16.1 source) | **2f684f9** (Dockerfile patche ARG/ENV Clarity) |
| keybuzz-infra | main | 1a91367 (AS.16.1 DEV rapport) | **6f5bc4b** (manifest PROD edit) |
| keybuzz-client | ph148/onboarding-activation-replay | 3fe90ab | 3fe90ab (inchange) |
| keybuzz-admin-v2 | main | 3707c83 | 3707c83 (inchange) |
| keybuzz-backend | main | b183817 | b183817 (inchange) |
| keybuzz-api | ph147.4/source-of-truth | 7a09c005 | 7a09c005 (inchange) |

### 2.2 Runtime PROD before/after

| Service | Avant AS.16.1-PROD | Apres AS.16.1-PROD |
|---|---|---|
| keybuzz-website PROD | v0.6.12-linkedin-insight-seo-prod | **v0.6.13-clarity-website-prod** (UPGRADED) |
| keybuzz-website DEV | v0.6.13-clarity-website-dev | v0.6.13-clarity-website-dev (UNCHANGED) |
| keybuzz-client PROD | v3.5.197-channels-bff-userauth-prod | v3.5.197-channels-bff-userauth-prod (UNCHANGED) |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod (UNCHANGED) |
| keybuzz-api PROD | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod (UNCHANGED) |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod (UNCHANGED) |

### 2.3 KEY-309 tag check

`docker manifest inspect ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-prod` avant build : `manifest unknown` = AVAILABLE.

---

## 3. DOCKERFILE PATCH (commit 2f684f9)

### 3.1 Necessite

Le premier build PROD (depuis commit 29bafcf) a renvoye un warning Docker :

```
[Warning] One or more build-args [NEXT_PUBLIC_CLARITY_PROJECT_ID] were not consumed
```

Cause : le Dockerfile keybuzz-website declare des `ARG NEXT_PUBLIC_*` + `ENV NEXT_PUBLIC_*=${...}` dans le stage `builder` pour chaque variable consommee par Next.js au build time (SITE_MODE, CLIENT_APP_URL, GA_ID, META_PIXEL_ID, SGTM_URL, TIKTOK_PIXEL_ID, LINKEDIN_PARTNER_ID). Aucune entree pour `NEXT_PUBLIC_CLARITY_PROJECT_ID`. Resultat : le build-arg fourni en CLI etait ignore, et Next.js compilait `process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID` comme `undefined` (= comportement DEV no-op).

### 3.2 Diff (commit 2f684f9)

```
+ # PH-ADMIN-T8.12AS.16.1 KEY-322 (2026-05-15): Microsoft Clarity Project ID,
+ # consumed by ClarityProvider only if consent accepted. Empty default = DEV no-op.
+ ARG NEXT_PUBLIC_CLARITY_PROJECT_ID=
  ENV NEXT_PUBLIC_SITE_MODE=${NEXT_PUBLIC_SITE_MODE}
  ...
  ENV NEXT_PUBLIC_LINKEDIN_PARTNER_ID=${NEXT_PUBLIC_LINKEDIN_PARTNER_ID}
+ ENV NEXT_PUBLIC_CLARITY_PROJECT_ID=${NEXT_PUBLIC_CLARITY_PROJECT_ID}

  RUN npm run build
```

Fichier touche : `Dockerfile`. Diff : +4 lignes (3 ARG block + 1 ENV).

Commit message :
```
feat(tracking): consume NEXT_PUBLIC_CLARITY_PROJECT_ID in Dockerfile (KEY-322 AS.16.1)
```

Push :
```
[main 2f684f9] feat(tracking): consume NEXT_PUBLIC_CLARITY_PROJECT_ID in Dockerfile (KEY-322 AS.16.1)
 1 file changed, 4 insertions(+)
To https://github.com/keybuzzio/keybuzz-website.git
   29bafcf..2f684f9  main -> main
```

### 3.3 Impact DEV

Le DEV image v0.6.13-clarity-website-dev (commit 29bafcf, Dockerfile sans patch) reste valide et fonctionnel en no-op intentionnel. Pas de re-build DEV necessaire car :
- `NEXT_PUBLIC_CLARITY_PROJECT_ID` est volontairement absent du build DEV
- ClarityProvider retourne null faute de variable -> no-op preserve
- Le manque de ARG/ENV dans le Dockerfile 29bafcf n affecte pas le DEV (silently ignored)

Pour la coherence des futurs builds DEV, le Dockerfile patch (commit 2f684f9) sera utilise automatiquement.

---

## 4. BUILD WEBSITE PROD (depuis commit 2f684f9)

### 4.1 Configuration

| Champ | Valeur |
|---|---|
| Tag | v0.6.13-clarity-website-prod |
| Branche | main |
| Commit source | 2f684f9 (full: 2f684f9961514406aad1c67274ec809ff1a08733) |
| Image ID | sha256:0724925773b4bd00db4a0cf3818b6eefc036e90bf2dd56a68ae9848454e959b4 |
| Manifest digest GHCR | sha256:b8daaf3a916a809138bf50f3df5d751f82da2c3125130a3118d876337076dda7 |

Build args :
- `NEXT_PUBLIC_SITE_MODE=production`
- `NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io`
- `NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx` (PROD activation)
- `IMAGE_REVISION=2f684f9961514406aad1c67274ec809ff1a08733`
- `IMAGE_CREATED=2026-05-15T11:46:54Z`
- `IMAGE_VERSION=v0.6.13-clarity-website-prod`

Aucun warning Docker build cette fois (Dockerfile consomme correctement le ARG). Step count 51/51 (vs 49/49 avant patch).

### 4.2 KEY-308 OCI labels

| Label | Valeur |
|---|---|
| org.opencontainers.image.created | 2026-05-15T11:46:54Z |
| org.opencontainers.image.revision | 2f684f9961514406aad1c67274ec809ff1a08733 |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website |
| org.opencontainers.image.title | keybuzz-website |
| org.opencontainers.image.version | v0.6.13-clarity-website-prod |

### 4.3 KEY-302 bundle check PROD

| Verification | Resultat | Attendu | Verdict |
|---|---|---|---|
| `api.keybuzz.io` (PROD URL) | 2 occurrences | PRESENT | OK |
| `api-dev.keybuzz.io` (DEV URL) | 0 occurrences | ABSENT | OK |
| `wrff07upjx` (PROD Project ID) | 2 occurrences | PRESENT (activation) | OK |
| `clarity.ms` (Microsoft script URL) | 2 occurrences | PRESENT (inline) | OK |
| `ClarityProvider` (code compile) | 15 occurrences | PRESENT | OK |

Verification differentiation DEV vs PROD :
- DEV bundle (commit 29bafcf, no-op) : `wrff07upjx` = 0 occurrences (absent)
- PROD bundle (commit 2f684f9, activation) : `wrff07upjx` = 2 occurrences (present)

---

## 5. DOCKER PUSH PROD

| Reference | Valeur |
|---|---|
| Tag pushed | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-prod |
| Manifest digest GHCR (pull) | sha256:b8daaf3a916a809138bf50f3df5d751f82da2c3125130a3118d876337076dda7 |
| Config digest (Image ID) | sha256:0724925773b4bd00db4a0cf3818b6eefc036e90bf2dd56a68ae9848454e959b4 |
| Size manifest | 2619 bytes |

---

## 6. GITOPS PROD APPLY

### 6.1 Manifest patche

| Manifest | Ligne | Avant | Apres |
|---|---|---|---|
| k8s/website-prod/deployment.yaml | 36 | image v0.6.12-linkedin-insight-seo-prod | image v0.6.13-clarity-website-prod + digest comment + rollback note |

Diff scope : 1 fichier, 1 ligne (+1/-1). Aucune env var `CLARITY` ajoutee dans le manifest runtime (la valeur est inline dans le bundle au build time).

### 6.2 Commit + push

```
[main 6f5bc4b] deploy(prod): Clarity website PROD activation (KEY-322 AS.16.1)
 1 file changed, 1 insertion(+), 1 deletion(-)
To https://github.com/keybuzzio/keybuzz-infra.git
   1a91367..6f5bc4b  main -> main
```

### 6.3 Apply + rollout

```
deployment.apps/keybuzz-website configured
service/keybuzz-website unchanged
namespace/keybuzz-website-prod unchanged
Waiting for deployment "keybuzz-website" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-website" successfully rolled out
```

Deployment a 2 replicas (HA). Rolling update progressif : 2 nouveaux pods up + 1 ancien terminate.

### 6.4 Triple-egalite post-rollout

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-prod |
| metadata last-applied-configuration | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-prod |
| pod imageID (x2 nouveaux pods) | ghcr.io/keybuzzio/keybuzz-website@sha256:b8daaf3a916a809138bf50f3df5d751f82da2c3125130a3118d876337076dda7 |
| GHCR manifest digest | sha256:b8daaf3a916a809138bf50f3df5d751f82da2c3125130a3118d876337076dda7 |

Convergence : MATCH. Deployment status ready=2/2, updated=2, available=2.

### 6.5 Anti-regression cross-service

| Service | Image | Statut |
|---|---|---|
| keybuzz-website DEV | v0.6.13-clarity-website-dev | UNCHANGED (no-op preserve) |
| keybuzz-client DEV | v3.5.197-channels-bff-userauth-dev | UNCHANGED |
| keybuzz-client PROD | v3.5.197-channels-bff-userauth-prod | UNCHANGED |
| keybuzz-api PROD | v3.5.190-channels-tenantguard-prod | UNCHANGED |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

---

## 7. QA LUDOVIC PROD

Confirmation Ludovic post-apply (navigateur + DevTools Network) :

| Verif | Resultat |
|---|---|
| https://www.keybuzz.pro charge sans erreur | OK |
| https://keybuzz.pro charge sans erreur | OK |
| CookieConsent v2 affiche avec mention Microsoft Clarity | OK |
| AVANT consent : 0 requete vers clarity.ms (Network DevTools) | OK |
| APRES clic Accepter : requete clarity.ms/tag/wrff07upjx visible | OK |
| /cookies texte mentionne Microsoft Clarity (section 2.2 + tableau + section 5) | OK |
| GA4 + Meta + TikTok + LinkedIn Insight Tag continuent de fonctionner | OK |
| Homepage : aucune regression visible (navbar, footer, hero, pricing CTA, IntroSplash) | OK |
| Session arrive ou en attente propagation dashboard Microsoft Clarity (~minutes) | OK / pending propagation |

---

## 8. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 session Clarity fake creee (script charge uniquement apres consentement reel utilisateur)
- 0 trafic fake genere par AS.16.1-PROD
- 0 modification destinations / delivery_logs / signup_attribution
- 0 token / secret affiche dans rapport ou chat
- 0 PII / payload sensible
- 0 modification DB
- 0 mutation provider Meta / TikTok / LinkedIn / GA4 (Clarity est independant des autres providers)
- Project ID `wrff07upjx` mentionne (PUBLIC par design Microsoft, pas un secret)

---

## 9. ANTI-REGRESSION INBOX / BROUILLON IA / TENANT SWITCHER / ESCALATION

Aucune regression possible : AS.16.1-PROD ne touche que keybuzz-website. Le Client (client.keybuzz.io) reste sur v3.5.197-channels-bff-userauth-prod sans changement. Clarity n est PAS injecte sur client.keybuzz.io (decision design : AS.16.2 future, pas AS.16.1).

| Surface | Risque AS.16.1-PROD | Resultat |
|---|---|---|
| Inbox messages | aucun (Client unchanged) | preserve |
| Brouillon IA | aucun (Client unchanged) | preserve |
| Tenant switcher | aucun (Client unchanged) | preserve |
| Escalation | aucun (Client unchanged) | preserve |
| Playbooks | aucun | preserve |
| Channels | aucun | preserve |
| Admin v2 | aucun (Admin unchanged) | preserve |

---

## 10. NON-REGRESSION (avant / apres AS.16.1-PROD)

| Service | Image PROD avant | Image PROD apres | Verdict |
|---|---|---|---|
| keybuzz-website | v0.6.12-linkedin-insight-seo-prod | v0.6.13-clarity-website-prod | UPGRADED (intentionnel) |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod | v3.5.197-channels-bff-userauth-prod | UNCHANGED |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-api | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | UNCHANGED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

DEV inchange (website DEV v0.6.13-clarity-website-dev no-op preserve).

---

## 11. ROLLBACK READY

Plan rollback PROD (si necessaire dans le futur) :

```
cd /opt/keybuzz/keybuzz-infra
git revert 6f5bc4b
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl -n keybuzz-website-prod rollout status deploy/keybuzz-website --timeout=240s
```

Resultat attendu : retour website PROD a v0.6.12-linkedin-insight-seo-prod (digest sha256:22bd41d5fcc482a397b017c4d10d64ded9947d6f1bc5881994ed76668d38ff49 visible dans pods historique). Image v0.6.13 reste sur GHCR mais non-applied.

Cote Microsoft Clarity dashboard : les sessions deja collectees restent visibles dans le dashboard `wrff07upjx`. Si rollback total cote Microsoft requis, Ludovic peut supprimer/archiver le Project Clarity manuellement.

Aucun rollback necessaire post-activation : 0 regression, QA Ludovic OK.

---

## 12. LINEAR (commentaire propose KEY-322)

```
PH-ADMIN-T8.12AS.16.1-PROD Microsoft Clarity website PROD activation livre.

Verdict : GO CLARITY WEBSITE PROD ACTIVATED.

Build :
- Image v0.6.13-clarity-website-prod from-git commit 2f684f9 (Dockerfile patche pour consommer NEXT_PUBLIC_CLARITY_PROJECT_ID via ARG + ENV pattern)
- Build-args : NEXT_PUBLIC_SITE_MODE=production, NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io, NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx
- KEY-308 OCI labels complets (revision full SHA, created ISO UTC, version, source, title)
- KEY-302 bundle check PROD : api.keybuzz.io PRESENT (2), api-dev.keybuzz.io ABSENT (0), wrff07upjx PRESENT (2 - PROD activation confirmee), clarity.ms PRESENT (URL Microsoft inline), ClarityProvider PRESENT (15)

Patch Dockerfile (commit 2f684f9) :
- Premier build a renvoye warning "[Warning] One or more build-args [NEXT_PUBLIC_CLARITY_PROJECT_ID] were not consumed"
- Cause : Dockerfile manquait ARG NEXT_PUBLIC_CLARITY_PROJECT_ID + ENV NEXT_PUBLIC_CLARITY_PROJECT_ID=$NEXT_PUBLIC_CLARITY_PROJECT_ID dans stage builder
- Fix : +4 lignes ajoutees au Dockerfile (commit 2f684f9), re-build PROD depuis nouveau commit
- Impact DEV : aucun (DEV reste sur commit 29bafcf no-op, fonctionne car CLARITY_PROJECT_ID volontairement absent)

GitOps PROD :
- Commit manifest e985168..6f5bc4b infra deploy(prod): Clarity website PROD activation
- kubectl apply, rollout OK 2/2 replicas (HA)
- Triple-egalite spec=last-applied=podImageID=GHCR digest sha256:b8daaf3a916a809138bf50f3df5d751f82da2c3125130a3118d876337076dda7

Validation PROD :
- QA Ludovic navigateur https://www.keybuzz.pro + https://keybuzz.pro : OK
- CookieConsent v2 affiche mention Microsoft Clarity
- AVANT consent : 0 requete clarity.ms (opt-in strict respecte)
- APRES clic Accepter : requete clarity.ms/tag/wrff07upjx visible (activation confirmee)
- /cookies texte OK (section 2.2 + tableau analytics + section 5)
- GA4 + Meta + TikTok + LinkedIn Insight Tag continuent fonctionner
- Session arrive ou en attente propagation Microsoft Clarity dashboard
- Aucune regression visible homepage

Anti-regression PROD : 5 services preserves (client, api, admin v2, backend, website DEV inchanges).

Hygiene :
- 0 Clarity session fake
- 0 token / secret expose
- 0 PII
- 0 mutation provider hors visiteurs reels post-consent
- 0 ticket Linear cree
- 0 changement Linear statut

Project ID wrff07upjx est PUBLIC par design Microsoft Clarity (mentionnable sans risque secret).

Decisions architecturales (AS.16.0.1) respectees :
- 1 Project ID PROD commun keybuzz.pro + www.keybuzz.pro (meme audience marketing)
- Opt-in strict via CookieConsent banner v2
- /cookies texte mis a jour (deja inclus dans le commit 29bafcf, promu en PROD avec le build)
- Compatible avec ajouts homepage futurs (CTA + Reviews captures automatiquement)

Prochaines phases optionnelles :
- AS.16.2 client.keybuzz.io funnel pre-auth Clarity (decision Project ID separe ou commun a prendre)
- AS.16.3 verification exclusion stricte Client authenticated + Admin v2
- AS.16.4 agency handoff docs MEDIA-BUYER-TRACKING-GUIDE

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause AS.14.2.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.16.1-MICROSOFT-CLARITY-WEBSITE-PROD-01.md
```

Aucun changement Linear statut.

---

## 13. PROCHAINES PHASES PROPOSEES

| Phase | Statut | Pre-requis |
|---|---|---|
| AS.16.1 DEV | LIVRE (commit 1a91367 rapport) | n/a |
| **AS.16.1 PROD** | **LIVRE (ce rapport)** | n/a |
| AS.16.2 client funnel | DEFERRED | Decision Project ID (commun PROD ou separe) + GO Ludovic |
| AS.16.3 exclusion verification | DEFERRED | Apres AS.16.2 |
| AS.16.4 agency docs | DEFERRED | Apres AS.16.3 |

---

## 14. GAPS / FOLLOW-UP

| Gap | Statut |
|---|---|
| DEV reste sur commit 29bafcf (sans Dockerfile patch) | Acceptable : DEV no-op, pas besoin de re-build |
| Propagation initiale Microsoft Clarity dashboard | Normal (~minutes a quelques heures pour les 1eres sessions) |
| Cross-domain Clarity keybuzz.pro <-> client.keybuzz.io | DEFERRED a AS.16.2 (decision Project ID commun ou separe) |
| Categorisation granulaire RGPD 3eme categorie (analytics vs session replay) | NOTED hors scope (pattern binaire CookieConsent conserve) |

Aucun gap bloquant.

---

## 15. PHRASE CIBLE FINALE

Microsoft Clarity active en PROD sur keybuzz.pro + www.keybuzz.pro avec Project ID wrff07upjx, opt-in strict via CookieConsent v2. Dockerfile patche (commit 2f684f9) pour consommation propre du build-arg. Triple-egalite spec=last-applied=podImageID=GHCR digest sha256:b8daaf3a916a8091.... QA Ludovic confirme : avant consent 0 requete, apres consent requete clarity.ms/tag/wrff07upjx. Anti-regression : 5 services PROD strictement inchanges (Client, API, Admin v2, Backend, Website DEV). KEY-322 reste Open. Aucun enchainement AS.16.2 sans GO Ludovic explicite + decision Project ID client funnel.

STOP
