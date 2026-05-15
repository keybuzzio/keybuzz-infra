# PH-ADMIN-T8.12AS.16.1-MICROSOFT-CLARITY-WEBSITE-DEV-01

> Date : 2026-05-15
> Linear : KEY-322 related. Parent design audit AS.16.0 (commit 9c4f843) + decisions AS.16.0.1 (commit 59a66b4)
> Phase : T8.12AS.16.1 (Microsoft Clarity website DEV first, no-op mode)
> Environnement : DEV (preview.keybuzz.io). PROD strictement inchangee.

---

## 0. VERDICT

GO CLARITY WEBSITE DEV NO-OP READY.

Implementation Clarity website livree en DEV sans charger le script Clarity (mode no-op intentionnel). Le ClarityProvider est compile dans le bundle DEV mais retourne null car `NEXT_PUBLIC_CLARITY_PROJECT_ID` n est volontairement pas defini dans le manifest DEV. QA Ludovic confirmee : page preview.keybuzz.io charge sans erreur, bandeau CookieConsent v2 affiche le nouveau texte mentionnant Microsoft Clarity, politique /cookies mise a jour, DevTools Network 0 requete vers clarity.ms, wrff07upjx (PROD ID) absent du bundle.

L architecture est anti-regression compatible : Client/API/Admin/Backend strictement inchanges. Website PROD inchange (v0.6.12-linkedin-insight-seo-prod). DEV runtime promu en v0.6.13-clarity-website-dev avec triple-egalite confirmee.

Prochaine etape : AS.16.1-PROD activation Clarity avec Project ID `wrff07upjx` apres GO Ludovic explicite (mise a jour /cookies texte deja faite cote source, sera promue en meme temps).

KEY-322 reste Open. Aucun ticket Linear cree. Aucun event Clarity fake declenche. Aucun trafic capture.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.16.1 DEV first, no-op mode) :
- 4 fichiers code source patches dans keybuzz-website (commit 29bafcf)
- 1 image GHCR construite + pushed (v0.6.13-clarity-website-dev)
- 1 manifest infra modifie (k8s/website-dev/deployment.yaml)
- 1 kubectl apply + rollout DEV website uniquement
- 0 patch Client, 0 patch Admin, 0 patch API, 0 patch Backend
- 0 modification PROD (website, client, admin, api, backend)
- 0 NEXT_PUBLIC_CLARITY_PROJECT_ID env var ajoutee (no-op DEV intentionnel)
- 0 script Microsoft charge en runtime DEV (verifie DevTools Network)
- 0 session Clarity creee
- 0 ticket Linear cree
- 0 secret modifie
- 0 token expose

---

## 2. PREFLIGHT

### 2.1 SSH + bastion

| Champ | Valeur |
|---|---|
| Alias | install-v3 |
| IP | 46.62.171.61 (conforme, pas 51.159.99.247) |

### 2.2 Repos

| Repo | Branche | HEAD avant | HEAD apres | Verdict |
|---|---|---|---|---|
| keybuzz-website | main | 660dc60 | 29bafcf | OK |
| keybuzz-infra | main | 9c4f843 (AS.16.0) | e985168 (AS.16.1 manifest) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 3fe90ab | 3fe90ab (inchange) | OK |
| keybuzz-admin-v2 | main | 3707c83 | 3707c83 (inchange) | OK |
| keybuzz-backend | main | b183817 | b183817 (inchange) | OK |
| keybuzz-api | ph147.4/source-of-truth | 7a09c005 | 7a09c005 (inchange) | OK |

### 2.3 Runtime images

| Service | DEV | PROD |
|---|---|---|
| keybuzz-website | **v0.6.13-clarity-website-dev** (NEW) | v0.6.12-linkedin-insight-seo-prod (UNCHANGED) |
| keybuzz-client | v3.5.197-channels-bff-userauth-dev | v3.5.197-channels-bff-userauth-prod |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod |
| keybuzz-api | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-prod |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod |

---

## 3. PATCH SOURCE (4 fichiers, commit 29bafcf)

### 3.1 Diff stat

```
src/app/cookies/page.tsx           | 37 ++++++++++++++-------
src/app/layout.tsx                 |  2 ++
src/components/ClarityProvider.tsx | 67 ++++++++++++++++++++++++++++++++++++++
src/components/CookieConsent.tsx   | 16 +++++----
4 files changed, 104 insertions(+), 18 deletions(-)
```

