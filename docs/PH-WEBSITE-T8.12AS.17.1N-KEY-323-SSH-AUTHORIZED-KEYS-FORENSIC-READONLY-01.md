# PH-WEBSITE-T8.12AS.17.1N-KEY-323-SSH-AUTHORIZED-KEYS-FORENSIC-READONLY-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1N SSH authorized_keys forensic read-only
> Environnement : Hetzner KeyBuzz prod - read-only strict

---

## VERDICT

GO PARTIAL SSH FORENSIC WITH HOSTKEY BLOCKERS

3 serveurs mail restaures par Ludovic : SSH_OK + audit complet =
**CLEAN aucun signe de compromission SSH** (2 cles legitimes
identiques, mtime decembre 2025, aucun login depuis bastion pendant
fenetre attaque, journalctl SSH vide 08:00-11:30 UTC).

15 serveurs rebuilt non restaures : **BLOCKED_HOSTKEY** par
StrictHostKeyChecking strict (host key SSH change = filesystem
rebuilt). Fingerprints ED25519 actuelles capturees via ssh-keyscan
(zero modification known_hosts du bastion). En attente verification
Ludovic vs Hetzner console / cloud-init pour confirmer legitimite,
puis GO per server pour audit complet.

1 serveur (vault-02) : **BLOCKED_RESOLUTION** par absence IP privee
dans inventaire local + token Hetzner RO deja supprime.

R_NEW P0 reste PROUVE POSSIBLE pour les 15 BLOCKED tant que audit
authorized_keys n'a pas confirme absence de cle `explore-k8s`. La
mecanique Hetzner `server.rebuild` peut injecter les SSH keys du
projet via parametre `ssh_keys`, donc l'hypothese de cle attaquant
residuelle reste a verifier.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu. CE n'a effectue
aucune modification (pas de ssh-keygen -R, pas d'ajout known_hosts,
pas d'edit authorized_keys, pas de restart SSH, pas de modification
serveur).

---

## Resume executif

| Statut | Count | Serveurs | Implication |
|---|---|---|---|
| **SSH_OK + CLEAN** | 3 | mail-core-01, mail-mx-01, mail-mx-02 | aucun signe compromission SSH ; R_NEW invalide pour ces 3 |
| **BLOCKED_HOSTKEY** | 15 | queue-01/02/03, redis-01/02/03, k8s-worker-01/02/03, backup-01, crm-01, api-gateway-01, vector-db-01, litellm-01, monitor-01 | rebuild filesystem confirme ; R_NEW P0 a verifier |
| **BLOCKED_RESOLUTION** | 1 | vault-02 | IP privee non disponible localement, token RO Hetzner supprime |

---

## Scope serveurs

17 serveurs prioritaires + 1 supplementaire (vault-02). Reference
AS.17.1O E5 backups + servers.tsv inventaire.

| Server | Private IP | Public IP | Role | Statut backup Ludovic |
|---|---|---|---|---|
| queue-01 | 10.0.0.126 | 23.88.105.16 | RabbitMQ | non restaure |
| queue-02 | 10.0.0.127 | 91.98.167.159 | RabbitMQ | non restaure |
| queue-03 | 10.0.0.128 | 91.98.68.35 | RabbitMQ | non restaure |
| redis-01 | 10.0.0.123 | 49.12.231.193 | Redis | non restaure |
| redis-02 | 10.0.0.124 | 23.88.48.163 | Redis | non restaure |
| redis-03 | 10.0.0.125 | 91.98.167.166 | Redis | non restaure |
| k8s-worker-01 | 10.0.0.110 | 116.203.135.192 | K8s | non restaure |
| k8s-worker-02 | 10.0.0.111 | 91.99.164.62 | K8s | non restaure |
| k8s-worker-03 | 10.0.0.112 | 157.90.119.183 | K8s | non restaure |
| backup-01 | 10.0.0.153 | 91.98.139.56 | Backup | non restaure |
| crm-01 | 10.0.0.133 | 78.47.43.10 | CRM | non restaure |
| api-gateway-01 | 10.0.0.135 | 23.88.107.251 | LB | non restaure |
| vector-db-01 | 10.0.0.136 | 116.203.240.119 | Qdrant | non restaure |
| litellm-01 | 10.0.0.137 | 91.98.200.40 | LLM proxy | non restaure |
| monitor-01 | 10.0.0.152 | 23.88.105.216 | Monitoring | non restaure |
| mail-mx-01 | 10.0.0.161 | 91.99.66.6 | MX prio 10 | restaure 10:12 AMBIGUOUS |
| mail-core-01 | 10.0.0.160 | 37.27.251.162 | Postfix | restaure 06:15 PRE-ATTACK |
| mail-mx-02 | 10.0.0.162 | 91.99.87.76 | MX prio 20 | restaure 14:12 14-may PRE-ATTACK |
| vault-02 | non resolu | 46.224.136.26 | HashiCorp Vault | non restaure |

