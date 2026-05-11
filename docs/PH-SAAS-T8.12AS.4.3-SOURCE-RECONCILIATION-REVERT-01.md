# PH-SAAS-T8.12AS.4.3 -- Source Reconciliation Revert

> Date : 2026-05-11
> Linear : KEY-304 + KEY-301 + KEY-263
> Phase : reconciliation source par revert apres rollback runtime AS.4.1
> Environnement : SOURCE ONLY -- runtime DEV/PROD READ-ONLY -- aucune mutation runtime

## VERDICT

**GO SOURCE RECONCILED -- API AND CLIENT ACTIVE BRANCHES SAFE -- RUNTIME UNCHANGED -- NO BUILD -- NO DEPLOY**

Les branches actives `keybuzz-api` (`ph147.4/source-of-truth`) et `keybuzz-client` (`ph148/onboarding-activation-replay`) sont maintenant alignees fonctionnellement avec leurs commits safe runtime respectifs (`070707a1` et `f244a58`). Les commits experimentaux KEY-304 (`4d88e989` cote API ; `a032d83` + `49a99f9` + `de498b0` cote Client) ont ete revertes proprement par 4 nouveaux commits de revert. Les commits originaux restent dans l'historique pour tracabilite, et sont aussi preserves explicitement via deux branches `archive/key-304-*` poussees sur origin pour reference future.

Aucun build, aucun docker push, aucun kubectl apply, aucune mutation runtime ni DB. Les runtimes DEV+PROD sont strictement identiques avant et apres cette phase. Le risque opera "rebuild depuis HEAD reconstruit images casseuses" identifie par AS.4.2 est ELIMINE : un build des HEAD actuels reconstruira maintenant des images fonctionnellement equivalentes au runtime stable.

KEY-301 et KEY-304 restent OPEN -- la faille tenantGuard reste non corrigee runtime. AS.1 PROD reste BLOQUE. Une nouvelle phase patch securite endpoint-by-endpoint (Strategie 1 du rapport AS.4.2 section 8) doit etre lancee dans une phase dediee.

PROD strictement inchangee.

---

## 0. Preflight

