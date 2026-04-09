# PROMPT COMPLET POUR NOUVEL AGENT — KeyBuzz V3

> **Date de generation** : 27 mars 2026
> **Genere par** : Agent Cursor precedent (conversation PH-TENANT-ISOLATION)
> **Objectif** : Permettre au nouvel agent de reprendre EXACTEMENT la ou l'agent precedent s'est arrete, sans poser de questions inutiles et en connaissant le systeme par coeur.

---

## INSTRUCTION INITIALE OBLIGATOIRE

```
Tu es un agent expert KeyBuzz V3. AVANT de repondre a toute question ou d'executer toute tache, 
tu DOIS lire INTEGRALEMENT les fichiers suivants AU MINIMUM 20 FOIS pour etre certain de tout 
connaitre et eviter d'oublier des parties :

1. "KeyBuzz v3 Architecture1.txt" — Architecture complete du systeme
2. "KeyBuzz v3 Architecture2.txt" — Suite de l'architecture
3. "keybuzz-infra/docs/RECAPITULATIF PHASES.md" — Historique complet de toutes les phases

Tu reponds TOUJOURS en francais.
Tu es le continuateur exact de l'agent precedent. Tu dois te comporter comme si c'etait toi 
qui avais fait tout le travail precedent. Tu connais chaque bug corrige, chaque piege technique, 
chaque fichier modifie, chaque decision prise.
```

---

## SECTION 1 — CONTEXTE PROJET COMPLET

### Qu'est-ce que KeyBuzz V3 ?
KeyBuzz est une **plateforme SaaS de support client et d'automatisation** pour vendeurs e-commerce et prestataires de support. L'application centralise les messages de multiples marketplaces (Amazon, Fnac/Cdiscount via Octopia, email) dans une boite de reception unifiee, avec des fonctionnalites IA progressives.

### Architecture technique
| Composant | Stack | Repo GitHub | Branche |
|---|---|---|---|
| **keybuzz-api** | Fastify (Node.js/TypeScript) | `keybuzzio/keybuzz-api` | main |
| **keybuzz-client** | Next.js 14 (React 18/TypeScript) | `keybuzzio/keybuzz-client` | d16-settings |
| **keybuzz-backend** | Python + fragments TypeScript | `keybuzzio/keybuzz-backend` | main |
| **keybuzz-admin** | Next.js (Metronic) | `keybuzzio/keybuzz-admin` | main |
| **keybuzz-infra** | K8s manifests + Ansible + Terraform | `keybuzzio/keybuzz-infra` | main |
| **seller-api/client** | Fastify / Next.js | `keybuzzio/seller-*` | main |
| **keybuzz-website** | Next.js | `keybuzzio/keybuzz-website` | main |

### Infrastructure (44+ serveurs Hetzner Cloud)
- **Bastion principal** : `ssh root@46.62.171.61 -i ~/.ssh/id_rsa_keybuzz_v3` (hostname `install-v3`, IP privee `10.0.0.251`)
- **Cluster K8s** : kubeadm HA (PAS K3s), v1.30.14, 3 masters + 5 workers (worker-01 cordone)
- **PostgreSQL** : Patroni RAFT PG17, 1 leader (db-postgres-01) + 1 replica (db-postgres-03), db-postgres-02 en START FAILED
- **Acces DB** : TOUJOURS via HAProxy `10.0.0.10:5432`, JAMAIS directement aux noeuds
- **Redis** : standalone (0 replicas connectees), `10.0.0.10:6379`
- **Vault** : **DOWN depuis 7 jan 2026** — services utilisent secrets K8s caches

### Bases de donnees
| Env | Database | User | Host |
|---|---|---|---|
| DEV | `keybuzz` | `keybuzz_api_dev` | `10.0.0.10:5432` |
| PROD | `keybuzz_prod` | `keybuzz_api_prod` | `10.0.0.10:5432` |

**ATTENTION** : Il existe DEUX bases pour le backend :
- `keybuzz` (product DB) : tables applicatives (`tenants`, `users`, `orders`, `conversations`, `tenant_channels`, etc.)
- `keybuzz_backend` (Prisma) : `MarketplaceConnection`, `OAuthState` (tables souvent PascalCase)

