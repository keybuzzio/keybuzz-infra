# Backup Firewalls Hetzner Cloud - 17 fevrier 2026

> **SAUVEGARDE AVANT MODIFICATIONS**
> Ce fichier contient la configuration EXACTE des firewalls Hetzner Cloud
> au moment de l'audit du 17 fevrier 2026.
> En cas de probleme, recreer les firewalls avec ces regles exactes.
> Date/heure: 2026-02-17 ~23:30 UTC

---

## 1. FIREWALL "fw-ssh-admin" (ID: 2449798)

**Applique a: TOUS les 47 serveurs**

### Regles INBOUND:
| Protocole | Port   | Source       | Description |
|-----------|--------|--------------|-------------|
| TCP       | 22     | 0.0.0.0/0, ::/0 | SSH |
| TCP       | 80     | 0.0.0.0/0, ::/0 | HTTP |
| TCP       | 443    | 0.0.0.0/0, ::/0 | HTTPS |
| TCP       | 26270  | 0.0.0.0/0, ::/0 | Custom SSH |
| ICMP      | -      | 0.0.0.0/0, ::/0 | Ping |

### Regles OUTBOUND:
AUCUNE (= tout le trafic sortant est autorise)

### Serveurs associes (47):
```
109780472  k8s-master-01      91.98.124.228
109781629  db-postgres-01     195.201.122.106
109781695  redis-01           49.12.231.193
109782191  k8s-worker-01      116.203.135.192
109783469  k8s-master-02      91.98.117.26
109783574  k8s-master-03      91.98.165.238
109783643  k8s-worker-02      91.99.164.62
109783713  queue-01           23.88.105.16
109783838  db-postgres-02     91.98.169.31
109784003  redis-02           23.88.48.163
109784037  redis-03           91.98.167.166
109784070  queue-02           91.98.167.159
109784080  queue-03           91.98.68.35
109784108  backup-01          91.98.139.56
109784158  minio-02           91.99.199.183
109784173  crm-01             78.47.43.10
109784201  api-gateway-01     23.88.107.251
109784364  vector-db-01       116.203.240.119
109784396  litellm-01         91.98.200.40
109784414  minio-01           116.203.144.185
109784447  monitor-01         23.88.105.216
109784494  k8s-worker-03      157.90.119.183
109784583  mail-core-01       37.27.251.162
109784816  temporal-01        91.98.197.70
109784838  temporal-db-01     88.99.227.128
109784894  analytics-01       91.99.237.167
109784916  analytics-db-01    91.98.134.176
109784945  etl-01             195.201.225.134
109784981  ml-platform-01     157.90.236.10
109785006  k8s-worker-04      91.98.200.38
109883784  vault-01           116.203.61.22
109883991  siem-01            91.99.58.179
109884364  nocodb-01          78.46.170.170
109884423  minio-03           91.99.103.47
109884534  k8s-worker-05      188.245.45.242
109884801  db-postgres-03     65.21.251.198
109885044  builder-01         5.75.128.134
110030455  backend-01         91.98.128.153
110171270  haproxy-01         159.69.159.32
110171338  haproxy-02         91.98.164.223
110237162  baserow-01         91.99.195.137
112572478  maria-02           46.224.43.75
112572479  maria-03           49.13.66.233
112572480  proxysql-01        46.224.64.206
112572481  proxysql-02        188.245.194.27
112572482  maria-01           91.98.35.206
114294716  install-v3         46.62.171.61
```

---

## 2. FIREWALL "fw-k3s-masters" (ID: 2449800)

**Applique a: 3 masters K8s**

### Regles INBOUND:
| Protocole | Port      | Source       | Description |
|-----------|-----------|--------------|-------------|
| TCP       | 6443      | 0.0.0.0/0, ::/0 | K8s API Server |
| TCP       | 2379-2380 | 0.0.0.0/0, ::/0 | etcd |
| TCP       | 10250     | 0.0.0.0/0, ::/0 | kubelet |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (3):
```
109780472  k8s-master-01  91.98.124.228
109783469  k8s-master-02  91.98.117.26
109783574  k8s-master-03  91.98.165.238
```

---

## 3. FIREWALL "fw-databases" (ID: 2449801)

**Applique a: 8 serveurs DB/Redis/Queue**

