# KeyBuzz Studio — Development Workflow

> Last update: 2026-04-02
> Phase: PH-STUDIO-01

---

## Development

### Local Setup

```bash
# Frontend
cd keybuzz-studio
npm install
npm run dev          # http://localhost:3000

# Backend
cd keybuzz-studio-api
npm install
npm run dev          # http://localhost:4010
```

### Host Override (before DNS is configured)

Add to hosts file:
```
# KeyBuzz Studio DEV (host override)
<cluster-ip>  studio-dev.keybuzz.io
<cluster-ip>  studio-api-dev.keybuzz.io
```

## Build & Deploy (DEV)

### Prerequisites
1. Git repo clean (run pre-build-check.sh)
2. Code committed and pushed
3. DNS or host override configured

### Build
```bash
cd /opt/keybuzz/keybuzz-infra/scripts
./build-studio-from-git.sh dev v1.0.X-feature-dev main
./build-studio-api-from-git.sh dev v1.0.X-feature-dev main
```

### Deploy
1. Update image tag in `keybuzz-infra/k8s/keybuzz-studio-dev/deployment.yaml`
2. Commit and push to keybuzz-infra
3. ArgoCD auto-syncs (or manual sync)
4. Verify: `kubectl get pods -n keybuzz-studio-dev`

### Rollback
```bash
/opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh studio dev v1.0.X-previous-dev
```

## Phase Workflow

For each new phase (PH-STUDIO-XX):

1. Read STUDIO-MASTER-REPORT.md for current state
2. Read .cursor/rules/studio-rules.mdc for rules
3. Execute the phase
4. Create PH-STUDIO-XX-REPORT.md
5. Update STUDIO-MASTER-REPORT.md with new state
6. Enrich studio-rules.mdc if new rules emerged
7. Commit all changes

## Branch Strategy

- `main` — stable, deployable
- `studio/feature-name` — feature branches for Studio
- Always merge via PR with review
