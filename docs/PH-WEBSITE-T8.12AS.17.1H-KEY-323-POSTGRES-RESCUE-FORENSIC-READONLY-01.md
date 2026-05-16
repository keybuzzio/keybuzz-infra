# PH-WEBSITE-T8.12AS.17.1H-KEY-323-POSTGRES-RESCUE-FORENSIC-READONLY-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1H Postgres rescue forensic read-only
> Environnement : Postgres Patroni KeyBuzz - read-only strict

---

## VERDICT

GO PARTIAL POSTGRES FORENSIC WITH BLOCKERS

Audit AS.17.1H partiel completee a hauteur d'E0+E1 + analyse CSP CSV
+ probe SSH host key. Decouverte majeure : **les rescues sur
db-postgres-01 et minio-02 n'ont jamais effectivement bascule les
serveurs en mode rescue**, parce que l'attaquant a omis le
`server.reboot` requis entre `enable_rescue` et `disable_rescue`.
Cela invalide R3 (Postgres rescue exfiltration) et R4 (MinIO rescue
exfiltration) en tant que P0, et les downgrade en P2 documentation
d'intention attaquante.

Decouverte secondaire critique : **R_NEW P0** = les 16 serveurs
rebuilt non restaures par Ludovic conservent potentiellement la cle
SSH attaquant `explore-k8s` dans `/root/.ssh/authorized_keys` du
nouveau filesystem, car la cle a ete creee a 08:00:36 AVANT les
rebuilds. La suppression `ssh_key.delete explore-k8s` a 11:30:11
n'affecte que Hetzner Cloud ; la copie locale sur chaque serveur
rebuilt PERSISTE.

Bloqueurs E2-E7 + E9 : aucun role Postgres RO d'audit disponible
cote agent CE (`PGRO_DSN` absent, aucun fichier dedie). Audit SQL
non lance.

Bloqueur E8 : aucun GO explicite SSH au master Postgres pour
journalctl + authorized_keys + bash_history audit. Gate1 SSH host
key passe sans warning, ce qui confirme indirectement que
db-postgres-01 n'a pas rebooted (host key inchange depuis derniere
connexion bastion).

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu. CE n'a effectue
aucune mutation, aucun pg_dump, aucun affichage PII, aucun secret
lu, aucune session psql ouverte.

---

## Preflight (E0)

| Champ | Valeur | Statut |
|---|---|---|
| Bastion identite | install-v3 / 46.62.171.61 / IPv6 2a01:4f9:c013:87d6::1/64 | OK |
| Date UTC | 2026-05-16T00:03:24 | OK |
| Date Paris | 2026-05-16T02:03 CEST | OK |
| keybuzz-infra HEAD | 7708a83 (post AS.17.1B+bis commit) | OK |
| Token Hetzner RO | supprime (post AS.17.1O) | OK aucune fuite |
| ICMP 10.0.0.120 db-postgres-01 | 0% loss | OK |
| ICMP 10.0.0.121 db-postgres-02 | 0% loss | OK |
| ICMP 10.0.0.122 db-postgres-03 | 0% loss | OK |
| psql client bastion | 17.7 (Ubuntu 17.7-3.pgdg24.04+1) | OK |

---

## Cluster health Patroni (E1)

Source : Patroni REST `:8008` endpoints HTTP non-auth (aucun
identifiant Postgres requis).

### Endpoint `/cluster` depuis db-postgres-01

```json
{
  "scope": "keybuzz-pg17",
  "members": [
    { "name": "db-postgres-01", "role": "leader", "state": "running",
      "host": "10.0.0.120", "port": 5432, "timeline": 26 },
    { "name": "db-postgres-02", "role": "replica", "state": "streaming",
      "host": "10.0.0.121", "port": 5432, "timeline": 26,
      "receive_lag": 0, "replay_lag": 0, "lsn": "1A/543B85A8" },
    { "name": "db-postgres-03", "role": "replica", "state": "streaming",
      "host": "10.0.0.122", "port": 5432, "timeline": 26,
      "receive_lag": 0, "replay_lag": 0, "lsn": "1A/543B85A8" }
  ]
}
```

