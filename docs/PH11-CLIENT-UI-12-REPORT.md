# PH11-CLIENT-UI-12 — IA Assistante (suggestions & explications)

**Date**: 2026-01-06  
**Statut**: ✅ DÉPLOYÉ

---

## 📦 Versions Déployées

| Composant | Version | Image Docker |
|-----------|---------|--------------|
| keybuzz-client | v0.2.32-dev | ghcr.io/keybuzzio/keybuzz-client:v0.2.32-dev |
| keybuzz-api | v0.1.60-dev | ghcr.io/keybuzzio/keybuzz-api:v0.1.60-dev |

---

## 🎯 Fonctionnalités Implémentées

### 1. API — Endpoint /ai/assist

**Fichier**: `keybuzz-api/src/modules/ai/ai-assist-routes.ts`

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/ai/assist` | POST | Génère suggestions et explications IA |
| `/ai/assist/status` | GET | Statut de disponibilité du service |

**Request Body**:
```json
{
  "tenantId": "kbz-001",
  "contextType": "conversation" | "order" | "playbook",
  "contextId": "id",
  "payload": { ... }
}
```

**Response**:
```json
{
  "status": "success",
  "suggestions": [...],
  "explanations": [...],
  "confidenceLevel": "low" | "medium" | "high",
  "disclaimer": "Suggestion générée par IA — à valider par un humain",
  "requestId": "air-xxx"
}
```

⚠️ **Strictement lecture seule** — Aucune action exécutée, aucune écriture DB.

---

### 2. Composants UI Client

**Fichier principal**: `keybuzz-client/src/features/ai-assistant/AIAssistant.tsx`

#### A) Inbox — Panneau Conversation

- **Bouton**: "🤖 Aide IA" dans le header de conversation
- **Localisation**: À côté de "Historique IA"
- **Fonctionnalité**: Suggestions de réponse basées sur les messages

#### B) Orders — Page Détail Commande

- **Bloc**: Panel "🤖 Aide IA sur cette commande" dans la sidebar
- **Contexte**: Données commande, statut SLA, client
- **Fonctionnalité**: Suggestions d'actions (contact transporteur, remboursement, etc.)

#### C) Playbooks — Page Détail

- **Bouton**: "🤖 Aide IA" à côté de "Tester"
- **Fonctionnalité**: Analyse et explication du playbook

---

### 3. Types d'Assistance IA

| Type | Icône | Description |
|------|-------|-------------|
| 🧠 Expliquer | Sparkles | Résumé, analyse sentiment, pourquoi client mécontent |
| ✍️ Suggérer | MessageSquare | Réponse client, reformulation, ton adapté |
| 🧭 Proposer | Lightbulb | Actions possibles (demander justificatif, escalader, etc.) |

---

### 4. UX & Contrôle Humain

- ✅ Bouton "Copier" sur chaque suggestion
- ✅ Bouton "Insérer dans la réponse" (pour réponses type)
- ✅ Disclaimer visible: "Suggestion générée par IA — à valider par un humain"
- ✅ Aucun envoi automatique
- ✅ Badge de confiance (faible/moyen/élevé)

---

### 5. Feature Gating

**Fichier**: `keybuzz-client/src/features/billing/planCapabilities.ts`

| Plan | Accès IA | Quota Journalier |
|------|----------|------------------|
| Starter | ✅ Oui | 3 appels/jour |
| Pro | ✅ Oui | Illimité |
| Autopilot | ✅ Oui | Illimité + priorité |
| Enterprise | ✅ Oui | Illimité + priorité |

- Si quota atteint: message clair + CTA vers /pricing
- Quota stocké en localStorage côté client

---

## 🧪 Tests E2E (DEV)

### Test 1: Endpoint AI Assist
```bash
curl -X POST https://api-dev.keybuzz.io/ai/assist \
  -H 'Content-Type: application/json' \
  -d '{"tenantId":"kbz-001","contextType":"conversation","contextId":"test-001","payload":{"messages":[{"role":"user","content":"Ma commande est en retard"}]}}'
```
**Résultat**: ✅ Suggestions générées avec confiance high/medium

### Test 2: Status Endpoint
```bash
curl https://api-dev.keybuzz.io/ai/assist/status
```
**Résultat**: ✅ `{"available":true,"provider":"mock","features":["suggestions","explanations","reformulations"]}`

### Test 3: UI Client
- ✅ Bouton "Aide IA" visible dans Inbox
- ✅ Panel AI Assistant visible dans Orders
- ✅ Bouton "Aide IA" visible dans Playbooks
- ✅ Disclaimer affiché sur toutes les suggestions

---

## 📁 Fichiers Créés/Modifiés

### keybuzz-api
- `src/modules/ai/ai-assist-routes.ts` — Nouveau endpoint
- `src/app.ts` — Registration du plugin

### keybuzz-client
- `src/features/ai-assistant/AIAssistant.tsx` — Composant principal
- `src/features/ai-assistant/index.ts` — Export
- `src/features/billing/planCapabilities.ts` — Ajout hasAIAssistant
- `app/inbox/InboxTripane.tsx` — Intégration AIAssistButton
- `app/orders/[orderId]/page.tsx` — Intégration AIAssistant
- `app/playbooks/[playbookId]/page.tsx` — Intégration AIAssistButton

---

## ⚠️ Limites Connues

1. **Provider Mock**: L'IA utilise actuellement des réponses mockées. Intégration OpenAI/LiteLLM à faire.
2. **Pas de persistance serveur**: Le quota est géré côté client (localStorage), pas serveur.
3. **Pas de contexte enrichi**: Les données passées à l'IA sont basiques, enrichissement possible.

---

## 🔮 Préparation PH11-CLIENT-UI-13 (Autopilot)

Pour la phase Autopilot:
- [ ] Connecter un vrai provider IA (OpenAI/LiteLLM)
- [ ] Ajouter mode "semi-autonome" pour exécution avec validation
- [ ] Implémenter le quota côté serveur
- [ ] Ajouter analytics des suggestions acceptées/refusées

---

## 📋 Commits Git

```
keybuzz-api: feat(PH11): ai/assist endpoint - suggestions & explanations
keybuzz-client: feat(PH11): AI Assistant component + UI integration
keybuzz-infra: docs(PH11): CLIENT-UI-12 report
```

---

**✅ PH11-CLIENT-UI-12 TERMINÉ**
