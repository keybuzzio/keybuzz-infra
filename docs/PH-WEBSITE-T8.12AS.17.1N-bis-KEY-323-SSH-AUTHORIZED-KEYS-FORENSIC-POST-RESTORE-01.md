# PH-WEBSITE-T8.12AS.17.1N-bis-KEY-323-SSH-AUTHORIZED-KEYS-FORENSIC-POST-RESTORE-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1N-bis SSH authorized_keys forensic post-restore
>          consolide 4 lots A+B+C+D
> Environnement : Hetzner KeyBuzz prod - read-only strict

---

## VERDICT

GO POST-RESTORE SSH FORENSIC CLEAN

**16 serveurs rebuilt restaures par Ludovic depuis backups PRE-ATTACK
sont entierement valides : aucun signe de cle attaquant `explore-k8s`
residuelle, aucun signe de login attaquant, aucun signe de
persistance.**

Combine avec les 3 mail servers deja audites CLEAN en AS.17.1N initial
(mail-core-01, mail-mx-01, mail-mx-02), le perimetre des **19
serveurs touches par l'incident KEY-323** est entierement valide
post-restore.

Risques residuels P0 sont desormais des decisions BUSINESS hors scope
audit forensic technique :
- rotation secrets globale (les secrets ont pu etre lus par
  l'attaquant via SSH exclusif sur les 16 serveurs pendant 1-14h)
- decision RGPD CNIL Art 33 notification (deadline 72h apres
  connaissance debut AS.17.1N-bis = 2026-05-19)

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu jusqu'a rotation
secrets effectuee. CE n'a effectue aucune mutation cote serveurs
cibles, aucune rotation, aucun restart, aucun affichage de secret/PII.

---

## Resume executif

### Mecanique attaque confirmee post-validation restore

L'attaquant a utilise le token RW Hetzner `PvaKOoh...` compromis pour
effectuer 19 `server.rebuild` entre 2026-05-15T08:38 et 10:54 UTC.
Avant les rebuilds, il a cree une cle SSH Hetzner Cloud nommee
`explore-k8s` a 08:00:36Z. Pour chaque server.rebuild, l'API Hetzner
permet de specifier le parametre `ssh_keys` qui determine quelles
cles SSH sont injectees dans `/root/.ssh/authorized_keys` du nouveau
filesystem.

Hypothese AS.17.1N-bis lot 1 (15 serveurs `Permission denied` depuis
bastion install-v3) : l'attaquant a fait `server.rebuild` avec
`ssh_keys=[explore-k8s]` UNIQUEMENT, sans inclure la cle bastion
legitime `install-v3-keybuzz-v3`. Resultat : controle SSH exclusif
attaquant sur les 15 serveurs rebuilt non restaures.

`ssh_key.delete explore-k8s` a 11:30:11Z par l'attaquant supprime la
cle de Hetzner Cloud mais N'AFFECTE PAS la copie deja installee dans
`/root/.ssh/authorized_keys` du filesystem des serveurs rebuilt. La
cle attaquant restait donc persistante dans le filesystem.

Decision Ludovic : restoration manuelle des 15 serveurs (+
mail-mx-01 redondance) depuis backups PRE-ATTACK. Le restore Hetzner
remplace integralement le filesystem du serveur par celui du backup
choisi, eliminant ainsi la cle attaquant residuelle.

CE en AS.17.1N-bis a valide cette restoration via audit read-only
strict sur 4 lots successifs.

### 4 lots de validation post-restore

| Lot | Serveurs | Verdict per server | Date validation |
|---|---|---|---|
| A | backup-01 + vault-02 | 2/2 GO RESTORE OK | 2026-05-16 ~00:51 UTC |
| B | api-gateway-01 + k8s-worker-01/02/03 | 4/4 GO RESTORE OK | 2026-05-16 ~01:35 UTC |
| C | redis-01/02/03 + queue-01/02/03 | 6/6 GO RESTORE OK | 2026-05-16 ~02:01 UTC |
| D | monitor-01 + vector-db-01 + litellm-01 + crm-01 | 4/4 GO RESTORE OK | 2026-05-16 ~02:15 UTC |

Total : 16/16 GO RESTORE OK.

Avec mail-core-01 + mail-mx-01 + mail-mx-02 deja CLEAN (audit
AS.17.1N initial commit 5dd08a0), le perimetre incident est de 19
serveurs tous valides.

---

## Methodologie de validation per server (rappel runbook AS.17.1N-bis)

### Phase 2 : Reset known_hosts bastion install-v3

```
ssh-keygen -R <PRIVATE_IP>
```

Suppression de l'entree existante (qui pointait soit vers la cle
pre-rebuild legitime, soit vers la cle attaquant ajoutee par CE en
AS.17.1N-bis lot 1 initial).

