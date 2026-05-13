# PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01

> Date : 2026-05-13
> Linear : KEY-301 (sous KEY-301, derive du gap G1 documente dans AS.12.2C-3-PROD)
> Phase : T8.12 AS.12.2C-3.1 -- correction scripts build-*-from-git.sh pour OCI args KEY-308
> Environnement : housekeeping scripts (aucun build PROD, aucun deploy, aucun manifest)

---

## 1. VERDICT

GO BUILD SCRIPTS OCI ARGS FIX READY

Patch minimal sur `scripts/build-api-from-git.sh` + `scripts/build-from-git.sh` :
- Ajout `GIT_SHA_FULL` (SHA complet 40 chars).
- Passage explicite de `--build-arg IMAGE_REVISION=$GIT_SHA_FULL` + `--build-arg IMAGE_CREATED=$BUILD_TIME` + `--build-arg IMAGE_VERSION=$TAG` (les 3 ARGs attendus par les Dockerfiles pour les OCI labels KEY-308 `org.opencontainers.image.revision`, `created`, `version`).
- Correction bug pre-existant Client DEV : `APP_ENV="development"` au lieu de `APP_ENV=""` pour ENV=dev, afin que `NEXT_PUBLIC_APP_ENV` soit toujours passe au Dockerfile et que le guard `check-client-build-args.sh` (KEY-302) passe.

Tests locaux avec tag throwaway `v0.0.1-oci-args-fix-test-dev` (aucun push) :
- API build via script : OCI labels 5/5 PASS (revision=SHA complet, created=ISO UTC, version=tag, source, title).
- Client build via script : OCI labels 5/5 PASS + sentinel `__MUST_BE_SET_BY_BUILD_ARG__` absent + `api-dev.keybuzz.io` present (x2) + `api.keybuzz.io` (sans api-dev) absent (bundle DEV propre).

Images test supprimees du daemon Docker local apres verification. Aucun push GHCR. KEY-309 et registry intacts.

Gap G1 du rapport AS.12.2C-3-PROD est resolu. Les builds futurs via les scripts produiront automatiquement les OCI labels conformes KEY-308. PROD anterieurs (v3.5.182, v3.5.193, v3.5.183, v3.5.194) non affectes.

KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- `scripts/build-api-from-git.sh` : ajout `GIT_SHA_FULL` + 3 ARGs OCI dans le `docker build`.
- `scripts/build-from-git.sh` : ajout `GIT_SHA_FULL` + 3 ARGs OCI dans la chaine `BUILD_CMD` + correction `APP_ENV="development"` en DEV.
- Test local builds (tags throwaway DEV `v0.0.1-oci-args-fix-test-dev`).
- Cleanup images test.
- Rapport docs-only.
- Commit + push docs + scripts.

Hors scope :
- Aucun build / push PROD.
- Aucun manifest infra.
- Aucun deploy K8s.
- Aucune mutation DB / runtime.
- Aucune modification source `keybuzz-api` / `keybuzz-client`.
- Aucun touchement scripts non listes.

---

## 3. Sources read

- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-PROD-01.md` -- gap G1 origine.
- `scripts/build-api-from-git.sh` + `scripts/build-from-git.sh` (etat initial).
- `keybuzz-api/Dockerfile` + `keybuzz-client/Dockerfile` (ARGs attendus, KEY-308 labels).
- `keybuzz-client/scripts/check-client-build-args.sh` (KEY-302 sentinel guard).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 | OK | OK |
| keybuzz-infra HEAD / branche / sync | 7881476 (rapport AS.12.2C-3-PROD) / main / 0-0 / 0 dirty | OK |
| Scope read scripts | api script 99 lignes / client script 129 lignes (avant patch) | OK |
| Dockerfile keybuzz-api ARGs OCI attendus | `IMAGE_REVISION`, `IMAGE_CREATED`, `IMAGE_VERSION` (defaults `unknown`) | OK |
| Dockerfile keybuzz-client ARGs OCI attendus | meme triplet (defaults `unknown`) + sentinel NEXT_PUBLIC_* (KEY-302) | OK |

---

## 5. Patch scripts

### 5.1 Diff cumulatif `scripts/build-api-from-git.sh`

```
@@ -50,6 +50,7 @@ git clone --depth 1 --branch "$BRANCH" \
   https://github.com/keybuzzio/keybuzz-api.git "$BUILD_DIR" 2>&1
 cd "$BUILD_DIR"
 GIT_SHA=$(git rev-parse --short HEAD)
+GIT_SHA_FULL=$(git rev-parse HEAD)
 echo "PASS: Cloned at $GIT_SHA"
 
 # STEP 2: Verify clean
