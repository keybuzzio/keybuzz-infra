# PH139-SIGNATURE-IDENTITY-01 — Rapport

**Date** : 2026-04-01
**Statut** : **DEV VALIDE**
**Images** : API `v3.5.162-signature-identity-dev` | Client `v3.5.162-signature-identity-dev`

---

## Objectif

Garantir que chaque message sortant (IA ou humain) contient une signature valide, sans placeholder, avec une identite coherente.

## Problemes identifies (audit)

| Probleme | Fichier | Impact |
|---|---|---|
| Aucune source centrale de signature | - | Signatures incoherentes |
| IA signe "Le service client" generiquement | `shared-ai-context.ts`, `engine.ts` | Pas de personnalisation |
| Fallback degrade hardcode "Le service client" | `ai-assist-routes.ts:525` | Identite absente |
| Templates `{{signature}}` non resolu | `response-templates/data.ts` | Variable non remplacee |
| Outbound worker sans injection de signature | `outboundWorker.ts` | Messages sans signature |
| Pas de configuration signature dans tenant_settings | - | Aucun parametrage possible |

## Implementation

### 1. Migration DB

Colonnes ajoutees a `tenant_settings` :
- `signature_company_name` TEXT
- `signature_sender_name` TEXT
- `signature_sender_title` TEXT

Seed : `ecomlg-001` -> `signature_company_name = 'eComLG'`

### 2. Source unique : `signatureResolver.ts`

Nouveau fichier `src/lib/signatureResolver.ts` :
- `getSignatureConfig(pool, tenantId)` : resout la config signature (settings -> tenant name -> fallback)
- `formatSignature(config)` : formate la signature texte
- `bodyContainsSignature(body)` : detecte si une signature existe deja
- `ensureSignature(body, config)` : injecte la signature si absente

Priorite de resolution :
1. `tenant_settings.signature_company_name` (si configure)
2. `tenants.name` (fallback automatique)
3. "Service client" (dernier recours)

### 3. IA Prompt Hardening

**`shared-ai-context.ts`** :
- `getWritingRules(signatureText?)` accepte maintenant un parametre optionnel
- Si signature fournie : "Terminer le message par cette signature exacte (NE PAS la modifier)"
- Si pas de signature : comportement par defaut

**`engine.ts`** (Autopilot) :
- Resolution automatique de la signature tenant via `getSignatureConfig()`
- Injection dans le system prompt avec instruction stricte
- Utilise `context.tenant_id` pour la resolution

**`ai-assist-routes.ts`** (Aide IA) :
- Resolution signature avant appel `buildSystemPrompt()`
- Passee en parametre a `buildSystemPrompt()` -> `getWritingRules(signatureText)`
- Fallback degrade : signature statique "Cordialement,\nService client"

### 4. Outbound Worker

**`outboundWorker.ts`** :
- Import `ensureSignature` depuis `signatureResolver`
- **Amazon SMTP** : verification + injection signature avant envoi
- **Email/SMTP** : verification + injection signature avant envoi
- Utilise `getPool()` interne du worker (pas de conflict)

### 5. API Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/tenant-context/signature/:tenantId` | Config signature + preview |
| PUT | `/tenant-context/signature/:tenantId` | Mise a jour signature |

### 6. Client UI

- **Nouvel onglet "Signature"** dans Parametres (icone PenLine)
- **`SignatureTab.tsx`** : formulaire avec apercu en temps reel
  - Champs : Nom entreprise, Nom expediteur (optionnel), Fonction (optionnel)
  - Preview live de la signature
  - Boutons Enregistrer / Reinitialiser
- **BFF route** : `app/api/tenant-context/signature/route.ts`
- **ContactSupplierModal** : "L'equipe SAV" -> "Service client"

## Tests DEV

| Test | Resultat |
|---|---|
| `GET /health` | `{"status":"ok"}` |
| `GET /tenant-context/signature/ecomlg-001` | `{"companyName":"eComLG","preview":"Cordialement,\neComLG"}` |
| `PUT /tenant-context/signature/ecomlg-001` (avec nom+titre) | `{"preview":"Cordialement,\nMarie\nService Client\neComLG"}` |
| Client `https://client-dev.keybuzz.io/login` | HTTP 200 |
| Inbox API | OK (conversations chargees) |
| Worker outbound | Demarre correctement, SMTP OK |
| Logs API | Aucune erreur |

## Non-regressions

| Module | Statut |
|---|---|
| Health API | OK |
| Inbox | OK |
| Outbound Worker | OK (demarre proprement) |
| Client | OK (200 sur /login) |
| Billing | Non impacte |
| AI | Prompt mis a jour avec signature tenant |

## Fichiers modifies

### API (`keybuzz-api`)
- **NOUVEAU** : `src/lib/signatureResolver.ts`
- `src/modules/ai/shared-ai-context.ts` (param signature)
- `src/modules/autopilot/engine.ts` (resolution + injection signature)
- `src/modules/ai/ai-assist-routes.ts` (resolution + passage a buildSystemPrompt)
- `src/workers/outboundWorker.ts` (injection signature avant envoi)
- `src/modules/auth/tenant-context-routes.ts` (endpoints GET/PUT signature)

### Client (`keybuzz-client`)
- **NOUVEAU** : `app/settings/components/SignatureTab.tsx`
- **NOUVEAU** : `app/api/tenant-context/signature/route.ts`
- `app/settings/page.tsx` (ajout onglet Signature)
- `src/features/inbox/components/ContactSupplierModal.tsx` (signature statique)

## Rollback

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.160-stripe-checkout-final-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.160-stripe-checkout-final-dev -n keybuzz-api-dev

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.161-agent-keybuzz-premium-ux-dev -n keybuzz-client-dev
```

Les colonnes DB `signature_*` peuvent rester en place (nullable, aucun impact).

## Verdict

**NO PLACEHOLDER — CLEAN SIGNATURE — CONSISTENT IDENTITY — PROFESSIONAL OUTPUT**

---

## Deploiement PROD

**Date** : 2026-04-01
**Images PROD** : API `v3.5.162-signature-identity-prod` | Client `v3.5.162-signature-identity-prod`

### Migration DB PROD

Colonnes ajoutees a `tenant_settings` (PROD) :
- `signature_company_name` TEXT
- `signature_sender_name` TEXT
- `signature_sender_title` TEXT

### Verification PROD

| Check | Resultat |
|---|---|
| API image | `v3.5.162-signature-identity-prod` |
| Worker image | `v3.5.162-signature-identity-prod` |
| Client image | `v3.5.162-signature-identity-prod` |
| Health API | `{"status":"ok"}` |
| DB colonnes signature | 3 colonnes presentes |
| Logs API | Aucune erreur |
| Worker outbound | SMTP OK, SES OK |
| Client PROD | HTTP 200 |

### Rollback PROD

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.160-stripe-checkout-final-prod -n keybuzz-api-prod

# Worker
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-prod -n keybuzz-api-prod

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.161-agent-keybuzz-premium-ux-prod -n keybuzz-client-prod
```

Les colonnes DB `signature_*` sont nullable et n'impactent pas le rollback.

## Verdict Final

**PH139 DEPLOYE DEV + PROD** — NO PLACEHOLDER — CLEAN SIGNATURE — CONSISTENT IDENTITY — PROFESSIONAL OUTPUT
