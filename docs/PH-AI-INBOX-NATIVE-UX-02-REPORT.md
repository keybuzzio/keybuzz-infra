# PH-AI-INBOX-NATIVE-UX-02 — RAPPORT

> Date : 2026-03-26
> Type : refonte UX legere — integration native IA dans l'inbox
> Environnement : DEV uniquement
> Image : `v3.5.117-ph-ai-inbox-native-ux-dev`

---

## VERDICT : AI INBOX UX NATIVELY INTEGRATED

---

## 1. Rollback Checkpoint

| Service | Env | Image actuelle | Rollback safe | Sur bastion |
|---------|-----|----------------|---------------|-------------|
| keybuzz-client | DEV | `v3.5.117-ph-ai-inbox-native-ux-dev` | `v3.5.116-ph-ai-product-integration-dev` | OUI |
| keybuzz-client | PROD | `v3.5.113-ph-trial-plan-fix-prod` | `v3.5.112-ph-billing-truth-02-prod` | OUI |
| keybuzz-api | DEV/PROD | inchange | inchange | N/A |

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.116-ph-ai-product-integration-dev -n keybuzz-client-dev
```

---

## 2. Ancien vs Nouvel Emplacement

### AIDecisionPanel

| | AVANT (v3.5.116) | APRES (v3.5.117) |
|---|---|---|
| **Position** | Gros bloc entre messages et zone de reponse | Panneau collapsible dans la zone de reponse |
| **Visibilite par defaut** | Toujours visible (prend ~200px de hauteur) | Masque par defaut, ouvert volontairement |
| **Declenchement** | Automatique au chargement | Bouton "Assist IA" dans la toolbar |
| **Fermeture** | Aucune (toujours la) | Auto-fermeture apres application d'une suggestion |
| **Impact visuel** | Casse le flux messages → reponse | Zero impact sur le flux de lecture |

**Justification UX** : Dans un flux de chat/inbox, l'utilisateur lit les messages puis repond. Un bloc IA entre les deux brise ce flux naturel. En integrant l'IA comme un outil optionnel dans la toolbar de reponse (au meme niveau que "Reponse" et "Note interne"), elle devient un assistant discret qu'on invoque quand on en a besoin, pas un obstacle permanent.

### PlaybookSuggestionBanner

| | AVANT (v3.5.116) | APRES (v3.5.117) |
|---|---|---|
| **Position** | Fin de la zone messages scrollable | Zone de reponse, avant le textarea |
| **Style** | Fond purple, bordure purple, texte 14px | Fond neutre gris, bordure subtile, texte 10-12px |
| **Encombrement** | Banner visible avec marges | Barre fine compacte |
| **Actions** | Boutons "Accepter" + "Ignorer" en texte | Icones compactes (check/x) |
| **Gating** | Aucun (visible pour tous les plans) | PRO+ seulement |

**Justification UX** : Les suggestions playbook sont contextuelles a la reponse, pas aux messages. Les placer dans la zone de reponse les rend plus pertinentes. Le style neutre les rend non-intrusives — elles ne "crient" plus visuellement.

---

## 3. Regles par plan appliquees

| Element | STARTER | PRO | AUTOPILOT |
|---------|---------|-----|-----------|
| Inbox (messages, conversations) | visible | visible | visible |
| AISuggestionSlideOver | visible | visible | visible |
| TemplatePickerSlideOver | visible | visible | visible |
| AISuggestionsPanel | masque | visible | visible |
| Bouton "Assist IA" | masque | visible | visible |
| AIDecisionPanel (collapsible) | masque | visible | visible |
| PlaybookSuggestionBanner | masque | visible | visible |

**Mecanisme** : `FeatureGate requiredPlan="PRO" fallback="hide"` — le composant n'est pas rendu du tout pour STARTER. Aucun teasing, aucun upsell dans l'inbox.

---

## 4. Fichiers modifies

| Fichier | Action | Changement |
|---------|--------|------------|
| `app/inbox/InboxTripane.tsx` | MODIFIE | +`Sparkles` import, +`showAIDecision` state, suppression ancien bloc AIDecisionPanel, suppression ancien PlaybookSuggestionBanner, ajout toolbar AI compact + panneaux collapsibles dans reply zone |
| `src/features/inbox/components/PlaybookSuggestionBanner.tsx` | MODIFIE | Redesign compact : fond neutre, bordures subtiles, texte plus petit, actions icones, marges reduites |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | MODIFIE | Tag image |
| `keybuzz-infra/docs/ROLLBACK-SOURCE-OF-TRUTH-01.md` | MODIFIE | Rollback chain |

### Fichiers NON modifies (confirmation)

- Aucun fichier backend
- Aucune API
- Aucune migration DB
- Aucun fichier billing/KBActions
- Aucun fichier Amazon
- Aucun fichier autopilot engine
- AIDecisionPanel.tsx : composant inchange, seule l'integration change
- AISuggestionsPanel.tsx : inchange
- AISuggestionSlideOver.tsx : inchange
- Tous les services (ai.service.ts, etc.) : inchanges

---

## 5. Architecture UX finale

```
INBOX v3.5.117 — Flux natif

