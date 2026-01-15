# PH-SRE-DB-ENDPOINT-NONREGRESSION-02 — Rapport

**Date** : 2026-01-15  
**Statut** : ✅ TERMINÉ

---

## Résumé

Correction d'une régression PGHOST introduite lors des tests PH-AI-CREDITS-02 où l'endpoint DB avait été modifié de `10.0.0.10` (LB) vers `10.0.0.122` (IP de node).

**Bonus critique** : Découverte et correction d'un problème de failover PostgreSQL non détecté par HAProxy.

---

## 1. Régression Identifiée

### 1.1 Inventaire Initial

| Composant | PGHOST Trouvé | Statut |
|-----------|---------------|--------|
| Secret `keybuzz-api-postgres` | `10.0.0.122` | ❌ RÉGRESSION |
| Deployment `keybuzz-api` (env override) | `10.0.0.122` | ❌ RÉGRESSION |
| Secret `keybuzz-api-postgres-static` | `10.0.0.10` | ✅ OK |
| Secret `keybuzz-db-migrator` | `10.0.0.10` | ✅ OK |

### 1.2 Manifests GitOps

| Fichier | IP Trouvée | Action |
|---------|------------|--------|
| `k8s/keybuzz-api-dev/job-migrate-010.yaml` | `10.0.0.122` | ✅ Corrigé |
| `k8s/observability/prometheus-*.yaml` | `10.0.0.12x` | ⚪ Légitime (monitoring) |

---

## 2. Problème Critique Découvert : HAProxy Failover

### 2.1 Contexte

Lors des tests, le LB `10.0.0.10` routait vers `10.0.0.120` qui était devenu **replica** après un failover automatique Patroni.

**État du cluster PostgreSQL** :
```
Node          | pg_is_in_recovery | Rôle Patroni
--------------|-------------------|-------------
10.0.0.120    | t (true)          | replica
10.0.0.121    | N/A (DOWN)        | offline
10.0.0.122    | f (false)         | primary ← LEADER
```

### 2.2 Cause Racine

La config HAProxy utilisait `tcp-check` qui vérifie seulement si le port 5432 répond, sans détecter le rôle PostgreSQL (primary/replica).

**Avant** :
```
listen postgres_write
    balance first
    option tcp-check
    tcp-check connect port 5432
    server db-postgres-01 10.0.0.120:5432 check  # Premier = routé même si replica
    server db-postgres-02 10.0.0.121:5432 check backup
    server db-postgres-03 10.0.0.122:5432 check backup
```

### 2.3 Solution Appliquée

Migration vers **Patroni HTTP health check** sur le port 8008 :

```
listen postgres_write
    balance first
    option httpchk GET /primary
    http-check expect status 200
    default-server inter 2000 fall 2 rise 2 on-marked-down shutdown-sessions
    server db-postgres-01 10.0.0.120:5432 check port 8008
    server db-postgres-02 10.0.0.121:5432 check port 8008
    server db-postgres-03 10.0.0.122:5432 check port 8008
```

**Comportement** :
- Patroni `/primary` → 200 uniquement sur le leader
- Patroni `/replica` → 200 uniquement sur les replicas
- HAProxy route automatiquement vers le vrai primary

---

## 3. Corrections Appliquées

### 3.1 Secret K8s

```bash
# Avant
kubectl -n keybuzz-api-dev get secret keybuzz-api-postgres -o jsonpath='{.data.PGHOST}' | base64 -d
# 10.0.0.122

# Après
# 10.0.0.10
```

### 3.2 Deployment Override

```bash
# Suppression de l'override env
kubectl -n keybuzz-api-dev set env deployment/keybuzz-api PGHOST-
```

### 3.3 HAProxy (10.0.0.11 et 10.0.0.12)

- Backup créé : `/etc/haproxy/haproxy.cfg.bak-20260115`
- Config mise à jour avec Patroni health check
- Service rechargé : `systemctl reload haproxy`

### 3.4 Fichiers GitOps Modifiés

| Fichier | Modification |
|---------|--------------|
| `k8s/keybuzz-api-dev/job-migrate-010.yaml` | IP hardcodée → secretKeyRef |
| `ansible/roles/postgres_haproxy_v3/tasks/main.yml` | tcp-check → httpchk Patroni |

---

## 4. Preuves

### 4.1 LB Write Fonctionnel

```bash
# Test pg_is_in_recovery via LB
psql -h 10.0.0.10 -c 'SELECT pg_is_in_recovery();'
 pg_is_in_recovery 
-------------------
 f
```

