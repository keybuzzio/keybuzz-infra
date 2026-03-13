# PH-ADMIN-86.1C — Auth Hardening + Vault Safety Audit

**Date** : 13 mars 2026
**Statut** : TERMINE
**Environnement** : DEV + PROD

---

## 1. Vault HA — Audit

### Cluster Status

| Node | IP | Role | Sealed | Healthy | Version |
|---|---|---|---|---|---|
| vault-01 | 10.0.0.150 | follower | false | true | 1.21.1 |
| vault-02 | 10.0.0.154 | **leader** | false | true | 1.21.1 |
| vault-03 | 10.0.0.155 | follower | false | true | 1.21.1 |

- **Seal Type** : Shamir (5 shares, threshold 3)
- **Storage** : Raft
- **HA Enabled** : true
- **Failure Tolerance** : 1
- **Raft Committed Index** : 148642
- **Raft Applied Index** : 148642
- **Autopilot** : Healthy

### Conclusion Vault HA
Cluster pleinement operationnel a 3 noeuds. Aucune anomalie detectee.

---

## 2. Vault Paths — Audit

### Paths existants (non modifies)

| Path | Status |
|---|---|
| kv/keybuzz/dev/jwt | OK |
| kv/keybuzz/prod/jwt | OK |
| kv/keybuzz/dev/internal-tokens | OK |
| kv/keybuzz/prod/internal-tokens | OK |
| kv/keybuzz/redis | OK |
| kv/keybuzz/backend-jwt/dev | OK |
| kv/keybuzz/backend-jwt/prod | OK |
| kv/keybuzz/backend-product-db/dev | OK |
| kv/keybuzz/backend-product-db/prod | OK |
| kv/keybuzz/octopia/prod | OK |
| kv/keybuzz/inbound-webhook/dev | OK |
| kv/keybuzz/backend-postgres/prod | OK |
| kv/keybuzz/ai/* | OK |
| kv/keybuzz/litellm/* | OK |
| kv/keybuzz/ses | OK |
| kv/keybuzz/stripe | OK |
| kv/keybuzz/minio | OK |
| kv/keybuzz/auth | OK |
| kv/keybuzz/observability/* | OK |
| kv/keybuzz/tenants/* | OK |

### Conclusion Paths
Aucun path client/backend modifie. Zero regression.

---

## 3. ESO — Audit

### ClusterSecretStores

| Nom | Status | Ready |
|---|---|---|
| vault-backend | Valid | True |
| vault-backend-database | Valid | True |

### ExternalSecrets (28 total)

Tous en status `SecretSynced`, `Ready=True`.

Namespaces couverts :
- keybuzz-admin-v2-dev (1 ES)
- keybuzz-admin-v2-prod (1 ES)
- keybuzz-ai (1 ES)
- keybuzz-api-dev (9 ES)
- keybuzz-api-prod (5 ES)
- keybuzz-backend-dev (2 ES)
- keybuzz-backend-prod (2 ES)
- keybuzz-client-dev (2 ES)
- keybuzz-client-prod (1 ES)
- keybuzz-seller-dev (1 ES)
- observability (2 ES)

### Conclusion ESO
Zero erreur, zero retry permanent. Tous les ExternalSecrets synchronises.

---

## 4. Suppression password_plaintext

### Avant
```
kv/keybuzz/admin-v2/bootstrap (version 1):
  - email: ludo.gonthier@gmail.com
  - password_hash: $2b$12$... (60 chars)
  - password_plaintext: PRESENT (31 chars)
```

### Actions
1. Ecrit version 2 avec uniquement `email` + `password_hash`
2. Detruit version 1 (contenait le plaintext)

### Apres
```
kv/keybuzz/admin-v2/bootstrap (version 2):
  - email: ludo.gonthier@gmail.com
  - password_hash: $2b$12$... (60 chars)
  Keys: ['email', 'password_hash']
  NO plaintext
```

### Verification
- Pod DEV : hash injecte par ESO = hash Vault (confirme)
- Mauvais mot de passe : session vide `{}` (confirme)

---

## 5. Script de rotation

### Fichier
`scripts/admin-rotate-password.sh`

### Fonctionnalites
1. Lit le bootstrap actuel depuis Vault
2. Genere un mot de passe aleatoire (openssl rand, 30 chars)
3. Hash bcrypt via Node.js (bcryptjs, cost 12)
4. Ecrit la nouvelle version dans Vault (email + hash uniquement)
5. Detruit l'ancienne version Vault
6. Force le resync ESO (annotation)
7. Rollout restart des pods DEV + PROD
8. Affiche le nouveau mot de passe en clair (a stocker manuellement)

### Securite
- Aucun mot de passe en clair dans Vault apres rotation
- Anciennes versions detruites
- Mode `--dry-run` disponible

### Test dry-run
```
[DRY RUN] No changes will be applied.
New password generated (30 chars)
New hash: $2b$12$...
[DRY RUN] Would update Vault with new hash.
[DRY RUN] Would restart admin pods.
```

---

## 6. Durcissement session NextAuth

### Cookies
| Parametre | Valeur |
|---|---|
| name (prod) | `__Secure-next-auth.session-token` |
| httpOnly | true |
| sameSite | strict |
| secure | true (production) |
| path | / |

### Session
| Parametre | Valeur |
|---|---|
| strategy | JWT |
| maxAge | 8 heures |

---

## 7. Headers de securite

### Headers actifs (DEV + PROD confirmes)

| Header | Valeur |
|---|---|
| X-Frame-Options | DENY |
| X-Content-Type-Options | nosniff |
| Referrer-Policy | strict-origin-when-cross-origin |
| X-XSS-Protection | 1; mode=block |
| Content-Security-Policy | default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' https://api-dev.keybuzz.io https://api.keybuzz.io; frame-ancestors 'none'; base-uri 'self'; form-action 'self' |
| Permissions-Policy | camera=(), microphone=(), geolocation=(), interest-cohort=() |
| Strict-Transport-Security | max-age=31536000; includeSubDomains |

---

## 8. Tests de non-regression

### Client isolation

| Service | Status |
|---|---|
| client-dev.keybuzz.io | HTTP 307 (redirect login) |
| client.keybuzz.io | HTTP 307 (redirect login) |
| admin-dev.keybuzz.io/login | HTTP 200 |
| admin.keybuzz.io/login | HTTP 200 |

### Login admin
- Mauvais mot de passe → session vide `{}` (OK)
- Pod hash = Vault hash (OK)
- ESO SecretSynced post-modification (OK)

---

## 9. Docker tags

| Env | Tag |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.3.0-ph86.1c-auth-hardening-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.3.0-ph86.1c-auth-hardening-prod` |

---

## 10. Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/lib/auth.ts` | Cookies durcis (sameSite strict, secure, httpOnly) |
| `next.config.mjs` | Headers securite (CSP, HSTS, X-Frame, etc.) |
| `scripts/admin-rotate-password.sh` | Nouveau — script rotation bootstrap |
| `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` | Image tag v0.3.0-ph86.1c |
| `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` | Image tag v0.3.0-ph86.1c |

---

## 11. Criteres de validation

| Critere | Status |
|---|---|
| Vault HA healthy (3 noeuds) | OK |
| password_plaintext supprime | OK |
| Version 1 Vault detruite | OK |
| password_hash utilise | OK |
| Rotation possible (script + dry-run) | OK |
| Client non impacte | OK |
| Admin login fonctionnel | OK |
| Headers securite actifs | OK |
| Cookies durcis | OK |
| ESO SecretSynced | OK |
| GitOps (manifests MAJ) | OK |
