# PH-MAIL-PRE-FIX-VALIDATION-02A — Validation pre-fix

> Date : 4 avril 2026
> Type : Simulation et validation (lecture seule)
> Prerequis : PH-MAIL-AUDIT-DELIVERABILITY-01

---

## RESUME

| Fix | Verdict | Risque | Commentaire |
|---|---|---|---|
| **F1 — TLS Let's Encrypt** | **SAFE** | ZERO | Certbot installe, nginx disponible, aucun impact inbound |
| **F3 — SPF ~all → -all** | **SAFE** | ZERO | DNS uniquement, pas de regression possible |
| **F4 — myorigin → keybuzz.io** | **SAFE** | NEGLIGEABLE | N'affecte que bounces/cron, pas l'application |
| **F2 — relay_domains** | **RISQUE** | **MOYEN** | Necessite config SUPPLEMENTAIRE sur mail-core-01 |

### PROBLEME CRITIQUE DECOUVERT

**Le webhook inbound est en echec permanent** — TOUS les emails Amazon marketplace sont bloques dans la queue de mail-core-01 avec `dsn=4.3.0 status=deferred (temporary failure)`. Ce probleme est **independant des fixes** mais bloque le pipeline inbound.

---

## ETAPE 1 — AUDIT TRANSPORT_MAPS

### Configuration

```
transport_maps = hash:/etc/postfix/transport
```

Contenu `/etc/postfix/transport` :
```
inbound.keybuzz.io    webhook:
```

Le fichier `transport.db` existe (compile le 17 dec 2025).

### master.cf — webhook pipe

```
webhook   unix  -       n       n       -       -       pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh
```

### Webhook script (`/usr/local/bin/postfix_webhook.sh`)

Le script est le pipeline PH32.3/PH32.4B d'ingestion inbound. Il gere :
1. **Emails SAV** (`sav.*@inbound.keybuzz.io`) → route vers `/supplier-inbound` API (PROD + DEV)
2. **Emails marketplace** → route vers `/api/v1/webhooks/inbound-email` (PROD + DEV)
3. Separation DEV/PROD via messageId `-dev`/`-prod` suffix (fix PH32.4B anti-dedup)
4. Body limit 10 MB (fix PH99)

**Verdict transport_maps** : la configuration est correcte. `inbound.keybuzz.io` est route vers le webhook. Le transport est fonctionnel en tant que config.

### ALERTE : webhook en echec

```
postfix/pipe: to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io>
  relay=webhook, delay=421057, dsn=4.3.0, status=deferred (temporary failure)
```

Le delay de `421 057s ≈ 4.9 jours` montre que les emails Amazon inbound sont bloques depuis le ~30 mars.
Le webhook script (`postfix_webhook.sh`) retourne `exit 75` (temporary failure) pour TOUS les emails.

**Causes possibles** : API backend DEV/PROD down, webhook key invalide, ou erreur dans le script.
**Impact** : les messages Amazon marketplace ne sont PAS livres au backend.
**Ce probleme est independant des fixes deliverabilite** mais doit etre investigue separement.

---

## ETAPE 2 — AUDIT INBOUND FLOW

### Flux normal

```
Amazon SES → MX-01/02 (port 25)
  MX accepte si destinataire @inbound.keybuzz.io (relay_domains)
  MX relaie vers mail-core-01 ([10.0.0.160]:25)
    mail-core-01 accepte (inbound.keybuzz.io dans relay_domains)
    transport_maps route vers webhook pipe
      webhook appelle API backend
```

### Preuves flux MX-01

```
490713EB8A: to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io>
  relay=10.0.0.160[10.0.0.160]:25, status=sent (250 2.0.0 Ok)
```

Le flux MX → mail-core-01 fonctionne pour `@inbound.keybuzz.io`.

### Emails @keybuzz.io rejetes par MX

```
NOQUEUE: reject: RCPT from a3-77.smtp-out.eu-west-1.amazonses.com:
  454 4.7.1 <dmarc@keybuzz.io>: Relay access denied
```

