# UNIFIED BASELINE — DEV = PROD (B08 PH361) — IDEMPROD

**Date** : 2026-02-19T14:16 UTC (cree) — 2026-02-19T14:30 UTC (fix client PROD)  
**Nom de reference** : **IDEMPROD** (pour rollback rapide)  
**Principe** : DEV et PROD utilisent le meme code source. API/Worker = meme image. Client = meme source, build separe (NEXT_PUBLIC_API_URL bake au build).

---

## Images deployes

### API + Worker (identiques DEV = PROD)

| Composant | Image | Tag |
|-----------|-------|-----|
| API | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.3-ph361-fix-check-user-dev` |
| Worker | `ghcr.io/keybuzzio/keybuzz-api` | `v3.4.4-ph353b-fixed-lock-dev` |

### Client (meme source, env different)

| Env | Image | Tag | NEXT_PUBLIC_API_URL |
|-----|-------|-----|---------------------|
| PROD | `ghcr.io/keybuzzio/keybuzz-client` | `v3.5.3-ph361-unified-prod` | `https://api.keybuzz.io` |
| DEV | `ghcr.io/keybuzzio/keybuzz-client` | `v3.5.3-ph361-unified-dev` | `https://api-dev.keybuzz.io` |

> **Note** : Next.js bake `NEXT_PUBLIC_*` au build. Le client DOIT etre builde separement pour DEV et PROD. C'est par design, pas du hardcodage.

---

## Tenants (auto-decouverts)

| Env | Tenant ID | Nom |
|-----|-----------|-----|
| DEV | `tenant-1771372217854` | SWITAA SASU |
| PROD | `tenant-1771372406836` | SWITAA SASU |

---

## Validation E2E

### PROD

| # | Test | Resultat |
|---|------|----------|
| 1 | Health | 200 OK |
| 2 | Auth check-user | 200 — exists:true, hasTenants:true |
| 3 | Conversations | 200 — 5 conv Octopia |
| 4 | Dashboard | 200 — total:233, open:47 |
| 5 | Billing | **400** — "Invalid tenantId format" (connu sur B08) |
| 6 | Suppliers | 200 |
| 7 | AI Settings | 200 — supervised, enabled |
| 8 | Pages SSR | 5/5 (login=200, inbox/orders/settings/suppliers=307) |

**Score : 7/8** — Billing en erreur (format tenantId, bug connu B08)

### DEV

Memes images = memes resultats attendus (valide precedemment dans la matrice).

---

## Etat avant unification (rollback PROD si besoin)

| Composant | Ancien tag PROD |
|-----------|-----------------|
| API | `v3.4.4-ph353-octopia-readonly-prod-2` |
| Client | `v3.4.2-ph351-octopia-import-prod` |
| Worker | `v3.4.4-ph353-octopia-readonly-prod-2` |

### Commandes de rollback PROD vers ancien etat

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2 -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2 -n keybuzz-api-prod
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-prod -n keybuzz-client-prod
```

### Commandes de rollback vers IDEMPROD (cette version)

```bash
# PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.3-ph361-fix-check-user-dev -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev -n keybuzz-api-prod
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.3-ph361-unified-prod -n keybuzz-client-prod

# DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.3-ph361-fix-check-user-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.3-ph361-unified-dev -n keybuzz-client-dev
```

---

*Point de repere cree. DEV = PROD = IDEMPROD.*
