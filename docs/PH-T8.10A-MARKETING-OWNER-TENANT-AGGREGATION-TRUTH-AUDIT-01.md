# PH-T8.10A-MARKETING-OWNER-TENANT-AGGREGATION-TRUTH-AUDIT-01 — TERMINÉ

**Date** : 2026-05-01
**Type** : Audit vérité architecture — agrégation marketing par tenant owner
**Environnement** : DEV + PROD (lecture seule)
**Verdict** : **PARTIEL — le socle existe, mais il manque la couche d'agrégation owner**

---

## Objectif

Établir la vérité exacte sur la capacité actuelle de KeyBuzz à supporter un modèle **marketing owner tenant** : un tenant unique portant la lecture agrégée de tout le marketing KeyBuzz (spend, KPIs, funnels, conversions, signups, activation, CAC, ROAS, MRR), permettant à une agence / media buyer de piloter le marketing depuis ce seul tenant.

---

## Préflight

| Élément | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `c0b0f195` (PH-T8.9J) |
| Repo status | Clean |
| API DEV | `v3.5.111-activation-completed-model-dev` |
| API PROD | `v3.5.111-activation-completed-model-prod` |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| Modifications effectuées | **Aucune** |

---

## ÉTAPE 1 — Définition des concepts

| Concept | Définition actuelle | Source de vérité actuelle |
|---|---|---|
| **Tenant client runtime** | Le tenant SaaS créé par un utilisateur via `/register` → création `tenants` + `user_tenants` + `billing_subscriptions`. Porte ses propres données opérationnelles (inbox, commandes, conversations). | Table `tenants`, `billing_subscriptions`, `signup_attribution` |
| **Tenant marketing owner** | **N'existe pas formellement.** Aujourd'hui, `keybuzz-consulting-mo9zndlk` est utilisé *de facto* comme porteur du spend ads et des destinations outbound. Mais aucune entité canonique ne le désigne comme "owner marketing" des autres tenants. | `ad_platform_accounts`, `ad_spend_tenant`, `outbound_conversion_destinations` — rattachés à KBC par convention, pas par modèle |
| **Agence opératrice** | **Partiellement modélisée.** L'Admin V2 a un RBAC avec rôles `super_admin`, `account_manager`, `media_buyer`. Le proxy marketing (`proxy.ts`) vérifie `MARKETING_ROLES`. Mais il n'y a pas de mécanisme d'assignation "cette agence ne voit que ce tenant marketing". | Admin `requireMarketing()` dans `proxy.ts`, rôles session NextAuth |

---

## ÉTAPE 2 — Identification du tenant owner cible

| Champ | Valeur |
|---|---|
| `tenant_id` cible PROD | `keybuzz-consulting-mo9zndlk` |
| Nom | KeyBuzz Consulting |
| Créé le | 2026-04-22 |
| Status | active |
| Raison métier | Unique tenant portant les comptes Meta Ads et destinations CAPI |
| Déjà utilisé pour spend ads ? | **OUI** — 16 rows `ad_spend_tenant`, 445.20 GBP (mars 2026) |
| Déjà utilisé pour outbound ? | **OUI** — destination Meta CAPI active (pixel `1234164602194748`) |
| Déjà utilisé par l'agence ? | **NON** — pas d'utilisateur agence assigné, pas de RBAC "agence = KBC only" |
| `tenant_id` cible DEV | `keybuzz-consulting-mo9y479d` |
| DEV spend | 16 rows `ad_spend_tenant`, 445.20 GBP (miroir) |

### Ambiguïté constatée

KBC est le seul tenant avec des comptes ads et des destinations CAPI, donc il joue *de facto* le rôle de tenant marketing owner. Mais :
- **Aucun marqueur `is_marketing_owner`** n'existe en DB
- **Aucune table de mapping** ne relie KBC aux tenants clients qu'il "possède" marketing-wise
- Les métriques `/metrics/overview` en mode global ne filtrent pas "agrégé pour le owner" — elles montrent TOUT (pas tenant-scoped)
- En mode tenant-scoped (`?tenant_id=KBC`), seuls les signups/trials/purchases **de KBC lui-même** apparaissent — pas ceux des autres tenants

