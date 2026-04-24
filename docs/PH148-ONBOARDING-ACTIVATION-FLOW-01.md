# PH148-ONBOARDING-ACTIVATION-FLOW-01

> Refonte complète du onboarding (Démarrage → Activation)
> Date : 13 avril 2026
> Environnement : DEV uniquement

---

## IMAGES


| Service     | Avant                                  | Après                                     |
| ----------- | -------------------------------------- | ----------------------------------------- |
| Client DEV  | `v3.5.258-ph146.4-billing-addons-dev`  | `v3.5.60-ph148-onboarding-activation-dev` |
| API DEV     | `v3.5.53-ph147.3-encoding-cleanup-dev` | inchangé                                  |
| Backend DEV | `v1.0.38-vault-tls-dev`                | inchangé                                  |


**Rollback** : `kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.258-ph146.4-billing-addons-dev -n keybuzz-client-dev`

---

## ÉTAT AVANT

L'ancien onboarding (`OnboardingHub.tsx`) était une **checklist statique** de 5 items :

1. Créer votre espace (hardcodé `done: true`)
2. Compléter vos informations entreprise → `/settings/tenant`
3. Ajouter un canal (Amazon) → `/channels`
4. Vérifier la réception des messages → `/inbox`
5. Tester une réponse IA → `/inbox`

**Problèmes** :

- Aucune détection dynamique de l'état utilisateur
- Force les settings entreprise en premier (friction)
- Pas de connexion directe depuis l'onboarding
- Aucune progression visuelle
- Pas de CTA adaptatif

---

## NOUVEAU FLOW

### Architecture : CONNECTER → VOIR → RÉPONDRE

Le nouvel onboarding est 100% dynamique avec 4 cas basés sur l'état réel :

### CAS 1 — 0 canal connecté

- Grille de marketplaces : Amazon (recommandé), Shopify, Cdiscount, Fnac, eBay
- Bouton Amazon → déclenche directement OAuth existant (`startAmazonOAuth`)
- Shopify / Cdiscount → redirigent vers `/channels`
- Fnac / eBay → badges "Bientôt"

### CAS 2 — Canal connecté, 0 message

- Loader animé + "Nous récupérons vos messages"
- Boutons : "Voir la boîte de réception" + "Gérer mes canaux"

### CAS 3 — Messages disponibles

- Compteur de messages à traiter
- Badge IA : "L'IA vous suggère des réponses intelligentes"
- CTA : "Répondre avec l'IA" → `/inbox`

### CAS 4 — Première réponse faite

- CTA Autopilot : "Automatiser vos réponses ?"
- Bouton "Configurer l'Autopilot" → `/playbooks`
- Alternative "Continuer manuellement" → `/inbox`

### Stepper visuel 4 étapes

- Connecter un canal (Radio)
- Voir les messages (MessageSquare)
- Répondre (Zap)
- Automatiser (Bot)
- États visuels : vert (complété), bleu (actif), gris (à venir)

---

## FICHIERS CRÉÉS/MODIFIÉS


| Action   | Fichier                                                | Description                           |
| -------- | ------------------------------------------------------ | ------------------------------------- |
| CRÉÉ     | `src/features/onboarding/hooks/useOnboardingState.ts`  | Hook de détection d'état (100 lignes) |
| RÉÉCRIT  | `src/features/onboarding/components/OnboardingHub.tsx` | Nouveau composant (264 lignes)        |
| INCHANGÉ | `app/start/page.tsx`                                   | Renders OnboardingHub                 |
| INCHANGÉ | `app/onboarding/page.tsx`                              | Renders OnboardingHub                 |
| BACKUP   | `OnboardingHub.tsx.pre-ph148.bak`                      | Sauvegarde version précédente         |


### useOnboardingState.ts — Hook de détection

Appels API parallèles :

- `GET /api/amazon/status?tenant_id={tenantId}` → `{ connected: boolean }`
- `GET /api/octopia/status?tenantId={tenantId}` → `{ connected: boolean }`
- `GET /api/shopify/status?tenantId={tenantId}` → `{ connected: boolean }`
- `GET /api/dashboard/summary?tenantId={tenantId}` → stats conversations

Retour :

