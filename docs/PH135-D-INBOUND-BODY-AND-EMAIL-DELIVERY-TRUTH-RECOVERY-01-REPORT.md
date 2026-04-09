# PH135-D — Inbound Body & Email Delivery Truth Recovery

> Date : 30 mars 2026
> Auteur : Agent Cursor
> Statut : **DEV DEPLOYE — PROD EN ATTENTE**

---

## Problemes

### Probleme 1 — Duplication du contenu dans un message inbound
Les messages Amazon inbound contenaient du contenu duplique ou corrompu dans le body stocke en DB.

### Probleme 2 — Auto-reply non recu cote client
Les reponses generees par l'Autopilot apparaissaient dans l'inbox KeyBuzz mais n'etaient jamais delivrees au client.

---

## Causes Racines

### Cause 1 — Fausse detection MIME sur separateur Amazon
La fonction `isMimeContent()` dans `mimeParser.service.ts` utilisait le regex `MIME_BOUNDARY_PATTERN = /^--[a-zA-Z0-9_=-]+\s*$/m` qui matchait `-------------` (separateur Amazon relay) comme un boundary MIME valide.

**Consequence** : `parseMimeContent()` etait appele sur du contenu non-MIME, produisant un body corrompu ou duplique.

**Ordre des operations (AVANT fix)** :
1. `body.body` → `finalBody`
2. `isMimeContent(body.body)` → **TRUE** (faux positif a cause de `-------------`)
3. `parseMimeContent(body.body)` → body potentiellement corrompu
4. `stripAmazonRelay(finalBody)` → trop tard, dommage deja fait
5. `stripEmailQuotes(finalBody)`

### Cause 2 — Absence de delivery dans executeReply
La fonction `executeReply()` dans `engine.ts` creait le message en DB (`INSERT INTO messages`) mais ne creait **aucun enregistrement** dans `outbound_deliveries`. Sans delivery record, le worker outbound ne pouvait jamais envoyer le message.

**Comparaison** :
| Flux | Messages INSERT | Delivery INSERT |
|------|----------------|-----------------|
| Reply manuelle (messages/routes.ts) | OUI | OUI |
| Autopilot reply (engine.ts) | OUI | **NON** ← bug |

---

## Corrections

### FIX 1 — Reordonnancement stripAmazonRelay avant MIME check
**Fichier** : `src/modules/inbound/routes.ts`

**Ordre des operations (APRES fix)** :
1. `body.body` → `finalBody`
2. `stripAmazonRelay(finalBody)` → supprime `-------------` **en premier**
3. `isMimeContent(finalBody)` → **FALSE** (plus de faux positif)
4. `stripEmailQuotes(finalBody)`

Egalement : `parseMimeContent(body.body)` change en `parseMimeContent(finalBody)` pour utiliser le body deja nettoye.

### FIX 2 — Creation delivery dans executeReply
**Fichier** : `src/modules/autopilot/engine.ts`

Apres l'insertion du message, `executeReply()` :
1. Lit le `channel` et `customer_handle` de la conversation
2. Determine le provider (`spapi` pour Amazon, `smtp` pour email, `octopia` pour Octopia)
3. Insere un enregistrement `outbound_deliveries` avec status `queued`
4. Le worker outbound le detecte et envoie le message

---

## Validation DEV

### Test 1 — Amazon inbound body clean (PASS)
- Input: `"-------------\n\nBonjour, ou en est ma commande svp ?\nMerci beaucoup."`
- Body stocke: `"Bonjour, ou en est ma commande svp ?\nMerci beaucoup."`
- Dashes: **supprimees**
- Resultat: **PASS**

### Test 2 — Email inbound non-regression (PASS)
- Body email conserve intact
- Resultat: **PASS**

### Test 3 — MIME reel non-regression (PASS)
- Contenu MIME multipart correctement parse
- Resultat: **PASS**

### Test 4 — Delivery creation Amazon (PASS)
- Channel: `amazon`, Provider: `spapi`, Status: `queued`
- Target: `test-buyer@marketplace.amazon.fr`
- Resultat: **PASS**

### Test 5 — Delivery creation Email (PASS)
- Channel: `email`, Provider: `smtp`, Status: `queued`
- Target: `customer@gmail.com`
- Resultat: **PASS**

---

## Versions

| Service | Tag DEV | Tag PROD (en attente) |
|---------|---------|----------------------|
| API | `v3.5.143-inbound-body-email-fix-dev` | `v3.5.143-inbound-body-email-fix-prod` |
| Worker | `v3.6.08-inbound-body-email-fix-dev` | `v3.6.08-inbound-body-email-fix-prod` |

### Rollback DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.142-amazon-inbound-thread-fix-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.07-amazon-inbound-thread-fix-dev -n keybuzz-api-dev
```

---

## Non-regressions

| Element | Statut |
|---------|--------|
| API health | OK |
| Worker outbound | Running, SMTP OK |
| CronJobs (SLA, outbound-tick) | Completent normalement |
| Email inbound classique | PASS |
| MIME parsing reel | PASS |
| Amazon outbound | Non affecte (worker inchange fonctionnellement) |
| GitOps manifests DEV | Mis a jour |

---

## PROD : DEPLOYE

Deploye le 30 mars 2026 a 19:08 UTC.

| Service | Tag PROD |
|---------|----------|
| API | `v3.5.143-inbound-body-email-fix-prod` |
| Worker | `v3.6.08-inbound-body-email-fix-prod` |

Health PROD : **OK**

### Rollback PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.142-amazon-inbound-thread-fix-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.07-amazon-inbound-thread-fix-prod -n keybuzz-api-prod
```