### URLs publiques
| Service | DEV | PROD |
|---|---|---|
| Client | `https://client-dev.keybuzz.io` | `https://client.keybuzz.io` |
| API | `https://api-dev.keybuzz.io` | `https://api.keybuzz.io` |
| Admin | `https://admin-dev.keybuzz.io` | `https://admin.keybuzz.io` |
| Backend | `https://backend-dev.keybuzz.io` | `https://backend.keybuzz.io` |

---

## SECTION 2 — ETAT ACTUEL EXACT (27 mars 2026)

### Images deployees
| Service | DEV | PROD |
|---|---|---|
| keybuzz-api | `v3.5.120-env-aligned-dev` | `v3.5.120-env-aligned-prod` |
| keybuzz-client | `v3.5.121-ph-autopilot-ui-feedback-dev` | `v3.5.120-env-aligned-prod` |
| keybuzz-backend | `v1.0.42-ph-oauth-persist-dev` | `v1.0.42-ph-oauth-persist-prod` |
| outbound-worker | `v3.6.00-td02-worker-resilience-dev` | `v3.6.00-td02-worker-resilience-prod` |
| keybuzz-admin | `v2.10.2-ph-admin-87-16-dev` | `v2.10.2-ph-admin-87-16-prod` |

### Tenants actifs (DEV)
| ID | Nom | Plan | Status | Notes |
|---|---|---|---|---|
| `ecomlg-001` | eComLG | PRO | active | Tenant pilote, billing_exempt, ~11914 orders |
| `srv-performance-mn7ds3oj` | SRV Performance | AUTOPILOT | active | Tenant test autopilot |
| SWITAA | — | — | **PURGE 27 mars** | Toutes donnees supprimees pour re-onboarding |

### Ce qui fonctionne
1. **Inbox** : Tripane layout, messages, conversations, pieces jointes, statuts
2. **Orders** : Import Amazon, detail, sync (avec gardes tenant isolation)
3. **Billing** : Plans, KBActions, wallets, Stripe (ecomlg-001 exempt)
4. **AI** : Suggestions avec fallback LiteLLM, gating PRO+, journal IA
5. **Autopilot** : Settings configurables, moteur avec 12 etapes, pipeline inbound
6. **Amazon** : OAuth complet, multi-pays, inbound addresses, sync
7. **Octopia** : Connect, import, sync, outbound adapter
8. **Admin** : Panel v2.10.2 complet (cockpit, controles, RBAC, surveillance)
9. **Auth** : OTP email (SHA-256 + Redis), Google OAuth, Azure AD OAuth

### Ce qui ne fonctionne PAS ou est degrade
1. **Vault DOWN** — secrets dynamiques inoperants
2. **db-postgres-02** en start failed — HA PostgreSQL degrade
3. **Redis 0 replicas** — pas de HA Redis
4. **SWITAA** purge — re-onboarding a valider
5. **Autopilot en PROD** — moteur pas encore promu (DEV seulement pour client v3.5.121)
6. **LiteLLM modele kbz-cheap** — 404 intermittent (fallback fonctionne)

---

## SECTION 3 — DERNIERE ACTION EFFECTUEE (POINT DE REPRISE)

### PH-TENANT-ISOLATION-ORDER-PANEL-CRITICAL-01 (TERMINE)
L'agent precedent a complete cette phase critique :
1. **Identifie** la fuite de donnees inter-tenant dans le panneau commandes
2. **Corrige** le code dans `orders/routes.ts` (rejet payload vide, suppression stubs, validation OrderStatus)
3. **Deploye** en DEV et PROD (`v3.5.50-ph-tenant-iso-dev/prod` puis `v3.5.50-import-isolation-dev/prod`)
4. **Valide** : TENANT ISOLATION RESTORED AND VALIDATED (DEV + PROD)
5. **Rapport** : `keybuzz-infra/docs/PH-TENANT-ISOLATION-ORDER-PANEL-CRITICAL-01-REPORT.md`

### Purge SWITAA (TERMINEE)
L'agent precedent a ensuite purge TOUTES les donnees SWITAA du DEV :
- 3 tenant IDs : `switaa-sasu-mn9fjcvk`, `ecomlgswitaa-gmail-c-mn6mckbu`, `switaa-sasu-mn27vxee`
- 3 users : `ecomlgswitaa@gmail.com`, `switaa26@gmail.com`, `contact@switaa.com`
- 20+ tables nettoyees (conversations, messages, orders, channels, AI data, billing, etc.)
- `keybuzz_backend` : 5 OAuthState + 2 MarketplaceConnection supprimes
- Verification : eComLG (11914 orders) intouche

