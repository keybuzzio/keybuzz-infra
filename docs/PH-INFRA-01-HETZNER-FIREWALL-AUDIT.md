# PH-INFRA-01 — Hetzner Firewall Hardening Audit — RAPPORT

**Date** : 2026-03-14
**Mode** : AUDIT UNIQUEMENT — Aucune modification appliquee
**Cluster** : Kubernetes v1.30.14, 3 masters + 5 workers, Ubuntu 24.04

---

## 1. INVENTAIRE SERVEURS HETZNER (48 serveurs)

### Kubernetes Cluster

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| k8s-master-01 | 91.98.124.228 | 10.0.0.100 | Control plane |
| k8s-master-02 | 91.98.117.26 | 10.0.0.101 | Control plane |
| k8s-master-03 | 91.98.165.238 | 10.0.0.102 | Control plane |
| k8s-worker-01 | 116.203.135.192 | 10.0.0.110 | Worker general |
| k8s-worker-02 | 91.99.164.62 | 10.0.0.111 | Worker general |
| k8s-worker-03 | 157.90.119.183 | 10.0.0.112 | Worker heavy (IA) |
| k8s-worker-04 | 91.98.200.38 | 10.0.0.113 | Worker observability |
| k8s-worker-05 | 188.245.45.242 | 10.0.0.114 | Worker extra |

### Bases de donnees

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| db-postgres-01 | 195.201.122.106 | 10.0.0.120 | PostgreSQL 16 Patroni (leader) |
| db-postgres-02 | 91.98.169.31 | 10.0.0.121 | PostgreSQL 16 Patroni (replica) |
| db-postgres-03 | 65.21.251.198 | 10.0.0.122 | PostgreSQL 16 Patroni (replica) |
| maria-01 | 91.98.35.206 | 10.0.0.170 | MariaDB Galera |
| maria-02 | 46.224.43.75 | 10.0.0.171 | MariaDB Galera |
| maria-03 | 49.13.66.233 | 10.0.0.172 | MariaDB Galera |

### Redis

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| redis-01 | 49.12.231.193 | 10.0.0.123 | Redis HA master |
| redis-02 | 23.88.48.163 | 10.0.0.124 | Redis HA replica |
| redis-03 | 91.98.167.166 | 10.0.0.125 | Redis HA replica/sentinel |

### RabbitMQ

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| queue-01 | 23.88.105.16 | 10.0.0.126 | RabbitMQ quorum |
| queue-02 | 91.98.167.159 | 10.0.0.127 | RabbitMQ quorum |
| queue-03 | 91.98.68.35 | 10.0.0.128 | RabbitMQ quorum |

### Infrastructure

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| install-v3 | 46.62.171.61 | 10.0.0.251 | Bastion v3 (GitOps) |
| install-01 | 91.98.128.153 | 10.0.0.250 | Bastion legacy |
| haproxy-01 | 159.69.159.32 | 10.0.0.11 | HAProxy interne |
| haproxy-02 | 91.98.164.223 | 10.0.0.12 | HAProxy interne |
| vault-01 | 116.203.61.22 | 10.0.0.150 | Vault secrets |
| proxysql-01 | 46.224.64.206 | 10.0.0.173 | ProxySQL MariaDB |
| proxysql-02 | 188.245.194.27 | 10.0.0.174 | ProxySQL MariaDB |

### Stockage

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| minio-01 | 116.203.144.185 | 10.0.0.134 | MinIO S3 |
| minio-02 | 91.99.199.183 | 10.0.0.131 | MinIO S3 |
| minio-03 | 91.99.103.47 | 10.0.0.132 | MinIO S3 |
| backup-01 | 91.98.139.56 | 10.0.0.153 | Backup |

### Mail

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| mail-core-01 | 37.27.251.162 | 10.0.0.160 | Serveur mail (SMTP, IMAP) |
| mail-mx-01 | 91.99.66.6 | 10.0.0.161 | MX 1 |
| mail-mx-02 | 91.99.87.76 | 10.0.0.162 | MX 2 |

### Autres

