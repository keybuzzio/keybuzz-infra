# PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-5 -- design audit /ai/rules + /playbooks (NO PATCH, NO BUILD, NO DEPLOY)
> Environnement : DEV + PROD read-only

---

## 1. VERDICT

GO AI RULES DESIGN READY -- avec **decoupage obligatoire AS.12.2C-5A (READ) puis AS.12.2C-5B (MUTATIONS)** et **scope elargi a `/playbooks`** decouvert pendant l audit.

Constat principal : la surface "rules" de KeyBuzz est expose en **deux endroits** sur l API :

1. `/ai/rules` (mount `/ai`, fichier `src/modules/ai/routes.ts`) : 2 endpoints seulement (GET list + POST create simple, sans conditions ni actions detaillees).
2. `/playbooks` (mount `/playbooks`, fichier `src/modules/playbooks/routes.ts`) : **9 endpoints CRUD complets sur la meme table `ai_rules`** + tables `ai_rule_conditions` + `ai_rule_actions` + `playbook_suggestions`. Cette surface est non protege par tenantGuard et est la **vraie surface CRUD ai_rules**.

Le prompt initial cible `/ai/rules`. Restreindre AS.12.2C-5 a `/ai/rules` strict laisserait `/playbooks` (CRUD complet) non protege. La sortie de cette phase doit explicitement faire le choix produit : ouvrir la phase a `/playbooks` aussi, ou garder un scope strict /ai/rules et creer une phase sub-securite separee pour `/playbooks` (recommandation : integrer dans AS.12.2C-5 etendu).

Aucun adminGuard plugin existe dans l API. Aucune route rules / playbooks n applique `requirePlan` ou role-based access. Tout est tenant-scoped via `tenantId` body/query/header (extrait par `tenantGuard.extractTenantId` deja en place). L application correcte de tenantGuard sur `/ai/rules` ET `/playbooks` est suffisante.

Client : aucun caller actif `/ai/rules` (ni ai.service.ts ni BFF). `/playbooks` est consomme activement via le hook `usePlaybooks` + 4 pages UI (`/playbooks`, `/playbooks/new`, `/playbooks/[id]`, `/playbooks/[id]/tester`). Patch `/playbooks` porte donc un risque UX reel.

BFF Client `/api/playbooks/*` (7 routes) deja safe (NextAuth session + X-User-Email). BFF `/api/ai/rules` absent (a creer si patch /ai/rules).

Validation 100% en negatifs (401 / 400 / 403 cross-tenant) possible **sans aucune mutation** ni creation/suppression de regle de test, grace au pattern preserve verifie sur AS.12.2C-1/2/3/4.

KEY-301 reste Open epic. Le verdict cloture la phase AUDIT ; les phases IMPLEMENT (5A + 5B) restent a livrer apres GO Ludovic.

---

## 2. Scope

