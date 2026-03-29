# PH133-A — Autopilot Contextual Draft Generation

> Date : 2026-03-29
> Statut : **DEV + PROD DEPLOYE ET VALIDE**
> Phase : PH133-A-AUTOPILOT-CONTEXTUAL-DRAFT-GENERATION-01

---

## 1. Objectif

Permettre a l'Autopilot de generer une reponse brouillon **contextualisee** (commande, tracking, transporteur, retard)
pre-remplie dans le champ de reponse, sans envoi automatique, avec validation humaine obligatoire.

---

## 2. Contexte disponible AVANT PH133-A

Le moteur autopilot (`engine.ts`) recevait **uniquement** :

| Donnee | Source |
|--------|--------|
| Canal (amazon/email/octopia) | `conversations.channel` |
| Sujet | `conversations.subject` |
| Statut conversation | `conversations.status` |
| Nombre de messages | COUNT messages |
| Dernier message client | `messages.body` (dernier inbound) |
| Agent assigne | `conversations.assigned_agent_id` |

**Absents** : numero de commande, tracking, transporteur, date/heure, retard, produits.

---

## 3. Contexte disponible APRES PH133-A

### 3.1 Contexte commande (si `conversations.order_ref` existe)

| Donnee | Source |
|--------|--------|
| Numero de commande | `orders.external_order_id` |
| Statut commande | `orders.status` |
| Transporteur | `orders.carrier` |
| Numero de suivi | `orders.tracking_code` |
| URL de suivi | `orders.tracking_url` |
| Statut livraison | `orders.delivery_status` |
| Date de commande | `orders.order_date` |
| Mode d'expedition | `orders.fulfillment_channel` (AFN/MFN) |
| Montant | `orders.total_amount` + `orders.currency` |
| Produits | `orders.products` (JSONB) |

### 3.2 Contexte temporel (calcule en temps reel)

| Donnee | Description |
|--------|--------|
| `currentDateTime` | Date/heure ISO courante |
| `currentDate` | Date du jour |
| `currentTime` | Heure courante |
| `timezone` | Europe/Paris |
| `daysSinceOrder` | Jours depuis la commande |
| `expectedDeliveryDays` | 4j (FBA) / 8j (FBM) |
| `deliveryDelayDays` | daysSinceOrder - expectedDays |
| `isPotentiallyLate` | true si retard detecte |

### 3.3 Source de verite tracking

Aucun connecteur externe n'a ete ajoute. Les donnees tracking proviennent **exclusivement**
de la table `orders` (alimentee par les sync Amazon SP-API existantes).

---

## 4. Modifications apportees

### 4.1 API — engine.ts (reecrit)

| Ajout | Description |
|-------|-------------|
| `OrderContext` interface | Structure des donnees commande |
| `TemporalContext` interface | Structure contexte temporel |
| `UsedContext` interface | Flags indiquant quelles donnees ont ete utilisees |
| `loadOrderContext()` | Charge la commande liee via `conversations.order_ref` → `orders.external_order_id` |
| `computeTemporalContext()` | Calcule date/heure, retard, delai |
| `buildUsedContext()` | Construit les flags usedContext |
| `AutopilotResult.draftReplyText` | Draft texte retourne au client |
| `AutopilotResult.usedContext` | Contexte utilise (audit) |
| `AutopilotResult.reasoningSummary` | Resume du raisonnement IA |
| Prompt IA enrichi | Sections commande, livraison, analyse temporelle |
| Safe mode = DRAFT | Genere le draft sans envoyer (raison: `DRAFT_GENERATED`) |
| `logAction()` avec draftText | Stocke le draft dans `ai_action_log.payload` |

### 4.2 API — routes.ts (patche)

| Ajout | Description |
|-------|-------------|
| `GET /autopilot/draft` | Endpoint pour recuperer le dernier draft d'une conversation |

### 4.3 Client — AutopilotDraftBanner.tsx (nouveau)

| Composant | Description |
|-----------|-------------|
| `AutopilotDraftBanner` | Bandeau affichant le brouillon IA avec boutons Utiliser/Ignorer |
| Props | `conversationId`, `tenantId`, `replyText`, `onApplyDraft` |
| Protection | Ne pre-remplit que si le champ reponse est vide |

### 4.4 Client — BFF route (nouveau)

| Route | Description |
|-------|-------------|
| `app/api/autopilot/draft/route.ts` | Proxy BFF vers `GET /autopilot/draft` |

### 4.5 Client — InboxTripane.tsx (patche)

| Modification | Description |
|--------------|-------------|
| Import `AutopilotDraftBanner` | Ajout import |
| Composant dans le JSX | Insere apres `PlaybookSuggestionBanner`, dans `FeatureGate requiredPlan="AUTOPILOT"` |

---

## 5. Comportement safe_mode

| safe_mode | Comportement avant PH133-A | Comportement apres PH133-A |
|-----------|---------------------------|---------------------------|
| `true` | SAFE_MODE_BLOCKED + escalation | **DRAFT_GENERATED** : draft cree, pas d'envoi, pas d'escalation |
| `false` | Reply auto envoye | Reply auto envoye (inchange) |

