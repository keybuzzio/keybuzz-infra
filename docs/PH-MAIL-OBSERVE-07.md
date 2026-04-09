# PH-MAIL-OBSERVE-07 — Validation Deliverability Reelle

> Date : 4 avril 2026
> Phase : PH-MAIL-OBSERVE-07
> Type : observation + tests reels (lecture seule)
> Serveur : mail-core-01 (10.0.0.160)

---

## 1. RESUME EXECUTIF

Les fixes appliques (TLS Let's Encrypt, SPF `-all`, myorigin aligne) sont **techniquement operationnels et valides**. Les 3 verifications d'authentification email (SPF, DKIM, DMARC) passent toutes avec succes sur Gmail. Le TLS est en version 1.3 avec chiffrement fort.

Cependant, les emails arrivent encore en **spam** sur Gmail en raison de la **reputation historique** du domaine/IP, accumulee pendant la periode ou les emails etaient envoyes avec un certificat auto-signe et un SPF en `~all`.

**Verdict : DELIVERABILITY IMPROVED (techniquement parfait, reputation en cours de rehabilitation)**

---

## 2. EMAILS DE TEST ENVOYES

### Envois depuis mail-core-01

| # | Destinataire | Provider | Statut Postfix | DSN | TLS |
|---|---|---|---|---|---|
| 1 | compta.ecomlg@gmail.com | Gmail | `status=sent` | 2.0.0 | Trusted TLS |
| 2 | ludovic@ecomlg.fr | OVH | `status=sent` | 2.0.0 | Trusted TLS |
| 3 | ludo.gonthier@free.fr | Free | `status=sent` | 2.6.0 | Trusted TLS |
| 4 | ecomlg26@gmail.com | Gmail | `status=sent` | 2.0.0 | Trusted TLS |

Tous les emails ont ete acceptes par les serveurs destinataires avec "Trusted TLS connection established."

### Logs Postfix confirmes

```
to=<compta.ecomlg@gmail.com>, relay=gmail-smtp-in.l.google.com, dsn=2.0.0, status=sent
to=<ludovic@ecomlg.fr>, relay=redirect.ovh.net, dsn=2.0.0, status=sent
to=<ludo.gonthier@free.fr>, relay=mx1.free.fr, dsn=2.6.0, status=sent
to=<ecomlg26@gmail.com>, relay=gmail-smtp-in.l.google.com, dsn=2.0.0, status=sent
```

Aucun defer, aucun bounce, aucune erreur TLS.

---

## 3. HEADERS COMPLETS — Gmail (ecomlg26@gmail.com)

Source : "Afficher l'original" Gmail, verification directe navigateur.

### Tableau d'authentification

| Verification | Resultat | Detail |
|---|---|---|
| **SPF** | **PASS** | `domain of alerts@keybuzz.io designates 49.13.35.167 as permitted sender` |
| **DKIM** | **PASS** | `header.i=@keybuzz.io header.s=default header.b=MvNyadcU` |
| **DMARC** | **PASS** | `p=QUARANTINE sp=QUARANTINE dis=NONE header.from=keybuzz.io` |

### Headers cles extraits

```
Return-Path: <alerts@keybuzz.io>
From: KeyBuzz Support <alerts@keybuzz.io>
To: ecomlg26@gmail.com

Received: from mail.keybuzz.io (mail.keybuzz.io. [49.13.35.167])
        by mx.google.com with ESMTPS id 2adb3069b0e04-...
        (version=TLS1_3 cipher=TLS_AES_256_GCM_SHA384 bits=256/256)

DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=keybuzz.io; s=default; t=1775326073
Received: by mail.keybuzz.io (Postfix, from userid 0) id 9EA453E621
```

### Placement

| Provider | Recu | Inbox | Spam | Raison |
|---|---|---|---|---|
| Gmail (ecomlg26) | Oui | Non | **Oui** | "Ce message est semblable a des messages identifies comme spam par le passe" |
| OVH (ludovic@ecomlg.fr) | Oui | A verifier par l'utilisateur | — | — |
| Free (ludo.gonthier@free.fr) | Oui | A verifier par l'utilisateur | — | — |

---

## 4. ALIGNEMENT DOMAINES

| Champ | Valeur | Aligne |
|---|---|---|
| From | `alerts@keybuzz.io` | OUI |
| Return-Path | `alerts@keybuzz.io` | OUI |
| DKIM domain (d=) | `keybuzz.io` | OUI |
| SPF domain | `keybuzz.io` | OUI |
| HELO/hostname | `mail.keybuzz.io` | OUI |
| Reverse DNS (PTR) | `mail.keybuzz.io` | OUI |

**Alignement parfait** — tous les domaines sont coherents sur `keybuzz.io`.

---

## 5. VALIDATION TLS

| Critere | Valeur |
|---|---|
| Version TLS | **TLS 1.3** |
| Cipher | `TLS_AES_256_GCM_SHA384` |
| Bits | 256 |
| Certificat | Let's Encrypt (E7) |
| CN | `mail.keybuzz.io` |
| Validite | Valide (installe PH-MAIL-FIX-DELIVERABILITY-02A) |
| Renouvellement auto | Certbot timer actif |

Gmail confirme la connexion avec `ESMTPS` (chiffre), ce qui est le meilleur signal possible.

---

## 6. CONFIGURATION POSTFIX VERIFIEE

| Parametre | Valeur | Statut |
|---|---|---|
| `smtpd_tls_cert_file` | `/etc/letsencrypt/live/mail.keybuzz.io/fullchain.pem` | OK |
| `smtpd_tls_key_file` | `/etc/letsencrypt/live/mail.keybuzz.io/privkey.pem` | OK |
| `myorigin` | `keybuzz.io` | OK |
| `myhostname` | `mail.keybuzz.io` | OK |

---

## 7. DNS VERIFIE

| Enregistrement | Valeur | Statut |
|---|---|---|
| SPF | `v=spf1 ip4:49.13.35.167 mx -all` | OK (`-all` durci) |
| DKIM | `default._domainkey.keybuzz.io` — cle RSA active | OK |
| DMARC | `_dmarc.keybuzz.io` — `p=quarantine` | OK |
| MX | `mail.keybuzz.io` | OK |
| PTR | `49.13.35.167` → `mail.keybuzz.io` | OK |

La signature DKIM est faite par OpenDKIM avec le `SigningTable` configure pour `*@keybuzz.io`.

---

## 8. COMPARAISON AVANT / APRES FIXES

| Critere | AVANT (pre-PH-MAIL-FIX) | APRES (post-fixes) | Amelioration |
|---|---|---|---|
| **TLS** | Certificat auto-signe | Let's Encrypt (TLS 1.3) | **ENORME** |
| **SPF** | `~all` (softfail) | `-all` (hardfail) | **FORTE** |
| **myorigin** | `inbound.keybuzz.io` | `keybuzz.io` | **MOYENNE** |
| **Return-Path** | `@inbound.keybuzz.io` (desaligne) | `@keybuzz.io` (aligne) | **FORTE** |
| **SPF result Gmail** | SOFTFAIL ou NEUTRAL | **PASS** | **CRITIQUE** |
| **DKIM result Gmail** | PASS (deja OK avant) | **PASS** | Stable |
| **DMARC result Gmail** | FAIL (misalignment) | **PASS** | **CRITIQUE** |
| **TLS version Gmail** | TLS 1.2 (self-signed, warning) | **TLS 1.3** (trusted) | **FORTE** |
| **Placement Gmail** | Spam (multiple causes) | Spam (reputation seule) | En progres |

---

## 9. ANALYSE : POURQUOI ENCORE EN SPAM ?

### Cause unique restante : reputation historique

Gmail indique : **"Ce message est semblable a des messages identifies comme spam par le passe"**

Cela signifie :
- La configuration technique est **parfaite** (SPF/DKIM/DMARC PASS, TLS 1.3, alignement complet)
- Gmail a memorise que les emails precedents de `keybuzz.io` / `49.13.35.167` ont ete classes spam
- Cette "memoire" prend **2 a 6 semaines** pour se rehabiliter avec des signaux positifs

### Ce n'est PAS :
- Un probleme SPF (PASS)
- Un probleme DKIM (PASS)
- Un probleme DMARC (PASS)
- Un probleme TLS (1.3 trusted)
- Un probleme d'alignement (parfait)
- Un probleme de blacklist (IPs verifiees clean lors de l'audit)

---

## 10. ACTIONS RECOMMANDEES POUR REHABILITATION REPUTATION

### Priorite 1 — Immediat

| # | Action | Effort | Impact |
|---|---|---|---|
| R1 | Inscrire le domaine sur **Google Postmaster Tools** (`postmaster.google.com`) | 10 min | Surveillance reputation |
| R2 | Marquer manuellement les emails test comme "Non-spam" sur Gmail | 2 min | Signal positif immediat |
| R3 | Envoyer des emails reels utiles (pas de mass mailing) | Continu | Construction reputation |

### Priorite 2 — Court terme (1-2 semaines)

| # | Action | Effort | Impact |
|---|---|---|---|
| R4 | Limiter le volume d'envoi a quelques dizaines d'emails/jour | Continu | Evite les pics suspects |
| R5 | S'assurer que les bounces sont correctement geres | Verification | Hygiene liste |
| R6 | Ajouter un lien de desinscription dans les emails marketing | Dev | Conformite |

### Priorite 3 — Moyen terme (2-6 semaines)

| # | Action | Effort | Impact |
|---|---|---|---|
| R7 | Passer DMARC de `quarantine` a `reject` | 2 min DNS | Signal confiance fort |
| R8 | Ajouter un enregistrement BIMI (logo dans Gmail) | 30 min | Confiance visuelle |
| R9 | Surveiller les taux de spam via Postmaster Tools | Continu | Alertes precoces |

---

## 11. LOGS POSTFIX — AUCUNE ANOMALIE

```
dsn=2.0.0, status=sent (250 2.0.0 OK)
Trusted TLS connection established to gmail-smtp-in.l.google.com
Trusted TLS connection established to redirect.ovh.net
Trusted TLS connection established to mx1.free.fr
```

Aucun defer, aucun bounce, aucun rejet, aucune erreur TLS. Pipeline d'envoi 100% operationnel.

---

## 12. VERDICT FINAL

```
+---------------------------------------------+
|  DELIVERABILITY IMPROVED                    |
|                                             |
|  Technique : PARFAIT (SPF/DKIM/DMARC PASS) |
|  TLS      : PARFAIT (1.3, Let's Encrypt)   |
|  Alignement: PARFAIT (keybuzz.io partout)   |
|  Placement : SPAM (reputation historique)   |
|  Pronostic : Inbox dans 2-6 semaines        |
+---------------------------------------------+
```

### Comparaison score technique

| Metrique | Avant fixes | Apres fixes |
|---|---|---|
| Score authentification | 1/3 (DKIM seul) | **3/3** (SPF + DKIM + DMARC) |
| TLS | Penalise (self-signed) | **Optimal** (TLS 1.3 trusted) |
| Alignement | Desaligne (inbound.keybuzz.io) | **Aligne** (keybuzz.io) |
| Causes spam | 5+ causes techniques | **1 seule** (reputation) |

---

## 13. NON-REGRESSION

| Element | Statut |
|---|---|
| Pipeline Amazon inbound | OK (non impacte) |
| Webhook postfix_webhook.sh | OK (non modifie) |
| MX servers (mx-01, mx-02) | OK (non touches) |
| OpenDKIM | OK (fonctionnel) |
| Postfix envoi SMTP | OK (tous emails delivres) |
| Transport maps | OK (non modifies) |

---

## 14. STOP POINT

Aucune modification effectuee durant cette phase (observation uniquement).
La rehabilitation de la reputation est un processus naturel qui prendra 2 a 6 semaines.
Les actions R1-R3 sont recommandees pour accelerer le processus.