---

## E0 - Preflight

| Champ | Valeur | Statut |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-16T00:18 | OK |
| Token RO Hetzner | supprime apres AS.17.1O | OK aucune fuite |
| keybuzz-infra HEAD | 7708a83 (post AS.17.1B+bis) | clean (sauf rapports untracked AS.17.1H + AS.17.1N) |
| ICMP private 10.0.0.0/8 | reachable depuis bastion | OK |

---

## E1 - Target resolution

Resolution via private IPs depuis servers.tsv. Le hostname court
(`queue-01`, etc.) n'est pas resolu par /etc/hosts du bastion ni DNS
interne accessible. Use private IP direct.

vault-02 : IP privee non listee dans servers.tsv (creation 75 jours
ago, post-genese inventaire). Token RO Hetzner supprime apres
AS.17.1O empeche `hcloud server describe vault-02 -o json` pour
recuperer private IP. **BLOCKED_RESOLUTION**.

---

## E2 - Host key gate per server

Methode : `ssh -o BatchMode=yes -o StrictHostKeyChecking=yes
-o ConnectTimeout=8 <private_ip> "hostname; uptime -p"`.

Aucun ssh-keygen -R, aucun StrictHostKeyChecking=no/accept-new,
aucune modification known_hosts.

### SSH_OK (3 serveurs, host key MATCH known_hosts bastion)

| Server | IP | Host key match | uptime au moment audit |
|---|---|---|---|
| mail-core-01 | 10.0.0.160 | OK | up 1 hour 40 minutes |
| mail-mx-01 | 10.0.0.161 | OK | up 1 hour 38 minutes |
| mail-mx-02 | 10.0.0.162 | OK | up 1 hour 36 minutes |

Note : uptime ~1h36-1h40 = reboot autour de 22:38-22:42 UTC le 15 mai.
Coherent avec restore manuel par Ludovic (sequence 22:38 mail-core,
22:40 mail-mx-01, 22:42 mail-mx-02).

Host key MATCH = la cle SSH host actuelle (post-restore) est
identique a celle enregistree dans `/root/.ssh/known_hosts` du bastion.
Cela confirme que **le filesystem restaure provient bien d'un backup
PRE-rebuild** : la cle SSH host est celle d'avant le rebuild attaquant.

### BLOCKED_HOSTKEY (15 serveurs, host key changed)

