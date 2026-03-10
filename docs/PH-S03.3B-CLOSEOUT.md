# PH-S03.3B — Closeout PH-S03.3A + PH-S03.2J (DEV only, GitOps only)

**Date :** 2026-01-30  
**Périmètre :** Finaliser PH-S03.3A (api.ts erreurs explicites) et PH-S03.2J (ArgoCD selector immutable) avec preuves runtime.  
**Environnement :** keybuzz-seller-dev uniquement.

**Règles absolues :** DEV only, GitOps only, aucun `kubectl apply` / `set image`, aucun secret en clair, bastion install-v3 / SSH inchangé.

---

## 1. Résumé des changements

| Ticket   | Périmètre              | Fichiers principaux |
|----------|------------------------|----------------------|
| PH-S03.3A | seller-client (api.ts) | `keybuzz-seller/seller-client/src/lib/api.ts` |
| PH-S03.2J | keybuzz-infra (GitOps) | `keybuzz-infra/k8s/keybuzz-seller-dev/*` (kustomization + manifests) |

---

## 2. A) GitOps — Commits et push

### Fichiers à committer (depuis la racine du repo V3)

**PH-S03.3A (seller-client) :**
- `keybuzz-seller/seller-client/src/lib/api.ts` — messages explicites 401/422/500 + log safe `[api] status endpoint`, plus de "Unknown error"

**PH-S03.2J (keybuzz-infra) :**
- `keybuzz-infra/k8s/keybuzz-seller-dev/kustomization.yaml` — suppression commonLabels + commentaire PH-S03.2J
- `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-client.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/service-client.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/service-api.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/ingress-client.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/ingress-api.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/externalsecret-postgres.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/externalsecret-vault.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/configmap-migration-006.yaml`
- `keybuzz-infra/k8s/keybuzz-seller-dev/job-migrate-006.yaml`

**Rapports (optionnel mais recommandé) :**
- `keybuzz-infra/docs/PH-S03.3A-WIZARD-UNKNOWN-ERROR-FIX.md`
- `keybuzz-infra/docs/PH-S03.2J-GITOPS-CLEANUP.md`
- `keybuzz-infra/docs/PH-S03.3B-CLOSEOUT.md` (ce document)

### Commandes suggérées (depuis la racine du repo)

```bash
# Option 1 : un commit groupé
git add keybuzz-seller/seller-client/src/lib/api.ts
git add keybuzz-infra/k8s/keybuzz-seller-dev/
git add keybuzz-infra/docs/PH-S03.3A-WIZARD-UNKNOWN-ERROR-FIX.md keybuzz-infra/docs/PH-S03.2J-GITOPS-CLEANUP.md keybuzz-infra/docs/PH-S03.3B-CLOSEOUT.md
git commit -m "PH-S03.3A + PH-S03.2J: erreurs explicites api.ts + fix ArgoCD selector immutable (DEV)"

# Option 2 : deux commits séparés
git add keybuzz-seller/seller-client/src/lib/api.ts
git commit -m "PH-S03.3A: api.ts erreurs explicites 401/422/500 + log safe (plus de Unknown error)"
git add keybuzz-infra/k8s/keybuzz-seller-dev/ keybuzz-infra/docs/PH-S03.3A-WIZARD-UNKNOWN-ERROR-FIX.md keybuzz-infra/docs/PH-S03.2J-GITOPS-CLEANUP.md keybuzz-infra/docs/PH-S03.3B-CLOSEOUT.md
git commit -m "PH-S03.2J: suppression commonLabels keybuzz-seller-dev (fix selector immutable ArgoCD)"

# Push (branche courante)
git push
```

### Preuve commits (à remplir après push)

| Commit (hash court) | Message |
|---------------------|---------|
| `________________` | PH-S03.3A: api.ts … (ou commit groupé) |
| `________________` | PH-S03.2J: suppression commonLabels … |

---

## 3. B) ArgoCD — Sync et preuve

### Commandes (depuis le bastion ou une machine avec accès au cluster + ArgoCD CLI)

```bash
# Sync manuel de l’app (après push sur la branche suivie par ArgoCD, ex. main)
argocd app sync keybuzz-seller-dev

# Statut détaillé
argocd app get keybuzz-seller-dev

# Ou via kubectl
kubectl get application -n argocd keybuzz-seller-dev -o yaml
```

### Preuve ArgoCD (à remplir après sync)

| Champ        | Valeur attendue | Valeur observée |
|-------------|------------------|------------------|
| Sync Status | Synced           | ________________ |
| Health      | Healthy          | ________________ |
| Revision    | commit hash (main) | ________________ |

**Extrait de sortie (coller ci-dessous) :**
```
Sync Status: Synced
Health: Healthy
...
```

---

## 4. C) Runtime proof (read-only)

### Commandes (depuis le bastion, read-only)

```bash
# Deployments — images déclarées
kubectl -n keybuzz-seller-dev get deploy seller-api seller-client -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image

# Pods — image + imageID (réellement tourné)
kubectl -n keybuzz-seller-dev get pod -l app=seller-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\t"}{.status.containerStatuses[0].imageID}{"\n"}{end}'
kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\t"}{.status.containerStatuses[0].imageID}{"\n"}{end}'
```

