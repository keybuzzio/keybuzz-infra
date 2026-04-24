# Serveurs et installation KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : inventaire infra et sommaire d'installation a lire avant toute action serveur.

## Sources

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\servers\servers_v3.tsv`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\ansible\inventory\hosts.yml`
- `C:\DEV\KeyBuzz\V3\Infra\scripts\PLAN_INSTALLATION_COMPLETE_V2.md`
- `C:\DEV\KeyBuzz\V3\Infra\scripts\RECAP_FINAL_INSTALLATION_V2.md`
- `C:\DEV\KeyBuzz\V3\Infra\scripts\RAPPORT_TECHNIQUE_COMPLET_KEYBUZZ_INFRASTRUCTURE.md`

Note : cet inventaire est une source locale/documentaire. Avant une operation destructive ou reseau, verifier l'etat live.

## Synthese serveurs

Inventaire v3 : 49 serveurs.

| Groupe | Nombre | Role |
|---|---:|---|
| bastions | 2 | `install-01` legacy, `install-v3` GitOps/orchestration |
| k8s masters | 3 | control plane |
| k8s workers | 5 | workloads applicatifs |
| PostgreSQL | 3 | Patroni/Postgres |
| MariaDB | 3 | Galera ERPNext |
| ProxySQL | 2 | proxy MariaDB |
| Redis | 3 | Redis HA/Sentinel |
| RabbitMQ | 3 | cluster queue |
| MinIO | 3 | stockage objet |
| HAProxy internes | 2 | LB interne Postgres/Redis/RabbitMQ |
| services donnees/app/support | 23 | analytics, temporal, qdrant, litellm, vault, monitor, mail, backup, builder, etc. |

## Inventaire serveurs v3

| Hostname | IP privee | IP publique | FQDN | Role v3 | Core |
|---|---|---|---|---|---|
| install-01 | `10.0.0.250` | `91.98.128.153` | `install-01.keybuzz.io` | bastion-legacy | yes |
| install-v3 | `10.0.0.251` | `46.62.171.61` | `install-v3.keybuzz.io` | bastion-v3 | yes |
| k8s-master-01 | `10.0.0.100` | `91.98.124.228` | `master1.keybuzz.io` | k8s-master | yes |
| k8s-master-02 | `10.0.0.101` | `91.98.117.26` | `master2.keybuzz.io` | k8s-master | yes |
| k8s-master-03 | `10.0.0.102` | `91.98.165.238` | `master3.keybuzz.io` | k8s-master | yes |
| k8s-worker-01 | `10.0.0.110` | `116.203.135.192` | `worker1.keybuzz.io` | k8s-worker | yes |
| k8s-worker-02 | `10.0.0.111` | `91.99.164.62` | `worker2.keybuzz.io` | k8s-worker | yes |
| k8s-worker-03 | `10.0.0.112` | `157.90.119.183` | `worker3.keybuzz.io` | k8s-worker | yes |
| k8s-worker-04 | `10.0.0.113` | `91.98.200.38` | `worker4.keybuzz.io` | k8s-worker | yes |
| k8s-worker-05 | `10.0.0.114` | `188.245.45.242` | `worker5.keybuzz.io` | k8s-worker | no |
| db-postgres-01 | `10.0.0.120` | `195.201.122.106` | `db-postgres-01.keybuzz.io` | db-postgres | yes |
| db-postgres-02 | `10.0.0.121` | `91.98.169.31` | `db-postgres-02.keybuzz.io` | db-postgres | yes |
| db-postgres-03 | `10.0.0.122` | `65.21.251.198` | `db-postgres-03.keybuzz.io` | db-postgres | yes |
| redis-01 | `10.0.0.123` | `49.12.231.193` | `redis1.keybuzz.io` | redis | yes |
| redis-02 | `10.0.0.124` | `23.88.48.163` | `redis2.keybuzz.io` | redis | yes |
| redis-03 | `10.0.0.125` | `91.98.167.166` | `redis3.keybuzz.io` | redis | yes |
| queue-01 | `10.0.0.126` | `23.88.105.16` | `queue1.keybuzz.io` | rabbitmq | yes |
| queue-02 | `10.0.0.127` | `91.98.167.159` | `queue2.keybuzz.io` | rabbitmq | yes |
| queue-03 | `10.0.0.128` | `91.98.68.35` | `queue3.keybuzz.io` | rabbitmq | yes |
| temporal-db-01 | `10.0.0.129` | `88.99.227.128` | `temporal-db.keybuzz.io` | db-temporal | no |
| analytics-db-01 | `10.0.0.130` | `91.98.134.176` | `analytics-db.keybuzz.io` | db-analytics | no |
| minio-02 | `10.0.0.131` | `91.99.199.183` | `minio-02.keybuzz.io` | minio | yes |
| minio-03 | `10.0.0.132` | `91.99.103.47` | `minio-03.keybuzz.io` | minio | yes |
| crm-01 | `10.0.0.133` | `78.47.43.10` | `crm.keybuzz.io` | app-crm | no |
| minio-01 | `10.0.0.134` | `116.203.144.185` | `s3.keybuzz.io` | minio | yes |
| api-gateway-01 | `10.0.0.135` | `23.88.107.251` | `gateway.keybuzz.io` | lb-apigw | no |
| vector-db-01 | `10.0.0.136` | `116.203.240.119` | `qdrant.keybuzz.io` | vector-db | yes |
| litellm-01 | `10.0.0.137` | `91.98.200.40` | `llm.keybuzz.io` | llm-proxy | yes |
| temporal-01 | `10.0.0.138` | `91.98.197.70` | `temporal.keybuzz.io` | app-temporal | no |
| analytics-01 | `10.0.0.139` | `91.99.237.167` | `analytics.keybuzz.io` | app-analytics | no |
| etl-01 | `10.0.0.140` | `195.201.225.134` | `etl.keybuzz.io` | app-etl | no |
| nocodb-01 | `10.0.0.142` | `78.46.170.170` | `nocodb.keybuzz.io` | app-nocode | no |
| ml-platform-01 | `10.0.0.143` | `157.90.236.10` | `ml.keybuzz.io` | ml-platform | no |
| baserow-01 | `10.0.0.144` | `91.99.195.137` | `baserow.keybuzz.io` | app-nocode | no |
| vault-01 | `10.0.0.150` | `116.203.61.22` | `vault.keybuzz.io` | vault | no |
| siem-01 | `10.0.0.151` | `91.99.58.179` | `siem.keybuzz.io` | siem | no |
| monitor-01 | `10.0.0.152` | `23.88.105.216` | `monitor.keybuzz.io` | monitoring | no |
| backup-01 | `10.0.0.153` | `91.98.139.56` | `backup.keybuzz.io` | backup | yes |
| mail-core-01 | `10.0.0.160` | `37.27.251.162` | `mail.keybuzz.io` | mail-core | no |
| mail-mx-01 | `10.0.0.161` | `91.99.66.6` | `mx1.keybuzz.io` | mail-mx | no |
| mail-mx-02 | `10.0.0.162` | `91.99.87.76` | `mx2.keybuzz.io` | mail-mx | no |
| maria-01 | `10.0.0.170` | `91.98.35.206` | `maria-01.keybuzz.io` | db-mariadb | yes |
| maria-02 | `10.0.0.171` | `46.224.43.75` | `maria-02.keybuzz.io` | db-mariadb | yes |
| maria-03 | `10.0.0.172` | `49.13.66.233` | `maria-03.keybuzz.io` | db-mariadb | yes |
| proxysql-01 | `10.0.0.173` | `46.224.64.206` | `proxysql-01.keybuzz.io` | db-proxysql | yes |
| proxysql-02 | `10.0.0.174` | `188.245.194.27` | `proxysql-02.keybuzz.io` | db-proxysql | yes |
| builder-01 | `10.0.0.200` | `5.75.128.134` | `builder.keybuzz.io` | builder | no |
| haproxy-01 | `10.0.0.11` | `159.69.159.32` | `haproxy1.keybuzz.io` | lb-internal | yes |
| haproxy-02 | `10.0.0.12` | `91.98.164.223` | `haproxy2.keybuzz.io` | lb-internal | yes |

