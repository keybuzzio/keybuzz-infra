# PH-MAIL-AUDIT-DELIVERABILITY-01 — Audit Deliverabilite Email keybuzz.io

> Date : 4 avril 2026
> Type : Audit lecture seule (aucune modification)
> Environnement : INFRA mail (mail-core-01, mail-mx-01, mail-mx-02)
> Statut : **7 problemes critiques identifies**

---

## 1. RESUME EXECUTIF

L'audit revele **7 causes directes** de mise en spam. Le ratio envoye/differe est catastrophique :
**199 emails envoyes avec succes vs 9 183 differes** (97.9% en echec/attente).

### Causes par ordre de gravite

| # | Cause | Severite | Impact |
|---|---|---|---|
| 1 | **Certificat TLS self-signed (snakeoil)** | CRITIQUE | Gmail/Outlook penalisent immediatement |
| 2 | **MX rejettent @keybuzz.io (Relay access denied)** | CRITIQUE | 70 emails internes bloques, boucle de reessai infinie |
| 3 | **IP sur Barracuda BRBL** (mx-01, mx-02) | CRITIQUE | Providers utilisant Barracuda rejettent |
| 4 | **SPF softfail (~all)** au lieu de hardfail (-all) | GRAVE | Providers interpretent comme "possiblement spam" |
| 5 | **Mismatch myorigin (inbound.keybuzz.io) vs From (@keybuzz.io)** | GRAVE | Alignement DMARC SPF echoue en mode strict |
| 6 | **Dovecot permission denied** sur /etc/dovecot/users | MOYEN | IMAP potentiellement casse |
| 7 | **Rspamd non integre** dans le pipeline Postfix milter | FAIBLE | Pas de filtrage anti-spam entrant |

---

## 2. INFRASTRUCTURE MAIL

### Serveurs

| Serveur | IP publique | IP privee | IP flottante | Role |
|---|---|---|---|---|
| mail-core-01 | 37.27.251.162 | 10.0.0.160 | **49.13.35.167** | SMTP sortant, Postfix, DKIM, Dovecot |
| mail-mx-01 | 91.99.66.6 | 10.0.0.161 | — | MX entrant (priorite 10) |
| mail-mx-02 | 91.99.87.76 | 10.0.0.162 | — | MX entrant (priorite 20) |

### Flux email

```
Application (K8s) → mail-core-01 (SMTP, ip bind 49.13.35.167) → Internet
                                                                    ↓
Internet → MX-01/MX-02 (port 25) → relay vers mail-core-01 (10.0.0.160:25)
                                     ↓
                              transport_maps → webhook (inbound.keybuzz.io)
```

### Services actifs sur mail-core-01

| Service | Statut |
|---|---|
| Postfix | active (running) |
| OpenDKIM | active (running) depuis 27 mars 2026 |
| Dovecot | active (running) — **ERREUR permission** |
| Rspamd | active (running) — **non integre milter** |

### Domaines geres

| Domaine | Role | MX | SPF |
|---|---|---|---|
| keybuzz.io | Domaine principal | mail-mx-01/02.keybuzz.io | `v=spf1 ip4:49.13.35.167 mx ~all` |
| inbound.keybuzz.io | Reception Amazon/marketplace | mail-mx-01/02.keybuzz.io | `v=spf1 ip4:49.13.35.167 -all` |
| keybuzz.pro | Email perso (OVH) | mx0-4.mail.ovh.net | `v=spf1 include:mx.ovh.com -all` |

---

## 3. AUDIT DNS COMPLET

### 3.1 SPF

| Domaine | Enregistrement SPF | Verdict |
|---|---|---|
| keybuzz.io | `v=spf1 ip4:49.13.35.167 mx ~all` | **PROBLEME : ~all (softfail)** |
| inbound.keybuzz.io | `v=spf1 ip4:49.13.35.167 -all` | OK |

