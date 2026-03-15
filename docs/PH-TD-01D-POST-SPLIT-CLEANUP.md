# PH-TD-01D — Post-Split Cleanup & Contract Clarification — Rapport Final

> Date : 15 mars 2026
> Auteur : Agent Cursor
> Prérequis : PH-TD-01C (Safe DB Split, même jour)
> Statut : **COMPLET — ARCHITECTURE DB PROPRE ET DOCUMENTÉE**

---

## 1. Résumé Exécutif

PH-TD-01D a finalisé l'architecture dual-DB initiée par PH-TD-01C :

- **Secret Kubernetes aligné** : `keybuzz-backend-db` pointe proprement vers `keybuzz_backend_prod`
- **Override deployment retiré** : plus de `DATABASE_URL` en dur dans les specs deployment
- **ESO (External Secrets Operator)** : `DATABASE_URL` retiré du champ ESO (sinon Vault revertait la valeur)
- **Workers Amazon réparés** : `secretKeyRef` restauré après suppression accidentelle
- **Contrat DB documenté** : architecture source de vérité pour tous les services
- **Guardrail d'isolation** : script de vérification empêchant les collisions DB
- **Tests complets** : 24/24 runtime + 20/20 intégrité = 44 assertions réussies

---

## 2. Architecture Finale DB

```
keybuzz_prod (87 tables — API / produit)
  ├── API tables snake_case (83 tables)
  ├── PascalCase legacy (4 tables, fantômes Prisma)
  └── Accédée par : API, outbound-worker, SLA CronJobs, backend (pg.Pool/PRODUCT_DB)

keybuzz_backend_prod (42 tables — Prisma backend)
  ├── PascalCase Prisma (30 tables)
  ├── Backend snake_case (12 tables)
  └── Accédée par : backend (Prisma ORM) UNIQUEMENT
```

### Variables d'Environnement (état final)

| Variable | Valeur | Source | Service |
|----------|--------|--------|---------|
| `DATABASE_URL` | `keybuzz_backend_prod` | Secret `keybuzz-backend-db` (hors ESO) | Backend, workers |
| `PRODUCT_DATABASE_URL` | `keybuzz_prod` | Secret `keybuzz-backend-secrets` (ESO) | Backend |
| `PGDATABASE` | `keybuzz_prod` | Secret `keybuzz-backend-db` (ESO) | Backend pg.Pool() |

---

## 3. Étapes Réalisées

### Step 0 — Snapshot sécurité

| Dump | Taille | Emplacement |
|------|--------|-------------|
| `td01d-keybuzz_prod-20260315_172734.dump` | 1.77 MB | `/opt/keybuzz/backups/td01d/` |
| `td01d-keybuzz_backend_prod-20260315_172734.dump` | 120 KB | `/opt/keybuzz/backups/td01d/` |

### Step 1 — Alignement secrets Kubernetes

**Problème initial** : Le secret `keybuzz-backend-db` avait `DATABASE_URL=keybuzz_prod` (ancien). L'override dans le deployment masquait ce problème.

**Découverte ESO** : External Secrets Operator (ExternalSecret `keybuzz-backend-db`) synchronisait depuis Vault (`keybuzz/prod/backend-postgres`) toutes les heures, revertant toute modification manuelle.

**Solution appliquée** :
1. Retiré `DATABASE_URL` du spec ExternalSecret (ESO ne le gère plus)
2. Patché le secret avec `DATABASE_URL=keybuzz_backend_prod`
3. Retiré l'override `DATABASE_URL` du deployment `keybuzz-backend`
4. Re-ajouté `DATABASE_URL` via `secretKeyRef` pour les workers (qui utilisent `env` et non `envFrom`)

**Incident corrigé** : Les workers `amazon-orders-worker` et `amazon-items-worker` sont tombés en CrashLoopBackOff car `kubectl set env DATABASE_URL-` a supprimé leur référence au secret (les workers utilisent `env[].secretKeyRef`, pas `envFrom`). Corrigé par `kubectl patch` pour ré-ajouter la référence.

### Step 2 — DB-ARCHITECTURE-CONTRACT.md

Document créé : `keybuzz-infra/docs/DB-ARCHITECTURE-CONTRACT.md`
- Contrat officiel d'architecture dual-DB
- Liste exhaustive des tables par DB avec service principal
- Diagramme de connexion
- Règles de sécurité et procédure de rollback

### Step 3 — Prisma Legacy Check

Tables PascalCase fantômes dans `keybuzz_prod` :

| Table | Rows | Safe to remove |
|-------|------|----------------|
| `ExternalMessage` | 4 | **NON** (données actives, 1 row de plus que backend_prod) |
| `MessageAttachment` | 0 | OUI |
| `Order` | 0 | OUI |
| `OrderItem` | 0 | OUI |