---

## ÉTAPE 3 — Audit du modèle actuel par brique

### A. Spend / ad accounts

| Élément | État actuel |
|---|---|
| `ad_platform_accounts` | 1 compte Meta, tenant=KBC, acct=`1485150039295668`, status=active, last_sync=23 avril |
| `ad_spend_tenant` | 16 rows, tenant=KBC, mars 2026, total 445.20 GBP |
| `/metrics/overview` scope | **Dual** : global = table `ad_spend` legacy ; tenant-scoped = `ad_spend_tenant WHERE tenant_id = $1` |
| Owner-compatible ? | **OUI pour le spend** — le spend est déjà sur KBC. Le problème est que les **signups/trials/MRR** ne sont PAS agrégés vers KBC. |

### B. Attributions et signup

| Élément | État actuel |
|---|---|
| `signup_attribution` PROD | 4 rows — aucune pour KBC |
| Relation attribution → tenant | Chaque attribution est liée à **son propre tenant_id** (celui créé par le signup) |
| Owner mapping | **ABSENT** — aucune colonne `marketing_owner_tenant_id` dans `signup_attribution` |
| Conséquence | Quand un user arrive via une pub KeyBuzz, crée un compte `tenant-xyz`, l'attribution est sur `tenant-xyz`, pas rattachable à KBC |

### C. Funnel

| Élément | État actuel |
|---|---|
| `funnel_events` PROD | 5 rows (tenant `test-prod-w3lg-mocmec72`) |
| Cohort stitching | Fonctionne via `funnel_id` → résolution `tenant_id` |
| Owner mapping | **ABSENT** — le funnel est scopé au tenant qui a été créé, pas à un owner |
| GET `/funnel/metrics?tenant_id=KBC` | Retourne cohort=0, steps=0 — normal, KBC n'a pas traversé le flow `/register` |
| Conséquence | Pour voir le funnel d'un signup arrivé via pub KeyBuzz, il faut connaître le `tenant_id` de ce signup spécifique |

### D. Business conversions

| Élément | État actuel |
|---|---|
| `conversion_events` PROD | 0 rows |
| `outbound_conversion_destinations` | 1 destination Meta CAPI sur KBC |
| `outbound_conversion_delivery_logs` | 4 logs (PageView) — pas de colonne `tenant_id` dans cette table |
| `emitOutboundConversion` | Appelé dans `billing/routes.ts` pour `StartTrial` et `Purchase` |
| Destination lookup | `WHERE tenant_id = $1 AND is_active = true` — cherche les destinations **du tenant qui a fait le trial/purchase** |
| Owner mapping | **PROBLÈME CRITIQUE** — les destinations sont sur KBC, mais le trigger se fait avec le `tenant_id` du client. Si `tenant-xyz` fait un StartTrial, le système cherche les destinations de `tenant-xyz` (0 résultat), PAS celles de KBC. |

### E. Metrics business

| Élément | État actuel |
|---|---|
| `billing_subscriptions` PROD | 11 rows (2 active, 6 trialing, 1 canceled, 2 pending_payment) |
| `billing_events.tenant_id` | **TOUJOURS NULL** — 130 events sans tenant_id |
| `tenant_billing_exempt` | 15 tenants marqués exempt (13 test + KBC + ecomlg-001) |
| `/metrics/overview` mode global | Agrège TOUS les tenants non-exemptés — signups, trials, paid, MRR, CAC, ROAS |
| `/metrics/overview?tenant_id=KBC` | Ne montre que les signups/subscriptions **de KBC lui-même** (= 0 signups réels car KBC est exempt) |
| MRR | Calculé depuis `billing_subscriptions WHERE status='active' AND NOT exempt` |
| CAC | `total_spend / signups` — en mode global OK, en mode tenant = spend KBC / signups KBC (= N/A) |

