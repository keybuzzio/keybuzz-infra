# PH135-E — Reply-To + Subject Encoding Fix

> Date : 30 mars 2026
> Auteur : Cursor Executor
> Statut : DEV + PROD DEPLOYES

---

## Problemes

### 1. Reply-To incorrect sur les reponses Amazon SMTP

**Cause racine** : Dans `sendAmazonViaSMTP()` (outboundWorker.ts), le champ `replyTo` etait defini a `delivery.reply_to` qui est toujours `null/undefined` car la table `outbound_deliveries` ne contient pas de colonne `reply_to`. Les emails envoyés n'avaient donc aucun header Reply-To.

**Impact** : Les reponses du client ne revenaient pas dans KeyBuzz car le Reply-To n'etait pas defini.

### 2. Sujets MIME non decodes (UTF-8/ISO-8859-1)

**Cause racine** : La fonction `decodeMimeToken()` (amazonForward.ts) ignorait le parametre `charset` et decodait tous les octets en UTF-8. Pour les emails encodes en ISO-8859-1 ou Windows-1252, les accents etaient corrompus (ex: `é` = 0xE9 en ISO-8859-1, interprete comme octet UTF-8 invalide).

**Bug secondaire** : `decodeMimeWords()` ne gerait pas le pliage RFC 2047 (CRLF+whitespace entre mots encodes), causant des sujets tronques.

**Preuves DB** : 4 conversations avec sujets bruts non decodes (`=?UTF-8?Q?...?=`).

---

## Corrections

### FIX 1 : Reply-To fallback (outboundWorker.ts)

```diff
- replyTo: delivery.reply_to,
+ replyTo: delivery.reply_to || inboundFromAddress,
```

Quand `delivery.reply_to` est null, le Reply-To utilise l'adresse inbound validee du tenant (ex: `amazon.ecomlg-001.de.49ecbe@inbound.keybuzz.io`).

### FIX 2a : Charset support (amazonForward.ts — decodeMimeToken)

```diff
- return Buffer.from(bytes).toString('utf-8');
+ const cs = charset.toUpperCase().replace(/[_-]/g, '');
+ const bufEnc = (cs === 'ISO88591' || cs === 'LATIN1' || cs === 'WINDOWS1252' || cs === 'CP1252')
+   ? 'latin1' : (cs === 'USASCII' || cs === 'ASCII') ? 'ascii' : 'utf-8';
+ return Buffer.from(bytes).toString(bufEnc);
```

Charsets supportes : UTF-8, ISO-8859-1, Latin-1, Windows-1252, ASCII.

### FIX 2b : Multiline MIME folding (amazonForward.ts — decodeMimeWords)

```diff
+ let unfolded = text.replace(/\?=\s*\r?\n\s*=\?/g, '?= =?');
```

Les mots encodes separes par CRLF+whitespace sont maintenant correctement joints avant decodage.

### FIX 2c : Q-encoding boundary check

```diff
- } else if (encoded[i] === '=' && i + 2 <= encoded.length) {
+ } else if (encoded[i] === '=' && i + 2 < encoded.length) {
+   const hex = parseInt(encoded.substring(i + 1, i + 3), 16);
+   if (!isNaN(hex)) { bytes.push(hex); i += 3; }
+   else { bytes.push(encoded.charCodeAt(i)); i++; }
```

Verification stricte de la longueur + gestion des sequences hex invalides.

---

## Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/workers/outboundWorker.ts` | Reply-To fallback inboundFromAddress |
| `src/modules/inbound/amazonForward.ts` | decodeMimeToken charset + decodeMimeWords folding |

---

## Validation DEV

### Tests encodage (7/7 PASS)

| Test | Input | Attendu | Resultat |
|------|-------|---------|----------|
| T1 UTF-8 Q | `=?UTF-8?Q?...arriv=C3=A9?=` | `arrivé` | PASS |
| T2 ISO-8859-1 Q | `=?ISO-8859-1?Q?R=E9ponse_=E0?=` | `Réponse à` | PASS |
| T3 UTF-8 B | `=?UTF-8?B?...?=` | `Demande d'annulation` | PASS |
| T4 Plain text | `Notification...` | passthrough | PASS |
| T5 Multiline | `=?UTF-8?Q?...?=\r\n =?UTF-8?Q?...?=` | joined | PASS |
| T6 Windows-1252 | `=?Windows-1252?Q?Fran=E7ois?=` | `François` | PASS |
| T7 Reply-To | inbound address lookup | `amazon.ecomlg-001.de.49ecbe@inbound.keybuzz.io` | PASS |

### Health check

- API DEV : `{"status":"ok"}` ✓
- Pods : Running ✓

---

## Non-regressions

- Amazon outbound SMTP : inchange (seul Reply-To ajoute)
- Email inbound : inchange (decodeMimeWords plus robuste)
- Pieces jointes : inchange
- Autopilot : inchange
- Inbox : inchange

---

## Versions

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.144-replyto-subject-fix-dev` | `v3.5.144-replyto-subject-fix-prod` |
| Worker | `v3.6.09-replyto-subject-fix-dev` | `v3.6.09-replyto-subject-fix-prod` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.143-inbound-body-email-fix-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.08-inbound-body-email-fix-dev -n keybuzz-api-dev
```

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.143-inbound-body-email-fix-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.08-inbound-body-email-fix-prod -n keybuzz-api-prod
```

---

## Verdict

REPLY FLOW FULLY FIXED — UTF8 SUBJECT OK — NO DATA LOSS — TENANT SAFE — ROLLBACK READY
