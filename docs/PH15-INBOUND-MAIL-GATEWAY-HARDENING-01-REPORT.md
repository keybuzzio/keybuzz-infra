# PH15-INBOUND-MAIL-GATEWAY-HARDENING-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Audit et stabilisation de la gateway mail inbound existante. Le système était fonctionnel mais mal configuré :
- L'URL webhook pointait vers `platform-api.keybuzz.io` (obsolète)
- La variable `INBOUND_WEBHOOK_KEY` manquait dans le backend K8s

**Corrections apportées** :
1. Script webhook mis à jour pour pointer vers `backend-dev.keybuzz.io`
2. `INBOUND_WEBHOOK_KEY` ajouté au déploiement K8s
3. Spool local pour retry en cas de panne API
4. Logs structurés ajoutés

---

## 1. Architecture du Flux Inbound

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUX INBOUND EMAIL                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Amazon SES                                                    │
│        │                                                        │
│        ▼                                                        │
│   ┌─────────────────────┐                                       │
│   │ MX inbound.keybuzz.io │                                     │
│   │   mail-mx-01 (91.99.66.6)                                  │
│   │   mail-mx-02 (91.99.87.76)                                 │
│   └──────────┬──────────┘                                       │
│              │                                                  │
│              ▼                                                  │
│   ┌─────────────────────┐                                       │
│   │ mail-core-01         │                                      │
│   │ (49.13.35.167)       │                                      │
│   │                      │                                      │
│   │ Postfix transport:   │                                      │
│   │ inbound.keybuzz.io → webhook pipe                          │
│   └──────────┬──────────┘                                       │
│              │                                                  │
│              ▼                                                  │
│   ┌─────────────────────┐                                       │
│   │ /usr/local/bin/      │                                      │
│   │ postfix_webhook.sh   │                                      │
│   │                      │                                      │
│   │ Parse email → JSON   │                                      │
│   │ POST to backend      │                                      │
│   └──────────┬──────────┘                                       │
│              │                                                  │
│              ▼                                                  │
│   ┌─────────────────────┐                                       │
│   │ backend-dev.keybuzz.io                                     │
│   │ POST /api/v1/webhooks/inbound-email                        │
│   │                      │                                      │
│   │ Auth: X-Internal-Key │                                      │
│   │ Parse recipient      │                                      │
│   │ Update DB status     │                                      │
│   └──────────┬──────────┘                                       │
│              │                                                  │
│              ▼                                                  │
│   ┌─────────────────────┐                                       │
│   │ PostgreSQL           │                                      │
│   │ inbound_addresses    │                                      │
│   │ pipelineStatus=VALIDATED                                   │
│   │ lastInboundAt=NOW()  │                                      │
│   └─────────────────────┘                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Configuration DNS

| Enregistrement | Valeur |
|---------------|--------|
| MX inbound.keybuzz.io | 10 mail-mx-01.keybuzz.io (91.99.66.6) |
| | 20 mail-mx-02.keybuzz.io (91.99.87.76) |
| A inbound.keybuzz.io | 49.13.35.167 (mail-core-01) |

---

## 3. Configuration Postfix (mail-core-01)

### transport
```
inbound.keybuzz.io    webhook:
```

### master.cf
```
webhook   unix  -  n  n  -  -  pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh
```

---

## 4. Script Webhook

**Fichier** : `/usr/local/bin/postfix_webhook.sh`

**Fonctionnalités** :
- Parse email (From, To, Subject, Body)
- Génère JSON avec jq ou python3
- POST vers `backend-dev.keybuzz.io/api/v1/webhooks/inbound-email`
- Auth via `X-Internal-Key` header
- Logs structurés vers `/var/log/keybuzz/webhook.log`
- Spool local en cas d'échec API

**Format logs** :
```
INBOUND_RECEIVED from=... to=... messageId=...
INBOUND_POST_OK endpoint=... status=200
INBOUND_POST_FAIL endpoint=... status=500 error=...
INBOUND_SPOOLED file=...
```

---

## 5. Configuration Backend K8s

**Ajout effectué** :
```bash
kubectl -n keybuzz-backend-dev set env deployment/keybuzz-backend \
  INBOUND_WEBHOOK_KEY=e867f60b660a66...
```

---

## 6. Preuves E2E

### Réception Postfix
```
2026-01-08T17:37:35 mail-core-01 postfix/pipe[...]:
  to=<amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io>
  relay=webhook, delay=0.5
  status=sent (delivered via webhook service)
```

### POST API réussi
```
[2026-01-08 17:37:35] INBOUND_RECEIVED from=Cardoso... 
  to=amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io
[2026-01-08 17:37:35] INBOUND_POST_OK 
  endpoint=https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email 
  status=200
```

### Mise à jour DB
```sql
SELECT "emailAddress", "pipelineStatus", "lastInboundAt"
FROM inbound_addresses
WHERE "tenantId" = 'tenant_test_dev';

amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io | VALIDATED | 2026-01-08 17:37:36.248
```

---

## 7. Problème Résolu

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Emails en queue "deferred" | `INBOUND_WEBHOOK_KEY` manquant dans K8s | Ajout via `kubectl set env` |
| HTTP 500 "Internal server error" | URL obsolète `platform-api.keybuzz.io` | Script mis à jour vers `backend-dev` |
| Broken pipe sur mkdir | Permissions spool | Suppression chmod du script |

---

## 8. Points Faibles Restants

| Point | Risque | Recommandation PROD |
|-------|--------|---------------------|
| Clé en env var | Visible avec `kubectl describe` | Utiliser Secret K8s |
| Un seul mail-core | SPOF | Ajouter mail-core-02 en actif/passif |
| Spool local | Perdu si serveur tombe | Spool distribué ou backup régulier |
| Pas de dashboard | Manque visibilité | Créer dashboard Grafana dédié |

---

## 9. Fichiers Modifiés

| Fichier | Serveur |
|---------|---------|
| `/usr/local/bin/postfix_webhook.sh` | mail-core-01 |
| `/usr/local/bin/retry_spooled.sh` | mail-core-01 |
| `deployment/keybuzz-backend` env | K8s keybuzz-backend-dev |

---

## 10. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-backend | v1.0.3-dev (avec INBOUND_WEBHOOK_KEY) |
| postfix_webhook.sh | v2 (backend-dev + spool) |

---

**Fin du rapport PH15-INBOUND-MAIL-GATEWAY-HARDENING-01**
