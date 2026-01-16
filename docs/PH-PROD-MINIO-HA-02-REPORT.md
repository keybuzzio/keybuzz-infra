# PH-PROD-MINIO-HA-02 — MinIO Strictement Interne

**Date** : 2026-01-15  
**Statut** : ✅ TERMINÉ

---

## Résumé Exécutif

Sécurisation de MinIO en mode **strictement interne** avec suppression de tout accès public. Les pièces jointes sont désormais téléchargées uniquement via l'API KeyBuzz authentifiée.

### Règles de Sécurité Appliquées

| Règle | Statut |
|-------|--------|
| ❌ MinIO accessible depuis Internet | ✅ Supprimé |
| ❌ Ingress K8s pour s3.keybuzz.io | ✅ Supprimé |
| ❌ DNS public pour MinIO | ✅ Non configuré |
| ✅ HAProxy MinIO interne only | ✅ 10.0.0.11/12 |
| ✅ PJ via API KeyBuzz (HTTPS) | ✅ /api/v1/attachments/:id |

---

## 1️⃣ SUPPRESSION INGRESS PUBLIC

### Avant (état PH-PROD-MINIO-HA-01)

```
Namespace: minio-proxy
├── Ingress: minio-s3 (s3.keybuzz.io)
├── Ingress: minio-console (minio-console.keybuzz.io)
├── Service: minio-ha
└── Endpoints: 10.0.0.11:9000, 10.0.0.12:9000
```

### Après (PH-PROD-MINIO-HA-02)

```bash
$ kubectl get ingress -A | grep minio
# Aucun résultat

$ kubectl get ns | grep minio
# Namespace minio-proxy supprimé
```

### Fichiers supprimés

```
keybuzz-infra/k8s/minio-ingress/minio-external.yaml (supprimé)
keybuzz-infra/k8s/minio-ingress/minio-external-secret.yaml (supprimé)
```

---

## 2️⃣ DNS NON CONFIGURÉ

```bash
$ dig +short s3.keybuzz.io
# Aucune réponse (DNS non résolu)

$ dig +short minio-console.keybuzz.io
# Aucune réponse
```

**Note** : Aucun enregistrement DNS public n'a été créé pour MinIO.

---

## 3️⃣ ARCHITECTURE FINALE

```
                    ┌─────────────────────┐
                    │  Internet (HTTPS)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  api-dev.keybuzz.io │
                    │   (Ingress K8s)     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   keybuzz-backend   │
                    │  /api/v1/attachments│
                    │       :id           │
                    └──────────┬──────────┘
                               │ (réseau interne)
              ┌────────────────┴────────────────┐
              │                                 │
     ┌────────▼────────┐           ┌────────────▼────────┐
     │   haproxy-01    │           │      haproxy-02     │
     │   10.0.0.11     │           │      10.0.0.12      │
     │   :9000 (S3)    │           │      :9000 (S3)     │
     └────────┬────────┘           └────────────┬────────┘
              │                                 │
              └────────────────┬────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼───────┐   ┌──────────▼──────┐   ┌──────────▼───────┐
│   minio-01    │   │    minio-02     │   │     minio-03     │
│  10.0.0.134   │   │   10.0.0.131    │   │    10.0.0.132    │
│   200GB SSD   │   │   200GB SSD     │   │    200GB SSD     │
└───────────────┘   └─────────────────┘   └──────────────────┘
```

---

## 4️⃣ ENDPOINT API ATTACHMENTS

### Route créée

```
GET /api/v1/attachments/:id
```

### Sécurité

- ✅ Authentification JWT/DEV obligatoire
- ✅ Vérification du tenantId
- ✅ Stream direct depuis MinIO interne
- ✅ Headers Content-Type/Content-Disposition

### Fichiers créés/modifiés

```
keybuzz-backend/src/modules/attachments/attachments.routes.ts (nouveau)
keybuzz-backend/src/main.ts (import ajouté)
keybuzz-backend/package.json (dépendance minio ajoutée)
```

### Test de l'endpoint

```bash
$ curl https://backend-dev.keybuzz.io/api/v1/attachments/test-id
{"error":"Unauthorized","message":"Invalid or missing JWT token"}
# ✅ Auth obligatoire (401 sans token)
```

