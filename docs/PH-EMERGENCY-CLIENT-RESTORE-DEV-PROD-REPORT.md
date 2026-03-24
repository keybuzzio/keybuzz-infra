# PH-EMERGENCY-CLIENT-RESTORE-DEV-PROD — Rapport Final

> Date : 20 mars 2026
> Auteur : Agent Cursor (CE)
> Mode : EMERGENCY RESTORE
> Statut : **SERVICE RESTORED**

---

## 1. Contexte

Restore d'urgence des clients DEV et PROD vers les dernieres versions saines connues, apres le deploiement `v3.5.60-signup-fix-*` qui necessitait un rollback.

## 2. Images avant/apres

| Env | Image AVANT restore | Image APRES restore |
|-----|---------------------|---------------------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.60-signup-fix-dev` | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.60-signup-fix-prod` | `ghcr.io/keybuzzio/keybuzz-client:v3.5.58-channels-billing-prod` |

## 3. Methode

### Snapshots sauvegardes (etape 0)
- `/tmp/dev-client-before-emergency-restore.yaml`
- `/tmp/prod-client-before-emergency-restore.yaml`
- `/tmp/dev-client-pods-before-emergency-restore.txt`
- `/tmp/prod-client-pods-before-emergency-restore.txt`

### DEV — GitOps
1. Manifest `k8s/keybuzz-client-dev/deployment.yaml` mis a jour
2. Git commit + push (`71cf871`)
3. ArgoCD hard refresh → auto-sync → rollout

### PROD — GitOps + kubectl set image
1. Manifest `k8s/keybuzz-client-prod/deployment.yaml` mis a jour
2. Git commit + push (meme commit `71cf871`)
3. **ArgoCD PROD bloque** (erreur pre-existante : `ExternalSecret v1beta1` vs `v1` installe)
4. `kubectl set image` utilise pour restaurer immediatement le service
5. Le manifest Git est a jour — coherence garantie une fois ExternalSecret corrige

**Commit Git** : `71cf871` — `EMERGENCY RESTORE DEV+PROD client to last known good images`

## 4. Resultats de validation

### DEV (client-dev.keybuzz.io) — 5/5 PASS

| Page | Resultat | Detail |
|------|----------|--------|
| `/login` | PASS | Formulaire de connexion complet (email, OTP, OAuth) |
| `/signup` | PASS | Formulaire d'inscription affiche correctement |
| `/pricing` | PASS | 4 plans tarifaires affiches (Starter, Pro, Autopilot, Entreprise) |
| `/dashboard` | PASS | Redirect vers /login (authentification requise — attendu) |
| `/inbox` | PASS | Redirect vers /login (authentification requise — attendu) |

### PROD (client.keybuzz.io) — 6/6 PASS

| Page | Resultat | Detail |
|------|----------|--------|
| `/login` | PASS | Formulaire de connexion complet |
| `/signup` | PASS | Formulaire d'inscription affiche correctement |
| `/pricing` | PASS | 4 plans tarifaires, toggle mensuel/annuel, FAQ, comparatif |
| `/locked` | PASS | Redirect vers /login (protection correcte) |
| `/dashboard` | PASS | Redirect vers /login (attendu) |
| `/inbox` | PASS | Redirect vers /login (attendu) |

## 5. Etat apres restore

| Env | Image | Pod | Status |
|-----|-------|-----|--------|
| DEV | `v3.5.59-channels-stripe-sync-dev` | keybuzz-client-697486b9c9-* | 1/1 Running |
| PROD | `v3.5.58-channels-billing-prod` | keybuzz-client-7dcf98d9b-* | 1/1 Running |

## 6. Note ArgoCD PROD

ArgoCD PROD ne peut pas sync automatiquement a cause d'une erreur pre-existante non liee a ce restore :

```
ExternalSecret v1beta1 vs v1: The Kubernetes API could not find version "v1beta1"
of external-secrets.io/ExternalSecret for requested resource
keybuzz-client-prod/keybuzz-auth-secrets
```

Le manifest Git est a jour (`v3.5.58-channels-billing-prod`). Le deploiement a ete effectue via `kubectl set image` en complement. La coherence sera complete une fois l'ExternalSecret corrige (hors scope de ce restore).

## 7. Perimetre — ce qui n'a PAS ete touche

- API (keybuzz-api) : aucune modification
- Backend (keybuzz-backend) : aucune modification
- Stripe : aucune modification
- Base de donnees : aucune modification
- Aucun rebuild : utilisation exclusive d'images existantes dans GHCR

## 8. Gel post-restore

Apres ce restore :
- Aucun nouveau build client
- Aucun nouveau push PROD
- Aucun re-essai du fix signup
- Attente de la prochaine phase dediee d'audit process

---

## Verdict : **SERVICE RESTORED**
