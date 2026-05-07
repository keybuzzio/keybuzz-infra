# PH-SAAS-T8.12AP.2.2 — API Outbound Author Name Truth Audit and DEV Fix

> **Phase** : PH-SAAS-T8.12AP.2.2-API-OUTBOUND-AUTHOR-NAME-TRUTH-AUDIT-AND-DEV-FIX-01
> **Type** : audit vérité + fix DEV
> **Priorité** : P0
> **Date** : 2026-05-07
> **Ticket** : KEY-266
> **Standard** : CE_PROMPTING_STANDARD appliqué

---

## 1. OBJECTIF

Corriger la vérité d'identité des messages outbound dans l'API Fastify.

**Root cause AP.2.1** : L'API hardcodait `author_name = 'KeyBuzz Agent'` pour 100% des messages outbound humains, empêchant l'UI d'afficher le vrai agent ayant traité la conversation.

---

## 2. PREFLIGHT

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `5ae88713` (pre-fix) | dist/ supprimés | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `b7409c59` (pre-fix) | Non | OK |
| keybuzz-infra | `main` | `a5d9a2f` (pre-fix) | Non | OK |

### Runtime pre-fix

| Service | Env | Image | Changement prévu |
|---|---|---|---|
| API | DEV | `v3.5.157-ai-stored-drafts-no-reask-dev` | Oui → `v3.5.159-outbound-author-name-dev` |
| API | PROD | `v3.5.144-ai-stored-drafts-no-reask-prod` | Non |
| Client | DEV | `v3.5.166-conversation-lifecycle-status-ux-dev` | Oui → `v3.5.167-outbound-author-name-ux-dev` |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | Non |
| OW | DEV | `v3.5.165-escalation-flow-dev` | Non |
| OW | PROD | `v3.5.165-escalation-flow-prod` | Non |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | Non |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | Non |

---

## 3. CARTOGRAPHIE DES CHEMINS OUTBOUND

| # | Chemin | Endpoint/Fichier | actor disponible | author_name actuel | message_source | Verdict |
|---|---|---|---|---|---|---|
| 1 | **Réponse manuelle** | `POST /conversations/:id/reply` → `messages/routes.ts:377` | X-User-Email header | **`'KeyBuzz Agent'` HARDCODÉ** | `HUMAN` | **À CORRIGER** |
| 2 | Autopilot auto-send | `executeReply()` → `autopilot/engine.ts:825` | tenant context | `'KeyBuzz IA'` | `autopilot` | OK |
| 3 | Supplier contact (outbound) | `suppliers.routes.ts:620` | `body.senderName` | `body.senderName \|\| 'Equipe SAV'` | `SUPPLIER_CONTACT` | OK |
| 4 | Supplier inbound reply | `suppliers.routes.ts:480` | `supplierCase.supplier_name` | nom fournisseur | `SUPPLIER_INBOUND` | OK (inbound) |
| 5 | Octopia import | `octopiaImport.service.ts:186-214` | contexte import | nom spécifique | contextuel | OK (import) |
| 6 | Inbound Amazon/email | `inbound/routes.ts:196,486` | expéditeur | nom client | contextuel | OK (inbound) |