Les rapports DMARC d'Amazon SES vers `dmarc@keybuzz.io` sont rejetes — ce qui explique pourquoi les rapports DMARC ne sont jamais recus.

### Dependance myorigin sur inbound

**myorigin n'affecte PAS le flux inbound**. Le routing inbound depend de :
- `relay_domains` (quels domaines sont acceptes en relay)
- `transport_maps` (comment router les emails acceptes)
- `mydestination` (livraison locale)

myorigin n'intervient que pour les bounces et les emails generes localement.

**Verdict** : changer myorigin est SAFE pour le flux inbound.

---

## ETAPE 3 — AUDIT RETURN-PATH

### Enveloppes sortantes actuelles

| Envelope-from | Count | Source |
|---|---|---|
| `alerts@keybuzz.io` | 16+ | Application (monitoring SRE) |
| `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` | 10 | Reponses marketplace FR |
| `amazon.ecomlg-001.es.8d80b1@inbound.keybuzz.io` | 7 | Reponses marketplace ES |
| `amazon.ecomlg-001.be.1aa8a8@inbound.keybuzz.io` | 2 | Reponses marketplace BE |
| `amazon.switaa-sasu-mnc1x4eq.fr.3c29f6@inbound.keybuzz.io` | 1 | Reponses marketplace Switaa |

### Analyse impact myorigin

L'application **definit explicitement** son envelope-from :
- Emails applicatifs : `from=<alerts@keybuzz.io>` → deja en `@keybuzz.io`
- Reponses marketplace : `from=<amazon.*@inbound.keybuzz.io>` → correct

`myorigin` n'affecte que :
1. **Bounces/DSN** : `MAILER-DAEMON@inbound.keybuzz.io` → deviendra `MAILER-DAEMON@keybuzz.io`
2. **Emails systeme** (cron) : `root@inbound.keybuzz.io` → deviendra `root@keybuzz.io`

**Impact** : POSITIF. Les bounces seront alignes avec le domaine principal.

### Signature DKIM

Les logs OpenDKIM confirment la signature :
```
DKIM-Signature field added (s=default, d=keybuzz.io)
```

Les emails sortants @keybuzz.io sont signes avec le selector `default`. Le changement de myorigin ne modifie PAS le comportement DKIM (le domaine de signature est base sur SigningTable, pas myorigin).

**Verdict myorigin** : **SAFE** — changement sans impact sur l'application ni sur DKIM.

---

## ETAPE 4 — AUDIT RELAY_DOMAINS

### Restrictions actuelles MX-01 et MX-02

```
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination, permit
mynetworks = 127.0.0.0/8 [::1]/128 10.0.0.0/16
relay_domains = inbound.keybuzz.io
relayhost = [10.0.0.160]:25
```

`reject_unauth_destination` bloque tout email dont le destinataire n'est PAS dans :
- `mydestination` (vide sur MX)
- `relay_domains` (actuellement inbound.keybuzz.io)
- `mynetworks` (reseaux internes)

### Simulation : ajout keybuzz.io

Si `relay_domains = inbound.keybuzz.io, keybuzz.io` :
- Les emails TO `@keybuzz.io` seront acceptes par les MX
- Les MX les relayeront vers `[10.0.0.160]:25` (mail-core-01)
- **Pas d'open relay** : `reject_unauth_destination` bloque tout autre domaine
- Seuls `@inbound.keybuzz.io` et `@keybuzz.io` sont relayables

### RISQUE IDENTIFIE : mail-core-01 ne sait pas gerer @keybuzz.io

Sur mail-core-01 :
```
mydestination = localhost
relay_domains = inbound.keybuzz.io
transport_maps → inbound.keybuzz.io → webhook
```

**keybuzz.io n'est PAS dans `mydestination`** ni dans `relay_domains` ni dans `transport_maps`.

Si les MX relayent un email `to=<dmarc@keybuzz.io>` vers mail-core-01 :
1. mail-core-01 recoit l'email
2. Cherche keybuzz.io dans mydestination → NON
3. Cherche keybuzz.io dans relay_domains → NON
4. Cherche keybuzz.io dans transport_maps → NON
5. **Resultat : BOUNCE** (550 User unknown ou relay denied)
6. Le bounce part vers l'expediteur original → MX le recoit → relaie vers mail-core-01 → BOUCLE