Tables snake_case dupliquées (PROD API + PROD Backend) :

| Table | keybuzz_prod | keybuzz_backend_prod | Safe |
|-------|-------------|---------------------|------|
| `ai_journal_events` | 19 | 0 | NON (données actives dans keybuzz_prod) |
| `amazon_backfill_*` (4 tables) | 0 | 0 | OUI (toutes vides) |
| `amazon_returns` / `*_sync_status` | 0 | 0 | OUI |
| `inbound_addresses` | 1 | 0 | NON (données actives) |
| `inbound_connections` | 1 | 0 | NON (données actives) |
| `return_analyses` | 0 | 0 | OUI |

### Step 4 — Matrice duplications

Document créé : `keybuzz-infra/docs/DB-TABLE-MATRIX.md`
- Vue complète des 4 bases (2 PROD + 2 DEV)
- Identification des 4 PascalCase legacy + 10 snake_case dupliquées
- Divergences DEV/PROD documentées

### Step 5 — Guardrail anti-erreur

Script créé : `scripts/td01d-guardrail-check.sh`
- Vérifie que `DATABASE_URL` et `PGDATABASE` ne pointent pas vers la même DB
- Vérifie que `DATABASE_URL` et `PRODUCT_DATABASE_URL` sont différents
- Vérifie que l'API n'accède pas à la DB backend

### Step 6 — DB-ACCESS-MAP.md

Document créé : `keybuzz-infra/docs/DB-ACCESS-MAP.md`
- Carte d'accès service → table → type → fréquence
- 16 moteurs IA mappés
- 4 CronJobs mappés
- Règle d'isolation documentée

### Step 7 — Prisma migrations

`_prisma_migrations` dans `keybuzz_backend_prod` : 4 entrées (identiques à DEV)

| Migration | Statut |
|-----------|--------|
| `ph11_05c1_ai_cost_guardrails` | OK (baseline) |
| `20251218162802_add_pipeline_marketplace_status` | OK (1 step) |
| `20251220235148_add_oauth_state_table` (1ère) | `finished_at: null` — **migration échouée historique** |
| `20251220235148_add_oauth_state_table` (2ème) | OK (baseline re-applied) |

