# PH11-03 ??? ESO dataFrom Extract Fix Report

**Date**: 2025-12-24 10:58:35 UTC  
**Scope**: DEV only (`keybuzz-api-dev`)  
**Status**: ??? **RESOLVED**

## ???? Objectif

Corriger l'ExternalSecret `keybuzz-api-postgres` pour que `PGUSER` et `PGPASSWORD` proviennent du **m??me lease Vault** (un seul fetch), puis valider que `/health/db` retourne **200 OK**.

## ???? Probl??me identifi??

L'ExternalSecret utilisait deux entr??es `data` s??par??es qui faisaient **deux reads Vault distincts** :

```yaml
data:
  - secretKey: PGUSER
    remoteRef:
      key: database/creds/keybuzz-api-db
      property: username
  - secretKey: PGPASSWORD
    remoteRef:
      key: database/creds/keybuzz-api-db
      property: password
```

**Cons??quence** : Chaque read g??n??rait un nouveau lease Vault avec username/password diff??rents ??? credentials incoh??rents ??? **authentification PostgreSQL ??chouait**.

## ??? Solution impl??ment??e

Utilisation de `dataFrom.extract` pour garantir **un seul fetch** Vault :

```yaml
dataFrom:
  - extract:
      key: database/creds/keybuzz-api-db

target:
  template:
    engineVersion: v2
    data:
      PGHOST: "10.0.0.10"
      PGPORT: "5432"
      PGDATABASE: "keybuzz"
      PGUSER: "{{ .username }}"
      PGPASSWORD: "{{ .password }}"
```

## ???? Modifications apport??es

### Fichier modifi??

- **Repo**: `keybuzz-infra`
- **Fichier**: `k8s/keybuzz-api-dev/externalsecret-postgres.yaml`
- **Commit**: `fe454c6` - `fix(PH11-03): use dataFrom extract to keep Vault username/password consistent`

### Changements

1. Suppression de la section `data` avec deux entr??es s??par??es
2. Ajout de `dataFrom.extract` sur `database/creds/keybuzz-api-db`
3. Mapping des variables dans `target.template.data` avec template Golang
4. Conservation de `engineVersion: v2` pour le template

## ???? V??rifications

### 1. Secret Kubernetes contient les 5 cl??s

```
??? PGDATABASE
??? PGHOST
??? PGPASSWORD
??? PGPORT
??? PGUSER
```

### 2. Valeurs du secret

```
PGHOST: 10.0.0.10
PGPORT: 5432
PGDATABASE: keybuzz
PGUSER: v-kubernet-keybuzz--K8XlvT5QvK... (dynamic)
PGPASSWORD: ********** (20 chars)
```

### 3. Validation des endpoints

**`/health`**:
```json
{
  "status": "ok",
  "timestamp": "2025-12-24T10:57:18.912Z",
  "service": "keybuzz-api",
  "version": "1.0.0"
}
```
**Status**: ??? `200 OK`

**`/health/db`**:
```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2025-12-24T10:57:19.166Z"
}
```
**Status**: ??? `200 OK` (r??solu !)

## ???? R??sultat

| Endpoint | Avant | Apr??s |
|----------|-------|-------|
| `/health` | 200 OK | 200 OK |
| `/health/db` | 503 (auth failed) | **200 OK** ??? |

## ???? Commandes ex??cut??es

```bash
# 1. Modification du manifest
cd /opt/keybuzz/keybuzz-infra
# Edit externalsecret-postgres.yaml

# 2. Commit et push
git add k8s/keybuzz-api-dev/externalsecret-postgres.yaml
git commit -m "fix(PH11-03): use dataFrom extract to keep Vault username/password consistent"
git push origin main

# 3. Force refresh
kubectl -n keybuzz-api-dev delete secret keybuzz-api-postgres
kubectl -n keybuzz-api-dev delete externalsecret keybuzz-api-postgres
kubectl apply -k /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev

# 4. Restart deployment
kubectl -n keybuzz-api-dev rollout restart deployment/keybuzz-api
kubectl -n keybuzz-api-dev rollout status deployment/keybuzz-api --timeout=120s

# 5. Validation
curl -k https://api-dev.keybuzz.io/health
curl -k https://api-dev.keybuzz.io/health/db
```

## ???? Le??ons apprises

1. **ESO `data` vs `dataFrom`**: 
   - `data` avec plusieurs entr??es sur le m??me path = plusieurs fetches
   - `dataFrom.extract` = un seul fetch, garantit coh??rence

2. **Vault dynamic secrets**: Les credentials ont un TTL court (15min), il est crucial qu'username et password proviennent du m??me lease

3. **Template engine v2**: N??cessaire pour utiliser `{{ .username }}` et `{{ .password }}`

## ???? Prochaines ??tapes

- ??? DEV valid?? et fonctionnel
- ?????? **PROD non touch??** (comme demand??)
- Si besoin d'appliquer en PROD : cr??er un ExternalSecret similaire dans `k8s/keybuzz-api-prod/`

---

**FIN DU RAPPORT PH11-03**