Inclus (audit / design only) :
- Lecture sources API `/ai/rules` + `/playbooks` + Client `usePlaybooks` + BFF `/api/playbooks` + Admin v2 `AiRuleCard` chain.
- Mapping endpoints + DB tables touchees + dependances downstream.
- Identification cross-tenant risk surface.
- Decoupage propose 5A (READ) / 5B (MUTATIONS).
- Conception patch futur (NON applique) + plan validation negative + plan rollback.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Aucun patch source.
- Aucun build.
- Aucun deploy.
- Aucun POST / PATCH / DELETE / PUT positif.
- Aucune creation / modification / suppression de regle.
- Aucune mutation DB.
- Aucun draftText publie / aucune PII.
- PROD strictement read-only.
- Resolution du gap produit GP1 (KEY-312, tracke separement).
- Plan gating sur /ai/execute (gap operationnel separe).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-*-*.md` (1, 2, 3, 3.1, 4 DEV+PROD).
- `keybuzz-api/src/modules/ai/routes.ts` (handlers /rules lignes 233-289).
- `keybuzz-api/src/modules/playbooks/routes.ts` (9 endpoints CRUD ai_rules, 306 lignes).
- `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES + extractTenantId + checkMembership).
- `keybuzz-api/src/app.ts` (mounts `/ai` et `/playbooks`).
- `keybuzz-api/src/services/playbook-engine.service.ts` (services internes).
- `keybuzz-api/src/services/playbook-seed.service.ts` (seed starter rules).
- `keybuzz-api/src/modules/ai/ai-assist-routes.ts` (consume ai_rules read-only en SQL).
- `keybuzz-client/src/hooks/usePlaybooks.ts` (8 fetch sites BFF).
- `keybuzz-client/app/api/playbooks/*` (7 fichiers BFF).
- `keybuzz-client/src/services/ai.service.ts` (aucune fonction rules ; `rules_evaluated` champ response uniquement).
- `keybuzz-client/app/api/channel-rules/[channel]/route.ts` (proxy `/attachments/channel-rules/` -- hors scope rules ai).
- `keybuzz-admin/src/features/ai/components/AiRuleCard.tsx` + `AiAutomationList.tsx` (mock pur, hors runtime).
- `keybuzz-admin/app/(admin)/ai/page.tsx` (utilise `AI_AUTOMATION_RULES_MOCK` constante).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-api HEAD / branche / sync | d7f2a8fd / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-client HEAD / branche / sync | 14a4ea66 / ph148/onboarding-activation-replay / 0-0 | OK |
| keybuzz-infra HEAD / sync | 348489e (post KEY-312 link) / 0-0 / 0 dirty | OK |
| Runtime DEV API | v3.5.184-ai-execute-tenantguard-dev | OK baseline AS.12.2C-4 |
| Runtime DEV Client | v3.5.195-ai-execute-bff-dev | OK baseline AS.12.2C-4 |
| Runtime PROD API | v3.5.184-ai-execute-tenantguard-prod | OK baseline AS.12.2C-4-PROD |
| Runtime PROD Client | v3.5.195-ai-execute-bff-prod | OK baseline AS.12.2C-4-PROD |
| Smoke V1 DEV | scripts/smoke-v1.sh absent du bastion | NOTE saute (non bloquant pour design audit) |
| Read-only PROD respecte | aucun curl POSITIF, aucun docker, aucun kubectl mutation | OK |

---

## 5. Audit detaille

### 5.1 Endpoint inventory (rules surface API)

| # | Method | Path | Mount | Source file | Side effects |
|---|---|---|---|---|---|
| R1 | GET | `/ai/rules` | `/ai` | `src/modules/ai/routes.ts:233` | SELECT ai_rules + JOIN ai_rule_conditions + JOIN ai_rule_actions |
| R2 | POST | `/ai/rules` | `/ai` | `src/modules/ai/routes.ts:251` | INSERT ai_rules + INSERT ai_rule_conditions + INSERT ai_rule_actions |
| P1 | GET | `/playbooks` | `/playbooks` | `src/modules/playbooks/routes.ts:13` | SELECT ai_rules + JOIN ai_rule_conditions + JOIN ai_rule_actions |
| P2 | GET | `/playbooks/:id` | `/playbooks` | `routes.ts:45` | SELECT ai_rules + conditions + actions par id |
| P3 | POST | `/playbooks` | `/playbooks` | `routes.ts:61` | INSERT ai_rules (12 colonnes) + INSERT conditions + INSERT actions (transactionnel) |
| P4 | PUT | `/playbooks/:id` | `/playbooks` | `routes.ts:116` | UPDATE ai_rules + DELETE/INSERT conditions + DELETE/INSERT actions (replace) |
| P5 | DELETE | `/playbooks/:id` | `/playbooks` | `routes.ts:179` | DELETE ai_rules + DELETE conditions + DELETE actions (cascade) |
| P6 | PATCH | `/playbooks/:id/toggle` | `/playbooks` | `routes.ts:206` | UPDATE ai_rules SET status CASE active <-> disabled |
| P7 | GET | `/playbooks/suggestions` | `/playbooks` | `routes.ts:224` | SELECT playbook_suggestions JOIN ai_rules |
| P8 | PATCH | `/playbooks/suggestions/:id/apply` | `/playbooks` | `routes.ts:259` | UPDATE playbook_suggestions + apply -> ai_rules |
| P9 | PATCH | `/playbooks/suggestions/:id/dismiss` | `/playbooks` | `routes.ts:284` | UPDATE playbook_suggestions SET dismissed |

**Total : 11 method-path tuples a proteger.**

