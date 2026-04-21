# PH-AUTOPILOT-BACKEND-CALLBACK-01 — Rapport Final

> Date : 2026-04-21
> Type : fix critique — restauration callback backend → API pour Autopilot
> Image DEV : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-autopilot-backend-callback-dev`
> Digest : `sha256:9ff366d1d86cd7ecd3c1c72f95746eb3e8c5830d5b75770f4eb13bdae21d5b51`

---

## Verdict : AUTOPILOT BACKEND CALLBACK RESTORED IN DEV — CONNECTOR-AGNOSTIC — BACKEND MAIN SOURCE LOCKED — PROD UNTOUCHED

---

## Correction de regle de branche par repo

| Repo | Branche obligatoire | Justification |
|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | Branche de reference API, lecture seule |
| `keybuzz-backend` | `main` | Repo distinct, n'a que `main` |
| `keybuzz-infra` | `main` | GitOps manifests |

La regle precedente imposait `ph147.4/source-of-truth` pour tous les repos, ce qui est incorrect car cette branche n'existe que dans `keybuzz-api`. La correction ci-dessus reflete la realite des repos.

---

## Preflight backend main

| Element | Valeur | Statut |
|---|---|---|
| Repo | `keybuzz-backend` | OK |
| Remote | `origin = https://github.com/keybuzzio/keybuzz-backend.git` | OK |
| Branche | `main` | OK |
| HEAD avant patch | `68aa2dd PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02` | Documente |
| HEAD apres patch | `df24693` (stubs) → `f30f621` (callback) → `8e8d40b` (stubs v1) | Documente |
| Repo clean | OUI | OK |
| Image backend DEV avant | `v1.0.44-ph150-thread-fix-prod` | Documente |
| Image backend PROD | `v1.0.44-ph150-thread-fix-prod` | Non modifiee |
| Image API DEV | `v3.5.91-autopilot-escalation-handoff-fix-dev` | Non modifiee |
| Image API PROD | `v3.5.91-autopilot-escalation-handoff-fix-prod` | Non modifiee |

---

## Audit du fix perdu PH-INBOUND-PIPELINE-TRUTH-04

Le callback `POST /autopilot/evaluate` implemente dans PH-INBOUND-PIPELINE-TRUTH-04 (image `v1.0.41-ph-inbound-pipeline-fix-dev`) a ete **perdu** dans les commits subsequents (`v1.0.42` → `v1.0.44`).

**Preuves** :
- `grep -rn "autopilot" src/modules/webhooks/` → ABSENT
- `grep -rn "API_INTERNAL_URL" src/` → ABSENT
- Les commits `v1.0.42` a `v1.0.44` ont ecrase/reecrit les fichiers sans conserver le callback

**Cause probable** : rebase ou merge qui n'a pas inclus le commit PH-04.

---

## Diff exact

**Fichier modifie** : `src/modules/webhooks/inboxConversation.service.ts`

**Changement** : 41 lignes inserees avant le `return` final de `createInboxConversation()`.

```diff
+  // ===== PH-AUTOPILOT-BACKEND-CALLBACK-01: Trigger autopilot evaluation =====
+  // Connector-agnostic: fires for ANY inbound conversation/message, not just Amazon.
+  // Fire-and-forget: does not block the webhook response.
+  const apiInternalUrl = process.env.API_INTERNAL_URL;
+  if (apiInternalUrl && conversationId) {
+    let callbackEmail = '';
+    try {
+      const ownerRow = await productDb.query(
+        `SELECT u.email FROM users u JOIN user_tenants ut ON u.id = ut.user_id
+         WHERE ut.tenant_id = $1 AND ut.role = 'owner' LIMIT 1`,
+        [tenantId]
+      );
+      if (ownerRow.rows.length > 0) callbackEmail = ownerRow.rows[0].email;
+    } catch (e) {
+      console.warn('[PH-CALLBACK-01] Owner email lookup failed:', (e as Error).message);
+    }
+
+    const callbackHeaders: Record<string, string> = {
+      'Content-Type': 'application/json',
+      'X-Tenant-Id': tenantId,
+    };
+    if (callbackEmail) callbackHeaders['X-User-Email'] = callbackEmail;
+
+    fetch(`${apiInternalUrl}/autopilot/evaluate`, {
+      method: 'POST',
+      headers: callbackHeaders,
+      body: JSON.stringify({ conversationId }),
+    })
+      .then(async (res) => {
+        const resBody = await res.text();
+        console.log(`[PH-CALLBACK-01] Autopilot trigger: status=${res.status} ...`);
+        if (res.status >= 400) {
+          console.warn(`[PH-CALLBACK-01] Autopilot trigger non-OK: ${resBody.substring(0, 200)}`);
+        }
+      })
+      .catch((err) => {
+        console.error(`[PH-CALLBACK-01] Autopilot trigger error: ${err.message}`);
+      });
+  }
```

