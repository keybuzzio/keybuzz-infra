# PH-TD-01E — Legacy Table Cleanup — Rapport Final

> Date : 15 mars 2026
> Auteur : Agent Cursor
> Prérequis : PH-TD-01D (Post-Split Cleanup, même jour)
> Statut : **COMPLET — 3 TABLES LEGACY SUPPRIMÉES**

---

## 1. Résumé Exécutif

3 tables Prisma fantômes vides ont été supprimées de `keybuzz_prod` :

| Table | Rows | FK | Résultat |
|-------|------|----|----------|
| `MessageAttachment` | 0 | Aucune | **DROPPED** |
| `OrderItem` | 0 | FK sortante vers `Order` | **DROPPED** (avant Order) |
| `Order` | 0 | 1 FK entrante (OrderItem) | **DROPPED** (après OrderItem) |

`keybuzz_prod` : **87 → 84 tables**.

Seule table PascalCase restante : `ExternalMessage` (4 rows, données actives).

---

## 2. Vérifications Pré-Suppression

### Conditions de suppression (toutes remplies)

| Condition | Order | OrderItem | MessageAttachment |
|-----------|-------|-----------|-------------------|
| Table vide (0 rows) | 0 | 0 | 0 |
| Aucun code API (`grep`) | 0 refs | 0 refs | 0 refs |
| Aucun code backend (non-Prisma) | N/A | 0 refs | 0 refs |
| Aucun log runtime | 0 | 0 | 0 |
| FK entrantes | 1 (OrderItem) | 0 | 0 |
| Backup effectué | 1.77 MB | 1.77 MB | 1.77 MB |

### FK OrderItem → Order

`OrderItem` possède une FK `OrderItem_orderId_fkey` vers `Order`. L'ordre de suppression est donc :
1. `MessageAttachment` (aucune dépendance)
2. `OrderItem` (supprime la FK sortante)
3. `Order` (maintenant sans FK entrante)

---

## 3. Backup

| Fichier | Taille | Emplacement |
|---------|--------|-------------|
| `td01e-pre-20260315_185233.dump` | 1.77 MB | `/opt/keybuzz/backups/td01e/` |
| `td01e-schema-pre-20260315_185233.sql` | 193 KB | `/opt/keybuzz/backups/td01e/` |

### Commande de restauration

```bash
pg_restore -d keybuzz_prod /opt/keybuzz/backups/td01e/td01e-pre-20260315_185233.dump
```

Temps estimé de rollback : < 2 minutes.

---

## 4. Tests Post-Suppression

### db-integrity-check.sh : 20/20

| Test | Résultat |
|------|----------|
| Backend health | OK |
| API health | OK |
| Backend DB reachable (DATABASE_URL) | OK |
| Product DB reachable (PRODUCT_DATABASE_URL) | OK |
| pg.Pool() default → keybuzz_prod | OK |
| PascalCase Prisma tables in backend DB (≥25) | OK |
| ExternalMessage exists in backend DB | OK |
| Ticket exists in backend DB | OK |
| MarketplaceConnection exists in backend DB | OK |
| OAuthState exists in backend DB | OK |
| conversations exists in API DB | OK |
| messages exists in API DB | OK |
| orders exists in API DB | OK |
| tenants exists in API DB | OK |
| users exists in API DB | OK |
| DATABASE_URL ≠ PGDATABASE | OK |
| DATABASE_URL ≠ PRODUCT_DATABASE_URL | OK |
| _prisma_migrations present (≥1) | OK |
| amazon-orders-worker pod ready | OK |
| amazon-items-worker pod ready | OK |

### Runtime endpoints

| Endpoint | Résultat |
|----------|----------|
| API /health | HTTP 200 |
| Backend /health | HTTP 200 |
| Client accessible | HTTP 200/307 |
| conversations query | 193 rows |
| messages query | 704 rows |
| orders (snake_case) query | 5316 rows |
| billing_subscriptions | 2 rows |
| Backend Prisma DB | keybuzz_backend_prod |

### Workers

| Worker | Ready | Restarts | Errors |
|--------|-------|----------|--------|
| amazon-orders-worker | True | ≤1 | 0 |
| amazon-items-worker | True | ≤1 | 0 |
| outbound-worker | True | N/A | N/A |

---

## 5. Documentation Mise à Jour

| Fichier | Modification |
|---------|-------------|
| `DB-TABLE-MATRIX.md` | Tables marquées comme supprimées, count 87→84 |
| `DB-ARCHITECTURE-CONTRACT.md` | Section 4 mise à jour (legacy tables) |

---

## 6. État Final keybuzz_prod

### Tables PascalCase restantes : 1

| Table | Rows | Raison de conservation |
|-------|------|----------------------|
| `ExternalMessage` | 4 | Données actives, delta avec backend_prod |

### Tables snake_case : 83

Toutes les tables API sont intactes. Aucune modification de données.

### Tailles DB

| Base | Taille |
|------|--------|
| keybuzz_prod | 29 MB |
| keybuzz_backend_prod | 9.8 MB |
| keybuzz (DEV) | 105 MB |
| keybuzz_backend (DEV) | 82 MB |

---

## 7. Scripts

| Script | Usage |
|--------|-------|
| `scripts/td01e-step0-4-precheck.sh` | Backup + vérifications pré-suppression |
| `scripts/td01e-step5-drop.sh` | Suppression des 3 tables |
| `scripts/td01e-step6-8-verify.sh` | Vérification post-suppression |

---

## 8. Ce Qui N'a PAS Été Modifié

- Aucune table API (snake_case) touchée
- Aucune table dans `keybuzz_backend_prod` modifiée
- Aucun code applicatif modifié
- Aucune migration Prisma ajoutée
- Aucun service redéployé
- Workers et CronJobs inchangés
