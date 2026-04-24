# PH-AUTOPILOT-CONSUME-PROMISE-ESCALATION-TRUTH-01

> **Date** : 2026-04-21
> **Auteur** : Agent Cursor
> **Phase** : Audit vérité — validation draft avec promesse d'escalade sans handoff
> **Environnement** : PROD + DEV lecture seule
> **Priorité** : P0
> **Verdict** : AUTOPILOT CONSUME PROMISE ESCALATION ROOT CAUSE IDENTIFIED

---

## 0. PRÉFLIGHT

| Élément | Valeur | Attendu | OK |
|---|---|---|---|
| Image API PROD | `v3.5.91-autopilot-escalation-handoff-fix-prod` | `v3.5.91-autopilot-escalation-handoff-fix-prod` | ✅ |
| Image Backend PROD | `v1.0.46-ph-recovery-01-prod` | `v1.0.46-ph-recovery-01-prod` | ✅ |
| Repo API (bastion) | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | ✅ |
| HEAD API | `7265d29a` | — | ✅ |
| Repo API clean | 1 fichier `.bak` non-tracké | — | ✅ |
| Pod API PROD | `keybuzz-api-768bfdc995-srhgg` (Running, 0 restarts, 7h56m) | — | ✅ |
| Pod Backend PROD | `keybuzz-backend-5dc6c84db9-v2vmb` (Running, 0 restarts, 36m) | — | ✅ |
| Tenants AUTOPILOT | `switaa-sasu-mnc1ouqu`, `compta-ecomlg-gmail--mnvu4649`, `ecomlg-mn3rdmf6`, `switaa-sasu-mn9c3eza` | — | ✅ |

---

## 1. CAS PROD UTILISATEUR IDENTIFIÉ

### Cas principal : `cmmo8sz5rd8f173c865e32cb4` (SWITAA SASU, PROD, 21 avril 2026)

| Élément | Valeur |
|---|---|
| Tenant | `switaa-sasu-mnc1ouqu` (AUTOPILOT) |
| Conversation ID | `cmmo8sz5rd8f173c865e32cb4` |
| Sujet | Commande 333-33333333-333 |
| Canal | amazon |
| Draft ai_action_log ID | `alog-1776786792225-wueksronl` |
| Draft type (blocked_reason) | `DRAFT_GENERATED` |
| Draft content contient promesse ? | **OUI** — "je transmets immédiatement" |
| Consume appelé ? | **OUI** — `consumedAt: 2026-04-21 15:53:43` |
| Outbound message ID | `msg-1776786824075-2l9sfztr5` |
| Escalation visible ? | **NON** — `escalation_status = 'none'` |

### Cas secondaires (même pattern)

| Conv ID | Tenant | Draft type | Promesse | Escalation | ConsumedAt |
|---|---|---|---|---|---|
| `cmmo8sivoaa2ec941425f3583` | SWITAA | `DRAFT_GENERATED` | "je transmettrai" | `none` ❌ | 15:51:23 |
| `cmmnu11w228e189ae24ec1542` | SWITAA | `DRAFT_GENERATED` | "je vérifierai" | `none` ❌ | 2026-04-11 |

### Cas de référence FONCTIONNEL (escalade réussie)

| Conv ID | Tenant | Draft type | Promesse | Escalation | ConsumedAt |
|---|---|---|---|---|---|
| `conv-4837f801` | SWITAA | `ESCALATION_DRAFT:0.75` | "je vais m'assurer" | `escalated` ✅ | 2026-04-20 21:28 |

---

## 2. CLASSIFICATION DU DRAFT

### Draft texte complet (`cmmo8sz5rd8f173c865e32cb4`)