### Conformité attendue (manifests Git)

| Ressource      | Image (manifest) | Attendu runtime |
|----------------|------------------|------------------|
| seller-api     | `ghcr.io/keybuzzio/seller-api@sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16` | Même digest (image + imageID) |
| seller-client  | `ghcr.io/keybuzzio/seller-client:v1.0.0` | Même tag |

### Preuve runtime (à remplir)

| Deploy / Pod | Image affichée | imageID (extrait) | Conforme O/N |
|--------------|----------------|-------------------|--------------|
| seller-api   | ________________ | ________________ | ____ |
| seller-client| ________________ | ________________ | ____ |

---

## 5. D) Wizard proof (UI)

### Étapes de reproduction

1. Ouvrir https://seller-dev.keybuzz.io (session KeyBuzz valide).
2. Aller à Catalog sources → Créer une source (wizard).
3. Remplir au moins : nom, type (ex. CSV), étape champs si demandée.
4. Aller jusqu’à l’étape finale (ou jusqu’à une erreur si config partielle).

### Critères de succès

- **Si tout réussit :** fin du wizard sans message rouge.
- **Si une erreur survient (ex. 401, 422, 500) :** le message affiché doit être **explicite** (ex. « Connexion expirée, merci de vous reconnecter », « Champs invalides », « Erreur serveur, réessayez »), **jamais** « Unknown error ».
- **Console :** au moins une ligne du type `[api] <status> <endpoint>` (sans corps ni secrets) en cas d’erreur.

### Preuve UI (à remplir)

- [ ] Parcours wizard effectué (date/heure : ________ )
- [ ] Aucune erreur **OU** erreur explicite (pas « Unknown error »)
- [ ] Extrait console (coller une ligne type `[api] 401 /api/catalog-sources/...` — **sans secrets**) :

```
[api] _____ /api/________________
```

**Screenshot (optionnel) :** décrire ou joindre une capture (message d’erreur explicite ou « no error »).

---

## 6. E) Endpoint FTP proof (API)

Objectif : prouver que « Tester la connexion » ne renvoie **plus 404** (401 / 400 / 422 / 200 acceptables).

### Commande curl (sans creds → attendu 401 Unauthorized, pas 404)

```bash
# Depuis le bastion (remplacer SOURCE_ID par un UUID valide si besoin)
curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection" \
  -H "Content-Type: application/json" -d '{}'
```

**Attendu :** `401` (ou `422` si body invalide). **Pas 404.**

### Preuve endpoint (à remplir)

| Appel | HTTP status observé | Body (masqué : oui/non) | != 404 OK |
|-------|----------------------|--------------------------|-----------|
| POST …/ftp/test-connection (sans auth) | ________ | oui | ____ |

### Bonus — OpenAPI (route présente)

```bash
curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -o '"/api/catalog-sources/[^"]*ftp[^"]*"'
# Ou via proxy
curl -s https://seller-dev.keybuzz.io/api/seller/openapi.json | grep -o '"/api/catalog-sources/[^"]*ftp[^"]*"'
```

**Attendu :** au moins une ligne contenant `ftp` et `test-connection` (ou équivalent). Coller un extrait masqué si besoin :

```
________________
```

---

## 7. Rollback (revert + resync)

En cas de régression :

```bash
# 1) Revert des commits (depuis la racine du repo)
git revert --no-edit <hash_commit_ph33b>   # ou les deux commits PH-S03.3A et PH-S03.2J
git push

# 2) Resync ArgoCD pour réappliquer l’état Git précédent
argocd app sync keybuzz-seller-dev
```

**À noter :** après revert de PH-S03.2J, les manifests retrouveront `commonLabels` ; si le cluster a déjà des Deployments avec selector « étendu » par un sync précédent, un nouveau sync pourrait à nouveau provoquer une erreur « selector immutable ». Dans ce cas, la procédure de rollback peut nécessiter une intervention manuelle (ex. recréer le Deployment avec l’ancien selector) ou de ne pas revert PH-S03.2J et de ne revert que PH-S03.3A si la régression est uniquement côté client.

---

## 8. Checklist finale

| # | Élément | Fait (à cocher) |
|---|--------|------------------|
| 1 | Commit(s) PH-S03.3A + PH-S03.2J (et push) | |
| 2 | ArgoCD keybuzz-seller-dev : Synced + Healthy | |
| 3 | Preuve runtime : images deploy/pod conformes aux manifests | |
| 4 | Preuve UI : plus de « Unknown error », message explicite ou « no error » | |
| 5 | Preuve endpoint : POST ftp/test-connection != 404 (401/422/200 ok) | |
| 6 | Rollback documenté (revert + resync) | |

---

**Statut :** Closeout rédigé. À compléter avec les preuves (commits, ArgoCD, runtime, UI, endpoint) après exécution sur le bastion / post-push.
