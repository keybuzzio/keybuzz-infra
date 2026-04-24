# PH-T8.9I — Post-Checkout Activation Event Foundation — PROD Promotion

> **Date** : 2026-05-01
> **Environnement** : PROD
> **Type** : Promotion PROD — fondation events d'activation post-checkout
> **Priorité** : P0
> **Statut** : LIVE

---

## Objectif

Promouvoir en PROD la fondation d'events d'activation post-checkout validée en DEV (PH-T8.9G), afin que le funnel CRO live en PROD couvre désormais les 15 steps complets : 9 pre-tenant + 6 post-checkout.

---

## Sources de vérité

| Document | Phase |
|---|---|
| `keybuzz-infra/docs/PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md` | DEV foundation |
| `keybuzz-infra/docs/PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md` | Audit read-only |
| `keybuzz-infra/docs/PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md` | PROD pre-tenant promotion |
| `keybuzz-infra/docs/PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md` | Tenant cohort stitching |

---

## ÉTAPE 0 — Préflight

### API

| Point | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `d004d45e` — PH-T8.9G post-checkout activation event foundation |
| Image DEV | `v3.5.110-post-checkout-activation-foundation-dev` |
| Image PROD (avant) | `v3.5.109-funnel-metrics-tenant-scope-prod` |
| Status | clean |

### Client

| Point | Valeur |
|---|---|
| Branche | `ph148/onboarding-activation-replay` |
| HEAD | `1db9852` — PH-T8.9G post-checkout activation instrumentation |
| Image DEV | `v3.5.110-post-checkout-activation-foundation-dev` |
| Image PROD (avant) | `v3.5.108-funnel-pretenant-foundation-prod` |
| Status | clean |

### Admin PROD

`ghcr.io/keybuzzio/keybuzz-admin:v2.11.11-funnel-metrics-tenant-proxy-fix-prod` — inchangée dans cette phase.

---

## ÉTAPE 1 — Vérification source

### API

| Point | Résultat |
|---|---|
| 6 events post-checkout dans ALLOWED_EVENTS | `success_viewed`, `dashboard_first_viewed`, `onboarding_started`, `marketplace_connected`, `first_conversation_received`, `first_response_sent` (L16-21) |
| `emitActivationEvent()` | Présent L62 `funnel/routes.ts` |
| Résolution funnel_id canonique | SELECT earliest funnel_id pour tenant, fallback tenantId |
| Fallback documenté | `tenantId` comme `funnel_id` si aucun event prior |
| Idempotence | `ON CONFLICT (funnel_id, event_name) DO NOTHING` |
| Aucune écriture conversion_events | grep → CLEAN |
| Usage inbound/routes.ts | L132-133 + L422-423 : `marketplace_connected` + `first_conversation_received` |
| Usage messages/routes.ts | L383 : `first_response_sent` |

### Client

| Point | Résultat |
|---|---|
| `success_viewed` | L62-63 `register/success/page.tsx` via `emitActivationStep` |
| `dashboard_first_viewed` | L37 `dashboard/page.tsx` |
| `onboarding_started` | L15 `start/page.tsx` |
| Dedup client `activation:{tenantId}:{eventName}` | L58+ `src/lib/funnel.ts` |
| Non-régression `trackPurchase()` | Émis APRÈS activation, avant clearAttribution |
| Non-régression flow redirect | success → dashboard intact |

---

## ÉTAPE 2 — Vérification PROD DB

| Point | Résultat |
|---|---|
| Table `funnel_events` existe | Oui |
| Colonnes | id, funnel_id, event_name, source, tenant_id, attribution_id, plan, cycle, properties, created_at |
| Contrainte UNIQUE | `funnel_events_funnel_id_event_name_key` (funnel_id, event_name) |
| Indexes | pkey + unique + idx_funnel + idx_tenant (partial) + idx_name + idx_created |
| Migration nécessaire | **NON** — aucun changement de schéma |

---

## ÉTAPE 3 — Build safe PROD

### Images construites

| Service | Tag | Digest |
|---|---|---|
| API | `v3.5.110-post-checkout-activation-foundation-prod` | `sha256:85a559090a4024bd3e5c3e97164247350d1ca8dcd9a1c28fc380f2b585d2bf53` |
| Client | `v3.5.110-post-checkout-activation-foundation-prod` | `sha256:99b94c0d273a20d190d8d640728d2a8be1aeb900e8014b374e799ff4a29d8aff` |

### Build metadata