@@ -74,6 +75,9 @@ echo ""
 docker build --no-cache \
   --build-arg GIT_COMMIT_SHA="$GIT_SHA" \
   --build-arg BUILD_TIME="$BUILD_TIME" \
+  --build-arg IMAGE_REVISION="$GIT_SHA_FULL" \
+  --build-arg IMAGE_CREATED="$BUILD_TIME" \
+  --build-arg IMAGE_VERSION="$TAG" \
   -t "$IMAGE" .
```

4 lignes ajoutees, 0 lignes supprimees.

### 5.2 Diff cumulatif `scripts/build-from-git.sh`

```
@@ -56,6 +56,7 @@ git clone --depth 1 --branch "$BRANCH" \
 
 cd "$BUILD_DIR"
 GIT_SHA=$(git rev-parse --short HEAD)
+GIT_SHA_FULL=$(git rev-parse HEAD)
 echo "PASS: Cloned at $GIT_SHA"
 
 # ============================================================
@@ -78,7 +79,7 @@ BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
 
 if [ "$ENV" = "dev" ]; then
   API_URL="https://api-dev.keybuzz.io"
-  APP_ENV=""
+  APP_ENV="development"
 else
   API_URL="https://api.keybuzz.io"
   APP_ENV="production"
@@ -95,6 +96,9 @@ BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_API_URL=$API_URL"
 BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_API_BASE_URL=$API_URL"
 BUILD_CMD="$BUILD_CMD --build-arg GIT_COMMIT_SHA=$GIT_SHA"
 BUILD_CMD="$BUILD_CMD --build-arg BUILD_TIME=$BUILD_TIME"
+BUILD_CMD="$BUILD_CMD --build-arg IMAGE_REVISION=$GIT_SHA_FULL"
+BUILD_CMD="$BUILD_CMD --build-arg IMAGE_CREATED=$BUILD_TIME"
+BUILD_CMD="$BUILD_CMD --build-arg IMAGE_VERSION=$TAG"
 
 if [ -n "$APP_ENV" ]; then
   BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_APP_ENV=$APP_ENV"
