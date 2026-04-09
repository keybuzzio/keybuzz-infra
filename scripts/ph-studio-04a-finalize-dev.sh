#!/bin/bash
set -euo pipefail

TAG="v0.2.0-dev"
REGISTRY="ghcr.io/keybuzzio"

echo "=== PH-STUDIO-04A — Finalize DEV Deploy ==="

# Push API image (was built but not pushed)
echo "--- Pushing API image ---"
docker push "${REGISTRY}/keybuzz-studio-api:${TAG}"
echo "API image pushed."

# Apply updated K8s API deployment
echo "--- Applying API deployment ---"
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
        deploy-timestamp: "20260403-v020"
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

# Apply updated K8s frontend deployment
echo "--- Applying Frontend deployment ---"
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
        deploy-timestamp: "20260403-v020"
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

echo "--- Waiting for rollouts ---"
kubectl rollout status deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n keybuzz-studio-dev --timeout=120s

sleep 8

echo "--- Pods ---"
kubectl get pods -n keybuzz-studio-api-dev
kubectl get pods -n keybuzz-studio-dev

echo "--- Health checks ---"
curl -s https://studio-api-dev.keybuzz.io/health
echo
curl -s https://studio-api-dev.keybuzz.io/api/v1/auth/setup/status
echo
curl -s https://studio-api-dev.keybuzz.io/api/v1/auth/me
echo

echo "--- Frontend login page ---"
curl -sI https://studio-dev.keybuzz.io/login | head -3
echo

echo "--- API Logs ---"
kubectl logs deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --tail=20

echo "=== FINALIZE COMPLETE ==="
