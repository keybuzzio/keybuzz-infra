# PH37 — GLOBAL AUDIT REPORT

> Date : 6 mars 2026
> Mode : **READ-ONLY** — aucune modification effectuee
> Auditeur : CE (Cursor Executor)
> Statut : **AUDIT TERMINE** — en attente de validation Ludovic

---

## MATRICE DE PRIORITE

### P0 — SECURITE CRITIQUE (a corriger avant onboarding)

| # | Probleme | Module | Impact | Detail |
|---|---|---|---|---|
| P0-1 | **Conversations accessibles cross-tenant** | messages/routes.ts | Exfiltration donnees | 29 queries SQL, seulement 2 filtrent par `tenant_id`. `GET /conversations/:id` fait `WHERE id = $1` sans filtre tenant |
| P0-2 | **Outbound sans isolation tenant** | outbound/routes.ts | Exfiltration + manipulation | `GET /deliveries` sans tenantId retourne TOUTES les deliveries. Acces par ID sans filtre tenant |
| P0-3 | **Agents/Teams sans isolation** | agents + teams routes | Exfiltration RH | `tenantId` optionnel. Sans lui, retourne tous les agents/equipes |
| P0-4 | **Integrations sans isolation** | integrations/routes.ts | Exposition credentials | `GET /integrations/:pk` par PK seul. Exposition potentielle des tokens/credentials |
| P0-5 | **tenantGuard passe silencieusement** | tenantGuard.ts | Bypass general | Si aucun tenantId dans la requete ET aucun email dans les headers, le guard `return` sans bloquer |
| P0-6 | **AI global settings sans auth admin** | ai/routes.ts | Kill switch accessible | `GET/PATCH /ai/global/settings` modifiable par n'importe quel utilisateur authentifie |
| P0-7 | **Auto-creation users via magic/start** | auth/routes.ts | Pollution DB | `POST /magic/start` cree automatiquement un user si inexistant. N'importe qui peut creer des comptes |
| P0-8 | **getUserFromEmail() fait INSERT** | tenant-context-routes.ts | Auto-creation | `getUserFromEmail()` fait un `INSERT INTO users` si l'email n'existe pas. Devrait etre read-only |

### P1 — BUGS FONCTIONNELS (a corriger rapidement)

| # | Probleme | Module | Impact | Detail |
|---|---|---|---|---|
| P1-1 | **Wallet/ledger drift -813.44** | ai-actions.service.ts | Comptabilite faussee | `devSetActions()` ecrit la valeur absolue comme delta. `monthly_reset` inscrit `includedMonthly` comme delta. Le ledger n'est pas un grand livre coherent |
| P1-2 | **Pas de UNIQUE sur request_id** | ai_actions_ledger | Double debit possible | L'idempotence repose sur un SELECT applicatif, pas sur une contrainte DB. Race condition en cas de requetes concurrentes |
| P1-3 | **Google OAuth sans email_verified** | auth-options.ts | Usurpation email | Aucune verification `email_verified` dans le callback Google. Un compte Google non verifie peut s'authentifier |
| P1-4 | **OTP en memoire (client)** | otp-store.ts (client) | OTP perdus au restart | Le NextAuth CredentialsProvider utilise un store OTP in-memory. Au restart du pod, tous les OTP en cours sont perdus |
| P1-5 | **Redis replication cassee** | redis-01/02/03 | Risque perte donnees | Master isole (0 replicas). `masterauth` mismatch. Sentinel marque master `s_down` depuis 3.3 jours |
| P1-6 | **PostgreSQL replica start failed** | db-postgres-02 | HA degrade | Timeline WAL divergente depuis le 21 fev. Necessite `patronictl reinit` |
| P1-7 | **Attachment download bypass** | attachments/routes.ts | Acces cross-tenant | Si aucun `X-Tenant-Id` envoye, la verification `att.tenant_id !== tenantId` est bypassee (tenantId falsy) |
| P1-8 | **Notifications sans isolation** | notifications/routes.ts | Fuite notifications | `tenantId` optionnel. Sans lui, expose les notifications de tous les tenants |
| P1-9 | **17 outbound failures** | outbound_deliveries | Messages non envoyes | 17/183 deliveries en echec (9.3%). A diagnostiquer |

### P2 — DETTE TECHNIQUE (a planifier)

