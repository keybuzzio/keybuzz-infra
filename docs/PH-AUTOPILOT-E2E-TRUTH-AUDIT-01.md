# PH-AUTOPILOT-E2E-TRUTH-AUDIT-01 — TERMINE

> Date : 2026-04-21
> Type : audit E2E complet Autopilot (client + BFF + API + consume)
> Environnement : DEV + PROD
> Aucune modification effectuee

---

## Verdict : NO GO — cause racine = plan gate

L'autopilot ne peut PAS fonctionner pour le tenant `ecomlg-001` car
le plan PRO est bloque par `ai-mode-engine.ts`. Le plan minimum requis est AUTOPILOT.

---

## 1. Preflight

### Images deployees

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.91-autopilot-escalation-handoff-fix-dev` | `v3.5.91-autopilot-escalation-handoff-fix-prod` |
| Client | `v3.5.83-linkedin-replay-dev` | `v3.5.81-tiktok-attribution-fix-prod` |

### Source

| Repo | Branche | HEAD |
|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `7265d29a` |
| keybuzz-client | `ph148/onboarding-activation-replay` | `bad2e22` |

### Tenant pilote

| Env | Tenant | Plan DB | Billing exempt |
|---|---|---|---|
| DEV | `ecomlg-001` | `pro` | oui (`internal_admin`) |
| PROD | `ecomlg-001` | `PRO` | oui (`internal_admin`) |

---

## 2. Matrice E2E DEV / PROD

| Env | Cas | Draft visible ? | Volet auto ? | Consume OK ? | Handoff visible ? |
|---|---|---|---|---|---|
| DEV | Cas 1 — inbound real (ecomlg-001) | NON — `MODE_NOT_AUTOPILOT:suggestion` | NON | N/A | N/A |
| DEV | Cas 1 — inbound real (switaa, plan AUTOPILOT) | OUI | OUI | OUI | OUI |
| DEV | Cas 2 — consume non-escalade (switaa) | N/A | N/A | OUI (`DRAFT_APPLIED`) | N/A |
| DEV | Cas 3 — consume ESCALATION_DRAFT (switaa) | N/A | N/A | OUI (`DRAFT_APPLIED`) | OUI (status pending) |
| PROD | Cas 1 — inbound real (ecomlg-001) | NON — `MODE_NOT_AUTOPILOT:suggestion` | NON | N/A | N/A |
| PROD | Cas 2 — non disponible | N/A | N/A | N/A | N/A |
| PROD | Cas 3 — non disponible | N/A | N/A | N/A | N/A |

### Preuve log DEV

```
[Autopilot] ecomlg-001 conv=cmmmkpduzza1bf79b738a6953 → MODE_NOT_AUTOPILOT:suggestion
[Autopilot] switaa-sasu-mnc1x4eq conv=cmmo8bqqa44c9f4bda90f4eac → ESCALATION_DRAFT (safe_mode)
[Autopilot] switaa-sasu-mnc1x4eq conv=cmmo8cmf8z827c3947a0df23c → DRAFT_GENERATED (safe_mode)
```

### Conclusion matrice

L'autopilot fonctionne correctement pour les tenants plan AUTOPILOT (`switaa`).
Il est bloque des le Step 2 du pipeline pour les tenants plan PRO (`ecomlg-001`).

---

## 3. Client DEV vs PROD

| Element client | DEV | PROD | Aligne ? |
|---|---|---|---|
| Image | `v3.5.83-linkedin-replay-dev` | `v3.5.81-tiktok-attribution-fix-prod` | NON (versions differentes) |
| BFF `/api/autopilot/draft/route.ts` | Present + compile | Present + compile | OUI |
| BFF `/api/autopilot/draft/consume/route.ts` | Present + compile | Present + compile | OUI |
| `AISuggestionSlideOver.tsx` | Present | Present | OUI |
| `InboxTripane.tsx` — auto-open logic | Present (PH143-E.4) | Present | OUI |
| `InboxTripane.tsx` — EscalationBadge | Present (PH123) | Present | OUI |
| `InboxTripane.tsx` — consumeDraft | Present | Present | OUI |
| baseUrl (chunk 1990) | `api-dev.keybuzz.io` | `api.keybuzz.io` | OUI (correct) |

### Le client PROD contient-il les fixes PH147.5 / PH152.2 ?

**OUI.** Les routes BFF (`app/api/autopilot/draft/route.ts`, `app/api/autopilot/draft/consume/route.ts`)
et les composants UI (`AISuggestionSlideOver`, `InboxTripane` auto-open) sont presents
et compiles dans les deux pods. Le code est fonctionnellement identique.

Les versions client differentes (`v3.5.83` DEV vs `v3.5.81` PROD) ne different que sur
les features tracking (LinkedIn vs TikTok) — aucune regression autopilot.

---

## 4. BFF

| Route BFF | DEV | PROD | OK ? |
|---|---|---|---|
| `GET /api/autopilot/draft` | Compile, route fonctionnelle | Compile, route fonctionnelle | OUI |
| `POST /api/autopilot/draft/consume` | Compile, route fonctionnelle | Compile, route fonctionnelle | OUI |
| Auth headers (`X-User-Email`, `X-Tenant-Id`) | Forwarded via session | Forwarded via session | OUI |
| Backend URL | `keybuzz-api.keybuzz-api-dev.svc:3001` | `keybuzz-api.keybuzz-api-prod.svc:80` | OUI |

### Tests API directs

| Endpoint API | DEV | PROD | OK ? |
|---|---|---|---|
| `GET /autopilot/draft` (sans conversationId) | `{"error":"conversationId required"}` | `{"error":"conversationId required"}` | OUI |
| `GET /autopilot/draft` (conv test avec draft) | `{"hasDraft":true, ...}` | `{"hasDraft":true, ...}` | OUI |
| `GET /autopilot/draft` (conv reelle pending) | `{"hasDraft":false}` | N/A | OUI (aucun draft genere) |
| `GET /autopilot/settings` | OK | OK | OUI |

---

## 5. API/DB

### Autopilot settings DEV vs PROD

| Parametre | DEV | PROD | Ecart |
|---|---|---|---|
| `is_enabled` | true | true | - |
| `mode` | supervised | supervised | - |
| `allow_auto_reply` | **true** | **false** | OUI |
| `allow_auto_escalate` | **true** | **false** | OUI |
| `safe_mode` | true | true | - |
| `escalation_target` | client | client | - |

**Impact de l'ecart** : AUCUN — ces parametres ne sont jamais atteints car le plan gate
bloque l'execution AVANT (Step 2-3). Si le plan etait AUTOPILOT, cet ecart affecterait
le comportement en mode autonome uniquement.

### ai_action_log — activite autopilot recente

| Tenant | Env | Entries reelles | Entries test | Derniere activite |
|---|---|---|---|---|
| `ecomlg-001` | DEV | 0 reelles, 1 `MODE_NOT_AUTOPILOT` log | 5 test manuels | 10 avr (test) |
| `ecomlg-001` | PROD | 0 | 2 test manuels | 10 avr (test) |
| `switaa-sasu-mnc1x4eq` | DEV | **10+ reelles** | 0 | 21 avr 08:15 (actif) |

### Conversations PROD avec activite autopilot reelle

| Conv | Status | Autopilot entries |
|---|---|---|
| `conv-shopify-test-prod-001` | resolved | 1 (test injecte manuellement) |
| Toute autre conversation | N/A | **ZERO** |

### Le pipeline evaluateAndExecute pour ecomlg-001

```
Step 1: Load settings → OK (is_enabled=true)
Step 2: resolveIAMode → plan=PRO → caps.maxMode='suggestion'
Step 3: canUseAutopilot({mode:'suggestion'}) → FALSE
→ RETURN noopResult('MODE_NOT_AUTOPILOT:suggestion')
```

Le pipeline s'arrete au Step 3. Les Steps 4-12 (guardrails, LLM, draft, debit) ne sont
JAMAIS executes.

---

## 6. Causes racines

### Cause A — Plan gate (PRINCIPALE, BLOQUANTE)

**Fichier** : `src/modules/ai/ai-mode-engine.ts`

**Mecanisme** :

```typescript
PRO: {
    canSuggest: true,
    canAutoReply: false,
    maxMode: 'suggestion',   // ← BLOQUE L'AUTOPILOT
}