Endpoint **non present** cote API mais reference cote BFF Client :
- `app/api/playbooks/[id]/simulate/route.ts` (BFF POST) -- pas de handler API `POST /playbooks/:id/simulate` correspondant (a verifier en runtime, le BFF forward peut tomber sur 404 ou autre surface non identifiee).
- `app/api/playbooks/[id]/suggestions/route.ts` (BFF GET + PATCH) -- l API a `/playbooks/suggestions` (sans :id prefix) mais pas `/playbooks/:id/suggestions`. **Gap a clarifier.**

### 5.2 DB tables touchees

| Table | Operations rules surface | Cross-tenant risk sans patch |
|---|---|---|
| `ai_rules` | SELECT / INSERT / UPDATE / DELETE | **HIGH** : creation/modification/suppression de regles d un autre tenant -> impact direct sur evaluation IA, escalations, replies automatises |
| `ai_rule_conditions` | SELECT / INSERT / DELETE | HIGH : conditions de declenchement compromises |
| `ai_rule_actions` | SELECT / INSERT / DELETE | HIGH : actions executees compromises (incluant send reply, escalate, tag_conversation) |
| `playbook_suggestions` | SELECT / UPDATE | MEDIUM : application de suggestions sur regles d un autre tenant |

L impact downstream est **plus grave** que /ai/execute (audit log) : un attaquant qui obtiendrait /playbooks cross-tenant peut :
1. Creer une regle `autopilot_reply` sur un tenant cible avec action `send_reply` contenant un draft choisi par l attaquant -> tenant cible enverra ce reply automatiquement aux clients ;
2. Activer une regle pre-existante via PATCH /toggle -> emballer l autopilot ;
3. Modifier les conditions/actions d une regle existante -> redirection du flux IA ;
4. Supprimer une regle critique -> degradation service SAV.

C est la **surface la plus critique** de tout le scope KEY-301 jusqu a present.

### 5.3 tenant-scoped vs admin-only

| Endpoint | Source de `tenantId` | Admin check |
|---|---|---|
| GET /ai/rules | query | NON (aucun) |
| POST /ai/rules | query | NON |
| GET /playbooks | query | NON |
| GET /playbooks/:id | query | NON |
| POST /playbooks | body | NON |
| PUT /playbooks/:id | body | NON |
| DELETE /playbooks/:id | query | NON |
| PATCH /playbooks/:id/toggle | body | NON |
| GET /playbooks/suggestions | query (verifier) | NON |
| PATCH /playbooks/suggestions/:id/apply | body (verifier) | NON |
| PATCH /playbooks/suggestions/:id/dismiss | body (verifier) | NON |

Aucun adminGuard plugin existe (`grep` retourne aucun fichier). Aucun `requirePlan` / `requireAdmin` n est applique. La protection est purement **tenant-scoped** via membership user_tenants. C est la **politique correcte** : rules sont configurees par tenant pour son propre flux IA, pas un usage admin global.

### 5.4 Client BFF coverage

| BFF Client (app/api) | Methods | Pattern auth | Status |
|---|---|---|---|
| `/api/playbooks/route.ts` | GET + POST | NextAuth + X-User-Email | OK safe (mais X-Tenant-Id pas en header -- query suffit pour extractTenantId) |
| `/api/playbooks/[id]/route.ts` | GET + PUT + DELETE | idem | OK safe |
| `/api/playbooks/[id]/toggle/route.ts` | PATCH | idem | OK safe |
| `/api/playbooks/[id]/simulate/route.ts` | POST | idem | OK safe ; route API correspondante a clarifier |
| `/api/playbooks/[id]/suggestions/route.ts` | GET + PATCH | idem | OK safe ; route API correspondante a clarifier |
| `/api/playbooks/suggestions/route.ts` | GET | idem | OK safe |
| `/api/playbooks/suggestions/[id]/[action]/route.ts` | PATCH | idem | OK safe |
| `/api/ai/rules` | -- | **ABSENT** | A creer dans 5A si /ai/rules patche |

Le BFF Client passe l email session via header `X-User-Email` mais le tenantId en query string (`?tenantId=...`). C est suffisant pour `extractTenantId` qui consulte query > header > body dans cet ordre. Aucun changement BFF requis pour `/playbooks` lors du patch tenantGuard ; juste verifier que `X-User-Email` est bien injecte sur **tous** les 7 fichiers BFF.

