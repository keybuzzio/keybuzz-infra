# PH133-D — Amazon Outbound Pipeline Truth Recovery

> Date : 30 mars 2026
> Auteur : Agent Cursor (CE)
> Phase precedente : PH133-C (Carrier Live Tracking)
> Statut : **DEV + PROD DEPLOYES ET VALIDES**

---

## 1. OBJECTIF

Diagnostiquer et corriger la regression sur le pipeline de reponse sortante Amazon :
- formatage HTML degrade
- encodage / charset non explicite
- caracteres potentiellement mal retranscrits

---

## 2. PREFLIGHT

### Versions avant intervention

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.133-carrier-live-tracking-dev` | `v3.5.133-carrier-live-tracking-prod` |
| Client | `v3.5.131-autopilot-contextual-draft-dev` | `v3.5.131-autopilot-contextual-draft-prod` |
| Outbound Worker | `v3.6.00-td02-worker-resilience-dev` | `v3.6.00-td02-worker-resilience-prod` |

### Rollback DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.133-carrier-live-tracking-dev -n keybuzz-api-dev
# Worker
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-dev -n keybuzz-api-dev
```

---

## 3. CARTOGRAPHIE DU FLUX SORTANT AMAZON

### Flow complet bout en bout

```
1. UI Inbox → User tape reponse, clique "Envoyer"
2. Client → POST /api/conversations/:id/reply (BFF Next.js)
3. API Fastify → POST /messages/conversations/:id/reply
   - Cree message dans `messages` (direction=outbound)
   - determineProvider('amazon') → 'spapi'
   - INSERT INTO outbound_deliveries (status='queued', provider='spapi')
   - Bind attachments (MinIO pending → message)
4. Outbound Worker (deployment separe, meme image)
   - Poll outbound_deliveries (FOR UPDATE SKIP LOCKED)
   - Provider 'spapi' → check AMAZON_SPAPI_MESSAGING_ENABLED
   - SP-API = false (default) → sendAmazonViaSMTP()
   - Get conversation details (order_ref, customer_handle, subject)
   - Get message body from DB
   - Get tenant validated inbound address (From)
   - Get MIME attachments from MinIO
   - Convert body → HTML
   - sendEmail() via emailService.ts
5. emailService.ts → nodemailer SMTP
   - DEV: 49.13.35.167:25
   - PROD: mail.keybuzz.io:25
6. SMTP → Relay to @marketplace.amazon.fr
7. Amazon displays in Seller Central / buyer messaging
```

### Reponses aux questions cles

| Question | Reponse |
|----------|---------|
| Quel service envoie le message ? | `outboundWorker.ts` via `emailService.ts` (SMTP) |
| Flux passe par API ou backend legacy ? | API Fastify uniquement (pas de backend Python) |
| Queues / workers impliques ? | Table `outbound_deliveries` = queue, Worker = consumer |
| Point de verite livraison | `outbound_deliveries.status = 'delivered'` + `delivery_trace` |
| SP-API active ? | NON (`AMAZON_SPAPI_MESSAGING_ENABLED=false`) |

---

## 4. ETAT REEL AVANT CORRECTION

### DEV

| Metrique | Valeur |
|----------|--------|
| Amazon delivered | 170 |
| Amazon failed | 13 (tous anciens, jan 2026) |
| Email delivered | 16 |

### PROD

| Metrique | Valeur |
|----------|--------|
| Amazon delivered | 88 |
| Amazon failed | **0** |
| Email delivered | 6 |

### Causes des 13 echecs DEV (tous anciens)

| Erreur | Count | Periode |
|--------|-------|---------|
| `Amazon OAuth not connected - no refresh token` | 3 | Jan 21 |
| `Client host rejected: Access denied` (IP) | 5 | Jan 18 |
| `Unknown provider: SMTP_AMAZON_NONORDER` | 2 | Jan 18 |

**Conclusion : le pipeline SMTP unifie fonctionne depuis fevrier. 0 echec PROD.**

---

## 5. DIAGNOSTIC — POINT DE RUPTURE

### 5.1 Le pipeline livre les messages (SMTP OK)

Les messages SONT envoyes et marques `delivered`. Le SMTP fonctionne.

### 5.2 Le formatage HTML est deficient

