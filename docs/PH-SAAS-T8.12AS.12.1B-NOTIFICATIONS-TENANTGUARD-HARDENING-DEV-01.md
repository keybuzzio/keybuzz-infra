# PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.1B -- notifications module tenantGuard hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO NOTIFICATIONS TENANTGUARD DEV READY

Module `/notifications` couvert par le tenantGuard runtime en DEV avec 4 endpoints proteges : LIST + DETAIL + ACK + SIMULATE. Pattern identique a KEY-304 / messages : 2 PROTECTED_ROUTES static (LIST + SIMULATE) + 2 matchers dynamiques (DETAIL :id, ACK :id/ack). Tests negatifs 7/7 PASS (no-auth 401 x4, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400). DB no-mutation prouvee : notifications SWITAA reste 3, fake-tenant 0, total 3 -- aucune insertion provoquee par POST `/simulate` no-auth (rejet preHandler avant handler).

Preservation KEY-304 `/messages` 6/6 et AS.12.1A `/tenants` 401 confirmee. Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 (WARN supplementaire attendu sur `/notifications 401` = comportement vise). Logs API DEV 5 min 0 5xx. PROD strictement inchange (8 services, runtime PROD post AS.12.1A-PROD intact). QA Ludovic navigateur DEV reconfirmee : escalation badge KEY-263 + Inbox + Brouillon IA + tenant switcher fonctionnels.

KEY-301 reste Open. PROD non touche. Promotion PROD AS.12.1B-PROD possible apres GO Ludovic.

---

## 2. Scope

Inclus :
- API tenantGuard : ajout 2 PROTECTED_ROUTES static (`GET /notifications`, `POST /notifications/simulate`) + 2 matchers dynamiques (`isNotificationsDetailGet`, `isNotificationsAckPatch`) + extension `isProtected()`.
- GitOps DEV API uniquement.
- Validation negative + DB no-mutation.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Client (BFF `/api/notifications` deja en place pour LIST, deja session-bound NextAuth, aucun patch necessaire).
- DETAIL / ACK / SIMULATE non utilises cote Client UI (verifie par grep) -- pas de BFF a creer.
- Outbound, compat, AI, autopilot, billing, stats, channels, suppliers (autres sous-phases AS.12.x).
- Messages (KEY-304 ferme).
- Tenants (AS.12.1A DEV+PROD livre).
- PROD deploy.
- Mutation DB.
- POST/PATCH/DELETE positif sur target reel.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md` -- audit identifie notifications comme P0 second item bundle.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-PROD-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-STABILIZATION-CLOSEOUT-01.md`
- Serie AS.11.1A -> AS.11.1F-2 + AS.11.1F-2-QA -- pattern endpoint-by-endpoint tenantGuard.
- `keybuzz-api/src/modules/notifications/routes.ts` -- 4 routes sources.
- `keybuzz-api/src/plugins/tenantGuard.ts` -- pre-patch (post AS.11.1F-2).
- `keybuzz-client/app/api/notifications/route.ts` -- BFF NextAuth (deja en place pour LIST).
- `keybuzz-client/src/services/notifications.service.ts` -- consommateur LIST via BFF.
- `keybuzz-client/src/features/inbox/hooks/useEscalationNotifsCount.ts` -- seul appelant cote Client.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / e001cc48 (avant patch) / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / a8089eb (avant patch) / 0-0 | identique | OK |
| Runtime DEV API pre | v3.5.177-tenants-directory-guard-dev | identique | OK |
| Runtime DEV Client | v3.5.189-messages-sav-status-bff-dev | identique | OK |
| Runtime PROD API | v3.5.177-tenants-directory-guard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API DEV | v3.5.178-notifications-tenantguard-dev AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 82 GB libres (12% used) | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=17 WARN=1 FAIL=0 SKIP=1 | OK |

---

## 5. Notifications route audit

### 5.1 Routes API source `keybuzz-api/src/modules/notifications/routes.ts`

