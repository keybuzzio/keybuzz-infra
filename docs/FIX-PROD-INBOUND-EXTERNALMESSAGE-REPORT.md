# FIX: PROD Inbound Messages — Table ExternalMessage manquante

> Date du fix : 2026-03-14
> Auteur : Agent Cursor
> Environnement : PROD uniquement

---

## 1. Problème constaté

Les messages inbound (emails Amazon) n'arrivaient plus en PROD depuis le **13 mars 2026 à 09:33 UTC**.

- DEV continuait à recevoir normalement (200 OK)
- PROD retournait **500 Internal Server Error** sur chaque email entrant
- Le webhook Postfix (`postfix_webhook.sh`) poste aux DEUX backends (DEV + PROD)
- DEV acceptait, PROD refusait

## 2. Cause racine

La table Prisma `ExternalMessage` **n'existait pas** dans la base `keybuzz_prod`.

Le backend PROD (`v1.0.39-channels-safety-prod`) utilise cette table pour la **déduplication des messages** :

```
prisma.externalMessage.findUnique({
  where: { type_connectionId_externalId: { ... } }
})
```

Erreur exacte dans les logs PROD :
```
[Webhook] Error processing inbound email: PrismaClientKnownRequestError:
Invalid `prisma.externalMessage.findUnique()` invocation:
The table `public.ExternalMessage` does not exist in the current database.
```

### Pourquoi la table manquait

- Les migrations Prisma (`_prisma_migrations`) n'ont **jamais été exécutées** sur `keybuzz_prod`
- La base DEV (`keybuzz`) a cette table car les migrations Prisma y ont été appliquées
- Le backend a été mis à jour vers une version utilisant `ExternalMessage` sans migration PROD correspondante

## 3. Chronologie

| Date/heure | Événement |
|------------|-----------|
| 2026-03-12 | PROD fonctionne normalement (5 inbound, 6 outbound) |
| 2026-03-13 09:33 | **Premier 500 PROD** — `ExternalMessage` table not found |
| 2026-03-13 09:33 → 2026-03-14 09:35 | **Tous les emails PROD échouent** (500), DEV continue (200) |
| 2026-03-14 10:30 | **Fix appliqué** — table `ExternalMessage` créée en PROD |
| 2026-03-14 10:33 | **Verification** — Prisma query OK, 0 erreurs |

## 4. Fix appliqué

Création de la table `ExternalMessage` dans `keybuzz_prod` avec le schéma identique à DEV :

```sql
CREATE TABLE "ExternalMessage" (
  "id" TEXT NOT NULL,
  "tenantId" TEXT NOT NULL,
  "connectionId" TEXT NOT NULL,
  "type" "MarketplaceType" NOT NULL,
  "externalId" TEXT NOT NULL,
  "threadId" TEXT,
  "orderId" TEXT,
  "buyerName" TEXT,
  "buyerEmail" TEXT,
  "language" TEXT,
  "receivedAt" TIMESTAMP(3) NOT NULL,
  "raw" JSONB NOT NULL,
  "ticketId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ExternalMessage_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ExternalMessage_type_connectionId_externalId_key"
  ON "ExternalMessage" ("type", "connectionId", "externalId");

CREATE INDEX "ExternalMessage_tenantId_receivedAt_idx"
  ON "ExternalMessage" ("tenantId", "receivedAt");

CREATE INDEX "ExternalMessage_ticketId_idx"
  ON "ExternalMessage" ("ticketId");
```

L'enum `MarketplaceType` existait déjà en PROD (AMAZON, FNAC, CDISCOUNT, OTHER).

## 5. Vérification

| Test | Résultat |
|------|----------|
| `prisma.externalMessage.findMany({take:1})` | OK (0 rows) |
| `prisma.inboundAddress.findMany({take:1})` | OK (1 row) |
| `SELECT COUNT(*) FROM "ExternalMessage"` | 0 (table vide, prête) |
| Schema identique DEV ↔ PROD | 14 colonnes, 4 index |

## 6. Impact

- **Messages perdus en PROD** : Du 13 mars 09:33 au 14 mars 10:30 (~25h)
- **Messages en DEV** : Non impactés (continuaient à arriver)
- Les messages ne sont **pas perdus définitivement** — ils existent dans la DB DEV
- Le prochain email Amazon arrivant en PROD sera traité normalement

## 7. Autre problème détecté (non bloquant)

Le CronJob `outbound-tick-processor` en PROD appelle `POST /debug/outbound/tick` qui retourne **404** car `NODE_ENV=production` désactive les routes `/debug/*`.

```
Route POST:/debug/outbound/tick not found
```

Ce problème existait avant et est séparé du fix inbound. Il pourrait affecter le traitement des emails sortants si le outbound-worker n'a pas de mécanisme alternatif.

## 8. Tables Prisma PROD vs DEV — divergence connue

| Table Prisma (PascalCase) | Existe en DEV | Existe en PROD | Utilisée par inbound |
|---------------------------|:---:|:---:|:---:|
| `ExternalMessage` | oui | **oui (créée 14/03)** | **oui** |
| `MarketplaceConnection` | oui | **non** | non |
| `Ticket` | oui | non (conversations) | non |
| `TicketMessage` | oui | non (messages) | non |
| `InboundAddress` (→ `inbound_addresses`) | oui | oui | oui |
| `InboundConnection` (→ `inbound_connections`) | oui | oui | oui |

Seule `ExternalMessage` était nécessaire pour le webhook inbound.

## 9. Rollback

Si nécessaire, supprimer la table (mais cela re-casserait l'inbound) :
```sql
DROP TABLE IF EXISTS "ExternalMessage";
```

## 10. Recommandation

Mettre en place un process de migration Prisma automatisé pour PROD, ou au minimum vérifier que les tables Prisma nécessaires existent après chaque déploiement backend.
