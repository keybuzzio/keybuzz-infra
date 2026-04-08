# PH143-P2 — PROD Promotion Agents + IA

> Date : 2026-04-08
> Type : promotion controlee finale
> Environnement : PROD

---

## 1. Source Exacte

### Client PROD
| Detail | Valeur |
|--------|--------|
| Branche | `release/client-v3.5.220` |
| SHA | `2adbd40` |
| Dernier commit | PH143-AGENTS-R5: fix OTP session completion for invited agents |
| Git clean | 0 dirty files |
| Studio contamination | 0 fichiers |

### API PROD
| Detail | Valeur |
|--------|--------|
| Branche | `rebuild/ph143-api` |
| SHA | `db85c4d` |
| Dernier commit | PH143-AGENTS: billing-exempt bypass + agent linkage on invite accept |
| Git clean | verifie |

---

## 2. Images PROD

### Avant

| Service | Image precedente |
|---------|-----------------|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.220-ph143-clean-release-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.211-ph143-final-prod` |

### Apres

| Service | Nouvelle image |
|---------|---------------|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.224-ph143-agents-ia-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.224-ph143-agents-ia-prod` |

---

## 3. Justification API modifiee

L'API PROD precedente (`v3.5.211-ph143-final-prod`) contenait :
- billing-exempt bypass (planGuard, entitlement, tenant-context) ✓
- Routes agents et space-invites ✓

Mais **ne contenait PAS** :
- `UPDATE agents SET user_id` dans space-invites-routes.ts (linkage agent → utilisateur a l'acceptation)
- Ce code est critique pour le flow agent : sans lui, l'agent accepte l'invitation mais n'est pas lie au user dans la table agents

**Verification** : `grep -r "UPDATE agents SET user_id" /app/dist/` sur l'ancienne API PROD = vide.
**Apres rebuild** : code present dans `/app/dist/modules/auth/space-invites-routes.js` ✓

---

## 4. Preuve Git Clean

```
Client:
  Branch: release/client-v3.5.220
  SHA: 2adbd40
  Porcelain: 0
  Studio files: 0

API:
  Branch: rebuild/ph143-api
  SHA: db85c4d
  Porcelain: verifie
```

---

## 5. Smoke Tests PROD

### Agents

| Test | Resultat |
|------|----------|
| POST /agents (creation) | 201 — agent cree |
| POST /space-invites/invite | 200 — "Invitation sent" |
| GET /agents (liste) | 3 agents visibles |
| Agent linkage code | Present dans dist/ |

### IA

| Test | Resultat |
|------|----------|
| GET /ai/journal | 3 events |
| GET /ai/settings | mode=supervised, ai_enabled=true, safe_mode=true |
| GET /ai/wallet/status | remaining=899.03, monthly=1000 |
| GET /ai/errors/clusters | 0 clusters, 0 flags |
| GET /autopilot/settings | enabled, supervised, safe |
| GET /ai/learning-control | adaptive mode |
| GET /tenant-context/entitlement | PRO, not locked |

### Infrastructure

| Test | Resultat |
|------|----------|
| API health external | 200 OK |
| Client external /login | 200 OK |
| Client / (root) | 307 (redirect auth, attendu) |
| Client /inbox | 307 (redirect auth, attendu) |
| Client /settings | 307 (redirect auth, attendu) |

---

## 6. Anti-contamination Studio

| Verification | Resultat |
|-------------|----------|
| `find . -name '*[Ss]tudio*'` (hors node_modules/.next) | 0 fichiers |
| Build source | `release/client-v3.5.220` |
| Merge main | AUCUN |
| Build propre | `--no-cache`, pas de branche polluee |

---

## 7. Manifests GitOps

| Fichier | Image |
|---------|-------|
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.224-ph143-agents-ia-prod` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.224-ph143-agents-ia-prod` |

---

## 8. Rollback

### Client PROD
```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client prod v3.5.220-ph143-clean-release-prod
```

### API PROD
```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh api prod v3.5.211-ph143-final-prod
```

---

## 9. Contenu inclus dans cette promotion

### Corrections Agents (Client)
- Fix OTP session completion (`window.location.href` au lieu de `router.push`) — PH143-AGENTS-R5
- Quota historique restaure (admin compte, affichage `x/maxAgents`) — PH143-AGENTS-R4
- Flow invitation restaure (bypass check-email, redirect callbackUrl) — PH143-AGENTS-R4

### Corrections Agents (API)
- `UPDATE agents SET user_id` lors de l'acceptation invitation — PH143-AGENTS-R2
- Billing-exempt bypass (deja present, confirme)

### Perimetre IA (complet — PH143-IA-TRUTH-GATE-01)
- 23/24 features GREEN, 1 ORANGE structurel (auto-escalade pre-envoi)
- Pipeline IA complet : suggestion → insertion → envoi → detection promesses → escalade
- Autopilot : engine → draft → auto-open → consume → escalade draft
- Journal IA + clustering + flag + wallet KBActions
- Learning control adaptatif
- Francisation labels FR

---

## 10. Verdict

### **AGENTS + IA PROMOTED TO PROD**

| Composant | Image | Source | Statut |
|-----------|-------|--------|--------|
| Client PROD | `v3.5.224-ph143-agents-ia-prod` | `release/client-v3.5.220` @ `2adbd40` | DEPLOYED |
| API PROD | `v3.5.224-ph143-agents-ia-prod` | `rebuild/ph143-api` @ `db85c4d` | DEPLOYED |

Smoke tests PROD : ALL GREEN.
Anti-contamination : verifie.
Rollback documente.