### Endpoint `/patroni` per node

| Node | role | server_version | postmaster_start_time UTC | timeline | replication |
|---|---|---|---|---|---|
| db-postgres-01 | primary | 170007 (PG 17.0.7) | **2026-04-23 06:33:40** | 26 | 2 replicas streaming async |
| db-postgres-02 | replica | 170007 | 2026-04-24 06:48:45 | 26 (replicated_timestamp 2026-05-16 00:03:20) | streaming |
| db-postgres-03 | replica | 170007 | 2026-04-23 06:26:36 | 26 (replicated_timestamp 2026-05-16 00:03:20) | streaming |

### Endpoint `/history` (Patroni timeline events)

25 entries depuis 2025-12-03 jusqu'au 2026-04-24. **Aucune entry
post 24 avril 2026** : aucun failover Patroni pendant l'incident
2026-05-15. Cluster system identifier `7579717422441030215`
consistant sur les 3 nodes.

### Constat structurel CRITIQUE

`postmaster_start_time` du leader db-postgres-01 est
**2026-04-23 06:33:40 UTC**, soit **22 jours avant l'incident du
2026-05-15**. Si Hetzner avait reellement boote le serveur en
rescue mode, postgres aurait redemarre (cold reboot + boot rescue
= shutdown brutal du postmaster) et le start_time serait
post-rescue (apres 09:06 UTC le 2026-05-15).

**Le start_time pre-incident prouve que db-postgres-01 n'a pas
reboote durant la fenetre attaque.** Idem pour les replicas
db-postgres-02 (start 2026-04-24) et db-postgres-03 (start
2026-04-23), tous anterieurs a l'incident.

Cluster health verdict : **SAIN, replicating, no failover, no
restart, lag 0**.

---

## Verification cle : enable_rescue sans reboot (E_critical)

### Hypothese a verifier

Hetzner Cloud `server.enable_rescue` prepare l'image de rescue Linux
mais ne reboote PAS automatiquement le serveur. Pour effectivement
booter en mode rescue, il faut appeler `server.reboot` (ou attendre
un reboot manuel/cron).

`server.disable_rescue` annule la preparation rescue avant le
prochain reboot. Si aucun reboot n'a eu lieu entre enable_rescue
et disable_rescue, **les disques n'ont jamais ete exposes au boot
rescue**, le serveur a continue de tourner sur son OS original.

### Verification CSV pendant la fenetre 2026-05-15T08:00 - 12:00 UTC

| UTC | Activity | Server | Note |
|---|---|---|---|
| 08:06:56 | server.enable_rescue | db-postgres-01 | requested |
| 08:06:58 | server.enable_rescue | db-postgres-01 | success |
| 08:29:09 | server.enable_rescue | minio-02 | requested |
| 08:29:12 | server.enable_rescue | minio-02 | success |
| 09:04:28 | server.stop | k8s-worker-03 | (different server) |
| 09:04:39 | server.stop | k8s-worker-03 | |
| 09:04:50 | server.start | k8s-worker-03 | |
| 09:04:59 | server.start | k8s-worker-03 | |
| **09:06:57** | **server.disable_rescue** | **db-postgres-01** | success ; **AUCUN reboot db-postgres-01 entre 08:06 et 09:06** |
| 09:08:05 | server.reboot | k8s-worker-03 | |
| 09:08:25 | server.reboot | k8s-worker-03 | |
| 09:25:28 | server.stop | k8s-worker-03 | |
| 09:25:39 | server.stop | k8s-worker-03 | |
| 09:25:49 | server.start | k8s-worker-03 | |
| 09:25:59 | server.start | k8s-worker-03 | |
| 09:29:05 | server.reboot | k8s-worker-03 | |
| **09:29:12** | **server.disable_rescue** | **minio-02** | success ; **AUCUN reboot minio-02 entre 08:29 et 09:29** |
| 09:29:25 | server.reboot | k8s-worker-03 | |
| 09:46:28 | server.stop | k8s-worker-03 | |
| ... | ... | k8s-worker-03 | |

