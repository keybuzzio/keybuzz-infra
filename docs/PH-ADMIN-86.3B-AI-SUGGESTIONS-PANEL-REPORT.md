# PH-ADMIN-86.3B — AI Suggestions Panel — Report

**Date** : 2026-03-04
**Phase** : PH-ADMIN-86.3B
**Objectif** : Ajouter un panneau de recommandations IA lisible et fiable au Case Workbench

---

## 1. Audit des champs IA réellement disponibles

### Champs exploitables (backend CaseDetail)

| Champ | Type | Source | Stabilité | Usage UI |
|---|---|---|---|---|
| `recommended_action` | string | `human_approval_queue` | Stable DEV/PROD | Action recommandée principale |
| `recommended_owner` | string | `human_approval_queue` | Stable DEV/PROD | Destinataire suggéré |
| `reason` | string | `human_approval_queue` | Stable DEV/PROD | Motif déclencheur / pourquoi le cas existe |
| `queue_type` | string | `human_approval_queue` | Stable DEV/PROD | Catégorie de revue (LEGAL, FRAUD, etc.) |
| `priority` | string | `human_approval_queue` | Stable DEV/PROD | Sévérité évaluée par l'IA |
| `risk_summary.abuseRisk` | string | JSONB `risk_summary` | Stable DEV/PROD | Signal risque abus |
| `risk_summary.fraudRisk` | string | JSONB `risk_summary` | Stable DEV/PROD | Signal risque fraude |
| `risk_summary.escalationType` | string | JSONB `risk_summary` | Stable DEV/PROD | Type d'escalade |
| `risk_summary.safetyBlockReason` | string\|null | JSONB `risk_summary` | Stable DEV/PROD | Raison blocage sécurité |
| `risk_summary.orderValueCategory` | string | JSONB `risk_summary` | Stable DEV/PROD | Catégorie valeur commande |
| `decision_context` | Record<string, unknown> | JSONB `decision_context` | Stable DEV/PROD | Contexte enrichi (snoozedUntil, etc.) |

### Champs NON disponibles

| Champ attendu | Statut | Commentaire |
|---|---|---|
| Score de confiance IA | Non disponible | Le backend ne fournit pas de % ou score de confiance |
| Policy ID / rule ID | Non disponible | Pas de référence à une policy spécifique |
| Journal IA (ai_actions_ledger) | Non disponible via API ops | Existe en DB mais pas exposé par l'API case detail |
| Historique actions IA | Non disponible | Pas d'endpoint audit trail IA |
| Score de risque numérique | Non disponible | Seuls des labels textuels (HIGH, CRITICAL, etc.) |

**Règle appliquée** : aucun score, aucun signal, aucune donnée n'a été inventée. Seuls les champs réellement retournés par le backend sont affichés.

---

## 2. Architecture UI du panneau IA

### Position dans le Workbench

Le panneau AI se positionne dans la **colonne principale** de `/cases/[id]`, entre le `CaseSummary` et le `ContextSection` (contexte cas), pour maximiser la visibilité sans perturber le workflow d'action.

### Hiérarchie visuelle

```
Header (CaseHeader)
  ↓
Résumé (CaseSummary)
  ↓
★ SUGGESTION IA (AISuggestionPanel)  ← NOUVEAU
  ├── Pourquoi ce cas existe
  ├── Prochaine étape recommandée
  ├── Sévérité + Catégorie
  ├── Signaux détectés (SuggestionReasonList)
  └── Contexte IA technique (repliable)
  ↓
Contexte cas (ContextSection)
  ↓
Contexte tenant (ContextSection)
  ↓
Conversation / Commande (ContextSection)
  ↓
Timeline (CaseTimeline)
```

### Distinction Suggestion / État réel / Action humaine

| Zone | Contenu | Visuel |
|---|---|---|
| **AISuggestionPanel** | Ce que l'IA recommande | Bordure bleue, badge "Recommandation", icône Sparkles |
| **CaseSummary + ContextSection** | État réel du cas | Bordure standard, pas de badge |
| **CaseActionPanel** | Actions humaines disponibles | Boutons d'action dans la sidebar |

