# PH-PLAYBOOKS-SUGGESTIONS-LIVE-04 — Rapport

> Date : 28 mars 2026
> Phase : PH-PLAYBOOKS-SUGGESTIONS-LIVE-04
> Type : Activation produit — Suggestions Playbooks live dans Inbox
> Statut : **DEV + PROD DEPLOYES — Validation Ludovic obtenue**

---

## 1. Objectif

Activer les suggestions Playbooks en temps reel dans l'Inbox, en utilisant le moteur backend existant (`playbook-engine.service.ts`), avec dedup, anti-spam, et zero auto-execution.

---

## 2. Audit pre-flight

### Constat initial

| Element | Etat |
|---|---|
| Table `playbook_suggestions` | EXISTE (11 colonnes, 0 rows) |
| `evaluatePlaybooksForConversation` dans inbound | DEJA APPELE (fire-and-forget, 2 points : email + Amazon) |
| Route `GET /playbooks/suggestions` | FONCTIONNE (200, `{"suggestions":[]}`) |
| `PlaybookSuggestionBanner.tsx` | EXISTE mais **non importe** dans InboxTripane |
| Routes BFF suggestions | EXISTENT (`GET` + `PATCH apply/dismiss`) |
| Starters actifs (PH-03) | 8/15 actifs, mode `suggest` uniquement |

### Verdict pre-flight

Le backend etait **totalement cable** mais la chaine etait incomplete :
1. Les starters etaient tous `disabled` (corrige par PH-03)
2. Le banner n'etait pas importe dans l'Inbox
3. Pas de gardes anti-spam/dedup dans le moteur

---

## 3. Modifications effectuees

### 3.1 Backend — playbook-engine.service.ts (bastion)

**Fichier** : `/opt/keybuzz/keybuzz-api/src/services/playbook-engine.service.ts`
**Backup** : `playbook-engine.service.ts.bak-ph04`

Ajout de 3 gardes anti-spam dans `evaluatePlaybooksForConversation` :

| Garde | Description |
|---|---|
| **Dedup (conversation + rule)** | Verifie si une suggestion `pending` existe deja pour le meme couple `(conversation_id, rule_id)`. Si oui, skip. |
| **Max 2 par evaluation** | `MAX_SUGGESTIONS_PER_EVAL = 2` — chaque message inbound genere au max 2 suggestions. |
| **Max 5 pending par conversation** | `MAX_PENDING_PER_CONV = 5` — une conversation ne peut pas accumuler plus de 5 suggestions en attente. |

```typescript
// PH-SUGGESTIONS-04: Anti-spam guards
const MAX_SUGGESTIONS_PER_EVAL = 2;
const MAX_PENDING_PER_CONV = 5;

const existingResult = await pool.query(
  'SELECT rule_id FROM playbook_suggestions WHERE conversation_id = $1 AND tenant_id = $2 AND status = $3',
  [context.conversationId, context.tenantId, 'pending']
);
const existingRuleIds = new Set(existingResult.rows.map((r: any) => r.rule_id));
const existingCount = existingResult.rows.length;

if (existingCount >= MAX_PENDING_PER_CONV) return [];

// In loop:
if (suggestions.length >= MAX_SUGGESTIONS_PER_EVAL) break;
if (existingCount + suggestions.length >= MAX_PENDING_PER_CONV) break;
if (existingRuleIds.has(rule.id)) continue;
```

### 3.2 Client — InboxTripane.tsx

**Fichier** : `app/inbox/InboxTripane.tsx`

1. **Import ajoute** (ligne 31) :
```typescript
import { PlaybookSuggestionBanner } from "@/src/features/inbox/components/PlaybookSuggestionBanner";
```

2. **Rendu ajoute** (entre AISuggestionsPanel et Messages) :
```tsx
<FeatureGate requiredPlan="PRO" fallback="hide">
  <PlaybookSuggestionBanner
    conversationId={selectedConversation.id}
    tenantId={currentTenantId || ''}
    onApplyReply={(text) => setReplyText(text)}
  />
</FeatureGate>
```

### 3.3 Aucune autre modification

- Pas de nouvelle table
- Pas de nouveau endpoint API
- Pas de modification BFF
- Pas de modification du composant `PlaybookSuggestionBanner.tsx` (deja complet)
- Pas de modification billing/onboarding/autopilot

---

## 4. Architecture complete du flux

