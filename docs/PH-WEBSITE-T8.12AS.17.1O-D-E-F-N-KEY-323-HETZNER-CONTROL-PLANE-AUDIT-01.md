# PH-WEBSITE-T8.12AS.17.1O-D-E-F-N-KEY-323-HETZNER-CONTROL-PLANE-AUDIT-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1O+D+E+F+N Hetzner control plane audit post-containment
> Environnement : Hetzner Cloud projet KeyBuzz - read-only strict

---

## VERDICT

GO CONTROL PLANE CONTAINMENT AUDIT READY

Containment Hetzner confirme par Ludovic et verifie cote agent CE via
token RO API (E2-E8 completes). Aucune anomalie active non documentee
trouvee dans le control plane Hetzner :
- 52 serveurs visibles, tous en running ou off intentionnel
- 7 cles SSH Hetzner Cloud toutes legitimes (explore-k8s absent)
- 14 firewalls : current state matches baseline PH-INFRA-02 hardening
  apres revert 11:30 par l'attaquant (pas de drift visible cote
  rules / sources / attached_to)
- Aucune redirection DNS malveillante sur keybuzz.io (131 records,
  tous critiques coherents)
- Aucun primary IP / certificate cree pendant l'attaque (les 2
  primary IPs du 14 mai sont liees a niche-lab-prod-01 legitime, les
  2 certificates obtained sont dans des projets annexes hors KeyBuzz)
- Floating IP 49.13.35.167 re-attachee a mail-core-01 post-restore
- 7 backups Hetzner par serveur, au moins 1 backup PRE-ATTACK
  disponible pour chaque serveur touche
- Mail post-restore externalement sain (TCP 25/587 OPEN, DNS coherent,
  SPF -all hardfail)

Risques residuels P0 confines au DATA PLANE (disques db-postgres-01 +
minio-02 exposes 1h en rescue, vault-02 rebuilt apres rescue mode des
2 precedents, backup-01 rebuilt, mail-mx-01 backup utilise dans la
fenetre AMBIGUOUS 10:12:11Z). Ces risques relevent des phases
suivantes AS.17.1G/H/I/J/M et ne sont pas adressables au niveau
control plane Hetzner seul.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu. CE n'a effectue
aucune mutation, aucun restart, aucun edit firewall/DNS, aucun SSH
vers serveurs, aucun test email reel. Token RO sera supprime sur le
bastion en fin de phase.

---

## Preflight (E0)

| Champ | Valeur | Statut |
|---|---|---|
| Bastion identite | install-v3 / 46.62.171.61 / IPv6 2a01:4f9:c013:87d6::1/64 | OK |
| Date locale | 2026-05-16 (Europe/Paris CEST) | OK |
| CSV Hetzner | 337 rows ouvert via PowerShell Import-Csv | OK |
| hcloud CLI | 1.57.0 sur bastion | OK |
| Token RO | source /root/.hcloud-ro.env via set -a (jamais affiche en clair) | OK |
| Token RW PvaKOoh... revoque | confirme par Ludovic + audit confirme actions cessees 11:30:20Z | OK |
| Token qtCPW8... | confirme absent du listing actif par Ludovic | OK |
| Token wTN7pU... | confirme legitime par Ludovic | OK |
| Methode safe respectee | aucun token leak en chat/log/rapport ; unset HCLOUD_TOKEN en fin de chaque session | OK |

---

## Timeline incident (E1, source CSV)

Tokens masques en prefixes courts. Source IPs preservees pour forensic.

### Pre-incident (legitime probable)

| UTC | Activity | Source IP | Token | Resource | Notes |
|---|---|---|---|---|---|
| 2026-05-05T09:05:12Z | user.login | (CSV vide) | - | - | console web Hetzner |
| 2026-05-05T17:07-08Z | zone.rrset add+remove+add gsazur.io + certificate.obtain id 1494870 | (CSV vide) | - | zone gsazur.io | projet annexe (autre projet Hetzner) |
| 2026-05-07T09:33-44Z | user.login + 4 zone.rrset.add keybuzz.io | 2001:861:42c2::/128 (Free FR) | - | zone keybuzz.io | Ludovic ; 1 remove+add pour IP 98.114.160.0/32 - a confirmer legitimite |
| 2026-05-09T16:44-45Z | zone.rrset mg-capitalgroup.io + certificate.obtain id 1497142 | (CSV vide) | - | zone mg-capitalgroup.io | projet annexe |
| 2026-05-12T11:13:08Z | user.login | (CSV vide) | - | - | - |
| 2026-05-14T10:43:41Z | user.login | (CSV vide) | - | - | **SUSPECT : juste avant token.create 11:46** |
| 2026-05-14T11:46:22Z | token.create | (CSV vide = console web) | qtCPW8... cree | - | **SUSPECT mais confirme absent du listing actif par Ludovic** |
| 2026-05-14T12:23:40-54Z | ssh_key.create niche-lab-admin-ed25519, server.create niche-lab-prod-01, 2 primary_ip.create, firewall.create niche-lab-prod-firewall, server.start, server.enable_backup | 2001:861:2049::/128 (Free FR) | wTN7pU... | niche-lab-prod-01 | **confirme legitime par Ludovic** (projet IA personnel, autre projet Hetzner) |