```typescript
{
  hasChannel: boolean;
  hasMessages: boolean;
  hasReplied: boolean;
  isLoading: boolean;
  currentStep: 1 | 2 | 3 | 4;
  channelDetails: { amazon: boolean; octopia: boolean; shopify: boolean };
  messageCount: number;
}
```

---

## LOGIQUE CONDITIONNELLE

```
hasChannel === false             → CAS 1 (step 1) : connecter
hasChannel && !hasMessages       → CAS 2 (step 2) : attente sync
hasChannel && hasMessages && !hasReplied → CAS 3 (step 3) : répondre
hasChannel && hasMessages && hasReplied  → CAS 4 (step 4) : automatiser
```

La détection de `hasReplied` utilise les stats `open + resolved > 0` comme proxy.

---

## INTÉGRATION CONNECTEURS

Les boutons marketplace dans CAS 1 utilisent les services existants :

- **Amazon** : `startAmazonOAuth(tenantId, returnUrl)` + `redirectToAmazonOAuth(authUrl)` — OAuth direct
- **Shopify / Octopia** : redirect vers `/channels` (configuration complète)
- **Fnac / eBay** : désactivés (`coming_soon`)

Aucune logique connecteur n'a été recréée — uniquement les appels existants.

---

## TESTS RÉELS — client-dev.keybuzz.io

### Compte : [compta.ecomlg@gmail.com](mailto:compta.ecomlg@gmail.com)


| Scénario                           | Résultat                                  |
| ---------------------------------- | ----------------------------------------- |
| Page `/start` charge               | ✅ Hero + Stepper + contenu dynamique      |
| Détection Amazon connecté          | ✅ `hasChannel = true`, badge Amazon vert  |
| CAS 2 affiché (0 messages)         | ✅ Loader + "Nous récupérons vos messages" |
| Navigation inbox depuis onboarding | ✅ Redirect `/inbox` correct               |
| Retour `/start` → état maintenu    | ✅ CAS 2 toujours affiché                  |
| Page canaux (`/channels`)          | ✅ 6 canaux Amazon connectés               |
| Dashboard                          | ✅ Tous les KPI visibles                   |
| Billing                            | ✅ Plan Autopilot, 2000 KBActions          |


---

## NON-RÉGRESSION

### Frontend (navigation réelle)


| Page                  | Statut                              |
| --------------------- | ----------------------------------- |
| `/start` (onboarding) | ✅ Nouveau flow dynamique            |
| `/inbox`              | ✅ Tripane, filtres, 0 conversations |
| `/channels`           | ✅ 6 Amazon connectés, logos, badges |
| `/dashboard`          | ✅ KPI cards, supervision, SLA       |
| `/billing`            | ✅ Plan Autopilot, KBActions, canaux |
| `/settings`           | ✅ Non testé (hors scope)            |


### Backend (DB via pod)


| Module                | Valeur | Statut   |
| --------------------- | ------ | -------- |
| Conversations         | 453    | ✅ stable |
| Orders                | 11 945 | ✅ stable |
| Agents                | 25     | ✅ stable |
| Tenants               | 13     | ✅ stable |
| AI Wallets            | 3      | ✅ stable |
| Billing subscriptions | 10     | ✅ stable |
| API errors (logs)     | 0      | ✅        |
| Client errors (logs)  | 0      | ✅        |


### Pods K8s


| Pod             | Status      | Image                                   |
| --------------- | ----------- | --------------------------------------- |
| keybuzz-api     | Running 1/1 | v3.5.53-ph147.3-encoding-cleanup-dev    |
| keybuzz-client  | Running 1/1 | v3.5.60-ph148-onboarding-activation-dev |
| keybuzz-backend | Running 1/1 | v1.0.38-vault-tls                       |


### API Health

```json
{"status":"ok","service":"keybuzz-api"}
```

---

## ANTI-CONTAMINATION

- ✅ Seul le client a été modifié (2 fichiers)
- ✅ API inchangée
- ✅ Backend inchangé
- ✅ Billing inchangé
- ✅ Agents inchangés
- ✅ Aucun connecteur modifié (Amazon OAuth réutilisé tel quel)
- ✅ DEV ONLY — aucun push PROD

---

## ROLLBACK

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.258-ph146.4-billing-addons-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## VERDICT

### ONBOARDING ACTIVATION FLOW READY