```

5 lignes ajoutees, 1 ligne modifiee, 0 lignes supprimees.

### 5.3 Justifications

| Modification | But | Risque |
|---|---|---|
| `GIT_SHA_FULL` ajoute apres `GIT_SHA` (2 scripts) | Capture le SHA complet 40 chars necessaire pour OCI revision (le `--short` produit 7 chars insuffisants pour traceabilite stricte) | Aucun : variable locale au script, n affecte rien d autre |
| `--build-arg IMAGE_REVISION=$GIT_SHA_FULL` (2 scripts) | Remplit le label OCI `org.opencontainers.image.revision` | Aucun : ARG existant cote Dockerfile (default `unknown`) |
| `--build-arg IMAGE_CREATED=$BUILD_TIME` (2 scripts) | Remplit le label OCI `org.opencontainers.image.created` ISO UTC | Aucun : ARG existant cote Dockerfile (default `unknown`) |
| `--build-arg IMAGE_VERSION=$TAG` (2 scripts) | Remplit le label OCI `org.opencontainers.image.version` = tag complet | Aucun : ARG existant cote Dockerfile (default `unknown`) |
| `APP_ENV="development"` au lieu de `APP_ENV=""` (Client uniquement, ENV=dev) | Resout bug pre-existant : `NEXT_PUBLIC_APP_ENV` n etait pas passe en DEV, donc `check-client-build-args.sh` (KEY-302 guard) bloquait le build DEV via le script. Avec le fix, `NEXT_PUBLIC_APP_ENV=development` est toujours passe en DEV | Aucun PROD : la branche PROD passe deja `APP_ENV="production"`. Aucun rebuild PROD ne change. Aucun build DEV anterieur reussi n est affecte (les builds DEV via le script qui passaient avant utilisaient probablement le sentinel non-bloquant ou un autre chemin -- non reproduit ici) |

Note GIT_COMMIT_SHA et BUILD_TIME conserves dans le `docker build` API meme s ils ne sont pas consommes par le Dockerfile API (warning Docker `One or more build-args were not consumed`). Conservation par retro-compatibilite : aucun script appelant ces ARGs n est casse, et le Dockerfile Client utilise bien `GIT_COMMIT_SHA` et `BUILD_TIME` (verifie ligne 24-25 du `keybuzz-client/Dockerfile`). Cleanup du warning API differe en gap separe.

---

## 6. Tests locaux (tag throwaway `v0.0.1-oci-args-fix-test-dev`)

### 6.1 Test API

```
bash scripts/build-api-from-git.sh dev v0.0.1-oci-args-fix-test-dev ph147.4/source-of-truth
```

Build OK : `Successfully built f039698a083a`, `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v0.0.1-oci-args-fix-test-dev`.

OCI labels post-build :

```
{
    "org.opencontainers.image.created": "2026-05-13T06:53:02Z",
    "org.opencontainers.image.revision": "85555b26cbcdfb1c7223d562453cc99c028cd91d",
    "org.opencontainers.image.source": "https://github.com/keybuzzio/keybuzz-api",
    "org.opencontainers.image.title": "keybuzz-api",
    "org.opencontainers.image.version": "v0.0.1-oci-args-fix-test-dev"
}
```

| Label | Valeur observee | Verdict |
|---|---|---|
| revision | 85555b26cbcdfb1c7223d562453cc99c028cd91d (SHA complet 40 chars) | PASS |
| created | 2026-05-13T06:53:02Z (ISO 8601 UTC) | PASS |
| version | v0.0.1-oci-args-fix-test-dev (tag complet) | PASS |
| source | https://github.com/keybuzzio/keybuzz-api | PASS |
| title | keybuzz-api | PASS |

5/5 OCI labels conformes KEY-308.

### 6.2 Test Client (apres correction APP_ENV DEV)

Premier test Client a echoue avec `[CLIENT-BUILD-ARGS-GUARD] FAIL: NEXT_PUBLIC_APP_ENV not overridden via --build-arg (sentinel still present)` (Step 36/60 du Dockerfile, avant les ARGs OCI). Cause identifiee : `APP_ENV=""` en DEV -> branche `if [ -n "$APP_ENV" ]` n etait pas declenchee -> `NEXT_PUBLIC_APP_ENV` jamais passe.

Patch applique : `APP_ENV="development"` en DEV. Re-test :

```
bash scripts/build-from-git.sh dev v0.0.1-oci-args-fix-test-dev ph148/onboarding-activation-replay
```

Build OK : `Successfully built 839fc4d9e355`, `Successfully tagged ghcr.io/keybuzzio/keybuzz-client:v0.0.1-oci-args-fix-test-dev`.

OCI labels post-build :

```
{
    "org.opencontainers.image.created": "2026-05-13T07:13:41Z",
    "org.opencontainers.image.revision": "c24d8c9263e3da21460fec3425fce1cc1af24604",
    "org.opencontainers.image.source": "https://github.com/keybuzzio/keybuzz-client",
    "org.opencontainers.image.title": "keybuzz-client",
    "org.opencontainers.image.version": "v0.0.1-oci-args-fix-test-dev"
}
```

| Label | Valeur observee | Verdict |
|---|---|---|
| revision | c24d8c9263e3da21460fec3425fce1cc1af24604 (SHA complet 40 chars) | PASS |
| created | 2026-05-13T07:13:41Z (ISO 8601 UTC) | PASS |
| version | v0.0.1-oci-args-fix-test-dev (tag complet) | PASS |
| source | https://github.com/keybuzzio/keybuzz-client | PASS |
| title | keybuzz-client | PASS |

5/5 OCI labels conformes KEY-308.

Bundle DEV verifications complementaires :

| Check | Count | Verdict |
|---|---|---|
| sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | PASS KEY-302 |
| `api-dev.keybuzz.io` (DEV URL attendue) | 2 | PASS bundle DEV |
| `api.keybuzz.io` standalone (sans api-dev) | 0 | PASS pas de contamination PROD |

### 6.3 Cleanup

```
docker rmi ghcr.io/keybuzzio/keybuzz-api:v0.0.1-oci-args-fix-test-dev
docker rmi ghcr.io/keybuzzio/keybuzz-client:v0.0.1-oci-args-fix-test-dev
```

Untagged + Deleted layers. `docker images` post-cleanup : aucune image avec ce tag.

Aucun `docker push` execute. KEY-309 et registry GHCR strictement inchanges.

---

## 7. Impact futur

| Cas d usage | Comportement avant fix | Comportement apres fix |
|---|---|---|
| `build-api-from-git.sh dev TAG BRANCH` | OCI labels revision/created/version = `unknown` | OCI labels remplis avec valeurs reelles |
| `build-api-from-git.sh prod TAG BRANCH` | OCI labels revision/created/version = `unknown` | OCI labels remplis avec valeurs reelles |
| `build-from-git.sh dev TAG BRANCH` | Echec `check-client-build-args.sh` (NEXT_PUBLIC_APP_ENV missing) ou labels `unknown` | Build OK + OCI labels remplis + `NEXT_PUBLIC_APP_ENV=development` correctement inlinee |
| `build-from-git.sh prod TAG BRANCH` | OCI labels `unknown` mais NEXT_PUBLIC_APP_ENV=production OK | OCI labels remplis + NEXT_PUBLIC_APP_ENV=production OK (inchange) |

Aucun build PROD anterieur n est invalide. Les images deja en runtime PROD (v3.5.182, v3.5.193, v3.5.183, v3.5.194) conservent leurs labels actuels.

---

## 8. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | Warning Docker `BUILD_TIME GIT_COMMIT_SHA were not consumed` lors du build API (le Dockerfile API n a pas ces ARGs en defaut, le Dockerfile Client si). Non bloquant mais bruyant. | Low | Sous-phase futur : nettoyer du script API ou ajouter les ARGs au Dockerfile API si traceabilite voulue. |
| G2 | AS.12.2C-4 `/ai/execute` (mutation critical) reste a livrer. | High | DEV avant PROD avec GO explicite. |
| G3 | AS.12.2C-5 `/ai/rules` (admin/CRUD) reste a livrer. | Medium | DEV avant PROD avec GO explicite. |
| G4 | Backlog 28 jeux de commentaires Linear KEY-* accumules en attente d acces token API. | Low | Resoudre method token hors-chat avant publication groupee. |

---

## 9. Linear text prepared (disclosure-controlled)

### 9.1 KEY-301 commentaire cible

```
## AS.12.2C-3.1 housekeeping : build scripts now produce OCI labels conformant to KEY-308

