# PH11-VERSION-01-FINALIZE - Fix version affichÃ©e = version dÃ©ployÃ©e

## Resume

**Objectif:** S'assurer que la version affichÃ©e dans les footers + /debug/version reflÃ¨te rÃ©ellement le build dÃ©ployÃ© (tag + git SHA).

**Status:** Manifests K8s mis Ã  jour, images Docker Ã  rebuildre.

## Images K8s avant finalisation

**Timestamp:** 2026-01-04T17:35:10Z

| Service | Image avant |
|---------|-------------|
| Client | ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev |
| Admin | ghcr.io/keybuzzio/keybuzz-admin:v1.0.53-dev |

**Logs:** `/opt/keybuzz/logs/ph11-version/k8s_images_final.txt`

## Modifications apportÃ©es

### 1. KeyBuzz Client

**Version bumpÃ©e:** 0.2.6-dev â†’ 0.2.13-dev

**Changements commitÃ©s:**
- `package.json`: Version bumpÃ©e Ã  0.2.13-dev
- `app/debug/page.tsx`: Utilise BUILD_METADATA
- `app/debug/version/page.tsx`: Route /debug/version crÃ©Ã©e
- `scripts/generate-build-metadata.py`: Script de gÃ©nÃ©ration des metadata
- `.gitignore`: AjoutÃ© src/lib/build-metadata.ts (gÃ©nÃ©rÃ©)

**Commit:** `8e1575f` - PH11-VERSION-01: Add build metadata generation + debug/version route

**Manifest K8s mis Ã  jour:**
- `k8s/keybuzz-client-dev/deployment.yaml`: image â†’ `ghcr.io/keybuzzio/keybuzz-client:v0.2.13-dev`

**Build metadata gÃ©nÃ©rÃ©e:**
```typescript
{
  app: 'keybuzz-client',
  version: '0.2.13-dev',
  gitSha: '8831ef6',
  buildDate: '2026-01-04T17:38:04.986621Z'
}
```

### 2. KeyBuzz Admin

**Version bumpÃ©e:** 1.0.52-dev â†’ 1.0.54-dev

**Changements commitÃ©s:**
- `package.json`: Version bumpÃ©e Ã  1.0.54-dev
- `components/layouts/keybuzz-admin/components/sidebar.tsx`: Utilise BUILD_METADATA dans footer
- `app/debug/version/page.tsx`: Route /debug/version crÃ©Ã©e
- `scripts/generate-build-metadata.py`: Script de gÃ©nÃ©ration des metadata
- `.gitignore`: AjoutÃ© src/lib/build-metadata.ts (gÃ©nÃ©rÃ©)

**Commit:** `e4bffe7` - PH11-VERSION-01: Add build metadata generation + debug/version route + sidebar footer fix

**Manifest K8s mis Ã  jour:**
- `k8s/keybuzz-admin-dev/deployment.yaml`: image â†’ `ghcr.io/keybuzzio/keybuzz-admin:v1.0.54-dev`

**Build metadata gÃ©nÃ©rÃ©e:**
```typescript
{
  app: 'keybuzz-admin',
  version: '1.0.54-dev',
  gitSha: '445afbc',
  buildDate: '2026-01-04T17:39:38.860817Z'
}
```

### 3. KeyBuzz Infra

**Manifests K8s mis Ã  jour:**
- `k8s/keybuzz-client-dev/deployment.yaml`: v0.2.33-dev â†’ v0.2.13-dev
- `k8s/keybuzz-admin-dev/deployment.yaml`: v1.0.53-dev â†’ v1.0.54-dev

**Commit:** `8151fe9` - PH11-VERSION-01: Update deployment tags to v0.2.13-dev (client) and v1.0.54-dev (admin)

## Images K8s finales (aprÃ¨s rebuild Docker)

**Nouveaux tags attendus:**
- Client: `ghcr.io/keybuzzio/keybuzz-client:v0.2.13-dev`
- Admin: `ghcr.io/keybuzzio/keybuzz-admin:v1.0.54-dev`

**âš ï¸ IMPORTANT:** Les images Docker doivent Ãªtre rebuildÃ©es avant le rollout:
- Les manifests K8s ont Ã©tÃ© mis Ã  jour avec les nouveaux tags
- Les images Docker doivent Ãªtre rebuildÃ©es via CI/CD (GitHub Actions) ou manuellement
- Une fois les images rebuildÃ©es, rollout via ArgoCD ou kubectl

## URLs /debug/version

**Client DEV:**
- URL: https://client-dev.keybuzz.io/debug/version
- Format: JSON + dÃ©tails lisibles
- Contenu attendu: version, gitSha, buildDate

