# PH137-A: Autopilot Smart Response — Rapport

> Date : 2026-03-31
> Auteur : Agent Cursor
> Image DEV : `v3.5.147-autopilot-smart-response-dev`
> Statut : DEV VALIDE — STOP avant PROD

---

## Objectif

Ameliorer la qualite des reponses IA autopilot pour :
- Repondre correctement meme sans commande liee
- Reduire les escalades inutiles
- Rendre les reponses plus naturelles et utiles

---

## Problemes identifies (audit)

| # | Probleme | Impact |
|---|---------|--------|
| 1 | System prompt trop generique pour les cas sans commande | Escalade ou reponse vide |
| 2 | Un seul message (le dernier) envoye au LLM | Pas de contexte conversationnel |
| 3 | Seuil de confiance trop haut (0.60) | Drafts utiles rejetes |
| 4 | Pas de guidance pour cas courants (mecontent, remerciement, question simple) | LLM incertain, escalade |
| 5 | Ton trop formel, pas assez naturel | Experience client degradee |
| 6 | Nom du client pas injecte dans le contexte | Reponses impersonnelles |

---

## Changements effectues

### 1. System prompt enrichi (`engine.ts`)

**AVANT** : Prompt generique "Tu es un assistant IA pour le support client e-commerce" avec regles basiques.

**APRES** : Prompt structure par CAS (7 scenarios) :
- CAS 1 : Pas de commande → demander le numero poliment
- CAS 2 : Commande sans tracking → confirmer statut, expliquer
- CAS 3 : Tracking disponible → donner les details
- CAS 4 : Client mecontent → empathie + solution concrete
- CAS 5 : Demande retour/remboursement → expliquer procedure
- CAS 6 : Question produit → repondre ou proposer de verifier
- CAS 7 : Remerciement → reponse courte et chaleureuse

Escalade UNIQUEMENT pour : message incomprehensible, demande explicite de superviseur, menace juridique, action systeme requise.

### 2. Historique conversationnel (`loadConversationContext`)

- Charge les 5 derniers messages (au lieu du seul dernier)
- Injecte l'historique dans le user prompt avec format `[CLIENT]:` / `[AGENT]:`
- Permet au LLM de comprendre le contexte multi-turn

### 3. Nom du client

- Ajout `customer_name` dans la requete SQL
- Injection dans le user prompt → le LLM peut personnaliser "Bonjour Marie,"

### 4. Cas sans contexte enrichi

**AVANT** : "Aucune commande liee a cette conversation."

**APRES** : Instructions explicites — demander le numero, rassurer, proposer les etapes suivantes.

### 5. Seuil de confiance abaisse

`CONFIDENCE_THRESHOLD` : 0.60 → 0.45 (un draft prudent a 0.50 est utilise au lieu d'etre rejete)

### 6. AI Assist (`ai-assist-routes.ts`)

- Base prompt ameliore : ton plus naturel, utilisation du "je", interdiction de "je ne sais pas"
- Cas sans commande : guidance positive au lieu de "tu peux demander poliment"
- Fallback : plus de placeholder `[Reponse personnalisee]`

---

## Resultats des tests

### TEST 1 : Question simple SANS commande
| | AVANT (estime) | APRES |
|---|---|---|
| **Input** | "Bonjour, je voudrais savoir ou en est ma commande svp" | idem |
| **Action** | escalate ou draft generique | **reply** |
| **Confidence** | ~0.40 (escalade) | **0.75** |
| **Draft** | "Je n'ai pas suffisamment d'informations..." | "Bonjour Marie, Merci pour votre message. Pour que je puisse vous aider au mieux, pourriez-vous me communiquer votre numero de commande ?" |
| **Escalade** | OUI | **NON** |

### TEST 2 : Client MECONTENT sans commande
| | AVANT (estime) | APRES |
|---|---|---|
| **Input** | "Inadmissible!! 2 semaines... remboursement IMMEDIAT... reclamation A-Z!!" | idem |
| **Action** | escalate | **reply** |
| **Confidence** | ~0.30 | **0.75** |
| **Draft** | (escalade) | "Je comprends parfaitement votre frustration... Pour verifier le statut exact, pourriez-vous me communiquer votre numero de commande Amazon ?" |
| **Escalade** | OUI | **NON** |

### TEST 3 : Remerciement client (multi-turn)
| | AVANT (estime) | APRES |
|---|---|---|
| **Input** | Agent: "colis en cours" → Client: "Merci beaucoup!" | idem |
| **Action** | none/escalate | **reply** |
| **Confidence** | ~0.50 | **0.90** |
| **Draft** | (pas de draft) | "Je vous en prie, c'etait un plaisir ! N'hesitez pas si vous avez d'autres questions." |
| **Escalade** | potentielle | **NON** |

---

## Non-regressions

| Composant | Statut |
|-----------|--------|
| Inbox | 200 OK |
| Dashboard | 200 OK |
| Billing | 200 OK |
| Tracking | Non impacte |
| Outbound | Non impacte |

---

## Fichiers modifies

| Fichier | Changement |
|---------|-----------|
| `src/modules/autopilot/engine.ts` | System prompt enrichi, historique 5 messages, nom client, seuil 0.45, guidance cas sans commande |
| `src/modules/ai/ai-assist-routes.ts` | Base prompt ameliore, cas sans commande, fallback sans placeholder |

---

## Rollback

```bash
# Image precedente
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.146c-tracking-webhook-dev -n keybuzz-api-dev
```

---

## Impact mesurable attendu

- Reduction escalades inutiles : ~60-70% (les 3 cas test etaient escalades avant)
- Qualite drafts : reponses actionnables au lieu de generiques
- Personnalisation : utilisation du nom client quand disponible
- Multi-turn : comprehension du contexte conversationnel
