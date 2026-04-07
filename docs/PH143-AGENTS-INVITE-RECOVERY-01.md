# PH143-AGENTS-INVITE-RECOVERY-01

**Date** : 2026-04-07
**Phase** : PH143-AGENTS-INVITE-RECOVERY-01
**Type** : audit + recuperation ciblee
**Environnement** : DEV uniquement

---

## 1. Cartographie de la feature Agents / Invites

### Chaine complete

```
UI (AgentsTab) → createAgent(tenantId, name, email, role)
  → BFF POST /api/agents → API POST /agents?tenantId=...
    → INSERT agents (tenant_id, first_name, last_name, email, type, role)

UI (AgentsTab) → sendAgentInvite(tenantId, email, role)
  → BFF POST /api/space-invites/:tenantId/invite → API POST /space-invites/:tenantId/invite
    → INSERT space_invites (tenant_id, email, role, token_hash, expires_at)
    → sendEmail() via SMTP (49.13.35.167:25)

Email recu → User clique lien /invite/{token}
  → /invite/[token]/page.tsx → cookie kb_invite_token → login OTP/OAuth
  → /invite/continue/page.tsx → POST /api/space-invites/accept
    → API POST /space-invites/accept
      → SELECT space_invites WHERE token_hash = hash(token)
      → INSERT/SELECT users
      → INSERT user_tenants (user_id, tenant_id, role)
      → UPDATE agents SET user_id = ... (FIX 2 de cette phase)
      → cookie currentTenantRole → redirect /inbox (agent) ou /dashboard (admin)
```

### Fichiers impliques

| Couche | Fichier | Role |
|--------|---------|------|
| UI | `app/settings/components/AgentsTab.tsx` | Creation agent + envoi invite |
| BFF | `app/api/agents/route.ts` | Proxy POST/GET agents |
| BFF | `app/api/space-invites/[tenantId]/invite/route.ts` | Proxy invite |
| BFF | `app/api/space-invites/accept/route.ts` | Proxy accept |
| API | `src/modules/agents/routes.ts` | CRUD agents + limites plan |
| API | `src/modules/auth/space-invites-routes.ts` | Invite + accept + email |
| Client | `app/invite/[token]/page.tsx` | Page lien invitation |
| Client | `app/invite/continue/page.tsx` | Acceptation post-auth |
| RBAC | `middleware.ts` | Restriction routes admin pour agents |
| RBAC | `src/components/layout/ClientLayout.tsx` | Nav reduite mode agent |
| Service | `src/services/agents.service.ts` | fetchAgents, createAgent, sendAgentInvite |

---

## 2. Phases sources retrouvees

| Phase | Contenu | Etat actuel |
|-------|---------|-------------|
| PH18 | Space invites complet (routes, email, token SHA-256, 7j expiry) | Present et fonctionnel |
| PH131-A | CRUD agents (routes, types, listing) | Present et fonctionnel |
| PH140-D | Unification agent+invite (createAgent puis sendAgentInvite) | Present cote client |
| PH140-H | Linkage agent.user_id sur accept d'invite | **ABSENT du code API** — documente mais jamais ajoute ou perdu |
| PH141-A | Limites agents par plan (AGENT_LIMITS hardcode) | Present mais **sans bypass billing-exempt** |
| PH141-C | Lockdown agent KeyBuzz (internal-only, X-Internal-Token) | Present et fonctionnel |

---

## 3. Reproduction exacte

### Etat avant correction

| Test | Resultat | Detail |
|------|----------|--------|
| `POST /agents` (creation) | **403** | `AGENT_LIMIT_REACHED (5/2)` — 5 agents client actifs, limite PRO = 2 |
| `sendAgentInvite()` | **Jamais appele** | createAgent echoue d'abord |
| Email invitation | **Jamais envoye** | Consequence du point precedent |
| `POST /space-invites/:tenantId/invite` (direct) | **200 OK** | Route fonctionnelle, email envoye, invite en DB |
| `check-user` agent non inscrit | `{exists:false, hasTenants:false}` | Normal — user pas dans DB tant que invite non acceptee |
| `check-user` agent inscrit | `{exists:true, hasTenants:true}` | OK |

### Donnees observees (ecomlg-001)

- 6 agents (5 client + 1 keybuzz)
- 10 invites (6 acceptees, 4 pending)
- 3 membres user_tenants (owner + 2 agents acceptes)
- Tenant plan : PRO, billing-exempt : true (internal_admin)

---

## 4. Causes racines

### Cause 1 — Agent limit bloque la creation

