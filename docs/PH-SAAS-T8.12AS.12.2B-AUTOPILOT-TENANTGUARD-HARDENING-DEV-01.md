# PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2B -- autopilot module tenantGuard hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO AUTOPILOT TENANTGUARD DEV READY

Module `/autopilot` couvert par tenantGuard runtime en DEV avec 7 (method, path) tuples proteges sur 5 paths : settings GET/POST/PATCH, draft GET, draft/consume POST, history GET, evaluate POST. Pattern static PROTECTED_ROUTES (paths exacts, pas de matcher dynamique necessaire).

Validation 9/9 PASS : 7 endpoints no-auth -> 401 AUTH_REQUIRED, bogus user -> 403 NOT_MEMBER, ludo cross-tenant SWITAA -> 403. DB no-mutation prouvee : `ai_action_log` SWITAA reste 174, dont autopilot_* reste 87 (delta 0). Aucun POST positif emis vers `/autopilot/evaluate` ou `/autopilot/draft/consume`. Aucune generation IA volontaire. Aucune consommation KBActions. Aucun draftText publie.

Preserve KEY-304 `/messages` 6/6, AS.12.1A `/tenants`, AS.12.1B `/notifications` -- toutes 401 no-auth. Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 (le WARN supplementaire vs pre-deploy etait deja attendu post AS.12.1B sur /notifications, pas de nouvelle deterioration). Logs API DEV 0 5xx. PROD strictement inchange 8 services.

QA Ludovic navigateur DEV confirmee avec switaa26@gmail.com (SWITAA owner, plan AUTOPILOT) : Brouillon IA auto visible sur conv eligible, bouton "Valider et envoyer" present, autopilot settings UI charge, history visible, Inbox + tenant switcher + escalation badge fonctionnels, aucune banniere d erreur.

KEY-301 reste Open epic. PROD non touche. Promotion PROD AS.12.2B-PROD possible apres GO Ludovic.

---

## 2. Scope

Inclus :
- API tenantGuard : ajout 7 entries PROTECTED_ROUTES static pour autopilot.
- GitOps DEV API uniquement.
- Validation negative + DB no-mutation.
- QA Ludovic navigateur DEV pour Brouillon IA (le risque UX critique).
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Client (5 BFF autopilot deja en place et confirmes injectent X-User-Email -- aucun patch necessaire).
- /ai broader scope (settings, wallet, assist, evaluate, execute, journal, ops, returns, intelligence) -- futurs AS.12.2C/D/E/F.
- Endpoints LLM-cost hors `/autopilot/evaluate` (qui est dans le scope autopilot).
- Tests qui generent IA (assist, evaluate sur conv reel, decision retour).
- PROD deploy.
- Mutation DB.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md` -- design audit + decoupage propose.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01.md` + `-PROD-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md`
- Rapports anti-regression Brouillon IA : AS.5.3, AS.5.4, AS.11.0.5, AS.11.0.6.
- `keybuzz-api/src/modules/autopilot/routes.ts` + `engine.ts` -- 7 routes + plan gating PH132-C.
- `keybuzz-api/src/plugins/tenantGuard.ts` -- pre-patch (post AS.12.1B).
- `keybuzz-client/app/api/autopilot/*` -- 5 BFF routes verifiees individuellement.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 5eadb345 (avant patch) / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 66bd71c (avant patch) / 0-0 | identique | OK |
| Runtime DEV API pre | v3.5.178-notifications-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.189-messages-sav-status-bff-dev | identique | OK |
| Runtime PROD API | v3.5.178-notifications-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API DEV | v3.5.179-autopilot-tenantguard-dev AVAILABLE | AVAILABLE | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. BFF Client verification (pre-patch)

Audit individuel des 5 BFF autopilot pour confirmer injection `X-User-Email` + `X-Tenant-Id` :

| BFF route | Source file | NextAuth session | X-User-Email | X-Tenant-Id | Verdict pre-patch |
|---|---|---|---|---|---|
| /api/autopilot/settings GET/POST/PATCH | app/api/autopilot/settings/route.ts | `getServerSession(authOptions)` via helper `getAuthHeaders` | OUI (`session?.user?.email`) | OUI (`tenantId` query) | SAFE |
| /api/autopilot/draft GET | app/api/autopilot/draft/route.ts | OUI inline | OUI | OUI | SAFE |
| /api/autopilot/draft/consume POST | app/api/autopilot/draft/consume/route.ts | OUI inline | OUI | OUI | SAFE |
| /api/autopilot/history GET | app/api/autopilot/history/route.ts | OUI inline | OUI | OUI | SAFE |
| /api/autopilot/evaluate POST | app/api/autopilot/evaluate/route.ts | OUI inline | OUI | OUI | SAFE |