| # | Probleme | Module | Impact | Detail |
|---|---|---|---|---|
| P2-1 | **Hardcode `client-dev.keybuzz.io`** | 4 fichiers API + 1 client | Mauvais redirects PROD | Fallback `APP_BASE_URL` pointe DEV si env var absente. Fichiers : auth/routes.ts, space-invites, billing, app.ts |
| P2-2 | **Hardcode `ecomlg-001`** | backend amazonFees | Single-tenant fallback | Default tenant hardcode dans le backend Python/TS |
| P2-3 | **CORS origins hardcodes** | app.ts | Securite CORS | admin-dev et client-dev en dur dans le fallback CORS |
| P2-4 | **Logging inconsistant** | Tous modules AI + Auth | Debug difficile | Mix `console.log` et `app.log` (Fastify structured logger) |
| P2-5 | **Deux systemes auth** | API + Client | Architecture fragile | API a son propre JWT/cookie (`kb_session`), Client utilise NextAuth. Deux sessions independantes |
| P2-6 | **devSetActions sans env guard** | ai-actions.service.ts | Risque PROD | Route `/wallet/actions/set` accessible sans verification `NODE_ENV` |
| P2-7 | **Admin DEV/PROD non aligne** | keybuzz-admin | Version divergente | DEV v2.1.3-ws, PROD v1.0.2 |
| P2-8 | **LiteLLM + CronJobs en :latest** | k8s manifests | Reproductibilite | Viole la regle "jamais de :latest" |
| P2-9 | **Demo users/tenants en memoire** | auth/routes.ts | Pollution | `kbz-001`, `kbz-002` hardcodes en memoire (desactives en prod mais code present) |
| P2-10 | **Autopilote KBA mismatch** | kbactions.ts | Confusion marketing | Code: 2000 KBA/mois, Marketing: 3500 KBA/mois |
| P2-11 | **Reset mensuel lazy** | ai-actions.service.ts | UX confuse | Reset declenche uniquement a la lecture du wallet, pas par cron |
| P2-12 | **SP-API marketplace_id fallback** | spapiMessaging.ts | Multi-pays fragile | `A13V1IB3VIYZZH` (Amazon.fr) hardcode comme fallback avec TODO |

### P3 — AMELIORATIONS (backlog)

| # | Probleme | Module | Impact |
|---|---|---|---|
| P3-1 | metrics-server absent | K8s | Pas de monitoring ressources pods |
| P3-2 | k8s-worker-01 cordonne | K8s | 8 CPU + 15GB RAM inutilises |
| P3-3 | sla-evaluator-escalation DEV only | CronJobs | Pas d'escalation SLA en PROD |
| P3-4 | Amazon SP-API messaging desactive | Outbound | Reponses via email forwarding uniquement |
| P3-5 | Outbound worker restarts | K8s | 8 restarts DEV, 3 PROD (accumules sur 69+ jours) |
| P3-6 | Redis Sentinel faux slave | Redis | 10.0.0.152 (siem-01) enregistre comme replica Redis |

---

## 1. RESUME AUTH (PH37.1)

### Etat du systeme

| Composant | Implementation | Verdict |
|---|---|---|
| OTP generation | `crypto.randomInt(100000, 999999)` | **OK** |
| OTP stockage API | SHA-256 + salt aleatoire (16 bytes) | **OK** |
| OTP stockage partage | Redis (`otp:{email}`, TTL 600s) | **OK** |
| OTP expiration | 10 minutes (600s) | **OK** |
| OTP tentatives max | 5 (API) / 3 (Client in-memory) | **INCOHERENT** |
| Rate limit OTP | 5/min/IP + 3/15min/email + 10/min verify | **OK** |
| Google email_verified | **NON VERIFIE** | **FAIL** |
| Cookies httpOnly | Oui (kb_session + NextAuth) | **OK** |
| Cookies secure | Oui en prod | **OK** |
| SameSite | `lax` | **OK** |
| JWT secret | Via env (`JWT_SECRET`, crash si absent) | **OK** |
| Cross-tenant protection | tenantGuard avec bypass silencieux | **PARTIEL** |
| Session renewal | Apres 24h (nouveau JWT) | **OK** |
| Token revocation | In-memory `Set<string>` (perdu au restart) | **FRAGILE** |

### Architecture auth duale

```
Client (NextAuth)                API (custom JWT)
├── Google OAuth ──────────►     ├── /auth/magic/start (OTP)
├── Azure AD OAuth              ├── /auth/magic/verify
├── Credentials (email-otp) ──► ├── /auth/me (cookie kb_session)
├── Session JWT (next-auth)     ├── /auth/select-tenant
└── Cookie: next-auth.*         └── Cookie: kb_session
```