### 5.5 Client UI consumers (pages actives runtime)

| Page | Hook | Calls BFF |
|---|---|---|
| `app/playbooks/page.tsx` | `usePlaybooks` | GET /api/playbooks |
| `app/playbooks/new/page.tsx` | `usePlaybooks.createPlaybook` | POST /api/playbooks |
| `app/playbooks/[playbookId]/page.tsx` | `usePlaybooks` (getById, update, delete, toggle, create) | GET / PUT / DELETE / PATCH (toggle) |
| `app/playbooks/[playbookId]/tester/page.tsx` | `usePlaybooks.getPlaybookById` + `togglePlaybook` | GET + PATCH toggle |

**4 pages UI actives runtime** consomment `/playbooks`. Contrairement a AIDecisionPanel (AS.12.2C-4, orphelin), patch `/playbooks` porte un risque UX reel.

### 5.6 Admin v2 chain

| Fichier | Status |
|---|---|
| `app/(admin)/ai/page.tsx` | utilise `AI_AUTOMATION_RULES_MOCK` constante -- aucun fetch API |
| `src/features/ai/components/AiAutomationList.tsx` | consume `AiRuleCard` |
| `src/features/ai/components/AiRuleCard.tsx` | composant mock-driven |

Admin v2 actuel est en **maquette pure** sur la surface rules. Aucun appel API runtime. Hors runtime concern pour cette phase. Si admin v2 connecte un jour les rules API, la protection tenantGuard / future adminGuard sera necessaire.

### 5.7 Mecanisme tenantGuard actuel (rappel)

`extractTenantId(request)` :
1. `request.query.tenantId`
2. `request.headers['x-tenant-id']`
3. `request.body.tenantId`

Retour `null` si introuvable -> reply 400 `TENANT_ID_MISSING`.

`request.headers['x-user-email']` requis -> reply 401 `AUTH_REQUIRED` sinon.

`checkMembership(email, tenantId)` :
```
SELECT 1 FROM user_tenants ut
JOIN users u ON u.id = ut.user_id
WHERE u.email = $1 AND ut.tenant_id = $2
LIMIT 1
```
Cache 30s. Reply 403 si non membre.

Le pattern est **prouve par AS.11.1A, AS.12.1A, AS.12.1B, AS.12.2B, AS.12.2C-1/2/3/4, AS.12.2D**.

---

## 6. Reponses aux questions obligatoires

### 6.1 /ai/rules doit-il etre tenantGuard, adminGuard, ou les deux ?

**tenantGuard suffit**. La policy de KeyBuzz pour les rules est par-tenant (chaque tenant configure son flux IA propre), pas admin global. Aucun adminGuard plugin existe (et son introduction serait hors scope KEY-301). Si une future surface admin global de rules est ajoutee, elle aura besoin d adminGuard, mais le scope actuel reste tenantGuard.

### 6.2 Y a-t-il un BFF existant ?

| Surface | BFF Client | Status |
|---|---|---|
| `/ai/rules` | `app/api/ai/rules/*` | **ABSENT** -- a creer (pattern AS.12.2C-3 /api/ai/evaluate / AS.12.2C-4 /api/ai/execute) |
| `/playbooks` | `app/api/playbooks/*` | **PRESENT et safe** (7 fichiers, NextAuth + X-User-Email injection) |

Donc :
- Pour patcher `/ai/rules` cote tenantGuard, il faut **creer** un BFF `/api/ai/rules` (GET + POST) -- 2 endpoints.
- Pour patcher `/playbooks` cote tenantGuard, **rien a faire cote BFF** (deja safe).

### 6.3 Quels tests negatifs sont possibles sans mutation ?

| # | Endpoint | Method | Test no-auth | Mutation |
|---|---|---|---|---|
| N1 | /ai/rules | GET | 401 | NON |
| N2 | /ai/rules | POST | 401 | NON (preHandler rejette avant handler) |
| N3 | /playbooks | GET | 401 | NON |
| N4 | /playbooks/:id | GET | 401 | NON |
| N5 | /playbooks | POST | 401 | NON |
| N6 | /playbooks/:id | PUT | 401 | NON |
| N7 | /playbooks/:id | DELETE | 401 | NON |
| N8 | /playbooks/:id/toggle | PATCH | 401 | NON |
| N9 | /playbooks/suggestions | GET | 401 | NON |
| N10 | /playbooks/suggestions/:id/apply | PATCH | 401 | NON |
| N11 | /playbooks/suggestions/:id/dismiss | PATCH | 401 | NON |

