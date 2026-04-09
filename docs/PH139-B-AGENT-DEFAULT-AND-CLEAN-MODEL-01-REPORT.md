# PH139-B-AGENT-DEFAULT-AND-CLEAN-MODEL-01 -- Rapport

**Date** : 2026-04-01
**Statut** : **DEV VALIDE**
**Images** : API `v3.5.163-agent-default-dev` | Client `v3.5.163-agent-default-dev`

---

## Objectif

Ameliorer la gestion des agents :
- Agent par defaut a l'onboarding
- Supprimer le type KeyBuzz cote client
- Signature coherente avec nom agent

## Implementation

### 1. Agent par defaut a la creation tenant

**Fichier** : `tenant-context-routes.ts` (endpoint `POST /tenant-context/create-signup`)

Apres le `COMMIT` de creation du tenant, un agent est automatiquement cree :
- `first_name` = prenom du user (ou "Admin")
- `last_name` = nom du user
- `email` = email du user
- `type` = `client`
- `role` = `admin`
- `is_active` = true
- `user_id` = id du user cree

Utilise `ON CONFLICT DO NOTHING` pour eviter les erreurs si l'agent existe deja.

### 2. Suppression type KeyBuzz (API)

**Fichier** : `agents/routes.ts` (endpoint `POST /agents`)

La validation du type est modifiee :
- **Avant** : `['client', 'keybuzz'].includes(type)` (les deux acceptes)
- **Apres** : `type !== 'client'` (seul `client` accepte)

Tentative de creation avec `type: 'keybuzz'` retourne `400 : "type must be client"`.

### 3. Suppression type KeyBuzz (Client)

**Fichier** : `app/settings/components/AgentsTab.tsx`

- Le `<select>` de type agent est supprime du formulaire de creation
- Le type est force a `'client'` dans le `createAgent()` call
- Les badges type `client`/`keybuzz` restent dans la liste pour la retrocompatibilite (agents keybuzz existants)

### 4. Signature avec nom agent

**Fichier** : `src/lib/signatureResolver.ts`

La resolution de la signature est enrichie :
1. **Settings avec senderName configure** : utilise tel quel
2. **Settings avec companyName mais sans senderName** : fallback vers le nom du premier agent admin actif
3. **Pas de settings** : fallback tenant name + nom agent admin actif
4. **Aucun agent** : company name seul

Requete agent fallback :
```sql
SELECT first_name, last_name FROM agents
WHERE tenant_id = $1 AND is_active = true AND type = 'client'
ORDER BY role = 'admin' DESC, created_at ASC LIMIT 1
```

## Tests DEV

| Test | Resultat |
|---|---|
| `GET /health` | `{"status":"ok"}` |
| `getSignatureConfig('ecomlg-001')` | `{"companyName":"eComLG","senderName":"Ludovic Gonthier"}` |
| `formatSignature(config)` | `Cordialement,\nLudovic Gonthier\neComLG` |
| POST agent type `keybuzz` | `400 : "type must be client"` |
| Client `https://client-dev.keybuzz.io/login` | HTTP 200 |
| Agents existants ecomlg-001 | 3 agents (Ludovic admin, Test agent, KeyBuzz support) |
| Worker outbound | SMTP OK, SES OK |

## Fichiers modifies

### API (`keybuzz-api`)
- `src/modules/auth/tenant-context-routes.ts` (auto-creation agent)
- `src/modules/agents/routes.ts` (blocage type keybuzz)
- `src/lib/signatureResolver.ts` (fallback agent name)

### Client (`keybuzz-client`)
- `app/settings/components/AgentsTab.tsx` (suppression select type)

## Rollback

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.162-signature-identity-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.162-signature-identity-dev -n keybuzz-api-dev

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.162-signature-identity-dev -n keybuzz-client-dev
```

## Verdict

**AGENT DEFAULT CREATED -- KEYBUZZ TYPE BLOCKED -- SIGNATURE WITH AGENT NAME -- PROFESSIONAL OUTPUT**

---

## Deploiement PROD

**Date** : 2026-04-01
**Images PROD** : API `v3.5.163-agent-default-prod` | Client `v3.5.163-agent-default-prod`

### Verification PROD

| Check | Resultat |
|---|---|
| API image | `v3.5.163-agent-default-prod` |
| Worker image | `v3.5.163-agent-default-prod` |
| Client image | `v3.5.163-agent-default-prod` |
| Health API | `{"status":"ok"}` |
| `getSignatureConfig('ecomlg-001')` | `{"companyName":"eComLG","senderName":"Ludovic Gonthier"}` |
| Signature formatee | `Cordialement,\nLudovic Gonthier\neComLG` |
| Worker outbound | SMTP OK, SES OK |
| Client PROD | HTTP 200 |

### Rollback PROD

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.162-signature-identity-prod -n keybuzz-api-prod

# Worker
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.162-signature-identity-prod -n keybuzz-api-prod

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.162-signature-identity-prod -n keybuzz-client-prod
```

## Verdict Final

**PH139-B DEPLOYE DEV + PROD** -- AGENT DEFAULT CREATED -- KEYBUZZ TYPE BLOCKED -- SIGNATURE WITH AGENT NAME -- PROFESSIONAL OUTPUT