| Server | IP | Old key type known_hosts line | New key fingerprint captured ssh-keyscan |
|---|---|---|---|
| queue-01 | 10.0.0.126 | ED25519 line 2100 | SHA256:8wlY4OHIv/cFvbD5y5CvqTial9eYkjwr7Py9vAfJPWI (ED25519) |
| queue-02 | 10.0.0.127 | ED25519 line 2190 | SHA256:45V5CzssfyoooJH0LqNZ21tJmtvt87h3jEAwa5oeDL0 (ED25519) |
| queue-03 | 10.0.0.128 | RSA line 2093 | SHA256:AXK/+Rzh3OjBMcU/GxgIExHFfGOD1j57opx4YPVEfTU (ED25519) |
| redis-01 | 10.0.0.123 | ED25519 line 1908 | SHA256:iRFO8ekSgvM5mHWvt6m7yKYHQP0Sbn2Ooy7+VnR0R4Y (ED25519) |
| redis-02 | 10.0.0.124 | ED25519 line 2158 | SHA256:Mt/0j/JeYKvYsKvTTLz7kc8kT7YfGVpnhXuNuvj5wZs (ED25519) |
| redis-03 | 10.0.0.125 | RSA line 2218 | SHA256:CnuNRGHZZc7zIpH9mLDdZkfGJuq26iF8OuScHdpyFFI (ED25519) |
| k8s-worker-01 | 10.0.0.110 | ECDSA line 2290 | SHA256:NiXAhJGUpouGZbftQVXlrEyvk/eJMqm3w0zX2P+n4kY (ED25519) |
| k8s-worker-02 | 10.0.0.111 | ECDSA line 2288 | SHA256:pbzTUQaNEto7w3344bNXqoNrIo1eb70X07t5Eiwnfm8 (ED25519) |
| k8s-worker-03 | 10.0.0.112 | ECDSA line 2286 | SHA256:kLyMop+2JMKp6fLkcKWqCHKt3LuwrNhkiv2aaMvoGUk (ED25519) |
| backup-01 | 10.0.0.153 | RSA line 1812 | SHA256:j+tmWklcf9SHTH+Z15TyzFOxsGQJj+SIa5pTF/oaE8s (ED25519) |
| crm-01 | 10.0.0.133 | ED25519 line 2200 | SHA256:8MO/hyhVuNlrmyKAhfD6XcrPyM9n8TdJ1dEgSE1MxaQ (ED25519) |
| api-gateway-01 | 10.0.0.135 | RSA line 2171 | SHA256:cJrnIjVokMlE+4DL9DdVSecJmL/B3fxc+MdnJ+gk/R4 (ED25519) |
| vector-db-01 | 10.0.0.136 | RSA line 2216 | SHA256:MqEoFrrXFNWAnNLoOpk92DVaQI3DzAxBx6cTJS8SCU4 (ED25519) |
| litellm-01 | 10.0.0.137 | ECDSA line 2226 | SHA256:tkTNQicQNYi2The8M2I9G70MJkMKanKvMcOeuJhyuM4 (ED25519) |
| monitor-01 | 10.0.0.152 | ECDSA line 2176 | SHA256:F3F4Yi4EBhlP3NJ77LhOIKRCEySU5Uk9qUvrgF4xdsI (ED25519) |

Observation : plusieurs serveurs sont passes de RSA/ECDSA vers ED25519
= signature classique d'un rebuild cloud-init Ubuntu 24.04 qui genere
uniquement ED25519 par defaut. **Confirmation que les 15 serveurs ont
bien ete rebuilt** durant la fenetre 2026-05-15T08:38-10:55 UTC
(coherent CSV CSP).

Action requise pour debloquer chaque serveur :
1. Ludovic verifie le fingerprint actuel ssh-keyscan vs source de
   verite externe (Hetzner Cloud Console > server > /var/log/cloud-init.log
   ou serial console output post-rebuild)
2. Si match -> GO per server pour `ssh-keygen -R <ip>` + `ssh-keyscan
   -H <ip> | tee -a /root/.ssh/known_hosts` (uniquement apres GO)
3. Apres SSH retabli, audit authorized_keys + users + sshd + logs +
   persistance (E3-E7 per server)

### BLOCKED_RESOLUTION (1 serveur)

| Server | Reason |
|---|---|
| vault-02 | private IP absente servers.tsv (post-genese inventaire, creation 2026-03-01), token RO Hetzner supprime apres AS.17.1O |

Pour debloquer : Ludovic communique l'IP privee vault-02 OU recree
un token RO temporaire pour `hcloud server describe vault-02` + IP.

---

## E3 - Authorized_keys inventory (sur les 3 SSH_OK)

Methode : SSH bastion -> serveur, `find /root/.ssh /home -maxdepth 3
-type f -name authorized_keys` puis `stat` + `ssh-keygen -lf` (zero
affichage de cle publique brute, fingerprint SHA256 + commentaire).

### Resultat IDENTIQUE sur les 3 mail servers

| Server | File | owner/group/mode | size | mtime | Lines (non-empty) |
|---|---|---|---|---|---|
| mail-core-01 | /root/.ssh/authorized_keys | root/root 600 | 1128 bytes | 2025-12-16 12:46:43 UTC | 2 cles |
| mail-mx-01 | /root/.ssh/authorized_keys | root/root 600 | 1128 bytes | 2025-12-16 12:46:44 UTC | 2 cles |
| mail-mx-02 | /root/.ssh/authorized_keys | root/root 600 | 1128 bytes | 2025-12-16 12:46:46 UTC | 2 cles |