### Regles INBOUND:
| Protocole | Port  | Source       | Description |
|-----------|-------|--------------|-------------|
| TCP       | 5432  | 0.0.0.0/0, ::/0 | PostgreSQL |
| TCP       | 6379  | 0.0.0.0/0, ::/0 | Redis |
| TCP       | 26379 | 0.0.0.0/0, ::/0 | Redis Sentinel |
| TCP       | 5672  | 0.0.0.0/0, ::/0 | RabbitMQ AMQP |
| TCP       | 15672 | 0.0.0.0/0, ::/0 | RabbitMQ Management |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (8):
```
109781629  db-postgres-01  195.201.122.106
109781695  redis-01        49.12.231.193
109783713  queue-01        23.88.105.16
109784003  redis-02        23.88.48.163
109784037  redis-03        91.98.167.166
109784070  queue-02        91.98.167.159
109784080  queue-03        91.98.68.35
109884801  db-postgres-03  65.21.251.198
```

**ATTENTION: db-postgres-02 (109783838) N'EST PAS dans ce firewall !**

---

## 4. FIREWALL "fw-mail" (ID: 2449802)

**Applique a: 1 serveur**

### Regles INBOUND:
| Protocole | Port | Source       | Description |
|-----------|------|--------------|-------------|
| TCP       | 25   | 0.0.0.0/0, ::/0 | SMTP |
| TCP       | 80   | 0.0.0.0/0, ::/0 | HTTP |
| TCP       | 443  | 0.0.0.0/0, ::/0 | HTTPS |
| TCP       | 587  | 0.0.0.0/0, ::/0 | SMTP submission |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (1):
```
109784583  mail-core-01  37.27.251.162
```

---

## 5. FIREWALL "fw-minio" (ID: 10087224)

**Applique a: 1 serveur**

### Regles INBOUND:
| Protocole | Port     | Source       | Description |
|-----------|----------|--------------|-------------|
| TCP       | 9001     | 0.0.0.0/0, ::/0 | MinIO Console |
| TCP       | 443-9001 | 0.0.0.0/0, ::/0 | Large range TCP |
| ICMP      | -        | 0.0.0.0/0, ::/0 | Ping |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (1):
```
109784414  minio-01  116.203.144.185
```

---

## 6. FIREWALL "v3-vault" (ID: 10290882)

**Applique a: 1 serveur**

### Regles INBOUND:
| Protocole | Port | Source       | Description |
|-----------|------|--------------|-------------|
| TCP       | 80   | 0.0.0.0/0, ::/0 | HTTP |
| TCP       | 443  | 0.0.0.0/0, ::/0 | HTTPS |
| TCP       | 8200 | 0.0.0.0/0, ::/0 | Vault API |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (1):
```
109883784  vault-01  116.203.61.22
```

---

## 7. FIREWALL "v3-mx" (ID: 10310131)

**Applique a: 2 serveurs**

### Regles INBOUND:
| Protocole | Port | Source       | Description |
|-----------|------|--------------|-------------|
| TCP       | 25   | 0.0.0.0/0, ::/0 | SMTP |
| TCP       | 80   | 0.0.0.0/0, ::/0 | HTTP |
| TCP       | 443  | 0.0.0.0/0, ::/0 | HTTPS |
| TCP       | 587  | 0.0.0.0/0, ::/0 | SMTP submission |

### Regles OUTBOUND:
AUCUNE

### Serveurs associes (2):
```
109784607  mail-mx-01  91.99.66.6
109784668  mail-mx-02  91.99.87.76
```

---

## 8. FIREWALL "n8n" (ID: 2252924)

**NON APPLIQUE a aucun serveur (0 serveurs)**

### Regles INBOUND:
| Protocole | Port  | Source       | Description |
|-----------|-------|--------------|-------------|
| TCP       | 22    | 0.0.0.0/0, ::/0 | SSH |
| TCP       | 80    | 0.0.0.0/0, ::/0 | HTTP |
| TCP       | 443   | 0.0.0.0/0, ::/0 | HTTPS |
| TCP       | 2222  | 0.0.0.0/0, ::/0 | Alt SSH |
| TCP       | 5678  | 0.0.0.0/0, ::/0 | n8n |
| TCP       | 8080  | 0.0.0.0/0, ::/0 | HTTP alt |
| TCP       | 26000 | 0.0.0.0/0, ::/0 | Custom |
| ICMP      | -     | 0.0.0.0/0, ::/0 | Ping |

### Regles OUTBOUND:
AUCUNE

---

## LOAD BALANCERS (pour reference)