| Serveur | IP Publique | IP Privee | Role |
|---|---|---|---|
| litellm-01 | 91.98.200.40 | 10.0.0.137 | Proxy LLM |
| qdrant-01 | 116.203.240.119 | 10.0.0.136 | Vector DB |
| ml-platform-01 | 157.90.236.10 | 10.0.0.143 | ML platform |
| siem-01 | 91.99.58.179 | 10.0.0.151 | SIEM |
| monitor-01 | 23.88.105.216 | 10.0.0.152 | Monitoring |
| builder-01 | 5.75.128.134 | 10.0.0.200 | CI/CD |
| api-gateway-01 | 23.88.107.251 | 10.0.0.135 | API Gateway |
| analytics-db | 91.98.134.176 | 10.0.0.130 | DB Analytics |
| analytics-01 | 91.99.237.167 | 10.0.0.139 | App Analytics |
| temporal-db | 88.99.227.128 | 10.0.0.129 | DB Temporal |
| temporal-01 | 91.98.197.70 | 10.0.0.138 | Temporal server |
| crm-01 | 78.47.43.10 | 10.0.0.133 | CRM |
| baserow-01 | 91.99.195.137 | 10.0.0.144 | Baserow |
| nocodb-01 | 78.46.170.170 | 10.0.0.142 | NocoDB |

---

## 2. ETAT FIREWALL ACTUEL

### Bastion (install-v3)
- **iptables INPUT policy** : **ACCEPT** (tout autorise par defaut)
- **UFW** : INACTIF
- **nftables** : Uniquement regles Docker NAT
- **Regles iptables manuelles** : DROP sur 8200, 8201 (Vault ports)

### CONSTAT CRITIQUE
**Aucun firewall Hetzner Cloud n'est configure.**
**Aucun pare-feu OS (UFW/iptables) n'est actif en mode deny-by-default.**
La politique INPUT est ACCEPT sur tous les serveurs audites.

---

## 3. PORTS OUVERTS — RESULTATS COMPLETS

### CRITIQUE : Services internes exposes sur Internet

| Serveur | Port | Service | Risque |
|---|---|---|---|
| db-postgres-01 | **5432** | PostgreSQL | **CRITIQUE** — Base de donnees exposee sur Internet |
| db-postgres-03 | **5432** | PostgreSQL | **CRITIQUE** — Base de donnees exposee sur Internet |
| redis-01 | **6379** | Redis | **CRITIQUE** — Cache/sessions expose sans auth par defaut |
| redis-02 | **6379** | Redis | **CRITIQUE** — Cache/sessions expose sans auth par defaut |
| redis-03 | **6379** | Redis | **CRITIQUE** — Cache/sessions expose sans auth par defaut |
| queue-01 | **5672** | RabbitMQ AMQP | **CRITIQUE** — Queue de messages exposee |
| queue-01 | **15672** | RabbitMQ Management | **ELEVE** — Console admin exposee |
| queue-02 | **5672** | RabbitMQ AMQP | **CRITIQUE** — Queue de messages exposee |
| queue-02 | **15672** | RabbitMQ Management | **ELEVE** — Console admin exposee |
| queue-03 | **5672** | RabbitMQ AMQP | **CRITIQUE** — Queue de messages exposee |
| queue-03 | **15672** | RabbitMQ Management | **ELEVE** — Console admin exposee |

### ELEVE : Ports Kubernetes exposes

| Serveur | Port | Service | Risque |
|---|---|---|---|
| k8s-master-01 | **6443** | K8s API Server | **ELEVE** — API K8s exposee sur Internet |
| k8s-master-02 | **6443** | K8s API Server | **ELEVE** — API K8s exposee sur Internet |
| k8s-master-03 | **6443** | K8s API Server | **ELEVE** — API K8s exposee sur Internet |
| k8s-master-02 | **2379** | etcd client | **CRITIQUE** — etcd expose sur Internet |
| k8s-master-02 | **2380** | etcd peer | **CRITIQUE** — etcd peer expose sur Internet |
| k8s-master-03 | **2379** | etcd client | **CRITIQUE** — etcd expose sur Internet |
| k8s-master-03 | **2380** | etcd peer | **CRITIQUE** — etcd expose sur Internet |
| masters (x3) | **10250** | Kubelet | **ELEVE** — Kubelet expose |

### ATTENDU : Ports legitimement ouverts

| Serveur | Port | Service | Commentaire |
|---|---|---|---|
| Workers (x5) + Masters (x3) | 80, 443 | HTTP/HTTPS (Ingress) | OK — necessaire pour le trafic web |
| Tous serveurs | 22 | SSH | A restreindre aux IPs admin |
| mail-core-01 | 25, 587, 80, 443 | SMTP + web | OK — serveur mail |
| mail-mx-01, mail-mx-02 | 25 | SMTP | OK — MX records |

### Serveurs correctement fermes (SSH uniquement)

install-v3, install-01, vault-01, haproxy-01, haproxy-02, minio-01, minio-02, minio-03, qdrant-01, ml-platform-01, siem-01, monitor-01 = **SSH uniquement**

litellm-01, builder-01, api-gateway-01 = **Aucun port ouvert** (SSH potentiellement sur interface privee uniquement)

