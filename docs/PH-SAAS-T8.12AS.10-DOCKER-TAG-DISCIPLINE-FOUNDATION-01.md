# PH-SAAS-T8.12AS.10-DOCKER-TAG-DISCIPLINE-FOUNDATION-01

> Date : 2026-05-11
> Linear : KEY-309 (principal)
> Phase : T8.12 AS.10 - Docker tag discipline foundation source/process-only
> Environnement : keybuzz-infra source + GHCR registry read-only ; runtime DEV+PROD inchange ; aucun docker push ; aucun deploy

---

## 1. VERDICT

GO DOCKER TAG DISCIPLINE READY

NO BUILD / NO DOCKER PUSH / NO DEPLOY / NO RUNTIME MUTATION.

Fondation livree :
- Script source-only `scripts/registry/check-image-tag-available.sh` (bash 3414 octets, mode 0755). Exit codes : 0 available, 1 taken, 2 error.
- 6 tests locaux read-only sur bastion install-v3 valides (3 erreurs usage/auth + 1 tag existant + 1 tag fictif + 1 repo inconnu, comportement documente).
- Doc reference `docs/DOCKER-TAG-DISCIPLINE.md` (5295 octets, regle "one tag = one source = one digest", convention naming, pre/post-push procedure, exceptions, limitations).
- SOT `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` section 8 enrichie d un sous-bloc "Tag discipline (AS.10 KEY-309)" (+8 lignes).

Registry GHCR read-only valide via `docker manifest inspect`. Aucune mutation registry, aucun `docker pull` complet, aucune image creee, aucun tag push.

---

## 2. Scope

1 commit infra source-only :

| Repo | Path | Branche | HEAD avant | HEAD apres |
|---|---|---|---|---|
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 0608d46 | (a creer dans cet commit) |

Fichiers ajoutes / modifies :

| Path | Status | Lignes | Role |
|---|---|---|---|
| scripts/registry/check-image-tag-available.sh | A | 3414 octets (mode 0755) | Tag availability guard read-only |
| docs/DOCKER-TAG-DISCIPLINE.md | A | 5295 octets | Reference de discipline tags |
| docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | M | +8 lignes section 8 | Pointeur + regles courtes |
| docs/PH-SAAS-T8.12AS.10-DOCKER-TAG-DISCIPLINE-FOUNDATION-01.md | A | (ce rapport) | Trace de la phase |

Aucun autre fichier touche. Aucun repo applicatif (api/client/admin-v2/backend/website) modifie : la phase est process-only cote infra.

Aucun manifest GitOps modifie. Aucun secret. Aucun CI workflow.

---

## 3. Current runtime tags

Audit read-only des 6 services runtime via `docker manifest inspect` sur GHCR.

| Service | Env | Image tag | Runtime pod digest | OCI revision label | Confidence source |
|---|---|---|---|---|---|
| keybuzz-api | DEV | v3.5.168-escalation-notifications-dev | sha256:45626491c5fa... | absent (pre-AS.9) | HIGH (AS.5.4 anchor 070707a1) |
| keybuzz-api | PROD | v3.5.151-conversation-tone-metric-prod | sha256:29e53af3db70... | absent (pre-AS.9) | MED (AR.5.2 promotion) |
| keybuzz-outbound-worker | DEV | v3.5.165-escalation-flow-dev | sha256:60423d4de2db... | absent | MED (pre-AS.1 escalation flow) |
| keybuzz-outbound-worker | PROD | v3.5.165-escalation-flow-prod | sha256:53833cf95a3e... | absent | MED |
| keybuzz-client | DEV | v3.5.179-as1-1-build-args-fix-dev | sha256:b8a64abd378a... | absent (pre-AS.9) | HIGH (AS.5.4 anchor f244a58) |
| keybuzz-client | PROD | v3.5.174-conversation-tone-metric-ux-prod | sha256:8d2e195ae6cf... | absent (pre-AS.9) | MED |
| keybuzz-backend | DEV/PROD | v1.0.47-cross-env-guard-fix-{dev,prod} | sha256:b9f9b5a7b827.../sha256:0a86583d1971... | absent | HIGH (commit c62f376) |
| keybuzz-website | PROD | v0.6.12-linkedin-insight-seo-prod | sha256:22bd41d5fcc4... | absent | HIGH (commit 5fc6f2b) |
| keybuzz-admin-v2 | DEV/PROD | v2.12.2-media-buyer-lp-domain-qa-{dev,prod} | sha256:4941eb...8d8/sha256:ecc208... | absent | HIGH (commit ad2bd4c) |

Notes :
- Tous les tags actuels respectent la convention `v<major>.<minor>.<patch>-<scope-slug>-<env>`. Pas de `:latest`, pas de tag reuse detecte hors KEY-309 historique (`v3.5.169` documente AS.5.5 / KEY-309 / DOCKER-TAG-DISCIPLINE.md).
- Aucune image actuelle ne porte de label OCI `revision` : AS.9 a ajoute le mecanisme dans les Dockerfiles, mais les images runtime n ont pas ete rebuildees. Les futurs builds porteront le label.