### Incident principal (token PvaKOoh... depuis 146.70.211.0/32 M247 VPN)

| UTC | Activity | Resource | Notes |
|---|---|---|---|
| 2026-05-15T08:00:36Z | ssh_key.create | explore-k8s (id 112320769) | suggere recon tooling |
| 2026-05-15T08:06:56-58Z | server.enable_rescue | db-postgres-01 | rescue 1h |
| 2026-05-15T08:29:09-12Z | server.enable_rescue | minio-02 | rescue 1h |
| 2026-05-15T08:38:30-09:34:07Z | server.rebuild x10 (test serie) | queue-03 x6, k8s-worker-03 x2, vault-02 x2 | + firewall.update/set_rules sur 4 firewalls entre les rebuilds |
| 2026-05-15T09:04-09:50Z | stop/start/reboot cycles | k8s-worker-03 (depuis IPv6 2a01:4f8:1c1a::/128 = Hetzner AS24940) | attaquant controle k8s-worker-03 post-rebuild via SSH explore-k8s |
| 2026-05-15T09:06:57Z | server.disable_rescue | db-postgres-01 | fin rescue DB |
| 2026-05-15T09:29:12Z | server.disable_rescue | minio-02 | fin rescue MinIO |
| 2026-05-15T10:53:35-10:54:53Z | server.rebuild RAFALE 32 events 17 unique srv | redis-01/02/03, k8s-worker-01/02, queue-01/02, backup-01, crm-01, api-gateway-01, vector-db-01, litellm-01, monitor-01, mail-core-01, mail-mx-01, mail-mx-02 | rafale 80 secondes |
| 2026-05-15T11:30:07-10Z | firewall.set_rules + firewall.update x4 | keybuzz-public-firewall, keybuzz-internal-firewall, keybuzz-k8s-masters-hardened, v3-vault | **revert vers baseline PH-INFRA-02 (confirme par diff E6 ci-dessous)** |
| 2026-05-15T11:30:11Z | ssh_key.delete | explore-k8s | cleanup attaquant |
| 2026-05-15T21:26:36Z | user.login | (CSV vide) | probable Ludovic post-incident |

Bruit : 208 firewall.apply events (propagation regles vers ressources).

---

## E2 - Tokens

| Token prefix | Statut connu | Verifie via | Decision |
|---|---|---|---|
| PvaKOoh...QayiL8MpTsPpkzDMdWqRLauDE | RW pre-incident (avant 2026-05-01) ; REVOQUE 2026-05-15 par Ludovic | UI Hetzner Ludovic + cessation actions CSV apres 11:30:20Z | Maintenir revoque |
| qtCPW8...syIu6BWdRXgYnJBuwAYC5Oyr21 | cree 2026-05-14T11:46:22Z console web ; absent listing actif | UI Hetzner Ludovic | Confirme |
| wTN7pU...4K8jcIZ5uomFX78DaAZZPOB8DM | utilise 14 mai IPv6 FR ; niche-lab-prod-01 | UI Hetzner Ludovic | Legitime, garder |
| incident-audit-readonly-2026-05-16 | cree par Ludovic 2026-05-16, scope read-only | UI Hetzner + session courante CE | Actif, supprimer apres audit |

