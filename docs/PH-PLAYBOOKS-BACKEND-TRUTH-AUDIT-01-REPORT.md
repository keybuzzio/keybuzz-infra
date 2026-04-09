# PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01 — Rapport Final

> Date : 1er mars 2026
> Agent : Cursor Executor
> Phase : PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01
> Type : audit cible + cadrage technique (sans implementation)
> Environnement : DEV uniquement — PROD NON TOUCHE

---

## Verdict Final

```
PLAYBOOKS AUDITED
REGRESSIONS STATUS: NO (PH-PLAYBOOKS-TRUTH-RECOVERY-01 n'a casse aucune feature)
BUSINESS TRUTH: ALIGNED (gating coherent entre planCapabilities et UI)
BACKEND TRUTH: DUAL SYSTEM (localStorage PAGE + DB ENGINE — desynchronises)
PROD STATUS: NOT TOUCHED
NEXT PHASE RECOMMENDED: PH-PLAYBOOKS-BACKEND-MIGRATION-02
```

---

## 1. Verite documentaire

### Contradiction majeure detectee

La documentation precedente (PH-PLAYBOOKS-TRUTH-RECOVERY-01) affirmait :
- "100% localStorage, aucune table playbooks en DB, aucun endpoint API"

**C'est FAUX.** L'audit revele :