---

## 4. KUBERNETES — SERVICES EXPOSES

### Ingress Controller
- Type : **NodePort** (pas LoadBalancer)
- Ports : 80:31169, 443:31631
- Tous les masters et workers exposent ces NodePorts

### 15 Ingress configures

| Host | Namespace | Service |
|---|---|---|
| client.keybuzz.io | keybuzz-client-prod | keybuzz-client |
| client-dev.keybuzz.io | keybuzz-client-dev | keybuzz-client |
| admin.keybuzz.io | keybuzz-admin-v2-prod | keybuzz-admin-v2 |
| admin-dev.keybuzz.io | keybuzz-admin-v2-dev | keybuzz-admin-v2 |
| api.keybuzz.io | keybuzz-api-prod | keybuzz-api |
| api-dev.keybuzz.io | keybuzz-api-dev | keybuzz-api |
| backend.keybuzz.io | keybuzz-backend-prod | keybuzz-backend |
| backend-dev.keybuzz.io | keybuzz-backend-dev | keybuzz-backend |
| platform-api.keybuzz.io | keybuzz-api | keybuzz-backend-api |
| llm.keybuzz.io | keybuzz-ai | litellm |
| seller-dev.keybuzz.io | keybuzz-seller-dev | seller-client |
| seller-api-dev.keybuzz.io | keybuzz-seller-dev | seller-api |
| www.keybuzz.pro / keybuzz.pro | keybuzz-website-prod | keybuzz-website |
| preview.keybuzz.pro | keybuzz-website-dev | keybuzz-website-preview |
| grafana-dev.keybuzz.io | observability | kube-prometheus-grafana |

### Services internes Kubernetes (ClusterIP — OK)
Tous les services applicatifs (API, client, backend, admin) sont en ClusterIP. Aucun service applicatif n'est directement expose en NodePort ou LoadBalancer.

### Points d'attention
- **llm.keybuzz.io** : LiteLLM proxy expose publiquement via Ingress
- **grafana-dev.keybuzz.io** : Dashboard monitoring expose publiquement
- **platform-api.keybuzz.io** : API backend exposee (nouveau, 2 jours)

---

## 5. ANALYSE DE RISQUE

### Risques CRITIQUES (action immediate requise)

| # | Risque | Impact | Serveurs |
|---|---|---|---|
| R1 | **PostgreSQL expose sur Internet (5432)** | Acces direct a la base de donnees. Brute force possible. | db-postgres-01, db-postgres-03 |
| R2 | **Redis expose sur Internet (6379)** | Acces aux sessions, cache, donnees sensibles. Redis souvent sans auth. | redis-01, redis-02, redis-03 |
| R3 | **RabbitMQ expose sur Internet (5672)** | Injection de messages, exfiltration de donnees. | queue-01, queue-02, queue-03 |
| R4 | **etcd expose sur Internet (2379/2380)** | Acces complet au state Kubernetes. Compromission totale du cluster. | k8s-master-02, k8s-master-03 |
| R5 | **RabbitMQ Management expose (15672)** | Console admin avec credentials par defaut possibles. | queue-01, queue-02, queue-03 |

### Risques ELEVES

| # | Risque | Impact | Serveurs |
|---|---|---|---|
| R6 | **K8s API expose sur Internet (6443)** | Si credentials fuites, controle total du cluster. | Tous masters |
| R7 | **Kubelet expose (10250)** | Execution de commandes sur les nodes. | Tous masters |
| R8 | **SSH ouvert sur 0.0.0.0/0 (22)** | Brute force SSH sur tous les serveurs. | 35+ serveurs |
| R9 | **Aucun firewall deny-by-default** | Tout nouveau service demarre sera automatiquement expose. | Tous |
| R10 | **LiteLLM expose publiquement** | Proxy IA potentiellement exploitable (couts, abus). | Via Ingress |
| R11 | **Grafana expose publiquement** | Dashboards monitoring visibles si auth faible. | Via Ingress |

### Risques MODERES

| # | Risque | Impact |
|---|---|---|
| R12 | NodePorts 31169/31631 sur tous les nodes | Trafic web peut atteindre n'importe quel node |
| R13 | Pas de network policies K8s | Communication inter-namespaces non restreinte |

---

## 6. PLAN DE HARDENING PROPOSE

### Phase H1 — Urgence (Semaine 1)

**Objectif** : Fermer les services internes exposes sur Internet.