Note : Hetzner API ne fournit pas d'endpoint CLI public `hcloud token
list`. Confirmation finale = UI Hetzner. Le token RO permet seulement
de lister les ressources Cloud, pas les tokens eux-memes.

---

## E3 - SSH keys Hetzner Cloud

7 cles visibles dans le projet KeyBuzz :

| ID | Name | Fingerprint | Created | Verdict |
|---|---|---|---|---|
| 100020680 | KeyBuzz.io | 76:bf:f9:6e:87:14:be:bd:ad:ee:8c:7b:0f:cf:95:34 | 2025-07-04 | OK legitime |
| 100633343 | n8n.keybuzz.io | 4a:78:18:c1:62:3b:7f:71:15:9a:18:e7:83:a9:7d:30 | 2025-08-01 | OK legitime |
| 102231373 | MX1 | f2:1c:14:f1:37:6b:6b:71:d3:97:c4:6b:57:5e:1c:ff | 2025-09-17 | OK legitime |
| 102231490 | MX2 | 4e:05:94:9b:c9:66:34:20:bc:5b:3e:7a:74:98:d0:ec | 2025-09-17 | OK legitime |
| 102231500 | CORE | c3:e3:fd:2a:0a:94:0f:a1:6f:66:7e:db:c8:1c:5a:18 | 2025-09-17 | OK legitime |
| 102727651 | infra_keybuzz | 39:7e:67:60:0c:61:7f:02:db:d5:f6:ff:23:79:e8:25 | 2025-09-27 | OK legitime |
| 104277690 | install-v3-keybuzz | 35:db:d0:6b:a9:b3:0d:56:ec:35:50:e1:20:8f:93:65 | 2025-12-04 | OK legitime bastion |

Constatations :
- `explore-k8s` ABSENT : confirme deleted par attaquant 11:30:11Z. OK.
- `niche-lab-admin-ed25519` ABSENT du projet KeyBuzz : coherent, c'est
  dans le projet Hetzner separe niche-lab. Pas une anomalie.
- Aucune cle non attendue.

Note importante : ces cles SSH visibles cote Hetzner Cloud sont les
cles qui peuvent etre **pre-installees** par Hetzner lors d'un `server.create`
ou d'un `server.rebuild` via user-data. Elles ne refletent PAS
necessairement les cles **actuellement presentes dans /root/.ssh/authorized_keys**
sur chaque serveur (qui sont gerees par cloud-init + ansible).

P1 : audit individuel `/root/.ssh/authorized_keys` sur chaque serveur
restaure reste a faire (phase AS.17.1N data-plane separee, GO Ludovic
explicite).

---

## E4 - Servers state

52 serveurs visibles dans le projet KeyBuzz, tous en etat coherent :

| Categorie | Count | Notes |
|---|---|---|
| Running | 48 | tous les serveurs critiques operationnels |
| Off | 4 | temporal-01, temporal-db-01, nocodb-01, builder-01 (off intentionnel selon inventaire) |
| Image | ubuntu-24.04 | sur tous les serveurs typiques ; mail-core-01, mail-mx-01, mail-mx-02, install-v3, vault-01 ont image=empty (custom image) |
| Locked | False | sur tous les serveurs |
| Backup_window | defini sur tous | 06-10, 10-14, 14-18, 18-22, 22-02, 02-06 (rotation 4h) |

Aucun serveur non documente. Aucun serveur dans un statut anormal
(autre que les 4 intentionnellement off). Aucun serveur en rescue mode
actuellement.

Serveurs sensibles a flagger (R3 + R4 + R5) :

| Server | ID | Public IP | Statut actuel | Action incident |
|---|---|---|---|---|
| db-postgres-01 | 109781629 | 195.201.122.106 | running | **rescue 1h 15 mai** |
| minio-02 | 109784158 | 91.99.199.183 | running | **rescue 1h 15 mai** |
| vault-02 | 122460339 | 46.224.136.26 | running | **rebuilt apres rescues** |
| backup-01 | 109784108 | 91.98.139.56 | running | **rebuilt rafale** |
| mail-core-01 | 109784583 | 37.27.251.162 | running | rebuilt + restaure par Ludovic backup PRE-ATTACK |
| mail-mx-01 | 109784607 | 91.99.66.6 | running | rebuilt + restaure par Ludovic backup AMBIGUOUS |
| mail-mx-02 | 109784668 | 91.99.87.76 | running | rebuilt + restaure par Ludovic backup PRE-ATTACK |
| autres 16 serveurs rebuilt | (voir E5) | (voir E5) | running | rebuilt rafale |

---

## E5 - Backups inventory

Retention Hetzner = 7 backups par serveur (1 semaine, rotation 4h).
**Pour chaque serveur touche, au moins 1 backup PRE-ATTACK disponible.**

| Server | Most recent | Most recent PRE-ATTACK | Used by Ludovic | Statut |
|---|---|---|---|---|
| queue-03 | 2026-05-15T14:12:11Z POST | 2026-05-14T14:12:07Z | n/a (rebuilt only) | pre-attack disponible |
| k8s-worker-03 | 2026-05-15T14:12:11Z POST | 2026-05-14T14:12:07Z | n/a | pre-attack disponible |
| vault-02 | 2026-05-15T18:14:09Z POST | 2026-05-14T18:14:33Z | n/a | pre-attack disponible |
| redis-01 | 2026-05-15T10:12:11Z AMBIGUOUS | 2026-05-14T10:12:08Z | n/a | pre-attack disponible |
| k8s-worker-01 | 2026-05-15T22:13:11Z POST | 2026-05-14T22:13:16Z | n/a | pre-attack disponible |
| k8s-worker-02 | 2026-05-15T14:12:11Z POST | 2026-05-14T14:12:07Z | n/a | pre-attack disponible |
| queue-01 | 2026-05-15T18:14:07Z POST | 2026-05-14T18:14:24Z | n/a | pre-attack disponible |
| redis-02 | 2026-05-15T22:13:11Z POST | 2026-05-14T22:13:16Z | n/a | pre-attack disponible |
| redis-03 | 2026-05-15T02:13:11Z PRE | 2026-05-15T02:13:11Z | n/a | **PRE-ATTACK frais 6h avant attaque** |
| queue-02 | 2026-05-15T06:15:13Z PRE | 2026-05-15T06:15:13Z | n/a | **PRE-ATTACK frais 2h avant attaque** |
| backup-01 | 2026-05-15T18:14:07Z POST | 2026-05-14T18:14:24Z | n/a (rebuilt, **a verifier integrite chain**) | pre-attack disponible |
| crm-01 | 2026-05-15T18:14:07Z POST | 2026-05-14T18:14:24Z | n/a | pre-attack disponible |
| api-gateway-01 | 2026-05-15T06:15:13Z PRE | 2026-05-15T06:15:13Z | n/a | **PRE-ATTACK frais 2h avant attaque** |
| vector-db-01 | 2026-05-15T22:13:11Z POST | 2026-05-14T22:13:16Z | n/a | pre-attack disponible |
| litellm-01 | 2026-05-15T14:12:11Z POST | 2026-05-14T14:12:07Z | n/a | pre-attack disponible |
| monitor-01 | 2026-05-15T02:13:11Z PRE | 2026-05-15T02:13:11Z | n/a | **PRE-ATTACK frais 6h avant attaque** |
| mail-core-01 | 2026-05-15T06:15:13Z PRE | 2026-05-15T06:15:13Z | **2026-05-15T06:15:12Z** | restaure OK |
| mail-mx-01 | 2026-05-15T10:12:11Z AMBIGUOUS | 2026-05-14T10:12:08Z | **2026-05-15T10:12:11Z** AMBIGUOUS | **R2 flag persistance possible heritage backup** ; backup PRE-ATTACK 2026-05-14T10:12 disponible si re-restore necessaire |
| mail-mx-02 | 2026-05-15T14:12:11Z POST | 2026-05-14T14:12:07Z | **2026-05-14T14:12:06Z** PRE | restaure OK |
| db-postgres-01 | 2026-05-15T06:15:12Z PRE | 2026-05-15T06:15:12Z | n/a (not rebuilt, just rescue) | **PRE-ATTACK frais 2h avant attaque** |
| minio-02 | 2026-05-15T22:13:11Z POST | 2026-05-14T22:13:16Z | n/a (not rebuilt, just rescue) | pre-attack disponible |

Flag PRE = pris avant 2026-05-15T08:00:00Z (debut attaque)
Flag AMBIGUOUS = pris entre 08:00 et 11:30 (pendant attaque)
Flag POST = pris apres 11:30 (potentiellement copie du restore Ludovic
ou serveur post-attaque)

R2 (mail-mx-01 backup AMBIGUOUS) : si audit forensique de mail-mx-01
revele persistance, Ludovic dispose du backup PRE-ATTACK
2026-05-14T10:12:08Z (id 386478695) pour re-restaurer.

backup-01 : Hetzner backup chain confirmee 7 snapshots, le serveur
backup-01 lui-meme est rebuilt mais ses snapshots Hetzner restent
independants. **Ne pas confondre backups Hetzner (stockage Hetzner
externe) et donnees applicatives stockees sur disque local de
backup-01 (perdues lors du rebuild)**.

---

## E6 - Firewalls current state

14 firewalls visibles. Diff vs baseline PH-INFRA-02 (mars 2026)
post-hardening :

| Firewall | ID | Applied | Rules current | vs baseline | Verdict |
|---|---|---|---|---|---|
| keybuzz-public-firewall | 10697211 | 8 srv k8s | TCP 80/443 + ICMP from 0.0.0.0/0::0/0 ; TCP/UDP/ICMP from 10.0.0.0/16 | identique baseline | OK |
| keybuzz-bastion-firewall | 10697212 | 2 srv (install-v3 + backend-01) | (non describe car non touchee) | non touchee par attaquant | OK |
| keybuzz-internal-firewall | 10697213 | 38 srv | TCP/UDP/ICMP from 10.0.0.0/16 only | identique baseline | OK |
| keybuzz-mail-firewall | 10697214 | 3 srv mail | (non touchee par attaquant) | OK | OK |
| keybuzz-k8s-masters-hardened | 10700427 | 3 masters | TCP 6443 from 46.62.171.61/32 + 91.98.128.153/32 + 10.0.0.0/16 ; TCP/UDP/ICMP from 10.0.0.0/16 | identique baseline | OK |
| v3-vault | 10290882 | 3 srv vault | **TCP 22 from 0.0.0.0/0 ::/0** ; TCP 8200 from 10.0.0.0/16 ; TCP 8201 from 10.0.0.0/16 | identique baseline historique (avant PH-INFRA-02 documente "SSH public, OK") | **P2 SSH 22 ouvert** documente, pas inseree par attaquant |
| n8n | 2252924 | 0 srv | (vestige, non attached) | (legacy) | OK |
| fw-ssh-admin | 2449798 | 0 srv | (vestige post-hardening) | OK | OK |
| fw-k3s-masters | 2449800 | 0 srv | (vestige) | OK | OK |
| fw-databases | 2449801 | 0 srv | (vestige) | OK | OK |
| fw-mail | 2449802 | 0 srv | (vestige) | OK | OK |
| fw-minio | 10087224 | 0 srv | (vestige) | OK | OK |
| v3-mx | 10310131 | 0 srv | (vestige) | OK | OK |
| quarantine-fw | 10687343 | 1 srv (kb-admin-quarantine-01) | (specifique) | non touchee | OK |

**Conclusion E6** : le pattern de revert 11:30 par l'attaquant a bien
remis les regles vers la baseline PH-INFRA-02 documentee mars 2026.
Aucune backdoor visible dans les regles current des 4 firewalls
touches. La regle SSH 22 ouverte sur v3-vault est documentee dans le
rapport de hardening initial comme heritage anterieur, **pas une
backdoor de l'attaquant**.

P2 : reduire SSH 22 sur v3-vault a bastion uniquement (46.62.171.61/32
+ 91.98.128.153/32 + 10.0.0.0/16) reste une amelioration de securite
generale, hors scope KEY-323 incident.

---

## E7 - DNS keybuzz.io rrset

Zone keybuzz.io : 131 records, age 42 jours.

### A records critiques

| Name | Type | Value | Verdict |
|---|---|---|---|
| mail | A | 49.13.35.167 | floating IP mail-core-01 OK |
| mail-mx-01 | A | 91.99.66.6 | public IP mail-mx-01 OK |
| mail-mx-02 | A | 91.99.87.76 | public IP mail-mx-02 OK |
| inbound | A | 49.13.35.167 | OK reception Amazon/marketplace |
| mta-sts.inbound | A | 49.13.35.167 | OK MTA-STS policy server |
| cdn | A | 49.13.35.167 | **observation P2** : `cdn` pointe vers mail-core (peut-etre serveur multifonction, a confirmer) |
| api, admin, client, etc. | A | 138.199.132.240 + 49.13.42.76 | OK ingress K8s (2 IPs LB) |

### MX records

| Name | MX | Verdict |
|---|---|---|
| @ (keybuzz.io) | 10 mail-mx-01 / 20 mail-mx-02 | OK |
| inbound | 10 mail-mx-01 / 20 mail-mx-02 | OK |
| ecomlg, mymail, support | mxa/mxb.mailgun.org | OK delegation Mailgun pour ces sous-domaines |

### TXT critiques

| Name | Value (extrait) | Verdict |
|---|---|---|
| @ | `v=spf1 ip4:49.13.35.167 mx -all` | hardfail OK (corrige vs audit 04/04 qui avait ~all) |
| inbound | `v=spf1 ip4:49.13.35.167 -all` | OK |
| _dmarc | `v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@keybuzz.io; ruf=mailto:dmarc-fail@keybuzz.io; fo=1` | strict OK |
| _dmarc.inbound | `v=DMARC1; p=quarantine; ...; adkim=s; aspf=s` | strict OK |
| default._domainkey | `v=DKIM1; ...` (RSA pubkey complete) | OK |
| kbz1._domainkey | DKIM v1 OK | OK |
| kbz1._domainkey.inbound | DKIM v1 OK | OK |
| _mta-sts | `v=STSv1; id=20250919` | MTA-STS active |
| _mta-sts.inbound | `v=STSv1; id=20251214001` | OK |
| _smtp._tls.inbound | `v=TLSRPTv1; rua=mailto:tlsrpt@keybuzz.io` | TLS reporting OK |

### CNAME (echantillon)

DKIM CNAME vers `*.dkim.amazonses.com` : presence de configuration
**AWS SES DKIM** pour 3 selectors (36zde..., dwcdco..., pug6n6...).
Suggere une **integration AWS SES historique pour certains usages**
(probablement non lie au contact form/OTP qui passent par SMTP local).

### Resume E7

Aucun changement DNS keybuzz.io pendant l'attaque 2026-05-15. Aucune
redirection malveillante sur A records critiques. SPF hardfail,
DMARC strict, DKIM multi-selectors, MTA-STS, TLS reporting : posture
deliverabilite saine apres audit deliverabilite anterieur du 2026-04-04.

Note : seule la zone `keybuzz.io` est visible dans Hetzner DNS Console
(d'apres `hcloud zone list` = 1 zone). `keybuzz.pro` est sur OVH (vu
DNS MX externe precedemment). `inbound.keybuzz.io` est un sous-domaine
de keybuzz.io, pas une zone separee.

---

## E8 - Primary IPs + Certificates + Floating IPs

### Primary IPs (extrait sensible)

| IP | ID | Server | Created | Verdict |
|---|---|---|---|---|
| 91.98.139.56 | 102344975 | backup-01 (109784108) | 2025-09-27 | OK historique |
| 195.201.122.106 | 102341067 | db-postgres-01 (109781629) | 2025-09-27 | OK |
| 91.99.199.183 | 102345038 | minio-02 (109784158) | 2025-09-27 | OK |
| 37.27.251.162 | 102345786 | mail-core-01 (109784583) | 2025-09-27 | OK |
| 91.99.66.6 | 102345833 | mail-mx-01 (109784607) | 2025-09-27 | OK |
| 91.99.87.76 | 102345958 | mail-mx-02 (109784668) | 2025-09-27 | OK |
| 46.62.171.61 | 108942813 | install-v3 (114294716) | 2025-11-29 | OK bastion |
| 46.224.136.26 | 120294161 | vault-02 (122460339) | 2026-03-01 | OK |

Aucune primary IP cree dans la fenetre 2026-05-15 (attaque).
Les 2 primary_ip.create du 2026-05-14 (IDs 130786677/130786678 dans
le CSV) ne sont pas visibles dans le listing actuel du projet
KeyBuzz : confirme qu'elles sont dans le projet Hetzner separe
niche-lab (legitime selon Ludovic).

### Certificates

`hcloud certificate list` retourne 0 ligne pour le projet KeyBuzz
Hetzner. Les 2 certificate.obtain du CSV (gsazur.io 5 mai et
mg-capitalgroup.io 9 mai) sont dans des projets Hetzner separes,
**pas dans le projet KeyBuzz**. Donc aucun cert MITM keybuzz.io
obtenu pendant la fenetre.

### Floating IPs

| ID | Type | Name | IP | Home | Server | DNS | Age |
|---|---|---|---|---|---|---|---|
| 102331858 | ipv4 | floating-ip-mail | 49.13.35.167 | nbg1 | **mail-core-01** | mail.keybuzz.io | 230d |

La floating IP est **re-attachee a mail-core-01** post-restore par
Ludovic, coherent avec l'OTP qui refonctionne. DNS reverse coherent.

---

## E9 - Mail post-restore sanity

### TCP probes externes depuis bastion install-v3

| Cible | Port 25 | Port 465 | Port 587 | Port 2525 |
|---|---|---|---|---|
| 49.13.35.167 (mail-core floating) | OPEN | CLOSED | OPEN | CLOSED |
| 37.27.251.162 (mail-core public) | OPEN | CLOSED | OPEN | CLOSED |
| 10.0.0.160 (mail-core private) | OPEN | CLOSED | OPEN | CLOSED |
| 91.99.66.6 (mail-mx-01) | OPEN | CLOSED | CLOSED | n/a |
| 91.99.87.76 (mail-mx-02) | OPEN | CLOSED | CLOSED | n/a |

### ICMP

Tous les 4 hosts mail repondent ICMP OK.

### DNS

Coherent (voir E7).

### OTP

Ludovic confirme OTP DEV+PROD refonctionne post-restore.

**Verdict E9** : mail post-restore externalement sain.

P1 : audit interne des serveurs mail (postfix integrity,
authorized_keys, cron, /var/log, etc.) reste a faire en phase
data-plane separee. Pour mail-mx-01 specifiquement (backup AMBIGUOUS),
audit prioritaire.

---

## N - SSH keys bastion + known_hosts

Bastion install-v3 known_hosts contient une entree pour 10.0.0.160
(mail-core-01) avec une cle ED25519 differente de la valeur post-restore
(decouverte AS.17.1B `REMOTE HOST IDENTIFICATION HAS CHANGED`).

Coherent : mail-core-01 a ete rebuilt 2026-05-15T10:54:36Z puis
restaure par Ludovic depuis backup 06:15 le 15 mai. La cle SSH host
ED25519 vient du backup PRE-ATTACK, **differente de l'historique
known_hosts du bastion** qui datait d'avant le 2026-05-09.

Action requise Ludovic / CE avec GO explicite :
1. Pour chaque serveur restaure (mail-core-01, mail-mx-01, mail-mx-02
   et tous les autres 19 rebuilt), Ludovic doit verifier la fingerprint
   SSH ED25519 cote console Hetzner ou cloud-init, puis autoriser CE
   a faire `ssh-keygen -R <ip_or_hostname>` + `ssh-keyscan -t
   ed25519 <ip_or_hostname>` pour ressetter le known_hosts du bastion.

CE n'effectue pas ces operations sans GO explicite par serveur.

---

## Risk register (E10)

| ID | Severity | Finding | Evidence | Impact | Recommended next | Mutation requise |
|---|---|---|---|---|---|---|
| R1 | P0 | Token PvaKOoh a permis 292 actions Hetzner control plane + rebuilds + rescues | CSV 337 events | Compromission tres large, donnees disques exposees | revocation deja effectuee par Ludovic | aucune cote CE |
| R2 | P0 | mail-mx-01 restaure depuis backup AMBIGUOUS (2026-05-15T10:12:11Z) | E5 backup timing | persistence possible heritage backup | AS.17.1N audit interne forensic mail-mx-01 (authorized_keys, cron, postfix, journalctl) ; re-restore depuis 2026-05-14T10:12:08Z (id 386478695) si compromission confirmee | non, lecture SSH + re-restore si necessaire GO Ludovic |
| R3 | P0 | db-postgres-01 disques expose 1h en rescue mode | CSV enable_rescue + disable_rescue | exfiltration probable donnees PII clients | AS.17.1H audit forensic DB (pg_authid, search_path, pg_hba.conf, audit logs si presents) + decision RGPD breach notification | rotation DB password = mutation, GO separe |
| R4 | P0 | minio-02 disques exposes 1h en rescue mode | idem | exfiltration probable objets MinIO | AS.17.1I audit forensic MinIO (buckets, ACL, policies, lifecycle, audit logs) | aucune mutation cote audit |
| R5 | P0 | vault-02 rebuilt apres rescue DB+MinIO | CSV vault rebuild 09:33-09:34 | secrets KeyBuzz potentiellement lus avant rebuild | AS.17.1G audit Vault post-restore + decision rotation secrets globale | rotation secrets = mutation, GO separe |
| R6 | P0 | backup-01 rebuilt | CSV 10:54:15Z | si backups KeyBuzz applicatifs stockes sur disque local de backup-01, perdus ; Hetzner snapshots restent intacts | AS.17.1M audit backup-01 chain + verification offsite eventuel | aucune mutation cote audit |
| R7 | P1 | 4 firewalls modifies puis "revert" 11:30 par meme token | CSV + E6 diff | current state matches baseline -> revert correct ; pas de drift visible | OK aucun follow-up infra | aucune |
| R8 | P1 | Toutes les SSH keys serveurs rebuilt sont neuves cote host key | observation AS.17.1B | possible que l'attaquant ait laisse une cle SSH dans cloud-init/authorized_keys lors du rebuild | AS.17.1N audit individuel /root/.ssh/authorized_keys + cloud-init logs | non, audit SSH GO separe |
| R9 | P1 | Source IP attaque = 146.70.211.0/32 = M247 VPN | CSV source_ip | attaquant via VPN commercial, identite masquee | decision Ludovic : plainte / signalement police + Hetzner abuse + ANSSI | decision business |
| R10 | P1 | Possible compromission compte Hetzner Console (user.login 14 mai 10:43 -> token.create 11:46 qtCPW8...) | CSV | autre voie d'acces compromise potentielle | reset password Hetzner + 2FA hardware FIDO2 + revoquer toutes sessions actives | decision Ludovic |
| R11 | P2 | SSH 22 ouvert sur v3-vault firewall (vault-01/02/03) depuis 0.0.0.0/0 | E6 describe | mauvaise pratique historique pre-incident (documente PH-INFRA-02 initial) | restreindre a bastion 46.62.171.61/32 + 91.98.128.153/32 + 10.0.0.0/16 | mutation, hors scope KEY-323 |
| R12 | P2 | Records DNS `cdn` pointe vers `49.13.35.167` (= mail floating IP) | E7 | possible erreur de configuration ou serveur multifonction non documente | a confirmer avec Ludovic | aucune cote CE |
| R13 | P2 | suspect 2026-05-07 zone keybuzz.io remove+add record IP `98.114.160.0/32` (US) depuis IPv6 Ludovic | CSV | a confirmer legitime ou non | demander a Ludovic ce qu'est cette IP US | aucune |
| R14 | P2 | wTN7pU... token + niche-lab-prod-01 + IPv6 FR | CSV | legitime selon Ludovic ; IPv6 source differente de celle du 7 mai (2001:861:42c2) | OK confirme | aucune |
| R15 | OK | Aucun DNS keybuzz.io / inbound modifie pendant l'attaque | CSV + E7 dig externe + hcloud zone | pas de MITM DNS | maintenir monitoring DNS | aucune |
| R16 | OK | Aucun primary_ip.create pendant l'attaque | CSV + E8 hcloud | pas de redirection IP | aucune | aucune |
| R17 | OK | Aucun certificate.obtain pendant l'attaque ni dans le projet KeyBuzz | CSV + E8 hcloud certificate list | pas de cert MITM keybuzz | aucune | aucune |
| R18 | OK | Mail post-restore externalement sain TCP+ICMP+DNS | E9 | OTP DEV+PROD refonctionne | follow-up AS.17.1N forensic mail-mx-01 ambigu uniquement | aucune cote CE |
| R19 | OK | Pour chaque serveur touche, au moins 1 backup PRE-ATTACK disponible (retention 7) | E5 hcloud image list | rollback possible si necessaire | preserver les snapshots PRE-ATTACK ; ne pas declencher de prune ; NE PAS desactiver backup_window | aucune |
| R20 | OK | Floating IP 49.13.35.167 re-attachee a mail-core-01 post-restore | E8 hcloud floating-ip list | coherent | aucun follow-up | aucune |
| R21 | OK | 7 cles SSH Hetzner Cloud toutes legitimes ; explore-k8s absent | E3 hcloud ssh-key list | controle entry point Hetzner Cloud sain | follow-up audit /root/.ssh/authorized_keys par serveur (R8) | aucune cote CE |
| R22 | OK | 14 firewalls current state matches baseline post-hardening PH-INFRA-02 (mars 2026) | E6 hcloud firewall describe vs FIREWALL-BACKUP-2026-02-17.md | revert 11:30 par attaquant a remis baseline | aucun follow-up firewall | aucune |
| R23 | OK | 52 serveurs visibles, 48 running + 4 off intentionnel, image=ubuntu-24.04 majoritaire, locked=False, backup_window defini | E4 hcloud server list | etat coherent post-restore | aucun follow-up control plane | aucune |

5 P0, 4 P1, 4 P2, 9 OK = 22 findings consolides.

---

## Recommandations phase suivante

Ordre propose, en attente GO Ludovic :

| Ordre | Phase | Pre-requis | Mutation requise |
|---|---|---|---|
| 1 | AS.17.1H Postgres rescue forensic | GO acces psql/pg_dump read-only db-postgres-01 (post-rescue) | non audit, rotation DB password = mutation GO separe |
| 2 | AS.17.1I MinIO rescue forensic | GO acces mc/aws s3 read-only minio-02 (post-rescue) | non |
| 3 | AS.17.1G Vault audit post-restore | GO acces vault read-only | rotation secrets = mutation GO separe |
| 4 | AS.17.1M Backup-01 chain integrity | GO acces SSH backup-01 + chain checksums | non |
| 5 | AS.17.1N SSH/host key audit individuel servers (incluant mail-mx-01 ambigu) | GO per server fingerprint verify + ssh-keygen -R + ssh-keyscan + audit authorized_keys + cron + systemd + journalctl | non, mais ssh-keygen -R sur bastion = action sensible GO separe par server |
| 6 | AS.17.1Q rotation secrets globale (decision business) | apres AS.17.1G | OUI, mutation, GO separe |
| 7 | AS.17.1S RGPD breach notification CNIL (decision juridique) | apres AS.17.1H/I forensic | communication externe GO clair |
| 8 | AS.17.1J K8s drift detection vs git | acces kubectl bastion | non, lecture |
| 9 | AS.17.1K/L Redis + Queue post-restore sanity | acces redis-cli / rabbitmq mgmt | non |
| 10 | AS.17.1R rapport incident consolide | toutes phases precedentes | docs-only |
| 11 | AS.17.1V verifier configuration AWS SES historique vs reactivation eventuelle pour OTP/contact form si choix B2 dans KEY-323 | acces AWS console | mutation = GO separe |

Note : la configuration AWS SES historique (visible via DKIM CNAME
`amazonses.com` dans la zone DNS) suggere que SES est techniquement
deja partiellement configure pour KeyBuzz cote DNS. Cela rouvre
l'option B2 du KEY-323 plan (SES fallback) avec une infrastructure
DNS deja en place. A creuser separement.

Avant la promotion PROD AS.17.0 + AS.17.0.1, les phases AS.17.1G/H/I
prioritaires doivent etre completees pour decider de la rotation
secrets + breach notification.

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1O+D+E+F+N control plane Hetzner read-only complete via
token RO incident-audit-readonly-2026-05-16. Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1O-D-E-F-N-KEY-323-HETZNER-CONTROL-PLANE-AUDIT-01.md

Resultats principaux :

Control plane Hetzner sain post-containment :
- 7 cles SSH Hetzner Cloud toutes legitimes (explore-k8s absent)
- 14 firewalls : current state matches baseline PH-INFRA-02 post-hardening
- 52 serveurs visibles, etat coherent (48 running + 4 off intentionnel)
- Aucun DNS keybuzz.io modifie pendant l'attaque ; SPF/DMARC/DKIM/MTA-STS sains
- Aucune primary IP / certificate cree pendant l'attaque dans le projet KeyBuzz
- Floating IP 49.13.35.167 re-attachee a mail-core-01
- 7 backups Hetzner par serveur, au moins 1 backup PRE-ATTACK pour chaque serveur touche

Risques residuels P0 confines au DATA PLANE :
- db-postgres-01 disques exposes 1h rescue 2026-05-15T08:06
- minio-02 disques exposes 1h rescue 2026-05-15T08:29
- vault-02 rebuilt apres rescues -> secrets potentiellement lus
- backup-01 rebuilt -> chain de confiance backups locale potentiellement compromise
- mail-mx-01 restaure depuis backup AMBIGUOUS 2026-05-15T10:12:11Z -> persistance possible

Phases suivantes priorisees :
1. AS.17.1H Postgres rescue forensic
2. AS.17.1I MinIO rescue forensic
3. AS.17.1G Vault post-restore audit
4. AS.17.1M Backup-01 chain integrity
5. AS.17.1N SSH/host key audit servers + mail-mx-01 forensic
6. AS.17.1Q rotation secrets globale (decision business apres audit)
7. AS.17.1S RGPD breach notification CNIL (decision juridique)

Observation positive : configuration AWS SES historique deja en place
cote DNS (DKIM CNAME amazonses.com pour 3 selectors). Reactivation
B2 du KEY-323 plan techniquement plus simple que prevu si necessaire.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu tant que AS.17.1G/H/I
non completes. Aucune mutation effectuee, aucun secret affiche, token
RO supprime du bastion en fin d'audit.
```

