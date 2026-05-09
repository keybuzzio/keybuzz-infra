# PH-SAAS-T8.12AR.1 - Dashboard Performance SAV - Truth Audit & Design

> Date : 2026-05-09
> Phase : AR.1 - Audit verite + design fonctionnel
> Ticket Linear : KEY-282
> Environnement : PROD read-only + DEV/source audit
> Type : audit verite + design fonctionnel + specification metriques
> Verdict : **GO PARTIEL - INSTRUMENTATION REQUIRED**

---

## 0. PREFLIGHT

### Repositories

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-api | `ph147.4/source-of-truth` | `9521fb35` | Non | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `5e24487` | Non | OK |
| keybuzz-admin-v2 | `main` | `ad2bd4c` | Non | OK |
| keybuzz-infra | `main` | `1ef99f5` | Non | OK |

### Runtimes PROD

| Service | Image attendue | Runtime | Match |
|---------|---------------|---------|-------|
| API | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.147-auto-assignment-after-reply-prod` | OK |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | `v3.5.170-shopify-visible-disabled-channels-prod` | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | OK |
| Website | `v0.6.12-linkedin-insight-seo-prod` | `v0.6.12-linkedin-insight-seo-prod` | OK |
| Admin | `v2.12.2-media-buyer-lp-domain-qa-prod` | `v2.12.2-media-buyer-lp-domain-qa-prod` | OK |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | OK |

---

## 1. INVENTAIRE DES SURFACES DASHBOARD ACTUELLES

### Pages existantes

| Surface | Fichier/endpoint | Donnee actuelle | Reutilisable ? |
|---------|------------------|-----------------|----------------|
| Dashboard page | `app/dashboard/page.tsx` | Conversations, SLA, orders, messages, channels, activity | Partiellement |
| KpiCards | `features/dashboard/components/KpiCards.tsx` | Total convs, open, pending, SLA | Non (format different) |
| ChannelSplit | `features/dashboard/components/ChannelSplit.tsx` | Repartition par canal | Non |
| SlaPanel | `features/dashboard/components/SlaPanel.tsx` | SLA ok/at_risk/breached | Non |
| ActivityFeed | `features/dashboard/components/ActivityFeed.tsx` | 10 derniers evenements | Non |
| SupervisionPanel | `features/dashboard/components/SupervisionPanel.tsx` | Charge agents, FRT agent | Partiellement (FRT) |
| DashboardSkeleton | `features/dashboard/components/DashboardSkeleton.tsx` | Loading state | Reutilisable pattern |
| Demo mode | `features/demo/` | `useDemoMode` + `DemoDashboardPreview` | Reutilisable pattern |
| BFF summary | `app/api/dashboard/summary/route.ts` -> `/stats/overview` | Overview agrege | Non (pas de series) |
| BFF supervision | `app/api/dashboard/supervision/route.ts` -> `/dashboard/supervision` | Agents KPI | Partiellement |
| BFF stats | `app/api/stats/conversations/route.ts` -> `/stats/conversations` | Count statuts | Non |

### Donnees NON presentes dans le dashboard actuel

| Donnee | Existe en DB ? | Existe en API ? |
|--------|---------------|-----------------|
| Series temporelles (courbes) | Calculable | NON |
| Ventilation humain/IA | Partiellement (ai_action_log) | NON |
| Temps moyen de reponse global | Calculable (FRT) | Partiel (KPI agent only) |
| Satisfaction client | NON | NON |
| Jalons timeline | Partiellement deductible | NON |
| Taux automatisation | Calculable | NON |
| Gains avant/apres | Calculable si assez d'historique | NON |

### Conclusion etape 1

Le dashboard actuel est un tableau de bord operationnel (backlog, SLA, agents). Il ne contient aucune dimension "Performance SAV" ni "preuve de valeur". La page Performance SAV doit etre une nouvelle page avec de nouveaux endpoints.

---

## 2. INVENTAIRE DES TABLES ET CHAMPS DISPONIBLES

### Table `conversations` (source primaire)

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `id` | text | Comptage | HAUTE |
| `tenant_id` | text | Scope | HAUTE |
| `channel` | text | Ventilation canaux | HAUTE |
| `status` | text | open/pending/resolved | HAUTE |
| `created_at` | timestamptz | Serie temporelle | HAUTE |
| `first_response_at` | timestamptz | FRT | MOYENNE (31.6% renseigne) |
| `last_customer_message_at` | timestamptz | FRT alternative | BASSE (2.5% renseigne en PROD) |
| `last_agent_message_at` | timestamptz | Derniere reponse | MOYENNE (31.6% renseigne) |
| `sla_state` | text | SLA tracking | HAUTE |
| `escalation_status` | text | Escalations | HAUTE |
| `assigned_agent_id` | text | Attribution | HAUTE |

### Table `messages` (source primaire)

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `direction` | text | inbound/outbound/internal_note | HAUTE |
| `message_source` | text | HUMAN/SUPPLIER_INBOUND/SUPPLIER_CONTACT | HAUTE |
| `author_name` | text | Identification agent | HAUTE |
| `created_at` | timestamptz | Serie temporelle | HAUTE |
| `conversation_id` | text | Jointure | HAUTE |
| `tenant_id` | text | Scope | HAUTE |

**CONSTAT CRITIQUE** : `message_source` ne contient que `HUMAN`, `SUPPLIER_INBOUND`, `SUPPLIER_CONTACT` en PROD. Aucune valeur `AI_ASSISTED`, `AI_AUTOPILOT`, `AI_AGENT` n'est presente. La distinction humain/IA passe par correlation avec `ai_action_log`.

### Table `ai_action_log` (source IA)

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `action_type` | text | Type action IA | HAUTE |
| `status` | text | completed/skipped/flagged | HAUTE |
| `conversation_id` | text | Correlation messages | HAUTE |
| `validated_by` | text | Validation humaine | HAUTE |
| `confidence_score` | numeric | Qualite IA | MOYENNE |
| `blocked` | boolean | Actions bloquees | HAUTE |
| `created_at` | timestamptz | Serie temporelle | HAUTE |

**Valeurs `action_type` en PROD** :

| action_type | Count PROD | Description |
|-------------|-----------|-------------|
| `AI_DECISION_TRACE` | 48 | Trace decision IA |
| `AI_SUGGESTION_GENERATED` | 31 | Suggestion IA generee |
| `draft_applied` | 15 | Brouillon IA applique |
| `autopilot_escalate` | 13 (skipped) | Escalation autopilot tentee |
| `autopilot_reply` | 12 (skipped) | Reponse autopilot tentee |
| `AI_FALSE_PROMISE_DETECTED` | 11 | Fausse promesse detectee |
| `AI_AUTO_ESCALATED` | 7 | Auto-escalation IA |
| `draft_modified` | 5 | Brouillon IA modifie |
| `draft_dismissed` | 1 | Brouillon IA rejete |

### Table `ai_settings` (configuration)

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `mode` | text | supervised/autonomous | HAUTE |
| `ai_enabled` | boolean | IA activee | HAUTE |
| `kill_switch` | boolean | IA coupee urgence | HAUTE |

**CONSTAT** : Pas d'historique des changements. On sait l'etat actuel mais pas QUAND le mode a change.

### Table `billing_subscriptions`

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `plan` | varchar | Plan actif | HAUTE |
| `status` | varchar | Statut Stripe | HAUTE |
| `has_agent_keybuzz_addon` | boolean | Addon Agent KB | HAUTE |
| `current_period_start` | timestamptz | Debut periode | HAUTE |

### Table `billing_events`

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `event_type` | varchar | Changements plan | MOYENNE (parsing payload JSONB) |
| `payload` | jsonb | Detail Stripe | MOYENNE |
| `created_at` | timestamptz | Timestamp | HAUTE |

**Events en PROD** : 56 subscription.updated, 41 invoice.paid, 22 checkout.session.completed, 22 subscription.created, 19 subscription.deleted, 2 payment_failed

### Table `ai_actions_ledger`

| Champ | Type | KPI possible | Fiabilite |
|-------|------|--------------|-----------|
| `reason` | varchar | Type operation | HAUTE |
| `kb_actions` | numeric | KBActions consommes | HAUTE |
| `cost_usd` | numeric | Cout interne | NE PAS EXPOSER |
| `created_at` | timestamptz | Timestamp | HAUTE |

**Reasons PROD** : ai_generation (160), plan_change_trial (12), initial_grant (9), monthly_reset (8), subscription_canceled (3)

### Tables NON EXISTANTES (recherche effectuee)

| Table recherchee | Resultat |
|-----------------|----------|
| feedback | ABSENTE |
| satisfaction | ABSENTE |
| csat | ABSENTE |
| nps | ABSENTE |
| survey | ABSENTE |
| rating | ABSENTE |

### Autres tables utiles

| Table | Count PROD | Usage |
|-------|-----------|-------|
| `tenants` | 14 | created_at pour jalon creation |
| `inbound_connections` | 6 | createdAt pour jalon canal |
| `inbound_addresses` | 11 | Adresses inbound configurees |
| `outbound_deliveries` | 230 | 229 delivered, 1 failed |
| `message_events` | 1706 | status_change(704), reply(405), etc. |
| `conversation_events` | 0 | TABLE VIDE |
| `marketplace_connections` | 0 | TABLE VIDE (mais inbound_connections a des donnees) |
| `notifications` | - | Notifications systeme |

---

## 3. DEFINITION DES KPIS

### KPI 1 - Messages recus

| Attribut | Valeur |
|----------|--------|
| **Definition** | Messages clients entrants (inbound humains) |
| **Formule SQL** | `SELECT COUNT(*) FROM messages WHERE tenant_id = $1 AND direction = 'inbound' AND message_source = 'HUMAN' AND created_at BETWEEN $2 AND $3` |
| **Exclusions** | `SUPPLIER_INBOUND` (6 en PROD), `internal_note` |
| **Fiabilite** | HAUTE |
| **Calculable maintenant** | OUI |
| **PROD actuel** | 1192 messages inbound HUMAN |

**Serie mensuelle PROD** :

| Mois | Messages recus |
|------|---------------|
| 2026-01 | 169 |
| 2026-02 | 171 |
| 2026-03 | 399 |
| 2026-04 | 393 |
| 2026-05 (partiel) | 60 |

### KPI 2 - Reponses envoyees

| Attribut | Valeur |
|----------|--------|
| **Definition** | Messages sortants envoyes (outbound) |
| **Formule SQL** | `SELECT COUNT(*) FROM messages WHERE tenant_id = $1 AND direction = 'outbound' AND created_at BETWEEN $2 AND $3` |
| **Fiabilite totale** | HAUTE |
| **Fiabilite ventilation** | MOYENNE (necessite correlation) |
| **Calculable maintenant** | OUI (total), PARTIELLEMENT (ventilation) |
| **PROD actuel** | 454 outbound (444 HUMAN + 10 SUPPLIER_CONTACT) |

**Ventilation par type de reponse** :

| Type reponse | Source technique | Fiabilite | Count PROD |
|--------------|-----------------|-----------|------------|
| Humaine pure | `messages.direction='outbound' AND message_source='HUMAN'` MINUS correlees IA | MOYENNE | ~424 |
| IA assistee (draft utilise) | Correlation `ai_action_log.action_type IN ('draft_applied','draft_modified')` par conversation_id + fenetre temporelle | MOYENNE | ~20 |
| Autopilot | `ai_action_log.action_type='autopilot_reply' AND status='completed'` | HAUTE | 0 (tous skipped) |
| Agent KeyBuzz | Non instrumente | N/A | 0 |
| Fournisseur | `messages.message_source='SUPPLIER_CONTACT'` | HAUTE | 10 |

**GAP CRITIQUE** : La colonne `message_source` ne distingue pas les reponses humaines pures des reponses IA-assistees. Les deux sont marquees `HUMAN`. Pour une ventilation fiable a terme, il faudra soit :
- (A) Ajouter des valeurs `message_source` (`AI_ASSISTED`, `AI_AUTOPILOT`) a l'insertion
- (B) Continuer la correlation `messages` <-> `ai_action_log` (plus complexe mais fonctionne retroactivement)

**Recommandation** : Option (A) en instrumentation future + (B) pour donnees historiques.

**Serie mensuelle PROD** :

| Mois | Reponses envoyees |
|------|-------------------|
| 2026-01 | 163 |
| 2026-02 | 26 (16 HUMAN + 10 SUPPLIER) |
| 2026-03 | 100 |
| 2026-04 | 148 |
| 2026-05 (partiel) | 17 |

### KPI 3 - Temps moyen de reponse (FRT)

| Attribut | Valeur |
|----------|--------|
| **Definition** | Temps entre creation conversation et premiere reponse agent |
| **Formule SQL** | `SELECT AVG(EXTRACT(EPOCH FROM (first_response_at - created_at))) FROM conversations WHERE tenant_id = $1 AND first_response_at IS NOT NULL AND created_at BETWEEN $2 AND $3` |
| **Fiabilite** | MOYENNE |
| **Calculable maintenant** | OUI (avec limitations) |
| **PROD actuel** | 180/569 conversations avec FRT (31.6%) |

**Distribution FRT PROD** :

| Bucket | Count | % |
|--------|-------|---|
| < 1h | 34 | 18.9% |
| 1-4h | 24 | 13.3% |
| 4-24h | 74 | 41.1% |
| 24-48h | 24 | 13.3% |
| > 48h | 24 | 13.3% |

**Limitations documentees** :
1. **68.4% des conversations n'ont PAS de first_response_at** (389/569). Raisons probables : notifications Amazon auto-resolues, conversations fermees sans reponse.
2. **Business hours non supportees** : le FRT inclut nuits et weekends, gonflant artificiellement la moyenne.
3. **Recommandation metrique** : Afficher la MEDIANE plutot que la moyenne (moins sensible aux outliers). Calculer aussi le P90.
4. **Recommandation filtre** : Exclure les conversations sans reponse du calcul FRT (ne pas compter les "notification-only" comme des conversations non repondues).

**Detail conversations sans reponse (PROD)** :

| Statut | Avec reponse | Sans reponse |
|--------|-------------|-------------|
| resolved | 154 | 357 |
| open | 25 | 31 |
| pending | 1 | 1 |

Les 357 conversations resolues SANS reponse sont tres probablement des notifications Amazon auto-resolues.

### KPI 4 - Taux de satisfaction client

| Attribut | Valeur |
|----------|--------|
| **Source fiable** | **AUCUNE** |
| **Tables recherchees** | feedback, satisfaction, csat, nps, survey, rating |
| **Resultat** | Aucune table trouvee |
| **CSAT reel** | ABSENT |
| **Feedback post-resolution** | ABSENT |
| **Note client** | ABSENT |
| **Sentiment IA** | Non stocke (inference possible mais non fiable comme CSAT) |
| **Reviews marketplace** | Non importees |

**DECISION : NE PAS AFFICHER de taux de satisfaction.**

Afficher un placeholder "Bientot disponible" avec explication. Proposer instrumentation future (phase AR.5).

### KPI 5 - Automatisation / IA

| Metrique | Calcul possible ? | Source | Fiabilite | Count PROD |
|----------|-------------------|--------|-----------|------------|
| Suggestions IA generees | OUI | `ai_action_log WHERE action_type='AI_SUGGESTION_GENERATED'` | HAUTE | 31 |
| Brouillons IA appliques | OUI | `ai_action_log WHERE action_type='draft_applied'` | HAUTE | 15 |
| Brouillons IA modifies | OUI | `ai_action_log WHERE action_type='draft_modified'` | HAUTE | 5 |
| Brouillons IA rejetes | OUI | `ai_action_log WHERE action_type='draft_dismissed'` | HAUTE | 1 |
| Reponses autopilot | OUI | `ai_action_log WHERE action_type='autopilot_reply' AND status='completed'` | HAUTE | 0 |
| Auto-escalations | OUI | `ai_action_log WHERE action_type='AI_AUTO_ESCALATED'` | HAUTE | 7 |
| Fausses promesses | OUI | `ai_action_log WHERE action_type='AI_FALSE_PROMISE_DETECTED'` | HAUTE | 11 |
| Taux adoption brouillon | OUI | `(draft_applied + draft_modified) / AI_SUGGESTION_GENERATED` | HAUTE | 64.5% |
| Taux automatisation globale | OUI | `suggestions / inbound_messages` | HAUTE | 2.6% |

**Constat** : L'IA est activee en mode `supervised` avec `ai_enabled=true` pour 1 tenant PROD. L'autopilot est configure mais toutes les tentatives sont `skipped` (non actif en PROD). L'activite IA a demarre en mars 2026 (48 decision traces) puis s'est intensifiee en avril (22 suggestions, 15 drafts appliques).

**Evolution mensuelle IA PROD** :

| Mois | Suggestions | Drafts appliques | Drafts modifies | Autopilot | Auto-escalations |
|------|------------|-----------------|-----------------|-----------|-----------------|
| 2026-03 | 0 | 0 | 0 | 0 | 0 |
| 2026-04 | 22 | 15 | 3 | 0 (11 skipped) | 4 |
| 2026-05 (partiel) | 9 | 0 | 2 | 0 (1 skipped) | 3 |

---

## 4. JALONS TIMELINE

### Jalons detectables

| Jalon | Source actuelle | Fiable ? | Besoin instrumentation ? |
|-------|----------------|----------|--------------------------|
| Tenant cree | `tenants.created_at` | OUI | Non |
| Premier canal connecte | `inbound_connections.createdAt` | OUI (6 records) | Non |
| Premier message recu | `MIN(messages.created_at WHERE direction='inbound')` | OUI | Non |
| Premiere reponse envoyee | `MIN(messages.created_at WHERE direction='outbound')` | OUI | Non |
| Premiere suggestion IA | `MIN(ai_action_log.created_at WHERE action_type='AI_SUGGESTION_GENERATED')` | OUI | Non |
| Premier brouillon IA utilise | `MIN(ai_action_log.created_at WHERE action_type='draft_applied')` | OUI | Non |
| Premiere auto-escalation | `MIN(ai_action_log.created_at WHERE action_type='AI_AUTO_ESCALATED')` | OUI | Non |
| Premiere fausse promesse detectee | `MIN(ai_action_log.created_at WHERE action_type='AI_FALSE_PROMISE_DETECTED')` | OUI | Non |

### Jalons NON detectables (instrumentation requise)

| Jalon | Source manquante | Instrumentation proposee |
|-------|-----------------|--------------------------|
| IA activee (ai_enabled = true) | Pas d'historique dans `ai_settings` | Table `tenant_config_events` avec event_type + timestamp |
| Autopilot active (mode = autonomous) | Pas d'historique dans `ai_settings` | Idem |
| Agent KeyBuzz active | Pas de timestamp dans `billing_subscriptions` | Log dans `billing_events` ou table dediee |
| Changement de plan | `billing_events` existe mais parsing payload JSONB requis | API de parsing des events Stripe |
| Premiere reponse autopilot | 0 autopilot_reply completed en PROD | Automatique quand autopilot sera actif |

---

## 5. AUDIT DONNEES PROD (AGREGE, SANS PII)

### Vue globale

| Metrique | Valeur |
|----------|--------|
| Tenants total | 14 |
| Tenants avec conversations | 6 |
| Conversations total | 569 |
| Messages total | 1670 |
| Messages inbound HUMAN | 1192 |
| Messages outbound HUMAN | 444 |
| Messages outbound SUPPLIER_CONTACT | 10 |
| Messages internal_note | 18 |
| Messages supplier_inbound | 6 |
| AI action logs | 143 |
| Outbound deliveries | 230 (229 delivered, 1 failed) |
| Plage temporelle | 2026-01-08 -> 2026-05-09 (4 mois) |

### Croissance conversations

| Mois | Conversations creees |
|------|---------------------|
| 2026-01 | 59 |
| 2026-02 | 63 |
| 2026-03 | 179 |
| 2026-04 | 222 |
| 2026-05 (9 jours) | 46 |

**Tendance** : Croissance forte (+184% janv->mars, +24% mars->avril). Projection mai : ~153 si rythme constant.

### KPI calculabilite par tenant

| KPI | Tenants avec donnees | Tenants sans donnees | Risque |
|-----|---------------------|---------------------|--------|
| Messages recus | 6 | 8 | FAIBLE (tenants inactifs/demo) |
| Reponses envoyees | 4 | 10 | FAIBLE |
| FRT | 4 | 10 | MOYEN (nombreuses convs sans FRT) |
| Automation IA | 1 | 13 | MOYEN (1 seul tenant IA actif) |
| Satisfaction | 0 | 14 | CRITIQUE (source absente) |
| Jalons creation | 14 | 0 | FAIBLE |
| Jalons canal | 6 | 8 | FAIBLE |

### Verdicts sources

| Source | Rows PROD | Utilite dashboard | Verdict |
|--------|----------|-------------------|---------|
| `messages` | 1670 | CRITIQUE | UTILISABLE |
| `conversations` | 569 | CRITIQUE | UTILISABLE |
| `ai_action_log` | 143 | HAUTE | UTILISABLE |
| `message_events` | 1706 | MOYENNE | UTILISABLE (reply events) |
| `outbound_deliveries` | 230 | MOYENNE | UTILISABLE (deliverabilite) |
| `billing_events` | 162 | MOYENNE | UTILISABLE (jalons plan) |
| `ai_actions_ledger` | 192 | BASSE | UTILISABLE (conso KBA) |
| `conversation_events` | 0 | NULLE | INUTILISABLE (table vide) |
| `marketplace_connections` | 0 | NULLE | REMPLACEE par inbound_connections |
| Tables satisfaction | 0 | NULLE | ABSENTES |

---

## 6. DESIGN UX FONCTIONNEL

### Page proposee

- **Route** : `/performance` (nouvelle page dediee)
- **Titre** : "Performance SAV"
- **Sous-titre** : "Vos gains avec KeyBuzz"
- **Menu sidebar** : Nouvelle entree sous "Dashboard" avec icone TrendingUp

### Structure de la page

#### 6.1 - Barre de controle

| Element | Detail |
|---------|--------|
| Titre | "Performance SAV" |
| Selecteur periode | `7j` / `30j` / `90j` / `Tout` (defaut: 30j) |
| Refresh | Bouton rafraichissement |

#### 6.2 - Cartes KPI (en haut, rangee horizontale)

| Carte | Valeur | Sous-texte | Evolution | Etat vide |
|-------|--------|-----------|-----------|-----------|
| Messages recus | 393 | "ce mois" | +2% vs mois precedent | "En attente de messages" |
| Reponses envoyees | 148 | "ce mois" | +48% vs mois precedent | "En attente de reponses" |
| Temps de reponse | "8h15" | "mediane" | -12% vs mois precedent | "Minimum 5 reponses requises" |
| Taux IA | "64.5%" | "adoption brouillons IA" | N/A si < 5 suggestions | "IA non activee" |
| Satisfaction | "—" | "Bientot disponible" | grise, desactivee | Toujours cet etat tant qu'absent |

#### 6.3 - Courbe principale (centre)

| Element | Detail |
|---------|--------|
| Axe X | Jours (7j/30j) ou semaines (90j/tout) |
| Ligne 1 | Messages recus (bleu, #3B82F6) |
| Ligne 2 | Reponses envoyees (vert, #10B981) |
| Ligne 3 (optionnelle) | Temps moyen reponse (orange, #F59E0B, axe Y2) |
| Jalons | Points annotes verticaux sur la courbe |
| Tooltip | Date + valeurs + jalon si present |
| Animation | Apparition progressive gauche->droite |

#### 6.4 - Jalons sur la courbe

Chaque jalon apparait comme un marqueur vertical avec label :

| Jalon | Label | Icone |
|-------|-------|-------|
| Premier message | "Premier message" | MessageSquare |
| Premiere reponse | "Premiere reponse" | Send |
| IA activee | "IA activee" | Zap |
| Premier brouillon IA | "Premier brouillon IA utilise" | FileEdit |
| Autopilot | "Autopilot active" | Bot |
| Changement plan | "Plan Pro active" | CreditCard |

#### 6.5 - Panel IA (sous la courbe)

| Bloc | Donnee | Etat vide |
|------|--------|-----------|
| Suggestions generees | 31 | "0 suggestion IA" |
| Brouillons utilises | 15 (48.4% du total suggestions) | "0 brouillon" |
| Brouillons modifies | 5 (16.1%) | "-" |
| Brouillons rejetes | 1 (3.2%) | "-" |
| Taux adoption | 64.5% | "-" |
| Reponses autopilot | 0 (en attente activation) | "Autopilot non actif" |
| Auto-escalations IA | 7 | "0 escalation" |
| Fausses promesses detectees | 11 | "0 fausse promesse" |

#### 6.6 - Etats vides (par scenario)

| Scenario | Affichage |
|----------|-----------|
| Nouveau tenant, 0 canal | Illustration + "Connectez un canal pour suivre vos performances" + bouton Canaux |
| Canal connecte, 0 message | Illustration + "En attente de vos premiers messages clients" |
| < 5 reponses | Cartes KPI sans FRT + message "Repondez a 5 conversations pour debloquer le temps de reponse" |
| IA non activee | Panel IA grise + "Activez l'Aide IA dans Parametres pour debloquer les metriques IA" |
| Satisfaction | Toujours "Bientot disponible" avec icone verrou |
| Tenant demo (kbz-*) | Demo mode avec donnees d'illustration + banniere "Donnees de demonstration" |

#### 6.7 - Bloc "Gains" (optionnel, si assez d'historique)

Si le tenant a > 60 jours d'historique :

| Gain | Calcul | Affichage |
|------|--------|-----------|
| Evolution volume | Mois courant vs premier mois | "+184% de messages traites" |
| Evolution FRT | FRT mois courant vs FRT premier mois | "Temps de reponse reduit de 42h a 8h" |
| Volume IA | Total brouillons IA utilises | "20 reponses assistees par l'IA" |

Si < 60 jours : ne pas afficher ce bloc.

### Wireframe structurel

```
+-----------------------------------------------------------+
| Performance SAV                    [7j] [30j] [90j] [All] |
+-----------------------------------------------------------+
| [Messages] [Reponses] [Temps rep] [Taux IA] [Satisf.]    |
|   393        148        8h15       64.5%      —           |
|  +2%         +48%      -12%                 Bientot       |
+-----------------------------------------------------------+
|                                                           |
|  IA activee              Premier brouillon IA             |
|      v                        v                           |
|  ....                    ....                              |
|  -----.........---------.....-----                        |
|  Messages recus (bleu) / Reponses (vert)                  |
|                                                           |
|  Jan       Fev       Mar       Avr       Mai              |
+-----------------------------------------------------------+
| [Panel IA]                                                |
| Suggestions: 31  | Adoptes: 20 (64.5%)  | Autopilot: 0  |
| Escalations: 7   | Fausses promesses: 11                 |
+-----------------------------------------------------------+
```

---

## 7. API DESIGN

### Endpoint principal

| Attribut | Valeur |
|----------|--------|
| **Route** | `GET /stats/performance` |
| **Query params** | `tenantId` (requis), `range` (7d/30d/90d/all, defaut 30d) |
| **Auth** | `X-User-Email` + tenant guard |
| **BFF** | `GET /api/stats/performance` |
| **Cache** | 5 min recommande (Redis) |

### Schema de reponse

```json
{
  "tenantId": "xxx",
  "range": "30d",
  "periodStart": "2026-04-09T00:00:00Z",
  "periodEnd": "2026-05-09T00:00:00Z",
  
  "kpis": {
    "messagesReceived": 393,
    "messagesReceivedPrevious": 385,
    "messagesReceivedDelta": 0.02,
    
    "repliesSent": 148,
    "repliesSentPrevious": 100,
    "repliesSentDelta": 0.48,
    
    "avgResponseTimeSeconds": 29700,
    "medianResponseTimeSeconds": 21600,
    "avgResponseTimePrevious": 33840,
    "avgResponseTimeDelta": -0.12,
    
    "automationRate": 0.645,
    "automationRatePrevious": null,
    
    "satisfactionRate": null
  },
  
  "repliesBreakdown": {
    "humanPure": 128,
    "aiAssisted": 20,
    "autopilot": 0,
    "supplier": 10
  },
  
  "series": {
    "interval": "day",
    "points": [
      {
        "date": "2026-04-09",
        "messagesReceived": 15,
        "repliesSent": 5,
        "avgResponseTimeSeconds": 28800,
        "aiSuggestions": 1,
        "aiDraftsUsed": 0
      }
    ]
  },
  
  "milestones": [
    {
      "date": "2026-01-08T19:58:05Z",
      "type": "first_message",
      "label": "Premier message recu"
    },
    {
      "date": "2026-01-08T20:15:00Z",
      "type": "first_reply",
      "label": "Premiere reponse envoyee"
    },
    {
      "date": "2026-03-01T00:00:00Z",
      "type": "ai_first_suggestion",
      "label": "Premiere suggestion IA"
    },
    {
      "date": "2026-04-03T00:00:00Z",
      "type": "ai_first_draft_used",
      "label": "Premier brouillon IA utilise"
    }
  ],
  
  "aiMetrics": {
    "suggestionsGenerated": 31,
    "draftsApplied": 15,
    "draftsModified": 5,
    "draftsDismissed": 1,
    "adoptionRate": 0.645,
    "autopilotReplies": 0,
    "autoEscalations": 7,
    "falsePromisesDetected": 11
  }
}
```

### Requetes SQL principales

**KPI Messages recus** :
```sql
SELECT COUNT(*) as received
FROM messages
WHERE tenant_id = $1
  AND direction = 'inbound'
  AND message_source = 'HUMAN'
  AND created_at BETWEEN $2 AND $3