| Composant | Existe ? | Deploye ? | Utilise ? |
|-----------|---------|-----------|-----------|
| `src/modules/playbooks/routes.ts` (API Fastify) | OUI | OUI (v3.5.50) | OUI (par inbox + autopilot) |
| `src/services/playbook-seed.service.ts` (API) | OUI | OUI | OUI (appele a chaque creation tenant) |
| `src/services/playbook-engine.service.ts` (API) | OUI | OUI | OUI (evaluation inbox) |
| Tables `ai_rules` / `ai_rule_conditions` / `ai_rule_actions` | OUI | OUI | OUI (105 rows, 7 tenants x 15 starters) |
| Table `playbook_suggestions` | OUI | OUI | OUI (0 rows, pas encore d'evaluation declenchee) |
| Routes BFF client (`app/api/playbooks/*`) | OUI | OUI | PARTIELLEMENT (suggestions = OUI, CRUD page = NON) |
| `PlaybookSuggestionBanner` (inbox) | OUI | OUI | OUI (appelle BFF → API → DB) |
| Page `/playbooks` | OUI | OUI | OUI mais **utilise localStorage, PAS le backend** |

Voir `PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01-DOC-TRUTH.md` pour le detail complet des contradictions.

---

## 2. Verite technique — Cartographie complete

### Architecture REELLE (deux systemes paralleles)

```
┌─────────────────────────────────────────────────────┐
│                    SYSTEME A                         │
│               Page /playbooks (CLIENT)               │
│                                                       │
│  Source : localStorage                                │
│  Cle : kb_client_playbooks:v1:<tenantId>              │
│  5 starters (delivery_delay, tracking_request,        │
│              damaged_item, supplier_escalation,        │
│              unanswered_2h)                            │
│  Status par defaut : enabled (sauf supplier)           │
│  IDs : pb-starter-1 a pb-starter-5                     │
│  Types : 8 triggers, 8 actions                         │
│  Simulation : client-side (checkTrigger/checkCondition)│
│  Persistence : navigateur uniquement                   │
│  Perdu si : clear localStorage, autre navigateur       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    SYSTEME B                         │
│               Moteur IA backend (API)                 │
│                                                       │
│  Source : PostgreSQL (tables ai_rules + conditions     │
│           + actions + playbook_suggestions)             │
│  15 starters par tenant (tracking, retard, retour,     │
│           defectueux, paiement, facture, annulation,    │
│           incompatible, hors-sujet, VIP, escalade...)   │
│  Status par defaut : disabled + is_starter=true         │
│  IDs : pb-<timestamp>-<random>                         │
│  Types : 15 triggers avec keywords + synonyms + regex   │
│  Evaluation : server-side (playbook-engine.service.ts)  │
│  Suggestions : via PlaybookSuggestionBanner (inbox)     │
│  Seed : automatique a la creation du tenant              │
│  Plan gating : min_plan dans chaque rule                 │
│  KBActions : debit sur execution (pas sur suggestion)    │
│  Persistence : DB multi-tenant, survit a tout             │
└─────────────────────────────────────────────────────┘

Les deux systemes ne communiquent PAS entre eux.
```

### Qui utilise quoi

| Consommateur | Systeme utilise | Detail |
|-------------|----------------|--------|
| Page `/playbooks` (liste, detail, tester) | **A (localStorage)** | `playbooks.service.ts` → `getPlaybooks()` |
| Page `/playbooks/new` | **A (localStorage)** | `savePlaybook()` ecrit dans localStorage |
| `PlaybookSuggestionBanner` (inbox) | **B (DB/API)** | BFF `/api/playbooks/suggestions` → API `/playbooks/suggestions` → DB `playbook_suggestions` |
| `PlaybookLink` (ai-ui) | **Navigation seule** | Lien vers `/playbooks/{id}` (page A) |
| AI Journal (`ai-journal/storage.ts`) | **MOCK** | Genere des faux events avec `source: "playbook"` |
| AI Journal (`ai-journal/page.tsx`) | **B (DB/API)** | Lit `ai_action_log` qui contient des references playbook |
| Autopilot Engine | **B (DB/API)** | `computeKBActions('playbook_auto')` pour le debit KBA |
| Seed a la creation tenant | **B (DB/API)** | `seedStarterPlaybooks()` dans `tenant-context-routes.ts` |
| Logout | **A (localStorage)** | Efface les cles `kb_playbooks:*` |

### Fichiers concernes

**Client (keybuzz-client — workspace local)** :
| Fichier | Systeme | Role |
|---------|---------|------|
| `src/services/playbooks.service.ts` | A | CRUD localStorage, simulation, 5 starters |
| `app/playbooks/page.tsx` | A | Liste des playbooks (localStorage) |
| `app/playbooks/[playbookId]/page.tsx` | A | Detail playbook (localStorage) |
| `app/playbooks/[playbookId]/tester/page.tsx` | A | Simulateur (localStorage) |
| `app/playbooks/new/page.tsx` | A | Creation (localStorage) |
| `src/features/inbox/components/PlaybookSuggestionBanner.tsx` | B | Suggestions inbox (API) |
| `src/features/ai-ui/PlaybookLink.tsx` | Nav | Lien vers page A |
| `src/features/ai-journal/storage.ts` | Mock | Faux events playbook |
| `app/api/playbooks/route.ts` | B (BFF) | Proxy CRUD vers API |
| `app/api/playbooks/[id]/route.ts` | B (BFF) | Proxy GET/PUT/DELETE vers API |
| `app/api/playbooks/[id]/toggle/route.ts` | B (BFF) | Proxy toggle vers API |
| `app/api/playbooks/suggestions/route.ts` | B (BFF) | Proxy suggestions vers API |
| `app/api/playbooks/suggestions/[id]/[action]/route.ts` | B (BFF) | Proxy apply/dismiss vers API |
| `app/api/playbooks/[id]/suggestions/route.ts` | B (BFF) | Proxy suggestions par ID |

**API (keybuzz-api — bastion)** :
| Fichier | Systeme | Role |
|---------|---------|------|
| `src/modules/playbooks/routes.ts` | B | CRUD complet + suggestions + toggle |
| `src/services/playbook-seed.service.ts` | B | 15 starters, seed automatique |
| `src/services/playbook-engine.service.ts` | B | Moteur d'evaluation (keywords, synonyms, regex) |
| `src/modules/auth/tenant-context-routes.ts` | B | Appelle `seedStarterPlaybooks()` |
| `src/modules/autopilot/engine.ts` | B | Debit KBA `playbook_auto` |
| `src/app.ts` | B | Enregistrement route `/playbooks` |

### Donnees en DB DEV

| Tenant | Rules (ai_rules) | Status | Source |
|--------|-----------------|--------|--------|
| ecomlg-001 | 15 | `disabled` | `is_starter=true` |
| switaa-mn9ioy5j | 15 | `disabled` | `is_starter=true` |
| switaa-sasu-mn9if5n2 | 15 | `disabled` | `is_starter=true` |
| ecomlg-mmiyygfg | 15 | `disabled` | `is_starter=true` |
| ecomlg07-gmail-com-mn7pn69e | 15 | `disabled` | `is_starter=true` |
| srv-performance-mn7ds3oj | 15 | `disabled` | `is_starter=true` |
| tenant-1772234265142 | 15 | `disabled` | `is_starter=true` |
| **Total** | **105 rules** | | |

**Suggestions** : 0 (table `playbook_suggestions` existe mais vide)

---

## 3. Verite business

### Matrice planCapabilities.ts vs page /playbooks vs inbox

| Feature | STARTER | PRO | AUTOPILOT | ENTERPRISE |
|---------|---------|-----|-----------|-----------|
| `hasBasicPlaybooks` | `true` | `true` | `true` | `true` |
| `hasAdvancedPlaybooks` | `false` | `true` | `true` | `true` |
| `canAutoExecute` | `false` | `false` | `true` | `true` |
| Page accessible (FeatureGate) | OUI (aucun gate) | OUI | OUI | OUI |
| InboxTripane suggestions | NON (`requiredPlan="PRO"`) | OUI | OUI | OUI |
| Autopilot auto-execution | NON | NON | OUI | OUI |

### Pricing config vs planCapabilities

| Feature pricing | Starter | Pro | Autopilot |
|-----------------|---------|-----|-----------|
| "Playbooks IA basiques" | OUI | OUI | OUI |
| "Playbooks IA avances" | NON | OUI | OUI |
| "Auto-execution playbooks" | NON | NON | OUI |

**Verdict : ALIGNED** — la page, le gating et la documentation pricing sont coherents.

### Sidebar / navigation

- `/playbooks` est visible pour TOUS les roles (owner, admin, agent)
- Les agents voient `/playbooks` dans la sidebar (`agentAllowed` dans `ClientLayout.tsx`)
- Le breadcrumb "Playbook" est gere pour les sous-pages

---

## 4. Preuve de non-regression post PH-PLAYBOOKS-TRUTH-RECOVERY-01

| Feature | Impact PH-PLAYBOOKS-TRUTH-RECOVERY-01 | Status |
|---------|--------------------------------------|--------|
| `/playbooks` (liste) | Fix tenantId → fonctionne | OK |
| `/playbooks/[id]` (detail) | Fix tenantId → fonctionne | OK |
| `/playbooks/[id]/tester` (simulateur) | Fix tenantId → fonctionne | OK |
| `/orders` | Aucun changement | OK |
| `/inbox` (suggestions) | Aucun changement (utilise systeme B) | OK |
| Billing / tenant context | Aucun changement | OK |
| Onboarding / auth | Aucun changement | OK |
| AI Journal | Aucun changement | OK |
| Autopilot | Aucun changement | OK |

Le fix de PH-PLAYBOOKS-TRUTH-RECOVERY-01 etait correct et cible : il a resolu le probleme de tenantId null dans la page client sans impacter le reste. Aucune regression detectee.

---

## 5. Contradictions detectees (recapitulatif)

| # | Contradiction | Gravite | Impact utilisateur |
|---|-------------|---------|-------------------|
| C1 | La documentation dit "pas de backend" — le backend existe | **HAUTE** | Les futurs developpeurs risquent de recreer ce qui existe deja |
| C2 | La page `/playbooks` montre 5 starters localStorage, l'inbox utilise 15 starters DB | **CRITIQUE** | L'utilisateur modifie des playbooks qui n'ont AUCUN effet sur le moteur IA |
| C3 | Les starters backend sont tous `disabled`, les starters client sont `enabled` | **HAUTE** | L'utilisateur pense que ses playbooks sont actifs, mais rien ne se passe cote IA |
| C4 | Le seed backend cree 15 rules a la creation du tenant, mais l'utilisateur ne les voit jamais | **MOYENNE** | Gaspillage de donnees, confusion si l'utilisateur voit des metriques differentes |
| C5 | Les IDs client (`pb-starter-N`) ne correspondent PAS aux IDs backend (`pb-<random>`) | **HAUTE** | Si l'utilisateur clique sur un lien playbook depuis le Journal IA, le playbook cible n'existe pas dans la page |
| C6 | La dette D25 dit "sans backend reel" — obsolete | **BASSE** | Documentation trompeuse pour les nouveaux developpeurs |

---

## 6. Architecture cible recommandee

### A. Stockage

**Cible : DB produit (PostgreSQL) — tables existantes**

Les tables existent deja et sont fonctionnelles :
- `ai_rules` : playbooks avec `tenant_id`, `name`, `trigger_type`, `scope`, `min_plan`, `priority`, `is_starter`, `status`
- `ai_rule_conditions` : conditions avec `rule_id`, `type`, `op`, `value`
- `ai_rule_actions` : actions avec `rule_id`, `type`, `params` (JSONB)
- `playbook_suggestions` : suggestions avec `conversation_id`, `tenant_id`, `rule_id`, `status`

**Aucune nouvelle table necessaire.** L'existant couvre deja :
- Multi-tenant strict (`tenant_id` sur chaque table)
- Versioning via `created_at` / `updated_at`
- Seed automatique (`is_starter` flag)
- Plan gating (`min_plan` column)

### B. API

**L'API CRUD existe deja et est fonctionnelle :**

| Method | Route | Implementation | Status |
|--------|-------|---------------|--------|
| GET | `/playbooks` | Liste tenant-scoped | OPERATIONNEL |
| GET | `/playbooks/:id` | Detail avec conditions/actions | OPERATIONNEL |
| POST | `/playbooks` | Creation avec conditions/actions | OPERATIONNEL |
| PUT | `/playbooks/:id` | Mise a jour avec remplacement conditions/actions | OPERATIONNEL |
| DELETE | `/playbooks/:id` | Suppression cascade | OPERATIONNEL |
| PATCH | `/playbooks/:id/toggle` | Toggle active/disabled | OPERATIONNEL |
| GET | `/playbooks/suggestions` | Suggestions par conversation | OPERATIONNEL |
| PATCH | `/playbooks/suggestions/:id/apply` | Appliquer suggestion | OPERATIONNEL |
| PATCH | `/playbooks/suggestions/:id/dismiss` | Rejeter suggestion | OPERATIONNEL |

**Routes BFF existantes et fonctionnelles :**

| Route BFF client | Vers API | Status |
|-----------------|----------|--------|
| `GET /api/playbooks` | `GET /playbooks` | OPERATIONNEL mais INUTILISE par la page |
| `POST /api/playbooks` | `POST /playbooks` | OPERATIONNEL mais INUTILISE |
| `GET /api/playbooks/[id]` | `GET /playbooks/:id` | OPERATIONNEL mais INUTILISE |
| `PUT /api/playbooks/[id]` | `PUT /playbooks/:id` | OPERATIONNEL mais INUTILISE |
| `DELETE /api/playbooks/[id]` | `DELETE /playbooks/:id` | OPERATIONNEL mais INUTILISE |
| `PATCH /api/playbooks/[id]/toggle` | `PATCH /playbooks/:id/toggle` | OPERATIONNEL mais INUTILISE |
| `GET /api/playbooks/suggestions` | `GET /playbooks/suggestions` | **UTILISE** par PlaybookSuggestionBanner |
| `PATCH /api/playbooks/suggestions/[id]/[action]` | `PATCH /playbooks/suggestions/:id/:action` | **UTILISE** |

**Conclusion : AUCUNE nouvelle API a creer.** Il suffit de brancher la page client sur les routes BFF existantes.

### C. Compatibilite migration

**Plan de migration recommande :**

1. **Modifier la page `/playbooks` pour lire depuis l'API** au lieu de localStorage
   - Remplacer `getPlaybooks()` (localStorage) par un fetch vers `/api/playbooks?tenantId=X`
   - Remplacer `savePlaybook()` par un POST/PUT vers `/api/playbooks`
   - Remplacer `deletePlaybook()` par un DELETE vers `/api/playbooks/:id`
   - Remplacer `togglePlaybook()` par un PATCH vers `/api/playbooks/:id/toggle`

2. **Gerer la migration des donnees localStorage existantes**
   - Au premier chargement apres migration, detecter si des playbooks custom existent dans localStorage
   - Si oui, les migrer vers la DB via POST `/api/playbooks`
   - Marquer la migration comme effectuee (`kb_playbooks_migrated:v1:<tenantId>`)
   - Ne PAS supprimer les donnees localStorage immediatement (rollback safety)

3. **Preserver ecomlg-001**
   - ecomlg-001 a deja 15 starters en DB (tous `disabled`)
   - Si l'utilisateur a cree des playbooks custom dans localStorage, ils seront migres
   - Les starters DB ne seront PAS touches (ils existent deja)

4. **Gerer les tenants deja seedes**
   - Tous les 7 tenants en DB ont deja 15 starters
   - La page va simplement les afficher au lieu des 5 du localStorage
   - L'utilisateur verra plus de playbooks (15 au lieu de 5) mais c'est un enrichissement

5. **Activer les starters au lieu de les laisser `disabled`**
   - Les starters backend sont tous `disabled` par defaut
   - Decision business a prendre : les activer en mode `suggest` (recommandation) plutot que `disabled`

### D. Exploitation produit

| Liaison | Status actuel | Apres migration |
|---------|-------------|-----------------|
| Inbox (suggestions) | FONCTIONNE (systeme B) | INCHANGE — meme systeme |
| Orders | AUCUNE liaison | Possible via `trigger_type` + `order_*` conditions |
| Autopilot | FONCTIONNE (systeme B, debit KBA) | INCHANGE — meme systeme |
| AI Journal | FONCTIONNE (logs dans `ai_action_log`) | INCHANGE |
| AI Assistant | INDIRECT (peut mentionner playbooks) | INCHANGE |

**Point cle : apres migration, la page affichera les MEMES playbooks que ceux utilises par le moteur IA.** C'est le gain majeur.

### E. Garde-fous

- `tenant_id` est present sur TOUTES les tables → pas d'effet cross-tenant possible
- Les routes API verifient toujours `tenantId` dans query ou body
- `tenantGuard` plugin Fastify s'applique (verification `user_tenants`)
- Le BFF passe `X-User-Email` → le backend peut verifier l'appartenance
- Pas de hardcode : tous les IDs sont dynamiques
- Fallback safe : si l'API echoue, la page peut afficher un etat vide avec message d'erreur
- Rollback possible : revenir a localStorage en une seule PR (changer les imports de service)

---

## 7. Decoupage des prochaines phases

### PH-PLAYBOOKS-BACKEND-MIGRATION-02 (P0 — Prioritaire)

**Objectif** : Brancher la page `/playbooks` sur le backend existant au lieu de localStorage.

**Scope** :
- Modifier `app/playbooks/page.tsx` pour fetch `/api/playbooks?tenantId=X`
- Modifier `app/playbooks/[playbookId]/page.tsx` pour fetch `/api/playbooks/:id`
- Modifier `app/playbooks/new/page.tsx` pour POST `/api/playbooks`
- Modifier le simulateur pour evaluer cote serveur ou garder client-side avec les donnees API
- Creer un hook `usePlaybooks()` qui centralise les appels API
- Ajouter une logique de migration one-shot localStorage → API
- Adapter les types TypeScript (structure `ai_rules` vs `Playbook` interface)

**Risques** :
- Les types TypeScript sont differents entre client (`Playbook`) et API (`ai_rules`)
- Les starters backend sont `disabled` → l'utilisateur verra 15 playbooks inactifs au lieu de 5 actifs
- La simulation client-side devra etre adaptee ou replacee par une evaluation serveur

**Rollback** : Revenir a `v3.5.123-playbooks-truth-recovery-*` (localStorage)

**Dependances** : Aucune — tout le backend est deja en place

### PH-PLAYBOOKS-STARTERS-ACTIVATION-03 (P1)

**Objectif** : Activer les starters pertinents en mode `suggest` au lieu de `disabled`.

**Scope** :
- Script SQL pour UPDATE les starters de `disabled` a `suggest` (mode suggestion, pas auto-execution)
- Decision business sur quels starters activer par defaut (les 15 ? seulement les `min_plan=starter` ?)
- Ajouter un mecanisme de "premiere activation" pour les nouveaux tenants

**Risques** :
- Si on active les starters pour tous les tenants d'un coup, il faut s'assurer que le moteur de suggestions ne genere pas de spam
- Le moteur d'evaluation doit etre verifie en conditions reelles

**Rollback** : UPDATE SQL inverse (`suggest` → `disabled`)

**Dependances** : PH-PLAYBOOKS-BACKEND-MIGRATION-02 (la page doit d'abord afficher les donnees DB)

### PH-PLAYBOOKS-AI-INTEGRATION-04 (P2)

**Objectif** : Connecter reellement le moteur d'evaluation aux flux inbound pour generer des suggestions.

**Scope** :
- Appeler `evaluatePlaybooksForConversation()` dans le pipeline inbound (nouveau message)
- Generer des `playbook_suggestions` en DB quand un trigger match
- Afficher les suggestions via `PlaybookSuggestionBanner` (deja en place)
- Integrer avec le journal IA pour tracer les evaluations
- Ajouter le debit KBActions sur application de suggestion

**Risques** :
- Performance : l'evaluation sur chaque message inbound doit etre rapide
- False positives : le matching par keywords/synonyms/regex peut etre trop large
- KBActions : le debit doit etre idempotent (`request_id`)

**Rollback** : Desactiver l'appel dans le pipeline inbound

**Dependances** : PH-PLAYBOOKS-STARTERS-ACTIVATION-03 (les starters doivent etre actifs)

### PH-PLAYBOOKS-AUTOPILOT-05 (P3)

**Objectif** : Activer l'auto-execution des playbooks pour les plans AUTOPILOT+.

**Scope** :
- Pour les tenants AUTOPILOT/ENTERPRISE avec `canAutoExecute: true`
- Les playbooks en mode `auto` executent directement les actions
- Integration avec le moteur autopilot existant (`engine.ts`)
- Journal IA : tracer les executions automatiques
- Garde-fous : limites de debit KBA, circuit breaker

**Risques** :
- Execution automatique = risque d'actions non desirees par l'utilisateur
- Necessite des gardes-fous robustes

**Rollback** : Passer tous les playbooks de `auto` a `suggest`

**Dependances** : PH-PLAYBOOKS-AI-INTEGRATION-04

---

## 8. Version / tag DEV

### Actuellement deploye

| Service | Image DEV | Image PROD |
|---------|----------|-----------|
| keybuzz-client | `v3.5.123-playbooks-truth-recovery-dev` | `v3.5.123-playbooks-truth-recovery-prod` |
| keybuzz-api | `v3.5.50-ph-tenant-iso-dev` | (non verifie — hors scope) |

### Pod client DEV

```
NAME                              READY   STATUS    RESTARTS   AGE
keybuzz-client-7fc4d4c9d9-zbb2x   1/1     Running   0          ~30min
```

### Rollback DEV disponible

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ph-amz-ui-state-dev \
  -n keybuzz-client-dev
```

### Modifications durant cet audit

**AUCUNE modification de code, image ou deploiement n'a ete effectuee.**

Cet audit est purement documentaire et analytique.

Seuls les fichiers de documentation suivants ont ete crees :
- `keybuzz-infra/docs/PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01-DOC-TRUTH.md`
- `keybuzz-infra/docs/PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01-REPORT.md`

---

## 9. Statut PROD

**PROD = NON TOUCHE**

Aucune action n'a ete effectuee sur l'environnement PROD :
- Aucun build PROD
- Aucun push PROD
- Aucun deploiement PROD
- Aucune modification de manifests PROD

---

## 10. Resume executif

### Ce que nous savons maintenant

1. **Le backend Playbooks EXISTE et est COMPLET** : CRUD + moteur d'evaluation + seed automatique + 4 tables DB + 105 rules en DEV
2. **La page `/playbooks` l'IGNORE** et utilise localStorage avec un jeu de starters different
3. **L'inbox utilise le backend** via `PlaybookSuggestionBanner` (gate PRO+)
4. **Le seed est automatique** a la creation de chaque tenant (15 starters `disabled`)
5. **Aucune regression** de PH-PLAYBOOKS-TRUTH-RECOVERY-01
6. **Le gating business est coherent** : basiques pour tous, avances pour PRO+, auto-execution pour AUTOPILOT+
7. **La migration est SIMPLE** car tout le backend est deja pret — il suffit de reconnecter la page

### Ce qui doit etre fait

La prochaine etape (PH-PLAYBOOKS-BACKEND-MIGRATION-02) consiste a :
- Brancher la page `/playbooks` sur les routes BFF deja existantes
- Unifier les deux systemes en un seul (DB)
- Migrer les eventuels playbooks custom localStorage vers la DB
- Eliminer le code localStorage devenu obsolete

### Estimation d'effort

| Phase | Effort | Risque |
|-------|--------|--------|
| PH-PLAYBOOKS-BACKEND-MIGRATION-02 | Moyen (4-6h) | Bas (backend pret) |
| PH-PLAYBOOKS-STARTERS-ACTIVATION-03 | Faible (1-2h) | Bas |
| PH-PLAYBOOKS-AI-INTEGRATION-04 | Moyen (4-6h) | Moyen (perf + false positives) |
| PH-PLAYBOOKS-AUTOPILOT-05 | Eleve (6-8h) | Eleve (auto-execution) |

---

## PLAYBOOKS AUDITED — REGRESSIONS: NO — BUSINESS: ALIGNED — BACKEND: DUAL SYSTEM — PROD: NOT TOUCHED — NEXT: PH-PLAYBOOKS-BACKEND-MIGRATION-02

---

DEV audite et pret. STOP avant PROD. J'attends la validation explicite de Ludovic : "Tu peux push PROD".