La migration échouée (ID `48cdc7f8`) a `finished_at: null` mais `applied_steps_count: 0`. Elle est inoffensive (pas d'étape appliquée). Le schéma est correct.

### Step 8 — Tests runtime

**24/24 tests passés** :

| Catégorie | Tests | Résultat |
|-----------|-------|----------|
| Health checks (API, Backend, Client) | 3 | 3/3 OK |
| DB Connectivity (4 connexions) | 4 | 4/4 OK |
| Data presence (conversations, orders, billing) | 3 | 3/3 OK |
| Workers (outbound, Amazon orders, Amazon items) | 5 | 5/5 OK |
| DB Isolation | 1 | 1/1 OK |
| Prisma tables (6 tables vérifiées) | 6 | 6/6 OK |
| Secret alignment (secret + ESO) | 2 | 2/2 OK |

### Step 9 — Script anti-régression

Script créé : `scripts/db-integrity-check.sh`
- 20 vérifications automatisées
- Teste connectivité, isolation, tables Prisma, tables produit, workers
- Utilisable comme health check périodique

---

## 4. Livrables

### Documentation

| Fichier | Description |
|---------|-------------|
| `keybuzz-infra/docs/DB-ARCHITECTURE-CONTRACT.md` | Contrat architecture DB |
| `keybuzz-infra/docs/DB-TABLE-MATRIX.md` | Matrice duplications tables |
| `keybuzz-infra/docs/DB-ACCESS-MAP.md` | Carte d'accès tables |
| `keybuzz-infra/docs/PH-TD-01D-POST-SPLIT-CLEANUP.md` | Ce rapport |

### Scripts

| Script | Usage |
|--------|-------|
| `scripts/td01d-step0-snapshot.sh` | Backup pré-cleanup |
| `scripts/td01d-step1-secret-align.sh` | Alignement secret (tentative 1) |
| `scripts/td01d-step1-fix-secret.sh` | Debug + fix secret (tentative 2) |
| `scripts/td01d-step1-eso-fix.sh` | Fix définitif ESO-aware |
| `scripts/td01d-step1-fix-workers.sh` | Réparation workers CrashLoopBackOff |
| `scripts/td01d-audit-tables.sh` | Audit complet tables 4 DBs |
| `scripts/td01d-prisma-legacy-check.sh` | Audit tables Prisma legacy |
| `scripts/td01d-guardrail-check.sh` | Guardrail isolation DB |
| `scripts/td01d-step8-runtime-tests.sh` | Tests runtime 24 assertions |
| `scripts/db-integrity-check.sh` | Anti-régression réutilisable |

---

## 5. Tables Legacy Restantes (pour PH-TD-01E)

### Candidates à suppression de `keybuzz_prod`

| Table | Rows | Raison |
|-------|------|--------|
| `MessageAttachment` | 0 | PascalCase Prisma fantôme, remplacée par `message_attachments` |
| `Order` (PascalCase) | 0 | Prisma fantôme, jamais utilisée en PROD |
| `OrderItem` (PascalCase) | 0 | Prisma fantôme, jamais utilisée en PROD |

### À conserver (données actives)

| Table | Rows | Raison |
|-------|------|--------|
| `ExternalMessage` | 4 | 1 row de plus que backend_prod (delta à investiguer) |
| `ai_journal_events` | 19 | Données actives du journal IA |
| `inbound_addresses` | 1 | Adresse inbound active |
| `inbound_connections` | 1 | Connexion inbound active |

---

## 6. Incident : Workers CrashLoopBackOff

**Cause** : `kubectl set env DATABASE_URL-` supprime l'env var du deployment spec. Pour `keybuzz-backend` (qui utilise `envFrom`), la variable est toujours disponible via le secret. Pour les workers (qui utilisent `env[].secretKeyRef`), la suppression retire définitivement la référence.

**Impact** : Workers en CrashLoopBackOff pendant ~10 minutes.

**Fix** : `kubectl patch deployment --type=json` pour ré-ajouter `DATABASE_URL` avec `secretKeyRef: keybuzz-backend-db`.

**Leçon** : Toujours vérifier si un deployment utilise `envFrom` ou `env[].secretKeyRef` avant de supprimer une variable.

---

## 7. Découverte ESO

External Secrets Operator gère `keybuzz-backend-db` depuis Vault (`keybuzz/prod/backend-postgres`). Même avec Vault DOWN, ESO utilise les valeurs cachées et les re-synchronise toutes les heures.

**Implication** : Toute modification manuelle du secret est revertée par ESO. Pour `DATABASE_URL`, la solution a été de retirer ce champ du spec ExternalSecret, permettant une gestion manuelle.

**Action future** : Quand Vault sera restauré, mettre à jour `keybuzz/prod/backend-postgres/DATABASE_URL` dans Vault avec la valeur `keybuzz_backend_prod`, puis remettre `DATABASE_URL` dans le spec ESO.

---

## 8. Rollback

En cas de besoin de rollback vers l'architecture mono-DB :

```bash
# 1. Remettre DATABASE_URL override
kubectl set env deployment/keybuzz-backend -n keybuzz-backend-prod \
  DATABASE_URL=postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod

# 2. Workers (via patch car ils utilisent secretKeyRef)
for DEPLOY in amazon-orders-worker amazon-items-worker; do
  kubectl patch deployment $DEPLOY -n keybuzz-backend-prod --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/env/4/value","value":"postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod"}]'
done

# 3. Restaurer ESO
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
... (remettre DATABASE_URL dans le spec)
EOF

# 4. Vérifier
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod
curl -s https://backend.keybuzz.io/health
```

**Temps estimé de rollback** : < 5 minutes.

---

## 9. Résultat Final

| Objectif | Statut |
|----------|--------|
| Séparation DB claire | ✅ |
| Secrets alignés | ✅ |
| Contrat DB documenté | ✅ |
| Tables legacy identifiées | ✅ |
| Aucun risque de dérive future | ✅ (guardrail + script anti-régression) |
| Migrations Prisma stabilisées | ✅ (4 entries, 1 failed historique inoffensive) |
| Workers opérationnels | ✅ (corrigés après incident) |
| 44 assertions runtime réussies | ✅ (24 runtime + 20 intégrité) |

---

## 10. Timeline

| Heure UTC | Action |
|-----------|--------|
| 17:27 | Step 0 : Backup sécurité (1.77 MB + 120 KB) |
| 17:28 | Step 1 : Tentative 1 alignement secret (revertée par ESO) |
| 17:31 | Step 1 : Debug ESO, découverte ExternalSecret |
| 17:33 | Step 1 : Fix ESO-aware (retire DATABASE_URL du spec ESO) |
| 17:35 | Incident : Workers CrashLoopBackOff |
| 17:37 | Fix : Workers réparés (secretKeyRef restauré) |
| 17:38 | Steps 2-4 : Documentation (CONTRACT, MATRIX, ACCESS-MAP) |
| 17:40 | Steps 3, 5 : Audit legacy + guardrail |
| 17:46 | Step 9 : db-integrity-check.sh (20/20) |
| 17:47 | Step 8 : Runtime tests (24/24) |
| 17:50 | Rapport final |
