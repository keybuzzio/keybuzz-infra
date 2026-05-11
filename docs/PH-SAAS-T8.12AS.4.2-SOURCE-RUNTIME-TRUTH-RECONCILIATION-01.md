# PH-SAAS-T8.12AS.4.2 -- Source Runtime Truth Reconciliation

> Date : 2026-05-11
> Linear : KEY-304 + KEY-301 + KEY-263 + KEY-302
> Phase : reconciliation source/runtime apres rollback securite AS.4.1
> Environnement : DEV + PROD READ-ONLY STRICT -- aucun patch, aucun build, aucun deploy, aucune mutation

## VERDICT

**GO PARTIEL -- RUNTIME STABLE BUT SOURCE REQUIRES REVERT PLAN -- NO MUTATION**

Le runtime DEV et PROD sont stables et alignes avec leurs manifests respectifs. AUCUNE mutation runtime, build, deploy ou DB n'a ete faite pendant cette phase. Les manifests infra reflechissent l'etat operationnel reel : pas de drift GitOps.

CEPENDANT, les branches source `keybuzz-api` et `keybuzz-client` contiennent au-dessus de leurs commits safe respectifs des commits experimentaux KEY-304 deja rollbackes en runtime. Si un build est lance depuis ces HEAD sans plan, il reconstruira les images qui ont casse DEV (api v3.5.169 + client v3.5.180/181/182) avec retour identique des regressions canaux/catalogue/AI.

Une phase de reconciliation source dediee (PH-SAAS-T8.12AS.4.3 a creer) doit revert proprement les commits experimentaux via nouveaux commits, sans reset ni clean ni reecriture d'historique. Cette phase de reconciliation N'EST PAS executee ici. Le plan complet est documente section 7. Aucun build ne doit etre lance avant son execution.

PROD strictement inchangee. KEY-301 et KEY-304 restent OPEN. AS.1 PROD reste BLOQUE.

---

## 0. Preflight repos