Les 5 BFF acceptent le pattern tenantGuard sans modification cote Client. **Aucun patch Client requis pour AS.12.2B**.

---

## 6. Design decision

Design : extension PROTECTED_ROUTES static (pattern KEY-301 AS.12.1B notifications LIST/SIMULATE).

| Endpoint | Method | Pattern propose | Justification |
|---|---|---|---|
| /autopilot/settings | GET | PROTECTED_ROUTES static | path exact, pas de dynamic |
| /autopilot/settings | POST | PROTECTED_ROUTES static | idem |
| /autopilot/settings | PATCH | PROTECTED_ROUTES static | idem |
| /autopilot/draft | GET | PROTECTED_ROUTES static | idem |
| /autopilot/draft/consume | POST | PROTECTED_ROUTES static | idem |
| /autopilot/history | GET | PROTECTED_ROUTES static | idem |
| /autopilot/evaluate | POST | PROTECTED_ROUTES static | idem |

Pas de matcher dynamique necessaire (aucun path param).

Order layering :
1. tenantGuard preHandler : X-User-Email present ? + user_tenants membership ?
2. Si pass : handler-level plan guard (PH132-C autopilot autonomous, PH130 AI mode change, PH137-D assist).

Apres AS.12.2B, le contournement de plan gating via crafted tenantId est ferme : l attaquant doit etre membre du tenant cible pour atteindre le plan check.

---

## 7. Patch summary

| Repo | HEAD avant | HEAD apres | Fichier |
|---|---|---|---|
| keybuzz-api | 5eadb345 | ffccbd188d003887e419fbb92497d952a3c290e1 | src/plugins/tenantGuard.ts (+22 lignes : 7 entries PROTECTED_ROUTES + 14 lignes docstring) |
| keybuzz-client | 094163b | identique | (zero patch Client, 5 BFF deja safe) |
| keybuzz-infra | 66bd71c | 3b42751 | k8s/keybuzz-api-dev/deployment.yaml (1 ligne image) |

Aucun changement aux helpers existants `extractTenantId` / `checkMembership` / matchers `/messages` ou `/notifications`. Reutilisation pure du mecanisme tenantGuard.

---

## 8. Build

| Item | Valeur |
|---|---|
| Source commit | ffccbd188d003887e419fbb92497d952a3c290e1 |
| Tag image | v3.5.179-autopilot-tenantguard-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | ffccbd188d003887e419fbb92497d952a3c290e1 (= source commit) |
| KEY-308 OCI created | 2026-05-12T13:38:32Z |
| KEY-308 OCI version | v3.5.179-autopilot-tenantguard-dev |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built b171befb448f |
| Digest GHCR | sha256:27b237dd83f7cb2bcea897efb13b123ec310cdbdd8a45943d249e85a4062164a |
| docker push | OK |
| Rollback tag | v3.5.178-notifications-tenantguard-dev |

Aucun build Client (zero patch Client requis).

---

## 9. GitOps deploy DEV

Commit infra `3b42751` :

```
deploy(dev): protect autopilot module via tenant guard (KEY-301 AS.12.2B)
```

Modifie 1 manifest :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.178 -> v3.5.179

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout OK
- Runtime DEV API : `v3.5.179-autopilot-tenantguard-dev` MATCH=YES
- /health DEV : `{"status":"ok",...}` 200

---

## 10. Validation negative (no-mutation, no PII)

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | GET /autopilot/settings no-auth | curl https public | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | GET /autopilot/draft no-auth | curl https public | 401 AUTH_REQUIRED | 401 | PASS |
| T3 | GET /autopilot/history no-auth | curl https public | 401 | 401 | PASS |
| T4 | POST /autopilot/settings no-auth | curl https public POST body `{}` | 401 | 401 | PASS |
| T5 | PATCH /autopilot/settings no-auth | curl https public PATCH | 401 | 401 | PASS |
| T6 | POST /autopilot/draft/consume no-auth | curl https public POST body fake ids | 401 | 401 | PASS |
| T7 | POST /autopilot/evaluate no-auth | curl https public POST body fake conv | 401 | 401 | PASS |
| T8 | GET /autopilot/draft bogus user (in-cluster) | kubectl exec curl x-user-email=bogus@example.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| T9 | GET /autopilot/draft ludo cross-tenant SWITAA (in-cluster) | kubectl exec curl x-user-email=ludo.gonthier@gmail.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |

9/9 PASS. Aucun POST positif vers `/autopilot/evaluate` (qui aurait consomme KBActions et genere du contenu IA). Aucun POST positif vers `/autopilot/draft/consume`.