AUTOPILOT: {
    canSuggest: true,
    canAutoReply: true,
    maxMode: 'autonomous',   // ← SEUL PLAN QUI PASSE
}
```

```typescript
function canUseAutopilot(resolution) {
  return (resolution.mode === 'supervised' || resolution.mode === 'autonomous')
    && !resolution.blocked;
}
```

Pour le plan PRO, `resolvedMode` est force a `'suggestion'` → `canUseAutopilot` retourne
`false` → le moteur autopilot ne genere JAMAIS de draft → le volet ne s'ouvre JAMAIS.

**Preuve** : log DEV `ecomlg-001 → MODE_NOT_AUTOPILOT:suggestion`

**Impact** : 100% — aucun draft, aucun volet, aucun consume, aucune escalade possible.

### Cause B — Client PROD non aligne ?

**NON.** Les BFF routes et composants UI sont presents et fonctionnels dans les deux
environments. Les versions client differentes (`v3.5.83` vs `v3.5.81`) ne concernent que
le tracking marketing. Pas de regression autopilot client.

### Cause C — BFF PROD casse ?

**NON.** Les routes `/api/autopilot/draft` et `/api/autopilot/draft/consume` repondent
correctement dans les deux environnements.

### Cause D — Consume ESCALATION_DRAFT pas reellement valide ?

**PARTIELLEMENT.** Le fix `status = 'pending'` (PH-ESCALATION-HANDOFF-FIX-01) est en place
et compile, mais il n'a JAMAIS ete teste E2E sur une conversation reelle car aucun draft
n'est genere pour `ecomlg-001`. Les seuls tests ont ete faits sur des conversations
synthetiques injectees manuellement (`conv-shopify-test-*`).

### Cause E — Ecart autopilot_settings DEV vs PROD

**SECONDAIRE, MASQUE.** `allow_auto_reply=false` et `allow_auto_escalate=false` en PROD
n'ont aucun impact actuel car le plan gate bloque avant. Si le plan etait AUTOPILOT,
cet ecart affecterait le comportement (pas d'envoi automatique en PROD, uniquement des drafts).

---

## 7. Plan recommande

### Scope API — Fix plan gate (OBLIGATOIRE)

**Option A** : Changer le plan de `ecomlg-001` de `PRO` a `AUTOPILOT` en DB.
C'est la correction la plus rapide et la plus coherente avec la matrice des plans.

```sql
UPDATE tenants SET plan = 'AUTOPILOT' WHERE id = 'ecomlg-001';
```

**Option B** : Modifier `PLAN_CAPABILITIES.PRO.maxMode` de `'suggestion'` a `'supervised'`.
Cela permettrait le mode supervise (drafts) pour TOUS les tenants PRO.
C'est une decision produit majeure — affecter tous les PRO clients.

**Recommandation** : Option A (changement plan DB) pour le tenant pilote,
puis decision produit pour generaliser en Option B si souhaite.

### Scope API — Aligner autopilot_settings (SECONDAIRE)

Apres changement de plan, aligner les settings PROD avec DEV :

```sql
UPDATE autopilot_settings
SET allow_auto_reply = true, allow_auto_escalate = true
WHERE tenant_id = 'ecomlg-001';
```

### Scope Client — aucun changement necessaire

Le code client est correct et fonctionnel.

### Scope BFF — aucun changement necessaire

Les routes BFF sont correctes et fonctionnelles.

---

## 8. Conclusion

La cause racine du probleme autopilot est une **incompatibilite de plan** :
le tenant pilote `ecomlg-001` est en plan PRO, mais l'autopilot requiert le plan AUTOPILOT.

Le moteur autopilot, le trigger inbound, les BFF routes, les composants client UI,
le fix escalation handoff — tout est en place et fonctionnel. Mais tout est inatteignable
car le plan gate bloque l'execution au tout debut du pipeline.

La preuve definitive est le tenant `switaa-sasu-mnc1x4eq` (plan AUTOPILOT) qui recoit
des drafts, des escalades, et des consumes en production reelle sur DEV.

### Aucune modification effectuee dans cette phase.

---

**AUTOPILOT E2E TRUTH ESTABLISHED**

**STOP**
