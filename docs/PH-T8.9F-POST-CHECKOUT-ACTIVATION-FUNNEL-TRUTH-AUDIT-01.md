# PH-T8.9F — Post-Checkout Activation Funnel Truth Audit

> **Date** : 2026-04-24  
> **Auteur** : Cursor Executor (CE)  
> **Phase** : PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01  
> **Environnement** : DEV + PROD (lecture seule)  
> **Type** : Audit vérité — funnel d'activation post-checkout  
> **Priorité** : P0  
> **Aucune modification effectuée** : zéro patch, zéro build, zéro deploy, zéro donnée créée

---

## 1. PRÉFLIGHT

### API — `keybuzz-api`

| Élément | Valeur |
|---------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `2a61895e` |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-dev` |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-prod` |
| Repo clean | ✅ |

### Client — `keybuzz-client`

| Élément | Valeur |
|---------|--------|
| Branche | `ph148/onboarding-activation-replay` |
| HEAD | `9d8b9a0` |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-dev` |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-prod` |
| Repo clean | ✅ |

**PROD inchangée pendant cette phase.** Aucune modification effectuée.

---

## 2. CARTOGRAPHIE DU FUNNEL POST-CHECKOUT RÉEL

### Séquence réelle observée dans le code

| Ordre | Étape | Route / UI / API | Source de vérité actuelle | Observable aujourd'hui ? |
|-------|-------|-------------------|---------------------------|--------------------------|
| 1 | **Stripe Checkout** | Redirect navigateur vers Stripe | `billing_subscriptions`, `billing_events` | ✅ Fiable (Stripe webhook) |
| 2 | **Stripe callback** | Redirect vers `/register/success?session_id=...` | Stripe `successUrl` param | ❌ **Invisible** — aucun event côté DB |
| 3 | **Polling entitlement** | `GET /api/auth/me` + `GET /api/tenant-context/entitlement` (2s loop) | Aucune — in-memory polling | ❌ **Invisible** |
| 4 | **Entitlement débloqué** | `!isLocked` détecté | `billing_subscriptions.status` change | 🟡 Indirect (inféré de la subscription) |
| 5 | **trackPurchase** | GA4 `purchase` + Meta `Purchase` + TikTok `CompletePayment` | Browser-side pixels uniquement | 🟡 Partiel (browser-only, pas de preuve DB) |
| 6 | **clearAttribution** | Purge `sessionStorage` | Aucune — destructif | ❌ **Invisible** (donnée détruite) |
| 7 | **Redirect /dashboard** | `router.push('/dashboard')` après 3s | Aucune | ❌ **Invisible** |
| 8 | **Dashboard affiché** | `app/dashboard/page.tsx` | Aucune | ❌ **Invisible** |
| 9 | **Navigation /start** | Sidebar "Démarrage" (volontaire) | Aucune | ❌ **Invisible** |
| 10 | **OnboardingHub** | Checklist statique, pas d'API | `localStorage` uniquement | ❌ **Invisible** côté serveur |
| 11 | **Connexion marketplace** | `/channels` → OAuth Amazon/Octopia/Shopify | `inbound_connections` / `shopify_connections` | ✅ Fiable |
| 12 | **Première conversation** | `/inbox` — message entrant automatique | `conversations.MIN(created_at)` | ✅ Fiable |
| 13 | **Première session utile** | Usage réel (répondre, configurer, etc.) | Aucune | ❌ **Invisible** |

### Fait critique n°1 : Le post-checkout va directement à `/dashboard`, PAS à `/start`

Le code de `/register/success` redirige explicitement vers `/dashboard` (ligne 78) :
```typescript
setTimeout(() => { if (!cancelled) router.push('/dashboard'); }, 3000);
```

Il n'existe **aucun redirect automatique** vers `/start`, `/onboarding`, ou `/workspace-setup` après le checkout. Le user atterrit sur le dashboard vide.

### Fait critique n°2 : Le hub d'onboarding est statique et non routé automatiquement

`OnboardingHub` (monté sur `/start` et `/onboarding`) est une checklist statique sans API, sans persistance DB, et avec un seul item pré-coché en dur ("Créer votre espace"). Il ne reflète pas l'avancement réel.

### Fait critique n°3 : OnboardingWizard est du code mort

`OnboardingWizard` (7 étapes, localStorage, progression) **n'est importé nulle part dans `app/`**. Aucun utilisateur ne le voit. Il a été développé mais jamais branché sur une route.

---

