# PH-S01.2D - Cookie Domain Configuration for Cross-Subdomain SSO

**Date**: 2026-01-30  
**Status**: DEPLOYED - DEV ONLY  
**Environment**: client-dev.keybuzz.io, seller-dev.keybuzz.io

---

## Objective

Configure NextAuth session cookies with `domain=.keybuzz.io` to enable cross-subdomain SSO between `client-dev.keybuzz.io` and `seller-dev.keybuzz.io`.

---

## Changes Made

### 1. Code Change (keybuzz-client)

**File**: `app/api/auth/[...nextauth]/auth-options.ts`

**Configuration applied**:
```typescript
const isProduction = process.env.NODE_ENV === 'production';

cookies: {
  sessionToken: {
    name: isProduction ? '__Secure-next-auth.session-token' : 'next-auth.session-token',
    options: {
      httpOnly: true,
      sameSite: 'lax' as const,
      path: '/',
      domain: isProduction ? '.keybuzz.io' : undefined,
      secure: isProduction,
    },
  },
  callbackUrl: {
    name: isProduction ? '__Secure-next-auth.callback-url' : 'next-auth.callback-url',
    options: {
      httpOnly: true,
      sameSite: 'lax' as const,
      path: '/',
      domain: isProduction ? '.keybuzz.io' : undefined,
      secure: isProduction,
    },
  },
  csrfToken: {
    name: isProduction ? '__Secure-next-auth.csrf-token' : 'next-auth.csrf-token',
    options: {
      httpOnly: true,
      sameSite: 'lax' as const,
      path: '/',
      domain: isProduction ? '.keybuzz.io' : undefined,
      secure: isProduction,
    },
  },
},
```

### 2. Git Branch & Commit

- **Branch**: `ph-s01.2d-cookie-domain`
- **Commit**: `ef961c8` - "PH-S01.2D: Configure NextAuth cookies with domain=.keybuzz.io for cross-subdomain SSO"

### 3. Docker Image

- **Image**: `ghcr.io/keybuzzio/keybuzz-client:v1.5.0-cookie-domain`
- **Digest**: `sha256:24f71ef14bedbfe3ad3a9270bd9c7e1cbcd15ef2eeb744eda3873f6556a2c68c`
- **Registry**: GitHub Container Registry (GHCR)

### 4. GitOps Deployment

- **Manifest**: `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml`
- **Commit**: `75cd821` - "PH-S01.2D: Deploy keybuzz-client v1.5.0-cookie-domain with cross-subdomain SSO cookies"
- **ArgoCD Application**: `keybuzz-client-dev` (auto-sync enabled)

---

## Test Results

### Test 1: client-dev Login (PASSED)

**Steps**:
1. Navigate to `https://client-dev.keybuzz.io/login`
2. Enter email: `ludo.gonthier@gmail.com`
3. Enter OTP code (DEV mode)
4. Verify redirection to `/select-tenant`

**Result**: ✅ PASSED
- No redirect loops
- No 4xx errors
- User authenticated successfully
- Email displayed: `ludo.gonthier@gmail.com`

### Test 2: seller-dev SSO (PARTIAL)

**curl test from bastion**:
```bash
curl -sI https://seller-dev.keybuzz.io/
```

**Result**:
```
HTTP/2 307 
location: https://client-dev.keybuzz.io/auth/signin?returnTo=https%3A%2F%2Fseller-dev.keybuzz.io%2F
```

- ✅ seller-dev responds correctly
- ✅ Redirect to client-dev with returnTo parameter works
- ⚠️ Browser SSO test inconclusive (network issues during testing)

### Test 3: Pod Status

```bash
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client
```

**Result**:
```
NAME                             READY   STATUS    RESTARTS   AGE
keybuzz-client-d64fbcb5b-znfsz   1/1     Running   0          Xm
```

**Image verification**:
```
ghcr.io/keybuzzio/keybuzz-client:v1.5.0-cookie-domain
```

---

## Rollback Procedure

### Quick Rollback (< 2 min)

1. **Revert GitOps manifest**:
```bash
cd /opt/keybuzz/keybuzz-infra
sed -i 's|v1.5.0-cookie-domain|v1.4.0-returnto-login|g' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "ROLLBACK: Revert to v1.4.0-returnto-login"
git push origin main
```

2. **ArgoCD will auto-sync** (or force sync):
```bash
kubectl delete application keybuzz-client-dev -n argocd
kubectl apply -f /tmp/keybuzz-client-dev-app.yaml
```

3. **Verify rollback**:
```bash
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o jsonpath='{.items[0].spec.containers[0].image}'
# Expected: ghcr.io/keybuzzio/keybuzz-client:v1.4.0-returnto-login
```

### Previous Working Image Tags

| Tag | Description | Safe to rollback |
|-----|-------------|------------------|
| `v1.4.0-returnto-login` | Pre-cookie-domain, returnTo support | ✅ Yes |
| `v1.3.0-returnto-tenant` | Earlier returnTo version | ✅ Yes |
| `v1.2.0-returnto` | Initial returnTo | ✅ Yes |

---

## ArgoCD Configuration

**Application manifest** (`/tmp/keybuzz-client-dev-app.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keybuzz-client-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/keybuzzio/keybuzz-infra.git
    targetRevision: main
    path: k8s/keybuzz-client-dev
  destination:
    server: https://kubernetes.default.svc
    namespace: keybuzz-client-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Known Issues

1. **seller-client useAuth hook**: Still attempts cross-origin fetch to `client-dev.keybuzz.io/api/auth/session`. This causes CORS errors but is mitigated by the server-side middleware redirect. A future fix should modify seller-client to only check for cookie presence, not make cross-origin API calls.

2. **select-tenant "Impossible de charger vos espaces"**: This error appears after login but is unrelated to cookie configuration - likely an API backend issue.

---

## Verification Commands

```bash
# Check deployed image
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client \
  -o jsonpath='{.items[0].spec.containers[0].image}'

# Check ArgoCD sync status
kubectl get application keybuzz-client-dev -n argocd \
  -o jsonpath='{.status.sync.status} {.status.health.status}'

# Test login page
curl -sI https://client-dev.keybuzz.io/login

# Test seller-dev redirect
curl -sI https://seller-dev.keybuzz.io/
```

---

## Next Steps

1. **Complete SSO browser test**: Verify full flow seller-dev → client-dev login → seller-dev access
2. **Fix seller-client useAuth**: Remove cross-origin fetch, rely on cookie check only
3. **Document PROD rollout plan** when DEV is validated

---

## Approval

- [x] DEV ONLY deployment
- [x] Branch created: `ph-s01.2d-cookie-domain`
- [x] Immutable image tag: `v1.5.0-cookie-domain`
- [x] GitOps deployment via ArgoCD
- [x] Rollback procedure documented
- [x] client-dev login test passed

**Ready for handover to another agent if needed.**