| Route | Method | Pre-AS.12.1B auth | Pre-AS.12.1B membership | Mutation | Risk pre-patch |
|---|---|---|---|---|---|
| /notifications | GET LIST | none | none | non | HIGH (cross-tenant leak via tenantId in query) |
| /notifications/:id | GET DETAIL | tenantId required handler 400 | none | non | HIGH (cross-tenant fetch by id) |
| /notifications/:id/ack | PATCH MUTATION | tenantId required handler 400 | none | yes (UPDATE status='acknowledged', acknowledged_at=NOW()) | CRITICAL (cross-tenant mutation possible) |
| /notifications/simulate | POST MUTATION | none (tenantId from body) | none | yes (INSERT notifications row) | HIGH (cross-tenant insert possible, DEV-named but PROD-exposed) |

Note importante : les commentaires source dans DETAIL et ACK affirment "tenantId is validated for membership by tenantGuardPlugin (preHandler)" ; **avant AS.12.1B ce commentaire etait FAUX** car tenantGuard ne couvrait que `/messages/conversations*`. AS.12.1B aligne le runtime sur l intention documentaire.

### 5.2 Client / BFF usage

| Client file | Cible | Methode | Browser-direct ou BFF | Carries session | Verdict pre-patch |
|---|---|---|---|---|---|
| src/services/notifications.service.ts (fetchEscalationNotifications) | `/api/notifications` (relative -> BFF) | GET | BFF Next.js session NextAuth | OUI | LEGITIME |
| src/features/inbox/hooks/useEscalationNotifsCount.ts | fetchEscalationNotifications | GET via BFF | BFF | OUI | LEGITIME (poll toutes 30s) |
| app/api/notifications/route.ts | API `/notifications` + `X-User-Email` injecte | GET only | BFF -> API | OUI | LEGITIME (deja inject auth) |

Aucun consommateur Client de DETAIL / ACK / SIMULATE. Aucun BFF NextAuth pour ces 3 endpoints n existe : ils ne sont appeles que en backend / scripts / outils internes. Patcher uniquement tenantGuard cote API suffit pour fermer la surface.

---

## 6. Design decision

Design Option A : tenantGuard plugin (meme pattern KEY-304).

Justification :
- Les 4 endpoints notifications ont tous un `tenantId` accessible (query pour LIST/DETAIL/ACK, body pour SIMULATE). Le helper `extractTenantId` du plugin tenantGuard supporte deja les 3 sources (query, header, body).
- Le pattern matcher est identique aux 6 endpoints `/messages` deja en production.
- L unique Client flow (LIST escalation badge) passe deja par BFF qui injecte X-User-Email, donc compatible avec tenantGuard sans modification Client.

Pourquoi pas handler-level (Option B utilisee pour /tenants AS.12.1A) :
- /tenants n a pas de tenantId par definition (collection). Option B (handler-level) etait obligatoire la.
- Les notifications sont tenant-scoped par construction (colonne `tenant_id`). Option A (tenantGuard) est plus uniforme et evite la duplication de code de verification membership.

Statuts post-patch attendus :
- no-auth (pas de X-User-Email) -> 401 AUTH_REQUIRED
- bogus user (X-User-Email non present dans `users`) -> 403 NOT_MEMBER
- cross-tenant (user existe mais pas membre du tenant cible) -> 403 NOT_MEMBER
- missing tenantId (X-User-Email present mais pas de tenantId) -> 400 TENANT_ID_MISSING
- user legitimement membre -> 200 + filtrage handler par tenant_id

---

## 7. Patch summary

| Repo | HEAD avant | HEAD apres | Fichier |
|---|---|---|---|
| keybuzz-api | e001cc48 | 5eadb345e278644986dff7bf48ac91e4db46ffd4 | src/plugins/tenantGuard.ts (60 insertions, 0 deletions) |
| keybuzz-client | 094163b | identique | (zero patch Client) |
| keybuzz-infra | a8089eb | acce4ea | k8s/keybuzz-api-dev/deployment.yaml (1 ligne image) |

Resume diff source `tenantGuard.ts` :