## 3. AUDIT CLIENT / UX POST-CHECKOUT

### Fichiers audités

| Step UI | Fichier/route | Trigger d'entrée | Trigger de sortie | État persistant ? | Observable serveur ? |
|---------|---------------|-------------------|-------------------|--------------------|----------------------|
| **Success page** | `app/register/success/page.tsx` | Stripe `successUrl` redirect | `router.push('/dashboard')` après 3s | Non (query param `session_id`) | ❌ Non |
| **Dashboard** | `app/dashboard/page.tsx` | Redirect depuis /register/success | Navigation sidebar | Non | ❌ Non |
| **Start/Onboarding** | `app/start/page.tsx` = `OnboardingHub` | Navigation manuelle (sidebar) | Clics vers /channels, /inbox, etc. | Non (hub statique) | ❌ Non |
| **Channels** | `app/channels/page.tsx` | Navigation manuelle | OAuth Amazon/Octopia/Shopify | `inbound_connections` DB | ✅ Oui |
| **Inbox** | `app/inbox/page.tsx` | Navigation ou bouton "Accéder à mes messages" | Interaction avec messages | `conversations` DB | ✅ Oui |
| **OnboardingWizard** | `src/features/onboarding/components/OnboardingWizard.tsx` | **NON ROUTÉ** — code mort | N/A | localStorage (non utilisé) | ❌ Code mort |
| **OnboardingBanner** | `src/features/onboarding/components/OnboardingBanner.tsx` | **NON IMPORTÉ** — code mort | N/A | localStorage (non utilisé) | ❌ Code mort |
| **workspace-setup** | `app/workspace-setup/page.tsx` | Users sans tenant (chemin parallèle) | `/select-tenant` | `tenants` DB | 🟡 Indirect |

### Logique de redirect post-checkout

```
Stripe checkout complete
  → navigateur redirect vers /register/success?session_id={CHECKOUT_SESSION_ID}
  → polling entitlement toutes les 2s (GET /api/auth/me + GET /api/tenant-context/entitlement)
  → quand !isLocked :
      1. trackPurchase() → GA4/Meta/TikTok browser-side
      2. clearAttribution() → purge sessionStorage
      3. setTimeout(3s) → router.push('/dashboard')
  → timeout 90s → affiche erreur + bouton vers /dashboard quand même
```

### SaaSAnalytics (pixels de tracking)

**Fait critique** : les pixels (GA4, Meta, TikTok, LinkedIn) sont chargés **uniquement sur `/register` et `/login`**. Toutes les pages post-login sont explicitement bloquées :

```typescript
const BLOCKED_PREFIXES = [
  '/inbox', '/dashboard', '/orders', '/settings',
  '/channels', '/suppliers', '/knowledge', '/playbooks',
  '/ai-journal', '/billing', '/onboarding', '/workspace-setup',
  '/start', '/help',
];
```

Conséquence : `/register/success` est trackée (préfixe `/register`) mais `/dashboard`, `/start`, `/channels` ne le sont pas. Une fois le user dans le produit, les pixels s'éteignent. C'est **voulu** (respect privacy post-login), mais ça confirme l'invisibilité totale de l'activation côté analytics.

---

## 4. AUDIT BACKEND / DB / BUSINESS TRUTH

### Tables auditées (DEV)