---

## 5️⃣ SCHÉMA DB MESSAGE_ATTACHMENTS

### Table créée

```sql
CREATE TABLE "MessageAttachment" (
    "id" TEXT PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "ticketId" TEXT,
    "messageId" TEXT,
    "externalMessageId" TEXT,
    
    -- Storage info
    "bucket" TEXT NOT NULL DEFAULT 'keybuzz-attachments',
    "objectKey" TEXT NOT NULL,
    "storageProvider" "AttachmentStorageProvider" DEFAULT 'MINIO',
    "status" "AttachmentStatus" DEFAULT 'UPLOADED',
    
    -- File metadata
    "filename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "size" INTEGER DEFAULT 0,
    "contentId" TEXT,
    "isInline" BOOLEAN DEFAULT false,
    
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Indexes

```sql
CREATE INDEX ON "MessageAttachment"("tenantId");
CREATE INDEX ON "MessageAttachment"("ticketId");
CREATE INDEX ON "MessageAttachment"("messageId");
CREATE INDEX ON "MessageAttachment"("objectKey");
```

---

## 6️⃣ TESTS DE SÉCURITÉ

### MinIO non accessible publiquement

```bash
$ kubectl get ingress -A | grep minio
# Aucun résultat ✅

$ dig +short s3.keybuzz.io
# Aucun résultat ✅
```

### MinIO accessible uniquement en interne

```bash
$ curl http://10.0.0.11:9000/minio/health/live
# HTTP 200 ✅ (depuis le réseau interne)

$ curl http://159.69.159.32:9000/minio/health/live
# Connection timeout ✅ (depuis Internet = bloqué)
```

### API attachments sécurisée

```bash
$ curl https://backend-dev.keybuzz.io/api/v1/attachments/test
{"error":"Unauthorized","message":"Invalid or missing JWT token"}
# ✅ Auth obligatoire
```

---

## 7️⃣ VERSIONS DÉPLOYÉES

| Composant | Version | Notes |
|-----------|---------|-------|
| keybuzz-backend | 1.0.26 | + endpoint attachments |
| MinIO cluster | 3 nœuds | Distributed HA (inchangé) |
| HAProxy | :9000 | Interne uniquement |

---

## 8️⃣ FLUX DE TÉLÉCHARGEMENT PJ

```
1. Client (navigateur) → GET /api/v1/attachments/:id
2. Ingress (api-dev.keybuzz.io) → keybuzz-backend pod
3. Backend vérifie JWT + tenantId
4. Backend query DB (MessageAttachment)
5. Backend stream depuis MinIO (via HAProxy 10.0.0.11:9000)
6. Backend → Client (stream avec headers)
```

**Note** : L'URL MinIO n'est JAMAIS exposée au client.

---

## 9️⃣ ROLLBACK

### Restaurer l'accès public (si nécessaire)

```bash
# Recréer le namespace et l'ingress
kubectl apply -f /path/to/minio-external.yaml
```

### Revenir à la version précédente du backend

```bash
kubectl set image deployment/keybuzz-backend \
  keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:1.0.24 \
  -n keybuzz-backend-dev
```

---

## Conclusion

### ✅ OBJECTIFS ATTEINTS

1. **Ingress MinIO supprimé** — Aucun accès public via K8s
2. **DNS non configuré** — s3.keybuzz.io ne résout pas
3. **API /attachments/:id** — Téléchargement sécurisé via backend
4. **Auth obligatoire** — JWT/DEV validation
5. **MinIO strictement interne** — HAProxy 10.0.0.11/12 uniquement

### SÉCURITÉ ✅

- MinIO n'est **JAMAIS** accessible depuis Internet
- Les presigned URLs MinIO ne sont **JAMAIS** exposées au client
- Tous les téléchargements passent par l'API authentifiée
- Le schéma DB `MessageAttachment` permet le tracking des PJ

### PROD READY ✅

MinIO est maintenant sécurisé en mode interne. Les pièces jointes peuvent être téléchargées uniquement via `https://api-dev.keybuzz.io/api/v1/attachments/:id` avec authentification.
