# PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01.md`
> **Date** : 2026-04-22
> **Type** : Promotion PROD — route DELETE destinations outbound (soft delete)
> **Phase source** : PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01 (validée DEV)

---

## 1. RÉSUMÉ

Promotion en PROD de la route `DELETE /outbound-conversions/destinations/:id` avec soft delete.

Cette route débloque la suppression de destinations depuis l'Admin V2 via ConfirmModal.

---

## 2. PRÉFLIGHT

### API (bastion)

| Point | Valeur |
|-------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `df4a2c5e` |
| Repo clean | OUI |
| Commit poussé sur origin | OUI |

### Images avant promotion

| Env | Image |
|-----|-------|
| DEV (validée) | `v3.5.101-outbound-destinations-delete-route-dev` |
| DEV digest | `sha256:12f9d1fd7fb236282b15ef3e51e7aa334f9c359fac6f5a14897434e57f7afc5a` |
| PROD (avant) | `v3.5.100-meta-capi-error-sanitization-prod` |
| Admin DEV | `v2.11.2-meta-capi-ui-hardening-dev` |
| Admin PROD | `v2.11.0-tenant-foundation-prod` (inchangée) |

---

## 3. VÉRIFICATION SOURCE

| Point | Présent ? | Preuve |
|-------|-----------|--------|
| Colonnes `deleted_at`, `deleted_by` | OUI | L64-65 ALTER TABLE |
| Route `DELETE /:id` | OUI | L373 `app.delete` |
| Soft delete (deleted_at + deleted_by + is_active=false) | OUI | L391 UPDATE |
| GET list filtre `deleted_at IS NULL` | OUI | L132 |
| PATCH filtre `deleted_at IS NULL` | OUI | L208 |
| POST test filtre `deleted_at IS NULL` | OUI | L274 |
| Emitter filtre `deleted_at IS NULL` | OUI | emitter.ts L75 |
| Logs historiques préservés (pas de filtre) | OUI | L412-414 |
| Token sanitization (redactSecrets) | OUI | routes L5/313/433, meta-capi L1/126/131, emitter L4/231 |

---

## 4. BUILD PROD

| Paramètre | Valeur |
|-----------|--------|
| Tag | `v3.5.101-outbound-destinations-delete-route-prod` |
| Commit source | `df4a2c5e` |
| Build | `docker build --no-cache` |
| Digest | `sha256:bfac9f57ff79a9eaf83e53f9e88bdb3816c3a31456cdf97438465c984dc8c4f3` |

---

## 5. GITOPS PROD

| Étape | Détail |
|-------|--------|
| Fichier modifié | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-prod` |
| Commit infra | `776e910` |
| Push | `main` → `origin/main` |
| Apply | `kubectl apply -f deployment.yaml` |
| Méthode | GitOps strict (aucun `kubectl set image`) |

---

## 6. VALIDATION RUNTIME PROD

| Check | Résultat |
|-------|----------|
| Rollout | Succès (~21s) |
| Pod running | OUI (`keybuzz-api-7d6cf69d6d-ws4x9`) |
| Restarts | 0 |
| Image deployment | `v3.5.101-outbound-destinations-delete-route-prod` |
| Health API | `{"status":"ok"}` |

---

## 7. VALIDATION DELETE PROD

### A — Webhook

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Créer webhook | 201 | OK |
| Liste avant delete | Count = 4 | OK |
| DELETE | `{success:true, deleted:true}` | **OK** |
| Liste après delete | Count = 3 | **OK** (disparu) |
| Re-delete | 404 | **404** OK |

### B — Meta CAPI

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Créer meta_capi | Token masqué | **0 leak** |
| DELETE | `{success:true}`, pas de token | **0 leak** |
| Disparaît de la liste | 0 occurrences | **OK** |

### C — Cross-tenant

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Tenant A crée destination | OK | OK |
| Tenant B tente DELETE | 403 ou 404 | **403** |
| Destination tenant A intacte | OUI | OK (nettoyée ensuite) |

### D — Logs et token

| Cas | Résultat |
|-----|----------|
| Logs historiques conservés | OUI (pas de hard delete) |
| Token sanitization | `[REDACTED_TOKEN]` dans test endpoint |
| Aucun secret/token exposé | Confirmé |

---

## 8. NON-RÉGRESSION PROD

| Test | Résultat |
|------|----------|
| Health API | OK |
| GET destinations | OK |
| POST webhook | OK |
| POST meta_capi | OK |
| PATCH name | OK (`prod-nr-test-renamed`) |
| POST test Meta CAPI PageView | OK (failed + `REDACTED_TOKEN`) |
| Delivery logs | OK (1 log) |
| Metrics global | OK |
| Metrics tenant | OK |
| Tenant isolation | OK (`Insufficient permissions`) |
| Admin V2 PROD | **INCHANGÉ** (`v2.11.0-tenant-foundation-prod`) |

---

## 9. ROLLBACK GITOPS PROD

**Cible rollback** :
```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.100-meta-capi-error-sanitization-prod
```

**Procédure** :
1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
2. `git add && git commit && git push`
3. `kubectl apply -f deployment.yaml`
4. Aucun `kubectl set image`

---

## 10. HISTORIQUE IMAGES PROD

| Version | Tag | Phase |
|---------|-----|-------|
| v3.5.95 | outbound-destinations-api-prod | PH-T8.6C |
| v3.5.99 | meta-capi-test-endpoint-fix-prod | PH-T8.7B.2 |
| v3.5.100 | meta-capi-error-sanitization-prod | PH-T8.7B.3 |
| **v3.5.101** | **outbound-destinations-delete-route-prod** | **PH-T8.7B.4** (actuel) |

---

## 11. VERDICT FINAL

```
OUTBOUND DESTINATIONS DELETE ROUTE LIVE IN PROD
— SOFT DELETE TENANT-SCOPED
— ADMIN PROD PROMOTION UNBLOCKED
```
