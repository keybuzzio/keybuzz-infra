# PH-AI-INBOX-UNIFIED-ENTRY-03 — Rapport

> **Date** : 26 mars 2026
> **Phase** : PH-AI-INBOX-UNIFIED-ENTRY-03
> **Environnement** : DEV uniquement
> **Type** : Unification entree IA inbox

---

## 1. Checkpoint Rollback

| Element | Valeur |
|---|---|
| Image client DEV avant | `v3.5.117-ph-ai-inbox-native-ux-dev` |
| Rollback safe immediat | `v3.5.117-ph-ai-inbox-native-ux-dev` |
| Disponibilite bastion | OUI |
| **ROLLBACK READY** | **YES** |

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.117-ph-ai-inbox-native-ux-dev -n keybuzz-client-dev
```

---

## 2. Suppression "Assist IA"

### Elements supprimes de InboxTripane.tsx

| Element | Localisation | Statut |
|---|---|---|
| Bouton "Assist IA" (toolbar reponse) | Reply toolbar, apres spacer | SUPPRIME |
| State `showAIDecision` | useState ligne 316 | SUPPRIME |
| AIDecisionPanel collapsible | Reply zone, sous PlaybookSuggestionBanner | SUPPRIME |
| Import `AIDecisionPanel` | Import depuis `@/src/features/ai-ui` | SUPPRIME |
| Import `Sparkles` (lucide) | Import lucide-react | SUPPRIME (plus utilise) |

### Elements NON supprimes (logique preservee)

| Element | Fichier | Statut |
|---|---|---|
| Composant `AIDecisionPanel` | `src/features/ai-ui/AIDecisionPanel.tsx` | INTACT |
| Export `AIDecisionPanel` | `src/features/ai-ui/index.ts` | INTACT |
| Endpoint `/ai/evaluate` | Backend API | INTACT |
| Endpoint `/ai/execute` | Backend API | INTACT |

---

## 3. Mapping "Aide IA"

### Identification

| Element | Valeur |
|---|---|
| Composant | `AISuggestionSlideOver` |
| Fichier | `src/features/ai-ui/AISuggestionSlideOver.tsx` |
| Label bouton | `Aide IA` (avec icone Sparkles) |
| Type | Slide-over panel (overlay droit) |
| Declencheur | Click sur bouton "Aide IA" |

### Flux declanche par "Aide IA"

1. Ouverture du slide-over
2. Affichage du contexte conversationnel
3. Possibilite d'ajouter du contexte additionnel (texte + fichiers)
4. Generation IA via `assistAI()` → LiteLLM
5. Affichage de la reponse avec analyse ("Pourquoi cette reponse")
6. Actions : Inserer / Copier / Regenerer / Fermer
7. Tracking KBActions (consommation avant/apres)

### Features IA accessibles (directement ou via panels auto)

| Feature | Acces via | Type |
|---|---|---|
| Generation IA (LiteLLM) | "Aide IA" (AISuggestionSlideOver) | Declenchement volontaire |
| Suggestions deterministes | AISuggestionsPanel (auto, PRO+) | Affichage automatique |
| Playbook suggestions | PlaybookSuggestionBanner (auto, PRO+) | Affichage contextuel |
| Templates de reponse | "Modeles" (TemplatePickerSlideOver) | Declenchement volontaire |

---

## 4. Regles Forfaits Appliquees

### STARTER

| Element | Visible | Justification |
|---|---|---|
| Bouton "Modeles" | OUI | Templates de reponse, pas d'IA |
| Bouton "Aide IA" | NON | FeatureGate PRO+ hide |
| AISuggestionsPanel | NON | FeatureGate PRO+ hide (existant) |
| PlaybookSuggestionBanner | NON | FeatureGate PRO+ hide (existant) |
| Inbox / Messages / Reply | OUI | Fonctionnalite de base |

### PRO / AUTOPILOT / ENTERPRISE

| Element | Visible | Justification |
|---|---|---|
| Bouton "Modeles" | OUI | Utile meme avec IA (pas redondant) |
| Bouton "Aide IA" | OUI | Unique entree IA, FeatureGate PRO+ |
| AISuggestionsPanel | OUI | Suggestions automatiques, PRO+ |
| PlaybookSuggestionBanner | OUI | Suggestions playbook, PRO+ |
| Inbox / Messages / Reply | OUI | Fonctionnalite de base |

---

## 5. Fichiers Modifies

| Fichier | Type modification |
|---|---|
| `app/inbox/InboxTripane.tsx` | Suppression Assist IA, gating AISuggestionSlideOver |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Tag image v3.5.118 |
| `keybuzz-infra/docs/ROLLBACK-SOURCE-OF-TRUTH-01.md` | Chaine deploiement + rollback |

---

## 6. Diff Effectif

```diff
- import { ..., AIDecisionPanel } from "@/src/features/ai-ui";
+ import { ..., } from "@/src/features/ai-ui";

