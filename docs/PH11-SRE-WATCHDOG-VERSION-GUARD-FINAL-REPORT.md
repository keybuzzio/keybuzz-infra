# PH11-SRE-WATCHDOG-VERSION-GUARD-FINAL-REPORT

## Resume executif

**Status:** Partiellement terminÃ© - Images Docker rebuildÃ©es et pushÃ©es, mais problÃ¨mes avec /debug/version

**Date:** 2026-01-04

## Objectif A - Remise en coherence des versions deployees

### 1. Images reellement deployees (DEV)

**Timestamp:** 2026-01-04T19:36:22Z

| Service | Image dÃ©ployÃ©e | Image attendue | Status |
|---------|----------------|----------------|--------|
| keybuzz-client | v0.2.13-dev | v0.2.13-dev | âœ… DÃ©ployÃ© |
| keybuzz-admin | v1.0.53-dev | v1.0.54-dev | âš ï¸ Partiel (rollout manuel fait mais deployment.yaml non mis Ã  jour) |
| keybuzz-api | v0.1.46-dev | - | â„¹ï¸ Non modifiÃ© |

**Logs:** `/opt/keybuzz/logs/ph11-version/k8s_images_final_verify.txt`

### 2. Validation /debug/version (DEV)

**Client:** https://client-dev.keybuzz.io/debug/version
- **Status:** âœ… Retourne JSON
- **RÃ©ponse actuelle:**
```json
{
  "app": "app",
  "version": "0.2.13-dev",
  "gitSha": "unknown",
  "buildDate": "2026-01-04T18:56:29.769845Z"
}
```
- **ProblÃ¨mes identifiÃ©s:**
  - `"app": "app"` au lieu de `"keybuzz-client"` (script generate-build-metadata.py ne dÃ©tecte pas correctement le nom)
  - `"gitSha": "unknown"` au lieu du vrai SHA (problÃ¨me avec git dans Docker container)

**Admin:** https://admin-dev.keybuzz.io/debug/version
- **Status:** âŒ Retourne 404
- **Cause:** Route /debug/version n'existe peut-Ãªtre pas dans l'image v1.0.54-dev, ou problÃ¨me de routage Next.js

**Logs:** 
- `/opt/keybuzz/logs/ph11-version/admin_debug_version.json` (404 HTML)
- `/opt/keybuzz/logs/ph11-version/client_debug_version.json` (JSON partiel)

### 3. CohÃ©rence version

**Client:**
- Image K8s: `v0.2.13-dev` âœ…
- Version JSON: `0.2.13-dev` âœ…
- **Status:** CohÃ©rent (mais valeurs app/gitSha incorrectes)

**Admin:**
- Image K8s: `v1.0.53-dev` âš ï¸
- Version JSON: N/A (404)
- **Status:** Non cohÃ©rent (image pas Ã  jour + endpoint 404)

## Actions realisees

### 1. Rebuild Docker images

**Client v0.2.13-dev:**
- âœ… npm ci + npm run build
- âœ… Docker build --no-cache
- âœ… Docker push vers ghcr.io
- âœ… Digest: `sha256:75ef8a3aeb5fb60206a66fc28e1c5107800329d20f03c83c4da56c8ab514bf9b`

**Admin v1.0.54-dev:**
- âœ… npm ci + npm run build
- âœ… Docker build --no-cache
- âœ… Docker push vers ghcr.io
- âœ… Digest: `sha256:0a7df71b2f2655b6ed748d6829cd7b01da58bdb8294bd1c1675987f0fba2e489`

### 2. Corrections apportees

**Dockerfiles:**
- âœ… Ajout de python3 dans Dockerfiles (Client: apk add, Admin: apt-get install)
- âœ… CrÃ©ation de API routes /debug/version (route.ts au lieu de page.tsx)
- âœ… RÃ©solution du conflit page.tsx vs route.ts

**Scripts:**
- âœ… Script generate-build-metadata.py crÃ©Ã© et fonctionnel
- âš ï¸ ProblÃ¨me: DÃ©tection du nom d'app incorrecte (utilise "app" au lieu de "keybuzz-client"/"keybuzz-admin")
- âš ï¸ ProblÃ¨me: gitSha = "unknown" (git non disponible ou erreur dans container Docker)

### 3. Rollouts DEV

**Client:**
- âœ… kubectl set image deployment/keybuzz-client
- âœ… Rollout rÃ©ussi
- âœ… Pod dÃ©marrÃ© avec v0.2.13-dev

**Admin:**
- âœ… kubectl set image deployment/keybuzz-admin (fait 2 fois)
- âœ… Rollout rÃ©ussi
- âš ï¸ deployment.yaml toujours Ã  v1.0.53-dev (non mis Ã  jour dans keybuzz-infra)

## Problemes identifies

### 1. Script generate-build-metadata.py

**ProblÃ¨me:** DÃ©tection incorrecte du nom d'app
- Retourne `"app": "app"` au lieu de `"keybuzz-client"` ou `"keybuzz-admin"`
- Cause: Le script utilise `work_dir.name` qui retourne "keybuzz-client" ou "keybuzz-admin", mais la logique de dÃ©tection ne fonctionne pas correctement