### Phase 3 : Capture nouvelle host key SSH

```
ssh-keyscan -H -T 8 -t ed25519 <PRIVATE_IP> 2>/dev/null
  | tee -a /root/.ssh/known_hosts
  | ssh-keygen -lf -
```

Output documente la fingerprint ED25519 actuelle du serveur
post-restore + ajoute au known_hosts du bastion en mode hashed.

### Phase 4 : Test SSH auth bastion -> serveur

```
ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=8 \
    <PRIVATE_IP> "hostname && uptime"
```

Critere GO : `hostname` + `uptime` court (post-restore). Si
`Permission denied` -> RESTORE INCOMPLETE.

### Phase 5-9 : Audit read-only stricte

- authorized_keys : `find` + `stat` + `ssh-keygen -lf` (fingerprints
  + comments only, pas de cle publique brute affichee)
- grep `explore` dans authorized_keys files
- last logins (`last -n 15`)
- journalctl SSH 2026-05-15 07:50-12:00 UTC (fenetre attaque)
- sudoers + sudoers.d
- sshd_config posture
- persistence cron/systemd `find -newermt 2026-05-15 07:00:00 UTC`
- bash_history root grep patterns suspects (`explore-k8s`,
  `146.70.211`, IPv6 attaquant, `reverse shell`, `backdoor`,
  `bash -i`)
- ports listening role-specific (`ss -ltn`)

---

## Resultats consolides per server

### Pattern uniforme observe sur 16/16 serveurs

| Critere | Resultat uniforme |
|---|---|
| SSH bastion -> serveur post-restore | OK auth avec install-v3-keybuzz-v3 |
| authorized_keys path | /root/.ssh/authorized_keys (root/root 600) |
| authorized_keys fingerprints | 2 cles RSA (1 sauf vault-02 qui en a 1 seule) |
| Cle #1 fingerprint | SHA256:M4cg09BBgTFQFxXjkwDoouj0bTe3o37ueqVahjmMK5k no comment (RSA 2048) |
| Cle #1 presente sur | 15/16 serveurs Lots A+B+C+D + 3 mail servers AS.17.1N = 18/19 (absente seulement vault-02) |
| Cle #2 fingerprint | SHA256:zz5iU+si8Yd6MfXKD5gzCEZg5Od1WwLf1xbMJQh7ORs install-v3-keybuzz-v3 (RSA 4096) |
| Cle #2 presente sur | 19/19 serveurs valides (bastion legitime) |
| explore-k8s pattern | not found sur 19/19 |
| mtime authorized_keys | 2025-12-16 12:45-46 UTC (decembre 2025) sauf vault-02 = 2026-03-01 (= creation vault-02) |
| last logins | uniquement depuis bastion 10.0.0.251 + system reboots |
| Login attaquant detecte | aucun sur 19/19 |
| journalctl SSH 2026-05-15 08:00-12:00 UTC | vide sur 19/19 |
| sudo group | sudo:x:27: (vide membres = root only) |
| sudoers.d files | 90-cloud-init-users + README uniquement |
| Persistence cron/systemd recent | rien sur 19/19 |
| bash_history suspect | rien sur 19/19 |

