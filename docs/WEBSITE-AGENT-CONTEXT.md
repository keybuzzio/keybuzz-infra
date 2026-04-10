# Contexte pour l'Agent Site Vitrine keybuzz.pro

> Document de briefing pour un agent Cursor travaillant EXCLUSIVEMENT sur le site vitrine `www.keybuzz.pro`
> Date : 10 avril 2026

---

## 1. QU'EST-CE QUE LE SITE VITRINE ?

Le site `www.keybuzz.pro` est le **site marketing** de KeyBuzz. C'est un site Next.js **statique/SSG** qui présente le produit, les tarifs, et redirige vers la plateforme SaaS (`client.keybuzz.io`) pour l'inscription.

**Ce n'est PAS** :
- La plateforme SaaS (c'est `keybuzz-client` → `client.keybuzz.io`)
- L'API backend (c'est `keybuzz-api` → `api.keybuzz.io`)
- L'admin panel (c'est `keybuzz-admin` → `admin.keybuzz.io`)
- Le Marketing OS (c'est `keybuzz-studio` → `studio.keybuzz.io`)
- Le module seller (c'est `keybuzz-seller` → `seller.keybuzz.io`)

---

## 2. ARCHITECTURE

| Composant | Valeur |
|---|---|
| **Repo GitHub** | `keybuzzio/keybuzz-website` |
| **Stack** | Next.js (App Router) |
| **Bastion** | `/opt/keybuzz/keybuzz-website/` |
| **Registry** | `ghcr.io/keybuzzio/keybuzz-website` |
| **Image actuelle** | `v0.5.1-ph3317b-prod-links` (DEV + PROD identiques) |
| **Port conteneur** | 3000 |

### Namespaces K8s

| Env | Namespace | Replicas | URL | Auth |
|---|---|---|---|---|
| DEV | `keybuzz-website-dev` | 1 | `preview.keybuzz.pro` | Basic auth (`preview-basic-auth`) |
| PROD | `keybuzz-website-prod` | 2 | `www.keybuzz.pro` + `keybuzz.pro` | Public (TLS Let's Encrypt) |

### Variables d'environnement

| Variable | DEV | PROD |
|---|---|---|
| `NEXT_PUBLIC_SITE_MODE` | `preview` | `production` |
| `NEXT_PUBLIC_CLIENT_APP_URL` | `https://client-dev.keybuzz.io` | `https://client.keybuzz.io` |
| `NODE_ENV` | `production` | `production` |

### Manifests K8s (dans `keybuzz-infra`)

| Fichier | Contenu |
|---|---|
| `k8s/website-dev/deployment.yaml` | Deployment DEV |
| `k8s/website-dev/service.yaml` | Service ClusterIP DEV |
| `k8s/website-dev/ingress.yaml` | Ingress `preview.keybuzz.pro` (basic auth) |
| `k8s/website-prod/deployment.yaml` | Deployment + Service + Namespace PROD |
| `k8s/website-prod/ingress.yaml` | Ingress `www.keybuzz.pro` + `keybuzz.pro` (TLS) |

---

## 3. CE QUI S'EST PASSÉ AVANT — LEÇONS CRITIQUES

### Incident 1 : NEXT_PUBLIC_ au build time (PH-STUDIO-04C)

**Problème** : L'image frontend PROD de Studio avait été créée par re-tag de l'image DEV. Mais `NEXT_PUBLIC_STUDIO_API_URL` était "bakée" au build time avec la valeur DEV. Résultat : le frontend PROD appelait l'API DEV → CORS erreurs, login cassé.

**Leçon** : Si le site vitrine utilise des `NEXT_PUBLIC_*` qui diffèrent entre DEV et PROD (comme `NEXT_PUBLIC_CLIENT_APP_URL`), chaque environnement nécessite un build Docker séparé avec les bons `--build-arg`. **NE JAMAIS re-tag une image DEV en PROD** dans ce cas.

### Incident 2 : Contamination code Studio dans Client (PH143-R1/R2)

**Problème** : Un merge Git a accidentellement inclus des fichiers Studio dans le build Docker du Client. Le `.dockerignore` ne filtrait pas ces fichiers.

**Leçon** : Vérifier qu'aucun fichier d'un autre produit ne se retrouve dans l'image Docker. Ajouter un `.dockerignore` explicite si nécessaire. Critère de validation : "0 fichier d'un autre produit dans l'image".

### Incident 3 : Encodage UTF-8 (PH-ONBOARDING-UTF8-FIX-01)

**Problème** : Les scripts Python de patch écrivaient les caractères accentués sous forme de séquences unicode (`\u00e9` au lieu de `é`). Dans du texte JSX brut, ces séquences sont affichées littéralement.

**Leçon** : Toujours utiliser `encoding="utf-8"` dans les fichiers Python et des raw strings (`r"..."`) pour les patterns. Vérifier les fichiers après patch avec `grep -n 'u00'`.

### Incident 4 : GitHub Push Protection (PH-GITOPS-UNBLOCK-01)

**Problème** : Des tokens Vault et secrets étaient présents dans l'historique Git de `keybuzz-infra`. GitHub Push Protection bloquait tous les push.

**Leçon** : Ne JAMAIS committer de secrets. Si c'est fait accidentellement, utiliser `git-filter-repo` pour nettoyer l'historique AVANT de pusher.

### Incident 5 : Split-brain API URLs (Client SaaS)

**Problème** : Le client Next.js utilisait DEUX variables d'env pour l'API (`NEXT_PUBLIC_API_URL` et `NEXT_PUBLIC_API_BASE_URL`). Une seule était définie au build → le Dashboard appelait PROD et les Messages appelaient DEV.

**Leçon** : Vérifier TOUTES les variables `NEXT_PUBLIC_*` au build time. Le site vitrine n'a normalement PAS de variables API backend, mais si vous en ajoutez, assurez-vous de les passer via `--build-arg`.

---

## 4. PÉRIMÈTRE DE TRAVAIL — CE QUE VOUS POUVEZ TOUCHER

### OUI — Vous pouvez modifier :
- Le code source dans `/opt/keybuzz/keybuzz-website/` (repo `keybuzzio/keybuzz-website`)
- Les manifests K8s dans `keybuzz-infra/k8s/website-dev/` et `keybuzz-infra/k8s/website-prod/`
- Les images Docker `ghcr.io/keybuzzio/keybuzz-website:*`

### NON — Ne JAMAIS toucher :
- `/opt/keybuzz/keybuzz-client/` ni `keybuzz-infra/k8s/keybuzz-client-*`
- `/opt/keybuzz/keybuzz-api/` ni `keybuzz-infra/k8s/keybuzz-api-*`
- `/opt/keybuzz/keybuzz-admin/` ni `keybuzz-infra/k8s/keybuzz-admin*`
- `/opt/keybuzz/keybuzz-studio/` ni `keybuzz-infra/k8s/keybuzz-studio-*`
- `/opt/keybuzz/keybuzz-backend/` ni `keybuzz-infra/k8s/keybuzz-backend-*`
- `/opt/keybuzz/keybuzz-seller/` ni `keybuzz-infra/k8s/keybuzz-seller-*`
- Tout deployment dans un namespace autre que `keybuzz-website-dev` / `keybuzz-website-prod`

---

## 5. PROCÉDURE BUILD + DEPLOY

### Accès bastion
```bash
ssh root@46.62.171.61 -i ~/.ssh/id_rsa_keybuzz_v3
# PowerShell Windows :
ssh root@46.62.171.61 -i $env:USERPROFILE\.ssh\id_rsa_keybuzz_v3
```

### Build DEV
```bash
cd /opt/keybuzz/keybuzz-website
NEW_TAG="ghcr.io/keybuzzio/keybuzz-website:v<VERSION>-<FEATURE>-dev"
docker build --no-cache -t "$NEW_TAG" .
docker push "$NEW_TAG"
kubectl set image deploy/keybuzz-website keybuzz-website="$NEW_TAG" -n keybuzz-website-dev
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-dev
```

### Build PROD
```bash
cd /opt/keybuzz/keybuzz-website
NEW_TAG="ghcr.io/keybuzzio/keybuzz-website:v<VERSION>-<FEATURE>-prod"
docker build --no-cache -t "$NEW_TAG" .
docker push "$NEW_TAG"
kubectl set image deploy/keybuzz-website keybuzz-website="$NEW_TAG" -n keybuzz-website-prod
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod
```

### GitOps (OBLIGATOIRE après chaque deploy)
Mettre à jour les fichiers dans `keybuzz-infra/` :
1. `k8s/website-dev/deployment.yaml` (image tag)
2. `k8s/website-prod/deployment.yaml` (image tag)
3. Commit + push sur GitHub (`keybuzzio/keybuzz-infra`)

### Vérification post-deploy
```bash
# DEV
curl -s https://preview.keybuzz.pro -u user:password | head -5
kubectl get pods -n keybuzz-website-dev

# PROD
curl -sI https://www.keybuzz.pro | head -5
kubectl get pods -n keybuzz-website-prod
```

### Rollback d'urgence
```bash
kubectl set image deploy/keybuzz-website keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:<PREVIOUS_TAG> -n keybuzz-website-<env>
```

---

## 6. PLANS TARIFAIRES (pour la page pricing)

| Plan | Prix | KBActions/mois |
|---|---|---|
| Starter | 97 EUR/mois | 0 |
| Pro (recommandé) | 297 EUR/mois | 1000 |
| Autopilote | 497 EUR/mois | 3500 |

### Packs KBActions premium
- 50 KBA : 24.90 EUR
- 200 KBA : 69.90 EUR
- 500 KBA : 149.90 EUR

Les CTA doivent pointer vers `https://client.keybuzz.io` (PROD) ou `https://client-dev.keybuzz.io` (DEV) selon l'env.

---

## 7. RÈGLES GÉNÉRALES DU PROJET

1. **Toujours répondre en français**
2. **JAMAIS de `:latest`** sur les images Docker — tags versionnés uniquement
3. **JAMAIS toucher `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/`**
4. **JAMAIS mentionner eDesk** (concurrent) dans le code ou l'UI
5. **DEV d'abord, puis PROD** — toujours tester en DEV avant promotion
6. **Documentation en français**
7. **Builds Docker sur le bastion** (pas en local Windows)
8. **Attention au CRLF** — convertir avec `sed -i 's/\r//' script.sh` si copié depuis Windows

---

## 8. INFRA RÉSUMÉ

| Service | IP / URL |
|---|---|
| Bastion SSH | `root@46.62.171.61` |
| Registry Docker | `ghcr.io/keybuzzio/` |
| Cluster K8s | kubeadm HA (PAS K3s) |
| Ingress | NGINX Ingress (DaemonSet) |
| TLS PROD | cert-manager + letsencrypt-prod |
| Monitoring | Prometheus + Grafana (`grafana-dev.keybuzz.io`) |

---

## 9. CHECKLIST AVANT CHAQUE DEPLOY

- [ ] Code modifié uniquement dans `keybuzz-website`
- [ ] Aucun fichier d'un autre produit dans l'image Docker
- [ ] Build `--no-cache` sur le bastion
- [ ] Tag versionné (pas `:latest`)
- [ ] DEV testé et validé avant PROD
- [ ] GitOps manifest mis à jour
- [ ] Commit + push `keybuzz-infra`
- [ ] Rollback documenté dans le rapport