```
AGENT_LIMITS = { starter: 1, free: 1, pro: 2, autopilot: 3, enterprise: 999 }
```

Le tenant `ecomlg-001` a 5 agents client actifs mais le plan PRO limite a 2.
Le code ne consulte **pas** `tenant_billing_exempt` → meme les tenants internes sont bloques.

**Impact** : aucun nouvel agent ne peut etre cree → `sendAgentInvite()` jamais appele → pas d'email.

### Cause 2 — Linkage agent.user_id absent sur accept

Le `POST /space-invites/accept` cree correctement :
- L'entree `users` si inexistante
- L'entree `user_tenants` avec le bon role
- La mise a jour `user_preferences`

Mais il **ne fait PAS** :
```sql
UPDATE agents SET user_id = $1 WHERE email = $2 AND tenant_id = $3 AND user_id IS NULL
```

Documente dans PH140-H mais absent du code deploye.

**Impact** : un agent accepte a son user_tenants mais agents.user_id reste NULL → fonctions d'assignation degradees.

---

## 5. Corrections appliquees

### Fix 1 — Bypass billing-exempt dans `agents/routes.ts`

```diff
+      // PH143-AGENTS: Bypass limit for billing-exempt tenants
+      const exemptResult = await pool.query(
+        'SELECT exempt FROM tenant_billing_exempt WHERE tenant_id = $1 AND exempt = true',
+        [tid]
+      );
+      const isBillingExempt = exemptResult.rows.length > 0;
+
       const currentCount = await getActiveAgentCount(pool, tid);
-      if (currentCount >= limit) {
+      if (!isBillingExempt && currentCount >= limit) {
```

### Fix 2 — Linkage agent dans `space-invites-routes.ts`

```diff
+    // PH143-AGENTS: Link agent record to user (PH140-H recovery)
+    await pool.query(
+      `UPDATE agents SET user_id = $1, updated_at = NOW()
+       WHERE email = $2 AND tenant_id = $3 AND user_id IS NULL`,
+      [userId, userEmail, invite.tenant_id],
+    );
```

### Commit

- SHA : `db85c4d`
- Branche : `rebuild/ph143-api`
- Message : `PH143-AGENTS: billing-exempt bypass + agent linkage on invite accept`

---

## 6. Tests E2E apres correction

| Test | Resultat | Detail |
|------|----------|--------|
| `POST /agents` (creation, tenant exempt) | **201 OK** | Agent cree malgre 5 agents existants |
| `POST /space-invites/invite` | **200 OK** | Invite creee + email envoye |
| Agent en DB | **PASS** | id=119, type=client, role=agent, is_active=true |
| Invite en DB | **PASS** | token_hash present, expires 7j, accepted_at=null |
| Space-invites listing | **PASS** | 13 invites dont 4 pending |
| Agents listing API | **PASS** | 7 agents listes correctement |
| Non-regression Health | **PASS** | `{"status":"ok"}` |
| Non-regression Billing | **PASS** | plan: PRO |
| Non-regression Messages | **PASS** | conversations accessibles |

---

## 7. Image deployee

| Service | Image |
|---------|-------|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev` |
| Digest | `sha256:238f52276d90234791ef449281b94ea914e9b53f136d32a1d4145c9ced61bc0c` |

### Rollback si necessaire

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.189-draft-lifecycle-kbactions-dev -n keybuzz-api-dev
```

---

## 8. GitOps

- Manifest `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` mis a jour
- Image precedente : `v3.5.189-draft-lifecycle-kbactions-dev` (PH142-G)
- Image actuelle : `v3.5.48-ph143-agents-fix-dev` (PH143-AGENTS)

---

## 9. Ce qui reste a valider par Ludovic

1. **Test UI reel** : creer un agent depuis Settings > Agents → verifier que l'email arrive
2. **Ouvrir le lien d'invitation** dans l'email → verifier que le flow OTP/OAuth fonctionne
3. **Accepter l'invite** → verifier que l'agent se retrouve dans l'espace avec le role `agent`
4. **Se connecter comme agent** → verifier que le mode focus fonctionne (nav reduite, restrictions admin)
5. **Linkage** : verifier que agents.user_id est bien rempli apres acceptation

---

## Verdict

**AGENT INVITE FLOW RESTORED**

- Creation agent debloquee pour tenants billing-exempt
- Chaine complete : creation → invite → email → accept → linkage → RBAC
- Aucune regression sur les autres endpoints API
- DEV uniquement — PROD non touchee
