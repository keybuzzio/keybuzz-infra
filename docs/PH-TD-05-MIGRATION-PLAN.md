# PH-TD-05 — Migration Plan: ExternalMessage Single Source of Truth

> Date: 2026-03-15
> Phase: PH-TD-05
> Auteur: Cursor Agent
> Status: PLAN — En attente d'execution

---

## 1. Hypothese de Source de Verite

**`keybuzz_prod.ExternalMessage`** = source de verite unique.

Justification :
- `keybuzz_prod` est la DB produit (API Fastify)
- L'API est le systeme principal (conversations, messages, orders)
- Le backend Python/TS est un service auxiliaire (workers, pollers)
- `ExternalMessage` contient des messages marketplace lies aux conversations (qui vivent dans `keybuzz_prod`)
- Le backend a deja un pool `productDb` vers `keybuzz_prod` pour les conversations

## 2. Etat Actuel (Audit 2026-03-15)

### 2.1 Schemas

| Propriete | keybuzz_prod | keybuzz_backend_prod | Identique |
|---|---|---|---|
| Colonnes | 14 | 14 | OUI |
| Types | identiques | identiques | OUI |
| PK | id (text) | id (text) | OUI |
| Index 1 | tenantId + receivedAt | tenantId + receivedAt | OUI |
| Index 2 | ticketId | ticketId | OUI |
| Unique | type + connectionId + externalId | type + connectionId + externalId | OUI |
| Owner | keybuzz_api_prod | kb_backend | DIFF (attendu) |

### 2.2 Donnees

| DB | Rows | IDs |
|---|---|---|
| keybuzz_prod | 4 | cmmqb5b85, cmmqutxgb, cmmr5p9et, cmmrzdav2 |
| keybuzz_backend_prod | 4 | cmmqb5b85, cmmqutxgb, cmmr5p9et, cmms1je7n |

**Delta :**
- 3 rows identiques (meme id, meme externalId, meme createdAt)
- 1 row PROD-only : `0102019cf25e93cf...` (Mar 15 16:40)
- 1 row BACKEND-only : `0102019cf296321f...` (Mar 15 17:40)

=> La divergence est ACTIVE et confirme la necessite de l'unification.

### 2.3 Chemins Code (Audit)

| Fichier | Operation | DB | Import |
|---|---|---|---|
| `amazon.service.ts` → `upsertExternalMessage()` | upsert (write) | `prisma` → backend_prod | `from "../../lib/db"` |
| `amazon.service.ts` → `mapExternalMessageToTicket()` | read + update | `prisma` → backend_prod | `from "../../lib/db"` |
| `amazon.poller.ts` | appelle upsert + map | `prisma` → backend_prod | via amazon.service |
| `inbound.routes.ts` | findUnique + create + update | `prisma` → backend_prod | `from "../../lib/db"` |
| `inboundEmailWebhook.routes.ts` | findUnique + create | `prisma` → backend_prod | `from "../../lib/db"` |
| `inboxConversation.service.ts` | PAS d'ExternalMessage | `productDb` → prod | N/A |
| `keybuzz-api/src/` | AUCUN usage | N/A | N/A |

**Conclusion** : 4 fichiers backend utilisent `prisma.externalMessage.*`, tous via `keybuzz_backend_prod`. L'API n'utilise PAS ExternalMessage.

## 3. Plan de Migration (10 etapes)

### Etape 0 : Ce plan (fait)

### Etape 1 : Backups
- `pg_dump -Fc` des deux tables
- `pg_dump -s` des schemas
- Localisation : `/opt/keybuzz/backups/td05/`
- **Status : FAIT** (4 fichiers, ~32K total)

### Etape 2 : Audit structurel
- Comparaison colonnes, types, indexes, contraintes
- **Status : FAIT** — schemas identiques

### Etape 3 : Merge donnees
- Copier la row backend-only vers `keybuzz_prod`
- Verifier que `keybuzz_prod` contient TOUTES les rows (5 total)
- Ne PAS supprimer la row prod-only de `keybuzz_prod`

### Etape 4 : Audit code (fait)
- 4 fichiers a modifier
- Tous utilisent `prisma.externalMessage.*`
- Remplacement par `productDb` (raw SQL via pg Pool)

### Etape 5 : Bascule code
Creer `src/lib/externalMessageStore.ts` :
- `findUnique(type, connectionId, externalId)` → SELECT via `productDb`
- `upsert(data)` → INSERT ON CONFLICT via `productDb`
- `create(data)` → INSERT via `productDb`
- `update(id, data)` → UPDATE via `productDb`

Modifier les 4 fichiers :
1. `amazon.service.ts` : remplacer `prisma.externalMessage.*` par store
2. `inbound.routes.ts` : remplacer `prisma.externalMessage.*` par store
3. `inboundEmailWebhook.routes.ts` : remplacer `prisma.externalMessage.*` par store
4. `amazon.poller.ts` : aucun changement direct (appelle amazon.service)

Ne PAS modifier :
- Le modele Prisma (garder pour reference, pas de migration Prisma)
- Les autres operations Prisma (ticket, ticketMessage, etc.)
- Les workers non concernes

### Etape 6 : Tests avant suppression
- Backend health OK
- Webhook inbound OK
- Amazon poller OK
- Nouvelle ecriture dans `keybuzz_prod.ExternalMessage`
- Aucune ecriture dans `keybuzz_backend_prod.ExternalMessage`
- Workers OK

### Etape 7 : Observation
- Logs backend (erreurs Prisma, erreurs SQL)
- Verifier inserts dans keybuzz_prod

### Etape 8 : Suppression table backend
- `DROP TABLE IF EXISTS "ExternalMessage"` dans `keybuzz_backend_prod`
- Jamais dans `keybuzz_prod`

### Etape 9 : Guardrails
- Mettre a jour `db-architecture-check.sh`
- Mettre a jour `DB-ARCHITECTURE-CONTRACT.md`

### Etape 10 : Tests finaux + rapport

## 4. Rollback

### Avant bascule code
- Rien a faire (code inchange)

### Apres bascule code, avant suppression table
- Remettre ancien code (`prisma.externalMessage.*`)
- Redeployer image precedente

### Apres suppression table
```bash
# Restaurer la table dans keybuzz_backend_prod
ssh 10.0.0.120 "sudo -u postgres pg_restore -d keybuzz_backend_prod /opt/keybuzz/backups/td05/externalmessage-keybuzz_backend_prod.dump"
# Remettre ancien code + redeployer
```

**Temps de rollback vise : < 5 minutes**

## 5. Version / Tag

Si code backend modifie :
- DEV : `v1.0.39-td05-externalmessage-unification-dev`
- PROD : `v1.0.39-td05-externalmessage-unification-prod`

Aucune autre image modifiee (API, Client, Workers Amazon inchanges).