```

**KPI Reponses envoyees** :
```sql
SELECT COUNT(*) as sent
FROM messages
WHERE tenant_id = $1
  AND direction = 'outbound'
  AND created_at BETWEEN $2 AND $3
```

**Ventilation reponses (correlation IA)** :
```sql
WITH ai_assisted_convs AS (
  SELECT DISTINCT conversation_id
  FROM ai_action_log
  WHERE tenant_id = $1
    AND action_type IN ('draft_applied', 'draft_modified')
    AND status = 'completed'
    AND created_at BETWEEN $2 AND $3
)
SELECT
  COUNT(*) FILTER (WHERE m.message_source = 'SUPPLIER_CONTACT') as supplier,
  COUNT(*) FILTER (WHERE m.message_source = 'HUMAN' AND ac.conversation_id IS NOT NULL) as ai_assisted,
  COUNT(*) FILTER (WHERE m.message_source = 'HUMAN' AND ac.conversation_id IS NULL) as human_pure
FROM messages m
LEFT JOIN ai_assisted_convs ac ON m.conversation_id = ac.conversation_id
WHERE m.tenant_id = $1
  AND m.direction = 'outbound'
  AND m.created_at BETWEEN $2 AND $3
```

**FRT mediane** :
```sql
SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY EXTRACT(EPOCH FROM (first_response_at - created_at))
  ) as median_frt_seconds,
  AVG(EXTRACT(EPOCH FROM (first_response_at - created_at))) as avg_frt_seconds,
  COUNT(*) as sample_size
