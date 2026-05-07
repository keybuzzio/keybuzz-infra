# PH-SAAS-T8.12AP.1E — AI Stored Drafts No-Reask Invalidation — DEV

> **Date** : 2026-05-07
> **Phase** : PH-SAAS-T8.12AP.1E-AI-STORED-DRAFTS-NO-REASK-INVALIDATION-DEV-01
> **Environnement** : DEV uniquement
> **Type** : Audit vérité + fix DEV
> **Priorité** : P0
> **Standard appliqué** : CE_PROMPTING_STANDARD.md + RULES_AND_RISKS.md

---

## Résumé

Traitement du dernier gap no-reask : les anciens brouillons IA automatiques stockés dans `ai_action_log` avant le fix AP.1D contenaient encore des formulations demandant commande/suivi alors que KeyBuzz connaissait déjà ces données.

**Root cause** : Le handler GET `/autopilot/draft` retournait le dernier brouillon stocké sans vérifier si son contenu était cohérent avec le contexte actuel de la conversation. Un brouillon généré avant le fix AP.1C/1D pouvait demander "communiquer votre numéro de commande" alors que `conversations.order_ref` existait déjà.

**Fix retenu** : Invalidation à la lecture (Option A). Aucune suppression DB, aucune mutation, aucun auto-send.

---

## Preflight

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `49ff3440` | src/ propre avant fix | **OK** |
| keybuzz-infra | `main` | `2a0d009` | — | **OK** |

### Runtimes avant fix

| Service | Env | Image avant | Changement |
|---|---|---|---|
| API | DEV | `v3.5.156-ai-auto-draft-no-reask-dev` | → `v3.5.157-ai-stored-drafts-no-reask-dev` |
| API | PROD | `v3.5.143-ai-auto-draft-no-reask-prod` | **AUCUN** |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | **AUCUN** |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | **AUCUN** |

---

## Cartographie du stockage des brouillons IA

| Table | Colonnes utiles | Source écriture | Source lecture | Utilisée par UI | Verdict |
|---|---|---|---|---|---|
| `ai_action_log` | `id`, `tenant_id`, `conversation_id`, `action_type` (`autopilot_reply`/`autopilot_escalate`), `status`, `blocked_reason`, `confidence_score`, `payload` (JSON avec `draftText`), `created_at` | `autopilot/engine.ts` via `logAction()` | `autopilot/routes.ts` GET `/draft` | Oui — InboxTripane → AISuggestionSlideOver | **Source unique** |

### Flux complet

```
engine.ts → evaluateAndExecute() → LLM génère suggestion → logAction() INSERT INTO ai_action_log
↓
routes.ts → GET /autopilot/draft → SELECT FROM ai_action_log ORDER BY created_at DESC LIMIT 1
↓
BFF → app/api/autopilot/draft/route.ts → fetch cache: 'no-store'
↓
InboxTripane.tsx → setAutopilotDraft() → AISuggestionSlideOver initialDraft={autopilotDraft}
```

### Critères de sélection du draft

```sql
WHERE tenant_id = $1 AND conversation_id = $2
  AND action_type LIKE 'autopilot_%'
  AND (
    (status = 'skipped' AND (blocked_reason = 'DRAFT_GENERATED' OR blocked_reason LIKE 'ESCALATION_DRAFT%'))
    OR status = 'completed'
  )
  AND payload::text LIKE '%draftText%'
ORDER BY created_at DESC
LIMIT 1
```

**Aucun mécanisme de versioning ou staleness** avant ce fix.

---

## Audit des brouillons obsolètes

| Env | Total drafts | Suspects reask | Conversations affectées | Pré-fix (avant 7 mai) | Post-fix |
|---|---|---|---|---|---|
| **DEV** | 102 | 32 | — | 102 (100%) | 0 |
| **PROD** | 25 | 8 | 7 | 25 (100%) | 0 |

**Patterns détectés dans les suspects** :
- "pourriez-vous me communiquer votre numéro de commande"
- "pourriez-vous me communiquer votre numéro de commande ou de suivi"
- "me fournir votre numéro de commande"
- "me communiquer votre numéro de commande"

---

## Stratégie retenue

