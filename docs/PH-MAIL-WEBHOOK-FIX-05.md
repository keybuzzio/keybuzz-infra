# PH-MAIL-WEBHOOK-FIX-05 — Fix Webhook Recipient

> Date : 4 avril 2026
> Serveur modifie : **mail-core-01 uniquement**
> Fichiers modifies : `master.cf` + `postfix_webhook.sh`
> MX / relay_domains / transport_maps : **NON TOUCHES**

---

## VERDICT : WEBHOOK RECIPIENT FIXED

---

## 1. CAUSE RACINE

### Le bug

Le script `postfix_webhook.sh` (ligne 44) extrait le destinataire depuis le **header `To:`** de l'email :

```bash
TO=$(grep -i "^To:" "$TEMP_EMAIL" | head -1 | sed 's/^To: *//;s/<//g;s/>//g;s/"//g' | tr -d '\r')
```

Pour certaines notifications Amazon (type "sin buzon electronico" / "non rispondere"), le header `To:` contient l'email original du vendeur (`contact@srvperformance.com`), pas l'adresse inbound KeyBuzz.

L'**envelope recipient** Postfix (l'adresse a laquelle l'email a ete livre) est toujours correct : `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`.

### Consequence

Le backend recevait `to: contact@srvperformance.com` et rejetait avec :

```json
{"error": "Invalid recipient format"}
```

Le script retournait `exit 75` (temporary failure), Postfix reessayait, et les emails s'accumulaient en queue deferred.

### Pourquoi `${recipient}` est la source de verite

L'envelope recipient est l'adresse que le MTA utilise pour router l'email. C'est l'adresse configuree dans Amazon Seller Central. Le header `To:` est un champ libre que l'expediteur (Amazon) peut remplir differemment.

---

## 2. MODIFICATIONS

### Fichier 1 : `/etc/postfix/master.cf` (ligne 48)

**AVANT :**

```
webhook   unix  -       n       n       -       -       pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh
```

**APRES :**

```
webhook   unix  -       n       n       -       -       pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh ${recipient}
```

Changement : ajout de `${recipient}` en argument. Postfix passe maintenant l'envelope recipient au script.

### Fichier 2 : `/usr/local/bin/postfix_webhook.sh` (ligne 44)

**AVANT (1 ligne) :**

```bash
TO=$(grep -i "^To:" "$TEMP_EMAIL" | head -1 | sed 's/^To: *//;s/<//g;s/>//g;s/"//g' | tr -d '\r')
```

**APRES (7 lignes) :**

```bash
# PH-WEBHOOK-FIX-05: Use Postfix envelope recipient ($1) as primary source
ENVELOPE_RECIPIENT="$1"
HEADER_TO=$(grep -i "^To:" "$TEMP_EMAIL" | head -1 | sed 's/^To: *//;s/<//g;s/>//g;s/"//g' | tr -d '\r')
if [ -n "$ENVELOPE_RECIPIENT" ]; then
    TO="$ENVELOPE_RECIPIENT"
else
    TO="$HEADER_TO"
fi
```

Logique :
- Source primaire : `$1` (envelope recipient Postfix)
- Fallback : header `To:` (si `$1` est vide — ne devrait pas arriver mais securite)
- Variable `$TO` inchangee pour le reste du script (SAV routing, payload, logs)

---

## 3. DIFF LOGIQUE

| Aspect | Avant | Apres |
|---|---|---|
| Source `TO` | Header `To:` email | Envelope recipient Postfix (`$1`) |
| `master.cf` argv | `postfix_webhook.sh` | `postfix_webhook.sh ${recipient}` |
| SAV routing | `TO_LOCAL` derive de `TO` | Identique (meme `$TO`) |
| Payload `'to'` | Header `To:` | Envelope recipient |
| Log `INBOUND_RECEIVED` | Affiche header `To:` | Affiche envelope recipient |
| Message standard | `TO` = inbound (OK) | `TO` = inbound (OK) |
| Notification atypique | `TO` = email vendeur (400) | `TO` = inbound (**FIXE**) |

