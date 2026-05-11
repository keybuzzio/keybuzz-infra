# PH-SAAS-T8.12AS.5.7-LINEAR-BACKLOG-CONTROLLED-UPDATE-01

> Date : 2026-05-11
> Linear : KEY-305, KEY-304, KEY-301, KEY-263, KEY-302 (mis a jour) ; KEY-306, KEY-307, KEY-308, KEY-309, KEY-310, KEY-311 (crees)
> Phase : T8.12 AS.5.7 - Linear backlog controlled update post AS.5.4 -> AS.5.6B
> Environnement : Linear (mutation comments + statuts + creation tickets) ; runtime read-only inchange ; aucun build, aucun deploy

---

## 1. VERDICT

GO LINEAR BACKLOG UPDATED READY

Linear backlog est desormais aligne avec la verite documentaire produite par les phases AS.5.4 -> AS.5.6B :
- 5 commentaires controles postes sur les issues KEY-305, KEY-304, KEY-301, KEY-263, KEY-302 (disclosure-controlled, pas de PoC, pas de mecanique exploit).
- 2 statuts mis a jour : KEY-305 Todo -> In Review ; KEY-304 In Progress -> Todo.
- 3 statuts maintenus volontairement : KEY-301 (Todo Open) ; KEY-263 (In Review blocked) ; KEY-302 (Done confirme).
- 6 tickets garde-fous crees (KEY-306 a KEY-311) couvrant JWT PROD, admin-v2 build args, OCI labels, tag policy, smoke automation, docs source-of-truth.

Aucune mutation source code, aucune mutation runtime cluster, aucune mutation DB, aucun build, aucun deploy, aucun secret affiche. Token Linear charge depuis fichier hors-repo C:\DEV\KeyBuzz\Linear.txt.

---

## 2. Linear preflight (etat avant AS.5.7)

| Issue | Title | State avant | Priority | Parent | Last comment date |
|---|---|---|---|---|---|
| KEY-305 | Inbox -- auto-suggestion IA ne se genere plus automatiquement | Todo (unstarted) | High | - | (none) |
| KEY-304 | Security -- patch tenantGuardPlugin Fastify scope before AS.1 promotion | In Progress (started) | Urgent | - | 2026-05-11 (AS.5 verdict) |
| KEY-301 | Security -- auditer tenantGuardPlugin DEV/PROD avant promotion notifications | Todo (unstarted) | High | - | 2026-05-11 (AS.5 update) |
| KEY-263 | AP.1.2 -- Escalade : auto-assignation, notification et destination lisible | In Review (started) | Medium | KEY-253 | 2026-05-11 (blocage AS.1 post AS.5) |
| KEY-302 | Infra -- rendre impossible un build Client sans build args DEV/PROD explicites | Done (completed) | Urgent | - | 2026-05-10 (KEY-302 done) |

Tous les commentaires precedents reflechissaient l etat AS.5 (juste avant rollback AS.5.3). Le besoin AS.5.7 etait de mettre a jour ces issues avec l etat post-rollback + post-realignment + post-smoke validation.

Workflow KEY identifie : Backlog (a1170d8e) ; Todo (e10913f0 unstarted) ; In Progress (56e941b0 started) ; In Review (a698a1af started) ; Done (5d43075d completed) ; Canceled / Duplicate. Pas d etat Blocked dans ce workflow.

Recherche tickets existants pour les 6 garde-fous proposes : aucun doublon detecte (search par mots cles JWT, NextAuth, admin-v2, OCI, image label, tag policy, smoke, source-of-truth). Le seul match titre etait KEY-278 (LP copywriting) sur le terme OCI, faux positif.

---

## 3. Commentaires postes (5)

Tous les commentaires ont ete postes via Linear API GraphQL mutation `commentCreate`. Disclosure controle applique strictement :
- aucun PoC, aucune commande curl/kubectl/git exploitable.
- aucun nom de fichier source sensible non public.
- aucun hash commit interne.
- mentions tenantGuard limitees a "audit valide, mitigation non active runtime apres rollback, reprise endpoint-by-endpoint requise".

| Issue | Comment URL |
|---|---|
| KEY-305 | linear.app/keybuzz/issue/KEY-305#comment-4a543771 |
| KEY-304 | linear.app/keybuzz/issue/KEY-304#comment-bae996cd |
| KEY-301 | linear.app/keybuzz/issue/KEY-301#comment-7b9eef56 |
| KEY-263 | linear.app/keybuzz/issue/KEY-263#comment-e34f5195 |
| KEY-302 | linear.app/keybuzz/issue/KEY-302#comment-b163c930 |

