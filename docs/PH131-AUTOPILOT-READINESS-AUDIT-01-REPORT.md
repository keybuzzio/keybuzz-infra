# PH131-AUTOPILOT-READINESS-AUDIT-01 — Rapport Final

> Date : 25 mars 2026
> Auteur : Agent Cursor
> Phase : PH131 — Audit de preparation Autopilot
> Type : LECTURE SEULE — aucune modification

---

## 1. Audit complet Autopilot — Ce qui existe reellement

### 1.1 Mode "autonomous" dans le backend

| Element | Existe | Execute reellement |
|---------|--------|-------------------|
| Colonne `mode` dans `ai_settings` | OUI (`text`) | Valeur stockee, pas de branche d'execution |
| Valeurs possibles du mode | `suggestion`, `supervised`, `autonomous` | Seul le GATING (PH130) utilise la valeur |
| Guard plan mode=autonomous | OUI (PH130) — 403 si plan < AUTOPILOT | Fonctionne |
| Guard plan mode=supervised | OUI (PH130) — 403 si plan = STARTER | Fonctionne |
| Auto-reply engine | **NON** | Aucun worker ni cron qui envoie des reponses automatiques |
| Auto-assign engine | **NON** | Aucune logique d'assignation automatique IA |
| Auto-escalate engine | **NON** | SLA cron SQL only (pas de routage vers agents) |
| Auto-status-change engine | **NON** | Aucun changement de statut automatique par l'IA |
| Playbook execution engine | **NON** | Playbooks = enrichissement de prompt, pas d'execution |

### 1.2 Moteurs PH existants (dry-run uniquement)

| Moteur | Fichier | Ce qu'il fait | Execute ? |
|--------|---------|-------------|-----------|
| PH105 — Autonomous Ops | `autonomousOpsEngine.ts` | Traduit decisions strategiques en plans d'actions | **DRY-RUN ONLY** — doc explicite |
| PH106 — Action Dispatcher | `actionDispatcherEngine.ts` | Route actions vers queues logiques | **DRY-RUN ONLY** — `dryRunEnforced: true` |
| PH108 — Case Manager | `autonomousCaseManagerEngine.ts` | Gere etats de cas IA | **DRY-RUN ONLY** |
| PH113 — Safe Real Execution | `safeRealExecutionEngine.ts` | Calcule eligibilite, readiness, quotas | **Pas d'appel HTTP reel** — pas de connecteur |

**Conclusion : Le mode `autonomous` est UNIQUEMENT GATE, pas MOTORISE. Il n'existe aucune execution automatique d'actions.**

### 1.3 Frontend — Ce qui existe pour "autonomous"

| Element | Existe | Fonctionnel |
|---------|--------|-------------|
| `AIModeSwitch.tsx` — boutons suggestion/supervised/autonomous | OUI | Lock+message pour plans insuffisants (PH130) |
| `AIDecisionPanel.tsx` — bouton "Laisser KeyBuzz repondre" | OUI | Affiche conditionnellement si mode=autonomous, appelle `POST /ai/execute` |
| `POST /ai/execute` endpoint | OUI dans le code | N'execute PAS d'envoi reel — bloque en mode `suggestion`, simule en autres modes |
| Settings IA — limites de securite | OUI (max_actions_per_hour, kill_switch, etc.) | Stocke en DB, pas utilise par un moteur |

### 1.4 Playbooks