FROM conversations
WHERE tenant_id = $1
  AND first_response_at IS NOT NULL
  AND created_at BETWEEN $2 AND $3
```

**Serie temporelle** :
```sql
SELECT
  DATE_TRUNC('day', m.created_at) as date,
  COUNT(*) FILTER (WHERE m.direction = 'inbound' AND m.message_source = 'HUMAN') as messages_received,
  COUNT(*) FILTER (WHERE m.direction = 'outbound') as replies_sent
FROM messages m
WHERE m.tenant_id = $1
  AND m.created_at BETWEEN $2 AND $3
GROUP BY date
ORDER BY date
```

**Jalons** :
```sql
SELECT 'first_message' as type, MIN(created_at) as date FROM messages WHERE tenant_id = $1 AND direction = 'inbound'
UNION ALL
SELECT 'first_reply', MIN(created_at) FROM messages WHERE tenant_id = $1 AND direction = 'outbound'
UNION ALL
SELECT 'ai_first_suggestion', MIN(created_at) FROM ai_action_log WHERE tenant_id = $1 AND action_type = 'AI_SUGGESTION_GENERATED'
UNION ALL
SELECT 'ai_first_draft_used', MIN(created_at) FROM ai_action_log WHERE tenant_id = $1 AND action_type = 'draft_applied'
UNION ALL
SELECT 'first_channel', MIN("createdAt") FROM inbound_connections WHERE "tenantId" = $1
```

### Endpoints supplementaires

| Endpoint | Methode | Source | Risque | Phase |
|----------|---------|--------|--------|-------|
| `GET /stats/performance` | GET | messages + conversations + ai_action_log | Perf SQL (index requis) | AR.2 |
| `GET /stats/performance/milestones` | GET | messages + ai_action_log + inbound_connections | FAIBLE | AR.2 |
| `GET /stats/performance/ai` | GET | ai_action_log | FAIBLE | AR.2 |

L'endpoint unique `/stats/performance` est recommande pour limiter les appels reseau. Decomposer seulement si le payload devient trop lourd.

---

## 8. RISQUES ET STOP CONDITIONS

| Risque | Gravite | Mitigation |
|--------|---------|------------|
| **FRT biaise par conversations sans reponse** | HAUTE | Filtrer `first_response_at IS NOT NULL`. Documenter que seules les conversations repondues sont comptees. |
| **message_source ne distingue pas IA-assiste de humain** | HAUTE | Correlation `ai_action_log` par conversation_id. Instrumentation future `message_source` enrichi. |
| **Autopilot non actif en PROD** | MOYENNE | Afficher "0" avec label "En attente activation". Ne pas masquer la metrique. |
| **Satisfaction absente** | HAUTE | NE PAS afficher de faux CSAT. Placeholder "Bientot disponible". Phase AR.5 dediee. |
| **Historique court (4 mois)** | MOYENNE | Range "Tout" commence en jan 2026. Gains avant/apres desactives si < 60 jours. |
| **conversation_events vide** | BASSE | Ne pas utiliser. Se baser sur messages + message_events. |
| **Pas de timestamp activation IA** | MOYENNE | Deduire de `MIN(ai_action_log)`. Phase AR.6 pour table `tenant_config_events`. |
| **Performance SQL sur gros tenants** | MOYENNE | Index sur `(tenant_id, direction, created_at)` pour messages. Cache Redis 5 min. |
| **Cross-tenant risk** | HAUTE | `WHERE tenant_id = $1` OBLIGATOIRE sur TOUTES les requetes. Tenant guard existant reutilise. |
| **Donnees demo melangees** | MOYENNE | Exclure tenants `kbz-*` des metriques ou demo mode specifique. |
| **Metrique trompeuse (FRT incluant nuits)** | MOYENNE | Recommander mediane au lieu de moyenne. Documenter dans tooltip "inclut nuits/weekends". |
| **Correlation IA approximative** | MOYENNE | La correlation par conversation_id peut compter une reponse comme "IA-assistee" si un draft a ete genere meme si non utilise pour CETTE reponse. Fenetre temporelle necessaire. |

---

## 9. PLAN D'IMPLEMENTATION

### AR.2 - API metrics foundation DEV

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Endpoint `GET /stats/performance` read-only, tenant-scoped |
| **Env** | DEV uniquement |
| **Scope** | SQL + service + route + tests |
| **Inclus** | KPIs, series temporelles, milestones, AI metrics, breakdown reponses |
| **Exclu** | UI, satisfaction, business hours |
| **Risque** | FAIBLE (lecture seule, nouvelles routes) |
| **Effort estime** | 1-2 sessions |

### AR.3 - Dashboard Performance UI DEV

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Nouvelle page `/performance` avec cartes KPI, courbe, jalons, panel IA |
| **Env** | DEV uniquement |
| **Scope** | Page, composants, BFF route, demo mode |
| **Inclus** | Cartes KPI, courbe Recharts, jalons, panel IA, etats vides |
| **Exclu** | Satisfaction reelle, business hours |
| **Risque** | FAIBLE (nouvelle page, pas de modification existante) |
| **Effort estime** | 2-3 sessions |
| **Dependance** | AR.2 |

### AR.4 - PROD promotion

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Deployer API + Client en PROD |
| **Env** | PROD |
| **Scope** | Build, deploy, validation, GitOps |
| **Inclus** | Build images, deploy, validation metriques PROD |
| **Exclu** | Modifications post-deploy |
| **Risque** | MOYEN (nouveau code en PROD) |
| **Effort estime** | 1 session |
| **Dependance** | AR.3 |

### AR.5 - Satisfaction instrumentation (FUTUR)

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Table feedback, formulaire post-resolution, API CSAT |
| **Env** | DEV puis PROD |
| **Scope** | Migration DB, API, UI formulaire, integration dashboard |
| **Inclus** | Table `conversation_feedback`, formulaire email post-resolution, endpoint CSAT |
| **Exclu** | NPS, reviews marketplace |
| **Risque** | MOYEN (migration DB, email post-resolution) |
| **Effort estime** | 2-3 sessions |
| **Dependance** | AR.4 |

### AR.6 - Milestone tracking instrumentation (FUTUR)

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Table `tenant_config_events`, logging changements config IA/plan |
| **Env** | DEV puis PROD |
| **Scope** | Migration DB, hooks dans ai_settings + billing |
| **Inclus** | Table audit, triggers/hooks, API milestones enrichie |
| **Exclu** | UI |
| **Risque** | FAIBLE |
| **Effort estime** | 1 session |
| **Dependance** | AR.4 |

### AR.7 - message_source enrichi (FUTUR)

| Attribut | Valeur |
|----------|--------|
| **Objectif** | Ajouter `AI_ASSISTED`, `AI_AUTOPILOT` dans message_source a l'insertion |
| **Env** | DEV puis PROD |
| **Scope** | Modification reply handler + outbound worker |
| **Inclus** | Enrichissement message_source, retrocompatibilite |
| **Exclu** | Migration historique |
| **Risque** | MOYEN (modification du flow de reply) |
| **Effort estime** | 1 session |
| **Dependance** | AR.2 |

### Resume phases

| Phase | Objectif | Env | Risque |
|-------|----------|-----|--------|
| AR.2 | API metrics foundation | DEV | FAIBLE |
| AR.3 | Dashboard Performance UI | DEV | FAIBLE |
| AR.4 | PROD promotion | PROD | MOYEN |
| AR.5 | Satisfaction instrumentation | DEV->PROD | MOYEN |
| AR.6 | Milestone tracking | DEV->PROD | FAIBLE |
| AR.7 | message_source enrichi | DEV->PROD | MOYEN |

---

## 10. LINEAR

### KEY-282 - Mise a jour

- **Statut** : En cours (audit termine, design pret)
- **Resume audit** : Donnees messages/conversations/IA disponibles et fiables. Satisfaction ABSENTE. Autopilot non actif. FRT calculable avec limitations.
- **KPIs fiables** : Messages recus, reponses envoyees (total), automation IA (suggestions, drafts, escalations)
- **KPIs partiellement fiables** : FRT (31.6% des conversations), ventilation reponses humain/IA (correlation requise)
- **KPIs non fiables/absents** : Satisfaction client (aucune source), autopilot completions (0)
- **Decision satisfaction** : NE PAS AFFICHER. Placeholder "Bientot disponible". Phase AR.5 dediee.
- **Phases futures** : AR.2 (API), AR.3 (UI), AR.4 (PROD), AR.5 (satisfaction), AR.6 (milestones), AR.7 (message_source)

### Sous-tickets proposes

| Ticket | Titre | Parent |
|--------|-------|--------|
| KEY-xxx | AR.2 - API Performance SAV metrics foundation DEV | KEY-282 |
| KEY-xxx | AR.3 - Dashboard Performance SAV UI DEV | KEY-282 |
| KEY-xxx | AR.4 - Performance SAV PROD promotion | KEY-282 |
| KEY-xxx | AR.5 - Satisfaction client instrumentation | KEY-282 |
| KEY-xxx | AR.6 - Milestone tracking instrumentation | KEY-282 |
| KEY-xxx | AR.7 - message_source enrichi (IA ventilation) | KEY-282 |

---

## 11. CONFIRMATIONS

| Verification | Resultat |
|-------------|----------|
| Code modifie | **0 fichier** |
| Build execute | **0 build** |
| Deploy execute | **0 deploy** |
| Mutation DB | **0 mutation** |
| Migration | **0 migration** |
| Seed | **0 seed** |
| Faux KPI | **0 faux KPI** |
| Faux CSAT | **0 faux CSAT** |
| Donnee fictive injectee | **0** |
| Modification tracking | **0** |
| Modification billing | **0** |
| PII dans le rapport | **0** |

---

## VERDICT

### **GO PARTIEL - INSTRUMENTATION REQUIRED**

Les donnees actuelles permettent de construire un dashboard honnete pour :
- Messages recus (HAUTE fiabilite)
- Reponses envoyees avec ventilation partielle humain/IA (MOYENNE fiabilite)
- Temps moyen de reponse / mediane (MOYENNE fiabilite, 31.6% des conversations)
- Metriques IA / automatisation (HAUTE fiabilite)
- Jalons detectables (6 sur 10)

Instrumentation requise pour :
- **Satisfaction client** (ABSENTE - aucune source)
- **Jalons IA/autopilot activation** (pas d'historique de changement de config)
- **Ventilation message_source enrichie** (message_source = HUMAN pour toutes les reponses)

### Phrase cible

**DASHBOARD PERFORMANCE SAV TRUTH ESTABLISHED - MESSAGES RECEIVED / REPLIES SENT / RESPONSE TIME / AUTOMATION MILESTONES / SATISFACTION SOURCE AUDITED (ABSENT) - KPI DEFINITIONS READY - UX CURVE DESIGN READY - NO FAKE METRICS - NO CODE - NO BUILD - NO DEPLOY - NO MUTATION - IMPLEMENTATION PHASES AR.2-AR.7 DEFINED - GO PARTIEL INSTRUMENTATION REQUIRED**
