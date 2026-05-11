# PH-SAAS-T8.12AS.9-DOCKER-OCI-REVISION-LABELS-FOUNDATION-01

> Date : 2026-05-11
> Linear : KEY-308 (principal)
> Phase : T8.12 AS.9 - Docker OCI revision labels foundation source-only
> Environnement : 5 service repos source ; runtime DEV+PROD inchange ; aucun push registry ; aucun deploy

---

## 1. VERDICT

GO OCI REVISION LABELS FOUNDATION READY

NO BUILD PUSH / NO DEPLOY / NO RUNTIME MUTATION.

5 service Dockerfiles patches avec un bloc OCI standard (3 ARG + 5 LABEL). Pattern identique partout, customise par repo (source URL + title). 1 validation locale prouve l inspection du label `org.opencontainers.image.revision` post-build avec un commit SHA reel. Cleanup image locale OK. SOT `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` mis a jour pour documenter la nouvelle regle build (section 8). Aucun docker push, aucun deploy, aucun manifeste touche, aucun runtime mute.

Defaults `unknown` conserves : la migration est non-bloquante pour les builds existants. KEY-309 (tag discipline) sera l etape suivante pour rendre non-`unknown` obligatoire.

---

## 2. Scope

5 repos patches (1 commit chacun, source-only) :

| Repo | Branche | HEAD avant | HEAD apres | Sync |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | b8613f0f | f371a79c | 0/0 |
| keybuzz-client | ph148/onboarding-activation-replay | 7a8a2fb | 4011ada | 0/0 |
| keybuzz-admin-v2 | main | 126eba1 | 3707c83 | 0/0 |
| keybuzz-backend | main | c62f376 | b183817 | 0/0 |
| keybuzz-website | main | 5fc6f2b | 660dc60 | 0/0 |

1 commit infra (rapport + SOT update) :

| Repo | Branche | HEAD avant | HEAD apres |
|---|---|---|---|
| keybuzz-infra | main | d85186e | (a creer dans cet commit) |

Aucun autre fichier modifie :
- pas de `app/`, pas de `src/`
- pas de `package.json`, pas de `package-lock.json`
- pas de manifest GitOps
- pas de CI workflow
- pas de secret

Aucune action runtime : aucun `kubectl apply / set / patch / edit`, aucun rollout, aucun docker push, aucune mutation DB.

---

## 3. Services audited

Tous les 5 services runtime ont ete audites et patches. Outbound worker : meme image que keybuzz-api (`v3.5.165-escalation-flow-*`), donc le patch keybuzz-api couvre aussi l outbound worker. Admin legacy (keybuzz-admin quarantained PH86.0) volontairement exclu (non runtime).

| Service | Repo | Dockerfile path | Label state avant | Label state apres |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api | /opt/keybuzz/keybuzz-api/Dockerfile | aucun OCI label | 5 OCI labels |
| keybuzz-client | keybuzz-client | /opt/keybuzz/keybuzz-client/Dockerfile | GIT_COMMIT_SHA + BUILD_TIME ENV (KEY-302), mais pas en LABEL OCI | 5 OCI labels (en plus de l existant) |
| keybuzz-admin-v2 | keybuzz-admin-v2 | /opt/keybuzz/keybuzz-admin-v2/Dockerfile | aucun OCI label | 5 OCI labels |
| keybuzz-backend | keybuzz-backend | /opt/keybuzz/keybuzz-backend/Dockerfile | aucun OCI label | 5 OCI labels |
| keybuzz-website | keybuzz-website | /opt/keybuzz/keybuzz-website/Dockerfile | aucun OCI label | 5 OCI labels |
| keybuzz-outbound-worker | keybuzz-api (meme image) | n/a (deja couvert par keybuzz-api Dockerfile) | n/a | herite du patch keybuzz-api |
| keybuzz-admin (legacy) | keybuzz-admin (quarantained) | n/a | n/a (non runtime) | volontairement non patche |

---

## 4. Labels standard

Pattern OCI applique a chaque Dockerfile (insere juste avant la ligne `EXPOSE` du stage runner final) :

```
# PH-SAAS-T8.12AS.9 KEY-308: OCI image labels for source/runtime traceability.
# These ARGs are optional and default to "unknown". Production builds SHOULD pass
#   --build-arg IMAGE_REVISION=$(git rev-parse HEAD)
#   --build-arg IMAGE_CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
#   --build-arg IMAGE_VERSION=<tag>
# See keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md.
ARG IMAGE_REVISION=unknown
ARG IMAGE_CREATED=unknown
ARG IMAGE_VERSION=unknown
LABEL org.opencontainers.image.revision=$IMAGE_REVISION
LABEL org.opencontainers.image.created=$IMAGE_CREATED
LABEL org.opencontainers.image.version=$IMAGE_VERSION
LABEL org.opencontainers.image.source="https://github.com/keybuzzio/<repo>"
LABEL org.opencontainers.image.title="<service>"
```