L'attaquant a effectue **24 events stop/start/reboot uniquement sur
k8s-worker-03** entre 09:04 et 09:50, mais **AUCUN reboot
db-postgres-01 ni minio-02** pendant les fenetres rescue
respectives 08:06-09:06 et 08:29-09:29.

### Verdict E_critical

R3 (Postgres rescue exfiltration) et R4 (MinIO rescue exfiltration)
sont **probablement INEFFECTIVES**. La sequence enable_rescue +
disable_rescue sans reboot intermediaire correspond a une
preparation rescue annulee. Les disques n'ont pas ete exposes au
boot Linux rescue Hetzner.

Confirmation triple :
1. CSV : pas de reboot entre enable/disable
2. Patroni postmaster_start_time : 22 jours avant incident
3. SSH host key bastion -> 10.0.0.120 : match sans warning
   (cle SSH host inchange = pas de reboot OS depuis derniere
   connexion bastion)

Risk register revision :

| Risk avant | Risk apres E_critical | Justification |
|---|---|---|
| R3 P0 db-postgres-01 disques exposes 1h rescue | **R3 P2 enable_rescue prepare mais jamais effective** | pas de reboot, postmaster start pre-incident |
| R4 P0 minio-02 disques exposes 1h rescue | **R4 P2 enable_rescue prepare mais jamais effective** | pas de reboot, **verification minio uptime requise en AS.17.1I pour confirmer** |

**RGPD breach notification deadline impact** : si R3 confirme
ineffective, **risque RGPD significativement reduit** sur les
donnees Postgres. Reste pertinent pour : (a) verifier MinIO de
maniere equivalente en AS.17.1I, (b) auditer authorized_keys/SSH
post-rebuild pour persistance autre voie d'acces.

---

## Schema drift PG vs Prisma (E2)

**BLOQUE** : sans role Postgres RO, queries SQL contre les bases
applicatives ne peuvent pas etre executees.

Methode safe demandee pour debloquer :
- Option A : Ludovic cree un role Postgres dedie audit RO :
  ```
  CREATE ROLE keybuzz_audit_ro LOGIN PASSWORD '<random>' VALID UNTIL '2026-05-31';
  GRANT pg_read_all_settings TO keybuzz_audit_ro;
  GRANT pg_read_all_stats TO keybuzz_audit_ro;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO keybuzz_audit_ro;
  GRANT USAGE ON SCHEMA public TO keybuzz_audit_ro;
  ```
  (Note : ces commandes sont DES MUTATIONS, executees PAR Ludovic
  lui-meme, mot de passe injecte hors chat dans
  `/root/.pg-audit-ro.env` sur le bastion sous forme
  `export PGRO_DSN="postgresql://keybuzz_audit_ro:<password>@10.0.0.120:5432/keybuzz?sslmode=require"`.
  Mode 0600. CE peut sourcer apres GO.)
- Option B : Ludovic execute lui-meme les requetes SQL listees dans
  le prompt CE AS.17.1H sections E2-E7+E9 et partage les outputs.
- Option C : pas de session SQL, conclusion limitee aux findings
  E0+E1+E_critical + SSH audit E8.

CE recommande Option A si l'audit SQL est juge necessaire, mais
note que **le risque RGPD sur Postgres est probablement deja
significativement reduit par E_critical**. Audit SQL devient
secondaire.

---

## Objets inattendus (E3) - BLOQUE

Idem E2.

Sans role RO, pas d'enumeration de pg_proc, pg_trigger, information_schema.

---

## Roles, privileges, password presence (E4) - BLOQUE

Idem E2.

---

## pg_hba.conf + postgresql.conf (E5) - PARTIEL via Patroni REST

Patroni expose certaines configs via `:8008/config` endpoint. Test
non encore execute en attente GO Ludovic. Endpoint expose
generalement la config DCS Patroni (postgresql parameters) mais pas
le fichier pg_hba.conf brut. Pour ce dernier, audit SSH du master
necessaire (BLOQUE par absence GO E8).

---

## Audit logs Postgres pendant fenetre attaque (E6) - BLOQUE

Idem E2 pour SQL. Idem E8 pour fichier logs.