### 3.1 KEY-305 commentaire (Inbox auto-suggestion IA)

Resume :
- AS.5.2 invalide (mauvais tenant).
- AS.5.3 rollback runtime pre-AS.5.
- AS.5.4 source/runtime realigne (HEAD byte-equivalent anchors safe).
- AS.5.6B smoke read-only OK cote API : /autopilot/draft hasDraft=true, actionType=autopilot_escalate, confidence=0.85 pour SWITAA AUTOPILOT.
- QA Ludovic navigateur DEV : Brouillon IA visible auto.
- Aucun runtime touche depuis rollback.
- Root cause exacte AS.5 -> Brouillon IA absent NON poursuivie (surface AS.5 retiree).
- Reprise eventuelle endpoint-by-endpoint exigera matrice QA complete (voir KEY-304).

### 3.2 KEY-304 commentaire (TenantGuard /messages)

Resume :
- Tentative AS.5 rollbackee (runtime AS.5.3, source AS.5.4).
- Source experimentale archivee (branches archive/ sur origin).
- Runtime stable actuel ne contient plus la mitigation AS.5.
- Prochaine reprise : design endpoint-by-endpoint obligatoire + matrice QA explicite (Inbox, Brouillon IA SWITAA AUTOPILOT, channels, catalogue/commande liee, suppliers, logs BFF/API, no direct browser regressions) + rollback pret + un endpoint a la fois.
- Pas de divulgation d exploit.

### 3.3 KEY-301 commentaire (audit tenantGuard)

Resume :
- Audit tenantGuard reste valide.
- Apres rollback AS.5, mitigation runtime NON active DEV/PROD.
- Risque securite documente reste ouvert, bloque promotion AS.1 PROD (KEY-263).
- Prochaine reprise progressive avec garde-fous complets + matrice QA (KEY-304).
- Disclosure controle strict.

### 3.4 KEY-263 commentaire (AS.1 PROD blocked)

Resume :
- AS.1 code DEV existe et runtime DEV stable (API v3.5.168 + Client v3.5.179).
- Promotion PROD reste BLOQUEE.
- Bloquants : KEY-301 (audit tenantGuard non corrige) + KEY-304 (reprise endpoint-by-endpoint requise) + necessite QA complete (Inbox, Brouillon IA, channels, catalogue, suppliers).
- Aucun GO PROD.
- Reste In Review (blocked by KEY-301 + KEY-304).
- Reference audit : AS.5.6A confirme alignement DEV/PROD fonctionnel (4 services SAME, 2 DEV_AHEAD_EXPECTED).

### 3.5 KEY-302 commentaire (build args hardening)

Resume :
- Client build args hardening reste source safe (sentinels Dockerfile + scripts publics + docs/BUILD-ARGS.md).
- AS.5.5 et AS.5.6A confirment KEY-302 = difference DEV-ahead attendue et utile.
- A inclure obligatoirement dans toute prochaine promotion Client PROD.
- Reste Done.
- Gap futur (ticket dedie KEY-307) : etendre principe a admin-v2.

---

## 4. Statuts modifies (2) + maintenus (3)

### 4.1 Modifies
| Issue | Avant | Apres | Justification |
|---|---|---|---|
| KEY-305 | Todo | In Review | post AS.5.4 source/runtime align + QA Ludovic OK navigateur + smoke API confirme. Pas Done car la root cause exacte AS.5 n est pas isolee (rollback du troncon plutot que correction). |
| KEY-304 | In Progress | Todo | la phase In Progress AS.5 est terminee par rollback. Reprise propre a planifier (design endpoint-by-endpoint + matrice QA). |

### 4.2 Maintenus
| Issue | State | Justification |
|---|---|---|
| KEY-301 | Todo | reste Open ; risque securite non corrige runtime ; ne pas fermer. |
| KEY-263 | In Review | blocked by KEY-301 + KEY-304 ; commentaire explicite ; pas d etat Blocked dans le workflow KEY donc In Review + comment. |
| KEY-302 | Done | acquis confirme par AS.5.5/AS.5.6A ; reste Done. |

Workflow note : le workflow KEY n a pas d etat dedie "Blocked". Convention adoptee : utiliser In Review + commentaire explicite "blocked by KEY-XXX" pour signaler le blocage dependance.

---

## 5. Tickets garde-fous crees (6)

Tous crees via Linear API mutation `issueCreate`. Team KEY (1a17e0f0-cb1e-47f6-b4b1-b5322329ec00). State initial Todo (e10913f0). Tous Open au moment de la creation.