### Tableau synthèse

| Brique | Scope actuel | Owner-compatible aujourd'hui ? | Gap exact |
|---|---|---|---|
| Spend ads | Tenant-scoped (KBC) | **OUI** | Aucun |
| Signups | Tenant-scoped (tenant créé) | **NON** | Pas de mapping owner → signups |
| Trials | Tenant-scoped (tenant créé) | **NON** | Pas de mapping owner → trials |
| Purchases | Tenant-scoped (tenant créé) | **NON** | Pas de mapping owner → purchases |
| Funnel | Tenant-scoped (tenant créé) | **NON** | Pas de mapping owner → funnels |
| Activation | Tenant-scoped (tenant créé) | **NON** | Pas de mapping owner → activation |
| Outbound CAPI | Destinations sur KBC | **NON** | Lookup destinations par tenant créé, pas owner |
| CAC | Global ou tenant-scoped | **NON** | CAC owner = spend KBC / signups agrégés — pas implémenté |
| ROAS | Global ou tenant-scoped | **NON** | MRR owner non calculable |
| MRR | Global ou tenant-scoped | **NON** | Pas de relation owner → subscriptions |

---

## ÉTAPE 4 — Question centrale : owner tenant possible ou non ?

**Aujourd'hui, un tenant marketing owner unique peut-il piloter TOUT le marketing KeyBuzz sans ouvrir les tenants clients individuellement ?**

| Domaine | Oui / Non / Partiel | Pourquoi |
|---|---|---|
| Spend ads | **OUI** | Le spend est déjà sur KBC via `ad_spend_tenant` + `ad_platform_accounts` |
| Signups | **NON** | `signup_attribution` est scopée au tenant créé, pas à un owner |
| Trials | **NON** | `billing_subscriptions` est scopée au tenant créé |
| Purchases | **NON** | Idem + `emitOutboundConversion` cherche les destinations du tenant créé |
| Funnel onboarding | **NON** | `funnel_events` scopée au `funnel_id` / `tenant_id` créé |
| Activation | **NON** | `emitActivationEvent` lie les events au tenant créé |
| CAC / ROAS | **PARTIEL** | Mode global existe mais inclut les comptes de test — pas de vue "owner aggregated" |
| MRR | **PARTIEL** | Mode global existe mais pas de vue "owner → ses clients" |
| Delivery / outbound logs | **NON** | Destination lookup par tenant créé — KBC non trouvé |
| Accès agence via Admin | **PARTIEL** | Rôle `media_buyer` existe mais aucune restriction par tenant |

---

## ÉTAPE 5 — Contrat d'intégration agence / LP / funnels

### Pour une agence branchant une LP/funnel externe

| Élément d'intégration | Déjà défini ? | Suffisant pour agence ? | Gap |
|---|---|---|---|
| UTM forwarding (`utm_*`) | **OUI** — doc `MEDIA-BUYER-UTM-TRACKING.md` | **OUI** si LP pointe vers `client.keybuzz.io/register?utm_*` | Aucun gap UTM |
| `fbclid` / `fbc` / `fbp` forwarding | **OUI** — `signup_attribution` capture ces champs | **OUI** pour le tracking cookie | Aucun gap |
| `gclid` forwarding | **OUI** — champ dans `signup_attribution` | **OUI** | Aucun gap |
| `ttclid` forwarding | **OUI** — champ ajouté dans `signup_attribution` | **OUI** | Aucun gap |
| `plan` / `cycle` forwarding | **OUI** — query params `/register?plan=pro&cycle=monthly` | **OUI** | Aucun gap |
| Cross-domain GA4 (`_gl` linker) | **OUI** — `gl_linker` dans `signup_attribution` | **Partiel** — ne fonctionne que si le domaine d'arrivée a le même GA4 property | Gap si LP externe ≠ keybuzz.pro |
| Attribution owner mapping | **NON** | **NON** | **Gap critique** : l'attribution atterrit sur le tenant créé, pas sur un owner marketing |
| Server-side conversions vers owner | **NON** | **NON** | **Gap critique** : StartTrial/Purchase cherchent les destinations du tenant créé |
| Webhook LP externe → KeyBuzz | **NON** | **NON** | Pas de collecteur d'events externe |
| Funnel events depuis LP externe | **NON** | **NON** | `POST /funnel/event` accepte des events mais sans concept de "LP source" externe |

