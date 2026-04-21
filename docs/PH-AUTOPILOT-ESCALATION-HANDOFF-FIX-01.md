# PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01 — Rapport Final

> Date : 2026-04-21
> Type : fix minimal handoff escalade
> Environnement : DEV ONLY — PROD NON TOUCHEE
> Branche : `ph147.4/source-of-truth`

---

## 1. OBJECTIF

Corriger le handoff reel apres validation d'un `ESCALATION_DRAFT` :
le statut `status = 'escalated'` (invalide dans le workflow UI) etait immediatement
ecrase par le reply flow (`status = 'open'`), rendant l'escalade invisible.

Fix minimal : remplacer `status = 'escalated'` par `status = 'pending'` dans la route
`POST /autopilot/draft/consume`.

---

## 2. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD avant fix | `1adbf73b` |
| Repo clean | OUI (untracked: .bak uniquement) |
| Image DEV avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-dev` |
| Image PROD avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-prod` |

### Preuve du statut initial

Ligne 332 de `src/modules/autopilot/routes.ts` :

```
status = 'escalated',
```

Confirme par `grep -n "status = 'escalated'" src/modules/autopilot/routes.ts`.

---

## 3. DIFF MINIMAL APPLIQUE

```diff
diff --git a/src/modules/autopilot/routes.ts b/src/modules/autopilot/routes.ts
index 377ded66..3c7eaf09 100644
--- a/src/modules/autopilot/routes.ts
+++ b/src/modules/autopilot/routes.ts
@@ -329,7 +329,7 @@ export async function autopilotRoutes(app: FastifyInstance) {
                escalation_reason = $2,
                escalated_at = now(),
                escalated_by_type = 'ai',
-               status = 'escalated',
+               status = 'pending',  // PH-ESCALATION-HANDOFF-FIX-01: use valid workflow status
                updated_at = now()
            WHERE id = $3 AND tenant_id = $4`,
           [escalationTarget, escalationReason, conversationId, tenantId]
```

**1 fichier, 1 ligne changee.**

---

## 4. COMMIT SOURCE

| Element | Valeur |
|---|---|
| Commit | `7265d29a` |
| Message | `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01: use 'pending' instead of 'escalated' for conversation status after ESCALATION_DRAFT consume` |
| Branche | `ph147.4/source-of-truth` |

---

## 5. IMAGE DEV

| Element | Valeur |
|---|---|
| Image avant | `v3.5.90-autopilot-orderid-prompt-fix-dev` |
| Image apres | `v3.5.91-autopilot-escalation-handoff-fix-dev` |
| Tag complet | `ghcr.io/keybuzzio/keybuzz-api:v3.5.91-autopilot-escalation-handoff-fix-dev` |
| Digest | `sha256:e67950b19d6bff404ef849e2a94448a85b307a1a529213cea9c21bfad0d46640` |
| Build | `docker build --no-cache` (build-from-git) |
| TypeScript | 0 erreurs |
| Rollback | `v3.5.90-autopilot-orderid-prompt-fix-dev` |

---

## 6. VALIDATION DEV

### Cas A — Patch compile verifie

| Verification | Resultat |
|---|---|
| `status = 'pending'` dans dist/modules/autopilot/routes.js | **OK** — ligne 271 |
| `status = 'escalated'` absent du status principal | **OK** |
| `escalation_status = 'escalated'` preservee (colonne dediee) | **OK** — ligne 266 |

### Cas B — Non-regression draft non-escalade

| Verification | Resultat |
|---|---|
| DRAFT_GENERATED presents | **OK** |
| DRAFT_APPLIED presents | **OK** |
| Comportement inchange | **OK** |

### Cas C — Non-regression API

| Endpoint | Resultat |
|---|---|
| `GET /health` | **OK** — `{"status":"ok"}` |
| `GET /messages/conversations` | **OK** — liste retournee |
| `GET /tenant-context/me` | **OK** — user info retourne |
| `GET /dashboard/summary` | **OK** — stats retournees |
| `GET /autopilot/settings` | **OK** — settings retournes |
| `GET /metrics/overview` | **OK** — metriques retournees |

### DB — Etat escalation existant

Les ESCALATION_DRAFTs existants en DEV sont non-consommes (aucun `consumedAt`).
Le fix s'appliquera au prochain consume d'un ESCALATION_DRAFT :
- `status` sera mis a `'pending'` (visible dans "En attente")
- `escalation_status` sera mis a `'escalated'` (badge escalade)
- Le reply flow ecrasera `status` a `'open'`, mais la conversation aura ete
  vue dans "En attente" et le badge escalade restera visible.

**Correction du timing :** Meme si le reply flow ecrase `status = 'open'` ~150ms apres,
`escalation_status = 'escalated'` reste intact. Le choix de `'pending'` au lieu de
`'escalated'` evite d'introduire un statut invalide dans le workflow.

---

## 7. ROLLBACK DEV

En cas de regression :

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 8. ETAT PROD

| Element | Valeur |
|---|---|
| Image PROD actuelle | `v3.5.90-autopilot-orderid-prompt-fix-prod` |
| Modifiee | **NON** |
| Raison | STOP — attente validation explicite |

---

## 9. GITOPS

Manifest DEV mis a jour : `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`
- Commit infra : `6946e06`
- Rollback documente dans le manifest

---

## 10. VERDICT

**ESCALATION HANDOFF FIXED IN DEV — MINIMAL PATCH — PROD UNTOUCHED**

### Effet attendu du fix

Apres consume d'un ESCALATION_DRAFT :
1. `conversations.status` = `'pending'` → conversation visible dans "En attente"
2. `conversations.escalation_status` = `'escalated'` → badge escalade visible
3. `conversations.escalation_target` = cible de l'escalade
4. `conversations.escalation_reason` = raison
5. Event `autopilot_escalate` insere dans `message_events`
6. Le reply flow met ensuite `status = 'open'` → conversation passe dans "Ouvert" avec badge escalade

### Ce qui n'est PAS traite (hors scope)

- Action B : assignation automatique d'un agent humain
- Action C : notification proactive aux agents
- Action D : refactoring du consume flow

---

**STOP**
