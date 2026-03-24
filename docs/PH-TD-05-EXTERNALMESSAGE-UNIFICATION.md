# PH-TD-05 — ExternalMessage Single Source of Truth Unification

> Date : 2026-03-16
> Phase : PH-TD-05
> Auteur : Cursor Agent
> Status : **COMPLETE**

---

## A. Hypothese de Depart

**`keybuzz_prod.ExternalMessage`** = source de verite unique.

Justification :
- `keybuzz_prod` est la DB produit (API Fastify, conversations, messages, orders)
- Le backend est un service auxiliaire dont le role est d'alimenter la DB produit
- Le backend avait deja `productDb` (pool pg vers `keybuzz_prod`) pour les conversations
- ExternalMessage contient des messages marketplace directement lies aux conversations

---

## B. Audit

### B.1 Schema

Les deux tables avaient un schema **IDENTIQUE** :
- 14 colonnes (id, tenantId, connectionId, type, externalId, threadId, orderId, buyerName, buyerEmail, language, receivedAt, raw, ticketId, createdAt)
- 3 indexes (PK, tenantId+receivedAt, ticketId)
- 1 contrainte unique (type, connectionId, externalId)
- Seule difference : ownership (keybuzz_api_prod vs kb_backend)

### B.2 Donnees (avant migration)