### Conclusion contrat agence

Le contrat UTM/click-ID est **complet et suffisant** pour le tracking client-side et l'attribution au signup.

Le contrat **manque** :
1. **Owner mapping rule** : comment rattacher un signup/trial/purchase au tenant marketing owner
2. **Outbound routing rule** : comment router les conversions server-side vers les destinations de l'owner (pas du tenant créé)
3. **Collecteur LP externe** : comment une LP externe peut pousser des events funnel vers KeyBuzz

---

## ÉTAPE 6 — Admin / RBAC / Agence

| Sujet | Déjà prêt ? | Limite actuelle |
|---|---|---|
| Accès agence | **PARTIEL** — rôle `media_buyer` existe dans `requireMarketing()` | Pas de restriction "ce media_buyer ne voit que le tenant KBC" |
| Tenant assignment | **NON** | Pas de mapping "user X → marketing owner tenant Y" |
| Spend | **OUI** — page `/marketing/ad-accounts`, proxy tenant-scoped | Fonctionne déjà pour KBC |
| Funnel | **OUI** — page `/marketing/funnel`, proxy tenant-scoped | Montre le funnel du tenant sélectionné (pas d'agrégation owner) |
| Conversions | **OUI** — page `/marketing/destinations` + `/marketing/delivery-logs` | Destinations sur KBC, mais pas de logs car les events sont émis par les tenants créés |
| Metrics owner-scoped | **NON** | `/metrics/overview` en mode global montre tout ; en mode tenant montre seulement le tenant lui-même |
| Autonomie LP/funnels | **NON** | Pas d'UI pour brancher une LP externe, pas de collecteur |

### RBAC Admin V2 — détail

| Composant | État |
|---|---|
| `proxy.ts` → `requireMarketing()` | Vérifie `['super_admin', 'account_manager', 'media_buyer']` — **pas de filtre tenant** |
| `proxyGet()` / `proxyMutate()` | Forward `x-tenant-id` — le tenant est choisi **côté UI** (sélecteur Admin), pas contraint par RBAC |
| Résultat | Un `media_buyer` peut aujourd'hui sélectionner **n'importe quel tenant** dans l'Admin — aucune isolation |

---

## ÉTAPE 7 — Modèle cible recommandé

| Modèle | Description | Avantages | Risques | Verdict |
|---|---|---|---|---|
| **A — Tout sur tenant créé** | Chaque tenant voit uniquement ses propres données. L'agence doit ouvrir chaque tenant individuellement. | Simple, déjà fonctionnel | Inutilisable pour le pilotage global marketing | **REJETÉ** |
| **B — Double lecture** | Conserver le tenant client runtime + ajouter un axe `marketing_owner_tenant_id` pour agrégation. L'API peut répondre en mode tenant-scoped OU en mode owner-aggregated. | Conserve l'existant, ajoute la vue agrégée, pas destructeur | Requiert un mapping owner explicite, requiert une couche d'agrégation API | **RECOMMANDÉ** |
| **C — Tout sur owner** | Basculer toutes les données marketing sur le tenant owner. Les tenants clients n'ont plus de données marketing propres. | Vue unique pour l'agence | Casse le modèle tenant-scoped existant, impossible de distinguer les canaux par client | **REJETÉ** |

### Verdict : **Modèle B — Double lecture**

Le modèle B est le seul qui :
1. **Conserve** la vue tenant-client existante (opérations SaaS intactes)
2. **Ajoute** la vue owner-aggregated pour le pilotage marketing global
3. **Permet** à l'agence de travailler depuis un seul tenant
4. **Permet** d'évoluer vers plusieurs marketing owners si besoin (multi-marque, etc.)

---

## ÉTAPE 8 — Entité canonique à introduire

### Nom recommandé

| Option | Avantages | Risques | Verdict |
|---|---|---|---|
| `marketing_owner_tenant_id` | Explicite, univoque | Un peu long | **RECOMMANDÉ** |
| `acquisition_owner_tenant_id` | Précis pour l'acquisition | Trop restrictif (exclut spend, LP, CRM) | Rejeté |
| `owner_tenant_id` | Court | Ambigu (owner de quoi ?) | Rejeté |

### Où la porter

| Option | Où | Avantages | Risques | Verdict |
|---|---|---|---|---|
| Colonne `marketing_owner_tenant_id` dans `tenants` | Table `tenants` | Source de vérité unique, jointure simple | Migration additive facile | **RECOMMANDÉ** |
| Table de mapping dédiée `marketing_tenant_ownership` | Table séparée | Flexible (N:N possible) | Jointure supplémentaire, complexité | Alternative acceptable |
| Colonne dans `signup_attribution` | Table `signup_attribution` | Proche de l'attribution | Ne couvre pas les tenants sans attribution | Insuffisant |
| Colonne dans `funnel_events` | Table `funnel_events` | Proche du funnel | Ne couvre pas les conversions | Insuffisant |

### Recommandation

**Colonne `marketing_owner_tenant_id` dans la table `tenants`** — nullable, FK vers `tenants(id)`.

```sql
-- Migration recommandée (future phase)
ALTER TABLE tenants ADD COLUMN marketing_owner_tenant_id TEXT
  REFERENCES tenants(id) ON DELETE SET NULL;
CREATE INDEX idx_tenants_marketing_owner ON tenants(marketing_owner_tenant_id);
```

Quand un tenant client est créé, il reçoit automatiquement `marketing_owner_tenant_id = 'keybuzz-consulting-mo9zndlk'` (ou le owner du moment).

L'API `/metrics/overview` en mode owner-scoped fait alors :

```sql
WHERE t.marketing_owner_tenant_id = $1 OR t.id = $1
```

Au lieu de `WHERE t.id = $1`.

---

## ÉTAPE 9 — Plan de phases recommandé

| Phase | Titre | Scope | Dépendances | Pré-requis |
|---|---|---|---|---|
| **T8.10B** | Owner mapping foundation — API/DB | SaaS/API | Aucune | Audit présent |
| | Migration additive `marketing_owner_tenant_id` sur `tenants` | | | |
| | Auto-assign owner au create-signup | | | |
| | API `GET /tenants/:id/marketing-children` | | | |
| **T8.10C** | Owner-scoped metrics aggregation | SaaS/API | T8.10B | |
| | `/metrics/overview?owner_tenant_id=X` → agrège signups/trials/MRR/CAC/ROAS | | | |
| | Conserver le mode `?tenant_id=X` existant intact | | | |
| **T8.10D** | Owner-scoped funnel + activation aggregation | SaaS/API | T8.10B | |
| | `/funnel/metrics?owner_tenant_id=X` → agrège tous les funnels des children | | | |
| | Cohort stitching multi-tenant | | | |
| **T8.10E** | Outbound routing owner-aware | SaaS/API | T8.10B | |
| | `emitOutboundConversion` cherche d'abord les destinations du tenant, puis celles du owner | | | |
| | Résout le **problème critique** : StartTrial/Purchase de `tenant-xyz` routés vers les destinations de KBC | | | |
| **T8.10F** | Admin owner cockpit + agency RBAC | Admin V2 | T8.10C, T8.10D | |
| | Page `/marketing/owner-dashboard` avec vue agrégée | | | |
| | RBAC : un `media_buyer` est assigné à un owner tenant → ne voit que les données de cet owner | | | |
| **T8.10G** | LP / external funnel tracking contract | SaaS/API + Doc | T8.10B | |
| | Collecteur d'events LP externes `POST /funnel/event` avec owner routing | | | |
| | Documentation contrat agence LP/funnel | | | |
| **T8.10H** | TikTok / Google / LinkedIn owner-scoped extension | SaaS/API | T8.10E | |
| | Adapters outbound pour TikTok Events API, Google Offline Conversions, LinkedIn CAPI | | | |

### Priorité d'implémentation

```
T8.10B (foundation)     → Doit être fait en premier
T8.10E (outbound fix)   → Critique : les conversions ne routent pas correctement
T8.10C (metrics agg)    → La vue agence
T8.10D (funnel agg)     → Secondaire tant que peu de funnels réels
T8.10F (Admin cockpit)  → Quand T8.10C+D sont prêts
T8.10G (LP contract)    → Quand les LP externes sont planifiées
T8.10H (multi-platform) → Dernier
```

---

## ÉTAPE 10 — Conclusion actionnable

### Le besoin "agence autonome sur le tenant KeyBuzz uniquement" est-il déjà satisfait ?

**NON — il manque le cœur du modèle.**

### À combien de distance est-on ?

**2 phases critiques** (T8.10B + T8.10E) pour le minimum viable :
- T8.10B : mapping owner → 1 migration + 1 helper API — estimé **demi-journée**
- T8.10E : outbound routing owner-aware — estimé **demi-journée**

Avec T8.10C en plus pour la vue métriques agrégée : **1 jour total**.

### Le plus petit prochain chantier utile ?

**T8.10B — Owner mapping foundation API/DB** :
1. Ajouter `marketing_owner_tenant_id` à `tenants`
2. Peupler pour les tenants existants
3. Auto-assign au `create-signup`
4. Endpoint lecture `GET /tenants/:id/marketing-children`

### Le trou funnel individuel est-il bloquant ?

**NON — il est secondaire pour ce besoin précis.**

Le trou funnel découvert en PH-T8.9M (0 events funnel en PROD car aucun signup post-déploiement) est un fait normal et non un bug. Pour le besoin owner tenant :
- Le funnel sera capturé automatiquement dès le premier vrai signup via `/register`
- L'agrégation owner (T8.10D) viendra après et lira ces events
- Le trou n'empêche pas la mise en place du mapping owner (T8.10B) ni du fix outbound (T8.10E)

Le vrai **problème bloquant** est le **routage outbound** (T8.10E) : aujourd'hui, quand `tenant-xyz` fait un StartTrial, le système cherche les destinations de `tenant-xyz` (0 résultat) au lieu de celles de KBC. Les conversions server-side ne partent donc **jamais** vers Meta CAPI pour les vrais clients.

---

## Données brutes collectées

### PROD tenants (16)

| Tenant | Nom | Status | Créé | Exempt | Subscription |
|---|---|---|---|---|---|
| ecomlg-001 | eComLG | active | 2026-02-06 | internal_admin | — |
| ecomlg-mn3rdmf6 | eComLG | active | 2026-03-23 | test_account | trialing AUTOPILOT |
| ecomlg-mn3roi1v | eComLG | pending_payment | 2026-03-23 | test_account | — |
| romruais-gmail-com-mn7mc6xl | romruais@gmail.com | active | 2026-03-26 | test_account | canceled AUTOPILOT |
| switaa-sasu-mn9c3eza | SWITAA SASU | active | 2026-03-27 | test_account | active AUTOPILOT |
| switaa-sasu-mnc1ouqu | SWITAA SASU | active | 2026-03-29 | test_account | active AUTOPILOT |
| compta-ecomlg-gmail--mnvu4649 | compta.ecomlg@gmail.com | active | 2026-04-12 | test_account | trialing AUTOPILOT |
| test-mnyycio7 | test | pending_payment | 2026-04-14 | test_account | — |
| ecomlg-mo45atga | eComLG | active | 2026-04-18 | test_account | trialing PRO |
| ecomlg-mo4h93e7 | eComLG | active | 2026-04-18 | test_account | trialing PRO |
| tiktok-prod-test-sas-mo5jsh7z | TikTok PROD Test SAS | pending_payment | 2026-04-19 | test_account | — |
| tiktok-prod-v2-sas-mo5k10ku | TikTok PROD V2 SAS | active | 2026-04-19 | test_account | trialing PRO |
| ludo-gonthier-ga4mpf-mo5ldw59 | ludo.gonthier+GA4MPFinal | active | 2026-04-19 | test_account | trialing PRO |
| ecomlg07-mo957dzr | ecomlg07 | active | 2026-04-21 | test_account | trialing PRO |
| **keybuzz-consulting-mo9zndlk** | **KeyBuzz Consulting** | **active** | **2026-04-22** | **internal_admin** | — |
| test-prod-w3lg-mocmec72 | Test PROD - W3LG | active | 2026-04-24 | — | trialing PRO |

### PROD schemas marketing

```
ad_platform_accounts: id, tenant_id, platform, account_id, account_name, currency, timezone, token_ref, status, last_sync_at, last_error, created_by, created_at, updated_at, deleted_at
ad_spend_tenant: id, tenant_id, account_id, platform, campaign_id, campaign_name, adset_id, adset_name, date, spend, spend_currency, impressions, clicks, conversions, created_at
signup_attribution: id, tenant_id, user_email, utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid, fbc, fbp, gl_linker, plan, cycle, landing_url, referrer, attribution_id, stripe_session_id, conversion_sent_at, created_at, ttclid
funnel_events: id, funnel_id, event_name, source, tenant_id, attribution_id, plan, cycle, properties, created_at
conversion_events: id, event_id, tenant_id, event_name, payload, status, attempts, last_attempt_at, created_at
outbound_conversion_destinations: id, tenant_id, name, destination_type, endpoint_url, secret, is_active, created_by, updated_by, created_at, updated_at, last_test_at, last_test_status, platform_account_id, platform_pixel_id, platform_token_ref, mapping_strategy, deleted_at, deleted_by
outbound_conversion_delivery_logs: id, destination_id, event_name, event_id, attempt, status, http_status, error_message, delivered_at, created_at
metrics_tenant_settings: tenant_id, metrics_display_currency, exclude_from_cac, exclude_reason, updated_by, updated_at, created_at
```

### API routes marketing enregistrées (app.ts)

```
/metrics       → metricsRoutes (overview, import)
/metrics       → metricsSettingsRoutes (settings/tenants CRUD)
/funnel        → funnelRoutes (event, events, metrics)
/ad-accounts   → adAccountsRoutes (CRUD + sync)
/outbound-conversions/destinations → outboundDestinationsRoutes
```

### Admin V2 proxy marketing

```
/api/admin/metrics/overview             → GET /metrics/overview
/api/admin/metrics/settings/tenants     → GET/PATCH /metrics/settings/tenants
/api/admin/marketing/ad-accounts        → CRUD /ad-accounts
/api/admin/marketing/destinations       → CRUD /outbound-conversions/destinations
/api/admin/marketing/delivery-logs      → GET delivery logs
/api/admin/marketing/funnel/metrics     → GET /funnel/metrics
/api/admin/marketing/funnel/events      → GET /funnel/events
```

RBAC Admin : `requireMarketing()` vérifie `['super_admin', 'account_manager', 'media_buyer']` — aucun filtre tenant.

### billing_events PROD

```
130 events total — TOUTES avec tenant_id = NULL
Types: checkout.session.completed(17), customer.subscription.created(17),
       customer.subscription.deleted(14), customer.subscription.updated(48),
       invoice.paid(32), invoice.payment_failed(2)
```

---

## Aucune modification effectuée

- Aucun patch
- Aucun build
- Aucun deploy
- Aucune migration
- Aucune création de donnée
- Aucune suppression
- Mode lecture seule stricte respecté

---

## Rapport : `keybuzz-infra/docs/PH-T8.10A-MARKETING-OWNER-TENANT-AGGREGATION-TRUTH-AUDIT-01.md`
