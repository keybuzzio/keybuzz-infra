# PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md`
> **Date** : 2026-04-22
> **Type** : Sécurité — redaction tokens Meta dans erreurs et delivery logs
> **Environnement** : DEV uniquement
> **PROD** : INCHANGÉE (`v3.5.99-meta-capi-test-endpoint-fix-prod`)

---

## 1. RÉSUMÉ

Correction d'une fuite potentielle de token Meta dans les messages d'erreur.

Lorsque Meta retourne une erreur (ex: `Malformed access token`), le message d'erreur complet de Meta pouvait contenir le token en clair. Ce token se retrouvait alors dans :

- La réponse API (visible par l'Admin V2)
- Les delivery logs en base de données
- Les logs pod Kubernetes

Cette phase ajoute un helper de redaction centralisé qui supprime systématiquement tout token de type Meta (`EA...`) de toutes les surfaces de sortie.

---

## 2. PRÉFLIGHT


| Point           | Valeur                                                 |
| --------------- | ------------------------------------------------------ |
| Branche API     | `ph147.4/source-of-truth`                              |
| HEAD avant      | `9b461717`                                             |
| Repo clean      | OUI                                                    |
| Image DEV avant | `v3.5.99-meta-capi-test-endpoint-fix-dev`              |
| Image PROD      | `v3.5.99-meta-capi-test-endpoint-fix-prod` (inchangée) |


---

## 3. AUDIT FUITE TOKEN


| Surface                                              | Risque token                        | Correction                         |
| ---------------------------------------------------- | ----------------------------------- | ---------------------------------- |
| `meta-capi.ts` — `result.error` (Meta error message) | OUI — Meta inclut le token invalide | `redactSecrets()` avant return     |
| `meta-capi.ts` — `err.message` dans catch            | FAIBLE — possible si erreur réseau  | `redactSecrets()` defense in depth |
| `emitter.ts` — `console.warn(${result.error})`       | OUI — log pod direct                | `redactSecrets()` avant log        |
| `routes.ts` — test endpoint API response             | OUI — retourné au client/Admin      | `redactSecrets()` avant réponse    |
| `routes.ts` — delivery_logs INSERT `error_message`   | OUI — stocké en DB                  | `redactSecrets()` avant INSERT     |
| `routes.ts` — LOGS endpoint lecture `error_message`  | OUI — retourné depuis la DB         | `redactSecrets()` defense in depth |


---

## 4. HELPER DE REDACTION

**Fichier** : `src/modules/outbound-conversions/redact-secrets.ts`

**Patterns détectés** :

- Tokens Meta : `/\bEA[A-Za-z0-9_\-]{10,}\b/g`
- URL query : `/\baccess_token=[^\s&"']+/gi`
- Bearer : `/\bBearer\s+[A-Za-z0-9_\-\.]{10,}\b/gi`

**Fonctionnement** :

1. Si un `knownToken` est fourni (le token exact de la destination), il est supprimé en priorité
2. Les 3 patterns regex sont appliqués pour capturer tout token résiduel
3. Tous les matches sont remplacés par `[REDACTED_TOKEN]`

**Exemples de transformation** :

- `Malformed access token EAAtest...` → `Malformed access token [REDACTED_TOKEN]`
- `access_token=EAAXXX` → `[REDACTED_TOKEN]`
- `Bearer EAAXXX` → `[REDACTED_TOKEN]`
- `HTTP 400` → `HTTP 400` (pas de modification)

---

## 5. FICHIERS MODIFIÉS


| Fichier                                                  | Modification                                                        |
| -------------------------------------------------------- | ------------------------------------------------------------------- |
| `src/modules/outbound-conversions/redact-secrets.ts`     | **NOUVEAU** — helper centralisé de redaction                        |
| `src/modules/outbound-conversions/adapters/meta-capi.ts` | Import + `redactSecrets()` sur `result.error` et `err.message`      |
| `src/modules/outbound-conversions/emitter.ts`            | Import + `redactSecrets()` sur `console.warn`                       |
| `src/modules/outbound-conversions/routes.ts`             | Import + `redactSecrets()` sur errorMessage + sanitizedLogs mapping |


**Commit API** : `f5d6793b` sur `ph147.4/source-of-truth`

---

## 6. VALIDATION DEV

### Test endpoint (token invalide intentionnel)


| Surface                                    | Token absent ? | Détail                                               |
| ------------------------------------------ | -------------- | ---------------------------------------------------- |
| Réponse API `/destinations/:id/test`       | OUI            | `"error": "Malformed access token [REDACTED_TOKEN]"` |
| Delivery logs DB `error_message`           | OUI            | `"Malformed access token [REDACTED_TOKEN]"`          |
| Delivery logs API `/destinations/:id/logs` | OUI            | Doublement sanitisé (DB + lecture)                   |
| Pod logs Kubernetes                        | OUI            | 0 occurrences du token                               |
| `event_name` dans delivery logs            | —              | `PageView` (non-régression PH-T8.7B.2)               |
| Token masqué dans CRUD                     | OUI            | `EA****...ck` (non-régression PH-T8.7B)              |


---

## 7. NON-RÉGRESSION


| Test                    | Résultat                                        |
| ----------------------- | ----------------------------------------------- |
| Health API              | OK                                              |
| Metrics `scope=global`  | OK                                              |
| Destinations CRUD       | OK                                              |
| PATCH is_active         | OK                                              |
| Token masking CRUD      | OK (pattern `EA****...xx`)                      |
| PageView test Meta CAPI | OK                                              |
| Tenant isolation        | OK (`Insufficient permissions`)                 |
| PROD inchangée          | OK (`v3.5.99-meta-capi-test-endpoint-fix-prod`) |


---

## 8. BUILD ET DÉPLOIEMENT


| Paramètre     | Valeur                                                                    |
| ------------- | ------------------------------------------------------------------------- |
| Tag DEV       | `v3.5.100-meta-capi-error-sanitization-dev`                               |
| Commit source | `f5d6793b`                                                                |
| Build         | `docker build --no-cache`                                                 |
| Digest DEV    | `sha256:4f148176d26f65189d9550df0cf7bdd6bd6d811e4af6b5eb7bbf70ff3ae2987e` |
| Manifest      | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`                       |
| GitOps        | `kubectl apply -f` (aucun kubectl set image)                              |
| Commit infra  | `bd6a9de` sur `main`                                                      |
| Rollout       | Succès en ~21s                                                            |


---

## 9. ROLLBACK DEV

```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.99-meta-capi-test-endpoint-fix-dev
```

Procédure : modifier manifest → commit + push → `kubectl apply -f`

---

## 10. PROD

**INCHANGÉE** : `v3.5.99-meta-capi-test-endpoint-fix-prod`

---

## 11. VERDICT FINAL

```
META CAPI TOKEN ERROR SANITIZED IN DEV
— NO TOKEN LEAK IN API RESPONSES OR DELIVERY LOGS
— PROD UNTOUCHED
```