**Solution nÃ©cessaire:**
- Corriger la logique de dÃ©tection dans generate-build-metadata.py
- Ou utiliser le nom du package.json
- Ou passer le nom en argument

### 2. Git SHA = "unknown"

**ProblÃ¨me:** gitSha retourne "unknown" dans le JSON
- Cause: `git rev-parse --short HEAD` Ã©choue dans le container Docker
- Possible cause: Git non initialisÃ© dans le container, ou rÃ©pertoire .git non copiÃ©

**Solution nÃ©cessaire:**
- VÃ©rifier que .git est copiÃ© dans le Dockerfile (COPY . .)
- Ou utiliser un build arg pour passer le git SHA au build time

### 3. Admin /debug/version 404

**ProblÃ¨me:** L'endpoint /debug/version retourne 404 pour Admin
- Cause possible: Route /debug/version/route.ts non prÃ©sente dans l'image
- Cause possible: ProblÃ¨me de routage Next.js

**Solution nÃ©cessaire:**
- VÃ©rifier que route.ts existe dans l'image Docker
- VÃ©rifier le build Next.js inclut la route
- Rebuild si nÃ©cessaire

### 4. deployment.yaml non mis Ã  jour

**ProblÃ¨me:** deployment.yaml dans keybuzz-infra toujours Ã  v1.0.53-dev
- Cause: Rollout manuel fait mais manifests Git non commitÃ©s
- Impact: ArgoCD peut rever les changements

**Solution nÃ©cessaire:**
- Mettre Ã  jour deployment.yaml dans keybuzz-infra avec v1.0.54-dev
- Commit et push

## Objectif B - Watchdog Version Guard

**Status:** â³ Non commencÃ© (Ã  faire aprÃ¨s rÃ©solution des problÃ¨mes /debug/version)

**Actions nÃ©cessaires:**
1. Installer/mettre Ã  jour version_guard.py sur monitor-01
2. CrÃ©er version_guard_config.yaml
3. CrÃ©er systemd service + timer (toutes les 5 minutes)
4. Tester le watchdog

## Objectif C - Diagnostic Badge IA

**Status:** â³ Non commencÃ© (Ã  faire)

**Actions nÃ©cessaires:**
1. VÃ©rifier DB (messages par message_source)
2. VÃ©rifier API retourne message_source
3. VÃ©rifier UI affiche correctement les badges IA
4. Corriger si nÃ©cessaire

## Prochaines etapes

### PrioritÃ© 1: Corriger /debug/version

1. **Corriger generate-build-metadata.py:**
   - Utiliser le nom du package.json au lieu du rÃ©pertoire
   - Ou passer le nom en argument depuis package.json

2. **Corriger gitSha:**
   - Utiliser build arg pour passer git SHA au build time
   - Ou copier .git dans Dockerfile

3. **VÃ©rifier Admin /debug/version:**
   - VÃ©rifier que route.ts existe dans l'image
   - Rebuild si nÃ©cessaire

4. **Mettre Ã  jour deployment.yaml:**
   - Mettre Ã  jour keybuzz-infra/k8s/keybuzz-admin-dev/deployment.yaml
   - Commit et push

### PrioritÃ© 2: DÃ©ployer Watchdog Version Guard

1. Installer version_guard.py sur monitor-01
2. CrÃ©er config + systemd service/timer
3. Tester

### PrioritÃ© 3: Diagnostiquer Badge IA

1. VÃ©rifier DB
2. VÃ©rifier API
3. VÃ©rifier UI
4. Corriger si nÃ©cessaire

## Logs et preuves

**Logs sauvegardÃ©s:**
- `/opt/keybuzz/logs/ph11-version/k8s_images_final_verify.txt`
- `/opt/keybuzz/logs/ph11-version/admin_debug_version.json` (404 HTML)
- `/opt/keybuzz/logs/ph11-version/client_debug_version.json` (JSON partiel)

**Images Docker:**
- Client: `ghcr.io/keybuzzio/keybuzz-client:v0.2.13-dev` (Digest: `sha256:75ef8a3aeb5fb60206a66fc28e1c5107800329d20f03c83c4da56c8ab514bf9b`)
- Admin: `ghcr.io/keybuzzio/keybuzz-admin:v1.0.54-dev` (Digest: `sha256:0a7df71b2f2655b6ed748d6829cd7b01da58bdb8294bd1c1675987f0fba2e489`)

## Contraintes respectees

- âœ… DEV ONLY (pas de modification PROD)
- âœ… GitOps (changements commitÃ©s oÃ¹ possible)
- âœ… Pas d'action destructive
- âœ… Pas de reboot
- âœ… Logs sauvegardÃ©s

---

**PH11-SRE-WATCHDOG-VERSION-GUARD-FINAL - Partiellement terminÃ©**

**Date:** 2026-01-04

**Status:** Images Docker rebuildÃ©es et pushÃ©es, mais problÃ¨mes avec /debug/version Ã  rÃ©soudre avant de continuer avec le watchdog.