```
Bonjour,

Je comprends votre préoccupation concernant votre article récupéré pour réparation.

Concernant votre commande 333-33333333-333 avec le colis 1Z121122512368, je transmets immédiatement
votre demande à notre équipe qui va vérifier le statut de la réparation et vous recontacter rapidement
avec une mise à jour.

Je note que plusieurs jours se sont écoulés sans nouvelle, ce qui est effectivement préoccupant. Notre
équipe va investiguer cette situation et s'assurer que vous receviez un suivi détaillé dans les plus
brefs délais.

Votre dossier est désormais prioritaire et vous devriez recevoir une réponse sous 24h maximum.

Cordialement,
Ludovic Ludovic
SWITAA SASU
```

### Promesses identifiées par lecture humaine

| Expression | Type de promesse | Détectée par engine ? | Détectée par reply PH143-E.8 ? |
|---|---|---|---|
| "je transmets immédiatement" | présent indicatif | **NON** | **NON** |
| "notre équipe qui va vérifier" | 3ème personne futur immédiat | **NON** | **NON** |
| "vous recontacter rapidement" | infinitif après conjonction | **NON** | **NON** |
| "Notre équipe va investiguer" | 3ème personne futur immédiat | **NON** | **NON** |
| "s'assurer que vous receviez" | infinitif réflexif | **NON** | **NON** |

### Tableau classification

| Champ | Valeur |
|---|---|
| action_type | `autopilot_reply` |
| status | `skipped` → `DRAFT_APPLIED` (après consume) |
| blocked_reason | `DRAFT_GENERATED` (original) → `DRAFT_APPLIED` (après consume) |
| confidence | `0.75` |
| escalation reason | *aucune* (car DRAFT_GENERATED) |
| draft contient promesse | **OUI** — 5 expressions |
| classification correcte ? | **NON** — devrait être `ESCALATION_DRAFT` |

---

## 3. AUDIT DU CONSUME

### Flux complet tracé

```
1. UI: "Valider et envoyer" (AISuggestionSlideOver.tsx l.612)
   → appels parallèles:
     a. onDirectSend(draftText) → sendReply() → POST /messages/conversations/:id/reply
     b. consumeDraft('applied') → POST /api/autopilot/draft/consume → API /autopilot/draft/consume
```

### Consume path détaillé (autopilot/routes.ts l.270-368)

| Étape | Résultat | Preuve |
|---|---|---|
| BFF consume | ✅ appelé | `app/api/autopilot/draft/consume/route.ts` |
| API consume | ✅ exécuté | `consumedAt: 2026-04-21 15:53:43` |
| `wasEscalationDraft` | **FALSE** | `blocked_reason = 'DRAFT_GENERATED'` ne commence pas par `ESCALATION_DRAFT` |
| Update `ai_action_log` | ✅ → `DRAFT_APPLIED` | `summary: DRAFT_APPLIED` |
| `draft_applied` log créé | ✅ | audit trail inséré |
| Escalation DB écrite ? | **NON** — `wasEscalationDraft = false` | `escalation_status = 'none'` |
| `status = 'pending'` écrit ? | **NON** — code ignoré | seul chemin si `wasEscalationDraft && action === 'applied'` |
| `message_events` autopilot_escalate | **NON** | aucun event `autopilot_escalate` |

### Reply path détaillé (messages/routes.ts)

| Étape | Résultat | Preuve |
|---|---|---|
| `sendReply()` appelé | ✅ | `onDirectSend` dans InboxTripane.tsx l.1572 |
| Outbound message créé | ✅ | `msg-1776786824075-2l9sfztr5` |
| `status = 'open'` | ✅ | conversation `status = 'open'` |
| `message_events` reply | ✅ | `evt-1776786824102-kat5lrdyx` type=reply |
| PH143-E.8 promise scan | ✅ exécuté | patterns testés |
| Patterns matched | **ZÉRO** | "je transmets" ≠ `/je vais transmettre/i` |
| Escalation par reply | **NON** | `escalation_status = 'none'` |

---

## 4. AUDIT PROMISE DETECTION

### Trois systèmes de détection indépendants