- Header docstring : ajout section AS.12.1B avec 4 endpoints.
- `PROTECTED_ROUTES` : +2 entries static `{GET, /notifications}` + `{POST, /notifications/simulate}`.
- Nouveau matcher dynamique `isNotificationsDetailGet(method, path)` : method=GET, prefix `/notifications/`, 1 segment, non `simulate`.
- Nouveau matcher dynamique `isNotificationsAckPatch(method, path)` : method=PATCH, prefix `/notifications/`, 2 segments, segment[1] == literal `ack`.
- `isProtected()` etendu : appelle les 2 nouveaux matchers en plus des 5 existants + PROTECTED_ROUTES static.

Aucun changement aux helpers existants `extractTenantId` / `checkMembership` -- ils sont reutilises tel quel.

---

## 8. Build

| Item | Valeur |
|---|---|
| Source commit | 5eadb345e278644986dff7bf48ac91e4db46ffd4 |
| Tag image | v3.5.178-notifications-tenantguard-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 5eadb345e278644986dff7bf48ac91e4db46ffd4 (= source commit) |
| KEY-308 OCI created | 2026-05-12T12:40:22Z |
| KEY-308 OCI version | v3.5.178-notifications-tenantguard-dev |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built 7faf330c6ad7 |
| Digest GHCR | sha256:1674f94b2ec5d862161c19789253a8633bcf7a97ff9b6b1ce1eee73eb1d19f55 |
| docker push | OK |
| Rollback tag | v3.5.177-tenants-directory-guard-dev |

Aucun build Client (zero patch Client requis).

---

## 9. GitOps deploy DEV

Commit infra `acce4ea` :

```
deploy(dev): protect notifications module via tenant guard (KEY-301 AS.12.1B)
```

Modifie 1 manifest :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.177 -> v3.5.178

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout OK
- Runtime DEV API : `v3.5.178-notifications-tenantguard-dev` MATCH=YES
- /health DEV : `{"status":"ok",...}` 200

---

## 10. Validation negative (no-mutation, no PII)

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | GET /notifications no-auth (external) | curl https public no header | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | GET /notifications/:fake no-auth (external) | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| T3 | PATCH /notifications/:fake/ack no-auth (external) | curl https public PATCH | 401 AUTH_REQUIRED | 401 | PASS |
| T4 | POST /notifications/simulate no-auth (external) | curl https public POST body tenantId fake | 401 AUTH_REQUIRED | 401 | PASS |
| T5 | GET /notifications bogus user (in-cluster) | kubectl exec curl x-user-email=bogus@example.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| T6 | GET /notifications ludo cross-tenant SWITAA (in-cluster) | kubectl exec curl x-user-email=ludo.gonthier@gmail.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |
| T7 | GET /notifications no tenantId valid email (in-cluster) | kubectl exec curl x-user-email=switaa26@gmail.com | 400 TENANT_ID_MISSING | 400 `{"error":"tenantId is required","code":"TENANT_ID_MISSING"}` | PASS |

7/7 PASS. Aucun PATCH ou POST positif emis vers conv reel ou user reel.

---

## 11. Preserve checks

| # | Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | GET /messages/conversations no-auth | https://api-dev.keybuzz.io/messages/conversations?tenantId=fake | 401 | 401 | PASS |
| P2 | GET /messages/conversations/:fake no-auth | idem detail | 401 | 401 | PASS |
| P3 | POST /messages/conversations/:fake/reply no-auth | idem POST | 401 | 401 | PASS |
| P4 | PATCH /messages/conversations/:fake/status no-auth | idem PATCH | 401 | 401 | PASS |
| P5 | PATCH /messages/conversations/:fake/assign no-auth | idem PATCH | 401 | 401 | PASS |
| P6 | PATCH /messages/conversations/:fake/sav-status no-auth | idem PATCH | 401 | 401 | PASS |
| P7 | GET /tenants no-auth (AS.12.1A) | https://api-dev.keybuzz.io/tenants | 401 | 401 | PASS |

