# PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-4 -- design audit /ai/execute (NO PATCH, NO BUILD, NO DEPLOY)
> Environnement : DEV + PROD read-only

---

## 1. VERDICT

GO AI EXECUTE DESIGN READY

L endpoint `POST /ai/execute` est **strictement un registreur d audit** : aucun appel LLM, aucun debit KBActions, aucun debit wallet, aucun appel downstream (pas de send reply, refund, escalate). Side effects DB limites a :
- `UPDATE ai_settings SET consecutive_errors = 0, updated_at = NOW() WHERE tenant_id = $1`
- `INSERT INTO ai_action_log (...)` avec `action_type='execute'`, `status='executed'`, `validated_by='human'`.

Blast radius cross-tenant en l etat (sans tenantGuard) :
- Pollution `ai_action_log` d un tenant autre (audit trail fausse, metrics derivees `consecutive_ai_actions`).
- Reset artificiel `ai_settings.consecutive_errors=0` du tenant autre (bypass partiel safe-mode counter).

**Decouverte significative** : le composant Client `AIDecisionPanel` qui contient le seul caller actuel d `executeAI` n est **pas integre** dans le DOM rendu (defini + reexporte mais 0 parent component qui le monte). Donc en runtime actuel, `/ai/execute` n a aucun caller actif. La protection se fait avec risque UX zero immediat.

Patch futur recommande (NON applique dans cette phase) :
1. `keybuzz-api/src/plugins/tenantGuard.ts` : ajouter `{ method: 'POST', path: '/ai/execute' }` dans PROTECTED_ROUTES (1 ligne).
2. `keybuzz-client/app/api/ai/execute/route.ts` : creer un nouveau BFF Next.js qui injecte `X-User-Email` + `X-Tenant-Id` depuis NextAuth session, forward POST -> API `/ai/execute` (pattern identique a `/api/ai/evaluate` deja en place).
3. `keybuzz-client/src/services/ai.service.ts` : modifier `executeAI` pour appeler le BFF `/api/ai/execute` au lieu du `fetchAI('/ai/execute', ...)` direct browser->API (1 fonction reecrite, pattern identique a `evaluateAI` AS.12.2C-3).

Validation negative possible **100% en negatifs** :
- POST /ai/execute no-auth -> 401 (tenantGuard).
- POST /api/ai/execute no-session -> 401 NO_SESSION (BFF).
- POST /api/ai/execute avec session mais sans tenantId body/header -> 400 (BFF).
- Aucun POST positif requis. Aucune fixture dry-run necessaire (handler ne fait pas d action LLM/KBActions/wallet). Le composant Client caller n etant pas monte, aucune QA UX directe possible -- mais c est ACCEPTABLE car aucune regression UX possible non plus.

Risques bloquants : aucun. Risque residuel uniquement = future integration d AIDecisionPanel (qui necessitera alors le BFF et tenantGuard correctement en place -- ce que ce patch garantit).

KEY-301 reste Open epic.

---

## 2. Scope

Inclus (audit / design only) :
- Lecture sources API + Client + BFF + downstream pour /ai/execute.
- Identification side effects + DB writes + dependances.
- Conception patch futur exact + plan validation negative + plan rollback.
- Risk matrix + verdict.
- Rapport docs-only.