| Système | Fichier | Patterns | Portée |
|---|---|---|---|
| **Engine** `detectFalsePromises` | `engine.ts` l.141-160 | 14 regex | Classification draft avant stockage |
| **Reply** PH143-E.8 | `messages/routes.ts` l.533-596 | 22 regex | Filet de sécurité après envoi |
| **Aide IA** PH142-C | `ai-assist-routes.ts` l.466-480 | 9 regex | Auto-escalade après suggestion |

### Lacune fondamentale partagée

**Tous les patterns sont ancrés sur "je vais + infinitif" (futur immédiat).** Aucun ne couvre :

| Forme verbale | Exemple | Couvert ? |
|---|---|---|
| Présent indicatif | "je transmets", "je vérifie" | **NON** |
| Futur simple | "je transmettrai", "je vérifierai" | **NON** |
| 3ème personne | "notre équipe va vérifier" | **NON** |
| Réflexif sans "je vais" | "s'assurer que" | **NON** |
| Infinitif après conjonction | "et vous recontacter" | **NON** |
| Futur immédiat "je vais" | "je vais transmettre" | **OUI** ✅ |

### Test empirique PROD — résultat formel

```
Conv: cmmo8sz5rd8f173c865e32cb4
  Texte: "je transmets immédiatement votre demande à notre équipe qui va vérifier..."
  Engine patterns matched: 0  []
  Reply  patterns matched: 0  []
  Patterns IDÉAUX (catch): 2  ['je transmets (present)', 'recontacter']

Conv: cmmo8sivoaa2ec941425f3583
  Texte: "je transmettrai votre dossier à notre équipe qui effectuera..."
  Engine patterns matched: 0  []
  Reply  patterns matched: 0  []
  Patterns IDÉAUX (catch): 3  ['je transmettrai (futur)', 'recontacter', 'effectuera']

Conv: cmmnu11w228e189ae24ec1542
  Texte: "je vérifierai auprès du transporteur... nous organiserons une nouvelle livraison"
  Engine patterns matched: 0  []
  Reply  patterns matched: 0  []
  Patterns IDÉAUX (catch): 2  ['je vérifie/vérifierai', 'nous organiserons']
```

### Matrice des 4 flows

| Flow | Promise detection appelée ? | Patterns matchent le cas PROD ? | Escalade écrite ? |
|---|---|---|---|
| Aide IA (PH142-C) | ✅ OUI | Dépend du verbe | ✅ si match |
| Reply classique (PH143-E.8) | ✅ OUI | **NON** pour formes non "je vais" | ❌ |
| Autopilot consume `DRAFT_GENERATED` | ❌ NON (pas de re-détection) | N/A | ❌ |
| Autopilot consume `ESCALATION_DRAFT` | ❌ NON (mais escalade directe) | N/A | ✅ par design |

---

## 5. DB AVANT / APRÈS (conv `cmmo8sz5rd8f173c865e32cb4`)

| Champ | Avant consume | Après consume |
|---|---|---|
| `conversations.status` | `pending` | `open` (reply flow) |
| `escalation_status` | `null` / `none` | **`none`** ❌ |
| `escalation_reason` | `null` | **`null`** ❌ |
| `escalated_at` | `null` | **`null`** ❌ |
| `escalated_by_type` | `null` | **`null`** ❌ |
| `escalation_target` | `null` | **`null`** ❌ |
| `assigned_agent_id` | `null` | `null` |
| `ai_action_log.status` | `skipped` | `skipped` (inchangé, seul blocked_reason change) |
| `ai_action_log.blocked_reason` | `DRAFT_GENERATED` | `DRAFT_APPLIED` |
| `message_events` | 0 events | 1 event (`reply`) — pas d'`autopilot_escalate` |

### Comparaison avec le cas FONCTIONNEL (`conv-4837f801` — ESCALATION_DRAFT)

