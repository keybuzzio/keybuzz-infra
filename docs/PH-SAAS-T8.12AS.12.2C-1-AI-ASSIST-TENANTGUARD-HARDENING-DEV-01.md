# PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-1 -- AI assist (LLM mutation) tenantGuard hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO AI ASSIST TENANTGUARD DEV READY

L endpoint `POST /ai/assist` (LLM-cost, KBActions-consuming) est desormais couvert par tenantGuard runtime en DEV. Patch minimal : 1 entry PROTECTED_ROUTES static. Aucun patch Client requis -- le BFF `/api/ai/assist` etait deja safe (NextAuth session check + 401 si pas de session + injection X-User-Email + X-Tenant-Id, audite AS.12.2A et reconfirme E0).

Validation 4/4 negatifs PASS : no-auth 401, bogus user 403, ludo cross-tenant SWITAA 403, missing tenantId 400. DB no-mutation prouvee : `ai_action_log` SWITAA reste 176 (delta 0). Aucun POST positif emis vers /ai/assist : aucune generation LLM declenchee, aucune consommation KBActions, aucun wallet debit.

Preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet (toutes 401 no-auth). Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable. Logs API DEV 0 5xx. PROD strictement inchange 8 services.

QA Ludovic navigateur DEV CRITIQUE confirmee avec switaa26@gmail.com (SWITAA AUTOPILOT) : Brouillon IA auto visible + AISuggestionSlideOver charge correctement (appel `assistAI` via BFF /api/ai/assist passe par tenantGuard membership check sans rejet) + qualite reponse inchangee visuellement + AIDecisionPanel charge + Inbox + tenant switcher fonctionnels, aucune banniere erreur, aucune regression.

Plan gating handler-level PH137-D (PRO+ requis) est desormais protege par tenantGuard membership en amont : crafted tenantId cross-tenant pour exploiter LLM tier est ferme.

KEY-301 reste Open epic. AS.12.2C-2 (/ai/guard/check), AS.12.2C-3 (/ai/evaluate), AS.12.2C-4 (/ai/execute), AS.12.2C-5 (/ai/rules) restent a livrer.

---

## 2. Scope