### Differences avec PH-04

| Aspect | PH-04 (perdu) | PH-CALLBACK-01 (actuel) |
|---|---|---|
| Emplacement | `inboundEmailWebhook.routes.ts` (webhook route) | `inboxConversation.service.ts` (service partage) |
| Connector-agnostic | Non (seulement le webhook Amazon) | **OUI** (tout connecteur qui appelle `createInboxConversation`) |
| Header X-User-Email | Absent | Present (lookup proprietaire tenant) |
| Raison X-User-Email | tenantGuard n'existait pas encore | tenantGuard exige maintenant X-User-Email |

---

## Preuve connector-agnostic

Le callback est dans `createInboxConversation()`, la fonction centrale de creation de conversation. Tout connecteur (Amazon, Octopia, Shopify, email, etc.) qui utilise ce service declenchera automatiquement l'evaluation Autopilot.

### Tests valides

| Marketplace | Conversation ID | Callback status | API [Autopilot] |
|---|---|---|---|
| `amazon` | `cmmo8o1eizada07eca044d4fa` | `status=200` | `MODE_NOT_AUTOPILOT:suggestion` |
| `octopia` | `cmmo8o429y3f1ac6de0b3015b` | `status=200` | `MODE_NOT_AUTOPILOT:suggestion` |
| `email` | `cmmo8o4akbc050fef82757706` | `status=200` | `MODE_NOT_AUTOPILOT:suggestion` |

Les 3 marketplaces retournent `status=200` et `[Autopilot]` est evalue par l'API. Le resultat `MODE_NOT_AUTOPILOT:suggestion` est correct pour `ecomlg-001` (mode `supervised`, pas `autonomous`).

---

## Image DEV