### Ce qu'il faut faire en PLUS du fix MX

Sur **mail-core-01**, il faut ajouter `keybuzz.io` pour que le serveur sache quoi en faire :

**Option A (recommandee)** : ajouter `keybuzz.io` a `mydestination` + configurer des aliases
```
mydestination = localhost, keybuzz.io
```
Puis dans `/etc/aliases` :
```
alerts:     /dev/null   (ou une adresse externe)
sre:        /dev/null   (ou une adresse externe)
dmarc-reports: /dev/null
dmarc-fail: /dev/null
dmarc:      /dev/null
tlsrpt:     /dev/null
security:   /dev/null
postmaster: root
```

**Option B** : ajouter une route transport_maps
```
keybuzz.io    discard:    (rejeter silencieusement)
```
Ou router vers un handler specifique.

**Option C** : utiliser `virtual_alias_maps` pour rediriger
```
@keybuzz.io    ludovic@keybuzz.pro
```

### Flux actuel du probleme (emails internes)

```
mail-core-01 genere: from=<alerts@keybuzz.io> to=<sre@keybuzz.io>
  → lookup MX keybuzz.io → mail-mx-01/02.keybuzz.io
  → MX rejette: "Relay access denied" (keybuzz.io pas dans relay_domains)
  → mail-core-01 reessaie en boucle (9183 deferred)
```

Avec le fix MX SEUL (sans fix mail-core-01) :
```
mail-core-01 genere: from=<alerts@keybuzz.io> to=<sre@keybuzz.io>
  → lookup MX keybuzz.io → mail-mx-01/02.keybuzz.io
  → MX accepte et relaie vers [10.0.0.160]:25
  → mail-core-01 recoit: to=<sre@keybuzz.io>
  → pas dans mydestination, relay_domains, transport_maps
  → BOUNCE → boucle de mail
```

**Verdict relay_domains** : **RISQUE MOYEN** — le fix MX seul cree une boucle de mail. Il faut imperativement configurer mail-core-01 pour gerer `@keybuzz.io` AVANT d'ajouter le domaine aux MX.

---

## ETAPE 5 — AUDIT SUBMISSION 587

### Configuration submission

```
submission inet n  -  y  -  -  smtpd
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_sasl_security_options=noanonymous
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
```

### SASL / Dovecot

| Element | Valeur | Statut |
|---|---|---|
| Socket auth | `/var/spool/postfix/private/auth` (srw-rw-rw-) | **OK** |
| Dovecot | v2.3.21, active since 2 avril | **OK** |
| Dovecot users | 1 user (`keybuzz-smtp`, CRAM-MD5) | **OK** |
| Dovecot users perms | `-rw------- root:root` | **PROBLEME (dovecot ne peut pas lire)** |

Le backend applicatif se connecte via le port 587 avec l'identifiant `keybuzz-smtp` et CRAM-MD5.
La restriction `permit_sasl_authenticated,reject` garantit que seuls les utilisateurs authentifies peuvent envoyer.

### Impact du changement TLS

Le submission (587) herite du certificat de la config principale :
```
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem  (actuellement)
```

Apres installation du cert LE :
```
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.keybuzz.io/fullchain.pem
```

Les deux ports (25 et 587) utiliseront le nouveau certificat apres `postfix reload`.

### Certbot disponible

```
Certbot 2.9.0 installe
Nginx actif sur port 80 (challenge HTTP possible)
Cert existant : mta-sts.inbound.keybuzz.io (Let's Encrypt)
```

Le challenge HTTP via nginx est la methode recommandee.

**Verdict submission** : **SAFE** — le changement de cert est transparent, SASL/Dovecot non affecte.

---

## DECOUVERTE CRITIQUE : WEBHOOK INBOUND EN PANNE

### Symptome

TOUS les emails inbound Amazon (`relay=webhook`) echouent avec `temporary failure` :

```
postfix/pipe: to=<amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io>
  relay=webhook, delay=421213s (~4.9 jours)
  dsn=4.3.0, status=deferred (temporary failure)
```