Deux systemes de session coexistent. Le client utilise NextAuth pour l'auth initiale, puis les routes BFF proxient vers l'API avec `X-User-Email` / `X-Tenant-Id`.

---

## 2. RESUME MULTI-TENANT (PH37.2)

### Pattern d'attaque principal

Le `tenantGuard` verifie que **l'utilisateur appartient au tenant** fourni. Mais les routes qui accedent aux ressources par **ID direct** (UUID conversation, PK integration) ne verifient pas que **la ressource appartient au tenant**. Resultat : un attaquant authentifie sur son propre tenant peut acceder aux ressources d'un autre tenant par ID.

### Bilan routes

| Module | Isolation | Verdict |
|---|---|---|
| dashboard | tenantId requis, SQL filtre | **OK** |
| stats | tenantId requis | **OK** |
| playbooks/ai_rules | tenantId requis, SQL filtre | **OK** |
| suppliers | tenantId requis, SQL filtre | **OK** |
| billing | tenantId requis + regex | **OK** |
| kpi | tenantId requis | **OK** |
| orders | tenantId requis, SQL filtre | **OK** |
| **messages** | **Acces par ID sans filtre tenant** | **FAIL P0** |
| **outbound** | **Aucune isolation** | **FAIL P0** |
| **agents** | **tenantId optionnel** | **FAIL P0** |
| **teams** | **tenantId optionnel** | **FAIL P0** |
| **integrations** | **tenantId optionnel + PK direct** | **FAIL P0** |
| **notifications** | **tenantId optionnel** | **FAIL P1** |
| **attachments** | **Verification bypassable** | **FAIL P1** |
| **ai global** | **Pas de check admin** | **FAIL P0** |

---

## 3. RESUME MARKETPLACES (PH37.3)

### Amazon

| Check | Resultat |
|---|---|
| Integration | **Email-based** (SMTP forwarding, pas API) |
| SP-API OAuth | Defini mais **aucune connexion active** |
| SP-API Messaging | **Desactive** (`AMAZON_SPAPI_MESSAGING_ENABLED=false`) |
| Import messages | **OK** — 154 conversations via inbound email |
| Import commandes | **OK** — 11 161 via backfill + sync |
| Sync | **OK** — CronJob `amazon-orders-sync` toutes les 5 min |
| Reponse message | **OK** — via SMTP (166 delivered, 17 failed) |
| Email inbound | **OK** — 1 adresse validee (`amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`) |
| Mocks | **AUCUN** |

### Octopia

| Check | Resultat |
|---|---|
| Integration | **API native complète** (auth, import, sync, outbound) |
| Modes | AGGREGATOR (credentials KeyBuzz) + DIRECT |
| Etat | **Aucun tenant connecte** (table vide) |
| Code quality | **OK** — Complet, bien structure, adapters dedies |

---

## 4. RESUME KBActions (PH37.4)

| Check | Resultat |
|---|---|
| Wallet ledger coherent | **FAIL** — Drift -813.44 sur ecomlg-001 |
| Remaining correct | **OK** — 968.01 (ecomlg), 1000 (switaa) |
| includedMonthly | **OK** — 1000 pour les 2 tenants PRO |
| purchasedRemaining | **OK** — 0 (aucun achat) |
| Reset mensuel | **PARTIEL** — Lazy (pas de cron), prochain 1er avril |
| Double credit impossible | **RISQUE** — SELECT applicatif, pas de UNIQUE DB |
| Downgrade/upgrade safe | **OK** — Grant idempotent via cle subscription |
| AI allowed logic | **OK** — Double check KBActions + budget USD |
| Balances negatives | **OK** — Aucune |
| Duplicate request_id | **OK** — Aucun detecte a ce jour |

---

## 5. RESUME INFRA (PH37.5)