## Endpoints internes principaux

- LB interne Hetzner : `10.0.0.10`
- PostgreSQL write : `10.0.0.10:5432`
- PostgreSQL read : `10.0.0.10:5433`
- Redis : `10.0.0.10:6379`
- RabbitMQ : `10.0.0.10:5672`
- MariaDB via ProxySQL : `10.0.0.20:3306`
- K8s API historique/documentaire : `10.0.0.100:6443`
- MinIO API : `10.0.0.134:9000`
- MinIO console : `10.0.0.134:9001`

## Sommaire d'installation

Plan d'installation V2 depuis serveurs vierges :

1. Module 2 : Base OS & Securite
   - apt update/upgrade, Docker, swap off, UFW, SSH hardening, DNS, sysctl, journald.
2. Module 3 : PostgreSQL HA
   - 3 noeuds, PostgreSQL 16, Patroni RAFT, HAProxy/PgBouncer.
3. Module 4 : Redis HA
   - 3 noeuds Redis + Sentinel, HAProxy.
4. Module 5 : RabbitMQ HA
   - 3 noeuds RabbitMQ Quorum, HAProxy.
5. Module 6 : MinIO S3
   - cible moderne : cluster 3 noeuds, version figée, erasure coding.
6. Module 7 : MariaDB Galera HA
   - 3 noeuds Galera pour ERPNext.
7. Module 8 : ProxySQL Advanced
   - 2 noeuds ProxySQL, frontend MariaDB.
8. Module 9 : Kubernetes HA Core
   - cible moderne : K8s complet, pas K3s, Calico IPIP, Ingress NGINX, Prometheus stack.

## Ambiguite historique K3s / K8s

Les anciens rapports et `servers.tsv` parlent souvent de K3s. Les plans V2 et la memoire moderne indiquent que la cible correcte est K8s complet, pas K3s, avec Calico IPIP. Avant toute action cluster, verifier le runtime reel.

## Regles avant action infra

- Ne jamais agir uniquement depuis cette synthese.
- Relire le rapport recent du domaine infra.
- Verifier inventaire + runtime live.
- Prevoir rollback.
- Ne pas exposer secrets.
- Ne pas utiliser `latest`.
- Ne pas modifier PROD sans validation explicite.
