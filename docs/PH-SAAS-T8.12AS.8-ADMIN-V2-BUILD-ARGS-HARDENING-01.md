# PH-SAAS-T8.12AS.8-ADMIN-V2-BUILD-ARGS-HARDENING-01

> Date : 2026-05-11
> Linear : KEY-307 (principal)
> Phase : T8.12 AS.8 - Admin-v2 build args hardening source-only
> Environnement : keybuzz-admin-v2 source ; runtime Admin DEV+PROD inchange ; aucun push registry ; aucun deploy

---

## 1. VERDICT

GO ADMIN BUILD ARGS HARDENING READY

NO BUILD PUSH / NO DEPLOY / NO RUNTIME MUTATION.

Hardening pattern KEY-302 Client applique a keybuzz-admin-v2 :
- Dockerfile : 2 ARG critiques (`NEXT_PUBLIC_APP_ENV`, `NEXT_PUBLIC_API_URL`) avec sentinels `__MUST_BE_SET_BY_BUILD_ARG__`.
- Guard pre-build : `scripts/check-admin-build-args.sh` (sh POSIX, 61 lignes).
- Verify post-build : `scripts/verify-admin-bundle-api-url.sh` (bash, 104 lignes, gestion 2 zones static/server).
- Doc : `docs/BUILD-ARGS.md` (105 lignes, exemples + failure modes).

5 build tests locaux sur bastion install-v3 :
- T1 no-args : FAIL au step 8/57 (guard sentinel detected). Exit non-zero.
- T2 mismatch DEV env + PROD URL : FAIL au guard. Exit non-zero.
- T3 staging env invalide : FAIL au guard. Exit non-zero.
- T4 DEV args complets : PASS, 2m20s, verify bundle OK (browser inlines api-dev URL, no PROD URL, no sentinel).
- T5 PROD args complets : PASS, 2m21s, verify bundle OK (browser inlines api URL, no DEV URL, no sentinel).

Images locales test cleanup OK. Aucun push registry effectue. Runtime Admin-v2 DEV (`v2.12.2-media-buyer-lp-domain-qa-dev`) et PROD (`v2.12.2-media-buyer-lp-domain-qa-prod`) inchanges.

---

## 2. Scope

Modifications strictes :

| Repo | Path | Branche | HEAD avant | HEAD apres | Sync |
|---|---|---|---|---|---|
| keybuzz-admin-v2 | /opt/keybuzz/keybuzz-admin-v2 | main | ad2bd4c | 126eba1 | 0/0 |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 11da76f | (a commiter) | 0/0 |

Fichiers ajoutes / modifies dans `keybuzz-admin-v2` (commit 126eba1) :

| Path | Status | Lignes |
|---|---|---|
| Dockerfile | M | +15 / -2 (sentinels + COPY guard + RUN guard avant npm ci) |
| docs/BUILD-ARGS.md | A | 105 |
| scripts/check-admin-build-args.sh | A | 61 (mode 0755) |
| scripts/verify-admin-bundle-api-url.sh | A | 104 (mode 0755) |

Total : 4 fichiers, +283/-2.

Aucun autre fichier touche :
- pas de `package.json`
- pas de `package-lock.json`
- pas de `next.config.mjs`
- pas de `app/`, pas de `src/`
- pas de manifest, pas de secret, pas de CI workflow

Aucun changement dans `keybuzz-client`, `keybuzz-api`, `keybuzz-admin` (legacy quarantine). Aucun deploy. Aucun docker push. Aucun kubectl apply. Aucune mutation DB.

---

## 3. Preflight

