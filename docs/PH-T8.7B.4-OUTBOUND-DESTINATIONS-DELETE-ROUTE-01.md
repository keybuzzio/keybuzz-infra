# PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01.md`
> **Date** : 2026-04-22
> **Type** : API fix — route DELETE destinations outbound (soft delete)
> **Environnement** : DEV uniquement
> **PROD** : INCHANGÉE (`v3.5.100-meta-capi-error-sanitization-prod`)

---

## 1. RÉSUMÉ

Implémentation de la route manquante `DELETE /outbound-conversions/destinations/:id` avec soft delete.

Cette route est requise par l'Admin V2 (`v2.11.2-meta-capi-ui-hardening-dev`) qui utilise un ConfirmModal pour supprimer des destinations. Sans cette route, l'Admin reçoit un 404.

---

## 2. PRÉFLIGHT

| Point | Valeur |
|-------|--------|
| Branche API | `ph147.4/source-of-truth` |
| HEAD avant | `f5d6793b` (PH-T8.7B.3) |
| Repo clean | OUI |
| Image DEV avant | `v3.5.100-meta-capi-error-sanitization-dev` |
| Image PROD | `v3.5.100-meta-capi-error-sanitization-prod` (inchangée) |
| Admin DEV | `v2.11.2-meta-capi-ui-hardening-dev` |

---

## 3. AUDIT ROUTES — DELETE ABSENT

| Route | Existait ? | Tenant-scoped ? | RBAC ? |
|-------|-----------|-----------------|--------|
| `GET /` (list) | OUI | OUI | OUI |
| `POST /` (create) | OUI | OUI | OUI |
| `PATCH /:id` (update) | OUI | OUI | OUI |
| `POST /:id/test` | OUI | OUI | OUI |
| `GET /:id/logs` | OUI | OUI | OUI |
| **`DELETE /:id`** | **NON** | — | — |

---

## 4. STRATÉGIE DELETE

**Choix : soft delete** (pas de hard delete)

Raisons :
- Les delivery logs historiques (`outbound_conversion_delivery_logs`) référencent `destination_id` — un hard delete casserait les références
- Le soft delete permet la récupération si nécessaire
- Cohérent avec les patterns existants du projet

### Schéma additif

```sql
ALTER TABLE outbound_conversion_destinations
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_by TEXT;
```

### Comportement DELETE

1. Vérifie `x-user-email`, `x-tenant-id`, RBAC
2. Vérifie que la destination existe et appartient au tenant (`tenant_id = $1 AND deleted_at IS NULL`)
3. Met à jour : `deleted_at = NOW()`, `deleted_by = email`, `is_active = false`
4. Retourne `{ success: true, deleted: true, id: "..." }`
5. Si déjà supprimée ou autre tenant → 404
6. Idempotent côté UX : première suppression = 200, re-suppression = 404

---

## 5. FICHIERS MODIFIÉS

| Fichier | Modification |
|---------|-------------|
| `src/modules/outbound-conversions/routes.ts` | Colonnes `deleted_at`/`deleted_by` dans ALTER TABLE |
| | Route `DELETE /:id` ajoutée (soft delete) |
| | `GET /` filtre `deleted_at IS NULL` |
| | `PATCH /:id` filtre `deleted_at IS NULL` (refuse dest supprimée) |
| | `POST /:id/test` filtre `deleted_at IS NULL` |
| | `GET /:id/logs` inchangé (logs historiques accessibles) |
| `src/modules/outbound-conversions/emitter.ts` | `getActiveDestinations()` filtre `deleted_at IS NULL` |

**Commit API** : `df4a2c5e` sur `ph147.4/source-of-truth`

---

## 6. VALIDATION DEV

### A — Webhook delete

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Créer webhook | 201 + id | OK |
| Liste avant delete | Count = N | OK (1) |
| DELETE | `{success:true, deleted:true}` | OK |
| Liste après delete | Count = N-1 | OK (0) |
| DELETE à nouveau | 404 | OK |

### B — Meta CAPI delete

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Créer meta_capi | Token masqué | OK (0 leak) |
| DELETE | `{success:true}`, pas de token | OK (0 leak) |
| Disparaît de la liste | 0 occurrences | OK |

### C — Cross-tenant

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Tenant A crée destination | OK | OK |
| Tenant B tente DELETE | 403 ou 404 | **403** (cross-tenant bloqué) |
| Destination tenant A intacte | Toujours dans la liste | OK (nettoyée ensuite) |

### D — RBAC

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Missing X-User-Email | 400 | **400** OK |
| Missing X-Tenant-Id | 400 | **400** OK |

---

## 7. NON-RÉGRESSION

| Test | Résultat |
|------|----------|
| Health API | OK |
| Test endpoint Meta CAPI | OK (failed + `REDACTED_TOKEN`) |
| Delivery logs | OK (1 log) |
| Token sanitization | OK |
| Metrics global | OK |
| PROD inchangée | OK (`v3.5.100-meta-capi-error-sanitization-prod`) |

---

## 8. BUILD ET DÉPLOIEMENT

| Paramètre | Valeur |
|-----------|--------|
| Tag DEV | `v3.5.101-outbound-destinations-delete-route-dev` |
| Commit source | `df4a2c5e` |
| Build | `docker build --no-cache` |
| Digest | `sha256:12f9d1fd7fb236282b15ef3e51e7aa334f9c359fac6f5a14897434e57f7afc5a` |
| Manifest | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| GitOps | `kubectl apply -f` (aucun `kubectl set image`) |
| Commit infra | `dd23202` |

---

## 9. ROLLBACK DEV

```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.100-meta-capi-error-sanitization-dev
```

Procédure : modifier manifest → commit + push → `kubectl apply -f`

---

## 10. IMPACT ADMIN V2 CONFIRMMODAL

L'Admin V2 (`v2.11.2-meta-capi-ui-hardening-dev`) peut désormais :
1. Cliquer "Supprimer" sur une destination
2. Confirmer via ConfirmModal
3. Appeler `DELETE /outbound-conversions/destinations/:id`
4. Recevoir une réponse 200 propre
5. La destination disparaît de la liste

Avant ce fix, l'Admin recevait un 404 et la suppression échouait.

---

## 11. VERDICT FINAL

```
OUTBOUND DESTINATIONS DELETE ROUTE READY IN DEV
— TENANT-SCOPED
— LOGS PRESERVED
— ADMIN CONFIRMMODAL UNBLOCKED
```