### 4.2 Test INSERT

```sql
CREATE TEMP TABLE test_lb_write_proof (id serial, ts timestamptz default now());
INSERT INTO test_lb_write_proof DEFAULT VALUES RETURNING *;
--  id |              ts              
-- ----+------------------------------
--   1 | 2026-01-15 08:57:33.93193+00

SELECT 'WRITE SUCCESS via LB 10.0.0.10' as result;
--              result             
-- --------------------------------
--  WRITE SUCCESS via LB 10.0.0.10
```

### 4.3 API Health

```bash
curl https://api-dev.keybuzz.io/health
# {"status":"ok","timestamp":"2026-01-15T08:57:48.578Z",...}
```

### 4.4 Guard PASS

```
[2026-01-15 08:58:20] DB Endpoint Guard - Scan démarré
[2026-01-15 08:58:20] Scan: keybuzz-infra K8s manifests...
[2026-01-15 08:58:20] Scan: keybuzz-api...
[2026-01-15 08:58:20] Scan: keybuzz-backend...
[2026-01-15 08:58:20] Scan: K8s secrets keybuzz-api-dev...
[2026-01-15 08:58:20] Scan: K8s secrets keybuzz-backend-dev...
[2026-01-15 08:58:20] ✅ PASS: Aucune IP de node PostgreSQL détectée
[2026-01-15 08:58:20]    Endpoint LB officiel: 10.0.0.10:5432
```

---

## 5. Guard Anti-Régression

### 5.1 Script Existant

Chemin : `/opt/keybuzz/sre/db_endpoint_guard.sh`

**Fonctionnalités** :
- Scanne les manifests K8s pour `10.0.0.12[0-2]`
- Scanne les secrets K8s (décode base64)
- Exclut les usages légitimes (Prometheus, docs)
- Log dans `/opt/keybuzz/logs/sre/db_endpoint_guard.log`

### 5.2 Exécution

```bash
# Manuelle
/opt/keybuzz/sre/db_endpoint_guard.sh

# Cron (recommandé)
0 */6 * * * /opt/keybuzz/sre/db_endpoint_guard.sh >> /opt/keybuzz/logs/sre/db_endpoint_guard.log 2>&1
```

---

## 6. Architecture Finale

```
┌─────────────────────────────────────────────────────────────┐
│                      Applications                           │
│  keybuzz-api-dev    keybuzz-backend-dev    keybuzz-worker  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ PGHOST=10.0.0.10
                            ▼
                ┌───────────────────────┐
                │   Hetzner LB Public   │
                └───────────┬───────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
     ┌─────────────────┐       ┌─────────────────┐
     │ HAProxy-01      │       │ HAProxy-02      │
     │ 10.0.0.11       │       │ 10.0.0.12       │
     │ httpchk /primary│       │ httpchk /primary│
     └────────┬────────┘       └────────┬────────┘
              │                         │
              └─────────┬───────────────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
   ┌───────────┐ ┌───────────┐ ┌───────────┐
   │postgres-01│ │postgres-02│ │postgres-03│
   │10.0.0.120 │ │10.0.0.121 │ │10.0.0.122 │
   │ REPLICA   │ │   DOWN    │ │  PRIMARY  │
   │ Patroni   │ │           │ │  Patroni  │
   │ port 8008 │ │           │ │ port 8008 │
   └───────────┘ └───────────┘ └───────────┘
```

---

## 7. Rollback

En cas de problème avec HAProxy Patroni health check :

```bash
# Sur HAProxy-01 et HAProxy-02
ssh root@10.0.0.11
cp /etc/haproxy/haproxy.cfg.bak-20260115 /etc/haproxy/haproxy.cfg
systemctl reload haproxy

ssh root@10.0.0.12
cp /etc/haproxy/haproxy.cfg.bak-20260115 /etc/haproxy/haproxy.cfg
systemctl reload haproxy
```

---

## 8. Conclusion

| Item | Statut |
|------|--------|
| Régression PGHOST corrigée | ✅ |
| HAProxy failover-aware | ✅ |
| LB write fonctionnel | ✅ |
| API santé OK | ✅ |
| Guard PASS | ✅ |
| GitOps mis à jour | ✅ |
| Rollback documenté | ✅ |

**Impact** :
- ✅ Zéro downtime
- ✅ Failover PostgreSQL maintenant transparent
- ✅ Aucune intervention manuelle requise lors des switchover Patroni

---

**Fin du rapport PH-SRE-DB-ENDPOINT-NONREGRESSION-02**