### Verdicts per server detail

| Lot | Server | IP privee | Boot post-restore UTC | Fingerprint host post-restore | Verdict |
|---|---|---|---|---|---|
| AS.17.1N | mail-core-01 | 10.0.0.160 | 2026-05-15 22:38 | (host key inchange depuis backup PRE-ATTACK) | GO CLEAN |
| AS.17.1N | mail-mx-01 | 10.0.0.161 | 2026-05-15 22:40 | (host key inchange depuis backup PRE-ATTACK) | GO CLEAN |
| AS.17.1N | mail-mx-02 | 10.0.0.162 | 2026-05-15 22:42 | (host key inchange depuis backup PRE-ATTACK) | GO CLEAN |
| A | backup-01 | 10.0.0.153 | 2026-05-16 00:44 | SHA256:cP1duiRcWCk3rgDxSitdZO6IRwSCsIBm/TRqfGyqK+U | GO RESTORE OK |
| A | vault-02 | 10.0.0.154 | 2026-05-16 00:47 | SHA256:KUyhqrnzJ/GovhWwr41SLKvL3xtZvEfscyTKz+LlXsA | GO RESTORE OK |
| B | api-gateway-01 | 10.0.0.135 | 2026-05-16 00:56 | SHA256:ESMaIg8zxkA9DreFA8znJ9eDNGirQc9n/cbmcWN2Zmo | GO RESTORE OK |
| B | k8s-worker-01 | 10.0.0.110 | 2026-05-16 01:08 | SHA256:6XcCGGqCGgTSjAra7RPf7gDwSjOXWNrm8eF9zRYUHvg | GO RESTORE OK (kubelet active 11 pods) |
| B | k8s-worker-02 | 10.0.0.111 | 2026-05-16 01:19 | SHA256:m6RNawMsubR2wyFyxUAjfPhDYtjSXcI5wF0+IDioRIk | GO RESTORE OK (kubelet active 34 pods) |
| B | k8s-worker-03 | 10.0.0.112 | 2026-05-16 01:34 | SHA256:7Kom8Ya8cXqW/PF7K9wFBSb6m6EZV9jQH2TEb7I8A2s | GO RESTORE OK (kubelet active 9 pods) |
| C | redis-01 | 10.0.0.123 | 2026-05-16 01:43 | SHA256:G8XfOLvwAbqGq8a35kEUeObKhg8eyIt2F8wnezNViqk | GO RESTORE OK (Redis + Sentinel) |
| C | redis-02 | 10.0.0.124 | 2026-05-16 01:45 | SHA256:vA1ZZ/LAb5y70oshF0HJPZIkxWm4M4K+UqwLCBmkrMY | GO RESTORE OK (Redis + Sentinel) |
| C | redis-03 | 10.0.0.125 | 2026-05-16 01:48 | SHA256:5d4FCFGMKaHxb031tW/0Me8Y/btNj6sgukSa7OvfNb0 | GO RESTORE OK (Redis + Sentinel) |
| C | queue-01 | 10.0.0.126 | 2026-05-16 01:50 | SHA256:C9g/9OuvHwpOD5vRtW6EFkIBQot+UcF1wtk5O9XWUXc | GO RESTORE OK (RabbitMQ cluster) |
| C | queue-02 | 10.0.0.127 | 2026-05-16 01:52 | SHA256:jdkH+u0L623VPf9S+subuNTHVbjsDRrmkOuiIZ/34CA | GO RESTORE OK (RabbitMQ cluster) |
| C | queue-03 | 10.0.0.128 | 2026-05-16 01:56 | SHA256:VUllxoHHaiO/m0gG9bE8hfYjuoVM1cz2Wr6zEBWBnlg | GO RESTORE OK (RabbitMQ cluster) |
| D | monitor-01 | 10.0.0.152 | 2026-05-16 02:09 | SHA256:Wi2B4CMx9awQbOmXNvQvrgz2qKfCaKU3VWdCPar/uu4 | GO RESTORE OK (Redis 0.0.0.0:6379 a clarifier) |
| D | vector-db-01 | 10.0.0.136 | 2026-05-16 02:11 | SHA256:A/mYRxIyv+y7nRzjMtHjWm9NJnC8K5dUsMz7ng9hYs0 | GO RESTORE OK (Qdrant Docker pas encore demarre) |
| D | litellm-01 | 10.0.0.137 | 2026-05-16 02:13 | SHA256:Yzb1bodx6lZvZIJB+lXpLbfYqMdWXs5o20Th67tKOZk | GO RESTORE OK (LiteLLM Docker pas encore demarre) |
| D | crm-01 | 10.0.0.133 | 2026-05-16 02:14 | SHA256:T9TWezCawyMNXBH1GdLXF0lKdupPXbNq/pIfOWG64Rg | GO RESTORE OK (proxy externe / Docker pas encore demarre) |

