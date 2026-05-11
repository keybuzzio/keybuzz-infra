# PH-SAAS-T8.12AS.6-READONLY-SMOKE-AUTOMATION-FOUNDATION-01

> Date : 2026-05-11
> Linear : KEY-310 (principal)
> Phase : T8.12 AS.6 - readonly smoke harness V1 (source-only, no build, no deploy, no runtime mutation)
> Environnement : keybuzz-client source ; runtime DEV read-only ; runtime PROD non touche

---

## 1. VERDICT

GO READONLY SMOKE V1 SOURCE READY

NO BUILD / NO DEPLOY / NO RUNTIME MUTATION.

Resultats verifies sur bastion install-v3 :
- Harness ASCII strict, LF only, syntaxe bash valide (bash -n OK).
- Self-check anti-mutation actif au demarrage (refuse de tourner si curl -X (POST|PATCH|PUT|DELETE), --request mutation, -d ou --data present dans le script hors commentaires).
- Test 1 sans env minimale : FAIL safe avec messages clairs (exit 1).
- Test 2 --help : usage clair (exit 0).
- Test 3 full DEV env : PASS=18 WARN=0 FAIL=0 SKIP=1 RESULT=PASS (exit 0).

Detail Test 3 PASS :
- Runtime / GitOps : 6/6 (API DEV image match expected, manifest=last-applied, pod ready ; idem Client DEV).
- Bundle guard : 5/5 (pas de sentinel `__MUST_BE_SET_BY_BUILD_ARG__`, api-dev inline, PAS de PROD URL, labels Brouillon IA + Valider et envoyer presents).
- API DEV read-only : 4/4 (health, messages/conversations, stats/conversations, notifications escalation pending).
- Client / BFF : 3/3 (Client root reachable, /inbox reachable, /api/auth/session 200).
- Optional /autopilot/draft : SKIP (pas de SMOKE_CONVERSATION_ID fourni dans le test ; optionnel).

---

## 2. Scope

Source-only V1 :
- ajout dossier `scripts/smoke/` dans `keybuzz-client`.
- ajout 2 fichiers : `readonly-smoke-dev.sh` + `README.md`.
- ajout 1 fichier rapport docs dans `keybuzz-infra`.
- aucun changement Dockerfile / package.json / package-lock.json / next.config / app/ / src/ / docs/ (hors rapport infra).
- aucune dependance npm ajoutee.
- aucun secret ni token committe.
- aucun build, aucun docker push, aucun kubectl apply, aucun rollout.

Hors scope V1 (planifie V2/V3) :
- Playwright login complet
- clics UI
- Valider et envoyer
- creation fixtures
- tests Stripe / webhook / mutationnels
- mode PROD readonly (V1 ne contient pas de probe PROD)

---

## 3. Files added

Repo `keybuzz-client` (branche `ph148/onboarding-activation-replay`, commit `7a8a2fb`) :

| Path | Size | Mode | Role |
|---|---|---|---|
| `scripts/smoke/readonly-smoke-dev.sh` | 14359 bytes | 0755 | Main entrypoint, bash, GET-only, self-checked |
| `scripts/smoke/README.md` | 6232 bytes | 0644 | Documentation : guarantees, env, examples, V2/V3 roadmap |

Aucun autre fichier modifie ou ajoute. `tsconfig.tsbuildinfo` reste UNSTAGED (artefact connu de longue date, hors scope AS.6).

Repo `keybuzz-infra` (branche `main`) :

| Path | Role |
|---|---|
| `docs/PH-SAAS-T8.12AS.6-READONLY-SMOKE-AUTOMATION-FOUNDATION-01.md` | Ce rapport |

Aucun manifest, aucun fichier k8s/, aucun secret modifie.

Commit messages exacts :
- keybuzz-client : `test(smoke): add read-only DEV smoke harness (KEY-310)` (commit `7a8a2fb`)
- keybuzz-infra : `docs(qa): readonly smoke automation foundation (KEY-310)` (commit a creer sur GO Ludovic)

---

## 4. Read-only guarantees

Le harness garantit l absence totale de mutation par 4 couches :