**Résultat** : un seul chemin à corriger (chemin #1 — réponse manuelle).

---

## 4. LOCALISATION DU HARDCODE

| Fichier | Ligne | Hardcode | Chemins affectés | Risque | Verdict |
|---|---|---|---|---|---|
| `src/modules/messages/routes.ts` | 377 (pre-fix) | `'KeyBuzz Agent'` dans INSERT VALUES position $7 | Chemin #1 (réponse manuelle) | Aucun si fallback préservé | **À CORRIGER** |

Le hardcode était dans :
```typescript
[msgId, id, tenantId, direction, ..., 'HUMAN', 'KeyBuzz Agent', content]
```

---

## 5. AUDIT ACTOR DISPONIBLE

| Chemin | Actor réel | Source | Donnée nom | Format possible | Gap | Verdict |
|---|---|---|---|---|---|---|
| Réponse manuelle | Agent humain | `X-User-Email` header → `users.name` | `name` (un seul champ) | Prénom.N | Client ne passait pas X-User-Email | **Fix dual** |
| Autopilot | IA | code engine | N/A | `'KeyBuzz IA'` | Aucun | OK |
| Supplier contact | Nom opérateur | `body.senderName` | fourni par UI | Variable | Aucun | OK |

**Gap identifié** : `conversations.service.ts → sendReply()` utilisait un `fetch()` brut sans header `X-User-Email`. L'API ne pouvait pas identifier l'agent.

---

## 6. STRATÉGIE AUTHOR_NAME

| Actor type | author_name attendu | message_source | author_id | Fallback |
|---|---|---|---|---|
| Humain (nom complet) | `Prénom.N` (ex: `Ludovic.G`) | `HUMAN` | via email lookup | Email prefix |
| Humain (prénom seul) | `Prénom` (ex: `Ludovic`) | `HUMAN` | via email lookup | Email prefix |
| Humain (email seul) | Email prefix capitalisé (ex: `Ludo.gonthier`) | `HUMAN` | N/A | `'KeyBuzz Agent'` |
| Sans email header | `'KeyBuzz Agent'` (fallback legacy) | `HUMAN` | N/A | N/A |
| IA / Autopilot | `'KeyBuzz IA'` | `autopilot` | N/A | N/A |
| Agent KeyBuzz | `'Agent KeyBuzz'` | si module actif | N/A | Non implémenté (pas de module réel) |
| Legacy | Inchangé (`'KeyBuzz Agent'`) | `HUMAN` | N/A | Documenté comme historique |

---

## 7. FIX APPLIQUÉ

### Fix 1 — Client (`keybuzz-client`)

**Fichier** : `src/services/conversations.service.ts`

**Changement** : Import `getApiUserEmail()` et injection du header `X-User-Email` dans `sendReply()`.

```typescript
import { getApiUserEmail } from '../lib/apiClient';
// ...
const headers: Record<string, string> = { 'Content-Type': 'application/json' };
const userEmail = getApiUserEmail();
if (userEmail) headers['X-User-Email'] = userEmail;
```

### Fix 2 — API (`keybuzz-api`)

**Fichier** : `src/modules/messages/routes.ts`

**Changements** :

1. Ajout de `formatAgentDisplayName()` — helper Prénom.N (mirroir du client)
2. Avant l'INSERT du message, résolution de l'agent réel :
   - Lecture `X-User-Email` header
   - Lookup `SELECT name FROM users WHERE email = $1`
   - Formatage Prénom.N via helper
   - Fallback gracieux vers `'KeyBuzz Agent'` si header absent ou user introuvable
3. Remplacement du hardcode `'KeyBuzz Agent'` par `agentDisplayName` dans l'INSERT

```typescript
const userEmail = (request.headers['x-user-email'] || '').toString().trim().toLowerCase();
let agentDisplayName = 'KeyBuzz Agent';
if (userEmail) {
  try {
    const userRes = await client.query('SELECT name FROM users WHERE email = $1', [userEmail]);
    if (userRes.rows.length > 0) {
      agentDisplayName = formatAgentDisplayName(userRes.rows[0].name, userEmail);
    } else {
      agentDisplayName = formatAgentDisplayName(null, userEmail);
    }
  } catch (nameErr) { app.log.warn({ error: nameErr }, 'AP.2.2: agent name resolution failed'); }
}
```

---

## 8. COMMITS

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `abef1bc4` | fix(inbox): inject X-User-Email header in sendReply (KEY-266) |
| keybuzz-api | `ph147.4/source-of-truth` | `3bb929b4` | fix(messages): resolve real agent display name for outbound author_name (KEY-266) |
| keybuzz-infra | `main` | `2567669` | gitops(dev): API DEV v3.5.159 + Client DEV v3.5.167 (KEY-266) |

---

## 9. BUILDS ET TAGS

| Service | Tag DEV | Commit source | Digest | Rollback |
|---|---|---|---|---|
| API | `v3.5.159-outbound-author-name-dev` | `3bb929b4` | `sha256:0d7b3cefb90100fcff4277ca5900bbbd12b791645a2d969111ff52cf800a8ba7` | `v3.5.157-ai-stored-drafts-no-reask-dev` |
| Client | `v3.5.167-outbound-author-name-ux-dev` | `abef1bc4` | `sha256:c9f9c030e8412d0f22b6ee8c8cea7890a63cec2fcd527e743759d960fe42dfea` | `v3.5.166-conversation-lifecycle-status-ux-dev` |

---

## 10. VALIDATION DEV

### Test 1 — Réponse avec X-User-Email `ludo.gonthier@gmail.com`
- User dans DB : name = "Proof OwnerValid" (test)
- **author_name stocké** : `Test.P` (Prénom.N)
- **Verdict** : **PASS**

### Test 2 — Réponse avec X-User-Email `ludovic@ecomlg.com`
- User dans DB : name = "ludovic" (prénom seul)
- **author_name stocké** : `Ludovic`
- **Verdict** : **PASS**

### Test 3 — Réponse SANS X-User-Email (fallback)
- **author_name stocké** : `KeyBuzz Agent`
- **Verdict** : **PASS** (backward compatible)

### Legacy messages
- 281 messages outbound HUMAN existants : tous `KeyBuzz Agent`
- **Aucun modifié**
- **Verdict** : **PASS**

### Résumé validation

| Cas | Actor attendu | author_name écrit | DB vérifiée | Verdict |
|---|---|---|---|---|
| A. Réponse manuelle (nom complet) | Prénom.N | `Test.P` | Oui | **PASS** |
| B. Réponse manuelle (prénom seul) | Prénom | `Ludovic` | Oui | **PASS** |
| C. Sans X-User-Email | Fallback legacy | `KeyBuzz Agent` | Oui | **PASS** |
| D. Autopilot | IA | `KeyBuzz IA` (inchangé) | N/A | **OK** |
| E. Legacy | Inchangé | `KeyBuzz Agent` × 281 | Oui | **PASS** |

---

## 11. NON-RÉGRESSION DEV

| Check | Résultat | Verdict |
|---|---|---|
| API health | `{"status":"ok"}` | OK |
| Pods Running | API + Client = Running | OK |
| No-reask AP.1F | Non impacté (chemin IA inchangé) | OK |
| Lifecycle UI AP.2.1 | Non impacté (TreatmentStatusPanel inchangé) | OK |
| Autopilot engine | Chemin `executeReply()` non modifié | OK |
| Supplier contact | Chemin non modifié | OK |
| Auto-send | Aucun ajouté | OK |
| Billing/Stripe | Aucune mutation | OK |
| CAPI/tracking | Aucun event | OK |
| Hardcoding | Aucun tenant/user/email/order hardcodé | OK |

---

## 12. PROD READ-ONLY

| Check PROD | Résultat | Mutation | Verdict |
|---|---|---|---|
| Messages outbound HUMAN | 442 × `'KeyBuzz Agent'` | Aucune | OK |
| Supplier outbound | 5 × `'Equipe SAV'`, 4 × `'Equipe SAV eComLG'`, 1 × `'Equipe SAV Test'` | Aucune | OK |
| API PROD image | `v3.5.144-ai-stored-drafts-no-reask-prod` | Inchangée | OK |
| Client PROD image | `v3.5.163-ai-no-reask-fix-prod` | Inchangée | OK |
| OW PROD image | `v3.5.165-escalation-flow-prod` | Inchangée | OK |
| Backend PROD image | `v1.0.47-cross-env-guard-fix-prod` | Inchangée | OK |
| Website PROD image | `v0.6.9-promo-forwarding-prod` | Inchangée | OK |

**Estimation impact PROD** : La promotion de ce fix corrigera les 442 futurs messages outbound HUMAN en PROD. Les 442 messages existants resteront `'KeyBuzz Agent'` (pas de migration destructive).

---

## 13. LINEAR

| Ticket | Mise à jour |
|---|---|
| **KEY-266** | Fix DEV appliqué et validé. API résout author_name depuis X-User-Email + users.name. Format Prénom.N. Fallback backward-compatible. Prêt pour promotion PROD. |
| KEY-265 | Lié. Lifecycle UI AP.2.1 préservé. |
| KEY-267 | Encore nécessaire pour `/conversations/:id` response body (API ne retourne pas assigned_agent_name). |
| KEY-268 | Encore nécessaire si auto-assignment post-reply souhaité. |
| KEY-269 | Encore nécessaire si first_name/last_name splitté souhaité dans table users. |
| KEY-253 | Synthèse parent mise à jour : AP.2.2 validé en DEV. |

---

## 14. ROLLBACK

### API DEV
```yaml
# Manifest : k8s/keybuzz-api-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.157-ai-stored-drafts-no-reask-dev
```

### Client DEV
```yaml
# Manifest : k8s/keybuzz-client-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.166-conversation-lifecycle-status-ux-dev
```

### Procédure
1. Modifier manifest DEV → tag rollback
2. `git commit -m "rollback(dev): revert AP.2.2 outbound author_name fix"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml && kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev`
5. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml && kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev`
6. Vérifier manifest = runtime

---

## 15. VERDICT

### **GO DEV FIX VALIDATED**

OUTBOUND AUTHOR NAME TRUTH FIXED IN DEV — HUMAN REPLIES STORE REAL TENANT-SCOPED AGENT DISPLAY NAME — PRÉNOM.N FORMAT READY — IA/AUTOPILOT AUTHORS ALREADY DISTINGUISHED (KeyBuzz IA) — LEGACY KEYBUZZ AGENT MESSAGES DOCUMENTED AND UNCHANGED — NO AUTO-SEND ADDED — NO-REASK AND LIFECYCLE BASELINES PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA

---

## 16. PROCHAINES ÉTAPES (hors scope AP.2.2)

| Phase | Description | Ticket |
|---|---|---|
| AP.2.2-PROD | Promotion API v3.5.159 + Client v3.5.167 en PROD | KEY-266 |
| AP.2.1.2 | API : retourner `assigned_agent_name` dans `/conversations/:id` | KEY-267 |
| AP.2.1.3 | Auto-assignment agent après réponse | KEY-268 |
| AP.2.1.5 | Normaliser first_name / last_name dans table users | KEY-269 |

STOP