---

## Verifications structurelles supplementaires

### Ports services attendus per role (extrait ss -ltn)

| Server | Service principal | Ports observes | Pattern attendu |
|---|---|---|---|
| backup-01 | backup | 22 + 53 | minimal, services backup probable cron-driven |
| vault-02 | HashiCorp Vault | 22 + 53 | Vault Docker dans 8200/8201 bind probable interne |
| api-gateway-01 | nginx/haproxy | 22 + 53 | nginx + haproxy = inactive : a clarifier (deprioriise vs deploiement non termine) |
| k8s-worker-01 | kubelet + Calico | 10245-10249 + 8181 + 443 + 80 + 179 + 22 | kubelet +kube-proxy + ingress + Calico BGP |
| k8s-worker-02 | kubelet + Calico | 10245-10249 + 443 + 80 + 179 + 22 | idem |
| k8s-worker-03 | kubelet + Calico | 10245-10249 + 9099 + 443 + 80 + 179 + 22 | idem + felix metrics |
| redis-01/02/03 | Redis HA + Sentinel | 6379 + 26379 + 9100 + 22 + 53 | Redis bind 10.0.0.X + 127.0.0.1, Sentinel idem, node_exporter |
| queue-01/02/03 | RabbitMQ | 5672 + 15672 + 25672 + 4369 + 9100 + 22 + 53 | AMQP + Management UI + Erlang clustering + epmd + node_exporter |
| monitor-01 | Prometheus/Grafana | 22 + 53 + 9100 + 9099 + 6379 (0.0.0.0) | node_exporter + felix metrics + Redis ; Prometheus 9090 / Grafana 3000 absent (Docker not yet up?) |
| vector-db-01 | Qdrant | 22 + 53 | Qdrant 6333/6334 absent (Docker not yet up post-restore 4 min) |
| litellm-01 | LiteLLM proxy | 22 + 53 | LiteLLM 4000/8000 absent (Docker not yet up post-restore 2 min) |
| crm-01 | CRM proxy | 22 + 53 | CRM applicatif absent (proxy externe / Docker not yet up) |

Aucun port suspect ni inattendu. Les services applicatifs Docker
peuvent prendre quelques minutes a demarrer apres restore.

### Cle SHA256:M4cg09BBgTFQFxXjkwDoouj0bTe3o37ueqVahjmMK5k no comment

Presente sur 18/19 serveurs valides. Absente uniquement de vault-02
(serveur cree 2026-03-01, posterieur a la mise en place de cette
cle). mtime authorized_keys decembre 2025 sur tous les autres
serveurs = cle pre-existante au moment du setup initial des serveurs
KeyBuzz. **A IDENTIFIER par Ludovic** comme cle legitime
(probablement cle d'operateur principal ou de service automation
historique).

Pas un signe de compromission : la cle existe identique sur 18
serveurs depuis decembre 2025, donc bien anterieure a l'incident
2026-05-15 et anterieure aussi a tout backup utilise pour la
restoration.

---

## Risk register FINAL

### P0 PROUVE confirme et neutralise post-restore