**Analyse** :
- L'IP `49.13.35.167` est correcte (floating IP de mail-core-01, utilisee via `smtp_bind_address`)
- Le mecanisme `mx` inclut les IPs des MX (91.99.66.6, 91.99.87.76) — correct
- Le qualificateur `~all` (softfail) indique aux providers "les emails de sources non listees sont suspects mais ne pas rejeter"
- **Devrait etre `-all` (hardfail)** pour affirmer : "seules ces sources sont autorisees, tout le reste est frauduleux"
- Les providers (Gmail, Outlook) penalisent le `~all` vs `-all` dans leur scoring spam

### 3.2 DKIM

| Selecteur | Domaine | Cle | Statut |
|---|---|---|---|
| `default._domainkey.keybuzz.io` | keybuzz.io | RSA 2048-bit | **PRESENT** — cle valide |
| `kbz1._domainkey.keybuzz.io` | keybuzz.io | RSA 2048-bit | PRESENT — ancienne cle (non utilisee dans SigningTable) |
| `kbz1._domainkey.inbound.keybuzz.io` | inbound.keybuzz.io | RSA 2048-bit | **PRESENT** — cle valide |

**Config OpenDKIM** :
```
KeyTable:
  kbz1._domainkey.inbound.keybuzz.io → inbound.keybuzz.io:kbz1:/etc/opendkim/keys/inbound.keybuzz.io/kbz1.private
  default._domainkey.keybuzz.io → keybuzz.io:default:/etc/opendkim/keys/keybuzz.io/default.private

SigningTable:
  *@inbound.keybuzz.io → kbz1._domainkey.inbound.keybuzz.io
  *@keybuzz.io → default._domainkey.keybuzz.io
```

**Verdict** : DKIM correctement configure pour les deux domaines. Les cles sont presentes et les tables de signature matchent.

### 3.3 DMARC

| Domaine | Politique | Alignement | Reporting |
|---|---|---|---|
| keybuzz.io | `p=quarantine; pct=100` | **Relaxed (defaut)** | rua: dmarc-reports@keybuzz.io, ruf: dmarc-fail@keybuzz.io |
| inbound.keybuzz.io | `p=quarantine; adkim=s; aspf=s; pct=100` | **STRICT** | rua/ruf: dmarc@keybuzz.io |

**Analyse** :
- `p=quarantine` est correct : les emails echouant DMARC vont en spam (pas rejetes)
- keybuzz.io utilise l'alignement **relaxed** (defaut) — c'est un atout car le mismatch myorigin est tolere
- inbound.keybuzz.io utilise l'alignement **strict** — OK car myorigin match
- `fo=1` active le reporting pour chaque echec (bien)

### 3.4 PTR / rDNS

| IP | PTR attendu | PTR reel | Verdict |
|---|---|---|---|
| 49.13.35.167 | mail.keybuzz.io | **mail.keybuzz.io** | **OK** |
| 91.99.66.6 | mail-mx-01.keybuzz.io | **mail-mx-01.keybuzz.io** | **OK** |
| 91.99.87.76 | mail-mx-02.keybuzz.io | **mail-mx-02.keybuzz.io** | **OK** |

**Verdict** : rDNS parfaitement configure. Chaque IP pointe vers le hostname correct.

### 3.5 Autres enregistrements DNS

| Type | Enregistrement | Statut |
|---|---|---|
| BIMI | `v=BIMI1; l=https://cdn.keybuzz.io/bimi/logo.svg` | Present (keybuzz.io) |
| MTA-STS | `v=STSv1; id=20250919` (keybuzz.io) | Present — **ID obsolete (sept 2025)** |
| TLSRPT | `v=TLSRPTv1; rua=mailto:tlsrpt@keybuzz.io` | Present |
| CAA | `issue "letsencrypt.org"`, `issuewild "letsencrypt.org"` | Present |
| SRV | `_imaps._tcp → 993 mail.keybuzz.io` | Present |
| SRV | `_submission._tcp → 587 mail.keybuzz.io` | Present |