### 4.1 Self-check au demarrage
Le script grep son propre code source (en excluant les lignes de commentaires) pour detecter et abandonner si :
- `curl -X (POST|PATCH|PUT|DELETE)` (regex `curl[^|;&]*[[:space:]]-X[[:space:]]*(POST|PATCH|PUT|DELETE)\b`)
- `curl --request (POST|PATCH|PUT|DELETE)`
- `curl -d` (flag body)
- `curl --data` / `--data-raw` / `--data-urlencode`

En cas de detection : message FATAL sur stderr, exit 1, avant toute requete HTTP. Verifie a chaque execution.

### 4.2 GET-only via wrappers
Toutes les requetes HTTP utilisent l un de ces trois wrappers :
- `probe_status URL [args]` : `curl -s -G -o /dev/null -w '%{http_code}' --max-time 8 ...`
- `probe_get URL [args]` : `curl -s -G -o /dev/null -w '%{http_code} %{size_download}' --max-time 8 ...`
- `probe_body URL OUTFILE [args]` : `curl -s -G -o OUTFILE -w '%{http_code} %{size_download}' --max-time 8 ...`

Le flag `-G` (alias `--get`) force la methode GET sur curl, meme si --data ou --data-urlencode est utilise (ce qui n est pas le cas ici).

### 4.3 Pas de mutation cluster
Les seuls appels kubectl sont `kubectl get` avec `-o jsonpath`. Aucun `apply`, `set`, `patch`, `edit`, `exec`, `delete`. Le bundle guard utilise `docker create` + `docker cp` + `docker rm`, qui ne modifient pas l image. Le conteneur cree est strictement local au bastion, jamais demarre.

### 4.4 Pas d affichage de PII / secrets
- Bodies API jamais imprimes en entier. Seuls les status codes, sizes, presence de literaux UI sont logges.
- Le probe `/autopilot/draft` parse le body localement via `node -e ...` et n imprime que `hasDraft`, `actionType`, `confidence`, `draftText_len`. La valeur `draftText` n est jamais imprimee.
- Pas de secret affiche : aucun header `Authorization` ou `Cookie` n est genere par le script. La seule header sensible-like est `x-user-email`, fournie via env SMOKE_USER_EMAIL (responsabilite operateur).

---

## 5. Checks implemented (V1)

| Section | Check | Action | Pass condition |
|---|---|---|---|
| A | API DEV runtime image | kubectl get deploy / jsonpath | match SMOKE_EXPECTED_API_IMAGE (si fourni) ou presence |
| A | API DEV spec = last-applied | kubectl annotation parse | spec image present dans annotation last-applied (GitOps no drift) |
| A | API DEV pod ready | kubectl get pods jsonpath | au moins un container status ready=true |
| A | Client DEV runtime image | idem | idem |
| A | Client DEV spec = last-applied | idem | idem |
| A | Client DEV pod ready | idem | idem |
| B | Bundle Client DEV - sentinel | docker create + cp + grep | aucun fichier ne contient `__MUST_BE_SET_BY_BUILD_ARG__` |
| B | Bundle Client DEV - api-dev URL | grep | presence `https://api-dev.keybuzz.io` |
| B | Bundle Client DEV - PROD URL absent | grep | absence `https://api.keybuzz.io` |
| B | Bundle Client DEV - label Brouillon IA | grep | presence litterale |
| B | Bundle Client DEV - label Valider et envoyer | grep | presence litterale |
| C | API /health | curl -G | status 200 |
| C | API /messages/conversations?tenantId=...&limit=1 | curl -G + headers BFF | status 200, 401, 403 ou 400 traites |
| C | API /stats/conversations?tenantId=... | idem | status 200 |
| C | API /notifications?tenantId=...&channel=escalation&status=pending&limit=1 | idem | status 200 |
| D | Client / | curl -G -L | status 200, 307 ou 302 (redirect auth) |
| D | Client /inbox | idem | idem |
| D | Client /api/auth/session | curl -G | status 200 (NextAuth shape) |
| E | /autopilot/draft (si SMOKE_CONVERSATION_ID) | curl -G body parse via node | status 200, hasDraft boolean, draftText_len numeric (jamais affiche le content) |