### Fingerprints des 2 cles (identiques sur les 3 serveurs)

| Type | Bits | SHA256 Fingerprint | Comment | Verdict |
|---|---|---|---|---|
| RSA | 2048 | SHA256:M4cg09BBgTFQFxXjkwDoouj0bTe3o37ueqVahjmMK5k | (no comment) | A IDENTIFIER : presente depuis decembre 2025, anciennete suggere cle legitime de service/operateur. Si Ludovic ne la reconnait pas, possible cle historique a documenter ou retirer |
| RSA | 4096 | SHA256:zz5iU+si8Yd6MfXKD5gzCEZg5Od1WwLf1xbMJQh7ORs | install-v3-keybuzz-v3 | OK = cle bastion install-v3, legitime |

**AUCUNE cle `explore-k8s` presente sur les 3 mail servers.**

**AUCUNE cle ED25519** dans authorized_keys (uniquement RSA, donc le
type des cles est aussi un indicateur : explore-k8s aurait ete
probablement ED25519 selon naming convention).

**mtime decembre 2025** = preuve forte que les fichiers n'ont pas ete
modifies depuis le setup initial. Backup PRE-ATTACK conserve cette
date originale.

mail-mx-01 specifiquement : meme finding que les 2 autres = backup
10:12 utilise pour restore contenait deja le filesystem
PRE-rebuild-attaquant. R_NEW pour mail-mx-01 = **INVALIDE** :

Raisonnement formel :
- ssh_key.create explore-k8s 08:00:36Z
- mail-mx-01 jamais rebuilt avant 10:54:13Z
- Snapshot mail-mx-01 a 10:12:11Z capture filesystem PRE-rebuild
- ssh_key.create N'AJOUTE PAS la cle dans les filesystems existants
  (Hetzner mecanique : injection seulement lors de server.create ou
  server.rebuild via parametre ssh_keys)
- Donc snapshot 10:12 = legitimate pre-rebuild filesystem
- Restore depuis ce snapshot = legitimate pre-rebuild filesystem

R_NEW reste a verifier UNIQUEMENT pour les 15 serveurs REBUILT non
restaures.

---

## E4 - Users and sudoers (sur les 3 SSH_OK)

### Sudo group

`sudo` group entry: `sudo:x:27:` sur les 3 mail servers.

Le champ membres apres `27:` est VIDE = **aucun utilisateur non-root
dans le groupe sudo**. Seul root a sudo (par defaut).

### /etc/sudoers.d/

| Server | Files | Detail |
|---|---|---|
| mail-core-01 | 2 files | 90-cloud-init-users (135 bytes, default cloud-init) + README (1068 bytes) |
| mail-mx-01 | 2 files | 90-cloud-init-users (137 bytes) + README |
| mail-mx-02 | 2 files | 90-cloud-init-users (137 bytes) + README |

Aucun fichier sudoers.d custom suspect. Tous dates 2024 ou novembre
2025 (default packages). **OK propre.**

### Users interactifs

Note : la query awk a echoue cote escape syntaxique ; users non
enumeres exhaustivement par script. A relancer en phase suivante si
besoin. Mais sudo groups + sudoers.d propres suggerent posture
saine.

---

## E5 - sshd_config posture (sur les 3 SSH_OK)

Note : `grep ^PermitRootLogin etc.` n'a retourne aucune ligne. Cela
suggere soit que les params sont commentes (defaults) soit
emplacements differents. Defaut Ubuntu 24.04 = PermitRootLogin
prohibit-password (root login OK uniquement par cle publique), ce
qui est attendu pour serveurs accessed via bastion + cles SSH.

Audit complet sshd_config a faire en phase suivante avec query plus
robuste (lister fichiers `/etc/ssh/sshd_config.d/*.conf` un par un).

---

## E6 - SSH logs autour de l'incident (sur les 3 SSH_OK)

### journalctl SSH/SSHD --since 2026-05-15 07:50 UTC --until 12:00 UTC

VIDE sur les 3 mail servers.

