#!/bin/bash
set -euo pipefail

DEV_TAG="v0.2.0-dev"
PROD_TAG="v0.2.0-prod"
REGISTRY="ghcr.io/keybuzzio"
export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

echo "=== PH-STUDIO-04A — PROD Promotion ==="

# --- 1. Tag and push PROD images ---
echo "--- Tagging images for PROD ---"
docker tag "${REGISTRY}/keybuzz-studio-api:${DEV_TAG}" "${REGISTRY}/keybuzz-studio-api:${PROD_TAG}"
docker tag "${REGISTRY}/keybuzz-studio:${DEV_TAG}" "${REGISTRY}/keybuzz-studio:${PROD_TAG}"

docker push "${REGISTRY}/keybuzz-studio-api:${PROD_TAG}"
docker push "${REGISTRY}/keybuzz-studio:${PROD_TAG}"
echo "PROD images pushed."

# --- 2. Create PROD auth K8s secret ---
echo "--- Creating PROD auth secret ---"
BOOTSTRAP_SECRET_PROD=$(vault kv get -field=bootstrap_secret secret/keybuzz/prod/studio-auth)

kubectl create secret generic keybuzz-studio-api-auth \
  --namespace=keybuzz-studio-api-prod \
  --from-literal=BOOTSTRAP_SECRET="$BOOTSTRAP_SECRET_PROD" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "PROD auth secret created."

# --- 3. Deploy API PROD ---
echo "--- Deploying API PROD ---"
cat <<'EOYAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-studio-api
  namespace: keybuzz-studio-api-prod
  labels:
    app: keybuzz-studio-api
    environment: production
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
        deploy-timestamp: "20260403-v020-auth"
    spec:
      imagePullSecrets:
        - name: ghcr-cred
      containers:
        - name: keybuzz-studio-api
          image: ghcr.io/keybuzzio/keybuzz-studio-api:v0.2.0-prod
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
              value: "production"
            - name: PORT
              value: "4010"
            - name: LOG_LEVEL
              value: "info"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: keybuzz-studio-api-db
                  key: DATABASE_URL
            - name: CORS_ORIGIN
              value: "https://studio.keybuzz.io"
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

# --- 4. Deploy Frontend PROD ---
echo "--- Deploying Frontend PROD ---"
cat <<'EOYAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-studio
  namespace: keybuzz-studio-prod
  labels:
    app: keybuzz-studio
    environment: production
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
        deploy-timestamp: "20260403-v020-auth"
    spec:
      imagePullSecrets:
        - name: ghcr-cred
      containers:
        - name: keybuzz-studio
          image: ghcr.io/keybuzzio/keybuzz-studio:v0.2.0-prod
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
              value: "production"
            - name: NEXT_PUBLIC_STUDIO_API_URL
              value: "https://studio-api.keybuzz.io"
EOYAML

# --- 5. Wait for rollouts ---
echo "--- Waiting for rollouts ---"
kubectl rollout status deployment/keybuzz-studio-api -n keybuzz-studio-api-prod --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n keybuzz-studio-prod --timeout=120s

sleep 8

# --- 6. Verify ---
echo "--- PROD Pods ---"
kubectl get pods -n keybuzz-studio-api-prod
kubectl get pods -n keybuzz-studio-prod

echo "--- PROD Health checks ---"
curl -s https://studio-api.keybuzz.io/health
echo
curl -s https://studio-api.keybuzz.io/api/v1/auth/setup/status
echo
curl -sI https://studio.keybuzz.io/login | head -3
echo

echo "--- PROD API Logs ---"
kubectl logs deployment/keybuzz-studio-api -n keybuzz-studio-api-prod --tail=10

echo "=== PROD PROMOTION COMPLETE ==="