Note importante : meme avec `x-user-email: switaa26@gmail.com` + tenantId=switaa-sasu-mnc1x4eq, je n ai PAS execute de test positif sur `/autopilot/evaluate` ni `/autopilot/draft/consume` -- la consigne "aucun POST/PATCH positif" + "aucune generation IA" + "aucune consommation KBActions" est strictement respectee.

---

## 11. DB no-mutation proof

| Mesure | PRE-test | POST-test (apres T1-T9) | Delta |
|---|---|---|---|
| `ai_action_log` count SWITAA total | 174 | 174 | 0 |
| `ai_action_log` count SWITAA autopilot_* | 87 | 87 | 0 |

Aucune nouvelle ligne `ai_action_log` inseree pendant les tests negatifs. Aucun draft consume / dismiss / evaluate effectif. Le tenantGuard preHandler rejette les requetes AVANT d atteindre `evaluateAndExecute()` ou les handlers UPDATE/INSERT.

---

## 12. Preserve checks

| # | Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | GET /messages/conversations no-auth | https://api-dev.keybuzz.io/messages/conversations?tenantId=fake | 401 (KEY-304) | 401 | PASS |
| P2 | GET /messages/conversations/:fake no-auth | idem detail | 401 | 401 | PASS |
| P3 | GET /tenants no-auth | https://api-dev.keybuzz.io/tenants | 401 (AS.12.1A) | 401 | PASS |
| P4 | GET /notifications no-auth | https://api-dev.keybuzz.io/notifications?tenantId=fake&limit=1 | 401 (AS.12.1B) | 401 | PASS |
| P5 | GET /notifications/:fake no-auth | idem detail | 401 (AS.12.1B) | 401 | PASS |

KEY-304, AS.12.1A, AS.12.1B integralement preserves.

---

## 13. Smoke V1 + logs

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Aucune nouvelle deterioration vs pre-deploy (les 2 WARN existaient deja post AS.12.1B : `/messages/conversations 401` et `/notifications 401`, comportements attendus). Le harness smoke n inclut pas de probe autopilot en V1.

| Source | Filtre | Count |
|---|---|---|
| API DEV 5min | statusCode 5xx ou level=50 | 0 |

---

## 14. QA Ludovic navigateur DEV

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth DEV | `switaa26@gmail.com` (SWITAA owner, plan AUTOPILOT) |
| Tenant courant | SWITAA |
| Inbox liste conversations visible | OUI |
| Conversation detail visible apres clic | OUI |
| Brouillon IA visible automatiquement sur conv eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Boutons "Modifier" / "Ignorer" visibles | OUI (NON cliques) |
| Autopilot settings UI charge | OUI |
| Autopilot history visible | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge KEY-263 (poll /api/notifications) | OUI |
| Banniere erreur visible | NON |
| Regression visible Inbox / channels / suppliers / catalogue | NON |
| 401 errors devtools sur appels Client autopilot legitimes | NON observe |

Le BFF Client `/api/autopilot/{draft,settings,history,draft/consume,evaluate}` injecte X-User-Email depuis NextAuth -> tenantGuard accepte les appels legitimes -> Brouillon IA continue de fonctionner sans regression.

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee. Aucun draftText publie.

---

## 15. Rollback plan (PRET, NON EXECUTE)

Si regression detectee :

```
cd /opt/keybuzz/keybuzz-infra
git revert 3b42751 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.178-notifications-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
```

Rollback rapide (< 2 minutes). PROD inchange (rien a rollback en PROD).

Triggers rollback :
- Brouillon IA disparait apres deploy (Inbox affiche conversations mais zone "Suggestion IA" vide)
- autopilot settings UI bloquee ou affiche `403`
- history vide pour SWITAA
- 401 errors devtools sur appels autopilot legitimes
- spike 5xx API DEV
- consommation anormale KBActions / wallet (signal de generation non-controlee)

---

## 16. PROD unchanged proof

| Namespace | Workload | Image runtime (avant + apres AS.12.2B) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.178-notifications-tenantguard-prod |
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

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 15 jeux de commentaires accumules.

### 17.1 KEY-301 commentaire (texte cible)