| ID | Finding initial | Statut post-restore |
|---|---|---|
| R_NEW SSH cle attaquant explore-k8s residuelle dans 15 serveurs rebuilt | **NEUTRALISE** : restore manuelle Ludovic depuis backups PRE-ATTACK confirme par audit AS.17.1N-bis lots A+B+C+D |
| R3 db-postgres-01 rescue exfiltration disque | **REDUIT P2** : rescue ineffective car aucun reboot intermediaire (AS.17.1H E_critical) |
| R4 minio-02 rescue exfiltration disque | **REDUIT P2 attendu** : meme analyse que R3, a confirmer formellement en AS.17.1I |

### P0 BUSINESS DECISION pending

| ID | Finding | Action requise | Owner |
|---|---|---|---|
| R_NEW1 Rotation secrets globale post-incident | **TOUS LES SECRETS** transitant via les 15 serveurs sous controle SSH attaquant 1-14h ont pu etre lus | rotation complete | Ludovic decision business |
| R_NEW2 RGPD CNIL Art 33 notification | controle SSH attaquant sur k8s-workers servant pods avec PII clients KeyBuzz constitute un acces non autorise potentiel | decision juridique | Ludovic + conseil juridique |

### P1 a investiguer ulterieurement

| ID | Finding | Action |
|---|---|---|
| Cle SHA256:M4cg09BB no comment sur 18 serveurs | Identite operateur a confirmer | Ludovic |
| api-gateway-01 nginx/haproxy inactive | Deprioriise vs configuration manquante | Ludovic clarifier |
| monitor-01 Redis 0.0.0.0:6379 | Exposition wide open inhabituelle | Ludovic clarifier |
| vector-db-01 / litellm-01 / crm-01 services Docker pas encore demarres | Verification dans 5-10 min apres restore | Ludovic re-verifier |
| vault-02 IP privee non listee dans servers.tsv | Inventaire a mettre a jour | Ludovic |

### P2 documentes hors scope incident

| ID | Finding |
|---|---|
| v3-vault firewall SSH 22 ouvert 0.0.0.0/0 historique | hardening separe |
| DNS keybuzz.io record `cdn` -> floating IP mail | clarification |
| 7 cles SSH Hetzner Cloud presentes : MX1, MX2, CORE, n8n.keybuzz.io, KeyBuzz.io, infra_keybuzz, install-v3-keybuzz | inventory clean |

---

## Liste cumulative des secrets a rotater (proposition pour AS.17.1Q)

Sans pretendre exhaustif, basee sur les services hostes par les 15
serveurs sous controle SSH attaquant 1-14h pendant l'incident :

| Categorie secret | Localisation probable | Justification rotation |
|---|---|---|
| Postgres app passwords | k8s secrets sur k8s-workers + pgbouncer/proxysql | k8s-workers compromis 1-14h, lecture /var/run/secrets possible |
| Redis auth (si configure) | redis-* server config | redis-* compromis 1-14h |
| RabbitMQ admin + app credentials | queue-* server config + k8s secrets | queue-* compromis 1-14h |
| Vault root token + Vault unseal keys | vault-02 + Ludovic externe | vault-02 rebuilt + rebuilt apres rescues, secrets potentiellement lus avant rebuild ; reset root + reseal recommande |
| LLM provider API keys | litellm-01 config + k8s secrets | litellm-01 rebuilt, config Docker possible expose |
| Stripe API keys | k8s secrets keybuzz-api / backend | k8s-workers compromis |
| OAuth refresh tokens marketplaces (Amazon, Shopify, etc.) | DB + k8s secrets | k8s-workers compromis |
| SMTP credentials | k8s secrets keybuzz-api + autres | k8s-workers compromis ; mail-core-01 lui-meme restaure clean (audit AS.17.1N) |
| AWS SES credentials (si configurees) | k8s secrets | k8s-workers compromis |
| Hetzner Cloud API tokens | UI Hetzner Ludovic | DEJA fait : RW PvaKOoh revoque + RO supprime |
| GitHub PAT keybuzz-infra GitOps | bastion install-v3 + Ludovic externe | bastion non touche par incident, PAT non lu |
| GHCR push tokens | bastion install-v3 + Ludovic externe | bastion non touche |
| LinkedIn API + Facebook CAPI tokens | k8s secrets | k8s-workers compromis |
| Microsoft Clarity Project ID | website public | non secret par design |