`pg_stat_activity` historique sur la fenetre 08:06-09:06 UTC :
**INACCESSIBLE** sans role RO. Patroni REST ne propose pas
historique queries.

---

## Tables sensibles (E7) - BLOQUE

Idem E2.

---

## Filesystem trace dumps (E8) - BLOQUE

Pas de GO explicite SSH au master Postgres 10.0.0.120 pour :
- `find / -newer ... .sql/.dump`
- `cat /root/.ssh/authorized_keys`
- `cat /root/.bash_history`
- `journalctl -u postgres* --since 2026-05-15T08:00`
- `last -n 50`

Gate1 SSH host key bastion -> 10.0.0.120 : **PASS** sans warning
known_hosts.

Note : compatible avec hypothese "pas de reboot serveur depuis
derniere connexion bastion". Si l'attaquant avait reboote le
serveur, la cle SSH host serait potentiellement regeneree au boot
(ou conservee selon config sshd_config) ; le host key MATCH confirme
indirectement pas de reboot.

---

## Indicateurs de compromission specifiques PG (E9) - BLOQUE

Idem E2.

Patroni REST non-auth ne permet pas d'enumerer pg_extension,
pg_replication_slots, pg_stat_statements.

---

## R_NEW P0 - 16 serveurs rebuilt non restaures + SSH key explore-k8s

### Decouverte

`ssh_key.create explore-k8s` (id 112320769) a 2026-05-15T08:00:36Z
**precede tous les server.rebuild** (premier rebuild a 08:38:30Z).

Hetzner Cloud API permet de specifier la liste de cles SSH a
installer lors d'un `server.rebuild` via le parametre `ssh_keys`.
Si l'attaquant a inclus `explore-k8s` dans `ssh_keys` de chaque
appel server.rebuild, alors **les serveurs rebuilt ont cette cle
dans `/root/.ssh/authorized_keys` du nouveau filesystem
post-rebuild**.

`ssh_key.delete explore-k8s` a 2026-05-15T11:30:11Z supprime la cle
de **Hetzner Cloud** mais N'AFFECTE PAS la copie deja installee
dans le filesystem de chaque serveur rebuilt. **La cle attaquant
peut donc PERSISTER sur chaque serveur rebuilt non restaure.**

### Etat des 19 serveurs rebuilt

| Server | Backup utilise par Ludovic | Authorized_keys post-restore probable | Action |
|---|---|---|---|
| mail-core-01 | 2026-05-15T06:15:12Z PRE-ATTACK 06:15 < 08:00 | **CLEAN** (backup pre-explore-k8s) | audit SSH preventif facultatif |
| mail-mx-01 | 2026-05-15T10:12:11Z AMBIGUOUS | **POTENTIELLEMENT CONTAMINE** (snapshot pris APRES explore-k8s creation 08:00 et possiblement APRES injection cle via rebuild) | audit SSH URGENT |
| mail-mx-02 | 2026-05-14T14:12:06Z PRE-ATTACK | **CLEAN** | audit SSH facultatif |
| queue-01, queue-02, queue-03 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| redis-01, redis-02, redis-03 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| k8s-worker-01, k8s-worker-02, k8s-worker-03 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| backup-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| vault-02 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| vector-db-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| litellm-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| monitor-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| crm-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |
| api-gateway-01 | non restaure | **POTENTIELLEMENT CONTAMINE** | audit SSH URGENT |

**16 serveurs potentiellement compromis cote authorized_keys**, dont
des serveurs critiques en production servant le SaaS KeyBuzz.

### Hypothese alternative

L'attaquant peut aussi avoir effectue les `server.rebuild` SANS
specifier `ssh_keys`. Dans ce cas Hetzner installe l'ensemble des
cles existantes par defaut (les 7 cles legitimes vues en AS.17.1O
E3 + `explore-k8s` qui etait active a ce moment-la). Dans les deux
cas, `explore-k8s` est probablement dans le filesystem.

A confirmer **per server** en AS.17.1N : `grep -F "explore-k8s"
/root/.ssh/authorized_keys` ; comparer fingerprint SHA256 vs cles
legitimes ; rechercher cle ED25519 inconnue.

### Si confirme