---

## 4. AUDIT POSTFIX

### 4.1 mail-core-01 (SMTP sortant)

| Parametre | Valeur | Commentaire |
|---|---|---|
| `myhostname` | `mail.keybuzz.io` | OK |
| `myorigin` | **`inbound.keybuzz.io`** | **PROBLEME** — devrait etre `keybuzz.io` |
| `mydestination` | `localhost` | OK (pas de livraison locale) |
| `relayhost` | (vide) | OK (livraison directe) |
| `smtp_bind_address` | `49.13.35.167` | OK (floating IP) |
| `smtp_helo_name` | `$myhostname` = `mail.keybuzz.io` | OK |
| `smtp_tls_security_level` | `may` | OK (TLS opportuniste) |
| `smtpd_tls_cert_file` | **`/etc/ssl/certs/ssl-cert-snakeoil.pem`** | **CRITIQUE — self-signed !** |
| `smtpd_tls_key_file` | `/etc/ssl/private/ssl-cert-snakeoil.key` | **CRITIQUE** |
| `inet_interfaces` | `all` | OK |
| `milter_protocol` | `6` | OK |
| `smtpd_milters` | `inet:localhost:8891` | OK (OpenDKIM) |
| `non_smtpd_milters` | `inet:localhost:8891` | OK (OpenDKIM pour outbound) |
| `message_size_limit` | `10485760` (10 MB) | OK |
| `relay_domains` | `inbound.keybuzz.io` | Correct pour le relais entrant |
| `transport_maps` | `hash:/etc/postfix/transport` | Route inbound.keybuzz.io vers webhook |
| `mynetworks` | `127.0.0.0/8 [::1]/128 10.0.0.0/16 188.245.0.0/16 91.99.0.0/16 37.27.0.0/16 116.203.0.0/16` | OK (reseau interne) |

**Submission (port 587)** : active avec SASL Dovecot, TLS may.

### 4.2 mail-mx-01 (MX entrant)

| Parametre | Valeur | Commentaire |
|---|---|---|
| `myhostname` | `mail-mx-01.keybuzz.io` | OK |
| `relay_domains` | **`inbound.keybuzz.io`** | **PROBLEME — keybuzz.io ABSENT** |
| `relayhost` | `[10.0.0.160]:25` | OK (relay vers mail-core-01) |
| `mydestination` | (vide) | OK |
| `smtpd_tls_cert_file` | `/etc/letsencrypt/live/mail-mx-01.keybuzz.io/fullchain.pem` | **OK — Let's Encrypt** |
| `mynetworks` | `127.0.0.0/8 [::1]/128 10.0.0.0/16` | OK |
| `smtpd_recipient_restrictions` | `permit_mynetworks, reject_unauth_destination, permit` | Cause du "Relay access denied" |

### 4.3 mail-mx-02 (MX entrant)

| Parametre | Valeur | Commentaire |
|---|---|---|
| `myhostname` | `mail-mx-02.keybuzz.io` | OK |
| `relay_domains` | **`inbound.keybuzz.io`** | **PROBLEME — keybuzz.io ABSENT** |
| `relayhost` | `[10.0.0.160]:25` | OK (relay vers mail-core-01) |
| `smtpd_tls_cert_file` | `/etc/letsencrypt/live/mail-mx-02.keybuzz.io/fullchain.pem` | **OK — Let's Encrypt** |

---

## 5. CERTIFICAT TLS — PROBLEME CRITIQUE #1

### Constat