| Option | Avantage | Risque | Mutation DB | Recommandation |
|---|---|---|---|---|
| **A. Invalidation lecture (API)** | Robuste, zero suppression, future-proof, pas de schema change | +1 requête SQL par draft suspect | NON | **RETENU** |
| B. Version policy metadata | Clean, versionnable | Schema change, migration DB | OUI | Trop lourd |
| C. Régénération bulk | Résout immédiatement | Auto-send risk, coût KBActions | OUI | NON — trop risqué |
| D. Marquage UI seul | Simple | Ne protège pas si client ignoré | NON | Insuffisant seul |

### Principe du fix

1. Draft récupéré normalement depuis `ai_action_log`
2. Analyse du texte contre 8 patterns reask (regex insensible à la casse)
3. Si pattern détecté → vérification SQL : la conversation a-t-elle un `order_ref` connu ?
4. Si `conversations.order_ref IS NOT NULL` → le draft est invalidé, retour `hasDraft: false`
5. Si pas d'`order_ref` → le draft est affiché (la demande d'info est légitime)

```
REASK_PATTERNS:
  /communiquer votre num/i
  /fournir votre num/i
  /transmettre votre num/i
  /indiquer votre num/i
  /votre num[eé]ro de commande/i
  /votre num[eé]ro de suivi/i
  /pourriez-vous.*num[eé]ro/i
  /me communiquer votre/i
```

---

## Fix API

### Fichier modifié

`src/modules/autopilot/routes.ts` — handler GET `/autopilot/draft` (lignes 252-280)

### Changement

+32 lignes insérées entre le check `!payload.draftText` et la section `PH142-E`.

### Logique

```
if (draftText matches REASK_PATTERNS) {
  → query conversations + orders for order_ref
  → if order_ref exists → return { hasDraft: false, staleReason: 'reask_with_known_data', canRegenerate: true }
}
```

---

## Build DEV

| Élément | Valeur |
|---|---|
| Commit source | `5ae88713` |
| Message | `fix(ai): stale draft invalidation — reask patterns blocked when order/tracking is known (PH-SAAS-T8.12AP.1E, KEY-256)` |
| Tag DEV | `v3.5.157-ai-stored-drafts-no-reask-dev` |
| Registry digest | `sha256:7c4bd81e3b2ddcd0d4d3b87d5eae51003154787d064ca512378f34f23ac392e0` |
| Rollback | `v3.5.156-ai-auto-draft-no-reask-dev` |
| Build depuis Git propre | ✅ |
| Aucun secret leak | ✅ |

---

## GitOps DEV

| Élément | Valeur |
|---|---|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Commit GitOps | `1dcf5ed` |
| Message | `gitops(dev): PH-SAAS-T8.12AP.1E API DEV v3.5.157-ai-stored-drafts-no-reask-dev (KEY-256)` |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |
| Pod | `keybuzz-api-9fb48cff7-l7cv6` — Running, 0 restart |

---

## Validation DEV

### Tests structurels

| Signal | Présent | Verdict |
|---|---|---|
| AP.1E marker dans dist | ✅ L208-231 | **OK** |
| REASK_PATTERNS dans dist | ✅ | **OK** |
| staleReason dans dist | ✅ | **OK** |
| Health API DEV | `{"status":"ok"}` | **OK** |
| 0 restarts | ✅ | **OK** |

### Tests fonctionnels live

| Cas | order_ref | Pattern reask | Résultat API | Verdict |
|---|---|---|---|---|
| A. Suspect + order connu (`cmmopx7bdb7d1e19fa73be914`) | `171-8133751-3047512` | ✅ "communiquer votre numéro" | `hasDraft: false, staleReason: reask_with_known_data` | **INVALIDÉ (correct)** |
| B. Suspect + pas d'order (`cmmnu2onxb53e59de0946a2b7`) | `null` | ✅ "communiquer votre numéro" | `hasDraft: true` (draft montré) | **AFFICHÉ (correct)** |
| C. Non-suspect (`cmmos9k7x2e4146f88dcf8a58`) | — | Non | `hasDraft: true` | **AFFICHÉ (correct)** |
| D. Aide IA (surface A) | — | — | Client `v3.5.163` inchangé | **OK** |
| E. Plan gates | — | — | Non modifiés par ce fix | **OK** |

---

## PROD Read-Only Check