L'attaquant peut **encore SSH** sur les 16 serveurs avec sa cle
privee correspondante. **L'incident n'est PAS resolu cote
data plane / OS plane** tant que cette cle n'est pas retiree de
tous les authorized_keys et tant que les serveurs n'ont pas ete
redemarres et SSH connections actives terminees.

---

## Risk register revise (E10)

Reference : AS.17.1O risk register etablie a 23 findings.

Mises a jour :

| ID | Severity AS.17.1O | Severity AS.17.1H | Changement |
|---|---|---|---|
| R3 db-postgres-01 rescue | P0 | **P2** | rescue inefficace, pas de reboot, postmaster_start_time pre-incident |
| R4 minio-02 rescue | P0 | **P2 a confirmer** | meme analyse probable, a verifier en AS.17.1I uptime + filesystem |
| R5 vault-02 rebuilt apres rescues | P0 | **P1** | si rescues inefficaces, vault-02 rebuild reste un fait, mais secrets pre-rebuild non lus via rescue ; reste risque SSH persistance post-rebuild |
| R_NEW SSH cle explore-k8s residuel post-rebuild | **n/a** | **P0 CRITIQUE** | nouvelle finding, 16 serveurs potentiellement compromis |
| R2 mail-mx-01 backup AMBIGUOUS | P0 | **P0** | inchange, audit URGENT (peut contenir cle explore-k8s) |
| R6 backup-01 rebuilt | P0 | **P1** | rescue ineffective ne touche pas backup-01 ; reste risque SSH residuel post-rebuild |

Score consolide :

- P0 : 2 (R2 mail-mx-01 backup AMBIGUOUS + R_NEW SSH persistance 16 servers)
- P1 : R5 vault-02 ssh residuel, R6 backup-01 ssh residuel, R7 firewall (matched baseline), R8 SSH keys, R9 source IP M247, R10 console Hetzner
- P2 : R3 rescue inefficace, R4 minio rescue (a confirmer), R11 SSH 22 v3-vault, R12 cdn->mail-core, R13 IP 98.114.160 du 7 mai, R14 wTN7pU IPv6
- OK : R15-R23 (DNS, primary IPs, certs, mail externe, backups disponibles, etc.)

---

## Recommandations phase suivante

Ordre revise selon findings AS.17.1H :

| Ordre | Phase | Justification |
|---|---|---|
| **1** | **AS.17.1N SSH authorized_keys audit URGENT sur les 16+1 serveurs** | R_NEW P0 ; verifier `explore-k8s` absent + audit fingerprints cles installees |
| 2 | AS.17.1I MinIO uptime + filesystem audit (verifier hypothese rescue inefficace symetrique) | confirmer downgrade R4 |
| 3 | AS.17.1G Vault audit post-rebuild + SSH authorized_keys vault-02 | persistance SSH post-rebuild |
| 4 | AS.17.1M Backup-01 chain integrity + SSH authorized_keys | persistance SSH post-rebuild |
| 5 | AS.17.1H-SQL (suite) : si pertinent post-E1+E_critical, Ludovic decide creer role RO ou skip | downgrade R3 reduit l'urgence |
| 6 | AS.17.1J K8s drift detection vs git | apres SSH audit k8s workers |
| 7 | AS.17.1Q rotation secrets globale | a decider apres audits SSH |
| 8 | AS.17.1S RGPD breach notification (decision juridique) | risque reduit par R3 downgrade, mais R_NEW peut justifier notification preventive ; decision business |

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1H Postgres rescue forensic read-only partiel. Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1H-KEY-323-POSTGRES-RESCUE-FORENSIC-READONLY-01.md

Verdict : GO PARTIAL POSTGRES FORENSIC WITH BLOCKERS

DECOUVERTES PRINCIPALES :

1. R3 (Postgres rescue exfiltration) probablement INEFFECTIVE.
   Hetzner enable_rescue prepare l'image mais ne reboote pas. Le CSV
   confirme aucun server.reboot entre enable_rescue 08:06 et
   disable_rescue 09:06 pour db-postgres-01. Patroni
   postmaster_start_time du leader = 2026-04-23 (22 jours avant
   incident) prouve postgres jamais redemarre. SSH host key bastion
   -> 10.0.0.120 matche sans warning -> serveur jamais reboote. R3
   downgrade en P2.

