# PH11-PRODUCT-01D - UX finale IA cote Client

## Resume

Phase de finalisation de l'experience utilisateur IA cote client. L'objectif est de rendre l'IA comprehensible, maitrisable et desirable pour les e-commercants.

**Principe directeur:** "Je comprends quand KeyBuzz agit, pourquoi, et je peux reprendre la main a tout moment."

## Livrables

### 1. Bouton "Laisser KeyBuzz repondre" (AIDecisionPanel)

**Emplacement:** Dans le panneau de detail conversation (Inbox tri-pane)

**Etats visuels:**
| Etat | Condition | UI |
|------|-----------|-----|
| ðŸŸ¢ Disponible | IA autorisee + confiance suffisante | Bouton actif violet |
| ðŸŸ¡ Proposition | Confiance moyenne | Bouton "Verifier avant envoi" |
| ðŸ”´ Bloque | Kill switch / limite | Bouton desactive + message |

**Tooltip explicatif:** Inclus pour chaque etat

### 2. Panneau Decision KeyBuzz (enrichi)

**Contenu affiche:**
- ðŸ§  **Pourquoi KeyBuzz agit** - Section explicative
- ðŸ“ **Niveau de confiance** - Badge colore (ðŸŸ¢ðŸŸ¡ðŸ”´)
- ðŸ“œ **Regle appliquee** - Nom de la regle
- âš™ï¸ **Action prevue** - Type d'action (repondre, tagger, etc.)
- ðŸš¦ **Mode actif** - Badge (Suggestion / Supervise / Autonome)

**Aucune information technique visible.**

### 3. Workflow utilisateur complet

**Quand l'IA propose une reponse:**

1. **Affichage clair:**
   - Reponse proposee dans une zone dediee
   - Actions associees
   - Impact prevu

2. **Boutons obligatoires:**
   - âœ… **Laisser KeyBuzz repondre** - Envoie directement
   - âœï¸ **Modifier avant envoi** - Copie dans la zone de texte
   - ðŸ‘¤ **Je reponds moi-meme** - Ignore la suggestion
   - ðŸ” **Toujours autoriser** - Option pour ce type de reponse

### 4. Badges Pre-IA

**Visualisation hierarchique:**
| Badge | Description |
|-------|-------------|
| ðŸ“„ Regle automatique | Reponse deterministe sans IA |
| ðŸ“˜ Modele de reponse | Template pre-defini |
| âœ¨ Suggestion KeyBuzz | IA propose, humain valide |
| ðŸ¤– Action KeyBuzz | IA agit automatiquement |

**Le client voit quand l'IA n'est PAS utilisee.**

### 5. Parametres > Intelligence Artificielle

**Sections implementees:**

#### Mode de fonctionnement
- **Suggestions uniquement** - KeyBuzz propose, vous decidez
- **Mode supervise** (recommande) - KeyBuzz agit sur cas surs
- **Mode autonome** - KeyBuzz repond automatiquement

#### Limites de securite (visibles)
- Actions par heure: `20` (defaut)
- Reponses par conversation: `3` (defaut)
- Actions consecutives sans validation: `2` (defaut)

#### Controle rapide
- Bouton **Mettre KeyBuzz en pause** / **Reactiver KeyBuzz**
- Etat IA visible (vert = actif, rouge = pause)

#### Historique actions bloquees
- Liste des 3 dernieres actions bloquees
- Lien vers journal complet

### 6. Lien vers Journal IA

**Depuis une conversation:**
- Lien "Voir l'historique KeyBuzz pour cette conversation"
- Redirection vers `/ai-journal?conversationId=xxx`

## Messages UX (sans jargon)

| Situation | Message |
|-----------|---------|
| IA disponible | "KeyBuzz peut vous aider" |
| IA bloquee | "KeyBuzz en pause" |
| Confiance elevee | "Cas connu, reponse fiable" |
| Confiance moyenne | "Verification recommandee" |
| Confiance faible | "Cas nouveau, attention requise" |
| Action envoyee | "KeyBuzz a envoye la reponse au client" |
| Action modifiee | "Modifiez la reponse dans la zone de texte" |
| Action ignoree | "Ecrivez votre propre reponse" |

## Composants modifies

### keybuzz-client/src/features/ai-ui/

| Fichier | Modifications |
|---------|---------------|
| `AIDecisionPanel.tsx` | Refonte complete avec workflow utilisateur |
| `AIModeSwitch.tsx` | Section settings enrichie avec limites et kill switch |
| `index.ts` | Exports mis a jour |

## Design

- Metronic coherent
- Pas de surcharge
- Badges, cartes, callouts
- Responsive
- Light / Dark OK

## Contraintes respectees

- âœ… Utilisation des endpoints existants (`/ai/evaluate`, `/ai/execute`, `/ai/settings`, `/ai/journal`)
- âœ… Pas de nouveau moteur
- âœ… Pas de logique serveur complexe
- âœ… DEV uniquement

## Criteres de validation

| Critere | Statut |
|---------|--------|
| Client comprend quand/pourquoi IA agit | âœ… |
| Peut bloquer, autoriser, modifier facilement | âœ… |
| Ne se sent jamais depossede | âœ… |
| Couts IA maitrisables | âœ… |
| Aucun jargon technique | âœ… |
| Aucun comportement surprise | âœ… |

## Image Docker deployee

| Image | Tag |
|-------|-----|
| keybuzz-client | v0.2.9-dev |

## Tests

```
âœ… https://client-dev.keybuzz.io/inbox â†’ HTTP 200
âœ… https://client-dev.keybuzz.io/settings â†’ HTTP 200
```

## Ce qui n'a PAS ete fait (intentionnellement)

- âŒ Bouton "Repondre automatiquement" sans contexte
- âŒ IA autonome sans confirmation claire
- âŒ Texte anxiogene ("KeyBuzz decide pour vous")
- âŒ UX "magique" non explicable

## DEV Only - PROD intact

Toutes les modifications sont en environnement DEV uniquement.

---

**PH11-PRODUCT-01D - Termine**

Date: 2026-01-04
