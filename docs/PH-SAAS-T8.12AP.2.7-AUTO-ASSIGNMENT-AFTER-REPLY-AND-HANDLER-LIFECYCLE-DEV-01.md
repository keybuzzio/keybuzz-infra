# PH-SAAS-T8.12AP.2.7 — Auto-Assignment After Reply & Handler Lifecycle DEV

> Date : 2026-05-07
> Auteur : Cursor Executor
> Phase : AP.2.7
> Ticket : KEY-268
> Tickets liés : KEY-265, KEY-263, KEY-253, KEY-267
> Environnement : DEV
> Type : Audit + implémentation DEV

---

## Objectif

Implémenter en DEV l'auto-assignation après réponse humaine : quand un humain répond à une conversation non assignée, `assigned_agent_id` est automatiquement renseigné avec l'ID de l'agent réel tenant-scoped.

---

## Sources relues

| Source | Statut |
|---|---|
| `CE_PROMPTING_STANDARD.md` | Contexte conversation |
| `RULES_AND_RISKS.md` | Contexte conversation |
| `AI_MESSAGING_FEATURE_PARITY_BASELINE.md` | Contexte conversation |
| `PH-SAAS-T8.12AP.1F-...-PROD-PROMOTION-01.md` | Contexte conversation |
| `PH-SAAS-T8.12AP.2.3.1-...-PROD-QA-DB-VERIFY-01.md` | Contexte conversation |
| `PH-SAAS-T8.12AP.2.5-...-PROD-PROMOTION-01.md` | Relue |
| `PH-SAAS-T8.12AP.2.6-...-CLEANUP-PROD-01.md` | Relue |

---

## Baselines PROD (inchangées)

| Service | Image | Verdict |
|---|---|---|
| API PROD | `v3.5.146-conversation-lifecycle-status-prod` | INCHANGÉ |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | INCHANGÉ |
| OW PROD | `v3.5.165-escalation-flow-prod` | INCHANGÉ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | INCHANGÉ |
| Website PROD | `v0.6.9-promo-forwarding-prod` | INCHANGÉ |

---

## Preflight

| Repo | Branche | HEAD | Status |
|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `a18a361d` (AP.2.4) | `dist/` deletions only |
| keybuzz-infra | `main` | `69bb480` (AP.2.6 rapport) | Clean |

---

## ÉTAPE 1 — Audit code des chemins d'envoi