Strictement hors scope :
- Aucun patch source.
- Aucun build.
- Aucun deploy.
- Aucun docker push.
- Aucune modification manifest.
- Aucun POST / PATCH / DELETE positif emis vers /ai/execute.
- Aucune execution action downstream.
- Aucune generation LLM.
- Aucune consommation KBActions ni debit wallet.
- Aucune mutation DB.
- Aucun draftText publie.
- Aucune PII publiee.
- PROD strictement read-only.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-AI-AUDIT-READONLY-01.md` (audit AS.12.2C global).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-*.md` (assist).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-*.md` (guard/check).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-*.md` (evaluate + RCA + R2 + PROD).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md`.
- `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES actuelles + commentaire ligne 115 sur /ai/execute differe).
- `keybuzz-api/src/plugins/planGuard.ts` (requirePlan pattern).
- `keybuzz-api/src/modules/ai/routes.ts` (lignes 356-394 handler `POST /execute`).
- `keybuzz-api/src/app.ts` (mount prefix `/ai`).
- `keybuzz-client/src/services/ai.service.ts` (executeAI ligne 187, fetchAI helper ligne 113).
- `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` (handleSendDirect ligne 152, onClick ligne 361).
- `keybuzz-client/src/features/ai-ui/index.ts` (re-export AIDecisionPanel).
- `keybuzz-client/app/api/ai/*` (mapping BFF existantes).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 | OK | OK |
| keybuzz-infra HEAD / sync | 3f5b75d (AS.12.2C-3.1 scripts fix) / 0-0 / 0 dirty | OK |
| keybuzz-api HEAD / branche / sync | 85555b26 / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-client HEAD / branche / sync | c24d8c9 / ph148/onboarding-activation-replay / 0-0 | OK |
| Runtime DEV API | v3.5.183-ai-evaluate-tenantguard-dev | OK MATCH baseline AS.12.2C-3-R2 |
| Runtime DEV Client | v3.5.194-ai-evaluate-bff-dev | OK MATCH baseline AS.12.2C-3-R2 |
| Runtime PROD API | v3.5.183-ai-evaluate-tenantguard-prod | OK MATCH baseline AS.12.2C-3-PROD |
| Runtime PROD Client | v3.5.194-ai-evaluate-bff-prod | OK MATCH baseline AS.12.2C-3-PROD |
| Smoke V1 script | scripts/smoke-v1.sh absent du repo bastion (saute, optionnel pour design audit) | NOTE |
| Read-only PROD verifie | aucun curl POSITIF, aucun docker, aucun kubectl mutation cette phase | OK |

---

## 5. Audit detaille /ai/execute

### 5.1 Path + method + handler

Mount API : `app.register(aiRoutes, { prefix: '/ai' })` (`src/app.ts` ligne 174). Le handler dans `src/modules/ai/routes.ts` ligne 356 : `app.post('/execute', ...)` -> route effectif `POST /ai/execute`.

Body : `interface AiExecuteBody { tenantId: string; actionId?: string; ruleId?: string; conversationId?: string }`.

Validation :
- 400 si `!tenantId` (`tenantId required`).
- 400 si `!actionId && !ruleId` (`actionId or ruleId required`).

### 5.2 Handler flow

1. `pool = await getPool()`.
2. `guard = await checkGuardrails(pool, tenantId, conversationId)` -- check `ai_global_settings.global_kill_switch` + (potentiellement d autres garde-fous).
3. `settings = SELECT * FROM ai_settings WHERE tenant_id = $1` (defaults `ai_enabled=true, mode='supervised', safe_mode=true`).
4. **Branche A** (`guard.blocked == true`) :
   - INSERT `ai_action_log` avec `action_type='execute'`, `status='blocked'`, `blocked=true`, `blocked_reason=guard.reason`, `blocked_by=guard.blockedBy`.
   - Reply 403 `{ status: 'blocked', log_id, blocked: true, blocked_reason, blocked_by }`.
5. **Branche B** (`settings.safe_mode == true && settings.mode === 'suggestion'`) :
   - INSERT `ai_action_log` avec `action_type='execute'`, `status='blocked'`, `blocked=true`, `blocked_reason='Mode suggestion: validation humaine requise'`, `blocked_by='mode_restriction'`.
   - Reply 403 `{ status: 'blocked', ... }`.
6. **Branche C** (succes) :
   - `UPDATE ai_settings SET consecutive_errors = 0, updated_at = NOW() WHERE tenant_id = $1`.
   - INSERT `ai_action_log` avec `action_type='execute'`, `status='executed'`, `summary='Executed action from rule <ruleId>'`, `payload=JSON({ actionId, ruleId, mode })`, `blocked=false`, `validated_by='human'`, `validated_at=NOW()`.
   - Reply 200 `{ status: 'executed', log_id, message: 'Action executed successfully' }`.
7. **Catch** : 503 `{ error: 'Database unavailable' }`.

### 5.3 Side effects DB

| Operation | Cible | Frequence | Cross-tenant impact (sans tenantGuard) |
|---|---|---|---|
| `UPDATE ai_settings.consecutive_errors=0, updated_at=NOW()` | tenant_id du body | 1 fois par succes | Bypass partiel safe-mode counter d un autre tenant |
| `INSERT ai_action_log (action_type='execute', status='executed', validated_by='human')` | tenant_id du body | 1 fois par succes | Pollution audit trail + metric `consecutive_ai_actions` |
| `INSERT ai_action_log (action_type='execute', status='blocked', blocked=true)` | tenant_id du body | 1 fois par blocked path | Pollution audit trail (moins critique car flag blocked=true) |

Aucune autre modification DB. Aucun trigger downstream documente dans cet handler (pas de event emit, pas de webhook out, pas de queue push).

### 5.4 Downstream actions

**AUCUN downstream call observe** dans le handler. Le route `/ai/execute` est concu uniquement comme registre d audit que l action a ete validee humainement. L action concrete (ex : envoi de message reel) se fait :
- Soit en parallele cote Client via `onSendDirect(text)` callback dans `AIDecisionPanel.handleSendDirect` (qui appelle l API canal `/messages/conversations/:id/reply`).
- Soit deja realisee par l autopilot engine via `evaluateAndExecute` (RCA AS.12.2C-3 confirme ce chemin direct, non HTTP, pour Brouillon IA auto).

`/ai/execute` ne declenche **rien d execute en aval** : ni email, ni reply, ni refund, ni escalate, ni notification.

### 5.5 Wallet / KBActions interaction

Le handler `/execute` **ne consulte ni ne modifie** :
- `ai_credits_wallet` (KBActions wallet).
- `ai_action_log` colonnes `kbactions_consumed`, `kbactions_remaining`.
- Aucun debit wallet.
- Aucune consommation KBActions.

Cas potentiellement different : `/ai/execute` accepte `ruleId` et logue `payload={actionId, ruleId, mode}`. Si une regle deja-validee debit-able existait, le debit aurait ete fait par `evaluateAI`/`assistAI` (qui sont LLM-bound et touchent au wallet). `/execute` n est qu une trace humaine.

### 5.6 Plan gating

`requirePlan` (plugin `src/plugins/planGuard.ts:34`) n est **pas applique** sur `POST /execute`. Aucune restriction par plan (STARTER / PRO / AUTOPILOT) appliquee sur ce route. Hors scope KEY-301 mais a noter comme gap operationnel separe.

### 5.7 Client `executeAI` implementation

```typescript
// ai.service.ts ligne 187
export async function executeAI(params: { tenantId: string; actionId?: string; ruleId?: string; conversationId?: string }): Promise<AIExecuteResponse> {
  return fetchAI<AIExecuteResponse>('/ai/execute', { method: 'POST', body: JSON.stringify(params) });
}
```

`fetchAI` (ligne 113) prefix `API_CONFIG.baseUrl + '/ai/execute'` => **appel direct browser->API**. Aucun X-User-Email / X-Tenant-Id injecte (pas de session NextAuth recuperee cote browser). C est exactement le pattern non-safe qui a ete remplace dans AS.12.2C-1/2/3 par BFF.

### 5.8 Caller actif executeAI

Unique caller : `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` ligne 156 :

```typescript
// handleSendDirect (line 152)
const result = await executeAI({ tenantId: effectiveTenantId, ruleId: selectedSuggestion.rule_id, conversationId });
```

Declenche par : `onClick={handleSendDirect}` au bouton "Valider et envoyer" (line 361). Action humaine explicite. PH25.9 (no auto-call without consent) respecte.

### 5.9 AIDecisionPanel mount status -- decouverte critique

Recherche `AIDecisionPanel` dans `keybuzz-client/app/` et `keybuzz-client/src/` :

| Fichier | Type | Statut |
|---|---|---|
| `src/features/ai-ui/AIDecisionPanel.tsx` | definition | OK (export function) |
| `src/features/ai-ui/index.ts` | re-export `export { AIDecisionPanel } from './AIDecisionPanel'` | OK (re-export) |
| `app/api/ai/evaluate/route.ts` | commentaire JSDoc seulement `consumers (AIDecisionPanel) should rely on...` | NON-MOUNT |

**Aucun parent component ne fait `<AIDecisionPanel ... />` ni `import { AIDecisionPanel }` utilise comme JSX**. Le composant est defini et exporte mais jamais integre dans un layout, page, ou autre composant rendu.

Consequence : en runtime actuel (DEV + PROD), `/ai/execute` n est **jamais appele** par le Client. Aucun browser ne deplie le bouton "Valider et envoyer". Aucun caller server-side autre n existe (`grep -rnE "/ai/execute" src/modules/` API = 0 result hors `tenantGuard.ts` commentaire).