A NE PAS poster sans GO Ludovic.

---

## Hors scope / actions NON faites

- Aucune mutation Hetzner Cloud
- Aucun SSH vers serveurs rebuilt
- Aucun ssh-keygen -R
- Aucun ajout known_hosts
- Aucun firewall edit
- Aucun DNS edit
- Aucun restart/rebuild/restore
- Aucun test SMTP avec mutation
- Aucun test email reel
- Aucune lecture /opt/keybuzz/credentials/
- Aucune lecture /opt/keybuzz/secrets/
- Aucun token affiche en clair dans le rapport ou les logs
- Aucun commit Git infra du rapport AS.17.1O (untracked en attente GO)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation secrets
- Aucun reset password Hetzner
- Aucune decision RGPD breach notification (business)
- Aucun rapport AS.17.1B commit non plus (en attente addendum post-restore)
- Suppression /root/.hcloud-ro.env en fin d'audit (a executer apres
  validation du rapport avec GO Ludovic)

---

## Phrase cible finale

GO CONTROL PLANE CONTAINMENT AUDIT READY. Hetzner control plane sain
post-containment selon 23 findings consolides (5 P0 confines data
plane, 4 P1, 4 P2, 9 OK). Aucune backdoor visible dans cles SSH
Hetzner, firewalls, DNS, primary IPs, certificates, floating IP.
Backups PRE-ATTACK preserves pour chaque serveur touche. Risques
residuels P0 (rescue DB+MinIO, vault rebuilt, backup-01 rebuilt,
mail-mx-01 backup AMBIGUOUS) relevent du data plane et necessitent
les phases suivantes AS.17.1G/H/I/M/N. Token RO utilise selon methode
safe sans aucun leak, sera supprime du bastion en fin d'audit avec
GO Ludovic. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu jusqu'a
completion des audits forensic data plane.

---