| ID | Titre | Priority | URL |
|---|---|---|---|
| KEY-306 | Auth -- investiguer les JWT_SESSION_ERROR PROD NextAuth | High (2) | linear.app/keybuzz/issue/KEY-306 |
| KEY-307 | Admin-v2 -- durcir les build args pour eviter les bundles pointant vers PROD par defaut | High (2) | linear.app/keybuzz/issue/KEY-307 |
| KEY-308 | Infra -- ajouter labels OCI commit_sha aux images Docker | High (2) | linear.app/keybuzz/issue/KEY-308 |
| KEY-309 | Infra -- empecher la reutilisation ambigue des tags d image (one tag = one source = one digest) | High (2) | linear.app/keybuzz/issue/KEY-309 |
| KEY-310 | QA -- automatiser les smoke tests read-only DEV avant build/deploy | High (2) | linear.app/keybuzz/issue/KEY-310 |
| KEY-311 | Docs -- mettre a jour les regles source-of-truth CE/Codex apres AS.5 | Medium (3) | linear.app/keybuzz/issue/KEY-311 |

### 5.1 KEY-306 -- JWT_SESSION_ERROR PROD investigation
Contexte : AS.5.5/AS.5.6B observent 31 occurrences JWT_SESSION_ERROR Client PROD sur 500 lignes logs (0 DEV).
Objectif : audit read-only PROD (volume, cause probable, impact users). Aucune mutation PROD. Hypotheses : rotation NEXTAUTH_SECRET, cookies legacy, bots, bug next-auth.
Acceptance : quantify errors / identify root cause category / no secret exposure / no PROD mutation / remediation plan si necessaire.

### 5.2 KEY-307 -- Admin-v2 build args hardening
Contexte : AS.5.5 a identifie que keybuzz-admin-v2 Dockerfile a defaults PROD-pointing sans sentinel guard, risque latent identique a l incident AS.1.1.
Objectif : appliquer pattern KEY-302 a admin-v2 (sentinels + check-script + verify-script + docs).
Acceptance : Dockerfile sentinels / scripts/check-admin-v2-build-args.sh / scripts/verify-admin-v2-bundle-api-url.sh / docs / pipeline DEV build sans args echoue avant npm run build.

### 5.3 KEY-308 -- OCI image revision labels
Contexte : AS.5.5 a constate que le mapping image -> commit source est MED confidence faute de label `org.opencontainers.image.revision`.
Objectif : ajouter label OCI standard sur Dockerfiles api/client/backend/website/admin-v2 + passer GIT_COMMIT_SHA au build time.
Acceptance : Dockerfiles incluent LABEL revision / build command passe GIT_COMMIT_SHA / runtime images inspectables / documente dans build process / exception keybuzz-admin (quarantained PH86.0).

### 5.4 KEY-309 -- Tag discipline immutable
Contexte : AS.5.5 a identifie une dette tag v3.5.169 utilise pour 2 builds API differents (AS.4.1 scope-fix vs AS.5 messages-guard).
Objectif : regle immuable stricte (one tag = one source = one digest) + preflight catch avant docker push.
Acceptance : politique tag documentee / preflight script detecte tag existant / echec build/push si tag deja present / release prompt template MAJ / rollback docs incluent digest.

### 5.5 KEY-310 -- Smoke read-only automation
Contexte : AS.5.6B a formalise des checks read-only sur DEV. A transformer en script automatise.
Objectif : script avant chaque build/deploy DEV. No send, no status change, no DB mutation, no browser cookie write. Redact PII.
Acceptance : script kubectl exec + curl localhost vers API DEV / aucun mutationnel / redact PII / run pre-deploy / outputs PASS/WARN/FAIL / couvre les 9 endpoints valides en AS.5.6B / extensible.

### 5.6 KEY-311 -- Docs source-of-truth update
Contexte : AS.5.5/AS.5.6A/AS.5.6B doivent devenir sources canoniques. CLAUDE.md ne mentionne pas keybuzz-admin-v2 (vrai repo runtime, vs keybuzz-admin quarantained). Certains docs referencent app-dev.keybuzz.io alors que l ingress reel est client-dev.keybuzz.io.
Objectif : mettre a jour docs source-of-truth pour eviter futures confusions agent.
Acceptance : CLAUDE.md mentionne keybuzz-admin-v2 / hostnames documents corrects / prompt template CE reference AS.5.5/AS.5.6A/AS.5.6B / pas de confusion CLAUDE/Codex/AGENTS.md / AS.5.5 ajoute a CURRENT_STATE.md + SOURCE_INDEX.md.