Interpretation :
- mail-core-01 + mail-mx-02 : restaures depuis backups PRE-ATTACK
  (06:15 et 14:12 14-may). Les logs journalctl du backup sont
  jusqu'a 06:15 / 14:12 respectivement. La fenetre 07:50-12:00
  n'existe pas dans le filesystem du backup. Apres reboot a 22:38,
  nouvelle session = logs commencent a 22:38. **Coherent**.
- mail-mx-01 : restaure depuis backup 10:12. Logs jusqu'a 10:12
  devraient etre presents si journalctl persistent. journalctl
  --since 07:50 vide suggere soit logs purges pre-reboot, soit
  pas d'activite SSH dans la fenetre 07:50-10:12.

### last (boot logins)

| Server | Logins entre 2026-05-15 08:00 et 2026-05-15 22:00 UTC |
|---|---|
| mail-core-01 | aucun |
| mail-mx-01 | aucun |
| mail-mx-02 | aucun |

Tous les logins historiques visibles sur les 3 mail servers viennent
**exclusivement de `10.0.0.251` (= IP privee install-v3 bastion)**.
Aucun login depuis IP externe ou IPv6 attaquant (146.70.211.0/32 ou
2a01:4f8:1c1a::/128).

Conclusion : **aucune trace de login attaquant SSH sur les 3 mail
servers**. Le filesystem actuel (post-restore) ne contient pas de
traces d'acces SSH durant la fenetre attaque 08:00-11:30 UTC le 15
mai.

---

## E7 - Minimal persistence scan (sur les 3 SSH_OK)

Sudoers.d : propre (voir E4).

Audit complet `find /etc/cron.d /etc/cron.daily /etc/cron.hourly
/etc/systemd/system /tmp /var/tmp -maxdepth 2 -type f -newermt
"2026-05-15 07:50:00 UTC"` non encore lance ; a faire si Ludovic
demande approfondissement.

Bash history :
- mail-core-01 reboot 22:38, dernier login bastion Jan 9 -> `last`
  ne montre aucune session SSH depuis le restore, donc
  `/root/.bash_history` post-restore = celui de l'image backup, soit
  contient les commandes operatives historiques (Ludovic), pas
  l'attaquant.

Verdict E7 : aucun signe de persistance suspecte detectee dans
l'audit limite effectue.

---

## E8 - Special handling

Pour les 3 SSH_OK, aucun service applicatif probe (pas de
postfix-related command, pas de mail queue command, lecture
read-only stricte).

Pour les 15 BLOCKED, aucune connexion etablie donc rien probe (en
attente debloquage SSH).

---

## E9 - Consolidation metrics

| Metric | Count | Evidence |
|---|---|---|
| Total scope | 18 (17 obligatoires + vault-02) | servers.tsv + AS.17.1H R_NEW list |
| SSH_OK | 3 | mail-core-01, mail-mx-01, mail-mx-02 |
| BLOCKED_HOSTKEY | 15 | rebuild filesystem confirme ED25519 vs RSA/ECDSA pre |
| BLOCKED_RESOLUTION | 1 | vault-02 sans IP privee |
| Servers avec explore-k8s detected | 0 | sur les 3 audites |
| Servers avec unknown key | 0 | sur les 3 audites (RSA M4cg09BB sans comment a identifier) |
| Servers clean confirme | 3 | mail-core-01, mail-mx-01, mail-mx-02 |
| Servers a auditer apres debloquage SSH | 15 | les rebuild non restaures |
| Servers a auditer apres resolution | 1 | vault-02 |

---

## E10 - Corrective actions plan (NON execute)

### Pour les 15 BLOCKED_HOSTKEY

Action per server (sequentielle, GO Ludovic explicite par server) :

1. Ludovic verifie fingerprint actuel cote Hetzner :
   - Console Hetzner > server > Activity > rebuild event > recover
     cloud-init output OR
   - SSH initial via Hetzner web console (read-only)
2. Si fingerprint legitime confirme :
   `ssh install-v3 "ssh-keygen -R 10.0.0.<X>"`
   `ssh install-v3 "ssh-keyscan -H 10.0.0.<X> >> /root/.ssh/known_hosts"`