Validation 100% en negatifs possible **sans creer / modifier / supprimer aucune regle de test**. tenantGuard rejette en preHandler avant atteinte du handler -> 0 ecriture DB de notre fait.

### 6.4 Faut-il separer READ rules et MUTATION rules ?

**OUI, decoupage 5A / 5B explicitement recommande.**

| Sous-phase | Endpoints | Risque UX | Justification |
|---|---|---|---|
| **AS.12.2C-5A READ** | R1 (GET /ai/rules) + P1 (GET /playbooks) + P2 (GET /playbooks/:id) + P7 (GET /playbooks/suggestions) | **LOW** | 4 endpoints lecture seule. Validation negative claire (401 no-auth). UX risk = vue d ecran rules vide si BFF/tenantGuard mauvaise injection. Rollback simple. |
| **AS.12.2C-5B MUTATIONS** | R2 (POST /ai/rules) + P3 (POST /playbooks) + P4 (PUT /playbooks/:id) + P5 (DELETE /playbooks/:id) + P6 (PATCH /playbooks/:id/toggle) + P8 (PATCH /playbooks/suggestions/:id/apply) + P9 (PATCH /playbooks/suggestions/:id/dismiss) | **MEDIUM-HIGH** | 7 endpoints mutation. UX risk = creation/edit/delete/toggle regle bloquee pour tenant authentifie si membership mal injectee. Validation negative (401) toujours possible. QA Ludovic UI playbooks (create, edit, toggle, delete) obligatoire avant cloture. |

Decoupage permet de :
- Livrer 5A rapidement avec risque UX minimal (read-only) ;
- Tester l UX list playbooks en DEV apres 5A pour confirmer aucun regression visuelle ;
- Livrer 5B apres validation 5A, avec QA mutations precise.

### 6.5 Peut-on patcher API-only ou faut-il Client/BFF ?

Mixte selon endpoint :

- `/playbooks/*` : **API-only**. BFF deja safe, aucune modification Client requise. 1 patch `tenantGuard.ts` (9 entries dans PROTECTED_ROUTES) + verification que les 7 BFF passent bien X-User-Email (deja OK).
- `/ai/rules` : **API + Client/BFF**. Il faut creer BFF `/api/ai/rules` (GET + POST). Optionnel : ajouter `getAIRules` / `createAIRule` dans `ai.service.ts` si un futur composant Client veut consommer (aucun caller actif aujourd hui).

Recommandation : patch API en premier (tenantGuard sur tous les 11 endpoints) ; creer le BFF `/api/ai/rules` seulement si un caller Client est identifie. Le BFF est "optionnel" pour `/ai/rules` car aucun consommateur Client actuel.

---

## 7. Design patch futur (NON EXECUTE)

### 7.1 AS.12.2C-5A READ -- fichiers a toucher

| Fichier | Repo | Modification |
|---|---|---|
| `src/plugins/tenantGuard.ts` | keybuzz-api | +4 lignes PROTECTED_ROUTES (R1 + P1 + P2 + P7) + commentaire phase 5A |
| `app/api/ai/rules/route.ts` | keybuzz-client | NOUVEAU fichier BFF GET (~60 lignes, pattern AS.12.2C-2 guard/check) |

Optionnel : `ai.service.ts` -- ajout `getAIRules(tenantId)` si un futur composant Client en a besoin. **Aucun caller actuel** -> non requis pour cette phase.

### 7.2 AS.12.2C-5B MUTATIONS -- fichiers a toucher

| Fichier | Repo | Modification |
|---|---|---|
| `src/plugins/tenantGuard.ts` | keybuzz-api | +7 lignes PROTECTED_ROUTES (R2 + P3 + P4 + P5 + P6 + P8 + P9) + commentaire phase 5B |
| `app/api/ai/rules/route.ts` | keybuzz-client | ajout POST handler (~30 lignes en complement du GET de 5A) |

