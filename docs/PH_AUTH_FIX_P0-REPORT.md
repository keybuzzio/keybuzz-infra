# PH_AUTH_FIX_P0 -- Security Patch Auth Report

**Date** : 2026-02-24
**Environnement** : DEV deploye, PROD en attente [PROD-APPROVED]

---

## Resume

| ID | Severite | Description | Statut |
|----|----------|-------------|--------|
| C1 | CRITIQUE | Cross-tenant access (pas de validation membership) | CORRIGE DEV |
| C2 | CRITIQUE | OTP en clair, Math.random(), stockage memoire | CORRIGE DEV |
| C3 | CRITIQUE | Aucun rate limiting API | CORRIGE DEV |
| H3 | HAUT | NODE_TLS_REJECT_UNAUTHORIZED=0 en PROD | BLOQUE (prerequis infra) |
| H5 | HAUT | /api/debug-env expose en PROD | CORRIGE DEV |

---

## C1 -- Tenant Guard Global

### Implementation
- Fichier : keybuzz-api/src/plugins/tenantGuard.ts
- Hook Fastify preHandler global
- Verification membership via user_tenants + users
- Cache 30s, max 10000 entrees
- Routes exemptees : /health, /auth/*, /tenant-context/*, /space-invites/*, /billing/stripe/webhook, /public/*, /inbound/*, /debug/*, /api/v1/orders/webhook*, OPTIONS

### Preuves DEV
- User A essaie tenant B -> 403 {"error":"Access denied: not a member of this tenant"}
- User A (ludo.gonthier@gmail.com) sur tenant ecomlg-001 -> 200
- Route health (exempt) -> 200

---

## C2 -- OTP Securise

### Implementation
- API : POST /auth/otp/store, /verify, /has (PostgreSQL, SHA-256+salt, 5 attempts, 10min TTL)
- Client : crypto.randomInt(100000,999999), delegation API, suppression Map memoire
- Anti-enumeration : reponse identique email existant/inexistant
- devCode supprime des reponses

### Preuves DEV
- Store OTP : 200 {"success":true}
- Verify correct : 200 {"valid":true}
- Brute force 5x : bloque apres max_attempts
- Anti-enum : meme reponse pour email inexistant
- DB : hash SHA-256 64 chars, salt 32 chars, plaintext absent

---

## C3 -- Rate Limiting

### Implementation
- Fichier : keybuzz-api/src/plugins/rateLimiter.ts
- Custom Map + sliding window (pas de dependance externe)
- Global : 200 req/min/IP, OTP store : 5/min/IP + 3/15min/email, OTP verify : 10/min/IP
- Reponse 429 avec Retry-After header

### Preuves DEV
- Request 1-2 : 200
- Request 3+ : 429 {"error":"Too many OTP requests","retryAfterSec":39}

---

## H3 -- TLS Verification

### Diagnostic
- Vault utilise cert auto-signe (CN=Vault, O=HashiCorp) sans SAN pour vault.default.svc.cluster.local
- ERR_TLS_CERT_ALTNAME_INVALID meme avec CA monte
- Rollback effectue : NODE_TLS_REJECT_UNAUTHORIZED=0 restaure
- Prerequis : regenerer cert Vault avec SANs corrects

### Statut : BLOQUE (prerequis infra)

---

## H5 -- debug-env

### Implementation
- Guard en debut de GET() : retourne 404 si NODE_ENV=production && NEXT_PUBLIC_APP_ENV=production
- Preuve : guard present dans le code compile

---

## Images Docker

| Env | Service | Tag |
|-----|---------|-----|
| DEV | API | v3.5.42-ph-auth-p0-dev-v2 |
| DEV | Client | v3.5.42-ph-auth-p0-client-dev-v2 |

### Rollback
- API DEV : kubectl -n keybuzz-api-dev set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.36-ph365g-dev
- Client DEV : kubectl -n keybuzz-client-dev set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.41-ph365h4-dev

---

## Fichiers source modifies (GitOps)

keybuzz-api :
- src/plugins/tenantGuard.ts (NOUVEAU)
- src/plugins/rateLimiter.ts (NOUVEAU)
- src/modules/auth/otp-routes.ts (NOUVEAU)
- src/app.ts (modifie)

keybuzz-client :
- src/lib/otp-store.ts (refactorise)
- app/api/auth/email/request/route.ts (adapte)
- app/api/auth/magic/start/route.ts (adapte)
- app/api/auth/[...nextauth]/auth-options.ts (adapte)
- app/api/debug-env/route.ts (guard PROD)

Infrastructure :
- Table PostgreSQL otp_codes (auto-creee)
- ConfigMap vault-ca-cert (DEV+PROD)

---

## Recommandations
1. H3 : Regenerer cert Vault avec SANs, puis retirer NODE_TLS_REJECT_UNAUTHORIZED=0
2. Migrer vers @fastify/rate-limit au prochain rebuild
3. Remplacer X-User-Email par JWT verifiable cote API
4. Ajouter CRON nettoyage OTP expires