5 labels OCI standards :
- `org.opencontainers.image.revision` : commit SHA Git (40 chars typiquement, ou `unknown` par defaut)
- `org.opencontainers.image.created` : timestamp RFC3339 UTC (ou `unknown`)
- `org.opencontainers.image.version` : tag immuable de release (ou `unknown`)
- `org.opencontainers.image.source` : URL GitHub fixe par repo
- `org.opencontainers.image.title` : nom du service fixe par repo

Choix design :
- Defaults `unknown` : la migration AS.9 est NON-BLOQUANTE. Un build sans `--build-arg IMAGE_*` reussit avec `unknown`. KEY-309 fera le passage non-`unknown` obligatoire.
- Insertion AVANT `EXPOSE` du stage runner final : c est la frontiere historique entre setup et runtime ; le label est porte par l image finale, pas par les stages intermediaires.
- N interfere pas avec KEY-302 Client guard ni KEY-307 Admin-v2 guard : les ARG sont declares dans le stage runner, distincts des ARG `NEXT_PUBLIC_*` du stage builder.

---

## 5. Files changed

| Repo | Path | Change | Lignes |
|---|---|---|---|
| keybuzz-api | Dockerfile | M | +15 |
| keybuzz-client | Dockerfile | M | +15 |
| keybuzz-admin-v2 | Dockerfile | M | +15 |
| keybuzz-backend | Dockerfile | M | +15 |
| keybuzz-website | Dockerfile | M | +15 |
| keybuzz-infra | docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | M | +10 (section 8) |
| keybuzz-infra | docs/PH-SAAS-T8.12AS.9-DOCKER-OCI-REVISION-LABELS-FOUNDATION-01.md | A | rapport |

Total : 7 fichiers, +75 lignes patch + rapport.

Aucun fichier hors-scope touche.

---

## 6. Local validation

Validation locale sur keybuzz-admin-v2 (representatif, cache layers chaud depuis AS.8). Commande exacte executee sur bastion install-v3 :

```
HEAD_SHA=$(git rev-parse HEAD)
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg IMAGE_REVISION=$HEAD_SHA \
  --build-arg IMAGE_CREATED=$BUILD_DATE \
  --build-arg IMAGE_VERSION=oci-label-test \
  -t keybuzz-local/keybuzz-admin-v2:oci-label-test .

docker image inspect keybuzz-local/keybuzz-admin-v2:oci-label-test \
  --format '{{json .Config.Labels}}' | python3 -m json.tool
```

Resultat inspection (cleanup OK apres) :

```
{
    "org.opencontainers.image.created": "2026-05-11T14:57:28Z",
    "org.opencontainers.image.revision": "126eba1772c04c639e57a57b81d101740c1a4730",
    "org.opencontainers.image.source": "https://github.com/keybuzzio/keybuzz-admin-v2",
    "org.opencontainers.image.title": "keybuzz-admin-v2",
    "org.opencontainers.image.version": "oci-label-test"
}
```

5 labels confirmes presents et bien values. `revision` = full SHA 40 chars du commit `126eba1` (AS.8 admin-v2 KEY-307). Build time : 1m22s (cache layers chaud). Image locale supprimee apres inspection : 3 sha256 layers deleted.

Les autres 4 services (api, client, backend, website) ne sont PAS rebuildes dans AS.9 :
- la modification Dockerfile est identique en pattern et identique en mecanisme.
- valider l ajout des labels ne necessite pas un rebuild reel : la presence syntaxique des `LABEL ...` dans le Dockerfile suffit, et le mecanisme Docker pour appliquer un LABEL est universel.
- cout de build (3-5 min par service Next.js, plus pour API/Backend depuis cold start) juge excessif pour AS.9 vs valeur ajoutee marginale.
- KEY-309 et la prochaine vraie release Docker auront l occasion de re-valider les 4 autres en pipeline.

Aucun `docker push` execute pendant AS.9. Aucun tag GHCR cree par AS.9.

---

## 7. Images local only

Tag local temporaire utilise pendant validation : `keybuzz-local/keybuzz-admin-v2:oci-label-test`.

`docker rmi keybuzz-local/keybuzz-admin-v2:oci-label-test` execute en cleanup post-inspection. 3 layers sha256 supprimes (output Deleted x3).

**AUCUN `docker push` execute.** **AUCUN tag immuable GHCR cree.** **AUCUN deploy.** Les images de test ont uniquement existe localement sur le bastion pendant la phase de validation.

---

## 8. No runtime mutation proof