| Point | API | Client |
|---|---|---|
| Branche | `ph147.4/source-of-truth` | `ph148/onboarding-activation-replay` |
| HEAD | `d004d45e` | `1db9852` |
| Repo clean | Oui | Oui |
| Build-from-git | Oui | Oui |
| `--no-cache` | Oui | Oui |
| Build args (Client) | — | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |

---

## ÉTAPE 4 — GitOps PROD

| Point | Valeur |
|---|---|
| Commit infra | `99d6ccd` |
| Message | `PH-T8.9I: GitOps PROD — post-checkout activation foundation — API v3.5.110 + Client v3.5.110` |
| Push | `eb61084..99d6ccd main -> main` |

### Diff API PROD

```
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-prod
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.110-post-checkout-activation-foundation-prod  # rollback: v3.5.109-funnel-metrics-tenant-scope-prod
```

### Diff Client PROD

```
- image: ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-prod
+ image: ghcr.io/keybuzzio/keybuzz-client:v3.5.110-post-checkout-activation-foundation-prod  # rollback: v3.5.108-funnel-pretenant-foundation-prod
```

### Non-modifiés

- Admin PROD : inchangée
- DEV API/Client : inchangés
- Aucun autre manifest modifié

---

## ÉTAPE 5 — Deploy PROD

| Point | Résultat |
|---|---|
| `kubectl apply -f` API | `deployment.apps/keybuzz-api configured` |
| `kubectl apply -f` Client | `deployment.apps/keybuzz-client configured` |
| Rollout API | successfully rolled out |
| Rollout Client | successfully rolled out |
| Pod API | `keybuzz-api-564d58864c-lz8tw` Running, 0 restarts |
| Pod Client | `keybuzz-client-59d8f9785c-mcrwk` Running, 0 restarts |
| Image runtime API | `v3.5.110-post-checkout-activation-foundation-prod` |
| Image runtime Client | `v3.5.110-post-checkout-activation-foundation-prod` |
| Health API | `{"status":"ok"}` |
| Admin | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` (inchangée) |

---

## ÉTAPE 6 — Validation PROD

### A. Endpoints

| Endpoint | Attendu | Résultat |
|---|---|---|
| `/register/success` | 200 | 200 |
| `/dashboard` | 307 redirect login | 307 |
| `/start` | 307 redirect login | 307 |
| API `/health` | `{"status":"ok"}` | OK |
| `/funnel/metrics` | 15 steps | 15 steps (ordre canonique) |
| `/funnel/events` | `{"events":[],"count":0}` | OK |

### B. 15 steps funnel

```
 1. register_started
 2. plan_selected
 3. email_submitted
 4. otp_verified
 5. oauth_started
 6. company_completed
 7. user_completed
 8. tenant_created
 9. checkout_started
10. success_viewed         ← NEW
11. dashboard_first_viewed ← NEW
12. onboarding_started     ← NEW
13. marketplace_connected  ← NEW
14. first_conversation_received ← NEW
15. first_response_sent    ← NEW
```

### C. Non-régression business

| Point | Attendu | Résultat |
|---|---|---|
| `conversion_events` | 0 activation events | 0 |
| `outbound_conversion_destinations` | 10 | 10 (inchangé) |
| `outbound_conversion_delivery_logs` | 4 | 4 (inchangé) |
| `signup_attribution` | 3 | 3 (inchangé) |
| `billing_events` | 127 | 127 (inchangé) |

---

## ÉTAPE 7 — Preuves DB / SQL

### Schema funnel_events

| Colonne | Type | Nullable |
|---|---|---|
| id | uuid | NO |
| funnel_id | text | NO |
| event_name | text | NO |
| source | text | NO |
| tenant_id | text | YES |
| attribution_id | text | YES |
| plan | text | YES |
| cycle | text | YES |
| properties | jsonb | YES |
| created_at | timestamptz | NO |

### Indexes

| Index | Définition |
|---|---|
| `funnel_events_pkey` | UNIQUE btree (id) |
| `funnel_events_funnel_id_event_name_key` | UNIQUE btree (funnel_id, event_name) — idempotence |
| `idx_funnel_events_funnel` | btree (funnel_id) |
| `idx_funnel_events_tenant` | btree (tenant_id) WHERE tenant_id IS NOT NULL |
| `idx_funnel_events_name` | btree (event_name) |
| `idx_funnel_events_created` | btree (created_at) |

### Preuves

| Preuve | Résultat |
|---|---|
| Activation events dans conversion_events | 0 (aucune pollution) |
| Outbound delivery logs | 4 (inchangé, aucune livraison liée aux activation events) |
| funnel_events rows | 0 (table prête) |
| Idempotence test (INSERT + duplicate) | INSERT 1 = INSERTED, INSERT 2 = SKIPPED (ON CONFLICT DO NOTHING fonctionne) |
| Test data cleanup | ROLLBACK appliqué (aucune donnée de test en PROD) |

---

## ÉTAPE 8 — Non-régression

| Point | Résultat |
|---|---|
| `/register` | Build OK, SSR fonctionnel |
| `/register/success` | 200 |
| `/dashboard` | 307 (redirect login, attendu) |
| `/start` | 307 (redirect login, attendu) |
| Plan/cycle/OAuth | Inchangés (pas de modification billing/auth) |
| `trackPurchase()` | Intact (émis après activation, avant clearAttribution) |
| `signup_attribution` | 3 rows (inchangé) |
| `funnel/events` | OK |
| `funnel/metrics` | 15 steps OK |
| `conversion_events` | 0 (intact) |
| Outbound conversions | 10 destinations, 4 logs (inchangé) |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` (inchangée) |