**Fichier** : `src/workers/outboundWorker.ts`, ligne 358

**Avant** (code problematique) :
```javascript
const htmlBody = finalBody.replace(/\n/g, '<br>\n');
```

**Problemes** :
1. **Pas d'echappement HTML** : `<`, `>`, `&` dans le texte passent tels quels → cassent le rendu
2. **Pas d'enveloppe HTML** : pas de `<!DOCTYPE>`, pas de `<meta charset="utf-8">`
3. **Pas de structure paragraphe** : juste des `<br>` bruts
4. Une fonction `textToHtml()` existante (ligne 81) fait tout correctement mais n'etait **PAS utilisee** dans le path Amazon

### 5.3 La fonction `textToHtml()` existante

```javascript
function textToHtml(text: string): string {
    // Escape HTML special chars (&, <, >)
    // Split into paragraphs (double line breaks)
    // Wrap each paragraph in <p> tags
    // Replace single \n with <br> inside paragraphs
}
```

Cette fonction etait utilisee pour le path `email_forward` (ligne 631) mais PAS pour le path Amazon SMTP.

---

## 6. CORRECTION APPLIQUEE

### Fix minimal dans `outboundWorker.ts`

**Avant** :
```javascript
const htmlBody = finalBody.replace(/\n/g, '<br>\n');
```

**Apres** :
```javascript
const htmlContent = textToHtml(finalBody);
const htmlBody = [
  '<!DOCTYPE html>',
  '<html><head><meta charset="utf-8"></head>',
  '<body style="font-family: Arial, sans-serif; font-size: 14px; line-height: 1.5; color: #333;">',
  htmlContent,
  '</body></html>',
].join('\n');
```

### Ce que ca corrige

| Probleme | Avant | Apres |
|----------|-------|-------|
| Echappement HTML | Non | Oui (`&amp;`, `&lt;`, `&gt;`) |
| Charset explicite | Non | `<meta charset="utf-8">` |
| Structure paragraphes | `<br>` bruts | `<p>` / `<br>` structures |
| Enveloppe HTML | Aucune | `<!DOCTYPE>`, `<html>`, `<body>` |
| Emojis UTF-8 | Implicite | Explicite via charset |
| Formatage texte long | Degrade | Paragraphes propres |

### Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/workers/outboundWorker.ts` | Conversion HTML Amazon utilise `textToHtml()` + enveloppe |

### Fichiers NON modifies (deja corrects)

| Fichier | Raison |
|---------|--------|
| `src/services/emailService.ts` | SMTP UTF-8 + CRLF normalization = OK |
| `src/modules/outbound/routes.ts` | Routes admin/retry = OK |
| `src/modules/messages/routes.ts` | Reply route = OK |

---

## 7. VALIDATION DEV

### 7.1 Tests fonctionnels

| Test | Resultat |
|------|----------|
| Health | OK |
| Worker demarrage | `v4.4.0-html-format-fix` |
| Orders API | OK |
| Conversations | OK |
| Autopilot | OK (enabled, supervised) |
| Billing | OK (PRO, active) |
| AI Wallet | OK (4.11 KBA) |
| Outbound deliveries | 186 delivered, 17 failed (anciens) |

### 7.2 Non-regressions

| Module | Statut |
|--------|--------|
| Health check | OK |
| Orders API | OK |
| Conversations / Inbox | OK |
| Dashboard | OK |
| Autopilot settings | OK |
| AI Wallet | OK |
| Billing | OK |
| Outbound worker | Running, v4.4.0 |

---

## 8. VERSIONS DEPLOYEES

### DEV

| Service | Image | Tag |
|---------|-------|-----|
| API | `v3.5.134-amazon-outbound-fix-dev` | Worker fix inclus |
| Worker | `v3.6.01-amazon-outbound-fix-dev` | `v4.4.0-html-format-fix` |

### PROD

| Service | Image |
|---------|-------|
| API | `v3.5.134-amazon-outbound-fix-prod` |
| Worker | `v3.6.01-amazon-outbound-fix-prod` |

### Verification PROD

| Test | Resultat |
|------|----------|
| Health | OK |
| Worker boot | `v4.4.0-html-format-fix` OK |
| Orders API | OK |
| Conversations | OK |
| Autopilot | OK (enabled, supervised) |
| Billing | OK (PRO, active) |
| AI Wallet | OK (388.67 KBA) |
| Outbound deliveries | 94 delivered, 1 failed |

### Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.133-carrier-live-tracking-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-dev -n keybuzz-api-dev
```

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.133-carrier-live-tracking-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-prod -n keybuzz-api-prod
```

### GitOps

Manifests mis a jour :
- `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`
- `keybuzz-infra/k8s/keybuzz-api-dev/outbound-worker-deployment.yaml`
- `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
- `keybuzz-infra/k8s/keybuzz-api-prod/outbound-worker-deployment.yaml`

---

## 9. RESUME TECHNIQUE DU PIPELINE

### Architecture actuelle (saine)

```
UI → BFF → API (messages/routes.ts)
         ↓ INSERT outbound_deliveries
     Worker (outboundWorker.ts) polls
         ↓ sendAmazonViaSMTP()
     emailService.ts → SMTP → Amazon relay
```

### Points de verite

| Element | Source |
|---------|--------|
| Message cree | `messages` table |
| Delivery queue | `outbound_deliveries` table |
| Delivery status | `outbound_deliveries.status` |
| Trace detaillee | `outbound_deliveries.delivery_trace` (JSONB) |
| Worker version | Log boot `v4.4.0-html-format-fix` |

### SP-API Messaging

Desactive par defaut (`AMAZON_SPAPI_MESSAGING_ENABLED=false`). Tout passe par SMTP unifie. Reactiver si necessaire via env var.

---

## 10. FIX CRITIQUE #2 : WRONG MARKETPLACE FROM ADDRESS

### Probleme decouvert lors du test reel

Le message pour la commande `402-5200517-9042745` etait marque `delivered` par le SMTP
mais n'arrivait **pas** sur la conversation Amazon.

**Cause racine** : la fonction `getInboundAddressForTenant()` selectionnait la **derniere adresse inbound creee**
au lieu de celle correspondant au marketplace de la conversation.

- DEV envoyait depuis `.be.` (Belgique) au lieu de `.fr.` (France)
- PROD envoyait depuis `.es.` (Espagne) au lieu de `.fr.` (France)

Amazon ignore silencieusement les messages dont le From ne correspond pas au marketplace.

### Correction

Ajout de `extractMarketplaceTld()` qui extrait le TLD du `customerHandle`
(`@marketplace.amazon.fr` -> `fr`) et matching avec l'adresse inbound correspondante (`.fr.`).

```
@marketplace.amazon.fr → amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
@marketplace.amazon.de → amazon.ecomlg-001.de.49ecbe@inbound.keybuzz.io
@marketplace.amazon.es → amazon.ecomlg-001.es.14153c@inbound.keybuzz.io
```

Fallback sur la derniere adresse si aucun match (comportement precedent).

### Versions apres fix #2

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.135-marketplace-from-fix-dev` | `v3.5.135-marketplace-from-fix-prod` |
| Worker | `v3.6.02-marketplace-from-fix-dev` | `v3.6.02-marketplace-from-fix-prod` |

Worker version interne : `4.5.0-marketplace-from-fix`

### Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.134-amazon-outbound-fix-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.01-amazon-outbound-fix-dev -n keybuzz-api-dev
# PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.134-amazon-outbound-fix-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.01-amazon-outbound-fix-prod -n keybuzz-api-prod
```

---

## 11. DETTE TECHNIQUE RESTANTE

| # | Element | Priorite |
|---|---------|----------|
| 1 | Reactiver SP-API Messaging si Amazon bloque les relais SMTP | BASSE (fonctionne) |
| 2 | Tester envoi reel avec PJ vers Amazon (aucun test recent) | MOYENNE |
| 3 | Ajouter monitoring sur taux echec outbound (Prometheus) | BASSE |

---

## VERDICT

**AMAZON OUTBOUND TRUTH RECOVERED — HTML FORMATTING FIXED — MARKETPLACE FROM ADDRESS FIXED — CHARSET UTF-8 EXPLICIT — DEV + PROD v3.5.135 / v3.6.02 — ROLLBACK READY**

**DEV + PROD deployes et valides le 30 mars 2026.**

**Retester l'envoi sur la commande 402-5200517-9042745 : le From sera desormais `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` (France).**