Inclus :
- API tenantGuard : ajout 1 entry PROTECTED_ROUTES static `POST /ai/assist`.
- GitOps DEV API uniquement.
- Validation negative + DB no-mutation.
- QA Ludovic navigateur DEV pour Brouillon IA (risque UX critique).
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Client (BFF /api/ai/assist deja safe -- aucun patch necessaire).
- /ai/evaluate, /ai/execute, /ai/guard/check, /ai/rules (sous-phases AS.12.2C-2 -> AS.12.2C-5).
- /ai/global/settings, /ai/credits/add, /ai/wallet/dev/* (defer AS.12.2D maintenu).
- POST positif sur /ai/assist (interdit : aurait declenche generation LLM + consommation KBActions).
- Generation IA artificielle de test.
- Consommation KBActions / wallet / credits artificielle.
- Mutation DB de test.
- PROD deploy.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit + decoupage 5 sous-phases.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md` -- baseline runtime.
- Rapports Brouillon IA AS.11.0.5 + AS.11.0.6 -- baseline UX critique.
- `keybuzz-api/src/modules/ai/ai-assist-routes.ts` (POST /assist + plan guard PH137-D).
- `keybuzz-api/src/plugins/tenantGuard.ts` (pre-patch).
- `keybuzz-client/app/api/ai/assist/route.ts` (BFF safe reconfirme).
- `keybuzz-client/src/services/ai.service.ts` `assistAI` (utilise deja path relatif `/api/ai/assist`).
- Consumers Client : `AISuggestionSlideOver.tsx`, `AIDecisionPanel.tsx`.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / e7ad363f (avant patch) / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / a46eb5f / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 2f1608d (avant patch) / 0-0 | identique | OK |
| Runtime DEV API pre | v3.5.180-ai-settings-wallet-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.192-ai-settings-wallet-bff-dev | identique | OK |
| Runtime PROD API | v3.5.180-ai-settings-wallet-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.192-ai-settings-wallet-bff-prod | identique | OK |
| KEY-309 tag avail API DEV | v3.5.181-ai-assist-tenantguard-dev AVAILABLE | AVAILABLE | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. BFF Client verification (pre-patch)

Verification reconfirmee du BFF `/api/ai/assist` (audit AS.12.2A + AS.12.2C deja confirmes) :

```typescript
export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const userEmail = session.user.email;
    const body = await request.json().catch(() => ({}));
    const tenantId = request.headers.get('X-Tenant-Id') || body.tenantId || '';

    if (!tenantId) {
      return NextResponse.json({ error: 'tenantId required' }, { status: 400 });
    }

    const response = await fetch(`${API_URL}/ai/assist`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': userEmail,
        'X-Tenant-Id': tenantId,
        ...
      },
      ...
    });
    ...
```

Le BFF :
- Requiert une session NextAuth (401 NO_SESSION sinon).
- Injecte `X-User-Email` depuis `session.user.email`.
- Injecte `X-Tenant-Id` depuis header ou body.
- Forward le body raw.

**Aucun patch Client requis pour AS.12.2C-1**. Le flux legitime AISuggestionSlideOver / AIDecisionPanel passe par ce BFF et continuera de fonctionner apres activation tenantGuard.

---

## 6. Design decision

Pattern : PROTECTED_ROUTES static (1 entry, path exact, no dynamic segment). Identique a AS.12.2B (autopilot) et AS.12.2D (settings + wallet).

| Aspect | Decision |
|---|---|
| Method | POST |
| Path | `/ai/assist` (exact) |
| Pattern | PROTECTED_ROUTES static entry |
| tenantId source | body (extractTenantId helper supporte deja le body) |
| Auth check | X-User-Email require + user_tenants membership |
| Status no-auth | 401 AUTH_REQUIRED |
| Status bogus user | 403 NOT_MEMBER |
| Status cross-tenant | 403 NOT_MEMBER |
| Status missing tenantId | 400 TENANT_ID_MISSING |
| Status user legitime | 200 -> handler plan gating PH137-D -> LLM call si PRO+ |
| Impact Client | ZERO (BFF /api/ai/assist deja safe) |

---

## 7. Patch summary

| Repo | HEAD avant | HEAD apres | Fichier |
|---|---|---|---|
| keybuzz-api | e7ad363f | 28a31d962f05e647a004211a5bdc1e27fdea7a2e | src/plugins/tenantGuard.ts (+14 lignes : 1 PROTECTED_ROUTES entry + 13 lignes docstring) |
| keybuzz-client | a46eb5f | identique | (zero patch Client) |
| keybuzz-infra | 2f1608d | 1832f10 | k8s/keybuzz-api-dev/deployment.yaml (1 ligne image) |

Diff resume tenantGuard.ts :
- Header docstring : ajout section AS.12.2C-1 (1 endpoint + justification BFF safe).
- PROTECTED_ROUTES : +1 entry `{ method: 'POST', path: '/ai/assist' }`.

Aucun nouveau matcher dynamique necessaire (path exact). Aucun changement aux helpers `extractTenantId` / `checkMembership` ni aux entries precedentes.

---

## 8. Build

| Item | Valeur |
|---|---|
| Source commit | 28a31d962f05e647a004211a5bdc1e27fdea7a2e |
| Tag image | v3.5.181-ai-assist-tenantguard-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 28a31d962f05e647a004211a5bdc1e27fdea7a2e |
| KEY-308 OCI created | 2026-05-12T15:33:49Z |
| KEY-308 OCI version | v3.5.181-ai-assist-tenantguard-dev |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built 03c6f9c1cf64 |
| Digest GHCR | sha256:a5eba88167dbb5d650c20f5b52f193a27c10a44d90d7b1fbe0af8faa5b0627c8 |
| Rollback tag | v3.5.180-ai-settings-wallet-tenantguard-dev |

Aucun build Client (zero patch Client requis).

---

## 9. GitOps deploy DEV

Commit infra `1832f10` :

```
deploy(dev): protect /ai/assist via tenant guard (KEY-301 AS.12.2C-1)
```

Modifie 1 manifest :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.180 -> v3.5.181

Apply :
- `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout OK
- Runtime DEV API : `v3.5.181-ai-assist-tenantguard-dev` MATCH=YES
- /health DEV : 200 ok

---

## 10. Validation negative (no-mutation, no LLM)

Tests negatifs uniquement. Aucun body valide envoye -- pas de generation LLM, pas de KBActions, pas de mutation ai_action_log.

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | POST /ai/assist no-auth (external) | curl https public POST `{"tenantId":"fake-tenant"}` | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | POST /ai/assist bogus user (in-cluster) | curl x-user-email=bogus@example.com body `{"tenantId":"switaa-sasu-mnc1x4eq"}` | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| T3 | POST /ai/assist ludo cross-tenant SWITAA (in-cluster) | curl x-user-email=ludo.gonthier@gmail.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |
| T4 | POST /ai/assist no tenantId valid email (in-cluster) | curl x-user-email=switaa26@gmail.com body `{}` | 400 TENANT_ID_MISSING | 400 `{"error":"tenantId is required","code":"TENANT_ID_MISSING"}` | PASS |

4/4 PASS. Aucun POST positif avec `contextType` + `conversationId` envoye -- la generation LLM ne peut donc PAS avoir ete declenchee meme si un test passait jusqu au handler. Le rejet en preHandler (T1-T3) ou avant plan check (T4) est anterieur a l atteinte du handler `assist`.

---

## 11. DB no-mutation proof

| Mesure | PRE-test | POST-test | Delta |
|---|---|---|---|
| `ai_action_log` count SWITAA | 176 | 176 | 0 |

Aucune nouvelle ligne `ai_action_log` inseree pendant les tests negatifs. Aucun assist execute (qui aurait insere status='completed' apres LLM response). Le tenantGuard preHandler rejette les requetes AVANT atteinte du handler INSERT.

Aucun debit wallet / credits / KBActions effectue (impossible sans atteinte du handler LLM).

---

## 12. Preserve checks

| # | Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | GET /messages/conversations no-auth | https://api-dev.keybuzz.io/messages/conversations?tenantId=fake | 401 (KEY-304) | 401 | PASS |
| P2 | GET /tenants no-auth | https://api-dev.keybuzz.io/tenants | 401 (AS.12.1A) | 401 | PASS |
| P3 | GET /notifications no-auth | https://api-dev.keybuzz.io/notifications?tenantId=fake | 401 (AS.12.1B) | 401 | PASS |
| P4 | GET /autopilot/draft no-auth | https://api-dev.keybuzz.io/autopilot/draft?tenantId=fake&conversationId=fake | 401 (AS.12.2B) | 401 | PASS |
| P5 | GET /ai/settings no-auth | https://api-dev.keybuzz.io/ai/settings?tenantId=fake | 401 (AS.12.2D) | 401 | PASS |
| P6 | GET /ai/wallet/status no-auth | https://api-dev.keybuzz.io/ai/wallet/status?tenantId=fake | 401 (AS.12.2D) | 401 | PASS |

KEY-304, AS.12.1A, AS.12.1B, AS.12.2B, AS.12.2D integralement preserves.

---

## 13. Smoke V1 + logs

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Aucune nouvelle deterioration vs pre-deploy (les 2 WARN sont sur `/messages/conversations 401` et `/notifications 401`, comportements attendus deja documentes). Le smoke V1 ne probe pas `/ai/assist` -- pas d evolution sur ce scope.

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
| Conversation detail visible | OUI |
| Brouillon IA visible automatiquement (depend de assistAI via BFF) | OUI |
| AISuggestionSlideOver charge correctement | OUI |
| AIDecisionPanel charge (consomme assist) | OUI |
| Qualite reponse Brouillon IA visuellement | inchangee |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| AIModeSwitch + wallet display (AS.12.2D) | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge KEY-263 | OUI |
| Banniere erreur visible | NON |
| 401 errors devtools sur appels Client legitimes (/api/ai/assist) | NON observe |
| Regression visible | NON |

Le BFF Client `/api/ai/assist` injecte X-User-Email + X-Tenant-Id depuis NextAuth -> tenantGuard accepte les appels legitimes -> Brouillon IA + AISuggestionSlideOver + AIDecisionPanel continuent de fonctionner. La qualite de reponse est preservee : le handler `assist` n est pas modifie, le tenantGuard ne fait que valider l acces en preHandler.

Aucune donnee client copiee. Aucun draftText publie. Aucune capture ecran PII committee.

---

## 15. Rollback plan (PRET, NON EXECUTE)

Si regression detectee :

```
cd /opt/keybuzz/keybuzz-infra
git revert 1832f10 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.180-ai-settings-wallet-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
```

Rollback rapide (< 2 minutes). PROD inchange (rien a rollback en PROD).

Triggers rollback :
- Brouillon IA disparait apres deploy
- AISuggestionSlideOver ne charge plus
- AIDecisionPanel KO
- 401 errors devtools sur `/api/ai/assist` legitime
- spike 5xx API DEV
- consommation anormale KBActions

---

## 16. PROD unchanged proof

| Namespace | Workload | Image runtime (avant + apres AS.12.2C-1) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.180-ai-settings-wallet-tenantguard-prod |
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.192-ai-settings-wallet-bff-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `*-prod`.

---

## 17. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 20 jeux de commentaires accumules.

### 17.1 KEY-301 commentaire (texte cible)

```
## AS.12.2C-1 AI assist (LLM mutation) hardened in DEV

First of 5 LLM-mutation sub-phases under KEY-301 (after AS.12.2C audit). The /ai/assist endpoint (LLM-cost + KBActions-consuming) is now covered by tenantGuard runtime in DEV with the simplest possible scope :
- 1 PROTECTED_ROUTES static entry POST /ai/assist.
- Zero Client patch required : the BFF /api/ai/assist already requires a NextAuth server session and injects X-User-Email + X-Tenant-Id.

Validation negative 4/4 PASS : no-auth 401, bogus user 403, cross-tenant 403, missing tenantId 400. DB no-mutation proof : ai_action_log count for SWITAA remained unchanged (176 -> 176). No positive POST issued -- no LLM generation triggered, no KBActions consumed, no wallet debit.

Preserve checks : KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet all still 401 unauthenticated.

Runtime DEV : API v3.5.181-ai-assist-tenantguard-dev. GitOps MATCH=yes. Logs API DEV 5min : 0 5xx. Smoke V1 stable.

Plan gating handler-level PH137-D (PRO+ requirement for AI suggestions) is now bound to the calling user's actual tenant membership : crafted tenantId attempts to exploit a tier's LLM access are rejected at preHandler.

Ludovic QA navigateur DEV with switaa26@gmail.com (SWITAA AUTOPILOT) confirmed : Brouillon IA auto visible, AISuggestionSlideOver loads, AIDecisionPanel loads, response quality visually unchanged, no error banner, no regression.

PROD strictly unchanged (8 services).

Remaining LLM-mutation sub-phases pending : AS.12.2C-2 guard/check (P1 read-only), AS.12.2C-3 evaluate (P0 mutation log), AS.12.2C-4 execute (P0 critical downstream side effects), AS.12.2C-5 rules (P1 admin). All 4 require Client BFF + service migration before tenantGuard activation.

KEY-301 stays Open. NOT marked Done.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 18. Compliance AS.12.2C-1

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API 28a31d96 + infra 1832f10) | OK |
| Build-from-Git | OK |
| Tag immuable | OK |
| API-only (aucun build Client) | OK |
| KEY-308 OCI labels non "unknown" | OK |
| KEY-309 pre-push check AVAILABLE | OK |
| Digest documente | OK (sha256:a5eba881...) |
| Rollback plan documente | OK section 15 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit | OK |
| Aucun deploy hors API DEV | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB (ai_action_log delta 0) | OK |
| Aucun POST positif sur /ai/assist | OK |
| Aucune generation LLM volontaire | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 statut Done NON applique | OK |
| Smoke V1 DEV pre + post deploy stable | OK |
| QA Ludovic navigateur DEV OK (Brouillon IA fonctionnel) | OK |
| Plan gating PH137-D preserve handler-level | OK |
| 4 sous-phases restantes (AS.12.2C-2..5) inchangees | OK |

---

## 19. Phrase cible finale

AS.12.2C-1 livre : endpoint `POST /ai/assist` (LLM-cost, KBActions-consuming) protege par tenantGuard runtime en DEV via 1 entry PROTECTED_ROUTES static ; tests negatifs 4/4 PASS (no-auth 401, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400) ; DB no-mutation prouvee : ai_action_log SWITAA 176 -> 176 delta 0, aucune ligne assist 'completed' inseree ; aucun POST positif emis, aucune generation LLM, aucune consommation KBActions, aucun wallet debit ; preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet 401 ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK avec switaa26@gmail.com (SWITAA AUTOPILOT) : Brouillon IA auto visible + AISuggestionSlideOver charge + AIDecisionPanel charge + qualite reponse inchangee visuellement + Inbox + tenant switcher + escalation badge fonctionnels, aucune banniere, aucune regression ; runtime DEV API v3.5.181-ai-assist-tenantguard-dev (commit 28a31d96, digest sha256:a5eba88167dbb5d650c20f5b52f193a27c10a44d90d7b1fbe0af8faa5b0627c8) MATCH=yes GitOps ; aucun build Client (BFF /api/ai/assist deja safe NextAuth + X-User-Email) ; PROD strictement inchange 8 services ; plan gating handler-level PH137-D PRO+ desormais protege par tenantGuard membership en amont (plan bypass cross-tenant ferme) ; aucune mutation DB, aucune PII publiee, aucun draftText, aucun secret, aucun ticket Linear cree ; KEY-301 reste Open epic ; AS.12.2C-2..5 (guard/check, evaluate, execute, rules) restent a livrer ; verdict AS.12.2C-1 GO AI ASSIST TENANTGUARD DEV READY.

STOP