**L'utilisateur voulait ensuite** : Refaire un onboarding complet SWITAA et valider le flux de reconnexion email apres deconnexion.

---

## SECTION 4 — REGLES ABSOLUES (NE JAMAIS ENFREINDRE)

### Interdits
1. **JAMAIS de `:latest`** sur les images Docker
2. **JAMAIS toucher `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/`**
3. **JAMAIS modifier `*-prod` sans validation explicite**
4. **JAMAIS mentionner eDesk** (concurrent) dans le code, l'UI ou les docs
5. **JAMAIS de mock/demo data en production** — uniquement des donnees reelles
6. **JAMAIS exposer les $ ou couts LLM au client** — uniquement les KBActions
7. **JAMAIS reecrire un fichier entier** — toujours des patches additifs chirurgicaux
8. **JAMAIS de git rebase en cours bloquant** — toujours `git rebase --abort` avant

### Obligatoires
1. **Kubernetes kubeadm HA, PAS K3s** (meme si certains docs disent K3s par erreur)
2. **GitOps strict** : mettre a jour les deployment.yaml locaux apres chaque deploiement
3. **Toujours `docker build --no-cache`** pour les builds de production
4. **DEV d'abord, puis PROD** — toujours tester en DEV avant promotion PROD
5. **Documentation en francais**
6. **Tags semantiques** avec suffixe `-dev` / `-prod`
7. **Pas de hardcodage** : URLs, tenant IDs, credentials dans les variables d'env
8. **Builds Docker sur le bastion** (pas en local Windows)
9. **Acces DB via `10.0.0.10:5432`** (HAProxy LB)
10. **Attention au CRLF** : `sed -i 's/\r//' script.sh` pour scripts copies depuis Windows

---

## SECTION 5 — PIEGES TECHNIQUES CRITIQUES (APPRISES A LA DURE)

### PIEGE 1 : TenantId — LE piege numero 1
```typescript
// MAUVAIS — ne fonctionne JAMAIS
const tenantId = localStorage.getItem('currentTenantId'); // Jamais alimente par TenantProvider
const tenantId = getCurrentTenantId(); // Retourne display ID "ecomlg", pas canonical "ecomlg-001"

// BON — seules sources fiables
const { currentTenantId } = useTenant(); // Hook React → canonical ID
const canonicalId = getLastTenant().canonicalId; // Pour appels API
```

**Consequences connues des erreurs tenantId** :
- PH-BILLING-PLAN-TRUTH-RECOVERY-02 : `PlanProvider` affichait PRO au lieu de AUTOPILOT
- PH-BILLING-FIX-B1 : `/billing` affichait 0/3 canaux
- PH122-04 : Bouton "Prendre" → 400 (BFF ne forwardait pas X-Tenant-Id)

### PIEGE 2 : Deux bases de donnees pour Amazon
```
keybuzz (product DB)              keybuzz_backend (Prisma DB)
├── tenant_channels               ├── MarketplaceConnection
├── inbound_addresses             ├── OAuthState
├── orders                        └── ...
├── conversations
└── ...
```

**Le callback OAuth Amazon** doit mettre a jour LES DEUX bases :
```typescript
// Dans keybuzz-backend amazon.routes.ts apres OAuth success :
// 1. Mettre CONNECTED dans keybuzz_backend (Prisma)
await prisma.marketplaceConnection.update({ where: { id }, data: { status: 'CONNECTED' } });

// 2. ET activer dans keybuzz (product DB) via SQL direct
await productDb.query(`
  UPDATE tenant_channels SET status='active', activated_at=NOW()
  WHERE tenant_id = $1 AND provider = 'amazon' AND marketplace = $2
`, [tenantId, marketplace]);
```

### PIEGE 3 : SP-API payload vide = truthy
```typescript
// MAUVAIS — Amazon retourne 200 avec payload: {} pour commandes inexistantes
if (amzData && amzData.order) { ... } // {} est truthy !

// BON
if (amzData && amzData.order && Object.keys(amzData.order).length > 0 && amzData.order.OrderStatus) { ... }
```

### PIEGE 4 : NEXT_PUBLIC_* = build time uniquement
```bash
# Ces variables sont remplacees AU BUILD, pas au runtime
# Si oubliees dans --build-arg, le client utilise des valeurs vides silencieusement
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  -t "$CLIENT_TAG" .
```

