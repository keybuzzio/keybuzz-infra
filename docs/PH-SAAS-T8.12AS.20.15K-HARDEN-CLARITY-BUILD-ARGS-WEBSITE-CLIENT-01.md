# PH-SAAS-T8.12AS.20.15K-HARDEN-CLARITY-BUILD-ARGS-WEBSITE-CLIENT-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity website ; KEY-325 Clarity client
> Phase : PH-SAAS-T8.12AS.20.15K (HARDEN CLARITY BUILD ARGS WEBSITE+CLIENT)
> Environnement : SOURCE ONLY (commits locaux ; aucun build/push/deploy/kubectl ; aucun fake event)

## 1. Verdict

GO HARDEN CLARITY BUILD ARGS WEBSITE CLIENT READY PH-SAAS-T8.12AS.20.15K

Durcissement source-only des deux repos pour empecher la recurrence du footgun NEXT_PUBLIC qui a casse Clarity (PH-20.15 website, PH-20.15F client). Un guard fail-fast echoue desormais tout build PRODUCTION ou un build-arg public de tracking requis est absent/vide, AVANT que l'image ne soit produite. Client : le guard existant (KEY-302, deja cable dans le Dockerfile) est etendu pour exiger Clarity en production. Website : nouveau guard cable via le script npm prebuild (aucune modif Dockerfile). Les builds DEV/preview ne sont pas contraints. Tests statiques + fonctionnels OK (OK / FAIL / SKIP conformes). Commits LOCAUX uniquement, aucun push, aucun build Docker, aucun deploy, runtime website v0.6.22 et client v3.5.217 inchanges. STOP au gate push.

## 2. Preflight (E0)

| Repo/service | branch/runtime | HEAD/image | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-website | main | 907689b = origin | 0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ef239e8 = origin | 1 (tsconfig.tsbuildinfo, artefact build genere) | OK compris |
| keybuzz-infra | main | 9a4397b = origin | 0 | OK |
| website PROD runtime | keybuzz-website-prod | v0.6.22-clarity-restore-prod | ready | OK (read-only) |
| client PROD runtime | keybuzz-client-prod | v3.5.217-clarity-client-restore-prod | ready | OK (read-only) |

bastion install-v3 / 46.62.171.61 confirme.

## 3. Build entrypoints (E1)

| Repo | build entrypoint | args actuels | gap | verdict |
|---|---|---|---|---|
| website | Dockerfile builder `RUN npm run build` (L44) ; package.json scripts standard Next.js | 9 ARG NEXT_PUBLIC_* (CLARITY/META/TIKTOK defaut vide) | AUCUN guard, AUCUN prebuild ; build sans build-arg droppe le tracking en silence | gap confirme |
| client | Dockerfile builder `RUN sh ./scripts/check-client-build-args.sh` (L66) puis `RUN npm run build` (L68) | guard KEY-302 existant valide APP_ENV/API_URL/API_BASE_URL | guard ne couvre PAS Clarity -> v3.5.201 a passe le guard mais droppe Clarity | gap confirme |

## 4. Required public build args (E2)

| Repo | build arg | required value (production) | source | verdict |
|---|---|---|---|---|
| website | NEXT_PUBLIC_SITE_MODE | production | Dockerfile L19, build v0.6.22 | OK |
| website | NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx | PH-20.15B/D, KEY-322 | OK |
| website | NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | PH-20.15B | OK |
| website | NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | PH-20.15B | OK |
| website | NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG | PH-20.15B baseline | OK |
| client | NEXT_PUBLIC_APP_ENV | production | Dockerfile L16 (deja garde KEY-302) | OK |
| client | NEXT_PUBLIC_API_URL | https://api.keybuzz.io | deja garde KEY-302 | OK |
| client | NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | deja garde KEY-302 | OK |
| client | NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | PH-20.15G/I, KEY-325 (gap comble ici) | OK |