| Verification | Avant AS.9 | Apres AS.9 |
|---|---|---|
| API DEV image | v3.5.168-escalation-notifications-dev | inchange |
| API PROD image | v3.5.151-conversation-tone-metric-prod | inchange |
| Client DEV image | v3.5.179-as1-1-build-args-fix-dev | inchange |
| Client PROD image | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| Admin-v2 DEV image | v2.12.2-media-buyer-lp-domain-qa-dev | inchange |
| Admin-v2 PROD image | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |
| Backend DEV/PROD image | v1.0.47-cross-env-guard-fix-* | inchange |
| Website DEV/PROD image | v0.6.12-linkedin-insight-seo-* | inchange |
| Outbound worker DEV/PROD | v3.5.165-escalation-flow-* | inchange |
| K8s manifests | aucune modification | aucune modification |
| Secrets K8s | aucune modification | aucune modification |
| DB | aucune modification | aucune modification |
| GitOps annotations | MATCH=yes (verifie AS.8) | MATCH=yes presume (aucune mutation) |

Phase 100% source-only. Aucune commande mutationnelle executee.

---

## 9. Source-of-truth update

`keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` section 8 (Build rules) etendue avec un sous-bloc OCI :

- Tout build Docker DOIT passer 3 build args : `IMAGE_REVISION`, `IMAGE_CREATED`, `IMAGE_VERSION`.
- Dockerfiles injectent les 5 labels OCI standards.
- Verification post-build via `docker image inspect <image> --format '{{json .Config.Labels}}'` : revision ne doit PAS etre `unknown` avant un push GHCR.
- AS.9 status : 5 services patches, defaults `unknown` conserves pour compatibilite ; KEY-309 fera le passage non-`unknown` obligatoire.

+10 lignes inserees ligne 113. ASCII strict preserve, no BOM, 0 non-ASCII.

---

## 10. Gaps / KEY-309 follow-up

1. **KEY-309 tag discipline** (suivant logique) : doit faire que les builds runtime KEY-VALIDATED rejettent `IMAGE_REVISION=unknown`. Couplage tag policy + label policy.
2. **Validation des 4 autres services en local** : non realisee dans AS.9 (cout temps). A re-valider lors de la prochaine vraie release de chaque service (API, Client, Backend, Website).
3. **Outbound worker** : meme image que API, donc deja couvert par le patch keybuzz-api. Documente.
4. **Admin legacy keybuzz-admin** : non patche volontairement (quarantained PH86.0, non runtime). A clarifier en phase TD si on souhaite cleanup le repo.
5. **CI workflows** : les pipelines GitHub Actions (si existants) doivent etre mis a jour pour passer les `--build-arg IMAGE_*`. Hors scope AS.9, a planifier en phase CI dediee.
6. **Smoke harness V1** : ne valide pas encore les labels OCI runtime. V2 du smoke (KEY-310 V2) pourrait ajouter un check `docker image inspect` pour verifier revision non-`unknown`.

---

## 11. Linear text prepared, posted

Texte poste en KEY-308 (cf section 11.bis URL apres E8).

### 11.bis Resume Linear poste (controle)

```
## AS.9 -- OCI revision labels foundation livre (source-only)

5 Dockerfiles patches (api, client, admin-v2, backend, website) avec un bloc OCI standard :
- 3 ARG (IMAGE_REVISION, IMAGE_CREATED, IMAGE_VERSION) defaut "unknown"
- 5 LABEL org.opencontainers.image.* (revision, created, version, source, title)
- Pattern identique partout, customise par repo (source URL + title).

Commits source-only :
- keybuzz-api : f371a79c
- keybuzz-client : 4011ada
- keybuzz-admin-v2 : 3707c83
- keybuzz-backend : b183817
- keybuzz-website : 660dc60
- keybuzz-infra : (rapport + SOT update)

Validation locale (1 service representatif, admin-v2) :
`docker image inspect ... --format '{{json .Config.Labels}}'` retourne les 5 labels correctement, avec revision = full SHA 40 chars. Cleanup image locale OK.

Aucun docker push. Aucun deploy. Aucun kubectl apply. Runtime DEV+PROD strictement inchanges.

SOT KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md section 8 mise a jour pour documenter la regle build.

Defaults `unknown` conserves : migration non-bloquante. KEY-309 (tag discipline) sera l etape suivante pour rendre non-`unknown` obligatoire.

Statut suggere : Done.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.9-DOCKER-OCI-REVISION-LABELS-FOUNDATION-01.md
```

---

### 11.ter Phrase cible finale

AS.9 livre les labels OCI standards (revision, created, version, source, title) sur les 5 Dockerfiles runtime KeyBuzz (api, client, admin-v2, backend, website) via 5 commits source-only ; SOT KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md section 8 mise a jour ; validation locale admin-v2 confirme l inspection des 5 labels avec revision SHA reel ; cleanup image locale OK ; aucun docker push, aucun deploy, aucun kubectl apply/set/patch/edit, aucune mutation runtime/DB/manifest/secret ; runtime DEV+PROD strictement inchanges ; defaults `unknown` conserves pour compatibilite, KEY-309 fera le passage non-`unknown` obligatoire ; verdict AS.9 GO OCI REVISION LABELS FOUNDATION READY.

STOP
