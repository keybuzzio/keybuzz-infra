# PH141-F — AI Context Utilization Fix

> Date : 3 avril 2026
> Auteur : Agent Cursor
> Type : correction IA critique
> Statut : **DEV + PROD DEPLOYES**

---

## Objectif

Empêcher l'IA de demander des informations déjà présentes dans le message client.

## Diagnostic

**Cause racine identifiée** : le prompt système contenait des instructions contradictoires qui poussaient l'IA à questionner le client plutôt qu'à utiliser les informations fournies.

| Instruction problématique | Effet |
|---|---|
| "Si une info manque, demande-la au client" | Pousse l'IA à questionner même si l'info est dans le message |
| CAS 1 : "Demande poliment le numéro de commande" | Aucune vérification préalable du message |
| Reformulation exemple : "Pourriez-vous communiquer votre numéro..." | Modèle de question qui s'applique même si le numéro est fourni |
| **AUCUNE règle de priorité** | Pas d'instruction pour utiliser les infos déjà fournies |

## Corrections apportées

### Fichier : `src/modules/ai/shared-ai-context.ts`

1. **Règle Prioritaire Absolue** (ajoutée en tête des règles de scénario)
   - Obligation de scanner le message client AVANT de répondre
   - Si le client fournit des infos (numéro commande, tracking, email, entreprise) : les utiliser directement
   - JAMAIS redemander une information déjà présente
   - Exemples concrets fournis au LLM

2. **CAS 1 mis à jour** : vérifie D'ABORD si le client a mentionné un numéro de commande dans son message
3. **CAS 5 mis à jour** : utilise la raison du retour si déjà fournie par le client
4. **Interdiction ajoutée** : "JAMAIS redemander une information déjà fournie par le client"
5. **Reformulation** : l'exemple de reformulation est maintenant conditionnel (SI pas fourni → demander, SINON → utiliser)

### Fichier : `src/modules/ai/ai-assist-routes.ts`

6. **Ligne 336** : "Si une info manque" → "Si une info manque ET n'est pas fournie dans le message du client"
7. **Section no-order** : "Demande poliment le numéro" → "VÉRIFIE D'ABORD le message du client"

## Tests DEV

### Test 1 — Conversation avec order_ref (annulation)
- **Input** : "Bonjour, je souhaite annuler ma commande 407-0239528-6695506"
- **Résultat** : L'IA utilise le numéro de commande, mentionne les produits (hubs USB), le montant (976,50 EUR)
- **Questions redondantes** : AUCUNE

### Test 2 — Demande facture avec infos complètes (pas d'order_ref système)
- **Input** : "Facture pour commande 407-9876543-1234567, ACME SAS, SIRET 12345678901234"
- **Résultat** : L'IA utilise le numéro de commande, reconnaît les infos entreprise
- **Questions redondantes** : AUCUNE

### Test 3 — Tracking fourni par le client
- **Input** : "Mon colis tracking 6A12345678901 indique livré mais je n'ai rien reçu"
- **Résultat** : L'IA reprend le tracking ET le numéro de commande fournis
- **Questions redondantes** : AUCUNE

## Non-régression

- Autopilot : non impacté (utilise le même `shared-ai-context.ts`)
- Billing : non touché
- Auth : non touché
- Inbox/messages : non touché
- Escalade : les cas d'escalade restent identiques

## Image déployée

| Env | Image |
|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.182-ai-context-fix-dev` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.182-ai-context-fix-prod` |

## Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.180-keybuzz-agent-lockdown-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.180-keybuzz-agent-lockdown-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

## Verdict

**AI USES PROVIDED DATA — NO REDUNDANT QUESTIONS — SMART RESPONSE**