| Champ | conv-4837f801 (ESCALATION_DRAFT) | cmmo8sz5rd8f173c865e32cb4 (DRAFT_GENERATED) |
|---|---|---|
| `escalation_status` | `escalated` ✅ | `none` ❌ |
| `escalation_reason` | "Promesse d'action détectée: je vais m'assurer" | `null` |
| `escalated_by_type` | `ai` | `null` |
| `message_events` | `autopilot_escalate` + `reply` | `reply` uniquement |

---

## 6. CAUSE RACINE

### Trois causes indépendantes et cumulées

#### Cause A (CRITIQUE) : Classification engine — patterns regex trop étroits

**Fichier** : `src/modules/autopilot/engine.ts` l.141-160 (`detectFalsePromises`)

L'engine Autopilot détecte les "fausses promesses" dans le draft LLM pour décider entre `DRAFT_GENERATED` et `ESCALATION_DRAFT`. Les 14 regex ne couvrent que la forme "je vais + infinitif" (futur immédiat). Le LLM génère régulièrement des promesses dans d'autres formes verbales :

- Présent : "je transmets" → non détecté
- Futur simple : "je vérifierai", "je transmettrai" → non détecté
- 3ème personne : "notre équipe va vérifier" → non détecté

**Impact** : le draft est classé `DRAFT_GENERATED` alors qu'il contient des promesses d'action humaine.

#### Cause B (DESIGN) : Consume ne re-détecte pas les promesses

**Fichier** : `src/modules/autopilot/routes.ts` l.288-295

La route consume vérifie `wasEscalationDraft` via `blocked_reason.startsWith('ESCALATION_DRAFT')`. Si le draft est `DRAFT_GENERATED`, aucune re-détection n'a lieu. Le consume fait confiance aveugle à la classification engine initiale.

**Impact** : aucune seconde chance de détecter une promesse après classification initiale.

#### Cause C (FILET TROUÉ) : Reply flow PH143-E.8 — même lacune regex

**Fichier** : `src/modules/messages/routes.ts` l.533-596

