# PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md`
> **Date** : 2026-04-22
> **Type** : Promotion PROD — sécurité — redaction tokens Meta
> **Phase source** : PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01 (validée DEV)

---

## 1. RÉSUMÉ

Promotion en PROD du fix sécurité PH-T8.7B.3 validé en DEV.

Ce fix garantit qu'aucun token Meta ne peut apparaître en clair dans :
- Les réponses API (test endpoint, erreurs Meta)
- Les delivery logs en base de données (`error_message`)
- La lecture API des delivery logs (defense in depth)
- Les logs pod Kubernetes
- Les erreurs retournées à l'Admin V2

---

## 2. PRÉFLIGHT

### API (bastion)

| Point | Valeur |
|-------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `f5d6793b` |
| Repo clean | OUI |
| Commit poussé sur origin | OUI (vérifié `origin/ph147.4/source-of-truth` = `f5d6793b`) |

### Images avant promotion

| Env | Image |
|-----|-------|
| DEV (validée) | `v3.5.100-meta-capi-error-sanitization-dev` |
| PROD (avant) | `v3.5.99-meta-capi-test-endpoint-fix-prod` |

### Clarification commits infra DEV

| Commit | Objet |
|--------|-------|
| `bd6a9de` | GitOps DEV — modification `deployment.yaml` DEV pour `v3.5.100` |
| `cba494c` | Ajout rapport DEV `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md` |

Les deux commits sont nécessaires et cohérents. `bd6a9de` = deploy, `cba494c` = rapport.

---

## 3. VÉRIFICATION SOURCE

| Surface | Redaction présente ? | Preuve |
|---------|---------------------|--------|
| `redact-secrets.ts` existant | OUI | Fichier 727 bytes, patterns EA*, access_token=, Bearer |
| `meta-capi.ts` — erreur Meta | OUI | L126: `redactSecrets(responseBody?.error?.message, accessToken)` |
| `meta-capi.ts` — erreur catch | OUI | L131: `redactSecrets(err.message?.substring(0, 200))` |
| `emitter.ts` — console.warn | OUI | L231: `redactSecrets(result.error, dest.platform_token_ref)` |
| `routes.ts` — errorMessage test | OUI | L311: `redactSecrets(result.error, d.platform_token_ref)` |
| `routes.ts` — delivery logs INSERT | OUI | Via L311 (errorMessage sanitisé avant INSERT L345) |
| `routes.ts` — LOGS endpoint lecture | OUI | L402-404: `sanitizedLogs` avec `redactSecrets(log.error_message)` |

---

## 4. BUILD PROD

| Paramètre | Valeur |
|-----------|--------|
| Tag | `v3.5.100-meta-capi-error-sanitization-prod` |
| Commit source | `f5d6793b` |
| Build | `docker build --no-cache` |
| Digest | `sha256:c7f6da86dda0726c0b35653e9dd01ca2ac506acaa6cf8d021fb39594c30e6cfc` |

---

## 5. GITOPS PROD

| Étape | Détail |
|-------|--------|
| Fichier modifié | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Image cible | `ghcr.io/keybuzzio/keybuzz-api:v3.5.100-meta-capi-error-sanitization-prod` |
| Commit infra | `7e67d58` |
| Push | `main` → `origin/main` |
| Apply | `kubectl apply -f deployment.yaml` |
| Méthode | GitOps strict (aucun `kubectl set image`) |

---

## 6. VALIDATION RUNTIME PROD

| Check | Résultat |
|-------|----------|
| Rollout | Succès (~20s) |
| Pod running | OUI (`keybuzz-api-5dc4c7cb67-fcpr2`) |
| Restarts | 0 |
| Image deployment | `v3.5.100-meta-capi-error-sanitization-prod` |
| Image pod | `v3.5.100-meta-capi-error-sanitization-prod` |
| Health API | `{"status":"ok"}` |

---

## 7. VALIDATION SÉCURITÉ PROD

Test avec destination Meta CAPI créée avec token invalide intentionnel.

| Surface | Token absent ? | Résultat |
|---------|---------------|----------|
| Réponse API `/test` | OUI | `"error": "Malformed access token [REDACTED_TOKEN]"` |
| Delivery logs DB `error_message` | OUI | `"Malformed access token [REDACTED_TOKEN]"` |
| API lecture logs `/logs` | OUI | Doublement sanitisé (DB + lecture) |
| Logs pod Kubernetes | OUI | 0 occurrences du token brut |
| CRUD destinations `platform_token_ref` | OUI | `EA****...on` (masqué) |
| `event_name` | — | `PageView` (non-régression PH-T8.7B.2) |

Destination de test désactivée après validation (`is_active: false`).

---

## 8. NON-RÉGRESSION PROD

| Test | Résultat |
|------|----------|
| Health API | OK |
| Metrics global | OK (`scope: global`) |
| Metrics tenant | OK |
| Destinations CRUD | OK |
| PATCH is_active | OK |
| Delivery logs | OK |
| Tenant isolation | OK (`Insufficient permissions`) |
| DEV inchangé | OK (`v3.5.100-meta-capi-error-sanitization-dev`) |
| Admin V2 | NON MODIFIÉ |

---

## 9. ROLLBACK GITOPS PROD

**Cible rollback** :
```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.99-meta-capi-test-endpoint-fix-prod
```

**Procédure** :
1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
2. `git add && git commit && git push`
3. `kubectl apply -f deployment.yaml`
4. Aucun `kubectl set image`

---

## 10. HISTORIQUE COMPLET DES IMAGES

| Version | Tag | Phase |
|---------|-----|-------|
| v3.5.95 | outbound-destinations-api-prod | PH-T8.6C-PROD |
| v3.5.99 | meta-capi-test-endpoint-fix-prod | PH-T8.7B.2-PROD |
| **v3.5.100** | **meta-capi-error-sanitization-prod** | **PH-T8.7B.3-PROD** (actuel) |

---

## 11. VERDICT FINAL

```
META CAPI TOKEN ERROR SANITIZED IN PROD
— NO TOKEN LEAK IN API RESPONSES OR DELIVERY LOGS
— ADMIN PROD UNBLOCKED
```
