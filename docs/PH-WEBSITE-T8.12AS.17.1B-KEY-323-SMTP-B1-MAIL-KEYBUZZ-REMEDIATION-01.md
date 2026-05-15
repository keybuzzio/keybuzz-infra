# PH-WEBSITE-T8.12AS.17.1B-KEY-323-SMTP-B1-MAIL-KEYBUZZ-REMEDIATION-01

> Date : 2026-05-15
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1B SMTP B1 mail.keybuzz.io remediation
> Environnement : INFRA mail diagnostic read-only, blocage acces serveur

---

## VERDICT

NO GO KEY-323 SMTP FIX BLOCKED BY MAIL SERVER ACCESS

Diagnostic infra read-only confirme une cause racine plus profonde que
le simple service down : la cle SSH du serveur mail-core-01 (10.0.0.160)
a change depuis la derniere session enregistree dans known_hosts. Cela
indique tres probablement une reinstallation ou un remplacement du
serveur mail principal. Coherent avec les symptomes :

- ICMP OK sur 37.27.251.162 et 10.0.0.160 -> serveur up
- TCP REFUSED sur 37.27.251.162:25 / 465 / 587 / 2525 -> postfix non
  ecoutant sur l'IP publique
- TCP TIMEOUT sur floating IP 49.13.35.167:25 / 465 / 587 / 2525 ->
  floating IP probablement detachee
- SSH 10.0.0.160 refuse car cle hote ED25519 differente de l'historique

Aucun acces SSH possible sans GO Ludovic pour traiter le mismatch
known_hosts. Aucun fix tente. Aucune mutation. Aucun secret lu.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu.

---

## Preflight (E0)

| Surface | Valeur | Statut |
|---|---|---|
| Bastion identite | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche/HEAD | main / aef393a4 | clean (post AS.17.1 push) |
| API DEV runtime | v3.5.190-channels-tenantguard-dev | UP |
| API PROD runtime | v3.5.190-channels-tenantguard-prod | UP |
| website DEV runtime | v0.6.14-cta-tracking-pass-dev | UP |
| website PROD runtime | v0.6.13-clarity-website-prod | UP (pre AS.17.0) |
| KEY-322 | Open | inchange |
| KEY-323 | Backlog High | inchange |

---

## Revalidation SMTP multi-source (E1)

### DNS

| Lookup | Result |
|---|---|
| A mail.keybuzz.io | 49.13.35.167 (floating IP - voir audit deliverabilite 2026-04-04) |
| Reverse 49.13.35.167 | mail.keybuzz.io |
| MX keybuzz.io | 10 mail-mx-01.keybuzz.io / 20 mail-mx-02.keybuzz.io (entrant) |
| MX keybuzz.pro | mx0/mx2/mx3/mx4.mail.ovh.net (OVH, separe) |

### TCP probes vers 49.13.35.167 (floating IP)

| Source | Port | Resultat | Interpretation |
|---|---|---|---|
| Bastion install-v3 | 25 | TIMEOUT | floating IP non routee / detachee |
| Bastion install-v3 | 465 | TIMEOUT | idem |
| Bastion install-v3 | 587 | TIMEOUT | idem |
| Bastion install-v3 | 2525 | TIMEOUT | idem |

### TCP probes vers 37.27.251.162 (IP publique mail-core-01 reel)

| Port | Resultat | Interpretation |
|---|---|---|
| 25 | Connection refused | TCP RST -> port ferme cote serveur (postfix non listening) |
| 465 | Connection refused | idem |
| 587 | Connection refused | idem |
| 2525 | Connection refused | idem |

### TCP probes vers 10.0.0.160 (IP privee mail-core-01 reseau interne Hetzner)

| Port | Resultat | Interpretation |
|---|---|---|
| 25 / 465 / 587 / 2525 | Connection refused depuis bastion (qui a route interne 10.0.0.0/8) | idem postfix non listening |

### ICMP

| Cible | Resultat |
|---|---|
| 49.13.35.167 (floating) | pas de reponse (3 paquets perdus) |
| 37.27.251.162 (public) | OK (1-2 ms, ttl=56) -> serveur up |
| 10.0.0.160 (privee) | OK (0.5-3 ms, ttl=63) -> reseau interne OK |

### Egress Hetzner control (preuve sortie OK)

