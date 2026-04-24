# PH-T8.10J.1-MARKETING-OWNER-STACK-PROD-RUNTIME-TRUTH-VALIDATION-01 — TERMINÉ

**Verdict : GO PARTIEL — OWNER MAPPING + BUSINESS/FUNNEL READ PROUVÉS — OUTBOUND STRUCTURELLEMENT PROUVÉ — STARTTRIAL NON ATTEINT (PAS DE PAIEMENT STRIPE)**

| Champ | Valeur |
|---|---|
| Phase | PH-T8.10J.1 |
| Environnement | PROD |
| Date | 2026-04-24 |
| Type | Validation runtime vérité — marketing owner stack |
| Priorité | P0 |
| API PROD | `v3.5.116-marketing-owner-stack-prod` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` (inchangée) |
| Owner tenant | `keybuzz-consulting-mo9zndlk` |
| Tenant enfant créé | `test-owner-runtime-p-modeeozl` |

---

## 1. Préflight

| Point | Résultat |
|---|---|
| API branche | `ph147.4/source-of-truth` |
| API HEAD | `ac29fd55` |
| API PROD image | `v3.5.116-marketing-owner-stack-prod` — conforme |
| Client branche | `ph148/onboarding-activation-replay` |
| Client HEAD | `6d5a796` |
| Client PROD image | `v3.5.116-marketing-owner-stack-prod` — conforme |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` — inchangée |
| Repos clean | Oui |
| Aucun patch/build/deploy | Confirmé |

---

## 2. État avant test

| Vue | Mesure | Avant test |
|---|---|---|
| `/metrics/overview?scope=owner` | `owner_cohort.children` | `[]` (vide) |
| `/metrics/overview?scope=owner` | `new_customers` | 0 |
| `/metrics/overview?scope=owner` | `spend_total_eur` | 512.89 |
| `/funnel/metrics?scope=owner` | `cohort_size` | 0 |
| `/funnel/metrics?scope=owner` | steps non-zero | `[]` (vide) |
| `/funnel/events?scope=owner` | count | 0 |
| DB | tenants avec owner KBC | 0 |
| DB | signup_attribution avec owner KBC | 0 |
| DB | total tenants | 16 |
| DB | total signup_attribution | 4 |
| DB | total funnel_events | 6 |
| DB | total conversion_events | 0 |

---

## 3. Test contrôlé

| Élément | Valeur |
|---|---|
| Owner tenant | `keybuzz-consulting-mo9zndlk` |
| Plan | `PRO` |
| Cycle | `monthly` |
| Email test | `test-owner-runtime-prod@keybuzz.io` |
| Flow utilisé | API `POST /tenant-context/create-signup` (même endpoint que le client post-OTP) |
| Tenant enfant créé | `test-owner-runtime-p-modeeozl` |
| User ID | `44b3b51e-6a1f-4363-aef5-835e647cbcb9` |
| Status réponse | 201 Created |

Le flow create-signup a été appelé directement depuis le pod API PROD avec les mêmes paramètres que le client envoie après l'authentification OTP. Ce n'est pas un insert SQL manuel — c'est le même endpoint API utilisé par le frontend.

Paramètres d'attribution :
- `marketing_owner_tenant_id`: `keybuzz-consulting-mo9zndlk`
- `utm_source`: `cursor-validation`
- `utm_campaign`: `PH-T8.10J.1-runtime-truth`
- `plan`: `pro`
- `cycle`: `monthly`

Événements funnel émis (via `POST /funnel/event`) :
- `plan_selected` (tenant_id=NULL, pre-tenant) — funnel_id `test-funnel-owner-prod-001`
- `register_started` (tenant_id=enfant) — même funnel_id
- `email_submitted` (tenant_id=enfant) — même funnel_id

---

## 4. Validation owner mapping PROD

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `tenants.marketing_owner_tenant_id` | `keybuzz-consulting-mo9zndlk` | **`keybuzz-consulting-mo9zndlk`** — OK |
| `tenants.plan` | PRO | **PRO** — OK |
| `tenants.status` | pending_payment | **pending_payment** — OK |
| `signup_attribution.marketing_owner_tenant_id` | `keybuzz-consulting-mo9zndlk` | **`keybuzz-consulting-mo9zndlk`** — OK |
| `signup_attribution.utm_source` | cursor-validation | **cursor-validation** — OK |
| `signup_attribution.plan` / `cycle` | pro / monthly | **pro / monthly** — OK |
| Pollution autres tenants | 0 | **0** — OK |

---

## 5. Validation owner-scoped business read

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `owner_cohort.children` | Contient le tenant enfant | **`["test-owner-runtime-p-modeeozl"]`** — OK |
| `owner_cohort.total` | 2 (owner + 1 enfant) | **2** — OK |
| `new_customers` | 1 (0 → 1) | **1** — OK |
| `spend_total_eur` | Reste KBC (512.89) | **512.89** — OK |
| `scope` | owner | **owner** — OK |

---

## 6. Validation owner-scoped funnel read

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `cohort_size` | 1 (nouveau funnel) | **1** — OK |
| `owner_cohort.children` | Contient enfant | **`["test-owner-runtime-p-modeeozl"]`** — OK |
| `owner_cohort.total` | 2 | **2** — OK |
| Steps non-zero | register_started, plan_selected, email_submitted | **`["register_started=1","plan_selected=1","email_submitted=1"]`** — OK |
| Pre-tenant stitching | plan_selected (tenant_id=NULL) inclus via funnel_id | **`plan_selected tenant_id: NULL funnel_id: test-funnel-owner-prod-001`** — OK |
| Post-tenant events | tenant_id = enfant | **`register_started tenant_id: test-owner-runtime-p-modeeozl`** — OK |
| `activation_completed` en #16 | Dernier step canonique | **`last_step: activation_completed`** — OK |
| Count events owner | 3 (0 → 3) | **3** — OK |