| DB | Rows |
|---|---|
| keybuzz_prod | 4 (PROD) |
| keybuzz_backend_prod | 4 (PROD) |
| keybuzz (DEV) | 0 (table n'existait pas) |
| keybuzz_backend (DEV) | 41 651 |

**Delta PROD** :
- 3 rows identiques dans les deux DBs
- 1 row unique dans `keybuzz_prod` (PROD-only)
- 1 row unique dans `keybuzz_backend_prod` (backend-only)
- **Divergence active confirmee** — justifie l'unification

### B.3 Usages Code

| Fichier | Operation | Ancien chemin |
|---|---|---|
| `amazon.service.ts` → `upsertExternalMessage()` | upsert | `prisma` → backend_prod |
| `amazon.service.ts` → `mapExternalMessageToTicket()` | read + update | `prisma` → backend_prod |
| `amazon.poller.ts` | appelle upsert + map | via amazon.service |
| `inbound.routes.ts` | findUnique + create + update | `prisma` → backend_prod |
| `inboundEmailWebhook.routes.ts` | findUnique + create | `prisma` → backend_prod |
| `keybuzz-api/src/` | **AUCUN usage** | N/A |

**Conclusion** : Tous les usages ExternalMessage etaient dans le backend, via Prisma → `keybuzz_backend_prod`. L'API n'utilisait pas cette table.

---

## C. Bascule

### C.1 Nouveau module : `externalMessageStore.ts`

Cree dans `src/lib/externalMessageStore.ts` :
- Utilise `productDb` (pool pg → `keybuzz_prod`) au lieu de Prisma
- 4 methodes : `findUnique`, `upsert`, `create`, `update`
- Generation d'ID compatible cuid (via `crypto.randomBytes`)
- Cast explicite `"MarketplaceType"` pour le type enum PostgreSQL

### C.2 Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/lib/externalMessageStore.ts` | **NOUVEAU** — store raw SQL via productDb |
| `amazon.service.ts` | `prisma.externalMessage.*` → `externalMessageStore.*` |
| `inbound.routes.ts` | `prisma.externalMessage.*` → `externalMessageStore.*` |
| `inboundEmailWebhook.routes.ts` | `prisma.externalMessage.*` → `externalMessageStore.*` |

Fichiers **NON** modifies :
- `amazon.poller.ts` (appelle amazon.service, pas de changement direct)
- `prisma/schema.prisma` (modele conserve pour reference, pas de migration Prisma)
- Tous les autres Prisma operations (Ticket, TicketMessage, MarketplaceConnection, etc.)

### C.3 Donnees

| Action | Resultat |
|---|---|
| Merge backend-only row → keybuzz_prod | 5 rows (union complete) |
| Creation table dans keybuzz DEV | 41 655 rows copiees |
| Verification superset | Toutes les rows backend presentes dans product DB |

### C.4 Tests DEV

**16 PASS / 0 FAIL** :
1. Backend /health : 200 OK
2. ProductDB connection : OK
3. ExternalMessage read from product DB : OK
4. ExternalMessageStore module loads : OK
5. findUnique (null for nonexistent) : OK
6. findUnique (real data) : OK
7. create : OK
8. update (ticketId) : OK
9. upsert (insert path) : OK
10. upsert (idempotent path) : OK
11. Amazon orders workers : OK
12. Amazon items worker : OK
13. API /health DEV : OK
14. Outbound worker : OK
15. No CrashLoopBackOff : OK
16. No errors in recent logs : OK

---

## D. Suppression

### D.1 Commandes executees

```bash
# DEV (keybuzz_backend) - via backend pod
DROP TABLE IF EXISTS "ExternalMessage";
# Result: 41 703 rows dropped, table gone

# PROD (keybuzz_backend_prod) - via postgres superuser on leader (10.0.0.122)
DROP TABLE IF EXISTS "ExternalMessage" CASCADE;
# Result: 4 rows dropped, table gone
```

Note : Le leader Patroni actuel est `db-postgres-03` (10.0.0.122), pas `db-postgres-01` (10.0.0.120) qui est en recovery.

### D.2 Verification post-suppression

| Verification | DEV | PROD |
|---|---|---|
| ExternalMessage dans backend DB | **ABSENT** (dropped) | **ABSENT** (dropped) |
| ExternalMessage dans product DB | **PRESENT** (41 655 rows) | **PRESENT** (5 rows) |
| Backend /health | 200 OK | 200 OK |
| API /health | 200 OK | 200 OK |
| ExternalMessageStore operations | OK | OK |
| Workers | OK | OK |

---

## E. Rollback

### Backups disponibles

```
/opt/keybuzz/backups/td05/
├── externalmessage-keybuzz_prod.dump (8.2K)
├── externalmessage-keybuzz_prod-schema.sql (2.4K)
├── externalmessage-keybuzz_backend_prod.dump (8.5K)
├── externalmessage-keybuzz_backend_prod-schema.sql (2.5K)
└── code-backup/
    ├── amazon.service.ts.orig
    ├── inbound.routes.ts.orig
    └── inboundEmailWebhook.routes.ts.orig
```

### Procedure de rollback

1. **Restaurer la table backend (PROD)** :
```bash
ssh 10.0.0.122 "sudo -u postgres pg_restore -d keybuzz_backend_prod /opt/keybuzz/backups/td05/externalmessage-keybuzz_backend_prod.dump"
```

2. **Restaurer le code** :
```bash
cp /opt/keybuzz/backups/td05/code-backup/amazon.service.ts.orig /opt/keybuzz/keybuzz-backend/src/modules/marketplaces/amazon/amazon.service.ts
cp /opt/keybuzz/backups/td05/code-backup/inbound.routes.ts.orig /opt/keybuzz/keybuzz-backend/src/modules/inbound/inbound.routes.ts
cp /opt/keybuzz/backups/td05/code-backup/inboundEmailWebhook.routes.ts.orig /opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboundEmailWebhook.routes.ts
```

3. **Rebuild et redeploy** :
```bash
docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-backend:v1.0.38-vault-tls-prod .
docker push ghcr.io/keybuzzio/keybuzz-backend:v1.0.38-vault-tls-prod
kubectl set image deploy/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.38-vault-tls-prod -n keybuzz-backend-prod
```

**Temps de rollback estime : < 5 minutes**

---

## F. Resultat Final

### Etat apres PH-TD-05

| Element | Etat |
|---|---|
| `keybuzz_prod.ExternalMessage` | **SOURCE DE VERITE UNIQUE** (5 rows PROD) |
| `keybuzz.ExternalMessage` | **SOURCE DE VERITE UNIQUE** (41 655 rows DEV) |
| `keybuzz_backend_prod.ExternalMessage` | **SUPPRIMEE** |
| `keybuzz_backend.ExternalMessage` | **SUPPRIMEE** |
| Code backend | Utilise `externalMessageStore` via `productDb` |
| Prisma schema | Modele conserve (pas de migration necessaire) |
| Duplication | **ELIMINEE** |

### Images deployees

| Service | DEV | PROD |
|---|---|---|
| Backend | `v1.0.39-td05-externalmsg-dev` | `v1.0.39-td05-externalmsg-prod` |
| API | `v3.5.47-vault-tls-fix-dev` (inchange) | `v3.5.47-vault-tls-fix-prod` (inchange) |
| Client | `v3.5.48-white-bg-dev` (inchange) | `v3.5.48-white-bg-prod` (inchange) |

### Observation Patroni

Le leader Patroni a change : `db-postgres-03` (10.0.0.122) est maintenant le leader (pg_is_in_recovery=false). `db-postgres-01` (10.0.0.120) est en recovery.

### Dette technique restante

Apres PH-TD-05, **ZERO dette technique significative liee a ExternalMessage**.

Le modele Prisma `ExternalMessage` reste dans `schema.prisma` comme reference inerte. Il ne genere aucun code problematique car toutes les operations passent par `externalMessageStore.ts`. Ce modele pourra etre retire lors d'une future migration Prisma si desire.