Cette decouverte rassure fortement sur le risque UX du patch tenantGuard : il n y a aucun trafic legitime a casser. Le patch protege un endpoint qui pourrait etre cible par un attaquant mais qui n est pas utilise en production.

### 5.10 BFF /api/ai/execute -- absent

Routes BFF Next.js existantes sous `keybuzz-client/app/api/ai/` :
- `assist`, `context/upload`, `context/download`, `context/download/[id]`
- `returns/analysis`, `returns/decision`
- `learning-control`, `guard/check`, `journal`, `evaluate`, `settings`
- `wallet/settings`, `wallet/status`, `wallet/dev/consume`, `wallet/dev/topup`, `wallet/ledger`
- `errors/clusters`, `suggestions`, `suggestions/stats`, `suggestions/flag`, `suggestions/track`, `dashboard`

**Pas de route `execute`** dans `app/api/ai/`. Le BFF doit etre cree dans le patch futur, pattern identique a `app/api/ai/evaluate/route.ts` (AS.12.2C-3).

### 5.11 tenantId source

Cote API : `tenantId` est lu **du body** uniquement (`request.body.tenantId`). Aucun fallback header.
Cote Client `executeAI` : `tenantId` est passe dans le body.

Le futur BFF doit accepter tenantId du body OU du header `X-Tenant-Id` (header injecte cote BFF a partir de la session). Forme robuste : BFF injecte X-Tenant-Id ET garde le body intact, l API tenantGuard utilise les headers (pattern AS.12.2C-3 evaluate / AS.12.2C-2 guard/check / AS.12.2D settings).

---

## 6. Reponses aux questions obligatoires

### 6.1 Peut-on proteger /ai/execute sans permettre aucun test positif ?

**Oui**. Validation negative complete possible :

| # | Test | Methode | Resultat attendu | Mutation DB |
|---|---|---|---|---|
| T1 | POST /ai/execute no-auth, body minimal valide | API direct (curl) | 401 tenantGuard | NON (rejete preHandler) |
| T2 | POST /api/ai/execute no-session | BFF direct (curl) | 401 NO_SESSION (BFF) | NON |
| T3 | POST /api/ai/execute session valide, body sans tenantId | BFF + session cookie | 400 tenantId required (BFF) | NON |
| T4 | POST /ai/execute valid session via BFF, body mismatch tenant vs user | BFF -> API | 403 tenant-mismatch (tenantGuard membership check) | NON |
| T5 | Negative preserve : 9 endpoints deja proteges restent 401 | API direct | 401 chacun | NON |

Aucun test positif (status executed) n est necessaire ni recommande. Aucune mutation DB attendue de cette phase.

### 6.2 Quelle BFF minimale est necessaire ?

Modele exact (copie ajustee de `app/api/ai/evaluate/route.ts` deja en place) :

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/auth-options';