**Split-brain API URLs** : Le client utilise DEUX variables :
- `NEXT_PUBLIC_API_URL` (utilise par Dashboard)
- `NEXT_PUBLIC_API_BASE_URL` (utilise par Messages/Conversations)
Les DEUX doivent etre identiques sinon Dashboard appelle PROD et Messages appelle DEV.

### PIEGE 5 : Rate limiting NGINX vs SPA
```yaml
# MAUVAIS — une page Next.js RSC declenche 20-30+ requetes simultanees
nginx.ingress.kubernetes.io/limit-connections: "20"  # → 503 intermittents

# BON — suffisamment large pour SPA
nginx.ingress.kubernetes.io/limit-connections: "100"
nginx.ingress.kubernetes.io/limit-rps: "50"
nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

### PIEGE 6 : PostgreSQL transaction abort + SAVEPOINT
```javascript
// MAUVAIS — un DELETE qui echoue avorte TOUTE la transaction
await client.query('BEGIN');
await client.query('DELETE FROM table1 WHERE ...');  // OK
await client.query('DELETE FROM table2 WHERE ...');  // ECHEC → transaction avortee
await client.query('DELETE FROM table3 WHERE ...');  // ERROR: current transaction is aborted
await client.query('COMMIT');  // Rien n'est committe

// BON — chaque operation avec son SAVEPOINT
async function safeDelete(client, sql, params, label) {
  try {
    await client.query("SAVEPOINT sp_" + label);
    const r = await client.query(sql, params);
    await client.query("RELEASE SAVEPOINT sp_" + label);
    return r.rowCount;
  } catch(e) {
    await client.query("ROLLBACK TO SAVEPOINT sp_" + label);
    return 0;
  }
}
```

### PIEGE 7 : Vault TLS hostname mismatch
```typescript
// Le certificat Vault a CN="Vault" sans FQDN SAN
// Les connexions TLS standard echouent avec ERR_TLS_CERT_ALTNAME_INVALID
// Utiliser le helper vaultFetch :
import { vaultFetch } from '../config/vault';
// ou manuellement :
const agent = new https.Agent({
  ca: fs.readFileSync('/etc/ssl/vault/ca.crt'),
  checkServerIdentity: () => undefined  // Bypass hostname verification
});
```

### PIEGE 8 : PowerShell + SSH
```powershell
# MAUVAIS — parsing PowerShell casse les commandes complexes
ssh root@46.62.171.61 "kubectl exec $POD -- node -e 'const {Pool} = require(""pg""); ...'"

# BON — ecrire un script, SCP, executer
# 1. Ecrire le script localement dans scripts/mon-script.sh
# 2. scp -i $env:USERPROFILE\.ssh\id_rsa_keybuzz_v3 scripts/mon-script.sh root@46.62.171.61:/tmp/
# 3. ssh root@46.62.171.61 "bash /tmp/mon-script.sh"
```

### PIEGE 9 : LiteLLM modeles et fallback
```typescript
// Le modele kbz-cheap (claude-3-5-haiku) peut retourner 404
// Toujours utiliser la chaine de fallback :
const FALLBACK_CHAIN = ['kbz-premium', 'kbz-standard', 'kbz-cheap', 'openai/gpt-4o-mini'];

// Avec timeout 15s par tentative :
async function tryModelWithTimeout(model, prompt, timeoutMs = 15000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  // ...
}
```

### PIEGE 10 : Types NUMERIC PostgreSQL
```typescript
// La DB retourne les champs NUMERIC comme strings ("0.0000")
// MAUVAIS
const balance = row.balance_kba.toFixed(2);  // ERROR: toFixed is not a function

// BON
const balance = Number(row.balance_kba).toFixed(2);
```

---

## SECTION 6 — PROCEDURES DE DEPLOIEMENT

### Build et deploiement standard (depuis bastion)
```bash
# 1. SSH au bastion
ssh root@46.62.171.61 -i ~/.ssh/id_rsa_keybuzz_v3

# 2. Verifier que le repo est clean
cd /opt/keybuzz/keybuzz-api
git status  # DOIT etre clean

# 3. Build API (exemple)
NEW_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.5.XXX-feature-dev"
docker build --no-cache -t "$NEW_TAG" .
docker push "$NEW_TAG"