```
## AS.12.2B autopilot module hardened in DEV

Third sub-phase under KEY-301 after AS.12.1A (tenants) and AS.12.1B (notifications). The autopilot module is now covered by the same tenantGuard runtime mechanism that closed `/messages` (KEY-304), `/tenants`, and `/notifications`.

Endpoints now protected (DEV) -- 5 paths, 7 method-path tuples :
- GET   /autopilot/settings
- POST  /autopilot/settings
- PATCH /autopilot/settings
- GET   /autopilot/draft
- POST  /autopilot/draft/consume
- GET   /autopilot/history
- POST  /autopilot/evaluate

Validation negative 9/9 PASS : 7 no-auth 401, bogus user 403, cross-tenant 403. DB no-mutation proof : ai_action_log count for SWITAA remained unchanged (174 -> 174 total, 87 -> 87 autopilot rows) ; no draft consume / dismiss / evaluate triggered during tests ; no LLM cost incurred ; no KBActions consumed.

Preserve checks : KEY-304 messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications still return 401 unauthenticated.

Runtime DEV : API v3.5.179-autopilot-tenantguard-dev. GitOps MATCH=yes. Logs API DEV 5min : 0 5xx. Smoke V1 unchanged (PASS=16 WARN=2 FAIL=0 SKIP=1 ; the WARNs are previously documented and not autopilot-related).

Client DEV unchanged (no Client patch required). The 5 BFF routes (settings / draft / draft/consume / history / evaluate) already inject X-User-Email + X-Tenant-Id from the NextAuth session ; tenantGuard accepts these legitimate calls. Ludovic QA navigateur DEV with switaa26@gmail.com (SWITAA owner, AUTOPILOT plan) confirmed : Brouillon IA auto visible, "Valider et envoyer" present (not clicked), autopilot settings UI loads, history visible, no error banner, no regression.

Plan gating handler-level (STARTER / PRO / AUTOPILOT / ENTERPRISE) is now protected from cross-tenant bypass : the tenantGuard membership check happens before the plan check.

PROD strictly unchanged (8 services on AS.12.1B-PROD baseline).

Remaining sub-phases from AS.12.2A audit : AS.12.2D AI settings + wallet (requires BFF fix prior), AS.12.2C AI assist/evaluate/execute mutations (requires new BFF + Client refactor), AS.12.2E AI ops + returns + journal + context, AS.12.2F intelligence + monitoring reads. Recommended next : either AS.12.2B-PROD promotion, or AS.12.2D depending on Ludovic priority.

KEY-301 stays Open. NOT marked Done in this phase.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 18. Compliance AS.12.2B

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API ffccbd18 + infra 3b42751) | OK |
| Build-from-Git | OK |
| Tag immuable | OK |
| API-only (aucun build Client) | OK |
| KEY-308 OCI labels non "unknown" | OK |
| KEY-309 pre-push check AVAILABLE | OK |
| Digest documente | OK (sha256:27b237dd83f7...) |
| Rollback plan documente | OK section 15 |
| GitOps strict | OK |
| No kubectl set / patch / edit | OK |
| Aucun deploy hors API DEV | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB (ai_action_log delta 0) | OK |
| Aucun POST / PATCH positif sur target reel | OK |
| Aucune generation IA volontaire | OK |
| Aucune consommation KBActions | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 statut Done NON applique | OK |
| Smoke V1 DEV pre + post deploy stable | OK (no nouvelle deterioration) |
| QA Ludovic navigateur DEV OK | OK (Brouillon IA fonctionnel) |
| Plan gating preserve PH130 PH132-C PH137-D | OK (handler-level inchange) |

---

## 19. Phrase cible finale

AS.12.2B livre : module `/autopilot` 5 paths / 7 routes (settings GET/POST/PATCH + draft GET + draft/consume POST + history GET + evaluate POST) protege par tenantGuard runtime en DEV via 7 entries PROTECTED_ROUTES static ; tests negatifs 9/9 PASS (7 no-auth 401 + bogus 403 + ludo cross-tenant SWITAA 403) ; DB no-mutation prouvee : ai_action_log SWITAA 174 -> 174 total, autopilot_* 87 -> 87 delta 0 ; aucun POST positif emis vers /evaluate ou /draft/consume, aucune generation IA, aucune consommation KBActions ; preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications 401 ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK avec switaa26@gmail.com (SWITAA AUTOPILOT) : Brouillon IA auto visible + bouton Valider et envoyer present + autopilot settings UI charge + history visible + Inbox + tenant switcher + escalation badge fonctionnels + aucune banniere ; runtime DEV API v3.5.179-autopilot-tenantguard-dev (commit ffccbd18, digest sha256:27b237dd83f7...) MATCH=yes GitOps ; aucun build Client (5 BFF deja safe X-User-Email injecte) ; PROD strictement inchange (8 services) ; aucune PII / draftText publie ; aucun ticket Linear cree ; KEY-301 reste Open epic ; verdict AS.12.2B GO AUTOPILOT TENANTGUARD DEV READY.

STOP