```
Message entrant (Amazon / Email / Octopia)
    |
    v
inbound/routes.ts — INSERT message + COMMIT
    |
    v
evaluatePlaybooksForConversation() [fire-and-forget]
    |
    +-- getTenantPlan() → verifie plan
    +-- detectTriggers(messageBody) → keywords/synonyms/regex
    +-- [PH-04] dedup check → existingRuleIds
    +-- [PH-04] max pending check → MAX_PENDING_PER_CONV
    +-- evaluateConditions(conditions, context)
    +-- isPlanSufficient(tenantPlan, rule.min_plan)
    +-- KBA balance check (si AI actions)
    +-- INSERT INTO playbook_suggestions
    +-- [PH-04] break if MAX_SUGGESTIONS_PER_EVAL
    |
    v
playbook_suggestions (DB table)
    |
    v
GET /playbooks/suggestions?conversationId=X&tenantId=Y
    |
    v
BFF /api/playbooks/suggestions (proxy avec session auth)
    |
    v
PlaybookSuggestionBanner (Inbox UI)
    |
    +-- Accepter → PATCH /suggestions/:id/apply → KBA debit + AI Journal log
    +-- Ignorer → PATCH /suggestions/:id/dismiss
```

---

## 5. Validation DEV

### 5.1 Tests fonctionnels

| Test | Resultat |
|---|---|
| API pod Running | OK |
| Client pod Running | OK |
| API Health | `{"status":"ok"}` |
| Dedup patch deploye | OUI |
| Tracking request ("ou est ma commande") | 2 suggestions (0 KBA) |
| Duplicate (meme conversation) | 0 nouvelles suggestions (dedup OK) |
| Message neutre ("merci pour votre service") | 0 suggestions |
| Multi-trigger (retard + casse + remboursement + responsable) | 2 suggestions (max 2 respecte) |
| DB duplicates | 0 (dedup fonctionne) |
| Cleanup test data | 4 rows nettoyees |

### 5.2 Gardes anti-spam valides

| Garde | Attendu | Observe |
|---|---|---|
| Max suggestions/eval | <= 2 | 2 (OK) |
| Dedup meme conv+rule | 0 doublons | 0 (OK) |
| Message neutre | 0 suggestions | 0 (OK) |
| KBA cost starters actifs | 0 (aucune action IA payante) | 0 (OK) |

### 5.3 Non-regressions

| Composant | Etat |
|---|---|
| Inbox | OK (accessible, pas de crash) |
| AISuggestionsPanel | Toujours present (FeatureGate PRO) |
| Autopilot | Non touche |
| Billing | Non touche |
| Onboarding | Non touche |
| AI Journal | Non touche |
| PROD | **NON TOUCHE** |

---

## 6. Versions

### DEV (deploye)

| Service | Tag |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.126-playbooks-suggestions-live-dev` |

### PROD (deploye — validation Ludovic 28 mars 2026)

| Service | Tag |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.51-playbooks-suggestions-live-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.126-playbooks-suggestions-live-prod` |

---

## 7. Rollback

### DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph-tenant-iso-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.125-playbooks-engine-alignment-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# Backend source rollback
cp /opt/keybuzz/keybuzz-api/src/services/playbook-engine.service.ts.bak-ph04 /opt/keybuzz/keybuzz-api/src/services/playbook-engine.service.ts
```

### Nettoyage DB (si necessaire)

```sql
DELETE FROM playbook_suggestions WHERE status = 'pending';
```

---

## 8. Composant PlaybookSuggestionBanner — Resume

Le composant existe depuis PH27 mais n'avait jamais ete branche dans l'Inbox.

**Fonctionnalites** :
- Affiche les suggestions `pending` pour la conversation courante
- Bandeau collapsable avec nombre de suggestions
- Pour chaque suggestion :
  - Nom du playbook
  - Actions proposees (tags, labels)
  - Cout KBA (si > 0)
  - Reponse suggeree (si template)
  - Boutons Accepter / Ignorer
- Accepter : pre-remplit la zone de reponse via `onApplyReply`
- Gating : `FeatureGate requiredPlan="PRO"` (invisible pour Starter)

---

## 9. Etat PROD

**PROD PROMU — Validation Ludovic obtenue le 28 mars 2026**

Verification post-deploiement PROD :
- API PROD Health : OK (`{"status":"ok"}`, port 3001)
- Dedup patch PROD : PRESENT (MAX_SUGGESTIONS_PER_EVAL, existingRuleIds, MAX_PENDING_PER_CONV confirmes)
- Pods PROD : Running (API + Client)

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.50-ph-tenant-iso-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.125-playbooks-engine-alignment-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 10. Verdict

**PLAYBOOK SUGGESTIONS LIVE — ENGINE CONNECTED — NO SPAM — TENANT SAFE — ROLLBACK READY**