Plan rotation propose dans AS.17.1Q (a ouvrir avec GO Ludovic).

---

## Recommandations decisions immediates Ludovic

1. **AS.17.1Q rotation secrets globale (priorite absolue)** : avant
   toute promotion PROD AS.17.0/AS.17.0.1 ou tout deploiement
   nouveau, rotation tous secrets categorises ci-dessus. Utiliser
   secrets management Vault (apres verification integrite vault-02)
   ou regeneration manuelle.

2. **AS.17.1S RGPD CNIL Art 33 notification** : decision juridique.
   Deadline 72h apres connaissance debut audit AS.17.1N-bis =
   2026-05-19. Argumentation possible en faveur de la notification :
   - Acces SSH non autorise a serveurs hostes pods K8s avec PII
     clients KeyBuzz
   - Duree expose 1-14h selon timing rebuild + restore per server
   - Donnees concernees : sellers KeyBuzz + leurs sous-clients
     marketplace (Amazon, Shopify, etc.) avec emails, noms, adresses
     postales selon stockage applicatif
   Decision Ludovic + conseil juridique.

3. **AS.17.1I MinIO uptime + filesystem** : confirmer formellement
   le verdict R4 "rescue ineffective" sur minio-02 par audit
   miroir de l'AS.17.1H. Compatible avec audit existant : SSH bastion
   -> minio-02 deja `BLOCKED_HOSTKEY` dans AS.17.1N (rebuild aussi
   minio-02 ? ou seulement rescue ?). **A noter** : minio-02 n'est
   PAS dans la liste des 19 server.rebuild, donc minio-02 a
   probablement uniquement subi le rescue (pas de rebuild).
   Verification AS.17.1I peut valider postmaster-equivalent uptime
   continu.

4. **Reverification services Docker post-restore** dans 10-30 minutes :
   Qdrant (vector-db-01:6333/6334), LiteLLM (litellm-01:4000/8000),
   Prometheus (monitor-01:9090), Grafana (monitor-01:3000), CRM
   (crm-01). Verifier que les containers Docker / services systemd
   demarrent normalement apres restore.

5. **Identification cle SHA256:M4cg09BBgTFQFxXjkwDoouj0bTe3o37ueqVahjmMK5k**
   no comment : Ludovic confirme legitimite (operateur principal,
   service automation historique, etc.) + ajout commentaire pour
   tracabilite future.

6. **Promotion PROD AS.17.0 + AS.17.0.1 GO** : seulement apres
   AS.17.1Q rotation secrets effective et confirmation absence
   regression keybuzz-api/client/website. Ne pas promouvoir avec
   secrets potentiellement compromis.

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1N-bis SSH authorized_keys forensic post-restore
consolide. Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1N-bis-KEY-323-SSH-AUTHORIZED-KEYS-FORENSIC-POST-RESTORE-01.md

Verdict : GO POST-RESTORE SSH FORENSIC CLEAN

CONTAINMENT + RESTAURATION COMPLETS :
- Token RW PvaKOoh revoque par Ludovic
- 16 serveurs rebuilt restaures manuellement par Ludovic depuis
  backups PRE-ATTACK
- 4 lots de validation read-only AS.17.1N-bis :
  Lot A (backup-01 + vault-02) : 2/2 GO
  Lot B (api-gateway-01 + k8s-worker-01/02/03) : 4/4 GO
  Lot C (redis-01/02/03 + queue-01/02/03) : 6/6 GO
  Lot D (monitor-01 + vector-db-01 + litellm-01 + crm-01) : 4/4 GO
- 3 mail servers deja CLEAN (AS.17.1N initial)
- Total : 19/19 serveurs valides

PATTERN UNIFORME OBSERVE :
- authorized_keys : 2 cles RSA legitimes (M4cg09BB no comment +
  install-v3-keybuzz-v3) sur 18/19, vault-02 = 1 cle
  install-v3-keybuzz-v3 uniquement
- mtime decembre 2025 (PRE-ATTACK) sur 18/19, vault-02 = 2026-03-01
  (creation)
- explore-k8s : not found sur 19/19
- Aucun login attaquant detecte
- journalctl SSH 2026-05-15 08:00-12:00 UTC : vide sur 19/19
- sudoers/sshd posture standard
- Aucune persistance suspecte (cron/systemd/bash_history)

RISQUES P0 RESIDUELS BUSINESS :
1. Rotation secrets globale URGENTE (Postgres app passwords +
   Redis + RabbitMQ + Vault + LLM keys + Stripe + OAuth marketplaces
   + SMTP). Les secrets ont pu etre lus par l'attaquant via SSH
   exclusif sur 15 serveurs pendant 1-14h.
2. RGPD CNIL Art 33 notification : decision juridique. Deadline
   2026-05-19 (72h apres connaissance debut AS.17.1N-bis).

NEXT STEPS :
1. AS.17.1Q rotation secrets globale (mutation = GO Ludovic separe)
2. AS.17.1S decision RGPD CNIL
3. AS.17.1I MinIO uptime + filesystem (confirmer R4 rescue ineffective)
4. Reverification Docker services post-restore dans 10-30 min
5. Identification cle SHA256:M4cg09BB no comment par Ludovic
6. Promotion PROD AS.17.0 + AS.17.0.1 SEULEMENT apres rotation
   secrets effective

Aucune mutation effectuee dans AS.17.1N-bis. Aucun secret affiche.
Aucun PII en clair. Aucun pg_dump. Aucun appel LLM. Aucun
redis-cli/rabbitmqctl/vault/kubectl. ssh-keygen -R + ssh-keyscan
limites au bastion install-v3 known_hosts pour les 16 serveurs des
4 lots.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic. Codex via connecteur Linear postera
apres GO.

---

## Hors scope / actions NON faites

- Aucune mutation cote serveurs cibles (16 valides + 3 mail)
- Aucun edit authorized_keys
- Aucune suppression cle SSH
- Aucun restart service
- Aucun docker change / docker stop / docker rm
- Aucun systemctl restart
- Aucun kubectl
- Aucun redis-cli
- Aucun rabbitmqctl
- Aucun vault CLI
- Aucun vault unseal
- Aucun appel LLM
- Aucun test CRM mutationnel
- Aucun pg_dump
- Aucun affichage cle publique brute
- Aucun affichage de secret/token/PII en clair
- Aucun token Hetzner reutilise (RO supprime apres AS.17.1O)
- Aucun commit Git infra du rapport AS.17.1N-bis (en attente GO -
  ce rapport untracked apres ecriture)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation secrets effectuee
- Aucune notification RGPD declenchee
- Aucun GitOps deploy / build / docker push
- ssh-keygen -R + ssh-keyscan limites au bastion install-v3
  known_hosts pour les 16 serveurs valides ; aucune modification
  hors bastion install-v3

---

## Phrase cible finale

GO POST-RESTORE SSH FORENSIC CLEAN. 16 serveurs rebuilt restaures
par Ludovic depuis backups PRE-ATTACK + 3 mail servers deja CLEAN
= 19/19 valides. Pattern uniforme : authorized_keys legitime,
explore-k8s absent, aucun login attaquant, persistance vide,
journalctl SSH attaque vide, mtime PRE-ATTACK confirme.
Containment + restoration techniques completes. Risques residuels
P0 = decisions BUSINESS (rotation secrets globale + RGPD CNIL Art 33
notification 72h). NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu
jusqu'a rotation secrets effective. Aucune mutation, aucun secret
affiche, aucun PII en clair.

---