| Element | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-autopilot-backend-callback-dev` |
| Digest | `sha256:9ff366d1d86cd7ecd3c1c72f95746eb3e8c5830d5b75770f4eb13bdae21d5b51` |
| Base | `node:22-alpine` |
| Build | `docker build --no-cache` depuis bastion |
| Source commit | `df24693` (main) |
| Branche | `main` |

### Image DEV avant/apres

| | Avant | Apres |
|---|---|---|
| Image | `v1.0.44-ph150-thread-fix-prod` | `v1.0.45-autopilot-backend-callback-dev` |
| Callback | ABSENT | PRESENT |
| Connector-agnostic | N/A | OUI |

---

## Manifest GitOps DEV

**Fichier** : `keybuzz-infra/k8s/keybuzz-backend-dev/deployment.yaml`

**Modifications** :
1. Image mise a jour de `v1.0.40-ph145.6-tenant-fk-fix-dev` vers `v1.0.45-autopilot-backend-callback-dev`
2. Rollback documente : `v1.0.44-ph150-thread-fix-prod`
3. Ajout `API_INTERNAL_URL=http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001` (etait absent du GitOps, ajoute manuellement lors de PH-04)

**Commit GitOps** : `9d9794a` pousse sur `keybuzz-infra/main`

---

## Validation E2E DEV

| Test | Attendu | Resultat |
|---|---|---|
| Conversation creee | OUI | OUI — `cmmo8o1eizada07eca044d4fa` |
| Message cree | OUI | OUI — `cmmo8o1ej944147ff0028c010` |
| Callback backend → API | status=200 | status=200 |
| Logs API [Autopilot] | Visibles | `[Autopilot] ecomlg-001 conv=... → MODE_NOT_AUTOPILOT:suggestion` |
| Pas Amazon-only | OUI | OUI — teste avec octopia et email |

**Note** : Le webhook HTTP complet (`POST /api/v1/webhooks/inbound-email`) echoue avec une erreur Prisma P2021 (`ExternalMessage` table inexistante dans la DB backend). C'est un probleme pre-existant (present aussi dans `v1.0.44`). Le test direct via `createInboxConversation()` valide le callback.

---

## Non-regression DEV

| Verification | Resultat |
|---|---|
| Backend health | 200 OK |
| API health | 200 OK |
| Conversations | open=312, pending=37, resolved=57, escalated=1 |
| Messages total | 1240 |
| Duplication messages | AUCUNE |
| Pod restarts | Backend=0, API=0 |
| Billing | Non impacte |
| Autopilot settings | Inchanges (8 tenants) |

---

## Audit PROD lecture seule

| Element PROD | Valeur |
|---|---|
| Image backend PROD | `v1.0.44-ph150-thread-fix-prod` (non modifiee) |
| API_INTERNAL_URL PROD | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:3001` |
| Port service API PROD | `80` → `targetPort 3001` |
| Mismatch | **OUI** — API_INTERNAL_URL :3001 vs Service port :80 |
| Callback effectif PROD | **ABSENT** (v1.0.44 n'a pas le code) |
| Logs [Autopilot] backend PROD | **AUCUN** |

### Port PROD incorrect documente

Le Service K8s `keybuzz-api-prod` expose le port `80` (qui route vers `targetPort 3001`). Le `API_INTERNAL_URL` PROD pointe sur `:3001`, ce qui ne correspond pas au port expose par le Service. Les connexions via le DNS du Service (`svc.cluster.local:3001`) echoueront car le Service n'ecoute que sur le port `80`.

**Correction requise lors de la promotion PROD** :
```
API_INTERNAL_URL=http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80
```

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod -n keybuzz-backend-dev
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-dev
```

---

## PROD non touchee

- AUCUNE image PROD buildee
- AUCUN manifest PROD modifie
- AUCUN `kubectl set image` PROD
- AUCUN `kubectl edit` PROD
- Image PROD : `v1.0.44-ph150-thread-fix-prod` (inchangee)

---

## Ce qui n'a PAS ete touche

- Autopilot engine (`evaluateAndExecute`) : inchange
- Routes API `/autopilot/*` : inchangees
- Routes API `/inbound/*` : inchangees
- UI / Client : inchange
- Admin : inchange
- Billing / KBActions / Stripe : inchange
- Plans, tenants, settings Autopilot : inchanges
- Tracking / metrics : inchange
- Schema DB : inchange
- keybuzz-api : inchange (lecture seule)
- PROD : inchange

---

## Notes pour la promotion PROD

1. **Corriger `API_INTERNAL_URL`** PROD vers `:80` (pas `:3001`)
2. Builder avec tag PROD : `v1.0.45-autopilot-backend-callback-prod`
3. Deployer dans `keybuzz-backend-prod`
4. Mettre a jour `keybuzz-infra/k8s/keybuzz-backend-prod/deployment.yaml`

---

## Commits source

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-backend` | `f30f621` | PH-AUTOPILOT-BACKEND-CALLBACK-01: restore connector-agnostic autopilot callback |
| `keybuzz-backend` | `8e8d40b` | fix: add stub modules for broken backfill imports (pre-existing) |
| `keybuzz-backend` | `df24693` | fix: complete stub signatures for backfill worker modules |
| `keybuzz-infra` | `9d9794a` | PH-AUTOPILOT-BACKEND-CALLBACK-01: update backend-dev manifest to v1.0.45 |

---

## Problemes pre-existants documentes (non corriges dans cette phase)

1. **ExternalMessage P2021** : La table `ExternalMessage` n'existe pas dans la DB Prisma backend (`keybuzz_backend`). Le webhook HTTP complet echoue a l'etape d'idempotence avant `createInboxConversation()`. Ce probleme est present dans `v1.0.44` egalement.

2. **Modules backfill manquants** : Les fichiers `workerResilience.ts` et `amazonBackfillWorkerAdapter.ts` etaient references par les fichiers backfill Amazon mais n'existaient pas. Des stubs ont ete crees pour permettre la compilation.

3. **Port PROD mismatch** : `API_INTERNAL_URL` PROD pointe sur `:3001` mais le Service expose `:80`.