**Admin DEV:**
- URL: https://admin-dev.keybuzz.io/debug/version
- Format: JSON + dÃ©tails lisibles
- Contenu attendu: version, gitSha, buildDate

## Validation E2E (aprÃ¨s rebuild Docker)

### 1. VÃ©rifier les images K8s dÃ©ployÃ©es

```bash
kubectl -n keybuzz-client-dev get deploy keybuzz-client -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl -n keybuzz-admin-dev get deploy keybuzz-admin -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Attendu:**
- Client: `ghcr.io/keybuzzio/keybuzz-client:v0.2.13-dev`
- Admin: `ghcr.io/keybuzzio/keybuzz-admin:v1.0.54-dev`

### 2. VÃ©rifier /debug/version

```bash
# Client
curl -s https://client-dev.keybuzz.io/debug/version | jq '.version, .gitSha'

# Admin
curl -s https://admin-dev.keybuzz.io/debug/version | jq '.version, .gitSha'
```

**Attendu:**
- Client: version: "0.2.13-dev", gitSha: "<sha du commit 8e1575f>"
- Admin: version: "1.0.54-dev", gitSha: "<sha du commit e4bffe7>"

### 3. VÃ©rifier les footers

**Client:**
- Ouvrir https://client-dev.keybuzz.io/debug
- VÃ©rifier que le footer affiche: `Version: v0.2.13-dev (sha: <sha>)`

**Admin:**
- Ouvrir https://admin-dev.keybuzz.io
- VÃ©rifier que le footer sidebar affiche: `KeyBuzz Admin v1.0.54-dev (sha: <sha>)`

### 4. Confirmation "versions affichÃ©es = versions dÃ©ployÃ©es"

**CritÃ¨res:**
- âœ… Image K8s dÃ©ployÃ©e = tag dans deployment.yaml
- âœ… Version affichÃ©e dans /debug/version = version dans package.json
- âœ… Git SHA affichÃ© dans /debug/version = git SHA du commit dÃ©ployÃ©
- âœ… Footer affiche la mÃªme version que /debug/version
- âœ… Footer affiche le mÃªme git SHA que /debug/version

## Prochaines Ã©tapes

1. **Rebuild Docker (Ã  faire):**
   - Rebuild Client: `docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-client:v0.2.13-dev .`
   - Rebuild Admin: `docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-admin:v1.0.54-dev .`
   - Push vers ghcr.io/keybuzzio (via CI/CD ou manuellement)

2. **Rollout (aprÃ¨s rebuild):**
   - ArgoCD sync automatique OU
   - `kubectl rollout restart deployment/keybuzz-client -n keybuzz-client-dev`
   - `kubectl rollout restart deployment/keybuzz-admin -n keybuzz-admin-dev`

3. **Validation E2E:**
   - VÃ©rifier /debug/version sur Client et Admin
   - VÃ©rifier les footers
   - Confirmer "versions affichÃ©es = versions dÃ©ployÃ©es"

## Commits

**KeyBuzz Client:**
- `8e1575f` - PH11-VERSION-01: Add build metadata generation + debug/version route
- Repo: https://github.com/keybuzzio/keybuzz-client

**KeyBuzz Admin:**
- `e4bffe7` - PH11-VERSION-01: Add build metadata generation + debug/version route + sidebar footer fix
- Repo: https://github.com/keybuzzio/keybuzz-admin

**KeyBuzz Infra:**
- `8151fe9` - PH11-VERSION-01: Update deployment tags to v0.2.13-dev (client) and v1.0.54-dev (admin)
- Repo: https://github.com/keybuzzio/keybuzz-infra

## Notes importantes

- Les metadata sont gÃ©nÃ©rÃ©es au build time (pas au runtime)
- Le fichier `src/lib/build-metadata.ts` est gÃ©nÃ©rÃ© automatiquement, ne pas le commiter
- Le script `generate-build-metadata.py` s'exÃ©cute avant `npm run build` (via prebuild script)
- Les images Docker doivent Ãªtre rebuildÃ©es avec les nouveaux tags avant le rollout
- Les manifests K8s sont dÃ©jÃ  mis Ã  jour, ArgoCD les appliquera aprÃ¨s le rebuild Docker

## Contraintes respectÃ©es

- âœ… DEV ONLY (pas de modification PROD)
- âœ… GitOps (changements commitÃ©s et pushÃ©s)
- âœ… Pas de modifs SSH keys
- âœ… Pas de hacks cache (metadata gÃ©nÃ©rÃ©es au build time)
- âœ… Source of truth: K8s images + git SHA

---

**PH11-VERSION-01-FINALIZE - TerminÃ©**

**Date:** 2026-01-04

**Status:** Manifests K8s mis Ã  jour, images Docker Ã  rebuildre avant rollout.