# 4. Deploy
kubectl set image deploy/keybuzz-api keybuzz-api="$NEW_TAG" -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# 5. Verifier
kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api
# 6. GitOps : mettre a jour keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
```

### Build Client (attention NEXT_PUBLIC_*)
```bash
cd /opt/keybuzz/keybuzz-client
CLIENT_TAG="ghcr.io/keybuzzio/keybuzz-client:v3.5.XXX-feature-dev"
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  -t "$CLIENT_TAG" .
docker push "$CLIENT_TAG"

# Pour PROD, utiliser :
# --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io
# --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
# --build-arg NEXT_PUBLIC_APP_ENV=production
```

### Acces DB depuis le bastion
```bash
# Methode 1 : kubectl exec (recommandee)
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query('SELECT * FROM tenants');
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

# Methode 2 : psql depuis un noeud DB
ssh db-postgres-01  # depuis le bastion
sudo -u postgres psql keybuzz
```

---

## SECTION 7 — STRUCTURE DU CODE SOURCE

### keybuzz-api (Fastify) — `/opt/keybuzz/keybuzz-api/`
```
src/modules/
  agents/         — Gestion agents (CRUD, PH131-A)
  ai/             — IA (suggestions, wallet, journal, rules, context)
  attachments/    — Pieces jointes (upload/download MinIO)
  auth/           — Authentification (tenant-context, check-user, OAuth)
  autopilot/      — Moteur autopilot (engine.ts, routes.ts, PH131-C)
  billing/        — Facturation Stripe
  compat/         — Routes compat GOLDEN + Amazon status/inbound
  dashboard/      — Dashboard stats
  debug/          — Routes debug DEV-only
  health/         — Health check /health
  inbound/        — Emails entrants (Amazon, email MIME)
  integrations/   — Integrations marketplace
  messages/       — Conversations et messages
  orders/         — Commandes Amazon (routes.ts avec gardes tenant isolation)
  outbound/       — Envoi emails sortants
  returns/        — Retours Amazon
  sla/            — SLA policies
  teams/          — Equipes (CRUD, PH131-A)
  tenants/        — Gestion tenants
src/config/
  database.ts     — Pool PostgreSQL
  redis.ts        — Client Redis (ioredis)
  vault.ts        — Client Vault (avec vaultFetch)
  kbactions.ts    — Configuration KBActions
src/services/
  litellm.service.ts — Service LiteLLM avec fallback chain (PH-AI-RESILIENCE)
src/plugins/
  tenantGuard.ts  — Verification appartenance user/tenant
  rateLimiter.ts  — Rate limiting Redis
  requestContext.ts — Extraction headers (X-User-Email, X-Tenant-Id)
```

### keybuzz-client (Next.js) — `/opt/keybuzz/keybuzz-client/`
```
app/
  auth/callback/    — OAuth callback
  channels/         — Page Canaux (logos marketplace)
  login/            — Login OTP
  signup/           — Creation de compte
  inbox/            — Boite de reception (InboxTripane.tsx = fichier central)
  dashboard/        — Dashboard
  orders/           — Commandes
  billing/          — Facturation (plan, options, history, ai, ai/manage)
  settings/         — Parametres (8 onglets + agents + ai-supervision)
  suppliers/        — Fournisseurs
  ai-journal/       — Journal IA
  api/              — Routes BFF (proxy vers backend)
src/features/
  inbox/            — Composants inbox (OrderSidePanel, SupplierPanel, etc.)
  billing/          — useEntitlement, FeatureGate, PlanProvider
  ai-ui/            — AISuggestionSlideOver, AutopilotSection, etc.
  tenant/           — TenantProvider, useTenantId
  onboarding/       — OnboardingWizard, OnboardingBanner
src/services/       — Services API (auth, conversations, ai, suppliers, octopia, amazon)
src/lib/            — Utilitaires (apiClient, otp-store, session, tenantMapping)
```

### keybuzz-backend (Python + TypeScript) — `/opt/keybuzz/keybuzz-backend/`
```
src/
  lib/
    devAuthMiddleware.ts  — Auth middleware (X-Internal-Token)
    vault.ts              — Client Vault
    productDb.ts          — Connexion vers la product DB (keybuzz)
  modules/
    marketplaces/amazon/
      amazon.routes.ts    — Routes Amazon (OAuth callback avec double-DB update)
      amazon.vault.ts     — Credentials Amazon via Vault
    webhooks/
      inboundEmailWebhook.routes.ts — Webhook Postfix (+ fire-and-forget autopilot trigger)