---

## 6. Checks intentionally excluded

Volontairement hors V1 :

| Categorie | Raison |
|---|---|
| Playwright full login | requiert dependance npm + credentials test ; V2 dediee |
| clic Valider et envoyer | MUTATION (envoi message) : interdit |
| clic Modifier sur draft | peut mutation ; V2 a designer si non-mutationnel |
| ack notifications | mutation |
| change status conversation | mutation |
| create / update / delete tenant, channel, supplier, order, agent | mutation |
| Stripe checkout / billing | mutation + cout |
| Webhook triggers | mutation systeme externe |
| tenantGuard mutationnel | risque + cible audit dedie KEY-301/304 |
| PROD probes profondes | mode PROD non implemente V1 |
| Image vulnerability scan / SBOM | hors smoke scope |

Ces sujets seront planifies V2/V3 apres validation V1 par Ludovic.

---

## 7. Test results (bastion install-v3)

### 7.1 bash -n syntax
```
syntax OK
```

### 7.2 Self-check grep defensif
```
no forbidden methods (OK)
```

### 7.3 Test 1 - fail-safe sans env
```
FATAL: required env SMOKE_API_BASE_URL is missing or empty
FATAL: required env SMOKE_BASE_URL is missing or empty
FATAL: required env SMOKE_TENANT_ID is missing or empty

Run "/tmp/readonly-smoke-dev.sh --help" for usage.
exit_code=1
```

### 7.4 Test 2 - --help
Affiche usage complet + required + optional + exit codes. Exit code 0.

### 7.5 Test 3 - full DEV env
Variables exportees :
- SMOKE_API_BASE_URL=https://api-dev.keybuzz.io
- SMOKE_BASE_URL=https://client-dev.keybuzz.io
- SMOKE_TENANT_ID=switaa-sasu-mnc1x4eq
- SMOKE_USER_EMAIL=(redacted, Ludovic email)
- SMOKE_EXPECTED_API_IMAGE=ghcr.io/keybuzzio/keybuzz-api:v3.5.168-escalation-notifications-dev
- SMOKE_EXPECTED_CLIENT_IMAGE=ghcr.io/keybuzzio/keybuzz-client:v3.5.179-as1-1-build-args-fix-dev

Resultat :
```
PASS=18 WARN=0 FAIL=0 SKIP=1
RESULT=PASS
exit_code=0
```

Detail PASS par section :
- A. Runtime / GitOps : 6/6
- B. Bundle guard : 5/5
- C. API DEV read-only : 4/4
- D. Client / BFF : 3/3
- E. Optional autopilot/draft : SKIP (SMOKE_CONVERSATION_ID non fourni)

Note section B : le bundle Client DEV v3.5.179 a ete extrait via `docker create` + `docker cp`. Aucun build, aucun push, conteneur supprime apres extraction (cleanup confirme).

---

## 8. How to run

### 8.1 Depuis bastion install-v3 (path canonical)
```
cd /opt/keybuzz/keybuzz-client
SMOKE_API_BASE_URL=https://api-dev.keybuzz.io \
SMOKE_BASE_URL=https://client-dev.keybuzz.io \
SMOKE_TENANT_ID=<tenant-id> \
SMOKE_USER_EMAIL=<authorized-email> \
SMOKE_EXPECTED_API_IMAGE=ghcr.io/keybuzzio/keybuzz-api:v3.5.168-escalation-notifications-dev \
SMOKE_EXPECTED_CLIENT_IMAGE=ghcr.io/keybuzzio/keybuzz-client:v3.5.179-as1-1-build-args-fix-dev \
  bash scripts/smoke/readonly-smoke-dev.sh
```

### 8.2 Avec /autopilot/draft probe optionnelle
Ajouter `SMOKE_CONVERSATION_ID=<conv-id-known-in-tenant>` au prefix env.

### 8.3 Degrade modes
- Sans kubectl : section A bascule en WARN (non-bloquant).
- Sans docker ou image non pullee localement : section B bascule en WARN.
- Sans NextAuth session : sections C et D restent en PASS si le BFF pattern x-user-email + x-tenant-id est honore ou en WARN si auth required.