### 3.2 NOUVEAU - src/components/ClarityProvider.tsx (+67 lignes)

Composant React `'use client'` mount au layout racine. Logique :
- Lit `NEXT_PUBLIC_CLARITY_PROJECT_ID` au build time
- Lit `keybuzz_cookie_consent` localStorage au mount (et listen storage event)
- Fallback no-op si Project ID absent (cas DEV par defaut)
- Consent gate : retourne null si status != "accepted"
- Inject Microsoft Clarity official snippet via `<Script strategy="afterInteractive">`

Pattern aligne sur Analytics.tsx existant (Script next/script, env var driven).

### 3.3 UPDATE - src/components/CookieConsent.tsx (+13/-7 lignes)

| Changement | Avant | Apres |
|---|---|---|
| CONSENT_VERSION | "1" | "2" (force re-display banner) |
| Texte banner | "aucun cookie de mesure d'audience n est actif" | mentionne Microsoft Clarity + heatmaps + session replay + opt-in strict 12 mois |

Pattern binaire conserve (accepted / refused). Pas de 3eme categorie granulaire (decision design AS.16.1 : reuser le pattern existant pour minimiser scope, categorisation granulaire potentielle en AS.16.x dedie ulterieurement).

### 3.4 UPDATE - src/app/layout.tsx (+2 lignes)

```typescript
import ClarityProvider from "@/components/ClarityProvider";  // ajout import
...
<Analytics />
<ClarityProvider />  // ajout mount apres Analytics
```

### 3.5 UPDATE - src/app/cookies/page.tsx (+25/-12 lignes)

3 zones de la politique cookies mises a jour :
- Section 2.2 : remplace "aucun outil tiers n est actif" par mention Microsoft Clarity (description + masquage champs sensibles + exclusion pages authentifiees)
- Tableau cookies analytics : remplace "Aucun actuellement" par row "Microsoft Clarity" avec domaines keybuzz.pro + www.keybuzz.pro
- Section 5 cookies tiers : ajoute mention Microsoft Clarity + lien externe vers politique de confidentialite Microsoft

### 3.6 Commit + push

```
[main 29bafcf] feat(tracking): Clarity website DEV (KEY-322 AS.16.1)
 4 files changed, 104 insertions(+), 18 deletions(-)
 create mode 100644 src/components/ClarityProvider.tsx
To https://github.com/keybuzzio/keybuzz-website.git
   660dc60..29bafcf  main -> main
```

---

## 4. BUILD WEBSITE DEV

### 4.1 Strategy

Pas de script `build-website-from-git.sh` dedie existant. Build manuel inline avec pattern :
- Fresh git clone `/tmp/keybuzz-website-build-as161` depuis main commit 29bafcf
- Verify HEAD matche commit attendu + git status clean
- Docker build `--no-cache` avec build-args + OCI labels
- Cleanup clone dir apres build

### 4.2 Configuration build

| Champ | Valeur |
|---|---|
| Tag | v0.6.13-clarity-website-dev |
| Branche source | main |
| Commit source | 29bafcf (full: 29bafcfbba0a5f731dcd37b62944e25b1deab36a) |
| Image ID | sha256:7005860732aeb3c983c817a5259e7ade0eda53995e5ac514d878eaafa8c969e2 |
| Manifest digest GHCR | sha256:57318f5dec7590faa45ec782d1981f51953d7b9f8be24794bb6482a1d2d0acd7 |

Build args :
- `NEXT_PUBLIC_SITE_MODE=preview`
- `NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io`
- `IMAGE_REVISION=29bafcfbba0a5f731dcd37b62944e25b1deab36a`
- `IMAGE_CREATED=2026-05-15T11:10:53Z`
- `IMAGE_VERSION=v0.6.13-clarity-website-dev`

**INTENTIONNEL** : aucune build-arg `NEXT_PUBLIC_CLARITY_PROJECT_ID` (no-op DEV).

### 4.3 KEY-308 OCI labels conformes

| Label | Valeur |
|---|---|
| org.opencontainers.image.created | 2026-05-15T11:10:53Z |
| org.opencontainers.image.revision | 29bafcfbba0a5f731dcd37b62944e25b1deab36a |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website |
| org.opencontainers.image.title | keybuzz-website |
| org.opencontainers.image.version | v0.6.13-clarity-website-dev |