| Composant | Etat | Detail |
|---|---|---|
| **Vault HA** | **SAIN** | 3 noeuds Raft, leader vault-02, tous unsealed, index sync 56550 |
| **ESO** | **SAIN** | 20 ExternalSecrets synchronises, ClusterSecretStores Valid |
| **PostgreSQL** | **DEGRADE** | Leader db-postgres-03, replica db-postgres-01 OK (lag <25ms), db-postgres-02 `start failed` (timeline divergente) |
| **Redis** | **CRITIQUE** | Master redis-01 isole (0 replicas), Sentinel `s_down` 3.3j, ACL mismatch, faux slave 10.0.0.152 |
| **K8s Pods** | **SAIN** | Aucun crash loop. Max restarts: 10 (kube-state-metrics sur 87j) |
| **Certificats** | **SAIN** | 12/12 valides (Let's Encrypt) |
| **worker-01** | **CORDONNE** | Sain mais SchedulingDisabled |
| **metrics-server** | **ABSENT** | `kubectl top` indisponible |

---

## 6. RESUME CODE QUALITY (PH37.6)

| Type | Count | Severite | Fichiers |
|---|---|---|---|
| Tenant ID hardcode | 1 | **CRITIQUE** | backend/amazonFees.routes.ts (`ecomlg-001`) |
| URL DEV fallback | 5 | **MOYEN** | auth/routes.ts, space-invites, billing, app.ts, client/logout |
| IP fallback | 6 | **FAIBLE** | Scripts one-shot + config/redis.ts (`10.0.0.10`) |
| CORS hardcode | 1 | **MOYEN** | app.ts (admin-dev, client-dev en dur) |
| Secrets en clair | 0 | **OK** | Aucun credential expose |

---

## 7. RESUME OBSERVABILITE (PH37.7)

| Log Pattern | Present dans le code | Present dans les logs live |
|---|---|---|
| Amazon inbound | **OUI** — `app.log.info/warn/error` | **OUI** — Messages recus |
| Backfill orders | **OUI** — `[OrdersWorker]` structured | **OUI** — Iterations + persisted count |
| Items worker | **OUI** — `[ItemsWorker]` structured | **OUI** — BATCH_DONE + tenant |
| Scheduler | **OUI** — `[Scheduler]` structured | **OUI** — GLOBAL_THROTTLE + fairness |
| AI debit | **OUI** — `KBACTIONS_DEBIT_EXECUTED` | **NON** — Pas d'action IA recente |
| Playbooks | **OUI** — `ai_action_log` table | **NON** — Tous disabled |
| Auth events | **OUI** — `[TenantContext]` tags | **NON** — Pas de login recent dans les logs captures |

### Inconsistance logging

Le code utilise un mix de `console.log` (modules AI, Auth) et `app.log` (Fastify structured logger, modules Inbound). Les logs ne sont pas uniformes, ce qui complique le parsing dans Loki.

---

## PLAN D'ACTION RECOMMANDE

### Sprint 1 — Securite (P0) — BLOQUANT onboarding

1. **Ajouter `AND tenant_id = $X`** a TOUTES les queries par ID dans messages/routes.ts
2. **Rendre tenantId OBLIGATOIRE** dans outbound, agents, teams, integrations, notifications
3. **Renforcer tenantGuard** : bloquer si aucun tenantId (au lieu de passer silencieusement)
4. **Proteger `/ai/global/settings`** avec verification admin
5. **Supprimer auto-creation** dans `magic/start` et `getUserFromEmail()`
6. **Ajouter check `email_verified`** dans callback Google OAuth
7. **Verification tenant sur attachments** : rendre `X-Tenant-Id` obligatoire pour download

### Sprint 2 — Fiabilite (P1)

1. **Redis** : realigner `masterauth`/`requirepass`/ACL, retablir replication
2. **PostgreSQL** : `patronictl reinit db-postgres-02` pour resynchroniser
3. **KBActions** : ajouter `UNIQUE(request_id)` sur `ai_actions_ledger`, corriger `devSetActions()`
4. **OTP client** : migrer vers Redis (au lieu d'in-memory) ou supprimer le double OTP
5. **Outbound failures** : diagnostiquer les 17 echecs

### Sprint 3 — Dette technique (P2)

1. Remplacer fallbacks `client-dev.keybuzz.io` par variables d'environnement obligatoires
2. Supprimer hardcode `ecomlg-001` du backend
3. Unifier le logging (Fastify structured everywhere)
4. Aligner Admin DEV/PROD
5. Pinner LiteLLM et CronJobs (supprimer `:latest`)
6. Ajouter guard `NODE_ENV` sur `devSetActions`
7. Aligner Autopilote KBA (2000 vs 3500)

---

**FIN — PH37 GLOBAL AUDIT REPORT**

Aucune modification effectuee. Rapport soumis pour validation Ludovic.
