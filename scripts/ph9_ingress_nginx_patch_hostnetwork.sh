#!/bin/bash
# PH9 - Patch ingress-nginx pour hostNetwork (DaemonSet)
# KeyBuzz v3 - Conversion Deployment → DaemonSet avec hostNetwork pour LB Hetzner TCP passthrough
# Ce script convertit ingress-nginx en DaemonSet avec hostNetwork pour fonctionner avec les LB Hetzner

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-ingress"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log" >&2
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

# Vérifier si ingress-nginx est déjà en DaemonSet
if kubectl get daemonset ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    log_info "✅ ingress-nginx est déjà en DaemonSet, vérification de hostNetwork..."
    if kubectl get daemonset ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.hostNetwork}' | grep -q "true"; then
        log_info "✅ ingress-nginx est déjà configuré avec hostNetwork=true"
        exit 0
    else
        log_info "⚠️  DaemonSet existe mais hostNetwork n'est pas activé, mise à jour nécessaire..."
    fi
fi

# Récupérer la version de l'image actuelle
log_info "Récupération de la version de l'image ingress-nginx..."
if kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    IMAGE=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].image}')
    log_info "Image actuelle: $IMAGE"
else
    log_error "Le Deployment ingress-nginx-controller n'existe pas"
    exit 1
fi

# Récupérer la configuration complète du Deployment
log_info "Récupération de la configuration du Deployment..."
DEPLOYMENT_CONFIG=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o yaml)

# Créer le DaemonSet avec hostNetwork
log_info "Création du DaemonSet ingress-nginx avec hostNetwork..."

cat > /tmp/ingress-nginx-daemonset.yaml << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/instance: ingress-nginx
      app.kubernetes.io/component: controller
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/instance: ingress-nginx
        app.kubernetes.io/component: controller
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: ingress-nginx
      terminationGracePeriodSeconds: 300
      containers:
      - name: controller
        image: ${IMAGE}
        imagePullPolicy: IfNotPresent
        lifecycle:
          preStop:
            exec:
              command:
                - /wait-shutdown
        args:
          - /nginx-ingress-controller
          - --publish-service=\$(POD_NAMESPACE)/ingress-nginx-controller
          - --election-id=ingress-nginx-leader
          - --controller-class=k8s.io/ingress-nginx
          - --ingress-class=nginx
          - --configmap=\$(POD_NAMESPACE)/ingress-nginx-controller
          - --validating-webhook=:8443
          - --validating-webhook-certificate=/usr/local/certificates/cert
          - --validating-webhook-key=/usr/local/certificates/key
        securityContext:
          capabilities:
            drop:
              - ALL
            add:
              - NET_BIND_SERVICE
          runAsUser: 101
          allowPrivilegeEscalation: false
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LD_PRELOAD
          value: /usr/local/lib/libmimalloc.so
        ports:
        - name: http
          containerPort: 80
          hostPort: 80
          protocol: TCP
        - name: https
          containerPort: 443
          hostPort: 443
          protocol: TCP
        - name: webhook
          containerPort: 8443
          protocol: TCP
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        volumeMounts:
        - name: webhook-cert
          mountPath: /usr/local/certificates/
          readOnly: true
        resources:
          requests:
            cpu: 100m
            memory: 90Mi
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - operator: Exists
      volumes:
      - name: webhook-cert
        secret:
          secretName: ingress-nginx-admission
EOF

log_info "Application du DaemonSet..."
kubectl apply -f /tmp/ingress-nginx-daemonset.yaml 2>&1 | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"

# Attendre que le DaemonSet soit prêt
log_info "Attente des pods DaemonSet (timeout 120s)..."
sleep 5

if kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pods \
    --selector=app.kubernetes.io/name=ingress-nginx \
    --timeout=120s 2>&1 | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"; then
    log_info "✅ Tous les pods DaemonSet sont Ready"
else
    log_error "⚠️  Certains pods DaemonSet ne sont pas encore Ready"
fi

# Supprimer l'ancien Deployment si le DaemonSet fonctionne
log_info "Vérification de l'état du DaemonSet..."
if kubectl get daemonset ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    READY_PODS=$(kubectl get daemonset ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.numberReady}')
    DESIRED_PODS=$(kubectl get daemonset ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.desiredNumberScheduled}')
    
    if [ "$READY_PODS" -eq "$DESIRED_PODS" ] && [ "$READY_PODS" -gt 0 ]; then
        log_info "✅ DaemonSet opérationnel ($READY_PODS/$DESIRED_PODS pods Ready)"
        log_info "Suppression de l'ancien Deployment..."
        if kubectl delete deployment ingress-nginx-controller -n ingress-nginx 2>&1 | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"; then
            log_info "✅ Ancien Deployment supprimé"
        else
            log_error "⚠️  Impossible de supprimer l'ancien Deployment (peut-être déjà supprimé)"
        fi
    else
        log_error "⚠️  DaemonSet pas encore prêt ($READY_PODS/$DESIRED_PODS pods Ready), ne pas supprimer le Deployment"
    fi
fi

log_info "État final des pods ingress-nginx:"
kubectl get pods -n ingress-nginx -o wide | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"

log_info "Vérification hostNetwork:"
kubectl get daemonset ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.hostNetwork}' | tee -a "$LOG_DIR/ingress-nginx-patch-hostnetwork.log"

log_info "✅ Patch hostNetwork terminé"