Optionnel : `ai.service.ts` -- ajout `createAIRule(...)`. **Aucun caller actuel.**

### 7.3 Tags futurs proposes

| Phase | Tag API | Tag Client |
|---|---|---|
| AS.12.2C-5A DEV | v3.5.185-ai-rules-read-tenantguard-dev | v3.5.196-ai-rules-bff-dev (si BFF /api/ai/rules cree) |
| AS.12.2C-5A PROD | v3.5.185-ai-rules-read-tenantguard-prod | v3.5.196-ai-rules-bff-prod |
| AS.12.2C-5B DEV | v3.5.186-ai-rules-mut-tenantguard-dev | v3.5.197-ai-rules-bff-dev |
| AS.12.2C-5B PROD | v3.5.186-ai-rules-mut-tenantguard-prod | v3.5.197-ai-rules-bff-prod |

KEY-309 + KEY-308 + KEY-302 conserves (scripts patches AS.12.2C-3.1).

### 7.4 Plan validation negative futur (5A + 5B)

Apres 5A : 11/11 preserve + 4 NEW READ protections = 15/15 total.
Apres 5B : 11/11 preserve + 11 NEW rules protections = 22/22 total (10 actuelles AS.11/AS.12.1/AS.12.2 + 1 AS.12.2C-1/2/3/4 + 11 AS.12.2C-5).

| # | Endpoint | Method | Expected | Phase |
|---|---|---|---|---|
| Preserve 10 | (10 endpoints precedents) | -- | 401 | toutes phases anterieures |
| 5A-N1 | /ai/rules | GET | 401 | 5A |
| 5A-N2 | /playbooks | GET | 401 | 5A |
| 5A-N3 | /playbooks/:id (fake UUID) | GET | 401 | 5A |
| 5A-N4 | /playbooks/suggestions | GET | 401 | 5A |
| 5B-N1 | /ai/rules | POST | 401 | 5B |
| 5B-N2 | /playbooks | POST | 401 | 5B |
| 5B-N3 | /playbooks/:id (fake UUID) | PUT | 401 | 5B |
| 5B-N4 | /playbooks/:id (fake UUID) | DELETE | 401 | 5B |
| 5B-N5 | /playbooks/:id/toggle (fake UUID) | PATCH | 401 | 5B |
| 5B-N6 | /playbooks/suggestions/:id/apply (fake UUID) | PATCH | 401 | 5B |
| 5B-N7 | /playbooks/suggestions/:id/dismiss (fake UUID) | PATCH | 401 | 5B |

Aucun POST positif requis. Aucune fixture / dry-run necessaire.

### 7.5 Plan rollback futur (PRET)

Standard GitOps revert + 2 kubectl apply (pattern AS.12.2C-4), reset vers v3.5.184/v3.5.195 (ou versions intermediaires si 5A et 5B sont separes).

Triggers rollback :
- Spike 401/403 sur GET /playbooks pour tenant authentifie -> regression list playbooks ;
- Spike 5xx API ;
- Spike JWT_SESSION_ERROR Client ;
- QA Ludovic confirme creation/edit/delete playbook impossible pour son tenant.

---

## 8. Risk matrix

| Risque | Severite | Probabilite | Mitigation |
|---|---|---|---|
| Cross-tenant create/edit/delete d une regle (rules + playbooks) | **CRITICAL** | confirmee (sans patch) | Patch 5A + 5B ferme la surface (11 endpoints) |
| Pollution `ai_rule_conditions` / `ai_rule_actions` | HIGH | confirmee | Patch transitif via FK ai_rules |
| Regression UX list playbooks | LOW | nulle si BFF correctement injecte X-User-Email | 5A read-only + QA browser obligatoire |
| Regression UX creation/edit playbook | MEDIUM | nulle si tenant membership correct (BFF + tenantGuard) | 5B + QA browser playbooks UI obligatoire |
| Plan gating absence (STARTER peut creer regle PRO-only) | MEDIUM | independante de KEY-301 | Gap operationnel separe (ticket housekeeping futur) |
| BFF `/api/playbooks/[id]/simulate` ou `/[id]/suggestions` pointing to non-existing API endpoint | LOW | a clarifier durant 5A | RCA dediee si necessaire |
| Admin v2 mock connecte un jour aux rules | LOW (future) | nulle aujourd hui (mock) | Si connection future, BFF + tenantGuard prets |