---

## 6. Compliance disclosure

Audit interne de chaque commentaire poste :

| Element | Inclus ? | Notes |
|---|---|---|
| Hashes commits internes | NON | aucun (ex. eae84b58, 57766ea, 8d8121f, b8613f0f, 8cdc04a, d468991, 070707a1, f244a58 retires des commentaires Linear) |
| Noms de fichiers source sensibles | NON | seuls noms publics mentionnes (docs/BUILD-ARGS.md, scripts/check-client-build-args.sh, scripts/verify-client-bundle-api-url.sh) |
| Mecanique tenantGuard / fastify-plugin / PROTECTED_PREFIXES / BFF mirror | NON | aucune description mecanique. Mentions limitees a "audit valide", "mitigation non active runtime apres rollback", "reprise endpoint-by-endpoint requise" |
| Commandes curl / kubectl / git exploitables | NON | aucune commande dans les commentaires |
| PoC / reproduction steps | NON | aucun |
| Mentions runtime images (tags) | OUI (limite) | v3.5.168 API + v3.5.179 Client DEV cites pour context. v3.5.151 + v3.5.174 PROD cites pour reference. Aucun tag DO_NOT_REDEPLOY cite |
| Tenant ID en clair | NON | mention "SWITAA AUTOPILOT" seulement (nom marque visible publiquement) |
| Email user / order ID / tracking | NON | aucune PII dans les commentaires |
| Token Linear | NON | charge depuis fichier hors-repo, jamais affiche |

Verdict disclosure : conforme.

---

## 7. Interdits respectes

| Interdit | Statut |
|---|---|
| aucun patch source | RESPECTE |
| aucun commit code | RESPECTE (seul commit envisage = ce rapport docs sur GO Ludovic) |
| aucun build | RESPECTE |
| aucun docker push | RESPECTE |
| aucun kubectl apply | RESPECTE |
| aucun kubectl set image / patch / edit / set env | RESPECTE |
| aucune modification manifest | RESPECTE |
| aucune mutation DB | RESPECTE |
| aucun test mutationnel | RESPECTE |
| aucun secret en log | RESPECTE (token Linear jamais affiche) |
| aucune divulgation detaillee de faille securite dans Linear | RESPECTE |
| ne pas coller de commandes exploitables tenantGuard dans Linear | RESPECTE |

---

## 8. Gaps materiels (toujours ouverts, pour rappel)

Heritage des phases AS.5.4/AS.5.5/AS.5.6A/AS.5.6B :
1. Root cause statique AS.5 -> Brouillon IA absent toujours non isolee.
2. JWT_SESSION_ERROR PROD recurrent : couvert par KEY-306.
3. KEY-301 tenantGuard runtime reste ouvert.
4. KEY-304 reprise endpoint-by-endpoint a faire avec design dedie.
5. KEY-263 AS.1 PROD promotion bloquee.
6. Source-of-truth docs gaps (CLAUDE.md keybuzz-admin-v2 manquant, hostnames) : couvert par KEY-311.
7. Repos dirty non-build (api dist, backend .bak, admin quarantine) : non couvert par ticket dedie ; a creer en TD-cleanup ulterieur si necessaire.
8. Dette tag v3.5.169 double usage : couvert par KEY-309.
9. Pas de label OCI revision : couvert par KEY-308.
10. Admin-v2 Dockerfile defaults PROD-pointing sans guard : couvert par KEY-307.

---

## 9. Linear texts prepared, NOT posted

N/A pour AS.5.7. Tous les commentaires prepares ont ete postes. Aucune retention "POSTING ON HOLD" cette fois (GO Ludovic explicite obtenu en AS.5.7).

---

### 9.bis Phrase cible finale

Linear backlog post AS.5.4 -> AS.5.6B aligne ; 5 commentaires controles postes (KEY-305, KEY-304, KEY-301, KEY-263, KEY-302) ; 2 statuts mis a jour (KEY-305 Todo -> In Review, KEY-304 In Progress -> Todo) ; 3 statuts maintenus (KEY-301 Todo, KEY-263 In Review blocked, KEY-302 Done) ; 6 tickets garde-fous crees (KEY-306 a KEY-311, tous Todo) ; aucune mutation source/runtime/manifest/DB ; aucun PoC ni exploit divulgues ; verdict AS.5.7 GO LINEAR BACKLOG UPDATED READY.

STOP