| Step activation | DB proof | API/log proof | Niveau de confiance |
|-----------------|----------|---------------|---------------------|
| **Stripe paiement reçu** | `billing_subscriptions` (status=active/trialing) | Stripe webhook → API `/billing/webhook` | ✅ **Fiable** |
| **Checkout completed** | `billing_events` (event_type=`checkout.session.completed`, **53 rows**) | Stripe webhook | 🟡 **Partiel** — `tenant_id = NULL` sur TOUS les 244 billing_events |
| **Trial démarré** | `tenant_metadata.is_trial + trial_ends_at` | API `/tenant-context/entitlement` | ✅ **Fiable** |
| **CGU acceptées** | `tenant_metadata.cgu_accepted_at` | Non exposé dans funnel | ✅ **Fiable** |
| **Signup attribution** | `signup_attribution` (6 rows, UTM complets, `conversion_sent_at`) | API `/tenant-context/create-signup` | ✅ **Fiable** |
| **/register/success vu** | **AUCUNE table** | Aucun log | ❌ **Invisible** |
| **/start vu** | **AUCUNE table** | Aucun log | ❌ **Invisible** |
| **Onboarding hub affiché** | **AUCUNE table** (localStorage seulement, code mort) | Aucun log | ❌ **Invisible** |
| **Marketplace connectée** | `inbound_connections` (5 Amazon READY), `shopify_connections` (1 active) | API `/integrations/channels` | ✅ **Fiable** |
| **Première conversation** | `conversations` (MIN(created_at) par tenant, 5/20 tenants) | API `/messages/conversations` | ✅ **Fiable** |
| **Première session utile** | **AUCUNE table** (pas de `sessions`, pas de `last_login_at`, pas de `first_action_at`) | Aucun log | ❌ **Invisible** |
| **Funnel pré-tenant** | `funnel_events` (12 rows, 2 funnels, s'arrête à `checkout_started`/`tenant_created`) | API `/funnel/event` | 🟡 **Partiel** — pré-checkout uniquement |

### Questions noir sur blanc

| Question | Réponse | Preuve |
|----------|---------|--------|
| Peut-on prouver qu'un user a vu `/register/success` ? | **NON** | Aucun event DB. Le `checkout.session.completed` (Stripe webhook) prouve le paiement mais pas le redirect navigateur. Le user peut fermer le browser avant d'arriver. |
| Peut-on prouver qu'un user a vu `/start` ? | **NON** | Aucune table, aucun event, aucun flag. Le menu sidebar "Démarrage" existe mais rien ne trace les visites. |
| Peut-on prouver qu'un onboarding hub a été affiché ? | **NON** | Le hub est statique (pas d'API). La persistance localStorage (`kb_client_onboarding:v1`) existe dans le code mais `OnboardingWizard` n'est pas routé — code mort. |
| Peut-on prouver qu'une marketplace a été connectée ? | **OUI** | `inbound_connections` (5 Amazon READY avec `createdAt`), `shopify_connections` (12 rows dont 1 active). |
| Peut-on prouver qu'une première conversation a été atteinte ? | **OUI** | `SELECT tenant_id, MIN(created_at) FROM conversations GROUP BY tenant_id` — 5 tenants sur 20 ont ≥1 conversation. |
| Peut-on prouver une "première session utile" ? | **NON** | Aucune notion de session en DB. `users` n'a même pas de `updated_at` ou `last_seen_at`. Pas de table `sessions`, `login_events`, ou `activity_log`. |

### Anomalie critique : `billing_events.tenant_id = NULL`

244 billing events avec `tenant_id = NULL` pour **tous les rows**. Impossible de joindre un checkout Stripe à un tenant en DB. Les événements sont orphelins. Cela empêche toute corrélation automatique billing → tenant → activation.

### Anomalie : `conversion_events` vide

La table `conversion_events` (schéma : `id`, `event_id`, `tenant_id`, `event_name`, `payload`, `status`, `attempts`, `last_attempt_at`, `created_at`) existe mais contient **0 rows en DEV**. Les conversions passent directement via `signup_attribution.conversion_sent_at` + browser-side pixels.

---

## 5. MATRICE D'OBSERVABILITÉ RÉELLE

| Étape post-checkout | Comptable aujourd'hui ? | Source de vérité | Granularité | Trou principal |
|---------------------|------------------------|------------------|-------------|----------------|
| **Checkout Stripe complété** | 🟡 Partiel | `billing_events` (webhook) | Global (pas par tenant!) | `tenant_id = NULL` — 100% orphelins |
| **Subscription active** | ✅ Fiable | `billing_subscriptions` | Par tenant | Pas de timestamp précis "first active" |
| **Trial démarré** | ✅ Fiable | `tenant_metadata.is_trial` | Par tenant | Pas de preuve que le user a vu la confirmation |
| **trackPurchase envoyé** | 🟡 Partiel | GA4/Meta/TikTok browser-side | Par session | Aucune preuve DB, dépend du navigateur |
| **/register/success affiché** | ❌ Invisible | Aucune | — | Zéro tracking, zéro event, zéro log |
| **Redirect /dashboard** | ❌ Invisible | Aucune | — | Transition technique sans trace |
| **Dashboard vu** | ❌ Invisible | Aucune | — | Pixels explicitement bloqués sur /dashboard |
| **/start vu** | ❌ Invisible | Aucune | — | Pas de redirect auto, navigation volontaire seule |
| **Onboarding hub affiché** | ❌ Invisible | localStorage (code mort) | — | Hub statique, wizard non routé, aucune API |
| **Marketplace connectée** | ✅ Fiable | `inbound_connections` / `shopify_connections` | Par tenant + timestamp | — |
| **Première conversation** | ✅ Fiable | `conversations.MIN(created_at)` | Par tenant | Dépend de l'import automatique post-connexion |
| **Première réponse agent** | ✅ Fiable | `messages` (direction=outbound, first) | Par tenant | — |
| **Première session utile** | ❌ Invisible | Aucune | — | Pas de table sessions/login/activity |
| **Activation produit complète** | ❌ Invisible | Aucune | — | Concept non modélisé |