Tous les LBs utilisent `use_private_ip: true` (trafic via reseau prive 10.0.0.x).

| Nom | IP publique | IP privee | Services | Targets |
|-----|-------------|-----------|----------|---------|
| lb-keybuzz-1 | 49.13.42.76 | 10.0.0.5 | TCP 80, 443, 6443 | 3 masters + 5 workers |
| lb-keybuzz-2 | 138.199.132.240 | 10.0.0.6 | TCP 80, 443, 6443 | 3 masters + 5 workers |
| lb-haproxy | 49.13.46.190 | 10.0.0.10 | TCP 5432, 5672, 6379, 8404, 9000, 9001 | haproxy-01, haproxy-02 |
| lb-proxysql | 128.140.26.199 | 10.0.0.20 | TCP 3306->6033 | proxysql-01, proxysql-02 |

---

## MAPPING COMPLET SERVEUR → FIREWALLS

| ID | Serveur | IP publique | Status | Firewalls |
|----|---------|-------------|--------|-----------|
| 109780472 | k8s-master-01 | 91.98.124.228 | running | fw-ssh-admin, fw-k3s-masters |
| 109781629 | db-postgres-01 | 195.201.122.106 | running | fw-ssh-admin, fw-databases |
| 109781695 | redis-01 | 49.12.231.193 | running | fw-ssh-admin, fw-databases |
| 109782191 | k8s-worker-01 | 116.203.135.192 | running | fw-ssh-admin |
| 109783469 | k8s-master-02 | 91.98.117.26 | running | fw-ssh-admin, fw-k3s-masters |
| 109783574 | k8s-master-03 | 91.98.165.238 | running | fw-ssh-admin, fw-k3s-masters |
| 109783643 | k8s-worker-02 | 91.99.164.62 | running | fw-ssh-admin |
| 109783713 | queue-01 | 23.88.105.16 | running | fw-ssh-admin, fw-databases |
| 109783838 | db-postgres-02 | 91.98.169.31 | running | fw-ssh-admin **(MANQUE fw-databases!)** |
| 109784003 | redis-02 | 23.88.48.163 | running | fw-ssh-admin, fw-databases |
| 109784037 | redis-03 | 91.98.167.166 | running | fw-ssh-admin, fw-databases |
| 109784070 | queue-02 | 91.98.167.159 | running | fw-ssh-admin, fw-databases |
| 109784080 | queue-03 | 91.98.68.35 | running | fw-ssh-admin, fw-databases |
| 109784108 | backup-01 | 91.98.139.56 | running | fw-ssh-admin |
| 109784158 | minio-02 | 91.99.199.183 | running | fw-ssh-admin |
| 109784173 | crm-01 | 78.47.43.10 | running | fw-ssh-admin |
| 109784201 | api-gateway-01 | 23.88.107.251 | **off** | fw-ssh-admin |
| 109784364 | vector-db-01 | 116.203.240.119 | running | fw-ssh-admin |
| 109784396 | litellm-01 | 91.98.200.40 | **off** | fw-ssh-admin |
| 109784414 | minio-01 | 116.203.144.185 | running | fw-ssh-admin, fw-minio |
| 109784447 | monitor-01 | 23.88.105.216 | running | fw-ssh-admin |
| 109784494 | k8s-worker-03 | 157.90.119.183 | running | fw-ssh-admin |
| 109784583 | mail-core-01 | 37.27.251.162 | running | fw-ssh-admin, fw-mail |
| 109784607 | mail-mx-01 | 91.99.66.6 | running | v3-mx |
| 109784668 | mail-mx-02 | 91.99.87.76 | running | v3-mx |
| 109784816 | temporal-01 | 91.98.197.70 | **off** | fw-ssh-admin |
| 109784838 | temporal-db-01 | 88.99.227.128 | **off** | fw-ssh-admin |
| 109784894 | analytics-01 | 91.99.237.167 | running | fw-ssh-admin |
| 109784916 | analytics-db-01 | 91.98.134.176 | running | fw-ssh-admin |
| 109784945 | etl-01 | 195.201.225.134 | running | fw-ssh-admin |
| 109784981 | ml-platform-01 | 157.90.236.10 | running | fw-ssh-admin |
| 109785006 | k8s-worker-04 | 91.98.200.38 | running | fw-ssh-admin |
| 109883784 | vault-01 | 116.203.61.22 | running | fw-ssh-admin, v3-vault |
| 109883991 | siem-01 | 91.99.58.179 | running | fw-ssh-admin |
| 109884364 | nocodb-01 | 78.46.170.170 | **off** | fw-ssh-admin |
| 109884423 | minio-03 | 91.99.103.47 | running | fw-ssh-admin |
| 109884534 | k8s-worker-05 | 188.245.45.242 | running | fw-ssh-admin |
| 109884801 | db-postgres-03 | 65.21.251.198 | running | fw-ssh-admin, fw-databases |
| 109885044 | builder-01 | 5.75.128.134 | **off** | fw-ssh-admin |
| 110030455 | backend-01 | 91.98.128.153 | running | fw-ssh-admin |
| 110171270 | haproxy-01 | 159.69.159.32 | running | fw-ssh-admin |
| 110171338 | haproxy-02 | 91.98.164.223 | running | fw-ssh-admin |
| 110237162 | baserow-01 | 91.99.195.137 | running | fw-ssh-admin |
| 112572478 | maria-02 | 46.224.43.75 | running | fw-ssh-admin |
| 112572479 | maria-03 | 49.13.66.233 | running | fw-ssh-admin |
| 112572480 | proxysql-01 | 46.224.64.206 | running | fw-ssh-admin |
| 112572481 | proxysql-02 | 188.245.194.27 | running | fw-ssh-admin |
| 112572482 | maria-01 | 91.98.35.206 | running | fw-ssh-admin |
| 114294716 | install-v3 | 46.62.171.61 | running | fw-ssh-admin |