### 4.4 KEY-302 bundle check (DEV no-op verification)

| Check | Resultat |
|---|---|
| `wrff07upjx` (Project ID PROD) | **0** occurrences (CONFIRME : pas de leak PROD ID en DEV) |
| `ClarityProvider` (code compile present) | 15 occurrences |
| `clarity.ms` (URL Microsoft) | 2 occurrences (presentes dans le snippet inline, mais code path INACTIF tant que CLARITY_PROJECT_ID env var absente au runtime) |

Pourquoi `clarity.ms` peut apparaitre 2 fois sans risque :
- Le composant ClarityProvider contient le snippet Microsoft Clarity inline
- Next.js compile le JSX du return statement dans le bundle, meme si le code path est conditionnel sur `CLARITY_PROJECT_ID`
- Au runtime, `process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID` est compile a `undefined` par Next.js (car non passe en build-arg)
- ClarityProvider s execute, fait `if (!CLARITY_PROJECT_ID) return null` -> court-circuite AVANT le `<Script>` tag
- Le `<Script>` n est donc JAMAIS injecte dans le DOM en DEV
- Verification finale par DevTools Network : 0 requete vers clarity.ms (QA Ludovic confirmee)

---

## 5. DOCKER PUSH DEV

| Reference | Valeur |
|---|---|
| Tag pushed | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-dev |
| Manifest digest GHCR (pull) | sha256:57318f5dec7590faa45ec782d1981f51953d7b9f8be24794bb6482a1d2d0acd7 |
| Config digest (Image ID) | sha256:7005860732aeb3c983c817a5259e7ade0eda53995e5ac514d878eaafa8c969e2 |
| Size manifest | 2619 bytes |

---

## 6. GITOPS DEV APPLY

### 6.1 Manifest patche

| Manifest | Ligne | Avant | Apres |
|---|---|---|---|
| k8s/website-dev/deployment.yaml | 23 | image v0.6.12-linkedin-insight-seo-dev | image v0.6.13-clarity-website-dev + digest comment + rollback note |

Diff scope : 1 fichier, 1 ligne (+1/-1). Aucune env var `CLARITY` ajoutee dans le manifest (no-op intentionnel).

### 6.2 Commit + push

```
[main e985168] deploy(dev): Clarity website opt-in DEV no-op (KEY-322 AS.16.1)
 1 file changed, 1 insertion(+), 1 deletion(-)
To https://github.com/keybuzzio/keybuzz-infra.git
   59a66b4..e985168  main -> main
```

### 6.3 Apply + rollout

```
deployment.apps/keybuzz-website configured
Waiting for deployment "keybuzz-website" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-website" successfully rolled out
```

### 6.4 Triple-egalite

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-dev |
| metadata last-applied-configuration | ghcr.io/keybuzzio/keybuzz-website:v0.6.13-clarity-website-dev |
| pod imageID (active) | ghcr.io/keybuzzio/keybuzz-website@sha256:57318f5dec7590faa45ec782d1981f51953d7b9f8be24794bb6482a1d2d0acd7 |
| GHCR manifest digest | sha256:57318f5dec7590faa45ec782d1981f51953d7b9f8be24794bb6482a1d2d0acd7 |

Convergence : MATCH. Pod actif `keybuzz-website-6dc9bbdf84-z6trm` Running, READY=1/1, RESTARTS=0.

### 6.5 Anti-regression cross-service

| Service | Image | Statut |
|---|---|---|
| keybuzz-website PROD | v0.6.12-linkedin-insight-seo-prod | UNCHANGED |
| keybuzz-client DEV | v3.5.197-channels-bff-userauth-dev | UNCHANGED |
| keybuzz-client PROD | v3.5.197-channels-bff-userauth-prod | UNCHANGED |
| keybuzz-api PROD | v3.5.190-channels-tenantguard-prod | UNCHANGED |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

---

## 7. QA LUDOVIC DEV (preview.keybuzz.io)

Confirmation Ludovic post-apply (QA navigateur + DevTools) :