### Synthèse par niveau

| Niveau | Étapes |
|--------|--------|
| **Fiable** (preuve DB directe) | Subscription active, trial démarré, marketplace connectée, première conversation, première réponse |
| **Indirect** (inférable mais pas prouvé) | Checkout complété (billing_events sans tenant_id), entitlement débloqué |
| **Partiel** (dépend du navigateur) | trackPurchase (GA4/Meta/TikTok), attribution UTM |
| **Invisible** (zéro donnée) | /register/success vu, /dashboard vu, /start vu, onboarding hub, première session, activation complète |

---

## 6. DISTINCTION BUSINESS VS ACTIVATION

### Business Truth (événements monétaires/contractuels)

| Event | Source | Destination |
|-------|--------|-------------|
| `checkout_started` | `funnel_events` (API) | Interne uniquement |
| `checkout.session.completed` | `billing_events` (Stripe webhook) | Interne — mais tenant_id NULL |
| `trial_started` | `tenant_metadata.is_trial` (API create-signup) | Interne |
| `purchase_completed` | `trackPurchase()` browser-side → GA4/Meta/TikTok | Ads platforms (browser-only) |
| `StartTrial` / `Purchase` | Stripe webhook → server-side conversion pipeline | Ads platforms (CAPI) |

**Ces événements business sont la source de vérité pour le revenue et le marketing.**  
Ils ne doivent PAS être modifiés dans cette phase ou les suivantes.

### Activation Produit (événements d'usage réel)

| Event | Existe ? | Destination cible |
|-------|----------|-------------------|
| `success_page_viewed` | ❌ N'existe pas | Interne uniquement |
| `dashboard_first_viewed` | ❌ N'existe pas | Interne uniquement |
| `onboarding_started` | ❌ N'existe pas | Interne uniquement |
| `marketplace_connected` | ✅ Indirectement (DB) mais pas comme event | Interne uniquement |
| `first_conversation_received` | ✅ Indirectement (DB) mais pas comme event | Interne uniquement |
| `first_response_sent` | ✅ Indirectement (DB) mais pas comme event | Interne uniquement |
| `first_session_active` | ❌ N'existe pas | Interne uniquement |
| `activation_completed` | ❌ N'existe pas | Interne uniquement |

### Règle absolue de séparation

- Les micro-steps d'activation **doivent rester purement internes** (funnel CRO produit)
- Ils ne doivent **JAMAIS** être envoyés comme conversions ads (Meta/TikTok/Google)
- Ils ne doivent **JAMAIS** alimenter `conversion_events` ou les destinations outbound
- Seuls `StartTrial` et `Purchase` restent les business events marketing/billing
- Les metrics d'activation alimentent **uniquement** des KPIs internes (Admin V2, dashboard CRO)

---

## 7. MODÈLE CIBLE RECOMMANDÉ

### Events canoniques post-checkout

| Event canonique | Propriétaire | Trigger | Clé de stitching | Usage | Purement interne ? |
|-----------------|-------------|---------|-------------------|-------|---------------------|
| `success_viewed` | **Client** | `/register/success` → status='success' | `funnel_id` (via `attribution_id` en sessionStorage) | Preuve que le user est revenu de Stripe | ✅ Oui |
| `dashboard_first_viewed` | **Client** | Premier render `/dashboard` pour ce tenant | `tenant_id` | Premier atterrissage dans le produit | ✅ Oui |
| `onboarding_started` | **Client** | Premier render `/start` ou `/onboarding` | `tenant_id` | User a cherché le hub d'onboarding | ✅ Oui |
| `marketplace_connected` | **API** | `inbound_connections` INSERT avec status=READY | `tenant_id` | Première marketplace fonctionnelle | ✅ Oui |
| `first_conversation_received` | **API** | Premier INSERT `conversations` pour le tenant | `tenant_id` | Premier message client entrant | ✅ Oui |
| `first_response_sent` | **API** | Premier INSERT `messages` direction=outbound pour le tenant | `tenant_id` | Premier usage réel du produit | ✅ Oui |
| `activation_completed` | **API** (calculé) | `marketplace_connected` + `first_conversation_received` tous deux vrais | `tenant_id` | Tenant réellement activé | ✅ Oui |

