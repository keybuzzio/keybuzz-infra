# 🔒 DEV GOLDEN FREEZE - PH26.6

**Date du gel:** 2026-02-01  
**Commit infra:** `4dca6eb85ece4ec6a1a003c6f70efb7b8d72d81d`  
**Status:** ✅ GELÉ

---

## ⚠️ RÈGLES DU GEL

### INTERDIT
- ❌ Aucune nouvelle feature sur DEV
- ❌ Aucun changement d'image K8s sans validation
- ❌ Aucune modification de configuration
- ❌ Aucun hotfix non critique

### AUTORISÉ
- ✅ Diagnostic et monitoring
- ✅ Documentation
- ✅ Préparation de la prochaine phase
- ✅ Hotfix critique (sécurité/data loss uniquement)

---

## 📦 VERSIONS GOLDEN (DEV)

### Services Principaux

| Service | Namespace | Image | Digest |
|---------|-----------|-------|--------|
| keybuzz-api | keybuzz-api-dev | `ghcr.io/keybuzzio/keybuzz-api:v1.0.40-guardrails` | `sha256:0fc2cdaf1c6bbc80e7b5e8b155963b9670c7a149ab75a57b8dea413c90049f6f` |
| keybuzz-client | keybuzz-client-dev | `ghcr.io/keybuzzio/keybuzz-client:v0.5.26-all-messages` | `sha256:bc2a18f05d04320ef953e8db38642d110c13bd30acbea541bd9cdcca4546e2fd` |
| keybuzz-admin | keybuzz-admin-dev | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.3-ws` | `sha256:1f8f171bec41a0c3aace3dbccb7840cdf9dbea6923d5a507090d91c7f71b86c0` |
| keybuzz-backend | keybuzz-backend-dev | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph265l` | *(voir GHCR)* |

### Workers

| Worker | Namespace | Image |
|--------|-----------|-------|
| keybuzz-outbound-worker | keybuzz-api-dev | `ghcr.io/keybuzzio/keybuzz-api:v0.1.106-smtp-unified` |
| amazon-items-worker | keybuzz-backend-dev | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` |
| amazon-orders-worker | keybuzz-backend-dev | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` |

---

## 🔗 ENDPOINTS HEALTH

| Endpoint | Status | Response |
|----------|--------|----------|
| https://api-dev.keybuzz.io/health | ✅ OK | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| https://backend-dev.keybuzz.io/health | ✅ OK | `{"status":"ok","version":"0.1.0"}` |
| https://client-dev.keybuzz.io/debug/version | ✅ OK | `{"version":"0.5.10-channels-polish"}` |
| https://admin-dev.keybuzz.io/debug/version | ✅ OK | `{"version":"1.0.57"}` |

---

## ✅ CHECKLIST DE VALIDATION (5 min)

```bash
# 1. Health checks (30s)
curl -s https://api-dev.keybuzz.io/health | jq .status
curl -s https://backend-dev.keybuzz.io/health | jq .status
curl -s https://client-dev.keybuzz.io/debug/version | jq .version
curl -s https://admin-dev.keybuzz.io/debug/version | jq .version

# 2. Pods running (30s)
kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client
kubectl get pods -n keybuzz-admin-dev -l app=keybuzz-admin
kubectl get pods -n keybuzz-backend-dev -l app=keybuzz-backend

# 3. Images match golden (1min)
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
# Attendu: ghcr.io/keybuzzio/keybuzz-api:v1.0.39-lang-strong

kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
# Attendu: ghcr.io/keybuzzio/keybuzz-client:v0.5.26-all-messages

# 4. Test fonctionnel rapide (3min)
# - Ouvrir https://client-dev.keybuzz.io/inbox
# - Vérifier qu'une conversation s'affiche
# - Générer une suggestion IA
# - Envoyer un message et vérifier le formatage
```

---

## 🚨 PROCÉDURE DE HOTFIX CRITIQUE

Si un hotfix critique est nécessaire :

1. **Créer une branche** `hotfix/ph26.6-xxx`
2. **Documenter** la raison dans ce fichier
3. **Tester** en local avant déploiement
4. **Incrémenter** le tag (ex: `v1.0.39-lang-strong` → `v1.0.40-hotfix-xxx`)
5. **Mettre à jour** ce document avec le nouveau digest
6. **Commit** dans keybuzz-infra avec référence au hotfix

---

## 📝 HISTORIQUE DES MODIFICATIONS POST-GEL

| Date | Tag | Raison | Approuvé par |
|------|-----|--------|--------------|
| 2026-02-01 | v1.0.40-guardrails | PH26.7 IA Guardrails Anti-Refus | Ludovic |

---

**Responsable du gel:** Système automatique PH26.6  
**Prochaine revue:** Après validation complète de PH26.6