Cette séparation garantit qu'un agent ne confonde jamais une suggestion IA avec un état réel ou une action exécutée.

---

## 3. Composants créés

### `AISuggestionPanel.tsx`
- Composant principal orchestrant le panneau IA
- Détecte si des données IA existent (`hasAIData`)
- Affiche un message explicite si aucune recommandation n'est disponible
- Badge "Recommandation" distinct
- Bordure et fond subtil bleu pour distinguer visuellement

### `RecommendedActionCard.tsx`
- Bloc **"Pourquoi ce cas existe"** : reformulation lisible du trigger + type de revue
- Bloc **"Prochaine étape recommandée"** : action IA + destinataire suggéré
- Bloc **Sévérité + Catégorie** : badges colorés selon la criticité
- Labels humains pour toutes les valeurs backend (ACTION_LABELS, REASON_LABELS, TYPE_LABELS, PRIORITY_CONFIG)

### `SuggestionReasonList.tsx`
- Construit dynamiquement la liste des signaux détectés à partir de `risk_summary`
- 5 types de signaux : abus, fraude, escalade, blocage sécurité, valeur commande
- Chaque signal a une icône, un label, et un badge coloré selon la sévérité
- Message sobre si aucun signal détecté

### `TechnicalAIContext.tsx`
- Panneau repliable (fermé par défaut)
- Affiche les données techniques brutes : reason code, queue type, action, owner, priority
- Affiche les champs risk_summary et decision_context en format clé-valeur lisible
- Destiné aux profils avancés, ne domine pas l'UX

---

## 4. États UI gérés

| État | Comportement |
|---|---|
| Données IA présentes | Panneau complet avec action, signaux, technique |
| Aucune donnée IA | Message explicite "Aucune recommandation IA disponible" |
| Données IA partielles | Seules les sections avec données sont affichées |
| Aucun signal de risque | Message "Aucun signal de risque particulier détecté" |
| Case introuvable | Page d'erreur existante (pas de changement) |

---

## 5. RBAC

- Le panneau IA est visible pour tous les rôles autorisés à voir un cas
- Les actions ops (assign, resolve, snooze) restent contrôlées par le RBAC existant
- Aucune permission n'est hardcodée dans les composants IA

---

## 6. Non-régression

### Admin v2
- Les actions ops existantes (assign, resolve, snooze, change status) restent fonctionnelles
- Le layout workbench n'est pas perturbé
- Les composants existants ne sont pas modifiés

### Client
- `client-dev.keybuzz.io` : HTTP 307 (redirect login) — fonctionnel
- `client.keybuzz.io` : HTTP 307 (redirect login) — fonctionnel
- Aucune modification backend, aucun impact client

---

## 7. Déploiement

| Environnement | Image | Statut |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.9.0-ph86.3b-ai-suggestions` | ✅ Running 1/1 |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.9.0-ph86.3b-ai-suggestions` | ✅ Running 1/1 |

---

## 8. Limitations documentées

| Limitation | Impact | Phase future |
|---|---|---|
| Pas de score de confiance IA | Pas de barre de progression ni % affiché | Backend enrichment futur |
| Pas de journal IA | Timeline n'inclut pas les actions IA passées | PH86.4+ |
| Pas de conversation/client context | Panneau conversation reste minimal | Backend enrichment futur |
| Pas de policy/rule ID | Pas de lien vers la règle déclencheuse | Backend enrichment futur |

---

## 9. Résumé validation

| Critère | Résultat |
|---|---|
| Panneau IA présent sur /cases/[id] | ✅ |
| Données affichées réelles (pas inventées) | ✅ |
| Recommandation principale lisible | ✅ |
| Justifications/signaux lisibles | ✅ |
| Séparation suggestion / état réel / action humaine | ✅ |
| Aucun score inventé | ✅ |
| Actions ops fonctionnelles | ✅ |
| Non-régression client | ✅ |
| Build OK | ✅ |
| Deploy DEV + PROD OK | ✅ |

**PH-ADMIN-86.3B : VALIDÉE**