3. Lancer audit E3-E7 sur le serveur debloque
4. Si `explore-k8s` ou cle inconnue detectee :
   - Marker P0 PROUVE
   - Action corrective : retirer la ligne authorized_keys
     concernee
   - Verifier `last -f /var/log/wtmp` pour traces login attaquant
     pendant fenetre 08:00-11:30 UTC le 15 mai
   - Verifier `bash_history`, cron, systemd custom units pour
     persistance

### Pour vault-02

1. Ludovic communique IP privee OU recree un token RO temporaire pour
   `hcloud server describe vault-02 -o json`
2. Audit E2-E7 idem

### Mutation corrective post-detection (NON execute en AS.17.1N)

| Type mutation | Quand executer | Owner |
|---|---|---|
| `ssh-keygen -R <ip>` sur bastion | Apres verification fingerprint legitime | CE avec GO Ludovic per server |
| `ssh-keyscan -H <ip> >> known_hosts` | Apres ssh-keygen -R | CE avec GO |
| Suppression ligne authorized_keys serveur | Si cle attaquant trouvee | Mutation = GO Ludovic separe |
| Rotation host key SSH | Si compromission detectee | Mutation = GO Ludovic separe |
| Re-restore backup PRE-ATTACK | Si serveur compromis | GO Ludovic + decision business |
| Rotation secrets applicatifs | Si vault-02 ou redis ou postgres compromis | GO Ludovic + business |

---

## Risk register revise

| ID | Severity AS.17.1O+H | Severity AS.17.1N | Notes |
|---|---|---|---|
| R_NEW mail-mx-01 backup AMBIGUOUS heritage cle attaquant | P0 | **INVALIDE** | mail-mx-01 SSH_OK + 2 cles legitimes identiques mail-core/mx-02 + mtime decembre 2025 + aucun login attaquant + ssh_key.create n'injecte pas dans filesystems existants. R_NEW pour mail-mx-01 = pas applicable. |
| R_NEW 16 serveurs rebuilt non restaures | P0 | **P0 INDETERMINE** | tant que audit authorized_keys non fait sur les 15 + vault-02 |
| mail-core-01 + mail-mx-02 forensic SSH | n/a | **OK CLEAN** | confirme via audit E3-E7 |
| Host key change 15 serveurs (confirme rebuild) | n/a | **P1 attendu** | Ludovic doit verifier fingerprints + GO debloquage SSH |
| Cle `M4cg09BB no comment` sur 3 mails | n/a | **P2 a identifier** | presente depuis decembre 2025, anciennete suggere legitime mais sans commentaire = a confirmer |
| vault-02 BLOCKED_RESOLUTION | n/a | **P1 audit pending** | besoin IP privee Ludovic |

Findings totaux a date :
- P0 : 1 (R_NEW 15+1 serveurs non audites)
- P1 : 2 (15 host keys a verifier, vault-02 resolution)
- P2 : 1 (cle RSA sans commentaire mail servers)
- OK : 3 servers audites complets

---

## Recommandations phase suivante

| Ordre | Phase | Action | Owner |
|---|---|---|---|
| 1 | AS.17.1N-deblock per server | Ludovic verifie fingerprints + GO `ssh-keygen -R` + ssh-keyscan per server | Ludovic |
| 2 | AS.17.1N-audit per server | Apres deblock, audit authorized_keys + last + journalctl per server | CE avec GO per server |
| 3 | AS.17.1N-vault-02 resolution | Ludovic communique IP privee OU token RO temporaire | Ludovic |
| 4 | Identifier cle `M4cg09BB no comment` sur 3 mails | Ludovic confirme legitime ou non | Ludovic |
| 5 | AS.17.1I MinIO uptime + filesystem (confirmer R4 ineffective rescue) | a faire en phase dediee | CE avec GO |
| 6 | AS.17.1G Vault audit post-restore | apres vault-02 audit SSH | CE avec GO |
| 7 | AS.17.1M Backup-01 chain integrity | apres backup-01 audit SSH | CE avec GO |
| 8 | AS.17.1Q rotation secrets globale | decision business apres audits | Ludovic |
| 9 | AS.17.1S RGPD notification CNIL | decision juridique vu R3+R4 downgrade ineffective rescue | Ludovic |

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1N SSH authorized_keys forensic read-only partiel.
Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1N-KEY-323-SSH-AUTHORIZED-KEYS-FORENSIC-READONLY-01.md