| Action | Serveurs | Ports | Methode |
|---|---|---|---|
| Bloquer PostgreSQL depuis Internet | db-postgres-01, 03 | 5432 | iptables/ufw : DROP sauf 10.0.0.0/24 |
| Bloquer Redis depuis Internet | redis-01, 02, 03 | 6379 | iptables/ufw : DROP sauf 10.0.0.0/24 |
| Bloquer RabbitMQ AMQP depuis Internet | queue-01, 02, 03 | 5672 | iptables/ufw : DROP sauf 10.0.0.0/24 |
| Bloquer RabbitMQ Management depuis Internet | queue-01, 02, 03 | 15672 | iptables/ufw : DROP sauf 10.0.0.0/24 |
| Bloquer etcd depuis Internet | k8s-master-02, 03 | 2379, 2380 | iptables/ufw : DROP sauf 10.0.0.0/24 |

**Risque de cette phase** : FAIBLE. Les services internes communiquent via le reseau prive (10.0.0.x). Le blocage sur l'interface publique n'affectera pas le fonctionnement.

**Verification** : Tester la connectivite interne (10.0.0.x) apres chaque changement.

### Phase H2 — SSH Hardening (Semaine 2)

| Action | Serveurs | Methode |
|---|---|---|
| Restreindre SSH aux IPs admin | Tous | ufw allow from {IP_ADMIN} to any port 22 |
| Activer fail2ban | Tous | apt install fail2ban |
| Desactiver auth par mot de passe | Tous | sshd_config: PasswordAuthentication no |

**IPs admin a autoriser** :
- IP du bastion install-v3 (46.62.171.61)
- IP du bastion install-01 (91.98.128.153)
- IP fixe admin (a definir)

### Phase H3 — Kubernetes API (Semaine 2-3)

| Action | Serveurs | Methode |
|---|---|---|
| Restreindre 6443 au bastion + reseau interne | Masters | iptables/ufw : 6443 uniquement depuis 10.0.0.0/24 + bastion |
| Restreindre 10250 au reseau interne | Masters | iptables/ufw : 10250 uniquement depuis 10.0.0.0/24 |

### Phase H4 — Ingress Hardening (Semaine 3-4)

| Action | Methode |
|---|---|
| Ajouter auth sur grafana-dev.keybuzz.io | Ingress annotation ou auth middleware |
| Ajouter auth sur llm.keybuzz.io | IP whitelist ou basic auth |
| Evaluer suppression platform-api.keybuzz.io | Si non utilise, supprimer l'Ingress |

### Phase H5 — Firewall Cloud Hetzner (Semaine 4+)

| Action | Methode |
|---|---|
| Creer firewall Hetzner Cloud "deny-by-default" | hcloud firewall create |
| Autoriser SSH depuis IPs admin uniquement | hcloud firewall add-rule |
| Autoriser 80/443 sur workers + masters | hcloud firewall add-rule |
| Autoriser reseau prive entre nodes | hcloud firewall add-rule |
| Attacher firewall a tous les serveurs | hcloud firewall apply-to-server |

### Phase H6 — Network Policies Kubernetes

| Action | Methode |
|---|---|
| Installer Calico ou Cilium (si pas deja) | CNI plugin |
| Creer NetworkPolicies par namespace | Deny all ingress, allow explicit |
| Isoler les namespaces sensibles | keybuzz-ai, observability |

---

## 7. RESUME EXECUTIF

| Categorie | Etat | Priorite |
|---|---|---|
| **PostgreSQL expose** | 2/3 serveurs, port 5432 | CRITIQUE — Semaine 1 |
| **Redis expose** | 3/3 serveurs, port 6379 | CRITIQUE — Semaine 1 |
| **RabbitMQ expose** | 3/3 serveurs, ports 5672 + 15672 | CRITIQUE — Semaine 1 |
| **etcd expose** | 2/3 masters, ports 2379 + 2380 | CRITIQUE — Semaine 1 |
| **K8s API expose** | 3/3 masters, port 6443 | ELEVE — Semaine 2 |
| **Kubelet expose** | 3 masters, port 10250 | ELEVE — Semaine 2 |
| **SSH sans restriction IP** | 35+ serveurs | ELEVE — Semaine 2 |
| **Firewall policy ACCEPT** | Tous serveurs | ELEVE — Semaine 4 |
| **LiteLLM / Grafana publics** | Via Ingress | MODERE — Semaine 3 |

**Score de securite reseau actuel** : 2/10

**Score apres Phase H1** : 5/10

**Score apres Phases H1-H5** : 8/10

---

## 8. AUCUNE MODIFICATION APPLIQUEE

Ce rapport est un **audit uniquement**. Aucun port n'a ete ferme, aucune regle firewall n'a ete modifiee, aucun service n'a ete interrompu.

Toutes les actions proposees doivent etre validees avant execution.
