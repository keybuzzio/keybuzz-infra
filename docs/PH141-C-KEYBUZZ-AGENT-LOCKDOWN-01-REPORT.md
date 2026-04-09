# PH141-C — KeyBuzz Agent Lockdown

**Date** : 3 avril 2026
**Status** : DEV + PROD OK
**Image DEV** : `ghcr.io/keybuzzio/keybuzz-api:v3.5.180-keybuzz-agent-lockdown-dev`

---

## Objectif

Empecher les clients de creer des agents de type `keybuzz` via l'API publique, tout en conservant la possibilite de creation via un endpoint interne protege.

---

## Cause

PH141-B avait ouvert le type `keybuzz` dans la validation du POST /agents public pour preparer le gating. Cela creait une faille : un client pouvait appeler l'API directement avec `type: 'keybuzz'`.

---

## Avant / Apres

| Point | PH141-B (avant) | PH141-C (apres) |
|---|---|---|
| POST /agents `type=keybuzz` | **Accepte** (avec limit check) | **400 Rejete** |
| POST /agents `type=client` | OK | OK (inchange) |
| Endpoint interne KeyBuzz | Inexistant | **POST /agents/internal-keybuzz** (X-Internal-Token) |
| Agent KeyBuzz existant | Intact | Intact |
| Limites PH141-B | OK | OK (inchange) |

---

## Modifications

### Backend uniquement (keybuzz-api)

| Fichier | Changement |
|---|---|
| `src/modules/agents/routes.ts` | Type validation : `['client', 'keybuzz']` → `'client'` uniquement |
| `src/modules/agents/routes.ts` | Suppression du bloc KeyBuzz limit check du POST public (code mort) |
| `src/modules/agents/routes.ts` | Ajout `POST /agents/internal-keybuzz` protege par `X-Internal-Token` |

### Frontend : aucune modification

Le frontend envoyait deja `type: 'client'` hardcode (ligne 252 de AgentsTab.tsx).

---

## Endpoint interne

```
POST /agents/internal-keybuzz?tenant_id=xxx
Headers: X-Internal-Token: <KEYBUZZ_INTERNAL_PROXY_TOKEN>
Body: { email?, first_name?, last_name? }

Protections:
- Verifie X-Internal-Token vs env KEYBUZZ_INTERNAL_PROXY_TOKEN
- Verifie KEYBUZZ_AGENT_LIMITS pour le plan du tenant
- Verifie unicite (pas de doublon type=keybuzz par tenant)
- Retourne 403 sans token, 403 si limite, 409 si deja existant
```

---

## Tests DEV (curl API directe)

| Test | Attendu | Resultat |
|---|---|---|
| POST `type=keybuzz` via API publique | 400 | `"type must be client"` |
| POST `type=client` (limite PRO atteinte) | 403 | `AGENT_LIMIT_REACHED (5/2)` |
| POST `/internal-keybuzz` sans token | 403 | `"Forbidden — internal only"` |
| Agent KeyBuzz existant (id=35) | Intact | `support@keybuzz.io, active` |

### Non-regression

| Test | Resultat |
|---|---|
| Limites agents PH141-B | OK (PRO=2, comptage client-only) |
| Agent KeyBuzz dans AgentsTab | OK (badge bleu, non compte) |
| Inbox / supervision | Non touche (API-only change) |

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.179-agent-limits-alignment-dev -n keybuzz-api-dev
```

---

## PROD

**Deploye le 3 avril 2026.**

### Image PROD

- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.180-keybuzz-agent-lockdown-prod`
  - sha256: `bf59b90355aee74daa827517e6b8f4c938800e9dd858b1a3367655857bfa1f05`
- Client : inchange (`v3.5.179-agent-limits-alignment-prod`)

### Verification post-deploiement

| Verification | Resultat |
|---|---|
| API pod | `1/1 Running`, 0 restarts |
| Health `api.keybuzz.io/health` | HTTP 200, 0.21s |
| Image API deployee | `v3.5.180-keybuzz-agent-lockdown-prod` |
| GitOps YAML api-prod | Mis a jour |

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.179-agent-limits-alignment-prod -n keybuzz-api-prod
```