| Repo | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-admin-v2 | main | ad2bd4c | 0/0 | clean | OK source-only patch autorise |
| keybuzz-infra | main | 11da76f (AS.7) | 0/0 | clean | OK (rapport docs-only a commit direct) |
| keybuzz-client | ph148/onboarding-activation-replay | 7a8a2fb | 0/0 | M tsconfig.tsbuildinfo (artefact connu) | OK lecture uniquement (reference KEY-302) |
| keybuzz-api | ph147.4/source-of-truth | b8613f0f | 0/0 | D dist/*.js (artefact connu) | OK READ-ONLY |

Runtime Admin-v2 :

| Env | Image | Pod ready | Verdict |
|---|---|---|---|
| DEV | v2.12.2-media-buyer-lp-domain-qa-dev | yes | unchanged |
| PROD | v2.12.2-media-buyer-lp-domain-qa-prod | yes | unchanged |

Pas de drift GitOps. AS.6.2 SOT `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` lu en premier comme requis.

---

## 4. Build args audit (avant patch)

| Variable | Used where | Default avant patch | Risk | Guard needed? |
|---|---|---|---|---|
| `NEXT_PUBLIC_APP_ENV` | Dockerfile ARG, runtime env, `src/config/env.ts`, NextAuth cookie scoping | `production` | HIGH : sans `--build-arg` DEV, bundle `APP_ENV=production` -> cookies scoped `.keybuzz.io` en DEV | OUI |
| `NEXT_PUBLIC_API_URL` | Dockerfile ARG, runtime env, `src/config/env.ts apiUrl`, 4 routes admin `apiInternalUrl` fallback | `https://api.keybuzz.io` | HIGH : sans `--build-arg` DEV, bundle DEV pointe API PROD (memes failure mode que AS.1.1 Client) | OUI |
| `NEXT_PUBLIC_BOOTSTRAP_INDICATOR` | source seulement | (aucun default) | LOW : feature-flag local, non lie au routing | NON (volontairement hors guard) |

Source patterns identifies (3 cas de fallback runtime legitime) :
- `src/config/env.ts apiInternalUrl: process.env.KEYBUZZ_API_INTERNAL_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io'`
- `src/app/api/admin/marketing/delivery-logs/route.ts: ... || 'https://api.keybuzz.io'`
- `src/app/api/admin/marketing/proxy.ts: ... || 'https://api.keybuzz.io'`
- `src/app/api/admin/marketing/google-observability/route.ts: ... || 'https://api.keybuzz.io'`

Ces fallbacks server-side sont legitimes : au runtime, le pod admin-v2 a `KEYBUZZ_API_INTERNAL_URL` set vers le service K8s interne, donc le literal `'https://api.keybuzz.io'` dans le code source n est jamais utilise. Le verify-script en tient compte (section 5.2 zone server bundle = WARN, pas FAIL).

---

## 5. Patch

### 5.1 Dockerfile (diff resume)

```
-ARG NEXT_PUBLIC_APP_ENV=production
-ARG NEXT_PUBLIC_API_URL=https://api.keybuzz.io
+ARG NEXT_PUBLIC_APP_ENV=__MUST_BE_SET_BY_BUILD_ARG__
+ARG NEXT_PUBLIC_API_URL=__MUST_BE_SET_BY_BUILD_ARG__
 ENV NEXT_PUBLIC_APP_ENV=${NEXT_PUBLIC_APP_ENV}
 ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
+
+# Guard runs BEFORE npm ci to fail fast
+COPY scripts/check-admin-build-args.sh ./scripts/check-admin-build-args.sh
+RUN sh ./scripts/check-admin-build-args.sh
```

Placement strategique : le `RUN sh ./scripts/check-admin-build-args.sh` est avant `COPY package*.json` et `RUN npm ci`. Si le guard fail, on n a meme pas downloade les dependences (build interrompu en quelques secondes, pas en plusieurs minutes).

### 5.2 scripts/check-admin-build-args.sh

POSIX sh (`set -eu`), 61 lignes. Verifications :
1. Non-empty pour les deux vars.
2. Sentinel `__MUST_BE_SET_BY_BUILD_ARG__` absent.
3. `NEXT_PUBLIC_APP_ENV` parmi {`development`, `production`}.
4. `NEXT_PUBLIC_API_URL` parmi {DEV_URL, PROD_URL} canoniques.
5. APP_ENV/URL match strict (development+DEV ou production+PROD seulement, sinon FAIL avec message clair).

Message FAIL ecrit sur stderr, exit 1.

### 5.3 scripts/verify-admin-bundle-api-url.sh

Bash (`set -euo pipefail`), 104 lignes. Usage : `verify-admin-bundle-api-url.sh <image> <development|production>`.

Etapes :
1. `docker create` + `docker cp /app` -> dossier temp local.
2. Sentinel `__MUST_BE_SET_BY_BUILD_ARG__` : FAIL si present DANS `/app` (strict, tout type de fichier).
3. Forbidden URL dans `/app/.next/static` (browser bundle) : FAIL strict.
4. Forbidden URL dans `/app/.next/server` (server bundle) : WARN seulement (legitime pour fallbacks runtime `... || 'https://api.keybuzz.io'`). Liste les fichiers concernes pour audit operateur.
5. Expected URL presence dans `/app/.next/static` : OK info.
6. Cleanup `docker rm -f` + `rm -rf` via trap EXIT.

Exit codes : 0 (OK ou OK+WARN), 1 (FAIL strict), 2 (extraction failure).

### 5.4 docs/BUILD-ARGS.md

105 lignes. Sections : TL;DR, Why, How, Canonical commands, Failure modes prevented, Notes, References.

Pattern reference visible : KEY-302 Client (`keybuzz-client/scripts/check-client-build-args.sh` et `verify-client-bundle-api-url.sh`).

---

## 6. Tests

5 tests executes sur bastion install-v3 (commande exacte `time docker build ... | tail`).

| # | Test | Build args | Expected | Result | Time |
|---|---|---|---|---|---|
| 1 | no-args | (aucun) | FAIL guard step | FAIL "NEXT_PUBLIC_APP_ENV not overridden via --build-arg (sentinel still present)" | ~5s avant npm ci |
| 2 | DEV env + PROD URL | NEXT_PUBLIC_APP_ENV=development NEXT_PUBLIC_API_URL=https://api.keybuzz.io | FAIL guard step | FAIL "DEV build must use DEV API URL, got: https://api.keybuzz.io" | ~5s |
| 3 | staging env | NEXT_PUBLIC_APP_ENV=staging NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io | FAIL guard step | FAIL "NEXT_PUBLIC_APP_ENV must be 'development' or 'production' (got: staging)" | ~5s |
| 4 | DEV complet | NEXT_PUBLIC_APP_ENV=development NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io | PASS + verify OK | Successfully built ; verify : "browser bundle inlines expected URL https://api-dev.keybuzz.io for development. Forbidden URL https://api.keybuzz.io absent from browser bundle. Sentinel absent everywhere." (10 WARN sur /app/.next/server pour fallbacks legitimes) | 2m20s |
| 5 | PROD complet | NEXT_PUBLIC_APP_ENV=production NEXT_PUBLIC_API_URL=https://api.keybuzz.io | PASS + verify OK | Successfully built ; verify : "browser bundle inlines expected URL https://api.keybuzz.io for production. Forbidden URL https://api-dev.keybuzz.io absent from browser bundle. Sentinel absent everywhere." (aucun WARN) | 2m21s |

Shell syntax pre-check : `sh -n scripts/check-admin-build-args.sh` et `bash -n scripts/verify-admin-bundle-api-url.sh` -> OK les deux.

---

## 7. Images local only

Tags locaux temporaires utilises pendant tests :
- `keybuzz-admin-v2:test-noargs` : etape interrompue au guard, image non finalisee.
- `keybuzz-admin-v2:test-mismatch` : idem.
- `keybuzz-admin-v2:test-staging` : idem.
- `keybuzz-admin-v2:test-dev` : image complete buildee localement (sha256:33100e63fac5..., layers intermediaires).
- `keybuzz-admin-v2:test-prod` : image complete buildee localement (sha256:96f524089e22...).

`docker rmi keybuzz-admin-v2:test-dev keybuzz-admin-v2:test-prod` execute en cleanup, layers intermediaires supprimes (5 sha256 reportes deleted dans la sortie cleanup).

**AUCUN `docker push` execute.** **AUCUN tag immuable cree.** **AUCUN deploy.** Les images de test ont uniquement existe localement sur le bastion pendant la phase de validation.

Aucun nouveau tag dans ghcr.io/keybuzzio/keybuzz-admin a ete cree par AS.8.

---

## 8. No runtime mutation proof

| Verification | Avant AS.8 | Apres AS.8 | Verdict |
|---|---|---|---|
| Admin-v2 DEV image | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-dev | INCHANGE |
| Admin-v2 PROD image | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| API DEV image | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | INCHANGE |
| API PROD image | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client DEV image | v3.5.179-as1-1-build-args-fix-dev | v3.5.179-as1-1-build-args-fix-dev | INCHANGE |
| Client PROD image | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend / Worker / Website | inchanges | inchanges | INCHANGE |
| K8s manifests | aucune modification | aucune modification | INCHANGE |
| Secrets K8s | aucune modification | aucune modification | INCHANGE |
| GitOps annotations | MATCH=yes | MATCH=yes | INCHANGE |
| DB | aucune modification | aucune modification | INCHANGE |

Phase 100% source-only. Aucune commande mutationnelle executee. `docker build` reste local (pas de push), `kubectl` non utilise pour mutation, `docker rmi` agit uniquement sur le cache local du bastion.

---

## 9. Gaps

1. **Promotion eventuelle vers PROD** : la nouvelle image Admin-v2 hardened doit eventuellement etre buildee + pushed + deployee. Hors scope AS.8. A planifier en phase dediee de promotion Admin-v2 quand il sera utile (par exemple si on rebuild Admin-v2 pour autre feature). Inclure obligatoirement les build args explicites a ce moment.

2. **Tag policy KEY-309** : la regle "one tag = one source = one digest" n est pas encore en place. Quand Admin-v2 sera build pour push, le tag immuable choisi devra suivre la convention KEY-309 quand elle sera implementee.

3. **OCI labels KEY-308** : le Dockerfile Admin-v2 ne contient pas encore `LABEL org.opencontainers.image.revision=$GIT_COMMIT_SHA`. A inclure dans une phase de hardening Dockerfile dedie ou lors de la prochaine modification Admin-v2.

4. **Smoke harness V1 (KEY-310)** : ne couvre pas encore Admin-v2 bundle. V2 du smoke pourrait ajouter une section bundle guard sur l image Admin-v2 (similar a la section B du Client smoke).

5. **Variables `NEXT_PUBLIC_*` futures** : si de nouvelles variables sensibles au routing sont ajoutees a Admin-v2, le guard doit etre etendu. Documente dans `docs/BUILD-ARGS.md`.

6. **CI/pipeline** : aucun workflow CI n a ete modifie dans AS.8. Si un pipeline GitHub Actions/autre existe pour Admin-v2 builds, il devra etre mis a jour pour passer les `--build-arg` explicites. Hors scope AS.8.

---

## 10. Linear text prepared, posted

Texte poste en KEY-307 lors de E7 ci-dessous. Voir section 10.bis.

### 10.bis Texte Linear poste (resume controle)

URL commentaire : voir resultat E7.

Contenu :
```
## AS.8 -- Admin-v2 build args hardening livre (source-only)

Source hardening livre dans keybuzz-admin-v2 (commit 126eba1, branche main) :
- Dockerfile : sentinels `__MUST_BE_SET_BY_BUILD_ARG__` sur `NEXT_PUBLIC_APP_ENV` et `NEXT_PUBLIC_API_URL`.
- Guard `scripts/check-admin-build-args.sh` (sh POSIX) execute AVANT npm ci.
- Verifier `scripts/verify-admin-bundle-api-url.sh` (bash) avec policy 2-zones : strict /app/.next/static (browser), WARN /app/.next/server (fallbacks runtime legitimes documentes).
- Doc `docs/BUILD-ARGS.md` (105 lignes, exemples + failure modes).

Validation 5 tests locaux bastion :
- no-args FAIL guard
- DEV env + PROD URL mismatch FAIL guard
- staging env invalide FAIL guard
- DEV complet : PASS + verify bundle OK (browser inlines api-dev URL, no PROD URL, no sentinel)
- PROD complet : PASS + verify bundle OK

Cleanup images locales fait. Aucun docker push. Aucun deploy. Runtime Admin-v2 DEV+PROD inchanges (v2.12.2-media-buyer-lp-domain-qa-*).

Statut suggere : Done. La prochaine fois qu un build Admin-v2 sera lance (build/push reel), il devra passer les --build-arg explicites sinon FAIL. Mecanisme equivalent KEY-302 Client.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.8-ADMIN-V2-BUILD-ARGS-HARDENING-01.md
```

---

### 10.ter Phrase cible finale

AS.8 livre le hardening build args Admin-v2 source-only en miroir de KEY-302 Client (Dockerfile sentinels + guard sh + verify bash 2-zones + docs) ; 5 tests locaux bastion install-v3 OK (3 FAIL guard expected + 2 PASS DEV/PROD avec bundle verifie strict static / WARN server documente) ; commit 126eba1 push origin main ; cleanup images locales fait ; aucun docker push, aucun deploy, aucun kubectl apply, aucune mutation runtime/DB/manifest/secret/CI ; runtime Admin-v2 DEV+PROD strictement inchanges ; verdict AS.8 GO ADMIN BUILD ARGS HARDENING READY.

STOP