| Surface | Fichier | Endpoint | Agent identifié ? | assigned_agent_id écrit ? | author_name ? | Risque |
|---|---|---|---|---|---|---|
| Réponse humaine | messages/routes.ts:395-535 | POST /conversations/:id/reply | Oui (X-User-Email → users) | **NON** (avant fix) | Oui (Prénom.N) | **CIBLE PATCH** |
| Note interne | messages/routes.ts:395-535 | POST /conversations/:id/reply (internal) | Oui | NON | Oui | Non outbound |
| Autopilot reply | autopilot/engine.ts:820 | executeReply() | Non (IA) | NON | KeyBuzz IA | OK — pas de faux agent |
| Autopilot assign | autopilot/engine.ts:870 | executeAssign() | Oui (agentId param) | OUI | N/A | OK |
| Draft consume | autopilot/routes.ts:350+ | POST /autopilot/draft/consume | Non | NON | N/A | Escalation only |
| AI auto-escalate | ai-assist-routes.ts | POST /ai/assist | Non | NON | N/A | OK |
| Manual assign | messages/routes.ts:914 | PATCH /assign | Oui | OUI | N/A | OK |
| Inbound | inbound/routes.ts | POST /inbound/* | Non | NON | Sender | OK |
| Supplier reply | suppliers routes | POST | Non | NON | Equipe SAV | OK |

---

## ÉTAPE 2 — Audit DB DEV

| Type | Count DEV | Risque |
|---|---|---|
| Outbound humain + agent NULL | 107 | Cible auto-assignation |
| Escalated + agent NULL | 44 | À prendre en charge (correct) |
| Déjà assigné | 1 | Préservé |
| Autopilot messages | 16 | Pas de fausse assignation |
| `assigned_agent_id` type | TEXT | Compatible UUID→text |
| `users.id` type | UUID | Cast implicite OK |

---

## ÉTAPE 3 — Audit DB PROD (read-only)

| Signal PROD | Count | Risque |
|---|---|---|
| Outbound humain + agent NULL | 193 | Sera corrigé par futures réponses après PROD promo |
| Escalated + agent NULL | 16 | État valide (À prendre en charge) |
| Déjà assigné | 2 | Préservé |
| Autopilot messages | 0 | N/A |
| Ludovic.G author_name | 2 | AP.2.2 fonctionne |

---

## ÉTAPE 4 — Décision de patch

**Surface** : `POST /conversations/:id/reply` dans `messages/routes.ts`

**Logique** :
1. Fetch `id` + `name` dans le SELECT users existant
2. Stocker `resolvedAgentUserId` dans une variable accessible
3. Après le status update outbound, si `resolvedAgentUserId` non null :
   - Vérifier scope tenant via `user_tenants`
   - UPDATE `assigned_agent_id` WHERE `assigned_agent_id IS NULL` (pas d'écrasement)
4. Non-bloquant en cas d'erreur (try/catch avec warn)

**Pourquoi API-only** : L'assignation est une donnée serveur, pas une décision client.

---

## ÉTAPE 5 — Patch appliqué

**Fichier** : `src/modules/messages/routes.ts`

### Modification 1 : Variable + fetch id

```typescript
let agentDisplayName = 'KeyBuzz Agent';
let resolvedAgentUserId: string | null = null;
// ...
const userRes = await client.query('SELECT id, name FROM users WHERE email = $1', [userEmail]);
if (userRes.rows.length > 0) {
  agentDisplayName = formatAgentDisplayName(userRes.rows[0].name, userEmail);
  resolvedAgentUserId = userRes.rows[0].id;
}
```

### Modification 2 : Auto-assignation après status update outbound

```typescript
if (resolvedAgentUserId) {
  try {
    const scopeCheck = await client.query(
      'SELECT 1 FROM user_tenants WHERE user_id = $1 AND tenant_id = $2',
      [resolvedAgentUserId, tenantId]
    );
    if (scopeCheck.rows.length > 0) {
      const assignResult = await client.query(
        'UPDATE conversations SET assigned_agent_id = $1, updated_at = now() WHERE id = $2 AND tenant_id = $3 AND assigned_agent_id IS NULL',
        [resolvedAgentUserId, id, tenantId]
      );
      if ((assignResult as any).rowCount > 0) {
        app.log.info({ conversationId: id, agentId: resolvedAgentUserId, tenantId }, 'AP.2.7: Auto-assigned conversation to replier');
      }
    }
  } catch (assignErr) {
    app.log.warn({ error: assignErr }, 'AP.2.7: Auto-assignment failed (non-blocking)');
  }
}
```

**Propriétés** :
- Tenant-scoped (vérifie `user_tenants`)
- Ne surcharge pas les assignations existantes (`WHERE assigned_agent_id IS NULL`)
- Non-bloquant (try/catch)
- Log structuré pour audit

---

## ÉTAPE 6 — Tests DEV

| Test | Résultat attendu | Résultat obtenu | Verdict |
|---|---|---|---|
| A — Humain sur non-assignée | agent = user.id | `0156d1ac-...-216af804e7ef` = user.id | **PASS** |
| B — Humain sur déjà-assignée | agent inchangé | Préservé | **PASS** |
| D — Autopilot sans humain | Pas d'assignation fictive | agent=NULL | **PASS** |
| E — Escaladée non prise | Reste sans agent | escalated + agent=NULL | **PASS** |

Tests C (Aide IA validée) et Brouillon IA validé sont couverts par Test A car ces chemins passent par le même POST /reply.

---

## Build + GitOps

| Champ | Valeur |
|---|---|
| Source commit | `9521fb35 feat(messages): auto-assign conversation to human replier (AP.2.7, KEY-268)` |
| Branche | `ph147.4/source-of-truth` |
| Tag API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.161-auto-assignment-after-reply-dev` |
| Digest | `sha256:9575cdce1f6288587e37def67c3bc3dc3d07ac168a428e94ba73ee1cb5b8240b` |
| GitOps commit | `096d4ef` (keybuzz-infra) |
| Rollback API DEV | `v3.5.160-conversation-lifecycle-status-dev` |

Aucun autre service buildé.

---

## Validation runtime DEV

| Check | Résultat |
|---|---|
| Runtime image | `v3.5.161-auto-assignment-after-reply-dev` |
| Health | OK |
| Pod | 1/1 Running, 0 restarts |
| `assigned_agent_id IS NULL` dans JS | 1 occurrence |
| `user_tenants WHERE user_id` dans JS | 1 occurrence |
| `resolvedAgentUserId` dans JS | 6 occurrences |
| `Auto-assigned conversation` log | 1 occurrence |
| AP.2.4 CASE WHEN | 1 occurrence |
| AP.2.2 formatAgentDisplayName | 3 occurrences |
| AP.1F REASK_PATTERNS | 2 occurrences |

---

## Non-régression

| Check | Résultat |
|---|---|
| API health | OK |
| Dashboard | 200 |
| AI assist | Route active (400 = body requis) |
| Pod restarts | 0 |
| PROD API | Inchangé |
| PROD Client | Inchangé |
| PROD OW | Inchangé |
| PROD Backend | Inchangé |
| PROD Website | Inchangé |
| No-reask | Préservé (REASK_PATTERNS) |
| Author name | Préservé (formatAgentDisplayName) |
| Escalation clear | Préservé (CASE WHEN) |
| Billing/Stripe | Non impacté |
| Tracking/CAPI | Non impacté (pas de build Client) |

---

## Contrat d'auto-assignation — Couverture

| Cas | Règle | Implémenté | Verdict |
|---|---|---|---|
| A — Réponse humaine directe | Auto-assign si vide | OUI | PASS |
| B — Aide IA validée par humain | Même chemin que A | OUI | PASS |
| C — Brouillon IA validé par humain | Même chemin que A | OUI | PASS |
| D — Autopilot sans humain | Pas d'assignation fictive | Chemin séparé (engine.ts) | PASS |
| E — Escalade non prise | Reste "À prendre en charge" | Pas touché | PASS |
| F — Déjà assigné | Ne pas écraser | WHERE IS NULL | PASS |

---

## Linear

| Ticket | Mise à jour |
|---|---|
| KEY-268 | Auto-assignation implémentée en DEV. Tests PASS. Prêt pour PROD promo. |
| KEY-265 | Cycle de vie complet : escalation clear (AP.2.5) + cleanup (AP.2.6) + auto-assign (AP.2.7) |
| KEY-263 | Notification d'escalade reste hors scope (phase dédiée si besoin) |
| KEY-267 | `assigned_agent_name` non exposé dans l'API — le client peut résoudre via `assigned_agent_id` + users table. Phase dédiée si endpoint dédié souhaité. |
| KEY-253 | Progression AP avant Ads : no-reask + author_name + lifecycle + data hygiene + auto-assign — tous en DEV, prêts pour PROD. |

---

## Images DEV après AP.2.7

| Service | Image | Changement |
|---|---|---|
| API DEV | `v3.5.161-auto-assignment-after-reply-dev` | **MISE À JOUR** |
| Client DEV | `v3.5.167-outbound-author-name-ux-dev` | Inchangé |
| OW DEV | `v3.5.165-escalation-flow-dev` | Inchangé |

---

## Gaps restants

1. **Notification agent on-escalade** (KEY-263) — pas implémenté, hors scope AP.2.7
2. **`assigned_agent_name` API endpoint** (KEY-267) — pas nécessaire si client résout via users
3. **193 conversations PROD avec outbound humain + agent NULL** — seront progressivement corrigées par les futures réponses avec le fix en PROD
4. **Backfill historique des assignations** — non requis, correction future par usage naturel

---

## Verdict

**GO DEV FIX VALIDATED**

AUTO-ASSIGNMENT AFTER HUMAN REPLY READY IN DEV — UNASSIGNED CONVERSATIONS ARE ASSIGNED TO THE REAL TENANT-SCOPED HUMAN AGENT ON REPLY — EXISTING ASSIGNMENTS PRESERVED — IA-ASSISTED HUMAN SENDS ATTRIBUTED TO HUMAN VALIDATOR — AUTOPILOT DOES NOT CREATE FAKE HUMAN ASSIGNMENT — ESCALATED UNASSIGNED CONVERSATIONS REMAIN ACTIONABLE — NO AUTO-SEND ADDED — NO-REASK/AUTHOR_NAME/LIFECYCLE BASELINES PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED
