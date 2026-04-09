# PH-MAIL-FIX-DELIVERABILITY-02A — Fix Deliverabilite SAFE

> Date : 4 avril 2026
> Type : Fix SAFE (TLS + myorigin uniquement)
> Serveur modifie : **mail-core-01 uniquement**
> Pipeline Amazon : **NON TOUCHE**
> MX servers : **NON TOUCHES**

---

## RESUME

| Fix | Statut | Resultat |
|---|---|---|
| **F1 — TLS Let's Encrypt** | **FAIT** | Cert valide `CN = mail.keybuzz.io`, Let's Encrypt E7 |
| **F2 — SPF ~all → -all** | **A FAIRE MANUELLEMENT** | API DNS post-migration non accessible |
| **F3 — myorigin → keybuzz.io** | **FAIT** | Return-Path aligne sur keybuzz.io |

---

## F1 — TLS Let's Encrypt

### Avant

```
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key
Subject: CN = mail-core-01 (SELF-SIGNED)
```

### Apres

```
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.keybuzz.io/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.keybuzz.io/privkey.pem
Subject: CN = mail.keybuzz.io
Issuer: Let's Encrypt E7
Expires: 3 juillet 2026
Renouvellement: automatique (certbot timer)
```

### Verification TLS

| Port | Protocole | Certificat | Verification |
|---|---|---|---|
| 25 (SMTP) | TLSv1.3 / TLS_AES_256_GCM_SHA384 | CN = mail.keybuzz.io | **OK** |
| 587 (Submission) | TLSv1.3 / TLS_AES_256_GCM_SHA384 | CN = mail.keybuzz.io | **OK** |

### Impact

- Gmail, Outlook, Free verront un certificat **Let's Encrypt valide** au lieu du self-signed
- Le hostname du cert **matche** le HELO/EHLO (`mail.keybuzz.io`)
- Elimination de la penalite TLS majeure

### Rollback

```
postconf -e "smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem"
postconf -e "smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key"
postfix reload
```

Backup : `/etc/postfix/main.cf.bak.ph-mail-fix-02a`

---

## F2 — SPF (A FAIRE MANUELLEMENT)

### Pourquoi pas automatique

Apres la migration DNS de keybuzz.io vers la nouvelle Hetzner Console, les deux tokens API ne fonctionnent plus :
- Token DNS Console (`J8Wq...`) : HTTP 404 (zone migree)
- Token Cloud (`PvaK...`) : HTTP 401 (pas un token DNS)

Un nouveau token DNS doit etre genere dans la nouvelle Hetzner Console.

### Action requise

Dans la console Hetzner (https://console.hetzner.cloud) :
1. Aller dans **DNS** > Zone `keybuzz.io`
2. Trouver l'enregistrement TXT racine (`@`) contenant `v=spf1`
3. Modifier :

```
AVANT : v=spf1 ip4:49.13.35.167 mx ~all
APRES : v=spf1 ip4:49.13.35.167 mx -all
```

4. Sauvegarder

### Verification apres changement

```
dig keybuzz.io TXT +short | grep spf
```

Resultat attendu : `"v=spf1 ip4:49.13.35.167 mx -all"`

---

## F3 — myorigin

### Avant

```
myorigin = inbound.keybuzz.io
```

### Apres

```
myorigin = keybuzz.io
```

### Impact

| Element | Avant | Apres | Impact |
|---|---|---|---|
| Bounces DSN | `MAILER-DAEMON@inbound.keybuzz.io` | `MAILER-DAEMON@keybuzz.io` | Aligne |
| Emails systeme | `root@inbound.keybuzz.io` | `root@keybuzz.io` | Aligne |
| Emails application | `alerts@keybuzz.io` (inchange) | `alerts@keybuzz.io` | Aucun |
| Emails marketplace | `amazon.*@inbound.keybuzz.io` (inchange) | Idem | Aucun |
| DKIM signing | `d=keybuzz.io` (inchange) | Idem | Aucun |
| SPF evaluation | Sur `inbound.keybuzz.io` (Return-Path) | Sur `keybuzz.io` | Meilleur alignement |

### Rollback

```
postconf -e "myorigin=inbound.keybuzz.io"
postfix reload
```

---

## VERIFICATION NON-REGRESSION

### Pipeline Amazon — NON TOUCHE

| Element | Valeur | Statut |
|---|---|---|
| `transport_maps` | `hash:/etc/postfix/transport` | **Inchange** |
| `/etc/postfix/transport` | `inbound.keybuzz.io    webhook:` | **Inchange** |
| `postfix_webhook.sh` | md5: `7eaeefa41a91...`, date: 16 mars | **Inchange** |
| `relay_domains` | `inbound.keybuzz.io` | **Inchange** |
| `mydestination` | `localhost` | **Inchange** |

### MX servers — NON TOUCHES

| Serveur | relay_domains | relayhost | Statut |
|---|---|---|---|
| MX-01 | `inbound.keybuzz.io` | `[10.0.0.160]:25` | **Inchange** |
| MX-02 | `inbound.keybuzz.io` | `[10.0.0.160]:25` | **Inchange** |

### Milters — NON TOUCHES

| Parametre | Valeur | Statut |
|---|---|---|
| `smtpd_milters` | `inet:localhost:8891` | **Inchange** |
| `non_smtpd_milters` | `inet:localhost:8891` | **Inchange** |
| OpenDKIM | active, SigningTable intact | **Inchange** |

### IP d'envoi — NON TOUCHEE

```
smtp_bind_address = 49.13.35.167 (inchange)
```

---

## ETAT ACTUEL POST-FIX

```
myhostname     = mail.keybuzz.io
myorigin       = keybuzz.io                                    ← MODIFIE
cert TLS       = /etc/letsencrypt/live/mail.keybuzz.io/...     ← MODIFIE
relay_domains  = inbound.keybuzz.io                            (inchange)
transport_maps = hash:/etc/postfix/transport                   (inchange)
mydestination  = localhost                                     (inchange)
milters        = inet:localhost:8891                            (inchange)
smtp_bind      = 49.13.35.167                                  (inchange)
```

---

## CE QUI RESTE A FAIRE

| Action | Type | Qui |
|---|---|---|
| **SPF ~all → -all** | DNS Hetzner Console | **Ludovic** (manuel) |
| relay_domains + mydestination pour @keybuzz.io | Postfix MX + core | Phase suivante |
| Delisting Barracuda mx-01/mx-02 | Formulaire web | Phase suivante |
| Verification Spamhaus | check.spamhaus.org | Phase suivante |
| Fix webhook inbound (pipeline Amazon bloque) | Investigation | Phase separee |
| DMARC p=quarantine → p=reject | DNS | Apres validation |

---

## AMELIORATION DELIVERABILITE ATTENDUE

### Avant ce fix

| Critere | Etat |
|---|---|
| TLS cert | Self-signed (CN=mail-core-01) — **penalite majeure** |
| TLS verification | ECHEC — cert non fiable |
| myorigin | inbound.keybuzz.io — mismatch avec From |
| SPF | ~all — softfail |

### Apres ce fix

| Critere | Etat |
|---|---|
| TLS cert | **Let's Encrypt** (CN=mail.keybuzz.io) — **fiable** |
| TLS verification | **OK** — cert valide, hostname match |
| myorigin | **keybuzz.io** — aligne avec From |
| SPF | ~all (**en attente fix manuel**) |

Le fix TLS seul devrait significativement ameliorer le placement inbox car le certificat self-signed etait la cause #1 de penalite identifiee par les providers.
