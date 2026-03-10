# DEV BEFORE SYNC SNAPSHOT

**Date:** 2026-02-03  
**Raison:** SYNC DEV ← PROD (SAFE MODE)

---

## Image DEV Actuelle (AVANT SYNC)

| Attribut | Valeur |
|----------|--------|
| Tag | `ghcr.io/keybuzzio/keybuzz-client:ph29.1-dev-rebased-2026-02-03` |
| Digest | `sha256:b28a0a007f55f9824d0f46aa355a44e4ce935a5aa8e4a656742a70cc77f79500` |

---

## Manifest DEV Actuel (AVANT SYNC)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-client
  namespace: keybuzz-client-dev
  labels:
    app: keybuzz-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keybuzz-client
  template:
    metadata:
      labels:
        app: keybuzz-client
    spec:
      imagePullSecrets:
        - name: ghcr-secret
      containers:
        - name: keybuzz-client
          # PH29.1B: Rebased on GOLDEN + Onboarding Hub
          image: ghcr.io/keybuzzio/keybuzz-client:ph29.1-dev-rebased-2026-02-03
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
              name: http
          env:
            - name: NODE_ENV
              value: "production"
            - name: NEXT_PUBLIC_API_URL
              value: "https://api-dev.keybuzz.io"
            - name: API_URL_INTERNAL
              value: "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001"
            - name: NEXTAUTH_URL
              value: "https://client-dev.keybuzz.io"
            # ... secrets ...
```

---

## Raison de la sauvegarde

Synchronisation DEV ← PROD demandée.
DEV sera rollback vers l'image PROD exacte.

---

**Snapshot créé le:** 2026-02-03T22:50:00Z