### 8.4 Exit codes
- 0 : PASS ou PASS_WITH_WARNINGS
- 1 : FAIL (au moins un check FAIL) ou env minimale manquante

---

## 9. Gaps / V2

Propositions hors AS.6 :

1. **V2 - Playwright UI session dediee** : login automatique avec compte test (jamais Ludovic personnel), navigation Inbox SWITAA AUTOPILOT, assertions no-click sur les actions Valider/Modifier/Ignorer (presence DOM uniquement, jamais click), screenshots dans le rapport. Pre-requis : creer un compte test dedie + flag CI.
2. **V2 - mode PROD-readonly** : derriere SMOKE_ALLOW_PROD=true, probes strictement health + bundle parity (no body fetch, no /messages/conversations probe). Garde-fous : refuser de tourner si environnement detecte = PROD sans flag explicite.
3. **V2 - integration CI** : ajouter le smoke comme step de validation post-deploy DEV (apres rollout, avant marquer comme deployable PROD).
4. **V2 - logs scrubbing** : checker que les 30 dernieres secondes de logs API/Client DEV ne contiennent pas plus de N erreurs JWT/5xx (seuil configurable).
5. **V3 - extension multi-tenant** : run smoke contre plusieurs tenants (SWITAA AUTOPILOT, ecomlg-001 PRO, etc.) pour valider isolation.
6. **V3 - integration KEY-308 OCI labels** : asserter que `docker image inspect <image> --format '{{.Config.Labels.org.opencontainers.image.revision}}'` retourne un commit SHA reconnu par git.
7. **V3 - integration KEY-309 tag policy** : refuser smoke si l image runtime n a pas un tag immuable (no `:latest`, no re-use).

---

## 10. Linear text prepared, NOT posted

POSTING ON HOLD. Texte propose pour KEY-310 (statut suggere : In Review ou Done selon validation Ludovic post-merge) :

```
## AS.6 -- V1 livree (source-only)

Read-only smoke harness V1 ajoute dans keybuzz-client :
- scripts/smoke/readonly-smoke-dev.sh (bash, GET only, self-checked anti-mutation)
- scripts/smoke/README.md (documentation guarantees + env + examples)

Commit : 7a8a2fb sur branche ph148/onboarding-activation-replay.

Garanties anti-mutation :
- self-grep au demarrage refuse curl -X (POST/PATCH/PUT/DELETE), --request mutation, -d, --data*
- toutes les requetes HTTP utilisent curl -G (force GET)
- kubectl uniquement en mode get / jsonpath
- aucun body affiche, aucun secret affiche, aucune PII

Couverture V1 :
- Runtime/GitOps (image runtime = manifest = last-applied, pods ready)
- Bundle guard Client (sentinel absent, api-dev inline, PROD URL absent, labels Brouillon IA + Valider et envoyer presents)
- API DEV read-only (/health, /messages/conversations, /stats/conversations, /notifications escalation)
- Client / BFF read-only (/, /inbox, /api/auth/session)
- Optional /autopilot/draft (hasDraft / actionType / confidence / draftText length)

Test bastion install-v3 : PASS=18 WARN=0 FAIL=0 SKIP=1 (SMOKE_CONVERSATION_ID optionnel non fourni).

V2 (propose, hors AS.6) : Playwright UI session dediee + mode PROD-readonly + integration CI + logs scrubbing.

Aucun build, aucun deploy, aucun apply, aucun docker push, aucune mutation runtime/DB realises.
```

---

### 10.bis Phrase cible finale

AS.6 livre le harness V1 read-only en source-only sur `keybuzz-client/scripts/smoke/` (commit 7a8a2fb) avec resultat bastion PASS=18 WARN=0 FAIL=0 SKIP=1 ; garanties anti-mutation actives (self-check + curl -G partout) ; aucun build, aucun docker push, aucun kubectl apply, aucun rollout, aucune mutation runtime/DB ; runtime DEV (API v3.5.168 + Client v3.5.179) et PROD inchanges ; texte KEY-310 prepare en attente GO Ludovic ; verdict AS.6 GO READONLY SMOKE V1 SOURCE READY.

STOP