### Logique de stitching

Le stitching post-checkout fonctionne différemment du pré-tenant :

- **Pré-tenant** : `funnel_id = attribution_id` (sessionStorage, anonyme)
- **Post-checkout** : `tenant_id` (authentifié, persistant)
- **Pont** : `tenant_created` relie le `funnel_id` au `tenant_id` (cohort stitching existant)

Pour `success_viewed` uniquement, le `funnel_id` est encore disponible en sessionStorage (avant `clearAttribution()`). Pour tous les autres events post-checkout, le `tenant_id` suffit.

### Table cible

Les events post-checkout peuvent être stockés dans la table `funnel_events` existante, en ajoutant les nouveaux noms à l'allowlist. La contrainte `UNIQUE(funnel_id, event_name)` assure l'idempotence.

Alternative : pour les events purement tenant-scoped, une contrainte `UNIQUE(tenant_id, event_name)` serait plus appropriée. Cela nécessiterait soit d'ajouter un index partiel, soit de stocker dans une table `activation_events` séparée.

**Recommandation** : utiliser `funnel_events` avec un flag `phase = 'pre_tenant' | 'post_checkout'` pour distinguer les deux familles, et ajouter un index partiel `UNIQUE(tenant_id, event_name) WHERE tenant_id IS NOT NULL` pour l'idempotence post-checkout.

---

## 8. PLAN DE PHASES RECOMMANDÉ

### Phase G1 — Instrumentation post-checkout client/API (DEV)

**Scope** : Émettre les events d'activation dans `funnel_events`.

| Tâche | Propriétaire | Détail |
|-------|-------------|--------|
| Ajouter `success_viewed` | Client | Émettre dans `/register/success` quand `status='success'` (AVANT `clearAttribution()`) |
| Ajouter `dashboard_first_viewed` | Client | Émettre au premier render de `/dashboard` (une seule fois par tenant, dedup tenant-scoped) |
| Ajouter `onboarding_started` | Client | Émettre au premier render de `/start` ou `/onboarding` |
| Ajouter `marketplace_connected` | API | Émettre côté API après INSERT dans `inbound_connections` avec status=READY |
| Ajouter `first_conversation_received` | API | Émettre côté API après premier INSERT dans `conversations` pour un tenant |
| Ajouter `first_response_sent` | API | Émettre côté API après premier INSERT dans `messages` (direction=outbound) pour un tenant |
| Ajouter index partiel | DB | `CREATE UNIQUE INDEX idx_funnel_events_tenant_event ON funnel_events(tenant_id, event_name) WHERE tenant_id IS NOT NULL` |
| Étendre `ALLOWED_EVENTS` | API | Ajouter les 6 nouveaux events à l'allowlist dans `routes.ts` |

**Estimation** : 1 session

### Phase G2 — Agrégation activation metrics (DEV)

**Scope** : Requête d'agrégation pour les events d'activation.

| Tâche | Détail |
|-------|--------|
| Endpoint `GET /funnel/activation-metrics` | Agrège les events post-checkout par tenant avec conversion rates |
| Calcul `activation_completed` | Dérivé = `marketplace_connected` + `first_conversation_received` |
| Filtres | `?tenant_id`, `?from`, `?to` |

**Estimation** : 1 session

### Phase G3 — UI Admin activation funnel

**Scope** : Visualisation dans l'Admin V2.

| Tâche | Détail |
|-------|--------|
| Tab "Activation" dans le dashboard Admin | Affiche le funnel post-checkout (success → dashboard → marketplace → conversation) |
| Tenant detail : activation status | Badge "Activé" / "En cours" / "Inactif" par tenant |
| Conversion rates globaux | Vue agrégée pour tous les tenants |

**Estimation** : 1 session

### Phase G4 — Promotion PROD

**Scope** : Promotion standard (build-from-git, GitOps, validation, non-régression).

| Tâche | Détail |
|-------|--------|
| Build PROD API + Client | Tags `-prod` |
| DB PROD | Index partiel additive |
| Validation PROD contrôlée | Events d'activation sur un tenant de test |
| Non-régression | Zéro impact conversion_events, ads, billing |

**Estimation** : 1 session

### Phase G5 — Exploitation CRO produit

**Scope** : Utilisation des données pour l'optimisation.