| Cible | Port | Resultat |
|---|---|---|
| 8.8.8.8 | 53 (DNS) | OK |
| smtp.gmail.com | 25 | OK |
| smtp.gmail.com | 465 | OK |
| smtp.gmail.com | 587 | OK |

**E1 verdict : egress Hetzner sain. Cause racine = cote SERVEUR
mail-core-01 (postfix arrete + floating IP detachee).**

---

## Identification infra mail (E2)

### Source canonique : INFRA_SERVERS_INSTALL_CONTEXT.md

Tableau inventaire (lignes 76-78) :

| Serveur | IP publique | IP privee | IP flottante | Role |
|---|---|---|---|---|
| mail-core-01 | 37.27.251.162 | 10.0.0.160 | 49.13.35.167 | SMTP sortant Postfix DKIM Dovecot |
| mail-mx-01 | 91.99.66.6 | 10.0.0.161 | n/a | MX entrant priorite 10 |
| mail-mx-02 | 91.99.87.76 | 10.0.0.162 | n/a | MX entrant priorite 20 |

Confirme : 49.13.35.167 est la floating IP officielle de mail-core-01,
pas une IP morte ou obsolete. Le DNS et le manifest API sont coherents
avec l'architecture historique.

### SSH config bastion install-v3

Aliases identifies :
- backend-01 -> 10.0.0.250
- mail-core-01 -> 10.0.0.160
- 10.0.0.160 (alias direct)

Aucun alias mail-mx-01 / mail-mx-02 dans la config consultee.

### Manifest API SMTP_HOST

| Env | Fichier | Valeur literale |
|---|---|---|
| DEV | k8s/keybuzz-api-dev/deployment.yaml | SMTP_HOST = '49.13.35.167' |
| PROD | k8s/keybuzz-api-prod/deployment.yaml | SMTP_HOST = "49.13.35.167" |

API tape directement la floating IP litterale (pas le hostname). Coherent
avec l'audit deliverabilite : Postfix configure pour bind sur cette IP
flottante (smtp_bind_address).

### Audit deliverabilite anterieur

Rapport PH-MAIL-AUDIT-DELIVERABILITY-01 du 2026-04-04 documentait DEJA
7 problemes critiques (sans rapport direct avec la panne actuelle mais
informatif) :

1. Certificat TLS self-signed (snakeoil)
2. MX rejettent @keybuzz.io (Relay access denied)
3. IP sur Barracuda BRBL (mx-01, mx-02)
4. SPF softfail (~all)
5. Mismatch myorigin
6. Dovecot permission denied
7. Rspamd non integre milter

A l'epoque : 199 envoyes succes vs 9183 differes (97.9% echec). Donc
le mail-core fonctionnait partiellement en avril. La panne complete
actuelle (mai 2026) est plus recente et plus grave.

---

## SSH mail server (E3) - BLOCAGE

### Tentative

```
ssh install-v3 -t "ssh -o ConnectTimeout=10 mail-core-01 \"<read-only checks>\""
```

### Resultat

```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
The fingerprint for the ED25519 key sent by the remote host is
SHA256:3sRIpo1csjE/TUEN2eo8924zVpzO6eWTh2IYUr/Ptl0.
Offending ED25519 key in /root/.ssh/known_hosts:2202
Password authentication is disabled to avoid man-in-the-middle attacks.
root@10.0.0.160: Permission denied (publickey,password).
```

### Interpretation

- Le serveur 10.0.0.160 a une **nouvelle cle hote SSH ED25519** differente
  de celle enregistree precedemment dans known_hosts ligne 2202.
- Cela signifie : reinstallation, redeploiement, ou remplacement physique
  du serveur mail-core-01.
- `StrictHostKeyChecking no` dans le SSH config ne leve pas le blocage car
  il existe deja une entree connue qui ne matche pas. Comportement de
  securite normal (anti-MITM).
- ssh-keygen -R 10.0.0.160 supprimerait l'entree, ce qui resoudrait le
  blocage SSH mais masquerait un eventuel scenario man-in-the-middle.
  NE PAS effectuer sans GO Ludovic explicite + confirmation que la
  reinstallation est legitime (verification fingerprint via panneau
  Hetzner ou autre source de verite externe).

### Cause racine confirmee

Combinaison parfaitement coherente :