| Verif | Resultat |
|---|---|
| Page preview.keybuzz.io charge sans erreur | OK |
| Bandeau CookieConsent v2 affiche | OK (texte mentionne Microsoft Clarity + heatmaps + session replay + opt-in strict 12 mois) |
| /cookies texte mis a jour avec Microsoft Clarity | OK (section 2.2 + tableau analytics + section 5 cookies tiers) |
| DevTools Network : 0 requete vers clarity.ms | OK (no-op DEV confirme) |
| wrff07upjx absent du source HTML / network | OK (pas de leak PROD ID) |
| Aucune regression visible (navigation, navbar, footer, IntroSplash, PreviewBanner) | OK |
| GA4 + Meta + TikTok + LinkedIn Insight Tag continuent de fonctionner | OK (Analytics.tsx inchange) |

---

## 8. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 session Clarity creee (script jamais charge en DEV)
- 0 requete vers clarity.ms en runtime DEV
- 0 trafic fake genere
- 0 modification destinations / delivery_logs / signup_attribution
- 0 token / Project ID expose dans chat ou source code committed (wrff07upjx absent du commit, sera ajoute uniquement dans le manifest PROD au moment AS.16.1-PROD)
- 0 PII / payload sensible
- 0 modification DB

---

## 9. ANTI-REGRESSION POUR HOMEPAGE FUTURE (CTA + Reviews)

Architecture compatible avec ajouts homepage futurs :
- ClarityProvider monte au layout racine -> capture automatique de toute nouvelle section homepage
- Aucune liste hardcoded de selectors specifiques
- Allowlist implicite : toute page publique website (pas de filter route specifique)
- Masking configurable cote Microsoft Clarity dashboard via class/data-attributes si necessaire

Quand Ludovic ajoute :
- Nouveau CTA homepage : Clarity mesurera automatiquement clics + heatmaps
- Section Reviews : Clarity capturera scroll depth + interactions
- Toute nouvelle section : aucune modification ClarityProvider necessaire

---

## 10. ROLLBACK READY

Plan rollback DEV (si necessaire) :

```
cd /opt/keybuzz/keybuzz-infra
git revert e985168
git push origin main
kubectl apply -f k8s/website-dev/deployment.yaml
kubectl -n keybuzz-website-dev rollout status deploy/keybuzz-website --timeout=240s
```

Resultat attendu : retour website DEV a v0.6.12-linkedin-insight-seo-dev. Image v0.6.13 reste sur GHCR mais non-applied.

Aucun rollback necessaire post-AS.16.1 DEV : 0 regression, QA OK.

---

## 11. LINEAR (commentaire propose KEY-322)

```
PH-ADMIN-T8.12AS.16.1 Microsoft Clarity website DEV livre (no-op mode).

Verdict : GO CLARITY WEBSITE DEV NO-OP READY.

Implementation :
- Composant ClarityProvider.tsx nouveau dans keybuzz-website
- CookieConsent banner v2 (texte mentionne Microsoft Clarity, opt-in strict)
- /cookies politique mise a jour (section 2.2, tableau analytics, section 5)
- layout.tsx mount ClarityProvider apres Analytics

Build :
- Image v0.6.13-clarity-website-dev from-git commit 29bafcf
- KEY-308 OCI labels complets (revision full SHA, created ISO UTC, version, source, title)
- KEY-302 bundle check : wrff07upjx ABSENT, ClarityProvider PRESENT, clarity.ms URL inline mais code path INACTIF (no-op)

GitOps DEV :
- Commit infra e985168 deploy(dev): Clarity website opt-in DEV no-op
- kubectl apply, rollout OK, triple-egalite spec=last-applied=podImageID=GHCR digest

Validation runtime DEV :
- QA navigateur preview.keybuzz.io OK
- CookieConsent v2 affiche avec mention Microsoft Clarity
- /cookies texte OK
- DevTools Network : 0 requete vers clarity.ms (no-op DEV confirme)
- wrff07upjx (PROD ID) ABSENT du bundle DEV (pas de leak)
- GA4 + Meta + TikTok + LinkedIn Insight Tag continuent de fonctionner

Anti-regression : Client DEV/PROD + API PROD + Admin PROD + Backend PROD + Website PROD strictement inchanges.

Decisions architecturales (AS.16.0.1 actees) respectees :
- NEXT_PUBLIC_CLARITY_PROJECT_ID absent en DEV (no-op intentionnel)
- Project ID PROD wrff07upjx pret a etre injecte en AS.16.1-PROD
- Consent gate via CookieConsent existant (pattern binaire conserve)
- Anti-regression Inbox/Brouillon IA/tenant switcher/escalation/playbooks/channels/Admin (Clarity NON charge sur Client + Admin)

Pre-requis AS.16.1-PROD :
- GO Ludovic explicite
- Manifest k8s/website-prod/deployment.yaml : ajouter env var NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx
- Build image v0.6.13-clarity-website-prod from-git commit 29bafcf avec build-arg supplementaire
- Verifier KEY-302 bundle PROD : api.keybuzz.io present, api-dev absent, wrff07upjx PRESENT cette fois (intentionnel)
- QA navigateur PROD post-deploy : confirmer session Clarity arrive dans dashboard Microsoft Clarity apres accepter consentement

Hors scope AS.16.1 (deferred) :
- AS.16.2 client.keybuzz.io funnel pre-auth Clarity (decision Project ID separe ou commun)
- AS.16.3 verification exclusion stricte
- AS.16.4 agency handoff docs

Hygiene :
- 0 Clarity charge en DEV (no-op)
- 0 session creee
- 0 secret expose
- 0 token affiche
- 0 mutation provider
- 0 ticket Linear cree

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause AS.14.2.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.16.1-MICROSOFT-CLARITY-WEBSITE-DEV-01.md
```