| Tâche | Détail |
|-------|--------|
| Dashboard CRO | Funnel complet : acquisition → trial → activation → retention |
| Alertes | Notification si un tenant payant n'a pas connecté de marketplace après 48h |
| Cohortes | Analyse par plan, par canal d'acquisition, par date |

**Estimation** : itératif

### Séparation des responsabilités

| Domaine | Events | Destination |
|---------|--------|-------------|
| **Acquisition** | `register_started` → `checkout_started` | `funnel_events` (interne) |
| **Revenue / Billing** | `StartTrial`, `Purchase` | `conversion_events` → CAPI (Meta/TikTok/Google) |
| **Activation produit** | `success_viewed` → `activation_completed` | `funnel_events` (interne) |
| **Reporting acquisition** | UTM, landing_url, gclid, fbclid | `signup_attribution` (interne) |

---

## 9. ANOMALIES ET DETTES IDENTIFIÉES

| # | Anomalie | Impact | Priorité |
|---|----------|--------|----------|
| **A1** | `billing_events.tenant_id = NULL` (244 rows) | Impossible de corréler checkout → tenant en DB | Haute |
| **A2** | `conversion_events` vide (0 rows) | Table prévue mais non alimentée | Moyenne |
| **A3** | `OnboardingWizard` non routé (code mort) | Investissement de dev perdu, confusion maintenance | Basse |
| **A4** | `OnboardingBanner` non importé (code mort) | Idem | Basse |
| **A5** | `OnboardingHub` statique (pas d'API, pas de progression réelle) | Hub inutile — donne une fausse impression de guidage | Moyenne |
| **A6** | `marketplace_connections` vide vs `inbound_connections` remplie | Deux tables pour le même concept, source de confusion | Basse |
| **A7** | `users` sans `last_login_at` / `updated_at` | Impossible de mesurer la rétention basique | Moyenne |
| **A8** | Pixels bloqués post-login (par design) | Correct pour la privacy, mais confirme le besoin d'instrumentation interne | Info |

---

## 10. CONCLUSION

### Ce qui est mesurable aujourd'hui

```
MESURABLE (5 étapes fiables):
  ✅ Subscription Stripe active
  ✅ Trial démarré
  ✅ Marketplace connectée (inbound_connections)
  ✅ Première conversation (conversations.MIN)
  ✅ Première réponse agent (messages outbound)
```

### Ce qui est un trou noir total (6 étapes invisibles)

```
INVISIBLE (6 étapes perdues):
  ❌ /register/success vu
  ❌ Dashboard première visite
  ❌ /start ou onboarding hub vu
  ❌ Première session utile
  ❌ Activation "produit prêt"
  ❌ Corrélation checkout → tenant (billing_events.tenant_id = NULL)
```

### Verdict

**Le funnel post-checkout est un trou noir d'activation.**

Entre le moment où Stripe confirme le paiement et le moment où le user connecte une marketplace (jours/semaines plus tard), il existe **6 étapes critiques totalement invisibles**. On ne peut même pas prouver que le user est revenu de Stripe.

La fondation technique est en place (table `funnel_events`, infrastructure de stitching) pour combler ce trou. Le modèle cible est défini (7 events, table existante, stitching par `tenant_id`). Le plan en 5 phases est prêt.

Aucune modification n'a été effectuée dans cette phase.

---

## 11. DOCUMENTS DE RÉFÉRENCE

| Document | Chemin |
|----------|--------|
| Audit funnel CRO pré-tenant | `keybuzz-infra/docs/PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md` |
| Fondation pré-tenant DEV | `keybuzz-infra/docs/PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md` |
| Tenant scope DEV | `keybuzz-infra/docs/PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md` |
| Promotion PROD funnel | `keybuzz-infra/docs/PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md` |
| Onboarding plan state | `keybuzz-infra/docs/PH-ONBOARDING-PLAN-STATE-CONTINUITY-01-REPORT.md` |
| Onboarding OAuth | `keybuzz-infra/docs/PH-ONBOARDING-OAUTH-CONTINUITY-01-REPORT.md` |
| Stripe real value PROD | `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md` |
| **Ce rapport** | `keybuzz-infra/docs/PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md` |

---

**PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01 — TERMINÉ**

**Verdict : GO** — Le trou noir est cartographié, le modèle cible est défini, le plan est prêt.

**POST-CHECKOUT ACTIVATION FUNNEL TRUTH ESTABLISHED — ACTIVATION OBSERVABILITY KNOWN — IMPLEMENTATION PLAN READY**