1. mail-core-01 reinstalle ou remplace recemment
2. Nouveau host key SSH genere (different de l'historique)
3. Postfix non remis en service au boot (ports SMTP fermes sur IP publique
   et privee)
4. Floating IP Hetzner 49.13.35.167 detachee du nouveau serveur (timeout
   au lieu de refused -> IP non routee)
5. ICMP OK car la machine elle-meme est UP (kernel + reseau de base
   fonctionnent)
6. Tous les flux email applicatifs cassent depuis cet instant : contact
   form, billing, lifecycle, outbound worker, invitations

---

## Actions Ludovic / admin infra requises (E4)

Comme l'acces SSH au mail-core n'est pas possible sans GO, voici la
liste d'actions a effectuer par Ludovic OU l'admin infra responsable du
mail-core-01 :

| # | Action | Detail |
|---|---|---|
| 1 | Confirmer reinstallation legitime mail-core-01 | Via panneau Hetzner ou historique provisioning |
| 2 | Verifier fingerprint nouveau host SSH | Comparer SHA256:3sRIpo1csjE/TUEN2eo8924zVpzO6eWTh2IYUr/Ptl0 avec console Hetzner / cloud-init logs |
| 3 | GO `ssh-keygen -R 10.0.0.160` sur bastion install-v3 si fingerprint legitime | Permet la reprise des connexions SSH |
| 4 | Verifier postfix status sur mail-core-01 | systemctl status postfix |
| 5 | Si postfix down : restart + enable | systemctl restart postfix && systemctl enable postfix |
| 6 | Verifier opendkim, dovecot, rspamd | meme commandes |
| 7 | Verifier floating IP 49.13.35.167 attachee | Via panneau Hetzner ou ip addr show |
| 8 | Si floating IP detachee : reattacher au mail-core-01 | Via panneau Hetzner |
| 9 | Verifier ss -ltnp ports 25 / 465 / 587 ouverts | sur mail-core-01 |
| 10 | Verifier firewall hote (ufw / iptables) ne bloque pas | sur mail-core-01 |
| 11 | Verifier postqueue -p (queue mail) | bouclage retry en attente |
| 12 | Verifier disque + memoire | df -h + free -h |
| 13 | Si tout OK : retest TCP depuis bastion install-v3 vers 49.13.35.167:25 | Doit donner CONNECT_OK |
| 14 | Verifier logs postfix dernieres heures | journalctl -u postfix -n 200 |
| 15 | NE PAS toucher SPF / DKIM / DMARC sans audit complet (cf audit deliverabilite 2026-04-04 documente 7 problemes anterieurs) |

Apres ces actions :
- Test SMTP TCP depuis bastion install-v3 vers floating IP 49.13.35.167
- Test SMTP TCP depuis pod API DEV vers meme IP
- Test envoi email DEV controle (GO Ludovic separe requis) :
  destinataire `info@keybuzz.pro`, contenu litteral `TEST DEV KEY-323 - ignorer`
- Verifier logs sendEmail succes [EmailService] cote API DEV
- Verifier reception cote info@keybuzz.pro (boite OVH)

---

## Fix conditionnel (E5) - NON EFFECTUE

Aucune action effectuee. Conditions de fix non remplies :
- acces SSH mail-core bloque par host key mismatch
- cause precise (re-installation) non confirmee par Ludovic
- GO Ludovic non donne pour ssh-keygen -R 10.0.0.160 ni pour
  intervention sur le serveur

---

## Test email controle DEV (E6) - NON EFFECTUE

Bloque par le fait que SMTP TCP n'est pas restaure. Aucun email envoye.
Plan documente pour la suite, dependant de la restauration mail-core.

---

## Tests effectues (read-only synthese)

| Test | Cible | Resultat |
|---|---|---|
| DNS A mail.keybuzz.io | 49.13.35.167 | OK |
| DNS reverse 49.13.35.167 | mail.keybuzz.io | OK |
| DNS MX keybuzz.io | mail-mx-01/02.keybuzz.io | OK |
| DNS MX keybuzz.pro | mx0-4.mail.ovh.net | OK (separe) |
| TCP 49.13.35.167:25 bastion | TIMEOUT | floating IP detachee |
| TCP 49.13.35.167:465/587/2525 bastion | TIMEOUT | idem |
| TCP 37.27.251.162:25/465/587 bastion | REFUSED | postfix not listening |
| TCP 37.27.251.162:2525 bastion | TIMEOUT | idem (port 2525 sans listener) |
| TCP 10.0.0.160:25/465/587/2525 bastion | REFUSED | idem |
| ICMP 37.27.251.162 | OK 1-2ms | serveur UP |
| ICMP 10.0.0.160 | OK 0.5-3ms | reseau interne UP |
| ICMP 49.13.35.167 | NO ANSWER | floating IP non routee |
| Egress smtp.gmail.com:25/465/587 bastion | OK | egress Hetzner sain |
| Egress 8.8.8.8:53 bastion | OK | egress sain |
| SSH mail-core-01 (10.0.0.160) | REFUSED (host key changed) | reinstallation suspectee |

---

## Non-regression PROD

| Surface | Etat avant audit AS.17.1B | Etat apres audit |
|---|---|---|
| API DEV+PROD pods | UP 1/1 | UP 1/1 (inchange) |
| Website DEV+PROD pods | UP | UP (inchange) |
| Linear KEY-322 | Open | Open (non touche) |
| Linear KEY-323 | Backlog High | Backlog High (non touche) |
| Branches Git | clean | inchange |
| Manifests k8s | inchange | inchange |
| Secrets k8s | non lus | non lus |
| Serveur mail-core-01 | UP (postfix down) | UP (postfix down, non touche) |
| Floating IP 49.13.35.167 | detachee | detachee (non touche) |

Aucune mutation effectuee pendant l'audit.

---

## Brouillon commentaire Linear KEY-323 (en attente GO, NON poste)

```
Audit AS.17.1B SMTP B1 read-only termine. Rapport docs-only :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1B-KEY-323-SMTP-B1-MAIL-KEYBUZZ-REMEDIATION-01.md

Cause racine confirmee plus profonde que prevu :
- mail-core-01 (10.0.0.160 / 37.27.251.162) a tres probablement ete
  reinstalle ou remplace recemment.
- Preuve : SSH depuis bastion install-v3 retourne "REMOTE HOST
  IDENTIFICATION HAS CHANGED" sur la cle ED25519, fingerprint differente
  de l'historique known_hosts ligne 2202.
- ICMP repond OK sur 37.27.251.162 et 10.0.0.160 (machine UP) mais TCP
  REFUSED sur ports 25/465/587/2525 -> postfix non remis en service.
- Floating IP 49.13.35.167 detachee (TIMEOUT au lieu de REFUSED).
- Egress Hetzner sain (Gmail SMTP joignable depuis le meme bastion).

Cela explique pourquoi tous les flux email applicatifs sont casses
(contact form, billing, lifecycle, outbound worker, invitations).

Aucun fix tente. Acces SSH au mail-core impossible sans GO Ludovic +
verification fingerprint legitime.

Actions requises par Ludovic / admin infra :
1. Confirmer reinstallation legitime mail-core-01 via console Hetzner
2. Verifier fingerprint SSH SHA256:3sRIpo1csjE/TUEN2eo8924zVpzO6eWTh2IYUr/Ptl0
3. GO ssh-keygen -R 10.0.0.160 sur bastion install-v3
4. Restart postfix + opendkim + dovecot + rspamd
5. Reattacher floating IP 49.13.35.167 au mail-core-01
6. Verifier listener ports 25/465/587 + firewall hote
7. Test TCP puis test email DEV controle vers info@keybuzz.pro

Audit deliverabilite anterieur PH-MAIL-AUDIT-DELIVERABILITY-01 (2026-04-04)
documentait deja 7 problemes critiques (TLS self-signed, MX relay denied,
Barracuda BRBL, SPF softfail, etc). Hors scope KEY-323 mais a corriger
ulterieurement pour la deliverabilite.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic.

---

## Gaps restants

| Gap | Action requise | Owner |
|---|---|---|
| Confirmer reinstallation mail-core-01 legitime | console Hetzner | Ludovic |
| Verifier fingerprint ED25519 legitime | console Hetzner / cloud-init | Ludovic |
| GO ssh-keygen -R pour reprise SSH | confirmer + lancer | Ludovic |
| Restart postfix + services associes | systemctl restart | Ludovic / admin infra |
| Reattachement floating IP 49.13.35.167 | console Hetzner | Ludovic |
| Test TCP post-restart | curl/nc depuis bastion | CE apres GO |
| Test envoi email DEV controle | endpoint contact DEV + verification reception info@keybuzz.pro | CE apres GO separe |
| Audit deliverabilite 7 problemes anterieurs | TLS, SPF, DKIM, DMARC, Barracuda, Dovecot, Rspamd | phase dediee separee |
| Patch contact.ts info@keybuzz.pro | apres mail OK | phase AS.17.1A separee |

---

## Phrase cible finale

NO GO KEY-323 SMTP FIX BLOCKED BY MAIL SERVER ACCESS. Cause racine
confirmee : mail-core-01 probablement reinstalle (host key SSH ED25519
change) + postfix non remis en service (TCP REFUSED 25/465/587) +
floating IP 49.13.35.167 detachee (TIMEOUT). Egress Hetzner sain.
Action serveur necessaire mais bloquee par mismatch SSH known_hosts.
Aucun fix tente, aucune mutation, aucun secret lu. NO GO PROD PROMOTION
AS.17.0 + AS.17.0.1 maintenu. STOP avant toute action serveur mail /
firewall / secret sans GO Ludovic explicite.

---

## ADDENDUM 2026-05-16 POST-RESTORE AS.17.1B-bis

> Date addendum : 2026-05-16
> Auteur : CE post-incident escalation
> Reference rapports lies :
>  - AS.17.1O+D+E+F+N control plane audit (commit 9956506)
>  - CSV Hetzner hc-activities 2026-05-01 a 2026-05-31

### Hypothese de cause racine confirmee et precisee

L'hypothese principale de cette phase AS.17.1B etait :
"mail-core-01 probablement reinstalle (host key SSH ED25519 change)
+ postfix non remis en service + floating IP detachee".

Avec le CSV Hetzner Cloud Audit fourni par Ludovic le 2026-05-15 et
l'audit AS.17.1O+D+E+F+N complete le 2026-05-16, cette hypothese est
**CONFIRMEE et precisee** :

- mail-core-01 a effectivement ete rebuilt (Hetzner server.rebuild) le
  2026-05-15T10:54:36Z. Coherent avec la nouvelle cle SSH ED25519 du
  serveur. Coherent avec postfix non remis en service avant restore.
  Coherent avec floating IP 49.13.35.167 detachee post-rebuild.
- mail-mx-01 rebuilt 2026-05-15T10:54:37Z, mail-mx-02 rebuilt
  2026-05-15T10:54:53Z.
- Cause racine reelle : compromission du token API Hetzner Cloud RW
  `PvaKOoh...` utilise par un acteur tiers depuis source IP M247 VPN
  `146.70.211.0/32` entre 2026-05-15T08:00:36Z et 11:30:20Z.
- 19 serveurs Hetzner rebuilt au total, 2 servers en rescue mode
  (db-postgres-01 + minio-02), 4 firewalls modifies puis revert vers
  baseline PH-INFRA-02 a 11:30.

L'hypothese initiale "panne infra simple SMTP/firewall/floating IP"
sans contexte securite etait incomplete. La cause racine est un
**incident de securite P0 (compromission token Hetzner)**, pas une
panne infra spontanee.

### Containment effectue par Ludovic (post AS.17.1B audit)

1. Revocation token RW `PvaKOoh...` (2026-05-15 par Ludovic)
2. Creation token RO `incident-audit-readonly-2026-05-16`
3. Restauration manuelle des 3 serveurs mail depuis backups Hetzner :
   - mail-core-01 depuis backup 2026-05-15T06:15:12Z (PRE-ATTACK)
   - mail-mx-01 depuis backup 2026-05-15T10:12:11Z (AMBIGUOUS, voir
     R2 dans AS.17.1O risk register)
   - mail-mx-02 depuis backup 2026-05-14T14:12:06Z (PRE-ATTACK)
4. OTP DEV+PROD refonctionne confirme par Ludovic.

### Etat post-restore verifie cote CE (read-only)

| Verification | Methode | Resultat |
|---|---|---|
| TCP 49.13.35.167:25/587 | bash /dev/tcp depuis bastion | OPEN |
| TCP 37.27.251.162:25/587 | idem | OPEN |
| TCP 10.0.0.160:25/587 | idem (reseau interne Hetzner) | OPEN |
| TCP 91.99.66.6:25 (mail-mx-01) | idem | OPEN |
| TCP 91.99.87.76:25 (mail-mx-02) | idem | OPEN |
| ICMP 49.13.35.167 + 37.27.251.162 + 91.99.66.6 + 91.99.87.76 | ping -c2 | OK 0% loss |
| DNS A mail.keybuzz.io | dig externe | 49.13.35.167 (coherent floating IP) |
| DNS MX keybuzz.io + inbound.keybuzz.io | dig | 10 mail-mx-01 / 20 mail-mx-02 coherent |
| DNS SPF keybuzz.io | dig TXT | v=spf1 ip4:49.13.35.167 mx -all (hardfail OK) |
| DNS SPF inbound.keybuzz.io | dig TXT | v=spf1 ip4:49.13.35.167 -all (coherent) |
| DNS DMARC keybuzz.io | dig TXT _dmarc | v=DMARC1; p=quarantine; ... (strict OK) |
| Floating IP 49.13.35.167 attachee | hcloud floating-ip list | server=mail-core-01 (re-attached post-restore) |
| OTP signup DEV + PROD | utilisation reelle Ludovic | refonctionne |

Verdict E9 post-restore : mail control plane sain et OTP operationnel.

### Verdict revise

Le verdict initial "NO GO KEY-323 SMTP FIX BLOCKED BY MAIL SERVER
ACCESS" est SUPERSEDE par la suite des evenements :

| Avant addendum | Apres addendum |
|---|---|
| Acces SSH au mail-core bloque par mismatch host key | mail-core restaure depuis backup PRE-ATTACK ; acces SSH non encore retabli cote bastion, audit interne en phase AS.17.1N |
| Fix infra propose : reparer SMTP + reattach floating IP + restart postfix | Restauration manuelle effectuee par Ludovic, mail OTP refonctionne |
| Cause racine hypothese : panne infra recente | Cause racine confirmee : compromission token Hetzner RW + rebuild attack ciblee 19 serveurs |
| Hypothese reinstall non prouvee a la date du rapport B | Reinstall (rebuild) prouvee par CSV Hetzner CSP fourni par Ludovic et audit AS.17.1O |

### Risques residuels deplaces vers data plane

Les risques P0 documentes dans AS.17.1O risk register sont :

- R2 P0 mail-mx-01 backup AMBIGUOUS (pendant fenetre attaque) :
  re-restore depuis 2026-05-14T10:12:08Z (id 386478695) possible si
  audit forensique reveler persistance. **Audit prioritaire mail-mx-01
  en AS.17.1N.**
- R3 P0 db-postgres-01 disques exposes 1h en rescue le 2026-05-15T08:06
  -> AS.17.1H Postgres forensic
- R4 P0 minio-02 disques exposes 1h en rescue le 2026-05-15T08:29 ->
  AS.17.1I MinIO forensic
- R5 P0 vault-02 rebuilt apres rescues -> AS.17.1G Vault audit
- R6 P0 backup-01 rebuilt -> AS.17.1M backup chain integrity

### Phrase cible finale revisee

GO KEY-323 SMTP B1 mail-core CONTAINMENT CONFIRMED VIA REBUILD ATTACK
RCA + MANUAL RESTORE. Cause racine reelle = incident securite P0
compromission token Hetzner RW + rebuild attack 19 serveurs depuis
146.70.211.0/32 M247 VPN. Containment effectue manuellement par
Ludovic. Mail control plane post-restore externalement sain (TCP
25/587 OPEN sur 5 IPs, DNS coherent, SPF hardfail, DMARC strict,
floating IP re-attachee, OTP DEV+PROD refonctionne). Risques residuels
P0 confines au data plane (R2 mail-mx-01 backup AMBIGUOUS, R3/R4
rescue DB+MinIO, R5 vault, R6 backup-01) traites en phases suivantes
AS.17.1G/H/I/M/N. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu
jusqu'a completion forensic data plane.

### Hors scope / actions non faites (addendum)

- Aucune mutation Hetzner Cloud post-incident
- Aucun SSH au mail-core/mx-01/mx-02 (audit interne reporte en AS.17.1N)
- Aucun ssh-keygen -R sur bastion (en attente GO per server)
- Aucun test SMTP avec mutation
- Aucun envoi email reel
- Aucun secret lu
- Token RO temporaire `incident-audit-readonly-2026-05-16` utilise via
  methode safe (source /root/.hcloud-ro.env, jamais affiche), supprime
  du bastion en fin d'audit AS.17.1O

---