Aucun risque bloquant pour le design.

---

## 9. Quick wins decouverts (hors scope strict mais a noter)

- **`/playbooks` non protege** : c est la surface CRUD ai_rules complete, beaucoup plus critique que `/ai/rules` partial. Le scope AS.12.2C-5 doit imperativement l inclure (sinon vulnerabilite ouverte).
- **BFF `/api/playbooks/*` deja safe** : pas de refactor BFF necessaire pour 5A+5B (gain de temps significatif).
- **`AIDecisionPanel` non monte** (rappel AS.12.2C-4 design audit) : pas de regression UX possible sur `/ai/execute` -- le pattern de non-mount peut etre verifie aussi sur d autres composants AI orphelins si decouverts.
- **Admin v2 mock-driven** : si admin v2 doit etre branche aux vrais rules un jour, BFF a creer en plus.

---

## 10. AI feature parity / anti-regression projete

| Surface | Statut projete apres AS.12.2C-5A | Statut projete apres AS.12.2C-5B |
|---|---|---|
| Tenant switcher | OK (preserve) | OK (preserve) |
| Inbox liste/detail/reply | OK (KEY-304 preserve) | OK |
| Brouillon IA auto + AI panels | OK (AS.12.2B+AS.12.2C-1/2/3 preserve) | OK |
| /ai/execute protection | OK (AS.12.2C-4 preserve) | OK |
| Playbooks list (page `/playbooks`) | **NEW protege** | OK |
| Playbook detail (page `/playbooks/[id]`) | **NEW protege** | OK |
| Playbook suggestions (sidebar / pages) | **NEW protege** | OK |
| Playbook create (page `/playbooks/new`) | OK (5A read seul, mutation 5B) | **NEW protege** |
| Playbook edit (PUT) | OK | **NEW protege** |
| Playbook delete | OK | **NEW protege** |
| Playbook toggle active/disabled | OK | **NEW protege** |
| Apply/dismiss suggestion | OK | **NEW protege** |
| /ai/rules (orphelin Client) | **NEW protege**, BFF a creer | **NEW protege** mutation |

---

## 11. No-mutation proof (audit phase)

| Item | Statut |
|---|---|
| Aucun patch source applique | OK |
| Aucun build | OK |
| Aucun docker push | OK |
| Aucun deploy K8s | OK |
| Aucun manifest infra touche | OK |
| Aucun POST / PATCH / DELETE / PUT positif emis | OK |
| Aucune creation / modification / suppression de regle | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucune mutation DB de notre fait | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| PROD strictement read-only (kubectl get / curl audits / file reads only) | OK |

---

## 12. Linear text prepared (disclosure-controlled)

### 12.1 KEY-301 commentaire cible