| Check PROD | Résultat | Mutation | Verdict |
|---|---|---|---|
| Total drafts PROD | 25 | NON | **OK** |
| Suspects PROD | 8 (7 conversations) | NON | **Documenté** |
| API PROD image | `v3.5.143-ai-auto-draft-no-reask-prod` | AUCUN changement | **OK** |
| Client PROD | `v3.5.163-ai-no-reask-fix-prod` | AUCUN changement | **OK** |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | AUCUN changement | **OK** |

**Impact PROD estimé** : 8 brouillons suspects sur 7 conversations. Après promotion PROD du fix AP.1E, ces brouillons seront automatiquement invalidés à la lecture si la conversation a un `order_ref` connu.

---

## Non-Régression

| Surface | Check | Résultat | Verdict |
|---|---|---|---|
| API health DEV | `{"status":"ok"}` | OK | **OK** |
| Pod Running, 0 restart | ✅ | — | **OK** |
| PROD inchangée | Images identiques avant/après | — | **OK** |
| 0 outbound envoyé | — | — | **OK** |
| 0 auto-send | — | — | **OK** |
| 0 billing mutation | — | — | **OK** |
| 0 CAPI | — | — | **OK** |
| 0 DB mutation PROD | — | — | **OK** |

---

## Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `5ae88713` | fix(ai): stale draft invalidation — reask patterns blocked when order/tracking is known (AP.1E, KEY-256) |
| keybuzz-infra | `main` | `1dcf5ed` | gitops(dev): API DEV `v3.5.157-ai-stored-drafts-no-reask-dev` (KEY-256) |

---

## Images

| Service | Env | Tag | Digest |
|---|---|---|---|
| API | DEV | `v3.5.157-ai-stored-drafts-no-reask-dev` | `sha256:7c4bd81e3b2ddcd0d4d3b87d5eae51003154787d064ca512378f34f23ac392e0` |
| API (rollback DEV) | DEV | `v3.5.156-ai-auto-draft-no-reask-dev` | — |

---

## Aucun hardcoding

- Aucun tenant ID hardcodé
- Aucun user/email hardcodé
- Aucun seller/order/tracking hardcodé
- Aucun marketplace/pays hardcodé

---

## Rollback GitOps strict

Si rollback DEV nécessaire :

1. Modifier `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` :
   ```
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.156-ai-auto-draft-no-reask-dev
   ```
2. `git commit` + `git push`
3. `kubectl apply -f`
4. `kubectl rollout status`
5. Vérifier manifest = runtime

---

## Linear

| Ticket | Action |
|---|---|
| KEY-256 | Fix AP.1E : invalidation brouillons obsolètes en DEV. Stale drafts avec reask patterns sont filtrés à la lecture quand `order_ref` connu. Test live confirmé. PROD promotion requise. |
| KEY-253 | AP.1A→1E complétés. AP.1E = dernier gap no-reask (stored drafts). |
| KEY-262 | Fix serveur complété en DEV — couvre désormais : génération (AP.1C) + lecture (AP.1E) |

---

## PROD inchangée

| Service | Image PROD | Touché par AP.1E |
|---|---|---|
| API | `v3.5.143-ai-auto-draft-no-reask-prod` | **NON** |
| Client | `v3.5.163-ai-no-reask-fix-prod` | **NON** |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | **NON** |
| Website | `v0.6.9-promo-forwarding-prod` | **NON** |
| DB PROD | Aucune mutation | **NON** |
| Stripe | Aucune mutation | **NON** |

---

## Verdict

### **GO DEV FIX VALIDATED — PROD PROMOTION REQUIRED**

- Fix validé en DEV : brouillons suspects avec `order_ref` connu sont invalidés à la lecture
- Brouillons suspects sans `order_ref` restent affichés (demande légitime)
- Brouillons non-suspects restent affichés normalement
- Aucune suppression DB, aucun auto-send, aucune mutation PROD
- Plan gates préservés
- Non-régression complète
- **Prochaine étape** : promotion PROD (AP.1F) du fix `v3.5.157-ai-stored-drafts-no-reask-dev`

---

## Phrase cible

AI STORED DRAFTS NO-REASK HANDLED IN DEV — OLD PREFIX DRAFTS NO LONGER SHOWN AS VALID SUGGESTIONS WHEN ORDER DATA KNOWN — NEW AUTOMATIC DRAFTS USE KNOWN ORDER/TRACKING DATA — AIDE IA REMAINS VALID — HUMAN VALIDATION PRESERVED — NO AUTO-SEND — PLAN GATES PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION

---

STOP
