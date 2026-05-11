# PH-SAAS-T8.12AS.5.5-SAAS-RUNTIME-SOURCE-TRUTH-AUDIT-01

> Date : 2026-05-11
> Linear : KEY-305, KEY-304, KEY-301, KEY-263, KEY-302
> Phase : T8.12 AS.5.5 - audit verite complet SaaS / source-runtime-build-GitOps / read-only
> Environnement : DEV (lecture), PROD (lecture). Aucune mutation.

---

## 1. VERDICT

GO SAAS TRUTH READY - CURRENT DEV STABLE, SOURCE SAFE

Conditions remplies pour Scenario A (freeze current runtime + source aligned + resume planned work) :
- Runtime DEV+PROD MATCH=yes 10/10 services (manifest = last-applied = pod image).
- Source keybuzz-api HEAD (b8613f0f) byte-equivalent au runtime safe API DEV v3.5.168 sur src/.
- Source keybuzz-client HEAD (8cdc04a) byte-equivalent au runtime safe Client DEV v3.5.179 sur perimetre code (app/src/scripts/docs/Dockerfile/package).
- Aucune regression critique observee en DEV (API/Backend/Website health 200, logs DEV propres).
- KEY-302 build args guard en place et durable cote Client.

Gaps materiels (non bloquants pour le freeze mais bloquants pour resume security) :
- JWT_SESSION_ERROR PROD recurrent (31 occurrences sur 500 lignes logs Client PROD), 0 en DEV.
- KEY-301 tenantGuard runtime ouvert (DEV+PROD).
- KEY-304 messages security a refaire endpoint-by-endpoint apres phase de design dediee.
- KEY-263 AS.1 PROD promotion bloquee.
- Root cause statique AS.5 -> Brouillon IA SWITAA AUTOPILOT casse non isolee.

---

## 2. Executive summary

Cet audit AS.5.5 est exclusivement read-only. Aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun commit hors rapport, aucun post Linear.

Constats principaux :

1. La crise AS.x (KEY-263 puis KEY-302 puis KEY-301 puis KEY-304 puis KEY-305) est CONTENUE en DEV. Le rollback AS.5.3 (runtime API v3.5.169 -> v3.5.168 + Client v3.5.180 -> v3.5.179) puis l alignement source AS.5.4 (revert eae84b58 par b8613f0f + revert 57766ea + 8d8121f par 8cdc04a + d468991) ont reconcilie source = runtime safe en DEV.

2. PROD n a jamais ete touchee par les phases AS.4.x / AS.5.x. Runtime PROD reste API v3.5.151 + Client v3.5.174 + Backend v1.0.47 + Website v0.6.12 + Admin v2.12.2, tous MATCH GitOps.

3. KEY-302 (build args guard Client) est livre source-only et empeche desormais qu un docker build sans --build-arg explicite produise un bundle dirige vers API PROD depuis DEV.

4. La faille initiale KEY-301 (tenantGuard runtime non propage) reste OUVERTE en DEV et PROD. Les tentatives AS.4.x et AS.5.x de durcissement ont casse des flux UI (Inbox, channels, catalogue, Brouillon IA SWITAA AUTOPILOT) et ont ete rollbackees. La reprise doit etre endpoint-par-endpoint avec une phase de design dediee qui integre EXPLICITEMENT la QA des flux critiques.

5. Surface PROD instable nouvelle detectee : Client PROD emet 31 erreurs JWT_SESSION_ERROR sur 500 lignes de logs (decryption operation failed). DEV n a aucune occurrence. A investiguer en phase dediee (probable rotation NEXTAUTH_SECRET ou cookies legacy users).