---

## 4. TESTS DE VALIDATION

### CAS 1 — Message Amazon standard

Envelope = `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`
Header `To:` = `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`

```
[17:38:05] INBOUND_RECEIVED to=amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
[17:38:06] INBOUND_POST_OK endpoint=DEV status=200
[17:38:07] INBOUND_POST_OK endpoint=PROD status=200
[17:38:07] INBOUND_RESULT success=2 fail=0
```

**Resultat : OK** — aucun changement de comportement.

### CAS 2 — Notification Amazon atypique

Envelope = `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`
Header `To:` = `contact@srvperformance.com` (DIFFERENT)

```
[17:38:10] INBOUND_RECEIVED to=amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
[17:38:10] INBOUND_POST_OK endpoint=DEV status=200
[17:38:11] INBOUND_POST_OK endpoint=PROD status=200
[17:38:11] INBOUND_RESULT success=2 fail=0
```

**Resultat : FIXE** — le `to` log affiche l'envelope recipient, pas le header `To:`.
Avant le fix, ce cas provoquait `400 Invalid recipient format`.

### Postfix pipe events

```
17:38:07 dsn=2.0.0 status=sent (delivered via webhook service) — CAS 1
17:38:11 dsn=2.0.0 status=sent (delivered via webhook service) — CAS 2
```

---

## 5. NON-REGRESSION

| Element | Statut |
|---|---|
| `transport_maps` | `hash:/etc/postfix/transport` — **inchange** |
| `relay_domains` | `inbound.keybuzz.io` — **inchange** |
| `mydestination` | `localhost` — **inchange** |
| `myorigin` | `keybuzz.io` — **inchange** |
| Webhook endpoints DEV | `https://backend-dev.keybuzz.io/...` — **inchange** |
| Webhook endpoints PROD | `https://backend.keybuzz.io/...` — **inchange** |
| Cle DEV | `/opt/keybuzz/secrets/webhook_key` — **OK** |
| Cle PROD | `/opt/keybuzz/secrets/webhook_key_prod` — **OK** |
| SAV routing | `sav.*@inbound.keybuzz.io` — **inchange** |
| MX-01 | `relay_domains=inbound.keybuzz.io` — **inchange** |
| MX-02 | `relay_domains=inbound.keybuzz.io` — **inchange** |
| OpenDKIM | active, SigningTable intact — **inchange** |
| TLS cert | Let's Encrypt `mail.keybuzz.io` — **inchange** |
| Postfix status | active, PID 755403 — **OK** |
| Permissions script | `755 root:root` — **OK** |
| Bash syntax check | exit 0 — **OK** |
| `postfix check` | exit 0 — **OK** |

---

## 6. ROLLBACK

### master.cf

```bash
cp /etc/postfix/master.cf.bak.ph-webhook-fix-05 /etc/postfix/master.cf
postfix reload
```

### postfix_webhook.sh

```bash
cp /usr/local/bin/postfix_webhook.sh.bak.ph-webhook-fix-05 /usr/local/bin/postfix_webhook.sh
chmod +x /usr/local/bin/postfix_webhook.sh
```

### Fichiers de backup

```
/etc/postfix/master.cf.bak.ph-webhook-fix-05
/usr/local/bin/postfix_webhook.sh.bak.ph-webhook-fix-05
```

---

## 7. METADATA

| Cle | Valeur |
|---|---|
| Script avant | md5: `7eaeefa41a9104811c42149740ebacd0`, 247 lignes, 10339 octets |
| Script apres | md5: `bcaac3ff23e07dfec92b9e54df23523f`, 254 lignes, 10540 octets |
| Delta | +7 lignes, +201 octets |
| master.cf | +1 mot (`${recipient}`) |
| Postfix reload | 1 seul, succes |
| Tests | 2 cas (standard + atypique), 4/4 POST OK |
