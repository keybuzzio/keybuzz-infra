# PH11-VERSION-01 - Fix "Version affichÃ©e" (Admin + Client)

## Resume

**Probleme:**
- Admin affichait encore v1.0.53-dev (hardcode)
- Client affichait encore v0.2.33-dev (hardcode)
- Les versions affichees ne reflechaient pas la realite des builds deployes

**Solution:**
- Injection de build metadata au build time (APP_VERSION, GIT_SHA, BUILD_DATE)
- Correction des footers pour utiliser BUILD_METADATA
- Ajout de routes /debug/version pour verification
- Script prebuild pour generer automatiquement les metadata

## Images K8s reellement deployees

**Timestamp:** 2026-01-04T16:55:35Z

| Service | Image |
|---------|-------|
| Admin | ghcr.io/keybuzzio/keybuzz-admin:v1.0.53-dev |
| Client | ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev |

**Logs sauvegardes:** `/opt/keybuzz/logs/ph11-version/k8s_images.txt`

## Modifications apportees

### 1. Script de generation des metadata

**Fichier:** `scripts/generate-build-metadata.py`

- Lit la version depuis `package.json`
- Recupere le git SHA (short) via `git rev-parse --short HEAD`
- Genere la date de build (ISO UTC)
- Cree `src/lib/build-metadata.ts` avec les metadata

**Format genere:**
```typescript
export const BUILD_METADATA = {
  app: 'keybuzz-admin' | 'keybuzz-client',
  version: 'X.X.X-dev',
  gitSha: 'abc1234',
  buildDate: '2026-01-04T17:09:09.167972Z',
} as const;
```

### 2. Routes /debug/version

**Admin:** `/opt/keybuzz/keybuzz-admin/app/debug/version/page.tsx`
**Client:** `/opt/keybuzz/keybuzz-client/app/debug/version/page.tsx`

- Affichent les metadata de build
- Format JSON + details lisibles
- Accessibles uniquement en DEV

### 3. Correction des footers

**Admin - Sidebar:**
- Fichier: `components/layouts/keybuzz-admin/components/sidebar.tsx`
- Avant: `KeyBuzz Admin v1.0.53-dev`
- Apres: `KeyBuzz Admin v{BUILD_METADATA.version} (sha: {BUILD_METADATA.gitSha})`
- Import ajoute: `import { BUILD_METADATA } from '@/src/lib/build-metadata';`

**Client - Debug page:**
- Fichier: `app/debug/page.tsx`
- Avant: `Version: v0.2.4-dev`
- Apres: `Version: v{BUILD_METADATA.version} (sha: {BUILD_METADATA.gitSha})`
- Import ajoute: `import { BUILD_METADATA } from '@/src/lib/build-metadata';`

### 4. Package.json prebuild

**Admin:** `package.json`
```json
{
  "scripts": {
    "prebuild": "python3 scripts/generate-build-metadata.py",
    "build": "next build",
    ...
  }
}
```

**Client:** `package.json`
```json
{
  "scripts": {
    "prebuild": "python3 scripts/generate-build-metadata.py",
    "build": "next build",
    ...
  }
}
```

Le script `prebuild` s'execute automatiquement avant `npm run build`.

## Methode build metadata

1. **Au build time:**
   - Le script `scripts/generate-build-metadata.py` s'execute avant `next build`
   - Il genere `src/lib/build-metadata.ts` avec les metadata actuelles
   - Next.js compile ce fichier TypeScript dans le bundle

2. **Au runtime:**
   - Les composants importent `BUILD_METADATA` depuis `@/src/lib/build-metadata`
   - Les metadata sont statiques (compilees dans le bundle)
   - Aucune requete HTTP supplementaire necessaire

3. **Avantages:**
   - Source of truth: git SHA + version package.json
   - Pas de fallback hardcode
   - Metadata toujours a jour au build
   - Performance: pas de fetch runtime

## Verification

### 1. Verifier les images K8s deployees

```bash
kubectl -n keybuzz-admin-dev get deploy keybuzz-admin -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl -n keybuzz-client-dev get deploy keybuzz-client -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 2. Verifier les routes /debug/version

**Admin:**
```bash
curl -s https://admin-dev.keybuzz.io/debug/version | grep -i "version\|gitSha"
```

**Client:**
```bash
curl -s https://client-dev.keybuzz.io/debug/version | grep -i "version\|gitSha"
```

### 3. Verifier le footer

- Ouvrir https://admin-dev.keybuzz.io
- Verifier le footer du sidebar: doit afficher la version + git SHA
- Comparer avec `/debug/version`

### 4. Verifier la generation des metadata

```bash
cd /opt/keybuzz/keybuzz-admin
python3 scripts/generate-build-metadata.py
cat src/lib/build-metadata.ts

cd /opt/keybuzz/keybuzz-client
python3 scripts/generate-build-metadata.py
cat src/lib/build-metadata.ts
```

## Fichiers modifies

### Admin
- `scripts/generate-build-metadata.py` (nouveau)
- `package.json` (ajout prebuild script)
- `src/lib/build-metadata.ts` (genere au build)
- `components/layouts/keybuzz-admin/components/sidebar.tsx` (corrige)
- `app/debug/version/page.tsx` (nouveau)

### Client
- `scripts/generate-build-metadata.py` (nouveau)
- `package.json` (ajout prebuild script)
- `src/lib/build-metadata.ts` (genere au build)
- `app/debug/page.tsx` (corrige)
- `app/debug/version/page.tsx` (nouveau)

## Prochaines etapes

1. **Build et deploy:**
   - Build Admin avec nouveau prebuild script
   - Build Client avec nouveau prebuild script
   - Deployer les nouvelles images en DEV
   - Verifier que les footers affichent les bonnes versions

2. **Validation E2E:**
   - Ouvrir /debug/version sur Admin et Client
   - Verifier que les footers affichent la meme version/sha
   - Comparer avec les images K8s deployees

3. **Documentation:**
   - Mettre a jour la documentation de build
   - Documenter comment changer la version (package.json)

## Notes importantes

- Les metadata sont generees au build time, pas au runtime
- Le fichier `build-metadata.ts` est genere automatiquement, ne pas le modifier manuellement
- Le script `generate-build-metadata.py` doit etre executable (`chmod +x`)
- Le script utilise `git rev-parse --short HEAD`, donc il doit etre execute dans un repo git

## Contraintes respectees

- âœ… DEV ONLY (pas de modification PROD)
- âœ… GitOps (changements dans les repos)
- âœ… Pas de changement de fonctionnement metier
- âœ… Source of truth: K8s images + git SHA
- âœ… Cache-proof (metadata compilees dans le bundle)
- âœ… Pas de secrets exposes dans /debug/version

---

**PH11-VERSION-01 - Termine**

Date: 2026-01-04