- import { ..., Sparkles } from "lucide-react";
+ import { ..., } from "lucide-react";

- const [showAIDecision, setShowAIDecision] = useState(false);
  (supprime)

  Zone AI entry :
+ <FeatureGate requiredPlan="PRO" fallback="hide">
    <AISuggestionSlideOver ... />
+ </FeatureGate>

  Reply toolbar :
- <FeatureGate requiredPlan="PRO" fallback="hide">
-   <button onClick={() => setShowAIDecision(...)}>Assist IA</button>
- </FeatureGate>
  (supprime)

  Reply zone :
- {showAIDecision && <AIDecisionPanel ... />}
  (supprime)
```

---

## 7. Validations DEV

### Image deployee

| Verification | Resultat |
|---|---|
| Image active | `v3.5.118-ph-ai-inbox-unified-entry-dev` |
| Rollout | SUCCESS |
| Pod running | OUI |

### Endpoints API (non-regression)

| Endpoint | Status | Resultat |
|---|---|---|
| `/health` | 200 | `{"status":"ok"}` |
| `/ai/settings` | 200 | mode=supervised, ai_enabled=true |
| `/ai/wallet/status` | 200 | plan=PRO, KBA remaining=4.11 |
| `/playbooks` | 200 | Playbooks retournes |
| `/billing/current` | 200 | plan=PRO, status=active |
| `/messages/conversations` | 200 | 3 conversations |
| `/ai/journal` | 200 | Events retournes |

### Verdicts

| Test | Verdict |
|---|---|
| AI INBOX ENTRY DEV | **OK** |
| AI GATING DEV | **OK** |
| INBOX NO REGRESSION DEV | **OK** |
| FEATURES IA EXISTANTES | **OK** |

---

## 8. Ce qui n'a PAS ete modifie

| Element | Statut |
|---|---|
| Backend API | INTACT |
| Base de donnees | INTACT |
| Billing / Stripe | INTACT |
| Amazon / SP-API | INTACT |
| Autopilot engine | INTACT |
| KBActions / Wallet | INTACT |
| Data flows | INTACT |
| AISuggestionSlideOver (composant) | INTACT |
| AISuggestionsPanel (composant) | INTACT |
| PlaybookSuggestionBanner (composant) | INTACT |
| AIDecisionPanel (composant, fichier) | INTACT (non utilise dans InboxTripane) |
| TemplatePickerSlideOver (composant) | INTACT |

---

## 9. Verdict Final

**AI INBOX ENTRY UNIFIED AND CORRECT**

- "Assist IA" supprime (bouton + collapsible + state)
- "Aide IA" = unique entree IA dans l'inbox (PRO+)
- "Modeles" = unique entree templates (tous plans)
- STARTER = Modeles uniquement, zero IA visible
- PRO+ = Aide IA + Modeles + suggestions auto
- Aucune feature IA supprimee ou cassee
- Diff minimal : 1 seul fichier applicatif modifie