Gap G1 from AS.12.2C-3-PROD report resolved.

Scripts patched (no source change in api/client, no PROD build, no deploy, no manifest) :
- `scripts/build-api-from-git.sh` : capture GIT_SHA_FULL + pass `--build-arg IMAGE_REVISION/IMAGE_CREATED/IMAGE_VERSION` to docker build.
- `scripts/build-from-git.sh` : same fix + bug correction `APP_ENV="development"` in DEV so `NEXT_PUBLIC_APP_ENV` is always passed to satisfy the KEY-302 sentinel guard (`check-client-build-args.sh`).

Local throwaway tests (no push) confirm :
- API : OCI labels 5/5 PASS (revision=SHA complet, created=ISO UTC, version=tag, source, title).
- Client : OCI labels 5/5 PASS + sentinel absent + bundle DEV URLs correct (api-dev present, api.keybuzz.io absent).

Test images cleaned up locally. GHCR registry strictly unchanged. KEY-309 untouched.

No PROD impact. Existing PROD images (v3.5.182, v3.5.193, v3.5.183, v3.5.194) keep their current labels.

KEY-301 stays Open. NOT marked Done.

Remaining KEY-301 sub-phases : AS.12.2C-4 `/ai/execute` (P0 critical mutation) + AS.12.2C-5 `/ai/rules` (P1 admin).

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md
```

---

## 10. Compliance

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Aucun patch source `keybuzz-api` / `keybuzz-client` | OK |
| Aucun build PROD | OK |
| Aucun push GHCR | OK (test images supprimees, tag throwaway sans push) |
| Aucun deploy K8s | OK |
| Aucun manifest infra touche | OK |
| Aucune mutation DB | OK |
| Aucun secret display | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Tests locaux limites a tag throwaway DEV | OK |
| Test images supprimees apres verification | OK |

---

## 11. Phrase cible finale

AS.12.2C-3.1 livre : patch `scripts/build-api-from-git.sh` (+ 4 lignes : GIT_SHA_FULL capture + 3 ARGs OCI IMAGE_REVISION/IMAGE_CREATED/IMAGE_VERSION dans `docker build`) et `scripts/build-from-git.sh` (+ 5 lignes : GIT_SHA_FULL capture + 3 ARGs OCI + 1 ligne modifiee `APP_ENV="development"` en DEV pour satisfaire le KEY-302 guard `check-client-build-args.sh`) ; tests locaux DEV throwaway `v0.0.1-oci-args-fix-test-dev` API + Client = OCI labels 5/5 PASS (revision SHA complet, created ISO UTC, version tag, source, title) + sentinel `__MUST_BE_SET_BY_BUILD_ARG__` absent Client + `api-dev.keybuzz.io` x2 + `api.keybuzz.io` standalone x0 (bundle DEV correct) ; images test supprimees du daemon Docker bastion (aucun push GHCR effectue, KEY-309 sain) ; gap G1 du rapport AS.12.2C-3-PROD resolu ; PROD strictement inchange aucun build aucun deploy aucun manifest ; aucune mutation source `keybuzz-api`/`keybuzz-client` ; aucune mutation DB ; KEY-301 reste Open epic ; gap G1 residuel (`BUILD_TIME`/`GIT_COMMIT_SHA` warning sur API) + AS.12.2C-4 + AS.12.2C-5 restent a livrer ; verdict AS.12.2C-3.1 GO BUILD SCRIPTS OCI ARGS FIX READY.

STOP