Aucun changement Linear statut effectue.

---

## 12. PROCHAINE PHASE PROPOSEE

### AS.16.1-PROD (apres GO Ludovic explicite)

Pre-requis :
- AS.16.1 DEV QA OK (cette phase, DONE)
- Project ID PROD wrff07upjx pret (DONE, recu cote Ludovic)
- Politique cookies texte deja mis a jour cote source (DONE, sera promue avec le build PROD)

Plan execution :
1. Build website PROD v0.6.13-clarity-website-prod from-git commit 29bafcf avec build-arg `NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx`
2. KEY-302 bundle check PROD : api.keybuzz.io PRESENT, api-dev ABSENT, wrff07upjx PRESENT (intentionnel)
3. KEY-308 OCI labels complets
4. docker push PROD (GO required)
5. Edit k8s/website-prod/deployment.yaml v0.6.12 -> v0.6.13-clarity-website-prod + digest comment + rollback note
6. Commit infra deploy(prod): Clarity website PROD activation (KEY-322 AS.16.1-PROD)
7. kubectl apply + rollout
8. Triple-egalite verification
9. Anti-regression : client/api/admin/backend PROD inchanges
10. QA Ludovic + agence : visite https://www.keybuzz.pro avec consent accepted -> session arrive dans dashboard Microsoft Clarity sous quelques minutes
11. Rapport AS.16.1-PROD docs-only

GO required : OUI (avant build PROD)

---

## 13. GAPS / UNKNOWNS

| Gap | Statut | Action proposee |
|---|---|---|
| Pattern binaire CookieConsent vs categorisation granulaire RGPD | NOTED | AS.16.x dedie ulterieur si besoin (3eme categorie analytics_storage vs session_replay_storage) |
| Cross-domain Clarity keybuzz.pro <-> client.keybuzz.io | DEFERRED a AS.16.2 | Decision Project ID separe ou commun |
| Test E2E Clarity dashboard en PROD post-deploy | DEFERRED a AS.16.1-PROD | Visite Ludovic + verification arrivee session Clarity |
| Anciens decalages politique cookies vs Analytics.tsx (GA4/Meta charge sans verifier banner) | NOTED hors scope | AS.16.x dedie si besoin amelioration consent global |

Aucun gap bloquant.

---

## 14. PHRASE CIBLE FINALE

Microsoft Clarity DEV no-op livre. ClarityProvider + CookieConsent v2 + /cookies texte + layout mount integres en DEV (preview.keybuzz.io). Project ID PROD wrff07upjx pret pour AS.16.1-PROD. Aucun script Clarity charge en DEV (no-op confirme via DevTools Network), aucune session creee, aucun secret expose. Triple-egalite spec=last-applied=podImageID=GHCR. Anti-regression confirmee : Client/API/Admin/Backend/Website PROD strictement inchanges. KEY-322 reste Open. Aucun enchainement AS.16.1-PROD sans GO Ludovic explicite.

STOP
