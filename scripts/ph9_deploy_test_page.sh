#!/bin/bash
# PH9 - Déploiement d'une page de test pour vérifier le routage Ingress
# KeyBuzz v3 - Page de test temporaire avant le déploiement de KeyBuzz Admin (PH10)
# Cette page affiche l'URL sur laquelle on se trouve

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/test-page-deploy.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/test-page-deploy.log" >&2
}

# Vérification kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

log_info "Vérification de l'accès au cluster..."
export KUBECONFIG=/root/.kube/config
if ! kubectl cluster-info &> /dev/null; then
    log_error "Impossible d'accéder au cluster Kubernetes"
    exit 1
fi

# Créer un ConfigMap avec la page HTML de test
log_info "Création du ConfigMap avec la page HTML de test..."

cat > /tmp/test-page-html.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-page-html
  namespace: keybuzz-admin-dev
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>KeyBuzz Admin - Page de Test</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px;
                max-width: 600px;
                text-align: center;
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 {
                margin-top: 0;
                font-size: 2.5em;
                margin-bottom: 20px;
            }
            .url-display {
                background: rgba(255, 255, 255, 0.2);
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
                font-size: 1.2em;
                word-break: break-all;
                font-family: 'Courier New', monospace;
            }
            .info {
                margin-top: 30px;
                font-size: 0.9em;
                opacity: 0.8;
            }
            .status {
                display: inline-block;
                padding: 5px 15px;
                background: rgba(76, 175, 80, 0.3);
                border-radius: 20px;
                margin-top: 20px;
                font-weight: bold;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>✅ KeyBuzz Admin</h1>
            <p style="font-size: 1.3em; margin-bottom: 20px;">Page de Test - Routage Ingress</p>
            <div class="url-display" id="urlDisplay">Chargement...</div>
            <div class="status">🚀 Ingress & TLS Opérationnels</div>
            <div class="info">
                <p><strong>Namespace:</strong> <span id="namespace">keybuzz-admin-dev</span></p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
                <p style="margin-top: 20px; font-size: 0.85em;">
                    Cette page de test sera supprimée lors du déploiement de PH10
                </p>
            </div>
        </div>
        <script>
            // Afficher l'URL complète
            const fullUrl = window.location.href;
            const hostname = window.location.hostname;
            const protocol = window.location.protocol;
            const pathname = window.location.pathname;
            
            document.getElementById('urlDisplay').innerHTML = `
                <strong>URL complète:</strong><br>
                ${fullUrl}<br><br>
                <strong>Hostname:</strong> ${hostname}<br>
                <strong>Protocole:</strong> ${protocol}<br>
                <strong>Chemin:</strong> ${pathname}
            `;
            
            // Afficher le timestamp
            document.getElementById('timestamp').textContent = new Date().toLocaleString('fr-FR');
            
            // Déterminer le namespace selon l'hostname
            if (hostname.includes('admin-dev')) {
                document.getElementById('namespace').textContent = 'keybuzz-admin-dev';
            } else if (hostname.includes('admin.keybuzz.io')) {
                document.getElementById('namespace').textContent = 'keybuzz-admin';
            }
        </script>
    </body>
    </html>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-page-html
  namespace: keybuzz-admin
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>KeyBuzz Admin - Page de Test</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px;
                max-width: 600px;
                text-align: center;
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 {
                margin-top: 0;
                font-size: 2.5em;
                margin-bottom: 20px;
            }
            .url-display {
                background: rgba(255, 255, 255, 0.2);
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
                font-size: 1.2em;
                word-break: break-all;
                font-family: 'Courier New', monospace;
            }
            .info {
                margin-top: 30px;
                font-size: 0.9em;
                opacity: 0.8;
            }
            .status {
                display: inline-block;
                padding: 5px 15px;
                background: rgba(76, 175, 80, 0.3);
                border-radius: 20px;
                margin-top: 20px;
                font-weight: bold;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>✅ KeyBuzz Admin</h1>
            <p style="font-size: 1.3em; margin-bottom: 20px;">Page de Test - Routage Ingress (PRODUCTION)</p>
            <div class="url-display" id="urlDisplay">Chargement...</div>
            <div class="status">🚀 Ingress & TLS Opérationnels</div>
            <div class="info">
                <p><strong>Namespace:</strong> <span id="namespace">keybuzz-admin</span></p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
                <p style="margin-top: 20px; font-size: 0.85em;">
                    Cette page de test sera supprimée lors du déploiement de PH10
                </p>
            </div>
        </div>
        <script>
            // Afficher l'URL complète
            const fullUrl = window.location.href;
            const hostname = window.location.hostname;
            const protocol = window.location.protocol;
            const pathname = window.location.pathname;
            
            document.getElementById('urlDisplay').innerHTML = `
                <strong>URL complète:</strong><br>
                ${fullUrl}<br><br>
                <strong>Hostname:</strong> ${hostname}<br>
                <strong>Protocole:</strong> ${protocol}<br>
                <strong>Chemin:</strong> ${pathname}
            `;
            
            // Afficher le timestamp
            document.getElementById('timestamp').textContent = new Date().toLocaleString('fr-FR');
            
            // Déterminer le namespace selon l'hostname
            if (hostname.includes('admin-dev')) {
                document.getElementById('namespace').textContent = 'keybuzz-admin-dev';
            } else if (hostname.includes('admin.keybuzz.io')) {
                document.getElementById('namespace').textContent = 'keybuzz-admin';
            }
        </script>
    </body>
    </html>
EOF

kubectl apply -f /tmp/test-page-html.yaml 2>&1 | tee -a "$LOG_DIR/test-page-deploy.log"

# Créer les Deployments de test
log_info "Création des Deployments de test..."

cat > /tmp/test-page-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-admin-test
  namespace: keybuzz-admin-dev
  labels:
    app: keybuzz-admin-test
    component: test-page
spec:
  replicas: 2
  selector:
    matchLabels:
      app: keybuzz-admin-test
  template:
    metadata:
      labels:
        app: keybuzz-admin-test
        component: test-page
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 64Mi
      volumes:
      - name: html
        configMap:
          name: test-page-html
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-admin-test
  namespace: keybuzz-admin
  labels:
    app: keybuzz-admin-test
    component: test-page
spec:
  replicas: 2
  selector:
    matchLabels:
      app: keybuzz-admin-test
  template:
    metadata:
      labels:
        app: keybuzz-admin-test
        component: test-page
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 64Mi
      volumes:
      - name: html
        configMap:
          name: test-page-html
EOF

kubectl apply -f /tmp/test-page-deployment.yaml 2>&1 | tee -a "$LOG_DIR/test-page-deploy.log"

# Créer les Services de test
log_info "Création des Services de test..."

cat > /tmp/test-page-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: keybuzz-admin
  namespace: keybuzz-admin-dev
  labels:
    app: keybuzz-admin-test
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: keybuzz-admin-test
---
apiVersion: v1
kind: Service
metadata:
  name: keybuzz-admin
  namespace: keybuzz-admin
  labels:
    app: keybuzz-admin-test
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: keybuzz-admin-test
EOF

kubectl apply -f /tmp/test-page-service.yaml 2>&1 | tee -a "$LOG_DIR/test-page-deploy.log"

# Attendre que les pods soient prêts
log_info "Attente des pods de test (timeout 60s)..."
sleep 3

if kubectl wait --namespace keybuzz-admin-dev \
    --for=condition=Ready pods \
    --selector=app=keybuzz-admin-test \
    --timeout=60s 2>&1 | tee -a "$LOG_DIR/test-page-deploy.log"; then
    log_info "✅ Pods de test dev sont Ready"
else
    log_error "⚠️  Certains pods de test dev ne sont pas encore Ready"
fi

if kubectl wait --namespace keybuzz-admin \
    --for=condition=Ready pods \
    --selector=app=keybuzz-admin-test \
    --timeout=60s 2>&1 | tee -a "$LOG_DIR/test-page-deploy.log"; then
    log_info "✅ Pods de test prod sont Ready"
else
    log_error "⚠️  Certains pods de test prod ne sont pas encore Ready"
fi

# Afficher l'état final
log_info "État des pods de test:"
kubectl get pods -n keybuzz-admin-dev -l app=keybuzz-admin-test | tee -a "$LOG_DIR/test-page-deploy.log"
kubectl get pods -n keybuzz-admin -l app=keybuzz-admin-test | tee -a "$LOG_DIR/test-page-deploy.log"

log_info "Services de test:"
kubectl get svc -n keybuzz-admin-dev keybuzz-admin | tee -a "$LOG_DIR/test-page-deploy.log"
kubectl get svc -n keybuzz-admin keybuzz-admin | tee -a "$LOG_DIR/test-page-deploy.log"

log_info "✅ Page de test déployée avec succès"
log_info "Vous pouvez maintenant accéder à:"
log_info "  - https://admin-dev.keybuzz.io"
log_info "  - https://admin.keybuzz.io"
log_info ""
log_info "⚠️  IMPORTANT: Utilisez ph9_remove_test_page.sh pour supprimer cette page de test avant PH10"