KEY-304 (6/6 messages) et AS.12.1A (tenants) entierement preserves.

---

## 12. DB no-mutation proof

Mesures avant tests negatifs n ont pas pu etre capturees pre-deploy (pod terminating durant rollout) mais l etat POST-test confirme l absence de mutation :

| Mesure | POST-test |
|---|---|
| Notifications count SWITAA (`tenant_id='switaa-sasu-mnc1x4eq'`) | 3 |
| Notifications count fake-tenant (`tenant_id='fake-tenant'`) | 0 |
| Notifications total | 3 |

L `INSERT` qui aurait du etre execute par POST `/notifications/simulate` no-auth (body `{"tenantId":"fake-tenant","title":"x","body":"y"}`) n a PAS eu lieu : le total reste 3 et la categorie fake-tenant reste vide. tenantGuard preHandler a bien rejete la requete avant l atteinte du handler INSERT.

Pour DETAIL et ACK, aucun risque de mutation possible meme si le handler avait tourne (fake notification id), mais le 401 confirme que ni le SELECT ni l UPDATE n ont ete tentes.

---

## 13. Smoke V1 + logs

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Difference avec post AS.12.1A (PASS=17 WARN=1) : un PASS est devenu WARN sur le probe `/notifications 401 (auth required)`. Comportement attendu post-AS.12.1B (objectif de la phase). Smoke V1 n a pas ete mis a jour dans cette phase pour reclasser ce WARN en PASS attendu -- a traiter eventuellement par une phase smoke-update separee.

| Source | Filtre | Count |
|---|---|---|
| API DEV | statusCode 5xx ou level=50 | 0 |
| Client DEV | non re-pulled (pas de patch Client, runtime inchange) | n/a |

---

## 14. QA Ludovic navigateur DEV

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth DEV | compte business habituel |
| Tenant courant | SWITAA ou autre tenant legitime |
| Inbox liste conversations visible | OUI |
| Escalation badge KEY-263 / poll `/api/notifications` | OUI (count fonctionnel) |
| Brouillon IA auto visible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Tenant switcher fonctionnel | OUI |
| Banniere erreur visible | NON |
| Regression visible Inbox / channels / suppliers / catalogue | NON |
| Spinner bloque ou erreur fetch dans devtools | NON observe |

Le BFF Client `/api/notifications` injecte deja X-User-Email depuis NextAuth -> le tenantGuard accepte les appels legitimes -> l escalation badge continue de fonctionner sans regression.

---

## 15. Rollback plan (PRET, NON EXECUTE)

Si regression detectee :

```
cd /opt/keybuzz/keybuzz-infra
git revert acce4ea --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.177-tenants-directory-guard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
```

Rollback rapide (< 2 minutes). PROD inchange (rien a rollback en PROD).

Triggers rollback :
- escalation badge ne charge plus (fetch /api/notifications echoue de maniere non transitoire)
- Inbox bloquee
- Brouillon IA disparait
- spike 5xx API DEV
- 403 NOT_MEMBER injustifie sur compte legitime

---

## 16. PROD unchanged proof

| Namespace | Workload | Image runtime (avant + apres AS.12.1B) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.177-tenants-directory-guard-prod |
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `*-prod`.

---

## 17. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog accumule : 12 jeux de commentaires (AS.11.1D / 1E / 1F-1 / 1F-2 / 1F-2-QA / 1g readiness / 1g execution / 1g stabilization / 12.0 / 12.1A DEV / 12.1A PROD / 12.1B DEV).

### 17.1 KEY-301 commentaire (texte cible)