```
Certificat SMTP mail-core-01 (ports 25 et 587) :
  Subject: CN = mail-core-01
  Issuer:  CN = mail-core-01  (SELF-SIGNED !)
  Dates:   15 dec 2025 → (pas d'expiration standard, c'est le snakeoil Debian)
  SAN:     DNS:mail-core-01

Certificat SMTP mail-mx-01 :
  Subject: CN = mail-mx-01.keybuzz.io
  Issuer:  Let's Encrypt E8  ✓
  Dates:   17 fev 2026 → 18 mai 2026

Certificat SMTP mail-mx-02 :
  Subject: CN = mail-mx-02.keybuzz.io
  Issuer:  Let's Encrypt E8  ✓
  Dates:   17 fev 2026 → 18 mai 2026
```

### Impact

Le serveur SMTP sortant (`mail-core-01`, IP `49.13.35.167`) presente un **certificat self-signed avec CN = mail-core-01** a TOUS les serveurs destinataires.

Quand Gmail / Outlook / Free recoivent une connexion TLS depuis `mail.keybuzz.io` :
1. Le certificat n'est pas signe par une CA reconnue → **erreur de verification**
2. Le CN est `mail-core-01` et non `mail.keybuzz.io` → **mismatch hostname**
3. Les providers appliquent une **penalite spam directe** (meme si TLS est opportuniste)

Les MX (mx-01, mx-02) ont des certs Let's Encrypt valides, mais ce n'est pas eux qui envoient les emails sortants.

### Fix requis

Obtenir un certificat Let's Encrypt pour `mail.keybuzz.io` sur mail-core-01 :
```
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.keybuzz.io/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.keybuzz.io/privkey.pem
```

---

## 6. RELAY ACCESS DENIED — PROBLEME CRITIQUE #2

### Constat

Les MX (mx-01, mx-02) ont `relay_domains = inbound.keybuzz.io` uniquement.

Quand un email arrive pour `alerts@keybuzz.io` ou `sre@keybuzz.io` :
1. Le MX verifie si le domaine destinataire est dans `relay_domains` ou `mydestination`
2. `keybuzz.io` n'est dans AUCUN des deux → **454 4.7.1 Relay access denied**
3. mail-core-01 reessaie en boucle → **9 183 emails deferred**
4. **70 emails bloques** dans la queue de mail-core-01

### Logs MX-01

```
NOQUEUE: reject: RCPT from mail.keybuzz.io[49.13.35.167]:
  454 4.7.1 <sre@keybuzz.io>: Relay access denied;
  from=<alerts@keybuzz.io> to=<sre@keybuzz.io>
```

### File d'attente mail-core-01

```
70 emails bloques, ~1097 KB
Tous destines a : alerts@keybuzz.io ou sre@keybuzz.io
Erreur : 454 4.7.1 Relay access denied
Les plus anciens datent du 30 mars 2026
```

### Impact

- Les emails internes (alertes SRE, monitoring) ne sont JAMAIS livres
- mail-core-01 reessaie toutes les ~5 minutes → charge inutile sur le serveur
- La queue grossit indefiniment

### Fix requis

Sur MX-01 et MX-02 : ajouter `keybuzz.io` a `relay_domains` :
```
relay_domains = inbound.keybuzz.io, keybuzz.io
```
Puis : `postmap` + `postfix reload`

---

## 7. REPUTATION IP — PROBLEME CRITIQUE #3

### Resultats DNSBL

| IP | Serveur | zen.spamhaus.org | bl.spamcop.net | b.barracudacentral.org |
|---|---|---|---|---|
| 49.13.35.167 | mail.keybuzz.io (float) | 127.255.255.254 (*) | CLEAN | CLEAN |
| 37.27.251.162 | mail-core-01 | 127.255.255.254 (*) | CLEAN | CLEAN |
| 91.99.66.6 | mail-mx-01 | CLEAN | CLEAN | **LISTE (127.0.0.2)** |
| 91.99.87.76 | mail-mx-02 | 127.255.255.254 (*) | CLEAN | **LISTE (127.0.0.2)** |

