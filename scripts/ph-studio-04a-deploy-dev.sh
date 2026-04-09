#!/bin/bash
set -euo pipefail

TAG="v0.2.0-dev"
REGISTRY="ghcr.io/keybuzzio"
export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

echo "=== PH-STUDIO-04A — DEV DEPLOY ==="

# --- 1. Create K8s secret for auth ---
echo "--- Creating K8s auth secret ---"
BOOTSTRAP_SECRET=$(vault kv get -field=bootstrap_secret secret/keybuzz/dev/studio-auth)

kubectl create secret generic keybuzz-studio-api-auth \
  --namespace=keybuzz-studio-api-dev \
  --from-literal=BOOTSTRAP_SECRET="$BOOTSTRAP_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Auth secret created."

# --- 2. Build API image ---
echo "--- Building API image ---"
cd /opt/keybuzz/keybuzz-studio-api
npm ci --prefer-offline 2>&1 | tail -3
docker build -t "${REGISTRY}/keybuzz-studio-api:${TAG}" .
echo "API image built."

# --- 3. Build Frontend image ---
echo "--- Building Frontend image ---"
cd /opt/keybuzz/keybuzz-studio
npm ci --prefer-offline 2>&1 | tail -3
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  -t "${REGISTRY}/keybuzz-studio:${TAG}" .
echo "Frontend image built."

# --- 4. Push images ---
echo "--- Pushing images ---"
docker push "${REGISTRY}/keybuzz-studio-api:${TAG}"
docker push "${REGISTRY}/keybuzz-studio:${TAG}"
echo "Images pushed."

# --- 5. Apply K8s manifests ---
echo "--- Deploying API ---"
cat <<'EOYAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-studio-api
  namespace: keybuzz-studio-api-dev
  labels:
    app: keybuzz-studio-api
    environment: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keybuzz-studio-api
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: keybuzz-studio-api
      annotations:
        reloader.stakater.com/auto: "true"
    spec:
      imagePullSecrets:
        - name: ghcr-cred
      containers:
        - name: keybuzz-studio-api
          image: ghcr.io/keybuzzio/keybuzz-studio-api:v0.2.0-dev
          imagePullPolicy: Always
          ports:
            - containerPort: 4010
          readinessProbe:
            tcpSocket:
              port: 4010
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            tcpSocket:
              port: 4010
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          env:
            - name: NODE_ENV
              value: "development"
            - name: PORT
              value: "4010"
            - name: LOG_LEVEL
              value: "debug"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: keybuzz-studio-api-db
                  key: DATABASE_URL
            - name: CORS_ORIGIN
              value: "https://studio-dev.keybuzz.io"
            - name: BOOTSTRAP_SECRET
              valueFrom:
                secretKeyRef:
                  name: keybuzz-studio-api-auth
                  key: BOOTSTRAP_SECRET
            - name: COOKIE_DOMAIN
              value: ".keybuzz.io"
            - name: SMTP_HOST
              value: "49.13.35.167"
            - name: SMTP_PORT
              value: "25"
            - name: SMTP_FROM
              value: "KeyBuzz Studio <studio@keybuzz.io>"
EOYAML

echo "--- Deploying Frontend ---"
cat <<'EOYAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-studio
  namespace: keybuzz-studio-dev
  labels:
    app: keybuzz-studio
    environment: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keybuzz-studio
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: keybuzz-studio
      annotations:
        reloader.stakater.com/auto: "true"
    spec:
      imagePullSecrets:
        - name: ghcr-cred
      containers:
        - name: keybuzz-studio
          image: ghcr.io/keybuzzio/keybuzz-studio:v0.2.0-dev
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          readinessProbe:
            tcpSocket:
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            tcpSocket:
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          env:
            - name: NEXT_PUBLIC_APP_ENV
              value: "development"
            - name: NEXT_PUBLIC_STUDIO_API_URL
              value: "https://studio-api-dev.keybuzz.io"
EOYAML

# --- 6. Wait for rollout ---
echo "--- Waiting for rollout ---"
kubectl rollout status deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n keybuzz-studio-dev --timeout=120s

# --- 7. Verify ---
echo "--- Verification ---"
kubectl get pods -n keybuzz-studio-api-dev
kubectl get pods -n keybuzz-studio-dev

echo "--- Health checks ---"
sleep 5
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- wget -qO- http://localhost:4010/health 2>/dev/null || echo "health check via wget"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- wget -qO- http://localhost:4010/api/v1/auth/setup/status 2>/dev/null || echo "setup status check"

echo "--- API logs (last 20) ---"
kubectl logs deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --tail=20

echo "=== PH-STUDIO-04A DEV DEPLOY COMPLETE ==="
