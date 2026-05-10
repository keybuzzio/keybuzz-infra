# PH-SAAS-T8.12AS.4.1 -- Tenant Guard BFF Compat and DEV Patch

> Date : 2026-05-11
> Linear : KEY-304 (Security) ; KEY-301 (audit parent) ; KEY-263 ; KEY-302
> Phase : patch securite tenantGuard + compat Client BFF allowlistee en DEV
> Environnement : DEV uniquement pour patch/build/deploy ; PROD read-only

## VERDICT

**NO GO CLIENT REGRESSION -- INBOX DEV BROKEN -- ROLLBACK EXECUTED -- AS.1 PROD STILL BLOCKED**

Le patch securite tenantGuard a ete techniquement applique avec succes en DEV : le hook `preHandler` est devenu actif sur toutes les routes non exemptees, et toutes les preuves negatives sont passees (lecture cross-tenant non authentifiee 401/403, mutation rejetee avant DB write, log `[TenantGuard] DENIED cross-tenant access` apparait pour la premiere fois). MAIS la compatibilite Client est insuffisante : malgre 3 iterations de Client (v3.5.180, v3.5.181, v3.5.182) et 2 fix follow-up (AIAssistant.tsx -> BFF /api/ai/assist ; proxy ne force plus tenantRequired), des regressions Client ont ete signalees par Ludovic (canaux non actifs, erreur "chargement du catalogue", probablement d'autres). Rollback DEV execute vers Client v3.5.179 + API v3.5.168 (etat pre-AS.4.1). Tous les flows DEV sont a nouveau fonctionnels apres rollback.

KEY-301 / KEY-304 restent OPEN. AS.1 PROD reste BLOQUE. Une nouvelle iteration est necessaire avec une couverture BFF plus exhaustive (audit complet de tous les patterns d'appel browser-direct, pas seulement `${API_CONFIG.baseUrl}` mais aussi `${process.env.NEXT_PUBLIC_API_URL}` directs et tout autre fetch absolu vers l'API).

PROD strictement inchangee tout au long de la phase.

---

## 0. Preflight

| Repo | Branche attendue | Branche reelle | HEAD initial | HEAD final | Sync origin | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 070707a1 | 4d88e989 (pousse, runtime rolled back) | 0/0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | f244a58 | a032d83 (pousse, runtime rolled back) | 0/0 | OK |
| keybuzz-infra | main | main | 965e2c0 | 1d99421 (rollback commit) | 0/0 | OK |

Note keybuzz-api : 223 fichiers `D dist/*.js` artifacts trackes en git sans .gitignore -- documente et compris ; build via `git worktree add` au commit pousse pour garantir un arbre clean dans Docker context.

---

## 1. Runtime baseline

### Avant phase

| Service | Image | Statut |
|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | OK |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | OK |
| API PROD | v3.5.151-conversation-tone-metric-prod | OK inchangee |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | OK inchangee |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | OK inchangee |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | OK inchangee |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | OK inchangee |
| OW PROD | v3.5.165-escalation-flow-prod | OK inchangee |
| OW DEV | v3.5.165-escalation-flow-dev | OK inchangee |

### Apres rollback (etat final)

| Service | Image | Statut |
|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | rolled back, OK |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | rolled back, OK |
| Tous services PROD | (identiques avant) | INCHANGES |

---

## 2. Inventaire complet appels Client direct API (ce qui a ete couvert)

| Service | Fichier | Endpoints | Traitement applique | Resultat |
|---|---|---|---|---|
| conversations | src/services/conversations.service.ts | /messages/conversations* (6 fns) | baseUrl -> /api/proxy | OK couvert |
| tenants | src/services/tenants.service.ts | /tenants | baseUrl -> /api/proxy + handler API patche | OK couvert |
| ai (fetchAI) | src/services/ai.service.ts | /ai/settings, /ai/global/settings, /ai/guard/check, /ai/evaluate, /ai/execute, /ai/journal, /ai/wallet/status | baseUrl -> /api/proxy ; proxy a ensuite eu son tenantRequired retire pour passer le body | partiellement OK |
| assistAI | src/services/ai.service.ts:165 | /api/ai/assist (BFF existante) | RIEN -- BFF dediee fonctionnait deja | OK |
| AIAssistant | src/features/ai-assistant/AIAssistant.tsx:143 | /ai/assist via NEXT_PUBLIC_API_URL direct | follow-up commit 49a99f9 : route via /api/ai/assist | OK couvert |
| auth | src/services/auth.service.ts:9 | /auth/me via NEXT_PUBLIC_API_URL direct | RIEN -- /auth deja exempt du guard | OK |
| dataSource/apiHealth | src/services/dataSource/apiHealth.ts | /messages/conversations test | baseUrl -> /api/proxy | OK |

### Inventaire INCOMPLET (gaps revelees pendant la validation)

| Surface | Symptome runtime | Cause probable | Statut |
|---|---|---|---|
| Channels catalog | Inbox affichait "erreur chargement du catalogue", canaux non actifs apres v3.5.182 | endpoint Channels potentiellement appele via un pattern non couvert (autre service, NEXT_PUBLIC_API_URL direct, ou BFF qui appelle l'API sans entete d'identite) | NON CORRIGE -- rollback execute |
| Autres flows non identifies | "Je suis certain qu'il doit y avoir autre chose qui ne fonctionne plus non plus" -- Ludovic | exhaustivite incomplete de l'audit pre-patch | NON CORRIGE -- rollback execute |

Lecon retenue : le grep `API_CONFIG\.baseUrl|API_ENDPOINTS\.|NEXT_PUBLIC_API_URL` n'a pas trouve TOUS les patterns. AIAssistant.tsx utilisait un `${API_URL}` local qui n'a ete repere que par un grep elargi `fetch(.*\${.*API_URL`. Une iteration suivante doit auditer TOUS les `await fetch(` du Client sans condition de pattern, et categoriser par cible (browser direct vs BFF).

---

## 3. Design BFF allowliste

Implementation : `app/api/proxy/[...path]/route.ts` (NEW, 179 lignes).

| Prefix API | Methodes | tenantRequired (initial v3.5.180) | tenantRequired (apres v3.5.182) |
|---|---|---|---|
| messages/conversations | GET, POST, PATCH | true | (check supprime du proxy) |
| ai | GET, POST, PATCH | true | (check supprime du proxy) |
| notifications | GET, PATCH | true | (check supprime du proxy) |
| stats | GET | true | (check supprime du proxy) |
| channels | GET | true | (check supprime du proxy) |
| suppliers | GET, POST, PATCH | true | (check supprime du proxy) |
| tenants | GET | false | false |

Comportement v3.5.180 : proxy validait session NextAuth + allowlist + tenantRequired (rejetait 400 si tenantId absent en query/header). Forwardait vers `API_URL_INTERNAL` avec `X-User-Email` + `X-Tenant-Id` injectes.

Comportement v3.5.182 : check tenantRequired retire. Le proxy ne fait plus que session check + allowlist + forward. Le tenantGuardPreHandler API est la seule source de verite pour le check tenant (il sait extraire tenantId du body POST/PATCH).

Allowlist refus par defaut : tout prefix ou methode hors liste retourne 403 PROXY_PATH_NOT_ALLOWED.

---

## 4. Design API guard

Option B retenue (hook direct sur parent scope) :

- Avant : `app.register(tenantGuardPlugin)` -> Fastify cree un scope encapsule -> hook preHandler ne s'applique pas aux routes en sibling scope -> guard no-op (cause racine confirmee KEY-301).
- Apres : `tenantGuardPreHandler(request, reply)` extrait du plugin et expose comme fonction. Dans `app.ts:103` : `app.addHook('preHandler', tenantGuardPreHandler)` directement sur l'instance parent. Le hook s'applique a TOUTES les routes registered ulterieurement.

Aucune nouvelle dependance npm (pas de `fastify-plugin`).

`/tenants` ajoute a `EXEMPT_PREFIXES` car identity-scoped, pas tenant-scoped. Le handler `/tenants` patche pour exiger `x-user-email` et filtrer par membership (`JOIN user_tenants`).

`tenantGuardPlugin` conserve, marque `@deprecated`.

---

## 5. Patches livres

### keybuzz-api commit 4d88e989

| Fichier | Type | Lignes |
|---|---|---|
| src/app.ts | EDIT | 4 (import + addHook) |
| src/plugins/tenantGuard.ts | EDIT | +50/-23 (refactor + /tenants exempt) |
| src/modules/tenants/routes.ts | EDIT | +57/-12 (handler patch user-membership) |

### keybuzz-client commits

| Commit | Sujet | Fichiers |
|---|---|---|
| de498b0 | fix(client): proxy tenant-scoped API calls through authenticated BFF (KEY-304) | app/api/proxy/[...path]/route.ts NEW (179 l), src/config/api.ts +1/-1 |
| 49a99f9 | fix(ai-assistant): use BFF /api/ai/assist instead of browser-direct (KEY-304) | src/features/ai-assistant/AIAssistant.tsx +2/-1 |
| a032d83 | fix(client-bff): drop tenantRequired enforcement from proxy (KEY-304) | app/api/proxy/[...path]/route.ts +3/-8 |

---

## 6. Checks source

| Repo | Check | Resultat |
|---|---|---|
| keybuzz-api | npx tsc --noEmit | exit 0 |
| keybuzz-client | npx tsc --noEmit | exit 0 (3 fois, apres chaque patch) |

---

## 7. Builds DEV (worktree clean from pushed commit)

| Image | Source commit | Tag | Image ID | Digest registry |
|---|---|---|---|---|
| keybuzz-api | 4d88e989 | v3.5.169-tenant-guard-scope-fix-dev | c0bdea5b787f | sha256:0445d06589c080df2266e86bf9b58a757b584c0c2b2dd3fad3cf8f2d7abfc5ed |
| keybuzz-client (initial) | de498b0 | v3.5.180-tenant-guard-bff-compat-dev | 3cbaf48537b5 | sha256:b1391ea9c2692baf2f0325170dd4951e2f8198c18d05f762ac550d6c21c399f5 |
| keybuzz-client (fix1) | 49a99f9 | v3.5.181-tenant-guard-bff-compat-fix-dev | 196002f88f16 | sha256:886b7a382627b6143180153676d044b7acc6f1d3ff6cfbe6871fa103a0cb4cca |
| keybuzz-client (fix2) | a032d83 | v3.5.182-tenant-guard-bff-compat-fix2-dev | 3195a6fc89f6 | sha256:4a4dae0ac23a3c63e25f1cc07849cb7402eaca8cc585b36d17d0c44adddc4d1c |

Tous builds avec KEY-302 build args explicites cote Client :
- NEXT_PUBLIC_APP_ENV=development
- NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io
- NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io

Bundle check manuel (KEY-302 verify script ne couvre pas le mode BFF -- gap a corriger separement) :

| Image Client | PROD URL count | DEV URL count | /api/proxy count | /api/ai/assist count |
|---|---|---|---|---|
| v3.5.180 | 0 | 0 | 2 | 0 (l'AIAssistant utilisait encore browser direct) |
| v3.5.181 | 0 | 0 | 2 | 3 |
| v3.5.182 | 0 | 0 | 2 | 3 |

Aucune fuite PROD URL inline dans les bundles -- securite KEY-302 preservee.

---

## 8. GitOps DEV

| Commit infra | Sujet | Action runtime |
|---|---|---|
| 34eeab6 | deploy(dev): tenant guard security patch with BFF compatibility (KEY-304) | apply Client v3.5.180 + API v3.5.169 |
| 0af9d90 | deploy(client-dev): v3.5.181 -- AIAssistant routed via BFF /api/ai/assist | apply Client v3.5.181 |
| b962592 | deploy(client-dev): v3.5.182 -- proxy drops tenantRequired | apply Client v3.5.182 |
| 1d99421 | rollback(dev): tenant guard security patch -- new Client regressions (KEY-304) | apply Client v3.5.179 + API v3.5.168 |

Aucun manifest PROD touche.

---

## 9. Validation negative DEV (PASSED -- la securite a fonctionne)

Tests sans authentification, depuis le bastion via ingress public :

| # | Endpoint | Status | Body | Verdict |
|---|---|---|---|---|
| T1 | GET /health | 200 | 96 B | OK exempt |
| T2 | GET /messages/conversations?tenantId=<real>&limit=1 | 401 | AUTH_REQUIRED | **FUITE CROSS-TENANT FERMEE** (etait 200+1214 B avant) |
| T3 | GET /notifications?tenantId=<real>&...&limit=1 | 401 | AUTH_REQUIRED | OK |
| T4 | GET /tenants | 401 | AUTH_REQUIRED | **/tenants protege handler-level** (etait 200+enumeration tous tenants avant) |
| T5 | GET /tenants/:id | 401 | AUTH_REQUIRED | OK |
| T6 | GET /ai/settings?tenantId=<real> | 401 | AUTH_REQUIRED | OK |
| T7 | GET /messages/conversations sans tenantId | 400 | TENANT_ID_MISSING | **Du guard, pas du handler** -- guard actif |
| T8 | GET /messages/conversations?tenantId=<real> + x-user-email bogus | 403 | "Access denied: not a member of this tenant" | **MEMBERSHIP CHECK ACTIF** ; log `[TenantGuard] DENIED cross-tenant access` apparait pour la premiere fois |

Mutations sans auth :

| # | Endpoint | Status | Body | Verdict |
|---|---|---|---|---|
| M1 | PATCH /notifications/fake-id-12345/ack | 401 | AUTH_REQUIRED | rejet avant DB write |
| M2 | POST /messages/conversations/fake-id-12345/reply | 401 | AUTH_REQUIRED | rejet avant DB write |
| M3 | POST /notifications/simulate (tenantId in body) | 401 | AUTH_REQUIRED | rejet avant DB write |

Conclusion negative : la fix tenantGuard fonctionne. Le `[TenantGuard] DENIED cross-tenant access` log apparait pour la premiere fois dans l'histoire DEV.

---

## 10. Validation positive DEV (KO -- regressions Client)

### Iteration 1 (apres v3.5.180 + API v3.5.169)

QA Ludovic : Inbox liste centrale OK. Topbar OK. Banner OK. PROD verifiee inchangee. MAIS le panneau de suggestion automatique IA n'affichait plus de generation de texte ; bouton manuel apparu en remplacement.

Diagnostic : `src/features/ai-assistant/AIAssistant.tsx:143` faisait un `fetch(${API_URL}/ai/assist)` browser-direct sans entete d'identite. Cet appel etait absent de l'inventaire E2 initial (pattern non couvert par le grep).

### Iteration 2 (apres v3.5.181)

Fix livre : AIAssistant.tsx route maintenant via `/api/ai/assist` (BFF existante).

QA Ludovic : auto-generation AI toujours absente.

Logs API : aucun hit `/ai/assist` ni `/ai/evaluate` ni `/ai/execute`. Hits `/ai/settings`, `/ai/wallet/status`, `/ai/suggestions/track`, `/ai/learning-control` arrivaient bien (ces endpoints utilisent tenantId en query string).

Diagnostic : `evaluateAI`, `executeAI`, `getAIGuardCheck` (depuis ai.service via `fetchAI`) envoient tenantId dans le body POST. Le proxy v3.5.180 / v3.5.181 rejetait avec 400 TENANT_ID_MISSING parce qu'il ne lisait pas le body avant de check tenantRequired.

### Iteration 3 (apres v3.5.182)

Fix livre : proxy ne force plus tenantRequired. Le tenantGuardPreHandler API devient la seule source de verite pour la verification tenant (il sait extraire du body).

QA Ludovic : nouvelle regression -- canaux non actifs, "erreur chargement du catalogue", probablement plus de cas. Demande explicite de rollback.

Diagnostic non termine pour cette regression. Hypothese : un autre pattern d'appel browser-direct non couvert (peut etre `/channels` via NEXT_PUBLIC_API_URL direct, ou un BFF channels qui appelle l'API sans injecter X-User-Email).

### Decision iteration 3

Rollback DEV execute selon demande Ludovic.

---

## 11. Rollback DEV (EXECUTED)

### Commits source non revertes

Les commits suivants restent sur origin :
- keybuzz-api 4d88e989 (tenant guard hook fix)
- keybuzz-client de498b0 (BFF proxy)
- keybuzz-client 49a99f9 (AIAssistant BFF route)
- keybuzz-client a032d83 (proxy drop tenantRequired)

Ils sont disponibles pour iteration suivante.

### Manifests rolled back

Commit infra 1d99421 :

| Service | Image avant rollback | Image apres rollback |
|---|---|---|
| API DEV | v3.5.169-tenant-guard-scope-fix-dev | v3.5.168-escalation-notifications-dev (pre-AS.4.1) |
| Client DEV | v3.5.182-tenant-guard-bff-compat-fix2-dev | v3.5.179-as1-1-build-args-fix-dev (pre-AS.4.1) |

### Apply order

1. API DEV apply (guard redevient no-op) -- evite que Client en cours de deploy se retrouve a parler avec un guard actif sans BFF.
2. Client DEV apply (revient au mode browser-direct vers une API non-patchee).

Pas de fenetre Inbox cassee. Confirme par QA Ludovic apres rollout.

### Etat post-rollback (validation finale Ludovic)

OK -- tout fonctionne comme avant. Inbox, canaux, catalogue, AI, sidebar, banner : tout est revenu.

---

## 12. PROD read-only

Aucune mutation PROD pendant toute la phase. Verification finale :

| Service PROD | Image | Statut |
|---|---|---|
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun manifest PROD modifie. Aucun docker push PROD. Aucun apply PROD.

---

## 13. Non-regression et blast radius

| Surface | Avant phase | Apres rollback | Verdict |
|---|---|---|---|
| API DEV runtime | v3.5.168 | v3.5.168 | INCHANGE NET |
| Client DEV runtime | v3.5.179 | v3.5.179 | INCHANGE NET |
| Tous services PROD | (idem baseline) | (idem baseline) | INCHANGE NET |
| OW DEV / OW PROD | v3.5.165 | v3.5.165 | INCHANGE |
| DB | aucune mutation | aucune mutation | INCHANGE |
| Manifests PROD | non touches | non touches | INCHANGE |
| Code keybuzz-api source HEAD | 070707a1 | 4d88e989 (pousse, runtime non utilise) | AVANCE source uniquement |
| Code keybuzz-client source HEAD | f244a58 | a032d83 (pousse, runtime non utilise) | AVANCE source uniquement |

Aucune mutation Stripe / billing / CAPI / tracking. Aucun envoi email externe. Aucun appel marketplace externe declenche par cette phase.

---

## 14. Lecons retenues pour iteration suivante

1. **Audit Client browser-direct doit etre exhaustif**. Le grep `API_CONFIG\.baseUrl|API_ENDPOINTS\.|NEXT_PUBLIC_API_URL` a manque AIAssistant.tsx (qui faisait `${API_URL}/ai/assist` avec API_URL local). Une meilleure approche : grep tous les `await fetch(` cote Client, categoriser un par un. Ou mieux : interdire au compile-time les fetch absolus vers l'API hors BFF.
2. **Le proxy ne peut pas pre-extraire tenantId du body** sans consommer le stream. Choix v3.5.182 : laisser le tenantGuard API faire le check (single source of truth). Acceptable mais reduit la valeur du `tenantRequired` cote BFF a une simple optimisation pre-rejet.
3. **Channels et autres endpoints non audites**. Une iteration suivante doit auditer specifiquement `/channels`, `/billing`, `/suppliers`, `/orders`, `/playbooks`, `/autopilot`, `/funnel` et tous les autres prefixes que mon allowlist couvre OU non couvre. Inventaire actuel incomplet.
4. **Les BFF existantes peuvent etre incompletes**. Certaines BFF deja en place pourraient ne pas injecter X-User-Email correctement. Audit a faire.
5. **KEY-302 verify-bundle script doit gerer le mode BFF** (baseUrl='/api/proxy'). Actuellement il fail avec `dev=0 prod=0` parce qu'il exige >=1 occurrence DEV. A patcher : accepter "0 dev OK si >=1 occurrence /api/proxy".
6. **Test mutationnel positif manquant**. Aucune validation positive end-to-end (Inbox + reply + status + AI complete) n'a ete faite avant le rollback. Une iteration suivante devrait inclure un test exhaustif des features avant declaration GO DEV.
7. **Strategie de deploiement par etapes possible**. Au lieu de tout patcher en une phase, on pourrait deployer le BFF proxy d'abord (sans activer le guard), valider que rien ne casse cote Client, puis activer le guard dans une phase suivante.

---

## 15. Gaps restants

1. **KEY-301 reste OPEN** : faille tenantGuard cross-tenant non corrigee en runtime DEV ni PROD. AS.1 PROD reste BLOQUE.
2. **KEY-304 reste OPEN** : patch tenantGuard livre source mais rollback execute pour cause de regression Client. Iteration suivante necessaire.
3. **KEY-302 verify-bundle script** : doit gerer le mode BFF. Hors scope AS.4.1.
4. **Channels / catalogue / autres flows non identifies** : a auditer en detail dans la phase suivante. Au minimum : `app/api/channels/*`, `app/api/billing/*`, et chaque service Client qui fait un fetch absolu non couvert.
5. **Audit autres plugins** : `rateLimiter`, `requestContext`, `postgres` -- verifier si l'un d'eux a aussi le meme bug d'encapsulation Fastify (KEY-301 a leve un doute pour rateLimiter mais pas verifie).
6. **OW DEV / OW PROD** : workers process, pas exposes HTTP. Pas affectes par tenantGuard. Pas a patcher.
7. **AS.1 PROD** : BLOQUE. Le badge escalation cote Client n'est qu'une UI ; sa source de verite est /notifications, qui reste expose sans authentification en PROD apres rollback.

---

## 16. Decision sur AS.1 PROD

**AS.1 PROD reste BLOQUE.** La faille tenantGuard cross-tenant identifiee par KEY-301 n'est pas corrigee en runtime apres ce rollback. Une nouvelle phase de patch securite est necessaire avant toute promotion AS.1 PROD.

Options pour la phase suivante :

A. Re-tenter une phase patch avec un audit Client exhaustif au prealable, deploiement progressif, validation positive end-to-end avant chaque etape.
B. Considerer une approche alternative : patcher le tenantGuard pour qu'il accepte aussi un mecanisme d'auth cookie session NextAuth cote API (couplage cross-service mais zero refactor Client). Reconsiderer l'analyse cout/benefice de l'option C de l'audit AS.4 initial.
C. Decouper la securite en plusieurs petits patches : un endpoint a la fois, avec validation Client correspondante.

Aucune option n'est decidee dans ce rapport. A discuter avec Ludovic.

---

## 17. Phrase cible finale

Le patch tenantGuard a ete techniquement applique avec succes en DEV (toutes les preuves negatives sont passees, premier log `[TenantGuard] DENIED cross-tenant access` jamais emis), mais des regressions Client non triviales sur les canaux / catalogue (et probablement plus) ont impose un rollback DEV complet vers Client v3.5.179 + API v3.5.168 conformement a la demande explicite de Ludovic ; PROD strictement inchangee tout au long ; KEY-301 reste OPEN ; KEY-304 reste OPEN ; AS.1 PROD reste BLOQUE jusqu'a une iteration suivante avec audit Client exhaustif et validation positive end-to-end.

STOP -- rollback livre, en attente decision sur strategie iteration suivante.