| Element | Existe | Fonctionnel |
|---------|--------|-------------|
| Table `ai_rules` | OUI — 10 regles pour tenant `ecomlg-mmiyygfg` | Toutes en mode `suggest`, toutes `disabled` |
| CRUD playbooks UI | OUI — liste, creation, edition | Fonctionnel |
| Simulateur playbook UI | OUI | Simulation locale (pas d'API) |
| Execution automatique backend | **NON** | Playbooks = enrichissement de prompt IA, pas de triggers auto |

---

## 2. Audit escalade par plan

### 2.1 Modele actuel

| Element | Etat reel |
|---------|----------|
| Table `agents` | EXISTE mais **VIDE** (0 lignes) |
| Table `user_tenants` | 6 associations — toutes role=`owner`, aucun `agent` |
| Assignation conversation | Colonne `assigned_agent_id` existe — **aucune conversation assignee** actuellement |
| Type `keybuzz_agent` | Declare dans `roles.ts` (UI client) — **aucune utilisation en DB** |
| `escalationTarget` dans `planCapabilities.ts` | `none` / `client_team` / `keybuzz_team` — **DECLARATIF seulement** |
| Routage escalade vers agents | **INEXISTANT** — pas de code qui route vers des agents specifiques |
| Agents KeyBuzz en DB | **INEXISTANTS** — pas d'utilisateurs KeyBuzz dans les tenants clients |

### 2.2 SLA et escalade

| Element | Etat |
|---------|------|
| `sla_policies` | 5 politiques (global, amazon, email, pro-amazon, enterprise-amazon) |
| CronJob `sla-evaluator` | OUI — SQL UPDATE sla_state (ok → risk → breached) |
| CronJob `sla-evaluator-escalation` | OUI — transition d'etats + tags + notifications |
| Auto-assign SLA | Version YAML reference : auto-assign `agent-001` si non assigne — **pas par plan** |
| Escalade vers equipe client | **INEXISTANT** — pas de logique de routage par plan |
| Escalade vers KeyBuzz | **INEXISTANT** — pas d'infrastructure ni d'agents |

### 2.3 Ce qui manque pour supporter le modele cible

| Plan | Cible | Manque |
|------|-------|--------|
| **STARTER** | Aucune escalade avancee | OK — rien a faire |
| **PRO** | Escalade vers equipe client uniquement | Table agents vide, pas de logique de routage, pas d'UI de gestion d'equipe fonctionnelle (teams = mock) |
| **AUTOPILOT** | Escalade configurable (KeyBuzz/client/both) | Tout manque : setting `escalation_target`, agents KeyBuzz, routage, file d'attente |
| **ENTERPRISE** | Idem AUTOPILOT, sur mesure | Idem |

---

## 3. Audit settings necessaires Autopilot

### 3.1 Ce qui existe dans `ai_settings`

| Colonne | Type | Valeur type | Role |
|---------|------|-------------|------|
| `mode` | text | `supervised` | Mode IA actif |
| `ai_enabled` | boolean | true | IA activee |
| `safe_mode` | boolean | true | Mode securise |
| `kill_switch` | boolean | false | Arret d'urgence |
| `max_actions_per_hour` | integer | 20 | Limite horaire |
| `max_auto_replies_per_conversation` | integer | 3 | Limite reponses auto/conversation |
| `max_consecutive_ai_actions` | integer | 2 | Limite actions consecutives |
| `max_simultaneous_executions` | integer | 1 | Limite executions simultanees |
| `auto_disable_threshold` | integer | 5 | Seuil erreurs avant auto-disable |
| `auto_disabled` | boolean | false | Auto-desactivation suite erreurs |
| `daily_budget` | integer | 0 | Budget quotidien (ancien systeme) |
| `daily_budget_usd` | numeric | null | Budget quotidien USD |

### 3.2 Ce qui MANQUE pour l'Autopilot

| Setting manquant | Description | Priorite |
|-----------------|-------------|----------|
| `escalation_target` | `client_only` / `keybuzz_only` / `both` | **CRITIQUE** |
| `allowed_auto_actions` | Liste : `reply`, `assign`, `escalate`, `status_change` | **CRITIQUE** |
| `auto_reply_enabled` | Boolean : autoriser les reponses auto | **CRITIQUE** |
| `auto_assign_enabled` | Boolean : autoriser l'assignation auto | MAJEUR |
| `fallback_mode` | Mode de repli si probleme (`suggestion` par defaut) | MAJEUR |
| `confidence_threshold` | Seuil de confiance pour action auto (ex: 0.85) | MAJEUR |
| `human_review_percentage` | % de cas revus par un humain meme en autonome | MINEUR |

---

## 4. Audit KBActions comme monnaie reelle

### 4.1 Schema `ai_actions_wallet`

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `tenant_id` | varchar | NON | Cle primaire |
| `remaining` | numeric | NON | KBActions restantes (incluses + achetees) |
| `purchased_remaining` | numeric | NON | KBActions achetees restantes |
| `included_monthly` | numeric | NON | KBActions incluses dans le plan |
| `reset_at` | timestamptz | NON | Date du prochain reset mensuel |
| `updated_at` | timestamptz | NON | Derniere mise a jour |

### 4.2 Donnees reelles (25 mars 2026)

| Tenant | Plan | Remaining | Purchased | Included | Reset |
|--------|------|-----------|-----------|----------|-------|
| `ecomlg-001` | PRO (exempt) | **0.38** | 0 | 1000 | 1er avril |
| `ecomlg-mmiyygfg` | PRO | 1000 | 0 | 1000 | 1er avril |
| `switaa-sasu-mn27vxee` | AUTOPILOT | 2000 | 0 | 2000 | 1er avril |
| `ecomlg-mn3rj8mg` | AUTOPILOT | 2000 | 0 | 2000 | 1er avril |
| `tenant-1772234265142` (Essai) | STARTER | **manquant** | - | - | - |
| `w3lg-mn2v3xyc` | PRO (pending_payment) | 0 | 0 | 0 | 1er avril |

### 4.3 Consommation reelle

Le dernier debit reel : tenant `ecomlg-001`, **-6.05 KBActions** pour `ai_generation` (inbox_suggestion), cout USD $0.009498.
- Poids utilise : `inbox_suggestion` = base 6.0 KBA ± 15% variance
- Decision context : riche (savScenario, costAwareness, merchantBehavior, etc.)
- Idempotence : sur `request_id` (verifie avant debit)

### 4.4 Poids par operation

| Source | Poids base (KBA) |
|--------|-----------------|
| `inbox_suggestion` | 6.0 |
| `inbox_contextualized` | 10.0 |
| `inbox_regenerate` | 3.0 |
| `playbook_auto` | 8.0 |
| `playbook_simulation` | 4.0 |
| `attachment_analysis` | 14.0 |
| `sentiment_analysis` | 6.0 |
| `heavy_decision` | 20.0 |

### 4.5 Comportement wallet vide

- `checkActionsAvailable(tenantId)` retourne `available: false` si `remaining <= 0`
- Le endpoint `/ai/assist` retourne **HTTP 402** `actions_exhausted`
- L'UI affiche un blocage (`AIActionsLimitBlock`)
- **Pas de debit negatif possible** : le check est AVANT l'appel LLM

### 4.6 Reset mensuel

- `getActionsWallet()` verifie `reset_at` — si passe, reset `remaining` a `included_monthly` (les `purchased_remaining` sont preservees)
- `reset_at` avance au 1er du mois suivant
- **Pas de CronJob dedie** : le reset est fait a la volee lors de la prochaine lecture du wallet

### 4.7 Systeme dual (legacy)

Il existe un **second systeme** `ai_credits_wallet` (`balance_usd`, `lifetime_credits_usd`) — legacy, utilise uniquement pour le tracking USD interne (`credits_enabled: false` sur presque tous les tenants sauf `ecomlg-001`). **Pas expose au client.**

---

## 5. Achat ponctuel KBActions — bout en bout

### 5.1 Flux complet

```
1. UI: AIActionsLimit.tsx → bouton "Acheter"
   Packs affiches: 50 KBA / 24.90€, 200 KBA / 69.90€, 500 KBA / 149.90€

2. BFF: POST /api/billing/ai-actions-checkout
   → Proxy vers API avec tenantId, packId, priceAmountCents, usdCredit, actions

3. API: POST /billing/ai-actions-checkout
   → Si Stripe non configure (DEV) : addPurchasedActions() direct
   → Si Stripe configure : checkout.sessions.create (mode: payment, price_data dynamique)

4. Stripe: Client paie

5. Webhook: checkout.session.completed
   → handleCheckoutCompleted() si metadata.type === 'ai_actions'
   → addPurchasedActions(tenantId, actions, 'stripe-'+session.id)

6. Service: addPurchasedActions()
   → UPDATE remaining += actions, purchased_remaining += actions
   → INSERT ledger (reason: 'purchase')

7. Wallet mis a jour, KBActions disponibles
```

### 5.2 Points d'attention

| Point | Etat | Impact |
|-------|------|--------|
| Packs KBActions = prix dynamiques Stripe (`price_data`) | OUI | Pas de Price ID Stripe dedie — checkout one-time |
| BFF PRODUCTION BLOCK | **OUI** — `ai-actions-checkout/route.ts` retourne 403 si `NEXT_PUBLIC_APP_ENV=production` | **BLOQUANT : les clients PROD ne peuvent PAS acheter de KBActions via le client** |
| STARTER peut acheter | OUI — aucune restriction plan sur le checkout API | OK |
| Idempotence achat | OUI — `request_id` = `'stripe-'+session.id` | OK |

### 5.3 PROBLEME CRITIQUE — BFF bloque en PROD

Le fichier `app/api/billing/ai-actions-checkout/route.ts` contient :

```
if (process.env.NEXT_PUBLIC_APP_ENV === 'production') {
  return NextResponse.json({ error: 'AI Actions purchase not available in production' }, { status: 403 });
}
```

Cela signifie que **le checkout KBActions est bloque en production**. Le test backend (PROD port 3001) passe car il contourne le BFF, mais un client reel via `client.keybuzz.io` ne pourra PAS acheter.

---

## 6. Audit Stripe en reel

### 6.1 Objets Stripe existants

#### DEV (sk_test_)

| Objet | Price ID | Statut |
|-------|----------|--------|
| STARTER Monthly | `price_1SmO9sFC0QQLHISRbZkOA7Ox` | EXISTE |
| STARTER Annual | `price_1SmO9tFC0QQLHISRZKmk6UMP` | EXISTE |
| PRO Monthly | `price_1SmO9uFC0QQLHISRwu8eFnyh` | EXISTE |
| PRO Annual | `price_1SmO9uFC0QQLHISRGoO27jUD` | EXISTE |
| AUTOPILOT Monthly | `price_1SmO9vFC0QQLHISRk0Pob4j9` | EXISTE |
| AUTOPILOT Annual | `price_1SmO9wFC0QQLHISRpDdOvrbY` | EXISTE |
| Channel Add-on Monthly | `price_1SmO9xFC0QQLHISR56XMUoRe` | EXISTE |
| Channel Add-on Annual | `price_1SmO9xFC0QQLHISRAiF5ynav` | EXISTE |
| KBActions Packs | **AUCUN Price ID** | prix dynamiques via `price_data` |
| ENTERPRISE | **AUCUN** | Sur devis (design) |

#### PROD (sk_live_)

| Objet | Price ID | Statut |
|-------|----------|--------|
| STARTER Monthly | `price_1SreqrFC0QQLHISRFea6HKbV` | EXISTE |
| STARTER Annual | `price_1SreqrFC0QQLHISRanCHlNHr` | EXISTE |
| PRO Monthly | `price_1SreqsFC0QQLHISRsNRFIMjr` | EXISTE |
| PRO Annual | `price_1SreqsFC0QQLHISRB1vgmBe6` | EXISTE |
| AUTOPILOT Monthly | `price_1SreqtFC0QQLHISRgKxY8ldF` | EXISTE |
| AUTOPILOT Annual | `price_1SreqtFC0QQLHISR1G9BhKZg` | EXISTE |
| Channel Add-on Monthly | `price_1SreqtFC0QQLHISRvTB3w1JX` | EXISTE |
| Channel Add-on Annual | `price_1SrequFC0QQLHISRDvm3ChUX` | EXISTE |
| Channel Add-on Product | `prod_TpJTEELacYjLGG` | EXISTE |
| KBActions Packs | **AUCUN Price ID** | prix dynamiques via `price_data` |
| ENTERPRISE | **AUCUN** | Sur devis |

### 6.2 Subscriptions reelles en DB

| Tenant | Plan | Stripe Sub ID | Cycle | Status |
|--------|------|---------------|-------|--------|
| `switaa-sasu-mn27vxee` | AUTOPILOT | `sub_1TDsjz...` | annual | **trialing** |
| `ecomlg-mmiyygfg` | PRO | `sub_1T8zyY...` | monthly | **active** |
| `ecomlg-mn3rj8mg` | AUTOPILOT | `sub_1TEH3y...` | annual | **trialing** |

### 6.3 Conclusions Stripe

- **Plans abonnement** : complets pour STARTER/PRO/AUTOPILOT (monthly + annual) en DEV et PROD
- **Channel add-ons** : complets (monthly + annual) en DEV et PROD
- **KBActions packs** : PAS de Product/Price Stripe dedies — utilise `price_data` dynamique (acceptable pour des achats one-time)
- **ENTERPRISE** : pas d'objet Stripe (sur devis — acceptable)
- **Webhook** : configure avec `STRIPE_WEBHOOK_SECRET` en DEV et PROD
- **Le flux Stripe fonctionne** : subscriptions creees et gerees (3 subscriptions actives)

---

## 7. Matrice business finale — Preparation Autopilot

| Element | STARTER | PRO | AUTOPILOT | ENTERPRISE |
|---------|---------|-----|-----------|------------|
| **IA incluse** | NON | OUI | OUI | OUI |
| **KBActions/mois** | 0 | 1000 | 2000 | 10000 |
| **Top-up KBActions** | OUI (autorise) | OUI | OUI | OUI |
| **Suggestions IA** | BLOQUE | OUI | OUI | OUI |
| **Supervision IA** | BLOQUE | OUI | OUI | OUI |
| **Mode suggestion** | BLOQUE | OUI | OUI | OUI |
| **Mode supervised** | BLOQUE | OUI | OUI | OUI |
| **Mode autonomous** | BLOQUE | BLOQUE | OUI | OUI |
| **Assignation manuelle** | OUI | OUI | OUI | OUI |
| **Assignation auto IA** | INEXISTANT | INEXISTANT | INEXISTANT | INEXISTANT |
| **Escalade SLA** | Basique (cron SQL) | Basique | Basique | Basique |
| **Destination escalade** | N/A | Client team (CIBLE, PAS IMPLEMENTE) | KeyBuzz + client (CIBLE, PAS IMPLEMENTE) | Custom (CIBLE, PAS IMPLEMENTE) |
| **Queue agent** | INEXISTANT | INEXISTANT | INEXISTANT | INEXISTANT |
| **Priorite** | INEXISTANT | INEXISTANT | INEXISTANT | INEXISTANT |
| **Actions auto autorisees** | Aucune | Aucune | Aucune (CIBLE : reply, assign, escalate, status) | Toutes |
| **Agents KeyBuzz** | N/A | N/A | INEXISTANT (prevu) | INEXISTANT |
| **Agents client** | 0 en DB (table vide) | 0 en DB | 0 en DB | 0 en DB |
| **Playbooks auto-execute** | NON | NON | NON (prevu) | NON |
| **Canaux inclus** | 1 | 3 | 5 | 999 |

---

## 8. Bloquants avant moteur Autopilot

### CRITIQUES (doivent etre resolus avant PH131 moteur)

| # | Bloquant | Description | Impact |
|---|----------|-------------|--------|
| B1 | **Aucun moteur d'execution** | Mode autonomous = label + gate, pas d'auto-reply, auto-assign, auto-escalate | Le produit "Autopilot" n'a aucune autonomie reelle |
| B2 | **BFF bloque KBActions en PROD** | `ai-actions-checkout/route.ts` retourne 403 en production | Les clients ne peuvent pas acheter de KBActions |
| B3 | **Table agents vide** | Aucun agent enregistre, teams = mock | Impossible d'escalader ou d'assigner |
| B4 | **Pas de setting escalation_target** | Colonne manquante dans `ai_settings` | Impossible de configurer la destination d'escalade |

### MAJEURS (doivent etre resolus pour un Autopilot fonctionnel)

| # | Bloquant | Description |
|---|----------|-------------|
| B5 | **Pas de allowed_auto_actions** | Aucune config pour definir quelles actions l'IA peut executer automatiquement |
| B6 | **Pas de confidence_threshold** | Aucun seuil de confiance pour decider quand agir automatiquement |
| B7 | **Pas d'agents KeyBuzz** | Pas de concept d'agent KeyBuzz en DB/API (seulement un type UI dans `roles.ts`) |
| B8 | **Pas de routage d'escalade** | SLA cron fait des transitions d'etat mais ne route vers personne |
| B9 | **Teams module = mock** | `GET /teams` retourne des donnees fictives, pas de CRUD reel |
| B10 | **Playbooks sans execution** | Playbooks = enrichissement prompt, pas de triggers/actions automatiques |

### MINEURS (peuvent attendre)

| # | Point | Description |
|---|-------|-------------|
| B11 | Dual wallet system | `ai_credits_wallet` (USD) coexiste avec `ai_actions_wallet` (KBA) — legacy |
| B12 | SLA state naming | `risk` vs `at_risk` inconsistance entre cron et code TypeScript |
| B13 | Packs UI vs BFF | Divergence packs affiches (50/200/500) vs BFF (50/150/500) et prix |
| B14 | Variance KBActions | ±15% variance sur le cout decontenant pour le client |

---

## 9. Scope recommande pour PH131 moteur

### Ce que PH131 moteur DEVRA faire (scope safe)

1. **Lever le blocage BFF KBActions en PROD** (B2) — correction mineure, impact business immediat
2. **Creer le module agents reel** (B3, B9) — remplacer le mock teams, permettre l'ajout d'agents au tenant
3. **Ajouter les colonnes settings Autopilot** (B4, B5) — `escalation_target`, `allowed_auto_actions`, `auto_reply_enabled`, `confidence_threshold`
4. **Implementer l'UI settings Autopilot** — ecran de configuration pour le client AUTOPILOT
5. **Poser les fondations du moteur** — structure du worker, sans execution reelle (dry-run docummente, logging complet)

### Ce que PH131 moteur NE DEVRA PAS faire

1. **Ne pas activer d'auto-reply reel** — trop risque sans validation extensive
2. **Ne pas creer d'agents KeyBuzz** — necessite une strategie operationnelle prealable
3. **Ne pas modifier le pricing Stripe** — stable et fonctionnel
4. **Ne pas toucher au systeme KBActions** (sauf le fix BFF) — fonctionne correctement
5. **Ne pas convertir les playbooks en execution auto** — necessite une phase dediee

### Ce qui doit etre traite AVANT PH131 moteur

| Action | Phase suggeree |
|--------|---------------|
| Fix BFF KBActions PROD | **PH131-FIX** (hotfix rapide) |
| Module agents + teams reel | **PH131-A** |
| Settings Autopilot DB + UI | **PH131-B** |

### Ce qui peut attendre PH132/PH133

| Action | Phase |
|--------|-------|
| Execution reelle auto-reply (premier cas simple) | PH132 |
| Agents KeyBuzz + routage inter-tenant | PH133 |
| Playbooks avec triggers auto | PH134 |
| Queue agent + priorisation avancee | PH135 |

---

## 10. Reponses explicites aux 4 questions critiques

### Q1 : Le mode AUTOPILOT est-il seulement gate, ou reellement motorise ?

**REPONSE : SEULEMENT GATE.**

Le mode `autonomous` est une valeur stockee dans `ai_settings.mode`. PH130 empeche les plans < AUTOPILOT de le selectionner. Mais aucun moteur n'execute d'actions automatiquement. Les moteurs PH105/106/108/113 sont tous documentes "DRY-RUN ONLY". L'UI a un bouton "Laisser KeyBuzz repondre" mais l'endpoint API ne fait pas d'envoi reel.

### Q2 : La logique d'escalade par plan est-elle complete et coherente ?

**REPONSE : NON, TRES INCOMPLETE.**

- `planCapabilities.ts` declare des `escalationTarget` — mais c'est purement declaratif
- La table `agents` est vide, le module `teams` est mock
- Le SLA cron fait des transitions d'etat mais ne route vers personne
- Il n'existe aucun mecanisme pour escalader vers l'equipe client ou vers KeyBuzz

### Q3 : Le systeme KBActions / wallet / top-up est-il reellement achetable et utilisable ?

**REPONSE : PARTIELLEMENT.**

- **Consommation** : FONCTIONNEL — les KBActions sont debitees lors des appels IA, avec idempotence
- **Wallet** : FONCTIONNEL — schema clean, reset mensuel correct, quotas par plan alignes
- **Achat ponctuel** : BLOQUE EN PROD — le BFF Next.js retourne 403 si `NEXT_PUBLIC_APP_ENV=production`
- **DEV** : fonctionne (stub sans Stripe, credit direct)

### Q4 : Stripe contient-il vraiment tout ce qui est necessaire ?

**REPONSE : OUI pour les abonnements, NON pour les packs KBActions.**

- Plans STARTER/PRO/AUTOPILOT : Price IDs existants en DEV et PROD (monthly + annual)
- Channel add-ons : existants
- KBActions packs : pas de Price ID Stripe (prix dynamiques via `price_data`) — acceptable pour du one-time
- Enterprise : pas d'objet Stripe (sur devis) — coherent avec la strategie

---

## Verdict Final

# AUTOPILOT SYSTEM INCOMPLETE — FIX REQUIRED BEFORE ENGINE

**Raisons :**

1. Le mode autonomous est GATE mais PAS MOTORISE — aucune execution automatique n'existe
2. L'achat KBActions est BLOQUE EN PRODUCTION (BFF retourne 403)
3. L'infrastructure d'escalade est INEXISTANTE (agents vides, teams mock, pas de routage)
4. Les settings Autopilot sont INCOMPLETS (pas de escalation_target, pas de allowed_auto_actions)

**Actions prioritaires avant moteur Autopilot :**

1. **HOTFIX** : lever le blocage BFF KBActions PROD
2. **PH131-A** : module agents + teams reel
3. **PH131-B** : settings Autopilot (DB + UI)
4. **PH131-C** : fondations moteur (dry-run, logging, structure worker)

Le systeme KBActions (wallet/ledger/debit) et Stripe (subscriptions/webhooks) sont fonctionnels et ne necessitent pas de correction.