| Repo | Branche attendue | Branche reelle | HEAD initial | HEAD final | Sync origin | Dirty | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 4d88e989 | a523db7c (revert commit) | 0/0 | 223 D dist/*.js artifacts (sans .gitignore, deletions locales) | OK COMPRIS |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | a032d83 | 9a2081c (3 reverts) | 0/0 | 1 M tsconfig.tsbuildinfo (artifact build) | OK COMPRIS |
| keybuzz-infra | main | main | 6639e61 | (rapport ajoute en fin de phase) | 0/0 | clean ou rapport doc | OK |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Runtime baseline READ-ONLY

| Service | Runtime image | Last-applied | Match | Statut |
|---|---|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | identique | OK | INCHANGE |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | identique | OK | INCHANGE |
| API PROD | v3.5.151-conversation-tone-metric-prod | identique | OK | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | identique | OK | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | identique | OK | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | identique | OK | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | identique | OK | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | identique | OK | INCHANGE |

DEV stable, PROD inchangee, manifest = runtime = annotation pour tous. Aucun drift GitOps.

---

## 2. Archive references experimentales

Avant revert, 2 branches archive ont ete creees pour preserver explicitement les commits experimentaux KEY-304 :

| Repo | Ref archive | Pointe vers | Push origin | Justification |
|---|---|---|---|---|
| keybuzz-api | archive/key-304-api-tenant-guard-experiment-4d88e989 | 4d88e989 | OUI | conservation explicite du patch tenantGuard fastify scope fix pour iteration future |
| keybuzz-client | archive/key-304-client-bff-experiment-a032d83 | a032d83 | OUI | conservation explicite du proxy BFF allowlist + AIAssistant fix + drop tenantRequired pour iteration future |

Ces branches archive sont maintenant disponibles sur origin et peuvent etre consultees, comparees ou utilisees comme base pour de futures iterations. Elles ne sont sur le chemin d'aucun build automatise.

---

## 3. Revert API source

### Action

```
cd /opt/keybuzz/keybuzz-api
git revert --no-edit 4d88e989
git push origin ph147.4/source-of-truth
```

### Resultat

| Element | Valeur |
|---|---|
| Commit revert | a523db7c |
| Sujet | Revert "fix(security): apply tenant guard globally across Fastify routes (KEY-304)" |
| Date | 2026-05-11 05:14:07 +0000 |
| Files changed | 3 (src/app.ts, src/plugins/tenantGuard.ts, src/modules/tenants/routes.ts) |
| Insertions / deletions | +39 / -111 (exactement l'inverse du diff 070707a1..4d88e989) |
| Diff src/ HEAD vs 070707a1 | VIDE -- src/ est byte-identique a 070707a1 |
| Push | 4d88e989..a523db7c sur ph147.4/source-of-truth |
| Sync origin | 0 / 0 |
| Dirty restant | 223 D dist/*.js artifacts (non stages, hors scope) |

### Verdict

API source reconciliee avec son commit safe runtime (070707a1 / image v3.5.168-escalation-notifications-dev).

---

## 4. Revert Client source

### Action

3 reverts successifs dans l'ordre inverse de creation des commits experimentaux :

```
cd /opt/keybuzz/keybuzz-client
git revert --no-edit a032d83   # drop tenantRequired
git revert --no-edit 49a99f9   # AIAssistant BFF fix
git revert --no-edit de498b0   # BFF proxy initial
git push origin ph148/onboarding-activation-replay
```

### Resultat

| Revert # | Commit revert | Sujet | Files | Insertions / deletions |
|---|---|---|---|---|
| 1 | 38b1b62 | Revert "fix(client-bff): drop tenantRequired enforcement from proxy (KEY-304)" | 1 (app/api/proxy/[...path]/route.ts) | +8 / -3 |
| 2 | ae915be | Revert "fix(ai-assistant): use BFF /api/ai/assist instead of browser-direct (KEY-304)" | 1 (src/features/ai-assistant/AIAssistant.tsx) | +1 / -2 |
| 3 | 9a2081c | Revert "fix(client): proxy tenant-scoped API calls through authenticated BFF (KEY-304)" | 2 (app/api/proxy/[...path]/route.ts SUPPRIME, src/config/api.ts) | +1 / -181 |

### Verifications

| Verification | Resultat |
|---|---|
| `git log --oneline -6` | shows 9a2081c, ae915be, 38b1b62, a032d83, 49a99f9, de498b0 (3 reverts au-dessus des 3 originaux) |
| `git status --short` | seul `M tsconfig.tsbuildinfo` (artifact, non stage) |
| `git diff f244a58..HEAD -- app src scripts docs Dockerfile package.json next.config.mjs` | VIDE -- byte-identique a f244a58 sur tous les fichiers principaux |
| `ls app/api/proxy/[...path]/route.ts` | SUPPRIME (delete mode 100644 confirme par revert 9a2081c) |
| Push | a032d83..9a2081c sur ph148/onboarding-activation-replay |
| Sync origin | 0 / 0 |

### Verdict

Client source reconciliee avec son commit safe runtime (f244a58 / image v3.5.179-as1-1-build-args-fix-dev). KEY-302 (commit f244a58 build args hardening) est PRESERVE absolument. Tous les commits anterieurs (a69477a AS.1.1, 37e70ac AS.1, 0a7306a AR.5.1, etc.) restent en place.

---

## 5. Push sources -- alignement origin

| Repo | HEAD apres revert | Push (range) | Sync origin | Verdict |
|---|---|---|---|---|
| keybuzz-api | a523db7c | 4d88e989..a523db7c -> ph147.4/source-of-truth | 0 / 0 | OK |
| keybuzz-client | 9a2081c | a032d83..9a2081c -> ph148/onboarding-activation-replay | 0 / 0 | OK |

Les branches actives sont en sync parfaite avec origin. Les archive branches restent disponibles cote origin sans interferer avec le workflow de build.

---

## 6. No build / no runtime / no DB / no infra mutation

| Action engageante | Effectuee dans cette phase ? |
|---|---|
| docker build | NON |
| docker push | NON |
| docker tag runtime | NON |
| kubectl apply | NON |
| kubectl set image | NON |
| kubectl set env | NON |
| kubectl patch / edit | NON |
| Manifest GitOps modifie | NON |
| Pod redemarre par cette phase | NON |
| DB INSERT / UPDATE / DELETE / DDL | NON |
| Runtime image modifiee | NON |
| Promotion AS.1 | NON |
| Build BFF / proxy / nouveau code | NON |
| Push image vers ghcr | NON |
| Modification cote PROD | NON |

Les seules actions executees sont des mutations de SOURCE Git uniquement : creation de 2 branches archive, 4 commits de revert, push de 2 branches actives + 2 branches archive. Aucune action runtime, aucune action build, aucune action DB.

---

## 7. Runtime post-revert (READ-ONLY)

| Service | Image avant phase | Image apres phase | Verdict |
|---|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | INCHANGE |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | v3.5.179-as1-1-build-args-fix-dev | INCHANGE |
| API PROD | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | INCHANGE |

8/8 services identiques avant/apres. Aucun pod n'a ete redemarre par cette phase. Aucun rollout n'a ete declenche.

---

## 8. Risque opera "rebuild depuis HEAD" -- ELIMINE

Avant cette phase :

- Un build CI ou manuel depuis le HEAD api (4d88e989) reconstruirait une image v3.5.169-tenant-guard-scope-fix-dev (le patch guard isole, qui en isolation ne casse pas API mais combinee au Client v3.5.179 actuel casserait Inbox/notifications).
- Un build depuis le HEAD client (a032d83) reconstruirait une image v3.5.182-tenant-guard-bff-compat-fix2-dev (proxy + AIAssistant BFF + drop tenantRequired) qui casse channels/catalogue/AI auto-suggestion en runtime.

Apres cette phase :

- Un build depuis HEAD api (a523db7c) reconstruirait une image fonctionnellement equivalente a v3.5.168-escalation-notifications-dev (le runtime stable actuel). Aucun risque de regression.
- Un build depuis HEAD client (9a2081c) reconstruirait une image fonctionnellement equivalente a v3.5.179-as1-1-build-args-fix-dev (le runtime stable actuel). Aucun risque de regression.

Le risque opera identifie par AS.4.2 est donc neutralise. Une CI peut maintenant declencher un rebuild sans danger.

---

## 9. Gaps restants

1. **KEY-301 reste OPEN** : faille tenantGuard cross-tenant non corrigee runtime DEV ni PROD.
2. **KEY-304 reste OPEN** : commits source experimentaux retires des branches actives (revertes), mais la faille n'est pas patchee. Une nouvelle phase patch est requise.
3. **Strategie 1 endpoint-by-endpoint recommandee** (rapport AS.4.2 section 8) : sequence proposee
   - /messages/conversations BFF dediee + service Client + tests E2E + activation guard pour ce prefix uniquement
   - puis /notifications
   - puis /ai/* (avec attention particuliere a AIAssistant.tsx et a la transmission de tenantId via body)
   - puis /channels, /suppliers
   - puis /tenants (refactor handler-level deja prepare dans 4d88e989, peut etre ressorti depuis archive/key-304-api-tenant-guard-experiment-4d88e989)
4. **AS.1 PROD reste BLOQUE** tant que KEY-301 et KEY-304 ne sont pas resolus.
5. **Code experimental preserve** : les branches archive permettent de comparer ou de re-extraire des morceaux du patch experimental sans devoir re-coder. Utile pour la nouvelle phase endpoint-by-endpoint.
6. **Aucun build ne doit etre lance jusqu'au prochain prompt CE valide**. Cette phase a juste reconcilie les branches actives ; la nouvelle phase patch doit etre planifiee separement.
7. **KEY-302 verify-bundle script ne supporte pas le mode BFF baseUrl='/api/proxy'**. Hors scope ici, mais a corriger lors de la prochaine iteration BFF.

---

## 10. Plan rollback de cette phase (NON EXECUTE)

Si une erreur source est detectee plus tard et qu'il faut annuler cette phase :

```
cd /opt/keybuzz/keybuzz-api
git revert --no-edit a523db7c
git push origin ph147.4/source-of-truth

cd /opt/keybuzz/keybuzz-client
git revert --no-edit 9a2081c ae915be 38b1b62
git push origin ph148/onboarding-activation-replay
```

Cette commande re-revert les reverts, ramenant le code a l'etat experimental KEY-304. Aucun reset, aucun force-push, aucun clean. Aucun rollback runtime applicable car le runtime n'a pas ete modifie.

A executer uniquement sur GO Ludovic explicite et raison documentee.

---

## 11. Textes Linear -- NON POSTES

### Texte KEY-304 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.3 -- Source reconciliation revert apres rollback runtime AS.4.1.

ACTION SOURCE-ONLY EFFECTUEE
- keybuzz-api : revert de 4d88e989 (KEY-304 patch tenantGuard fastify scope)
  par nouveau commit a523db7c. HEAD branche active maintenant
  fonctionnellement equivalent a 070707a1 (correspondant runtime
  v3.5.168-escalation-notifications-dev).
- keybuzz-client : revert de a032d83 + 49a99f9 + de498b0 (KEY-304 BFF proxy
  + AIAssistant fix + drop tenantRequired) par 3 nouveaux commits 38b1b62,
  ae915be, 9a2081c. HEAD branche active maintenant fonctionnellement
  equivalent a f244a58 (correspondant runtime v3.5.179-as1-1-build-args-fix-dev).
- KEY-302 (f244a58 build args hardening) PRESERVE absolument.
- Branches archive creees pour conservation explicite des commits
  experimentaux :
  - archive/key-304-api-tenant-guard-experiment-4d88e989 (origin OK)
  - archive/key-304-client-bff-experiment-a032d83 (origin OK)

RUNTIME : strictement inchange.
- DEV : API v3.5.168 + Client v3.5.179
- PROD : tous services inchanges depuis le debut

NO BUILD, NO DOCKER PUSH, NO KUBECTL APPLY, NO DB MUTATION. Source-only.

RISQUE OPERA "rebuild depuis HEAD reconstruit images casseuses" ELIMINE :
un build des branches actives reconstruira maintenant des images
fonctionnellement equivalentes au runtime stable actuel.

PROCHAINE ETAPE PROPOSEE : phase patch securite endpoint-by-endpoint
(Strategie 1 du rapport AS.4.2 section 8) dans une phase dediee. Sequence
recommandee : /messages/conversations -> /notifications -> /ai/* ->
/channels, /suppliers -> /tenants. Chaque iteration : 1 BFF dediee + 1
service Client modifie + 1 test E2E + activation guard partielle.

KEY-304 reste OPEN jusqu'a livraison reussie d'au moins la premiere
iteration patch endpoint-by-endpoint.

Rapport : keybuzz-infra commit a venir
docs/PH-SAAS-T8.12AS.4.3-SOURCE-RECONCILIATION-REVERT-01.md
ASCII strict.
```

### Texte KEY-301 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.3 -- Source reconciliation revert.

Les commits source experimentaux KEY-304 ont ete retires des branches
actives par revert propre. La faille tenantGuard cross-tenant identifiee
par cet audit reste cependant non corrigee en runtime DEV ni PROD --
seul le risque opera "rebuild depuis HEAD reconstruit le patch buggy"
a ete elimine.

Une nouvelle phase patch securite endpoint-by-endpoint est tracee sous
KEY-304. Le code experimental est conserve sur les branches archive
pour iteration future.

KEY-301 reste OPEN. AS.1 PROD reste BLOQUE.
```

### Texte KEY-263 (a coller manuellement sur GO Ludovic)

```
PH-SAAS-T8.12AS.4.3 -- Source reconciliation revert.

Le badge escalation cote Client (AS.1) reste non promu en PROD car la
source de verite (/notifications) reste exposee sans authentification
en runtime PROD apres tout le cycle AS.4.x.

Le code AS.1 source est conserve absolument :
- keybuzz-api 070707a1 (toujours en chemin direct du HEAD a523db7c)
- keybuzz-client 37e70ac (toujours en chemin du HEAD 9a2081c, sous
  a69477a callsite unwire et f244a58 build args)

Aucune action AS.1 dans cette phase. A reprendre apres securite
(KEY-301 + KEY-304 resolus).
```

---

## 12. Phrase cible finale

Les branches source actives `keybuzz-api` (`ph147.4/source-of-truth`) et `keybuzz-client` (`ph148/onboarding-activation-replay`) ont ete reconciliees avec les commits safe runtime respectifs (`070707a1` et `f244a58`) par 4 nouveaux commits de revert (`a523db7c` cote API et `38b1b62` + `ae915be` + `9a2081c` cote Client) qui annulent fonctionnellement les commits experimentaux KEY-304 (`4d88e989`, `a032d83`, `49a99f9`, `de498b0`) ; KEY-302 (`f244a58`) est preserve absolument ; les commits experimentaux restent dans l'historique Git pour tracabilite et sont egalement preserves explicitement via 2 branches `archive/key-304-*` poussees sur origin pour iteration future ; aucun build, aucun docker push, aucun kubectl apply, aucune mutation DB ni manifest GitOps ; runtime DEV et PROD strictement inchanges ; risque opera "rebuild depuis HEAD reconstruit images casseuses" elimine ; KEY-301 et KEY-304 restent OPEN ; AS.1 PROD reste BLOQUE jusqu'a une phase patch securite endpoint-by-endpoint dediee a livrer ulterieurement.

STOP -- source reconcilie, en attente decision Ludovic sur lancement nouvelle phase patch securite endpoint-by-endpoint.