| Repo | Branche attendue | Branche reelle | HEAD | Sync origin | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 4d88e989 | 0 / 0 | 223 D dist/*.js artifacts (sans .gitignore, deletions locales heritage de npm clean) | OK COMPRIS |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | a032d83 | 0 / 0 | 1 M tsconfig.tsbuildinfo (artifact build) | OK COMPRIS |
| keybuzz-infra | main | main | a3aee26 | 0 / 0 | clean | OK |
| keybuzz-backend | main | main | c62f376 | 0 / 0 | 1 untracked .bak (artifact dev) | OK |
| keybuzz-admin | main | main | e4bffe7 | 0 / 0 | 14 fichiers (Dockerfile, package*.json, src/features/messages/*, app/api/, app/debug/version/, MessageBubble.tsx.bak, QUARANTINED.md) -- work-in-progress dev PRE-EXISTANT non lie a AS.4.x ni a aucun ticket securite | OK COMPRIS HORS SCOPE |
| keybuzz-website | main | main | 5fc6f2b | 0 / 0 | clean | OK |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Runtime baseline DEV/PROD (READ-ONLY)

### Etat alignement manifest = runtime = annotation

| Service | Runtime image | Last-applied | Match | Ready |
|---|---|---|---|---|
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.168-escalation-notifications-dev | identique | OK | 1/1 Running |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.179-as1-1-build-args-fix-dev | identique | OK | 1/1 Running |
| Backend DEV | ghcr.io/keybuzzio/keybuzz-backend:v1.0.47-cross-env-guard-fix-dev | identique | OK | 1/1 Running |
| OW DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev | identique | OK | 1/1 Running |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.151-conversation-tone-metric-prod | identique | OK | 1/1 Running |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.174-conversation-tone-metric-ux-prod | identique | OK | 1/1 Running |
| Backend PROD | ghcr.io/keybuzzio/keybuzz-backend:v1.0.47-cross-env-guard-fix-prod | identique | OK | 1/1 Running |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.6.12-linkedin-insight-seo-prod | identique | OK | 1/1 Running |
| Admin PROD | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | identique | OK | 1/1 Running |
| OW PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod | identique | OK | 1/1 Running |

Aucun drift GitOps. Aucun pod crashloop. DEV restaure. PROD inchangee.

---

## 2. API source/runtime mapping (keybuzz-api)

| Commit | Sujet | Image liee | Runtime actuel ? | Statut |
|---|---|---|---|---|
| 4d88e989 (HEAD) | fix(security): apply tenant guard globally across Fastify routes (KEY-304) | v3.5.169-tenant-guard-scope-fix-dev (registry+local cache) | NON | EXPERIMENTAL_ROLLED_BACK |
| 070707a1 (parent) | feat(notifications): internal escalation notifications + tenant-scoped routes (PH-SAAS-T8.12AS.1, KEY-263) | v3.5.168-escalation-notifications-dev | OUI | SAFE_RUNTIME_SOURCE |
| 0e26bfc3 et anterieurs | AR.x baselines | (images PROD/DEV anterieures) | n/a | GOOD_SOURCE_NOT_RUNTIME |

Diff 070707a1..4d88e989 :

```
src/app.ts                    |  4 +-
src/modules/tenants/routes.ts | 69 ++++++++++++++++++++++++++++++--------
src/plugins/tenantGuard.ts    | 77 +++++++++++++++++++++++++++++--------------
3 files changed, 111 insertions(+), 39 deletions(-)
```

Decision recommandee API : revert 4d88e989 par un nouveau commit de revert (Option A etape 7). HEAD revient effectivement a un etat fonctionnellement equivalent a 070707a1. Aucun reset, aucune reecriture d'historique, le commit experimental reste lisible dans le log mais devient inactif au build.

---

## 3. Client source/runtime mapping (keybuzz-client)

| Commit | Sujet | Image liee | Runtime actuel ? | Statut |
|---|---|---|---|---|
| a032d83 (HEAD) | fix(client-bff): drop tenantRequired enforcement (KEY-304) | v3.5.182-tenant-guard-bff-compat-fix2-dev | NON | EXPERIMENTAL_ROLLED_BACK |
| 49a99f9 | fix(ai-assistant): use BFF /api/ai/assist (KEY-304) | v3.5.181-tenant-guard-bff-compat-fix-dev | NON | EXPERIMENTAL_ROLLED_BACK |
| de498b0 | fix(client): proxy via BFF allowlist (KEY-304) | v3.5.180-tenant-guard-bff-compat-dev | NON | EXPERIMENTAL_ROLLED_BACK |
| f244a58 | fix(client-build): require explicit API build args for safe bundles (KEY-302) | v3.5.179-as1-1-build-args-fix-dev | OUI | SAFE_RUNTIME_SOURCE |
| a69477a | fix(inbox): unwire AS.1 escalation badge from InboxTripane (KEY-263) | n/a directement (parent de v3.5.179 build chain) | NON | GOOD_SOURCE_NOT_RUNTIME |
| 37e70ac | feat(inbox): escalation notifications badge + tenant-scoped client (KEY-263 AS.1) | v3.5.177 + v3.5.178 (obsoletes / buggy) | NON | GOOD_SOURCE_NOT_RUNTIME |
| 0a7306a (parent AR.5.1) | conversation tone card | (anciens builds) | n/a | GOOD_SOURCE_NOT_RUNTIME |

Diff f244a58..a032d83 :

```
app/api/proxy/[...path]/route.ts          | 174 ++++++++++++++++++++++++++++++
src/config/api.ts                         |   3 +-
src/features/ai-assistant/AIAssistant.tsx |   3 +-
3 files changed, 178 insertions(+), 2 deletions(-)
```

Decision recommandee Client : revert successif des 3 commits experimentaux dans l'ordre inverse de creation (a032d83, 49a99f9, de498b0) par 3 nouveaux commits de revert. HEAD revient effectivement a un etat fonctionnellement equivalent a f244a58. Le commit f244a58 (KEY-302) doit etre preserve absolument.

---

## 4. Infra GitOps history mapping

| Commit | Sujet | Action runtime | Etat final conservation | Statut |
|---|---|---|---|---|
| a3aee26 (HEAD) | docs(security): tenant guard BFF compat and DEV patch validation (KEY-304) | aucune | OUI | DOC |
| 1d99421 | rollback(dev): tenant guard security patch -- new Client regressions (KEY-304) | apply API v3.5.168 + Client v3.5.179 -- restaure cible stable runtime actuel | OUI | ROLLBACK_RESTORE |
| b962592 | deploy(client-dev): v3.5.182 (KEY-304) | apply -- rollbacke par 1d99421 | NON | DEPLOY_REVERTED |
| 0af9d90 | deploy(client-dev): v3.5.181 (KEY-304) | apply -- rollbacke par 1d99421 | NON | DEPLOY_REVERTED |
| 34eeab6 | deploy(dev): tenant guard security patch with BFF compatibility (KEY-304) -- API v3.5.169 + Client v3.5.180 | apply -- rollbacke par 1d99421 | NON | DEPLOY_REVERTED |
| 965e2c0 | docs(security): audit tenantGuard runtime truth before AS.1 promotion (KEY-301) | aucune | OUI | DOC |
| cb55a42 | docs(infra): document Client build args hardening after AS.1 incident (KEY-302) | aucune | OUI | DOC |
| b4389d6 | docs: PH-SAAS-T8.12AS.1.2 client build-args fix DEV closeout (KEY-263) | aucune | OUI | DOC |
| b958002 | deploy(client-dev): v3.5.179-as1-1-build-args-fix-dev (KEY-263 AS.1.2) | apply = origine de la cible runtime stable actuel | OUI | DEPLOY_LIVE |
| e1d0f93 | rollback(client-dev): v3.5.178 -> v3.5.176 (KEY-263 build args incident) | apply -- precede b958002 | NON | ROLLBACK_HISTORICAL |
| 190310f | deploy(client-dev): v3.5.178 (KEY-263 AS.1.1) | apply -- rollbacke par e1d0f93 | NON | DEPLOY_HISTORICAL |
| c4a41e3 | rollback(client-dev): v3.5.177 -> v3.5.176 (KEY-263 AS.1 incident initial) | apply -- precede 190310f | NON | ROLLBACK_HISTORICAL |

L'historique infra est coherent. Pas de reecriture necessaire. Les commits DEPLOY_REVERTED restent dans le log pour tracabilite mais n'influencent plus le runtime grace au commit ROLLBACK_RESTORE 1d99421.

Manifest infra reflechit exactement le runtime actuel : pas de divergence GitOps a reconcilier au niveau infra.

---

## 5. Linear state (lecture API hors scope -- statuts deduits)

| Ticket | Titre | Statut deduit | Decision actuelle | Bloque quoi |
|---|---|---|---|---|
| KEY-263 | AR.5 Satisfaction / parent AS.1 escalation notifications | en attente / partiellement bloque | code AS.1 source preserve, runtime AS.1 livre sauf badge escalation | promotion AS.1 PROD bloquee par KEY-301 |
| KEY-301 | audit tenantGuardPlugin avant promotion AS.1 PROD | OPEN | faille non corrigee runtime DEV ni PROD | promotion AS.1 PROD ; toute promotion multi-tenant PROD ; nouvelle iteration patch securite necessaire |
| KEY-302 | Dockerfile Client build args hardening | DONE | f244a58 + cb55a42 livres et runtime stable | rien |
| KEY-303 | Agents edit/delete | NON LIE A SECURITE -- ne pas confondre avec patch tenantGuard | n/a pour cette phase | n/a |
| KEY-304 | patch tenantGuardPlugin Fastify scope | OPEN | source pousse sur origin (4d88e989, de498b0, 49a99f9, a032d83) mais runtime rollbacke par 1d99421 ; rapport AS.4.1 livre via a3aee26 ; nouvelle iteration source-reconciliation puis nouvelle phase patch necessaires | promotion AS.1 PROD ; tout build futur depuis HEAD api ou client sans plan de revert |

Aucun commentaire Linear poste dans cette phase. Textes prepares section 11.

---

## 6. Sources safe -- matrice de risque

| Repo | Runtime stable | Source commit safe | HEAD actuel | Divergence | Risque si build depuis HEAD aujourd'hui |
|---|---|---|---|---|---|
| keybuzz-api | v3.5.168-escalation-notifications-dev | 070707a1 | 4d88e989 | +1 commit KEY-304 | Reconstruirait v3.5.169 (patch guard isole). En isolation API ne casse rien, mais combine avec le Client v3.5.179 actuel (browser-direct sans X-User-Email) la guard nouvelle active casserait Inbox/notifications. Risque ELEVE. |
| keybuzz-client | v3.5.179-as1-1-build-args-fix-dev | f244a58 | a032d83 | +3 commits KEY-304 (de498b0 + 49a99f9 + a032d83) | Reconstruirait v3.5.182 qui casse channels/catalogue/AI auto-suggestion en runtime DEV. Risque TRES ELEVE. |
| keybuzz-infra | (manifests reflechissent le runtime) | a3aee26 | a3aee26 | aucune | Aucun -- manifest = runtime. |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev/prod | c62f376 | c62f376 | aucune | Aucun. |
| keybuzz-admin | v2.12.2-media-buyer-lp-domain-qa-prod | (HEAD avec WIP) | e4bffe7 + 14 modifs WIP | dirty WIP non lie AS.4.x | Hors scope securite ; les modifs WIP sont une autre phase admin in-progress. Pas un risque pour la securite tenantGuard. |
| keybuzz-website | v0.6.12-linkedin-insight-seo-prod | 5fc6f2b | 5fc6f2b | aucune | Aucun. |

**Risque operationnel principal** : un build CI/CD ou manuel depuis le HEAD actuel des branches `keybuzz-api` (HEAD=4d88e989) ou `keybuzz-client` (HEAD=a032d83) reconstruirait automatiquement les images experimentales rollbackees. Sans nouveau commit de revert, la branche source contient toujours le patch buggy en HEAD.

---

## 7. Plan de reconciliation source -- NON EXECUTE

Trois options proposees. Aucune n'est appliquee dans cette phase. La reconciliation elle-meme fera l'objet d'une phase dediee (PH-SAAS-T8.12AS.4.3) avec GO Ludovic.

### Option A -- Revert source par nouveaux commits (RECOMMANDEE)

Principe : preserver l'historique complet, creer des commits de revert propres, ne pas reecrire origin.

Commandes prevues (NON EXECUTEES) :

API :

```
cd /opt/keybuzz/keybuzz-api
git revert --no-edit 4d88e989
# le revert ramene src/app.ts, src/plugins/tenantGuard.ts,
# src/modules/tenants/routes.ts a l'etat 070707a1
git push origin ph147.4/source-of-truth
```

Client (3 reverts dans l'ordre inverse de creation) :

```
cd /opt/keybuzz/keybuzz-client
git revert --no-edit a032d83 49a99f9 de498b0
# revert chaine ; HEAD final = etat fonctionnellement equivalent a f244a58
git push origin ph148/onboarding-activation-replay
```

Apres reconciliation Option A, un build des HEAD reconstruirait des images :
- API : equivalentes a v3.5.168 (donc le runtime stable actuel)
- Client : equivalentes a v3.5.179 (donc le runtime stable actuel)

Avantages : historique preserve, traceable, reversible (re-revert pour reactiver), pas de force-push, pas de reset.
Risques : aucun runtime modifie. Necessite un commit infra parallele pour aligner manifests si on rebuild (mais pas obligatoire si on garde les images runtime en place).

### Option B -- Branches de sauvegarde experimentales puis revert

Principe : creer refs (branches ou tags) qui pointent sur les commits experimentaux pour les preserver explicitement, puis Option A sur la branche active.

Commandes prevues (NON EXECUTEES) :

```
# API
git branch experiment/KEY-304-tenant-guard-fix 4d88e989
git push origin experiment/KEY-304-tenant-guard-fix
# puis Option A
# Client
git branch experiment/KEY-304-bff-allowlist a032d83
git push origin experiment/KEY-304-bff-allowlist
# puis Option A
```

Avantages : sauvegarde explicite des commits experimentaux, accessibles pour iteration future.
Risques : pollution branches, doit etre pose avec convention claire.

### Option C -- Ne rien revert, interdire build depuis HEAD

Principe : ne pas modifier les branches source, mais documenter dans CI / Cursor rules / CLAUDE.md une interdiction de build sans plan.

Avantages : zero modification source.
Risques : repose sur la discipline humaine, pas un garde-fou technique. Premier build distrait casse DEV. Plus dangereux operationnellement, surtout en periode d'acquisition active.

### Recommandation

**Option A est recommandee**, eventuellement combinee avec Option B (creer un tag pour conserver explicitement l'experiment KEY-304 avant revert -- option B legere). Cela donne un garde-fou technique fort sans perdre la valeur de l'iteration experimentale.

---

## 8. Plan patch securite futur -- NON EXECUTE

Trois strategies proposees pour reprendre la phase patch tenantGuard apres echec AS.4.1.

### Strategie 1 -- Endpoint-by-endpoint (RECOMMANDEE)

Principe :

1. Choisir un endpoint a securiser en premier (ex. /messages/conversations).
2. Ecrire la BFF dediee correspondante (mirror /api/notifications) qui injecte X-User-Email + X-Tenant-Id.
3. Modifier le service Client correspondant (conversations.service) pour pointer vers la BFF dediee.
4. Tests E2E positifs (Inbox liste fonctionne).
5. Activer le tenantGuardPreHandler API SEULEMENT pour ce prefix d'endpoint (via une whitelist contraire = check seulement /messages, exempt tout le reste pour cette iteration).
6. Tests negatifs (sans auth -> 401/403 sur /messages, mais tout le reste reste comme avant).
7. Iteration suivante : ajouter /notifications, etc.

Avantages : risque tres faible par iteration ; Inbox marche tout le temps ; chaque iteration rapide.
Risques : multi-iteration, plus de PR, fenetre faille securite reste ouverte sur les autres routes.
Delai : moyen-long (5-8 iterations).

### Strategie 2 -- Full BFF allowlist v2

Principe : reprendre AS.4.1 mais avec audit Client EXHAUSTIF prealable + tests E2E positifs complets sur Inbox + canaux + catalogue + AI + suppliers + autopilot + billing + autres avant de switcher le runtime.

Avantages : un seul deploy reussi.
Risques : enorme inventaire Client a auditer ; tres facile d'oublier un cas (comme AIAssistant.tsx la premiere fois) ; gros patch difficile a rollbacker proprement.
Delai : court mais risque eleve.

### Strategie 3 -- API lit session/JWT NextAuth cookie

Principe : modifier le tenantGuardPreHandler API pour ALSO accepter un cookie session NextAuth (decodage JWT cote API avec NEXTAUTH_SECRET partage). Pas de refactor Client necessaire car les cookies session sont deja envoyes par le browser via credentials:'include'.

Avantages : aucun refactor Client.
Risques : couplage cross-service au secret NextAuth ; viole le pattern BFF ; nouvelle dependance lourde cote API (next-auth) ; cookies HttpOnly necessitent meme domaine cross-env (verifie : .keybuzz.io OK).
Delai : court mais re-architecture auth.

### Recommandation

**Strategie 1 (endpoint-by-endpoint) recommandee**. Permet d'avancer sans casser l'ecosysteme. Sequence proposee :

1. /messages/conversations (le plus critique pour Inbox).
2. /notifications (AS.1 badge a la fin).
3. /ai/* (auto-suggestion + assist).
4. /channels, /suppliers (canaux UI).
5. /tenants (refactor handler-level deja prepare dans 4d88e989, peut etre re-applique).

Chaque iteration : 1 BFF dediee + 1 service Client modifie + 1 test E2E + activation guard partielle.

Strategie 1 elimine l'option proxy generique catchall et reprend le pattern BFF-par-module deja present dans le repo (`/api/notifications`, `/api/stats/conversations`, `/api/ai/assist`, etc.).

---

## 9. Non-regression -- AUCUNE MUTATION CONFIRMEE

| Surface | Avant phase | Apres phase | Statut |
|---|---|---|---|
| API DEV runtime | v3.5.168-escalation-notifications-dev | identique | INCHANGE |
| Client DEV runtime | v3.5.179-as1-1-build-args-fix-dev | identique | INCHANGE |
| API PROD runtime | v3.5.151-conversation-tone-metric-prod | identique | INCHANGE |
| Client PROD runtime | v3.5.174-conversation-tone-metric-ux-prod | identique | INCHANGE |
| Backend DEV/PROD runtime | v1.0.47-cross-env-guard-fix-* | identique | INCHANGE |
| Website PROD runtime | v0.6.12-linkedin-insight-seo-prod | identique | INCHANGE |
| Admin PROD runtime | v2.12.2-media-buyer-lp-domain-qa-prod | identique | INCHANGE |
| OW DEV/PROD runtime | v3.5.165-escalation-flow-* | identique | INCHANGE |
| Manifests GitOps DEV/PROD | aucun touche | aucun touche | INCHANGE |
| Source code keybuzz-api | aucune modif | aucune modif | INCHANGE |
| Source code keybuzz-client | aucune modif | aucune modif | INCHANGE |
| Source code keybuzz-infra | aucune modif (sauf rapport via SCP+commit doc) | rapport doc seulement | DOC ONLY (autorise par prompt) |
| Source code keybuzz-backend / keybuzz-admin / keybuzz-website | aucune modif | aucune modif | INCHANGE |
| DB | aucune mutation | aucune mutation | INCHANGE |
| Stripe / billing / CAPI / tracking | aucune action | aucune action | INCHANGE |
| Docker push | aucun | aucun | INCHANGE |
| kubectl apply | aucun | aucun | INCHANGE |
| Pods restarts causes par cette phase | 0 | 0 | INCHANGE |

---

## 10. Gaps restants

1. **KEY-301 reste OPEN** : faille tenantGuard cross-tenant non corrigee runtime DEV ni PROD. AS.1 PROD reste BLOQUE.
2. **KEY-304 reste OPEN** : commits source pousses mais runtime rollbacke. Reconciliation source requise (Option A section 7) puis nouvelle phase patch securite (Strategie 1 section 8).
3. **Branches source api / client divergent du runtime** : risque opera majeur si build futur sans reconciliation. Cette phase ne corrige PAS la divergence -- elle la cartographie.
4. **KEY-302 verify-bundle script** ne sait pas valider le mode BFF (`baseUrl='/api/proxy'`) -- gap deja note dans AS.1.2 / AS.4.1, hors scope ici.
5. **keybuzz-admin dirty work-in-progress** non lie a la securite. Hors scope mais a noter pour les prochaines phases admin.
6. **OW DEV / OW PROD** : workers process, pas exposes HTTP, pas affectes par tenantGuard. Pas d'action requise.

---

## 11. Textes Linear -- NON POSTES

### Texte KEY-304 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.2 -- Source/runtime truth reconciliation apres rollback AS.4.1.

ETAT RUNTIME : stable et restaure depuis le rollback (1d99421).
- API DEV : v3.5.168-escalation-notifications-dev
- Client DEV : v3.5.179-as1-1-build-args-fix-dev
- PROD : strictement inchangee depuis le debut.

ETAT SOURCE : DIVERGE du runtime sur 2 repos.
- keybuzz-api HEAD = 4d88e989 (KEY-304 patch guard) au-dessus de 070707a1
  qui correspond au runtime v3.5.168.
- keybuzz-client HEAD = a032d83 (KEY-304 fix2 BFF proxy) au-dessus de
  f244a58 qui correspond au runtime v3.5.179.
- keybuzz-infra : aligne avec runtime (a3aee26 = HEAD = manifests
  reflechissent v3.5.168 + v3.5.179).

RISQUE : un build depuis le HEAD api ou client reconstruirait les
images experimentales rollbackees, qui ont casse Inbox/canaux/
catalogue/AI en runtime DEV. Risque opera ELEVE.

PROCHAINE PHASE PROPOSEE : PH-SAAS-T8.12AS.4.3 -- Reconciliation
source par revert (Option A) :
- git revert --no-edit 4d88e989 sur keybuzz-api puis push.
- git revert --no-edit a032d83 49a99f9 de498b0 sur keybuzz-client
  puis push.
- Optionnel : creer tag experiment/KEY-304 sur les commits
  experimentaux avant revert pour tracabilite.

PUIS, phase patch securite endpoint-by-endpoint (Strategie 1 du
rapport AS.4.2) :
1. /messages/conversations BFF + service + tests E2E + guard partiel.
2. /notifications.
3. /ai/*.
4. /channels, /suppliers.
5. /tenants (refactor handler).

KEY-304 reste OPEN jusqu'a livraison reussie d'une iteration patch
endpoint-by-endpoint (au minimum /messages/conversations).

Rapport : keybuzz-infra commit a venir
docs/PH-SAAS-T8.12AS.4.2-SOURCE-RUNTIME-TRUTH-RECONCILIATION-01.md
ASCII strict.
```

### Texte KEY-301 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.2 -- truth reconciliation apres rollback AS.4.1.

La faille tenantGuard cross-tenant identifiee par cet audit n'est
toujours pas corrigee en runtime DEV ni PROD. Le patch tente sous
KEY-304 a ete rollbacke en runtime suite a regressions Client non
triviales (canaux, catalogue, AI auto-suggestion). PROD strictement
inchangee tout au long.

Une nouvelle strategie patch endpoint-by-endpoint a ete proposee
sous KEY-304 et sera tracee la-bas. KEY-301 reste OPEN jusqu'a
livraison reussie de la premiere iteration et validation runtime
DEV+PROD que les routes critiques renvoient bien 401/403/404 sans
auth.

AS.1 PROD reste BLOQUE.
```

### Texte KEY-263 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.2 -- truth reconciliation.

Le badge escalation cote Client (AS.1) reste non promu en PROD car
sa source de verite est /notifications, exposee sans authentification
en runtime PROD apres le rollback AS.4.1.

AS.1 PROD ne peut pas etre repris tant que KEY-301 et KEY-304 ne
sont pas resolus. Le code AS.1 source est conserve sur origin
(commit 37e70ac sur keybuzz-client, 070707a1 sur keybuzz-api) et
ne necessite aucun revert.

Aucune action requise sur KEY-263 dans cette phase. A reprendre
apres securite.
```

---

## 12. Phrase cible finale

Cette phase a etabli noir sur blanc, en READ-ONLY STRICT, que le runtime DEV et PROD sont stables et alignes avec leurs manifests respectifs apres le rollback AS.4.1 (commit infra 1d99421), mais que les branches source `keybuzz-api` (HEAD=4d88e989) et `keybuzz-client` (HEAD=a032d83) divergent de leurs commits safe runtime respectifs (`070707a1` pour API, `f244a58` pour Client) avec des commits experimentaux KEY-304 dont les images correspondantes (v3.5.169, v3.5.180, v3.5.181, v3.5.182) ont casse Inbox/canaux/catalogue/AI en DEV ; aucun runtime, build, deploy, push, kubectl apply ni mutation DB n'a ete fait pendant cette phase ; PROD strictement inchangee ; KEY-301 et KEY-304 restent OPEN ; un plan de reconciliation source par revert (Option A recommandee, sections 7 et 8) est documente mais non execute, a executer dans une phase dediee (PH-SAAS-T8.12AS.4.3) avec GO Ludovic ; trois textes Linear contoles sont prepares mais non postes.

STOP -- truth verrouillee, en attente decision Ludovic sur execution Option A reconciliation source puis Strategie 1 patch securite endpoint-by-endpoint.