### Preuve du stitching pre-tenant

```
 event_name      | tenant_id                     | funnel_id
 plan_selected   | NULL                          | test-funnel-owner-prod-001
 register_started| test-owner-runtime-p-modeeozl | test-funnel-owner-prod-001
 email_submitted | test-owner-runtime-p-modeeozl | test-funnel-owner-prod-001
```

L'événement `plan_selected` a `tenant_id=NULL` (pré-tenant) mais partage le même `funnel_id`. Le scope=owner résout d'abord les `funnel_id` associés aux tenants enfants, puis inclut TOUS les événements de ces funnels — y compris ceux avec `tenant_id=NULL`.

---

## 7. Validation outbound owner-aware

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `marketing_owner_tenant_id` résolu | KBC | **`keybuzz-consulting-mo9zndlk`** — OK |
| Routing tenant pour lookup | Owner KBC | **`keybuzz-consulting-mo9zndlk`** — OK |
| Destination active trouvée | Meta CAPI KBC | **1 destination `meta_capi` (`87f8dc49`)** — OK |
| `conversion_events.tenant_id` (serait) | Tenant runtime enfant | **`test-owner-runtime-p-modeeozl`** — OK |
| StartTrial atteint | Non requis | **Non — `pending_payment`** |
| Delivery HTTP | N/A | **N/A — pas de StartTrial** |

Le routing outbound est **structurellement prouvé** : la résolution `resolveOutboundRoutingTenantId` trouve l'owner KBC, la destination Meta CAPI active est trouvée, et le tenant runtime serait préservé dans `conversion_events`. La delivery réelle se produira au premier paiement Stripe d'un tenant enfant.

---

## 8. Preuves DB / API

### Tenant runtime créé
```
id: test-owner-runtime-p-modeeozl
name: Test Owner Runtime PROD
plan: PRO
status: pending_payment
marketing_owner_tenant_id: keybuzz-consulting-mo9zndlk
created_at: 2026-04-24 21:04:06
```

### Signup attribution
```
id: 94c8fd38-2d52-4db1-95c4-68c9ff56eeae
tenant_id: test-owner-runtime-p-modeeozl
marketing_owner_tenant_id: keybuzz-consulting-mo9zndlk
utm_source: cursor-validation
utm_campaign: PH-T8.10J.1-runtime-truth
plan: pro
cycle: monthly
```

### Funnel events enfant
```
funnel_id: test-funnel-owner-prod-001
events: 3 (plan_selected=NULL, register_started=enfant, email_submitted=enfant)
```

### Counts avant / après

| Mesure | Avant | Après | Delta |
|---|---|---|---|
| tenants | 16 | 17 | +1 |
| signup_attribution | 4 | 5 | +1 |
| funnel_events | 6 | 9 | +3 |
| conversion_events | 0 | 0 | 0 |

### Legacy NULL préservé
3 tenants (romruais, ecomlg-001, switaa-sasu) avec `marketing_owner_tenant_id=NULL` — intacts.

---

## 9. Non-régression

| Sujet | Attendu | Résultat |
|---|---|---|
| Legacy sans owner (ecomlg-001, no scope) | 200, scope=tenant | **200, scope=tenant, owner_cohort=false** — OK |
| Legacy funnel (ecomlg-001, no scope) | 200, 16 steps | **200, scope=NONE, 16 steps, owner_cohort=false** — OK |
| Health endpoint | 200 | **200** — OK |
| API restarts | 0 | **0** — OK |
| Client restarts | 0 | **0** — OK |
| Admin PROD | Inchangée | **`v2.11.11`** — OK |
| `billing_subscriptions` | Intacte (11) | **11** — OK |
| `conversion_events` | Intacte (0) | **0** — OK |
| Aucune promotion supplémentaire | Aucune | **Confirmé** |

---

## 10. Conclusion

### Verdict : GO PARTIEL (Cas B)

**Prouvé :**
- Signup owner-mappé en PROD : `tenants.marketing_owner_tenant_id` et `signup_attribution.marketing_owner_tenant_id` correctement renseignés
- Owner business read : `owner_cohort.children` contient le tenant enfant, `new_customers` incrémenté de 0 à 1, spend KBC préservé
- Owner funnel read : stitching pre-tenant fonctionne (tenant_id=NULL inclus via funnel_id), 3 events agrégés, activation_completed en #16
- Outbound routing structurellement prouvé : résolution owner → destination Meta CAPI KBC trouvée

**Non atteint :**
- StartTrial non atteint — le tenant enfant est en `pending_payment` (pas de paiement Stripe dans ce test contrôlé)
- Delivery outbound réelle non testée (sera validée au premier paiement réel)

**Prochaine phase possible :**
- Promotion Admin PROD owner cockpit
- Validation business delivery au premier paiement réel

**Aucune modification effectuée hors données créées par le test runtime :**
- 1 tenant créé (`test-owner-runtime-p-modeeozl`)
- 1 user créé (`test-owner-runtime-prod@keybuzz.io`)
- 1 signup_attribution
- 3 funnel_events
- Aucun patch, build, ou deploy

**Admin PROD inchangée : oui**

---

**MARKETING OWNER STACK RUNTIME TRUTH ESTABLISHED IN PROD — OWNER-MAPPED CHILD PROVED — OWNER-SCOPED READ CONFIRMED — OUTBOUND OWNER-AWARE STRUCTURALLY VERIFIED (STARTTRIAL PENDING REAL PAYMENT)**

---

**Rapport** : `keybuzz-infra/docs/PH-T8.10J.1-MARKETING-OWNER-STACK-PROD-RUNTIME-TRUTH-VALIDATION-01.md`