Toutes ces valeurs sont des IDs analytics PUBLICS (documentation OK, aucun secret hardcode). Le guard exige NON-VIDE en production (robuste a une rotation d'ID), pas une valeur exacte ; la valeur canonique est documentee dans BUILD-ARGS.md.

## 5. Design hardening (E3)

| Repo | guard location | behavior | risk | verdict |
|---|---|---|---|---|
| client | scripts/check-client-build-args.sh (etendu) ; deja cable Dockerfile L66 | + si APP_ENV=production : exige NEXT_PUBLIC_CLARITY_PROJECT_ID non vide et != sentinel | faible (DEV non contraint ; deja invoque par le build) | OK |
| website | scripts/check-website-build-args.sh (nouveau) ; cable via package.json prebuild | si SITE_MODE=production : exige CLARITY/META/TIKTOK/GA non vides ; sinon SKIP | faible (aucune modif Dockerfile ; DEV/preview non contraints) | OK |

Approche minimale, adaptee par repo (pas de script commun fragile). Aucun Dockerfile modifie : client deja cable, website cable via prebuild (npm execute prebuild avant build, donc dans le builder Docker au `RUN npm run build`).

## 6. Files changed (E4)

| Repo | file | change | risk | verdict |
|---|---|---|---|---|
| client | scripts/check-client-build-args.sh | +bloc Clarity production-only + ligne rappel dans fail() (13 insertions) | faible | OK |
| client | docs/BUILD-ARGS.md | documente Clarity required (production) + commande PROD + KEY-325 | nul (doc) | OK |
| website | scripts/check-website-build-args.sh | nouveau guard POSIX sh (58 lignes) | faible | OK |
| website | package.json | +1 ligne "prebuild": "sh scripts/check-website-build-args.sh" | faible | OK |
| website | docs/BUILD-ARGS.md | nouveau doc build-args website (100 lignes) | nul (doc) | OK |

Hors scope strict respecte : aucun code app/tracking modifie, aucun Dockerfile, aucun manifest.

## 7. Validation tests (E5)

| Test | expected | result | verdict |
|---|---|---|---|
| sh -n website guard | syntaxe OK | OK | OK |
| sh -n client guard | syntaxe OK | OK | OK |
| website package.json JSON parse | valide + prebuild present | valide, prebuild=sh scripts/check-website-build-args.sh | OK |
| website guard PROD tous args | exit 0 (OK) | exit 0 | OK |
| website guard PROD Clarity vide | exit 1 (FAIL, liste manquant) | exit 1 | OK |
| website guard SITE_MODE=development | exit 0 (SKIP) | exit 0 SKIP | OK |
| client guard PROD + Clarity | exit 0 (OK) | exit 0 | OK |
| client guard PROD Clarity vide | exit 1 (FAIL) | exit 1 | OK |
| client guard development sans Clarity | exit 0 (OK, non contraint) | exit 0 | OK |
| shellcheck | si dispo | absent (skip, non bloquant) | N/A |

## 8. No side-effect (E6)

| Garantie | etat |
|---|---|
| docker build | 0 |
| image creee dans la phase | 0 (images v0.6.22/v3.5.217 datent de 15B/15G, anterieures) |
| docker push | 0 |
| kubectl | 0 |
| manifest GitOps modifie | 0 |
| runtime website/client | inchanges (v0.6.22 / v3.5.217) |
| repo dirty | uniquement changements attendus (+ tsconfig.tsbuildinfo client pre-existant, exclu du commit) |

## 9. No fake metrics / no fake events (E8)

| Garantie | etat |
|---|---|
| fake Clarity event | 0 |
| fake pageview / session | 0 |
| synthetic conversion | 0 |
| analytics backfill | 0 |
| DB mutation | 0 |

## 10. AI feature parity / anti-regression (E9)

| Garantie | etat |
|---|---|
| website runtime preserve | OUI (v0.6.22 inchange) |
| client runtime preserve | OUI (v3.5.217 inchange) |
| Amazon KEY-323 | preserve (non touche) |
| Inbox / AI / KBActions | non touches (aucun code app modifie) |
| no api-dev leak introduced | OUI (guard renforce l'isolation, n'introduit rien) |
| no tracking runtime mutation | OUI (source-only, aucun deploy) |

## 11. Commits locaux (E7)

| Repo | commit local | message | push |
|---|---|---|---|
| keybuzz-website | eba00d8 | chore(build): require website tracking public build args (PH-20.15K KEY-322) | NON (gate) |
| keybuzz-client | dda6b45 | chore(build): require client clarity public build args (PH-20.15K KEY-325) | NON (gate) |
| keybuzz-infra | (ce rapport) | docs(clarity): PH-20.15K harden clarity build args | NON (gate) |

## 12. Rollback

| Action | rollback |
|---|---|
| website commit eba00d8 | git revert eba00d8 (ou reset local avant push) ; supprime prebuild + guard + doc |
| client commit dda6b45 | git revert dda6b45 ; le guard revient a la version KEY-302 sans Clarity |
| effet runtime | nul (rien deploye) ; aucun rollback runtime necessaire |

Note : tant que les commits ne sont PAS pushes, aucun build futur ne consomme le guard ; le durcissement ne prend effet qu'au prochain build APRES push + (pour le client) prise en compte au prochain docker build (Dockerfile recopie le script edite).

## 13. Linear (E11)

Texte de commentaire prepare pour KEY-337 + KEY-322 + KEY-325 (NON poste tant que non pushe) :

"PH-20.15K (HARDEN CLARITY BUILD ARGS) - source-only, commits locaux, gate push. Guard fail-fast ajoute pour empecher la recurrence du footgun NEXT_PUBLIC. Client : check-client-build-args.sh etendu (Clarity wuk12h9i33 obligatoire si production ; deja cable Dockerfile). Website : nouveau check-website-build-args.sh cable via prebuild (CLARITY wrff07upjx / META / TIKTOK / GA obligatoires si production ; aucune modif Dockerfile). DEV/preview non contraints. Tests OK/FAIL/SKIP conformes. Aucun build/push/deploy ; runtime inchange. Docs BUILD-ARGS.md mises a jour. En attente GO push."

## 14. Next GO

GO PUSH HARDEN CLARITY BUILD ARGS WEBSITE CLIENT PH-SAAS-T8.12AS.20.15K

(push des 3 commits locaux : keybuzz-website eba00d8, keybuzz-client dda6b45, keybuzz-infra ce rapport ; puis post Linear.)

## 15. Phrase cible

GO HARDEN CLARITY BUILD ARGS WEBSITE CLIENT READY PH-SAAS-T8.12AS.20.15K

STOP.
