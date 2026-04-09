# PH135-B — Email Pipeline Sanity

> Phase : PH135-B-EMAIL-PIPELINE-SANITY-01
> Date : 2026-03-30
> Statut : **DEV + PROD DEPLOYES**

---

## Problemes identifies

### 1. Duplication inbound (CRITIQUE)

**Preuve** : 13 doublons du meme body (20 chars) dans `conv cmmk6as67v`, et plusieurs autres conversations avec doublons.

**Cause** : Aucune idempotence sur l'insertion des messages inbound. Le `messageId` est genere aleatoirement (`msg-${randomBytes()}`), donc chaque webhook retry cree un nouveau message identique.

### 2. Mauvais Reply-To (CRITIQUE)

**Preuve** : La table `outbound_deliveries` n'a PAS de colonne `reply_to`. Le worker lit `delivery.reply_to` qui est toujours `undefined`. Les emails sortants sont envoyes depuis `noreply@keybuzz.io` sans Reply-To.

**Consequence** : Le destinataire qui clique "Repondre" envoie a `noreply@keybuzz.io` — la reponse est perdue.

### 3. Parsing email (MOYEN)

**Cause** : Le body est insere tel quel apres MIME parsing, sans suppression de l'historique cite (citations, "On ... wrote:", signatures, lignes `>>`).

**Consequence** : L'IA recoit le thread complet au lieu du dernier message, ce qui dilue le contexte et augmente les couts LLM.

## Corrections appliquees

### FIX 1 — Dedup inbound (idempotence)

Avant l'insertion du message dans `/inbound/email` :
- Calcul du hash MD5 du body
- Recherche de message identique (meme conversation, meme body, direction inbound, < 5 minutes)
- Si doublon trouve : retour 200 OK avec `duplicate: true`, SANS insertion

```javascript
const dupCheck = await client.query(
  `SELECT id FROM messages WHERE conversation_id = $1 AND tenant_id = $2
   AND direction = 'inbound' AND md5(body) = md5($3)
   AND created_at > NOW() - INTERVAL '5 minutes' LIMIT 1`,
  [conversationId, body.tenantId, finalBody]
);
```

### FIX 2 — Reply-To email

Dans le worker (`outboundWorker.ts`), pour le path email/SMTP :
- Si `delivery.reply_to` est vide (toujours le cas)
- Cherche d'abord dans `inbound_addresses` (adresse validee du tenant)
- Fallback sur `tenant_metadata.support_email`
- Utilise le resultat comme `replyTo` dans `sendEmail()`

### FIX 3 — Stripping citations email

Fonction `stripEmailQuotes(body)` ajoutee dans `inbound/routes.ts` :
- Coupe le texte au premier marqueur de citation :
  - `On ... wrote:` / `Le ... a ecrit :`
  - `--- Original message ---`
  - `_____` (separateur Outlook)
  - `From: user@...` (header forwarded)
- Supprime les lignes commencant par `>>` (citations profondes)
- Conserve les lignes `>` simples (blockquotes)
- Appliquee juste avant le dedup et l'insertion

## Fichiers modifies

| Fichier | Changement |
|---|---|
| `src/modules/inbound/routes.ts` | `stripEmailQuotes()` + dedup check avant INSERT |
| `src/workers/outboundWorker.ts` | Reply-To lookup pour email channel |

## Non-regressions

| Element | Statut |
|---|---|
| Amazon outbound (SMTP) | Non touche — path separe |
| Amazon inbound | Non touche — `/inbound/amazon-forward` non modifie |
| Octopia outbound | Non touche |
| Pieces jointes | Non impactees |
| Autopilot | Non touche |
| Billing/Wallet | Non touche |
| Health API | OK |

## Versions DEV

| Service | Image |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-email-pipeline-fix-dev` |
| Worker DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.06-email-pipeline-fix-dev` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.140-autopilot-behavior-control-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.05-amazon-line-visual-fix-dev -n keybuzz-api-dev
```

## Versions PROD

| Service | Image |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-email-pipeline-fix-prod` |
| Worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.06-email-pipeline-fix-prod` |

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.140-autopilot-behavior-control-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.05-amazon-line-visual-fix-prod -n keybuzz-api-prod
```

## Verdict

EMAIL PIPELINE CLEAN — NO DUPLICATION — REPLY FLOW FIXED — AI INPUT CLEAN — ROLLBACK READY