```
## AS.12.2C-5 design audit /ai/rules + /playbooks -- GO DESIGN READY with mandatory 5A/5B split

Read-only audit of the rules surface delivered. Major finding : the prompt-targeted `/ai/rules` (2 partial endpoints) is **not the full CRUD surface for ai_rules**. The real CRUD lives at `/playbooks` (9 endpoints in `src/modules/playbooks/routes.ts`) which writes to the same `ai_rules`, `ai_rule_conditions`, `ai_rule_actions` tables and is **currently not protected** by tenantGuard.

Surface complete : 11 endpoints to protect (2 on /ai/rules + 9 on /playbooks).

Recommended split :
- **AS.12.2C-5A READ** : 4 GET endpoints (low UX risk, read-only).
- **AS.12.2C-5B MUTATIONS** : 7 POST/PUT/PATCH/DELETE endpoints (medium-high UX risk -- /playbooks UI active in 4 runtime pages : list, new, [id], tester).

Cross-tenant risk in current state is **CRITICAL** : an attacker with /playbooks unprotected can create / edit / delete rules of arbitrary tenant -> autopilot reply pollution, send_reply with attacker-chosen draft, escalation rerouting, rule deletion. More severe than /ai/execute (audit log).

Client BFF `/api/playbooks/*` (7 routes) already safe (NextAuth + X-User-Email). BFF `/api/ai/rules` absent (to create in 5A).

Validation 100% in negatives possible (401 no-auth) without creating / editing / deleting any rule. No fixture / no dry-run needed.

Admin v2 `app/(admin)/ai/page.tsx` uses `AI_AUTOMATION_RULES_MOCK` constant -- no runtime API call, hors runtime concern.

No adminGuard plugin exists. tenantGuard alone is the correct policy (rules are tenant-scoped, not admin global).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no PII, no draftText.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 13. Compliance

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Aucun patch source `keybuzz-api` / `keybuzz-client` | OK |
| Aucun build / push / deploy / manifest | OK |
| Aucun POST / PATCH / DELETE / PUT positif | OK |
| Aucune mutation DB | OK |
| Aucune creation/modification/suppression de regle | OK |
| Aucun secret / PII / draftText | OK |
| PROD read-only strict | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |

---

## 14. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-5A IMPLEMENT (READ tenantGuard on 4 GET endpoints) reste a livrer apres GO design | High | Phase suivante : AS.12.2C-5A IMPLEMENT DEV puis PROD |
| G2 | AS.12.2C-5B IMPLEMENT (MUTATIONS tenantGuard on 7 endpoints) reste a livrer apres validation 5A | High | Phase suivante apres AS.12.2C-5A |
| G3 | BFF `/api/playbooks/[id]/simulate` et `/[id]/suggestions` pointent vers des endpoints API potentiellement absents (`/playbooks/:id/simulate`, `/playbooks/:id/suggestions`) | Low | Clarifier durant AS.12.2C-5A par runtime probe ou RCA dediee |
| G4 | Plan gating absent sur /ai/rules + /playbooks (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G5 | Admin v2 mock pur sur rules ; future connexion API necessitera BFF + tenantGuard (deja prevu par 5A/5B) | Low | A documenter quand admin v2 branche real rules |
| G6 | Backlog 32 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |
| GP1 | (rappel) Brouillon IA silent failure -- Linear KEY-312 | Medium | Decision produit attendue, hors KEY-301 |

---

## 15. Phrase cible finale

AS.12.2C-5 design audit livre : surface rules KeyBuzz inventories 11 method-path tuples a proteger (2 sur `/ai/rules` GET+POST partial + 9 sur `/playbooks` GET list + GET:id + POST + PUT:id + DELETE:id + PATCH:id/toggle + GET /suggestions + PATCH /suggestions/:id/apply + PATCH /suggestions/:id/dismiss, CRUD complet table `ai_rules` + `ai_rule_conditions` + `ai_rule_actions` + `playbook_suggestions`) ; cross-tenant risk en l etat = CRITICAL (creation/modification/suppression de regle d un tenant arbitraire avec impact downstream sur autopilot reply / escalation / send_reply via action types) ; aucun adminGuard plugin existe ; tenantGuard suffit (rules tenant-scoped via `tenantId` query/body/header) ; Client BFF `/api/playbooks/*` (7 routes) **DEJA SAFE** (NextAuth + X-User-Email) -- aucun refactor BFF requis pour /playbooks ; BFF `/api/ai/rules` **ABSENT** -- a creer dans 5A ; 4 pages UI `/playbooks` actives runtime (list, new, [id], tester) via hook `usePlaybooks` -- patch /playbooks porte risque UX reel ; Admin v2 `app/(admin)/ai/page.tsx` utilise `AI_AUTOMATION_RULES_MOCK` constante -- aucun fetch API, hors runtime ; **decoupage obligatoire** AS.12.2C-5A READ (4 GET endpoints, risque UX low) puis AS.12.2C-5B MUTATIONS (7 POST/PUT/PATCH/DELETE endpoints, risque UX medium-high) ; validation 100% en negatifs possible sans creer / modifier / supprimer aucune regle de test ; aucune fixture / aucun dry-run necessaire ; 3 patches futurs proposes par sous-phase (tenantGuard +4/+7 lignes selon 5A/5B + BFF /api/ai/rules nouveau + ai.service optionnel) ; aucune mutation source / build / push / deploy / DB / runtime cette phase ; PROD strictement read-only ; KEY-301 reste Open epic ; gaps G1-G6 + GP1 (KEY-312) documentes ; verdict AS.12.2C-5 GO AI RULES DESIGN READY avec scope obligatoirement elargi a `/playbooks` et decoupage 5A puis 5B.

STOP