function getApiUrl(): string {
  return process.env.API_URL_INTERNAL || process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || '';
}

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
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

    const API_URL = getApiUrl();
    const res = await fetch(`${API_URL}/ai/execute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': userEmail,
        'X-Tenant-Id': tenantId,
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text();
      return NextResponse.json({ error: 'Backend error', details: text.substring(0, 200) }, { status: res.status });
    }
    return NextResponse.json(await res.json());
  } catch (error: any) {
    console.error('[ai/execute] Error:', error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
```

~60 lignes total. Aucune dependance externe. Aucune ecriture cote BFF.

### 6.3 Quel Client refactor minimal ?

Une seule fonction modifiee dans `src/services/ai.service.ts` :

```typescript
// Avant
export async function executeAI(params: { tenantId: string; actionId?: string; ruleId?: string; conversationId?: string }): Promise<AIExecuteResponse> {
  return fetchAI<AIExecuteResponse>('/ai/execute', { method: 'POST', body: JSON.stringify(params) });
}

// Apres (AS.12.2C-4 KEY-301)
export async function executeAI(params: { tenantId: string; actionId?: string; ruleId?: string; conversationId?: string }): Promise<AIExecuteResponse> {
  // PH-SAAS-T8.12AS.12.2C-4 KEY-301: routed via authenticated BFF /api/ai/execute
  // which injects X-User-Email + X-Tenant-Id from the NextAuth server session
  // so the API tenantGuard membership check applies cleanly.
  const response = await fetch('/api/ai/execute', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(params),
  });
  if (!response.ok) {
    throw new Error('API error: ' + response.status);
  }
  return response.json();
}
```

Aucune autre modification source Client. `AIDecisionPanel.tsx` reste identique (il appelle toujours `executeAI()` qui delegue maintenant via BFF).

### 6.4 Quels compteurs DB / no-mutation surveiller ?

Pre-deploy + post-deploy snapshots, tenant SWITAA derniere heure :

| Mesure SQL | Pre-deploy | Post-deploy attendu | Verdict |
|---|---|---|---|
| `SELECT COUNT(*) FROM ai_action_log WHERE tenant_id LIKE 'switaa%' AND action_type='execute' AND created_at >= NOW() - INTERVAL '1 hour'` | snapshot X | X (inchange) | PASS si X_post = X_pre |
| `SELECT updated_at FROM ai_settings WHERE tenant_id LIKE 'switaa%'` | snapshot timestamp | inchange | PASS si timestamp_post == timestamp_pre |
| `SELECT consecutive_errors FROM ai_settings WHERE tenant_id LIKE 'switaa%'` | snapshot N | N (inchange) | PASS si N_post == N_pre |

Aucun POST positif emis. Toute augmentation de `execute` count sur SWITAA proviendrait de l activite naturelle (mais comme AIDecisionPanel n est pas monte, attendu nul).

### 6.5 Quelle QA Ludovic sans execution reelle ?

QA proposee minimale (sans mutation) :

| Test | Procedure | Resultat attendu |
|---|---|---|
| Q1 | Ouvrir navigateur DEV https://app-dev.keybuzz.io et naviguer Inbox / AI panels / tenant switcher | Aucune erreur, aucun spike 401/403 dans DevTools Network |
| Q2 | Inspecter DevTools Network : verifier qu aucun appel `/api/ai/execute` n est emis spontanement | 0 occurrence (AIDecisionPanel non monte) |
| Q3 | Verifier que `/api/autopilot/draft` continue de repondre 200 (preserve AS.12.2B) | 200 |
| Q4 | Confirmer Brouillon IA + AIModeSwitch + Inbox liste/detail/reply OK | Comme baseline |

Aucune action humaine "Valider et envoyer" possible (composant non monte). Si l UX future re-integre AIDecisionPanel, un test positif pourra etre fait a ce moment, mais avec ce patch deja en place.

### 6.6 Faut-il une fixture dediee ou un dry-run mode ?

**Non**. Le handler `/execute` :
- ne fait pas d appel LLM (pas de provider call) ;
- ne consomme pas KBActions (pas de debit wallet) ;
- ne declenche pas d action downstream (pas de send reply, pas de refund, pas d escalate) ;
- ne fait que 2 ecritures DB simples (UPDATE ai_settings + INSERT ai_action_log).

Une fixture dediee n apporterait rien : la validation negative 401 suffit pour confirmer la protection. Pas de dry-run mode necessaire. Pas de phase separee.

---

## 7. Failure modes si tenantGuard active

| Scenario | Probabilite | Mitigation |
|---|---|---|
| Bug `fastify-plugin` wrap (encapsulation) | TRES FAIBLE | tenantGuard.ts deja correctement wrappee depuis AS.11.1A (cf project memory `tenant_guard_critical`) ; tous les preserve checks AS.12.1A-AS.12.2D-AS.12.2C-3 passent en runtime |
| Regression UX | NULL | AIDecisionPanel non monte, aucun caller actif a impacter |
| Faux positif race condition (cf AS.12.2C-3 RCA) | NUL | aucune chaine autopilot worker ne passe par `/ai/execute` ; uniquement caller direct executeAI cote AIDecisionPanel |
| Plan gating accidentel | NUL | requirePlan non applique, ce patch ne touche pas le plan |
| Effet sur metrics ai_action_log derives | NUL | aucune ecriture supplementaire de notre fait |
| BFF /api/ai/execute timeout / 500 | TRES FAIBLE | pattern identique a /api/ai/evaluate en place qui n a pas montre de timeout en PROD |
| Cache Next.js stale | NUL | `export const dynamic = 'force-dynamic'` |
| Bundle Client browser cache | FAIBLE | nouveau tag (-bff-dev / -bff-prod) declenche re-fetch |

Aucun failure mode bloquant identifie.

---

## 8. Design patch futur (NON EXECUTE)

### 8.1 Fichiers a toucher

| Fichier | Repo | Modification |
|---|---|---|
| `src/plugins/tenantGuard.ts` | keybuzz-api | +1 ligne PROTECTED_ROUTES + commentaire phase |
| `app/api/ai/execute/route.ts` | keybuzz-client | NOUVEAU fichier BFF ~60 lignes |
| `src/services/ai.service.ts` | keybuzz-client | 1 fonction `executeAI` reecrite (relative path via BFF) |

Aucune autre source touchee. Aucun manifest infra. Aucun script.

### 8.2 Tags futurs proposes

| Phase | Tag image |
|---|---|
| AS.12.2C-4-DEV | API : v3.5.184-ai-execute-tenantguard-dev / Client : v3.5.195-ai-execute-bff-dev |
| AS.12.2C-4-PROD | API : v3.5.184-ai-execute-tenantguard-prod / Client : v3.5.195-ai-execute-bff-prod |

KEY-309 tags immuables. KEY-308 OCI labels generes automatiquement par les scripts post-AS.12.2C-3.1.

### 8.3 Plan validation negative future

| # | Endpoint | Method | Expected |
|---|---|---|---|
| N1 | /ai/execute | POST no-auth, body valide | 401 (NEW) |
| N2 | /ai/assist | POST no-auth | 401 (preserve) |
| N3 | /ai/guard/check | POST no-auth | 401 (preserve) |
| N4 | /ai/evaluate | POST no-auth | 401 (preserve) |
| N5-N10 | /messages, /tenants, /notifications, /autopilot/draft, /ai/settings, /ai/wallet/status | GET no-auth | 401 (preserve 6/6) |

Total : 10 preserve protections apres AS.12.2C-4.

### 8.4 Plan rollback futur (PRET)

```
cd /opt/keybuzz/keybuzz-infra
git revert <commit-AS.12.2C-4>
git push origin main
kubectl apply -f k8s/keybuzz-api-<env>/deployment.yaml      # -> v3.5.183-...
kubectl -n keybuzz-api-<env> rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-<env>/deployment.yaml   # -> v3.5.194-...
kubectl -n keybuzz-client-<env> rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback (si appliques) :
- Spike 401 anormal sur tenant authentifie -> regression.
- 5xx API > baseline -> regression.
- JWT_SESSION_ERROR spike Client -> regression auth.

---

## 9. Risk matrix

| Risque | Severite | Probabilite | Mitigation |
|---|---|---|---|
| Cross-tenant pollution ai_action_log existant | HIGH | confirmed (sans patch) | Patch tenantGuard ferme la route |
| Regression UX si patch | LOW | nulle (AIDecisionPanel non monte) | N/A |
| Plan gating manquant sur /ai/execute | MEDIUM | independant | Gap operationnel separe (KEY-XXX futur) |
| Future re-integration AIDecisionPanel sans BFF | MEDIUM | possible | Ce patch prepare le terrain (BFF + tenantGuard prets) |
| Wallet / KBActions impact si handler evolue | LOW | a surveiller | Code review futur si /execute evolue |

Aucun risque bloquant pour le patch.

---

## 10. AI feature parity / anti-regression projete

| Surface | Statut projete apres AS.12.2C-4 | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2B+AS.12.2D preserve) | inchange |
| AISuggestionSlideOver | OK (AS.12.2C-1+AS.12.2C-2 preserve) | inchange |
| /ai/evaluate auto-call avoid (PH25.9) | OK (AS.12.2C-3 preserve) | inchange |
| /ai/execute protection | actif (AS.12.2C-4) | objectif phase |
| AIDecisionPanel (orphelin) | non monte (statut actuel) | hors scope cette phase |

---

## 11. No-mutation proof (audit phase)

| Item | Statut |
|---|---|
| Aucun patch source applique | OK |
| Aucun build | OK |
| Aucun docker push | OK |
| Aucun deploy K8s | OK |
| Aucun manifest infra touche | OK |
| Aucun POST positif emis | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucune mutation DB | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| PROD strictement read-only (curl audits uniquement) | OK |

---

## 12. Linear text prepared (disclosure-controlled)

### 12.1 KEY-301 commentaire cible

```
## AS.12.2C-4 design audit /ai/execute -- GO DESIGN READY (NO PATCH, NO BUILD, NO DEPLOY)

Read-only audit of POST /ai/execute completed. Findings :

- Handler is an audit-log only endpoint : INSERT into ai_action_log (action_type='execute', validated_by='human') + UPDATE ai_settings.consecutive_errors=0. No LLM call. No KBActions consumption. No wallet debit. No downstream action (no send reply, no refund, no escalate).
- Cross-tenant risk in current state : audit pollution + consecutive_errors reset of arbitrary tenant. No mass data exfiltration vector.
- Client caller executeAI is direct browser->API (not via BFF). BFF /api/ai/execute is absent.
- Critical finding : AIDecisionPanel (the only component using executeAI) is defined and re-exported but **not mounted** in any parent component. No active runtime caller. Patch carries zero UX regression risk.

Recommended future patch (NOT executed this phase) :
1. tenantGuard.ts : add `{method:'POST', path:'/ai/execute'}` to PROTECTED_ROUTES (1 line).
2. New BFF `app/api/ai/execute/route.ts` : NextAuth session + X-User-Email / X-Tenant-Id forward (pattern AS.12.2C-3 evaluate, ~60 lines).
3. ai.service.ts `executeAI` rewritten to use relative `/api/ai/execute` (1 function).

Validation 100% in negatives possible (401 / 400). No positive POST needed. No fixture / no dry-run.

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no PII, no draftText.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 13. Compliance

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun docker push | OK |
| Aucun deploy K8s | OK |
| Aucun POST / PATCH / DELETE positif | OK |
| Aucun appel /ai/execute positif | OK |
| Aucune execution action downstream | OK |
| Aucune generation LLM | OK |
| Aucun debit wallet / KBActions | OK |
| Aucune mutation DB | OK |
| Aucun draftText / PII | OK |
| PROD read-only strict | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |

---

## 14. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-4 IMPLEMENT (DEV puis PROD) reste a livrer apres GO design accepte | High | Phase suivante : AS.12.2C-4-IMPLEMENT |
| G2 | AS.12.2C-5 /ai/rules (admin CRUD) reste a livrer | Medium | Phase suivante apres AS.12.2C-4 |
| G3 | AIDecisionPanel non monte : composant orphelin. Si l UX future re-integre AIDecisionPanel, le patch AS.12.2C-4 doit etre en place | Low | A documenter dans BUILD_NOTES ; ce patch prepare le terrain |
| G4 | Plan gating manquant sur /ai/execute (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G5 | Backlog 29 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |

---

## 15. Phrase cible finale

AS.12.2C-4 livre design audit : `POST /ai/execute` est un registreur d audit pur (DB writes limitees a UPDATE `ai_settings.consecutive_errors=0` + INSERT `ai_action_log` action_type='execute' status='executed' validated_by='human') ; aucun appel LLM ; aucun debit KBActions/wallet ; aucun downstream action declenchee (pas de send/refund/escalate) ; cross-tenant risk en l etat = pollution audit + reset consecutive_errors d un tenant arbitraire (HIGH severity sans patch) ; Client caller unique `executeAI` ligne 187 dans `ai.service.ts` appel direct browser->API non-safe ; **decouverte critique** : AIDecisionPanel.tsx (unique consommateur d executeAI via `handleSendDirect` ligne 152) est defini + reexporte mais non monte dans aucun parent component => aucun caller actif en runtime DEV/PROD => patch tenantGuard porte risque UX zero immediat ; BFF `/api/ai/execute` absent (a creer pattern identique a `/api/ai/evaluate` AS.12.2C-3) ; design futur a 3 modifs (1 ligne `tenantGuard.ts` + 1 BFF nouveau ~60 lignes + 1 fonction `executeAI` reecrite ai.service.ts) ; validation negative 100% en negatifs 10/10 sans POST positif ; aucune fixture / aucun dry-run necessaire ; failure modes aucun bloquant ; rollback futur 4 commandes connues ; aucune mutation source / build / push / deploy / DB / runtime cette phase ; PROD read-only strict ; KEY-301 reste Open epic ; gaps G1-G5 documentes ; verdict AS.12.2C-4 GO AI EXECUTE DESIGN READY.

STOP