### Impact

- Les messages Amazon marketplace pour eComLG et Switaa ne sont PAS livres
- Ils s'accumulent dans la queue de mail-core-01
- Les clients KeyBuzz ne recoivent PAS les messages marketplace
- **Ce probleme existe depuis ~30 mars 2026**

### Cause probable

Le script `postfix_webhook.sh` appelle :
- `https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email`
- `https://backend.keybuzz.io/api/v1/webhooks/inbound-email`

Si les deux echouent (timeout, 5xx, webhook key invalide), le script retourne `exit 75` (temporary failure).

### Ce probleme est INDEPENDANT des fixes deliverabilite

Il ne sera pas resolu par les fixes TLS/SPF/myorigin/relay_domains. Il necessite une investigation separee.

---

## SYNTHESE DES VERDICTS

### F1 — TLS Let's Encrypt → **SAFE**

| Critere | Verdict |
|---|---|
| Certbot installe | Oui (v2.9.0) |
| Nginx disponible pour challenge HTTP | Oui (port 80 actif) |
| Impact inbound | AUCUN (n'affecte pas le routage) |
| Impact submission 587 | POSITIF (meilleur cert) |
| Impact outbound | POSITIF (providers font confiance) |
| Rollback possible | Oui (remettre snakeoil dans postconf) |
| Interruption service | NON (`postfix reload` = 0 downtime) |

**Procedure** :
```
certbot certonly --nginx -d mail.keybuzz.io
→ modifier main.cf : smtpd_tls_cert_file / smtpd_tls_key_file
→ postfix reload
```

### F3 — SPF ~all → -all → **SAFE**

| Critere | Verdict |
|---|---|
| Type de changement | DNS TXT uniquement |
| Impact serveurs | AUCUN |
| Impact deliverabilite | POSITIF |
| Rollback possible | Oui (remettre ~all) |
| Propagation | ~TTL (3600s = 1h) |

### F4 — myorigin → keybuzz.io → **SAFE**

| Critere | Verdict |
|---|---|
| Impact application | AUCUN (l'app definit son envelope-from explicitement) |
| Impact inbound | AUCUN (myorigin n'affecte pas le routing) |
| Impact DKIM | AUCUN (signing base sur SigningTable) |
| Impact bounces | POSITIF (alignement domaine) |
| Rollback possible | Oui (remettre inbound.keybuzz.io) |

### F2 — relay_domains → **RISQUE MOYEN**

| Critere | Verdict |
|---|---|
| Open relay ? | NON (`reject_unauth_destination` protege) |
| Boucle de mail ? | **OUI** si mail-core-01 pas configure |
| Config supplementaire requise | **OUI** — mail-core-01 doit gerer @keybuzz.io |

**Plan relay_domains CORRIGE (3 etapes sequentielles)** :

1. **mail-core-01** : ajouter `keybuzz.io` a `mydestination`
2. **mail-core-01** : configurer aliases (`alerts`, `sre`, `dmarc-reports`, `dmarc-fail`, `dmarc`, `tlsrpt`, `security`, `postmaster`)
3. **MX-01 + MX-02** : ajouter `keybuzz.io` a `relay_domains`
4. **mail-core-01** : `postqueue -f` pour flusher la queue

---

## RECOMMANDATION ORDRE D'EXECUTION

```
Phase 1 — SAFE (peut etre fait immediatement)
  1. F1 : certbot + postfix reload (TLS)
  2. F3 : DNS SPF ~all → -all
  3. F4 : myorigin → keybuzz.io + postfix reload

Phase 2 — RISQUE (necessite preparation)
  4a. mail-core-01 : mydestination += keybuzz.io
  4b. mail-core-01 : /etc/aliases (alerts, sre, dmarc*, ...)
  4c. MX-01/02 : relay_domains += keybuzz.io
  4d. mail-core-01 : postqueue -f

Phase 3 — INVESTIGATION SEPAREE
  5. Diagnostiquer webhook inbound en panne (pipeline Amazon)
  6. Flusher la queue inbound apres fix webhook
```