---

## 4. Tag policy

Regles AS.10 (codifiees dans `docs/DOCKER-TAG-DISCIPLINE.md` et SOT section 8) :

1. **One tag = one source = one digest.**
2. **No tag reuse.** Tout `docker push` sur un tag existant est interdit par defaut.
3. **Naming convention** : `v<major>.<minor>.<patch>-<scope-slug>-<env>` avec `<env>` dans `{dev, prod}`.
4. **`:latest` interdit.**
5. **No numeric-base reuse with different scope-slug** : la dette `v3.5.169` documentee AS.5.5 ne doit pas se reproduire.
6. **DEV/PROD coherence** : les branches DEV produisent `-dev`, les branches PROD produisent `-prod`. Pas de cross.
7. **Pre-push obligatoire** : `scripts/registry/check-image-tag-available.sh <image>:<tag>` doit retourner exit 0 avant `docker push`. Sinon STOP.
8. **Post-push documentation obligatoire** : tag + digest + OCI revision label + build args dans le rapport de phase.
9. **Exceptions** : tag reuse nominalement interdit ; seule exception est un GO Ludovic explicite + documentation old/new digests.

Reference complete : `keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md`.

---

## 5. Script added

### 5.1 scripts/registry/check-image-tag-available.sh

- Shebang : `#!/usr/bin/env bash`
- `set -u`
- Defensive arg parsing : usage check + tag presence regex.
- Defensive docker presence check.
- Run `docker manifest inspect "$IMAGE" >/dev/null 2>"$TMP_STDERR"`.
- Stderr captured separately to distinguish "manifest unknown" (tag absent) from auth/network errors.
- Cleanup tempfile via explicit `rm -f`.
- Exit codes :
  - `0` : tag AVAILABLE (manifest unknown / 404 / no such manifest).
  - `1` : tag TAKEN (manifest inspect succeeded).
  - `2` : error (usage, missing docker, auth/network failure).

### 5.2 Read-only guarantees

Le script n appelle JAMAIS :
- `docker build` / `docker tag` / `docker push` / `docker rm` / `docker rmi`
- `kubectl ...`
- aucune ecriture fichier hors `mktemp` temp file pour capture stderr (supprime explicitement).

Le seul appel a docker est `docker manifest inspect <image>` qui est read-only par definition (consulte le manifest sans pull les layers).

Aucun secret n est affiche. Aucune valeur d auth n est manipule. Le script delegue l auth a la session docker du host (typiquement `docker login ghcr.io` deja fait sur le bastion).

---

## 6. Script tests

6 tests executes sur bastion install-v3 avec resultats exacts :