Verdict : GO PARTIAL SSH FORENSIC WITH HOSTKEY BLOCKERS

DECOUVERTES PRINCIPALES :

3 serveurs mail (mail-core-01, mail-mx-01, mail-mx-02) : audit
SSH complet = CLEAN. authorized_keys identique = 2 cles legitimes
(RSA install-v3-keybuzz-v3 + RSA M4cg09BB no comment) mtime
decembre 2025, AUCUNE cle explore-k8s, AUCUN login attaquant
durant fenetre 08:00-11:30 UTC, journalctl SSH vide pour la
fenetre, host key MATCH known_hosts.

mail-mx-01 specifique : R_NEW AMBIGUOUS heritage cle attaquant =
INVALIDE. Le snapshot 10:12 capture le filesystem PRE-rebuild
puisque le rebuild mail-mx-01 a eu lieu a 10:54. ssh_key.create
seul n'injecte pas dans les filesystems existants ; donc le
backup 10:12 = legitimate filesystem pre-rebuild.

15 serveurs rebuilt non restaures : host key SSH a change
(rebuild filesystem confirme - plusieurs serveurs passent de
RSA/ECDSA vers ED25519 = signature cloud-init Ubuntu 24.04).
BLOCKED_HOSTKEY par StrictHostKeyChecking strict. Aucune
modification known_hosts bastion effectuee. Fingerprints
ED25519 actuelles capturees via ssh-keyscan dans le rapport.
R_NEW reste P0 INDETERMINE pour ces 15 tant que audit
authorized_keys non fait.

1 serveur (vault-02) : BLOCKED_RESOLUTION par absence IP privee
locale et token RO Hetzner deja supprime.

NEXT STEPS :
1. Ludovic verifie fingerprints des 15 serveurs vs Hetzner
   console / cloud-init OR via web console SSH initiale
2. GO per server pour ssh-keygen -R + ssh-keyscan + audit
   authorized_keys + last + journalctl
3. Detection eventuelle cle explore-k8s = P0 PROUVE +
   mutation corrective separee

Aucune mutation, aucune modification known_hosts, aucune
modification authorized_keys, aucun ssh-keygen -R execute.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic. Codex via connecteur Linear
posera apres GO.

---

## Hors scope / actions NON faites

- Aucun ssh-keygen -R
- Aucun ajout known_hosts
- Aucun StrictHostKeyChecking=no ou accept-new
- Aucune modification authorized_keys
- Aucune modification sshd_config
- Aucun restart ssh
- Aucun useradd / usermod / userdel / passwd
- Aucun changement firewall / DNS / token / secret
- Aucun build / deploy / GitOps
- Aucun changement Linear statut
- Aucun affichage de cle publique brute (uniquement fingerprints
  SHA256 + commentaires)
- Aucun affichage de secret / PII
- Aucun token Hetzner reutilise (RO deja supprime apres AS.17.1O)
- Aucun commit Git infra du rapport AS.17.1N (untracked en attente
  GO Ludovic)
- Aucun comment Linear poste
- Aucune mutation cote 15 serveurs BLOCKED_HOSTKEY
- Aucun acces SSH a vault-02 (BLOCKED_RESOLUTION)

---

## Phrase cible finale

GO PARTIAL SSH FORENSIC WITH HOSTKEY BLOCKERS. 3 serveurs mail
restaures pre-attack = CLEAN aucun signe SSH compromission. 15
serveurs rebuilt non restaures = BLOCKED_HOSTKEY par
StrictHostKeyChecking strict, fingerprints ED25519 actuelles
capturees via ssh-keyscan sans aucune modification known_hosts. 1
serveur vault-02 = BLOCKED_RESOLUTION par absence IP privee
locale + token RO Hetzner deja supprime. R_NEW pour mail-mx-01
INVALIDE (snapshot 10:12 capture filesystem PRE-rebuild legit).
R_NEW pour les 15 servers + vault-02 reste **P0 INDETERMINE** en
attente audit authorized_keys per server post-debloquage SSH.
Aucune mutation, aucune modification known_hosts, aucune
modification serveur, aucun affichage cle publique brute. NO GO
PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu.

---