---

## ÉTAPE 9 — Gaps restants

| Gap | Description | Impact | Phase correctrice |
|---|---|---|---|
| `billing_events.tenant_id = NULL` | 127 rows PROD avec `tenant_id = NULL` | Impossible de coudre checkout → tenant sans `signup_attribution` | Future phase billing |
| `OnboardingWizard` | Code mort | Aucun impact fonctionnel | Nettoyage technique |
| `OnboardingHub` | Composant statique | Expérience onboarding limitée | Évolution produit |
| `activation_completed` | Event composite non modélisé | Pas de marqueur "fully activated" | Future phase CRO |
| Labels bruts steps 10-15 (Admin) | `success_viewed` etc. non humanisés en Admin V2 | Dette cosmétique non bloquante | Prochaine phase Admin |

---

## ÉTAPE 10 — Rollback PROD

### Images rollback (non exécuté)

| Service | Rollback tag |
|---|---|
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` |

### Procédure

1. Modifier l'image dans le manifest YAML vers le tag rollback
2. `git commit && git push`
3. SSH bastion → `cd /opt/keybuzz/keybuzz-infra && git pull --ff-only`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
5. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
6. Vérifier `kubectl rollout status`
7. La table `funnel_events` ne nécessite aucune modification

---

## Images PROD — Avant / Après

| Service | Avant | Après |
|---|---|---|
| API | `v3.5.109-funnel-metrics-tenant-scope-prod` | `v3.5.110-post-checkout-activation-foundation-prod` |
| Client | `v3.5.108-funnel-pretenant-foundation-prod` | `v3.5.110-post-checkout-activation-foundation-prod` |
| Admin | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | Inchangée |

### Digests

| Service | Digest |
|---|---|
| API PROD | `sha256:85a559090a4024bd3e5c3e97164247350d1ca8dcd9a1c28fc380f2b585d2bf53` |
| Client PROD | `sha256:99b94c0d273a20d190d8d640728d2a8be1aeb900e8014b374e799ff4a29d8aff` |

---

## Verdict

**POST-CHECKOUT ACTIVATION EVENT FOUNDATION LIVE IN PROD — INTERNAL ACTIVATION STEPS CAPTURED — FUNNEL STITCHING PRESERVED — NO ADS POLLUTION — ADMIN UNCHANGED**

### Funnel complet PROD (15 steps)

```
Pre-tenant (steps 1-9):
  register_started → plan_selected → email_submitted → otp_verified →
  oauth_started → company_completed → user_completed → tenant_created →
  checkout_started

Post-checkout activation (steps 10-15):
  success_viewed → dashboard_first_viewed → onboarding_started →
  marketplace_connected → first_conversation_received → first_response_sent
```

### Garanties

- Aucune pollution `conversion_events` — les 6 events restent internes
- Aucune livraison outbound (Meta/TikTok/Google) liée à ces events
- Idempotence garantie par `UNIQUE(funnel_id, event_name)` + `ON CONFLICT DO NOTHING`
- Funnel stitching préservé via `emitActivationEvent` avec résolution canonique `funnel_id`
- Admin PROD inchangée — consomme naturellement les nouveaux events via `/funnel/metrics`
- Rollback documenté et prêt

---

## Rapport

`keybuzz-infra/docs/PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md`