6. Repos locaux dirty hors-build-path (artefacts) : keybuzz-api a ~50 fichiers dist/*.js supprimes ; keybuzz-client a tsconfig.tsbuildinfo modifie ; keybuzz-backend a un fichier .bak untracked ; keybuzz-admin est quarantained PH86.0 et dirty (non-utilise pour build). Aucun de ces dirty ne bloque un rebuild safe car les artefacts sont regeneres par les Dockerfiles.

7. Existence de keybuzz-admin-v2 (repo distinct, HEAD ad2bd4c, branche main, sync 0/0, clean) comme vraie source des images admin runtime. CLAUDE.md mentionne keybuzz-admin sans preciser admin-v2 ; risque d induction en erreur pour un agent qui suit CLAUDE.md a la lettre.

Recommandation : Scenario A (freeze + resume planned work). Pas de scenario B ou C necessaire. Voir section 12.

---

## 3. Preflight repos

| Repo | Path | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | b8613f0f | 0/0 | ~50 D dist/*.js (artefact build) | OK build-from-Git regenere dist |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | 8cdc04a | 0/0 | M tsconfig.tsbuildinfo (artefact) | OK |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 5de7405 | 0/0 | clean | OK |
| keybuzz-backend | /opt/keybuzz/keybuzz-backend | main | c62f376 | 0/0 | ?? amazon.routes.ts.bak (artefact AO.2) | OK (a nettoyer plus tard) |
| keybuzz-website | /opt/keybuzz/keybuzz-website | main | 5fc6f2b | 0/0 | clean | OK |
| keybuzz-admin (legacy) | /opt/keybuzz/keybuzz-admin | main | e4bffe7 | 0/0 | DIRTY 10 modif + 4 untracked + QUARANTINED.md | NON-UTILISE (PH86.0 quarantine) |
| keybuzz-admin-v2 | /opt/keybuzz/keybuzz-admin-v2 | main | ad2bd4c | 0/0 | clean | OK |

Anchors safe identifies pour rebuild equivalence :
- API : 070707a1 (commit AS.1 = image runtime v3.5.168). Diff 070707a1..HEAD sur src/ = vide.
- Client : f244a58 (commit AS.1.2 closeout = image runtime v3.5.179). Diff f244a58..HEAD sur app+src+scripts+docs+Dockerfile+package*.json+next.config.mjs = vide.

Repo missing dans CLAUDE.md : keybuzz-admin-v2 (le vrai repo admin runtime). CLAUDE.md liste keybuzz-admin sans preciser admin-v2.

---

## 4. Runtime DEV/PROD inventory

Tous les services testes : MATCH=yes entre spec deployment et annotation kubectl.kubernetes.io/last-applied-configuration. Aucun drift GitOps detecte.

| Env | Service | Runtime image | Last-applied | Match | Pod | Restarts | Age |
|---|---|---|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.168-escalation-notifications-dev | idem | yes | keybuzz-api-84b46bbd7f-nctcf | 0 | 2026-05-11T08:38:44Z |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | idem | yes | keybuzz-outbound-worker-f5f459d47-z2b89 | 8 | 2026-04-10T19:55:21Z |
| DEV | keybuzz-client | v3.5.179-as1-1-build-args-fix-dev | idem | yes | keybuzz-client-d4bfb7c78-nrwzg | 0 | 2026-05-11T08:37:55Z |
| DEV | keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | idem | yes | keybuzz-backend-7cbd4bdbf5-dd6rq | 0 | 2026-05-06T06:47:06Z |
| DEV | keybuzz-website | (non probe dans cet audit, pod present) | n/a | n/a | keybuzz-website-5556965bc4-wz47b | 0 | 2026-05-08T22:01:13Z |
| DEV | keybuzz-admin-v2 | (non probe explicitement dans cet audit) | n/a | n/a | keybuzz-admin-v2-7f89db5ff8-zgnf5 | 0 | 2026-05-09T06:42:03Z |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | idem | yes | keybuzz-api-6d664b7669-rxcz4 | 0 | 2026-05-10T03:33:06Z |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | idem | yes | keybuzz-outbound-worker-d7649c55b-gqrqh | 7 | 2026-04-10T19:55:22Z |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | idem | yes | keybuzz-client-6f65b8c8fb-nkj88 | 0 | 2026-05-10T03:33:27Z |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | idem | yes | keybuzz-backend-5bc765c7d8-6qqp6 | 0 | 2026-05-06T08:43:45Z |
| PROD | keybuzz-website | v0.6.12-linkedin-insight-seo-prod | idem | yes | keybuzz-website-59db958f45-6n7sd + 59db958f45-zc7lk | 0 + 0 | 2026-05-08T22:16:16Z + 22:16:36Z |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | idem | yes | keybuzz-admin-v2-565ddfcbc9-xwfhm | 0 | 2026-05-09T06:45:56Z |

Note workers : keybuzz-outbound-worker DEV+PROD ont 7-8 restarts mais pods AGE 1 mois ; restarts repartis sur la duree, non-bloquant pour AS.5.5 audit (hors scope). A surveiller en phase ops dediee.

---

## 5. Source / runtime mapping

| Service | Env | Image | Digest court | Commit source (preuve ou supposition) | Rapport | Confiance |
|---|---|---|---|---|---|---|
| API | DEV | v3.5.168-escalation-notifications-dev | 45626491c5fa | 070707a1 (AS.1) | AS.1 | HIGH (verifie en AS.4.3+AS.5.4 par diff vide) |
| API | PROD | v3.5.151-conversation-tone-metric-prod | 29e53af3db70 | AR.5.2 (commit hash a confirmer ulterieurement) | AR.5.2 | MED (CURRENT_STATE.md + rapport AR.5.2) |
| outbound-worker | DEV | v3.5.165-escalation-flow-dev | 60423d4de2db | pre-AS.x escalation flow | (pre-AS.1) | MED |
| outbound-worker | PROD | v3.5.165-escalation-flow-prod | 53833cf95a3e | pre-AS.x escalation flow | (pre-AS.1) | MED |
| Client | DEV | v3.5.179-as1-1-build-args-fix-dev | b8a64abd378a | f244a58 (AS.1.2) | AS.1.2 | HIGH (verifie en AS.4.3+AS.5.4 par diff vide) |
| Client | PROD | v3.5.174-conversation-tone-metric-ux-prod | 8d2e195ae6cf | AR.5.2 (commit hash a confirmer) | AR.5.2 | MED |
| Backend | DEV | v1.0.47-cross-env-guard-fix-dev | b9f9b5a7b827 | c62f376 (AO.6.2) | AO.6.2 | HIGH (commit message match) |
| Backend | PROD | v1.0.47-cross-env-guard-fix-prod | 0a86583d1971 | c62f376 (AO.6.2) | AO.6.2 | HIGH |
| Website | PROD | v0.6.12-linkedin-insight-seo-prod | 22bd41d5fcc4 | 5fc6f2b (AQ.3) | AQ.3 | HIGH (commit message match) |
| Admin v2 | PROD | v2.12.2-media-buyer-lp-domain-qa-prod | ecc2080ff7fe | ad2bd4c (AQ.4.1) | AQ.4.1 | HIGH (commit message match) |

Limite traceability : aucune image ne porte de label Docker `org.opencontainers.image.revision` ni `commit_sha`. La traceability commit-source -> image-tag passe uniquement par les rapports PH et par les commits infra GitOps.

Recommandation source-of-truth : ajouter le label Docker `org.opencontainers.image.revision` aux Dockerfiles api/client/backend/website/admin-v2 dans une phase ulterieure (hors scope AS.5.5).

---

## 6. Build process truth

| Repo | Build entrypoint | Args obligatoires | Guard present | Verdict |
|---|---|---|---|---|
| keybuzz-client | Dockerfile multi-stage (node:20-alpine) | NEXT_PUBLIC_APP_ENV, NEXT_PUBLIC_API_URL, NEXT_PUBLIC_API_BASE_URL avec sentinels `__MUST_BE_SET_BY_BUILD_ARG__` | OUI : scripts/check-client-build-args.sh + scripts/verify-client-bundle-api-url.sh + docs/BUILD-ARGS.md (KEY-302) | DURCI |
| keybuzz-api | Dockerfile multi-stage (node:lts builder + node:lts-alpine runner) | aucun NEXT_PUBLIC_*, build TypeScript via `npm run build` (tsc) | aucun guard supplementaire requis | OK pour build-from-Git |
| keybuzz-backend | Dockerfile multi-stage (node:22-alpine) + Prisma generate | aucun obligatoire build-time, configurations runtime | aucun guard supplementaire | OK |
| keybuzz-website | Dockerfile (non lu en detail dans AS.5.5) | (a documenter en phase dediee) | n/a | OK presume (runtime stable) |
| keybuzz-admin-v2 | Dockerfile multi-stage (node:20-alpine) | NEXT_PUBLIC_APP_ENV=production + NEXT_PUBLIC_API_URL=https://api.keybuzz.io (defaults non-sentinel) | aucun guard equivalent KEY-302 | RISQUE FAIBLE : defaults PROD-pointing, mais pas de sentinel guard. Un build admin-v2 DEV doit explicitement passer NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io sinon bundle pointera PROD comme AS.1 client. A durcir dans une phase ulterieure si admin-v2 a un build DEV regulier. |

Note KEY-302 hardening (Client) :
- Sentinel `__MUST_BE_SET_BY_BUILD_ARG__` injecte dans Dockerfile.
- Guard `check-client-build-args.sh` execute AVANT `npm run build`, fait echouer le build si sentinel encore present.
- Verification post-build `verify-client-bundle-api-url.sh` peut etre lancee contre l image construite pour confirmer que l URL inlinee dans le bundle correspond a l environnement attendu.
- Documentation : `docs/BUILD-ARGS.md` reference l incident AS.1.1 (v3.5.177/178) qui a motive cette regle.

Note dist tracking API : `.gitignore` keybuzz-api n exclut PAS `dist/`. Le repo a actuellement ~50 fichiers `D dist/*.js` (suppressions non commit). Le Dockerfile build-stage regenere dist via `npm run build`, donc le dirty ne bloque pas un rebuild. Cependant, le tracking de dist est une mauvaise pratique : a remediter en phase dediee `.gitignore` cleanup.

---

## 7. Images do-not-redeploy

| Image | Env | Commit source | Cause rollback | Statut | Preuve |
|---|---|---|---|---|---|
| keybuzz-client:v3.5.177-escalation-notifications-ux-dev | DEV | (AS.1 client build) | build sans --build-arg explicite, bundle pointait vers API PROD depuis DEV, Inbox vide | DO_NOT_REDEPLOY | AS.1.2 rapport + docs/BUILD-ARGS.md |
| keybuzz-client:v3.5.178-escalation-notifications-client-fix-dev | DEV | (AS.1.1 tentative fix) | meme cause que v3.5.177, fix non suffisant | DO_NOT_REDEPLOY | AS.1.2 rapport |
| keybuzz-api:v3.5.169-tenant-guard-scope-fix-dev | DEV | 4d88e989 (AS.4.1 global tenant guard) | tenantGuard global a casse plusieurs flux DEV (channels, catalogue, etc.) | DO_NOT_REDEPLOY | AS.4.3 revert par a523db7c |
| keybuzz-client:v3.5.180-messages-bff-tenant-guard-dev | DEV | 57766ea (AS.5 BFF /messages) | BFF allowlistee /messages a casse Brouillon IA SWITAA AUTOPILOT | DO_NOT_REDEPLOY | AS.5.3 rollback runtime |
| keybuzz-client:v3.5.181-inbox-ai-auto-suggestion-dev | DEV | 8d8121f (AS.5.1 useEffect autotrigger) | mauvais comportement UX, affichait Suggestion IA au lieu de Brouillon IA pour AUTOPILOT | DO_NOT_REDEPLOY | AS.5.3 rollback |
| keybuzz-client:v3.5.182-tenant-guard-bff-compat-fix2-dev | DEV | (AS.4.x BFF generique) | BFF generique a casse channels et catalogue UI | DO_NOT_REDEPLOY | AS.4.3 revert client par 9a2081c |
| keybuzz-api:v3.5.169-messages-tenant-guard-dev | DEV | eae84b58 (AS.5 messages tenantGuard) | corruption flux Brouillon IA SWITAA AUTOPILOT par effet de bord runtime non isole en statique | DO_NOT_REDEPLOY | AS.5.3 rollback + AS.5.4 source revert par b8613f0f |

Confusion note : il existe DEUX images de tag v3.5.169 differentes selon le contexte (`tenant-guard-scope-fix-dev` issue de AS.4.1 et `messages-tenant-guard-dev` issue de AS.5). Cette collision de version mineure est une dette de tag : a clarifier en pratique future en utilisant des numeros distincts.

Liste a maintenir : ces 7 images ne doivent jamais etre re-deployees, ni re-tagguees, ni rebuild. Tout pipeline qui les referencerait est suspect. Les commits source associes (4d88e989, eae84b58, 57766ea, 8d8121f) ont ete archives sur des branches archive/ origin et ne sont plus sur les HEAD des branches imposees.

Archives branches origin (preservation experimentation) :
- archive/key-304-api-as5-messages-guard-eae84b58
- archive/key-304-client-as5-messages-bff-57766ea
- archive/key-305-client-as51-ai-autotrigger-8d8121f

Aucune image PROD dans la liste DO_NOT_REDEPLOY. PROD n a jamais ete touchee par les rollbacks AS.x.

---

## 8. Functional audit DEV / PROD

Probes read-only HTTP (depuis bastion install-v3) :

| Surface | Endpoint | DEV | PROD | Verdict |
|---|---|---|---|---|
| API health | /health | 200 (170ms) | 200 (184ms) | OK |
| API messages | /messages/conversations (sans auth) | 400 (tenant_id requis) | 400 (idem) | OK -- comportement conforme |
| API /api/ai/mode probe | /api/ai/mode | 404 (route non exposee en GET libre) | 400 | not-a-bug, route protegee |
| Admin redirection | / | 307 redirect login | 307 redirect login | OK |
| Website root | / | (not tested DEV) | 200 | OK PROD |
| Backend health | /health | 200 | 200 | OK |
| Client root | / | status=000 depuis bastion | status=000 depuis bastion | NOT TESTED (firewall sortant bastion probable). Test reel = navigateur Ludovic. |
| Client BFF /api/notifications | / | 000 (idem) | 000 (idem) | NOT TESTED depuis bastion. |
| API /tenant-context/entitlement | observe dans logs DEV | 200 (12-32ms) | (non observe dans 50 lignes recentes) | OK DEV |

Surfaces non testees en read-only (necessitent navigateur logged-in, hors scope read-only bastion) :
- Auth / Tenant : login/session, tenant-context, plan/entitlement, current tenant SWITAA, owner display - status presume OK car runtime images stables et confirmees AS.5.3.
- Inbox / Messages : liste conversations, nouveaux messages, detail, reply, filters, channels visibles, catalogue, SAV panels - status presume OK.
- AI / Autopilot : Brouillon IA SWITAA AUTOPILOT, draft amont, Valider et envoyer, Modifier/Ignorer, KBActions balance, no Suggestion IA pour AUTOPILOT - QA Ludovic AS.5.3 confirme OK ("OK -- Brouillon IA visible auto").
- Tracking / Orders : commande liee, tracking number, 17Track, carrier endpoints - presume OK car pas de changement runtime AS.x.
- Channels / Suppliers / Catalogue : channels actifs, suppliers, catalogue, supplier cases batch - "tout fonctionne comme avant" Ludovic post-rollback AS.4.3.
- Stats / Dashboard : overview, supervision - presume OK.
- Notifications AS.1 : code DEV v3.5.168 inclut AS.1, badge escalation visible cote UI DEV ; PROD inchangee.
- Billing / Plans : current, plan AUTOPILOT SWITAA - presume OK.

Conclusion E8 : aucune regression critique observable cote API/Backend/Website endpoints depuis bastion. La majorite des verifications de UX necessitent un navigateur logged-in et sont reportees a une phase QA dediee si Ludovic exprime un doute supplementaire. Tous les rapports AS.x recents et la QA Ludovic AS.5.3 convergent vers un DEV fonctionnel stable.

---

## 9. Logs read-only

| Signal | Observe | Impact | Verdict |
|---|---|---|---|
| API DEV requests | /health 200, /tenant-context/entitlement 200, /messages/conversations 400 (no auth), /debug/outbound/tick 200, /api/ai/mode 404 (probe AS.5.5) | Normal | OK |
| API PROD requests | /health 200, /messages/conversations entrant, /debug/outbound/tick 404 (debug disabled PROD) | Normal | OK |
| API DEV erreurs | (aucune erreur dans 50 lignes recentes) | - | OK |
| API PROD erreurs | (aucune erreur dans 50 lignes recentes) | - | OK |
| Backend DEV erreurs | (aucune erreur grep error\|fail\|exception\|crash dans 100 lignes) | - | OK |
| Backend PROD erreurs | (aucune erreur dans 100 lignes) | - | OK |
| Client DEV erreurs | Demarrage Next.js 14.2.35 normal, ready 541ms, pas d erreur | - | OK |
| Client PROD erreurs | 31 occurrences `[next-auth][error][JWT_SESSION_ERROR] decryption operation failed` sur 500 lignes ; 0 occurrence DEV | Login utilisateurs PROD potentiellement impacte | A INVESTIGUER (hors scope AS.5.5) |
| Pods restart counts | Tous 0 sauf outbound-worker DEV 8 et PROD 7 (workers en restart depuis 1 mois) | Workers stable malgre restarts repartis | HORS SCOPE AS.5.5 |

Hypotheses JWT_SESSION_ERROR PROD (toutes a verifier en phase ulterieure) :
- Rotation NEXTAUTH_SECRET depuis un deploy precedent ; cookies legacy users PROD invalides.
- NEXTAUTH_SECRET build args manquant ou desaligne.
- Bot / scraper qui essaie d injecter des cookies bidons.

Aucun secret affiche dans cet audit. Filtre PII applique sur les outputs logs (tenant_id, email, switaa, ecomlg, order, tracking, password, token, userId, messageId, conversationId, amazon, client_id).

---

## 10. PROD parity analysis

DEV n est pas et ne doit pas etre byte-identique a PROD : DEV contient des features validees non encore promues.

### 10.1 Categorie A - Parite REQUISE (bloquant si divergence inacceptable)

| Surface | DEV | PROD | Risque | Action |
|---|---|---|---|---|
| login / auth | code DEV identique au pattern PROD | OK | nul | aucun |
| tenant context | v3.5.168 / v3.5.151 partagent /tenant-context | OK | nul | aucun |
| inbox / messages | DEV runtime v3.5.168+v3.5.179 fonctionnel ; PROD inchangee | OK | nul | aucun |
| Brouillon IA SWITAA AUTOPILOT | DEV OK (QA Ludovic) ; PROD inchangee (reference) | OK | nul | aucun |
| commandes / tracking | code DEV n a pas modifie commandes/tracking | OK | nul | aucun |
| billing display | code DEV n a pas modifie billing | OK | nul | aucun |

### 10.2 Categorie B - Differences DEV ACCEPTEES (non bloquantes)

| Difference | Categorie | Risque | Action |
|---|---|---|---|
| AS.1 notifications escalation code present DEV (v3.5.168) absent PROD (v3.5.151) | feature DEV en attente promotion | medium (KEY-263 bloquee par KEY-301/304) | resoudre KEY-301 avant promotion |
| KEY-302 build args hardening Client (sentinels Dockerfile + scripts) present DEV (v3.5.179) absent PROD (v3.5.174) | hardening source-only DEV | nul tant que pas de rebuild PROD | inclure KEY-302 dans la prochaine promotion Client PROD |
| Documentation 12 rapports AS.x dans keybuzz-infra/docs/ | rapports internes | nul | conserver |
| AR.5.x / AR.7 / AS.1 commits intermediaires DEV vs PROD AR.5.2 | DEV a 17 versions API d avance (v3.5.151 -> v3.5.168) et 5 versions Client (v3.5.174 -> v3.5.179) | normal pour un cycle de developpement | promotion progressive prevue mais bloquee par KEY-301 |
| 3 branches archive/* sur origin (key-304 + key-305) | preservation experimentation rollbackee | nul | maintenir pour future reprise |

### 10.3 Categorie C - Differences DEV DANGEREUSES (a corriger)

Aucune difference dangereuse detectee a la date 2026-05-11 post-AS.5.4.

Pre-AS.5.4 : la dette source/runtime drift (HEAD AS.5+AS.5.1 vs runtime AS.5.3) etait dangereuse car un rebuild aurait re-introduit la regression Brouillon IA. Cette dette est ELIMINEE par AS.5.4.

| Difference | Categorie | Risque | Action |
|---|---|---|---|
| (aucune) | - | - | - |

---

## 11. What were we doing before (avant la derive AS.x)

Fil de travail observable d apres CURRENT_STATE.md + rapports infra recents :

Phase active avant la cascade AS.1 -> AS.5.4 :
- Theme : promotion AS.1 notifications escalation proactive en PROD (KEY-263, KEY-265, KEY-253).
- API : promotion attendue v3.5.168-escalation-notifications-prod a partir du commit 070707a1 sur branche ph147.4/source-of-truth.
- Client : promotion attendue Client PROD avec build args fix integre apres incident AS.1.1.
- Linear bloquants connus : KEY-263 (parent), KEY-265, KEY-253.

Phases anterieures stables (commit infra `eeae935` = AR.5.2 PROD promotion) :
- AR.5 / KEY-292 : conversation tone internal metric, DEV puis PROD. Runtime PROD actuel = v3.5.151 (API) + v3.5.174 (Client) issus de cette promotion.
- AR.7 : message source enrichment DEV (en cours au moment AS.1).

Plus loin :
- T8.10 / T8.11 : marketing owner stack PROD promotion, media buyer LP domain QA.
- T8.9A / B / C : pre-tenant funnel visibility foundation (KEY funnel).
- T8.8 series : ad_spend tenant safety + idempotence + Meta CAPI + ad-accounts UI + secret store.
- T8.7 series : Meta CAPI native per-tenant + error sanitization.
- Phases AO (Autopilot Outbound) : escalation handoff, promise detection, consume guardrail (commit api c62f376 + backend v1.0.47).

Prochaine action prevue avant la derive : promotion AS.1 PROD (KEY-263).

Apres la derive : la promotion AS.1 PROD reste BLOQUEE par les decouvertes KEY-301 (tenantGuard runtime ouvert) et KEY-304 (security messages a refaire endpoint-by-endpoint). Aucun GO PROD ne doit etre donne sans resolution propre de KEY-301/304.

Incertitude : aucune. Le fil de travail "avant la derive" est documente dans CURRENT_STATE.md + rapports AR.5.x / AR.7 / AS.1 et les commits infra correspondants.

---

## 12. Strategic recommendation

### 12.1 Scenario A - Freeze current runtime, source aligned, resume planned work (RECOMMANDE)

Conditions :
- DEV stable : MATCH=yes 10/10 services, pods Ready, source aligne.
- Source HEAD safe : diffs vs anchors (070707a1 / f244a58) vides sur perimetre code.
- Pas de regression critique observee en DEV.
- KEY-302 hardening source en place.

Actions proposees (HORS SCOPE AS.5.5, propositions a kicker en phases dediees) :
1. Maintenir runtime DEV (API v3.5.168 + Client v3.5.179) et PROD (API v3.5.151 + Client v3.5.174). Aucune action requise.
2. Phase AS.5.6 ou AS.6 dediee : investigation root cause AS.5 -> Brouillon IA absent. Analyse runtime DevTools / network trace cote DEV en parallele v3.5.179 vs v3.5.180 sur la meme conversation SWITAA AUTOPILOT. Identifier la dependance exacte BFF /messages -> autopilot draft worker.
3. Phase AS.7 ou ulterieure (apres root cause isolee) : reprise endpoint-by-endpoint tenant guard KEY-301/304. Phase de design integrant EXPLICITEMENT la QA Brouillon IA + Inbox + channels + catalogue + commandes + tracking.
4. Phase NS dediee : investigation JWT_SESSION_ERROR PROD (31 occurrences sur 500 lignes). Verifier NEXTAUTH_SECRET stabilite, cookies legacy users, possible bot.
5. Phase TD dediee : nettoyage repos dirty non-build (keybuzz-api .gitignore dist/, keybuzz-backend .bak files, keybuzz-admin quarantine archive vs delete).
6. Phase doc dediee : enrichir CLAUDE.md pour mentionner explicitement keybuzz-admin-v2 comme repo admin runtime (vs keybuzz-admin quarantained).
7. Phase TD dediee : ajout label Docker `org.opencontainers.image.revision` aux Dockerfiles pour traceability commit-source -> image automatique.

### 12.2 Scenario B - Rollback plus loin vers etat comparable PROD (NON RECOMMANDE)

Conditions non remplies :
- DEV est stable.
- Source est aligned.
- Pas plusieurs workflows casses.

Si neanmoins envisage (par exemple par decision produit), couts :
- Rollback API DEV v3.5.168 -> v3.5.151 et Client DEV v3.5.179 -> v3.5.174 effacerait le travail AS.1 + KEY-302.
- Perte de la baseline de development.
- Risque elevee de regression sur les features post-v3.5.151 en cours.
- Aucun GO produit ne semble justifier ce scenario actuellement.

### 12.3 Scenario C - Full audit + rebuild clean (NON RECOMMANDE)

Conditions non remplies :
- Source / runtime sont relies via anchors 070707a1 + f244a58.
- Rebuild safe est demontre par les diffs vides AS.5.4.

Si neanmoins envisage, couts :
- Worktree clean + build args explicites + tags immuables + GitOps + QA matrix complet par service.
- Cout temps eleve.
- Pas necessaire vu AS.5.4 alignment fait.

---

## 13. Gaps materiels (toutes phases prevues HORS AS.5.5)

1. Root cause statique AS.5 -> Brouillon IA absent NON isolee. Necessite analyse runtime cote DEV (DevTools network trace + state inspection en parallele v3.5.179 vs v3.5.180 sur SWITAA AUTOPILOT recente conversation). Bloquant pour toute reprise security messages.

2. JWT_SESSION_ERROR PROD recurrent (31 occurrences / 500 lignes) ; 0 DEV. A investiguer : rotation NEXTAUTH_SECRET, cookies legacy, bot.

3. Faille tenantGuard runtime /messages (KEY-301) reste ouverte en DEV et PROD. Trade-off assume post-AS.5.3 : priorite restauration flux Brouillon IA sur durcissement security. A reprendre endpoint-by-endpoint apres root cause isolee.

4. AS.1 PROD promotion (KEY-263) bloquee tant que KEY-301/304 non resolus.

5. CLAUDE.md ne mentionne pas keybuzz-admin-v2 (vrai repo admin runtime). Mentionne seulement keybuzz-admin (quarantained). Risque d induction en erreur pour agent qui suit CLAUDE.md a la lettre.

6. Repos dirty non-build (non bloquant build mais signaux desordre) :
   - keybuzz-api : ~50 fichiers D dist/*.js (artefact regenere par Dockerfile build stage).
   - keybuzz-client : M tsconfig.tsbuildinfo (artefact build).
   - keybuzz-backend : ?? amazon.routes.ts.bak (artefact pre-AO.2 patch).
   - keybuzz-admin : DIRTY 10 modif + 4 untracked + QUARANTINED.md (non-utilise pour build, PH86.0 legacy).

7. Dette tag image keybuzz-api : tag v3.5.169 utilise pour 2 builds differents (`tenant-guard-scope-fix-dev` AS.4.1 et `messages-tenant-guard-dev` AS.5). A clarifier en pratique future avec numerotation distincte.

8. Aucune image ne porte de label Docker `org.opencontainers.image.revision`. Traceability commit-source -> image-tag uniquement via rapports PH.

9. Outbound workers DEV+PROD ont 7-8 restarts sur 1 mois. Repartis sur la duree donc non-critique mais a surveiller.

10. keybuzz-admin-v2 Dockerfile a des defaults PROD-pointing (`NEXT_PUBLIC_API_URL=https://api.keybuzz.io`) sans sentinel guard equivalent KEY-302. Si admin-v2 a un build DEV regulier, risque latent identique a AS.1.1 (bundle DEV pointant vers PROD).

---

## 14. Linear texts prepared, NOT posted

POSTING ON HOLD : aucun commentaire Linear poste dans cet audit AS.5.5. Les textes ci-dessous sont des propositions disclosure-controlled. Conformite memoire AS.5.4 : pas de detail technique mecanisme d implementation (wrappers Fastify, prefixes, BFF mirror).

### KEY-305 - propose (Done ou In Review selon workflow)
```
AS.5.5 audit verite complet termine read-only. Brouillon IA SWITAA AUTOPILOT reste fonctionnel en DEV runtime v3.5.179 (Client) + v3.5.168 (API). PROD inchangee.

Root cause statique AS.5 -> Brouillon IA absent toujours NON isolee. A investiguer en phase dediee avec analyse runtime DevTools / network trace parallele v3.5.179 vs v3.5.180.

Source / runtime align via AS.5.4 reverts. Aucun risque rebuild HEAD.

Statut propose : Done (audit termine, alignment confirme) ou In Review.
```

### KEY-304 - propose (Open, ajout note)
```
AS.5.5 confirme : security messages a refaire endpoint-by-endpoint apres phase de design dediee integrant QA Brouillon IA + Inbox + channels + catalogue + commandes + tracking. Branches archive sur origin preservent l experimentation.

Statut : reste Open. Ne pas relancer reprise sans design preable.
```

### KEY-301 - propose (Open, ajout note)
```
AS.5.5 audit confirme : faille tenantGuard runtime /messages reste ouverte en DEV et PROD. Trade-off assume post-AS.5.3 : priorite restauration flux Brouillon IA. A reprendre apres root cause statique AS.5 isolee.

Statut : reste Open.
```

### KEY-263 - propose (Blocked, ajout note)
```
AS.5.5 audit confirme : AS.1 notifications escalation code DEV existe et fonctionne (runtime v3.5.168). Promotion PROD reste BLOQUEE par KEY-301 + KEY-304.

Aucun GO PROD a ce stade. Pas de relance avant resolution KEY-301/304 et QA Inbox / Brouillon IA revalidee.

Statut : reste Blocked.
```

### KEY-302 - propose (Done ou In Review, ajout note)
```
AS.5.5 audit confirme : KEY-302 build args guard Client en place et durable. Sentinels Dockerfile + scripts check-client-build-args.sh + verify-client-bundle-api-url.sh + docs/BUILD-ARGS.md. Runtime DEV v3.5.179 valide la chaine. PROD Client v3.5.174 ne contient pas encore KEY-302 ; inclure dans la prochaine promotion Client PROD.

Statut suggere : Done DEV ou In Review.
```

POSTING ON HOLD : ne rien publier avant nouveau GO Ludovic explicite.

---

### 14.bis Phrase cible finale

Runtime DEV (API v3.5.168 + Client v3.5.179) et PROD (API v3.5.151 + Client v3.5.174 + Backend v1.0.47 + Website v0.6.12 + Admin v2.12.2) sont MATCH GitOps 10/10 ; source keybuzz-api HEAD b8613f0f et keybuzz-client HEAD 8cdc04a sont byte-equivalents aux anchors safe 070707a1 et f244a58 ; aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun commit hors rapport, aucun post Linear realise dans cette phase ; AS.5.5 verdict GO SAAS TRUTH READY - CURRENT DEV STABLE, SOURCE SAFE avec gaps materiels documentes pour phases dediees.

STOP