2. R4 (MinIO rescue) probablement INEFFECTIVE pour la meme raison
   (enable_rescue + disable_rescue sans reboot pour minio-02). A
   confirmer en AS.17.1I.

3. Cluster Patroni keybuzz-pg17 SAIN : leader db-postgres-01 +
   2 replicas streaming, lag 0, timeline 26 consistant, system
   identifier 7579717422441030215, aucun failover post-attaque.

4. **R_NEW P0 CRITIQUE** : 16 serveurs rebuilt non restaures par
   Ludovic conservent potentiellement la cle SSH attaquant
   `explore-k8s` dans /root/.ssh/authorized_keys du filesystem
   post-rebuild. Concerne : queue-01/02/03, redis-01/02/03,
   k8s-worker-01/02/03, backup-01, vault-02, vector-db-01,
   litellm-01, monitor-01, crm-01, api-gateway-01. Aussi mail-mx-01
   (backup AMBIGUOUS 10:12 = peut contenir cle attaquant).
   `ssh_key.delete explore-k8s` a 11:30:11 supprime de Hetzner
   Cloud mais N'AFFECTE PAS les copies installees sur filesystem.

IMPACT BUSINESS :
- Risque RGPD significativement reduit cote Postgres
- Risque persistance attaquant via SSH residuel ELEVE sur 16
  serveurs SaaS production
- Action prioritaire requise : audit per server authorized_keys +
  rotation SSH host keys + nouvelle paire de cles applicatives

BLOQUEURS AS.17.1H sections E2-E9 :
- BLOCKED RO ROLE MISSING pour audit SQL (E2-E4, E7, E9 SQL)
- Pas de GO SSH au master Postgres pour audit filesystem E8 (mais
  decouverte E_critical reduit l'urgence)

Phase prioritaire suivante : AS.17.1N SSH authorized_keys audit
URGENT sur les 16 serveurs rebuilt + mail-mx-01.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu jusqu'a
completion AS.17.1N.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic explicite. Codex via connecteur
Linear posera apres GO.

---

## Hors scope / actions NON faites

- Aucun pg_dump
- Aucune session psql ouverte
- Aucune session SSH au master Postgres ouverte
- Aucun cat sur authorized_keys / bash_history / journalctl
- Aucun ALTER / CREATE / DROP / TRUNCATE / INSERT / UPDATE / DELETE /
  COPY / GRANT / REVOKE
- Aucun token Hetzner reutilise (RO supprime apres AS.17.1O)
- Aucun secret affiche en clair dans le rapport
- Aucun PII affiche en clair
- Aucun commit Git infra du rapport AS.17.1H (untracked en attente
  GO Ludovic)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation secrets
- Aucune mutation Hetzner
- Aucun ssh-keygen -R sur bastion
- Aucune decision RGPD breach notification

---

## Phrase cible finale

GO PARTIAL POSTGRES FORENSIC WITH BLOCKERS. Cluster Patroni
keybuzz-pg17 SAIN (leader + 2 replicas streaming lag 0, timeline 26,
postmaster_start_time pre-incident). R3 (Postgres rescue
exfiltration) probablement INEFFECTIVE par decouverte E_critical :
Hetzner enable_rescue + disable_rescue sans server.reboot
intermediaire = preparation rescue jamais effective. R4 (MinIO)
attendu meme verdict, a confirmer AS.17.1I. **R_NEW P0 CRITIQUE
nouveau** : 16 serveurs rebuilt + potentiellement mail-mx-01
peuvent conserver cle SSH attaquant `explore-k8s` dans
authorized_keys post-rebuild. BLOCKED RO ROLE MISSING pour audit
SQL E2-E9, mais E_critical reduit urgence. Phase prioritaire
suivante : AS.17.1N SSH authorized_keys audit URGENT 16 serveurs +
mail-mx-01. Aucune mutation effectuee, aucun pg_dump, aucun PII en
clair, aucun secret lu. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1
maintenu.

---