---

## 6. Test DEV — Resultats

### 6.1 Cas test : tracking request avec vrai suivi

- **Tenant** : switaa-sasu-mnc1x4eq (AUTOPILOT, autonomous, safe_mode=true)
- **Message client** : "j'ai passe commande il y a 12 jours [...] le colis semble bloque"
- **Commande** : MFN, Colissimo, tracking 6A12345678901, 89.90 EUR
- **Resultat** :

```
action: reply
reason: DRAFT_GENERATED
confidence: 1.0
executed: false (safe_mode)
kbActionsDebited: 0
```

**Draft genere** :
> Bonjour, je suis desole pour le retard concernant votre commande.
> Votre colis a ete expedie via Colissimo et il semble effectivement y avoir un retard.
> Vous pouvez suivre votre colis en utilisant ce lien : [Suivi Colissimo](https://www.laposte.fr/outils/suivre-vos-envois?code=6A12345678901).
> Nous vous recommandons de contacter Colissimo pour plus d'informations sur l'etat actuel de la livraison. Merci de votre patience.

**usedContext** :
```json
{
  "orderNumber": true,
  "trackingNumber": true,
  "trackingStatus": true,
  "currentDateTime": true,
  "carrierName": true,
  "deliveryDelay": true
}
```

**reasoningSummary** : "Le colis est en retard de 4 jours, et le client demande une verification, donc fournir le lien de suivi et reconnaitre le retard est approprie."

### 6.2 Endpoint draft

- `GET /autopilot/draft?tenantId=...&conversationId=...` → `hasDraft: true`, `draftText: ...`, `confidence: 1.0`

### 6.3 Plan guard

- `ecomlg-001` (PRO) → `PLAN_INSUFFICIENT:PRO` — OK, refuse correctement

### 6.4 Non-regressions

| Endpoint | Status |
|----------|--------|
| `GET /health` | 200 |
| `GET /billing/current` | 200 |
| `GET /ai/settings` | 200 |
| `GET /messages/conversations` | 200 |
| `GET /ai/rules` (playbooks) | 200 |
| `GET /autopilot/settings` | 200 |
| `GET /ai/wallet/status` | 200 |

---

## 7. Versions deployees

### DEV

| Service | Image DEV |
|---------|-----------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.131-autopilot-contextual-draft-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.131-autopilot-contextual-draft-dev` |

### PROD

| Service | Image PROD |
|---------|-----------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.131-autopilot-contextual-draft-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.131-autopilot-contextual-draft-prod` |

### Rollback DEV

| Service | Image rollback |
|---------|---------------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev` |

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev -n keybuzz-client-dev
```

### Rollback PROD

| Service | Image rollback |
|---------|---------------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.127-kba-checkout-fix-prod` |

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.130-bootstrap-fix-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.127-kba-checkout-fix-prod -n keybuzz-client-prod
```

---

## 8. GitOps

| Fichier | Modification |
|---------|--------------|
| `k8s/keybuzz-api-dev/deployment.yaml` | Image → v3.5.131-autopilot-contextual-draft-dev |
| `k8s/keybuzz-client-dev/deployment.yaml` | Image → v3.5.131-autopilot-contextual-draft-dev |
| `k8s/keybuzz-api-prod/deployment.yaml` | Image → v3.5.131-autopilot-contextual-draft-prod |
| `k8s/keybuzz-client-prod/deployment.yaml` | Image → v3.5.131-autopilot-contextual-draft-prod |

---

## 9. Fichiers modifies/crees

### API (keybuzz-api)
| Fichier | Action |
|---------|--------|
| `src/modules/autopilot/engine.ts` | Reecrit (enrichissement contexte + draft) |
| `src/modules/autopilot/routes.ts` | Patche (ajout GET /draft) |

### Client (keybuzz-client)
| Fichier | Action |
|---------|--------|
| `src/features/inbox/components/AutopilotDraftBanner.tsx` | Cree |
| `app/api/autopilot/draft/route.ts` | Cree (BFF) |
| `app/inbox/InboxTripane.tsx` | Patche (import + usage AutopilotDraftBanner) |

---

## 10. PROD

**STATUT : DEPLOYE ET VALIDE (2026-03-29)**

### Validation PROD

| Endpoint | Status |
|----------|--------|
| `GET /health` | 200 |
| `GET /billing/current` | 200 |
| `GET /ai/settings` | 200 |
| `GET /messages/conversations` | 200 |
| `GET /ai/rules` (playbooks) | 200 |
| `GET /autopilot/settings` | 200 |
| `GET /ai/wallet/status` | 200 |
| `GET /autopilot/draft` | 200 |
| External `https://api.keybuzz.io/health` | 200 |
| External `https://client.keybuzz.io/` | 200 |

**Non-regressions : 8/8 OK**

---

## 11. Verdict

**AUTOPILOT CONTEXTUAL DRAFT LIVE — REAL ORDER/TRACKING CONTEXT — TIME AWARE — HUMAN VALIDATION LOOP ENABLED — DEV+PROD ALIGNED — ROLLBACK READY**