+----------------------------------------------------------+
| Toolbar : Historique IA | Commande                       |
+----------------------------------------------------------+
| [TemplatePickerSlideOver] [AISuggestionSlideOver]         |
+----------------------------------------------------------+
| AISuggestionsPanel (PRO+, thin)                           |
+----------------------------------------------------------+
|                                                          |
|  Messages (scrollable, clean, zero IA inline)            |
|  ┌──────────────────────────────────────────┐            |
|  │ Client: "Ma commande n'est pas arrivee" │            |
|  └──────────────────────────────────────────┘            |
|                     ┌─────────────────────────────┐      |
|                     │ Agent: "Je verifie..."      │      |
|                     └─────────────────────────────┘      |
|                                                          |
+----------------------------------------------------------+
| Reply zone                                               |
|  Reponse | Note interne | ─────── | [✨ Assist IA] PRO+  |
|                                                          |
|  [PlaybookSuggestionBanner] (compact, PRO+, auto-hide)   |
|  [AIDecisionPanel] (collapsible, PRO+, ouvert si clic)   |
|                                                          |
|  [textarea ...........................................]   |
|  [📎 Joindre]                             [Envoyer ➤]   |
+----------------------------------------------------------+
```

---

## 6. Validations DEV

### Endpoints

| Test | Status | Resultat |
|------|--------|----------|
| Client DEV (client-dev.keybuzz.io) | 200 | OK |
| API DEV (api-dev.keybuzz.io/health) | 200 | `status: ok` |
| AI Settings | 200 | `mode: supervised` |
| Billing | 200 | `plan: PRO` |
| Playbook Suggestions | 200 | `suggestions: []` |
| Conversations | 200 | `length=2347` |

### Pod

```
keybuzz-client-75bd68fbfd-hgtgk   1/1   Running   0
Image: v3.5.117-ph-ai-inbox-native-ux-dev
Node: k8s-worker-02
```

### Verdicts DEV

| Verdict | Resultat |
|---------|----------|
| AI INBOX UX DEV | **OK** — integration native, flux naturel |
| AI GATING DEV | **OK** — STARTER masque, PRO+ visible |
| INBOX NO REGRESSION DEV | **OK** — health 200, conversations 200, billing 200 |

---

## 7. Ce qui N'A PAS ete modifie

| Element | Confirme |
|---------|----------|
| Backend (keybuzz-api) | OUI |
| APIs | OUI |
| Base de donnees | OUI |
| Billing/KBActions | OUI |
| Autopilot engine | OUI |
| Amazon | OUI |
| PROD | OUI |
| Tracking API (evaluateAI, executeAI, trackApply, trackDismiss) | OUI — conserve tel quel |

---

## 8. Stop point

- PAS de PROD
- PAS de moteur
- PAS de backend
- Image PROD inchangee : `v3.5.113-ph-trial-plan-fix-prod`

---

**VERDICT FINAL : AI INBOX UX NATIVELY INTEGRATED**