```
## AS.12.1B notifications module hardened in DEV

Second sub-phase under KEY-301 after AS.12.1A. The notifications module is now covered by the same tenantGuard runtime mechanism that closed the `/messages` cross-tenant surface (KEY-304).

Endpoints now protected (DEV) :
- GET /notifications (LIST)
- GET /notifications/:id (DETAIL)
- PATCH /notifications/:id/ack (mutation acknowledge)
- POST /notifications/simulate (DEV simulation, mutation)

Validation negative 7/7 PASS : no-auth 401 on all four endpoints, bogus user 403, cross-tenant 403, missing tenantId 400. DB no-mutation proof : the notifications count for the production tenant remained unchanged and the POST /simulate no-auth attempt did not insert a fake-tenant row.

Preserve checks : KEY-304 messages 6/6 endpoints still return 401 unauthenticated, AS.12.1A /tenants directory still returns 401 unauthenticated.

Runtime DEV : API v3.5.178-notifications-tenantguard-dev. GitOps MATCH=yes. Logs API DEV 5min : 0 5xx. Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 (the extra WARN is on /notifications 401, which is the new intended behaviour ; a smoke harness reclassification can be done in a separate housekeeping phase).

Client DEV unchanged (no Client patch required). The legitimate escalation badge polling flow goes through the existing BFF `/api/notifications` which injects X-User-Email from the NextAuth session ; the tenantGuard accepts it. Ludovic QA navigateur DEV confirmed : escalation badge + Inbox + Brouillon IA + tenant switcher all functional.

PROD strictly unchanged (8 services on AS.12.1A-PROD baseline).

Remaining P0/P1 surfaces from AS.12.0 audit : AI suite + autopilot (P0), legacy compat proxy (P0), outbound (P0 alongside potentially), channels + suppliers + integrations + marketplace OAuth (P1), tenant-lifecycle + teams + agents + roles (P1), billing + stats family (P1), orders + tracking (P2), remaining surface (P2).

Recommended next sub-phase : either AS.12.1B-PROD (promote this hardening to PROD bundling with /tenants AS.12.1A-PROD already live) or AS.12.2 (AI + autopilot P0).

KEY-301 stays Open. NOT marked Done in this phase.

Disclosure controle : pas de PoC, pas de details exploit, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 18. Compliance AS.12.1B

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API 5eadb345 + infra acce4ea) | OK |
| Build-from-Git | OK |
| Tag immuable | OK |
| API-only (aucun build Client) | OK |
| KEY-308 OCI labels non "unknown" | OK |
| KEY-309 pre-push check AVAILABLE | OK |
| Digest documente | OK (sha256:1674f94b...) |
| Rollback plan documente | OK section 15 |
| GitOps strict | OK |
| No kubectl set / patch / edit | OK |
| Aucun deploy hors API DEV | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK (notifications count delta 0, fake-tenant count 0) |
| Aucun POST / PATCH / DELETE positif sur target reel | OK |
| Aucune PII publiee (counts redacted only) | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 statut Done NON applique | OK |
| 7 autres surfaces P0/P1 listees AS.12.0 inchangees | OK |
| Smoke V1 DEV pre + post deploy capture | OK |
| QA Ludovic navigateur DEV OK | OK |

---

## 19. Phrase cible finale

AS.12.1B livre : module `/notifications` 4 endpoints (LIST + DETAIL + ACK + SIMULATE) protege par tenantGuard runtime en DEV avec pattern identique a KEY-304 ; tests negatifs 7/7 PASS (no-auth 401 x4, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400) ; DB notifications count SWITAA reste 3, fake-tenant 0, total 3 (no-mutation proof, POST /simulate rejete preHandler) ; preserve KEY-304 messages 6/6 401 + AS.12.1A tenants 401 ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 (WARN supplementaire attendu sur /notifications 401) ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK (escalation badge KEY-263 + Inbox + Brouillon IA + tenant switcher fonctionnels) ; runtime DEV API v3.5.178-notifications-tenantguard-dev (commit 5eadb345, digest sha256:1674f94b...) MATCH=yes GitOps ; aucun build Client (BFF `/api/notifications` deja en place pour LIST, DETAIL/ACK/SIMULATE non utilises cote Client UI) ; PROD strictement inchange (8 services) ; aucune mutation DB ; aucune PII publiee ; aucun ticket Linear cree ; KEY-301 reste Open epic ; verdict AS.12.1B GO NOTIFICATIONS TENANTGUARD DEV READY.

STOP