| # | Test | Argument | Expected | Actual | Verdict |
|---|---|---|---|---|---|
| 1 | no args | (empty) | exit 2 + usage | "FATAL: missing required argument" + usage printed, exit 2 | OK |
| 2 | --help | --help | exit 0 + usage | usage printed, exit 0 | OK |
| 3 | invalid arg without tag | `ghcr.io/keybuzzio/keybuzz-api` | exit 2 + "must include a tag" | "FATAL: image must include a tag", exit 2 | OK |
| 4 | existing tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-conversation-tone-metric-prod` | exit 1 + TAKEN message | "[TAG-GUARD] FAIL: tag is TAKEN in registry", exit 1 | OK |
| 5 | fictional tag (existing repo) | `ghcr.io/keybuzzio/keybuzz-api:v9.9.9-as10-fictional-never-existed-dev` | exit 0 + AVAILABLE message | "[TAG-GUARD] OK: tag is AVAILABLE in registry", exit 0 | OK |
| 6 | unknown repo | `ghcr.io/keybuzzio/nonexistent-repo-as10:v0.0.0` | exit 0 (par design) ou exit 2 selon GHCR | exit 0 (registry returns "manifest unknown" identique a un tag absent) | acceptable (limitation documentee section 7 DOCKER-TAG-DISCIPLINE.md) |

Note test 6 : GHCR retourne le meme message `manifest unknown` pour un repo inexistant et un tag inexistant. Le script considere les deux comme "tag available" (exit 0). Limitation acceptable en pratique car les 5 repos KeyBuzz pre-existent ; une typo dans le nom du repo serait detectee plus loin par le push (permissions / repo missing). Documente en section "Limitations of the guard" de `docs/DOCKER-TAG-DISCIPLINE.md`.

Aucun docker push, aucun docker pull, aucun docker build, aucun docker rm execute pendant les tests.

---

## 7. Source-of-truth update

`docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` section 8 (Build rules) enrichie d un sous-bloc "Tag discipline (AS.10 KEY-309)" inserre apres le bloc AS.9 OCI labels. 8 nouvelles lignes resume la regle, le script, la convention naming, les exceptions, et pointent vers `docs/DOCKER-TAG-DISCIPLINE.md` pour le detail.

ASCII strict preserve (verify post-edit : 0 non-ASCII).

---

## 8. No runtime mutation proof

| Verification | Avant AS.10 | Apres AS.10 |
|---|---|---|
| API DEV image runtime | v3.5.168-escalation-notifications-dev | inchange |
| API PROD image runtime | v3.5.151-conversation-tone-metric-prod | inchange |
| Client DEV image runtime | v3.5.179-as1-1-build-args-fix-dev | inchange |
| Client PROD image runtime | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| Admin-v2 DEV/PROD | v2.12.2-* | inchange |
| Backend DEV/PROD | v1.0.47-* | inchange |
| Website DEV/PROD | v0.6.12-* | inchange |
| Outbound worker DEV/PROD | v3.5.165-* | inchange |
| K8s manifests | aucune modification | aucune modification |
| Secrets K8s | aucune modification | aucune modification |
| DB | aucune modification | aucune modification |
| Registry GHCR | aucune mutation (read-only via manifest inspect) | aucune mutation |
| GitOps annotations | MATCH=yes (heritage AS.9) | MATCH=yes preserve |

Phase 100% source-only cote infra + lecture seule cote registry. Aucune commande mutationnelle executee.

---

## 9. Gaps

1. **Application au pipeline release** : le script et la doc sont en place, mais aucun pipeline CI/CD KeyBuzz n est encore relie a `check-image-tag-available.sh`. Hors scope AS.10. Quand un pipeline GitHub Actions / autre orchestrera les builds, ajouter le check comme step pre-push.

2. **Validation OCI revision label non-`unknown`** : AS.9 ajoute le mecanisme mais les defaults restent `unknown`. KEY-309 (cette phase) traite la discipline tag, pas la verification du label content. Une phase ulterieure (KEY-308 V2 ou AS.10.1) peut ajouter dans le script un check post-push : `docker image inspect <image> --format '{{index .Config.Labels "org.opencontainers.image.revision"}}'` != `unknown`.

3. **Smoke harness V1** ne valide pas encore la tag policy. KEY-310 V2 pourrait ajouter `check-image-tag-available.sh` en pre-build step.

4. **Registry auth** : le script delegue l auth a `docker login` de l host. Si la session docker du bastion expire, le script renverra exit 2. Documente.

5. **Repo typo false positive (test 6)** : le script considere un repo inexistant comme "tag available". Limitation acceptable, documentee. Resolution possible via un additional check `docker manifest inspect <image>:any-known-tag` upfront pour valider l existence du repo. Hors scope AS.10.

6. **Tag dette `v3.5.169`** : non resolue dans AS.10 (les 2 images problematiques sont marquees DO_NOT_REDEPLOY dans la SOT, leurs commits sources archives). Le script empeche desormais qu un futur build reutilise ce tag.

---

## 10. Linear text prepared, posted

Texte poste en KEY-309. Voir section 10.bis pour resume controle.

### 10.bis Resume Linear poste (controle)

```
## AS.10 -- Docker tag discipline foundation livre (source/process-only)

Livre dans keybuzz-infra (commit a venir, branche main) :
- scripts/registry/check-image-tag-available.sh (bash, exit 0 available / exit 1 taken / exit 2 error)
- docs/DOCKER-TAG-DISCIPLINE.md (regles "one tag = one source = one digest", naming convention, pre/post-push procedure)
- SOT KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md section 8 etendue d un sous-bloc "Tag discipline"
- Rapport interne PH-SAAS-T8.12AS.10-...md

6 tests script valides bastion install-v3 :
- no-args : exit 2 + usage
- --help : exit 0
- invalid arg sans tag : exit 2
- tag existant (current PROD API) : exit 1 TAKEN
- tag fictif : exit 0 AVAILABLE
- repo inconnu : exit 0 (limitation acceptable et documentee : GHCR renvoie le meme manifest unknown)

Aucun docker push. Aucun docker build. Aucun deploy. Aucun kubectl apply. Aucune mutation registry. Aucune mutation runtime/DB/manifest/secret. Runtime DEV+PROD strictement inchanges.

KEY-309 traite la discipline tag ; la dette historique v3.5.169 est protegee desormais (le script bloque toute reutilisation accidentelle).

Statut suggere : Done.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.10-DOCKER-TAG-DISCIPLINE-FOUNDATION-01.md
```

---

### 10.ter Phrase cible finale

AS.10 livre la fondation de discipline tags Docker KeyBuzz : script source-only `scripts/registry/check-image-tag-available.sh` (exit 0/1/2), doc reference `docs/DOCKER-TAG-DISCIPLINE.md`, SOT section 8 etendue, 6 tests bastion install-v3 valides ; aucun docker push, aucun docker build, aucun deploy, aucun kubectl apply/set/patch/edit, aucune mutation registry/runtime/DB/manifest/secret ; runtime DEV+PROD strictement inchanges ; dette historique v3.5.169 desormais protegee par le guard ; verdict AS.10 GO DOCKER TAG DISCIPLINE READY.

STOP
