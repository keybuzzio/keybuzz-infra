# PH-WEBSITE-IMAGE-CACHE-FIX-01 — Fix permissions cache images Next.js

> Date : 10 avril 2026
> Environnement : DEV + PROD
> Type : fix infrastructure (permissions Dockerfile)
> Scope : keybuzz-website uniquement — zero impact SaaS

---

## Objectif

Corriger l'affichage des images cassées sur www.keybuzz.pro :
- Logo header (icon.png) absent
- Logos marketplace manquants (Darty, Cdiscount, eBay, Fnac)
- Photo fondateur (ludovic.jpg) absente

---

## Cause racine

L'optimiseur d'images Next.js (`/_next/image`) a besoin d'écrire dans `/app/.next/cache/` pour stocker les images optimisées. Le Dockerfile crée un utilisateur non-root `nextjs` (uid 1001) mais le répertoire `/app/.next/` appartient à `root`. Résultat :

```
EACCES: permission denied, mkdir '/app/.next/cache'
```

Chaque requête image déclenche une ré-optimisation complète (cache: MISS permanent), surchargeant le pod (100m CPU, 128Mi RAM) et provoquant des timeouts côté client.

Les SVG (Amazon, Shopify, WooCommerce) n'étaient pas affectés car ils sont servis en statique sans passer par l'optimiseur.

---

## Fix appliqué

**Fichier modifié** : `Dockerfile` (keybuzz-website) — 1 ligne ajoutée

```dockerfile
# Stage 3: Production — avant USER nextjs
RUN mkdir -p /app/.next/cache && chown -R nextjs:nodejs /app/.next/cache
```

**Commit inclus** : le build-arg `NEXT_PUBLIC_CLIENT_APP_URL` pré-existant (non déployé auparavant) a été inclus dans le même commit.

**Fichier non touché** : `src/app/pricing/page.tsx` (modifié localement mais non stagé).

---

## Références Git

| Element | Valeur |
|---|---|
| SHA website | `6dcdc9026d48c761706077cd16d8f19fa9ed004a` |
| Commit message | `fix: grant nextjs user write access to .next/cache for image optimization` |
| SHA infra (DEV) | `ebe291211b5dabcbe568caa63336667d84f700aa` |
| SHA infra (PROD) | `8ca3abe` |

---

## Images déployées

| Env | Image | Digest | Rollback |
|---|---|---|---|
| **PROD** | `ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-prod` | `sha256:5c34af1e8ec866603034263f46f3ac2c5623a634766be573e11a24736848a1c0` | `v0.5.1-ph3317b-prod-links` |
| DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-dev` | `sha256:62a1775af40a3a83ee3e63dea31a9b08b07ebbe607142ebdac9134ad36e6dcd9` | `v0.5.1-ph3317b-prod-links` |

---

## Validation DEV (preview.keybuzz.pro)

| Test | Résultat |
|---|---|
| Logs pod | `Ready in 1408ms` — aucune erreur |
| EACCES | ZERO occurrence |
| Cache `/app/.next/cache/images/` | 6 sous-dossiers créés, owner `nextjs` |
| icon.png 1er appel | HTTP 200, 1653 bytes, cache: MISS |
| icon.png 2ème appel | HTTP 200, 1653 bytes, **cache: HIT** |
| ludovic.jpg 1er appel | HTTP 200, 39306 bytes, cache: MISS |
| ludovic.jpg 2ème appel | HTTP 200, 39306 bytes, **cache: HIT** |
| darty/cdiscount/ebay/fnac | HTTP 200, toutes servies correctement |

**DEV validé par le client avant promotion PROD.**

---

## Validation PROD (www.keybuzz.pro)

| Test | Résultat |
|---|---|
| Homepage `/` | HTTP 200, 84 508 bytes |
| Logs pod | `Ready in 1217ms` — aucune erreur |
| EACCES | ZERO occurrence |
| Cache peuplé | 8 sous-dossiers dans `/app/.next/cache/images/` |
| Replicas | 2/2 Running (worker-01 + worker-05) |

### Images via https://www.keybuzz.pro

| Image | Status | Taille | Cache (2ème appel) |
|---|---|---|---|
| icon.png (logo header) | HTTP 200 | 1 653 bytes | **x-nextjs-cache: HIT** |
| ludovic.jpg (photo fondateur) | HTTP 200 | 39 306 bytes | **x-nextjs-cache: HIT** |
| darty.png | HTTP 200 | 4 071 bytes | **x-nextjs-cache: HIT** |
| cdiscount.jpg | HTTP 200 | 6 004 bytes | HTTP 200 |
| ebay.png | HTTP 200 | 3 472 bytes | HTTP 200 |
| fnac.png | HTTP 200 | 3 068 bytes | HTTP 200 |

---

## Scope vérifié

| Vérification | Résultat |
|---|---|
| `git diff --stat` infra (PROD) | 1 seul fichier : `k8s/website-prod/deployment.yaml` |
| Namespaces touchés | `keybuzz-website-dev` + `keybuzz-website-prod` uniquement |
| Impact Client/Studio/Admin/API | ZERO |
| `pricing/page.tsx` | Non touché |
| Tags immuables | Oui (DEV ≠ PROD, noms distincts) |
| Méthode de déploiement | GitOps (manifest → commit → push → apply) |

---

## Rollback

### GitOps (procédure standard)

```bash
# 1. Modifier le manifest
sed -i 's/v0.6.0-fix-image-cache-prod/v0.5.1-ph3317b-prod-links/' \
  /opt/keybuzz/keybuzz-infra/k8s/website-prod/deployment.yaml

# 2. Commit + push
cd /opt/keybuzz/keybuzz-infra
git add k8s/website-prod/deployment.yaml
git commit -m "rollback: website-prod to v0.5.1-ph3317b-prod-links"
git push origin main

# 3. Apply
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod
```

### Urgence (secours immédiat)

```bash
kubectl set image deploy/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.5.1-ph3317b-prod-links \
  -n keybuzz-website-prod
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod
```

---

## Verdict

**DEV : VALIDÉ** — Preview validé par le client, cache fonctionnel, zero EACCES.

**PROD : VALIDÉ** — Toutes les images servies en HTTP 200, cache HIT confirmé, logs propres, 2 replicas stables, zero impact SaaS.