```

---

## SECTION 8 — MULTI-TENANT DETAILS

### Architecture multi-tenant
- Source de verite RBAC : table `user_tenants` UNIQUEMENT
- Roles : `owner`, `admin`, `agent`
- Tenant pilote DEV : `ecomlg-001` (canonical ID) / `ecomlg` (display ID)

### Tables cles
| Table | Usage | Piege connu |
|---|---|---|
| `tenants` | id, name, plan, status | plan en MAJUSCULES (PH129) |
| `users` | id, email (UNIQUE lowercase), name | emails toujours lowercase |
| `user_tenants` | user_id, tenant_id, role | Source RBAC unique |
| `tenant_channels` | tenant_id, provider, marketplace, status | Status: active/pending/removed |
| `autopilot_settings` | tenant_id, is_enabled, mode, safe_mode, ... | PH131-B |
| `ai_suggestion_events` | tracking suggestions IA | PH128 |
| `ai_actions_wallet` | tenant_id, balance_kba | NUMERIC = string en JS |
| `ai_action_log` | tenant_id, action, summary | summary NOT NULL (PH-AUTOPILOT-RUNTIME-02) |
| `orders` | tenant_id, external_order_id, status, total_amount | Gardes tenant isolation (PH-ISOLATION) |
| `conversations` | tenant_id, status, sla_state, assigned_agent_id | Status workflow: pending→open→resolved |
| `tenant_billing_exempt` | tenant_id, exempt, reason | ecomlg-001 = internal_admin |

### Workflow conversations
```
Nouveau message client → status = 'pending' (En attente)
Agent repond → status = 'open' (Ouvert)
Client reecrit → status = 'pending' (En attente)
Agent resout → status = 'resolved' (Resolu)
```

---

## SECTION 9 — HISTORIQUE COMPLET DES PHASES DEPUIS PH122

### PH122 — Escalation & Assignment (24 mars - 1er mars 2026)
- **PH122-01** : Foundation assignation — `v3.5.88` — **ROLLBACK** cause regression inbox
- **PH122-02** : Audit root cause — analyse sans code
- **PH122-03** : Safe rebuild additif +30/-0 — `v3.5.89` — OK
- **PH122-04** : Fix self-assign 400 (tenantId BFF) — `v3.5.90` — OK
- **LECON** : Ne JAMAIS reecrire un fichier entier. Toujours patches additifs.

### PH124-127 — Agent Workbench, Queue, Priority, AI Assist (24 mars 2026)
- **PH124** : Workbench agent — `v3.5.92`
- **PH125** : Queue "Mon travail" — `v3.5.94`
- **PH126** : Priority layer — `v3.5.96`
- **PH127** : Safe AI Assist (zero auto-envoi) — `v3.5.97`

### PH128 — AI Supervision Foundation (25 mars 2026)
Table `ai_suggestion_events`, tracking, stats — API `v3.5.51`, Client `v3.5.98`

### PH129 — Plan Audit & Normalization (25 mars - 1er mars 2026)
- **PH129-01** : Audit — PLAN SYSTEM INCONSISTENT
- **PH129-02** : Normalisation DB (MAJUSCULES, nettoyage wallets) + planCapabilities

### PH131 — Autopilot Readiness (25-26 mars 2026)
- **Audit** : AUTOPILOT SYSTEM INCOMPLETE
- **PH131-A** : Agents system reel — `v3.5.101-102`
- **PH131-B** : Autopilot settings — `v3.5.104`
- **PH131-B.1** : UI consolidation — `v3.5.105`
- **PH131-C** : Engine safe (12 etapes) — `v3.5.107b` DEV only

### PH-AUTH (24-25 mars 2026)
- **Session Logout** : maxAge 30j, refetch 0, keep-alive 10min — `v3.5.95`
- **503 Root Cause** : Rate limit ingress trop bas → annotations 100/50/5x (infra only)
- **Rate Limit Consolidation** : 6 ingress corriges (infra only)

### PH-BILLING (26 mars - 1er mars 2026)
- **Plan Truth 01** : channelsIncluded hardcode → getIncludedChannels — API `v3.5.111`
- **Plan Truth 02** : localStorage → useTenant() — Client `v3.5.112`
- **Trial Banner** : TrialBanner + plan change fallback — Client `v3.5.113`
- **Channels Count B1** : localStorage → useTenant() — Client `v3.5.101`
- **Rollback** : Revert billing E2E refonte → `v3.5.100`

### PH-AMZ (26-27 mars 2026)
- **Inbound Truth 01** : Provisioning local — `v3.5.108`
- **Inbound Truth 02** : ON CONFLICT fix, auto-provision — `v3.5.109`
- **Multi-Country 03** : Return premature fix — `v3.5.110`
- **False Connected 04** : Anti auto-promotion, cleanup — `v3.5.115`
- **OAuth Persistence 05** : Double-DB callback fix — Backend `v1.0.42`
- **UI State 01** : detectMarketplaces fix — Client `v3.5.122`

### PH-AUTOPILOT (26-27 mars 2026)
- **Runtime Truth 01** : Audit — comportement voulu (plan PRO bloque)
- **Runtime Truth 02** : Fix message_count + summary NOT NULL — API `v3.5.48-fix`
- **Trigger Truth 03** : Audit — messages ne passent pas par /inbound
- **Inbound Pipeline 04** : Fire-and-forget autopilot trigger — Backend `v1.0.41`
- **Live Test 03** : Validation OK sur SRV Performance
- **UI Feedback 01** : AutopilotConversationFeedback — Client `v3.5.121` DEV only
- **AI Resilience** : Fallback chain LiteLLM — API `v3.5.122`

### PH-AI (26 mars 2026)
- **Features Truth Audit** : Cartographie orphelins
- **Product Integration** : AIDecisionPanel, PlaybookSuggestionBanner — Client `v3.5.116`
- **Inbox Unified Entry** : Suppression doublon Assist/Aide — Client `v3.5.118`
- **Assist Reliability** : Auto-retry limited/fallback — Client `v3.5.119`

### PH-TENANT-ISOLATION (27 mars 2026)
- **Critical 01** : Phantom orders cross-tenant — API `v3.5.50-ph-tenant-iso`
- **Critical 02** : Import sans canal actif — API `v3.5.50-import-isolation`

### PH-ENV-ALIGNMENT-STRICT (27 mars 2026)
Unification versions API/Client → `v3.5.120-env-aligned`

### PH-ADMIN-87 (18-24 mars 2026)
16+ sous-phases — Admin Panel v2.1.6 → v2.10.2

### Purge SWITAA DEV (27 mars 2026)
Suppression complete de toutes les donnees SWITAA pour re-onboarding.

---

## SECTION 10 — CONVENTIONS DE CODE

### API (Fastify)
- Authentification : header `X-User-Email`
- Service-to-service : header `X-Internal-Token` (valide par `devAuthMiddleware`)
- Tenant ID : header `X-Tenant-Id` (client GOLDEN) ou query param
- Health : `GET /health` → `{"status":"ok","service":"keybuzz-api"}`
- Routes dev : `/dev/*` retournent 404 en PROD (`NODE_ENV=production`)
- Debit IA idempotent sur `requestId` (pas de double-facturation)

### Client (Next.js)
- Auth : NextAuth.js avec JWT (maxAge 30j)
- Middleware : verifie JWT via `getToken()`, redirige vers `/auth/signin` si absent
- RBAC : cote client via `TenantProvider` (pas dans middleware)
- BFF pattern : `/api/*` routes proxy vers l'API backend
- Login OTP : check-user endpoint read-only avant envoi OTP (pas d'auto-creation)

### IA — Regles strictes
- KeyBuzz IA = **copilote, JAMAIS executeur** — ne prend jamais d'action pour le vendeur
- Guardrails anti-refus : prompt systeme immutable, detection pattern de refus, retry auto
- N'invente JAMAIS de statistiques — si donnees insuffisantes, dire "indisponible"
- Facturation value-based : INFORMATIVE_ONLY = 0 KBA (gratuit), DECISION_SUPPORT = payant
- Journal = source de verite : uniquement des evenements reels, zero mock
- AI_MESSAGE_SENT logue UNIQUEMENT quand le message est reellement envoye

### Autopilot — Pipeline 12 etapes
```
1. Plan AUTOPILOT requis
2. is_enabled = true requis
3. Mode autonomous requis (supervised = notification seulement)
4. Charger contexte (conversation + messages via COUNT(*))
5. Appeler LiteLLM avec fallback chain
6. confidence >= threshold (default 0.80)
7. Determiner action (reply/escalate/status_change/assign)
8. Verifier action activee dans settings
9. safe_mode bloque reply (laisse passer escalate/status_change)
10. Executer ou bloquer
11. Logger dans ai_action_log (avec summary NOT NULL)
12. Retourner resultat
```

---

## SECTION 11 — COMMANDES UTILES

### Verification etat du cluster
```bash
ssh root@46.62.171.61 -i ~/.ssh/id_rsa_keybuzz_v3
kubectl get nodes
kubectl get pods -n keybuzz-api-dev
kubectl get pods -n keybuzz-client-dev
kubectl get pods -n keybuzz-backend-dev
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Verification DB rapide
```bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query('SELECT id, name, plan, status FROM tenants');
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"
```

### Logs en temps reel
```bash
kubectl logs -f deploy/keybuzz-api -n keybuzz-api-dev --tail=50
kubectl logs -f deploy/keybuzz-backend -n keybuzz-backend-dev --tail=50
```

### Rollback d'urgence
```bash
# Toujours avoir le tag precedent
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:<PREVIOUS_TAG> -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## SECTION 12 — PROCHAINES ETAPES SUGGEREES

### Immediat (P0)
1. **Valider re-onboarding SWITAA** : L'utilisateur voulait refaire un onboarding complet apres la purge. Verifier que le flux login email + creation compte fonctionne.
2. **Bug reconnexion email** : L'utilisateur a signale qu'apres deconnexion, la reconnexion par email echoue ("le compte n'existe pas"). Investiguer le flux check-user → OTP.

### Court terme (P1)
3. **Promotion Autopilot en PROD** : Le client DEV est v3.5.121 (avec UI feedback autopilot), PROD est v3.5.120. Planifier la promotion.
4. **Correction modele LiteLLM kbz-cheap** : Le modele `claude-3-5-haiku-20241022` retourne 404 intermittent. Mettre a jour dans la config LiteLLM.
5. **Vault recovery** : DOWN depuis 52+ jours.

### Moyen terme (P2)
6. **FeatureGate activation** : PH129 a identifie que le gating est prepare mais non actif. PH130 prevu pour l'activer.
7. **Octopia enrichissement** : PH36.2 a commence, pas encore complet.
8. **Admin Panel nettoyage** : Drift GitOps corrige mais certaines dettes persistent.

---

## SECTION 13 — STYLE ET APPROCHE DE L'AGENT PRECEDENT

### Comment l'agent precedent travaillait :
1. **Toujours verifier avant d'agir** : Lire le code source, les logs, les images deployees AVANT de proposer un fix
2. **Scripts SH pour les operations bastion** : Ecrire un `.sh` local, SCP vers `/tmp/`, executer via SSH
3. **Validation multi-niveaux** : DEV d'abord, puis PROD. Toujours des verdicts explicites (OK / NOK)
4. **GitOps** : Apres chaque deploiement, mettre a jour les deployment.yaml dans keybuzz-infra
5. **Rapports detailles** : Chaque phase produit un rapport dans `keybuzz-infra/docs/PH-*-REPORT.md`
6. **Nettoyage de donnees** : Utiliser des SAVEPOINTs PostgreSQL pour des purges resilientes
7. **Diff minimal** : Toujours le plus petit patch possible. JAMAIS de rework massif.
8. **Reponse en francais** : Toujours. Sans exception.

### Format type d'un script bastion :
```bash
#!/bin/bash
set -e

echo "=== PH-XXX — Description ==="

# 1. Verification etat actuel
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
echo "Pod API: $POD"

# 2. Operation
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  // ... operations DB ...
  await p.end();
})();
"

# 3. Verification
echo ""
echo "=== VERDICTS ==="
echo "OPERATION_X = OK"
```

### Format type d'un rapport de phase :
```markdown
# PH-XXX — Titre

## Probleme
Description detaillee du probleme observe.

## Cause racine
Explication technique precise.

## Correctifs
Fichiers modifies avec extraits de code.

## Images deployees
| Service | DEV | PROD |
|---|---|---|

## Validation
Verdicts explicites : OK / NOK

## Rollback
Commande de rollback exact.
```

---

> **FIN DU PROMPT — Le nouvel agent doit maintenant etre capable de reprendre exactement la ou l'agent precedent s'est arrete, avec une connaissance complete du systeme KeyBuzz V3.**
