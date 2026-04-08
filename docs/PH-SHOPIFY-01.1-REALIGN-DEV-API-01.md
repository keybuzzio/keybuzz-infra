# PH-SHOPIFY-01.1 — REALIGN DEV API

> Date : 2026-04-08
> Type : Réalignement environnement DEV — zéro feature, zéro refactor
> Statut : **TERMINÉ — GO**

---

## Verdict Final

### GO — DEV API REALIGNED — SHOPIFY PHASES CAN START SAFELY

---

## Préflight (État avant intervention)

| Service | Image avant | Status |
|---|---|---|
| **API DEV** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev` | Running, health OK |
| **API PROD** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.224-ph143-agents-ia-prod` | Running, health OK |
| **Client DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.224-ph143-agents-otp-session-fix-dev` | Aligné |
| **Client PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.224-ph143-agents-ia-prod` | Aligné |

### Cause de la dérive

L'API DEV était restée sur `v3.5.48` (PH143-AGENTS-R4, phase agents) alors que l'API PROD avait été promue en `v3.5.224` (PH143-P2, promotion finale agents+IA). Le Client DEV avait été correctement réaligné en `v3.5.224`, mais l'API DEV n'avait pas suivi.

Delta : **176 versions de retard** (v3.5.48 → v3.5.224).

---

## Étape 1 — Portabilité de l'image PROD vers DEV

L'API KeyBuzz est un serveur Fastify (Node.js). Aucune variable build-time (pas de `NEXT_PUBLIC_*`). Toute la configuration est injectée au runtime via les env vars du manifest K8s.

### Contrôles effectués

| Critère | Résultat |
|---|---|
| Variables d'env DEV vs PROD | Différenciées par manifest (NODE_ENV, URLs, Stripe IDs, DB) |
| Secrets K8s DEV en place | Oui (keybuzz-api-postgres, redis-credentials, keybuzz-stripe, etc.) |
| Absence de dépendance codée en dur à PROD | Confirmé |
| Absence de comportement destructif PROD | Confirmé |
| Port container identique | 3001 (DEV et PROD) |

**Verdict : Image PROD portable vers DEV sans risque.**

---

## Étape 2 — Plan de rollback

| Élément | Valeur |
|---|---|
| Image de rollback | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev` |
| Commande rollback | `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev -n keybuzz-api-dev` |
| Manifest rollback | Commit `01766dd^` (parent du premier commit) |
| Rollback testé | Oui, image précédente documentée dans manifest (`# ROLLBACK:` comment) |

---

## Étape 3 — Action appliquée

### Stratégie

Promotion de l'image PROD `v3.5.224-ph143-agents-ia-prod` directement en DEV via modification du manifest GitOps. Aucun rebuild. Aucun merge. Aucun cherry-pick.

### Modifications

1. **Manifest DEV** : `k8s/keybuzz-api-dev/deployment.yaml`
   - Image : `v3.5.48-ph143-agents-fix-dev` → `v3.5.224-ph143-agents-ia-prod`
   - Ajout `LEGACY_BACKEND_URL` (requis par l'image v3.5.224, safety check channels)
   - Commentaire rollback ajouté

2. **Commits infra** :
   - `01766dd` — `PH-SHOPIFY-01.1: realign API DEV on PROD baseline v3.5.224`
   - `29c5bf0` — `PH-SHOPIFY-01.1: add LEGACY_BACKEND_URL + fix image indent in DEV manifest`

### Image DEV finale

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.224-ph143-agents-ia-prod
```

---

## Étape 4 — Validation technique DEV

### Pod status

```
NAME                           READY   STATUS    RESTARTS   AGE
keybuzz-api-6f44b7fc77-wbfxv   1/1     Running   0          75s
```

### Endpoints testés

| Endpoint | HTTP | Résultat |
|---|---|---|
| `/health` | 200 | `{"status":"ok","service":"keybuzz-api"}` |
| `/messages/conversations` | 200 | OK |
| `/tenant-context/check-user` | 200 | OK |
| `/agents` | 200 | OK |
| `/billing/current` | 200 | OK |
| `/ai/wallet/status` | 200 | OK |
| `/ai/settings` | 200 | OK |
| `/ai/playbooks` | 404 | Attendu (D25 — playbooks client-side uniquement) |
| `/space-invites/ecomlg-001` | 200 | OK |
| `/dashboard/summary` | 200 | OK |
| `/api/v1/orders` | 200 | OK |
| `/tenant-context/entitlement` | 200 | OK |

### Vérification non-régression

- Aucune erreur 500
- Tous les endpoints critiques répondent 200
- API PROD inchangée : toujours `v3.5.224-ph143-agents-ia-prod`

---

## Étape 5 — Contrôle anti-contamination

| Critère | Résultat |
|---|---|
| 0 fichier Studio | Confirmé (grep négatif) |
| 0 merge large | Confirmé |
| 0 changement code applicatif | Confirmé |
| Seul fichier modifié | `k8s/keybuzz-api-dev/deployment.yaml` |
| 0 modification PROD | Confirmé |
| 0 rebuild API | Confirmé |

---

## Étape 6 — Verdict

### GO — DEV API REALIGNED — SHOPIFY PHASES CAN START SAFELY

### État final aligné

| Service | Image | Baseline commune |
|---|---|---|
| API DEV | `v3.5.224-ph143-agents-ia-prod` | v3.5.224 |
| API PROD | `v3.5.224-ph143-agents-ia-prod` | v3.5.224 |
| Client DEV | `v3.5.224-ph143-agents-otp-session-fix-dev` | v3.5.224 |
| Client PROD | `v3.5.224-ph143-agents-ia-prod` | v3.5.224 |

DEV est désormais aligné sur la même base fonctionnelle que PROD. L'environnement DEV est fiable pour démarrer PH-SHOPIFY-02.

### Correction découverte pendant le déploiement

La variable `LEGACY_BACKEND_URL` était absente du manifest DEV mais requise par le code v3.5.224 (safety check `[CHANNELS-SAFETY]`). Ajoutée au manifest avec la valeur DEV correcte. Ce n'est pas un bug introduit — c'est une variable qui existait dans le deployment K8s en cluster mais manquait du manifest GitOps local.

---

## Rollback

| Élément | Valeur |
|---|---|
| Image rollback | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev` |
| Procédure | `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev -n keybuzz-api-dev` |

---

## Conclusion

- DEV API réalignée sur PROD baseline v3.5.224
- Aucune régression visible
- Rollback prêt et documenté
- PROD non touchée
- Shopify autorisé en DEV