Le "filet de sécurité" PH143-E.8 vérifie le contenu du message sortant après envoi. Bien que ce code contienne 22 patterns (vs 14 dans l'engine), il partage la même faiblesse fondamentale : toutes les expressions commencent par "je vais" + infinitif. Les formes présent, futur simple, et 3ème personne échappent aussi à ce filet.

**Impact** : même quand le reply flow tourne (ce qu'il fait — preuve : event `reply` créé), la détection échoue car les patterns ne couvrent pas les formes verbales utilisées par le LLM.

### Résumé causal

```
LLM génère draft avec "je transmets" (présent)
  ↓
Engine detectFalsePromises() → 0 match → DRAFT_GENERATED
  ↓
User clique "Valider et envoyer"
  ↓
consumeDraft('applied') → wasEscalationDraft = false → PAS d'escalade DB
  ↓
sendReply() → POST /messages/conversations/:id/reply
  ↓
PH143-E.8 promise scan → 0 match → PAS d'escalade reply
  ↓
Résultat : escalation_status = 'none' ❌
```

---

## 7. PLAN DE FIX RECOMMANDÉ

### Option 1 — Classification engine (fix patterns)

**Scope** : `src/modules/autopilot/engine.ts` function `detectFalsePromises`

Étendre les regex pour couvrir :

```typescript
// Formes manquantes à ajouter
[/je (transmets|transmet|transmettrai|transmettrons)/i, 'je transmets'],
[/je (v[eé]rifie|v[eé]rifierai|v[eé]rifierons)/i, 'je vérifie/vérifierai'],
[/je (contacte|contacterai|contacterons)/i, 'je contacte/contacterai'],
[/(notre|mon|l['\u2019]?) ?(équipe|service|support|département) (va|devra|s)/i, 'notre équipe va...'],
[/et (vous )?(recontacter|rappeler|revenir vers)/i, 'et recontacter'],
[/nous (organiserons|effectuerons|procéderons|vérifierons)/i, 'nous organiserons'],
```

**Avantage** : corrige la source — les drafts avec promesse seront classés `ESCALATION_DRAFT` dès la génération.
**Risque** : faux positifs possibles — à calibrer avec des cas réels.

### Option 2 — Consume guardrail (re-détection)

**Scope** : `src/modules/autopilot/routes.ts` route `/draft/consume`

Ajouter une re-détection de promesse dans le consume, même pour `DRAFT_GENERATED` :

```typescript
// Après la lecture du draft original et AVANT le return
if (consumeAction === 'applied' && !wasEscalationDraft) {
  const draftText = originalDraft.rows[0]?.payload?.draftText || '';
  const falsePromises = detectFalsePromises(draftText); // réutiliser la même fonction (étendue)
  if (falsePromises.length > 0) {
    // Reclassifier et escalader
    wasEscalationDraft = true;
    // ... même logique d'escalade
  }
}
```

**Avantage** : seconde chance de capturer les promesses même si l'engine initial a raté.
**Risque** : dépend aussi de l'extension des patterns (Option 1 nécessaire en amont).

### Option 3 — Promise detection partagée (refactoring)

**Scope** : créer un module partagé `src/lib/promise-detection.ts`

Mutualiser les patterns entre :
- `engine.ts` (classification draft)
- `messages/routes.ts` (PH143-E.8 filet de sécurité)
- `ai-assist-routes.ts` (PH142-C Aide IA)

**Avantage** : un seul point de maintenance pour les regex, cohérence garantie.
**Risque** : refactoring plus large, potentiels effets de bord sur les trois modules.

### Recommandation

**Option 1 + Option 2 combinées** : étendre les patterns dans l'engine (classification correcte dès la source) ET ajouter un guardrail de re-détection dans le consume (seconde chance).

L'Option 3 (refactoring) est souhaitable à terme mais peut être faite dans une phase ultérieure.

---

## 8. ÉTAT DE LECTURE — AUCUNE MODIFICATION

| Vérification | Résultat |
|---|---|
| Fichiers modifiés dans keybuzz-api ? | ❌ NON |
| Fichiers modifiés dans keybuzz-backend ? | ❌ NON |
| Fichiers modifiés dans keybuzz-client ? | ❌ NON |
| Fichiers modifiés dans keybuzz-infra ? | ❌ NON (ce rapport uniquement) |
| Build effectué ? | ❌ NON |
| Deploy effectué ? | ❌ NON |
| Image Docker créée ? | ❌ NON |
| Manifest K8s modifié ? | ❌ NON |
| DB modifiée ? | ❌ NON |

---

## VERDICT

**AUTOPILOT CONSUME PROMISE ESCALATION ROOT CAUSE IDENTIFIED**

### Synthèse

Le problème est un **trou dans la couverture regex** des trois systèmes de détection de promesses :

1. **Engine** (`detectFalsePromises`) : classifie le draft comme `DRAFT_GENERATED` au lieu de `ESCALATION_DRAFT` quand le LLM utilise le présent ("je transmets"), le futur simple ("je vérifierai"), ou la 3ème personne ("notre équipe va").

2. **Consume** (`/autopilot/draft/consume`) : fait confiance aveugle à la classification engine — aucune re-détection si `DRAFT_GENERATED`.

3. **Reply** (PH143-E.8) : le filet de sécurité a les mêmes trous regex que l'engine — les promesses en présent/futur simple/3ème personne passent silencieusement.

Le cas PROD prouvé (`cmmo8sz5rd8f173c865e32cb4`) montre un draft contenant 5 expressions de promesse humaine, toutes non détectées par les 36 regex combinés des trois systèmes, résultant en zéro escalade malgré validation et envoi par l'utilisateur.

Le fix recommandé est **Option 1 + 2** : étendre les patterns regex + ajouter un guardrail de re-détection dans le consume.

**Aucune modification effectuée.**

---

**STOP**