(*) Le code `127.255.255.254` de Spamhaus indique une requete depuis un resolveur DNS non enregistre chez Spamhaus (les resolvers cloud/hebergement doivent s'inscrire). Resultat **non concluant** — a verifier depuis un resolveur enregistre ou via https://check.spamhaus.org/

### Impact Barracuda

Les IP MX (`91.99.66.6` et `91.99.87.76`) sont listees sur **Barracuda Reputation Block List** :
- Les providers utilisant Barracuda pour le filtrage (nombreux domaines corporate) rejettent ou penalisent les emails
- Cela n'affecte pas directement les emails SORTANTS (envoyes depuis 49.13.35.167) mais la reputation globale du domaine

### Fix requis

1. Demander le delisting Barracuda : https://www.barracudacentral.org/lookups
2. Verifier le listing Spamhaus depuis https://check.spamhaus.org/ (IPs 49.13.35.167 et 37.27.251.162)
3. Si liste : soumettre une demande de delisting

---

## 8. SPF SOFTFAIL — PROBLEME GRAVE #4

### Constat

```
keybuzz.io TXT : "v=spf1 ip4:49.13.35.167 mx ~all"
                                               ^^^^
                                               SOFTFAIL
```

### Impact

- `~all` indique aux providers : "les emails de sources non listees sont suspects mais ne les rejetez pas"
- Gmail et Outlook traitent `~all` comme un **signal negatif** dans leur algorithme de scoring
- Avec `-all` (hardfail), le message est clair : "rejetez tout ce qui ne vient pas de mes IPs"
- La difference `~all` vs `-all` peut a elle seule faire basculer un email de inbox a spam

### Fix requis

```
v=spf1 ip4:49.13.35.167 mx -all
```

---

## 9. MISMATCH MYORIGIN — PROBLEME GRAVE #5

### Constat

```
mail-core-01 :
  myhostname = mail.keybuzz.io
  myorigin = inbound.keybuzz.io    ← PROBLEME
```

`myorigin` determine le domaine du `Return-Path` (envelope-from) pour les bounces et les emails systeme.

Quand l'application envoie un email avec `From: noreply@keybuzz.io` :
- Le header `From` est `@keybuzz.io`
- Le `Return-Path` (envelope) est `@inbound.keybuzz.io` (myorigin)
- L'evaluation SPF se fait sur le domaine du `Return-Path` → `inbound.keybuzz.io`
- L'evaluation DMARC compare `From` domain (`keybuzz.io`) avec SPF domain (`inbound.keybuzz.io`)

### Verification alignement DMARC

Le DMARC de `keybuzz.io` utilise l'alignement **relaxed** (defaut) :
- En relaxed, `inbound.keybuzz.io` est considere comme un sous-domaine de `keybuzz.io` → **aligne**
- En strict, ils ne matcheraient PAS

**Verdict** : Grace a l'alignement relaxed, le mismatch n'empeche pas DMARC de passer.
Mais c'est une mauvaise pratique : un changement de DMARC vers `aspf=s` casserait tout.

### Fix recommande

```
myorigin = keybuzz.io
```

---

## 10. AUDIT OPENDKIM

### Configuration

| Parametre | Valeur | Verdict |
|---|---|---|
| Mode | `sv` (sign + verify) | OK |
| Canonicalization | `relaxed/simple` | OK |
| Socket | `inet:8891@localhost` | OK |
| SubDomains | `no` | OK |
| AutoRestart | `yes` | OK |
| RequireSafeKeys | `false` | OK (necessaire pour les perms) |

### Cles

| Domaine | Selecteur | Fichier | Perms | Statut |
|---|---|---|---|---|
| keybuzz.io | default | `/etc/opendkim/keys/keybuzz.io/default.private` | 600 opendkim | OK |
| keybuzz.io | kbz1 | `/etc/opendkim/keys/keybuzz.io/kbz1.private` | 600 opendkim | Present (non utilise dans SigningTable) |
| inbound.keybuzz.io | kbz1 | `/etc/opendkim/keys/inbound.keybuzz.io/kbz1.private` | 600 opendkim | OK |

### TrustedHosts

```
127.0.0.1, ::1, localhost
mail.keybuzz.io, inbound.keybuzz.io
49.13.35.167, 10.0.0.0/16, 10.0.0.160
91.99.164.62 (k8s-worker-02)
188.245.45.242, 116.203.135.192, 46.62.171.61 (K8s NAT IPs)
```

**Verdict DKIM** : correctement configure. Les emails sortants `@keybuzz.io` sont signes avec le selector `default`, les emails `@inbound.keybuzz.io` avec `kbz1`.

---

## 11. ANALYSE TLS

### Certificats par port

| Serveur | Port | Cert | Issuer | CN | Verdict |
|---|---|---|---|---|---|
| mail-core-01 | 25 | snakeoil | Self-signed | mail-core-01 | **CRITIQUE** |
| mail-core-01 | 587 | snakeoil | Self-signed | mail-core-01 | **CRITIQUE** |
| mail-mx-01 | 25 | Let's Encrypt E8 | Let's Encrypt | mail-mx-01.keybuzz.io | OK |
| mail-mx-02 | 25 | Let's Encrypt E8 | Let's Encrypt | mail-mx-02.keybuzz.io | OK |

### TLS versions

- TLSv1.3 avec `TLS_AES_256_GCM_SHA384` partout — **protocole OK**
- Le probleme n'est pas le protocole TLS mais le **certificat** presente

---

## 12. STATISTIQUES D'ENVOI

### Derniers jours (mail.log)

| Metrique | Valeur | Commentaire |
|---|---|---|
| Emails envoyes (sent) | **199** | Incluant Gmail, OVH, Amazon SES |
| Emails differes (deferred) | **9 183** | Essentiellement Relay access denied vers @keybuzz.io |
| Emails rebondis (bounced) | **0** | — |
| Queue actuelle | **70 emails** / 1 097 KB | Tous bloques par Relay access denied |

### Destinations reussies (extraits logs)

| Destination | Relay | Statut | Commentaire |
|---|---|---|---|
| ludovic@keybuzz.pro | mx0.mail.ovh.net | sent | Multiples envois OK |
| ludo.gonthier@gmail.com | gmail-smtp-in.l.google.com | sent | OK (mais peut arriver en spam) |
| switaa26@gmail.com | gmail-smtp-in.l.google.com | sent | OK |
| keybuzz.pro@gmail.com | gmail-smtp-in.l.google.com | sent | OK |
| compta.ecomlg@gmail.com | gmail-smtp-in.l.google.com | sent | OK |
| contact@switaa.com | mx0.mail.ovh.net | sent | OK |
| Amazon marketplace | inbound-smtp.eu-west-1.amazonaws.com | sent | OK |
| alerts@keybuzz.io | mail-mx-01/02.keybuzz.io | **deferred** | Relay access denied |
| sre@keybuzz.io | mail-mx-01/02.keybuzz.io | **deferred** | Relay access denied |

### Observations

- Les emails vers Gmail sont **acceptes** (250 OK) mais arrivent probablement en **spam** a cause du cert self-signed + SPF softfail
- Les emails vers OVH sont acceptes normalement
- Les emails internes (@keybuzz.io) sont **tous bloques**
- Amazon SES accepte les emails correctement (reponses marketplace)

---

## 13. PROBLEMES SECONDAIRES

### 13.1 Dovecot — Permission denied

```
Error: passwd-file /etc/dovecot/users: open(/etc/dovecot/users) failed:
  Permission denied (euid=113(dovecot) egid=116(dovecot)
  missing +r perm: /etc/dovecot/users, dir owned by 0:0 mode=0755)
```

**Impact** : Dovecot ne peut pas lire la liste des utilisateurs → l'authentification IMAP peut echouer.
**Fix** : `chmod 644 /etc/dovecot/users`

### 13.2 Rspamd non integre

Rspamd est installe et actif mais n'apparait PAS dans la chaine milter de Postfix :
```
smtpd_milters = inet:localhost:8891   ← uniquement OpenDKIM
```

Rspamd n'est utilise ni pour le filtrage entrant ni pour le scoring sortant.
**Impact faible** pour la deliverabilite sortante mais empechera le filtrage spam entrant.

### 13.3 MTA-STS ID obsolete

```
_mta-sts.keybuzz.io : "v=STSv1; id=20250919"
```

L'ID date de septembre 2025. Il devrait etre mis a jour a chaque modification de la politique MTA-STS.

### 13.4 Tentatives d'authentification non autorisees

Les logs montrent des tentatives de connexion SMTP depuis des IPs externes (scanners) :
```
103.81.170.109 - auth fail
141.98.9.102  - auth fail
77.83.39.218  - auth fail
178.16.54.15  - auth fail
185.93.89.64  - auth fail
```
Postfix les rejette correctement (`smtpd_client_restrictions`). Pas d'impact mais a surveiller.

### 13.5 Spoofing attempt detecte

```
NOQUEUE: reject from unknown[91.92.240.214]:
  from=<admin@keybuzz.io> to=<wangyang9000001@hotmail.com>
```
Quelqu'un tente d'utiliser mail-core-01 pour envoyer des emails en se faisant passer pour `admin@keybuzz.io`. Rejete correctement par `smtpd_sender_restrictions`.

---

## 14. SYNTHESE ALIGNEMENT EMAIL

| Champ | Valeur actuelle | Valeur attendue | Statut |
|---|---|---|---|
| HELO/EHLO | `mail.keybuzz.io` | `mail.keybuzz.io` | **OK** |
| From (application) | `@keybuzz.io` | `@keybuzz.io` | OK |
| Return-Path (myorigin) | `@inbound.keybuzz.io` | `@keybuzz.io` | **MISMATCH** |
| DKIM domain | `keybuzz.io` (selector default) | `keybuzz.io` | **OK** |
| SPF domain evalue | `inbound.keybuzz.io` (Return-Path) | `keybuzz.io` | **MISMATCH** |
| PTR (49.13.35.167) | `mail.keybuzz.io` | `mail.keybuzz.io` | **OK** |
| Cert TLS CN | `mail-core-01` | `mail.keybuzz.io` | **MISMATCH CRITIQUE** |

### Evaluation DMARC theorique

```
From domain:     keybuzz.io
SPF domain:      inbound.keybuzz.io (via Return-Path/myorigin)
DKIM domain:     keybuzz.io (via SigningTable)
DMARC alignment: relaxed (defaut)

SPF alignment:  inbound.keybuzz.io vs keybuzz.io → PASS (relaxed, sous-domaine)
DKIM alignment: keybuzz.io vs keybuzz.io → PASS (exact match)

DMARC result:   PASS (au moins un alignement OK)
```

**Malgre le mismatch myorigin, DMARC devrait PASSER en mode relaxed.**
Le probleme principal reste le certificat TLS et le SPF softfail.

---

## 15. LISTE PRIORISEE DES FIXES

### PRIORITE 1 — CRITIQUE (resoudra la majorite du probleme spam)

| # | Fix | Serveur | Effort | Impact |
|---|---|---|---|---|
| F1 | **Installer un cert Let's Encrypt** pour `mail.keybuzz.io` sur mail-core-01 | mail-core-01 | 15 min | **ENORME** — elimine la penalite TLS |
| F2 | **Ajouter `keybuzz.io` a `relay_domains`** sur mx-01 et mx-02 | mx-01, mx-02 | 5 min | Debloque 70 emails + emails internes |
| F3 | **Passer SPF de `~all` a `-all`** pour keybuzz.io | DNS | 2 min | Elimine la penalite SPF softfail |

### PRIORITE 2 — GRAVE (amelioration notable)

| # | Fix | Serveur | Effort | Impact |
|---|---|---|---|---|
| F4 | **Changer `myorigin` de `inbound.keybuzz.io` a `keybuzz.io`** | mail-core-01 | 2 min | Alignement propre Return-Path |
| F5 | **Demander delisting Barracuda** pour mx-01 et mx-02 | Barracuda | 10 min | Debloque les providers utilisant BRBL |
| F6 | **Verifier listing Spamhaus** via https://check.spamhaus.org/ | Spamhaus | 5 min | Confirmer ou exclure le risque |

### PRIORITE 3 — MOYEN (hardening)

| # | Fix | Serveur | Effort | Impact |
|---|---|---|---|---|
| F7 | **Corriger permissions Dovecot** : `chmod 644 /etc/dovecot/users` | mail-core-01 | 1 min | IMAP fonctionnel |
| F8 | **Integrer Rspamd** dans le pipeline milter Postfix | mail-core-01 | 30 min | Filtrage anti-spam entrant |
| F9 | **Mettre a jour MTA-STS ID** | DNS | 2 min | Conformite MTA-STS |
| F10 | **Flusher la queue mail** apres fix F2 | mail-core-01 | 1 min | Livrer les 70 emails bloques |
| F11 | **Passer DMARC a `p=reject`** (apres validation que tout passe) | DNS | 2 min | Protection anti-spoofing maximale |

---

## 16. ORDRE D'EXECUTION RECOMMANDE

```
1. F1 — Let's Encrypt sur mail-core-01 (IMPACT MAXIMAL)
2. F3 — SPF ~all → -all (DNS, instantane)
3. F4 — myorigin → keybuzz.io (Postfix reload)
4. F2 — relay_domains += keybuzz.io sur MX (Postfix reload)
5. F10 — postqueue -f (flush la queue)
6. F5 — Delisting Barracuda (formulaire web)
7. F6 — Verifier Spamhaus
8. F7 — chmod Dovecot
9. Tester envoi Gmail/Outlook et verifier headers
10. Si DMARC passe → F11 (p=reject)
```

**Estimation temps total : ~1h (hors propagation DNS et attente delisting)**

---

## 17. PREUVES ET DONNEES BRUTES

### Config Postfix mail-core-01 (postconf -n)

```
myhostname = mail.keybuzz.io
myorigin = inbound.keybuzz.io
mydestination = localhost
smtp_bind_address = 49.13.35.167
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
relay_domains = inbound.keybuzz.io
transport_maps = hash:/etc/postfix/transport
```

### Config MX-01 et MX-02

```
MX-01: myhostname = mail-mx-01.keybuzz.io
       relay_domains = inbound.keybuzz.io  (keybuzz.io ABSENT)
       smtpd_tls_cert_file = /etc/letsencrypt/live/mail-mx-01.keybuzz.io/fullchain.pem

MX-02: myhostname = mail-mx-02.keybuzz.io
       relay_domains = inbound.keybuzz.io  (keybuzz.io ABSENT)
       smtpd_tls_cert_file = /etc/letsencrypt/live/mail-mx-02.keybuzz.io/fullchain.pem
```

### Queue mail-core-01

```
70 Requests / 1097 KB
Tous en status=deferred
Erreur: 454 4.7.1 Relay access denied
Destinations: alerts@keybuzz.io, sre@keybuzz.io
```

### OpenDKIM config

```
KeyTable:
  kbz1._domainkey.inbound.keybuzz.io → inbound.keybuzz.io:kbz1
  default._domainkey.keybuzz.io → keybuzz.io:default

SigningTable:
  *@inbound.keybuzz.io → kbz1._domainkey.inbound.keybuzz.io
  *@keybuzz.io → default._domainkey.keybuzz.io
```