---

## PROCEDURE DE RESTAURATION EN CAS DE PERTE D'ACCES

### Si tu perds l'acces SSH apres modification du firewall:

**Option 1: Console Hetzner Cloud (https://console.hetzner.cloud)**
1. Aller dans le projet
2. Cliquer sur le serveur concerne
3. Onglet "Firewalls" → supprimer le firewall ou modifier les regles
4. L'acces SSH sera immediat

**Option 2: Console VNC Hetzner**
1. Dans la console Hetzner Cloud, cliquer sur le serveur
2. Onglet "Console" (en haut a droite)
3. Ouvrir une session VNC (pas besoin de SSH)
4. Se connecter en root
5. Le firewall Hetzner est EXTERNE au serveur, il faut le modifier via l'API/console web

**Option 3: API Hetzner (depuis n'importe quel PC)**
```bash
# Lister les firewalls
curl -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/firewalls

# Modifier une regle (exemple: reouvrir SSH depuis partout)
curl -X POST -H "Authorization: Bearer $HCLOUD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rules":[{"direction":"in","protocol":"tcp","port":"22","source_ips":["0.0.0.0/0","::/0"]},{"direction":"in","protocol":"icmp","source_ips":["0.0.0.0/0","::/0"]}]}' \
  https://api.hetzner.cloud/v1/firewalls/2449798/actions/set_rules
```

**IMPORTANT**: Le firewall Hetzner Cloud est gere HORS du serveur. Meme si tu te
bloques en SSH, tu peux toujours modifier le firewall via la console web Hetzner
ou l'API. Tu ne peux PAS perdre l'acces definitivement comme avec iptables.
C'est la grande difference avec un firewall au niveau OS.

---

## RESUME DES MODIFICATIONS PREVUES

### fw-ssh-admin - Modifications:
- SSH 22: restreindre a 46.62.171.61/32 (bastion)
- TCP 26270: restreindre a 46.62.171.61/32
- SUPPRIMER TCP 80, 443
- GARDER ICMP
- AJOUTER regles OUTBOUND: TCP 1-65535, UDP 53, UDP 123, ICMP

### fw-k3s-masters - Modifications:
- TCP 6443: restreindre a 46.62.171.61/32
- SUPPRIMER TCP 2379-2380 (etcd, passe par prive)
- SUPPRIMER TCP 10250 (kubelet, passe par prive)

### fw-databases - Modifications:
- SUPPRIMER toutes les regles (tout passe par reseau prive via lb-haproxy)
- OU restreindre a 46.62.171.61/32

### fw-minio - Modifications:
- SUPPRIMER TCP 443-9001 (plage trop large)
- TCP 9001: restreindre a 46.62.171.61/32

### v3-vault - Modifications:
- TCP 8200: restreindre a 46.62.171.61/32
- TCP 80, 443: garder si cert-manager en a besoin

### Ajout manquant:
- Ajouter db-postgres-02 (109783838) a fw-databases
